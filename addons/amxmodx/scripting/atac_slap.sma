/* ATAC Slap
*
* Copyright © 2006-2007, ATAC Team
*
* This file is provided as is (no warranties).
*
*/

#include <amxmodx>
#include <fakemeta>
#include <atac>

#define PLUGIN "Slap"
#define VERSION "1.1"
#define AUTHOR "ATAC Team"

new gCVARSlapAmount
new gCVARSlapPower

public plugin_init()
{
	register_plugin( PLUGIN, VERSION, AUTHOR )
	atac_register_punishment()
	gCVARSlapAmount = register_cvar( "atac_slap_amount", "10" )
	gCVARSlapPower = register_cvar( "atac_slap_power", "5" )
}

public atac_punishment_name( id )
{
	new text[ 64 ]
	formatex( text, 63, "%L", id, "ATAC_SLAP_X_TIMES", get_pcvar_num( gCVARSlapAmount ) )
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
	new power[ 2 ]
	power[ 0 ] = id
	power[ 1 ] = get_pcvar_num( gCVARSlapPower )
	set_task( 0.25, "player_slap", 0, power, 2, "a", get_pcvar_num( gCVARSlapAmount ) )
}

public player_slap( param[ 2 ] )
{
	new id = param[ 0 ]
	new power = param[ 1 ]

	if ( is_user_alive( id ) )
	{
		set_pev( id, pev_dmg_inflictor, 0 )
		user_slap( id, power )
	}
}
