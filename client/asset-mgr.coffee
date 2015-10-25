get = (name, cb) ->
	xhr = new XMLHttpRequest
	xhr.open 'GET', '/assets/' + name, true
	xhr.responseType = 'arraybuffer'
	xhr.onload = ->
		cb xhr.response
	xhr.send()

module.exports = {
	get: get
}
