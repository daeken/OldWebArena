Renderer = require './renderer.coffee'
Player = require './player.coffee'
assets = require './asset-mgr.coffee'
importer = require './importer.coffee'
Network = require './network.coffee'
Time = require './time.coffee'

interval = (time, cb) ->
	setInterval cb, time

class MainApp
	constructor: ->
		stats = new Stats()
		stats.setMode 0
		stats.domElement.style.position = 'absolute'
		stats.domElement.style.left = stats.domElement.style.top = '0px'
		document.body.appendChild stats.domElement

		@player = new Player [0, 0, 100]

		renderer = new Renderer @player
		renderer.onrendercomplete = ->
			stats.update()
			for id, player of players
				player.mesh.update Time.elapsed

		players = {}

		network = new Network
		network.onannounce = (id) ->
			if !players[id]
				assets.get_json 'sarge.json', (data) =>
					model = importer.parse_playermodel data
					renderer.scene.add model
					players[id] = renderer.addPlayer new Player [-1000, -1000, -1000], model
		network.onupdate = (id, position, rotation) ->
			players[id].update position, rotation
		network.ondisconnect = (id) ->
			if players[id]
				renderer.removePlayer players[id]
				delete players[id]
		
		pos = [-1000, -1000, -1000]
		rotation = [0, 0]
		interval 33, ->
			newpos = renderer.curPosition()
			newrot = renderer.curRotation()
			if newpos[0] != pos[0] or newpos[1] != pos[1] or newpos[2] != pos[2] or rotation[0] != newrot[0] or rotation[1] != newrot[1]
				pos = newpos
				rotation = newrot
				network.update newpos, newrot
		
		assets.get_json 'tourney.json', (data) =>
			map = importer.parse_map data
			renderer.loadMap map

$(document).ready ->
	new MainApp
