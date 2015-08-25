
/* AMX Mod script.
*
* (c) Copyright 2002, W@lker /Yakutsk,Russia/
* This file is provided as is (no warranties).
*
*/

#include <amxmod>

// file to read descriptions from 
new ipdesc[32] = "addons/amx/ipdesc.ini" 


public amx_showip(id){
new userip[16]
new name[64]
new players[32],inum
new buffor[3000]
new header[50]
new temp[150]

new arg[1]
new team

read_args(arg,1)
team=strtonum(arg)

switch(team){
case 1: {
header="IP List - Terrorists Forces"
get_players(players,inum,"e","TERRORIST")
}
case 2: {
header="IP List - CT Forces"
get_players(players,inum,"e","CT")
}
default:{
header="IP List"
get_players(players,inum)
}
	}
//
client_print(id,print_console,"%s",header)

format(buffor,100,"%-25.24s %-16.15s %s","Name","IP","Description^n____________________________________^n")


for(new i = 0; i < inum; ++i) {
    temp=""	
    get_user_ip(players[i],userip,16,1) 
    get_user_name(players[i],name,64) 
    if (strlen(name)>20) {
		copy(name,17,name)  	
    		add(name,64,"...")
			}	
    new IPD[32]
    findip(userip,IPD)   
    format(temp,150,"%-25.24s %-16.15s %s^n",name,userip,IPD)
    add(buffor,3000,temp)	
    client_print(id,print_console,"%-32.31s %-16.15s %s",name,userip,IPD)
}
show_motd(id,buffor,header)
return PLUGIN_CONTINUE
}

public getdesc(sip[16],sdesc[32]){
if (file_exists(ipdesc)) 
	{
new data[128]
new stextsize = 0
new line = 0
new ip[16]
new desc[32]
while((line=read_file(ipdesc,line,data,192,stextsize))!=0) 
		{ /*while*/
if (contain(data,"//") == -1)   {/*skip comments*/
parse(data,ip,16,desc,32)
if (equal(sip,ip)) {
sdesc=desc
return 1
		    }
				} /*skip comments*/
		} /*while*/
	} else log_message("IP Descriptions file not found!")  
sdesc=""
return 0
}

public findip(sip[16],sdesc[32]){
new ipsubnet[16]
new RValue=0
new uip[16]
new ippart1[12]
new ippart2[12]
new ippart3[12]
new ippart4[12]

/*Calculating subnet*/
copy(uip, 16, sip) 
while(replace(uip, 16, ".", " ")){}
parse(uip, ippart1,12,ippart2,12,ippart3,12,ippart4,12) 
ipsubnet=""
add(ipsubnet,16,ippart1)
add(ipsubnet,16,".")
add(ipsubnet,16,ippart2)
add(ipsubnet,16,".")
add(ipsubnet,16,ippart3)
/*Calculating subnet*/

RValue = getdesc(sip , sdesc);
if (RValue==0) RValue = getdesc(ipsubnet , sdesc)
return RValue
}

public client_connect(id){
new userip[16]
new name[32]
new IPD[32]
get_user_ip(id,userip,16,1) 
get_user_name(id,name,32)
findip(userip, IPD)
//server_cmd("say [AMX] %s (%s , %s) trying to connect",name,userip,IPD)
client_print(0,print_chat," %s (%s,%s) Connectou-se ao servidor!",name,userip,IPD);
return PLUGIN_CONTINUE
}  

public admin_ipban(id)
{
/*	if (!(get_user_flags(id)&ADMIN_BAN)){
		client_print(id,print_console,"[AMX] You have no access to that command")
		return PLUGIN_HANDLED
	}*/
	if (read_argc() < 3){
		client_print(id,print_console,"[AMX] Usage: amx_ipban < minutes > < part of nick >")
		return PLUGIN_HANDLED
	}

	new arg[32]
	read_argv(2,arg,32)
	new player = find_player("b",arg)

	if (player)	{
		if (get_user_flags(player)&ADMIN_IMMUNITY){
			client_print(id,print_console,"[AMX] The player has immunity")
			return PLUGIN_HANDLED
		}
		else if (is_user_bot(player))	{
			client_print(id,print_console,"[AMX] Bot can't be banned")
			return PLUGIN_HANDLED
		}

		new minutes[32]
		read_argv(1,minutes,32)
		new ip[16],name2[32],ip2[16],name[32]
		get_user_ip(player,ip2,16,1)
		get_user_ip(id,ip,16,1)
		get_user_name(player,name2,32)
		get_user_name(id,name,32)
		new IPD[32]
		findip(ip2, IPD)
		if(containi(IPD,"*") == -1) { 
		log_to_file("addons/amx/admin.log","^"%s<%d><%s><>^" ipban ^"%s<%d><%s><>^" (minutes ^"%s^")",
			name,get_user_userid(id),ip, name2,get_user_userid(player),ip2,minutes )

		server_cmd("addip %s %s;writeip",minutes,ip2)

		client_print(id,print_console,"[AMX] Client ^"%s^" banned",name2)
					    } /*IPD No Contain - * */
		else {
		client_print(id,print_console,"[AMX] Client ^"%s^" has ban immunity. - Exec Quit",name2)
		//server_cmd("kick #%d",player)
//		client_cmd(player,"spk sound/misc/cow"); 
//		client_cmd(player,"unbindall"); 
		client_cmd(player,"quit"); 
		     }	
	}
	else {
		client_print(id,print_console,"[AMX] Client with that part of nick not found")
	}

	return PLUGIN_HANDLED
}
 

public plugin_init() {
	register_plugin("Show IP","0.8","W@lker's Showip")
	register_clcmd("amx_showip","amx_showip")
	register_clcmd("amx_ipban","admin_ipban",ADMIN_BAN,"< minutes > < part of nick >")
	return PLUGIN_CONTINUE
}

