Collider = require './collider.coffee'

class Renderer
	constructor: ->
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
		@controls.enabled = false
		@controls.getObject().position.set(0, 100, 0)
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

		@render()

	addPlayer: (player) ->
		@players.push player
		geometry = new THREE.BoxGeometry 10, 50, 10
		material = new THREE.MeshBasicMaterial { color: 0xffffff }
		player.mesh = new THREE.Mesh geometry, material
		@scene.add player.mesh
		player

	removePlayer: (player) ->
		@scene.remove player.mesh

	curPosition: ->
		pos = @controls.getObject().position
		[pos.x, pos.y, pos.z]

	render: =>
		requestAnimationFrame @render

		if @onupdate
			@onupdate()

		@players.forEach (player) ->
			player.mesh.position.x = player.position[0]
			player.mesh.position.y = player.position[1]
			player.mesh.position.z = player.position[2]

		movement = new THREE.Vector3
		if @keyboard.pressed('w')
			movement.z -= 10
		if @keyboard.pressed('s')
			movement.z += 10
		if @keyboard.pressed('a')
			movement.x -= 10
		if @keyboard.pressed('d')
			movement.x += 10
		if @leftmouse
			movement.y += 10
		if @rightmouse
			movement.y -= 10
		if movement.x != 0 or movement.y != 0 or movement.z != 0
			@move movement

		@renderer.setClearColor new THREE.Color(0x000010)
		@renderer.render @scene, @camera

		if @onrendercomplete
			@onrendercomplete()

	move: (movement) ->
		obj = @controls.getObject()
		startpos = obj.position.clone()
		obj.translateX movement.x
		obj.translateY movement.y
		obj.translateZ movement.z
		endpos = obj.position.clone()

		point = @collider.checkCollision startpos, endpos, null
		if point
			console.log 'collided'
			obj.position.copy(point)

	loadMap: (map) ->
		material = new THREE.MeshNormalMaterial
		@map_mesh = new THREE.Mesh map.geometry, material
		#@map_mesh.frustumCulled = false
		@scene.add @map_mesh

		@collider = new Collider map.brushtree

module.exports = Renderer