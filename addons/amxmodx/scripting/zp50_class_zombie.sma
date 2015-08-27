/*================================================================================
	
	--------------------------
	-*- [ZP] Class: Zombie -*-
	--------------------------
	
	This plugin is part of Zombie Plague Mod and is distributed under the
	terms of the GNU General Public License. Check ZP_ReadMe.txt for details.
	
================================================================================*/

#include <amxmodx>
#include <fun>
#include <fakemeta>
#include <amx_settings_api>
#include <cs_player_models_api>
#include <cs_weap_models_api>
#include <cs_maxspeed_api>
#include <cs_weap_restrict_api>
#include <zp50_core>
#include <zp50_colorchat>
#include <zp50_class_zombie_const>

// Zombie Classes file
new const ZP_ZOMBIECLASSES_FILE[] = "zp_zombieclasses.ini"

#define MAXPLAYERS 32

#define ZOMBIES_DEFAULT_NAME "Zombie"
#define ZOMBIES_DEFAULT_DESCRIPTION "Default"
#define ZOMBIES_DEFAULT_HEALTH 1800
#define ZOMBIES_DEFAULT_SPEED 0.75
#define ZOMBIES_DEFAULT_GRAVITY 1.0
#define ZOMBIES_DEFAULT_MODEL "zombie"
#define ZOMBIES_DEFAULT_CLAWMODEL "models/zombie_plague/v_knife_zombie.mdl"
#define ZOMBIES_DEFAULT_KNOCKBACK 1.0

// Allowed weapons for zombies
const ZOMBIE_ALLOWED_WEAPONS_BITSUM = (1<<CSW_KNIFE)|(1<<CSW_HEGRENADE)|(1<<CSW_FLASHBANG)|(1<<CSW_SMOKEGRENADE)|(1<<CSW_C4)
const ZOMBIE_DEFAULT_ALLOWED_WEAPON = CSW_KNIFE

// CS Player PData Offsets (win32)
const OFFSET_CSMENUCODE = 205

// For class list menu handlers
#define MENU_PAGE_CLASS g_menu_data[id]
new g_menu_data[MAXPLAYERS+1]

enum _:TOTAL_FORWARDS
{
	FW_CLASS_SELECT_PRE = 0,
	FW_CLASS_SELECT_POST
}
new g_Forwards[TOTAL_FORWARDS]
new g_ForwardResult

new g_ZombieClassCount
new Array:g_ZombieClassRealName
new Array:g_ZombieClassName
new Array:g_ZombieClassDesc
new Array:g_ZombieClassHealth
new Array:g_ZombieClassSpeed
new Array:g_ZombieClassGravity
new Array:g_ZombieClassKnockbackFile
new Array:g_ZombieClassKnockback
new Array:g_ZombieClassModelsFile
new Array:g_ZombieClassModelsHandle
new Array:g_ZombieClassClawsFile
new Array:g_ZombieClassClawsHandle
new g_ZombieClass[MAXPLAYERS+1]
new g_ZombieClassNext[MAXPLAYERS+1]
new g_AdditionalMenuText[32]

public plugin_init()
{
	register_plugin("[ZP] Class: Zombie", ZP_VERSION_STRING, "ZP Dev Team")
	
	register_clcmd("say /zclass", "show_menu_zombieclass")
	register_clcmd("say /class", "show_class_menu")
	
	g_Forwards[FW_CLASS_SELECT_PRE] = CreateMultiForward("zp_fw_class_zombie_select_pre", ET_CONTINUE, FP_CELL, FP_CELL)
	g_Forwards[FW_CLASS_SELECT_POST] = CreateMultiForward("zp_fw_class_zombie_select_post", ET_CONTINUE, FP_CELL, FP_CELL)
}

public plugin_precache()
{
	new model_path[128]
	formatex(model_path, charsmax(model_path), "models/player/%s/%s.mdl", ZOMBIES_DEFAULT_MODEL, ZOMBIES_DEFAULT_MODEL)
	precache_model(model_path)
	// Support modelT.mdl files
	formatex(model_path, charsmax(model_path), "models/player/%s/%sT.mdl", ZOMBIES_DEFAULT_MODEL, ZOMBIES_DEFAULT_MODEL)
	if (file_exists(model_path)) precache_model(model_path)
	
	precache_model(ZOMBIES_DEFAULT_CLAWMODEL)
}

public plugin_cfg()
{
	// No classes loaded, add default zombie class
	if (g_ZombieClassCount < 1)
	{
		ArrayPushString(g_ZombieClassRealName, ZOMBIES_DEFAULT_NAME)
		ArrayPushString(g_ZombieClassName, ZOMBIES_DEFAULT_NAME)
		ArrayPushString(g_ZombieClassDesc, ZOMBIES_DEFAULT_DESCRIPTION)
		ArrayPushCell(g_ZombieClassHealth, ZOMBIES_DEFAULT_HEALTH)
		ArrayPushCell(g_ZombieClassSpeed, ZOMBIES_DEFAULT_SPEED)
		ArrayPushCell(g_ZombieClassGravity, ZOMBIES_DEFAULT_GRAVITY)
		ArrayPushCell(g_ZombieClassKnockbackFile, false)
		ArrayPushCell(g_ZombieClassKnockback, ZOMBIES_DEFAULT_KNOCKBACK)
		ArrayPushCell(g_ZombieClassModelsFile, false)
		ArrayPushCell(g_ZombieClassModelsHandle, Invalid_Array)
		ArrayPushCell(g_ZombieClassClawsFile, false)
		ArrayPushCell(g_ZombieClassClawsHandle, Invalid_Array)
		g_ZombieClassCount++
	}
}

public plugin_natives()
{
	register_library("zp50_class_zombie")
	register_native("zp_class_zombie_get_current", "native_class_zombie_get_current")
	register_native("zp_class_zombie_get_next", "native_class_zombie_get_next")
	register_native("zp_class_zombie_set_next", "native_class_zombie_set_next")
	register_native("zp_class_zombie_get_max_health", "_class_zombie_get_max_health")
	register_native("zp_class_zombie_register", "native_class_zombie_register")
	register_native("zp_class_zombie_register_model", "_class_zombie_register_model")
	register_native("zp_class_zombie_register_claw", "_class_zombie_register_claw")
	register_native("zp_class_zombie_register_kb", "native_class_zombie_register_kb")
	register_native("zp_class_zombie_get_id", "native_class_zombie_get_id")
	register_native("zp_class_zombie_get_name", "native_class_zombie_get_name")
	register_native("zp_class_zombie_get_real_name", "_class_zombie_get_real_name")
	register_native("zp_class_zombie_get_desc", "native_class_zombie_get_desc")
	register_native("zp_class_zombie_get_kb", "native_class_zombie_get_kb")
	register_native("zp_class_zombie_get_count", "native_class_zombie_get_count")
	register_native("zp_class_zombie_show_menu", "native_class_zombie_show_menu")
	register_native("zp_class_zombie_menu_text_add", "_class_zombie_menu_text_add")
	
	// Initialize dynamic arrays
	g_ZombieClassRealName = ArrayCreate(32, 1)
	g_ZombieClassName = ArrayCreate(32, 1)
	g_ZombieClassDesc = ArrayCreate(32, 1)
	g_ZombieClassHealth = ArrayCreate(1, 1)
	g_ZombieClassSpeed = ArrayCreate(1, 1)
	g_ZombieClassGravity = ArrayCreate(1, 1)
	g_ZombieClassKnockback = ArrayCreate(1, 1)
	g_ZombieClassKnockbackFile = ArrayCreate(1, 1)
	g_ZombieClassModelsHandle = ArrayCreate(1, 1)
	g_ZombieClassModelsFile = ArrayCreate(1, 1)
	g_ZombieClassClawsHandle = ArrayCreate(1, 1)
	g_ZombieClassClawsFile = ArrayCreate(1, 1)
}

public client_putinserver(id)
{
	g_ZombieClass[id] = ZP_INVALID_ZOMBIE_CLASS
	g_ZombieClassNext[id] = ZP_INVALID_ZOMBIE_CLASS
}

public client_disconnect(id)
{
	// Reset remembered menu pages
	MENU_PAGE_CLASS = 0
}

public show_class_menu(id)
{
	if (zp_core_is_zombie(id))
		show_menu_zombieclass(id)
}

public show_menu_zombieclass(id)
{
	static menu[128], name[32], description[32], transkey[64]
	new menuid, itemdata[2], index
	
	formatex(menu, charsmax(menu), "%L\r", id, "MENU_ZCLASS")
	menuid = menu_create(menu, "menu_zombieclass")
	
	for (index = 0; index < g_ZombieClassCount; index++)
	{
		// Additional text to display
		g_AdditionalMenuText[0] = 0
		
		// Execute class select attempt forward
		ExecuteForward(g_Forwards[FW_CLASS_SELECT_PRE], g_ForwardResult, id, index)
		
		// Show class to player?
		if (g_ForwardResult >= ZP_CLASS_DONT_SHOW)
			continue;
		
		ArrayGetString(g_ZombieClassName, index, name, charsmax(name))
		ArrayGetString(g_ZombieClassDesc, index, description, charsmax(description))
		
		// ML support for class name + description
		formatex(transkey, charsmax(transkey), "ZOMBIEDESC %s", name)
		if (GetLangTransKey(transkey) != TransKey_Bad) formatex(description, charsmax(description), "%L", id, transkey)
		formatex(transkey, charsmax(transkey), "ZOMBIENAME %s", name)
		if (GetLangTransKey(transkey) != TransKey_Bad) formatex(name, charsmax(name), "%L", id, transkey)
		
		// Class available to player?
		if (g_ForwardResult >= ZP_CLASS_NOT_AVAILABLE)
			formatex(menu, charsmax(menu), "\d%s %s %s", name, description, g_AdditionalMenuText)
		// Class is current class?
		else if (index == g_ZombieClassNext[id])
			formatex(menu, charsmax(menu), "\r%s \y%s \w%s", name, description, g_AdditionalMenuText)
		else
			formatex(menu, charsmax(menu), "%s \y%s \w%s", name, description, g_AdditionalMenuText)
		
		itemdata[0] = index
		itemdata[1] = 0
		menu_additem(menuid, menu, itemdata)
	}
	
	// No classes to display?
	if (menu_items(menuid) <= 0)
	{
		zp_colored_print(id, "%L", id, "NO_CLASSES")
		menu_destroy(menuid)
		return;
	}
	
	// Back - Next - Exit
	formatex(menu, charsmax(menu), "%L", id, "MENU_BACK")
	menu_setprop(menuid, MPROP_BACKNAME, menu)
	formatex(menu, charsmax(menu), "%L", id, "MENU_NEXT")
	menu_setprop(menuid, MPROP_NEXTNAME, menu)
	formatex(menu, charsmax(menu), "%L", id, "MENU_EXIT")
	menu_setprop(menuid, MPROP_EXITNAME, menu)
	
	// If remembered page is greater than number of pages, clamp down the value
	MENU_PAGE_CLASS = min(MENU_PAGE_CLASS, menu_pages(menuid)-1)
	
	// Fix for AMXX custom menus
	set_pdata_int(id, OFFSET_CSMENUCODE, 0)
	menu_display(id, menuid, MENU_PAGE_CLASS)
}

public menu_zombieclass(id, menuid, item)
{
	// Menu was closed
	if (item == MENU_EXIT)
	{
		MENU_PAGE_CLASS = 0
		menu_destroy(menuid)
		return PLUGIN_HANDLED;
	}
	
	// Remember class menu page
	MENU_PAGE_CLASS = item / 7
	
	// Retrieve class index
	new itemdata[2], dummy, index
	menu_item_getinfo(menuid, item, dummy, itemdata, charsmax(itemdata), _, _, dummy)
	index = itemdata[0]
	
	// Execute class select attempt forward
	ExecuteForward(g_Forwards[FW_CLASS_SELECT_PRE], g_ForwardResult, id, index)
	
	// Class available to player?
	if (g_ForwardResult >= ZP_CLASS_NOT_AVAILABLE)
	{
		menu_destroy(menuid)
		return PLUGIN_HANDLED;
	}
	
	// Make selected class next class for player
	g_ZombieClassNext[id] = index
	
	new name[32], transkey[64]
	new Float:maxspeed = Float:ArrayGetCell(g_ZombieClassSpeed, g_ZombieClassNext[id])
	ArrayGetString(g_ZombieClassName, g_ZombieClassNext[id], name, charsmax(name))
	// ML support for class name
	formatex(transkey, charsmax(transkey), "ZOMBIENAME %s", name)
	if (GetLangTransKey(transkey) != TransKey_Bad) formatex(name, charsmax(name), "%L", id, transkey)
	
	// Show selected zombie class
	zp_colored_print(id, "%L: %s", id, "ZOMBIE_SELECT", name)
	zp_colored_print(id, "%L: %d %L: %d %L: %.2fx %L %.2fx", id, "ZOMBIE_ATTRIB1", ArrayGetCell(g_ZombieClassHealth, g_ZombieClassNext[id]), id, "ZOMBIE_ATTRIB2", cs_maxspeed_display_value(maxspeed), id, "ZOMBIE_ATTRIB3", Float:ArrayGetCell(g_ZombieClassGravity, g_ZombieClassNext[id]), id, "ZOMBIE_ATTRIB4", Float:ArrayGetCell(g_ZombieClassKnockback, g_ZombieClassNext[id]))
	
	// Execute class select post forward
	ExecuteForward(g_Forwards[FW_CLASS_SELECT_POST], g_ForwardResult, id, index)
	
	menu_destroy(menuid)
	return PLUGIN_HANDLED;
}

public zp_fw_core_infect_post(id, attacker)
{
	// Show zombie class menu if they haven't chosen any (e.g. just connected)
	if (g_ZombieClassNext[id] == ZP_INVALID_ZOMBIE_CLASS)
	{
		if (g_ZombieClassCount > 1)
			show_menu_zombieclass(id)
		else // If only one class is registered, choose it automatically
			g_ZombieClassNext[id] = 0
	}
	
	// Bots pick class automatically
	if (is_user_bot(id))
	{
		// Try choosing class
		new index, start_index = random_num(0, g_ZombieClassCount - 1)
		for (index = start_index + 1; /* no condition */; index++)
		{
			// Start over when we reach the end
			if (index >= g_ZombieClassCount)
				index = 0
			
			// Execute class select attempt forward
			ExecuteForward(g_Forwards[FW_CLASS_SELECT_PRE], g_ForwardResult, id, index)
			
			// Class available to player?
			if (g_ForwardResult < ZP_CLASS_NOT_AVAILABLE)
			{
				g_ZombieClassNext[id] = index
				break;
			}
			
			// Loop completed, no class could be chosen
			if (index == start_index)
				break;
		}
	}
	
	// Set selected zombie class. If none selected yet, use the first one
	g_ZombieClass[id] = g_ZombieClassNext[id]
	if (g_ZombieClass[id] == ZP_INVALID_ZOMBIE_CLASS) g_ZombieClass[id] = 0
	
	// Apply zombie attributes
	set_user_health(id, ArrayGetCell(g_ZombieClassHealth, g_ZombieClass[id]))
	set_user_gravity(id, Float:ArrayGetCell(g_ZombieClassGravity, g_ZombieClass[id]))
	cs_set_player_maxspeed_auto(id, Float:ArrayGetCell(g_ZombieClassSpeed, g_ZombieClass[id]))
	
	// Apply zombie player model
	new Array:class_models = ArrayGetCell(g_ZombieClassModelsHandle, g_ZombieClass[id])
	if (class_models != Invalid_Array)
	{
		new index = random_num(0, ArraySize(class_models) - 1)
		new player_model[32]
		ArrayGetString(class_models, index, player_model, charsmax(player_model))
		cs_set_player_model(id, player_model)
	}
	else
	{
		// No models registered for current class, use default model
		cs_set_player_model(id, ZOMBIES_DEFAULT_MODEL)
	}
	
	// Apply zombie claw model
	new claw_model[64], Array:class_claws = ArrayGetCell(g_ZombieClassClawsHandle, g_ZombieClass[id])
	if (class_claws != Invalid_Array)
	{
		new index = random_num(0, ArraySize(class_claws) - 1)
		ArrayGetString(class_claws, index, claw_model, charsmax(claw_model))
		cs_set_player_view_model(id, CSW_KNIFE, claw_model)
	}
	else
	{
		// No models registered for current class, use default model
		cs_set_player_view_model(id, CSW_KNIFE, ZOMBIES_DEFAULT_CLAWMODEL)
	}
	cs_set_player_weap_model(id, CSW_KNIFE, "")
	
	// Apply weapon restrictions for zombies
	cs_set_player_weap_restrict(id, true, ZOMBIE_ALLOWED_WEAPONS_BITSUM, ZOMBIE_DEFAULT_ALLOWED_WEAPON)
}

public zp_fw_core_cure(id, attacker)
{
	// Remove zombie claw models
	cs_reset_player_view_model(id, CSW_KNIFE)
	cs_reset_player_weap_model(id, CSW_KNIFE)
	
	// Remove zombie weapon restrictions
	cs_set_player_weap_restrict(id, false)
}

public native_class_zombie_get_current(plugin_id, num_params)
{
	new id = get_param(1)
	
	if (!is_user_connected(id))
	{
		log_error(AMX_ERR_NATIVE, "[ZP] Invalid Player (%d)", id)
		return ZP_INVALID_ZOMBIE_CLASS;
	}
	
	return g_ZombieClass[id];
}

public native_class_zombie_get_next(plugin_id, num_params)
{
	new id = get_param(1)
	
	if (!is_user_connected(id))
	{
		log_error(AMX_ERR_NATIVE, "[ZP] Invalid Player (%d)", id)
		return ZP_INVALID_ZOMBIE_CLASS;
	}
	
	return g_ZombieClassNext[id];
}

public native_class_zombie_set_next(plugin_id, num_params)
{
	new id = get_param(1)
	
	if (!is_user_connected(id))
	{
		log_error(AMX_ERR_NATIVE, "[ZP] Invalid Player (%d)", id)
		return false;
	}
	
	new classid = get_param(2)
	
	if (classid < 0 || classid >= g_ZombieClassCount)
	{
		log_error(AMX_ERR_NATIVE, "[ZP] Invalid zombie class id (%d)", classid)
		return false;
	}
	
	g_ZombieClassNext[id] = classid
	return true;
}

public _class_zombie_get_max_health(plugin_id, num_params)
{
	new id = get_param(1)
	
	if (!is_user_connected(id))
	{
		log_error(AMX_ERR_NATIVE, "[ZP] Invalid Player (%d)", id)
		return -1;
	}
	
	new classid = get_param(2)
	
	if (classid < 0 || classid >= g_ZombieClassCount)
	{
		log_error(AMX_ERR_NATIVE, "[ZP] Invalid zombie class id (%d)", classid)
		return -1;
	}
	
	return ArrayGetCell(g_ZombieClassHealth, classid);
}

public native_class_zombie_register(plugin_id, num_params)
{
	new name[32]
	get_string(1, name, charsmax(name))
	
	if (strlen(name) < 1)
	{
		log_error(AMX_ERR_NATIVE, "[ZP] Can't register zombie class with an empty name")
		return ZP_INVALID_ZOMBIE_CLASS;
	}
	
	new index, zombieclass_name[32]
	for (index = 0; index < g_ZombieClassCount; index++)
	{
		ArrayGetString(g_ZombieClassRealName, index, zombieclass_name, charsmax(zombieclass_name))
		if (equali(name, zombieclass_name))
		{
			log_error(AMX_ERR_NATIVE, "[ZP] Zombie class already registered (%s)", name)
			return ZP_INVALID_ZOMBIE_CLASS;
		}
	}
	
	new description[32]
	get_string(2, description, charsmax(description))
	new health = get_param(3)
	new Float:speed = get_param_f(4)
	new Float:gravity = get_param_f(5)
	
	// Load settings from zombie classes file
	new real_name[32]
	copy(real_name, charsmax(real_name), name)
	ArrayPushString(g_ZombieClassRealName, real_name)
	
	// Name
	if (!amx_load_setting_string(ZP_ZOMBIECLASSES_FILE, real_name, "NAME", name, charsmax(name)))
		amx_save_setting_string(ZP_ZOMBIECLASSES_FILE, real_name, "NAME", name)
	ArrayPushString(g_ZombieClassName, name)
	
	// Description
	if (!amx_load_setting_string(ZP_ZOMBIECLASSES_FILE, real_name, "INFO", description, charsmax(description)))
		amx_save_setting_string(ZP_ZOMBIECLASSES_FILE, real_name, "INFO", description)
	ArrayPushString(g_ZombieClassDesc, description)
	
	// Models
	new Array:class_models = ArrayCreate(32, 1)
	amx_load_setting_string_arr(ZP_ZOMBIECLASSES_FILE, real_name, "MODELS", class_models)
	if (ArraySize(class_models) > 0)
	{
		ArrayPushCell(g_ZombieClassModelsFile, true)
		
		// Precache player models
		new index, player_model[32], model_path[128]
		for (index = 0; index < ArraySize(class_models); index++)
		{
			ArrayGetString(class_models, index, player_model, charsmax(player_model))
			formatex(model_path, charsmax(model_path), "models/player/%s/%s.mdl", player_model, player_model)
			precache_model(model_path)
			// Support modelT.mdl files
			formatex(model_path, charsmax(model_path), "models/player/%s/%sT.mdl", player_model, player_model)
			if (file_exists(model_path)) precache_model(model_path)
		}
	}
	else
	{
		ArrayPushCell(g_ZombieClassModelsFile, false)
		ArrayDestroy(class_models)
		amx_save_setting_string(ZP_ZOMBIECLASSES_FILE, real_name, "MODELS", ZOMBIES_DEFAULT_MODEL)
	}
	ArrayPushCell(g_ZombieClassModelsHandle, class_models)
	
	// Claw models
	new Array:class_claws = ArrayCreate(64, 1)
	amx_load_setting_string_arr(ZP_ZOMBIECLASSES_FILE, real_name, "CLAWMODEL", class_claws)
	if (ArraySize(class_claws) > 0)
	{
		ArrayPushCell(g_ZombieClassClawsFile, true)
		
		// Precache claw models
		new index, claw_model[64]
		for (index = 0; index < ArraySize(class_claws); index++)
		{
			ArrayGetString(class_claws, index, claw_model, charsmax(claw_model))
			precache_model(claw_model)
		}
	}
	else
	{
		ArrayPushCell(g_ZombieClassClawsFile, false)
		ArrayDestroy(class_claws)
		amx_save_setting_string(ZP_ZOMBIECLASSES_FILE, real_name, "CLAWMODEL", ZOMBIES_DEFAULT_CLAWMODEL)
	}
	ArrayPushCell(g_ZombieClassClawsHandle, class_claws)
	
	// Health
	if (!amx_load_setting_int(ZP_ZOMBIECLASSES_FILE, real_name, "HEALTH", health))
		amx_save_setting_int(ZP_ZOMBIECLASSES_FILE, real_name, "HEALTH", health)
	ArrayPushCell(g_ZombieClassHealth, health)
	
	// Speed
	if (!amx_load_setting_float(ZP_ZOMBIECLASSES_FILE, real_name, "SPEED", speed))
		amx_save_setting_float(ZP_ZOMBIECLASSES_FILE, real_name, "SPEED", speed)
	ArrayPushCell(g_ZombieClassSpeed, speed)
	
	// Gravity
	if (!amx_load_setting_float(ZP_ZOMBIECLASSES_FILE, real_name, "GRAVITY", gravity))
		amx_save_setting_float(ZP_ZOMBIECLASSES_FILE, real_name, "GRAVITY", gravity)
	ArrayPushCell(g_ZombieClassGravity, gravity)
	
	// Knockback
	new Float:knockback = ZOMBIES_DEFAULT_KNOCKBACK
	if (!amx_load_setting_float(ZP_ZOMBIECLASSES_FILE, real_name, "KNOCKBACK", knockback))
	{
		ArrayPushCell(g_ZombieClassKnockbackFile, false)
		amx_save_setting_float(ZP_ZOMBIECLASSES_FILE, real_name, "KNOCKBACK", knockback)
	}
	else
		ArrayPushCell(g_ZombieClassKnockbackFile, true)
	ArrayPushCell(g_ZombieClassKnockback, knockback)
	
	g_ZombieClassCount++
	return g_ZombieClassCount - 1;
}

public _class_zombie_register_model(plugin_id, num_params)
{
	new classid = get_param(1)
	
	if (classid < 0 || classid >= g_ZombieClassCount)
	{
		log_error(AMX_ERR_NATIVE, "[ZP] Invalid zombie class id (%d)", classid)
		return false;
	}
	
	// Player models already loaded from file
	if (ArrayGetCell(g_ZombieClassModelsFile, classid))
		return true;
	
	new player_model[32]
	get_string(2, player_model, charsmax(player_model))
	
	new model_path[128]
	formatex(model_path, charsmax(model_path), "models/player/%s/%s.mdl", player_model, player_model)
	
	precache_model(model_path)
	
	// Support modelT.mdl files
	formatex(model_path, charsmax(model_path), "models/player/%s/%sT.mdl", player_model, player_model)
	if (file_exists(model_path)) precache_model(model_path)
	
	new Array:class_models = ArrayGetCell(g_ZombieClassModelsHandle, classid)
	
	// No models registered yet?
	if (class_models == Invalid_Array)
	{
		class_models = ArrayCreate(32, 1)
		ArraySetCell(g_ZombieClassModelsHandle, classid, class_models)
	}
	ArrayPushString(class_models, player_model)
	
	// Save models to file
	new real_name[32]
	ArrayGetString(g_ZombieClassRealName, classid, real_name, charsmax(real_name))
	amx_save_setting_string_arr(ZP_ZOMBIECLASSES_FILE, real_name, "MODELS", class_models)
	
	return true;
}

public _class_zombie_register_claw(plugin_id, num_params)
{
	new classid = get_param(1)
	
	if (classid < 0 || classid >= g_ZombieClassCount)
	{
		log_error(AMX_ERR_NATIVE, "[ZP] Invalid zombie class id (%d)", classid)
		return false;
	}
	
	// Claw models already loaded from file
	if (ArrayGetCell(g_ZombieClassClawsFile, classid))
		return true;
	
	new claw_model[64]
	get_string(2, claw_model, charsmax(claw_model))
	
	precache_model(claw_model)
	
	new Array:class_claws = ArrayGetCell(g_ZombieClassClawsHandle, classid)
	
	// No models registered yet?
	if (class_claws == Invalid_Array)
	{
		class_claws = ArrayCreate(64, 1)
		ArraySetCell(g_ZombieClassClawsHandle, classid, class_claws)
	}
	ArrayPushString(class_claws, claw_model)
	
	// Save models to file
	new real_name[32]
	ArrayGetString(g_ZombieClassRealName, classid, real_name, charsmax(real_name))
	amx_save_setting_string_arr(ZP_ZOMBIECLASSES_FILE, real_name, "CLAWMODEL", class_claws)
	
	return true;
}

public native_class_zombie_register_kb(plugin_id, num_params)
{
	new classid = get_param(1)
	
	if (classid < 0 || classid >= g_ZombieClassCount)
	{
		log_error(AMX_ERR_NATIVE, "[ZP] Invalid zombie class id (%d)", classid)
		return false;
	}
	
	// Knockback already loaded from file
	if (ArrayGetCell(g_ZombieClassKnockbackFile, classid))
		return true;
	
	new Float:knockback = get_param_f(2)
	
	// Set zombie class knockback
	ArraySetCell(g_ZombieClassKnockback, classid, knockback)
	
	// Save to file
	new real_name[32]
	ArrayGetString(g_ZombieClassRealName, classid, real_name, charsmax(real_name))
	amx_save_setting_float(ZP_ZOMBIECLASSES_FILE, real_name, "KNOCKBACK", knockback)
	
	return true;
}

public native_class_zombie_get_id(plugin_id, num_params)
{
	new real_name[32]
	get_string(1, real_name, charsmax(real_name))
	
	// Loop through every class
	new index, zombieclass_name[32]
	for (index = 0; index < g_ZombieClassCount; index++)
	{
		ArrayGetString(g_ZombieClassRealName, index, zombieclass_name, charsmax(zombieclass_name))
		if (equali(real_name, zombieclass_name))
			return index;
	}
	
	return ZP_INVALID_ZOMBIE_CLASS;
}

public native_class_zombie_get_name(plugin_id, num_params)
{
	new classid = get_param(1)
	
	if (classid < 0 || classid >= g_ZombieClassCount)
	{
		log_error(AMX_ERR_NATIVE, "[ZP] Invalid zombie class id (%d)", classid)
		return false;
	}
	
	new name[32]
	ArrayGetString(g_ZombieClassName, classid, name, charsmax(name))
	
	new len = get_param(3)
	set_string(2, name, len)
	return true;
}


public _class_zombie_get_real_name(plugin_id, num_params)
{
	new classid = get_param(1)
	
	if (classid < 0 || classid >= g_ZombieClassCount)
	{
		log_error(AMX_ERR_NATIVE, "[ZP] Invalid zombie class id (%d)", classid)
		return false;
	}
	
	new real_name[32]
	ArrayGetString(g_ZombieClassRealName, classid, real_name, charsmax(real_name))
	
	new len = get_param(3)
	set_string(2, real_name, len)
	return true;
}

public native_class_zombie_get_desc(plugin_id, num_params)
{
	new classid = get_param(1)
	
	if (classid < 0 || classid >= g_ZombieClassCount)
	{
		log_error(AMX_ERR_NATIVE, "[ZP] Invalid zombie class id (%d)", classid)
		return false;
	}
	
	new description[32]
	ArrayGetString(g_ZombieClassDesc, classid, description, charsmax(description))
	
	new len = get_param(3)
	set_string(2, description, len)
	return true;
}

public Float:native_class_zombie_get_kb(plugin_id, num_params)
{
	new classid = get_param(1)
	
	if (classid < 0 || classid >= g_ZombieClassCount)
	{
		log_error(AMX_ERR_NATIVE, "[ZP] Invalid zombie class id (%d)", classid)
		return ZOMBIES_DEFAULT_KNOCKBACK;
	}
	
	// Return zombie class knockback)
	return ArrayGetCell(g_ZombieClassKnockback, classid);
}

public native_class_zombie_get_count(plugin_id, num_params)
{
	return g_ZombieClassCount;
}

public native_class_zombie_show_menu(plugin_id, num_params)
{
	new id = get_param(1)
	
	if (!is_user_connected(id))
	{
		log_error(AMX_ERR_NATIVE, "[ZP] Invalid Player (%d)", id)
		return false;
	}
	
	show_menu_zombieclass(id)
	return true;
}

public _class_zombie_menu_text_add(plugin_id, num_params)
{
	static text[32]
	get_string(1, text, charsmax(text))
	format(g_AdditionalMenuText, charsmax(g_AdditionalMenuText), "%s%s", g_AdditionalMenuText, text)
}