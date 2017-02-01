/* AMX Mod X Script */

/*
  Admin Speed v1.1  -=- by KinSprite , 06/08, 2006
  
  With this plugin , the admin can set Players's running speed.
  
  [Cvars]:   
	    amx_allowspeed <1 or 0>    // 0, turn off speed changing.
	    
	    amx_speedall <1 or 0>      // 1, all players at the same running speed, except special players
	    
	    amx_speedallvalue <Integer: percent of normal speed> 
	                               //all players's running speed value, except special players
	    
  
  [Command]:
            amx_speed <#userid,nick,authorid,@ALL,@TEAM> [ON/OFF] [Integer: percent of normal speed]
	    
	    // to Set special players' speed. 
	    
	    
  [Required Module]:  Fun

  
  [Change Log]:
  
	v1.1:
	    1, fix speed when a sniper rifle is zoomed in/out or a shield is opened/closed
	    2, all players can run at the same percent of normal speed, except special players
	
*/

#include <amxmodx>
#include <amxmisc>
#include <fun>

#define PLUGIN "Admin Speed"
#define VERSION "1.1"
#define AUTHOR "KinSprite"

new g_WpnUsed[33]
new bool:g_hasSpeed[33]
new g_Speed[33]
new g_allowspeed
new g_speedall
new g_speedallvalue

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	register_concmd("amx_speed", "cmdspeed", ADMIN_LEVEL_A, "<#userid,nick,authorid,@ALL,@TEAM> [ON/OFF] [Integer: percent of normal speed] - Set special players' speed")
	register_event("CurWeapon","Change_Wpn","be","1=1")
	register_event("HideWeapon", "Change_WpnState", "b")
	register_logevent("new_round",2,"0=World triggered","1=Round_Start")
	g_allowspeed = register_cvar("amx_allowspeed","1")
	g_speedall = register_cvar("amx_speedall","0")
	g_speedallvalue = register_cvar("amx_speedallvalue","100")
}

public cmdspeed(id,level,cid)
{
	if (!cmd_access(id, level, cid, 2))
		return PLUGIN_HANDLED
		
	if (!get_pcvar_num(g_allowspeed))
	{
		if (id == 0)
			server_print("[AMX Speed] Speed changing is not allowed !")
		else 
			console_print(id, "[AMX Speed] Speed changing is not allowed !")
		return PLUGIN_HANDLED
	}
	
	new arga[32], argb[8], argc[8]
	read_argv(1, arga, 31)
	read_argv(2, argb, 7)
	
	new admin[32], plName[32]
	get_user_name(id, admin, 31)
	
	new activity = get_cvar_num("amx_show_activity")
	
	if (arga[0] == '@')
	{
		new players[32], tName[32]
		new num
		
		if(equali(arga[1],"A") 
		|| equali(arga[1],"ALL")) 
		{
			format(tName, 31, "ALL PlAYERS")
			get_players(players, num)
		}
		else
		{
			if(equali(arga[1],"TERRORIST")
			|| equali(arga[1],"T") 
			|| equali(arga[1],"TERROR") 
			|| equali(arga[1],"TE") 
			|| equali(arga[1],"TER")) 
			{
				format(tName, 31, "TERRORIST")
				get_players(players,num,"e","TERRORIST")
			}
			else
			{
				if(equali(arga[1],"CT")
				|| equali(arga[1],"C") 
				|| equali(arga[1],"COUNTER")) 
				{
					format(tName, 31, "COUNTER-TERRORIST")
					get_players(players,num,"e","CT")
				}
				else
				{
					if (id == 0)
						server_print("[AMX Speed] invalid parameter !")
					else 
						console_print(id, "[AMX Speed] invalid parameter !")
					return PLUGIN_HANDLED
				}
			}
		}
		
		if (num ==0)
		{
			if (id == 0)
				server_print("[AMX Speed] *** No players in this team !")
			else
				console_print(id, "[AMX Speed] *** No players in this team !")
			return PLUGIN_HANDLED
		}
		
		if (equali(argb, "ON"))
		{
			read_argv(3, argc, 7)
			new value = str_to_num(argc)
			value = (value > 0) ? value : 0
			
			for (new i=0; i<num; i++)
			{
				g_hasSpeed[players[i]] = true
				g_Speed[players[i]] = value
				speed_control(players[i], value)
			}
			
			switch(activity)
			{	
				case 1:
				{
					client_print(0,print_chat,"[AMX Speed] ADMIN: set %s to run %d%% of normal speed.", tName, value)
					server_print("[AMX Speed] ADMIN: set %s to run %d%% of normal speed.", tName, value)
				}
				case 2:
				{
					client_print(0,print_chat,"[AMX Speed] ADMIN %s: set %s to run %d%% of normal speed.", admin, tName, value)
					server_print("[AMX Speed] ADMIN %s: set %s to run %d%% of normal speed.", admin, tName, value)
				}
			}
		}
		else
		{
			if (equali(argb, "OFF"))
			{
				for (new i=0; i<num; i++)
				{
					g_hasSpeed[players[i]] = false
					set_user_maxspeed(players[i], 0.0)
				}
				
				switch(activity)
				{	
					case 1:
					{
						client_print(0,print_chat,"[AMX Speed] ADMIN: set %s to run normal speed.", tName)
						server_print("[AMX Speed] ADMIN: set %s to run normal speed.", tName)
					}
					case 2:
					{
						client_print(0,print_chat,"[AMX Speed] ADMIN %s: set %s to run normal speed.", admin, tName)
						server_print("[AMX Speed] ADMIN %s: set %s to run normal speed.", admin, tName)
					}
				}
			}
			else
			{
				if (id == 0)
					server_print("[AMX Speed] The second parameter must be ON or OFF !")
				else
					console_print(id, "[AMX Speed] The second parameter must be ON or OFF !")
			}
		}
	}
	else
	{
		new player = cmd_target(id, arga, 2)
		if (!player)
			return PLUGIN_HANDLED
			
		get_user_name(player, plName, 31)
		
		if (argb[0] == 0)
		{
			if (g_hasSpeed[player])
			{
				if (id == 0)
					server_print("[AMX Speed] PLAYER %s 's speed is %d%% of normal speed.", plName, g_Speed[player])
				else 
					console_print(id, "[AMX Speed] PLAYER %s 's speed is %d%% of normal speed.", plName, g_Speed[player])
			}
			else
			{
				if (id == 0)
					server_print("[AMX Speed] PLAYER %s is at normal speed.", plName)
				else 
					console_print(id, "[AMX Speed] PLAYER %s is at normal speed.", plName)
			}
		}
		else
		{
			if (equali(argb, "ON"))
			{
				g_hasSpeed[player] = true
				read_argv(3, argc, 7)
				new value = str_to_num(argc)
				g_Speed[player] = (value > 0) ? value : 0
				speed_control(player, g_Speed[player])
				
				switch(activity)
				{
					case 1:
					{
						client_print(0,print_chat,"[AMX Speed] ADMIN: set Player %s to run %d%% of normal speed.", plName, g_Speed[player])
						server_print("[AMX Speed] ADMIN: set Player %s to run %d%% of normal speed.", plName, g_Speed[player])
					}
					case 2:
					{
						client_print(0,print_chat,"[AMX Speed] ADMIN %s: set Player %s to run %d%% of normal speed.", admin, plName, g_Speed[player])
						server_print("[AMX Speed] ADMIN %s: set Player %s to run %d%% of normal speed.", admin, plName, g_Speed[player])
					}
				}
				
			}
			else
			{
				if (equali(argb, "OFF"))
				{
					g_hasSpeed[player] = false
					set_user_maxspeed(player, 0.0)    // run normal speed
					
					switch(activity)
					{
						case 1:
						{
							client_print(0,print_chat,"[AMX Speed] ADMIN: set Player %s to run normal speed.", plName)
							server_print("[AMX Speed] ADMIN: set Player %s to run normal speed.", plName)
						}
						case 2:
						{
							client_print(0,print_chat,"[AMX Speed] ADMIN %s: set Player %s to run normal speed.", admin, plName)
							server_print("[AMX Speed] ADMIN %s: set Player %s to run normal speed.", admin, plName)
						}
					}
				}
				else
				{
					if (id == 0)
						server_print("[AMX Speed] The second parameter must be ON or OFF !")
					else 
						console_print(id, "[AMX Speed] The second parameter must be ON or OFF !")
				}
				
			}
		}
	}
	
	return PLUGIN_HANDLED
}

public speed_control(id, percent)
{
	new Float:value = get_user_maxspeed(id) * percent / 100.0
	value = (value > 0.1) ? value : 0.1
	set_user_maxspeed(id, value)
}

public Change_Wpn(id)
{
	if (!get_pcvar_num(g_allowspeed) || (!g_hasSpeed[id] && !get_pcvar_num(g_speedall)))
		return PLUGIN_CONTINUE
		
	new iWpnNum = read_data(2)
	
	if (iWpnNum != g_WpnUsed[id])
	{
		if (g_hasSpeed[id])
		{
			 speed_control(id, g_Speed[id])
		}
		else
		{
			speed_control(id, get_pcvar_num(g_speedallvalue))
		}
		
		g_WpnUsed[id] = iWpnNum
	}
	
	return PLUGIN_CONTINUE
}

public Change_WpnState(id)
{
	if (!get_pcvar_num(g_allowspeed) || (!g_hasSpeed[id] && !get_pcvar_num(g_speedall)))
		return PLUGIN_CONTINUE
		
	//new iWpnNum = get_user_weapon(id)
	//g_WpnUsed[id] = iWpnNum
	
	if (g_hasSpeed[id])
	{
		speed_control(id, g_Speed[id])
	}
	else
	{
		speed_control(id, get_pcvar_num(g_speedallvalue))
	}	
	
	return PLUGIN_CONTINUE
}

public new_round()
{
	if (get_pcvar_num(g_allowspeed))
		set_task(0.2, "reset_speed")
}

public reset_speed()
{
	new players[32]
	new num
	get_players(players, num)
	for (new i=0; i<num; i++)
	{
		if (g_hasSpeed[players[i]])
		{
			speed_control(players[i], g_Speed[players[i]])
		}
		else
		{
			if (get_pcvar_num(g_speedall))
			{
				speed_control(players[i], get_pcvar_num(g_speedallvalue))	
			}
		}
	}
}

public client_putinserver(id)
{
	g_hasSpeed[id] = false
	return PLUGIN_CONTINUE
}
