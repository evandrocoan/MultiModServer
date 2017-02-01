 #include <amxmod.inc>
 #include <xtrafun>
 #include <superheromod.inc>

 // Bigmomma - modded  from houndeye by Emp
 // houndeye Created by litovietboi & [SIN]
 // Credits goes to Freecode for helping with keydown.

 //Bigmomma CVARS
 // big_level 7 		//level default-7
 // big_cooldown 600 		//cooldown default-600

 //Change These CVARS in monster_skill.cfg in cstrike folder
//sk_houndeye_health  20
//sk_houndeye_dmg_blast  15
 //
 
 // VARIABLES
 new gHeroName[]="Houndeye"
 new bool:gHashoundeyePowers[SH_MAXSLOTS+1]={false}
 new gPlayerLevels[SH_MAXSLOTS+1]
 //BREAK
 //--------------------------------------------------------------------------------------------------------
 public plugin_init()
 {
	// Plugin Info
	register_plugin("Houndeye","1.0","[ LiToVietBoi ] & [SiN]")

	if ( isDebugOn() ) server_print("Attempting to create houndeye Hero")
	register_cvar("houndeye_level", "8" )
	register_cvar("houndeye_cooldown", "600")
	shCreateHero(gHeroName, "Spawn a Houndeye", "Spawn a crazy Houndeye thing on keydown!", true, "big_level" )


	register_event("ResetHUD","houndeye_newround","b")
	register_srvcmd("houndeye_init", "houndeye_init")
	shRegHeroInit(gHeroName, "houndeye_init")

	register_srvcmd("houndeye_levels", "houndeye_levels")
	shRegLevels(gHeroName,"houndeye_levels")

	register_srvcmd("houndeye_kd", "houndeye_kd")
	shRegKeyDown(gHeroName, "houndeye_kd")

 }
 //--------------------------------------------------------------------------------------------------------
 public houndeye_newround(id)
 {
	gPlayerUltimateUsed[id]=false

 }
 //--------------------------------------------------------------------------------------------------------
 public houndeye_kd()
 {
	// First Argument is an id with Bigmomma Powers!
	new temp[6]
	read_argv(1,temp,5)
	new id=str_to_num(temp)

	if ( gHashoundeyePowers[id] && hasRoundStarted() && is_user_alive(id) )
	{
		if ( gPlayerUltimateUsed[id] )
		{
			playSoundDenySelect(id)
			client_print(id,print_chat,"[Houndeye] You have already spawned a Houndeye.")
			return PLUGIN_HANDLED
		}
		houndeye_summon(id)
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
 public houndeye_init()
 {
	new temp[6]
	// First Argument is an id
	read_argv(1,temp,5)
	new id=str_to_num(temp)

	// 2nd Argument is 0 or 1 depending on whether the id has Bigmomma skills
	read_argv(2,temp,5)
	new hasPowers=str_to_num(temp)

	if ( hasPowers )
	gHashoundeyePowers[id]=true
	else
	gHashoundeyePowers[id]=false
 }
 //--------------------------------------------------------------------------------------------------------
 public houndeye_levels()
 {
	new id[5]
	new lev[5]

	read_argv(1,id,1)
	read_argv(2,lev,1)

	gPlayerLevels[str_to_num(id)]=str_to_num(lev)
 }
 //--------------------------------------------------------------------------------------------------------
 public houndeye_summon(id)
 {
	if ( gHashoundeyePowers[id] && is_user_alive(id) )
	{
		{
			new cmd[128]
			format(cmd, 127, "monster houndeye #%i", (id) )
			server_cmd(cmd)
		}

	}
	return PLUGIN_HANDLED
 }
 //--------------------------------------------------------------------------------------------------------
