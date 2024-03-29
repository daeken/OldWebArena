from Struct import *
import json, sys
import numpy as np

@Struct
def Direntry():
	offset, length = int32[2]

@Struct
def Header():
	magic = string(4)
	version = int32
	direntries = Direntry()[17]

@Struct
def Texture():
	name = string(64)
	surface_flags = int32
	content_flags = int32

@Struct
def Plane():
	normal = vec3
	dist = float

@Struct
def Node():
	plane = int32
	children = int32[2]
	mins = int32[3]
	maxs = int32[3]

@Struct
def Leaf():
	cluster = int32
	area = int32
	mins = int32[3]
	maxs = int32[3]
	leafface = int32
	n_leaffaces = int32
	leafbrush = int32
	n_leafbrushes = int32

@Struct
def LeafFace():
	face = int32

@Struct
def LeafBrush():
	brush = int32

@Struct
def Model():
	mins = vec3
	maxs = vec3
	face = int32
	n_faces = int32
	brush = int32
	n_brushes = int32

@Struct
def Brush():
	brushside = int32
	n_brushsides = int32
	texture = int32

@Struct
def BrushSide():
	plane = int32
	texture = int32

@Struct
def Vertex():
	position = vec3
	texcoords = vec4
	normal = vec3
	color = uint8[4]

@Struct
def Meshvert():
	offset = int32

@Struct
def Effect(): # Called 'Fog' in the original source
	name = string(64)
	brush = int32
	visibleside = int32

@Struct
def Face():
	texture, effect, type = int32[3]
	vertex, n_vertices = int32[2]
	meshvert, n_meshverts = int32[2]
	lm_index = int32
	lm_start = int32[2]
	lm_size = int32[2]
	lm_origin = vec3
	lm_vec_S = vec3
	lm_vec_T = vec3
	normal = vec3
	size = int32[2]

# ind, verts = tesselate(face.size, fv, fmv)
# this function is directly adapted from http://media.tojicode.com/q3bsp/js/q3bsp_worker.js
def tesselate(size, verts, meshverts):
	def getPoint(c0, c1, c2, dist):
		def sub(attr):
			v0, v1, v2 = map(np.array, (getattr(c0, attr), getattr(c1, attr), getattr(c2, attr)))
			b = 1 - dist

			vc = v0 * (b * b) + v1 * (2 * b * dist) + v2 * (dist * dist)
			if attr == 'normal':
				vc /= np.linalg.norm(vc)
			setattr(outvert, attr, vc.tolist())

		outvert = Vertex()
		sub('position')
		sub('texcoords')
		sub('color')
		sub('normal')
		return outvert

	level = 5.
	L1 = int(level) + 1

	for py in xrange(0, size[1]-2, 2):
		for px in xrange(0, size[0]-2, 2):
			rowOff = py * size[0]

			c0, c1, c2 = verts[rowOff + px:rowOff + px + 3]
			rowOff += size[0]
			c3, c4, c5 = verts[rowOff + px:rowOff + px + 3]
			rowOff += size[0]
			c6, c7, c8 = verts[rowOff + px:rowOff + px + 3]

			indexOff = len(verts)

			for i in xrange(L1):
				a = i / level
				verts.append(getPoint(c0, c3, c6, a))

			for i in xrange(1, L1):
				a = i / level

				tc0 = getPoint(c0, c1, c2, a)
				tc1 = getPoint(c3, c4, c5, a)
				tc2 = getPoint(c6, c7, c8, a)

				for j in xrange(L1):
					b = j / level

					verts.append(getPoint(tc0, tc1, tc2, b))

			for row in xrange(int(level)):
				for col in xrange(int(level)):
					meshverts.append(indexOff + (row + 1) * L1 + col)
					meshverts.append(indexOff + row * L1 + col)
					meshverts.append(indexOff + row * L1 + col + 1)
					
					meshverts.append(indexOff + (row + 1) * L1 + col)
					meshverts.append(indexOff + row * L1 + col + 1)
					meshverts.append(indexOff + (row + 1) * L1 + col + 1)

	return meshverts, verts

def rewind(data):
	out = []
	for i in xrange(0, len(data), 3):
		out += [data[i+0], data[i+2], data[i+1]]
	return out

def main(fn, ofn):
	def decode(lump, cls):
		size = len(cls())
		fp.seek(header.direntries[lump].offset)
		return [cls(unpack=fp) for i in xrange(header.direntries[lump].length / size)]

	fp = file(fn, 'rb')
	header = Header(unpack=fp)

	fp.seek(header.direntries[0].offset)
	entities = fp.read(header.direntries[0].length)
	
	textures = decode(1, Texture)
	planes = decode(2, Plane)
	nodes = decode(3, Node)
	leafs = decode(4, Leaf)
	leaffaces = decode(5, LeafFace)
	leafbrushes = decode(6, LeafBrush)
	models = decode(7, Model)
	brushes = decode(8, Brush)
	brushsides = decode(9, BrushSide)
	vertices = decode(10, Vertex)
	meshverts = decode(11, Meshvert)
	effects = decode(12, Effect)
	faces = decode(13, Face)

	outindices = []
	outpositions = []
	outnormals = []

	model = models[0]
	numverts = 0
	for face in faces[model.face:model.face+model.n_faces]:
		fmv = [x.offset for x in meshverts[face.meshvert:face.meshvert+face.n_meshverts]]
		fv = vertices[face.vertex:face.vertex+face.n_vertices]
		if face.type == 1 or face.type == 3:
			outindices += [mv + numverts for mv in fmv]
			for vert in fv:
				outpositions += vert.position
				outnormals += vert.normal
			numverts += len(fv)
		elif face.type == 2:
			fmv, fv = tesselate(face.size, fv, fmv)
			outindices += [mv + numverts for mv in fmv]
			for vert in fv:
				outpositions += vert.position
				outnormals += vert.normal
			numverts += len(fv)
		elif face.type == 4:
			pass
		else:
			print 'other', face.type

	outplanes = []
	for plane in planes:
		outplanes.append(plane.normal + [plane.dist])
	outbrushes = []
	for brush in brushes[model.brush:model.brush+model.n_brushes]:
		texture = textures[brush.texture]
		# XXX: Rewrite file so non-solid brushes are nuked.
		collidable = (texture.content_flags & 1) == 1
		sides = brushsides[brush.brushside:brush.brushside+brush.n_brushsides]
		outbrushes.append([collidable, []])
		curbrush = outbrushes[-1][1]
		for side in sides:
			curbrush.append(side.plane)

	def btree(ind):
		if ind >= 0:
			node = nodes[ind]
			return [0, node.plane, node.mins, node.maxs, btree(node.children[0]), btree(node.children[1])]
		else:
			leaf = leafs[-(ind + 1)]
			return [1, leaf.mins, leaf.maxs, [x.brush for x in leafbrushes[leaf.leafbrush:leaf.leafbrush+leaf.n_leafbrushes]]]

	tree = btree(0)

	outfp = file(ofn, 'wb')
	outdata = dict(indices=rewind(outindices), vertex_positions=outpositions, vertex_normals=outnormals, planes=outplanes, brushes=outbrushes, tree=tree)
	json.dump(outdata, outfp)

if __name__=='__main__':
	main(*sys.argv[1:])
