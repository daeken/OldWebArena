Function::property = (prop, desc) ->
	Object.defineProperty @prototype, prop, desc

class Time
	constructor: ->
		@startTime = new Date()

	@property 'elapsed', 
		get: -> new Date() - @startTime

	delay: (ms, cb) ->
		setTimeout cb, ms

module.exports = new Time