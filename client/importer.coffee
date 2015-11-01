arrvec = (x) -> new THREE.Vector3 x[0], x[1], x[2]
arrmat3 = (x) ->
	mat = new THREE.Matrix4
	mat.elements[ 0] = x[0]
	mat.elements[ 1] = x[3]
	mat.elements[ 2] = x[6]

	mat.elements[ 4] = x[1]
	mat.elements[ 5] = x[4]
	mat.elements[ 6] = x[7]

	mat.elements[ 8] = x[2]
	mat.elements[ 9] = x[5]
	mat.elements[10] = x[8]

	mat

arrmat2quat = (x) ->
	mat = arrmat3 x
	quat = new THREE.Quaternion()
	quat.setFromRotationMatrix mat
	quat
parse_map = (data) ->
	console.time 'Parsing map'

	tree = data.tree
	brushes = data.brushes
	planes = data.planes

	indices = Uint32Array.from data.indices
	positions = Float32Array.from data.vertex_positions
	normals = Float32Array.from data.vertex_normals

	geometry = new THREE.BufferGeometry
	geometry.setIndex new THREE.BufferAttribute(indices, 1)
	geometry.addAttribute 'position', new THREE.BufferAttribute(positions, 3)
	geometry.addAttribute 'normal', new THREE.BufferAttribute(normals, 3)

	for i in [0...planes.length]
		plane = planes[i]
		planes[i] = [arrvec(plane), plane[3]]

	for [collidable, brush] in brushes
		for i in [0...brush.length]
			brush[i] = planes[brush[i]]

	deref_tree = (node) ->
		if node[0] == 0
			node[1] = planes[node[1]]
			deref_tree node[4]
			deref_tree node[5]
		else
			nbrushes = node[3]
			for i in [0...nbrushes.length]
				nbrushes[i] = brushes[nbrushes[i]]
	deref_tree tree

	console.timeEnd 'Parsing map'

	{
		geometry: geometry, 
		brushtree: tree
	}

class WAModel extends THREE.Object3D
	constructor: (data) ->
		super()

		@frameCount = data.meshes[0].frames.length
		@static = @frameCount == 1
		@frame = 0
		@meshes = []

		mat = new THREE.MeshNormalMaterial { color: 0xffffff }
		for mesh in data.meshes
			indices = Uint32Array.from mesh.indices
			framePositions = []
			frameNormals = []
		
			for frame in mesh.frames
				positions = Float32Array.from frame[0]
				normals = new Float32Array frame[0].length
				offset = 0
				for i in [0...frame[1].length] by 2
					lat = frame[1][i] * 2 * Math.PI / 255
					long = frame[1][i+1] * 2 * Math.PI / 255
					normals[offset++] = Math.cos(long) * Math.sin(lat)
					normals[offset++] = Math.sin(long) * Math.sin(lat)
					normals[offset++] = Math.cos(lat)
				framePositions.push positions
				frameNormals.push normals

			geometry = new THREE.BufferGeometry
			geometry.setIndex new THREE.BufferAttribute(indices, 1)
			geometry.addAttribute 'position', new THREE.BufferAttribute(positions, 3)
			geometry.addAttribute 'normal', new THREE.BufferAttribute(normals, 3)

			mesh = new THREE.Mesh geometry, mat
			mesh.framePositions = framePositions
			mesh.frameNormals = frameNormals
			@add mesh
			@meshes.push mesh

		@tags = data.tags
		for name, value of @tags
			@tags[name] = value.map (x) -> [arrvec(x[0]), arrmat2quat(x[1])]
		@tagpoints = []

	attach: (tag, model) ->
		attachment = new THREE.Object3D
		attachment.add model
		@add attachment
		@tagpoints.push [tag, attachment, model]

	update: ->
		@frame = (10) % @frameCount
		for mesh in @meshes
			pos = mesh.geometry.getAttribute 'position'
			normal = mesh.geometry.getAttribute 'normal'
			pos.array = mesh.framePositions[@frame]
			normal.array = mesh.frameNormals[@frame]
			pos.needsUpdate = true
			normal.needsUpdate = true
		for [tag, attachment, model] in @tagpoints
			model.update()
			[pos, tx] = model.tags[tag][if model.static then 0 else @frame]
			model.position.copy pos.clone().invert()
			model.quaternion.copy tx.clone().inverse()
			[pos, tx] = @tags[tag][@frame]
			attachment.position.copy pos
			attachment.quaternion.copy tx.clone().inverse()

parse_playermodel = (data) ->
	lower_model = new WAModel data.lower
	upper_model = new WAModel data.upper
	head_model = new WAModel data.head

	upper_model.attach 'tag_head', head_model
	lower_model.attach 'tag_torso', upper_model
	lower_model.update()

	lower_model

module.exports = {
	parse_map: parse_map, 
	parse_model: WAModel, 
	parse_playermodel: parse_playermodel
}
