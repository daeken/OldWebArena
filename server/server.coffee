express = require 'express'
app = express()
expressWs = require('express-ws')(app)
compression = require 'compression'
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

id = 0
app.ws '/', (ws, req) ->
	ws.id = id++
	console.log 'connected', ws.id
	ws.connected = false
	announce = JSON.stringify {type: 'announce', playerId: ws.id}
	wss.clients.forEach (client) ->
		if client != ws
			if client.connected
				client.send announce, (err) ->
					client.close()
			ws.send JSON.stringify({type: 'announce', playerId: client.id}), (err) ->
				ws.close()
	ws.on 'open', ->
		console.log 'connected', ws.id
		ws.connected = true
	ws.on 'message', (msg) ->
		msg = JSON.parse msg
		msg.playerId = ws.id
		omsg = JSON.stringify msg
		if msg.type == 'update'
			wss.clients.forEach (client) ->
				if client != ws and client.connected
					client.send omsg, (err) ->
						client.close()
	ws.on 'close', ->
		msg = JSON.stringify {type: 'disconnect', playerId: ws.id}
		wss.clients.forEach (client) ->
			client.send msg
wss = expressWs.getWss '/'

server = app.listen 5000, ->
	host = server.address().address
	port = server.address().port

	console.log 'Listening at http://%s:%s', host, port
