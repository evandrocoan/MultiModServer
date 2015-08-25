# Console command(s) for compiling on Cygwin/MinGW:
#   Example Cygwin: make HOST=cygwin
# 	http://www.xake.dk/target/tools.html

MODNAME = csdm_amxx
SRCFILES = amxxmodule.cpp csdm_amxx.cpp csdm_config.cpp csdm_message.cpp	\
	csdm_mm.cpp csdm_natives.cpp csdm_player.cpp csdm_spawning.cpp \
	csdm_tasks.cpp csdm_timer.cpp csdm_util.cpp CSigMngr.cpp

RESFILE = csdm.rc

EXTRA_LIBS_LINUX =
EXTRA_LIBS_WIN32 =
EXTRA_LIBDIRS_LINUX = -Lextra/lib_linux
EXTRA_LIBDIRS_WIN32 = -Lextra/lib_win32

#EXTRA_FLAGS = -Dstrcmpi=strcasecmp

SDKTOP = ../hlsdk
SDKSRC = $(SDKTOP)/multiplayer
METADIR = ../metamod/metamod
SRCDIR=.

OBJDIR_LINUX=obj.linux
OBJDIR_WIN32=obj.win32

ifeq "$(shell uname | cut -d _ -f1)" "CYGWIN"
	HOST=cygwin
endif

ifdef ComSpec
	ifeq "$(HOST)" "cygwin"
		OS=LINUX
		MCPU=-mcpu
		PATH_WIN=/usr/local/cross-tools/i386-mingw32msvc/bin
		CLEAN=clean_linux
	else
		OS=WIN32
		MCPU=-mtune
		PATH_WIN=/mingw/bin
		CLEAN=clean_win32
	endif
else
	ifdef COMSPEC
		ifeq "$(HOST)" "cygwin"
			OS=LINUX
			MCPU=-mcpu
			PATH_WIN=/usr/local/cross-tools/i386-mingw32msvc/bin
			CLEAN=clean_linux
		else
			OS=WIN32
			MCPU=-mtune
			PATH_WIN=/mingw/bin
			CLEAN=clean_msys_w32
		endif
	else
		OS=LINUX
		PATH_WIN=/usr/local/cross-tools/i386-mingw32msvc/bin
		CLEAN=clean_linux
	endif
endif

ifeq "$(HOST)" "cygwin"
	ifeq "$(ARCH)" "amd64"
		CC_LINUX=gcc-linux-x86_64
	else
#		CC_LINUX=gcc-linux
		CC_LINUX=gcc-linux-4.1
	endif
else
	ifeq "$(ARCH)" "amd64"
		CC_LINUX=gcc-x86_64
	else
		CC_LINUX=gcc
	endif
endif

ifeq "$(OS)" "LINUX"
	INSTALL=install -m 644
	LD_WINDLL= PATH=$(PATH_WIN) $(PATH_WIN)/dllwrap
	DEFAULT=linux
else	# WIN32
	INSTALL=cp
	CC_WIN32=g++
	LD_WINDLL= dllwrap
	DEFAULT=win32
endif

RES_WIN32=windres

# optimisation level; overridden for certain problematic files
OPT_FLAGS = -O2 -funroll-loops -s -pipe -fomit-frame-pointer
#DEBUG_FLAGS = -g -ggdb3

CFLAGS = -DNDEBUG -Wno-deprecated -fno-exceptions -DHAVE_STDINT_H -Dstricmp=strcasecmp -fno-rtti -Dstrcmpi=strcasecmp -D_snprintf=snprintf -Wall -Wno-unknown-pragmas -Wno-non-virtual-dtor
# -fPIC -static-libgcc


# Just call everything i386 unless its a 64bit binary!
ifeq "$(ARCH)" "amd64"
	LIBFILE_LINUX = $(MODNAME)_amd64.so
	CFLAGS += -DPAWN_CELL_SIZE=64 -DHAVE_I64 -m64 
else
	LIBFILE_LINUX = $(MODNAME)_i386.so
	CFLAGS += -DPAWN_CELL_SIZE=32 -DJIT -DASM32
endif

ifeq "$(OS)" "WIN32"
	CFLAGS += -DPAWN_CELL_SIZE=32 -DJIT -DASM32
endif

LIBFILE_WIN32 = $(MODNAME).dll
TARGET_LINUX = $(OBJDIR_LINUX)/$(LIBFILE_LINUX)
TARGET_WIN32 = $(OBJDIR_WIN32)/$(LIBFILE_WIN32)

FILES_ALL = *.cpp *.h [A-Z]* *.rc
ifeq "$(OS)" "LINUX"
#	ASRCFILES := $(shell ls -t $(SRCFILES))
else
#	ASRCFILES := $(shell dir /b)
endif

OBJ_LINUX := $(SRCFILES:%.cpp=$(OBJDIR_LINUX)/%.o)
OBJ_WIN32 := $(SRCFILES:%.cpp=$(OBJDIR_WIN32)/%.o)
RES_OBJ_WIN32 := $(RESFILE:%.rc=$(OBJDIR_WIN32)/%.o)

# architecture tuning by arch type
ifeq "$(ARCH)" "amd64"
	CCOPT_ARCH =
else
	CCOPT_ARCH = -march=i586
endif

CCOPT = $(OPT_FLAGS) $(CCOPT_ARCH)
CFLAGS:=$(CCOPT) $(CFLAGS)

INCLUDEDIRS= -I$(SRCDIR) -I$(METADIR) -I$(SDKSRC)/engine -I$(SDKSRC)/common -I$(SDKSRC)/pm_shared -I$(SDKSRC)/game_shared -I$(SDKSRC)/dlls -I$(SDKSRC) $(EXTRA_INCLUDEDIRS)

#$(OBJ_LINUX)
#	$(CPP) $(INCLUDE) $(CFLAGS) $(OBJ_LINUX) $(LINK) -shared -ldl -lm -o$(BIN_DIR)/$(BINARY) 

DO_CC_LINUX=$(CC_LINUX) $(CFLAGS) -fPIC $(INCLUDEDIRS) -o $@ -c $<
DO_CC_WIN32=$(CC_WIN32) $(CFLAGS) $(INCLUDEDIRS) -DWIN32 -o $@ -c $<
DO_RES_WIN32=$(RES_WIN32) -I$(SRCDIR) -I$(METADIR) -i $< -O coff -o $@
#LINK_LINUX=$(CC_LINUX) $(CFLAGS) -shared -ldl -lm -static-libgcc $(OBJ_LINUX) $(EXTRA_LIBDIRS_LINUX) $(EXTRA_LIBS_LINUX) -s -o $@
LINK_LINUX=$(CC_LINUX) $(CFLAGS) -shared -ldl -lm $(OBJ_LINUX) $(EXTRA_LIBDIRS_LINUX) $(EXTRA_LIBS_LINUX) -s -o $@
LINK_WIN32=$(CC_WIN32) -mdll -Xlinker --add-stdcall-alias $(OBJ_WIN32) $(RES_OBJ_WIN32) $(EXTRA_LIBDIRS_WIN32) $(EXTRA_LIBS_WIN32) -s -o $@


$(OBJDIR_LINUX)/%.o: $(SRCDIR)/%.cpp
	$(DO_CC_LINUX)

$(OBJDIR_WIN32)/%.o: $(SRCDIR)/%.cpp
	$(DO_CC_WIN32)

# compiling windows resource file
$(OBJDIR_WIN32)/%.o: $(SRCDIR)/%.rc $(INFOFILES)
	$(DO_RES_WIN) 

# compiling windows resource file
$(OBJDIR_WIN32)/%.o: $(SRCDIR)/%.rc
	$(DO_RES_WIN32)

default: $(DEFAULT)

$(TARGET_LINUX): $(OBJDIR_LINUX) $(OBJ_LINUX)
	$(LINK_LINUX)

$(TARGET_WIN32): $(OBJDIR_WIN32) $(OBJ_WIN32) $(RES_OBJ_WIN32)
	$(LINK_WIN32)


$(OBJDIR_LINUX):
	mkdir $@

$(OBJDIR_WIN32):
	mkdir $@

win32: $(TARGET_WIN32)

linux: $(TARGET_LINUX)
	
clean: $(CLEAN)

clean_linux:
	test -n "$(OBJDIR_LINUX)"
	-rm -f $(OBJDIR_LINUX)/*.o

clean_win32:
	-if exist $(OBJDIR_WIN32)\*.o del /q $(OBJDIR_WIN32)\*.o
	
clean_msys_w32:
	test -n "$(OBJDIR_WIN32)"
	-rm -f $(OBJDIR_WIN32)/*.o
	
clean_both: clean_linux clean_win32
