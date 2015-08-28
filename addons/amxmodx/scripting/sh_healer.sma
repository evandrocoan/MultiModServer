#include <amxmod>
#include <fun>
#include <superheromod>

/*Credit a AssKicR pour son hro Electro
Modification fait Par Slid13 


CVARS

healer_level 5
healer_cooldown 45
healer_searchtime 15
healer_health 100
healer_armor 100
healer_speed 300
healer_range 500

*/



new lightning
new gmsgDeathMsg
new bool:lightninghit[33]
new bool:issearching[33]



// VARIABLES
new gHeroName[]="Healer"
new bool:gHashealerPowers[SH_MAXSLOTS+1]
//----------------------------------------------------------------------------------------------
public plugin_init()
{
  // Plugin Info
  register_plugin("SUPERHERO healer","1.17.6","Slid13 & AssKicR & Zero")
 
  // FIRE THE EVENT TO CREATE THIS SUPERHERO!
  if ( isDebugOn() ) server_print("Attempting to create healer Hero")
  register_cvar("healer_level", "5" )
  shCreateHero(gHeroName, "Lightning regenerate", "Lightning that regenerate Multiple ally", true, "healer_level" )
  
  // REGISTER EVENTS THIS HERO WILL RESPOND TO! (AND SERVER COMMANDS)
  // INIT
  register_srvcmd("healer_init", "healer_init")
  shRegHeroInit(gHeroName, "healer_init")

  register_srvcmd("healer_kd", "healer_kd") 
  shRegKeyDown(gHeroName, "healer_kd") 

  register_event("ResetHUD","newRound","b")
  
  gmsgDeathMsg = get_user_msgid("DeathMsg")

  register_cvar("healer_cooldown", "45") 
  register_cvar("healer_searchtime", "15")
  register_cvar("healer_health", "100")
  register_cvar("healer_armor", "100")
  register_cvar("healer_speed", "300")
  register_cvar("healer_range", "500")

  shSetMaxHealth(gHeroName, "healer_health" )
  shSetMaxArmor(gHeroName, "healer_armor" )
  shSetMaxSpeed(gHeroName, "healer_speed", "[0]" )
  // DEFAULT THE CVARS
}
//----------------------------------------------------------------------------------------------
public healer_init()
{
new temp[6]
// First Argument is an id
read_argv(1,temp,5)
new id=str_to_num(temp)
  
// 2nd Argument is 0 or 1 depending on whether the id has healer skills
read_argv(2,temp,5)
new hasPowers=str_to_num(temp)

// Got to slow down a healer that lost his powers...
if ( !hasPowers )
shRemSpeedPower(id)
    
if ( hasPowers ) {
gHashealerPowers[id]=true
}else{
gHashealerPowers[id]=false
shRemHealthPower(id)
shRemSpeedPower(id)
shRemArmorPower(id)
}
}

public healer_kd() { 
if ( !hasRoundStarted() ) return PLUGIN_HANDLED 
new temp[6]
 
// First Argument is an id with healer Powers!
read_argv(1,temp,5)
new id=str_to_num(temp)
if ( !is_user_alive(id) ) return PLUGIN_HANDLED 
if ( !gHashealerPowers[id] ) return PLUGIN_HANDLED 
	
if ( gPlayerUltimateUsed[id] ) {
playSoundDenySelect(id)
return PLUGIN_HANDLED 
}
	
new parm[2]
parm[0]=id
parm[1]=get_cvar_num("healer_searchtime")
lightsearchtarget(parm)		// Chain Lightning
return PLUGIN_CONTINUE 
}

public lightsearchtarget(parm[2]){
new id = parm[0]
new p, body
get_user_aiming(id,p,body)
if ( 0<p<=32 && get_user_team(id)==get_user_team(p) ){
gPlayerUltimateUsed[id]=true
new linewidth = 80
new heal = 50
issearching[id]=false
lightningeffect(id,p,linewidth,heal,id)
new lightparm[4]
lightparm[0]=p
lightparm[1]=heal
lightparm[2]=linewidth
lightparm[3]=id
set_task(0.2,"lightningnext",24,lightparm,4)
ultimateTimer(id, get_cvar_num("healer_cooldown") * 1.0 )
}
else{
issearching[id]=true
gPlayerUltimateUsed[id]=true
new counter = parm[1]
while (counter >= 0){
counter -= 10
if (counter==0)
emit_sound(id,CHAN_ITEM, "turret/tu_ping.wav", 1.0, ATTN_NORM, 0, PITCH_NORM)
}
--parm[1]
if (parm[1]>0 && get_user_health(id)>=0) {
set_task(0.1,"lightsearchtarget",26,parm,2)
} else {
issearching[id]=false
gPlayerUltimateUsed[id]=false
}
}
return PLUGIN_CONTINUE
}

public lightningnext(parm[4]){		// Chain Lightning
new id=parm[0]
new caster=parm[3]
new origin[3]
get_user_origin(id, origin)
new players[32]
new numberofplayers
new teamname[32]
get_user_team(id, teamname, 31)
get_players(players, numberofplayers,"ae",teamname)
new i
new targetid = 0
new distancebetween = 0
new targetorigin[3]
new heal = parm[1]*2/3
new linewidth = parm[2]*2/3
new closestdistance = 0
new closestid = 0
for (i = 0; i < numberofplayers; ++i){
targetid=players[i]
if (get_user_team(id)==get_user_team(targetid) && is_user_alive(targetid)){
get_user_origin(targetid,targetorigin)
distancebetween=get_distance(origin,targetorigin)
if (distancebetween < get_cvar_num("healer_range") && !lightninghit[targetid] ){
if (distancebetween < closestdistance || closestid==0){
closestdistance = distancebetween
closestid = targetid
}
}
}
}
if (closestid){
lightningeffect(id,closestid,linewidth,heal,caster)
parm[0]=targetid
parm[1]=heal
parm[2]=linewidth
parm[3]=caster
set_task(0.2,"lightningnext",27,parm,4)
}
else{
for (i = 0; i < numberofplayers; ++i){
targetid=players[i]
lightninghit[targetid]=false
}
}
return PLUGIN_CONTINUE
}

public lightningeffect(id,targetid,linewidth,heal,caster){

new bool:targetdied
new bool:targetdead
lightninghit[targetid]=true
targetdead=false

if (is_user_alive(targetid))
targetdead=false
else
targetdead=true

if (get_user_health(targetid)>500){		// Evasion kill
if (get_user_health(targetid)+heal<=1024){
set_user_health(targetid, -1)
targetdied=true
}
}
else if (get_user_health(targetid)+heal<=0)
targetdied=true

set_user_health(targetid,get_user_health(targetid)+heal)
if (get_user_armor(targetid)+heal<=0)
set_user_armor(targetid,0)
else
set_user_armor(targetid,get_user_armor(targetid)+heal)

if (targetdied && !targetdead){
shAddXP(caster,targetid,1)
logKill(caster,targetid, "Chain Lightning")
set_user_frags(caster, get_user_frags(caster)+1)
set_user_frags(targetid, get_user_frags(targetid)+1)
message_begin( MSG_ALL, gmsgDeathMsg,{0,0,0},0)
write_byte(caster)
write_byte(targetid)
write_byte(0)
write_string("Chain Lightning")
message_end()
}

message_begin( MSG_BROADCAST, SVC_TEMPENTITY ); 
write_byte( 8 ) //TE_BEAMENTS 
write_short(id); // start entity 
write_short(targetid); // entity 
write_short(lightning ); // model 
write_byte( 0 ); // starting frame 
write_byte( 15 ); // frame rate 
write_byte( 10 ); // life 
write_byte( linewidth ); // line width 
write_byte( 10 ); // noise amplitude 
write_byte( 0 ); // r, g, b 
write_byte( 0 ); // r, g, b 
write_byte( 255 ); // r, g, b 
write_byte( 255 ); // brightness 
write_byte( 0 ); // scroll speed 
message_end(); 

new origin[3] 
get_user_origin(targetid,origin) 

message_begin( MSG_BROADCAST, SVC_TEMPENTITY ); 
write_byte( 28 ) //TE_ELIGHT 
write_short(targetid); // entity 
write_coord(origin[0]) // initial position 
write_coord(origin[1]) // initial position 
write_coord(origin[2]) // initial position 
write_coord(100) // radius 
write_byte( 0 ); // r, g, b 
write_byte( 0 ); // r, g, b 
write_byte( 255 ); // r, g, b 
write_byte( 15 ); // life 
write_coord(0) // decay rate 
message_end(); 

	

emit_sound(id,CHAN_ITEM, "weapons/gauss2.wav", 1.0, ATTN_NORM, 0, PITCH_NORM)

return PLUGIN_CONTINUE
}

public newRound(id)
{
gPlayerUltimateUsed[id]=false
return PLUGIN_CONTINUE
}

logKill(id, victim, const weaponDescription[32])
{
	new namea[32], namev[32], authida[32], authidv[32], teama[16], teamv[16]

	// Info On Attacker
	get_user_name(id, namea, charsmax(namea))
	get_user_team(id, teama, charsmax(teama))
	get_user_authid(id, authida, charsmax(authida))
	new auserid = get_user_userid(id)

	// Info On Victim
	get_user_name(victim, namev, charsmax(namev))
	get_user_team(victim, teamv, charsmax(teamv))
	get_user_authid(victim, authidv, charsmax(authidv))

	// Log This Kill
	if ( id != victim ) {
		log_message("^"%s<%d><%s><%s>^" killed ^"%s<%d><%s><%s>^" with ^"%s^"",
			namea, auserid, authida, teama, namev, get_user_userid(victim), authidv, teamv, weaponDescription)
	}
	else {
		log_message("^"%s<%d><%s><%s>^" committed suicide with ^"%s^"",
			namea, auserid, authida, teama, weaponDescription)
	}
}

public plugin_precache() {
precache_sound("turret/tu_ping.wav")
precache_sound("weapons/gauss2.wav")
lightning = precache_model("sprites/shmod/medic3.spr")
}
