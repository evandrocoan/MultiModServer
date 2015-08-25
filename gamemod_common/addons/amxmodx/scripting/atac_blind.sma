/* ATAC Blind
*
* Copyright © 2006-2007, ATAC Team
*
* This file is provided as is (no warranties).
*
*/

#include <amxmodx>
#include <fakemeta>
#include <atac>

#define PLUGIN "Blind"
#define VERSION "1.0"
#define AUTHOR "ATAC Team"

new g_blind[ 33 ]
new gmsgScreenFade

public plugin_init()
{
	register_plugin( PLUGIN, VERSION, AUTHOR )
	atac_register_punishment()
	register_event( "ScreenFade", "ScreenFade_event", "be" )
	gmsgScreenFade = get_user_msgid( "ScreenFade" )
}

public client_putinserver( id )
{
	g_blind[ id ] = 0
}

public atac_punishment_name( id )
{
	new text[ 64 ]
	formatex( text, 63, "%L", id, "ATAC_BLIND" )
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
	g_blind[ killer ] = 0
	message_begin( MSG_ONE, gmsgScreenFade, _, killer )
	write_short( 1 << 0 )
	write_short( 1 << 0 )
	write_short( 1 << 0 )
	write_byte( 0 )
	write_byte( 0 )
	write_byte( 0 )
	write_byte( 0 )
	message_end()
}

exec_punishment( id )
{
	if ( !g_blind[ id ] )
	{
		g_blind[ id ] = 1
		message_begin( MSG_ONE, gmsgScreenFade, _, id )
		write_short( 1 << 12 )
		write_short( 1 << 8 )
		write_short( 1 << 0 )
		write_byte( 0 )
		write_byte( 0 )
		write_byte( 0 )
		write_byte( 255 )
		message_end()
		set_task( 0.9, "fade_screen", id )
	}
}

public fade_screen( id )
{
	if ( g_blind[ id ] )
	{
		message_begin( MSG_ONE, gmsgScreenFade, _, id )
		write_short( 1 << 0 )
		write_short( 1 << 0 )
		write_short( 1 << 2 )
		write_byte( 0 )
		write_byte( 0 )
		write_byte( 0 )
		write_byte( 255 )
		message_end()
	}
}

public ScreenFade_event( id )
{
	if ( g_blind[ id ] )
		set_task( 0.6, "fade_screen", id )
}
