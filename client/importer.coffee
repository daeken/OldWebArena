parse_wam = (data) ->
		dv = new DataView data
		geometry = new THREE.Geometry

		numind = dv.getUint32 0, true
		numvert = dv.getUint32 4, true

		indices = []
		normals = []

		offset = 8
		for i in [0...numind]
			indices.push dv.getUint32 offset, true
			offset += 4
		for i in [0...numvert]
			geometry.vertices.push new THREE.Vector3(
				dv.getFloat32(offset+0, true), 
				dv.getFloat32(offset+4, true), 
				dv.getFloat32(offset+8, true), 
			)
			normals.push new THREE.Vector3(
				dv.getFloat32(offset+12, true), 
				dv.getFloat32(offset+16, true), 
				dv.getFloat32(offset+20, true), 
			)
			offset += 24
		
		for i in [0...numind] by 3
			geometry.faces.push new THREE.Face3(
				indices[i], indices[i+1], indices[i+2], 
				[
					normals[indices[i]], 
					normals[indices[i+1]], 
					normals[indices[i+2]]
				]
			)

		geometry

module.exports = {
	parse_wam: parse_wam
}
