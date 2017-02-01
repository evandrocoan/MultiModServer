/* ATAC SlapToOne
*
* Copyright © 2006-2007, ATAC Team
*
* This file is provided as is (no warranties).
*
*/

#include <amxmodx>
#include <fakemeta>
#include <atac>

#define PLUGIN "Slap2One"
#define VERSION "1.1"
#define AUTHOR "ATAC Team"

public plugin_init()
{
	register_plugin( PLUGIN, VERSION, AUTHOR )
	atac_register_punishment()
}

public atac_punishment_name( id )
{
	new text[ 64 ]
	formatex( text, 63, "%L", id, "ATAC_SLAP_TO_1" )
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
		set_pev( id, pev_dmg_inflictor, 0 )
		user_slap( id, get_user_health( id ) - 1 )
	}
}
