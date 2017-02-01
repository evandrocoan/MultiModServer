/*
	Copyright © 2009, aNNakin
		Suport & help : http://forums.alliedmods.net/showthread.php?t=103669
	
	ResetScore is free software;
	you can redistribute it and/or modify it under the terms of the
	GNU General Public License as published by the Free Software Foundation.

	This program is distributed in the hope that it will be useful,
	but WITHOUT ANY WARRANTY; without even the implied warranty of
	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
	GNU General Public License for more details.

	You should have received a copy of the GNU General Public License
	along with ResetScore; if not, write to the
	Free Software Foundation, Inc., 59 Temple Place - Suite 330,
	Boston, MA 02111-1307, USA.
*/

#include < amxmodx >
#include < amxmisc >
#include < cstrike >
#include < fun >

#define PLUGIN "ResetScore"
#define VERSION "0.2.0"
#define AUTHOR "aNNakin"

new const gs_Commands[ ][ ] =
{
	"say /resetscore",
	"say resetscore",
	"say /restartscore",
	"say restartscore",
	"say /rr",
	"say .rr"
};

new ToggleMax, ToggleInterval, ToggleMoney, g_Pointer;
new gi_Reset[ 33 ], gi_CanReset[ 33 ];

public plugin_init ( )
{
	register_plugin ( PLUGIN, VERSION, AUTHOR );
	register_dictionary ( "resetscore.txt" );
	
	register_concmd ( "amx_resetscore", "resetscore_concmd", ADMIN_KICK, "- <target>" );
	
	for ( new i_Index; i_Index < sizeof gs_Commands; i_Index++ )
		register_clcmd ( gs_Commands[ i_Index ], "resetscore_clcmd" );
	
	// how many times players can reset their score
	ToggleMax = register_cvar ( "resetscore_max", "5" );
	
	// how many minutes must pass before players can reset theirs score again
	ToggleInterval = register_cvar ( "resetscore_interval", "3" );
	
	// -2 don't set, -1 set at mp_startmoney value, another number will set to that value (e.g 0)
	ToggleMoney = register_cvar ( "resetscore_money", "-1" );
	
	g_Pointer = get_cvar_pointer ( "mp_startmoney" );
	
}

public client_putinserver ( e_Index ) gi_Reset[ e_Index ] = get_pcvar_num ( ToggleMax );

public resetscore_clcmd ( e_Index )
{
	new i_TimeCvar, i_Free, i_GameTime, Float:f_GameTime;
			
	if ( ScoreReseted ( e_Index ) )
	{
		client_print ( e_Index, print_chat, "%L", e_Index, "RESETSCORE_PLAYER_ALREADY_RESETED" );
		return PLUGIN_HANDLED;
	}
	
	f_GameTime = get_gametime ( );
	i_GameTime = floatround ( f_GameTime );
	i_TimeCvar = get_pcvar_num ( ToggleInterval );
	
	if ( ! get_pcvar_num ( ToggleMax ) )
	{
		i_Free = 1;
		goto CheckLimit;
		FreeReset:
		client_print ( e_Index, print_chat, "%L", e_Index, "RESETSCORE_PLAYER_SUCCES_FREE_RESET" );
		ResetScore ( e_Index );
		gi_CanReset[ e_Index ] = i_GameTime;
	}
	else
	{
		if ( gi_Reset[ e_Index ] > 0 )
		{
			CheckLimit:
			if ( gi_CanReset[ e_Index ] && ( i_GameTime - gi_CanReset[ e_Index ] < ( i_TimeCvar * 60 ) ) )
			{
				client_print ( e_Index, print_chat, "%L", e_Index, "RESETSCORE_PLAYER_WAIT_BEFORE_RESET", i_TimeCvar );
				return PLUGIN_HANDLED;
			}
			else	
				if ( i_Free )
					goto FreeReset;
				
			gi_Reset[ e_Index ]--;
			gi_CanReset[ e_Index ] = i_GameTime;
			ResetScore ( e_Index );
					
			if ( gi_Reset[ e_Index ] > 0 )
			{
				if ( gi_Reset[ e_Index ] == 1 )
					client_print ( e_Index, print_chat, "%L", e_Index, "RESETSCORE_PLAYER_SUCCESS_ONE_REMAIN" );
				else	
					client_print ( e_Index, print_chat, "%L", e_Index, "RESETSCORE_PLAYER_SUCCESS_MORE_RAMAIN", gi_Reset[ e_Index ] );
			}
			else
				client_print ( e_Index, print_chat, "%L", e_Index, "RESETSCORE_PLAYER_SUCCESS_NOT_REMAIN" );
			
			return PLUGIN_CONTINUE;
		}
		else
		{
			client_print ( e_Index, print_chat, "%L", e_Index, "RESETSCORE_PLAYER_CANT_USE_NOT_REMAIN" );
			return PLUGIN_HANDLED;
		}
	}
	
	return PLUGIN_CONTINUE;
}

public resetscore_concmd ( id, level, cid )
{
	if ( ! cmd_access ( id, level, cid, 2 ) )
		return PLUGIN_HANDLED;
		
	new s_Arg[ 32 ];
	read_argv ( 1, s_Arg, 31 );
	
	new e_Target = cmd_target ( id, s_Arg, 3 );
	if ( ! e_Target )
		return PLUGIN_HANDLED;
		
	if ( ScoreReseted ( e_Target ) )
	{
		console_print ( id, "%L", id, "RESETSCORE_ADMIN_ALREADY_RESETED" );
		return PLUGIN_HANDLED;
	}
	
	ResetScore ( e_Target );
	
	client_print ( e_Target, print_chat, "%L", e_Target, "RESETSCORE_PLAYER_ADMIN_HAS_RESETSCORE" );
	console_print ( id, "%L", id, "RESETSCORE_ADMIN_SUCCESS_RESETED" );
	return PLUGIN_HANDLED;
}
	
ResetScore ( e_Index )
{
	set_user_frags ( e_Index, 0 );
	cs_set_user_deaths ( e_Index, 0 );
	set_user_frags ( e_Index, 0 );
	cs_set_user_deaths ( e_Index, 0 );
	
	new i_MoneyCvar = get_pcvar_num ( ToggleMoney );
	new i_Value;
	
	// make sure he won't get more money
	if ( i_MoneyCvar >= 0 && cs_get_user_money ( e_Index ) <= i_MoneyCvar )
		return 1;
		
	switch ( i_MoneyCvar )
	{
		case -2: return 1;
		case -1: i_Value = get_pcvar_num ( g_Pointer );
		default: i_Value = i_MoneyCvar;
	}
	
	cs_set_user_money ( e_Index, i_Value );
	return 1;
}

ScoreReseted ( e_Index )
	return  ( !get_user_frags ( e_Index ) && !get_user_deaths ( e_Index ) ) ? 1 : 0;
