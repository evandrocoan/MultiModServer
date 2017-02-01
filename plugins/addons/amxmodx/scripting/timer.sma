// Timer / Nextmap 

#include <amxmod> 

public show_timer(){ 
new nextmap[32] 
get_cvar_string("amx_nextmap",nextmap,31) 
new timeleft = get_timeleft() 
set_hudmessage(150, 100, 0, -0.02, 0.25, 0, 0.0, 5.0, 0.2, 0.2, 15) 
new players[32], inum 
get_players(players,inum,"","") 
for(new o = 0 ;o < inum ;++o){ 
if (!(get_user_flags(players[o])&ADMIN_RCON)){ 
show_hudmessage(players[o],"Time remaining: %d:%02d^nNext map: %s",timeleft / 60, timeleft % 60,nextmap) 
} else {
new sfps[32]
get_cvar_string("server_fps",sfps,31)  
show_hudmessage(players[o],"Time remaining: %d:%02d^nNext map: %s^nServer FPS: %s",timeleft / 60, timeleft %60, nextmap, sfps) 
}
}  
return PLUGIN_CONTINUE 
} 

public plugin_init(){ 
register_plugin("Timer/Nextmap/Server FPS","0.1","hakcenter") 
set_task(1.0, "show_timer",0,"",0,"b") 
return PLUGIN_CONTINUE 
}
