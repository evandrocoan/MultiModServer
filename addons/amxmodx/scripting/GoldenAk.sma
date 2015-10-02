/* AMX Mod script
* 
* (c) 2009, AlejandroSk
* This file is provided as is (no warranties).
*
*/



#include <amxmodx>
#include <fakemeta>
#include <fun>
#include <hamsandwich>
#include <cstrike>
#include <amxmisc>


#define is_valid_player(%1) (1 <= %1 <= 32)

new AK_V_MODEL[64] = "models/v_golden_ak47.mdl"
new AK_P_MODEL[64] = "models/p_golden_ak47.mdl"

/* Pcvars */
new cvar_dmgmultiplier, cvar_goldbullets,  cvar_custommodel, cvar_uclip, cvar_cost

new bool:g_HasAk[33]

new g_hasZoom[ 33 ]
new bullets[ 33 ]

// Sprite
new m_spriteTexture

const Wep_ak47 = ((1<<CSW_AK47))

public plugin_init()
{
	
	/* CVARS */
	cvar_dmgmultiplier = register_cvar("goldenak_dmg_multiplier", "5")
	cvar_custommodel = register_cvar("goldenak_custom_model", "1")
	cvar_goldbullets = register_cvar("goldenak_gold_bullets", "1")
	cvar_uclip = register_cvar("goldenak_unlimited_clip", "1")
	cvar_cost = register_cvar("goldenak_cost", "6000")
	
	// Register The Buy Cmd
	register_clcmd("say /goldenak", "CmdBuyAk")
	register_clcmd("say_team /goldenak", "CmdBuyAk")
	register_clcmd("say /silvermenu", "CmdBuyAk");
	register_clcmd("say /akdemonio", "CmdBuyAk");
	register_clcmd("say /coltdemonio", "CmdBuyAk");
	register_clcmd("say akdemonio", "CmdBuyAk");
	register_clcmd("say coltdemonio", "CmdBuyAk");

	register_concmd("amx_goldenak", "CmdGiveAk", ADMIN_BAN, "<name>")
	
	// Register The Plugin
	register_plugin("Golden Ak 47", "1.0", "AlejandroSk")
	// Death Msg
	register_event("DeathMsg", "Death", "a")
	// Weapon Pick Up
	register_event("WeapPickup","checkModel","b","1=19")
	// Current Weapon Event
	register_event("CurWeapon","checkWeapon","be","1=1")
	register_event("CurWeapon", "make_tracer", "be", "1=1", "3>0")
	// Ham TakeDamage
	RegisterHam(Ham_TakeDamage, "player", "fw_TakeDamage")
	register_forward( FM_CmdStart, "fw_CmdStart" )
	RegisterHam(Ham_Spawn, "player", "fwHamPlayerSpawnPost", 1)
	
}

public client_connect(id)
{
	g_HasAk[id] = false
}

public client_disconnect(id)
{
	g_HasAk[id] = false
}

public Death()
{
	g_HasAk[read_data(2)] = false
}

public fwHamPlayerSpawnPost(id)
{
	g_HasAk[id] = false
}

public plugin_precache()
{
	precache_model(AK_V_MODEL)
	precache_model(AK_P_MODEL)
	m_spriteTexture = precache_model("sprites/dot.spr")
	precache_sound("weapons/zoom.wav")
}

public checkModel(id)
{
	if ( !g_HasAk[id] )
		return PLUGIN_HANDLED
	
	new szWeapID = read_data(2)
	
	if ( szWeapID == CSW_AK47 && g_HasAk[id] == true && get_pcvar_num(cvar_custommodel) )
	{
		set_pev(id, pev_viewmodel2, AK_V_MODEL)
		set_pev(id, pev_weaponmodel2, AK_P_MODEL)
	}
	return PLUGIN_HANDLED
}

public checkWeapon(id)
{
	new plrClip, plrAmmo, plrWeap[32]
	new plrWeapId
	
	plrWeapId = get_user_weapon(id, plrClip , plrAmmo)
	
	if (plrWeapId == CSW_AK47 && g_HasAk[id])
	{
		checkModel(id)
	}
	else 
	{
		return PLUGIN_CONTINUE
	}
	
	if (plrClip == 0 && get_pcvar_num(cvar_uclip))
	{
		// If the user is out of ammo..
		get_weaponname(plrWeapId, plrWeap, 31)
		// Get the name of their weapon
		give_item(id, plrWeap)
		engclient_cmd(id, plrWeap) 
		engclient_cmd(id, plrWeap)
		engclient_cmd(id, plrWeap)
	}
	return PLUGIN_HANDLED
}



public fw_TakeDamage(victim, inflictor, attacker, Float:damage)
{
	if ( is_valid_player( attacker ) && get_user_weapon(attacker) == CSW_AK47 && g_HasAk[attacker] )
	{
		SetHamParamFloat(4, damage * get_pcvar_float( cvar_dmgmultiplier ) )
	}
}

public fw_CmdStart( id, uc_handle, seed )
{
	if( !is_user_alive( id ) ) 
		return PLUGIN_HANDLED
	
	if( ( get_uc( uc_handle, UC_Buttons ) & IN_ATTACK2 ) && !( pev( id, pev_oldbuttons ) & IN_ATTACK2 ) )
	{
		new szClip, szAmmo
		new szWeapID = get_user_weapon( id, szClip, szAmmo )
		
		if( szWeapID == CSW_AK47 && g_HasAk[id] == true && !g_hasZoom[id] == true)
		{
			g_hasZoom[id] = true
			cs_set_user_zoom( id, CS_SET_AUGSG552_ZOOM, 0 )
			emit_sound( id, CHAN_ITEM, "weapons/zoom.wav", 0.20, 2.40, 0, 100 )
		}
		
		else if ( szWeapID == CSW_AK47 && g_HasAk[id] == true && g_hasZoom[id])
		{
			g_hasZoom[ id ] = false
			cs_set_user_zoom( id, CS_RESET_ZOOM, 0 )
			
		}
		
	}
	return PLUGIN_HANDLED
}


public make_tracer(id)
{
	if (get_pcvar_num(cvar_goldbullets))
	{
		new clip,ammo
		new wpnid = get_user_weapon(id,clip,ammo)
		new pteam[16]
		
		get_user_team(id, pteam, 15)
		
		if ((bullets[id] > clip) && (wpnid == CSW_AK47) && g_HasAk[id]) 
		{
			new vec1[3], vec2[3]
			get_user_origin(id, vec1, 1) // origin; your camera point.
			get_user_origin(id, vec2, 4) // termina; where your bullet goes (4 is cs-only)
			
			
			//BEAMENTPOINTS
			message_begin( MSG_BROADCAST,SVC_TEMPENTITY)
			write_byte (0)     //TE_BEAMENTPOINTS 0
			write_coord(vec1[0])
			write_coord(vec1[1])
			write_coord(vec1[2])
			write_coord(vec2[0])
			write_coord(vec2[1])
			write_coord(vec2[2])
			write_short( m_spriteTexture )
			write_byte(1) // framestart
			write_byte(5) // framerate
			write_byte(2) // life
			write_byte(10) // width
			write_byte(0) // noise
			write_byte( 255 )     // r, g, b
			write_byte( 215 )       // r, g, b
			write_byte( 0 )       // r, g, b
			write_byte(200) // brightness
			write_byte(150) // speed
			message_end()
		}
		
		bullets[id] = clip
	}
	
}

public CmdBuyAk(id)
{
	if ( !is_user_alive(id) )
	{
		client_print(id,print_chat, "[AMXX] To buy golden Ak 47 You need to be alive!")
		return PLUGIN_HANDLED
	}
	
	new money = cs_get_user_money(id)
	
	if (money >= get_pcvar_num(cvar_cost))
	{
		cs_set_user_money(id, money - get_pcvar_num(cvar_cost))
		give_item(id, "weapon_ak47")
		g_HasAk[id] = true
	}
	
	else
	{
		client_print(id, print_chat, "[AMXX] You dont hav enough money to buy Golden Ak 47. Cost $%d ", get_pcvar_num(cvar_cost))
	}
	return PLUGIN_HANDLED
}

public CmdGiveAk(id,level,cid)
{
	if (!cmd_access(id,level,cid,2))
		return PLUGIN_HANDLED;
	new arg[32];
	read_argv(1,arg,31);
	
	new player = cmd_target(id,arg,7);
	if (!player) 
		return PLUGIN_HANDLED;
	
	new name[32];
	get_user_name(player,name,31);
	
	give_item(player, "weapon_ak47")
	g_HasAk[player] = true
	
	return PLUGIN_HANDLED
}

stock drop_prim(id) 
{
	new weapons[32], num
	get_user_weapons(id, weapons, num)
	for (new i = 0; i < num; i++) {
		if (Wep_ak47 & (1<<weapons[i])) 
		{
			static wname[32]
			get_weaponname(weapons[i], wname, sizeof wname - 1)
			engclient_cmd(id, "drop", wname)
		}
	}
}
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1034\\ f0\\ fs16 \n\\ par }
*/
