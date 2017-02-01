/* ATAC Rocket
*
* Copyright © 2006-2007, ATAC Team
*
* This file is provided as is (no warranties).
*
*/

#include <amxmodx>
#include <fakemeta>
#include <atac>

#define PLUGIN "Rocket"
#define VERSION "1.0"
#define AUTHOR "ATAC Team"

new g_rocket[ 33 ]
new g_rocket_count[ 33 ]
new gmsgScreenShake

new g_trail
new g_mflash
new g_white
new g_smoke

public plugin_precache()
{
	precache_sound( "ambience/thunder_clap.wav" )
	precache_sound( "weapons/rocketfire1.wav" )
	precache_sound( "weapons/rocket1.wav" )

	g_trail = precache_model( "sprites/smoke.spr" )
	g_mflash = precache_model( "sprites/muzzleflash.spr" )
	g_white = precache_model( "sprites/white.spr" )
	g_smoke = precache_model( "sprites/steam1.spr" )
}

public plugin_init()
{
	register_plugin( PLUGIN, VERSION, AUTHOR )
	atac_register_punishment()
	gmsgScreenShake = get_user_msgid( "ScreenShake" )
}

public client_putinserver( id )
{
	g_rocket[ id ] = 0
	g_rocket_count[ id ] = 0
}

public atac_punishment_name( id )
{
	new text[ 64 ]
	formatex( text, 63, "%L", id, "ATAC_ROCKET" )
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
	g_rocket[ killer ] = 0
	g_rocket_count[ killer ] = 0
	emit_sound( killer, CHAN_VOICE, "weapons/rocket1.wav", 0.0, 0.0, ( 1 << 5 ), PITCH_NORM )
	set_pev( killer, pev_maxspeed, 1.0 )
	set_pev( killer, pev_gravity, 1.0 )
}

exec_punishment( id )
{
	if ( !g_rocket[ id ] )
	{
		new origin[ 3 ]
		get_user_origin( id, origin )

		g_rocket[ id ] = 1
		g_rocket[ id ] = origin[ 2 ] + 576 // 8 players height
		emit_sound( id, CHAN_VOICE, "weapons/rocketfire1.wav", 1.0, 0.5, 0, PITCH_NORM )
		set_pev( id, pev_maxspeed, 1.2 )
		set_task( 0.7, "rocket_sfx", id )
	}
}

public rocket_sfx( id )
{
	if ( is_user_alive( id ) )
	{
		set_pev( id, pev_gravity, -0.5 )
		set_pev( id, pev_velocity, Float:{ 0.0, 0.0, 350.0 } )
		emit_sound( id, CHAN_VOICE, "weapons/rocket1.wav", 1.0, 0.5, 0, PITCH_NORM )
		rocket_rise( id )
		
		message_begin( MSG_ONE_UNRELIABLE, gmsgScreenShake, _, id )
		write_short( 1 << 15 ) // shake amount
		write_short( 1 << 15 ) // shake lasts this long
		write_short( 1 << 15 ) // shake noise frequency
		message_end()
		
		message_begin( MSG_BROADCAST, SVC_TEMPENTITY ) // Rocket Trail
		write_byte( TE_BEAMFOLLOW )
		write_short( id )
		write_short( g_trail )
		write_byte( 30 )
		write_byte( 2 )
		write_byte( 250 )
		write_byte( 250 )
		write_byte( 250 )
		write_byte( 250 )
		message_end()
	}
}

public rocket_rise( id )
{
	new origin[ 3 ]
	get_user_origin( id, origin )
	draw_fire( origin )
	
	if ( g_rocket[ id ] <= origin[ 2 ]  || g_rocket_count[ id ] > 10 )
		rocket_explode( id )
	else if ( g_rocket[ id ] != 0 )
	{
		g_rocket_count[ id ]++
		set_task( 0.1, "rocket_rise", id )
	}
}

public rocket_explode( id )
{
	message_begin( MSG_BROADCAST, SVC_TEMPENTITY )
	write_byte( TE_KILLBEAM )
	write_short( id )
	message_end()
	
	player_slay( id )
	emit_sound( id, CHAN_VOICE, "weapons/rocket1.wav", 0.0, 0.0, ( 1 << 5 ), PITCH_NORM )
	set_pev( id, pev_maxspeed, 1.0 )
	set_pev( id, pev_gravity, 1.0 )
}

public player_slay( id )
{
	if ( is_user_alive( id ) )
	{
		new origin[ 3 ]
		get_user_origin( id, origin )
		origin[ 2 ] = origin[ 2 ] - 26

		message_begin( MSG_BROADCAST, SVC_TEMPENTITY, origin ) // Blast Circles
		write_byte( TE_BEAMCYLINDER )
		write_coord( origin[ 0 ] )
		write_coord( origin[ 1 ] )
		write_coord( origin[ 2 ] + 16 )
		write_coord( origin[ 0 ] )
		write_coord( origin[ 1 ] )
		write_coord( origin[ 2 ] + 1936 )
		write_short( g_white )
		write_byte( 0 )
		write_byte( 0 )
		write_byte( 2 )
		write_byte( 16 )
		write_byte( 0 )
		write_byte( 188 )
		write_byte( 220 )
		write_byte( 255 )
		write_byte( 255 )
		write_byte( 0 )
		message_end()

		message_begin( MSG_BROADCAST, SVC_TEMPENTITY ) // Explosion2
		write_byte( TE_EXPLOSION2 )
		write_coord( origin[ 0 ] )
		write_coord( origin[ 1 ] )
		write_coord( origin[ 2 ] )
		write_byte( 188 )
		write_byte( 10 )
		message_end()

		smoke_effect( origin, 2 ) // Smoke
		user_kill( id, 1 )
	}
}

draw_fire( origin[ 3 ] )
{
	message_begin( MSG_BROADCAST, SVC_TEMPENTITY )
	write_byte( TE_SPRITE )
	write_coord( origin[ 0 ] )
	write_coord( origin[ 1 ] )
	write_coord( origin[ 2 ] )
	write_short( g_mflash )
	write_byte( 20 )
	write_byte( 200 )
	message_end()

	smoke_effect( origin, 20 ) // Smoke
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
