//Frieza 

/*THE CVARS TO COPY AND PASTE IN SHCONFIG.CFG

//Frieza
frieza_level 10
frieza_damage 200
frieza_cooldown 50
frieza_diskspeed 750
frieza_disklife 50
*/

/*	Version 1.0:  The hero is born.
	Version 1.1:  Made the disk position right in front of user, and added
		      0.2 seconds of immunity. Since many people have IMed me complaining
		      about when they fire the disk at an incline it kills them.  So 
		      this version will fix that problem up.

*/

#include <amxmodx>
#include <engine>
#include <superheromod>

new gHeroName[] = "Frieza" 
new bool:g_hasfriezaPowers[SH_MAXSLOTS+1] 
new diskTimer[SH_MAXSLOTS+1] 
//This variable will represent the disk being made. 
new disk[SH_MAXSLOTS+1]
new flash
//------------------------------------------------------------------------------------ 
public plugin_init() 
{ 
    //Special thanks to avalanche for helping me to debug my hero.
    register_plugin("SUPERHERO frieza", "1.1", "Gorlag/Batman  /  XxAvalanchexX") 

    //THE CVARS 
    register_cvar("frieza_level", "10") 
    register_cvar("frieza_damage", "200")  
    register_cvar("frieza_cooldown", "50") 
    register_cvar("frieza_diskspeed", "750") 
    register_cvar("frieza_disklife", "50") 

    //THIS LINE MAKES THE HERO SELECTABLE 
    shCreateHero(gHeroName, "Energy Disk", "Unleash an energy disk and take control of where it flies!", true, "frieza_level") 

    //INITIAL ACTIONS 
    register_srvcmd("frieza_init", "frieza_init") 
    shRegHeroInit(gHeroName, "frieza_init") 

    //KEY DOWN COMMAND 
    register_srvcmd("frieza_kd", "frieza_kd") 
    shRegKeyDown(gHeroName, "frieza_kd") 

    //SPAWNING EVENT 
    register_event("ResetHUD", "newSpawn", "b") 

    //THIS EVENT IS TRIGGERED WHEN SOMEONE DIES
    register_event("DeathMsg", "frieza_kill", "a")

    //SET THE LIFE OF THE DISK 
    set_task(0.1, "frieza_disklife", 0, "", 0, "b") 

    //REGISTERS A TOUCH EVENT, WHEN TWO THINGS TOUCH
    register_touch("disk", "*", "touch_event")
} 
//-------------------------------------------------------------------------------------- 
public plugin_precache() 
{ 
    precache_model("models/shmod/frieza_friezadisc.mdl") 
    precache_sound("shmod/frieza_destructodisc.wav") 
    flash = precache_model("sprites/muzzleflash2.spr")
} 
//--------------------------------------------------------------------------------------- 
public frieza_init() 
{ 
    new temp[6] //To store temporary information 

    //First Argument is the id of the player 
    read_argv(1,temp,5) //Converts the string to a number 
    new id = str_to_num(temp) //gets the id of the player

    //Second Argument is either 0 or 1 depending on whether the person has the hero or not 
    read_argv(2,temp,5) 
    new hasPowers = str_to_num(temp) //Makes the string into a number 
    g_hasfriezaPowers[id] = (hasPowers != 0) //tells if player has power or not

    if(hasPowers){
	disk[id] = 0
        diskTimer[id] = -1 
    }

    if(!hasPowers && diskTimer[id] > 0){ //When a player doesn't have power anymore
        diskTimer[id] = -1
        new Float: fOrigin[3]
	new origin[3]
	if(is_valid_ent(disk[id])){
		entity_get_vector(disk[id], EV_VEC_origin, fOrigin)
		FVecIVec(fOrigin, origin)
		decay_effects(disk[id], origin)
	}
    } 

} 
//--------------------------------------------------------------------------------------- 
public frieza_kd() 
{ 
    if(!hasRoundStarted()) return 

    new temp[6] 

    //Get the id of the player 
    read_argv(1,temp,5) 
    new id = str_to_num(temp) //the player id

    if(!is_user_alive(id) || !g_hasfriezaPowers[id]) return 

    if(gPlayerUltimateUsed[id]){ 
        playSoundDenySelect(id) 
        return 
    } 
    diskTimer[id] = get_cvar_num("frieza_disklife") //How long the disk can fly

    fire_disk(id) 

    if(get_cvar_float("frieza_cooldown") > 0.0) 
        ultimateTimer(id, get_cvar_float("frieza_cooldown")) //cooldown timer
} 
//---------------------------------------------------------------------------------------- 
public newSpawn(id) 
{ 
    gPlayerUltimateUsed[id] = false  //Makes you able to use power again 
} 
//---------------------------------------------------------------------------------------- 
public frieza_kill()  //triggered everytime someone dies
{
	new id = read_data(2)  //This tells who the victim is
	if(g_hasfriezaPowers[id] && diskTimer[id] > 0){
		diskTimer[id] = -1
		new Float: fOrigin[3]
		new origin[3]
		//gets current position of entity
		entity_get_vector(disk[id], EV_VEC_origin, fOrigin)
		//converts a floating vector into an integer vector
		FVecIVec(fOrigin, origin)
		decay_effects(disk[id], origin)
	}
}
//----------------------------------------------------------------------------------------
public frieza_disklife(){ 
    for(new id = 1; id <= SH_MAXSLOTS; id++){ 
        if(g_hasfriezaPowers[id] && is_user_alive(id)){ 
            if(diskTimer[id] > 0){ 
                diskTimer[id]-- 
		new Float: fVelocity[3]
		//gets the velocity by the direction you are looking at
		velocity_by_aim(id, get_cvar_num("frieza_diskspeed"), fVelocity)
		//sets the new velocity
		entity_set_vector(disk[id], EV_VEC_velocity, fVelocity)
            } 
            else if(diskTimer[id] == 0){
		new Float: fOrigin[3]
		new origin[3]
		//gets the current position of entity
                entity_get_vector(disk[id], EV_VEC_origin, fOrigin)
		//converts a floating vector to an integer vector
		FVecIVec(fOrigin, origin)
		decay_effects(disk[id], origin)
                diskTimer[id]-- 
            } 
        } 
    } 
} 
//----------------------------------------------------------------------------------------
public fire_disk(id) 
{   //makes sure that the number of entities created does not exceed the maximum amount
    //of entities allowed
    if(entity_count() == get_global_int(GL_maxEntities)){
	client_print(id, print_chat, "[SH] Cannot create more entities")
	return
    } 

    //Makes an array of origin in the (x,y,z) coordinate system.
    new origin[3]

    //Makes an array of velocity, specifically in the (x,y,z) coordinate system 
    new velocity[3] 

    new Float:fOrigin[3], Float:fVelocity[3]
    get_user_origin(id, origin, 1)
    new Float: minBound[3] = {-50.0, -50.0, 0.0}  //sets the minimum bound of entity
    new Float: maxBound[3] = {50.0, 50.0, 0.0}    //sets the maximum bound of entity
    IVecFVec(origin, fOrigin)

    //This will make it so that the disk appears in front of the user
    new Float:viewing_angles[3]
    new distance_from_user = 70
    entity_get_vector(id, EV_VEC_angles, viewing_angles)
    fOrigin[0] += floatcos(viewing_angles[1], degrees) * distance_from_user
    fOrigin[1] += floatsin(viewing_angles[1], degrees) * distance_from_user
    fOrigin[2] += floatsin(-viewing_angles[0], degrees) * distance_from_user

    new NewEnt = create_entity("info_target")  //Makes an object 
    entity_set_string(NewEnt, EV_SZ_classname, "disk") //sets the classname of the entity
    disk[id] = NewEnt

    //This tells what the object will look like 
    entity_set_model(NewEnt, "models/shmod/frieza_friezadisc.mdl") 

    //This will set the origin of the entity 
    entity_set_origin(NewEnt, fOrigin) 

    //This will set the movetype of the entity 
    entity_set_int(NewEnt,EV_INT_movetype, MOVETYPE_NOCLIP) 

    //This makes the entity touchable
    entity_set_int(NewEnt, EV_INT_solid, SOLID_TRIGGER)

    //This will set the velocity of the entity 
    velocity_by_aim(id, get_cvar_num("frieza_diskspeed"), fVelocity) 
    FVecIVec(fVelocity, velocity) //converts a floating vector to an integer vector

    //Sets the size of the entity
    entity_set_size(NewEnt, minBound, maxBound)

    //Sets who the owner of the entity is
    entity_set_edict(NewEnt, EV_ENT_owner, id)

    //This will set the entity in motion 
    entity_set_vector(NewEnt, EV_VEC_velocity, fVelocity) 

    //This will make the entity have sound.
    emit_sound(NewEnt, CHAN_VOICE, "shmod/frieza_destructodisc.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM)

    new lifetime = get_cvar_num("frieza_disklife")

    //This is the trail effects, to learn more about animation effects go to this link
    //http://shero.rocks-hideout.com/forums/viewtopic.php?t=1941
    message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
    write_byte(22)       //TE_BEAMFOLLOW
    write_short(NewEnt)  //The entity to attach the sprite to
    write_short(flash)  //sprite's model
    write_byte(lifetime)   //life in 0.1 seconds
    write_byte(50)   //width of sprite
    write_byte(255)  //red
    write_byte(0)    //green
    write_byte(255)  //blue
    write_byte(255)  //brightness
    message_end()

    return

} 
//-----------------------------------------------------------------------------------------	
public touch_event(pToucher, pTouched)  //This is triggered when two entites touch
{ 
    new aimvec[3], Float:fAimvec[3]  //This is the position where the disk collides 
    entity_get_vector(pTouched, EV_VEC_origin, fAimvec) 
    FVecIVec(fAimvec, aimvec) 
    new self_immune = get_cvar_num("frieza_disklife") - 2 //Gives split-second immunity

    if(pTouched == entity_get_edict(pToucher, EV_ENT_owner) && diskTimer[pTouched] > self_immune)
	return PLUGIN_HANDLED
    //Checks to see if entity is a player or an inanimate object. 
    if(is_user_connected(pTouched)){
	special_effects(pToucher, pTouched, aimvec)
	return PLUGIN_CONTINUE
    }

    special_effects(pToucher, 0, aimvec)

    return PLUGIN_CONTINUE 
} 
//----------------------------------------------------------------------------------------- 
public special_effects(pToucher, pTouched, aimvec[3]) //effects for when disk touch
{
	new Float:fVelocity[3]
	new velocity[3]
	new damage
	entity_get_vector(pToucher, EV_VEC_velocity, fVelocity)
	FVecIVec(fVelocity, velocity)

	//Got to know who's the one using the disk
	//So that when the victim dies, he knows who's the killer
	//That used the disk
	new killer = entity_get_edict(pToucher, EV_ENT_owner)

	//To learn more about animation effects go to this link
	//http://shero.rocks-hideout.com/forums/viewtopic.php?t=1941
	if(is_user_alive(pTouched)){
		message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
		write_byte(101)  //BLOODSTREAM
		write_coord(aimvec[0])
		write_coord(aimvec[1])
		write_coord(aimvec[2])
		write_coord(velocity[0])
		write_coord(velocity[1])
		write_coord(velocity[2])
		write_byte(95)
		write_byte(100)
		message_end()

		damage = get_cvar_num("frieza_damage")
		new victim = pTouched
		shExtraDamage(victim, killer, damage, "Frieza's Energy Disk")
	}
	//Same link for here to http://shero.rocks-hideout.com/forums/viewtopic.php?t=1941
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
	write_byte(9)  //SPARKS
	write_coord(aimvec[0])
	write_coord(aimvec[1])
	write_coord(aimvec[2])
	message_end()

}
//-----------------------------------------------------------------------------------------
public decay_effects(NewEnt, origin[3])  //removes the entity plus adds a decaying effect
{
	if(is_valid_ent(NewEnt)){
		remove_entity(NewEnt)
		//To learn more about animation effects go to this link
		//http://shero.rocks-hideout.com/forums/viewtopic.php?t=1941
		message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
		write_byte(14) //IMPLOSION
		write_coord(origin[0])
		write_coord(origin[1])
		write_coord(origin[2])
		write_byte(50)
		write_byte(10)
		write_byte(10)
		message_end()
	}
}
//------------------------------------------------------------------------------------------
public client_disconnect(id)  //This makes sure that the disk isn't flying after disconnect
{
	if(g_hasfriezaPowers[id] && diskTimer[id] > 0){
		new Float: fOrigin[3]
		new origin[3]
		entity_get_vector(disk[id], EV_VEC_origin, fOrigin)
		FVecIVec(fOrigin, origin)
		decay_effects(disk[id], origin)
	}
}
//------------------------------------------------------------------------------------------