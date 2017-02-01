
/* AMX Mod script. 
* 
* (c) Copyright 2002, OLO 
* This file is provided as is (no warranties). 
* 
*/ 

/*  cvars: 
*   amx_highping_max < value >
*		set max. ping
* 
*   amx_highping_time < value >
*   set in sec. how often the ping will be checked
* 
*   amx_highping_tests < value >
*   set min. number of checks before doing anything
*
*   Players with IMMUNITY won't be checked
*/ 

#include <amxmod>

new pping[33]
new psamples[33]

kick_player(id){
	new name[33]
	get_user_name(id,name,32)
	client_print(0,print_chat,"[AMX] Player %s disconnected due to high ping.",name) 
	client_cmd(id,"echo ^"[AMX] Desculpa desconectado por ter a latencia acima do limite...^";disconnect") 
}

public check_ping(param[]){
	new id = param[0] 
	new cping, closs 
	get_user_ping(id,cping,closs) 
	pping[id] += cping 
	psamples[id]++ 
	if ((get_cvar_num("amx_highping_tests") < psamples[id]) && (get_cvar_num("amx_highping_max") < (pping[id] / psamples[id]))) 
		kick_player(id) 
	return PLUGIN_CONTINUE 
} 

public client_putinserver(id){
	if (is_user_bot(id)||(get_user_flags(id)&ADMIN_IMMUNITY))
		return PLUGIN_CONTINUE
		
	new Float:check_time = get_cvar_float("amx_highping_time") 
	if (check_time>0.0){ 
		pping[id] = 0 
		psamples[id] = 0 
		new param[2] 
		param[0] = id 
		set_task(check_time,"check_ping",12345+id,param,2,"b") 
	}
	
	return PLUGIN_CONTINUE 
} 
 
public client_disconnect(id)
	remove_task(12345+id)

public plugin_init(){ 
	register_plugin("High Ping Kicker","0.8","[SE]ErASor") 
	register_cvar("amx_hpk","250") 
	register_cvar("amx_highping_time","20") /* check every 10 sec. */ 
	register_cvar("amx_highping_tests","12") /* so start kicking after 2 min. */ 
	return PLUGIN_CONTINUE 
}

