/********************************************************************************
*  AMX Mod X script.
*
*   SH Gloce (sh_gloce.sma)
*   Copyright (C) 2008 Atomen
*
*   This program is free software; you can redistribute it and/or
*   modify it under the terms of the GNU General Public License
*   as published by the Free Software Foundation; either version 2
*   of the License, or (at your option) any later version.
*
*   This program is distributed in the hope that it will be useful,
*   but WITHOUT ANY WARRANTY; without even the implied warranty of
*   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
*   GNU General Public License for more details.
*
*   You should have received a copy of the GNU General Public License
*   along with this program; if not, write to the Free Software
*   Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
*
*   In addition, as a special exception, the author gives permission to
*   link the code of this program with the Half-Life Game Engine ("HL
*   Engine") and Modified Game Libraries ("MODs") developed by Valve,
*   L.L.C ("Valve"). You must obey the GNU General Public License in all
*   respects for all of the code used other than the HL Engine and MODs
*   from Valve. If you modify this file, you may extend this exception
*   to your version of the file, but you are not obligated to do so. If
*   you do not wish to do so, delete this exception statement from your
*   version.
*
*********************************************************************************

//Gloce
gloce_level 7			//Hero Level
gloce_glock 1			//Receive glock on (re)spawn
gloce_percent 30		//Percent to freeze enemy
gloce_times 5			//Amounts of time to freeze per spawn
gloce_freeze_time 5		//How long they should be frozen
*/

#include <amxmodx>
#include <superheromod>
#include <hamsandwich>
#include <fakemeta>

#define USE_MODEL

#define gVERSION "1.1"
#define GLOCE_DSPT "Icy Powers - Slow down your enemies with your Ice glock"

new const g_sound[]	=	"warcraft3/frostnova.wav"
new const g_sprite[]	=	"sprites/white.spr"

#if defined USE_MODEL
 new const g_model[]	=	"models/shmod/v_gloce.mdl"
#endif

new gloce_glock
new gloce_pct

new gloce_times
new gloce_time

new g_spriteRing
new v_model

new bool:slowed[33]
new Float:g_fMaxSpeed[33]

new g_HeroName[] = "Gloce"
new g_HasPower[SH_MAXSLOTS+1]

new times_id[SH_MAXSLOTS+1]

public plugin_init()
{
	//Register Plugin
	register_plugin("SUPERHERO Gloce", gVERSION, "[A]tomen")

	//Register Events
	register_event("CurWeapon", "weapon_event", "be", "1=1")

	register_forward(FM_ClientConnect, "fwd_Client_Connect")
	register_forward(FM_ClientDisconnect, "fwd_Client_Disconnect")

	RegisterHam(Ham_Spawn, "player", "fwd_Ham_Spawn_post", 1)
	RegisterHam(Ham_TakeDamage, "player", "fwd_Ham_TakeDamage_post")

	//Register Cvars
	register_cvar("gloce_level", "7" )
	register_cvar("gloce_version", gVERSION, FCVAR_SERVER|FCVAR_SPONLY)

	gloce_glock = register_cvar("gloce_glock", "1")
	gloce_pct = register_cvar("gloce_percent", "30")

	gloce_times = register_cvar("gloce_times", "5")
	gloce_time = register_cvar("gloce_freeze_time", "5")

	//Create Hero
	shCreateHero(g_HeroName, "Ice Glock", GLOCE_DSPT, false, "gloce_level")

	//Register Hero
	register_srvcmd("gloce_init", "gloce_init")
	shRegHeroInit(g_HeroName, "gloce_init")
}

public plugin_precache()
{
	precache_sound(g_sound)
	g_spriteRing = precache_model(g_sprite)

	#if defined USE_MODEL
	 v_model = precache_model(g_model)
	#endif
}

public gloce_init()
{
	new temp[6]
	read_argv(1,temp,5)
	new id = str_to_num(temp)

	read_argv(2,temp,5)
	new hasPowers = str_to_num(temp)

	g_HasPower[id] = (hasPowers != 0)

	if(g_HasPower[id])
	{
		times_id[id] = get_pcvar_num(gloce_times)

		#if defined USE_MODEL
		 gloce_v_model(id)
		#endif
	}
}

public gloce_v_model(id)
{
	new weapon = get_user_weapon(id)

	if(weapon == CSW_GLOCK18 && is_user_connected(id) && g_HasPower[id] && shModActive())
		set_pev(id, pev_viewmodel2, v_model)
}

public fwd_Ham_Spawn_post(id)
{
	if(is_user_alive(id) && shModActive() && is_user_connected(id))
	{
		pev(id, pev_maxspeed, g_fMaxSpeed[id])

		times_id[id] = get_pcvar_num(gloce_times)
		if(g_HasPower[id] && get_pcvar_num(gloce_glock))
		{
			ham_give_weapon(id, "weapon_glock18")
			ExecuteHam(Ham_GiveAmmo, id, 80, "9mm", 120)
		}
	}

	return HAM_IGNORED
}

public fwd_Ham_TakeDamage_post(id, nothing, Attacker, Float:fDamage)
{
	if(Attacker == 0) return HAM_IGNORED

	else if(is_user_alive(id) && shModActive() && is_user_connected(id))
	{
		new Float:fHealth
		pev(id, pev_health, fHealth)

		if(fHealth - fDamage > 0.0)
		{
			new weapon = get_user_weapon(Attacker)
			if(weapon == CSW_GLOCK18 && g_HasPower[Attacker] && times_id[Attacker] > 0)
			{
				if(random_num(0, 100) <= get_pcvar_num(gloce_pct))
				{
					new Float:fMaxSpeed
					pev(id, pev_maxspeed, fMaxSpeed)

					if(fMaxSpeed != g_fMaxSpeed[id] && fMaxSpeed != 130.0)
					{
						g_fMaxSpeed[id] = fMaxSpeed
					}

					if(task_exists(id))
						remove_task(id)

					new origin[3]
					get_user_origin(id, origin)

					set_pev(id, pev_maxspeed, 130.0)
					fm_set_rendering(id, kRenderFxGlowShell, 30, 125, 255, kRenderNormal, 0)

					emit_sound(id, CHAN_WEAPON, g_sound, 1.0, ATTN_NORM, 0, PITCH_NORM)

					//Make the screen blue
					message_begin(MSG_ONE, get_user_msgid("ScreenFade"), {0,0,0}, id)
					write_short(~0)
					write_short(~0)
					write_short(0x0004)
					write_byte(30)
					write_byte(125)
					write_byte(255)
					write_byte(100)
					message_end()

					ring_effect(origin, 225, 5, 30, 125, 255)

					slowed[id] = true

					set_task(get_pcvar_float(gloce_time), "remove_frozen", id)
					times_id[Attacker]--
				}
			}
		}
	}

	return HAM_IGNORED
}

public weapon_event(id)
{
	if(is_user_connected(id) && shModActive())
	{
		new weaponid = read_data(2)

		if(slowed[id] && weaponid != CSW_GLOCK18)
		{
			set_pev(id, pev_maxspeed, 130.0)
		}

		else if(slowed[id] && weaponid == CSW_GLOCK18 && g_HasPower[id])
		{
			set_pev(id, pev_maxspeed, 130.0)

			#if defined USE_MODEL
			 gloce_v_model(id)
			#endif
		}

		#if defined USE_MODEL
		 else if(weaponid == CSW_GLOCK18 && g_HasPower[id])
		 {
			 gloce_v_model(id)
		 }
		#endif
	}

	return 0;
}

public remove_frozen(id)
{
	if(slowed[id])
	{
		set_pev(id, pev_maxspeed, g_fMaxSpeed[id])
		fm_set_rendering(id, kRenderFxGlowShell, 0, 0, 0, kRenderNormal, 0)

		message_begin(MSG_ONE, get_user_msgid("ScreenFade"), {0,0,0}, id)
		write_short(1<<10)
		write_short(1<<10)
		write_short(0x0000)
		write_byte(30)
		write_byte(125)
		write_byte(255)
		write_byte(100)
		message_end()

		slowed[id] = false
	}
}

public fwd_Client_Connect(id)
{
	g_HasPower[id] = false
	times_id[id] = 0
}

public fwd_Client_Disconnect(id)
{
	g_HasPower[id] = false
	times_id[id] = 0
}

stock ring_effect(vector[3], radius, height, red, green, blue)
{
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY, vector)
	write_byte(21)						// TE_BEAMCYLINDER
	write_coord(vector[0])					// center position
	write_coord(vector[1])
	write_coord(vector[2] + height)
	write_coord(vector[0])					// axis and radius
	write_coord(vector[1])
	write_coord(vector[2] + radius)
	write_short(g_spriteRing)				// sprite index
	write_byte(0)						// starting frame
	write_byte(0)						// frame rate in 0.1's
	write_byte(2)						// life in 0.1's
	write_byte(20)						// line width in 0.1's
	write_byte(0)						// noise amplitude in 0.01's
	write_byte(red)						//colour
	write_byte(green)
	write_byte(blue)
	write_byte(255)						// brightness
	write_byte(0)						// scroll speed in 0.1's
	message_end()
}

stock ham_give_weapon(id,weapon[])
{
    if(!equal(weapon,"weapon_",7)) return 0;

    new wEnt = engfunc(EngFunc_CreateNamedEntity,engfunc(EngFunc_AllocString,weapon));
    if(!pev_valid(wEnt)) return 0;

    set_pev(wEnt,pev_spawnflags,SF_NORESPAWN);
    dllfunc(DLLFunc_Spawn,wEnt);
    
    if(!ExecuteHamB(Ham_AddPlayerItem,id,wEnt))
    {
        if(pev_valid(wEnt)) set_pev(wEnt,pev_flags,pev(wEnt,pev_flags) | FL_KILLME);
        return 0;
    }

    ExecuteHamB(Ham_Item_AttachToPlayer,wEnt,id)
    return 1;
}

stock fm_set_rendering(entity, fx = kRenderFxNone, r = 255, g = 255, b = 255, render = kRenderNormal, amount = 16)
{
	new Float:RenderColor[3]
	RenderColor[0] = float(r)
	RenderColor[1] = float(g)
	RenderColor[2] = float(b)

	set_pev(entity, pev_renderfx, fx)
	set_pev(entity, pev_rendercolor, RenderColor)
	set_pev(entity, pev_rendermode, render)
	set_pev(entity, pev_renderamt, float(amount))

	return 1
}