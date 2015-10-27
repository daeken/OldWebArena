arrvec = (x) -> new THREE.Vector3 x[0], x[1], x[2]

parse_map = (data) ->
	console.time 'Parsing map'
	geometry = new THREE.Geometry

	indices = data.indices
	vertices = data.vertices
	tree = data.tree
	brushes = data.brushes
	planes = data.planes

	for [vert, normal] in vertices
		geometry.vertices.push arrvec vert

	for i in [0...indices.length] by 3
		geometry.faces.push new THREE.Face3(
			indices[i], indices[i+1], indices[i+2], 
			[
				arrvec(vertices[indices[i+0]][1]), 
				arrvec(vertices[indices[i+1]][1]), 
				arrvec(vertices[indices[i+2]][1])
			]
		)

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
