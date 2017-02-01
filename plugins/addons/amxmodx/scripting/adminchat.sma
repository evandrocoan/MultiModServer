#include <amxmodx>
#include <amxmisc>

#if AMXX_VERSION_NUM < 183
	#include <dhudmessage>
#endif

#define PLUGIN_NAME "OciXCrom's Admin Chat"
#define PLUGIN_VERSION "1.2"

#define FLAG_ADMIN ADMIN_SLAY 								/* Flag for "ADMIN" usage */
#define FLAG_PSAY ADMIN_BAN 								/* Players with this flag can read others players' private messages, including team ones */
#define FLAG_READ ADMIN_SLAY 								/* Players with this flag can see the admin chat */
#define FLAG_VIPCHAT ADMIN_CHAT 							/* Players with this flag can use and read VIP chat messages */
#define FLAG_ANONYMOUS ADMIN_RCON							/* This flag grants you access to szAnonymous, which allows you to change the message's type to anonymous */

#define SAY_ALL '#'											/* The symbol used for executing amx_say through default chat */
#define SAY_HUD '@'											/* The symbol used for sending a HUD message through default chat */
#define SAY_DHUD '&'										/* The symbol used for sending a DHUD message through default chat */
#define TSAY_ADMIN '@'										/* The symbol used for accessing the admin chat through team chat */
#define TSAY_VIPCHAT '!'									/* The symbol used for accessing the VIP chat through team chat */
#define TSAY_PRIVATE '#'									/* The symbol used for sending a private message through team chat */
#define TSAY_TEAMSAY '&'									/* The symbol used for sending a message to a specific team */
#define HUD_BLINK "$"										/* The symbol used for applying a blink effect to a (D)HUD message */
#define HUD_TYPEWRITER "#"									/* The symbol used for applying a typewriter effect to a (D)HUD message */

/* Here you can change the messages' secondary color.
* You can use TEAM_COLOR, RED, BLUE and GREY */
#define COLOR_SAY TEAM_COLOR								/* Color for command: amx_say */
#define COLOR_ASAY TEAM_COLOR								/* Color for command: amx_asay */
#define COLOR_CHAT TEAM_COLOR								/* Color for command: amx_chat */
#define COLOR_PSAY TEAM_COLOR								/* Color for command: amx_psay */
#define COLOR_TEAMSAY TEAM_COLOR							/* Color for command: amx_teamsay */

new const szAdmin[] = "ADMIN" 								/* The ADMIN prefix in the admin chat */
new const szVip[] = "!tVIP" 								/* The VIP prefix in the admin chat */
new const szPlayer[] = "!nPLAYER" 							/* The PLAYER prefix in the admin chat */
new const szPrivate[] = "scientist/overhere.wav" 			/* The sound used when a player receives a private message */
new const szServer[] = "!gS!tE!nR!gV!tE!nR"					/* This is used instead of name when a command is executed through the server console */
new const szAnonymous[] = "!an"								/* Using this in a message will convert it to an anonymous one */

/* These messages are used in Default Mode - Feel free to modify them */
new const g_Messages[][] = {
	"!g(ALL) !t%name% !n: !g%message%",						/* amx_say -- Sends a message to all players */
	"!g(%level%!g) %name% !t: !g%message%",					/* amx_asay -- Sends a message to all admins */
	"!g(VIP CHAT) !t%name% !n: !t%message%", 				/* amx_chat -- Send a message to VIP users */
	"!t(!g%name%!t -> !g%name2%!t) !n%message%", 			/* amx_psay -- Sends a private message to a player */
	"!t(!g%team%!t) !n%name% : !g%message%",				/* amx_teamsay -- Sends a message to a specific team */
	"%name% : %message%" 									/* amx_<letter>say(2) -- Sends a (D)HUD message to all players */
}

/* These messages are used in Anonymous Mode - Feel free to modify them */
new const g_AnonymousMessages[][] = {
	"!g(ALL) !n: !g%message%", 								/* amx_say -- Sends a message to all players */
	"!g(%level%!g) %name% !t: !g%message%",					/* amx_asay -- Sends a message to all admins */
	"!g(VIP CHAT) !t%name% !n: !t%message%",				/* amx_chat -- Send a message to VIP users */
	"!t(!g%name%!t -> !g%name2%!t) !n%message%", 			/* amx_psay -- Sends a private message to a player */
	"!t(!g%team%!t) !n: !g%message%",						/* amx_teamsay -- Sends a message to a specific team */
	"%message%"												/* amx_<letter>say(2) -- Sends a (D)HUD message to all players */
}

/* Team names for amx_teamsay */
new const szTeams[][] = {
	"",
	"Terrorist",
	"Counter-Terrorist",
	"Spectator"
}

/* These symbols are used for different colors in chat messages [don't touch the second ones (^4/^3/^1)] */
new const g_Colors[][] = {
	"!g", "^4",
	"!t", "^3",
	"!n", "^1"
}

/* These commands are used when the SAY_HUD symbol is entered X times in normal chat */
new const g_ChatHud[][] = { "amx_tsay", "amx_csay", "amx_bsay", "amx_rsay" }

new g_HudColors[][] = {"random", "white", "red", "green", "blue", "yellow", "magenta", "cyan", "orange", "ocean", "maroon"}
new g_HudValues[][] = {{0, 0, 0}, {255, 255, 255}, {255, 0, 0}, {0, 255, 0}, {0, 0, 255}, {255, 255, 0}, {255, 0, 255}, {0, 255, 255}, {227, 96, 8}, {45, 89, 116}, {103, 44, 38}}
new Float:g_Positions[][] = {{-1.0, 0.7}, {-1.0, 0.1}, {0.75, 0.55}, {0.05, 0.55}}
new g_Anonymous, g_MessageChannel

/* Don't modify anything from here ... */
#define X 0
#define Y 1
#define R 0
#define G 1
#define B 2

#define CMD_SAY 0
#define CMD_ASAY 1
#define CMD_CHAT 2
#define CMD_PSAY 3
#define CMD_TEAM 4
#define CMD_HSAY 5

#define CMD_BSAY 0
#define CMD_CSAY 1
#define CMD_RSAY 2
#define CMD_TSAY 3

enum Color
{
	NORMAL = 1, // clients scr_concolor cvar color
	GREEN, // Green Color
	TEAM_COLOR, // Red, grey, blue
	GREY, // grey
	RED, // Red
	BLUE, // Blue
}

new TeamName[][] = 
{
	"",
	"TERRORIST",
	"CT",
	"SPECTATOR"
}
/* ... to here */

public plugin_init()
{
	register_plugin(PLUGIN_NAME, PLUGIN_VERSION, "OciXCrom")
	register_cvar("CRXAdminChat", PLUGIN_VERSION, FCVAR_SERVER|FCVAR_SPONLY|FCVAR_UNLOGGED)
	
	register_clcmd("say", "hook_say")
	register_clcmd("say_team", "hook_sayTeam")
	
	register_concmd("amx_say", "cmd_say", ADMIN_CHAT, "<message> -- Sends a message to all players")
	register_concmd("amx_asay", "cmd_asay", ADMIN_ALL, "<message> -- Sends a message to all admins")
	register_concmd("amx_chat", "cmd_chat", FLAG_VIPCHAT, "<message> -- Sends a message to all VIP users")
	register_concmd("amx_psay", "cmd_psay", ADMIN_CHAT, "<player> <message> -- Sends a private message to a player")
	register_concmd("amx_teamsay", "cmd_teamsay", ADMIN_BAN, "<team> <message> -- Sends a message to a specific team")
	
	register_concmd("amx_bsay", "cmd_hsay", ADMIN_CHAT, "<color> <message> -- Sends a bottom HUD message to all players")
	register_concmd("amx_bsay2", "cmd_hsay", ADMIN_CHAT, "<color> <message> -- Sends a bottom HUD message to all players")
	register_concmd("amx_csay", "cmd_hsay", ADMIN_CHAT, "<color> <message> -- Sends a top HUD message to all players")
	register_concmd("amx_csay2", "cmd_hsay", ADMIN_RCON, "<color> <message> -- Sends a top DHUD message to all players")
	register_concmd("amx_rsay", "cmd_hsay", ADMIN_CHAT, "<color> <message> -- Sends a right sided HUD message to all players")
	register_concmd("amx_rsay2", "cmd_hsay", ADMIN_RCON, "<color> <message> -- Sends a right sided DHUD message to all players")
	register_concmd("amx_tsay", "cmd_hsay", ADMIN_CHAT, "<color> <message> -- Sends a left HUD message to all players")
	register_concmd("amx_tsay2", "cmd_hsay", ADMIN_RCON, "<color> <message> -- Sends a left DHUD message to all players")
	
	g_Anonymous = register_cvar("crxchat_anonymous", "0")
}

public hook_say(id)
{
	new message[192]
	read_args(message, charsmax(message))
	remove_quotes(message)
		
	switch(message[0])
	{
		case SAY_ALL: client_cmd(id, "amx_say %s", fix_message(message))
		case SAY_HUD, SAY_DHUD:
		{
			new type, color, symbol = message[0]
			message[0] = ' '
			
			for(new i = 1; i < 4; i++)
			{
				if(message[i] == symbol)
				{
					message[i] = ' '
					type++
				}
				else break
			}
			
			switch(message[type + 1])
			{
				case 'W': color = 1
				case 'R': color = 2
				case 'G': color = 3
				case 'B': color = 4
				case 'Y': color = 5
				case 'M': color = 6
				case 'C': color = 7
				case 'O': color = 8
			}
			
			if(color > 0) message[type + 1] = ' '
			trim(message)
			client_cmd(id, "%s%s %s %s", g_ChatHud[type], (symbol == SAY_DHUD) ? "2" : "", g_HudColors[color], message)
		}
		default: return PLUGIN_CONTINUE
	}
	
	return PLUGIN_HANDLED
}

public hook_sayTeam(id)
{
	new message[192]
	read_args(message, charsmax(message))
	remove_quotes(message)
		
	switch(message[0])
	{
		case TSAY_ADMIN: client_cmd(id, "amx_asay %s", fix_message(message))
		case TSAY_VIPCHAT: client_cmd(id, "amx_chat %s", fix_message(message))
		case TSAY_PRIVATE:
		{
			message[0] = ' '
			trim(message)
			
			new arg[32]
			parse(message, arg, charsmax(arg))
			
			if(equal(arg, ""))
				return PLUGIN_HANDLED
			
			new player = cmd_target(id, arg, 0)
			if(!player) return PLUGIN_HANDLED
			
			replace(message, charsmax(message), arg, "")
			client_cmd(id, "amx_psay #%i %s", get_user_userid(player), message)
		}
		case TSAY_TEAMSAY:
		{
			message[0] = ' '
			trim(message)
			
			new arg[32]
			parse(message, arg, charsmax(arg))
			
			if(equal(arg, ""))
				return PLUGIN_HANDLED
			
			replace(message, charsmax(message), arg, "")
			client_cmd(id, "amx_teamsay %s %s", arg, message)
		}
		default: return PLUGIN_CONTINUE
	}
	
	return PLUGIN_HANDLED
}

public cmd_say(id, level, cid)
{
	if(!cmd_access(id, level, cid, 2))
		return PLUGIN_HANDLED
	
	new arg[160]
	read_args(arg, charsmax(arg))
	remove_quotes(arg)
	trim(arg)
	
	if(equal(arg, ""))
		return PLUGIN_HANDLED
	
	new message[192], name[32]
	get_user_name(id, name, charsmax(name))
	formatex(message, charsmax(message), "%s", get_message(id, 0, is_anonymous(id, arg) ? g_AnonymousMessages[CMD_SAY] : g_Messages[CMD_SAY], arg))
	
	new players[32], num
	get_players(players, num)
	
	for(new i = 0; i < num; i++)
		ColorChat(players[i], COLOR_SAY, message)
	
	message_log(name, arg, "amx_say")
	return PLUGIN_HANDLED
}

public cmd_asay(id, level, cid)
{
	if(!cmd_access(id, level, cid, 2))
		return PLUGIN_HANDLED
	
	new arg[160]
	read_args(arg, charsmax(arg))
	remove_quotes(arg)
	trim(arg)
	
	if(equal(arg, ""))
		return PLUGIN_HANDLED
	
	new message[192], name[32]
	get_user_name(id, name, charsmax(name))
	formatex(message, charsmax(message), "%s", get_message(id, 0, is_anonymous(id, arg) ? g_AnonymousMessages[CMD_ASAY] : g_Messages[CMD_ASAY], arg))
		
	new players[32], num
	get_players(players, num)
	
	for(new i = 0; i < num; i++)
		if(get_user_flags(players[i]) & FLAG_READ || id == players[i]) ColorChat(players[i], COLOR_ASAY, message)
	
	message_log(name, arg, "amx_asay")
	return PLUGIN_HANDLED
}

public cmd_chat(id, level, cid)
{
	if(!cmd_access(id, level, cid, 2))
		return PLUGIN_HANDLED
	
	new arg[160]
	read_args(arg, charsmax(arg))
	remove_quotes(arg)
	trim(arg)
	
	if(equal(arg, ""))
		return PLUGIN_HANDLED
	
	new message[192], name[32]
	get_user_name(id, name, charsmax(name))
	formatex(message, charsmax(message), "%s", get_message(id, 0, is_anonymous(id, arg) ? g_AnonymousMessages[CMD_CHAT] : g_Messages[CMD_CHAT], arg))
		
	new players[32], num
	get_players(players, num)
	
	for(new i = 0; i < num; i++)
		if(get_user_flags(players[i]) & FLAG_VIPCHAT) ColorChat(players[i], COLOR_CHAT, message)
	
	message_log(name, arg, "amx_chat")
	return PLUGIN_HANDLED
}

public cmd_psay(id, level, cid)
{
	if(!cmd_access(id, level, cid, 3))
		return PLUGIN_HANDLED
	
	new arg[180], plr[32]
	read_args(arg, charsmax(arg))
	read_argv(1, plr, charsmax(plr))
	
	new player = cmd_target(id, plr, 0)
	
	if(!player)
		return PLUGIN_HANDLED
	
	replace(arg, charsmax(arg), plr, "")
	trim(arg)
	
	if(equal(arg, ""))
		return PLUGIN_HANDLED
	
	new message[192], name[68], name2[32]
	get_user_name(id, name, charsmax(name))
	get_user_name(player, name2, charsmax(name2))
	formatex(message, charsmax(message), "%s", get_message(id, player, is_anonymous(id, arg) ? g_AnonymousMessages[CMD_PSAY] : g_Messages[CMD_PSAY], arg))
	add(name, charsmax(name), " > ")
	add(name, charsmax(name), name2)
		
	new players[32], num
	get_players(players, num)
	
	for(new i = 0; i < num; i++)
		if(get_user_flags(players[i]) & FLAG_PSAY || player == players[i] || id == players[i]) ColorChat(players[i], COLOR_PSAY, message)
	
	client_cmd(player, "spk %s", szPrivate)
	
	message_log(name, arg, "amx_psay")
	return PLUGIN_HANDLED
}

public cmd_teamsay(id, level, cid)
{
	if(!cmd_access(id, level, cid, 3))
		return PLUGIN_HANDLED
	
	new arg[180], strteam[32], team
	read_args(arg, charsmax(arg))
	read_argv(1, strteam, charsmax(strteam))
	
	switch(strteam[0])
	{
		case 't': team = 1
		case 'c': team = 2
		case 's': team = 3
		default: return PLUGIN_HANDLED
	}
	
	replace(arg, charsmax(arg), strteam, "")
	trim(arg)
	
	if(equal(arg, ""))
		return PLUGIN_HANDLED
	
	new message[192], name[68]
	get_user_name(id, name, charsmax(name))
	formatex(message, charsmax(message), "%s", get_message(id, team, is_anonymous(id, arg) ? g_AnonymousMessages[CMD_TEAM] : g_Messages[CMD_TEAM], arg))
	add(name, charsmax(name), " > ")
	add(name, charsmax(name), szTeams[team])
		
	new players[32], num
	get_players(players, num)
	
	for(new i = 0; i < num; i++)
		if(get_user_flags(players[i]) & FLAG_PSAY || get_user_team(players[i]) == team || id == players[i]) ColorChat(players[i], COLOR_TEAMSAY, message)
	
	message_log(name, arg, "amx_teamsay")
	return PLUGIN_HANDLED
}

public cmd_hsay(id, level, cid)
{
	if(!cmd_access(id, level, cid, 3))
		return PLUGIN_HANDLED
	
	new arg[180], color[10]
	read_args(arg, charsmax(arg))
	parse(arg, color, charsmax(color))	
	replace(arg, charsmax(arg), color, "")
	trim(arg)
	
	if(equal(arg, ""))
		return PLUGIN_HANDLED
	
	new message[192], name[32], command[10], type, clr, effect
	get_user_name(id, name, charsmax(name))
	read_argv(0, command, charsmax(command))
	formatex(message, charsmax(message), "%s", get_message(id, 0, is_anonymous(id, arg) ? g_AnonymousMessages[CMD_HSAY] : g_Messages[CMD_HSAY], arg))
	
	if(contain(message, HUD_BLINK) != -1)
	{
		replace(message, charsmax(message), HUD_BLINK, "")
		effect = 1
	}
	else if(contain(message, HUD_TYPEWRITER) != -1)
	{
		replace(message, charsmax(message), HUD_TYPEWRITER, "")
		effect = 2
	}
	
	if(++g_MessageChannel > 6 || g_MessageChannel < 3)
		g_MessageChannel = 3
	
	switch(command[4])
	{
		case 'b': type = CMD_BSAY
		case 'c': type = CMD_CSAY
		case 'r': type = CMD_RSAY
		case 't': type = CMD_TSAY
	}
	
	for(clr = 0; clr < sizeof(g_HudColors); clr++)
	{
		if(equal(color, g_HudColors[clr]))
			break
	}
	
	if(clr >= sizeof(g_HudColors))
		clr = 0
	
	new dhud = (command[8] == '2') ? 1 : 0
	new bool:rndm = (clr == 0) ? true : false
	
	rndm ? send_hudmessage(dhud, random(255), random(255), random(255), type, message, effect) : send_hudmessage(dhud, g_HudValues[clr][R], g_HudValues[clr][G], g_HudValues[clr][B], type, message, effect)
	client_print(0, print_console, "[%sHUD] %s", dhud ? "D" : "", message)
	
	message_log(name, arg, command)
	return PLUGIN_HANDLED
}

public plugin_precache()
	precache_sound(szPrivate)

public message_log(name[], message[], command[])
	log_amx("[%s] %s : %s", command, name, message)
	
public send_hudmessage(hud, red, green, blue, type, message[], effect)
{
	new Float:position = g_Positions[type][Y] + float(g_MessageChannel) / 35.0
	
	switch(hud)
	{
		case 0:
		{
			set_hudmessage(red, green, blue, g_Positions[type][X], position, effect, 1.0, 15.0, 0.1, 0.15, -1)
			show_hudmessage(0, message)
		}
		case 1:
		{
			set_dhudmessage(red, green, blue, g_Positions[type][X], position, effect, 1.0, 15.0, 0.1, 0.15)
			show_dhudmessage(0, message)
		}
	}
}

stock get_message(id, player, msg[], arg[])
{
	new message[192], info[32]
	formatex(message, charsmax(message), "%s", msg)
	
	if(contain(message, "%name%") != -1)
	{
		is_user_connected(id) ? get_user_name(id, info, charsmax(info)) : formatex(info, charsmax(info), "%s", szServer)
		replace_all(message, charsmax(message), "%name%", info)
	}
	
	if(contain(message, "%name2%") != -1)
	{
		get_user_name(player, info, charsmax(info))
		replace_all(message, charsmax(message), "%name2%", info)
	}
	
	if(contain(message, "%level%") != -1)
	{
		formatex(info, charsmax(info), "%s", get_user_flags(id) & FLAG_ADMIN ? szAdmin : is_user_admin(id) ? szVip : szPlayer)
		replace_all(message, charsmax(message), "%level%", info)
	}
	
	if(contain(message, "%team%") != -1)
		replace_all(message, charsmax(message), "%team%", szTeams[player])
		
	if(contain(message, "%message%") != -1)
		replace_all(message, charsmax(message), "%message%", arg)
	
	if(contain(message, "%") != -1)
		replace_all(message, charsmax(message), "%", "")
		
	if(contain(message, szAnonymous) != -1)
		if(get_user_flags(id) & FLAG_ANONYMOUS) replace_all(message, charsmax(message), szAnonymous, "")
		
	for(new i = 0; i < sizeof(g_Colors) - 1; i += 2)
		replace_all(message, charsmax(message), g_Colors[i], g_Colors[i + 1])
	
	return message
}

stock fix_message(msg[])
{
	new message[192]
	formatex(message, charsmax(message), "%s", msg)
	message[0] = ' '
	trim(message)
	return message
}
	
stock is_anonymous(id, message[])
	return (get_pcvar_num(g_Anonymous) || ((contain(message, szAnonymous) != -1) && get_user_flags(id) & FLAG_ANONYMOUS)) ? true : false

/* ColorChat */

ColorChat(id, Color:type, const msg[], {Float,Sql,Result,_}:...)
{
	static message[256];

	switch(type)
	{
		case NORMAL: // clients scr_concolor cvar color
		{
			message[0] = 0x01;
		}
		case GREEN: // Green
		{
			message[0] = 0x04;
		}
		default: // White, Red, Blue
		{
			message[0] = 0x03;
		}
	}

	vformat(message[1], 251, msg, 4);

	// Make sure message is not longer than 192 character. Will crash the server.
	message[192] = '^0';

	static team, ColorChange, index, MSG_Type;
	
	if(id)
	{
		MSG_Type = MSG_ONE;
		index = id;
	} else {
		index = FindPlayer();
		MSG_Type = MSG_ALL;
	}
	
	team = get_user_team(index);
	ColorChange = ColorSelection(index, MSG_Type, type);

	ShowColorMessage(index, MSG_Type, message);
		
	if(ColorChange)
	{
		Team_Info(index, MSG_Type, TeamName[team]);
	}
}

ShowColorMessage(id, type, message[])
{
	message_begin(type, get_user_msgid("SayText"), _, id);
	write_byte(id)		
	write_string(message);
	message_end();	
}

Team_Info(id, type, team[])
{
	message_begin(type, get_user_msgid("TeamInfo"), _, id);
	write_byte(id);
	write_string(team);
	message_end();

	return 1;
}

ColorSelection(index, type, Color:Type)
{
	switch(Type)
	{
		case RED:
		{
			return Team_Info(index, type, TeamName[1]);
		}
		case BLUE:
		{
			return Team_Info(index, type, TeamName[2]);
		}
		case GREY:
		{
			return Team_Info(index, type, TeamName[0]);
		}
	}

	return 0;
}

FindPlayer()
{
	static i;
	i = -1;

	while(i <= get_maxplayers())
	{
		if(is_user_connected(++i))
		{
			return i;
		}
	}

	return -1;
}