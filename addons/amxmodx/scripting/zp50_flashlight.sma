/*================================================================================
	
	-----------------------
	-*- [ZP] Flashlight -*-
	-----------------------
	
	This plugin is part of Zombie Plague Mod and is distributed under the
	terms of the GNU General Public License. Check ZP_ReadMe.txt for details.
	
================================================================================*/

#include <amxmodx>
#include <fakemeta>
#include <hamsandwich>
#include <xs>
#include <cs_ham_bots_api>
#include <zp50_core>

#define TASK_FLASHLIGHT 100
#define TASK_CHARGE 200
#define ID_FLASHLIGHT (taskid - TASK_FLASHLIGHT)
#define ID_CHARGE (taskid - TASK_CHARGE)

// CS Player PData Offsets (win32)
const PDATA_SAFE = 2
const OFFSET_FLASHLIGHT_BATTERIES = 244

const IMPULSE_FLASHLIGHT = 100

new const g_sound_flashlight[] = "items/flashlight1.wav"

#define MAXPLAYERS 32

#define flag_get(%1,%2) (%1 & (1 << (%2 & 31)))
#define flag_get_boolean(%1,%2) (flag_get(%1,%2) ? true : false)
#define flag_set(%1,%2) %1 |= (1 << (%2 & 31))
#define flag_unset(%1,%2) %1 &= ~(1 << (%2 & 31))

new g_MsgFlashlight, g_MsgFlashBat

new g_FlashlightActive
new g_FlashlightCharge[MAXPLAYERS+1]
new Float:g_FlashlightLastTime[MAXPLAYERS+1]

new cvar_flashlight_starting_charge
new cvar_flashlight_custom, cvar_flashlight_radius
new cvar_flashlight_distance, cvar_flashlight_show_all
new cvar_flashlight_drain_rate, cvar_flashlight_charge_rate
new cvar_flashlight_color_R, cvar_flashlight_color_G, cvar_flashlight_color_B

public plugin_init()
{
	register_plugin("[ZP] Flashlight", ZP_VERSION_STRING, "ZP Dev Team")
	
	register_forward(FM_CmdStart, "fw_CmdStart")
	RegisterHam(Ham_Killed, "player", "fw_PlayerKilled")
	RegisterHamBots(Ham_Killed, "fw_PlayerKilled")
	
	g_MsgFlashlight = get_user_msgid("Flashlight")
	g_MsgFlashBat = get_user_msgid("FlashBat")
	register_message(g_MsgFlashBat, "message_flashbat")
	
	cvar_flashlight_starting_charge = register_cvar("zp_flashlight_starting_charge", "100")
	cvar_flashlight_custom = register_cvar("zp_flashlight_custom", "0")
	cvar_flashlight_radius = register_cvar("zp_flashlight_radius", "10")
	cvar_flashlight_distance = register_cvar("zp_flashlight_distance", "1000")
	cvar_flashlight_show_all = register_cvar("zp_flashlight_show_all", "1")
	cvar_flashlight_drain_rate = register_cvar("zp_flashlight_drain_rate", "1")
	cvar_flashlight_charge_rate = register_cvar("zp_flashlight_charge_rate", "5")
	cvar_flashlight_color_R = register_cvar("zp_flashlight_color_R", "100")
	cvar_flashlight_color_G = register_cvar("zp_flashlight_color_G", "100")
	cvar_flashlight_color_B = register_cvar("zp_flashlight_color_B", "100")
}


public plugin_natives()
{
	register_library("zp50_flashlight")
	register_native("zp_flashlight_get_charge", "native_flashlight_get_charge")
	register_native("zp_flashlight_set_charge", "native_flashlight_set_charge")
}

public native_flashlight_get_charge(plugin_id, num_params)
{
	new id = get_param(1)
	
	if (!is_user_connected(id))
	{
		log_error(AMX_ERR_NATIVE, "[ZP] Invalid Player (%d)", id)
		return -1;
	}
	
	// Custom flashlight not enabled
	if (!get_pcvar_num(cvar_flashlight_custom))
		return -1;
	
	return g_FlashlightCharge[id];
}

public native_flashlight_set_charge(plugin_id, num_params)
{
	new id = get_param(1)
	new charge = get_param(2)
	
	if (!is_user_connected(id))
	{
		log_error(AMX_ERR_NATIVE, "[ZP] Invalid Player (%d)", id)
		return false;
	}
	
	// Custom flashlight not enabled
	if (!get_pcvar_num(cvar_flashlight_custom))
		return false;
	
	g_FlashlightCharge[id] = clamp(charge, 0, 100)
	
	// Set the flashlight charge task to update batteries
	remove_task(id+TASK_CHARGE)
	set_task(1.0, "flashlight_charge_task", id+TASK_CHARGE, _, _, "b")
	
	return true;
}

public plugin_precache()
{
	precache_sound(g_sound_flashlight)
}

public plugin_cfg()
{
	// Enables flashlight
	server_cmd("mp_flashlight 1")
}

// Forward CmdStart
public fw_CmdStart(id, handle)
{
	// Not alive
	if (!is_user_alive(id))
		return;
	
	// Check if it's a flashlight impulse
	if (get_uc(handle, UC_Impulse) != IMPULSE_FLASHLIGHT)
		return;
	
	// Flashlight is being turned off
	if (pev(id, pev_effects) & EF_DIMLIGHT)
		return;
	
	if (zp_core_is_zombie(id))
	{
		// Block it!
		set_uc(handle, UC_Impulse, 0)
	}
	else if (get_pcvar_num(cvar_flashlight_custom))
	{
		// Block it!
		set_uc(handle, UC_Impulse, 0)
		
		// Should human's custom flashlight be turned on?
		if (g_FlashlightCharge[id] > 2 && get_gametime() - g_FlashlightLastTime[id] > 1.2)
		{
			// Prevent calling flashlight too quickly (bugfix)
			g_FlashlightLastTime[id] = get_gametime()
			
			// Toggle custom flashlight
			if (flag_get(g_FlashlightActive, id))
			{
				// Remove flashlight task
				remove_task(id+TASK_FLASHLIGHT)
				
				flag_unset(g_FlashlightActive, id)
			}
			else
			{
				// Set the custom flashlight task
				set_task(0.1, "custom_flashlight_task", id+TASK_FLASHLIGHT, _, _, "b")
				
				flag_set(g_FlashlightActive, id)
			}
			
			// Set the flashlight charge task
			remove_task(id+TASK_CHARGE)
			set_task(1.0, "flashlight_charge_task", id+TASK_CHARGE, _, _, "b")
			
			// Play flashlight toggle sound
			emit_sound(id, CHAN_ITEM, g_sound_flashlight, 1.0, ATTN_NORM, 0, PITCH_NORM)
			
			// Update flashlight status on HUD
			message_begin(MSG_ONE, g_MsgFlashlight, _, id)
			write_byte(flag_get_boolean(g_FlashlightActive, id)) // toggle
			write_byte(g_FlashlightCharge[id]) // batteries
			message_end()
		}
	}
}

// Ham Player Killed Forward
public fw_PlayerKilled(victim, attacker, shouldgib)
{
	// Reset flashlight flags
	flag_unset(g_FlashlightActive, victim)
	remove_task(victim+TASK_FLASHLIGHT)
	remove_task(victim+TASK_CHARGE)
}

public client_disconnect(id)
{
	// Reset flashlight flags
	flag_unset(g_FlashlightActive, id)
	remove_task(id+TASK_FLASHLIGHT)
	remove_task(id+TASK_CHARGE)
}

// Flashlight batteries messages
public message_flashbat(msg_id, msg_dest, msg_entity)
{
	// Block if custom flashlight is enabled instead
	if (get_pcvar_num(cvar_flashlight_custom))
		return PLUGIN_HANDLED;
	
	// Block if zombie
	if (is_user_connected(msg_entity) && zp_core_is_zombie(msg_entity))
		return PLUGIN_HANDLED;
	
	return PLUGIN_CONTINUE;
}

public zp_fw_core_infect_post(id, attacker)
{
	// Turn off zombies flashlight
	turn_off_flashlight(id)
}

public zp_fw_core_cure_post(id, attacker)
{
	// Turn off humans flashlight (prevents double flashlight bug/exploit after respawn)
	turn_off_flashlight(id)
}

// Turn Off Flashlight and Restore Batteries
turn_off_flashlight(id)
{
	// Restore batteries to starting charge
	if (get_pcvar_num(cvar_flashlight_custom))
		g_FlashlightCharge[id] = get_pcvar_num(cvar_flashlight_starting_charge)
	else
		fm_cs_set_flash_batteries(id, get_pcvar_num(cvar_flashlight_starting_charge))
	
	// Check if flashlight is on
	if (pev(id, pev_effects) & EF_DIMLIGHT)
	{
		// Turn it off
		set_pev(id, pev_impulse, IMPULSE_FLASHLIGHT)
	}
	else
	{
		// Clear any stored flashlight impulse (bugfix)
		set_pev(id, pev_impulse, 0)
		
		// Update flashlight HUD
		message_begin(MSG_ONE, g_MsgFlashlight, _, id)
		write_byte(0) // toggle
		write_byte(get_pcvar_num(cvar_flashlight_starting_charge)) // batteries
		message_end()
	}
	
	if (get_pcvar_num(cvar_flashlight_custom))
	{
		// Turn it off
		flag_unset(g_FlashlightActive, id)
		
		// Remove previous tasks
		remove_task(id+TASK_CHARGE)
		remove_task(id+TASK_FLASHLIGHT)
	}
}

// Custom Flashlight Task
public custom_flashlight_task(taskid)
{
	// Get player and aiming origins
	static Float:origin[3], Float:destorigin[3]
	pev(ID_FLASHLIGHT, pev_origin, origin)
	fm_get_aim_origin(ID_FLASHLIGHT, destorigin)
	
	// Max distance check
	if (get_distance_f(origin, destorigin) > get_pcvar_float(cvar_flashlight_distance))
		return;
	
	// Send to all players?
	if (get_pcvar_num(cvar_flashlight_show_all))
		engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, destorigin, 0)
	else
		message_begin(MSG_ONE_UNRELIABLE, SVC_TEMPENTITY, _, ID_FLASHLIGHT)
	
	// Flashlight
	write_byte(TE_DLIGHT) // TE id
	engfunc(EngFunc_WriteCoord, destorigin[0]) // x
	engfunc(EngFunc_WriteCoord, destorigin[1]) // y
	engfunc(EngFunc_WriteCoord, destorigin[2]) // z
	write_byte(get_pcvar_num(cvar_flashlight_radius)) // radius
	write_byte(get_pcvar_num(cvar_flashlight_color_R)) // r
	write_byte(get_pcvar_num(cvar_flashlight_color_G)) // g
	write_byte(get_pcvar_num(cvar_flashlight_color_B)) // b
	write_byte(3) // life
	write_byte(0) // decay rate
	message_end()
}

// Flashlight Charge Task
public flashlight_charge_task(taskid)
{
	// Drain or charge?
	if (flag_get(g_FlashlightActive, ID_CHARGE))
		g_FlashlightCharge[ID_CHARGE] = max(g_FlashlightCharge[ID_CHARGE] - get_pcvar_num(cvar_flashlight_drain_rate), 0)
	else
		g_FlashlightCharge[ID_CHARGE] = min(g_FlashlightCharge[ID_CHARGE] + get_pcvar_num(cvar_flashlight_charge_rate), 100)
	
	// Batteries fully charged
	if (g_FlashlightCharge[ID_CHARGE] == 100)
	{
		// Update flashlight batteries on HUD
		message_begin(MSG_ONE, g_MsgFlashBat, _, ID_CHARGE)
		write_byte(100) // batteries
		message_end()
		
		// Task not needed anymore
		remove_task(taskid)
		return;
	}
	
	// Batteries depleted
	if (g_FlashlightCharge[ID_CHARGE] == 0)
	{
		// Turn it off
		flag_unset(g_FlashlightActive, ID_CHARGE)
		
		// Remove flashlight task for this player
		remove_task(ID_CHARGE+TASK_FLASHLIGHT)
		
		// Play flashlight toggle sound
		emit_sound(ID_CHARGE, CHAN_ITEM, g_sound_flashlight, 1.0, ATTN_NORM, 0, PITCH_NORM)
		
		// Update flashlight status on HUD
		message_begin(MSG_ONE, g_MsgFlashlight, _, ID_CHARGE)
		write_byte(0) // toggle
		write_byte(0) // batteries
		message_end()
		
		return;
	}
	
	// Update flashlight batteries on HUD
	message_begin(MSG_ONE_UNRELIABLE, g_MsgFlashBat, _, ID_CHARGE)
	write_byte(g_FlashlightCharge[ID_CHARGE]) // batteries
	message_end()
}

// Set Flashlight Batteries
stock fm_cs_set_flash_batteries(id, value)
{
	// Prevent server crash if entity's private data not initalized
	if (pev_valid(id) != PDATA_SAFE)
		return;
	
	set_pdata_int(id, OFFSET_FLASHLIGHT_BATTERIES, value)
}

// Get entity's aim origins (from fakemeta_util)
stock fm_get_aim_origin(id, Float:origin[3])
{
	static Float:origin1F[3], Float:origin2F[3]
	pev(id, pev_origin, origin1F)
	pev(id, pev_view_ofs, origin2F)
	xs_vec_add(origin1F, origin2F, origin1F)

	pev(id, pev_v_angle, origin2F);
	engfunc(EngFunc_MakeVectors, origin2F)
	global_get(glb_v_forward, origin2F)
	xs_vec_mul_scalar(origin2F, 9999.0, origin2F)
	xs_vec_add(origin1F, origin2F, origin2F)

	engfunc(EngFunc_TraceLine, origin1F, origin2F, 0, id, 0)
	get_tr2(0, TR_vecEndPos, origin)
}