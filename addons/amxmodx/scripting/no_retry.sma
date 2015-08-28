/*
NO RETRY 1.10

Plugin by Priski

Usage :
kicks and/or notifies users if they use retry

CVARS :
amx_retrytime	 - time in seconds to determine if retry was used ( default: 15 )
amx_retrykick	 - set to 1 if you want to kick retry users ( default: 0 )
amx_retryshow	 - set to 0 if you want to disable public announces about use of retry ( default: 0 )
amx_retrychat	 - show usage in playerchat ( default: 1 )
amx_retrymsg	 - message which is displayed after reconnect to user ( default: "No retry allowed here, %s" ) *
amx_retrykickmsg - reason when kicked ( default: "DO NOT USE RETRY COMMAND" )
amx_retrychatmsg - message in playerchat ( default: "%s was kicked: reconnect in %t seconds" ) *

* NOTE:
%s = players name
%t = same as in amx_retrytime

Changelog :

1.16 / 2005-10-17
- added new feature cvars:
  amx_retrychat & amx_retrychatmsg
- better functionality
- hudmessages only to user who triggered

1.10 / 2005-08-17
- whole code rewritten
- bugs fixed

1.00 / 2005-08-15
- first release


*/
#include <amxmodx>
#include <amxmisc>

#define MAX_PLAYERS 32

new pID[MAX_PLAYERS][22]

public plugin_init() {
	register_plugin("No retry","1.16","Priski") 
	register_cvar("amx_retrytime","60")
	register_cvar("amx_retrykick","0")
	register_cvar("amx_retryshow","0")
	register_cvar("amx_retrychat","1")
	
	// %s is the player name, %t is amx_retrytime
	register_cvar("amx_retrymsg","No retry allowed here, %s")
	register_cvar("amx_retrykickmsg","Too fast reconnect is not allowed")
	register_cvar("amx_retrychatmsg","%s was kicked: reconnect in %t seconds")
		
	return PLUGIN_HANDLED
}

public client_putinserver(id) {
	// no bots or admin immunity users
	if ((is_user_bot(id)) || (get_user_flags(id)&ADMIN_IMMUNITY)) {
		return PLUGIN_HANDLED
	}
	
	// gather info
	new ip[22]
	get_user_ip(id,ip,21)
	
	for(new i = 1; i < MAX_PLAYERS; i++) {
		if (equal(ip, pID[i], 21)) {
			
			new name[34]
			get_user_name(id, name, 33)
			
			if (get_cvar_num("amx_retryshow")) {
				new uID[1]
				uID[0] = id
				set_task(2.0,"showMsg", id, uID, 1)
			}
			
			if (get_cvar_num("amx_retrychat")) {
				new txt[128]
				get_cvar_string("amx_retrychatmsg", txt, 127)
				new sec[6]
				num_to_str(get_cvar_num("amx_retrytime"),sec, 5)
				
				replace(txt, 127, "%s", name)
				replace(txt, 127, "%t", sec)
				
				client_print( 0, print_chat, "[AMXX] %s", txt)
			}
						
			if (get_cvar_num("amx_retrykick")) {
				new uID[1]
				uID[0] = get_user_userid(id)
								
				// delayed kick
				set_task(7.0,"kick",77,uID,1)
				
			}
			
			break
		}
	}
	
	return PLUGIN_HANDLED;
}

public client_disconnect(id) {
	// no bots or admin immunity users are in list
	if ((is_user_bot(id)) || (get_user_flags(id)&ADMIN_IMMUNITY)) {
	return PLUGIN_HANDLED; }

	// gather info
	new ip[22]
	get_user_ip(id,ip,21)
	new found = 0;
	
	for(new i = 1; i < MAX_PLAYERS; i++) {
		if (equal(ip, pID[i], 21)) {
			// this user has been already kicked
			found = 1
			break
		}
	}
	
	if (found == 0) {
		for(new i = 1; i < MAX_PLAYERS; i++) {
			if (pID[i][0] == 0) {	// found empty slot
				get_user_ip(id, pID[i], 21)
				new aID[1]
				aID[0] = i
				set_task( get_cvar_float("amx_retrytime"), "cleanID", (id + MAX_PLAYERS),aID,1)
						
				break
			}
		}
	}
	return PLUGIN_HANDLED;
}


public cleanID(i[]) {
	pID[i[0]][0] = 0
}

public showMsg(pID[]) {
	new txt[128]
	get_cvar_string("amx_retrymsg", txt, 127)
	
	new playername[34]
	get_user_name(pID[0], playername, 33)
	
	new sec[6]
	num_to_str(get_cvar_num("amx_retrytime"),sec, 5)
	
	replace(txt, 127, "%s", playername)
	replace(txt, 127, "%t", sec)
	
	set_hudmessage(255, 255, 255, 0.05, 0.72, 0, 5.0, 10.0, 2.0, 0.15, 3)
	show_hudmessage(pID[0],txt)
}

public kick(id[]) {
	new txt[128]
	get_cvar_string("amx_retrykickmsg", txt, 127)
	server_cmd("kick #%d ^"%s^"", id[0], txt)
}
