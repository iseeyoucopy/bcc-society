fx_version "adamant"
games { "rdr3" }
rdr3_warning "I acknowledge that this is a prerelease build of RedM, and I am aware my resources *will* become incompatible once RedM ships."
lua54 "yes"
author "BCC Scripts @iseeyoucopy"

shared_scripts {
    'config.lua',
    'locale.lua',
    'languages/*.lua'
}

client_scripts {
    'client/helpers/functions.lua',
    'client/helpers/*.lua',
    'client/services/menus/*.lua',
    'client/services/*.lua',
    'client/main.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/helpers/functions.lua',
    'server/services/API.lua', --Ensure first so we can use the api in this society script
    'server/services/dbupdater.lua',
    'server/helpers/*.lua',
    'server/services/*.lua',
    'server/main.lua'
}

dependencies {
    'oxmysql',
    'vorp_core',
    'feather-menu',
    'bcc-utils',
    'vorp_character',
    'vorp_inventory',
}

version '1.0.2'
