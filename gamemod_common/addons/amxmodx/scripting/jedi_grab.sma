/*******************************************************************************
Ultimate Jedi Grab

Version: 1.1.0
Authors: Jedi Grab by SpaceDude
New commands in Ultimate Jedi Grab by Morpheus759

1.0.0   Release
1.0.1   Added message that tells you what you've grabbed (id and classname)
1.1.0   You can now move cars (with the noclip commands)
You can hurt/kill players by hitting them with a grabbed entity/player (not grabbed with a noclip command)
Fixed crash that happened when you released a trigger entity next to the world (not grabbed with a noclip command)
Added french translation of the menu


Another plugin for those admins who like to abuse their players and have a little fun.
With this plugin you can literally pick players/entities up, drag them around in the air and then
depending on your mood either slam them into the ground or let them go free.
And you can now do many other things. :)


Cvars:

sv_grab_force 10 - sets the amount of force used when grabbing players/entities
sv_grab_glow 1/0 - enables or disables the glow
sv_grab_red 0 - glow RRR (red, 0-255)
sv_grab_green 255 - glow GGG (green, 0-255)
sv_grab_blue 128 - glow BBB (blue, 0-255)
sv_grab_transp 32 - glow transparency (0-255)
sv_grab_beam 1/0 - enables or disables the beam
sv_throw_force 1500 - sets the amount of force used when throwing players/entities
sv_pushpull_speed 35 - sets the speed when pushing/pulling players/entities
sv_speedkill 2500 - sets the speed needed to kill a player when you hit him with a grabbed ent/player
if the speed is lower than this value, the player who has been hit will lose some health


Commands:

grab_toggle [entId/name/authid/#userid] - Press once to grab and again to release.
+grab - Bind a key to +grab
grab_toggle2 [entId/name/authid/#userid] - Press once to grab and again to release (noclip).
+grab2 - Bind a key to +grab2 (noclip)
throw - Throws the grabee.

ent_kill [entity classname] [range] - Kills the entity being looked at. You can specify an entity type and a range.
ent_rotate <y> <y> <z> [entId/name/authid/#userid] - Rotates the entity being looked at. You can specify an entity id or a player id.
ent_droptofloor [entId] - Drops to floor the entity.
ent_setkeyvalue <key> <value> [entId/name/authid/#userid] - Sets keyvalue on the entity being looked at or specified.

ent_es_grab [entId] - Adds the entity to the save list.
ent_es_ungrab - Removes the last entity added from the save list.
ent_es_cancel - Removes all the entities added from the save list.
ent_es_save <name> - Saves all entities grabbed with the name specified.
ent_es_list - Lists all entity saves for the current map.
ent_es_listall - Lists all entity saves on the server.
ent_es_load - Loads the specified entity save. Saves can only be loaded on the map they were saved on.

ent_mm_grab - Selects an entity to be mass moved.
ent_mm_start - Starts the mass move process once all entities have been grabbed.
ent_mm_start2 - Starts the mass move process once all entities have been grabbed (noclip).
ent_mm_end - Releases all entities being mass moved.

ent_grabtype <entity classname> [range] - Grabs a certain entity at a specified range (default 250).
ent_stopgrab - Used to stop moving an entity grabbed with amx_grabtype.

copyent_toggle - Press once to copy and grab and again to release (noclip).
+copyent - Bind a key to +copyent

ent_telestart <name> [x] [y] [z] - Creates a teleporter entrance that leads to the exit with the matching name.
ent_teleend <name> [x] [y] [z] - Creates a teleporter exit that comes from the entrance with a matching name.
ent_teledelete <name> - Deletes the teleporter entrances and exit with the name specified.

ent_stack <amount> <offset x> <offset y> <offset z> - Creates a certain amount of entities each offseted from the last the specified amount.
ent_wall <entId> <rowNum> <colNum> <rowOffset> <colOffset> - Creates a wall made of the entity specified.

ent_lookingat - Gives information about the entity being looked at.
ent_search - Searches for entities within 100 cells of your location.
ent_showx - Creates a temporary line in the x direction.
ent_showy - Creates a temporary line in the y direction.
ent_showz - Creates a temporary line in the z direction.
ent_showkeyvalue [entId/name/authid/#userid] - Shows keyvalues of the entity being looked at or specified.

ent_use [name/authid/#userid] - Makes you/the player use the entity you're looking at (open door, defuse bomb, ..).
ent_undomoving - Places the entity being looked at where it was.

jedichoke - Chokes the grabee for 8 seconds (it damages the grabee with 3 hp per second).


[..] means that the parameter is optional.
<..> means that the parameter is required.

There is also a menu: type "amx_jedigrabmenu" in your console to display it.

You can change the admin access flags for all these commands below.


Setup:

Install the amx file.
Enable VexdUM.


Credit:

Jedi Force Grab
by SpaceDude
email: eayumns@nottingham.ac.uk
MSN: eayumns@nottingham.ac.uk
ICQ: 1615758
IRC: Quakenet, nickname: "SpaceDude"

EntMod by drunkenf00l for the names of some commands and the ideas.

*******************************************************************************/

#include <amxmod>
#include <amxmisc>
#include <fun>
#include <VexdUM>

/*******************************************************************************
* ADMIN ACCESS (read amxconst.inc if you want to modify the access flags)
******************************************************************************/

new const ACCESS_GRAB = ADMIN_LEVEL_B
new const ACCESS_GRAB_TOGGLE = ADMIN_LEVEL_B
new const ACCESS_GRAB2 = ADMIN_LEVEL_B
new const ACCESS_GRAB_TOGGLE2 = ADMIN_LEVEL_B
new const ACCESS_THROW = ADMIN_LEVEL_B
new const ACCESS_PULL = ADMIN_LEVEL_B
new const ACCESS_PUSH = ADMIN_LEVEL_B
new const ACCESS_UNDOMOVING = ADMIN_LEVEL_B

new const ACCESS_ENT_KILL = ADMIN_LEVEL_C
new const ACCESS_ENT_ROTATE = ADMIN_LEVEL_C
new const ACCESS_ENT_DROPTOFLOOR = ADMIN_LEVEL_C
new const ACCESS_ENT_SETKEYVALUE = ADMIN_LEVEL_C

new const ACCESS_ES_GRAB = ADMIN_LEVEL_C
new const ACCESS_ES_UNGRAB = ADMIN_LEVEL_C
new const ACCESS_ES_CANCEL = ADMIN_LEVEL_C
new const ACCESS_ES_SAVE = ADMIN_LEVEL_C
new const ACCESS_ES_LIST = ADMIN_LEVEL_C
new const ACCESS_ES_LISTALL = ADMIN_LEVEL_C
new const ACCESS_ES_LOAD = ADMIN_LEVEL_C

new const ACCESS_ENT_MM_GRAB = ADMIN_LEVEL_D
new const ACCESS_ENT_MM_START = ADMIN_LEVEL_D
new const ACCESS_ENT_MM_START2 = ADMIN_LEVEL_D
new const ACCESS_ENT_MM_END = ADMIN_LEVEL_D
new const ACCESS_ENT_GRABTYPE = ADMIN_LEVEL_D
new const ACCESS_ENT_STOPGRAB = ADMIN_LEVEL_D
new const ACCESS_COPYENT_TOGGLE = ADMIN_LEVEL_D
new const ACCESS_COPYENT = ADMIN_LEVEL_D

new const ACCESS_ENT_TELESTART = ADMIN_LEVEL_E
new const ACCESS_ENT_TELEEND = ADMIN_LEVEL_E
new const ACCESS_ENT_TELEDELETE = ADMIN_LEVEL_E

new const ACCESS_ENT_STACK = ADMIN_LEVEL_F
new const ACCESS_ENT_WALL = ADMIN_LEVEL_F

new const ACCESS_ENT_LOOKINGAT = ADMIN_LEVEL_G
new const ACCESS_ENT_SEARCH = ADMIN_LEVEL_G
new const ACCESS_ENT_SHOWAXIS = ADMIN_LEVEL_G
new const ACCESS_ENT_SHOWKEYVALUE = ADMIN_LEVEL_G

new const ACCESS_ENT_USE = ADMIN_LEVEL_H

new const ACCESS_JEDICHOKE = ADMIN_SLAY

/*******************************************************************************
* GLOBALS / DEFINES
******************************************************************************/

new g_spriteTeleStart[] = "sprites/enter1.spr"
new g_spriteTeleEnd[] = "sprites/exit1.spr"

#define MAX_ENTS 256
#define MAX_KEYVALUES 16
#define KEY_LENGTH 32
#define VALUE_LENGTH 32

#define MAX_CLASSNAMES_TO_GRAB 9
new g_classnameToGrab[MAX_CLASSNAMES_TO_GRAB][] = {
	"weaponbox",
	"grenade",
	"func_breakable",
	"func_ladder",
	"csdm",
	"bullet",
	"rocket",
	"dookie",
	"piss_puddle"
}

#define MAX_MODELS_TO_GRAB 1
new g_modelToGrab[MAX_MODELS_TO_GRAB][] = {
	"models/w_"
}

#define MAX_MASSMOVE_ENTS 16

/*******************************************************************************
* DON'T MODIFY BELOW IF YOU DON'T KNOW WHAT YOU'RE DOING
******************************************************************************/

new g_key[MAX_ENTS][MAX_KEYVALUES][KEY_LENGTH]
new g_keyValueNum[MAX_ENTS]
new g_value[MAX_ENTS][MAX_KEYVALUES][VALUE_LENGTH]

new grabbed[33]
new grabbedIsBrush[33]
new grabbedNoClip[33]
new grabbedCopyEnt[33]
new grabbedOldMoveType[33][MAX_MASSMOVE_ENTS]
new grabbedOldSolid[33][MAX_MASSMOVE_ENTS]
new grabbedOldFlags[33][MAX_MASSMOVE_ENTS]
new grabbedOldRender[33][MAX_MASSMOVE_ENTS][6]
new grablength[33]
new bool:grabmodeon[33]
new g_massMoveEnts[33][MAX_MASSMOVE_ENTS]
new g_massMoveNum[33]
new bool:g_massMoveOn[33]
new Float:g_massMoveOldOrigin[33][3]

new g_saveEnts[33][MAX_MASSMOVE_ENTS]
new g_saveEntsNum[33]

new g_maxents
new g_maxplayers

new velocity_multiplier
new laserbeam
new g_msgidScreenShake, g_msgidDamage, g_msgidScreenFade

new const BOUNDS = 3

#if !defined ADMIN_SUPREME
#define ADMIN_SUPREME (1<<24)
#endif

/******************************************************************************/

public plugin_init()
{
	register_plugin("Ultimate JediGrab", "1.1.0", "KRoT@L / SpaceDude")
	/*******************************************************************************
	* CVARS
	******************************************************************************/
	register_cvar("sv_grab_force", "10")
	register_cvar("sv_grab_glow", "1")
	register_cvar("sv_grab_red", "0")
	register_cvar("sv_grab_green", "255")
	register_cvar("sv_grab_blue", "128")
	register_cvar("sv_grab_transp", "32")
	register_cvar("sv_grab_beam", "1")
	register_cvar("sv_throw_force", "1500")
	register_cvar("sv_pushpull_speed", "35")
	register_cvar("sv_speedkill", "2500")
	/*******************************************************************************
	* COMMANDS
	******************************************************************************/
	register_clcmd("grab_toggle","grab_toggle",ACCESS_GRAB_TOGGLE,"[entId/name/authid/#userid] Press once to grab and again to release.")
	register_clcmd("+grab","grab",ACCESS_GRAB,"Bind a key to +grab")
	register_clcmd("-grab","release",ACCESS_GRAB)
	register_clcmd("grab_toggle2","grab_toggle",ACCESS_GRAB_TOGGLE2,"[entId/name/authid/#userid] Press once to grab and again to release (noclip).")
	register_clcmd("+grab2","grab",ACCESS_GRAB2,"Bind a key to +grab2 (noclip)")
	register_clcmd("-grab2","release",ACCESS_GRAB2)
	register_clcmd("throw","throw",ACCESS_THROW,"Throws the grabee.")
	register_clcmd("+pull","startpull",ACCESS_PULL,"Bind a key to +pull")
	register_clcmd("-pull","stopdist",ACCESS_PULL)
	register_clcmd("+push","startpush",ACCESS_PUSH,"Bind a key to +push")
	register_clcmd("-push","stopdist",ACCESS_PUSH)
	register_clcmd("ent_undomoving","e_undo",ACCESS_UNDOMOVING,"Places the entity being looked at where it was.")
	
	register_concmd("ent_kill","e_kill",ACCESS_ENT_KILL,"[entity classname] [range] Kills the entity being looked at. You can specify an entity type and a range.")
	register_concmd("ent_rotate","e_rotate",ACCESS_ENT_ROTATE,"<y> <y> <z> [entId/name/authid/#userid] Rotates the entity being looked at. You can specify an entity id or a player id.")
	register_concmd("ent_droptofloor","e_droptofloor",ACCESS_ENT_DROPTOFLOOR,"[entId] Drops to floor the entity.")
	register_concmd("ent_setkeyvalue","e_setkeyvalue",ACCESS_ENT_SETKEYVALUE,"<key> <value> [entId/name/authid/#userid] Sets keyvalue on the entity being looked at or specified.")
	
	register_clcmd("ent_es_grab","es_grab",ACCESS_ES_GRAB,"[entId] Adds the entity to the save list.")
	register_clcmd("ent_es_ungrab","es_ungrab",ACCESS_ES_UNGRAB,"Removes the last entity added from the save list.")
	register_clcmd("ent_es_cancel","es_cancel",ACCESS_ES_CANCEL,"Removes all the entities added from the save list.")
	register_clcmd("ent_es_save","es_save",ACCESS_ES_SAVE,"<name> Saves all entities grabbed with the name specified.")
	register_clcmd("ent_es_list","es_list",ACCESS_ES_LIST,"Lists all entity saves for the current map.")
	register_clcmd("ent_es_listall","es_listall",ACCESS_ES_LISTALL,"Lists all entity saves on the server.")
	register_concmd("ent_es_load","es_load",ACCESS_ES_LOAD,"Loads the specified entity save. Saves can only be loaded on the map they were saved on.")
	
	register_clcmd("ent_mm_grab","mm_grab",ACCESS_ENT_MM_GRAB,"Selects an entity to be mass moved.")
	register_clcmd("ent_mm_start","mm_start",ACCESS_ENT_MM_START,"Starts the mass move process once all entities have been grabbed.")
	register_clcmd("ent_mm_start2","mm_start",ACCESS_ENT_MM_START2,"Starts the mass move process once all entities have been grabbed (noclip).")
	register_clcmd("ent_mm_end","mm_end",ACCESS_ENT_MM_END,"Releases all entities being mass moved.")
	register_clcmd("ent_grabtype","e_grabtype",ACCESS_ENT_GRABTYPE,"<entity classname> [range] Grabs a certain entity at a specified range (default 250).")
	register_clcmd("ent_stopgrab","e_stopgrab",ACCESS_ENT_STOPGRAB,"Used to stop moving an entity grabbed with amx_grabtype.")
	register_clcmd("copyent_toggle","copyent_toggle",ACCESS_COPYENT_TOGGLE,"Press once to copy and grab and again to release (noclip).")
	register_clcmd("+copyent","copyent",ACCESS_COPYENT,"Bind a key to +copyent")
	register_clcmd("-copyent","release",ACCESS_COPYENT)
	
	register_concmd("ent_telestart","e_telestart",ACCESS_ENT_TELESTART,"<name> [x] [y] [z] Creates a teleporter entrance that leads to the exit with the matching name.")
	register_concmd("ent_teleend","e_teleend",ACCESS_ENT_TELEEND,"<name> [x] [y] [z] Creates a teleporter exit that comes from the entrance with a matching name.")
	register_concmd("ent_teledelete","e_teledelete",ACCESS_ENT_TELEDELETE,"<name> Deletes the teleporter entrances and exit with the name specified.")
	
	register_clcmd("ent_stack","e_stack",ACCESS_ENT_STACK,"<amount> <offset x> <offset y> <offset z> Creates a certain amount of entities each offseted from the last the specified amount.")
	register_clcmd("ent_wall","e_wall",ACCESS_ENT_WALL,"<entId> <rowNum> <colNum> <rowOffset> <colOffset> Creates a wall made of the entity specified.")
	
	register_clcmd("ent_lookingat","e_lookingat",ACCESS_ENT_LOOKINGAT,"Gives information about the entity being looked at.")
	register_clcmd("ent_search","e_search",ACCESS_ENT_SEARCH,"Searches for entities within 100 cells of your location.")
	register_clcmd("ent_showx","showaxis",ACCESS_ENT_SHOWAXIS,"Creates a temporary line in the x direction.")
	register_clcmd("ent_showy","showaxis",ACCESS_ENT_SHOWAXIS,"Creates a temporary line in the y direction.")
	register_clcmd("ent_showz","showaxis",ACCESS_ENT_SHOWAXIS,"Creates a temporary line in the z direction.")
	register_clcmd("ent_showkeyvalue","e_showkeyvalue",ACCESS_ENT_SHOWKEYVALUE,"[entId/name/authid/#userid] Shows keyvalues of the entity being looked at or specified.")
	
	register_clcmd("ent_use","e_use",ACCESS_ENT_USE,"[name/authid/#userid] Makes you/the player use the entity you're looking at (open door, defuse bomb, ..).")
	
	register_clcmd("jedichoke","choke_func",ACCESS_JEDICHOKE,"Chokes the grabee.")
	/*******************************************************************************
	* DO NOT MODIFY WHAT IS BELOW
	******************************************************************************/
	register_event("StatusValue","spec_event","be","1=2")
	register_event("DeathMsg","death_event","a")
	register_event("ResetHUD", "resethud_event", "be")
	
	g_msgidScreenShake = get_user_msgid("ScreenShake")
	g_msgidDamage = get_user_msgid("Damage")
	g_msgidScreenFade = get_user_msgid("ScreenFade")
	
	g_maxents = get_maxentities()
	g_maxplayers = get_maxplayers()
	new i
	new Float:ori[3]
	for(i = g_maxplayers+1; i <= g_maxents; i++) {
		if(is_entity(i)) {
			entity_get_vector(i, EV_VEC_origin, ori)
			if((entity_get_int(i, EV_INT_solid) == SOLID_BSP && entity_get_int(i, EV_INT_movetype) == MOVETYPE_PUSH)
			|| (ori[0] == 0.0 && ori[1] == 0.0 && ori[2] == 0.0)) {
				entity_set_int(i, EV_INT_iuser4, 99)
			}
		}
	}
}

public plugin_precache() {
	new file[128], text[64], line=0, len, langFileFound = 0
	build_path(file, 127, "$langdir/menufront.txt")
	if(file_exists(file)) {
		while(read_file(file, line++, text, 63, len)) {
			if(!len) continue
			if(equal(text, "+ ^"ultimate_jedigrab^"")) {
				langFileFound = 1
				break
			}
		}
	}
	if(langFileFound == 0) {
		format(text, 63, "+ ^"ultimate_jedigrab^"")
		write_file(file, "")
		write_file(file, "")
		write_file(file, text)
	}
	
	laserbeam = precache_model("sprites/laserbeam.spr")
	precache_sound("player/PL_PAIN2.WAV")
	precache_model(g_spriteTeleStart)
	precache_model(g_spriteTeleEnd)
}

Float:calcDamage(Float:vel[3]) {
	return vector_length(vel) * (100.0/get_cvar_float("sv_speedkill"))
}

public entity_touch(entity1, entity2) {
	new Float:vel[3], Float:damage
	if(entity1 > 0 && is_entity(entity1) && is_user_alive(entity2)) {
		new i
		for(i = 1; i <= g_maxplayers; i++) {
			if(grabbed[i] == entity1) {
				entity_get_vector(entity1, EV_VEC_velocity, vel)
				damage = calcDamage(vel)
				if(damage > 0.0) {
					new Float:ori[3]
					entity_get_vector(entity2, EV_VEC_origin, ori)
					new classname[32]
					entity_get_string(entity1, EV_SZ_classname, classname, 31)
					take_damage(entity2, i, ori, damage, DMG_CRUSH, classname, 0)
				}
				entity_set_vector(entity2, EV_VEC_velocity, vel)
				return PLUGIN_CONTINUE
			}
		}
	}
	return PLUGIN_CONTINUE
}

public plugin_cfg() {
	createMenu()
}

createMenu() {
	new strFlags[16]
	
	server_cmd("amx_addmenu ^"Ultimate JediGrab^" ^"amx_jedigrabmenu^" ^"u^" ^"- displays Ultimate Jedi Grab Menu^" ^"7^"")
	
	//Page 1
	get_flags(ACCESS_GRAB_TOGGLE, strFlags, 15)
	server_cmd("amx_addmenuitem ^"amx_jedigrabmenu^" ^"Ultimate JediGrab^" ^"Grab Toggle^" ^"grab_toggle^" ^"be^" ^"%s^"", strFlags)
	get_flags(ACCESS_GRAB_TOGGLE, strFlags, 15)
	server_cmd("amx_addmenuitem ^"amx_jedigrabmenu^" ^"Ultimate JediGrab^" ^"Grab Toggle Player^" ^"grab_toggle %%player%%^" ^"b^" ^"%s^" ^"1^"", strFlags)
	get_flags(ACCESS_GRAB_TOGGLE2, strFlags, 15)
	server_cmd("amx_addmenuitem ^"amx_jedigrabmenu^" ^"Ultimate JediGrab^" ^"Grab Toggle with NoClip^" ^"grab_toggle2^" ^"be^" ^"%s^"", strFlags)
	get_flags(ACCESS_GRAB_TOGGLE2, strFlags, 15)
	server_cmd("amx_addmenuitem ^"amx_jedigrabmenu^" ^"Ultimate JediGrab^" ^"Grab Toggle Player with NoClip^" ^"grab_toggle2 %%player%%^" ^"b^" ^"%s^" ^"1^"", strFlags)
	get_flags(ACCESS_THROW, strFlags, 15)
	server_cmd("amx_addmenuitem ^"amx_jedigrabmenu^" ^"Ultimate JediGrab^" ^"Throw^" ^"throw^" ^"be^" ^"%s^"", strFlags)
	get_flags(ACCESS_JEDICHOKE, strFlags, 15)
	server_cmd("amx_addmenuitem ^"amx_jedigrabmenu^" ^"Ultimate JediGrab^" ^"Jedi Choke^" ^"jedichoke^" ^"be^" ^"%s^"", strFlags)
	get_flags(ACCESS_UNDOMOVING, strFlags, 15)
	server_cmd("amx_addmenuitem ^"amx_jedigrabmenu^" ^"Ultimate JediGrab^" ^"Undo Moving^" ^"ent_undomoving^" ^"be^" ^"%s^"", strFlags)
	
	//Page 2
	get_flags(ACCESS_ENT_KILL, strFlags, 15)
	server_cmd("amx_addmenuitem ^"amx_jedigrabmenu^" ^"Ultimate JediGrab^" ^"Kill Entity^" ^"ent_kill^" ^"be^" ^"%s^"", strFlags)
	get_flags(ACCESS_ENT_MM_GRAB, strFlags, 15)
	server_cmd("amx_addmenuitem ^"amx_jedigrabmenu^" ^"Ultimate JediGrab^" ^"MassMove Grab^" ^"ent_mm_grab^" ^"be^" ^"%s^"", strFlags)
	get_flags(ACCESS_ENT_MM_START, strFlags, 15)
	server_cmd("amx_addmenuitem ^"amx_jedigrabmenu^" ^"Ultimate JediGrab^" ^"MassMove Start^" ^"ent_mm_start^" ^"be^" ^"%s^"", strFlags)
	get_flags(ACCESS_ENT_MM_START2, strFlags, 15)
	server_cmd("amx_addmenuitem ^"amx_jedigrabmenu^" ^"Ultimate JediGrab^" ^"MassMove Start with NoClip^" ^"ent_mm_start2^" ^"be^" ^"%s^"", strFlags)
	get_flags(ACCESS_ENT_MM_END, strFlags, 15)
	server_cmd("amx_addmenuitem ^"amx_jedigrabmenu^" ^"Ultimate JediGrab^" ^"MassMove End^" ^"ent_mm_end^" ^"be^" ^"%s^"", strFlags)
	get_flags(ACCESS_COPYENT_TOGGLE, strFlags, 15)
	server_cmd("amx_addmenuitem ^"amx_jedigrabmenu^" ^"Ultimate JediGrab^" ^"Copy Ent Toggle^" ^"copyent_toggle^" ^"be^" ^"%s^"", strFlags)
	get_flags(ACCESS_ENT_DROPTOFLOOR, strFlags, 15)
	server_cmd("amx_addmenuitem ^"amx_jedigrabmenu^" ^"Ultimate JediGrab^" ^"Drop To Floor^" ^"ent_droptofloor^" ^"be^" ^"%s^"", strFlags)
	
	//Page 3
	get_flags(ACCESS_ENT_LOOKINGAT, strFlags, 15)
	server_cmd("amx_addmenuitem ^"amx_jedigrabmenu^" ^"Ultimate JediGrab^" ^"Ent Being Looking At^" ^"ent_lookingat^" ^"b^" ^"%s^"", strFlags)
	get_flags(ACCESS_ENT_SEARCH, strFlags, 15)
	server_cmd("amx_addmenuitem ^"amx_jedigrabmenu^" ^"Ultimate JediGrab^" ^"Entity Search^" ^"ent_search^" ^"b^" ^"%s^"", strFlags)
	get_flags(ACCESS_ENT_SHOWAXIS, strFlags, 15)
	server_cmd("amx_addmenuitem ^"amx_jedigrabmenu^" ^"Ultimate JediGrab^" ^"Show X Axis^" ^"ent_showx^" ^"b^" ^"%s^"", strFlags)
	get_flags(ACCESS_ENT_SHOWAXIS, strFlags, 15)
	server_cmd("amx_addmenuitem ^"amx_jedigrabmenu^" ^"Ultimate JediGrab^" ^"Show Y Axis^" ^"ent_showy^" ^"b^" ^"%s^"", strFlags)
	get_flags(ACCESS_ENT_SHOWAXIS, strFlags, 15)
	server_cmd("amx_addmenuitem ^"amx_jedigrabmenu^" ^"Ultimate JediGrab^" ^"Show Z Axis^" ^"ent_showz^" ^"b^" ^"%s^"", strFlags)
	get_flags(ACCESS_ENT_SHOWKEYVALUE, strFlags, 15)
	server_cmd("amx_addmenuitem ^"amx_jedigrabmenu^" ^"Ultimate JediGrab^" ^"Show KeyValues^" ^"ent_showkeyvalue^" ^"b^" ^"%s^"", strFlags)
	get_flags(ACCESS_ENT_USE, strFlags, 15)
	server_cmd("amx_addmenuitem ^"amx_jedigrabmenu^" ^"Ultimate JediGrab^" ^"Use Entity^" ^"ent_use^" ^"be^" ^"%s^"", strFlags)
}

setOldRendering(id, ent, pos) {
	set_rendering(ent, grabbedOldRender[id][pos][0], grabbedOldRender[id][pos][1], grabbedOldRender[id][pos][2], grabbedOldRender[id][pos][3], grabbedOldRender[id][pos][4], grabbedOldRender[id][pos][5])
}

setMMGrabRendering(ent) {
	set_rendering(ent, kRenderFxNone, 0, 255, 0, kRenderTransColor, 96)
}

setSaveRendering(ent) {
	set_rendering(ent, kRenderFxNone, 255, 0, 100, kRenderTransColor, 96)
}

canCreateEntity() {
	if(get_num_ents() < (g_maxents-5*g_maxplayers)) return 1
	return 0
}

searchTarget(id, aiming) {
	new targetid=0, body, found=0
	if(aiming == 1) get_user_aiming(id, targetid, body)
	if(!targetid)
	{
		new iOrigin[3], Float:origin[3]
		get_user_origin(id, iOrigin, 3)
		IVecFVec(iOrigin, origin)
		new string[64], i
		targetid = find_entity_sphere(id, origin, 8.0)
		while(targetid > 0 && found == 0)
		{
			string[0] = '^0'
			entity_get_string(targetid, EV_SZ_model, string, 63)
			for(i = 0; i < MAX_MODELS_TO_GRAB; i++)
			{
				if(containi(string, g_modelToGrab[i]) != -1)
				{
					found = 1
					break
				}
			}
			string[0] = '^0'
			entity_get_string(targetid, EV_SZ_classname, string, 63)
			for(i = 0; i < MAX_CLASSNAMES_TO_GRAB; i++)
			{
				if(containi(string, g_classnameToGrab[i]) != -1)
				{
					found = 1
					break
				}
			}
			if(found == 0) targetid = find_entity_sphere(targetid, origin, 8.0)
		}
	}
	return targetid
}

makeBounds(Float:traceEnds[8][3], Float:origin[3]) { // by JGHG
	traceEnds[0][0] = origin[0] - BOUNDS
	traceEnds[0][1] = origin[1] - BOUNDS
	traceEnds[0][2] = origin[2] - BOUNDS
	traceEnds[1][0] = origin[0] - BOUNDS
	traceEnds[1][1] = origin[1] - BOUNDS
	traceEnds[1][2] = origin[2] + BOUNDS
	traceEnds[2][0] = origin[0] + BOUNDS
	traceEnds[2][1] = origin[1] - BOUNDS
	traceEnds[2][2] = origin[2] + BOUNDS
	traceEnds[3][0] = origin[0] + BOUNDS
	traceEnds[3][1] = origin[1] - BOUNDS
	traceEnds[3][2] = origin[2] - BOUNDS
	traceEnds[4][0] = origin[0] - BOUNDS
	traceEnds[4][1] = origin[1] + BOUNDS
	traceEnds[4][2] = origin[2] - BOUNDS
	traceEnds[5][0] = origin[0] - BOUNDS
	traceEnds[5][1] = origin[1] + BOUNDS
	traceEnds[5][2] = origin[2] + BOUNDS
	traceEnds[6][0] = origin[0] + BOUNDS
	traceEnds[6][1] = origin[1] + BOUNDS
	traceEnds[6][2] = origin[2] + BOUNDS
	traceEnds[7][0] = origin[0] + BOUNDS
	traceEnds[7][1] = origin[1] + BOUNDS
	traceEnds[7][2] = origin[2] - BOUNDS
	return 1
}

makeCopyOf(entId) {
	if(canCreateEntity() == 0) {
		server_print("[AMX] Too many entities on the map.")
		return 0
	}
	if(!is_entity(entId) || is_user_connected(entId)) return 0
	new classname[64]
	entity_get_string(entId, EV_SZ_classname, classname, 63)
	new copyId = create_entity(classname)
	if(copyId < 1) return 0
	new oldEntId = 0
	if(!g_key[entId][0][0]) {
		oldEntId = entId
		entId = entity_get_int(entId, EV_INT_iuser3)
	}
	if(!g_key[entId][0][0]) {
		return 0
	}
	new maxkeyvalues = g_keyValueNum[entId]
	for(new i = 0; i < maxkeyvalues; i++) {
		DispatchKeyValue(copyId, g_key[entId][i], g_value[entId][i])
	}
	DispatchSpawn(copyId)
	entity_set_int(copyId, EV_INT_iuser3, entId)
	entity_set_int(copyId, EV_INT_iuser4, entity_get_int(entId, EV_INT_iuser4))
	new Float:vec[3]
	entity_get_vector((oldEntId == 0) ? entId : oldEntId, EV_VEC_absmin, vec)
	entity_set_vector(copyId, EV_VEC_absmin, vec)
	entity_get_vector((oldEntId == 0) ? entId : oldEntId, EV_VEC_absmax, vec)
	entity_set_vector(copyId, EV_VEC_absmax, vec)
	/*entity_get_vector((oldEntId == 0) ? entId : oldEntId, EV_VEC_mins, vec)
	entity_set_vector(copyId, EV_VEC_mins, vec)
	entity_get_vector((oldEntId == 0) ? entId : oldEntId, EV_VEC_maxs, vec)
	entity_set_vector(copyId, EV_VEC_maxs, vec)*/
	return copyId
}

public keyvalue(entity) {
	if(entity >= 0 && is_entity(entity) && entity < MAX_ENTS && g_keyValueNum[entity] < MAX_KEYVALUES) {
		new class[2], key[KEY_LENGTH], value[VALUE_LENGTH]
		copy_keyvalue(class, 1, key, KEY_LENGTH-1, value, VALUE_LENGTH-1);
		if(key[0] && value[0]) {
			copy(g_key[entity][g_keyValueNum[entity]], KEY_LENGTH-1, key)
			copy(g_value[entity][g_keyValueNum[entity]], VALUE_LENGTH-1, value)
			g_keyValueNum[entity]++
		}
	}
}

public grabtask(parm[])
{
	new id = parm[0]
	if (!grabbed[id])
	{
		new targetid=0, body
		get_user_aiming(id, targetid, body)
		if (targetid)
		{
			if(grabbedCopyEnt[id] == 1) {
				new idCopy = makeCopyOf(targetid)
				if(idCopy > 0) targetid = idCopy
			}
			set_grabbed(id, targetid)
		}
		else
		{
			new iOrigin[3], Float:origin[3]
			get_user_origin(id, iOrigin, 3)
			IVecFVec(iOrigin, origin)
			new string[64], i
			targetid = find_entity_sphere(id, origin, 8.0)
			while(targetid > 0)
			{
				string[0] = '^0'
				entity_get_string(targetid, EV_SZ_model, string, 63)
				for(i = 0; i < MAX_MODELS_TO_GRAB; i++)
				{
					if(containi(string, g_modelToGrab[i]) != -1)
					{
						if(grabbedCopyEnt[id] == 1) {
							new idCopy = makeCopyOf(targetid)
							if(idCopy > 0) targetid = idCopy
						}
						set_grabbed(id, targetid)
						return PLUGIN_CONTINUE
					}
				}
				string[0] = '^0'
				entity_get_string(targetid, EV_SZ_classname, string, 63)
				for(i = 0; i < MAX_CLASSNAMES_TO_GRAB; i++)
				{
					if(containi(string, g_classnameToGrab[i]) != -1)
					{
						if(grabbedCopyEnt[id] == 1) {
							new idCopy = makeCopyOf(targetid)
							if(idCopy > 0) targetid = idCopy
						}
						set_grabbed(id, targetid)
						return PLUGIN_CONTINUE
					}
				}
				targetid = find_entity_sphere(targetid, origin, 8.0)
			}
		}
	}
	else {
		if(!is_entity(grabbed[id])) {
			release(id,0,0)
			return PLUGIN_CONTINUE
		}
		
		new origin[3], look[3], direction[3], moveto[3], gborigin[3], Float:grabbedorigin[3], Float:velocity[3], length
		get_user_origin(id, origin, 1)
		get_user_origin(id, look, 3)
		if(grabbedIsBrush[id] == 1) {
			get_brush_entity_origin(grabbed[id], grabbedorigin)
		}
		else {
			entity_get_vector(grabbed[id], EV_VEC_origin, grabbedorigin)
		}
		FVecIVec(grabbedorigin, gborigin)
		
		direction[0]=look[0]-origin[0]
		direction[1]=look[1]-origin[1]
		direction[2]=look[2]-origin[2]
		length = get_distance(look,origin)
		if (!length) length=1 // avoid division by 0
		
		moveto[0]=origin[0]+direction[0]*grablength[id]/length
		moveto[1]=origin[1]+direction[1]*grablength[id]/length
		moveto[2]=origin[2]+direction[2]*grablength[id]/length
		
		if(get_cvar_num("sv_grab_beam"))
		{
			message_begin(MSG_PVS, SVC_TEMPENTITY, gborigin)
			write_byte(1)
			write_short(id)
			write_coord(gborigin[0])
			write_coord(gborigin[1])
			write_coord(gborigin[2])
			write_short(laserbeam)
			write_byte(1)
			write_byte(1)
			write_byte(1)
			write_byte(6)
			write_byte(0)
			write_byte(255)
			write_byte(0)
			write_byte(0)
			write_byte(128)
			write_byte(0)
			message_end()
		}
		
		velocity[0]=(moveto[0]-grabbedorigin[0])*velocity_multiplier
		velocity[1]=(moveto[1]-grabbedorigin[1])*velocity_multiplier
		velocity[2]=(moveto[2]-grabbedorigin[2])*velocity_multiplier
		
		new not_a_player
		new Float:fmoveto[3]
		IVecFVec(moveto, fmoveto)
		if(g_massMoveOn[id] == true) {
			new ent, i, num = g_massMoveNum[id], Float:grabbedorigin2[3]
			for(i = 0; i < num; i++) {
				ent = g_massMoveEnts[id][i]
				if(!is_entity(ent)) continue
				not_a_player = !is_user_connected(ent)
				if(grabbedNoClip[id] == 1) {
					IVecFVec(moveto, fmoveto)
					if(!not_a_player) {
						entity_set_int(ent, EV_INT_solid, SOLID_NOT)
						entity_set_int(ent, EV_INT_movetype, MOVETYPE_NOCLIP)
						if(i == 0) {
							entity_set_origin(ent, fmoveto)
						}
						else {
							entity_get_vector(ent, EV_VEC_origin, grabbedorigin2)
							grabbedorigin2[0] += (grabbedorigin[0] - g_massMoveOldOrigin[id][0])
							grabbedorigin2[1] += (grabbedorigin[1] - g_massMoveOldOrigin[id][1])
							grabbedorigin2[2] += (grabbedorigin[2] - g_massMoveOldOrigin[id][2])
							entity_set_origin(ent, grabbedorigin2)
						}
					}
					else {
						entity_get_vector(ent, EV_VEC_origin, grabbedorigin2)
						grabbedorigin2[0] += (grabbedorigin[0] - g_massMoveOldOrigin[id][0])
						grabbedorigin2[1] += (grabbedorigin[1] - g_massMoveOldOrigin[id][1])
						grabbedorigin2[2] += (grabbedorigin[2] - g_massMoveOldOrigin[id][2])
						new Float:Min[3], Float:Max[3]
						entity_get_vector(grabbed[id], EV_VEC_mins, Min)
						entity_get_vector(grabbed[id], EV_VEC_maxs, Max)
						grabbedorigin2[0] -= (Min[0] + Max[0]) * 0.5
						grabbedorigin2[1] -= (Min[1] + Max[1]) * 0.5
						grabbedorigin2[2] -= (Min[2] + Max[2]) * 0.5
						entity_set_origin(grabbed[id], grabbedorigin2)
					}
					continue
				}
				else if(not_a_player) {
					entity_set_int(ent, EV_INT_solid, SOLID_BBOX)
					entity_set_int(ent, EV_INT_movetype, MOVETYPE_FLY)
				}
				entity_set_vector(ent, EV_VEC_velocity, velocity)
			}
			g_massMoveOldOrigin[id][0] = grabbedorigin[0]
			g_massMoveOldOrigin[id][1] = grabbedorigin[1]
			g_massMoveOldOrigin[id][2] = grabbedorigin[2]
		}
		else {
			not_a_player = !is_user_connected(grabbed[id])
			if(grabbedNoClip[id] == 1) {
				IVecFVec(moveto, fmoveto)
				if(!not_a_player) {
					entity_set_int(grabbed[id], EV_INT_solid, SOLID_NOT)
					entity_set_int(grabbed[id], EV_INT_movetype, MOVETYPE_NOCLIP)
					entity_set_origin(grabbed[id], fmoveto)
				}
				else {
					new Float:Min[3], Float:Max[3]
					entity_get_vector(grabbed[id], EV_VEC_mins, Min)
					entity_get_vector(grabbed[id], EV_VEC_maxs, Max)
					fmoveto[0] -= (Min[0] + Max[0]) * 0.5
					fmoveto[1] -= (Min[1] + Max[1]) * 0.5
					fmoveto[2] -= (Min[2] + Max[2]) * 0.5
					entity_set_origin(grabbed[id], fmoveto)
				}
				return PLUGIN_CONTINUE
			}
			else if(not_a_player) {
				entity_set_int(grabbed[id], EV_INT_solid, SOLID_BBOX)
				entity_set_int(grabbed[id], EV_INT_movetype, MOVETYPE_FLY)
			}
			entity_set_vector(grabbed[id], EV_VEC_velocity, velocity)
		}
	}
	return PLUGIN_CONTINUE
}

public grab_toggle(id,level,cid)
{
	if (!cmd_access(id,level,cid,1))
	{
		return PLUGIN_HANDLED
	}
	if (grabmodeon[id])
		release(id,0,0)
	else {
		new cmd[32]
		read_argv(0, cmd, 31)
		if(containi(cmd, "2") != -1) {
			grabbedNoClip[id] = 1
		}
		else {
			grabbedNoClip[id] = 0
		}
		if(read_argc() >= 2) {
			new arg[32]
			read_argv(1, arg, 31)
			new ent
			if(is_str_num(arg)) {
				ent = strtonum(arg)
			}
			else {
				ent = cmd_target(id, arg, 5)
			}
			if(!is_entity(ent) || ent == id) {
				console_print(id, "[AMX] Entity invalid")
				return PLUGIN_HANDLED
			}
			new range = 200
			if(read_argc() == 3) {
				read_argv(2, arg, 31)
				range = strtonum(arg)
				if(range <= 0) {
					console_print(id, "[AMX] Incorrect range")
					return PLUGIN_HANDLED
				}
			}
			new parm[1]
			parm[0] = id
			velocity_multiplier = get_cvar_num("sv_grab_force")
			grabmodeon[id]=true
			set_task(0.1, "grabtask", 100+id, parm, 1, "b")
			set_grabbed(id, ent)
			grablength[id] = range
		}
		grab(id,0,0)
	}
	return PLUGIN_HANDLED
}

public grab(id,level,cid)
{
	if (!cmd_access(id,level,cid,1))
	{
		return PLUGIN_HANDLED
	}
	if(level != 0 || cid != 0) {
		new cmd[32]
		read_argv(0, cmd, 31)
		if(containi(cmd, "2") != -1) {
			grabbedNoClip[id] = 1
		}
		else {
			grabbedNoClip[id] = 0
		}
	}
	if (!grabmodeon[id])
	{
		new targetid=0, body
		new parm[1]
		parm[0] = id
		velocity_multiplier = get_cvar_num("sv_grab_force")
		grabmodeon[id]=true
		set_task(0.1, "grabtask", 100+id, parm, 1, "b")
		get_user_aiming(id, targetid, body)
		if (targetid)
		{
			if(grabbedCopyEnt[id] == 1) {
				new idCopy = makeCopyOf(targetid)
				if(idCopy > 0) targetid = idCopy
			}
			set_grabbed(id, targetid)
			return PLUGIN_HANDLED
		}
		else
		{
			new iOrigin[3], Float:origin[3]
			get_user_origin(id, iOrigin, 3)
			IVecFVec(iOrigin, origin)
			new string[64], i
			targetid = find_entity_sphere(id, origin, 8.0)
			while(targetid > 0)
			{
				string[0] = '^0'
				entity_get_string(targetid, EV_SZ_model, string, 63)
				for(i = 0; i < MAX_MODELS_TO_GRAB; i++)
				{
					if(containi(string, g_modelToGrab[i]) != -1)
					{
						if(grabbedCopyEnt[id] == 1) {
							new idCopy = makeCopyOf(targetid)
							if(idCopy > 0) targetid = idCopy
						}
						set_grabbed(id, targetid)
						return PLUGIN_CONTINUE
					}
				}
				string[0] = '^0'
				entity_get_string(targetid, EV_SZ_classname, string, 63)
				for(i = 0; i < MAX_CLASSNAMES_TO_GRAB; i++)
				{
					if(containi(string, g_classnameToGrab[i]) != -1)
					{
						if(grabbedCopyEnt[id] == 1) {
							new idCopy = makeCopyOf(targetid)
							if(idCopy > 0) targetid = idCopy
						}
						set_grabbed(id, targetid)
						return PLUGIN_CONTINUE
					}
				}
				targetid = find_entity_sphere(targetid, origin, 8.0)
			}
		}
		client_print(id,print_chat,"[AMX] Searching for a target")
	}
	return PLUGIN_HANDLED
}

public release(id,level,cid)
{
	if (!cmd_access(id,level,cid,1))
	{
		return PLUGIN_HANDLED
	}
	if (grabmodeon[id])
	{
		new Float:origin[3], Float:traceEnds[8][3]
		if(g_massMoveOn[id] == true) {
			new ent, i, num = g_massMoveNum[id], goToNextEnt = 0
			for(i = 0; i < num; i++) {
				ent = g_massMoveEnts[id][i]
				if(!is_entity(ent)) continue
				if(grabbedNoClip[id] == 0 && !is_user_connected(ent) && entity_get_int(ent, EV_INT_iuser4) != 99) {
					entity_get_vector(ent, EV_VEC_origin, origin)
					// By JGHG
					makeBounds(traceEnds, origin)
					for(new j = 0; j < 8; j++) {
						if(PointContents(traceEnds[j]) == CONTENTS_SOLID) {
							remove_entity(ent)
							goToNextEnt = i+1
							break
						}
					}
				}
				if(goToNextEnt == i+1) continue
				entity_set_int(ent, EV_INT_flags, grabbedOldFlags[id][i])
				entity_set_int(ent, EV_INT_movetype, grabbedOldMoveType[id][i])
				entity_set_int(ent, EV_INT_solid, grabbedOldSolid[id][i])
				setOldRendering(id, ent, i)
			}
			client_print(id,print_chat,"[AMX] You have released something!")
		}
		else if (grabbed[id])
		{
			if(is_entity(grabbed[id])) {
				if(grabbedNoClip[id] == 0 && !is_user_connected(grabbed[id]) && entity_get_int(grabbed[id], EV_INT_iuser4) != 99) {
					entity_get_vector(grabbed[id], EV_VEC_origin, origin)
					// By JGHG
					makeBounds(traceEnds, origin)
					for(new j = 0; j < 8; j++) {
						if(PointContents(traceEnds[j]) == CONTENTS_SOLID) {
							client_print(id,print_chat,"[AMX] You can't release a TRIGGER entity inside something SOLID!")
							return PLUGIN_HANDLED
						}
					}
				}
				entity_set_int(grabbed[id], EV_INT_flags, grabbedOldFlags[id][0])
				entity_set_int(grabbed[id], EV_INT_movetype, grabbedOldMoveType[id][0])
				entity_set_int(grabbed[id], EV_INT_solid, grabbedOldSolid[id][0])
				setOldRendering(id, grabbed[id], 0)
				client_print(id,print_chat,"[AMX] You have released something!")
			}
		}
		grabmodeon[id]=false
		grabbed[id]=0
		grabbedCopyEnt[id] = 0
		remove_task(100+id)
	}
	return PLUGIN_HANDLED
}

public copyent_toggle(id,level,cid)
{
	if (!cmd_access(id,level,cid,1))
	{
		return PLUGIN_HANDLED
	}
	if (grabmodeon[id])
		release(id,0,0)
	else {
		grabbedNoClip[id] = 1
		grabbedCopyEnt[id] = 1
		grab(id,0,0)
	}
	return PLUGIN_HANDLED
}

public copyent(id,level,cid)
{
	if (!cmd_access(id,level,cid,1))
	{
		return PLUGIN_HANDLED
	}
	grabbedCopyEnt[id] = 1
	grab(id,0,0)
	return PLUGIN_HANDLED
}

public throw(id,level,cid)
{
	if (!cmd_access(id,level,cid,1))
	{
		return PLUGIN_HANDLED
	}
	new Float:origin[3], Float:traceEnds[8][3]
	new Float:pVelocity[3]
	if(g_massMoveOn[id] == true) {
		VelocityByAim(id,get_cvar_num("sv_throw_force"),pVelocity)
		new ent, i, num = g_massMoveNum[id], goToNextEnt = 0
		for(i = 0; i < num; i++) {
			ent = g_massMoveEnts[id][i]
			if(!is_entity(ent)) continue
			if(grabbedNoClip[id] == 0 && !is_user_connected(ent) && entity_get_int(ent, EV_INT_iuser4) != 99) {
				entity_get_vector(ent, EV_VEC_origin, origin)
				// By JGHG
				makeBounds(traceEnds, origin)
				for(new j = 0; j < 8; j++) {
					if(PointContents(traceEnds[j]) == CONTENTS_SOLID) {
						remove_entity(ent)
						goToNextEnt = i+1
						break
					}
				}
			}
			if(goToNextEnt == i+1) continue
			entity_set_vector(ent, EV_VEC_velocity, pVelocity)
			entity_set_int(ent, EV_INT_flags, grabbedOldFlags[id][i])
			entity_set_int(ent, EV_INT_movetype, grabbedOldMoveType[id][i])
			entity_set_int(ent, EV_INT_solid, grabbedOldSolid[id][i])
			setOldRendering(id, ent, i)
		}
		grabbed[id]=0
		grabbedCopyEnt[id] = 0
		grabmodeon[id]=false
		remove_task(100+id)
		client_print(id,print_chat,"[AMX] You have thrown something!")
	}
	else if (grabbed[id])
	{
		if(is_entity(grabbed[id])) {
			if(grabbedNoClip[id] == 0 && !is_user_connected(grabbed[id]) && entity_get_int(grabbed[id], EV_INT_iuser4) != 99) {
				entity_get_vector(grabbed[id], EV_VEC_origin, origin)
				// By JGHG
				makeBounds(traceEnds, origin)
				for(new j = 0; j < 8; j++) {
					if(PointContents(traceEnds[j]) == CONTENTS_SOLID) {
						client_print(id,print_chat,"[AMX] You can't release a TRIGGER entity inside something SOLID!")
						return PLUGIN_HANDLED
					}
				}
			}
			VelocityByAim(id,get_cvar_num("sv_throw_force"),pVelocity)
			entity_set_vector(grabbed[id],EV_VEC_velocity,pVelocity)
			setOldRendering(id, grabbed[id], 0)
			entity_set_int(grabbed[id], EV_INT_flags, grabbedOldFlags[id][0])
			entity_set_int(grabbed[id], EV_INT_movetype, grabbedOldMoveType[id][0])
			entity_set_int(grabbed[id], EV_INT_solid, grabbedOldSolid[id][0])
		}
		grabbed[id]=0
		grabbedCopyEnt[id] = 0
		grabmodeon[id]=false
		remove_task(100+id)
		client_print(id,print_chat,"[AMX] You have thrown something!")
	}
	return PLUGIN_HANDLED
}

public spec_event(id)
{
	new targetid = read_data(2)
	
	if (!is_user_alive(targetid))
		return PLUGIN_CONTINUE
	
	if (grabmodeon[id] && !grabbed[id])
	{
		set_grabbed(id, targetid)
	}
	return PLUGIN_CONTINUE
}

public set_grabbed(id, targetid)
{
	if(is_user_alive(targetid) && get_user_flags(targetid) & ADMIN_IMMUNITY && !(get_user_flags(id) & ADMIN_SUPREME))
	{
		grabmodeon[id]=false
		grabbed[id]=0
		grabbedCopyEnt[id] = 0
		remove_task(100+id)
		client_print(id,print_chat,"[AMX] Player has immunity!")
		return PLUGIN_CONTINUE
	}
	new origin1[3], origin2[3], Float:forigin2[3]
	get_user_origin(id, origin1)
	entity_get_vector(targetid, EV_VEC_origin, forigin2)
	if(!is_user_connected(targetid) && entity_get_int(targetid, EV_INT_iuser4) == 99) {
		get_brush_entity_origin(targetid, forigin2)
		grabbedIsBrush[id] = 1
	}
	FVecIVec(forigin2, origin2)
	g_massMoveOldOrigin[id][0] = forigin2[0]
	g_massMoveOldOrigin[id][1] = forigin2[1]
	g_massMoveOldOrigin[id][2] = forigin2[2]
	grabbed[id] = targetid
	grabbedOldMoveType[id][0] = entity_get_int(targetid, EV_INT_movetype)
	grabbedOldSolid[id][0] = entity_get_int(targetid, EV_INT_solid)
	grabbedOldFlags[id][0] = entity_get_int(targetid, EV_INT_flags)
	if(g_massMoveOn[id] == false) {
		new Float:color[3]
		grabbedOldRender[id][0][0] = entity_get_int(targetid, EV_INT_renderfx)
		entity_get_vector(targetid, EV_VEC_rendercolor, color)
		grabbedOldRender[id][0][1] = floatround(color[0])
		grabbedOldRender[id][0][2] = floatround(color[1])
		grabbedOldRender[id][0][3] = floatround(color[2])
		grabbedOldRender[id][0][4] = entity_get_int(targetid, EV_INT_rendermode)
		grabbedOldRender[id][0][5] = floatround(entity_get_float(targetid, EV_FL_renderamt))
		if(get_cvar_num("sv_grab_glow"))
		{
			set_rendering(targetid,kRenderFxGlowShell,get_cvar_num("sv_grab_red"),get_cvar_num("sv_grab_green"),get_cvar_num("sv_grab_blue"),kRenderTransAlpha,get_cvar_num("sv_grab_transp"))
		}
	}
	grablength[id] = get_distance(origin1,origin2)
	new classname[32]
	entity_get_string(targetid, EV_SZ_classname, classname, 31)
	client_print(id,print_chat,"[AMX] You have grabbed something! (id=%d, classname=%s)", targetid, classname)
	return PLUGIN_CONTINUE
}

public disttask(parm[])
{
	new id = parm[0]
	if (grabbed[id])
	{
		if (parm[1] == 1)
		{
			grablength[id] -= get_cvar_num("sv_pushpull_speed")
		}
		else if (parm[1] == 2)
		{
			grablength[id] += get_cvar_num("sv_pushpull_speed")
		}
	}
}

public startpull(id,level,cid)
{
	if (!cmd_access(id,level,cid,1))
	{
		return PLUGIN_HANDLED
	}
	if (grabbed[id])
	{
		new parm[2]
		parm[0] = id
		parm[1] = 1
		set_task(0.1, "disttask", 500+id, parm, 2, "b")
	}
	return PLUGIN_HANDLED
}

public startpush(id,level,cid)
{
	if (!cmd_access(id,level,cid,1))
	{
		return PLUGIN_HANDLED
	}
	if (grabbed[id])
	{
		new parm[2]
		parm[0] = id
		parm[1] = 2
		set_task(0.1, "disttask", 500+id, parm, 2, "b")
	}
	return PLUGIN_HANDLED
}

public stopdist(id,level,cid)
{
	if (!cmd_access(id,level,cid,1))
	{
		return PLUGIN_HANDLED
	}
	if (grabbed[id])
	{
		remove_task(500+id)
	}
	return PLUGIN_HANDLED
}

public choke_func(id,level,cid)
{
	if (!cmd_access(id,level,cid,1))
	{
		return PLUGIN_HANDLED
	}
	if (is_user_alive(grabbed[id]) && !task_exists(id+200))
	{
		new victim_name[33]
		get_user_name(grabbed[id], victim_name, 32)
		client_print(grabbed[id],print_chat,"*** You Are Being Choked By A Jedi !")
		client_print(id,print_chat,"*** You Are Choking %s !", victim_name)
		message_begin(MSG_ONE, g_msgidScreenShake , {0,0,0}, grabbed[id])
		write_short(1<<14)
		write_short(1<<14)
		write_short(1<<14)
		message_end()
		message_begin(MSG_ONE, g_msgidScreenFade , {0,0,0}, grabbed[id])
		write_short(1<<1) //total duration
		write_short(1<<0) //time it stays one color
		write_short(0<<1) //fade out, which means it goes away
		write_byte(255) //red
		write_byte(30) //green
		write_byte(30) //blue
		write_byte(180) //alpha, 255 means non-transparent
		message_end()
		new vec[3]
		get_user_origin(grabbed[id],vec)
		message_begin(MSG_ONE, g_msgidDamage, {0,0,0}, grabbed[id])
		write_byte(30) // dmg_save
		write_byte(30) // dmg_take
		write_long(1<<0) // visibleDamageBits
		write_coord(vec[0]) // damageOrigin.x
		write_coord(vec[1]) // damageOrigin.y
		write_coord(vec[2]) // damageOrigin.z
		message_end()
		new var[1],health
		var[0]=id
		set_task(1.0,"repeat_shake",id+200,var,1,"a",8)
		emit_sound(grabbed[id],CHAN_BODY,"player/PL_PAIN2.WAV",1.0,ATTN_NORM,0, PITCH_NORM)
		health=get_user_health(grabbed[id])
		if(health>3)
			set_user_health(grabbed[id],health-3)
	}
	return PLUGIN_HANDLED
}

public repeat_shake(var[])
{
	new id = var[0]
	if (is_user_alive(grabbed[id]))
	{
		message_begin(MSG_ONE, g_msgidScreenShake , {0,0,0}, grabbed[id])
		write_short(1<<14)
		write_short(1<<14)
		write_short(1<<14)
		message_end()
		message_begin(MSG_ONE, g_msgidScreenFade , {0,0,0}, grabbed[id])
		write_short(1<<1) //total duration
		write_short(1<<0) //time it stays one color
		write_short(0<<1) //fade out, which means it goes away
		write_byte(255) //red
		write_byte(30) //green
		write_byte(30) //blue
		write_byte(180) //alpha, 255 means non-transparent
		message_end()
		new vec[3]
		get_user_origin(grabbed[id],vec)
		message_begin(MSG_ONE, g_msgidDamage, {0,0,0}, grabbed[id])
		write_byte(30) // dmg_save
		write_byte(30) // dmg_take
		write_long(1<<0) // visibleDamageBits
		write_coord(vec[0]) // damageOrigin.x
		write_coord(vec[1]) // damageOrigin.y
		write_coord(vec[2]) // damageOrigin.z
		message_end()
		new health=get_user_health(grabbed[id])
		if(health>3)
			set_user_health(grabbed[id],health-3)
		emit_sound(grabbed[id],CHAN_BODY,"player/PL_PAIN2.WAV",1.0,ATTN_NORM,0, PITCH_NORM)
	}
	else
	{
		if(task_exists(id+200))
			remove_task(id+200)
	}
	return PLUGIN_CONTINUE
}

public resethud_event(id)
{
	if(task_exists(100+id))
	{
		remove_task(100+id)
	}
	if(grabbed[id] > 0 && is_entity(grabbed[id]))
	{
		setOldRendering(id, grabbed[id], 0)
	}
	grabbed[id] = 0
	grabmodeon[id] = false
	massrelease(id)
}

public death_event()
{
	new id = read_data(2)
	if(!is_user_connected(id)) return PLUGIN_CONTINUE
	if(task_exists(100+id))
	{
		remove_task(100+id)
	}
	if(grabbed[id] > 0 && is_entity(grabbed[id]))
	{
		if(is_entity(grabbed[id])) {
			if(grabbedNoClip[id] == 0 && !is_user_connected(grabbed[id]) && entity_get_int(grabbed[id], EV_INT_iuser4) != 99) {
				new Float:origin[3]
				entity_get_vector(grabbed[id], EV_VEC_origin, origin)
				new Float:traceEnds[8][3]
				// By JGHG
				makeBounds(traceEnds, origin)
				for(new j = 0; j < 8; j++) {
					if(PointContents(traceEnds[j]) == CONTENTS_SOLID) {
						remove_entity(grabbed[id])
						break
					}
				}
			}
			if(is_entity(grabbed[id])) {
				entity_set_int(grabbed[id], EV_INT_flags, grabbedOldFlags[id][0])
				entity_set_int(grabbed[id], EV_INT_movetype, grabbedOldMoveType[id][0])
				entity_set_int(grabbed[id], EV_INT_solid, grabbedOldSolid[id][0])
				setOldRendering(id, grabbed[id], 0)
			}
		}
		if(g_massMoveOn[id] == true) {
			new ent, i, num = g_massMoveNum[id], goToNextEnt = 0
			for(i = 0; i < num; i++) {
				ent = g_massMoveEnts[id][i]
				if(!is_entity(ent)) continue
				if(grabbedNoClip[id] == 0 && !is_user_connected(ent) && entity_get_int(ent, EV_INT_iuser4) != 99) {
					entity_get_vector(ent, EV_VEC_origin, origin)
					// By JGHG
					makeBounds(traceEnds, origin)
					for(new j = 0; j < 8; j++) {
						if(PointContents(traceEnds[j]) == CONTENTS_SOLID) {
							remove_entity(ent)
							goToNextEnt = i+1
							break
						}
					}
				}
				if(goToNextEnt == i+1) continue
				entity_set_int(ent, EV_INT_flags, grabbedOldFlags[id][i])
				entity_set_int(ent, EV_INT_movetype, grabbedOldMoveType[id][i])
				entity_set_int(ent, EV_INT_solid, grabbedOldSolid[id][i])
				setOldRendering(id, ent, i)
			}
		}
	}
	grabbed[id] = 0
	grabmodeon[id] = false
	new players[32], inum, player
	get_players(players, inum)
	for(new k = 0 ; k < inum ; k++)
	{
		player = players[k]
		if(grabbed[player] == id)
		{
			if(task_exists(100+player))
			{
				remove_task(100+player)
			}
			grabbed[player] = 0
			grabmodeon[player] = false
		}
	}
	massrelease(id)
	return PLUGIN_CONTINUE
}

public client_kill(id)
{
	if(task_exists(100+id))
	{
		remove_task(100+id)
	}
	if(grabbed[id] > 0 && is_entity(grabbed[id]))
	{
		if(is_entity(grabbed[id])) {
			if(grabbedNoClip[id] == 0 && !is_user_connected(grabbed[id]) && entity_get_int(grabbed[id], EV_INT_iuser4) != 99) {
				new Float:origin[3]
				entity_get_vector(grabbed[id], EV_VEC_origin, origin)
				new Float:traceEnds[8][3]
				// By JGHG
				makeBounds(traceEnds, origin)
				for(new j = 0; j < 8; j++) {
					if(PointContents(traceEnds[j]) == CONTENTS_SOLID) {
						remove_entity(grabbed[id])
						break
					}
				}
			}
			if(is_entity(grabbed[id])) {
				entity_set_int(grabbed[id], EV_INT_flags, grabbedOldFlags[id][0])
				entity_set_int(grabbed[id], EV_INT_movetype, grabbedOldMoveType[id][0])
				entity_set_int(grabbed[id], EV_INT_solid, grabbedOldSolid[id][0])
				setOldRendering(id, grabbed[id], 0)
			}
		}
		if(g_massMoveOn[id] == true) {
			new ent, i, num = g_massMoveNum[id], goToNextEnt = 0
			for(i = 0; i < num; i++) {
				ent = g_massMoveEnts[id][i]
				if(!is_entity(ent)) continue
				if(grabbedNoClip[id] == 0 && !is_user_connected(ent) && entity_get_int(ent, EV_INT_iuser4) != 99) {
					entity_get_vector(ent, EV_VEC_origin, origin)
					// By JGHG
					makeBounds(traceEnds, origin)
					for(new j = 0; j < 8; j++) {
						if(PointContents(traceEnds[j]) == CONTENTS_SOLID) {
							remove_entity(ent)
							goToNextEnt = i+1
							break
						}
					}
				}
				if(goToNextEnt == i+1) continue
				entity_set_int(ent, EV_INT_flags, grabbedOldFlags[id][i])
				entity_set_int(ent, EV_INT_movetype, grabbedOldMoveType[id][i])
				entity_set_int(ent, EV_INT_solid, grabbedOldSolid[id][i])
				setOldRendering(id, ent, i)
			}
		}
	}
	grabbed[id] = 0
	grabmodeon[id] = false
	new players[32], inum, player
	get_players(players, inum)
	for(new k = 0 ; k < inum ; k++)
	{
		player = players[k]
		if(grabbed[player] == id)
		{
			if(task_exists(100+player))
			{
				remove_task(100+player)
			}
			grabbed[player] = 0
			grabmodeon[player] = false
		}
	}
	massrelease(id)
	return PLUGIN_CONTINUE
}

public client_connect(id)
{
	if(task_exists(100+id))
	{
		remove_task(100+id)
	}
	grabbed[id] = 0
	grabmodeon[id] = false
}

public client_disconnect(id)
{
	if(task_exists(100+id))
	{
		remove_task(100+id)
	}
	if(grabbed[id] > 0 && is_entity(grabbed[id]))
	{
		if(is_entity(grabbed[id])) {
			if(grabbedNoClip[id] == 0 && !is_user_connected(grabbed[id]) && entity_get_int(grabbed[id], EV_INT_iuser4) != 99) {
				new Float:origin[3]
				entity_get_vector(grabbed[id], EV_VEC_origin, origin)
				new Float:traceEnds[8][3]
				// By JGHG
				makeBounds(traceEnds, origin)
				for(new j = 0; j < 8; j++) {
					if(PointContents(traceEnds[j]) == CONTENTS_SOLID) {
						remove_entity(grabbed[id])
						break
					}
				}
			}
			if(is_entity(grabbed[id])) {
				entity_set_int(grabbed[id], EV_INT_flags, grabbedOldFlags[id][0])
				entity_set_int(grabbed[id], EV_INT_movetype, grabbedOldMoveType[id][0])
				entity_set_int(grabbed[id], EV_INT_solid, grabbedOldSolid[id][0])
				setOldRendering(id, grabbed[id], 0)
			}
		}
		if(g_massMoveOn[id] == true) {
			new ent, i, num = g_massMoveNum[id], goToNextEnt = 0
			for(i = 0; i < num; i++) {
				ent = g_massMoveEnts[id][i]
				if(!is_entity(ent)) continue
				if(grabbedNoClip[id] == 0 && !is_user_connected(ent) && entity_get_int(ent, EV_INT_iuser4) != 99) {
					entity_get_vector(ent, EV_VEC_origin, origin)
					// By JGHG
					makeBounds(traceEnds, origin)
					for(new j = 0; j < 8; j++) {
						if(PointContents(traceEnds[j]) == CONTENTS_SOLID) {
							remove_entity(ent)
							goToNextEnt = i+1
							break
						}
					}
				}
				if(goToNextEnt == i+1) continue
				entity_set_int(ent, EV_INT_flags, grabbedOldFlags[id][i])
				entity_set_int(ent, EV_INT_movetype, grabbedOldMoveType[id][i])
				entity_set_int(ent, EV_INT_solid, grabbedOldSolid[id][i])
				setOldRendering(id, ent, i)
			}
		}
	}
	grabbed[id] = 0
	grabmodeon[id] = false
	massrelease(id)
}

public e_kill(id,level,cid) {
	if(!cmd_access(id,level,cid,1))
		return PLUGIN_HANDLED
	
	if(read_argc() >= 2) {
		new class[64]
		new Float:range = 250.0
		if(read_argc() == 3) {
			read_argv(2, class, 63)
			range = floatstr(class)
		}
		read_argv(1, class, 63)
		new Float:origin[3]
		if(id > 0) entity_get_vector(id, EV_VEC_origin, origin)
		new string[64], tempent
		new targetid = find_entity_sphere(id, origin, range)
		while(targetid > 0) {
			tempent = find_entity_sphere(targetid, origin, range)
			string[0] = '^0'
			entity_get_string(targetid, EV_SZ_classname, string, 63)
			if(equali(string, class)) {
				remove_entity(targetid)
			}
			targetid = tempent
		}
		return PLUGIN_HANDLED
	}
	if(id <= 0) return PLUGIN_HANDLED
	
	new targetid = searchTarget(id, 1)
	if(targetid > 0) {
		if(!is_user_connected(targetid) && is_entity(targetid)) {
			remove_entity(targetid)
			console_print(id, "[AMX] The entity %d has been removed", targetid)
			return PLUGIN_HANDLED
		}
	}
	console_print(id, "[AMX] No entity or entity not valid")
	return PLUGIN_HANDLED
}

public e_rotate(id,level,cid) {
	if(!cmd_access(id,level,cid,4))
		return PLUGIN_HANDLED
	
	new targetid=0
	if(read_argc() == 5) {
		new arg[32]
		read_argv(4, arg, 31)
		if(is_str_num(arg)) {
			targetid = strtonum(arg)
		}
		else {
			targetid = cmd_target(id, arg, 5)
		}
		if(!is_entity(targetid) || targetid == id) {
			console_print(id, "[AMX] Entity invalid")
			return PLUGIN_HANDLED
		}
	}
	else {
		targetid = searchTarget(id, 1)
	}
	if(targetid > 0) {
		if(is_entity(targetid)) {
			new Float:angles[3], Float:vangle[3]
			entity_get_vector(targetid, EV_VEC_angles, angles)
			entity_get_vector(targetid, EV_VEC_v_angle, vangle)
			new i, arg[32]
			for(i = 0; i < 3; i++) {
				read_argv(i+1, arg, 31)
				angles[i] += floatstr(arg)
				vangle[i] += floatstr(arg)
			}
			entity_set_vector(targetid, EV_VEC_angles, angles)
			entity_set_vector(targetid, EV_VEC_v_angle, vangle)
			entity_set_int(targetid, EV_INT_fixangle, 1)
			console_print(id, "[AMX] The entity %d has been rotated", targetid)
			return PLUGIN_HANDLED
		}
	}
	console_print(id, "[AMX] No entity or entity not valid")
	return PLUGIN_HANDLED
}

public e_droptofloor(id,level,cid) {
	if(!cmd_access(id,level,cid,1))
		return PLUGIN_HANDLED
	
	new targetid=0
	if(read_argc() == 2) {
		new arg[32]
		read_argv(1, arg, 31)
		if(is_str_num(arg)) {
			targetid = strtonum(arg)
		}
		if(!is_entity(targetid) || targetid <= g_maxplayers) {
			console_print(id, "[AMX] Entity invalid")
			return PLUGIN_HANDLED
		}
	}
	else {
		targetid = searchTarget(id, 1)
	}
	if(targetid > 0) {
		if(is_entity(targetid)) {
			drop_to_floor(targetid)
			console_print(id, "[AMX] The entity %d has been dropped to floor", targetid)
			return PLUGIN_HANDLED
		}
	}
	console_print(id, "[AMX] No entity or entity not valid")
	return PLUGIN_HANDLED
}

public e_telestart(id,level,cid) {
	if(!cmd_access(id,level,cid,2))
		return PLUGIN_HANDLED
	
	new arg[32]
	read_argv(1, arg, 31)
	new Float:origin[3]
	if(read_argc() == 5) {
		new arg2[32]
		read_argv(2, arg2, 31)
		origin[0] = floatstr(arg2)
		read_argv(3, arg2, 31)
		origin[1] = floatstr(arg2)
		read_argv(4, arg2, 31)
		origin[2] = floatstr(arg2)
	}
	else {
		entity_get_vector(id, EV_VEC_origin, origin)
	}
	if(canCreateEntity() == 0) {
		console_print(id, "[AMX] Too many entities on the map.")
		return PLUGIN_HANDLED
	}
	new ent = create_entity("cycler_sprite")
	if(ent > 0) {
		DispatchKeyValue(ent, "classname", "cycler_sprite")
		DispatchKeyValue(ent, "model", g_spriteTeleStart)
		DispatchKeyValue(ent, "rendercolor", "0 0 0")
		DispatchKeyValue(ent, "framerate", "10")
		DispatchKeyValue(ent, "angles", "0 0 0")
		DispatchSpawn(ent)
		entity_set_model(ent, g_spriteTeleStart)
		entity_set_size(ent, Float:{-40.0, -40.0, -40.0}, Float:{40.0, 40.0, 40.0})
		entity_set_int(ent, EV_INT_rendermode, 5)
		entity_set_float(ent, EV_FL_renderamt, 175.0)
		entity_set_int(ent, EV_INT_solid, SOLID_NOT)
		entity_set_origin(ent, origin)
		new ent2 = create_entity("trigger_teleport")
		if(ent2 > 0) {
			DispatchKeyValue(ent2, "classname", "trigger_teleport")
			DispatchKeyValue(ent2, "style", "32")
			DispatchKeyValue(ent2, "target", arg)
			DispatchSpawn(ent2)
			entity_set_edict(ent2, EV_ENT_euser1, ent)
			entity_set_size(ent2, Float:{-10.0, -10.0, -10.0}, Float:{10.0, 10.0, 10.0})
			entity_set_origin(ent2, origin)
			entity_set_int(ent2, EV_INT_solid, SOLID_TRIGGER)
			entity_set_int(ent2, EV_INT_effects, EF_NODRAW)
			console_print(id, "[AMX] Teleporter start ^"%s^" has been created", arg)
			return PLUGIN_HANDLED
		}
	}
	console_print(id, "[AMX] Couldn't create teleporter start")
	return PLUGIN_HANDLED
}

public e_teleend(id,level,cid) {
	if(!cmd_access(id,level,cid,2))
		return PLUGIN_HANDLED
	
	new arg[32]
	read_argv(1, arg, 31)
	new Float:origin[3]
	if(read_argc() == 5) {
		new arg2[32]
		read_argv(2, arg2, 31)
		origin[0] = floatstr(arg2)
		read_argv(3, arg2, 31)
		origin[1] = floatstr(arg2)
		read_argv(4, arg2, 31)
		origin[2] = floatstr(arg2)
	}
	else {
		entity_get_vector(id, EV_VEC_origin, origin)
	}
	if(canCreateEntity() == 0) {
		console_print(id, "[AMX] Too many entities on the map.")
		return PLUGIN_HANDLED
	}
	new ent = create_entity("cycler_sprite")
	if(ent > 0) {
		DispatchKeyValue(ent, "classname", "cycler_sprite")
		DispatchKeyValue(ent, "model", g_spriteTeleEnd)
		DispatchKeyValue(ent, "rendercolor", "0 0 0")
		DispatchKeyValue(ent, "framerate", "10")
		DispatchKeyValue(ent, "angles", "0 0 0")
		DispatchSpawn(ent)
		entity_set_size(ent, Float:{-40.0, -40.0, -40.0}, Float:{40.0, 40.0, 40.0})
		entity_set_int(ent, EV_INT_rendermode, 5)
		entity_set_float(ent, EV_FL_renderamt, 175.0)
		entity_set_int(ent, EV_INT_solid, SOLID_NOT)
		entity_set_origin(ent, origin)
		new ent2 = create_entity("info_teleport_destination")
		if(ent2 > 0) {
			DispatchKeyValue(ent2, "classname", "info_teleport_destination")
			DispatchKeyValue(ent2, "targetname", arg)
			DispatchKeyValue(ent2, "angles", "0 0 0")
			DispatchSpawn(ent2)
			entity_set_edict(ent2, EV_ENT_euser1, ent)
			entity_set_size(ent2, Float:{-1.0, -1.0, -1.0}, Float:{1.0, 1.0, 1.0})
			entity_set_origin(ent2, origin)
			entity_set_int(ent2, EV_INT_solid, SOLID_TRIGGER)
			entity_set_int(ent2, EV_INT_effects, EF_NODRAW)
			console_print(id, "[AMX] Teleporter end ^"%s^" has been created", arg)
			return PLUGIN_HANDLED
		}
	}
	console_print(id, "[AMX] Couldn't create teleporter end")
	return PLUGIN_HANDLED
}

public e_teledelete(id,level,cid) {
	if(!cmd_access(id,level,cid,2))
		return PLUGIN_HANDLED
	
	new arg[32]
	read_argv(1, arg, 31)
	new ent2, tempent, target[32]
	new ent = find_entity(-1, "info_teleport_destination")
	while(ent > 0) {
		tempent = find_entity(ent, "info_teleport_destination")
		entity_get_string(ent, EV_SZ_targetname, target, 31)
		if(equal(target, arg)) {
			ent2 = entity_get_edict(ent, EV_ENT_euser1)
			if(is_entity(ent2)) remove_entity(ent2)
			remove_entity(ent)
		}
		ent = tempent
	}
	ent = find_entity(-1, "trigger_teleport")
	while(ent > 0) {
		tempent = find_entity(ent, "trigger_teleport")
		entity_get_string(ent, EV_SZ_target, target, 31)
		if(equal(target, arg)) {
			ent2 = entity_get_edict(ent, EV_ENT_euser1)
			if(is_entity(ent2)) remove_entity(ent2)
			remove_entity(ent)
		}
		ent = tempent
	}
	console_print(id, "[AMX] Teleporters ^"%s^" have been removed", arg)
	return PLUGIN_HANDLED
}

massrelease(id) {
	g_massMoveOn[id] = false
	new num = g_massMoveNum[id]
	if(num > 1) {
		new i, ent
		setOldRendering(id, ent, 0)
		new Float:origin[3], Float:traceEnds[8][3], goToNextEnt = 0
		for(i = 1; i < num; i++) {
			ent = g_massMoveEnts[id][i]
			if(!is_entity(ent)) continue
			if(grabbedNoClip[id] == 0 && !is_user_connected(ent) && entity_get_int(ent, EV_INT_iuser4) != 99) {
				entity_get_vector(ent, EV_VEC_origin, origin)
				// By JGHG
				makeBounds(traceEnds, origin)
				for(new j = 0; j < 8; j++) {
					if(PointContents(traceEnds[j]) == CONTENTS_SOLID) {
						remove_entity(ent)
						goToNextEnt = i+1
						break
					}
				}
			}
			if(goToNextEnt == i+1) continue
			entity_set_int(ent, EV_INT_movetype, grabbedOldMoveType[id][i])
			entity_set_int(ent, EV_INT_solid, grabbedOldSolid[id][i])
			entity_set_int(ent, EV_INT_flags, grabbedOldFlags[id][i])
			setOldRendering(id, ent, i)
		}
	}
	g_massMoveNum[id] = 0
}

isGrabbed(id, ent) {
	new num = g_massMoveNum[id]
	if(num < 1) return 0
	new i
	for(i = 0; i < num; i++) {
		if(g_massMoveEnts[id][i] == ent)
			return 1
	}
	return 0
}

public mm_grab(id,level,cid) {
	if(!cmd_access(id,level,cid,1))
		return PLUGIN_HANDLED
	
	if(g_massMoveNum[id] >= MAX_MASSMOVE_ENTS) {
		client_print(id, print_chat, "[AMX] You can't grab any more entities")
		return PLUGIN_HANDLED
	}
	
	new targetid=0, body
	get_user_aiming(id, targetid, body)
	if(is_user_alive(targetid) && get_user_flags(targetid) & ADMIN_IMMUNITY && !(get_user_flags(id) & ADMIN_SUPREME))
	{
		client_print(id, print_chat, "[AMX] Player has immunity!")
		return PLUGIN_HANDLED
	}
	if(!targetid)
	{
		targetid = searchTarget(id, 0)
	}
	if(targetid > 0) {
		if(is_entity(targetid) && !isGrabbed(id, targetid)) {
			new num = g_massMoveNum[id]
			g_massMoveEnts[id][num] = targetid
			new Float:color[3]
			grabbedOldRender[id][num][0] = entity_get_int(targetid, EV_INT_renderfx)
			entity_get_vector(targetid, EV_VEC_rendercolor, color)
			grabbedOldRender[id][num][1] = floatround(color[0])
			grabbedOldRender[id][num][2] = floatround(color[1])
			grabbedOldRender[id][num][3] = floatround(color[2])
			grabbedOldRender[id][num][4] = entity_get_int(targetid, EV_INT_rendermode)
			grabbedOldRender[id][num][5] = floatround(entity_get_float(targetid, EV_FL_renderamt))
			setMMGrabRendering(targetid)
			g_massMoveNum[id]++
			new class[32]
			entity_get_string(targetid, EV_SZ_classname, class, 31)
			client_print(id, print_chat, "[AMX] You grabbed entity %d (%s)", targetid, class)
			return PLUGIN_HANDLED
		}
	}
	client_print(id, print_chat, "[AMX] No target found or entity already grabbed")
	
	return PLUGIN_HANDLED
}

public mm_start(id,level,cid) {
	if(!cmd_access(id,level,cid,1))
		return PLUGIN_HANDLED
	
	if(g_massMoveOn[id] == true) {
		return PLUGIN_HANDLED
	}
	new num = g_massMoveNum[id]
	if(num <= 0) {
		client_print(id, print_chat, "[AMX] You haven't grabbed any entity")
		return PLUGIN_HANDLED
	}
	g_massMoveOn[id] = true
	set_grabbed(id, g_massMoveEnts[id][0])
	new i
	for(i = 1; i < num; i++) {
		grabbedOldMoveType[id][i] = entity_get_int(g_massMoveEnts[id][i], EV_INT_movetype)
		grabbedOldSolid[id][i] = entity_get_int(g_massMoveEnts[id][i], EV_INT_solid)
		grabbedOldFlags[id][i] = entity_get_int(g_massMoveEnts[id][i], EV_INT_flags)
	}
	velocity_multiplier = get_cvar_num("sv_grab_force")
	new cmd[32]
	read_argv(0, cmd, 31)
	if(containi(cmd, "2") != -1) {
		grabbedNoClip[id] = 1
	}
	else {
		grabbedNoClip[id] = 0
	}
	grabmodeon[id]=true
	new parm[1]
	parm[0] = id
	set_task(0.1, "grabtask", 100+id, parm, 1, "b")
	return PLUGIN_HANDLED
}

public mm_end(id,level,cid) {
	if(!cmd_access(id,level,cid,1))
		return PLUGIN_HANDLED
	
	if(g_massMoveOn[id] == false) {
		return PLUGIN_HANDLED
	}
	release(id, 0, 0)
	massrelease(id)
	return PLUGIN_HANDLED
}

public e_stack(id,level,cid) {
	if(!cmd_access(id,level,cid,5))
		return PLUGIN_HANDLED
	
	new num
	new arg[32]
	read_argv(1, arg, 31)
	num = strtonum(arg)
	if(num <= 0) {
		console_print(id, "[AMX] Incorrect amount of entities")
		return PLUGIN_HANDLED
	}
	new Float:offset[3]
	read_argv(2, arg, 31)
	offset[0] = floatstr(arg)
	read_argv(3, arg, 31)
	offset[1] = floatstr(arg)
	read_argv(4, arg, 31)
	offset[2] = floatstr(arg)
	
	new targetid=0, body
	get_user_aiming(id, targetid, body)
	if(is_user_connected(targetid))
	{
		console_print(id, "[AMX] You can't stack players")
		return PLUGIN_HANDLED
	}
	if(!targetid)
	{
		targetid = searchTarget(id, 0)
	}
	if(targetid > 0) {
		if(is_entity(targetid)) {
			new i, copyId, Float:targetOrigin[3], Float:copyOrigin[3]
			entity_get_vector(targetid, EV_VEC_origin, targetOrigin)
			for(i = 1; i <= num; i++) {
				copyId = makeCopyOf(targetid)
				copyOrigin[0] = targetOrigin[0] + (i*offset[0])
				copyOrigin[1] = targetOrigin[1] + (i*offset[1])
				copyOrigin[2] = targetOrigin[2] + (i*offset[2])
				entity_set_origin(copyId, copyOrigin)
			}
			client_print(id, print_chat, "[AMX] Entity has been copied %d times", num)
			return PLUGIN_HANDLED
		}
	}
	client_print(id, print_chat, "[AMX] No target found")
	
	return PLUGIN_HANDLED
}

public e_lookingat(id,level,cid) {
	if(!cmd_access(id,level,cid,1))
		return PLUGIN_HANDLED
	
	new targetid=0, body
	get_user_aiming(id, targetid, body)
	if(is_user_connected(targetid))
	{
		return PLUGIN_HANDLED
	}
	if(!targetid)
	{
		targetid = searchTarget(id, 0)
	}
	if(targetid > 0) {
		if(is_entity(targetid)) {
			new class[32]
			entity_get_string(targetid, EV_SZ_classname, class, 31)
			new Float:vecmins[3], Float:vecmaxs[3]
			entity_get_vector(targetid, EV_VEC_mins, vecmins)
			entity_get_vector(targetid, EV_VEC_maxs, vecmaxs)
			console_print(id, "[AMX] The entity you're looking at is:")
			console_print(id, "  Id: %d", targetid)
			console_print(id, "  ClassName: %s", class)
			console_print(id, "  Size on the X Axis: %d", floatround(vecmaxs[0] - vecmins[0]))
			console_print(id, "  Size on the Y Axis: %d", floatround(vecmaxs[1] - vecmins[1]))
			console_print(id, "  Size on the Z Axis: %d", floatround(vecmaxs[2] - vecmins[2]))
			return PLUGIN_HANDLED
		}
	}
	client_print(id, print_chat, "[AMX] No target found")
	
	return PLUGIN_HANDLED
}

public e_grabtype(id,level,cid) {
	if(!cmd_access(id,level,cid,2))
		return PLUGIN_HANDLED
	
	new class[64]
	new Float:range = 250.0
	if(read_argc() == 3) {
		read_argv(2, class, 63)
		range = floatstr(class)
	}
	read_argv(1, class, 63)
	new Float:origin[3]
	entity_get_vector(id, EV_VEC_origin, origin)
	new string[64]
	new targetid = find_entity_sphere(id, origin, range)
	while(targetid > 0) {
		string[0] = '^0'
		entity_get_string(targetid, EV_SZ_classname, string, 63)
		if(equali(string, class)) {
			break
		}
		targetid = find_entity_sphere(targetid, origin, range)
	}
	if(targetid > 0) {
		grabbedNoClip[id] = 1
		new parm[1]
		parm[0] = id
		velocity_multiplier = get_cvar_num("sv_grab_force")
		grabmodeon[id]=true
		set_task(0.1, "grabtask", 100+id, parm, 1, "b")
		set_grabbed(id, targetid)
	}
	client_print(id, print_chat, "[AMX] No target found")
	
	return PLUGIN_HANDLED
}

public e_stopgrab(id,level,cid) {
	if(!cmd_access(id,level,cid,1))
		return PLUGIN_HANDLED
	
	release(id, 0, 0)
	return PLUGIN_HANDLED
}

public showaxis(id,level,cid) {
	if(!cmd_access(id,level,cid,1))
		return PLUGIN_HANDLED
	
	new cmd[32]
	read_argv(0, cmd, 31)
	new red, green, blue
	new origin[3], origin2[3]
	get_user_origin(id, origin)
	origin2[0] = origin[0]
	origin2[1] = origin[1]
	origin2[2] = origin[2]
	switch(cmd[8]) {
		case 'x': {
			origin2[0] += 400
			red = 255
		}
		case 'y': {
			origin2[1] += 400
			green = 255
		}
		case 'z': {
			origin2[2] += 400
			blue = 255
		}
	}
	message_begin(MSG_ONE, SVC_TEMPENTITY, {0,0,0}, id)
	write_byte(0)
	write_coord(origin[0])
	write_coord(origin[1])
	write_coord(origin[2])
	write_coord(origin2[0])
	write_coord(origin2[1])
	write_coord(origin2[2])
	write_short(laserbeam)
	write_byte(0)
	write_byte(0)
	write_byte(600)
	write_byte(40)
	write_byte(0)
	write_byte(red)
	write_byte(green)
	write_byte(blue)
	write_byte(255)
	write_byte(0)
	message_end()
	return PLUGIN_HANDLED
}

public e_showkeyvalue(id,level,cid) {
	if(!cmd_access(id,level,cid,1))
		return PLUGIN_HANDLED
	
	new targetid=0
	if(read_argc() == 2) {
		new arg[32]
		read_argv(1, arg, 31)
		if(is_str_num(arg)) {
			targetid = strtonum(arg)
		}
		else {
			targetid = cmd_target(id, arg, 0)
		}
		if(!is_entity(targetid)) {
			console_print(id, "[AMX] Entity invalid")
			return PLUGIN_HANDLED
		}
	}
	else {
		targetid = searchTarget(id, 1)
	}
	if(targetid > 0) {
		if(is_entity(targetid)) {
			console_print(id, "KeyValues of entity %d:", targetid)
			if(targetid > g_maxplayers) {
				if(!g_key[targetid][0][0]) {
					targetid = entity_get_int(targetid, EV_INT_iuser3)
				}
			}
			new maxkeyvalues = g_keyValueNum[targetid]
			for(new i = 0; i < maxkeyvalues; i++) {
				console_print(id, "Key=^"%s^", Value=^"%s^"", g_key[targetid][i], g_value[targetid][i])
			}
			return PLUGIN_HANDLED
		}
	}
	console_print(id, "[AMX] No entity or entity not valid")
	return PLUGIN_HANDLED
}

public e_setkeyvalue(id,level,cid) {
	if(!cmd_access(id,level,cid,3))
		return PLUGIN_HANDLED
	
	new targetid=0
	if(read_argc() == 4) {
		new arg[32]
		read_argv(1, arg, 31)
		if(is_str_num(arg)) {
			targetid = strtonum(arg)
		}
		else {
			targetid = cmd_target(id, arg, 1)
		}
		if(!is_entity(targetid)) {
			console_print(id, "[AMX] Entity invalid")
			return PLUGIN_HANDLED
		}
	}
	else {
		targetid = searchTarget(id, 1)
	}
	if(targetid > 0) {
		if(is_entity(targetid)) {
			new key[64], value[64]
			read_argv(1, key, 63)
			read_argv(2, value, 63)
			DispatchKeyValue(targetid, key, value)
			if(targetid > g_maxplayers) {
				if(!g_key[targetid][0][0]) {
					targetid = entity_get_int(targetid, EV_INT_iuser3)
				}
			}
			new maxkeyvalues = g_keyValueNum[targetid]
			for(new i = 0; i < maxkeyvalues; i++) {
				if(equal(g_key[targetid][i], key)) {
					copy(g_value[targetid][i], VALUE_LENGTH-1, value)
					break
				}
			}
			if(targetid > g_maxplayers) DispatchSpawn(targetid)
			console_print(id, "KeyValue set on entity %d.", targetid)
			return PLUGIN_HANDLED
		}
	}
	console_print(id, "[AMX] No entity or entity not valid")
	return PLUGIN_HANDLED
}

public e_use(id,level,cid) {
	if(!cmd_access(id,level,cid,1))
		return PLUGIN_HANDLED
	
	new targetid = searchTarget(id, 1)
	if(targetid > 0) {
		if(is_entity(targetid)) {
			new user
			if(read_argc() == 2) {
				new arg[32]
				read_argv(1, arg, 31)
				user = cmd_target(id, arg, 5)
				if(!user) return PLUGIN_HANDLED
			}
			else {
				user = id
			}
			entity_use(targetid, user)
			new class[32]
			entity_get_string(targetid, EV_SZ_classname, class, 31)
			if(user != id) {
				new plname[32]
				get_user_name(user, plname, 31)
				client_print(id, print_chat, "[AMX] %s ^"used^" entity %d (%s)", plname, targetid, class)
			}
			else {
				client_print(id, print_chat, "[AMX] You ^"used^" entity %d (%s)", targetid, class)
			}
			return PLUGIN_HANDLED
		}
	}
	client_print(id, print_chat, "[AMX] No target found")
	
	return PLUGIN_HANDLED
}

public e_search(id,level,cid) {
	if(!cmd_access(id,level,cid,1))
		return PLUGIN_HANDLED
	
	new Float:range = 200.0
	new Float:origin[3]
	entity_get_vector(id, EV_VEC_origin, origin)
	new class[64]
	new targetid = find_entity_sphere(id, origin, range)
	if(targetid < 1) {
		console_print(id, "No entity found")
		return PLUGIN_HANDLED
	}
	while(targetid > 0) {
		entity_get_string(targetid, EV_SZ_classname, class, 63)
		console_print(id, "Entity found: Id = %d, ClassName = %s", targetid, class)
		targetid = find_entity_sphere(targetid, origin, range)
	}
	return PLUGIN_HANDLED
}

public e_undo(id,level,cid) {
	if(!cmd_access(id,level,cid,1))
		return PLUGIN_HANDLED
	
	new targetid = searchTarget(id, 1)
	if(targetid > 0) {
		if(is_entity(targetid) && targetid > g_maxplayers) {
			entity_set_origin(targetid, Float:{0.0,0.0,0.0})
			return PLUGIN_HANDLED
		}
	}
	client_print(id, print_chat, "[AMX] No target found")
	
	return PLUGIN_HANDLED
}

setBrushOrigin(ent, entId, Float:origin[3]) {
	new Float:entorigin[3], Float:mins[3], Float:maxs[3], Float:absmin[3], Float:absmax[3]
	new Float:sizeX, Float:sizeY, Float:sizeZ
	entity_get_vector(entId, EV_VEC_mins, mins)
	entity_get_vector(entId, EV_VEC_maxs, maxs)
	sizeX = maxs[0] - mins[0]
	sizeY = maxs[1] - mins[1]
	sizeZ = maxs[2] - mins[2]
	absmin[0] = origin[0] - (sizeX/2.0)
	absmin[1] = origin[1] - (sizeY/2.0)
	absmin[2] = origin[2]
	absmax[0] = origin[0] + (sizeX/2.0)
	absmax[1] = origin[1] + (sizeY/2.0)
	absmax[2] = origin[2] + sizeZ
	entity_set_vector(ent, EV_VEC_absmin, absmin)
	entity_set_vector(ent, EV_VEC_absmax, absmax)
	entorigin[0] = absmin[0] - mins[0]
	entorigin[1] = absmin[1] - mins[1]
	entorigin[2] = absmin[2] - mins[2]
	entity_set_origin(ent, entorigin)
}

public e_wall(id,level,cid) {
	if(!cmd_access(id,level,cid,6))
		return PLUGIN_HANDLED
	
	new arg1[16], arg2[16], arg3[16], arg4[16], arg5[16]
	read_argv(1, arg1, 15)
	read_argv(2, arg2, 15)
	read_argv(3, arg3, 15)
	read_argv(4, arg4, 15)
	read_argv(5, arg5, 15)
	new entId = strtonum(arg1)
	if(!is_entity(entId) || entId <= g_maxplayers) {
		console_print(id, "[AMX] Entity not valid")
		return PLUGIN_HANDLED
	}
	
	new iAimorigin[3], Float:aimorigin[3]
	get_user_origin(id, iAimorigin, 3)
	IVecFVec(iAimorigin, aimorigin)
	
	new Float:angles[3]
	entity_get_vector(id, EV_VEC_v_angle, angles)
	angles[0] = 0.0
	new Float:entangles[3]
	entangles[1] = angles[1] - 90.0
	
	new rownums = str_to_num(arg3) - 1
	new colnums = str_to_num(arg2)
	new middleent = floatround(float(colnums)/2.0, floatround_floor)
	new rowoffset = str_to_num(arg4)
	new coloffset = str_to_num(arg5)
	if(rownums <= 0 || colnums <= 0 || rowoffset < 0 || coloffset < 0) {
		console_print(id, "[AMX] A parameter is incorrect.")
		return PLUGIN_HANDLED
	}
	
	new isBrush = 0
	if(entity_get_int(entId, EV_INT_iuser4) == 99) {
		isBrush = 1
	}
	new Float:entorigin[3], Float:velocity[3]
	
	new ent, i, j
	
	for(i = -middleent ; i <= ((colnums%2 == 1) ? middleent : middleent - 1) ; i++)
	{
		ent = makeCopyOf(entId)
		if(ent > 0)
		{
			if(isBrush == 1) setBrushOrigin(ent, entId, aimorigin)
			else entity_set_origin(ent, aimorigin)
			entity_set_vector(ent, EV_VEC_v_angle, entangles)
			VelocityByAim(ent, rowoffset*i, velocity) //x*i, x = distance between columns
			entorigin[0] = aimorigin[0] + velocity[0]
			entorigin[1] = aimorigin[1] + velocity[1]
			entorigin[2] = aimorigin[2] + velocity[2]
			if(isBrush == 1) setBrushOrigin(ent, entId, entorigin)
			else entity_set_origin(ent, entorigin)
			if(isBrush == 0) entity_set_vector(ent, EV_VEC_angles, angles)
			for(j = 0 ; j < rownums ; j++)
			{
				ent = makeCopyOf(entId)
				if(ent > 0)
				{
					entorigin[2] += float(coloffset) // height between rows
					if(isBrush == 1) setBrushOrigin(ent, entId, entorigin)
					else entity_set_origin(ent, entorigin)
					if(isBrush == 0) entity_set_vector(ent, EV_VEC_angles, angles)
				}
			}
		}
	}
	client_print(id, print_chat, "[AMX] Wall has been created.")
	
	return PLUGIN_HANDLED
}

isSaved(id, ent) {
	new num = g_saveEntsNum[id]
	if(num < 1) return 0
	new i
	for(i = 0; i < num; i++) {
		if(g_saveEnts[id][i] == ent)
			return 1
	}
	return 0
}

public es_grab(id,level,cid) {
	if(!cmd_access(id,level,cid,1))
		return PLUGIN_HANDLED
	
	new targetid=0
	if(read_argc() == 2) {
		new arg[32]
		read_argv(1, arg, 31)
		if(is_str_num(arg)) {
			targetid = strtonum(arg)
		}
		if(!is_entity(targetid) || targetid <= g_maxplayers) {
			console_print(id, "[AMX] Entity invalid")
			return PLUGIN_HANDLED
		}
	}
	else {
		targetid = searchTarget(id, 1)
	}
	if(targetid > 0) {
		if(is_entity(targetid) && targetid > g_maxplayers && !isSaved(id, targetid)) {
			new num = g_saveEntsNum[id]
			g_saveEnts[id][num] = targetid
			new Float:color[3]
			grabbedOldRender[id][num][0] = entity_get_int(targetid, EV_INT_renderfx)
			entity_get_vector(targetid, EV_VEC_rendercolor, color)
			grabbedOldRender[id][num][1] = floatround(color[0])
			grabbedOldRender[id][num][2] = floatround(color[1])
			grabbedOldRender[id][num][3] = floatround(color[2])
			grabbedOldRender[id][num][4] = entity_get_int(targetid, EV_INT_rendermode)
			grabbedOldRender[id][num][5] = floatround(entity_get_float(targetid, EV_FL_renderamt))
			setSaveRendering(targetid)
			g_saveEntsNum[id]++
			new class[32]
			entity_get_string(targetid, EV_SZ_classname, class, 31)
			client_print(id, print_chat, "[AMX] You grabbed entity %d (%s)", targetid, class)
			return PLUGIN_HANDLED
		}
	}
	client_print(id, print_chat, "[AMX] No target found")
	
	return PLUGIN_HANDLED
}

public es_ungrab(id,level,cid) {
	if(!cmd_access(id,level,cid,1))
		return PLUGIN_HANDLED
	
	if(g_saveEntsNum[id] > 0) {
		--g_saveEntsNum[id]
		console_print(id, "[AMX] Last entity added (%d) has been removed.", g_saveEnts[id][g_saveEntsNum[id]])
		setOldRendering(id, g_saveEnts[id][g_saveEntsNum[id]], g_saveEntsNum[id])
		return PLUGIN_HANDLED
	}
	console_print(id, "[AMX] You haven't saved any entities.")
	
	return PLUGIN_HANDLED
}

public es_cancel(id,level,cid) {
	if(!cmd_access(id,level,cid,1))
		return PLUGIN_HANDLED
	
	if(g_saveEntsNum[id] > 0) {
		new maxnum = g_saveEntsNum[id]
		for(new i = 0; i < maxnum; i++) {
			setOldRendering(id, g_saveEnts[id][i], i)
		}
		g_saveEntsNum[id] = 0
		console_print(id, "[AMX] All the entities added have been removed.")
		return PLUGIN_HANDLED
	}
	console_print(id, "[AMX] You haven't saved any entities.")
	
	return PLUGIN_HANDLED
}

public es_save(id,level,cid) {
	if(!cmd_access(id,level,cid,2))
		return PLUGIN_HANDLED
	
	if(g_saveEntsNum[id] > 0) {
		new arg[32]
		read_argv(1, arg, 31)
		new filename[128], savedir[64], text[128], classname[32]
		build_path(savedir, 127, "$basedir/entsave")
		if(!dir_exists(savedir)) mkdir(savedir)
		new mapname[32]
		get_mapname(mapname, 31)
		format(filename, 127, "%s/%s_%s.txt", savedir, mapname, arg)
		if(file_exists(filename)) delete_file(filename)
		new num = g_saveEntsNum[id]
		new ent, i, j
		new maxkeyvalues
		new Float:vector[3]
		for(j = 0; j < num; j++) {
			ent = g_saveEnts[id][j]
			if(!is_entity(ent)) continue
			if(!g_key[ent][0][0]) {
				ent = entity_get_int(ent, EV_INT_iuser3)
			}
			if(!is_entity(ent)) continue
			write_file(filename, "{")
			entity_get_string(ent, EV_SZ_classname, classname, 31)
			format(text, 127, "^"classname^" ^"%s^"", classname)
			write_file(filename, text)
			maxkeyvalues = g_keyValueNum[ent]
			for(i = 0; i < maxkeyvalues; i++) {
				format(text, 127, "^"%s^" ^"%s^"", g_key[ent][i], g_value[ent][i])
				write_file(filename, text)
			}
			write_file(filename, "")
			entity_get_vector(ent, EV_VEC_origin, vector)
			format(text, 127, "^"origin^" ^"%f %f %f^"", vector[0], vector[1], vector[2])
			write_file(filename, text)
			/*entity_get_vector(ent, EV_VEC_absmin, vector)
			format(text, 127, "%f %f %f", vector[0], vector[1], vector[2])
			write_file(filename, text)
			entity_get_vector(ent, EV_VEC_absmax, vector)
			format(text, 127, "%f %f %f", vector[0], vector[1], vector[2])
			write_file(filename, text)*/
			entity_get_vector(ent, EV_VEC_angles, vector)
			format(text, 127, "^"angles^" ^"%f %f %f^"", vector[0], vector[1], vector[2])
			write_file(filename, text)
			format(text, 127, "^"iuser4^" ^"%d^"", entity_get_int(ent, EV_INT_iuser4))
			write_file(filename, text)
			write_file(filename, "}")
		}
		console_print(id, "[AMX] All the entities have been saved (%s).", arg)
		return PLUGIN_HANDLED
	}
	console_print(id, "[AMX] You haven't saved any entities.")
	
	return PLUGIN_HANDLED
}

public es_list(id,level,cid) {
	if(!cmd_access(id,level,cid,1))
		return PLUGIN_HANDLED
	
	new savedir[64]
	build_path(savedir, 127, "$basedir/entsave")
	if(!dir_exists(savedir)) {
		console_print(id, "[AMX] Save directory doesn't exist (%s)", savedir)
		return PLUGIN_HANDLED
	}
	new fileprefix[34], text[128]
	new motd[512], motdlen = 0
	motdlen += copy(motd, 511-motdlen, "<b>Groups saved for this map:</b><br><br>")
	new mapname[32]
	get_mapname(mapname, 31)
	format(fileprefix, 33, "%s_", mapname)
	new fileprefixLen = strlen(fileprefix)
	new pos, len
	while((pos = read_dir(savedir, pos, text, 127, len))) {
		console_print(id, "text=%s", text)
		if(len < 4) continue
		if(!equal(text, fileprefix, fileprefixLen)) continue
		if(len >= 4 && !equali(text[len - 4], ".txt", 4)) continue
		replace(text, 127, mapname, "")
		replace(text, 127, ".txt", "")
		motdlen += copy(motd[motdlen], 511-motdlen, text[1])
		motdlen += copy(motd[motdlen], 511-motdlen, "<br>")
	}
	show_motd(id, motd, mapname)
	return PLUGIN_HANDLED
}

public es_listall(id,level,cid) {
	if(!cmd_access(id,level,cid,1))
		return PLUGIN_HANDLED
	
	new savedir[64], text[128]
	build_path(savedir, 127, "$basedir/entsave")
	if(!dir_exists(savedir)) {
		console_print(id, "[AMX] Save directory doesn't exist (%s)", savedir)
		return PLUGIN_HANDLED
	}
	new motd[1024], motdlen = 0
	motdlen += copy(motd, 1023-motdlen, "<b>Groups saved for the server:</b><br><br>")
	new pos, len
	while((pos = read_dir(savedir, pos, text, 127, len))) {
		if(len < 4) continue
		if(len >= 4 && !equali(text[len - 4], ".txt", 4)) continue
		motdlen += format(motd[motdlen], 1023-motdlen, "%s<br>", text)
	}
	show_motd(id, motd, "All saved entities")
	return PLUGIN_HANDLED
}

public es_load(id,level,cid) {
	if(!cmd_access(id,level,cid,1))
		return PLUGIN_HANDLED
	
	new savedir[64]
	build_path(savedir, 127, "$basedir/entsave")
	if(!dir_exists(savedir)) {
		console_print(id, "[AMX] Save directory doesn't exist")
		return PLUGIN_HANDLED
	}
	new fileprefix[128], filename[128], text[128]
	new mapname[32]
	get_mapname(mapname, 31)
	format(fileprefix, 33, "%s_", mapname)
	new fileprefixLen = strlen(fileprefix)
	new pos, len, line, ent_state, key[64], value[96], ent=0
	new Float:vector[3], str1[32], str2[32], str3[32]
	while((pos = read_dir(savedir, pos, text, 127, len))) {
		if(len < 4) continue
		if(!equal(text, fileprefix, fileprefixLen)) continue
		if(len >= 4 && !equali(text[len - 4], ".txt", 4)) continue
		format(filename, 127, "%s/%s", savedir, text)
		line = 0
		while(read_file(filename, line++, text, 127, len)) {
			if(text[0] == '{') {
				ent_state = 1
				ent = 0
				continue
			}
			if(text[0] == '}' && ent_state >= 1) {
				if(ent > 0) {
					DispatchSpawn(ent)
				}
				ent_state = 0
				ent = 0
				continue
			}
			if(ent_state >= 1) {
				if(!text[0] && ent_state == 2) {
					ent_state = 3
					continue
				}
				if(len > 5) {
					if(ent_state == 1) {
						parse(text, key, 63, value, 95)
						if(equal(key, "classname")) {
							ent = create_entity(value)
							if(ent <= 0) {
								console_print(id, "[AMX] Couldn't create entity.")
								return PLUGIN_HANDLED
							}
							ent_state = 2
						}
					}
					else if(ent > 0) {
						if(ent_state == 2) {
							parse(text, key, 63, value, 95)
							DispatchKeyValue(ent, key, value)
							if(ent < MAX_ENTS && g_keyValueNum[ent] < MAX_KEYVALUES) {
								copy(g_key[ent][g_keyValueNum[ent]], KEY_LENGTH-1, key)
								copy(g_value[ent][g_keyValueNum[ent]], VALUE_LENGTH-1, value)
								g_keyValueNum[ent]++
							}
						}
						else if(ent_state == 3) {
							parse(text, key, 63, value, 95)
							if(equal(key, "origin")) {
								parse(value, str1, 31, str2, 31, str3, 31)
								vector[0] = floatstr(str1)
								vector[1] = floatstr(str2)
								vector[2] = floatstr(str3)
								entity_set_origin(ent, vector)
							}
							else if(equal(key, "angles")) {
								parse(value, str1, 31, str2, 31, str3, 31)
								vector[0] = floatstr(str1)
								vector[1] = floatstr(str2)
								vector[2] = floatstr(str3)
								entity_set_vector(ent, EV_VEC_angles, vector)
							}
							else if(equal(key, "iuser4")) {
								entity_set_int(ent, EV_INT_iuser4, strtonum(value))
							}
						}
					}
				}
			}
		}
	}
	return PLUGIN_HANDLED
}
