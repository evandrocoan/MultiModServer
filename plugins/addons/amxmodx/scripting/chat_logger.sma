/* Chat Logger v2.1a
   Author: Jim (jim_yang @ AlliedModders Forum)
   Credit: aligind4h0us3 for the idea, suggestion and test.
           Cheap_Suit
           Amx Mod X Team for Adminchat plugin.
   
   Description: It logs messages of say(@|@@|@@@), say_team(@), amx_say, amx_chat, amx_psay, amx_csay, amx_tsay
   Install: put this plugin above adminchat.amxx in amxxdir\configs\plugins.ini
   Cvar: cl_logmode 0  log chat messages to ChatLog.htm in amxxdir\logs\
                    1  log chat messages(by date)to XXXX.XX.XX.htm in amxxdir\logs\
		       XXXX.XX.XX is the date.
                       default is 1.
*/

#include <amxmodx>
#include <amxmisc>
#include <cstrike>

#define MAXLEN 511
#define TITLE "<h2 align=center>Chat Logger</h2><hr>"
#define FONT "<font face=^"Verdana^" size=2>"
static FilePath[49]
new g_cvarlogmode
new g_adminchatID
new const HUDPOS[4][] = {"", "HUDCHAT", "HUDCENTER", "HUDBOTTOM"}
new const TEAMCOLOR[_:CsTeams][] = {"gray", "red", "blue", "gray"}
new const TEAMNAME[_:CsTeams][] = {"*DEAD*", "(Terrorist) ", "(Counter-Terrorist) ", "*SPEC*"}

public plugin_init()
{
	register_plugin("Chat Logger", "2.1a", "Jim")
	g_cvarlogmode = register_cvar("cl_logmode", "1")
	register_clcmd("say", "logtext")
	register_clcmd("say_team", "logtext")
	register_concmd("amx_say", "logtext")
	register_concmd("amx_chat", "logtext")
	register_concmd("amx_psay", "logtext")
	register_concmd("amx_tsay", "logtext")
	register_concmd("amx_csay", "logtext")
	get_localinfo("amxx_logs", FilePath, 48)
}

public plugin_cfg()
{
	g_adminchatID = is_plugin_loaded("Admin Chat")
}

public logtext(id)
{
	if(is_user_bot(id)) return
	
	new bool:IsAdminChatRunning = false
	if(g_adminchatID != -1)
	{
		new tmp[1], status[2]
		get_plugin(g_adminchatID,tmp,0,tmp,0,tmp,0,tmp,0,status,1)
		if(status[0] == 0x72)
			IsAdminChatRunning = true
	}
		
	static datestr[11], LogFile[65]
	new timestr[9], authid[32], ip[16], cmd[9], logmsg[MAXLEN + 1]
	new pos = 0, ufg = get_user_flags(id) & ADMIN_CHAT
	
	get_time("%Y.%m.%d", datestr, 10)
	get_time("%H:%M:%S", timestr, 8)
	get_user_authid(id, authid, 31)
	get_user_ip(id, ip, 15, 1)
	
	if(get_pcvar_num(g_cvarlogmode))
	{
		formatex(LogFile, 64, "%s/%s.htm", FilePath, datestr)
		if(!file_exists(LogFile))
		{	
			new title[80]
			formatex(title, 79, "<title>Chat Logger - %s</title>%s", datestr, TITLE)
			write_file(LogFile, title)
			write_file(LogFile, FONT)
		}
		formatex(logmsg, MAXLEN, "%s &lt;%s&gt;&lt;%s&gt;", timestr, authid, ip)
	}
	else
	{
		formatex(LogFile, 64, "%s/ChatLog.htm", FilePath)
		if(!file_exists(LogFile))
		{
			write_file(LogFile, "<title>Chat Logger</title>")
			write_file(LogFile, TITLE)
			write_file(LogFile, FONT)
		}
		formatex(logmsg, MAXLEN, "%s - %s &lt;%s&gt;&lt;%s&gt;", datestr, timestr, authid, ip)
	}
	
	read_argv(0, cmd, 8)
	if(cmd[0] == 0x61)
	{
		if(!IsAdminChatRunning || !ufg) return
		
		formatex(logmsg, MAXLEN, "%s <font color=purple>", logmsg)
		if(cmd[5] == 0x68)
			formatex(logmsg, MAXLEN, "%s(ADMINS) ", logmsg)
		else
		{
			switch(cmd[4])
			{
				case 0x73:	formatex(logmsg, MAXLEN, "%s(ALL) ", logmsg)
				case 0x74:	formatex(logmsg, MAXLEN, "%s(HUDCHAT) ", logmsg)
				case 0x63:	formatex(logmsg, MAXLEN, "%s(HUDCENTER) ", logmsg)
				case 0x70:
				{
					new priv, pname[32]
					read_argv(1, pname, 31)
					pos = strlen(pname) + 1
					priv = cmd_target(id, pname, 0)
					if(!priv)
						return
					get_user_name(priv, pname, 31)
					CheckPlayerName(pname)
					formatex(logmsg, MAXLEN, "%s(%s) ", logmsg, pname)
				}
			}
		}
	}
	else
	{
		new a = 0, at[5]
		read_argv(1, at, 4)
		while(at[a] == 0x40)
			a++
		if(IsAdminChatRunning && a && cmd[3])
		{
			pos = 1
			formatex(logmsg, MAXLEN, "%s <font color=teal>(%s) ", logmsg, is_user_admin(id) ? "ADMIN" : "PLAYER")
		}
		else if(IsAdminChatRunning && 0 < a < 4 && !cmd[3] && ufg)
		{	
			pos = IsColorLetter(at[a]) ? a + 1 : a
			formatex(logmsg, MAXLEN, "%s <font color=purple>(%s) ", logmsg, HUDPOS[a])
		}
		else
		{
			if(!is_user_connected(id)) return
			new CsTeams:team = cs_get_user_team(id)
			formatex(logmsg, MAXLEN, "%s <font color=%s>", logmsg, TEAMCOLOR[_:team])
			switch(team)
			{
				case 1, 2: 
				{
					if(!is_user_alive(id))
						formatex(logmsg, MAXLEN, "%s*DEAD*", logmsg)
					if(cmd[3])
						formatex(logmsg, MAXLEN, "%s%s", logmsg, TEAMNAME[_:team])
				}
				case 0, 3:	formatex(logmsg, MAXLEN, "%s%s", logmsg, TEAMNAME[_:team])
			}
		}
	}
	
	new name[32],  said[192]
	get_user_name(id, name, 31)
	CheckPlayerName(name)
	read_args(said, 191)
	remove_quotes(said)
	replace_all(said, 191, "<", "&lt;")
	replace_all(said, 191, ">", "&gt;")
	formatex(logmsg, MAXLEN, "%s%s</font> : <font color=green>%s</font><br>", logmsg, name, said[pos])
	write_file(LogFile, logmsg)
}

CheckPlayerName(name[])
{
	new i = 0, c
	while((c = name[i]))
	{
		switch(c)
		{
			case 0x3C: name[i] = 0x5B
			case 0x3E: name[i] = 0x5D
		}
		i++
	}
}

bool:IsColorLetter(c)
{
	switch(c)
	{
		case 0x72,0x67,0x62,0x79,0x6D,0x63,0x6F: return true
		default: return false
	}
	return false
}
