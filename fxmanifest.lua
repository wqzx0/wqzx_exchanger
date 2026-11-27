fx_version 'cerulean'
game 'gta5'

author 'Wqzx'
description 'Currency exchange with English and Czech localization'

dependencies {
    '/onesync',
    'ox_lib',
    'ox_target',
    'ox_inventory'
}

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua'
}

client_scripts {
    'locales/en.lua',
    'locales/cs.lua',
    'client/client.lua'
}

server_script 'server/server.lua'
