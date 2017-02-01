//Sub-Zero From Mortal Kombat

//Credits go to SRGety for forge

/*
//Subzero
subzero_level 0 //At what level is this hero available
subzero_cooldown  2.0 //cooldown for his ice balst
subzero_blastspeed 600 //Speed of SubZero's ice blast
subzero_freezetime 5 //for How long is the player Freezed
subzero_freezeradius 50 //radius for the ice blast
subzero_freezedamage 35 //how much damage the ice blast does

*/
/*
* Version 1.0 Posted
* Version 1.1 Better Freeze Effect + a Freeze Sound
*/

#include <amxmod>
#include <superheromod>
#include <Vexd_Utilities>
#include <xtrafun> 

new gHeroName[]="Sub-Zero"
new bool:g_HasSubZeroPower[SH_MAXSLOTS+1]
new gLastWeapon[SH_MAXSLOTS+1]
new blastring

public plugin_init()
{
	// Plugin Info
	register_plugin("SUPERHERO Sub-Zero","1.0","Om3gA/Yang")

	// FIRE THE EVENT TO CREATE THIS SUPERHERO!
	register_cvar("subzero_level", "7" )
	register_cvar("subzero_cooldown", "2.0")
	register_cvar("subzero_blastspeed", "600")
	register_cvar("subzero_freezetime", "5" )
	register_cvar("subzero_freezeradius", "50")
	register_cvar("subzero_freezedamage", "35")

	shCreateHero(gHeroName, "Ice Blast", "Fire A Ice Blast to freeze your enemys", true, "subzero_level" )

	// REGISTER EVENTS THIS HERO WILL RESPOND TO! (AND SERVER COMMANDS)
	register_event("ResetHUD","newRound","b")
	register_touch("ice_blast","*","frozen")
	// KEY DOWN
	register_srvcmd("subzero_kd", "subzero_kd")
	shRegKeyDown(gHeroName, "subzero_kd")

	// INIT
	register_srvcmd("subzero_init", "subzero_init")
	shRegHeroInit(gHeroName, "subzero_init")

}


public plugin_precache()
{
	precache_model("sprites/shmod/iceball.spr")
	precache_sound("shmod/freezed.wav")
	precache_model("models/shmod/freezed.mdl")
	blastring = precache_model("sprites/white.spr")
}


public subzero_init()
{
	new temp[6]
	read_argv(1,temp,5)
	new id=str_to_num(temp)
	read_argv(2,temp,5)
	new hasPowers=str_to_num(temp)

	g_HasSubZeroPower[id]=(hasPowers!=0)
}


public subzero_kd()
{
	new temp[6]

	if ( !hasRoundStarted() ) return PLUGIN_HANDLED

	// First Argument is an id with SubZero Powers!
	read_argv(1,temp,5)
	new id=str_to_num(temp)
	if ( !is_user_alive(id) || !g_HasSubZeroPower[id] || !shModActive() ) return PLUGIN_HANDLED
	if ( gPlayerUltimateUsed[id] ) {
		playSoundDenySelect(id)
		return PLUGIN_HANDLED
	}

	new clip,ammo,weaponID = get_user_weapon(id,clip,ammo)
	gLastWeapon[id] = weaponID


	engclient_cmd(id,"weapon_knife")

	make_iceblast(id)

	if(get_cvar_float("subzero_cooldown") > 0.0)
	ultimateTimer(id, get_cvar_float("subzero_cooldown"))

	// Switch back to previous weapon...
	if ( gLastWeapon[id] != CSW_KNIFE ) shSwitchWeaponID( id, gLastWeapon[id] )

	return PLUGIN_HANDLED
}

public frozen(pToucher, pTouched)
{

	new szClassName[32]
	new victim = pTouched
	Entvars_Get_String(pToucher, EV_SZ_classname, szClassName, 31)

	if(equal(szClassName, "ice_blast") )
	{
		new freezeradius = get_cvar_num("subzero_freezeradius")
		new freezedamage = get_cvar_num("subzero_freezedamage")

		new Float:fl_vExplodeAt[3]
		Entvars_Get_Vector(pToucher, EV_VEC_origin, fl_vExplodeAt)
		new vExplodeAt[3]
		vExplodeAt[0] = floatround(fl_vExplodeAt[0])
		vExplodeAt[1] = floatround(fl_vExplodeAt[1])
		vExplodeAt[2] = floatround(fl_vExplodeAt[2])
		new id = Entvars_Get_Edict(pToucher, EV_ENT_owner)
		new origin[3],dist,i,Float:dRatio,damage

		for ( i = 1; i <= SH_MAXSLOTS; i++)
		{

			if( !is_user_alive(i) ) continue
			get_user_origin(i,origin)
			dist = get_distance(origin,vExplodeAt)
			if (dist <= freezeradius) {

				dRatio = floatdiv(float(dist),float(freezeradius))
				damage = freezedamage - floatround( freezedamage * dRatio)

				shExtraDamage(i, id, damage, "Ice Blast" )
				shStun(i, get_cvar_num("subzero_freezetime"))
				set_user_maxspeed(i, 0.1)
				set_hudmessage(50, 100, 255, -1.0, 0.40, 2, 0.02, 4.0, 0.01, 0.1, 7)
				show_hudmessage(i, "You Got Frozen")
				emit_sound(i, CHAN_WEAPON, "shmod/freezed.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
				freezed(victim)
			}
		}

		message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
		write_byte( 21 )
		write_coord(vExplodeAt[0])
		write_coord(vExplodeAt[1])
		write_coord(vExplodeAt[2])
		write_coord(vExplodeAt[0])
		write_coord(vExplodeAt[1])
		write_coord(vExplodeAt[2] + freezeradius )
		write_short( blastring )
		write_byte( 0 ) // startframe
		write_byte( 1 ) // framerate
		write_byte( 6 ) // 3 life 2
		write_byte( 2 ) // width 16
		write_byte( 1 ) // noise
		write_byte( 50 ) // r
		write_byte( 50 ) // g
		write_byte( 255 ) // b
		write_byte( 200 ) //brightness
		write_byte( 0 ) // speed
		message_end()

		RemoveEntity(pToucher)
	}
}

public freezed(victim)
{
	new Float:vOrigin[3]
	entity_get_vector(victim, EV_VEC_origin, vOrigin)
	vOrigin[2] -= 25
	
	new frozenground = create_entity("info_target")
	entity_set_string(frozenground, EV_SZ_classname, "freezed")
	entity_set_model(frozenground, "models/shmod/freezed.mdl")
	entity_set_size(frozenground, Float:{-2.5, -2.5, -1.5}, Float:{2.5, 2.5, 1.5})
	entity_set_int(frozenground, EV_INT_solid, 0)
	entity_set_int(frozenground,EV_INT_movetype, MOVETYPE_NOCLIP)
	entity_set_vector(frozenground, EV_VEC_origin, vOrigin)
}

public make_iceblast(id)
{
	new Float:Origin[3]
	new Float:Velocity[3]
	new Float:vAngle[3]

	new BlastSpeed = get_cvar_num("subzero_blastspeed")

	Entvars_Get_Vector(id, EV_VEC_origin , Origin)
	Entvars_Get_Vector(id, EV_VEC_v_angle, vAngle)

	new NewEnt = CreateEntity("info_target")

	entity_set_string(NewEnt, EV_SZ_classname, "ice_blast")

	entity_set_model(NewEnt, "sprites/shmod/iceball.spr")

	entity_set_size(NewEnt, Float:{-1.5, -1.5, -1.5}, Float:{1.5, 1.5, 1.5})

	ENT_SetOrigin(NewEnt, Origin)
	entity_set_vector(NewEnt, EV_VEC_angles, vAngle)
	entity_set_int(NewEnt, EV_INT_solid, 2)

	//thanx to vittu for this part.
	entity_set_int(NewEnt, EV_INT_rendermode, 5)
	entity_set_float(NewEnt, EV_FL_renderamt, 200.0)
	entity_set_float(NewEnt, EV_FL_scale, 1.00)

	entity_set_int(NewEnt, EV_INT_movetype, 5)
	entity_set_edict(NewEnt, EV_ENT_owner, id)

	VelocityByAim(id, BlastSpeed , Velocity)
	entity_set_vector(NewEnt, EV_VEC_velocity ,Velocity)

	return PLUGIN_HANDLED
}
//----------------------------------------------------------------------------------------------
public newRound(id) {
	
	gPlayerUltimateUsed[id]=false
	RemoveByClass(id)

	return PLUGIN_CONTINUE
}
public RemoveByClass(id){
	new frozenground = 0 
	do{ 
	frozenground = find_entity(frozenground,"freezed") 
 	if (frozenground > 0) 
 	  RemoveEntity(frozenground) 
  	} 
  	  while (frozenground) 
}
