fx_version 'cerulean'
game 'gta5'
lua54 'yes'

ui_page 'index.html'

files {
    'index.html',
    'sounds/*.ogg'
}

shared_scripts {
    '@ox_lib/init.lua'
}

client_script 'client.lua'
server_script 'server.lua'

dependency 'ox_lib'
