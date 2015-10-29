class Time
	constructor: ->
		@startTime = new Date()

	getElapsed: ->
		new Date() - @startTime

module.exports = new Time