local inventory = exports.ox_inventory
local rates
local nextRateUpdate = 0
local quoteLifetime = 60
local quotes = {}
local nextQuoteId = 0
local exchanging = {}

local directions = {
    dollarToPesos = { from = Config.rates.dollar.item, to = Config.rates.cayo.item },
    pesosToDollar = { from = Config.rates.cayo.item, to = Config.rates.dollar.item }
}

local function isAtStation(playerId, station)
    local location = Config.target.coords[station]
    if not location then return false end

    local ped = GetPlayerPed(playerId)
    return ped ~= 0 and #(GetEntityCoords(ped) - location) <= 3.0
end

lib.callback.register('wqzx_exchanger:getRates', function(playerId, station)
    if type(station) ~= 'number' or exchanging[playerId] or not isAtStation(playerId, station) then
        return nil
    end

    local now = os.time()
    if not rates or now >= nextRateUpdate then
        rates = {
            dollarToPesos = math.random(Config.rates.dollar.min, Config.rates.dollar.max),
            pesosToDollar = math.random(Config.rates.cayo.min, Config.rates.cayo.max)
        }
        nextRateUpdate = now + Config.updateInterval
    end

    nextQuoteId = nextQuoteId + 1
    quotes[playerId] = {
        id = nextQuoteId,
        station = station,
        rates = rates,
        expires = now + quoteLifetime
    }
    return rates, nextQuoteId
end)

local function transfer(playerId, direction, amount, payout)
    local removed, reason = inventory:RemoveItem(playerId, direction.from, amount, {})
    if not removed then
        return false, reason == 'not_enough_items' and 'insufficient_funds' or 'exchange_failed'
    end

    local failure = 'inventory_full'
    if inventory:CanCarryItem(playerId, direction.to, payout) then
        local added, addReason = inventory:AddItem(playerId, direction.to, payout)
        if added then return true, 'exchange_success', payout end
        if addReason ~= 'inventory_full' then failure = 'exchange_failed' end
    end

    if not inventory:AddItem(playerId, direction.from, amount) then
        print(('[wqzx_exchanger] Refund failed for player %d (%d x %s)'):format(playerId, amount, direction.from))
        return false, 'exchange_failed'
    end
    return false, failure
end

lib.callback.register('wqzx_exchanger:exchange', function(playerId, request, quoteId)
    if exchanging[playerId] then return false, 'exchange_failed' end

    local quote = quotes[playerId]
    if not quote or quote.id ~= quoteId or quote.expires <= os.time() then
        return false, 'quote_expired'
    end
    if not isAtStation(playerId, quote.station) then return false, 'too_far' end

    local direction = type(request) == 'table' and directions[request.type]
    if not direction then return false, 'exchange_failed' end

    local amount = type(request.amount) == 'number' and math.tointeger(request.amount)
    if not amount or amount < Config.minExchange then return false, 'invalid_amount' end

    local rate = quote.rates[request.type]
    local payout = math.tointeger(math.floor(amount * (rate + 0.0) / 100))
    if not payout or payout < 1 then return false, 'exchange_failed' end

    quotes[playerId] = nil
    exchanging[playerId] = true
    local ok, success, result, received = pcall(transfer, playerId, direction, amount, payout)
    exchanging[playerId] = nil

    if not ok then
        print(('[wqzx_exchanger] Exchange failed for player %d: %s'):format(playerId, success))
        return false, 'exchange_failed'
    end
    return success, result, received
end)

AddEventHandler('playerDropped', function()
    quotes[source] = nil
end)
