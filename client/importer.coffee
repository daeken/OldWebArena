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

		@static = data.meshes[0].frames.length == 1
		if 100 <= data.meshes[0].frames.length
			@frame = 91
		else
			@frame = 0

		mat = new THREE.MeshNormalMaterial { color: 0xffffff }
		
		for mesh in data.meshes
			indices = Uint32Array.from mesh.indices
			positions = Float32Array.from mesh.frames[@frame][0]
			normals = new Float32Array mesh.frames[@frame][0].length
			offset = 0
			for i in [0...mesh.frames[@frame][1].length] by 2
				lat = mesh.frames[@frame][1][i] * 2 * Math.PI / 255
				long = mesh.frames[@frame][1][i+1] * 2 * Math.PI / 255
				normals[offset++] = Math.cos(long) * Math.sin(lat)
				normals[offset++] = Math.sin(long) * Math.sin(lat)
				normals[offset++] = Math.cos(lat)

			geometry = new THREE.BufferGeometry
			geometry.setIndex new THREE.BufferAttribute(indices, 1)
			geometry.addAttribute 'position', new THREE.BufferAttribute(positions, 3)
			geometry.addAttribute 'normal', new THREE.BufferAttribute(normals, 3)

			mesh = new THREE.Mesh geometry, mat
			@add mesh

		@tags = data.tags
		for name, value of @tags
			@tags[name] = value.map (x) -> [arrvec(x[0]), arrmat3(x[1])]
		@tagpoints = []

	attach: (tag, model) ->
		attachment = new THREE.Object3D
		attachment.add model
		@add attachment
		@tagpoints.push [tag, attachment, model]

		@updatePositions()

	updatePositions: ->
		for [tag, attachment, model] in @tagpoints
			[pos, tx] = model.tags[tag][if model.static then 0 else @frame]
			model.position.copy pos
			#model.quaternion.copy tx
			[pos, tx] = @tags[tag][@frame]
			attachment.position.copy pos
			#attachment.quaternion.copy tx

parse_playermodel = (data) ->
	upper_model = new WAModel data.upper
	lower_model = new WAModel data.lower
	head_model = new WAModel data.head

	upper_model.attach 'tag_head', head_model
	upper_model.attach 'tag_torso', lower_model

	upper_model

module.exports = {
	parse_map: parse_map, 
	parse_model: WAModel, 
	parse_playermodel: parse_playermodel
}
