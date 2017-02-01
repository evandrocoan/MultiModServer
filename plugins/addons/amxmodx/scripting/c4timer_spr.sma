/*	Copyright � 2009, ConnorMcLeod

	C4 Sprites Timer is free software;
	you can redistribute it and/or modify it under the terms of the
	GNU General Public License as published by the Free Software Foundation.

	This program is distributed in the hope that it will be useful,
	but WITHOUT ANY WARRANTY; without even the implied warranty of
	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
	GNU General Public License for more details.

	You should have received a copy of the GNU General Public License
	along with C4 Sprites Timer; if not, write to the
	Free Software Foundation, Inc., 59 Temple Place - Suite 330,
	Boston, MA 02111-1307, USA.
*/

#include <amxmodx>
#include <engine>
#include <fakemeta>
#include <hamsandwich>

#define PLUGIN "C4 Sprites Timer"
#define AUTHOR "ConnorMcLeod"
#define VERSION "0.1.0"

#define SPRITE_DIST 36  // min = ~32
new const SPRITE_NAME[] = "sprites/c4_sprites/clock_digits.spr"

const OFFSET_C4_EXPLODE_TIME	= 100

new g_iC4
new g_iSprite
new g_iSprite2
new HamHook:g_HhGrenadeThink

new g_iUnits = -1
new g_iDozen = -1

new Float:g_flExplodeTime

new g_pCvarSpriteScale, g_pCvarEnable

public plugin_precache()
{
	precache_model(SPRITE_NAME)
}

public plugin_init()
{	
	register_plugin(PLUGIN, VERSION, AUTHOR)

	g_pCvarEnable = register_cvar("c4_sprite_timer", "1")
	g_pCvarSpriteScale = register_cvar("c4_sprite_scale", "0.6")

	if( find_ent_by_class(FM_NULLENT, "func_bomb_target") || find_ent_by_class(FM_NULLENT, "info_bomb_target") )
	{
		g_HhGrenadeThink = RegisterHam(Ham_Think, "grenade", "C4_Think", 1)

		register_event("HLTV", "StopHook", "a", "1=0", "2=0")
		register_logevent("StopHook", 2, "1=Round_End")

		register_logevent("StartHook", 3, "2=Planted_The_Bomb")

		StopHook()
	}
}

public StopHook()
{
	g_iC4 = 0
	g_iUnits = -1
	g_iDozen = -1
	DisableHamForward( g_HhGrenadeThink )
	if( g_iSprite )
	{
		entity_set_int(g_iSprite, EV_INT_flags, FL_KILLME)
		g_iSprite = 0
	}

	if( g_iSprite2 )
	{
		entity_set_int(g_iSprite2, EV_INT_flags, FL_KILLME)
		g_iSprite2 = 0
	}
}

public StartHook()
{
	if( !get_pcvar_num(g_pCvarEnable) )
	{
		return
	}

	new iC4 = FM_NULLENT
	new const grenade[] = "grenade"
	new const env_sprite[] = "env_sprite"
	while( (iC4 = find_ent_by_class(iC4, grenade)) )
	{
		if( get_pdata_int(iC4, 96, 5) & (1<<8) )
		{
			g_iC4 = iC4
			g_flExplodeTime = get_pdata_float(g_iC4, OFFSET_C4_EXPLODE_TIME, 5)
			EnableHamForward( g_HhGrenadeThink )

			new Float:flOrigin[3], Float:flGround[3]

			entity_get_vector(iC4, EV_VEC_origin, flOrigin)

			flGround[0] = flOrigin[0]
			flGround[1] = flOrigin[1]
			flGround[2] = flOrigin[2] - 9999.9

			trace_line(FM_NULLENT, flOrigin, flGround, flGround) 

			new Float:flScale = get_pcvar_float(g_pCvarSpriteScale)

			if( ( g_iSprite = create_entity(env_sprite) ) )
			{
				entity_set_string(g_iSprite, EV_SZ_model, SPRITE_NAME)
				flGround[2] += max( floatround( SPRITE_DIST * flScale ) , 20 )
				entity_set_vector(g_iSprite, EV_VEC_origin, flGround)
				entity_set_float(g_iSprite, EV_FL_scale, flScale)
				DispatchSpawn(g_iSprite)
			}

			if( ( g_iSprite2 = create_entity(env_sprite) ) )
			{
				entity_set_string(g_iSprite2, EV_SZ_model, SPRITE_NAME)
				flGround[2] += floatround( SPRITE_DIST * flScale )
				entity_set_vector(g_iSprite2, EV_VEC_origin, flGround)
				entity_set_float(g_iSprite2, EV_FL_scale, flScale)
				DispatchSpawn(g_iSprite2)
			}
			return
		}
	}
}

public C4_Think( iC4 )
{
	if( g_iC4 != iC4 )
	{
		return
	}

	static Float:flTime, iTime, iUnits, iDozen

	flTime = g_flExplodeTime - get_gametime()
	iTime = floatround(flTime, floatround_ceil)
	iUnits = iTime % 10
	iDozen = (iTime - iUnits) / 10

	if( g_iSprite && g_iUnits != iUnits )
	{
		g_iUnits = iUnits
		entity_set_float(g_iSprite, EV_FL_frame, 0.0 + iUnits)
	}

	if( g_iSprite2 && g_iDozen != iDozen)
	{
		g_iDozen = iDozen
		if( !iDozen )
		{
			entity_set_int(g_iSprite2, EV_INT_flags, FL_KILLME)
			g_iSprite2 = 0
		}
		else
		{
			entity_set_float(g_iSprite2, EV_FL_frame, 0.0 + iDozen)
		}
	}
}