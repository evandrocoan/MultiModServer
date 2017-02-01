
	/*
		Author 	: hornet
		Plugin 	: Timer Controller
		Version : v0.0.3
		
		<^>
		
		This plugin is free software; you can redistribute it and/or modify it
		under the terms of the GNU General Public License as published by the
		Free Software Foundation; either version 2 of the License, or (at
		your option) any later version.
		
		This plugin is distributed in the hope that it will be useful, but
		WITHOUT ANY WARRANTY; without even the implied warranty of
		MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
		General Public License for more details.
		
		You should have received a copy of the GNU General Public License
		along with this plugin; if not, write to the Free Software Foundation,
		Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA
		
		<^>
	*/

#include <amxmodx>
#include <orpheu>
#include <orpheu_memory>

#define VERSION			"0.0.4"

#define MemorySet(%0,%1)	OrpheuMemorySetAtAddress( g_pGameRules, %0, 1, %1 )
#define MemoryGet(%0)		OrpheuMemoryGetAtAddress( g_pGameRules, %0 )

#define ADMIN_TIME		ADMIN_CVAR

#define TASK_PAUSEMSG		1001

new bool:IsTimerPaused, bool:g_bBombPlanted;
new Float:g_flRoundStart, Float:g_flRoundPaused, Float:g_flTotalPauseTime;
new g_pGameRules, g_pRoundTime, g_pRoundEndTime;

new g_msgRoundTime;

new OrpheuHook:_CGameRules_Think, OrpheuFunction:__CGameRules_Think;

public plugin_precache()
{
	OrpheuRegisterHook( OrpheuGetFunction( "InstallGameRules" ), "InstallGameRules", OrpheuHookPost );
}

public OrpheuHookReturn:InstallGameRules()
{
	g_pGameRules = OrpheuGetReturn();
}

public plugin_init() 
{	
	register_plugin( "Timer Controller", VERSION, "hornet" );
	register_cvar( "timercontroller_version", VERSION, FCVAR_SERVER | FCVAR_SPONLY );
	
	register_logevent( "LogEvent_RoundStart", 2, "1=Round_Start" );
	register_logevent( "LogEvent_BombPlanted", 3, "2=Planted_The_Bomb" );
	
	register_concmd( "roundtimer_pause", "ConsoleCommand_TimerPause" );
	register_concmd( "roundtimer_set", "ConsoleCommand_TimerSet" );
	
	OrpheuRegisterHook( OrpheuGetFunctionFromObject( g_pGameRules, "CheckWinConditions", "CGameRules" ), "CGameRules_CheckWinConditions" );
	__CGameRules_Think = OrpheuGetFunctionFromObject( g_pGameRules, "Think", "CGameRules" );
	
	g_pRoundTime 	= 	get_cvar_pointer( "mp_roundtime" );
	g_pRoundEndTime =	register_cvar( "tc_roundend_time", "5" );
	
	g_msgRoundTime = get_user_msgid( "RoundTime" );
}

public plugin_natives()
{
	register_native( "RoundTimerPause", "_RoundTimerPause" );
	register_native( "IsRoundTimerPaused", "_IsRoundTimerPaused" );
	register_native( "RoundTimerSet", "_RoundTimerSet" );
	register_native( "RoundTimerGet", "_RoundTimerGet" );
}

public LogEvent_RoundStart()
{
	g_bBombPlanted = false;
	
	g_flRoundStart = get_gametime();
	g_flTotalPauseTime = 0.0;
	g_flRoundPaused = 0.0;
}

public LogEvent_BombPlanted()
{
	g_bBombPlanted = true;
	
	if( IsTimerPaused )
	{
		IsTimerPaused = false;
		
		remove_task( TASK_PAUSEMSG );
	}
}

public ConsoleCommand_TimerPause( id )
{
	if( id && !( get_user_flags( id ) & ADMIN_TIME ) )
	{
		console_print( id, "You have no access that command." );
		return;
	}
	
	if( !MemoryGet( "m_bRoundTerminating" ) && !MemoryGet( "m_iRoundWinStatus" ) && !g_bBombPlanted )
	{
		if( !IsTimerPaused )
		{
			_CGameRules_Think = OrpheuRegisterHook( __CGameRules_Think, "CGameRules_Think" );
			
			set_task( 0.25, "Task_PauseMsg", TASK_PAUSEMSG, _, _, "b" );
			
			g_flRoundPaused += ( ( g_flRoundPaused ? 0.0 : get_pcvar_float( g_pRoundTime ) ) * 60 ) - ( get_gametime() - g_flRoundStart ) + g_flTotalPauseTime;
			
			IsTimerPaused = true;
		}
		else
		{
			OrpheuUnregisterHook( _CGameRules_Think );
			_CGameRules_Think = OrpheuHook:0;
			
			remove_task( TASK_PAUSEMSG );
			
			MemorySet( "m_iRoundTimeSecs", floatround( g_flRoundPaused ) );
			MemorySet( "m_fRoundCount", get_gametime() );
			
			UTIL_RoundTime( floatround( g_flRoundPaused ) );
			
			IsTimerPaused = false;
		}
	}
}

public ConsoleCommand_TimerSet( id, iTime )
{
	if( id && !( get_user_flags( id ) & ADMIN_TIME ) )
	{
		console_print( id, "You have no access that command." );
		return;
	}
	
	if( !MemoryGet( "m_bRoundTerminating" ) && !MemoryGet( "m_iRoundWinStatus" ) && !g_bBombPlanted )
	{
		if( !iTime )
		{
			new szMinutes[ 3 ], szSeconds[ 3 ];
			read_argv( 1, szMinutes, charsmax( szMinutes ) );
			read_argv( 2, szSeconds, charsmax( szSeconds ) );
			
			iTime = ( str_to_num( szMinutes ) * 60 ) + ( str_to_num( szSeconds ) );
			
			if( !iTime )
			{
				console_print( id, "Usage: <minutes> <seconds>" );
				return;
			}
		}
		
		g_flRoundStart = get_gametime();
		g_flRoundPaused = float( iTime );
		g_flTotalPauseTime = 0.0;
		
		MemorySet( "m_iRoundTimeSecs", iTime );
		MemorySet( "m_fRoundCount", get_gametime() );
		
		UTIL_RoundTime( iTime );
	}
}

public Task_PauseMsg()
{
	g_flTotalPauseTime += 0.25;
	
	set_hudmessage( 0, 255, 0, -1.0, 0.9, 0, 0.0, 0.25, 0.5, 0.5 );
	show_hudmessage( 0, "-ROUND TIMER PAUSED-" );
	
	UTIL_RoundTime( floatround( g_flRoundPaused ) );
}

public OrpheuHookReturn:CGameRules_CheckWinConditions()
{
	new iStatus = MemoryGet( "m_iRoundWinStatus" );
	
	if( iStatus && iStatus != 3  )
	{
		MemorySet( "m_fTeamCount", get_gametime() + get_pcvar_float( g_pRoundEndTime ) );
		MemorySet( "m_bRoundTerminating", true ); 
	}
}

public OrpheuHookReturn:CGameRules_Think()
{
	return OrpheuSupercede;
}

UTIL_RoundTime( iTime )
{
	message_begin( MSG_BROADCAST, g_msgRoundTime );
	write_short( iTime );	
	message_end();
}

	/* 
		Available natives for devs
	*/

public _RoundTimerPause()
{
	ConsoleCommand_TimerPause( 0 );
}

public _IsRoundTimerPaused()
{
	return IsTimerPaused;
}

public _RoundTimerSet()
{
	ConsoleCommand_TimerSet( 0, ( get_param( 1 ) * 60 ) + get_param( 2 ) );
}

public _RoundTimerGet()
{
	return MemoryGet("m_iRoundTimeSecs");
}