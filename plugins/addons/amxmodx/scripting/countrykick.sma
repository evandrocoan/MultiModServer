/*
*  AMX Mod script. 
* 
* (c) Copyright 2003, ST4life 
* This file is provided as is (no warranties). 
*/

#include <amxmod>
#include <geoip>

/*
* "CountryKick" is a plugin to kick players how does not come from allowed countries.
*
* Define modus:
* Open your server.cfg or admin.cfg and a a new line:
*
*  amx_ckick "flag"
*
*    a - only player from defined countries are allowed to play (amx_ckick_allow)
*    b - everyone can play exept the defined players (amx_ckick_deny)
*
* Define Countries:
* Open your server.cfg or admin.cfg and a a new line:
*
*  amx_ckick_allow "land" "land 2"
*
*  the form for "land" and "land 2" are with 2 letters like de = germany: example:
*  amx_ckick_allow "se" "dk" "us" "uk"
*
*  
*  amx_ckick_deny "land" "land 2"
*
*  the form for "land" and "land 2" are with 2 letters like de = germany: example:
*  amx_ckick_deny "de" "be" "no" 
*
*
* History:
*
* v0.1: - public release
*/ 

#define MAX_ALLOW	64
#define MAX_DENY	64

new ckick_allow[MAX_ALLOW][3]
new ckick_deny[MAX_DENY][3]
new ckick[2]
new ckicka_num = 0
new ckickd_num = 0
new pa_num = 1
new pd_num = 1

public ckickallow_cmd(){
	if (ckicka_num >= MAX_ALLOW){
		server_print("[AMX] Country limit reached!")
		return PLUGIN_HANDLED
	}
	for(new i = 0; i < MAX_ALLOW; ++i) {
		read_argv(pa_num,ckick_allow[ckicka_num],2)
		ckicka_num++
		pa_num++
	}
	return PLUGIN_HANDLED
}

public ckickdeny_cmd(){
	if (ckickd_num >= MAX_DENY){
		server_print("[AMX] Country limit reached!")
		return PLUGIN_HANDLED
	}
	for(new i = 0; i < MAX_DENY; ++i) {
		read_argv(pd_num,ckick_deny[ckickd_num],2)
		ckickd_num++
		pd_num++
	}
	return PLUGIN_HANDLED
}

public ckick_cmd(){
	read_argv(1,ckick,1)
	return PLUGIN_HANDLED
}

public client_connect(id){
        new ip[32], country[3]
	get_user_ip(id,ip,31)
	geoip_code2(ip,country)
	new index = -1
	if(contain(ckick,"a") != -1) {
		for(new i = 0; i < MAX_ALLOW; ++i) {
			if (equali(country,ckick_allow[i])) {
				index = -1
				break
			} else {
				index = i
			}

		}
		if (index != -1) {
			client_cmd(id,"echo ^"[AMX] Sorry, but you're not allowed to play on this server!^"")
			client_cmd(id,"echo ^"[AMX] Your country is not on the list of enabled countries^";disconnect")
		}
	}
	if(contain(ckick,"b") != -1) {
		for(new i = 0; i < MAX_DENY; ++i) {
			if (equali(country,ckick_deny[i])) {
				index = i
				break
			}
		}
		if (index != -1) {
			client_cmd(id,"echo ^"[AMX] Sorry, but you're not allowed to play on this server!^"")
			client_cmd(id,"echo ^"[AMX] Your country is not on the list of enabled countries^";disconnect")
		}
	}
	return PLUGIN_CONTINUE 
}

public plugin_init(){
	register_plugin("CountryKick","0.1","ST4life")
	register_srvcmd("amx_ckick_allow","ckickallow_cmd")
	register_srvcmd("amx_ckick_deny","ckickdeny_cmd")
	register_srvcmd("amx_ckick","ckick_cmd")
	return PLUGIN_CONTINUE
}
