#include "amxxmodule.h"
#include "csdm_amxx.h"
#include "csdm_spawning.h"
#include "csdm_util.h"
#include "csdm_player.h"
#include "csdm_timer.h"
#include "csdm_tasks.h"


int g_PreDeath = -1;
int g_PostDeath = -1;
int g_PreSpawn = -1;
int g_PostSpawn = -1;
int g_RoundRestart = -1;
int g_StateChange = -1;
int g_CfgInitFwd = -1;
int g_IntroMsg = 1;
int g_RemoveWeapon = -1;
float g_SpawnWaitTime = 0.7;
int g_InitFwd = -1;
bool g_ffa_state = false;

void DeathHandler(int pk, int pv, int hs, const char *wp, bool post)
{
	int team = GetPlayerTeam(pv);
	if (team == TEAM_T || team == TEAM_CT)
	{
		if (!post)
		{
			//we're not post.  let the plugins know he's just died. 
			//we also don't care about the return value
			if (g_PreDeath >= 0)
				MF_ExecuteForward(g_PreDeath, (cell)pk, (cell)pv, (cell)hs, wp);
		} else {
			//we're post.  death has been settled.
			bool spawn = true;
			if (g_PostDeath >= 0)
			{
				if (MF_ExecuteForward(g_PostDeath, (cell)pk, (cell)pv, (cell)hs, wp) > 0)
					spawn = false;
			}
			if (spawn)
			{
				RespawnPlayer(MF_GetPlayerEdict(pv));
			}
		}
	}
}

void SpawnHandler(int pk, bool fake)
{
	if (g_SpawnMethod != -1)
	{
		SpawnMethod *pSpawn = g_SpawnMngr.GetSpawn(g_SpawnMethod);

		if (pSpawn)
		{
			pSpawn->Spawn(pk, fake ? 1 : 0);
		}
	}

	if (g_PostSpawn >= 0)
	{
		MF_ExecuteForward(g_PostSpawn, (cell)pk, (cell)(fake ? 1 : 0));
	}
}

bool g_load_okay = false;

void OnAmxxAttach()
{
	if (InitUtilCode())
	{
		MF_AddNatives(g_CsdmNatives);
		g_load_okay = true;
	} else {
		g_load_okay = false;
	}
}

void OnAmxxDetach()
{
}

void OnPluginsLoaded()
{
	if (g_load_okay)
	{
		g_PreDeath = MF_RegisterForward("csdm_PreDeath", ET_IGNORE, FP_CELL, FP_CELL, FP_CELL, FP_STRING, FP_DONE);
		g_PostDeath = MF_RegisterForward("csdm_PostDeath", ET_STOP, FP_CELL, FP_CELL, FP_CELL, FP_STRING, FP_DONE);
		g_PreSpawn = MF_RegisterForward("csdm_PreSpawn", ET_STOP, FP_CELL, FP_CELL, FP_DONE);
		g_PostSpawn = MF_RegisterForward("csdm_PostSpawn", ET_STOP, FP_CELL, FP_CELL, FP_DONE);
		g_RoundRestart = MF_RegisterForward("csdm_RoundRestart", ET_IGNORE, FP_CELL, FP_DONE);
		g_StateChange = MF_RegisterForward("csdm_StateChange", ET_IGNORE, FP_CELL, FP_DONE);
		g_InitFwd = MF_RegisterForward("csdm_Init", ET_IGNORE, FP_STRING, FP_DONE);
		g_CfgInitFwd = MF_RegisterForward("csdm_CfgInit", ET_IGNORE, FP_DONE);
		g_RemoveWeapon = MF_RegisterForward("csdm_RemoveWeapon", ET_STOP, FP_CELL, FP_CELL, FP_CELL, FP_DONE);
	}
}

void OnPluginsUnloaded()
{
	g_SpawnMethod = -1;
}

#ifdef __linux__
void RestartRound( void* pGameRules )
#else
void RestartRound()
#endif
{
#ifdef __linux__
	if( RestartRoundHook->Restore() )
	{
		RestartRoundOrig( pGameRules );
		RestartRoundHook->Patch();
	}
#endif

	if (!IsActive())
		return;

	RestartRoundTask *pTask = new RestartRoundTask();

	g_Timer.AddTask(pTask, 0.1);
}

extern "C" void __cxa_pure_virtual(void)
{
}

