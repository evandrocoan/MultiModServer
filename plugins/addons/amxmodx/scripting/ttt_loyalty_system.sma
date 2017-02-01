#include <amxmodx>
#include <engine>
#include <ttt>

new g_iBackpack1[33], g_iBackpack2[33];
new g_iLoyaltySettingTo[33];

public plugin_init()
{
	register_plugin("[TTT] Loyalty system", TTT_VERSION, TTT_AUTHOR);
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

			if(gamemode == GAME_STARTED && ttt_get_playerstate(id) == PC_DETECTIVE)
			{
				formatex(out, charsmax(out), "%L", id, "TTT_LOYALTY_ONE");
				g_iBackpack1[id] = ttt_backpack_add(id, out);
				formatex(out, charsmax(out), "%L", id, "TTT_LOYALTY_ALL");
				g_iBackpack2[id] = ttt_backpack_add(id, out);
			}
		}
	}
}

public ttt_item_backpack(id, item, name[])
{
	if(g_iBackpack1[id] == item)
	{
		new ent, body;
		get_user_aiming(id, ent, body);
		if(is_user_alive(ent))
		{
			new Float:origin[2][3];
			entity_get_vector(id, EV_VEC_origin, origin[0]);
			entity_get_vector(ent, EV_VEC_origin, origin[1]);
			if(get_distance_f(origin[0], origin[1]) < 100.0)
			{
				loyalty_menu_show(id, ent);
			}
			else
			{
				static name[32];
				get_user_name(ent, name, charsmax(name));
				client_print_color(id, print_team_default, "%s %L", TTT_TAG, id, "TTT_TOOFARCLOSE", name);
				ttt_backpack_show(id);
			}
		}
		else client_print_color(id, print_team_default, "%s %L", TTT_TAG, id, "TTT_LOYALTY_AIMING", name);
	}

	if(g_iBackpack2[id] == item)
		players_menu_show(id);
	
	return PLUGIN_CONTINUE;
}

public players_menu_show(id)
{
	if(!is_user_alive(id) || ttt_return_check(id) || ttt_get_playerstate(id) != PC_DETECTIVE)
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
	if(item == MENU_EXIT || !is_user_alive(id) || ttt_return_check(id) || ttt_get_playerstate(id) != PC_DETECTIVE)
	{
		menu_destroy(menu);
		return PLUGIN_HANDLED;
	}

	new access, callback, num[3];
	menu_item_getinfo(menu, item, access, num, charsmax(num), _, _, callback);
	menu_destroy(menu);

	new target = str_to_num(num);
	loyalty_menu_show(id, target);
	return PLUGIN_HANDLED;
}

public loyalty_menu_show(id, target)
{
	if(!is_user_alive(id) || ttt_return_check(id) || ttt_get_playerstate(id) != PC_DETECTIVE)
		return PLUGIN_HANDLED;

	static name[32], data[3], menu, menu_name[64], loyalties[TTT_ITEMLENGHT];
	get_user_name(target, name, charsmax(name));
	formatex(menu_name, charsmax(menu_name), "Player: %s", name);
	menu = menu_create(menu_name, "loyalty_menu_handle");

	g_iLoyaltySettingTo[id] = target;
	new has_loyalty = ttt_get_playerdata(target, PD_LOYALTY);

	for(new i = 0; i < sizeof(player_loyalty); i++)
	{
		num_to_str(i, data, charsmax(data));
		if(has_loyalty == i)
			formatex(loyalties, charsmax(loyalties), "%L <--", id, player_loyalty[i]);
		else formatex(loyalties, charsmax(loyalties), "%L", id, player_loyalty[i]);
		menu_additem(menu, loyalties, data, 0);
	}

	menu_display(id, menu);
	return PLUGIN_HANDLED;
}

public loyalty_menu_handle(id, menu, item)
{
	if(item == MENU_EXIT || !is_user_alive(id) || ttt_return_check(id) || ttt_get_playerstate(id) != PC_DETECTIVE)
	{
		menu_destroy(menu);
		return PLUGIN_HANDLED;
	}

	new access, callback, num[3];
	menu_item_getinfo(menu, item, access, num, charsmax(num), _, _, callback);
	menu_destroy(menu);

	new loyalty = str_to_num(num), target = g_iLoyaltySettingTo[id];
	static name[32];
	get_user_name(target, name, charsmax(name));
	ttt_set_playerdata(target, PD_LOYALTY, loyalty);
	client_print_color(id, print_team_default, "%s %L", TTT_TAG, id, "TTT_LOYALTY_SET", name, id, player_loyalty[loyalty]);

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
		reset_one(id);
	}
}

stock reset_one(id)
{
	g_iLoyaltySettingTo[id] = false;

	g_iBackpack1[id] = -1;
	g_iBackpack2[id] = -1;
}