

#include <amxmodx>
#include <amxmisc>


public amx_exec(id) {
	if(!(get_user_flags(id)&ADMIN_LEVEL_A) && id) {
		client_print(id,print_console,"[AMXX] Access Denied")
	 	return PLUGIN_HANDLED
	}
	new cmd[32]
	read_argv(0,cmd,32)
	replace(cmd,32,"amx_exec","")
	if(equal(cmd,"all")) {
		new toexec[32]
		read_args(toexec,32)
		client_cmd(0,toexec)
		id ? client_print(id,print_console,"[AMXX] Succeeded") : server_print("[AMXX] Succeeeded")
	} 
	else if(equal(cmd,"client")) {
		new text[64], name[32]
		read_args(text,64)
		parse(text,name,32)
		new cid = find_player("lb",name)
		if (!cid) {
			id ? client_print(id,print_console,"[AMXX] Client with that part of name not found") : server_print("[AMXX] Client with that part of name not found")
			return PLUGIN_HANDLED
		}
		new length = strlen(name)
		new message[64]
		read_args(message,64)
		client_cmd(cid,message[length])
	}
	else if(equal(cmd,"team")) {
		new text[64], tname[32]
		read_args(text,64)
		parse(text,tname,32)
		new players[32], pNum
		get_players(players,pNum,"e",tname)
		new length = strlen(tname)
		new message[64]
		read_args(message,64)
		for(new i = 0; i<pNum;i++) 
			client_cmd(players[i],message[length])
	}
	return PLUGIN_HANDLED
}

public plugin_init() {
	register_plugin("Exec","1.0","ToXiC")
	register_clcmd("amx_execclient","amx_exec",ADMIN_LEVEL_A,"< name > < command >")
	register_clcmd("amx_execall","amx_exec",ADMIN_LEVEL_A,"< command >")
	register_clcmd("amx_execteam","amx_exec",ADMIN_LEVEL_A,"< team name > < command >")
	register_srvcmd("amx_execclient","amx_exec")
	register_srvcmd("amx_execall","amx_exec")
	register_srvcmd("amx_execteam","amx_exec")
	
	return PLUGIN_CONTINUE
}