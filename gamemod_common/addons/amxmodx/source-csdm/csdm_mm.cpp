#include "amxxmodule.h"
#include "csdm_amxx.h"
#include "csdm_message.h"
#include "csdm_timer.h"
#include "csdm_config.h"
#include "csdm_player.h"
#include "csdm_util.h"
#include "csdm_tasks.h"
#include "csdm_spawning.h"

#define	FRAMEWAIT	2.0f

#define GETINFOKEYBUFFER				(*g_engfuncs.pfnGetInfoKeyBuffer)
#define	SETCLIENTKEYVALUE				(*g_engfuncs.pfnSetClientKeyValue)
#define GETCLIENTKEYVALUE				(*g_engfuncs.pfnInfoKeyValue)

Message g_Msg;
FakeCommand g_FakeCmd;
int g_DeathMsg = 0;
int g_ShowMenuMsg = 0;
int g_CurMsg = 0;
int g_VGUIMenuMsg = 0;
int g_CurPostMsg = 0;
float g_LastTime;
bool g_First = true;
edict_t *pTarget = NULL;
float g_LastScore = 0.0f;
float g_LastHudReset = 0.0f;
int g_HudResets = 0;
int g_HudsNeeded = 0;

cvar_t init_csdm_active = {"csdm_active", "1", FCVAR_SERVER|FCVAR_SPONLY};
cvar_t init_csdm_version = {"csdm_version", MODULE_VERSION, FCVAR_SERVER|FCVAR_SPONLY};
cvar_t init_mp_freeforall = {"mp_freeforall", "0", FCVAR_SERVER|FCVAR_SPONLY};

cvar_t *csdm_active = NULL;
cvar_t *csdm_version = NULL;
cvar_t *mp_freeforall = NULL;
edict_t *pLastCliKill = NULL;

void csdm_version_cmd()
{
	print_srvconsole("[CSDM] Version %s (C)2003-2013 David \"BAILOPAN\" Anderson\n", MODULE_VERSION);
	print_srvconsole("[CSDM] Written by the CSDM Team (BAILOPAN and Freecode), edited by KWo\n");
	print_srvconsole("[CSDM] http://www.bailopan.net/\n");
}

void OnMetaAttach()
{
	CVAR_REGISTER(&init_csdm_active);
	CVAR_REGISTER(&init_csdm_version);
	CVAR_REGISTER(&init_mp_freeforall);

	csdm_active = CVAR_GET_POINTER(init_csdm_active.name);
	csdm_version = CVAR_GET_POINTER(init_csdm_version.name);
	mp_freeforall = CVAR_GET_POINTER(init_mp_freeforall.name);

	g_LastTime = gpGlobals->time;

	REG_SVR_COMMAND("csdm", csdm_version_cmd);
}

void OnMetaDetach()
{
	ClearAllTaskCaches();
}

bool g_already_ran = false;

void ServerDeactivate_Post()
{
	g_Timer.Clear();
	g_Config.Clear();
	g_SpawnMngr.Clear();
	g_already_ran = false;

	RETURN_META(MRES_IGNORED);
}

void SetActive(bool active)
{
	if (active)
	{
		csdm_active->value = 1;
	} else {
		csdm_active->value = 0;
	}
	MF_ExecuteForward(g_StateChange, (active) ? CSDM_ENABLE : CSDM_DISABLE);
}

void ClientKill(edict_t *pEdict)
{
	pLastCliKill = pEdict;

	RETURN_META(MRES_IGNORED);
}

int DispatchSpawn_Post(edict_t *pEdict)
{
	if (g_already_ran)
		RETURN_META_VALUE(MRES_IGNORED, 0);

	g_already_ran = true;

	g_LastTime = gpGlobals->time;

	ClearAllPlayers();

	if (!g_load_okay)
	{
		MF_Log("CSDM failed to load, contact author...");
		MF_ExecuteForward(g_InitFwd, "");
		RETURN_META_VALUE(MRES_IGNORED, 0);
	}

	MF_ExecuteForward(g_InitFwd, MODULE_VERSION);
	MF_ExecuteForward(g_CfgInitFwd);

	char file[255];
	MF_BuildPathnameR(file, sizeof(file)-1, "%s/csdm.cfg", LOCALINFO("amxx_configsdir"));

	if (g_Config.ReadConfig(file) != Config_Ok)
		MF_Log("Could not read config file: %s", file);

	RETURN_META_VALUE(MRES_IGNORED, 0);
}

void StartFrame_Post()
{
	if (IsActive() && g_LastTime + 0.1 < gpGlobals->time)
	{
		g_LastTime = gpGlobals->time;
		g_Timer.Tick(gpGlobals->time);
		if (g_First)
		{
			if (!g_DeathMsg)
				g_DeathMsg = GET_USER_MSG_ID(PLID, "DeathMsg", NULL);
			if (!g_ShowMenuMsg)
				g_ShowMenuMsg = GET_USER_MSG_ID(PLID, "ShowMenu", NULL);
			if (!g_VGUIMenuMsg)
				g_VGUIMenuMsg = GET_USER_MSG_ID(PLID, "VGUIMenu", NULL);
			g_First = false;
		}
	}

	RETURN_META(MRES_IGNORED);
}

void MessageBegin(int msg_dest, int msg_type, const float *pOrigin, edict_t *ed)
{
	if (!IsActive())
		RETURN_META(MRES_IGNORED);

	if (g_DeathMsg && (msg_type == g_DeathMsg))
	{
		g_CurMsg = msg_type;
	} else if (g_ShowMenuMsg && (msg_type == g_ShowMenuMsg)) {
		g_CurMsg = g_ShowMenuMsg;
		pTarget = ed;
	} else if (g_VGUIMenuMsg && (msg_type == g_VGUIMenuMsg)) {
		g_CurMsg = g_VGUIMenuMsg;
		pTarget = ed;
	}

	RETURN_META(MRES_IGNORED);
}

void MessageEnd()
{
	if (g_CurMsg)
	{
		if (g_CurMsg == g_DeathMsg)
		{
			int pk = g_Msg.GetParamInt(0);
			int pv = g_Msg.GetParamInt(1);
			int hs = g_Msg.GetParamInt(2);
			const char *sz = g_Msg.GetParamString(3);
			DeathHandler(pk, pv, hs, sz, false);
			g_CurPostMsg = g_DeathMsg;
		} else if (g_CurMsg == g_ShowMenuMsg) {
			const char *str = g_Msg.GetParamString(3);
			if (!strcmp(str, "#Terrorist_Select") || !strcmp(str, "#CT_Select"))
			{
				int client = ENTINDEX(pTarget);
				player_states *pPlayer = GET_PLAYER(client);
				if (pPlayer->spawned)
				{
					//doesn't matter if they're dead, stop respawn
					pPlayer->spawned = 0;
					pPlayer->spawning = false;
					pPlayer->blockspawn = true;
					pPlayer->wait = -1.0f;
					SetPlayerModel(pTarget, 0xFF);
				}
			}
			g_Msg.Reset();
		} else if (g_CurMsg == g_VGUIMenuMsg) {
			int id = g_Msg.GetParamInt(0);
			int client = ENTINDEX(pTarget);
			player_states *pPlayer = GET_PLAYER(client);
			if ((id == 26 || id == 27) && pPlayer->spawned)
			{
				pPlayer->spawned = 0;
				pPlayer->spawning = false;
				pPlayer->blockspawn = true;
				pPlayer->wait = -1.0f;
				SetPlayerModel(pTarget, 0xFF);
			}
			g_Msg.Reset();
		}
		g_CurMsg = 0;
	}

	RETURN_META(MRES_IGNORED);
}

void MessageEnd_Post()
{
	if (g_CurPostMsg)
	{
		if (g_CurPostMsg == g_DeathMsg)
		{
			int pk = g_Msg.GetParamInt(0);
			int pv = g_Msg.GetParamInt(1);
			if (!pv && !FNullEnt(pLastCliKill))
				pv = ENTINDEX(pLastCliKill);
			if (pv)
			{
				int hs = g_Msg.GetParamInt(2);
				const char *sz = g_Msg.GetParamString(3);
				DeathHandler(pk, pv, hs, sz, true);
			}
		}
		g_CurPostMsg = 0;
		g_Msg.Reset();
	}

	RETURN_META(MRES_IGNORED);
}

void WriteByte(int iValue)
{
	if (g_CurMsg)
	{
		g_Msg.AddParam(iValue);
	}

	RETURN_META(MRES_IGNORED);
}

void WriteChar(int iValue)
{
	if (g_CurMsg)
	{
		g_Msg.AddParam(iValue);
	}

	RETURN_META(MRES_IGNORED);
}

void WriteShort(int iValue)
{
	if (g_CurMsg)
	{
		g_Msg.AddParam(iValue);
	}

	RETURN_META(MRES_IGNORED);
}

void WriteLong(int iValue)
{
	if (g_CurMsg)
	{
		g_Msg.AddParam(iValue);
	}

	RETURN_META(MRES_IGNORED);
}

void WriteAngle(float fValue)
{
	if (g_CurMsg)
	{
		g_Msg.AddParam(fValue);
	}

	RETURN_META(MRES_IGNORED);
}

void WriteCoord(float fValue)
{
	if (g_CurMsg)
	{
		g_Msg.AddParam(fValue);
	}

	RETURN_META(MRES_IGNORED);
}

void WriteString(const char *sz)
{
	if (g_CurMsg)
	{
		g_Msg.AddParam(sz);
	}

	RETURN_META(MRES_IGNORED);
}

void WriteEntity(int iValue)
{
	if (g_CurMsg)
	{
		g_Msg.AddParam(iValue);
	}

	RETURN_META(MRES_IGNORED);
}

void ClientPutInServer(edict_t *pEdict)
{
	int index = ENTINDEX(pEdict);

	player_states *pPlayer = GET_PLAYER(index);
	pPlayer->ingame = true;

	if (g_IntroMsg)
	{
		Welcome *pWelcome = new Welcome(pEdict);
		g_Timer.AddTask(pWelcome, 10.0);
	}

	RETURN_META(MRES_IGNORED);
}

void ClientDisconnect(edict_t *pEdict)
{
	int index = ENTINDEX(pEdict);

	if (pEdict == pLastCliKill)
		pLastCliKill = NULL;

	ClearPlayer(index);

	RETURN_META(MRES_IGNORED);
}

void ClientUserInfoChanged(edict_t *pEntity, char *infobuffer)
{
	int index = ENTINDEX(pEntity);

	player_states *pPlayer = GET_PLAYER(index);

	if (!pPlayer->ingame && (pEntity->v.flags & FL_FAKECLIENT))
		pPlayer->ingame = true;

	RETURN_META(MRES_IGNORED);
}

BOOL ClientConnect(edict_t *pEntity, const char *pszName, const char *pszAddress, char szRejectReason[128])
{
	int index = ENTINDEX(pEntity);

	player_states *pPlayer = GET_PLAYER(index);

	if (pEntity->v.flags & FL_FAKECLIENT)
		pPlayer->ingame = true;
	else
		pPlayer->ingame = false;

	pPlayer->blockspawn = false;
	pPlayer->wait = 0.0f;

	RETURN_META_VALUE(MRES_IGNORED, true);
}

#if 0 //temporarily disabled, under research
void PlayerPreThink(edict_t *pEdict)
{
	int index = ENTINDEX(pEdict);

	if (!IsActive())
	{
		RETURN_META(MRES_IGNORED);
	}

	player_states *pPlayer = GET_PLAYER(index);

	if ( (!(pEdict->v.flags & FL_CLIENT) &&
		  !(pEdict->v.flags & FL_FAKECLIENT))
		  ||
		 (pEdict->v.flags & FL_SPECTATOR) )
	{
		RETURN_META(MRES_IGNORED);
	}

	int team = GetPlayerTeam(pEdict);
	if ( (team != TEAM_T && team != TEAM_CT) )
	{
		RETURN_META(MRES_IGNORED);
	}

	if ( (pEdict->v.deadflag == DEAD_NO) && ((int)pEdict->v.health > 0) )
	{
		if (pEdict->v.weaponmodel != 0)
		{
			const char *str = STRING(pEdict->v.weaponmodel);
			if (!str || str[0] == '\0')
			{
				RespawnPlayer(pEdict);
			}
		} else {
			//we need some sort of timer or validation here
			RespawnPlayer(pEdict);
		}
	}

	RETURN_META(MRES_IGNORED);
}
#endif

void PlayerPostThink(edict_t *pEdict)
{
	int index = ENTINDEX(pEdict);

	if (!IsActive())
	{
		RETURN_META(MRES_IGNORED);
	}

	player_states *pPlayer = GET_PLAYER(index);

	//if they're not in game or have already spawned once, we don't care...
	if (pPlayer->spawned)
	{
		RETURN_META(MRES_IGNORED);
	} else if (!pPlayer->ingame || pPlayer->spawning) {
		RETURN_META(MRES_IGNORED);
	}

	//if they're on an invalid team, we don't care...
	int team = GetPlayerTeam(pEdict);
	if (team != TEAM_T && team != TEAM_CT)
	{
		RETURN_META(MRES_IGNORED);
	}

	if (strcmp(STRING(pEdict->v.model), "models/player.mdl")==0 ||
	    strcmp(STRING(pEdict->v.model), "models\\player.mdl")==0)
	{
		RETURN_META(MRES_IGNORED);	
	}

	if (GetPlayerModel(pEdict) == 0xFF)
		RETURN_META(MRES_IGNORED);

	//are they alive?
	if ((pEdict->v.deadflag == DEAD_NO) && !(pEdict->v.flags & FL_SPECTATOR))
	{
		pPlayer->spawned = 1;
		FakespawnPlayer(pEdict);
	} else {
		if (pPlayer->wait == -1.0f)
		{
			pPlayer->spawned = 1;
			RespawnPlayer(pEdict);
			pPlayer->wait = 0.0f;
		} else if (pPlayer->wait < 0.1f) {
			pPlayer->wait = gpGlobals->time;
		} else if (gpGlobals->time - pPlayer->wait > FRAMEWAIT) {
			//they've selected a team, and we can safely respawn him.
			pPlayer->spawned = 1;
			RespawnPlayer(pEdict);
			pPlayer->wait = 0.0f;
		}
	}

	RETURN_META(MRES_IGNORED);
}

const char *Cmd_Args()
{
	if (g_FakeCmd.GetArgc())
		RETURN_META_VALUE(MRES_SUPERCEDE, g_FakeCmd.GetFullString());

	RETURN_META_VALUE(MRES_IGNORED, NULL);
}

const char *Cmd_Argv(int argc)
{
	if (g_FakeCmd.GetArgc())
		RETURN_META_VALUE(MRES_SUPERCEDE, g_FakeCmd.GetArg(argc));

	RETURN_META_VALUE(MRES_IGNORED, NULL);
}

int Cmd_Argc(void)
{
	if (g_FakeCmd.GetArgc())
		RETURN_META_VALUE(MRES_SUPERCEDE, g_FakeCmd.GetArgc());

	RETURN_META_VALUE(MRES_IGNORED, 0);
}

void ClientCommand(edict_t *pEntity)
{
	const char* cmd = CMD_ARGV(0);

	if (!cmd)
		RETURN_META(MRES_IGNORED);

	if (strcmp(cmd, "csdm")==0 || strcmp(cmd, "csdm_version")==0)
	{
		print_client(pEntity, 2, "[CSDM] Version %s (C)2003-2013 David \"BAILOPAN\" Anderson\n", MODULE_VERSION);
		print_client(pEntity, 2, "[CSDM] Written by the CSDM Team (BAILOPAN and Freecode), edited by KWo\n");
		print_client(pEntity, 2, "[CSDM] http://www.bailopan.net/csdm/\n");
		RETURN_META(MRES_SUPERCEDE);
	}

	RETURN_META(MRES_IGNORED);
}

