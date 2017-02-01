/* ATAC Drop
*
* Copyright © 2006-2007, ATAC Team
*
* This file is provided as is (no warranties).
*
*/

#include <amxmodx>
#include <fakemeta>
#include <atac>

#define PLUGIN "Drop"
#define VERSION "1.0"
#define AUTHOR "ATAC Team"

new g_drop[ 33 ]

public plugin_init()
{
	register_plugin( PLUGIN, VERSION, AUTHOR )
	atac_register_punishment()
}

public client_putinserver( id )
{
	g_drop[ id ] = 0
}

public atac_punishment_name( id )
{
	new text[ 64 ]
	formatex( text, 63, "%L", id, "ATAC_DROP_REPEATEDLY" )
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
	g_drop[ killer ] = 0
	set_pev( killer, pev_gravity, 1.0 )
}

exec_punishment( id )
{
	if ( !g_drop[ id ] )
	{
		new origin[ 3 ]
		g_drop[ id ] = 1
		get_user_origin( id, origin )
		set_pev( id, pev_gravity, -2.0 )
		set_pev( id, pev_velocity, Float:{ 0.0, 0.0, 350.0 } )
		rise( id )
	}
}

public rise( id )
{
	if ( is_user_alive( id ) && g_drop[ id ] )
	{
		new origin[ 3 ], Float:fVelocity[ 3 ], Float:fGravity
		new flags = pev( id, pev_flags )
		get_user_origin( id, origin )
		pev( id, pev_velocity, fVelocity )
		pev( id, pev_gravity, fGravity )

		if ( ( flags & FL_ONGROUND ) || ( flags & FL_PARTIALGROUND ) )
		{
			set_pev( id, pev_gravity, -2.0 )
			fVelocity[ 2 ] = 350.0
			set_pev( id, pev_velocity, fVelocity )
		}
		else
			set_pev( id, pev_gravity, 2.0 )

		set_task( 0.1, "rise", id )
	}
	else
		set_pev( id, pev_gravity, 1.0 )
}
