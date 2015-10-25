import sys
from Struct import *
import struct

Struct = StructDecorator

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
	name = string(64, stripNulls=True)
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
	name = string(64, stripNulls=True)
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
	outvertices = []

	model = models[0]
	for face in faces[model.face:model.face+model.n_faces]:
		if face.type == 1:
			outindices += [mv.offset + len(outvertices) for mv in meshverts[face.meshvert:face.meshvert+face.n_meshverts]]
			for vert in vertices[face.vertex:face.vertex+face.n_vertices]:
				outvertices.append((
					[
						vert.position[0], 
						vert.position[2], 
						vert.position[1]
					], 
					vert.normal
				))
		elif face.type == 3:
			print 'mesh'
		else:
			print 'other', face.type

	outfp = file(ofn, 'wb')
	outfp.write(struct.pack('II', len(outindices), len(outvertices)))
	for index in outindices:
		outfp.write(struct.pack('I', index))
	for (pos, normal) in outvertices:
		outfp.write(struct.pack('ffffff', *pos+normal))
	outfp.close()

if __name__=='__main__':
	main(*sys.argv[1:])
