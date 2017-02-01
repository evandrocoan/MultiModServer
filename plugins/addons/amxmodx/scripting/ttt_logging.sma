#include <amxmodx>
#include <amxmisc>
#include <hamsandwich>
#include <engine>
#include <ttt>

#define LOG_MSG_SIZE 200
#define LOG_MSG_DIR "addons/amxmodx/logs/ttt"
#define LOG_MSG_PREFIX "TTT"

new cvar_logging, cvar_logging_error, cvar_logging_type;
new g_szFileNames[2][64];
new g_iDamageHolder[33][33]; //ATTACKER - VICTIM

public plugin_init()
{
	register_plugin("[TTT] Logging", TTT_VERSION, TTT_AUTHOR);

	RegisterHamPlayer(Ham_TakeDamage, "Ham_TakeDamage_post", 1);
	RegisterHamPlayer(Ham_Killed, "Ham_Killed_post", 1);

	cvar_logging		= my_register_cvar("ttt_logging",		"1",		"Logging enabled? (Default: 1)");
	cvar_logging_error	= my_register_cvar("ttt_logging_error",	"1",		"Logging should separate error file? (Default: 1)");
	cvar_logging_type	= my_register_cvar("ttt_logging_type",	"abcdefg",	"Logging type - a=default, b=error, c=gametype, d=item, e=kill, f=damage, g=misc. (Default: abcdefg)");

	new msg[32];
	get_time("%Y%m%d", msg, charsmax(msg)); 
	formatex(g_szFileNames[0], charsmax(g_szFileNames[]), "%s/%s%s.log", LOG_MSG_DIR, LOG_MSG_PREFIX, msg);
	formatex(g_szFileNames[1], charsmax(g_szFileNames[]), "%s/%s_ERRORS.log", LOG_MSG_DIR, LOG_MSG_PREFIX);
	
	get_mapname(msg, charsmax(msg));
	_ttt_log_to_file(LOG_DEFAULT, "Map changed to %s", msg);
}

public plugin_natives()
{
	register_library("ttt");
	register_native("ttt_logging", "_logging");
}

public plugin_end()
{
	new cvar = get_cvar_pointer("amx_nextmap");
	if(cvar)
	{
		new mapname[32];
		get_pcvar_string(get_cvar_pointer("amx_nextmap"), mapname, charsmax(mapname));
		_ttt_log_to_file(LOG_DEFAULT, "amx_nextmap is %s", mapname);
	}
}

public client_putinserver(id)
{
	static name[32];
	get_user_name(id, name, charsmax(name));
	_ttt_log_to_file(LOG_DEFAULT, "%s connected", name);
}

public client_disconnect(id)
{
	new num;
	static players[32];
	get_players(players, num);
	for(--num; num >= 0; num--)
		g_iDamageHolder[id][players[num]] = 0;

	get_user_name(id, players, charsmax(players));
	_ttt_log_to_file(LOG_DEFAULT, "%s disconnected", players);
}

public ttt_winner(winner)
{
	new num, numA;
	static players[32];
	get_players(players, numA, "a");
	get_players(players, num);
	ttt_log_to_file(LOG_DEFAULT, "Round was won by %s", winner == PC_TRAITOR ? "TRAITORS" : "INNOCENTS");
	ttt_log_to_file(LOG_DEFAULT, "Current player count %d/%d", numA, num);
	for(--num; num >= 0; num--)
		log_all_damage(players[num]);
}

public ttt_bomb_status(id, status, ent)
{
	static const c4_status[][] =
	{
		"planted",
		"defused",
		"failed to defuse",
		"exploded"
	};

	static name[32];
	get_user_name(id, name, charsmax(name));
	_ttt_log_to_file(LOG_ITEM, "%s %s the C4", name, c4_status[status]);
}

public Ham_TakeDamage_post(victim, inflictor, attacker, Float:damage, bits)
{
	if(!is_user_connected(attacker))
		return;

	new dmg = floatround(entity_get_float(victim, EV_FL_dmg_take));
	g_iDamageHolder[attacker][victim] += dmg;
}

public Ham_Killed_post(victim, killer, shouldgib)
{
	if(!is_user_connected(killer))
		killer = ttt_find_valid_killer(victim, killer);

	static name[32], killmsg[64];
	get_user_name(victim, name, charsmax(name));

	ttt_get_kill_message(victim, killer, killmsg, charsmax(killmsg), 1);
	_ttt_log_to_file(LOG_KILL, "[%L] %s was killed by %s", LANG_PLAYER, special_names[ttt_get_alivestate(victim)], name, killmsg);

	if(is_user_connected(killer))
	{
		new ids[2];
		ids[0] = killer;
		ids[1] = victim;
		set_task(0.1, "log_damage", _, ids, 2);
	}
}

public log_damage(params[])
{
	log_damage_one(params[0], params[1]);
}

//
public _logging(plugin, params)
{
	if(params != 2)
		return _ttt_log_api_error("ttt_logging needs 2 params(p1: %d, p2: %d)", plugin, params, get_param(1), get_param(2));

	static msg[LOG_MSG_SIZE];
	get_string(2, msg, charsmax(msg));
	remove_colors(msg, charsmax(msg));
	cs_log_file(get_param(1), msg);

	return 1;
}

stock _ttt_log_api_error(text[], plugin, params, any:...)
{
	static plugin_name[32], msg[LOG_MSG_SIZE];
	get_plugin(plugin, plugin_name, charsmax(plugin_name));
	vformat(msg, charsmax(msg), text, 4);
	_ttt_log_to_file(LOG_ERROR, "%s (params %d, plugin: %s)", msg, params, plugin_name);
	return 0;
}

stock _ttt_log_to_file(type, text[], any:...)
{
	static msg[LOG_MSG_SIZE];
	vformat(msg, charsmax(msg), text, 3);
	cs_log_file(type, msg);
}

stock cs_log_file(type, text[])
{

	if(!get_pcvar_num(cvar_logging))
		return 0;

	static cvar[15];
	get_pcvar_string(cvar_logging_type, cvar, charsmax(cvar));
	if(!cvar[0])
		return 0;

	if(read_flags(cvar) & type)
	{
		static const log_messages[][] =
		{
			"DEFAULT",
			"ERROR",
			"GAMETYPE",
			"ITEM",
			"KILL",
			"DAMAGE",
			"MISC"
		};

		static time_msg[24], msg[LOG_MSG_SIZE];
		get_time("%m/%d/%Y - %H:%M:%S", time_msg, charsmax(time_msg));
		format(msg, charsmax(msg), "[LOG] %s: [%-8s] --- %s", time_msg, log_messages[bit_to_int(type)], text);
		write_to_file(g_szFileNames[0], msg);

		if(type == LOG_ERROR && get_pcvar_num(cvar_logging_error))
			write_to_file(g_szFileNames[1], msg);
		return 1;
	}

	return 0;
}

stock remove_colors(string[], len)
{
	replace_all(string, len, "^1", "");
	replace_all(string, len, "^2", "");
	replace_all(string, len, "^3", "");
	replace_all(string, len, "^4", "");
}

stock write_to_file(file[], msg[])
{
	if(!dir_exists(LOG_MSG_DIR))
		mkdir(LOG_MSG_DIR);

	if(!file_exists(file))
	{
		new filenew = fopen(file, "wt");
		fclose(filenew);
	}

	write_file(file, msg);
}

// AKA log2(n)
stock bit_to_int(n)
{
	new count;
	while(n != 1)
	{
		n = n/2;
		count++;
		if(count > 7)
			break;
	}

	return count;
}

stock log_all_damage(attacker)
{
	new num, victim;
	static players[32];

	get_players(players, num);
	for(--num; num >= 0; num--)
	{
		victim = players[num];
		if(g_iDamageHolder[attacker][victim] > 0)
			log_damage_one(attacker, victim);
	}
}

stock log_damage_one(attacker, victim)
{
	if(g_iDamageHolder[attacker][victim] > 0)
	{
		static name[2][32];		
		get_user_name(attacker, name[0], charsmax(name[]));
		get_user_name(victim, name[1], charsmax(name[]));
		
		_ttt_log_to_file(LOG_DAMAGE, "[%L] %s attacked [%L] %s with %d damage",
			LANG_PLAYER, special_names[ttt_get_alivestate(attacker)], name[0],
			LANG_PLAYER, special_names[ttt_get_alivestate(victim)], name[1], g_iDamageHolder[attacker][victim]);

		g_iDamageHolder[attacker][victim] = 0;
	}
}