// SuperHero Constants Include File
// Version 1.2.0

#if defined _sheroconst_included
  #endinput
#endif
#define _sheroconst_included

//----------------------------------------------------------------------------------------------
// Changeable DEFINE Settings, must recompile SuperHero plugins if changed
//----------------------------------------------------------------------------------------------

// Max levels that can be loaded from the superhero.ini
#define SH_MAXLEVELS 80

// Max Amount of heros that can be loaded
#define SH_MAXHEROS 80

// Potential of power1-power9 but limited by sh_maxbinds (3 default)
#define SH_MAXBINDPOWERS 9

// Comment out for new optimized coding only, old coded heroes will break
#define SH_BACKCOMPAT

//----------------------------------------------------------------------------------------------
// DO NOT EDIT BELOW HERE
//----------------------------------------------------------------------------------------------

#define SH_VERSION		1.20
stock const SH_VERSION_STR[] =	"1.2.0.14";

// Cooldown task id, required to allow core to stop task
#define SH_COOLDOWN_TASKID	572910

// Max player slots
#define SH_MAXSLOTS		32

// sh_hero_init(id, heroID, mode) modes
#define SH_HERO_DROP		0	//Hero is dropped
#define SH_HERO_ADD		1	//Hero is added

// sh_hero_key(id, heroID, key) keys
#define SH_KEYUP		0	//Power Key is released
#define SH_KEYDOWN		1	//Power Key is pressed

// sh_extra_damage() damage types
#define SH_DMG_MULT		0	// Multipiler damage, armor will not reduce damage hit points (armor is still reduced)
#define SH_DMG_NORM		1	// Normal damage, armor will reduce damage hit points
#define SH_DMG_KILL		2	// Kill damage, instantly kills if damage is possible (Note: godmode can block this)

// From HLSDK for sh_screenfade
#define SH_FFADE_IN		0x0000	// Just here so we don't pass 0 into the function
#define SH_FFADE_OUT		0x0001	// Fade out (not in)
#define SH_FFADE_MODULATE	0x0002	// Modulate (don't blend)
#define SH_FFADE_STAYOUT	0x0004	// Ignores the duration, stays faded out until new ScreenFade message received

// User Flags, saved with XP data
#define SH_FLAG_HUDHELP		(1<<0)	/* flag "a" */	// Enable the Help HUD
#define SH_FLAG_NOAUTOMENU	(1<<1)	/* flag "b" */	// Do not show menu automatically on spawn
#define SH_FLAG_XPIMMUNE	(1<<2)	/* flag "c" */	// Immue to xp reset from savedays. (Not available for nVault)
#define SH_FLAG_BANNED		(1<<3)	/* flag "d" */	// Flag user banned from having hereos (not used, if used would have to keep info stored and will not work with nVault)

// VIP Flags, set with sh_blockvip CVAR
#define VIP_BLOCK_POWERKEYS	(1<<0)	/* flag "a" */	// VIP blocked from using power keys
#define VIP_BLOCK_WEAPONS	(1<<1)	/* flag "b" */	// VIP blocked from receiving weapons thru sh
#define VIP_BLOCK_HEALTH	(1<<2)	/* flag "c" */	// VIP blocked from receiving health thru sh
#define VIP_BLOCK_ARMOR		(1<<3)	/* flag "d" */	// VIP blocked from receiving armor thru sh
#define VIP_BLOCK_SPEED		(1<<4)	/* flag "e" */	// VIP blocked from receiving speed thru sh
#define VIP_BLOCK_GRAVITY	(1<<5)	/* flag "f" */	// VIP blocked from receiving gravity thru sh
#define VIP_BLOCK_EXTRADMG	(1<<6)	/* flag "g" */	// VIP blocked from using sh_extra_damage
#define VIP_BLOCK_CUSTOM	(1<<7)	/* flag "h" */	// Custom VIP block, heroes can use for whatever they want

// From multiplayer/dlls/player.cpp (Note: Actual CS calculation is unknown)
#define SH_ARMOR_RATIO		0.5	// Armor Takes 50% of the damage (0.2 in the HL SDK)
#define SH_ARMOR_BONUS		0.5	// Each Point of Armor is worth 1/x points of health (0.5 in the HL SDK)

// Common sound for denying power use, precached by core
stock const gSoundDeny[] = 	"common/wpn_denyselect.wav";

//------------
// Weapon look up tables
//------------
// usage: sh_get_max_bpammo(weaponID)
#define sh_get_max_bpammo(%1) gMaxBPAmmo[%1]
stock gMaxBPAmmo[] = {
	0,
	52,	//CSW_P228
	0,
	90,	//CSW_SCOUT
	1,	//CSW_HEGRENADE
	32,	//CSW_XM1014
	1,	//CSW_C4
	100,	//CSW_MAC10
	90,	//CSW_AUG
	1,	//CSW_SMOKEGRENADE
	120,	//CSW_ELITE
	100,	//CSW_FIVESEVEN
	100,	//CSW_UMP45
	90,	//CSW_SG550
	90,	//CSW_GALIL
	90,	//CSW_FAMAS
	100,	//CSW_USP
	120,	//CSW_GLOCK18
	30,	//CSW_AWP
	120,	//CSW_MP5NAVY
	200,	//CSW_M249
	32,	//CSW_M3
	90,	//CSW_M4A1
	120,	//CSW_TMP
	90,	//CSW_G3SG1
	2,	//CSW_FLASHBANG
	35,	//CSW_DEAGLE
	90,	//CSW_SG552
	90,	//CSW_AK47
	0,	//CSW_KNIFE
	100	//CSW_P90
};
// usage: sh_get_max_clipammo(weaponID)
#define sh_get_max_clipammo(%1) gMaxClipAmmo[%1]
stock gMaxClipAmmo[] = {
	0,
	13,	//CSW_P228
	0,
	10,	//CSW_SCOUT
	0,	//CSW_HEGRENADE
	7,	//CSW_XM1014
	0,	//CSW_C4
	30,	//CSW_MAC10
	30,	//CSW_AUG
	0,	//CSW_SMOKEGRENADE
	30,	//CSW_ELITE
	20,	//CSW_FIVESEVEN
	25,	//CSW_UMP45
	30,	//CSW_SG550
	35,	//CSW_GALIL
	25,	//CSW_FAMAS
	12,	//CSW_USP
	20,	//CSW_GLOCK18
	10,	//CSW_AWP
	30,	//CSW_MP5NAVY
	100,	//CSW_M249
	8,	//CSW_M3
	30,	//CSW_M4A1
	30,	//CSW_TMP
	20,	//CSW_G3SG1
	0,	//CSW_FLASHBANG
	7,	//CSW_DEAGLE
	30,	//CSW_SG552
	30,	//CSW_AK47
	0,	//CSW_KNIFE
	50	//CSW_P90
};
// usage: sh_get_weapon_slot(weaponID)
#define sh_get_weapon_slot(%1) gWeaponSlot[%1]
stock gWeaponSlot[] = {
	0,
	2,	//CSW_P228
	0,
	1,	//CSW_SCOUT
	4,	//CSW_HEGRENADE
	1,	//CSW_XM1014
	5,	//CSW_C4
	1,	//CSW_MAC10
	1,	//CSW_AUG
	4,	//CSW_SMOKEGRENADE
	2,	//CSW_ELITE
	2,	//CSW_FIVESEVEN
	1,	//CSW_UMP45
	1,	//CSW_SG550
	1,	//CSW_GALIL
	1,	//CSW_FAMAS
	2,	//CSW_USP
	2,	//CSW_GLOCK18
	1,	//CSW_AWP
	1,	//CSW_MP5NAVY
	1,	//CSW_M249
	1,	//CSW_M3
	1,	//CSW_M4A1
	1,	//CSW_TMP
	1,	//CSW_G3SG1
	4,	//CSW_FLASHBANG
	2,	//CSW_DEAGLE
	1,	//CSW_SG552
	1,	//CSW_AK47
	3,	//CSW_KNIFE
	1	//CSW_P90
};
// usage: check sh_get_weapon_speed stock in superheromod.inc
// Thanks WC3:FT for weapon speeds so I didn't have to check them
stock Float:gWeaponSpeed[] = {
	0.0,
	250.0,	// CSW_P228
	0.0,
	260.0,	// CSW_SCOUT
	250.0,	// CSW_HEGRENADE
	240.0,	// CSW_XM1014
	250.0,	// CSW_C4
	250.0,	// CSW_MAC10
	240.0,	// CSW_AUG
	250.0,	// CSW_SMOKEGRENADE
	250.0,	// CSW_ELITE
	250.0,	// CSW_FIVESEVEN
	250.0,	// CSW_UMP45
	210.0,	// CSW_SG550
	240.0,	// CSW_GALI
	240.0,	// CSW_FAMAS
	250.0,	// CSW_USP
	250.0,	// CSW_GLOCK18
	210.0,	// CSW_AWP
	250.0,	// CSW_MP5NAVY
	220.0,	// CSW_M249
	230.0,	// CSW_M3
	230.0,	// CSW_M4A1
	250.0,	// CSW_TMP
	210.0,	// CSW_G3SG1
	250.0,	// CSW_FLASHBANG
	250.0,	// CSW_DEAGLE
	235.0,	// CSW_SG552
	221.0,	// CSW_AK47
	250.0,	// CSW_KNIFE
	245.0	// CSW_P90
};