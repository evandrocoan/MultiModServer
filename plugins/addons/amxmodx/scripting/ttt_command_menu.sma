#include <amxmodx>
#include <ttt>

new g_pMenuForward, g_iTotalCount;
new g_szCommands[15][TTT_ITEMLENGHT];

public plugin_init()
{
	register_plugin("[TTT] Command menu", TTT_VERSION, TTT_AUTHOR);

	register_clcmd("say /ttt", "command_menu_show");
	register_clcmd("say_team /ttt", "command_menu_show");

	g_pMenuForward = CreateMultiForward("ttt_command_selected", ET_IGNORE, FP_CELL, FP_CELL, FP_STRING);
}

public plugin_natives()
{
	register_library("ttt");
	register_native("ttt_command_add", "_command_add");
}

public command_menu_show(id)
{
	if(!is_user_connected(id))
		return PLUGIN_HANDLED;

	static num[3];
	new menu = menu_create("\rTTT Command Menu", "command_menu_handle");

	for(new i = 0; i < g_iTotalCount; i++)
	{
		num_to_str(i, num, charsmax(num));
		menu_additem(menu, g_szCommands[i], num);
	}

	menu_display(id, menu, 0);
	return PLUGIN_CONTINUE;
}

public command_menu_handle(id, menu, item)
{
	if(item == MENU_EXIT || !is_user_connected(id))
	{
		menu_destroy(menu);
		return PLUGIN_HANDLED;
	}

	new access, callback, num[3];
	menu_item_getinfo(menu, item, access, num, charsmax(num), _, _, callback);
	menu_destroy(menu);

	new ret, itemid = str_to_num(num);
	ExecuteForward(g_pMenuForward, ret, id, itemid, g_szCommands[itemid]);

	static name[32];
	get_user_name(id, name, charsmax(name));
	ttt_log_to_file(LOG_MISC, "Player %s called menu item %s with ID %d", name, g_szCommands[itemid], itemid);

	return PLUGIN_HANDLED;
}

// API
public _command_add(plugin, params)
{
	if(params != 1)
		return ttt_log_api_error("ttt_command_add needs 1 param", plugin, params) -1;

	get_string(1, g_szCommands[g_iTotalCount], charsmax(g_szCommands[]));

	g_iTotalCount++;
	return (g_iTotalCount - 1);
}
