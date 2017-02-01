/*  AMXModX Script
*
*   Title:    Restrict Commands Config (restrictcommandscfg)
*   Author:   SubStream
*
*   Current Version:   2.1
*   Release Date:      2006-07-24
*
*   For support on this plugin, please visit the following URL:
*   Restrict Commands URL = http://forums.alliedmods.net/showthread.php?t=27089
*
*   Restrict Commands Config - Configures the Restrict Commands plugin via an in-game menu
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


new const gs_PLUGIN[]	= "Restrict Commands Config"
new const gs_VERSION[]	= "2.1"
new const gs_AUTHOR[]	= "SubStream"


new const gs_FILENAME[]	= "restrictcommands"
new const gs_FILETYPE[]	= ".cfg"


new gi_menupage[33]
new g_keys
new gi_casenum
new gs_menucase[10][64]
new gs_rcmenu[512]


new gs_directory[33]
new gs_cfgfile[128]
new gs_motdurl[128]


new gs_rc_immunity[64]
new gs_rc_attack[64]
new gs_rc_attack2[64]
new gs_rc_reload[64]
new gs_rc_use[64]
new gs_rc_buyequip[64]
new gs_rc_chooseteam[64]
new gs_rc_cl_autobuy[64]
new gs_rc_cl_setautobuy[64]
new gs_rc_coverme[64]
new gs_rc_drop[64]
new gs_rc_enemydown[64]
new gs_rc_enemyspot[64]
new gs_rc_fallback[64]
new gs_rc_followme[64]
new gs_rc_getinpos[64]
new gs_rc_getout[64]
new gs_rc_go[64]
new gs_rc_holdpos[64]
new gs_rc_impulse100[64]
new gs_rc_impulse201[64]
new gs_rc_inposition[64]
new gs_rc_lastinv[64]
new gs_rc_needbackup[64]
new gs_rc_negative[64]
new gs_rc_nightvision[64]
new gs_rc_radio1[64]
new gs_rc_radio2[64]
new gs_rc_radio3[64]
new gs_rc_regroup[64]
new gs_rc_report[64]
new gs_rc_reportingin[64]
new gs_rc_roger[64]
new gs_rc_say[64]
new gs_rc_say_team[64]
new gs_rc_sectorclear[64]
new gs_rc_sticktog[64]
new gs_rc_stormfront[64]
new gs_rc_takepoint[64]
new gs_rc_takingfire[64]
new gs_rc_weapon_knife[64]
new gs_rc_weapon_c4[64]


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
	register_cvar ( "restrictcommandscfg_version", gs_VERSION, FCVAR_SERVER|FCVAR_SPONLY )
	
	for ( gi_rcslotnum = 0; gi_rcslotnum < 42; gi_rcslotnum++ )
	{
		formatex ( gs_cvar, 29, "restrictcommand_%s", gs_rcarray[gi_rcslotnum] )
		gp_pcvar[gi_rcslotnum] = get_cvar_pointer ( gs_cvar )
	}
		
	register_clcmd ( "amx_rcmenu", "fn_checkaccess", ADMIN_CFG, "- [Restrict Commands]: Configuration Menu" )
	register_clcmd ( "say /rcmenu", "fn_checkaccess", ADMIN_CFG, "- [Restrict Commands]: Configuration Menu" )
	register_clcmd ( "say /rchelp", "fn_showrchelp", ADMIN_CFG, "- Shows Command Description Help Page." )
	register_clcmd ( "/rchelp", "fn_showrchelp", ADMIN_CFG, "- Shows Command Description Help Page." )
	register_dictionary ( "restrictcommandscfg.txt" )
	register_menucmd ( register_menuid ( "[Restrict Commands]" ), 1023, "fn_menuselection" )
}

public fn_checkaccess ( id, level, cid )
{
	if ( ! ( cmd_access ( id, level, cid, 1 ) ) ) return PLUGIN_HANDLED
	
	else
	{
		gi_menupage[id] = 1
		fn_showrcmenu ( id )
	}
	
	return PLUGIN_HANDLED
}

public fn_showrcmenu ( id )
{
	g_keys =  (1<<0)|(1<<1)|(1<<2)|(1<<3)|(1<<4)|(1<<5)|(1<<6)|(1<<7)|(1<<8)|(1<<9)
	
	for ( gi_casenum = 0; gi_casenum < 10; ++gi_casenum )
	{
		gs_menucase[gi_casenum][0] = 0
	}
	
	switch ( gi_menupage[id] )
	{
		case 1:
		{
			formatex ( gs_menucase[0], 63, "\w1. %L\R\y%s^n", id, "RC_LANG_MENU_ADMIN_IMMUNITY", get_pcvar_num ( gp_pcvar[41] ) ? "ON" : "OFF" )
			formatex ( gs_menucase[1], 63, "\w2. %L\R\y%s^n", id, "RC_LANG_MENU_RESTRICT_ATTACK", get_pcvar_num ( gp_pcvar[0] ) ? "ON" : "OFF" )
			formatex ( gs_menucase[2], 63, "\w3. %L\R\y%s^n", id, "RC_LANG_MENU_RESTRICT_ATTACK2", get_pcvar_num ( gp_pcvar[1] ) ? "ON" : "OFF" )
			formatex ( gs_menucase[3], 63, "\w4. %L\R\y%s^n", id, "RC_LANG_MENU_RESTRICT_RELOAD", get_pcvar_num ( gp_pcvar[2] ) ? "ON" : "OFF" )
			formatex ( gs_menucase[4], 63, "\w5. %L\R\y%s^n", id, "RC_LANG_MENU_RESTRICT_USE", get_pcvar_num ( gp_pcvar[3] ) ? "ON" : "OFF" )
			formatex ( gs_menucase[5], 63, "\w6. %L\R\y%s^n", id, "RC_LANG_MENU_RESTRICT_BUYEQUIP", get_pcvar_num ( gp_pcvar[6] ) ? "ON" : "OFF" )
			formatex ( gs_menucase[6], 63, "\w7. %L\R\y%s^n^n", id, "RC_LANG_MENU_RESTRICT_CHOOSETEAM", get_pcvar_num ( gp_pcvar[7] ) ? "ON" : "OFF" )
			formatex ( gs_menucase[7], 63, "\w8. %L^n^n", id, "RC_LANG_MENU_SAVE" )
			formatex ( gs_menucase[8], 63, "\w9. %L^n", id, "RC_LANG_MENU_MORE" )
			formatex ( gs_menucase[9], 63, "\w0. %L", id, "RC_LANG_MENU_EXIT" )
		}
		
		case 2:
		{
			formatex ( gs_menucase[0], 63, "\w1. %L\R\y%s^n", id, "RC_LANG_MENU_RESTRICT_CL_AUTOBUY", get_pcvar_num ( gp_pcvar[8] ) ? "ON" : "OFF" )
			formatex ( gs_menucase[1], 63, "\w2. %L\R\y%s^n", id, "RC_LANG_MENU_RESTRICT_CL_SETAUTOBUY", get_pcvar_num ( gp_pcvar[9] ) ? "ON" : "OFF" )
			formatex ( gs_menucase[2], 63, "\w3. %L\R\y%s^n", id, "RC_LANG_MENU_RESTRICT_COVERME", get_pcvar_num ( gp_pcvar[10] ) ? "ON" : "OFF" )
			formatex ( gs_menucase[3], 63, "\w4. %L\R\y%s^n", id, "RC_LANG_MENU_RESTRICT_DROP", get_pcvar_num ( gp_pcvar[11] ) ? "ON" : "OFF" )
			formatex ( gs_menucase[4], 63, "\w5. %L\R\y%s^n", id, "RC_LANG_MENU_RESTRICT_ENEMYDOWN", get_pcvar_num ( gp_pcvar[12] ) ? "ON" : "OFF" )
			formatex ( gs_menucase[5], 63, "\w6. %L\R\y%s^n", id, "RC_LANG_MENU_RESTRICT_ENEMYSPOT", get_pcvar_num ( gp_pcvar[13] ) ? "ON" : "OFF" )
			formatex ( gs_menucase[6], 63, "\w7. %L\R\y%s^n^n", id, "RC_LANG_MENU_RESTRICT_FALLBACK", get_pcvar_num ( gp_pcvar[14] ) ? "ON" : "OFF" )
			formatex ( gs_menucase[7], 63, "\w8. %L^n^n", id, "RC_LANG_MENU_SAVE" )
			formatex ( gs_menucase[8], 63, "\w9. %L^n", id, "RC_LANG_MENU_MORE" )
			formatex ( gs_menucase[9], 63, "\w0. %L", id, "RC_LANG_MENU_BACK" )
		}
		
		case 3:
		{
			formatex ( gs_menucase[0], 63, "\w1. %L\R\y%s^n", id, "RC_LANG_MENU_RESTRICT_FOLLOWME", get_pcvar_num ( gp_pcvar[15] ) ? "ON" : "OFF" )
			formatex ( gs_menucase[1], 63, "\w2. %L\R\y%s^n", id, "RC_LANG_MENU_RESTRICT_GETINPOS", get_pcvar_num ( gp_pcvar[16] ) ? "ON" : "OFF" )
			formatex ( gs_menucase[2], 63, "\w3. %L\R\y%s^n", id, "RC_LANG_MENU_RESTRICT_GETOUT", get_pcvar_num ( gp_pcvar[17] ) ? "ON" : "OFF" )
			formatex ( gs_menucase[3], 63, "\w4. %L\R\y%s^n", id, "RC_LANG_MENU_RESTRICT_GO", get_pcvar_num ( gp_pcvar[18] ) ? "ON" : "OFF" )
			formatex ( gs_menucase[4], 63, "\w5. %L\R\y%s^n", id, "RC_LANG_MENU_RESTRICT_HOLDPOS", get_pcvar_num ( gp_pcvar[19] ) ? "ON" : "OFF" )
			formatex ( gs_menucase[5], 63, "\w6. %L\R\y%s^n", id, "RC_LANG_MENU_RESTRICT_IMPULSE100", get_pcvar_num ( gp_pcvar[4] ) ? "ON" : "OFF" )
			formatex ( gs_menucase[6], 63, "\w7. %L\R\y%s^n^n", id, "RC_LANG_MENU_RESTRICT_IMPULSE201", get_pcvar_num ( gp_pcvar[5] ) ? "ON" : "OFF" )
			formatex ( gs_menucase[7], 63, "\w8. %L^n^n", id, "RC_LANG_MENU_SAVE" )
			formatex ( gs_menucase[8], 63, "\w9. %L^n", id, "RC_LANG_MENU_MORE" )
			formatex ( gs_menucase[9], 63, "\w0. %L", id, "RC_LANG_MENU_BACK" )
		}
		
		case 4:
		{
			formatex ( gs_menucase[0], 63, "\w1. %L\R\y%s^n", id, "RC_LANG_MENU_RESTRICT_INPOSITION", get_pcvar_num ( gp_pcvar[20] ) ? "ON" : "OFF" )
			formatex ( gs_menucase[1], 63, "\w2. %L\R\y%s^n", id, "RC_LANG_MENU_RESTRICT_LASTINV", get_pcvar_num ( gp_pcvar[21] ) ? "ON" : "OFF" )
			formatex ( gs_menucase[2], 63, "\w3. %L\R\y%s^n", id, "RC_LANG_MENU_RESTRICT_NEEDBACKUP", get_pcvar_num ( gp_pcvar[22] ) ? "ON" : "OFF" )
			formatex ( gs_menucase[3], 63, "\w4. %L\R\y%s^n", id, "RC_LANG_MENU_RESTRICT_NEGATIVE", get_pcvar_num ( gp_pcvar[23] ) ? "ON" : "OFF" )
			formatex ( gs_menucase[4], 63, "\w5. %L\R\y%s^n", id, "RC_LANG_MENU_RESTRICT_NIGHTVISION", get_pcvar_num ( gp_pcvar[24] ) ? "ON" : "OFF" )
			formatex ( gs_menucase[5], 63, "\w6. %L\R\y%s^n", id, "RC_LANG_MENU_RESTRICT_RADIO1", get_pcvar_num ( gp_pcvar[25] ) ? "ON" : "OFF" )
			formatex ( gs_menucase[6], 63, "\w7. %L\R\y%s^n^n", id, "RC_LANG_MENU_RESTRICT_RADIO2", get_pcvar_num ( gp_pcvar[26] ) ? "ON" : "OFF" )
			formatex ( gs_menucase[7], 63, "\w8. %L^n^n", id, "RC_LANG_MENU_SAVE" )
			formatex ( gs_menucase[8], 63, "\w9. %L^n", id, "RC_LANG_MENU_MORE" )
			formatex ( gs_menucase[9], 63, "\w0. %L", id, "RC_LANG_MENU_BACK" )
		}
		
		case 5:
		{
			formatex ( gs_menucase[0], 63, "\w1. %L\R\y%s^n", id, "RC_LANG_MENU_RESTRICT_RADIO3", get_pcvar_num ( gp_pcvar[27] ) ? "ON" : "OFF" )
			formatex ( gs_menucase[1], 63, "\w2. %L\R\y%s^n", id, "RC_LANG_MENU_RESTRICT_REGROUP", get_pcvar_num ( gp_pcvar[28] ) ? "ON" : "OFF" )
			formatex ( gs_menucase[2], 63, "\w3. %L\R\y%s^n", id, "RC_LANG_MENU_RESTRICT_REPORT", get_pcvar_num ( gp_pcvar[29] ) ? "ON" : "OFF" )
			formatex ( gs_menucase[3], 63, "\w4. %L\R\y%s^n", id, "RC_LANG_MENU_RESTRICT_REPORTINGIN", get_pcvar_num ( gp_pcvar[30] ) ? "ON" : "OFF" )
			formatex ( gs_menucase[4], 63, "\w5. %L\R\y%s^n", id, "RC_LANG_MENU_RESTRICT_ROGER", get_pcvar_num ( gp_pcvar[31] ) ? "ON" : "OFF" )
			formatex ( gs_menucase[5], 63, "\w6. %L\R\y%s^n", id, "RC_LANG_MENU_RESTRICT_SAY", get_pcvar_num ( gp_pcvar[32] ) ? "ON" : "OFF" )
			formatex ( gs_menucase[6], 63, "\w7. %L\R\y%s^n^n", id, "RC_LANG_MENU_RESTRICT_SAY_TEAM", get_pcvar_num ( gp_pcvar[33] ) ? "ON" : "OFF" )
			formatex ( gs_menucase[7], 63, "\w8. %L^n^n", id, "RC_LANG_MENU_SAVE" )
			formatex ( gs_menucase[8], 63, "\w9. %L^n", id, "RC_LANG_MENU_MORE" )
			formatex ( gs_menucase[9], 63, "\w0. %L", id, "RC_LANG_MENU_BACK" )
		}
		
		case 6:
		{
			formatex ( gs_menucase[0], 63, "\w1. %L\R\y%s^n", id, "RC_LANG_MENU_RESTRICT_SECTORCLEAR", get_pcvar_num ( gp_pcvar[34] ) ? "ON" : "OFF" )
			formatex ( gs_menucase[1], 63, "\w2. %L\R\y%s^n", id, "RC_LANG_MENU_RESTRICT_STICKTOG", get_pcvar_num ( gp_pcvar[35] ) ? "ON" : "OFF" )
			formatex ( gs_menucase[2], 63, "\w3. %L\R\y%s^n", id, "RC_LANG_MENU_RESTRICT_STORMFRONT", get_pcvar_num ( gp_pcvar[36] ) ? "ON" : "OFF" )
			formatex ( gs_menucase[3], 63, "\w4. %L\R\y%s^n", id, "RC_LANG_MENU_RESTRICT_TAKEPOINT", get_pcvar_num ( gp_pcvar[37] ) ? "ON" : "OFF" )
			formatex ( gs_menucase[4], 63, "\w5. %L\R\y%s^n", id, "RC_LANG_MENU_RESTRICT_TAKINGFIRE", get_pcvar_num ( gp_pcvar[38] ) ? "ON" : "OFF" )
			formatex ( gs_menucase[5], 63, "\w6. %L\R\y%s^n", id, "RC_LANG_MENU_RESTRICT_WEAPON_KNIFE", get_pcvar_num ( gp_pcvar[39] ) ? "ON" : "OFF" )
			formatex ( gs_menucase[6], 63, "\w7. %L\R\y%s^n^n", id, "RC_LANG_MENU_RESTRICT_WEAPON_C4", get_pcvar_num ( gp_pcvar[40] ) ? "ON" : "OFF" )
			formatex ( gs_menucase[7], 63, "\w8. %L^n^n", id, "RC_LANG_MENU_SAVE" )
			formatex ( gs_menucase[9], 63, "\w0. %L", id, "RC_LANG_MENU_BACK" )
			g_keys -= (1<<8)
		}
	}
	
	formatex ( gs_rcmenu, 511, "\y[Restrict Commands] Menu:^n^n%s%s%s%s%s%s%s%s%s%s", gs_menucase[0], gs_menucase[1], gs_menucase[2], gs_menucase[3], gs_menucase[4], gs_menucase[5], gs_menucase[6], gs_menucase[7], gs_menucase[8], gs_menucase[9] )
	
	show_menu ( id, g_keys, gs_rcmenu )
	
	return PLUGIN_HANDLED
}

public fn_menuselection ( id, key )
{
	if ( gi_menupage[id] == 1 )
	{
		switch ( key )
		{
			case 0: set_pcvar_num ( gp_pcvar[41], get_pcvar_num ( gp_pcvar[41] ) ? 0 : 1 )
			case 1: set_pcvar_num ( gp_pcvar[0], get_pcvar_num ( gp_pcvar[0] ) ? 0 : 1 )
			case 2: set_pcvar_num ( gp_pcvar[1], get_pcvar_num ( gp_pcvar[1] ) ? 0 : 1 )
			case 3: set_pcvar_num ( gp_pcvar[2], get_pcvar_num ( gp_pcvar[2] ) ? 0 : 1 )
			case 4: set_pcvar_num ( gp_pcvar[3], get_pcvar_num ( gp_pcvar[3] ) ? 0 : 1 )
			case 5: set_pcvar_num ( gp_pcvar[6], get_pcvar_num ( gp_pcvar[6] ) ? 0 : 1 )
			case 6: set_pcvar_num ( gp_pcvar[7], get_pcvar_num ( gp_pcvar[7] ) ? 0 : 1 )
			
			case 7: fn_rcsave ( id )
			
			case 8:
			{
				gi_menupage[id] = 2
				fn_showrcmenu ( id )
				return PLUGIN_HANDLED
			}
			
			case 9:
			{
				gi_menupage[id] = 0
				return PLUGIN_HANDLED
			}
		}
		fn_showrcmenu ( id )
		return PLUGIN_HANDLED
	}
	
	if ( gi_menupage[id] == 2 )
	{
		switch ( key )
		{
			case 0: set_pcvar_num ( gp_pcvar[8], get_pcvar_num ( gp_pcvar[8] ) ? 0 : 1 )
			case 1: set_pcvar_num ( gp_pcvar[9], get_pcvar_num ( gp_pcvar[9] ) ? 0 : 1 )
			case 2: set_pcvar_num ( gp_pcvar[10], get_pcvar_num ( gp_pcvar[10] ) ? 0 : 1 )
			case 3: set_pcvar_num ( gp_pcvar[11], get_pcvar_num ( gp_pcvar[11] ) ? 0 : 1 )
			case 4: set_pcvar_num ( gp_pcvar[12], get_pcvar_num ( gp_pcvar[12] ) ? 0 : 1 )
			case 5: set_pcvar_num ( gp_pcvar[13], get_pcvar_num ( gp_pcvar[13] ) ? 0 : 1 )
			case 6: set_pcvar_num ( gp_pcvar[14], get_pcvar_num ( gp_pcvar[14] ) ? 0 : 1 )
			
			case 7: fn_rcsave ( id )
			
			case 8:
			{
				gi_menupage[id] = 3
				fn_showrcmenu ( id )
				return PLUGIN_HANDLED
			}
			
			case 9:
			{
				gi_menupage[id] = 1
				fn_showrcmenu ( id )
				return PLUGIN_HANDLED
			}
		}
	}
	
	if ( gi_menupage[id] == 3 )
	{
		switch ( key )
		{
			case 0: set_pcvar_num ( gp_pcvar[15], get_pcvar_num ( gp_pcvar[15] ) ? 0 : 1 )
			case 1: set_pcvar_num ( gp_pcvar[16], get_pcvar_num ( gp_pcvar[16] ) ? 0 : 1 )
			case 2: set_pcvar_num ( gp_pcvar[17], get_pcvar_num ( gp_pcvar[17] ) ? 0 : 1 )
			case 3: set_pcvar_num ( gp_pcvar[18], get_pcvar_num ( gp_pcvar[18] ) ? 0 : 1 )
			case 4: set_pcvar_num ( gp_pcvar[19], get_pcvar_num ( gp_pcvar[19] ) ? 0 : 1 )
			case 5: set_pcvar_num ( gp_pcvar[4], get_pcvar_num ( gp_pcvar[4] ) ? 0 : 1 )
			case 6: set_pcvar_num ( gp_pcvar[5], get_pcvar_num ( gp_pcvar[5] ) ? 0 : 1 )
			
			case 7: fn_rcsave ( id )
			
			case 8:
			{
				gi_menupage[id] = 4
				fn_showrcmenu ( id )
				return PLUGIN_HANDLED
			}
			
			case 9:
			{
				gi_menupage[id] = 2
				fn_showrcmenu ( id )
				return PLUGIN_HANDLED
			}
		}
	}
	
	if ( gi_menupage[id] == 4 )
	{
		switch ( key )
		{
			case 0: set_pcvar_num ( gp_pcvar[20], get_pcvar_num ( gp_pcvar[20] ) ? 0 : 1 )
			case 1: set_pcvar_num ( gp_pcvar[21], get_pcvar_num ( gp_pcvar[21] ) ? 0 : 1 )
			case 2: set_pcvar_num ( gp_pcvar[22], get_pcvar_num ( gp_pcvar[22] ) ? 0 : 1 )
			case 3: set_pcvar_num ( gp_pcvar[23], get_pcvar_num ( gp_pcvar[23] ) ? 0 : 1 )
			case 4: set_pcvar_num ( gp_pcvar[24], get_pcvar_num ( gp_pcvar[24] ) ? 0 : 1 )
			case 5: set_pcvar_num ( gp_pcvar[25], get_pcvar_num ( gp_pcvar[25] ) ? 0 : 1 )
			case 6: set_pcvar_num ( gp_pcvar[26], get_pcvar_num ( gp_pcvar[26] ) ? 0 : 1 )
			
			case 7: fn_rcsave ( id )
			
			case 8:
			{
				gi_menupage[id] = 5
				fn_showrcmenu ( id )
				return PLUGIN_HANDLED
			}
			
			case 9:
			{
				gi_menupage[id] = 3
				fn_showrcmenu ( id )
				return PLUGIN_HANDLED
			}
		}
	}
	
	if ( gi_menupage[id] == 5 )
	{
		switch ( key )
		{
			case 0: set_pcvar_num ( gp_pcvar[27], get_pcvar_num ( gp_pcvar[27] ) ? 0 : 1 )
			case 1: set_pcvar_num ( gp_pcvar[28], get_pcvar_num ( gp_pcvar[28] ) ? 0 : 1 )
			case 2: set_pcvar_num ( gp_pcvar[29], get_pcvar_num ( gp_pcvar[29] ) ? 0 : 1 )
			case 3: set_pcvar_num ( gp_pcvar[30], get_pcvar_num ( gp_pcvar[30] ) ? 0 : 1 )
			case 4: set_pcvar_num ( gp_pcvar[31], get_pcvar_num ( gp_pcvar[31] ) ? 0 : 1 )
			case 5: set_pcvar_num ( gp_pcvar[32], get_pcvar_num ( gp_pcvar[32] ) ? 0 : 1 )
			case 6: set_pcvar_num ( gp_pcvar[33], get_pcvar_num ( gp_pcvar[33] ) ? 0 : 1 )
			
			case 7: fn_rcsave ( id )
			
			case 8:
			{
				gi_menupage[id] = 6
				fn_showrcmenu ( id )
				return PLUGIN_HANDLED
			}
			
			case 9:
			{
				gi_menupage[id] = 4
				fn_showrcmenu ( id )
				return PLUGIN_HANDLED
			}
		}
	}
	
	if ( gi_menupage[id] == 6 )
	{
		switch ( key )
		{
			case 0: set_pcvar_num ( gp_pcvar[34], get_pcvar_num ( gp_pcvar[34] ) ? 0 : 1 )
			case 1: set_pcvar_num ( gp_pcvar[35], get_pcvar_num ( gp_pcvar[35] ) ? 0 : 1 )
			case 2: set_pcvar_num ( gp_pcvar[36], get_pcvar_num ( gp_pcvar[36] ) ? 0 : 1 )
			case 3: set_pcvar_num ( gp_pcvar[37], get_pcvar_num ( gp_pcvar[37] ) ? 0 : 1 )
			case 4: set_pcvar_num ( gp_pcvar[38], get_pcvar_num ( gp_pcvar[38] ) ? 0 : 1 )
			case 5: set_pcvar_num ( gp_pcvar[39], get_pcvar_num ( gp_pcvar[39] ) ? 0 : 1 )
			case 6: set_pcvar_num ( gp_pcvar[40], get_pcvar_num ( gp_pcvar[40] ) ? 0 : 1 )
			
			case 7: fn_rcsave ( id )
			
			case 9:
			{
				gi_menupage[id] = 5
				fn_showrcmenu ( id )
				return PLUGIN_HANDLED
			}
		}
	}
	
	update_rcmenu ()
	return PLUGIN_HANDLED
}

public update_rcmenu ()
{
	new i_playerID[32], i_playercnt, menu, keys
	
	get_players ( i_playerID, i_playercnt )
	
	for ( new i_playernum = 0; i_playernum < i_playercnt; ++i_playernum )
	{
		if ( gi_menupage[i_playerID[i_playernum]] > 0 && ! get_user_menu ( i_playerID[i_playernum], menu, keys ) ) gi_menupage[i_playerID[i_playernum]] = 0
		else if ( gi_menupage[i_playerID[i_playernum]] > 0 ) fn_showrcmenu ( i_playerID[i_playernum] )
		else return PLUGIN_CONTINUE
	}
	
	return PLUGIN_CONTINUE
}

public fn_rcsave ( id )
{
	formatex ( gs_rc_immunity, 63, "restrictcommand_immunity %i", get_pcvar_num ( gp_pcvar[41] ) )
	formatex ( gs_rc_attack, 63, "restrictcommand_attack %i", get_pcvar_num ( gp_pcvar[0] ) )
	formatex ( gs_rc_attack2, 63, "restrictcommand_attack2 %i", get_pcvar_num ( gp_pcvar[1] ) )
	formatex ( gs_rc_reload, 63, "restrictcommand_reload %i", get_pcvar_num ( gp_pcvar[2] ) )
	formatex ( gs_rc_use, 63, "restrictcommand_use %i", get_pcvar_num ( gp_pcvar[3] ) )
	formatex ( gs_rc_buyequip, 63, "restrictcommand_buyequip %i", get_pcvar_num ( gp_pcvar[6] ) )
	formatex ( gs_rc_chooseteam, 63, "restrictcommand_chooseteam %i", get_pcvar_num ( gp_pcvar[7] ) )
	formatex ( gs_rc_cl_autobuy, 63, "restrictcommand_cl_autobuy %i", get_pcvar_num ( gp_pcvar[8] ) )
	formatex ( gs_rc_cl_setautobuy, 63, "restrictcommand_cl_setautobuy %i", get_pcvar_num ( gp_pcvar[9] ) )
	formatex ( gs_rc_coverme, 63, "restrictcommand_coverme %i", get_pcvar_num ( gp_pcvar[10] ) )
	formatex ( gs_rc_drop, 63, "restrictcommand_drop %i", get_pcvar_num ( gp_pcvar[11] ) )
	formatex ( gs_rc_enemydown, 63, "restrictcommand_enemydown %i", get_pcvar_num ( gp_pcvar[12] ) )
	formatex ( gs_rc_enemyspot, 63, "restrictcommand_enemyspot %i", get_pcvar_num ( gp_pcvar[13] ) )
	formatex ( gs_rc_fallback, 63, "restrictcommand_fallback %i", get_pcvar_num ( gp_pcvar[14] ) )
	formatex ( gs_rc_followme, 63, "restrictcommand_followme %i", get_pcvar_num ( gp_pcvar[15] ) )
	formatex ( gs_rc_getinpos, 63, "restrictcommand_getinpos %i", get_pcvar_num ( gp_pcvar[16] ) )
	formatex ( gs_rc_getout, 63, "restrictcommand_getout %i", get_pcvar_num ( gp_pcvar[17] ) )
	formatex ( gs_rc_go, 63, "restrictcommand_go %i", get_pcvar_num ( gp_pcvar[18] ) )
	formatex ( gs_rc_holdpos, 63, "restrictcommand_holdpos %i", get_pcvar_num ( gp_pcvar[19] ) )
	formatex ( gs_rc_impulse100, 63, "restrictcommand_impulse100 %i", get_pcvar_num ( gp_pcvar[4] ) )
	formatex ( gs_rc_impulse201, 63, "restrictcommand_impulse201 %i", get_pcvar_num ( gp_pcvar[5] ) )
	formatex ( gs_rc_inposition, 63, "restrictcommand_inposition %i", get_pcvar_num ( gp_pcvar[20] ) )
	formatex ( gs_rc_lastinv, 63, "restrictcommand_lastinv %i", get_pcvar_num ( gp_pcvar[21] ) )
	formatex ( gs_rc_needbackup, 63, "restrictcommand_needbackup %i", get_pcvar_num ( gp_pcvar[22] ) )
	formatex ( gs_rc_negative, 63, "restrictcommand_negative %i", get_pcvar_num ( gp_pcvar[23] ) )
	formatex ( gs_rc_nightvision, 63, "restrictcommand_nightvision %i", get_pcvar_num ( gp_pcvar[24] ) )
	formatex ( gs_rc_radio1, 63, "restrictcommand_radio1 %i", get_pcvar_num ( gp_pcvar[25] ) )
	formatex ( gs_rc_radio2, 63, "restrictcommand_radio2 %i", get_pcvar_num ( gp_pcvar[26] ) )
	formatex ( gs_rc_radio3, 63, "restrictcommand_radio3 %i", get_pcvar_num ( gp_pcvar[27] ) )
	formatex ( gs_rc_regroup, 63, "restrictcommand_regroup %i", get_pcvar_num ( gp_pcvar[28] ) )
	formatex ( gs_rc_report, 63, "restrictcommand_report %i", get_pcvar_num ( gp_pcvar[29] ) )
	formatex ( gs_rc_reportingin, 63, "restrictcommand_reportingin %i", get_pcvar_num ( gp_pcvar[30] ) )
	formatex ( gs_rc_roger, 63, "restrictcommand_roger %i", get_pcvar_num ( gp_pcvar[31] ) )
	formatex ( gs_rc_say, 63, "restrictcommand_say %i", get_pcvar_num ( gp_pcvar[32] ) )
	formatex ( gs_rc_say_team, 63, "restrictcommand_say_team %i", get_pcvar_num ( gp_pcvar[33] ) )
	formatex ( gs_rc_sectorclear, 63, "restrictcommand_sectorclear %i", get_pcvar_num ( gp_pcvar[34] ) )
	formatex ( gs_rc_sticktog, 63, "restrictcommand_sticktog %i", get_pcvar_num ( gp_pcvar[35] ) )
	formatex ( gs_rc_stormfront, 63, "restrictcommand_stormfront %i", get_pcvar_num ( gp_pcvar[36] ) )
	formatex ( gs_rc_takepoint, 63, "restrictcommand_takepoint %i", get_pcvar_num ( gp_pcvar[37] ) )
	formatex ( gs_rc_takingfire, 63, "restrictcommand_takingfire %i", get_pcvar_num ( gp_pcvar[38] ) )
	formatex ( gs_rc_weapon_knife, 63, "restrictcommand_weapon_knife %i", get_pcvar_num ( gp_pcvar[39] ) )
	formatex ( gs_rc_weapon_c4, 63, "restrictcommand_weapon_c4 %i", get_pcvar_num ( gp_pcvar[40] ) )
	
	get_configsdir ( gs_directory, 32 )
	formatex ( gs_cfgfile, 127, "%s/%s%s", gs_directory, gs_FILENAME, gs_FILETYPE )
	
	write_file ( gs_cfgfile, gs_rc_immunity, 7 )
	write_file ( gs_cfgfile, gs_rc_attack, 11 )
	write_file ( gs_cfgfile, gs_rc_attack2, 15 )
	write_file ( gs_cfgfile, gs_rc_reload, 19 )
	write_file ( gs_cfgfile, gs_rc_use, 23 )
	write_file ( gs_cfgfile, gs_rc_buyequip, 27 )
	write_file ( gs_cfgfile, gs_rc_chooseteam, 31 )
	write_file ( gs_cfgfile, gs_rc_cl_autobuy, 35 )
	write_file ( gs_cfgfile, gs_rc_cl_setautobuy, 39 )
	write_file ( gs_cfgfile, gs_rc_coverme, 43 )
	write_file ( gs_cfgfile, gs_rc_drop, 47 )
	write_file ( gs_cfgfile, gs_rc_enemydown, 51 )
	write_file ( gs_cfgfile, gs_rc_enemyspot, 55 )
	write_file ( gs_cfgfile, gs_rc_fallback, 59 )
	write_file ( gs_cfgfile, gs_rc_followme, 63 )
	write_file ( gs_cfgfile, gs_rc_getinpos, 67 )
	write_file ( gs_cfgfile, gs_rc_getout, 71 )
	write_file ( gs_cfgfile, gs_rc_go, 75 )
	write_file ( gs_cfgfile, gs_rc_holdpos, 79 )
	write_file ( gs_cfgfile, gs_rc_impulse100, 83 )
	write_file ( gs_cfgfile, gs_rc_impulse201, 87 )
	write_file ( gs_cfgfile, gs_rc_inposition, 91 )
	write_file ( gs_cfgfile, gs_rc_lastinv, 95 )
	write_file ( gs_cfgfile, gs_rc_needbackup, 99 )
	write_file ( gs_cfgfile, gs_rc_negative, 103 )
	write_file ( gs_cfgfile, gs_rc_nightvision, 107 )
	write_file ( gs_cfgfile, gs_rc_radio1, 111 )
	write_file ( gs_cfgfile, gs_rc_radio2, 115 )
	write_file ( gs_cfgfile, gs_rc_radio3, 119 )
	write_file ( gs_cfgfile, gs_rc_regroup, 123 )
	write_file ( gs_cfgfile, gs_rc_report, 127 )
	write_file ( gs_cfgfile, gs_rc_reportingin, 131 )
	write_file ( gs_cfgfile, gs_rc_roger, 135 )
	write_file ( gs_cfgfile, gs_rc_say, 139 )
	write_file ( gs_cfgfile, gs_rc_say_team, 143 )
	write_file ( gs_cfgfile, gs_rc_sectorclear, 147 )
	write_file ( gs_cfgfile, gs_rc_sticktog, 151 )
	write_file ( gs_cfgfile, gs_rc_stormfront, 155 )
	write_file ( gs_cfgfile, gs_rc_takepoint, 159 )
	write_file ( gs_cfgfile, gs_rc_takingfire, 163 )
	write_file ( gs_cfgfile, gs_rc_weapon_knife, 167 )
	write_file ( gs_cfgfile, gs_rc_weapon_c4, 171 )
	
	client_print ( id, print_chat, "%L", id, "RC_LANG_MENU_SAVE_MSG" )
	
	return PLUGIN_CONTINUE
}

public fn_showrchelp ( id, level, cid )
{
	if ( ! cmd_access ( id, level, cid, 1 ) ) return PLUGIN_HANDLED
	
	else
	{
		formatex ( gs_motdurl, 127, "http://www.geocities.com/neoxxander/" )
		show_motd ( id, gs_motdurl, "Command Description Help Page" )
		return PLUGIN_HANDLED
	}
	
	return PLUGIN_HANDLED
}
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1033\\ f0\\ fs16 \n\\ par }
*/
