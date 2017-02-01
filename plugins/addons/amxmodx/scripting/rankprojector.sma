#include <amxmodx>
#include <csstats>
#include <csx>

public plugin_init()
{
	register_plugin("Rank Projector","3.0","Addons zz")
	set_task(1.0, "show_timer",0,"",0,"b")
	return PLUGIN_CONTINUE
}

public show_timer(id){

	new as = get_user_frags(1)

	new os = get_user_deaths(1)

	new name[32] 
	get_user_name(1, name, 31) 

	new ping, loss
	get_user_ping(1,ping,loss)
	
	new izStats[8], izBody[8]
	new iRankPos
	
	iRankPos = get_user_stats(1, izStats, izBody)

	set_hudmessage(150, 100, 0, -0.02, 0.25, 0, 0.0, 5.0, 0.2, 0.2, 15)
	show_hudmessage(0,"Nick: %s^nFrags: %d       Rank: %d^nMortes: %d     Ping: %d", name, as,iRankPos,os,ping)
	
	return PLUGIN_CONTINUE
}

public client_putinserver(id){
	set_task(45.0,"My") 
}

public My(id){
	client_print(id, print_console, "Addons zz -- Rank Projector Ativado.")
}
