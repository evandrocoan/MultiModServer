/* ATAC Fire
*
* Copyright © 2006-2007, ATAC Team
*
* This file is provided as is (no warranties).
*
*/

#include <amxmodx>
#include <fakemeta>
#include <atac>

#define PLUGIN "Fire"
#define VERSION "1.0"
#define AUTHOR "ATAC Team"

new g_fire[ 33 ]
new maxplayers

new g_mflash
new g_smoke
new g_plugin
new gCVARFireMode

public plugin_precache()
{
	precache_sound( "ambience/flameburst1.wav" )
	precache_sound( "scientist/scream07.wav" )
	precache_sound( "scientist/scream21.wav" )

	g_mflash = precache_model( "sprites/muzzleflash.spr" )
	g_smoke = precache_model( "sprites/steam1.spr" )
}

public plugin_init()
{
	register_plugin( PLUGIN, VERSION, AUTHOR )
	g_plugin = atac_register_punishment()
	gCVARFireMode = register_cvar( "atac_fire_mode", "0" )
	register_forward( FM_Touch, "Touch" )
	maxplayers = get_maxplayers()
}

public client_putinserver( id )
{
	g_fire[ id ] = 0
}

public atac_punishment_name( id )
{
	new text[ 64 ]
	formatex( text, 63, "%L", id, "ATAC_FIRE" )
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
	g_fire[ killer ] = 0

	if ( !is_user_alive( killer ) )
		emit_sound( killer, CHAN_AUTO, "scientist/scream21.wav", 1.0, ATTN_NORM, 0, PITCH_HIGH )
}

exec_punishment( id )
{
	if ( !g_fire[ id ] )
	{
		g_fire[ id ] = 1
		fire_effects( id )
		fire_damage( id )
	}
}

public fire_effects( id )
{
	if ( is_user_alive( id ) && g_fire[ id ] )
	{
		new origin[ 3 ]
		get_user_origin( id, origin )
		draw_fire( origin )
		set_task( 0.2, "fire_effects", id )
	}
}

public fire_damage( id )
{
	if ( is_user_alive( id ) && g_fire[ id ] )
	{
		new health = get_user_health( id )
		set_pev( id, pev_dmg_inflictor, 0 ) // Reset attacker, else ATAC will rapidly start adding Team Attacks!

		if ( health - 5 <= 0 )
			user_kill( id, 1 )
		else
		{
			set_pev( id, pev_health, float( health ) - 5.0 )
			emit_sound( id, CHAN_ITEM, "ambience/flameburst1.wav", 0.6, ATTN_NORM, 0, PITCH_NORM )
			set_task( 1.0, "fire_damage", id )
		}
	}
}

public Touch( ptr, ptd )
{
	if ( ptr < 1 || ptr > maxplayers || ptd < 1 || ptd > maxplayers || !get_pcvar_num( gCVARFireMode ) )
		return FMRES_IGNORED

	if ( is_user_alive( ptr ) && !g_fire[ ptr ] && is_user_alive( ptd ) && g_fire[ ptd ] )
	{
		set_atac_kills( ptr, ptd, get_atac_kills( ptr ), g_plugin )
		emit_sound( ptr, CHAN_WEAPON, "scientist/scream07.wav", 1.0, ATTN_NORM, 0, PITCH_HIGH )
	}

	return FMRES_IGNORED
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
