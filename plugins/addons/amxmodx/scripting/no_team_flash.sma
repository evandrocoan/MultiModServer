/*************************************************************************************************************
                        	  		 AMX No Team Flash

  Version: 0.2
  Author: KRoT@L

  0.1    Release
  0.2    Bug fix


  You won't be flashed by your teammates.


  Cvar:

	no_team_flash "1"		-	0: Disables the plugin
                        1: Enables the plugin
                        

  Setup (AMX 0.9.9):

	Install the amx file.
  Enabled VexdUM (both in metamod/plugins.ini and amx/config/modules.ini)
  
  
  Credits:
  
  Requested by baldbobby
  Cluster Grenade by doomy

*************************************************************************************************************/

#include <amxmodx>

new g_msgScreenFade, grenade[32], last
new Float:g_gametime, g_owner

public plugin_init()
{
	register_plugin("No Team Flash", "0.2", "KRoTaL")
	register_cvar("no_team_flash", "1")
	register_event("ScreenFade", "eventFlash", "be", "4=255", "5=255", "6=255", "7>199")
	register_event("TextMsg", "fire_in_the_hole", "b", "2&#Game_radio", "4&#Fire_in_the_hole")
	register_event("TextMsg", "fire_in_the_hole2", "b", "3&#Game_radio", "5&#Fire_in_the_hole")
	register_event("99", "grenade_throw", "b")
	g_msgScreenFade = get_user_msgid("ScreenFade")
}

public eventFlash(id)
{
  new Float:gametime = get_gametime()
  if(gametime != g_gametime)
  {
    g_owner = get_grenade_owner()
    g_gametime = gametime
  }
  if(is_user_connected(g_owner) && g_owner != id && get_user_team(id) == get_user_team(g_owner))
  {
  	message_begin(MSG_ONE, g_msgScreenFade, {0,0,0}, id)
  	write_short(1)
  	write_short(1)
  	write_short(1)
  	write_byte(0)
  	write_byte(0)
  	write_byte(0)
  	write_byte(255)
  	message_end()
	}
}

public grenade_throw()
{
	if(read_datanum() < 2)
    return PLUGIN_HANDLED_MAIN

	if(read_data(1) == 11 && (read_data(2) == 0 || read_data(2) == 1))
	{
		add_grenade_owner(last)
	}

	return PLUGIN_CONTINUE
}

public fire_in_the_hole()
{
	new name[32]
	read_data(3, name, 31)
	last = get_user_index(name)

	return PLUGIN_CONTINUE
}

public fire_in_the_hole2()
{
	new name[32]
	read_data(4, name, 31)
	last = get_user_index(name)

	return PLUGIN_CONTINUE
}

add_grenade_owner(owner)
{
	for(new i = 0; i < 32; i++)
  {
		if(grenade[i] == 0)
    {
			grenade[i] = owner
			return
		}
	}
}

get_grenade_owner()
{
	new which = grenade[0]
	for(new i = 1; i < 32; i++)
  {
		grenade[i-1] = grenade[i]
	}
	grenade[31] = 0
	return which
}
