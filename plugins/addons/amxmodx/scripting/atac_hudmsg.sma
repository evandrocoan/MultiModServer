/* ATAC HudMessages
*
* Copyright © 2006-2008, ATAC Team
*
* This file is provided as is (no warranties).
*
*/

#include <amxmodx>
#include <amxmisc>
#include <atac>

#define PLUGIN "Hud Messages"
#define VERSION "1.1"
#define AUTHOR "ATAC Team"

new gCVARHudText
new gCVARTeamAttacks
new gCVARTeamKills
new gCVARBanTime

new gHudSyncDamage
new gHudSyncKill
new gmsgSayText

new TeamAttacks[ 33 ]
new TeamKills[ 33 ]

public plugin_init()
{
	register_plugin( PLUGIN, VERSION, AUTHOR )
	atac_register_addon()

	gCVARHudText = register_cvar( "atac_hudtext", "0" )
	gCVARTeamAttacks = get_cvar_pointer( "atac_team_attacks" )
	gCVARTeamKills = get_cvar_pointer( "atac_team_kills" )
	gCVARBanTime = get_cvar_pointer( "atac_ban_time" )
	
	gHudSyncDamage = CreateHudSyncObj()
	gHudSyncKill = CreateHudSyncObj()
	gmsgSayText = get_user_msgid( "SayText" )
}

public atac_team_attack( attacker, victim, damage )
{
	TeamAttacks[ attacker ] = get_atac_attacks( attacker )

	if ( TeamAttacks[ attacker ] < get_pcvar_num( gCVARTeamAttacks ) )
	{
		new name[ 32 ]
		get_user_name( victim, name, 31 )
		new team = get_user_team( attacker )

		set_hudmessage( ( team == 1 ) ? 140 : 0, ( team == 2 ) ? 100 : 0, ( team == 2 ) ? 200 : 0, 0.05, 0.42, 2, 0.1, 4.0, 0.02, 0.02, -1 )
		say_msg( attacker, gHudSyncDamage, MSG_ONE, "[ATAC] %L", attacker, "ATAC_TA_WARNING", TeamAttacks[ attacker ], get_pcvar_num( gCVARTeamAttacks ), damage, name )
	}
}

public atac_punished( killer, const name[], const authid[], bantype )
{
	if ( is_user_connected( killer ) )
	{
		new team = get_user_team( killer )
		set_hudmessage( ( team == 1 ) ? 140 : 0, ( team == 2 ) ? 100 : 0, ( team == 2 ) ? 200 : 0, 0.05, 0.50, 2, 0.1, 4.0, 0.02, 0.02, -1 )
	}
	else
		set_hudmessage( 255, 25, 255, 0.05, 0.50, 2, 0.1, 4.0, 0.02, 0.02, -1 )

	new max_tk = get_pcvar_num( gCVARTeamKills )
	TeamKills[ killer ] = get_atac_kills( killer )

	if ( TeamKills[ killer ] >= max_tk )
	{
		new ban_time = get_pcvar_num( gCVARBanTime )

		if ( !bantype )
			say_msg( 0, gHudSyncKill, MSG_BROADCAST, "[ATAC] %L", LANG_PLAYER, "ATAC_TK_KICK", TeamKills[ killer ], max_tk, name )
		else
		{
			if ( ban_time )
				say_msg( 0, gHudSyncKill, MSG_BROADCAST, "[ATAC] %L", LANG_PLAYER, "ATAC_TK_BAN_MIN", TeamKills[ killer ], max_tk, name, ban_time )
			else
				say_msg( 0, gHudSyncKill, MSG_BROADCAST, "[ATAC] %L", LANG_PLAYER, "ATAC_TK_BAN_PERM", TeamKills[ killer ], max_tk, name )
		}
	}
	else if ( is_user_connected( killer ) )
		say_msg( killer, gHudSyncKill, MSG_ONE, "[ATAC] %L", killer, "ATAC_TK_WARNING", TeamKills[ killer ], max_tk )
}

say_msg( id, ptr, type, const fmt[], {Float,_}:... )
{
	static string[ 128 ]
	string[ 0 ] = '^0'

	switch ( get_pcvar_num( gCVARHudText ) )
	{
		case 0: type = -1
		case 1: string[ 0 ] = 0x01
		case 2: string[ 0 ] = 0x04
		case 3: string[ 0 ] = 0x03
	}

	if ( type != -1 )
	{
		vformat( string[ 1 ], sizeof( string ) - 1, fmt, 5 )
		message_begin( type, gmsgSayText, _, id )
		write_byte( id )
		write_string( string )
		message_end()
	}
	else
	{
		vformat( string, sizeof( string ) - 1, fmt, 5 )
		ShowSyncHudMsg( id, ptr, string )
	}
}