/* Requested by GodLike29 */

#include <amxmodx>
#include <amxmisc> 
#include <Vexd_Utilities>
#include <superheromod>

#define PLUGIN "SuperHero Sasuke"
#define VERSION "1.0"
#define AUTHOR "Spider"

new gHeroName[]="Sasuke";
new bool:gHasPowers[SH_MAXSLOTS+1];
new bool:gSelected[SH_MAXSLOTS+1]
new gIsBurning[SH_MAXSLOTS+1];
new gSpriteSmoke, gSpriteFire, gSpriteBurning;

public plugin_init() {
	register_plugin(PLUGIN, VERSION, AUTHOR)
	register_cvar("sasuke_speed","900");
	register_cvar("sasuke_hp","1500");
	register_cvar("sasuke_armor","2000");
	register_cvar("sasuke_regenhp","50");
	register_cvar("sasuke_level","0");
	register_cvar("sasuke_adminflag","a");
	register_cvar("sasuke_cooldown","0.1");
	register_cvar("sasuke_burndmg","400");
	register_cvar("sasuke_numburns","60");
	
	register_event("ResetHUD","sasuke_res","be");
	register_event("DeathMsg", "sasuke_death", "a")
	
	shCreateHero(gHeroName, "GodLike Hero", "Speed, FireBall, HP, Armor, Regen", true, "sasuke_level" );
	
	register_srvcmd("sasuke_init", "sasuke_init");
	shRegHeroInit(gHeroName, "sasuke_init");
	
	register_srvcmd("sasuke_kd", "sasuke_kd");
	shRegKeyDown(gHeroName, "sasuke_kd");
	
	shSetMaxSpeed(gHeroName, "sasuke_speed","[0]");
	shSetMaxArmor(gHeroName, "sasuke_armor");
	shSetMaxHealth(gHeroName, "sasuke_hp");
}

public plugin_precache()
{
	gSpriteSmoke = precache_model("sprites/steam1.spr")
	gSpriteFire = precache_model("sprites/explode1.spr")
	gSpriteBurning = precache_model("sprites/xfire.spr")
	precache_sound("ambience/burning1.wav")
	precache_sound("ambience/flameburst1.wav")
	precache_sound("scientist/c1a0_sci_catscream.wav")
	precache_sound("vox/_period.wav")
	precache_sound("shmod/katun.wav")
}

public sasuke_init()
{
	//if(!cmd_access( id,level,cid,0) && (get_cvar_num("sasuke_adminonly") == 1))
	//	return PLUGIN_HANDLED;
	
	new temp[6];
	read_argv(1, temp, 5);
	
	new id = str_to_num(temp);
	read_argv(2,temp,5);
	new hasPowers = str_to_num(temp);
	gHasPowers[id] = (hasPowers != 0);
	
	gSelected[id] = gHasPowers[id];
	
	if (is_user_connected(id)) {
		if (hasPowers) {
			sasuke_admincheck(id);
		}
		else {
			shRemSpeedPower(id);
			shRemHealthPower(id);
			shRemArmorPower(id);
		}
	}
	
	set_task(1.0,"sasuke_loop",0,"",0,"b" );
	
	return PLUGIN_HANDLED;
}

public sasuke_res(id) { 
	gIsBurning[id] = 0;
	stopFireSound(id);
	sasuke_admincheck(id);
	if (gHasPowers[id])  {
		gPlayerUltimateUsed[id] = false;
	}
	
	return PLUGIN_CONTINUE;
}
public sasuke_death(id) {
	gIsBurning[id] = 0;
	stopFireSound(id);
	if ( gHasPowers[id] ) {
		gPlayerUltimateUsed[id] = false;
	}
	return PLUGIN_CONTINUE;
}

//START AFTERBURN SCRIPT ---> ALL CREDITS TO AFTERBURN AUTHOR!!!


public sasuke_kd() {
	new temp[6];
	read_argv(1,temp,5);
	new id=str_to_num(temp);
	if ( !is_user_alive(id) || !hasRoundStarted() || !gHasPowers[id] || get_user_team(id) < 1 || get_user_team(id) > 2) return PLUGIN_HANDLED;
	if ( Entvars_Get_Int( id, EV_INT_waterlevel ) == 3 ) {
		console_print(id,"[SH] You cannot use the Flame Thrower while underwater")
		playSoundDenySelect(id)
		return PLUGIN_HANDLED;
	}
	
	if ( gPlayerUltimateUsed[id] ) {
		playSoundDenySelect(id)
		return PLUGIN_HANDLED;
	}
	
	emit_sound(id, CHAN_WEAPON, "ambience/flameburst1.wav", 1.0, ATTN_NORM, 0, PITCH_NORM)
	emit_sound(id, CHAN_WEAPON, "shmod/katun.wav", 1.0, ATTN_NORM, 0, PITCH_NORM)
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
	
	if (dist < 50) {
		radius = 0
		speed = 5
	}
	else if (dist < 150) {
		speed1 = speed2 = 1
		speed = 5
		radius = 50
	}
	else if (dist < 200) {
		speed1 = speed2 = 1
		speed = 5
		radius = 90
	}
	else if (dist < 250) {
		speed1 = speed2 = 90
		speed = 6
		radius = 90
	}
	else if (dist < 300) {
		speed1 = speed2 = 140
		speed = 7
	}
	else if (dist < 350) {
		speed1 = speed2 = 190
		speed = 7
	}
	else if (dist < 400) {
		speed1 = 150
		speed2 = 240
		speed = 8
	}
	else if (dist < 450) {
		speed1 = 150
		speed2 = 290
		speed = 8
	}
	else if (dist < 500) {
		speed1 = 180
		speed2 = 340
		speed = 9
	}
	//Edited
	else if (dist < 1000) {
		speed1 = 200
		speed2 = 400
		speed = 18
		radius = 150
	}
	else if (dist > 1000) {
		speed1 = 300
		speed2 = 500
		speed = 35
		radius = 150
	}
	
	velocityvec[0] = aimvec[0] - vec[0]
	velocityvec[1] = aimvec[1] - vec[1]
	velocityvec[2] = aimvec[2] - vec[2]
	length = sqrt(velocityvec[0]*velocityvec[0] + velocityvec[1]*velocityvec[1] + velocityvec[2]*velocityvec[2])
	if (!length) length = 1
	velocityvec[0] = velocityvec[0]*speed / length
	velocityvec[1] = velocityvec[1]*speed / length
	velocityvec[2] = velocityvec[2]*speed / length
	
	new args[6]
	args[0] = vec[0]
	args[1] = vec[1]
	args[2] = vec[2]
	args[3] = velocityvec[0]
	args[4] = velocityvec[1]
	args[5] = velocityvec[2]
	set_task(0.1, "te_spray", 0, args, 6, "a", 2)
	check_burnzone(id, vec, aimvec, speed1, speed2, radius)
	
	if (get_cvar_float("sasuke_cooldown") > 0.0) ultimateTimer(id, get_cvar_float("sasuke_cooldown"))
	
	return PLUGIN_HANDLED;
}

public te_spray(args[])
{
	//TE_SPRAY
	message_begin(MSG_BROADCAST,SVC_TEMPENTITY)
	write_byte(120)		// Throws a shower of sprites or models
	write_coord(args[0])	// start pos
	write_coord(args[1])
	write_coord(args[2])
	write_coord(args[3])	// velocity
	write_coord(args[4])
	write_coord(args[5])
	write_short(gSpriteFire)	// spr
	write_byte(8)		// count
	write_byte(70)		// speed
	write_byte(100)	// (noise)
	write_byte(5)		// (rendermode)
	message_end()
}

check_burnzone(id, vec[], aimvec[], speed1, speed2, radius)
{
new tbody, tid
get_user_aiming(id, tid, tbody, 9999)

if (tid <= 0 || tid > SH_MAXSLOTS) return

if ( get_cvar_num("mp_friendlyfire") == 1 ) {
	burn_victim(tid, id)
}
else if ( get_user_team(id) != get_user_team(tid) ) {
	burn_victim(tid, id)
}

new burnvec1[3],burnvec2[3],length1

burnvec1[0] = aimvec[0]-vec[0]
burnvec1[1] = aimvec[1]-vec[1]
burnvec1[2] = aimvec[2]-vec[2]

length1 = sqrt(burnvec1[0]*burnvec1[0] + burnvec1[1]*burnvec1[1] + burnvec1[2]*burnvec1[2])
if (!length1) length1 = 1
burnvec2[0] = burnvec1[0]*speed2 / length1
burnvec2[1] = burnvec1[1]*speed2 / length1
burnvec2[2] = burnvec1[2]*speed2 / length1
burnvec1[0] = burnvec1[0]*speed1 / length1
burnvec1[1] = burnvec1[1]*speed1 / length1
burnvec1[2] = burnvec1[2]*speed1 / length1
burnvec1[0] += vec[0]
burnvec1[1] += vec[1]
burnvec1[2] += vec[2]
burnvec2[0] += vec[0]
burnvec2[1] += vec[1]
burnvec2[2] += vec[2]

new origin[3]
for (new i = 1; i <= SH_MAXSLOTS; i++){
	if ( is_user_alive(i) && i != id && ( get_cvar_num("mp_friendly_fire") || get_user_team(id) != get_user_team(i) ) ) {
		get_user_origin(i, origin)
		if ( get_distance(origin, burnvec1) < radius ) {
			burn_victim(i, id)
		}
		else if ( get_distance(origin, burnvec2) < radius ) {
			burn_victim(i, id)
		}
	}
}
}

public burn_victim(id, killer)
{
if ( Entvars_Get_Int( id, EV_INT_waterlevel ) == 3 ) return
if ( gIsBurning[id] ) return

gIsBurning[id] = 1

emit_sound(id, CHAN_ITEM, "ambience/burning1.wav", 1.0, ATTN_NORM, 0, PITCH_NORM)

new args[3]
args[0] = id
args[1] = killer
set_task(0.3, "on_fire", 451, args, 3, "a", get_cvar_num("sasuke_numburns"))
set_task(0.7, "fire_scream", 0, args, 3)
set_task(5.5, "stopFireSound", id)
}

public on_fire(args[])
{
new id = args[0]
new killer = args[1]

if( !is_user_connected(id) || !is_user_alive(id) ) {
	gIsBurning[id] = 0
	return
}
if( Entvars_Get_Int( id, EV_INT_waterlevel ) == 3 ) {
	gIsBurning[id] = 0
	return
}
if (!gIsBurning[id]) return

new rx, ry, rz, forigin[3]
rx = random_num(-30, 30)
ry = random_num(-30, 30)
rz = random_num(-30, 30)
get_user_origin(id, forigin)

//TE_SPRITE - additive sprite, plays 1 cycle
message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
write_byte(17)
write_coord(forigin[0]+rx)	// coord, coord, coord (position)
write_coord(forigin[1]+ry)
write_coord(forigin[2]+10+rz)
write_short(gSpriteBurning)	// short (sprite index)
write_byte(30)				// byte (scale in 0.1's)
write_byte(200)			// byte (brightness)
message_end()

//Smoke
message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
write_byte(5)
write_coord(forigin[0]+(rx*2))	// coord, coord, coord (position)
write_coord(forigin[1]+(ry*2))
write_coord(forigin[2]+100+(rz*2))
write_short(gSpriteSmoke)	// short (sprite index)
write_byte(60)				// byte (scale in 0.1's)
write_byte(15)				// byte (framerate)
message_end()

new health = get_user_health(id)
new damage = get_cvar_num("sasuke_burndmg")

//Prevents the shExtraDamage from saying you attacked a teammate for every cycle of the loop
if(health - damage  <= 0) {
	shExtraDamage(id, killer, damage, "Fire")
}
else {
	set_user_health(id, health - damage)
	
	//let them know who is hurting them with a flame
	new attackerName[32]
	get_user_name(killer, attackerName, 31)
	client_print(id, print_chat, "[SH]%s is burning you from beyond the grave", attackerName)
}
}

public fire_scream(args[])
{
emit_sound(args[0], CHAN_AUTO, "scientist/c1a0_sci_catscream.wav", 1.0, ATTN_NORM, 0, PITCH_NORM)
}

public stopFireSound(id)
{
new sndStop = (1<<5)
gIsBurning[id] = 0
emit_sound(id, CHAN_ITEM, "ambience/burning1.wav", 1.0, ATTN_NORM, sndStop, PITCH_NORM)
}

//END AFTERBURN SCRIPT

public sasuke_admincheck(id) {
new accessLevel[10];
get_cvar_string("sasuke_adminflag", accessLevel, 9);
//trim(accessLevel);
console_print(1,"%s",accessLevel);
if (accessLevel[0] != '0') {
	if (gSelected[id] && !(get_user_flags(id) & read_flags(accessLevel))) {
		client_print(id, print_chat, "[SH](%s) **Admin Only** You are not authorized to use this hero", gHeroName)
		gHasPowers[id] = false;
		client_cmd(id, "say drop %s", gHeroName);
		shRemSpeedPower(id);
		shRemHealthPower(id);
		shRemArmorPower(id);
	}
}
}

public sasuke_loop() {
new  players[SH_MAXSLOTS],pnum,id;
get_players(players,pnum,"a")
for (new i=0;i < pnum;i++) {
	id=players[i];
	if (gHasPowers[id]) {
		shAddHPs(id, get_cvar_num("sasuke_regenhp"), get_cvar_num("sasuke_hp"));
	}
}
}
