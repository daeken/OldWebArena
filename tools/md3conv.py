import sys
from Struct import *
import struct

@Struct
def Frame():
	mins, maxs = vec3, vec3
	local_origin = vec3
	radius = float
	name = string(16)

@Struct
def Tag():
	name = string(64)
	origin = vec3
	axis = float[9]

@Struct
def Shader():
	name = string(64)
	index = uint32

@Struct
def Triangle():
	indices = int32[3]

@Struct
def TexCoord():
	st = float[2]

@Struct
def Vertex():
	coord = int16[3]
	normal = uint8[2]

@Struct
def Surface(self):
	magic = string(4)
	name = string(64)
	flags = int32
	num_frames, num_shaders, num_verts, num_triangles = uint32[4]
	ofs_triangles, ofs_shaders, ofs_st, ofs_xyznormal, ofs_end = uint32[5]

	with struct_seek(self.ofs_shaders, STRUCT_RELATIVE):
		shaders = Shader()[self.num_shaders]
	with struct_seek(self.ofs_triangles, STRUCT_RELATIVE):
		triangle = Triangle()[self.num_triangles]
	with struct_seek(self.ofs_st, STRUCT_RELATIVE):
		texcoords = TexCoord()[self.num_verts]
	with struct_seek(self.ofs_xyznormal, STRUCT_RELATIVE):
		vertices = Vertex()[lambda self: self.num_frames * self.num_verts]
	struct_seek(self.ofs_end, STRUCT_RELATIVE)

@Struct
def Header(self):
	magic = string(4)
	version = int32
	name = string(64)
	flags = int32
	num_frames, num_tags, num_surfaces, num_skins = uint32[4]
	ofs_frames, ofs_tags, ofs_surfaces, ofs_eof = uint32[4]

	with struct_seek(self.ofs_frames, STRUCT_RELATIVE):
		frames = Frame()[self.num_frames]
	with struct_seek(self.ofs_tags, STRUCT_RELATIVE):
		tags = Tag()[self.num_tags]
	with struct_seek(self.ofs_surfaces, STRUCT_RELATIVE):
		surfaces = Surface()[self.num_surfaces]
	struct_seek(self.ofs_eof, STRUCT_RELATIVE)

def main(fn, ofn):
	fp = file(fn, 'rb')
	header = Header(fp)
	print header

if __name__=='__main__':
	main(*sys.argv[1:])
