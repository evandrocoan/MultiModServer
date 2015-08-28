// Naruto

/* Cvars - copy and paste into shconfig.cfg
// Naruto
naru_level 2 // Level
naru_health 200 // Health
naru_hppersec 4 // How much hp will he heal per second?
naru_knifemult 2.0 // Knife multiplyer
naru_speed 500 // Running speed
naru_gravity 0.5 // Gravity (0.5 is like sv_gravity 400)
naru_footsteps 0 // Will you hear him when he run?
*/

/*******************************
* Created this hero because my
* friend Tobias Bj'o'rklund
* wanted me to do it.
*******************************/

/**************************************
* Creator: Berserker
* Idea by: Tobias
* Thank you K-OS for helping me.
* Model from http://www.fpsbanana.com
* Thank Doom for the modelswitch,
* even if I made the code.
**************************************/

#include <amxmodx>
#include <superheromod>
#include <engine>

new gHeroName[]="Naruto"
new bool:gHasNarutoPowers[SH_MAXSLOTS+1]
new gPlayerMaxHealth[SH_MAXSLOTS+1]
//-------------------------------------
public plugin_init()
{
	register_plugin("SUPERHERO Naruto", "1.00", "Berserker")

	register_cvar("naru_level", "2")
	register_cvar("naru_health", "200")
	register_cvar("naru_hppersec", "4")
	register_cvar("naru_knifemult", "2.0")
	register_cvar("naru_speed", "500")
	register_cvar("naru_gravity", "0.5")
	register_cvar("naru_footsteps", "0")
	
	shCreateHero(gHeroName, "HP, Speed, etc.", "He has the Kyuubi sealed in himself. He is Naruto!", false, "naru_level")
	
	register_srvcmd("naru_init", "naru_init")
	shRegHeroInit(gHeroName, "naru_init")
	
	register_srvcmd("naru_maxhealth", "naru_maxhealth")
	shRegMaxHealth(gHeroName, "naru_maxhealth")

	shSetMaxHealth(gHeroName, "naru_health")
	shSetMinGravity(gHeroName, "naru_gravity")
	shSetMaxSpeed(gHeroName, "naru_speed", "[0]")
	
	register_event("Damage", "naru_damage", "b", "2!0")
	register_event("CurWeapon", "weaponChange","be","1=1")
	
	set_task(1.0,"naru_loop",0,"",0,"b" )
}
//---------------------------------------
public naru_init()			
{
	new temp[6]
	read_argv(1,temp,5)
	new id=str_to_num(temp)
	
	read_argv(2,temp,5)
	new hasPowers = str_to_num(temp)
	
	gPlayerMaxHealth[id] = 100
	gHasNarutoPowers[id] = (hasPowers!=0)

	if( !hasPowers ) {
		shRemHealthPower(id)
		shRemGravityPower(id)
		shRemSpeedPower(id)
		set_user_footsteps(id, 1)
	}
	else if( get_cvar_num("naru_footsteps") )
		set_user_footsteps(id, 0)
}
//----------------------------------------
public naru_loop()
{		
	if (!shModActive()) return
	
	new HealPoints = get_cvar_num("naru_hppersec")
	
	for ( new id = 1; id <= SH_MAXSLOTS; id++ ) {
		if (  gHasNarutoPowers[id] && is_user_alive(id) )   {
			shAddHPs(id, HealPoints, gPlayerMaxHealth[id] )
		}
	}
}
//----------------------------------------
public plugin_precache()
{
	precache_model("models/shmod/naruto_v_knife.mdl")
}
//----------------------------------------
public naru_damage(id)
{
	if (!shModActive() || !is_user_alive(id)) return

	new damage = read_data(2)
	new weapon, bodypart, attacker = get_user_attacker(id, weapon, bodypart)
	new headshot = bodypart == 1 ? 1 : 0

	if ( attacker <= 0 || attacker > SH_MAXSLOTS ) return

	if ( gHasNarutoPowers[attacker] && weapon == CSW_KNIFE && is_user_alive(id) ) {
		new extraDamage = floatround(damage * get_cvar_float("naru_knifemult") - damage)
		if (extraDamage > 0) shExtraDamage( id, attacker, extraDamage, "knife", headshot )
	}
	return
}
//-----------------------------------------
public naru_maxhealth()
{
	new id[6]
	new health[9]

	read_argv(1,id,5)
	read_argv(2,health,8)

	gPlayerMaxHealth[str_to_num(id)] = str_to_num(health)
}
//-----------------------------------------
public client_connect(id)
{
	gHasNarutoPowers[id] = false
}
//-----------------------------------------
public weaponChange(id)
{
	if ( !gHasNarutoPowers[id] || !shModActive() ) return

	new wpnid = read_data(2)
	if ( wpnid != CSW_KNIFE ) return
	
	else {
	switchmodel(id)
		 }
}
//-----------------------------------------
public switchmodel(id)
{
	if ( !is_user_alive(id) ) return
	else {
	entity_set_string(id, EV_SZ_viewmodel, "models/shmod/naruto_v_knife.mdl")
		}
}
	