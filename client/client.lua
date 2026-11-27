local locale = Locales[Config.Locale] or Locales.en
local menuId = 'wqzx_exchanger:menu'
local npcs = {}

local function notify(description, kind)
    if Config.Notify == 'none' then return end

    if Config.Notify == 'esx' and GetResourceState('es_extended') == 'started' then
        exports.es_extended:getSharedObject().ShowNotification(description, kind)
    elseif Config.Notify == 'qb' and GetResourceState('qb-core') == 'started' then
        exports['qb-core']:GetCoreObject().Functions.Notify({
            text = description,
            caption = locale.title
        }, kind)
    else
        lib.notify({ title = locale.title, description = description, type = kind })
    end
end

local function exchangeOption(npc, token, direction, rate, from, to)
    local text = locale[direction]
    local rateText = text.rate:format(rate)
    local icon = Config.rates[from].icon

    return {
        title = locale[from],
        description = rateText,
        icon = icon,
        onSelect = function()
            local alert = lib.alertDialog({
                header = ('%s ➤ %s'):format(locale[from], locale[to]),
                content = text.confirm .. '\n' .. rateText,
                centered = true,
                cancel = true,
                labels = { cancel = locale.cancel, confirm = locale.confirm }
            })
            if alert ~= 'confirm' then return end

            local input = lib.inputDialog(locale.title, {
                { type = 'number', label = text.amount, icon = icon, min = Config.minExchange, precision = 0 }
            })
            if not input or not input[1] then return end

            if not lib.progressBar({
                duration = 5000,
                label = locale.counting,
                useWhileDead = false,
                canCancel = true,
                disable = { car = true, move = true, combat = true }
            }) then
                notify(locale.exchange_canceled, 'error')
                return
            end

            local success, result, payout = lib.callback.await('wqzx_exchanger:exchange', false, {
                type = direction,
                amount = input[1]
            }, token)

            if success then
                lib.requestAnimDict('mp_common')
                TaskPlayAnim(cache.ped, 'mp_common', 'givetake2_a', 8.0, 8.0, 2000, 48, 1, false, false, false)
                TaskPlayAnim(npc, 'mp_common', 'givetake2_a', 8.0, 8.0, 2000, 48, 1, false, false, false)
                Wait(2000)
                RemoveAnimDict('mp_common')

                local sent = locale[from .. '_amount']:format(input[1])
                local received = locale[to .. '_amount']:format(payout)
                notify(locale.exchange_success:format(sent, received), 'success')
            elseif result == 'invalid_amount' then
                notify(locale.invalid_amount:format(Config.minExchange), 'error')
            else
                notify(locale[result] or locale.exchange_failed, 'error')
            end
        end
    }
end

local function openMenu(npc, station)
    local rates, token = lib.callback.await('wqzx_exchanger:getRates', false, station)
    if not rates then
        notify(locale.rates_unavailable, 'error')
        return
    end

    lib.registerContext({
        id = menuId,
        title = locale.title,
        options = {
            exchangeOption(npc, token, 'dollarToPesos', rates.dollarToPesos, 'dollar', 'cayo'),
            exchangeOption(npc, token, 'pesosToDollar', rates.pesosToDollar, 'cayo', 'dollar')
        }
    })
    lib.showContext(menuId)
end

CreateThread(function()
    lib.requestModel(Config.npc.model)

    for i, coords in ipairs(Config.npc.coords) do
        local npc = CreatePed(0, Config.npc.model, coords.x, coords.y, coords.z - 1.0, coords.w, false, false)
        SetEntityAsMissionEntity(npc, true, true)
        SetBlockingOfNonTemporaryEvents(npc, true)
        FreezeEntityPosition(npc, true)
        SetEntityInvincible(npc, true)
        npcs[i] = npc

        exports.ox_target:addBoxZone({
            coords = Config.target.coords[i],
            size = vec3(1, 1, 2),
            rotation = 0.0,
            options = {
                {
                    name = 'wqzx_exchanger:open:' .. i,
                    icon = Config.target.icon,
                    label = locale.open,
                    distance = 1.5,
                    onSelect = function()
                        openMenu(npc, i)
                    end
                }
            }
        })
    end

    SetModelAsNoLongerNeeded(Config.npc.model)
end)

AddEventHandler('onResourceStop', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end

    for _, npc in pairs(npcs) do
        DeleteEntity(npc)
    end
end)
