/*------------------ > CREDITS < ------------------\\
//	Arkshine - unstuck method 
//	ConnorMcLeod - Opening / Closing Doors & Team Damage
//	Exolent - For Mic System & Help & striping weapons & returning them
// 	xGamer - Original Coder 
//	joaquimandrade - For Viewable ct
// 	XxAvalanchexX - For striping weapons 
//-------------------------------------------------*/
#include <amxmodx>
#include <amxmisc>
#include <fakemeta>
#include <fun>
#include <cstrike>
#include <hamsandwich>
#include <engine>
#include <nvault>
#include <xs>

#pragma semicolon 1;

/*================================================================================
 [Defines & Variables]
=================================================================================*/
#define get_bit(%1,%2) 		( %1 &   1 << ( %2 & 31 ) )
#define set_bit(%1,%2)	 	%1 |=  ( 1 << ( %2 & 31 ) )
#define clear_bit(%1,%2)	%1 &= ~( 1 << ( %2 & 31 ) )

new g_iMaxPlayers;
#define FIRST_PLAYER_ID	1
#define IsPlayer(%1) ( FIRST_PLAYER_ID <= %1 <= g_iMaxPlayers )

#define PLUGIN_NAME "Jailbreak - MAIN"
#define PLUGIN_VERS "1.6.5"
#define PLUGIN_AUTH "Pastout!"
#define PLUGIN_CVAR "JailBreakMod"

#define GetPlayerHullSize(%1)  ( ( pev ( %1, pev_flags ) & FL_DUCKING ) ? HULL_HEAD : HULL_HUMAN )

// --| The first search distance for finding a free location in the map.
#define START_DISTANCE    32   
// --| How many times to search in an area for a free space.
#define MAX_ATTEMPTS      128  

// --| Just for readability.
enum Coord_e { Float:x, Float:y, Float:z }

// Tasks ID's
#define TASK_TIMER 	7000
#define TASK_SIMONBEAM 	6000
#define TASK_MATH 	5000
#define TASK_BEAM 	4000 	// Beam Cylinder Task
#define TASK_HNS 	3000
#define TASK_DAYTIMER 	2000
#define TASKID 		1000

// Offsets (FM)
#define OFFSET_CLIPAMMO 51	// Clip Ammo Offset 
#define OFFSET_LINUX 4		// Weapons Linux Offset
#define OFFSET_PRIMWEAPON 116	// Primary Weapon Fix

#if cellbits == 32
    #define OFFSET_BUYZONE 235
#else
    #define OFFSET_BUYZONE 268
#endif

// Offsets (Ham)
#define m_pPlayer 41		// Ham_Item_Deploy (Weapon Owner)

#define HITGROUP_HEAD 1

// damage of explode, required for fm_radius_damage
#define EXPLODE_DAMAGE 100.0

// radius of damage (required for fm_radius damage )
#define EXPLODE_RADIUS 300.0

#define TEAM_T	1
#define TEAM_CT	2

#define XO_PLAYER  5
#define m_flWait   44 		// Offset for button delay
#define m_iTeam    114

#define cs_get_user_team_index(%1)	get_pdata_int(%1, m_iTeam, XO_PLAYER)
#define cs_set_user_team_index(%1,%2)	set_pdata_int(%1, m_iTeam, %2, XO_PLAYER)
#define m_iFlashBattery  244
#define m_pActiveItem    373
#define m_iUserPrefs     510
const HAS_SHIELD = 1<<24;
#define HasShield(%0)    ( get_pdata_int(%0, m_iUserPrefs, XO_PLAYER) & HAS_SHIELD )

new const g_szPluginPrefix[] = "JailBreak-Mod";		// Plugin g_szPluginPrefix (Tag)

#define DAY_ACCESS 		ADMIN_BAN	// access to start a day
#define VOTEDAY_ACCESS 		ADMIN_KICK	// access to start a vote day.
#define SPRAY_ACCESS 		ADMIN_MENU	// access to turn message on/off
#define ADMIN_CLASS 		ADMIN_BAN 	// access to the speical guard classes
#define ADMIN_MIC 		ADMIN_MENU 	// access to talk on there mic as prisoners
#define ADMIN_POINTS 		ADMIN_IMMUNITY	// access to give/take/set points
#define ADMIN_SIMON 		ADMIN_BAN 	// access to all simon items
#define ADMIN_DOORS 		ADMIN_BAN	// access to open/close doors as a prisoner
#define ADMIN_RANDOM_CT_SWITCH	ADMIN_MENU	// access to switch a prisoner to guard

//The weight of players votes
#define WEIGHT_PLAYER 1
#define WEIGHT_ADMIN 2
//This is for rebel options They must be 3 guards alive to choose this option in /lr unless you are a head admin
#define NUMBER_OF_GUARDS 3
//Max Simons allowed at ounce
#define MAX_SIMONS 1
//The value of this takes away hp from a user if they get a math question wrong
#define DMG_MATHQ 		50
#define ZOMBIE_SPEED 		400.0
#define NIGHTCRAWLER_SPEED 	400.0
#define REZOMBIE_SPEED 		325.0
#define RENIGHTCRAWLER_SPEED 	325.0
#define GRAVITY_DAY 		200
#define FREEZETAG_GRAVITY 	400
#define SCOUTDUAL_GRAVITY 	300

#define SPEAK_TEAM  4
new g_iSpeakFlags[33];

#define RACE_TIMER 5 // Last request for race timer count down...
#define CELL_TIMER 59.0 //Time before cells open automacticly if guards do not open cells themselfs

// Do NOT uncomment all 3 will not work... either uncomment SAVE_METHOD_NICK OR SAVE_METHOD_IP OR SAVE_METHOD_ID
// To save player data by nick, change "//#define SAVE_METHOD_NICK" to "#define SAVE_METHOD_NICK"
//#define SAVE_METHOD_NICK
// To save player data by ip, change "//#define SAVE_METHOD_IP" to "#define SAVE_METHOD_IP"
//#define SAVE_METHOD_IP
// To save player data by id, change "//#define SAVE_METHOD_ID" to "#define SAVE_METHOD_ID"
#define SAVE_METHOD_ID

#define ENG_NULLENT -1

static const g_iZombieDayLights[] = "a"; 	// Change this for the darkness of map when its a zombie/reverse day || You can choose abcdefghijklmnopqrstuvwxyz || a = PitchBlack z = Brightest

const WEAPONS_PISTOLS = (1<<CSW_P228)|(1<<CSW_ELITE)|(1<<CSW_FIVESEVEN)|(1<<CSW_USP)|(1<<CSW_GLOCK18)|(1<<CSW_DEAGLE);
const WEAPONS_SHOTGUNS = (1<<CSW_XM1014)|(1<<CSW_M3);
const WEAPONS_SUBMACHINEGUNS = (1<<CSW_MAC10)|(1<<CSW_UMP45)|(1<<CSW_MP5NAVY)|(1<<CSW_TMP)|(1<<CSW_P90);
const WEAPONS_RIFLES = (1<<CSW_SCOUT)|(1<<CSW_AUG)|(1<<CSW_SG550)|(1<<CSW_GALIL)|(1<<CSW_FAMAS)|(1<<CSW_AWP)|(1<<CSW_M4A1)|(1<<CSW_G3SG1)|(1<<CSW_SG552)|(1<<CSW_AK47);
const WEAPONS_MACHINEGUNS = (1<<CSW_M249);

const VALID_WEAPONS = WEAPONS_PISTOLS|WEAPONS_SHOTGUNS|WEAPONS_SUBMACHINEGUNS|WEAPONS_RIFLES|WEAPONS_MACHINEGUNS;

#define IsWeaponInBits(%1,%2) (((1<<%1) & %2) > 0)

const MAX_PLAYERS = 32;

new g_iWeaponBits[MAX_PLAYERS+1];
new g_iWeaponClip[MAX_PLAYERS+1][CSW_P90+1];
new g_iWeaponAmmo[MAX_PLAYERS+1][CSW_P90+1];
new g_iTagCount[MAX_PLAYERS+1];
new g_bIsTag;
new g_iDeaths[MAX_PLAYERS+1];

static const g_szWeaponNames[CSW_P90+1][] = {
	"","weapon_p228","","weapon_scout",
	"weapon_hegrenade","weapon_xm1014",
	"","weapon_mac10","weapon_aug",
	"weapon_smokegrenade","weapon_elite",
	"weapon_fiveseven","weapon_ump45",
	"weapon_sg550","weapon_galil",
	"weapon_famas","weapon_usp",
	"weapon_glock18","weapon_awp",
	"weapon_mp5navy","weapon_m249",
	"weapon_m3","weapon_m4a1","weapon_tmp",
	"weapon_g3sg1","weapon_flashbang","weapon_deagle",
	"weapon_sg552","weapon_ak47","","weapon_p90"
};

new iRandom;

static const szWeapons[][] = {
	"weapon_p228", "weapon_scout", "weapon_hegrenade",
	"weapon_xm1014", "weapon_mac10", "weapon_aug",
	"weapon_elite", "weapon_fiveseven", "weapon_ump45",
	"weapon_sg550", "weapon_galil", "weapon_famas",
	"weapon_usp", "weapon_glock18", "weapon_awp",
	"weapon_mp5navy", "weapon_m249", "weapon_m3",
	"weapon_m4a1", "weapon_tmp", "weapon_g3sg1",
	"weapon_deagle", "weapon_sg552", "weapon_ak47",
	"weapon_p90"
}; 

static const szWeapons2[][] = {
	"weapon_p228", "weapon_scout", "weapon_xm1014", 
	"weapon_mac10", "weapon_aug", "weapon_elite", 
	"weapon_fiveseven", "weapon_ump45", "weapon_sg550", 
	"weapon_galil", "weapon_famas", "weapon_usp", 
	"weapon_glock18", "weapon_awp", "weapon_mp5navy", 
	"weapon_m249", "weapon_m3", "weapon_m4a1", 
	"weapon_tmp", "weapon_g3sg1", "weapon_deagle", 
	"weapon_sg552", "weapon_ak47", "weapon_p90"
};

static const iBpAmmo[] = {
	52, 90, 90,
	32, 100, 90,
	120, 100, 100,
	90, 90, 90,
	100, 120, 30,
	120, 200, 32,
	90, 120, 90,
	35, 90, 90,
	100
};

static const g_szWeaponList1[][] = { 	
	"weapon_galil", "weapon_famas", 
	"weapon_ak47", "weapon_m4a1"
};

// Button Classnames
static const g_szButtonClasses[][] = {
	"func_button",
	"func_rot_button",
	"button_target"
};

new const g_szClassNameCrowbar[] = "class_crowbar";

enum _:g_iStartDay
{
	DAY_NONE, DAY_GRAVITY, DAY_FREEDAY,
	DAY_ZOMBIE, DAY_LAVA, DAY_SHARK,
	DAY_CAGE, DAY_DEATHMATCH, DAY_NIGHT,
	DAY_SPARTAN, DAY_HIDENSEEK, DAY_REZOMBIE,
	DAY_RESHARK, DAY_RENIGHT, DAY_FREEZETAG
};

#define TOTAL_DAYS 14

new gVoteMenu;
new gVotes[g_iStartDay];
new gVoting;
new bool:g_iAreWeInaVote;
new g_DayTimer = 0;
new g_iAutoStartVote = 0;

new const g_iStartDayNames[g_iStartDay][] =
{
	"", "JB_DAYNAME_GRAVITY", "JB_DAYNAME_FREEDAY",
	"JB_DAYNAME_ZOMBIE", "JB_DAYNAME_LAVA", "JB_DAYNAME_SHARK",
	"JB_DAYNAME_CAGE", "JB_DAYNAME_DM", "JB_DAYNAME_NC",
	"JB_DAYNAME_SPARTAN", "JB_DAYNAME_HIDENSEEK", "JB_DAYNAME_RZOMBIE",
	"JB_DAYNAME_RSHARK", "JB_DAYNAME_RNC",
	"JB_DAYNAME_FREEZETAG"
};

new g_iDay[ g_iStartDay ];

// Precache
new const CrowbarModels[][] = { "models/p_crowbar.mdl", "models/v_crowbar.mdl", "models/w_crowbar.mdl" };
new const ZombieModels[][]= { "models/jb_claws.mdl" };
new const CrowbarSounds[][] = { "weapons/cbar_hitbod2.wav",
	"weapons/cbar_hitbod1.wav", "weapons/bullet_hit1.wav", "weapons/bullet_hit2.wav",
	"weapons/knife_slash1.wav", "weapons/cbar_miss1.wav",  "weapons/cbar_hit1.wav",
	"debris/metal2.wav", "items/gunpickup2.wav"
 };
 
new const g_szSound_Bell[] = "buttons/bell1.wav";

new Float:DetectionMaxDistance = 1000.0;
new Ham:Ham_Player_ResetMaxSpeed = Ham_Item_PreFrame;
new g_bIsLast;			// It's the last terrorist?
new g_bIsGlowing;		// Is the user glowing?
new g_bHasFreeday;		// Do they have a freeday?
new g_bHasCrowbar;		// Does he own a crowbar?
new g_bHasSpeed;		// Does he own speed?
new g_bHasInvis;		// Does he own invisibility?
new g_bHasNadepack;		// Does he own a nadepack?
new g_bHasArmor;		// Does he own armor?
new g_bHasDisguise;		// Does he own a disguise?
new g_bHasCellKeys;		// Does he own a cell key?
new g_bHasFootstep;		// Does he own no footstep?
new g_bIsChosen;		// It's the chosen ct for the battle?
new g_bIsAlive;			// Are we alive?
new g_bIsConnected;		// Are we connected?
new g_bIsSimon;			// Are we simon?
new g_bHasMenuOpen;		// Has a menu open
new g_bInDisguise;		// Are they in disguise
new g_bInMathProblem;		// Are we in math problem
new g_bHasVotedAlready;		// Did we vote already?
new g_bHasClosedMenu;		// Did we close the vote menu?
new bool:g_bBoxMatch;		// Are we in a box match?
new bool:g_bAutoOpened;		// Did the cells open at 8:00?
new bool:g_bAlreadyOpened;	// If the cells have been opened before 8:00
new bool:g_bInLr;		// Is the terrorist in an Lr?
new bool:g_bCanBuy;		// Can they use the shop?
new bool:g_bDayHasStarted;
new bool:g_bGrenade;
new bool:g_bFrozenTime;	
new bool:g_bTeamDivided;
new bool:g_bSprayMessages;
new bool:g_bBufferDoors;
new g_bHeadShot[MAX_PLAYERS+1][MAX_PLAYERS+1];
new g_iFinalCT;		
new g_iRingSprite;			// ShockWave Sprite
new g_iCrowbars;			// number of players with crowbars
new g_iDisguise;			// number of players with disguise
new g_iCellKeys;			// number of players with cell keys
new g_iSpeed;				// number of players with speed
new g_iInvis;				// number of players with invisibility
new g_iFootstep;			// number of players with no footsteps
new g_iMsgSayText;			// SayText (ColorPrint)
new g_iMsgTextMsg;
new g_iMsgId_ScreenFade;
new g_iMsgFog;
new g_iMsgDeath;
new g_iMsgScoreInfo;
new g_iBlockLastRequest;		// Block Last Request Command (BugFix)
new g_iGameType;			// Last Request Game Type
new g_iPoints[MAX_PLAYERS+1];		// Amount of Points a player has
new g_iAdminDay = 0;
new g_iVictimTeam;

#if defined SAVE_METHOD_NICK
new g_iAuth[MAX_PLAYERS+1][32];
#endif
#if defined SAVE_METHOD_IP
new g_iAuthIP[MAX_PLAYERS+1][32];
#endif
#if defined SAVE_METHOD_ID
new g_iAuthID[MAX_PLAYERS+1][32];
#endif

new g_vault;				// Open a new vault to store a players points.
new g_buttonvault;			// Open a new vault to store the cell door button.
new iEnt;				// This is the button
new explosion_sprite;			// Suicide bomber sprite
new szMap[33];
new szClass[33];
new szModel[33];
new g_ThermalOn[MAX_PLAYERS+1];
new HamHook:g_iHhTakeDamagePost;
new g_Timer;
new g_FrozenT;
new g_10HP = 10;
new g_25HP = 25;
new g_50HP = 50;
new g_100HP = 100;
new mathAnswer[MAX_PLAYERS+1];
new mathEquations[MAX_PLAYERS+1][128];
new g_pRoundTime;
//Thanks to exo
new Float:g_fRoundStartTime;
new Float:g_fRoundTime;

new const g_iOperators[4][2] = {
	"+", 
	"-", 
	"*", 
	"/"
};

new const g_iSpeakNames[][] = {
	"",
	"JB_CHANNEL_M1", 
	"JB_CHANNEL_M2",
	"JB_CHANNEL_M3", 
	"JB_CHANNEL_M4"
};

new g_iTimerEntity;

new const SayClientCmds[][64] = {
	"lr", "ClCmd_LastRequest", "spray",   "CmdSprayMessage", "status", "status", "box", "ClCmd_boxmatch", "boxmatch", "ClCmd_boxmatch",
	"day", "specialday_check", "days", "specialday_check", "voteday", "CheckStartVote", "endday", "specialday_ends",
	"glow", "JBGlowMenu", "freeday", "JBGlowMenu", "unglow", "JBUnglowMenu", 
	"class", "ClassMenu", "shop", "ClCmd_shop", "point", "ClCmd_points", "points", "ClCmd_points", "simon", "ClCmd_simon",
	"talkchannel", "ClCmd_channel", "talk", "ClCmd_channel", "channel", "ClCmd_channel", "mic", "ClCmd_channel",
	"close", "ClCmd_closedoors", "closedoors", "ClCmd_closedoors", "open", "ClCmd_opendoors", "opendoors", "ClCmd_opendoors",
	"random", "ClCmd_randomct", "next", "ClCmd_nextproblem"
};

enum _:Cvars 
{
	cvar_shop,
	cvar_killpoints,
	cvar_headshotpoints,
	cvar_crowbarprice,
	cvar_armorprice,
	cvar_disguiseprice,
	cvar_nadepackprice,
	cvar_speedprice,
	cvar_invisprice,
	cvar_footstepprice,
	cvar_crowbarlimit,
	cvar_invislimit,
	cvar_footsteplimit,
	cvar_speedlimit,
	cvar_disguiselimit,
	cvar_alphavalue,
	cvar_shopspeed,
	cvar_admindaywait,
	cvar_autostartvote,
	cvar_blockvoice,
	cvar_fogeffect,
	cvar_sprayenable,
	cvar_shootbuttons,
	cvar_cellkeyslimit,
	cvar_cellkeysprice
};

new const cvar_names[Cvars][] = {
	"jb_shop",		// Enable/disable shop
	"jb_points_kill",	// Points per kill
	"jb_points_headshot",	// Additional points per headshot
	"jb_shop_crowbar",	// price for crowbar
	"jb_shop_armor",	// price for armor
	"jb_shop_disguise",	// price for armor
	"jb_shop_nadepack",	// price for nade pack
	"jb_shop_speed",	// price for speed
	"jb_shop_invisibility",	// price for stealth
	"jb_shop_footstep",	// price for footstep
	"jb_crowbar_limit",	// crowbar limit
	"jb_invisibility_limit",// stealth limit
	"jb_footstep_limit",	// footstep limit
	"jb_speed_limit",	// speed limit
	"jb_disguise_limit",	// disguise limit
	"jb_shop_alpha_value",	// alpha value
	"jb_shop_speed_value",	// speed value
	"jb_admin_daywait",	// How many days an non admin has to wait before starting a day
	"jb_startvote_wait",	// How many days/rounds to wait before automaticly starting a day vote
	"jb_blockvoice",	// 0- Alltalk 1- Guards can't hear prisoners 2- Prisoners can't talk 
	"jb_fogeffect",		// Enable Fog (1 = Enable) (2 = Disable)
	"jb_enablespray",	// Enable spray (1 = Enable) (2 = Disable)
	"jb_shootbuttons",	// Allow button press by bullets
	"jb_cellkey_limit",	// call keys limit
	"jb_shop_cellkeys"	// price for cell keys
};

new const cvar_defaults[Cvars][] = {
	"1",		// Enable/disable shop
	"1",		// Points per kill
	"1",		// Additional points per headshot
	"20",		// price for crowbar
	"10",		// price for armor
	"50",		// price for armor
	"10",		// price for nade pack
	"10",		// price for speed
	"10",		// price for stealth
	"10",		// price for footstep
	"2",		// crowbar limit
	"5",		// stealth limit
	"5",		// footstep limit
	"5",		// speed limit
	"1",		// disguise limit
	"120",		// alpha value
	"300",		// speed value
	"2",		// How many days an non admin has to wait before starting a day
	"4",		// How many days/rounds to wait before automaticly starting a day vote
	"1",		// 0- Alltalk 1- Guards can't hear prisoners 2- Prisoners can't talk 
	"1",		// Enable Fog (1 = Enable) (2 = Disable)
	"1",		// Enable spray (1 = Enable) (2 = Disable)
	"1",		// Allow button press by bullets
	"2",		// call keys limit
	"45"		// price for cell keys
};

new cvar_pointer[Cvars];

/*================================================================================
 [Init]
=================================================================================*/
public plugin_init() 
{
	register_plugin(PLUGIN_NAME, PLUGIN_VERS, PLUGIN_AUTH);
	register_cvar(PLUGIN_CVAR, PLUGIN_VERS, FCVAR_SERVER|FCVAR_SPONLY);
	
	register_dictionary("jailbreakmod.txt");

	// Variables
	g_iMaxPlayers	 	= get_maxplayers();
	g_iMsgSayText	 	= get_user_msgid("SayText");
	g_iMsgTextMsg 	 	= get_user_msgid("TextMsg");
	g_iMsgId_ScreenFade 	= get_user_msgid("ScreenFade");
	g_iMsgFog		= get_user_msgid("Fog");
	g_iMsgDeath		= get_user_msgid("DeathMsg");
	g_iMsgScoreInfo		= get_user_msgid("ScoreInfo");

	g_bCanBuy        = true;
	g_bAutoOpened	= false;
	
	// HAM Forwards
	RegisterHam(Ham_Spawn, "player", "Fwd_PlayerSpawn_Post", 1);
	RegisterHam(Ham_Killed, "player", "Fwd_PlayerKilled_Pre", 0);
	RegisterHam(Ham_TraceAttack, "player", "Fwd_TraceAttack_Player", 1);
	RegisterHam(Ham_TraceAttack, "func_button", "Fwd_ButtonAttack");
	RegisterHam(Ham_TraceAttack, "func_door", "Fwd_DoorAttack");
	RegisterHam(Ham_Touch, "player", "Fwd_PlayerTouch");
	RegisterHam(Ham_Touch, "weaponbox", "Fwd_PlayerWeaponTouch"); 
	RegisterHam(Ham_Touch, "armoury_entity", "Fwd_PlayerWeaponTouch");
	RegisterHam(Ham_AddPlayerItem, "player", "Player_AddPlayerItem", 0);
	RegisterHam(Ham_Player_ResetMaxSpeed, "player", "Player_ResetMaxSpeed", 1);
	RegisterHam(Ham_TakeDamage, "player", "Fwd_PlayerDamage");
	g_iHhTakeDamagePost = RegisterHam(Ham_TakeDamage, "player", "Player_TakeDamage_Post", 1);
	DisableHamForward(g_iHhTakeDamagePost);
	
	new szWeaponName[32];
	for(new i=CSW_P228; i<=CSW_P90; i++)
		if( get_weaponname(i, szWeaponName, charsmax(szWeaponName)) )
			RegisterHam(Ham_Item_Deploy, szWeaponName, "Fwd_ItemDeploy_Post", 1);
		
	RegisterHam(Ham_Item_Deploy, "weapon_knife", "Fwd_ItemDeploy2_Post", 1);

	for (new i = 0; i < sizeof(g_szButtonClasses); i++)
		RegisterHam(Ham_Use, g_szButtonClasses[i], "Fwd_Use_Pre", 0);
        
	register_forward(FM_EmitSound, "sound_emit");
	register_forward(FM_Voice_SetClientListening, "Fwd_SetVoice");
	register_forward(FM_Think, "Fwd_Entity_Think");
	register_forward(FM_SetModel,"Fwd_Model_Think");
	register_forward(FM_AddToFullPack, "Fwd_AddToFullPack", 1);
	
	register_touch(g_szClassNameCrowbar, "worldspawn", "CrowbarTouch");
	register_touch(g_szClassNameCrowbar, "player", "Fwd_PlayerCrowbarTouch");
	
	for(new i = 0; i < Cvars; i++)
		cvar_pointer[i] = register_cvar(cvar_names[i] , cvar_defaults[i]);
		
	g_pRoundTime = get_cvar_pointer("mp_roundtime");

	// Events
	register_logevent("EventNewRound", 2, "1=Round_Start");
	register_logevent("EventRoundEnd", 2, "1&Restart_Round");
	register_logevent("EventRoundEnd", 2, "1=Game_Commencing");
	register_logevent("EventRoundEnd", 2, "1=Round_End");
	register_event("SendAudio", "Event_SendAudio", "a", "2&%!MRAD_terwin");
	register_event("NVGToggle", "Event_NVGToggle", "be");
	register_event("23", "EventSpray", "a", "1=112");
	register_message(get_user_msgid("SendAudio"), "MsgSendAudio");
	register_message(get_user_msgid("StatusIcon"), "MsgStatusIcon");
	register_message(get_user_msgid("FlashBat"), "MsgFlashBat");
	register_message(get_user_msgid("Flashlight"), "MsgFlashLight");
	
	// Client Commands
	register_clcmd("wear_disguise", "ClCmd_CheckDisguise", _, "Wear Disguise");
	register_clcmd("glow_blue", "Clcmd_GlowBlue", _, "Glow Blue");
	register_clcmd("glow_red", "Clcmd_GlowRed", _, "Glow Red");
	register_clcmd("unglow", "Clcmd_UnglowPlayer", _, "Unglow Player");
	register_clcmd("drop", "ClCmd_drop", _, "Crowbar Drop");
	register_clcmd("say", "ClCmd_Say", _, "Check Answer");
	
	for(new i = 0; i < sizeof(SayClientCmds); i = i+2)
		rd_register_saycmd(SayClientCmds[i], SayClientCmds[i+1], 0);
	
	register_concmd("amx_take_points", "cmd_take_points", ADMIN_POINTS, "<target> <amount>");
	register_concmd("amx_give_points", "cmd_give_points", ADMIN_POINTS, "<target> <amount>");
	register_concmd("amx_reset_points", "cmd_reset_points", ADMIN_POINTS, "<target>");
	register_concmd("amx_set_button", "cmd_set_button", ADMIN_RCON);
	
	g_iTimerEntity = create_entity( "info_target" );
	entity_set_string( g_iTimerEntity, EV_SZ_classname, "hud_entity" );
	register_think( "hud_entity", "Fwd_HudThink" );
	entity_set_float( g_iTimerEntity, EV_FL_nextthink, get_gametime() + 1.0 );

	#if defined SAVE_METHOD_NICK
	g_vault = nvault_open("jbpoints_nicks");
	#endif
	#if defined SAVE_METHOD_IP
	g_vault = nvault_open("jbpoints_ip");
	#endif
	#if defined SAVE_METHOD_ID
	g_vault = nvault_open("jbpoints");
	#endif
	if(g_vault == INVALID_HANDLE)
		set_fail_state( "Error opening Points nVault" );
}

enum Commands
{
	say,
	say_slash,
	say_dot,
	sayteam,
	sayteam_slash,
	sayteam_dot
};
	
new const say_commands[Commands][] = {
	"say /%s",
	"say %s",
	"say .%s",
	"say_team %s",
	"say_team /%s",
	"say_team .%s"
};

stock rd_register_saycmd(const saycommand[], const function[], flags) {
	static temp[64];
	for (new Commands:i = say; i < Commands; i++)
	{
		formatex(temp, 63, say_commands[i], saycommand);
		register_clcmd(temp, function, flags);
	}
}

public MsgFlashLight( const MsgId, const MsgType, const id )
	set_msg_arg_int( 2, ARG_BYTE, 100 );

public MsgFlashBat( const MsgId, const MsgType, const id ) {
	if( get_msg_arg_int( 1 ) < 100 ) {
		set_msg_arg_int( 1, ARG_BYTE, 100 );
		
		set_pdata_int( id, m_iFlashBattery, 100, 5 );
	}	
}

public Fwd_ButtonAttack(button, id, Float:damage, Float:direction[3], tracehandle, damagebits)
{
	new Float:fNextUse;
	pev(button, pev_fuser4, fNextUse);
	
	new Float:fGametime = get_gametime();
	new class[32], sModel[32];
	pev(button, pev_classname, class, 32);
	pev(button, pev_model, sModel, 32);
	
	if (fNextUse > fGametime)
		return HAM_IGNORED;
		
	if(is_valid_ent(button) && get_pcvar_num(cvar_pointer[cvar_shootbuttons]) == 1)
	{
		ExecuteHamB(Ham_Use, button, id, 0, 1, 1.0);
		entity_set_float(button, EV_FL_frame, 0.0);
		if( equal(sModel, szModel, 0) )
		{
			new szTargetName[32];
			get_user_name(id, szTargetName, charsmax(szTargetName));
			if(g_bAutoOpened)
				g_bAutoOpened = false;
			else {
				static iTimeLeft, iMinutes, iSeconds;
				iTimeLeft = floatround(g_fRoundTime - (get_gametime() - g_fRoundStartTime),floatround_ceil);
	
				if(iTimeLeft <= 0)
				{
					iMinutes = 0;
					iSeconds = 0;
				}
				else {
					iMinutes = (iTimeLeft / 60);
					iSeconds = (iTimeLeft % 60);
				}
				
				if(id > 0)
					fnColorPrint(0, "%L", 
					LANG_SERVER, "JB_OPENCELLS", '^3', szTargetName, '^1', '^4', '^1', 
					'^3', iMinutes, '^1', '^3', iSeconds > 9 ? "" : "0", iSeconds);
			}
					
			if (!g_bAlreadyOpened)
			{
				remove_task( TASKID );
				g_bAlreadyOpened = true;
				g_bCanBuy = false;
			}
				
			set_pev(button, pev_fuser4, fGametime + get_pdata_float(button, m_flWait, 5));
		}
	}
	return HAM_IGNORED;
}

public Fwd_DoorAttack(door, id, Float:damage, Float:direction[3], tracehandle, damagebits)
{	
	if(is_valid_ent(door))
	{
		if(g_iDay[ TOTAL_DAYS ] != DAY_NONE)
		{
			ExecuteHamB(Ham_Use, door, id, 0, 1, 1.0);
			entity_set_float(door, EV_FL_frame, 0.0);
		}
		if(get_bit(g_bHasCellKeys, id))
		{
			fnColorPrint(id, "%L", LANG_SERVER, "JB_SHOP_CELLKEY1");
			ExecuteHamB(Ham_Use, door, id, 0, 1, 1.0);
			entity_set_float(door, EV_FL_frame, 0.0);
			clear_bit(g_bHasCellKeys, id);
		}
	}
	return HAM_IGNORED;
}

public Fwd_PlayerWeaponTouch( const iEntity, const id )
{
	if(!IsPlayer(id))
		return HAM_IGNORED;

	new Model[32];
	pev(iEntity, pev_model, Model, 31);
		
	static CsTeams:team;
	team = cs_get_user_team(id);

	switch( g_iDay[ TOTAL_DAYS ] )
	{
		case DAY_ZOMBIE:
			switch(team)
			{
				case CS_TEAM_T: if (!equal(Model, "models/w_ak47.mdl")) return HAM_SUPERCEDE;
				case CS_TEAM_CT: return HAM_SUPERCEDE;
			}
		case DAY_SHARK:
			switch(team)
			{
				case CS_TEAM_T: if (!equal(Model, "models/w_awp.mdl")) return HAM_SUPERCEDE;
				case CS_TEAM_CT: return HAM_SUPERCEDE;
			}
		case DAY_NIGHT:
			switch(team)
			{
				case CS_TEAM_T: if (!equal(Model, "models/w_m4a1.mdl")) return HAM_SUPERCEDE;
				case CS_TEAM_CT: return HAM_SUPERCEDE;
			}
		case DAY_HIDENSEEK:
			if(team == CS_TEAM_T)
				return HAM_SUPERCEDE;
		case DAY_REZOMBIE:
			switch(team)
			{
				case CS_TEAM_T: return HAM_SUPERCEDE;
				case CS_TEAM_CT: if (!equal(Model, "models/w_ak47.mdl")) return HAM_SUPERCEDE;
			}
		case DAY_RESHARK:	
			switch(team)
			{
				case CS_TEAM_T: return HAM_SUPERCEDE;
				case CS_TEAM_CT: if (!equal(Model, "models/w_awp.mdl")) return HAM_SUPERCEDE;
			}
		case DAY_RENIGHT:
			switch(team)
			{
				case CS_TEAM_T: return HAM_SUPERCEDE;
				case CS_TEAM_CT: if (!equal(Model, "models/w_m4a1.mdl")) return HAM_SUPERCEDE;
			}
		case DAY_FREEZETAG:
			return HAM_SUPERCEDE;
	}
	
	return HAM_IGNORED;
}

public Player_AddPlayerItem(id, iEntity)
{
	new iWeapID = cs_get_weapon_id( iEntity );

	if( !iWeapID )
		return HAM_IGNORED;
		
	static CsTeams:team;
	team = cs_get_user_team(id);
	switch( g_iDay[ TOTAL_DAYS ] )
	{
		case DAY_ZOMBIE:
			switch(team)
			{
				case CS_TEAM_T:
					if(iWeapID != CSW_KNIFE && iWeapID != CSW_AK47)
					{
						SetHamReturnInteger( 1 );
						return HAM_SUPERCEDE;
					}
				case CS_TEAM_CT:
					if(iWeapID != CSW_KNIFE)
					{
						SetHamReturnInteger( 1 );
						return HAM_SUPERCEDE;
					}
			}
		case DAY_SHARK:
			switch(team)
			{
				case CS_TEAM_T:
					if(iWeapID != CSW_KNIFE && iWeapID != CSW_AWP)
					{
						SetHamReturnInteger( 1 );
						return HAM_SUPERCEDE;
					}
				case CS_TEAM_CT:
					if(iWeapID != CSW_KNIFE)
					{
						SetHamReturnInteger( 1 );
						return HAM_SUPERCEDE;
					}
			}
		case DAY_NIGHT:
			switch(team)
			{
				case CS_TEAM_T:
					if(iWeapID != CSW_KNIFE && iWeapID != CSW_M4A1)
					{
						SetHamReturnInteger( 1 );
						return HAM_SUPERCEDE;
					}
				case CS_TEAM_CT:
					if(iWeapID != CSW_KNIFE)
					{
						SetHamReturnInteger( 1 );
						return HAM_SUPERCEDE;
					}
			}
		case DAY_HIDENSEEK:
			if(team == CS_TEAM_T)
				if(iWeapID != CSW_KNIFE)
				{
					SetHamReturnInteger( 1 );
					return HAM_SUPERCEDE;
				}
		case DAY_REZOMBIE:
			switch(team)
			{
				case CS_TEAM_T:
					if(iWeapID != CSW_KNIFE)
					{
						SetHamReturnInteger( 1 );
						return HAM_SUPERCEDE;
					}
				case CS_TEAM_CT:
					if(iWeapID != CSW_KNIFE && iWeapID != CSW_AK47)
					{
						SetHamReturnInteger( 1 );
						return HAM_SUPERCEDE;
					}
			}
		case DAY_RESHARK:
			switch(team)
			{
				case CS_TEAM_CT:
					if(iWeapID != CSW_KNIFE && iWeapID != CSW_AWP)
					{
						SetHamReturnInteger( 1 );
						return HAM_SUPERCEDE;
					}
				case CS_TEAM_T:
					if(iWeapID != CSW_KNIFE)
					{
						SetHamReturnInteger( 1 );
						return HAM_SUPERCEDE;
					}
			}
		case DAY_RENIGHT:
			switch(team)
			{
				case CS_TEAM_T:
					if(iWeapID != CSW_KNIFE)
					{
						SetHamReturnInteger( 1 );
						return HAM_SUPERCEDE;
					}
				case CS_TEAM_CT:
					if(iWeapID != CSW_KNIFE && iWeapID != CSW_M4A1)
					{
						SetHamReturnInteger( 1 );
						return HAM_SUPERCEDE;
					}
			}
		case DAY_FREEZETAG:
			if(iWeapID != CSW_KNIFE)
			{
				SetHamReturnInteger( 1 );
				return HAM_SUPERCEDE;
			}
	}
	
	return HAM_IGNORED;
}

public plugin_precache()
{
	g_iRingSprite = precache_model("sprites/shockwave.spr");
	
	static i;
	for(i = 0; i < sizeof(CrowbarModels); i++)
		precache_model(CrowbarModels[i]);
 
	for(i = 0; i < sizeof(CrowbarSounds); i++)
		precache_sound(CrowbarSounds[i]);
		
	precache_model(ZombieModels[0]);
		
	precache_model("models/player/urban/urban.mdl");
	precache_model("models/player/leet/leet.mdl");
	
	precache_sound(g_szSound_Bell);
	
	g_buttonvault = nvault_open("cellbuttons");
	if(g_buttonvault == INVALID_HANDLE)
		set_fail_state("Error opening Cell Buttons nVault");
	RegisterHam(Ham_Spawn, "func_button", "ButtonSpawn");
	Get_Button();
}

public plugin_cfg()
	get_mapname(szMap, 32);

public client_putinserver(id) {
	if(bool:!is_user_hltv(id))
		set_bit(g_bIsConnected, id);
		
	fm_set_speak(id, SPEAK_NORMAL);
	
	clear_bit(g_bIsAlive, id);
	reset_all(id);
}

public client_authorized(id) {
	if(!is_user_bot(id) && !is_user_hltv(id))
	{
		#if defined SAVE_METHOD_NICK
		get_user_name(id, g_iAuth[id], 31);
		#endif
		#if defined SAVE_METHOD_IP
		get_user_ip(id, g_iAuthIP[id], 31);
		#endif
		#if defined SAVE_METHOD_ID
		get_user_authid(id, g_iAuthID[id], 31);
		#endif
		
		GetData(id);
	}
}

public plugin_end(){
	nvault_close(g_vault);
	nvault_close(g_buttonvault);
}

public client_disconnect(id){
	if(get_bit(g_bIsSimon, id)){
		set_task(0.1, "ResetSimon");
		clear_bit(g_bIsSimon, id);
	}
	remove_task(id+TASK_BEAM);
	// Save Points
	SaveData(id);
	clear_bit(g_bIsConnected, id);
	clear_bit(g_bIsAlive, id);
	
	if( g_iDay[TOTAL_DAYS] == DAY_FREEZETAG )
		CheckTerrorist( );
}

public status( id )
	if( g_iDay[ TOTAL_DAYS ] == DAY_FREEZETAG )
		fnColorPrint(id, "%L", LANG_SERVER, "JB_FREEZETAG_M1", '^3', fnGetTerrorists(), '^1', '^3', g_FrozenT );

public EventNewRound() {
	g_fRoundTime = floatmul(get_pcvar_float(g_pRoundTime),60.0) - 1.0;
	g_fRoundStartTime = get_gametime();
	
	set_task(CELL_TIMER, "TASK_PushButton", TASKID );//61
	if(g_iAdminDay >= 1)
		g_iAdminDay--;
		
	g_iAutoStartVote++;
	if(g_iAutoStartVote == get_pcvar_num(cvar_pointer[cvar_autostartvote]))
	{
		fnColorPrint(0, "%L", LANG_SERVER, "JB_VOTEDAY_M1");
		set_task(5.0, "CheckVoteDay");
		g_iAutoStartVote = 0;
	}
	
	// Reset LR Blocker
	g_iBlockLastRequest = 0;
	g_bDayHasStarted = false;
	g_bGrenade = false;
	g_bTeamDivided = false;
	remove_entity_name(g_szClassNameCrowbar);
	Day_Ends( );
}

public CheckVoteDay()
{
	static iPlayers[32], iNum, iPlayer, i;
	get_players( iPlayers, iNum ); 
	for( i = 0; i < iNum; i++ )
	{
		iPlayer = iPlayers[i];
		StartVote(iPlayer, 0);
	}
}

public specialday_check(id){
	if(get_user_team(id) != 2 )
	{
		fnColorPrint(id, "%L", LANG_SERVER, "JB_DAY_M1");
		return PLUGIN_HANDLED;
	}
	
	if(!access(id, DAY_ACCESS) )
	{
		fnColorPrint(id, "%L", LANG_SERVER, "JB_DAY_M2");
		return PLUGIN_HANDLED;
	}
	
	if(!get_bit(g_bIsConnected, id))	
		return PLUGIN_HANDLED;

	if(!get_bit(g_bIsAlive, id))
	{	
		fnColorPrint(id, "%L", LANG_SERVER, "JB_USER_DEAD");
		return PLUGIN_HANDLED;
	}
	
	if(g_iDay[ TOTAL_DAYS ] != DAY_NONE)
	{
		fnColorPrint(id, "%L", LANG_SERVER, "JB_DAY_M3");
		return PLUGIN_HANDLED;
	}
	
	if(g_bDayHasStarted)
	{
		fnColorPrint(id, "%L", LANG_SERVER, "JB_DAY_M4");
		return PLUGIN_HANDLED;
	}
	if(g_iAreWeInaVote)
	{
		fnColorPrint(id, "%L", LANG_SERVER, "JB_DAY_M5");
		return PLUGIN_HANDLED;
	}
	static g_iAdminDayChat;
	if( g_iAdminDay == 1 )
		g_iAdminDayChat = true;
	else g_iAdminDayChat = false;

	if( g_iAdminDay >= 1 && !access(id, DAY_ACCESS) )
	{
		fnColorPrint(id, "%L", LANG_SERVER, "JB_DAY_M6", g_iAdminDay, g_iAdminDayChat ? "" : "s" );
		return PLUGIN_HANDLED;
	}
	
	if(fnGetTerrorists() <= 1)
	{
		fnColorPrint(id, "%L", LANG_SERVER, "JB_DAY_M7");
		return PLUGIN_HANDLED;
	}
	
	specialday_menu(id);
	return PLUGIN_HANDLED;
}

public specialday_ends(id)
{
	if(get_user_team(id) != 2){
		fnColorPrint(id, "%L", LANG_SERVER, "JB_DAY_M8");	
		return PLUGIN_HANDLED;
	}
	if(g_iDay[ TOTAL_DAYS ] == DAY_NONE){
		fnColorPrint(id, "%L", LANG_SERVER, "JB_DAY_M9");
		return PLUGIN_HANDLED;
	}
	static szName[32]; get_user_name(id, szName, charsmax(szName));
	fnColorPrint(id, "%L", LANG_SERVER, "JB_DAY_M10", '^3', szName, '^1');

	Day_Ends( );
	return PLUGIN_HANDLED;
}

stock StripPlayerWeapons(id)
{
	strip_user_weapons(id); 
	give_item(id, "weapon_knife");
	set_pdata_int(id, OFFSET_PRIMWEAPON, 0);
}

public Day_Ends( )
{
	if( g_iDay[ TOTAL_DAYS ] == DAY_NONE )
		return PLUGIN_HANDLED;

	static CsTeams:team;
	static iPlayers[32], iNum, i, iPlayer;
	get_players( iPlayers, iNum, "a" ); 
	for ( i=0; i<iNum; i++ ) 
	{
		iPlayer = iPlayers[i];
		team = cs_get_user_team(iPlayer);
		set_user_health(iPlayer, g_100HP);	
		set_user_noclip(iPlayer, 0);
		set_user_footsteps(iPlayer, 0);
		set_user_maxspeed(iPlayer, 250.0);
		set_user_rendering(iPlayer, _, 0, 0, 0, _, 0);
		switch(g_iDay[ TOTAL_DAYS ])
		{
			case DAY_ZOMBIE:
			{	
				g_iDeaths[iPlayer] = 0;
				if(team == CS_TEAM_CT)
				{
					if( g_ThermalOn[iPlayer] )
					{
						engclient_cmd(iPlayer, "nightvision");
						cs_set_user_nvg(iPlayer,false);
					}
					else cs_set_user_nvg(iPlayer,false);
				}
			}
			case DAY_REZOMBIE:
			{	
				g_iDeaths[iPlayer] = 0;
				if(team == CS_TEAM_T)
				{
					if( g_ThermalOn[iPlayer] )
					{
						engclient_cmd(iPlayer, "nightvision");
						cs_set_user_nvg(iPlayer,false);
					}
					else cs_set_user_nvg(iPlayer,false);
				}
			}
			case DAY_FREEZETAG: Unfreeze(iPlayer);
			case DAY_HIDENSEEK: Unfreeze(iPlayer);
		}
		if(is_user_stuck(iPlayer))
			ClientCommand_UnStuck(iPlayer);
	}
	server_cmd("sv_gravity 800");
	if( g_iDay[ TOTAL_DAYS ] == DAY_ZOMBIE || g_iDay[ TOTAL_DAYS ] == DAY_REZOMBIE)
	{
		set_lights("#OFF");
		fog(false);
	}
	g_iDay[ TOTAL_DAYS ] = DAY_NONE;
	for ( i=0; i<iNum; i++ ) 
	{
		iPlayer = iPlayers[i];
		team = cs_get_user_team(iPlayer);
		switch(team)
		{
			case CS_TEAM_T: StripPlayerWeapons(iPlayer);
			case CS_TEAM_CT: RestoreWeapons(iPlayer);
		}
		if (get_user_weapon(iPlayer) == CSW_KNIFE) 
		{
			new iWeapon = get_pdata_cbase(iPlayer, m_pActiveItem, XO_PLAYER);
			ExecuteHamB(Ham_Item_Deploy, iWeapon);
		}
	}
	return PLUGIN_HANDLED;
}

public CheckStartVote(id)
{
	if( gVoting )
	{
		fnColorPrint(id, "%L", LANG_SERVER, "JB_DAY_M11");
		return PLUGIN_HANDLED;
	}
	if( !access(id, VOTEDAY_ACCESS) )
	{
		fnColorPrint(id, "%L", LANG_SERVER, "JB_NOACCESS");
		return PLUGIN_HANDLED;
	}
	
	if(g_iDay[ TOTAL_DAYS ] != DAY_NONE || g_bDayHasStarted /* || fnGetTerrorists() <= 1 || fnGetCounterTerrorists() == 0*/ )
	{
		return PLUGIN_HANDLED;
	}
	
	StartVote(id, 0);
	return PLUGIN_HANDLED;
}

public StartVote(id, iPage){
	if(g_bDayHasStarted)
		return PLUGIN_HANDLED;
	
	if( !task_exists(TASK_DAYTIMER) )
	{
		fnColorPrint(0, "%L", LANG_SERVER, "JB_DAY_M12");
		g_DayTimer = 30;
		set_task( 1.0, "EndVote", TASK_DAYTIMER, _, _, "b" );
	}
	
	new gMenu[256];
	formatex( gMenu, charsmax(gMenu), "%L", LANG_SERVER, "JB_VOTEMENU_TITLE", g_szPluginPrefix, g_DayTimer );
	
	gVoteMenu = menu_create( gMenu, "menu_handler" );

	new iNumber[5], szOption[40];
	for( new i = 1; i < g_iStartDay; i++ )
	{
		num_to_str(i, iNumber, 4);
		formatex(szOption, 39, "%L", LANG_SERVER, "JB_VOTEMENU_SUB", LANG_SERVER, g_iStartDayNames[i], gVotes[i]);
		menu_additem(gVoteMenu, szOption, iNumber);
	}

	menu_display(id, gVoteMenu, iPage);
	if( access(id, VOTEDAY_ACCESS) )
			gVoting += WEIGHT_ADMIN;
		else
			gVoting += WEIGHT_PLAYER;
			
	clear_bit(g_bHasClosedMenu, id);
	g_iAreWeInaVote = true;

	return PLUGIN_HANDLED;
}

new iPage;
public menu_handler(id, gVoteMenu, item)
{
	//If the menu was exited or if there is not a vote
	if( item == MENU_EXIT || !gVoting )
	{
		set_bit(g_bHasClosedMenu, id);
		menu_destroy(gVoteMenu);
		return PLUGIN_HANDLED;
	}
	if(get_bit(g_bHasVotedAlready, id))
	{
		player_menu_info(id, gVoteMenu, gVoteMenu, iPage); 
		StartVote(id, iPage);
		return PLUGIN_HANDLED;
	}
	
	new data[6], name[64];
	new access, callback;
	menu_item_getinfo(gVoteMenu, item, access, data, charsmax(data), name, charsmax(name), callback);
	
	new szKey = str_to_num(data);
	
	new szName[32]; get_user_name(id, szName, 31);

	if( !get_bit(g_bHasVotedAlready, id) && get_user_flags(id) & VOTEDAY_ACCESS)
	{
		gVotes[szKey] += WEIGHT_ADMIN;
		fnColorPrint(0, "%L", LANG_SERVER, "JB_DAY_M13", '^3', szName, '^1', LANG_SERVER, g_iStartDayNames[ szKey ], '^4', '^1', '^4');
	}
	else if( !get_bit(g_bHasVotedAlready, id) )
	{
		gVotes[szKey] += WEIGHT_PLAYER;
		fnColorPrint(0, "%L", LANG_SERVER, "JB_DAY_M14", '^3', szName, '^1', LANG_SERVER, g_iStartDayNames[ szKey ], '^4', '^1', '^4');
	}

	set_bit(g_bHasVotedAlready, id);
	player_menu_info(id, gVoteMenu, gVoteMenu, iPage); 
	StartVote(id, iPage);

	return PLUGIN_HANDLED;
	
}

public EndVote()
{
	g_DayTimer--;
	if( g_DayTimer >= 0 )
	{
		static iPlayers[32], iNum, iPlayer, i;
		get_players( iPlayers, iNum ); 
		for( i = 0; i < iNum; i++ )
		{
			iPlayer = iPlayers[i];
			player_menu_info(iPlayer, gVoteMenu, gVoteMenu, iPage); 
			if(!get_bit(g_bHasClosedMenu, iPlayer))
				StartVote(iPlayer, iPage);
		}
	}
	
	if( g_DayTimer <= 5 )
	{
		new sSound[16];
		num_to_word(g_DayTimer, sSound, 15);
		client_cmd(0, "spk vox/%s.wav", sSound);
	}
	
	if( g_DayTimer <= 0 ) // if for some reason it glitches and gets below zero
	{
		remove_task(TASK_DAYTIMER);
		new bigger = 0;
		for( new i=1; i<g_iStartDay; i++ )
		{
			if( gVotes[i] > gVotes[bigger] )
			{
				bigger = i;
			}
		}
		
		if( bigger == 0 )
		{
			bigger = random_num(1,13);
			fnColorPrint(0, "%L", LANG_SERVER, "JB_DAY_M15");
		}

		EXEC_DayAction( 0, bigger);
		gVoting = 0;
		g_DayTimer = 0;
		for( new i=1; i<g_iStartDay; i++ )
		{
			gVotes[i] = 0;
		}
	}
}

EXEC_DayAction( id, iValue )
{
	switch( iValue )
	{
		case 1: g_iDay[ TOTAL_DAYS ] = DAY_GRAVITY;
		case 2: g_iDay[ TOTAL_DAYS ] = DAY_FREEDAY;
		case 3: g_iDay[ TOTAL_DAYS ] = DAY_ZOMBIE;
		case 4: g_iDay[ TOTAL_DAYS ] = DAY_LAVA;
		case 5: g_iDay[ TOTAL_DAYS ] = DAY_SHARK;
		case 6: g_iDay[ TOTAL_DAYS ] = DAY_CAGE;
		case 7: g_iDay[ TOTAL_DAYS ] = DAY_DEATHMATCH;
		case 8: g_iDay[ TOTAL_DAYS ] = DAY_NIGHT;
		case 9: g_iDay[ TOTAL_DAYS ] = DAY_SPARTAN;
		case 10: g_iDay[ TOTAL_DAYS ] = DAY_HIDENSEEK;
		case 11: g_iDay[ TOTAL_DAYS ] = DAY_REZOMBIE;
		case 12: g_iDay[ TOTAL_DAYS ] = DAY_RESHARK;
		case 13: g_iDay[ TOTAL_DAYS ] = DAY_RENIGHT;
		case 14: g_iDay[ TOTAL_DAYS ] = DAY_FREEZETAG;
	}
	
	static iPlayers[32], iNum, i, iPlayer;
	get_players(iPlayers, iNum); 
	
	new newmenu;
	for( i = 0; i < iNum; i++ )
	{
		iPlayer = iPlayers[i];
		clear_bit(g_bHasVotedAlready, iPlayer);
		if( player_menu_info(iPlayer, gVoteMenu, newmenu) )
		{
			menu_cancel(iPlayer);
			client_cmd(iPlayer, "slot1" );
		}
		clear_bit(g_bHasClosedMenu, iPlayer);
	}
	iPage = 0;
	do_specialday(id);
	g_iAreWeInaVote = false;
}

public specialday_menu(id)
{
	new gMenu[256];
	formatex( gMenu, charsmax(gMenu), "%L", LANG_SERVER, "JB_DAYMENU_TITLE");
	
	new specialdaymenu = menu_create( gMenu, "specialday_submenu" );
	
	new iNumber[5], szOption[64];
	for( new i = 1; i < g_iStartDay; i++ )
	{
		num_to_str(i, iNumber, 4);
		formatex(szOption, 63, "%L ", LANG_SERVER, g_iStartDayNames[i]);
		menu_additem(specialdaymenu, szOption, iNumber);
	}
		
	menu_setprop(specialdaymenu, MPROP_EXIT, MEXIT_ALL);
	menu_display(id, specialdaymenu, 0);
}

public specialday_submenu(id, specialdaymenu, item)
{
	if (item == MENU_EXIT)
	{
		menu_destroy(specialdaymenu);
		return PLUGIN_HANDLED;
	}
	
	if(!get_bit(g_bIsConnected, id))
		return PLUGIN_HANDLED;
	
	if(!get_bit(g_bIsAlive, id))
	{
		menu_destroy(specialdaymenu);
		fnColorPrint(id, "%L", LANG_SERVER, "JB_USER_DEAD");
		return PLUGIN_HANDLED;
	}
	
	new data[7], name[64];
	new access, callback;
	menu_item_getinfo(specialdaymenu, item, access, data, charsmax(data), name, charsmax(name), callback);
	
	new Key = str_to_num(data);
	for( new i = 1; i < g_iStartDay; i++ )
		g_iDay[ i ] = Key;

	g_iAdminDay = get_pcvar_num(cvar_pointer[cvar_admindaywait]) + 1;
	do_specialday(id);
	menu_destroy(specialdaymenu);
	return PLUGIN_HANDLED;
}

public do_specialday(id)
{
	if(g_bDayHasStarted)
	{
		return PLUGIN_HANDLED;
	}
	if(g_iDay[ TOTAL_DAYS ] == DAY_DEATHMATCH)
	{
		iRandom = random( sizeof(szWeapons) );
	}
	
	if(g_bBoxMatch)
	{
		fnColorPrint(0, "%L", LANG_SERVER, "JB_DAY_M16");
		g_bBoxMatch = false;
	}
	switch(g_iDay[ TOTAL_DAYS ])
	{
		case DAY_GRAVITY: server_cmd("sv_gravity %d", GRAVITY_DAY);
		case DAY_LAVA: server_cmd("decalfrequency 5");
		case DAY_HIDENSEEK:
		{
			g_Timer = 90;
			g_bFrozenTime = true;
			set_task( 1.0, "countdown", TASK_HNS );
		}
		case DAY_FREEZETAG:
		{
			server_cmd("sv_gravity %d", FREEZETAG_GRAVITY);
			g_FrozenT = 0;
		}
		case DAY_ZOMBIE:
		{
			set_lights(g_iZombieDayLights);
			if(get_pcvar_num(cvar_pointer[cvar_fogeffect]) == 1)
				fog(true);
		}
		case DAY_REZOMBIE:
		{
			set_lights(g_iZombieDayLights);
			if(get_pcvar_num(cvar_pointer[cvar_fogeffect]) == 1)
				fog(true);
		}
	}
	g_bCanBuy = false;
	
	if(pev_valid(iEnt))
	{
		fnColorPrint(0, "%L", LANG_SERVER, "JB_DAY_M21");
		ExecuteHamB(Ham_Use, iEnt, 0, 0, 1, 1.0);
	}
	else {
		fnColorPrint(0, "%L", LANG_SERVER, "JB_DAY_M22");
		OpenDoors("func_door");
		OpenDoors("func_door_rotating");
	}
		
	if(!g_bAlreadyOpened) {
		remove_task( TASKID );
		g_bCanBuy = false;
		g_bAutoOpened = true;
		g_bAlreadyOpened = true;
		
	}
	g_bDayHasStarted = true;
	if(!g_iAreWeInaVote)
	{
		new szName[ 32 ]; get_user_name(id, szName, 31);
		fnColorPrint(0, "%L", LANG_SERVER, "JB_DAY_M23", '^3', szName, '^1', '^3', LANG_SERVER, g_iStartDayNames[ g_iDay[ TOTAL_DAYS ] ] );
	}
	else {
		fnColorPrint(0, "%L", LANG_SERVER, "JB_DAY_M24", '^3', LANG_SERVER, g_iStartDayNames[ g_iDay[ TOTAL_DAYS ] ] );
	}
	
	static iPlayers[32], iNum, i, iPlayer;
	get_players( iPlayers, iNum, "a" ); 
	for ( i=0; i<iNum; i++ ) 
	{
		iPlayer = iPlayers[i];
		set_player_day(iPlayer);
	}
		
	return PLUGIN_HANDLED;
}

set_player_day(const iPlayer)
{
	static CsTeams:team;
	team = cs_get_user_team(iPlayer);
	new g_AliveCT = fnGetCounterTerrorists();
	new g_AliveT = fnGetTerrorists();
		
	if(get_bit(g_bIsSimon, iPlayer))
	{
		fnColorPrint(iPlayer, "%L", LANG_SERVER, "JB_DAY_M17");
		set_task(0.1, "ResetSimon");
		clear_bit(g_bIsSimon, iPlayer);
	}
	if(get_bit(g_bHasNadepack, iPlayer)) {
		ham_strip_weapon(iPlayer, "weapon_flashbang");
		ham_strip_weapon(iPlayer, "weapon_hegrenade");
		ham_strip_weapon(iPlayer, "weapon_smokegrenade");
		g_iPoints[iPlayer] += get_pcvar_num(cvar_pointer[cvar_nadepackprice]);
		fnColorPrint(iPlayer, "%L", LANG_SERVER, "JB_DAY_M18");
		clear_bit(g_bHasNadepack, iPlayer);
	}
	switch(g_iDay[ TOTAL_DAYS ])
	{
		case DAY_FREEDAY:
			if(team == CS_TEAM_T)
				set_user_rendering(iPlayer, kRenderFxGlowShell, 255, 140, 0, kRenderNormal, 20); 
		
		case DAY_ZOMBIE:
		{
			switch(team)
			{
				case CS_TEAM_T: GiveItem(iPlayer, "weapon_ak47", 900);
				case CS_TEAM_CT:
				{
					SaveWeapons(iPlayer);
					cs_set_user_nvg(iPlayer,true);
					//engclient_cmd(iPlayer, "nightvision");
					
					set_user_health(iPlayer, g_AliveT * g_100HP + g_100HP);
					set_user_maxspeed(iPlayer, ZOMBIE_SPEED);
					if (get_user_weapon(iPlayer) == CSW_KNIFE) 
					{
						new iWeapon = get_pdata_cbase(iPlayer, m_pActiveItem, XO_PLAYER);
						ExecuteHamB(Ham_Item_Deploy, iWeapon);
					}
				}
			}
		}
		
		case DAY_SHARK:
		{
			switch(team)
			{
				case CS_TEAM_T: GiveItem(iPlayer, "weapon_awp", 30);
				case CS_TEAM_CT:
				{
					SaveWeapons(iPlayer);
					set_user_noclip(iPlayer, 1);
					set_user_health(iPlayer, g_AliveT * g_25HP + g_100HP);
				}
			}
		}
		
		case DAY_DEATHMATCH:
		{
			SaveWeapons(iPlayer);
			GiveItem(iPlayer, szWeapons[iRandom], iBpAmmo[iRandom]);
		}
		
		case DAY_NIGHT:
		{
			switch(team)
			{
				case CS_TEAM_T:
				{
					GiveItem(iPlayer, "weapon_m4a1", 90);
					GiveItem(iPlayer, "weapon_deagle", 35);
				}
				case CS_TEAM_CT:
				{
					SaveWeapons(iPlayer);
					set_user_footsteps(iPlayer, 1);
					set_user_maxspeed(iPlayer, NIGHTCRAWLER_SPEED);
				}
			}
		}
		
		case DAY_SPARTAN:
		{
			switch(team)
			{
				case CS_TEAM_T:
				{
					GiveItem(iPlayer, "weapon_deagle", 150);
					give_item(iPlayer, "weapon_shield");
				}
				case CS_TEAM_CT:
				{
					SaveWeapons(iPlayer);
					GiveItem(iPlayer, "weapon_m4a1", 150);
				}
			}
		}
		case DAY_REZOMBIE:
		{
			switch(team)
			{
				case CS_TEAM_CT:
				{
					SaveWeapons(iPlayer);
					GiveItem(iPlayer, "weapon_ak47", 900);
				}
				case CS_TEAM_T:
				{
					cs_set_user_nvg(iPlayer,true);
					//engclient_cmd(iPlayer, "nightvision");
					set_user_health(iPlayer, g_AliveCT * g_100HP + g_100HP );
					set_user_maxspeed(iPlayer, REZOMBIE_SPEED);
					if (get_user_weapon(iPlayer) == CSW_KNIFE) 
					{
						new iWeapon = get_pdata_cbase(iPlayer, m_pActiveItem, XO_PLAYER);
						ExecuteHamB(Ham_Item_Deploy, iWeapon);
					}
				}
			}
		}
		case DAY_RESHARK:
		{
			switch(team)
			{
				case CS_TEAM_CT:
				{
					SaveWeapons(iPlayer);
					set_user_health(iPlayer, g_AliveT * g_10HP + g_100HP);	
					GiveItem(iPlayer, "weapon_awp", 30);
				}
				case CS_TEAM_T:
				{
					set_user_noclip(iPlayer, 1);
					set_user_health(iPlayer, g_AliveCT * g_10HP + g_50HP);
				}
			}
		}
		case DAY_RENIGHT:
		{
			switch(team)
			{
				case CS_TEAM_CT:
				{
					SaveWeapons(iPlayer);
					set_user_health(iPlayer, g_AliveT * g_10HP + g_100HP);
					GiveItem(iPlayer, "weapon_m4a1", 90);
					GiveItem(iPlayer, "weapon_deagle", 35);
				}
				case CS_TEAM_T:
				{
					set_user_footsteps(iPlayer, 1);
					set_user_maxspeed(iPlayer, RENIGHTCRAWLER_SPEED);
				}
			}
		}
		case DAY_FREEZETAG:
		{
			SaveWeapons(iPlayer);
			if(get_bit(g_bHasSpeed, iPlayer)) {
				fnColorPrint(iPlayer, "%L", LANG_SERVER, "JB_DAY_M19");
				fnColorPrint(iPlayer, "%L", LANG_SERVER, "JB_DAY_M20");
				g_iPoints[iPlayer] += get_pcvar_num(cvar_pointer[cvar_speedprice]);
				clear_bit(g_bHasSpeed, iPlayer);
				ExecuteHamB(Ham_Player_ResetMaxSpeed, iPlayer);
			}
		}
	}
}

public countdown()
{	
	static iPlayers[32], iNum, i, iPlayer;
	get_players( iPlayers, iNum, "ae", "CT" ); 
	
	set_hudmessage(255, 255, 255, -1.0, -1.0, 0, 0.75, 0.75, 0.75, 0.75, 1);
	if( g_Timer > 60 )
		show_hudmessage(0, "%L", LANG_SERVER, "JB_DAY_M25", g_Timer-60);
		
	if( g_Timer == 60 )
		for ( i=0; i<iNum; i++ ) 
		{
			iPlayer = iPlayers[i];
			set_pev(iPlayer, pev_flags, pev(iPlayer, pev_flags) | FL_FROZEN);
		}
			
	if( g_Timer <= 60 && g_Timer > 0 )
	{
		show_hudmessage(0, "%L", LANG_SERVER, "JB_DAY_M26", g_Timer);
		if( g_Timer <= 10 )
		{
			new sSound[16];
			num_to_word(g_Timer, sSound, 15);
			client_cmd(0, "spk vox/%s.wav", sSound);
		}
		for ( i=0; i<iNum; i++ )
		{
			iPlayer = iPlayers[i];
			UTIL_ScreenFade(iPlayer, 1.0, 1.0);
		}
	}
	g_Timer--;
	set_task( 1.0, "countdown", TASK_HNS );
	if( g_iDay[ TOTAL_DAYS ] == DAY_NONE )
		g_Timer = 0;
		
	if( g_Timer <= 0 )
	{
		for ( i=0; i<iNum; i++ ) 
		{
			iPlayer = iPlayers[i];
			RestoreWeapons(iPlayer);
			Unfreeze(iPlayer);
		}
		g_bFrozenTime = false;
		show_hudmessage(0, "%L", LANG_SERVER, "JB_DAY_M27");
		client_cmd(0, "spk ^"sound/radio/com_go.wav^"");
		remove_task( TASK_HNS );
	}
}

#define CLAMP_SHORT(%1) clamp( %1, 0, 0xFFFF )
#define CLAMP_BYTE(%1) clamp( %1, 0, 0xFF )

UTIL_ScreenFade(id, Float:fDuration, Float:fHoldTime) {
	message_begin( MSG_ONE_UNRELIABLE, g_iMsgId_ScreenFade, _, id);
	write_short(CLAMP_SHORT(floatround(4096 * fDuration))); // 1 << 12 = 4096
	write_short(CLAMP_SHORT(floatround(4096 * fHoldTime)));
	write_short(0x0000); // FFADE_IN = 0x0000
	write_byte(0);
	write_byte(0);
	write_byte(0);
	write_byte(200);
	message_end();
}

/*================================================================================
 [Forwards / Events]
=================================================================================*/
public Fwd_PlayerSpawn_Post(id)
{
	if (!is_user_alive(id))
		return HAM_HANDLED;
		
	set_bit(g_bIsAlive, id);
	
	static CsTeams:team;
	team = cs_get_user_team(id);

	switch(team)
	{
		case CS_TEAM_T:
		{
			clear_bit(g_bHasCrowbar, id);
			switch (get_pcvar_num(cvar_pointer[cvar_blockvoice]))
			{
				case 0: fm_set_speak(id, SPEAK_ALL);
				case 1: 
					if(get_user_flags(id) & ADMIN_MIC)
						fm_set_speak(id, SPEAK_ALL);
					else fm_set_speak(id, SPEAK_TEAM);
				case 2: 
					if(get_user_flags(id) & ADMIN_MIC)
						fm_set_speak(id, SPEAK_ALL);
					else fm_set_speak(id, SPEAK_LISTENALL);
			}
		}
		case CS_TEAM_CT: fm_set_speak(id, SPEAK_ALL);
	}
	
	if(g_iDay[ TOTAL_DAYS ] == DAY_NONE)
	{
		StripPlayerWeapons(id);
		reset_all(id);
		if(team == CS_TEAM_CT)
			set_task(0.4, "ClassMenu", id);
			
		new iWeapon = get_pdata_cbase(id, m_pActiveItem, XO_PLAYER);
		ExecuteHamB(Ham_Item_Deploy, iWeapon);
	}
	else set_player_day(id);
	
	return HAM_HANDLED;
}

public Fwd_TraceAttack_Player(victim, attacker, Float:flDamage, Float:flDirection[3], ptr, iDamagebits)
{
	// Not a valid attacker / no victim
	if (!IsPlayer(attacker))
		return HAM_IGNORED;

	g_bHeadShot[attacker][victim] = bool:( get_tr2(ptr, TR_iHitgroup) == HITGROUP_HEAD );
	return HAM_IGNORED;
}

public Fwd_PlayerDamage(victim, inflictor, attacker, Float:damage, bits)
{
	if(!IsPlayer( attacker ) || victim == attacker)
		return HAM_IGNORED;
		
	if(g_bBoxMatch)
	{
		g_iVictimTeam = cs_get_user_team_index(victim);
		if( g_iVictimTeam == cs_get_user_team_index(attacker) )
		{
			cs_set_user_team_index(victim, g_iVictimTeam == TEAM_T ? TEAM_CT : TEAM_T);
			EnableHamForward(g_iHhTakeDamagePost);
			return HAM_HANDLED;
		}
	}

	switch( g_iDay[ TOTAL_DAYS ] )
	{
		case DAY_DEATHMATCH:
		{	
			g_iVictimTeam = cs_get_user_team_index(victim);
			if( g_iVictimTeam == cs_get_user_team_index(attacker) )
			{
				cs_set_user_team_index(victim, g_iVictimTeam == TEAM_T ? TEAM_CT : TEAM_T);
				EnableHamForward(g_iHhTakeDamagePost);
				return HAM_HANDLED;
			}
		}
		case DAY_HIDENSEEK:
			if( g_bFrozenTime )
				if(cs_get_user_team(attacker) == CS_TEAM_T)
					return HAM_SUPERCEDE;
		case DAY_FREEZETAG: return HAM_SUPERCEDE;
		case DAY_ZOMBIE:
			if(cs_get_user_team(attacker) == CS_TEAM_CT)
				SetHamParamFloat(4, (damage+10)-damage);
		case DAY_REZOMBIE:
			if(cs_get_user_team(attacker) == CS_TEAM_T)
				SetHamParamFloat(4, (damage+10)-damage);
				
	}
	
	if(get_bit(g_bInDisguise, victim))
	{
		cs_reset_user_model(victim);
		fnColorPrint(victim, "%L", LANG_SERVER, "JB_DAY_M28");
		fnColorPrint(victim, "%L", LANG_SERVER, "JB_DAY_M29");
		clear_bit(g_bInDisguise, victim);
	}

	if(attacker == inflictor && get_user_weapon(attacker) == CSW_KNIFE && get_bit(g_bHasCrowbar, attacker))
	{
		SetHamParamFloat(4, damage + 35);
		return HAM_HANDLED;
	}

	return HAM_IGNORED;
}

public Player_TakeDamage_Post(victim)
{
	if( g_iDay[ TOTAL_DAYS ] == DAY_DEATHMATCH || g_bBoxMatch)
	{
		cs_set_user_team_index(victim, g_iVictimTeam);
		DisableHamForward( g_iHhTakeDamagePost );
	}
}  

public RespawnPlayer(id)
{
	if(g_iDay[ TOTAL_DAYS ] != DAY_NONE)
	{
		ExecuteHamB(Ham_CS_RoundRespawn, id);
		set_user_health(id, get_user_health(id) + (g_50HP * g_iDeaths[id]));
	}
}

public Fwd_PlayerKilled_Pre(victim, attacker, shouldgib)
{
	if (!IsPlayer(victim))
		return HAM_IGNORED;
		
	clear_bit(g_bIsAlive, victim);
		
	if(get_bit(g_bHasCrowbar, victim))
		g_iCrowbars--;
	
	if(get_bit(g_bHasSpeed, victim))
		g_iSpeed--;
		
	if(get_bit(g_bHasInvis, victim))
		g_iInvis--;

	if(get_bit(g_bHasFootstep, victim))
		g_iFootstep--;	
		
	if(get_bit(g_bHasDisguise, victim))
	{
		g_iDisguise--;
		cs_reset_user_model(victim);
		clear_bit(g_bHasDisguise, victim);
		clear_bit(g_bInDisguise, victim);
	}
	
	if(get_bit(g_bHasCellKeys, victim))
		g_iCellKeys--;
	
	if(get_bit(g_bInMathProblem, victim)) {
		set_user_rendering(victim, _, 0, 0, 0, _, 0);
		// Unfreeze player if it's frozen
		//static Flags; Flags = entity_get_int( victim, EV_INT_flags );
		//entity_set_int( victim, EV_INT_flags, Flags &~ FL_FROZEN );
		clear_bit(g_bInMathProblem, victim);
	}
	
	if(get_bit(g_bIsSimon, victim)){
		set_task(0.1, "ResetSimon");
		clear_bit(g_bIsSimon, victim);
	}

	// Get info
	new vName[32];
	get_user_name(victim, vName, charsmax(vName));		
	// Check if they are something special to annoy them lol
	if( get_bit(g_bIsChosen, victim) || get_bit(g_bIsLast, victim) && g_bInLr )
	{
		// Advertise
		if (g_iGameType == 10)
		{
			//fnColorPrint(0, "OMG! %s sucks! He died as Rambo", vName)
			if(get_user_team(victim) == 1) 
			{
				remove_task(victim+TASK_BEAM);
				clear_bit(g_bIsLast, victim);
				g_bInLr = false;
			}
		}
		else {
			fnColorPrint(0, "%L", LANG_SERVER, "JB_DAY_M30", '^3', vName, '^1', '^4', LANG_SERVER, fnGetGameType());

			for (new i = 1; i <= g_iMaxPlayers; i++)
			{
				remove_task(i+TASK_BEAM);
				clear_bit(g_bIsLast, i);
				clear_bit(g_bIsChosen, i);
				g_bInLr = false;
			}
		}
	}
	
	// Hide Terrorist's name/give points for kill by Kruegs (soccdooccs)
	if (get_user_team(attacker) == 1 && get_user_team(victim) == 2)
	{
		g_iPoints[attacker] += get_pcvar_num(cvar_pointer[cvar_killpoints]);
		
		if(g_bHeadShot[attacker][victim])
		{
			g_bHeadShot[attacker][victim] = false;
			g_iPoints[attacker] += get_pcvar_num(cvar_pointer[cvar_headshotpoints]);
			
		}
		SaveData(attacker);
		
		ExecuteHamB(Ham_Killed, victim, 0, shouldgib);
		set_pev(attacker, pev_frags, pev(attacker, pev_frags) + 1.0);
		
		return HAM_SUPERCEDE;
	}
	
	switch( g_iDay[ TOTAL_DAYS ] ) {
		case DAY_ZOMBIE:
			if(cs_get_user_team(victim) == CS_TEAM_CT)
			{
				g_iDeaths[victim]++;
				set_task(10.0*g_iDeaths[victim], "RespawnPlayer", victim);
				fnColorPrint(victim, "%L", LANG_SERVER, "JB_DAY_M31", (10*g_iDeaths[victim]));
			}
		case DAY_REZOMBIE:
			if(cs_get_user_team(victim) == CS_TEAM_T)
			{
				g_iDeaths[victim]++;
				set_task(10.0*g_iDeaths[victim], "RespawnPlayer", victim);
				fnColorPrint(victim, "%L", LANG_SERVER, "JB_DAY_M31", (10*g_iDeaths[victim]));
			}
	}
	
	if( g_iDay[ TOTAL_DAYS ] == DAY_FREEZETAG )
		CheckTerrorist( );
		
	return HAM_IGNORED;
}

public Fwd_PlayerTouch( Touched, Toucher )
{
	if( g_iDay[ TOTAL_DAYS ] == DAY_FREEZETAG )
	{
		if( IsPlayer(Toucher) )
		{
			static Flags; Flags = entity_get_int( Touched, EV_INT_flags );
				
			// Freeze an enemy
			if( cs_get_user_team(Toucher) == CS_TEAM_CT && cs_get_user_team(Touched) == CS_TEAM_T )
			{
				// Already frozen ?
				if( Flags & FL_FROZEN )
					return;

				entity_set_int( Touched, EV_INT_flags, Flags | FL_FROZEN );
				g_iTagCount[ Touched ]++;
				g_FrozenT++;
				set_bit(g_bIsTag, Touched);
				
				// msg		
				static dName[ 33 ]; get_user_name( Touched, dName, charsmax( dName ) );
				static rName[ 33 ]; get_user_name( Toucher, rName, charsmax( rName ) );
				fnColorPrint( 0, "%L", LANG_SERVER, "JB_DAY_M32", '^3', '^4', dName, '^1', '^4', rName, '^1'); 
	
				// Check if all the terrorist are frozen
				CheckTerrorist( );
				if(g_iTagCount[ Touched ] < 2)
					if( is_user_admin( Touched ) )
						set_user_rendering( Touched, kRenderFxGlowShell, 0, 255, 0, kRenderNormal, 40 );
					else set_user_rendering( Touched, kRenderFxGlowShell, 255, 0, 0, kRenderNormal, 40 );
				else set_user_rendering( Touched, kRenderFxGlowShell, 255, 255, 0, kRenderNormal, 40 );
			}
			
			// Unfreeze a teammate
			if( cs_get_user_team(Toucher) == CS_TEAM_T && cs_get_user_team(Touched) == CS_TEAM_T )
			{
				if( Flags & FL_FROZEN && g_iTagCount[ Touched ] < 2 )
				{
					// msg		
					static dName[ 33 ]; get_user_name( Touched, dName, charsmax( dName ) );
					static rName[ 33 ]; get_user_name( Toucher, rName, charsmax( rName ) );
					fnColorPrint( 0, "%L", LANG_SERVER, "JB_DAY_M33", '^3', '^4', dName, '^1', '^4', rName, '^1'); 
					
					Unfreeze( Touched );
					
					set_user_rendering( Touched );
				}
				if( Flags & FL_FROZEN && g_iTagCount[ Touched ] >= 2 )
				{
					g_iPoints[Toucher] += get_pcvar_num(cvar_pointer[cvar_killpoints]);
					fnColorPrint( Touched, "%L", LANG_SERVER, "JB_DAY_M34", '^3', '^1'); 
					Unfreeze(Touched);
					set_user_rendering(Touched);
					user_silentkill(Touched);
				}
			}
		}
	}
}

public Unfreeze( id ){
	// Unfreeze player if it's frozen
	static Flags; Flags = entity_get_int( id, EV_INT_flags );
	entity_set_int( id, EV_INT_flags, Flags &~ FL_FROZEN );
	
	if( get_bit(g_bIsTag, id) )
	{
		g_FrozenT--;
		clear_bit(g_bIsTag, id);
	}
}

// Check if all the terrorist are frozen
CheckTerrorist( )
{
	new g_prisonors = fnGetTerrorists();
	new g_LastPrisoner = g_prisonors - 1;
	if( g_LastPrisoner == g_FrozenT )
	{
		static iPlayers[32], iNum, i, iPlayer;
		get_players( iPlayers, iNum, "ae", "TERRORIST"  ); 
		for( i=0; i<iNum; i++ )
		{
			iPlayer = iPlayers[i];
			g_iTagCount[iPlayer] = 0;
			if( get_bit(g_bIsTag, iPlayer) )
			{
				Unfreeze(iPlayer);
				user_silentkill(iPlayer);
			}
		}
		g_FrozenT = 0;	
	}
}

public sound_emit(id, channel, sample[])
{
	if(get_bit(g_bIsAlive, id) && equal(sample, "weapons/knife_", 14) && get_bit(g_bHasCrowbar, id))
	{
		switch(sample[17])
		{
			case('b'): emit_sound(id, CHAN_WEAPON, "weapons/cbar_hitbod2.wav", 1.0, ATTN_NORM, 0, PITCH_NORM);
			case('w'): emit_sound(id, CHAN_WEAPON, "weapons/cbar_hit1.wav", 1.0, ATTN_NORM, 0, PITCH_LOW);
			case('1', '2'): emit_sound(id, CHAN_WEAPON, "weapons/bullet_hit2.wav", random_float(0.5, 1.0), ATTN_NORM, 0, PITCH_NORM);
			case('s'): emit_sound(id, CHAN_WEAPON, "weapons/cbar_miss1.wav", 1.0, ATTN_NORM, 0, PITCH_NORM);
		}
		return FMRES_SUPERCEDE;
	}
	return FMRES_IGNORED;
}

public ClCmd_drop(id)
{
	if (get_bit(g_bHasCrowbar,id) && (get_user_weapon(id) == CSW_KNIFE)) 
	{
		clear_bit(g_bHasCrowbar, id);
		new iWeapon = get_pdata_cbase(id, m_pActiveItem, XO_PLAYER);
		ExecuteHamB(Ham_Item_Deploy, iWeapon);
		spawn_crowbar(id);
		return PLUGIN_HANDLED;
	}
	
	return PLUGIN_CONTINUE;	
}

public spawn_crowbar(id)
{
	new iEntity;
	new Float:where[3];
	
	iEntity = create_entity("info_target");
	set_pev(iEntity, pev_classname, g_szClassNameCrowbar);
	set_pev(iEntity, pev_solid, SOLID_TRIGGER);
	set_pev(iEntity, pev_movetype, MOVETYPE_BOUNCE);
	entity_set_model(iEntity, CrowbarModels[2]);
	pev(id, pev_origin, where);
	where[2] += 50.0;
	where[0] += random_float(-20.0, 20.0);
	where[1] += random_float(-20.0, 20.0);
	entity_set_origin(iEntity, where);
	where[0] = 0.0;
	where[2] = 0.0;
	where[1] = random_float(0.0, 180.0);
	entity_set_vector(iEntity, EV_VEC_angles, where);
	velocity_by_aim(id, 200, where);
	entity_set_vector(iEntity, EV_VEC_velocity, where);
	
	
	return PLUGIN_HANDLED;
}

public CrowbarTouch(id, world)	
{
	new Float:velocity[3];
	new Float:volume;
	entity_get_vector(id, EV_VEC_velocity, velocity);
	
	velocity[0] = (velocity[0] * 0.45);
	velocity[1] = (velocity[1] * 0.45);
	velocity[2] = (velocity[2] * 0.45);
	entity_set_vector(id, EV_VEC_velocity, velocity);
	volume = get_speed(id) * 0.005; 
	if (volume > 1.0) volume = 1.0;
	if (volume > 0.1) emit_sound(id, CHAN_AUTO, "debris/metal2.wav", volume, ATTN_NORM, 0, PITCH_NORM);
	return PLUGIN_CONTINUE;	
}

public Fwd_PlayerCrowbarTouch( const iEntity, const id )
{
	if(!IsPlayer(id))
		return HAM_IGNORED;
		
	if( get_bit(g_bIsAlive, id) && cs_get_user_team(id) == CS_TEAM_T && !get_bit(g_bHasCrowbar, id))
	{
		set_bit(g_bHasCrowbar, id);
		remove_entity(iEntity);
		if (get_user_weapon(id) == CSW_KNIFE) 
		{
			new iWeapon = get_pdata_cbase(id, m_pActiveItem, XO_PLAYER);
			ExecuteHamB(Ham_Item_Deploy, iWeapon);
		}
		emit_sound(id, CHAN_AUTO, "items/gunpickup2.wav", 1.0, ATTN_NORM, 0, PITCH_NORM);
	}
	return HAM_IGNORED;
}

public Player_ResetMaxSpeed(id)
{
	if(get_bit(g_bIsAlive, id))
	{
		if(get_bit(g_bHasSpeed, id))
		{
			new Float:maxSpeed = get_pcvar_float(cvar_pointer[cvar_shopspeed]);
			set_pev(id, pev_maxspeed, maxSpeed);
		}
		static CsTeams:team;
		team = cs_get_user_team(id);
			
		switch( g_iDay[ TOTAL_DAYS ] )
		{
			case DAY_ZOMBIE:
				if(team == CS_TEAM_CT)
					set_user_maxspeed(id, ZOMBIE_SPEED);
			case DAY_NIGHT:
				if(team == CS_TEAM_CT)
					set_user_maxspeed(id, NIGHTCRAWLER_SPEED);
			case DAY_REZOMBIE:
				if(team == CS_TEAM_T)
					set_user_maxspeed(id, REZOMBIE_SPEED);
			case DAY_RENIGHT:
				if(team == CS_TEAM_T)
					set_user_maxspeed(id, RENIGHTCRAWLER_SPEED);
		}
	}
}

public Fwd_ItemDeploy2_Post(weapon)
{
	// Get the owner of the weapon
	new id = get_pdata_cbase(weapon, m_pPlayer, OFFSET_LINUX);
	if(get_bit(g_bIsAlive, id))
	{
		if( get_bit(g_bHasCrowbar, id))
		{
			set_pev(id, pev_viewmodel2, CrowbarModels[1]);
			set_pev(id, pev_weaponmodel2, CrowbarModels[0]);
		}
		else if(g_iDay[ TOTAL_DAYS ] == DAY_ZOMBIE || g_iDay[ TOTAL_DAYS ] == DAY_REZOMBIE )
		{
			static CsTeams:team;
			team = cs_get_user_team(id);
			if(g_iDay[ TOTAL_DAYS ] == DAY_ZOMBIE && team == CS_TEAM_CT)
				set_pev(id, pev_viewmodel2, ZombieModels[0]);
			if(g_iDay[ TOTAL_DAYS ] == DAY_REZOMBIE && team == CS_TEAM_T)
				set_pev(id, pev_viewmodel2, ZombieModels[0]);
		}
		else {
			set_pev(id, pev_viewmodel2, "models/v_knife.mdl");
			set_pev(id, pev_weaponmodel2, "models/p_knife.mdl");
		}
	}
}

public Fwd_ItemDeploy_Post(weapon)
{
	// Get the owner of the weapon
	new id = get_pdata_cbase(weapon, m_pPlayer, OFFSET_LINUX);
	// The game isn't Shot4Shot
	if (g_iGameType != 2)
		return HAM_IGNORED;
	if (get_bit(g_bIsLast, id) || get_bit(g_bIsChosen, id))
		if( weapon != CSW_KNIFE )
			set_pdata_int(weapon, OFFSET_CLIPAMMO, 1, 4);
	return HAM_IGNORED;
}

public Fwd_Use_Pre(this, caller, activator, use_type, Float:value)
{
	if (caller != activator)
		return HAM_IGNORED;
	
	new Float:fNextUse;
	pev(this, pev_fuser4, fNextUse);
	
	new Float:fGametime = get_gametime();
	
	if (fNextUse > fGametime)
		return HAM_IGNORED;
	
	new class[32], sModel[32];
	pev(this, pev_classname, class, 32);
	pev(this, pev_model, sModel, 32);
	
	if( equal(sModel, szModel, 0) )
	{
		new szTargetName[32];
		get_user_name(caller, szTargetName, charsmax(szTargetName));
		if(g_bAutoOpened)
			g_bAutoOpened = false;
		else {
			static iTimeLeft, iMinutes, iSeconds;
			iTimeLeft = floatround(g_fRoundTime - (get_gametime() - g_fRoundStartTime),floatround_ceil);

			if(iTimeLeft <= 0)
			{
				iMinutes = 0;
				iSeconds = 0;
			}
			else {
				iMinutes = (iTimeLeft / 60);
				iSeconds = (iTimeLeft % 60);
			}
			
			if(caller > 0)
				fnColorPrint(0, "%L", LANG_SERVER, "JB_OPENCELLS", 
				'^3', szTargetName, '^1', '^4', '^1', 
				'^3', iMinutes, '^1', '^3', iSeconds > 9 ? "" : "0", iSeconds);
		}
				
		if (!g_bAlreadyOpened)
		{
			remove_task( TASKID );
			g_bAlreadyOpened = true;
			g_bCanBuy = false;
		}
			
		set_pev(this, pev_fuser4, fGametime + get_pdata_float(this, m_flWait, 5));
	}
	return HAM_IGNORED;
}

public Event_SendAudio()
	g_iBlockLastRequest = 1;
	
public EventRoundEnd()
{
	remove_task( TASKID );
	server_cmd("sv_gravity 800");
	g_bInLr = false;
	g_bAlreadyOpened = false;
	g_bAutoOpened = false;
	g_bCanBuy = true;
	g_bBoxMatch = false;
	g_iCrowbars = 0;
	g_iDisguise = 0;
	g_iFootstep = 0;
	g_iCellKeys = 0;
	g_iInvis = 0;
	g_iSpeed = 0;
	Day_Ends( );
}

/*================================================================================
 [Save/Load Points]
=================================================================================*/
public SaveData(id)
{	
	new vKey[32], vData[32];
	//Save their points  
	#if defined SAVE_METHOD_NICK
	formatex(vKey, 31, "%s-points", g_iAuth[id]);  
	#endif 
	#if defined SAVE_METHOD_IP
	formatex(vKey, 31, "%s-points", g_iAuthIP[id]); 
	#endif 
	#if defined SAVE_METHOD_ID
	formatex(vKey, 31, "%s-points", g_iAuthID[id]);  
	#endif 
	
	formatex(vData, 31, "%i", g_iPoints[id]);
	nvault_set(g_vault, vKey , vData);
}

public GetData(id)
{	
	new szKey[32];
	#if defined SAVE_METHOD_NICK
	formatex(szKey, 31, "%s-points", g_iAuth[id]);  
	#endif 
	#if defined SAVE_METHOD_IP
	formatex(szKey, 31, "%s-points", g_iAuthIP[id]);  
	#endif 
	#if defined SAVE_METHOD_ID
	formatex(szKey, 31, "%s-points", g_iAuthID[id]); 
	#endif 
	g_iPoints[id] = nvault_get( g_vault , szKey );
}

/*================================================================================
 [The Shop]
=================================================================================*/
public ClCmd_shop(id)
{
	if(!get_bit(g_bIsConnected, id))
		return PLUGIN_HANDLED;

	if(!get_pcvar_num(cvar_pointer[cvar_shop]))
	{
		fnColorPrint( id, "%L", LANG_SERVER, "JB_DAY_M35");
		return PLUGIN_HANDLED;
	}
	if(cs_get_user_team(id) != CS_TEAM_T)
	{
		fnColorPrint(id, "%L", LANG_SERVER, "JB_DAY_M36");
		return PLUGIN_HANDLED;
	}
	
	if(!g_bCanBuy)
	{
		fnColorPrint( id, "%L", LANG_SERVER, "JB_DAY_M37");
		return PLUGIN_HANDLED;
	}
	
	if(!get_bit(g_bIsAlive, id))
	{
		fnColorPrint( id, "%L", LANG_SERVER, "JB_USER_DEAD");
		return PLUGIN_HANDLED;
	}
	
	shopmenu(id);
	return PLUGIN_HANDLED;
}

public shopmenu(id)
{
	if(get_bit(g_bIsAlive, id) && cs_get_user_team(id) == CS_TEAM_T)
	{
		new szText[256];
		new points = g_iPoints[id];
		//g_bHasMenuOpen[id] = true
		set_bit(g_bHasMenuOpen, id);
		
		formatex(szText, charsmax(szText), "%L", LANG_SERVER, "JB_SHOP_TITLE", points);
		new shopmenu = menu_create(szText, "sub_shopmenu");
		
		formatex(szText, charsmax(szText), "%L", LANG_SERVER, "JB_SHOP_M1", get_pcvar_num(cvar_pointer[cvar_crowbarprice]), g_iCrowbars, get_pcvar_num(cvar_pointer[cvar_crowbarlimit]));
		menu_additem(shopmenu, szText, "1", 0);
		
		formatex(szText, charsmax(szText), "%L", LANG_SERVER, "JB_SHOP_M2", get_pcvar_num(cvar_pointer[cvar_armorprice]));
		menu_additem(shopmenu, szText, "2", 0);
		
		formatex(szText, charsmax(szText), "%L", LANG_SERVER, "JB_SHOP_M3", get_pcvar_num(cvar_pointer[cvar_nadepackprice]));
		menu_additem(shopmenu, szText, "3", 0);
		
		formatex(szText, charsmax(szText), "%L", LANG_SERVER, "JB_SHOP_M4", get_pcvar_num(cvar_pointer[cvar_invisprice]), g_iInvis, get_pcvar_num(cvar_pointer[cvar_invislimit]));
		menu_additem(shopmenu, szText, "4", 0);
		
		formatex(szText, charsmax(szText), "%L", LANG_SERVER, "JB_SHOP_M5", get_pcvar_num(cvar_pointer[cvar_speedprice]), g_iSpeed, get_pcvar_num(cvar_pointer[cvar_speedlimit]));
		menu_additem(shopmenu, szText, "5", 0);
		
		formatex(szText, charsmax(szText), "%L", LANG_SERVER, "JB_SHOP_M6", get_pcvar_num(cvar_pointer[cvar_footstepprice]), g_iFootstep, get_pcvar_num(cvar_pointer[cvar_footsteplimit]));
		menu_additem(shopmenu, szText, "6", 0);
		
		formatex(szText, charsmax(szText), "%L", LANG_SERVER, "JB_SHOP_M7", get_pcvar_num(cvar_pointer[cvar_disguiseprice]), g_iDisguise, get_pcvar_num(cvar_pointer[cvar_disguiselimit]));
		menu_additem(shopmenu, szText, "7", 0);
		
		formatex(szText, charsmax(szText), "%L", LANG_SERVER, "JB_SHOP_M8", get_pcvar_num(cvar_pointer[cvar_cellkeysprice]), g_iCellKeys, get_pcvar_num(cvar_pointer[cvar_cellkeyslimit]));
		menu_additem(shopmenu, szText, "8", 0);
		
		menu_setprop(shopmenu, MPROP_EXIT , MEXIT_ALL);
		menu_display(id, shopmenu, 0);
	}

	return PLUGIN_HANDLED;
}

public sub_shopmenu(id, shopmenu, item)  
{
	if(!get_bit(g_bIsConnected, id))
		return PLUGIN_HANDLED;
	if (item == MENU_EXIT || cs_get_user_team(id) == CS_TEAM_CT)
	{
		clear_bit(g_bHasMenuOpen, id);
		menu_destroy(shopmenu);
		return PLUGIN_HANDLED;
	}
	
	if (!get_bit(g_bIsAlive, id) || !g_bCanBuy)
	{
		clear_bit(g_bHasMenuOpen, id);
		menu_destroy(shopmenu);
		return PLUGIN_HANDLED;
	}
	
	new data[7], name[64];
	new access, callback;
	clear_bit(g_bHasMenuOpen, id);
	menu_item_getinfo(shopmenu, item, access, data, charsmax(data), name, charsmax(name), callback);
	
	new Key = str_to_num(data);
	
	switch (Key)
	{
		case 1:
		{
			if(g_iPoints[id] < get_pcvar_num(cvar_pointer[cvar_crowbarprice]))
			{
				fnColorPrint(id, "%L", LANG_SERVER, "JB_DAY_M38");
				return PLUGIN_HANDLED;
			}
			else {
				if(get_bit(g_bHasCrowbar, id))
				{
					fnColorPrint(id, "%L", LANG_SERVER, "JB_DAY_M39");
					return PLUGIN_HANDLED;
				}
				
				else if(g_iCrowbars >= get_pcvar_num(cvar_pointer[cvar_crowbarlimit]))
				{
					fnColorPrint(id, "%L", LANG_SERVER, "JB_DAY_M40");
					return PLUGIN_HANDLED;
				}
				else give_crowbar(id);
			}
		}
		
		case 2:
		{
			
			if(get_bit(g_bHasArmor, id))
			{
				fnColorPrint(id, "%L", LANG_SERVER, "JB_DAY_M39");
				return PLUGIN_HANDLED;
			}
			
			else if(g_iPoints[id] < get_pcvar_num(cvar_pointer[cvar_armorprice]))
			{
				fnColorPrint(id, "%L", LANG_SERVER, "JB_DAY_M38");
				return PLUGIN_HANDLED;
			}
			else give_armor(id);
		}
		
		case 3:
		{
			if(get_bit(g_bHasNadepack, id))
			{
				fnColorPrint(id, "%L", LANG_SERVER, "JB_DAY_M39");
				return PLUGIN_HANDLED;
			}
			
			else if(g_iPoints[id] < get_pcvar_num(cvar_pointer[cvar_nadepackprice]))
			{
				fnColorPrint(id, "%L", LANG_SERVER, "JB_DAY_M38");
				return PLUGIN_HANDLED;
			}
			else give_nadepack(id);
		}
		
		case 4:
		{
			if(get_bit(g_bHasInvis, id))
			{
				fnColorPrint(id, "%L", LANG_SERVER, "JB_DAY_M39");
				return PLUGIN_HANDLED;
			}
			
			else if(g_iPoints[id] < get_pcvar_num(cvar_pointer[cvar_invisprice]))
			{
				fnColorPrint(id, "%L", LANG_SERVER, "JB_DAY_M38");
				return PLUGIN_HANDLED;
			}
			
			else if(get_bit(g_bHasFreeday, id))
			{
				fnColorPrint(id, "%L", LANG_SERVER, "JB_DAY_M41");
				return PLUGIN_HANDLED;
			}
			else {
				if(g_iInvis >= get_pcvar_num(cvar_pointer[cvar_invislimit]))
				{
					fnColorPrint(id, "%L", LANG_SERVER, "JB_DAY_M42");
					return PLUGIN_HANDLED;
				}
				else give_invis(id);
			}
		}
		
		case 5:
		{
			if(get_bit(g_bHasSpeed, id))
			{
				fnColorPrint(id, "%L", LANG_SERVER, "JB_DAY_M39");
				return PLUGIN_HANDLED;
			}
			
			else if(g_iPoints[id] < get_pcvar_num(cvar_pointer[cvar_speedprice]))
			{
				fnColorPrint(id, "%L", LANG_SERVER, "JB_DAY_M38");
				return PLUGIN_HANDLED;
			}
			
			else if(g_iDay[ TOTAL_DAYS ] == DAY_FREEZETAG)
			{
				fnColorPrint(id, "%L", LANG_SERVER, "JB_DAY_M43");
				return PLUGIN_HANDLED;
			}
			else
			{
				if(g_iSpeed >= get_pcvar_num(cvar_pointer[cvar_speedlimit]))
				{
					fnColorPrint(id, "%L", LANG_SERVER, "JB_DAY_M44");
					return PLUGIN_HANDLED;
				}
				else give_speed(id);
			}
		}
		
		case 6:
		{
			if(get_bit(g_bHasFootstep, id))
			{
				fnColorPrint(id, "%L", LANG_SERVER, "JB_DAY_M39");
				return PLUGIN_HANDLED;
			}
			
			else if(g_iPoints[id] < get_pcvar_num(cvar_pointer[cvar_footstepprice]))
			{
				fnColorPrint(id, "%L", LANG_SERVER, "JB_DAY_M38");
				return PLUGIN_HANDLED;
			}
			else
			{
				if(g_iFootstep >= get_pcvar_num(cvar_pointer[cvar_footsteplimit]))
				{
					fnColorPrint(id, "%L", LANG_SERVER, "JB_DAY_M45");
					return PLUGIN_HANDLED;
				}
				else give_footstep(id);
			}
		}
		
		case 7:
		{
			if(get_bit(g_bHasDisguise, id))
			{
				fnColorPrint(id, "%L", LANG_SERVER, "JB_DAY_M39");
				return PLUGIN_HANDLED;
			}
			else if(g_iPoints[id] < get_pcvar_num(cvar_pointer[cvar_disguiseprice]))
			{
				fnColorPrint(id, "%L", LANG_SERVER, "JB_DAY_M38");
				return PLUGIN_HANDLED;
			}
			else
			{
				if(g_iDisguise >= get_pcvar_num(cvar_pointer[cvar_disguiselimit]))
				{
					fnColorPrint(id, "%L", LANG_SERVER, "JB_DAY_M46");
					return PLUGIN_HANDLED;
				}
				else give_disguise(id);
			}
		}
		case 8:
		{
			if(get_bit(g_bHasCellKeys, id))
			{
				fnColorPrint(id, "%L", LANG_SERVER, "JB_DAY_M39");
				return PLUGIN_HANDLED;
			}
			else if(g_iPoints[id] < get_pcvar_num(cvar_pointer[cvar_cellkeysprice]))
			{
				fnColorPrint(id, "%L", LANG_SERVER, "JB_DAY_M38");
				return PLUGIN_HANDLED;
			}
			else
			{
				if(g_iCellKeys >= get_pcvar_num(cvar_pointer[cvar_cellkeyslimit]))
				{
					fnColorPrint(id, "%L", LANG_SERVER, "JB_DAY_M47");
					return PLUGIN_HANDLED;
				}
				else give_cellkeys(id);
			}
		}

	}
	menu_destroy(shopmenu);
	return PLUGIN_HANDLED;
}

public give_crowbar(id)
{
	set_bit(g_bHasCrowbar, id);
	ham_strip_weapon(id, "weapon_knife");
	give_item(id, "weapon_knife");
	g_iCrowbars++;
	g_iPoints[id] -= get_pcvar_num(cvar_pointer[cvar_crowbarprice]);

	fnColorPrint(id, "%L", LANG_SERVER, "JB_DAY_M48");
	return PLUGIN_HANDLED;
}

public give_armor(id)
{
	set_bit(g_bHasArmor, id);
	set_user_armor(id, 100);
	fnColorPrint(id, "%L", LANG_SERVER, "JB_DAY_M49");
	g_iPoints[id] -= get_pcvar_num(cvar_pointer[cvar_armorprice]);

	return PLUGIN_HANDLED;
}

public give_nadepack(id)
{
	set_bit(g_bHasNadepack, id);
	give_item(id, "weapon_flashbang");
	give_item(id, "weapon_hegrenade");
	give_item(id, "weapon_smokegrenade");
	g_iPoints[id] -= get_pcvar_num(cvar_pointer[cvar_nadepackprice]);
	
	fnColorPrint(id, "%L", LANG_SERVER, "JB_DAY_M50");
	
	return PLUGIN_HANDLED;
}

public give_invis(id)
{
	new AlphaVal = get_pcvar_num(cvar_pointer[cvar_alphavalue]);
	set_bit(g_bHasInvis, id);
	set_user_rendering(id,kRenderFxGlowShell,0,0,0,kRenderTransAlpha,AlphaVal);
	g_iPoints[id] -= get_pcvar_num(cvar_pointer[cvar_invisprice]);
	
	g_iInvis++;
	fnColorPrint(id, "%L", LANG_SERVER, "JB_DAY_M51");
	return PLUGIN_HANDLED;
}

public give_speed(id)
{
	new Float:maxSpeed = get_pcvar_float(cvar_pointer[cvar_shopspeed]);
	set_bit(g_bHasSpeed, id);
	set_user_maxspeed(id,maxSpeed);
	g_iPoints[id] -= get_pcvar_num(cvar_pointer[cvar_speedprice]);
	
	g_iSpeed++;
	fnColorPrint(id, "%L", LANG_SERVER, "JB_DAY_M52");
	return PLUGIN_HANDLED;
}

public give_footstep(id)
{
	set_user_footsteps(id, 1);
	set_bit(g_bHasFootstep, id);
	g_iPoints[id] -= get_pcvar_num(cvar_pointer[cvar_footstepprice]);
	
	g_iFootstep++;
	fnColorPrint(id, "%L", LANG_SERVER, "JB_DAY_M53");
	return PLUGIN_HANDLED;
}

public give_disguise(id)
{
	set_bit(g_bHasDisguise, id);
	g_iPoints[id] -= get_pcvar_num(cvar_pointer[cvar_crowbarprice]);

	g_iDisguise++;
	fnColorPrint(id, "%L", LANG_SERVER, "JB_DAY_M54");
	fnColorPrint(id, "%L", LANG_SERVER, "JB_DAY_M55");
	return PLUGIN_HANDLED;
}

public give_cellkeys(id)
{
	set_bit(g_bHasCellKeys, id);
	g_iPoints[id] -= get_pcvar_num(cvar_pointer[cvar_cellkeysprice]);

	g_iCellKeys++;
	fnColorPrint(id, "%L", LANG_SERVER, "JB_DAY_M56");
	fnColorPrint(id, "%L", LANG_SERVER, "JB_DAY_M57");
	return PLUGIN_HANDLED;
}

/*================================================================================
 [Give/Take Points]
=================================================================================*/
public cmd_give_points(id,level,cid)
{
	if(!cmd_access(id,level,cid,3))
		return PLUGIN_HANDLED;

	new target[32], amount[21];
 
	read_argv(1, target, 31 );
	read_argv(2, amount, 20 );
 
	new player = cmd_target( id, target, 8 );
 
	if(!player) 
		return PLUGIN_HANDLED;
 
	new admin_name[32], player_name[32];
	get_user_name(id, admin_name, 31);
	get_user_name(player, player_name, 31);
 
	new pointnum = str_to_num(amount);
	
	g_iPoints[player] += pointnum;
 
	switch(get_cvar_num ("amx_show_activity"))
	{
		case 1: fnColorPrint( 0, "%L", LANG_SERVER, "JB_DAY_M58", pointnum, player_name);
		case 2: fnColorPrint( 0, "%L", LANG_SERVER, "JB_DAY_M59", admin_name, pointnum, player_name);
	}
	
	fnColorPrint(player, "%L", LANG_SERVER, "JB_DAY_M60", pointnum, g_iPoints[player]);
 
	SaveData(id);

	return PLUGIN_HANDLED;
}

public cmd_take_points(id,level,cid)
{
	if(!cmd_access (id, level, cid, 2))
		return PLUGIN_HANDLED;
 
	new target[32], amount[21];
 
	read_argv( 1, target, 31 );
	read_argv( 2, amount, 20 );
 
	new player = cmd_target( id, target, 8 );

	if(!player ) 
		return PLUGIN_HANDLED;
 
	new admin_name[32], player_name[32];
	get_user_name( id, admin_name, 31 );
	get_user_name( player, player_name, 31 );
 
	new pointnum = str_to_num( amount );
	
	if(g_iPoints[player] < pointnum)
	{
		fnColorPrint( id, "%L", LANG_SERVER, "JB_DAY_M61");
		return PLUGIN_HANDLED;
	}
	
	g_iPoints[player] -= pointnum;
	
	switch(get_cvar_num("amx_show_activity"))
	{
		case 1: fnColorPrint( 0, "%L", LANG_SERVER, "JB_DAY_M62", pointnum, player_name);
		case 2: fnColorPrint( 0, "%L", LANG_SERVER, "JB_DAY_M63", admin_name, pointnum, player_name);
	}
	
	fnColorPrint( player, "%L", LANG_SERVER, "JB_DAY_M64", pointnum, g_iPoints[player]);
 
	SaveData(id);
 
	return PLUGIN_HANDLED;
}

public cmd_reset_points(id,level,cid)
{
	if(!cmd_access(id,level,cid,2))
		return PLUGIN_HANDLED;
		
	new target[32];
 
	read_argv(1, target, 31);
 
	new player = cmd_target(id, target, 8);
 
	if(!player) 
		return PLUGIN_HANDLED;
 
	new admin_name[32], player_name[32];
	get_user_name(id, admin_name, 31);
	get_user_name(player, player_name, 31);
 
	g_iPoints[player] = 0;
 
	switch(get_cvar_num ("amx_show_activity"))
	{
		case 1: fnColorPrint( 0, "%L", LANG_SERVER, "JB_DAY_M65", player_name);
		case 2: fnColorPrint( 0, "%L", LANG_SERVER, "JB_DAY_M66", admin_name, player_name);
	}
	
	fnColorPrint(player, "%L", LANG_SERVER, "JB_DAY_M67");
 
	SaveData(id);

	return PLUGIN_HANDLED;
}

/*================================================================================
 [Open By 8:00/cell button stuff]
=================================================================================*/

public cmd_set_button(id,level,cid)
{
	if(!cmd_access(id,level,cid,1))
		return PLUGIN_HANDLED;
		
	new szTempModel[64];
	new szTempClass[64];
	new szTemp[64];
	new szTempEnt;
	new Map[32];
	new szKey[32];
	
	szTempEnt = GetAimingEnt(id);
	
	if( pev_valid(szTempEnt) )
	{
		entity_get_string( szTempEnt, EV_SZ_classname, szTempClass, charsmax( szTempClass ) );
		if( equal( szTempClass, "func_button" ) || equal( szTempClass, "func_rot_button" ) || equal( szTempClass, "button_target" ) )
		{
			pev(szTempEnt, pev_model, szTempModel, 63);
			iEnt = szTempEnt;
			log_amx("%s", iEnt);
			
			get_mapname(Map, 31);
			strtolower(Map);
			
			formatex(szKey , 31 , "%s" , Map);
			formatex(szTemp , 64, "%s#%s#", szTempModel, szTempClass);
			
			nvault_set(g_buttonvault , szKey , szTemp);
			fnColorPrint(id, "%L", LANG_SERVER, "JB_DAY_M68", szTempModel, szTempClass, Map);
		
		}
		else{
			fnColorPrint(id, "%L", LANG_SERVER, "JB_DAY_M69");
		}
	}
	else{
		fnColorPrint(id, "%L", LANG_SERVER, "JB_DAY_M70");
	}

	return PLUGIN_HANDLED;
}

GetAimingEnt(id)
{
	static Float:start[3], Float:view_ofs[3], Float:dest[3], i;
	
	pev(id, pev_origin, start);
	pev(id, pev_view_ofs, view_ofs);
	
	for( i = 0; i < 3; i++ )
	{
		start[i] += view_ofs[i];
	}
	
	pev(id, pev_v_angle, dest);
	engfunc(EngFunc_MakeVectors, dest);
	global_get(glb_v_forward, dest);
	
	for( i = 0; i < 3; i++ )
	{
		dest[i] *= 9999.0;
		dest[i] += start[i];
	}

	engfunc(EngFunc_TraceLine, start, dest, DONT_IGNORE_MONSTERS, id, 0);
	
	return get_tr2(0, TR_pHit);
}

public TASK_PushButton()
{
	if(g_iAreWeInaVote)
		remove_task( TASKID );
	else
	{
		static iTimeLeft, iMinutes, iSeconds;
		iTimeLeft = floatround(g_fRoundTime - (get_gametime() - g_fRoundStartTime),floatround_ceil);
	
		iMinutes = (iTimeLeft / 60);
		iSeconds = (iTimeLeft % 60);
		fnColorPrint(0, "%L", LANG_SERVER, "JB_DAY_M71", '^3', iMinutes, '^1', '^3', iSeconds > 9 ? "" : "0", iSeconds, '^1' );
		g_bCanBuy = false;
		if(pev_valid(iEnt))
		{
			g_bAutoOpened = true;
			ExecuteHamB(Ham_Use, iEnt, 0, 0, 1, 1.0);
		}
	}
}

public Get_Button()
{
	new szTemp[64];
	new Map[32];
	new szKey[32];
	new ButtonModel, ButtonClass;
	
	get_mapname(Map, 31);
	strtolower(Map);
	
	formatex(szKey , 31 , "%s" , Map);
	formatex(szTemp , 63, "%s#%s#", ButtonModel, ButtonClass); 
	nvault_get(g_buttonvault, szKey, szTemp, 255); 
	replace_all(szTemp , 255, "#", " ");
	
	parse(szTemp,szModel, 31, szClass, 31);  
	log_amx("%L", LANG_SERVER, "JB_DAY_M72", szModel[0], szClass[0]);

	ButtonClass = szClass[0];
	ButtonModel = szModel[0];
	
	return PLUGIN_HANDLED;
} 

public ButtonSpawn( Ent )
{
	new Mnumber[32];
	pev( Ent, pev_model, Mnumber, 31 );
	
	if( equali( Mnumber, szModel ) )
		iEnt = Ent;
}
/*================================================================================
 [Commands]
=================================================================================*/
public ClCmd_simon(id) {
	if(!get_bit(g_bIsConnected, id))
		return PLUGIN_HANDLED;
		
	// Not a terrorist
	if (get_user_team(id) != 2)
	{
		fnColorPrint(id, "%L", LANG_SERVER, "JB_DAY_M73");
		return PLUGIN_HANDLED;
	}
	// Not alive
	if (!get_bit(g_bIsAlive, id))
	{
		fnColorPrint(id, "%L", LANG_SERVER, "JB_USER_DEAD");
		return PLUGIN_HANDLED;
	}
	
	if(g_bInLr)
	{
		fnColorPrint(id, "%L", LANG_SERVER, "JB_DAY_M74");
		return PLUGIN_HANDLED;
	}
	
	// More than 1 terrorist
	if (fnGetTerrorists() < 1)
	{
		fnColorPrint(id, "%L", LANG_SERVER, "JB_DAY_M75");
		return PLUGIN_HANDLED;
	}
	
	if(g_iDay[ TOTAL_DAYS ] != DAY_NONE)
	{
		fnColorPrint(id, "%L", LANG_SERVER, "JB_DAY_M76");
		return PLUGIN_HANDLED;
	}
	if (fnGetSimons() > MAX_SIMONS)
	{
		fnColorPrint(id, "%L", LANG_SERVER, "JB_DAY_M77");
		return PLUGIN_HANDLED;
	}
	
	if(get_bit(g_bIsSimon, id))
	{
		fnColorPrint(id, "%L", LANG_SERVER, "JB_DAY_M78");
		clear_bit(g_bIsSimon, id);
		if (!task_exists(id+TASK_SIMONBEAM))
			remove_task(id+TASK_SIMONBEAM);
		return PLUGIN_HANDLED;
	}
	new szName[32]; get_user_name(id, szName, 31);
	fnColorPrint(0, "%L", LANG_SERVER, "JB_DAY_M79", '^3', szName, '^1', '^4', '^1', '^4', '^1', '^3', '^1');
	set_bit(g_bIsSimon, id);
	if (!task_exists(id+TASK_SIMONBEAM))
		set_task(3.0, "Task_SimonStartRing", id+TASK_SIMONBEAM, _, _, "b");
	show_SimonMenu(id);
	return PLUGIN_HANDLED;
}

#define SIMON_ITEMS 8
new const g_iSimonNames[SIMON_ITEMS][] = {
	"", 
	"JB_SIMON_M1", 
	"JB_SIMON_M2",
	"JB_SIMON_M3", 
	"JB_SIMON_M4",
	"JB_SIMON_M5", 
	"JB_SIMON_M6",
	"JB_SIMON_M7"
};

new const g_iAccessSimon[SIMON_ITEMS] = {
	0, 
	0, 
	0,
	0, 
	0,
	0, 
	0,
	ADMIN_SIMON
};

public show_SimonMenu(id)
{
	if(get_bit(g_bIsSimon, id))
	{
		new szText[256];
		formatex(szText, charsmax(szText), "%L", LANG_SERVER, "JB_SIMON_TITLE", g_szPluginPrefix);
		new simonmenu = menu_create(szText, "sub_simonmenu");
		
		new iNumber[5], szOption[40];
		for( new i = 1; i < SIMON_ITEMS; i++ ) {
			num_to_str(i, iNumber, 4);
			formatex(szOption, 39, "%L", LANG_SERVER, g_iSimonNames[i]);
			menu_additem(simonmenu, szOption, iNumber, g_iAccessSimon[i]);
		}
		
		menu_setprop(simonmenu, MPROP_EXIT , MEXIT_ALL);
		menu_display(id, simonmenu, 0);
	}
	return PLUGIN_HANDLED;
}

public sub_simonmenu(id, simonmenu, item)  
{
	if(!get_bit(g_bIsConnected, id))
		return PLUGIN_HANDLED;
		
	if (item == MENU_EXIT || cs_get_user_team(id) == CS_TEAM_T)
	{
		menu_destroy(simonmenu);
		return PLUGIN_HANDLED;
	}
	
	if (!get_bit(g_bIsAlive, id) || g_iDay[ TOTAL_DAYS ] != DAY_NONE || !get_bit(g_bIsSimon, id) || g_bInLr)
	{
		menu_destroy(simonmenu);
		return PLUGIN_HANDLED;
	}
	
	new data[7], name[64];
	new access, callback;
	menu_item_getinfo(simonmenu, item, access, data, charsmax(data), name, charsmax(name), callback);
	
	new Key = str_to_num(data);
	static szName[32];
	get_user_name(id, szName, 31);
	
	switch (Key)
	{
		case 1:
		{
			if(pev_valid(iEnt))
				ExecuteHamB(Ham_Use, iEnt, 0, 0, 1, 1.0);
				
			if(!g_bAlreadyOpened)
			{
				remove_task( TASKID );
				
				g_bCanBuy = false;
				
				fnColorPrint(0, "%L", LANG_SERVER, "JB_DAY_M80", '^3', '^4', szName, '^1');
				g_bAutoOpened = true;
				g_bAlreadyOpened = true;
			}
			show_SimonMenu(id);
		}
		case 2: {ClCmd_opendoors(id);show_SimonMenu(id);}
		case 3: {ClCmd_closedoors(id);show_SimonMenu(id);}
		case 4:
		{
			static iNum, iPlayers[32], iPlayer, i, Count;
			Count = 0;
			get_players(iPlayers, iNum, "ae", "TERRORIST");  
			
			for ( i=0; i<iNum; i++ ) 
			{
				iPlayer = iPlayers[i]; 
				if(get_bit(g_bHasFreeday, iPlayer))
					continue;
				Count++;
			}
			new iExtraPlayers = Count % 2; 
			if (iExtraPlayers)  
			{ 
				fnColorPrint(id, "%L", LANG_SERVER, "JB_DAY_M81", '^4', '^1', '^3'); 
				fnColorPrint(id, "%L", LANG_SERVER, "JB_DAY_M82"); 
			} 
			else if(g_bTeamDivided) 
			{ 
				for ( i=0; i<iNum; i++ ) 
				{
					iPlayer = iPlayers[i]; 
					if(get_bit(g_bHasFreeday, iPlayer))
						continue;
						
					set_user_rendering(iPlayer, _, 0, 0, 0, _, 0);
				}
				g_bTeamDivided = false; 
				fnColorPrint(id, "%L", LANG_SERVER, "JB_DAY_M83"); 
			} 
			else 
			{ 
				for(new maxPerTeam = (iNum / 2), g_iTeams[2], g_iTeam, iPlayer, i = 0; i < iNum; i++) 
				{ 
					iPlayer = iPlayers[i]; 
					if(get_bit(g_bHasFreeday, iPlayer))
						continue;
					
					g_iTeam = random_num(0, 1); 
					
					if(g_iTeams[g_iTeam] >= maxPerTeam) 
						g_iTeam = !g_iTeam; 
					else 
						g_iTeams[g_iTeam]++; 
					
					if( g_iTeam == 1 )
						set_user_rendering(iPlayer,kRenderFxGlowShell,255,0,0,kRenderNormal,16);
					if( g_iTeam == 0 )
						set_user_rendering(iPlayer,kRenderFxGlowShell,0,0,255,kRenderNormal,16);
				}
				
				fnColorPrint(0, "%L", LANG_SERVER, "JB_DAY_M84", '^3', '^4', szName, '^1', '^3', '^1'); 
				g_bTeamDivided = true; 
			} 
			show_SimonMenu(id);
		}
		case 5: {emit_sound(0, CHAN_AUTO, g_szSound_Bell, 1.0, ATTN_NORM, 0, PITCH_NORM);show_SimonMenu(id);}
		case 6:
		{
			fnColorPrint(0, "%L", LANG_SERVER, "JB_DAY_M85", '^3', '^4', szName, '^1'); 
			MathMenu(id);
		}
		case 7:
		{
			static g_iPlayer; 
			g_iPlayer = fnGetRandomPlayer();
			new szName1[32]; get_user_name(g_iPlayer, szName1, 31);
			if(g_iPlayer > 0 && !get_bit(g_bHasFreeday, g_iPlayer))
			{
				user_silentkill(g_iPlayer);
				fnColorPrint(0, "%L", LANG_SERVER, "JB_DAY_M86", '^3', '^4', szName, '^1', '^3', szName1); 
			}
			show_SimonMenu(id);
		}

	}
	menu_destroy(simonmenu);
	return PLUGIN_HANDLED;
}

public ResetSimon() {
	static iPlayers[32], iNum, i, iPlayer;
	get_players(iPlayers, iNum, "ae", "TERRORIST");  
	for ( i=0; i<iNum; i++ ) 
	{
		iPlayer = iPlayers[i];
		if(get_bit(g_bInMathProblem, iPlayer))
		{
			fnColorPrint(iPlayer, "%L", LANG_SERVER, "JB_DAY_M87");
			//static Flags; Flags = entity_get_int( iPlayer, EV_INT_flags );
			//entity_set_int( iPlayer, EV_INT_flags, Flags &~ FL_FROZEN );
			clear_bit(g_bInMathProblem, iPlayer);
			set_user_rendering(iPlayer, _, 0, 0, 0, _, 0);
		}
	}
}
//Thanks to gangien
public ClCmd_math(id) {
	new count = random_num(3, 6);
	new values[10];
	new operations[10];
	for(new i = 0; i < count; i++) {
		if(i < count - 1)
			operations[i] = random_num(0, 3);
		do {
			values[i] = random_num(1, 20);
		} while ((i > 0) && (values[i] == 0) && (operations[i - 1] == 3));
	}
	new solved = values[random_num(0, count - 1)];
	new str[256];
	new fl[16];
	for(new i = 0; i < count - 1; i++) 
		add(str, sizeof(str), "(");
	
	for(new i = 0; i < count; i++) {
		if(values[i] == solved)
			add(str, sizeof(str), "x");
		else {
			num_to_str(values[i], fl, sizeof(fl));
			add(str, sizeof(str), fl);
		}
		if(i > 0)
			add(str, sizeof(str), ")");
		
		if(i < count - 1)
			add(str, sizeof(str), g_iOperators[operations[i]]);
		
	}
	
	new Float:fValue = float(values[0]);
	for(new i = 1; i < count; i++)
	{
		switch(operations[i - 1]) 
		{
			case 0: fValue = floatadd(fValue, float(values[i]));
			case 1: fValue = floatsub(fValue, float(values[i]));
			case 2: fValue = floatmul(fValue, float(values[i]));
			case 3: fValue = floatdiv(fValue, float(values[i]));
		}
	}

	format(mathEquations[id], 127, "%L", LANG_SERVER, "JB_DAY_M89", str, fValue);
	mathAnswer[id] = solved;
	set_hudmessage(200, 155, 0, -1.0, 0.50, 0, 6.0, 1.0, 0.3, 0.5, 3);
	show_hudmessage(id, mathEquations[id]);
	set_task(1.0, "Task_StartMath", id+TASK_MATH, _, _, "b");
	return PLUGIN_HANDLED;
}

public Task_StartMath(id)
{
	// id = id - TASK_BEAM = id
	id -= TASK_MATH;
	
	// Avoid the task call if the user died
	if (!get_bit(g_bIsConnected, id) || !get_bit(g_bIsAlive, id) || !get_bit(g_bInMathProblem, id) || g_bInLr)
	{
		remove_task(id+TASK_MATH);
		return;
	}
	// Set the beam
	fnSetMath(id);
}

fnSetMath(id) {
	set_hudmessage(200, 155, 0, -1.0, 0.50, 0, 6.0, 1.1, 0.3, 0.5, 3);
	show_hudmessage(id, mathEquations[id]);
	set_user_rendering(id,kRenderFxGlowShell,255,255,255,kRenderNormal,16);
}

public ClCmd_nextproblem(id) {
	if( get_bit(g_bInMathProblem, id))
	{
		fnColorPrint(id, "%L", LANG_SERVER, "JB_DAY_M88");
		ClCmd_math(id);
	}
}

public ClCmd_Say(id)
{
	new Message[128];

	read_argv(1, Message, 127);
	remove_quotes(Message);

	new myAns[128];
	num_to_str(mathAnswer[id], myAns, 127);

	if( get_bit(g_bInMathProblem, id) && is_str_num(Message))
	{
		new szName[32]; get_user_name(id, szName, 31);
		if (equali(Message, myAns))
		{
			fnColorPrint(id, "%L", LANG_SERVER, "JB_DAY_M90");
			set_user_rendering(id, _, 0, 0, 0, _, 0);
			// Unfreeze player if it's frozen
			//static Flags; Flags = entity_get_int( id, EV_INT_flags );
			//entity_set_int( id, EV_INT_flags, Flags &~ FL_FROZEN );

			if (task_exists(id + TASK_MATH))
				remove_task(id + TASK_MATH);
				
			fnColorPrint(0, "%L", LANG_SERVER, "JB_DAY_M91", szName);
			clear_bit(g_bInMathProblem, id);
		}
		else {
			new Health = get_user_health(id);
			new hp;

			if (Health <= DMG_MATHQ)
			{
				if (Health == 1) {
					fnColorPrint(id, "%L", LANG_SERVER, "JB_DAY_M92");
					fnColorPrint(0, "%L", LANG_SERVER, "JB_DAY_M93", '^3', szName, '^1', '^4', '^1');
					fnColorPrint(0, "%L", LANG_SERVER, "JB_DAY_M94");
					//static Flags; Flags = entity_get_int( id, EV_INT_flags );
					//entity_set_int( id, EV_INT_flags, Flags &~ FL_FROZEN );
					clear_bit(g_bInMathProblem, id);
					set_user_rendering(id,kRenderFxGlowShell,255,255,0,kRenderNormal,16);
					return PLUGIN_HANDLED;
				} 
				else hp = 1;
			} 
			else hp = Health - DMG_MATHQ;

			set_user_health(id, hp);
			fnColorPrint(id, "%L", LANG_SERVER, "JB_DAY_M95", Health - hp);
		}
		return PLUGIN_HANDLED;
	}
	return PLUGIN_CONTINUE;
}

public MathMenu(id) { 
	if(!get_bit(g_bIsConnected, id)) 
		return PLUGIN_HANDLED;
		
	if(!get_bit(g_bIsSimon, id)) 
	{
		fnColorPrint(id, "%L", LANG_SERVER, "JB_DAY_M96");
		return PLUGIN_HANDLED;
	}
	
	if(g_bInLr)
	{
		fnColorPrint(id, "%L", LANG_SERVER, "JB_DAY_M97");
		return PLUGIN_HANDLED;
	}

	new szText[256];
	formatex(szText, charsmax(szText), "%L", LANG_SERVER, "JB_MATH_TITLE");
	new menu = menu_create(szText, "sub_mathmenu");
	
	new players[32], pnum, tempid; 
	new szName[32], szTempid[10]; 
	
	get_players(players, pnum, "ae", "TERRORIST"); 
	
	formatex(szText, charsmax(szText), "%L", LANG_SERVER, "JB_MATH_M1");
	menu_additem(menu, szText, "1", 0);
	
	for( new i; i<pnum; i++ ) { 
		tempid = players[i]; 
		
		if(get_bit(g_bInMathProblem, tempid) || get_bit(g_bHasFreeday, tempid)) 
			continue;
		get_user_name(tempid, szName, 31); 
		num_to_str(tempid, szTempid, 9); 
		menu_additem(menu, szName, szTempid, 0); 
	} 
	
	menu_display(id, menu); 
	return PLUGIN_HANDLED; 
}

public sub_mathmenu(id, menu, item) { 
	if(!get_bit(g_bIsConnected, id)) 
		return PLUGIN_HANDLED;
	if( item == MENU_EXIT || !get_bit(g_bIsSimon, id) || g_bInLr ) { 
		menu_destroy(menu); 
		return PLUGIN_HANDLED; 
	}
	
	new data[6], name[64]; 
	new access, callback; 
	menu_item_getinfo(menu, item, access, data, charsmax(data), name, charsmax(name), callback); 
	
	new tempid = str_to_num(data); 
	
	new szName[32], szName2[32]; 
	get_user_name(id, szName, 31); 
	get_user_name(tempid, szName2, 31);
	if(tempid == 1) {
		new players[32], pnum, iPlayer; 
		get_players(players, pnum, "ae", "TERRORIST");
		for( new i; i<pnum; i++ ) { 
			iPlayer = players[i]; 
			
			if(get_bit(g_bInMathProblem, iPlayer) || get_bit(g_bHasFreeday, iPlayer)) 
				continue;
	
			set_bit(g_bInMathProblem, iPlayer);
			ClCmd_math(iPlayer);
			fnColorPrint(iPlayer, "%L", LANG_SERVER, "JB_DAY_M98");
			//static Flags; Flags = entity_get_int(iPlayer, EV_INT_flags);
			//entity_set_int(iPlayer, EV_INT_flags, Flags | FL_FROZEN );
		} 
		fnColorPrint(0, "%L", LANG_SERVER, "JB_DAY_M99", '^3', '^4', szName, '^1', '^4', '^1');
	}else{
		fnColorPrint(0, "%L", LANG_SERVER, "JB_DAY_M100", '^3', '^4', szName, '^1', '^4', szName2, '^1');
		fnColorPrint(tempid, "%L", LANG_SERVER, "JB_DAY_M101");
		set_bit(g_bInMathProblem, tempid);
		ClCmd_math(tempid);
		//static Flags; Flags = entity_get_int(tempid, EV_INT_flags);
		//entity_set_int(tempid, EV_INT_flags, Flags | FL_FROZEN );
	}
	menu_destroy(menu); 
	show_SimonMenu(id);
	return PLUGIN_HANDLED; 
}  

public ClCmd_points(id)
	fnColorPrint(id, "%L", LANG_SERVER, "JB_DAY_M102", '^4', g_iPoints[id], '^1');
	
public ClCmd_boxmatch(id)
{
	if(g_iDay[ TOTAL_DAYS ] != DAY_NONE)
	{
		fnColorPrint(id, "%L", LANG_SERVER, "JB_DAY_M103");
		return PLUGIN_HANDLED;
	}
	if(g_bInLr)
	{
		fnColorPrint(id, "%L", LANG_SERVER, "JB_DAY_M104");
		return PLUGIN_HANDLED;
	}
	// Not alive
	if (!get_bit(g_bIsAlive, id))
	{
		fnColorPrint(id, "%L", LANG_SERVER, "JB_USER_DEAD");
		return PLUGIN_HANDLED;
	}
	// Not a terrorist
	if (get_user_team(id) == 1)
	{
		fnColorPrint(id, "%L", LANG_SERVER, "JB_DAY_M105");
		return PLUGIN_HANDLED;
	}
	new szName[32]; get_user_name(id, szName, 31);
	if(g_bBoxMatch)
	{
		g_bBoxMatch = false;
		fnColorPrint(0, "%L", LANG_SERVER, "JB_DAY_M106", '^3', szName, '^1', '^4', '^1');
	}
	else
	{
		g_bBoxMatch = true;
		fnColorPrint(0, "%L", LANG_SERVER, "JB_DAY_M107", '^3', szName, '^1', '^4', '^1');
	}
	return PLUGIN_HANDLED;
}
	
public ClCmd_closedoors(id) {
	if(g_bBufferDoors)
	{
		fnColorPrint(id, "%L", LANG_SERVER, "JB_DAY_M108");
		return PLUGIN_HANDLED;
	}
	if(g_bInLr)
	{
		fnColorPrint(id, "%L", LANG_SERVER, "JB_DAY_M104");
		return PLUGIN_HANDLED;
	}
	// Not alive
	if (!get_bit(g_bIsAlive, id))
	{
		fnColorPrint(id, "%L", LANG_SERVER, "JB_USER_DEAD");
		return PLUGIN_HANDLED;
	}
	// Not a counter-terrorist
	if (get_user_team(id) == 1 && !access(id, ADMIN_DOORS))
	{
		fnColorPrint(id, "%L", LANG_SERVER, "JB_DAY_M105");
		return PLUGIN_HANDLED;
	}
	g_bBufferDoors = true;
	set_task(2.0, "BufferDoors");
	CloseDoors("func_door");
	CloseDoors("func_door_rotating");
	new szName[32]; get_user_name(id, szName, 31); 
	fnColorPrint(0, "%L", LANG_SERVER, "JB_DAY_M109", '^3', szName, '^1', '^4', '^1');
	return PLUGIN_HANDLED;
}

public ClCmd_randomct(id) {
	if(g_bInLr)
	{
		fnColorPrint(id, "%L", LANG_SERVER, "JB_DAY_M104");
		return PLUGIN_HANDLED;
	}
	// Not alive
	if (!get_bit(g_bIsAlive, id))
	{
		fnColorPrint(id, "%L", LANG_SERVER, "JB_USER_DEAD");
		return PLUGIN_HANDLED;
	}
	// Not a counter-terrorist
	if (!access(id, ADMIN_RANDOM_CT_SWITCH))
	{
		fnColorPrint(id, "%L", LANG_SERVER, "JB_NOACCESS");
		return PLUGIN_HANDLED;
	}
	
	static g_iPlayer; 
	g_iPlayer = fnGetRandomPlayer();
	new szName[32]; get_user_name(id, szName, 31);
	new szName1[32]; get_user_name(g_iPlayer, szName1, 31);
	
	if(g_iPlayer > 0 && !get_bit(g_bHasFreeday, g_iPlayer) && get_user_team(g_iPlayer) == 1)
	{
		cs_set_user_team(g_iPlayer, CS_TEAM_CT);
		fnColorPrint(0, "%L", LANG_SERVER, "JB_DAY_M110", '^3', szName, '^1', '^3', szName1, '^1', '^4', '^1'); 
	}

	return PLUGIN_HANDLED;
}

public ClCmd_opendoors(id) {
	if(g_bBufferDoors)
	{
		fnColorPrint(id, "%L", LANG_SERVER, "JB_DAY_M108");
		return PLUGIN_HANDLED;
	}
	if(g_bInLr)
	{
		fnColorPrint(id, "%L", LANG_SERVER, "JB_DAY_M104");
		return PLUGIN_HANDLED;
	}
	// Not alive
	if (!get_bit(g_bIsAlive, id))
	{
		fnColorPrint(id, "%L", LANG_SERVER, "JB_USER_DEAD");
		return PLUGIN_HANDLED;
	}
	// Not a counter-terrorist
	if (get_user_team(id) == 2 && !access(id, ADMIN_DOORS))
	{
		fnColorPrint(id, "%L", LANG_SERVER, "JB_DAY_M105");
		return PLUGIN_HANDLED;
	}
	g_bBufferDoors = true;
	set_task(2.0, "BufferDoors");
	OpenDoors("func_door");
	OpenDoors("func_door_rotating");
	new szName[32]; get_user_name(id, szName, 31); 
	fnColorPrint(0, "%L", LANG_SERVER, "JB_DAY_M111", '^3', szName, '^1', '^4', '^1');
	return PLUGIN_HANDLED;
}

public BufferDoors()
	g_bBufferDoors = false;

CloseDoors( const szClassName[] ) {
	new iEntity = find_ent_by_class(ENG_NULLENT, szClassName);
	while( is_valid_ent( iEntity ) )
	{
		dllfunc(DLLFunc_Think, iEntity);
		iEntity = find_ent_by_class(iEntity, szClassName);
		//DispatchKeyValue(iEnt,"wait",2);
	}
}
//Thanks to connor
OpenDoors( const szClassName[] ) {
	new iEntity = find_ent_by_class(ENG_NULLENT, szClassName);
	while( is_valid_ent( iEntity ) )
	{
		dllfunc( DLLFunc_Use, iEntity, 0 );
		iEntity = find_ent_by_class(iEntity, szClassName);
		//DispatchKeyValue(iEnt,"wait",0);
	}
}

public ClCmd_channel(id)
{
	if(!get_bit(g_bIsConnected, id))
		return PLUGIN_HANDLED;
		
	fnColorPrint(id, "%L", LANG_SERVER, "JB_DAY_M112", '^3', g_iSpeakNames[ fm_get_speak(id) ] );
	// Not a guard
	if (get_user_team(id) != 2 && !access(id, ADMIN_MIC))
	{
		fnColorPrint(id, "%L", LANG_SERVER, "JB_DAY_M105");
		return PLUGIN_HANDLED;
	}
	if(!access(id, ADMIN_MIC))
	{
		fnColorPrint(id, "%L", LANG_SERVER, "JB_NOACCESS");
		return PLUGIN_HANDLED;
	}
	Show_MicMenu(id, iPage);
	return PLUGIN_HANDLED;
}

public Show_MicMenu(id, iPage) { 
	if(!get_bit(g_bIsConnected, id)) 
		return PLUGIN_HANDLED;
	
	new szText[256];
	formatex(szText, charsmax(szText), "%L", LANG_SERVER, "JB_MIC_TITLE");
	new menu = menu_create(szText, "sub_channelmenu");
	
	new players[32], pnum, tempid; 
	new szName[32], szTempid[10];
	new szOption[128];
	get_players(players, pnum); 
	
	for( new i; i<pnum; i++ ) { 
		tempid = players[i]; 
		fm_get_speak(tempid);
		get_user_name(tempid, szName, 31); 
		num_to_str(tempid, szTempid, 9);
		formatex(szOption, 127, "%L", LANG_SERVER, "JB_MIC_M1", szName, g_iSpeakNames[ fm_get_speak(tempid) ] );
		menu_additem(menu, szOption, szTempid);
	} 
	
	menu_display(id, menu, iPage); 
	return PLUGIN_HANDLED; 
}

public sub_channelmenu(id, menu, item) { 
	if(!get_bit(g_bIsConnected, id)) 
		return PLUGIN_HANDLED;
	if( item == MENU_EXIT ) { 
		menu_destroy(menu); 
		return PLUGIN_HANDLED; 
	}
	
	new data[6], name[64]; 
	new access, callback; 
	menu_item_getinfo(menu, item, access, data, charsmax(data), name, charsmax(name), callback); 
	
	new tempid = str_to_num(data); 
	
	new szName[32], szName2[32]; 
	get_user_name(id, szName, 31); 
	get_user_name(tempid, szName2, 31);
	
	switch( fm_get_speak(tempid) )
	{
		case 1: fm_set_speak(tempid, 2);
		case 2: fm_set_speak(tempid, 3);
		case 3: fm_set_speak(tempid, 4);
		case 4: fm_set_speak(tempid, 1);
	}

	if( id != tempid )
		fnColorPrint(tempid, "%L", LANG_SERVER, "JB_DAY_M113", '^3', szName, '^1', '^4', g_iSpeakNames[ fm_get_speak(tempid) ], '^1');

	player_menu_info(id, menu, menu, iPage); 
	Show_MicMenu(id, iPage);
	return PLUGIN_HANDLED; 
}  

public ClCmd_LastRequest(id)
{
	if(!get_bit(g_bIsConnected, id))
		return PLUGIN_HANDLED;
	// Not a terrorist
	if (get_user_team(id) != 1)
	{
		fnColorPrint(id, "%L", LANG_SERVER, "JB_DAY_M114");
		return PLUGIN_HANDLED;
	}
	
	// Not alive
	if (!get_bit(g_bIsAlive, id))
	{
		fnColorPrint(id, "%L", LANG_SERVER, "JB_USER_DEAD");
		return PLUGIN_HANDLED;
	}
		
	// More than 1 terrorist
	if (fnGetTerrorists() > 1)
	{
		fnColorPrint(id, "%L", LANG_SERVER, "JB_DAY_M115");
		return PLUGIN_HANDLED;
	}
	
	// Less than 1 Counter-terrorist
	if (fnGetCounterTerrorists() < 1)
	{
		fnColorPrint(id, "%L", LANG_SERVER, "JB_DAY_M116");
		return PLUGIN_HANDLED;
	}
	
	// Is he the last one?	
	if (get_bit(g_bIsLast, id))
	{
		// Check if there's a game
		if (g_iGameType)
		{
			// There's a battle in progress
			if (fnGetChosen())
			{
				fnColorPrint(id, "%L", LANG_SERVER, "JB_DAY_M117");
				return PLUGIN_HANDLED;
			}
			else if (g_iGameType == 10)
			{
				fnColorPrint(id, "%L", LANG_SERVER, "JB_DAY_M117");
				return PLUGIN_HANDLED;
			}
		}
	}
	
	// He's the last terrorist, open menu!
	Show_LastRequestMenu(id);
	fm_set_speak(id, SPEAK_ALL);
	return PLUGIN_HANDLED;
}		

public Task_StartRing(id)
{
	// id = id - TASK_BEAM = id
	id -= TASK_BEAM;
	
	// Avoid the task call if the user died
	if (!get_bit(g_bIsConnected, id) || !get_bit(g_bIsAlive, id))
	{
		remove_task(id+TASK_BEAM);
		return;
	}
	
	// Set the beam
	fnSetRing(id);
}

public Task_SimonStartRing(id)
{
	// id = id - TASK_BEAM = id
	id -= TASK_SIMONBEAM;
	
	// Avoid the task call if the user died
	if (!get_bit(g_bIsConnected, id) || !get_bit(g_bIsAlive, id) || !get_bit(g_bIsSimon, id) || g_bInLr)
	{
		remove_task(id+TASK_SIMONBEAM);
		return;
	}

	// Set the beam
	fnSetSimonRing(id);
}
#define LastRequest 10
new const g_iLastRequestNames[LastRequest][] = {
	"", 
	"JB_LASTREQUEST_M1", 
	"JB_LASTREQUEST_M2",
	"JB_LASTREQUEST_M3", 
	"JB_LASTREQUEST_M4",
	"JB_LASTREQUEST_M5", 
	"JB_LASTREQUEST_M6",
	"JB_LASTREQUEST_M7", 
	"JB_LASTREQUEST_M8",
	"JB_LASTREQUEST_M9"
};

/*================================================================================
 [Lr Menu]
=================================================================================*/
Show_LastRequestMenu(id)
{
	new alivenumm = fnGetCounterTerrorists();
	// Avoid Round End Last Request
	if (g_iBlockLastRequest)
	{
		fnColorPrint(id, "%L", LANG_SERVER, "JB_DAY_M118");
		return PLUGIN_HANDLED;
	}
	
	set_bit(g_bHasMenuOpen, id);
	set_bit(g_bIsLast, id);

	new szText[256];
	formatex(szText, charsmax(szText), "%L", LANG_SERVER, "JB_LASTREQUEST_TITLE");
	new rMenu = menu_create(szText, "LastRequestHandler");
	new iNumber[5], szOption[40];
	
	for( new i = 1; i < LastRequest; i++ ) {
		num_to_str(i, iNumber, 4);
		formatex(szOption, 39, "%L", LANG_SERVER, g_iLastRequestNames[i]);
		menu_additem(rMenu, szOption, iNumber);
	}

	if (alivenumm >= NUMBER_OF_GUARDS)
	{
		formatex(szText, charsmax(szText), "%L", LANG_SERVER, "JB_LASTREQUEST_M10");
		menu_additem(rMenu, szText, "10", 0);
	}
	else {
		formatex(szText, charsmax(szText), "%L", LANG_SERVER, "JB_LASTREQUEST_M10");
		menu_additem(rMenu, szText, "10", ADMIN_IMMUNITY);
	}

	menu_setprop(rMenu, MPROP_EXIT, MEXIT_ALL);
	menu_display(id, rMenu, 0);
	
	return PLUGIN_CONTINUE;
}

Show_PlayersMenu(id)
{
	new Pos[3], szName[32], Title[96];
	formatex(Title, charsmax(Title), "%L", LANG_SERVER, "JB_LASTREQUEST_SUB", LANG_SERVER, fnGetGameType());
	
	new pMenu = menu_create(Title, "PlayersHandler");
	if (g_iGameType == 10 || g_iGameType == 7)
	{
		formatex(Title, charsmax(Title), "%L", LANG_SERVER, "JB_LASTREQUEST_SUB_M1");
		menu_additem(pMenu, Title, "1", 0);
	}
	else
	{
		static iPlayers[32], iNum, i, iPlayer;
		get_players( iPlayers, iNum, "ae", "CT" ); 
		for ( i=0; i<iNum; i++ ) 
		{
			iPlayer = iPlayers[i];
			// Add them to the menu
			num_to_str(iPlayer, Pos, charsmax(Pos));
			get_user_name(iPlayer, szName, charsmax(szName));
		
			menu_additem(pMenu, szName, Pos);
			
		}
	}
	menu_setprop(pMenu, MPROP_EXIT, MEXIT_NEVER);
	menu_display(id, pMenu, 0);
}
	
public LastRequestHandler(id, rMenu, item)
{
	if (item == MENU_EXIT || !get_bit(g_bHasMenuOpen, id)) {
		menu_destroy(rMenu);
		return PLUGIN_HANDLED;
	}
	
	new name[64], data[6];
	new access, callback;
	menu_item_getinfo(rMenu, item, access, data, charsmax(data), name, charsmax(name), callback);
	
	new szKey = str_to_num(data);
	
	// Show CT's Menu + Set the gametype to the key chosen
	g_iGameType = szKey;
	Show_PlayersMenu(id);
	
	return PLUGIN_HANDLED;
}

#define Rebel 5
new const g_iRebelNames[Rebel][] = {
	"", 
	"JB_REBEL_M1", 
	"JB_REBEL_M2",
	"JB_REBEL_M3", 
	"JB_REBEL_M4"
};

#define S4S 10
new const g_iS4SNames[S4S][] = {
	"", 
	"JB_S4S_M1", //JB_S4S_M1 == random weapon
	"JB_S4S_M2",
	"JB_S4S_M3", 
	"JB_S4S_M4",
	"JB_S4S_M5", 
	"JB_S4S_M6",
	"JB_S4S_M7", 
	"JB_S4S_M8",
	"JB_S4S_M9"
};

#define WEAPON_TOSS 5
new const g_iWeaponTossNames[WEAPON_TOSS][] = {
	"", 
	"JB_S4S_M1", //JB_S4S_M1 == random weapon
	"JB_WEAPONTOSS_M2", // Grenage
	"JB_S4S_M3", //JB_S4S_M3 == Deagle
	"JB_S4S_M5" //JB_S4S_M5 == M4A1
};

public PlayersHandler(id, pMenu, item) {
	if(!get_bit(g_bIsConnected, id))
		return PLUGIN_HANDLED;
	if (item == MENU_EXIT || !get_bit(g_bHasMenuOpen, id)) {
		menu_destroy(pMenu);
		return PLUGIN_HANDLED;
	}
	
	// Not a terrorist
	if (get_user_team(id) != 1)
		return PLUGIN_HANDLED;
	
	// Not alive
	if (!get_bit(g_bIsAlive, id))
		return PLUGIN_HANDLED;
		
	// More than 1 terrorist
	if (fnGetTerrorists() > 1)
		return PLUGIN_HANDLED;
	
	if(get_bit(g_bIsAlive, id)) {
		if(g_iGameType == 10) {
	
			clear_bit(g_bHasMenuOpen, id);
			
			new szText[256];
			formatex(szText, charsmax(szText), "%L", LANG_SERVER, "JB_REBEL_TITLE");
			new rebelingmenu = menu_create(szText, "sub_rebelmenu");
			new iNumber[5], szOption[40];
			for( new i = 1; i < Rebel; i++ ) {
				num_to_str(i, iNumber, 4);
				formatex(szOption, 39, "%L", LANG_SERVER, g_iRebelNames[i]);
				menu_additem(rebelingmenu, szOption, iNumber);
			}
			menu_setprop(rebelingmenu, MPROP_EXIT, MEXIT_ALL);
			menu_display(id, rebelingmenu, 0);
			g_bGrenade = false;

		}
		else {
			
			new cName[32], Name[64], Data[6];
			new Access, Callback;
			menu_item_getinfo(pMenu, item, Access, Data, charsmax(Data), Name, charsmax(Name), Callback);
			get_user_name(id, cName, charsmax(cName));
		
			clear_bit(g_bHasMenuOpen, id);
			
			g_iFinalCT = str_to_num(Data);

			// Start the battle
			fnColorPrint(0, "%L", LANG_SERVER, "JB_DAY_M119", cName, '^4', LANG_SERVER, fnGetGameType(), '^1', '^4', Name);
			set_user_footsteps(id, 0);
			set_pev(id, pev_maxspeed, 250.0);
			// Make the rings
			set_task(3.0, "Task_StartRing", g_iFinalCT+TASK_BEAM, _, _, "b");
		
			// Avoid the task twice for the last terrorist
			if (!task_exists(id+TASK_BEAM))
				set_task(3.0, "Task_StartRing", id+TASK_BEAM, _, _, "b");
		
			// Reset health
			set_user_health(g_iFinalCT, 100);
			set_user_health(id, 100);	
	
			// Strip Weapons
			StripPlayerWeapons(id);
			StripPlayerWeapons(g_iFinalCT);
			g_bGrenade = false;
			
			// GameType = Key = Game
			switch (g_iGameType) 
			{
				case 1: {
					// No ideas here..
					fnColorPrint(0, "%L", LANG_SERVER, "JB_DAY_M120");
					fnColorPrint(0, "%L", LANG_SERVER, "JB_DAY_M121");
					server_cmd("sv_gravity 800");
				}
				case 2: {
					
					new szText[256];
					formatex(szText, charsmax(szText), "%L", LANG_SERVER, "JB_S4S_TITLE");
					new Shot4Shot = menu_create(szText, "Shot4Shot_submenu");
					
					// Give random weapon for Shot4Shot
					new iNumber[5], szOption[40];
					for( new i = 1; i < S4S; i++ ) {
						num_to_str(i, iNumber, 4);
						formatex(szOption, 39, "%L", LANG_SERVER, g_iS4SNames[i]);
						menu_additem(Shot4Shot, szOption, iNumber);
					}

					menu_setprop(Shot4Shot,MPROP_EXIT, MEXIT_ALL);
					menu_display(id, Shot4Shot, 0);
					
					server_cmd("sv_gravity 800");
				}
			
				case 3: {	
					new szText[128];
					formatex(szText, charsmax(szText), "%L", LANG_SERVER, "JB_RACE_TITLE");
					new race = menu_create(szText, "race_submenu");
					formatex(szText, charsmax(szText), "%L", LANG_SERVER, "JB_RACE_M1", RACE_TIMER);
					menu_additem(race, szText, "1", 0);
					menu_setprop(race,MPROP_EXIT, MEXIT_ALL);
					menu_display(id, race, 0);
					fnColorPrint(0, "%L", LANG_SERVER, "JB_DAY_M122");
					server_cmd("sv_gravity 800");
				}
			
				case 4: {
					// Give a random weapon for the gun toss
					new szText[256];
					formatex(szText, charsmax(szText), "%L", LANG_SERVER, "JB_WEAPONTOSS_TITLE");
					new Weapon_Toss = menu_create(szText, "Weapon_Toss_submenu");
					
					// Give random weapon for Shot4Shot
					new iNumber[5], szOption[40];
					for( new i = 1; i < WEAPON_TOSS; i++ ) {
						num_to_str(i, iNumber, 4);
						formatex(szOption, 39, "%L", LANG_SERVER, g_iWeaponTossNames[i]);
						menu_additem(Weapon_Toss, szOption, iNumber);
					}
		
					menu_setprop(Weapon_Toss,MPROP_EXIT, MEXIT_ALL);
					menu_display(id, Weapon_Toss, 0);
			
					// Empty clip ammo
					//set_pdata_int(Ent, OFFSET_CLIPAMMO, 0, OFFSET_LINUX)
					//set_pdata_int(Ent2, OFFSET_CLIPAMMO, 0, OFFSET_LINUX)
					server_cmd("sv_gravity 800");
				}
			
				case 5: {
					// No ideas here..
					fnColorPrint(0, "%L", LANG_SERVER, "JB_DAY_M123");
					server_cmd("sv_gravity 800");
				}
			
				case 6: {
					set_user_armor(id ,100);
					set_user_armor(g_iFinalCT ,100);
					GiveItem(id, "weapon_hegrenade", 1000);
					GiveItem(g_iFinalCT, "weapon_hegrenade", 1000);
					fnColorPrint(0, "%L", LANG_SERVER, "JB_DAY_M124");
					server_cmd("sv_gravity 800");
				}
				
				case 7: {
					explode_me(id);
					server_cmd("sv_gravity 800");
				}
				case 8: {
					GiveItem(id, "weapon_m3", 100);
					GiveItem(g_iFinalCT, "weapon_m3", 100);
					set_user_health(g_iFinalCT, 500);
					set_user_health(id, 500);
					set_user_armor(id ,100);
					set_user_armor(g_iFinalCT ,100);
					server_cmd("sv_gravity 800");
				}
				case 9: {
					GiveItem(id, "weapon_scout", 100);
					GiveItem(g_iFinalCT, "weapon_scout", 100);
					set_user_armor(id ,100);
					set_user_armor(g_iFinalCT ,100);
					server_cmd("sv_gravity %d", SCOUTDUAL_GRAVITY);	
				}
			}
			set_bit(g_bIsChosen, g_iFinalCT);
		}
		g_bInLr = true;
		clear_bit(g_bHasCrowbar, id);
	}
	return PLUGIN_HANDLED;
}

public sub_rebelmenu(id, rebelingmenu, item)
{
	if (item == MENU_EXIT)
	{
		menu_destroy(rebelingmenu);
		return PLUGIN_HANDLED;
	}
	if(!g_bInLr)
	{
		menu_destroy(rebelingmenu);
		return PLUGIN_HANDLED;
	}
	
	new data[7], name[64];
	new access, callback;
	menu_item_getinfo(rebelingmenu, item, access, data, charsmax(data), name, charsmax(name), callback);
	
	new Key = str_to_num(data);
	
	StripPlayerWeapons(id);
	new g_AliveCT = fnGetCounterTerrorists();
	switch (Key)
	{
		case 1:
		{
			// Start the battle
			fnColorPrint(0, "%L", LANG_SERVER, "JB_DAY_M125");
			StripPlayerWeapons(id);
			
			iRandom = random( sizeof(g_szWeaponList1) );
			GiveItem(id, g_szWeaponList1[iRandom], 600);
			
			set_user_health(id, g_AliveCT * g_100HP + g_100HP );
			set_user_armor(id, 100);
			set_user_footsteps(id, 0);
			set_pev(id, pev_maxspeed, 250.0);
		}
		
		case 2: 
		{
			StripPlayerWeapons(id);
			set_user_health(id, g_AliveCT * g_100HP + g_100HP );
			GiveItem(id, "weapon_deagle", 35);
			fnColorPrint(0, "%L", LANG_SERVER, "JB_DAY_M126");
		}
		
		case 3: 
		{	
			StripPlayerWeapons(id);
			set_user_health(id, 1);
			GiveItem(id, "weapon_ak47", 200);
			set_user_rendering(id, kRenderFxGlowShell, 0, 0, 0, kRenderTransAlpha, 15);
			fnColorPrint(0, "%L", LANG_SERVER, "JB_DAY_M127");
		}
		
		case 4: 
		{
			StripPlayerWeapons(id);
			set_user_health(id, g_AliveCT * g_100HP + g_100HP );
			GiveItem(id, "weapon_glock18", 200);
			set_user_rendering(id, kRenderFxGlowShell, 255, 0, 0, kRenderTransAlpha, 255);
			fnColorPrint(0, "%L", LANG_SERVER, "JB_DAY_M128");
		}
	}
	menu_destroy(rebelingmenu);
	return PLUGIN_HANDLED;
}

public Shot4Shot_submenu(id, Shot4Shot, item)
{
	if(item == MENU_EXIT)
	{
		menu_destroy(Shot4Shot);
		return PLUGIN_HANDLED;
	}
	if(!g_bInLr)
	{
		menu_destroy(Shot4Shot);
		return PLUGIN_HANDLED;
	}
	
	new data[7], name[64];
	new access, callback;
	menu_item_getinfo(Shot4Shot, item, access, data, charsmax(data), name, charsmax(name), callback);
	
	new key = str_to_num(data);
	static weapon;
	switch(key)
	{
		case 1: GiveRandomWeapon(id);
		case 2: weapon = give_item(g_iFinalCT, "weapon_usp")		& give_item(id, "weapon_usp");
		case 3: weapon = give_item(g_iFinalCT, "weapon_deagle")		& give_item(id, "weapon_deagle");
		case 4: weapon = give_item(g_iFinalCT, "weapon_fiveseven") 	& give_item(id, "weapon_fiveseven");
		case 5: weapon = give_item(g_iFinalCT, "weapon_m4a1")		& give_item(id, "weapon_m4a1");
		case 6: weapon = give_item(g_iFinalCT, "weapon_tmp")		& give_item(id, "weapon_tmp");
		case 7: weapon = give_item(g_iFinalCT, "weapon_m249")		& give_item(id, "weapon_m249");
		case 8: weapon = give_item(g_iFinalCT, "weapon_awp")		& give_item(id, "weapon_awp");
		case 9: weapon = give_item(g_iFinalCT, "weapon_scout")		& give_item(id, "weapon_scout");	
	}
	set_pdata_int(weapon, OFFSET_CLIPAMMO, 1, OFFSET_LINUX);
	menu_destroy( Shot4Shot );
	return PLUGIN_CONTINUE;
}
new g_iTime;
public race_submenu(id, race, item)
{
	if(item == MENU_EXIT)
	{
		menu_destroy(race);
		return PLUGIN_HANDLED;
	}
	if(!g_bInLr)
	{
		menu_destroy(race);
		return PLUGIN_HANDLED;
	}
	
	new data[7], name[64];
	new access, callback;
	menu_item_getinfo(race, item, access, data, charsmax(data), name, charsmax(name), callback);
	new count = RACE_TIMER;
	g_iTime = RACE_TIMER+1;
	new key = str_to_num(data);
	switch(key)
	{
		case 1: set_task(1.0, "TaskStartTimer", TASK_TIMER, _, _, "a", count+2);
	}
	menu_destroy( race );
	return PLUGIN_CONTINUE;
}

public TaskStartTimer(count) {
	switch(g_iTime--)
	{
		case 0:
		{
			client_cmd(0, "spk ^"sound/radio/com_go.wav^"");
			set_hudmessage(0, 255, 0, -1.0, -1.0, 1);
			show_hudmessage(0, "%L", LANG_SERVER, "JB_DAY_M27");
		}
		case 1..21:
		{
			new szTime[20];
			num_to_word(g_iTime, szTime, charsmax(szTime));
			client_cmd(0, "spk ^"fvox/%s.wav^"", szTime);
			set_hudmessage(255, 0, 0, -1.0, -1.0, 1);
			show_hudmessage(0, "%L", LANG_SERVER, "JB_DAY_M173", g_iTime);
		}
	}
}

public Weapon_Toss_submenu(id, Weapon_Toss, item)
{
	if(item == MENU_EXIT)
	{
		menu_destroy(Weapon_Toss);
		return PLUGIN_HANDLED;
	}
	if(!g_bInLr)
	{
		menu_destroy(Weapon_Toss);
		return PLUGIN_HANDLED;
	}
	
	new data[7], name[64];
	new access, callback;
	menu_item_getinfo(Weapon_Toss, item, access, data, charsmax(data), name, charsmax(name), callback);
	
	new key = str_to_num(data);
	static weapon;
	
	switch(key)
	{
		case 1: GiveRandomWeapon(id);
		case 2:
		{
			give_item(g_iFinalCT, "weapon_hegrenade");
			give_item(id, "weapon_hegrenade");
		}
		case 3:
		{
			weapon = give_item(g_iFinalCT, "weapon_deagle");
			weapon = give_item(id, "weapon_deagle");
			set_pdata_int(weapon, OFFSET_CLIPAMMO, 0, OFFSET_LINUX);  
		}
		case 4:
		{
			weapon = give_item(g_iFinalCT, "weapon_m4a1");
			weapon = give_item(id, "weapon_m4a1");
			set_pdata_int(weapon, OFFSET_CLIPAMMO, 0, OFFSET_LINUX);
		}
	}
	
	g_bGrenade = true;
	menu_destroy( Weapon_Toss );
	return PLUGIN_CONTINUE;
}

public GiveRandomWeapon(id)
{
	static weapon;
	iRandom = random( sizeof(szWeapons2) );
	
	weapon = give_item(g_iFinalCT, szWeapons2[iRandom]);
	weapon = give_item(id, szWeapons2[iRandom]);  

	if(g_iGameType != 2)
		set_pdata_int(weapon, OFFSET_CLIPAMMO, 0, OFFSET_LINUX);
}

public Fwd_Entity_Think( ent )
{
	if( !g_bInLr )
		return FMRES_IGNORED;
	
	if ( !pev_valid( ent ) )
		return FMRES_IGNORED;
	
	if( g_bGrenade )
	{
		static owner;
		owner = pev( ent, pev_owner );
		if(get_bit(g_bIsLast, owner) || get_bit(g_bIsChosen, owner))
		{
			new hit = -1, Float:origin[3];
			// Get the origin
			pev(ent, pev_origin, origin);
			
			while ((hit = find_ent_in_sphere(hit, origin, 18.2)))
			{
				if (hit > g_iMaxPlayers)
					break;
				
				if (!get_bit(g_bIsConnected, hit) && !get_bit(g_bIsAlive, hit))
					continue;
				
				return touch_em(ent, hit);
			}
			set_pev(ent, pev_nextthink, get_gametime() + 0.1);		
			return FMRES_SUPERCEDE;
		}
	}
	return FMRES_IGNORED;
}

touch_em(ent, id)
{
	new szClassname[32];
	pev(ent, pev_model, szClassname, charsmax(szClassname));
	
	if (contain(szClassname, "w_hegrenade.mdl") != -1)
	{
		
		// User can have the grenade, give it to him and remove it
		if (cs_get_user_bpammo(id, CSW_HEGRENADE) < 1)
		{
			if (cs_get_user_bpammo(id, CSW_HEGRENADE) == 0)
				give_item(id, "weapon_hegrenade");
			else cs_set_user_bpammo(id, CSW_HEGRENADE, cs_get_user_bpammo(id, CSW_HEGRENADE) + 1);
			
			// Remove and block engine call
			remove_entity(ent);
			return PLUGIN_HANDLED;
		}		
	}
	
	// If not then we set the next think and block again the engine call
	set_pev(ent, pev_nextthink, get_gametime() + 0.1);
	return HAM_SUPERCEDE;
}

public Fwd_Model_Think( ent )
{
	if( !g_bInLr )
		return FMRES_IGNORED;
	
	if ( !pev_valid( ent ) )
		return FMRES_IGNORED;
		
	static id;
	id = pev( ent, pev_owner );
	if(!IsPlayer(id))
		return FMRES_IGNORED;

	if(get_bit(g_bIsLast, id) || get_bit(g_bIsChosen, id))	
		if( g_bGrenade )
			switch(get_user_team(id))
			{
				case 1:set_rendering(ent,kRenderFxGlowShell,255,0,0,kRenderNormal,16);
				case 2:set_rendering(ent,kRenderFxGlowShell,0,0,255,kRenderNormal,16);
			}

	return FMRES_IGNORED;
}

/*================================================================================
 [Suicide Bomber]
=================================================================================*/

public explode_me(id) {
	// get my origin
	new Float:explosion[3];
	pev(id, pev_origin, explosion);

	user_kill(id);   

	// create explosion
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY);
	write_byte(TE_EXPLOSION);
	write_coord(floatround(explosion[0]));
	write_coord(floatround(explosion[1]));
	write_coord(floatround(explosion[2]));
	write_short(explosion_sprite);
	write_byte(30);
	write_byte(30);
	write_byte(0);
	message_end();

	fm_radius_damage(id, explosion, EXPLODE_DAMAGE, EXPLODE_RADIUS, "grenade");
}

stock fm_radius_damage(id, Float:orig[3], Float:dmg , Float:rad, wpnName[]="") {
	new szClassname[33], Float:Health;
	static Ent;
	Ent = -1;
	while((Ent = engfunc(EngFunc_FindEntityInSphere, Ent, orig, rad))) {
		pev(Ent,pev_classname,szClassname,32);
		if(!equali(szClassname, "player") && !get_bit(g_bIsConnected, Ent) && !get_bit(g_bIsAlive, Ent))
			continue;
			
		pev(Ent, pev_health, Health);
		Health -= dmg;
		
		new szName[32], szName1[32];
		get_user_name(Ent, szName, 31);
		get_user_name(id, szName1, 31);
		
		if(Health <= 0.0) 
			createKill(Ent, id, wpnName);
		else set_pev(Ent, pev_health, Health);
	}             
}

// stock for create kill
stock createKill(id, attacker, weaponDescription[]) {
	new szFrags, szFrags2;
	
	if(id != attacker) {
		szFrags = get_user_frags(attacker);
		set_user_frags(attacker, szFrags + 1);
		logKill(attacker, id, weaponDescription);
		   
		//Kill the victim and block the messages
		set_msg_block(g_iMsgDeath,BLOCK_ONCE);
		set_msg_block(g_iMsgScoreInfo,BLOCK_ONCE);
		user_kill(id);
		  
		//user_kill removes a frag, this gives it back
		szFrags2 = get_user_frags(id);
		set_user_frags(id, szFrags2 + 1);
		  
		//Replaced HUD death message
		message_begin(MSG_ALL, g_iMsgDeath,{0,0,0},0);
		write_byte(attacker);
		write_byte(id);
		write_byte(0);
		write_string(weaponDescription);
		message_end();
		  
		//Update killers scorboard with new info
		message_begin(MSG_ALL, g_iMsgScoreInfo);
		write_byte(attacker);
		write_short(szFrags);
		write_short(get_user_deaths(attacker));
		write_short(0);
		write_short(get_user_team(attacker));
		message_end();
		  
		//Update victims scoreboard with correct info
		message_begin(MSG_ALL, g_iMsgScoreInfo);
		write_byte(id);
		write_short(szFrags2);
		write_short(get_user_deaths(id));
		write_short(0);
		write_short(get_user_team(id));
		message_end();
		
		new szName[32], szName1[32];
		get_user_name(id, szName, 31);
		get_user_name(attacker, szName1, 31);
	}
}

// stock for log kill
stock logKill(id, victim, weaponDescription[] ) {
	new namea[32],namev[32],authida[35],authidv[35],teama[16],teamv[16];
   
	//Info On Attacker
	get_user_name(id,namea,31);
	get_user_team(id,teama,15);
	get_user_authid(id,authida,34);
   
	//Info On Victim
	get_user_name(victim,namev,31);
	get_user_team(victim,teamv,15);
	get_user_authid(victim,authidv,34);
   
	//Log This Kill
	if(id != victim)
		log_message("^"%s<%d><%s><%s>^" killed ^"%s<%d><%s><%s>^" with ^"%s^"",
		namea,get_user_userid(id),authida,teama,namev,get_user_userid(victim),authidv,teamv, weaponDescription );
	else
		log_message("^"%s<%d><%s><%s>^" committed suicide with ^"%s^"",
		namea,get_user_userid(id),authida,teama, weaponDescription );
}

/*================================================================================
 [Glow/UnGlow Menu]
=================================================================================*/
public JBGlowMenu(id) { 
	if(!get_bit(g_bIsConnected, id)) 
		return PLUGIN_HANDLED;
	if(!is_user_admin(id)) {
		if( cs_get_user_team( id ) != CS_TEAM_CT ) {
			fnColorPrint(id, "%L", LANG_SERVER, "JB_DAY_M129");
			return PLUGIN_HANDLED;
		}
		
		if(!get_bit(g_bIsAlive, id)) {
			fnColorPrint(id, "%L", LANG_SERVER, "JB_USER_DEAD");
			return PLUGIN_HANDLED;
		}
	}	
	new szText[128];
	formatex(szText, charsmax(szText), "%L", LANG_SERVER, "JB_GLOW_TITLE");
	new menu = menu_create(szText, "sub_menu");
	
	new players[32], pnum, tempid; 
	new szName[32], szTempid[10]; 
	
	set_bit(g_bHasMenuOpen, id);
	get_players(players, pnum, "ae", "TERRORIST"); 
	
	for( new i; i<pnum; i++ ) { 
		tempid = players[i]; 
		
		if(!get_bit(g_bHasFreeday, tempid)) {
			get_user_name(tempid, szName, 31); 
			num_to_str(tempid, szTempid, 9); 
			menu_additem(menu, szName, szTempid, 0); 
		}
	} 
	
	menu_display(id, menu); 
	return PLUGIN_HANDLED; 
}

public sub_menu(id, menu, item) { 
	if(!get_bit(g_bIsConnected, id)) 
		return PLUGIN_HANDLED;
	if( item == MENU_EXIT ) { 
		clear_bit(g_bHasMenuOpen, id);
		menu_destroy(menu); 
		return PLUGIN_HANDLED; 
	} 
	
	if(!is_user_admin(id)) {
		if( cs_get_user_team( id ) != CS_TEAM_CT )
			return PLUGIN_HANDLED;
		
		if(!get_bit(g_bIsAlive, id)) 
			return PLUGIN_HANDLED;
	}
	
	new data[6], name[64]; 
	new access, callback; 
	menu_item_getinfo(menu, item, access, data, charsmax(data), name, charsmax(name), callback); 
	
	new tempid = str_to_num(data); 
	new szName[32], szName2[32], szauth[32], szauth2[32]; 
	get_user_name(id, szName, 31); 
	get_user_name(tempid, szName2, 31);
	get_user_authid(id, szauth, 31);
	get_user_authid(tempid, szauth2, 31);
	
	set_user_rendering(tempid, kRenderFxGlowShell, 255, 140, 0, kRenderNormal, 20); 
	set_bit(g_bHasFreeday, tempid);
	clear_bit(g_bHasMenuOpen, id);
	fnColorPrint(0, "%L", LANG_SERVER, "JB_DAY_M130", szName, szName2);
	log_amx("%L", LANG_SERVER, "JB_DAY_M132", szName, szauth, szName2, szauth2);
	
	if(get_bit(g_bHasInvis, tempid)) {
		fnColorPrint(tempid, "%L", LANG_SERVER, "JB_DAY_M131");
		fnColorPrint(tempid, "%L", LANG_SERVER, "JB_DAY_M133");
		g_iPoints[tempid] += get_pcvar_num(cvar_pointer[cvar_invisprice]);
		clear_bit(g_bHasInvis, tempid);
		
		return PLUGIN_HANDLED;
	}
	
	menu_destroy(menu); 
	return PLUGIN_HANDLED; 
}  

public JBUnglowMenu(id) { 
	if(!get_bit(g_bIsConnected, id)) 
		return PLUGIN_HANDLED;
	if(!is_user_admin(id)) {
		if( cs_get_user_team( id ) != CS_TEAM_CT ) {
			fnColorPrint(id, "%L", LANG_SERVER, "JB_DAY_M134");
			return PLUGIN_HANDLED;
		}
		
		if(!get_bit(g_bIsAlive, id)) {
			fnColorPrint(id, "%L", LANG_SERVER, "JB_USER_DEAD");
			return PLUGIN_HANDLED;
		}
	}
	
	new szText[256];
	formatex(szText, charsmax(szText), "%L", LANG_SERVER, "JB_UNGLOW_TITLE");
	new menu = menu_create(szText, "Unglow_sub_menu");
	
	new players[32], pnum, tempid; 
	new szName[32], szTempid[10]; 
	
	set_bit(g_bHasMenuOpen, id);
	get_players(players, pnum, "a"); 
	
	for( new i; i<pnum; i++ ) {
		tempid = players[i]; 
		
		if (get_bit(g_bHasFreeday, tempid)) { 
			get_user_name(tempid, szName, 31); 
			num_to_str(tempid, szTempid, 9); 
			menu_additem(menu, szName, szTempid, 0);	
		}  
	} 
	
	menu_display(id, menu); 
	return PLUGIN_HANDLED; 
}

public Unglow_sub_menu(id, menu, item) { 
	if(!get_bit(g_bIsConnected, id)) 
		return PLUGIN_HANDLED;
	if( item == MENU_EXIT ) { 
		clear_bit(g_bHasMenuOpen, id);
		menu_destroy(menu); 
		return PLUGIN_HANDLED; 
	} 
	
	if(!is_user_admin(id)) {
		if( cs_get_user_team( id ) != CS_TEAM_CT ) {
			return PLUGIN_HANDLED;
		}
		
		if(!get_bit(g_bIsAlive, id)) {
			return PLUGIN_HANDLED;
		}
	}
	
	new data[6], name[64]; 
	new access, callback; 
	menu_item_getinfo(menu, item, access, data, charsmax(data), name, charsmax(name), callback); 
	
	clear_bit(g_bHasMenuOpen, id);
	new tempid = str_to_num(data); 
	new szName[32], szName2[32], szauth[32], szauth2[32]; 
	get_user_name(id, szName, 31); 
	get_user_name(tempid, szName2, 31);
	get_user_authid(id, szauth, 31);
	get_user_authid(tempid, szauth2, 31);
	
	set_user_rendering(tempid);
	clear_bit(g_bHasFreeday, tempid);
	fnColorPrint(0, "%L", LANG_SERVER, "JB_DAY_M135", szName, szName2);
	log_amx("%L", LANG_SERVER, "JB_DAY_M136", szName, szauth, szName2, szauth2);
	
	menu_destroy(menu); 
	return PLUGIN_HANDLED; 
} 

public Clcmd_GlowRed(id) { 
	if(!get_bit(g_bIsConnected, id)) 
		return PLUGIN_HANDLED;
	if(!is_user_admin(id)) {
		if( cs_get_user_team( id ) != CS_TEAM_CT ) {
			fnColorPrint(id, "%L", LANG_SERVER, "JB_DAY_M129");
			return PLUGIN_HANDLED;
		}
		
		if(!get_bit(g_bIsAlive, id)) {
			fnColorPrint(id, "%L", LANG_SERVER, "JB_USER_DEAD");
			return PLUGIN_HANDLED;
		}
	}
	
	new szTempClass[64];
	new player;
	
	player = GetAimingEnt(id);
	
	if(!pev_valid(player))
		return PLUGIN_HANDLED;
	
	pev(player, pev_classname, szTempClass, 63);
	
	if(equali(szTempClass, "player", 0)) {
		if(cs_get_user_team(player) == CS_TEAM_CT) {
			fnColorPrint(id, "%L", LANG_SERVER, "JB_DAY_M137");
			return PLUGIN_HANDLED;
		}
		
		if(get_bit(g_bHasFreeday, player)) {
			fnColorPrint(id, "%L", LANG_SERVER, "JB_DAY_M138");
			return PLUGIN_HANDLED;
		}
		set_user_rendering(player,kRenderFxGlowShell,255,0,0,kRenderNormal,16);
		set_bit(g_bIsGlowing, player);
		fnColorPrint(player, "%L", LANG_SERVER, "JB_DAY_M139");
	}
	else {
		fnColorPrint(id, "%L", LANG_SERVER, "JB_DAY_M140");
		return PLUGIN_HANDLED;
	}
	return PLUGIN_HANDLED; 
} 

public Clcmd_GlowBlue(id) { 
	if(!get_bit(g_bIsConnected, id)) 
		return PLUGIN_HANDLED;
	if(!is_user_admin(id)) {
		if( cs_get_user_team( id ) != CS_TEAM_CT ) {
			fnColorPrint(id, "%L", LANG_SERVER, "JB_DAY_M129");
			return PLUGIN_HANDLED;
		}
		
		if(!get_bit(g_bIsAlive, id)) {
			fnColorPrint(id, "%L", LANG_SERVER, "JB_USER_DEAD");
			return PLUGIN_HANDLED;
		}
	}
	
	new szTempClass[64];
	new player;
	
	player = GetAimingEnt(id);
	
	if(!pev_valid(player))
		return PLUGIN_HANDLED;
	
	pev(player, pev_classname, szTempClass, 63);
	
	if(equali(szTempClass, "player", 0)) {
		if(cs_get_user_team(player) == CS_TEAM_CT) {
			fnColorPrint(id, "%L", LANG_SERVER, "JB_DAY_M137");
			return PLUGIN_HANDLED;
		}
		if(get_bit(g_bHasFreeday, player)) {
			fnColorPrint(id, "%L", LANG_SERVER, "JB_DAY_M138");
			return PLUGIN_HANDLED;
		}
		set_user_rendering(player,kRenderFxGlowShell,0,0,255,kRenderNormal,16);
		set_bit(g_bIsGlowing, player);
		fnColorPrint(player, "%L", LANG_SERVER, "JB_DAY_M141");
	}
	else {
		fnColorPrint(id, "%L", LANG_SERVER, "JB_DAY_M140");
		return PLUGIN_HANDLED;
	}
	return PLUGIN_HANDLED; 
} 

public Clcmd_UnglowPlayer(id) { 
	if(!get_bit(g_bIsConnected, id)) 
		return PLUGIN_HANDLED;
	if(!is_user_admin(id)) {
		if( cs_get_user_team( id ) != CS_TEAM_CT ) {
			fnColorPrint(id, "%L", LANG_SERVER, "JB_DAY_M142");
			return PLUGIN_HANDLED;
		}
		if(!get_bit(g_bIsAlive, id)) {
			fnColorPrint(id, "%L", LANG_SERVER, "JB_USER_DEAD");
			return PLUGIN_HANDLED;
		}
	}
	new szTempClass[64];
	new player;
	new szName[32], szName2[32], szauth[32], szauth2[32]; 
	get_user_name(id, szName, 31); 
	get_user_name(player, szName2, 31);
	get_user_authid(id, szauth, 31);
	get_user_authid(player, szauth2, 31);
	
	player = GetAimingEnt(id);
	
	if(!pev_valid(player))
		return PLUGIN_HANDLED;
	
	pev(player, pev_classname, szTempClass, 63);
	
	if(equali(szTempClass, "player", 0)) {
		if(get_bit(g_bHasFreeday, player)) {
			set_user_rendering(player, _, 0, 0, 0, _, 0);
			fnColorPrint(0, "%L", LANG_SERVER, "JB_DAY_M143", szName, szName2);
			clear_bit(g_bHasFreeday, player);
			return PLUGIN_HANDLED;
		}
		else if(get_bit(g_bIsGlowing, player)) {	
			set_user_rendering(player, _, 0, 0, 0, _, 0);
			clear_bit(g_bIsGlowing, player);
			fnColorPrint(player, "%L", LANG_SERVER, "JB_DAY_M144", szName);
		}
		
		else
			fnColorPrint(id, "%L", LANG_SERVER, "JB_DAY_M145");
	}
	else
		fnColorPrint(id, "%L", LANG_SERVER, "JB_DAY_M140");
	
	return PLUGIN_HANDLED; 
}

/*================================================================================
 [Class Menu]
=================================================================================*/
#define CLASS 11
new const g_iClassNames[CLASS][] = {
	"", 
	"JB_CLASS_M1", 
	"JB_CLASS_M2",
	"JB_CLASS_M3", 
	"JB_CLASS_M4",
	"JB_CLASS_M5", 
	"JB_CLASS_M6",
	"JB_CLASS_M7",
	"JB_CLASS_M8",
	"JB_CLASS_M9",
	"JB_CLASS_M10"
};

new const g_iAccessClass[CLASS] = {
	0, 
	0, 
	0,
	0, 
	0,
	0, 
	0,
	0,
	ADMIN_CLASS,
	ADMIN_CLASS,
	ADMIN_CLASS
};

public ClassMenu(id)
{ 
	if(!get_bit(g_bIsConnected, id)) 
		return PLUGIN_HANDLED;
	
	if( cs_get_user_team( id ) != CS_TEAM_CT ) {
		fnColorPrint(id, "%L", LANG_SERVER, "JB_DAY_M146");
		return PLUGIN_HANDLED;
	}
	
	if(!get_bit(g_bIsAlive, id)) {
		fnColorPrint(id, "%L", LANG_SERVER, "JB_USER_DEAD");
		return PLUGIN_HANDLED;
	}
	
	if(!g_bCanBuy) {
		fnColorPrint( id, "%L", LANG_SERVER, "JB_DAY_M147");
		return PLUGIN_HANDLED;
	}
	set_bit(g_bHasMenuOpen, id);
	new szText[256];
	formatex(szText, charsmax(szText), "%L", LANG_SERVER, "JB_CLASS_TITLE");
	new menu = menu_create(szText, "Class_sub_menu");
	
	// Give random weapon for Shot4Shot
	new iNumber[5], szOption[40];
	for( new i = 1; i < CLASS; i++ ) {
		num_to_str(i, iNumber, 4);
		formatex(szOption, 39, "%L", LANG_SERVER, g_iClassNames[i]);
		menu_additem(menu, szOption, iNumber, g_iAccessClass[i]);
	}
	
	menu_display(id, menu); 
	return PLUGIN_HANDLED; 
}

public Class_sub_menu(id, menu, item) 
{ 
	if(!get_bit(g_bIsConnected, id)) 
		return PLUGIN_HANDLED;
	if( item == MENU_EXIT || cs_get_user_team( id ) != CS_TEAM_CT) { 
		clear_bit(g_bHasMenuOpen, id);
		menu_destroy(menu);
		return PLUGIN_HANDLED; 
	}
	
	if( cs_get_user_team( id ) != CS_TEAM_CT )
		return PLUGIN_HANDLED;
	
	if(!get_bit(g_bIsAlive, id)) 
		return PLUGIN_HANDLED;
	
	if(!g_bCanBuy) 
		return PLUGIN_HANDLED;
	
	new data[6], name[64]; 
	new access, callback; 
	StripPlayerWeapons(id);
	clear_bit(g_bHasMenuOpen, id);
	menu_item_getinfo(menu, item, access, data, charsmax(data), name, charsmax(name), callback); 
	
	switch(str_to_num(data)) {
		case(1): {
			GiveItem(id, "weapon_m4a1", 90);
			GiveItem(id, "weapon_usp", 100);
			fnColorPrint(id, "%L", LANG_SERVER, "JB_DAY_M148");
		}
		case(2): {
			GiveItem(id, "weapon_ak47", 90);
			GiveItem(id, "weapon_glock18", 120);
			fnColorPrint(id, "%L", LANG_SERVER, "JB_DAY_M149");
		}
		case(3): {
			GiveItem(id, "weapon_awp", 30);
			GiveItem(id, "weapon_deagle", 35);
			fnColorPrint(id, "%L", LANG_SERVER, "JB_DAY_M150");
		}
		case(4): {
			GiveItem(id, "weapon_ump45", 100);
			GiveItem(id, "weapon_usp", 100);
			fnColorPrint(id, "%L", LANG_SERVER, "JB_DAY_M151");
		}
		case(5): {
			GiveItem(id, "weapon_m3", 32);
			GiveItem(id, "weapon_p228", 52);
			fnColorPrint(id, "%L", LANG_SERVER, "JB_DAY_M152");
		}
		case(6): {
			GiveItem(id, "weapon_mac10", 100);
			GiveItem(id, "weapon_deagle", 1000);
			fnColorPrint(id, "%L", LANG_SERVER, "JB_DAY_M153");
		}
		case(7): {
			GiveItem(id, "weapon_aug", 90);
			GiveItem(id, "weapon_p228", 52);
			fnColorPrint(id, "%L", LANG_SERVER, "JB_DAY_M154");
		}
		case(8): {
			//cs_set_user_model(id, "vip");
			give_item(id, "weapon_shield");
			GiveItem(id, "weapon_usp", 200);
			fnColorPrint(id, "%L", LANG_SERVER, "JB_DAY_M155");
		}
		case(9): {
			//cs_set_user_model(id, "vip");
			GiveItem(id, "weapon_m249", 400);
			GiveItem(id, "weapon_elite", 100);
			fnColorPrint(id, "%L", LANG_SERVER, "JB_DAY_M156");
		}
		case(10): {
			//cs_set_user_model(id, "vip");
			GiveItem(id, "weapon_galil", 200);
			GiveItem(id, "weapon_deagle", 100);
			fnColorPrint(id, "%L", LANG_SERVER, "JB_DAY_M157");
		}
	}
	set_user_armor(id, 100);
	menu_destroy(menu); 
	return PLUGIN_HANDLED; 
}  

public MsgStatusIcon(const iMsgId, const iMsgDest, const iPlayer)
{
	if(get_bit(g_bIsConnected, iPlayer) && get_bit(g_bIsAlive, iPlayer))
	{
		static szMsg[8];
		get_msg_arg_string(2, szMsg, 7);
    
		if(equal(szMsg, "buyzone"))
		{
			set_pdata_int(iPlayer, OFFSET_BUYZONE, get_pdata_int(iPlayer, OFFSET_BUYZONE) & ~(1<<0));
			return PLUGIN_HANDLED;
		}
	}
	return PLUGIN_CONTINUE;
}

/*================================================================================
 [Hud message]
=================================================================================*/

public Fwd_HudThink( iEntity )
{
	if ( iEntity != g_iTimerEntity )
		return;
		
	new g_prisoners = fnGetTerrorists();
	new g_guards = fnGetCounterTerrorists();
	
	if( g_prisoners == 1 && g_iDay[ TOTAL_DAYS ] != DAY_NONE )
	{
		fnColorPrint(0, "%L", LANG_SERVER, "JB_DAY_M158");
		Day_Ends( );
	}
	if( g_guards < 1 && g_iDay[ TOTAL_DAYS ] != DAY_NONE )
	{
		fnColorPrint(0, "%L", LANG_SERVER, "JB_DAY_M159");
		Day_Ends( );
	}
	
	set_hudmessage(0, 255, 0, -1.0, 0.01, 0, 0.75, 0.75, 0.75, 0.75, 2);
	
	if( g_iDay[ TOTAL_DAYS ] != DAY_NONE && !g_iAreWeInaVote )
		show_hudmessage(0,"%L", LANG_SERVER, "JB_HUD_M1", g_prisoners, g_guards, LANG_SERVER, g_iStartDayNames[ g_iDay[ TOTAL_DAYS ] ] );
	else
		show_hudmessage(0,"%L", LANG_SERVER, "JB_HUD_M2", g_prisoners, g_guards );
    
	entity_set_float( g_iTimerEntity, EV_FL_nextthink, get_gametime() + 1.0 );
} 

/*================================================================================
 [Functions]
=================================================================================*/
fnGetSimons() {
	static iPlayers[32], iNum, i, iPlayer, Simons;
	Simons = 0;
	get_players(iPlayers, iNum, "ae", "CT"); 
	for( i=0; i<iNum; i++ ) {
		iPlayer = iPlayers[i];
		if(get_bit(g_bIsSimon, iPlayer))
			Simons++;
	}

	return Simons;
}

fnGetRandomPlayer() {
	static iPlayers[32], iNum;
	get_players(iPlayers, iNum, "ae", "TERRORIST"); 
	return iNum ? iPlayers[random(iNum)] : 0;
}

fnGetTerrorists() {
	/* Get's the number of terrorists */
	static iPlayers[32], iNum;
	get_players(iPlayers, iNum, "ae", "TERRORIST"); 
	return iNum;
}

fnGetCounterTerrorists() {
	/* Get's the number of counter-terrorists */
	static iPlayers[32], iNum;
	get_players(iPlayers, iNum, "ae", "CT");
	return iNum;
}

fnGetChosen() {
	/* Get's if there's a chosen one between players */
	new temp;
	static iPlayers[32], iNum, i, iPlayer;
	get_players(iPlayers, iNum, "ae", "CT"); 
	for( i=0; i<iNum; i++ )
	{
		iPlayer = iPlayers[i];
		if(get_bit(g_bIsChosen, iPlayer))
			temp = set_bit(g_bIsChosen, iPlayer);
	}

	return temp;
}

stock in_array(needle, data[], size) { 
	for(new i = 0; i < size; i++) { 
		if(data[i] == needle) 
			return i;
	} 
	return -1; 
}  


fnGetGameType() {
	/* Get's the game type of the last request games */
	new Game[32];
	
	switch (g_iGameType) {
		case 0: Game = "JB_LASTREQUEST_M0";
		case 1: Game = "JB_LASTREQUEST_M1";
		case 2: Game = "JB_LASTREQUEST_M2";
		case 3: Game = "JB_LASTREQUEST_M3";
		case 4: Game = "JB_LASTREQUEST_M4";
		case 5: Game = "JB_LASTREQUEST_M5";
		case 6: Game = "JB_LASTREQUEST_M6";
		case 7: Game = "JB_LASTREQUEST_M7";
		case 8: Game = "JB_LASTREQUEST_M8";
		case 9: Game = "JB_LASTREQUEST_M9";
		case 10: Game = "JB_LASTREQUEST_M10";	
	}
	return Game;
}

fnSetRing(id) {	
	/* Teh beam cylinder !!! */
	new Float:flOrigin[3], iOrigin[3];
	pev(id, pev_origin, flOrigin);
	FVecIVec(flOrigin, iOrigin);

	// Beam Color
	new Colors = get_user_team(id);
	new Beam = GetPlayerHullSize(id);
	new Admin = is_user_admin(id);
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY, iOrigin); 
	write_byte(TE_BEAMCYLINDER);
	write_coord(iOrigin[0]);
	write_coord(iOrigin[1]);
	if(Beam == HULL_HEAD)
		write_coord(iOrigin[2]-16);
	else
		write_coord(iOrigin[2]-33);
	write_coord(iOrigin[0]);
	write_coord(iOrigin[1]);
	write_coord(iOrigin[2] + 200);
	write_short(g_iRingSprite);		// Sprite Index
	write_byte(0);				// Start Frame
	write_byte(0);				// Frame Rate
	write_byte(5);				// Life
	write_byte(5);				// Width 
	write_byte(0);				// Noise
	if(Admin)
	{
		write_byte(Colors == 2 ? 255 : 0);//r
		write_byte(Colors == 1 ? 255 : 255);//g
		write_byte(0);//b
	}
	else {
		write_byte(Colors == 1 ? 255 : 0);
		write_byte(0);
		write_byte(Colors == 2 ? 255 : 0);
	}
	write_byte(200);			// Brightness
	write_byte(0);				// Speed
	message_end();
}

fnSetSimonRing(id) {
	/* Teh beam cylinder !!! */
	new Float:flOrigin[3], iOrigin[3];
	pev(id, pev_origin, flOrigin);
	FVecIVec(flOrigin, iOrigin);

	// Beam Color
	new Beam = GetPlayerHullSize(id);

	message_begin(MSG_BROADCAST, SVC_TEMPENTITY, iOrigin); 
	write_byte(TE_BEAMCYLINDER);
	write_coord(iOrigin[0]);
	write_coord(iOrigin[1]);
	if(Beam == HULL_HEAD)
		write_coord(iOrigin[2]-16);
	else
		write_coord(iOrigin[2]-33);
	write_coord(iOrigin[0]);
	write_coord(iOrigin[1]);
	write_coord(iOrigin[2] + 200);
	write_short(g_iRingSprite);		// Sprite Index
	write_byte(0);				// Start Frame
	write_byte(0);				// Frame Rate
	write_byte(5);				// Life
	write_byte(25);				// Width 
	write_byte(0);				// Noise

	write_byte(255);//r
	write_byte(255);//g
	write_byte(255);//b

	write_byte(200);			// Brightness
	write_byte(0);				// Speed
	message_end();
}

fnColorPrint(index, const Msg[], any:...) {
	new Buffer[190], Buffer2[192];
	formatex(Buffer2, charsmax(Buffer2), "^x04[%s] ^x01%s", g_szPluginPrefix, Msg);
	vformat(Buffer, charsmax(Buffer), Buffer2, 3);

	if (!index) {
		for (new i = 1; i <= g_iMaxPlayers; i++) {
			if (!is_user_connected(i))
				continue;

			message_begin(MSG_ONE_UNRELIABLE, g_iMsgSayText,_, i);
			write_byte(i);
			write_string(Buffer);
			message_end();
		}
	}
	else {
		if (!is_user_connected(index))
			return;

		message_begin(MSG_ONE, g_iMsgSayText,_, index);
		write_byte(index);
		write_string(Buffer);
		message_end();
	}
}

public MsgSendAudio(iMsgId, iMsgDest, id)
{
	if( id )
	{
		if( g_bGrenade )
		{
			new szRadioKey[19];
			static const MRAD_FIREINHOLE[] = "%!MRAD_FIREINHOLE";
			get_msg_arg_string(2, szRadioKey, charsmax(szRadioKey));
			if( equal(szRadioKey, MRAD_FIREINHOLE) )
			{
				if( get_msg_block(g_iMsgTextMsg) != BLOCK_SET )
				{
					set_msg_block(g_iMsgTextMsg, BLOCK_ONCE);
				}
				return PLUGIN_HANDLED;
			}
		}
	}
	return PLUGIN_CONTINUE;
} 

public reset_all(id)
{ 	
	clear_bit(g_bIsLast, id);
	clear_bit(g_bIsChosen, id);
	clear_bit(g_bHasCrowbar, id);
	clear_bit(g_bHasArmor, id);
	clear_bit(g_bHasSpeed, id);
	clear_bit(g_bHasInvis, id);
	clear_bit(g_bInDisguise, id);
	clear_bit(g_bHasNadepack, id);
	clear_bit(g_bHasFootstep, id);
	clear_bit(g_bHasDisguise, id);
	clear_bit(g_bHasCellKeys, id);
	clear_bit(g_bHasFreeday, id);
	clear_bit(g_bInDisguise, id);
	clear_bit(g_bIsGlowing, id);
	clear_bit(g_bIsSimon, id);
	clear_bit(g_bInMathProblem, id);
	
	if(task_exists(id+TASK_BEAM))
		remove_task(id+TASK_BEAM);
	
	set_user_footsteps(id, 0);
	set_user_maxspeed(id, 250.0);
	set_user_rendering(id);
}

// takes a weapon from a player efficiently
// Thanks to XxAvalanchexX
public ham_strip_weapon(id,weapon[])
{
	if(!equal(weapon,"weapon_",7)) return 0;
	
	new wId = get_weaponid(weapon);
	if(!wId) return 0;

	new wEnt;
	while((wEnt = engfunc(EngFunc_FindEntityByString,wEnt,"classname",weapon)) && pev(wEnt,pev_owner) != id) {}
	if(!wEnt) return 0;
	
	if(get_user_weapon(id) == wId) ExecuteHamB(Ham_Weapon_RetireWeapon,wEnt);
	
	if(!ExecuteHamB(Ham_RemovePlayerItem,id,wEnt)) return 0;
	ExecuteHamB(Ham_Item_Kill,wEnt);
	
	set_pev(id,pev_weapons,pev(id,pev_weapons) & ~(1<<wId));
	
	return 1;
}
public ClCmd_CheckDisguise(id) {
	if(!get_bit(g_bIsConnected, id)) 
		return PLUGIN_HANDLED;
	if( cs_get_user_team( id ) != CS_TEAM_T ) {
		fnColorPrint(id, "%L", LANG_SERVER, "JB_DAY_M160");
		return PLUGIN_HANDLED;
	}
		
	if(!get_bit(g_bIsAlive, id)) {
		fnColorPrint(id, "%L", LANG_SERVER, "JB_USER_DEAD");
		return PLUGIN_HANDLED;
	}
	
	if(!get_bit(g_bHasDisguise, id)) {
		fnColorPrint( id, "%L", LANG_SERVER, "JB_DAY_M161");
		return PLUGIN_HANDLED;
	}
	
	if(get_bit(g_bInDisguise, id)) {
		if(IsBeingWatched(id)) {
			fnColorPrint( id, "%L", LANG_SERVER, "JB_DAY_M162");
			return PLUGIN_HANDLED;
		}
		else {
			cs_set_user_model(id, "leet");
			clear_bit(g_bInDisguise, id);
			fnColorPrint( id, "%L", LANG_SERVER, "JB_DAY_M163");
			return PLUGIN_HANDLED;
		}
	}
	else {
		if(IsBeingWatched(id)) {
			fnColorPrint( id, "%L", LANG_SERVER, "JB_DAY_M164");
			return PLUGIN_HANDLED;
		}
		else {
			cs_set_user_model(id, "urban");
			set_bit(g_bInDisguise, id);
			fnColorPrint( id, "%L", LANG_SERVER, "JB_DAY_M165");
			return PLUGIN_HANDLED;
		}
	}
	return PLUGIN_HANDLED;
}
// checks if they are in a ct's view
// Thanks to joaquimandrade
IsBeingWatched(id) {
	new CsTeams:team = cs_get_user_team(id);
	new Float:origin[3];
	entity_get_vector(id,EV_VEC_origin,origin);
		
	for(new i=1,CsTeams:teamViewer;i<=g_iMaxPlayers;i++) {
		if(get_bit(g_bIsAlive, i)) {
			teamViewer = cs_get_user_team(i);
				
			if(team != teamViewer)
				if(fm_is_ent_visible_maxdistance(i,id,.maxdistance = DetectionMaxDistance) && is_in_viewcone(i,origin))
					return true;
		}
	}
	return false;
}

bool:fm_is_ent_visible_maxdistance(index, entity,ignoremonsters = 0,Float:maxdistance) {	
	new Float:start[3], Float:dest[3];
	pev(index, pev_origin, start);
	pev(index, pev_view_ofs, dest);
	xs_vec_add(start, dest, start);
	pev(entity, pev_origin, dest);
	
	if(vector_distance(start,dest) <= maxdistance) {
		engfunc(EngFunc_TraceLine, start, dest, ignoremonsters, index, 0);
		new Float:fraction;
		get_tr2(0, TR_flFraction, fraction);
		
		if (fraction == 1.0 || get_tr2(0, TR_pHit) == entity)
			return true;
	}
	return false;
}

//Taken From exolent//
public Fwd_SetVoice(receiver, sender, bool:bListen)
{
	if(!get_bit(g_bIsConnected, receiver) 
	|| !get_bit(g_bIsConnected, sender) 
	|| g_iSpeakFlags[sender] == SPEAK_NORMAL 
	&& g_iSpeakFlags[receiver] != SPEAK_LISTENALL)
	{
		return FMRES_IGNORED;
	}
	
	new iSpeakType = 0;
	if(g_iSpeakFlags[sender] == SPEAK_ALL
	|| g_iSpeakFlags[receiver] == SPEAK_LISTENALL
	|| g_iSpeakFlags[sender] == SPEAK_TEAM && get_pdata_int(sender, 114) == get_pdata_int(receiver, 114))
	{
		iSpeakType = 1;
	}
	
	engfunc(EngFunc_SetClientListening, receiver, sender, iSpeakType);
	return FMRES_SUPERCEDE;
}

public SaveWeapons(iPlayer)
{
	if( !get_bit(g_bIsConnected, iPlayer) && !get_bit(g_bIsAlive, iPlayer) )
		return PLUGIN_HANDLED;
		
	new iWeaponBits = g_iWeaponBits[iPlayer] = entity_get_int(iPlayer, EV_INT_weapons) & VALID_WEAPONS;
	
	for(new i;i<=CSW_P90;i++)
	{
		if(IsWeaponInBits(i, iWeaponBits))
		{
			g_iWeaponClip[iPlayer][i] = cs_get_weapon_ammo(find_ent_by_owner(-1, g_szWeaponNames[i], iPlayer));
			g_iWeaponAmmo[iPlayer][i] = cs_get_user_bpammo(iPlayer, i);
		}
	}
	StripPlayerWeapons(iPlayer);
	
	return PLUGIN_HANDLED;
}

public RestoreWeapons(iPlayer)
{
	if( !get_bit(g_bIsConnected, iPlayer) && !get_bit(g_bIsAlive, iPlayer) )
	{
		return PLUGIN_HANDLED;
	}
	
	StripPlayerWeapons(iPlayer);
	new iWeaponBits = g_iWeaponBits[iPlayer];
	new iEntity;
	
	for(new i;i<=CSW_P90;i++)
	{
		if(IsWeaponInBits(i, iWeaponBits))
		{
			iEntity = give_item(iPlayer, g_szWeaponNames[i]);
			
			cs_set_weapon_ammo(iEntity, g_iWeaponClip[iPlayer][i]);
			cs_set_user_bpammo(iPlayer, i, g_iWeaponAmmo[iPlayer][i]);
		}
	}
	return PLUGIN_HANDLED;
}
// Thanks to Arkshine
public ClientCommand_UnStuck(const id)
{
	new i_Value;

	if ((i_Value = UTIL_UnstuckPlayer(id, START_DISTANCE, MAX_ATTEMPTS)) != 1)
		switch (i_Value)
		{
			case 0: fnColorPrint(id, "%L", LANG_SERVER, "JB_DAY_M166");
			case -1: fnColorPrint(id, "%L", LANG_SERVER, "JB_DAY_M167");
		}

	return PLUGIN_CONTINUE;
}

UTIL_UnstuckPlayer(const id, const i_StartDistance, const i_MaxAttempts)
{
	// Is Not alive, ignore.
	if (!get_bit(g_bIsAlive, id))  return -1;
	
	static Float:vf_OriginalOrigin[Coord_e], Float:vf_NewOrigin[Coord_e];
	static i_Attempts, i_Distance;
	
	// Get the current player's origin.
	pev (id, pev_origin, vf_OriginalOrigin);
	
	i_Distance = i_StartDistance;

	while (i_Distance < 1000)
	{
		i_Attempts = i_MaxAttempts;
	
		while (i_Attempts--)
		{
			vf_NewOrigin[x] = random_float(vf_OriginalOrigin[ x ] - i_Distance, vf_OriginalOrigin[ x ] + i_Distance);
			vf_NewOrigin[y] = random_float(vf_OriginalOrigin[ y ] - i_Distance, vf_OriginalOrigin[ y ] + i_Distance);
			vf_NewOrigin[z] = random_float(vf_OriginalOrigin[ z ] - i_Distance, vf_OriginalOrigin[ z ] + i_Distance);
		
			engfunc (EngFunc_TraceHull, vf_NewOrigin, vf_NewOrigin, DONT_IGNORE_MONSTERS, GetPlayerHullSize (id), id, 0);
		
			// Free space found.
			if (get_tr2 (0, TR_InOpen) && !get_tr2 (0, TR_AllSolid) && !get_tr2 (0, TR_StartSolid))
			{
				// Set the new origin .
				engfunc (EngFunc_SetOrigin, id, vf_NewOrigin);
				return 1;
			}
		}
	
		i_Distance += i_StartDistance;
	}

	// Could not be found.
	return 0;
} 

stock bool:is_user_stuck(id) { 
	new Float:g_origin[3]; 
	pev(id, pev_origin, g_origin); 
	if ( trace_hull(g_origin, HULL_HUMAN,id) != 0 ) 
	{ 
		return true; 
	} 
	return false; 
} 

public CmdSprayMessage( id )
{
	if(get_pcvar_num(cvar_pointer[cvar_sprayenable]) != 1)
		return PLUGIN_HANDLED;
	if(get_user_team(id) == 1 && !access(id, SPRAY_ACCESS))
	{
		fnColorPrint( id, "%L", LANG_SERVER, "JB_DAY_M168" );
		return PLUGIN_HANDLED;
	}
	
	if( !g_bSprayMessages )
	{
		g_bSprayMessages = true;
		fnColorPrint( id, "%L", LANG_SERVER, "JB_DAY_M169", '^4', '^3' );
	} 
	else {
		g_bSprayMessages = false;
		fnColorPrint( id, "%L", LANG_SERVER, "JB_DAY_M170", '^4', '^3' );
	}
	return PLUGIN_HANDLED;
}

public EventSpray()
{
	if(get_pcvar_num(cvar_pointer[cvar_sprayenable]) != 1)
		return;
	new iPlayer = read_data(2);
	if(!get_bit(g_bIsConnected, iPlayer) && !get_bit(g_bIsAlive, iPlayer))
		return;
		
	new iOrigin[3];
	iOrigin[0] = read_data(3);
	iOrigin[1] = read_data(4);
	iOrigin[2] = read_data(5);
	
	new Float:vecOrigin[3];
	IVecFVec(iOrigin, vecOrigin);
	
	new Float:vecDirection[3];
	velocity_by_aim(iPlayer, 5, vecDirection);
	
	new Float:vecStop[3];
	xs_vec_add(vecOrigin, vecDirection, vecStop);
	xs_vec_mul_scalar(vecDirection, -1.0, vecDirection);
	
	new Float:vecStart[3];
	xs_vec_add(vecOrigin, vecDirection, vecStart);
	engfunc(EngFunc_TraceLine, vecStart, vecStop, IGNORE_MONSTERS, -1, 0);
	get_tr2(0, TR_vecPlaneNormal, vecDirection);
	vecDirection[2] = 0.0;
	xs_vec_normalize(vecDirection, vecDirection);
	xs_vec_mul_scalar(vecDirection, 5.0, vecDirection);
	xs_vec_add(vecOrigin, vecDirection, vecStart);
	xs_vec_copy(vecStart, vecStop);
	vecStop[2] -= 9999.0;
	engfunc(EngFunc_TraceLine, vecStart, vecStop, IGNORE_MONSTERS, -1, 0);
	get_tr2(0, TR_vecEndPos, vecStop);
	
	new szName[32]; get_user_name(iPlayer, szName, charsmax(szName));
	
	if(g_bSprayMessages) {
		if(iPlayer > 0)
			fnColorPrint(0, "%L", LANG_SERVER, "JB_DAY_M171", szName, '^4', (vecStart[2] - vecStop[2]), '^1', '^3');
	}
	else {
		if(iPlayer > 0)
			fnColorPrint( iPlayer, "%L", LANG_SERVER, "JB_DAY_M172", '^4', (vecStart[2] - vecStop[2]), '^1', '^3');
	}
}

public Fwd_AddToFullPack(es_handle, e, ent, host, hostflags, player, pSet)
{
	
	if( player && get_bit(g_bIsAlive, host))
	{
		if(g_iDay[ TOTAL_DAYS ] == DAY_HIDENSEEK)
		{
			
			static CsTeams:team; team = cs_get_user_team(ent);
			static alpha;
			switch (team)
			{
				case CS_TEAM_CT: alpha = 255;
				case CS_TEAM_T:
				{
					static Float:flDistance;
					flDistance = entity_range(host, ent); 
					if( flDistance < 1000.0 ) 
					{ 
						alpha = floatround((1.0 - (flDistance / 1000.0)) * 255.0);
					}
					else alpha = 1;
				}
			}
			
			if(get_user_team(ent) != get_user_team(host))
			{
				set_es(es_handle, ES_RenderMode, kRenderTransAlpha);
				set_es(es_handle, ES_RenderAmt, alpha);
			}
			
		}
		if(g_iDay[ TOTAL_DAYS ] == DAY_NIGHT)
		{	
			static CsTeams:team; team = cs_get_user_team(host);
			static alpha;
			
			switch (team)
			{
				case CS_TEAM_CT: alpha = 255;
				case CS_TEAM_T: alpha = 0;
			}
			if(get_user_team(ent) != get_user_team(host))
			{
				set_es(es_handle, ES_RenderMode, kRenderTransAlpha);
				set_es(es_handle, ES_RenderAmt, alpha);
			}
		}
		if(g_iDay[ TOTAL_DAYS ] == DAY_RENIGHT)
		{	
			static CsTeams:team; team = cs_get_user_team(host);
			static alpha;
			
			switch (team)
			{
				case CS_TEAM_CT: alpha = 0;
				case CS_TEAM_T: alpha = 255;
			}
			
			if(get_user_team(ent) != get_user_team(host))
			{
				set_es(es_handle, ES_RenderMode, kRenderTransAlpha);
				set_es(es_handle, ES_RenderAmt, alpha);
			}
		}
		if(g_ThermalOn[host])
		{
			static CsTeams:team; team = cs_get_user_team(host);
			static color[3];
			
			switch (team)
			{
				case CS_TEAM_CT:
				{
					color[0] = 255;
					color[1] = 0;
					color[2] = 0;
				}
				case CS_TEAM_T:
				{
					color[0] = 0;
					color[1] = 0;
					color[2] = 255;
				}
			}
			
			if(get_user_team(ent) != get_user_team(host))
			{
				set_es(es_handle, ES_RenderFx, 19);
				set_es(es_handle, ES_RenderColor, color);
				set_es(es_handle, ES_RenderMode, 0);
				set_es(es_handle, ES_RenderAmt, 25);
			}
		}
	}
	
	return FMRES_IGNORED;
}

public fm_get_speak(id)
{
	if(!get_bit(g_bIsConnected, id))
	{
		log_error(AMX_ERR_NATIVE, "[FmSetSpeak] Invalid player %d", id);
		return 0;
	}
	
	return g_iSpeakFlags[id];
}

public fm_set_speak(id, nums)
{
	if(!get_bit(g_bIsConnected, id))
	{
		log_error(AMX_ERR_NATIVE, "[FmSetSpeak] Invalid player %d", id);
		return;
	}
	g_iSpeakFlags[id] = nums;
}

GiveItem(const id, const szItem[], const bpAmmo) {
	give_item(id, szItem); 
	cs_set_user_bpammo(id, get_weaponid(szItem), bpAmmo);
}

public fog(bool:FogOn) {
	if(FogOn) {
		message_begin(MSG_ALL,g_iMsgFog,{0,0,0},0);
		write_byte(180);	// red
		write_byte(1);		// green
		write_byte(1);		// blue
		write_byte(10);		// Start distance
		write_byte(41);		// Start distance
		write_byte(95);		// End distance
		write_byte(59);		// End distance
		message_end();	
	}
	else {
		message_begin(MSG_ALL,g_iMsgFog,{0,0,0},0);
		write_byte(0);		// red
		write_byte(0);		// green
		write_byte(0);		// blue
		write_byte(0);		// Start distance
		write_byte(0);		// Start distance
		write_byte(0);		// End distance
		write_byte(0);		// End distance
		message_end();
	}
}

public Event_NVGToggle(id)
	g_ThermalOn[id] = read_data(1);
