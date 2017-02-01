#include <amxmodx>
#include <engine>
#include <ttt>

new g_iItem_Teleporter, cvar_price_tele, cvar_teleport_wait, g_iItemBought;
new g_iHasTeleporter[33], g_iItem_Coordinates[33] = {-1, -1, ...}, g_iItem_Teleport[33] = {-1, -1, ...};
new Float:g_fPlayerOrigin[33][3], Float:g_fHasUsed[33];

public plugin_init()
{
	register_plugin("[TTT] Item: Teleport", TTT_VERSION, TTT_AUTHOR);

	cvar_teleport_wait	= my_register_cvar("ttt_teleport_wait", "5.0",	"Teleport waiting time before can be used again. (Default: 5.0)");
	cvar_price_tele		= my_register_cvar("ttt_price_tele", "1",		"Teleport price. (Default: 1)");
}

public ttt_plugin_cfg()
{
	new name[TTT_ITEMLENGHT];
	formatex(name, charsmax(name), "%L", LANG_PLAYER, "TTT_ITEM_ID12");
	g_iItem_Teleporter = ttt_buymenu_add(name, get_pcvar_num(cvar_price_tele), PC_DETECTIVE);
}

public ttt_gamemode(gamemode)
{
	if(!g_iItemBought)
		return;

	if(gamemode == GAME_PREPARING || gamemode == GAME_RESTARTING)
	{
		new num, id;
		static players[32];
		get_players(players, num);
		for(--num; num >= 0; num--)
		{
			id = players[num];
			g_iHasTeleporter[id] = false;
			g_fHasUsed[id] = 0.0;
			g_iItem_Coordinates[id] = -1;
			g_iItem_Teleport[id] = -1;
		}
		g_iItemBought = true;
	}
}

public ttt_item_selected(id, item, name[], price)
{
	if(g_iItem_Teleporter == item)
	{
		static out[TTT_ITEMLENGHT];
		g_iHasTeleporter[id] = true;
		formatex(out, charsmax(out), "%L", id, "TTT_ITEM_TELE1", 0.0, 0.0, 0.0);
		g_iItem_Coordinates[id] = ttt_backpack_add(id, out);
		g_iItemBought = true;

		client_print_color(id, print_team_default, "%s %L", TTT_TAG, id, "TTT_ITEM2", name, id, "TTT_ITEM_BACKPACK", name);
		return PLUGIN_HANDLED;
	}

	return PLUGIN_CONTINUE;
}

public ttt_item_backpack(id, item, name[])
{
	if(g_iHasTeleporter[id])
	{
		if(g_iItem_Coordinates[id] == item)
		{
			ttt_backpack_remove(id, g_iItem_Coordinates[id]);
			entity_get_vector(id, EV_VEC_origin, g_fPlayerOrigin[id]);
			if(entity_get_int(id, EV_INT_flags) & FL_DUCKING)
				g_fPlayerOrigin[id][2] += 40.0;

			static out[TTT_ITEMLENGHT];
			formatex(out, charsmax(out), "%L", id, "TTT_ITEM_TELE1", g_fPlayerOrigin[id][0], g_fPlayerOrigin[id][1], g_fPlayerOrigin[id][2]);
			g_iItem_Coordinates[id] = ttt_backpack_add(id, out);

			if(g_iItem_Teleport[id] == -1)
			{
				formatex(out, charsmax(out), "%L", id, "TTT_ITEM_ID12");
				g_iItem_Teleport[id] = ttt_backpack_add(id, out);
			}

			client_print_color(id, print_team_default, "%s %L", TTT_TAG, id, "TTT_ITEM_TELE2", g_fPlayerOrigin[id][0], g_fPlayerOrigin[id][1], g_fPlayerOrigin[id][2]);
			ttt_backpack_show(id);
		}
		else if(g_iItem_Teleport[id] == item)
		{
			if(g_fHasUsed[id] > get_gametime())
			{
				client_print_color(id, print_team_default, "%s %L", TTT_TAG, id, "TTT_ITEM_TELE4", g_fHasUsed[id]-get_gametime());
				return PLUGIN_CONTINUE;
			}

			entity_set_origin(id, g_fPlayerOrigin[id]);
			if(entity_get_int(id, EV_INT_flags) | FL_ONGROUND)
				drop_to_floor(id);

			g_fHasUsed[id] = get_gametime() + get_pcvar_float(cvar_teleport_wait);
			client_print_color(id, print_team_default, "%s %L", TTT_TAG, id, "TTT_ITEM_TELE3", g_fPlayerOrigin[id][0], g_fPlayerOrigin[id][1], g_fPlayerOrigin[id][2]);
			ttt_backpack_show(id);
		}
	}

	return PLUGIN_CONTINUE;
}