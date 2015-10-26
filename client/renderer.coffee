class Renderer
	constructor: ->
		@scene = new THREE.Scene
		@camera = new THREE.PerspectiveCamera 60, window.innerWidth / window.innerHeight, .01, 10000
		@camera.position.z = 0
		@camera.position.y = 0
		@scene.add @camera

		@scene.add new THREE.AmbientLight 0xffffff

		@renderer = new THREE.WebGLRenderer { antialias: true }
		@de = @renderer.domElement
		@renderer.setSize window.innerWidth, window.innerHeight
		THREEx.WindowResize @renderer, @camera

		document.body.appendChild @de

		@controls = new THREE.PointerLockControls @camera
		@controls.enabled = false
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

		if @keyboard.pressed('w')
			@controls.getObject().translateZ(-1)
		if @keyboard.pressed('s')
			@controls.getObject().translateZ(1)
		if @keyboard.pressed('a')
			@controls.getObject().translateX(-1)
		if @keyboard.pressed('d')
			@controls.getObject().translateX(1)
		if @leftmouse
			@controls.getObject().translateY(1)
		if @rightmouse
			@controls.getObject().translateY(-1)

		@renderer.setClearColor new THREE.Color(0x000010)
		@renderer.render @scene, @camera

		if @onrendercomplete
			@onrendercomplete()

	loadMap: (geometry) ->
		material = new THREE.MeshNormalMaterial
		@map_mesh = new THREE.Mesh geometry, material
		#@map_mesh.frustumCulled = false
		@map_mesh.scale.set(.1, .1, .1)
		@scene.add @map_mesh

module.exports = Renderer