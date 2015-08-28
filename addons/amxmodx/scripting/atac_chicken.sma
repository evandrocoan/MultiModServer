/* ATAC Chicken
*
* Copyright © 2006-2007, ATAC Team
*
* This file is provided as is (no warranties).
*
*/

#include <amxmodx>
#include <fakemeta>
#include <atac>

#define PLUGIN "Chicken"
#define VERSION "1.0"
#define AUTHOR "ATAC Team"

new g_chicken[ 33 ]

public plugin_init()
{
	register_plugin( PLUGIN, VERSION, AUTHOR )

	if ( !cvar_exists( "chicken_version" ) )
		pause( "ade", PLUGIN )
	else
		atac_register_punishment()
}

public client_putinserver( id )
{
	g_chicken[ id ] = 0
}

public atac_punishment_name(id)
{
	new text[ 64 ]
	formatex( text, 63, "%L", id, "ATAC_CHICKEN" )
	return engfunc( EngFunc_AllocString, text )
}

public atac_player_punish( killer, victim )
{
	exec_punishment( killer )
	return ATAC_HOOK_RESET
}

public atac_player_spawn( killer, victim )
{
	if ( g_chicken[ killer ] )
	{
		g_chicken[ killer ] = 0
		server_cmd( "c_unchicken #%i", get_user_userid( killer ) )
	}
	else
	{
		exec_punishment( killer )
		return ATAC_HOOK_RESET
	}

	return ATAC_HOOK_CONTINUE
}

public atac_player_reset( killer, victim )
{
	return ATAC_HOOK_SPAWNED
}

exec_punishment( id )
{
	if ( !g_chicken[ id ] )
	{
		g_chicken[ id ] = 1
		server_cmd( "c_chicken #%i", get_user_userid( id ) )
	}
}
