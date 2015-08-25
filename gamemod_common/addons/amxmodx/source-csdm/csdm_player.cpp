#include "amxxmodule.h"
#include "csdm_player.h"

player_states Players[33];
player_states *g_player = NULL;

void ClearAllPlayers()
{
	for (int i=1; i<=gpGlobals->maxClients; i++)
		ClearPlayer(i);
}

void ClearPlayer(int index)
{
	player_states *pPlayer = GET_PLAYER(index);

	pPlayer->ingame = false;
	pPlayer->spawned = 0;
	pPlayer->spawning = false;
	pPlayer->wait = 0.0f;
	pPlayer->blockspawn = false;
}

int GetPlayerTeam(int index)
{
	edict_t *pEdict = MF_GetPlayerEdict(index);
	return GetPlayerTeam(pEdict);
}

void SetPlayerTeam(edict_t *pEdict, int team)
{
	if (!pEdict || FNullEnt(pEdict))
		return;

	*( (int *)pEdict->pvPrivateData + OFFSET_TEAM ) = team;
}

int GetPlayerTeam(const edict_t *pEdict)
{
	if (!pEdict || FNullEnt(pEdict))
		return 0;

	//if (pEdict->v.flags & FL_FAKECLIENT)
	//	return pEdict->v.team;
	
	return  *( (int *)pEdict->pvPrivateData + OFFSET_TEAM );
}

int GetPlayerModel(edict_t *pEdict)
{
	return *((int *)pEdict->pvPrivateData + OFFSET_INTERNALMODEL);
}

void SetPlayerModel(edict_t *pEdict, int model_id)
{
	*((int *)pEdict->pvPrivateData + OFFSET_INTERNALMODEL) = model_id;
}

