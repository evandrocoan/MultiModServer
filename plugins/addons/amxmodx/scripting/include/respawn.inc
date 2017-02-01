/**
 * (C)2006 teame06
 * Respawn Controller
 */

#if defined _respawn_included
  #endinput
#endif
#define _respawn_included

#pragma library respawn

#define FRAMEWAIT 2.0
#define SLOT_PRIMARY 1
#define SLOT_SECONDARY 2
#define SLOT_C4 4

/* Forwards */

// Called when the round starts.
forward RoundStart();

// Called when round ended.
forward RoundEnd();

// Called when a player is killed
forward DeathMessage(Killer, Victim, HeadShot, WeaponName[]);

/* Called before a player is spawn.
a return PLUGIN_HANDLED stop the spawn. */
forward PreSpawn(player);

// Called when a player is spawned
forward PostSpawn(player);

/* Natives */
/* Forces a spawn on a player */
native spawn_player(player);

//Weapon slot lookup table
stock g_WeaponSlots[] = {
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