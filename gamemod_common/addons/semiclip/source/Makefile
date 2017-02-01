#(C)2004-2005 AMX Mod X Development Team
# Makefile written by David "BAILOPAN" Anderson

HLSDK = sdk/hlsdk
METAMOD = sdk/metamod
M_INCLUDE = include

OPT_FLAGS = -O2 -funroll-loops -s -pipe -fomit-frame-pointer -fno-strict-aliasing
DEBUG_FLAGS = -g -ggdb3
CPP = g++
NAME = semiclip

BIN_SUFFIX_32 = mm_i386.so
BIN_SUFFIX_64 = mm_amd64.so

OBJECTS = main.cpp config.cpp memory.cpp mem_parse.cpp meta_api.cpp

LINK = 

INCLUDE = -I. -I$(M_INCLUDE)/ -I$(HLSDK)/common -I$(HLSDK)/dlls -I$(HLSDK)/engine -I$(HLSDK)/pm_shared -I$(METAMOD)

GCC_VERSION := $(shell $(CPP) -dumpversion >&1 | cut -b1)

ifeq "$(GCC_VERSION)" "4"
	OPT_FLAGS += -fvisibility=hidden -fvisibility-inlines-hidden
endif

ifeq "$(DEBUG)" "true"
	BIN_DIR = Debug
	CFLAGS = $(DEBUG_FLAGS)
else
	BIN_DIR = Release
	CFLAGS = $(OPT_FLAGS)
endif

CFLAGS += -DNDEBUG -Wall -Wno-char-subscripts -Wno-unknown-pragmas -Wno-write-strings -Wno-deprecated -Wno-non-virtual-dtor -fno-exceptions -DHAVE_STDINT_H -fno-rtti -static-libgcc -m32

ifeq "$(AMD64)" "true"
	BINARY = $(NAME)_$(BIN_SUFFIX_64)
	CFLAGS += -DPAWN_CELL_SIZE=64 -DHAVE_I64 -m64 
else
	BINARY = $(NAME)_$(BIN_SUFFIX_32)
	CFLAGS += -DPAWN_CELL_SIZE=32 -DJIT -DASM32
	OPT_FLAGS += -march=i586
endif

OBJ_LINUX := $(OBJECTS:%.cpp=$(BIN_DIR)/%.o)

$(BIN_DIR)/%.o: %.cpp
	$(CPP) $(INCLUDE) $(CFLAGS) -o $@ -c $<

all:
	mkdir -p $(BIN_DIR)
	$(MAKE) $(NAME)

amd64:
	$(MAKE) all AMD64=true

$(NAME): $(OBJ_LINUX)
	$(CPP) $(INCLUDE) $(CFLAGS) $(OBJ_LINUX) $(LINK) -shared -ldl -lm -o$(BIN_DIR)/$(BINARY)

debug:	
	$(MAKE) all DEBUG=true

default: all

clean:
	rm -rf $(BIN_DIR)/*.o
	rm -rf $(BIN_DIR)/$(NAME)_$(BIN_SUFFIX_32)
	rm -rf $(BIN_DIR)/$(NAME)_$(BIN_SUFFIX_64)
