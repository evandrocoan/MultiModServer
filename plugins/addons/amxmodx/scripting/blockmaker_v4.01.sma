#include <amxmodx>
#include <amxmisc>
#include <engine>
#include <fun>
#include <cstrike>
#include <fakemeta>

#pragma semicolon 1;

#define PLUGIN "blockmaker"
#define VERSION "4.01"
#define AUTHOR "Necro"
#define BM_ADMIN_LEVEL ADMIN_MENU	//admin access level to use this plugin. ADMIN_MENU = flag 'u'

new gKeysMainMenu;
new gKeysBlockMenu;
new gKeysBlockSelectionMenu;
new gKeysTeleportMenu;
new gKeysTimerMenu;
new gKeysMeasureMenu;
new gKeysLongJumpMenu;
new gKeysOptionsMenu;
new gKeysChoiceMenu;

const Float:gfSnapDistance = 10.0;	//blocks snap together when they're within this value + the players snap gap

// enum for menu option values
enum
{
	N1, N2, N3, N4, N5, N6, N7, N8, N9, N0
};

// enum for bit-shifted numbers 1 - 10
enum
{
	B1 = 1 << N1, B2 = 1 << N2, B3 = 1 << N3, B4 = 1 << N4, B5 = 1 << N5,
	B6 = 1 << N6, B7 = 1 << N7, B8 = 1 << N8, B9 = 1 << N9, B0 = 1 << N0,
};

// enum for options with YES/NO confirmation
enum
{
	CHOICE_LOAD,
	CHOICE_DEL_BLOCKS,
	CHOICE_DEL_TELEPORTS
};

// enum for different block sizes
enum
{
	NORMAL,
	SMALL,
	LARGE
};

// enum for axes
enum
{
	X,
	Y,
	Z
};

// block scales
const Float:SCALE_SMALL = 0.25;
const Float:SCALE_NORMAL = 1.0;
const Float:SCALE_LARGE = 2.0;

// hud message values
const gHudRed = 10;
const gHudGreen = 30;
const gHudBlue = 200;
const Float:gfTextX = -1.0;
const Float:gfTextY = 0.84;
const gHudEffects = 0;
const Float:gfHudFxTime = 0.0;
const Float:gfHudHoldTime = 0.25;
const Float:gfHudFadeInTime = 0.0;
const Float:gfHudFadeOutTime = 0.0;
const gHudChannel = 2;

// Task ID offsets
const TASK_BHOPSOLID = 1000;
const TASK_BHOPSOLIDNOT = 2000;
const TASK_INVINCIBLE = 3000;
const TASK_STEALTH = 4000;
const TASK_ICE = 5000;
const TASK_SPRITE = 6000;
const TASK_CAMOUFLAGE = 7000;
const TASK_HONEY = 8000;
const TASK_FIRE = 9000;
const TASK_BOOTSOFSPEED = 10000;
const TASK_TELEPORT = 11000;
const TASK_NOSLOW = 12000;
const TASK_AUTOBHOP = 13000;

// strings
new const gszPrefix[] = "[BM] ";
new const gszInfoTarget[] = "info_target";
new const gszHelpFilenameFormat[] = "blockmaker_v%s.txt";
new gszFile[128];
new gszNewFile[128];
new gszMainMenu[256];
new gszBlockMenu[256];
new gszTeleportMenu[256];
new gszTimerMenu[256];
new gszMeasureMenu[512];
new gszLongJumpMenu[256];
new gszOptionsMenu[256];
new gszChoiceMenu[128];
new gszHelpTitle[64];
new gszHelpText[1600];
new gszHelpFilename[32];
new gszViewModel[33][32];

// block dimensions
new Float:gfBlockSizeMinForX[3] = {-4.0,-32.0,-32.0};
new Float:gfBlockSizeMaxForX[3] = { 4.0, 32.0, 32.0};
new Float:gfBlockSizeMinForY[3] = {-32.0,-4.0,-32.0};
new Float:gfBlockSizeMaxForY[3] = { 32.0, 4.0, 32.0};
new Float:gfBlockSizeMinForZ[3] = {-32.0,-32.0,-4.0};
new Float:gfBlockSizeMaxForZ[3] = { 32.0, 32.0, 4.0};
new Float:gfDefaultBlockAngles[3] = { 0.0, 0.0, 0.0 };

// block models
new const gszBlockModelDefault[] = "models/blockmaker/bm_block_default.mdl";
new const gszBlockModelPlatform[] = "models/blockmaker/bm_block_platform.mdl";
new const gszBlockModelBhop[] = "models/blockmaker/bm_block_bhop.mdl";
new const gszBlockModelDamage[] = "models/blockmaker/bm_block_damage.mdl";
new const gszBlockModelHealer[] = "models/blockmaker/bm_block_healer.mdl";
new const gszBlockModelInvincibility[] = "models/blockmaker/bm_block_invincibility.mdl";
new const gszBlockModelStealth[] = "models/blockmaker/bm_block_stealth.mdl";
new const gszBlockModelSpeedBoost[] = "models/blockmaker/bm_block_speedboost.mdl";
new const gszBlockModelNoFallDamage[] = "models/blockmaker/bm_block_nofalldamage.mdl";
new const gszBlockModelIce[] = "models/blockmaker/bm_block_ice.mdl";
new const gszBlockModelDeath[] = "models/blockmaker/bm_block_death.mdl";
new const gszBlockModelNuke[] = "models/blockmaker/bm_block_nuke.mdl";
new const gszBlockModelCamouflage[] = "models/blockmaker/bm_block_camouflage.mdl";
new const gszBlockModelLowGravity[] = "models/blockmaker/bm_block_lowgravity.mdl";
new const gszBlockModelFire[] = "models/blockmaker/bm_block_fire.mdl";
new const gszBlockModelRandom[] = "models/blockmaker/bm_block_random.mdl";
new const gszBlockModelSlap[] = "models/blockmaker/bm_block_slap.mdl";
new const gszBlockModelHoney[] = "models/blockmaker/bm_block_honey.mdl";
new const gszBlockModelBarrierCT[] = "models/blockmaker/bm_block_barrier_ct.mdl";
new const gszBlockModelBarrierT[] = "models/blockmaker/bm_block_barrier_t.mdl";
new const gszBlockModelBootsOfSpeed[] = "models/blockmaker/bm_block_bootsofspeed.mdl";
new const gszBlockModelGlass[] = "models/blockmaker/bm_block_glass.mdl";
new const gszBlockModelBhopNoSlow[] = "models/blockmaker/bm_block_bhop_noslow.mdl";
new const gszBlockModelAutoBhop[] = "models/blockmaker/bm_block_autobhop.mdl";

// block sprites
new const gszBlockSpriteFire[] = "sprites/blockmaker/bm_block_fire.spr";				//custom
new const gszBlockSpriteFireSmall[] = "sprites/blockmaker/bm_block_fire_small.spr";		//custom
new const gszBlockSpriteFireLarge[] = "sprites/blockmaker/bm_block_fire_large.spr";		//custom
new const gszBlockSpriteTrampoline[] = "sprites/blockmaker/bm_block_trampoline.spr";		//custom
new const gszBlockSpriteTrampolineSmall[] = "sprites/blockmaker/bm_block_trampoline_small.spr";	//custom
new const gszBlockSpriteTrampolineLarge[] = "sprites/blockmaker/bm_block_trampoline_large.spr";	//custom
new const gszBlockSpriteSpeedBoost[] = "sprites/blockmaker/bm_block_speedboost.spr";		//custom
new const gszBlockSpriteSpeedBoostSmall[] = "sprites/blockmaker/bm_block_speedboost_small.spr";	//custom
new const gszBlockSpriteSpeedBoostLarge[] = "sprites/blockmaker/bm_block_speedboost_large.spr";	//custom
new const gszFireSprite[] = "sprites/blockmaker/bm_block_fire_flame.spr";			//custom

// block sounds
new const gszNukeExplosion[] = "weapons/c4_explode1.wav";				//from CS
new const gszFireSoundFlame[] = "ambience/flameburst1.wav";				//from HL
new const gszInvincibleSound[] = "warcraft3/divineshield.wav";				//from WC3 plugin
new const gszCamouflageSound[] = "warcraft3/antend.wav";					//from WC3 plugin
new const gszStealthSound[] = "warcraft3/levelupcaster.wav";				//from WC3 plugin
new const gszBootsOfSpeedSound[] = "warcraft3/purgetarget1.wav";				//from WC3 plugin
new const gszAutoBhopSound[] = "blockmaker/boing.wav";					//from 'www.wavsource.com/sfx/sfx.htm'

// teleport
new const Float:gfTeleportSizeMin[3] = {-16.0,-16.0,-16.0};
new const Float:gfTeleportSizeMax[3] = { 16.0, 16.0, 16.0};
new const Float:gfTeleportZOffset = 36.0;
new const gTeleportStartFrames = 20;
new const gTeleportEndFrames = 5;
new const gszTeleportSound[] = "warcraft3/blinkarrival.wav";				//from WC3 plugin
new const gszTeleportSpriteStart[] = "sprites/flare6.spr";				//from HL
new const gszTeleportSpriteEnd[] = "sprites/blockmaker/bm_teleport_end.spr";		//custom

// timer
new const gszTimerModelStart[] = "models/blockmaker/bm_timer_start.mdl";
new const gszTimerModelEnd[] = "models/blockmaker/bm_timer_end.mdl";
new Float:gfTimerSizeMin[3] = {-8.0,-8.0, 0.0};
new Float:gfTimerSizeMax[3] = { 8.0, 8.0, 60.0};
new Float:gfTimerTime[33];
new Float:gfScoreTimes[15];
new gszScoreNames[15][32];
new gszScoreSteamIds[15][32];
new bool:gbHasTimer[33];

// global variables
new gSpriteIdBeam;
new gSpriteIdFire;
new gMsgScreenFade;
new gBlockSize[33];
new gMenuBeforeOptions[33];
new gChoiceOption[33];
new gBlockMenuPage[33];
new gTeleportStart[33];
new gStartTimer[33];
new gGrabbed[33];
new gGroupedBlocks[33][256];
new gGroupCount[33];
new gMeasureToolBlock1[33];
new gMeasureToolBlock2[33];
new gLongJumpDistance[33];
new gLongJumpAxis[33];

// global booleans
new bool:gbMeasureToolEnabled[33];
new bool:gbSnapping[33];
new bool:gbNoFallDamage[33];
new bool:gbOnIce[33];
new bool:gbNoSlowDown[33];
new bool:gbLowGravity[33];
new bool:gbOnFire[33];
new bool:gbAutoBhop[33];
new bool:gbJustDeleted[33];
new bool:gbAdminGodmode[33];
new bool:gbAdminNoclip[33];

// global floats
new Float:gfSnappingGap[33];
new Float:gfOldMaxSpeed[33];
new Float:gfGrablength[33];
new Float:gfNextHealTime[33];
new Float:gfNextDamageTime[33];
new Float:gfInvincibleNextUse[33];
new Float:gfInvincibleTimeOut[33];
new Float:gfStealthNextUse[33];
new Float:gfStealthTimeOut[33];
new Float:gfTrampolineTimeout[33];
new Float:gfSpeedBoostTimeOut[33];
new Float:gfNukeNextUse[33];
new Float:gfCamouflageNextUse[33];
new Float:gfCamouflageTimeOut[33];
new Float:gfRandomNextUse[33];
new Float:gfBootsOfSpeedTimeOut[33];
new Float:gfBootsOfSpeedNextUse[33];
new Float:gfAutoBhopTimeOut[33];
new Float:gfAutoBhopNextUse[33];

// global vectors
new Float:gvGrabOffset[33][3];
new Float:gvMeasureToolPos1[33][3];
new Float:gvMeasureToolPos2[33][3];

// global strings
new gszCamouflageOldModel[33][32];

// block & teleport types
const gBlockMax = 24;
new gSelectedBlockType[gBlockMax];
new gRender[gBlockMax];
new gRed[gBlockMax];
new gGreen[gBlockMax];
new gBlue[gBlockMax];
new gAlpha[gBlockMax];

new const gszBlockClassname[] = "bm_block";
new const gszSpriteClassname[] = "bm_sprite";
new const gszTeleportStartClassname[] = "bm_teleport_start";
new const gszTeleportEndClassname[] = "bm_teleport_end";
new const gszTimerClassname[] = "bm_timer";

enum
{
	TELEPORT_START,
	TELEPORT_END,
	TIMER_START,
	TIMER_END
};

enum
{
	BM_PLATFORM,		//A
	BM_BHOP,		//B
	BM_DAMAGE,		//C
	BM_HEALER,		//D
	BM_NOFALLDAMAGE,	//I
	BM_ICE,			//J
	BM_TRAMPOLINE,		//G
	BM_SPEEDBOOST,		//H
	BM_INVINCIBILITY,	//E
	BM_STEALTH,		//F
	BM_DEATH,		//K
	BM_NUKE,		//L
	BM_CAMOUFLAGE,		//M
	BM_LOWGRAVITY,		//N
	BM_FIRE,		//O
	BM_SLAP,		//P
	BM_RANDOM,		//Q
	BM_HONEY,		//R
	BM_BARRIER_CT,		//S
	BM_BARRIER_T,		//T
	BM_BOOTSOFSPEED,	//U
	BM_GLASS,		//V
	BM_BHOP_NOSLOW,		//W
	BM_AUTO_BHOP		//X
};

enum
{
	NORMAL,
	GLOWSHELL,
	TRANSCOLOR,
	TRANSALPHA,
	TRANSWHITE
};

new const gszBlockNames[gBlockMax][32] =
{
	"Platform",
	"Bunnyhop",
	"Damage",
	"Healer",
	"No Fall Damage",
	"Ice",
	"Trampoline",
	"Speed Boost",
	"Invincibility",
	"Stealth",
	"Death",
	"Nuke",
	"Camouflage",
	"Low Gravity",
	"Fire",
	"Slap",
	"Random",
	"Honey",
	"CT Barrier",
	"T Barrier",
	"Boots Of Speed",
	"Glass",
	"Bunnyhop (No slow down)",
	"Auto Bunnyhop"
};

// save IDs
new const gBlockSaveIds[gBlockMax] =
{
	'A', 'B', 'C', 'D', 'I', 'J', 'G', 'H', 'E', 'F', 'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X'
};

const gTeleportSaveId = '*';

const gTimerSaveId = '&';

//global array of strings to store the paths and filenames to the block models
new gszBlockModels[gBlockMax][256];

//array of blocks that the random block can be
const gRandomBlocksMax = 7;

new const gRandomBlocks[gRandomBlocksMax] =
{
	BM_INVINCIBILITY,
	BM_STEALTH,
	BM_DEATH,
	BM_CAMOUFLAGE,
	BM_SLAP,
	BM_BOOTSOFSPEED,
	BM_AUTO_BHOP
};

//max speed for player when they have the boots of speed
const Float:gfBootsMaxSpeed = 400.0;

//how many pages for the block selection menu
new gBlockMenuPagesMax;

/***** PLUGIN START *****/
public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR);
	register_cvar(PLUGIN, VERSION, FCVAR_SERVER, 0.0);
	
	//register client commands
	register_clcmd("say /bm", "showMainMenu");
	register_clcmd("say /bm15", "timerShowScoreboard");
	register_clcmd("+bmgrab", "cmdGrab", BM_ADMIN_LEVEL, "bind a key to +bmgrab");
	register_clcmd("-bmgrab", "cmdRelease", BM_ADMIN_LEVEL);
	
	//register forwards
	register_forward(FM_EmitSound, "forward_EmitSound");
	
	//create the menus
	createMenus();
	
	//register menus
	register_menucmd(register_menuid("bmMainMenu"), gKeysMainMenu, "handleMainMenu");
	register_menucmd(register_menuid("bmBlockMenu"), gKeysBlockMenu, "handleBlockMenu");
	register_menucmd(register_menuid("bmBlockSelectionMenu"), gKeysBlockSelectionMenu, "handleBlockSelectionMenu");
	register_menucmd(register_menuid("bmTeleportMenu"), gKeysTeleportMenu, "handleTeleportMenu");
	register_menucmd(register_menuid("bmTimerMenu"), gKeysTimerMenu, "handleTimerMenu");
	register_menucmd(register_menuid("bmMeasureMenu"), gKeysMeasureMenu, "handleMeasureMenu");
	register_menucmd(register_menuid("bmLongJumpMenu"), gKeysLongJumpMenu, "handleLongJumpMenu");
	register_menucmd(register_menuid("bmOptionsMenu"), gKeysOptionsMenu, "handleOptionsMenu");
	register_menucmd(register_menuid("bmChoiceMenu"), gKeysChoiceMenu, "handleChoiceMenu");
	
	//register CVARs
	register_cvar("bm_telefrags", "1");			//players near teleport exit die if someone comes through
	register_cvar("bm_firedamageamount", "20.0");		//damage you take per half-second on the fire block
	register_cvar("bm_damageamount", "5.0");		//damage you take per half-second on the damage block
	register_cvar("bm_healamount", "1.0");			//how much hp per half-second you get on the healing block
	register_cvar("bm_invincibletime", "20.0");		//how long a player is invincible
	register_cvar("bm_invinciblecooldown", "60.0");		//time before the invincible block can be used again
	register_cvar("bm_stealthtime", "20.0");		//how long a player is in stealth
	register_cvar("bm_stealthcooldown", "60.0");		//time before the stealth block can be used again
	register_cvar("bm_camouflagetime", "20.0");		//how long a player is in camouflage
	register_cvar("bm_camouflagecooldown", "60.0");		//time before the camouflage block can be used again
	register_cvar("bm_nukecooldown", "60.0");		//someone might have been invincible when it was used
	register_cvar("bm_randomcooldown", "30.0");		//time before the random block can be used again
	register_cvar("bm_bootsofspeedtime", "20.0");		//how long the player has boots of speed
	register_cvar("bm_bootsofspeedcooldown", "60.0");	//time before boots of speed can be used again
	register_cvar("bm_autobhoptime", "20.0");		//how long the player has auto bhop
	register_cvar("bm_autobhopcooldown", "60.0");		//time before auto bhop can be used again
	register_cvar("bm_teleportsound", "1");			//teleporters make sound
	
	//register events
	register_event("DeathMsg", "eventPlayerDeath", "a");
	register_event("TextMsg", "eventRoundRestart", "a", "2&#Game_C", "2&#Game_w");
	register_event("ResetHUD", "eventPlayerSpawn", "b");
	register_event("CurWeapon", "eventCurWeapon", "be");
	register_logevent("eventRoundRestart", 2, "1=Round_Start");
	
	//make save folder in basedir (new saving/loading method)
	new szDir[64];
	new szMap[32];
	get_basedir(szDir, 64);
	add(szDir, 64, "/blockmaker");
	
	//make config folder if it doesn't already exist
	if (!dir_exists(szDir))
	{
		mkdir(szDir);
	}
	
	get_mapname(szMap, 32);
	formatex(gszNewFile, 96, "%s/%s.bm", szDir, szMap);
}
 
public plugin_precache()
{
	//set block models to defaults
	gszBlockModels[BM_PLATFORM] = gszBlockModelPlatform;
	gszBlockModels[BM_BHOP] = gszBlockModelBhop;
	gszBlockModels[BM_DAMAGE] = gszBlockModelDamage;
	gszBlockModels[BM_HEALER] = gszBlockModelHealer;
	gszBlockModels[BM_NOFALLDAMAGE] = gszBlockModelNoFallDamage;
	gszBlockModels[BM_ICE] = gszBlockModelIce;
	gszBlockModels[BM_TRAMPOLINE] = gszBlockModelDefault;
	gszBlockModels[BM_SPEEDBOOST] = gszBlockModelSpeedBoost;
	gszBlockModels[BM_INVINCIBILITY] = gszBlockModelInvincibility;
	gszBlockModels[BM_STEALTH] = gszBlockModelStealth;
	gszBlockModels[BM_DEATH] = gszBlockModelDeath;
	gszBlockModels[BM_NUKE] = gszBlockModelNuke;
	gszBlockModels[BM_CAMOUFLAGE] = gszBlockModelCamouflage;
	gszBlockModels[BM_LOWGRAVITY] = gszBlockModelLowGravity;
	gszBlockModels[BM_FIRE] = gszBlockModelFire;
	gszBlockModels[BM_SLAP] = gszBlockModelSlap;
	gszBlockModels[BM_RANDOM] = gszBlockModelRandom;
	gszBlockModels[BM_HONEY] = gszBlockModelHoney;
	gszBlockModels[BM_BARRIER_CT] = gszBlockModelBarrierCT;
	gszBlockModels[BM_BARRIER_T] = gszBlockModelBarrierT;
	gszBlockModels[BM_BOOTSOFSPEED] = gszBlockModelBootsOfSpeed;
	gszBlockModels[BM_GLASS] = gszBlockModelGlass;
	gszBlockModels[BM_BHOP_NOSLOW] = gszBlockModelBhopNoSlow;
	gszBlockModels[BM_AUTO_BHOP] = gszBlockModelAutoBhop;
	
	//setup default block rendering (unlisted block use normal rendering)
	setupBlockRendering(BM_INVINCIBILITY, GLOWSHELL, 255, 255, 255, 16);
	setupBlockRendering(BM_STEALTH, TRANSWHITE, 255, 255, 255, 100);
	setupBlockRendering(BM_GLASS, TRANSALPHA, 255, 255, 255, 50);
	
	//process block models config file
	processBlockModels();
	
	new szBlockModelSmall[256];
	new szBlockModelLarge[256];
	
	//precache blocks
	for (new i = 0; i < gBlockMax; ++i)
	{
		//get filenames for the small and large blocks based on normal block name
		setBlockModelNameSmall(szBlockModelSmall, gszBlockModels[i], 256);
		setBlockModelNameLarge(szBlockModelLarge, gszBlockModels[i], 256);
		
		precache_model(gszBlockModels[i]);
		precache_model(szBlockModelSmall);
		precache_model(szBlockModelLarge);
	}
	
	//precache timer models
	precache_model(gszTimerModelStart);
	precache_model(gszTimerModelEnd);
	
	//precache sprites
	precache_model(gszBlockSpriteFire);
	precache_model(gszBlockSpriteFireSmall);
	precache_model(gszBlockSpriteFireLarge);
	precache_model(gszBlockSpriteTrampoline);
	precache_model(gszBlockSpriteTrampolineSmall);
	precache_model(gszBlockSpriteTrampolineLarge);
	precache_model(gszBlockSpriteSpeedBoost);
	precache_model(gszBlockSpriteSpeedBoostSmall);
	precache_model(gszBlockSpriteSpeedBoostLarge);
	precache_model(gszTeleportSpriteStart);
	precache_model(gszTeleportSpriteEnd);
	gSpriteIdFire = precache_model(gszFireSprite);
	gSpriteIdBeam = precache_model("sprites/zbeam4.spr");
	
	//precache sounds
	precache_sound(gszTeleportSound);
	precache_sound(gszNukeExplosion);
	precache_sound(gszInvincibleSound);
	precache_sound(gszCamouflageSound);
	precache_sound(gszStealthSound);
	precache_sound(gszFireSoundFlame);
	precache_sound(gszBootsOfSpeedSound);
	precache_sound(gszAutoBhopSound);
}

public plugin_cfg()
{
	//format help text filename
	format(gszHelpFilename, 32, gszHelpFilenameFormat, VERSION);
	
	//create help title
	format(gszHelpTitle, sizeof(gszHelpTitle), "%s v%s by %s", PLUGIN, VERSION, AUTHOR);
	
	//read in help text from file
	new szConfigsDir[32];
	new szHelpFilename[64];
	new szLine[128];
	get_configsdir(szConfigsDir, 32);
	format(szHelpFilename, sizeof(szHelpFilename), "%s/%s", szConfigsDir, gszHelpFilename);
	
	//open help file for reading
	new f = fopen(szHelpFilename, "rt");
	
	//iterate through all the lines in the file
	new size = sizeof(gszHelpText);
	while (!feof(f))
	{
		fgets(f, szLine, 128);
		
		add(gszHelpText, size, szLine);
	}
	
	//close file
	fclose(f);
	
	//get id for message 'ScreenFade'
	gMsgScreenFade = get_user_msgid("ScreenFade");
	
	//make the scoreboard times very large
	for (new i = 0; i < 15; ++i)
	{
		gfScoreTimes[i] = 999999.9;
	}
	
	//load blocks from file
	loadBlocks(0);
}

createMenus()
{
	//calculate maximum number of block menu pages from maximum amount of blocks
	gBlockMenuPagesMax = floatround((float(gBlockMax) / 8.0), floatround_ceil);
	
	//create main menu
	new size = sizeof(gszMainMenu);
	add(gszMainMenu, size, "\yBlock Maker Menu^n^n");
	add(gszMainMenu, size, "\r1. \wBlock Menu^n");
	add(gszMainMenu, size, "\r2. \wTeleport Menu^n");
	add(gszMainMenu, size, "\r3. \wTimer Menu^n");
	add(gszMainMenu, size, "\r4. \wMeasuring Tool^n");
	add(gszMainMenu, size, "\r5. \wLong Jump Creator^n^n");
	add(gszMainMenu, size, "\r6. %sNoclip: %s^n");
	add(gszMainMenu, size, "\r7. %sGodmode: %s^n^n^n");
	add(gszMainMenu, size, "\r9. \wOptions Menu^n");
	add(gszMainMenu, size, "\r0. \wClose");
	gKeysMainMenu = B1 | B2 | B3 | B4 | B5 | B6 | B7 | B9 | B0;
	
	//create block menu
	size = sizeof(gszBlockMenu);
	add(gszBlockMenu, size, "\yBlock Menu^n^n");
	add(gszBlockMenu, size, "\r1. \wBlock Type: \y%s^n");
	add(gszBlockMenu, size, "\r2. %sCreate Block^n");
	add(gszBlockMenu, size, "\r3. %sConvert Block^n");
	add(gszBlockMenu, size, "\r4. %sDelete Block^n");
	add(gszBlockMenu, size, "\r5. %sRotate Block^n^n");
	add(gszBlockMenu, size, "\r6. %sNoclip: %s^n");
	add(gszBlockMenu, size, "\r7. %sGodmode: %s^n");
	add(gszBlockMenu, size, "\r8. \wBlock Size: \y%s^n^n");
	add(gszBlockMenu, size, "\r9. \wOptions Menu^n");
	add(gszBlockMenu, size, "\r0. \wBack");
	gKeysBlockMenu = B1 | B2 | B3 | B4 | B5 | B6 | B7 | B8 | B9 | B0;
	gKeysBlockSelectionMenu = B1 | B2 | B3 | B4 | B5 | B6 | B7 | B8 | B9 | B0;
	
	//create teleport menu
	size = sizeof(gszTeleportMenu);
	add(gszTeleportMenu, size, "\yTeleporter Menu^n^n");
	add(gszTeleportMenu, size, "\r1. %sTeleport Start^n");
	add(gszTeleportMenu, size, "\r2. %sTeleport Destination^n");
	add(gszTeleportMenu, size, "\r3. %sSwap Teleport Start/Destination^n");
	add(gszTeleportMenu, size, "\r4. %sDelete Teleport^n");
	add(gszTeleportMenu, size, "\r5. %sShow Teleport Path^n^n");
	add(gszTeleportMenu, size, "\r6. %sNoclip: %s^n");
	add(gszTeleportMenu, size, "\r7. %sGodmode: %s^n^n^n");
	add(gszTeleportMenu, size, "\r9. \wOptions Menu^n");
	add(gszTeleportMenu, size, "\r0. \wBack");
	gKeysTeleportMenu = B1 | B2 | B3 | B4 | B5 | B6 | B7 | B9 | B0;
	
	//create timer menu
	size = sizeof(gszTimerMenu);
	add(gszTimerMenu, size, "\yTimer Menu^n^n");
	add(gszTimerMenu, size, "\r1. %sTimer Start^n");
	add(gszTimerMenu, size, "\r2. %sTimer End^n");
	add(gszTimerMenu, size, "\r3. %sSwap Start/End^n");
	add(gszTimerMenu, size, "\r4. %sDelete Timer^n");
	add(gszTimerMenu, size, "\r5. %sRotate Timer^n^n");
	add(gszTimerMenu, size, "\r6. %sNoclip: %s^n");
	add(gszTimerMenu, size, "\r7. %sGodmode: %s^n^n^n");
	add(gszTimerMenu, size, "\r9. \wOptions Menu^n");
	add(gszTimerMenu, size, "\r0. \wBack");
	gKeysTimerMenu = B1 | B2 | B3 | B4 | B5 | B6 | B7 | B9 | B0;
	
	//measuring tool menu
	size = sizeof(gszMeasureMenu);
	add(gszMeasureMenu, size, "\yMeasuring Tool Menu^n^n");
	add(gszMeasureMenu, size, "\r1. \wBlock 1: \y%s^n");
	add(gszMeasureMenu, size, "\r2. \wBlock 2: \y%s^n");
	add(gszMeasureMenu, size, "\r3. \wPosition 1: \y%.2f, %.2f, %.2f^n");
	add(gszMeasureMenu, size, "\r4. \wPosition 2: \y%.2f, %.2f, %.2f^n^n");
	add(gszMeasureMenu, size, "\r5. %sMeasuring Tool: %s^n");
	add(gszMeasureMenu, size, "\r6. %sNoclip: %s^n");
	add(gszMeasureMenu, size, "\r7. %sGodmode: %s^n^n^n");
	add(gszMeasureMenu, size, "\r9. \wOptions Menu^n");
	add(gszMeasureMenu, size, "\r0. \wBack");
	gKeysMeasureMenu = B1 | B2 | B3 | B4 | B5 | B6 | B7 | B9 | B0;
	
	//long jump menu
	size = sizeof(gszLongJumpMenu);
	add(gszLongJumpMenu, size, "\yLong Jump Creator Menu^n^n");
	add(gszLongJumpMenu, size, "\r1. \wDistance +^n");
	add(gszLongJumpMenu, size, "\r2. %sCreate \y%d %sUnit Long Jump Along \y%s^n");
	add(gszLongJumpMenu, size, "\r3. \wDistance -^n");
	add(gszLongJumpMenu, size, "\r4. %sDelete Block^n");
	add(gszLongJumpMenu, size, "\r5. %sRotate^n^n");
	add(gszLongJumpMenu, size, "\r6. %sNoclip: %s^n");
	add(gszLongJumpMenu, size, "\r7. %sGodmode: %s^n");
	add(gszLongJumpMenu, size, "\r8. \wBlock Size: \y%s^n^n");
	add(gszLongJumpMenu, size, "\r9. \wOptions Menu^n");
	add(gszLongJumpMenu, size, "\r0. \wBack");
	gKeysLongJumpMenu = B1 | B2 | B3 | B4 | B5 | B6 | B7 | B8 | B9 | B0;
	
	//create the options menu
	size = sizeof(gszOptionsMenu);
	add(gszOptionsMenu, size, "\yOptions Menu^n^n");
	add(gszOptionsMenu, size, "\r1. %sSnapping: %s^n");
	add(gszOptionsMenu, size, "\r2. %sSnapping gap: \y%.1f^n");
	add(gszOptionsMenu, size, "\r3. %sAdd to group^n");
	add(gszOptionsMenu, size, "\r4. %sClear group^n^n");
	add(gszOptionsMenu, size, "\r5. %sDelete all blocks^n");
	add(gszOptionsMenu, size, "\r6. %sDelete all teleports^n^n");
	add(gszOptionsMenu, size, "\r7. %sSave to file^n");
	add(gszOptionsMenu, size, "\r8. %sLoad from file^n");
	add(gszOptionsMenu, size, "\r9. \wShow help^n");
	add(gszOptionsMenu, size, "\r0. \wBack");
	gKeysOptionsMenu = B1 | B2 | B3 | B4 | B5 | B6 | B7 | B8 | B9 | B0;
	
	//create choice (YES/NO) menu
	size = sizeof(gszChoiceMenu);
	add(gszChoiceMenu, size, "\y%s^n^n");
	add(gszChoiceMenu, size, "\r1. \wYes^n");
	add(gszChoiceMenu, size, "\r2. \wNo^n^n^n^n^n^n^n^n^n^n");
	add(gszChoiceMenu, size, "\r0. \wBack");
	gKeysChoiceMenu = B1 | B2 | B0;
}

setupBlockRendering(blockType, renderType, red, green, blue, alpha)
{
	gRender[blockType] = renderType;
	gRed[blockType] = red;
	gGreen[blockType] = green;
	gBlue[blockType] = blue;
	gAlpha[blockType] = alpha;
}

setBlockModelNameLarge(szBlockModelTarget[256], szBlockModelSource[256], size)
{
	szBlockModelTarget = szBlockModelSource;
	replace(szBlockModelTarget, size, ".mdl", "_large.mdl");
}

setBlockModelNameSmall(szBlockModelTarget[256], szBlockModelSource[256], size)
{
	szBlockModelTarget = szBlockModelSource;
	replace(szBlockModelTarget, size, ".mdl", "_small.mdl");
}

processBlockModels()
{     
	//get full path to block models config file
	new szBlockModelsFile[96];
	get_configsdir(szBlockModelsFile, 96);
	add(szBlockModelsFile, 96, "/blockmaker_models.ini");
	
	//open block models config file for reading
	new f = fopen(szBlockModelsFile, "rt");
	new szData[160];
	new szType[32];
	new szBlockModel[256];
	new szRender[16];
	new szRed[8];
	new szGreen[8];
	new szBlue[8];
	new szAlpha[8];
	new blockType;
	new render;
	new red;
	new green;
	new blue;
	new alpha;
	
	//iterate through all the lines in the file
	while (!feof(f))
	{
		//clear data
		szBlockModel = "";
		szRender = "";
		szRed = "";
		szGreen = "";
		szBlue = "";
		szAlpha = "";
		blockType = -1;
		
		//get and parse a line of data from file
		fgets(f, szData, 160);
		parse(szData, szType, 24, szBlockModel, 64, szRender, 16, szRed, 8, szGreen, 8, szBlue, 8, szAlpha, 8);
		
		//replace '\' with '/' in block model path
		replace_all(szBlockModel, 64, "\", "/");
		
		if (equal(szType, "PLATFORM")) blockType = BM_PLATFORM;
		else if (equal(szType, "BHOP")) blockType = BM_BHOP;
		else if (equal(szType, "DAMAGE")) blockType = BM_DAMAGE;
		else if (equal(szType, "HEALER")) blockType = BM_HEALER;
		else if (equal(szType, "NOFALLDAMAGE")) blockType = BM_NOFALLDAMAGE;
		else if (equal(szType, "ICE")) blockType = BM_ICE;
		else if (equal(szType, "TRAMPOLINE")) blockType = BM_TRAMPOLINE;
		else if (equal(szType, "SPEEDBOOST")) blockType = BM_SPEEDBOOST;
		else if (equal(szType, "INVINCIBILITY")) blockType = BM_INVINCIBILITY;
		else if (equal(szType, "STEALTH")) blockType = BM_STEALTH;
		else if (equal(szType, "DEATH")) blockType = BM_DEATH;
		else if (equal(szType, "NUKE")) blockType = BM_NUKE;
		else if (equal(szType, "CAMOUFLAGE")) blockType = BM_CAMOUFLAGE;
		else if (equal(szType, "LOWGRAVITY")) blockType = BM_LOWGRAVITY;
		else if (equal(szType, "FIRE")) blockType = BM_FIRE;
		else if (equal(szType, "SLAP")) blockType = BM_SLAP;
		else if (equal(szType, "RANDOM")) blockType = BM_RANDOM;
		else if (equal(szType, "HONEY")) blockType = BM_HONEY;
		else if (equal(szType, "BARRIER_CT")) blockType = BM_BARRIER_CT;
		else if (equal(szType, "BARRIER_T")) blockType = BM_BARRIER_T;
		else if (equal(szType, "BOOTSOFSPEED")) blockType = BM_BOOTSOFSPEED;
		else if (equal(szType, "GLASS")) blockType = BM_GLASS;
		else if (equal(szType, "BHOP_NOSLOW")) blockType = BM_BHOP_NOSLOW;
		else if (equal(szType, "AUTO_BHOP")) blockType = BM_AUTO_BHOP;
		
		//if we're dealing with a valid block type
		if (blockType >= 0 && blockType < gBlockMax)
		{
			new bool:bDoRendering = false;
			
			//if block model file exists
			if (file_exists(szBlockModel))
			{
				//set block models for given block type
				gszBlockModels[blockType] = szBlockModel;
				
				//block model file does exist so process rendering values as well
				bDoRendering = true;
			}
			else
			{
				if (equal(szBlockModel, "DEFAULT"))
				{
					//block is set to use default so process rendering values
					bDoRendering = true;
				}
			}
			
			//process rendering values
			if (bDoRendering)
			{
				render = NORMAL;
				red = 255;
				green = 255;
				blue = 255;
				alpha = 255;
				
				if (equal(szRender, "GLOWSHELL")) render = GLOWSHELL;
				if (equal(szRender, "TRANSCOLOR")) render = TRANSCOLOR;
				if (equal(szRender, "TRANSALPHA")) render = TRANSALPHA;
				if (equal(szRender, "TRANSWHITE")) render = TRANSWHITE;
				
				if (strlen(szRed) > 0) red = str_to_num(szRed);
				if (strlen(szGreen) > 0) green = str_to_num(szGreen);
				if (strlen(szBlue) > 0) blue = str_to_num(szBlue);
				if (strlen(szAlpha) > 0) alpha = str_to_num(szAlpha);
				
				//set blocks rendering values
				setupBlockRendering(blockType, render, red, green, blue, alpha);
			}
		}
	}
	
	//close file
	fclose(f);
}

/***** FORWARDS *****/
public client_connect(id)
{
	//make sure snapping is on by default
	gbSnapping[id] = true;
	
	//players chosen snapping gap defaults to 0.0 units
	gfSnappingGap[id] = 0.0;
	
	//make sure players can die
	gbNoFallDamage[id] = false;
	
	//players block selection menu is on page 1
	gBlockMenuPage[id] = 1;
	
	//player doesn't have godmode or noclip
	gbAdminGodmode[id] = false;
	gbAdminNoclip[id] = false;
	
	//player doesn't have any blocks grouped
	gGroupCount[id] = 0;
	
	//set default long jump distance and axis
	gLongJumpDistance[id] = 240;
	gLongJumpAxis[id] = X;
	
	//reset players timers
	resetTimers(id);
}

public client_disconnect(id)
{
	//clear players group
	groupClear(id);
	
	//if player was grabbing an entity when they disconnected
	if (gGrabbed[id])
	{
		//if entity is valid
		if (is_valid_ent(gGrabbed[id]))
		{
			//set the entity to 'not being grabbed'
			entity_set_int(gGrabbed[id], EV_INT_iuser2, 0);
		}
		
		gGrabbed[id] = 0;
	}
	
	//disable measure tool and reset values
	gbMeasureToolEnabled[id] = false;
	gMeasureToolBlock1[id] = 0;
	gMeasureToolBlock2[id] = 0;
	gvMeasureToolPos1[id][0] = 0.0;
	gvMeasureToolPos1[id][1] = 0.0;
	gvMeasureToolPos1[id][2] = 0.0;
	gvMeasureToolPos2[id][0] = 0.0;
	gvMeasureToolPos2[id][1] = 0.0;
	gvMeasureToolPos2[id][2] = 0.0;
}

public pfn_touch(ent, id)
{
	//if touch event involves a player
	if (id > 0 && id <= 32)
	{
		//if player is alive
		if (is_user_alive(id))
		{
			//if entity involved is a block
			if (isBlock(ent))
			{
				//get the blocktype
				new blockType = entity_get_int(ent, EV_INT_body);
				
				//if blocktype is a bunnyhop block or barrier
				if (blockType == BM_BHOP || blockType == BM_BARRIER_CT || blockType == BM_BARRIER_T || blockType == BM_BHOP_NOSLOW)
				{
					//if task does not already exist for bunnyhop block
					if (!task_exists(TASK_BHOPSOLIDNOT + ent) && !task_exists(TASK_BHOPSOLID + ent))
					{
						//get the players team
						new CsTeams:team = cs_get_user_team(id);
						
						//if players team is different to barrier
						if (blockType == BM_BARRIER_CT && team == CS_TEAM_T)
						{
							//make block SOLID_NOT without any delay
							taskSolidNot(TASK_BHOPSOLIDNOT + ent);
						}
						else if (blockType == BM_BARRIER_T && team == CS_TEAM_CT)
						{
							//make block SOLID_NOT without any delay
							taskSolidNot(TASK_BHOPSOLIDNOT + ent);
						}
						else if (blockType == BM_BHOP || blockType == BM_BHOP_NOSLOW)
						{
							//set bhop block to be SOLID_NOT after 0.1 seconds
							set_task(0.1, "taskSolidNot", TASK_BHOPSOLIDNOT + ent);
						}
					}
				}
			}
		}
	}
	
	return PLUGIN_CONTINUE;
}

public server_frame()
{
	new ent;
	new Float:vOrigin[3];
	new bool:entNear = false;
	new tele;
	new entinsphere;
	
	//iterate through all players and remove slow down after jumping
	for (new i = 1; i <= 32; ++i)
	{
		if (is_user_alive(i))
		{
			if (gbOnIce[i] || gbNoSlowDown[i])
			{
				entity_set_float(i, EV_FL_fuser2, 0.0);
			}
		}
	}
	
	//find all teleport start entities in map and if a player is close to one, teleport the player
	while ((ent = find_ent_by_class(ent, gszTeleportStartClassname)))
	{
		new Float:vOrigin[3];
		entity_get_vector(ent, EV_VEC_origin, vOrigin);
		
		//teleport players and grenades within a sphere around the teleport start entity
		entinsphere = -1;
		while ((entinsphere = find_ent_in_sphere(entinsphere, vOrigin, 32.0)))
		{
			//get classname of entity
			new szClassname[32];
			entity_get_string(entinsphere, EV_SZ_classname, szClassname, 32);
			
			//if entity is a player
			if (entinsphere > 0 && entinsphere <= 32)
			{
				//only teleport player if they're alive
				if (is_user_alive(entinsphere))
				{
					//teleport the player
					actionTeleport(entinsphere, ent);
				}
			}
			//or if entity is a grenade
			else if (equal(szClassname, "grenade"))
			{
				//get the end of the teleport
				tele = entity_get_int(ent, EV_INT_iuser1);
				
				//if the end of the teleport exists
				if (tele)
				{
					//set the end of the teleport to be not solid
					entity_set_int(tele, EV_INT_solid, SOLID_NOT);	//can't be grabbed or deleted
					
					//teleport the grenade
					actionTeleport(entinsphere, ent);
					
					//set a time in the teleport it will become solid after 2 seconds
					entity_set_float(tele, EV_FL_ltime, halflife_time() + 2.0);
				}
			}
		}
	}
	
	//make teleporters SOLID_NOT when players are near them
	while ((ent = find_ent_by_class(ent, gszTeleportEndClassname)))
	{
		//get the origin of the teleport end entity
		entity_get_vector(ent, EV_VEC_origin, vOrigin);
		
		//compare this origin with all player and grenade origins
		entinsphere = -1;
		while ((entinsphere = find_ent_in_sphere(entinsphere, vOrigin, 64.0)))
		{
			//get classname of entity
			new szClassname[32];
			entity_get_string(entinsphere, EV_SZ_classname, szClassname, 32);
			
			//if entity is a player
			if (entinsphere > 0 && entinsphere <= 32)
			{
				//make sure player is alive
				if (is_user_alive(entinsphere))
				{
					entNear = true;
					
					break;
				}
			}
			//or if entity is a grenade
			else if (equal(szClassname, "grenade"))
			{
				entNear = true;
				
				break;
			}
		}
		
		//set the solid type of the teleport end entity depending on whether or not a player is near
		if (entNear)
		{
			//only do this if it is not being grabbed
			if (entity_get_int(ent, EV_INT_iuser2) == 0)
			{
				entity_set_int(ent, EV_INT_solid, SOLID_NOT);	//can't be grabbed or deleted
			}
		}
		else
		{
			//get time from teleport end entity to check if it can go solid
			new Float:fTime = entity_get_float(ent, EV_FL_ltime);
			
			//only set teleport end entity to solid if its 'solid not' time has elapsed
			if (halflife_time() >= fTime)
			{
				entity_set_int(ent, EV_INT_solid, SOLID_BBOX);	//CAN be grabbed and deleted
			}
		}
	}
	
	//find all block entities
	while ((ent = find_ent_by_class(ent, gszBlockClassname)))
	{
		//get block type
		new blockType = entity_get_int(ent, EV_INT_body);
		
		//if block is a speed boost
		if (blockType == BM_SPEEDBOOST)
		{
			new Float:vOrigin[3];
			new Float:pOrigin[3];
			new Float:dist = 9999.9;
			new Float:playerDist = 9999.9;
			new nearestPlayer = 0;
			
			//get the origin of the speed boost block
			entity_get_vector(ent, EV_VEC_origin, vOrigin);
			
			//compare this origin with all players origins to find the nearest player to the block
			for (new id = 1; id <= 32; ++id)
			{
				//if player is alive
				if (is_user_alive(id))
				{
					//get player origin
					entity_get_vector(id, EV_VEC_origin, pOrigin);
					
					//get the distance from the block to the player
					dist = get_distance_f(vOrigin, pOrigin);
					
					if (dist < playerDist)
					{
						nearestPlayer = id;
						playerDist = dist;
					}
				}
			}
			
			//if we found a player within 100 units of the speed boost block
			if (nearestPlayer > 0 && playerDist < 200.0)
			{
				//get the sprite on top of the speed boost block
				new sprite = entity_get_int(ent, EV_INT_iuser3);
				
				//make sure sprite entity is valid
				if (sprite)
				{
					new Float:vAngles[3];
					
					//get the direction the player is looking
					entity_get_vector(nearestPlayer, EV_VEC_angles, vAngles);
					
					//set the angles of the sprite to be the same as the player
					vAngles[0] = 90.0;	//always make sure sprite is flat to the block
					vAngles[1] += 90.0;	//rotate the sprite by 90 because it doesnt point up (PAT!)
					entity_set_vector(sprite, EV_VEC_angles, vAngles);
				}
			}
		}
	}
}

public client_PreThink(id)
{
	//make sure player is connected
	if (is_user_connected(id))
	{
		//display type of block that player is aiming at
		new ent, body;
		get_user_aiming(id, ent, body, 320);
		
		if (isBlock(ent))
		{
			new blockType = entity_get_int(ent, EV_INT_body);
			
			set_hudmessage(gHudRed, gHudGreen, gHudBlue, gfTextX, gfTextY, gHudEffects, gfHudFxTime, gfHudHoldTime, gfHudFadeInTime, gfHudFadeOutTime, gHudChannel);
			show_hudmessage(id, "Block Type: %s", gszBlockNames[blockType]);
		}
		
		//if player has the measure tool enabled
		if (gbMeasureToolEnabled[id])
		{
			new Float:vOrigin1[3];
			new Float:vOrigin2[3];
			new Float:vSizeMax1[3];
			new Float:vSizeMax2[3];
			new Float:fDist = 0.0;
			new Float:fX = 0.0;
			new Float:fY = 0.0;
			new Float:fZ = 0.0;
			
			if (is_valid_ent(gMeasureToolBlock1[id]))
			{
				if (is_valid_ent(gMeasureToolBlock2[id]))
				{
					//get position and size information from the blocks
					entity_get_vector(gMeasureToolBlock1[id], EV_VEC_origin, vOrigin1);
					entity_get_vector(gMeasureToolBlock2[id], EV_VEC_origin, vOrigin2);
					entity_get_vector(gMeasureToolBlock1[id], EV_VEC_maxs, vSizeMax1);
					entity_get_vector(gMeasureToolBlock2[id], EV_VEC_maxs, vSizeMax2);
					
					//calculate differences on X, Y and Z
					fX = floatabs(vOrigin2[0] - vOrigin1[0]) - vSizeMax1[0] - vSizeMax2[0];
					fY = floatabs(vOrigin2[1] - vOrigin1[1]) - vSizeMax1[1] - vSizeMax2[1];
					fZ = (vOrigin2[2] + vSizeMax2[2]) - (vOrigin1[2] + vSizeMax1[2]);
					
					//make sure X and Y are never below 0.0
					if (fX < 0.0) fX = 0.0;
					if (fY < 0.0) fY = 0.0;
				}
				else
				{
					gMeasureToolBlock2[id] = 0;
				}
			}
			else
			{
				gMeasureToolBlock1[id] = 0;
			}
			
			//calculate the sums of the 2 positions
			new Float:pos1sum = gvMeasureToolPos1[id][0] + gvMeasureToolPos1[id][1] + gvMeasureToolPos1[id][2];
			new Float:pos2sum = gvMeasureToolPos2[id][0] + gvMeasureToolPos2[id][1] + gvMeasureToolPos2[id][2];
			
			//calculate distance between measure tool positions 1 and 2
			if (pos1sum != 0.0 && pos2sum != 0.0)
			{
				fDist = get_distance_f(gvMeasureToolPos1[id], gvMeasureToolPos2[id]);
			}
			
			//show the values to the player
			set_hudmessage(gHudRed, gHudGreen, gHudBlue, 0.02, 0.22, gHudEffects, gfHudFxTime, gfHudHoldTime, gfHudFadeInTime, gfHudFadeOutTime, gHudChannel);
			show_hudmessage(id, "X: %.2f^nY: %.2f^nZ: %.2f^nDistance: %.2f", fX, fY, fZ, fDist);
		}
		
		//make sure player is alive
		if (is_user_alive(id))
		{
			//if player has low gravity
			if (gbLowGravity[id])
			{
				//get players flags
				new flags = entity_get_int(id, EV_INT_flags);
				
				//if player has feet on the ground, set gravity to normal
				if (flags & FL_ONGROUND)
				{
					set_user_gravity(id);
					
					gbLowGravity[id] = false;
				}
			}
			
			//if player has auto bhop
			if (gbAutoBhop[id])
			{
				//get players old buttons
				new oldbuttons = get_user_oldbutton(id);
				
				//remove jump flag from old buttons
				oldbuttons &= ~IN_JUMP;
				entity_set_int(id, EV_INT_oldbuttons, oldbuttons);
			}
			
			//trace directly down to see if there is a block beneath player
			new Float:pOrigin[3];
			new Float:pSize[3];
			new Float:pMaxs[3];
			new Float:vTrace[3];
			new Float:vReturn[3];
			entity_get_vector(id, EV_VEC_origin, pOrigin);
			entity_get_vector(id, EV_VEC_size, pSize);
			entity_get_vector(id, EV_VEC_maxs, pMaxs);
			
			//calculate position of players feet
			pOrigin[2] = pOrigin[2] - ((pSize[2] - 36.0) - (pMaxs[2] - 36.0));
			
			//make the trace small for some blocks
			vTrace[2] = pOrigin[2] - 1.0;
			
			//do 4 traces for each corner of the player
			for (new i = 0; i < 4; ++i)
			{
				switch (i)
				{
					case 0: { vTrace[0] = pOrigin[0] - 16; vTrace[1] = pOrigin[1] + 16; }
					case 1: { vTrace[0] = pOrigin[0] + 16; vTrace[1] = pOrigin[1] + 16; }
					case 2: { vTrace[0] = pOrigin[0] + 16; vTrace[1] = pOrigin[1] - 16; }
					case 3: { vTrace[0] = pOrigin[0] - 16; vTrace[1] = pOrigin[1] - 16; }
				}
				
				ent = trace_line(id, pOrigin, vTrace, vReturn);
				
				//if entity found is a block
				if (isBlock(ent))
				{
					new blockType = entity_get_int(ent, EV_INT_body);
					
					switch (blockType)
					{
						case BM_HEALER: actionHeal(id);
						case BM_DAMAGE: actionDamage(id);
						case BM_INVINCIBILITY: actionInvincible(id, false);
						case BM_STEALTH: actionStealth(id, false);
						case BM_TRAMPOLINE: actionTrampoline(id);
						case BM_SPEEDBOOST: actionSpeedBoost(id);
						case BM_DEATH: actionDeath(id);
						case BM_NUKE: actionNuke(id, false);
						case BM_LOWGRAVITY: actionLowGravity(id);
						case BM_CAMOUFLAGE: actionCamouflage(id, false);
						case BM_FIRE: actionFire(id, ent);
						case BM_SLAP: actionSlap(id);
						case BM_RANDOM: actionRandom(id, ent);
						case BM_HONEY: actionHoney(id);
						case BM_BOOTSOFSPEED: actionBootsOfSpeed(id, false);
						case BM_AUTO_BHOP: actionAutoBhop(id, false);
					}
				}
			}
			
			//make the trace longer for other blocks
			vTrace[2] = pOrigin[2] - 20.0;
			
			//do 4 traces for each corner of the player
			for (new i = 0; i < 4; ++i)
			{
				switch (i)
				{
					case 0: { vTrace[0] = pOrigin[0] - 16; vTrace[1] = pOrigin[1] + 16; }
					case 1: { vTrace[0] = pOrigin[0] + 16; vTrace[1] = pOrigin[1] + 16; }
					case 2: { vTrace[0] = pOrigin[0] + 16; vTrace[1] = pOrigin[1] - 16; }
					case 3: { vTrace[0] = pOrigin[0] - 16; vTrace[1] = pOrigin[1] - 16; }
				}
				
				ent = trace_line(id, pOrigin, vTrace, vReturn);
				
				//if entity found is a block
				if (isBlock(ent))
				{
					new blockType = entity_get_int(ent, EV_INT_body);
					
					switch (blockType)
					{
						case BM_TRAMPOLINE: actionTrampoline(id);
						case BM_NOFALLDAMAGE: actionNoFallDamage(id);
						case BM_ICE: actionOnIce(id);
						case BM_BHOP_NOSLOW: actionNoSlowDown(id);
					}
				}
			}
			
			//display amount of invincibility/stealth/camouflage/boots of speed timeleft
			new Float:fTime = halflife_time();
			new Float:fTimeleftInvincible = gfInvincibleTimeOut[id] - fTime;
			new Float:fTimeleftStealth = gfStealthTimeOut[id] - fTime;
			new Float:fTimeleftCamouflage = gfCamouflageTimeOut[id] - fTime;
			new Float:fTimeleftBootsOfSpeed = gfBootsOfSpeedTimeOut[id] - fTime;
			new Float:fTimeleftAutoBhop = gfAutoBhopTimeOut[id] - fTime;
			new szTextToShow[256] = "";
			new szText[48];
			new bool:bShowText = false;
			
			if (fTimeleftInvincible >= 0.0)
			{
				format(szText, sizeof(szText), "Invincible: %.1f^n", fTimeleftInvincible);
				add(szTextToShow, sizeof(szTextToShow), szText);
				bShowText = true;
			}
			
			if (fTimeleftStealth >= 0.0)
			{
				format(szText, sizeof(szText), "Stealth: %.1f^n", fTimeleftStealth);
				add(szTextToShow, sizeof(szTextToShow), szText);
				bShowText = true;
			}
			
			if (fTimeleftCamouflage >= 0.0)
			{
				//if player is a CT
				if (get_user_team(id) == 1)
				{
					format(szText, sizeof(szText), "You look like a Counter-Terrorist: %.1f^n", fTimeleftCamouflage);
				}
				else
				{
					format(szText, sizeof(szText), "You look like a Terrorist: %.1f^n", fTimeleftCamouflage);
				}
				
				add(szTextToShow, sizeof(szTextToShow), szText);
				bShowText = true;
			}
			
			if (fTimeleftBootsOfSpeed >= 0.0)
			{
				format(szText, sizeof(szText), "Boots of speed: %.1f^n", fTimeleftBootsOfSpeed);
				add(szTextToShow, sizeof(szTextToShow), szText);
				bShowText = true;
			}
			
			if (fTimeleftAutoBhop >= 0.0)
			{
				format(szText, sizeof(szText), "Auto bunnyhop: %.1f^n", fTimeleftAutoBhop);
				add(szTextToShow, sizeof(szTextToShow), szText);
				bShowText = true;
			}
			
			//if there is some text to show then show it
			if (bShowText)
			{
				set_hudmessage(gHudRed, gHudGreen, gHudBlue, gfTextX, gfTextY, gHudEffects, gfHudFxTime, gfHudHoldTime, gfHudFadeInTime, gfHudFadeOutTime, gHudChannel);
				show_hudmessage(id, szTextToShow);
			}
		}
		
		//get players buttons
		new buttons = get_user_button(id);
		new oldbuttons = get_user_oldbutton(id);
		
		//if player has grabbed an entity
		if (gGrabbed[id] > 0)
		{
			//check for a single press on the following buttons
			if (buttons & IN_JUMP && !(oldbuttons & IN_JUMP)) cmdJump(id);
			if (buttons & IN_DUCK && !(oldbuttons & IN_DUCK)) cmdDuck(id);
			if (buttons & IN_ATTACK && !(oldbuttons & IN_ATTACK)) cmdAttack(id);
			if (buttons & IN_ATTACK2 && !(oldbuttons & IN_ATTACK2)) cmdAttack2(id);
			
			//prevent player from using attack
			buttons &= ~IN_ATTACK;
			entity_set_int(id, EV_INT_button, buttons);
			
			//if player has grabbed a valid entity
			if (is_valid_ent(gGrabbed[id]))
			{
				//if block the player is grabbing is in their group and group count is larger than 1
				if (isBlockInGroup(id, gGrabbed[id]) && gGroupCount[id] > 1)
				{
					new Float:vMoveTo[3];
					new Float:vOffset[3];
					new Float:vOrigin[3];
					new block;
					
					//move the block the player has grabbed and get the move vector
					moveGrabbedEntity(id, vMoveTo);
					
					//move the rest of the blocks in the players group using vector for grabbed block
					for (new i = 0; i <= gGroupCount[id]; ++i)
					{
						block = gGroupedBlocks[id][i];
						
						//if block is still in this players group
						if (isBlockInGroup(id, block))
						{
							//get offset vector from block
							entity_get_vector(block, EV_VEC_vuser1, vOffset);
							
							vOrigin[0] = vMoveTo[0] - vOffset[0];
							vOrigin[1] = vMoveTo[1] - vOffset[1];
							vOrigin[2] = vMoveTo[2] - vOffset[2];
							
							//move grouped block
							moveEntity(id, block, vOrigin, false);
						}
					}
				}
				else
				{
					//move the entity the player has grabbed
					moveGrabbedEntity(id);
				}
			}
			else
			{
				cmdRelease(id);
			}
		}
		
		//if player has just deleted something
		if (gbJustDeleted[id])
		{
			//if player is pressing attack2
			if (buttons & IN_ATTACK2)
			{
				//prevent player from using attack2
				buttons &= ~IN_ATTACK2;
				entity_set_int(id, EV_INT_button, buttons);
			}
			else
			{
				//player has now NOT just deleted something
				gbJustDeleted[id] = false;
			}
		}
	}
	
	return PLUGIN_CONTINUE;
}

public client_PostThink(id)
{
	//if player is alive
	if (is_user_alive(id))
	{
		//if player is set to not get fall damage
		if (gbNoFallDamage[id])
		{
			entity_set_int(id,  EV_INT_watertype, -3);
			gbNoFallDamage[id] = false;
		}
	}
}

public forward_EmitSound(id, channel, sample[])
{
	if (is_user_alive(id) && containi(sample, "common/wpn_select.wav") >= 0)
	{
		actionTimer(id);
	}
}

/***** EVENTS *****/
public eventPlayerDeath()
{
	new id = read_data(2);
	
	resetTimers(id);
}

public eventRoundRestart()
{
	//iterate through all players
	for (new id = 1; id <= 32; ++id)
	{
		//reset all players timers
		resetTimers(id);
	}
}

public eventPlayerSpawn(id)
{
	//if player has godmode enabled
	if (gbAdminGodmode[id])
	{
		//re-enable godmode on player
		set_user_godmode(id, 1);
	}
	
	//if player has noclip enabled
	if (gbAdminNoclip[id])
	{
		//re-enable noclip on player
		set_user_noclip(id, 1);
	}
}

resetTimers(id)
{
	gfInvincibleTimeOut[id] = 0.0;
	gfInvincibleNextUse[id] = 0.0;
	gfStealthTimeOut[id] = 0.0;
	gfStealthNextUse[id] = 0.0;
	gfCamouflageTimeOut[id] = 0.0;
	gfCamouflageNextUse[id] = 0.0;
	gfNukeNextUse[id] = 0.0;
	gbOnFire[id] = false;
	gfRandomNextUse[id] = 0.0;
	gfBootsOfSpeedTimeOut[id] = 0.0;
	gfBootsOfSpeedNextUse[id] = 0.0;
	gfAutoBhopTimeOut[id] = 0.0;
	gfAutoBhopNextUse[id] = 0.0;
	
	//remove any task this player might have
	new taskId = TASK_INVINCIBLE + id;
	if (task_exists(taskId)) 
	{
		remove_task(taskId);
	}
	
	taskId = TASK_STEALTH + id;
	if (task_exists(taskId))
	{
		remove_task(taskId);
	}
	
	taskId = TASK_CAMOUFLAGE + id;
	if (task_exists(taskId))
	{
		remove_task(taskId);
		
		//change back to players old model
		cs_set_user_model(id, gszCamouflageOldModel[id]);
	}
	
	taskId = TASK_BOOTSOFSPEED + id;
	if (task_exists(taskId))
	{
		remove_task(taskId);
	}
	
	taskId = TASK_AUTOBHOP + id;
	if (task_exists(taskId))
	{
		remove_task(taskId);
	}
	
	//make sure player is connected
	if (is_user_connected(id))
	{
		//set players rendering to normal
		set_user_rendering(id, kRenderFxGlowShell, 0, 0, 0, kRenderNormal, 255);
	}
	
	//player is not 'on ice'
	gbOnIce[id] = false;
	
	//player slows down after jumping
	gbNoSlowDown[id] = false;
	
	//player does not have auto bhop
	gbAutoBhop[id] = false;
	
	//player does not have a timer
	gbHasTimer[id] = false;
}

public eventCurWeapon(id)
{
	new Float:fTime = halflife_time();
	new Float:fTimeleftBootsOfSpeed = gfBootsOfSpeedTimeOut[id] - fTime;
	
	//if the player has the boots of speed
	if (fTimeleftBootsOfSpeed >= 0.0)
	{
		//set their max speed so they obtain their speed after changing weapon
		set_user_maxspeed(id, gfBootsMaxSpeed);
	}
}

/***** BLOCK ACTIONS *****/
actionDamage(id)
{
	if (halflife_time() >= gfNextDamageTime[id])
	{
		if (get_user_health(id) > 0)
		{
			new Float:amount = get_cvar_float("bm_damageamount");
			fakedamage(id, "damage block", amount, DMG_CRUSH);
		}
		
		gfNextDamageTime[id] = halflife_time() + 0.5;
	}
}

actionHeal(id)
{
	if (halflife_time() >= gfNextHealTime[id])
	{
		new hp = get_user_health(id);
		new amount = floatround(get_cvar_float("bm_healamount"), floatround_floor);
		new sum = (hp + amount);
		
		if (sum < 100)
		{
			set_user_health(id, sum);
		}
		else
		{
			set_user_health(id, 100);
		}
		
		gfNextHealTime[id] = halflife_time() + 0.5;
	}
}

actionInvincible(id, OverrideTimer)
{
	new Float:fTime = halflife_time();
	
	if (fTime >= gfInvincibleNextUse[id] || OverrideTimer)
	{
		new Float:fTimeout = get_cvar_float("bm_invincibletime");
		
		set_user_godmode(id, 1);
		set_task(fTimeout, "taskInvincibleRemove", TASK_INVINCIBLE + id, "", 0, "a", 1);
		
		//only make player glow white for invincibility if player isn't already stealth
		if (fTime >= gfStealthTimeOut[id])
		{
			set_user_rendering(id, kRenderFxGlowShell, 255, 255, 255, kRenderNormal, 16);
		}
		
		//play invincibility sound
		emit_sound(id, CHAN_STATIC, gszInvincibleSound, 1.0, ATTN_NORM, 0, PITCH_NORM);
		
		gfInvincibleTimeOut[id] = fTime + fTimeout;
		gfInvincibleNextUse[id] = fTime + fTimeout + get_cvar_float("bm_invinciblecooldown");
	}
	else
	{
		set_hudmessage(gHudRed, gHudGreen, gHudBlue, gfTextX, gfTextY, gHudEffects, gfHudFxTime, gfHudHoldTime, gfHudFadeInTime, gfHudFadeOutTime, gHudChannel);
		show_hudmessage(id, "Invincibility next use: %.1f", gfInvincibleNextUse[id] - fTime);
	}
}

actionStealth(id, OverrideTimer)
{
	new Float:fTime = halflife_time();
	
	//check if player is outside of cooldown time to use stealth
	if (fTime >= gfStealthNextUse[id] || OverrideTimer)
	{
		new Float:fTimeout = get_cvar_float("bm_stealthtime");
		
		//set a task to remove stealth after time out amount
		set_task(fTimeout, "taskStealthRemove", TASK_STEALTH + id, "", 0, "a", 1);
		
		//make player invisible
		set_user_rendering(id, kRenderFxGlowShell, 0, 0, 0, kRenderTransColor, 0);
		
		//play stealth sound
		emit_sound(id, CHAN_STATIC, gszStealthSound, 1.0, ATTN_NORM, 0, PITCH_NORM);
		
		gfStealthTimeOut[id] = fTime + fTimeout;
		gfStealthNextUse[id] = fTime + fTimeout + get_cvar_float("bm_stealthcooldown");
	}
	else
	{
		set_hudmessage(gHudRed, gHudGreen, gHudBlue, gfTextX, gfTextY, gHudEffects, gfHudFxTime, gfHudHoldTime, gfHudFadeInTime, gfHudFadeOutTime, gHudChannel);
		show_hudmessage(id, "Stealth next use: %.1f", gfStealthNextUse[id] - fTime);
	}
}

actionTrampoline(id)
{
	//if trampoline timeout has exceeded (needed to prevent velocity being given multiple times)
	if (halflife_time() >= gfTrampolineTimeout[id])
	{
		new Float:velocity[3];
		
		//set player Z velocity to make player bounce
		entity_get_vector(id, EV_VEC_velocity, velocity);
		velocity[2] = 500.0;					//jump velocity
		entity_set_vector(id, EV_VEC_velocity, velocity);
		
		entity_set_int(id, EV_INT_gaitsequence, 6);   		//play the Jump Animation
		
		gfTrampolineTimeout[id] = halflife_time() + 0.5;
	}
}

actionSpeedBoost(id)
{
	//if speed boost timeout has exceeded (needed to prevent speed boost being given multiple times)
	if (halflife_time() >= gfSpeedBoostTimeOut[id])
	{
		new Float:pAim[3];
		
		//set velocity on player in direction they're aiming
		velocity_by_aim(id, 800, pAim);
		pAim[2] = 260.0;					//make sure Z velocity is only as high as a jump
		entity_set_vector(id, EV_VEC_velocity, pAim);
		
		entity_set_int(id, EV_INT_gaitsequence, 6);   		//play the Jump Animation
		
		gfSpeedBoostTimeOut[id] = halflife_time() + 0.5;
	}
}

actionNoFallDamage(id)
{
	//set the player to not receive any fall damage (handled in client_PostThink)
	gbNoFallDamage[id] = true;
}

actionOnIce(id)
{
	new taskid = TASK_ICE + id;
	
	if (!gbOnIce[id])
	{
		//save players maxspeed value
		gfOldMaxSpeed[id] = get_user_maxspeed(id);
		
		//make player feel like they're on ice
		entity_set_float(id, EV_FL_friction, 0.15);
		set_user_maxspeed(id, 600.0);
		
		//player is now 'on ice'
		gbOnIce[id] = true;
	}
	
	//remove any existing 'not on ice' task
	if (task_exists(taskid))
	{
		remove_task(taskid);
	}
	
	//set task to remove 'on ice' effect very soon (task replaced if player is still on ice before task time reached)
	set_task(0.1, "taskNotOnIce", taskid);
}

actionDeath(id)
{
	//if player does not have godmode enabled (admin godmode or invincibility)
	if (!get_user_godmode(id))
	{
		//kill player by inflicting massive damage
		fakedamage(id, "the block of death", 10000.0, DMG_GENERIC);
	}
}

actionNuke(id, OverrideTimer)
{
	//get game time
	new Float:fTime = halflife_time();
	
	//make sure player is alive
	if (is_user_alive(id) && (fTime >= gfNukeNextUse[id] || OverrideTimer))
	{
		//get players team
		new CsTeams:playerTeam = cs_get_user_team(id);
		new CsTeams:team;
		
		//iterate through all players
		for (new i = 1; i <= 32; ++i)
		{
			//make sure player is alive
			if (is_user_alive(i))
			{
				team = cs_get_user_team(i);
				
				//if this player is on a different team to the player that used the nuke
				if ((team == CS_TEAM_T && playerTeam == CS_TEAM_CT) || (team == CS_TEAM_CT && playerTeam == CS_TEAM_T))
				{
					//slay player
					fakedamage(i, "a nuke", 10000.0, DMG_BLAST);
				}
			}
			
			//make sure player is connected
			if (is_user_connected(i))
			{
				//make the screen flash for a nuke effect
				message_begin(MSG_ONE, gMsgScreenFade, {0, 0, 0}, i);
				write_short(1024);	//duration
				write_short(1024);	//hold time
				write_short(4096);	//type (in / out)
				write_byte(255);	//red
				write_byte(255);	//green
				write_byte(255);	//blue
				write_byte(255);	//alpha
				message_end();
			}
		}
		
		//play explosion sound
		emit_sound(0, CHAN_STATIC, gszNukeExplosion, 1.0, ATTN_NORM, 0, PITCH_NORM);
		
		//set the time when the player can use the nuke again (someone might have been invincible)
		gfNukeNextUse[id] = fTime + get_cvar_float("bm_nukecooldown");
		
		//get the name of the player that used the nuke
		new szPlayerName[32];
		get_user_name(id, szPlayerName, 32);
		
		//setup hud message to show who nuked what team
		set_hudmessage(255, 255, 0, -1.0, 0.35, 0, 6.0, 10.0, 1.0, 1.0);
		
		//show message saying player nuked the other team
		if (playerTeam == CS_TEAM_T)
		{
			show_hudmessage(0, "%s just nuked the Counter-Terrorists", szPlayerName);
		}
		else
		{
			show_hudmessage(0, "%s just nuked the Terrorists", szPlayerName);
		}
	}
	else
	{
		set_hudmessage(gHudRed, gHudGreen, gHudBlue, gfTextX, gfTextY, gHudEffects, gfHudFxTime, gfHudHoldTime, gfHudFadeInTime, gfHudFadeOutTime, gHudChannel);
		show_hudmessage(id, "Nuke next use: %.1f", gfNukeNextUse[id] - fTime);
	}
}

actionCamouflage(id, OverrideTimer)
{
	new Float:fTime = halflife_time();
	
	//check if player is outside of cooldown time to use camouflage
	if (fTime >= gfCamouflageNextUse[id] || OverrideTimer)
	{
		new Float:fTimeout = get_cvar_float("bm_camouflagetime");
		
		//get players team and model
		new szModel[32];
		new team;
		
		cs_get_user_model(id, szModel, 32);
		
		team = get_user_team(id);
		
		//save current player model
		gszCamouflageOldModel[id] = szModel;
		
		//change player model depending on their current team
		if (team == 1)		//TERRORIST
		{
			cs_set_user_model(id, "urban");
		}
		else
		{
			cs_set_user_model(id, "leet");
		}
		
		//play camouflage sound
		emit_sound(id, CHAN_STATIC, gszCamouflageSound, 1.0, ATTN_NORM, 0, PITCH_NORM);
		
		//set a task to remove camouflage after time out amount
		set_task(fTimeout, "taskCamouflageRemove", TASK_CAMOUFLAGE + id, "", 0, "a", 1);
		
		//set timers to prevent player from using camouflage again so soon
		gfCamouflageTimeOut[id] = fTime + fTimeout;
		gfCamouflageNextUse[id] = fTime + fTimeout + get_cvar_float("bm_camouflagecooldown");
	}
	else
	{
		set_hudmessage(gHudRed, gHudGreen, gHudBlue, gfTextX, gfTextY, gHudEffects, gfHudFxTime, gfHudHoldTime, gfHudFadeInTime, gfHudFadeOutTime, gHudChannel);
		show_hudmessage(id, "Camouflage next use: %.1f", gfCamouflageNextUse[id] - fTime);
	}
}

actionLowGravity(id)
{
	//set player to have low gravity
	set_user_gravity(id, 0.25);
	
	//set global boolean showing player has low gravity
	gbLowGravity[id] = true;
}

actionFire(id, ent)
{
	if (halflife_time() >= gfNextDamageTime[id])
	{
		new hp = get_user_health(id);
		
		//if players health is greater than 0
		if (hp > 0)
		{
			//if player does not have godmode
			if (!get_user_godmode(id))
			{
				new Float:amount = get_cvar_float("bm_firedamageamount") / 10.0;
				new Float:newAmount = hp - amount;
				
				//if this amount of damage won't kill the player
				if (newAmount > 0)
				{
					set_user_health(id, floatround(newAmount, floatround_floor));
				}
				else
				{
					//use fakedamage to kill the player
					fakedamage(id, "fire block", amount, DMG_BURN);
				}
			}
			
			//get halflife time and time for next fire sound from fire block
			new Float:fTime = halflife_time();
			new Float:fNextFireSoundTime = entity_get_float(ent, EV_FL_ltime); 
			
			//if the current time is greater than or equal to the next time to play the fire sound
			if (fTime >= fNextFireSoundTime)
			{
				//play the fire sound
				emit_sound(ent, CHAN_ITEM, gszFireSoundFlame, 0.6, ATTN_NORM, 0, PITCH_NORM);
				
				//set the fire blocks time
				entity_set_float(ent, EV_FL_ltime, fTime + 0.75);
			}
			
			//get effects vectors using block origin
			new Float:origin1[3];
			new Float:origin2[3];
			entity_get_vector(ent, EV_VEC_origin, origin1);
			entity_get_vector(ent, EV_VEC_origin, origin2);
			origin1[0] -= 32.0;
			origin1[1] -= 32.0;
			origin1[2] += 10.0;
			origin2[0] += 32.0;
			origin2[1] += 32.0;
			origin2[2] += 10.0;
			
			//get a random height for the flame
			new randHeight = random_num(0, 32) + 16;
			
			//show some effects
			message_begin(MSG_BROADCAST, SVC_TEMPENTITY);
			write_byte(TE_BUBBLES);
			write_coord(floatround(origin1[0], floatround_floor));	//min start position
			write_coord(floatround(origin1[1], floatround_floor));
			write_coord(floatround(origin1[2], floatround_floor));
			write_coord(floatround(origin2[0], floatround_floor));	//max start position
			write_coord(floatround(origin2[1], floatround_floor));
			write_coord(floatround(origin2[2], floatround_floor));
			write_coord(randHeight);				//float height
			write_short(gSpriteIdFire);				//model index
			write_byte(10);						//count
			write_coord(1);						//speed
			message_end();
		}
		
		gfNextDamageTime[id] = halflife_time() + 0.05;
	}
}

actionSlap(id)
{
	user_slap(id, 0);
	user_slap(id, 0);
	set_hudmessage(255, 255, 255, -1.0, 0.20, 0, 6.0, 12.0, 0.0, 1.0, 3);
	
	show_hudmessage(id, "GET OFF MY FACE!!!");
}

actionRandom(id, ent)
{
	new Float:fTime = halflife_time();
	
	//check if player is outside of cooldown time to use camouflage
	if (fTime >= gfRandomNextUse[id])
	{
		//get which type of block this is set to be
		new blockType = entity_get_int(ent, EV_INT_iuser4);
		
		//do the random block action
		switch (blockType)
		{
			case BM_INVINCIBILITY: actionInvincible(id, true);
			case BM_STEALTH: actionStealth(id, true);
			case BM_DEATH: actionDeath(id);
			case BM_CAMOUFLAGE: actionCamouflage(id, true);
			case BM_SLAP: actionSlap(id); 
			case BM_BOOTSOFSPEED: actionBootsOfSpeed(id, true);
			case BM_AUTO_BHOP: actionAutoBhop(id, true);
		}
		
		//set timer to prevent player from using the random block again so soon
		gfRandomNextUse[id] = fTime + get_cvar_float("bm_randomcooldown");
		
		//set this random block to another random block!
		new randNum = random_num(0, gRandomBlocksMax - 1);
		entity_set_int(ent, EV_INT_iuser4, gRandomBlocks[randNum]);
	}
	else
	{
		set_hudmessage(gHudRed, gHudGreen, gHudBlue, gfTextX, gfTextY, gHudEffects, gfHudFxTime, gfHudHoldTime, gfHudFadeInTime, gfHudFadeOutTime, gHudChannel);
		show_hudmessage(id, "Random block next use: %.1f", gfRandomNextUse[id] - fTime);
	}
}

actionHoney(id)
{
	new taskid = TASK_HONEY + id;
	
	//make player feel like they're stuck in honey by lowering their maxspeed
	set_user_maxspeed(id, 50.0);
	
	//remove any existing 'in honey' task
	if (task_exists(taskid))
	{
		remove_task(taskid);
	}
	else
	{
		//half the players velocity the first time they touch it
		new Float:vVelocity[3];
		entity_get_vector(id, EV_VEC_velocity, vVelocity);
		vVelocity[0] = vVelocity[0] / 2.0;
		vVelocity[1] = vVelocity[1] / 2.0;
		entity_set_vector(id, EV_VEC_velocity, vVelocity);
	}
	
	//set task to remove 'in honey' effect very soon (task replaced if player is still in honey before task time reached)
	set_task(0.1, "taskNotInHoney", taskid);
}

actionBootsOfSpeed(id, bool:OverrideTimer)
{
	new Float:fTime = halflife_time();
	
	//check if player is outside of cooldown time to use the boots of speed
	if (fTime >= gfBootsOfSpeedNextUse[id] || OverrideTimer)
	{
		new Float:fTimeout = get_cvar_float("bm_bootsofspeedtime");
		
		//set a task to remove the boots of speed after time out amount
		set_task(fTimeout, "taskBootsOfSpeedRemove", TASK_BOOTSOFSPEED + id, "", 0, "a", 1);
		
		//set the players maxspeed to 400 so they run faster!
		set_user_maxspeed(id, gfBootsMaxSpeed);
		
		//play boots of speed sound
		emit_sound(id, CHAN_STATIC, gszBootsOfSpeedSound, 1.0, ATTN_NORM, 0, PITCH_NORM);
		
		gfBootsOfSpeedTimeOut[id] = fTime + fTimeout;
		gfBootsOfSpeedNextUse[id] = fTime + fTimeout + get_cvar_float("bm_bootsofspeedcooldown");
	}
	else
	{
		set_hudmessage(gHudRed, gHudGreen, gHudBlue, gfTextX, gfTextY, gHudEffects, gfHudFxTime, gfHudHoldTime, gfHudFadeInTime, gfHudFadeOutTime, gHudChannel);
		show_hudmessage(id, "Boots of speed next use: %.1f", gfBootsOfSpeedNextUse[id] - fTime);
	}
}

actionNoSlowDown(id)
{
	new taskid = TASK_NOSLOW + id;
	
	gbNoSlowDown[id] = true;
	
	//remove any existing 'slow down' task
	if (task_exists(taskid))
	{
		remove_task(taskid);
	}
	
	//set task to remove 'no slow down' effect very soon
	set_task(0.1, "taskSlowDown", taskid);
}

actionAutoBhop(id, bool:OverrideTimer)
{
	new Float:fTime = halflife_time();
	
	//check if player is outside of cooldown time to use the auto bhop
	if (fTime >= gfAutoBhopNextUse[id] || OverrideTimer)
	{
		new Float:fTimeout = get_cvar_float("bm_autobhoptime");
		
		//set a task to remove the auto bhop after time out amount
		set_task(fTimeout, "taskAutoBhopRemove", TASK_AUTOBHOP + id, "", 0, "a", 1);
		
		//set autobhop boolean
		gbAutoBhop[id] = true;
		
		//play boots of speed sound
		emit_sound(id, CHAN_STATIC, gszAutoBhopSound, 1.0, ATTN_NORM, 0, PITCH_NORM);
		
		gfAutoBhopTimeOut[id] = fTime + fTimeout;
		gfAutoBhopNextUse[id] = fTime + fTimeout + get_cvar_float("bm_autobhopcooldown");
	}
	else
	{
		set_hudmessage(gHudRed, gHudGreen, gHudBlue, gfTextX, gfTextY, gHudEffects, gfHudFxTime, gfHudHoldTime, gfHudFadeInTime, gfHudFadeOutTime, gHudChannel);
		show_hudmessage(id, "Auto bunnyhop next use: %.1f", gfAutoBhopNextUse[id] - fTime);
	}
}

actionTeleport(id, ent)
{
	//get end entity id
	new tele = entity_get_int(ent, EV_INT_iuser1);
	
	//if teleport end id is valid
	if (tele)
	{
		//get end entity origin
		new Float:vTele[3];
		entity_get_vector(tele, EV_VEC_origin, vTele);
		
		//if id of entity being teleported is a player and telefrags CVAR is set then kill any nearby players
		if ((id > 0 && id <= 32) && get_cvar_num("bm_telefrags") > 0)
		{
			new player = -1;
			
			do
			{
				player = find_ent_in_sphere(player, vTele, 16.0);
				
				//if entity found is a player
				if (player > 0 && player <= 32)
				{
					//if player is alive, and is not the player that went through the teleport
					if (is_user_alive(player) && player != id)
					{
						//kill the player
						user_kill(player, 1);
					}
				}
			}while(player);
		}
		
		//get origin of the start of the teleport
		new Float:vOrigin[3];
		new origin[3];
		entity_get_vector(ent, EV_VEC_origin, vOrigin);
		FVecIVec(vOrigin, origin);
		
		//show some teleporting effects
		message_begin(MSG_PVS, SVC_TEMPENTITY, origin);
		write_byte(TE_IMPLOSION);
		write_coord(origin[0]);
		write_coord(origin[1]);
		write_coord(origin[2]);
		write_byte(64);		// radius
		write_byte(100);	// count
		write_byte(6);		// life
		message_end();
		
		//teleport player
		entity_set_vector(id, EV_VEC_origin, vTele);
		
		//reverse players Z velocity
		new Float:vVelocity[3];
		entity_get_vector(id, EV_VEC_velocity, vVelocity);
		vVelocity[2] = floatabs(vVelocity[2]);
		entity_set_vector(id, EV_VEC_velocity, vVelocity);
		
		//if teleport sound CVAR is set
		if (get_cvar_num("bm_teleportsound") > 0)
		{
			//play teleport sound
			emit_sound(id, CHAN_STATIC, gszTeleportSound, 1.0, ATTN_NORM, 0, PITCH_NORM);
		}
	}
}

actionTimer(id)
{
	new Float:origin[3];
	new Float:radius = 100.0;
	new ent = -1;
	new bool:bNearStart = false;
	new bool:bNearEnd = false;
	
	//get players origin
	entity_get_vector(id, EV_VEC_origin, origin);
	
	//find entities in a sphere around the player
	while ((ent = find_ent_in_sphere(ent, origin, radius)))
	{
		//if entity is a timer
		if (isTimer(ent))
		{
			//get what type of timer it is (start/end)
			new timerType = entity_get_int(ent, EV_INT_body);
			
			switch (timerType)
			{
				case TIMER_START: bNearStart = true;
				case TIMER_END: bNearEnd = true;
			}
		}
	}
	
	if (bNearStart && bNearEnd)
	{
		//start or stop timer depending on whether or not the player has a timer
		if (gbHasTimer[id])
		{
			timerStop(id);
		}
		else
		{
			timerStart(id);
		}
	}
	else if (bNearStart)
	{
		timerStart(id);
	}
	else if (bNearEnd)
	{
		timerStop(id);
	}
}

public timerStart(id)
{
	//if player is alive
	if (is_user_alive(id))
	{
		//store the game time to calculate players time later
		gfTimerTime[id] = halflife_time();
		
		//if player already had a timer
		if (gbHasTimer[id])
		{
			client_print(id, print_chat, "%sTimer Re-started.", gszPrefix);
		}
		else
		{
			gbHasTimer[id] = true;
			
			client_print(id, print_chat, "%sTimer Started.", gszPrefix);
		}
	}
}

public timerStop(id)
{
	if (gbHasTimer[id])
	{
		gbHasTimer[id] = false;
		
		//get players name
		new szName[33];
		get_user_name(id, szName, 32);
		
		//calculate players time in minutes and seconds
		new Float:fTime = halflife_time() - gfTimerTime[id];
		new Float:fMins = fTime / 60.0;
		new mins = floatround(fMins, floatround_floor);
		new Float:fSecs = (fMins - mins) * 60.0;
		
		//format the players time into a string
		new szTime[17];
		format(szTime, 16, "%s%d:%s%.3f", (mins < 10 ? "0" : ""), mins, (fSecs < 10.0 ? "0" : ""), fSecs);
		
		//announce the players time
		client_print(0, print_chat, "%s'%s' just completed the course in %s", gszPrefix, szName, szTime);
		
		//player no longer has a timer
		gbHasTimer[id] = false;
		
		//add players time to scoreboard
		timerCheckScoreboard(id, fTime);
	}
}

public timerCheckScoreboard(id, Float:fTime)
{
	new szName[32], szSteamId[32];
	
	//get players name, steam ID and time
	get_user_name(id, szName, 32);
	get_user_authid(id, szSteamId, 32);
	fTime = halflife_time() - gfTimerTime[id];
	
	for (new i = 0; i < 15; i++)
	{
		//if the player was faster than a time on the scoreboard
		if (fTime < gfScoreTimes[i])
		{
			new pos = i;
			
			//get position where the player is already on the scoreboard (if any)
			while (!equali(gszScoreSteamIds[pos], szSteamId) && pos < 14)
			{
				pos++;
			}
			
			//shift scores down
			for (new j = pos; j > i; j--)
			{
				format(gszScoreSteamIds[j], 32, gszScoreSteamIds[j - 1]);
				format(gszScoreNames[j], 32, gszScoreNames[j - 1]);
				gfScoreTimes[j] = gfScoreTimes[j - 1];
			}
			
			//put player onto the scoreboard
			format(gszScoreSteamIds[i], 32, szSteamId);
			format(gszScoreNames[i], 32, szName);
			gfScoreTimes[i] = fTime;
			
			//if player got first place on the scoreboard
			if ((i + 1) == 1)
			{
				client_print(0, print_chat, "%s'%s' is now the fastest player on the course!", gszPrefix, szName);
			}
			else
			{
				client_print(0, print_chat, "%s'%s' is now rank %d on the scoreboard", gszPrefix, szName, (i + 1));
			}
			
			break;
		}
		
		//compare steam ID of player with steam ID on scoreboard
		if (equali(gszScoreSteamIds[i], szSteamId))
		{
			//break out of loop because player did not beat their old time
			break;
		}
	}
}

public timerShowScoreboard(id)
{
	new szLine[128];
	new szMapName[32];
	new szConfigsDir[32];
	new szHostName[32];
	new i = 0, len = 0;
	new szTop15File[96];
	new szCSS[512];
	new szTime[16];
	new szName[33];
	new szBuffer[2048];
	new bufSize = sizeof(szBuffer) - 1;
	
	get_mapname(szMapName, 31);
	get_configsdir(szConfigsDir, 31);
	get_cvar_string("hostname", szHostName, 31);
	
	format(szTop15File, 96, "%s/blockmaker_scoreboard.css", szConfigsDir);
	
	//get contents of CSS file
	getFileContents(szTop15File, szCSS);
	
	len += format(szBuffer[len], bufSize-len, "<style>%s</style>", szCSS);
	len += format(szBuffer[len], bufSize-len, "<h1>%s</h1>", szMapName);
	
	// ************* START OF TABLE **************
	len += format(szBuffer[len], bufSize-len, "<table><tr><th>#<th>Player<th>Time");
	
	//iterate through the scoreboard
	for (i = 0; i < 15; i++)
	{
		//if top15 entry is blank
		if (gfScoreTimes[i] == 999999.9)
		{
			//create table row
			format(szLine, 127, "<tr><td>%d<td id=b><td id=c>", (i+1));
		}
		else
		{
			//make name HTML friendly
			htmlFriendly(szName);
			
			//calculate players time in minutes and seconds
			new Float:fMins = (gfScoreTimes[i] / 60.0);
			new mins = floatround(fMins, floatround_floor);
			new Float:fSecs = (fMins - mins) * 60.0;
			
			//format the players time into a string
			format(szTime, 16, "%s%d:%s%.3f", (mins < 10 ? "0" : ""), mins, (fSecs < 10.0 ? "0" : ""), fSecs);
			
			//create table row
			format(szLine, 127, "<tr><td id=a>%d<td id=b>%s<td id=c>%s", (i+1), gszScoreNames[i], szTime);
		}
		
		//append table row to szBuffer
		len += format(szBuffer[len], bufSize-len, szLine);
	}
	// ************** END OF TABLE ******************
	
	new szTitle[64];
	format(szTitle, 63, "Top 15 Climbers - %s", szHostName);
	show_motd(id, szBuffer, szTitle);
	
	return PLUGIN_HANDLED;
}

/***** TASKS *****/
public taskSolidNot(ent)
{
	ent -= TASK_BHOPSOLIDNOT;
	
	//make sure entity is valid
	if (is_valid_ent(ent))
	{
		//if block isn't being grabbed
		if (entity_get_int(ent, EV_INT_iuser2) == 0)
		{
			entity_set_int(ent, EV_INT_solid, SOLID_NOT);
			set_rendering(ent, kRenderFxNone, 255, 255, 255, kRenderTransAdd, 25);
			set_task(1.0, "taskSolid", TASK_BHOPSOLID + ent);
		}
	}
}

public taskSolid(ent)
{
	ent -= TASK_BHOPSOLID;
	
	//make sure entity is valid
	if (isBlock(ent))
	{
		//make block solid
		entity_set_int(ent, EV_INT_solid, SOLID_BBOX);
		
		//get the player ID of who has the block in a group (if anyone)
		new player = entity_get_int(ent, EV_INT_iuser1);
		
		//if the block is in a group
		if (player > 0)
		{
			//set the block so it is now 'being grouped' (for setting the rendering)
			groupBlock(0, ent);
		}
		else
		{
			new blockType = entity_get_int(ent, EV_INT_body);
			
			set_block_rendering(ent, gRender[blockType], gRed[blockType], gGreen[blockType], gBlue[blockType], gAlpha[blockType]);
		}
	}
}

public taskInvincibleRemove(id)
{
	id -= TASK_INVINCIBLE;
	
	//make sure player is alive
	if (is_user_alive(id))
	{
		set_user_godmode(id, 0);
		
		//only set players rendering back to normal if player is not stealth
		if (halflife_time() >= gfStealthTimeOut[id])
		{
			set_user_rendering(id, kRenderFxGlowShell, 0, 0, 0, kRenderNormal, 16);
		}
	}
}

public taskStealthRemove(id)
{
	id -= TASK_STEALTH;
	
	//make sure player is connected
	if (is_user_connected(id))
	{
		//only set players rendering back to normal if player is not invincible
		if (halflife_time() >= gfInvincibleTimeOut[id])
		{	
			set_user_rendering(id, kRenderFxGlowShell, 0, 0, 0, kRenderNormal, 255);
		}
		else	//if player is invincible then set player to glow white
		{
			set_user_rendering(id, kRenderFxGlowShell, 255, 255, 255, kRenderTransColor, 16);
		}
	}
}

public taskNotOnIce(id)
{
	id -= TASK_ICE;
	
	//make player run normally
	entity_set_float(id, EV_FL_friction, 1.0);
	
	if (gfOldMaxSpeed[id] > 100.0)
	{
		set_user_maxspeed(id, gfOldMaxSpeed[id]);
	}
	else
	{
		set_user_maxspeed(id, 250.0);
	}
	
	//no longer 'on ice'
	gbOnIce[id] = false;
	gfOldMaxSpeed[id] = 0.0;
}

public taskCamouflageRemove(id)
{
	id -= TASK_CAMOUFLAGE;
	
	//if player is still connected
	if (is_user_connected(id))
	{
		//change back to players old model
		cs_set_user_model(id, gszCamouflageOldModel[id]);
	}
}

public taskNotInHoney(id)
{
	id -= TASK_HONEY;
	
	//if player is alive
	if (is_user_alive(id))
	{
		//make player move normally
		set_user_maxspeed(id, 250.0);
		
		//this will set the players maxspeed faster if they have the boots of speed!
		eventCurWeapon(id);
	}
}

public taskBootsOfSpeedRemove(id)
{
	id -= TASK_BOOTSOFSPEED;
	
	//set players speed back to normal
	if (is_user_alive(id))
	{
		set_user_maxspeed(id, 250.0);
	}
}

public taskSlowDown(id)
{
	id -= TASK_NOSLOW;
	
	//player no longer has 'no slow down'
	gbNoSlowDown[id] = false;
}

public taskAutoBhopRemove(id)
{
	id -= TASK_AUTOBHOP;
	
	//player no long has 'auto bhop'
	gbAutoBhop[id] = false;
}

public taskSpriteNextFrame(params[])
{
	new ent = params[0];
	
	//make sure entity is valid
	if (is_valid_ent(ent))
	{
		new frames = params[1];
		new Float:current_frame = entity_get_float(ent, EV_FL_frame);
		
		if (current_frame < 0.0 || current_frame >= frames)
		{
			entity_set_float(ent, EV_FL_frame, 1.0);
		}
		else
		{
			entity_set_float(ent, EV_FL_frame, current_frame + 1.0);
		}
	}
	else
	{
		remove_task(TASK_SPRITE + ent);
	}
}

/***** COMMANDS *****/
public cmdJump(id)
{
	//if the object the player is grabbing isn't too close
	if (gfGrablength[id] > 72.0)
	{
		//move the object closer
		gfGrablength[id] -= 16.0;
	}
}

public cmdDuck(id)
{
	//move the object further away
	gfGrablength[id] += 16.0;
}

public cmdAttack(id)
{
	//if entity being grabbed is a block
	if (isBlock(gGrabbed[id]))
	{
		//if block the player is grabbing is in their group and group count is larger than 1
		if (isBlockInGroup(id, gGrabbed[id]) && gGroupCount[id] > 1)
		{
			new block;
			
			//move the rest of the blocks in the players group using vector for grabbed block
			for (new i = 0; i <= gGroupCount[id]; ++i)
			{
				block = gGroupedBlocks[id][i];
				
				//if this block is in this players group
				if (isBlockInGroup(id, block))
				{
					//only copy the block if it is not stuck
					if (!isBlockStuck(block))
					{
						//copy the block
						copyBlock(block);
					}
				}
			}
		}
		else
		{
			//only copy the block the player has grabbed if it is not stuck
			if (!isBlockStuck(gGrabbed[id]))
			{
				//copy the block
				new newBlock = copyBlock(gGrabbed[id]);
				
				//if new block was created successfully
				if (newBlock)
				{
					//set currently grabbed block to 'not being grabbed'
					entity_set_int(gGrabbed[id], EV_INT_iuser2, 0);
					
					//set new block to 'being grabbed'
					entity_set_int(newBlock, EV_INT_iuser2, id);
					
					//set player to grabbing new block
					gGrabbed[id] = newBlock;
				}
			}
			else
			{
				//tell the player they can't copy a block when it is in a stuck position
				client_print(id, print_chat, "%sYou cannot copy a block that is in a stuck position!", gszPrefix);
			}
		}
	}
}

public cmdAttack2(id)
{
	//if player is grabbing a block
	if (isBlock(gGrabbed[id]))
	{
		//if block the player is grabbing is in their group and group count is larger than 1
		if (isBlockInGroup(id, gGrabbed[id]) && gGroupCount[id] > 1)
		{
			new block;
			
			//iterate through all blocks in the players group
			for (new i = 0; i <= gGroupCount[id]; ++i)
			{
				block = gGroupedBlocks[id][i];
				
				//if block is still valid
				if (is_valid_ent(block))
				{
					//if block is still in this players group
					if (isBlockInGroup(id, block))
					{
						//delete the block
						gbJustDeleted[id] = deleteBlock(block);
					}
				}
			}
		}
		else
		{
			//delete the block
			gbJustDeleted[id] = deleteBlock(gGrabbed[id]);
		}
	}
	//if player is grabbing a teleport
	else if (isTeleport(gGrabbed[id]))
	{
		//delete the teleport
		gbJustDeleted[id] = deleteTeleport(id, gGrabbed[id]);
	}
	//if player is grabbing a timer
	else if (isTimer(gGrabbed[id]))
	{
		//delete the timer
		gbJustDeleted[id] = deleteTimer(gGrabbed[id]);
	}
}

public cmdGrab(id)
{
	//make sure player has access to use this command
	if (get_user_flags(id) & BM_ADMIN_LEVEL)
	{
		//get the entity the player is aiming at and the length
		new ent, body;
		gfGrablength[id] = get_user_aiming(id, ent, body);
		
		//set booleans depending on entity type
		new bool:bIsBlock = isBlock(ent);
		new bool:bIsTeleport = isTeleport(ent);
		new bool:bIsTimer = isTimer(ent);
		
		//if the entity is a block or teleport
		if (bIsBlock || bIsTeleport || bIsTimer)
		{
			//get who is currently grabbing the entity (if anyone)
			new grabber = entity_get_int(ent, EV_INT_iuser2);
			
			//if entity is not being grabbed by someone else
			if (grabber == 0 || grabber == id)
			{
				//if entity is a block
				if (bIsBlock)
				{
					//get the player ID of who has the block in a group (if anyone)
					new player = entity_get_int(ent, EV_INT_iuser1);
					
					//if the block is not in a group or is in this players group
					if (player == 0 || player == id)
					{
						//set the block to 'being grabbed'
						setGrabbed(id, ent);
						
						//if this block is in this players group and group count is greater than 1
						if (player == id && gGroupCount[id] > 1)
						{
							new Float:vGrabbedOrigin[3];
							new Float:vOrigin[3];
							new Float:vOffset[3];
							new block;
							
							//get origin of the block
							entity_get_vector(ent, EV_VEC_origin, vGrabbedOrigin);
							
							//iterate through all blocks in players group
							for (new i = 0; i <= gGroupCount[id]; ++i)
							{
								block = gGroupedBlocks[id][i];
								
								//if block is still valid
								if (is_valid_ent(block))
								{
									player = entity_get_int(ent, EV_INT_iuser1);
									
									//if block is still in this players group
									if (player == id)
									{
										//get origin of block in players group
										entity_get_vector(block, EV_VEC_origin, vOrigin);
										
										//calculate offset from grabbed block
										vOffset[0] = vGrabbedOrigin[0] - vOrigin[0];
										vOffset[1] = vGrabbedOrigin[1] - vOrigin[1];
										vOffset[2] = vGrabbedOrigin[2] - vOrigin[2];
										
										//save offset value in grouped block
										entity_set_vector(block, EV_VEC_vuser1, vOffset);
										
										//indicate that entity is being grabbed
										entity_set_int(block, EV_INT_iuser2, id);
									}
								}
							}
						}
					}
				}
				//if entity is a teleporter
				else if (bIsTeleport)
				{
					//set the teleport to 'being grabbed'
					setGrabbed(id, ent);
				}
				//if entity is a timer
				else if (bIsTimer)
				{
					//set the timer to 'being grabbed'
					setGrabbed(id, ent);
				}
			}
		}
	}
	
	return PLUGIN_HANDLED;
}

setGrabbed(id, ent)
{
	new Float:fpOrigin[3];
	new Float:fbOrigin[3];
	new Float:fAiming[3];
	new iAiming[3];
	new bOrigin[3];
	
	//get players current view model then clear it
	entity_get_string(id, EV_SZ_viewmodel, gszViewModel[id], 32);
	entity_set_string(id, EV_SZ_viewmodel, "");
	
	get_user_origin(id, bOrigin, 1);			//position from eyes (weapon aiming)
	get_user_origin(id, iAiming, 3);			//end position from eyes (hit point for weapon)
	entity_get_vector(id, EV_VEC_origin, fpOrigin);		//get player position
	entity_get_vector(ent, EV_VEC_origin, fbOrigin);	//get block position
	IVecFVec(iAiming, fAiming);
	FVecIVec(fbOrigin, bOrigin);
	
	//set gGrabbed
	gGrabbed[id] = ent;
	gvGrabOffset[id][0] = fbOrigin[0] - iAiming[0];
	gvGrabOffset[id][1] = fbOrigin[1] - iAiming[1];
	gvGrabOffset[id][2] = fbOrigin[2] - iAiming[2];
	
	//indicate that entity is being grabbed
	entity_set_int(ent, EV_INT_iuser2, id);
}

public cmdRelease(id)
{
	//make sure player has access to use this command
	if (get_user_flags(id) & BM_ADMIN_LEVEL)
	{
		//if player is grabbing an entity
		if (gGrabbed[id])
		{
			//if entity player is grabbing is a block
			if (isBlock(gGrabbed[id]))
			{
				//if block the player is grabbing is in their group and group count is > 1
				if (isBlockInGroup(id, gGrabbed[id]) && gGroupCount[id] > 1)
				{
					new block;
					new bool:bGroupIsStuck = true;
					
					//iterate through all blocks in the players group
					for (new i = 0; i <= gGroupCount[id]; ++i)
					{
						block = gGroupedBlocks[id][i];
						
						//if this block is in this players group
						if (isBlockInGroup(id, block))
						{
							//indicate that entity is no longer being grabbed
							entity_set_int(block, EV_INT_iuser2, 0);
							
							//start off thinking all blocks in group are stuck
							if (bGroupIsStuck)
							{
								//if block is not stuck
								if (!isBlockStuck(block))
								{
									//at least one of the blocks in the group are not stuck
									bGroupIsStuck = false;
								}
							}
						}
					}
					
					//if all the blocks in the group are stuck
					if (bGroupIsStuck)
					{
						//iterate through all blocks in the players group
						for (new i = 0; i <= gGroupCount[id]; ++i)
						{
							block = gGroupedBlocks[id][i];
							
							//if this block is in this players group
							if (isBlockInGroup(id, block))
							{
								//delete the block
								deleteBlock(block);
							}
						}
						
						//tell the player all the blocks were deleted because they were stuck
						client_print(id, print_chat, "%sGroup deleted because all the blocks were stuck!", gszPrefix);
					}
				}
				else
				{
					//if block player has grabbed is valid
					if (is_valid_ent(gGrabbed[id]))
					{
						//if the block is stuck
						if (isBlockStuck(gGrabbed[id]))
						{
							//delete the block
							new bool:bDeleted = deleteBlock(gGrabbed[id]);
							
							//if the block was deleted successfully
							if (bDeleted)
							{
								//tell the player the block was deleted and why
								client_print(id, print_chat, "%sBlock deleted because it was stuck!", gszPrefix);
							}
						}
						else
						{
							//indicate that the block is no longer being grabbed
							entity_set_int(gGrabbed[id], EV_INT_iuser2, 0);
						}
					}
				}
			}
			else if (isTeleport(gGrabbed[id]))
			{
				//indicate that the teleport is no longer being grabbed
				entity_set_int(gGrabbed[id], EV_INT_iuser2, 0);
			}
			else if (isTimer(gGrabbed[id]))
			{
				//indicate that the timer is no longer being grabbed
				entity_set_int(gGrabbed[id], EV_INT_iuser2, 0);
			}
			
			//set the players view model back to what it was
			entity_set_string(id, EV_SZ_viewmodel, gszViewModel[id]);
			
			//indicate that player is not grabbing an object
			gGrabbed[id] = 0;
		}
	}
	
	return PLUGIN_HANDLED;
}

/* MENUS */
public showMainMenu(id)
{
	new col[3];
	new szMenu[256];
	new szGodmode[6];
	new szNoclip[6];
	col = (get_user_flags(id) & BM_ADMIN_LEVEL ? "\w" : "\d");
	szNoclip = (get_user_noclip(id) ? "\yOn" : "\rOff");
	szGodmode = (get_user_godmode(id) ? "\yOn" : "\rOff");
	
	//format the main menu
	format(szMenu, 256, gszMainMenu, col, szNoclip, col, szGodmode);
	
	//show the main menu to the player
	show_menu(id, gKeysMainMenu, szMenu, -1, "bmMainMenu");
	
	return PLUGIN_HANDLED;
}

showBlockMenu(id)
{
	new col[3];
	new szMenu[256];
	new szGodmode[6];
	new szNoclip[6];
	new szSize[8];
	col = (get_user_flags(id) & BM_ADMIN_LEVEL ? "\w" : "\d");
	szNoclip = (get_user_noclip(id) ? "\yOn" : "\rOff");
	szGodmode = (get_user_godmode(id) ? "\yOn" : "\rOff");
	
	switch (gBlockSize[id])
	{
		case SMALL: szSize = "Small";
		case NORMAL: szSize = "Normal";
		case LARGE: szSize = "Large";
	}
	
	//format the main menu
	format(szMenu, 256, gszBlockMenu, gszBlockNames[gSelectedBlockType[id]], col, col, col, col, col, szNoclip, col, szGodmode, szSize);
	
	//show the block menu to the player
	show_menu(id, gKeysBlockMenu, szMenu, -1, "bmBlockMenu");
	
	return PLUGIN_HANDLED;
}

showBlockSelectionMenu(id)
{
	//create block selection menu 1 (first 8 blocks)
	new szBlockMenu[256];
	new szTitle[32];
	new szEntry[32];
	new num;
	new startBlock;
	
	//format the page number into the menu title
	format(szTitle, sizeof(szTitle), "\yBlock Selection %d^n^n", gBlockMenuPage[id]);
	
	//add the title to the menu
	add(szBlockMenu, sizeof(szBlockMenu), szTitle);
	
	//calculate the block that the menu will start on
	startBlock = (gBlockMenuPage[id] - 1) * 8;
	
	//iterate through 8 blocks to add to the menu
	for (new i = startBlock; i < startBlock + 8; ++i)
	{
		//make sure the loop doesn't go above the maximum number of blocks
		if (i < gBlockMax)
		{
			//calculate the menu item number
			num = (i - startBlock) + 1;
			
			//format the block name into the menu entry
			format(szEntry, sizeof(szEntry), "\r%d. \w%s^n", num, gszBlockNames[i]);
		}
		else
		{
			//format a blank menu entry
			format(szEntry, sizeof(szEntry), "^n");
		}
		
		//add the entry to the menu
		add(szBlockMenu, sizeof(szBlockMenu), szEntry);
	}
	
	//if the block selection page the player is on is less than the maximum page
	if (gBlockMenuPage[id] < gBlockMenuPagesMax)
	{
		add(szBlockMenu, sizeof(szBlockMenu), "^n\r9. \wMore");
	}
	else
	{
		add(szBlockMenu, sizeof(szBlockMenu), "^n");
	}
	
	//add a back option to the menu
	add(szBlockMenu, sizeof(szBlockMenu), "^n\r0. \wBack");
	
	//display the block selection menu
	show_menu(id, gKeysBlockSelectionMenu, szBlockMenu, -1, "bmBlockSelectionMenu");
}

showTeleportMenu(id)
{
	new col[3];
	new szMenu[256];
	new szGodmode[6];
	new szNoclip[6];
	col = (get_user_flags(id) & BM_ADMIN_LEVEL ? "\w" : "\d");
	szNoclip = (get_user_noclip(id) ? "\yOn" : "\rOff");
	szGodmode = (get_user_godmode(id) ? "\yOn" : "\rOff");
	
	//format teleport menu
	format(szMenu, sizeof(szMenu), gszTeleportMenu, col, (gTeleportStart[id] ? "\w" : "\d"), col, col, col, col, szNoclip, col, szGodmode);
	
	show_menu(id, gKeysTeleportMenu, szMenu, -1, "bmTeleportMenu");
}

showTimerMenu(id)
{
	new col[3];
	new szMenu[256];
	new szGodmode[6];
	new szNoclip[6];
	col = (get_user_flags(id) & BM_ADMIN_LEVEL ? "\w" : "\d");
	szNoclip = (get_user_noclip(id) ? "\yOn" : "\rOff");
	szGodmode = (get_user_godmode(id) ? "\yOn" : "\rOff");
	
	//format timer menu
	format(szMenu, sizeof(szMenu), gszTimerMenu, col, (gStartTimer[id] ? "\w" : "\d"), col, col, col, col, szNoclip, col, szGodmode);
	
	show_menu(id, gKeysTimerMenu, szMenu, -1, "bmTimerMenu");
}

showMeasureMenu(id)
{
	new col[3];
	new szMenu[512];
	new szGodmode[6];
	new szNoclip[6];
	new szBlock1[40];
	new szBlock2[40];
	new szMeasureTool[16];
	
	col = (get_user_flags(id) & BM_ADMIN_LEVEL ? "\w" : "\d");
	
	//if players measuring block 1 is valid
	if (is_valid_ent(gMeasureToolBlock1[id]))
	{
		//add entity id to the start of the string followed by a hyphon seperator
		num_to_str(gMeasureToolBlock1[id], szBlock1, 40);
		add(szBlock1, 40, " - ");
		
		//if entity is a block
		if (isBlock(gMeasureToolBlock1[id]))
		{
			new blockType = entity_get_int(gMeasureToolBlock1[id], EV_INT_body);
			add(szBlock1, 40, gszBlockNames[blockType]);
		}
		else if (isTimer(gMeasureToolBlock1[id]))
		{
			//get what type of timer it is (start/end)
			new timerType = entity_get_int(gMeasureToolBlock1[id], EV_INT_body);
			
			switch (timerType)
			{
				case TIMER_START: add(szBlock1, 40, "Timer Start");
				case TIMER_END: add(szBlock1, 40, "Timer End");
			}
		}
	}
	else
	{
		szBlock1 = "\rNone";
	}
	
	//if players measuring block 2 is valid
	if (is_valid_ent(gMeasureToolBlock2[id]))
	{
		//add entity id to the start of the string followed by a hyphon seperator
		num_to_str(gMeasureToolBlock2[id], szBlock2, 40);
		add(szBlock2, 40, " - ");
		
		//if entity is a block
		if (isBlock(gMeasureToolBlock2[id]))
		{
			new blockType = entity_get_int(gMeasureToolBlock2[id], EV_INT_body);
			add(szBlock2, 40, gszBlockNames[blockType]);
		}
		else if (isTimer(gMeasureToolBlock2[id]))
		{
			//get what type of timer it is (start/end)
			new timerType = entity_get_int(gMeasureToolBlock2[id], EV_INT_body);
			
			switch (timerType)
			{
				case TIMER_START: add(szBlock2, 40, "Timer Start");
				case TIMER_END: add(szBlock2, 40, "Timer Stop");
			}
		}
	}
	else
	{
		szBlock2 = "\rNone";
	}
	
	szMeasureTool = (gbMeasureToolEnabled[id] ? "\yOn" : "\rOff");
	szNoclip = (get_user_noclip(id) ? "\yOn" : "\rOff");
	szGodmode = (get_user_godmode(id) ? "\yOn" : "\rOff");
	
	//format measure menu
	format(szMenu, sizeof(szMenu), gszMeasureMenu, szBlock1, szBlock2, gvMeasureToolPos1[id][0], gvMeasureToolPos1[id][1], gvMeasureToolPos1[id][2], gvMeasureToolPos2[id][0], gvMeasureToolPos2[id][1], gvMeasureToolPos2[id][2], col, szMeasureTool, col, szNoclip, col, szGodmode);
	
	//show the measure menu to the player
	show_menu(id, gKeysMeasureMenu, szMenu, -1, "bmMeasureMenu");
}

showLongJumpMenu(id)
{
	new col[3];
	new szMenu[256];
	new szGodmode[6];
	new szNoclip[6];
	new szSize[8];
	
	col = (get_user_flags(id) & BM_ADMIN_LEVEL ? "\w" : "\d");
	szNoclip = (get_user_noclip(id) ? "\yOn" : "\rOff");
	szGodmode = (get_user_godmode(id) ? "\yOn" : "\rOff");
	
	switch (gBlockSize[id])
	{
		case SMALL: szSize = "Small";
		case NORMAL: szSize = "Normal";
		case LARGE: szSize = "Large";
	}
	
	//format the long jump menu
	format(szMenu, sizeof(szMenu), gszLongJumpMenu, col, gLongJumpDistance[id], col, (gLongJumpAxis[id] == X ? "X" : "Y"), col, col, col, szNoclip, col, szGodmode, szSize);
	
	//show the long jump menu to the player
	show_menu(id, gKeysLongJumpMenu, szMenu, -1, "bmLongJumpMenu");
}

showOptionsMenu(id, oldMenu)
{
	//set the oldmenu global variable so when the back key is pressed it goes back to the previous menu
	gMenuBeforeOptions[id] = oldMenu;
	
	new col[3];
	new szSnapping[6];
	new szMenu[256];
	col = (get_user_flags(id) & BM_ADMIN_LEVEL ? "\w" : "\d");
	szSnapping = (gbSnapping[id] ? "\yOn" : "\rOff");
	
	//format the options menu
	format(szMenu, sizeof(szMenu), gszOptionsMenu, col, szSnapping, col, gfSnappingGap[id], col, col, col, col, col, col);
	
	//show the options menu to the player
	show_menu(id, gKeysOptionsMenu, szMenu, -1, "bmOptionsMenu");
}

showChoiceMenu(id, gChoice, const szTitle[96])
{
	gChoiceOption[id] = gChoice;
	
	//format choice menu using given title
	new szMenu[128];
	format(szMenu, sizeof(szMenu), gszChoiceMenu, szTitle);
	
	//show the choice menu to the player
	show_menu(id, gKeysChoiceMenu, szMenu, -1, "bmChoiceMenu");
}

public handleMainMenu(id, num)
{
	switch (num)
	{
		case N1: { showBlockMenu(id); }
		case N2: { showTeleportMenu(id); }
		case N3: { showTimerMenu(id); }
		case N4: { showMeasureMenu(id); }
		case N5: { showLongJumpMenu(id); }
		case N6: { toggleNoclip(id); }
		case N7: { toggleGodmode(id); }
		case N9: { showOptionsMenu(id, 1); }
		case N0: { return; }
	}
	
	//selections 1, 2, 3, 4, 5 and 9 show different menus
	if (num != N1 && num != N2 && num != N3 && num != N4 && num!= N5 && num != N9)
	{
		//display menu again
		showMainMenu(id);
	}
}

public handleBlockMenu(id, num)
{
	switch (num)
	{
		case N1: { showBlockSelectionMenu(id); }
		case N2: { createBlockAiming(id, gSelectedBlockType[id]); }
		case N3: { convertBlockAiming(id, gSelectedBlockType[id]); }
		case N4: { deleteBlockAiming(id); }
		case N5: { rotateBlockAiming(id); }
		case N6: { toggleNoclip(id); }
		case N7: { toggleGodmode(id); }
		case N8: { changeBlockSize(id); }
		case N9: { showOptionsMenu(id, 2); }
		case N0: { showMainMenu(id); }
	}
	
	//selections 1, 9 and 0 show different menus
	if (num != N1 && num != N9 && num != N0)
	{
		//display menu again
		showBlockMenu(id);
	}
}

public handleBlockSelectionMenu(id, num)
{
	switch (num)
	{
		case N9:
		{
			//goto next block selection menu page
			++gBlockMenuPage[id];
			
			//make sure the player can't go above the maximum block selection page
			if (gBlockMenuPage[id] > gBlockMenuPagesMax)
			{
				gBlockMenuPage[id] = gBlockMenuPagesMax;
			}
			
			//show block selection menu again
			showBlockSelectionMenu(id);
		}
		
		case N0:
		{
			//goto previous block selection menu page
			--gBlockMenuPage[id];
			
			//show block menu if player goes back too far
			if (gBlockMenuPage[id] < 1)
			{
				showBlockMenu(id);
				gBlockMenuPage[id] = 1;
			}
			else
			{
				//show block selection menu again
				showBlockSelectionMenu(id);
			}
		}
		
		default:
		{
			//offset the num value using the players block selection page number
			num += (gBlockMenuPage[id] - 1) * 8;
			
			//if block number is within range
			if (num < gBlockMax)
			{
				gSelectedBlockType[id] = num;
				showBlockMenu(id);
			}
			else
			{
				showBlockSelectionMenu(id);
			}
		}
	}
}

public handleTeleportMenu(id, num)
{
	switch (num)
	{
		case N1: { createTeleportAiming(id, TELEPORT_START); }
		case N2: { createTeleportAiming(id, TELEPORT_END); }
		case N3: { swapTeleportAiming(id); }
		case N4: { deleteTeleportAiming(id); }
		case N5: { showTeleportPath(id); }
		case N6: { toggleNoclip(id); }
		case N7: { toggleGodmode(id); }
		case N9: { showOptionsMenu(id, 3); }
		case N0: { showMainMenu(id); }
	}
	
	//selections 9 and 0 show different menus
	if (num != N9 && num != N0)
	{
		showTeleportMenu(id);
	}
}

public handleTimerMenu(id, num)
{
	switch (num)
	{
		case N1: { createTimerAiming(id, TIMER_START); }
		case N2: { createTimerAiming(id, TIMER_END); }
		case N3: { swapTimerAiming(id); }
		case N4: { deleteTimerAiming(id); }
		case N5: { rotateTimerAiming(id); }
		case N6: { toggleNoclip(id); }
		case N7: { toggleGodmode(id); }
		case N9: { showOptionsMenu(id, 4); }
		case N0: { showMainMenu(id); }
	}
	
	//selections 9 and 0 show different menus
	if (num != N9 && num != N0)
	{
		showTimerMenu(id);
	}
}

public handleMeasureMenu(id, num)
{
	switch (num)
	{
		case N1: { measureToolSelectBlock(id, 1); }
		case N2: { measureToolSelectBlock(id, 2); }
		case N3: { measureToolSelectPos(id, 1); }
		case N4: { measureToolSelectPos(id, 2); }
		case N5: { toggleMeasureTool(id); }
		case N6: { toggleNoclip(id); }
		case N7: { toggleGodmode(id); }
		case N9: { showOptionsMenu(id, 5); }
		case N0: { showMainMenu(id); }
	}
	
	//selections 9 and 0 show different menus
	if (num != N9 && num != N0)
	{
		showMeasureMenu(id);
	}
}

public handleLongJumpMenu(id, num)
{
	switch (num)
	{
		case N1: { longJumpDistance(id, 1); }
		case N2: { longJumpCreate(id); }
		case N3: { longJumpDistance(id, 2); }
		case N4: { deleteBlockAiming(id); }
		case N5: { longJumpRotate(id); }
		case N6: { toggleNoclip(id); }
		case N7: { toggleGodmode(id); }
		case N8: { changeBlockSize(id); }
		case N9: { showOptionsMenu(id, 6); }
		case N0: { showMainMenu(id); }
	}
	
	//selections 9 and 0 show different menus
	if (num != N9 && num != N0)
	{
		showLongJumpMenu(id);
	}
}

public handleOptionsMenu(id, num)
{
	switch (num)
	{
		case N1: { toggleSnapping(id); }
		case N2: { toggleSnappingGap(id); }
		case N3: { groupBlockAiming(id); }
		case N4: { groupClear(id); }
		case N5: { showChoiceMenu(id, CHOICE_DEL_BLOCKS, "Are you sure you want to erase all blocks on the map?"); }
		case N6: { showChoiceMenu(id, CHOICE_DEL_TELEPORTS, "Are you sure you want to erase all teleports on the map?"); }
		case N7: { saveBlocks(id); }
		case N8: { showChoiceMenu(id, CHOICE_LOAD, "Loading will erase all blocks and teleports, do you want to continue?"); }
		case N9: { showHelp(id); }
		
		case N0:  //back to previous menu
		{
			switch (gMenuBeforeOptions[id])
			{
				case 1: showMainMenu(id);
				case 2: showBlockMenu(id);
				case 3: showTeleportMenu(id);
				case 4: showTimerMenu(id);
				case 5: showMeasureMenu(id);
				case 6: showLongJumpMenu(id);
				
				//for some reason the players 'gMenuBeforeOptions' number is invalid
				default: log_amx("%sPlayer ID: %d has an invalid gMenuBeforeOptions: %d", gszPrefix, id, gMenuBeforeOptions[id]);
			}
		}
	}
	
	//these selections show a different menu
	if (num != N5 && num != N6 && num != N8 && num != N0)
	{
		//display menu again
		showOptionsMenu(id, gMenuBeforeOptions[id]);
	}
}

public handleChoiceMenu(id, num)
{
	switch (num)
	{
		case N1:	//YES
		{
			switch (gChoiceOption[id])
			{
				case CHOICE_LOAD: loadBlocks(id);
				case CHOICE_DEL_BLOCKS: deleteAllBlocks(id, true);
				case CHOICE_DEL_TELEPORTS: deleteAllTeleports(id, true);
				
				default:
				{
					log_amx("%sInvalid choice in handleChoiceMenu()", gszPrefix);
				}
			}
		}
	}
	
	//show options menu again
	showOptionsMenu(id, gMenuBeforeOptions[id]);
}

measureToolSelectBlock(id, num)
{
	new ent;
	new body;
	get_user_aiming(id, ent, body);
	
	//if player is aiming at a block or a timer
	if (isBlock(ent) || isTimer(ent))
	{
		switch (num)
		{
			case 1:
			{
				//if block being aimed at is different than one already selected
				if (ent != gMeasureToolBlock2[id])
				{
					gMeasureToolBlock1[id] = ent;
				}
			}
			
			case 2:
			{
				//if block being aimed at is different than one already selected
				if (ent != gMeasureToolBlock1[id])
				{
					gMeasureToolBlock2[id] = ent;
				}
			}
			
			default:
			{
				log_amx("%sInvalid number in measureToolSelectBlock()", gszPrefix);
			}
		}
	}
}

measureToolSelectPos(id, num)
{
	new origin[3];
	new Float:vOrigin[3];
	
	//get the origin of where the player is aiming
	get_user_origin(id, origin, 3);
	IVecFVec(origin, vOrigin);
	
	switch (num)
	{
		case 1:
		{
			gvMeasureToolPos1[id] = vOrigin;
		}
		
		case 2:
		{
			gvMeasureToolPos2[id] = vOrigin;
		}
		
		default:
		{
			log_amx("%sInvalid number in measureToolSelectPos()", gszPrefix);
		}
	}
}

toggleMeasureTool(id)
{
	//make sure player has access to this command
	if (get_user_flags(id) & BM_ADMIN_LEVEL)
	{
		gbMeasureToolEnabled[id] = !gbMeasureToolEnabled[id];
	}
}

longJumpDistance(id, num)
{
	switch (num)
	{
		case 1:
		{
			if (gLongJumpDistance[id] < 300) gLongJumpDistance[id]++;
		}
		
		case 2:
		{
			if (gLongJumpDistance[id] > 200) gLongJumpDistance[id]--;
		}
		
		default:
		{
			log_amx("%sInvalid number in longJumpDistance()", gszPrefix);
		}
	}
}

longJumpCreate(id)
{
	//make sure player has access to this command
	if (get_user_flags(id) & BM_ADMIN_LEVEL)
	{
		new origin[3];
		new Float:vOrigin[3];
		new Float:fScale;
		new bool:bFailed = false;
		new axis;
		
		//get the origin of the player and add Z offset
		get_user_origin(id, origin, 3);
		IVecFVec(origin, vOrigin);
		vOrigin[2] += gfBlockSizeMaxForZ[2];
		
		//get scale depending on size
		switch (gBlockSize[id])
		{
			case SMALL: fScale = SCALE_SMALL;
			case NORMAL: fScale = SCALE_NORMAL;
			case LARGE: fScale = SCALE_LARGE;
		}
		
		//calculate half the jump distance and half the width of the block
		new Float:fDist = gLongJumpDistance[id] / 2.0;
		new Float:fHalfWidth = gfBlockSizeMaxForZ[0] * fScale;
		
		//move origin along X and create first block
		vOrigin[axis] -= (fDist + fHalfWidth);
		new block1 = createBlock(id, BM_PLATFORM, vOrigin, Z, gBlockSize[id]);
		
		//set axis on which to create the two blocks
		axis = gLongJumpAxis[id];
		
		//if first block is not stuck
		if (!isBlockStuck(block1))
		{
			//move origin along X and create second block
			vOrigin[axis] += (fDist + fHalfWidth) * 2;
			new block2 = createBlock(id, BM_PLATFORM, vOrigin, Z, gBlockSize[id]);
			
			//if block is stuck
			if (isBlockStuck(block2))
			{
				//delete both blocks
				deleteBlock(block1);
				deleteBlock(block2);
				bFailed = true;
			}
		}
		else
		{
			//delete the block
			deleteBlock(block1);
			bFailed = true;
		}
		
		//if long jump failed to create (because one of the blocks was stuck) notify the player
		if (bFailed)
		{
			client_print(id, print_chat, "%sLong jump failed to create because one or more of the blocks were stuck.", gszPrefix);
		}
	}
}

longJumpRotate(id)
{
	//swap between X and Y axes
	if (gLongJumpAxis[id] == X)
	{
		gLongJumpAxis[id] = Y;
	}
	else
	{
		gLongJumpAxis[id] = X;
	}
}

toggleGodmode(id)
{
	//make sure player has access to this command
	if (get_user_flags(id) & BM_ADMIN_LEVEL)
	{
		//if player has godmode
		if (get_user_godmode(id))
		{
			//turn off godmode for player
			set_user_godmode(id, 0);
			gbAdminGodmode[id] = false;
		}
		else
		{
			//turn on godmode for player
			set_user_godmode(id, 1);
			gbAdminGodmode[id] = true;
		}
	}
}

toggleNoclip(id)
{
	//make sure player has access to this command
	if (get_user_flags(id) & BM_ADMIN_LEVEL)
	{
		//if player has noclip
		if (get_user_noclip(id))
		{
			//turn off noclip for player
			set_user_noclip(id, 0);
			gbAdminNoclip[id] = false;
		}
		else
		{
			//turn on noclip for player
			set_user_noclip(id, 1);
			gbAdminNoclip[id] = true;
		}
	}
}

changeBlockSize(id)
{
	switch (gBlockSize[id])
	{
		case SMALL: gBlockSize[id] = NORMAL;
		case NORMAL: gBlockSize[id] = LARGE;
		case LARGE: gBlockSize[id] = SMALL;
	}
}

toggleSnapping(id)
{
	//make sure player has access to this command
	if (get_user_flags(id) & BM_ADMIN_LEVEL)
	{
		gbSnapping[id] = !gbSnapping[id];
	}
}

toggleSnappingGap(id)
{
	//make sure player has access to this command
	if (get_user_flags(id) & BM_ADMIN_LEVEL)
	{
		//increment this players snapping gap by 5
		gfSnappingGap[id] += 4.0;
		
		//if this players snapping gap gets too big then loop it back to 0
		if (gfSnappingGap[id] > 40.0)
		{
			gfSnappingGap[id] = 0.0;
		}
	}
}

showHelp(id)
{
	//get cvar values
	new szHelpText[1600];
	
	new Telefrags = get_cvar_num("bm_telefrags");
	new Float:fFireDamageAmount = get_cvar_float("bm_firedamageamount");
	new Float:fDamageAmount = get_cvar_float("bm_damageamount");
	new Float:fHealAmount = get_cvar_float("bm_healamount");
	new Float:fInvincibleTime = get_cvar_float("bm_invincibletime");
	new Float:fInvincibleCooldown = get_cvar_float("bm_invinciblecooldown");
	new Float:fStealthTime = get_cvar_float("bm_stealthtime");
	new Float:fStealthCooldown = get_cvar_float("bm_stealthcooldown");
	new Float:fCamouflageTime = get_cvar_float("bm_camouflagetime");
	new Float:fCamouflageCooldown = get_cvar_float("bm_camouflagecooldown");
	new Float:fNukeCooldown = get_cvar_float("bm_nukecooldown");
	new Float:fRandomCooldown = get_cvar_float("bm_randomcooldown");
	new Float:fBootsOfSpeedTime = get_cvar_float("bm_bootsofspeedtime");
	new Float:fBootsOfSpeedCooldown = get_cvar_float("bm_bootsofspeedcooldown");
	new Float:fAutoBhopTime = get_cvar_float("bm_autobhoptime");
	new Float:fAutoBhopCooldown = get_cvar_float("bm_autobhopcooldown");
	new TeleportSound = get_cvar_num("bm_teleportsound");
	
	//format the help text
	format(szHelpText, sizeof(szHelpText), gszHelpText, Telefrags, fFireDamageAmount, fDamageAmount, fHealAmount, fInvincibleTime, fInvincibleCooldown, fStealthTime, fStealthCooldown, fCamouflageTime, fCamouflageCooldown, fNukeCooldown, fRandomCooldown, fBootsOfSpeedTime, fBootsOfSpeedCooldown, fAutoBhopTime, fAutoBhopCooldown, TeleportSound);
	
	//show the help
	show_motd(id, szHelpText, gszHelpTitle);
}

showTeleportPath(id)
{
	//get the entity the player is aiming at
	new ent, body;
	get_user_aiming(id, ent, body);
	
	//if entity found is a teleport
	if (isTeleport(ent))
	{
		//get other side of teleport
		new tele = entity_get_int(ent, EV_INT_iuser1);
		
		//if there is another end to the teleport
		if (tele)
		{
			//get origins of the start and end teleport entities
			new life = 50;
			new Float:vOrigin1[3];
			new Float:vOrigin2[3];
			entity_get_vector(ent, EV_VEC_origin, vOrigin1);
			entity_get_vector(tele, EV_VEC_origin, vOrigin2);
			
			//draw a line in between the 2 origins
			drawLine(vOrigin1, vOrigin2, life);
			
			//get the distance between the points
			new Float:fDist = get_distance_f(vOrigin1, vOrigin2);
			
			//notify that a line has been drawn between the start and end of the teleport
			client_print(id, print_chat, "%sA line has been drawn to show the teleport path. Distance: %f units.", gszPrefix, fDist);
		}
	}
}

/* GROUPING BLOCKS */
groupBlockAiming(id)
{
	//make sure player has access to this command
	if (get_user_flags(id) & BM_ADMIN_LEVEL)
	{
		//get the entity the player is aiming at
		new ent, body;
		get_user_aiming(id, ent, body);
		
		//is entity is a block
		if (isBlock(ent))
		{
			//get whether or not block is already being grouped
			new player = entity_get_int(ent, EV_INT_iuser1);
			
			//if block is not in a group
			if (player == 0)
			{
				//increment group value
				++gGroupCount[id];
				
				//add this entity to the players group
				gGroupedBlocks[id][gGroupCount[id]] = ent;
				
				//set the block so it is now 'being grouped'
				groupBlock(id, ent);
				
			}
			//if block is in this players group
			else if (player == id)
			{
				//remove block from being grouped
				groupRemoveBlock(ent);
			}
			//if another player has the block grouped
			else
			{
				//get id and name of who has the block grouped
				new szName[32];
				new player = entity_get_int(ent, EV_INT_iuser1);
				get_user_name(player, szName, 32);
				
				//notify player who the block is being grouped by
				client_print(id, print_chat, "%sBlock is already in a group by: %s", gszPrefix, szName);
			}
		}
	}
}

groupBlock(id, ent)
{
	//if entity is valid
	if (is_valid_ent(ent))
	{
		//if id passed in is a player
		if (id > 0 && id <= 32)
		{
			//set block so it is now being grouped
			entity_set_int(ent, EV_INT_iuser1, id);
		}
		
		//make block glow red to show it is grouped
		set_rendering(ent, kRenderFxGlowShell, 255, 0, 0, kRenderNormal, 16);
	}
}

groupRemoveBlock(ent)
{
	//make sure entity is a block
	if (isBlock(ent))
	{
		//remove block from being grouped (stays in players gGroupedBlocks[id][] array
		entity_set_int(ent, EV_INT_iuser1, 0);
		
		//get block type
		new blockType = entity_get_int(ent, EV_INT_body);
		
		//set rendering on block
		set_block_rendering(ent, gRender[blockType], gRed[blockType], gGreen[blockType], gBlue[blockType], gAlpha[blockType]);
	}
}

groupClear(id)
{
	new blockCount = 0;
	new blocksDeleted = 0;
	new block;
	
	//remove all players blocks from being grouped
	for (new i = 0; i <= gGroupCount[id]; ++i)
	{
		block = gGroupedBlocks[id][i];
		
		//if block is in this players group
		if (isBlockInGroup(id, block))
		{
			//if block is stuck
			if (isBlockStuck(block))
			{
				//delete the stuck block
				deleteBlock(block);
				
				//count how many blocks have been deleted
				++blocksDeleted;
			}
			else
			{
				//remove block from being grouped
				groupRemoveBlock(block);
				
				//count how many blocks have been removed from group
				++blockCount;
			}
		}
	}
	
	//set players group count to 0
	gGroupCount[id] = 0;
	
	//if player is connected
	if (is_user_connected(id))
	{
		//if some blocks were deleted
		if (blocksDeleted > 0)
		{
			//notify player how many blocks were cleared from group and deleted
			client_print(id, print_chat, "%sRemoved %d blocks from group, deleted %d stuck blocks", gszPrefix, blockCount, blocksDeleted);
		}
		else
		{
			//notify player how many blocks were cleared from group
			client_print(id, print_chat, "%sRemoved %d blocks from group", gszPrefix, blockCount);
		}
	}
}

/* BLOCK & TELEPORT OPERATIONS */
moveGrabbedEntity(id, Float:vMoveTo[3] = {0.0, 0.0, 0.0})
{
	new iOrigin[3], iLook[3];
	new Float:fOrigin[3], Float:fLook[3], Float:fDirection[3], Float:fLength;
	
	get_user_origin(id, iOrigin, 1);		//Position from eyes (weapon aiming)
	get_user_origin(id, iLook, 3);			//End position from eyes (hit point for weapon)
	IVecFVec(iOrigin, fOrigin);
	IVecFVec(iLook, fLook);
	
	fDirection[0] = fLook[0] - fOrigin[0];
	fDirection[1] = fLook[1] - fOrigin[1];
	fDirection[2] = fLook[2] - fOrigin[2];
	fLength = get_distance_f(fLook, fOrigin);
	
	if (fLength == 0.0) fLength = 1.0;		//avoid division by 0
	
	//calculate the position to move the block
	vMoveTo[0] = (fOrigin[0] + fDirection[0] * gfGrablength[id] / fLength) + gvGrabOffset[id][0];
	vMoveTo[1] = (fOrigin[1] + fDirection[1] * gfGrablength[id] / fLength) + gvGrabOffset[id][1];
	vMoveTo[2] = (fOrigin[2] + fDirection[2] * gfGrablength[id] / fLength) + gvGrabOffset[id][2];
	vMoveTo[2] = float(floatround(vMoveTo[2], floatround_floor));
	
	//move the block and its sprite (if it has one)
	moveEntity(id, gGrabbed[id], vMoveTo, true);
}

moveEntity(id, ent, Float:vMoveTo[3], bool:bDoSnapping)
{
	//if entity is a block
	if (isBlock(ent))
	{
		//do snapping for entity if snapping boolean passed in is true
		if (bDoSnapping)
		{
			doSnapping(id, ent, vMoveTo);
		}
		
		//set the position of the block
		entity_set_origin(ent, vMoveTo);
		
		//get the sprite that sits above the block (if any)
		new sprite = entity_get_int(ent, EV_INT_iuser3);
		
		//if sprite entity is valid
		if (sprite)
		{
			//get size of block
			new Float:vSizeMax[3];
			entity_get_vector(ent, EV_VEC_maxs, vSizeMax);
			
			//move the sprite onto the top of the block
			vMoveTo[2] += vSizeMax[2] + 0.15;
			entity_set_origin(sprite, vMoveTo);
		}
	}
	else
	{
		//set the position of the entity
		entity_set_origin(ent, vMoveTo);
	}
}

/* TELEPORTS */
createTeleportAiming(const id, const teleportType)
{
	//make sure player has access to this command
	if (get_user_flags(id) & BM_ADMIN_LEVEL)
	{
		//get where player is aiming for origin of teleport entity
		new pOrigin[3], Float:vOrigin[3];
		get_user_origin(id, pOrigin, 3);
		IVecFVec(pOrigin, vOrigin);
		vOrigin[2] += gfTeleportZOffset;
		
		//create the teleport of the given type
		createTeleport(id, teleportType, vOrigin);
	}
}

createTeleport(const id, const teleportType, Float:vOrigin[3])
{
	new ent = create_entity(gszInfoTarget);
	
	if (is_valid_ent(ent))
	{
		switch (teleportType)
		{
			case TELEPORT_START:
			{
				//if player has already created a teleport start entity then delete it
				if (gTeleportStart[id])
				{
					remove_entity(gTeleportStart[id]);
				}
				
				//set teleport properties
				entity_set_string(ent, EV_SZ_classname, gszTeleportStartClassname);
				entity_set_int(ent, EV_INT_solid, SOLID_BBOX);
				entity_set_int(ent, EV_INT_movetype, MOVETYPE_NONE);
				entity_set_model(ent, gszTeleportSpriteStart);
				entity_set_size(ent, gfTeleportSizeMin, gfTeleportSizeMax);
				entity_set_origin(ent, vOrigin);
				
				//set the rendermode and transparency
				entity_set_int(ent, EV_INT_rendermode, 5);	//rendermode
				entity_set_float(ent, EV_FL_renderamt, 255.0);	//visable 
				
				//set task for animating sprite
				new params[2];
				params[0] = ent;
				params[1] = gTeleportStartFrames;
				set_task(0.1, "taskSpriteNextFrame", TASK_SPRITE + ent, params, 2, "b");
				
				//store teleport start entity to a global variable so it can be linked to the end entity 
				gTeleportStart[id] = ent;
			}
			
			case TELEPORT_END:
			{
				//make sure there is a teleport start entity
				if (gTeleportStart[id])
				{
					//set teleport properties
					entity_set_string(ent, EV_SZ_classname, gszTeleportEndClassname);
					entity_set_int(ent, EV_INT_solid, SOLID_BBOX);
					entity_set_int(ent, EV_INT_movetype, MOVETYPE_NONE);
					entity_set_model(ent, gszTeleportSpriteEnd);
					entity_set_size(ent, gfTeleportSizeMin, gfTeleportSizeMax);
					entity_set_origin(ent, vOrigin);
					
					//set the rendermode and transparency
					entity_set_int(ent, EV_INT_rendermode, 5);	//rendermode
					entity_set_float(ent, EV_FL_renderamt, 255.0);	//visable 
					
					//link up teleport start and end entities
					entity_set_int(ent, EV_INT_iuser1, gTeleportStart[id]);
					entity_set_int(gTeleportStart[id], EV_INT_iuser1, ent);
					
					//set task for animating sprite
					new params[2];
					params[0] = ent;
					params[1] = gTeleportEndFrames;
					set_task(0.1, "taskSpriteNextFrame", TASK_SPRITE + ent, params, 2, "b");
					
					//indicate that this player has no teleport start entity waiting for an end
					gTeleportStart[id] = 0;
				}
				else
				{
					//delete entity that was created because there is no start entity
					remove_entity(ent);
				}
			}
		}
	}
	else
	{
		log_amx("%sCouldn't create 'env_sprite' entity", gszPrefix);
	}
}

swapTeleportAiming(id)
{
	//make sure player has access to this command
	if (get_user_flags(id) & BM_ADMIN_LEVEL)
	{
		//get entity that player is aiming at
		new ent, body;
		get_user_aiming(id, ent, body, 9999);
		
		//swap teleport start and destination
		if (isTeleport(ent))
		{
			swapTeleport(id, ent);
		}
	}
}

swapTeleport(id, ent)
{
	new Float:vOriginEnt[3];
	new Float:vOriginTele[3];
	
	//get the other end of the teleport
	new tele = entity_get_int(ent, EV_INT_iuser1);
	
	//if the teleport has another side
	if (is_valid_ent(tele))
	{
		//get teleport properties
		entity_get_vector(ent, EV_VEC_origin, vOriginEnt);
		entity_get_vector(tele, EV_VEC_origin, vOriginTele);
		
		new szClassname[32];
		entity_get_string(ent, EV_SZ_classname, szClassname, 32);
		
		//delete old teleport
		deleteTeleport(id, ent);
		
		//create new teleport at opposite positions
		if (equal(szClassname, gszTeleportStartClassname))
		{
			createTeleport(id, TELEPORT_START, vOriginTele);
			createTeleport(id, TELEPORT_END, vOriginEnt);
		}
		else if (equal(szClassname, gszTeleportEndClassname))
		{
			createTeleport(id, TELEPORT_START, vOriginEnt);
			createTeleport(id, TELEPORT_END, vOriginTele);
		}
	}
	else
	{
		//tell player they cant swap because its only 1 sided
		client_print(id, print_chat, "%sCan't swap teleport positions", gszPrefix);
	}
}

deleteTeleportAiming(id)
{
	//make sure player has access to this command
	if (get_user_flags(id) & BM_ADMIN_LEVEL)
	{
		//get entity that player is aiming at
		new ent, body;
		get_user_aiming(id, ent, body, 9999);
		
		//delete block that player is aiming at
		new bool:deleted = deleteTeleport(id, ent);
		
		if (deleted)
		{
			client_print(id, print_chat, "%sTeleport deleted!", gszPrefix);
		}
	}
}

bool:deleteTeleport(id, ent)
{
	//if entity is a teleport then delete both the start and the end of the teleport
	if (isTeleport(ent))
	{
		//get entity id of the other side of the teleport
		new tele = entity_get_int(ent, EV_INT_iuser1);
		
		//clear teleport start entity if it was just deleted
		if (gTeleportStart[id] == ent || gTeleportStart[id] == tele)
		{
			gTeleportStart[id] = 0;
		}
		
		//remove tasks that exist to animate the teleport sprites
		if (task_exists(TASK_SPRITE + ent))
		{
			remove_task(TASK_SPRITE + ent);
		}
		
		if (task_exists(TASK_SPRITE + tele))
		{
			remove_task(TASK_SPRITE + tele);
		}
		
		//delete both the start and end positions of the teleporter
		if (tele)
		{
			remove_entity(tele);
		}
		
		remove_entity(ent);
		
		//delete was deleted
		return true;
	}
	
	//teleport was not deleted
	return false;
}

/* TIMERS */
createTimerAiming(id, timerType)
{
	//make sure player has access to this command
	if (get_user_flags(id) & BM_ADMIN_LEVEL)
	{
		new origin[3];
		new Float:vOrigin[3];
		
		//get the origin of where the player is looking
		get_user_origin(id, origin, 3);
		IVecFVec(origin, vOrigin);
		
		//create the timer
		createTimer(id, timerType, vOrigin);
	}
}

createTimer(id, timerType, Float:vOrigin[3], Float:vAngles[3] = { 0.0, 0.0, 0.0 })
{
	new ent;
	
	switch (timerType)
	{
		case TIMER_START:
		{
			//if player has already created a timer start entity then delete it
			if (gStartTimer[id])
			{
				if (is_valid_ent(gStartTimer[id]))
				{
					remove_entity(gStartTimer[id]);
				}
			}
			
			ent = create_entity("func_button");
			
			//make sure entity was created successfully
			if (is_valid_ent(ent))
			{
				//set timer properties
				entity_set_string(ent, EV_SZ_classname, gszTimerClassname);
				entity_set_int(ent, EV_INT_body, timerType);
				entity_set_int(ent, EV_INT_solid, SOLID_BBOX);
				entity_set_int(ent, EV_INT_movetype, MOVETYPE_NONE);
				entity_set_model(ent, gszTimerModelStart);
				entity_set_vector(ent, EV_VEC_angles, vAngles);
				entity_set_size(ent, gfTimerSizeMin, gfTimerSizeMax);
				entity_set_origin(ent, vOrigin);
				
				//player has now created a timer start
				gStartTimer[id] = ent;
			}
		}
		
		case TIMER_END:
		{
			//make sure player has created a start timer entity
			if (isTimer(gStartTimer[id]))
			{
				ent = create_entity("func_button");
				
				//make sure entity was created successfully
				if (is_valid_ent(ent))
				{
					//set timer properties
					entity_set_string(ent, EV_SZ_classname, gszTimerClassname);
					entity_set_int(ent, EV_INT_body, timerType);
					entity_set_int(ent, EV_INT_solid, SOLID_BBOX);
					entity_set_int(ent, EV_INT_movetype, MOVETYPE_NONE);
					entity_set_model(ent, gszTimerModelEnd);
					entity_set_vector(ent, EV_VEC_angles, vAngles);
					entity_set_size(ent, gfTimerSizeMin, gfTimerSizeMax);
					entity_set_origin(ent, vOrigin);
					
					//link up start and end timers
					entity_set_int(ent, EV_INT_iuser1, gStartTimer[id]);
					entity_set_int(gStartTimer[id], EV_INT_iuser1, ent);
					
					//indicate that this player has no start timer entity
					gStartTimer[id] = 0;
				}
			}
		}
	}
	
	return ent;
}

swapTimerAiming(id)
{
	//make sure player has access to this command
	if (get_user_flags(id) & BM_ADMIN_LEVEL)
	{
		//get entity that player is aiming at
		new ent, body;
		get_user_aiming(id, ent, body, 9999);
		
		//swap the start & end timer positions
		if (isTimer(ent))
		{
			swapTimer(id, ent);
		}
	}
}

swapTimer(id, ent)
{
	new Float:vOriginEnt[3];
	new Float:vOriginTimer[3];
	new Float:vAngleEnt[3];
	new Float:vAngleTimer[3];
	
	//get the other end of the timer
	new timer = entity_get_int(ent, EV_INT_iuser1);
	
	//if the timer has another side
	if (is_valid_ent(timer))
	{
		//get timer properties
		new type = entity_get_int(ent, EV_INT_body);
		entity_get_vector(ent, EV_VEC_origin, vOriginEnt);
		entity_get_vector(ent, EV_VEC_angles, vAngleEnt);
		entity_get_vector(timer, EV_VEC_origin, vOriginTimer);
		entity_get_vector(timer, EV_VEC_angles, vAngleTimer);
		
		//delete old timers
		remove_entity(ent);
		remove_entity(timer);
		
		//create new timers at opposite positions
		if (type == TIMER_START)
		{
			createTimer(id, TIMER_START, vOriginTimer, vAngleTimer);
			createTimer(id, TIMER_END, vOriginEnt, vAngleEnt);
		}
		else if (type == TIMER_END)
		{
			createTimer(id, TIMER_START, vOriginEnt, vAngleEnt);
			createTimer(id, TIMER_END, vOriginTimer, vAngleTimer);
		}
		else
		{
			log_amx("Invalid timer type: %d", type);
		}
	}
	else
	{
		//tell player they cant swap because its only 1 sided
		client_print(id, print_chat, "%sCan't swap timer positions", gszPrefix);
	}
}

deleteTimerAiming(id)
{
	//make sure player has access to this command
	if (get_user_flags(id) & BM_ADMIN_LEVEL)
	{
		//get entity that player is aiming at
		new ent, body;
		get_user_aiming(id, ent, body, 9999);
		
		//delete timer that player is aiming at
		new bool:deleted = deleteTimer(ent);
		
		if (deleted)
		{
			client_print(id, print_chat, "%sTimer deleted!", gszPrefix);
			
			//make sure all players start timer entities are valid
			for (new i = 1; i <= 32; ++i)
			{
				if (!is_valid_ent(gStartTimer[i]))
				{
					gStartTimer[i] = 0;
				}
			}
		}
	}
}

bool:deleteTimer(ent)
{
	//if entity is a teleport then delete both the start and the end of the timer
	if (isTimer(ent))
	{
		//get entity id of the other side of the timer
		new timer = entity_get_int(ent, EV_INT_iuser1);
		
		//delete both the start and end positions of the timer
		if (timer)
		{
			remove_entity(timer);
		}
		
		remove_entity(ent);
		
		//timer was deleted
		return true;
	}
	
	//teleport was not deleted
	return false;
}

rotateTimerAiming(id)
{
	//make sure player has access to this command
	if (get_user_flags(id) & BM_ADMIN_LEVEL)
	{
		//get entity that player is aiming at
		new ent, body;
		get_user_aiming(id, ent, body, 9999);
		
		//rotate timer that player is aiming at
		if (isTimer(ent))
		{
			rotateTimer(ent);
		}
	}
}

rotateTimer(ent)
{
	new Float:vAngles[3]; 
	
	//get timer angles
	entity_get_vector(ent, EV_VEC_angles, vAngles);
	
	//change the timers angles depending on its current angle
	if (vAngles[1] == 0.0)
	{
		vAngles[1] = 90.0;
	}
	else if (vAngles[1] == 90.0)
	{
		vAngles[1] = 180.0;
	}
	else if (vAngles[1] == 180.0)
	{
		vAngles[1] = 270.0;
	}
	else if (vAngles[1] == 270.0)
	{
		vAngles[1] = 0.0;
	}
	
	//set the timers new angles
	entity_set_vector(ent, EV_VEC_angles, vAngles);
}

/* OPTIONS */
deleteAllBlocks(id, bool:bNotify)
{
	//make sure player has access to this command
	if (get_user_flags(id) & BM_ADMIN_LEVEL)
	{
		new bool:bDeleted;
		new blockCount = 0;
		new ent = -1;
		
		//find all blocks in the map
		while ((ent = find_ent_by_class(ent, gszBlockClassname)))
		{
			//delete the block
			bDeleted = deleteBlock(ent);
			
			//if block was successfully deleted
			if (bDeleted)
			{
				//increment counter for how many blocks have been deleted
				++blockCount;
			}
		}
		
		//if some blocks were deleted
		if (blockCount > 0)
		{
			//get players name
			new szName[32];
			get_user_name(id, szName, 32);
			
			//iterate through all players
			for (new i = 1; i <= 32; ++i)
			{
				//make sure nobody is grabbing a block because they've all been deleted!
				gGrabbed[id] = 0;
				
				//make sure player is connected
				if (is_user_connected(i))
				{
					//notify all admins that the player deleted all the blocks
					if (bNotify && get_user_flags(i) & BM_ADMIN_LEVEL)
					{
						client_print(i, print_chat, "%s'%s' deleted all the blocks from the map. Total blocks: %d", gszPrefix, szName, blockCount);
					}
				}
			}
		}
	}
}

deleteAllTeleports(id, bool:bNotify)
{
	//make sure player has access to this command
	if (get_user_flags(id) & BM_ADMIN_LEVEL)
	{
		new bool:bDeleted;
		new teleCount = 0;
		new ent = -1;
		
		//find all teleport start entities in the map
		while ((ent = find_ent_by_class(ent, gszTeleportStartClassname)))
		{
			//delete the teleport
			bDeleted = deleteTeleport(id, ent);
			
			//if teleport was successfully deleted
			if (bDeleted)
			{
				//increment counter for how many teleports have been deleted
				++teleCount;
			}
		}
		
		//if some teleports were deleted
		if (teleCount > 0)
		{
			//get players name
			new szName[32];
			get_user_name(id, szName, 32);
			
			//iterate through all players
			for (new i = 1; i <= 32; ++i)
			{
				//make sure nobody has a teleport start set
				gTeleportStart[id] = 0;
				
				//make sure player is connected
				if (is_user_connected(i))
				{
					//notify all admins that the player deleted all the teleports
					if (bNotify && get_user_flags(i) & BM_ADMIN_LEVEL)
					{
						client_print(i, print_chat, "%s'%s' deleted all the teleports from the map. Total teleports: %d", gszPrefix, szName, teleCount);
					}
				}
			}
		}
	}
}

deleteAllTimers(id, bool:bNotify)
{
	//make sure player has access to this command
	if (get_user_flags(id) & BM_ADMIN_LEVEL)
	{
		new bool:bDeleted;
		new timerCount = 0;
		new ent = -1;
		
		//find all timer start entities in the map
		while ((ent = find_ent_by_class(ent, gszTimerClassname)))
		{
			//delete the timer
			bDeleted = deleteTimer(ent);
			
			//if timer was successfully deleted
			if (bDeleted)
			{
				//increment counter for how many timers have been deleted
				++timerCount;
			}
		}
		
		//if some timers were deleted
		if (timerCount > 0)
		{
			//get players name
			new szName[32];
			get_user_name(id, szName, 32);
			
			//iterate through all players
			for (new i = 1; i <= 32; ++i)
			{
				//make sure nobody has a timer start set
				gStartTimer[id] = 0;
				
				//make sure player is connected
				if (is_user_connected(i))
				{
					//notify all admins that the player deleted all the teleports
					if (bNotify && get_user_flags(i) & BM_ADMIN_LEVEL)
					{
						client_print(i, print_chat, "%s'%s' deleted all the teleports from the map. Total teleports: %d", gszPrefix, szName, timerCount);
					}
				}
			}
		}
	}
}

/***** BLOCKS *****/
createBlockAiming(const id, const blockType)
{
	//make sure player has access to this command
	if (get_user_flags(id) & BM_ADMIN_LEVEL)
	{
		new origin[3];
		new Float:vOrigin[3];
		
		//get the origin of the player and add Z offset
		get_user_origin(id, origin, 3);
		IVecFVec(origin, vOrigin);
		vOrigin[2] += gfBlockSizeMaxForZ[2];
		
		//create the block
		createBlock(id, blockType, vOrigin, Z, gBlockSize[id]);
	}
}

createBlock(const id, const blockType, Float:vOrigin[3], const axis, const size)
{
	new ent = create_entity(gszInfoTarget);
	
	//make sure entity was created successfully
	if (is_valid_ent(ent))
	{
		//set block properties
		entity_set_string(ent, EV_SZ_classname, gszBlockClassname);
		entity_set_int(ent, EV_INT_solid, SOLID_BBOX);
		entity_set_int(ent, EV_INT_movetype, MOVETYPE_NONE);
		
		new Float:vSizeMin[3];
		new Float:vSizeMax[3];
		new Float:vAngles[3];
		new Float:fScale;
		new szBlockModel[256];
		
		//set mins, maxs and angles depending on axis
		switch (axis)
		{
			case X:
			{
				vSizeMin = gfBlockSizeMinForX;
				vSizeMax = gfBlockSizeMaxForX;
				vAngles[0] = 90.0;
			}
			
			case Y:
			{
				vSizeMin = gfBlockSizeMinForY;
				vSizeMax = gfBlockSizeMaxForY;
				vAngles[0] = 90.0;
				vAngles[2] = 90.0;
			}
			
			case Z:
			{
				vSizeMin = gfBlockSizeMinForZ;
				vSizeMax = gfBlockSizeMaxForZ;
				vAngles = gfDefaultBlockAngles;
			}
		}
		
		//set block model name and scale depending on size
		switch (size)
		{
			case SMALL:
			{
				setBlockModelNameSmall(szBlockModel, gszBlockModels[blockType], 256);
				fScale = SCALE_SMALL;
			}
			
			case NORMAL:
			{
				szBlockModel = gszBlockModels[blockType];
				fScale = SCALE_NORMAL;
			}
			
			case LARGE:
			{
				setBlockModelNameLarge(szBlockModel, gszBlockModels[blockType], 256);
				fScale = SCALE_LARGE;
			}
		}
		
		//adjust size min/max vectors depending on scale
		for (new i = 0; i < 3; ++i)
		{
			if (vSizeMin[i] != 4.0 && vSizeMin[i] != -4.0)
			{
				vSizeMin[i] *= fScale;
			}
			
			if (vSizeMax[i] != 4.0 && vSizeMax[i] != -4.0)
			{
				vSizeMax[i] *= fScale;
			}
		}
		
		//if it's a valid block type
		if (blockType >= 0 && blockType < gBlockMax)
		{
			entity_set_model(ent, szBlockModel);
		}
		else
		{
			entity_set_model(ent, gszBlockModelDefault);
		}
		
		entity_set_vector(ent, EV_VEC_angles, vAngles);
		entity_set_size(ent, vSizeMin, vSizeMax);
		entity_set_int(ent, EV_INT_body, blockType);
		
		//if a player is creating the block
		if (id > 0 && id <= 32)
		{
			//do snapping for new block
			doSnapping(id, ent, vOrigin);
		}
		
		//set origin of new block
		entity_set_origin(ent, vOrigin);
		
		//setup special properties for the random block
		if (blockType == BM_RANDOM)
		{
			//set this random block to a random block!
			new randNum = random_num(0, gRandomBlocksMax - 1);
			entity_set_int(ent, EV_INT_iuser4, gRandomBlocks[randNum]);
		}
		
		//set rendering on block
		set_block_rendering(ent, gRender[blockType], gRed[blockType], gGreen[blockType], gBlue[blockType], gAlpha[blockType]);
		
		//if blocktype is one which requires an additional sprite
		if (blockType == BM_FIRE || blockType == BM_TRAMPOLINE || blockType == BM_SPEEDBOOST)
		{
			//add sprite on top of the block
			new sprite = create_entity(gszInfoTarget);
			
			//make sure entity was created successfully
			if (sprite)
			{
				//create angle vector and rotate it so its horizontal
				new Float:vAngles[3];
				vAngles[0] = 90.0;
				vAngles[1] = 0.0;
				vAngles[2] = 0.0;
				
				//move the sprite up onto the top of the block, adding 0.15 to prevent flickering
				vOrigin[2] += vSizeMax[2] + 0.15;
				
				//set block properties
				entity_set_string(sprite, EV_SZ_classname, gszSpriteClassname);
				entity_set_int(sprite, EV_INT_solid, SOLID_NOT);
				entity_set_int(sprite, EV_INT_movetype, MOVETYPE_NONE);
				entity_set_vector(sprite, EV_VEC_angles, vAngles);
				
				//set sprite name depending on size
				switch (size)
				{
					case SMALL:
					{
						//set sprite model depending on block type
						switch (blockType)
						{
							case BM_TRAMPOLINE: entity_set_model(sprite, gszBlockSpriteTrampolineSmall);
							case BM_SPEEDBOOST: entity_set_model(sprite, gszBlockSpriteSpeedBoostSmall);
							case BM_FIRE: entity_set_model(sprite, gszBlockSpriteFireSmall);
						}
					}
					
					case NORMAL:
					{
						//set sprite model depending on block type
						switch (blockType)
						{
							case BM_TRAMPOLINE: entity_set_model(sprite, gszBlockSpriteTrampoline);
							case BM_SPEEDBOOST: entity_set_model(sprite, gszBlockSpriteSpeedBoost);
							case BM_FIRE: entity_set_model(sprite, gszBlockSpriteFire);
						}
					}
					
					case LARGE:
					{
						//set sprite model depending on block type
						switch (blockType)
						{
							case BM_TRAMPOLINE: entity_set_model(sprite, gszBlockSpriteTrampolineLarge);
							case BM_SPEEDBOOST: entity_set_model(sprite, gszBlockSpriteSpeedBoostLarge);
							case BM_FIRE: entity_set_model(sprite, gszBlockSpriteFireLarge);
						}
					}
				}
				
				//set the rendermode to additive and set the transparency
				entity_set_int(sprite, EV_INT_rendermode, 5);
				entity_set_float(sprite, EV_FL_renderamt, 255.0);
				
				//set origin of new sprite
				entity_set_origin(sprite, vOrigin);
				
				//link this sprite to the block
				entity_set_int(ent, EV_INT_iuser3, sprite);
				
				//set task for animating the sprite
				if (blockType == BM_FIRE || blockType == BM_TRAMPOLINE)
				{
					new params[2];
					params[0] = sprite;
					params[1] = 8;		//both the fire and trampoline sprites have 8 frames
					set_task(0.1, "taskSpriteNextFrame", TASK_SPRITE + sprite, params, 2, "b");
				}
			}
		}
		
		return ent;
	}
	
	return 0;
}

convertBlockAiming(id, const convertTo)
{
	//make sure player has access to this command
	if (get_user_flags(id) & BM_ADMIN_LEVEL)
	{
		//get entity that player is aiming at
		new ent, body;
		get_user_aiming(id, ent, body);
		
		//if player is aiming at a block
		if (isBlock(ent))
		{
			//get who is currently grabbing the block (if anyone)
			new grabber = entity_get_int(ent, EV_INT_iuser2);
			
			//if entity is not being grabbed by someone else
			if (grabber == 0 || grabber == id)
			{
				//get the player ID of who has the block in a group (if anyone)
				new player = entity_get_int(ent, EV_INT_iuser1);
				
				//if the block is not in a group or is in this players group
				if (player == 0 || player == id)
				{
					new newBlock;
					
					//if block is in the players group and group count is larger than 1
					if (isBlockInGroup(id, ent) && gGroupCount[id] > 1)
					{
						new block;
						new blockCount = 0;
						
						//iterate through all blocks in the players group
						for (new i = 0; i <= gGroupCount[id]; ++i)
						{
							block = gGroupedBlocks[id][i];
							
							//if this block is in this players group
							if (isBlockInGroup(id, block))
							{
								//convert the block
								newBlock = convertBlock(id, block, convertTo, true);
								
								//if block was converted
								if (newBlock != 0)
								{
									//new block is now in the group
									gGroupedBlocks[id][i] = newBlock;
									
									//set the block so it is now 'being grouped'
									groupBlock(id, newBlock);
								}
								//count how many blocks could NOT be converted
								else
								{
									++blockCount;
								}
							}
						}
						
						//if some blocks could NOT be converted
						if (blockCount > 1)
						{
							client_print(id, print_chat, "%sCouldn't convert %d blocks!", gszPrefix, blockCount);
						}
					}
					else
					{
						newBlock = convertBlock(id, ent, convertTo, false);
						
						//if block was not converted
						if (newBlock == 0)
						{
							//get the block type
							new blockType = entity_get_int(ent, EV_INT_body);
							
							client_print(id, print_chat, "%sYou cannot convert a %s block into a %s block while it is rotated!", gszPrefix, gszBlockNames[blockType], gszBlockNames[convertTo]);
						}
					}
				}
				else
				{
					//get name of player who has this block in their group
					new szName[32]; 
					get_user_name(player, szName, 32);
					
					//notify player who has this block in their group
					client_print(id, print_chat, "%s%s currently has this block in their group!", gszPrefix, szName);
				}
			}
		}
	}
}

convertBlock(id, ent, const convertTo, const bool:bPreserveSize)
{
	new blockType;
	new Float:vOrigin[3];
	new Float:vSizeMax[3];
	new axis;
	
	//get block information from block player is aiming at
	blockType = entity_get_int(ent, EV_INT_body);
	entity_get_vector(ent, EV_VEC_origin, vOrigin);
	entity_get_vector(ent, EV_VEC_maxs, vSizeMax);
	
	//work out the axis orientation
	for (new i = 0; i < 3; ++i)
	{
		if (vSizeMax[i] == 4.0)
		{
			axis = i;
			break;
		}
	}
	
	//if block is rotated and we're trying to convert it to a block that cannot be rotated
	if ((axis == X || axis == Y) && !isBlockTypeRotatable(blockType))
	{
		return 0;
	}
	else
	{
		//delete old block and create new one of given type
		deleteBlock(ent);
		
		if (bPreserveSize)
		{
			//work out the block size
			new size = SMALL;
			new Float:fMax = vSizeMax[0] + vSizeMax[1] + vSizeMax[2];
			if (fMax > 64.0) size = NORMAL;
			if (fMax > 128.0) size = LARGE;
			
			return createBlock(id, convertTo, vOrigin, axis, size);
		}
		else
		{
			return createBlock(id, convertTo, vOrigin, axis, gBlockSize[id]);
		}
	}
	
	return ent;
}

deleteBlockAiming(id)
{
	//make sure player has access to this command
	if (get_user_flags(id) & BM_ADMIN_LEVEL)
	{
		//get entity that player is aiming at
		new ent, body;
		get_user_aiming(id, ent, body);
		
		//if entity player is aiming at is a block
		if (isBlock(ent))
		{
			//get who is currently grabbing the block (if anyone)
			new grabber = entity_get_int(ent, EV_INT_iuser2);
			
			//if entity is not being grabbed by someone else
			if (grabber == 0 || grabber == id)
			{
				//get the player ID of who has the block in a group (if anyone)
				new player = entity_get_int(ent, EV_INT_iuser1);
				
				//if the block is not in a group or is in this players group
				if (player == 0 || player == id)
				{
					//if block is not being grabbed
					if (entity_get_int(ent, EV_INT_iuser2) == 0)
					{
						//if block is in the players group and group count is larger than 1
						if (isBlockInGroup(id, ent) && gGroupCount[id] > 1)
						{
							new block;
							
							//iterate through all blocks in the players group
							for (new i = 0; i <= gGroupCount[id]; ++i)
							{
								block = gGroupedBlocks[id][i];
								
								//if block is still valid
								if (is_valid_ent(block))
								{
									//get player id of who has this block in their group
									new player = entity_get_int(block, EV_INT_iuser1);
									
									//if block is still in this players group
									if (player == id)
									{
										//delete the block
										deleteBlock(block);
									}
								}
							}
						}
						else
						{
							//delete the block
							deleteBlock(ent);
						}
					}
				}
				else
				{
					//get name of player who has this block in their group
					new szName[32]; 
					get_user_name(player, szName, 32);
					
					//notify player who has this block in their group
					client_print(id, print_chat, "%s%s currently has this block in their group!", gszPrefix, szName);
				}
			}
		}
	}
}

bool:deleteBlock(ent)
{
	//if entity is a block
	if (isBlock(ent))
	{
		//get the sprite attached to the top of the block
		new sprite = entity_get_int(ent, EV_INT_iuser3);
		
		//if sprite entity is valid
		if (sprite)
		{
			//remove the task for the animation of the sprite (if one exists)
			if (task_exists(TASK_SPRITE + sprite))
			{
				remove_task(TASK_SPRITE + sprite);
			}
			
			//delete the sprite
			remove_entity(sprite);
		}
		
		//delete the block
		remove_entity(ent);
		
		//block was deleted
		return true;
	}
	
	//block was not deleted
	return false;
}

rotateBlockAiming(id)
{
	//make sure player has access to this command
	if (get_user_flags(id) & BM_ADMIN_LEVEL)
	{
		//get block that player is aiming at
		new ent, body;
		get_user_aiming(id, ent, body);
		
		//if entity found is a block
		if (isBlock(ent))
		{
			//get who is currently grabbing the block (if anyone)
			new grabber = entity_get_int(ent, EV_INT_iuser2);
			
			//if entity is not being grabbed by someone else
			if (grabber == 0 || grabber == id)
			{
				//get the player ID of who has the block in a group (if anyone)
				new player = entity_get_int(ent, EV_INT_iuser1);
				
				//if the block is not in a group or is in this players group
				if (player == 0 || player == id)
				{
					//if block is in the players group and group count is larger than 1
					if (isBlockInGroup(id, ent) && gGroupCount[id] > 1)
					{
						new block;
						new bool:bRotateGroup = true;
						
						//iterate through all blocks in the players group
						for (new i = 0; i <= gGroupCount[id]; ++i)
						{
							block = gGroupedBlocks[id][i];
							
							//if block is in players group
							if (isBlockInGroup(id, block))
							{
								//get block type
								new blockType = entity_get_int(block, EV_INT_body);
								 
								//if block cannot be rotated
								if (!isBlockTypeRotatable(blockType))
								{
									//found a block that cannot be rotated
									bRotateGroup = false;
									
									break;
								}
							}
						}
						
						//if we can rotate the group
						if (bRotateGroup)
						{
							//iterate through all blocks in the players group
							for (new i = 0; i <= gGroupCount[id]; ++i)
							{
								block = gGroupedBlocks[id][i];
								
								//if block is still valid
								if (isBlockInGroup(id, block))
								{
									//rotate the block
									rotateBlock(block);
								}
							}
						}
						else
						{
							//notify player that their group cannot be rotated
							client_print(id, print_chat, "%sYour group contains blocks that cannot be rotated!", gszPrefix);
						}
					}
					else
					{
						//rotate the block and get rotated block ID
						new bool:bRotatedBlock = rotateBlock(ent);
						
						//if block did not rotate successfully
						if (!bRotatedBlock)
						{
							//get block type
							new blockType = entity_get_int(ent, EV_INT_body);
							
							//notify player block couldn't rotate
							client_print(id, print_chat, "%s%s blocks cannot be rotated!", gszPrefix, gszBlockNames[blockType]);
						}
					}
				}
				else
				{
					//get name of player who has this block in their group
					new szName[32]; 
					get_user_name(player, szName, 32);
					
					//notify player who has this block in their group
					client_print(id, print_chat, "%s%s currently has this block in their group!", gszPrefix, szName);
				}
			}
		}
	}
}

bool:rotateBlock(ent)
{
	//if entity is valid
	if (is_valid_ent(ent))
	{
		//get block type
		new blockType = entity_get_int(ent, EV_INT_body);
		
		//if block is a type that can be rotated (a block without a sprite, makes it easier!)
		if (isBlockTypeRotatable(blockType))
		{
			new Float:vAngles[3]; 
			new Float:vSizeMin[3];
			new Float:vSizeMax[3];
			new Float:fTemp;
			
			//get block information
			entity_get_vector(ent, EV_VEC_angles, vAngles);
			entity_get_vector(ent, EV_VEC_mins, vSizeMin);
			entity_get_vector(ent, EV_VEC_maxs, vSizeMax);
			
			//create new block using current block information with new angles and sizes
			if (vAngles[0] == 0.0 && vAngles[2] == 0.0)
			{
				vAngles[0] = 90.0;
			}
			else if (vAngles[0] == 90.0 && vAngles[2] == 0.0)
			{
				vAngles[0] = 90.0;
				vAngles[2] = 90.0;
			}
			else
			{ 
				vAngles = gfDefaultBlockAngles;
			}
			
			//shift vector values along
			fTemp = vSizeMin[0];
			vSizeMin[0] = vSizeMin[2];
			vSizeMin[2] = vSizeMin[1];
			vSizeMin[1] = fTemp;
			
			fTemp = vSizeMax[0];
			vSizeMax[0] = vSizeMax[2];
			vSizeMax[2] = vSizeMax[1];
			vSizeMax[1] = fTemp;
			
			//set the blocks new angle
			entity_set_vector(ent, EV_VEC_angles, vAngles);
			
			//set the blocks new size
			entity_set_size(ent, vSizeMin, vSizeMax);
			
			return true;
		}
	}
	
	return false;
}

copyBlock(ent)
{
	//if entity is valid
	if (is_valid_ent(ent))
	{
		new Float:vOrigin[3];
		new Float:vAngles[3];
		new Float:vSizeMin[3];
		new Float:vSizeMax[3];
		new Float:fMax;
		new blockType;
		new size;
		new axis;
		
		//get blocktype and origin of currently grabbed block
		blockType = entity_get_int(ent, EV_INT_body);
		entity_get_vector(ent, EV_VEC_origin, vOrigin);
		entity_get_vector(ent, EV_VEC_angles, vAngles);
		entity_get_vector(ent, EV_VEC_mins, vSizeMin);
		entity_get_vector(ent, EV_VEC_maxs, vSizeMax);
		
		//work out the block size
		size = SMALL;
		fMax = vSizeMax[0] + vSizeMax[1] + vSizeMax[2];
		if (fMax > 64.0) size = NORMAL;
		if (fMax > 128.0) size = LARGE;
		
		//work out the axis orientation
		for (new i = 0; i < 3; ++i)
		{
			if (vSizeMax[i] == 4.0)
			{
				axis = i;
				break;
			}
		}
		
		//create a block of the same type in the same location
		return createBlock(0, blockType, vOrigin, axis, size);
	}
	
	return 0;
}

set_block_rendering(ent, type, red, green, blue, alpha)
{
	if (isBlock(ent))
	{
		switch (type)
		{
			case GLOWSHELL: set_rendering(ent, kRenderFxGlowShell, red, green, blue, kRenderNormal, alpha);
			case TRANSCOLOR: set_rendering(ent, kRenderFxGlowShell, red, green, blue, kRenderTransColor, alpha);
			case TRANSALPHA: set_rendering(ent, kRenderFxNone, red, green, blue, kRenderTransColor, alpha);
			case TRANSWHITE: set_rendering(ent, kRenderFxNone, red, green, blue, kRenderTransAdd, alpha);
			default: set_rendering(ent, kRenderFxNone, red, green, blue, kRenderNormal, alpha);
		}
	}
}

/* BLOCK TESTS */
bool:isBlockInGroup(id, ent)
{
	//is entity valid
	if (is_valid_ent(ent))
	{
		//get player who has this block in their group (if anyone)
		new player = entity_get_int(ent, EV_INT_iuser1);
		
		if (player == id)
		{
			return true;
		}
	}
	
	return false;
}

bool:isBlockTypeRotatable(blockType)
{
	if (blockType != BM_FIRE && blockType != BM_TRAMPOLINE && blockType != BM_SPEEDBOOST)
	{
		return true;
	}
	
	return false;
}

bool:isBlock(ent)
{
	//is it a valid entity
	if (is_valid_ent(ent))
	{
		//get classname of entity
		new szClassname[32];
		entity_get_string(ent, EV_SZ_classname, szClassname, 32);
		
		//if classname of entity matches global block classname
		if (equal(szClassname, gszBlockClassname) || equal(szClassname, "bcm"))
		{
			//entity is a block
			return true;
		}
	}
	
	//entity is not a block
	return false;
}

bool:isTimer(ent)
{
	//is it a valid entity
	if (is_valid_ent(ent))
	{
		//get classname of entity
		new szClassname[32];
		entity_get_string(ent, EV_SZ_classname, szClassname, 32);
		
		//if classname of entity matches global timer classname
		if (equal(szClassname, gszTimerClassname))
		{
			//entity is a timer
			return true;
		}
	}
	
	//entity is not a timer
	return false;
}

bool:isBlockStuck(ent)
{
	//first make sure the entity is valid
	if (is_valid_ent(ent))
	{
		new content;
		new Float:vOrigin[3];
		new Float:vPoint[3];
		new Float:fSizeMin[3];
		new Float:fSizeMax[3];
		
		//get the size of the block being grabbed
		entity_get_vector(ent, EV_VEC_mins, fSizeMin);
		entity_get_vector(ent, EV_VEC_maxs, fSizeMax);
		
		//get the origin of the block
		entity_get_vector(ent, EV_VEC_origin, vOrigin);
		
		//decrease the size values of the block
		fSizeMin[0] += 1.0;
		fSizeMax[0] -= 1.0;
		fSizeMin[1] += 1.0;
		fSizeMax[1] -= 1.0; 
		fSizeMin[2] += 1.0;
		fSizeMax[2] -= 1.0;
		
		//get the contents of the centre of all 6 faces of the block
		for (new i = 0; i < 14; ++i)
		{
			//start by setting the point to the origin of the block (the middle)
			vPoint = vOrigin;
			
			//set the values depending on the loop number
			switch (i)
			{
				//corners
				case 0: { vPoint[0] += fSizeMax[0]; vPoint[1] += fSizeMax[1]; vPoint[2] += fSizeMax[2]; }
				case 1: { vPoint[0] += fSizeMin[0]; vPoint[1] += fSizeMax[1]; vPoint[2] += fSizeMax[2]; }
				case 2: { vPoint[0] += fSizeMax[0]; vPoint[1] += fSizeMin[1]; vPoint[2] += fSizeMax[2]; }
				case 3: { vPoint[0] += fSizeMin[0]; vPoint[1] += fSizeMin[1]; vPoint[2] += fSizeMax[2]; }
				case 4: { vPoint[0] += fSizeMax[0]; vPoint[1] += fSizeMax[1]; vPoint[2] += fSizeMin[2]; }
				case 5: { vPoint[0] += fSizeMin[0]; vPoint[1] += fSizeMax[1]; vPoint[2] += fSizeMin[2]; }
				case 6: { vPoint[0] += fSizeMax[0]; vPoint[1] += fSizeMin[1]; vPoint[2] += fSizeMin[2]; }
				case 7: { vPoint[0] += fSizeMin[0]; vPoint[1] += fSizeMin[1]; vPoint[2] += fSizeMin[2]; }
				
				//centre of faces
				case 8: { vPoint[0] += fSizeMax[0]; }
				case 9: { vPoint[0] += fSizeMin[0]; }
				case 10: { vPoint[1] += fSizeMax[1]; }
				case 11: { vPoint[1] += fSizeMin[1]; }
				case 12: { vPoint[2] += fSizeMax[2]; }
				case 13: { vPoint[2] += fSizeMin[2]; }
			}
			
			//get the contents of the point on the block
			content = point_contents(vPoint);
			
			//if the point is out in the open
			if (content == CONTENTS_EMPTY || content == 0)
			{
				//block is not stuck
				return false;
			}
		}
	}
	else
	{
		//entity is invalid but don't say its stuck
		return false;
	}
	
	//block is stuck
	return true;
}

bool:isTeleport(ent)
{
	if (is_valid_ent(ent))
	{
		//get classname of entity
		new szClassname[32];
		entity_get_string(ent, EV_SZ_classname, szClassname, 32);
		
		//compare classnames
		if (equal(szClassname, gszTeleportStartClassname) || equal(szClassname, gszTeleportEndClassname))
		{
			//entity is a teleport
			return true;
		}
	}
	
	//entity is not a teleport
	return false;
}

doSnapping(id, ent, Float:fMoveTo[3])
{
	//if player has snapping enabled
	if (gbSnapping[id])
	{
		new Float:fSnapSize = gfSnapDistance + gfSnappingGap[id];
		new Float:vReturn[3];
		new Float:dist;
		new Float:distOld = 9999.9;
		new Float:vTraceStart[3];
		new Float:vTraceEnd[3];
		new tr;
		new trClosest = 0;
		new blockFace;
		
		//get the size of the block being grabbed
		new Float:fSizeMin[3];
		new Float:fSizeMax[3];
		entity_get_vector(ent, EV_VEC_mins, fSizeMin);
		entity_get_vector(ent, EV_VEC_maxs, fSizeMax);
		
		//do 6 traces out from each face of the block
		for (new i = 0; i < 6; ++i)
		{
			//setup the start of the trace
			vTraceStart = fMoveTo;
			
			switch (i)
			{
				case 0: vTraceStart[0] += fSizeMin[0];		//edge of block on -X
				case 1: vTraceStart[0] += fSizeMax[0];		//edge of block on +X
				case 2: vTraceStart[1] += fSizeMin[1];		//edge of block on -Y
				case 3: vTraceStart[1] += fSizeMax[1];		//edge of block on +Y
				case 4: vTraceStart[2] += fSizeMin[2];		//edge of block on -Z
				case 5: vTraceStart[2] += fSizeMax[2];		//edge of block on +Z
			}
			
			//setup the end of the trace
			vTraceEnd = vTraceStart;
			
			switch (i)
			{
				case 0: vTraceEnd[0] -= fSnapSize;
				case 1: vTraceEnd[0] += fSnapSize;
				case 2: vTraceEnd[1] -= fSnapSize;
				case 3: vTraceEnd[1] += fSnapSize;
				case 4: vTraceEnd[2] -= fSnapSize;
				case 5: vTraceEnd[2] += fSnapSize;
			}
			
			//trace a line out from one of the block faces
			tr = trace_line(ent, vTraceStart, vTraceEnd, vReturn);
			
			//if the trace found a block and block is not in group or block to snap to is not in group
			if (isBlock(tr) && (!isBlockInGroup(id, tr) || !isBlockInGroup(id, ent)))
			{
				//get the distance from the grabbed block to the found block
				dist = get_distance_f(vTraceStart, vReturn);
				
				//if distance to found block is less than the previous block
				if (dist < distOld)
				{
					trClosest = tr;
					distOld = dist;
					
					//save the block face where the trace came from
					blockFace = i;
				}
			}
		}
		
		//if there is a block within the snapping range
		if (is_valid_ent(trClosest))
		{
			//get origin of closest block
			new Float:vOrigin[3];
			entity_get_vector(trClosest, EV_VEC_origin, vOrigin);
			
			//get sizes of closest block
			new Float:fTrSizeMin[3];
			new Float:fTrSizeMax[3];
			entity_get_vector(trClosest, EV_VEC_mins, fTrSizeMin);
			entity_get_vector(trClosest, EV_VEC_maxs, fTrSizeMax);
			
			//move the subject block to the origin of the closest block
			fMoveTo = vOrigin;
			
			//offset the block to be on the side where the trace hit the closest block
			if (blockFace == 0) fMoveTo[0] += (fTrSizeMax[0] + fSizeMax[0]) + gfSnappingGap[id];
			if (blockFace == 1) fMoveTo[0] += (fTrSizeMin[0] + fSizeMin[0]) - gfSnappingGap[id];
			if (blockFace == 2) fMoveTo[1] += (fTrSizeMax[1] + fSizeMax[1]) + gfSnappingGap[id];
			if (blockFace == 3) fMoveTo[1] += (fTrSizeMin[1] + fSizeMin[1]) - gfSnappingGap[id];
			if (blockFace == 4) fMoveTo[2] += (fTrSizeMax[2] + fSizeMax[2]) + gfSnappingGap[id];
			if (blockFace == 5) fMoveTo[2] += (fTrSizeMin[2] + fSizeMin[2]) - gfSnappingGap[id];
		}
	}
}

/***** FILE HANDLING *****/
saveBlocks(id)
{
	//make sure player has access to this command
	if (get_user_flags(id) & BM_ADMIN_LEVEL)
	{
		new file = fopen(gszNewFile, "wt");
		new ent = -1;
		new blockType;
		new Float:vOrigin[3];
		new Float:vAngles[3];
		new Float:vStart[3];
		new Float:vEnd[3];
		new blockCount = 0;
		new teleCount = 0;
		new timerCount = 0;
		new szData[128];
		new Float:fMax;
		new size;
		new Float:vSizeMax[3];
		
		while ((ent = find_ent_by_class(ent, gszBlockClassname)))
		{
			//get block info
			blockType = entity_get_int(ent, EV_INT_body);
			entity_get_vector(ent, EV_VEC_origin, vOrigin);
			entity_get_vector(ent, EV_VEC_angles, vAngles);
			entity_get_vector(ent, EV_VEC_maxs, vSizeMax);
			
			size = SMALL;
			fMax = vSizeMax[0] + vSizeMax[1] + vSizeMax[2];
			if (fMax > 64.0) size = NORMAL;
			if (fMax > 128.0) size = LARGE;
			
			//format block info and save it to file
			formatex(szData, 128, "%c %f %f %f %f %f %f %d^n", gBlockSaveIds[blockType], vOrigin[0], vOrigin[1], vOrigin[2], vAngles[0], vAngles[1], vAngles[2], size);
			fputs(file, szData);
			
			//increment block count
			++blockCount;
		}
		
		//iterate through teleport end entities because you can't have an end without a start
		ent = -1;
		
		while ((ent = find_ent_by_class(ent, gszTeleportEndClassname)))
		{
			//get the id of the start of the teleporter
			new tele = entity_get_int(ent, EV_INT_iuser1);
			
			//check that start of teleport is a valid entity
			if (tele)
			{
				//get the origin of the start of the teleport and save it to file
				entity_get_vector(tele, EV_VEC_origin, vStart);
				entity_get_vector(ent, EV_VEC_origin, vEnd);
				
				formatex(szData, 128, "%c %f %f %f %f %f %f^n", gTeleportSaveId, vStart[0], vStart[1], vStart[2], vEnd[0], vEnd[1], vEnd[2]);
				fputs(file, szData);
				
				//2 teleport entities count as 1 teleporter
				++teleCount;
			}
		}
		
		//iterate through timer end entities because you can't have an end without a start
		ent = -1;
		
		while ((ent = find_ent_by_class(ent, gszTimerClassname)))
		{
			//get the type of timer
			new timerType = entity_get_int(ent, EV_INT_body);
			
			//timer type must be an end
			if (timerType == TIMER_END)
			{
				//get the id of the start of the timer
				new timer = entity_get_int(ent, EV_INT_iuser1);
				
				//check that start of timer is a valid entity
				if (timer)
				{
					//get the origin of the start of the timer and its angles
					entity_get_vector(timer, EV_VEC_origin, vStart);
					entity_get_vector(timer, EV_VEC_angles, vAngles);
					
					//save the start timer information to file
					formatex(szData, 128, "%c %f %f %f %f %f %f^n", gTimerSaveId, vStart[0], vStart[1], vStart[2], vAngles[0], vAngles[1], vAngles[2]);
					fputs(file, szData);
					
					//get the origin of the end of the timer and its angles
					entity_get_vector(ent, EV_VEC_origin, vEnd);
					entity_get_vector(ent, EV_VEC_angles, vAngles);
					
					//save the end timer information to file
					formatex(szData, 128, "%c %f %f %f %f %f %f^n", gTimerSaveId, vEnd[0], vEnd[1], vEnd[2], vAngles[0], vAngles[1], vAngles[2]);
					fputs(file, szData);
					
					//2 timer entities count as 1 timer
					++timerCount;
				}
			}
		}
		
		//get players name
		new szName[32];
		get_user_name(id, szName, 32);
		
		//notify all admins that the player saved blocks to file
		for (new i = 1; i <= 32; ++i)
		{
			//make sure player is connected
			if (is_user_connected(i))
			{
				if (get_user_flags(i) & BM_ADMIN_LEVEL)
				{
					client_print(i, print_chat, "%s'%s' saved %d block%s, %d teleporter%s and %d timer%s! Total entites in map: %d", gszPrefix, szName, blockCount, (blockCount == 1 ? "" : "s"), teleCount, (teleCount == 1 ? "" : "s"), timerCount, (timerCount == 1 ? "" : "s"), entity_count());
				}
			}
		}
		
		//close file
		fclose(file);
	}
}

loadBlocks(id)
{
	new bool:bAccess = false;
	
	//if this function was called on map load, ID is 0
	if (id == 0)
	{
		bAccess = true;
	}
	//make sure user calling this function has access
	else if (get_user_flags(id) & BM_ADMIN_LEVEL)
	{
		bAccess = true;
	}
	
	if (bAccess)
	{
		//if map file exists
		if (file_exists(gszNewFile))
		{
			//if a player is loading then first delete all the old blocks, teleports and timers
			if (id > 0 && id <= 32)
			{
				deleteAllBlocks(id, false);
				deleteAllTeleports(id, false);
				deleteAllTimers(id, false);
			}
			
			new szData[128];
			new szType[2];
			new sz1[16], sz2[16], sz3[16], sz4[16], sz5[16], sz6[16], sz7[16];
			new Float:vVec1[3];
			new Float:vVec2[3];
			new axis;
			new size;
			new f = fopen(gszNewFile, "rt");
			new blockCount = 0;
			new teleCount = 0;
			new timerCount = 0;
			new bool:bTimerStart = true;
			new Float:vTimerOrigin[3];
			new Float:vTimerAngles[3];
			
			//iterate through all the lines in the file
			while (!feof(f))
			{
				szType = "";
				fgets(f, szData, 128);
				parse(szData, szType, 1, sz1, 16, sz2, 16, sz3, 16, sz4, 16, sz5, 16, sz6, 16, sz7, 16);
				
				vVec1[0] = str_to_float(sz1);
				vVec1[1] = str_to_float(sz2);
				vVec1[2] = str_to_float(sz3);
				vVec2[0] = str_to_float(sz4);
				vVec2[1] = str_to_float(sz5);
				vVec2[2] = str_to_float(sz6);
				size = str_to_num(sz7);
				
				if (strlen(szType) > 0)
				{
					//if type is not a teleport
					if (szType[0] != gTeleportSaveId)
					{
						//set axis orientation depending on block angles
						if (vVec2[0] == 90.0 && vVec2[1] == 0.0 && vVec2[2] == 0.0)
						{
							axis = X;
						}
						else if (vVec2[0] == 90.0 && vVec2[1] == 0.0 && vVec2[2] == 90.0)
						{
							axis = Y;
						}
						else
						{
							axis = Z;
						}
						
						//increment block counter
						++blockCount;
					}
					
					//create block or teleport depending on type
					switch (szType[0])
					{
						case 'A': createBlock(0, BM_PLATFORM, vVec1, axis, size);
						case 'B': createBlock(0, BM_BHOP, vVec1, axis, size);
						case 'C': createBlock(0, BM_DAMAGE, vVec1, axis, size);
						case 'D': createBlock(0, BM_HEALER, vVec1, axis, size);
						case 'E': createBlock(0, BM_INVINCIBILITY, vVec1, axis, size);
						case 'F': createBlock(0, BM_STEALTH, vVec1, axis, size);
						case 'G': createBlock(0, BM_TRAMPOLINE, vVec1, axis, size);
						case 'H': createBlock(0, BM_SPEEDBOOST, vVec1, axis, size);
						case 'I': createBlock(0, BM_NOFALLDAMAGE, vVec1, axis, size);
						case 'J': createBlock(0, BM_ICE, vVec1, axis, size);
						case 'K': createBlock(0, BM_DEATH, vVec1, axis, size);
						case 'L': createBlock(0, BM_NUKE, vVec1, axis, size);
						case 'M': createBlock(0, BM_CAMOUFLAGE, vVec1, axis, size);
						case 'N': createBlock(0, BM_LOWGRAVITY, vVec1, axis, size);
						case 'O': createBlock(0, BM_FIRE, vVec1, axis, size);
						case 'P': createBlock(0, BM_SLAP, vVec1, axis, size);
						case 'Q': createBlock(0, BM_RANDOM, vVec1, axis, size);
						case 'R': createBlock(0, BM_HONEY, vVec1, axis, size);
						case 'S': createBlock(0, BM_BARRIER_CT, vVec1, axis, size);
						case 'T': createBlock(0, BM_BARRIER_T, vVec1, axis, size);
						case 'U': createBlock(0, BM_BOOTSOFSPEED, vVec1, axis, size);
						case 'V': createBlock(0, BM_GLASS, vVec1, axis, size);
						case 'W': createBlock(0, BM_BHOP_NOSLOW, vVec1, axis, size);
						case 'X': createBlock(0, BM_AUTO_BHOP, vVec1, axis, size);
						
						case gTeleportSaveId:
						{
							createTeleport(0, TELEPORT_START, vVec1);
							createTeleport(0, TELEPORT_END, vVec2);
							
							//increment teleport count
							++teleCount;
						}
						
						case gTimerSaveId:
						{
							//is this the first timer info retrieved from file?
							if (bTimerStart)
							{
								//store start timer info
								vTimerOrigin[0] = vVec1[0];
								vTimerOrigin[1] = vVec1[1];
								vTimerOrigin[2] = vVec1[2];
								vTimerAngles[0] = vVec2[0];
								vTimerAngles[1] = vVec2[1];
								vTimerAngles[2] = vVec2[2];
								
								//the next timer to come along is the end of the timer
								bTimerStart = false;
							}
							else
							{
								//create the start of timer
								createTimer(0, TIMER_START, vTimerOrigin, vTimerAngles);
								
								//create the end of the timer
								createTimer(0, TIMER_END, vVec1, vVec2);
								
								//if another timer comes along then it'll be the start again
								bTimerStart = true;
								
								//increment timer count
								++timerCount;
							}
						}
						
						default:
						{
							log_amx("%sInvalid block type: %c in: %s", gszPrefix, szType[0], gszFile);
							
							//decrement block counter because a block was not created
							--blockCount;
						}
					}
				}
			}
			
			fclose(f);
			
			//if a player is loading the blocks
			if (id > 0 && id <= 32)
			{
				//get players name
				new szName[32];
				get_user_name(id, szName, 32);
				
				//notify all admins that the player loaded blocks from file
				for (new i = 1; i <= 32; ++i)
				{
					//make sure player is connected
					if (is_user_connected(i))
					{
						if (get_user_flags(i) & BM_ADMIN_LEVEL)
						{
							client_print(i, print_chat, "%s'%s' loaded %d block%s, %d teleporter%s and %d timer%s! Total entites in map: %d", gszPrefix, szName, blockCount, (blockCount == 1 ? "" : "s"), teleCount, (teleCount == 1 ? "" : "s"), timerCount, (timerCount == 1 ? "" : "s"), entity_count());
						}
					}
				}
			}
		}
		else
		{
			//if a player is loading the blocks
			if (id > 0 && id <= 32)
			{
				//notify player that the file could not be found
				client_print(id, print_chat, "%sCouldn't find file: %s", gszPrefix, gszNewFile);
			}
		}
	}
}

/* MISC */
drawLine(Float:vOrigin1[3], Float:vOrigin2[3], life)
{
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY);
	write_byte(TE_BEAMPOINTS);
	write_coord(floatround(vOrigin1[0], floatround_floor));
	write_coord(floatround(vOrigin1[1], floatround_floor));
	write_coord(floatround(vOrigin1[2], floatround_floor));
	write_coord(floatround(vOrigin2[0], floatround_floor));
	write_coord(floatround(vOrigin2[1], floatround_floor));
	write_coord(floatround(vOrigin2[2], floatround_floor));
	write_short(gSpriteIdBeam);		//sprite index
	write_byte(0);				//starting frame
	write_byte(1);				//frame rate in 0.1's
	write_byte(life);			//life in 0.1's
	write_byte(5);				//line width in 0.1's
	write_byte(0);				//noise amplitude in 0.01's
	write_byte(255);			//red
	write_byte(255);			//green
	write_byte(255);			//blue
	write_byte(255);			//brightness
	write_byte(0);				//scroll speed in 0.1's
	message_end();
}

htmlFriendly(szString[])
{
	//replace < > in string with HTML friendly characters
	while (contain(szString, "<") != -1)
	{
		replace(szString, 2048, "<", "&lt");
	}
	
	while (contain(szString, ">") != -1)
	{
		replace(szString, 2048, ">", "&gt");
	}
}

bool:getFileContents(szFilename[], szContents[])
{
	new size = file_size(szFilename, 0);
	new line = 0;
	new length = 0;
	new pos;
	new szData[128];
	
	if (size > 0)
	{
		do
		{
			line = read_file(szFilename, line, szData, size, length);
			
			if (line != 0)
			{
				pos += format(szContents[pos], 511 - pos, szData);
			}
		
		}while (line != 0);
		
		return true;
	}
	
	return false;
}
