fx_version 'cerulean'
games {'gta5'}
description 'Holy man revive ritual'

lua54 'yes'

shared_script {
	'bridge.lua',
	'config.lua',
}
client_scripts {
	'client/*.lua',
}

server_scripts {
	'server/*.lua',
}

dependency 'community_bridge'
