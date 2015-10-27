EPS = .003125

clamp = (x) -> Math.min Math.max(x, 0), 1

class Collider
	constructor: (@tree) ->

	checkCollision: (a, b, radius) ->
		@clipPlanes = []
		outputStartsOut = true
		outputAllSolid = false
		outputFraction = 1

		checkNode = (node, startFraction, endFraction, start, end) =>
			if node[0] == 0
				sd = start.dot(node[1][0]) - node[1][1]
				ed =   end.dot(node[1][0]) - node[1][1]

				if sd >= radius and ed >= radius
					checkNode node[4], startFraction, endFraction, start, end
				else if sd < -radius and ed < -radius
					checkNode node[5], startFraction, endFraction, start, end
				else
					if sd < ed
						side = 1
						id = 1 / (sd - ed)
						fraction1 = clamp (sd - radius + EPS) * id
						fraction2 = clamp (sd + radius + EPS) * id
					else if ed < sd
						side = 0
						id = 1 / (sd - ed)
						fraction1 = clamp (sd + radius + EPS) * id
						fraction2 = clamp (sd - radius - EPS) * id
					else
						side = 0
						fraction1 = 1
						fraction2 = 0

					middleFraction = startFraction + (endFraction - startFraction) * fraction1
					middle = start.clone().add(end.clone().sub(start).multiplyScalar fraction1)
					checkNode node[4 + side], startFraction, middleFraction, start, middle

					middleFraction = startFraction + (endFraction - startFraction) * fraction2
					middle = start.clone().add(end.clone().sub(start).multiplyScalar fraction2)
					checkNode node[5 - side], middleFraction, endFraction, middle, end
			else
				mins = node[1]
				maxs = node[2]
				if (
					true or
					(mins[0] <= a.x <= maxs[0] and mins[1] <= a.y <= maxs[1] and mins[2] <= a.z <= maxs[2]) or
					(mins[0] <= b.x <= maxs[0] and mins[1] <= b.y <= maxs[1] and mins[2] <= b.z <= maxs[2])
				)
					for brush in node[3]
						[collidable, brush] = brush
						if collidable and brush.length > 0
							checkBrush brush, start, end

		checkBrush = (brush, start, end) =>
			startsOut = false
			endsOut = false
			startFraction = -1
			endFraction = 1
			clipped = false
			for plane in brush
				sd = start.dot(plane[0]) - (plane[1] + radius)
				ed = end.dot(plane[0]) - (plane[1] + radius)

				startsOut = true if sd > 0
				endsOut = true if ed > 0

				if sd > 0 and ed > 0
					return
				else if sd <= 0 and ed <= 0
					continue

				if not clipped
					for bp in brush
						d = end.dot(bp[0]) - bp[1]
						same = d >= 0
						@clipPlanes.push [bp, same]
					clipped = true

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

		if outputFraction != 1
			return a.clone().add(b.clone().sub(a).multiplyScalar outputFraction)
		else
			return undefined

module.exports = Collider