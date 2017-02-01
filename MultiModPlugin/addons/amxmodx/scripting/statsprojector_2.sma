#include <amxmodx>
#include <csstats>
#include <csx>

public plugin_init()
{
	register_plugin("Stats Projector 2","2.1","Addons zz")
	set_task(1.0, "show_timer",0,"",0,"b")
	return PLUGIN_CONTINUE
}

public show_timer(id){

	new ping, loss
	get_user_ping(1,ping,loss)
	
	new izStats[8], izBody[8]
	new iRankPos
	
	new name[32] 
	get_user_name(1, name, 31) 
	
	new as = get_user_frags(1)

	new os = get_user_deaths(1)
	
	iRankPos = get_user_stats(1, izStats, izBody)

	new CurrentTim[19] 
	get_time("%d/%m/%Y", CurrentTim, 18)
	
	new CurrentTime[9] 
	get_time("%H:%M:%S", CurrentTime, 8)
	
	new nextmap[32]
	get_cvar_string("amx_nextmap",nextmap,31)
	
	new timeleft = get_timeleft()
	
	new Currentmap[32]
	get_mapname(Currentmap, 31)
	
	set_hudmessage(150, 100, 0, -0.02, 0.25, 0, 0.0, 5.0, 0.2, 0.2, 15)
	show_hudmessage(0,"Addons zz^n-------------------------------^nData: %s^nHora: %s^nMapa Atual: %s^n-------------------------------^nTempo Restante: %d:%02d^nProximo Mapa: %s^n-------------------------------^nNick: %s^nFrags: %d       Rank: %d^nMortes: %d     Ping: %d^n-------------------------------^nwww.addons.zz.mu", CurrentTim, CurrentTime, Currentmap, timeleft / 60, timeleft % 60, nextmap, name, as, iRankPos, os,ping)
	
	return PLUGIN_CONTINUE
}

public client_putinserver(id){
	set_task(40.0,"My") 
}

public My(id){
	client_print(id, print_console, "Addons zz -- Stats Projector Ativado.")
}
