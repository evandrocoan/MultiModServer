// Red Blood by FireWalker877
// Thanks to AssKicR and JTP10181 for the magneto code! And thanks to (_msv) for the idea. :)

/* CVARS - copy and paste to shconfig.cfg

//Redblood
redblood_level 10
redblood_cooldown 5			//Time delay between automatic uses
redblood_damage .5			//Fraction of attacker's health to be deducted. Default .50
*/

#include <amxmod>
#include <Vexd_Utilities>
#include <superheromod>

// GLOBAL VARIABLES
new gHeroName[]="Red Blood"
new bool:gHasRedbloodPowers[SH_MAXSLOTS+1]
new gSpriteLightning
//----------------------------------------------------------------------------------------------
public plugin_init()
{
	// Plugin Info
	register_plugin("SUPERHERO Red Blood","1.2","FireWalker877")

	// DO NOT EDIT THIS FILE TO CHANGE CVARS, USE THE SHCONFIG.CFG
	register_cvar("redblood_level", "10" )
	register_cvar("redblood_cooldown", "5" )
	register_cvar("redblood_damage", ".5" )

	// FIRE THE EVENT TO CREATE THIS SUPERHERO!
	shCreateHero(gHeroName, "Revenge!", "Do instant damage to your attacker!", false, "redblood_level" )

	// REGISTER EVENTS THIS HERO WILL RESPOND TO! (AND SERVER COMMANDS)

	// INIT
	register_srvcmd("redblood_init", "redblood_init")
	shRegHeroInit(gHeroName, "redblood_init")

	// GET MORE GUNZ!
	register_event("ResetHUD", "newSpawn", "b")
	register_event("Damage", "damage_attacker", "b", "2!0")
	
	//Shield Restrict
	shSetShieldRestrict(gHeroName)

}
//----------------------------------------------------------------------------------------------
public plugin_precache()
{
	precache_sound("debris/beamstart15.wav")
	gSpriteLightning = precache_model("sprites/lgtning.spr")
}
//----------------------------------------------------------------------------------------------
public newSpawn(id)
{
	gPlayerUltimateUsed[id] = false
}
//----------------------------------------------------------------------------------------------
public redblood_init()
{
	// First Argument is an id
	new temp[6]
	read_argv(1,temp,5)
	new id=str_to_num(temp)

	// 2nd Argument is 0 or 1 depending on whether the id has wolverine skills
	read_argv(2,temp,5)
	new hasPowers = str_to_num(temp)

	gHasRedbloodPowers[id] = (hasPowers != 0)

	//Reset thier shield restrict status
	//Shield restrict MUST be before weapons are given out
	shResetShield(id)
}
//----------------------------------------------------------------------------------------------
public damage_attacker(id)
{
	if ( !shModActive() || !gHasRedbloodPowers[id] || gPlayerUltimateUsed[id] || !is_user_connected(id) ) 
		return
	
	new attacker = get_user_attacker(id)

	if ( attacker <= 0 || attacker > SH_MAXSLOTS ) return

	if ( is_user_alive(attacker) && !get_user_godmode(attacker) && !gHasRedbloodPowers[attacker] && id != attacker ) {
		new attackerHealth = get_user_health(attacker)

		new rbHP = floatround( attackerHealth * get_cvar_float("redblood_damage") )
		if (rbHP <= 0) rbHP = 1
		shExtraDamage(attacker, id, rbHP, "red blood")

		ultimateTimer(id, get_cvar_num("redblood_cooldown") * 1.0)
		playSound(id)
		playSound(attacker)
		lightning_effect(id, attacker, 2)
		setScreenFlash(attacker, 255, 0, 0, 10, 200 )  //Screen Flash
	}
}
//----------------------------------------------------------------------------------------------
public lightning_effect(id, targetid, linewidth)
{
	message_begin( MSG_BROADCAST, SVC_TEMPENTITY )
	write_byte( 8 )
	write_short(id)	// start entity
	write_short(targetid)	// entity
	write_short(gSpriteLightning )	// model
	write_byte( 0 ) // starting frame
	write_byte( 15 )  // frame rate
	write_byte( 10 )  // life
	write_byte( linewidth )  // line width
	write_byte( 60 )  // noise amplitude
	write_byte( 255 )	// r, g, b
	write_byte( 0 )	// r, g, b
	write_byte( 0 )	// r, g, b
	write_byte( 255 )	// brightness
	write_byte( 0 )	// scroll speed
	message_end()
}
//----------------------------------------------------------------------------------------------
public playSound(id)
{
	new parm[1]
	parm[0] = id

	emit_sound(id, CHAN_AUTO, "debris/beamstart15.wav", 1.0, ATTN_NORM, 0, PITCH_HIGH)
	set_task(1.5,"stopSound", 0, parm, 1)
}
//----------------------------------------------------------------------------------------------
public stopSound(parm[])
{
	new sndStop = (1<<5)
	emit_sound(parm[0], CHAN_AUTO, "debris/beamstart15.wav", 1.0, ATTN_NORM, sndStop, PITCH_NORM)
}
//----------------------------------------------------------------------------------------------