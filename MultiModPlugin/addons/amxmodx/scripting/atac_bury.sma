/* ATAC Bury
*
* Copyright © 2006-2007, ATAC Team
*
* This file is provided as is (no warranties).
*
*/

#include <amxmodx>
#include <fakemeta>
#include <atac>

#define PLUGIN "Bury"
#define VERSION "1.0"
#define AUTHOR "ATAC Team"

new g_bury[ 33 ]

public plugin_init()
{
	register_plugin( PLUGIN, VERSION, AUTHOR )
	atac_register_punishment()
}

public client_putinserver( id )
{
	g_bury[ id ] = 0
}

public atac_punishment_name( id )
{
	new text[ 64 ]
	formatex( text, 63, "%L", id, "ATAC_BURY" )
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
	g_bury[ killer ] = 0
}

exec_punishment( id )
{
	if ( !g_bury[ id ] )
	{
		new Float:vOrigin[ 3 ], Float:vEnd[ 3 ]
		g_bury[ id ] = 1
		drop_weapons( id )
		vEnd[ 2 ] = -8192.0
		pev( id, pev_origin, vOrigin )
		engfunc( EngFunc_TraceLine, vOrigin, vEnd, 0, id, 0 )
		get_tr2( 0, TR_vecEndPos, vOrigin )
		set_pev( id, pev_origin, vOrigin )
	}
}

drop_weapons( id )
{
	new iwpn, iwpns[ 32 ], nwpn[ 32 ]
	get_user_weapons( id, iwpns, iwpn )

	for ( new a; a < iwpn; ++a )
	{
		get_weaponname( iwpns[ a ], nwpn, 31 )
		engclient_cmd( id, "drop", nwpn )
	}
}
