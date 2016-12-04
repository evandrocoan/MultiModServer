#ifndef _MEMORY_H_
#define _MEMORY_H_

#include <string.h>

#ifdef _WIN32
	#include <windows.h>
	#include <psapi.h>
#else
	#include <dlfcn.h>
	#include <unistd.h>
	//#include <sys/types.h>
	#include <sys/stat.h>
	#include <sys/mman.h>
	#include <link.h>

	#define Align(addr) ((void *)(((dword)addr) & ~(sysconf(_SC_PAGESIZE) - 1)))
#endif

//#include "extdll.h"
//#include "meta_api.h"
#include "types.h"

struct lib_t
{
	char *base;
	size_t size;
	char *handle;
};

int lib_load_info(void *addr,lib_t *lib);
int mem_memcpy(void *addr,void *patch,int len);

char *lib_find_string_push(lib_t *lib,const char *string);
char *lib_find_string(lib_t *lib,dword opcode,const char *string);

char *mem_find_cmp(char *pos,int range,int ref,int pos_byte);
char *mem_find_ref(char *start,int range,int opcode,dword ref,int relative);
char *mem_find_pattern(char *pos,int range,const char *pattern,int len);
char *lib_find_pattern(lib_t *lib,const char *pattern,int len);
char *lib_find_pattern_fstr(lib_t *lib,const char *string,int range,const char *pattern,int len);

#ifndef _WIN32
	char *lib_find_symbol(lib_t *lib,const char *symbol);
#endif

#endif //_MEMORY_H_
