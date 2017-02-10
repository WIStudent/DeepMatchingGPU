# Path to gpudm and libcaffe.so
CAFFEDIR=caffe
CAFFELIB=$(CAFFEDIR)/build/lib
CAFFE_BUIL_SRC=$(CAFFEDIR)/.build_release/src

# Path to google tools (protobuf, glogs)
GOOGLETOOLS=google_tools

# Path to CUDA
CUDA=/scratch/hydrus/cuda-6.5

# Path to MKL (or BLAS)
MKL=/home/clear/lear/intel/mkl

INCLUDES=-I/usr/include/python2.7 \
-I$(CAFFEDIR)/include \
-I$(CUDA)/include \
-I$(GOOGLETOOLS)/include/ \
-I$(MKL)/include \
-I$(CAFFEDIR)/include \
-I$(CAFFE_BUIL_SRC)

#include gpudm/Makefile.config
CUDA_ARCH := \
    -gencode arch=compute_35,code=sm_35 \
    -gencode arch=compute_50,code=sm_50

HEADERS := $(shell find . -name '*.hpp')
EXTRA_LAYERS := $(shell find . -name '*.hpp')

OPTFLAGS=-g -O2

all:  _gpudm.so

_gpudm.so: gpudm_wrap.o $(EXTRA_LAYERS:.hpp=.o) $(EXTRA_LAYERS:.hpp=.cuo)
	g++ $(OPTFLAGS) -fPIC $(INCLUDES) -L$(CAFFELIB) $^ -shared -o $@ -lcaffe -L$(CUDA)/lib64 -lcusparse
	CAFFEDIR=$(CAFFEDIR); GOOGLETOOLS=$(GOOGLETOOLS); CUDA=$(CUDA); MKL=$(MKL); LD_LIBRARY_PATH="$(CAFFELIB):$(CUDA)/lib64:$(MKL)/lib/intel64:/usr/lib64/openmpi/lib/:$(GOOGLETOOLS)/lib:$(LD_LIBRARY_PATH)" python -c "import gpudm"

%.cuo: %.cu %.hpp 
	$(CUDA)/bin/nvcc $(CUDA_ARCH) -Xcompiler -fPIC $(INCLUDES) $(OPTFLAGS) -c $< -o $@

gpudm_wrap.cxx: gpudm.swig $(HEADERS)
	swig -python -c++ $(INCLUDES) gpudm.swig

gpudm_wrap.o: gpudm_wrap.cxx 
	g++ $(OPTFLAGS) -c gpudm_wrap.cxx -fPIC $(INCLUDES) -o gpudm_wrap.o

%.o: %.cpp %.hpp 
	g++ $(OPTFLAGS) -c $< -fPIC $(INCLUDES) -L$(CAFFEDIR) -o $@

clean:
	rm -f *.pyc *~ _gpudm.so gpudm_wrap.o $(EXTRA_LAYERS:.hpp=.o) $(EXTRA_LAYERS:.hpp=.cuo)

cleanswig: clean
	rm -f gpudm.py gpudm_wrap.cxx gpudm_wrap.o

























