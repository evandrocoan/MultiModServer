/**
 * csdm_ffa.sma
 * Allows for Counter-Strike to be played as DeathMatch.
 *
 * CSDM FFA - Sets free-for-all mode on other plugins.
 *
 * (C)2003-2006 David "BAILOPAN" Anderson
 *
 *  Give credit where due.
 *  Share the source - it sets you free
 *  http://www.opensource.org/
 *  http://www.gnu.org/
 */
 
#include <amxmodx>
#include <amxmisc>
#include <csdm>
#pragma library csdm_main

new PLUGIN[]	= "CSDM Main"
new VERSION[]	= CSDM_VERSION
new AUTHOR[]	= "CSDM Team"
new ACCESS		= ADMIN_MAP

new bool:g_MainPlugin = true

public plugin_natives()
{
	set_module_filter("module_filter")
	set_native_filter("native_filter")
}

public module_filter(const module[])
{
	if (equali(module, "csdm_main"))
		return PLUGIN_HANDLED
	
	return PLUGIN_CONTINUE
}

public native_filter(const name[], index, trap)
{
	if (!trap)
		return PLUGIN_HANDLED
		
	return PLUGIN_CONTINUE
}

public csdm_Init(const version[])
{
	if (version[0] == 0)
	{
		set_fail_state("CSDM failed to load.")
		return
	}
}

public csdm_CfgInit()
{	
	csdm_reg_cfg("ffa", "read_cfg")
}

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	
	register_concmd("csdm_ffa_enable", "csdm_ffa_enable", ACCESS, "Enables FFA Mode")
	register_concmd("csdm_ffa_disable", "csdm_ffa_disable", ACCESS, "Disables FFA Mode")
	register_concmd("csdm_ffa_ctrl", "csdm_ffa_ctrl", ACCESS, "FFA Toggling")
	
	g_MainPlugin = module_exists("csdm_main") ? true : false
	
	if (g_MainPlugin)
	{
		new menu = csdm_main_menu()
		
		new callback = menu_makecallback("hook_item_display")
		menu_additem(menu, "Enable/Disable FFA", "csdm_ffa_ctrl", ADMIN_MAP, callback)
	}
	
	set_task(4.0, "enforce_ffa")
	
	register_message(get_user_msgid("Radar"), "Radar_Hook")
}

public Radar_Hook(msg_id, msg_dest, msg_entity)
{
	if (csdm_get_ffa())
	{
		return PLUGIN_HANDLED
	}
	
	return PLUGIN_CONTINUE
}

public enforce_ffa()
{
	//enforce this
	if (csdm_get_ffa())
	{
		set_cvar_num("mp_friendlyfire", 1)
	}
}

public csdm_ffa_ctrl(id, level, cid)
{
	if (!cmd_access(id, level, cid, 1))
		return PLUGIN_HANDLED
	
	csdm_set_ffa( csdm_get_ffa() ? 0 : 1 )
	client_print(id, print_chat, "[CSDM] CSDM FFA mode changed.")
	
	return PLUGIN_HANDLED
}

public hook_item_display(player, menu, item)
{
	new paccess, command[24], call
	
	menu_item_getinfo(menu, item, paccess, command, 23, _, 0, call)
	
	if (equali(command, "csdm_ffa_ctrl"))
	{
		if (!csdm_get_ffa())
		{
			menu_item_setname(menu, item, "Enable FFA")
		} else {
			menu_item_setname(menu, item, "Disable FFA")
		}
	}
}

public csdm_ffa_enable(id, level, cid)
{
	if (!cmd_access(id, level, cid, 1))
		return PLUGIN_HANDLED

	csdm_set_ffa(1)
	client_print(id, print_chat, "CSDM FFA enabled.")
	
	return PLUGIN_HANDLED	
}

public csdm_ffa_disable(id, level, cid)
{
	if (!cmd_access(id, level, cid, 1))
		return PLUGIN_HANDLED

	csdm_set_ffa(0)
	client_print(id, print_chat, "CSDM FFA disabled.")
	
	return PLUGIN_HANDLED	
}

public read_cfg(readAction, line[], section[])
{
	if (readAction == CFG_READ)
	{
		new setting[24], sign[3], value[32];

		parse(line, setting, 23, sign, 2, value, 31);
	
		if (equali(setting, "enabled"))
		{
			csdm_set_ffa(str_to_num(value))
		}
	}
}
