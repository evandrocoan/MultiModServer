//BATTEAM! THE WHOLE BAT TEAM! 

/* CVARS - copy and paste to shconfig.cfg

//Bat Team
batteam_level 0
batteam_health 125		//defualt 125
batteam_armor 125			//defualt 125
batteam_gravity 0.40		//defualt 0.40
batteam_speed 375			//defualt 375
batteam_moveacc 650			//How quickly they can move while on the zipline
batteam_reelspeed 1000		//How fast hook line reels in
batteam_hookstyle 3			//1=spacedude, 2=spacedude auto reel (spiderman), 3=cheap kids real	(batteam)
batteam_hooksky 0			//0=no sky hooking 1=sky hooking allowed
batteam_teamcolored 1		//1=teamcolored zip lines 0=white zip lines
batteam_maxhooks -1			//Max ammout of hooks allowed (-1 is an unlimited ammount)
*/

#include <amxmod>
#include <Vexd_Utilities>
#include <superheromod>

#if !defined AMX_NEW
  #include <xtrafun>  //Only for the constants, doesn't use any functions
#endif

// GLOBAL VARIABLES
#define HOOKBEAMLIFE  100
#define HOOKBEAMPOINT 1
#define HOOKKILLBEAM  99
#define HOOK_DELTA_T  0.1  // units per second

#define CONTENTS_SKY -6

new gHeroName[]="Bat Team"
new gHasBatTeamPower[SH_MAXSLOTS+1]
new g_hookLocation[SH_MAXSLOTS+1][3]
new g_hookLength[SH_MAXSLOTS+1]
new bool:g_hooked[SH_MAXSLOTS+1]
new Float:g_hookCreated[SH_MAXSLOTS+1]
new g_hooksLeft[SH_MAXSLOTS+1]
new g_spriteWeb

#define giveTotal 24
new weapArray[giveTotal][24] = {
	"weapon_usp",
	"weapon_mac10",
	"weapon_ump45",
	"weapon_glock18",
	"weapon_elite",
	"weapon_mp5navy",
	"weapon_tmp",
	"weapon_deagle",
	"weapon_p228",
	"weapon_fiveseven",
	"weapon_p90",
	"weapon_xm1014",
	"weapon_ak47",
	"weapon_scout",
	"weapon_g3sg1",
	"weapon_sg552",
	"weapon_m4a1",
	"weapon_aug",
	"weapon_sg550",
	"weapon_awp",
	"weapon_m249",
	"weapon_hegrenade",
	"weapon_flashbang",
	"weapon_smokegrenade"
}
//----------------------------------------------------------------------------------------------
public plugin_init()
{
	// Plugin Info
	register_plugin("SUPERHERO Bat Team", "1.0", "bLiNd")

	// DEFAULT THE CVARS
	register_cvar("batteam_level", "0")
	register_cvar("batteam_health", "125")
	register_cvar("batteam_armor", "125")
	register_cvar("batteam_gravity", "0.40")
	register_cvar("batteam_speed", "375")
	register_cvar("batteam_moveacc", "650" )
	register_cvar("batteam_reelspeed", "1000" )
	register_cvar("batteam_hookstyle", "3" )
	register_cvar("batteam_hooksky", "0" )
	register_cvar("batteam_teamcolored", "1" )
	register_cvar("batteam_maxhooks", "-1" )

	// FIRE THE EVENT TO CREATE THIS SUPERHERO!
	shCreateHero(gHeroName, "Guns/HP/AP/Speed/Gravity And Hook", "Get All Of BatTeam's Powers!", true, "batteam_level" )

	// REGISTER EVENTS THIS HERO WILL RESPOND TO! (AND SERVER COMMANDS)
	// KEY UP
	register_srvcmd("batteam_ku", "batteam_ku")
	shRegKeyUp(gHeroName, "batteam_ku")

	// KEY DOWN
	register_srvcmd("batteam_kd", "batteam_kd")
	shRegKeyDown(gHeroName, "batteam_kd")

	// DEATH
	register_event("DeathMsg", "batteam_death", "a")  // Re-uses KeyUp!
	
	// INIT
	register_srvcmd("BatTeam_init", "BatTeam_init")
	shRegHeroInit(gHeroName, "BatTeam_init")

	//EVENTS
	register_event("ResetHUD", "newSpawn", "b")

	// Let Server know about Bat Team's Variables
	shSetMaxHealth(gHeroName, "batteam_health")
	shSetMaxArmor(gHeroName, "batteam_armor")
	shSetMinGravity(gHeroName, "batteam_gravity")
	shSetMaxSpeed(gHeroName, "batteam_speed", "[0]")
}
//----------------------------------------------------------------------------------------------
public plugin_precache()
{
	precache_sound("weapons/xbow_hit2.wav")
	g_spriteWeb = precache_model("sprites/zbeam4.spr")
}
//----------------------------------------------------------------------------------------------
public BatTeam_init()
{
	// First Argument is an id
	new temp[6]
	read_argv(1,temp,5)
	new id = str_to_num(temp)

	// 2nd Argument is 0 or 1 depending on whether the id has the hero	
	read_argv(2,temp,5)
	new hasPowers = str_to_num(temp)

	if ( hasPowers ) {
		BatTeam_giveweapons(id)
	}
	//This gets run if they had the power but don't anymore
	else if ( gHasBatTeamPower[id] ) {
		shRemHealthPower(id)
		shRemArmorPower(id)
		shRemGravityPower(id)
		shRemSpeedPower(id)
	}

	//Sets this variable to the current status
	gHasBatTeamPower[id] = (hasPowers != 0)
	
	gHasBatTeamPower[id] = (hasPowers != 0)
	if ( g_hooked[id] ) batteam_hookOff(id)
}
//----------------------------------------------------------------------------------------------
public newSpawn(id)
{
	g_hooksLeft[id] = get_cvar_num("batteam_maxhooks")
	if ( g_hooked[id] ) batteam_hookOff(id)
	
	if ( gHasBatTeamPower[id] && is_user_connected(id) && is_user_alive(id) ) {
		set_task(0.1, "BatTeam_giveweapons",id)
	}
}
//----------------------------------------------------------------------------------------------
public BatTeam_giveweapons(id)
{
	if ( !is_user_alive(id) ) return

	for (new x = 0; x < giveTotal; x++) {
		shGiveWeapon(id, weapArray[x])
	}

	// Give CTs a Defuse Kit
	if ( get_user_team(id) == 2 ) shGiveWeapon(id,"item_thighpack")
}
//----------------------------------------------------------------------------------------------
public batteam_kd()
{
	new temp[6]
	read_argv(1,temp,5)
	new id=str_to_num(temp)

	if ( g_hooked[id] || !is_user_alive(id) || !gHasBatTeamPower[id] || !hasRoundStarted() ) return

	if (PassAimTest(id)) batteam_hookOn(id)
}
//----------------------------------------------------------------------------------------------
public batteam_ku()
{
	new temp[10]
	read_argv(1,temp,9)
	new id=str_to_num(temp)

	if ( g_hooked[id] ) batteam_hookOff(id)
}
//----------------------------------------------------------------------------------------------
public batteam_death()
{
	new id=read_data(2)

	if ( g_hooked[id] ) batteam_hookOff(id)

	return PLUGIN_CONTINUE
}
//----------------------------------------------------------------------------------------------
PassAimTest(id) {
	new origin[3]
	new Float:Orig[3]
	get_user_origin(id, origin, 3)
	Orig[0]=float(origin[0])
	Orig[1]=float(origin[1])
	Orig[2]=float(origin[2])
	new AimAt = PointContents(Orig)
	if (AimAt == CONTENTS_SKY && !get_cvar_num("batteam_hooksky")) {
		client_print(id,print_chat,"[SH](BatTeam) You cannot hook to the sky")
		return false
	}
	return true
}
//----------------------------------------------------------------------------------------------
public batteam_checkWeb(parm[])
{
	new id=parm[0]
	new style=parm[1]

	if (style==1) batteam_physics(id, false)
	if (style==2) batteam_physics(id, true)
	if (style>2 || style < 0 ) batteam_cheapReel( id )
}
//----------------------------------------------------------------------------------------------
public batteam_physics(id, bool:autoReel)
{
	new user_origin[3], user_look[3], user_direction[3], move_direction[3]
	new A[3], D[3], buttonadjust[3]
	new acceleration, Float:vTowards_A, Float:DvTowards_A
	new Float:velocity[3], null[3], buttonpress

	if ( !g_hooked[id]  ) return

	if (!is_user_alive(id)) {
		batteam_hookOff(id)
		return
	}

	if ( g_hookCreated[id] + HOOKBEAMLIFE/10 <= get_gametime() ) {
		beamentpoint(id)
	}

	null[0] = 0
	null[1] = 0
	null[2] = 0

	get_user_origin(id, user_origin)
	get_user_origin(id, user_look,2)

	Entvars_Get_Vector(id, EV_VEC_velocity, velocity)

	buttonadjust[0]=0
	buttonadjust[1]=0

	buttonpress = Entvars_Get_Int(id, EV_INT_button)

	if (buttonpress&IN_FORWARD) {
		buttonadjust[0]+=1
	}
	if (buttonpress&IN_BACK) {
		buttonadjust[0]-=1
	}
	if (buttonpress&IN_MOVERIGHT) {
		buttonadjust[1]+=1
	}
	if (buttonpress&IN_MOVELEFT) {
		buttonadjust[1]-=1
	}
	if (buttonpress&IN_JUMP) {
		buttonadjust[2]+=1
	}
	if (buttonpress&IN_DUCK) {
		buttonadjust[2]-=1
	}

	if (buttonadjust[0] || buttonadjust[1]) {
		user_direction[0] = user_look[0] - user_origin[0]
		user_direction[1] = user_look[1] - user_origin[1]

		move_direction[0] = buttonadjust[0]*user_direction[0] + user_direction[1]*buttonadjust[1]
		move_direction[1] = buttonadjust[0]*user_direction[1] - user_direction[0]*buttonadjust[1]
		move_direction[2] = 0

		velocity[0] += move_direction[0] * get_cvar_float("batteam_moveacc") * HOOK_DELTA_T / get_distance(null,move_direction)
		velocity[1] += move_direction[1] * get_cvar_float("batteam_moveacc") * HOOK_DELTA_T / get_distance(null,move_direction)
	}
	if (buttonadjust[2] < 0 || (buttonadjust[2] && g_hookLength[id] >= 60)) {
		g_hookLength[id] -= floatround(buttonadjust[2] * get_cvar_float("batteam_reelspeed") * HOOK_DELTA_T)
	}
	else if (autoReel && !(buttonpress&IN_DUCK) && g_hookLength[id] >= 200) {
		buttonadjust[2] += 1
		g_hookLength[id] -= floatround(buttonadjust[2] * get_cvar_float("batteam_reelspeed") * HOOK_DELTA_T)
	}

	A[0] = g_hookLocation[id][0] - user_origin[0]
	A[1] = g_hookLocation[id][1] - user_origin[1]
	A[2] = g_hookLocation[id][2] - user_origin[2]

	D[0] = A[0]*A[2] / get_distance(null,A)
	D[1] = A[1]*A[2] / get_distance(null,A)
	D[2] = -(A[1]*A[1] + A[0]*A[0]) / get_distance(null,A)

	new aDistance = get_distance(null,D) ? get_distance(null,D) : 1
	acceleration = (-get_cvar_num("sv_gravity")) * D[2] / aDistance

	vTowards_A = (velocity[0] * A[0] + velocity[1] * A[1] + velocity[2] * A[2]) / get_distance(null,A)
	DvTowards_A = float((get_distance(user_origin,g_hookLocation[id]) - g_hookLength[id]) * 4)

	if (get_distance(null,D)>10) {
		velocity[0] += (acceleration * HOOK_DELTA_T * D[0]) / get_distance(null,D)
		velocity[1] += (acceleration * HOOK_DELTA_T * D[1]) / get_distance(null,D)
		velocity[2] += (acceleration * HOOK_DELTA_T * D[2]) / get_distance(null,D)
	}

	velocity[0] += ((DvTowards_A - vTowards_A) * A[0]) / get_distance(null,A)
	velocity[1] += ((DvTowards_A - vTowards_A) * A[1]) / get_distance(null,A)
	velocity[2] += ((DvTowards_A - vTowards_A) * A[2]) / get_distance(null,A)

	Entvars_Set_Vector(id, EV_VEC_velocity, velocity)
}
//----------------------------------------------------------------------------------------------
public batteam_cheapReel(id)
{
	// Cheat Web - just drags you where you shoot it...

	if ( !g_hooked[id] ) return

	new user_origin[3]
	new Float:velocity[3]

	if (!is_user_alive(id)) {
		batteam_hookOff(id)
		return
	}

	get_user_origin(id, user_origin)

	Entvars_Get_Vector(id, EV_VEC_velocity, velocity)

	new distance = get_distance( g_hookLocation[id], user_origin )
	if ( distance > 60 ) {
		velocity[0] = (g_hookLocation[id][0] - user_origin[0]) * ( 1.0 * get_cvar_num("batteam_reelspeed") / distance )
		velocity[1] = (g_hookLocation[id][1] - user_origin[1]) * ( 1.0 * get_cvar_num("batteam_reelspeed") / distance )
		velocity[2] = (g_hookLocation[id][2] - user_origin[2]) * ( 1.0 * get_cvar_num("batteam_reelspeed") / distance )
	}
	else {
		velocity[0] = 0.0
		velocity[1] = 0.0
		velocity[2] = 0.0
	}

	Entvars_Set_Vector(id, EV_VEC_velocity, velocity)
}
//----------------------------------------------------------------------------------------------
public batteam_hookOn(id)
{
	new parm[2], user_origin[3]
	parm[0] = id

	if ( !is_user_alive(id) ) return PLUGIN_HANDLED

	if ( g_hooksLeft[id]== 0 ) {
		playSoundDenySelect(id)
		return PLUGIN_HANDLED
	}

	if ( g_hooksLeft[id] > 0 ) g_hooksLeft[id]--

	if ( g_hooksLeft[id]>=0 && g_hooksLeft[id]<5 ) {
		client_print(id, print_center, "You have %d BatTeam hooks left", g_hooksLeft[id] )
	}

	g_hooked[id] = true
	set_user_info(id,"ROPE","1")
	get_user_origin(id, user_origin)
	get_user_origin(id, g_hookLocation[id], 3)
	g_hookLength[id] = get_distance(g_hookLocation[id],user_origin)
	set_user_gravity(id,0.001)
	beamentpoint(id)
	emit_sound(id, CHAN_STATIC, "weapons/xbow_hit2.wav", 1.0, ATTN_NORM, 0, PITCH_NORM)
	parm[1]=get_cvar_num("batteam_hookstyle")
	set_task(HOOK_DELTA_T, "batteam_checkWeb", id, parm, 2, "b")

	return PLUGIN_CONTINUE
}
//----------------------------------------------------------------------------------------------
public batteam_hookOff(id)
{
	g_hooked[id] = false
	set_user_info(id,"ROPE","0")
	killbeam(id)
	if ( is_user_connected(id) ) shSetGravityPower(id)
	remove_task(id)
}
//----------------------------------------------------------------------------------------------
public beamentpoint(id)
{
	message_begin( MSG_BROADCAST, SVC_TEMPENTITY )
	write_byte( HOOKBEAMPOINT )
	write_short( id )
	write_coord( g_hookLocation[id][0] )
	write_coord( g_hookLocation[id][1] )
	write_coord( g_hookLocation[id][2] )
	write_short( g_spriteWeb ) // sprite index
	write_byte( 0 )            // start frame
	write_byte( 0 )            // framerate
	write_byte( HOOKBEAMLIFE ) // life
	write_byte( 10 )           // width
	write_byte( 0 )            // noise
	if (!get_cvar_num("batteam_teamcolored")) {
		write_byte( 250 )     // r, g, b
		write_byte( 250 )       // r, g, b
		write_byte( 250 )       // r, g, b
	}
	// Terrorist
	else if (get_user_team(id)==1) {
		write_byte( 255 )     // r, g, b
		write_byte( 0 )       // r, g, b
		write_byte( 0 )       // r, g, b
	}
	// Counter-Terrorist
	else {
		write_byte( 0 )      // r, g, b
		write_byte( 0 )      // r, g, b
		write_byte( 255 )    // r, g, b
	}
	write_byte( 150 )          // brightness
	write_byte( 0 )            // speed
	message_end( )
	g_hookCreated[id] = get_gametime()
}
//----------------------------------------------------------------------------------------------
public killbeam(id)
{
	message_begin( MSG_BROADCAST, SVC_TEMPENTITY )
	write_byte( HOOKKILLBEAM )
	write_short( id )
	message_end()
}
//----------------------------------------------------------------------------------------------
public client_connect(id)
{
	gHasBatTeamPower[id] = false
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