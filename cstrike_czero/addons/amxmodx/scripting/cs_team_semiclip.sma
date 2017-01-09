/*================================================================================
	
		***********************************************
		********* [CS/CZ Team Semiclip 3.1.1] *********
		***********************************************
	
	----------------------
	-*- Licensing Info -*-
	----------------------
	
	CS/CZ Team Semiclip
	by schmurgel1983(@msn.com)
	Copyright (C) 2010-2015 Stefan "schmurgel1983" Focke
	
	This program is free software: you can redistribute it and/or modify it
	under the terms of the GNU General Public License as published by the
	Free Software Foundation, either version 3 of the License, or (at your
	option) any later version.
	
	This program is distributed in the hope that it will be useful, but
	WITHOUT ANY WARRANTY; without even the implied warranty of
	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General
	Public License for more details.
	
	You should have received a copy of the GNU General Public License along
	with this program. If not, see <http://www.gnu.org/licenses/>.
	
	In addition, as a special exception, the author gives permission to
	link the code of this program with the Half-Life Game Engine ("HL
	Engine") and Modified Game Libraries ("MODs") developed by Valve,
	L.L.C ("Valve"). You must obey the GNU General Public License in all
	respects for all of the code used other than the HL Engine and MODs
	from Valve. If you modify this file, you may extend this exception
	to your version of the file, but you are not obligated to do so. If
	you do not wish to do so, delete this exception statement from your
	version.
	
	No warranties of any kind. Use at your own risk.
	
=================================================================================*/

/*================================================================================
 [Plugin Customization]
=================================================================================*/

const Float:CVAR_INTERVAL  = 6.0		/* ¬ 6.0 */
const Float:SPEC_INTERVAL  = 0.2		/* ¬ 0.2 */
const Float:RANGE_INTERVAL = 0.1		/* It's like a 10 FPS server (look RANGE_CHECK_ON_SEMICLIP comment) ¬ 0.1 */

#define MAX_HOSTAGE     6	/* Have seen maps with more as 4 hostages ¬ 6 */
#define MAX_PLAYERS     32	/* Server slots ¬ 32 */
#define MAX_REG_SPAWNS	24	/* Max cached regular spawns per team ¬ 24 */
#define MAX_CSDM_SPAWNS 60	/* CSDM 2.1.2 value if you have more increase it ¬ 60 */
#define MAX_ENT_ARRAY   128	/* Is for max 4096 entities (128*32=4096) ¬ 128 */

/*	Uncomment the line below to have range check in semiclip start forward maybe most
	useful for surf servers this call any 1/FPS in seconds indeed of RANGE_INTERVAL.
	Use at your own risk, for server with a high 1000 FPS setup (cause lags).
	*/
//#define RANGE_CHECK_ON_SEMICLIP

/*================================================================================
 Customization ends here! Yes, that's it. Editing anything beyond
 here is not officially supported. Proceed at your own risk...
=================================================================================*/

/* Just a little bit extra, not too much */
#pragma dynamic 8192

#include <amxmodx>

#if AMXX_VERSION_NUM < 182
	#assert AMX Mod X v1.8.2 or later library required!
#endif

#include <cstrike>
#include <engine>
#include <fakemeta>
#include <hamsandwich>

/*================================================================================
 [TODO]
 
 nothing :)
 
=================================================================================*/

/*================================================================================
 [Constants, Offsets and Defines]
=================================================================================*/

new const PLUGIN_VERSION[]        = "3.1.1"
new const CT_SPAWN_ENTITY_NAME[]  = "info_player_start"
new const TER_SPAWN_ENTITY_NAME[] = "info_player_deathmatch"

const Float:ANTI_BOOST_DISTANCE = 85.041169	/* do not change this! ¬ 85.041169 */

const pev_spec_mode     = pev_iuser1
const pev_spec_target   = pev_iuser2
const pev_hostage_index = pev_iuser3 /* hostage: pev_iuser1 and pev_iuser2 get a reset... */

const m_hObserverTarget  = 447
const m_pPlayer          = 41
const linux_diff         = 5
const mac_diff           = 5	/* the same? (i don't have a mac pc or server) */
const linux_weapons_diff = 4
const mac_weapons_diff   = 4	/* the same? (i don't have a mac pc or server) */
const pdata_safe         = 2

const Ham:Ham_Player_SemiclipStart = Ham_Player_UpdateClientData	/* Ham_Player_UpdateClientData <|> Ham_Player_PreThink */
const Ham:Ham_Player_SemiclipEnd   = Ham_Item_ItemSlot				/* Ham_Item_ItemSlot <|> Ham_Player_PostThink */
const Ham:Ham_Entity_SemiclipStart = Ham_SetObjectCollisionBox

const FM_Entity_MovingEnd = FM_UpdateClientData
const FM_Player_Clashing  = FM_SetAbsBox

enum (+= 35)
{
	TASK_SPECTATOR = 5000,
	TASK_RANGE,
	TASK_DURATION,
	TASK_PREPARATION,
	TASK_CVARS,
	TASK_CSBOTS
}

/* tsc_set_user_rendering */
enum
{
	SPECIAL_MODE = 0,
	SPECIAL_AMT,
	SPECIAL_FX,
	MAX_SPECIAL
}

/* semiclip_color_* cvars */
enum
{
	COLOR_CT = 0,
	COLOR_TER,
	COLOR_ADMIN_CT,
	COLOR_ADMIN_TER,
	COLOR_HOSTAGE,
	COLOR_VIP,
	MAX_COLORS
}

#define OUT_OF_RANGE -1

/*================================================================================
 [Global Variables]
=================================================================================*/

/* Cvar global */
new cvar_iSemiclip,
	cvar_iSemiclipBlockTeam,
	cvar_iSemiclipEnemies,
	cvar_iSemiclipButton,
	cvar_iSemiclipButtonTrigger,
	cvar_iSemiclipButtonAntiBoost,
	cvar_iSemiclipUnstuck,
	cvar_iSemiclipUnstuckRender,
	cvar_iSemiclipHostage,
	cvar_iSemiclipKnifeTrace,
	cvar_iSemiclipRender,
	cvar_iSemiclipRenderFreeLook,
	cvar_iSemiclipNormalMode,
	cvar_iSemiclipNormalFx,
	cvar_iSemiclipNormalAmt,
	cvar_iSemiclipNormalSpec,
	cvar_iSemiclipFadeMode,
	cvar_iSemiclipFadeFx,
	cvar_iSemiclipFadeSpec,
	cvar_iBotQuota

new cvar_flSemiclipRadius,
	cvar_flSemiclipUnstuckDelay,
	cvar_flSemiclipPreparation,
	cvar_flSemiclipDuration,
	cvar_flSemiclipFadeMin,
	cvar_flSemiclipFadeMax

new cvar_szSemiclipColorFlag,
	cvar_szSemiclipColors[MAX_COLORS]

/* Cvar cached */
new c_iSemiclip,
	c_iBlockTeam,
	c_iEnemies,
	c_iButton,
	c_iButtonTrigger,
	c_iButtonAntiBoost,
	c_iHostage,
	c_iUnstuck,
	c_iUnstuckRender,
	c_iKnifeTrace,
	c_iRender,
	c_iFreeLook,
	c_iNormalMode,
	c_iNormalFx,
	c_iNormalAmt,
	c_iNormalSpec,
	c_iFadeMode,
	c_iFadeFx,
	c_iFadeSpec

new Float:c_flRadius,
	Float:c_flUnstuckDelay,
	Float:c_flFadeMin,
	Float:c_flFadeMax

new c_iColorFlag,
	c_iColors[MAX_COLORS][3]

/* Server global */
new bool:g_bPreparation,
	bool:g_bZpReallyRunning

new g_iAddToFullPack,
	g_iStartFrame,
	g_iBlocked,
	g_iCmdStart,
	g_iTraceLine,
	g_iEntityMovingEnd,
	g_iPlayerClashing,
	g_iMaxPlayers,
	g_iHamCsBots,
	g_iCvarEntity,
	g_iSpawnCountCTs,
	g_iSpawnCountTer,
	g_iSpawnCountCSDM,
	g_iHostage[MAX_HOSTAGE],
	g_iHostageCount,
	g_iFuncNum,
	g_iLastClashed

new Float:g_flSpawnsCTs[MAX_REG_SPAWNS][3],
	Float:g_flSpawnsTer[MAX_REG_SPAWNS][3],
	Float:g_flSpawnsCSDM[MAX_CSDM_SPAWNS][3]

new Trie:TrieFunctions = Invalid_Trie

new HamHook:g_iHamFuncForwards[16] /* Max supported entity classes ¬ 16 */

/* Client global */
new g_iTeam[MAX_PLAYERS+1],
	g_iRange[MAX_PLAYERS+1][MAX_PLAYERS+1],
	g_iHostageRange[MAX_PLAYERS+1][MAX_HOSTAGE],
	g_iSpectating[MAX_PLAYERS+1],
	g_iSpectatingTeam[MAX_PLAYERS+1],
	g_iAntiBoost[MAX_PLAYERS+1][MAX_PLAYERS+1],
	g_iRenderSpecial[MAX_PLAYERS+1][MAX_SPECIAL],
	g_iRenderSpecialColor[MAX_PLAYERS+1][MAX_SPECIAL]

new Float:g_flAbsMin[MAX_PLAYERS+1][3],
	Float:g_flAbsMax[MAX_PLAYERS+1][3]

/* Bitsum */
new bs_IsConnected,
	bs_IsAlive,
	bs_IsBot,
	bs_IsVip,
	bs_IsAdmin,
	bs_InSemiclip,
	bs_IsSolid,
	bs_InButton,
	bs_InAntiBoost,
	bs_WasInButton,
	bs_InKnifeSecAtk,
	bs_RenderSpecial,
	bs_IsDying,
	bs_IsAbsStored

/* Bitsum array */
new bs_IsHostage[MAX_ENT_ARRAY],
	bs_HostageIsSolid[MAX_ENT_ARRAY],
	bs_HostageIsRescued[MAX_ENT_ARRAY],
	bs_HostageIsKilled[MAX_ENT_ARRAY],
	bs_IgnoreEntity[MAX_ENT_ARRAY],
	bs_EntityDamage[MAX_ENT_ARRAY]

/*================================================================================
 [Macros]
=================================================================================*/

#define ID_SPECTATOR	(taskid - TASK_SPECTATOR)
#define ID_RANGE		(taskid - TASK_RANGE)

#define get_bitsum(%1,%2)   (%1 &   (1<<((%2-1)&31)))
#define add_bitsum(%1,%2)    %1 |=  (1<<((%2-1)&31));
#define del_bitsum(%1,%2)    %1 &= ~(1<<((%2-1)&31));

#define get_bitsum_array(%1,%2)   (%1[(%2-1)/32] &   (1<<((%2-1)&31)))
#define add_bitsum_array(%1,%2)    %1[(%2-1)/32] |=  (1<<((%2-1)&31));
#define del_bitsum_array(%1,%2)    %1[(%2-1)/32] &= ~(1<<((%2-1)&31));

#define UTIL_Vector_Add(%1,%2,%3)	(%3[0] = %1[0] + %2[0], %3[1] = %1[1] + %2[1], %3[2] = %1[2] + %2[2]);
#define TSC_Vector_MA(%1,%2,%3,%4)	(%4[0] = %2[0] * %3 + %1[0], %4[1] = %2[1] * %3 + %1[1]);

#define is_user_valid(%1)			(1 <= %1 <= g_iMaxPlayers)
#define is_user_valid_connected(%1)	(1 <= %1 <= g_iMaxPlayers && get_bitsum(bs_IsConnected, %1))
#define is_user_valid_alive(%1)		(1 <= %1 <= g_iMaxPlayers && get_bitsum(bs_IsAlive, %1) && !get_bitsum(bs_IsDying, %1))
#define is_same_team(%1,%2)			(g_iTeam[%1] == g_iTeam[%2])

/*================================================================================
 [Natives, Init and Cfg]
=================================================================================*/

native zp_has_round_started()

public plugin_natives()
{
	/* TODO: maybe more? */
	register_native("tsc_get_user_rendering", "fn_get_user_rendering")
	register_native("tsc_set_user_rendering", "fn_set_user_rendering")
	register_native("tsc_get_user_semiclip", "fn_get_user_semiclip")
	register_native("tsc_get_user_anti_boost", "fn_get_user_anti_boost")
	register_native("scm_load_ini_file", "fn_load_ini_file") /* for tsc_file_editor.amxx only */
	register_library("cs_team_semiclip")
	
	set_native_filter("native_filter")
}
public native_filter(name[], index, trap)
{
	if (equal(name, "zp_has_round_started") && trap)
	{
		g_bZpReallyRunning = false
		return PLUGIN_HANDLED
	}
	
	return (!trap) ? PLUGIN_HANDLED : PLUGIN_CONTINUE
}

public plugin_init()
{
	/* Check mods and register plugin */
	CheckMods()
	
	/* AMX Mod X check */
	CheckAmxxVersion()
	
	/* Check max Entities */
	CheckMaxEntities()
	
	register_event("HLTV", "EventRoundStart", "a", "1=0", "2=0")
	register_event("SendAudio", "EventHostageRescued", "a", "2&%!MRAD_rescued", "2&%!MRAD_escaped")
	
	register_logevent("LogEventRoundStart", 2, "1=Round_Start")
	register_logevent("EventBecameVip", 3, "1=triggered", "2=Became_VIP")
	register_logevent("EventHostageKilled", 3, "1=triggered", "2=Killed_A_Hostage")
	
	RegisterHam(Ham_Spawn, "player", "fw_PlayerSpawn_Post", true)
	RegisterHam(Ham_Killed, "player", "fw_PlayerKilled", false)
	RegisterHam(Ham_Player_SemiclipStart, "player", "fw_PlayerSemiclip_Start", true)
	RegisterHam(Ham_Player_SemiclipEnd, "player", "fw_PlayerSemiclip_End", false)
	
	RegisterHam(Ham_Weapon_PrimaryAttack, "weapon_knife", "fw_Knife_PrimaryAttack", false)
	RegisterHam(Ham_Weapon_SecondaryAttack, "weapon_knife", "fw_Knife_SecondaryAttack", false)
	
	g_iAddToFullPack = register_forward(FM_AddToFullPack, "fw_AddToFullPack_Post", true)
	g_iStartFrame = register_forward(FM_StartFrame, "fw_StartFrame", false)
	g_iBlocked = register_forward(FM_Blocked, "fw_Blocked", false)
	g_iCmdStart = register_forward(FM_CmdStart, "fw_CmdStart_Post", true)
	
	register_message(get_user_msgid("TeamInfo"), "MessageTeamInfo")
	register_message(get_user_msgid("ClCorpse"), "MessageClCorpse")
	
	/* General */
	cvar_iSemiclip = register_cvar("semiclip", "1")
	cvar_iSemiclipBlockTeam = register_cvar("semiclip_block_team", "0")
	cvar_iSemiclipEnemies = register_cvar("semiclip_enemies", "0")
	cvar_flSemiclipRadius = register_cvar("semiclip_radius", "250.0")
	
	/* Button */
	cvar_iSemiclipButton = register_cvar("semiclip_button", "0")
	cvar_iSemiclipButtonTrigger = register_cvar("semiclip_button_trigger", "32")
	cvar_iSemiclipButtonAntiBoost = register_cvar("semiclip_button_anti_boost", "1")
	
	/* Unstuck */
	cvar_iSemiclipUnstuck = register_cvar("semiclip_unstuck", "4")
	cvar_iSemiclipUnstuckRender = register_cvar("semiclip_unstuck_render", "1")
	cvar_flSemiclipUnstuckDelay = register_cvar("semiclip_unstuck_delay", "0")
	
	/* Hostage */
	cvar_iSemiclipHostage = register_cvar("semiclip_hostage", "0")
	
	/* Other */
	cvar_iSemiclipKnifeTrace = register_cvar("semiclip_knife_trace", "0")
	cvar_flSemiclipPreparation = register_cvar("semiclip_preparation", "0")
	cvar_flSemiclipDuration = register_cvar("semiclip_duration", "0")
	
	/* Render */
	cvar_iSemiclipRender = register_cvar("semiclip_render", "0")
	cvar_iSemiclipRenderFreeLook = register_cvar("semiclip_render_free_look", "1")
	
	/* Normal */
	cvar_iSemiclipNormalMode = register_cvar("semiclip_normal_mode", "1")
	cvar_iSemiclipNormalFx = register_cvar("semiclip_normal_fx", "19")
	cvar_iSemiclipNormalAmt = register_cvar("semiclip_normal_amt", "4")
	cvar_iSemiclipNormalSpec = register_cvar("semiclip_normal_spec", "0")
	
	/* Fade */
	cvar_iSemiclipFadeMode = register_cvar("semiclip_fade_mode", "2")
	cvar_iSemiclipFadeFx = register_cvar("semiclip_fade_fx", "0")
	cvar_flSemiclipFadeMin = register_cvar("semiclip_fade_min", "130")
	cvar_flSemiclipFadeMax = register_cvar("semiclip_fade_max", "225")
	cvar_iSemiclipFadeSpec = register_cvar("semiclip_fade_spec", "0")
	
	/* Color */
	cvar_szSemiclipColorFlag = register_cvar("semiclip_color_admin_flag", "b")
	cvar_szSemiclipColors[COLOR_ADMIN_TER] = register_cvar("semiclip_color_admin_ter", "255 63 63")
	cvar_szSemiclipColors[COLOR_ADMIN_CT] = register_cvar("semiclip_color_admin_ct", "153 204 255")
	cvar_szSemiclipColors[COLOR_TER] = register_cvar("semiclip_color_ter", "255 63 63")
	cvar_szSemiclipColors[COLOR_CT] = register_cvar("semiclip_color_ct", "153 204 255")
	cvar_szSemiclipColors[COLOR_HOSTAGE] = register_cvar("semiclip_color_hos", "192 148 32")
	cvar_szSemiclipColors[COLOR_VIP] = register_cvar("semiclip_color_vip", "192 148 32")
	
	register_cvar("Team_Semiclip_version", PLUGIN_VERSION, FCVAR_SERVER|FCVAR_SPONLY)
	set_cvar_string("Team_Semiclip_version", PLUGIN_VERSION)
	
	cvar_iBotQuota = get_cvar_pointer("bot_quota")
	
	g_iMaxPlayers = get_maxplayers()
}

public plugin_cfg()
{
	new szConfigDir[35]
	get_configsdir(szConfigDir, charsmax(szConfigDir))
	server_cmd("exec %s/scm/main.cfg", szConfigDir)
	
	new iEnt = -1
	while ((iEnt = find_ent_by_class(iEnt, "hostage_entity")) != 0)
	{
		g_iHostage[g_iHostageCount] = iEnt
		add_bitsum_array(bs_IsHostage, iEnt)
		set_pev(iEnt, pev_hostage_index, g_iHostageCount)
		
		if (++g_iHostageCount >= MAX_HOSTAGE)
			break
	}
	
	CreateCvarEntityTask()
	set_task(1.5, "LoadSpawns")
	set_task(2.0, "LoadSemiclipFile")
}

/*================================================================================
 [Pause, Unpause]
=================================================================================*/

public plugin_pause()
{
	unregister_forward(FM_AddToFullPack, g_iAddToFullPack, true)
	unregister_forward(FM_StartFrame, g_iStartFrame, false)
	unregister_forward(FM_Blocked, g_iBlocked, false)
	unregister_forward(FM_CmdStart, g_iCmdStart, true)
	unregister_forward(FM_Entity_MovingEnd, g_iEntityMovingEnd, false)
	unregister_forward(FM_Player_Clashing, g_iPlayerClashing, false)
	g_iEntityMovingEnd = 0
	
	remove_task(TASK_CVARS)
	remove_task(TASK_DURATION)
	remove_task(TASK_PREPARATION)
	
	if (g_iCvarEntity && pev_valid(g_iCvarEntity))
		remove_entity(g_iCvarEntity)
	
	if (g_iHostageCount)
	{
		static id, iHos
		for (id = 0; id < g_iHostageCount; id++)
		{
			iHos = g_iHostage[id]
			
			if (get_bitsum_array(bs_HostageIsRescued, iHos) || get_bitsum_array(bs_HostageIsKilled, iHos) || get_bitsum_array(bs_HostageIsSolid, iHos))
				continue
			
			set_pev(iHos, pev_solid, SOLID_SLIDEBOX)
			add_bitsum_array(bs_HostageIsSolid, iHos)
		}
	}
	
	for (new id = 1; id <= g_iMaxPlayers; id++)
	{
		if (!get_bitsum(bs_IsAlive, id) || get_bitsum(bs_IsDying, id))
			goto Label_Disconnect
		
		if (!get_bitsum(bs_IsSolid, id))
		{
			set_pev(id, pev_solid, SOLID_SLIDEBOX)
			add_bitsum(bs_IsSolid, id)
		}
		
		if (tsc_is_player_stuck(id))
			DoRandomSpawn(id, 3)
		
		Label_Disconnect:
		client_disconnect(id)
	}
}

public plugin_unpause()
{
	CacheCvars(TASK_CVARS)
	CreateCvarEntityTask()
	
	g_iAddToFullPack = register_forward(FM_AddToFullPack, "fw_AddToFullPack_Post", true)
	g_iStartFrame = register_forward(FM_StartFrame, "fw_StartFrame", false)
	g_iBlocked = register_forward(FM_Blocked, "fw_Blocked", false)
	g_iCmdStart = register_forward(FM_CmdStart, "fw_CmdStart_Post", true)
	
	if (g_iHostageCount)
	{
		static id, iHos
		for (id = 0; id < g_iHostageCount; id++)
		{
			iHos = g_iHostage[id]
			
			if (!get_bitsum_array(bs_HostageIsRescued, iHos) && pev(iHos, pev_effects) & EF_NODRAW)
			{
				add_bitsum_array(bs_HostageIsRescued, iHos)
			}
			else if (!get_bitsum_array(bs_HostageIsKilled, iHos) && !pev(iHos, pev_health))
			{
				add_bitsum_array(bs_HostageIsKilled, iHos)
			}
			else
			{
				del_bitsum_array(bs_HostageIsRescued, iHos)
				del_bitsum_array(bs_HostageIsKilled, iHos)
				
				set_pev(iHos, pev_solid, SOLID_SLIDEBOX)
				add_bitsum_array(bs_HostageIsSolid, iHos)
				
				continue
			}
			
			set_pev(iHos, pev_solid, SOLID_NOT)
			del_bitsum_array(bs_HostageIsSolid, iHos)
		}
	}
	
	bs_IsVip = 0
	for (new id = 1; id <= g_iMaxPlayers; id++)
	{
		/* disconnected while pausing? */
		if (!is_user_connected(id))
			continue
		
		/* do all other staff */
		client_putinserver(id)
		g_iTeam[id] = _:cs_get_user_team(id)
		
		if (is_user_alive(id))
		{
			remove_task(id+TASK_SPECTATOR)
			
			add_bitsum(bs_IsAlive, id)
			add_bitsum(bs_IsSolid, id)
			
			if (cs_get_user_vip(id))
				add_bitsum(bs_IsVip, id)
		}
		else if (pev(id, pev_deadflag) == DEAD_DYING)
		{
			remove_task(id+TASK_SPECTATOR)
			
			add_bitsum(bs_IsAlive, id)
			add_bitsum(bs_IsDying, id)
		}
	}
}

public plugin_end()
{
	TrieDestroy(TrieFunctions)
}

/*================================================================================
 [Put in, Disconnect]
=================================================================================*/

public client_authorized(id)
{
	if (is_user_bot(id) && !g_iHamCsBots && cvar_iBotQuota && get_pcvar_num(cvar_iBotQuota))
	{
		set_task(0.1, "StopCsBotForward", TASK_CSBOTS) /* Fake Bot? */
		g_iHamCsBots = register_forward(FM_SetClientKeyValue, "fw_SetClientKeyValue", false)
	}
}

public client_putinserver(id)
{
	add_bitsum(bs_IsConnected, id)
	SetUserCvars(id)
	
	if (is_user_bot(id))
	{
		add_bitsum(bs_IsBot, id)
		add_bitsum(bs_InButton, id)
	}
	else set_task(SPEC_INTERVAL, "SpectatorCheck", id+TASK_SPECTATOR, _, _, "b")
	
	#if !defined RANGE_CHECK_ON_SEMICLIP
	set_task(RANGE_INTERVAL, "RangeCheck", id+TASK_RANGE, _, _, "b")
	#endif // !RANGE_CHECK_ON_SEMICLIP
}

public client_disconnect(id)
{
	del_bitsum(bs_IsConnected, id)
	SetUserCvars(id)
	
	#if !defined RANGE_CHECK_ON_SEMICLIP
	remove_task(id+TASK_RANGE)
	#endif // !RANGE_CHECK_ON_SEMICLIP
	
	remove_task(id+TASK_SPECTATOR)
}

/*================================================================================
 [Main Events]
=================================================================================*/

/* Hostage is SOLID_NOT and in EF_NODRAW when rescued.
   Hostage have no health when killed. */
public EventRoundStart()
{
	for (new i = 0; i < g_iFuncNum; i++)
		DisableHamForward(g_iHamFuncForwards[i])
	
	unregister_forward(FM_Entity_MovingEnd, g_iEntityMovingEnd, false)
	unregister_forward(FM_Player_Clashing, g_iPlayerClashing, false)
	g_iEntityMovingEnd = 0
	
	remove_task(TASK_DURATION)
	remove_task(TASK_PREPARATION)
	
	new Float:flDuration = get_pcvar_float(cvar_flSemiclipDuration)
	new Float:flPreparation = get_pcvar_float(cvar_flSemiclipPreparation)
	
	/* Duration */
	if (flDuration >= 0.1)
	{
		set_pcvar_num(cvar_iSemiclip, 1)
		c_iSemiclip = 1
		g_bPreparation = true
		
		set_task(flDuration, "DisableTask", TASK_DURATION)
	}
	
	/* Preparation */
	if (flPreparation >= 0.1)
	{
		g_bPreparation = true
		
		set_task(flPreparation, "DisableTask", TASK_PREPARATION)
	}
}

/* It's dosen't matter if freezetime is 0, all hostage values are already set. thanks valve :) */
public LogEventRoundStart()
{
	for (new i = 0; i < g_iFuncNum; i++)
		EnableHamForward(g_iHamFuncForwards[i])
	
	if (g_iHostageCount)
	{
		static id, iHos
		for (id = 0; id < g_iHostageCount; id++)
		{
			iHos = g_iHostage[id]
			
			del_bitsum_array(bs_HostageIsRescued, iHos)
			del_bitsum_array(bs_HostageIsKilled, iHos)
			add_bitsum_array(bs_HostageIsSolid, iHos)
		}
	}
}

public EventHostageRescued()
{
	static id, iHos
	for (id = 0; id < g_iHostageCount; id++)
	{
		iHos = g_iHostage[id]
		
		if (!get_bitsum_array(bs_HostageIsRescued, iHos) && pev(iHos, pev_effects) & EF_NODRAW)
		{
			add_bitsum_array(bs_HostageIsRescued, iHos)
		}
		else continue
		
		set_pev(iHos, pev_solid, SOLID_NOT)
		del_bitsum_array(bs_HostageIsSolid, iHos)
	}
}

public EventHostageKilled()
{
	static id, iHos
	for (id = 0; id < g_iHostageCount; id++)
	{
		iHos = g_iHostage[id]
		
		if (!get_bitsum_array(bs_HostageIsKilled, iHos) && !pev(iHos, pev_health))
		{
			add_bitsum_array(bs_HostageIsKilled, iHos)
		}
		else continue
		
		set_pev(iHos, pev_solid, SOLID_NOT)
		del_bitsum_array(bs_HostageIsSolid, iHos)
	}
}

public EventBecameVip()
{
	bs_IsVip = 0
	
	new szLogUser[80], szName[32]
	read_logargv(0, szLogUser, charsmax(szLogUser))
	parse_loguser(szLogUser, szName, charsmax(szName))
	
	add_bitsum(bs_IsVip, get_user_index(szName))
}

/*================================================================================
 [Main Forwards]
=================================================================================*/

public fw_StartFrame()
{
	bs_IsAbsStored = 0
}

public fw_PlayerSpawn_Post(id)
{
	if (!is_user_alive(id) || !g_iTeam[id])
		return
	
	remove_task(id+TASK_SPECTATOR)
	
	add_bitsum(bs_IsAlive, id)
	del_bitsum(bs_IsDying, id)
	del_bitsum(bs_InSemiclip, id)
	add_bitsum(bs_IsSolid, id)
}

public fw_PlayerKilled(id)
{
	add_bitsum(bs_IsDying, id)
	del_bitsum(bs_InSemiclip, id)
	del_bitsum(bs_IsSolid, id)
}

public fw_PlayerSemiclip_Start(id)
{
	if (!c_iSemiclip || !get_bitsum(bs_IsAlive, id) || get_bitsum(bs_IsDying, id))
		return
	
	#if defined RANGE_CHECK_ON_SEMICLIP
	RangeCheck(id+TASK_RANGE)
	#endif // RANGE_CHECK_ON_SEMICLIP
	
	del_bitsum(bs_InSemiclip, id)
	
	static i
	for (i = 1; i <= g_iMaxPlayers; i++)
	{
		if (!get_bitsum(bs_IsSolid, i) || i == id || g_iRange[id][i] == OUT_OF_RANGE || !AllowSemiclip(id, i))
			continue
		
		set_pev(i, pev_solid, SOLID_NOT)
		del_bitsum(bs_IsSolid, i)
		add_bitsum(bs_InSemiclip, id)
	}
	
	if (g_iHostageCount && (c_iHostage == 3 || c_iHostage == g_iTeam[id]))
	{
		static iHos
		for (i = 0; i < g_iHostageCount; i++)
		{
			iHos = g_iHostage[i]
			
			if (!get_bitsum_array(bs_HostageIsSolid, iHos) || g_iHostageRange[id][i] == OUT_OF_RANGE)
				continue
			
			set_pev(iHos, pev_solid, SOLID_NOT)
			del_bitsum_array(bs_HostageIsSolid, iHos)
		}
	}
}

public fw_PlayerSemiclip_End(id)
{
	if (!c_iSemiclip || !get_bitsum(bs_IsAlive, id) || get_bitsum(bs_IsDying, id))
		return
	
	static i
	for (i = 1; i <= g_iMaxPlayers; i++)
	{
		if (!get_bitsum(bs_IsAlive, i) || get_bitsum(bs_IsDying, i) || get_bitsum(bs_IsSolid, i))
			continue
		
		set_pev(i, pev_solid, SOLID_SLIDEBOX)
		add_bitsum(bs_IsSolid, i)
	}
	
	if (c_iHostage && g_iHostageCount)
	{
		static iHos
		for (i = 0; i < g_iHostageCount; i++)
		{
			iHos = g_iHostage[i]
			
			if (get_bitsum_array(bs_HostageIsRescued, iHos) || get_bitsum_array(bs_HostageIsKilled, iHos) || get_bitsum_array(bs_HostageIsSolid, iHos))
				continue
			
			set_pev(iHos, pev_solid, SOLID_SLIDEBOX)
			add_bitsum_array(bs_HostageIsSolid, iHos)
		}
	}
}

/* Slash - 48.0 */
public fw_Knife_PrimaryAttack(ent)
{
	if (!c_iSemiclip || !c_iKnifeTrace)
		return
	
	static iOwner
	iOwner = ham_cs_get_weapon_ent_owner(ent)
	
	if (!is_user_valid(iOwner))
		return
	
	if (!g_iTraceLine)
		g_iTraceLine = register_forward(FM_TraceLine, "fw_TraceLine_Post", true)
}

/* Stab - 32.0 */
public fw_Knife_SecondaryAttack(ent)
{
	if (!c_iSemiclip || !c_iKnifeTrace)
		return
	
	static iOwner
	iOwner = ham_cs_get_weapon_ent_owner(ent)
	
	if (!is_user_valid(iOwner))
		return
	
	if (!g_iTraceLine)
	{
		add_bitsum(bs_InKnifeSecAtk, iOwner)
		g_iTraceLine = register_forward(FM_TraceLine, "fw_TraceLine_Post", true)
	}
}

public fw_TraceLine_Post(Float:vStart[3], Float:vEnd[3], iNoMonsters, id, iTrace)
{
	if (!is_user_valid_alive(id))
		return
	
	static Float:flFraction
	get_tr2(iTrace, TR_flFraction, flFraction)
	
	if (flFraction >= 1.0)
		goto Label_Unregister
	
	static pHit
	pHit = get_tr2(iTrace, TR_pHit)
	
	if (!is_user_valid_alive(pHit) || !is_same_team(id, pHit))
		goto Label_Unregister
	
	static Float:flLine[3], Float:flStart[3]
	velocity_by_aim(id, 32, flLine) /* 22.62742 - 42.520584 */
	UTIL_Vector_Add(flLine, vStart, flStart)
	velocity_by_aim(id, get_bitsum(bs_InKnifeSecAtk, id) ? 48 : 64, flLine)
	UTIL_Vector_Add(flLine, vStart, vEnd)
	
	engfunc(EngFunc_TraceLine, flStart, vEnd, iNoMonsters|DONT_IGNORE_MONSTERS, pHit, 0)
	
	pHit = get_tr2(0, TR_pHit)
	
	if (!is_user_valid_alive(pHit) || is_same_team(id, pHit))
		goto Label_Unregister
	
	static Float:flBuffer[3]
	set_tr2(iTrace, TR_AllSolid, get_tr2(0, TR_AllSolid))
	set_tr2(iTrace, TR_StartSolid, get_tr2(0, TR_StartSolid))
	set_tr2(iTrace, TR_InOpen, get_tr2(0, TR_InOpen))
	set_tr2(iTrace, TR_InWater, get_tr2(0, TR_InWater))
	get_tr2(0, TR_flFraction, flFraction); set_tr2(iTrace, TR_flFraction, flFraction)
	get_tr2(0, TR_vecEndPos, flBuffer); set_tr2(iTrace, TR_vecEndPos, flBuffer)
	get_tr2(0, TR_flPlaneDist, flFraction); set_tr2(iTrace, TR_flPlaneDist, flFraction)
	get_tr2(0, TR_vecPlaneNormal, flBuffer); set_tr2(iTrace, TR_vecPlaneNormal, flBuffer)
	set_tr2(iTrace, TR_pHit, pHit)
	set_tr2(iTrace, TR_iHitgroup, get_tr2(0, TR_iHitgroup))
	
	Label_Unregister:
	unregister_forward(FM_TraceLine, g_iTraceLine, true)
	g_iTraceLine = 0
	del_bitsum(bs_InKnifeSecAtk, id)
}

public fw_AddToFullPack_Post(es_handle, e, ent, host, flags, player, pSet)
{
	if (!c_iSemiclip)
		return
	
	if (c_iHostage && g_iHostageCount && is_user_valid(host) && get_bitsum_array(bs_IsHostage, ent))
	{
		if (get_bitsum_array(bs_HostageIsRescued, ent) || (c_iHostage != 3 && c_iHostage != g_iSpectatingTeam[host]))
			return
		
		static iHost, iEnt
		iHost = g_iSpectating[host]
		iEnt = pev(ent, pev_hostage_index)
		
		if (g_iHostageRange[iHost][iEnt] == OUT_OF_RANGE)
			return
		
		set_es(es_handle, ES_Solid, SOLID_NOT)
		
		switch (c_iRender)
		{
			case 1: /* Normal */
			{
				set_es(es_handle, ES_RenderMode, c_iNormalMode)
				set_es(es_handle, ES_RenderFx, c_iNormalFx)
			}
			case 2: /* Fade */
			{
				set_es(es_handle, ES_RenderMode, c_iFadeMode)
				set_es(es_handle, ES_RenderFx, c_iFadeFx)
			}
			default: return
		}
		
		set_es(es_handle, ES_RenderAmt, g_iHostageRange[iHost][iEnt])
		set_es(es_handle, ES_RenderColor, c_iColors[COLOR_HOSTAGE])
		return
	}
	
	if (!player || host == ent)
		return
	
	if (g_iTeam[host] == _:CS_TEAM_SPECTATOR)
	{
		if (!c_iRender || get_bitsum(bs_IsBot, host) || !get_bitsum(bs_IsAlive, ent))
			return
		
		static iHost
		iHost = g_iSpectating[host]
		
		if (!iHost || !get_bitsum(bs_IsAlive, iHost) || g_iRange[iHost][ent] == OUT_OF_RANGE || !AllowSemiclip(iHost, ent))
			return
		
		if (!c_iUnstuckRender && !g_bPreparation && c_iUnstuck == 4 && !c_iEnemies && !is_same_team(ent, iHost))
			return
		
		switch (c_iRender)
		{
			case 2: /* Fade */
			{
				if (!c_iFadeSpec && iHost == ent)
					return
				
				if (get_bitsum(bs_RenderSpecial, ent)) goto Label_Special
				else
				{
					set_es(es_handle, ES_RenderMode, c_iFadeMode)
					set_es(es_handle, ES_RenderFx, c_iFadeFx)
				}
			}
			case 1: /* Normal */
			{
				if (!c_iNormalSpec && iHost == ent)
					return
				
				if (get_bitsum(bs_RenderSpecial, ent)) goto Label_Special
				else
				{
					set_es(es_handle, ES_RenderMode, c_iNormalMode)
					set_es(es_handle, ES_RenderFx, c_iNormalFx)
				}
			}
		}
		
		set_es(es_handle, ES_RenderAmt, g_iRange[iHost][ent])
		switch (g_iTeam[ent])
		{
			case 1: get_bitsum(bs_IsAdmin, ent) ? set_es(es_handle, ES_RenderColor, c_iColors[COLOR_ADMIN_TER]) : set_es(es_handle, ES_RenderColor, c_iColors[COLOR_TER])
			case 2: get_bitsum(bs_IsVip, ent) ? set_es(es_handle, ES_RenderColor, c_iColors[COLOR_VIP]) : get_bitsum(bs_IsAdmin, ent) ? set_es(es_handle, ES_RenderColor, c_iColors[COLOR_ADMIN_CT]) : set_es(es_handle, ES_RenderColor, c_iColors[COLOR_CT])
		}
		return
	}
	
	if (!get_bitsum(bs_IsAlive, host) || !get_bitsum(bs_IsAlive, ent) || g_iRange[host][ent] == OUT_OF_RANGE || !AllowSemiclip(host, ent))
		return
	
	set_es(es_handle, ES_Solid, SOLID_NOT)
	
	if (!c_iRender || (!c_iUnstuckRender && !g_bPreparation && c_iUnstuck == 4 && !c_iEnemies && !is_same_team(ent, host)))
		return
	
	switch (c_iRender)
	{
		case 2: /* Fade */
		{
			if (get_bitsum(bs_RenderSpecial, ent)) goto Label_Special
			else
			{
				set_es(es_handle, ES_RenderMode, c_iFadeMode)
				set_es(es_handle, ES_RenderFx, c_iFadeFx)
			}
		}
		case 1: /* Normal */
		{
			if (get_bitsum(bs_RenderSpecial, ent)) goto Label_Special
			else
			{
				set_es(es_handle, ES_RenderMode, c_iNormalMode)
				set_es(es_handle, ES_RenderFx, c_iNormalFx)
			}
		}
		case -1: /* For special render */
		{
			Label_Special:
			set_es(es_handle, ES_RenderMode, g_iRenderSpecial[ent][SPECIAL_MODE])
			set_es(es_handle, ES_RenderFx, g_iRenderSpecial[ent][SPECIAL_FX])
			set_es(es_handle, ES_RenderAmt, g_iRenderSpecial[ent][SPECIAL_AMT])
			set_es(es_handle, ES_RenderColor, g_iRenderSpecialColor[ent])
			return
		}
		default: return /* Disabled */
	}
	
	set_es(es_handle, ES_RenderAmt, g_iRange[host][ent])
	switch (g_iTeam[ent])
	{
		case 1: get_bitsum(bs_IsAdmin, ent) ? set_es(es_handle, ES_RenderColor, c_iColors[COLOR_ADMIN_TER]) : set_es(es_handle, ES_RenderColor, c_iColors[COLOR_TER])
		case 2: get_bitsum(bs_IsVip, ent) ? set_es(es_handle, ES_RenderColor, c_iColors[COLOR_VIP]) : get_bitsum(bs_IsAdmin, ent) ? set_es(es_handle, ES_RenderColor, c_iColors[COLOR_ADMIN_CT]) : set_es(es_handle, ES_RenderColor, c_iColors[COLOR_CT])
	}
}

public fw_CmdStart_Post(id, handle)
{
	if (!c_iSemiclip || !c_iButton || !get_bitsum(bs_IsAlive, id) || get_bitsum(bs_IsDying, id) || get_bitsum(bs_IsBot, id) || get_bitsum(bs_InAntiBoost, id))
		return
	
	if (get_uc(handle, UC_Buttons) & c_iButtonTrigger)
	{
		add_bitsum(bs_InButton, id)
	}
	else
	{
		if (get_bitsum(bs_InButton, id))
			add_bitsum(bs_WasInButton, id)
		
		del_bitsum(bs_InButton, id)
		
		if (c_iButtonAntiBoost && get_bitsum(bs_WasInButton, id))
			RangeCheck(id+TASK_RANGE)
	}
}

public fw_Blocked(iBlocked, iBlocker)
{
	if (!c_iSemiclip || get_bitsum_array(bs_IgnoreEntity, iBlocked) || !is_user_valid(iBlocker))
		return FMRES_IGNORED
	
	/* Entity damage handle. */
	return get_bitsum_array(bs_EntityDamage, iBlocked) ? FMRES_IGNORED : FMRES_SUPERCEDE
}

/* Register csbots */
public fw_SetClientKeyValue(id, infobuffer[], key[], value[])
{
	if (value[0] == '1' && equal(key, "*bot"))
	{
		unregister_forward(FM_SetClientKeyValue, g_iHamCsBots, false)
		remove_task(TASK_CSBOTS)
		
		RegisterHamFromEntity(Ham_Spawn, id, "fw_PlayerSpawn_Post", true)
		RegisterHamFromEntity(Ham_Killed, id, "fw_PlayerKilled", false)
		RegisterHamFromEntity(Ham_Player_SemiclipStart, id, "fw_PlayerSemiclip_Start", true)
		RegisterHamFromEntity(Ham_Player_SemiclipEnd, id, "fw_PlayerSemiclip_End", false)
	}
}

/*================================================================================
 [Entity movement fix]
=================================================================================*/

public fw_EntitySemiclip_Start(ent)
{
	if (!c_iSemiclip || get_bitsum_array(bs_IgnoreEntity, ent))
		return
	
	if (PlayerSolidNot(ent, ent) && g_iEntityMovingEnd == 0)
	{
		g_iEntityMovingEnd = register_forward(FM_Entity_MovingEnd, "fw_EntitySemiclip_End", false)
		g_iPlayerClashing = register_forward(FM_Player_Clashing, "fw_PlayerClashing", false)
		g_iLastClashed = 0
	}
}

public fw_EntitySemiclip_End(id)
{
	unregister_forward(FM_Entity_MovingEnd, g_iEntityMovingEnd, false)
	unregister_forward(FM_Player_Clashing, g_iPlayerClashing, false)
	g_iEntityMovingEnd = 0
	
	PlayerSolid(id)
}

public fw_PlayerClashing(id)
{
	if (!is_user_valid_alive(id))
		return
	
	if (g_iLastClashed && get_bitsum(bs_IsSolid, g_iLastClashed))
	{
		set_pev(g_iLastClashed, pev_solid, SOLID_NOT)
		del_bitsum(bs_IsSolid, g_iLastClashed)
	}
	
	if (!get_bitsum(bs_IsSolid, id))
	{
		set_pev(id, pev_solid, SOLID_SLIDEBOX)
		add_bitsum(bs_IsSolid, id)
		g_iLastClashed = id
	}
}

/*================================================================================
 [Unsolid and solid function]
=================================================================================*/

PlayerSolidNot(id, i)
{
	static iNum, Float:flEntityAbsMin[3], Float:flEntityAbsMax[3]
	iNum = 0
	pev(i, pev_absmin, flEntityAbsMin)
	pev(i, pev_absmax, flEntityAbsMax)
	
	for (id = 1; id <= g_iMaxPlayers; id++)
	{
		if (!get_bitsum(bs_IsAlive, id) || get_bitsum(bs_IsDying, id))
			continue
		
		if (!get_bitsum(bs_IsAbsStored, id))
		{
			pev(id, pev_absmin, g_flAbsMin[id])
			pev(id, pev_absmax, g_flAbsMax[id])
			add_bitsum(bs_IsAbsStored, id)
		}
		
		if (GetIntersects(g_flAbsMin[id], g_flAbsMax[id], flEntityAbsMin, flEntityAbsMax))
		{
			for (i = 1; i <= g_iMaxPlayers; i++)
			{
				if (!get_bitsum(bs_IsSolid, i) || i == id || g_iRange[id][i] == OUT_OF_RANGE || !AllowSemiclip(id, i))
					continue
				
				set_pev(i, pev_solid, SOLID_NOT)
				del_bitsum(bs_IsSolid, i)
				iNum++
			}
		}
	}
	
	return iNum
}

PlayerSolid(id)
{
	for (id = 1; id <= g_iMaxPlayers; id++)
	{
		if (get_bitsum(bs_IsSolid, id) || !get_bitsum(bs_IsAlive, id) || get_bitsum(bs_IsDying, id))
			continue
		
		set_pev(id, pev_solid, SOLID_SLIDEBOX)
		add_bitsum(bs_IsSolid, id)
	}
}

GetIntersects(Float:flAbsMin[3], Float:flAbsMax[3], Float:flAbsMin2[3], Float:flAbsMax2[3])
{
	if (flAbsMin[0] > flAbsMax2[0] || flAbsMin[1] > flAbsMax2[1] || flAbsMin[2] > flAbsMax2[2] || flAbsMax[0] < flAbsMin2[0] || flAbsMax[1] < flAbsMin2[1] || flAbsMax[2] < flAbsMin2[2])
	{
		return 0
	}
	return 1
}

/*================================================================================
 [Other Functions and Tasks]
=================================================================================*/

CheckMods()
{
	new szModName[8]
	get_modname(szModName, charsmax(szModName))
	if (equal(szModName, "cstrike")) register_plugin("[CS] Team Semiclip", PLUGIN_VERSION, "schmurgel1983")
	else if (equal(szModName, "czero")) register_plugin("[CZ] Team Semiclip", PLUGIN_VERSION, "schmurgel1983")
	else
	{
		register_plugin("[??] Team Semiclip", PLUGIN_VERSION, "schmurgel1983")
		set_fail_state("Error: This plugin is for cstrike and czero only!")
	}
}

CheckAmxxVersion()
{
	new szBuffer[6]
	get_amxx_verstring(szBuffer, 5)
	
	while (replace(szBuffer, 5, ".", "")) {}
	
	if (str_to_num(szBuffer) < 182)
		set_fail_state("Error: AMX Mod X v1.8.2 or later required!")
}

CheckMaxEntities()
{
	new Float:flValue, iValue
	flValue = float(global_get(glb_maxEntities)) / 32
	iValue = floatround(flValue, floatround_ceil)
	
	if (iValue > MAX_ENT_ARRAY)
	{
		new szError[100]
		format(szError, charsmax(szError), "Error: MAX_ENT_ARRAY is to low! Increase it to: %d and re-compile sma!", iValue)
		set_fail_state(szError)
	}
}

CreateCvarEntityTask()
{
	g_iCvarEntity = create_entity("info_target")
	if (pev_valid(g_iCvarEntity))
	{
		register_think("TSC_CvarEntity", "CacheCvars")
		
		set_pev(g_iCvarEntity, pev_classname, "TSC_CvarEntity")
		set_pev(g_iCvarEntity, pev_nextthink, get_gametime() + 1.0)
	}
	else
	{
		set_task(1.0, "CacheCvars", TASK_CVARS)
		set_task(CVAR_INTERVAL, "CacheCvars", TASK_CVARS, _, _, "b")
	}
}

public StopCsBotForward()
{
	unregister_forward(FM_SetClientKeyValue, g_iHamCsBots, false)
	g_iHamCsBots = 0
}

public CacheCvars(entity)
{
	c_iSemiclip = !!get_pcvar_num(cvar_iSemiclip)
	c_iBlockTeam = clamp(get_pcvar_num(cvar_iSemiclipBlockTeam), 0, 3)
	c_iEnemies = !!get_pcvar_num(cvar_iSemiclipEnemies)
	c_flRadius = floatclamp(get_pcvar_float(cvar_flSemiclipRadius), ANTI_BOOST_DISTANCE, 14116.235352)
	
	c_iButton = clamp(get_pcvar_num(cvar_iSemiclipButton), 0, 3)
	c_iButtonTrigger = clamp(get_pcvar_num(cvar_iSemiclipButtonTrigger), 1, 65535)
	c_iButtonAntiBoost = !!get_pcvar_num(cvar_iSemiclipButtonAntiBoost)
	
	c_iUnstuck = clamp(get_pcvar_num(cvar_iSemiclipUnstuck), 0, 4)
	c_iUnstuckRender = !!get_pcvar_num(cvar_iSemiclipUnstuckRender)
	c_flUnstuckDelay = floatclamp(get_pcvar_float(cvar_flSemiclipUnstuckDelay), 0.0, 3.0)
	
	c_iHostage = clamp(get_pcvar_num(cvar_iSemiclipHostage), 0, 3)
	
	c_iKnifeTrace = !!get_pcvar_num(cvar_iSemiclipKnifeTrace)
	
	c_iRender = clamp(get_pcvar_num(cvar_iSemiclipRender), 0, 2)
	c_iFreeLook = !!get_pcvar_num(cvar_iSemiclipRenderFreeLook)
	
	c_iNormalMode = clamp(get_pcvar_num(cvar_iSemiclipNormalMode), 0, 5)
	c_iNormalFx = clamp(get_pcvar_num(cvar_iSemiclipNormalFx), 0, 20)
	c_iNormalAmt = clamp(get_pcvar_num(cvar_iSemiclipNormalAmt), 0, 255)
	c_iNormalSpec = !!get_pcvar_num(cvar_iSemiclipNormalSpec)
	
	c_iFadeMode = clamp(get_pcvar_num(cvar_iSemiclipFadeMode), 0, 5)
	c_iFadeFx = clamp(get_pcvar_num(cvar_iSemiclipFadeFx), 0, 20)
	c_flFadeMin = floatclamp(get_pcvar_float(cvar_flSemiclipFadeMin), 0.0, 255.0)
	c_flFadeMax = floatclamp(get_pcvar_float(cvar_flSemiclipFadeMax), 0.0, 255.0)
	c_iFadeSpec = !!get_pcvar_num(cvar_iSemiclipFadeSpec)
	
	static index, szColors[12], szRed[4], szGreen[4], szBlue[4]
	for (index = COLOR_CT; index < MAX_COLORS; index++)
	{
		get_pcvar_string(cvar_szSemiclipColors[index], szColors, 11)
		parse(szColors, szRed, 3, szGreen, 3, szBlue, 3)
		c_iColors[index][0] = clamp(str_to_num(szRed), 0, 255)
		c_iColors[index][1] = clamp(str_to_num(szGreen), 0, 255)
		c_iColors[index][2] = clamp(str_to_num(szBlue), 0, 255)
	}
	
	static szFlags[24]
	get_pcvar_string(cvar_szSemiclipColorFlag, szFlags, charsmax(szFlags))	
	c_iColorFlag = read_flags(szFlags)
	
	for (index = 1; index <= g_iMaxPlayers; index++)
	{
		if (!get_bitsum(bs_IsConnected, index))
			continue
		
		/* amx_reloadadmins ? */
		if (get_user_flags(index) & c_iColorFlag) add_bitsum(bs_IsAdmin, index)
		else del_bitsum(bs_IsAdmin, index)
	}
	
	/* No CSDM spawns found */
	if (!g_iSpawnCountCSDM && c_iUnstuck == 2)
	{
		set_pcvar_num(cvar_iSemiclipUnstuck, 1)
		c_iUnstuck = 1
	}
	
	if (entity != TASK_CVARS)
	{
		if (!pev_valid(entity)) set_task(CVAR_INTERVAL, "CacheCvars", TASK_CVARS, _, _, "b")
		else set_pev(entity, pev_nextthink, get_gametime() + CVAR_INTERVAL)
	}
}

public LoadSpawns()
{
	/* Check if Zombie Plague is running */
	if (LibraryExists("zp50_core", LibType_Library))
	{
		Label_FailState:
		plugin_pause()
		set_fail_state("Error: This plugin is not for Zombie Plague Mod")
	}
	else if (get_cvar_pointer("zp_on")) /* Cvar is registered! */
	{
		/* Check if ZP is really running! */
		g_bZpReallyRunning = true
		zp_has_round_started()
		
		if (g_bZpReallyRunning)
			goto Label_FailState
	}
	
	/* Zombie Plague is not running */
	new szConfigDir[32], szMapName[32], szFilePath[100], szLineData[64]
	
	get_configsdir(szConfigDir, charsmax(szConfigDir))
	get_mapname(szMapName, charsmax(szMapName))
	formatex(szFilePath, charsmax(szFilePath), "%s/csdm/%s.spawns.cfg", szConfigDir, szMapName)
	
	if (file_exists(szFilePath))
	{
		new iFile
		if ((iFile = fopen(szFilePath, "rt")) != 0)
		{
			new szDataCSDM[10][6]
			while (!feof(iFile))
			{
				fgets(iFile, szLineData, charsmax(szLineData))
				
				if (!szLineData[0] || str_count(szLineData,' ') < 2)
					continue
				
				parse(szLineData, szDataCSDM[0], 5, szDataCSDM[1], 5, szDataCSDM[2], 5, szDataCSDM[3], 5, szDataCSDM[4], 5, szDataCSDM[5], 5, szDataCSDM[6], 5, szDataCSDM[7], 5, szDataCSDM[8], 5, szDataCSDM[9], 5)
				
				g_flSpawnsCSDM[g_iSpawnCountCSDM][0] = floatstr(szDataCSDM[0])
				g_flSpawnsCSDM[g_iSpawnCountCSDM][1] = floatstr(szDataCSDM[1])
				g_flSpawnsCSDM[g_iSpawnCountCSDM][2] = floatstr(szDataCSDM[2])
				
				if (++g_iSpawnCountCSDM >= MAX_CSDM_SPAWNS)
					break
			}
			fclose(iFile)
			
			goto Label_Collect
		}
	}
	
	if (c_iUnstuck == 2)
	{
		set_pcvar_num(cvar_iSemiclipUnstuck, 1)
		c_iUnstuck = 1
	}
	
	Label_Collect:
	/* CT */
	new iEnt = -1
	while ((iEnt = find_ent_by_class(iEnt, CT_SPAWN_ENTITY_NAME)) != 0)
	{
		new Float:flOrigin[3]
		pev(iEnt, pev_origin, flOrigin)
		g_flSpawnsCTs[g_iSpawnCountCTs][0] = flOrigin[0]
		g_flSpawnsCTs[g_iSpawnCountCTs][1] = flOrigin[1]
		g_flSpawnsCTs[g_iSpawnCountCTs][2] = flOrigin[2]
		
		if (++g_iSpawnCountCTs >= sizeof g_flSpawnsCTs)
			break
	}
	
	/* TERROR */
	iEnt = -1
	while ((iEnt = find_ent_by_class(iEnt, TER_SPAWN_ENTITY_NAME)) != 0)
	{
		new Float:flOrigin[3]
		pev(iEnt, pev_origin, flOrigin)
		g_flSpawnsTer[g_iSpawnCountTer][0] = flOrigin[0]
		g_flSpawnsTer[g_iSpawnCountTer][1] = flOrigin[1]
		g_flSpawnsTer[g_iSpawnCountTer][2] = flOrigin[2]
		
		if (++g_iSpawnCountTer >= sizeof g_flSpawnsTer)
			break
	}
}

public RandomSpawnDelay(id)
{
	DoRandomSpawn(id, c_iUnstuck)
}

/* credits to MeRcyLeZZ */
DoRandomSpawn(id, type)
{
	if (!c_iUnstuck || !get_bitsum(bs_IsAlive, id) || get_bitsum(bs_IsDying, id))
		return
	
	static iHull, iSpawnPoint, i
	iHull = (pev(id, pev_flags) & FL_DUCKING) ? HULL_HEAD : HULL_HUMAN
	
	switch (type)
	{
		case 1: /* Specified team */
		{
			switch (g_iTeam[id])
			{
				case 1: /* TERRORIST */
				{
					if (!g_iSpawnCountTer)
						return
					
					iSpawnPoint = random_num(0, g_iSpawnCountTer - 1)
					
					for (i = iSpawnPoint + 1; /*no condition*/; i++)
					{
						if (i >= g_iSpawnCountTer)
							i = 0
						
						if (is_hull_vacant(g_flSpawnsTer[i], iHull))
						{
							engfunc(EngFunc_SetOrigin, id, g_flSpawnsTer[i])
							break
						}
						
						if (i == iSpawnPoint)
							break
					}
				}
				case 2: /* CT */
				{
					if (!g_iSpawnCountCTs)
						return
					
					iSpawnPoint = random_num(0, g_iSpawnCountCTs - 1)
					
					for (i = iSpawnPoint + 1; /*no condition*/; i++)
					{
						if (i >= g_iSpawnCountCTs)
							i = 0
						
						if (is_hull_vacant(g_flSpawnsCTs[i], iHull))
						{
							engfunc(EngFunc_SetOrigin, id, g_flSpawnsCTs[i])
							break
						}
						
						if (i == iSpawnPoint)
							break
					}
				}
			}
		}
		case 2: /* CSDM */
		{
			if (!g_iSpawnCountCSDM)
				return
			
			iSpawnPoint = random_num(0, g_iSpawnCountCSDM - 1)
			
			for (i = iSpawnPoint + 1; /*no condition*/; i++)
			{
				if (i >= g_iSpawnCountCSDM)
					i = 0
				
				if (is_hull_vacant(g_flSpawnsCSDM[i], iHull))
				{
					engfunc(EngFunc_SetOrigin, id, g_flSpawnsCSDM[i])
					break
				}
				
				if (i == iSpawnPoint)
					break
			}
		}
		case 3: /* Random around own place */
		{
			static const Float:RANDOM_OWN_PLACE[][3] =
			{
				{ -96.5,   0.0, 0.0 },
				{  96.5,   0.0, 0.0 },
				{   0.0, -96.5, 0.0 },
				{   0.0,  96.5, 0.0 },
				{ -96.5, -96.5, 0.0 },
				{ -96.5,  96.5, 0.0 },
				{  96.5,  96.5, 0.0 },
				{  96.5, -96.5, 0.0 }
			}
			
			new Float:flOrigin[3], Float:flOriginFinal[3], iSize
			pev(id, pev_origin, flOrigin)
			iSize = sizeof(RANDOM_OWN_PLACE)
			
			iSpawnPoint = random_num(0, iSize - 1)
			
			for (i = iSpawnPoint + 1; /*no condition*/; i++)
			{
				if (i >= iSize)
					i = 0
				
				flOriginFinal[0] = flOrigin[0] + RANDOM_OWN_PLACE[i][0]
				flOriginFinal[1] = flOrigin[1] + RANDOM_OWN_PLACE[i][1]
				flOriginFinal[2] = flOrigin[2]
				
				engfunc(EngFunc_TraceLine, flOrigin, flOriginFinal, IGNORE_MONSTERS, id, 0)
				
				new Float:flFraction
				get_tr2(0, TR_flFraction, flFraction)
				if (flFraction < 1.0)
				{
					new Float:vTraceEnd[3], Float:vNormal[3]
					get_tr2(0, TR_vecEndPos, vTraceEnd)
					get_tr2(0, TR_vecPlaneNormal, vNormal)
					
					TSC_Vector_MA(vTraceEnd, vNormal, 32.5, flOriginFinal)
				}
				flOriginFinal[2] -= 35.0
				
				new iZ = 0
				do
				{
					if (is_hull_vacant(flOriginFinal, iHull))
					{
						i = iSpawnPoint
						engfunc(EngFunc_SetOrigin, id, flOriginFinal)
						break
					}
					
					flOriginFinal[2] += 40.0
				}
				while (++iZ <= 2)
				
				if (i == iSpawnPoint)
					break
			}
		}
		case 4: /* Trespass */
		{
			new iNum, iPlayer, iPlayers[32]
			iNum = find_sphere_class(id, "player", 102.0, iPlayers, g_iMaxPlayers)
			
			for (--iNum; iNum >= 0; iNum--)
			{
				iPlayer = iPlayers[iNum]
				
				if (id == iPlayer || g_iAntiBoost[id][iPlayer])
					continue
				
				SetBoosting(id, iPlayer, 1)
			}
		}
	}
}

public RangeCheck(taskid)
{
	if (!c_iSemiclip)
		return
	
	static id
	for (id = 1; id <= g_iMaxPlayers; id++)
	{
		if (!get_bitsum(bs_IsAlive, id))
			continue
		
		g_iRange[ID_RANGE][id] = CalculateAmount(ID_RANGE, id)
		
		if (c_iUnstuck == 4 && g_iAntiBoost[ID_RANGE][id])
			goto Label_Trespass
		
		if (!c_iButtonAntiBoost || ID_RANGE == id)
			continue
		
		/* Anti boosting */
		switch (c_iButton)
		{
			case 3: /* BOTH */
			{
				if ((get_bitsum(bs_InButton, ID_RANGE) || get_bitsum(bs_WasInButton, ID_RANGE)) && !g_iAntiBoost[ID_RANGE][id] && entity_range(ID_RANGE, id) <= ANTI_BOOST_DISTANCE)
				{
					if (!c_iEnemies && !is_same_team(id, ID_RANGE))
						continue
					
					SetBoosting(ID_RANGE, id, 1)
				}
				else if (g_iAntiBoost[ID_RANGE][id] && entity_range(ID_RANGE, id) > ANTI_BOOST_DISTANCE)
				{
					SetBoosting(ID_RANGE, id, 0)
				}
			}
			case 1, 2: /* CT or TERROR */
			{
				if ((get_bitsum(bs_InButton, ID_RANGE) || get_bitsum(bs_WasInButton, ID_RANGE)) && !g_iAntiBoost[ID_RANGE][id] && c_iButton == g_iTeam[ID_RANGE] && c_iButton == g_iTeam[id] && entity_range(ID_RANGE, id) <= ANTI_BOOST_DISTANCE)
				{
					if (c_iEnemies && !is_same_team(id, ID_RANGE))
						continue
					
					SetBoosting(ID_RANGE, id, 1)
				}
				else if (g_iAntiBoost[ID_RANGE][id] && entity_range(ID_RANGE, id) > ANTI_BOOST_DISTANCE)
				{
					SetBoosting(ID_RANGE, id, 0)
				}
			}
			case -1: /* Trespass */
			{
				Label_Trespass:
				if (entity_range(ID_RANGE, id) > ANTI_BOOST_DISTANCE)
				{
					SetBoosting(ID_RANGE, id, 0)
				}
			}
			default: continue
		}
	}
	del_bitsum(bs_WasInButton, ID_RANGE)
	
	if (c_iHostage && g_iHostageCount)
	{
		static iHos
		for (id = 0; id < g_iHostageCount; id++)
		{
			iHos = g_iHostage[id]
			
			if (get_bitsum_array(bs_HostageIsRescued, iHos))
				continue
			
			g_iHostageRange[ID_RANGE][id] = CalculateAmount(ID_RANGE, iHos)
		}
	}
}

SetBoosting(iBooster, iOther, Set)
{
	if (Set)
	{
		add_bitsum(bs_InAntiBoost, iBooster)
		add_bitsum(bs_InButton, iBooster)
		g_iAntiBoost[iBooster][iOther] = 1
		
		add_bitsum(bs_InAntiBoost, iOther)
		add_bitsum(bs_InButton, iOther)
		g_iAntiBoost[iOther][iBooster] = 1
	}
	else
	{
		g_iAntiBoost[iBooster][iOther] = 0
		
		for (iOther = 1; iOther <= g_iMaxPlayers; iOther++)
		{
			Set += g_iAntiBoost[iBooster][iOther]
		}
		
		if (!Set)
		{
			del_bitsum(bs_InAntiBoost, iBooster)
		}
	}
}

public SpectatorCheck(taskid)
{
	if (!c_iSemiclip || get_bitsum(bs_IsAlive, ID_SPECTATOR) || get_bitsum(bs_IsDying, ID_SPECTATOR))
		return
	
	static iTarget
	iTarget = pev(ID_SPECTATOR, pev_spec_target)
	
	if (c_iFreeLook && !is_user_valid(iTarget)) goto Label_FreeLook
	else
	{
		Label_SetTarget:
		g_iSpectating[ID_SPECTATOR] = iTarget
		g_iSpectatingTeam[ID_SPECTATOR] = g_iTeam[iTarget]
		return
	}
	
	Label_FreeLook:
	if (pev(ID_SPECTATOR, pev_spec_mode) != 3)
		return
	
	iTarget = fm_cs_get_free_look_target(ID_SPECTATOR)
	
	if (is_user_valid(iTarget))
		goto Label_SetTarget
}

CalculateAmount(host, ent)
{
	/* Fade */
	if (c_iRender == 2)
	{
		static Float:flRange
		flRange = entity_range(host, ent)
		
		if (flRange > c_flRadius)
			return OUT_OF_RANGE
		
		static Float:flAmount
		flAmount = flRange / (c_flRadius / (c_flFadeMax - c_flFadeMin))
		
		return floatround((flAmount >= 0.0) ? flAmount + c_flFadeMin : floatabs(flAmount - c_flFadeMax))
	}
	
	return (entity_range(host, ent) <= c_flRadius) ? c_iNormalAmt : OUT_OF_RANGE
}

AllowSemiclip(host, ent)
{
	if (g_bPreparation || g_iAntiBoost[host][ent])
		return 1
	
	switch (c_iButton)
	{
		case 3: /* BOTH */
		{
			if (get_bitsum(bs_InButton, host))
			{
				if (!c_iEnemies && !is_same_team(ent, host))
					return 0
			}
			else if (QueryEnemies(host, ent))
				return 0
		}
		case 1, 2: /* CT or TERROR */
		{
			if (get_bitsum(bs_InButton, host) && c_iButton == g_iTeam[host] && c_iButton == g_iTeam[ent])
			{
				if (c_iEnemies && !is_same_team(ent, host))
					return 0
			}
			else if (QueryEnemies(host, ent))
				return 0
		}
		default:
		{
			if (QueryEnemies(host, ent))
				return 0
		}
	}
	return 1
}

QueryEnemies(host, ent)
{
	if (c_iBlockTeam == 3)
		return 1
	
	switch (c_iEnemies)
	{
		case 1: if (c_iBlockTeam == g_iTeam[ent] && is_same_team(ent, host)) return 1
		case 0: if (!is_same_team(ent, host) || c_iBlockTeam == g_iTeam[ent]) return 1
	}
	
	return 0
}

public DisableTask(taskid)
{
	g_bPreparation = false
	
	if (taskid != TASK_DURATION)
	{
		new id, bs_IsStucking, iCts, iTerrorists, iTeam, iEnemy
		for (id = 1; id <= g_iMaxPlayers; id++)
		{
			if (!get_bitsum(bs_IsAlive, id) || get_bitsum(bs_IsDying, id) || !tsc_is_player_stuck(id))
				continue
			
			add_bitsum(bs_IsStucking, id)
			
			switch (g_iTeam[id])
			{
				case 1: iTerrorists++
				case 2: iCts++
			}
		}
		
		if (iCts == iTerrorists) iTeam = random_num(1, 2)
		else if (iTerrorists > iCts) iTeam = 1
		else iTeam = 2
		
		for (id = 1; id <= g_iMaxPlayers; id++)
		{
			if (!get_bitsum(bs_IsStucking, id))
				continue
			
			if (g_iTeam[id] == iTeam)
			{
				if (!get_bitsum(bs_InButton, id) && (c_iButton == iTeam || c_iButton == 3))
					DoRandomSpawn(id, c_iUnstuck)
				
				continue
			}
			
			if (c_iButton)
			{
				if (!c_iEnemies || (iEnemy && !get_bitsum(bs_InButton, id)))
				{
					DoRandomSpawn(id, c_iUnstuck)
					continue
				}
				else if (iEnemy && !get_bitsum(bs_InButton, iEnemy))
					DoRandomSpawn(iEnemy, c_iUnstuck)
				
				iEnemy = id
				continue
			}
			
			if (!c_iEnemies)
				DoRandomSpawn(id, c_iUnstuck)
		}
		return
	}
	
	/* Duration has higher priority as Preparation */
	remove_task(TASK_PREPARATION)
	set_pcvar_num(cvar_iSemiclip, 0)
	c_iSemiclip = 0
	
	for (new id = 1; id <= g_iMaxPlayers; id++)
	{
		if (!get_bitsum(bs_IsAlive, id) || get_bitsum(bs_IsDying, id))
			continue
		
		if (!get_bitsum(bs_IsSolid, id))
		{
			set_pev(id, pev_solid, SOLID_SLIDEBOX)
			add_bitsum(bs_IsSolid, id)
		}
		
		if (tsc_is_player_stuck(id))
			DoRandomSpawn(id, c_iUnstuck)
	}
}

TeamInfoUnstuck(id)
{
	if (!c_iUnstuck || !get_bitsum(bs_IsAlive, id) || get_bitsum(bs_IsDying, id) || !tsc_is_player_stuck(id))
		return 0
	
	if (c_iUnstuck == 4)
		return 1
	
	static i
	for (i = 1; i <= g_iMaxPlayers; i++)
	{
		if (!get_bitsum(bs_IsAlive, i) || get_bitsum(bs_IsDying, i) || i == id || g_iRange[id][i] == OUT_OF_RANGE || !tsc_is_player_stuck(i))
			continue
		
		if (c_iButton)
		{
			if (c_iEnemies)
			{
				if (!get_bitsum(bs_InButton, id) && c_iButton == g_iTeam[i])
					return 1
				
				return 0
			}
			
			return !is_same_team(id, i)
		}
		
		if (QueryEnemies(id, i))
			return 1
	}
	
	return 0
}

SetUserCvars(id)
{
	del_bitsum(bs_IsAlive, id)
	del_bitsum(bs_IsDying, id)
	del_bitsum(bs_IsBot, id)
	del_bitsum(bs_InSemiclip, id)
	del_bitsum(bs_IsSolid, id)
	del_bitsum(bs_InKnifeSecAtk, id)
	g_iTeam[id] = _:CS_TEAM_UNASSIGNED
	
	del_bitsum(bs_RenderSpecial, id)
	del_bitsum(bs_IsVip, id)
	
	arrayset(g_iAntiBoost[id], 0, MAX_PLAYERS)
	arrayset(g_iRange[id], OUT_OF_RANGE, MAX_PLAYERS)
	arrayset(g_iHostageRange[id], OUT_OF_RANGE, MAX_HOSTAGE)
}

public LoadSemiclipFile()
{
	new szFilePath[96], szMapName[32]
	
	get_configsdir(szFilePath, charsmax(szFilePath))
	get_mapname(szMapName, charsmax(szMapName))
	format(szFilePath, charsmax(szFilePath), "%s/scm/entities/%s.ini", szFilePath, szMapName)
	
	if (!file_exists(szFilePath))
		return
	
	/* Disable ham forwards */
	for (new i = 0; i < g_iFuncNum; i++)
		DisableHamForward(g_iHamFuncForwards[i])
	
	/* Reset Damage */
	for (new i = 0; i < MAX_ENT_ARRAY; i++)
		bs_EntityDamage[i] = 0
	
	/* Create Trie: */
	if (TrieFunctions == Invalid_Trie)
		TrieFunctions = TrieCreate()
	
	new iFile
	if ((iFile = fopen(szFilePath, "rt")) != 0)
	{
		if (TrieFunctions != Invalid_Trie)
		{
			new szLineData[64], szData[4][32]
			while (!feof(iFile))
			{
				fgets(iFile, szLineData, charsmax(szLineData))
				replace(szLineData, charsmax(szLineData), "^n", "")
				
				if (!szLineData[0] || szLineData[0] == '/' || szLineData[0] == ';' || szLineData[0] == '#')
					continue
				
				/* func *model semiclip damage */
				parse(szLineData, szData[0], charsmax(szData[]), szData[1], 7, szData[2], 7, szData[3], 7)
				
				/* Get Entity Index */
				new iEntity = find_ent_by_model(0, szData[0], szData[1])
				
				/* Entity not found */
				if (!iEntity)
					continue
				
				/* Ignore entity */
				if (equal(szData[2], "ignore"))
				{
					add_bitsum_array(bs_IgnoreEntity, iEntity)
					continue
				}
				
				/* Register HamForward */
				if (!TrieKeyExists(TrieFunctions, szData[0]))
				{
					g_iHamFuncForwards[g_iFuncNum] = RegisterHam(Ham_Entity_SemiclipStart, szData[0], "fw_EntitySemiclip_Start", true)
					TrieSetCell(TrieFunctions, szData[0], g_iFuncNum)
					g_iFuncNum++
				}
				else
				{
					new iValue
					if (TrieGetCell(TrieFunctions, szData[0], iValue))
					{
						EnableHamForward(g_iHamFuncForwards[iValue])
					}
					else
					{
						abort(AMX_ERR_NATIVE, "Can't Re-enable %s (%d).", szData[0], iValue)
					}
				}
				
				/* Entity damage */
				if (equal(szData[3], "enable"))
				{
					add_bitsum_array(bs_EntityDamage, iEntity)
				}
			}
			fclose(iFile)
		}
		else
		{
			fclose(iFile)
			abort(AMX_ERR_NATIVE, "Failed to create Trie:Variable.")
		}
	}
	else
	{
		abort(AMX_ERR_NATIVE, "Failed to open ^"%s^" file.", szFilePath)
	}
}

/*================================================================================
 [Message Hooks]
=================================================================================*/

public MessageTeamInfo(msg_id, msg_dest)
{
	if (msg_dest != MSG_ALL && msg_dest != MSG_BROADCAST)
		return
	
	static id, szTeam[2]
	id = get_msg_arg_int(1)
	get_msg_arg_string(2, szTeam, charsmax(szTeam))
	
	switch (szTeam[0])
	{
		case 'T': g_iTeam[id] = _:CS_TEAM_T
		case 'C': g_iTeam[id] = _:CS_TEAM_CT
		case 'S':
		{
			if (get_bitsum(bs_IsDying, id))
			{
				del_bitsum(bs_IsAlive, id)
				del_bitsum(bs_IsDying, id)
				
				g_iSpectatingTeam[id] = g_iTeam[id]
				
				if (!get_bitsum(bs_IsBot, id))
					set_task(SPEC_INTERVAL, "SpectatorCheck", id+TASK_SPECTATOR, _, _, "b")
			}
			else
			{
				g_iSpectatingTeam[id] = c_iHostage
			}
			
			g_iSpectating[id] = id
			g_iTeam[id] = _:CS_TEAM_SPECTATOR
			return
		}
		default:
		{
			g_iTeam[id] = _:CS_TEAM_UNASSIGNED
			return
		}
	}
	g_iSpectating[id] = id
	g_iSpectatingTeam[id] = g_iTeam[id]
	
	if (TeamInfoUnstuck(id))
	{
		if (c_flUnstuckDelay >= 0.1) set_task(c_flUnstuckDelay, "RandomSpawnDelay", id)
		else DoRandomSpawn(id, c_iUnstuck)
	}
}

public MessageClCorpse(msg_id, msg_dest)
{
	if (msg_dest != MSG_ALL && msg_dest != MSG_BROADCAST)
		return
	
	static id
	id = get_msg_arg_int(12)
	
	if (get_bitsum(bs_IsDying, id))
	{
		del_bitsum(bs_IsAlive, id)
		del_bitsum(bs_IsDying, id)
		g_iTeam[id] = _:CS_TEAM_SPECTATOR
		
		if (!get_bitsum(bs_IsBot, id))
			set_task(SPEC_INTERVAL, "SpectatorCheck", id+TASK_SPECTATOR, _, _, "b")
	}
}

/*================================================================================
 [Custom Natives]
=================================================================================*/

/* tsc_get_user_rendering(id) */
public fn_get_user_rendering(plugin_id, num_params)
{
	new id = get_param(1)
	
	if (!is_user_valid_connected(id))
	{
		log_error(AMX_ERR_NATIVE, "[Team Semiclip] Player is not in game (%d)", id)
		return -1
	}
	
	return get_bitsum(bs_RenderSpecial, id) ? 1 : 0
}

/* tsc_set_user_rendering(id, special = 0, fx = kRenderFxNone, r = 255, g = 255, b = 255, render = kRenderNormal, amount = 16) */
public fn_set_user_rendering(plugin_id, num_params)
{
	new id = get_param(1)
	
	if (!is_user_valid_connected(id))
	{
		log_error(AMX_ERR_NATIVE, "[Team Semiclip] Player is not in game (%d)", id)
		return -1
	}
	
	switch (get_param(2))
	{
		case 0:
		{
			del_bitsum(bs_RenderSpecial, id)
			
			return 1
		}
		case 1:
		{
			add_bitsum(bs_RenderSpecial, id)
			
			g_iRenderSpecial[id][SPECIAL_FX] = clamp(get_param(3), 0, 20)
			
			g_iRenderSpecialColor[id][0] = clamp(get_param(4), 0, 255)
			g_iRenderSpecialColor[id][1] = clamp(get_param(5), 0, 255)
			g_iRenderSpecialColor[id][2] = clamp(get_param(6), 0, 255)
			
			g_iRenderSpecial[id][SPECIAL_MODE] = clamp(get_param(7), 0, 5)
			g_iRenderSpecial[id][SPECIAL_AMT] = clamp(get_param(8), 0, 255)
			
			return 1
		}
	}
	
	return 0
}

/* tsc_get_user_semiclip(id) */
public fn_get_user_semiclip(plugin_id, num_params)
{
	new id = get_param(1)
	
	if (!is_user_valid_connected(id))
	{
		log_error(AMX_ERR_NATIVE, "[Team Semiclip] Player is not in game (%d)", id)
		return -1
	}
	
	return get_bitsum(bs_InSemiclip, id) ? 1 : 0
}

/* tsc_get_user_anti_boost(id, other = 0) */
public fn_get_user_anti_boost(plugin_id, num_params)
{
	new id = get_param(1)
	
	if (!is_user_valid_connected(id))
	{
		log_error(AMX_ERR_NATIVE, "[Team Semiclip] Player is not in game (%d)", id)
		return -1
	}
	
	new other = get_param(2)
	
	if (other == 0) return get_bitsum(bs_InAntiBoost, id) ? 1 : 0
	else if (!is_user_valid_connected(other))
	{
		log_error(AMX_ERR_NATIVE, "[Team Semiclip] Other player is not in game (%d)", other)
		return -1
	}
	
	return g_iAntiBoost[id][other]
}

/* scm_load_ini_file() */
public fn_load_ini_file(plugin_id, num_params)
{
	if (is_plugin_loaded("tsc_file_editor.amxx", true) != plugin_id)
	{
		log_error(AMX_ERR_NATIVE, "[Team Semiclip] Plugin has no access permission for scm_load_ini_file.")
		return 0
	}
	
	LoadSemiclipFile()
	return 1
}

/*================================================================================
 [Stocks]
=================================================================================*/

stock tsc_is_player_stuck(id)
{
	if (!get_bitsum(bs_IsSolid, id) || get_bitsum(bs_InSemiclip, id))
		return true;
	
	return false;
}

/* credits to VEN */
stock is_hull_vacant(Float:origin[3], hull)
{
	engfunc(EngFunc_TraceHull, origin, origin, DONT_IGNORE_MONSTERS, hull, 0, 0)
	
	if (!get_tr2(0, TR_StartSolid) && !get_tr2(0, TR_AllSolid) && get_tr2(0, TR_InOpen))
		return true
	
	return false
}

/* Stock by (probably) Twilight Suzuka -counts number of chars in a string */
stock str_count(str[], searchchar)
{
	new count, i, len = strlen(str)
	
	for (i = 0; i <= len; i++)
	{
		if (str[i] == searchchar)
			count++
	}
	
	return count
}

/* credits to MeRcyLeZZ */
stock ham_cs_get_weapon_ent_owner(ent)
{
	return (pev_valid(ent) == pdata_safe) ? get_pdata_cbase(ent, m_pPlayer, linux_weapons_diff, mac_weapons_diff) : 0
}

/* credits to me */
stock fm_cs_get_free_look_target(id)
{
	return (pev_valid(id) == pdata_safe) ? get_pdata_int(id, m_hObserverTarget, linux_diff, mac_diff) : 0
}

/* amxmisc.inc */
stock get_configsdir(name[], len)
{
	return get_localinfo("amxx_configsdir", name, len)
}
