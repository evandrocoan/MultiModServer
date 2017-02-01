#include <amxmodx>
#include <hamsandwich>
#include <engine>
#include <ttt>

new g_iJBMap, Trie:g_iCellManagers, g_iButtons[10], cvar_cell_open_delay;
new Float:g_fRoundTime;

public plugin_precache()
{
	if(ttt_is_jailmap())
	{
		g_iCellManagers = TrieCreate();
		g_iJBMap = true;
	}
}

public plugin_init()
{
	register_plugin("[TTT] Map support", TTT_VERSION, TTT_AUTHOR);

	if(g_iJBMap)
	{
		cvar_cell_open_delay = my_register_cvar("ttt_cell_open_delay", "10.0", "Cells can be opened again after X seconds. (Default: 10.0)");
		setup_buttons();
		register_clcmd("jail_open", "jail_open");
		register_clcmd("say /open", "jail_open_id");
		register_clcmd("say_team /open", "jail_open_id");
	}
}

public ttt_gamemode(gamemode)
{
	if(!g_iJBMap)
		return;

	if(gamemode == GAME_PREPARING)
	{
		set_task(1.0, "jail_open");
		g_fRoundTime = 0.0;
	}
}

public pfn_keyvalue(ent)
{
	if(!g_iJBMap || !is_valid_ent(ent))
		return PLUGIN_CONTINUE;

	static classname[32], keyname[32], value[32];
	copy_keyvalue(classname, charsmax(classname), keyname, charsmax(keyname), value, charsmax(value));
	if(!equal(classname, "multi_manager"))
		return PLUGIN_CONTINUE;

	TrieSetCell(g_iCellManagers, keyname, ent);

	return PLUGIN_CONTINUE;
}

public jail_open_id(id)
{
	new Float:cvar = get_pcvar_float(cvar_cell_open_delay), Float:round = ttt_get_roundtime();
	if(round > g_fRoundTime+cvar)
	{
		g_fRoundTime = round;
		jail_open();
		client_print_color(0, print_team_default, "%s %L", TTT_TAG, LANG_SERVER, "TTT_CANOPENCELLS");
	}
	else client_print_color(id, print_team_default, "%s %L", TTT_TAG, id, "TTT_NOTOPENCELLS", g_fRoundTime+cvar-round);
}

public jail_open()
{
	new i;
	for(i = 0; i < sizeof(g_iButtons); i++)
	{
		if(g_iButtons[i])
		{
			ExecuteHamB(Ham_Use, g_iButtons[i], 0, 0, 1, 1.0);
			entity_set_float(g_iButtons[i], EV_FL_frame, 0.0);
		}
	}
}

public setup_buttons()
{
	static info[32];
	new ent[3], Float:origin[3], pos;
	while((pos <= sizeof(g_iButtons)) && (ent[0] = find_ent_by_class(ent[0], "info_player_deathmatch")))
	{
		entity_get_vector(ent[0], EV_VEC_origin, origin);
		while((ent[1] = find_ent_in_sphere(ent[1], origin, 200.0)))
		{
			if(!is_valid_ent(ent[1]))
				continue;

			entity_get_string(ent[1], EV_SZ_classname, info, charsmax(info));
			if(!equal(info, "func_door"))
				continue;

			entity_get_string(ent[1], EV_SZ_targetname, info, charsmax(info));
			if(!info[0])
				continue;

			if(TrieKeyExists(g_iCellManagers, info))
				TrieGetCell(g_iCellManagers, info, ent[2]);
			else ent[2] = find_ent_by_target(0, info);

			if(is_valid_ent(ent[2]) && (in_array(ent[2], g_iButtons, sizeof(g_iButtons)) < 0))
			{
				g_iButtons[pos] = ent[2];
				pos++;
				break;
			}
		}
	}

	TrieDestroy(g_iCellManagers);
}

stock in_array(needle, data[], size)
{
	new i;
	for(i = 0; i < size; i++)
		if(data[i] == needle)
			return i;
	return -1;
}