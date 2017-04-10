BIN=main
OBJS=main.o gl_utils.o gl_platform.o utils.o

# needs glm (`apt install libglm-dev` on rpi)

UNAME_M := $(shell uname -m)

ifeq ($(UNAME_M),armv7l)
    # RPI
    CFLAGS+=-DRPI
    #CFLAGS+=-DSTANDALONE -D__STDC_CONSTANT_MACROS -D__STDC_LIMIT_MACROS -DTARGET_POSIX -D_LINUX -fPIC -DPIC -D_REENTRANT -D_LARGEFILE64_SOURCE -D_FILE_OFFSET_BITS=64 -U_FORTIFY_SOURCE -Wall -g -DHAVE_LIBOPENMAX=2 -DOMX -DOMX_SKIP64BIT -ftree-vectorize -pipe -DUSE_EXTERNAL_OMX -DHAVE_LIBBCM_HOST -DUSE_EXTERNAL_LIBBCM_HOST -DUSE_VCHIQ_ARM -Wno-psabi

    LDFLAGS+=-L$(SDKSTAGE)/opt/vc/lib/ -lbrcmGLESv2 -lbrcmEGL -lopenmaxil -lbcm_host -lvcos -lvchiq_arm -lpthread -lrt -lm -L$(SDKSTAGE)/opt/vc/src/hello_pi/libs/ilclient -L$(SDKSTAGE)/opt/vc/src/hello_pi/libs/vgfont

    INCLUDES+=-I$(SDKSTAGE)/opt/vc/include/ -I$(SDKSTAGE)/opt/vc/include/interface/vcos/pthreads -I$(SDKSTAGE)/opt/vc/include/interface/vmcs_host/linux -I./ -I$(SDKSTAGE)/opt/vc/src/hello_pi/libs/ilclient -I$(SDKSTAGE)/opt/vc/src/hello_pi/libs/vgfont
else
    # other (linux)
    LIBS+=-lGLESv2 -lEGL
endif

CPPFLAGS+=$(CFLAGS) $(INCLUDES)

run: $(BIN)
	./$(BIN)

open: run
	xdg-open img.bmp

all: $(BIN)

%.o: %.cpp
	g++ -c $< $(CPPFLAGS) -g -o $@

$(BIN): $(OBJS)
	g++ -o $@ $^ $(LDFLAGS) $(LIBS)

clean:
	@rm -f $(BIN) $(OBJS)
	@rm -f img.bmp

