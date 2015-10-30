express = require 'express'
app = express()
expressWs = require('express-ws')(app)
compression = require 'compression'
THREE = require('three-math')
app.use compression {level: 9}

browserify_express = require('browserify-express')
bundle = browserify_express({
	entry: __dirname + '/../client/main.coffee',
	watch: __dirname + '/../client/',
	mount: '/app.js',
	verbose: true,
	#minify: true,
	opts: { debug: true },
	write_file: __dirname + '/public/_gen/app.js',
})
app.use bundle
app.use express.static('public')

class Player
	constructor: (@client, @position) ->

	setPosition: (position) ->
		@position = position

clients = {}
defaultPosition = () -> new THREE.Vector3 0, 0, 0
id = 0
app.ws '/', (ws, req) ->
	ws.id = id++
	console.log 'connected', ws.id
	clients[ws.id] = new Player ws, defaultPosition
	announce = JSON.stringify {type: 'announce', playerId: ws.id}
	wss.clients.forEach (client) ->
		if client != ws
			client.send announce, (err) ->
				
			ws.send JSON.stringify({type: 'announce', playerId: client.id}), (err) ->
				
	ws.on 'message', (msg) ->
		msg = JSON.parse msg
		msg.playerId = ws.id
		omsg = JSON.stringify msg
		player = clients[msg.playerId]
		if msg.type == 'update'
			newPosition = new THREE.Vector3 msg.position[0], msg.position[1], msg.position[2]
			player.setPosition newPosition
			wss.clients.forEach (client) ->
				if client != ws
					client.send omsg, (err) ->
						
	ws.on 'close', ->
		msg = JSON.stringify {type: 'disconnect', playerId: ws.id}
		console.log "disconnect", ws.id
		delete clients[msg.playerId] # Lets not leak memory forever.
		wss.clients.forEach (client) ->
			client.send msg, (err) ->

wss = expressWs.getWss '/'

server = app.listen 5000, ->
	host = server.address().address
	port = server.address().port

	console.log 'Listening at http://%s:%s', host, port
