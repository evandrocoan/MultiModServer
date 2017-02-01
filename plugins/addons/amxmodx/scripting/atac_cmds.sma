/* ATAC Commands
*
* Copyright © 2006-2007, ATAC Team
*
* This file is provided as is (no warranties).
*
*/

#include <amxmodx>
#include <amxmisc>
#include <atac>

#define PLUGIN "ATAC Commands"
#define VERSION "1.1"
#define AUTHOR "ATAC Team"


new gPunish[ 32 ][ 32 ]
new gFlags[ 32 ][ 32 ]
new maxpunishments

public plugin_init()
{
	register_plugin( PLUGIN, VERSION, AUTHOR )
	register_clcmd( "atac_addmetk", "ClientCommand_addmetk", ADMIN_RCON, "- lets you punish yourself" )
	register_srvcmd( "atac_register_command", "ServerCommand_atac" )
}

public ServerCommand_atac( id )
{
	if ( id == 0 )
	{
		new plugin[ 32 ], cmd[ 32 ], flags[ 32 ], null[ 1 ], name[ 32 ], punish_id
		read_argv( 1, plugin, 31 )
		read_argv( 2, cmd, 31 )
		read_argv( 3, flags, 31 )

		for ( new i = 2; i <= maxpunishments; ++i )
		{
			punish_id = is_punishment_valid( i )

			if ( punish_id )
			{
				get_plugin( punish_id, null, 0, name, 31, null, 0, null, 0, null, 0 )

				if ( equali( plugin, name ) )
				{
					formatex( gPunish[ i ], 31, "atac_%s", cmd )
					formatex( gFlags[ i ], 31, flags )
				}
			}
		}
	}
}

public plugin_cfg()
{
	new dir[ 64 ]; get_configsdir( dir, 63 )
	maxpunishments = get_maxpunishments()
	server_cmd( "exec %s/atac/atac_commands.cfg", dir )
}

public client_command( id )
{
	new arg0[ 31 ], arg1[ 32 ]
	read_argv( 0, arg0, 31 ) // 1st argument
	read_argv( 1, arg1, 31 ) // 2nd argument

	for ( new i = 2; i <= maxpunishments; ++i ) // Registered Punishments always start at Index 2
	{
		if ( equal( arg0, gPunish[ i ] ) ) // Does the 1st argument match anything we've registered?
		{
			if ( !has_flag( id, gFlags[ i ] ) )
			{
				console_print( id, "%L", id, "NO_ACC_COM" )
				return PLUGIN_HANDLED
			}

			new id2 = cmd_target( id, arg1, 2 ) // Convert 2nd argument into a player

			if ( !is_user_connected( id2 ) ) // id2 not valid?
				return PLUGIN_HANDLED

			set_atac_kills( id2, id, get_atac_kills( id2 ), i ) // Activate Punishment without increasing TK (note last value)
			return PLUGIN_HANDLED
		}
	}
	return PLUGIN_CONTINUE 
}

public ClientCommand_addmetk( id, level, cid )
{
	if ( !cmd_access( id, level, cid, 0 ) )
		return PLUGIN_HANDLED

	set_atac_kills( id, id, get_atac_kills( id ), 1 )
	return PLUGIN_HANDLED
}
