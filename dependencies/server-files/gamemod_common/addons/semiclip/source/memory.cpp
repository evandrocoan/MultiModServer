#include "extdll.h"
#include "meta_api.h"

#include "memory.h"

#ifdef _WIN32
int lib_load_info(void *addr,lib_t *lib)
{
	MEMORY_BASIC_INFORMATION mem;
	VirtualQuery(addr,&mem,sizeof(mem));

	IMAGE_DOS_HEADER *dos = (IMAGE_DOS_HEADER*)mem.AllocationBase;
	IMAGE_NT_HEADERS *pe = (IMAGE_NT_HEADERS*)((dword)dos + (dword)dos->e_lfanew);

	if(pe->Signature != IMAGE_NT_SIGNATURE)
		return 0;

	lib->base = (char *)mem.AllocationBase;
	lib->size = (uint32_t)pe->OptionalHeader.SizeOfImage;

	return 1;
}
#else
char *lib_find_symbol(lib_t *lib,const char *symbol)
{
	return (char *)dlsym(lib->handle,symbol);
}
static ElfW(Addr) dlsize(void *base)
{
	int i;
	ElfW(Ehdr) *ehdr;
	ElfW(Phdr) *phdr;
	ElfW(Addr) end = 0;

	ehdr = (ElfW(Ehdr)*)base;
	phdr = (ElfW(Phdr)*)((ElfW(Addr))ehdr + ehdr->e_phoff);

	for(i = 0; i < ehdr->e_phnum; ++i)
	{
		if(phdr[i].p_type == PT_LOAD)
			end = phdr[i].p_vaddr + phdr[i].p_memsz;
	}
	return end;
}
int lib_load_info(void *addr,lib_t *lib)
{
	Dl_info info;
	if((!dladdr(addr,&info) && !info.dli_fbase) || !info.dli_fname)
	{
		return 0;
	}

	lib->base = (char *)info.dli_fbase;
	lib->size = (uint32_t)dlsize(info.dli_fbase);
	lib->handle = (char *)dlopen(info.dli_fname,RTLD_NOW);

	return 1;
}
#endif
static inline int mem_compare_c(const char *addr,const char *pattern,const char *pattern_end)
{
	const char *c;
	for(c = pattern; c < pattern_end; ++c, ++addr)
	{
		if(*c == *addr || *c == '\x2A')
			continue;

		return 0;
	}
	return 1;
}
static char *mem_find_ref_c(char *pos,char *end,int opcode,dword ref,int pos_byte,int relative)
{
	for(; pos < end; ++pos)
	{
		if(*pos == opcode)
		{
			if(relative)
			{
				if((dword)pos + 5 + *(dword *)(pos + pos_byte) == ref)
					return pos;
			}
			else
			{
				if(*(dword *)(pos + pos_byte) == ref)
					return pos;
			}
		}
	}
	return NULL;
}
char *lib_find_pattern_fstr(lib_t *lib,const char *string,int range,const char *pattern,int len)
{
	char *addr;
	addr = lib_find_string_push(lib,string);

	if(addr)
	{
		if(range < 0)
		{
			addr += range;
			range = -range;
		}
		return mem_find_pattern(addr,range,pattern,len);
	}
	return NULL;
}
char *mem_find_ref(char *start,int range,int opcode,dword ref,int relative)
{
	return mem_find_ref_c(start,start + range - 5,opcode,ref,1,relative);
}
char *mem_find_cmp(char *pos,int range,int ref,int pos_byte)
{
	char *end = pos + range;
	for(; pos < end; ++pos)
	{
		if(*pos == '\x83' && *(pos + pos_byte) == ref)
			return pos;
	}
	return NULL;
}
char *mem_find_pattern(char *pos,int range,const char *pattern,int len)
{
	char *end;
	const char *pattern_end;
	
	pattern_end = pattern + len;

	for(end = pos + range - len; pos < end; ++pos)
	{
		if(mem_compare_c(pos,pattern,pattern_end))
			return pos;
	}
	return NULL;
}
char *lib_find_pattern(lib_t *lib,const char *pattern,int len)
{
	return mem_find_pattern(lib->base,lib->size,pattern,len);
}
char *lib_find_string(lib_t *lib,dword opcode,const char *string)
{
	char *addr;
	addr = mem_find_pattern(lib->base,lib->size,string,strlen(string) + 1);
	return mem_find_ref_c(lib->base,lib->base + lib->size - 5,opcode,(dword)addr,1,0);
}
char *lib_find_string_push(lib_t *lib,const char *string)
{
	char *addr;
	addr = mem_find_pattern(lib->base,lib->size,string,strlen(string) + 1);
	return mem_find_ref_c(lib->base,lib->base + lib->size - 5,'\x68',(dword)addr,1,0);
}
int mem_memcpy(void *addr,void *patch,int len)
{
#ifdef _WIN32
	static HANDLE process = 0;

	DWORD OldProtection = 0;
	DWORD NewProtection = PAGE_EXECUTE_READWRITE;

	if(!process)
		process = GetCurrentProcess();

	FlushInstructionCache(process,addr,len);
	if(VirtualProtect(addr,len,NewProtection,&OldProtection))
	{
		memcpy(addr,patch,len);
		return VirtualProtect(addr,len,OldProtection,&NewProtection);
	}
#else
	uint32_t size = sysconf(_SC_PAGESIZE);
	void *alignedAddress = Align(addr);

	if(Align(addr + len - 1) != alignedAddress)
		size *= 2;

	if(!mprotect(alignedAddress,size,(PROT_READ|PROT_WRITE|PROT_EXEC)))
	{
		memcpy(addr,patch,len);
		return !mprotect(alignedAddress,size,(PROT_READ|PROT_EXEC));
	}
#endif
	return 0;
}
