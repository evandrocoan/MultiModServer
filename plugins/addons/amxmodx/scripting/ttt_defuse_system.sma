#include <amxmodx>
#include <engine>
#include <hamsandwich>
#include <cstrike>
#include <ttt>

#define MAX_C4 10

enum _:C4INFO
{
	STORED,
	ENT,
	WIRES,
	RIGHT,
	TIME
}

new const g_szWireColors[][] =
{
	"Red",
	"Green",
	"Blue",
	"White",
	"Black",
	"Yellow"
};

new g_iPlayerWires[33][2][sizeof(g_szWireColors)];
new g_iPlayerC4[33];
new g_iC4Info[MAX_C4][C4INFO];
new g_pBombStatusForward;

public plugin_init()
{
	register_plugin("[TTT] Defusing system", TTT_VERSION, TTT_AUTHOR);
	RegisterHam(Ham_Use, "grenade", "Ham_Use_pre", 0);
	g_pBombStatusForward = CreateMultiForward("ttt_bomb_status", ET_IGNORE, FP_CELL, FP_CELL, FP_CELL);
}

public bomb_planted(id)
{
	new c4 = -1;
	while((c4 = find_ent_by_model(c4, "grenade", "models/w_c4.mdl")))
	{
		if(is_valid_ent(c4) && !entity_get_int(c4, EV_INT_iuser1))
			set_task(0.2, "give_basic_values", c4);
	}
}

public give_basic_values(c4)
{
	new index = c4_store(c4);
	new timer = floatround(cs_get_c4_explode_time(c4) - get_gametime());
	new wires = timer / (get_pcvar_num(get_cvar_pointer("ttt_c4_maxtime"))/sizeof(g_szWireColors));

	if(wires < 2)
		wires = 2;

	static const right_wires[] =
	{
		0,
		0,
		1, // total 2
		1, // 3
		1, // 4
		2, // 5
		2  // 6
	};

	g_iC4Info[index][WIRES] = wires;
	g_iC4Info[index][TIME] = timer;
	g_iC4Info[index][RIGHT] = right_wires[wires];
}

public Ham_Use_pre(ent, id, idactivator, type, Float:value)
{
	if(type != 2 || value != 1.0 || !is_user_alive(idactivator))
		return HAM_IGNORED;

	static Float:defuse_delay[33];
	if(defuse_delay[idactivator] < get_gametime())
	{
		if(ttt_get_playerstate(id) != PC_TRAITOR)
		{
			defuse_delay[idactivator] = get_gametime() + 1.0;
			ttt_wires_show(idactivator, ent);
		}
	}
	return HAM_SUPERCEDE;
}

public ttt_gamemode(gamemode)
{
	if(gamemode == GAME_PREPARING || gamemode == GAME_RESTARTING)
	{
		c4_clear(-1);
		new num, id;
		static players[32];
		get_players(players, num);
		for(--num; num >= 0; num--)
		{
			id = players[num];
			reset_all(id);
			g_iPlayerC4[id] = 0;
		}
	}
}

public ttt_wires_show(id, ent)
{
	reset_all(id);
	get_c4_info(id, ent);

	new param[1];
	param[0] = ent;
	set_task(1.0, "check_distance", id, param, 1, "b");

	new size = g_iC4Info[c4_get(ent)][WIRES];
	new menu = menu_create("\rWires", "ttt_wires_handler");
	for(new i = 0; i < size; i++)
		menu_additem(menu, g_szWireColors[g_iPlayerWires[id][0][i]], "", 0);

	menu_setprop(menu, MPROP_EXIT, MEXIT_ALL);
	menu_setprop(menu, MPROP_NOCOLORS, 1);

	menu_display(id, menu, 0);
	return PLUGIN_HANDLED;
}

public check_distance(param[], id)
{
	if(!is_valid_ent(param[0]) || entity_range(id, param[0]) > 60.0)
	{
		remove_task(id);
		show_menu(id, 0, "^n", 1);
		client_print_color(id, print_team_default, "%s %L", TTT_TAG, id, "TTT_DEFUSE3");
	}
}

public ttt_wires_handler(id, menu, item)
{
	remove_task(id);
	if(item == MENU_EXIT)
	{
		menu_destroy(menu);
		return PLUGIN_HANDLED;
	}

	static command[6], name[64];
	new access, callback;
	menu_item_getinfo(menu, item, access, command, charsmax(command), name, charsmax(name), callback);
	menu_destroy(menu);

	check_defusion(id, item, g_iPlayerC4[id]);
	return PLUGIN_HANDLED;
}

public get_c4_info(id, c4)
{
	g_iPlayerC4[id] = c4;
	new size = g_iC4Info[c4_get(c4)][WIRES];
	random_right(id, size, g_iC4Info[c4_get(c4)][RIGHT]);
	random_order(id, size);
}

public random_order(id, size)
{
	new i, ran = -1, count;
	while(ran == -1)
	{
		ran = random_num(0, size-1);
		for(i = 0; i < size; i++)
		{
			if(g_iPlayerWires[id][0][i] == ran)
				ran = -1;
		}
		if(ran != -1)
		{
			g_iPlayerWires[id][0][count] = ran;
			count++;
		}

		if(count >= size)
			break;
		else ran = -1;
	}
}

public random_right(id, size, rights)
{
	new count, ran, right = rights;
	if(cs_get_user_defuse(id) && (size-right) != 1)
		right++;

	while(count < right)
	{
		ran = random_num(0, size-1);
		if(!g_iPlayerWires[id][1][ran])
		{
			// log_amx("RIGTS %d", ran);
			g_iPlayerWires[id][1][ran] = 1;
			count++;
		}
	}
}

public check_defusion(id, item, c4)
{
	if(is_valid_ent(c4))
	{
		new ret;
		if(g_iPlayerWires[id][1][item])
		{
			message_begin(MSG_ONE_UNRELIABLE, get_user_msgid("BarTime"), _, id);
			write_short(1);
			message_end();

			// if(is_valid_ent(c4))
				// remove_entity(c4);

			ExecuteForward(g_pBombStatusForward, ret, id, BS_DEFUSED, c4);
			client_print_color(id, print_team_default, "%s %L", TTT_TAG, id, "TTT_DEFUSE1");
		}
		else
		{
			cs_set_c4_explode_time(c4, get_gametime()+0.5);
			ExecuteForward(g_pBombStatusForward, ret, id, BS_FAILED, c4);
			client_print_color(id, print_team_default, "%s %L", TTT_TAG, id, "TTT_DEFUSE2");
		}
	}

	c4_clear(item);
}

stock c4_store(c4)
{
	for(new i = 0; i < MAX_C4; i++)
	{
		if(!g_iC4Info[i][STORED])
		{
			g_iC4Info[i][STORED] = 1;
			g_iC4Info[i][ENT] = c4;
			return i;
		}
	}

	return -1;
}

stock c4_get(c4)
{
	for(new i = 0; i < MAX_C4; i++)
		if(g_iC4Info[i][ENT] == c4)
			return i;

	return -1;
}

stock c4_clear(c4)
{
	for(new z, i = 0; i < MAX_C4; i++)
	{
		for(z = 0; z < C4INFO; z++)
		{
			if(c4 >= 0) g_iC4Info[c4][z] = 0;
			else g_iC4Info[i][z] = 0;
		}

		if(c4 >= 0) break;
	}
}

stock reset_all(id)
{
	for(new i = 0; i <= charsmax(g_szWireColors); i++)
	{
		g_iPlayerWires[id][0][i] = -1;
		g_iPlayerWires[id][1][i] = 0;
	}

	if(task_exists(id))
		remove_task(id);
}