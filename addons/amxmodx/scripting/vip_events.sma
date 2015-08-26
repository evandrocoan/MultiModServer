
/* AMX Mod script. 
* 
* (c) Copyright 2002-2003, OLO 
* This file is provided as is (no warranties). 
* 
*/ 

/*
* Plugin to enable by menu from Stats Settings Plugin.
*/

#include <amxmod> 

#define STS_CHNL 	6

#define STS_FLAG1 1 //VIP nomination
#define STS_FLAG2 2 //VIP assassination
#define STS_FLAG3 3 //VIP not escaped
#define STS_FLAG4 4 //VIP escaped

new vip_name[32]
new vip_messages[4][32] = {
"%s se tornou o VIP",
"%s VIP foi assassinado!",
"%s VIP nao escapou!",
"%s VIP escapou!"
}

public show_msg(msg[]){ 
	set_hudmessage(200, 100, 0, -1.0, 0.30, 0, 6.0, 6.0, 0.5, 1.5, 1)
	show_hudmessage(0,msg,vip_name) 
} 

public vip_spawn(id){ 
	get_user_name(id,vip_name,31)
	if ( get_user_flags(0,STS_CHNL) & (1 << STS_FLAG1) )
		set_task(0.1,"show_msg",0,vip_messages[0],32) 
} 

public vip_assa() {
	if ( get_user_flags(0,STS_CHNL) & (1 << STS_FLAG2) )
		set_task(0.1,"show_msg",0,vip_messages[1],32) 
}

public vip_notess() {
	if ( get_user_flags(0,STS_CHNL) & (1 << STS_FLAG3) )
		set_task(0.1,"show_msg",0,vip_messages[2],32) 
}

public vip_ess() {
	if ( get_user_flags(0,STS_CHNL) & (1 << STS_FLAG4) )
		set_task(0.1,"show_msg",0,vip_messages[3],32)
}

public plugin_init() { 
	register_plugin("Vip Events","0.9.3","default") 
	register_event("Battery","vip_spawn","b","1=200") 
	register_event("TextMsg","vip_assa","a","2&#VIP_A") 
	register_event("TextMsg","vip_notess","a","2&#VIP_N") 
	register_event("TextMsg","vip_ess","a","2&#VIP_E") 
	
	server_cmd("amx_addoption ^"VIP nomination^" %d %d",STS_CHNL,STS_FLAG1)	
	server_cmd("amx_addoption ^"VIP assassination^" %d %d",STS_CHNL,STS_FLAG2)
	server_cmd("amx_addoption ^"VIP not escaped^" %d %d",STS_CHNL,STS_FLAG3)
	server_cmd("amx_addoption ^"VIP escaped^" %d %d",STS_CHNL,STS_FLAG4)	

	new mapname[4]
	get_mapname(mapname,3)
	if (!equali(mapname,"as_",3))	pause("a") /* Pause on non as_ maps*/
	return PLUGIN_CONTINUE
}  
