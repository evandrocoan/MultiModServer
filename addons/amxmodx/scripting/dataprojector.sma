#include <amxmodx>


public plugin_init()
{
	register_plugin("Data Projector","4.0","Addons zz")
	set_task(1.0, "show_timer",0,"",0,"b")
	return PLUGIN_CONTINUE
}

public show_timer(){
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
	show_hudmessage(0,"Data: %s^nHora: %s^nMapa: %s^n^nTempo Restante: %d:%02d^nProximo Mapa: %s", CurrentTim, CurrentTime, Currentmap, timeleft / 60, timeleft % 60, nextmap)
	return PLUGIN_CONTINUE
}

public client_putinserver(id){
	set_task(50.0,"My") 
}

public My(id){
	client_print(id, print_console, "Addons zz -- Data Projector Ativado!")
}
