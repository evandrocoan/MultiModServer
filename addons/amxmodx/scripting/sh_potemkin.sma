#include <amxmod.inc>
#include <superheromod.inc>

// GGXX Potemkin

// CVARS
// potemkin_level  - guess what
// potemkin_speed  - he's a behemoth, so he'll be slow
// potemkin_chance - the chance he'll get to negate an attack

// VARIABLES
new gHeroName[]="Potemkin"
new bool:gHasPotemkinPower[SH_MAXSLOTS+1]
new potemkin_speed
//-------------------------------------------------------------------------------------------------------
public plugin_init()
{
	// Plugin Info
	register_plugin("SUPERHERO Potemkin","1.0","Mydas")

	// Fire the Event to Create This SuperHero
	if ( isDebugOn() ) server_print("Attempting to create Potemkin Hero")
	register_cvar("potemkin_level", "9" )
	shCreateHero(gHeroName, "Powerful and Protective", "Slow, but very powerful. Deals double damage and has a chance to negate any attack on himself", false, "potemkin_level" )

	// Register Events This Hero Will Respond To! (And Server Commands)
	register_srvcmd("potemkin_init","potemkin_init")
	shRegHeroInit(gHeroName, "potemkin_init")

	// NEW ROUND
	register_event("ResetHUD","newRound","b")

	// Loop
	register_srvcmd("potemkin_loop","potemkin_loop")
	set_task(1.0,"potemkin_loop",0,"",0,"b")

	// DAMAGE
	register_event("Damage", "potemkin_damage", "b", "2!0")

	// DEFAULT THE CVARS
	register_cvar("potemkin_speed", "120" )
	register_cvar("potemkin_chance", "0.2" )
}
//-------------------------------------------------------------------------------------------------------
public potemkin_init()
{
	new temp[6]
	// First Argument is an id
	read_argv(1,temp,5)
	new id=str_to_num(temp)

	// 2nd Argument is 0 or 1 depending on whether the id has flash
	read_argv(2,temp,5)
	new hasPowers=str_to_num(temp)
	gHasPotemkinPower[id]=(hasPowers!=0)

	if ( !hasPowers && is_user_connected(id) )
	{
		set_user_maxspeed(id)
	}
	if ( is_user_alive(id) && gHasPotemkinPower[id] )
	{
		potemkin_speed=get_cvar_num("potemkin_speed")
		shStun(id, 999)
		set_user_maxspeed(id, potemkin_speed * 1.0)
	}
}

//-------------------------------------------------------------------------------------------------------
public newRound(id)
{
	if (is_user_alive(id) && gHasPotemkinPower[id] )
	{
		shStun(id, 999)
		set_user_maxspeed(id, potemkin_speed * 1.0)
	}
	return PLUGIN_HANDLED
}
//-------------------------------------------------------------------------------------------------------
public potemkin_loop()
{
	for ( new id=1; id<=SH_MAXSLOTS; id++ ) {
		if (gHasPotemkinPower[id] && is_user_alive(id)) {
			set_user_maxspeed(id, potemkin_speed * 1.0)
			shStun(id, 999)
		}
	}
}
//-------------------------------------------------------------------------------------------------------
public potemkin_damage(id)
{
	if (!shModActive() || !is_user_alive(id)) return PLUGIN_CONTINUE

	new damage = read_data(2)
	new weapon, bodypart, attacker = get_user_attacker(id, weapon, bodypart)

	if ( attacker <= 0 || attacker > SH_MAXSLOTS ) return PLUGIN_CONTINUE

	if ( gHasPotemkinPower[attacker] && weapon != CSW_HEGRENADE && is_user_alive(id) ) {
		// do extra damage
		new extraDamage = damage //floatround(damage * get_cvar_float("wolv_knifemult") - damage)
		shExtraDamage( id, attacker, extraDamage, "Potemkin's Heavy Damage" )
	}
	if ( gHasPotemkinPower[id] && is_user_alive(id) ) {
		new randNum = random_num(0, 100)
		if (get_cvar_float("potemkin_chance") * 100 >= randNum) shAddHPs(id, damage, 1000)
	}
	return PLUGIN_CONTINUE
}
//----------------------------------------------------------------------------------------------