 #include <amxmod.inc>
 #include <xtrafun>
 #include <superheromod.inc>

 // Bullsquid - modded  from Agrunt by Emp
 // Agrunt Created by litovietboi & [SIN]
 // Credits goes to Freecode for helping with keydown.

 //Bullsquid CVARS
 // bull_level 7 		//level default-7
 // bull_cooldown 600 		//cooldown default-600

 //Change These CVARS in monster_skill.cfg in cstrike folder
 // sk_bullsquid_health  200
 // sk_bullsquid_dmg_bite 100 
 // sk_bullsquid_dmg_whip  200
 // sk_bullsquid_dmg_spit  300
 //
 
 // VARIABLES
 new gHeroName[]="Bullsquid"
 new bool:gHasBULLPowers[SH_MAXSLOTS+1]={false}
 new gPlayerLevels[SH_MAXSLOTS+1]
 //BREAK
 //--------------------------------------------------------------------------------------------------------
 public plugin_init()
 {
	// Plugin Info
	register_plugin("Bullsquid","1.0","[ LiToVietBoi ] & [SiN]")

	if ( isDebugOn() ) server_print("Attempting to create Bullsquid Hero")
	register_cvar("bull_level", "8" )
	register_cvar("bull_cooldown", "600")
	shCreateHero(gHeroName, "Spawn a Bullsquid", "Spawn a crazy Bullsquid thing on keydown!", true, "bull_level" )


	register_event("ResetHUD","BULL_newround","b")
	register_srvcmd("BULL_init", "BULL_init")
	shRegHeroInit(gHeroName, "BULL_init")

	register_srvcmd("BULL_levels", "BULL_levels")
	shRegLevels(gHeroName,"BULL_levels")

	register_srvcmd("Bullsquid_kd", "Bullsquid_kd")
	shRegKeyDown(gHeroName, "Bullsquid_kd")

 }
 //--------------------------------------------------------------------------------------------------------
 public BULL_newround(id)
 {
	gPlayerUltimateUsed[id]=false

 }
 //--------------------------------------------------------------------------------------------------------
 public Bullsquid_kd()
 {
	// First Argument is an id with Bullsquid Powers!
	new temp[6]
	read_argv(1,temp,5)
	new id=str_to_num(temp)

	if ( gHasBULLPowers[id] && hasRoundStarted() && is_user_alive(id) )
	{
		if ( gPlayerUltimateUsed[id] )
		{
			playSoundDenySelect(id)
			client_print(id,print_chat,"[Bullsquid] You have already spawned a bullsquid.")
			return PLUGIN_HANDLED
		}
		BULL_summon(id)
		ultimateTimer(id, get_cvar_num("bull_cooldown") * 1.0)
	}
	return PLUGIN_HANDLED
 }
 //----------------------------------------------------------------------------------------------
 public plugin_precache()
 {
	precache_sound("ambience/port_suckin1.wav")
 }
 //--------------------------------------------------------------------------------------------------------
 public BULL_init()
 {
	new temp[6]
	// First Argument is an id
	read_argv(1,temp,5)
	new id=str_to_num(temp)

	// 2nd Argument is 0 or 1 depending on whether the id has Bullsquid skills
	read_argv(2,temp,5)
	new hasPowers=str_to_num(temp)

	if ( hasPowers )
	gHasBULLPowers[id]=true
	else
	gHasBULLPowers[id]=false
 }
 //--------------------------------------------------------------------------------------------------------
 public BULL_levels()
 {
	new id[5]
	new lev[5]

	read_argv(1,id,1)
	read_argv(2,lev,1)

	gPlayerLevels[str_to_num(id)]=str_to_num(lev)
 }
 //--------------------------------------------------------------------------------------------------------
 public BULL_summon(id)
 {
	if ( gHasBULLPowers[id] && is_user_alive(id) )
	{
		{
			new cmd[128]
			format(cmd, 127, "monster bullsquid #%i", (id) )
			server_cmd(cmd)
		}

	}
	return PLUGIN_HANDLED
 }
 //--------------------------------------------------------------------------------------------------------
