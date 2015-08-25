/**
 * (C)2003-2006 David "BAILOPAN" Anderson
 * Counter-Strike: Deathmatch
 *
 * Licensed under the GNU General Public License, version 2
 */

#ifdef WIN32
#define WINDOWS_LEAN_AND_MEAN	1
#include <windows.h>
#else
#include <dlfcn.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <unistd.h>
#endif
#include <string.h>
#include <stdio.h>
#include <stdlib.h>
#include "CSigMngr.h"

CSigMngr g_SigMngr;


bool CSigMngr::ResolveAddress(signature_t *sigmem)
{
#ifdef WIN32
	MEMORY_BASIC_INFORMATION mem;

	if (!VirtualQuery(sigmem->memInBase, &mem, sizeof(MEMORY_BASIC_INFORMATION)))
		return false;

	if (mem.AllocationBase == NULL)
		return false;

	HMODULE dll = (HMODULE)mem.AllocationBase;

	//code adapted from hullu's linkent patch
	union 
	{
		unsigned long mem;
		IMAGE_DOS_HEADER *dos;
		IMAGE_NT_HEADERS *pe;
	} dllmem;

	dllmem.mem = (unsigned long)dll;

	if (IsBadReadPtr(dllmem.dos, sizeof(IMAGE_DOS_HEADER)) || (dllmem.dos->e_magic != IMAGE_DOS_SIGNATURE))
		return false;

	dllmem.mem = ((unsigned long)dll + (unsigned long)(dllmem.dos->e_lfanew));
	if (IsBadReadPtr(dllmem.pe, sizeof(IMAGE_NT_HEADERS)) || (dllmem.pe->Signature != IMAGE_NT_SIGNATURE))
		return false;

	//end adapted hullu's code

	IMAGE_NT_HEADERS *pe = dllmem.pe;

	sigmem->allocBase = mem.AllocationBase;
	sigmem->memSize = (DWORD)(pe->OptionalHeader.SizeOfImage);

	return true;
#else
	Dl_info info;

	if (!dladdr(sigmem->memInBase, &info))
		return false;

	if (!info.dli_fbase || !info.dli_fname)
		return false;

	sigmem->allocBase = info.dli_fbase;

	pid_t pid = getpid();
	char file[255];
	char buffer[2048];
	snprintf(file, sizeof(file)-1, "/proc/%d/maps", pid);
	FILE *fp = fopen(file, "rt");
	if (!fp)
		return false;
	void *start=NULL;
	void *end=NULL;
	void *found=NULL;
	while (!feof(fp))
	{
		fgets(buffer, sizeof(buffer)-1, fp);
#if defined AMD64
		sscanf(buffer, "%Lx-%Lx", &start, &end);
#else
		sscanf(buffer, "%lx-%lx", &start, &end);
#endif

		if (start == sigmem->allocBase)
		{
			found = end;
			break;
		}
	}
	fclose(fp);

	if (!found)
		return false;

	sigmem->memSize = (unsigned long)end - (unsigned long)start;

#ifdef DEBUG
	Msg("Alloc base: %p\n", sigmem->allocBase);
#endif

	return true;
#endif
}

void *CSigMngr::ResolveSig(void *memInBase, const char *pattern, size_t siglen)
{
#if defined __linux__
	Dl_info info;

	if (!dladdr(memInBase, &info))
	{
		return NULL;
	}

	if (!info.dli_fbase || !info.dli_fname)
	{
		return NULL;
	}

	void *handle = dlopen(info.dli_fname, RTLD_NOW);
	if (handle == NULL)
	{
		return NULL;
	}

	void *addr = dlsym(handle, pattern);

	dlclose(handle);

	return addr;
#else
	signature_t sig;

	memset(&sig, 0, sizeof(signature_t));

	sig.sig = (const char *)pattern;
	sig.siglen = siglen;
	sig.memInBase = memInBase;

	if (!ResolveAddress(&sig))
		return NULL;

	const char *paddr = (const char *)sig.allocBase;
	bool found;

	register unsigned int j;

	sig.memSize -= sig.siglen;	//prevent a crash maybe?

	for (size_t i=0; i<sig.memSize; i++)
	{
		found = true;
		for (j=0; j<sig.siglen; j++)
		{
			if ( (pattern[j] != (char)0x2A) &&
				 (pattern[j] != paddr[j]) )
			{
				found = false;
				break;
			}
		}
		if (found)
		{
			sig.offset = (void *)paddr;
			break;
		}

		paddr++;
	}

	return sig.offset;
#endif
}

