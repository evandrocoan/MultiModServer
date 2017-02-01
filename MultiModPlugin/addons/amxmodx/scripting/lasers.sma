#include <amxmodx>

#define MAX_TEAMS 4

new sprite
new numwpns
new weapons[32]

new ls_enabled
new ls_line
new ls_pvis
new ls_wpns
new ls_rgb

new numteams
new rgb[3][MAX_TEAMS]

public plugin_init()
{
	register_plugin("Lasers","0.5","Toster v2.1")
	
	ls_enabled = register_cvar("ls_enabled", "1")
	ls_line = register_cvar("ls_line", "1")
	ls_pvis = register_cvar("ls_pvis", "0")
	ls_wpns = register_cvar("ls_wpns", "0;4;6;9;25;29;")
	ls_rgb = register_cvar("ls_rgb", "255 0 0;")
	
	register_clcmd("ls_refresh", "getcvars", ADMIN_KICK)
	register_clcmd("ls_getteam", "getteam", ADMIN_KICK)
	register_clcmd("ls_getwpn", "getwpn", ADMIN_KICK)
	
	getcvars()
}

public getwpn(id)
{
	new clip, ammo
	new w = get_user_weapon(id, clip, ammo)
	
	console_print(id, "[ls] Your current weapon's id: %d", w)
	return PLUGIN_HANDLED
}

public getteam(id)
{
	new t = get_user_team(id)
	console_print(id, "[ls] Your current team's id: %d", t)
	return PLUGIN_HANDLED
}

public getcvars()
{
	getwpns()
	getrgb()
	
	return PLUGIN_HANDLED
}

public getrgb()
{
	new txt[MAX_TEAMS * 16]
	new team[MAX_TEAMS][16]
	new tmp[4]
	
	get_pcvar_string(ls_rgb, txt, 64)
	add(txt, 64, " ")
	
	for(numteams = 0; contain(txt, ";")!=-1; numteams++)
	{
	  strtok(txt, team[numteams], 16, txt, MAX_TEAMS * 16, ';')
	  
	  for(new i=0; i<2; i++)
	  {
	    strtok(team[numteams], tmp, 4, team[numteams], 16, ' ')
	    rgb[i][numteams] = str_to_num(tmp)
	  }
	  trim(team[numteams])
	  rgb[2][numteams] = str_to_num(team[numteams])
	  
	  trim(txt)
	}
}

public getwpns()
{
	new txt[64]
	new wpns[3]
	
	get_pcvar_string(ls_wpns, txt, 64)
	add(txt, 64, " ")
	
	for(numwpns = 0; contain(txt, ";")!=-1; numwpns++)
	{
	  strtok(txt, wpns, 3, txt, 64, ';')
	  weapons[numwpns] = str_to_num(wpns)
	}
}

public plugin_precache() 
{
	sprite = precache_model("sprites/white.spr")
}

public client_PreThink(id)
{
	if(!is_user_alive(id)||get_pcvar_num(ls_enabled)!=1) return PLUGIN_HANDLED
	
	new clip, ammo
	new w = get_user_weapon(id, clip, ammo)
	
	for(new i=0; i<numwpns; i++) if(w == weapons[i]) return PLUGIN_HANDLED
	
	new e[3]
	new t = get_user_team(id)
	
	get_user_origin(id, e, 3)
	
	if(get_pcvar_num(ls_pvis) == 0)message_begin( MSG_BROADCAST,SVC_TEMPENTITY)
	else message_begin( MSG_ONE_UNRELIABLE,SVC_TEMPENTITY, _, id)
	
	if(get_pcvar_num(ls_line) != 0)
	{
	  write_byte (TE_BEAMENTPOINT)
	  write_short(id | 0x1000)
	  write_coord (e[0])
	  write_coord (e[1])
	  write_coord (e[2])
	}
	else
	{
	  write_byte (0)
	  write_coord (e[0] + 1)
	  write_coord (e[1] + 1)
	  write_coord (e[2] + 1)
	  write_coord (e[0] - 1)
	  write_coord (e[1] - 1)
	  write_coord (e[2] - 1)
	}
	
	write_short(sprite)
	write_byte (0)      						
	write_byte (10)     						
	write_byte (1)
	write_byte (5)   						
	write_byte (0)    
	
	if(numteams>=t)  
	{
	  write_byte (rgb[0][t-1]) 	
	  write_byte (rgb[1][t-1])
	  write_byte (rgb[2][t-1])
	}
	else
	{
	  write_byte (rgb[0][0]) 	
	  write_byte (rgb[1][0])
	  write_byte (rgb[2][0])
	}
	
	write_byte (255)     						
	write_byte (10)      						
	message_end()
	
	return PLUGIN_HANDLED
}
