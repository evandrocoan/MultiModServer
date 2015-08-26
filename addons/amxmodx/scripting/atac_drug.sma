/* ATAC Drug
*
* Copyright © 2006-2007, ATAC Team
*
* This file is provided as is (no warranties).
*
*/

#include <amxmodx>
#include <fakemeta>
#include <atac>

#define PLUGIN "Drug"
#define VERSION "1.0"
#define AUTHOR "ATAC Team"

new g_drug[ 33 ]
new gmsgSetFOV

public plugin_init()
{
	register_plugin( PLUGIN, VERSION, AUTHOR )
	atac_register_punishment()
	register_event( "SetFOV", "SetFOV_event", "be", "1!170" )
	gmsgSetFOV = get_user_msgid( "SetFOV" )
}

public client_putinserver( id )
{
	g_drug[ id ] = 0
}

public atac_punishment_name( id )
{
	new text[ 64 ]
	formatex( text, 63, "%L", id, "ATAC_DRUG" )
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
	g_drug[ killer ] = 0
	set_vision( killer, 90 )
}

exec_punishment( id )
{
	if ( !g_drug[ id ] )
	{
		g_drug[ id ] = 1
		set_vision( id, 170 )
	}
}

public SetFOV_event( id )
{
	if ( g_drug[ id ] )
		set_vision( id, 170 )
}

set_vision( id, value )
{
	message_begin( MSG_ONE, gmsgSetFOV, _, id )
	write_byte( value )
	message_end()
}
