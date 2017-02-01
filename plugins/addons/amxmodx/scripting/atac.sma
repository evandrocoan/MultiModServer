/*	Copyright © 2006-2008, ATAC Team

	ATAC (Advanced Team Attack Control) is free software;
	you can redistribute it and/or modify it under the terms of the
	GNU General Public License as published by the Free Software Foundation.

	This program is distributed in the hope that it will be useful,
	but WITHOUT ANY WARRANTY; without even the implied warranty of
	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
	GNU General Public License for more details.

	You should have received a copy of the GNU General Public License
	along with ATAC (Advanced Team Attack Control); if not, write to the
	Free Software Foundation, Inc., 59 Temple Place - Suite 330,
	Boston, MA 02111-1307, USA.
*/

#include <amxmodx>
#include <amxmisc>
#include <fakemeta>
#include <atac>

#define PLUGIN "ATAC"
#define VERSION "3.0.1"
#define AUTHOR "ATAC Team"

#define MAX_STORED_KILLS 512
#define MENU_TASK 1066 // Battle of Team Killing

new TeamAttacks[ 33 ]
new TeamKills[ 33 ]

new StoreKills[ MAX_STORED_KILLS ][ 38 ] // authid 0-31, tkamount 32-34, tkpunish 35-37
new g_StoreKill_Count

new KillerAuthID[ 33 ][ 32 ]
new KillerName[ 33 ][ 32 ]
new KilledMenu[ 33 ][ 33 ]
new CurrentKiller[ 33 ]
new PlayerPunish[ 33 ][ MAX_PUNISHMENTS ]
new MenuCount[ 33 ]
new g_atac
new g_atac_on
new g_atac_menu
new g_UserPage[ 33 ]
new g_hp[ 33 ]
new EntOwner[ 2048 ]
new maxplayers
new g_immunityFlags[32]
new g_ColourMenus
new g_CSRunning
new g_Bomb // Fix for CS/CZ

enum PUNISH_SETTINGS
{
	fwd_punish = 0,
	fwd_spawn,
	fwd_reset,
	fwd_name,
	punish_id
}

enum ADDON_SETTINGS
{
	fwd_attack = 0,
	fwd_kill,
	fwd_punished,
	fwd_punish_active,
	addon_id
}

new Plugin_Punishments[ MAX_PUNISHMENTS ][ PUNISH_SETTINGS ]
new g_Punish_Count = 2
new Plugin_Addons[ MAX_ADDONS ][ ADDON_SETTINGS ]
new g_Addon_Count = 0

new bool:gRestart
new gCVARRestart
new gCVARDisabled
new gCVARMenu
new gCVARMenuOverwrite
new gCVARShowPunishment
new gCVARAdminsImmune
new gCVARStoreKills
new gCVARTKAfterdeath
new gCVARTKAvoidance
new gCVARBanType
new gCVARBanTime
new gCVARTeamAttacks
new gCVARTeamKills
new gCVARImmunityFlags

public plugin_init()
{
	g_atac = register_plugin( PLUGIN, VERSION, AUTHOR )
	register_dictionary( "atac.txt" )
	register_dictionary( "atac_punishments.txt" )
	register_cvar( "atac_version", VERSION, FCVAR_SERVER|FCVAR_SPONLY )
	set_cvar_string("atac_version", VERSION);
	register_concmd( "atac", "ConsoleCommand_atac", ADMIN_RCON, "- access ATAC information" )

	gCVARRestart = get_cvar_pointer( "sv_restart" )
	gCVARDisabled = register_cvar( "atac_disabled", "0" )
	gCVARMenu = register_cvar( "atac_menu", "1" )
	gCVARMenuOverwrite = register_cvar( "atac_menu_overwrite", "0" )
	gCVARShowPunishment = register_cvar( "atac_show_punishment", "1" )
	gCVARAdminsImmune = register_cvar( "atac_admins_immune", "0" )
	gCVARStoreKills = register_cvar( "atac_store_kills", "1" )
	gCVARTKAfterdeath = register_cvar( "atac_tk_afterdeath", "0" )
	gCVARBanType = register_cvar( "atac_ban_type", "3" )
	gCVARBanTime = register_cvar( "atac_ban_time", "120" )
	gCVARTeamAttacks = register_cvar( "atac_team_attacks", "5" )
	gCVARTeamKills = register_cvar( "atac_team_kills", "3" )
	gCVARImmunityFlags = register_cvar( "atac_immunity_flags", "a" )
	gCVARTKAvoidance = register_cvar( "atac_tk_avoidance", "1" )
	Plugin_Punishments[ 0 ][ punish_id ] = g_atac
	Plugin_Punishments[ 1 ][ punish_id ] = g_atac

	if ( !get_pcvar_num( gCVARDisabled ) )
		atac_load()
}

atac_load()
{
	new dir[ 64 ]
	get_configsdir( dir, 63 )
	g_atac_on = 1

	server_cmd( "exec %s/atac/atac.cfg", dir )
	server_cmd( "exec %s/atac/punishments.cfg", dir )
	server_cmd( "exec %s/atac/addons.cfg", dir )
	server_cmd( "exec %s/atac/mod.cfg", dir )

	register_clcmd( "fullupdate", "ClientCommand_fullupdate" )
	register_clcmd( "say /atacstatus", "ClientCommand_atacstatus", 0, "- shows your Team Attack and Team Kill status" )
	g_atac_menu = register_menuid( "ATAC_TK" )
	register_menucmd( g_atac_menu, 1023, "action_atac_menu" )

	register_event( "DeathMsg", "Event_DeathMsg", "a", "1>0" )
	register_event( "Health", "Event_Health", "be" )
	register_event( "ResetHUD", "Event_ResetHUD", "be" )
	register_event( "TextMsg", "RestartGame", "a", "2=#Game_will_restart_in" )
	register_logevent( "Log_Round_Start", 2, "0=World triggered", "1=Round_Start" )  // Fix for CS/CZ

	register_forward( FM_Think, "Forward_Think" )
	
	maxplayers = get_maxplayers()
	g_ColourMenus = colored_menus()
	g_CSRunning = cstrike_running()

	get_pcvar_string( gCVARImmunityFlags, g_immunityFlags, sizeof( g_immunityFlags ) - 1 )
}

public client_authorized( id )
{
	if ( !g_atac_on )
		return 

	for ( new player = 1; player <= maxplayers; ++player )
	{
		KilledMenu[ id ][ player ] = 0
		KilledMenu[ player ][ id ] = 0
	}

	TeamAttacks[ id ] = 0
	TeamKills[ id ] = 0
	CurrentKiller[ id ] = 0
	MenuCount[ id ] = 0
	g_UserPage[ id ] = 0
	g_hp[ id ] = 0

	get_real_authid( id, KillerAuthID[ id ] )

	if ( !is_user_bot( id ) && get_pcvar_num( gCVARStoreKills ) )
	{
		new found = find_authid( KillerAuthID[ id ] )

		if ( found != -1 )
		{
			new stored_authid[ 32 ], stored_kill[ 3 ], stored_punish[ 3 ], plugin_id
			parse( StoreKills[ found ], stored_authid, 31, stored_kill, 2, stored_punish, 2 )
			TeamKills[ id ] = str_to_num( stored_kill )
			plugin_id = str_to_num( stored_punish )
			PlayerPunish[ id ][ plugin_id ] = ATAC_HOOK_SPAWNED
		}
	}
}

public client_disconnect( id )
{
	if ( !g_atac_on )
		return
	
	remove_task( MENU_TASK + id )
	new punishhook = find_punishhook( id, ATAC_HOOK_RESET )
	new phook

	while ( punishhook )
	{
		exec_Punishment( id, 0, ATAC_HOOK_RESET, punishhook )
		phook = punishhook
		punishhook = find_punishhook( id, ATAC_HOOK_RESET )
	}

	if ( !phook )
	{
		punishhook = find_punishhook(id, ATAC_HOOK_SPAWNED )
		
		while ( punishhook )
		{
			PlayerPunish[ id ][ punishhook ] = 0
			phook = punishhook
			punishhook = find_punishhook( id, ATAC_HOOK_SPAWNED )
		}
	}

	for ( new player = 1; player <= maxplayers; ++player )
	{
		if ( KilledMenu[ id ][ player ] )
		{
			KilledMenu[ id ][ player ] = 0 // Make sure record is cleared

			if ( get_pcvar_num( gCVARTKAvoidance ) )
				check_teamkills( id )
		}

		if ( CurrentKiller[ player ] == id )
		{
			show_menu( player, 0, " ", 0 )
			find_killer( player ) // Find next TK'er for Victim

			if ( get_pcvar_num( gCVARTKAvoidance ) )
				check_teamkills( id )
		}
	}

	if ( !is_user_bot( id ) && get_pcvar_num( gCVARStoreKills ) )
	{
		new temp[ 38 ]
		new found = find_authid( KillerAuthID[ id ] )

		if ( found != -1 )
		{
			new stored_authid[ 32 ], stored_kill[ 3 ], stored_punish[ 3 ]
			parse( StoreKills[ found ], stored_authid, 31, stored_kill, 2, stored_punish, 2 )
			formatex( temp, 37, "%s %i %i", KillerAuthID[ id ], ( TeamKills[ id ] >= get_pcvar_num( gCVARTeamKills ) ) ? 0 : TeamKills[ id ], phook )
			StoreKills[ found ] = temp
		}
		else if ( found == -1 && g_StoreKill_Count < MAX_STORED_KILLS )
		{
			formatex( temp, 37, "%s %i %i", KillerAuthID[ id ], TeamKills[ id ], phook )
			StoreKills[ g_StoreKill_Count ] = temp
			g_StoreKill_Count++
		}
	}

	for ( new j; j < MAX_PUNISHMENTS; ++j ) // Clear all plugin player punishments
		PlayerPunish[ id ][ j ] = 0
}

public Forward_Think( id )
{
	static owner, model[ 32 ]

	if ( pev_valid( id ) && id > maxplayers )
	{
		owner = pev( id, pev_owner )

		if ( owner > 0 && EntOwner[ id ] > -1 && EntOwner[ id ] != owner )
		{
			EntOwner[ id ] = owner
			// Fix for CS/CZ
			if ( g_CSRunning )
			{
				pev( id, pev_model, model, 31 )
				
				if ( equali( model, "models/w_c4.mdl" ) )
				{
					EntOwner[ id ] = -1
					g_Bomb = id
				}
			}
		}
	}
}

// Fix for CS/CZ
public Log_Round_Start()
{
	EntOwner[ g_Bomb ] = 0
	g_Bomb = 0
}

public RestartGame()
{
	gRestart = true
	set_task( float( get_pcvar_num( gCVARRestart ) ) - 0.2, "ResetGame" )
}

public ResetGame()
{
	gRestart = false
}

public plugin_natives()
{
	register_library( "atac" )
	register_native( "atac_register_punishment", "Native_register_punishment" )
	register_native( "atac_register_addon", "Native_register_addon" )
	register_native( "is_punishment_valid", "Native_is_punishment_valid" )
	register_native( "get_maxpunishments", "Native_get_maxpunishments" )
	register_native( "get_atac_attacks", "Native_get_atac_attacks" )
	register_native( "set_atac_attacks", "Native_set_atac_attacks" )
	register_native( "get_atac_kills", "Native_get_atac_kills" )
	register_native( "set_atac_kills", "Native_set_atac_kills" )
}

public Native_register_punishment( plugin_id )
{
	for ( new i = 2; i <= g_Punish_Count; ++i ) // Ensure this plugin hasn't already registered a punishment
	{
		if ( Plugin_Punishments[ i ][ punish_id ] == plugin_id )  
			return -1
	}

	if ( g_Punish_Count < MAX_PUNISHMENTS - 1 )
	{
		new null[ 1 ], name[ 32 ]
		get_plugin( plugin_id, null, 0, name, 31, null, 0, null, 0, null, 0 )
		server_cmd( "amx_pausecfg add ^"%s^"", name )

		Plugin_Punishments[ g_Punish_Count ][ punish_id ]  = plugin_id
		Plugin_Punishments[ g_Punish_Count ][ fwd_name ]   = CreateOneForward( plugin_id, "atac_punishment_name", FP_CELL )
		Plugin_Punishments[ g_Punish_Count ][ fwd_punish ] = CreateOneForward( plugin_id, "atac_player_punish", FP_CELL, FP_CELL )
		Plugin_Punishments[ g_Punish_Count ][ fwd_reset ]  = CreateOneForward( plugin_id, "atac_player_reset", FP_CELL, FP_CELL )
		Plugin_Punishments[ g_Punish_Count ][ fwd_spawn ]  = CreateOneForward( plugin_id, "atac_player_spawn", FP_CELL, FP_CELL )
		g_Punish_Count++
		return g_Punish_Count - 1
	}

	return -1
}

public Native_is_punishment_valid( plugin_id )
{
	new index = get_param( 1 )

	if ( index < 2 || index > MAX_PUNISHMENTS - 1 )
		return -1

	if ( Plugin_Punishments[ index ][ punish_id ] > 0 )
		return Plugin_Punishments[ index ][ punish_id ]

	return -1
}

public Native_get_maxpunishments( plugin_id )
{
	return g_Punish_Count
}

public Native_register_addon(plugin_id)
{
	for ( new i; i <= g_Addon_Count; ++i ) // Ensure this plugin hasn't already registered an addon
	{ 
		if ( Plugin_Addons[ i ][ addon_id ] == plugin_id )  
			return -1
	}

	if ( g_Addon_Count < MAX_ADDONS - 1 )
	{
		Plugin_Addons[ g_Addon_Count ][ addon_id ] = plugin_id
		Plugin_Addons[ g_Addon_Count ][ fwd_attack ] = CreateOneForward( plugin_id, "atac_team_attack", FP_CELL, FP_CELL, FP_CELL )
		Plugin_Addons[ g_Addon_Count ][ fwd_kill ] = CreateOneForward( plugin_id, "atac_team_kill", FP_CELL, FP_CELL )
		Plugin_Addons[ g_Addon_Count ][ fwd_punished ] = CreateOneForward( plugin_id, "atac_punished", FP_CELL, FP_STRING, FP_STRING, FP_CELL )
		Plugin_Addons[ g_Addon_Count ][ fwd_punish_active ] = CreateOneForward( plugin_id, "atac_punishment_activated",  FP_CELL, FP_CELL, FP_CELL )
		g_Addon_Count++
		return g_Addon_Count - 1
	}

	return -1
}

public Native_get_atac_attacks()
{
	new id = get_param( 1 )

	if ( is_user_connected( id ) )
		return TeamAttacks[ id ]

	return 0
}

public Native_set_atac_attacks()
{
	new attacker = get_param( 1 )

	if ( is_user_connected( attacker ) )
	{
		if ( check_immunity( attacker ) == 2 )
			return 0

		new victim = get_param( 2 )
		new amount = get_param( 3 )

		if ( !is_user_connected( victim ) )
			return 0

		set_pev( victim, pev_dmg_inflictor, attacker )

		if ( amount <= -1 )
			TeamAttacks[ attacker ]++
		else
			TeamAttacks[ attacker ] = amount

		if ( amount != 0 )
		{
			new team1 = get_user_team( attacker )
			new team2 = get_user_team( victim )

			if ( team1 == team2 )
			{
				TeamAttacks[ attacker ]--
				if ( TeamAttacks[ attacker ] < 0 )
					TeamAttacks[ attacker ] = 0

				check_teamattack( attacker, victim, 0 )
			}
		}
	}

	return 0
}

public Native_get_atac_kills()
{
	new id = get_param( 1 )

	if ( is_user_connected( id ) )
		return TeamKills[ id ]

	return 0
}

public Native_set_atac_kills()
{
	new killer = get_param( 1 )

	if ( is_user_connected( killer ) )
	{
		if ( check_immunity( killer ) == 2 )
			return 0

		new victim = get_param( 2 )
		new amount = get_param( 3 )
		new item = get_param( 4 )

		if ( !is_user_connected( victim ) )
			return 0

		set_pev( victim, pev_dmg_inflictor, killer )

		if ( amount <= -1 )
			TeamKills[ killer ]++
		else
			TeamKills[ killer ] = amount
		
		check_menus( killer )

		switch ( item )
		{
			case 0:
			{
				TeamKills[ killer ]--
				if ( TeamKills[ killer ] < 0 )
					TeamKills[ killer ] = 0

				check_teamkill( killer, victim )
			}
			case 1:
			{
				if ( !CurrentKiller[ victim ] )
				{
					CurrentKiller[ victim ] = killer
					menu_status( victim, killer, 0 )
				}
				else
					KilledMenu[ killer ][ victim ]++
			}
			case 2 .. MAX_PUNISHMENTS - 1:
			{
				new Float:fPage, page
				CurrentKiller[ victim ] = killer
				fPage = item / 8.0
				page = floatround( fPage, floatround_ceil ) - 1
				g_UserPage[ victim ] = page

				for ( new key; key < 10; key++ )
				{
					if ( page * 8 + key == item )
					{
						action_atac_menu( victim, key, 1 )
						break
					} 
				}
			}
		}
	}

	return 0
}

public ConsoleCommand_atac( id, level, cid )
{
	if ( id != 0 && !cmd_access( id, level, cid, 0 ) )
		return PLUGIN_HANDLED

	new cmd[ 16 ], null[ 1 ], temp[ 64 ], version[ 8 ], author[ 32 ]
	read_argv( 1, cmd, 15 )
	
	if ( equali( cmd, "off" ) )
	{
		if ( !g_atac_on )
			console_print( id, "   atac is already disabled" )
		else
		{
			formatex( temp, 63, "   Disabling ATAC...  Restarting Round" )
			console_print( id, temp )
			client_print( 0, print_chat, temp )
			set_cvar_num( "atac_disabled", 1 )
			set_cvar_num( "sv_restartround", 3 )
			g_atac_on = 0
		}
	}
	else if ( equali( cmd, "on" ) )
	{
		if ( g_atac_on )
			console_print( id, "   atac is already enabled" )
		else
		{
			formatex( temp, 63, "   Enabling ATAC...  Restarting Round" )
			console_print( id, temp )
			client_print( 0, print_chat, temp )
			set_cvar_num( "atac_disabled", 0 )
			set_cvar_num( "sv_restartround", 3 )
			atac_load()
		}
	}
	else if ( equali( cmd, "version" ) )
		console_print( id, "   Advanced Team Attack Control  v%s  (http://www.space-headed.net)", VERSION )
	else if ( equali( cmd, "settings" ) )
	{
		console_print( id, "registered settings:" )
		new maxcvars = get_plugins_cvarsnum()
		new cvar[ 32 ], cvar_flags, plugin_id, pcvar_handle, value[ 32 ], l

		for ( new i; i < maxcvars; ++i )
		{
			get_plugins_cvar( i, cvar, 31, cvar_flags, plugin_id, pcvar_handle )

			if ( plugin_id == g_atac )
			{
				l++
				get_pcvar_string( pcvar_handle, value, 31 )
				console_print( id, " [%s%i]  ATAC  -  %s  %s", l > 9 ? "" : "  ", l, cvar, value )
			}
			if ( g_Punish_Count > 0 )
			{
				for ( new j = 2; j < g_Punish_Count; ++j )
				{
					if ( plugin_id == Plugin_Punishments[ j ][ punish_id ] )
					{
						l++
						get_pcvar_string( pcvar_handle, value, 31 )
						get_plugin( Plugin_Punishments[ j ][ punish_id ], null, 0, temp, 31, version, 7, author, 31, null, 0 )
						console_print( id, " [%s%i]  %s  -  %s  %s", l > 9 ? "" : "  ", l, temp, cvar, value )
					}
				}
			}
			if ( g_Addon_Count > 0 )
			{
				for ( new k; k < g_Addon_Count; ++k )
				{
					if ( plugin_id == Plugin_Addons[ k ][ addon_id ] )
					{
						l++
						get_pcvar_string( pcvar_handle, value, 31 )
						get_plugin( Plugin_Addons[ k ][ addon_id ], null, 0, temp, 31, version, 7, author, 31, null, 0 )
						console_print( id, " [%s%i]  %s  -  %s  %s", l > 9 ? "" : "  ", l, temp, cvar, value )
					}
				}
			}
		}

		console_print( id, "%i settings", l )
	}
	else if ( equali( cmd, "players" ) )
	{
		console_print( id, "registered players:  %i/%i", get_playersnum(), maxplayers )

		for ( new player = 1; player <= maxplayers; ++player )
		{
			if ( is_user_connected( player ) )
			{
				get_user_name( player, temp, 31 )
				console_print( id, " [%s%i]  %s  -  Team Attacks:  %i/%i  -  Team Kills:  %i/%i%s", player > 9 ? "" : "  ", player, temp, TeamAttacks[ player ],
					get_pcvar_num( gCVARTeamAttacks ), TeamKills[ player ], get_pcvar_num( gCVARTeamKills ), check_immunity( player ) ? "  -  ADMIN" : "" )
			}
		}
	}
	else if ( equali( cmd, "punishments" ) )
	{
		console_print( id, "registered punishments:  %i/%i", g_Punish_Count, MAX_PUNISHMENTS )

		if ( g_Punish_Count > 0 )
		{
			console_print( id, " [  1]  Forgive  1.0  -  ATAC Team" )
			console_print( id, " [  2]  IncreaseTK  1.0  -  ATAC Team" )

			for ( new i = 2; i < g_Punish_Count; ++i )
			{
				get_plugin( Plugin_Punishments[ i ][ punish_id ], null, 0, temp, 31, version, 7, author, 31, null, 0 )
				console_print( id, " [%s%i]  %s  %s  -  %s", i + 1 > 9 ? "" : "  ", i + 1, temp, version, author )
			}
		}
	}
	else if ( equali( cmd, "addons" ) )
	{
		console_print( id, "registered addons:  %i/%i", g_Addon_Count, MAX_ADDONS )

		if ( g_Addon_Count > 0 )
		{
			for ( new i; i < g_Addon_Count; ++i )
			{
				get_plugin( Plugin_Addons[ i ][ addon_id ], null, 0, temp, 31, version, 7, author, 31, null, 0 )
				console_print( id, " [%s%i]  %s  %s  -  %s", i + 1 > 9 ? "" : "  ", i + 1, temp, version, author )
			}
		}
	}
	else if ( equali( cmd, "credits" ) )
	{
		console_print( id, "   Aleksander  ^"OLO^"  Naszko  -  Original TA/TK plugin from which ATAC was born" )
		console_print( id, "   Aaron  ^"f117bomb^"  Drabeck  -  Co-Author who worked on ATAC 0.x - 2.5" )
		console_print( id, "   teame06  -  Converting and improving ATAC 2.5.x for AMX Mod X" )
		console_print( id, "   AMX Mod X  -  For its powerful features which makes ATAC 3 possible" )
		console_print( id, "   Space Headed Productions  -  For supporting and hosting ATAC 3" )
	}
	else if ( equali( cmd, "team" ) )
	{
		console_print( id, "   Phil  ^"Orangutanz^"  Poland  -  Lead coder, original ATAC co-author" )
		console_print( id, "   Brad Jones  -  ATAC core, Punishment and Addon coder ")
		console_print( id, "   Christoph  ^"DevconeS^"  Amrein  -  Punishment and Addon coder" )
	}
	else
	{
		console_print( id, "usage: atac <command>^ncommands:" )
		console_print( id, "   off  -  turns atac off" )
		console_print( id, "   on  -  turns atac on" )
		console_print( id, "   version  -  display atac version info" )
		console_print( id, "   settings  -  display atac settings info" )
		console_print( id, "   players  -  displays players info" )
		console_print( id, "   punishments  -  display atac punishments info" )
		console_print( id, "   addons  -  display atac addons info" )
		console_print( id, "   credits  -  display atac credits info" )
		console_print( id, "   team  -  display atac team info") 
	}

	return PLUGIN_HANDLED
}

public ClientCommand_fullupdate( id )
{
	return PLUGIN_HANDLED
}

public ClientCommand_atacstatus( id )
{
	if ( !g_atac_on )
		return PLUGIN_CONTINUE

	client_print( id, print_chat, "*  [ATAC] Team Attacks: %i/%i  -  Team Kills: %i/%i", TeamAttacks[ id ], get_pcvar_num( gCVARTeamAttacks ), TeamKills[ id ], get_pcvar_num( gCVARTeamKills ) )
	return PLUGIN_HANDLED
}

public Event_ResetHUD( id )
{
	if ( !g_atac_on || gRestart )
		return PLUGIN_CONTINUE

	TeamAttacks[ id ] = 0
	set_pev( id, pev_dmg_inflictor, 0 )
	g_hp[ id ] = get_user_health( id )
	set_task( 0.5, "delay_Punishment", id )
	return PLUGIN_CONTINUE
}

public Event_Health( id )
{
	if ( !g_atac_on )
		return PLUGIN_CONTINUE

	new hp = read_data( 1 )

	if ( hp >= g_hp[ id ] ) 	// Player gained health, update and break
	{
		g_hp[ id ] = hp
		return PLUGIN_CONTINUE
	}

	new damage = g_hp[ id ] - hp
	g_hp[ id ] = hp
	new attacker = pev( id, pev_dmg_inflictor )

	if ( !is_user_connected( attacker ) )
	{
		new owner = EntOwner[ attacker ]

		if ( is_user_connected( owner ) )
		{
			attacker = owner

			if ( get_pcvar_num( gCVARTKAfterdeath ) && !is_user_alive( attacker ) )
				return PLUGIN_CONTINUE
		}
		else
		{
			EntOwner[ attacker ] = 0
			return PLUGIN_CONTINUE // Something seriously messed up so return
		}
	}
	
	check_teamattack( attacker, id, damage )
	return PLUGIN_CONTINUE
}

check_teamattack( attacker, victim, damage )
{
	new aTeam = get_user_team( attacker )
	new vTeam = get_user_team( victim )
	new team_attacks = get_pcvar_num( gCVARTeamAttacks )

	if ( !team_attacks || aTeam != vTeam || victim == attacker || check_immunity( attacker ) == 2 )
		return

	TeamAttacks[ attacker ] = min( ++TeamAttacks[ attacker ], team_attacks )
	exec_TeamAttack( attacker, victim, damage )

	if ( TeamAttacks[ attacker ] >= team_attacks )
	{
		TeamAttacks[ attacker ] = 0
		check_teamkills( attacker )
	}
}

public Event_DeathMsg()
{
	if ( !g_atac_on )
		return PLUGIN_CONTINUE

	new killer = read_data( 1 )
	new victim = read_data( 2 )

	new punishhook = find_punishhook( victim, ATAC_HOOK_RESET )

	while ( punishhook )
	{
		exec_Punishment( victim, 0, ATAC_HOOK_RESET, punishhook )
		punishhook = find_punishhook( victim, ATAC_HOOK_RESET )
	}

	if ( get_pcvar_num( gCVARTKAfterdeath ) && !is_user_alive( killer ) )
		return PLUGIN_CONTINUE

	check_teamkill( killer, victim )
	return PLUGIN_CONTINUE
}

check_teamkill( killer, victim )
{
	new kTeam = get_user_team( killer )
	new vTeam = get_user_team( victim )

	if ( !get_pcvar_num( gCVARTeamKills ) || kTeam != vTeam || victim == killer || check_immunity( killer ) == 2 )
		return

	TeamAttacks[ killer ] = 0
	exec_TeamKill( killer, victim )

	if ( get_pcvar_num( gCVARMenu ) )
	{
		if ( !CurrentKiller[ victim ] )
		{
			CurrentKiller[ victim ] = killer
			menu_status( victim, killer, 0 )
		}
		else
			KilledMenu[ killer ][ victim ]++
	}
	else
		check_teamkills( killer )
}

check_menus( killer )
{
	for ( new id = 1; id <= maxplayers; ++id )
	{
		if ( CurrentKiller[ id ] == killer )
		{
			menu_status( id, killer, g_UserPage[ id ] )
			return
		}
	}
}

check_teamkills( id )
{
	if ( !check_immunity( id ) )
	{
		new max_tk = get_pcvar_num( gCVARTeamKills )
		TeamKills[ id ] = min( ++TeamKills[ id ], max_tk )
		check_menus( id )

		new ban
		if ( contain( KillerAuthID[ id ], "." ) > 0 )
			ban = 1
		else if ( contain( KillerAuthID[ id ], ":" ) > 0 )
			ban = 2
		else
			ban = 0

		if ( !get_pcvar_num( gCVARBanType ) )
			ban = 0

		get_user_name( id, KillerName[ id ], 31 )
		new rtn = exec_CheckKill( id, ban )

		if ( rtn < 1 )
		{
			if ( TeamKills[ id ] >= max_tk )
			{
				if ( ban )
					server_cmd( "%s ^"%i^" ^"%s^";wait;%s", ( ban == 1 ) ? "addip" : "banid", get_pcvar_num( gCVARBanTime ), KillerAuthID[ id ], ( ban == 1 ) ? "writeip" : "writeid" )

				if ( is_user_connected( id ) )
				{
					new line1[ 32 ], line2[ 32 ], line3[ 32 ]
					formatex( line1, sizeof( line1 ) - 1, "%L", id, !ban ? "ATAC_KICKED_LINE1" : "ATAC_BANNED_LINE1" )
					formatex( line2, sizeof( line2 ) - 1, "%L", id, !ban ? "ATAC_KICKED_LINE2" : "ATAC_BANNED_LINE2" )
					formatex( line3, sizeof( line3 ) - 1, "%L", id, !ban ? "ATAC_KICKED_LINE3" : "ATAC_BANNED_LINE3" )
					kick_ML( id, line1, line2, line3 )
				}
			}
		}
	}
}

show_atac_menu( id, killer, page )
{
	get_user_name( killer, KillerName[ killer ], 31 )
	new max_tk = get_pcvar_num( gCVARTeamKills )

	if ( TeamKills[ killer ] >= max_tk - 1 )
		page = -1

	if ( is_user_bot( id ) )
	{
		new param[ 2 ]
		param[ 0 ] = id
		param[ 1 ] = page
		set_task( 0.2, "show_atac_botmenu", 0, param, 2 )
		return PLUGIN_HANDLED
	}

	new szMenuBody[ 1024 ], keys
	new iLen = formatex( szMenuBody, sizeof( szMenuBody ) - 1, "%L^n^n", id, "ATAC_CHOOSE", g_ColourMenus ? "\y" : "", g_ColourMenus ? "\d" : "", TeamKills[ id ], max_tk, g_ColourMenus ? "\y" : "", KillerName[ killer ], g_ColourMenus ? "\w" : "" )
	
	switch ( page )
	{
		case -1:
		{
			keys |= ( 1 << 0 )|( 1 << 1 )
			iLen += formatex( szMenuBody[ iLen ], sizeof( szMenuBody ) - 1 - iLen, "1. %L^n", id, "ATAC_FORGIVE" )
			iLen += formatex( szMenuBody[ iLen ], sizeof( szMenuBody ) - 1 - iLen, "2. %L^n", id, "ATAC_KICK" )

			if ( get_pcvar_num( gCVARBanType) > 0 )
			{
				keys |= ( 1 << 2 )
				new ban_time = get_pcvar_num( gCVARBanTime )

				if ( ban_time )
					iLen += formatex( szMenuBody[ iLen ], sizeof( szMenuBody ) - 1 - iLen, "3. %L", id, "ATAC_BAN_MIN", ban_time )
				else
					iLen += formatex( szMenuBody[ iLen ], sizeof( szMenuBody ) - 1 - iLen, "3. %L", id, "ATAC_BAN_PERM" )
			}
		}
		default:
		{
			new start = page * 8
			new end = start + 8
			new name[ 64 ]

			for ( new i = start; i < end; i++ )
			{
				name = exec_PunishName( page * 8 + i - start, id )

				if ( name[ 0 ] != 0 )
				{
					keys |= ( 1 << i - start )
					iLen += formatex( szMenuBody[ iLen ], sizeof( szMenuBody ) - 1 - iLen, "%d. %s^n", i - start + 1, name )
				}
			}

			if ( end < g_Punish_Count )
			{
				keys |= ( 1 << 8 )
				iLen += formatex( szMenuBody[ iLen ], sizeof( szMenuBody ) - 1 - iLen, "^n9. %L", id, "ATAC_MORE" )
			}
			if ( page > 0 )
			{
				keys |= ( 1 << 9 )
				iLen += formatex( szMenuBody[ iLen ], sizeof( szMenuBody ) - 1 - iLen, "^n0. %L", id, "ATAC_BACK" )
			}
		}
	}

	g_UserPage[ id ] = page
	show_menu( id, keys, szMenuBody, -1, "ATAC_TK" )
	return PLUGIN_HANDLED
}

// KWo: Bot Menu Support
public show_atac_botmenu( param[ 2 ] )
{
	new id = param[ 0 ]

	if ( !is_user_connected( id ) )
		return
	
	new page = param[ 1 ]
	new iBotPunish, iBotKey, iBotPage

	if ( page == -1 )
	{
		if ( is_user_bot( CurrentKiller[ id ] ) )
			iBotKey = random_num( 0, 1 )
		else
			iBotKey = 0

		iBotPage = -1
	}
	else
	{
		iBotPunish = random_num( 0, g_Punish_Count - 1 )
		iBotKey = iBotPunish % 8
		iBotPage = iBotPunish / 8
	}

	g_UserPage[ id ] = iBotPage
	action_atac_menu( id, iBotKey, 0 )
}

public action_atac_menu( id, key, forced )
{
	if ( !g_atac_on )
		return PLUGIN_CONTINUE

	new killer = CurrentKiller[ id ]

	if ( killer )
	{
		new vName[ 32 ]
		get_user_name( id, vName, 31 )
		new page = g_UserPage[ id ]

		if ( ( page == -1 || page == 0 ) && key == 0 )
		{
			client_print( 0, print_chat, "* [ATAC] %L", LANG_PLAYER, "ATAC_FORGAVE", vName, KillerName[ killer ] )
			find_killer( id )
			return PLUGIN_HANDLED
		}

		switch ( page )
		{
			case -1:
			{
				switch ( key )
				{
					case 1:
					{
						client_print( 0, print_chat, "* [ATAC] %L", LANG_PLAYER, "ATAC_KICKED", vName, KillerName[ killer ] )					
						exec_CheckKill( killer, 0 )
						find_killer( id )

						if ( is_user_connected( killer ) )
						{
							new line1[ 32 ], line2[ 32 ], line3[ 32 ];
							formatex( line1, sizeof( line1 ) - 1, "%L", killer, "ATAC_KICKED_LINE1" )
							formatex( line2, sizeof( line2 ) - 1, "%L", killer, "ATAC_KICKED_LINE2" )
							formatex( line3, sizeof( line3 ) - 1, "%L", killer, "ATAC_KICKED_LINE3" )
							kick_ML( killer, line1, line2, line3 )
						}
						return PLUGIN_HANDLED
					}
					case 2:
						client_print( 0, print_chat, "* [ATAC] %L", LANG_PLAYER, "ATAC_BANNED", vName, KillerName[ killer ] )
				}
			}
			default:
			{
				switch ( key )
				{
					case 8:
					{
						show_atac_menu( id, killer, page + 1 )
						return PLUGIN_HANDLED
					}
					case 9:
					{
						show_atac_menu( id, killer, page - 1 )
						return PLUGIN_HANDLED
					}
					default:
					{
						if ( !forced )
						{
							if ( get_pcvar_num( gCVARShowPunishment ) )
							{
								new punishname[ 64 ]
								for ( new player = 1; player <= maxplayers; ++player )
								{
									if ( is_user_connected( player ) )
									{
										punishname = exec_PunishName( page * 8 + key, player )
										client_print( player, print_chat, "* [ATAC] %L (^"%s^")", player, "ATAC_PUNISHED", vName, KillerName[ killer ], punishname )
									}
								}
							}
							else
								client_print( 0, print_chat, "* [ATAC] %L", LANG_PLAYER, "ATAC_PUNISHED", vName, KillerName[ killer ] )
						}
						if ( is_user_connected( killer ) )
						{
							if ( !is_user_alive( killer ) )
								PlayerPunish[ killer ][ page * 8 + key ] = ATAC_HOOK_SPAWNED
							else
								exec_Punishment( killer, id, 0, page * 8 + key )
						}
					}
				}
			}
		}

		CurrentKiller[ id ] = 0

		if ( !forced )
		{
			find_killer( id )
			check_teamkills( killer )
		}
	}
	else
		find_killer( id )

	return PLUGIN_HANDLED
}

get_real_authid( id, authid[ 32 ] )
{
	new ban = get_pcvar_num( gCVARBanType )

	switch ( ban )
	{
		case 1:
			get_user_ip( id, authid, 31, 1 )

		case 2:
			get_user_authid( id, authid, 31 )

		default:
		{
			get_user_authid( id, authid, 31 )

			if ( equal( authid, "STEAM_ID_LAN" ) || equal( authid, "VALVE_ID_LAN" )
					|| equal( authid, "STEAM_ID_PENDING" ) || equal( authid, "VALVE_ID_PENDING" ) )
				get_user_ip( id, authid, 31, 1 )
		}
	}

	return authid
}

find_authid( authid[ 32 ] )
{
	new stored_authid[ 32 ]

	for ( new i; i <= g_StoreKill_Count; ++i )
	{
		parse( StoreKills[ i ], stored_authid, 31 )

		if ( equal( stored_authid, authid ) )
			return i
	}

	return -1
}

find_killer( id )
{
	for ( new player = 1; player <= maxplayers; ++player )
	{
		if ( KilledMenu[ player ][ id ] > 0 )
		{
			KilledMenu[ player ][ id ]--
			CurrentKiller[ id ] = player
			menu_status( id, player, 0 )
			return 1
		}
	}

	CurrentKiller[ id ] = 0
	g_UserPage[ id ] = 0
	return 0
}

find_punishhook( id, data )
{
	for ( new i = 2; i < MAX_PUNISHMENTS; ++i )
	{
		if ( PlayerPunish[ id ][ i ] == data )
			return i
	}

	return 0
}

check_immunity( id )
{
	if ( has_flag( id, g_immunityFlags ) )
		return get_pcvar_num( gCVARAdminsImmune )
		
	return 0
}

public delay_Punishment( id )
{
	new punishhook1 = find_punishhook( id, ATAC_HOOK_RESET )

	while ( punishhook1 )
	{
		exec_Punishment( id, 0, ATAC_HOOK_RESET, punishhook1 )
		punishhook1 = find_punishhook( id, ATAC_HOOK_RESET )
	}

	new punishhook2 = find_punishhook( id, ATAC_HOOK_SPAWNED )

	while ( punishhook2 )
	{
		exec_Punishment( id, 0, ATAC_HOOK_SPAWNED, punishhook2 )
		punishhook2 = find_punishhook( id, ATAC_HOOK_SPAWNED )
	}

	new menuid, keys
	get_user_menu( id, menuid, keys )

	if ( menuid == g_atac_menu )
		return

	if ( !menu_status( id, CurrentKiller[ id ], g_UserPage[ id ] ) )
		find_killer( id )
}

exec_PunishName( plugin_id, id )
{
	new name[ 64 ], rtn

	if ( plugin_id > 1 && Plugin_Punishments[ plugin_id ][ punish_id ] > 0 )
	{
		ExecuteForward( Plugin_Punishments[ plugin_id ][ fwd_name ], rtn, id )
		global_get( glb_pStringBase, rtn, name, 63 )
	}
	else if ( plugin_id == 0 || plugin_id == 1 )
		formatex( name, 63, "%L", id, plugin_id ? "ATAC_INCREASE_TK" : "ATAC_FORGIVE" )

	return name
}

exec_Punishment( killer, victim, punishhook, plugin_id )
{
	if ( plugin_id > 1 && Plugin_Punishments[ plugin_id ][ punish_id ] > 0 )
	{
		new rtn
		ExecuteForward( Plugin_Punishments[ plugin_id ][ PUNISH_SETTINGS:punishhook ], rtn, killer, victim )

		if ( rtn < 1 || rtn > 2 || rtn == punishhook )
			rtn = 0

		PlayerPunish[ killer ][ plugin_id ] = rtn

		if ( punishhook == ATAC_HOOK_CONTINUE || punishhook == ATAC_HOOK_SPAWNED )
		{
			for ( new i; i < MAX_ADDONS; ++i )
			{
				if ( Plugin_Addons[ i ][ addon_id ] > 0 )
					ExecuteForward( Plugin_Addons[ i ][ fwd_punish_active ], rtn, plugin_id, killer, victim )
			}
		}
	}
}

exec_TeamAttack( attacker, victim, damage )
{
	new rtn

	for ( new i; i < MAX_ADDONS; ++i )
	{
		if ( Plugin_Addons[ i ][ addon_id ] > 0 )
			ExecuteForward( Plugin_Addons[ i ][ fwd_attack ], rtn, attacker, victim, damage )
	}
}

exec_TeamKill( killer, victim )
{
	new rtn

	for ( new i; i < MAX_ADDONS; ++i )
	{
		if ( Plugin_Addons[ i ][ addon_id ] > 0 )
			ExecuteForward( Plugin_Addons[ i ][ fwd_kill ], rtn, killer, victim )
	}
}

exec_CheckKill( killer, type = 1 )
{
	new rtn, handle

	for ( new i; i < MAX_ADDONS; ++i )
	{
		if ( Plugin_Addons[ i ][ addon_id ] > 0 )
		{
			ExecuteForward( Plugin_Addons[ i ][ fwd_punished ], rtn, killer, KillerName[ killer ], KillerAuthID[ killer ], type )

			if ( handle < rtn )
				handle = rtn
		}
	}

	return handle
}

// << KWo: Menu Overwrite fix. >> << Orangutanz: Optimised for better performance >>
menu_status( victim, killer, page )
{
	if ( !victim || !killer )
		return 0

	new menuid, keys
	get_user_menu( victim, menuid, keys )

	if ( ( menuid < 1 ) || is_user_bot( victim ) || ( menuid == g_atac_menu ) || get_pcvar_num( gCVARMenuOverwrite ) > 0 )
	{
		show_atac_menu( victim, killer, page )
		return killer
	}
	else if ( menuid > 0 && !task_exists( MENU_TASK + victim ) )
	{
		new param[ 3 ]
		param[ 0 ] = victim
		param[ 1 ] = killer
		param[ 2 ] = page
		MenuCount[ victim ] = 0
		set_task( 1.0, "menu_check", MENU_TASK + victim , param, 3, "b" )
		return killer
	}

	return 0
}

public menu_check( param[ 3 ] )
{
	new victim = param[ 0 ]
	new killer = param[ 1 ]
	new page = param[ 2 ]
	MenuCount[victim]++

	if ( !victim || !is_user_connected( victim ) )
	{
		remove_task( MENU_TASK + victim )
		return
	}
	if ( MenuCount[ victim ] > 9 ) // Enforce menu after 10 seconds
	{
		show_atac_menu( victim, killer, page )
		remove_task( MENU_TASK + victim )
	}
	else
	{
		new menuid, keys
		get_user_menu( victim, menuid, keys )

		if ( ( menuid < 1 ) || ( menuid == g_atac_menu ) )
		{
			show_atac_menu( victim, killer, page )
			remove_task( MENU_TASK + victim )
		}
	}
}

#define SVC_DISCONNECT	2
/* SVC_DISCONNECT: ask the client to disconnect and show the given string in a popup dialog.
 *  -> (string) kick_reason: reason of the kick. It is shown to the client via
 *                           a popup dialog. It's content can't be large.
 *
 * Note: such messages are sent when using the <kick> command, or when the client
 *      disconnect himself. In the latter, no popup dialog is shown.
 */
/* Kick with a multilines reason */
kick_ML( id, line1[ 32 ], line2[ 32 ], line3[ 32 ] )
{
	new msg_content[ 128 ], pl_name[ 32 ], pl_userid, pl_authid[ 32 ];

	/* grab logging infos */
	pl_userid = get_user_userid( id );
	get_user_name( id, pl_name, sizeof( pl_name ) - 1 );
	get_user_authid( id, pl_authid, sizeof( pl_authid ) - 1 );

	/* do kick the player */
	format( msg_content, sizeof( msg_content ) - 1, "%s^n%s^n%s", line1, line2, line3 );
	message_begin( MSG_ONE, SVC_DISCONNECT, {0, 0, 0}, id );
	write_string( msg_content );
	message_end();
	
	/* log the kick as <kick> command do */
	log_message( "Kick: ^"%s<%d><%s><>^" was kicked by ^"Console^" (message ^"%s  %s  %s^")",
		pl_name, pl_userid, pl_authid, line1, line2, line3 );
}
