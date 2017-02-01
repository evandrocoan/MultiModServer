#include <amxmodx>
#include <amxmisc>
#include <fakemeta>

new cvar_on
new entlist[][] = {
	"func_button",
	"trigger_multiple",
	"trigger_once"
}

public plugin_init() {
	register_plugin("Jail Opener","1.0","danielkza")
	register_concmd("open_jail","open_jail_cmd",ADMIN_KICK,"Open/Close the jail on surf maps")
	cvar_on = register_cvar("open_jail_on","1")
}

public open_jail_cmd(id,level,cid) {
	if(!cmd_access(id,level,cid,0))
		return PLUGIN_HANDLED
	
	new map[32]
	get_mapname(map,31)
	
	if(!get_pcvar_num(cvar_on)) {
		client_print(id,print_console,"[AMXX] Jail opening disabled")
		return PLUGIN_HANDLED
	}
	
	else if(!equali(map,"surf",4)) {
		client_print(id,print_console,"[AMXX] Not in a Surf map")
		return PLUGIN_HANDLED
	}
	
	else {
		if(read_argc()>1) {
			new arg[8]
			read_argv(1,arg,7)
			set_task(str_to_float(arg),"open_jail",id)
		}
		else
			open_jail(id)
	}
	return PLUGIN_HANDLED
}

public open_jail(id) {
	new ent,target[32],ent2

	for(new i=0;i < sizeof entlist;i++) {
		ent=0
		ent2=0
		while((ent = engfunc(EngFunc_FindEntityByString, ent, "classname", entlist[i]))) {
			if(pev_valid(ent)) {
				//dllfunc(DLLFunc_Touch,ent,id)
				pev(ent,pev_target,target,31)
				while((ent2 = engfunc(EngFunc_FindEntityByString, ent2, "targetname", target))) {
					dllfunc(DLLFunc_Use,ent2,id)
					client_print(id,print_console,"[AMXX] Jail has been opened")
					return PLUGIN_HANDLED
				}
			}
		}
	}
	client_print(id,print_console,"[AMXX] Error opening jail.Make sure map has one")
	return PLUGIN_HANDLED
}