/* ATAC Bomb
*
* Copyright © 2006-2007, ATAC Team
*
* This file is provided as is (no warranties).
*
*/

#include <amxmodx>
#include <fakemeta>
#include <atac>

#define PLUGIN "Timebomb"
#define VERSION "1.1"
#define AUTHOR "ATAC Team"

new g_timebomb[ 33 ]
new countdown[ 33 ]
new gmsgDeathMsg

new gCVARBombMode
new gCVARBombRange

new g_fireball
new g_xfire
new g_smoke

public plugin_precache()
{
	g_fireball = precache_model( "sprites/zerogxplode.spr" )
	g_xfire = precache_model( "sprites/xfireball3.spr" )
	g_smoke = precache_model( "sprites/steam1.spr" )
	precache_sound( "fvox/ten.wav" )
	precache_sound( "fvox/nine.wav" )
	precache_sound( "fvox/eight.wav" )
	precache_sound( "fvox/seven.wav" )
	precache_sound( "fvox/six.wav" )
	precache_sound( "fvox/five.wav" )
	precache_sound( "fvox/four.wav" )
	precache_sound( "fvox/three.wav" )
	precache_sound( "fvox/two.wav" )
	precache_sound( "fvox/one.wav" )
	precache_sound( "hgrunt/fire!.wav" )
}

public plugin_init()
{
	register_plugin( PLUGIN, VERSION, AUTHOR )
	atac_register_punishment()
	gmsgDeathMsg = get_user_msgid( "DeathMsg" )
	gCVARBombMode = register_cvar( "atac_bomb_mode", "0" )
	gCVARBombRange = register_cvar( "atac_bomb_range", "1000" )
}

public client_putinserver( id )
{
	g_timebomb[ id ] = 0
}

public atac_punishment_name( id )
{
	new text[ 64 ]
	formatex( text, 63, "%L", id, "ATAC_BOMB" )
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
	g_timebomb[ killer ] = 0
}

public exec_punishment( id )
{
	if ( !g_timebomb[ id ] )
	{
		g_timebomb[ id ] = 1
		countdown[ id ] = 10
		set_task( 1.0, "exec_punishment", id )	
	}
	else if ( is_user_alive( id ) && g_timebomb[ id ] )
	{
		new speak[ 11 ][] = { "hgrunt/fire!.wav", "fvox/one.wav", "fvox/two.wav", "fvox/three.wav", "fvox/four.wav", "fvox/five.wav", "fvox/six.wav", "fvox/seven.wav", "fvox/eight.wav", "fvox/nine.wav", "fvox/ten.wav" }
		new red = random_num( 0, 255 )
		new green = random_num( 0, 255 )
		new blue = random_num( 0, 255 )
		new alpha = random_num( 100, 255 )

		if ( countdown[ id ] > 0 )
		{
			set_player_rendering( id, kRenderFxGlowShell, red, green, blue, kRenderTransAlpha, alpha, 1 ) // Glow Me
			emit_sound( id, CHAN_VOICE, speak[ countdown[ id ] ], 1.0, ATTN_NORM, 0, PITCH_NORM ) // Annouce Me
			countdown[ id ]--
			set_task( 1.0, "exec_punishment", id ) // Call Again
		}
		else   //explode
		{
			if ( g_timebomb[ id ] )
				g_timebomb[ id ] = 0
		
			set_player_rendering( id, kRenderFxGlowShell, 0, 0, 0, kRenderTransAlpha, 255, 1 )
			emit_sound( id, CHAN_VOICE, speak[ countdown[ id ] ], 1.0, ATTN_NORM, 0, PITCH_NORM )
			new param[ 2 ]

			if ( get_pcvar_num( gCVARBombMode ) )
			{
				new id2, players[ 32 ], inum, pOrigin[ 3 ], kOrigin[ 3 ]
				get_players( players, inum, "a" )

				for (new i; i < inum; ++i)
				{
					id2 = players[ i ]

					if ( id2 == id )
						continue

					get_user_origin( id2, pOrigin )
					get_user_origin( id, kOrigin )

					if ( get_pcvar_num( gCVARBombRange ) > get_distance( kOrigin, pOrigin ) )
					{
						message_begin( MSG_BROADCAST, gmsgDeathMsg ) // Death Msg
						write_byte( id )
						write_byte( id2 )
						write_byte( 0 )
						write_string( "grenade" )
						message_end()
						
						param[ 0 ] = id2
						param[ 1 ] = 0
						player_slay( param )
					}
				}
			}

			message_begin( MSG_BROADCAST, gmsgDeathMsg )
			write_byte( 0 )
			write_byte( id )
			write_byte( 0 )
			write_string( "grenade" )
			message_end()

			param[ 0 ] = id
			param[ 1 ] = 3
			player_slay( param )
		}
	}
	else
		set_player_rendering( id, kRenderFxGlowShell, 0, 0, 0, kRenderTransAlpha, 255, 0 )
}

set_player_rendering( id, renderfx, red, green, blue, rendermode, renderamt, alive )
{
	if ( is_user_connected( id ) && ( is_user_alive( id ) && alive == 1 ) || ( alive == 0 ) )
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

player_slay( param[ 2 ] )
{
	new id = param[ 0 ]
	new effect = param[ 1 ]

	if ( is_user_alive( id ) )
	{
		new origin[ 3 ]
		get_user_origin( id, origin )
		origin[ 2 ] = origin[ 2 ] - 26

		switch ( effect )
		{
			case 3: // Timebomb
			{
				message_begin( MSG_BROADCAST, SVC_TEMPENTITY, origin )
				write_byte( TE_SPRITE )
				write_coord( origin[ 0 ] )
				write_coord( origin[ 1 ] )
				write_coord( origin[ 2 ] + 256 )
				write_short( g_xfire )
				write_byte( 120 )
				write_byte( 255 )
				message_end()

				message_begin( MSG_BROADCAST, SVC_TEMPENTITY ) // Implosion
				write_byte( TE_IMPLOSION )
				write_coord( origin[ 0 ] )
				write_coord( origin[ 1 ] )
				write_coord( origin[ 2 ] )
				write_byte( 100 )
				write_byte( 20 )
				write_byte( 5 )
				message_end()

				message_begin( MSG_PVS, SVC_TEMPENTITY, origin ) // Random Explosions
				write_byte( TE_EXPLOSION )
				write_coord( origin[ 0 ] )
				write_coord( origin[ 1 ] )
				write_coord( origin[ 2 ] )
				write_short( g_fireball )
				write_byte( 30 )
				write_byte( 12 )
				write_byte( TE_EXPLFLAG_NONE )
				message_end()

				smoke_effect( origin, 60 ) // Lots of Smoke
			}
		}

		set_msg_block( gmsgDeathMsg, BLOCK_ONCE )
		user_kill( id, 1 )
	}
}

smoke_effect( origin[ 3 ], amount )
{
	message_begin( MSG_BROADCAST, SVC_TEMPENTITY, origin )
	write_byte( TE_SMOKE)
	write_coord( origin[ 0 ] )
	write_coord( origin[ 1 ] )
	write_coord( origin[ 2 ] )
	write_short( g_smoke )
	write_byte( amount )
	write_byte( 10 )
	message_end()
}
