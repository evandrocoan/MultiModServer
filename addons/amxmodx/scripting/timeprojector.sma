/*
*  AMX Mod script. 
* 
* (c) Copyright 2003, ST4life 
* This file is provided as is (no warranties). 
*/

#include <amxmod>

/*
* TimeProjector displays the remaining time and the next map on the top right corner of the client
* display as a hudmessage.
*
* History:
*
* v0.1: - first release
*/


public show_timer(){
	new nextmap[32]
	get_cvar_string("amx_nextmap",nextmap,31)
	new timeleft = get_timeleft()
	set_hudmessage(150, 100, 0, -0.02, 0.25, 0, 0.0, 5.0, 0.2, 0.2, 15)
	show_hudmessage(0,"Time remaining: %d:%02d^nNext map: %s",timeleft / 60, timeleft % 60,nextmap)
	return PLUGIN_CONTINUE
}

public plugin_init()
{
	register_plugin("TimeProjector","0.1","ST4life")
	set_task(1.0, "show_timer",0,"",0,"b")
	return PLUGIN_CONTINUE
}
