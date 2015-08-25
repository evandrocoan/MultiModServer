/**
 * Today, and forever more, I am ending this mess.
 */

#ifndef _INCLUDE_OFFSETS_H
#define _INCLUDE_OFFSETS_H

/**
 * NOTE: On X86, our patches look like:
 *  0xFF 0x25 * * * * (6 bytes)
 * On AMD64, we need 12 bytes:
 *  0x48 0xB8 * * * * * * * * (10 bytes)
 *  0xFF 0xE0 (2 bytes)
 */

//"six byte nop"
#define SBN		"\x90\x90\x90\x90\x90\x90"

#if defined WIN32

//find mp_tkpunish + kill
#define CSPLAYER_ROUNDRESPAWN		"\x83\x2A\x2A\x53\x56\x8B\x2A\x33\x2A\x57\x8A"
#define CSPLAYER_ROUNDRESPAWN_BYTES	11

//find mp_autoteambalance
//subtract the return from the start
#define CSPLAYER_RESTARTROUND		"\x51\x53\x56\x8B\x2A\x8B\x2A\x2A\x2A\x2A\x2A\x8B"
#define CSPLAYER_RESTARTROUND_BYTES	12
//there are 0x9DE bytes in this function.
//the last ones are a mov, 3 pops, and a retn
//that gives us, from the end...
#define CSPLAYER_RESTARTROUND_END			0xA05
#define CSPLAYER_RESTARTROUND_PATCH_BYTES	10

#define CSPLAYER_TAKEDAMAGE			"\x83\x2A\x2A\x53\x8B\x2A\x2A\x2A\x55\x33\x2A\x56\x57"
#define CSPLAYER_TAKEDAMAGE_BYTES	13
/**
 * 09C840 (base)
 * 09CA04 (0x1C4) - first  check, jnz->1byte jmp, purpose unknown
 * 09CD14 (0x4D4) - second check, jz->2byte nop, purpose unknown
 * 09D04F (0x80F) - third  check, jnz->2byte jmp, displays "hint"
 * 09D191 (0x951) - fourth check, jnz->1byte jmp, displays attack
 * 09D1F0 (0x9B0) - fifth  check, jnz->1byte jmp, does dmg deamp
 * 09D6F4 (0xEB4) - sixth  check, jz->2byte nop, purpose unknown*/
#define CSP_TD_PATCHES				{{"\xEB",0x1C4},{"\x90\x90",0x4D4},{"\x90\xE9",0x80F},{"\xEB",0x951},{"\xEB",0x9B0},{"\x90\x90",0xEB4}}
#define CSP_TD_PATCH_COUNT			6

#define CSGAME_PLAYERKILLED			"\x51\x53\x8B\x2A\x2A\x2A\x55\x8B\x2A\x8B"
#define CSGAME_PLAYERKILLED_BYTES	10
/**
 * 091A70 (base)	
 * 091BD2 - (0x162) - first check, jnz->2byte jump, does kill stuff
 */
#define CSG_PK_PATCHES		{{"\x90\xE9",0x162}}
#define CSG_PK_PATCH_COUNT	1

#else

/**
 * LINUX OFFSETS 
 */

#if defined AMD64

#error No longer supported!

///////
// AMD64
///////

#define CSPLAYER_ROUNDRESPAWN			"\x48\x83\xEC\x18\x48\x89\x5C\x24\x08\x48\x89\x6C\x24\x10\x48\x89\xFB\x80\xBF\xF8\x03\x00\x00\x01\xC6\x87\x59\x0A\x00\x00\x01\x74"
#define CSPLAYER_ROUNDRESPAWN_BYTES		32

#define CSPLAYER_RESTARTROUND			"\x41\x56\x41\x55\x41\x54\x49\x89\xFC\x55\x53\x48\x83\xEC\x10\x48\x8B\x0D\x2A\x2A\x2A\x2A\x48\x8B\x39\x48\x8B\x17\xFF\x52\x38\x48"
#define CSPLAYER_RESTARTROUND_BYTES		32
//there are 0x847 bytes in this function.
//note that this val does not disasm to the VERY end,
//the return is in the middle
#define CSPLAYER_RESTARTROUND_END		0x847
#define CSPLAYER_RESTARTROUND_PATCH_BYTES	13

#define CSPLAYER_TAKEDAMAGE				"\x41\x57\x41\x56\x41\x89\xCE\x41\x55\x41\x54\x49\x89\xFC\x55\x53\x48\x81\xEC\x98\x00\x00\x00\xF7\xC1\x60\x00\x00\x01\x48\x89\x54"
#define CSPLAYER_TAKEDAMAGE_BYTES		32
/**
 * 1248D4 (0x4A4) - first check, jz->6byte nop, purpose unknown
 * 124A79 (0x649) - second check, jz->6byte nop, displays "Hint" about not shooting mates
 * 124F3F (0xB0F) - third check, jnz->2byte JMP, does dmg deamplification
 * 124FEF (0xBBF) - fourth check, jz->2byte nop, displays team attack msg
 * 1255C2 (0x1192) - fifth check, jz->6byte nop, purpose unknown
 */
#define CSP_TD_PATCHES		{{SBN,0x4A4},{SBN,0x649},{"\x90\xE9",0xB0F},{"\x90\x90",0xBBF},{SBN,0x1192}}
#define CSP_TD_PATCH_COUNT	5

#define CSGAME_PLAYERKILLED				"\x41\x57\x41\x56\x49\x89\xD6\x41\x55\x41\x54\x49\x89\xFC\x55\x48\x89\xF5\x53\x48\x83\xEC\x18\x48\x89\x4C\x24\x10\x48\x8B\x1F\xFF"
#define CSGAME_PLAYERKILLED_BYTES		32
/**
 * 117179 (0x289) - first check, jz->6byte nop, does kill stuff
 */
#define CSG_PK_PATCHES			{{SBN,0x289}}
#define CSG_PK_PATCH_COUNT		1

#else

///////
// X86
///////

#define CSPLAYER_ROUNDRESPAWN			"_ZN11CBasePlayer12RoundRespawnEv"

#define CSPLAYER_RESTARTROUND			"_ZN18CHalfLifeMultiplay12RestartRoundEv"
//there are 0x78A bytes in this function.
//the last ones are all two/one byte instrs
//that gives us, from the end...
#define CSPLAYER_RESTARTROUND_END			0x78A
#define CSPLAYER_RESTARTROUND_PATCH_BYTES	7

#define CSPLAYER_TAKEDAMAGE				"_ZN11CBasePlayer10TakeDamageEP9entvars_sS1_fi"

/**
 * 111720 (base)
 * 111DF6 (0x6D6)  - first check	, jz->5byte nop	, displays hint
 * 112414 (0xCF4)  - second check	, jnz->2byte jmp, related to career task
 * 11256E (0xE4E)  - third check	, jnz->2byte jmp, does dmg deamp
 * 1127B3 (0x1093) - fourth check	, jnz->2byte jmp, related to grenade and mp_friendlyfire
 * 11284C (0x112C) - fifth check	, jnz->2byte jmp, related to career task
 * 1124BB (0xD9B)  - sixth check	, jnz->2byte jmp, related to grenade and mp_friendlyfire
 * 112B94 (0x1474) - seventh check	, jnz->1byte jmp, displays team attack msg
 */
#define CSP_TD_PATCHES		{{SBN,0x6D6},{"\x90\xE9",0xCF4},{"\x90\xE9",0xE4E},{"\x90\xE9",0x1093},{"\x90\xE9",0x112C},{"\x90\xE9",0xD9B},{"xEB",0x1474}}
#define CSP_TD_PATCH_COUNT	7

#define CSGAME_PLAYERKILLED	"_ZN18CHalfLifeMultiplay12PlayerKilledEP11CBasePlayerP9entvars_sS3_"
/**
 * F2880 (base)
 * F2A4C (0x1CC) - first check, jnz->5byte nop, does kill stuff
 */		
#define CSG_PK_PATCHES		{{"\x90\x90\x90\x90\x90\x90",0x1CC}}
#define CSG_PK_PATCH_COUNT	1

#endif //AMD64

#endif //WIN32

#endif //_INCLUDE_OFFSETS_H
