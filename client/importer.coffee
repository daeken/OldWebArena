arrvec = (x) -> new THREE.Vector3 x[0], x[1], x[2]

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

module.exports = {
	parse_map: parse_map
}
