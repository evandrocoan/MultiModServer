// Shadow the Hedgehog - An android created by Dr. Eggman

/* CVARS - copy and paste to shconfig.cfg

//Shadow the Hedgehog
shadow_level 7      //The level you have to be to use Shadow
shadow_health 300   //Health
shadow_armor 400    //Armor
shadow_speed 5000   //Runspeed
shadow_godtime 15   //Time of godmode
shadow_cooldown 60  //Cooldown for Godmode
shadow_coltmult 2.5 //Damage multiplyer for M4A1/Colt

*/

/*
* Made by Berserker
* Idea from Shadow the Hedgehog (the game)
* Took Sepiroth's godmode code so, thank you for the code =)
* Thank you K-OS for the help!
* K-OS made the explosion part.
* Written in Notepad
*/

	/**************** Shadow the Hedgehog *****************
	*						      *
	*   "He was created as the ultimate lifeform."	      *
	*   "Darker, Stronger, Faster, And more dangerous."   *
	*   "His name is Shadow!"			      *
	*						      *
	******************************************************/
/*
Updates

v. 1.1 (20/01 2006)

Now get colt/m4a1 at respawn

v. 1.11 (21/01 2006)
K-OS

Replaced all amx code with amxx code
Added explosion code
Changed the Ultimate code
Fixed some bugs

*/

#include <amxmodx>
#include <engine>
#include <superheromod>


// VARIABLES
new gHeroName[]="Shadow"
new bool:gHasShadowPower[SH_MAXSLOTS+1]
new gCurrentWeapon[SH_MAXSLOTS+1]

//Sprites
new explode, fire, white

#define giveTotal 1
new weapArray[giveTotal][24] = {
	"weapon_m4a1"
}

//--------------------------------------------------------
public plugin_init()
{
	// Plugin Info
	register_plugin("SUPERHERO Shadow","1.11","berserker")

	// FIRE THE EVENT TO CREATE THIS SUPERHERO!
	if ( isDebugOn() ) server_print("Attempting to create Shadow the Hedgehog Hero")
	register_cvar("shadow_level", "0" )

	shCreateHero(gHeroName, "Hero or Villain?", "More damage with Colt M4A1/HP/AP/Godmode + Chaos Blast", true, "shadow_level" )

	// REGISTER EVENTS THIS HERO WILL RESPOND TO! (AND SERVER COMMANDS)

	// KEY DOWN
	register_srvcmd("shadow_kd", "shadow_kd")
	shRegKeyDown(gHeroName, "shadow_kd")  

	// INIT
	register_srvcmd("shadow_init", "shadow_init")
	shRegHeroInit(gHeroName, "shadow_init")

	// EVENTS
	register_event("Damage", "shadow_damage", "b", "2!0")
	register_event("ResetHUD","newRound","b")
	register_event("CurWeapon","changeWeapon","be","1=1")

	// DEFAULT THE CVARS
	register_cvar("shadow_armor", "400")
	register_cvar("shadow_health", "300")
	register_cvar("shadow_speed", "5000")
	register_cvar("shadow_coltmult", "2" )
	register_cvar("shadow_godtime", "15" )
	register_cvar("shadow_cooldown", "60" )

	// Let Server know about Tutorials Variable
	// It is possible that another hero has more hps, less gravity, or more armor
	// so rather than just setting these - let the superhero module decide each round
	shSetMaxHealth(gHeroName, "shadow_health" )
	shSetMinGravity(gHeroName, "shadow_gravity" )
	shSetMaxArmor(gHeroName, "shadow_armor" )
	shSetMaxSpeed(gHeroName, "shadow_speed", "[0]" )
}
//--------------------------------------------------------
public plugin_precache()
{
	explode = precache_model("sprites/fexplo1.spr")
	fire = precache_model("sprites/fire.spr")
	white = precache_model("sprites/white.spr")
	precache_sound("shmod/chaosblast.wav")
}
//--------------------------------------------------------
public shadow_init()
{
	new temp[6]
	// First Argument is an id
	read_argv(1,temp,5) 
	new id = str_to_num(temp) 
  
	// 2nd Argument is 0 or 1 depending on whether the id has flash
	read_argv(2,temp,5) 
	new hasPowers=str_to_num(temp) 
	gHasShadowPower[id]=(hasPowers!=0) 

	//Reset thier shield restrict status
	//Shield restrict MUST be before weapons are given out
	shResetShield(id)
  
	if( hasPowers ) {
		shadow_giveweapons(id)
	}
	else if( is_user_connected(id) ) {
		//Remove everything if dropped
		shRemHealthPower(id)
		shRemArmorPower(id)
		shRemSpeedPower(id)
		shadow_dropweapons(id)
	}
}
//--------------------------------------------------------
// RESPOND TO KEYDOWN
public shadow_kd()
{
	new temp[6]
	// First Argument is an id with Shadow Powers!
	read_argv(1,temp,5)
	new id=str_to_num(temp)
  
	// Let them know they already used the power
	if( gPlayerUltimateUsed[id] || !is_user_alive(id)) {
		playSoundDenySelect(id)
		return PLUGIN_HANDLED
	} 
  
	gPlayerUltimateUsed[id] = true
	ultimateTimer(id, float(get_cvar_num("shadow_cooldown")))

	set_user_godmode(id,1)
	
	new parm[1]
	parm[0] = id
	set_task( float(get_cvar_num("shadow_godtime")), "shadow_end_godmode", 0, parm, 1)
	
	// Message at Keydown
	new message[128]
	format(message, 127, "GODMODE!!!!" )
	set_hudmessage(255,0,0,-1.0,0.3,0,0.25,1.0,0.0,0.0,4)
	show_hudmessage(id, message)

	emit_sound(id, CHAN_AUTO, "shmod/chaosblast.wav", 1.0, ATTN_NORM, 0, PITCH_NORM)
	set_task(2.5, "shadow_chaosblast", 0, parm, 1)

	return PLUGIN_HANDLED 
}
//--------------------------------------------------------
public shadow_end_godmode(parm[])
{
	new id = parm[0]
	set_user_godmode(id,0)
	
	new message[128]
	format(message, 127, "Godmode has ended" )
	set_hudmessage(255,0,0,-1.0,0.3,0,0.25,1.0,0.0,0.0,4)
	show_hudmessage(id, message)

}
//--------------------------------------------------------
public shadow_chaosblast(parm[])
{
	new id = parm[0]
	
	if(!is_user_alive(id)) return
	
	new Origin[3]
	get_user_origin(id, Origin)
  
	// Explosion
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
	write_byte(3)
	write_coord(Origin[0])
	write_coord(Origin[1])
	write_coord(Origin[2] + 32)
	write_short(explode)
	write_byte(100)		// scale
	write_byte(12)		// framerate
	write_byte(0)
	message_end() 
	
	// shockwave
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
	write_byte(21)
	write_coord(Origin[0])
	write_coord(Origin[1])
	write_coord(Origin[2])
	write_coord(Origin[0])
	write_coord(Origin[1])
	write_coord(Origin[2] + 800)
	write_short(white)
	write_byte(0)		// startframe
	write_byte(0)		// framerate
	write_byte(2)		// life
	write_byte(32)		// width 128
	write_byte(0)		// noise
	write_byte(255)		// r
	write_byte(255)		// g
	write_byte(255)		// b
	write_byte(200)		// brightness
	write_byte(0)		// scroll speed
	message_end()
	
	// firewall
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
	write_byte(21)
	write_coord(Origin[0])
	write_coord(Origin[1])
	write_coord(Origin[2] + 16)
	write_coord(Origin[0])
	write_coord(Origin[1])
	write_coord(Origin[2] + 800)
	write_short(fire)
	write_byte(0)		// startframe
	write_byte(0)		// framerate
	write_byte(3)		// life
	write_byte(128)		// width 128
	write_byte(0)		// noise
	write_byte(255)		// r
	write_byte(255)		// g
	write_byte(255)		// b
	write_byte(200)		// brightness
	write_byte(0)		// scroll speed
	message_end()
	
	new Victim_origin[3], distance
	for ( new i = 1; i <= SH_MAXSLOTS; i++) {
		if ( !is_user_alive(i) || i == id) continue
		
		get_user_origin(i, Victim_origin)
		distance = get_distance(Origin, Victim_origin)
		
		if (distance < 400)
			shExtraDamage(i, id, 400 - distance, "Chaos Blast" )
	}
}
//--------------------------------------------------------
public shadow_damage(id)
{
	if (!shModActive() ) return PLUGIN_CONTINUE

	new damage = read_data(2)
	new weapon, bodypart, attacker = get_user_attacker(id, weapon, bodypart)
    
	if ( attacker <=0 || attacker>SH_MAXSLOTS ) return PLUGIN_CONTINUE
    
	if ( gHasShadowPower[attacker] && weapon == CSW_M4A1 && is_user_alive(id) ) {
		// do extra damage
		new extraDamage = floatround(damage * get_cvar_float("shadow_coltmult") - damage)
		shExtraDamage( id, attacker, extraDamage, "Chaos infused Colt" )
	}
	
	return PLUGIN_CONTINUE
}

//--------------------------------------------------------
public newRound(id)
{
	if ( gHasShadowPower[id] && is_user_alive(id) && shModActive() ) {
		set_task(0.1, "shadow_giveweapons",id)
		gPlayerUltimateUsed[id] = false
	}
}
//--------------------------------------------------------
public shadow_giveweapons(id)
{
	if ( !is_user_alive(id) ) return

	for (new x = 0; x < giveTotal; x++) {
		shGiveWeapon(id, weapArray[x])
	}
}
//--------------------------------------------------------
public shadow_dropweapons(id)
{
	if( !is_user_alive(id) || !shModActive() ) return

	for (new x = 0; x < giveTotal; x++) {
		engclient_cmd(id,"drop", weapArray[x])
	}

	new iCurrent = -1
	new Float:weapvel[3]

	while ( (iCurrent = find_ent_by_class(iCurrent, "weaponbox")) > 0 ) {
		//Skip anything not owned by this client
		if( entity_get_edict(iCurrent, EV_ENT_owner) != id) continue
		
		//Get Weapon velocites
		entity_get_vector(iCurrent, EV_VEC_velocity, weapvel)
		if (weapvel[0] == 0.0 && weapvel[1] == 0.0 && weapvel[2] == 0.0) continue
		
		remove_entity(iCurrent)
	}
}
//--------------------------------------------------------
public changeWeapon(id)
{
	if( !shModActive() || !gHasShadowPower[id] ) return

	new weaponid = read_data(2)
	new clip = read_data(3)

	if( gCurrentWeapon[id] != weaponid ) {
		gCurrentWeapon[id] = weaponid
		shadow_zoomout(id)
	}
	
	if( !clip ) shReloadAmmo(id)
}
//--------------------------------------------------------
public client_connect(id)
{
	gHasShadowPower[id] = false
}
//--------------------------------------------------------
public shadow_zoomout(id)
{
	if ( !is_user_connected(id) || !is_user_alive(id)) return
	message_begin(MSG_ONE, get_user_msgid("SetFOV"), {0,0,0}, id)
	write_byte(90)
	message_end()
}
//--------------------------------------------------------