//Tyrael - by Mydas

/*
tyrael_level 4
tyrael_chance 0.15  - chance to Banish an opponent
tyrael_banishtime 3 - amount of time the banishment lasts
tyrael_cooldown 6   - how long till he can banish someone again
*/

#include <amxmod>
#include <superheromod>

// VARIABLES
new gHeroName[]="Tyrael"
new bool:gHasTyraelPowers[SH_MAXSLOTS + 1]
new tyraelCooldown

public plugin_init()
{
	register_plugin("SUPERHERO Tyrael", "1.0", "Mydas")
 
	register_cvar("tyrael_level", "4" )
	shCreateHero(gHeroName, "Banish", "Temporarily teleports your attackers to the netherworld", false, "tyrael_level" )

	register_srvcmd("tyrael_init", "tyrael_init")
	shRegHeroInit(gHeroName, "tyrael_init")

	register_event("ResetHUD","newRound","b")
	register_event("Damage", "tyrael_damage", "b", "2!0")

	register_cvar("tyrael_chance", "0.15")
	register_cvar("tyrael_banishtime", "3")
	register_cvar("tyrael_cooldown", "6")
}

public tyrael_init()
{
	new temp[6]
	read_argv(1,temp,5)

	new id=str_to_num(temp)
	read_argv(2,temp,5)

	new hasPowers=str_to_num(temp)
	gHasTyraelPowers[id] = (hasPowers!=0)
	tyraelCooldown=get_cvar_num("tyrael_cooldown")
}

public newRound(id)
{
	gPlayerUltimateUsed[id]=false
}

public tyrael_damage(id)
{
	if (!gHasTyraelPowers[id] || gPlayerUltimateUsed[id]) return PLUGIN_CONTINUE

	//new damage = read_data(2)
	new weapon, bodypart, attacker = get_user_attacker(id, weapon, bodypart)

	if (is_user_alive(id) && attacker!=id && random_num(1, 100)<=floatround(100*get_cvar_float("tyrael_chance"))) {
		new origin[3]
		get_user_origin(attacker, origin)
		origin[2]-=3000
		set_user_origin(attacker, origin)

		new str[32]
		get_user_name(attacker, str, 32)
		client_print(id, print_center, "%s has been banished for attacking you.", str)
		get_user_name(id, str, 32)
		client_print(attacker, print_center, "You have been banished for attacking %s", str)

		new parm[1]
		parm[0]=attacker
		set_task(get_cvar_float("tyrael_banishtime"), "remove_banishment", attacker, parm, 1)
		ultimateTimer(id, tyraelCooldown * 1.0)
	}

	return PLUGIN_CONTINUE
}

public remove_banishment(parm[])
{
	new id = parm[0]
	new origin[3]
	get_user_origin(id, origin)
	origin[2]+=3000
	set_user_origin(id, origin)
}