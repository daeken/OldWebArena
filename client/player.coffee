class Player
	constructor: ->
		@position = [-1000, -1000, -1000]

	update: (pos) ->
		@position = pos

module.exports = Player