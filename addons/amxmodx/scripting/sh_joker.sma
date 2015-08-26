#include <amxmod>
#include <superheromod>
#include <vexd_utilities>

// The Joker! - High damage para and tie squirter aka bubble squirter!
// NOTE! THIS HERO USED -|-LoA-|-Bass's BUBBLE THROWER CODE!

// CVARS
// joker_level - What level till they can use Joker? (Default 0)
// joker_health - How much health for Joker? (Default 100)
// joker_armor - How much armor for Joker? (Default 0)
// joker_m249mult - How much damage does Joker's para do? (Default 35)
// joker_armorcost - How much armor does it cost to shoot Joker's tie squirter? (Default 15)
// joker_numsquirts - How many tie squirts does Joker have? (Default 6)
// joker_squirtdamage - How much damage does Joker's tie squirter do? (Default 25)

// VARIABLES
new gHeroName[]="The Joker"
new gHasJokerPower[SH_MAXSLOTS+1]
new bool:g_HasJokaPower[SH_MAXSLOTS+1]
new gIsBurning[SH_MAXSLOTS+1]
new gSpriteBubble
//----------------------------------------------------------------------------------------------
public plugin_init()
{
	// PLUGIN INFO
	register_plugin("SUPERHERO JOKER","1.0","-=InViSiBlEMan=- and SlammerVirus")

	// FIRE THE EVENT TO CREATE THIS SUPERHERO!
	if ( isDebugOn() ) server_print("Attempting to create Joker Hero")
	register_cvar("joker_level", "0" )
	shCreateHero(gHeroName, "Tie Squirter", "Your Tommy Gun does more damage and you got a tie squirter!", true, "joker_level" )

	// INIT
	register_srvcmd("joker_init", "joker_init")
	shRegHeroInit(gHeroName, "joker_init")

	// KEYDOWN
	register_srvcmd("joker_kd", "joker_kd")
	shRegKeyDown(gHeroName, "joker_kd")

	// EXTRA PARA DAMAGE
	register_event("Damage", "joker_damage", "a", "2!0")

	// DEFAULT THE CVARS
	register_cvar("joker_armorcost", "15" )
	register_cvar("joker_numsquirts", "6" )
	register_cvar("joker_squirtdamage", "25" )
	if ( !cvar_exists("joker_health" ) )register_cvar("joker_health", "100" )
	if ( !cvar_exists("joker_armor" ) )register_cvar("joker_armor", "0" )
	if ( !cvar_exists("joker_m249mult" ) )register_cvar("joker_m249mult", "35" )

	// SERVER DECIDE IMPULSES MAX SPEED, HP, AND AP
	shSetMaxHealth(gHeroName, "joker_health" )
	shSetMaxArmor(gHeroName, "joker_armor" )
}
//---------------------------------------------------------------------------------------------
public joker_init()
{
	// FIRST ARGUMENT IS AN ID
	new temp[6]
	read_argv(1,temp,5)
	new id = str_to_num(temp)

	// 2ND ARGUMENT IS IF ID HAS JOKER OR NOT
	read_argv(2,temp,5)
	new hasPowers = str_to_num(temp)

	g_HasJokaPower[id]=(hasPowers!=0)
}
//----------------------------------------------------------------------------------------------
public joker_giveweapon(id)
{
	shGiveWeapon(id,"weapon_m249")
}
//----------------------------------------------------------------------------------------------
public plugin_precache()
{
	gSpriteBubble = precache_model("sprites/bubble.spr")
	//precache_sound("misc/bubbles.wav")
}
//---------------------------------------------------------------------------------------------
public joker_damage(id)
{
	if (!shModActive()) return PLUGIN_CONTINUE

	new damage = read_data(2)
	new weapon, bodypart, attacker = get_user_attacker(id,weapon,bodypart)

	if ( attacker <=0 || attacker>SH_MAXSLOTS ) return PLUGIN_CONTINUE

	if ( gHasJokerPower[attacker] && weapon == CSW_M249 && is_user_alive(id) )
	{
		// XTRA DAMAGE
		new extraDamage = floatround(damage * get_cvar_float("joker_m249mult") - damage)
		shExtraDamage( id, attacker, extraDamage, "JOKER PARA!" )
	}
	return PLUGIN_CONTINUE
}
//---------------------------------------------------------------------------------------------
public joker_kd()
{

	// BASED ON -|-LoA-|-Bass's BUBBLE THROWER!
	new temp[6]
	if ( !hasRoundStarted() ) return PLUGIN_HANDLED

	// First Argument is an id with joker
	read_argv(1,temp,5)
	new id=str_to_num(temp)

	if ( !is_user_alive(id) ) return PLUGIN_HANDLED
	if ( !g_HasJokaPower[id] ) return PLUGIN_HANDLED
	if ( Entvars_Get_Int( id, EV_INT_waterlevel) != 0 ) {
		playSoundDenySelect(id)
		return PLUGIN_HANDLED
	}

	new fl_cost = get_cvar_num("joker_armorcost")
	new armr = get_user_armor(id)

	if(armr < fl_cost)
	{
		client_print(id,print_chat,"%s squirts cost %d armor points each", gHeroName, fl_cost)
		playSoundDenySelect(id)
		return PLUGIN_HANDLED
	}
	set_user_armor(id,armr - fl_cost)

	new vec[3]
	new aimvec[3]
	new velocityvec[3]
	new length
	new speed = 10
	get_user_origin(id,vec)
	get_user_origin(id,aimvec,2)
	new dist = get_distance(vec,aimvec)

	new speed1 = 160
	new speed2 = 350
	new radius = 105

	if(dist < 50)
	{
		radius = 0
		speed = 5
	}
	else if(dist < 150)
	{
		speed1 = speed2 = 1
		speed = 5
		radius = 50
	}
	else if(dist < 200)
	{
		speed1 = speed2 = 1
		speed = 5
		radius = 90
	}
	else if(dist < 250)
	{
		speed1 = speed2 = 90
		speed = 6
		radius = 90
	}
	else if(dist < 300)
	{
		speed1 = speed2 = 140
		speed = 7
	}
	else if(dist < 350)
	{
		speed1 = speed2 = 190
		speed = 7
	}
	else if(dist < 400)
	{
		speed1 = 150
		speed2 = 240
		speed = 8
	}
	else if(dist < 450)
	{
		speed1 = 150
		speed2 = 290
		speed = 8
	}
	else if(dist < 500)
	{
		speed1 = 180
		speed2 = 340
		speed = 9
	}

	velocityvec[0]=aimvec[0]-vec[0]
	velocityvec[1]=aimvec[1]-vec[1]
	velocityvec[2]=aimvec[2]-vec[2]
	length=sqrt(velocityvec[0]*velocityvec[0]+velocityvec[1]*velocityvec[1]+velocityvec[2]*velocityvec[2])
	velocityvec[0]=velocityvec[0]*speed/length
	velocityvec[1]=velocityvec[1]*speed/length
	velocityvec[2]=velocityvec[2]*speed/length

	new args[8]
	args[0] = vec[0]
	args[1] = vec[1]
	args[2] = vec[2]
	args[3] = velocityvec[0]
	args[4] = velocityvec[1]
	args[5] = velocityvec[2]
	set_task(0.1,"te_spray",0,args,8,"a",2)
	check_burnzone(id,vec,aimvec,speed1,speed2,radius)

	if ( !is_user_alive(id) ) return PLUGIN_HANDLED

	return PLUGIN_HANDLED
}
//----------------------------------------------------------------------------------------------
public te_spray(args[]){

	//TE_SPRAY
	message_begin(MSG_BROADCAST,SVC_TEMPENTITY)
	write_byte (120) // Throws a shower of sprites or models
	write_coord(args[0]) // start pos
	write_coord(args[1])
	write_coord(args[2])
	write_coord(args[3]) // velocity
	write_coord(args[4])
	write_coord(args[5])
	write_short (gSpriteBubble) // spr
	write_byte (8) // count
	write_byte (70) // speed
	write_byte (100) //(noise)
	write_byte (5) // (rendermode)
	message_end()

	return PLUGIN_CONTINUE
}
//----------------------------------------------------------------------------------------------
check_burnzone(id,vec[],aimvec[],speed1,speed2,radius)
{
	new tbody,tid
	get_user_aiming(id,tid,tbody,550)
	if(get_cvar_num("mp_friendlyfire") == 1)
	{
		if((tid > 0) && (tid < 33))
		burn_victim(tid,id)
	}
	else
	{
		if( ((tid > 0) && (tid < 33)) && (get_user_team(id) != get_user_team(tid)) )
		burn_victim(tid,id)
	}
	new burnvec1[3],burnvec2[3],length1

	burnvec1[0]=aimvec[0]-vec[0]
	burnvec1[1]=aimvec[1]-vec[1]
	burnvec1[2]=aimvec[2]-vec[2]

	length1=sqrt(burnvec1[0]*burnvec1[0]+burnvec1[1]*burnvec1[1]+burnvec1[2]*burnvec1[2])
	burnvec2[0]=burnvec1[0]*speed2/length1
	burnvec2[1]=burnvec1[1]*speed2/length1
	burnvec2[2]=burnvec1[2]*speed2/length1
	burnvec1[0]=burnvec1[0]*speed1/length1
	burnvec1[1]=burnvec1[1]*speed1/length1
	burnvec1[2]=burnvec1[2]*speed1/length1
	burnvec1[0] += vec[0]
	burnvec1[1] += vec[1]
	burnvec1[2] += vec[2]
	burnvec2[0] += vec[0]
	burnvec2[1] += vec[1]
	burnvec2[2] += vec[2]

	new origin[3]
	new maxplayers = SH_MAXSLOTS+1
	for (new i=1; i<=maxplayers; i++)
	{

		if( (is_user_alive(i) == 1) && (i != id) && ( get_cvar_num("mp_friendlyfire") == 1 || get_user_team(id)!=get_user_team(i) ) )
		{
			get_user_origin(i,origin)
			if(get_distance(origin,burnvec1) < radius)
			burn_victim(i,id)
			else if(get_distance(origin,burnvec2) < radius)
			burn_victim(i,id)

		}
	}
	return PLUGIN_CONTINUE
}
//----------------------------------------------------------------------------------------------
public burn_victim(id,killer)
{
	if(gIsBurning[id] == 1)
	return PLUGIN_CONTINUE
	gIsBurning[id] = 1

	//emit_sound(id, CHAN_ITEM, "misc/bubbles.wav", 1.0, ATTN_NORM, 0, PITCH_NORM)

	new args[3]
	// new hp = get_user_health(id)
	args[0] = id
	args[1] = killer
	set_task(0.3,"drowning",451,args,3,"a", get_cvar_num("joker_numbubbles") )
	set_task(0.7,"drown_scream",0,args,3)
	set_task(5.5,"stopFireSound",0,args,3)
	return PLUGIN_CONTINUE
}
//-------------------------------------------------------------------------------------------------------