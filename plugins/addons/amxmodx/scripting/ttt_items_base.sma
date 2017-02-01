#include <amxmodx>
#include <cstrike>
#include <ttt>

enum _:ITEM_DATA
{
	ITEM_NAME[TTT_ITEMLENGHT],
	ITEM_COST,
	ITEM_TEAM
}

new g_pCommandMenuID, g_pMsgBuyClose;
new g_iTotalItems, g_iSetupItems = -1;
new g_iItemForward, Array:g_aSetup;
new g_szItems[TTT_MAXSHOP][ITEM_DATA];

new const g_szBuyCommands[][] =  
{ 
	"buy", "buyequip", "usp", "glock", "deagle", "p228", "elites", "fn57", "m3", "xm1014", "mp5", "tmp", "p90", "mac10", "ump45", "ak47",  
	"galil", "famas", "sg552", "m4a1", "aug", "scout", "awp", "g3sg1", "sg550", "m249", "vest", "vesthelm", "flash", "hegren", 
	"sgren", "defuser", "nvgs", "shield", "primammo", "secammo", "km45", "9x19mm", "nighthawk", "228compact", "12gauge", 
	"autoshotgun", "smg", "mp", "c90", "cv47", "defender", "clarion", "krieg552", "bullpup", "magnum", "d3au1", "krieg550", 
	"buyammo1", "buyammo2", "cl_autobuy", "cl_rebuy", "cl_setautobuy", "cl_setrebuy"
};

public plugin_precache()
	precache_sound("items/gunpickup2.wav");

public plugin_init()
{
	register_plugin("[TTT] Item menu base", TTT_VERSION, TTT_AUTHOR);

	register_clcmd("say /buy", "ttt_buymenu_showit");
	register_clcmd("say_team /buy", "ttt_buymenu_showit");
	g_pCommandMenuID = ttt_command_add("Buy menu");

	g_aSetup = ArrayCreate(SETUP_DATA);
	g_iItemForward = CreateMultiForward("ttt_item_selected", ET_STOP, FP_CELL, FP_CELL, FP_STRING, FP_CELL);
	g_pMsgBuyClose = get_user_msgid("BuyClose");
}

public plugin_end()
{
	ArrayDestroy(g_aSetup);
}

public plugin_natives()
{
	register_library("ttt");
	register_native("ttt_buymenu_add", "_buymenu_add");
	register_native("ttt_buymenu_show", "_buymenu_show");
	register_native("ttt_item_setup_add", "_item_setup_add");
	register_native("ttt_item_setup_remove", "_item_setup_remove");
	register_native("ttt_item_setup_update", "_item_setup_update");
	register_native("ttt_item_setup_get", "_item_setup_get");
	register_native("ttt_is_item_setup", "_is_item_setup");
	register_native("ttt_get_item_name", "_get_item_name");
	register_native("ttt_get_item_id", "_get_item_id");
}

public ttt_command_selected(id, menuid, name[])
{
	if(g_pCommandMenuID == menuid)
		ttt_buymenu_showit(id);
}

public ttt_gamemode(gamemode)
{
	if(gamemode == GAME_PREPARING)
		ArrayClear(g_aSetup);
}

public client_command(id)
{
	if(!is_user_alive(id) || ttt_return_check(id))
		return PLUGIN_CONTINUE;

	static command[16];
	read_argv(0, command, charsmax(command));
	for(new i = 0; i <= charsmax(g_szBuyCommands); i++)
	{
		if(equal(command, g_szBuyCommands[i]))
		{
			if(!task_exists(id))
				set_task(0.1, "ttt_buymenu_showit", id);

			return PLUGIN_HANDLED;
		}
	}

	if(equal(command, "client_buy_open"))
	{
		// CHANGED
		message_begin(MSG_ONE, g_pMsgBuyClose, _, id);
		message_end();
		ttt_buymenu_showit(id);
	}

	return PLUGIN_CONTINUE;
}

public ttt_buymenu_showit(id)
{
	if(!is_user_alive(id) || ttt_return_check(id))
		return PLUGIN_HANDLED;

	if(g_iTotalItems == -1)
	{
		client_print_color(id, print_team_default, "%s %L", TTT_TAG, id, "TTT_NOITEMSTOTAL");
		return PLUGIN_HANDLED;
	}

	new inno;
	static item[128], num[3];
	new menu = menu_create("\rTTT Buy menu", "ttt_buymenu_handle");
	new team = ttt_get_playerstate(id);
	for(new i = 0; i < g_iTotalItems; i++)
	{
		if(g_szItems[i][ITEM_COST] == -1) continue;
		if(g_szItems[i][ITEM_TEAM] == PC_INNOCENT)
			inno++;

		if((g_szItems[i][ITEM_TEAM] == PC_SPECIAL && (team == PC_TRAITOR || team == PC_DETECTIVE)) || team == g_szItems[i][ITEM_TEAM])
		{
			formatex(item, charsmax(item), "%s\R\y%i												", g_szItems[i][ITEM_NAME], g_szItems[i][ITEM_COST]);
			num_to_str(i, num, charsmax(num));
			menu_additem(menu, item, num);
		}
	}

	if(!inno && team == PC_INNOCENT)
	{
		client_print_color(id, print_team_default, "%s %L", TTT_TAG, id, "TTT_NOITEMSTEAM", id, special_names[team]);
		return PLUGIN_HANDLED;
	}

	menu_display(id, menu, 0);
	return PLUGIN_HANDLED;
}

public ttt_buymenu_handle(id, menu, item)
{
	if(!is_user_alive(id) || ttt_return_check(id))
		return PLUGIN_HANDLED;

	if(item == MENU_EXIT)
	{
		menu_destroy(menu);
		return PLUGIN_HANDLED;
	}

	new access, callback, num[3];
	menu_item_getinfo(menu, item, access, num, charsmax(num), _, _, callback);
	menu_destroy(menu);

	new itemid = str_to_num(num);

	new player_state = ttt_get_playerstate(id);
	if((g_szItems[itemid][ITEM_TEAM] == PC_SPECIAL && player_state != PC_TRAITOR && player_state != PC_DETECTIVE) || (player_state != g_szItems[itemid][ITEM_TEAM] && PC_SPECIAL != g_szItems[itemid][ITEM_TEAM]))
	{
		client_print_color(id, print_team_default, "%s %L", TTT_TAG, id, "TTT_ITEM3", id, special_names[g_szItems[itemid][ITEM_TEAM]], g_szItems[itemid][ITEM_NAME]);
		return PLUGIN_HANDLED;
	}

	new credits = ttt_get_playerdata(id, PD_CREDITS);
	if(credits < g_szItems[itemid][ITEM_COST])
	{
		client_print_color(id, print_team_default, "%s %L", TTT_TAG, id, "TTT_ITEM4", g_szItems[itemid][ITEM_NAME], g_szItems[itemid][ITEM_COST]);
		return PLUGIN_HANDLED;
	}

	new ret, buyer = get_sharing_id(id);
	if(is_user_alive(buyer))
	{
		ExecuteForward(g_iItemForward, ret, buyer, itemid, g_szItems[itemid][ITEM_NAME], g_szItems[itemid][ITEM_COST]);

		if(ret == PLUGIN_HANDLED)
		{
			client_cmd(buyer, "spk ^"%s^"", "items/gunpickup2.wav");
			ttt_set_playerdata(id, PD_CREDITS, credits-g_szItems[itemid][ITEM_COST]);
		
			static name[32];
			get_user_name(id, name, charsmax(name));
			if(is_sharing(id))
			{
				static name_for[32];
				get_user_name(buyer, name_for, charsmax(name_for));
				ttt_log_to_file(LOG_ITEM, "Player %s bought item %s with ID %d for player %s", name, g_szItems[itemid][ITEM_NAME], itemid, name_for);
				ttt_set_playerdata(id, PD_ITEM_SHARING, 0);
				client_print_color(id, print_team_default, "%s %L", TTT_TAG, id, "TTT_ITEM_FROM", g_szItems[itemid][ITEM_NAME], name_for);
				client_print_color(buyer, print_team_default, "%s %L", TTT_TAG, id, "TTT_ITEM_TO", name, g_szItems[itemid][ITEM_NAME]);
			}
			else ttt_log_to_file(LOG_ITEM, "Player %s bought item %s with ID %d", name, g_szItems[itemid][ITEM_NAME], itemid);
		}
	}

	return PLUGIN_HANDLED;
}

public _buymenu_add(plugin, params)
{
	if(params != 3)
		return ttt_log_api_error("ttt_buymenu_add needs 3 params(p2: %d, p3: %d)", plugin, params, get_param(2), get_param(3)) -1;

	get_string(1, g_szItems[g_iTotalItems][ITEM_NAME], charsmax(g_szItems[][ITEM_NAME]));
	g_szItems[g_iTotalItems][ITEM_COST] = get_param(2);
	g_szItems[g_iTotalItems][ITEM_TEAM] = get_param(3);

	g_iTotalItems++;
	return (g_iTotalItems - 1);
}

public _buymenu_show(plugin, params)
{
	if(params != 1)
		return ttt_log_api_error("ttt_buymenu_show needs 1 param(p1: %d)", plugin, params, get_param(1));

	new id = get_param(1);
	if(is_user_alive(id))
	{
		ttt_buymenu_showit(id);
		return 1;
	}

	return 0;
}

public _item_setup_add(plugin, params)
{
	if(params != 7)
		return ttt_log_api_error("ttt_item_setup_add needs 7 params", plugin, params) -1;

	static data[SETUP_DATA];
	data[SETUP_ITEMID] = get_param(1);
	data[SETUP_ITEMENT] = get_param(2);
	data[SETUP_ITEMTIME] = get_param(3);
	data[SETUP_ITEMOWNER] = get_param(4);
	data[SETUP_ITEMTRACER] = get_param(5);
	data[SETUP_ITEMACTIVE] = get_param(6);
	get_string(7, data[SETUP_ITEMNAME], charsmax(data[SETUP_ITEMNAME]));

	ArrayPushArray(g_aSetup, data);
	g_iSetupItems = ArraySize(g_aSetup);

	return (g_iSetupItems -1);
}

public _item_setup_remove(plugin, params)
{
	if(params != 1)
		return ttt_log_api_error("ttt_item_setup_remove needs 1 param(p1: %d)", plugin, params, get_param(1)) -1;

	new item = get_param(1);
	if(item > -1)
	{
		new data[SETUP_DATA] = {0, 0, ...};
		ArraySetArray(g_aSetup, item, data);
		return 1;
	}

	return -1;
}

public _item_setup_get(plugin, params)
{
	if(params != 2)
		return ttt_log_api_error("ttt_item_setup_get needs 2 params(p1: %d)", plugin, params, get_param(1)) -1;

	new item = get_param(1);
	if(item > -1)
	{
		static data[SETUP_DATA];
		ArrayGetArray(g_aSetup, item, data);

		set_array(2, data, sizeof(data));
		return 1;
	}

	return -1;
}

public _item_setup_update(plugin, params)
{
	if(params != 2)
		return ttt_log_api_error("ttt_item_setup_update needs 2 params(p1: %d)", plugin, params, get_param(1)) -1;

	new item = get_param(1);
	if(item > -1)
	{
		static data[SETUP_DATA];
		get_array(2, data, sizeof(data));

		ArraySetArray(g_aSetup, item, data);
		return 1;
	}

	return -1;
}

public _is_item_setup(plugin, params)
{
	if(params != 1)
		return ttt_log_api_error("ttt_is_item_setup needs 1 param(p1: %d)", plugin, params, get_param(1));


	if(g_iSetupItems > 0 && ArraySize(g_aSetup))
	{
		new ent = get_param(1);
		new data[SETUP_DATA];
		for(new i = 0; i < g_iSetupItems-1; i++)
		{
			ArrayGetArray(g_aSetup, i, data);
			if(ent == data[SETUP_ITEMENT])
				return i;
		}
	}

	return -1;
}

public _get_item_name(plugin, params)
{
	if(params != 3)
		return ttt_log_api_error("ttt_get_item_name needs 3 params(p1: %d, p3: %d)", plugin, params, get_param(1), get_param(3));

	set_string(2, g_szItems[get_param(1)][ITEM_NAME], get_param(3));
	return 1;
}

public _get_item_id(plugin, params)
{
	if(params != 1)
		return ttt_log_api_error("ttt_get_item_id needs 1 param(p1: %d)", plugin, params, get_param(1)) -2;

	new name[TTT_ITEMLENGHT];
	get_string(1, name, charsmax(name));
	for(new i = 0; i < g_iTotalItems-1; i++)
	{
		if(equal(g_szItems[i][ITEM_NAME], name))
			return i;
	}

	return -2;
}

stock get_sharing_id(id)
{
	new buyer = ttt_get_playerdata(id, PD_ITEM_SHARING);
	return buyer ? buyer : id;
}

stock is_sharing(id)
	return ttt_get_playerdata(id, PD_ITEM_SHARING);