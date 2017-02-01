/*	Copyright © 2009, ConnorMcLeod

	DeathRun Lock Buttons is free software;
	you can redistribute it and/or modify it under the terms of the
	GNU General Public License as published by the Free Software Foundation.

	This program is distributed in the hope that it will be useful,
	but WITHOUT ANY WARRANTY; without even the implied warranty of
	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
	GNU General Public License for more details.

	You should have received a copy of the GNU General Public License
	along with DeathRun Lock Buttons; if not, write to the
	Free Software Foundation, Inc., 59 Temple Place - Suite 330,
	Boston, MA 02111-1307, USA.
*/

#include <amxmodx>
#include <fakemeta>
#include <hamsandwich>
#include <xs>

#define PLUGIN "DeathRun Lock Buttons"
#define AUTHOR "ConnorMcLeod"
#define VERSION "0.1.5"

/***************** EDITABLE **********************/
#define LOCK_SOUND "buttons/lever4.wav"
#define LOCKED_SOUND "buttons/latchlocked1.wav"
#define UNLOCK_SOUND "buttons/button3.wav"
#define ALREADY_LOCKED_SOUND "buttons/button4.wav"
#define BUTTON_VOLUME 0.5
/*************************************************/

#define MAX_PLAYERS	32
#define USE_SET 2

const m_pPlayer = 41

const m_iTeam = 114

new g_iMaxPlayers
new g_iButton[MAX_PLAYERS+1]
new Float:g_fLockedTime[MAX_PLAYERS+1]
new Float:g_fNextUse[MAX_PLAYERS+1]

new g_pCvarMaxDistLock, g_pCvarMaxDistKeepLock, g_pCvarMaxTimeKeepLock, g_pCvarUseDelay

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	register_dictionary("drbuttons.txt")

	g_pCvarMaxDistLock = register_cvar("dr_lock_dist", "100")
	g_pCvarMaxDistKeepLock = register_cvar("dr_keeplock_dist", "750")
	g_pCvarMaxTimeKeepLock = register_cvar("dr_keeplock_time", "30")
	g_pCvarUseDelay = register_cvar("dr_lock_delay", "5.0")

	register_event("HLTV", "Event_HLTV_New_Round", "a", "1=0", "2=0")

	RegisterHam(Ham_Spawn, "player", "Player_Spawn", 1)
	RegisterHam(Ham_Killed, "player", "Player_Killed", 1)
	
	RegisterHam(Ham_Use, "func_button", "FuncButton_Use")
	RegisterHam(Ham_Weapon_PrimaryAttack, "weapon_knife", "Knife_Attack")
	RegisterHam(Ham_Weapon_SecondaryAttack, "weapon_knife", "Knife_Attack")

	g_iMaxPlayers = get_maxplayers()
}

public plugin_precache()
{
	precache_sound( LOCKED_SOUND )
	precache_sound( LOCK_SOUND )
	precache_sound( UNLOCK_SOUND )
	precache_sound( ALREADY_LOCKED_SOUND )
}

public Event_HLTV_New_Round()
{
	UnLock_AllButtons()
}

public Player_Spawn( id )
{
	UnLock_PlayerButton( id )
}

public Player_Killed( id )
{
	UnLock_PlayerButton( id )
}

public client_disconnect( id )
{
	UnLock_PlayerButton( id )
}

LockButton(iButton, id)
{
	UnLock_PlayerButton( id )
	if( pev_valid( iButton ) )
	{
		set_pev(iButton, pev_iuser4, id)
		g_iButton[id] = iButton
		g_fLockedTime[id] = get_gametime()
		emit_sound(iButton, CHAN_VOICE, LOCK_SOUND, BUTTON_VOLUME, ATTN_NORM, 0, PITCH_NORM)
		client_print(id, print_center, "%L", id, "DR_LOCKED", get_pcvar_num(g_pCvarMaxTimeKeepLock))
	}
}

UnLock_PlayerButton( id )
{
	new iButton = g_iButton[id]
	if( iButton && pev_valid(iButton) )
	{
		if( pev(iButton, pev_iuser4) == id )
		{
			set_pev(iButton, pev_iuser4, 0)
		}
	}
	g_iButton[id] = 0
}

UnLock_Button( iButton )
{
	if( pev_valid(iButton) )
	{
		new id
		if( (id = pev(iButton, pev_iuser4)) )
		{
			set_pev(iButton, pev_iuser4, 0)
			g_iButton[id] = 0
		}
	}
}

UnLock_AllButtons()
{
	new iButton = g_iMaxPlayers
	while( (iButton = engfunc(EngFunc_FindEntityByString, iButton, "classname", "func_button")) )
	{
		UnLock_Button( iButton )
	}
}

Is_Button_Locked( iButton, id=0 )
{
	if(id == 0)
	{
		id = pev(iButton, pev_iuser4)
	}

	if(	is_user_alive(id)
	&&	get_button_dist(id, iButton) <= get_pcvar_float(g_pCvarMaxDistKeepLock)
	&& 	get_gametime() - g_fLockedTime[id] <= get_pcvar_float(g_pCvarMaxTimeKeepLock)	)
	{
		return 1
	}
	return 0
}

public FuncButton_Use(iButton, iActivator, iCaller, iUseType, Float:fValue)
{
	if(	!(1 <= iActivator <= g_iMaxPlayers)
	||	iUseType != USE_SET
	||	get_pdata_int(iActivator, m_iTeam, 5) != 1	)
	{
		return HAM_IGNORED
	}

	new id = pev(iButton, pev_iuser4)
	if( id && id != iActivator )
	{
		if( Is_Button_Locked(iButton, id) )
		{
			client_print(iActivator, print_center, "%L", iActivator, "DR_RESERVED")
			emit_sound(iButton, CHAN_VOICE, LOCKED_SOUND, BUTTON_VOLUME, ATTN_NORM, 0, PITCH_NORM)
			return HAM_SUPERCEDE
		}
		UnLock_PlayerButton( id )
	}

	UnLock_Button( iButton )
	return HAM_IGNORED
}

public Knife_Attack(iEnt)
{
	static id ; id = get_pdata_cbase(iEnt, m_pPlayer, 4)

	if( get_pdata_int(id, m_iTeam, 5) != 1 )
	{
		return
	}

	static Float:fTime ; fTime = get_gametime()
	if( g_fNextUse[id] > fTime )
	{
		return
	}

	new iButton = Get_AimedButton(id)
	if( !iButton )
	{
		return
	}

	if( Is_Button_Locked( iButton ) )
	{
		if( g_iButton[id] == iButton )
		{
			client_print(id, print_center, "%L", id, "DR_UNLOCKED")
			emit_sound(iButton, CHAN_VOICE, UNLOCK_SOUND, BUTTON_VOLUME, ATTN_NORM, 0, PITCH_NORM)
			UnLock_PlayerButton( id )
			g_fNextUse[id] = fTime + get_pcvar_float(g_pCvarUseDelay)
			return
		}
		else
		{
			client_print(id, print_center, "%L", id, "DR_AR_LOCKED")
			emit_sound(iButton, CHAN_VOICE, ALREADY_LOCKED_SOUND, BUTTON_VOLUME, ATTN_NORM, 0, PITCH_NORM)
			return
		}
	}

	g_fNextUse[id] = fTime + get_pcvar_float(g_pCvarUseDelay)
	UnLock_PlayerButton( id )
	LockButton(iButton, id)
}

Get_AimedButton(id)
{
	new Float:flStart[3], Float:flAim[3]

	pev(id, pev_origin, flStart)
	pev(id, pev_view_ofs, flAim)
	xs_vec_add(flStart, flAim, flStart)

	pev(id, pev_v_angle, flAim)	
	engfunc(EngFunc_MakeVectors, flAim)
	global_get(glb_v_forward, flAim)
	xs_vec_mul_scalar(flAim, get_pcvar_float(g_pCvarMaxDistLock), flAim)

	xs_vec_add(flStart, flAim, flAim)

	engfunc(EngFunc_TraceLine, flStart, flAim, 0, id, 0)

	new iEnt = get_tr2(0, TR_pHit)
	if( pev_valid(iEnt) )
	{
		new szClassName[13]
		pev(iEnt, pev_classname, szClassName, charsmax(szClassName))
		if( equal(szClassName, "func_button") )
		{
			return iEnt
		}
	}
	return 0
}

Float:get_button_dist(id, iButton)
{
	if( !is_user_alive(id) || !pev_valid(iButton) )
	{
		return 9999.9
	}

	new Float:fOrig1[3], Float:fOrig2[3]
	pev(iButton, pev_maxs, fOrig2)
	pev(iButton, pev_mins, fOrig1)
	xs_vec_add(fOrig1, fOrig2, fOrig1)
	xs_vec_mul_scalar(fOrig1, 0.5, fOrig1)

	pev(id, pev_origin, fOrig2)
	xs_vec_sub(fOrig2, fOrig1, fOrig2)

	return xs_vec_len(fOrig2)
}