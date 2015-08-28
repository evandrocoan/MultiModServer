#include <amxmodx>
#include <amxmisc>

#define VERSION "2.0"

new g_kills[33] = {0,...}
new g_deaths[33] = {0,...}
new g_levels[13] = {3, 5, 7, 9, 11, 13, 16, 19, 22, 25, 28, 31, 35}

new g_roundKills[33], g_top
new g_firstBlood

new bool:g_died[33]

new streakSounds[13][] = 
{
	"qs/rampage.wav",
	"qs/killingspree.wav",
	"qs/dominating.wav",
	"qs/unstoppable.wav",
	"qs/ultrakill.wav",
	"qs/eagleeye.wav",
	"qs/ownage.wav",
	"qs/ludicrouskill.wav",
	"qs/headhunter.wav",
	"qs/whickedsick.wav",
	"qs/monsterkill.wav",
	"qs/holyshit.wav",
	"qs/godlike.wav"
}

new streakMsgs[13][] = 
{
	"RAMPAGE", 
	"KILLING_SPREE",
	"DOMINATING",
	"UNSTOPPABLE",
	"ULTRA_KILL",
	"EAGLE_EYE",
	"OWNAGE",
	"LUDICROUS_KILL",
	"HEAD_HUNTER",
	"WHICKED_SICK",
	"MONSTER_KILL",
	"HOLY_SHIT",
	"GODLIKE"
}

new qs_enable, qs_streak, qs_firstblood, qs_headshot, qs_humiliatingdefeat, qs_hattrick, qs_flawlessvictory

new g_msgHudSync

public plugin_init()
{
	register_plugin("Quake Sounds", VERSION, "hleV")
	register_cvar("qs_version", VERSION, FCVAR_SPONLY|FCVAR_SERVER)

	register_dictionary("quakesounds.txt")
	register_dictionary("common.txt")

	register_concmd("amx_quakesounds", "cmdQuakeSounds", ADMIN_RCON, "<1|0> - enables/disables Quake Sounds")
	register_clcmd("say qs_version", "cmdSayVersion")

	qs_enable = register_cvar("qs_enable", "1")
	qs_streak = register_cvar("qs_streak", "1")
	qs_firstblood = register_cvar("qs_firstblood", "1")
	qs_headshot = register_cvar("qs_headshot", "1")
	qs_humiliatingdefeat = register_cvar("qs_humiliatingdefeat", "1")
	qs_hattrick = register_cvar("qs_hattrick", "4")
	qs_flawlessvictory = register_cvar("qs_flawlessvictory", "6")

	register_event("DeathMsg", "death", "a", "1>0")
	register_event("DeathMsg", "deathHS", "a", "3=1")
	register_event("DeathMsg", "deathHD", "a", "4&kni")
	register_event("SendAudio", "roundEnd", "a", "2=%!MRAD_terwin", "2=%!MRAD_ctwin", "2=%!MRAD_rounddraw")
	register_event("SendAudio", "soundCTWin", "a", "2=%!MRAD_ctwin")
	register_event("SendAudio", "soundTWin", "a", "2=%!MRAD_terwin")

	register_logevent("gameStart", 2, "1=Game_Commencing")
	register_logevent("roundStart", 2, "1=Round_Start")

	g_msgHudSync = CreateHudSyncObj()
}

public cmdQuakeSounds(id, level)
{
	if (!(get_user_flags(id) & level))
	{
		console_print(id, "%L", LANG_SERVER, "NO_ACC_COM")

		return PLUGIN_HANDLED
	}

	new arg[2]
	read_argv(1, arg, 1)

	if (equali(arg, "1"))
	{
		if (get_pcvar_num(qs_enable))
			console_print(id, "%L", LANG_SERVER, "ALREADY_ENABLED")
		else
		{
			set_pcvar_num(qs_enable, 1)
			console_print(id, "%L", LANG_SERVER, "ENABLED")
		}
	}
	else if (equali(arg, "0"))
	{
		if (get_pcvar_num(qs_enable))
		{
			set_pcvar_num(qs_enable, 0)
			console_print(id, "%L", LANG_SERVER, "DISABLED")
		}
		else
			console_print(id, "%L", LANG_SERVER, "ALREADY_DISABLED")
	}
	else
		console_print(id, "%L: amx_quakesounds <1|0>", LANG_SERVER, "USAGE")

	return PLUGIN_HANDLED
}

public cmdSayVersion(id)
	client_print(id, print_chat, "Quake Sounds %s by hleV | Download @ www.amxmodx.org", VERSION)

public client_connect(id)
{
	g_kills[id] = 0
	g_deaths[id] = 0
	g_roundKills[id] = 0
	g_top = 0
}

public death()
{
	if (!get_pcvar_num(qs_enable))
		return PLUGIN_HANDLED

	new killer = read_data(1)
	new victim = read_data(2)

    	g_kills[victim] = 0
    	g_deaths[victim] += 1
	g_died[victim] = true

	if (get_pcvar_num(qs_streak) && killer != victim)
	{
    		g_kills[killer] += 1
    		g_kills[victim] = 0

    		for (new i = 0; i < 13; i++)
        		if (g_kills[killer] == g_levels[i])
				streakAnnounce(killer, i)
	}

	if (get_pcvar_num(qs_firstblood) && g_firstBlood && killer != victim)
	{
		new name[32]
		get_user_name(killer, name, 31)		
		
		set_hudmessage(200, 200, 200, -1.0, 0.27, 0, 6.0, 5.0)
		ShowSyncHudMsg(0, g_msgHudSync, "%L", LANG_SERVER, "FIRST_BLOOD", name)
		client_cmd(0, "spk qs/firstBlood")

		g_firstBlood = 0
	}

	if (get_pcvar_num(qs_hattrick) && killer != victim)
	{
		g_roundKills[killer] = g_roundKills[killer] + 1

		topPlayer()
	}

	return PLUGIN_CONTINUE
}

streakAnnounce(killer, level)
{
	new name[32]
	get_user_name(killer, name, 32)

	set_hudmessage(200, 200, 200, -1.0, 0.27, 0, 6.0, 5.0)
	ShowSyncHudMsg(0, g_msgHudSync, "%L", LANG_SERVER, streakMsgs[level], name)
	client_cmd(0, "spk %s", streakSounds[level])
}

public topPlayer()
{
	new players[32], score, playerNum
	get_players(players, playerNum)

	for (new i = 0; i < playerNum; i++)
	{
		if (g_roundKills[players[i]] > score)
		{
			score = g_roundKills[players[i]]
			g_top = players[i]
		}
		else if (g_roundKills[players[i]] == score)
			g_top = 0
	}
}

public gameStart() g_firstBlood = 1

public roundStart()
{
	if (get_pcvar_num(qs_firstblood) >= 2) 
		g_firstBlood = 1

	for (new i = 1; i <= get_maxplayers(); i++)
		g_died[i] = false
}

public deathHS()
{
	if (!get_pcvar_num(qs_enable) || !get_pcvar_num(qs_headshot))
		return PLUGIN_HANDLED

	if (get_pcvar_num(qs_headshot) == 1)
		client_cmd(read_data(1), "spk qs/headshot")
	else if (get_pcvar_num(qs_headshot) >= 2)
		client_cmd(0, "spk qs/headshot")

	return PLUGIN_CONTINUE
}

public deathHD()
{
	if (!get_pcvar_num(qs_enable) || !get_pcvar_num(qs_humiliatingdefeat))
		return PLUGIN_HANDLED

	if (get_pcvar_num(qs_humiliatingdefeat) == 1)
		client_cmd(read_data(1), "spk qs/humiliatingdefeat")
	else if (get_pcvar_num(qs_humiliatingdefeat) >= 2)
		client_cmd(0, "spk qs/humiliatingdefeat")

	return PLUGIN_CONTINUE
}

public roundEnd()
{
	if (!get_pcvar_num(qs_enable) || !get_pcvar_num(qs_hattrick))
		return PLUGIN_HANDLED

	new players[32], playerNum
	get_players(players, playerNum)

	if (g_top != 0 && g_roundKills[g_top] >= get_pcvar_num(qs_hattrick))
		set_task(3.0, "setHattrick", g_top)

	for (new i = 0; i < playerNum; i++)
	{
		g_roundKills[players[i]] = 0
		g_top = 0
	}

	return PLUGIN_CONTINUE
}

public setHattrick(g_top)
{
	new name[32]
	get_user_name(g_top, name, 32)

	set_hudmessage(200, 200, 200, -1.0, 0.27, 0, 6.0, 5.0)
	ShowSyncHudMsg(0, g_msgHudSync, "%L", LANG_SERVER, "HATTRICK", name)
	client_cmd(0, "spk qs/hattrick")
}

public soundCTWin() checkAlive("CT")
public soundTWin() checkAlive("TERRORIST")

checkAlive(const team[])
{
	if (!get_pcvar_num(qs_enable) || !get_pcvar_num(qs_flawlessvictory))
		return PLUGIN_HANDLED

	new players[32], playerNum, bool:g_flawlessVictory = true
	get_players(players, playerNum, "e", team)
    
	for (new i = 0; i < playerNum; i++)
	{
		if (!is_user_alive(players[i]) && g_died[players[i]])
		{
			g_flawlessVictory = false

			break
		}
	}

	for (new i = get_pcvar_num(qs_flawlessvictory); i <= get_maxplayers(); i++)
		if (g_flawlessVictory && is_user_connected(i))
			set_task(1.5, "setFlawlessVictory", team[0])
    
	return 1
}

public setFlawlessVictory(team)
{
	if (team == 'C')
	{
		set_hudmessage(200, 200, 200, 0.64, 0.85, 0, 6.0, 10.0)
		show_hudmessage(0, "%L", LANG_SERVER, "FLAWLESS_VICTORY_CT")
		client_cmd(0, "speak qs/flawlessvictory")
	}
	else if (team == 'T')
	{
		set_hudmessage(200, 200, 200, 0.64, 0.85, 0, 6.0, 10.0)
		show_hudmessage(0, "%L", LANG_SERVER, "FLAWLESS_VICTORY_T")
		client_cmd(0, "speak qs/flawlessvictory")
	}
}

public plugin_precache()
{
	new i

	for (i = 0; i < 13; i++)
		precache_sound(streakSounds[i])

	precache_sound("qs/firstblood.wav")
	precache_sound("qs/headshot.wav")
	precache_sound("qs/humiliatingdefeat.wav")
	precache_sound("qs/hattrick.wav")
	precache_sound("qs/flawlessvictory.wav")
}