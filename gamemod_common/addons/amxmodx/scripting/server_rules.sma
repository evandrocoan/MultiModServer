/*AMXMOD script.
*=====
* server_rules
* Server Rules
*=====
* (server_rules.sma)
* Version 1.4 
* http://djeyl.net/forum/index.php?showtopic=11675&st=0
* (c) Copyright 2004, DoubleTap <doubletap@twazz.net>
* http://counterstrike.twazz.net
* Display Rules - ClanMod Style
* Much thanks to Deagles3 for giving this plugin some life !
* modified to support both amx and amxx by Dopefish
* Command say /showrules 
* Added: additional say commands to display rules on more ways
* rules - showrules - serverrules - /rules - /showrules - /serverrules
* Can execute rules on players like ClanMod - amx_showrules username
* Can force rules on players at logon with cvar in amx.cfg: forcerules 1
*/  

#include <amxmodx> 
#include <amxmisc>

public informclient(strindex[]) { 
	new myindex 
	myindex=str_to_num(strindex) 
	if(myindex>0) 
		client_print(myindex, print_chat, "%L", myindex, "TYPE_HELP") 
} 


public mandatoryinform(strindex[]) { 
	new myindex 
	myindex=str_to_num(strindex) 
	if(myindex>0) 
	#if defined _amxmodx_included
		show_motd(myindex,"/addons/amxmodx/configs/comandos.html","Server Rules") 
	#else
		show_motd(myindex,"/addons/amxmodx/configs/comandos.html","Server Rules")
	#endif
} 

public client_putinserver(id) { 
	new str[4] 
	num_to_str(id,str,2) 
	set_task(10.0,"informclient",432211+id,str,2) 
	if(get_cvar_num("forcerules")) 
	set_task(11.0,"mandatoryinform",432611+id,str,2) 
} 

public client_disconnect(id) { 
	remove_task(432211+id) 
	remove_task(432611+id) 
} 

public server_rules(id) { 
	#if defined _amxmodx_included
		show_motd(id,"/addons/amxmodx/configs/comandos.html","Server Rules") 
	#else
		show_motd(id,"/addons/amxmodx/configs/comandos.html","Server Rules") 
	#endif
	return PLUGIN_HANDLED 
} 

public admin_showthem(id,level,cid) { 
	if (!cmd_access(id,level,cid,2)) 
  		return PLUGIN_HANDLED 
	new arg[32] 
	read_argv(1,arg,31) 
	new player = cmd_target(id,arg,5) 
	if (!player) return PLUGIN_HANDLED 

	//new name[32] 
	//get_user_name(player,name,31) 
	client_cmd(player,"say Don't shoot! I am studing!") 
	#if defined _amxmodx_included	
		show_motd(player,"/addons/amxmodx/configs/comandos.html","READ THE RULES!") 
	#else
		show_motd(player,"/addons/amxmodx/configs/comandos.html","READ THE RULES!") 
	#endif
	return PLUGIN_HANDLED 
} 

public plugin_init() {  
	register_plugin("Server Rules","1.4","DoubleTap")  
	register_dictionary("adminhelp.txt")
	
	register_clcmd("say /showrules", "server_rules") 
	register_clcmd("say showrules", "server_rules") 
	register_clcmd("say /rules", "server_rules") 
	register_clcmd("say rules", "server_rules") 

	register_clcmd("say /commands", "server_rules") 
	register_clcmd("say commands", "server_rules") 
	register_clcmd("say /regras", "server_rules") 
	register_clcmd("say regras", "server_rules") 
	
	register_cvar("forcerules","0") 
	register_concmd("amx_showrules","admin_showthem",ADMIN_SLAY,"<authid, nick or #userid>") 
	return PLUGIN_CONTINUE  
} 
