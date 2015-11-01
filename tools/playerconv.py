import json, sys
from glob import glob
from pprint import pprint
from md3conv import convert, Header

def loadSkin(fn):
	data = file(fn, 'r').read()
	return dict(line.strip().split(',', 1) for line in data.split('\n') if ',' in line and not line.strip().endswith(','))

def loadSkinClass(dir, name):
	return {
		'head' : loadSkin('%s/head_%s.skin' % (dir, name)), 
		'upper' : loadSkin('%s/upper_%s.skin' % (dir, name)), 
		'lower' : loadSkin('%s/lower_%s.skin' % (dir, name))
	}

def loadAllSkins(dir):
	names = [fn.rsplit('/', 1)[-1][5:-5] for fn in glob(dir + '/head_*.skin')]
	return {name: loadSkinClass(dir, name) for name in names}

def processFile(fn):
	fp = file(fn, 'rb')
	return convert(fp)

def main(dir, ofn=None):
	skins = loadAllSkins(dir)

	output = dict(
		lower=processFile(dir + '/lower.md3'), 
		upper=processFile(dir + '/upper.md3'), 
		head=processFile(dir + '/head.md3'), 
		skins=skins
	)
	if ofn is None:
		pprint(output)
	else:
		json.dump(output, file(ofn, 'wb'))

if __name__=='__main__':
	main(*sys.argv[1:])
