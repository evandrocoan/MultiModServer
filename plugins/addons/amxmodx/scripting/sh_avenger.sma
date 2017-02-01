/* Avenger 1.0 (by Corvae aka TheRaven)

I've worked on a new teleportation script for my mod
and after finishing it, I thought I could as well put
it to some use in a hero.

You'll like it. The idea is, that you can take revenge
for a fallen teammate. Basicly you enable the special
ability and you teleport to the location of the next
killed member of your team for a few seconds being
invincible.


CVARS - copy and paste to shconfig.cfg
--------------------------------------------------------------------------------------------------
//Avenger
Avenger_level		5		// Character level to take this hero.
Avenger_cooldown	30		// Time to wait until you can use the special ability again.
Avenger_delay		0.0		// The delay between keypress and teleport.
Avenger_time		3		// Defines the time you have to take revenge.	
Avenger_freeze		0		// Put this to 1 for enabling a freeze during avenger mode.
--------------------------------------------------------------------------------------------------*/


#include <amxmod>
#include <Vexd_Utilities>
#include <superheromod>

new gHeroName[]="Avenger"
new bool:g_hasAvengerPower[SH_MAXSLOTS+1]
new checkLocation[SH_MAXSLOTS+1][3]
new pod[3]
new avengenext[SH_MAXSLOTS+1]
new white
//----------------------------------------------------------------------------------------------
public plugin_init()
{
	register_plugin("SUPERHERO Avenger","1.0","TheRaven aka Corvae")

	register_cvar("Avenger_level", "5" )
	register_cvar("Avenger_cooldown", "30" )
	register_cvar("Avenger_delay", "0.0" )
	register_cvar("Avenger_time", "3" )
	register_cvar("Avenger_freeze", "0" )

	shCreateHero(gHeroName, "Revenge for the fallen", "Teleports to a fallen teammember and become invincible.", true, "Avenger_level" )

	register_srvcmd("Avenger_init", "Avenger_init")
	shRegHeroInit(gHeroName, "Avenger_init")
	register_event("ResetHUD","Avenger_newRound","b")
	register_srvcmd("Avenger_kd", "Avenger_kd")
	shRegKeyDown(gHeroName, "Avenger_kd")
	register_event("DeathMsg", "Avenger_death", "a")
}
//----------------------------------------------------------------------------------------------
public Avenger_init()
{
	new temp[6]
	read_argv(1,temp,5)
	new id=str_to_num(temp)
	read_argv(2,temp,5)
	new hasPowers = str_to_num(temp)
	g_hasAvengerPower[id] = (hasPowers != 0)
}
//----------------------------------------------------------------------------------------------
public Avenger_newRound(id)
{
	gPlayerUltimateUsed[id] = false
	avengenext[id] = false
	if ( g_hasAvengerPower[id] ) Avenger_Unfade(id)
}
//----------------------------------------------------------------------------------------------
public Avenger_kd()
{
	if ( !hasRoundStarted() ) return PLUGIN_HANDLED
	
	new temp[6]
	read_argv(1,temp,5)
	new id = str_to_num(temp)
	if ( !is_user_alive(id) || !g_hasAvengerPower[id] ) return PLUGIN_HANDLED

	if ( gPlayerUltimateUsed[id] ) {
		set_hudmessage(0, 100, 200, 0.05, 0.70, 1, 0.1, 2.0, 0.1, 0.1, 89)
		show_hudmessage(id, "Ability not yet ready again.")
		playSoundDenySelect(id)
		return PLUGIN_HANDLED
	}
	
	if ( avengenext[id] ) {
		avengenext[id]=false
		client_print(id, print_center, "You are no longer ready for revenge.")
	} else {
		avengenext[id]=true
		client_print(id, print_center, "You are ready to avenge your next fallen teammember.")
	}
	return PLUGIN_HANDLED	
}
//----------------------------------------------------------------------------------------------
public Avenger_go(id)
{
	ultimateTimer(id, get_cvar_float("Avenger_cooldown"))
	avengenext[id]=false
	get_user_origin(id, checkLocation[id])
	checkLocation[id][2] += 50
	
	new Float:Avengerdelay = get_cvar_float("Avenger_delay")
	if (Avengerdelay < 0.1) Avengerdelay = 0.1

	set_task(Avengerdelay,"Avenger_Toport", id+25487)
	return PLUGIN_HANDLED
}
//----------------------------------------------------------------------------------------------
public Avenger_Toport(id)
{	
	id -= 25487
	set_user_origin(id, pod)
	
	Avenger_explode(checkLocation[id])	
	Avenger_explode(pod)
	new stuncheck = get_cvar_num("Avenger_freeze")
	new stuntime = get_cvar_num("Avenger_time")
	if( stuncheck == 1 ) {
		shStun(id, stuntime)
		set_user_maxspeed(id, -1.0)
	}
	shSetGodMode(id,stuntime)
	Avenger_Fade(id)

	set_task(get_cvar_float("Avenger_time"),"Avenger_Backport",id)
	return PLUGIN_HANDLED
}
//----------------------------------------------------------------------------------------------
public Avenger_Fade(id)
{
	new gmsgScreenFade = get_user_msgid("ScreenFade")
	message_begin(MSG_ONE,gmsgScreenFade,{0,0,0},id)
	write_short( 15 )
	write_short( 15 )
	write_short( 12 )
	write_byte( 50 )
	write_byte( 50 )
	write_byte( 250 )
	write_byte( 100 )
	message_end()	
}
//----------------------------------------------------------------------------------------------
public Avenger_Unfade(id)
{
	new gmsgScreenFade = get_user_msgid("ScreenFade")
	message_begin(MSG_ONE,gmsgScreenFade,{0,0,0},id)
	write_short( 15 )
	write_short( 15 )
	write_short( 12 )
	write_byte( 0 )
	write_byte( 0 )
	write_byte( 0 )
	write_byte( 0 )
	message_end()
}
//----------------------------------------------------------------------------------------------
public Avenger_Backport(id)
{
	if( gPlayerUltimateUsed[id] ) set_user_origin(id, checkLocation[id])
	Avenger_Unfade(id)
	get_user_origin(id, pod)
	Avenger_explode(pod)
	Avenger_explode(checkLocation[id])	
}
//----------------------------------------------------------------------------------------------
public Avenger_death()
{
	new id = read_data(2)
	if ( !is_user_connected(id) || is_user_alive(id) ) return
	if ( g_hasAvengerPower[id] ) Avenger_Unfade(id)
	
	for ( new player = 1; player <= SH_MAXSLOTS; player++ ) {
		if ( player != id && is_user_alive(player) && avengenext[player] && get_user_team(id) == get_user_team(player) ) {
			get_user_origin(id, pod)
			Avenger_go(player)
			break
		}
	}
}
//----------------------------------------------------------------------------------------------
public plugin_precache()
{
	white = precache_model("sprites/white.spr")
}
//----------------------------------------------------------------------------------------------
public Avenger_explode( vec1[3] )
{
	message_begin( MSG_BROADCAST,SVC_TEMPENTITY,vec1)
	write_byte( 21 )
	write_coord(vec1[0])
	write_coord(vec1[1])
	write_coord(vec1[2] + 16)
	write_coord(vec1[0])
	write_coord(vec1[1])
	write_coord(vec1[2] + 1936)
	write_short( white )
	write_byte( 0 ) // startframe
	write_byte( 0 ) // framerate
	write_byte( 2 ) // life 2
	write_byte( 5 ) // width 16
	write_byte( 0 ) // noise
	write_byte( 100 ) // r
	write_byte( 100 ) // g
	write_byte( 255 ) // b
	write_byte( 200 ) //brightness
	write_byte( 0 ) // speed
	message_end()
}
//----------------------------------------------------------------------------------------------