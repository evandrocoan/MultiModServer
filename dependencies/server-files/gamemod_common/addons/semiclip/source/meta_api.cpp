#include "extdll.h"
#include "meta_api.h"

#include "main.h"

#undef C_DLLEXPORT

#ifdef _WIN32
	#define C_DLLEXPORT extern "C" __declspec(dllexport)
#else
	#include <sys/mman.h>
	#define C_DLLEXPORT extern "C" __attribute__((visibility("default")))
#endif

plugin_info_t Plugin_info = {
	META_INTERFACE_VERSION,
	"Semiclip",
	"2.2",
	"07/08/14",
	"s1lent",
	"http://www.aghl.ru/",
	"Semiclip",
	PT_ANYTIME,
	PT_ANYTIME,
};

meta_globals_t *gpMetaGlobals;
gamedll_funcs_t *gpGamedllFuncs;
mutil_funcs_t *gpMetaUtilFuncs;

enginefuncs_t g_engfuncs;
enginefuncs_t gpEnginefuncs_Post;
enginefuncs_t *g_pEnginefuncsTable_Post;
enginefuncs_t *gpEnginefuncInterface;

globalvars_t *gpGlobals;

DLL_FUNCTIONS gpFunctionTable;
DLL_FUNCTIONS gpFunctionTable_Post;

DLL_FUNCTIONS *g_pFunctionTable;
META_FUNCTIONS gMetaFunctionTable;

C_DLLEXPORT int GetEntityAPI2(DLL_FUNCTIONS *pFunctionTable,int *)
{
	memset(&gpFunctionTable,0,sizeof(DLL_FUNCTIONS));
	gpFunctionTable.pfnPM_Move = PM_Move;
	memcpy(pFunctionTable,&gpFunctionTable,sizeof(DLL_FUNCTIONS));
	g_pFunctionTable = pFunctionTable;
	return 1;
}
C_DLLEXPORT int GetEntityAPI2_Post(DLL_FUNCTIONS *pFunctionTable,int *)
{
	memset(&gpFunctionTable_Post,0,sizeof(DLL_FUNCTIONS));

	gpFunctionTable_Post.pfnServerActivate = ServerActivate_Post;
	gpFunctionTable_Post.pfnClientPutInServer = ClientPutInServer_Post;

	memcpy(pFunctionTable,&gpFunctionTable_Post,sizeof(DLL_FUNCTIONS));

	return 1;
}
C_DLLEXPORT int Meta_Query(char *,plugin_info_t **pPlugInfo,mutil_funcs_t *pMetaUtilFuncs)
{
	*pPlugInfo = &(Plugin_info);
	gpMetaUtilFuncs = pMetaUtilFuncs;

	return 1;
}
C_DLLEXPORT int GetEngineFunctions_Post(enginefuncs_t *pEnginefuncsTable,int *interfaceVersion)
{
	memset(&gpEnginefuncs_Post,0,sizeof(enginefuncs_t));

	if(semiclipData.time)
	{
		gpEnginefuncs_Post.pfnAlertMessage = AlertMessage;
	}

	memcpy(pEnginefuncsTable,&gpEnginefuncs_Post,sizeof(enginefuncs_t));
	g_pEnginefuncsTable_Post = pEnginefuncsTable;

	return 1;
}
C_DLLEXPORT int Meta_Attach(PLUG_LOADTIME now,META_FUNCTIONS *pFunctionTable,meta_globals_t *pMGlobals,gamedll_funcs_t *pGamedllFuncs)
{
	gpMetaGlobals = pMGlobals;
	gpGamedllFuncs = pGamedllFuncs;

	if(!OnMetaAttach())
	{
		return 0;
	}

	GET_HOOK_TABLES(PLID,&gpEnginefuncInterface,NULL,NULL);

	gMetaFunctionTable.pfnGetEntityAPI2 = GetEntityAPI2;
	gMetaFunctionTable.pfnGetEntityAPI2_Post = GetEntityAPI2_Post;
	gMetaFunctionTable.pfnGetEngineFunctions_Post = GetEngineFunctions_Post;

	memcpy(pFunctionTable,&gMetaFunctionTable,sizeof(META_FUNCTIONS));

	return 1;
}
C_DLLEXPORT int Meta_Detach(PLUG_LOADTIME now,PL_UNLOAD_REASON reason)
{
	OnMetaDetach();

	return 1;
}
#ifndef _WIN32
	C_DLLEXPORT void GiveFnptrsToDll(enginefuncs_t *pEnginefuncsTable,globalvars_t *pGlobals)
	{
#else
	#ifdef _MSC_VER
	C_DLLEXPORT __declspec(naked) void GiveFnptrsToDll(enginefuncs_t *pEnginefuncsTable,globalvars_t *pGlobals)
	{
		__asm
		{
			push ebp
			mov ebp,esp
			sub esp,__LOCAL_SIZE
			push ebx
			push esi
			push edi
		}
	#else	// _MSC_VER
		#ifdef __GNUC__
			C_DLLEXPORT void __stdcall GiveFnptrsToDll(enginefuncs_t *pEnginefuncsTable,globalvars_t *pGlobals)
			{
		#else
			#error There is no support (yet) for your compiler. Please use MSVC or GCC compilers.
		#endif
	#endif // _MSC_VER
#endif // _WIN32
		memcpy(&g_engfuncs,pEnginefuncsTable,sizeof(enginefuncs_t));
		gpGlobals = pGlobals;
		#ifdef _MSC_VER
		if(sizeof(int *) == 8)
		{
			__asm
			{
				pop edi
				pop esi
				pop ebx
				mov esp,ebp
				pop ebp
				ret 16
			}
		}
		else
		{
			__asm
			{
				pop edi
				pop esi
				pop ebx
				mov esp,ebp
				pop ebp
				ret 8
			}
		}
	#endif // #ifdef _MSC_VER
}
