// US MARINE! - Cool colt/m4a1.

/* CVARS - copy and paste to shconfig.cfg

//US Marine
usmarine_level 10
usmarine_m4a1mult 1.5		//Multiplier for m4a1 damage
usmarine_gravity 0.40		//Gravity US Marine has

*/

// Another Morpheus rip this time with a m4a1

#include <amxmod>
#include <Vexd_Utilities>
#include <superheromod>

// GLOBAL VARIABLES
new gHeroName[]="US Marine"
new gHasUsmarinePower[SH_MAXSLOTS+1]
//----------------------------------------------------------------------------------------------
public plugin_init()
{
	// Plugin Info
	register_plugin("SUPERHERO US MARINE", "1.1", "M0L")

	register_cvar("usmarine_level", "10")
	register_cvar("usmarine_m4a1mult", "1.5")
	register_cvar("usmarine_gravity", "0.40")


	// FIRE THE EVENT TO CREATE THIS SUPERHERO!
	shCreateHero(gHeroName, "M4A1 Reskin", " Lower Gravity / New M4A1 skin with unlimited ammo and more damge", false, "usmarine_level")

	// REGISTER EVENTS THIS HERO WILL RESPOND TO! (AND SERVER COMMANDS)
	// Init
	register_srvcmd("usmarine_init", "usmarine_init")
	shRegHeroInit(gHeroName, "usmarine_init")

	register_event("ResetHUD", "newSpawn", "b")
	register_event("Damage", "usmarine_damage", "b")
	register_event("CurWeapon", "weaponChange", "be", "1=1")

	// Let Server know about US Marine's Variable
	shSetMinGravity(gHeroName, "usmarine_gravity")
	shSetShieldRestrict(gHeroName)
}
//----------------------------------------------------------------------------------------------
public plugin_precache()
{
	precache_model("models/shmod/usmarine_m4a1.mdl")
}
//----------------------------------------------------------------------------------------------
public usmarine_init()
{
	// First Argument is an id
	new temp[6]
	read_argv(1,temp,5)
	new id = str_to_num(temp)

	// 2nd Argument is 0 or 1 depending on whether the id has the hero
	read_argv(2,temp,5)
	new hasPowers = str_to_num(temp)

	gHasUsmarinePower[id] = (hasPowers != 0)

	//Reset thier shield restrict status
	//Shield restrict MUST be before weapons are given out
	shResetShield(id)

	if ( !is_user_alive(id) ) return

	if ( gHasUsmarinePower[id] ) {
		usmarine_weapons(id)
		switchmodel(id)
	}
	else {
		engclient_cmd(id, "drop", "weapon_m4a1")
		shRemGravityPower(id)
	}
}
//-----------------------------------------------------------------------------------------------
public newSpawn(id)
{
	if ( gHasUsmarinePower[id] && is_user_alive(id) && shModActive() ) {
		set_task(0.1, "usmarine_weapons", id)

		new clip, ammo, wpnid = get_user_weapon(id, clip, ammo)
		if ( wpnid != CSW_M4A1 && wpnid > 0 ) {
			new wpn[32]
			get_weaponname(wpnid, wpn, 31)
			engclient_cmd(id, wpn)
		}
	}
}
//-----------------------------------------------------------------------------------------------
public usmarine_weapons(id)
{
	if ( is_user_alive(id) && shModActive() ) {
		shGiveWeapon(id, "weapon_m4a1")
	}
}
//-----------------------------------------------------------------------------------------------
public switchmodel(id)
{
	if ( !is_user_alive(id) || !gHasUsmarinePower[id] ) return

	new clip, ammo, wpnid = get_user_weapon(id, clip, ammo)
	if ( wpnid == CSW_M4A1 ) {
		// Weapon Model change thanks to [CCC]Taz-Devil
		Entvars_Set_String(id, EV_SZ_viewmodel, "models/shmod/usmarine_m4a1.mdl")
	}
}
//----------------------------------------------------------------------------------------------
public weaponChange(id)
{
	if ( !gHasUsmarinePower[id] || !shModActive() ) return

	new wpnid = read_data(2)
	new clip = read_data(3)

	if ( wpnid != CSW_M4A1 ) return

	switchmodel(id)

	// Never Run Out of Ammo!
	if ( clip == 0 ) {
		shReloadAmmo(id)
	}
}
//-----------------------------------------------------------------------------------------------
public usmarine_damage(id)
{
	if ( !shModActive() || !is_user_alive(id) ) return

	new damage = read_data(2)
	new weapon, bodypart, attacker = get_user_attacker(id, weapon, bodypart)
	new headshot = bodypart == 1 ? 1 : 0

	if ( attacker <= 0 || attacker > SH_MAXSLOTS ) return

	if ( gHasUsmarinePower[attacker] && weapon == CSW_M4A1 && is_user_alive(id) ) {
		// do extra damage
		new extraDamage = floatround(damage * get_cvar_float("usmarine_m4a1mult") - damage)
		if (extraDamage > 0) shExtraDamage(id, attacker, extraDamage, "m4a1", headshot)
	}
}
//-----------------------------------------------------------------------------------------------