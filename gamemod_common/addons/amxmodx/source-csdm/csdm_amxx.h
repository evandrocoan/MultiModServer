#ifndef _INCLUDE_CSDM_AMXX_H
#define _INCLUDE_CSDM_AMXX_H

#define	MAX_ENTITIES		2000

#define CSDM_FFA_ENABLE		3
#define CSDM_FFA_DISABLE	2
#define CSDM_ENABLE			1
#define CSDM_DISABLE		0
#define EntityPevOffset 4

extern int g_PreDeath;
extern int g_PostDeath;
extern int g_SpawnMethod;
extern int g_PreSpawn;
extern int g_PostSpawn;
extern int g_RoundRestart;
extern int g_StateChange;
extern int g_InitFwd;
extern int g_CfgInitFwd;
extern int g_IntroMsg;
extern int g_RemoveWeapon;
extern float g_SpawnWaitTime;
extern bool g_ffa_state;
extern bool g_load_okay;
extern cvar_t *csdm_active;
extern cvar_t *mp_freeforall;
extern AMX_NATIVE_INFO g_CsdmNatives[];

void DeathHandler(int pk, int pv, int hs, const char *wp, bool post);
void SpawnHandler(int pk, bool fake);
void SetActive(bool active);
#ifdef __linux__
void RestartRound( void* pGameRules );
#else
void RestartRound();
#endif
void ResetHUD(edict_t *pEdict);

inline bool IsActive()
{
	return ( (int)csdm_active->value != 0 );
}

#endif //_INCLUDE_CSDM_AMXX_H
