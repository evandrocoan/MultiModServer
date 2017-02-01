
/** *************************************************************************
*** AMXX Plugin:   Ultimate Warcraft3 (UWC3)
*** Plugin Author: K2mia
*** UWC3 Module:   Global Defines 
*** Date:          May 25, 2004
*** Last Update:   September 23, 2004
*
*  Module: Global Defines 
*  All #defines are included in this module.
*----------------------------------------------------------------------------
*
*  UWC3 is written exclusively for AMX Mod X
*
*  Ultimate Warcraft3 Dev. Team
*  ------------------------------
*   Small scripting:  K2mia ( Andrew Cowan ) < admin@mudconnect.com >
*   Graphics:         steve french < garbageweed@hotmail.com >
*   Website Design:   Jim Rhoades < jim@radzone.org >
*
*  str_break() routine provided by BAILOPAN from AMXX0.20 to replace parse()
*  ultimate_decoy() code derived from code for Beyonder superhero (Freecode/Asskicr)
*    some decoy concepts from AMXX forums posts by jjkiller
*
****************************************************************************/

// **************************************************************************
// BEGIN UWC3 Defs
// The following #defines control various aspects of the plugin
// It is not recommended changing anything in this section
// **************************************************************************

#define DEBUG_STARTXP 250000    // If in DEBUG mode, starting XP for players
#define DEBUG_CASH 16000        // If in DEBUG mode, starting Cash for players

#define STEAM_POWERED 1         // Running CS1.6 required for this plugin

#define MAX_PLAYERS 33          // Max number of players in the game
#define MAX_LEVEL 35            // Max level a player can achieve
#define MAX_ULTIMATES 3         // Max # of ultimates trainable by a player
#define MAX_ATTRIBS 6           // Number of attributes is (this-1) (0 slot is unused)
#define MAX_RESISTS 6           // Number of resists is (this-1) (0 slot is unused)
#define MAX_SKILLS 41           // Number of skills is (this-1) (0 slot is unused)
#define MAX_SKILL_LEVEL10 10    // Maximum level this skill can be trained - 10
#define MAX_SKILL_LEVEL5 5      // Maximum level this skill can be trained - 5
#define MAX_SKILL_LEVEL3 3      // Maximum level this skill can be trained - 3
#define MAX_SKILL_LEVEL1 1      // Maximum level this skill can be trained - 1
#define MAX_SKILL_PAGES 5       // Number of pages of skill choices in select_skill()
#define SKILLS_PER_SET 8        // Number of skills displayed per page of selectskill
#define ATTRIB_BASE 10          // The base amount for each player attribute
#define ATTRIB_MAX_VALUE 18     // The Maximum amount for each player attribute
#define ENH_MIN_LEVEL 20        // Default Min. level to start using enhancement XP

#define NOTICE_WAIT_TIME 15     // Time to wait before reminding about skillpoints

#define MONEY_PER_KILL 300	// Amount of money earned per skill-based kill

#define SKILLSET1_LEVEL 0       // Min. level to use these skills
#define SKILLSET2_LEVEL 5       // Min. level to use these skills
#define SKILLSET3_LEVEL 12      // Min. level to use these skills
#define SKILLSET4_LEVEL 16      // Min. level to use these skills

#define XP_PER_LEVEL 1000          // Amount to add for levels after 10 (Fast XP)
#define XP_PER_LEVEL_LT 12800      // Amount to add for levels after 10 (Long term XP)
#define XP_PER_LEVEL_BASE 5500     // Base amount, xp from lvl 10  (Fast XP)
#define XP_PER_LEVEL_BASE_LT 38400 // Base amount, xp from lvl 10 (Long term XP)

#define XP_BASE 60              // Base XP for xp gaining (xpgiven)
#define XP_ADD_LEVEL 20         // Per level xp gain (xpgiven)

// Define the levels for achieving UWC3 Rank titles
#define RANK2_LEVEL 5           // Level needed for 2nd rank
#define RANK3_LEVEL 8           // Level needed for 3rd rank
#define RANK4_LEVEL 12          // Level needed for 4th rank
#define RANK5_LEVEL 16          // Level needed for 5th rank
#define RANK6_LEVEL 20          // Level needed for 6th rank
#define RANK7_LEVEL 24          // Level needed for 7th rank
#define RANK8_LEVEL 28          // Level needed for 8th rank
#define RANK9_LEVEL 30          // Level needed for 9th rank
#define RANK10_LEVEL 32         // Level needed for 10th rank
#define RANK11_LEVEL 34         // Level needed for 11th rank

// Define the UWC3 p_attribs[] index for each attribute
#define ATTRIBIDX_STR 1         // Strength Attribute
#define ATTRIBIDX_INT 2         // Intellect Attribute
#define ATTRIBIDX_DEX 3         // Dexterity Attribute
#define ATTRIBIDX_AGI 4         // Agility Attribute
#define ATTRIBIDX_CON 5         // Constitution Attribute

#define STR_HEALTH_BONUS 5      // Bonus health for each str enhancement
#define CON_HEAL_INTERVAL 5.0   // Task interval for Constitution health regen
#define DEX_EVADE_BONUS 0.02    // Dexterity bonus to Evasion skill
#define INT_IMPALE_LEVEL 11     // Intellect level needed for Impale bonus
#define INT_IMPALE_BONUS 0.08   // Intellect bonus to hit for Impale
#define INT_SIPHON_LEVEL 12     // Intellect level needed for Siphon Mana bonus
#define INT_SIPHON_BONUS 0.06   // Intellect bonus percent for Siphon Mana
#define INT_BANISH_LEVEL 13     // Intellect level needed for Banish bonus
#define INT_BANISH_BONUS 0.06   // Intellect bonus to hit for Banish
#define INT_HEX_LEVEL 14        // Intellect level needed for Hex bonus
#define INT_HEX_BONUS 0.07      // Intellect bonus to hit for Hex
#define INT_BASH_LEVEL 15       // Intellect level needed for Bash bonus
#define INT_BASH_BONUS 0.08     // Intellect bonus to hit for Bash
#define INT_TRUESHOT_LEVEL 16   // Intellect level needed for Trueshot bonus
#define INT_TRUESHOT_BONUS 0.07 // Intellect bonus damage for Trueshot
#define INT_SERPENT_LEVEL 17    // Intellect level needed for Serpent Ward bonus
#define INT_SERPENT_BONUS 2     // Intellect bonus # of serpent wards
#define INT_TELEPORT_LEVEL 17   // Intellect level needed for Teleport bonus
#define INT_TELEPORT_COOL 25.0  // Intellect bonus Teleport improved cooldown
#define INT_MASTER_LEVEL 18     // Intellect level to be considered Master

// Misc skill max values
#define SPIKED_MAX_DMG 25	// Max. damage Spiked Carapace can do
#define THORNS_MAX_DMG 35	// Max. damage Thorns Aura can do

// Define the UWC3 p_resists[] index for each resistance
#define RESISTIDX_POISON 1      // Poison Resistance
#define RESISTIDX_DISEASE 2     // Disease Resistance
#define RESISTIDX_ELECTRIC 3    // Electricity Resistance
#define RESISTIDX_FIRE 4        // Fire Resistance
#define RESISTIDX_MAGIC 5       // Magic Resistance

// Define the UWC3 p_skills[] index for each skill
#define SKILLIDX_VAMPIRIC 1
#define SKILLIDX_LEVITATION 2
#define SKILLIDX_DEVOTION 3
#define SKILLIDX_EQREINC 4
#define SKILLIDX_HEALWAVE 5
#define SKILLIDX_SIPHON 6
#define SKILLIDX_IMPALE 7
#define SKILLIDX_LSKIN 8
#define SKILLIDX_UNHOLY 9
#define SKILLIDX_BASH 10
#define SKILLIDX_CRITSTRIKE 11
#define SKILLIDX_REPAIR 12
#define SKILLIDX_BANISH 13
#define SKILLIDX_HEX 14
#define SKILLIDX_CARAPACE 15
#define SKILLIDX_MEND 16
#define SKILLIDX_EVASION 17
#define SKILLIDX_TRUESHOT 18
#define SKILLIDX_SSKIN 19
#define SKILLIDX_CARRION 20
#define SKILLIDX_SSTRIKE 21
#define SKILLIDX_ENTANGLE 22
#define SKILLIDX_FSTRIKE 23
#define SKILLIDX_FLASH 24
#define SKILLIDX_CRITGREN 25
#define SKILLIDX_SERPWARD 26
#define SKILLIDX_THORNS 27
#define SKILLIDX_INVIS 28
#define SKILLIDX_TELEPORT 29
#define SKILLIDX_VOODOO 30
#define SKILLIDX_FAN 31
#define SKILLIDX_VENGEANCE 32
#define SKILLIDX_LOCUST 33
#define SKILLIDX_BLINK 34
#define SKILLIDX_PHOENIX 35
#define SKILLIDX_NAPALM 36
#define SKILLIDX_GATE 37
#define SKILLIDX_SUICIDE 38
#define SKILLIDX_LIGHTNING 39
#define SKILLIDX_DECOY 40
#define SKILLIDX_UNUSED2 41

#define VENG_READY 0		// Vengeance state is Ready
#define VENG_WAIT 1		// Vengeance state is waiting to be revived
#define VENG_DONE 2		// Vengeance state is done for this round

#define BOMB_NOTPLANTED 0
#define BOMB_PLANTED 1
#define BOMB_DEFUSED 2

#define SQL_SAVEBY_STEAMID 1	// Save SQL data by steamid
#define SQL_SAVEBY_NAME 2	// Save SQL data by name

#define CSW_WORLD 0		// World Spawn death, for weapon xp multiplier
// **************************************************************************
// END UWC3 Defs
// **************************************************************************


// **************************************************************************
// BEGIN Backwards-Compatible Defs from War3 and War3FT
// The following #defines come straight from Warcraft3 FT plugin
// **************************************************************************

// Shopmenu 1 items list
#define ANKH 1
#define BOOTS 2
#define CLAWS 3
#define CLOAK 4
#define MASK 5
#define IMMUNITY 6
#define FROST 7
#define HEALTH 8
#define TOME 9

// Shopmenu 2 items list
#define RESPAWN 1
#define PROTECTANT 2
#define HELM 3
#define CAT 4
#define FEATHER 5
#define INFERNO 6
#define REGEN 7
#define CHAMELEON 8
#define MOLE 9

// Item default values Item Values
#define BOOTSPEED_DEF 275.0
#define CLAWSOFATTACK_DEF 6
#define CLOAKINVISIBILITY_DEF 150
#define MASKPERCENT_DEF 0.3
#define FROSTSPEED_DEF 125.0
#define HEALTHBONUS_DEF 15

#define CBSPEED 215.0
#define ARMORBONUS1 10
#define ARMORBONUS2 15
#define NORMALARMORMAX 100

// Team Numbers for get_user_team(id)
#define SPEC 0
#define TEAM_T 1
#define TEAM_CT 2

// NEVER CHANGE THESE !!! DISASTEROUS RESULTS (Message Defines)
#define TE_BEAMPOINTS 0
#define TE_EXPLOSION 3
#define TE_EXPLFLAG_NONE 0
#define TE_SMOKE 5
#define TE_BEAMENTS 8
#define TE_IMPLOSION 14
#define TE_SPRITETRAIL 15
#define TE_SPRITE 17
#define TE_BEAMCYLINDER 21
#define TE_BEAMFOLLOW 22
#define TE_ELIGHT 28
#define TE_PLAYERATTACHMENT 124
#define TE_LARGEFUNNEL 100
#define MAX_NAME_LENGTH 31
#define MAX_VAR_LENGTH 64

#define MAXGLOW 150
#define ULTIMATESEARCHTIME 50
#define TELEPORT_RADIUS 50
#define LIGHTNING_RANGE 500

// **************************************************************************
// END Backwards-Compatible Defs from War3 and War3FT
// **************************************************************************


