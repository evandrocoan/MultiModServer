#include <amxmodx>
#include <fun>
#include <superheromod>

// colossus!

// CVARS
/*

//Colossus
colossus_level 0
colossus_armor 500
colossus_gravity 5.35
colossus_speed 100
colossus_cooldown 30	//# of seconds before colossus can godmode Again
colossus_godtime 5	//# of seconds colossus has in godmode mode.

*/


// VARIABLES
new gHeroName[] = "Colossus"
new bool:g_hascolossusPower[SH_MAXSLOTS+1]
new g_colossusTimer[SH_MAXSLOTS+1]
new g_colossusSound[] = "ambience/alien_zonerator.wav"
//----------------------------------------------------------------------------------------------
public plugin_init()
{
	// Plugin Info
	register_plugin("SUPERHERO Colossus","1.0","Vectren & AssKicR")

	register_cvar("colossus_level", "0")
	register_cvar("colossus_armor", "500")
	register_cvar("colossus_gravity", "5.35")
	register_cvar("colossus_speed", "100")
	register_cvar("colossus_cooldown", "30")
	register_cvar("colossus_godtime", "5")


	// FIRE THE EVENT TO CREATE THIS SUPERHERO!
	shCreateHero(gHeroName, "Iron Body", "Godmode in X sek on keydown", true, "colossus_level")

	// REGISTER EVENTS THIS HERO WILL RESPOND TO! (AND SERVER COMMANDS)
	register_event("ResetHUD","newRound","b")

	// KEY DOWN
	register_srvcmd("colossus_kd", "colossus_kd")
	shRegKeyDown(gHeroName, "colossus_kd")

	// INIT
	register_srvcmd("colossus_init", "colossus_init")
	shRegHeroInit(gHeroName, "colossus_init")

	// LOOP
	set_task(1.0,"colossus_loop",0,"",0,"b") //forever loop

	//Let server know about his cvars
	shSetMaxArmor(gHeroName, "colossus_armor")
	shSetMinGravity(gHeroName, "colossus_gravity")
	shSetMaxSpeed(gHeroName, "colossus_speed", "[0]")

}
//----------------------------------------------------------------------------------------------
public plugin_precache()
{
	precache_sound(g_colossusSound)
}
//----------------------------------------------------------------------------------------------
public colossus_init()
{
	new temp[128]
	// First Argument is an id
	read_argv(1,temp,5)
	new id=str_to_num(temp)

	// 2nd Argument is 0 or 1 depending on whether the id has iron man powers
	read_argv(2,temp,5)
	new hasPowers=str_to_num(temp)

	// REMOVE the powers if he is not colossus...
	if ( !hasPowers )
	{
		colossus_endgodmode(id)
		g_colossusTimer[id]=0
		shRemGravityPower(id)
		shRemArmorPower(id)
		shRemSpeedPower(id)
	}

	g_hascolossusPower[id]=(hasPowers!=0)

}
//----------------------------------------------------------------------------------------------
public newRound(id)
{
	gPlayerUltimateUsed[id]=false
	return PLUGIN_HANDLED
}
//----------------------------------------------------------------------------------------------
// RESPOND TO KEYDOWN
public colossus_kd()
{
	new temp[6]

	// First Argument is an id with colossus Powers!
	read_argv(1,temp,5)
	new id=str_to_num(temp)

	if ( !is_user_alive(id) ) return PLUGIN_HANDLED

	// Let them know they already used their ultimate if they have
	if ( gPlayerUltimateUsed[id] )
	{
		playSoundDenySelect(id)
		return PLUGIN_HANDLED
	}

	// Make sure they're not in the middle of GOD already
	if ( g_colossusTimer[id]>0 ) return PLUGIN_HANDLED

	g_colossusTimer[id]=get_cvar_num("colossus_godtime")+1
	set_user_godmode(id,1)
	ultimateTimer(id, get_cvar_num("colossus_cooldown") * 1.0)

	// colossus Messsage
	new message[128]
	format(message, 127, "Entered colossus Mode" )
	set_hudmessage(255,0,0,-1.0,0.3,0,0.25,1.0,0.0,0.0,4)
	show_hudmessage(id, message)
	emit_sound(id,CHAN_STATIC, g_colossusSound, 0.1, ATTN_NORM, 0, PITCH_LOW)

	return PLUGIN_HANDLED
}
//----------------------------------------------------------------------------------------------
public stopSound(id)
{
	emit_sound(id,CHAN_STATIC, g_colossusSound, 0.1, ATTN_NORM, SND_STOP, PITCH_LOW)
}
//----------------------------------------------------------------------------------------------
public colossus_loop()
{
	for ( new id=1; id<=SH_MAXSLOTS; id++ )
	{
		if ( g_hascolossusPower[id] && is_user_alive(id)  )
		{
			if ( g_colossusTimer[id]>0 )
			{
				g_colossusTimer[id]--
				new message[128]
				format(message, 127, "%d seconds left of Colossus Mode", g_colossusTimer[id] )
				set_user_rendering(id,kRenderFxGlowShell,0,0,255,10,50)
				set_hudmessage(255,0,0,-1.0,0.3,0,1.0,1.0,0.0,0.0,4)
				show_hudmessage( id, message)
			}
			else
			{
				if ( g_colossusTimer[id] == 0 )
				{
					g_colossusTimer[id]--
					colossus_endgodmode(id)
					stopSound(id)
				}
			}
		}
	}
}
//----------------------------------------------------------------------------------------------
public colossus_endgodmode(id)
{
	stopSound(id)
	g_colossusTimer[id]=0
	if ( get_user_godmode(id) == 1)
	{
		// Turn off GODMODE
		set_user_godmode(id,0)
		set_user_rendering(id,kRenderFxGlowShell,0,0,0,kRenderNormal,255)
	}
}
//----------------------------------------------------------------------------------------------