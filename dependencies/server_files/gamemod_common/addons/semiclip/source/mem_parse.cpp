#include "main.h"

static lib_t lib;
static char *addr;

static int parse_radiusflash()
{
	char *addr;
	char patch[5] = { '\xE8' };

	lib_t libGameDll;
	lib_load_info((void *)MDLL_Spawn,&libGameDll);

#ifdef _WIN32
	addr = lib_find_pattern(&libGameDll,"\xE8\x2A\x2A\x2A\x2A\x68\x2A\x2A\x2A\x2A\x6A\x00\xFF\x2A\x2A\x2A\x2A\x2A\xDC\x2A\x2A\x2A\x2A\x2A\x83",25);
#else
	addr = lib_find_pattern(&libGameDll,"\x57\x52\x8D\x2A\x2A\x50\xE8\x2A\x2A\x2A\x2A\x8B\x2A\x2A\x2A\x2A\x2A\x83\x2A\x2A\x83",20);

	if(!addr)
	{
		addr = lib_find_pattern(&libGameDll,"\xC7\x2A\x2A\x2A\x2A\x2A\x2A\x2A\xE8\x2A\x2A\x2A\x2A\xC7\x2A\x2A\x2A\x2A\x2A\x2A\x2A\xC7\x2A\x2A\x2A\x2A\x2A\x2A\xFF",28);

		if(addr)
		{
			addr += 8;
		}
	}
	else addr += 6;

#endif

	if(!addr)
	{
		LOG_ERROR(PLID,"can't find \"RadiusFlash\"");
		return 0;
	}

	patchData[1].addr = (void *)addr;
	patchData[1].nSize = sizeof(patch);

	memcpy(patchData[1].bytes,addr,sizeof(patch));

	*(dword *)(patch + 1) = (dword)RadiusFlash_Handler - (dword)addr - 5;

	return mem_memcpy(addr,patch,sizeof(patch));
}
static int parse_memcpy()
{
	char *memcpy_addr;
	char patch[5] = { '\xE8' };

#ifdef _WIN32
	addr = lib_find_string_push(&lib,"Too many entities in visible packet list.\n");
#else
	addr = lib_find_symbol(&lib,"SV_WriteEntitiesToClient");
#endif

	if(!addr)
	{
		LOG_ERROR(PLID,"can't find \"SV_WriteEntitiesToClient\"");
		return 0;
	}

#ifdef _WIN32
	const char p1[] = "\xE8\x2A\x2A\x2A\x2A\x83\xC4\x0C";

	addr = mem_find_pattern(addr,512,p1,sizeof(p1) - 1);
#else
	memcpy_addr = lib_find_symbol(&lib,"Q_memcpy");

	if(!memcpy_addr)
	{
		LOG_ERROR(PLID,"can't find \"Q_memcpy\"");
		return 0;
	}

	addr = mem_find_ref(addr,960,'\xE8',(dword)memcpy_addr,1);
#endif

	if(!addr)
	{
		LOG_ERROR(PLID,"can't find \"Q_memcpy\" inside function \"SV_WriteEntitiesToClient\"");
		return 0;
	}

	patchData[0].addr = (void *)addr;
	patchData[0].nSize = sizeof(patch);

	memcpy(patchData[0].bytes,addr,sizeof(patch));

	*(dword *)(patch + 1) = (dword)Q_memcpy_Handler - (dword)addr - 5;

	return mem_memcpy(addr,patch,sizeof(patch));
}
static int parse_host_client()
{
#ifdef _WIN32
	addr = lib_find_string_push(&lib,"WARNING: reliable overflow for %s\n");

	if(!addr)
	{
		LOG_ERROR(PLID,"can't find \"host_client\" string push");
		return 0;
	}

	addr = mem_find_pattern(addr,32,"\xA1\x2A\x2A\x2A\x2A\x68",6) + 1;

	if(!addr)
	{
		LOG_ERROR(PLID,"can't find \"host_client\"");
		return 0;
	}

	global_host_client = *(char ***)addr;
#else
	addr = lib_find_symbol(&lib,"host_client");
	
	if(!addr)
	{
		LOG_ERROR(PLID,"can't find \"host_client\"");
		return 0;
	}
	global_host_client = (char **)addr;
#endif

	return 1;
}
static int patch_solid()
{
	#ifdef _WIN32
		addr = lib_find_string_push(&lib,"Trigger in clipping list");
	#else
		addr = lib_find_symbol(&lib,"SV_ClipToLinks");
	#endif

	if(!addr)
	{
		LOG_ERROR(PLID,"can't find \"SV_ClipToLinks\"");
		return 0;
	}

	addr = mem_find_cmp(addr,512,SOLID_SLIDEBOX,2);

	if(!addr)
	{
		LOG_ERROR(PLID,"can't find inside function \"SV_ClipToLinks\" cmp SOLID_SLIDEBOX");
		return 0;
	}

	char patch[3];

	patchData[2].addr = (void *)addr;
	patchData[2].nSize = sizeof(patch);

	memcpy(patch,addr,sizeof(patch));
	memcpy(patchData[2].bytes,addr,sizeof(patch));

	*(patch + 2) = SOLID_NOT;

	return mem_memcpy(addr,patch,sizeof(patch));
}
int load_parse()
{
	lib_load_info((void *)gpGlobals,&lib);

	if((semiclipData.patch && !patch_solid())
		|| (semiclipData.flashfix && !parse_radiusflash()))
	{
		return 0;
	}

	return (parse_memcpy()
		&& parse_host_client());
}
