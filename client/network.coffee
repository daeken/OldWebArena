class Network
	constructor: ->
		@ws = new WebSocket 'ws://' + window.location.host
		@ws.onopen = =>
			console.log 'Connected'
			@connected = true
		@ws.onclose = =>
			console.log 'Disconnected'
			@connected = false
		@ws.onmessage = (evt) =>
			msg = JSON.parse evt.data
			if msg.type == 'announce' and @onannounce
				@onannounce msg.playerId
			else if msg.type == 'update' and @onupdate
				@onupdate msg.playerId, msg.position
			else if msg.type == 'disconnect' and @ondisconnect
				@ondisconnect msg.playerId
		@ws.onerror = (evt) =>
			console.log 'Error', etc

	send: (data) ->
		@ws.send JSON.stringify data

	update: (position) ->
		if @connected
			@send {
				type: 'update', 
				position: position
			}

module.exports = Network