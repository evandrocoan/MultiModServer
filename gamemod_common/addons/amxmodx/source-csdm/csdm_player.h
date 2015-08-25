#ifndef _INCLUDE_CSDM_PLAYER_H
#define _INCLUDE_CSDM_PLAYER_H

#include "csdm_timer.h"

struct player_states
{
	bool ingame;
	bool spawning;
	int spawned;
	float wait;
	bool blockspawn;

	//float reset;
};

extern player_states Players[33];

void ClearAllPlayers();
void ClearPlayer(int index);
int GetPlayerTeam(int index);
void SetPlayerTeam(edict_t *pEdict, int team);
int GetPlayerTeam(const edict_t *pEdict);
int GetPlayerModel(edict_t *pEdict);
void SetPlayerModel(edict_t *pEdict, int model_id);

#define	GET_PLAYER(id)	(&Players[(id)])

#if defined __linux__
	#define EXTRAOFFSET					5 // offsets 5 higher in Linux builds
	#define EXTRAOFFSET_WEAPONS			4 // weapon offsets are obviously only 4 steps higher on Linux!
#else
	#define EXTRAOFFSET					0 // no change in Windows builds
	#define EXTRAOFFSET_WEAPONS			0
#endif // defined __linux__

#if !defined __amd64__
	// 32 bit offsets here
	#define OFFSET_TEAM					114 + EXTRAOFFSET
	#define OFFSET_INTERNALMODEL		126 + EXTRAOFFSET
#else
	// Amd64 offsets here
	#define OFFSET_TEAM					139 + EXTRAOFFSET // +25
	#define OFFSET_INTERNALMODEL		152 + EXTRAOFFSET // +26
#endif

#define	TEAM_T		1
#define	TEAM_CT		2
#define	TEAM_SPEC	3

#endif //_INCLUDE_CSDM_PLAYER_H
