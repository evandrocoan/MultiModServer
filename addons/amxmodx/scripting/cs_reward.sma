/*		
		Copyright © 2014, zmd94.

		This plugin is free software;
		you can redistribute it and/or modify it under the terms of the
		GNU General Public License as published by the Free Software Foundation.

		This program is distributed in the hope that it will be useful,
		but WITHOUT ANY WARRANTY; without even the implied warranty of
		MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
		GNU General Public License for more details.
*/

#include <amxmodx>
#include <amxmisc>
#include <cstrike>
#include <hamsandwich>
#include <fakemeta>
#include <engine>
#include <fun>
#include <xs>

// Just uncomment 'CUSTOM_MESSAGE' if your want to enable custom message from cs_reward.sma
#define CUSTOM_MESSAGE

// Credit: https://forums.alliedmods.net/showpost.php?p=717994&postcount=2
#define START_DISTANCE  32   // The first search distance for finding a free location in the map
#define MAX_ATTEMPTS    128  // How many times to search in an area for a free space

// Sprites
#define LINE_SPRITES "sprites/dot.spr"
#define RING_SPRITES "sprites/white.spr"
#define TRAIL_SPRITES "sprites/laserbeam.spr"

// Macro
#define PlayerHullSize(%1)  ((pev(%1, pev_flags) & FL_DUCKING) ? HULL_HEAD : HULL_HUMAN)

// Credit: https://forums.alliedmods.net/showpost.php?p=853202&postcount=11
new Ham:Ham_Player_ResetMaxSpeed = Ham_Item_PreFrame

// Just for readability ;)
enum Coord_e 
{ 
	Float:x, 
	Float:y, 
	Float:z 
}

enum (+= 123)
{
	TASK_INVI = 1234,
	TASK_NOCLIP,
	TASK_HEADSHOT,
	TASK_GODMODE,
	TASK_GLOW,
	TASK_AURA,
	TASK_LINE,
	TASK_RING,
	TASK_TRAIL,
	TASK_RESET
}

// CS player CBase offsets: https://wiki.alliedmods.net/CBasePlayer_%28CS%29
const pdata_safe = 2
const m_pActiveItem  = 373
const m_afButtonPressed = 246
const m_flFallVelocity = 251 
const linux_diff = 5
const mac_diff = 5

// Weapon bitsum
const WEAPONS_BITSUM = (1<<CSW_KNIFE|1<<CSW_HEGRENADE|1<<CSW_FLASHBANG|1<<CSW_SMOKEGRENADE|1<<CSW_C4)

// Weapon IDs for ammo types
new const AMMOWEAPON[] = { 0, CSW_AWP, CSW_SCOUT, CSW_M249, CSW_AUG, CSW_XM1014, CSW_MAC10, CSW_FIVESEVEN, CSW_DEAGLE,
			CSW_P228, CSW_ELITE, CSW_FLASHBANG, CSW_HEGRENADE, CSW_SMOKEGRENADE, CSW_C4 }
			
// Ammo type names for weapons
new const AMMOTYPE[][] = { "", "357sig", "", "762nato", "", "buckshot", "", "45acp", "556nato", "", "9mm", "57mm", "45acp",
	"556nato", "556nato", "556nato", "45acp", "9mm", "338magnum", "9mm", "556natobox", "buckshot",
	"556nato", "9mm", "762nato", "", "50ae", "556nato", "762nato", "", "57mm" }

// Max BP ammo for weapons
new const MAXBPAMMO[] = { -1, 52, -1, 90, 1, 32, 1, 100, 90, 1, 120, 100, 100, 90, 90, 90, 100, 120,
	30, 120, 200, 32, 90, 120, 90, 2, 35, 90, 90, -1, 100 }
	
// Max clip for weapons
new const MAXCLIP[] = { -1, 13, -1, 10, -1, 7, -1, 30, 30, -1, 30, 20, 25, 30, 35, 25, 12, 20,
			10, 30, 100, 8, 30, 30, 20, -1, 7, 30, 30, -1, 50 }

// BP ammo refill
#define REFILL_WEAPONID args[0]

#define MAXPLAYERS 32

// Bools
new bool:g_bHeadShot[MAXPLAYERS+1]
new bool:g_bSpeedBoost[MAXPLAYERS+1]
new bool:g_bMultiJump[MAXPLAYERS+1]
new bool:g_bAllUnlimit[MAXPLAYERS+1], bool:g_bBPUnlimit[MAXPLAYERS+1]
new bool:g_bNoRecoil[MAXPLAYERS+1]
new bool:g_bRender[MAXPLAYERS+1]
new bool:g_bLow[MAXPLAYERS+1]
new bool:g_bWall[MAXPLAYERS+1]

// Float
new Float:g_fClosestLine, Float:g_fLine
new Float:g_fClosestRing, Float:g_fRing

new Float:g_fLastTime[MAXPLAYERS+1]
new Float:g_fPushAngle[MAXPLAYERS+1][3]
new Float:g_fWall[MAXPLAYERS+1]

// Variables
new g_iJump[MAXPLAYERS+1]
new g_iJumpCount[MAXPLAYERS+1]
new g_iSpeed[MAXPLAYERS+1]
new g_gRed[MAXPLAYERS+1], g_gGreen[MAXPLAYERS+1], g_gBlue[MAXPLAYERS+1]
new g_aRed[MAXPLAYERS+1], g_aGreen[MAXPLAYERS+1], g_aBlue[MAXPLAYERS+1]
new g_lRed[MAXPLAYERS+1], g_lGreen[MAXPLAYERS+1], g_lBlue[MAXPLAYERS+1]
new g_rRed[MAXPLAYERS+1], g_rGreen[MAXPLAYERS+1], g_rBlue[MAXPLAYERS+1]
new g_tRed[MAXPLAYERS+1], g_tGreen[MAXPLAYERS+1], g_tBlue[MAXPLAYERS+1]

new g_iPlayerOrigin[3], g_iOtherOrigin[3]
new g_iFindLine, g_iCloseLine
new g_iFindRing, g_iCloseRing

new g_iTrace
new g_iLine, g_iRing, g_iTrail
new g_iMsgSayTxt, g_iMsgAmmo

public plugin_init()
{
	register_plugin("[API] Rewards", "6.1", "zmd94")

	register_event("HLTV", "event_new_round", "a", "1=0", "2=0")

	RegisterHam(Ham_Spawn, "player", "fw_PlayerRespawn", 1)
	RegisterHam(Ham_Killed, "player", "fw_PlayerKilled", 1)
	
	g_iMsgSayTxt = get_user_msgid("SayText") 
}

public plugin_natives()
{
	register_library("cs_core")
	register_native("cs_health_reward", "native_health_reward")
	register_native("cs_armor_reward", "native_armor_reward")
	register_native("cs_money_reward", "native_money_reward")
	register_native("cs_invisible_reward", "native_invisible_reward")
	register_native("cs_noclip_reward", "native_noclip_reward")
	register_native("cs_istrap", "native_istrap")
	register_native("cs_grenade_reward", "native_grenade_reward")
	register_native("cs_weapon_reward", "native_weapon_reward")
	register_native("cs_headshot_reward", "native_headshot_reward")
	register_native("cs_godmode_reward", "native_godmode_reward")
	register_native("cs_glow_reward", "native_glow_reward")
	register_native("cs_aura_reward", "native_aura_reward")
	register_native("cs_speed_reward", "native_speed_reward")
	register_native("cs_jump_reward", "native_jump_reward")
	register_native("cs_unlimited_reward", "native_unlimited_reward")
	register_native("cs_norecoil_reward", "native_norecoil_reward")
	register_native("cs_line_reward", "native_line_reward")
	register_native("cs_ring_reward", "native_ring_reward")
	register_native("cs_trail_reward", "native_trail_reward")
	register_native("cs_gravity_reward", "native_gravity_reward")
	register_native("cs_wall_reward", "native_wall_reward")
}

public plugin_precache()
{
	g_iLine = precache_model(LINE_SPRITES)
	g_iRing = precache_model(RING_SPRITES)
	g_iTrail = precache_model(TRAIL_SPRITES)
}

public native_health_reward(iPlugin, iParams)
{
	if(iParams != 3)
	{
		log_error(AMX_ERR_NATIVE, "cs_health_reward native is incorrect. Param count is 3")
		return 0
	}
	
	new id = get_param(1)

	// Prevent the reward if the player is died
	if(!is_user_alive(id))
		return 0
	
	new Float:fHP = get_param_f(2)
	
	// Prevent the reward if the values is less than "0"
	if(fHP < 0.0)
	{
		log_error(AMX_ERR_NATIVE, "cs_health_reward native is incorrect. fHP must not less than 0.0")
		return 0
	}
	
	switch(get_param(3))
    {
        case 0:     
        {
			set_pev(id, pev_health, fHP)
		}
		case 1:
		{
			// Limit the reward as goldsrc engine can show 255 health
			set_pev(id, pev_health, floatmin(pev(id, pev_health) + fHP, 255.0))
			
			#if defined CUSTOM_MESSAGE
			// Print the message about the value of the reward
			print_colored(id, "!g[CS] !tHealth reward for !y%.f!", fHP) 
			#endif
		}
		default:
		{
			log_error(AMX_ERR_NATIVE, "cs_health_reward native is incorrect. iType must not less than 0 or more than 1")
			return 0
		}
	}
	
	return 1
}

public native_armor_reward(iPlugin, iParams)
{
	if(iParams != 3)
	{
		log_error(AMX_ERR_NATIVE, "cs_armor_reward native is incorrect. Param count is 3")
		return 0
	}
	
	new id = get_param(1)
	
	// Prevent the reward if the player is died
	if(!is_user_alive(id))
		return 0
	
	new Float:fAP = get_param_f(2)
	
	// Prevent the reward if the values is less than "0"
	if(fAP < 0.0)
	{
		log_error(AMX_ERR_NATIVE, "cs_armor_reward native is incorrect. fAP must not less than 0.0")
		return 0
	}
	
	switch(get_param(3))
    {
        case 0:     
        {
			set_pev(id, pev_armorvalue, fAP)
		}
		case 1:
		{
			// Limit reward as goldsrc engine can show 9999 armor
			set_pev(id, pev_armorvalue, floatmin(pev(id, pev_armorvalue) + fAP, 9999.0))
			
			#if defined CUSTOM_MESSAGE
			// Print the message about the value of the reward
			print_colored(id, "!g[CS] !tArmor reward for !y%.f!", fAP) 
			#endif
		}
		default:
		{
			log_error(AMX_ERR_NATIVE, "cs_armor_reward native is incorrect. iType must not less than 0 or more than 1")
			return 0
		}
	}
	
	return 1
}

public native_money_reward(iPlugin, iParams)
{
	if(iParams != 3)
	{
		log_error(AMX_ERR_NATIVE, "cs_money_reward native is incorrect. Param count is 3")
		return 0
	}
	
	new id = get_param(1)
	
	// Prevent the reward if the player is died
	if(!is_user_alive(id))
		return 0
	
	new iMoney = get_param(2)
	
	// Prevent the reward if the values is less than "0"
	if(iMoney < 0)
	{
		log_error(AMX_ERR_NATIVE, "cs_money_reward native is incorrect. iMoney must not less than 0")
		return 0
	}
	
	switch(get_param(3))
    {
        case 0:     
        {
			cs_set_user_money(id, iMoney)
		}
		case 1:
		{
			// Limit the reward as the default maximum money is 16000
			cs_set_user_money(id, min(cs_get_user_money(id) + iMoney, 16000))
			
			#if defined CUSTOM_MESSAGE
			// Print the message about the value of the reward
			print_colored(id, "!g[CS] !tMoney reward for !y%d!", iMoney)
			#endif	
		}
		default:
		{
			log_error(AMX_ERR_NATIVE, "cs_money_reward native is incorrect. iType must not less than 0 or more than 1")
			return 0
		}
	}
	
	return 1
}

public native_invisible_reward(iPlugin, iParams)
{
	if(iParams != 5)
	{
		log_error(AMX_ERR_NATIVE, "cs_invisible_reward native is incorrect. Param count is 5")
		return 0
	}
	
	new id = get_param(1)
	
	// Prevent the reward if the player is died
	if(!is_user_alive(id))
		return 0
	
	switch(get_param(2))
    {
        case 0:     
        {
			set_user_rendering(id)
			set_user_footsteps(id, 0)
			
			#if defined CUSTOM_MESSAGE
			// Print the message about the reward is over
			print_colored(id, "!g[CS] !tInvisibility is over!") 
			#endif
		}
		case 1:
		{
			new iInvi = get_param(3)
	
			// Prevent the reward if the values is less than "0"
			if(iInvi < 0)
			{
				log_error(AMX_ERR_NATIVE, "cs_invisible_reward native is incorrect. iInvi must not less than 0")
				return 0
			}
			
			//This reward will also give silent footsteps to the player
			set_user_rendering(id, kRenderFxGlowShell, 0, 0, 0, kRenderTransAlpha, iInvi)
			set_user_footsteps(id,1)
			
			switch(get_param(4))
			{
				case 0:     
				{
					#if defined CUSTOM_MESSAGE
					// Print the message about the duration of the reward
					print_colored(id, "!g[CS] !tInvisibility reward!")
					#endif
				}
				case 1:
				{
					new Float:fInviT = get_param_f(5)
			
					// Prevent the reward if the values is less than "0.0"
					if(fInviT < 0.0)
					{
						log_error(AMX_ERR_NATIVE, "cs_invisible_reward native is incorrect. fInviT must not less than 0.0")
						return 0
					}
						
					// Just in case we don't want the duplicate task
					remove_task(id+TASK_INVI) 
					set_task(fInviT, "restore_invisible", id+TASK_INVI)
					
					#if defined CUSTOM_MESSAGE
					// Print the message about the duration of the reward
					print_colored(id, "!g[CS] !tInvisibility reward for !y%.f seconds!", fInviT) 
					#endif
				}
				default:
				{
					log_error(AMX_ERR_NATIVE, "cs_invisible_reward native is incorrect. iType must not less than 0 or more than 1")
					return 0
				}
			}
		}
		default:
		{
			log_error(AMX_ERR_NATIVE, "cs_invisible_reward native is incorrect. iValue must not less than 0 or more than 1")
			return 0
		}
	}
	
	return 1
}

// Restore the invisibility
public restore_invisible(id)
{
	id -= TASK_INVI
	if(is_user_alive(id))
	{
		set_user_rendering(id)
		set_user_footsteps(id, 0)
		
		// Print the message about the reward is over
		print_colored(id, "!g[CS] !tInvisibility is over!") 
	}
}

public native_noclip_reward(iPlugin, iParams)
{
	if(iParams != 4)
	{
		log_error(AMX_ERR_NATIVE, "cs_noclip_reward native is incorrect. Param count is 4")
		return 0
	}
	
	new id = get_param(1)
	
	// Prevent the reward if the player is died
	if(!is_user_alive(id))
		return 0
	
	switch(get_param(2))
    {
        case 0:     
        {
			set_user_noclip(id, 0)
			i_NoClip(id)
			
			#if defined CUSTOM_MESSAGE
			// Print the message about the reward is over
			print_colored(id, "!g[CS] !tNoclip is over!") 
			#endif
		}
		case 1:
		{
			set_user_noclip(id, 1)
			
			switch(get_param(3))
			{
				case 0:     
				{
					#if defined CUSTOM_MESSAGE
					// Print the message about the reward
					print_colored(id, "!g[CS] !tNoclip reward!")
					#endif
				}
				case 1:
				{
					new Float:fNoclipT = get_param_f(4)
	
					// Prevent the reward if the values is less than "0.0"
					if(fNoclipT < 0.0)
					{
						log_error(AMX_ERR_NATIVE, "cs_noclip_reward native is incorrect. fNoclipT must not less than 0.0")
						return 0
					}
					
					// Just in case we don't want the duplicate task
					remove_task(id+TASK_NOCLIP)
					set_task(fNoclipT, "restore_noclip", id+TASK_NOCLIP)
					
					#if defined CUSTOM_MESSAGE
					// Print the message about the duration of the reward
					print_colored(id, "!g[CS] !tNoclip reward for !y%.f seconds!", fNoclipT)
					#endif
				}
				default:
				{
					log_error(AMX_ERR_NATIVE, "cs_noclip_reward native is incorrect. iType must not less than 0 or more than 1")
					return 0
				}
			}
		}
		default:
		{
			log_error(AMX_ERR_NATIVE, "cs_noclip_reward native is incorrect. iValue must not less than 0 or more than 1")
			return 0
		}
	}
	
	return 1
}

// Restore the noclip
public restore_noclip(id)
{
	id -= TASK_NOCLIP
	if(is_user_alive(id))
	{
		set_user_noclip(id, 0)
		i_NoClip(id)
		
		// Print the message about the reward is over
		print_colored(id, "!g[CS] !tNoclip is over!") 
	}
}

public native_istrap(iPlugin, iParams)
{
	new id = get_param(1)
	
	// Prevent the reward if the player is died
	if(!is_user_alive(id))
		return 0
	
	i_NoClip(id)
	
	return 1
}

// Credit: https://forums.alliedmods.net/showpost.php?p=717994&postcount=2
i_NoClip(id)
{
	if (get_gametime() - g_fLastTime[id] < 4.0) 
	{
		print_colored(id, "!g[CS] !tPlease wait !y4 seconds !tbefore trying to free yourself!")
		return PLUGIN_HANDLED
	}
	
	g_fLastTime[id] = get_gametime()
	
	new i_Value
	if((i_Value = UTIL_Player(id, START_DISTANCE, MAX_ATTEMPTS)) != 1)
	{
		switch(i_Value)
		{
			case 0: print_colored(id, "!g[CS] !tCouldn't find a free spot to move you too!")
			case -1: print_colored(id, "!g[CS] !tYou cannot free yourself as dead player!")
		}
	}
	
	return PLUGIN_CONTINUE
}

// Credit: https://forums.alliedmods.net/showpost.php?p=717994&postcount=2
UTIL_Player (const id, const i_StartDistance, const i_MaxAttempts)
{
	// If the player is not alive
	if (!is_user_alive(id))  
		return -1

	new Float:vf_OriginalOrigin[Coord_e], Float:vf_NewOrigin[Coord_e]
	new i_Attempts, i_Distance;

	// This is to get the current player's origin
	pev (id, pev_origin, vf_OriginalOrigin)

	i_Distance = i_StartDistance;

	while (i_Distance < 1000)
	{
		i_Attempts = i_MaxAttempts;
		
		while(i_Attempts--)
		{
			vf_NewOrigin[x] = random_float(vf_OriginalOrigin[x] - i_Distance, vf_OriginalOrigin[x] + i_Distance)
			vf_NewOrigin[y] = random_float(vf_OriginalOrigin[y] - i_Distance, vf_OriginalOrigin[y] + i_Distance)
			vf_NewOrigin[z] = random_float(vf_OriginalOrigin[z] - i_Distance, vf_OriginalOrigin[z] + i_Distance)
			
			engfunc ( EngFunc_TraceHull, vf_NewOrigin, vf_NewOrigin, DONT_IGNORE_MONSTERS, PlayerHullSize(id), id, 0)
			
			// Free space found
			if(get_tr2(0, TR_InOpen) && !get_tr2 (0, TR_AllSolid) && !get_tr2(0, TR_StartSolid))
			{
				// Set the new origin 
				engfunc (EngFunc_SetOrigin, id, vf_NewOrigin)
				return 1;
			}
		}
		
		i_Distance += i_StartDistance
	}

	// Could not be found
	return 0
}

public native_grenade_reward(iPlugin, iParams)
{
	if(iParams != 3)
	{
		log_error(AMX_ERR_NATIVE, "cs_grenade_reward native is incorrect. Param count is 3")
		return 0
	}
	
	new id = get_param(1)
	
	// Prevent the reward if the player is died
	if(!is_user_alive(id))
		return 0
	
	new iGrenade = get_param(2)
	
	// Prevent the reward if the values is less than "0"
	if(iGrenade < 0)
	{
		log_error(AMX_ERR_NATIVE, "cs_grenade_reward native is incorrect. iGrenade must more than 0")
		return 0
	}
	
	switch(get_param(3))
	{
		case 0:
		{
			give_item(id, "weapon_hegrenade")
			cs_set_user_bpammo(id, CSW_HEGRENADE, iGrenade)
		}
		case 1:
		{
			give_item(id, "weapon_flashbang")
			cs_set_user_bpammo(id, CSW_FLASHBANG, iGrenade)
		}
		case 2:
		{
			give_item(id, "weapon_smokegrenade")
			cs_set_user_bpammo(id, CSW_SMOKEGRENADE, iGrenade)
		}
		case 3:
		{
			give_item(id, "weapon_flashbang")
			cs_set_user_bpammo(id, CSW_FLASHBANG, iGrenade)
			
			give_item(id, "weapon_hegrenade")
			cs_set_user_bpammo(id, CSW_HEGRENADE, iGrenade)
			
			give_item(id, "weapon_smokegrenade")
			cs_set_user_bpammo(id, CSW_SMOKEGRENADE, iGrenade)
		}
		default:
		{
			log_error(AMX_ERR_NATIVE, "cs_grenade_reward native is incorrect. iType must not less than 0 and more than 3")
			return 0
		}
	}
	
	#if defined CUSTOM_MESSAGE
	// Print the message about the reward
	print_colored(id, "!g[CS] !tFree grenade reward!") 
	#endif
	
	return 1
}

public native_weapon_reward(iPlugin, iParams)
{
	if(iParams != 2)
	{
		log_error(AMX_ERR_NATIVE, "cs_weapon_reward native is incorrect. Param count is 2")
		return 0
	}
	
	new id = get_param(1)
	
	// Prevent the reward if the player is died
	if(!is_user_alive(id))
		return 0
	
	new szWeapon[32]
	get_string(2, szWeapon, charsmax(szWeapon))
	
	if(!equal(szWeapon, "weapon_",7))
	{
		log_error(AMX_ERR_NATIVE, "cs_weapon_reward native is incorrect. const szName[] must start with weapon_")
		return 0
	}
	
	give_item(id, szWeapon)
	
	new weapon_id = get_weaponid(szWeapon)
	ExecuteHamB(Ham_GiveAmmo, id, MAXBPAMMO[weapon_id], AMMOTYPE[weapon_id], MAXBPAMMO[weapon_id])
	
	#if defined CUSTOM_MESSAGE
	// Print the message about the reward		
	print_colored(id, "!g[CS] !tFree weapon reward!")
	#endif
	
	return 1
}

public native_headshot_reward(iPlugin, iParams)
{
	if(iParams != 4)
	{
		log_error(AMX_ERR_NATIVE, "cs_headshot_reward native is incorrect. Param count is 4")
		return 0
	}
	
	new HamHook:hHamTrace
	if(!hHamTrace)
	{
		hHamTrace = RegisterHam(Ham_TraceAttack, "player", "fw_HeadShot")
	}
	
	new id = get_param(1)
	
	// Prevent the reward if the player is died
	if(!is_user_alive(id))
		return 0
	
	switch(get_param(2))
    {
        case 0:     
        {
			g_bHeadShot[id] = false
			
			#if defined CUSTOM_MESSAGE
			// Print the message about the reward is over
			print_colored(id, "!g[CS] !tDeadly shot ability is over!")
			#endif			
		}
		case 1:
		{
			g_bHeadShot[id] = true
			
			switch(get_param(3))
			{
				case 0:     
				{
					#if defined CUSTOM_MESSAGE
					// Print the message about the reward
					print_colored(id, "!g[CS] !tDeadly shot reward!") 
					#endif
				}
				case 1:
				{
					new Float:fHeadshotT = get_param_f(4)
					
					// Prevent the reward if the values is less than "0.0"
					if(fHeadshotT < 0.0)
					{
						log_error(AMX_ERR_NATIVE, "cs_noclip_reward native is incorrect. fHeadshotT must not less than 0.0")
						return 0
					}
					
					#if defined CUSTOM_MESSAGE
					// Print the message about the duration of the reward
					print_colored(id, "!g[CS] !tDeadly shot reward for !y%.f seconds!", fHeadshotT)
					#endif	
					
					// Just in case we don't want the duplicate task
					remove_task(id+TASK_HEADSHOT) 
					set_task(fHeadshotT, "remove_headshot", id+TASK_HEADSHOT)
				}
				default:
				{
					log_error(AMX_ERR_NATIVE, "cs_headshot_reward native is incorrect. iType must not less than 0 or more than 1")
					return 0
				}
			}
		}
		default:
		{
			log_error(AMX_ERR_NATIVE, "cs_headshot_reward native is incorrect. iValue must not less than 0 or more than 1")
			return 0
		}
	}
	
	return 1
}

// Remove headshot
public remove_headshot(id)
{
	id -= TASK_HEADSHOT
	if(is_user_alive(id))
	{
		g_bHeadShot[id] = false
		
		// Print the message about the reward is over
		print_colored(id, "!g[CS] !tDeadly shot ability is over!") 
	}
}

public native_godmode_reward(iPlugin, iParams)
{
	if(iParams != 4)
	{
		log_error(AMX_ERR_NATIVE, "cs_godmode_reward native is incorrect. Param count is 4")
		return 0
	}
	
	new id = get_param(1)
	
	// Prevent the reward if the player is died
	if(!is_user_alive(id))
		return 0
	
	switch(get_param(2))
    {
        case 0:     
        {
			set_user_godmode(id, 0)
			
			#if defined CUSTOM_MESSAGE
			// Print the message about the reward is over
			print_colored(id, "!g[CS] !tGod mode ability is over!")
			#endif
		}
		case 1:
		{
			set_user_godmode(id, 1)
			
			switch(get_param(3))
			{
				case 0:     
				{
					#if defined CUSTOM_MESSAGE
					// Print the message about the reward
					print_colored(id, "!g[CS] !tGod mode ability!")
					#endif
				}
				case 1:
				{
					new Float:fGodmodeT = get_param_f(4)
	
					// Prevent the reward if the values is less than "0.0"
					if(fGodmodeT < 0.0)
					{
						log_error(AMX_ERR_NATIVE, "cs_godmode_reward native is incorrect. fGodmodeT must not less than 0.0")
						return 0
					}
					
					#if defined CUSTOM_MESSAGE
					// Print the message about the duration of the reward
					print_colored(id, "!g[CS] !tGod mode ability !yfor %.f seconds!", fGodmodeT)
					#endif
					
					// Just in case we don't want the duplicate task
					remove_task(id+TASK_GODMODE)
					set_task(fGodmodeT, "remove_godmode", id+TASK_GODMODE)
				}
				default:
				{
					log_error(AMX_ERR_NATIVE, "cs_godmode_reward native is incorrect. iType must not less than 0 or more than 1")
					return 0
				}
			}
		}
		default:
		{
			log_error(AMX_ERR_NATIVE, "cs_godmode_reward native is incorrect. iValue must not less than 0 or more than 1")
			return 0
		}
	}
	
	return 1
}

// Remove godmode
public remove_godmode(id)
{
	id -= TASK_GODMODE
	if(is_user_alive(id))
	{
		set_user_godmode(id, 0)
		
		// Print the message about the reward is over
		print_colored(id, "!g[CS] !tGod mode ability is over!") 
	}
}

public native_glow_reward(iPlugin, iParams)
{
	if(iParams != 5)
	{
		log_error(AMX_ERR_NATIVE, "cs_glow_reward native is incorrect. Param count is 5")
		return 0
	}
	
	new id = get_param(1)
	
	// Prevent the reward if the player is died
	if(!is_user_alive(id))
		return 0
	
	g_bRender[id] = true
	
	switch(get_param(2))
    {
        case 0:     
        {
			set_user_rendering(id)
			
			g_bRender[id] = false
			
			#if defined CUSTOM_MESSAGE
			// Print the message about the reward is over
			print_colored(id, "!g[CS] !tGlow is over!")
			#endif
		}
		case 1:
		{
			get_color(g_gRed[id], g_gGreen[id], g_gBlue[id])
			set_user_rendering(id, kRenderFxGlowShell, g_gRed[id], g_gGreen[id], g_gBlue[id], kRenderNormal, 25)
			
			switch(get_param(4))
			{
				case 0:     
				{
					#if defined CUSTOM_MESSAGE
					// Print the message about the reward
					print_colored(id, "!g[CS] !tGlow reward!")
					#endif
				}
				case 1:
				{
					new Float:fGlowT = get_param_f(5)
	
					// Prevent the reward if the values is less than "0.0"
					if(fGlowT < 0.0)
					{
						log_error(AMX_ERR_NATIVE, "cs_glow_reward native is incorrect. fGlowT must not less than 0.0")
						return 0
					}

					#if defined CUSTOM_MESSAGE
					// Print the message about the duration of the reward
					print_colored(id, "!g[CS] !tGlow reward !yfor %.f seconds!", fGlowT)
					#endif
					
					// Just in case we don't want the duplicate task
					remove_task(id+TASK_GLOW)
					set_task(fGlowT, "restore_glow", id+TASK_GLOW)
				}
				default:
				{
					log_error(AMX_ERR_NATIVE, "cs_glow_reward native is incorrect. iType must not less than 0 or more than 1")
					return 0
				}
			}
		}
		default:
		{
			log_error(AMX_ERR_NATIVE, "cs_glow_reward native is incorrect. iValue must not less than 0 or more than 1")
			return 0
		}
	}
	
	return 1
}

// Restore the glow
public restore_glow(id)
{
	id -= TASK_GLOW
	if(is_user_alive(id))
	{
		set_user_rendering(id)
		
		g_bRender[id] = false
		
		// Print the message about the reward is over
		print_colored(id, "!g[CS] !tGlow is over!") 
	}
}

public native_aura_reward(iPlugin,iParams)
{
	if(iParams != 5)
	{
		log_error(AMX_ERR_NATIVE, "cs_aura_reward native is incorrect. Param count is 5")
		return 0
	}
	
	new id = get_param(1)
	
	// Prevent the reward if the player is died
	if(!is_user_alive(id))
		return 0
	
	switch(get_param(2))
    {
        case 0:     
        {
			remove_task(id+TASK_AURA)
			
			#if defined CUSTOM_MESSAGE
			// Print the message about the reward is over
			print_colored(id, "!g[CS] !tColored aura is over!")
			#endif
		}
		case 1:
		{
			// Just in case we don't want the duplicate task
			remove_task(id+TASK_AURA)
			
			set_task(0.1, "player_aura", id+TASK_AURA, _, _, "b")
			
			get_color(g_aRed[id], g_aGreen[id], g_aBlue[id])
			
			switch(get_param(4))
			{
				case 0:     
				{
					#if defined CUSTOM_MESSAGE
					// Print the message about the reward
					print_colored(id, "!g[CS] !tAura reward!")
					#endif
				}
				case 1:
				{
					new Float:fAuraT = get_param_f(5)
	
					// Prevent the reward if the values is less than "0.0"
					if(fAuraT < 0.0)
					{
						log_error(AMX_ERR_NATIVE, "cs_aura_reward native is incorrect. fAuraT must not less than 0.0")
						return 0
					}
					
					// Just in case we don't want the duplicate task
					remove_task(id+TASK_RESET)
					
					set_task(fAuraT, "remove_aura", id+TASK_RESET)
					
					#if defined CUSTOM_MESSAGE
					// Print the message about the duration of the reward
					print_colored(id, "!g[CS] !tAura reward !yfor %.f seconds!", fAuraT)
					#endif
				}
				default:
				{
					log_error(AMX_ERR_NATIVE, "cs_aura_reward native is incorrect. iType must not less than 0 or more than 1")
					return 0
				}
			}
		}
		default:
		{
			log_error(AMX_ERR_NATIVE, "cs_aura_reward native is incorrect. iValue must not less than 0 or more than 1")
			return 0
		}
	}
	
	return 1
}

public player_aura(id)
{
	id -= TASK_AURA
	if(is_user_alive(id))
	{
		get_user_origin(id, g_iPlayerOrigin)
		
		message_begin(MSG_PVS, SVC_TEMPENTITY, g_iPlayerOrigin)
		write_byte(TE_DLIGHT) 
		write_coord(g_iPlayerOrigin[0]) 
		write_coord(g_iPlayerOrigin[1]) 
		write_coord(g_iPlayerOrigin[2]) 
		write_byte(20) // Radius
		write_byte(g_aRed[id])
		write_byte(g_aGreen[id]) 
		write_byte(g_aBlue[id]) 
		write_byte(2) 
		write_byte(0) 
		message_end()
	}
}

// Remove aura
public remove_aura(id)
{
	id -= TASK_RESET
	if(is_user_alive(id))
	{
		remove_task(id+TASK_AURA)
		
		// Print the message about the reward is over
		print_colored(id, "!g[CS] !tColored aura is over!") 
	}
}

public native_speed_reward(iPlugin, iParams)
{
	if(iParams != 5)
	{
		log_error(AMX_ERR_NATIVE, "cs_speed_reward native is incorrect. Param count is 5")
		return 0
	}
	
	new HamHook:hHamResetMaxSpeed
	if(!hHamResetMaxSpeed)
	{
		hHamResetMaxSpeed = RegisterHam(Ham_Player_ResetMaxSpeed, "player", "fw_ResetMaxSpeed", 1)
	}
	
	new id = get_param(1)
	
	// Prevent the reward if the player is died
	if(!is_user_alive(id))
		return 0
	
	switch(get_param(2))
	{
		case 0:     
		{
			g_bSpeedBoost[id] = false
			
			#if defined CUSTOM_MESSAGE
			// Print the message about the reward is over
			print_colored(id, "!g[CS] !tSpeed boost is over!")
			#endif
			
			// Update player's maxspeed
			ExecuteHamB(Ham_Player_ResetMaxSpeed, id)
		}
		case 1:
		{
			new g_iAddSpeed = get_param(3)
	
			// Prevent the reward if the values is less than "0"
			if(g_iAddSpeed < 0)
			{
				log_error(AMX_ERR_NATIVE, "cs_speed_reward native is incorrect. g_iAddSpeed must not less than 0")
				return 0
			}
			
			g_iSpeed[id] = g_iAddSpeed
			
			// Prevent the reward when the player is frozen or CS freezetime
			if (pev(id, pev_maxspeed) <= 1)
			{
				print_colored(id, "!g[CS] !tSpeed boost is disabled while frozen!")
				return 0
			}
			else
			{
				g_bSpeedBoost[id] = true
				
				// Update player's maxspeed
				ExecuteHamB(Ham_Player_ResetMaxSpeed, id)
			}
			
			switch(get_param(4))
			{
				case 0:     
				{
					#if defined CUSTOM_MESSAGE
					// Print the message about the reward
					print_colored(id, "!g[CS] !tSpeed boost reward!")
					#endif
				}
				case 1:
				{
					new Float:fSpeedT = get_param_f(5)
	
					// Prevent the reward if the values is less than "0.0"
					if(fSpeedT < 0.0)
					{
						log_error(AMX_ERR_NATIVE, "cs_speed_reward native is incorrect. fSpeedT must not less than 0.0")
						return 0
					}
					
					// Just in case we don't want the duplicate task
					remove_task(id+TASK_RESET)
					
					set_task(fSpeedT, "restore_speed", id+TASK_RESET)
					
					#if defined CUSTOM_MESSAGE
					// Print the message about the duration of the reward
					print_colored(id, "!g[CS] !tSpeed boost reward !yfor %.f seconds!", fSpeedT)
					#endif
				}
				default:
				{
					log_error(AMX_ERR_NATIVE, "cs_speed_reward native is incorrect. iType must not less than 0 or more than 1")
					return 0
				}
			}
		}
		default:
		{
			log_error(AMX_ERR_NATIVE, "cs_speed_reward native is incorrect. iValue must not less than 0 or more than 1")
			return 0
		}
	}
	
	return 1
}

// Restore the speed boost
public restore_speed(id)
{
	id -= TASK_RESET
	if(is_user_alive(id))
	{
		g_bSpeedBoost[id] = false
		
		// Print the message about the reward is over
		print_colored(id, "!g[CS] !tSpeed boost is over!")
		
		// Update player's maxspeed
		ExecuteHamB(Ham_Player_ResetMaxSpeed, id)
	}
}

public native_jump_reward(iPlugin, iParams)
{
	if(iParams != 5)
	{
		log_error(AMX_ERR_NATIVE, "cs_jump_reward native is incorrect. Param count is 5")
		return 0
	}
	
	new HamHook:hHamPlayerJump
	if(!hHamPlayerJump)
	{
		hHamPlayerJump = RegisterHam(Ham_Player_Jump, "player", "fw_PlayerJump", 0)
		register_forward(FM_CmdStart, "fw_CmdStart")
	}
	
	new id = get_param(1)
	
	// Prevent the reward if the player is died
	if(!is_user_alive(id))
		return 0
	
	switch(get_param(2))
	{
		case 0:     
		{
			g_bMultiJump[id] = false
			
			#if defined CUSTOM_MESSAGE
			// Print the message about the reward is over
			print_colored(id, "!g[CS] !tMulti-jump is over!")
			#endif
		}
		case 1:
		{
			new g_iAddJump = get_param(3)
	
			// Prevent the reward if the values is less than "0"
			if(g_iAddJump < 0)
			{
				log_error(AMX_ERR_NATIVE, "cs_jump_reward native is incorrect. g_iAddJump must not less than 0")
				return 0
			}
			
			g_iJump[id] = g_iAddJump
			
			g_bMultiJump[id] = true
			
			switch(get_param(4))
			{
				case 0:     
				{
					#if defined CUSTOM_MESSAGE
					// Print the message about the duration of the reward
					print_colored(id, "!g[CS] !tMulti-jump reward!")
					print_colored(id, "!g[CS] !tFree parachute also given. !yJust press [E] to use it!")
					#endif
				}
				case 1:
				{
					new Float:fJumpT = get_param_f(5)
	
					// Prevent the reward if the values is less than "0.0"
					if(fJumpT < 0.0)
					{
						log_error(AMX_ERR_NATIVE, "cs_jump_reward native is incorrect. fJumpT must not less than 0.0")
						return 0
					}
					
					// Just in case we don't want the duplicate task
					remove_task(id+TASK_RESET)
					
					set_task(fJumpT, "restore_jump", id+TASK_RESET)
					
					#if defined CUSTOM_MESSAGE
					// Print the message about the duration of the reward
					print_colored(id, "!g[CS] !tMulti-jump reward !yfor %.f seconds!", fJumpT)
					print_colored(id, "!g[CS] !tFree parachute also given. !yJust press [E] to use it!")
					#endif
				}
				default:
				{
					log_error(AMX_ERR_NATIVE, "cs_jump_reward native is incorrect. iType must not less than 0 or more than 1")
					return 0
				}
			}
		}
		default:
		{
			log_error(AMX_ERR_NATIVE, "cs_jump_reward native is incorrect. iValue must not less than 0 or more than 1")
			return 0
		}
	}
	
	return 1
}

// Restore the multi-jump
public restore_jump(id)
{
	id -= TASK_RESET
	if(is_user_alive(id))
	{
		g_bMultiJump[id] = false
		
		// Print the message about the reward is over
		print_colored(id, "!g[CS] !tMulti-jump is over!")
	}
}

// Credit to WBYOKOMO for his parachute API. ;)
public fw_CmdStart(id, uc_handle)
{
	if(!g_bMultiJump[id]) 
		return;
	
	static Button, OldButtons;
	Button = get_uc(uc_handle, UC_Buttons);
	OldButtons = pev(id, pev_oldbuttons);
	
	// Free parachute for player that was given multi-jump reward
	if((Button & IN_USE) && (OldButtons & IN_USE))
	{
		static Float:fVelocity[3]; pev(id, pev_velocity, fVelocity);
		if(fVelocity[2] < 0.0)
		{
			fVelocity[2] = -60.0
			set_pev(id, pev_velocity, fVelocity)
		}
	}
}

// Credit to ZP Team
public native_unlimited_reward(iPlugin, iParams)
{
	if(iParams != 4)
	{
		log_error(AMX_ERR_NATIVE, "cs_unlimited_reward native is incorrect. Param count is 4")
		return 0
	}
	
	if(!g_iMsgAmmo)
	{
		register_event("AmmoX", "event_ammo", "be")
		register_message(get_user_msgid("CurWeapon"), "message_cur_weapon")
		
		g_iMsgAmmo = get_user_msgid("AmmoPickup")
	}
	
	new id = get_param(1)
	
	// Prevent the reward if the player is died
	if(!is_user_alive(id))
		return 0
	
	switch(get_param(2))
	{
		case 0:     
		{	
			g_bAllUnlimit[id] = false
			g_bBPUnlimit[id] = false
			
			#if defined CUSTOM_MESSAGE
			// Print the message about the reward is over
			print_colored(id, "!g[CS] !tUnlimited bullet is over!")
			#endif
		}
		case 1:
		{
			g_bAllUnlimit[id] = true
			g_bBPUnlimit[id] = true
			
			switch(get_param(3))
			{
				case 0:
				{
					#if defined CUSTOM_MESSAGE
					// Print the message about the reward
					print_colored(id, "!g[CS] !tUnlimited clip reward!")
					#endif
				}
				case 1:
				{
					new Float:fUnlimitT = get_param_f(4)
	
					// Prevent the reward if the values is less than "0.0"
					if(fUnlimitT < 0.0)
					{
						log_error(AMX_ERR_NATIVE, "cs_unlimited_reward native is incorrect. fUnlimitT must not less than 0.0")
						return 0
					}
							
					// Just in case we don't want the duplicate task
					remove_task(id+TASK_RESET)
					
					set_task(fUnlimitT, "restore_unlimit", id+TASK_RESET)
					
					#if defined CUSTOM_MESSAGE
					// Print the message about the duration of the reward
					print_colored(id, "!g[CS] !tUnlimited bullet reward !yfor %.f seconds!", fUnlimitT)
					#endif
				}
				default:
				{
					log_error(AMX_ERR_NATIVE, "cs_unlimited_reward native is incorrect. iType must not less than 0 or more than 1")
					return 0
				}
			}
		}
		case 2:
		{
			g_bBPUnlimit[id] = true
			
			switch(get_param(3))
			{
				case 0:
				{
					#if defined CUSTOM_MESSAGE
					// Print the message about the reward
					print_colored(id, "!g[CS] !tUnlimited BP ammo reward!")
					#endif
				}
				case 1:
				{
					new Float:fUnlimitT = get_param_f(4)
			
					// Prevent the reward if the values is less than "0.0"
					if(fUnlimitT < 0.0)
					{
						log_error(AMX_ERR_NATIVE, "cs_unlimited_reward native is incorrect. fUnlimitT must not less than 0.0")
						return 0
					}
							
					// Just in case we don't want the duplicate task
					remove_task(id+TASK_RESET)
					
					set_task(fUnlimitT, "restore_unlimit", id+TASK_RESET)
					
					#if defined CUSTOM_MESSAGE
					// Print the message about the duration of the reward
					print_colored(id, "!g[CS] !tUnlimited bullet reward !yfor %.f seconds!", fUnlimitT)
					#endif
				}
				default:
				{
					log_error(AMX_ERR_NATIVE, "cs_unlimited_reward native is incorrect. iType must not less than 0 or more than 1")
					return 0
				}
			}
		}
		default:
		{
			log_error(AMX_ERR_NATIVE, "cs_unlimited_reward native is incorrect. iValue must not less than 0 or more than 2")
			return 0
		}
	}
	
	return 1
}

// Restore the unlimited bullet
public restore_unlimit(id)
{
	id -= TASK_RESET
	if(is_user_alive(id))
	{
		g_bAllUnlimit[id] = false
		g_bBPUnlimit[id] = false
		
		// Print the message about the reward is over
		print_colored(id, "!g[CS] !tUnlimited bullet is over!")
	}
}

// Credit to H.RED.ZONE
public native_norecoil_reward(iPlugin, iParams)
{
	if(iParams != 4)
	{
		log_error(AMX_ERR_NATIVE, "cs_norecoil_reward native is incorrect. Param count is 4")
		return 0
	}
	
	new HamHook:hHamWeaponPrimary
	if(!hHamWeaponPrimary)
	{
		new szWeapon[24]
		for(new i = 1; i <= 30; i++) 
		{
			if (!(WEAPONS_BITSUM & 1 << i) && get_weaponname(i, szWeapon, charsmax(szWeapon))) 
			{
				hHamWeaponPrimary = RegisterHam(Ham_Weapon_PrimaryAttack, szWeapon, "fw_WeaponPrimary_Pre")
				RegisterHam(Ham_Weapon_PrimaryAttack, szWeapon, "fw_WeaponPrimary_Post", 1)
			}
		}
	}
	
	new id = get_param(1)
	
	// Prevent the reward if the player is died
	if(!is_user_alive(id))
		return 0
	
	switch(get_param(2))
	{
		case 0:     
		{	
			g_bNoRecoil[id] = false
			
			#if defined CUSTOM_MESSAGE
			// Print the message about the reward is over
			print_colored(id, "!g[CS] !tNo-recoil is over!")
			#endif
		}
		case 1:
		{
			g_bNoRecoil[id] = true
			
			switch(get_param(3))
			{
				case 0:
				{
					#if defined CUSTOM_MESSAGE
					// Print the message about the reward
					print_colored(id, "!g[CS] !tNo-recoil reward!")
					#endif
				}
				case 1:
				{
					new Float:fRecoilT = get_param_f(4)
	
					// Prevent the reward if the values is less than "0.0"
					if(fRecoilT < 0.0)
					{
						log_error(AMX_ERR_NATIVE, "cs_norecoil_reward native is incorrect. fRecoilT must not less than 0.0")
						return 0
					}
							
					// Just in case we don't want the duplicate task
					remove_task(id+TASK_RESET)
					
					set_task(fRecoilT, "restore_norecoil", id+TASK_RESET)
					
					#if defined CUSTOM_MESSAGE
					// Print the message about the duration of the reward
					print_colored(id, "!g[CS] !tNo-recoil reward !yfor %.f seconds!", fRecoilT)
					#endif
				}
				default:
				{
					log_error(AMX_ERR_NATIVE, "cs_norecoil_reward native is incorrect. iType must not less than 0 or more than 1")
					return 0
				}
			}
		}
		default:
		{
			log_error(AMX_ERR_NATIVE, "cs_norecoil_reward native is incorrect. iValue must not less than 0 or more than 1")
			return 0
		}
	}
	
	return 1
}

// Restore the no-recoil
public restore_norecoil(id)
{
	id -= TASK_RESET
	if(is_user_alive(id))
	{
		g_bNoRecoil[id] = false
		
		// Print the message about the reward is over
		print_colored(id, "!g[CS] !tNo-recoil is over!")
	}
}

// Credit to: https://forums.alliedmods.net/showthread.php?t=14188
// This simulates a sort of ability by drawing a line between you and the enemy
public native_line_reward(iPlugin, iParams)
{
	if(iParams != 6)
	{
		log_error(AMX_ERR_NATIVE, "cs_line_reward native is incorrect. Param count is 6")
		return 0
	}
	
	new id = get_param(1)
	
	// Prevent the reward if the player is died
	if(!is_user_alive(id))
		return 0
	
	switch(get_param(2))
    {
        case 0:     
        {
			remove_task(id+TASK_LINE)
		
			#if defined CUSTOM_MESSAGE
			// Print the message about the reward is over
			print_colored(id, "!g[CS] !tLine drawing ability is over!")
			#endif
		}
		case 1:
		{
			// Just in case we don't want the duplicate task
			remove_task(id+TASK_LINE)
			
			set_task(1.0, "player_line", id+TASK_LINE, _, _, "b")
			
			get_color(g_lRed[id], g_lGreen[id], g_lBlue[id])
			
			g_iFindLine = get_param(4)
			if(g_iFindLine < 0 || g_iFindLine > 1)
			{
				log_error(AMX_ERR_NATIVE, "cs_line_reward native is incorrect. g_iFindLine must not less than 0 or more than 1")
				return 0
			}
			
			switch(get_param(5))
			{
				case 0:     
				{
					#if defined CUSTOM_MESSAGE
					// Print the message about the reward
					print_colored(id, "!g[CS] !tLine drawing ability!")
					#endif
				}
				case 1:
				{
					new Float:fLineT = get_param_f(6)
	
					// Prevent the reward if the values is less than "0.0"
					if(fLineT < 0.0)
					{
						log_error(AMX_ERR_NATIVE, "cs_line_reward native is incorrect. fLineT must not less than 0.0")
						return 0
					}
					
					// Just in case we don't want the duplicate task
					remove_task(id+TASK_RESET)
					
					set_task(fLineT, "remove_line", id+TASK_RESET)
					
					#if defined CUSTOM_MESSAGE
					// Print the message about the duration of the reward
					print_colored(id, "!g[CS] !tLine drawing ability !yfor %.f seconds!", fLineT)
					#endif
				}
				default:
				{
					log_error(AMX_ERR_NATIVE, "cs_line_reward native is incorrect. iType must not less than 0 or more than 1")
					return 0
				}
			}
		}
		default:
		{
			log_error(AMX_ERR_NATIVE, "cs_line_reward native is incorrect. iValue must not less than 0 or more than 1")
			return 0
		}
	}
	
	return 1
}

public player_line(id)
{
	id -= TASK_LINE
	if(is_user_alive(id))
	{	
		get_user_origin(id, g_iPlayerOrigin)
		
		new iPlayers[32] 
		new iPlayerCount, i, tid
		
		get_players(iPlayers, iPlayerCount, "a") 
		for(i = 0; i <= iPlayerCount; i++)
		{
			tid = iPlayers[i]
			
			if(tid == id || !is_user_alive(tid) || cs_get_user_team(tid) == cs_get_user_team(id)) 
				continue
			
			switch(g_iFindLine)
			{
				case 0:
				{
					get_user_origin(tid, g_iOtherOrigin)
					
					message_begin(MSG_ONE, SVC_TEMPENTITY, {0,0,0}, id)
					write_byte(0)
					write_coord(g_iPlayerOrigin[0]) // Starting position
					write_coord(g_iPlayerOrigin[1])
					write_coord(g_iPlayerOrigin[2])
					write_coord(g_iOtherOrigin[0])	// Ending position
					write_coord(g_iOtherOrigin[1])
					write_coord(g_iOtherOrigin[2])
					write_short(g_iLine) // Sprite index
					write_byte(1) // Starting frame
					write_byte(5) // Frame rate
					write_byte(5) // Life
					write_byte(3) // Line width
					write_byte(1) // Noise
					write_byte(g_lRed[id])
					write_byte(g_lGreen[id])
					write_byte(g_lBlue[id])
					write_byte(155)	// Brightness
					write_byte(5) // Scroll speed
					message_end()
				}
				case 1:
				{
					g_iCloseLine = 0
					g_fClosestLine = 9999.0
					
					g_fLine = entity_range(id, tid)
					if(g_fLine < g_fClosestLine)
					{
						g_iCloseLine = tid
						g_fClosestLine = g_fLine
					}
				}
			}
		}
		
		if(g_iCloseLine)
		{
			get_user_origin(g_iCloseLine, g_iOtherOrigin)
			
			message_begin(MSG_ONE, SVC_TEMPENTITY, {0,0,0}, id)
			write_byte(0)
			write_coord(g_iPlayerOrigin[0]) // Starting position
			write_coord(g_iPlayerOrigin[1])
			write_coord(g_iPlayerOrigin[2])
			write_coord(g_iOtherOrigin[0])	// Ending position
			write_coord(g_iOtherOrigin[1])
			write_coord(g_iOtherOrigin[2])
			write_short(g_iLine) // Sprite index
			write_byte(1) // Starting frame
			write_byte(5) // Frame rate
			write_byte(5) // Life
			write_byte(3) // Line width
			write_byte(1) // Noise
			write_byte(g_lRed[id])
			write_byte(g_lGreen[id])
			write_byte(g_lBlue[id])
			write_byte(155)	// Brightness
			write_byte(5) // Scroll speed
			message_end()
		}
	}
}

// Remove line drawing
public remove_line(id)
{
	id -= TASK_RESET
	if(is_user_alive(id))
	{
		remove_task(id+TASK_LINE)
		
		// Print the message about the reward is over
		print_colored(id, "!g[CS] !tLine drawing ability is over!") 
	}
}

// Credit to: https://forums.alliedmods.net/showthread.php?t=14188
// This ability start at enemy feet and expanded outwards into a much larger sort of ring	
public native_ring_reward(iPlugin, iParams)
{
	if(iParams != 6)
	{
		log_error(AMX_ERR_NATIVE, "cs_ring_reward native is incorrect. Param count is 6")
		return 0
	}
	
	new id = get_param(1)
	
	// Prevent the reward if the player is died
	if(!is_user_alive(id))
		return 0
	
	switch(get_param(2))
    {
        case 0:     
        {
			remove_task(id+TASK_RING)
			
			#if defined CUSTOM_MESSAGE
			// Print the message about the reward is over
			print_colored(id, "!g[CS] !tRing indicator ability is over!")
			#endif
		}
		case 1:
		{
			// Just in case we don't want the duplicate task
			remove_task(id+TASK_RING)
			
			set_task(0.5, "player_ring", id+TASK_RING, _, _, "b")
			
			get_color(g_rRed[id], g_rGreen[id], g_rBlue[id])
			
			g_iFindRing = get_param(4)
			if(g_iFindRing < 0 || g_iFindRing > 1)
			{
				log_error(AMX_ERR_NATIVE, "cs_ring_reward native is incorrect. g_iFindRing must not less than 0 or more than 1")
				return 0
			}
			
			switch(get_param(5))
			{
				case 0:     
				{
					#if defined CUSTOM_MESSAGE
					// Print the message about the reward
					print_colored(id, "!g[CS] !tRing indicator ability!")
					#endif
				}
				case 1:
				{
					new Float:fRingT = get_param_f(6)
	
					// Prevent the reward if the values is less than "0.0"
					if(fRingT < 0.0)
					{
						log_error(AMX_ERR_NATIVE, "cs_ring_reward native is incorrect. fRingT must not less than 0.0")
						return 0
					}
					
					// Just in case we don't want the duplicate task
					remove_task(id+TASK_RESET)
					
					set_task(fRingT, "remove_ring", id+TASK_RESET)
					
					#if defined CUSTOM_MESSAGE
					// Print the message about the duration of the reward
					print_colored(id, "!g[CS] !tRing indicator ability !yfor %.f seconds!", fRingT)
					#endif
				}
				default:
				{
					log_error(AMX_ERR_NATIVE, "cs_ring_reward native is incorrect. iType must not less than 0 or more than 1")
					return 0
				}
			}
		}
		default:
		{
			log_error(AMX_ERR_NATIVE, "cs_ring_reward native is incorrect. iValue must not less than 0 or more than 1")
			return 0
		}
	}
	
	return 1
}

public player_ring(id)
{
	id -= TASK_RING
	if(is_user_alive(id))
	{			
		new iPlayers[32] 
		new iPlayerCount, i, tid
		
		get_players(iPlayers, iPlayerCount, "a") 
		for(i = 0; i <= iPlayerCount; i++)
		{
			tid = iPlayers[i]
			
			if(tid == id || !is_user_alive(tid) || cs_get_user_team(tid) == cs_get_user_team(id)) 
				continue
			
			switch(g_iFindRing)
			{
				case 0:
				{
					get_user_origin(tid, g_iOtherOrigin)
				
					message_begin(MSG_ONE, SVC_TEMPENTITY, {0,0,0}, id)
					write_byte(20)
					write_coord(g_iOtherOrigin[0])	// Center position
					write_coord(g_iOtherOrigin[1])
					write_coord(g_iOtherOrigin[2] - 35)	
					write_coord(g_iOtherOrigin[0])
					write_coord(g_iOtherOrigin[1])
					write_coord(g_iOtherOrigin[2] + 400)
					write_short(g_iRing) // Sprite index
					write_byte(1) // Starting frame
					write_byte(5) // Frame rate
					write_byte(6) // Life
					write_byte(8) // Line width
					write_byte(1) // Noise	
					write_byte(g_rRed[id])
					write_byte(g_rGreen[id])
					write_byte(g_rBlue[id]) 
					write_byte(155)	// Brightness
					write_byte(0) // Scroll speed
					message_end()
				}
				case 1:
				{
					g_iCloseRing = 0
					g_fClosestRing = 9999.0
					
					g_fRing = entity_range(id, tid)
					if(g_fRing < g_fClosestRing)
					{
						g_iCloseRing = tid
						g_fClosestRing = g_fRing
					}
				}
			}
		}
		
		if(g_iCloseRing)
		{
			get_user_origin(g_iCloseRing, g_iOtherOrigin)
			
			message_begin(MSG_ONE, SVC_TEMPENTITY, {0,0,0}, id)
			write_byte(20)
			write_coord(g_iOtherOrigin[0])	// Center position
			write_coord(g_iOtherOrigin[1])
			write_coord(g_iOtherOrigin[2] - 35)	
			write_coord(g_iOtherOrigin[0])
			write_coord(g_iOtherOrigin[1])
			write_coord(g_iOtherOrigin[2] + 400)
			write_short(g_iRing) // Sprite index
			write_byte(1) // Starting frame
			write_byte(5) // Frame rate
			write_byte(6) // Life
			write_byte(8) // Line width
			write_byte(1) // Noise
			write_byte(g_rRed[id])
			write_byte(g_rGreen[id])
			write_byte(g_rBlue[id])
			write_byte(155)	// Brightness
			write_byte(0) // Scroll speed
			message_end()
		}
	}
}

// Remove ring indicator
public remove_ring(id)
{
	id -= TASK_RESET
	if(is_user_alive(id))
	{
		remove_task(id+TASK_RING)
		
		// Print the message about the reward is over
		print_colored(id, "!g[CS] !tRing indicator ability is over!") 
	}
}

public native_trail_reward(iPlugin, iParams)
{
	if(iParams != 5)
	{
		log_error(AMX_ERR_NATIVE, "cs_trail_reward native is incorrect. Param count is 5")
		return 0
	}
	
	new id = get_param(1)
	
	// Prevent the reward if the player is died
	if(!is_user_alive(id))
		return 0
	
	switch(get_param(2))
    {
        case 0:     
        {
			remove_task(id+TASK_TRAIL)
			
			message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
			write_byte(TE_KILLBEAM)
			write_short(id)
			message_end()
			
			#if defined CUSTOM_MESSAGE
			// Print the message about the reward is over
			print_colored(id, "!g[CS] !tTrail is over!")
			#endif
		}
		case 1:
		{
			// Just in case we don't want the duplicate task
			remove_task(id+TASK_TRAIL)
			
			set_task(3.0, "player_trail", id+TASK_TRAIL, _, _, "b")
			
			get_color(g_tRed[id], g_tGreen[id], g_tBlue[id])
			
			switch(get_param(4))
			{
				case 0:     
				{
					#if defined CUSTOM_MESSAGE
					// Print the message about the reward
					print_colored(id, "!g[CS] !tTrail reward!")
					#endif
				}
				case 1:
				{
					new Float:fTrailT = get_param_f(5)
	
					// Prevent the reward if the values is less than "0.0"
					if(fTrailT < 0.0)
					{
						log_error(AMX_ERR_NATIVE, "cs_trail_reward native is incorrect. fTrailT must not less than 0.0")
						return 0
					}
					
					// Just in case we don't want the duplicate task
					remove_task(id+TASK_RESET)
					
					set_task(fTrailT, "remove_trail", id+TASK_RESET)
					
					#if defined CUSTOM_MESSAGE
					// Print the message about the duration of the reward
					print_colored(id, "!g[CS] !tTrail reward !yfor %.f seconds!", fTrailT)
					#endif
				}
				default:
				{
					log_error(AMX_ERR_NATIVE, "cs_trail_reward native is incorrect. iType must not less than 0 or more than 1")
					return 0
				}
			}
		}
		default:
		{
			log_error(AMX_ERR_NATIVE, "cs_trail_reward native is incorrect. iValue must not less than 0 or more than 1")
			return 0
		}
	}
	
	return 1
}

public player_trail(id)
{
	id -= TASK_TRAIL
	if(is_user_alive(id))
	{			
		message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
		write_byte(TE_BEAMFOLLOW)
		write_short(id);
		write_short(g_iTrail)
		write_byte(15) // Life 0.1's
		write_byte(5) // Line width in 0.1's 
		write_byte(g_tRed[id])
		write_byte(g_tGreen[id])
		write_byte(g_tBlue[id])
		write_byte(150) // Brightness
		message_end()
	}
}

// Remove trail
public remove_trail(id)
{
	id -= TASK_RESET
	if(is_user_alive(id))
	{
		remove_task(id+TASK_TRAIL)
		
		message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
		write_byte(TE_KILLBEAM)
		write_short(id)
		message_end()
		
		// Print the message about the reward is over
		print_colored(id, "!g[CS] !tTrail is over!") 
	}
}

public native_gravity_reward(iPlugin, iParams)
{
	if(iParams != 5)
	{
		log_error(AMX_ERR_NATIVE, "cs_gravity_reward native is incorrect. Param count is 5")
		return 0
	}
	
	new id = get_param(1)
	
	// Prevent the reward if the player is died
	if(!is_user_alive(id))
		return 0
	
	if(!g_bLow[id])
	{
		g_bLow[id] = true
	}
	
	switch(get_param(2))
    {
        case 0:     
        {
			set_user_gravity(id, 1.0)
			
			g_bLow[id] = false
			
			#if defined CUSTOM_MESSAGE
			// Print the message about the reward is over
			print_colored(id, "!g[CS] !tCustom gravity is over!")
			#endif
		}
		case 1:
		{
			new Float:g_iAddLow = get_param_f(3)
	
			// Prevent the reward if the values is less than "0.0"
			if(g_iAddLow < 0.0)
			{
				log_error(AMX_ERR_NATIVE, "cs_gravity_reward native is incorrect. g_iAddLow must not less than 0.0")
				return 0
			}
			
			set_user_gravity(id, g_iAddLow)
			
			switch(get_param(4))
			{
				case 0:     
				{
					#if defined CUSTOM_MESSAGE
					// Print the message about the reward
					print_colored(id, "!g[CS] !tCustom gravity reward!")
					#endif
				}
				case 1:
				{
					new Float:fLowT = get_param_f(5)
	
					// Prevent the reward if the values is less than "0.0"
					if(fLowT < 0.0)
					{
						log_error(AMX_ERR_NATIVE, "cs_gravity_reward native is incorrect. fLowT must not less than 0.0")
						return 0
					}
					
					// Just in case we don't want the duplicate task
					remove_task(id+TASK_RESET)
					
					set_task(fLowT, "restore_gravity", id+TASK_RESET)
					
					#if defined CUSTOM_MESSAGE
					// Print the message about the duration of the reward
					print_colored(id, "!g[CS] !tCustom gravity !yfor %.f seconds!", fLowT)
					#endif
				}
				default:
				{
					log_error(AMX_ERR_NATIVE, "cs_gravity_reward native is incorrect. iType must not less than 0 or more than 1")
					return 0
				}
			}
		}
		default:
		{
			log_error(AMX_ERR_NATIVE, "cs_gravity_reward native is incorrect. iValue must not less than 0 or more than 1")
			return 0
		}
	}
	
	return 1
}

// Restore gravity
public restore_gravity(id)
{
	id -= TASK_RESET
	if(is_user_alive(id))
	{
		set_user_gravity(id, 1.0)
		
		g_bLow[id] = false
		
		#if defined CUSTOM_MESSAGE
		// Print the message about the reward is over
		print_colored(id, "!g[CS] !tCustom gravity is over!")
		#endif
	}
}

// Credit to Xalus
public native_wall_reward(iPlugin, iParams)
{
	if(iParams != 4)
	{
		log_error(AMX_ERR_NATIVE, "cs_wall_reward native is incorrect. Param count is 4")
		return 0
	}
	
	new hRegisterTouch
	if(!hRegisterTouch)
	{
		hRegisterTouch = register_touch("worldspawn", "player", "fw_TouchWall")
		register_touch("func_brush", "player", "fw_TouchWall")
		register_touch("func_breakable", "player", "fw_TouchWall")
	}
	
	new id = get_param(1)
	
	// Prevent the reward if the player is died
	if(!is_user_alive(id))
		return 0
	
	switch(get_param(2))
    {
        case 0:     
        {	
			g_bWall[id] = false
			
			#if defined CUSTOM_MESSAGE
			// Print the message about the reward is over
			print_colored(id, "!g[CS] !tWall ability is over!")
			#endif
		}
		case 1:
		{
			g_bWall[id] = true
			
			switch(get_param(3))
			{
				case 0:     
				{
					#if defined CUSTOM_MESSAGE
					// Print the message about the reward
					print_colored(id, "!g[CS] !tWall ability!")
					#endif
				}
				case 1:
				{
					new Float:fWallT = get_param_f(4)
	
					// Prevent the reward if the values is less than "0.0"
					if(fWallT < 0.0)
					{
						log_error(AMX_ERR_NATIVE, "cs_wall_reward native is incorrect. fWallT must not less than 0.0")
						return 0
					}
					
					// Just in case we don't want the duplicate task
					remove_task(id+TASK_RESET)
					
					set_task(fWallT, "remove_wall", id+TASK_RESET)
					
					#if defined CUSTOM_MESSAGE
					// Print the message about the duration of the reward
					print_colored(id, "!g[CS] !tWall ability !yfor %.f seconds!", fWallT)
					#endif
				}
				default:
				{
					log_error(AMX_ERR_NATIVE, "cs_wall_reward native is incorrect. iType must not less than 0 or more than 1")
					return 0
				}
			}
		}
		default:
		{
			log_error(AMX_ERR_NATIVE, "cs_wall_reward native is incorrect. iValue must not less than 0 or more than 1")
			return 0
		}
	}
	
	return 1
}

// Remove wall
public remove_wall(id)
{
	id -= TASK_RESET
	if(is_user_alive(id))
	{
		g_bWall[id] = false
		
		#if defined CUSTOM_MESSAGE
		// Print the message about the reward is over
		print_colored(id, "!g[CS] !tWall ability is over!")
		#endif
	}
}

public event_new_round()
{
	new iPlayers[32] 
	new iPlayerCount, i, id
	get_players(iPlayers, iPlayerCount, "ch") 
	
	for(i = 0; i < iPlayerCount; i++)
	{
		id = iPlayers[i]
		ResetAlls(id)
	}
}

public client_disconnect(id)
{
	ResetAlls(id)
}

public fw_PlayerRespawn(id)
{
	ResetAlls(id)
}

public fw_PlayerKilled(id)
{
	ResetAlls(id)
}

public fw_HeadShot(victim, attacker, Float:damage, direction[3], traceresult, dmgbits)
{
	if(attacker == victim || !is_user_alive(attacker))
		return HAM_IGNORED
	
	if(g_bHeadShot[attacker])
	{
		set_tr2(traceresult, TR_iHitgroup, HIT_HEAD)
	}
	
	return HAM_IGNORED
}

public fw_ResetMaxSpeed(id)
{
	if (!is_user_alive(id) || !g_bSpeedBoost[id])
		return;
	
	// Apply speed boost
	set_user_maxspeed(id, get_user_maxspeed(id) + g_iSpeed[id])
}

// Credits to Connor
public fw_PlayerJump(id) 
{
	// If is user alive.
	if(is_user_alive(id) && g_bMultiJump[id]) 
	{
		// Pev flags
		new Flags = pev(id, pev_flags)
		
		// If user jumps out of the water.
		if(Flags & FL_WATERJUMP 
		
		// or if water level is 2 or more (Submerged)
		|| pev(id, pev_waterlevel) >= 2 
		
		// If button not pressed
		|| !(get_pdata_int(id, m_afButtonPressed, linux_diff, mac_diff) & IN_JUMP))
		{
			// Return ham ignore
			return HAM_IGNORED
		}
		// If user is on the ground
		if(Flags & FL_ONGROUND) 
		{
			// Jump count is set to 0
			g_iJumpCount[id] = 0
			
			return HAM_IGNORED
		}
	
		// If multi-jump is on
		if(g_iJump[id] > 0) 
		{
			// If Private data from fall velocity is lower then 500
			if(get_pdata_float(id, m_flFallVelocity, linux_diff, mac_diff) < 500
			
			// and jump counts added lower or same as multi jump count
			&& ++g_iJumpCount[id] <= g_iJump[id]) 
			{
				// Set velocity
				new Float:fVelocity[ 3 ]
				pev( id, pev_velocity, fVelocity )
				fVelocity[ 2 ] = 268.328157
				set_pev( id, pev_velocity, fVelocity )
				
				return HAM_HANDLED
			}
		}
	}

	return HAM_IGNORED
}

public fw_WeaponPrimary_Pre(entity) 
{
	// Id is entity
	new id = pev( entity, pev_owner )

	if(is_valid_ent(entity) && g_bNoRecoil[id]) 
	{
		// Pev set angle
		pev(id, pev_punchangle, g_fPushAngle[id])
	}
}

public fw_WeaponPrimary_Post(entity) 
{
	// Id is entity
	new id = pev(entity, pev_owner)

	if(is_valid_ent(entity) && g_bNoRecoil[id]) 
	{
		// Push float
		new Float:g_fPush[3]
		
		// Pev Angle
		pev(id, pev_punchangle, g_fPush)
		
		// xs Angles.
		xs_vec_sub(g_fPush, g_fPushAngle[id], g_fPush)
		xs_vec_mul_scalar(g_fPush, 0.0, g_fPush)
		xs_vec_add(g_fPush, g_fPushAngle[id], g_fPush)
		set_pev(id, pev_punchangle, g_fPush)
	}
}

// Credit to Xalus
public fw_TouchWall(entity, id)
{
	if(is_user_alive(id) && g_bWall[id])
	{
		if(g_fWall[id] < get_gametime())
		{
			set_behind_wall(id)
		}
		else
		{
			set_hudmessage(random_num(10,255), random(256), random(256), -1.0, 0.15, 0, 1.0, 1.0);
			show_hudmessage(id, "Please wait to penetrate again!")
		}
	}
}

// Credit to ZP Team
// BP Ammo update
public event_ammo(id)
{
	// Not alive or not human
	if (!is_user_alive(id) && !g_bBPUnlimit[id])
		return;
	
	// This is to get ammo type
	new type = read_data(1)
	if (type >= sizeof AMMOWEAPON)
		return;
	
	// This is to get weapon's id
	new weapon = AMMOWEAPON[type]
	
	// Primary and secondary only
	if (MAXBPAMMO[weapon] <= 2)
		return;
	
	// This is to get ammo amount
	new amount = read_data(2)
	
	// Unlimited BP ammo
	if (amount < MAXBPAMMO[weapon])
	{
		// The BP Ammo refill code causes the engine to send a message, but we
		// can't have that in this forward or we risk getting some recursion bugs.
		// For more info see: https://bugs.alliedmods.net/show_bug.cgi?id=3664
		new args[1]
		args[0] = weapon
		set_task(0.1, "refill_bpammo", id, args, sizeof args)
	}
}

// Refill BP ammo
public refill_bpammo(const args[], id)
{
	// Player died or 
	if (!is_user_alive(id) || !g_bBPUnlimit[id])
		return;
	
	new g_iStatus = get_msg_block(g_iMsgAmmo)
	set_msg_block(g_iMsgAmmo, BLOCK_ONCE)
	
	ExecuteHamB(Ham_GiveAmmo, id, MAXBPAMMO[REFILL_WEAPONID], AMMOTYPE[REFILL_WEAPONID], MAXBPAMMO[REFILL_WEAPONID])
	set_msg_block(g_iMsgAmmo, g_iStatus)
}

// Current weapon info
public message_cur_weapon(msg_id, msg_dest, msg_entity)
{
	// Not alive
	if (!is_user_alive(msg_entity) || !g_bAllUnlimit[msg_entity])
		return
	
	// Not an active weapon
	if (get_msg_arg_int(1) != 1)
		return;
	
	// This is to get weapon's id
	new weapon = get_msg_arg_int(2)
	
	// Primary and secondary only
	if (MAXBPAMMO[weapon] <= 2)
		return;
	
	// Max out clip ammo
	new weapon_ent = fm_cs_get_current_weapon_ent(msg_entity)
	if (pev_valid(weapon_ent)) cs_set_weapon_ammo(weapon_ent, MAXCLIP[weapon])
	
	// HUD should show full clip all the time
	set_msg_arg_int(3, get_msg_argtype(3), MAXCLIP[weapon])
}

// This is to get user current weapon entity
stock fm_cs_get_current_weapon_ent(id)
{
	// Prevent server crash if entity's private data not initalized
	return (pev_valid(id) == pdata_safe) ? get_pdata_cbase(id, m_pActiveItem, linux_diff, mac_diff) : 0
}

// Credit to Xalus
stock set_behind_wall(id)
{
	new Float:flOrigin[4][3], Float:flAngle[3]
	
	pev(id, pev_origin, flOrigin[0])
	pev(id, pev_v_angle, flAngle)
	
	flAngle[0] = -10.0
	
	origin_in_front(flAngle, flOrigin[0], 100.0, flOrigin[1])
	
	engfunc(EngFunc_TraceLine, flOrigin[0], flOrigin[1], DONT_IGNORE_MONSTERS, id, g_iTrace)
	get_tr2(g_iTrace, TR_vecEndPos, flOrigin[2])
	
	if(get_distance_f(flOrigin[0], flOrigin[2]) > 17.0)
	{
		set_hudmessage(random_num(10,255), random(256), random(256), -1.0, 0.20, 0, 1.0, 1.0);
		show_hudmessage(id, "This wall cannot be penetrable! ^nJust find another wall!")
		return 0
	}
	
	engfunc(EngFunc_TraceLine, flOrigin[1], flOrigin[0], DONT_IGNORE_MONSTERS, id, g_iTrace)
	get_tr2(g_iTrace, TR_vecEndPos, flOrigin[3])
	
	origin_in_front(flAngle, flOrigin[3], 16.55, flOrigin[3])
	
	if(is_hull_vacant(flOrigin[3], pev(id, pev_flags) & FL_DUCKING ? HULL_HEAD : HULL_HUMAN))
	{	
		xs_vec_copy(flOrigin[3], flOrigin[1])
		flOrigin[1][2] -= 1000.0
		
		engfunc(EngFunc_TraceLine, flOrigin[3], flOrigin[1], IGNORE_MONSTERS, id, g_iTrace)
		get_tr2(g_iTrace, TR_vecEndPos, flOrigin[1])
		
		if(get_distance_f(flOrigin[3], flOrigin[1]) > 150.0)
		{
			set_hudmessage(random_num(10,255), random(256), random(256), -1.0, 0.25, 0, 1.0, 1.0);
			show_hudmessage(id, "Ability is restriced as wall is too high!")
			return 0
		}
		
		engfunc(EngFunc_SetOrigin, id, flOrigin[3])
	}
	
	g_fWall[id] = (get_gametime() + 0.7)
	
	return 1
}

// Credit to Exolent. ;)
stock origin_in_front( Float:vAngles[3], Float:vecOrigin[ 3 ], Float:flDistance, Float:vecOutput[ 3 ] )
{
	new Float:vecAngles[3]
	xs_vec_copy(vAngles, vecAngles)
	
	engfunc( EngFunc_MakeVectors, vecAngles );
	global_get( glb_v_forward, vecAngles );
	
	xs_vec_mul_scalar( vecAngles, flDistance, vecAngles );
	
	xs_vec_add( vecOrigin, vecAngles, vecOutput );
}

stock bool:is_hull_vacant(const Float:origin[3], hull) 
{
	engfunc(EngFunc_TraceHull, origin, origin, IGNORE_MONSTERS, hull, 0, g_iTrace)
	if (!get_tr2(g_iTrace, TR_StartSolid) && !get_tr2(g_iTrace, TR_AllSolid) && get_tr2(g_iTrace, TR_InOpen))
	{
		return true
	}
    
	return false
}

stock get_color(&iRed, &iGreen, &iBlue) 
{
	new g_iColor[20]
	new g_Red[5], g_Green[5], g_Blue[5]
	
	get_string(3, g_iColor, charsmax(g_iColor))
	parse(g_iColor, g_Red, charsmax(g_Red), g_Green, charsmax(g_Green), g_Blue, charsmax(g_Blue))
	
	iRed = str_to_num(g_Red)
	iGreen = str_to_num(g_Green)
	iBlue = str_to_num(g_Blue)
}

stock print_colored(const index, const input [ ], const any:...)
{ 
	new message[191]
	vformat(message, 190, input, 3)
	replace_all(message, 190, "!y", "^1")
	replace_all(message, 190, "!t", "^3")
	replace_all(message, 190, "!g", "^4")

	if(index)
	{
		// Print to single person
		message_begin(MSG_ONE_UNRELIABLE, g_iMsgSayTxt, _, index)
		write_byte(index)
		write_string(message)
		message_end()
	}
	else
	{
		// Print to all players
		new players[32], count, i, id
		get_players(players, count, "ch")
		for( i = 0; i < count; i ++ )
		{
			id = players[i]
			if(!is_user_alive(id)) continue;

			message_begin(MSG_ONE_UNRELIABLE, g_iMsgSayTxt, _, id)
			write_byte(id)
			write_string(message)
			message_end()
		}
	}
}

ResetAlls(id)
{
	g_bHeadShot[id] = false
	g_bSpeedBoost[id] = false
	g_bMultiJump[id] = false
	g_bAllUnlimit[id] = false
	g_bBPUnlimit[id] = false
	g_bNoRecoil[id] = false
	g_bWall[id] = false
	
	if(g_bRender[id])
	{
		set_user_rendering(id)
		g_bRender[id] = false
	}
	
	if(g_bLow[id])
	{
		set_user_gravity(id, 1.0)
		g_bLow[id] = false
	}
	
	remove_task(id+TASK_INVI)
	remove_task(id+TASK_NOCLIP)
	remove_task(id+TASK_HEADSHOT)
	remove_task(id+TASK_GODMODE)
	remove_task(id+TASK_GLOW)
	remove_task(id+TASK_AURA)
	remove_task(id+TASK_LINE)
	remove_task(id+TASK_RING)
	remove_task(id+TASK_TRAIL)
	remove_task(id+TASK_RESET)
}  