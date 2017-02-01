/*  AMXModX Script
*
*   Title:    Restrict Commands (restrictcommands)
*   Author:   SubStream
*
*   Current Version:   2.1
*   Release Date:      2006-07-24
*
*   For support on this plugin, please visit the following URL:
*   Restrict Commands URL = http://forums.alliedmods.net/showthread.php?t=27089
*
*   Restrict Commands - Allows Admin to restrict commands.
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


#include <amxmodx>
#include <amxmisc>
#include <engine>
#include <nvault>


new const gs_PLUGIN[]	= "Restrict Commands"
new const gs_VERSION[]	= "2.1"
new const gs_AUTHOR[]	= "SubStream"


new const gs_FILENAME[]		= "restrictcommands"
new const gs_FILETYPE[]		= ".cfg"
new const gs_VAULTNAME[]	= "rcflagvault"


new bool: gb_CommandFlag[41][33]


new gs_directory[33]
new gs_rcconfigfile[55]


new gs_clcmdarg0[15]
new gs_rcplayerarg1[33]
new gs_rcplayerarg2[15]
new gi_targetID
new gs_adminname[32]
new gs_adminauthid[32]
new gs_targetname[32]
new gs_targetauthid[32]
new gs_rcinfoarg1[33]


new g_rcflagvault
new gs_keyname[60]
new gi_vkey_value


new gi_linenum
new gp_pcvar[42]
new gs_cvar[30]
new gi_rcslotnum

new gs_rcarray[42][] =
{
	"attack",
	"attack2",
	"reload",
	"use",
	"impulse100",
	"impulse201",
	"buyequip",
	"chooseteam",
	"cl_autobuy",
	"cl_setautobuy",
	"coverme",
	"drop",
	"enemydown",
	"enemyspot",
	"fallback",
	"followme",
	"getinpos",
	"getout",
	"go",
	"holdpos",
	"inposition",
	"lastinv",
	"needbackup",
	"negative",
	"nightvision",
	"radio1",
	"radio2",
	"radio3",
	"regroup",
	"report",
	"reportingin",
	"roger",
	"say",
	"say_team",
	"sectorclear",
	"sticktog",
	"stormfront",
	"takepoint",
	"takingfire",
	"weapon_knife",
	"weapon_c4",
	"immunity"
}


public plugin_init ()
{
	register_plugin ( gs_PLUGIN, gs_VERSION, gs_AUTHOR )
	register_cvar ( "restrictcommands_version", gs_VERSION, FCVAR_SERVER|FCVAR_SPONLY )
	
	for ( gi_rcslotnum = 0; gi_rcslotnum < 42; gi_rcslotnum++ )
	{
		formatex ( gs_cvar, 29, "restrictcommand_%s", gs_rcarray[gi_rcslotnum] )
		gp_pcvar[gi_rcslotnum] = register_cvar ( gs_cvar, "0" )
	}
	
	for ( gi_rcslotnum = 6; gi_rcslotnum < 41; gi_rcslotnum++ )
	{
		register_clcmd ( gs_rcarray[gi_rcslotnum], "fn_hookclcmds" )
	}
	
	register_concmd ( "amx_rcplayer", "fn_cmdamx_rcplayer", ADMIN_LEVEL_H, "<name or #userid> <command>" )
	register_concmd ( "amx_unrcplayer", "fn_cmdamx_unrcplayer", ADMIN_LEVEL_H, "<name or #userid> <command>" )
	register_concmd ( "amx_rccommands", "fn_cmdamx_rccommands", ADMIN_LEVEL_H, "- Displays valid commands in the correct format" )
	register_concmd ( "amx_rcinfo", "fn_cmdamx_rcinfo", ADMIN_LEVEL_H, "<name or #userid>" )
	
	register_dictionary ( "restrictcommands.txt" )
	
	get_configsdir ( gs_directory, 32 )
	formatex ( gs_rcconfigfile, 54, "%s/%s%s", gs_directory, gs_FILENAME, gs_FILETYPE )
	if ( file_exists ( gs_rcconfigfile ) ) server_cmd ( "exec %s", gs_rcconfigfile )
	
	g_rcflagvault = nvault_open ( gs_VAULTNAME )
	
	fn_servermessage ()
}

// Add these menus to the amxmodmenu
public plugin_cfg()
{
	set_task(0.9, "addToMenuFront");
}
public addToMenuFront()
{
	new PluginFileName[64];
	
	get_plugin(-1, PluginFileName, charsmax(PluginFileName));
	new cvarflags;
	new cmd[32];

	if (strcmp(cmd, "amx_rcmenu") != 0)
	{
		// this should never happen, but just incase!
		cvarflags = ADMIN_CVAR;
	}

	AddMenuItem("Restrict Commands", "amx_rcmenu", cvarflags, PluginFileName);
}

public fn_servermessage ()
{
	server_print ( "%L", LANG_SERVER, "RC_LANG_INFO_STARTUP", gs_PLUGIN, gs_VERSION, gs_AUTHOR )
	server_print ( "%L", LANG_SERVER, "RC_LANG_SERVER_MSG1" )
	if ( file_exists ( gs_rcconfigfile ) ) server_print ( "%L", LANG_SERVER, "RC_LANG_SERVER_MSG2" )
		
	return PLUGIN_HANDLED
}

public client_putinserver ( id )
{
	set_task ( 30.0, "fn_putinserverdelay", id )
}

public fn_putinserverdelay ( id )
{
	if ( ! ( get_user_flags ( id ) & ADMIN_IMMUNITY ) )
	{
		get_user_authid ( id, gs_targetauthid, 31 )
	
		for ( gi_rcslotnum = 0; gi_rcslotnum < 41; gi_rcslotnum++ )
		{
			formatex ( gs_keyname, 59, "%s%s", gs_targetauthid, gs_rcarray[gi_rcslotnum] )
			gi_vkey_value = nvault_get ( g_rcflagvault, gs_keyname )
			if ( gi_vkey_value == 1 ) gb_CommandFlag[gi_rcslotnum][id] = true
			else gb_CommandFlag[gi_rcslotnum][id] = false
		}
	}
	
	else
	{
		for ( gi_rcslotnum = 0; gi_rcslotnum < 41; gi_rcslotnum++ )
		{
			gb_CommandFlag[gi_rcslotnum][id] = false
		}
	}
}

public client_disconnect ( id )
{
	for ( gi_rcslotnum = 0; gi_rcslotnum < 41; gi_rcslotnum++ )
	{
		gb_CommandFlag[gi_rcslotnum][id] = false
	}
}

public client_PreThink ( id )
{
	if ( ! fn_player_is_immuned ( id ) )
	{
		if ( get_pcvar_num ( gp_pcvar[0] ) && get_user_button ( id ) & IN_ATTACK || gb_CommandFlag[0][id] == true && get_user_button ( id ) & IN_ATTACK )
		{
			entity_set_int ( id, EV_INT_button, get_user_button ( id ) & ~IN_ATTACK )
			fn_printmessage ( id )
		}
		
		if ( get_pcvar_num ( gp_pcvar[1] ) && get_user_button ( id ) & IN_ATTACK2 || gb_CommandFlag[1][id] == true && get_user_button ( id ) & IN_ATTACK2 )
		{
			entity_set_int ( id, EV_INT_button, get_user_button ( id ) & ~IN_ATTACK2 )
			fn_printmessage ( id )
		}
		
		if ( get_pcvar_num ( gp_pcvar[2] ) && get_user_button ( id ) & IN_RELOAD || gb_CommandFlag[2][id] == true && get_user_button ( id ) & IN_RELOAD )
		{
			entity_set_int ( id, EV_INT_button, get_user_button ( id ) & ~IN_RELOAD )
			fn_printmessage ( id )
		}
		
		if ( get_pcvar_num ( gp_pcvar[3] ) && get_user_button ( id ) & IN_USE || gb_CommandFlag[3][id] == true && get_user_button ( id ) & IN_USE )
		{
			entity_set_int ( id, EV_INT_button, get_user_button ( id ) & ~IN_USE )
			fn_printmessage ( id )
		}
	}
	
	return PLUGIN_CONTINUE
}

public client_impulse ( id, impulse )
{
	if ( ! fn_player_is_immuned ( id ) && fn_find_pcvar_flag_impulse ( id, impulse ) )
	{
		entity_set_int ( id, EV_INT_impulse, 0 )
		fn_printmessage ( id )
		return PLUGIN_HANDLED
	}
	
	return PLUGIN_CONTINUE
}
			
public fn_hookclcmds ( id )
{
	read_argv ( 0, gs_clcmdarg0, 14 )
	
	if ( ! fn_player_is_immuned ( id ) && fn_find_and_get_pcvar ( gs_clcmdarg0 ) || ! fn_player_is_immuned ( id ) && fn_find_clcmdflag ( id, gs_clcmdarg0 ) )
	{
		fn_printmessage ( id )
		return PLUGIN_HANDLED
	}
	
	return PLUGIN_CONTINUE
}

public fn_printmessage ( id )
{
	client_print ( id, print_center, "%L", id, "RC_LANG_BLOCKED_MESSAGE" )
	return PLUGIN_HANDLED
}

public fn_cmdamx_rcplayer ( id, level, cid )
{
	if ( ! cmd_access ( id, level, cid, 3 ) ) return PLUGIN_HANDLED
	
	read_argv ( 1, gs_rcplayerarg1, 32 )
	read_argv ( 2, gs_rcplayerarg2, 14 )
	remove_quotes ( gs_rcplayerarg1 )
	remove_quotes ( gs_rcplayerarg2 )
		
	gi_targetID = cmd_target ( id, gs_rcplayerarg1, 3 )
	if ( ! gi_targetID ) return PLUGIN_HANDLED
	
	if ( ! fn_is_valid_command ( gs_rcplayerarg2 ) )
	{
		console_print ( id, "[AMXX] %L", id, "RC_LANG_INVALID_COMMAND1", gs_rcplayerarg2 )
		console_print ( id, "[AMXX] %L", id, "RC_LANG_INVALID_COMMAND2" )
		return PLUGIN_HANDLED
	}
	
	get_user_name ( gi_targetID, gs_targetname, 31 )
	
	if ( fn_is_already_restricted ( gi_targetID, gs_rcplayerarg2 ) )
	{
		console_print ( id, "[AMXX] %L", id, "RC_LANG_ALREADY_RESTRICTED", gs_targetname, gs_rcplayerarg2 )
		return PLUGIN_HANDLED
	}
	
	get_user_authid ( gi_targetID, gs_targetauthid, 31 )
		
	fn_set_command_flag ( gi_targetID, gs_rcplayerarg2, gs_targetauthid )
	
	get_user_name ( id, gs_adminname, 31 )
	get_user_authid ( id, gs_adminauthid, 31 )
		
	log_amx ( "%L", LANG_SERVER, "RC_LANG_LOG_CMDRCPLAYER", gs_adminname, get_user_userid ( id ), gs_adminauthid, gs_targetname, get_user_userid ( gi_targetID ), gs_targetauthid, gs_rcplayerarg2 )
	
	switch ( get_cvar_num ( "amx_show_activity" ) )
	{
		case 2: client_print ( 0, print_chat, "%L", LANG_PLAYER, "RC_LANG_ADMIN_RCPLAYER_2", gs_adminname, gs_targetname, gs_rcplayerarg2 )
		case 1: client_print ( 0, print_chat, "%L", LANG_PLAYER, "RC_LANG_ADMIN_RCPLAYER_1", gs_targetname, gs_rcplayerarg2 )
	}
	
	console_print ( id, "[AMXX] %L", id, "RC_LANG_CLIENT_RCPLAYER", gs_targetname, gs_rcplayerarg2 )
	
	return PLUGIN_HANDLED
}

public fn_cmdamx_unrcplayer ( id, level, cid )
{
	if ( ! cmd_access ( id, level, cid, 3 ) ) return PLUGIN_HANDLED
	
	read_argv ( 1, gs_rcplayerarg1, 32 )
	read_argv ( 2, gs_rcplayerarg2, 14 )
	remove_quotes ( gs_rcplayerarg1 )
	remove_quotes ( gs_rcplayerarg2 )
		
	gi_targetID = cmd_target ( id, gs_rcplayerarg1, 3 )
	if ( ! gi_targetID ) return PLUGIN_HANDLED
	
	if ( ! fn_is_valid_command ( gs_rcplayerarg2 ) )
	{
		console_print ( id, "[AMXX] %L", id, "RC_LANG_INVALID_COMMAND1", gs_rcplayerarg2 )
		console_print ( id, "[AMXX] %L", id, "RC_LANG_INVALID_COMMAND2" )
		return PLUGIN_HANDLED
	}
	
	get_user_name ( gi_targetID, gs_targetname, 31 )
	
	if ( ! fn_is_already_restricted ( gi_targetID, gs_rcplayerarg2 ) )
	{
		console_print ( id, "[AMXX] %L", id, "RC_LANG_NOT_RESTRICTED", gs_targetname, gs_rcplayerarg2 )
		return PLUGIN_HANDLED
	}
	
	get_user_authid ( gi_targetID, gs_targetauthid, 31 )
		
	fn_remove_command_flag ( gi_targetID, gs_rcplayerarg2, gs_targetauthid )
	
	get_user_name ( id, gs_adminname, 31 )
	get_user_authid ( id, gs_adminauthid, 31 )
		
	log_amx ( "%L", LANG_SERVER, "RC_LANG_LOG_UNCMDRCPLAYER", gs_adminname, get_user_userid ( id ), gs_adminauthid, gs_targetname, get_user_userid ( gi_targetID ), gs_targetauthid, gs_rcplayerarg2 )
	
	switch ( get_cvar_num ( "amx_show_activity" ) )
	{
		case 2: client_print ( 0, print_chat, "%L", LANG_PLAYER, "RC_LANG_ADMIN_UNRCPLAYER_2", gs_adminname, gs_targetname, gs_rcplayerarg2 )
		case 1: client_print ( 0, print_chat, "%L", LANG_PLAYER, "RC_LANG_ADMIN_UNRCPLAYER_1", gs_targetname, gs_rcplayerarg2 )
	}
	
	console_print ( id, "[AMXX] %L", id, "RC_LANG_CLIENT_UNRCPLAYER", gs_targetname, gs_rcplayerarg2 )
	
	return PLUGIN_HANDLED
}

public fn_set_command_flag ( id, const s_COMMAND[], const s_AUTHID[] )
{
	for ( gi_rcslotnum = 0; gi_rcslotnum < 41; gi_rcslotnum++ )
	{
		if ( equali ( s_COMMAND, gs_rcarray[gi_rcslotnum] ) )
		{
			formatex ( gs_keyname, 59, "%s%s", s_AUTHID, s_COMMAND )
			nvault_pset ( g_rcflagvault, gs_keyname, "1" )
			gb_CommandFlag[gi_rcslotnum][id] = true
		}
	}
}

public fn_remove_command_flag ( id, const s_COMMAND[], const s_AUTHID[] )
{
	for ( gi_rcslotnum = 0; gi_rcslotnum < 41; gi_rcslotnum++ )
	{
		if ( equali ( s_COMMAND, gs_rcarray[gi_rcslotnum] ) )
		{
			formatex ( gs_keyname, 59, "%s%s", s_AUTHID, s_COMMAND )
			nvault_pset ( g_rcflagvault, gs_keyname, "0" )
			nvault_remove ( g_rcflagvault, gs_keyname )
			gb_CommandFlag[gi_rcslotnum][id] = false
		}
	}
}

public fn_cmdamx_rccommands ( id, level, cid )
{
	if ( ! cmd_access ( id, level, cid, 1 ) ) return PLUGIN_HANDLED
	
	console_print ( id, "%L", id, "RC_LANG_BEGIN_LIST" )
	console_print ( id, "%L", id, "RC_LANG_VALID_COMMANDS" )
	for ( gi_rcslotnum = 0; gi_rcslotnum < 41; gi_rcslotnum++ )
	{
		console_print ( id, "%i. %s", gi_rcslotnum+1, gs_rcarray[gi_rcslotnum] )
	}
	console_print ( id, "%L", id, "RC_LANG_END_OF_LIST" )
	
	return PLUGIN_HANDLED
}

public fn_cmdamx_rcinfo ( id, level, cid )
{
	if ( ! cmd_access ( id, level, cid, 2 ) ) return PLUGIN_HANDLED
	
	read_argv ( 1, gs_rcinfoarg1, 32 )
	remove_quotes ( gs_rcinfoarg1 )
	
	gi_targetID = cmd_target ( id, gs_rcinfoarg1, 2 )
	if ( ! gi_targetID ) return PLUGIN_HANDLED
	
	get_user_name ( gi_targetID, gs_targetname, 31 )
	
	if ( ! fn_is_player_restricted ( gi_targetID ) )
	{
		console_print ( id, "[AMXX] %L", id, "RC_LANG_NO_RESTRICTIONS", gs_targetname )
		return PLUGIN_HANDLED
	}
	
	console_print ( id, "%L", id, "RC_LANG_BEGIN_LIST" )
	console_print ( id, "%L", id, "RC_LANG_INFO", gs_targetname )
	gi_linenum = 0
	for ( gi_rcslotnum = 0; gi_rcslotnum < 41; gi_rcslotnum++ )
	{
		if ( gb_CommandFlag[gi_rcslotnum][gi_targetID] == true ) console_print ( id, "%i. %s", ++gi_linenum, gs_rcarray[gi_rcslotnum] )
	}
	console_print ( id, "%L", id, "RC_LANG_END_OF_LIST" )
	
	return PLUGIN_HANDLED
}

stock fn_player_is_immuned ( id )
{
	if ( get_pcvar_num ( gp_pcvar[41] ) && get_user_flags ( id ) & ADMIN_IMMUNITY ) return 1
	
	return 0
}

stock fn_find_pcvar_flag_impulse ( id, impulse )
{
	if ( get_pcvar_num ( gp_pcvar[4] ) && impulse == 100 || gb_CommandFlag[4][id] == true && impulse == 100 ) return 1
	if ( get_pcvar_num ( gp_pcvar[5] ) && impulse == 201 || gb_CommandFlag[5][id] == true && impulse == 201 ) return 1
	
	return 0
}

stock fn_find_and_get_pcvar ( const s_CLCMD[] )
{
	for ( gi_rcslotnum = 6; gi_rcslotnum < 41; gi_rcslotnum++ )
	{
		if ( equali ( s_CLCMD, gs_rcarray[gi_rcslotnum] ) ) return get_pcvar_num ( gp_pcvar[gi_rcslotnum] )
	}
		
	return 0
}

stock fn_find_clcmdflag ( id, const s_CLCMD[] )
{
	for ( gi_rcslotnum = 6; gi_rcslotnum < 41; gi_rcslotnum++ )
	{
		if ( equali ( s_CLCMD, gs_rcarray[gi_rcslotnum] ) && gb_CommandFlag[gi_rcslotnum][id] == true ) return 1
	}
		
	return 0
}

stock fn_is_valid_command ( const s_COMMAND[] )
{
	for ( gi_rcslotnum = 0; gi_rcslotnum < 41; gi_rcslotnum++ )
	{
		if ( equali ( s_COMMAND, gs_rcarray[gi_rcslotnum] ) ) return 1
	}
	
	return 0
}

stock fn_is_already_restricted ( id, const s_COMMAND[] )
{
	for ( gi_rcslotnum = 0; gi_rcslotnum < 41; gi_rcslotnum++ )
	{
		if ( equali ( s_COMMAND, gs_rcarray[gi_rcslotnum] ) && gb_CommandFlag[gi_rcslotnum][id] == true ) return 1
	}
		
	return 0
}

stock fn_is_player_restricted ( id )
{
	for ( gi_rcslotnum = 0; gi_rcslotnum < 41; gi_rcslotnum++ )
	{
		if ( gb_CommandFlag[gi_rcslotnum][id] == true ) return 1
	}
	
	return 0
}
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1033\\ f0\\ fs16 \n\\ par }
*/
