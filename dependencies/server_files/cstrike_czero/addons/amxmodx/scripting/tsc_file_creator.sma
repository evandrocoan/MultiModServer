/*
	----------------------
	-*- Licensing Info -*-
	----------------------
	
	Semiclip Mod: File Creator
	by schmurgel1983(@msn.com)
	Copyright (C) 2014 Stefan "schmurgel1983" Focke
	
	This program is free software: you can redistribute it and/or modify it
	under the terms of the GNU General Public License as published by the
	Free Software Foundation, either version 3 of the License, or (at your
	option) any later version.
	
	This program is distributed in the hope that it will be useful, but
	WITHOUT ANY WARRANTY; without even the implied warranty of
	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General
	Public License for more details.
	
	You should have received a copy of the GNU General Public License along
	with this program. If not, see <http://www.gnu.org/licenses/>.
	
	In addition, as a special exception, the author gives permission to
	link the code of this program with the Half-Life Game Engine ("HL
	Engine") and Modified Game Libraries ("MODs") developed by Valve,
	L.L.C ("Valve"). You must obey the GNU General Public License in all
	respects for all of the code used other than the HL Engine and MODs
	from Valve. If you modify this file, you may extend this exception
	to your version of the file, but you are not obligated to do so. If
	you do not wish to do so, delete this exception statement from your
	version.
	
	No warranties of any kind. Use at your own risk.
	
*/

/*================================================================================
 [Plugin Customization]
=================================================================================*/

#define MAX_STORAGE 64	/* Max stored entities per func_* ¬ 64 */

/*================================================================================
 Customization ends here! Yes, that's it. Editing anything beyond
 here is not officially supported. Proceed at your own risk...
=================================================================================*/

#include <amxmodx>
#include <engine>
#include <fakemeta>

#pragma semicolon 1

/*================================================================================
 [Constants, Offsets and Defines]
=================================================================================*/

/* All supported entity classes */
new const ENTITY_CLASSES[][] =
{
	"func_button",
	"func_door",
	"func_door_rotating",
	"func_guntarget",
	"func_pendulum",
	"func_plat",
	"func_platrot",
	"func_rot_button",
	"func_rotating",
	"func_tank",
	"func_trackchange",
	"func_tracktrain",
	"func_train",
	"func_vehicle",
	"momentary_door",
	"momentary_rot_button"
};
const CLASS_SIZE = sizeof(ENTITY_CLASSES);

#define SF_VEHICLE_PASSABLE  0x0008
#define SF_ROTATING_NOTSOLID 0x0040

/*================================================================================
 [Global Variables]
=================================================================================*/

/* Server Global */
new g_szEntitiesFile[128],
	g_szMapName[32];

new g_iEntityNum[CLASS_SIZE],
	g_iEntityIndex[CLASS_SIZE][MAX_STORAGE],
	g_iEntityEnable[CLASS_SIZE][MAX_STORAGE],
	g_iEntityDamage[CLASS_SIZE][MAX_STORAGE];

new g_szEntityModel[CLASS_SIZE][MAX_STORAGE][6];

/*================================================================================
 [Natives, Init and Cfg]
=================================================================================*/

public plugin_init()
{
	/* Register plugin */
	register_plugin("[SCM] File Creator", "1.0.3", "schmurgel1983");
	
	/* Store Map name... */
	get_mapname(g_szMapName, charsmax(g_szMapName));
	
	new szDir[192];
	get_configsdir(szDir, charsmax(szDir));
	format(szDir, charsmax(szDir), "%s/scm/entities", szDir);
	
	/* ...and *.ini file */
	format(g_szEntitiesFile, charsmax(g_szEntitiesFile), "%s/%s.ini", szDir, g_szMapName);
}

public plugin_cfg()
{
	/* <mapname>.ini file already exists */
	if (file_exists(g_szEntitiesFile))
		return;
	
	/* Get all entities */
	for (new iIndex = 0, iEntity, iNum; iIndex < CLASS_SIZE; iIndex++)
	{
		/* Pre-Define entities, accurate is not 100% */
		iEntity = -1, iNum = 0;
		while ((iEntity = find_ent_by_class(iEntity, ENTITY_CLASSES[iIndex])) != 0)
		{
			/* Set Entity Index */
			g_iEntityIndex[iIndex][iNum] = iEntity;
			
			/* Get BSP Model */
			pev(iEntity, pev_model, g_szEntityModel[iIndex][iNum], charsmax(g_szEntityModel[][]));
			
			/* Setup Entity Data */
			switch (ENTITY_CLASSES[iIndex][5])
			{
				case 'b': /* func_button */
				{
					if (pev(iEntity, pev_spawnflags) & SF_BUTTON_DONTMOVE)
						g_iEntityEnable[iIndex][iNum] = 0;
					else
						g_iEntityEnable[iIndex][iNum] = 1;
				}
				case 'd':
				{
					/* func_door */
					if (pev(iEntity, pev_spawnflags) & SF_DOOR_PASSABLE)
						g_iEntityEnable[iIndex][iNum] = 0;
					else
						g_iEntityEnable[iIndex][iNum] = 1;
				}
				case 'g': g_iEntityEnable[iIndex][iNum] = 1; /* func_guntarget */
				case 'p':
				{
					/* func_pendulum */
					if (ENTITY_CLASSES[iIndex][9] == 'u')
					{
						if (pev(iEntity, pev_spawnflags) & SF_DOOR_PASSABLE)
							g_iEntityEnable[iIndex][iNum] = 0;
						else
							g_iEntityEnable[iIndex][iNum] = 1;
					}
					else /* func_plat, func_platrot */
						g_iEntityEnable[iIndex][iNum] = 1;
				}
				case 'r':
				{
					/* func_rot_button */
					if (ENTITY_CLASSES[iIndex][9] == 'b')
					{
						if (pev(iEntity, pev_spawnflags) & SF_ROTBUTTON_NOTSOLID)
							g_iEntityEnable[iIndex][iNum] = 0;
						else
							g_iEntityEnable[iIndex][iNum] = 1;
					}
					else /* func_rotating */
					{
						if (pev(iEntity, pev_spawnflags) & SF_ROTATING_NOTSOLID)
							g_iEntityEnable[iIndex][iNum] = 0;
						else
							g_iEntityEnable[iIndex][iNum] = 1;
					}
				}
				case 't':
				{
					switch (ENTITY_CLASSES[iIndex][10])
					{
						case 'd': /* momentary_door */
						{
							if (pev(iEntity, pev_spawnflags) & SF_DOOR_PASSABLE)
								g_iEntityEnable[iIndex][iNum] = 0;
							else
								g_iEntityEnable[iIndex][iNum] = 1;
						}
						case 'r': /* momentary_rot_button */
						{
							if (pev(iEntity, pev_spawnflags) & SF_MOMENTARY_DOOR)
								g_iEntityEnable[iIndex][iNum] = 1;
							else
								g_iEntityEnable[iIndex][iNum] = 0;
						}
						default:
						{
							if (ENTITY_CLASSES[iIndex][6] == 'a') /* func_tank */
								g_iEntityEnable[iIndex][iNum] = 1;
							else if (ENTITY_CLASSES[iIndex][10] == 'c') /* func_trackchange */
								g_iEntityEnable[iIndex][iNum] = 1;
							else /* func_tracktrain, func_train */
							{
								if (pev(iEntity, pev_spawnflags) & SF_TRAIN_PASSABLE)
									g_iEntityEnable[iIndex][iNum] = 0;
								else
									g_iEntityEnable[iIndex][iNum] = 1;
							}
						}
					}
				}
				case 'v': /* func_vehicle */
				{
					if (pev(iEntity, pev_spawnflags) & SF_VEHICLE_PASSABLE)
						g_iEntityEnable[iIndex][iNum] = 0;
					else
						g_iEntityEnable[iIndex][iNum] = 1;
				}
			}
			
			/* All entities do damage as default */
			g_iEntityDamage[iIndex][iNum] = 1;
			
			if (++iNum >= MAX_STORAGE)
				break;
		}
		g_iEntityNum[iIndex] = iNum;
	}
	
	/* Save */
	SaveMapFile();
}

/*================================================================================
 [Other Functions and Tasks]
=================================================================================*/

SaveMapFile()
{
	new iFile = fopen(g_szEntitiesFile, "wt+");
	if (!iFile)
	{
		new szError[128];
		format(szError, charsmax(szError), "Error: Can't open '%s' file.", g_szEntitiesFile);
		set_fail_state(szError);
		return;
	}
	
	/* Info */
	new szBuffer[96];
	format(szBuffer, charsmax(szBuffer), "// Map: %s^n//^n// func_ *model semiclip damage^n^n", g_szMapName);
	fputs(iFile, szBuffer);
	
	for (new i = 0, j, iNum; i < CLASS_SIZE; i++)
	{
		iNum = g_iEntityNum[i];
		if (!iNum) continue;
		
		for (j = 0; j < iNum; j++)
		{
			if (pev_valid(g_iEntityIndex[i][j]))
			{
				format(szBuffer, charsmax(szBuffer), "%s %s %s %s^n", ENTITY_CLASSES[i], g_szEntityModel[i][j], g_iEntityEnable[i][j] ? "enable" : "ignore", g_iEntityDamage[i][j] ? "enable" : "disable");
				fputs(iFile, szBuffer);
			}
		}
	}
	fclose(iFile);
}

/*================================================================================
 [Stocks]
=================================================================================*/

stock get_configsdir(name[], len)
{
	return get_localinfo("amxx_configsdir", name, len);
}
