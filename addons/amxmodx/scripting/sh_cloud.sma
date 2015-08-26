#include <amxmod>
#include <superheromod>
#include <Vexd_Utilities>

// VARIABLES
new smoke
new gspritestreak
new streak_shots[33]

// Damage Variables
#define h1_dam 100 //head
#define h2_dam 75  //body
#define h3_dam 65  //stomach
#define h4_dam 45  //arm
#define h6_dam 45  //leg

new gHeroName[]="Cloud"
new bool:g_hasCloudPower[SH_MAXSLOTS+1]
new gLastWeapon[SH_MAXSLOTS+1]
//----------------------------------------------------------------------------------------------
public plugin_init()
{
	// Plugin Info
	register_plugin("SUPERHERO Cloud", ".1", "SRGrty")

	register_cvar("Cloud_level", "5" )
	register_cvar("Cloud_streak_ammo", "25")
	register_cvar("Cloud_streak_burndecals", "1")
	register_cvar("Cloud_cooldown", "0.10" )
	register_cvar("Cloud_knifemult", "5")

	// FIRE THE EVENT TO CREATE THIS SUPERHERO!
	shCreateHero(gHeroName, "Cloud", "Fires Clouds limit break Blade Beam!", true, "Cloud_level")

	// REGISTER EVENTS THIS HERO WILL RESPOND TO! (AND SERVER COMMANDS)
	// INIT
	register_srvcmd("Cloud_init", "Cloud_init")
	shRegHeroInit(gHeroName, "Cloud_init")

	register_event("ResetHUD","newRound","b")
	register_event("WeapPickup","model","b","1=19")
	register_event("Damage", "Cloud_damage", "b", "2!0")
	register_event("CurWeapon","check_Knife","be","1=1")

	// KEY DOWN
	register_srvcmd("Cloud_kd", "Cloud_kd")
	shRegKeyDown(gHeroName, "Cloud_kd")

	register_srvcmd("Cloud_ku", "Cloud_ku")
	shRegKeyUp(gHeroName, "Cloud_ku")

	// DEATH
	register_event("DeathMsg", "Cloud_death", "a")
}
//----------------------------------------------------------------------------------------------
public plugin_precache()
{
	precache_model("models/Cloud/buster-sword.mdl")
	gspritestreak = precache_model("sprites/streak.spr")
	smoke = precache_model("sprites/steam1.spr")
	precache_sound("weapons/electro4.wav")
	precache_sound("vox/_period.wav")
}
//----------------------------------------------------------------------------------------------
public Cloud_init()
{
	new temp[128]
	// First Argument is an id
	read_argv(1,temp,5)
	new id=str_to_num(temp)

	// 2nd Argument is 0 or 1 depending on whether the id has Cloud powers
	read_argv(2,temp,5)
	new hasPowers=str_to_num(temp)

	g_hasCloudPower[id]=(hasPowers!=0)

}
//----------------------------------------------------------------------------------------------
public Cloud_death()
{
	new id=read_data(2)

	if ( id<0 || id>SH_MAXSLOTS ) return PLUGIN_CONTINUE
	remove_task(id)
	return PLUGIN_CONTINUE

}
//----------------------------------------------------------------------------------------------
public newRound(id)
{
	if ( !hasRoundStarted() ) {
		streak_shots[id] = get_cvar_num("Cloud_streak_ammo")
		gPlayerUltimateUsed[id]=false
	}
	return PLUGIN_HANDLED
}
//----------------------------------------------------------------------------------------------
// RESPOND TO KEYDOWN
public Cloud_kd()
{
	if ( !hasRoundStarted() ) return PLUGIN_HANDLED

	// First Argument is an id
	new temp[6]
	read_argv(1,temp,5)
	new id=str_to_num(temp)

	if ( !is_user_alive(id) ) return PLUGIN_HANDLED

	// Remember this weapon...
	new clip,ammo,weaponID=get_user_weapon(id,clip,ammo);
	gLastWeapon[id]=weaponID

	// switch to knife
	engclient_cmd(id,"weapon_knife")

	// Let them know they already used their ultimate if they have
	new parm[1]
	parm[0]=id
	CloudFire(parm)  // 1 immediate shot
	set_task( get_cvar_float("Cloud_cooldown"), "CloudFire", id, parm, 1, "b")  //delayed shots

	return PLUGIN_HANDLED
}
//----------------------------------------------------------------------------------------------
public CloudFire(parm[])
{
	fire_streak(parm[0])
}
//----------------------------------------------------------------------------------------------
public Cloud_ku()
{
	// First Argument is an id
	new temp[6]
	read_argv(1,temp,5)
	new id=str_to_num(temp)

	remove_task(id)
}
//----------------------------------------------------------------------------------------------
public streakEffects(id, aimvec[3] )
{
	new choose_decal,decal_id

	emit_sound(id,CHAN_ITEM, "weapons/electro4.wav", 1.0, ATTN_NORM, 0, PITCH_NORM)

	choose_decal = random_num(0,0)
	switch(choose_decal)
	{
		case 0: decal_id = 28
		case 1: decal_id = 103
		case 2: decal_id = 198
		case 3: decal_id = 199
	}

	new origin[3]
	get_user_origin(id, origin, 1)

	//Streakning
	message_begin( MSG_BROADCAST,SVC_TEMPENTITY)
	write_byte ( 0 )
	write_coord(origin[0])
	write_coord(origin[1])
	write_coord(origin[2])
	write_coord(aimvec[0])
	write_coord(aimvec[1])
	write_coord(aimvec[2])
	write_short( gspritestreak )
	write_byte( 1 ) // framestart
	write_byte( 5 ) // framerate
	write_byte( 2 ) // life
	write_byte( 50 ) // width
	write_byte( 30 ) // noise
	write_byte( 0 ) // r, g, b
	write_byte( 130 ) // r, g, b
	write_byte( 125 ) // r, g, b
	write_byte( 200 ) // brightness
	write_byte( 200 ) // speed
	message_end()

	//Sparks
	message_begin( MSG_PVS, SVC_TEMPENTITY, aimvec)
	write_byte( 9 )
	write_coord( aimvec[0] )
	write_coord( aimvec[1] )
	write_coord( aimvec[2] )
	message_end()

	//Smoke
	message_begin( MSG_BROADCAST,SVC_TEMPENTITY, aimvec)
	write_byte( 5 ) // 5
	write_coord(aimvec[0])
	write_coord(aimvec[1])
	write_coord(aimvec[2])
	write_short( smoke )
	write_byte( 10 )  // 10
	write_byte( 10 )  // 10
	message_end()

	if(get_cvar_num("Cloud_streak_burndecals") == 1)
	{
		//TE_GUNSHOTDECAL
		message_begin( MSG_BROADCAST,SVC_TEMPENTITY)
		write_byte( 109 ) // decal and ricochet sound
		write_coord( aimvec[0] ) //pos
		write_coord( aimvec[1] )
		write_coord( aimvec[2] )
		write_short (0)
		write_byte (decal_id) //decal
		message_end()
	}

}
//----------------------------------------------------------------------------------------------
public fire_streak(id)
{
	new aimvec[3]
	new tid,tbody
	new FFOn= get_cvar_num("mp_friendlyfire")

	if( !is_user_alive(id) ) return

	if ( streak_shots[id]<=0 )
	{
		playSoundDenySelect(id)
		return
	}

	// Use the ultimate
	// ultimateTimer(id, get_cvar_float("Cloud_cooldown") )

	// Make sure still on knife
	new clip,ammo,weaponID=get_user_weapon(id,clip,ammo);
	if ( weaponID != CSW_KNIFE ) engclient_cmd(id,"weapon_knife")

	// Warn How many Blasts Left...
	streak_shots[id]--
	if(streak_shots[id] < 6) client_print(id,print_chat,"Warning %d Cloud Blade Beams Left", streak_shots[id] )

	get_user_origin(id,aimvec,3)
	streakEffects(id,aimvec)

	get_user_aiming(id,tid,tbody,9999)

	if( tid > 0 && tid < 33 && ( FFOn || get_user_team(id)!=get_user_team(tid) ) )
	{
		emit_sound(tid,CHAN_ITEM, "ambience/thunder_clap.wav", 1.0, ATTN_NORM, 0, PITCH_NORM)

		// Determine the damage
		new damage;
		switch(tbody)
		{
			case 1: damage=h1_dam
			case 2: damage=h2_dam
			case 3: damage=h3_dam
			case 4: damage=h4_dam
			case 5: damage=h4_dam
			case 6: damage=h6_dam
			case 7: damage=h6_dam
		}

		// Deal the damage...
		shExtraDamage(tid, id, damage, "Cloud streak")
	}
}
//----------------------------------------------------------------------------------------------
public client_disconnect(id)
{
	// stupid check but lets see
	if ( id <=0 || id>32 ) return PLUGIN_CONTINUE

	// Yeah don't want any left over residuals
	remove_task(id)

	return PLUGIN_CONTINUE
}
//----------------------------------------------------------------------------------------------
public Cloud_damage(id)
{
	if (!shModActive()) return PLUGIN_CONTINUE

	new damage = read_data(2)
	new weapon, bodypart, attacker = get_user_attacker(id,weapon,bodypart)

	if ( attacker <=0 || attacker>SH_MAXSLOTS ) return PLUGIN_CONTINUE

	if ( g_hasCloudPower[attacker] && weapon == CSW_KNIFE && is_user_alive(id) )
	{
		// do extra damage
		new extraDamage = floatround(damage * get_cvar_float("Cloud_knifemult") - damage)
		shExtraDamage( id, attacker, extraDamage, "Sword" )
	}
	return PLUGIN_CONTINUE
}
//-----------------------------------------------------------------------------------------------
public model(id)
{
	if ( !is_user_alive(id) ) return

	// Weapon Model change thanks to [CCC]Taz-Devil
	Entvars_Set_String(id, EV_SZ_viewmodel, "models/Cloud/buster-sword.mdl")
}
//-----------------------------------------------------------------------------------------------
public check_Knife(id)
{

	if ( !g_hasCloudPower[id] || !shModActive() ) return PLUGIN_CONTINUE
	new clip, ammo
	new wpn_id=get_user_weapon(id, clip, ammo)

	if ( wpn_id == CSW_KNIFE ) model(id)

	if ( !g_hasCloudPower[id] || !shModActive() ) return PLUGIN_CONTINUE

	new wpn[32]
	if ( wpn_id!=CSW_KNIFE ) return PLUGIN_CONTINUE

	if ( clip == 0 )
	{
		//server_print("INVOKING MATTBT MODE! ID=%d CLIP=%d, AMMO=%d WPN=%d", id, clip, ammo, wpn_id)
		get_weaponname(wpn_id,wpn,31)
		//highly recommend droppging weapon - buggy without it!
		give_item(id,wpn)
		engclient_cmd(id, wpn )
		engclient_cmd(id, wpn )
		engclient_cmd(id, wpn )
	}
	return PLUGIN_CONTINUE
}
//--------------------------------------------------------------------------------------------------------