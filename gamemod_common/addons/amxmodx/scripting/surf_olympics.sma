#pragma dynamic 131072 //I used to much memory =(
/*
 * ====================================================================================================
 * ====================================================================================================
 * 		---------------------------SURF_OLYMPICS-v1.5.2a--------BY: OneEyed---------------------------
 * ====================================================================================================
 * ====================================================================================================
 *	COMMENTS: 
 *		Install the plugin normally, and get ready to beat some freagin records!
 * ====================================================================================================
 *	REQUIRED:
 *		AMXX 1.70
 *
 *	MODULES:
 *		CSTRIKE
 *		ENGINE
 *		FAKEMETA
 *		NVAULT
 * ====================================================================================================
 *	CVARS: 
 *		surf_flyspeed <#> 				- Changes flying speed of surf_endzone tool
 *		surf_teamstack < 0 | 1 | 2 > 	- Forces players to be in a certain team.
 *		surf_godmode < 0 | 1 >			- Enables/Disables godmode on players.
 *		surf_semiclip < 0 | 1 > 		- Enables/Disables semi-clip on players.
 *	
 *	COMMANDS:
 *		surf_endzone					- Enables Surf EndZone Creation Tool
 *		surf_delete						- Enables Map Record Catagory Deletion menu.
 *		surf_on	< 0 | 1 >				- Enables/Disables plugin 99%.
 *
 *	CHAT COMMANDS:
 *		/spec							- Makes you a spectator.
 *		/respawn						- Respawns you.
 *		/top3							- Opens Map Top Records list.
 *		/help							- Opens help menu.
 *
 * ====================================================================================================
 *	PLUGIN DETAILS:
 *		When you spawn in, your in standby mode.  As soon as you jump, your game is activated and your
 *		records get recorded.  Current records are Map Completion, Speed, Hang Time, Distance, and
 *		Height.  The plugin automatically respawns users when you die or fall down.  Players also have
 *		a simulated Semi-clip, so they don't get stuck inside each other, but still allow to block
 *		each other.  To complete the map, touch the designated EndZone lightning bolt.
 *
 * ====================================================================================================
 *	CREDITS: 
 *		- Rukia found how to know if your on ladder. (drove me nuts yet it was so easy)
 *		- teame06/VEN for HLTV event.
 *		- teame06 help with new menu system, and Team_Select menu, and some inspiration =).
 *		- Xtrem3 found a major hang time exploit.
 *		- iron helix found a major height exploit.
 *		- XAD - used the same font color from his statsx motd.
 *		- door for helping me test some features.
 *		- Gorlag/Batman for his Flying code.
 *		- BASIC-MASTER, I copied his Special Effect. (not the code, just effect)
 *		- BAILOPAN for some of the weapon removal code from CSDM v1.
 *		- BAILOPAN, for his information on code optimization. (READ IT)
 *			-- http://www.sourcemod.net/devlog/?p=62
 * ====================================================================================================
 *	CHANGELOG:
 *
 *	v1.5.2a:
 *	- Reverted back to old method, will crash again on surf_xss and surf_maya 
 *		if you have plugins that precache models.  It's the maps fault for having 
 *		to many brush models.  Attempting to fix, completely breaks my plugin on normal maps.
 *
 *	v1.5.2:
 *	- Fixed crashing in surf_xss and surf_maya.
 *
 *	v1.5.1:
 *	- Fixed a bug with the semi-clip cvar.
 *	- Fixed a entity leak error with weapon removal.
 *
 *	v1.5:
 *	- Commentator can be turned on/off through a #define.
 *	- New CVARs: 
 *		- surf_godmode 	< 0 | 1 >	(Turns God Mode OFF/ON, for everyone.)
 *		- surf_semiclip  < 0 | 1 >	(Turns Semi-Clip OFF/ON, for everyone.)
 *	- New Commands:
 *		- surf_delete 			(Opens menu to delete records of current map.)
 *		- surf_on < 0 | 1 > 	(Turns plugin OFF/ON completely.)
 *	- Reworked Top Record System:
 *		- One person can't dominate an entire record, there will always be three
 *		- different players for every record catagory. Saved by STEAMID not name.
 *	- Weapons from game_player_equip entity are removed upon death, to prevent spam.
 *	- Players can now easily jump on top of users in Semi-Clip mode.
 *
 *	v1.1:
 *	- Changed the HUD system a little bit, to be less laggy.
 *	- Fixed an accidental logical error with clearing airtype records.
 *	- Blocked trigger_hurts that heal from teleporting.
 *	- Added Personal Statistics to /top3 window. 
 * ====================================================================================================
 */

/*======== User Changeable Defines =========*/

//Uncomment to add commentator text.
//#define COMMENTATOR		

#define STATS_COLOR_RED		255
#define STATS_COLOR_GREEN	180
#define STATS_COLOR_BLUE	0
#define STATS_LOC_X 		1.0
#define STATS_LOC_Y			0.5

#define RECORDS_HUD_DELAY	7.0
#define RECORD_COLOR_RED	220
#define RECORD_COLOR_GREEN	80
#define RECORD_COLOR_BLUE	0
#define RECORD_LOC_X		1.0
#define RECORD_LOC_Y		0.30

//EndZone Special Effects
#define PULSE_FREQUENCY		0.4 //in seconds

#define LINE_COLOR_RED		255
#define LINE_COLOR_GREEN	255
#define LINE_COLOR_BLUE		255

#define WAVE_COLOR_RED		0
#define WAVE_COLOR_GREEN	255
#define WAVE_COLOR_BLUE		0

/*==========================================*/


/*======================ONLY CODERS BEYOND THIS POINT!!=======================================*/
/*======================ONLY CODERS BEYOND THIS POINT!!=======================================*/
/*======================ONLY CODERS BEYOND THIS POINT!!=======================================*/

/*====================================================================================================
 How To Add A custom Record:
 	Update the globals to add your custom record info.  Scroll down to [Custom Records] and create your
 	custom record function and math there and at the end add the template Validate_BeatRecord.
 	If you have any global vars for your custom record, drop them inside the clean up functions, so 
 	they get reset.  After that, add your custom record function inside the core named JudgeJudy.
====================================================================================================*/
#include <amxmodx>
#include <amxmisc>
#include <engine>
#include <fakemeta>
#include <cstrike>
#include <nvault>

new Vault
static const VAULTNAME[] = "MapRecords"

new Vault_EndZone
static const ENDZONE_VAULT[] = "EndZones"

#define MAX_BUFFER_LENGTH 2047
#define MAX_TEXT_LENGTH 100
#define MAX_PLAYERS	32
/****************************************************/
/**************** Editable Globals ******************/

#define NUMRANKS 	3
#define NUMRECORDS 	5

//Record Types in order.
enum { 
	COMPLETION = 1,
	SPEED,
	HANGTIME,
	DISTANCE,
	HEIGHT
}

//These records require players to be in the air for recording.
#define NUM_AIR_RECORDS 		3
new AIR_RECORDS[NUM_AIR_RECORDS] = {
	HANGTIME,
	DISTANCE,
	HEIGHT
}

//These records are read at all times.
#define NUM_ANYTIME_RECORDS		1
new ANYTIME_RECORDS[NUM_ANYTIME_RECORDS] = {
	SPEED	
}

//I predefined up to 7th rank. Be warned, show_motd can only hold 2047 characters in total.
//4 ranks uses nearly all that.  So some changes will need to be made if u want to display more.
//You shouldn't need more than 4, cause the records end up being very close to each other.
static const RANKS[NUMRANKS+1][] = { 
	"NULL", 
	"st", 
	"nd", 
	"rd" 
/*	"th", 
	"th", 
	"th", 
	"th" */
}

//The Titles order must match enum up top.
static const TITLES[NUMRECORDS+1][] = {
	"NULL",
	"Completion",
	"Speed",
	"Hang Time",
	"Distance",
	"Height"
}

//symbols records use, order must match enum up top.
static const TYPES[NUMRECORDS+1][] = { "NULL", "sec", "mph", "sec", "ft", "ft" }

#if defined COMMENTATOR
static const BAD_COMMENT[4][] = { 
	"Wipe Out!", 
	"OUCH!", 
	"That's gotta hurt!", 
	"Try Again!" 
}
	
static const GOOD_COMMENT[5][] = { 
	"Way to go!", 
	"Awesome!", 
	"Nice!", 
	"Spectacular!", 
	"That's OUTRAGEOUS!" 
}
#endif


/****************************************************/
/**************** Record Variables ******************/

//Saved Personal Best Record
new Float:g_fPersonalRecord[MAX_PLAYERS+1][NUMRECORDS+1]
//Current Record of current run (prevents multiple records for top records in one jump)
new Float:g_fPersonalOld[MAX_PLAYERS+1][NUMRECORDS+1]
//Top Records of map 1st/2nd/3rd
new Float:g_fTopRecord[NUMRECORDS+1][NUMRANKS+1]

//For quick data accessing
new g_TopRecordName[NUMRECORDS+1][NUMRANKS+1][MAX_TEXT_LENGTH+1]
new g_TopRecordSteamId[NUMRECORDS+1][NUMRANKS+1][MAX_TEXT_LENGTH+1]

/****************************************************/
/************ Custom Record Variables ***************/

new Float:g_fTimeElapsed[MAX_PLAYERS+1]
new Float:g_fvecEndOrigin[MAX_PLAYERS+1][3]	//Where we currently are.
new Float:g_fvecPrevOrigin[MAX_PLAYERS+1][3]	//For Teleport Menu (Prev Location).
new Float:g_fHeight[MAX_PLAYERS+1]				//Height we reached.
new g_vecStartOrigin[MAX_PLAYERS+1][3] 		//Where we took off from wave/jump.
new bool:g_bDistCheck[MAX_PLAYERS+1]			//When to calculate distance.

/****************************************************/
/****************** Event Flags *********************/

new Float:g_Gametime
new Float:g_fShowHudDelay[MAX_PLAYERS+1]

new Float:g_fIsInAir[MAX_PLAYERS+1] //If this is not equal to current get_gametime(), player is in AIR.
new bool:g_bPlaystarted[MAX_PLAYERS+1]
new bool:g_bRespawning[MAX_PLAYERS+1]
new bool:g_bPlaying[MAX_PLAYERS+1]
new bool:g_bIsDead[MAX_PLAYERS+1]

//record beating flags, so we don't update only once... appropriately
new bool:g_bCheckPersonal[MAX_PLAYERS+1][NUMRECORDS+1]
new bool:g_bCheckTop[MAX_PLAYERS+1][NUMRECORDS+1]


/****************************************************/
/**************** Hud Text Messages *****************/

new g_StatText[MAX_PLAYERS+1][NUMRECORDS + 1][MAX_TEXT_LENGTH + 1]
new g_RecordText[MAX_PLAYERS+1][NUMRECORDS + 1][MAX_TEXT_LENGTH + 1]

new HudText_Records[MAX_BUFFER_LENGTH + 1]
new HudText_Stats[MAX_BUFFER_LENGTH + 1]

/****************************************************/
/****************** Misc Variables ******************/
new bool:g_bIsSurf
new bool:g_bRunOnce
new g_Maxplayers
new g_MapName[64]
new g_EndRound
new g_NoClip

//endzone misc.
new bool:g_bModifyMode[MAX_PLAYERS+1]
new bool:g_IsFlying[MAX_PLAYERS+1]
new bool:g_bFinished[MAX_PLAYERS+1]

//menus
new menu_teleport
new menu_modify[MAX_PLAYERS+1]
new menu_finished[MAX_PLAYERS+1]
new menu_help
new menu_savecheck
new menu_deletecheck
new menu_deleterecords

/****************************************************/
/************** Special FX Variables ****************/

new g_fxBeamSprite, g_fxWave

/****************************************************/
/**************** Entity Variables ******************/

//game_player_equip weapons
new g_StartWeap[32][64]
new g_TotalWeap
//teleport destinations
new g_TotalTeleDest
new g_TeleDest[100][32]
new g_TeleDestId[100]				
//trigger_teleports
new g_TotalTeleports
new g_TriggerTeleport[100][32]
new g_TriggerTeleId[100]	
//trigger hurts with healing
new g_TriggerHurtHealers[100]
new g_TrigHurtHealTotal
//linked info_target_destination & trigger_teleport
new g_LinkedTeleAndDest[100][2]
new g_TotalLinked	
//spawns info
new g_InfoPlayerStart
new g_InfoPlayerDeathmatch
new bool:g_bBothTeamsActive
//EndZone Vars
new g_EndzoneEntity
static const ENDZONE_MODEL[] = "models/chick.mdl" //this will be invisible (needed to set a bounding box)
/****************************************************/
//====================================================================================================
static const TITLE[] = "surf_olympics"
static const VERSION[] = "1.5.2a"
static const AUTHOR[] = "OneEyed"
//====================================================================================================


/*====================================================================================================
 [Initialize]

 Purpose:	Prepares the map by automating a bunch of information at start of map, so plugin won't lag 
			during gameplay.  Also validates if we're on a SURF_MAP.  If not plugin disables itself
			100%.

 Comment:	Added CVAR for internet query lookup of plugin.

====================================================================================================*/
public plugin_init() {
	register_plugin(TITLE,VERSION,AUTHOR)
	register_cvar(TITLE,"0",FCVAR_SERVER)

	if(g_bIsSurf)
		set_cvar_num(TITLE,1)
	else {
		set_cvar_num(TITLE,0)
		return PLUGIN_HANDLED
	}
	
	PRECACHE_MODELS()
	
	g_Maxplayers = get_maxplayers()
	
	//Find if map is missing a teams spawn points.
	if(g_InfoPlayerDeathmatch == 0 || g_InfoPlayerStart == 0)
		g_bBothTeamsActive = true
	
	LoadMenus()

	register_cvar("surf_flyspeed","1500")
	register_cvar("surf_teamstack","0")
	register_cvar("surf_semiclip","1")
	register_cvar("surf_godmode","0")
	
	register_clcmd("say /spec","cmdSpectate")
	register_clcmd("say /respawn","cmdRespawn")
	register_clcmd("say_team /respawn","cmdRespawn")
	register_clcmd("say /top3","recordLookUp")
	register_clcmd("say_team /top3","recordLookUp")
	register_clcmd("say","handle_say")
	register_clcmd("say_team", "handle_say")
	
	register_concmd("surf_on","cmdEnable",ADMIN_RCON,"<0|1> Enable / Disable Surf Olympics")
	register_concmd("surf_delete","cmdDeleteRecords",ADMIN_RCON, " Deletes Top Map Records by Type.")
	register_concmd("surf_endzone","cmdEZModify",ADMIN_RCON," Easy Endzone Creator!")
	
	
	register_menucmd(register_menuid("Team_Select",1), (1<<0)|(1<<1)|(1<<4)|(1<<5), "team_select") 
	
	register_event("DeathMsg", "Event_DeathMsg", "a")
	register_event("ResetHUD", "Event_ResetHUD", "be")
	register_event("SendAudio","Event_EndRound","a","2=%!MRAD_terwin","2=%!MRAD_ctwin","2=%!MRAD_rounddraw")
	register_event("TextMsg","Event_EndRound","a","1=4","2=#Game_Commencing")
	register_event("HLTV","Event_StartRound","a","1=0","2=0")
	
	register_touch("trigger_hurt", "player",  "Touch_TriggerHurt")
	register_touch("trigger_teleport", "player", "Touch_Teleport")
	
	//These are our slopes, considered like your in the air to EV_INT_flags so we need them.
	register_touch("player", "worldspawn", "Touch_World")
	register_touch("player", "func_water", "Touch_World")
	register_touch("player", "func_wall", "Touch_World")
	register_touch("player", "func_breakable", "Touch_World")
	
	register_touch("EndZone", "player", "Touch_EndZone")
	register_touch("player", "player", "Touch_Player")
	
	//CORE Loop
	//Meanest bitch of the south!
	new judge = create_entity("info_target")
	if (judge) {
		entity_set_string(judge, EV_SZ_classname, "JudgeJudy")
		entity_set_float(judge, EV_FL_nextthink, halflife_time() + 0.1)
		register_think("JudgeJudy", "JudgeJudy")
	}
	
	register_think("EndZone","setEffects")
	
	LoadRecords()
	return PLUGIN_HANDLED
}

PRECACHE_MODELS() {
	if(g_bIsSurf) {
		engfunc( EngFunc_PrecacheModel, "models/chick.mdl");	
		g_fxBeamSprite = engfunc( EngFunc_PrecacheModel,"sprites/lgtning.spr")//engfunc( EngFunc_PrecacheModel,
		g_fxWave = engfunc( EngFunc_PrecacheModel,"sprites/shockwave.spr")//engfunc( EngFunc_PrecacheModel,
	}	
}

/*====================================================================================================
 [Core]

 Purpose:	This is the core, it runs every 0.1 seconds.  Scans through all players.  Works by knowing
			when player enters team, dies, jumps to begin session, if player is in the air for record 
			logging, and prints their HUD of information.  All record checks are activated here, except
			for map completion.

 Comment:	The core of the plugin lies in Judge Judy's hands, so RESPECT!
			If your smart, you can add your own custom records to it.

====================================================================================================*/
public JudgeJudy(judge) {
	
	if(!g_EndRound && g_bIsSurf) {
		
		g_Gametime = get_gametime()
		g_NoClip = get_cvar_num("surf_semiclip")
		
		for(new id=1;id<=g_Maxplayers;id++) {
			
			if(!is_user_connected(id) || g_bModifyMode[id]) continue
			
			new team = get_user_team(id)
			if( team == 1 || team == 2 ) 
			{
				if(!g_bBothTeamsActive)
					check_team(id,team)
				
				if(!is_user_alive(id)) {
					if(!g_bIsDead[id]) {
						g_bIsDead[id] = true
						set_task(0.5,"AutoRespawn",id)
					}
					g_fIsInAir[id] = g_Gametime + 0.1
					continue
				}
				
				//part of semi-clip
				if(entity_get_int(id,EV_INT_solid) != SOLID_BBOX)
					entity_set_int(id,EV_INT_solid,SOLID_BBOX)
				
				new flags = entity_get_int(id, EV_INT_flags)
				new grounded = on_ground(id,flags)
				new bool:playstarted2 = g_bPlaystarted[id]
				
				// Time Elapsed Timer
				showTimeElapsed(id,playstarted2)
				
				//Player just spawned/teleported in, don't start anything until they touch ground
				if(!g_bPlaying[id]) {
					if(grounded) {
						clearAirRecords(id)	
						g_bPlaying[id] = true
					}
					continue
				}
				else {
					
					entity_get_vector(id,EV_VEC_origin,g_fvecEndOrigin[id])
					//player on ground.
					if(grounded)
					{	
						Validate_AirChecks(id)
						clearAirRecords(id)
						
					}
					else if(g_fIsInAir[id] < g_Gametime) //We're in the air do your stuff quickly.
					{	
						if(!playstarted2) //Player jumped lets begin recording everything
						{				
							g_fTimeElapsed[id] = g_Gametime
							playstarted2 = true
						}
						
						if(flags & FL_BASEVELOCITY)	//Block Trigger_Push Exploit (but still update HUD)
							clearAirRecords(id)
						
						if(g_bRespawning[id]) {		//Fix Teleport/Respawn exploit
							g_bRespawning[id] = false
							clearAirRecords(id)	
						}
						
						/*Records that require player in air*/
						Check_Distance(id)
						Check_Height(id)
						Check_HangTime(id)
						/************************************/
					}
					
					/*Records of player at all times*/
					Check_Speed(id)
					/*******************************/
				}
					
				g_bPlaystarted[id] = playstarted2

				showStats(id)	//Display HUD
				
			}
			else {
				if(g_NoClip && entity_get_int(id,EV_INT_solid) != SOLID_NOT)
					entity_set_int(id, EV_INT_solid, SOLID_NOT)
			}
		}
	}
	entity_set_float(judge, EV_FL_nextthink, halflife_time() + 0.1)
}

/*====================================================================================================
 [Display HUD]

 Purpose:	Displays Records/Stats to users.  show Records is displayed when user respawns/uses command.
 			showStats displays when user is playing.

 Comment:	$$

====================================================================================================*/
public showRecords(id)
{
	if((g_Gametime - g_fShowHudDelay[id]) > (RECORDS_HUD_DELAY + 1.0)) 
	{
		new rLen = format(HudText_Records, MAX_BUFFER_LENGTH, "Record Statistics")

		for( new x = 2 ; x <= NUMRECORDS ; x++ )
			rLen += format(HudText_Records[rLen], MAX_BUFFER_LENGTH-rLen, "%s", g_RecordText[id][x])
	
		rLen += format(HudText_Records[rLen], MAX_BUFFER_LENGTH-rLen, "%s", g_RecordText[id][COMPLETION])
	
		set_hudmessage(RECORD_COLOR_RED, RECORD_COLOR_GREEN, RECORD_COLOR_BLUE, RECORD_LOC_X, RECORD_LOC_Y, 1, 3.0, RECORDS_HUD_DELAY, 0.0, 1.0, 5)
		show_hudmessage(id,"%s",HudText_Records)
		g_fShowHudDelay[id] = g_Gametime
	}
	
}

public showTimeElapsed(id, bool:started) {
	if(g_EndzoneEntity && !g_bFinished[id] && started)
	{
		format(g_StatText[id][COMPLETION],MAX_TEXT_LENGTH,"^nTime Elapsed %.1f sec",(g_Gametime - g_fTimeElapsed[id]))

		set_hudmessage(STATS_COLOR_RED, STATS_COLOR_GREEN, STATS_COLOR_BLUE, -1.0, 0.0, 0, 0.0, 0.3, 0.0, 0.0, 4)
		show_hudmessage(id,"%s",g_StatText[id][COMPLETION])
	}
	else
		g_StatText[id][COMPLETION][0] = 0
}

public showStats(id) 
{
	HudText_Stats[0] = 0
	new sLen = 0
	for( new x = 2 ; x <= NUMRECORDS ; x++ )
		sLen += format(HudText_Stats[sLen], MAX_BUFFER_LENGTH-sLen, "%s", g_StatText[id][x])
	
	set_hudmessage(STATS_COLOR_RED, STATS_COLOR_GREEN, STATS_COLOR_BLUE, STATS_LOC_X, STATS_LOC_Y, 0, 0.0, 0.3, 0.0, 0.0, 3)
	show_hudmessage(id,"%s",HudText_Stats)

}

/*====================================================================================================
 [Custom Records]

 Purpose:	Our record keepings are done here.

 Comment:	Use the template Validate_BeatRecord for custom records if you want records to be
 			beaten more than once in an entire run.  Unlike check completion, which is checked once when
 			player reaches endzone.

====================================================================================================*/

Check_HangTime(id) 
{
	//check for a serious ladder exploit
	new startEnt, cn[64]
	while((startEnt = find_ent_in_sphere(startEnt,g_fvecEndOrigin[id],45.0)) != 0) 
	{
		if(is_user_connected(startEnt) || !is_valid_ent(startEnt)) continue
			
		entity_get_string(startEnt,EV_SZ_classname,cn,63)
		if(equal(cn,"func_ladder")) {
			g_fIsInAir[id] = g_Gametime
			return PLUGIN_HANDLED
		}
	}
		
	new Float:pHangtime = (g_Gametime - g_fIsInAir[id])
	Validate_BeatRecord(id, HANGTIME, pHangtime)
	
	return PLUGIN_HANDLED
}

Check_Speed(id) {
	new Float:pSpeed = float(get_speed(id)) / 18.0
	Validate_BeatRecord(id, SPEED, pSpeed)
}

Check_Distance(id) {
	
	if(g_bDistCheck[id])
	{
		
		g_vecStartOrigin[id][0] = floatround(g_fvecEndOrigin[id][0])
		g_vecStartOrigin[id][1] = floatround(g_fvecEndOrigin[id][1])
		
		g_bDistCheck[id] = false
	}
	else
	{
		new newdist[3]
		newdist[0] = floatround(g_fvecEndOrigin[id][0])
		newdist[1] = floatround(g_fvecEndOrigin[id][1])
		
		new Float:pDist = float(get_distance(g_vecStartOrigin[id],newdist)) / 16.5
		Validate_BeatRecord(id, DISTANCE, pDist)
	}
}

Check_Height(id) {

	new Float:jHeight = (g_fvecEndOrigin[id][2] - g_fHeight[id]) / 8.0
	
	if(jHeight < 0.0) return
	
	Validate_BeatRecord(id, HEIGHT, jHeight)

	return
}

Float:Check_Completion(id) {
	//use get_gametime() to get a more accurate reading.
	new Float:fCompletion = get_gametime() - g_fTimeElapsed[id]
	
	format(g_StatText[id][COMPLETION],MAX_TEXT_LENGTH,"^nMap Completed in %.2f seconds",fCompletion)
	
	if(fCompletion < g_fPersonalRecord[id][COMPLETION]) {
		g_fPersonalRecord[id][COMPLETION] = fCompletion
		format(g_RecordText[id][COMPLETION],MAX_TEXT_LENGTH,"^nCompletion -- %.2f sec",fCompletion)
	}
	
	g_fPersonalOld[id][COMPLETION] = fCompletion
	
	Check_TopRecord(id, COMPLETION, 1) 
	
	return fCompletion
}

/*====================================================================================================
 [Validation]

 Purpose:	If we beat a personal record, automatically update it.  If we beat a Top 3 record, do
			a check to find what rank our player reached.  Cascade our top_records down a rank respectively.

 Comment:	If you add a custom record, use the Validate BeatRecord template.

====================================================================================================*/
Validate_BeatRecord(id, recordtype, Float:jRecord) {
	
	//Format HUD Stat String of recordtype
	format(g_StatText[id][recordtype], MAX_TEXT_LENGTH, "^n%s -- %.2f %s", TITLES[recordtype], jRecord, TYPES[recordtype])
	
	//If our running statistic beats players record of current session, update it
	//and check if it beat a personal/top record, if so, mark its flag.
	if(jRecord > g_fPersonalOld[id][recordtype]) 
	{ 
		g_fPersonalOld[id][recordtype] = jRecord 	//save their best (for current session)
		
		if(jRecord > g_fPersonalRecord[id][recordtype])		// beat their own record
			g_bCheckPersonal[id][recordtype] = true
			
		if(jRecord > g_fTopRecord[recordtype][NUMRANKS]) 	//beat lowest rank
			g_bCheckTop[id][recordtype] = true	
	}
}

//Validate our checks
Validate_AirChecks(id)
{
	for( new x = 0 ; x < NUM_AIR_RECORDS ; x++ ) 
	{
		if(g_bCheckPersonal[id][AIR_RECORDS[x]])
			Set_PersonalRecord(id, AIR_RECORDS[x])
			
		if(g_bCheckTop[id][AIR_RECORDS[x]])
			Check_TopRecord(id, AIR_RECORDS[x], 0)
	}
}

Validate_OtherChecks(id) 
{
	for( new x = 0 ; x < NUM_ANYTIME_RECORDS ; x++ ) 
	{
		if(g_bCheckPersonal[id][ANYTIME_RECORDS[x]])
			Set_PersonalRecord(id, ANYTIME_RECORDS[x])
			
		if(g_bCheckTop[id][ANYTIME_RECORDS[x]])
			Check_TopRecord(id, ANYTIME_RECORDS[x], 0)
	}
}

//Update their Personal Record
Set_PersonalRecord(id, recordtype) {
	
	new Float:jRecord = g_fPersonalOld[id][recordtype]
	format(g_RecordText[id][recordtype], MAX_TEXT_LENGTH, "^n%s -- %.2f %s", TITLES[recordtype], jRecord, TYPES[recordtype])
	
	g_fPersonalRecord[id][recordtype] = jRecord
	g_bCheckPersonal[id][recordtype] = false
}

Check_TopRecord(id, recordtype, iftype) 
{
	new hasrank, authid[32], x
	get_user_authid(id,authid,31)
	
	//Do we have a record in the list?
	for( x = 1 ; x <= NUMRANKS ; x++ )
		if(equali(g_TopRecordSteamId[recordtype][x][0],authid)) {
			hasrank = x
			break
		}
			
	new endrank = ( (hasrank > 0) ? hasrank : NUMRANKS )
	new Float:jRecord = g_fPersonalOld[id][recordtype]
	
	//Difference is the greaterthan / lesserthan signs
	switch(iftype) {
		case 0: {
			for( x = 1 ; x <= endrank ; x++ )
				if(jRecord > g_fTopRecord[recordtype][x]) {
					Set_TopRecord(id, authid, recordtype, x, jRecord, hasrank)
					break
				}
		}
		case 1: {
			for( x = 1 ; x <= endrank ; x++ ) 
				if(jRecord < g_fTopRecord[recordtype][x]) {
					Set_TopRecord(id, authid, recordtype, x, jRecord, hasrank)
					break
				}
		}
	}
	g_bCheckTop[id][recordtype] = false
}
//We don't allow double records, only update users record.
Set_TopRecord(id, authid[], recordtype, rank, Float:jRecord, hasrank) 
{ 
	
	new name[MAX_TEXT_LENGTH+1]
	get_user_name(id,name,MAX_TEXT_LENGTH)
	
	replace(name,MAX_TEXT_LENGTH,"<","(")	//These symbols screw up html,
	replace(name,MAX_TEXT_LENGTH,">",")")	//if user has them in their name.
	replace(name,MAX_TEXT_LENGTH,"&","&amp;") 
	
	new temp, x
	
	if(hasrank) 	//Update according to their current saved rank.
	{	
		for( x = hasrank; x >= rank ; x-- ) 
			if(x == rank) 
				saveRecord(authid, name, rank, recordtype, jRecord)
			else {
				temp = x-1 //temp rank (helps amxx run faster)
				saveRecord(g_TopRecordSteamId[recordtype][temp], g_TopRecordName[recordtype][temp], x, recordtype, g_fTopRecord[recordtype][temp])
			}
	}
	else 		//No saved rank, cascade ranks down from current
	{
		for( x = NUMRANKS; x >= rank ; x-- ) 
			if(x == rank) 
				saveRecord(authid, name, x, recordtype, jRecord)
			else {
				temp = x-1 //temp rank (helps amxx run faster)
				saveRecord(g_TopRecordSteamId[recordtype][temp], g_TopRecordName[recordtype][temp], x, recordtype, g_fTopRecord[recordtype][temp])
			}
	}
}

/*====================================================================================================
 [Touched]

 Purpose:	These functions are for certain events for when player touches what we specified.
			Mostly record checks.

 Comment:	$$

====================================================================================================*/
public Touch_Teleport(teleport, id) {
	if(!g_EndRound && g_bIsSurf) {
		
		g_bRespawning[id] = true
		
		//If player touches teleport, check their records immediately if they have one
		Validate_AirChecks(id)
		
		//same as above
		Validate_OtherChecks(id)
		
		#if defined COMMENTATOR
			new rand = random_num(0,3)
			client_print(id, print_chat, "%s", GOOD_COMMENT[rand])
		#endif
	}
}

//stop players stucking inside each other, still allow semi block
public Touch_Player(id, otherPlayer) 
{
	if(!g_bModifyMode[id] && !g_bModifyMode[otherPlayer] && g_bIsSurf)  
	{
		
		clearAirRecords(id) //Exploit Fix.
		
		if(g_NoClip) {
			if(entity_get_int(id, EV_INT_solid) != SOLID_NOT)
				entity_set_int(id, EV_INT_solid, SOLID_NOT)
			if(entity_get_int(otherPlayer, EV_INT_solid) != SOLID_NOT)
				entity_set_int(otherPlayer, EV_INT_solid, SOLID_NOT)
				
			//Allow players to jump/stack on each other	
			new buttonPressed = entity_get_int(id, EV_INT_button)
			if( (buttonPressed & IN_JUMP) ) {
				new Float:jVel[3]
				entity_get_vector(id,EV_VEC_velocity,jVel)
				jVel[2] = 375.0
				entity_set_vector(id,EV_VEC_velocity,jVel)
			}
		}
	}
}

//touched func_wall/worldspawn/func_water
public Touch_World(id, world) {
	if(!g_EndRound && g_bIsSurf) 
	{
		if(!g_bRespawning[id])
			Validate_AirChecks(id)
			
		clearAirRecords(id)
	}
	return PLUGIN_HANDLED
}

//respawn player, compensate for if olympics is turned off
public Touch_TriggerHurt(hurt, id) 
{
	if(is_user_alive(id)) 
	{
		new bool:check
		for(new x=0;x<g_TrigHurtHealTotal;x++) //Allow hurts to heal.
			if(g_TriggerHurtHealers[x] == hurt)
				check = true

		if(g_bIsSurf) 
		{
			if(!g_bModifyMode[id] && !check) 
			{
				g_bRespawning[id] = true
				
				//Only need OtherChecks here
				Validate_OtherChecks(id)
				
				
				AutoRespawn(id)
				
				#if defined COMMENTATOR
					new rand = random_num(0,3)
					client_print(id, print_chat, "%s", BAD_COMMENT[rand])
				#endif
			}
		}
		else
			if(!check)
				user_kill(id)	//since we removed dmg
	}
}

//Player touched EndZone entity
public Touch_EndZone(ezone, id) {
	if(!g_EndRound && !g_bModifyMode[id] && !g_bFinished[id] && g_bIsSurf) {
		g_bFinished[id] = true
		
		Validate_OtherChecks(id)
		
		new Float:tempVel[3], Float:tempOrig[3]
		entity_get_vector(ezone, EV_VEC_origin, tempOrig)
		entity_set_origin(id, tempOrig)
		entity_set_vector(id, EV_VEC_velocity, tempVel)
		
		new Float:completion = Check_Completion(id)
		new menuName[64]
		format(menuName, 63, "Map Completed in %.2f seconds!", completion)
		menu_finished[id] = menu_create(menuName, "finished_handler")
		menu_additem(menu_finished[id], "Start Over", "1", 0)
		menu_additem(menu_finished[id], "Keep Playing", "2", 0)
		menu_setprop(menu_finished[id], MPROP_EXIT, MEXIT_NEVER);
		menu_display(id, menu_finished[id], 0)
		
		showRecords(id)
	}
}
//This goes connected with touchedEndZone
public finished_handler(id, menu, item) {
	if(is_user_connected(id)) {
		new cmd[6], iName[64];
		new access, callback;
		menu_item_getinfo(menu, item, access, cmd,5, iName, 63, callback); 
		
		switch(str_to_num(cmd)) {
			case 1: {
				AutoRespawn(id)
			}
			case 2: {
				if(g_bFinished[id])
					client_print(id, print_chat, "[Surf Olympics] - Type /respawn when your ready to start again.")
			}	
		}
	}
}

//NEVER CHANGE!!
on_ground(id, flags) {	
	new movetype = entity_get_int(id,EV_INT_movetype)
	if( (movetype == 5) || (flags & FL_ONGROUND) || (flags & FL_PARTIALGROUND) || 
		(flags & FL_INWATER) || (flags & FL_CONVEYOR) || (flags & FL_FLOAT) )
			return 1
	return 0
}

/*====================================================================================================
 [Clean Up]

 Purpose:	Clean up all the crap so player doesn't exploit by accident.

 Comment:	If you add a custom record, clean up your variables here.

====================================================================================================*/

//CLEANUP EVERYTHING
public cleanup(id) {
	for( new x = 1 ; x <= NUMRANKS ; x++ ) {
		g_bCheckPersonal[id][x] = false
		g_bCheckTop[id][x] = false
	}
	
	for( new x = 2 ; x <= NUMRECORDS ; x++ ) {
		g_fPersonalOld[id][x] = 0.0	
	}
	
	if(g_bFinished[id]) 
	{
		g_bFinished[id] = false
		
		new men, newmenu
		player_menu_info(id, men, newmenu)
		if(newmenu == menu_finished[id])	//close our finished menu
			client_cmd(id,"slot2")
	}
	//CORE variables
	g_fTimeElapsed[id] = 0.0
	g_bPlaying[id] = false
	g_bPlaystarted[id] = false
	
	//make AIR RECORD vars equal less than 0 to your Checks
	g_fHeight[id] = 9999.0
	g_bDistCheck[id] = true
	g_fIsInAir[id] = 999999.0
}

//Clear AIR RECORDs
public clearAirRecords(id) {
	
	for( new x = 0 ; x < NUM_AIR_RECORDS ; x++ )
		g_fPersonalOld[id][AIR_RECORDS[x]] = 0.0
	
	//Reset your AIR record variables here.
	g_fIsInAir[id] = get_gametime()
	g_fHeight[id] = g_fvecEndOrigin[id][2]
	g_bDistCheck[id] = true
}

/*====================================================================================================
 [Misc.]

 Purpose:	Help Clean up when round ends/player dies, or manually respawns. 

 Comment:	$$

====================================================================================================*/
//Client Command respawn
public cmdRespawn(id) {
	new CsTeams:team = cs_get_user_team(id)
	if(team == CS_TEAM_T || team == CS_TEAM_CT) {
		cs_user_spawn(id)
		cleanup(id)
	}
	return PLUGIN_HANDLED
}

// dead & trigger_hurt respawn
public AutoRespawn(id)	 {
	if(is_user_connected(id)) {
		cs_user_spawn(id)
		cleanup(id)
		if(g_bIsDead[id])
			g_bIsDead[id] = false
	}
}

public Event_ResetHUD(id) {
	if(g_bIsSurf) 
	{
		if(get_cvar_num("surf_godmode"))
			entity_set_float(id,EV_FL_takedamage,0.0)	
		else
			entity_set_float(id,EV_FL_takedamage,1.0)
			
		//make sure we have a record before showing
		if(is_user_connected(id) && (g_fPersonalRecord[id][SPEED] || g_fPersonalRecord[id][DISTANCE])) 
			showRecords(id)
	}
}

//clean up when round ends
public Event_EndRound() {
	if(g_bIsSurf) {
		for(new x=1;x<=g_Maxplayers;x++)
			if(is_user_connected(x))
				cleanup(x)
		g_EndRound = true
	}
}

//clean up when round starts (safety)
public Event_StartRound() {
	if(g_bIsSurf) {
		server_print("=======|||||||||| STARTING ROUND |||||||||=========")
		for(new x=1;x<=g_Maxplayers;x++)
			if(is_user_connected(x)) {
				if(g_bModifyMode[x]) {
					menu_display(x, menu_modify[x], 0)
					client_cmd(x,"slot7")
				}
				cleanup(x)
			}
		g_EndRound = false
	}
}

public client_disconnect(id) {
	if(g_bIsSurf) {
		cleanup(id)
		g_bIsDead[id] = false
		g_bModifyMode[id] = false
		g_IsFlying[id] = false
		
		for( new x = 2 ; x <= NUMRECORDS ; x++ )
			g_fPersonalRecord[id][x] = 0.0
			
		for( new x = 1 ; x <= NUMRECORDS ; x++ ) {
			g_StatText[id][x][0] = 0
			g_RecordText[id][x][0] = 0
		}
		
		g_fPersonalRecord[id][COMPLETION] = 9999.9
		
	}
}

/*====================================================================================================
 [Surf Help]

 Purpose:	Help System for everything Surf and Plugin.

 Comment:	$$

====================================================================================================*/
/*public client_connect(id)
	if(g_bIsSurf)
		set_user_info(id,"_vgui_menus","0")*/
		
public client_putinserver(id)
	if(g_bIsSurf)
		set_task(30.0,"surfHelp",id)

public surfHelp(id) {
	new name[32]
	get_user_name(id,name,31)
	client_print(id,print_chat,"=======================================================")
	client_print(id,print_chat,"[Surf Olympics] - Hello %s, you entered the Surf Olympics, do your best!",name)
	client_print(id,print_chat,"[Surf Olympics] - Type /help for all your Surf Olympic questions.")
}

public handle_say(id) {
	new said[192], help[6]
	read_args(said,192)
	remove_quotes(said)
	strcat(help,said,5)
	if( (containi(help, "help") != -1) )
		menu_display(id, menu_help, 0)
	return PLUGIN_CONTINUE
}

public Help_Handler(id, menu, item) {
	if(is_user_connected(id) && g_bIsSurf) {

		if(item == MENU_EXIT)
			return PLUGIN_HANDLED

		new cmd[6], iName[64];
		new access, callback;
		menu_item_getinfo(menu, item, access, cmd,5, iName, 63, callback); 

		switch(str_to_num(cmd)) {
			case 1:
			{
				new help_title[64], msg[2047]
				format(help_title,63,"Surfing Help")
				add(msg,2046,"<body bgcolor=#000000><font color=#FFB000><br>")
				add(msg,2046,"<center><h2>Surfing Help</h2><br><table><tr><td><p><b><font color=#FFB000>")
				add(msg,2046,"To surf, strafe toward the wave.  Never use the forward / back key!!<br>")
				add(msg,2046,"For more momentum practice strafing away from the wave, and back onto it.<br>")
				add(msg,2046,"This won't work on all waves, so learn which waves you can use it on. <br>")
				add(msg,2046,"Maps with water surfaces, allow you to skee across them, while holding <i>duck+jump</i> key together.")
				add(msg,2046,"</b><br></td></tr></table></center>")
				show_motd(id,msg,help_title)
			}
			case 2:
			{
				client_print(id,print_chat,"[Surf_Olympics] - To view Top 3 Records, type /top3")
			}
			case 3:
			{
				client_print(id,print_chat,"[Surf_Olympics] - Type /respawn to restart timer or fully respawn.")
			}
			case 4:
			{
				new help_title[64], msg[2047]
				format(help_title,63,"Surf Olympics Rules")
				add(msg,2046,"<body bgcolor=#000000><font color=#FFB000><br>")
				add(msg,2046,"<center><h2><u>Surf Olympics Rules</u></h2><br><table><tr><td><p><b><font color=#FFB000>")
				add(msg,2046,"1. To score a hang time, distance, or height record, you cannot get respawned during the jump.<br>")
				add(msg,2046,"2. You can score a speed record when you teleport or get respawned.<br>")
				add(msg,2046,"3. To complete the map, you must touch the lightning bolt that has a pulsating wave attached to it. <br>")
				add(msg,2046,"4. Your personal records will be erased when you leave server. <br>")
				add(msg,2046,"5. If you beat a Top 3 record, you may view your name by typing /top3 in chat.")
				add(msg,2046,"</b><br></td></tr></table></center>")
				show_motd(id,msg,help_title)
			}
			case 5:
			{
				client_print(id,print_chat,"[Surf_Olympics] - surf_olympics v%s By: %s",VERSION,AUTHOR)
				client_print(id,print_chat,"[Surf_Olympics] - Plugin Available @ http://www.amxmodx.org/forums/viewtopic.php?p=223786")
			}
		}
		menu_display(id, menu_help, 0)
	}
	return PLUGIN_HANDLED
}
/*====================================================================================================
 [Team Control]

 Purpose:	Force Players into specified team by CVAR surf_teamstack

 Comment:	$$

====================================================================================================*/
public team_select(id, key)
{
	if(!g_bBothTeamsActive && g_bIsSurf) {
		new teamstack = get_cvar_num("surf_teamstack")
		if(teamstack == 1 || teamstack == 2) 
		{
			if(key != 5 && key != teamstack-1)
			{
				new message[64]
				switch(teamstack) {
					case 1: format(message, 63, "You must join Terrorist team!")
					case 2: format(message, 63, "You must join Counter-Terrorist team!")
				}

				message_begin(MSG_ONE_UNRELIABLE, get_user_msgid("StatusText"), {0, 0, 0}, id);
				write_byte(0);
				write_string(message);
				message_end();

				engclient_cmd(id,"chooseteam")

				return PLUGIN_HANDLED
			}
		}
	}
	return PLUGIN_CONTINUE
}

check_team(id,team) {
	new teamstack = get_cvar_num("surf_teamstack")
	//if user not in correct team, fix them
	if(teamstack == 1 || teamstack == 2) {
		if(team != teamstack) {
			new randModel
			switch(teamstack) {
				case 1: randModel = random_num(1,4)
				case 2: randModel = random_num(1,5)
			}
			select_model(id,teamstack,randModel)
		}
	}
}

public cmdSpectate(id)
	select_model(id,3, 0)

//random model selecting for teamstack
select_model(id,team, model) {
	switch(team) {
		case 1: {
			switch(model) {
				case 1: cs_set_user_team(id, CS_TEAM_T, CS_T_TERROR)
				case 2: cs_set_user_team(id, CS_TEAM_T, CS_T_LEET)
				case 3:	cs_set_user_team(id, CS_TEAM_T, CS_T_ARCTIC)
				case 4: cs_set_user_team(id, CS_TEAM_T, CS_T_GUERILLA)
			}
		}
		case 2: {
			switch(model) {
				case 1: cs_set_user_team(id, CS_TEAM_CT, CS_CT_URBAN)
				case 2: cs_set_user_team(id, CS_TEAM_CT, CS_CT_GSG9)
				case 3: cs_set_user_team(id, CS_TEAM_CT, CS_CT_SAS)
				case 4: cs_set_user_team(id, CS_TEAM_CT, CS_CT_GIGN)
				case 5: cs_set_user_team(id, CS_TEAM_CT, CS_CT_VIP) //my lil secret
			}
		}
		case 3: {
			cs_set_user_team(id, CS_TEAM_SPECTATOR, CS_DONTCHANGE)
			if(is_user_alive(id))
				user_kill(id)
		}
	}
}

public client_command(id) {
	if(g_bIsSurf && get_cvar_num("surf_teamstack") > 0) {
		new arg[64]
		read_argv( 0, arg , 63 )
		if( equal("chooseteam",arg) || equal("jointeam",arg) ) {
			return PLUGIN_HANDLED
		}
	}
	return PLUGIN_CONTINUE
}
/*====================================================================================================
 [Remove Weapons]

 Purpose:	Remove the weapon listed in game_player_equip entity, (since this will be the most dropped).

 Comment:	Thanks to BAILOPAN on this safe weapon removal method.

====================================================================================================*/
public Event_DeathMsg() 
{
	if(g_bIsSurf) {
		new player = read_data(2)
		if(player) {
			new wps[32], num, i, Drop[1]
			get_user_weapons(player, wps, num)		//catch every dropped weapon!
			
			for (i=0; i<num; i++) {
				Drop[0] = wps[i]
				set_task(0.2,"remove_weapon", 0, Drop, 1)
			}
		}
	}
}

public remove_weapon(data[]) 
{
	new wp = data[0]
	new weapbox, model[64], left[32], right[32]
	
	while((weapbox = find_ent_by_class(weapbox,"weaponbox")) != 0) 
	{
		entity_get_string(weapbox,EV_SZ_model,model,63)
		for(new x = 0; x < g_TotalWeap ; x++) 
		{
			strtok(g_StartWeap[x], left, 31, right, 32, '_')
			if( containi(model, right) != -1 )
				remove_weapon_final(wp, weapbox)
		}
	}
	
}

remove_weapon_final(wp, weapbox) {
	new wEnt, wfEnt, name[24]
	new woEnt
	
	remove_entity(weapbox)
	get_weaponname(wp, name, 24)
	wEnt = find_ent_by_class(-1, name)
	while (wEnt > 0) {
		wfEnt = find_ent_by_class(wEnt, name)
		woEnt = entity_get_edict(wEnt, EV_ENT_owner)
		if (woEnt > 32 && woEnt == weapbox)
			remove_entity(wEnt)
			
		wEnt = wfEnt
	}
}
/*====================================================================================================
 [nVault Data Handling]

 Purpose:	Saves/Loads EndZone Location origin to file.  Also save record, saves to vault and cascades
			records down a rank.  LoadRecord is called once at map load, to load records saved in vault.
			RecordLookup is called when player types /top3 and formats it to fit on MOTD window.

 Comment:	$$

====================================================================================================*/
SaveEndZoneLocation(Float:ezOrig[3]) {

	Vault_EndZone = nvault_open( ENDZONE_VAULT )
	if(Vault_EndZone == INVALID_HANDLE)
       server_print("Error opening nVault file: %s",ENDZONE_VAULT)

	new key[64], update[511]

	format(key,63,"%s",g_MapName)
	format(update,510,"^"%f^" ^"%f^" ^"%f^"",ezOrig[0],ezOrig[1],ezOrig[2])

	if(ezOrig[0] != 0.0 && ezOrig[1] != 0.0 && ezOrig[2] != 0.0) {
		if(!g_EndzoneEntity)
			createEndZone()

		entity_set_origin(g_EndzoneEntity,ezOrig)
	}
	nvault_set(Vault_EndZone, key, update)	//update End Zone Location

	nvault_close(Vault_EndZone)

	for( new x = 1 ; x <= NUMRANKS ; x++ )
		saveRecord("0", "Nobody", x, COMPLETION, 9999.9)
		
	for( new x = 1 ; x <= g_Maxplayers ; x++ )
		g_fPersonalRecord[x][COMPLETION] = 9999.0	
}

LoadEndZoneLocation() {

	Vault_EndZone = nvault_open( ENDZONE_VAULT )
	if(Vault_EndZone == INVALID_HANDLE)
       server_print("Error opening nVault file: %s",ENDZONE_VAULT)

	new key[64], val[511], TimeStamp
	new endzoneOrig[3][64]

	format(key,63,"%s",g_MapName)

	//Retrieve origin from file, parse it, convert to float, and set it to endzone model.
	if( nvault_lookup(Vault_EndZone, key, val, 510, TimeStamp) ) {
		parse(val, endzoneOrig[0], 63, endzoneOrig[1], 63, endzoneOrig[2], 63)
		new Float:ezOrig[3]
		for(new x=0;x<3;x++)
			ezOrig[x] = floatstr(endzoneOrig[x])

		if(ezOrig[0] != 0 && ezOrig[1] != 0 && ezOrig[2] != 0)
			createEndZone()

		if(g_EndzoneEntity)
			entity_set_origin(g_EndzoneEntity,ezOrig)
		nvault_close(Vault_EndZone)
	}
	else
		nvault_close(Vault_EndZone)
}

saveRecord(authid[], name[], rank, recordtype, Float:record) {

	Vault = nvault_open( VAULTNAME )
	if(Vault == INVALID_HANDLE)
       server_print("Error opening nVault file: %s",VAULTNAME)
 
	new key[64], update[511]

	format(key,63,"%s %i %i",g_MapName,rank,recordtype)
	format(update,510,"^"%s^" ^"%s^" ^"%f^"", authid, name, record)

	format(g_TopRecordSteamId[recordtype][rank],MAX_TEXT_LENGTH,"%s",authid)	//steamid
	format(g_TopRecordName[recordtype][rank],MAX_TEXT_LENGTH,"%s",name)	//name

	g_fTopRecord[recordtype][rank] = record

	nvault_set(Vault, key, update)

	nvault_close(Vault)	
}

LoadRecords() {

	Vault = nvault_open( VAULTNAME )

	if(Vault == INVALID_HANDLE)
       server_print("Error opening nVault file: %s",VAULTNAME)

	new key[64], value[511], TimeStamp
	new playerinfo[3][MAX_TEXT_LENGTH+1]     // "STEAMID" "NICK" "RECORD"
	new empty[511], full[511] //full is for completion to == 9999.0

	format(full,510,"^"0^" ^"Nobody^" ^"9999.0^"")
	format(empty,510,"^"0^" ^"Nobody^" ^"0.0^"")

	for( new x = 1 ; x <= NUMRECORDS ; x++ ) {
		for( new m = 1 ; m <= NUMRANKS ; m++ )
		{
			format(key,63,"%s %i %i",g_MapName,m,x)
			if( nvault_lookup(Vault, key, value, 510, TimeStamp) ) {

				parse(value, playerinfo[0], MAX_TEXT_LENGTH, playerinfo[1], MAX_TEXT_LENGTH, playerinfo[2], MAX_TEXT_LENGTH)

				g_fTopRecord[x][m] = floatstr(playerinfo[2])
				format(g_TopRecordSteamId[x][m],MAX_TEXT_LENGTH,"%s",playerinfo[0])	//steamid
				format(g_TopRecordName[x][m],MAX_TEXT_LENGTH,"%s",playerinfo[1])	//name
			}
			else { //Fill empty slots
				if(x == COMPLETION) 
					nvault_set(Vault, key, full) //Fill in None and 9999.0
				else
					nvault_set(Vault, key, empty) //Fill in None and 0.0
				format(g_TopRecordSteamId[x][m],MAX_TEXT_LENGTH,"0")	//steamid
				format(g_TopRecordName[x][m],MAX_TEXT_LENGTH,"Nobody")	//name
			}
		}
	}
	nvault_close(Vault)	
}

public recordLookUp(id) {

	Vault = nvault_open( VAULTNAME )
    	if(Vault == INVALID_HANDLE)
			server_print("Error opening nVault file: %s",VAULTNAME)

	new key[64], value[511], TimeStamp
	new rankings[MAX_BUFFER_LENGTH+1], map[64]
	new Float:record
	new playerinfo[3][MAX_TEXT_LENGTH+1]     // "STEAMID" "NICK" "RECORD"

	new rLen = 0

	format(map,63,"Top Records: %s ",g_MapName)
	rLen += format(rankings,MAX_BUFFER_LENGTH,"<body bgcolor=#000000><font color=#FFB000><br>")

	//Write personal record statistics
	rLen += format(rankings[rLen],MAX_BUFFER_LENGTH-rLen,"<p><b>Personal Statistics</b><br>")
	for( new x = 1 ; x <= NUMRECORDS ; x++ )
	{
		if( x == COMPLETION && !g_EndzoneEntity ) continue //No EndZone, skip completions!
		rLen += format(rankings[rLen],MAX_BUFFER_LENGTH-rLen,"%s: %.2f %s<br>",TITLES[x],g_fPersonalRecord[id][x],TYPES[x])
	}
	rLen += format(rankings[rLen],MAX_BUFFER_LENGTH-rLen,"</p>")

	//Write top record statistics
	for( new x = 1 ; x <= NUMRECORDS ; x++ )
	{
		if( x == COMPLETION && !g_EndzoneEntity ) continue //No EndZone, skip completions!

		rLen += format(rankings[rLen],MAX_BUFFER_LENGTH-rLen,"<p><b>Record %s</b><br>",TITLES[x])

		for( new m = 1 ; m <= NUMRANKS ; m++ ) 
		{
			format(key,63,"%s %i %i",g_MapName,m,x)
			if( nvault_lookup(Vault, key, value, 510, TimeStamp) ) 
			{
				parse(value, playerinfo[0], MAX_TEXT_LENGTH, playerinfo[1], MAX_TEXT_LENGTH, playerinfo[2], MAX_TEXT_LENGTH)
				record = floatstr(playerinfo[2])

				rLen += format(rankings[rLen],MAX_BUFFER_LENGTH-rLen,"%i%s : %s %.2f %s<br>",m,RANKS[m],playerinfo[1],record,TYPES[x])
			}
		}
		rLen += format(rankings[rLen],MAX_BUFFER_LENGTH-rLen,"</p>")
	}
	nvault_close(Vault)	
	show_motd(id,rankings,map)
}

/*====================================================================================================
 [Keyvalue]

 Purpose: 	Since this runs before plugin_precache and plugin_init, find out if it's a surf map here.
 			Then disable all damage from trigger_hurts and func_water, disable kill buttons.
 			Also save target/targetname and id's of trigger_teleport, info_teleport_destination, and
 			info_target.
 
 Comment: 	This function runs whenever something spawns, but for these entities,
			it is used only at map load.
			
==================================================================================================*/
public pfn_keyvalue(entid) {
	if(!g_bRunOnce) {
		get_mapname(g_MapName,64)
		if(containi(g_MapName, "surf") != -1 || containi(g_MapName, "wurf") != -1)
			g_bIsSurf = true
		else
			g_bIsSurf = false
		g_bRunOnce = true
	}
	if(g_bIsSurf) {
		new classname[32], key[32], value[32]
		copy_keyvalue(classname, 31, key, 31, value, 31)

		if(equal(classname,"env_explosion"))
			remove_entity(entid)

		/***** Remove damage from entities *****/
		if(equal(classname,"func_water"))
			if(equal(key,"lip"))
				DispatchKeyValue("lip","0")

		if(equal(key, "dmg"))
			if(floatstr(value) > 0.0)	//Only cancel damage, some trigger_hurts give HP
				DispatchKeyValue("dmg","0")

		if(equal(key, "damagetype"))
			DispatchKeyValue("damagetype","0")
		/***************************************/

		/*********** trigger_hurt healers **********/
		if(equali(classname,"trigger_hurt"))
			if(equali(key,"dmg"))
				if(floatstr(value) < 0.0)
					g_TriggerHurtHealers[g_TrigHurtHealTotal++] = entid
		/*******************************************/
		
		/******* Player Equip Weapon Info ******/
		if( (equali(classname,"game_player_equip")) && (containi(key,"weapon_") != -1) && (!equali(key,"weapon_knife")) )
			format(g_StartWeap[g_TotalWeap++],63,"%s",key)
		/***************************************/
		
		/************* Player Spawn Info *******/
		if(equal(classname, "info_player_start"))
			g_InfoPlayerStart++

		if(equal(classname, "info_player_deathmatch"))
			g_InfoPlayerDeathmatch++	
		/***************************************/

		/*********** Teleport Info *************/
		if(equal(classname, "info_teleport_destination") || equal(classname, "info_target") || equal(classname, "trigger_teleport"))	
			if(equal(key, "targetname")) {	//save "targetname" to link to target and save ID
				format(g_TeleDest[g_TotalTeleDest],31,"%s",value)
				g_TeleDestId[g_TotalTeleDest++] = entid
			}
		if(equal(classname, "trigger_teleport")) {
			if(equal(key, "target")) {	//save "target" to link to targetname and save ID
				format(g_TriggerTeleport[g_TotalTeleports],31,"%s",value)
				g_TriggerTeleId[g_TotalTeleports++] = entid
			}
		}
		/***************************************/
	}
}

/*====================================================================================================
 [EndZone Tool & Other Menus Setup]

 Purpose: 	Link our target/targetnames into one array and save id's of linked trigger_teleport/destinations.
			After that, create our EndZone entity, with a bounding box.  Search if map has a saved origin
			for it and apply, if not don't create entity.  Finally create several of our menus automatically 
			based on information we have.

 Comment: 	This is done on mapload, and never again.
 
=====================================================================================================*/
LoadMenus() { 

	new targetName[100][32] //Save the target name for tele menu

	//Link teleport <-> destination
	for(new x=0;x<g_TotalTeleDest;x++)
		for(new m=0;m<g_TotalTeleports;m++)
			if(equal(g_TriggerTeleport[m], g_TeleDest[x])) {	//if target & targetname are the same, put both ID's in our array
				g_LinkedTeleAndDest[g_TotalLinked][0] = g_TriggerTeleId[m]
				g_LinkedTeleAndDest[g_TotalLinked][1] = g_TeleDestId[x]
				format(targetName[g_TotalLinked++],31,g_TeleDest[x])
			}

	for(new x=1;x<=g_Maxplayers;x++)
		g_fPersonalRecord[x][COMPLETION] = 9999.0	//Set default user completions to 9999.0

	for(new x=1;x<=NUMRANKS;x++)
		g_fTopRecord[COMPLETION][x] = 9999.0	//Set default top completions to 9999.0


	/**************** EndZone Entity Box *****************************/
	LoadEndZoneLocation()
	/*************************************************************/


	/****************** Automated Menu Creation ***********************/
	//End Zone Menu
	for(new x=1;x<g_Maxplayers;x++) {
		menu_modify[x] = menu_create("EndZone Creation Tool:", "Endzone_Handler");
		if(!g_EndzoneEntity)
			menu_additem(menu_modify[x], "Create EndZone Here", "1", ADMIN_RCON)
		else
			menu_additem(menu_modify[x], "Move EndZone Here", "1", ADMIN_RCON)
		menu_additem(menu_modify[x], "NoClip (OFF)","2", ADMIN_RCON)
		menu_additem(menu_modify[x], "Flying (OFF)","3", ADMIN_RCON)
		menu_additem(menu_modify[x], "Choose Teleport Destination", "4", ADMIN_RCON)
		menu_addblank(menu_modify[x], 5)
		menu_additem(menu_modify[x], "Go to current EndZone", "6", ADMIN_RCON)
		menu_additem(menu_modify[x], "Delete EndZone", "7", ADMIN_RCON)
		menu_addblank(menu_modify[x], 8)
		menu_setprop(menu_modify[x], MPROP_EXIT, MEXIT_ALL);
	}

	//Delete Records Menu
	new num[11]
	menu_deleterecords = menu_create("Delete Records Menu:", "DeleteRecord_Handler")
	menu_additem(menu_deleterecords, "All Records", "0", ADMIN_RCON)
	for( new x = 1 ; x <= NUMRECORDS ; x++ ) {
		format(num,10,"%i",x)
		menu_additem(menu_deleterecords, TITLES[x], num, ADMIN_RCON)
	}
	menu_addblank(menu_deleterecords, NUMRECORDS+1)
	menu_setprop(menu_deleterecords, MPROP_EXIT, MEXIT_ALL);


	//Teleport Menu
	menu_teleport = menu_create("Choose Teleport Destination:", "Teleport_Handler");
	menu_additem(menu_teleport, "Previous Location", "1")

	new menu_name[64], menu_cmd[64]
	for(new x=0;x<g_TotalLinked;x++) {
		//if duplicate move on
		if(equal(targetName[x],"@@@@@@@")) continue 

		//create menu item
		format(menu_name,63,"Tele (%s)",targetName[x])
		format(menu_cmd,63,"%i",g_LinkedTeleAndDest[x][0])
		menu_additem(menu_teleport, menu_name, menu_cmd, ADMIN_RCON);

		//delete duplicate destinations (mark w/ @@@@@@@)
		for(new m=x+1;m<g_TotalLinked;m++)
			if(equal(targetName[x], targetName[m]))
				format(targetName[m],31,"@@@@@@@")
	}
	menu_setprop(menu_teleport, MPROP_PERPAGE, 6);
	menu_setprop(menu_teleport, MPROP_EXIT, MEXIT_ALL);
	menu_setprop(menu_teleport, MPROP_NEXTNAME, "More");

	//Help Menu
	menu_help = menu_create("Help FAQ Information:", "Help_Handler");
	menu_additem(menu_help, "How to Surf?", "1", 0)
	menu_additem(menu_help, "How to view top records?","2", 0)
	menu_additem(menu_help, "Restart Completion Time or Stuck?", "3", 0)
	menu_additem(menu_help, "How do I play Surf_Olymipcs?", "4", 0)
	menu_additem(menu_help, "About plugin.", "5", 0)
	menu_addblank(menu_help, 6)
	menu_setprop(menu_help, MPROP_EXIT, MEXIT_ALL);

	menu_savecheck = menu_create("(Saving Location) Are you sure?", "Save_Handler");
	menu_additem(menu_savecheck, "YES", "1", ADMIN_RCON)
	menu_additem(menu_savecheck, "CANCEL", "5", ADMIN_RCON)
	menu_setprop(menu_savecheck, MPROP_EXIT, MEXIT_NEVER);

	menu_deletecheck = menu_create("(Deleting EndZone) Are you sure?", "Delete_Handler");
	menu_additem(menu_deletecheck, "YES", "1", ADMIN_RCON)
	menu_additem(menu_deletecheck, "CANCEL", "5", ADMIN_RCON)
	menu_setprop(menu_deletecheck, MPROP_EXIT, MEXIT_NEVER);
	/*******************************************************************/
}

/*====================================================================================================
 [Enable/Disable Surf_Olympics]

 Purpose:	Enable/Disable surf olympic plugin completely, minus /respawn, /spec, /top3 .
			COMMAND: surf_on <1|0>

 Comment:	$$

====================================================================================================*/
public cmdEnable(id,level,cid) {
	if (!cmd_access(id,level,cid,1))
		return PLUGIN_HANDLED
	new arg[32], status
	read_argv(1,arg,31)
	status = str_to_num(arg)
	if(status == 1) {
		set_cvar_num(TITLE,1)
		g_bIsSurf = true
		client_print(0,print_chat,"[Surf Olympics] Plugin is now enabled.")
		new team
		for(new id=1;id<=g_Maxplayers;id++) {
			team = get_user_team(id)
			if(is_user_connected(id) && (team == 1 || team == 2))
				AutoRespawn(id)
		}
	}
	else {
		set_cvar_num(TITLE,0)
		g_bIsSurf = false
		client_print(0,print_chat,"[Surf Olympics] Plugin is now disabled.")
	}
	return PLUGIN_HANDLED
}

/*====================================================================================================
 [Delete Record Menu]

 Purpose:	Opens a menu for deleting ALL records or by Record Type.
			COMMAND: surf_delete

 Comment:	$$

====================================================================================================*/
public cmdDeleteRecords(id, level, cid) 
{
	if( g_bIsSurf && (id > 0) && (id <= g_Maxplayers) && is_user_connected(id) && cmd_access(id,level,cid,0)) 
		menu_display(id, menu_deleterecords, 0)

	return PLUGIN_HANDLED
}

public DeleteRecord_Handler(id, menu, item) 
{
	if(is_user_connected(id)) {
		if(item == MENU_EXIT || !g_bIsSurf) {
			return PLUGIN_HANDLED
		}

		new cmd[6], iName[64];
		new access, callback;
		menu_item_getinfo(menu, item, access, cmd,5, iName, 63, callback); 

		new recordtype = str_to_num(cmd)

		new delRecord[MAX_TEXT_LENGTH+1]
		if(recordtype != 0)
			format(delRecord,MAX_TEXT_LENGTH,"(Deleting %s Records) Are you sure?",TITLES[recordtype])
		else
			format(delRecord,MAX_TEXT_LENGTH,"(Deleting ALL Records) Are you sure?")

		new menu_areyousure = menu_create(delRecord, "DelCheck_Handler")
		menu_additem(menu_areyousure, "YES", cmd, ADMIN_RCON)
		menu_additem(menu_areyousure, "CANCEL", "500", ADMIN_RCON)
		menu_setprop(menu_areyousure, MPROP_EXIT, MEXIT_NEVER);

		menu_display(id, menu_areyousure, 0)
	}
	return PLUGIN_HANDLED
}

public DelCheck_Handler(id, menu, item) 
{
	if(is_user_connected(id)) 
	{
		new cmd[6], iName[64];
		new access, callback;
		menu_item_getinfo(menu, item, access, cmd,5, iName, 63, callback); 

		new recordtype = str_to_num(cmd)
		new Float:record

		if(recordtype == 0) //All Records
		{
			for( new m = 1 ; m <= NUMRECORDS ; m++ ) 
			{
				if(m == COMPLETION)
					record = 9999.9
				else
					record = 0.0

				for(new x=1;x<=NUMRANKS;x++)
					saveRecord("0", "Nobody", x, m, record)
			}
		}
		else if(recordtype != 500) //Single Record Type
		{
			if(recordtype == COMPLETION)
				record = 9999.9

			for( new x = 1 ; x <= NUMRANKS ; x++ )
				saveRecord("0", "Nobody", x, recordtype, record)
		}
	}
}

/*====================================================================================================
 [EndZone Creation Tool]

 Purpose:	surf_endzone admin command.  This handles all the EndZone Tool features.
			COMMAND: surf_endzone

 Comment:	I tried making it flexible for the average user.  Even allows some cool combos.

====================================================================================================*/
public cmdEZModify(id,level,cid) {
	if(!g_bIsSurf) {
		client_print(id,print_chat,"[Surf Olympics] ERROR: Surf Olympics must be activated to use this tool.")
		return PLUGIN_HANDLED	
	}
	if(!id) {
		server_print("[Surf Olympics] ERROR: surf_endzone is a command for ingame use only.")
		return PLUGIN_HANDLED
	}

	new CsTeams:team = cs_get_user_team(id)//get_user_team(id)
	if (!cmd_access(id,level,cid,0) || g_EndRound || !is_user_alive(id) || (team != CS_TEAM_T && team != CS_TEAM_CT))
		return PLUGIN_HANDLED

	g_bModifyMode[id] = true
	entity_set_float(id,EV_FL_takedamage,0.0)
	if(!g_EndzoneEntity) {
		menu_item_setname(menu_modify[id],5, "(NULL) Delete EndZone")
		menu_item_setname(menu_modify[id],0, "Create EndZone Here")
	}
	else {
		menu_item_setname(menu_modify[id],5, "Delete EndZone")
		menu_item_setname(menu_modify[id],0, "Move EndZone Here")
	}
	menu_item_setname(menu_modify[id],1, "NoClip (OFF)")
	menu_item_setname(menu_modify[id], 2, "Flying (OFF)")
	menu_display(id, menu_modify[id], 0)
	return PLUGIN_HANDLED
}

public Endzone_Handler(id, menu, item) {
	if(is_user_connected(id)) {
		if(item == MENU_EXIT || !g_bIsSurf) {
			g_IsFlying[id] = false
			g_bModifyMode[id] = false
			AutoRespawn(id)
			return PLUGIN_HANDLED
		}
		switch(item) {
			case 0: //save loc to file
			{
				menu_display(id, menu_savecheck, 0)
				return PLUGIN_HANDLED
			}
			case 1: //noclip on/off (cancel out flying)
			{
				new movetype = entity_get_int(id, EV_INT_movetype)
				switch(movetype) {
					case MOVETYPE_NOCLIP: {
						entity_set_int(id, EV_INT_movetype, MOVETYPE_WALK)
						menu_item_setname(menu, item, "NoClip (OFF)")
					}
					case MOVETYPE_WALK: {
						entity_set_int(id, EV_INT_movetype, MOVETYPE_NOCLIP)
						
						menu_item_setname(menu, item, "NoClip (ON)")
						menu_item_setname(menu, item+1, "Flying (OFF)")
						g_IsFlying[id] = false
					}	
				}
			}
			case 2: //flying on/off (cancel out noclip)
			{
				if(!g_IsFlying[id]) {
					g_IsFlying[id] = true
					menu_item_setname(menu, item-1, "NoClip (OFF)")
					menu_item_setname(menu, item, "Flying (ON)")
					entity_set_int(id, EV_INT_movetype, MOVETYPE_WALK)
				}
				else {
					g_IsFlying[id] = false
					menu_item_setname(menu, item, "Flying (OFF)")
				}
			}
			case 3: //teleport menu
			{
				menu_display(id, menu_teleport, 0)
				return PLUGIN_HANDLED
			}
			case 4: //go to endzone location
			{
				if(!g_EndzoneEntity)
					client_print(id,print_chat,"[Surf Olympics] - There is no EndZone created yet!")
				else {
					new Float:ezEntOrig[3]
					entity_get_vector(g_EndzoneEntity,EV_VEC_origin,ezEntOrig)
					entity_set_origin(id,ezEntOrig)	
					new Float:temp_vel[3]
					entity_set_vector(id,EV_VEC_velocity,temp_vel)
				}
			}
			case 5: 
			{
				if(!g_EndzoneEntity)
					client_print(id,print_chat,"[Surf Olympics] - There is no EndZone to delete!")
				else {
					menu_display(id, menu_deletecheck, 0)
					return PLUGIN_HANDLED
				}
			}
		}
		if(item != MENU_EXIT && item != MENU_BACK && item != MENU_MORE)
			menu_display(id, menu_modify[id], 0)
	}
	return PLUGIN_HANDLED
}

public Delete_Handler(id, menu, item) {
	if(is_user_connected(id)) {
		if(item == 0 )
		{
			remove_entity(g_EndzoneEntity)
			g_EndzoneEntity = 0
			new Float:nullOrig[3]
			SaveEndZoneLocation(nullOrig)
			menu_item_setname(menu_modify[id],5, "(NULL) Delete EndZone")
			menu_item_setname(menu_modify[id],0, "Create EndZone Here")
		}
		menu_display(id,menu_modify[id], 0)
	}
	return PLUGIN_HANDLED
}

public Save_Handler(id, menu, item) {
	if(is_user_connected(id)) {
		if(item == 0)
		{
			new Float:myorig[3]
			entity_get_vector(id,EV_VEC_origin,myorig)
			menu_item_setname(menu_modify[id],5, "Delete EndZone")
			menu_item_setname(menu_modify[id],0, "Move EndZone Here")
			SaveEndZoneLocation(myorig)
		}
		menu_display(id,menu_modify[id], 0)
	}
	return PLUGIN_HANDLED
}

public Teleport_Handler(id, menu, item) {
	if(is_user_connected(id)) {
		if(item == MENU_EXIT) {
			menu_display(id, menu_modify[id], 0)
			return PLUGIN_HANDLED	
		}
		new cmd[6], iName[64];
		new access, callback;
		menu_item_getinfo(menu, item, access, cmd,5, iName, 63, callback); 

		//If user teleports by accident, this allows them to return to their location.
		if(item > -1) {
			if(str_to_num(cmd) == 1) {
				if(g_fvecPrevOrigin[id][0] == 0.0 && g_fvecPrevOrigin[id][1] == 0.0 && g_fvecPrevOrigin[id][2] == 0.0) {
					menu_display(id, menu_modify[id], 0)
					return PLUGIN_HANDLED
				}
				//setting origin doesn't remove users velocity, so do it for them.
				new Float:temp_vel[3]
				entity_set_vector(id,EV_VEC_velocity,temp_vel)
				entity_set_origin(id,g_fvecPrevOrigin[id])
				menu_display(id, menu_modify[id], 0)
				return PLUGIN_HANDLED
			}

			new teleport_id = str_to_num(cmd)

			entity_get_vector(id,EV_VEC_origin,g_fvecPrevOrigin[id]) //Save location to go back (Previous Location)

			fake_touch(teleport_id,id)	//fake touch chosen teleport

			menu_display(id, menu_modify[id], 0)
		}
	}
	return PLUGIN_HANDLED
}

/*====================================================================================================
 [Fly Mode]

 Purpose: 	The ability to fly allows the ADMIN to create EndZone locations much faster and easier.

 Comment: 	This was created by Gorlag/Batman.  FULL CREDIT to him for this Flying mode.

=====================================================================================================*/
public client_PreThink(id)
{
	if( g_bIsSurf && g_IsFlying[id] )
		define_flyMovements(id)
}

public define_flyMovements(id)
{
	new maxSpeed = get_cvar_num("surf_flyspeed")
	new Float:fVelocity[3], Float:v_angles[3]
	new flag = entity_get_int(id, EV_INT_flags)
	new buttonPressed = entity_get_int(id, EV_INT_button)
	if(flag & FL_ONGROUND){
		if(buttonPressed & IN_JUMP){
			entity_get_vector(id, EV_VEC_velocity, fVelocity)
			fVelocity[2] += 8000.0
			entity_set_vector(id, EV_VEC_velocity, fVelocity)
		}
	}
	if(!(flag & FL_ONGROUND)) {
		if((buttonPressed & IN_FORWARD) && !(buttonPressed & IN_BACK) && !(buttonPressed & IN_MOVELEFT) && !(buttonPressed & IN_MOVERIGHT)){
			velocity_by_aim(id, maxSpeed, fVelocity)
			entity_set_vector(id, EV_VEC_velocity, fVelocity)
		}
		if((buttonPressed & IN_BACK) && !(buttonPressed & IN_FORWARD) && !(buttonPressed & IN_MOVELEFT) && !(buttonPressed & IN_MOVERIGHT)){
			velocity_by_aim(id, maxSpeed, fVelocity)
			fVelocity[0] -= fVelocity[0]*2.0
			fVelocity[1] -= fVelocity[1]*2.0
			fVelocity[2] -= fVelocity[2]*2.0
			entity_set_vector(id, EV_VEC_velocity, fVelocity)
		}
		if((buttonPressed & IN_MOVELEFT) && !(buttonPressed & IN_FORWARD) && !(buttonPressed & IN_MOVERIGHT) && !(buttonPressed & IN_BACK)){
			entity_get_vector(id, EV_VEC_v_angle, v_angles)
			v_angles[1] += 90.0
			fVelocity[0] = floatcos(v_angles[1], degrees) * maxSpeed
			fVelocity[1] = floatsin(v_angles[1], degrees) * maxSpeed
			fVelocity[2] = 0.0
			entity_set_vector(id, EV_VEC_velocity, fVelocity)
		}
		if((buttonPressed & IN_MOVERIGHT) && !(buttonPressed & IN_FORWARD) && !(buttonPressed & IN_BACK) && !(buttonPressed & IN_MOVELEFT)){
			entity_get_vector(id, EV_VEC_v_angle, v_angles)
			v_angles[1] += 270.0
			fVelocity[0] = floatcos(v_angles[1], degrees) * maxSpeed
			fVelocity[1] = floatsin(v_angles[1], degrees) * maxSpeed
			fVelocity[2] = 0.0
			entity_set_vector(id, EV_VEC_velocity, fVelocity)
		}
		if((buttonPressed & IN_FORWARD) && (buttonPressed & IN_MOVELEFT) && !(buttonPressed & IN_MOVERIGHT) && !(buttonPressed & IN_BACK)){
			entity_get_vector(id, EV_VEC_v_angle, v_angles)
			v_angles[1] += 45.0
			fVelocity[0] = floatcos(v_angles[1], degrees) * maxSpeed
			fVelocity[1] = floatsin(v_angles[1], degrees) * maxSpeed
			fVelocity[2] -= floatsin(-v_angles[0], degrees) * maxSpeed
			entity_set_vector(id, EV_VEC_velocity, fVelocity)
		}
		if((buttonPressed & IN_FORWARD) && (buttonPressed & IN_MOVERIGHT) && !(buttonPressed & IN_MOVELEFT) && !(buttonPressed & IN_BACK)){
			entity_get_vector(id, EV_VEC_v_angle, v_angles)
			v_angles[1] += 135.0
			fVelocity[0] -= floatcos(v_angles[1], degrees) * maxSpeed
			fVelocity[1] -= floatsin(v_angles[1], degrees) * maxSpeed
			fVelocity[2] -= floatsin(-v_angles[0], degrees) * maxSpeed
			entity_set_vector(id, EV_VEC_velocity, fVelocity)
		}
		if((buttonPressed & IN_BACK) && (buttonPressed & IN_MOVELEFT) && !(buttonPressed & IN_MOVERIGHT) && !(buttonPressed & IN_FORWARD)){
			entity_get_vector(id, EV_VEC_v_angle, v_angles)
			v_angles[1] += 135.0
			fVelocity[0] = floatcos(v_angles[1], degrees) * maxSpeed
			fVelocity[1] = floatsin(v_angles[1], degrees) * maxSpeed
			fVelocity[2] = floatsin(-v_angles[0], degrees) * maxSpeed
			entity_set_vector(id, EV_VEC_velocity, fVelocity)
		}
		if((buttonPressed & IN_BACK) && (buttonPressed & IN_MOVERIGHT) && !(buttonPressed & IN_MOVELEFT) && !(buttonPressed & IN_FORWARD)){
			entity_get_vector(id, EV_VEC_v_angle, v_angles)
			v_angles[1] += 45.0
			fVelocity[0] -= floatcos(v_angles[1], degrees) * maxSpeed
			fVelocity[1] -= floatsin(v_angles[1], degrees) * maxSpeed
			fVelocity[2] = floatsin(-v_angles[0], degrees) * maxSpeed
			entity_set_vector(id, EV_VEC_velocity, fVelocity)
		}
		if(!(buttonPressed & IN_BACK) && !(buttonPressed & IN_MOVERIGHT) && !(buttonPressed & IN_MOVELEFT) && !(buttonPressed & IN_FORWARD)){
			fVelocity[0] = 0.0
			fVelocity[1] = 0.0
			fVelocity[2] = 1.0
			entity_set_vector(id, EV_VEC_velocity, fVelocity)
		}
	}
}

/*====================================================================================================
 [Create EndZone Entity]

 Purpose: 	Create an EndZone Entity with a hitbox.

 Comment: 	To make a hitbox the entity requires a model.  So I gave it one and made its 
 			visibility zero.

=====================================================================================================*/
createEndZone() {
	g_EndzoneEntity = create_entity("info_target")
	if (g_EndzoneEntity) {

		entity_set_string(g_EndzoneEntity,EV_SZ_classname,"EndZone")
		entity_set_model(g_EndzoneEntity, ENDZONE_MODEL)
		set_pev(g_EndzoneEntity,pev_solid,SOLID_TRIGGER)
		set_pev(g_EndzoneEntity,pev_movetype,MOVETYPE_NONE)

		new Float:MinBox[3]
		new Float:MaxBox[3]
		MinBox[0] = -25.0
		MinBox[1] = -25.0
		MinBox[2] = -36.0
		MaxBox[0] = 25.0
		MaxBox[1] = 25.0
		MaxBox[2] = 36.0

		entity_set_vector(g_EndzoneEntity, EV_VEC_mins, MinBox)
		entity_set_vector(g_EndzoneEntity, EV_VEC_maxs, MaxBox)

		set_entity_visibility(g_EndzoneEntity, 0)

		//Use this entity's think to show the special effects.
		entity_set_float(g_EndzoneEntity, EV_FL_nextthink, halflife_time() + PULSE_FREQUENCY)

	}
}

/*====================================================================================================
 [Special Effects]

 Purpose: 	Create Special Effect every PULSE_FREQUENCY seconds

 Comment: 	Message is BROADCAST meaning it sends the message to player without waiting for approval
			that they received it.

=====================================================================================================*/
public setEffects(effectID)
{
	if(g_bIsSurf) {
		new Float:effectOrig[3], iEffectOrig[3]
		entity_get_vector(effectID,EV_VEC_origin,effectOrig)

		for(new x=0;x<3;x++)
			iEffectOrig[x] = floatround(effectOrig[x])

		specialFX(iEffectOrig)

	}
	if(g_EndzoneEntity)
		entity_set_float(effectID, EV_FL_nextthink, halflife_time() + PULSE_FREQUENCY)
}

public specialFX(meorig[3]) {
	//lightning beam
	new freq = floatround(PULSE_FREQUENCY * 10.0)
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
	write_byte(0)
	write_coord(meorig[0])			//(start positionx) 
	write_coord(meorig[1])			//(start positiony)
	write_coord(meorig[2] - 20)			//(start positionz)
	write_coord(meorig[0])			//(end positionx)
	write_coord(meorig[1])		//(end positiony)
	write_coord(meorig[2] + 75)		//(end positionz) 
	write_short(g_fxBeamSprite) 			//(sprite index) 
	write_byte(0) 			//(starting frame) 
	write_byte(0) 			//(frame rate in 0.1's) 
	write_byte(freq) 			//(life in 0.1's) 
	write_byte(25) 			//(line width in 0.1's) 
	write_byte(100) 			//(noise amplitude in 0.01's) 
	write_byte(LINE_COLOR_RED)			//r
	write_byte(LINE_COLOR_GREEN)			//g
	write_byte(LINE_COLOR_BLUE)			//b
	write_byte(255)			//brightness
	write_byte(1) 			//(scroll speed in 0.1's)
	message_end()

	//wave
	message_begin(MSG_BROADCAST,SVC_TEMPENTITY)
	write_byte( 21 ) 
	write_coord(meorig[0])
	write_coord(meorig[1])
	write_coord(meorig[2] - 20)
	write_coord(meorig[0])
	write_coord(meorig[1])
	write_coord(meorig[2] + 100)
	write_short( g_fxWave )
	write_byte( 0 ) // startframe 
	write_byte( 0 ) // framerate 
	write_byte(freq) // life 2
	write_byte( 15 ) // width 16 
	write_byte( 20 ) // noise 
	write_byte( WAVE_COLOR_RED ) 	// r 
	write_byte( WAVE_COLOR_GREEN ) 	// g 
	write_byte( WAVE_COLOR_BLUE ) 	// b 
	write_byte( 255 ) //brightness 
	write_byte( 5 / 10 ) // speed 
	message_end() 
}
/*====================================================================================================
	[End Of File]
====================================================================================================*/