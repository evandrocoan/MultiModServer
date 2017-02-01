#include <amxmod>
#include <Vexd_Utilities>
#include <superheromod>

/* 
------------- CHANGELOG -------------\\
V 1.25 (LATEST)
Upon request I added a cvar for a choice, do you want to die if you get stuck or no?

V1.20 
Added in code to check to see if the user is stuck. If so kill them.
Too lazy to write this on my own so I took it from Nightcrawler with few modifications

V1.10 
Cleaned up code and took out unneccessary crap.
This was my first hero so I didn't know what I was doing :O rofl...

V1.00 
Initial Release.
*/


/*
CVARS 
// Shadow Cat
scat_level 17       // Default level is 17
scat_wallkill 0     // Will the user die if stuck in the wall (0=NO | 1=YES)
*/

// GLOBAL VARIABLES
new gHeroName[]="Shadow Cat"
new bool:g_hasscatPowers[SH_MAXSLOTS+1]
new g_lastPosition[SH_MAXSLOTS+1][3]
//----------------------------------------------------------------------------------------------
public plugin_init()
{
	// Plugin Info
	register_plugin("SUPERHERO Shadow Cat","1.25","bLiNd")

	// Use the shconfig.cfg not cvars to change level
	register_cvar("scat_level", "17")
	register_cvar("scat_wallkill", "0")

	// FIRE THE EVENT TO CREATE THIS SUPERHERO!
	shCreateHero(gHeroName, "Shadow Cat Powers", "Use Your knife to Walk through walls.", false, "scat_level" )

	// REGISTER EVENTS THIS HERO WILL RESPOND TO! (AND SERVER COMMANDS)
	// INIT
	register_srvcmd("scat_init", "scat_init")
	shRegHeroInit(gHeroName, "scat_init")

	//NEW ROUND
	register_event("ResetHUD","newSpawn","b")
	
	// WEAPON CHECK
	register_event("CurWeapon","weaponChange","be","1=1")

}
//----------------------------------------------------------------------------------------------
public scat_init()
{
	new temp[6]
	// First Argument is an id
	read_argv(1,temp,5)
	new id=str_to_num(temp)

	// 2nd Argument is 0 or 1 depending on whether the id has scat power
	read_argv(2,temp,5)
	new hasPowers=str_to_num(temp)

	g_hasscatPowers[id] = (hasPowers!=0)

	// Got to slow down a cat that lost his powers...
	if ( !hasPowers  && is_user_alive(id) ){
		set_user_noclip(id,0)
		
	}
	else {
		weaponChange(id)
	}
}
//----------------------------------------------------------------------------------------------
public newSpawn(id)
{
	gPlayerUltimateUsed[id] = false
	if (g_hasscatPowers[id]) {
		scat_endnoclip(id)
	}
}
//----------------------------------------------------------------------------------------------
public weaponChange(id)
{
	if ( !g_hasscatPowers[id] || !shModActive() ) return

	new wpnid = read_data(2)

	if ( wpnid == CSW_KNIFE ) set_user_noclip(id,1)
	
	if (!get_cvar_num("scat_wallkill")) {
		if ( wpnid != CSW_KNIFE ) set_user_noclip(id,0)
	}
	else {
	if ( wpnid != CSW_KNIFE ) scat_endnoclip(id)
	}
}
//----------------------------------------------------------------------------------------------
public positionChangeTimer(id)
{
	if ( !is_user_alive(id) ) return

	get_user_origin(id, g_lastPosition[id], 0)

	new Float:velocity[3]
	Entvars_Get_Vector(id, EV_VEC_velocity, velocity)

	if ( velocity[0]==0.0 && velocity[1]==0.0 ) {
		velocity[0] += 20.0
		velocity[2] += 100.0
		Entvars_Set_Vector(id, EV_VEC_velocity, velocity)
	}

	set_task(0.4,"positionChangeCheck",id)
}
//----------------------------------------------------------------------------------------------
public positionChangeCheck(id)
{
	new origin[3]

	if (!is_user_alive(id) ) return

	get_user_origin(id, origin, 0)
	if ( g_lastPosition[id][0] == origin[0] && g_lastPosition[id][1] == origin[1] && g_lastPosition[id][2] == origin[2] && is_user_alive(id) ) {
		//Kill the cute little Kitty :D
		user_kill(id)
	}
}
//----------------------------------------------------------------------------------------------
public scat_endnoclip(id)
{
	if (!is_user_connected(id)) return

	if (!is_user_alive(id)) return
	if ( get_user_noclip(id) == 1) {
		// Turn off no-clipping and make sure the user has moved
		set_user_noclip(id, 0)
		positionChangeTimer(id)
	}
}
//----------------------------------------------------------------------------------------------