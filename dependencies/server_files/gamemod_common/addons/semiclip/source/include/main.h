#ifndef _MAIN_H
#define _MAIN_H

#include "types.h"
#include "memory.h"

#include "extdll.h"
#include "meta_api.h"

#include "pm_defs.h"
#include "entity_state.h"

#define MIN_AMOUNT			100.0f

#define FLOAT_CROUCH			49.9f
#define MAX_CLIENTS			32

#define GET_DISTANCE(a,b)		((a - b).Length2D())
#define GET_COLLIDE(a,b)		(abs(a.z - b.z) < 96 && (a - b).Length2D() < 96)

#define NUM_FOR_TEAM_ID(e)		(*((int *)e->pvPrivateData + OFFSET_TEAM_ID))

#define NUM_FOR_EDICT(e)		((int)(e - nullEdict))
#define EDICT_NUM(e)			((edict_t *)(nullEdict + e))

#ifdef _WIN32
	#define OFFSET_TEAM_ID 114
	#define OFFSET_EDICT_CL 19356

	#define OFFSET_FLASH_UNTIL 514
	#define OFFSET_FLASH_AT 515
	#define OFFSET_FLASH_HOLD_TIME 516
	#define OFFSET_FLASH_DURATION 517
	#define OFFSET_FLASH_ALPHA 518

#else
	#define OFFSET_TEAM_ID 119
	#define OFFSET_EDICT_CL 19076

	#define OFFSET_FLASH_UNTIL 519
	#define OFFSET_FLASH_AT 520
	#define OFFSET_FLASH_HOLD_TIME 521
	#define OFFSET_FLASH_DURATION 522
	#define OFFSET_FLASH_ALPHA 523
#endif

typedef enum
{
	READ_IN_GAME = 0,
	READ_START
} TypeRead;

typedef struct semiclip_s
{
	bool dont;
	float diff[MAX_CLIENTS + 1];
	bool solid[MAX_CLIENTS + 1];
	bool crouch[MAX_CLIENTS + 1];
} semiclip_t;

typedef struct screenfade_s
{
	unsigned short duration;
	unsigned short holdTime;
	short fadeFlags;
	byte r,g,b,a;
} screenfade_t;

typedef struct patch_s
{
	void *addr;
	char bytes[5];
	int nSize;
} patch_t;

typedef struct semiclipData_s
{
	float count;

	float time;
	float distance;

	int team;
	int patch;
	int crouch;
	int effects;
	int flashfix;
	int noteamflash;
	int transparency;

	int semiclip;

} semiclipData_t;

int load_config();

void print_settings();

int parse_settings(const char *cvar,const char *value,TypeRead iType);

int OnMetaAttach();

void OnMetaDetach();

void SVR_SemiclipOption();

void ClientPutInServer_Post(edict_t *pEdict);

void PM_Move(playermove_t *pmove,int);

void AlertMessage(ALERT_TYPE atype, char *szFmt, ...);

void ServerActivate_Post(edict_t *pEdictList,int edictCount,int clientMax);

void *Q_memcpy_Handler(void *_Dst,entity_state_t *_Src,uint32_t _Size);

void RadiusFlash_Handler(Vector vecSrc,entvars_t *pevInflictor,entvars_t *pevAttacker,float flDamage);

extern bool g_bNotActive;

extern char **global_host_client;

extern patch_t patchData[];

extern semiclipData_t semiclipData;

extern DLL_FUNCTIONS *g_pFunctionTable;

extern enginefuncs_t *g_pEnginefuncsTable_Post;

extern enginefuncs_t *gpEnginefuncInterface;

#endif //_MAIN_H
