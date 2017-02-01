/* ATAC Jail
*
* Copyright © 2006-2007, ATAC Team
*
* This file is provided as is (no warranties).
*
*/

#include <amxmodx>
#include <amxmisc>
#include <fakemeta>
#include <atac>

#define PLUGIN "Jail"
#define VERSION "1.1"
#define AUTHOR "ATAC Team"

new g_jail[ 33 ]
new StoreName[ 33 ][ 32 ]
new Float:JailOrigin[ 33 ][ 3 ]
new map_cors_pre
new Float:map_cors_origin[ 3 ]
new gCVARJailTime

public plugin_init()
{
	register_plugin( PLUGIN, VERSION, AUTHOR )
	map_cors_pre = map_cors_present( map_cors_origin )

	if ( !map_cors_pre )
		pause( "ade", PLUGIN )
	else
	{
		atac_register_punishment()
		gCVARJailTime = register_cvar( "atac_jail_time", "45" )
	}
}

public client_putinserver( id )
{
	g_jail[ id ] = 0
}

public atac_punishment_name( id )
{
	new text[ 64 ]
	formatex( text, 63, "%L", id, "ATAC_JAIL", get_pcvar_num( gCVARJailTime ) )
	return engfunc( EngFunc_AllocString, text )
}

public atac_player_punish( killer, victim )
{
	set_task( 1.0, "exec_punishment", killer )
	return ATAC_HOOK_RESET
}

public atac_player_spawn( killer, victim )
{
	set_task( 1.0, "exec_punishment", killer )
	return ATAC_HOOK_RESET
}

public atac_player_reset( killer, victim )
{
	g_jail[ killer ] = 0
	set_user_info( killer, "name", StoreName[ killer ] )
}

public exec_punishment( id )
{
	if ( !g_jail[id] )
	{
		new name[ 32 ], JailName[ 32 ]
		g_jail[ id ] = 1
		get_user_name( id, name, 31 )
		StoreName[ id ] = name
		formatex( JailName, 31, "*JAIL* %s", StoreName[ id ] )
		set_user_info( id, "name", JailName )

		drop_weapons( id )
		pev( id, pev_origin, JailOrigin[ id ] ) // Teleport
		JailOrigin[ id ][ 2 ] += 5
		set_pev( id, pev_origin, map_cors_origin )
		set_task( float( get_pcvar_num( gCVARJailTime ) ), "unjail", id )
	}
}

public unjail( id )
{
	if ( is_user_alive( id ) && g_jail[ id ] )
	{
		set_user_info( id, "name", StoreName[ id ] )
		set_pev( id, pev_origin, JailOrigin[ id ] )
		g_jail[ id ] = 0
	}
}

map_cors_present( Float:maporigin[ 3 ] )
{
	new filename[ 128 ], atacpath[ 64 ]
	get_configsdir( atacpath, 63 )
	formatex( atacpath, 63, "%s/atac", atacpath )
	formatex( filename, 127, "%s/atac.cor", atacpath )

	if ( file_exists( filename ) )
	{
		new readdata[ 64 ]
		new currentmap[ 32 ]
		get_mapname( currentmap, 31 )
		new map[ 32 ], x[ 16 ], y[ 16 ], z[ 16 ], len

		for ( new i; i < 128 && read_file( filename, i, readdata, 63, len ); ++i )
		{
			parse( readdata, map, 31, x, 15, y, 15, z, 15 )

			if ( equal( map, currentmap ) )
			{
				maporigin[ 0 ] = str_to_float( x )
				maporigin[ 1 ] = str_to_float( y )
				maporigin[ 2 ] = str_to_float( z )
				return PLUGIN_HANDLED
			}
		}
	}

	return PLUGIN_CONTINUE
}

drop_weapons(id)
{
	new iwpn, iwpns[ 32 ], nwpn[ 32 ]
	get_user_weapons( id, iwpns, iwpn )

	for ( new a; a < iwpn; ++a )
	{
		get_weaponname( iwpns[ a ], nwpn, 31 )
		engclient_cmd( id, "drop", nwpn )
	}
}
