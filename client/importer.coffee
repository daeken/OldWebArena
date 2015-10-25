arrvec = (x) -> new THREE.Vector3 x[0], x[1], x[2]

parse_map = (data) ->
	geometry = new THREE.Geometry

	indices = data.indices
	vertices = data.vertices

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

	geometry

module.exports = {
	parse_map: parse_map
}
