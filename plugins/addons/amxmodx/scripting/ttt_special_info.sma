#include <amxmodx>
#include <engine>
#include <fakemeta>
#include <amx_settings_api>
#include <ttt>

new const g_szDSprite[] = "sprites/ttt/team_d.spr";
new const g_szTSprite[] = "sprites/ttt/team_t.spr";

new cvar_show_health;
new g_iBodyEnts[33], g_iBodyCount, Float:g_fShowTime[33];
new g_iStatusSync, g_iKarmaSync, g_pDetectiveSpr, g_pTraitorSpr, g_iActiveTarget[33];

public plugin_precache()
{
	new sprites[TTT_FILELENGHT];
	if(!amx_load_setting_string(TTT_SETTINGSFILE, "Player Icons", "TRAITOR", sprites, charsmax(sprites)))
	{
		amx_save_setting_string(TTT_SETTINGSFILE, "Player Icons", "TRAITOR", g_szTSprite);
		g_pTraitorSpr = precache_model(g_szTSprite);
	}
	else g_pTraitorSpr = precache_model(sprites);

	if(!amx_load_setting_string(TTT_SETTINGSFILE, "Player Icons", "DETECTIVE", sprites, charsmax(sprites)))
	{
		amx_save_setting_string(TTT_SETTINGSFILE, "Player Icons", "DETECTIVE", g_szDSprite);
		g_pDetectiveSpr = precache_model(g_szDSprite);
	}
	else g_pDetectiveSpr = precache_model(sprites);
}

public plugin_init()
{
	register_plugin("[TTT] Special player info", TTT_VERSION, TTT_AUTHOR);
	cvar_show_health = my_register_cvar("ttt_show_health", "1", "Should show health if aimed on player? (Default: 1)");

	register_event("StatusValue", "Event_StatusValue_S", "be", "1=2", "2!0");
	register_event("StatusValue", "Event_StatusValue_H", "be", "1=1", "2=0");

	g_iStatusSync = CreateHudSyncObj();
	g_iKarmaSync = CreateHudSyncObj();
}

public client_putinserver(id)
{
	set_task(1.0, "show_status", id, _, _, "b");
}

public client_disconnect(id)
{
	if(task_exists(id))
		remove_task(id);
}

public ttt_gamemode(gamemode)
{
	if(gamemode == GAME_ENDED)
	{
		for(new i = 0; i < g_iBodyCount; i++)
			g_iBodyEnts[i] = false;
		g_iBodyCount = 0;
	}
}

public ttt_spawnbody(owner, ent)
{
	g_iBodyEnts[g_iBodyCount] = ent;
	g_iBodyCount++;
}

// public client_PostThink(id)
// {
// 	if(!is_user_alive(id) || g_fShowTime[id] > get_gametime() || ttt_return_check(id))
// 		return;

// 	g_fShowTime[id] = get_gametime() + 1.0;
// 	new ent = find_dead_body_1d(id, g_iBodyEnts, g_iBodyCount);
// 	if(ent)
// 	{
// 		new target = entity_get_int(ent, EV_INT_iuser1);
// 		if(!is_user_connected(target) || is_user_alive(target))
// 			return;

// 		new R, G = 50, B;
// 		static out[64];
// 		if(ttt_get_playerdata(target, PD_IDENTIFIED))
// 		{
// 			new killedstate = ttt_get_playerdata(target, PD_KILLEDSTATE);
// 			R = g_iTeamColors[killedstate][0];
// 			G = g_iTeamColors[killedstate][1];
// 			B = g_iTeamColors[killedstate][2];
// 			static name[32];
// 			get_user_name(target, name, charsmax(name));
// 			formatex(out, charsmax(out), "[%L] %s", id, special_names[killedstate], name);
// 		}
// 		else
// 		{
// 			R = 255;
// 			G = 222;
// 			if(ttt_get_playerstate(id) == PC_TRAITOR)
// 				formatex(out, charsmax(out), "%L --- [%L]", id, "TTT_UNIDENTIFIED", id, special_names[ttt_get_playerdata(target, PD_KILLEDSTATE)]);
// 			else formatex(out, charsmax(out), "%L", id, "TTT_UNIDENTIFIED");
// 		}

// 		g_fShowTime[id] += 1.0;
// 		set_hudmessage(R, G, B, -1.0, 0.60, 1, 1.0, 1.3, 0.05, 0.01, -1);
// 		ShowSyncHudMsg(id, g_iStatusSync, "%s", out);
// 	}
// 	else
// 	{
// 		new body;
// 		get_user_aiming(id, ent, body);
// 		if(is_valid_ent(ent))
// 		{
// 			static classname[32];
// 			entity_get_string(ent, EV_SZ_classname, classname, charsmax(classname));
		
// 			if(equal(classname, TTT_DEATHSTATION) && ttt_get_playerstate(id) == PC_TRAITOR)
// 			{
// 				new target = entity_get_int(ent, EV_INT_iuser1);
// 				if(!is_user_connected(target))
// 					return;
		
// 				g_fShowTime[id] += 1.0;
// 				static name[32];
// 				get_user_name(target, name, charsmax(name));
// 				set_hudmessage(g_iTeamColors[PC_TRAITOR][0], g_iTeamColors[PC_TRAITOR][1], g_iTeamColors[PC_TRAITOR][2], -1.0, 0.60, 1, 1.0, 1.3, 0.01, 0.01, -1);
// 				ShowSyncHudMsg(id, g_iStatusSync, "%s --- [%L]", name, id, "TTT_ITEM_ID8");
// 			}
// 		}
// 	}
// }

public Event_StatusValue_S(id)
{
	if(!is_user_connected(id))
		return;

	new mode = ttt_get_gamemode();
	if(mode != GAME_STARTED && mode != GAME_PREPARING)
		return;

	static message[128], name[32], loyalties[32];
	new target = read_data(2);

	new targetState = ttt_get_playerstate(target), idState = ttt_get_playerstate(id), useState;
	new fakeState = ttt_get_playerdata(target, PD_FAKESTATE);
	if(fakeState && targetState != idState)
		targetState = fakeState;

	if(targetState == PC_DETECTIVE)
		useState = PC_DETECTIVE;
	else if(targetState == PC_TRAITOR && idState == PC_TRAITOR)
		useState = PC_TRAITOR;
	else useState = PC_INNOCENT;

	if(mode == GAME_PREPARING)
	{
		targetState = PC_INNOCENT;
		useState = PC_INNOCENT;
	}

	new loyalty = ttt_get_playerdata(target, PD_LOYALTY);
	if(loyalty)
		formatex(loyalties, charsmax(loyalties), "[%L]", id, player_loyalty[loyalty]);
	else loyalties = "";

	new R = g_iTeamColors[useState][0];
	new G = g_iTeamColors[useState][1];
	new B = g_iTeamColors[useState][2];

	new karma = ttt_get_playerdata(target, PD_KARMA);
	set_hudmessage(R, G, B, -1.0, 0.60, 1, 0.01, 3.0, 0.01, 0.01, -1);
	remove_special_sprite(id, g_iActiveTarget[id]);

	ttt_get_user_name(target, name, charsmax(name));
	if(get_pcvar_num(cvar_show_health))
		formatex(message, charsmax(message), "%s %s -- [Karma = %d] [HP = %d]", loyalties, name, karma, get_user_health(target));
	else formatex(message, charsmax(message), "%s %s -- [Karma = %d]", loyalties, name, karma);

	if((idState == PC_INNOCENT || idState == PC_DETECTIVE) && targetState != PC_DETECTIVE)
	{
		if(!ttt_get_playerdata(target, PD_HIDENAME))
			ShowSyncHudMsg(id, g_iStatusSync, "%s", message);
	}
	else if(target != g_iActiveTarget[id])
	{
		if(mode == GAME_PREPARING || mode == GAME_OFF)
			ShowSyncHudMsg(id, g_iStatusSync, "%s", message);
		else 
		{
			format(message, charsmax(message), "[%L] %s", id, special_names[targetState], message);
			ShowSyncHudMsg(id, g_iStatusSync, "%s", message);
		}

		if(targetState == PC_DETECTIVE)
			show_special_sprite(id, target, PC_DETECTIVE);
		else if(targetState == PC_TRAITOR && idState == PC_TRAITOR)
			show_special_sprite(id, target, PC_TRAITOR);
	}

	g_iActiveTarget[id] = target;
}

public Event_StatusValue_H(id)
{
	ClearSyncHud(id, g_iStatusSync);
	remove_special_sprite(id, g_iActiveTarget[id]);
}

public show_special_sprite(id, target, which)
{
	if(!is_user_connected(id) || !is_user_connected(target))
		return;

	message_begin(MSG_ONE, SVC_TEMPENTITY, _, id);
	write_byte(TE_PLAYERATTACHMENT);
	write_byte(target);
	write_coord(45);
	if(which == PC_TRAITOR)
		write_short(g_pTraitorSpr);
	else if(which == PC_DETECTIVE)
		write_short(g_pDetectiveSpr);
	write_short(30);
	message_end();
}

public remove_special_sprite(id, target)
{
	if(!is_user_connected(id) || !is_user_connected(target))
		return;

	message_begin(MSG_ONE, SVC_TEMPENTITY, _, id);
	write_byte(TE_KILLPLAYERATTACHMENTS);
	write_byte(target);
	message_end();

	g_iActiveTarget[id] = 0;
}

public show_status(alive)
{
	new dead = alive;
	if(!is_user_alive(dead))
	{
		alive = entity_get_int(dead, EV_INT_iuser2);
		if(!is_user_alive(alive))
			return;
	}

	new R, G, B;
	new aliveState = ttt_get_playerstate(alive), deadState = ttt_get_playerstate(dead);
	if(deadState == PC_DEAD || deadState == PC_NONE)
	{
		R = g_iTeamColors[deadState][0];
		G = g_iTeamColors[deadState][1];
		B = g_iTeamColors[deadState][2];
	}
	else
	{
		R = g_iTeamColors[aliveState][0];
		G = g_iTeamColors[aliveState][1];
		B = g_iTeamColors[aliveState][2];
	}
	
	set_hudmessage(R, G, B, 0.02, 0.9, 0, 6.0, 1.1, 0.0, 0.0, -1);
	new karma = ttt_get_playerdata(alive, PD_KARMA);

	static loyalties[32];
	new loyalty = ttt_get_playerdata(alive, PD_LOYALTY);
	if(loyalty)
		formatex(loyalties, charsmax(loyalties), "[%L]", alive, player_loyalty[loyalty]);
	else loyalties = "";

	if(deadState == PC_DEAD || deadState == PC_NONE)
		ShowSyncHudMsg(dead, g_iKarmaSync, "%s [Karma = %d]", loyalties, karma);
	else if(aliveState != PC_DETECTIVE && aliveState != PC_TRAITOR)
		ShowSyncHudMsg(alive, g_iKarmaSync, "%s [Karma = %d] [%L]", loyalties, karma, alive, special_names[aliveState]);
	else ShowSyncHudMsg(alive, g_iKarmaSync, "%s [Karma = %d] [%L] [Credits = %d]", loyalties, karma, alive, special_names[aliveState], ttt_get_playerdata(alive, PD_CREDITS));
}