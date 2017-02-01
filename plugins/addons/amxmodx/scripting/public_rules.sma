/*
PUBLIC SERVER RULES 1.20 ( 2005-08-18 )

Plugin by Priski

Usage :
Put rules in rules.txt file in cstrike folder
and set rules_speed and rules_interval whatever you like

Commands :
rules_show	 - shows rules listed in rules.txt
rules_enable	 - set this to 0 to disable automatic rules display
say /rules	 - displays rules to normal user

CVARS :
 

Changelog :

1.20 / 2005-08-18
- removed client chat rules
- fixed major bugs

1.11 / 2005-08-15
- fixed some bugs

1.10 / 2005-08-14
- new CVARs : rules_hudmessage, rules_hudmessage_time
rules_join_timeout
- Rules in hudmessage mode also

1.03 / 2005-08-12
- rules_enable command fix.
- new CVAR "rules_join" set 1 to show rules
to players when they join server

1.02 / 2005-08-11
- optimized code
- rules_enable is now a command	
- default interval is now 10 minutes

1.01 / 2005-08-11
- added rules_admin_only & say /rules command
- variables are global now

1.0 / 2005-08-11
- first release

*/

#include <amxmodx>
#include <amxmisc>

new base[] = "addons/amxmodx/configs/rules.txt"

new i, num, text[127], hudmsg[440] //max hudmessage length was 439 chars (?)

public plugin_init()
{
	
	register_plugin("AMXX Public server rules", "1.20", "Priski")
	
	// register command
	
	register_concmd("rules_show", "rules", ADMIN_KICK, "- show rules to everybody")
	register_concmd("rules_enable", "r_enable", ADMIN_KICK, "- <1|0> set automessagin on/off")
	register_cvar("rules_admin_only", "1")
	register_cvar("rules_join", "1")
	register_cvar("rules_join_timeout", "5")
	register_cvar("rules_hudmessage_time", "20")
	register_cvar("rules_interval", "600")
	register_clcmd("say /regras", "clientrules", ADMIN_ALL, "- show rules")
} 

public plugin_cfg() {
	
	if (!file_exists(base)) {
		write_file(base, "; This is the public rules file, put your rules below")
		write_file(base, "; Remember, max amount of characters is 439")
		console_print(0, "%s file not found. creating new ...", base)
	}
	
}

public client_authorized ( id ) {
	// on join display rules
	
	if (get_cvar_num("rules_join")) {
		new tmp[1]
		tmp[0] = id
		set_task(1.0, "showrules",id,tmp,1)
		console_print(0, "", tmp[0])
	}
	
	return PLUGIN_HANDLED
}

public showrules (pid[]) {
	new id = pid[0]
	
	if ( get_user_team(id) != 1 && get_user_team(id) != 2 ) {
		if (id) {
			new tmp[1]
			tmp[0] = id
			set_task(2.0, "showrules",id,tmp,1)  // not yet in server
			console_print(0, "[user %d] wait for joining team ...", id)
		}
		return PLUGIN_HANDLED
	}
	
	new tmp[1]
	tmp[0] = id
	
	console_print(0, "[user %d] joined team : %d", id, get_user_team(id))
	console_print(0, "[user %d] printing rules after %d seconds", id, get_cvar_num("rules_join_timeout"))
	
	set_task(get_cvar_float("rules_join_timeout"), "printrules", id, tmp, 1)  // not yet in server
	
	return PLUGIN_HANDLED
}

public printrules(pid[])
{
	new id = pid[0]
	if (file_exists(base))
		{
		
		console_print(0, "[user] printing rules for user %d", id)
		
		set_hudmessage ( 200, 150, 0, 0.02, 0.25, 2, 0.1, get_cvar_float("rules_hudmessage_time"), 0.05, 1.0, 1)
		format(hudmsg, 439, "")
		
		// read all the rules
		for(i=0; read_file(base, i, text, 127, num); i++) {
			if (num > 0 && text[0] != ';') {
				// display with predefined delay
				add(hudmsg,439,text)
				add(hudmsg,439,"^n")
			}
		}
		
		// show hudmessages
		show_hudmessage(id, hudmsg)
		
	}
	
	return PLUGIN_HANDLED
}


public r_enable(id, level, cid)
{
	if (!cmd_access(id, level, cid, 0)) {  // NOT ADMIN
		return PLUGIN_HANDLED
	}
	
	new arg[3]
	
	read_argv(1, arg, 2)
	new value = str_to_num(arg)
	
	if (!isalnum(arg[0]))
		value = -1
	
	if (value == 0) {
		
		if (task_exists(2)) // close task
			remove_task(2)	
		
		console_print(id, "You have disabled automatic messages")
		return PLUGIN_HANDLED
		
	}
	if (value == 1) {
		// activate task, reload if already exist
		if (task_exists(2)) {
			change_task(2, get_cvar_float("rules_interval"))
			} else {
			set_task(get_cvar_float("rules_interval"), "rules", 2, "", 0, "b")
		}	
		console_print(id, "You have enabled automatic messages")
		return PLUGIN_HANDLED		
	}
	if (task_exists(2)) {
		console_print(id, "automessages is ON.")
		} else {
		console_print(id, "automessages is OFF.")
	}
	console_print(id, "rules_enable <1|0> (1 = ON, 0 = OFF)")
	return PLUGIN_HANDLED		
	
}

public clientrules(id, level, cid) {
	new pID[1]
	pID[0] = id
	
	console_print(0,"[user %d]Print rules for me only",pID[0])
	printrules(pID[0])
}

public rules(id, level, cid)
{
	new pID[1]
	pID[0] = id
			
	if (!cmd_access(id, level, cid, 0)) {  // NOT ADMIN
		return PLUGIN_HANDLED
	}
	
	// read file to all users
	pID[0] = 0
	console_print(0,"[user %d]Print rules for all",id)
	printrules(pID[0])
	
	// Reset scheduled task after display
	if (get_cvar_float("rules_interval") > 0) {
		if (task_exists(2)) {
			change_task(2, get_cvar_float("rules_interval"))
			} else {
			set_task(get_cvar_float("rules_interval"), "rules", 200, "", 0, "b")
		}
	}
	
	return PLUGIN_HANDLED
}
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1046\\ f0\\ fs16 \n\\ par }
*/
