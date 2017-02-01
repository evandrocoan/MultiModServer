/* Firestarter 1.0 (by Corvae aka TheRaven)

I've worked on a new teleportation script for my mod
and after finishing it, I thought I could as well put
it to some use in a hero. The idea is simple. You
teleport to where you point your crosshair and there
you explode damaging you the ones around you.


CVARS - copy and paste to shconfig.cfg
--------------------------------------------------------------------------------------------------
//Firestarter
Firestarter_level 5				// Character level to take this hero.
Firestarter_cooldown 20			// Time to wait until you can use the special ability again.
Firestarter_delay 1.0			// The delay between keypress and teleport. You are frozen as well.
Firestarter_mindamage 75		// Minimum damage the explosion does.
Firestarter_maxdamage 125		// Maximum damage the explosion does.
Firestarter_reducedamage 25		// The firestarter himself takes this less damage.
Firestarter_radius 350			// Radius for the explosion
--------------------------------------------------------------------------------------------------*/


#include <amxmod>
#include <Vexd_Utilities>
#include <superheromod>

new gHeroName[]="Firestarter"
new bool:g_hasFirestarterPower[SH_MAXSLOTS+1]
new gLastPosition[SH_MAXSLOTS+1][3]
new checkLocation[SH_MAXSLOTS+1][3]
new newLocation[SH_MAXSLOTS+1][3]
new smoke, white, fire
//----------------------------------------------------------------------------------------------
public plugin_init()
{
	register_plugin("SUPERHERO Firestarter","1.0","TheRaven aka Corvae")

	register_cvar("Firestarter_level", "5" )
	register_cvar("Firestarter_cooldown", "20" )
	register_cvar("Firestarter_delay", "1.0" )
	register_cvar("Firestarter_mindamage", "75" )
	register_cvar("Firestarter_maxdamage", "125" )
	register_cvar("Firestarter_reducedamage", "25" )
	register_cvar("Firestarter_radius", "350" )

	shCreateHero(gHeroName, "Teleport and Explode", "Point to a location and teleport there to explode.", true, "Firestarter_level" )

	register_srvcmd("Firestarter_init", "Firestarter_init")
	shRegHeroInit(gHeroName, "Firestarter_init")
	register_event("ResetHUD","newRound","b")
	register_srvcmd("Firestarter_kd", "Firestarter_kd")
	shRegKeyDown(gHeroName, "Firestarter_kd")
}
//----------------------------------------------------------------------------------------------
public Firestarter_init()
{
	new temp[6]
	read_argv(1,temp,5)
	new id=str_to_num(temp)
	read_argv(2,temp,5)
	new hasPowers = str_to_num(temp)
	g_hasFirestarterPower[id] = (hasPowers != 0)
}
//----------------------------------------------------------------------------------------------
public newRound(id)
{
	gPlayerUltimateUsed[id] = false
}
//----------------------------------------------------------------------------------------------
public Firestarter_kd()
{
	if ( !hasRoundStarted() ) return PLUGIN_HANDLED
	
	new temp[6]
	read_argv(1,temp,5)
	new id = str_to_num(temp)
	if ( !is_user_alive(id) || !g_hasFirestarterPower[id] ) return PLUGIN_HANDLED

	if ( gPlayerUltimateUsed[id] ) {
		set_hudmessage(0, 100, 200, 0.05, 0.70, 1, 0.1, 2.0, 0.1, 0.1, 89)
		show_hudmessage(id, "Ability not yet ready again.")
		playSoundDenySelect(id)
		return PLUGIN_HANDLED
	}
	ultimateTimer(id, get_cvar_float("Firestarter_cooldown"))
	Firestarter_go(id)
	return PLUGIN_HANDLED	
}
//----------------------------------------------------------------------------------------------
public Firestarter_go(id)
{
	new oldLocation[3]

	get_user_origin(id, oldLocation)
	oldLocation[2] += 30
	checkLocation[id][0] = oldLocation[0]
	checkLocation[id][1] = oldLocation[1]
	checkLocation[id][2] = oldLocation[2]
	
	get_user_origin(id, newLocation[id], 3)	
	if((newLocation[id][0] - oldLocation[0]) > 0)
		newLocation[id][0] -= 50
	else
		newLocation[id][0] += 50
	
	if((newLocation[id][1] - oldLocation[1]) > 0)
		newLocation[id][1] -= 50
	else
		newLocation[id][1] += 50
	
	newLocation[id][2] += 40
	
	new Float:Firestarterdelay = get_cvar_float("Firestarter_delay")
	if (Firestarterdelay < 0.0) Firestarterdelay = 0.0
	
	shStun(id, get_cvar_num("Firestarter_delay"))
	set_user_maxspeed(id, -1.0)

	set_task(Firestarterdelay,"NewTeleport", id+25487)
	return PLUGIN_HANDLED
}
//----------------------------------------------------------------------------------------------
public NewTeleport(id)
{	
	id -= 25487
	set_user_origin(id, newLocation[id])
	set_task(0.1,"NewTeleportCheck",id)
	return PLUGIN_HANDLED
}
//----------------------------------------------------------------------------------------------
public NewTeleportCheck(id)
{
	new origin[3]
	new velocity[3]

	if ( !is_user_alive(id) ) return

	get_user_origin(id, origin, 0)
	gLastPosition[id][0]=origin[0]
	gLastPosition[id][1]=origin[1]
	gLastPosition[id][2]=origin[2]

	new Float:vector[3]
	Entvars_Get_Vector(id, EV_VEC_velocity, vector)
	FVecIVec(vector, velocity)

	if ( velocity[0]==0 && velocity[1]==0 && velocity[2] ) {
		velocity[0]=50
		velocity[1]=50

		IVecFVec(velocity, vector)
		Entvars_Set_Vector(id, EV_VEC_velocity, vector)
	}

	set_task(0.5,"NewPositionCheck",id+25487)
}
//----------------------------------------------------------------------------------------------
public NewPositionCheck(id)
{
	id -= 25487
	new origin[3]

	if (!is_user_alive(id) ) return
	get_user_origin(id, origin, 0)
	if ( gLastPosition[id][0] == origin[0] && gLastPosition[id][1] == origin[1] && gLastPosition[id][2] == origin[2] && is_user_alive(id) ) {
		set_user_origin(id, checkLocation[id])
	} else {
		setScreenFlash(id, 255, 10, 10, 10, 200 )
		BlowItUp(id)
	}
}
//----------------------------------------------------------------------------------------------
public plugin_precache()
{
	smoke = precache_model("sprites/steam1.spr")
	white = precache_model("sprites/white.spr")
	fire = precache_model("sprites/explode1.spr")
	precache_sound( "buttons/blip2.wav")
}
//----------------------------------------------------------------------------------------------
public BlowItUp(id)
{
	new damage, distanceBetween, name[32]
	
	new Xmindamage = get_cvar_num("Firestarter_mindamage")
	new Xmaxdamage = get_cvar_num("Firestarter_maxdamage")
	new Xreducedamage = get_cvar_num("Firestarter_reducedamage")
	if ( Xmindamage>Xmaxdamage ) Xmindamage = 75
	if ( Xmindamage>Xmaxdamage ) Xmaxdamage = 125
	if ( Xreducedamage>Xmindamage ) Xreducedamage = Xmindamage
	
	get_user_name(id,name,31)
	new FFOn = get_cvar_num("mp_friendlyfire")
	new origin[3]
	get_user_origin(id,origin)
	explode(origin)

	for(new a = 1; a <= SH_MAXSLOTS; a++) {
		if( is_user_alive(a) && ( get_user_team(id) != get_user_team(a) || FFOn != 0 || a == id ) ) {
			new origin1[3]
			get_user_origin(a,origin1)

			distanceBetween = get_distance(origin, origin1 )
			if( distanceBetween < get_cvar_num("Firestarter_radius") ) {
				new mindamage = Xmindamage - Xreducedamage
				new maxdamage = Xmaxdamage - Xreducedamage
				damage = random_num(mindamage, maxdamage)
				if( a!=id ) {
					user_slap(a,0)
					user_slap(a,0)
					user_slap(a,0)
				}
				shExtraDamage(a, id, damage, "Firestarter")
				if( a!=id ) shExtraDamage(a, id, Xreducedamage, "Firestarter")
			}
		}
	}
}
//----------------------------------------------------------------------------------------------
public explode( vec1[3] )
{
	// blast circles
	message_begin( MSG_BROADCAST,SVC_TEMPENTITY,vec1)
	write_byte( 21 )
	write_coord(vec1[0])
	write_coord(vec1[1])
	write_coord(vec1[2] + 16)
	write_coord(vec1[0])
	write_coord(vec1[1])
	write_coord(vec1[2] + 1936)
	write_short( white )
	write_byte( 0 ) // startframe
	write_byte( 0 ) // framerate
	write_byte( 2 ) // life 2
	write_byte( 20 ) // width 16
	write_byte( 0 ) // noise
	write_byte( 188 ) // r
	write_byte( 220 ) // g
	write_byte( 255 ) // b
	write_byte( 255 ) //brightness
	write_byte( 0 ) // speed
	message_end()

	//Explosion2
	message_begin( MSG_BROADCAST,SVC_TEMPENTITY)
	write_byte( 12 )
	write_coord(vec1[0])
	write_coord(vec1[1])
	write_coord(vec1[2])
	write_byte( 188 ) // byte (scale in 0.1's) 188
	write_byte( 10 ) // byte (framerate)
	message_end()

	//TE_Explosion
	message_begin( MSG_BROADCAST,SVC_TEMPENTITY,vec1)
	write_byte( 3 )
	write_coord(vec1[0])
	write_coord(vec1[1])
	write_coord(vec1[2])
	write_short( fire )
	write_byte( 60 ) // byte (scale in 0.1's) 188
	write_byte( 10 ) // byte (framerate)
	write_byte( 0 ) // byte flags
	message_end()

	//Smoke
	message_begin( MSG_BROADCAST,SVC_TEMPENTITY,vec1)
	write_byte( 5 ) // 5
	write_coord(vec1[0])
	write_coord(vec1[1])
	write_coord(vec1[2])
	write_short( smoke )
	write_byte( 10 )  // 2
	write_byte( 10 )  // 10
	message_end()

}
//----------------------------------------------------------------------------------------------