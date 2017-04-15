BIN=main

COMMON_OBJS=utils.o
CUBE_OBJS=gl_utils.o gl_platform.o shaders.o cubes.o
COMPRESSION_OBJS=compression.o
OBJS=main.o $(CUBE_OBJS) $(COMPRESSION_OBJS) $(COMMON_OBJS)

HEADERS=$(shell ls *.hpp)

HUFFMAN_SRC=huffman_decode_colors.cpp  huffman_decode_lengths.cpp  huffman_encode_colors.cpp  huffman_encode_lengths.cpp

# needs glm (`apt install libglm-dev` on rpi)

UNAME_M := $(shell uname -m)
ifeq ($(UNAME_M),armv7l)
    # RPI
    CFLAGS+=-DRPI
    #CFLAGS+=-DSTANDALONE -D__STDC_CONSTANT_MACROS -D__STDC_LIMIT_MACROS -DTARGET_POSIX -D_LINUX -fPIC -DPIC -D_REENTRANT -D_LARGEFILE64_SOURCE -D_FILE_OFFSET_BITS=64 -U_FORTIFY_SOURCE -Wall -g -DHAVE_LIBOPENMAX=2 -DOMX -DOMX_SKIP64BIT -ftree-vectorize -pipe -DUSE_EXTERNAL_OMX -DHAVE_LIBBCM_HOST -DUSE_EXTERNAL_LIBBCM_HOST -DUSE_VCHIQ_ARM -Wno-psabi
    LDFLAGS+=-L$(SDKSTAGE)/opt/vc/lib/ -lbrcmGLESv2 -lbrcmEGL -lopenmaxil -lbcm_host -lvcos -lvchiq_arm -lpthread -lrt -lm
    INCLUDES+=-I$(SDKSTAGE)/opt/vc/include/ -I$(SDKSTAGE)/opt/vc/include/interface/vcos/pthreads -I$(SDKSTAGE)/opt/vc/include/interface/vmcs_host/linux -I./ 
else
    # other (linux)
    LIBS+=-lGLESv2 -lEGL -lX11
endif

LIBS+=`pkg-config --libs python3`
CFLAGS+=-fPIC `pkg-config --cflags python3`
CPPFLAGS+=$(CFLAGS) $(INCLUDES)

default: all

run: $(BIN)
	./$(BIN)

open: run
	xdg-open img.bmp

all: $(BIN) _cubes.so _compression.so

%.o: %.cpp $(HEADERS)
	g++ -c $< $(CPPFLAGS) -g -o $@

$(BIN): $(OBJS)
	g++ -o $@ $^ $(LDFLAGS) $(LIBS)

clean:
	@rm -f $(BIN) *.o
	@rm -f img.bmp
	@rm -f shaders.cpp cubes_wrap.cpp _cubes.so cubes.py compression.py
	@rm -rf __pycache__

shaders.cpp: vertex_shader.glsl fragment_shader.glsl
	rm  -f $@
	xxd -i vertex_shader.glsl >> $@
	xxd -i fragment_shader.glsl >> $@

cubes_wrap.cpp: cubes.i
	swig -c++ -python $<
	mv cubes_wrap.cxx $@

compression_wrap.cpp: compression.i
	swig -c++ -python $<
	mv compression_wrap.cxx $@

_cubes.so: $(CUBE_OBJS) cubes_wrap.o
	g++ -o $@ $^ $(LDFLAGS) $(LIBS) -shared

_compression.so: $(OBJS) compression_wrap.o
	g++ -o $@ $^ $(LDFLAGS) $(LIBS) -shared

compression.o: compression.cpp $(HEADERS) $(HUFFMAN_SRC)
$(HUFFMAN_SRC): _cubes.so ../gen_ogl_huffman_file.py
	cd ..
	python gen_ogl_huffman_file.py
