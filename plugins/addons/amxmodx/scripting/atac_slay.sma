/* ATAC Slay
*
* Copyright © 2006-2007, ATAC Team
*
* This file is provided as is (no warranties).
*
*/

#include <amxmodx>
#include <fakemeta>
#include <atac>

#define PLUGIN "Slay"
#define VERSION "1.1"
#define AUTHOR "ATAC Team"

new g_light
new g_smoke

public plugin_precache()
{
	precache_sound( "ambience/thunder_clap.wav" )
	g_smoke = precache_model( "sprites/steam1.spr" )
	g_light = precache_model( "sprites/lgtning.spr" )
}

public plugin_init()
{
	register_plugin( PLUGIN, VERSION, AUTHOR )
	atac_register_punishment()
}

public atac_punishment_name( id )
{
	new text[ 64 ]
	formatex( text, 63, "%L", id, "ATAC_SLAY" )
	return engfunc( EngFunc_AllocString, text )
}

public atac_player_punish( killer, victim )
{
	exec_punishment( killer )
}

public atac_player_spawn( killer, victim )
{
	exec_punishment( killer )
}

exec_punishment( id )
{
	if ( is_user_alive( id ) )
	{
		new origin[ 3 ]
		get_user_origin( id, origin )
		origin[ 2 ] = origin[ 2 ] - 26

		message_begin( MSG_BROADCAST, SVC_TEMPENTITY ) // Lightning
		write_byte( TE_BEAMPOINTS )
		write_coord( origin[ 0 ] )
		write_coord( origin[ 1 ] )
		write_coord( origin[ 2 ] )
		write_coord( origin[ 0 ] + 150 )
		write_coord( origin[ 1 ] + 150 )
		write_coord( origin[ 2 ] + 400 )
		write_short( g_light )
		write_byte( 1 )
		write_byte( 5 )
		write_byte( 2 )
		write_byte( 20 )
		write_byte( 30 )
		write_byte( 200 )
		write_byte( 200 )
		write_byte( 200 )
		write_byte( 200 )
		write_byte( 200 )
		message_end()

		message_begin( MSG_PVS, SVC_TEMPENTITY, origin ) // Sparks
		write_byte( TE_SPARKS )
		write_coord( origin[ 0 ] )
		write_coord( origin[ 1 ] )
		write_coord( origin[ 2 ] )
		message_end()

		smoke_effect( origin, 10 ) // Smoke
		emit_sound( id, CHAN_AUTO, "ambience/thunder_clap.wav", 1.0, ATTN_NORM, 0, PITCH_NORM )
		user_kill( id, 1 )
	}
}

smoke_effect( origin[ 3 ], amount )
{
	message_begin( MSG_BROADCAST, SVC_TEMPENTITY )
	write_byte( TE_SMOKE )
	write_coord( origin[ 0 ] )
	write_coord( origin[ 1 ] )
	write_coord( origin[ 2 ] )
	write_short( g_smoke )
	write_byte( amount )
	write_byte( 10 )
	message_end()
}
