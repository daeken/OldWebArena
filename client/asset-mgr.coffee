module.exports = {
	get: (name, type, cb) ->
		console.time 'Getting asset ' + name
		xhr = new XMLHttpRequest
		xhr.open 'GET', '/assets/' + name, true
		xhr.responseType = type
		xhr.onload = ->
			console.timeEnd 'Getting asset ' + name
			cb xhr.response
		xhr.send()
	get_json: (name, cb) ->
		@get name, 'json', cb
	get_binary: (name, cb) ->
		@get name, 'arraybuffer', cb
}
