/*		
		Copyright © 2015, zmd94.

		This plugin is free software;
		you can redistribute it and/or modify it under the terms of the
		GNU General Public License as published by the Free Software Foundation.

		This program is distributed in the hope that it will be useful,
		but WITHOUT ANY WARRANTY; without even the implied warranty of
		MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
		GNU General Public License for more details.
*/

#include <amxmodx>
#include <fakemeta>
#include <hamsandwich>
#include <cstrike> 
#include <engine>
#include <fun>

#define MAXPLAYERS 32

// BP ammo refill
#define REFILL_WEAPONID args[0]

// Weapons Offsets
#define XO_WEAPONS 4
#define m_iId 43
#define m_flNextPrimaryAttack 46
#define m_flNextSecondaryAttack 47

#define m_flNextSpecButtonTime 100
#define m_fDeadTime 354

// Players Offsets
#define XO_PLAYER 5

#define flag_get(%1,%2) (%1 & (1 << (%2 & 31)))
#define flag_get_boolean(%1,%2) (flag_get(%1,%2) ? true : false)
#define flag_set(%1,%2) %1 |= (1 << (%2 & 31))
#define flag_unset(%1,%2) %1 &= ~(1 << (%2 & 31))

enum (+= 123)
{
	TASK_HUD = 1234,
	TASK_VOTE,
	TASK_RESPAWN
}

enum _:TOTAL_FORWARDS
{
	FW_WAR_ROUND_START = 0,
	FW_WAR_ROUND_END,
	FW_WAR_VOTE_START,
	FW_WAR_VOTE_END,
	FW_WAR_SPAWN_POST,
}

enum _:WEAPONSWAR
{
	WeaponType[64],
	WeaponName[64],
	WeaponID[64],
	WeaponIndex
}

// Weapon IDs for ammo types
new const WEAPONID[] = { 0, CSW_AWP, CSW_SCOUT, CSW_M249, CSW_AUG, CSW_XM1014, CSW_MAC10, CSW_FIVESEVEN, CSW_DEAGLE,
			CSW_P228, CSW_ELITE, CSW_FLASHBANG, CSW_HEGRENADE, CSW_SMOKEGRENADE, CSW_C4 }
			
// Ammo type names for weapons
new const AMMOTYPE[][] = { "", "357sig", "", "762nato", "", "buckshot", "", "45acp", "556nato", "", "9mm", "57mm", "45acp",
	"556nato", "556nato", "556nato", "45acp", "9mm", "338magnum", "9mm", "556natobox", "buckshot",
	"556nato", "9mm", "762nato", "", "50ae", "556nato", "762nato", "", "57mm" }

// Max BP ammo for weapons
new const MAXBPAMMO[] = { -1, 52, -1, 90, 1, 32, 1, 100, 90, 1, 120, 100, 100, 90, 90, 90, 100, 120,
	30, 120, 200, 32, 90, 120, 90, 2, 35, 90, 90, -1, 100 }
	
new const m_rgpPlayerItems_CWeaponBox[6] = {34,35,...}
new const WeaponsData[][WEAPONSWAR] =
{
	{"Hand-gun", "9x19mm Side-arm", "weapon_glock18", CSW_GLOCK18}, 
	{"Hand-gun", "KM.45 Tactical", "weapon_usp", CSW_USP}, 
	{"Hand-gun", "228 Compact", "weapon_p228", CSW_P228},
	{"Hand-gun", "Night Haw2.50c", "weapon_deagle", CSW_DEAGLE}, 
	{"Hand-gun", "Elites", "weapon_elite", CSW_ELITE}, 
	{"Hand-gun", "Five-Seven", "weapon_fiveseven", CSW_FIVESEVEN},
	{"Shotgun", "12 gauge", "weapon_m3", CSW_M3}, 
	{"Shotgun", "Auto-Shotgun", "weapon_xm1014", CSW_XM1014},
	{"Sub-machine", "TMP", "weapon_tmp", CSW_TMP},
	{"Sub-machine", "MP5-Navy", "weapon_mp5navy", CSW_MP5NAVY},
	{"Sub-machine", "KM-UMP45", "weapon_ump45", CSW_UMP45},
	{"Sub-machine", "ES-C90", "weapon_p90", CSW_P90},
	{"Sub-machine", "Ingram MAC-10", "weapon_mac10", CSW_MAC10},
	{"Rifles", "IDF-Defender", "weapon_galil", CSW_GALIL},
	{"Rifles", "Famas", "weapon_famas", CSW_FAMAS},
	{"Rifles", "AK-47", "weapon_ak47", CSW_AK47},
	{"Rifles", "M4A1", "weapon_m4a1", CSW_M4A1},
	{"Rifles", "Scout", "weapon_scout", CSW_SCOUT},
	{"Rifles", "Ster-Aug", "weapon_aug", CSW_AUG },
	{"Rifles", "Krieg 552", "weapon_sg552", CSW_SG552},
	{"Rifles", "Krieg 550", "weapon_sg550", CSW_SG550},
	{"Rifles", "Magnum", "weapon_awp", CSW_AWP},
	{"Rifles", "D3/AU-1", "weapon_g3sg1", CSW_G3SG1},
	{"Heavy", "Machine-gun", "weapon_m249", CSW_M249},
	{"Melee", "Knife", "weapon_knife", CSW_KNIFE},
	{"Nade", "HE grenade", "weapon_hegrenade", CSW_HEGRENADE}
}

// Bool
new bool:g_bInWar
new bool:g_bHEWar
new bool:g_bStartWar
new bool:g_bVote
new bool:g_bLastRoundIsWar
new bool:g_bJustDrop[MAXPLAYERS+1], bool:g_bBPUnlimit[MAXPLAYERS+1]

// Float
new Float:g_iCHudXPosition
new Float:g_iCHudYPosition

// String
new g_sAdminFlag, g_sCurrentFlag[15]
new g_sWeaponWar[32], g_sWeaponID[32]
new g_sLastWar[32]

// Variables
new g_WeaponIndex
new g_ForwardResult
new g_Forwards[TOTAL_FORWARDS]

new g_iPoints[MAXPLAYERS+1]
new g_iAllVote[MAXPLAYERS+1]
new g_iVotes[2]
new g_iVoteMenu

new g_WarMenu, g_isPointLeader
new g_iAllowWarStart, g_iAllowWarVote
new g_iVotingTime, g_iBullet
new g_iShowHud, g_iXPosition, g_iYPosition, g_iHudColors
new g_iPointLeader, g_iPointBonus, g_iBonusAmount
new g_iAutoWarVote, g_iVoteCountdown, g_iAutoWarStart, g_iWarCountdown
new g_iVoteDelay, g_iWarDelay, g_iWeaponDrop
new g_iAutoRespawn, g_iStripWeapon, g_iNoShield 
new g_iKillerView, g_iBlockChangeViewTime, g_iKillerViewFade, g_iSpecMode

new g_iMsgSayTxt, g_iSyncHud, g_iMsgScreenFade, g_iMsgAmmo

public plugin_init() 
{
	register_plugin("Weapons War", "7.0", "zmd94")
	
	register_dictionary("cs_war.txt")
	
	register_clcmd("drop", "cs_war_drop")
	
	register_clcmd("say /ww", "cs_war_start")
	register_clcmd("say_team /ww", "cs_war_start")
	register_clcmd("say /wvote", "cs_war_vote")
	register_clcmd("say_team /wvote", "cs_war_vote")
	
	register_event("HLTV", "cs_war_new_round", "a", "1=0", "2=0")
	register_event("TextMsg", "cs_war_restart", "a", "2&#Game_C", "2&#Game_w")	
	register_event("CurWeapon", "cs_war_CurWeapon", "be", "1=1")
	register_event("AmmoX", "cs_war_ammo", "be")
	
	register_logevent("cs_war_round_start", 2, "1=Round_Start")
	register_logevent("cs_war_round_end", 2, "1=Round_End") 
	
	RegisterHam(Ham_Spawn, "player", "cs_war_PlayerRespawn", 1)
	RegisterHam(Ham_Killed, "player", "cs_war_PlayerKilled", 1)
	
	new szWeapon[20]
	for(new i; i < sizeof(WeaponsData); i++)
	{
		copy(szWeapon, charsmax(szWeapon), WeaponsData[i][WeaponID])
		RegisterHam(Ham_Item_Deploy, szWeapon, "cs_war_WeaponsDeploy", true)
	}
	
	register_touch("weaponbox", "player", "cs_war_WeaponBox")
	register_touch("weapon_shield", "player", "cs_war_Shield")
	
	///////////////////////////////////////////////////////////////////////////////////////////////////////
	//             If you want to allow custom war round, please disable below option. ;)                //
	///////////////////////////////////////////////////////////////////////////////////////////////////////
	g_iAutoWarVote = register_cvar("ww_auto_vote", "0") // Allow auto war vote
	g_iAutoWarStart = register_cvar("ww_auto_war", "0") // Allow auto war start
	///////////////////////////////////////////////////////////////////////////////////////////////////////
	g_sAdminFlag = register_cvar("ww_admin_flag", "j") // Configure access flag to open war menu and start vote command. ;)
	g_iAllowWarStart = register_cvar("ww_allow_war_start", "1") // Allow admin to start custom war round
	g_iAllowWarVote = register_cvar("ww_allow_war_vote", "1") // Allow admin to start custom war vote
	g_iVoteDelay = register_cvar("ww_vote_delay", "2") // Amount of round delay for auto war vote
	g_iWarDelay = register_cvar("ww_war_delay", "3") // Amount of round delay for auto war start
	g_iWeaponDrop = register_cvar("ww_weapon_drop", "1") // 0; Prevent players to drop any weapons || 1; Allow players to drop current war weapon
	g_iBullet = register_cvar("ww_allow_bullet", "0") // Allow player to have unlimited bullet
	g_iShowHud = register_cvar("ww_show_war_hud", "1") // Show current war round. ;)
	g_iXPosition = register_cvar("ww_hud_X_position", "0.75") // X Position ( --- )
	g_iYPosition = register_cvar("ww_hud_Y_position", "0.20") // Y Position ( ||| )
	g_iHudColors = register_cvar("ww_hud_colors", "0 255 0") // Hud colors 
	g_iVotingTime = register_cvar("ww_vote_time", "30") // Time for vote
	g_iPointLeader = register_cvar("ww_point_leader", "1") // Enable showing point leader
	g_iPointBonus = register_cvar("ww_leader_bonus", "1") // Enable point leader bonus
	g_iBonusAmount = register_cvar("ww_bonus_amount", "2000") // Amount of money given
	g_iAutoRespawn = register_cvar("ww_allow_respawn", "1") // Allow auto respawn during war round
	g_iStripWeapon = register_cvar("ww_strip_weapon", "0") // Strip player weapon during war at the end of round 
	g_iNoShield  = register_cvar("ww_no_shield", "1") // Prevent player from getting shield on floor
	g_iKillerView = register_cvar("ww_allow_killer_view", "1") // Allow players see themselves dying from killer's view
	g_iBlockChangeViewTime = register_cvar("ww_buttons_delay", "2.0") // Delay before which player won't be able to switch spec view/target with mouse buttons
	g_iSpecMode = register_cvar("ww_spec_mode", "0") // 0; Third person view || 1; First person view
	g_iKillerViewFade = register_cvar("ww_fade_color", "030000000180") // Color and alpha of fade effect. RRR is red, GGG is green, BBB is blue and AAA is alpha
	
	// Forwards
	g_Forwards[FW_WAR_ROUND_START] = CreateMultiForward("cs_fw_war_start", ET_IGNORE)
	g_Forwards[FW_WAR_ROUND_END] = CreateMultiForward("cs_fw_war_end", ET_IGNORE)
	g_Forwards[FW_WAR_VOTE_START] = CreateMultiForward("cs_fw_vote_start", ET_IGNORE)
	g_Forwards[FW_WAR_VOTE_END] = CreateMultiForward("cs_fw_vote_end", ET_IGNORE)
	g_Forwards[FW_WAR_SPAWN_POST] = CreateMultiForward("cs_fw_war_spawn", ET_IGNORE, FP_CELL)
	
	g_iMsgSayTxt = get_user_msgid("SayText") 
	g_iSyncHud = CreateHudSyncObj()
	g_iMsgScreenFade = get_user_msgid("ScreenFade")
	g_iMsgAmmo = get_user_msgid("AmmoPickup")
	
	g_WarMenu = menu_create("\yWeapons War \rv7.0", "war_handler")
    
	new szItem[64]
	for(new i; i < sizeof(WeaponsData); i++)
	{
		formatex(szItem, charsmax(szItem), "%s: \y%s", WeaponsData[i][WeaponType], WeaponsData[i][WeaponName])
		menu_additem(g_WarMenu, szItem)
	}
}

public plugin_cfg()
{
	g_iCHudXPosition = get_pcvar_float(g_iXPosition)
	g_iCHudYPosition = get_pcvar_float(g_iYPosition)
}

public plugin_end()
{
	menu_destroy(g_WarMenu)
}

public plugin_natives()
{
	register_library("cs_war")
	register_native("cs_is_war_round", "native_is_war_round")
	register_native("cs_current_war", "native_current_war")
	register_native("cs_last_war", "native_last_war")
	register_native("cs_war_set", "native_war_set")
	register_native("cs_start_war", "native_start_war")
	register_native("cs_start_vote", "native_start_vote")
	register_native("cs_is_point_leader", "native_is_point_leader")
}

public native_is_war_round(iPlugin, iParams)
{
	return g_bInWar
}

public native_current_war(iPlugin, iParams)
{
	set_string(1, g_sWeaponWar, get_param(2))
}

public native_last_war(iPlugin, iParams)
{
	set_string(1, g_sLastWar, get_param(2))
}

public native_war_set(iPlugin, iParams)
{
	if(iParams != 2)
	{
		log_error(AMX_ERR_NATIVE, "cs_war_set native is incorrect. Param count is 2")
		return 0
	}
	
	get_string(1, g_sWeaponWar, charsmax(g_sWeaponWar))
	if (strlen(g_sWeaponWar) < 1)
	{
		log_error(AMX_ERR_NATIVE, "cs_war_set native is incorrect. Plugin can't register custom war with an empty name")
		return 0
	}
	
	get_string(2, g_sWeaponID, charsmax(g_sWeaponID))
	if(!equal(g_sWeaponID, "weapon_",7))
	{
		log_error(AMX_ERR_NATIVE, "cs_war_set native is incorrect. const szWarID[] must start with weapon_")
		return 0
	}
	
	return 1
}

public native_start_war(iPlugin, iParams)
{
	if(g_bVote)
	{
		log_error(AMX_ERR_NATIVE, "cs_start_war native is incorrect. There is already on-going vote") 
		return 0
	}
		
	if(g_bStartWar || g_bInWar)
	{
		log_error(AMX_ERR_NATIVE, "cs_start_war native is incorrect. There is already on-going weapon war")
		return 0
	}
	
	// Start war round. ;)
	StartWar()
	
	return 1
}

public native_start_vote(iPlugin, iParams)
{
	if(iParams != 1)
	{
		log_error(AMX_ERR_NATIVE, "cs_start_vote native is incorrect. Param count is 1")
		return 0
	}
	
	if(g_bVote)
	{
		log_error(AMX_ERR_NATIVE, "cs_start_vote native is incorrect. There is already on-going vote") 
		return 0
	}
		
	if(g_bStartWar || g_bInWar)
	{
		log_error(AMX_ERR_NATIVE, "cs_start_war native is incorrect. There is already on-going weapon war")
		return 0
	}
	
	new Float:fVoteTime = get_param_f(1)
	
	// Prevent vote if the values is less than "0.0"
	if(fVoteTime < 0.0)
	{
		log_error(AMX_ERR_NATIVE, "cs_start_vote native is incorrect. fVoteTime must not less than 0.0")
		return 0
	}
	
	set_task(fVoteTime, "EndVote", TASK_VOTE)
	
	print_colored(0, "!g[WW]!t %.f seconds !yto vote!", fVoteTime)
	
	g_bVote = true
	
	// Start war vote. ;)
	StartVote()
	
	return 1
}

public native_is_point_leader(iPlugin, iParams)
{
	if(iParams != 1)
	{
		log_error(AMX_ERR_NATIVE, "cs_is_point_leader native is incorrect. Param count is 1")
		return 0
	}
	
	if(!get_pcvar_num(g_iPointLeader))
	{
		log_error(AMX_ERR_NATIVE, "Problem with a cvar value. Please enable ww_point_leader cvar first!")
		return 0
	}
	
	new id = get_param(1)
	
	if (!is_user_connected(id))
		return 0
	
	return flag_get_boolean(g_isPointLeader, id);
}

public cs_war_new_round()
{
	g_bInWar = false
	g_bHEWar = false
	g_bVote = false
	
	remove_task(TASK_HUD)
	remove_task(TASK_VOTE)
	
	new iPlayers[MAXPLAYERS], iPlayerCount, i, id
	
	get_players(iPlayers, iPlayerCount, "c") 
	for(i = 0; i < iPlayerCount; i++)
	{
		id = iPlayers[i]
		g_iAllVote[id] = false
		g_bJustDrop[id] = false
		g_bBPUnlimit[id] = false

		g_iPoints[id] = 0
	}
}

public cs_war_restart()
{
	g_iWarCountdown = 0
	g_iVoteCountdown = 0
}

public cs_war_round_start()
{		
	if(g_bStartWar)
	{
		StartWar()
		
		g_bStartWar = false
	}
	else
	{
		if(get_pcvar_num(g_iAutoWarVote))
		{
			if(g_iVoteCountdown >= get_pcvar_num(g_iVoteDelay))
			{
				new iWeaponIndex = random(sizeof WeaponsData)
				
				copy(g_sWeaponWar, charsmax(g_sWeaponWar), WeaponsData[iWeaponIndex][WeaponName])
				copy(g_sWeaponID, charsmax(g_sWeaponID), WeaponsData[iWeaponIndex][WeaponID])
				g_WeaponIndex = WeaponsData[iWeaponIndex][WeaponIndex]
				
				set_task(get_pcvar_float(g_iVotingTime), "EndVote", TASK_VOTE)
				
				print_colored(0, "!g[WW]!t %L", LANG_PLAYER, "CSWAR_VOTE_TIME", get_pcvar_num(g_iVotingTime))
				
				g_bVote = true
				
				StartVote()
				
				g_iVoteCountdown = 0
			}

			g_iVoteCountdown ++
		}
		
		if(get_pcvar_num(g_iAutoWarStart))
		{
			if(g_iWarCountdown >= get_pcvar_num(g_iWarDelay))
			{
				new iWeaponIndex = random(sizeof WeaponsData)
				
				copy(g_sWeaponWar, charsmax(g_sWeaponWar), WeaponsData[iWeaponIndex][WeaponName])
				copy(g_sWeaponID, charsmax(g_sWeaponID), WeaponsData[iWeaponIndex][WeaponID])
				g_WeaponIndex = WeaponsData[iWeaponIndex][WeaponIndex]
				
				StartWar()
				
				g_iWarCountdown = 0
			}
			
			g_iWarCountdown ++
		}
	}
}

public cs_war_round_end()
{
	if(g_bLastRoundIsWar)
	{
		g_bLastRoundIsWar = false
	}
	
	if(g_bInWar)
	{
		new iPlayers[MAXPLAYERS], iPlayerCount, i, id
		new iStripWeapon = get_pcvar_num(g_iStripWeapon)
		
		get_players(iPlayers, iPlayerCount, "a") 
		for(i = 0; i < iPlayerCount; i++)
		{
			id = iPlayers[i]
			
			if(g_bHEWar)
			{
				give_item(id, g_sWeaponID)
				cs_set_user_bpammo(id, g_WeaponIndex, 1)
				
				g_bHEWar = false
			}
			else
			{
				if(iStripWeapon)
				{
					if(!equal(g_sWeaponID, "weapon_knife"))
					{
						cs_strip_weapon(id, g_sWeaponID)
					}
				}
			}
			
			g_bJustDrop[id] = false
			g_bBPUnlimit[id] = false
			
			remove_task(id+TASK_RESPAWN)
		}
		
		if(get_pcvar_num(g_iPointLeader))
		{
			new iPoints, Others
			new iLeader = FindLeader(iPoints)

			get_players(iPlayers, iPlayerCount, "c" )
			for ( new i = 0; i < iPlayerCount; i++ )
			{
				Others = g_iPoints[i]
			}
				
			if(iPoints == Others)
			{
				set_hudmessage(random_num(10,255), random(256), random(256), -1.0, 0.20, 0, 3.0, 6.0, 0.0, 0.0, -1)
				show_hudmessage(0, "%L", LANG_PLAYER, "CSWAR_EQUAL_POINT")
			}
			else
			{
				new szName[MAXPLAYERS]
				get_user_name(iLeader, szName, charsmax(szName))
				
				flag_set(g_isPointLeader, iLeader)
				
				set_hudmessage(random_num(10,255), random(256), random(256), -1.0, 0.20, 0, 3.0, 6.0, 0.0, 0.0, -1)
				show_hudmessage(0, "%L", LANG_PLAYER, "CSWAR_POINT_LEADER", szName, iPoints)
				
				if (get_pcvar_num(g_iPointBonus))
				{
					cs_set_user_money(iLeader, min(cs_get_user_money(iLeader) + get_pcvar_num(g_iBonusAmount), 16000))
					print_colored(0, "!g[WW]!t %L", LANG_PLAYER, "CSWAR_POINT_CHAT", szName, iPoints)
				}
			}
		}
		
		copy(g_sLastWar, charsmax(g_sLastWar), g_sWeaponWar)
		
		ExecuteForward(g_Forwards[FW_WAR_ROUND_END], g_ForwardResult)
		
		if(get_pcvar_num(g_iWeaponDrop))
		{
			new szWeapon[20]
			for(new i; i < sizeof(WeaponsData); i++)
			{
				copy(szWeapon, charsmax(szWeapon), WeaponsData[i][WeaponID])
				RegisterHam(Ham_CS_Item_CanDrop, szWeapon, "cs_war_CanDrop")
			}
			
			new const WeaponCannotDrop[][] = {"weapon_knife", "weapon_hegrenade"}
			for(new i; i < sizeof(WeaponCannotDrop); i++)
			{
				copy(szWeapon, charsmax(szWeapon), WeaponCannotDrop[i])
				RegisterHam(Ham_CS_Item_CanDrop, szWeapon, "cs_war_CannotDrop")
			}
		}
		
		g_bLastRoundIsWar = true
	}
	
	g_bInWar = false
	g_bHEWar = false
	g_bVote = false
	
	remove_task(TASK_HUD)
	remove_task(TASK_VOTE)
}

FindLeader(&iPoints)
{
	new iPlayers[MAXPLAYERS], iPlayerCount, i, id
	new iLeader, iAllPoints	
	
	get_players(iPlayers, iPlayerCount, "c")
	for ( i = 0; i < iPlayerCount; i++ )
	{
		id = iPlayers[i]
		iAllPoints = g_iPoints[id]
		
		if (iAllPoints > iPoints)
		{
			iPoints = iAllPoints
			iLeader = id
		}
	}

	return iLeader;
}

public cs_war_PlayerRespawn(id)
{
	if(g_bInWar && is_user_alive(id))
	{
		if(get_pcvar_num(g_iAutoRespawn))
		{
			if(g_bHEWar)
			{
				give_item(id, g_sWeaponID)
				cs_set_user_bpammo(id, g_WeaponIndex, 191)
			}
			else
			{
				give_item(id, g_sWeaponID)
				ExecuteHamB(Ham_GiveAmmo, id, MAXBPAMMO[g_WeaponIndex], AMMOTYPE[g_WeaponIndex], MAXBPAMMO[g_WeaponIndex])
				
				if(get_pcvar_num(g_iBullet))
				{
					if(!equal(g_sWeaponID, "weapon_knife"))
					{
						g_bBPUnlimit[id] = true
					}
				}
			}
		}
		
		// Spawn forward
		ExecuteForward(g_Forwards[FW_WAR_SPAWN_POST], g_ForwardResult, id)
	}
}

public cs_war_PlayerKilled(iVictim, iKiller)  
{
	if (!g_bInWar || !is_user_alive(iKiller) || iVictim == iKiller) 
		return
	
	if(get_pcvar_num(g_iPointLeader))
	{
		g_iPoints[iKiller] ++
	}
	
	if(get_pcvar_num(g_iAutoRespawn))
	{
		set_task(3.0, "AutoRespawn", iVictim+TASK_RESPAWN)
	}
	
	// Credit to ConnorMcLeod: https://forums.alliedmods.net/showthread.php?t=188465
	if(get_pcvar_num(g_iKillerView))
	{
		set_pev(iVictim, pev_deadflag, DEAD_DEAD)
		new Float:flTime = get_gametime()
		set_pdata_float(iVictim, m_fDeadTime, flTime - 3.1)
		ExecuteHam(Ham_Think, iVictim)
		
		engclient_cmd(iVictim, "specmode", get_pcvar_num(g_iSpecMode) ? "1" : "4")

		set_pdata_float(iVictim, m_flNextSpecButtonTime, flTime + get_pcvar_float(g_iBlockChangeViewTime))
		
		set_pev(iVictim, pev_deadflag, DEAD_DYING)
		set_pev(iVictim, pev_nextthink, flTime + 0.1)
		set_pdata_float(iVictim, m_fDeadTime, flTime + 9999.0)

		new szFade[13], l = get_pcvar_string(g_iKillerViewFade, szFade, charsmax(szFade))
		if( l == 12 )
		{
			new RedColor, GreenColor, BlueColor, Alpha

			RedColor = (szFade[0] - '0') * 100 + (szFade[1] - '0') * 10 + (szFade[2] - '0')
			GreenColor = (szFade[3] - '0') * 100 + (szFade[4] - '0') * 10 + (szFade[5] - '0')
			BlueColor = (szFade[6] - '0') * 100 + (szFade[7] - '0') * 10 + (szFade[8] - '0')
			Alpha = (szFade[9] - '0') * 100 + (szFade[10] - '0') * 10 + (szFade[11] - '0')

			message_begin(MSG_ONE_UNRELIABLE, g_iMsgScreenFade, .player=iVictim)
			write_short(2<<12)
			write_short(1<<11)
			write_short(0)
			write_byte(RedColor)
			write_byte(GreenColor)
			write_byte(BlueColor)
			write_byte(Alpha)
			message_end()
		}
	}
}

public AutoRespawn(id)
{
	id -= TASK_RESPAWN
	if(g_bInWar && !is_user_alive(id))
	{
		ExecuteHamB(Ham_CS_RoundRespawn, id)
	}
}

public cs_war_CurWeapon(id)
{
	if(g_bInWar)
	{
		engclient_cmd(id, g_sWeaponID)
	}
}

// Credit to ConnorMcLeod: https://forums.alliedmods.net/showpost.php?p=1238819&postcount=47
public cs_war_WeaponsDeploy(iWeapon)
{
	if(g_bInWar && get_pcvar_num(g_iWeaponDrop))
	{
		new iId = get_pdata_int(iWeapon, m_iId, XO_WEAPONS)
		if(iId != g_WeaponIndex)
		{
			set_pdata_float(iWeapon, m_flNextPrimaryAttack, 99.0, XO_WEAPONS)
			set_pdata_float(iWeapon, m_flNextSecondaryAttack, 99.0, XO_WEAPONS)
		}
	}
	else if(g_bLastRoundIsWar)
	{
		set_pdata_float(iWeapon, m_flNextPrimaryAttack, 0.0, XO_WEAPONS)
		set_pdata_float(iWeapon, m_flNextSecondaryAttack, 0.0, XO_WEAPONS)
	}
}  

public client_disconnect(id)
{
	g_iAllVote[id] = false
	g_bBPUnlimit[id] = false
	g_bJustDrop[id] = false
	g_iPoints[id] = 0
	
	flag_unset(g_isPointLeader, id)
}

public cs_war_drop(id)
{
	if(g_bInWar)
	{
		if(!get_pcvar_num(g_iWeaponDrop))
		{
			print_colored(id, "!g[WW]!t %L", LANG_PLAYER, "CSWAR_RESTRICT_IN_WAR", g_sWeaponWar)
			return PLUGIN_HANDLED
		}
		
		g_bJustDrop[id] = true
		set_task(3.0, "RestoreDrop", id)
	}
	
	return PLUGIN_CONTINUE
}

public RestoreDrop(id)
{
	if(g_bInWar)
	{
		g_bJustDrop[id] = false
	}
}

public cs_war_vote(id)
{
	get_pcvar_string(g_sAdminFlag, g_sCurrentFlag, charsmax(g_sCurrentFlag))
	new iFlags  = read_flags(g_sCurrentFlag)
	if(get_pcvar_num(g_iAllowWarStart) && get_user_flags(id) & iFlags)
	{
		if(g_bVote)
		{
			print_colored(id, "!g[WW]!t %L", LANG_PLAYER, "CSWAR_VOTE_START")
		}
		else
		{
			if(g_bStartWar)
			{
				print_colored(id, "!g[WW]!t %L", LANG_PLAYER, "CSWAR_NEXT_WAR", g_sWeaponWar)
			}
			else
			{		
				if(g_bInWar)
				{
					print_colored(id, "!g[WW]!t %L", LANG_PLAYER, "CSWAR_NO_VOTE", g_sWeaponWar)
				}
				else
				{
					g_iAllVote[id] = true
					
					menu_display(id, g_WarMenu, 0)
				}
			}
		}
	}
	else
	{
		print_colored(id, "!g[WW]!t %L", LANG_PLAYER, "CSWAR_COMMAND_RESTRICT")
	}
}

public vote_handler(const id, const menuid, const item) 
{
	if(item == MENU_EXIT || !g_bVote) 
	{
		return PLUGIN_HANDLED
	}
	
	g_iVotes[item] ++
	
	return PLUGIN_HANDLED
}

public cs_war_start(id)
{
	get_pcvar_string(g_sAdminFlag, g_sCurrentFlag, charsmax(g_sCurrentFlag))
	new iFlags  = read_flags(g_sCurrentFlag)
	if(get_pcvar_num(g_iAllowWarVote) && get_user_flags(id) & iFlags)
	{
		if(g_bVote)
		{
			print_colored(id, "!g[WW]!t %L", LANG_PLAYER, "CSWAR_VOTE_START")
		}
		else
		{
			if(g_bStartWar)
			{
				print_colored(id, "!g[WW]!t %L", LANG_PLAYER, "CSWAR_NEXT_WAR", g_sWeaponWar)
			}
			else
			{
				if(g_bInWar)
				{
					print_colored(0, "!g[WW]!t %L", LANG_PLAYER, "CSWAR_CURRENT_WAR", g_sWeaponWar)
				}
				else
				{
					menu_display(id, g_WarMenu, 0)
				}
			}
		}
	}
	else
	{
		print_colored(id, "!g[WW]!t %L", LANG_PLAYER, "CSWAR_COMMAND_RESTRICT")
	}
}

public war_handler(const id, const menuid, const item)
{
	if(is_user_alive(id))
	{
		if(item == MENU_EXIT)
		{
			return PLUGIN_HANDLED
		}
		
		copy(g_sWeaponWar, charsmax(g_sWeaponWar), WeaponsData[item][WeaponName])
		copy(g_sWeaponID, charsmax(g_sWeaponID), WeaponsData[item][WeaponID])
		g_WeaponIndex = WeaponsData[item][WeaponIndex]
		
		menu_cancel(id)
		
		WarType(id)
	}
	
	return PLUGIN_HANDLED
}

public WarType(id)
{
	if(g_iAllVote[id])
	{
		new szADMIN[MAXPLAYERS]
		get_user_name(id, szADMIN, charsmax(szADMIN))
		
		set_task(get_pcvar_float(g_iVotingTime), "EndVote", TASK_VOTE)
		
		print_colored(0, "!g[WW]!t %L", LANG_PLAYER, "CSWAR_ADMIN_VOTE", szADMIN, g_sWeaponWar)
		print_colored(0, "!g[WW]!t %L", LANG_PLAYER, "CSWAR_VOTE_TIME", get_pcvar_num(g_iVotingTime))
		
		g_bVote = true
		
		StartVote()
	}
	else
	{
		StartWar()
	}
}

public StartVote()
{
	g_iVotes[0] = g_iVotes[1] = 0
	
	new szVote[101]
	formatex(szVote, charsmax(szVote), "Vote for War Round! ^n\rNext is %s war!", g_sWeaponWar)
	
	g_iVoteMenu = menu_create(szVote, "vote_handler")
	
	menu_additem(g_iVoteMenu, "Yes!", "", 0)
	menu_additem(g_iVoteMenu, "No!", "", 0)
	
	new iPlayers[MAXPLAYERS], iPlayerCount, id
	
	get_players(iPlayers, iPlayerCount, "ac")
	for(new i; i < iPlayerCount; i++)
	{
		id = iPlayers[i];
		menu_display(id, g_iVoteMenu, 0)
	}
	
	// Forward
	ExecuteForward(g_Forwards[FW_WAR_VOTE_START], g_ForwardResult)
}

public EndVote()
{
	if(g_iVotes[0] > g_iVotes[1])
	{
		print_colored(0, "!g[WW]!t %L", LANG_PLAYER, "CSWAR_VOTE_SUCCESS")
		print_colored(0, "!g[WW]!t %L", LANG_PLAYER, "CSWAR_NEXT_WAR", g_sWeaponWar)
		
		g_bStartWar = true
	}
	else
	{
		print_colored(0, "!g[WW]!t %L", LANG_PLAYER, "CSWAR_VOTE_FAILED")
	}
	
	menu_destroy(g_iVoteMenu)
	
	g_bVote = false
	
	// Forward
	ExecuteForward(g_Forwards[FW_WAR_VOTE_END], g_ForwardResult)
}

public StartWar()
{
	new iPlayers[MAXPLAYERS], iPlayerCount, i, id
	
	get_players(iPlayers, iPlayerCount, "a") 
	for(i = 0; i < iPlayerCount; i++)
	{
		id = iPlayers[i]
		flag_unset(g_isPointLeader, id)
	
		if(equal(g_sWeaponID, "weapon_hegrenade"))
		{
			give_item(id, g_sWeaponID)
			cs_set_user_bpammo(id, g_WeaponIndex, 191)
			
			g_bHEWar = true
		}
		else
		{
			give_item(id, g_sWeaponID)
			ExecuteHamB(Ham_GiveAmmo, id, MAXBPAMMO[g_WeaponIndex], AMMOTYPE[g_WeaponIndex], MAXBPAMMO[g_WeaponIndex])
			
			if(get_pcvar_num(g_iBullet))
			{
				if(!equal(g_sWeaponID, "weapon_knife"))
				{
					g_bBPUnlimit[id] = true
				}
			}
		}
	}
	
	g_bInWar = true
	
	if(get_pcvar_num(g_iShowHud))
	{
		set_task(1.0, "WarHud", TASK_HUD, _, _, "b")
	}
	
	set_hudmessage(random_num(10,255), random(256), random(256), -1.0, 0.20, 0, 6.0, 12.0, 0.0, 0.0, -1)
	show_hudmessage(0, "%L", LANG_PLAYER, "CSWAR_WAR_START", g_sWeaponWar)
	
	
	// Execute war round started forward
	ExecuteForward(g_Forwards[FW_WAR_ROUND_START], g_ForwardResult)
	
	if(get_pcvar_num(g_iWeaponDrop))
	{
		new szWeapon[20]
		for(new i; i < sizeof(WeaponsData); i++)
		{
			copy(szWeapon, charsmax(szWeapon), WeaponsData[i][WeaponID])
			RegisterHam(Ham_CS_Item_CanDrop, szWeapon, "cs_war_CannotDrop")
		}
		
		RegisterHam(Ham_CS_Item_CanDrop, g_sWeaponID, "cs_war_CanDrop")
		
		new const WeaponCannotDrop[][] = {"weapon_knife", "weapon_hegrenade"}
		for(new i; i < sizeof(WeaponCannotDrop); i++)
		{
			copy(szWeapon, charsmax(szWeapon), WeaponCannotDrop[i])
			RegisterHam(Ham_CS_Item_CanDrop, szWeapon, "cs_war_CannotDrop")
		}
	}
}

// Credit to ConnorMcLeod: https://forums.alliedmods.net/showthread.php?p=1117804
public cs_war_CanDrop(iEnt)
{
	SetHamReturnInteger(1)
	return HAM_SUPERCEDE
}

public cs_war_CannotDrop(iEnt)
{
	SetHamReturnInteger(0)
	return HAM_SUPERCEDE
}

// Credit to ZP Team
// BP Ammo update
public cs_war_ammo(id)
{
	// Not alive or not human
	if (!is_user_alive(id) || !g_bInWar || !g_bBPUnlimit[id])
		return;
	
	// This is to get ammo type
	new type = read_data(1)
	if (type >= sizeof WEAPONID)
		return;
	
	// This is to get weapon's id
	new weapon = WEAPONID[type]
	
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
		set_task(0.1, "Refill_BPAmmo", id, args, sizeof args)
	}
}

// Refill BP ammo
public Refill_BPAmmo(const args[], id)
{
	// Player died or 
	if (!is_user_alive(id) || !g_bInWar || !g_bBPUnlimit[id])
		return;
	
	new g_iStatus = get_msg_block(g_iMsgAmmo)
	set_msg_block(g_iMsgAmmo, BLOCK_ONCE)
	
	ExecuteHamB(Ham_GiveAmmo, id, MAXBPAMMO[REFILL_WEAPONID], AMMOTYPE[REFILL_WEAPONID], MAXBPAMMO[REFILL_WEAPONID])
	set_msg_block(g_iMsgAmmo, g_iStatus)
}

public WarHud()
{
	new szColors[16]
	new szRed[4], szGreen[4], szBlue[4]
	new iRed, iGreen, iBlue
	
	get_pcvar_string(g_iHudColors, szColors, charsmax(szColors))
	parse(szColors, szRed, charsmax(szRed), szGreen, charsmax(szGreen), szBlue, charsmax(szBlue))
	iRed = str_to_num(szRed); iGreen = str_to_num(szGreen); iBlue = str_to_num(szBlue);
	
	set_hudmessage(iRed, iGreen, iBlue, g_iCHudXPosition, g_iCHudYPosition, 0, 1.0, 1.0)
	ShowSyncHudMsg(0, g_iSyncHud, "%L", LANG_PLAYER, "CSWAR_WAR_HUD", g_sWeaponWar)
}

// Credit to ConnorMcLeod: https://forums.alliedmods.net/showthread.php?t=235139
public cs_war_WeaponBox(ent, id)
{
	if(get_pcvar_num(g_iWeaponDrop) && g_bInWar && is_user_alive(id))
	{
		new iId = GetWeaponBoxWeaponType(ent)
		if(!g_bJustDrop[id] && iId == g_WeaponIndex)
		{
			if(!(cs_get_user_bpammo(id, iId) == 0))
			{
				give_item(id, g_sWeaponID)
				cs_set_user_bpammo(id, g_WeaponIndex, cs_get_user_bpammo(id, iId))
			}
		}
	}
}

public cs_war_Shield(ent, id)
{
	if(get_pcvar_num(g_iNoShield) && g_bInWar)
	{
		return PLUGIN_HANDLED
	}
	
	return PLUGIN_CONTINUE
}

GetWeaponBoxWeaponType( ent )
{
    new iId
    for(new i = 1; i<= 5; i++)
    {
        iId = get_pdata_cbase(ent, m_rgpPlayerItems_CWeaponBox[i], XO_WEAPONS)
        if(iId > 0)
        {
            return cs_get_weapon_id(iId)
        }
    }

    return 0
}

stock cs_strip_weapon(id, sWeaponID[])
{
    if(!equal(sWeaponID,"weapon_",7)) return 0

    new wId = get_weaponid(sWeaponID)
    if(!wId) return 0

    new wEnt
    while((wEnt = engfunc(EngFunc_FindEntityByString,wEnt,"classname", sWeaponID)) && pev(wEnt,pev_owner) != id) {}
    if(!wEnt) return 0

    if(get_user_weapon(id) == wId) ExecuteHamB(Ham_Weapon_RetireWeapon, wEnt)
	
    if(!ExecuteHamB(Ham_RemovePlayerItem, id, wEnt)) return 0
	
    ExecuteHamB(Ham_Item_Kill, wEnt)

    set_pev(id, pev_weapons, pev(id, pev_weapons) & ~(1<<wId))

    return 1;
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
		message_begin(MSG_ONE_UNRELIABLE , g_iMsgSayTxt, _, index)
		write_byte(index)
		write_string(message)
		message_end()
	}
	else
	{
		new players[MAXPLAYERS], count, i, id
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
