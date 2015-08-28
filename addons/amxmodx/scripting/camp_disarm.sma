/* AMX Mod X script. 
* 
* (c) Copyright 2002, OLO
* (c) Copyright 2002-2003, Mike Cao (mike@mikecao.com)
* (c) Copyright 2003, NitrX (nitrx@djeyl.net)
* Ported By KingPin(www.kingpinservers.com). I take no responsibility
* for this file in any way. Use at your own risk. No warranties of any kind.
* 
* Thx to Camper Detector from OLO & Admin Disarm from Mike Cao.
* This file is provided as is (no warranties).
* 
*/

#include <amxmodx>
#include <amxmisc>
#include <fun>

new bool:camp_checkme[33]
new camp_pos[33][3]

public checksniper(param[]){
	new origin[3], id = param[0]
	camp_checkme[id] = true
	get_user_origin(id,origin)
	if ( get_distance(origin,camp_pos[id]) > 300 ) return
	new clip, ammo, wpnid =	get_user_weapon(id,clip,ammo)
	new wpnname[32], name[32]
	get_user_name(id,name,31)
	get_weaponname(wpnid,wpnname,31)
	set_hudmessage(200, 100, 0, 0.05, 0.55, 0, 6.0, 7.0, 0.5, 0.15, 1)
	show_hudmessage(0,"%s camps with %s,^nlet's disarm him !",name,wpnname[7])
	
	get_user_origin(id,origin)
	origin[2] -= 2000
	set_user_origin(id,origin)
	new iweapons[32], wpname[32], inum
	get_user_weapons(id,iweapons,inum)
	for(new a=0;a<inum;++a){
		get_weaponname(iweapons[a],wpname,31)
		engclient_cmd(id,"drop",wpname)
	}
	engclient_cmd(id,"weapon_knife")
	origin[2] += 2005
	set_user_origin(id,origin)
	
}

public startchecking(id){
	if ( !camp_checkme[id] ) return
	camp_checkme[id] = false
	new param[2]
	param[0] = id
	get_user_origin(id,camp_pos[id])
	set_task(8.0,"checksniper",id,param,1)
}

public removechecking(id){
	camp_checkme[id] = true
	remove_task(id)
}

public client_connect(id){
	camp_checkme[id] = true
	return PLUGIN_CONTINUE
}

public plugin_init() {
	register_plugin("Camp Disarm","0.1","NitrX")
	register_event("SetFOV","startchecking","be","1<50")
	register_event("SetFOV","removechecking","be","1=90")
	return PLUGIN_CONTINUE
}