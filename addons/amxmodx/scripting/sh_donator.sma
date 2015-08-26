// Hero: Donator
// version 1.0 - Created by Smoid

/*

Cvars (put in your Shconfig.cfg file)

Donator_level 10 //OMG! could this be the level he is at! :O

*/

#include <amxmodx>
#include <superheromod>


// Global stuff
new gHeroName[] ="Donator"
new bool:ghasDonatorPower[SH_MAXSLOTS+1]

//---------------------------------------------------------------------------------weeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee-----------20
public plugin_init()
{

	//info
	register_plugin("SUPERHERO Donator", "1.0", "Smoid")

	//register the cvars, do not edit these, edit in shconfig file
	register_cvar("Donator_level", "10")

	//Fire event to create the hero
	shCreateHero(gHeroName, "Generosity", "Give some of your xp to others", true, "Donator_level" )

	register_srvcmd("Donator_kd", "Donator_kd")
	shRegKeyDown(gHeroName, "Donator_kd")


}
//------------------------------------------------wooooooooooooooooooooooooooooooooooooh------------------43

public Donator_kd()
{ 

	// First Argument is an id
	new temp[6]
	read_argv(1,temp,5)
	new id=str_to_num(temp)

	// Find who the donator is looking at 
   	new targetid, body 

	
	get_user_aiming(id, targetid, body)

	new targname[32]
	new idname[32]
	
	get_user_name(targetid, targname, 31)
	get_user_name(id, idname, 31)

	
	// Give away the xp :)

	if ( is_user_alive(targetid)) {
	shAddXP(targetid, id, 1)
	client_print(id,print_chat, "[SHM Donator]You gave %s 1 kill's worth of XP", targname) 
	shAddXP(id, id, -1)
	client_print(targetid,print_chat, "[SHM Donator]%s gave you XP", idname) 
	}


	//resets target id so you dont give the same person xp even if your looking at noone
}