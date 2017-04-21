BIN=main

COMMON_OBJS=utils.o
CUBE_OBJS=gl_utils.o gl_platform.o shaders.o cubes.o
OBJS=main.o $(CUBE_OBJS) $(COMMON_OBJS) compression.o chunker.o

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
CFLAGS+=-fPIC `pkg-config --cflags python3` -O2
CPPFLAGS+=$(CFLAGS) $(INCLUDES)

default: all

run: $(BIN)
	./$(BIN)

open: run
	xdg-open img.bmp

all: $(BIN) _cubes.so _compression.so _chunker.so

%.o: %.cpp $(HEADERS)
	g++ -c $< $(CPPFLAGS) -g -o $@

$(BIN): $(OBJS)
	g++ -o $@ $^ $(LDFLAGS) $(LIBS)

clean:
	rm -f $(BIN) *.o
	rm -f img.bmp
	rm -f shaders.cpp *_wrap.cpp _*.so cubes.py compression.py chunker.py
	rm -f $(HUFFMAN_SRC)
	rm -rf __pycache__

shaders.cpp: vertex_shader.glsl fragment_shader.glsl
	xxd -i vertex_shader.glsl > $@
	xxd -i fragment_shader.glsl >> $@

%_wrap.cpp: %.i $(HEADERS)
	swig -c++ -python -o $@ $<

_%.so: $(COMMON_OBJS) %_wrap.o %.o
	g++ -o $@ $^ $(LDFLAGS) $(LIBS) -shared

_cubes.so: $(CUBE_OBJS)
_compression.so: chunker.o
#_cubes.so: $(CUBE_OBJS) $(COMMON_OBJS) cubes_wrap.o
#	g++ -o $@ $^ $(LDFLAGS) $(LIBS) -shared
#
#_compression.so: $(COMPRESSION_OBJS) $(COMMON_OBJS)  compression_wrap.o
#	g++ -o $@ $^ $(LDFLAGS) $(LIBS) -shared
#
#_chunker.so: $(COMMON_OBJS) chunker.o chunker_wrap.o
#	g++ -o $@ $^ $(LDFLAGS) $(LIBS) -shared

compression.o: $(HUFFMAN_SRC)

$(HUFFMAN_SRC): _cubes.so _chunker.so ../gen_ogl_huffman_file.py
	cd .. && python3 gen_ogl_huffman_file.py

