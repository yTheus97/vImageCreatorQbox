fx_version 'cerulean'
game 'gta5'

shared_script 'config.lua'

server_scripts {
	'@oxmysql/lib/MySQL.lua', -- https://github.com/CommunityOx/oxmysql
	'server/server.lua',
    'server/downloader.js'
}

client_script 'client/client.lua'

dependency 'screencapture' -- https://github.com/itschip/screencapture
