/*  AMXModX Script
*
*   Title:    Auto Round Restart (autorr)
*   Author:   SubStream
*
*   Current Version:   1.6
*   Release Date:      2007-10-13
*
*   For support on this plugin, please visit the following URL:
*   Auto Round Restart URL = http://forums.alliedmods.net/showthread.php?t=40583
*
*   Auto Round Restart - Manages Auto Round Restarts, lo3, switching of teams, and more
*   Copyright (C) 2006  SubStream
*
*   This program is free software; you can redistribute it and/or
*   modify it under the terms of the GNU General Public License
*   as published by the Free Software Foundation; either version 2
*   of the License, or (at your option) any later version.
*
*   This program is distributed in the hope that it will be useful,
*   but WITHOUT ANY WARRANTY; without even the implied warranty of
*   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
*   GNU General Public License for more details.
*
*   You should have received a copy of the GNU General Public License
*   along with this program; if not, write to the Free Software
*   Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
*
*   Author Contact Email: starlineclan@dj-rj.com
*/


#define SWITCH_TEAM_OPTIONS // comment this line out to disable all switch team options
#define ALLOW_HUD_TOGGLE // comment this line out to disable the hud toggle commands


#include <amxmodx>
#include <amxmisc>


#if defined SWITCH_TEAM_OPTIONS
	#include <cstrike>
	new gp_switchall
	new gp_switchkill
	new gp_specnchoose
	new bool: gb_IsSpecnChoose
#endif

#if defined ALLOW_HUD_TOGGLE
	#include <nvault>
	new const gs_VAULTNAME[]	= "showhudvault"
	new const gs_KEYNAMEADDON[]	= "showhud"
	new bool: gb_HideHud[33]
	new g_showhudvault
	new gs_keyname[60]
	new gi_vkey_value
	new gs_targetauthid[32]
#endif


new const gs_PLUGIN[]	= "Auto Round Restart"
new const gs_VERSION[]	= "1.6"
new const gs_AUTHOR[]	= "SubStream"


new const gs_FILENAME[]		= "lo3"
new const gs_FILETYPE[]		= ".cfg"


new gp_autorr_on
new gp_autorr_round
new gp_autorr_time
new gp_timewaitrnd
new gp_performlo3
new gp_lo3cfgfile
new gp_saylastround
new gp_hudmessage
new gp_sv_restart
new gp_mp_timelimit


new bool: gb_IsFirstRound
new bool: gb_IsAutoRestarting
new bool: gb_IsLiveOnThree
new bool: gb_Lo3Restart1
new bool: gb_Lo3Restart2
new bool: gb_IsAdminRestart
new bool: gb_IsARRCommand
new bool: gb_AreTherePlayers
new bool: gb_CanAddRounds
new bool: gb_TimeRRNextRound


new Float: gf_temptimelimit


new gs_directory[33]
new gs_lo3configfile[55]


new gi_roundnum
new gi_roundsleft
new gs_lang_lastround[100]
new gi_timeleft
new gi_minutespassed


new gs_t_players[32]
new gs_ct_players[32]
new gi_t_playercnt
new gi_ct_playercnt
new gs_adminname[32]
new gs_adminauthid[32]
new gs_lang_roundsleft[100]
new gs_lang_unable[100]
new gs_lang_timeleft[100]
new gs_lang_showhud[101]


new gi_players[32]
new gi_playercnt
new gi_playernum 
new gi_playerID

public plugin_init ()
{
	register_plugin ( gs_PLUGIN, gs_VERSION, gs_AUTHOR )
	register_cvar ( "autorr_version", gs_VERSION, FCVAR_SERVER|FCVAR_SPONLY )
	
	gp_autorr_on	= register_cvar ( "autorr_enable", "0" )
	gp_autorr_round	= register_cvar ( "autorr_round", "0" )
	gp_autorr_time	= register_cvar ( "autorr_time", "0" )
	gp_timewaitrnd	= register_cvar ( "autorr_timewaitround", "0" )
	gp_performlo3	= register_cvar ( "autorr_lo3", "0" )
	gp_lo3cfgfile	= register_cvar ( "autorr_lo3cfgfile", "0" )
	gp_saylastround	= register_cvar ( "autorr_saylastround", "0" )
	gp_hudmessage	= register_cvar ( "autorr_hudmessage", "0" )
	
	register_concmd ( "amx_restart", "fn_cmdamx_restart", ADMIN_LEVEL_A, "- Restarts the game at round 1" )
	register_concmd ( "amx_lo3", "fn_cmdamx_lo3", ADMIN_CFG, "- Executes lo3.cfg" )
	register_clcmd ( "say /restart", "fn_cmdamx_restart", ADMIN_LEVEL_A, "- Restarts the game at round 1" )
	register_clcmd ( "say /lo3", "fn_cmdamx_lo3", ADMIN_CFG, "- Executes lo3.cfg" )
	register_clcmd ( "say roundsleft", "fn_cmdroundsleft", 0, "- Displays how many rounds are left after the current round before an auto round restart will occur" )
	register_clcmd ( "say timeleftrr", "fn_cmdtimeleftrr", 0, "- Displays much time is left until an auto round restart will occur" )
	
	#if defined SWITCH_TEAM_OPTIONS
		gp_switchall	= register_cvar ( "autorr_autoswitchall", "0" )
		gp_switchkill	= register_cvar ( "autorr_switchallkill", "0" )
		gp_specnchoose	= register_cvar ( "autorr_specnchoose", "0" )
		register_concmd ( "amx_switchall", "fn_cmdamx_switchall", ADMIN_LEVEL_B, "- Switches all players to the opposite team" )
		register_concmd ( "amx_specnchoose", "fn_cmdamx_specnchoose", ADMIN_LEVEL_C, "- Sends everyone to spectate and brings up the choose team menu" )
		register_clcmd ( "say /switchall", "fn_cmdamx_switchall", ADMIN_LEVEL_B, "- Switches all players to the opposite team" )
		register_clcmd ( "say /specnchoose", "fn_cmdamx_specnchoose", ADMIN_LEVEL_C, "- Sends everyone to spectate and brings up the choose team menu" )
	#endif
	
	#if defined ALLOW_HUD_TOGGLE
		register_clcmd ( "say /hudoff", "fn_cmdsayhudoff", 0, "- Removes the AutoRR Hud Message" )
		register_clcmd ( "say /hudon", "fn_cmdsayhudon", 0, "- Displays the AutoRR Hud Message" )
		g_showhudvault = nvault_open ( gs_VAULTNAME )
	#endif
	
	gp_sv_restart	= get_cvar_pointer ( "sv_restart" )
	gp_mp_timelimit	= get_cvar_pointer ( "mp_timelimit" )
	
	register_logevent ( "fn_triggerroundstart" , 2, "1=Round_Start" )
	register_logevent ( "fn_triggersvrestart1" , 2, "1=Restart_Round_(1_second)" )
	register_logevent ( "fn_triggersvrestart3" , 2, "1=Restart_Round_(3_seconds)" )
	
	register_dictionary ( "autorr.txt" )
	
	set_task ( 1.0, "fn_checkiftime" )
}

public fn_checkiftime ()
{
	if ( fn_can_autorr_time () )
	{
		set_task ( 60.0, "fn_addminute", 0, "", 0, "b" )
	}
	
	else gi_minutespassed = 0
}

public fn_addminute ()
{
	if ( fn_can_autorr_time () )
	{
		get_players ( gs_t_players, gi_t_playercnt, "e", "TERRORIST" )
		get_players ( gs_ct_players, gi_ct_playercnt, "e", "CT" )
		
		if ( gi_t_playercnt > 0 && gi_ct_playercnt > 0 )
		{
			gi_minutespassed++
			
			if ( ! get_pcvar_num ( gp_timewaitrnd ) )
			{
				if ( fn_time_is_up () && ! gb_IsARRCommand == true && ! gb_IsAutoRestarting == true )
				{
					fn_autorestartround ()
				}
			}
			
			else
			{
				if ( gi_minutespassed == get_pcvar_num ( gp_autorr_time ) )
				{
					gb_TimeRRNextRound = true
					
					if ( get_pcvar_num ( gp_saylastround ) )
					{
						fn_saylastround ()
					}
				}
			}
		}
		
		else gi_minutespassed = 0
	}
	
	else gi_minutespassed = 0
}

public client_putinserver ( id )
{
	if ( get_pcvar_num ( gp_hudmessage ) )
	{
		set_task ( 5.0, "fn_showclienthud", id )
		
		#if defined ALLOW_HUD_TOGGLE
			set_task ( 30.0, "fn_putinserverdelay", id )
		#endif
	}
}

public fn_showclienthud ( id )
{
	if ( is_user_connected ( id ) )
	{
		#if defined ALLOW_HUD_TOGGLE
			if ( gb_HideHud[id] == true )
			{
				set_task ( 1.0, "fn_showclienthud", id )
				return PLUGIN_HANDLED
			}
		#endif
		
		if ( fn_can_autorr_round () )
		{
			gi_roundsleft = get_pcvar_num ( gp_autorr_round ) - gi_roundnum
			
			if ( gi_roundsleft == 0 ) formatex ( gs_lang_showhud, 100, "%L", id, "AUTORR_LANG_NOROUNDHUD" )
			else if ( gi_roundsleft == 1 ) formatex ( gs_lang_showhud, 100, "%L", id, "AUTORR_LANG_1ROUNDHUD" )
			else formatex ( gs_lang_showhud, 100, "%L", id, "AUTORR_LANG_ROUNDSHUD", gi_roundsleft )
		}
	
		if ( fn_can_autorr_time () )
		{
			gi_timeleft = get_pcvar_num ( gp_autorr_time ) - gi_minutespassed
			
			if ( gb_TimeRRNextRound == true ) formatex ( gs_lang_showhud, 100, "%L", id, "AUTORR_LANG_NOTIMEHUD" )
			else if ( gi_timeleft == 1 ) formatex ( gs_lang_showhud, 100, "%L", id, "AUTORR_LANG_1MINHUD" )
			else formatex ( gs_lang_showhud, 100, "%L", id, "AUTORR_LANG_TIMEHUD", gi_timeleft )
		}
		
		if ( ! fn_can_autorr_round () && ! fn_can_autorr_time () )
		{
			formatex ( gs_lang_showhud, 100, "%L", id, "AUTORR_LANG_HUDUNABLE" )
		}
		
		set_hudmessage ( 255, 255, 255, 0.3, 0.0, 0, 0.0, 1.0 )
		show_hudmessage ( id, gs_lang_showhud )
		
		set_task ( 1.0, "fn_showclienthud", id )
	}
	
	return PLUGIN_CONTINUE
}

#if defined ALLOW_HUD_TOGGLE
public fn_putinserverdelay ( id )
{
	get_user_authid ( id, gs_targetauthid, 31 )
	formatex ( gs_keyname, 59, "%s%s", gs_targetauthid, gs_KEYNAMEADDON )
	gi_vkey_value = nvault_get ( g_showhudvault, gs_keyname )
	if ( gi_vkey_value == 1 ) gb_HideHud[id] = true
	else gb_HideHud[id] = false
}
#endif

public fn_triggerroundstart ()
{
	if ( gb_TimeRRNextRound == true ) gb_TimeRRNextRound = false
	
	if ( ! gb_IsLiveOnThree == true )
	{
		if ( gb_IsAdminRestart == true )
		{
			gb_IsFirstRound = true
			gb_IsAdminRestart = false
		}
		
		get_players ( gs_t_players, gi_t_playercnt, "e", "TERRORIST" )
		get_players ( gs_ct_players, gi_ct_playercnt, "e", "CT" )
		
		if ( gi_t_playercnt > 0 && gi_ct_playercnt > 0 )
		{
			gb_AreTherePlayers = true
			
			#if defined SWITCH_TEAM_OPTIONS
				if ( gb_IsSpecnChoose == true )
				{
					gb_IsFirstRound = true
					gb_IsSpecnChoose = false
				}
			#endif
			
			fn_checkisfirstround ()
			
			if ( fn_can_autorr_time () && get_pcvar_num ( gp_timewaitrnd ) && fn_time_is_up () && ! gb_IsARRCommand == true && ! gb_IsAutoRestarting == true )
			{
				fn_autorestartround ()
			}
			
			if ( fn_can_autorr_round () )
			{
				if ( ! gb_CanAddRounds == false ) gi_roundnum++
				
				if ( get_pcvar_num ( gp_saylastround ) && gi_roundnum == get_pcvar_num ( gp_autorr_round ) )
				{
					fn_saylastround ()
				}
				
				if ( gi_roundnum > get_pcvar_num ( gp_autorr_round ) && ! gb_IsARRCommand == true && ! gb_IsAutoRestarting == true )
				{
					fn_autorestartround ()
				}
				
				if ( gb_CanAddRounds == false ) gb_CanAddRounds = true
			}
		}
		
		if ( gi_t_playercnt == 0 || gi_ct_playercnt == 0 )
		{
			gb_AreTherePlayers = false
			
			#if defined SWITCH_TEAM_OPTIONS
				if ( ! gb_IsSpecnChoose == true ) fn_checkisfirstround ()
			#else
				fn_checkisfirstround ()
			#endif
		}
	}
}

public fn_saylastround ()
{
	formatex ( gs_lang_lastround, 99, "%L", 0, "AUTORR_LANG_LASTROUND" )
	
	get_players ( gi_players, gi_playercnt, "ch" )
	
	for ( gi_playernum = 0; gi_playernum < gi_playercnt; gi_playernum++ )
	{
		gi_playerID = gi_players[gi_playernum]
		
		set_hudmessage ( 255, 0, 0, -1.0, 0.45, 0, 6.0, 12.0 )
		show_hudmessage ( gi_playerID, gs_lang_lastround )
	}
}

public fn_autorestartround ()
{
	if ( get_pcvar_float ( gp_mp_timelimit ) ) gf_temptimelimit = ( float ( get_timeleft () ) / 60.0 )
	gi_roundnum = 0
	gi_minutespassed = 0
	gb_IsAutoRestarting = true
	
	#if defined SWITCH_TEAM_OPTIONS
		if ( get_pcvar_num ( gp_specnchoose ) )
		{
			gb_IsSpecnChoose = true
			fn_specnchoose ()
		}
		
		if ( ! gb_IsSpecnChoose == true )
		{
			if ( get_pcvar_num ( gp_switchall ) ) fn_switchall ()
			fn_restartorlo3 ()
		}
	#else
		fn_restartorlo3 ()
	#endif
}

public fn_checkisfirstround ()
{
	if ( gb_IsFirstRound == true )
	{
		if ( gb_IsAutoRestarting == true && get_pcvar_float ( gp_mp_timelimit ) ) set_pcvar_float ( gp_mp_timelimit, gf_temptimelimit )
		
		gb_IsFirstRound = false
		gb_IsARRCommand = false
		gb_IsAutoRestarting = false
		
		if ( fn_can_autorr_round () && gb_AreTherePlayers == true )
		{
			gb_CanAddRounds = false
			gi_roundnum = 1
		}
		
		if ( fn_can_autorr_round () && ! gb_AreTherePlayers == true ) gi_roundnum = 0
		if ( fn_can_autorr_time () ) gi_minutespassed = 0
	}
}

public fn_restartorlo3 ()
{
	if ( ! gb_IsLiveOnThree == true || ! gb_IsAdminRestart == true )
	{
		switch ( get_pcvar_num ( gp_performlo3 ) )
		{
			case 1: fn_execlo3part1 ()
			case 0:
			{
				gb_IsFirstRound = true
				set_pcvar_num ( gp_sv_restart, 1 )
			}
		}
	}
}

public fn_execlo3part1 ()
{
	gb_IsLiveOnThree = true
	
	if ( get_pcvar_num ( gp_lo3cfgfile ) )
	{
		get_configsdir ( gs_directory, 32 )
		formatex ( gs_lo3configfile, 54, "%s/%s%s", gs_directory, gs_FILENAME, gs_FILETYPE )
		if ( file_exists ( gs_lo3configfile ) ) server_cmd ( "exec %s", gs_lo3configfile )
		return PLUGIN_HANDLED
	}
	
	server_cmd ( "say ^"---- Going live in 3 restarts ----" )
	set_task ( 1.0, "fn_execlo3part2" )
	
	return PLUGIN_CONTINUE
}

public fn_execlo3part2 ()
{
	gb_Lo3Restart1 = true
	server_cmd ( "say ^"---- LIVE ON THREE ----" )
	set_pcvar_num ( gp_sv_restart, 1 )
	server_cmd ( "say ^"---- RESTART #1 ----" )
}

public fn_triggersvrestart1 ()
{
	if ( gb_IsLiveOnThree == true && ! get_pcvar_num ( gp_lo3cfgfile ) ) set_task ( 1.1, "fn_triggersvrestart1delay" )
}

public fn_triggersvrestart1delay ()
{
	if ( gb_IsLiveOnThree == true )
	{
		if ( gb_Lo3Restart2 == true )
		{
			gb_Lo3Restart2 = false
			server_cmd ( "say ^"---- LIVE ON NEXT RESTART ----" )
			set_pcvar_num ( gp_sv_restart, 3 )
			server_cmd ( "say ^"---- RESTART #3 ----" )
		}
		
		if ( gb_Lo3Restart1 == true )
		{
			gb_Lo3Restart1 = false
			gb_Lo3Restart2 = true
			server_cmd ( "say ^"---- LIVE ON TWO ----" )
			set_pcvar_num ( gp_sv_restart, 1 )
			server_cmd ( "say ^"---- RESTART #2 ----" )
		}
	}
}

public fn_triggersvrestart3 ()
{
	set_task ( 3.1, "fn_triggersvrestart3delay" )
}

public fn_triggersvrestart3delay ()
{
	if ( gb_IsLiveOnThree == true )
	{
		if ( ! get_pcvar_num ( gp_lo3cfgfile ) )
		{
			set_task ( 0.2, "fn_saylive", 0, "", 0, "a", 5 )
			set_task ( 1.1, "fn_saygoodluck" )
		}
		
		gb_IsFirstRound = true
		gb_IsLiveOnThree = false
		
		get_players ( gs_t_players, gi_t_playercnt, "e", "TERRORIST" )
		get_players ( gs_ct_players, gi_ct_playercnt, "e", "CT" )
		
		if ( gi_t_playercnt > 0 && gi_ct_playercnt > 0 ) gb_AreTherePlayers = true
		else gb_AreTherePlayers = false			
	}
	
	fn_checkisfirstround ()
}

public fn_saylive ()
{
	server_cmd ( "say ^"-- L ---" )
	server_cmd ( "say ^"--- I ---" )
	server_cmd ( "say ^"---- V ---" )
	server_cmd ( "say ^"----- E ---" )
}

public fn_saygoodluck ()
{
	server_cmd ( "say ^"Good Luck - Have Fun!" )
}

public fn_cmdamx_restart ( id, level, cid )
{
	if ( ! cmd_access ( id, level, cid, 1 ) ) return PLUGIN_HANDLED
	
	if ( gb_IsAutoRestarting == true )
	{
		console_print ( id, "[AMXX] %L", id, "AUTORR_LANG_CANNOT_ADMIN1" )
		return PLUGIN_HANDLED
	}
	
	if ( gb_IsARRCommand == true )
	{
		console_print ( id, "[AMXX] %L", id, "AUTORR_LANG_CANNOT_ADMIN2" )
		return PLUGIN_HANDLED
	}
	
	get_user_name ( id, gs_adminname, 31 )
	get_user_authid ( id, gs_adminauthid, 31 )
		
	log_amx ( "Cmd: %L", LANG_SERVER, "AUTORR_LANG_LOG1", gs_adminname, get_user_userid ( id ), gs_adminauthid )
	
	console_print ( id, "[AMXX] %L", id, "AUTORR_LANG_CLIENT_RESTART" )
	
	gb_IsAdminRestart = true
	gb_IsARRCommand = true
	set_pcvar_num ( gp_sv_restart, 1 )
	
	switch ( get_cvar_num ( "amx_show_activity" ) )
	{
		case 2: client_print ( 0, print_chat, "%L", id, "AUTORR_LANG_ADMIN_RESTART_2", gs_adminname )
		case 1: client_print ( 0, print_chat, "%L", id, "AUTORR_LANG_ADMIN_RESTART_1" )
	}
	
	return PLUGIN_HANDLED
}

public fn_cmdamx_lo3 ( id, level, cid )
{
	if ( ! cmd_access ( id, level, cid, 1 ) ) return PLUGIN_HANDLED
	
	if ( gb_IsAutoRestarting == true )
	{
		console_print ( id, "[AMXX] %L", id, "AUTORR_LANG_CANNOT_ADMIN1" )
		return PLUGIN_HANDLED
	}
	
	if ( gb_IsARRCommand == true )
	{
		console_print ( id, "[AMXX] %L", id, "AUTORR_LANG_CANNOT_ADMIN2" )
		return PLUGIN_HANDLED
	}
	
	get_user_name ( id, gs_adminname, 31 )
	get_user_authid ( id, gs_adminauthid, 31 )
		
	log_amx ( "Cmd: %L", LANG_SERVER, "AUTORR_LANG_LOG2", gs_adminname, get_user_userid ( id ), gs_adminauthid )
	
	console_print ( id, "[AMXX] %L", id, "AUTORR_LANG_CLIENT_LO3" )
	
	gb_IsARRCommand = true
	fn_execlo3part1 ()
	
	switch ( get_cvar_num ( "amx_show_activity" ) )
	{
		case 2: client_print ( 0, print_chat, "%L", id, "AUTORR_LANG_ADMIN_LO3_2", gs_adminname )
		case 1: client_print ( 0, print_chat, "%L", id, "AUTORR_LANG_ADMIN_LO3_1" )
	}
	
	return PLUGIN_HANDLED
}

public fn_cmdroundsleft ( id )
{
	if ( fn_can_autorr_round () )
	{
		gi_roundsleft = get_pcvar_num ( gp_autorr_round ) - gi_roundnum
		
		if ( gi_roundsleft == 0 ) formatex ( gs_lang_roundsleft, 99, "%L", id, "AUTORR_LANG_NOROUNDSLEFT" )
		else if ( gi_roundsleft == 1 ) formatex ( gs_lang_roundsleft, 99, "%L", id, "AUTORR_LANG_1ROUNDLEFT" )
		else formatex ( gs_lang_roundsleft, 99, "%L", id, "AUTORR_LANG_ROUNDSLEFT", gi_roundsleft )
		
		client_print ( 0, print_chat, gs_lang_roundsleft )
	}
	
	else
	{
		formatex ( gs_lang_unable, 99, "%L", id, "AUTORR_LANG_UNABLEROUND" )
		client_print ( id, print_chat, gs_lang_unable )
		return PLUGIN_HANDLED
	}
	
	return PLUGIN_CONTINUE
}

public fn_cmdtimeleftrr ( id )
{
	if ( fn_can_autorr_time () )
	{
		gi_timeleft = get_pcvar_num ( gp_autorr_time ) - gi_minutespassed
		
		if ( gb_TimeRRNextRound == true ) formatex ( gs_lang_timeleft, 99, "%L", id, "AUTORR_LANG_NOTIMELEFT" )
		else if ( gi_timeleft == 1 ) formatex ( gs_lang_timeleft, 99, "%L", id, "AUTORR_LANG_1MINUTE" )
		else formatex ( gs_lang_timeleft, 99, "%L", id, "AUTORR_LANG_TIMELEFT", gi_timeleft )
		
		client_print ( 0, print_chat, gs_lang_timeleft )
	}
	
	else
	{
		formatex ( gs_lang_unable, 99, "%L", id, "AUTORR_LANG_UNABLETIME" )
		client_print ( id, print_chat, gs_lang_unable )
		return PLUGIN_HANDLED
	}
	
	return PLUGIN_CONTINUE
}

#if defined SWITCH_TEAM_OPTIONS
public fn_switchall ()
{
	get_players ( gi_players, gi_playercnt, "h" )
	
	for ( gi_playernum = 0; gi_playernum < gi_playercnt; gi_playernum++ )
	{
		gi_playerID = gi_players[gi_playernum]
		
		if ( get_user_team ( gi_playerID ) == 1 )
		{
			fn_if_then_kill ( gi_playerID )
			cs_set_user_team ( gi_playerID, 2 )
			cs_reset_user_model ( gi_playerID )
		}
		
		else if ( get_user_team ( gi_playerID ) == 2 )
		{
			fn_if_then_kill ( gi_playerID )
			cs_set_user_team ( gi_playerID, 1 )
			cs_reset_user_model ( gi_playerID )
		}
	}
	
	gb_IsARRCommand = false
}

public fn_if_then_kill ( id )
{
	if ( get_pcvar_num ( gp_switchkill ) ) user_kill ( id )
}

public fn_specnchoose ()
{
	get_players ( gi_players, gi_playercnt, "h" )
	
	for ( gi_playernum = 0; gi_playernum < gi_playercnt; gi_playernum++ )
	{
		gi_playerID = gi_players[gi_playernum]
		
		if ( ! ( get_user_team ( gi_playerID ) == 3 ) )
		{
			user_kill ( gi_playerID )
			cs_set_user_team ( gi_playerID, 3 )
			engclient_cmd ( gi_playerID, "chooseteam" )
		}
	}
}

public fn_cmdamx_switchall ( id, level, cid )
{
	if ( ! cmd_access ( id, level, cid, 1 ) ) return PLUGIN_HANDLED
	
	if ( gb_IsAutoRestarting == true )
	{
		console_print ( id, "[AMXX] %L", id, "AUTORR_LANG_CANNOT_ADMIN1" )
		return PLUGIN_HANDLED
	}
	
	if ( gb_IsARRCommand == true )
	{
		console_print ( id, "[AMXX] %L", id, "AUTORR_LANG_CANNOT_ADMIN2" )
		return PLUGIN_HANDLED
	}
	
	get_user_name ( id, gs_adminname, 31 )
	get_user_authid ( id, gs_adminauthid, 31 )
		
	log_amx ( "Cmd: %L", LANG_SERVER, "AUTORR_LANG_LOG3", gs_adminname, get_user_userid ( id ), gs_adminauthid )
	
	console_print ( id, "[AMXX] %L", id, "AUTORR_LANG_CLIENT_SWITCHALL" )
	
	gb_IsARRCommand = true
	fn_switchall ()
	
	switch ( get_cvar_num ( "amx_show_activity" ) )
	{
		case 2: client_print ( 0, print_chat, "%L", id, "AUTORR_LANG_ADMIN_SWITCHALL_2", gs_adminname )
		case 1: client_print ( 0, print_chat, "%L", id, "AUTORR_LANG_ADMIN_SWITCHALL_1" )
	}
	
	return PLUGIN_HANDLED
}

public fn_cmdamx_specnchoose ( id, level, cid )
{
	if ( ! cmd_access ( id, level, cid, 1 ) ) return PLUGIN_HANDLED
	
	if ( gb_IsAutoRestarting == true )
	{
		console_print ( id, "[AMXX] %L", id, "AUTORR_LANG_CANNOT_ADMIN1" )
		return PLUGIN_HANDLED
	}
	
	if ( gb_IsARRCommand == true )
	{
		console_print ( id, "[AMXX] %L", id, "AUTORR_LANG_CANNOT_ADMIN2" )
		return PLUGIN_HANDLED
	}
	
	get_user_name ( id, gs_adminname, 31 )
	get_user_authid ( id, gs_adminauthid, 31 )
		
	log_amx ( "Cmd: %L", LANG_SERVER, "AUTORR_LANG_LOG4", gs_adminname, get_user_userid ( id ), gs_adminauthid )
	
	console_print ( id, "[AMXX] %L", id, "AUTORR_LANG_CLIENT_SPECNCHOOSE" )
	
	gb_IsSpecnChoose = true
	gb_IsARRCommand = true
	fn_specnchoose ()
	
	switch ( get_cvar_num ( "amx_show_activity" ) )
	{
		case 2: client_print ( 0, print_chat, "%L", id, "AUTORR_LANG_ADMIN_SPECNCHOOSE_2", gs_adminname )
		case 1: client_print ( 0, print_chat, "%L", id, "AUTORR_LANG_ADMIN_SPECNCHOOSE_1" )
	}
	
	return PLUGIN_HANDLED
}
#endif

#if defined ALLOW_HUD_TOGGLE
public fn_cmdsayhudoff ( id )
{
	gb_HideHud[id] = true
	get_user_authid ( id, gs_targetauthid, 31 )
	formatex ( gs_keyname, 59, "%s%s", gs_targetauthid, gs_KEYNAMEADDON )
	nvault_pset ( g_showhudvault, gs_keyname, "1" )
	return PLUGIN_HANDLED
}

public fn_cmdsayhudon ( id )
{
	gb_HideHud[id] = false
	get_user_authid ( id, gs_targetauthid, 31 )
	formatex ( gs_keyname, 59, "%s%s", gs_targetauthid, gs_KEYNAMEADDON )
	nvault_pset ( g_showhudvault, gs_keyname, "0" )
	nvault_remove ( g_showhudvault, gs_keyname )
	return PLUGIN_HANDLED
}
#endif

stock fn_can_autorr_round ()
{
	if ( get_pcvar_num ( gp_autorr_on ) && get_pcvar_num ( gp_autorr_round ) && ! get_pcvar_num ( gp_autorr_time ) ) return 1
	
	return 0
}

stock fn_can_autorr_time ()
{
	if ( get_pcvar_num ( gp_autorr_on ) && ! get_pcvar_num ( gp_autorr_round ) && get_pcvar_num ( gp_autorr_time ) ) return 1
	
	return 0
}

stock fn_time_is_up ()
{
	if ( gi_minutespassed >= get_pcvar_num ( gp_autorr_time ) ) return 1
	
	return 0
}
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1033\\ f0\\ fs16 \n\\ par }
*/
