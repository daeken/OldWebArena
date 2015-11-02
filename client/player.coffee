Time = require './time.coffee'

# Code adapted/based on toji's webgl-quake3, in turn adapted from q3 itself.

q3movement_stopspeed = 100.0
q3movement_duckScale = 0.25
q3movement_jumpvelocity = 50

q3movement_accelerate = 10.0
q3movement_airaccelerate = 0.1
q3movement_flyaccelerate = 8.0

q3movement_friction = 6.0
q3movement_flightfriction = 3.0

q3movement_frameTime = 0.30
q3movement_overclip = 0.501
q3movement_stepsize = 18

q3movement_gravity = 20.0

q3movement_playerRadius = 20.0
q3movement_scale = 50

class Player
	constructor: (pos, model) ->
		@position = new THREE.Vector3 pos[0], pos[1], pos[2]
		@velocity = new THREE.Vector3 0, 0, 0
		@onGround = false
		@groundTrace = undefined
		@walked = 0
		if model and not model.used
			model.used = true
			@mesh = model
		else
			geometry = new THREE.BoxGeometry 10, 10, 50
			material = new THREE.MeshBasicMaterial { color: 0xffffff }
			@mesh = new THREE.Mesh geometry, material
			@mesh.animate = () ->

	# Remote player update
	update: (pos) ->
		@mesh.animate 'walk'
		id = ++@walked
		Time.delay 100, ->
			if @walked == id
				@mesh.animate 'stand'
				@mesh.animate 'idle'
		@position.set pos[0], pos[1], pos[2]-50

	applyFriction: ->
		return if not @onGround

		speed = @velocity.length()
		drop = 0

		control = Math.max q3movement_stopspeed, speed
		drop += control * q3movement_friction * q3movement_frameTime

		newSpeed = Math.max 0, speed - drop
		if speed != 0
			newSpeed /= speed
			@velocity.multiplyScalar newSpeed
		else
			@velocity.set 0, 0, 0

	groundCheck: ->
		checkPoint = @position.clone().setZ(@position.z - q3movement_playerRadius - .25)
		
		@groundTrace = @collider.trace @position, checkPoint, q3movement_playerRadius
		
		@onGround = not (
			@groundTrace.fraction == 1 or # falling
			(@velocity.z > 0 and @velocity.dot(@groundTrace.plane[0]) > 10) or # jumping
			@groundTrace.plane[0].z < .7 # steep slope
		)

	clipVelocity: (vel, normal) ->
		backoff = vel.dot normal
		if backoff < 0
			backoff *= q3movement_overclip
		else
			backoff /= q3movement_overclip

		change = normal.clone().multiplyScalar backoff
		vel.clone().sub change

	accelerate: (dir, speed, accel) ->
		curspeed = @velocity.dot dir
		addSpeed = speed - curspeed
		return if addSpeed <= 0

		accelSpeed = accel * q3movement_frameTime * speed
		accelSpeed = Math.min accelSpeed, addSpeed

		accelDir = dir.clone().multiplyScalar accelSpeed
		@velocity.add accelDir

	walkMove: (dir) ->
		@applyFriction()
		speed = q3movement_scale

		@accelerate dir, speed, q3movement_accelerate
		@velocity = @clipVelocity @velocity, @groundTrace.plane[0]
		return if @velocity.x == 0 and @velocity.y == 0

		@stepSlideMove false

	airMove: (dir) ->
		speed = q3movement_scale
		@accelerate dir, speed, q3movement_airaccelerate
		@stepSlideMove true

	slideMove: (gravity) ->
		numbumps = 4
		planes = []
		endVelocity = new THREE.Vector3 0, 0, 0

		if gravity
			endVelocity.copy @velocity
			endVelocity.z -= q3movement_gravity * q3movement_frameTime
			@velocity.z = (@velocity.z + endVelocity.z) * .5

			@velocity = @clipVelocity @velocity, @groundTrace.plane[0] if @groundTrace.plane

		planes.push @groundTrace.plane[0].clone() if @groundTrace.plane
		planes.push @velocity.clone().normalize()

		timeLeft = q3movement_frameTime
		end = new THREE.Vector3 0, 0, 0

		for bumpcount in [0...numbumps]
			end = @position.clone().add(@velocity.clone().multiplyScalar timeLeft)

			trace = @collider.trace @position, end, q3movement_playerRadius
			if trace.allSolid
				@velocity.z = 0
				return true

			@position.copy trace.endPos if trace.fraction > 0
			break if trace.fraction == 1

			timeLeft -= timeLeft * trace.fraction

			nudged = false
			for plane in planes
				if trace.plane[0].dot(plane) > .99
					@velocity.add trace.plane[0]
					nudged = true
					break
			continue if nudged

			planes.push trace.plane[0].clone()

			for plane in planes
				into = @velocity.dot plane
				continue if into >= .1

				clipVelocity = @clipVelocity @velocity, plane
				endClipVelocity = @clipVelocity endVelocity, plane

				for splane in planes
					continue if splane == plane or clipVelocity.dot(splane) >= .1

					clipVelocity = @clipVelocity clipVelocity, splane
					endClipVelocity = @clipVelocity endClipVelocity, splane

					continue if clipVelocity.dot(plane) >= 0

					dir = plane.clone().cross(splane).normalize()
					d = dir.dot endVelocity
					endClipVelocity = dir.multiplyScalar d

					for ssplane in planes
						continue if ssplane == plane or ssplane == splane or clipVelocity.dot(ssplane) >= .1

						@velocity.set 0, 0, 0
						return true

				@velocity.copy clipVelocity
				endVelocity.copy endClipVelocity
				break

		@velocity.copy endVelocity if gravity

		return bumpcount != 0

	stepSlideMove: (gravity) ->
		return if not @slideMove(gravity)

		sp = @position.clone()
		sv = @velocity.clone()

		down = sp.clone()
		down.z -= q3movement_stepsize
		trace = @collider.trace sp, down, q3movement_playerRadius

		up = new THREE.Vector3 0, 0, 1
		return if @velocity.z > 0 and (trace.fraction == 1 or trace.plane[0].dot(up) < .7)

		up = sp.clone()
		up.z += q3movement_stepsize

		trace = @collider.trace sp, up, q3movement_playerRadius
		if trace.allSolid
			console.log 'stuck'
			return

		stepSize = trace.endPos.z - sp.z
		@position.copy trace.endPos

		@slideMove gravity

		down = @position.clone()
		down.z -= stepSize
		trace = @collider.trace @position, down, q3movement_playerRadius
		@position.copy trace.endPos if not trace.allSolid

		@velocity = @clipVelocity(@velocity, trace.plane[0]) if trace.fraction < 1

	move: (dir, frameTime) ->
		# XXX: No global hacks.
		q3movement_frameTime = frameTime*0.0075

		@groundCheck()
		if @onGround
			@walkMove dir
		else
			@airMove dir

module.exports = Player