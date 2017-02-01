#include <amxmodx>
#include <hamsandwich>
#include <fakemeta>
#include <engine>
#include <ttt>
#include <round_terminator>
#include <amx_settings_api>

#define TASK_ROUNDEND 1111

new g_iWonGame;
new g_iWonScore[PLAYER_CLASS], g_pWonForward, cvar_karma_win;

new g_szWinSounds[3][TTT_FILELENGHT];
new const g_szWinner[][] =
{
	"",
	"TTT_TWIN",
	"TTT_IWIN"
};

public plugin_precache()
{
	if(!amx_load_setting_string(TTT_SETTINGSFILE, "Win sounds", "TRAITOR", g_szWinSounds[1], charsmax(g_szWinSounds[])))
	{
		g_szWinSounds[1] = "ttt/win_traitors.wav";
		amx_save_setting_string(TTT_SETTINGSFILE, "Win sounds", "TRAITOR", g_szWinSounds[1]);
	}

	if(!amx_load_setting_string(TTT_SETTINGSFILE, "Win sounds", "INNOCENT", g_szWinSounds[2], charsmax(g_szWinSounds[])))
	{
		g_szWinSounds[2] = "ttt/win_innocent.wav";
		amx_save_setting_string(TTT_SETTINGSFILE, "Win sounds", "INNOCENT", g_szWinSounds[2]);
	}

	precache_sound(g_szWinSounds[1]);
	precache_sound(g_szWinSounds[2]);
}

public plugin_init()
{
	register_plugin("[TTT] Round winner", TTT_VERSION, TTT_AUTHOR);

	cvar_karma_win = my_register_cvar("ttt_karma_win", "20", "Karma for winning and keeping alive. (Default: 20)");
	register_message(get_user_msgid("TextMsg"), "Message_Winner");

	RegisterHamPlayer(Ham_Killed, "Ham_Killed_post", 1);
	g_pWonForward = CreateMultiForward("ttt_winner", ET_IGNORE, FP_CELL);
}

public plugin_natives()
{
	register_library("ttt");
	register_native("ttt_get_winner", "_get_winner");
	register_native("ttt_set_winner", "_set_winner");
}

public ttt_gamemode(gamemode)
{
	if(gamemode != GAME_STARTED && task_exists(TASK_ROUNDEND))
		remove_task(TASK_ROUNDEND);

	switch(gamemode)
	{
		case GAME_RESTARTING:
		{
			g_iWonGame = false;
			g_iWonScore[PC_DETECTIVE] = 0;
			g_iWonScore[PC_TRAITOR] = 0;
		}
		case GAME_PREPARING: set_task(floatmul(get_pcvar_float(get_cvar_pointer("mp_roundtime")), 60.0) + get_pcvar_float(get_cvar_pointer("ttt_preparation_time")), "End_Round_False", TASK_ROUNDEND);
	}

	// set_task(0.2, "Update_Scores");
}

public client_disconnect(id)
{
	if(ttt_get_gamemode() == GAME_STARTED && get_winner(0))
	{
		//new alive, num;
		//static players[32];
        //
		//get_players(players, num);
		//get_players(players, alive, "a");
		//log_amx("ENDs here %d/%d", alive, num);
		End_Round_False();
	}
}

public client_putinserver(id)
{
	if(ttt_get_gamemode() == GAME_OFF || ttt_get_gamemode() == GAME_UNSET)
	{
		new total, alive;
		static players[32];
		get_players(players, total);
		get_players(players, alive, "a");

		if(total > 2 || alive == 1)
			set_pcvar_num(get_cvar_pointer("sv_restartround"), 3);
	}
}

public Ham_Killed_post(victim, killer)
{
	if(ttt_get_specialcount(PC_TRAITOR) == 0 && ttt_get_alivestate(victim) == PC_TRAITOR)
	{
		new bomb = -1, count;
		while((bomb = find_ent_by_model(-1, "grenade", "models/w_c4.mdl")) != 0)
		{
			if(is_valid_ent(bomb))
			{
				remove_entity(bomb);
				count++;
			}
		}
		if(count)
			End_Round_False();
	}
}

public End_Round_False()
{
	new mode = ttt_get_gamemode();
	if(mode == GAME_STARTED || mode == GAME_OFF || mode == GAME_UNSET)
		TerminateRound(RoundEndType_TeamExtermination, PC_DETECTIVE, MapType_Bomb);
}

public get_winner(type)
{
	new who, num;
	static players[32];

	get_players(players, num, "a");
	if(num == 0)
	{
		//log_amx("END by NUM %d", num);
		who = PC_TRAITOR;
	}
	else if(ttt_get_specialcount(PC_DETECTIVE) == 0 && ttt_get_specialcount(PC_INNOCENT) == 0)
	{
		//log_amx("END by COUNT1 %d, %d", ttt_get_specialcount(PC_DETECTIVE), ttt_get_specialcount(PC_INNOCENT));
		who = PC_TRAITOR;
	}
	else if(ttt_get_specialcount(PC_TRAITOR) == 0)
	{
		//log_amx("END by COUNT2 %d", ttt_get_specialcount(PC_TRAITOR));
		who = PC_DETECTIVE;
	}

	if(type && who > 0)
	{
		new id, specstate, cvar = get_pcvar_num(cvar_karma_win);
		for(--num; num >= 0; num--)
		{
			id = players[num];
			specstate = ttt_get_playerstate(id);
			if(specstate == who || (who == PC_DETECTIVE && specstate == PC_INNOCENT))
				ttt_set_playerdata(id, PD_KARMATEMP, ttt_get_playerdata(id, PD_KARMATEMP) + cvar);
		}
	}
	return who;
}

public Message_Winner(msgid, dest, id)
{
	if(g_iWonGame && ttt_get_gamemode() != GAME_STARTED)
		return PLUGIN_CONTINUE;

	static message[20];
	get_msg_arg_string(2, message, charsmax(message));
	if(equal(message, "#Terrorists_Win") || equal(message, "#CTs_Win"))
	{
		new who;
		get_winner(1);
		if(equal(message, "#Terrorists_Win"))
			who = PC_TRAITOR;
		else if(equal(message, "#CTs_Win"))
			who = PC_DETECTIVE;
	
		if(!who)
			who = get_winner(0);
	
		if(who)
		{
			g_iWonGame = who;
			g_iWonScore[who]++;
			static out[32];
			formatex(out, charsmax(out), "%L", LANG_PLAYER, g_szWinner[g_iWonGame]);
			set_msg_arg_string(2, out);
			client_cmd(0, "spk ^"%s^"", g_szWinSounds[g_iWonGame]);

			new ret;
			move_grenade();
			ExecuteForward(g_pWonForward, ret, g_iWonGame);

			return PLUGIN_HANDLED;
		}
	}

	return PLUGIN_CONTINUE;
}

public Update_Scores()
{
	new msg = get_user_msgid("TeamScore");

	message_begin(MSG_BROADCAST, msg, _, 0);
	write_string("TERRORIST");
	write_short(g_iWonScore[PC_TRAITOR]);
	message_end();

	message_begin(MSG_BROADCAST, msg, _, 0);
	write_string("CT");
	write_short(g_iWonScore[PC_DETECTIVE]);
	message_end();

	g_iWonGame = false;
}

public _get_winner()
	return g_iWonGame;

public _set_winner(plugin, params)
{
	if(params != 1)
		return ttt_log_api_error("ttt_set_winner needs 1 param(p1: %d)", plugin, params, get_param(1));

	new team = get_param(1);
	if(team != PC_TRAITOR && team != PC_DETECTIVE)
		return ttt_log_api_error("ttt_set_winner team isn't Traitor or Detective, team: %d", plugin, params, team);

	TerminateRound(RoundEndType_TeamExtermination, team);
	return 1;
}