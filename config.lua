Config = {
    Locale = 'en', -- 'en' or 'cs'
    Notify = 'ox_lib', -- 'ox_lib', 'esx', 'qb', or 'none'
    npc = {
        model = `a_m_m_business_01`,
        coords = {
            vec4(219.4438, -1510.7322, 29.2918, 118.9809),
            vec4(4520.3311, -4515.3848, 4.4804, 21.7340),
            vec4(1767.8912, 3651.1401, 34.8881, 17.6925)
        }
    },
    target = {
        icon = 'fa-solid fa-money-bill-trend-up',
        coords = {
            vec3(218.449, -1510.846, 29.109),
            vec3(4520.3311, -4515.3848, 4.4804),
            vec3(1768.082, 3652.455, 34.705)
        }
    },
    rates = {
        dollar = {
            item = 'money',
            icon = 'fa-solid fa-dollar-sign',
            min = 5, -- Pesos received per 100 dollars
            max = 15
        },
        cayo = {
            item = 'black_money',
            icon = 'fa-solid fa-colon-sign',
            min = 35, -- Dollars received per 100 pesos
            max = 65
        }
    },
    minExchange = 100,
    updateInterval = 60 -- Seconds between rate updates
}
