#include <amxmodx>
#include <engine>
#include <fakemeta>
#include <ttt>

new g_iBodyEnts[33], g_iBodyCount;
new g_iItemID, cvar_price_disguiser, g_iItemBought;
new g_iHasDisguiser[33], g_iItem_Backpack1[33], g_iItem_Backpack2[33], g_iItem_Backpack3[33];

public plugin_init()
{
	register_plugin("[TTT] Item: Disguiser", TTT_VERSION, TTT_AUTHOR);

	cvar_price_disguiser = my_register_cvar("ttt_price_disguiser", "1", "Disguiser price. (Default: 1)");
}

public ttt_plugin_cfg()
{
	new name[TTT_ITEMLENGHT];
	formatex(name, charsmax(name), "%L", LANG_PLAYER, "TTT_ITEM_ID7");
	g_iItemID = ttt_buymenu_add(name, get_pcvar_num(cvar_price_disguiser), PC_TRAITOR);
}

public ttt_gamemode(gamemode)
{
	if(gamemode == GAME_ENDED)
	{
		for(new i = 0; i < g_iBodyCount; i++)
			g_iBodyEnts[i] = false;
		g_iBodyCount = 0;
	}

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
			g_iHasDisguiser[id] = false;
			g_iItem_Backpack1[id] = -1;
			g_iItem_Backpack2[id] = -1;
			g_iItem_Backpack3[id] = -1;
		}
		g_iItemBought = false;
	}
}

public ttt_spawnbody(owner, ent)
{
	g_iBodyEnts[g_iBodyCount] = ent;
	g_iBodyCount++;
}

public ttt_item_selected(id, item, name[], price)
{
	if(g_iItemID == item)
	{
		g_iHasDisguiser[id] = true;
		g_iItemBought = true;
		client_print_color(id, print_team_default, "%s %L", TTT_TAG, id, "TTT_ITEM2", name, id, "TTT_ITEM_BACKPACK", name);
		g_iItem_Backpack1[id] = ttt_backpack_add(id, name);

		static pname[32], message[64];
		formatex(message, charsmax(message), "%L", id, "TTT_DISGUISER2");
		g_iItem_Backpack2[id] = ttt_backpack_add(id, message);

		ttt_get_user_name(id, pname, charsmax(pname));
		formatex(message, charsmax(message), "%L %s", id, "TTT_DISGUISER3", pname);
		g_iItem_Backpack3[id] = ttt_backpack_add(id, message);

		return PLUGIN_HANDLED;
	}

	return PLUGIN_CONTINUE;
}

public ttt_item_backpack(id, item, name[])
{
	if(g_iHasDisguiser[id])
	{
		if(g_iItem_Backpack1[id] == item)
		{
			new hide = ttt_get_playerdata(id, PD_HIDENAME);
			client_print_color(id, print_team_default, "%s %L", TTT_TAG, id, "TTT_DISGUISER1", hide ? "de" : "", name);
			ttt_set_playerdata(id, PD_HIDENAME, !hide);
		}
		else if(g_iItem_Backpack2[id] == item)
		{
			ttt_set_playerdata(id, PD_OTHERNAME, 0);
			set_player_name(id);
		}
		else if(g_iItem_Backpack3[id] == item)
		{
			new ent = find_dead_body_1d(id, g_iBodyEnts, g_iBodyCount);
			if(ent)
			{
				new owner = entity_get_int(ent, EV_INT_iuser1);
				if(owner != ttt_get_playerdata(id, PD_OTHERNAME))
				{
					ttt_set_playerdata(id, PD_OTHERNAME, owner);
					set_player_name(id);
				}
			}
			else client_print_color(id, print_team_default, "%s %L", TTT_TAG, id, "TTT_NOBODY", id, "TTT_DEADBODY");
		}

		ttt_backpack_show(id);
	}

	return PLUGIN_CONTINUE;
}

stock set_player_name(id)
{
	ttt_backpack_remove(id, g_iItem_Backpack3[id]);
	static pname[32], message[64];
	ttt_get_user_name(id, pname, charsmax(pname));
	formatex(message, charsmax(message), "%L %s", id, "TTT_DISGUISER3", pname);
	g_iItem_Backpack3[id] = ttt_backpack_add(id, message);
}