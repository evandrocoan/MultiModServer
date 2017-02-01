//Leviathan - made by Mydas
//creds to Cheap_Suit for the WaterWorld plugin

/*
leviathan_level 5           - level at which he becomes available
leviathan_gravity 200       - server gravity when the level is Flooded
leviathan_othersspeed 225   - swimspeed of others
leviathan_swimspeed 380     - his swimspeed
leviathan_threshold 0.3     - percentage of life he must go below to flood level
leviathan_underwaterdmg 1.5 - how much dmg does Leviathan do when in flood ?
*/


#include <amxmod>
#include <superheromod>


new bubbleSprite
new lastwpn[SH_MAXSLOTS + 1]
new lastammo[SH_MAXSLOTS + 1]
new check[SH_MAXSLOTS + 1]
new bool:Swim[SH_MAXSLOTS + 1]
new gPlayerMaxHealth[SH_MAXSLOTS+1]
new GrenOldOrigin[3]
new bool:FloodOn=false
new svgravity, leviathan_gravity, leviathan_swimspeed, leviathan_othersspeed, Float:leviathan_underwaterdmg, Float:leviathan_threshold

new gHeroName[] = "Leviathan" 
new bool:gHasLeviathanPowers[SH_MAXSLOTS + 1]

public plugin_init()
{
	register_plugin("SUPERHERO Leviathan", "1.0", "Mydas")
	register_cvar("leviathan_level", "5")

	shCreateHero(gHeroName, "Flood", "Flood the map when you are on low health; then, swim fast and shoot hard; tap forward to swim", false, "leviathan_level") 
	register_srvcmd("leviathan_init", "leviathan_init") 
	register_event("CurWeapon", "BulletEffect", "be", "3>0") 

	register_cvar("leviathan_gravity", "200")
	register_cvar("leviathan_othersspeed", "225")
	register_cvar("leviathan_swimspeed", "380")
	register_cvar("leviathan_threshold", "0.3")
	register_cvar("leviathan_underwaterdmg", "1.5")
	svgravity=get_cvar_num("sv_gravity")

	shRegHeroInit(gHeroName, "leviathan_init") 
	register_srvcmd("leviathan_maxhealth", "leviathan_maxhealth")
	shRegMaxHealth(gHeroName, "leviathan_maxhealth" )
	register_event("ResetHUD", "newRound", "b")
	register_event("Damage", "leviathan_damage", "b", "2!0") 
}

public plugin_precache()
{
	bubbleSprite = precache_model("sprites/bubble.spr")
}

public client_connect(id)
{
	check[id] = 0
	Swim[id] = false
}

public leviathan_init() 
{ 
	new temp[128] 
	// First Argument is an id 
	read_argv(1, temp, 5) 
	new id = strtonum(temp) 

	read_argv(2, temp, 5) 
	new hasPowers = strtonum(temp) 
	check[id] = 0
	Swim[id] = false
	gHasLeviathanPowers[id] = (hasPowers!=0)	
	gPlayerMaxHealth[id] = 100

	leviathan_gravity = get_cvar_num("leviathan_gravity")
	leviathan_swimspeed = get_cvar_num("leviathan_swimspeed")
	leviathan_othersspeed = get_cvar_num("leviathan_othersspeed")
	leviathan_underwaterdmg = get_cvar_float("leviathan_underwaterdmg")
	leviathan_threshold = get_cvar_float("leviathan_threshold")

	if (!gHasLeviathanPowers[id] && FloodOn) remove_flood()
} 

public newRound(id)
{ 
	if (/*gHasLeviathanPowers[id] && */FloodOn) { 
		//client_print(id, print_center, "FLOOD REMOVED %i", svgravity) 
		remove_flood() 
	}
	return PLUGIN_CONTINUE 
} 

public client_PreThink(id)
{
	if(!is_user_connected(id) || !is_user_alive(id))
		return PLUGIN_CONTINUE
		
	if(!FloodOn && (get_user_health(id)%512)<=floatround(gPlayerMaxHealth[id]*leviathan_threshold) && gHasLeviathanPowers[id]) {
		new pstr[2]
		pstr[0] = id
		set_task(0.2, "make_flood", 0, pstr, 1)
	}
	
	if(!FloodOn)
		return PLUGIN_CONTINUE
			
	new button = get_user_button(id)
	if (button & IN_FORWARD && !check[id]) {
		check[id]++
		new pstr[2]
		pstr[0] = id
		set_task(0.35, "can_switch", 0, pstr, 1)
	}
	
	if (!(button & IN_FORWARD) && check[id]==1) check[id]++
	
	if (button & IN_FORWARD && check[id]==2) {
		Swim[id] = true
		check[id]++
	}
	
	if (!(button & IN_FORWARD) && check[id]==3) {
		check[id] = 0
		Swim[id] = false
	}
	
	//client_print(id,print_center,"%i",check[id])
	return PLUGIN_CONTINUE
}

public client_PostThink(id)
{
	if(!FloodOn)
		return PLUGIN_CONTINUE
	if(!is_user_connected(id) || !is_user_alive(id))
		return PLUGIN_CONTINUE

	entity_set_int(id, EV_INT_waterlevel, 3)
	entity_set_float(id, EV_FL_air_finished, entity_get_float(id, EV_FL_air_finished ) + 2.0) 
	if(Swim[id] == true)
	{
		new Float:Velocity[3]
		if (gHasLeviathanPowers[id]) VelocityByAim(id, leviathan_swimspeed, Velocity)
		else VelocityByAim(id, leviathan_othersspeed, Velocity)
		entity_set_vector(id, EV_VEC_velocity, Velocity) 

		/*if(!(get_user_button(id) & IN_FORWARD)) {
		Swim[id]=false
		canswim[id]=false
	}*/
		return PLUGIN_CONTINUE
	}
	return PLUGIN_CONTINUE
}

public can_switch(pstr[])
{
	new id = pstr[0]
	if (check[id]!=3) check[id] = 0
}

public grenade_throw(index, greindex, wId)
{	
	if(!FloodOn)
		return PLUGIN_CONTINUE
	new iPlayerOrigin[3]
	get_user_origin(index, iPlayerOrigin, 1)
	make_bubbles(greindex, iPlayerOrigin)
		
	return PLUGIN_CONTINUE
}

public make_bubbles(entity, iOldOrigin[3])
{
	if(!is_valid_ent(entity))
		return PLUGIN_CONTINUE
		
	new iGrenadeOrigin[3], Float:fGrenadeOrigin[3]
	entity_get_vector(entity, EV_VEC_origin, fGrenadeOrigin)

	FVecIVec(fGrenadeOrigin, iGrenadeOrigin)
	Bubbles(iOldOrigin, iGrenadeOrigin)
	
	new param[1]
	param[0] = entity
	GrenOldOrigin = iGrenadeOrigin
	set_task(0.1, "loop_bubbles", 0, param, 1)
	
	return PLUGIN_CONTINUE
}

public loop_bubbles(param[])
{
	new entity = param[0]
	if(!is_valid_ent(entity))
		return PLUGIN_CONTINUE
	
	new iGrenadeOrigin[3], Float:fGrenadeOrigin[3]
	entity_get_vector(entity, EV_VEC_origin, fGrenadeOrigin)
	FVecIVec(fGrenadeOrigin, iGrenadeOrigin)
	Bubbles(GrenOldOrigin, iGrenadeOrigin)

	GrenOldOrigin = iGrenadeOrigin
	set_task(0.1, "loop_bubbles", 0, param, 1)
	return PLUGIN_CONTINUE
}

public BulletEffect(id)
{		
	if(!FloodOn)
		return PLUGIN_CONTINUE
	new wpn = read_data(2)
	new ammo = read_data(3)
	
	if(lastwpn[id] == wpn && lastammo[id] > ammo) 
	{ 
		new PlayerOrigin[3], BulletOrigin[3]
		get_user_origin(id, PlayerOrigin, 1) 
		get_user_origin(id, BulletOrigin, 4)
		Bubbles(PlayerOrigin, BulletOrigin)
	}
	lastwpn[id] = wpn
	lastammo[id] = ammo
	
	return PLUGIN_CONTINUE
}

stock Bubbles(StartOrigin[3], EndOrigin[3])
{
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY, EndOrigin) 
	write_byte(114)
	write_coord(StartOrigin[0])
	write_coord(StartOrigin[1])
	write_coord(StartOrigin[2])
	write_coord(EndOrigin[0]) 
	write_coord(EndOrigin[1]) 
	write_coord(EndOrigin[2]) 
	write_coord(40) 
	write_short(bubbleSprite) 
	write_byte(10) 
	write_coord(40)
	message_end()
}

public make_flood(pstr[])
{
	if (FloodOn) return
	new id = pstr[0]
	if ((get_user_health(id)%512)<=floatround(gPlayerMaxHealth[id]*leviathan_threshold)) {
		FloodOn=true
		client_print(id, print_center, "[Leviathan] - Level Flooded")
		svgravity=get_cvar_num("sv_gravity")
		set_cvar_num("sv_gravity", leviathan_gravity)
	}
}

public remove_flood()
{
	if (!FloodOn) return
	FloodOn=false
	set_cvar_num("sv_gravity", svgravity)
}

public leviathan_maxhealth()
{
	new id[6]
	new health[9]

	read_argv(1,id,5)
	read_argv(2,health,8)

	gPlayerMaxHealth[str_to_num(id)] = str_to_num(health)
}

public leviathan_damage(id)
{
	if (!FloodOn) return PLUGIN_CONTINUE

	new damage = read_data(2)
	new weapon, bodypart, attacker = get_user_attacker(id, weapon, bodypart)

	if (attacker <= 0 || attacker > SH_MAXSLOTS) return PLUGIN_CONTINUE

	if (gHasLeviathanPowers[attacker] && is_user_alive(id) && attacker!=id) {
		new extraDamage = floatround(damage * leviathan_underwaterdmg - damage)
		if (extraDamage>0) if (get_user_health(id)>extraDamage) 
			shExtraDamage(id, attacker, extraDamage, "leviathan")
		else shExtraDamage(id, attacker, get_user_health(id)-random_num(1,6), "leviathan")
	}
	return PLUGIN_CONTINUE
}
