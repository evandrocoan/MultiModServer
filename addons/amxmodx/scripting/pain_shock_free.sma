/*  AMX Mod X script.
 
    Pain Shock Free Plugin
 
    (c) Copyright 2007, Simon Logic (e-mail: slspam@land.ru)
    This file is provided as is (no warranties).

	Info:
    	When a player is hit he slows down a bit because of a pain shock. 
    	Sometimes it's very annoying, especially when playing dynamic style 
    	mod, e.g. CSDM. This plugin can turn off original player's slowdown 
    	on bullet hit.

	Requirements:
		* CS/CZ mod
		* AMX/X 1.7x or higher
		* Fakemeta module
    
	New cvars:
		* amx_painshockfree <0|1> (default=1)

    History:
    	1.0.0 [2007-12-16]
    	* first release
*/

#include <amxmodx>
#include <fakemeta>

#define MY_PLUGIN_NAME    "Pain Shock Free"
#define MY_PLUGIN_VERSION "1.0.0"
#define MY_PLUGIN_AUTHOR  "Simon Logic"


new bool:g_bRestoreVel
new Float:g_vecVel[3]
new g_cvarPainShockFree
new g_fmPlayerPreThink
new g_fmPlayerPreThink_Post
//-----------------------------------------------------------------------------
public plugin_init()
{
	register_plugin(MY_PLUGIN_NAME, MY_PLUGIN_VERSION, MY_PLUGIN_AUTHOR)

	g_cvarPainShockFree = register_cvar("amx_painshockfree", "1", FCVAR_SERVER)

	g_fmPlayerPreThink = register_forward(FM_PlayerPreThink, "onPlayerPreThink")
	g_fmPlayerPreThink_Post = register_forward(FM_PlayerPreThink, "onPlayerPreThink_Post", 1)
}
//-----------------------------------------------------------------------------
public plugin_end()
{
	if(g_fmPlayerPreThink)
		unregister_forward(FM_PlayerPreThink, g_fmPlayerPreThink)
	if(g_fmPlayerPreThink_Post)
		unregister_forward(FM_PlayerPreThink, g_fmPlayerPreThink_Post, 1)
}
//-----------------------------------------------------------------------------
public onPlayerPreThink(id)
{
	if(get_pcvar_num(g_cvarPainShockFree))
	{
		if(pev_valid(id) && is_user_alive(id) 
		&& (FL_ONGROUND & pev(id, pev_flags)))
		{
			pev(id, pev_velocity, g_vecVel)
			g_bRestoreVel = true
		}
		
		return FMRES_HANDLED
	}
	
	return FMRES_IGNORED
}
//-----------------------------------------------------------------------------
public onPlayerPreThink_Post(id)
{
	if(g_bRestoreVel)
	{
		g_bRestoreVel = false

		if(!(FL_ONTRAIN & pev(id, pev_flags)))
		{
			// NOTE: within DLL PlayerPreThink Jump() function is called;
			// there is a conveyor velocity addiction we should care of

			static iGEnt
			
			iGEnt = pev(id, pev_groundentity)
			if(pev_valid(iGEnt) && (FL_CONVEYOR & pev(iGEnt, pev_flags)))
			{
				static Float:vecTemp[3]
				
				pev(id, pev_basevelocity, vecTemp)
				
				g_vecVel[0] += vecTemp[0]
				g_vecVel[1] += vecTemp[1]
				g_vecVel[2] += vecTemp[2]
			}				

			set_pev(id, pev_velocity, g_vecVel)
			
			return FMRES_HANDLED
		}
	}

	return FMRES_IGNORED
}
//-----------------------------------------------------------------------------
