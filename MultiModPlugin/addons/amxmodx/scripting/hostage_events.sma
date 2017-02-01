

/* AMX Mod script. 
* 
* (c) Copyright 2002-2003, OLO 
* This file is provided as is (no warranties). 
* 
*/ 

/*
* Plugin to enable by menu from Stats Settings Plugin.
*
*/

#include <amxmod> 

#define STS_CHNL 	6

#define STS_FLAG25 25 //Hostages not rescued
#define STS_FLAG26 26 //Hostages rescued
#define STS_FLAG27 27 //Hostage kill
#define STS_FLAG28 28 //Hostage rescue
#define STS_FLAG29 29 //Hostage grab

new hos_owner 
new pmoney[33] 
new Float:lannounce 
new Float:trespawn[33]

new hostage_msg[5][64] = {
"Os Terroristas impediram os CTs de salvar os refens!",
"Os CTs salvaram todos os refens!",
"Ohh Inteligencia!! %s Matou um refem!",
"Refens Salvos por %s...",
"%s esta regatando um Refem!"
}

public show_msg(msg[]){ 
    set_hudmessage(200, 100, 0, 0.01, 0.91, 2, 0.02, 6.0, 0.01, 0.1, 1) 
    show_hudmessage(0,msg) 
} 

public host_notres(){
	if (get_user_flags(0,STS_CHNL)&(1<<STS_FLAG25))
		set_task(0.1,"show_msg",0,hostage_msg[0],64)
}

public host_allres(){
	if (get_user_flags(0,STS_CHNL)&(1<<STS_FLAG26))
		set_task(0.1,"show_msg",0,hostage_msg[1],64) 
	lannounce = get_gametime() + 0.25
}

public host_killed(id){
	if (!(get_user_flags(0,STS_CHNL)&(1<<STS_FLAG27))) return
	new name[32], message[128] 
	get_user_name(id,name,31) 
	new len = format(message,127,hostage_msg[2],name) 
	set_task(0.1,"show_msg",0,message,len+1) 
} 

public host_res(){ 
	if (!(get_user_flags(0,STS_CHNL)&(1<<STS_FLAG28))) return
	if (lannounce < get_gametime()){ 
		new name[32], message[128] 
		get_user_name(hos_owner,name,31) 
		new len = format(message,127,hostage_msg[3],name) 
		set_task(0.1,"show_msg",0,message,len+1) 
	} 
} 

public host_got(id){
	hos_owner = id
	if (!(get_user_flags(0,STS_CHNL)&(1<<STS_FLAG29))) return
	new money = read_data(1)
	if (money-pmoney[id]==150 && trespawn[id]<get_gametime() ) { 
		new name[32], message[128]
		get_user_name(id,name,31) 
		new len = format(message,127,hostage_msg[4],name) 
		set_task(0.1,"show_msg",0,message,len+1) 
	}
	pmoney[id] = money
} 

public user_respawn(id)
	trespawn[id] = get_gametime() + 15.0 

public plugin_init() { 
	register_plugin("Hostage Events","0.9.3","default") 
	register_event("TextMsg","host_notres","a","2&#Hostages_N") 
	register_event("TextMsg","host_allres","a","2&#All_Hostages_R") 
	register_event("TextMsg","host_killed","b","2&#Killed_Hostage") 
	register_event("SendAudio","host_res","a","2&%!MRAD_rescued") 
	register_event("Money","host_got","b","2=1") 
	register_event("ResetHUD","user_respawn","b")
		
	server_cmd("amx_addoption ^"Hostages not rescued^" %d %d",STS_CHNL,STS_FLAG25)	
	server_cmd("amx_addoption ^"Hostages rescued^" %d %d",STS_CHNL,STS_FLAG26)
	server_cmd("amx_addoption ^"Hostage kill^" %d %d",STS_CHNL,STS_FLAG27)
	server_cmd("amx_addoption ^"Hostage rescue^" %d %d",STS_CHNL,STS_FLAG28)			
	server_cmd("amx_addoption ^"Hostage grab^" %d %d",STS_CHNL,STS_FLAG29)		
	
	new mapname[4]
	get_mapname(mapname,3)
	if (!equali(mapname,"cs_",3))	pause("a")
	
	return PLUGIN_CONTINUE 
} 
