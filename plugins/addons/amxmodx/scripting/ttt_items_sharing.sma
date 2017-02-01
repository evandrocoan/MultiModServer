#include <amxmodx>
#include <ttt>

new g_iBackpack1[33], g_iBackpack2[33];

public plugin_init()
{
	register_plugin("[TTT] Item sharing system", TTT_VERSION, TTT_AUTHOR);
}

public ttt_gamemode(gamemode)
{
	if(gamemode == GAME_RESTARTING || gamemode == GAME_PREPARING)
		reset_all();

	if(gamemode == GAME_STARTED)
	{
		new num, id;
		static players[32], out[TTT_ITEMLENGHT];
		get_players(players, num);
		for(--num; num >= 0; num--)
		{
			id = players[num];

			if(ttt_state_special(ttt_get_playerstate(id)))
			{
				formatex(out, charsmax(out), "%L", id, "TTT_ITEM_SHARING_MENU");
				g_iBackpack1[id] = ttt_backpack_add(id, out);
			}
		}
	}
}

public ttt_item_backpack(id, item, name[])
{
	if(g_iBackpack1[id] == item)
		players_menu_show(id);

	if(g_iBackpack2[id] == item)
	{
		ttt_set_playerdata(id, PD_ITEM_SHARING, 0);
		return PLUGIN_HANDLED;
	}
	
	return PLUGIN_CONTINUE;
}

public players_menu_show(id)
{
	if(!is_user_alive(id) || ttt_return_check(id) || !ttt_state_special(ttt_get_playerstate(id)))
		return PLUGIN_HANDLED;

	static name[32], data[3], menu;
	menu = menu_create("Players menu", "players_menu_handle");

	new num, i;
	static players[32];
	get_players(players, num);

	for(--num; num >= 0; num--)
	{
		i = players[num];
		get_user_name(i, name, charsmax(name));
		num_to_str(i, data, charsmax(data));
		menu_additem(menu, name, data, 0);
	}

	menu_display(id, menu);
	return PLUGIN_HANDLED;
}

public players_menu_handle(id, menu, item)
{
	if(item == MENU_EXIT || !is_user_alive(id) || ttt_return_check(id) || !ttt_state_special(ttt_get_playerstate(id)))
	{
		menu_destroy(menu);
		return PLUGIN_HANDLED;
	}

	new access, callback, num[3];
	menu_item_getinfo(menu, item, access, num, charsmax(num), _, _, callback);
	menu_destroy(menu);

	new target = str_to_num(num);
	ttt_set_playerdata(id, PD_ITEM_SHARING, target);
	if(g_iBackpack2[id] == -1)
	{
		static out[TTT_ITEMLENGHT];
		formatex(out, charsmax(out), "%L", id, "TTT_ITEM_SHARING_CLEAR");
		g_iBackpack2[id] = ttt_backpack_add(id, out);
	}

	ttt_buymenu_show(id);
	return PLUGIN_HANDLED;
}

stock reset_all()
{
	new num, id;
	static players[32];
	get_players(players, num);

	for(--num; num >= 0; num--)
	{
		id = players[num];
		g_iBackpack1[id] = -1;
		g_iBackpack2[id] = -1;
	}
}