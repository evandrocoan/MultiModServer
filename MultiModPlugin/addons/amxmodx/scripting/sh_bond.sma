// James Bond! - Cool Deagle/Golden Gun.

/* CVARS - copy and paste to shconfig.cfg

//James Bond
bond_level 6
bond_gravity 0.40		//Gravity James Bond has
bond_deaglemult 1.3  	//Multiplier for Deagle damage

*/

#include <amxmod>
#include <Vexd_Utilities>
#include <superheromod>

// Global VARIABLES
new gHeroName[]="James Bond"
new gHasbondPower[SH_MAXSLOTS+1]
//----------------------------------------------------------------------------------------------
public plugin_init()
{
	// Plugin Info
	register_plugin("SUPERHERO JAMES BOND","1.0","bLiNd")

	register_cvar("bond_level", "10")
	register_cvar("bond_gravity", "0.40")
	register_cvar("bond_deaglemult", "1.5")

	// FIRE THE EVENT TO CREATE THIS SUPERHERO!
	shCreateHero(gHeroName, "Golden Gun", " Lower Gravity / Golden Gun With More Damage.", false, "bond_level" )

	// REGISTER EVENTS THIS HERO WILL RESPOND TO! (AND SERVER COMMANDS)
	// Init
	register_srvcmd("bond_init", "bond_init")
	shRegHeroInit(gHeroName, "bond_init")

	register_event("ResetHUD", "newRound","b")
	register_event("Damage", "bond_damage", "b")
	register_event("CurWeapon", "weaponChange","be","1=1")

	// Let Server know about James Bond's Variable
	shSetMinGravity(gHeroName, "bond_gravity" )
	shSetShieldRestrict(gHeroName)
}
//----------------------------------------------------------------------------------------------
public plugin_precache()
{
	precache_model("models/shmod/bond2_deagle.mdl")
}
//----------------------------------------------------------------------------------------------
public bond_init()
{
	new temp[6]
	// First Argument is an id
	read_argv(1,temp,5)
	new id=str_to_num(temp)

	// 2nd Argument is 0 or 1 depending on whether the id has James Bond
	read_argv(2,temp,5)
	new hasPowers=str_to_num(temp)

	gHasbondPower[id] = (hasPowers != 0)

	//Reset thier shield restrict status
	//Shield restrict MUST be before weapons are given out
	shResetShield(id)

	if ( is_user_alive(id) ) {
		if ( gHasbondPower[id] ) {
			bond_weapons(id)
			switchmodel(id)
		}
		else {
			shRemGravityPower(id)
			engclient_cmd(id, "drop", "weapon_deagle")
		}
	}
}
//-----------------------------------------------------------------------------------------------
public newRound(id)
{
	if ( gHasbondPower[id] && is_user_alive(id) && shModActive() ) {
		bond_weapons(id)

		new clip, ammo, wpnid = get_user_weapon(id,clip,ammo)
		if (wpnid != CSW_DEAGLE && wpnid > 0) {
			new wpn[32]
			get_weaponname(wpnid,wpn,31)
			engclient_cmd(id,wpn)
		}
	}
}
//-----------------------------------------------------------------------------------------------
public bond_weapons(id)
{
	if ( is_user_alive(id) ) {
		shGiveWeapon(id,"weapon_deagle")
	}
}
//-----------------------------------------------------------------------------------------------
public switchmodel(id)
{
	if ( !is_user_alive(id) || !gHasbondPower[id] ) return

	new clip, ammo, wpnid = get_user_weapon(id,clip,ammo)
	if (wpnid == CSW_DEAGLE) {
		// Weapon Model change thanks to [CCC]Taz-Devil
		Entvars_Set_String(id, EV_SZ_viewmodel, "models/shmod/bond2_deagle.mdl")
	}
}
//----------------------------------------------------------------------------------------------
public weaponChange(id)
{
	if ( !gHasbondPower[id] || !shModActive() ) return

	new wpnid = read_data(2)
	new clip = read_data(3)

	if ( wpnid != CSW_DEAGLE ) return

	switchmodel(id)

	// Never Run Out of Ammo!
	if ( clip == 0 ) {
		shReloadAmmo(id)
	}
}
//-----------------------------------------------------------------------------------------------
public bond_damage(id)
{
	if (!shModActive() || !is_user_alive(id)) return

	new damage = read_data(2)
	new weapon, bodypart, attacker = get_user_attacker(id,weapon,bodypart)
	new headshot = bodypart == 1 ? 1 : 0

	if ( attacker <= 0 || attacker > SH_MAXSLOTS ) return

	if ( gHasbondPower[attacker] && weapon == CSW_DEAGLE && is_user_alive(id)) {
		// do extra damage
		new extraDamage = floatround(damage * get_cvar_float("bond_deaglemult") - damage)
		if (extraDamage > 0) shExtraDamage( id, attacker, extraDamage, "deagle", headshot)
	}
}
//-----------------------------------------------------------------------------------------------