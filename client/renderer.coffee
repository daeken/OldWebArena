Time = require './time.coffee'
Collider = require './collider.coffee'

THREE.Vector3.prototype.invert = ->
	this.x = -this.x
	this.y = -this.y
	this.z = -this.z
	this

class Renderer
	constructor: (@localPlayer) ->
		@scene = new THREE.Scene
		@camera = new THREE.PerspectiveCamera 60, window.innerWidth / window.innerHeight, .01, 10000
		@scene.add @camera

		@scene.add new THREE.AmbientLight 0xffffff

		@renderer = new THREE.WebGLRenderer { antialias: true }
		@de = @renderer.domElement
		@renderer.setSize window.innerWidth, window.innerHeight
		THREEx.WindowResize @renderer, @camera

		document.body.appendChild @de

		@controls = new THREE.PointerLockControls @camera
		@controls.getObject().position.set(0, 0, 100)
		@scene.add @controls.getObject()

		@pointerLock = false
		@$ = $(@de)
		@$.click =>
			if !@pointerLock
				@de.requestPointerLock()
		@leftmouse = @rightmouse = false
		@$.mousedown (evt) =>
			if !@pointerLock
				return
			if evt.button == 0
				@leftmouse = true
			else
				@rightmouse = true
		@$.mouseup (evt) =>
			if !@pointerLock
				return
			if evt.button == 0
				@leftmouse = false
			else
				@rightmouse = false
		document.addEventListener 'pointerlockchange', (evt) =>
			@pointerLock = !@pointerLock
			@controls.enabled = @pointerLock

		@keyboard = new THREEx.KeyboardState @de
		@de.setAttribute 'tabIndex', '0'
		@de.focus()

		@players = []

		@lastMove = 0

		@render()

	addPlayer: (player) ->
		@players.push player
		@scene.add player.mesh
		player

	removePlayer: (player) ->
		@scene.remove player.mesh

	curPosition: ->
		pos = @controls.getObject().position
		[pos.x, pos.y, pos.z]

	curRotation: ->
		@controls.getRotation()

	render: =>
		requestAnimationFrame @render
		return if not @map_mesh
		
		if @onupdate
			@onupdate()

		@players.forEach (player) =>
			if player != @localPlayer
				player.mesh.position.copy player.position
				player.mesh.rotation.z = player.rotation[0] + Math.PI / 2

		movement = new THREE.Vector3
		if @keyboard.pressed('w')
			movement.y += 1
		if @keyboard.pressed('s')
			movement.y -= 1
		if @keyboard.pressed('a')
			movement.x -= 1
		if @keyboard.pressed('d')
			movement.x += 1
		if @leftmouse
			movement.z += 1
		if @rightmouse
			movement.z -= 1
		@move movement

		@renderer.setClearColor new THREE.Color(0x000010)
		@renderer.render @scene, @camera

		if @onrendercomplete
			@onrendercomplete()

	move: (movement) ->
		obj = @controls.getObject()
		movement.applyQuaternion obj.quaternion
		dir = movement.normalize()

		elapsed = Time.elapsed
		while elapsed - @lastMove >= 16
			@lastMove += 16

			@localPlayer.move dir, 16
			
			obj.position.copy @localPlayer.position
			obj.position.z += 57

	loadMap: (map) ->
		material = new THREE.MeshNormalMaterial
		@map_mesh = new THREE.Mesh map.geometry, material
		@map_mesh.frustumCulled = false
		@scene.add @map_mesh

		@collider = new Collider map.brushtree
		@localPlayer.collider = @collider

module.exports = Renderer