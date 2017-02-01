/*
 *
 *	Author:		Cheesy Peteza
 *	Date:		22-Apr-2004 (updated 2-March-2005)
 *
 *
 *	Description:	Enable bunny hopping in Counter-Strike.
 *
 *	Cvars:
 *			bh_enabled		1 to enable this plugin, 0 to disable.
 *			bh_autojump		If set to 1 players just need to hold down jump to bunny hop (no skill required)
 *			bh_showusage		If set to 1 it will inform joining players that bunny hopping has been enabled
 *						and how to use it if bh_autojump enabled.
 *
 *	Requirements:	AMXModX 0.16 or greater
 *
 * 
 */

#include <amxmodx>
#include <engine>

#define	FL_WATERJUMP	(1<<11)	// player jumping out of water
#define	FL_ONGROUND	(1<<9)	// At rest / on the ground

public plugin_init() {
	register_plugin("Super Bunny Hopper", "1.2", "Cheesy Peteza")
	register_cvar("sbhopper_version", "1.2", FCVAR_SERVER)

	register_cvar("bh_enabled", "1")
	register_cvar("bh_autojump", "1")
	register_cvar("bh_showusage", "1")
}

public client_PreThink(id) {
	if (!get_cvar_num("bh_enabled"))
		return PLUGIN_CONTINUE

	entity_set_float(id, EV_FL_fuser2, 0.0)		// Disable slow down after jumping

	if (!get_cvar_num("bh_autojump"))
		return PLUGIN_CONTINUE

// Code from CBasePlayer::Jump (player.cpp)		Make a player jump automatically
	if (entity_get_int(id, EV_INT_button) & 2) {	// If holding jump
		new flags = entity_get_int(id, EV_INT_flags)

		if (flags & FL_WATERJUMP)
			return PLUGIN_CONTINUE
		if ( entity_get_int(id, EV_INT_waterlevel) >= 2 )
			return PLUGIN_CONTINUE
		if ( !(flags & FL_ONGROUND) )
			return PLUGIN_CONTINUE

		new Float:velocity[3]
		entity_get_vector(id, EV_VEC_velocity, velocity)
		velocity[2] += 250.0
		entity_set_vector(id, EV_VEC_velocity, velocity)

		entity_set_int(id, EV_INT_gaitsequence, 6)	// Play the Jump Animation
	}
	return PLUGIN_CONTINUE
}

public client_putinserver(id)
{
	if (!is_user_bot(id))
    {
        set_task(180.0, "showUsage", id)
    }
}
	

public showUsage(id) {
	if ( !get_cvar_num("bh_enabled") || !get_cvar_num("bh_showusage") )
		return PLUGIN_HANDLED

	if ( !get_cvar_num("bh_autojump") ) {
		client_print(id, print_chat, "[AMX] Bunny hopping is enabled on this server. You will not slow down after jumping.")
	} else {
		client_print(id, print_chat, "[AMX] Auto bunny hopping is enabled on this server. Just hold down jump to bunny hop.")
	}
	return PLUGIN_HANDLED
}
