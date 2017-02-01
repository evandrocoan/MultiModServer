 #include <amxmod.inc>
 #include <xtrafun>
 #include <superheromod.inc>

 // Bigmomma - modded  from Agrunt by Emp
 // Agrunt Created by litovietboi & [SIN]
 // Credits goes to Freecode for helping with keydown.

 //Bigmomma CVARS
 // big_level 7 		//level default-7
 // big_cooldown 600 		//cooldown default-600

 //Change These CVARS in monster_skill.cfg in cstrike folder
 // sk_bigmomma_health_factor  1.5
 // sk_bigmomma_dmg_slash  100 
 // sk_bigmomma_dmg_blast  200
 // sk_bigmomma_radius_blast  350
 //
 
 // VARIABLES
 new gHeroName[]="Big Momma"
 new bool:gHasBIGPowers[SH_MAXSLOTS+1]={false}
 new gPlayerLevels[SH_MAXSLOTS+1]
 //BREAK
 //--------------------------------------------------------------------------------------------------------
 public plugin_init()
 {
	// Plugin Info
	register_plugin("Big Momma","1.0","[ LiToVietBoi ] & [SiN]")

	if ( isDebugOn() ) server_print("Attempting to create Big Momma Hero")
	register_cvar("big_level", "8" )
	register_cvar("big_cooldown", "600")
	shCreateHero(gHeroName, "Spawn a Big Momma", "Spawn a crazy Big Momma thing on keydown!", true, "big_level" )


	register_event("ResetHUD","BIG_newround","b")
	register_srvcmd("BIG_init", "BIG_init")
	shRegHeroInit(gHeroName, "BIG_init")

	register_srvcmd("BIG_levels", "BIG_levels")
	shRegLevels(gHeroName,"BIG_levels")

	register_srvcmd("Bigmomma_kd", "Bigmomma_kd")
	shRegKeyDown(gHeroName, "Bigmomma_kd")

 }
 //--------------------------------------------------------------------------------------------------------
 public BIG_newround(id)
 {
	gPlayerUltimateUsed[id]=false

 }
 //--------------------------------------------------------------------------------------------------------
 public Bigmomma_kd()
 {
	// First Argument is an id with Bigmomma Powers!
	new temp[6]
	read_argv(1,temp,5)
	new id=str_to_num(temp)

	if ( gHasBIGPowers[id] && hasRoundStarted() && is_user_alive(id) )
	{
		if ( gPlayerUltimateUsed[id] )
		{
			playSoundDenySelect(id)
			client_print(id,print_chat,"[Big Momma] You have already spawned a big Momma.")
			return PLUGIN_HANDLED
		}
		BIG_summon(id)
		ultimateTimer(id, get_cvar_num("big_cooldown") * 1.0)
	}
	return PLUGIN_HANDLED
 }
 //----------------------------------------------------------------------------------------------
 public plugin_precache()
 {
	precache_sound("ambience/port_suckin1.wav")
 }
 //--------------------------------------------------------------------------------------------------------
 public BIG_init()
 {
	new temp[6]
	// First Argument is an id
	read_argv(1,temp,5)
	new id=str_to_num(temp)

	// 2nd Argument is 0 or 1 depending on whether the id has Bigmomma skills
	read_argv(2,temp,5)
	new hasPowers=str_to_num(temp)

	if ( hasPowers )
	gHasBIGPowers[id]=true
	else
	gHasBIGPowers[id]=false
 }
 //--------------------------------------------------------------------------------------------------------
 public BIG_levels()
 {
	new id[5]
	new lev[5]

	read_argv(1,id,1)
	read_argv(2,lev,1)

	gPlayerLevels[str_to_num(id)]=str_to_num(lev)
 }
 //--------------------------------------------------------------------------------------------------------
 public BIG_summon(id)
 {
	if ( gHasBIGPowers[id] && is_user_alive(id) )
	{
		{
			new cmd[128]
			format(cmd, 127, "monster bigmomma #%i", (id) )
			server_cmd(cmd)
		}

	}
	return PLUGIN_HANDLED
 }
 //--------------------------------------------------------------------------------------------------------
