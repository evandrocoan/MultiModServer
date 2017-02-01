/*	========================================================
*	- NAME:
*	  + CS Surf Boards
*
*	- DESCRIPTION:
*	  + This plugin will let you add a NPC to any map in which
*	  + you can talk to get a surf board. The surf board will change
*	  + animations depending on what you are doing to make it look
*	  + like you are surfing. The surf board is just for looks and
*	  + doesn't do anything.
*
*	- CREDITS:
*	  + Jester for making the surf board model for the plugin.
*	  + Anyone else I may have forgot.
*
*	---------------
*	Admin Commands:
*	---------------
*	- Type in console 'amx_createnpc' to create the surfboard NPC.
*
*	-------------
*	Server cvars:
*	-------------
*	- sb_npc_model "model-name"
*	  + Default model is vip.
*	  + To add custom models place them in the models/player folder.
*	  + The custom model must be stored in a folder with the same name as the model.
*	  + Example custom model structure: models/player/customguy/customguy.mdl
*
*	---------
*	Versions:
*	---------
*	1.1 - Added a cvar to change the NPC model. (11-08-2007).
*	1.0 - First version made and works. (08-25-2007).
*/

#include <amxmodx>
#include <amxmisc>
#include <fakemeta>

#define PLUGIN "CS Surf Boards"
#define VERSION "1.0"
#define AUTHOR "hlstriker"

//////////////////////////////////////
// SURF BOARD STUFF!
//////////////////////////////////////
#define BOARD_MODEL1 "models/board3.mdl" // Model by Jester
new bool:hasBoard[33];
new boards[33];
new bool:shouldSurf[33];
//////////////////////////////////////

//////////////////////////////////////
// CVAR STUFF!
//////////////////////////////////////
#define CVAR_NAME "sb_npc_model"
new model[32];
new g_npcModel[63];
new g_modelName;
//////////////////////////////////////

//////////////////////////////////////
// NPC STUFF!
//////////////////////////////////////
#define menuKeys	((1<<0)|(1<<1))

new g_npc;
new g_weapon;
new bool:npcMade;
new bool:inMenu[33];
new filename[256];
//////////////////////////////////////

public plugin_init()
{
	new confFolder[32];
	get_mapname(filename, 255);
	get_configsdir(confFolder, 31);
	format(filename, 255, "%s/npcsaved/%s.coord", confFolder, filename);
	set_task(3.0, "loadNPC");
	
	register_plugin(PLUGIN, VERSION, AUTHOR);
	register_forward(FM_PlayerPreThink, "hook_PlayerPreThink");
	register_forward(FM_AddToFullPack, "fw_AddToFullPack", 1);
	register_forward(FM_Touch, "hook_Touch");
	register_event("ResetHUD", "hook_ResetHUD", "be");
	register_menucmd(register_menuid("npcMenu"), menuKeys, "npcMenuEnter");
	register_concmd("amx_createnpc", "tryCreateNPC", ADMIN_RCON, "- creates the surf board NPC");
}

public plugin_precache()
{
	g_modelName = register_cvar(CVAR_NAME, "vip");
	get_pcvar_string(g_modelName, model, 31);
	formatex(g_npcModel, 63, "models/player/%s/%s.mdl", model, model);
	
	precache_model(g_npcModel);
	precache_model(BOARD_MODEL1);
}

public client_connect(id)
{
	inMenu[id] = false;
	hasBoard[id] = false;
}

public client_disconnect(id)
{
	if(hasBoard[id])
		engfunc(EngFunc_RemoveEntity, boards[id]);
	hasBoard[id] = false;
}

public hook_ResetHUD(id)
	inMenu[id] = false;

public hook_Touch(ent, id)
{
	if(!is_user_alive(id))
		return FMRES_IGNORED;
	
	new classname[32];
	pev(ent, pev_classname, classname, 31);
	
	if((equali(classname, "worldspawn") || equali(classname, "func_wall")) && hasBoard[id] && !(pev(ent, pev_flags) & FL_ONGROUND))
	{
		remove_task(id);
		shouldSurf[id] = true;
		set_task(0.5, "resetSurfing", id);
	}
	
	if(equali(classname, "shacks_npc") && !inMenu[id])
	{
		inMenu[id] = true;
		
		new name[33], text[512];
		
		get_user_name(id, name, 32);
		format(text, 511, "Yo %s!^n^nWould you like a surf board?^n^n1: Yes   -   2: No", name);
		
		show_menu(id, menuKeys, text, -1, "npcMenu");
	}
	
	return FMRES_IGNORED;
}

public resetSurfing(id)
{
	shouldSurf[id] = false;
}

public fw_AddToFullPack(es_handle,e,ent,host,hostflags,player,pSet)
{
	if(!is_user_alive(ent) || pev(ent, pev_flags) & FL_ONGROUND || !hasBoard[ent] || pev(ent, pev_movetype) == MOVETYPE_FLY)
		return FMRES_IGNORED;
	
	new waterlevel = pev(ent, pev_waterlevel);
	
	if((shouldSurf[ent] || (waterlevel > 0 && waterlevel <= 2)) && !(pev(ent, pev_flags) & FL_ONGROUND))
	{
		// Board under feet
		set_es(es_handle, ES_Sequence, 6);
		set_es(es_handle, ES_GaitSequence, 0);
		set_es(es_handle, ES_Frame, 255.0);
		set_es(es_handle, ES_FrameRate, 1.0);
	}
	else if(pev(ent, pev_flags) & FL_ONGROUND && waterlevel == 0)
	{
		// Board on back
		return FMRES_HANDLED;
	}
	else if(pev(ent, pev_movetype) == MOVETYPE_FLY || !shouldSurf[ent] || waterlevel >= 3)
	{
		// Board under arm
		set_es(es_handle, ES_Sequence, 8);
		set_es(es_handle, ES_GaitSequence, 0);
		set_es(es_handle, ES_Frame, 255.0);
		set_es(es_handle, ES_FrameRate, 1.0);
	}
	
	return FMRES_HANDLED;
}

public hook_PlayerPreThink(id)
{
	if(!is_user_alive(id) || !hasBoard[id])
		return FMRES_IGNORED;
	
	new waterlevel = pev(id, pev_waterlevel);
	
	// if(shouldSurf[id] || (waterlevel > 0 && waterlevel <= 2 && !(pev(id, pev_flags) & FL_ONGROUND)))
	if((shouldSurf[id] || (waterlevel > 0 && waterlevel <= 2)) && !(pev(id, pev_flags) & FL_ONGROUND))
	{
		// Board under feet
		set_pev(boards[id], pev_sequence, 2);
	}
	else if(pev(id, pev_flags) & FL_ONGROUND && waterlevel == 0)
	{
		// Board on back
		set_pev(boards[id], pev_sequence, 1);
	}
	else if(pev(id, pev_movetype) == MOVETYPE_FLY || !shouldSurf[id] || waterlevel >= 3)
	{
		// Board under arm
		set_pev(boards[id], pev_sequence, 0);
	}
	
	return FMRES_HANDLED;
}

public checkBoard(id)
{
	if(!is_user_alive(id))
		return FMRES_IGNORED;
	
	if(!hasBoard[id])
	{
		// Give board
		hasBoard[id] = true;
		boards[id] = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "info_target"));
		set_pev(boards[id], pev_movetype, MOVETYPE_FOLLOW);
		set_pev(boards[id], pev_aiment, id);
		engfunc(EngFunc_SetModel, boards[id], BOARD_MODEL1);
	}
	else
	{
		client_print(id, print_chat, "Yo man, you already have a board!");
	}
	return FMRES_HANDLED;
}

//////////////////////////////////////////////
// NPC STUFF
//////////////////////////////////////////////
public npcMenu(id)
{
	new name[33], text[512];
	
	get_user_name(id, name, 32);
	format(text, 511, "Yo %s!^n^nWould you like a surf board?^n^n1: Yes   -   2: No", name);
	
	show_menu(id, menuKeys, text, -1, "npcMenu");
	return FMRES_HANDLED;
}

public npcMenuEnter(id, key)
{
	switch(key)
	{
		case 0:
		{
			// Key 1
			checkBoard(id);
			inMenu[id] = false;
		}
		case 1:
		{
			// Key 2
			inMenu[id] = false;
		}
	}
}

public tryCreateNPC(id, level, cid)
{
	if(!cmd_access(id, level, cid, 1))
		return FMRES_IGNORED;
	createNPC(id);
	return FMRES_HANDLED;
}

public loadNPC()
	createNPC(0);

public createNPC(id)
{
	new tempModel[32];
	get_pcvar_string(g_modelName, tempModel, 31);
	
	if(!equal(model, tempModel))
	{
		client_print(id, print_chat, "The ^"%s^" cvar was changed. The map must restart before inserting the NPC.", CVAR_NAME);
		return FMRES_IGNORED;
	}
	
	if(npcMade && pev_valid(g_npc))
	{
		engfunc(EngFunc_RemoveEntity, g_npc);
		engfunc(EngFunc_RemoveEntity, g_weapon);
	}
	npcMade = true;
	
	new Float:origin[3], Float:angles[3];
	if(id > 0)
	{
		pev(id, pev_origin, origin);
		pev(id, pev_angles, angles);
	}
	else
	{
		new file = fopen(filename, "r");
		if(file)
		{
			// File exists
			new data[128];
			new i;
			
			while(!feof(file))
			{
				fgets(file, data, 127);
				if(i <= 2) // Line 1-3 = origin
				{
					origin[i] = str_to_float(data);
				}
				else if(i == 3) angles[0] = str_to_float(data);
				else if(i == 4) angles[1] = str_to_float(data);
				else if(i == 5) angles[2] = str_to_float(data);
				i++;
			}
			fclose(file);
		}
		else
		{
			// File doesn't exist, exit function
			return FMRES_IGNORED;
		}
	}
	
	// Create the npc entity
	g_npc = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "info_target"));
	
	engfunc(EngFunc_SetModel, g_npc, g_npcModel);
	engfunc(EngFunc_SetSize, g_npc, Float:{-17.0,-17.0,-36.0}, Float:{17.0,17.0,36.0});
	angles[0] = 0.0;
	set_pev(g_npc, pev_angles, angles);
	
	engfunc(EngFunc_SetOrigin, g_npc, origin);
	
	if(id > 0)
	{
		origin[2] += 80;
		engfunc(EngFunc_SetOrigin, id, origin);
	}
	
	set_pev(g_npc, pev_solid, SOLID_BBOX);
	//set_pev(g_npc, pev_movetype, MOVETYPE_TOSS);
	set_pev(g_npc, pev_classname, "shacks_npc");
	
	// Set the default animation
	set_pev(g_npc, pev_animtime, 2.0);
	set_pev(g_npc, pev_framerate, 1.0);
	set_pev(g_npc, pev_sequence, 1);
	
	// Set bone positions
	set_pev(g_npc, pev_controller_0, 125);
	set_pev(g_npc, pev_controller_1, 125);
	set_pev(g_npc, pev_controller_2, 125);
	set_pev(g_npc, pev_controller_3, 125);
	
	// Set damage and hp
	set_pev(g_npc, pev_takedamage, 0.0);
	
	// Drop to ground?
	engfunc(EngFunc_DropToFloor, g_npc);
	
	// Give item
	give_item(g_npc);
	
	// Save the origin + angles
	if(id > 0)
	{
		new filepointer = fopen(filename, "w+");
		if(filepointer)
		{
			fprintf(filepointer, "%f^n%f^n%f^n%f^n%f^n%f", origin[0], origin[1], origin[2], angles[0], angles[1], angles[2]);
			fclose(filepointer);
			client_print(id, print_chat, "The NPC has been created and saved.");
		}
	}
	
	return FMRES_HANDLED;
}

public give_item(ent)
{
	g_weapon = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "info_target"));
	set_pev(g_weapon, pev_classname, "npc_weapon");
	set_pev(g_weapon, pev_solid, SOLID_NOT);
	set_pev(g_weapon, pev_movetype, MOVETYPE_FOLLOW);
	set_pev(g_weapon, pev_aiment, ent);
	set_pev(g_weapon, pev_sequence, 1);
	engfunc(EngFunc_SetModel, g_weapon, BOARD_MODEL1);
}
