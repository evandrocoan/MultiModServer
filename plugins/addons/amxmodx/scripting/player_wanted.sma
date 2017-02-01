/*
==========================================================================================
*** Player Wanted ***
author:		Nightscream
msn:		pipo1568@hotmail.com
		
Version:	1.1
==========================================================================================
Credits:	Kleenex: for fixing and helping me
		V3X: for giving me the most kill script
==========================================================================================
### Cvars ###
wanted_start "1000"	This is the start money that is set on the wanted player
wanted_extra "500"	This is the money that will increase the wanted money for every
			round the top player suvives
==========================================================================================
### Modules ###
Cstrike required
==========================================================================================
### Tested On ###
Listen server | Condition zero | Windows XP | AMXX 1.71
==========================================================================================
### Suggestions ###
Got some suggestions
post them in the topic or in pm me
==========================================================================================
### Changelog ###
1.0 Release
1.1 Added Top players won't get wanted money
*/

#include <amxmodx>
#include <amxmisc>
#include <cstrike>

#define PLUGIN "Player Wanted"
#define VERSION "1.1"
#define AUTHOR "Nightscream"

new gSurvived[33]
new gTop_terror
new gTop_ct
new gOldTerror
new gOldct
new gWantedmoney


public plugin_init() {
	register_plugin( PLUGIN, VERSION, AUTHOR );
	
	register_cvar( "wanted_start", "1000")
	register_cvar( "wanted_extra", "500");
	
	register_event( "DeathMsg" , "on_death" , "a" );
	
	register_logevent( "event_roundstart", 2, "0=World triggered", "1=Round_Start" );
	register_logevent( "event_roundend", 2, "0=World triggered", "1=Round_End" );
}
public event_roundstart() {
	
	gTop_terror = getMostKills( CS_TEAM_T );
	gTop_ct = getMostKills( CS_TEAM_CT );
	
	if( gTop_terror != gOldTerror ) {
		gSurvived[gTop_terror] = 0;
	}
	if( gTop_ct != gOldct ) {
		gSurvived[gTop_ct] = 0;
	}
	
	new Tname[32], CTname[32];
	get_user_name( gTop_terror, Tname, 31 );
	get_user_name( gTop_ct, CTname, 31 );
	
	client_print( 0, print_center, "Preocura-se: %s e %s.", CTname, Tname );
	
	return PLUGIN_CONTINUE
}

public on_death( id ) {
	new killer_id = read_data( 1 ); //Killer id
	new victim_id = read_data( 2 ); //Victim id
	
	//if( killer_id == gTop_terror || killer_id == gTop_ct ) return PLUGIN_CONTINUE
	
	if( gTop_terror == victim_id ) {
		new kname[32], vname[32];
		get_user_name( killer_id, kname, 31 ); //get killer name
		get_user_name( gTop_terror, vname, 31 ); //get victim name
		
		new money = cs_get_user_money( killer_id );
		cs_set_user_money( killer_id, money + gWantedmoney );
		
		client_print( 0, print_center, "%s capturou %s, e recebeu seus %d, de recompensa.", kname, vname, gWantedmoney );
		client_print( 0, print_chat, "[  %s capturou %s, e recebeu seus %d, de recompensa.  ]", kname, vname, gWantedmoney );
	}
	if( gTop_ct == victim_id ) {
		new kname[32], vname[32]
		get_user_name( killer_id, kname, 31 ); //get killer name
		get_user_name( gTop_ct, vname, 31 ); //get victim name
		
		new money = cs_get_user_money( killer_id );
		
		cs_set_user_money( killer_id, money + gWantedmoney );
		
		client_print( 0, print_center, "%s capturou %s, e recebeu seus %d, de recompensa.", kname, vname, gWantedmoney );
		client_print( 0, print_chat, "[  %s capturou %s, e recebeu seus %d, de recompensa.  ]", kname, vname, gWantedmoney );
	}
	
	return PLUGIN_CONTINUE
}

public event_roundend() {
	
	if( is_user_alive( gTop_terror ) ) {
		gSurvived[gTop_terror]++
		checkwantedmoney( gTop_terror )
		
	}else {
		gSurvived[gTop_terror] = 0;
		checkwantedmoney( gTop_terror )
	}
	if( is_user_alive( gTop_ct ) ) {
		gSurvived[gTop_ct]++
		checkwantedmoney( gTop_ct )
	}else {
		gSurvived[gTop_ct] = 0;
		checkwantedmoney( gTop_ct )
	}
	
	gOldTerror = gTop_terror;
	gOldct = gTop_ct;
	
	//client_print( 0, print_chat, "O terrorista procurado sobreviveu %i vezes. E o contra-terrorista procurado sobreviveu %i vezes.", gSurvived[gTop_terror], gSurvived[gTop_ct] );
	
	return PLUGIN_CONTINUE
}

public checkwantedmoney( id ) {
	new wmoney = get_cvar_num( "wanted_start" );
	new extramoney = get_cvar_num( "wanted_extra" );
	gWantedmoney = wmoney + (extramoney * gSurvived[id]);
}

public getMostKills( CsTeams:team )
{
        new maxPlayers = get_maxplayers();
        new mostkills[2] = { 0, 0 }; // 0 = id, 1 = frags

        for( new i = 1; i <= maxPlayers; i++ )
        {
                if( !is_user_connected( i ) || cs_get_user_team( i ) != team )
                        continue;
                new frags = get_user_frags( i );
                if( frags > mostkills[1] )
                {
                        mostkills[1] = frags;
                        mostkills[0] = i;
                }
                
        } 

        return mostkills[0];      
}  	
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang2067\\ f0\\ fs16 \n\\ par }
*/
