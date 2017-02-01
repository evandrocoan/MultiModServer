/* ATAC AMXBans
*
* Copyright © 2006-2007, ATAC Team
*
* This file is provided as is (no warranties).
*
*/

#include <amxmodx>
#include <fakemeta>
#include <atac>

#define PLUGIN "ATAC AMXBans"
#define VERSION "1.1"
#define AUTHOR "ATAC Team"

new gBanning[ 33 ]
new gCVARTeamKills
new gCVARBanTime

public plugin_init()
{
	register_plugin( PLUGIN, VERSION, AUTHOR )
	new amxbans = get_cvar_pointer( "amxbans_version" ) // Check to see if the server has AMX Bans installed

	if ( !amxbans )
		pause( "ade", PLUGIN )
	else
	{
		atac_register_addon()
		gCVARTeamKills = get_cvar_pointer( "atac_team_kills" )
		gCVARBanTime = get_cvar_pointer( "atac_ban_time" )
	}
}

public client_putinserver( id )
{
	gBanning[ id ] = 0
}

public atac_punished( killer, const name[], const authid[], bantype )
{
	if ( !bantype ) // 0 = Kick, DO NOT BAN!
		return PLUGIN_CONTINUE  // Allow ATAC to carry on as normal

	if ( gBanning[ killer ] ) // Check to make sure we are not trying to ban the client already
		return PLUGIN_HANDLED // Supercede ATAC's banning system

	new tk = get_atac_kills( killer )
	new maxtk = get_pcvar_num( gCVARTeamKills )

	if ( tk >= maxtk ) // Let AMX Bans take over
	{
		gBanning[ killer ] = 1
		
		switch( bantype )
		{
			// IP Banning
			case 1: server_cmd( "amx_banip %i %s Max Team Kill Warning %i/%i", get_pcvar_num( gCVARBanTime ), authid, tk, maxtk )
			// STEAMID Banning
			case 2: server_cmd( "amx_ban %i %s Max Team Kill Warning %i/%i", get_pcvar_num( gCVARBanTime ), authid, tk, maxtk )
			// Invalid Banning Type
			default: server_print( "%s: Invalid Banning ID - Name: %s AuthID: %s", PLUGIN, name, ( authid[ 0 ] == 0 ) ? "NULL" : authid )
		}

		return PLUGIN_HANDLED // Supercede ATAC's banning system
	}

	return PLUGIN_CONTINUE // Allow ATAC to carry on as normal
}
