/* ATAC Glow
*
* Copyright © 2006-2007, ATAC Team
*
* This file is provided as is (no warranties).
*
*/

#include <amxmodx>
#include <fakemeta>
#include <atac>

#define PLUGIN "Glow"
#define VERSION "1.0"
#define AUTHOR "ATAC Team"

new g_glow[ 33 ]

public plugin_init()
{
	register_plugin( PLUGIN, VERSION, AUTHOR )
	atac_register_punishment()
}

public client_putinserver( id )
{
	g_glow[ id ] = 0
}

public atac_punishment_name( id )
{
	new text[ 64 ]
	formatex( text, 63, "%L", id, "ATAC_GLOW" )
	return engfunc( EngFunc_AllocString, text )
}

public atac_player_punish( killer, victim )
{
	exec_punishment( killer )
	return ATAC_HOOK_RESET
}

public atac_player_spawn( killer, victim )
{
	exec_punishment( killer )
	return ATAC_HOOK_RESET
}

public atac_player_reset( killer, victim )
{
	g_glow[ killer ] = 0
	set_player_rendering( killer, kRenderFxGlowShell, 0, 0, 0, kRenderTransAlpha, 255, 0 )
}

exec_punishment( id )
{
	if ( !g_glow[ id ] )
	{
		g_glow[ id ] = 1
		set_player_rendering( id, kRenderFxGlowShell, 255, 0, 255, kRenderTransAlpha, 255, 1 )
	}
}

set_player_rendering( id, renderfx, red, green, blue, rendermode, renderamt, alive )
{
	if ( is_user_connected( id ) && ( is_user_alive( id ) && alive == 1 ) || alive == 0 )
	{
		new Float:rendercolor[ 3 ]
		set_pev( id, pev_renderfx, renderfx )
		rendercolor[ 0 ] = float( red )
		rendercolor[ 1 ] = float( green )
		rendercolor[ 2 ] = float( blue )
		set_pev( id, pev_rendercolor, rendercolor )
		set_pev( id, pev_rendermode, rendermode )
		set_pev( id, pev_renderamt, float( renderamt ) )
	}
}
