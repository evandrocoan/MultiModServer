#include "amxxmodule.h"
#include "csdm_amxx.h"
#include "csdm_spawning.h"
#include "csdm_util.h"
#include "csdm_config.h"
#include "csdm_player.h"
#include "csdm_util.h"
#include "csdm_tasks.h"

Vector CellToVector(AMX *amx, cell param)
{
	cell *addr = MF_GetAmxAddr(amx, param);

	Vector a(amx_ctof(addr[0]), amx_ctof(addr[1]), amx_ctof(addr[2]));

	return a;
}

void VectorToCell(AMX *amx, cell param, Vector &vec)
{
	cell *addr = MF_GetAmxAddr(amx, param);

	addr[0] = amx_ftoc(vec.x);
	addr[1] = amx_ftoc(vec.y);
	addr[2] = amx_ftoc(vec.z);
}

// from HAM module - thanks to arkshine to help with this
inline edict_t* PrivateToEdict( const void* pdata )
{
	if( !pdata || ( int )pdata == -1 )
	{
		return NULL;
	}

	char* ptr = ( char* )pdata + EntityPevOffset;

	if( !ptr )
	{
		return NULL;
	}

	entvars_t* pev = *( entvars_t** )ptr;

	if( !pev )
	{
		return NULL;
	}

	return pev->pContainingEntity;
};

edict_t* get_pdata_cbase( edict_t *pEntity, int offset )
{
	void *pPrivate = *( ( void** )( ( int* )( edict_t* )( INDEXENT( 0 ) + ENTINDEX( pEntity ) )->pvPrivateData + offset ) );

	if( !pPrivate )
	{
		return NULL;
	}

	return PrivateToEdict( pPrivate );	
}

static cell AMX_NATIVE_CALL csdm_getpos(AMX *amx, cell *params)
{
	int player = params[1];
	if (player < 0 || player > gpGlobals->maxClients || !MF_IsPlayerIngame(player))
	{
		MF_LogError(amx, AMX_ERR_NATIVE, "Invalid or not in-game player %d", player);
		return 0;
	}

	int numParams = *params / sizeof(cell);
	edict_t *pEdict = MF_GetPlayerEdict(player);
	
	VectorToCell(amx, params[1], pEdict->v.origin);

	if (numParams >= 2)
	{
		VectorToCell(amx, params[2], pEdict->v.angles);
		if (numParams >= 3)
			VectorToCell(amx, params[3], pEdict->v.v_angle);
	}

	return 1;
}

static cell AMX_NATIVE_CALL csdm_setpos(AMX *amx, cell *params)
{
	int player = params[1];
	if (player < 0 || player > gpGlobals->maxClients || !MF_IsPlayerIngame(player))
	{
		MF_LogError(amx, AMX_ERR_NATIVE, "Invalid or not in-game player %d", player);
		return 0;
	}

	int numParams = *params / sizeof(cell);
	edict_t *pEdict = MF_GetPlayerEdict(player);

	pEdict->v.origin = CellToVector(amx, params[1]);

	if (numParams >= 2)
	{
		pEdict->v.angles = CellToVector(amx, params[2]);
		if (numParams >= 3)
			pEdict->v.v_angle = CellToVector(amx, params[3]);
		pEdict->v.fixangle = 1;
	}

	return 1;
}

static cell AMX_NATIVE_CALL csdm_spawnstyles(AMX *amx, cell *params)
{
	return g_SpawnMngr.Spawns();
}

static cell AMX_NATIVE_CALL csdm_curstyle(AMX *amx, cell *params)
{
	return g_SpawnMethod;
}

static cell AMX_NATIVE_CALL csdm_styleinfo(AMX *amx, cell *params)
{
	int method = params[1];

	SpawnMethod *pMethod = g_SpawnMngr.GetSpawn(method);

	if (!pMethod)
		return 0;

	return MF_SetAmxString(amx, params[2], pMethod->GetName(), params[3]);
}

static cell AMX_NATIVE_CALL csdm_addstyle(AMX *amx, cell *params)
{
	int len;
	char *name, *func;

	name = MF_GetAmxString(amx, params[1], 0, &len);
	func = MF_GetAmxString(amx, params[2], 1, &len);

	int callback = MF_RegisterSPForwardByName(amx, func, FP_CELL, FP_CELL, FP_DONE);
	if (callback < 0)
	{
		MF_LogError(amx, AMX_ERR_NATIVE, "Callback function not found (\"%s\")", func);
		return -1;
	}

	g_SpawnMngr.AddMethod(name, callback);

	return callback;
}

static cell AMX_NATIVE_CALL csdm_setstyle(AMX *amx, cell *params)
{
	int len;
	char *name = MF_GetAmxString(amx, params[1], 0, &len);

	if (strcmp(name, "none") == 0)
	{
		g_SpawnMethod = -1;
		return 1;
	}

	SpawnMethod *pSpawn = NULL;

	for (size_t i=0; i<g_SpawnMngr.Spawns(); i++)
	{
		pSpawn = g_SpawnMngr.GetSpawn(i);
		if (strcmpi(pSpawn->GetName(), name) == 0)
		{
			g_SpawnMethod = i;
			return 1;
		}
	}

	return 0;
}

static cell AMX_NATIVE_CALL csdm_respawn(AMX *amx, cell *params)
{
	int index = params[1];

	if (index < 1 || index > gpGlobals->maxClients || !MF_IsPlayerIngame(index))
	{
		MF_LogError(amx, AMX_ERR_NATIVE, "Player %d is not valid", index);
		return 0;
	}

	edict_t *pEdict = MF_GetPlayerEdict(index);

	if (FNullEnt(pEdict))
		return 0;

	int team = GetPlayerTeam(pEdict);
	if (team == TEAM_T || team == TEAM_CT)
	{
		RespawnPlayer(pEdict);
	} else {
		return 0;
	}

	return 1;
}

static cell AMX_NATIVE_CALL csdm_fakespawn(AMX *amx, cell *params)
{
	int index = params[1];

	if (index < 1 || index > gpGlobals->maxClients || !MF_IsPlayerIngame(index))
	{
		MF_LogError(amx, AMX_ERR_NATIVE, "Player %d is not valid", index);
		return 0;
	}

	edict_t *pEdict = MF_GetPlayerEdict(index);

	if (FNullEnt(pEdict))
		return 0;

	return 1;
}

static cell AMX_NATIVE_CALL csdm_reg_cfg(AMX *amx, cell *params)
{
	int length;
	char *setting = MF_GetAmxString(amx, params[1], 0, &length);
	char *func = MF_GetAmxString(amx, params[2], 1, &length);

	int forward = MF_RegisterSPForwardByName(amx, func, FP_CELL, FP_STRING, FP_STRING, FP_DONE);
	if (forward < 1)
	{
		MF_LogError(amx, AMX_ERR_NATIVE, "Public function \"%s\" not found", func);
		return 0;
	}

	g_Config.AddHook(setting, forward);

	return 1;
}

static cell AMX_NATIVE_CALL csdm_force_drop(AMX *amx, cell *params)
{
	// Check index.
	if (params[1] < 1 || params[1] > gpGlobals->maxClients)
	{
		MF_LogError(amx, AMX_ERR_NATIVE, "Invalid player %d", params[1]);
		return 0;
	} else if (!MF_IsPlayerIngame(params[1])) {
		MF_LogError(amx, AMX_ERR_NATIVE, "Player %d is not in game", params[1]);
		return 0;
	}

	int len;
	char *str = MF_GetAmxString(amx, params[2], 0, &len);

	edict_t *pEdict = MF_GetPlayerEdict(params[1]);

	/** Force the drop! */
	g_FakeCmd.AddArg("drop");
	g_FakeCmd.AddArg(str);
	g_FakeCmd.SetFullString("drop %s", str);
	MDLL_ClientCommand(pEdict);
	g_FakeCmd.Reset();

	if (!params[3])
	{
		return -1;
	}

	edict_t *searchEnt = NULL;
	if (strcmp(str, "weapon_shield") != 0)
	{
		while (!FNullEnt( (searchEnt = FIND_ENTITY_BY_STRING(searchEnt, "classname", "weaponbox")) ))
		{
			if (searchEnt->v.owner == pEdict)
			{
				edict_t *find = FIND_ENTITY_BY_STRING(NULL, "classname", str);
				edict_t *findNext;
				while (find != NULL && !FNullEnt(find))
				{
					findNext = FIND_ENTITY_BY_STRING(find, "classname", str);
					if (find->v.owner == searchEnt)
					{
						REMOVE_ENTITY(find);
						REMOVE_ENTITY(searchEnt);
						return 1;
					}
					find = findNext;
				}
			}
		}
	} else {
		while (!FNullEnt((searchEnt = FIND_ENTITY_BY_STRING(searchEnt, "classname", "weapon_shield"))))
		{
			if (searchEnt->v.owner == pEdict)
			{
				REMOVE_ENTITY(searchEnt);
				return 1;
			}
		}
	}

	return 0;
}

//shamelessly pulled from fun
static cell AMX_NATIVE_CALL csdm_give_item(AMX *amx, cell *params) // native give_item(index, const item[]); = 2 params
{
	// Check index.
	if (params[1] < 1 || params[1] > gpGlobals->maxClients)
	{
		MF_LogError(amx, AMX_ERR_NATIVE, "Invalid player %d", params[1]);
		return 0;
	} else if (!MF_IsPlayerIngame(params[1])) {
		MF_LogError(amx, AMX_ERR_NATIVE, "Player %d is not in game", params[1]);
		return 0;
	}

	// Get player pointer.
	edict_t *pPlayer = MF_GetPlayerEdict(params[1]);

	// Create item entity pointer
	edict_t	*pItemEntity;

	// Make an "intstring" out of 2nd parameter
	int length;
	const char *szItem = MF_GetAmxString(amx, params[2], 1, &length);

	//check for valid item
	if (strncmp(szItem, "weapon_", 7) && 
		strncmp(szItem, "ammo_", 5) && 
		strncmp(szItem, "item_", 5) &&
		strncmp(szItem, "tf_weapon_", 10)
	) {
		return 0;
	}

	string_t item = ALLOC_STRING(szItem); // Using MAKE_STRING makes "item" contents get lost when we leave this scope! ALLOC_STRING seems to allocate properly...
	pItemEntity = CREATE_NAMED_ENTITY(item);

	if (FNullEnt(pItemEntity)) {
		MF_LogError(amx, AMX_ERR_NATIVE, "Item \"%s\" failed to create", szItem);
		return 0;
	}

	pItemEntity->v.origin = pPlayer->v.origin;
	pItemEntity->v.spawnflags |= (1 << 30);	//SF_NORESPAWN;

	MDLL_Spawn(pItemEntity);

	int save = pItemEntity->v.solid;

	MDLL_Touch(pItemEntity, ENT(pPlayer));

	if (pItemEntity->v.solid == save)
	{
		REMOVE_ENTITY(pItemEntity);
		//the function did not fail - we're just deleting the item
		return -1;
	}

	return ENTINDEX(pItemEntity);
}

static cell AMX_NATIVE_CALL csdm_reload_cfg(AMX *amx, cell *params)
{
	char file[255];

	file[0] = '\0';

	if  (params[0] / sizeof(cell) != 0)
	{
		int len;
		char *str = MF_GetAmxString(amx, params[1], 0, &len);
		if (str[0] != '\0')
		{
			MF_BuildPathnameR(file, sizeof(file)-1, "%s/%s", LOCALINFO("amxx_configsdir"), str);
		}
	}

	if (file[0] == '\0')
	{
		MF_BuildPathnameR(file, sizeof(file)-1, "%s/csdm.cfg", LOCALINFO("amxx_configsdir"));
	}

	if (g_Config.ReadConfig(file) != Config_Ok)
	{
		MF_Log("Could not read config file: %s", file);
		return 0;
	}

	return 1;
}

static cell AMX_NATIVE_CALL csdm_remove_weaponbox(AMX *amx, cell *params)
{
	// Check index.
	unsigned int owner = params[1];
	unsigned int ent = params[2];
	const unsigned char m_rgpPlayerItems_wpnbx[] = { 34, 35, 36, 37, 38, 39 };

	if (owner < 1 || owner > (unsigned int)gpGlobals->maxClients)
	{
		MF_LogError(amx, AMX_ERR_NATIVE, "Invalid player %d", owner);
		return 0;
	} else if (!MF_IsPlayerIngame(owner)) {
		MF_LogError(amx, AMX_ERR_NATIVE, "Player %d is not in game", owner);
		return 0;
	}

	unsigned int weapon_shield = params[5];
	edict_t *searchEnt = INDEXENT(ent);

	if (FNullEnt(searchEnt))
	{
		MF_LogError(amx, AMX_ERR_NATIVE, "Invalid weaponbox %d", ent);
		return 0;
	} else if ((weapon_shield != 1) && (strcmp(STRING(searchEnt->v.classname),"weaponbox") != 0)) {
		MF_LogError(amx, AMX_ERR_NATIVE, "Not a weaponbox %d", ent);
		return 0;
	} else if ((weapon_shield == 1) && (strcmp(STRING(searchEnt->v.classname),"weapon_shield") != 0)) {
		MF_LogError(amx, AMX_ERR_NATIVE, "Not a shield %d", ent);
		return 0;
	}

	edict_t *pEdict = MF_GetPlayerEdict(owner);
	if (weapon_shield == 1)
	{
		if (searchEnt->v.owner == pEdict)
		{
			if (!params[3])
			{
				if (NotifyForRemove(owner, searchEnt, NULL))
				{
					REMOVE_ENTITY(searchEnt);
				}
			} else {
				RemoveWeapon::SchedRemoval(params[3], pEdict, NULL, searchEnt);
			}
			return 1;
		}
		MF_LogError(amx, AMX_ERR_NATIVE, "Shield %d not found", ent);
		return 0;
	}

	edict_t *pWeapEdict;
	unsigned char i;

	for( i = 0; i < sizeof (m_rgpPlayerItems_wpnbx); i++ )
	{
		pWeapEdict = get_pdata_cbase( searchEnt, m_rgpPlayerItems_wpnbx[ i ] + EXTRAOFFSET_WEAPONS );

		if (pWeapEdict == NULL)
			continue;
		if (FNullEnt(pWeapEdict))
			continue;
		if (pWeapEdict->free)
			continue;
		if ((pWeapEdict->v.flags & FL_FAKECLIENT) || (pWeapEdict->v.flags & FL_CLIENT))
			continue;
		if (pWeapEdict->v.owner == searchEnt)
		{
//			ALERT(at_logged, "CSDM - found weapon edict in private data of weaponbox in slot %d.\n", i);
			if (!params[3] || !params[4])
			{
				if (NotifyForRemove(owner, pWeapEdict, searchEnt))
				{
					REMOVE_ENTITY(pWeapEdict);
					REMOVE_ENTITY(searchEnt);
				}
			}
			else 
			{
				FindWeapon *p = FindWeapon::NewFindWeapon(pEdict, STRING(pWeapEdict->v.classname), params[3]);
				g_Timer.AddTask(p, 0.1);
				return 1;

//				RemoveWeapon::SchedRemoval(params[3], pEdict, searchEnt, pWeapEdict);
			}
			return 1;
		}
	}
	ALERT(at_logged, "CSDM - weapon edict not found in private data of weaponbox!!!.\n");
	return 0;
}


static cell AMX_NATIVE_CALL csdm_remove_weapon(AMX *amx, cell *params)
{
	// Check index.
	unsigned int owner = params[1];
	if (owner < 1 || owner > (unsigned int)gpGlobals->maxClients)
	{
		MF_LogError(amx, AMX_ERR_NATIVE, "Invalid player %d", owner);
		return 0;
	} else if (!MF_IsPlayerIngame(owner)) {
		MF_LogError(amx, AMX_ERR_NATIVE, "Player %d is not in game", owner);
		return 0;
	}
   bool found = false;
	int len;
	char *str = MF_GetAmxString(amx, params[2], 0, &len);
	edict_t *pEdict = MF_GetPlayerEdict(owner);

	if (params[4])
	{
		FindWeapon *p = FindWeapon::NewFindWeapon(pEdict, str, params[3]);
		g_Timer.AddTask(p, 0.1);
		return 1;
	}

	edict_t *searchEnt = NULL;
   if (strcmp(str, "weapon_shield") != 0)
	{
		while (!FNullEnt( (searchEnt = FIND_ENTITY_BY_STRING(searchEnt, "classname", "weaponbox")) ))
		{
			if (searchEnt->v.owner == pEdict)
			{
				edict_t *find = FIND_ENTITY_BY_STRING(NULL, "classname", str);
				edict_t *findNext;
				while (find != NULL && !FNullEnt(find))
				{
					findNext = FIND_ENTITY_BY_STRING(find, "classname", str);
					if (find->v.owner == searchEnt)
					{
                  found = true;
						if (!params[3])
						{
							if (NotifyForRemove(owner, find, searchEnt))
							{
								REMOVE_ENTITY(find);
								REMOVE_ENTITY(searchEnt);
							}
						} else {
							RemoveWeapon::SchedRemoval(params[3], pEdict, searchEnt, find);
						}
						return 1;
					}
					find = findNext;
				}
			}
		}
	} else {
		while (!FNullEnt((searchEnt=FIND_ENTITY_BY_STRING(searchEnt, "classname", "weapon_shield"))))
		{
			if (searchEnt->v.owner == pEdict)
			{
				if (!params[3])
				{
					if (NotifyForRemove(owner, searchEnt, NULL))
					{
						REMOVE_ENTITY(searchEnt);
					}
				} else {
					RemoveWeapon::SchedRemoval(params[3], pEdict, NULL, searchEnt);
				}
				return 1;
			}
		}
	}
/*
   if (!found)
      ALERT(at_logged, "[CSDM - csdm_remove_weapon - can't remove weapon dropped by %s.\n", STRING(pEdict->v.netname));
*/
	return 0;
}

static cell AMX_NATIVE_CALL is_csdm_active(AMX *amx, cell *params)
{
	return IsActive() ? 1 : 0;
}

static cell AMX_NATIVE_CALL csdm_set_active(AMX *amx, cell *params)
{
	if (IsActive() && params[1])
		return 0;
	if (!IsActive() && !params[1])
		return 0;

	SetActive(params[1] ? true : false);

	return 1;
}

static cell AMX_NATIVE_CALL csdm_cache(AMX *amx, cell *params)
{
	cell *ar = MF_GetAmxAddr(amx, params[1]);

	int num, avail;
	ar[0] = g_FreeSpawns.size();
	g_Timer.TaskInfo(num, avail);
	ar[2] = num;
	ar[1] = avail;

	num = 0, avail=0;
	num = 0;
	avail = 0;

	ar[3] = num;
	ar[4] = avail;

	if (params[2] >= 2)
	{
		ar[5] = g_FreeFinds.size();
	}

	return 1;
}

static cell AMX_NATIVE_CALL csdm_set_spawnwait(AMX *amx, cell *params)
{
	g_SpawnWaitTime = amx_ctof(params[1]);

	return 1;
}

static cell AMX_NATIVE_CALL csdm_get_ffa(AMX *amx, cell *params)
{
	return g_ffa_state ? 1 : 0;
}

static cell AMX_NATIVE_CALL csdm_get_spawnwait(AMX *amx, cell *params)
{
	return amx_ftoc(g_SpawnWaitTime);
}

static cell AMX_NATIVE_CALL csdm_set_ffa(AMX *amx, cell *params)
{
	cell state = params[1];

	if (g_ffa_state && state)
	{
		return 0;
	}
	if (!g_ffa_state && !state)
	{
		return 0;
	}

	if (!IsActive())
	{
		return 0;
	}

	if (g_ffa_state && !state)
	{
		FFA_Disable();
	} else if (!g_ffa_state && state) {
		FFA_Enable();
	}

	return 1;
}

static cell AMX_NATIVE_CALL csdm_trace_hull(AMX *amx,cell *params)
{
	TraceResult tr;
	Vector vPos;
	cell *vCell;

	vCell = MF_GetAmxAddr(amx, params[1]);

	vPos.x = amx_ctof(vCell[0]);
	vPos.y = amx_ctof(vCell[1]);
	vPos.z = amx_ctof(vCell[2]);

	TRACE_HULL(vPos,vPos, 0, params[2], NULL, &tr);

	if (tr.fStartSolid)
		return 1;

	if (tr.fAllSolid)
		return 1;

	if (!tr.fInOpen)
		return 1;

	return 0;
}

static cell AMX_NATIVE_CALL csdm_set_intromsg(AMX *amx, cell *params)
{
	int old = g_IntroMsg;

	if (params[1] != -1)
	{
		g_IntroMsg = params[1];
	}

	return old;
}

AMX_NATIVE_INFO g_CsdmNatives[] = 
{
	{"csdm_getpos",				csdm_getpos},
	{"csdm_setpos",				csdm_setpos},
	{"csdm_spawnstyles",		csdm_spawnstyles},
	{"csdm_styleinfo",			csdm_styleinfo},
	{"csdm_addstyle",			csdm_addstyle},
	{"csdm_setstyle",			csdm_setstyle},
	{"csdm_respawn",			csdm_respawn},
	{"csdm_fakespawn",			csdm_fakespawn},
	{"csdm_reg_cfg",			csdm_reg_cfg},
	{"csdm_give_item",			csdm_give_item},
	{"csdm_force_drop",			csdm_force_drop},
	{"csdm_reload_cfg",			csdm_reload_cfg},
	{"csdm_curstyle",			csdm_curstyle},
	{"csdm_remove_weapon",		csdm_remove_weapon},
	{"csdm_remove_weaponbox",		csdm_remove_weaponbox},
	{"csdm_set_active",			csdm_set_active},
	{"csdm_active",				is_csdm_active},
	{"csdm_cache",				csdm_cache},
	{"csdm_get_spawnwait",		csdm_get_spawnwait},
	{"csdm_set_spawnwait",		csdm_set_spawnwait},
	{"csdm_get_ffa",			csdm_get_ffa},
	{"csdm_set_ffa",			csdm_set_ffa},
	{"csdm_trace_hull",			csdm_trace_hull},
	{"csdm_set_intromsg",		csdm_set_intromsg},

	{NULL,						NULL},
};
