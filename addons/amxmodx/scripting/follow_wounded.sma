/*************************************************************************************************************
                              AMX Follow the Wounded

  Version: 0.1
  Author: KRoT@L

  0.1    Release


	When the health of a player goes below ftw_health, the footsteps of this player will be
	covered with blood. Thus you can follow him.


  Cvars:

	ftw_active "1"	-	0: Disables the plugin
                    1: Enables the plugin

	ftw_health "20"			-	the footsteps are covered with blood only if health goes below this value


  Setup (AMX 0.9.9):
  
	Install the amx file.
	Enable VexdUM (both in metamod/plugins.ini and amx/config/modules.ini)

*************************************************************************************************************/

#include <amxmodx>
#include <amxmisc>
#include <engine>

//If one line doesn't work, comment it and uncomment the other line
//new decals[2] = {105,106}
new decals[2] = {107,108}


new bool:g_isDying[33]
new g_decalSwitch[33]

public plugin_init()
{
	register_plugin("Follow the Wounded", "0.1", "KRoTaL")

	register_cvar("ftw_active", "1")
	register_cvar("ftw_health", "20")

	register_event("ResetHUD","resethud_event","be")
	register_event("Damage","damage_event","b")
	register_event("DeathMsg","death_event","a")
}

public client_connect(id)
{
	g_isDying[id] = false
	remove_task(4247545+id)
}

public resethud_event(id)
{
	if(g_isDying[id])
	{
		g_isDying[id] = false
		remove_task(4247545+id)
	}
}

public damage_event(id)
{
	if(get_cvar_num("ftw_active") == 0) return PLUGIN_CONTINUE

	if(!g_isDying[id] && is_user_alive(id) && get_user_health(id) <= get_cvar_num("ftw_health"))
	{
		g_isDying[id] = true
		g_decalSwitch[id] = 0
		new param[1]
		param[0] = id
		set_task(0.2, "make_footsteps", 4247545+id, param, 1, "b")
	}
	return PLUGIN_CONTINUE
}

public death_event()
{
	new id = read_data(2)
	if(g_isDying[id])
	{
		g_isDying[id] = false
		remove_task(4247545+id)
	}
}

public make_footsteps(param[])
{
	new id = param[0]
	if(!is_user_alive(id) || get_cvar_num("ftw_active") == 0 || get_speed(id) < 120) return
	new origin[3]
	get_user_origin(id, origin)
	if(entity_get_int(id, EV_INT_bInDuck) == 1)
		origin[2] -= 18
	else
		origin[2] -= 36
	new Float:velocity[3]
	new Float:ent_angles[3]
	new Float:ent_origin[3]
	new ent

	entity_get_vector(id, EV_VEC_v_angle, ent_angles)
	entity_get_vector(id, EV_VEC_origin, ent_origin)

	ent = create_entity("info_target")
	if(ent > 0)
	{
		ent_angles[0] = 0.0
		if(g_decalSwitch[id] == 0) ent_angles[1] -= 90
		else ent_angles[1] += 90
		entity_set_vector(ent, EV_VEC_origin, ent_origin)
		entity_set_vector(ent, EV_VEC_v_angle, ent_angles)
		VelocityByAim(ent, 12, velocity)
		remove_entity(ent)
	}
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY, origin)
	write_byte(116)
	write_coord(origin[0] + floatround(velocity[0]))
	write_coord(origin[1] + floatround(velocity[1]))
	write_coord(origin[2])
	write_byte(decals[g_decalSwitch[id]])
	message_end()
	g_decalSwitch[id] = 1 - g_decalSwitch[id]
	return
}
