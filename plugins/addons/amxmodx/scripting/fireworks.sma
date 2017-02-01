/**
07-11-04 , 01:55   Fireworks++ 3.0

3.0 uses simple entity think routines to gain an almost lagless, and almost entirely task-less method of doing things.

In additions, shooters have been completely fixed.

This plugin provides relatively lagless Voogru style fireworks, along with adding tons of customability and lagless features.

Basic Commands:
Notes: Putting a 0 for r g or b (or not putting it in) will make a random rocket, either with totally random colors, or solid colors, depending on a cvar.
A 0 for effects (or not putting it in) will render an "abcdz" rocket.

Spawn Commands:
firework <r> <g> [b] <effects>
firework_rc <r> <g> [b] <effects>
firework_rv <r> <g> [b] <effects>

Spawned fireworks glow the color they will become when fired, and bounce up and down every 5 seconds, so you remember they still exist.
The shockwave effect was just for kicks ^^

Fire Commands:
shoot_fireworks
Take note, executing shoot_fireworks when fireworks are already launched will detonate them.

So, you can spawn them, shoot them, then press it again to detonate.

A normal firework shoots straight up (with deviation by cvar)
A RC firework follows he laser dot, which spawns where your aiming
A RV firework is remote controlled by you, you ARE the firework.

Shooter Commands:
firework_shooter <shots> <time between shots> <r> <g> [b] <effects>

A shooter shoots fireworks at <time> intervals, for <shots>. You can define what fireworks you want it to shoot, or make it random.

say fireworks - Brings up the fireworks menu. The fireworks menu lets you quickly see how many fireworks you can fire, how many you HAVE fired, and lets you hit all the commands that were above.

CVARS:
(cvar name | example)

//Enabled/disables fireworks hierarchy. Look below for details
fireworks_enable	1

// Max amount of flares
fireworks_flare_count	30

// Max normal client fireworks
fireworks_maxcount	4

// Max admin fireworks
fireworks_amaxcount	16

// If 0, totally random fireworks. If 1, standard color fireworks
fireworks_colortype	0

// Multiplier for effects. Setting to high value may cause lag with some effects
fireworks_multiplier	2

// Changes the variation on the path of the rocket.
fireworks_xvelocity	100
fireworks_yvelocity	100

// The fireworks password
fireworks	tsx

FIREWORKS ADMIN SYSTEM:
fireworks_enable (1|0)

When fireworks_enable is 1, all players may fire rockets. The amount of rockets they can make is defined by their admin level. 

If they have admin level G or are an admin, they can fire based on the cvar: "fireworks_amaxcount"

If they do not, they can fire based on the cvar : "fireworks_maxcount"
They can also not fire shooters.

Turning either CVAR to 0 renders those type of users with no fireworks.

when fireworks_enable is 0, anyone with the fireworks password, defined by the cvar: "fireworks", can fire fireworks.

To input the password, if you are a client wanting to use fireworks, the command is :"fireworks_password <password"

That way, when fireworks_enable is 0, only the people who know the password can use fireworks.

NOTE: When fireworks_enable is 1, the password will not help anyone.

Remove Commands:
// Removes all of your fireworks
remove_fireworks

// Removes all of your shooters
remove_shooters

// ADMIN: removes ALL fireworks
amx_remove_fireworks

// ADMIN: Removes ALL fireworks
amx_remove_shooters

Well thats all the commands and cvars, here is the list of effects:

a: Voogru Fireworks Copy.
b: Flares
c. Falling Flares
d: Lightening
e: Dynamic lights
f: Flares flying upward
g: Throws Ents
h: Explosion
i: Particals
j: Blood field
k: ??
l: Sprite field 

s: old voogru effect
t: Smoke
u: Fiery Explosion
v: thunderclap
w,x,y,z: Explosion sounds

Have fun with the new, lagless, and effecient, Fireworks++

*/


#include <amxmodx> 
#include <amxmisc> 
#include <fakemeta>
#include <engine>

// Sprite Index
new ls_dot, fire, white, sprSmoke, sprLightning, sprBflare, sprRflare, sprGflare, sprTflare, sprOflare, sprPflare, sprYflare, garbgibs, flare3, sprFlare6, shockwave

// Has Sound Index
new has_rocket = 0, has_drop = 0

new player_fireworks[33] = 0;
new bool:allowed_fireworks[33] = false;

public check_fireworks(id,mode){
	new amount;
	if(get_cvar_num("fireworks_enable") == 0) {
		if(!allowed_fireworks[id]) return 0;
		return 1;
	}

	if(mode == 0) {
		if(!access(id,ADMIN_LEVEL_G)) return 0;
		return 1;
	}

	if(mode) {
		if(access(id,ADMIN_LEVEL_G)) amount = get_cvar_num("fireworks_amaxcount")
		else amount = get_cvar_num("fireworks_maxcount")
	
		if( (player_fireworks[id]) >= amount) return 0;
	}
	
	return amount;
}

public check_password(id){
	new arg[200],password[200]
	read_argv(1,arg,199)
	get_cvar_string("fireworks",password,199)
	trim(password)

	if(equali(arg,password,strlen(password))){
		allowed_fireworks[id] = true;
		client_print(id,print_chat,"[FIRE] Password Accepted")
	}
	else {
		allowed_fireworks[id] = false;
		client_print(id,print_chat,"[FIRE] Password Denied")
	}

	return PLUGIN_HANDLED;
}


public spawn_shooter(id){
	if(!check_fireworks(id,0)){
		client_print(id,print_chat,"[FIRE] You are not allowed to throw shooters.")
		return PLUGIN_HANDLED;
	}

	new arg[30]
	read_argv(1,arg,29)
	new shots = str_to_num(arg)
	if(!shots) shots = 5;

	read_argv(2,arg,29)
	new Float:time2 = floatstr(arg)
	if(time2 == 0.0) time2 = 5.0

	read_argv(3,arg,29)
	new r = str_to_num(arg)

	read_argv(4,arg,29)
	new g = str_to_num(arg)

	read_argv(5,arg,29)
	new b = str_to_num(arg)

	read_argv(6,arg,29)
	new type = read_flags(arg)
	if(!type ) format(arg,29,"abcdefsz")
	
	shooter_spawn(id,time2,shots,r,g,b,arg)
	
	return PLUGIN_HANDLED;
}

public shooter_spawn(id,Float:tasktime,shots,r,g,b,effects[]){
	new Float:Origin[3]

	pev(id,pev_origin,Origin)

	new Ent = create_entity("info_target") 
	if (!Ent) return PLUGIN_HANDLED;
	
	engfunc(EngFunc_SetOrigin,Ent,Origin)
	engfunc(EngFunc_SetModel,Ent,"models/w_rpgammo.mdl")
	entity_set_string(Ent,EV_SZ_target,effects)
	entity_set_string(Ent,EV_SZ_classname,"fireworks_shooter")
	set_pev(Ent,pev_owner,id)
	entity_set_int(Ent, EV_INT_movetype, MOVETYPE_TOSS) 

	entity_set_int(Ent,EV_INT_iuser1,shots)
	shots = entity_get_int(Ent,EV_INT_iuser1)
	set_pev(Ent,pev_iuser2,r)
	set_pev(Ent,pev_iuser3,g)
	set_pev(Ent,pev_iuser4,b)

	dllfunc(DLLFunc_Spawn,Ent)

	if (has_drop) emit_sound(Ent, CHAN_WEAPON, "fireworks/weapondrop1.wav", 1.0, ATTN_NORM, 0, PITCH_NORM)
	else emit_sound(Ent, CHAN_WEAPON, "items/weapondrop1.wav", 1.0, ATTN_NORM, 0, PITCH_NORM)

	set_task(tasktime,"shooter_think",Ent,"",0,"a",shots)

	return PLUGIN_HANDLED;
}

public shooter_think(id){
	new shots,r,g,b, effects[30], Float:origin[3]
	shots = entity_get_int(id,EV_INT_iuser1)
	pev(id,pev_iuser2,r)
	pev(id,pev_iuser3,g)
	pev(id,pev_iuser4,b)
	entity_get_string(id,EV_SZ_target,effects,29)

	pev(id,pev_origin,origin)
	origin[2] += 10
	touch_effect(origin,255,255,255)

	fireworks_spawn(id,"firework_normal",effects,r,g,b)
	shoot_firework(id)

	shots = shots - 1
	if(shots < 1) detonate_shooter(id)
	else set_pev(id,pev_iuser1,shots);

	return 1;
}
	
public detonate_shooter(id){
	explode(id)
	remove_entity(id)
	remove_task(id)

	return 1;
}

public spawn_firework(id){
	if(!check_fireworks(id,1)){
		client_print(id,print_chat,"[FIRE] You are not allowed to throw more fireworks.")
		return PLUGIN_HANDLED;
	}
	new arg[30],type2[30]

	read_argv(0,type2,29)
	if(equali(type2,"firework")) format(type2,29,"firework_normal");

	read_argv(1,arg,29)
	new r = str_to_num(arg)

	read_argv(2,arg,29)
	new g = str_to_num(arg)

	read_argv(3,arg,29)
	new b = str_to_num(arg)

	read_argv(4,arg,29)
	new type = read_flags(arg)
	if(!type ) format(arg,29,"abcdefsz")

	fireworks_spawn(id,type2,arg,r,g,b)
	
	return PLUGIN_HANDLED;
}

public fireworks_spawn(id,type[],effects[],r,g,b) {
	new Float:Origin[3]
	new Float:Angles[3]

	Angles[0] = 90.0
	Angles[1] = random_float(0.0,360.0)
	Angles[2] = 0.0

	pev(id,pev_origin,Origin)

	new Float:Mins[3] = {-4.0, -4.0, -1.0}
	new Float:Maxs[3] = {4.0, 4.0, 12.0}

	new Ent = create_entity("info_target") 
	if (!Ent) return PLUGIN_HANDLED;

	engfunc(EngFunc_SetOrigin,Ent,Origin)
	engfunc(EngFunc_SetSize,Ent,Mins,Maxs)
	engfunc(EngFunc_SetModel,Ent,"models/rpgrocket.mdl")

	entity_set_string(Ent,EV_SZ_classname,"nrm_fireworks")
	entity_set_string(Ent,EV_SZ_target,effects)
	entity_set_string(Ent,EV_SZ_targetname,type)
	set_pev(Ent,pev_angles,Angles)
	set_pev(Ent,pev_owner,id)
	set_pev(Ent,pev_solid,3)
	set_pev(Ent,pev_movetype,6)

	dllfunc(DLLFunc_Spawn,Ent)

	if(r != 0 || g != 0 || b != 0) client_cmd(id,"speak beep.wav")
	else if (get_cvar_num("fireworks_colortype")) {
		switch(random_num(0,6)) {
			case 0: r = 255
			case 1: g = 255
			case 2: b = 255
			case 3: 
			{
				g = 255
				b = 255
			}
			case 4:
			{
				r = 255
				b = 255
			}
			case 5: 
			{
				r = 255
				g = 255
			}
			case 6: 
			{
				r = 255
				g = 128
			}
		}
	} 
	else 
	{
		r = random_num(0,255)
		g = random_num(0,255)
		b = random_num(0,255)
	}
	set_rendering(Ent,kRenderFxGlowShell,r,g,b,kRenderNormal,20)
	set_pev(Ent,pev_iuser2,r)
	set_pev(Ent,pev_iuser3,g)
	set_pev(Ent,pev_iuser4,b)

	if (has_drop) emit_sound(Ent, CHAN_WEAPON, "fireworks/weapondrop1.wav", 1.0, ATTN_NORM, 0, PITCH_NORM)
	else emit_sound(Ent, CHAN_WEAPON, "items/weapondrop1.wav", 1.0, ATTN_NORM, 0, PITCH_NORM)

	entity_set_float(Ent,EV_FL_nextthink,halflife_time() + 5.0)
	if( (id < 33) && (id > -1) ) player_fireworks[id] += 1;

	return PLUGIN_HANDLED
}

public shoot_firework(id){
	detonate_fireworks(id,"firework_rc")
	detonate_fireworks(id,"firework_rv")
	detonate_fireworks(id,"firework_normal")
	fireworks_shoot(id,"nrm_fireworks")
	
	return PLUGIN_HANDLED;
}

public fireworks_shoot(id,class[]) {
	new ent = find_ent_by_owner(-1,class,id,0);
	if(!ent) return 0;

	while ( ent != 0 ) 
	{
		new tname[200]
		entity_get_string(ent,EV_SZ_targetname,tname,199)

		entity_set_string(ent,EV_SZ_classname,tname)
		set_pev(ent,pev_effects,64)

		emit_sound(ent, CHAN_WEAPON, "weapons/rocketfire1.wav", 1.0, ATTN_NORM, 0, PITCH_NORM)

		if (has_rocket) emit_sound(ent, CHAN_VOICE, "fireworks/rocket1.wav", 1.0, ATTN_NORM, 0, PITCH_NORM)
		else emit_sound(ent, CHAN_VOICE, "weapons/rocket1.wav", 1.0, ATTN_NORM, 0, PITCH_NORM)

		new r,g,b
		set_pev(ent,pev_iuser1,get_cvar_num("fireworks_maxlife"))
		r = pev(ent,pev_iuser2)
		g = pev(ent,pev_iuser3)
		b = pev(ent,pev_iuser4)
		set_pev(ent,pev_movetype,5)

		message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
		write_byte(22)
		write_short(ent)
		write_short(sprSmoke)
		write_byte(45)
		write_byte(4)
		write_byte(r)
		write_byte(g)
		write_byte(b)
		write_byte(255)
		message_end()

 		new Float:vVelocity[3]
		vVelocity[2] = random_float(400.0,1000.0)
		set_pev(ent,pev_velocity,vVelocity)

		entity_set_float(ent,EV_FL_nextthink,halflife_time() + 0.1)

		ent = find_ent_by_owner(ent, class, id, 0);
	}
	return PLUGIN_HANDLED
}

public detonate_fireworks(id,class[]) {
	new ent = find_ent_by_owner(-1,class,id,0);
	if(!ent) return 0;

	while ( ent != 0 ) 
	{
		explode(ent)
		if( (id < 33) && (id > 0) ) attach_view(id,id)
		new ent2 = find_ent_by_owner(ent, class, id, 0);
		remove_entity(ent)
		ent = ent2

	}
	return PLUGIN_HANDLED
}

public fireworks_think(id){
	new classname[32], owner
	owner = pev(id,pev_owner)
	entity_get_string(id,EV_SZ_classname,classname,31)
	if(equali(classname,"nrm_fireworks")){
		set_pev(id,pev_velocity,{0.0,0.0,450.0})
		entity_set_float(id,EV_FL_nextthink,halflife_time() + 5.0)
	}
	else if(equali(classname,"firework_normal")){
		new Float:velo[3]
		pev(id,pev_velocity,velo)

		new Float:x = get_cvar_float("fireworks_xvelocity")
		new Float:y = get_cvar_float("fireworks_yvelocity")
		velo[0] += random_float((-1.0*x),x)
		velo[1] += random_float((-1.0*y),y)
		velo[2] += random_float(10.0,200.0)
		set_pev(id,pev_velocity,velo)
		entity_set_float(id,EV_FL_nextthink,halflife_time() + 0.1)
	}
	else if(equali(classname,"firework_rc")){
	
		new Float:vOrigin[3]
		new aimvec[3], uorigin[3]
		entity_get_vector(id,EV_VEC_origin,vOrigin)
		get_user_origin(owner,aimvec,3)

		make_dot(aimvec)

		uorigin[0] = floatround(vOrigin[0])
		uorigin[1] = floatround(vOrigin[1])
		uorigin[2] = floatround(vOrigin[2])

		new velocityvec[3],length
		velocityvec[0]=aimvec[0]-uorigin[0] 
		velocityvec[1]=aimvec[1]-uorigin[1]
		velocityvec[2]=aimvec[2]-uorigin[2]

		length=sqrt(velocityvec[0]*velocityvec[0]+velocityvec[1]*velocityvec[1]+velocityvec[2]*velocityvec[2])
		velocityvec[0]=velocityvec[0]*1000/length 
		velocityvec[1]=velocityvec[1]*1000/length 
		velocityvec[2]=velocityvec[2]*1000/length 

		new Float:fl_iNewVelocity[3], iNewVelocity[3]
		iNewVelocity[0] = (velocityvec[0])
		iNewVelocity[1] = (velocityvec[1])
		iNewVelocity[2] = (velocityvec[2])

		fl_iNewVelocity[0] = iNewVelocity[0] + 0.0
		fl_iNewVelocity[1] = iNewVelocity[1] + 0.0
		fl_iNewVelocity[2] = iNewVelocity[2] + 0.0
		entity_set_vector(id, EV_VEC_velocity, fl_iNewVelocity)
		entity_set_float(id,EV_FL_nextthink,halflife_time() + 0.1)
		
	}
	else if(equali(classname,"firework_rv")){
		attach_view(owner,id)
		new Float:fl_iNewVelocity[3] 
		velocity_by_aim(owner, 750, fl_iNewVelocity)
		entity_set_vector(id, EV_VEC_velocity, fl_iNewVelocity)

		new Float:vAngles[3]
		entity_get_vector(owner, EV_VEC_v_angle, vAngles)
		entity_set_vector(id, EV_VEC_angles, vAngles)

		entity_set_float(id,EV_FL_nextthink,halflife_time() + 0.01)
	}
	return 1;
}

public fireworks_touch(tid,id){
	new classname[32]
	entity_get_string(id,EV_SZ_classname,classname,31)

	new Float:origin[3]
	pev(id,pev_origin,origin)

	new r = pev(id,pev_iuser2)
	new g = pev(id,pev_iuser3)
	new b = pev(id,pev_iuser4)

	if(equali(classname,"firework_normal")){
		explode(id)
		remove_entity(id)
	}
	else if(equali(classname,"firework_rc")){
		new owner
		owner = pev(id,pev_owner)
		attach_view(owner,owner)
		explode(id)
		remove_entity(id)
	}
	else if(equali(classname,"firework_rv")){
		new owner
		owner = pev(id,pev_owner)
		attach_view(owner,owner)
		explode(id)
		remove_entity(id)
	}
	else if(equali(classname,"nrm_fireworks")) emit_sound(id,CHAN_ITEM, "fvox/bell.wav", 1.0, ATTN_NORM, 0, PITCH_NORM)

	touch_effect(origin,r,g,b)
	return 1;
}

public touch_effect(Float:Origin[3],r,g,b){
	// blast circles
	new origin[3];
	origin[0] = floatround(Origin[0])
	origin[1] = floatround(Origin[1])
	origin[2] = floatround(Origin[2])

	message_begin( MSG_PAS, SVC_TEMPENTITY, origin );
	write_byte( 21 );
	write_coord( origin[0]);
	write_coord( origin[1]);
	write_coord( origin[2] + 16);
	write_coord( origin[0]);
	write_coord( origin[1]);
	write_coord( origin[2] + 16 + 348); // reach damage radius over .3 seconds
	write_short( shockwave );

	write_byte( 0 ); // startframe
	write_byte( 0 ); // framerate
	write_byte( 3 ); // life
	write_byte( 30 );  // width
	write_byte( 0 );   // noise

	write_byte(r)
	write_byte(g)
	write_byte(b)

	write_byte( 255 ); //brightness
	write_byte( 0 );		// speed
	message_end();

	message_begin( MSG_PAS, SVC_TEMPENTITY, origin );
	write_byte( 21 );
	write_coord( origin[0]);
	write_coord( origin[1]);
	write_coord( origin[2] + 16);
	write_coord( origin[0]);
	write_coord( origin[1]);
	write_coord( origin[2] + 16 + ( 384 / 2 )); // reach damage radius over .3 seconds
	write_short( shockwave );

	write_byte( 0 ); // startframe
	write_byte( 0 ); // framerate
	write_byte( 3 ); // life
	write_byte( 30 );  // width
	write_byte( 0 );   // noise

	write_byte(256-r)
	write_byte(256-g)
	write_byte(256-b)
		
	write_byte( 255 ); //brightness
	write_byte( 0 );		// speed
	message_end();


	return 1;
}

// Explode Function
public explode(id) {
	if(!id) return 0;
	new Float:ent_origin2[3]
	pev(id,pev_origin,ent_origin2)

	new owner
	owner = pev(id,pev_owner)
	if( (owner < 33) && (owner > -1) ) player_fireworks[owner]--
	
	new ent_origin[3];
	new multi = get_cvar_num("fireworks_multiplier")
	for(new i; i < 3; i++) ent_origin[i] = floatround(ent_origin2[i])

	new szType[64],type
	entity_get_string(id,EV_SZ_target,szType,63)
	type = read_flags(szType)

	new r = pev(id,pev_iuser2)
	new g = pev(id,pev_iuser3)
	new b = pev(id,pev_iuser4)

	if (type&(1<<0)) { //a -- Voogru Effect
		message_begin(MSG_BROADCAST,SVC_TEMPENTITY)
		write_byte(20) 				// TE_BEAMDISK
		write_coord(ent_origin[0])			// coord coord coord (center position)
		write_coord(ent_origin[1])
		write_coord(ent_origin[2])
		write_coord(0)			// coord coord coord (axis and radius)
		write_coord(0)
		write_coord(100)
		switch(random_num(0,1)) {
			case 0: write_short(sprFlare6)			// short (sprite index)
			case 1: write_short(sprLightning)			// short (sprite index)
		}
		write_byte(0)				// byte (starting frame)
		write_byte(0)				// byte (frame rate in 0.1's)
		write_byte(50)				// byte (life in 0.1's)
		write_byte(0)				// byte (line width in 0.1's)
		write_byte(150)				// byte (noise amplitude in 0.01's)
		write_byte(r)				// byte,byte,byte (color)
		write_byte(g)
		write_byte(b)
		write_byte(255)				// byte (brightness)
		write_byte(0)				// byte (scroll speed in 0.1's)
		message_end()
	}
	if (type&(1<<1)){ //b -- Flares
		if (get_cvar_num("fireworks_colortype")) {
			message_begin(MSG_BROADCAST,SVC_TEMPENTITY)
			write_byte(15)				// TE_SPRITETRAIL
			write_coord(ent_origin[0])			// coord, coord, coord (start)
			write_coord(ent_origin[1])
			write_coord(ent_origin[2]-20)
			write_coord(ent_origin[0])			// coord, coord, coord (end)
			write_coord(ent_origin[1])
			write_coord(ent_origin[2]+20)
			if ((r > 128) && (g < 127) && (b < 127)) write_short(sprRflare)
			else if ((r < 127) && (g > 128) && (b < 127)) write_short(sprGflare)
			else if ((r < 127) && (g < 127) && (b > 128)) write_short(sprBflare)
			else if ((r < 127) && (g > 128) && (b > 128)) write_short(sprTflare)
			else if ((r > 128) && (g < 127) && (b < 200) && (b > 100)) write_short(sprPflare)
			else if ((r > 128) && (g > 128) && (b < 127)) write_short(sprYflare)
			else if ((r > 128) && (g > 100) && (g < 200) && (b < 127))write_short(sprOflare)

			else write_short(sprBflare)
			write_byte(get_cvar_num("fireworks_flare_count"))				// byte (count)
			write_byte(10)				// byte (life in 0.1's)
			write_byte(10)				// byte (scale in 0.1's)
			write_byte(random_num(40,100))		// byte (velocity along vector in 10's)
			write_byte(40)				// byte (randomness of velocity in 10's)
			message_end()
		}else{
			message_begin(MSG_BROADCAST,SVC_TEMPENTITY)
			write_byte(15)				// TE_SPRITETRAIL
			write_coord(ent_origin[0])			// coord, coord, coord (start)
			write_coord(ent_origin[1])
			write_coord(ent_origin[2]-20)
			write_coord(ent_origin[0])			// coord, coord, coord (end)
			write_coord(ent_origin[1])
			write_coord(ent_origin[2]+20)
			if ((r > 128) && (g < 127) && (b < 127)) write_short(sprRflare)
			else if ((r < 127) && (g > 128) && (b < 127)) write_short(sprGflare)
			else if ((r < 127) && (g < 127) && (b > 128)) write_short(sprBflare)
			else if ((r < 127) && (g > 128) && (b > 128)) write_short(sprTflare)
			else if ((r > 128) && (g < 127) && (b < 200) && (b > 100)) write_short(sprPflare)
			else if ((r > 128) && (g > 128) && (b < 127)) write_short(sprYflare)
			else if ((r > 128) && (g > 100) && (g < 200) && (b < 127))write_short(sprOflare)
			else write_short(sprBflare)

			write_byte(get_cvar_num("fireworks_flare_count"))				// byte (count)
			write_byte(2)				// byte (life in 0.1's)
			write_byte(5)				// byte (scale in 0.1's)
			write_byte(random_num(40,100))		// byte (velocity along vector in 10's)
			write_byte(40)				// byte (randomness of velocity in 10's)
			message_end()
		}
	}
	if (type&(1<<2)) { //c -- Falling flares
		new velo = random_num(30,70)
		new spr
		new choosespr = random_num(0,3) 

		switch(choosespr)
		{
			case 0: spr = flare3
			case 1: spr = sprBflare
			case 2: spr = sprFlare6
			case 3: spr = sprRflare	
		}

		//TE_SPRITETRAIL
		message_begin(MSG_BROADCAST,SVC_TEMPENTITY)
		write_byte (15)	// line of moving glow sprites with gravity, fadeout, and collisions
		write_coord(ent_origin[0])			// coord, coord, coord (start)
		write_coord(ent_origin[1])
		write_coord(ent_origin[2])
		write_coord(ent_origin[0])			// coord, coord, coord (start)
		write_coord(ent_origin[1])
		write_coord(ent_origin[2]-80)
		write_short(spr) // (sprite index)
		write_byte(50*multi) // (count)
		write_byte(random_num(1,3)) // (life in 0.1's) 
		write_byte(10) // byte (scale in 0.1's) 
		write_byte(velo) // (velocity along vector in 10's)
		write_byte(40) // (randomness of velocity in 10's)

		message_end()
	}
	if (type&(1<<3)) { //d - lightening
		//Lightning 
		message_begin( MSG_BROADCAST,SVC_TEMPENTITY) 
		write_byte( 0 ) 
		write_coord(ent_origin[0])			// coord, coord, coord (start)
		write_coord(ent_origin[1])
		write_coord(ent_origin[2]-50)
		write_coord(ent_origin[0])			// coord, coord, coord (End)
		write_coord(ent_origin[1])
		write_coord((ent_origin[2]-2000))
		write_short( sprLightning ) 
		write_byte( 1 ) // framestart 
		write_byte( 5 ) // framerate 
		write_byte( 3 ) // life 
		write_byte( 150*multi ) // width 
		write_byte( 30 ) // noise 
		write_byte( 200 ) // r, g, b 
		write_byte( 200 ) // r, g, b 
		write_byte( 200 ) // r, g, b 
		write_byte( 200 ) // brightness 
		write_byte( 100 ) // speed 
		message_end() 

		//Sparks 
		message_begin( MSG_PVS, SVC_TEMPENTITY) 
		write_byte( 9 ) 
		write_coord(ent_origin[0])			// coord, coord, coord (start)
		write_coord(ent_origin[1])
		write_coord((ent_origin[2]-1000))
		message_end() 	
	}
	if (type&(1<<4)) { //e -- Lights
		message_begin(MSG_BROADCAST,SVC_TEMPENTITY)
		write_byte(27)
		write_coord(ent_origin[0])			// coord, coord, coord (start)
		write_coord(ent_origin[1])
		write_coord(ent_origin[2])
		write_byte(60)			// byte (radius in 10's) 
		write_byte(r)			// byte byte byte (color)
		write_byte(g)
		write_byte(b)
		write_byte(100)			// byte (life in 10's)
		write_byte(15)			// byte (decay rate in 10's)
		message_end()
	}
	if (type&(1<<5)) { //f -- Effect upward
		message_begin(MSG_BROADCAST, SVC_TEMPENTITY);
		write_byte( 100 );
		write_coord( ent_origin[0] );
		write_coord( ent_origin[1] );
		write_coord( ent_origin[2] - 64);
		write_short(sprFlare6);
		write_short(1);
		message_end();
	}
	if (type&(1<<6)) { //g -- Throw ents
		new velo = random_num(300,700)

		//define TE_EXPLODEMODEL
		message_begin(MSG_BROADCAST,SVC_TEMPENTITY)
		write_byte(107) // spherical shower of models, picks from set
		write_coord(ent_origin[0])			// coord, coord, coord (start)
		write_coord(ent_origin[1])
		write_coord(ent_origin[2]-50)
		write_coord(velo) //(velocity)
		write_short (garbgibs) //(model index)
		write_short (25*multi) // (count)
		write_byte (15) // (life in 0.1's)		
		message_end()
	}
	if (type&(1<<7)) { //h
		//TE_TAREXPLOSION
		message_begin(MSG_BROADCAST,SVC_TEMPENTITY)
		write_byte( 4) // Quake1 "tarbaby" explosion with sound
		write_coord(ent_origin[0])			// coord, coord, coord (start)
		write_coord(ent_origin[1])
		write_coord((ent_origin[2]-40))
		message_end()
	}
	if (type&(1<<8)) { //i
		new color = random_num(0,255)
		new width = random_num(400,1000)
		//TE_PARTICLEBURST
		message_begin(MSG_BROADCAST,SVC_TEMPENTITY)
		write_byte(122) // very similar to lavasplash.
		write_coord(ent_origin[0])			// coord, coord, coord (start)
		write_coord(ent_origin[1])
		write_coord(ent_origin[2])
		write_short (width)
		write_byte (color) // (particle color)
		write_byte (40) // (duration * 10) (will be randomized a bit)
		message_end()
	}
	if (type&(1<<9)) { //j...for random...blood
		message_begin( MSG_BROADCAST,SVC_TEMPENTITY) 
		write_byte( 10 ) 
		write_coord(ent_origin[0])			// coord, coord, coord (start)
		write_coord(ent_origin[1])
		write_coord(ent_origin[2])
		message_end() 
	}
	if (type&(1<<10)) { //k
		message_begin(MSG_BROADCAST,SVC_TEMPENTITY)
		write_byte(14)
		write_coord(ent_origin[0])
		write_coord(ent_origin[1])
		write_coord((ent_origin[2]-100))
		write_byte(5000) // radius
		write_byte(80)
		write_byte(20)
		message_end()
	}
	if (type&(1<<11))  { //l Sprite field
		message_begin(MSG_BROADCAST,SVC_TEMPENTITY)
		write_byte(123);
		write_coord(ent_origin[0])			// coord, coord, coord (start)
		write_coord(ent_origin[1])
		write_coord(ent_origin[2])
		write_short(256);
		if ((r > 128) && (g < 127) && (b < 127)) write_short(sprRflare)
		else if ((r < 127) && (g > 128) && (b < 127)) write_short(sprGflare)
		else if ((r < 127) && (g < 127) && (b > 128)) write_short(sprBflare)
		else if ((r < 127) && (g > 128) && (b > 128)) write_short(sprTflare)
		else if ((r > 128) && (g < 127) && (b < 200) && (b > 100)) write_short(sprPflare)
		else if ((r > 128) && (g > 128) && (b < 127)) write_short(sprYflare)
		else if ((r > 128) && (g > 100) && (g < 200) && (b < 127))write_short(sprOflare)
		else write_short(sprBflare)
		write_byte(10);
		write_byte(1);
		write_byte(20);
		message_end()
	}
	if (type&(1<<18)) { //s
		message_begin(MSG_BROADCAST,SVC_TEMPENTITY)
		write_byte(20) 				// TE_BEAMDISK
		write_coord(ent_origin[0])			// coord coord coord (center position)
		write_coord(ent_origin[1])
		write_coord(ent_origin[2])
		write_coord(ent_origin[0])			// coord coord coord (axis and radius)
		write_coord(ent_origin[1])
		write_coord(ent_origin[2]+random_num(250,750))
		switch(random_num(0,1)) {
			case 0: write_short(sprFlare6)			// short (sprite index)
			case 1: write_short(sprLightning)			// short (sprite index)
		}
		write_byte(0)				// byte (starting frame)
		write_byte(0)				// byte (frame rate in 0.1's)
		write_byte(25)				// byte (life in 0.1's)
		write_byte(150)				// byte (line width in 0.1's)
		write_byte(0)				// byte (noise amplitude in 0.01's)
		write_byte(r)				// byte,byte,byte (color)
		write_byte(g)
		write_byte(b)
		write_byte(255)				// byte (brightness)
		write_byte(0)				// byte (scroll speed in 0.1's)
		message_end()
	}
	if (type&(1<<19)) { //t
		message_begin( MSG_BROADCAST, SVC_TEMPENTITY )
		write_byte( 17 )
		write_coord( ent_origin[0] )
		write_coord( ent_origin[1] )
		write_coord( ent_origin[2] )
		write_short( sprSmoke )
		write_byte( 10 )
		write_byte( 150 )
		message_end( )
	}
	if (type&(1<<20)) { //u
		message_begin( MSG_BROADCAST,SVC_TEMPENTITY) 
		write_byte( 21 ) 
		write_coord(ent_origin[0])			// coord, coord, coord (start)
		write_coord(ent_origin[1])
		write_coord(ent_origin[2]-70)
		write_coord(ent_origin[0])			// coord, coord, coord (start)
		write_coord(ent_origin[1])
		write_coord(ent_origin[2]+136)
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
		write_coord(ent_origin[0])			// coord, coord, coord (start)
		write_coord(ent_origin[1])
		write_coord(ent_origin[2])
		write_byte( 188 ) // byte (scale in 0.1's) 188 
		write_byte( 10 ) // byte (framerate) 
		message_end() 

		//TE_Explosion 
		message_begin( MSG_BROADCAST,SVC_TEMPENTITY) 
		write_byte( 3 ) 
		write_coord(ent_origin[0])			// coord, coord, coord (start)
		write_coord(ent_origin[1])
		write_coord(ent_origin[2])
		write_short( fire ) 
		write_byte( 60 ) // byte (scale in 0.1's) 188 
		write_byte( 10 ) // byte (framerate) 
		write_byte( 0 ) // byte flags 
		message_end() 

		//Smoke 
		message_begin( MSG_BROADCAST,SVC_TEMPENTITY) 
		write_byte( 5 ) // 5 
		write_coord(ent_origin[0])			// coord, coord, coord (start)
		write_coord(ent_origin[1])
		write_coord(ent_origin[2])
		write_short( sprSmoke ) 
		write_byte( 10 ) // 2 
		write_byte( 10 ) // 10 
		message_end() 
	}

	if (type&(1<<21)) emit_sound(id,CHAN_ITEM, "ambience/thunder_clap.wav", 1.0, ATTN_NORM, 0, PITCH_NORM)//v
	if (type&(1<<22)) emit_sound(id, CHAN_VOICE, "weapons/explode3.wav", 1.0, ATTN_NORM, 0, PITCH_NORM) // w
	if (type&(1<<23)) emit_sound(id, CHAN_VOICE, "weapons/explode4.wav", 1.0, ATTN_NORM, 0, PITCH_NORM) //x
	if (type&(1<<24)) emit_sound(id, CHAN_VOICE, "weapons/explode5.wav", 1.0, ATTN_NORM, 0, PITCH_NORM) //y
	if (type&(1<<25)) emit_sound(id, CHAN_VOICE, "weapons/mortarhit.wav", 1.0, ATTN_NORM, 0, PITCH_NORM) //z

	return 1;
}

public remove_fireworks(id){
	player_fireworks[id] = 0;
	remove_by_class(id,"nrm_fireworks")
	remove_by_class(id,"firework_normal")
	remove_by_class(id,"firework_rv")
	remove_by_class(id,"firework_rc")

	return PLUGIN_HANDLED;
}

public remove_shooters(id){
	remove_by_class(id,"fireworks_shooter")
	return PLUGIN_HANDLED;
}

public amx_remove_fireworks(id){
	if(!access(id,ADMIN_LEVEL_G)) return 0;
	remove_entity_name("nrm_fireworks")
	remove_entity_name("firework_normal")
	remove_entity_name("firework_rv")
	remove_entity_name("firework_rc")
	for(new i=0; i < 33; i++) player_fireworks[i] = 0;

	return PLUGIN_HANDLED;
}

public amx_remove_shooters(id){
	if(!access(id,ADMIN_LEVEL_G)) return 0;
	remove_entity_name("fireworks_shooter")
	return PLUGIN_HANDLED;
}

public remove_by_class(id,class[]){
	new ent = find_ent_by_owner(-1,class,id,0);
	if(!ent) return 0;

	while ( ent != 0 ) 
	{
		new ent2 = find_ent_by_owner(ent, class, id, 0);
		remove_task(ent)
		remove_entity(ent)
		ent = ent2

	}
	return 1;
}

public sqrt(num) 
{ 
	// Cool - Newton's Method - Ludwig 
	new div = num, result = 1 
	while (div > result) 
	{  // end when div == result, or just below 
		div = (div + result) / 2 // take mean value as new divisor 
		result = num / div 
	} 
	return div 
} 

public make_dot(vec[])
{
	message_begin( MSG_BROADCAST,SVC_TEMPENTITY)  
	write_byte( 17 ) 
	write_coord(vec[0]) 
	write_coord(vec[1]) 
	write_coord(vec[2])
	write_short( ls_dot ) 
	write_byte( 10 ) 
	write_byte( 255 ) 
	message_end()
}

public plugin_precache() {
	precache_sound("weapons/explode3.wav")	
	precache_sound("weapons/explode4.wav")
	precache_sound("weapons/explode5.wav")

	precache_sound("weapons/rocketfire1.wav")
	precache_sound("weapons/mortarhit.wav")
	precache_sound( "ambience/thunder_clap.wav")

	flare3 = precache_model("sprites/flare3.spr")
	garbgibs = precache_model("models/garbagegibs.mdl")
	//l_tube = precache_model("models/w_flare.mdl")

	if (file_exists("sound/fireworks/rocket1.wav")) {
		precache_sound("fireworks/rocket1.wav")
		has_rocket = 1
	} else {
		precache_sound("weapons/rocket1.wav")
		has_rocket = 0
	}

	if (file_exists("sound/fireworks/weapondrop1.wav")) {
		precache_sound("fireworks/weapondrop1.wav")
		has_drop = 1
	} else {
		precache_sound("items/weapondrop1.wav")
		has_drop = 0
	}

	precache_model("models/rpgrocket.mdl")
	precache_model("models/w_rpgammo.mdl")

	sprSmoke = precache_model("sprites/smoke.spr")
	sprFlare6 = precache_model("sprites/Flare6.spr")
	sprLightning = precache_model("sprites/lgtning.spr")
	white = precache_model("sprites/white.spr") 
	fire = precache_model("sprites/explode1.spr") 

	sprBflare = precache_model("sprites/fireworks/bflare.spr")
	sprRflare = precache_model("sprites/fireworks/rflare.spr")
	sprGflare = precache_model("sprites/fireworks/gflare.spr")
	sprTflare = precache_model("sprites/fireworks/tflare.spr")
	sprOflare = precache_model("sprites/fireworks/oflare.spr")
	sprPflare = precache_model("sprites/fireworks/pflare.spr")
	sprYflare = precache_model("sprites/fireworks/yflare.spr")
	ls_dot = precache_model("sprites/laserdot.spr")

	precache_sound("fvox/bell.wav");
	shockwave = precache_model("sprites/shockwave.spr")

	return PLUGIN_CONTINUE
}


public fireworks_menu(id) {
	new amount;
	if(check_fireworks(id,1) == 0){
		shoot_firework(id) 
		client_print(id,print_chat,"[FIRE] You are not allowed to use the menu.")
		return PLUGIN_HANDLED;
	}		

	if(access(id,ADMIN_LEVEL_G)) amount = get_cvar_num("fireworks_amaxcount")
	else amount = get_cvar_num("fireworks_maxcount")

	new menu[1024]
	format(menu,sizeof(menu),"Fireworks Menu: (%i of %i)^n^n",player_fireworks[id],amount)
	add(menu,sizeof(menu),"1. Spawn Normal Rocket^n")
	add(menu,sizeof(menu),"2. Spawn Laser Guided Rocket^n")
	add(menu,sizeof(menu),"3. Spawn Remote View Rocket^n^n")
	add(menu,sizeof(menu),"4. Fire Rockets^n")
	add(menu,sizeof(menu),"5. Spawn Shooter^n^n")
	add(menu,sizeof(menu),"6. Remove All Your Rockets^n")
	add(menu,sizeof(menu),"7. Remove All Your Shooters^n^n")
	add(menu,sizeof(menu),"0. Cancel^n")

	show_menu(id,1023,menu)

	return PLUGIN_HANDLED;
}

public fireworks_keys(id,key){
	switch(key){
		case 0: fireworks_spawn(id,"firework_normal","abcdefsz",0,0,0)
		case 1: fireworks_spawn(id,"firework_rc","abcdefsz",0,0,0)
		case 2: fireworks_spawn(id,"firework_rv","abcdefsz",0,0,0)
		case 3: shoot_firework(id) 
		case 4:
		{
			if(check_fireworks(id,0)) shooter_spawn(id,5.0,5,0,0,0,"abcdz")
			else {
				client_print(id,print_chat,"[FIRE] You cannot spawn shooters")
				return 0;
			}
		}
		case 5: remove_fireworks(id);
		case 6: remove_shooters(id);
		case 7: return 0;
		case 8: return 0;
		case 9: return 0;

	}
	fireworks_menu(id)
	return PLUGIN_HANDLED;
}
	

public client_connect(id){
	player_fireworks[id] = 0;
	allowed_fireworks[id] = false;
}

public client_putinserver(id) if (!is_user_bot(id)) set_task(15.0,"display_info",id)

public display_info(id)
{
	client_print(id,print_chat,"Simply say 'fireworks' to open the fireworks menu")
}

public handle_say(id) {
	new arg1[32]
	new arg2[32]
	read_argv(1,arg1,sizeof(arg1))
	read_argv(2,arg2,sizeof(arg2))

	if (equali(arg1,"fireworks menu") || equali(arg1,"fireworks_menu") || equali(arg1,"fireworks"))
		fireworks_menu(id)

	return PLUGIN_CONTINUE
}


public changelights(id) 
{ 
	
	new arg[3] 
	read_argv(1,arg,2) 
	set_lights(arg) 
	console_print(id,"[AMXX] Light Change Successful.")

	return PLUGIN_HANDLED 
} 



public plugin_modules()
{
	require_module("FakeMeta")
	require_module("Engine")
}

public plugin_init() {
	register_plugin("Fireworks++","2.5","Twilight Suzuka")

	register_menucmd(register_menuid("Fireworks Menu:"),1023,"fireworks_keys")

	register_think("nrm_fireworks","fireworks_think");
	register_think("firework_rc","fireworks_think");
	register_think("firework_rv","fireworks_think");
	register_think("firework_normal","fireworks_think");

	register_touch("*","firework_rc","fireworks_touch");
	register_touch("*","firework_rv","fireworks_touch");
	register_touch("*","firework_normal","fireworks_touch");
	register_touch("*","nrm_fireworks","fireworks_touch");

	register_concmd("say","handle_say")
	register_srvcmd("set_lights","changelights")
	register_concmd("firework","spawn_firework")
	register_concmd("firework_rv","spawn_firework")
	register_concmd("firework_rc","spawn_firework")

	register_concmd("firework_shooter","spawn_shooter")
	register_concmd("shoot_fireworks","shoot_firework")

	register_concmd("fireworks_password","check_password")

	register_concmd("remove_fireworks","remove_fireworks")
	register_concmd("remove_shooters","remove_shooters")

	register_concmd("amx_remove_fireworks","amx_remove_fireworks")
	register_concmd("amx_remove_shooters","amx_remove_shooters")

	register_cvar("fireworks_enable","1")
	register_cvar("fireworks_flare_count","30")
	register_cvar("fireworks_maxcount","4")
	register_cvar("fireworks_amaxcount","16")
	register_cvar("fireworks_colortype","0")
	register_cvar("fireworks_multiplier","2")

	register_cvar("fireworks_xvelocity","100")
	register_cvar("fireworks_yvelocity","100")

	register_cvar("fireworks","tsx")
}

