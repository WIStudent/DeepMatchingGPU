# Path to caffe's install directory that was created by Cmake 
CAFFEDIR=/caffe_location_dir
CAFFELIB=$(CAFFEDIR)/lib

# 1: Include the location of the libcaffe.so library in the _gpudm.so library. Usefull if the CAFFEDIR is not in a standard location
# for libraries because you don't need to set the location by setting the variable LD_LIBRARY_PATH before using _gpudm.so.
# A disadvantage is, that _gpudm.so won't work anymore if you move the CAFFEDIR folder.
INCLUDE_CAFFE_LOCATION = 1

OPTFLAGS=-g -O2

# Path to python header file
INCLUDES += -I/usr/include/python2.7/
# Path to caffe's header files
INCLUDES += -I$(CAFFEDIR)/include/
# Path to hdf5's header files
INCLUDES += -I/usr/include/hdf5/serial/


#include gpudm/Makefile.config
CUDA_ARCH := \
    -gencode arch=compute_35,code=sm_35 \
    -gencode arch=compute_50,code=sm_50 \
    -gencode arch=compute_60,code=sm_60

HEADERS := $(shell find . -maxdepth 1 -name '*.hpp')
EXTRA_LAYERS := $(shell find . -maxdepth 1 -name '*.hpp')

all: _gpudm.so

_gpudm.so: gpudm_wrap.o $(EXTRA_LAYERS:.hpp=.o) $(EXTRA_LAYERS:.hpp=.cuo)
ifeq ($(INCLUDE_CAFFE_LOCATION),1)
	g++ $(OPTFLAGS) -fPIC -L$(CAFFELIB) $^ -shared -Xlinker -rpath $(CAFFELIB) -o $@ -lcaffe -lcusparse
else
	g++ $(OPTFLAGS) -fPIC -L$(CAFFELIB) $^ -o $@ -lcaffe -lcusparse
endif

%.cuo: %.cu %.hpp 
	nvcc $(CUDA_ARCH) -Xcompiler -fPIC $(INCLUDES) $(OPTFLAGS) -c $< -o $@

gpudm_wrap.cxx: gpudm.swig $(HEADERS)
	swig -cpperraswarn -python -c++ $(INCLUDES) gpudm.swig

gpudm_wrap.o: gpudm_wrap.cxx 
	g++ $(OPTFLAGS) -c gpudm_wrap.cxx -fPIC $(INCLUDES) -o gpudm_wrap.o

%.o: %.cpp %.hpp
	g++ $(OPTFLAGS) -c $< -fPIC $(INCLUDES) -L$(CAFFELIB) -o $@

clean:
	rm -f *.pyc *~ _gpudm.so gpudm_wrap.o $(EXTRA_LAYERS:.hpp=.o) $(EXTRA_LAYERS:.hpp=.cuo)

cleanswig: clean
	rm -f gpudm.py gpudm_wrap.cxx gpudm_wrap.o
