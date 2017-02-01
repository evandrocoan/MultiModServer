/*================================================================================
	
	----------------------------
	-*- [ZP] Random Spawning -*-
	----------------------------
	
	This plugin is part of Zombie Plague Mod and is distributed under the
	terms of the GNU General Public License. Check ZP_ReadMe.txt for details.
	
================================================================================*/

#include <amxmodx>
#include <amxmisc>
#include <cstrike>
#include <fakemeta>
#include <hamsandwich>
#include <cs_ham_bots_api>
#include <zp50_core_const>

#define MAX_CSDM_SPAWNS 128

#define SPAWN_DATA_ORIGIN_X 0
#define SPAWN_DATA_ORIGIN_Y 1
#define SPAWN_DATA_ORIGIN_Z 2
#define SPAWN_DATA_ANGLES_X 3
#define SPAWN_DATA_ANGLES_Y 4
#define SPAWN_DATA_ANGLES_Z 5
#define SPAWN_DATA_V_ANGLES_X 6
#define SPAWN_DATA_V_ANGLES_Y 7
#define SPAWN_DATA_V_ANGLES_Z 8

new Float:g_spawns_csdm[MAX_CSDM_SPAWNS][SPAWN_DATA_V_ANGLES_Z+1], Float:g_spawns_regular[MAX_CSDM_SPAWNS][SPAWN_DATA_V_ANGLES_Z+1]
new g_SpawnCountCSDM, g_SpawnCountRegular

new cvar_random_spawning

public plugin_init()
{
	register_plugin("[ZP] Random Spawning", ZP_VERSION_STRING, "ZP Dev Team")
	
	cvar_random_spawning = register_cvar("zp_random_spawning_csdm", "1") // 1-use CSDM spawns // 0-use regular spawns
	
	// Collect random spawn points
	load_spawns()
}


public plugin_natives()
{
	register_library("zp50_random_spawn")
	register_native("zp_random_spawn_do", "native_random_spawn_do")
}

public native_random_spawn_do(plugin_id, num_params)
{
	new id = get_param(1)
	
	if (!is_user_alive(id))
	{
		log_error(AMX_ERR_NATIVE, "[ZP] Invalid Player (%d)", id)
		return false;
	}
	
	new csdmspawns = get_param(2)
	
	do_random_spawn(id, csdmspawns)
	return true;
}

// ZP Player Spawn Post Forward
public zp_fw_core_spawn_post(id)
{
	do_random_spawn(id, get_pcvar_num(cvar_random_spawning))
}

// Place user at a random spawn
do_random_spawn(id, csdmspawns = true)
{
	new hull, spawn_index, current_index
	
	// Get whether the player is crouching
	hull = (pev(id, pev_flags) & FL_DUCKING) ? HULL_HEAD : HULL_HUMAN
	
	// Use CSDM spawns?
	if (csdmspawns && g_SpawnCountCSDM)
	{
		// Choose random spawn to start looping at
		spawn_index = random_num(0, g_SpawnCountCSDM - 1)
		
		// Try to find a clear spawn
		for (current_index = spawn_index + 1; /*no condition*/; current_index++)
		{
			// Start over when we reach the end
			if (current_index >= g_SpawnCountCSDM) current_index = 0
			
			// Fetch spawn data: origin
			static Float:spawndata[3]
			spawndata[0] = g_spawns_csdm[current_index][SPAWN_DATA_ORIGIN_X]
			spawndata[1] = g_spawns_csdm[current_index][SPAWN_DATA_ORIGIN_Y]
			spawndata[2] = g_spawns_csdm[current_index][SPAWN_DATA_ORIGIN_Z]
			
			// Free spawn space?
			if (is_hull_vacant(spawndata, hull))
			{
				// Engfunc_SetOrigin is used so ent's mins and maxs get updated instantly
				engfunc(EngFunc_SetOrigin, id, spawndata)
				
				// Fetch spawn data: angles
				spawndata[0] = g_spawns_csdm[current_index][SPAWN_DATA_ANGLES_X]
				spawndata[1] = g_spawns_csdm[current_index][SPAWN_DATA_ANGLES_Y]
				spawndata[2] = g_spawns_csdm[current_index][SPAWN_DATA_ANGLES_Z]
				set_pev(id, pev_angles, spawndata)
				
				// Fetch spawn data: view angles
				spawndata[0] = g_spawns_csdm[current_index][SPAWN_DATA_V_ANGLES_X]
				spawndata[1] = g_spawns_csdm[current_index][SPAWN_DATA_V_ANGLES_Y]
				spawndata[2] = g_spawns_csdm[current_index][SPAWN_DATA_V_ANGLES_Z]
				set_pev(id, pev_v_angle, spawndata)
				
				break;
			}
			
			// Loop completed, no free space found
			if (current_index == spawn_index) break;
		}
	}
	else if (g_SpawnCountRegular)
	{
		// Choose random spawn to start looping at
		spawn_index = random_num(0, g_SpawnCountRegular - 1)
		
		// Try to find a clear spawn
		for (current_index = spawn_index + 1; /*no condition*/; current_index++)
		{
			// Start over when we reach the end
			if (current_index >= g_SpawnCountRegular) current_index = 0
			
			// Fetch spawn data: origin
			static Float:spawndata[3]
			spawndata[0] = g_spawns_regular[current_index][SPAWN_DATA_ORIGIN_X]
			spawndata[1] = g_spawns_regular[current_index][SPAWN_DATA_ORIGIN_Y]
			spawndata[2] = g_spawns_regular[current_index][SPAWN_DATA_ORIGIN_Z]
			
			// Free spawn space?
			if (is_hull_vacant(spawndata, hull))
			{
				// Engfunc_SetOrigin is used so ent's mins and maxs get updated instantly
				engfunc(EngFunc_SetOrigin, id, spawndata)
				
				// Fetch spawn data: angles
				spawndata[0] = g_spawns_regular[current_index][SPAWN_DATA_ANGLES_X]
				spawndata[1] = g_spawns_regular[current_index][SPAWN_DATA_ANGLES_Y]
				spawndata[2] = g_spawns_regular[current_index][SPAWN_DATA_ANGLES_Z]
				set_pev(id, pev_angles, spawndata)
				
				// Fetch spawn data: view angles
				spawndata[0] = g_spawns_regular[current_index][SPAWN_DATA_V_ANGLES_X]
				spawndata[1] = g_spawns_regular[current_index][SPAWN_DATA_V_ANGLES_Y]
				spawndata[2] = g_spawns_regular[current_index][SPAWN_DATA_V_ANGLES_Z]
				set_pev(id, pev_v_angle, spawndata)
				
				break;
			}
			
			// Loop completed, no free space found
			if (current_index == spawn_index) break;
		}
	}
}

// Checks if a space is vacant (credits to VEN)
stock is_hull_vacant(Float:origin[3], hull)
{
	engfunc(EngFunc_TraceHull, origin, origin, 0, hull, 0, 0)
	
	if (!get_tr2(0, TR_StartSolid) && !get_tr2(0, TR_AllSolid) && get_tr2(0, TR_InOpen))
		return true;
	
	return false;
}


// Collect random spawn points
stock load_spawns()
{
	// Check for CSDM spawns of the current map
	new cfgdir[32], mapname[32], filepath[100], linedata[64]
	get_configsdir(cfgdir, charsmax(cfgdir))
	get_mapname(mapname, charsmax(mapname))
	formatex(filepath, charsmax(filepath), "%s/csdm/%s.spawns.cfg", cfgdir, mapname)
	
	// Load CSDM spawns if present
	if (file_exists(filepath))
	{
		new csdmdata[10][6], file = fopen(filepath,"rt")
		
		while (file && !feof(file))
		{
			fgets(file, linedata, charsmax(linedata))
			
			// invalid spawn
			if(!linedata[0] || str_count(linedata,' ') < 2) continue;
			
			// get spawn point data
			parse(linedata,csdmdata[0],5,csdmdata[1],5,csdmdata[2],5,csdmdata[3],5,csdmdata[4],5,csdmdata[5],5,csdmdata[6],5,csdmdata[7],5,csdmdata[8],5,csdmdata[9],5)
			
			// origin
			g_spawns_csdm[g_SpawnCountCSDM][SPAWN_DATA_ORIGIN_X] = floatstr(csdmdata[0])
			g_spawns_csdm[g_SpawnCountCSDM][SPAWN_DATA_ORIGIN_Y] = floatstr(csdmdata[1])
			g_spawns_csdm[g_SpawnCountCSDM][SPAWN_DATA_ORIGIN_Z] = floatstr(csdmdata[2])
			
			// angles
			g_spawns_csdm[g_SpawnCountCSDM][SPAWN_DATA_ANGLES_X] = floatstr(csdmdata[3])
			g_spawns_csdm[g_SpawnCountCSDM][SPAWN_DATA_ANGLES_Y] = floatstr(csdmdata[4])
			g_spawns_csdm[g_SpawnCountCSDM][SPAWN_DATA_ANGLES_Z] = floatstr(csdmdata[5])
			
			// view angles
			g_spawns_csdm[g_SpawnCountCSDM][SPAWN_DATA_V_ANGLES_X] = floatstr(csdmdata[7])
			g_spawns_csdm[g_SpawnCountCSDM][SPAWN_DATA_V_ANGLES_Y] = floatstr(csdmdata[8])
			g_spawns_csdm[g_SpawnCountCSDM][SPAWN_DATA_V_ANGLES_Z] = floatstr(csdmdata[9])
			
			// increase spawn count
			g_SpawnCountCSDM++
			if (g_SpawnCountCSDM >= sizeof g_spawns_csdm) break;
		}
		if (file) fclose(file)
	}
	else
	{
		// Collect regular spawns
		collect_spawns_ent("info_player_start")
		collect_spawns_ent("info_player_deathmatch")
	}
}

// Collect spawn points from entity origins
stock collect_spawns_ent(const classname[])
{
	new Float:data[3]
	new ent = -1
	while ((ent = engfunc(EngFunc_FindEntityByString, ent, "classname", classname)) != 0)
	{
		// get origin
		pev(ent, pev_origin, data)
		g_spawns_regular[g_SpawnCountRegular][SPAWN_DATA_ORIGIN_X] = data[0]
		g_spawns_regular[g_SpawnCountRegular][SPAWN_DATA_ORIGIN_Y] = data[1]
		g_spawns_regular[g_SpawnCountRegular][SPAWN_DATA_ORIGIN_Z] = data[2]
		
		// angles
		pev(ent, pev_angles, data)
		g_spawns_regular[g_SpawnCountRegular][SPAWN_DATA_ANGLES_X] = data[0]
		g_spawns_regular[g_SpawnCountRegular][SPAWN_DATA_ANGLES_Y] = data[1]
		g_spawns_regular[g_SpawnCountRegular][SPAWN_DATA_ANGLES_Z] = data[2]
		
		// view angles
		pev(ent, pev_v_angle, data)
		g_spawns_regular[g_SpawnCountRegular][SPAWN_DATA_V_ANGLES_X] = data[0]
		g_spawns_regular[g_SpawnCountRegular][SPAWN_DATA_V_ANGLES_Y] = data[1]
		g_spawns_regular[g_SpawnCountRegular][SPAWN_DATA_V_ANGLES_Z] = data[2]
		
		// increase spawn count
		g_SpawnCountRegular++
		if (g_SpawnCountRegular >= sizeof g_spawns_regular) break;
	}
}

// Stock by (probably) Twilight Suzuka -counts number of chars in a string
stock str_count(const str[], searchchar)
{
	new count, i, len = strlen(str)
	
	for (i = 0; i <= len; i++)
	{
		if(str[i] == searchchar)
			count++
	}
	
	return count;
}