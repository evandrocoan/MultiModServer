 #include <amxmod.inc>
 #include <xtrafun>
 #include <superheromod.inc>

 // Tentacle - modded  from Agrunt by Emp
 // Agrunt Created by litovietboi & [SIN]
 // Credits goes to Freecode for helping with keydown.

 //Tentacle CVARS
 // tent_level 7 		//level default-7
 // tent_cooldown 600 		//cooldown default-600

 //Change These CVARS in monster_skill.cfg in cstrike folder
 // sk_tentacle_health 180 	//health of the tentacle default-180
 // sk_tentacle_dmg_bite 1000000 //dmg of bit default-1000000

 // VARIABLES
 new gHeroName[]="Tentacle"
 new bool:gHasTENTPowers[SH_MAXSLOTS+1]={false}
 new gPlayerLevels[SH_MAXSLOTS+1]
 //BREAK
 //--------------------------------------------------------------------------------------------------------
 public plugin_init()
 {
	// Plugin Info
	register_plugin("Tentacle","1.0","[ LiToVietBoi ] & [SiN]")

	if ( isDebugOn() ) server_print("Attempting to create Tentacle Hero")
	register_cvar("tent_level", "8" )
	register_cvar("tent_cooldown", "600")
	shCreateHero(gHeroName, "Spawn a Tentacle", "Spawn a crazy tentacle thing on keydown!", true, "tent_level" )


	register_event("ResetHUD","TENT_newround","b")
	register_srvcmd("TENT_init", "TENT_init")
	shRegHeroInit(gHeroName, "TENT_init")

	register_srvcmd("TENT_levels", "TENT_levels")
	shRegLevels(gHeroName,"TENT_levels")

	register_srvcmd("Tentacle_kd", "Tentacle_kd")
	shRegKeyDown(gHeroName, "Tentacle_kd")

 }
 //--------------------------------------------------------------------------------------------------------
 public TENT_newround(id)
 {
	gPlayerUltimateUsed[id]=false

 }
 //--------------------------------------------------------------------------------------------------------
 public Tentacle_kd()
 {
	// First Argument is an id with Tentacly Powers!
	new temp[6]
	read_argv(1,temp,5)
	new id=str_to_num(temp)

	if ( gHasTENTPowers[id] && hasRoundStarted() && is_user_alive(id) )
	{
		if ( gPlayerUltimateUsed[id] )
		{
			playSoundDenySelect(id)
			client_print(id,print_chat,"[Tentacle] You have already spawned a tentacle.")
			return PLUGIN_HANDLED
		}
		TENT_summon(id)
		ultimateTimer(id, get_cvar_num("tent_cooldown") * 1.0)
	}
	return PLUGIN_HANDLED
 }
 //----------------------------------------------------------------------------------------------
 public plugin_precache()
 {
	precache_sound("ambience/port_suckin1.wav")
 }
 //--------------------------------------------------------------------------------------------------------
 public TENT_init()
 {
	new temp[6]
	// First Argument is an id
	read_argv(1,temp,5)
	new id=str_to_num(temp)

	// 2nd Argument is 0 or 1 depending on whether the id has Tentacle skills
	read_argv(2,temp,5)
	new hasPowers=str_to_num(temp)

	if ( hasPowers )
	gHasTENTPowers[id]=true
	else
	gHasTENTPowers[id]=false
 }
 //--------------------------------------------------------------------------------------------------------
 public TENT_levels()
 {
	new id[5]
	new lev[5]

	read_argv(1,id,1)
	read_argv(2,lev,1)

	gPlayerLevels[str_to_num(id)]=str_to_num(lev)
 }
 //--------------------------------------------------------------------------------------------------------
 public TENT_summon(id)
 {
	if ( gHasTENTPowers[id] && is_user_alive(id) )
	{
		{
			new cmd[128]
			format(cmd, 127, "monster tentacle #%i", (id) )
			server_cmd(cmd)
		}

	}
	return PLUGIN_HANDLED
 }
 //--------------------------------------------------------------------------------------------------------