/*================================================================================
	
	-------------------------
	-*- [ZP] Admin Models -*-
	-------------------------
	
	This plugin is part of Zombie Plague Mod and is distributed under the
	terms of the GNU General Public License. Check ZP_ReadMe.txt for details.
	
================================================================================*/

#include <amxmodx>
#include <amx_settings_api>
#include <cs_player_models_api>
#include <cs_weap_models_api>
#include <zp50_core>
#define LIBRARY_NEMESIS "zp50_class_nemesis"
#include <zp50_class_nemesis>
#define LIBRARY_SURVIVOR "zp50_class_survivor"
#include <zp50_class_survivor>

// Settings file
new const ZP_SETTINGS_FILE[] = "zombieplague.ini"

// Default models
new const models_admin_human_player[][] = { "vip" }
new const models_admin_human_knife[][] = { "models/v_knife.mdl" }
new const models_admin_zombie_player[][] = { "zombie_source" }
new const models_admin_zombie_claw[][] = { "models/zombie_plague/v_knife_zombie.mdl" }

#define PLAYERMODEL_MAX_LENGTH 32
#define MODEL_MAX_LENGTH 64
#define ACCESSFLAG_MAX_LENGTH 2

// Access flags
new g_access_admin_models[ACCESSFLAG_MAX_LENGTH] = "d"

// Custom models
new Array:g_models_admin_human_player
new Array:g_models_admin_human_knife
new Array:g_models_admin_zombie_player
new Array:g_models_admin_zombie_claw

new cvar_admin_models_human_player, cvar_admin_models_human_knife
new cvar_admin_models_zombie_player, cvar_admin_models_zombie_knife

public plugin_init()
{
	register_plugin("[ZP] Admin Models", ZP_VERSION_STRING, "ZP Dev Team")
	
	cvar_admin_models_human_player = register_cvar("zp_admin_models_human_player", "1")
	cvar_admin_models_human_knife = register_cvar("zp_admin_models_human_knife", "1")
	cvar_admin_models_zombie_player = register_cvar("zp_admin_models_zombie_player", "1")
	cvar_admin_models_zombie_knife = register_cvar("zp_admin_models_zombie_knife", "1")
}

public plugin_precache()
{
	// Initialize arrays
	g_models_admin_human_player = ArrayCreate(PLAYERMODEL_MAX_LENGTH, 1)
	g_models_admin_human_knife = ArrayCreate(MODEL_MAX_LENGTH, 1)
	g_models_admin_zombie_player = ArrayCreate(PLAYERMODEL_MAX_LENGTH, 1)
	g_models_admin_zombie_claw = ArrayCreate(MODEL_MAX_LENGTH, 1)
	
	// Load from external file
	amx_load_setting_string_arr(ZP_SETTINGS_FILE, "Player Models", "ADMIN HUMAN", g_models_admin_human_player)
	amx_load_setting_string_arr(ZP_SETTINGS_FILE, "Weapon Models", "V_KNIFE ADMIN HUMAN", g_models_admin_human_knife)
	amx_load_setting_string_arr(ZP_SETTINGS_FILE, "Player Models", "ADMIN ZOMBIE", g_models_admin_zombie_player)
	amx_load_setting_string_arr(ZP_SETTINGS_FILE, "Weapon Models", "V_KNIFE ADMIN ZOMBIE", g_models_admin_zombie_claw)
	
	// If we couldn't load from file, use and save default ones
	new index
	if (ArraySize(g_models_admin_human_player) == 0)
	{
		for (index = 0; index < sizeof models_admin_human_player; index++)
			ArrayPushString(g_models_admin_human_player, models_admin_human_player[index])
		
		// Save to external file
		amx_save_setting_string_arr(ZP_SETTINGS_FILE, "Player Models", "ADMIN HUMAN", g_models_admin_human_player)
	}
	if (ArraySize(g_models_admin_human_knife) == 0)
	{
		for (index = 0; index < sizeof models_admin_human_knife; index++)
			ArrayPushString(g_models_admin_human_knife, models_admin_human_knife[index])
		
		// Save to external file
		amx_save_setting_string_arr(ZP_SETTINGS_FILE, "Weapon Models", "V_KNIFE ADMIN HUMAN", g_models_admin_human_knife)
	}
	if (ArraySize(g_models_admin_zombie_player) == 0)
	{
		for (index = 0; index < sizeof models_admin_zombie_player; index++)
			ArrayPushString(g_models_admin_zombie_player, models_admin_zombie_player[index])
		
		// Save to external file
		amx_save_setting_string_arr(ZP_SETTINGS_FILE, "Player Models", "ADMIN ZOMBIE", g_models_admin_zombie_player)
	}
	if (ArraySize(g_models_admin_zombie_claw) == 0)
	{
		for (index = 0; index < sizeof models_admin_zombie_claw; index++)
			ArrayPushString(g_models_admin_zombie_claw, models_admin_zombie_claw[index])
		
		// Save to external file
		amx_save_setting_string_arr(ZP_SETTINGS_FILE, "Weapon Models", "V_KNIFE ADMIN ZOMBIE", g_models_admin_zombie_claw)
	}
	
	// Load from external file, save if not found
	if (!amx_load_setting_string(ZP_SETTINGS_FILE, "Access Flags", "ADMIN MODELS", g_access_admin_models, charsmax(g_access_admin_models)))
		amx_save_setting_string(ZP_SETTINGS_FILE, "Access Flags", "ADMIN MODELS", g_access_admin_models)
	
	// Precache models
	new player_model[PLAYERMODEL_MAX_LENGTH], model[MODEL_MAX_LENGTH], model_path[128]
	for (index = 0; index < ArraySize(g_models_admin_human_player); index++)
	{
		ArrayGetString(g_models_admin_human_player, index, player_model, charsmax(player_model))
		formatex(model_path, charsmax(model_path), "models/player/%s/%s.mdl", player_model, player_model)
		precache_model(model_path)
		// Support modelT.mdl files
		formatex(model_path, charsmax(model_path), "models/player/%s/%sT.mdl", player_model, player_model)
		if (file_exists(model_path)) precache_model(model_path)
	}
	for (index = 0; index < ArraySize(g_models_admin_human_knife); index++)
	{
		ArrayGetString(g_models_admin_human_knife, index, model, charsmax(model))
		precache_model(model)
	}
	for (index = 0; index < ArraySize(g_models_admin_zombie_player); index++)
	{
		ArrayGetString(g_models_admin_zombie_player, index, player_model, charsmax(player_model))
		formatex(model_path, charsmax(model_path), "models/player/%s/%s.mdl", player_model, player_model)
		precache_model(model_path)
		// Support modelT.mdl files
		formatex(model_path, charsmax(model_path), "models/player/%s/%sT.mdl", player_model, player_model)
		if (file_exists(model_path)) precache_model(model_path)
	}
	for (index = 0; index < ArraySize(g_models_admin_zombie_claw); index++)
	{
		ArrayGetString(g_models_admin_zombie_claw, index, model, charsmax(model))
		precache_model(model)
	}
}

public plugin_natives()
{
	set_module_filter("module_filter")
	set_native_filter("native_filter")
}
public module_filter(const module[])
{
	if (equal(module, LIBRARY_NEMESIS) || equal(module, LIBRARY_SURVIVOR))
		return PLUGIN_HANDLED;
	
	return PLUGIN_CONTINUE;
}
public native_filter(const name[], index, trap)
{
	if (!trap)
		return PLUGIN_HANDLED;
		
	return PLUGIN_CONTINUE;
}

public zp_fw_core_infect_post(id, attacker)
{
	// Skip if player doesn't have required admin flags
	if (!(get_user_flags(id) & read_flags(g_access_admin_models)))
		return;
	
	// Skip for Nemesis
	if (LibraryExists(LIBRARY_NEMESIS, LibType_Library) && zp_class_nemesis_get(id))
		return;
	
	// Apply admin zombie player model?
	if (get_pcvar_num(cvar_admin_models_zombie_player))
	{
		new player_model[PLAYERMODEL_MAX_LENGTH]
		ArrayGetString(g_models_admin_zombie_player, random_num(0, ArraySize(g_models_admin_zombie_player) - 1), player_model, charsmax(player_model))
		cs_set_player_model(id, player_model)
	}
	
	// Apply admin zombie claw model?
	if (get_pcvar_num(cvar_admin_models_zombie_knife))
	{
		new model[MODEL_MAX_LENGTH]
		ArrayGetString(g_models_admin_zombie_claw, random_num(0, ArraySize(g_models_admin_zombie_claw) - 1), model, charsmax(model))
		cs_set_player_view_model(id, CSW_KNIFE, model)
	}
}

public zp_fw_core_cure_post(id, attacker)
{
	// Skip if player doesn't have required admin flags
	if (!(get_user_flags(id) & read_flags(g_access_admin_models)))
		return;
	
	// Skip for Survivor
	if (LibraryExists(LIBRARY_SURVIVOR, LibType_Library) && zp_class_survivor_get(id))
		return;
	
	// Apply admin human player model?
	if (get_pcvar_num(cvar_admin_models_human_player))
	{
		new player_model[PLAYERMODEL_MAX_LENGTH]
		ArrayGetString(g_models_admin_human_player, random_num(0, ArraySize(g_models_admin_human_player) - 1), player_model, charsmax(player_model))
		cs_set_player_model(id, player_model)
	}
	
	// Apply admin human knife model?
	if (get_pcvar_num(cvar_admin_models_human_knife))
	{
		new model[MODEL_MAX_LENGTH]
		ArrayGetString(g_models_admin_human_knife, random_num(0, ArraySize(g_models_admin_human_knife) - 1), model, charsmax(model))
		cs_set_player_view_model(id, CSW_KNIFE, model)
	}
}
