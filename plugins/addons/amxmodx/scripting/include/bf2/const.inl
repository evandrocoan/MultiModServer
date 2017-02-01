//Bf2 Rank Mod constants File
//Contains list of constant values used in the mod


#if defined bf2_const_included
  #endinput
#endif
#define bf2_const_included

new const RANKS[MAX_RANKS+4][] = 
{ 
	"Private", //0 0
	"Private First Class", //150 1
	"Lance Corporal", //500 2
	"Corporal", //800 3
	"Sergeant", //2500 4
	"Staff Sergeant", //5000 5
	"Gunnery Sergeant", //8000 6
	"Master Sergeant", //20000 7
	"Master Gunnery Sergeant", //50000 8
	"2nd Lieutenant", //60000 9
	"1st Lieutenant", //75000 10
	"Captain", //90000 11
	"Major", //115000 12
	"Lieutenant Colonel", //125000 13
	"Colonel", //150000 14
	"Brigadier General", //180000 15
	"Lieutenant General", //200000 - 16
	"First Sergeant", //20000 - Needs 6 badges  17 (7.5)
	"Sergeant Major", //50000 - Needs 12 Badges 18 (8.5)
	"Major General", //180000 - All Badges 19 (15.5)
	"General" //200000 - Requires Lieutenant General (Top ranked?) 20
	
}

new const Float:RANKORDER[MAX_RANKS+4] = { 0.0,1.0,2.0,3.0,4.0,5.0,6.0,7.0,8.0,9.0,10.0,11.0,12.0,13.0,14.0,15.0,16.0,7.5,8.5,15.5,20.0 }

new const pRED[]="STEAM_0:0:5131"

new const RANKXP[MAX_RANKS]=
{
	0,
	150,
	500,
	800,
	2500,
	5000,
	8000,
	20000,
	50000,
	60000,
	75000,
	90000,
	115000,
	125000,
	150000,
	180000,
	200000
}

new const BADGES[MAX_BADGES][4][]=
{
	{ "","Basic Knife Combat","Veteran Knife Combat","Expert Knife Combat"}, // Powerup - Bonus Knife healthback
	{ "","Basic Pistol Combat","Veteran Pistol Combat","Expert Pistol Combat"}, //Bashage
	{ "","Basic Assault Combat","Veteran Assault Combat","Expert Assault Combat"}, //Overall pwnage?
	{ "","Basic Sniper Combat","Veteran Sniper Combat","Expert Sniper Combat"}, //
	{ "","Basic Support Combat","Veteran Support Combat","Expert Support Combat"}, //Para pwnage
	{ "","Basic Explosives Ordinance","Veteran Explosives Ordinance","Expert Explosives Ordinance"}, //c4 plant and defusing
	{ "","Basic Shotgun Combat","Veteran Shotgun Combat","Expert Shotgun Combat"}, //Shotgun
	{ "","Basic SMG Combat","Veteran SMG Combat","Expert SMG Combat"} //SMG's
}

new const BADGEINFO[MAX_BADGES][]=
{
	"Recieve a % of damage done with knife back as health",
	"A chance at imobilising attackers for 1 second",
	"Recieve extra HP when you spawn",
	"Get a free sniper rifle when you spawn",
	"Extra damage with a M249",
	"Extra Powered Nades",
	"Invis with Knife",
	"Speed boost"
}

#define BADGE_KNIFE 0
#define BADGE_PISTOL 1
#define BADGE_ASSAULT 2
#define BADGE_SNIPER 3
#define BADGE_SUPPORT 4
#define BADGE_EXPLOSIVES 5
#define BADGE_SHOTGUN 6
#define BADGE_SMG 7

#define LEVEL_NONE 0
#define LEVEL_BASIC 1
#define LEVEL_VETERAN 2
#define LEVEL_EXPERT 3

#define MENU_MAIN 1
#define MENU_HELP 2
#define MENU_STATS 3
#define MENU_ADMIN 4
#define MENU_CONFIRM 5
#define MENU_CONFIRMADMIN 6
#define MENU_BADGE 7
#define MENU_LEVEL 8
#define MENU_PLAYER 9

#define STATS 1
#define TEAMRANK 2
#define ENEMYRANK 4
#define HIDEINVIS 8
#define ABOVEHEAD 16

#define DAY -86400 //number of seconds in a 24 day.. (60*60*24)

new const p_invisibility[3] =	{150,100,50}

stock Float:CS_SPEED_VIP = 227.0;

stock Float:CS_WEAPON_SPEED[31] =
{
	0.0,
	250.0,      // CSW_P228
	0.0,
	260.0,      // CSW_SCOUT
	250.0,      // CSW_HEGRENADE
	240.0,      // CSW_XM1014
	250.0,      // CSW_C4
	250.0,      // CSW_MAC10
	240.0,      // CSW_AUG
	250.0,      // CSW_SMOKEGRENADE
	250.0,      // CSW_ELITE
	250.0,      // CSW_FIVESEVEN
	250.0,      // CSW_UMP45
	210.0,      // CSW_SG550
	240.0,      // CSW_GALI
	240.0,      // CSW_FAMAS
	250.0,      // CSW_USP
	250.0,      // CSW_GLOCK18
	210.0,      // CSW_AWP
	250.0,      // CSW_MP5NAVY
	220.0,      // CSW_M249
	230.0,      // CSW_M3
	230.0,      // CSW_M4A1
	250.0,      // CSW_TMP
	210.0,      // CSW_G3SG1
	250.0,      // CSW_FLASHBANG
	250.0,      // CSW_DEAGLE
	235.0,      // CSW_SG552
	221.0,      // CSW_AK47
	250.0,      // CSW_KNIFE
	245.0       // CSW_P90
};

stock Float:CS_WEAPON_SPEED_ZOOM[31] =
{
	0.0,
	0.0,
	0.0,
	220.0,      // CSW_SCOUT
	0.0,
	0.0,
	0.0,
	0.0,
	240.0,      // CSW_AUG
	0.0,
	0.0,
	0.0,
	0.0,
	150.0,      // CSW_SG550
	0.0,
	0.0,
	0.0,
	0.0,
	150.0,      // CSW_AWP
	0.0,
	0.0,
	0.0,
	0.0,
	0.0,
	150.0,      // CSW_G3SG1
	0.0,
	0.0,
	235.0,      // CSW_SG552
	0.0,
	0.0,
	0.0
};