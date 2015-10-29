import sys
from pprint import pprint
from md3conv import Header

def main(id, ofn):
	fp = file(id + '/head.md3', 'rb')
	header = Header(fp)

	pprint(header.toDict())

	output = dict(

	)

	for i, frame in enumerate(header.frames):
		pass#print i, frame.name

if __name__=='__main__':
	main(*sys.argv[1:])
