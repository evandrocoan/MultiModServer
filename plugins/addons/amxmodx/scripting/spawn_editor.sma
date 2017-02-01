/**
 * csdm_preset_editor.sma
 * Allows for Counter-Strike to be played as DeathMatch.
 *
 * CSDM Preset Spawn Editor
 *
 * By Freecode
 * (C)2003-2006 David "BAILOPAN" Anderson
 *
 *  Give credit where due.
 *  Share the source - it sets you free
 *  http://www.opensource.org/
 *  http://www.gnu.org/
 */

#include <amxmodx>
#include <amxmisc>
#include <fakemeta>
#include <csdm>

#pragma semicolon 1

//Tampering with the author and name lines will violate copyrights
new PLUGINNAME[] = "CSDM Spawn Editor";
new VERSION[] = CSDM_VERSION;
new AUTHORS[] = "CSDM Team";

#define	MAX_SPAWNS 			60

//Menus
new g_MainMenu[] = "CSDM: Spawn Manager";
new g_MainMenuID = -1;				
new g_cMain;

new g_SpawnVecs[MAX_SPAWNS][3];	
new g_SpawnAngles[MAX_SPAWNS][3];
new g_SpawnVAngles[MAX_SPAWNS][3];

new g_TotalSpawns = 0;

new g_Ents[MAX_SPAWNS];
new g_Ent[33];					// Current closest spawn

new Float:red[3] = {255.0,0.0,0.0};
new Float:yellow[3] = {255.0,200.0,20.0};

new g_iszInfoTarget;

public plugin_init()
{
	register_plugin(PLUGINNAME, VERSION, AUTHORS);

	g_iszInfoTarget = engfunc(EngFunc_AllocString, "info_target");
	readSpawns();
	register_concmd("edit_spawns", "Command_EditSpawns", ADMIN_MAP, "Edits spawn configuration");
	
	new menu = csdm_main_menu();
	menu_additem(menu, "Spawn Editor", "edit_spawns", ADMIN_MAP);
}

readSpawns()
{
	new Map[32], config[32],  MapFile[256];
	
	get_mapname(Map, 31);
	get_configsdir(config, 31);
	format(MapFile, 255, "%s\csdm\%s.spawns.cfg",config, Map);
	g_TotalSpawns = 0;
	
	if (file_exists(MapFile)) 
	{
		new Data[124], len;
		new line = 0;
		new pos[11][8];
    		
		while(g_TotalSpawns < MAX_SPAWNS && (line = read_file(MapFile , line , Data , 123 , len) ) != 0 ) 
		{
			if (strlen(Data)<2) continue;
			parse(Data, pos[1], 7, pos[2], 7, pos[3], 7, pos[4], 7, pos[5], 7, pos[6], 7, pos[7], 7, pos[8], 7, pos[9], 7, pos[10], 7);	// KWo - 05.11.2005
			
			// Origin
			g_SpawnVecs[g_TotalSpawns][0] = str_to_num(pos[1]);
			g_SpawnVecs[g_TotalSpawns][1] = str_to_num(pos[2]);
			g_SpawnVecs[g_TotalSpawns][2] = str_to_num(pos[3]);
			
			//Angles
			g_SpawnAngles[g_TotalSpawns][0] = str_to_num(pos[4]);
			g_SpawnAngles[g_TotalSpawns][1] = str_to_num(pos[5]);
			g_SpawnAngles[g_TotalSpawns][2] = str_to_num(pos[6]);

			// Teams
						
			//v-Angles
			g_SpawnVAngles[g_TotalSpawns][0] = str_to_num(pos[8]);
			g_SpawnVAngles[g_TotalSpawns][1] = str_to_num(pos[9]);
			g_SpawnVAngles[g_TotalSpawns][2] = str_to_num(pos[10]);
			
			g_TotalSpawns++;
			
			
		}
	}
}

buildMenu()
{
// Create Menu
	g_MainMenuID = menu_create(g_MainMenu, "m_MainHandler");

//Menu Callbacks
	g_cMain = menu_makecallback("c_Main");

	menu_additem(g_MainMenuID, "Add current position to Spawn","1", 0, g_cMain);
	menu_additem(g_MainMenuID, "Edit closest spawn (yellow) to Current Position","2", 0, g_cMain);
	menu_additem(g_MainMenuID, "Delete closest Spawn","3", 0, g_cMain);
	menu_additem(g_MainMenuID, "Refresh Closest Spawn", "4", 0, g_cMain);
	menu_additem(g_MainMenuID, "Show statistics", "5", 0, -1);
}

public m_MainHandler(id, menu, item)
{
	if (item == MENU_EXIT)
	{
		ent_remove(-1);
		menu_destroy(menu);	
		return PLUGIN_HANDLED;
	}
	
	// Get item info
	new cmd[6], iName[64];
	new access, callback;
	
	menu_item_getinfo(menu, item, access, cmd,5, iName, 63, callback);
	
	new iChoice = str_to_num(cmd);
	
	switch(iChoice)
	{
		case 1:
		{
			new Float:vecs[3], vec[3];
			new Float:angles[3], angle[3];
			new Float:vangles[3], vangle[3];
			
		
			pev(id, pev_origin, vecs);
			pev(id, pev_angles, angles);
			pev(id, pev_v_angle, vangles);
			
			FVecIVec(vecs,vec);
			FVecIVec(angles,angle);
			FVecIVec(vangles,vangle);
			
			vec[2] += 15;
			add_spawn(vec,angle,vangle);
			menu_display(id, g_MainMenuID, 0);
		}
		case 2:
		{
			new Float:vecs[3], vec[3];
			new Float:angles[3], angle[3];
			new Float:vangles[3], vangle[3];

			pev(id, pev_origin, vecs);
			pev(id, pev_angles, angles);
			pev(id, pev_v_angle, vangles);

			FVecIVec(vecs,vec);
			FVecIVec(angles,angle);
			FVecIVec(vangles,vangle);

			vec[2] += 15;
			edit_spawn(g_Ent[id],vec,angle,vangle);
			menu_display(id, g_MainMenuID, 0);
		}
		case 3:
		{
			ent_unglow(g_Ent[id]);
			delete_spawn(g_Ent[id]);
			g_Ent[id] = closest_spawn(id);
			menu_display(id, g_MainMenuID, 0);				
		}
		case 4:
		{
			ent_unglow(g_Ent[id]);
			g_Ent[id] = closest_spawn(id);
			ent_glow(g_Ent[id],yellow);
			menu_display(id, g_MainMenuID, 0);
		}
		case 5:
		{	
			new Float:Org[3];
			pev(id, pev_origin, Org);
			
			client_print(id, 
				print_chat,
				"Total Spawns: %d ^nCurrent Origin: X: %f  Y: %f  Z: %f", 
				g_TotalSpawns + 1,
				Org[0],
				Org[1],
				Org[2]);
			 
			menu_display(id, g_MainMenuID, 0);
		}
	}
	
	return PLUGIN_HANDLED;
}

public c_Main(id, menu, item)
{
	if (item == MENU_EXIT)
	{
		return PLUGIN_CONTINUE;
	}
	
	new cmd[6], fItem[326], iName[64];
	new access, callback;
	
	menu_item_getinfo(menu, item, access, cmd,5, iName, 63, callback);
	
	new num = str_to_num(cmd);
		
	switch(num)
	{
		case	1:
		{
			if (g_TotalSpawns == MAX_SPAWNS)
			{
				format(fItem,325,"Add Spawns - Max Spawn Limit Reached");
				menu_item_setname(menu, item, fItem );
				return ITEM_DISABLED;
			}
			else
			{
				format(fItem,325,"Add current position to Spawn");
				menu_item_setname(menu, item, fItem );
				return ITEM_ENABLED;
			}
		}
		case	2:
		{
			if (g_TotalSpawns < 1)
			{
				format(fItem,325,"Edit Spawn - No spawns");
				menu_item_setname(menu, item, fItem );
				return ITEM_DISABLED;
			}
			else if (g_Ent[id]==0)
			{
				format(fItem,325,"Edit Spawn - No spawn marked");
				menu_item_setname(menu, item, fItem );
				return ITEM_DISABLED;
			}
			else
			{
				format(fItem,325,"Edit closest spawn (yellow) to Current Position");
				menu_item_setname(menu, item, fItem );
				return ITEM_ENABLED;
			}
		}
		case	3:
		{
			if (g_TotalSpawns < 1)
			{
				format(fItem,325,"Delete Spawn - No spawns");
				menu_item_setname(menu, item, fItem );
				return ITEM_DISABLED;
			}
			else if (g_Ent[id]==0)
			{
				format(fItem,325,"Delete Spawn - No spawn marked");
				menu_item_setname(menu, item, fItem );
				return ITEM_DISABLED;
			}			
			else
			{
				new iorg[3];
				get_user_origin(id, iorg);
				new distance = get_distance(iorg, g_SpawnVecs[g_Ent[id]]);
					
				if (distance > 200)
				{
					format(fItem,325,"Delete Spawn - Marked spawn far away");
					menu_item_setname(menu, item, fItem );
					return ITEM_DISABLED;
				}
				else
				{
					format(fItem,325,"Delete closest Spawn");
					menu_item_setname(menu, item, fItem );
					return ITEM_ENABLED;
				}
			}
		}
	}
	
	return PLUGIN_HANDLED;
}

add_spawn(vecs[3], angles[3], vangles[3])
{
	new Map[32], config[32],  MapFile[256];
	
	get_mapname(Map, 31);
	get_configsdir(config, 31);
	format(MapFile, 255, "%s\csdm\%s.spawns.cfg",config, Map);

	new line[128];
	format(line, 127, "%d %d %d %d %d %d 0 %d %d %d",vecs[0], vecs[1], vecs[2], angles[0], angles[1], angles[2], vangles[0], vangles[1], vangles[2]);
	write_file(MapFile, line, -1);
	
	// origin
	g_SpawnVecs[g_TotalSpawns][0] = vecs[0];
	g_SpawnVecs[g_TotalSpawns][1] = vecs[1];
	g_SpawnVecs[g_TotalSpawns][2] = vecs[2];
	// Angles
	g_SpawnAngles[g_TotalSpawns][0] = angles[0];
	g_SpawnAngles[g_TotalSpawns][1] = angles[1];
	g_SpawnAngles[g_TotalSpawns][2] = angles[2];

	// Teams
						
	// v-Angles
	g_SpawnVAngles[g_TotalSpawns][0] = vangles[0];
	g_SpawnVAngles[g_TotalSpawns][1] = vangles[1];
	g_SpawnVAngles[g_TotalSpawns][2] = vangles[2];
	
	ent_make(g_TotalSpawns);
	g_TotalSpawns++;
	
}

edit_spawn(ent, vecs[3], angles[3], vangles[3])
{
	new Map[32], config[32],  MapFile[256];
	
	get_mapname(Map, 31);
	get_configsdir( config, 31);
	format(MapFile, 255, "%s\csdm\%s.spawns.cfg",config, Map);
	
	if (file_exists(MapFile)) 
	{
		new Data[124], len;
    		new line = 0;
    		new pos[11][8];
    		new currentVec[3], newSpawn[128];
    		
		while ((line = read_file(MapFile , line , Data , 123 , len) ) != 0 ) 
		{
			if (strlen(Data)<2) continue;
			
			parse(Data,pos[1],7,pos[2],7,pos[3],7,pos[4],7,pos[5],7,pos[6],7,pos[7],7,pos[8],7,pos[9],7,pos[10],7);
			currentVec[0] = str_to_num(pos[1]);
			currentVec[1] = str_to_num(pos[2]);
			currentVec[2] = str_to_num(pos[3]);
			
			if ( (g_SpawnVecs[ent][0] == currentVec[0]) && (g_SpawnVecs[ent][1] == currentVec[1]) && ( (g_SpawnVecs[ent][2] - currentVec[2])<=15) )
			{	
				format(newSpawn, 127, "%d %d %d %d %d %d 0 %d %d %d",vecs[0], vecs[1], vecs[2], angles[0], angles[1], angles[2], vangles[0], vangles[1], vangles[2]); 
				write_file(MapFile, newSpawn, line-1);
				
				ent_remove(ent);
				
				g_SpawnVecs[ent][0] = vecs[0];
				g_SpawnVecs[ent][1] = vecs[1];
				g_SpawnVecs[ent][2] = vecs[2];

				g_SpawnAngles[ent][0] = angles[0];
				g_SpawnAngles[ent][1] = angles[1];
				g_SpawnAngles[ent][2] = angles[2];

				g_SpawnVAngles[ent][0] = vangles[0];
				g_SpawnVAngles[ent][1] = vangles[1];
				g_SpawnVAngles[ent][2] = vangles[2];
				
				ent_make(ent);
				ent_glow(ent,red);
				
				break;
			}
		}
	}
}
	
delete_spawn(ent)
{
	new Map[32], config[32],  MapFile[256];
	
	get_mapname(Map, 31);
	get_configsdir( config, 31);
	format(MapFile, 255, "%s\csdm\%s.spawns.cfg",config, Map);
	
	if (file_exists(MapFile)) 
	{
		new Data[124], len;
    		new line = 0;
    		new pos[11][8];
    		new currentVec[3];
    		
		while ((line = read_file(MapFile , line , Data , 123 , len) ) != 0 ) 
		{
			if (strlen(Data)<2) continue;
			
			parse(Data,pos[1],7,pos[2],7,pos[3],7);
			currentVec[0] = str_to_num(pos[1]);
			currentVec[1] = str_to_num(pos[2]);
			currentVec[2] = str_to_num(pos[3]);
			
			if ( (g_SpawnVecs[ent][0] == currentVec[0]) && (g_SpawnVecs[ent][1] == currentVec[1]) && ( (g_SpawnVecs[ent][2] - currentVec[2])<=15) )
			{
				write_file(MapFile, "", line-1);
				
				ent_remove(-1);
				readSpawns();
				ent_make(-1);
				
				break;
			}
		}
	}
}

closest_spawn(id)
{
	new origin[3];
	new lastDist = 999999;
	new closest;
	
	get_user_origin(id, origin);
	for (new x = 0; x < g_TotalSpawns; x++)
	{
		new distance = get_distance(origin, g_SpawnVecs[x]);
		
		if (distance < lastDist)
		{
			lastDist = distance;
			closest = x;
		}
	}
	return closest;
}

ent_make(id)
{
	new iEnt;

	if(id < 0)
	{
		for (new x = 0; x < g_TotalSpawns; x++)
		{
	
			iEnt = engfunc(EngFunc_CreateNamedEntity, g_iszInfoTarget);
			set_pev(iEnt, pev_classname, "view_spawn");
			engfunc(EngFunc_SetModel, iEnt, "models/player/vip/vip.mdl");
			set_pev(iEnt, pev_solid, SOLID_SLIDEBOX);
			set_pev(iEnt, pev_movetype, MOVETYPE_NOCLIP);
			set_pev(iEnt, pev_flags, pev(iEnt, pev_flags) & FL_ONGROUND);
			set_pev(iEnt, pev_sequence, 1);
			
			if (g_Ents[x])
			{
				engfunc(EngFunc_RemoveEntity, g_Ents[x]);
			}

			g_Ents[x] = iEnt;
			ent_unglow(x);
		}
	}
	else
	{
		iEnt = engfunc(EngFunc_CreateNamedEntity, g_iszInfoTarget);
		set_pev(iEnt, pev_classname, "view_spawn");
		engfunc(EngFunc_SetModel, iEnt, "models/player/vip/vip.mdl");
		set_pev(iEnt, pev_solid, SOLID_SLIDEBOX);
		set_pev(iEnt, pev_movetype, MOVETYPE_NOCLIP);
		set_pev(iEnt, pev_sequence, 1);
		set_pev(iEnt, pev_flags, pev(iEnt, pev_flags) & FL_ONGROUND);
		
		if (g_Ents[id])
		{
			engfunc(EngFunc_RemoveEntity, g_Ents[id]);
		}

		g_Ents[id] = iEnt;			
		ent_unglow(id);
	}
}

ent_remove(ent)
{
	if( ent < 0 )
	{
		for( new i = 0; i < g_TotalSpawns; i++)
		{
			if(pev_valid(g_Ents[i]))
			{
				engfunc(EngFunc_RemoveEntity, g_Ents[i]);
				g_Ents[i] = 0;
			}
		}
	} else {
		engfunc(EngFunc_RemoveEntity, g_Ents[ent]); //remove_entity(ent)
		g_Ents[ent] = 0;
	}
}

ent_glow(ent,Float:color[3])
{
	new iEnt = g_Ents[ent];
	
	if (iEnt)
	{
		set_ent_pos(ent);
		
		set_pev(iEnt, pev_renderfx, kRenderFxGlowShell); 
		set_pev(iEnt, pev_renderamt, 127.0);				
		set_pev(iEnt, pev_rendermode, kRenderTransAlpha);
		set_pev(iEnt, pev_rendercolor, color) ;
	}
	
}

ent_unglow(ent)
{
	new iEnt = g_Ents[ent];
	
	if (iEnt)
	{
		set_ent_pos(ent);
		
		set_pev(iEnt, pev_renderfx, kRenderFxNone); 
		set_pev(iEnt, pev_renderamt, 255.0);
		set_pev(iEnt, pev_rendermode, kRenderTransAlpha);		
	}
}

set_ent_pos(ent)
{
	new iEnt = g_Ents[ent];
	
	new Float:org[3];
	IVecFVec(g_SpawnVecs[ent],org);
	set_pev( iEnt, pev_origin, org);
		
	new Float:ang[3];																
	IVecFVec(g_SpawnAngles[ent],ang);
	set_pev(iEnt, pev_angles, ang);

	new Float:vang[3];
	IVecFVec(g_SpawnVAngles[ent],vang);
	set_pev(iEnt, pev_v_angle, vang);
	
	set_pev(iEnt, pev_fixangle, 1);
}

public Command_EditSpawns(id, level, cid)
{
	if (!cmd_access(id, level, cid, 1))
	{
		return PLUGIN_HANDLED;
	}
	
	buildMenu();
	ent_make(-1);
	menu_display( id, g_MainMenuID, 0);
	
	return PLUGIN_HANDLED;
}


