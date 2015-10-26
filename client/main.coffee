Renderer = require './renderer.coffee'
Player = require './player.coffee'
assets = require './asset-mgr.coffee'
importer = require './importer.coffee'
Network = require './network.coffee'

console.log 'foo'

interval = (time, cb) ->
	setInterval cb, time

$(document).ready ->
	stats = new Stats()
	stats.setMode 1
	stats.domElement.style.position = 'absolute'
	stats.domElement.style.left = stats.domElement.style.top = '0px'
	document.body.appendChild stats.domElement

	renderer = new Renderer
	renderer.onrendercomplete = ->
		stats.update()

	players = {}

	network = new Network
	network.onannounce = (id) ->
		if !players[id]
			players[id] = renderer.addPlayer new Player
	network.onupdate = (id, position) ->
		players[id].update position
	network.ondisconnect = (id) ->
		if players[id]
			renderer.removePlayer players[id]
			delete players[id]
	
	pos = [-1000, -1000, -1000]
	interval 33, ->
		newpos = renderer.curPosition()
		if newpos[0] != pos[0] or newpos[1] != pos[1] or newpos[2] != pos[2]
			pos = newpos
			network.update newpos
	
	assets.get_json 'tourney.json', (data) ->
		map = importer.parse_map data
		renderer.loadMap map.geometry
