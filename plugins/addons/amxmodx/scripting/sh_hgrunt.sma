 #include <amxmod.inc>
 #include <xtrafun>
 #include <superheromod.inc>

 // Bigmomma - modded  from hgrunt by Emp
 // hgrunt Created by litovietboi & [SIN]
 // Credits goes to Freecode for helping with keydown.

 //Bigmomma CVARS
 // big_level 7 		//level default-7
 // big_cooldown 600 		//cooldown default-600

 //Change These CVARS in monster_skill.cfg in cstrike folder
//sk_hgrunt_health  50
//sk_hgrunt_kick  10
//sk_hgrunt_pellets  5
//sk_hgrunt_gspeed  600
 //
 
 // VARIABLES
 new gHeroName[]="Hgrunt"
 new bool:gHashgruntPowers[SH_MAXSLOTS+1]={false}
 new gPlayerLevels[SH_MAXSLOTS+1]
 //BREAK
 //--------------------------------------------------------------------------------------------------------
 public plugin_init()
 {
	// Plugin Info
	register_plugin("Hgrunt","1.0","[ LiToVietBoi ] & [SiN]")

	if ( isDebugOn() ) server_print("Attempting to create hgrunt Hero")
	register_cvar("hgrunt_level", "8" )
	register_cvar("hgrunt_cooldown", "600")
	shCreateHero(gHeroName, "Spawn a Hgrunt", "Spawn a crazy Hgrunt thing on keydown!", true, "big_level" )


	register_event("ResetHUD","hgrunt_newround","b")
	register_srvcmd("hgrunt_init", "hgrunt_init")
	shRegHeroInit(gHeroName, "hgrunt_init")

	register_srvcmd("hgrunt_levels", "hgrunt_levels")
	shRegLevels(gHeroName,"hgrunt_levels")

	register_srvcmd("hgrunt_kd", "hgrunt_kd")
	shRegKeyDown(gHeroName, "hgrunt_kd")

 }
 //--------------------------------------------------------------------------------------------------------
 public hgrunt_newround(id)
 {
	gPlayerUltimateUsed[id]=false

 }
 //--------------------------------------------------------------------------------------------------------
 public hgrunt_kd()
 {
	// First Argument is an id with Bigmomma Powers!
	new temp[6]
	read_argv(1,temp,5)
	new id=str_to_num(temp)

	if ( gHashgruntPowers[id] && hasRoundStarted() && is_user_alive(id) )
	{
		if ( gPlayerUltimateUsed[id] )
		{
			playSoundDenySelect(id)
			client_print(id,print_chat,"[Hgrunt] You have already spawned a Hgrunt.")
			return PLUGIN_HANDLED
		}
		hgrunt_summon(id)
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
 public hgrunt_init()
 {
	new temp[6]
	// First Argument is an id
	read_argv(1,temp,5)
	new id=str_to_num(temp)

	// 2nd Argument is 0 or 1 depending on whether the id has Bigmomma skills
	read_argv(2,temp,5)
	new hasPowers=str_to_num(temp)

	if ( hasPowers )
	gHashgruntPowers[id]=true
	else
	gHashgruntPowers[id]=false
 }
 //--------------------------------------------------------------------------------------------------------
 public hgrunt_levels()
 {
	new id[5]
	new lev[5]

	read_argv(1,id,1)
	read_argv(2,lev,1)

	gPlayerLevels[str_to_num(id)]=str_to_num(lev)
 }
 //--------------------------------------------------------------------------------------------------------
 public hgrunt_summon(id)
 {
	if ( gHashgruntPowers[id] && is_user_alive(id) )
	{
		{
			new cmd[128]
			format(cmd, 127, "monster hgrunt #%i", (id) )
			server_cmd(cmd)
		}

	}
	return PLUGIN_HANDLED
 }
 //--------------------------------------------------------------------------------------------------------
