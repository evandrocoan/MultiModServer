/***
 * Link to the plugin
 *
 *	http://forums.alliedmods.net/showthread.php?t=78197
 */

#include < amxmodx >
#include < engine >
#include < cstrike >
#include < fun >
#include < fakemeta >
#include < hamsandwich >

#pragma semicolon 1

// Comment this line if you do not want to have fake player !
#define FAKE_PLAYER

// Bot name
#if defined FAKE_PLAYER
	new const g_szBotName[ ] = "DRM Fake Player";
#endif

// Messages prefix
new const g_szPrefix[ ] = "[ Deathrun ]";

// Global Variables
new bool:g_bHauntedHouse, bool:g_bGamerFun, bool:g_bRandromized, bool:g_bStarting, bool:g_bFirstRound;
new bool:g_bEnabled, bool:g_bRestart, bool:g_bConnected[ 33 ];

new g_pRemoveBuyZone, g_pHideHuds, g_pBlockMoney, g_pLifeSystem, g_pSvRestart, g_pAutoBalance, g_pLimitTeams;
new g_pNoFallDmg, g_pGameName, g_pToggle, g_pBlockSpray, g_pBlockRadio, g_pSemiclip, g_pGiveUsp, g_pBlockKill;

new g_iMsgHideWeapon, g_iMsgCrosshair, g_iMsgMoney, g_iMsgTeamInfo, g_iMsgSayText;
new g_iMaxplayers, g_iHudSync, g_iHudSync2, g_iLastTerr, g_iThinker;
new g_iSemiClip[ 33 ], g_Lifes[ 33 ];

#if defined FAKE_PLAYER
	new g_iFakeplayer;
#endif

// Macros
#if cellbits == 32
	#define OFFSET_BZ 235
#else
	#define OFFSET_BZ 268
#endif

// Colorchat
enum Color {
	NORMAL = 1,
	GREEN,
	RED,
	BLUE
};

new TeamName[ ][ ] = {
	"",
	"TERRORIST",
	"CT",
	"SPECTATOR"
};

// =======================================================================================

public plugin_init( ) {
	new const VERSION[ ] = "3.0.3";
	
	register_plugin( "Deathrun Manager", VERSION, "xPaw" );
	
	g_pToggle        = register_cvar( "deathrun_toggle",     "1" );
	g_pBlockSpray    = register_cvar( "deathrun_spray",      "1" );
	g_pBlockRadio    = register_cvar( "deathrun_radio",      "1" );
	g_pBlockKill     = register_cvar( "deathrun_blockkill",  "1" );
	g_pBlockMoney    = register_cvar( "deathrun_blockmoney", "1" );
	g_pSemiclip      = register_cvar( "deathrun_semiclip",   "1" );
	g_pGiveUsp       = register_cvar( "deathrun_giveusp",    "1" );
	g_pHideHuds      = register_cvar( "deathrun_hidehud",    "1" );
	g_pLifeSystem    = register_cvar( "deathrun_lifesystem", "1" );
	g_pGameName      = register_cvar( "deathrun_gamename",   "1" );
	g_pNoFallDmg     = register_cvar( "deathrun_terrnfd",    "1" );
	g_pRemoveBuyZone = register_cvar( "deathrun_removebz",   "1" );
	
	// Lets get map name...
	new szMapName[ 64 ];
	get_mapname( szMapName, 63 );
	
	if( contain( szMapName, "deathrun_" ) != -1 ) {
		set_pcvar_num( g_pToggle, 1 );
		
		if( contain( szMapName, "hauntedhouse" ) != -1 )
			g_bHauntedHouse = true;
		else {
			g_bHauntedHouse = false;
			
			if( equal( szMapName, "deathrun_gamerfun" ) )
				g_bGamerFun = true;
			else
				g_bGamerFun = false;
		}
	} else
		set_pcvar_num( g_pToggle, 0 );
	
	g_pSvRestart   = get_cvar_pointer( "sv_restart" );
	g_pAutoBalance = get_cvar_pointer( "mp_autoteambalance" );
	g_pLimitTeams  = get_cvar_pointer( "mp_limitteams" );
	
	register_cvar( "deathrun_version", VERSION, FCVAR_SERVER | FCVAR_SPONLY );
	set_cvar_string( "deathrun_version", VERSION );
	
	// Registering Language file
	register_dictionary( "deathrun.txt" );
	
	// Logging Events
	register_logevent( "EventRoundStart", 2, "1=Round_Start" );
	register_logevent( "EventRandromize", 2, "1=Round_End" );
	register_event( "SendAudio", "EventTerrsWin",   "a", "2&%!MRAD_terwin" );
	register_event( "TextMsg",	 "EventRandromize", "a", "2&#Game_w" );
	register_event( "DeathMsg",	 "EventDeath",      "a");
	register_event( "Money",	 "EventMoney",      "b" );
	register_event( "ResetHUD",	 "EventResetHud",   "be" );
	
	g_bFirstRound    = true;
	g_iMaxplayers    = get_maxplayers( );
	g_iMsgHideWeapon = get_user_msgid( "HideWeapon" );
	g_iMsgCrosshair  = get_user_msgid( "Crosshair" );
	g_iMsgMoney      = get_user_msgid( "Money" );
	g_iMsgSayText    = get_user_msgid( "SayText" );
	g_iMsgTeamInfo   = get_user_msgid( "TeamInfo" );
	
	g_iHudSync       = CreateHudSyncObj( );
	g_iHudSync2      = CreateHudSyncObj( );
	
	if( get_pcvar_num( g_pToggle ) ) {
		RegisterHam( Ham_TakeDamage, "player", "FwdHamPlayerDamage" );
		RegisterHam( Ham_Spawn,      "player", "FwdHamPlayerSpawn", 1 );
		register_forward( FM_ClientKill,       "FwdClientKill" );
		register_impulse( 201, "FwdImpulse_201" );
		
		if( get_pcvar_num( g_pGameName ) )
			register_forward( FM_GetGameDescription, "FwdGameDesc" );
		
		register_clcmd( "say /lifes", "CmdShowlifes" );
		register_clcmd( "say /lives", "CmdShowlifes" );
		
		register_clcmd( "radio1", "CmdRadio" );
		register_clcmd( "radio2", "CmdRadio" );
		register_clcmd( "radio3", "CmdRadio" );
		
		// Terrorist Check
		g_iThinker= create_entity( "info_target" );
		
		if( is_valid_ent( g_iThinker ) ) {
			entity_set_string( g_iThinker, EV_SZ_classname, "DeathrunThinker" );
			entity_set_float( g_iThinker, EV_FL_nextthink, get_gametime( ) + 20.0 );
			
			g_bRestart = true;
			
			// First think will happen in 20.0, Restart will be done there.
			
			register_think( "DeathrunThinker", "FwdThinker" );
		} else {
			set_task( 15.0, "CheckTerrorists", _, _, _, "b" );
			
			// Lets make restart after 20 seconds from map start.
			set_task( 20.0, "RestartRound" );
		}
		
		if( get_pcvar_num( g_pRemoveBuyZone ) ) {
			register_message( get_user_msgid( "StatusIcon" ), "MsgStatusIcon" ); // BuyZone Icon
			
			// Remove buyzone on map
			remove_entity_name( "info_map_parameters" );
			remove_entity_name( "func_buyzone" );
			
			// Create own entity to block buying
			new iEntity = create_entity( "info_map_parameters" );
			
			DispatchKeyValue( iEntity, "buying", "3" );
			DispatchSpawn( iEntity );
		}
		
		if( get_pcvar_num( g_pSemiclip ) ) {
			register_forward( FM_StartFrame,	"FwdStartFrame", 0 );
			register_forward( FM_AddToFullPack,	"FwdFullPack",   1 );
		}
		
		g_bEnabled = true;
		
	#if defined FAKE_PLAYER
		new iEntity, iCount;
		
		while( ( iEntity = find_ent_by_class( iEntity, "info_player_deathmatch" ) ) > 0 )
			if( iCount++ > 1 )
				break;
		
		if( iCount <= 1 )
			g_iFakeplayer = -1;
		
		set_task( 5.0, "UpdateBot" );
		
		register_message( get_user_msgid( "DeathMsg" ), "MsgDeathMsg" );
	#endif
	} else
		g_bEnabled = false;
}

// FAKEPLAYER
///////////////////////////////////////////
#if defined FAKE_PLAYER
	public UpdateBot( ) {
		if( g_iFakeplayer == -1 )
			return;
		
		new id = find_player( "i" );
		
		if( !id ) {
			id = engfunc( EngFunc_CreateFakeClient, g_szBotName );
			if( pev_valid( id ) ) {
				engfunc( EngFunc_FreeEntPrivateData, id );
				dllfunc( MetaFunc_CallGameEntity, "player", id );
				set_user_info( id, "rate", "3500" );
				set_user_info( id, "cl_updaterate", "25" );
				set_user_info( id, "cl_lw", "1" );
				set_user_info( id, "cl_lc", "1" );
				set_user_info( id, "cl_dlmax", "128" );
				set_user_info( id, "cl_righthand", "1" );
				set_user_info( id, "_vgui_menus", "0" );
				set_user_info( id, "_ah", "0" );
				set_user_info( id, "dm", "0" );
				set_user_info( id, "tracker", "0" );
				set_user_info( id, "friends", "0" );
				set_user_info( id, "*bot", "1" );
				set_pev( id, pev_flags, pev( id, pev_flags ) | FL_FAKECLIENT );
				set_pev( id, pev_colormap, id );
				
				new szMsg[ 128 ];
				dllfunc( DLLFunc_ClientConnect, id, g_szBotName, "127.0.0.1", szMsg );
				dllfunc( DLLFunc_ClientPutInServer, id );
				
				cs_set_user_team( id, CS_TEAM_T );
				ExecuteHamB( Ham_CS_RoundRespawn, id );
				
				set_pev( id, pev_effects, pev( id, pev_effects ) | EF_NODRAW );
				set_pev( id, pev_solid, SOLID_NOT );
				dllfunc( DLLFunc_Think, id );
				
				g_iFakeplayer = id;
			}
		}
	}
	
	public MsgDeathMsg( const iMsgId, const iMsgDest, const id ) {
		if( get_msg_arg_int( 2 ) == g_iFakeplayer )
			return PLUGIN_HANDLED;
		
		return PLUGIN_CONTINUE;
	}
#endif

// NEW TERRORIST
///////////////////////////////////////////
public EventRandromize( ) {
	if( !g_bEnabled || g_bFirstRound || g_bRandromized )
		return PLUGIN_CONTINUE;
	
	g_bRandromized = true;
	
	new i, iPlayers[ 32 ], iNum, iPlayer;
	get_players( iPlayers, iNum, "c" );
	
	if( iNum <= 1 )
		return PLUGIN_CONTINUE;
	
	for( i = 0; i < iNum; i++ ) {
		iPlayer = iPlayers[ i ];
		
		if( cs_get_user_team( iPlayer ) == CS_TEAM_T )
			cs_set_user_team( iPlayer, CS_TEAM_CT );
	}
	
	new iRandomPlayer, CsTeams:iTeam;
	
	while( ( iRandomPlayer = iPlayers[ random_num( 0, iNum - 1 ) ] ) == g_iLastTerr ) { }
	
	g_iLastTerr = iRandomPlayer;
	
	iTeam = cs_get_user_team( iRandomPlayer );
	
	if( iTeam == CS_TEAM_T || iTeam == CS_TEAM_CT ) {
		cs_set_user_team(iRandomPlayer, CS_TEAM_T);
		
		new szName[ 32 ];
		get_user_name( iRandomPlayer, szName, 31 );
		
		for( i = 0; i < iNum; i++ )
			ColorChat(iPlayers[ i ], RED, "%s^4 %L", g_szPrefix, iPlayers[ i ], "DR_NOW_TERR", szName);
		
		if( !g_bRestart && is_valid_ent( g_iThinker ) )
			entity_set_float( g_iThinker, EV_FL_nextthink, get_gametime( ) + 15.0 );
	} else {
		g_bRandromized = false;
		EventRandromize( );
	}
	
	return PLUGIN_CONTINUE;
}

// NEW ROUND
///////////////////////////////////////////
public EventRoundStart( ) {
	if( !g_bEnabled )
		return PLUGIN_CONTINUE;
	
	g_bRandromized	= false;
	g_bStarting	= false;
	
	new i, iPlayers[ 32 ], iNum, iRealPlayers, CsTeams:iTeam;
	get_players( iPlayers, iNum, "c" );
	
	if( iNum <= 1 )
		return PLUGIN_CONTINUE;
	
	for( i = 0; i < iNum; i++ ) {
		iTeam = cs_get_user_team( iPlayers[ i ] );
		
		if( iTeam == CS_TEAM_T || iTeam == CS_TEAM_CT )
			iRealPlayers++;
	}
	
	if( iRealPlayers <= 1 ) {
		set_hudmessage( 0, 128, 0, -1.0, 0.1, 0, 4.0, 4.0, 0.5, 0.5, 4 );
		
		for( i = 0; i < iNum; i++ )
			ShowSyncHudMsg( iPlayers[ i ], g_iHudSync, "%L", iPlayers[ i ], "DR_NOT_ENOUGH" );
		
		return PLUGIN_CONTINUE;
	}
	
	set_pcvar_num( g_pAutoBalance, 0 );
	set_pcvar_num( g_pLimitTeams, 0 );
	
	if( g_bFirstRound ) {
		set_hudmessage( 0, 128, 0, -1.0, 0.1, 0, 4.0, 4.0, 0.5, 0.5, 4 );
		
		for( i = 0; i < iNum; i++ ) {
			ShowSyncHudMsg( iPlayers[ i ], g_iHudSync, "%L", iPlayers[ i ], "DR_STARTING" );
			
			ColorChat( iPlayers[ i ], RED, "%s^1 %L", g_szPrefix, iPlayers[ i ], "DR_STARTING_CC" );
		}
		
		if( is_valid_ent( g_iThinker ) ) {
			g_bRestart = true;
			
			entity_set_float( g_iThinker, EV_FL_nextthink, get_gametime( ) + 9.0 );
		} else
			set_task( 9.0, "RestartRound" );
		
		g_bStarting = true;
		g_bFirstRound = false;
	}
	
	return PLUGIN_CONTINUE;
}

// CHECK TERRORIST
///////////////////////////////////////////
public FwdThinker( iEntity ) {
	if( g_bRestart ) {
		g_bRestart = false;
		
		RestartRound( );
	} else
		CheckTerrorists( );
	
	entity_set_float( iEntity, EV_FL_nextthink, get_gametime( ) + 15.0 );
}

public CheckTerrorists( ) {
	if( !g_bEnabled || g_bFirstRound || g_bStarting )
		return PLUGIN_CONTINUE;
	
	new i, iPlayers[ 32 ], iTerrors, iNum, iRealPlayers, CsTeams:iTeam;
	get_players( iPlayers, iNum, "c" );
	
	if( iNum <= 1 )
		return PLUGIN_CONTINUE;
	
	for( i = 0; i < iNum; i++ ) {
		iTeam = cs_get_user_team( iPlayers[ i ] );
		
		if( iTeam == CS_TEAM_T )
			iTerrors++;
		
		if( iTeam == CS_TEAM_T || iTeam == CS_TEAM_CT )
			iRealPlayers++;
	}
	
	if( iRealPlayers <= 1 ) {
		set_hudmessage( 0, 128, 0, -1.0, 0.1, 0, 4.0, 4.0, 0.5, 0.5, 4 );
		
		for( i = 0; i < iNum; i++ )
			ShowSyncHudMsg( iPlayers[ i ], g_iHudSync, "%L", iPlayers[ i ], "DR_NOT_ENOUGH" );
		
		return PLUGIN_CONTINUE;
	}
	
	if( iTerrors == 0 ) {
		for( i = 0; i < iNum; i++ ) {
			ColorChat(iPlayers[ i ], RED, "%s^1 %L", g_szPrefix, iPlayers[ i ], "DR_NO_DETECT");
			
			if( is_user_alive( iPlayers[ i ] ) && cs_get_user_team( iPlayers[ i ] ) == CS_TEAM_CT )
				user_silentkill( iPlayers[ i ] );
		}
		
		set_task( 0.5, "EventRandromize" );
	}
	
	return PLUGIN_CONTINUE;
}

// LIFE SYSTEM
///////////////////////////////////////////
public EventTerrsWin( ) {
	if( !g_bEnabled || g_bFirstRound )
		return PLUGIN_CONTINUE;
	
	new iPlayers[ 32 ], iNum, iPlayer;
	get_players( iPlayers, iNum, "c" );
	
	if( iNum <= 1 )
		return PLUGIN_CONTINUE;
	
	new iLifeCvar = get_pcvar_num( g_pLifeSystem );
	
	for( new i = 0; i < iNum; i++ ) {
		iPlayer = iPlayers[ i ];
		
		if( cs_get_user_team( iPlayer ) == CS_TEAM_T ) {
			set_user_frags( iPlayer, get_user_frags( iPlayer ) + 3 );
			
			if( iLifeCvar == 2 )
				g_Lifes[ iPlayer ]++;
		}
	}
	
	return PLUGIN_CONTINUE;
}

public EventDeath( ) {
	if( !g_bEnabled )
		return PLUGIN_CONTINUE;
	
#if defined FAKE_PLAYER
	new iVictim = read_data( 2 );
	new iTeam = get_user_team( iVictim );
	
	if( iTeam == 1 && is_user_alive( g_iFakeplayer ) )
		fakedamage( g_iFakeplayer, "worldspawn", 100.0, DMG_GENERIC );
	
	if( !get_pcvar_num( g_pLifeSystem ) )
		return PLUGIN_CONTINUE;
#else
	if( !get_pcvar_num( g_pLifeSystem ) )
		return PLUGIN_CONTINUE;
	
	new iVictim = read_data( 2 );
	new iTeam = get_user_team( iVictim );
#endif
	
	new iKiller = read_data( 1 );
	
	if( iKiller != iVictim && get_user_team(iKiller) != iTeam )
		g_Lifes[iKiller]++;
	
	if( cs_get_user_team( iVictim ) == CS_TEAM_CT && g_Lifes[ iVictim ] > 0 ) {
		new iCTcount;
		for( new i = 1; i <= g_iMaxplayers; i++ ) {
			if( is_user_alive( i ) && cs_get_user_team( i ) == CS_TEAM_CT )
				iCTcount++;
		}
		
		if( iCTcount > 1 ) {
			set_task(3.2, "fnRevivePlayer", iVictim);
			
			ColorChat( iVictim, RED, "%s^1 %L", g_szPrefix, iVictim, "DR_LIFE_RESPAWN" );
		}
		/*else
			ColorChat( iVictim, RED, "%s^1 %L", g_szPrefix, iVictim, "DR_LIFE_CANT" );*/
	}
	
	return PLUGIN_CONTINUE;
}

public fnRevivePlayer( id ) {
	if( g_bConnected[ id ] ) {
		if( cs_get_user_team( id ) == CS_TEAM_CT ) {
			new iCTcount;
			for( new i = 1; i <= g_iMaxplayers; i++ )
				if( is_user_alive( i ) && cs_get_user_team( i ) == CS_TEAM_CT )
					iCTcount++;
			
			if( iCTcount > 1 ) {
				ExecuteHamB( Ham_CS_RoundRespawn, id );
				
				g_Lifes[ id ]--;
			}
		}
	}
}

public CmdShowlifes( id ) {
	if( get_pcvar_num( g_pLifeSystem ) == 0 ) {
		ColorChat( id, RED, "%s^1 %L", g_szPrefix, id, "DR_LIFE_DISABLE" );
		return PLUGIN_HANDLED;
	}
	
	if( g_Lifes[ id ] > 0 )
		ColorChat( id, RED, "%s^1 %L", g_szPrefix, id, "DR_LIFE_CC_COUNT", g_Lifes[ id ] );
	else
		ColorChat( id, RED, "%s^1 %L", g_szPrefix, id, "DR_LIFE_CC_NO" );
	
	return PLUGIN_HANDLED;
}

public Showlifes( id ) {
	set_hudmessage( 0, 128, 0, 0.04, 0.71, 0, 2.5, 2.5, 0.5, 0.5, 3 );
	
	if( g_Lifes[ id ] > 0 )
		ShowSyncHudMsg( id, g_iHudSync2, "%L", id, "DR_LIFE_COUNT", g_Lifes[ id ] );
	else
		ShowSyncHudMsg( id, g_iHudSync2, "%L", id, "DR_LIFE_NO" );
}

// EVENTS
///////////////////////////////////////////
public EventResetHud( id ) {
	if( g_bEnabled && get_pcvar_num( g_pHideHuds ) && !is_user_bot( id ) ) {
		message_begin( MSG_ONE_UNRELIABLE, g_iMsgHideWeapon, _, id );
		write_byte( ( 1<<4 | 1<<5 ) );
		message_end( );
		
		message_begin( MSG_ONE_UNRELIABLE, g_iMsgCrosshair, _, id );
		write_byte( 0 );
		message_end( );
	}
}

public EventMoney( id ) {
	if( g_bEnabled && get_pcvar_num( g_pBlockMoney ) ) {
		set_pdata_int( id, 115, 0 );
		
		message_begin( MSG_ONE_UNRELIABLE, g_iMsgMoney, _, id );
		write_long ( 0 );
		write_byte ( 1 );
		message_end( );
	}
}

public client_putinserver( id )
	g_bConnected[ id ] = true;

public client_disconnect( id ) {
	g_bConnected[ id ] = false;
	CheckTerrorists( );
	
	if( !g_bRestart && is_valid_ent( g_iThinker ) )
		entity_set_float( g_iThinker, EV_FL_nextthink, get_gametime( ) + 15.0 );
	
#if defined FAKE_PLAYER
	if( g_iFakeplayer == id ) {
		set_task( 1.5, "UpdateBot" );
		
		g_iFakeplayer = 0;
	}
#endif
}

// SEMICLIP
///////////////////////////////////////////
public FwdFullPack( es, e, ent, host, flags, player, pSet ) {
	if( !g_bEnabled )
		return FMRES_IGNORED;
	
	if( player && g_iSemiClip[ ent ] && g_iSemiClip[ host ] ) {
		set_es( es, ES_Solid, SOLID_NOT );
		set_es( es, ES_RenderMode, kRenderTransAlpha );
		set_es( es, ES_RenderAmt, 85 );
	}
	
	return FMRES_IGNORED;
}

public FwdStartFrame( ) {
	if( !g_bEnabled )
		return FMRES_IGNORED;
	
	static iPlayers[ 32 ], iNum, iPlayer, iPlayer2, i, j;
	get_players( iPlayers, iNum, "ache", "CT" );
	
	arrayset( g_iSemiClip, 0, 32 );
	
	if( iNum <= 1 )
		return FMRES_IGNORED;
	
	for( i = 0; i < iNum; i++ ) {
		iPlayer = iPlayers[ i ];
		
		for( j = 0; j < iNum; j++ ) {
			iPlayer2 = iPlayers[ j ];
			
			if( iPlayer == iPlayer2 )
				continue;
			
			if( g_iSemiClip[ iPlayer ] && g_iSemiClip[ iPlayer2 ] )
				continue;
			
			if( entity_range( iPlayer, iPlayer2 ) < 128 ) {
				g_iSemiClip[ iPlayer ]	= true;
				g_iSemiClip[ iPlayer2 ]	= true;
			}
		}
	}
	
	for( i = 0; i < iNum; i++ ) {
		iPlayer = iPlayers[ i ];
		
		set_pev( iPlayer, pev_solid, g_iSemiClip[ iPlayer ] ? SOLID_NOT : SOLID_SLIDEBOX );
	}
	
	return FMRES_IGNORED;
}

// FORWARDS
///////////////////////////////////////////
public FwdHamPlayerSpawn( id ) {
	if( !g_bEnabled || !is_user_alive( id ) )
		return HAM_IGNORED;
	
	if( get_pcvar_num( g_pBlockRadio ) ) // thanks to ConnorMcLeod for this good way :)
		set_pdata_int( id, 192, 0 );
	
#if defined FAKE_PLAYER
	if( g_iFakeplayer == id ) {
		set_pev( id, pev_frags, -1000.0 );
		cs_set_user_deaths( id, -1000 );
		
		set_pev( id, pev_effects, pev( id, pev_effects ) | EF_NODRAW );
		set_pev( id, pev_solid, SOLID_NOT );
		entity_set_origin( id, Float:{ 999999.0, 999999.0, 999999.0 } );
		dllfunc( DLLFunc_Think, id );
	} else {
#endif
		new CsTeams:iTeam = cs_get_user_team( id );
		
		// An small delay for message
		if( get_pcvar_num( g_pLifeSystem ) != 0 && iTeam == CS_TEAM_CT )
			set_task( 0.8, "Showlifes", id );
		
		strip_user_weapons( id );
		give_item( id, "weapon_knife" );
		
		set_pdata_int( id, 116, 0 ); // Pickup fix by ConnorMcLeod
		
		if( g_bGamerFun && iTeam == CS_TEAM_CT )
			give_item( id, "weapon_smokegrenade" );
		
		if( get_pcvar_num( g_pGiveUsp ) && iTeam == CS_TEAM_CT && !g_bHauntedHouse )
			set_task( 1.0, "GiveUsp", id );

#if defined FAKE_PLAYER
	}
#endif
	
	return HAM_IGNORED;
}

public GiveUsp( const id ) {
	if( is_user_alive( id ) ) {
		give_item( id, "weapon_usp" );
		cs_set_user_bpammo( id, CSW_USP, 100 );
	}
}

public FwdGameDesc( ) {
	static const GameName[ ] = "Deathrun v3.0";
	
	forward_return( FMV_STRING, GameName );
	
	return FMRES_SUPERCEDE;
}

public FwdClientKill( const id ) {
	if( !g_bEnabled || !is_user_alive(id) )
		return FMRES_IGNORED;
	
	if( get_pcvar_num( g_pBlockKill ) || cs_get_user_team( id ) == CS_TEAM_T ) {
		client_print( id, print_center, "%L", id, "DR_BLOCK_KILL" );
		client_print( id, print_console, "%L", id, "DR_BLOCK_KILL" );
		
		return FMRES_SUPERCEDE;
	}
	
	return FMRES_IGNORED;
}

public FwdImpulse_201( const id ) {
	if( g_bEnabled && get_pcvar_num( g_pBlockSpray ) ) {
		if( is_user_alive( id ) )
			client_print( id, print_center, "%L", id, "DR_BLOCK_SPRAY" );
		
		return PLUGIN_HANDLED_MAIN;
	}
	
	return PLUGIN_CONTINUE;
}

public FwdHamPlayerDamage( id, idInflictor, idAttacker, Float:flDamage, iDamageBits ) {
	if( get_pcvar_num( g_pNoFallDmg ) )
		if( iDamageBits & DMG_FALL )
			if( get_user_team( id ) == 1 )
				return HAM_SUPERCEDE;
	
	return HAM_IGNORED;
}

public MsgStatusIcon( msg_id, msg_dest, id ) {
	new szIcon[ 8 ];
	get_msg_arg_string( 2, szIcon, 7 );
	
	static const BuyZone[ ] = "buyzone";
	
	if( equal( szIcon, BuyZone ) ) {
		set_pdata_int( id, OFFSET_BZ, get_pdata_int( id, OFFSET_BZ, 5 ) & ~( 1 << 0 ), 5 );
		
		return PLUGIN_HANDLED;
	}
	
	return PLUGIN_CONTINUE;
}

public CmdRadio( id ) {
	if( get_pcvar_num( g_pBlockRadio ) )
		return PLUGIN_HANDLED_MAIN;
	
	return PLUGIN_CONTINUE;
}

public RestartRound( )
	set_pcvar_num( g_pSvRestart, 1 );

// COLORCHAT
/////////////////////////////////////////////
ColorChat( id, Color:type, const szMessage[], {Float,Sql,Result,_}:... ) {
	if( !get_playersnum( ) ) return;
	
	new message[ 256 ];
	
	switch( type ) {
		case NORMAL: message[0] = 0x01;
		case GREEN: message[0] = 0x04;
		default: message[0] = 0x03;
	}
	
	vformat( message[ 1 ], 251, szMessage, 4 );
	
	message[ 192 ] = '^0';
	
	replace_all( message, 191, "\YEL", "^1" );
	replace_all( message, 191, "\GRN", "^4" );
	replace_all( message, 191, "\TEM", "^3" );
	
	new iTeam, ColorChange, index, MSG_Type;
	
	if( id ) {
		MSG_Type = MSG_ONE_UNRELIABLE;
		index = id;
	} else {
		index = CC_FindPlayer();
		MSG_Type = MSG_BROADCAST;
	}
	
	iTeam = get_user_team( index );
	ColorChange = CC_ColorSelection(index, MSG_Type, type);

	CC_ShowColorMessage(index, MSG_Type, message);
	
	if( ColorChange )
		CC_Team_Info(index, MSG_Type, TeamName[iTeam]);
}

CC_ShowColorMessage( id, type, message[] ) {
	message_begin( type, g_iMsgSayText, _, id );
	write_byte( id );	
	write_string( message );
	message_end( );	
}

CC_Team_Info( id, type, team[] ) {
	message_begin( type, g_iMsgTeamInfo, _, id );
	write_byte( id );
	write_string( team );
	message_end( );
	
	return 1;
}

CC_ColorSelection( index, type, Color:Type ) {
	switch( Type ) {
		case RED: return CC_Team_Info( index, type, TeamName[ 1 ] );
		case BLUE: return CC_Team_Info( index, type, TeamName[ 2 ] );
	}
	
	return 0;
}

CC_FindPlayer( ) {
	for( new i = 1; i <= g_iMaxplayers; i++ )
		if( g_bConnected[ i ] )
			return i;
	
	return -1;
}