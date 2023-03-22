description 'A SQL based need system for an ESX environment.'
version '1.0.0'
fx_version 'cerulean'
game 'gta5'
lua54 'yes'

shared_scripts {
    '@es_extended/imports.lua',
    '@es_extended/locale.lua',
    'locales/*.lua',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'config.lua',
    'server/status.lua',
    'server/needs.lua',
}

client_scripts {
    'client/main.lua',
}

dependencies {
    'oxmysql',
    'rpemotes',
}
