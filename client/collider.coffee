EPS = .03125

clamp = (x) -> Math.min Math.max(x, 0), 1

class Collider
	constructor: (@tree) ->

	checkCollision: (a, b, bbox) ->
		outputStartsOut = true
		outputAllSolid = false
		outputFraction = 1

		checkNode = (node, startFraction, endFraction, start, end) ->
			if node[0] == 0
				sd = start.dot(node[1][0]) - node[1][1]
				ed =   end.dot(node[1][0]) - node[1][1]

				if sd >= 0 and ed >= 0
					checkNode node[4], startFraction, endFraction, start, end
				else if sd < 0 and ed < 0
					checkNode node[5], startFraction, endFraction, start, end
				else
					if sd < ed
						side = 1
						id = 1 / (sd - ed)
						fraction1 = fraction2 = clamp (sd + EPS) * id
					else if ed < sd
						side = 0
						id = 1 / (sd - ed)
						fraction1 = clamp (sd + EPS) * id
						fraction2 = clamp (sd - EPS) * id
					else
						side = 0
						fraction1 = 1
						fraction2 = 0

					middleFraction = startFraction + (endFraction - startFraction) * fraction1
					middle = start.clone().add(end.clone().sub(start).multiplyScalar fraction1)
					checkNode node[4], startFraction, middleFraction, start, middle

					middleFraction = startFraction + (endFraction - startFraction) * fraction2
					middle = start.clone().add(end.clone().sub(start).multiplyScalar fraction2)
					checkNode node[5], middleFraction, endFraction, start, middle
			else
				for brush in node[3]
					if brush.length > 0
						checkBrush brush

		checkBrush = (brush) ->
			startsOut = false
			endsOut = false
			startFraction = -1
			endFraction = 1
			for plane in brush
				sd = a.dot(plane[0]) - plane[1]
				ed = b.dot(plane[0]) - plane[1]

				startsOut = true if sd > 0
				endsOut = true if ed > 0

				if sd > 0 and ed > 0
					return
				else if sd <= 0 and ed <= 0
					console.log '...'
					continue
				console.log 'dsfaopj'

				if sd > ed
					fraction = (sd - EPS) / (sd - ed)
					startFraction = fraction if fraction > startFraction
				else
					fraction = (sd + EPS) / (sd - ed)
					endFraction = fraction if fraction < endFraction
			if not startsOut
				outputStartsOut = false
				if not endsOut
					outputAllSolid = true
				return
			if startFraction < endFraction
				if startFraction > -1 and startFraction < outputFraction
					startFraction = Math.max(startFraction, 0)
					outputFraction = startFraction

		checkNode @tree, 0, 1, a, b

		console.log outputFraction, outputAllSolid, outputStartsOut

		if outputFraction != 1
			console.log 'collided'
			return a.clone().add(b.clone().sub(a).multiplyScalar outputFraction)
		else
			return undefined

module.exports = Collider