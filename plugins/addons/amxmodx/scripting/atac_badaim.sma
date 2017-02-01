/* ATAC Bad Aim
*
* Copyright © 2007, ATAC Team
*
* This file is provided as is (no warranties).
*
*/

#include <amxmodx>
#include <fakemeta>
#include <atac>

#define PLUGIN "Bad Aim"
#define VERSION "1.1"
#define AUTHOR "ATAC Team"

new g_badaim[ 33 ]

public plugin_init()
{
	register_plugin( PLUGIN, VERSION, AUTHOR )
	register_forward(FM_TraceLine, "TraceLine_Post", 1)
	atac_register_punishment()
}

public atac_punishment_name( id )
{
	new text[ 64 ]
	formatex( text, 63, "%L", id, "ATAC_BAD_AIM" )
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
	remove_task( killer )
	g_badaim[ killer ] = 0
}

exec_punishment( id )
{
	remove_task( id )
	g_badaim[ id ] = 0
	randomize_hitzones( id )
	set_task( 10.0, "randomize_hitzones", id, _, _, "b" )
}

public randomize_hitzones( id )
{
	if ( is_user_alive( id ) )
	{
		for ( new partIdx; partIdx < 3; partIdx++ )
			g_badaim[ id ] |= ( 1 << 0 ) | ( 1 << random_num( 1, 7 ) )
	}
}

public TraceLine_Post( Float:v1[ 3 ], Float:v2[ 3 ], noMonsters, entity )
{
	if ( !is_user_alive( entity ) )
		return FMRES_IGNORED

	new entity2 = get_tr(TR_pHit)
	
	if ( !is_user_alive( entity2 ) )
		return FMRES_IGNORED
	
	if ( !g_badaim[ entity ] )
		return FMRES_IGNORED
	
	new hitzone = ( 1 << get_tr( TR_iHitgroup ) )

	if ( g_badaim[ entity ] & hitzone )
	{
		set_tr( TR_flFraction, 1.0 )
		return FMRES_SUPERCEDE
	}

	return FMRES_IGNORED
}
