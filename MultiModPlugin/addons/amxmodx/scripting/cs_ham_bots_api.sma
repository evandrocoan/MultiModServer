/*================================================================================
	
	------------------------------------------
	-*- [CS] Ham Hooks for CZ Bots API 1.0 -*-
	------------------------------------------
	
	- Fixes RegisterHam player hooks not working for CZ bots
	
================================================================================*/

#include <amxmodx>
#include <hamsandwich>

#define INVALID_HANDLE -1
#define REGISTERHAM_CALLBACK "__RegisterHamBots"

new g_HamsNotRegistered
new g_CZBotPlayerID
new g_MaxPlayers
new cvar_bot_quota

new Array:g_PluginID
new Array:g_PluginCallback
new Array:g_HamFunctionID
new Array:g_HamFunctionIsPost
new Array:g_HamForwardHandle
new Array:g_HamForwardEnable
new g_BotHooksCount

public plugin_precache()
{
	// Initialize dynamic arrays
	g_PluginID = ArrayCreate(1, 1)
	g_PluginCallback = ArrayCreate(64, 1)
	g_HamFunctionID = ArrayCreate(1, 1)
	g_HamFunctionIsPost = ArrayCreate(1, 1)
	g_HamForwardHandle = ArrayCreate(1, 1)
	g_HamForwardEnable = ArrayCreate(1, 1)
}

public plugin_init()
{
	register_plugin("[CS] Ham Hooks for Bots API", "1.0", "WiLS")
	
	g_MaxPlayers = get_maxplayers()
	cvar_bot_quota = get_cvar_pointer("bot_quota")
}

public plugin_natives()
{
	register_library("cs_ham_bots_api")
	register_native("RegisterHamBots", "native_register_ham_bots")
	register_native("DisableHamForwardBots", "native_disable_ham_forward_bots")
	register_native("EnableHamForwardBots", "native_enable_ham_forward_bots")
}

public native_register_ham_bots(plugin_id, num_params)
{
	new ham_function_id = get_param(1)
	
	if (!IsHamValid(Ham:ham_function_id))
	{
		log_error(AMX_ERR_NATIVE, "[HAM] Invalid Function ID (%d).", ham_function_id)
		return -1;
	}
	
	new plugin_callback[64]
	get_string(2, plugin_callback, charsmax(plugin_callback))
	
	if (get_func_id(plugin_callback, plugin_id) < 0)
	{
		log_error(AMX_ERR_NATIVE, "[HAM] Function %s not found.", plugin_callback)
		return -1;
	}
	
	new is_post = get_param(3) ? true : false
	
	ArrayPushCell(g_PluginID, plugin_id)
	ArrayPushString(g_PluginCallback, plugin_callback)
	ArrayPushCell(g_HamFunctionID, ham_function_id)
	ArrayPushCell(g_HamFunctionIsPost, is_post)
	ArrayPushCell(g_HamForwardHandle, INVALID_HANDLE)
	ArrayPushCell(g_HamForwardEnable, true)
	g_BotHooksCount++
	
	// Reset flags
	g_HamsNotRegistered = true
	
	// Is there a CZ Bot connected?
	if (g_CZBotPlayerID)
	{
		// Use it to register right away
		register_ham_czbots(g_CZBotPlayerID)
	}
	
	return g_BotHooksCount - 1;
}

public native_disable_ham_forward_bots(plugin_id, num_params)
{
	new ham_hook_index = get_param(1)
	
	if (ham_hook_index < 0 || ham_hook_index > g_BotHooksCount - 1)
	{
		log_error(AMX_ERR_NATIVE, "[HAM] Invalid hook index (%d).", ham_hook_index)
		return false;
	}
	
	// Hook is already disabled
	if (!ArrayGetCell(g_HamForwardEnable, ham_hook_index))
		return true;
	
	// Is this forward already registered?
	if (ArrayGetCell(g_HamForwardHandle, ham_hook_index) != INVALID_HANDLE)
	{
		// We have the forward handle, disable right away
		new ham_forward_handle = ArrayGetCell(g_HamForwardHandle, ham_hook_index)
		DisableHamForward(HamHook:ham_forward_handle)
	}
	
	// If we don't have a forward handle, disable it once it's registered
	ArraySetCell(g_HamForwardEnable, ham_hook_index, false)
	return true;
}

public native_enable_ham_forward_bots(plugin_id, num_params)
{
	new ham_hook_index = get_param(1)
	
	if (ham_hook_index < 0 || ham_hook_index > g_BotHooksCount - 1)
	{
		log_error(AMX_ERR_NATIVE, "[HAM] Invalid hook index (%d).", ham_hook_index)
		return false;
	}
	
	// Hook is already enabled
	if (ArrayGetCell(g_HamForwardEnable, ham_hook_index))
		return true;
	
	// Is this forward already registered?
	if (ArrayGetCell(g_HamForwardHandle, ham_hook_index) != INVALID_HANDLE)
	{
		// We have the forward handle, enable right away
		new ham_forward_handle = ArrayGetCell(g_HamForwardHandle, ham_hook_index)
		EnableHamForward(HamHook:ham_forward_handle)
	}
	
	// If we don't have a forward handle, enable it once it's registered
	ArraySetCell(g_HamForwardEnable, ham_hook_index, true)
	return true;
}

public client_disconnect(id_leaving)
{
	// Our CZ Bot used for registering hooks is leaving
	if (id_leaving == g_CZBotPlayerID)
	{
		// Can we find a replacement?
		new index = 1
		while ((!is_user_connected(index) || !is_user_bot(index) || index == id_leaving) && (index <= g_MaxPlayers))
			index++ // keep looping
		
		// Update player ID
		if (index <= g_MaxPlayers)
			g_CZBotPlayerID = index
		else
			g_CZBotPlayerID = 0
	}
}

public client_putinserver(id)
{
	// CZ bots seem to use a different "classtype" for player entities
	// (or something like that) which needs to be hooked separately
	if (is_user_bot(id) && cvar_bot_quota)
	{
		// Set a task to let the private data initialize
		set_task(0.1, "register_ham_czbots", id)
	}
}

// Register Ham Forwards for CZ bots
public register_ham_czbots(id_bot)
{
	// Make sure it's a CZ bot and it's still connected
	if (!is_user_connected(id_bot) || !get_pcvar_num(cvar_bot_quota))
		return;
	
	// Save CZ Bot Player ID in case we need to register any more forwards later
	g_CZBotPlayerID = id_bot
	
	// Nothing to hook?
	if (!g_HamsNotRegistered)
		return;
	
	new index, plugin_id, plugin_filename[64], ham_function_id, plugin_callback[64], is_post, func_id, ham_forward_handle, plugin_is_paused
	for (index = 0; index < g_BotHooksCount; index++)
	{
		// Already registered
		if (ArrayGetCell(g_HamForwardHandle, index) != INVALID_HANDLE)
			continue;
		
		plugin_id = ArrayGetCell(g_PluginID, index)
		ham_function_id = ArrayGetCell(g_HamFunctionID, index)
		ArrayGetString(g_PluginCallback, index, plugin_callback, charsmax(plugin_callback))
		is_post = ArrayGetCell(g_HamFunctionIsPost, index)
		func_id = get_func_id(REGISTERHAM_CALLBACK, plugin_id)
		plugin_is_paused = (callfunc_begin_i(func_id, plugin_id) == -2) ? true : false // -2 = Function not executable
		
		if (plugin_is_paused)
		{
			// Unpause plugin before callfunc
			get_plugin(plugin_id, plugin_filename, charsmax(plugin_filename))
			unpause("c", plugin_filename, REGISTERHAM_CALLBACK) //unpause("ac", plugin_filename)
			
			if (callfunc_begin_i(func_id, plugin_id) == -2)
			{
				pause("c", plugin_filename, REGISTERHAM_CALLBACK) //pause("ac", plugin_filename)
				log_amx("ERROR: callfunc_begin_i: Function still not executable after unpausing - plugin id %d (%s) - func id %d (%s)", plugin_id, plugin_filename, func_id, REGISTERHAM_CALLBACK)
				continue;
			}
		}
		
		callfunc_push_int(ham_function_id)
		callfunc_push_int(id_bot)
		callfunc_push_str(plugin_callback)
		callfunc_push_int(is_post)
		ham_forward_handle = callfunc_end()
		
		if (plugin_is_paused)
		{
			// Pause plugin again after callfunc
			pause("c", plugin_filename, REGISTERHAM_CALLBACK) //pause("ac", plugin_filename)
		}
		
		ArraySetCell(g_HamForwardHandle, index, ham_forward_handle)
		
		// Ham forward was disabled
		if (!ArrayGetCell(g_HamForwardEnable, index))
		{
			DisableHamForward(HamHook:ham_forward_handle)
		}
		else if (ham_function_id == _:Ham_Spawn && is_user_alive(id_bot) && !plugin_is_paused)
		{
			// If the bot has already spawned, call Ham_Spawn forward manually for him (bugfix)
			func_id = get_func_id(plugin_callback, plugin_id)
			callfunc_begin_i(func_id, plugin_id)
			callfunc_push_int(id_bot)
			callfunc_end()
		}
	}
	
	// Ham forwards for CZ bots succesfully registered
	g_HamsNotRegistered = false
}