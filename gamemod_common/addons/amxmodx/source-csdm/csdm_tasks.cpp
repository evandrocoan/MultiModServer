#include "amxxmodule.h"
#include "csdm_amxx.h"
#include "csdm_tasks.h"
#include "csdm_player.h"
#include "csdm_util.h"

CStack<Respawn *> g_FreeSpawns;
CStack<FindWeapon *> g_FreeFinds;
CStack<RemoveWeapon *> g_RemoveWeapons;

void RestartRoundTask::Run()
{
	if (g_RoundRestart != -1)
	{
		MF_ExecuteForward(g_RoundRestart, (cell)0);
	}

	player_states *pPlayer;
	edict_t *pEdict;
	for (int i=1; i<=gpGlobals->maxClients; i++)
	{
		pPlayer = GET_PLAYER(i);
		pEdict = GetEdict(i);
		if (pPlayer->ingame && pEdict)
		{
			int team = GetPlayerTeam(i);
			if (team == TEAM_T || team == TEAM_CT)
			{
				int model_id = GetPlayerModel(pEdict);
				if (model_id == 0xFF)
					continue;
				FakespawnPlayer(pEdict);
			}
		}
	}

	if (g_RoundRestart != -1)
	{
		MF_ExecuteForward(g_RoundRestart, (cell)1);
	}
}

void ClearAllTaskCaches()
{

	RemoveWeapon *r;
	while (!g_RemoveWeapons.empty())
	{
		r = g_RemoveWeapons.front();
		delete r;
		g_RemoveWeapons.pop();
	}

	Respawn *p;
	while (!g_FreeSpawns.empty())
	{
		p = g_FreeSpawns.front();
		delete p;
		g_FreeSpawns.pop();
	}

	FindWeapon *f;
	while (!g_FreeFinds.empty())
	{
		f = g_FreeFinds.front();
		delete f;
		g_FreeFinds.pop();
	}
}

Respawn::Respawn(edict_t *pEdict, int notify) : m_pEdict(pEdict), m_Notify(notify)
{
}

bool Respawn::deleteThis()
{
	g_FreeSpawns.push(this);
	return true;
}

void Respawn::set(edict_t *pEdict, int notify)
{
	m_pEdict = pEdict;
}

Respawn *Respawn::NewRespawn(edict_t *pEdict, int notify)
{
	Respawn *p;

	if (g_FreeSpawns.empty())
	{
		p = new Respawn(pEdict, notify);
	} else {
		p = g_FreeSpawns.front();
		g_FreeSpawns.pop();
		p->set(pEdict, notify);
	}
	
	return p;
}

void Respawn::Run()
{
	int index = ENTINDEX(m_pEdict);
	player_states *pPlayer = GET_PLAYER(index);

	if (!pPlayer->ingame || !pPlayer->spawning)
		return;

	if (pPlayer->blockspawn)
	{
		pPlayer->blockspawn = false;
		pPlayer->spawning = false;
		return;
	}

	int team = GetPlayerTeam(m_pEdict);

	if (team == TEAM_T || team == TEAM_CT)
	{
		InternalSpawnPlayer(m_pEdict);
	
		if (m_Notify != -1)
		{
			pPlayer->spawned++;
			if (m_Notify == -2)
			{
				SpawnHandler(index, false);
			} else if (MF_ExecuteForward(m_Notify, (cell)index, (cell)0) == 0)
			{
				SpawnHandler(index, false);
			}
			pPlayer->spawning = false;
		}
	}
}

void Welcome::Run()
{
	player_states *pPlayer = GET_PLAYER(ENTINDEX(m_pEdict));

	if (!pPlayer->ingame)
	{
		return;
	}

	print_client(m_pEdict, 3, "[CSDM] This server is running CSDM %s\n", MODULE_VERSION);
	print_client(m_pEdict, 3, "[CSDM] Visit http://www.bailopan.net/\n");
}

void RemoveWeapon::Run()
{
	if (m_pOwner == NULL)
	{
//      ALERT(at_logged, "CSDM - RemoveWeapon::Run - can't remove weapon - no owner....\n");
		return;
	}

	if (m_pBox)
	{
		if (FNullEnt(m_pBox)
			|| ((m_pBox->v.owner != m_pOwner) && (m_pBox->v.owner != NULL))
			|| (box_serial != m_pBox->serialnumber))
		{
/*
         if (FNullEnt(m_pBox))
            ALERT(at_logged, "CSDM - RemoveWeapon::Run - can't remove weapon - wbox is NULL...\n");
         if ((m_pBox->v.owner != m_pOwner) && (m_pWeapon->v.flags & FL_ONGROUND))
            ALERT(at_logged, "CSDM - RemoveWeapon::Run - can't remove weapon - wrong owner for wbox...\n");
         if ((box_serial != m_pBox->serialnumber) && (m_pWeapon->v.flags & FL_ONGROUND))
            ALERT(at_logged, "CSDM - RemoveWeapon::Run - can't remove weapon - wrong serial number for wbox...\n");
*/
			m_pBox = NULL;

		}

		if (FNullEnt(m_pWeapon) || (m_pWeapon->v.owner != m_pBox))
		{
/*
         if (FNullEnt(m_pWeapon))
            ALERT(at_logged, "CSDM - RemoveWeapon::Run - can't remove weapon - weapon is NULL...\n");
         if ((m_pWeapon->v.owner != m_pBox) && (m_pWeapon->v.flags & FL_ONGROUND))
            ALERT(at_logged, "CSDM - RemoveWeapon::Run - can't remove weapon - wrong owner - not wbox...\n");
*/
			m_pWeapon = NULL;
		}
	} else {
		if (FNullEnt(m_pWeapon) 
			|| ((m_pWeapon->v.owner != m_pOwner) && (m_pWeapon->v.owner != NULL))
			|| (weapon_serial != m_pWeapon->serialnumber))
		{
/*
         if (FNullEnt(m_pWeapon))
            ALERT(at_logged, "CSDM - RemoveWeapon::Run - can't remove weapon - weapon is NULL...\n");
         if (m_pWeapon->v.owner != m_pOwner)
            ALERT(at_logged, "CSDM - RemoveWeapon::Run - can't remove weapon - owner of weapon different...\n");
         if (weapon_serial != m_pWeapon->serialnumber)
            ALERT(at_logged, "CSDM - RemoveWeapon::Run - can't remove weapon - serial number of weapon problem...\n");
*/
			m_pWeapon = NULL;
		}
	}

	if (!m_pWeapon)
	{
		/* shouldn't happen but just in case*/
		if (m_pBox)
		{
			REMOVE_ENTITY(m_pBox);
		}
		return;
	}

	if (NotifyForRemove(ENTINDEX(m_pOwner), m_pWeapon, m_pBox))
	{
		if (m_pBox)
		{
			REMOVE_ENTITY(m_pBox);
		}
		REMOVE_ENTITY(m_pWeapon);
	}
/*
   else
      ALERT(at_logged, "CSDM - RemoveWeapon::Run - can't remove weapon - Notify for remove failed...\n");
*/
}

void RemoveWeapon::set(edict_t *pOwner, edict_t *pBox, edict_t *pWeapon)
{
	m_pOwner = pOwner;
	m_pBox = pBox;
	if (m_pBox)
	{
		box_serial = m_pBox->serialnumber;
		m_BaseIdx = ENTINDEX(m_pBox);
	}

	m_pWeapon = pWeapon;
	weapon_serial = m_pWeapon->serialnumber;
}

bool RemoveWeapon::valid()
{
	return (m_pOwner != NULL);
}

void RemoveWeapon::invalidate()
{
	m_pOwner = NULL;
}

bool RemoveWeapon::deleteThis()
{
	g_RemoveWeapons.push(this);
	return true;
}

void RemoveWeapon::SchedRemoval(int seconds, edict_t *pOwner, edict_t *pBox, edict_t *pWeapon)
{
	RemoveWeapon *pTask;
	if (g_RemoveWeapons.empty())
	{
		pTask = new RemoveWeapon(pOwner, pBox, pWeapon);
	} else {
		pTask = g_RemoveWeapons.front();
		g_RemoveWeapons.pop();
		pTask->set(pOwner, pBox, pWeapon);
	}

	g_Timer.AddTask(pTask, (float)seconds);
}

FindWeapon *FindWeapon::NewFindWeapon(edict_t *pOwner, const char *className, int delay)
{
	FindWeapon *p;

	if (g_FreeFinds.empty())
	{
		p = new FindWeapon(pOwner, className, delay);
	} else {
		p = g_FreeFinds.front();
		g_FreeFinds.pop();
		p->set(pOwner, className, delay);
	}

	return p;
}

bool FindWeapon::deleteThis()
{
	g_FreeFinds.push(this);
	return true;
}

FindWeapon::FindWeapon(edict_t *pOwner, const char *className, int delay) : 
	m_pOwner(pOwner), m_Delay(delay)
{
	m_Classname.assign(className);
}

void FindWeapon::set(edict_t *pOwner, const char *className, int delay)
{
	m_pOwner = pOwner;
	m_Classname.assign(className);
	m_Delay = delay;
}

void FindWeapon::Run()
{
	edict_t *pEdict = m_pOwner;

	edict_t *searchEnt = NULL;
	if (m_Classname.compare("weapon_shield") != 0)
	{
		while (!FNullEnt( (searchEnt = FIND_ENTITY_BY_STRING(searchEnt, "classname", "weaponbox")) ))
		{
			if (searchEnt->v.owner == pEdict)
			{
				edict_t *find = FIND_ENTITY_BY_STRING(NULL, "classname", m_Classname.c_str());
				edict_t *findNext;
				while (find != NULL && !FNullEnt(find))
				{
					findNext = FIND_ENTITY_BY_STRING(find, "classname", m_Classname.c_str());
					if (find->v.owner == searchEnt)
					{
						if (!m_Delay)
						{
							if (NotifyForRemove(ENTINDEX(m_pOwner), find, searchEnt))
							{
								REMOVE_ENTITY(find);
								REMOVE_ENTITY(searchEnt);
							}
						} else {
							RemoveWeapon::SchedRemoval(m_Delay, pEdict, searchEnt, find);
						}
						return;
					}
					find = findNext;
				}
			}
		}
	} else {
		while (!FNullEnt((searchEnt=FIND_ENTITY_BY_STRING(searchEnt, "classname", m_Classname.c_str()))))
		{
			if (searchEnt->v.owner == pEdict)
			{
				if (!m_Delay)
				{
					if (NotifyForRemove(ENTINDEX(m_pOwner), searchEnt, NULL))
					{
						REMOVE_ENTITY(searchEnt);
					}
				} else {
					RemoveWeapon::SchedRemoval(m_Delay, pEdict, NULL, searchEnt);
				}
				return;
			}
		}
	}
}

