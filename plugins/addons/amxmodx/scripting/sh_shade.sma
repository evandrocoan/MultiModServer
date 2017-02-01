#include <amxmod>
#include <xtrafun>
#include <superheromod>

// shade

// CVARS
// shade_cooldown
// shade_time
// shade_level


// VARIABLES
new gHeroName[]="Shade"
new bool:gHasShadePower[SH_MAXSLOTS+1]
new g_shadeTimer[SH_MAXSLOTS+1]
new gShadeMode[33]
new g_shadeSound[]="ambience/sandfall1.wav"
new smoke
//----------------------------------------------------------------------------------------------
public plugin_init()
{
	// Plugin Info
	register_plugin("SUPERHERO Shade","1.0","[SiN]")

	// FIRE THE EVENT TO CREATE THIS SUPERHERO!
	if ( isDebugOn() ) server_print("Attempting to create Shade Hero")
	if (!cvar_exists("shade_level")) register_cvar("shade_level", "10" )
	shCreateHero(gHeroName, "Dust-storm", "Create a dust storm!", true, "shade_level")
	register_clcmd("ShadePower","make_fog",ADMIN_USER)
	// REGISTER EVENTS THIS HERO WILL RESPOND TO! (AND SERVER COMMANDS)
	register_event("ResetHUD","newRound","b")
	register_event("CurWeapon","changeWeapon","be","1=1")
	// KEY DOWN
	register_srvcmd("shade_kd", "shade_kd")
	shRegKeyDown(gHeroName, "shade_kd")
	// INIT
	register_srvcmd("shade_init", "shade_init")
	shRegHeroInit(gHeroName, "shade_init")
	// LOOP
	register_srvcmd("shade_loop", "shade_loop")
	//  shRegLoop1P0(gHeroName, "shade_loop", "ac" )
	set_task(1.0,"shade_loop",0,"",0,"b") //forever loop
	// DEATH
	register_event("DeathMsg", "shade_death", "a")
	// DEFAULT THE CVARS
	if (!cvar_exists("shade_cooldown")) register_cvar("shade_cooldown", "0" ) //CoolDown
	if (!cvar_exists("shade_time")) register_cvar("shade_time", "1" )
	if ( !cvar_exists("shade_speed") ) register_cvar("shade_speed", "450" )
	if ( !cvar_exists("shade_summon") ) register_cvar("shade_summon", "0" )
	if ( !cvar_exists("shade_smoke") ) register_cvar("shade_smoke", "1" )
	if ( !cvar_exists("shade_ammo") ) register_cvar("shade_ammo", "0" )
}
//----------------------------------------------------------------------------------------------
public plugin_precache()
{
	smoke = precache_model("sprites/steam1.spr")
	precache_sound(g_shadeSound)
}
//----------------------------------------------------------------------------------------------
public shade_init()
{
	new temp[128]
	// First Argument is an id
	read_argv(1,temp,5)
	new id=str_to_num(temp)

	// 2nd Argument is 0 or 1 depending on whether the id has shade powers
	read_argv(2,temp,5)
	new hasPowers=str_to_num(temp)

	if ( !hasPowers )
	{
		shade_endmode(id)
		g_shadeTimer[id]=0
	}

	gHasShadePower[id]=(hasPowers!=0)
}
//----------------------------------------------------------------------------------------------
public newRound(id)
{
	gPlayerUltimateUsed[id]=false
	if ( gHasShadePower[id] ) {
		shade_gunz(id)
	}
	if (g_shadeTimer[id]>0) {
		shade_endmode(id)
	}
	return PLUGIN_HANDLED
}
//----------------------------------------------------------------------------------------------
// RESPOND TO KEYDOWN
public shade_kd()
{
	new temp[6]

	// First Argument is an id with shade Powers!
	read_argv(1,temp,5)
	new id=str_to_num(temp)

	if ( !is_user_alive(id) ) return PLUGIN_HANDLED

	// Let them know they already used their ultimate if they have
	if ( gPlayerUltimateUsed[id] )
	{
		playSoundDenySelect(id)
		return PLUGIN_HANDLED
	}


	if ( g_shadeTimer[id]>0 ) return PLUGIN_HANDLED

	g_shadeTimer[id]=get_cvar_num("shade_time")+1
	if (get_cvar_num("shade_smoke")==1){
		make_fog(id)
	}
	set_user_footsteps(id,1)
	shSetMaxSpeed(gHeroName, "shade_speed", "[0]" )
	ultimateTimer(id, get_cvar_num("shade_cooldown") * 1.0)
	gShadeMode[id]=true

	// shade Messsage
	new message[128]
	format(message, 127, "Created a dust-storm!" )
	set_hudmessage(0,0,255,-1.0,0.3,0,0.25,1.0,0.0,0.0,4)
	show_hudmessage(id, message)
	emit_sound(id,CHAN_STATIC, g_shadeSound, 0.1, ATTN_NORM, 0, PITCH_LOW)

	return PLUGIN_HANDLED
}
//----------------------------------------------------------------------------------------------
public stopSound(id)
{
	//new SND_STOP=(1<<5)
	emit_sound(id,CHAN_STATIC, g_shadeSound, 0.1, ATTN_NORM, SND_STOP, PITCH_LOW)
}
//----------------------------------------------------------------------------------------------
public shade_loop()
{
	for ( new id=1; id<=SH_MAXSLOTS; id++ )
	{
		if ( gHasShadePower[id] && is_user_alive(id)  )
		{
			if ( g_shadeTimer[id]>0 )
			{
				g_shadeTimer[id]--
				new message[128]
				format(message, 127, "Dust storm created.", g_shadeTimer[id] )
				set_hudmessage(0,0,255,-1.0,0.3,0,1.0,1.0,0.0,0.0,4)
				show_hudmessage( id, message)
				set_user_rendering(id,kRenderFxGlowShell,0,0,0,kRenderTransAlpha,80)
			}
			else
			{
				if ( g_shadeTimer[id] == 0 )
				{
					g_shadeTimer[id]--
					shade_endmode(id)
					stopSound(id)
				}
			}
		}
	}
}
//----------------------------------------------------------------------------------------------
public shade_endmode(id)
{
	stopSound(id)
	g_shadeTimer[id]=0
	if ( gShadeMode[id])
	{
		// Turn it off
		set_user_footsteps(id,0)
		shRemSpeedPower(id)
		set_user_rendering(id,kRenderFxGlowShell,0,0,0,kRenderTransAlpha,255)
		gShadeMode[id]=false
	}
}
//----------------------------------------------------------------------------------------------
public shade_death()
{
	new id=read_data(2)
	shade_endmode(id)
	gPlayerUltimateUsed[id]=false
}
//----------------------------------------------------------------------------------------------
public fog_this_area(origin[3])
{
	message_begin( MSG_BROADCAST,SVC_TEMPENTITY,origin )
	write_byte( 5 )
	write_coord( origin[0] + random_num( -100, 100 ))
	write_coord( origin[1] + random_num( -100, 100 ))
	write_coord( origin[2] + random_num( -75, 75 ))
	write_short( smoke )
	write_byte( 60 )
	write_byte( 5 )
	message_end()
}
//----------------------------------------------------------------------------------------------
//----------------------------------------------------------------------------------------------
public changeWeapon(id)
{
	if (get_cvar_num("shade_ammo")==1){
		if ( !gHasShadePower[id] || !shModActive() ) return PLUGIN_CONTINUE
	}
	else{
		if ( !gHasShadePower[id] || !gShadeMode[id] || !shModActive() ) return PLUGIN_CONTINUE
	}
	new  clip, ammo
	new wpn_id=get_user_weapon(id, clip, ammo);
	new wpn[32]

	if ( wpn_id!=CSW_DEAGLE) {
		engclient_cmd(id,"weapon_deagle")
	}

	if ( wpn_id==CSW_TMP) {

		// Never Run Out of Ammo!
		//server_print("STATUS ID=%d CLIP=%d, AMMO=%d WPN=%d", id, clip, ammo, wpn_id)
		if ( clip == 0 )
		{
			//server_print("INVOKING PUNISHER MODE! ID=%d CLIP=%d, AMMO=%d WPN=%d", id, clip, ammo, wpn_id)
			get_weaponname(wpn_id,wpn,31)
			//highly recommend droppging weapon - buggy without it!
			give_item(id,wpn)
			engclient_cmd(id, wpn )
			engclient_cmd(id, wpn ) // Checking to see if multple sends helps - sometimes this doesn't work... ;-(
			engclient_cmd(id, wpn ) // Checking to see if multple sends helps - sometimes this doesn't work... ;-(
		}
	}

	return PLUGIN_CONTINUE
}
//----------------------------------------------------------------------------------------------
public shade_gunz(id)
{
	shGiveWeapon(id,"weapon_deagle")
	shGiveWeapon(id,"ammo_7mm")
	shGiveWeapon(id,"ammo_7mm")
}
//----------------------------------------------------------------------------------------------
public make_fog(id){
	if (gHasShadePower[id]==false)
		return PLUGIN_HANDLED
	if (is_user_alive(id)!=1)
		return PLUGIN_HANDLED
	new origin[3]
	get_user_origin(id,origin)
	fog_this_area(origin)
	fog_this_area(origin)
	fog_this_area(origin)
	fog_this_area(origin)
	fog_this_area(origin)
	fog_this_area(origin)
	fog_this_area(origin)
	fog_this_area(origin)
	fog_this_area(origin)
	fog_this_area(origin)
	fog_this_area(origin)
	fog_this_area(origin)
	fog_this_area(origin)
	fog_this_area(origin)
	fog_this_area(origin)
	fog_this_area(origin)
	if (get_cvar_num("shade_summon")==1){
		summon_shade(id)
	}
	return PLUGIN_HANDLED
}
//----------------------------------------------------------------------------------------------
public summon_shade(id)
{
	new cmd[128]
	new team[24]
	get_user_team(id,team,7)

	if (equal(team, "CT", 1)) {
		format(cmd, 127, "amx_monster hassassin #%i 1 @T", id)
		server_cmd(cmd)
	}
	else {
		format(cmd, 127, "amx_monster hassassin #%i 1 @CT", id)
		server_cmd(cmd)
	}
}
//----------------------------------------------------------------------------------------------
