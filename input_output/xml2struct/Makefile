BOOST ?= /usr/local/opt/boost/include
CC ?= c++
CXX ?= c++
LD ?= c++
mexext := $(shell mexext)

all: xml2struct.${mexext}

xml2struct.${mexext}: xml2struct.cc | rapidxml
	mex CC=${CC} CXX=${CXX} LD=${LD} -I./rapidxml -I${BOOST} $<

rapidxml:
	mkdir -p rapidxml && wget -O - http://iweb.dl.sourceforge.net/project/rapidxml/rapidxml/rapidxml%201.13/rapidxml-1.13.zip | tar -C rapidxml -zx --strip-components 1

clean:
	-rm *.${mexext}

distclean: clean
	-rm -r rapidxml

test:
	matlab -nojvm -r "tic; disp(xml2struct('test.xml')); toc; exit"
