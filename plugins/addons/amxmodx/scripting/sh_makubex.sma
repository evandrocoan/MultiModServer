 #include <amxmod.inc>
 #include <xtrafun>
 #include <superheromod.inc>
 #include <Vexd_Utilities>
 #include <fakemeta>

 // Tentacle - modded  from Agrunt by Emp
 // Tentacle - modded  from Agrunt by Emp
 // Agrunt Created by litovietboi & [SIN]
 // Credits goes to Freecode for helping with keydown.

 //makubex CVARS
 // makubex_level 42 		//level default-7
 // makubex_cooldown 20 		//cooldown default-600
 // makubex_speed 5000
 // makubex_traillength 25 
 // makubex_showteam 1
 // makubex_showenemy 1
 // makubex_refreshtimer 5.0

 //Change These CVARS in monster_skill.cfg in cstrike folder
 // sk_tentacle_health 180 	//health of the tentacle default-180
 // sk_tentacle_dmg_bite 1000000 //dmg of bit default-1000000

 // VARIABLES
new gHeroName[]="Makubex"
new bool:gHasMakubexPowers[SH_MAXSLOTS+1]={false}
new gPlayerLevels[SH_MAXSLOTS+1]
new g_spriteLaserBeam
new bool:NoTarget[SH_MAXSLOTS+1]
new CvarRadius
new dice1[33] = 0
new dice2[33] = 0
new dice3[33] = 0
new dice4[33] = 0
new dice5[33] = 0

#define giveTotal 1
new weapArray[giveTotal][24] = {
	"weapon_m249"
}

//BREAK //--------------------------------------------------------------------------------------------------------
public plugin_init()
{
	// Plugin Info
	register_plugin("MakubeX","1.0","D4rkSh4cl0w")

	if ( isDebugOn() ) server_print("Attempting to create Tentacle Hero")
	register_cvar("makubex_level", "42" )
	register_cvar("makubex_cooldown", "5")
	register_cvar("makubex_traillength", "25" )
	register_cvar("makubex_showteam", "0" )
	register_cvar("makubex_showenemy", "1" )
	register_cvar("makubex_refreshtimer", "5.0" )
	register_cvar("makubex_chance", "0.5" )
	register_cvar("makubex_speed", "800" )
	shCreateHero(gHeroName, "The Cyber Lord of Hacking", "Create a random virtual illusion and get a SUPER MACHINE-GUN", true, "makubex_level" )

	//Ignore this
	CvarRadius = register_cvar("makubex_radius", "99999" )

	register_event("DeathMsg","death","a")
	register_event("ResetHUD","makubex_newround","b")
	register_srvcmd("makubex_init", "makubex_init")
	shRegHeroInit(gHeroName, "makubex_init")

	register_srvcmd("MAKUBEX_levels", "MAKUBEX_levels")
	shRegLevels(gHeroName,"MAKUBEX_levels")

	register_srvcmd("makubex_kd", "makubex_kd")
	shRegKeyDown(gHeroName, "makubex_kd")
	
	// Let Server know about Tutorials Variable
	// It is possible that another hero has more hps, less gravity, or more armor
	// so rather than just setting these - let the superhero module decide each round
	shSetMaxSpeed(gHeroName, "makubex_speed", "[0]" )
	
	//Hook the events
	register_event("ResetHUD","newRound","b")
	register_event("Damage", "makubex_damage", "b", "2!0")
	register_event("CurWeapon", "weaponChange","be","1=1")
}
 //--------------------------------------------------------------------------------------------------------
 public makubex_newround(id)
{
  if (!is_user_connected(id)) return PLUGIN_HANDLED
  gPlayerUltimateUsed[id]=false
  dice1[id] = 0
  dice2[id] = 0
  dice3[id] = 0
  dice4[id] = 0
  dice5[id] = 0
  return PLUGIN_CONTINUE
}
//--------------------------------------------------------------------------------------------------------
public makubex_kd()
{
  // First Argument is an id with Gamblor Powers!
  new temp[6]
  read_argv(1,temp,5)
  new id=str_to_num(temp)

  if ( gHasMakubexPowers[id] && hasRoundStarted())
  {
    if ( gPlayerUltimateUsed[id] )
    {
    playSoundDenySelect(id)
    return PLUGIN_HANDLED
    }
    makubex_diceroll(id)
    client_print(id,print_chat,"[Makubex] Attempting to create a virtual illusion...")
    }else{
    }

  return PLUGIN_HANDLED
}
//----------------------------------------------------------------------------------------------
public plugin_precache()
{
	precache_sound("ambience/port_suckin1.wav")
	precache_model("models/shmod/v_m249.mdl")
	g_spriteLaserBeam = precache_model("sprites/laserbeam.spr")
}
//--------------------------------------------------------------------------------------------------------
public makubex_init()
{
	new temp[6]
	// First Argument is an id
	read_argv(1,temp,5)
	new id=str_to_num(temp)

	// 2nd Argument is 0 or 1 depending on whether the id has Tentacle skills
	read_argv(2,temp,5)
	new hasPowers=str_to_num(temp)

	if ( hasPowers )
	gHasMakubexPowers[id]=true
	else
	gHasMakubexPowers[id]=false
			
	//Clear out any stale tasks
	remove_task(id)

	if ( hasPowers ) {
		set_task(get_cvar_float("makubex_refreshtimer"),"trailMoveCheck", id, "", 0, "b")
	}
	//This gets run if they had the power but don't anymore
	else if (gHasMakubexPowers[id]) {
		removeAllMarks(id)
	}

	//Sets this variable to the current status
	gHasMakubexPowers[id] = (hasPowers != 0)
	
	if (is_user_connected(id))
	dice1[id] = 0
	dice2[id] = 0
	dice3[id] = 0
	dice4[id] = 0
	dice5[id] = 0
}
//--------------------------------------------------------------------------------------------------------
public MAKUBEX_levels()
{
	new id[5]
	new lev[5]

	read_argv(1,id,1)
	read_argv(2,lev,1)

	gPlayerLevels[str_to_num(id)]=str_to_num(lev)
}
//--------------------------------------------------------------------------------------------------------
 public makubex_damage(id)
{
    if (!shModActive() || !is_user_alive(id)) return PLUGIN_CONTINUE

    new weapon, bodypart, attacker = get_user_attacker(id, weapon, bodypart)

    if ( attacker <= 0 || attacker > SH_MAXSLOTS ) return PLUGIN_CONTINUE

    if ( gHasMakubexPowers[attacker] && weapon == CSW_M249 && is_user_alive(attacker) && is_user_alive(id) && (id!=attacker) ) {
      new randNum = random_num(0, 100)
      if (get_cvar_float("makubex_chance") * 100 >= randNum) {
		shExtraDamage(id, attacker, get_user_health(id), "Assassination" )		
      }
    }
    return PLUGIN_CONTINUE
}
//----------------------------------------------------------------------------------------------
public removeAllMarks(id)
{
	new players[32], n

	if ( is_user_connected(id) && gHasMakubexPowers[id] )  {
		get_players(players, n, "a")
		for ( new p = 0; p < n; p++ ) {
			if ( players[p] == id ) continue
			removeMark(id,players[p])
		}
	}
}
//----------------------------------------------------------------------------------------------
public removeMark(id, pid)
{
	if ( !is_user_connected(id) ) return
	message_begin(MSG_ONE, SVC_TEMPENTITY, {0,0,0}, id)
	write_byte(99)
	write_short(pid)
	message_end()
}
//----------------------------------------------------------------------------------------------
public addAllMarks(id)
{
	new players[32], n
	new bool:sameTeam
	new bool:showTeam
	new bool:showEnemy

	if ( is_user_alive(id) && gHasMakubexPowers[id] )  {

		showTeam = ( get_cvar_num("makubex_showteam") != 0 )
		showEnemy =( get_cvar_num("makubex_showenemy") != 0 )

		get_players(players, n, "a")
		for ( new p = 0; p < n; p++ ) {

			if ( players[p] == id ) continue
			sameTeam = ( get_user_team(id)==get_user_team(players[p]) )

			if ( (sameTeam && showTeam) || (!sameTeam && showEnemy) )
			addMark(id,players[p])
		}
	}
}
//----------------------------------------------------------------------------------------------
public addMark(id, pid)
{
	if ( !is_user_alive(pid) ) return

	removeMark(id, pid)
	if ( get_user_team(pid) == 1 ) {
		make_trail(id, pid, 255, 0, 0, g_spriteLaserBeam)
	}
	if ( get_user_team(pid) == 2 ) {
		make_trail(id, pid, 0, 0, 255, g_spriteLaserBeam)
	}
}
//----------------------------------------------------------------------------------------------
public make_trail(id, markid, iRed, iGreen, iBlue, spr)
{
	if ( id == markid ) return

	if ( !is_user_alive(id) ) return
	message_begin(MSG_ONE, SVC_TEMPENTITY, {0,0,0}, id)
	write_byte(22)
	write_short(markid)
	write_short(spr)
	write_byte(get_cvar_num("makubex_traillength") ) //length
	write_byte(8)      //width
	write_byte(iRed)   //red
	write_byte(iGreen) //green
	write_byte(iBlue)  //blue
	write_byte(150)    //bright
	message_end()
}
//----------------------------------------------------------------------------------------------
public trailMoveCheck(id)
{
	addAllMarks(id)    // Refresh the Marks...
}
//----------------------------------------------------------------------------------------------
public death()
{
	if (!shModActive() ) return

	new victim_id = read_data(2)
	removeAllMarks(victim_id)
}
//----------------------------------------------------------------------------------------------
public newRound(id)
{
	if ( is_user_alive(id) && gHasMakubexPowers[id] )  {
		addAllMarks(id)
	}
	if ( gHasMakubexPowers[id] && is_user_alive(id) && shModActive() ) {
	set_task(0.1, "makubex_giveweapons",id)
	gPlayerUltimateUsed[id] = false
	}
}
//----------------------------------------------------------------------------------------------
public client_disconnect(id)
{
	// stupid check but lets see
	if ( id <= 0 || id > SH_MAXSLOTS ) return

	// Yeah don't want any left over residuals
	remove_task(id)
}
//----------------------------------------------------------------------------------------------
public makubex_diceroll(id)
{
  if(!is_user_alive(id)) return PLUGIN_HANDLED
  if ( gPlayerUltimateUsed[id] ) return PLUGIN_HANDLED

  if ( !gPlayerUltimateUsed[id] )
  {
    ultimateTimer(id, get_cvar_num("makubex_cooldown") * 1.0)
    new diceroll = random_num(1,25)
    set_hudmessage(id, 100, 200, 0.05, 0.65, 2, 0.02, 4.0, 0.01, 0.1, 2)
    
    if (diceroll == 1) {
       if (dice1[id] > 0) {
              show_hudmessage(id,"You already created Apache virtual illusion!")
              gPlayerUltimateUsed[id]=false
              return PLUGIN_HANDLED
       }else{ 
         dice1[id] = 1
         APACHE_summon(id)
         show_hudmessage(id,"You have created Apache virtual illusion!")
        }
       return PLUGIN_HANDLED
      }
    if (diceroll == 2) {
       if (dice2[id] > 0) {
              show_hudmessage(id,"You already created Human Grunt virtual illusion!")
              gPlayerUltimateUsed[id]=false
              return PLUGIN_HANDLED
       }else{ 
         dice2[id] = 1
         HGRUNT_summon(id)
         show_hudmessage(id,"You have created Human Grunt virtual illusion!")
       }
       return PLUGIN_HANDLED
      }
    if (diceroll == 3) {
       if (dice3[id] > 0) {
              show_hudmessage(id,"You already created Assassin virtual illusion!")
              gPlayerUltimateUsed[id]=false
              return PLUGIN_HANDLED
       }else{ 
         dice3[id] = 1
         ASSASSIN_summon(id)
         show_hudmessage(id,"You have created Assassin virtual illusion!")
        }
       return PLUGIN_HANDLED
       }
    if (diceroll == 4) {
       if (dice4[id] > 0) {
              show_hudmessage(id,"You already created Barney virtual illusion!")
              gPlayerUltimateUsed[id]=false
              return PLUGIN_HANDLED
       }else{ 
         dice4[id] = 1
         BARNEY_summon(id)
         show_hudmessage(id,"You have created Barney virtual illusion!")
          }
       return PLUGIN_HANDLED
       }
    if (diceroll == 5) {
       if (dice5[id] > 0) {
              show_hudmessage(id,"You already created Alien Boss virtual illusion!")
              gPlayerUltimateUsed[id]=false
              return PLUGIN_HANDLED
       }else{ 
         dice5[id] = 1
         BIGMOMMA_summon(id)
         show_hudmessage(id,"You have created Alien Boss virtual illusion!")
          }
       return PLUGIN_HANDLED
       }
    return PLUGIN_HANDLED
    }
  return PLUGIN_HANDLED
}      
//----------------------------------------------------------------------------------------------       
public APACHE_summon(id)
{
	if ( !shModActive() || !is_user_alive(id) || !gHasMakubexPowers[id] )
		return

	new distance, aimOrigin[3], vicOrigin[3], radius[SH_MAXSLOTS+1]
	new players[SH_MAXSLOTS], pnum, victim, targetid
	new idTeam = get_user_team(id)

	radius[id] = get_pcvar_num(CvarRadius)

	get_user_origin(id, aimOrigin, 3)

	get_players(players, pnum, "a")

	// Find the closest target to aim location, and make sure monster can spawn on them
	for (new i = 0; i < pnum; i++)
	{
		victim = players[i]

		if ( !is_user_alive(victim) || idTeam  == get_user_team(victim) )
			continue

		get_user_origin(victim, vicOrigin)

		distance = get_distance(vicOrigin, aimOrigin)

		if ( distance < radius[id] )
		{
			if ( pev(victim, pev_flags) & FL_NOTARGET )
			{
				NoTarget[id] = true
				continue
			}

			radius[id] = distance
			targetid = victim
		}
	}

	if ( targetid && is_user_alive(targetid) )
	{
		emit_sound(id, CHAN_STATIC, "ambience/port_suckin1.wav", 1.0, ATTN_NORM, 0, PITCH_NORM)
		emit_sound(targetid, CHAN_STATIC, "ambience/port_suckin1.wav", 1.0, ATTN_NORM, 0, PITCH_NORM)

		new targetName[32]
		get_user_name(targetid, targetName, 31)

		server_cmd("monster apache #%i", targetid)

		NoTarget[id] = false
	}
	else
	{
		switch(NoTarget[id])
		{
			case false:
			{
				server_cmd("monster apache #%i", id)
			}

			case true:
			{
				makubex_diceroll(id)
				NoTarget[id] = false
			}
		}
	}
}
//--------------------------------------------------------------------------------------------------------
public HGRUNT_summon(id)
{
	if ( gHasMakubexPowers[id] && is_user_alive(id) )
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
public BARNEY_summon(id)
{
	if ( gHasMakubexPowers[id] && is_user_alive(id) )
	{
		{
			new cmd[128]
			format(cmd, 127, "monster barney #%i", (id) )
			server_cmd(cmd)
		}

	}
	return PLUGIN_HANDLED
}
//--------------------------------------------------------------------------------------------------------
public ASSASSIN_summon(id)
{
	if ( gHasMakubexPowers[id] && is_user_alive(id) )
	{
		{
			new cmd[128]
			format(cmd, 127, "monster hassassin #%i", (id) )
			server_cmd(cmd)
		}

	}
	return PLUGIN_HANDLED
}
//--------------------------------------------------------------------------------------------------------
public BIGMOMMA_summon(id)
{
	if ( gHasMakubexPowers[id] && is_user_alive(id) )
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
public switchmodel(id)
{
	if ( !is_user_alive(id) || !gHasMakubexPowers[id] ) return
	new clip, ammo, wpnid = get_user_weapon(id,clip,ammo)
	if (wpnid == CSW_M249) {
		// Weapon Model change thanks to [CCC]Taz-Devil
		Entvars_Set_String(id, EV_SZ_viewmodel, "models/shmod/v_m249.mdl")
	}
}
//----------------------------------------------------------------------------------------------
public weaponChange(id)
{
	if ( !gHasMakubexPowers[id] || !shModActive() ) return

	//new clip, ammo, wpnid = get_user_weapon(id,clip,ammo)
	new wpnid = read_data(2)

	if ( wpnid == CSW_M249 ) switchmodel(id)
}
//----------------------------------------------------------------------------------------------
public makubex_giveweapons(id)
{
	if ( !is_user_alive(id) ) return

	for (new x = 0; x < giveTotal; x++) {
		shGiveWeapon(id, weapArray[x])
	}
}
//----------------------------------------------------------------------------------------------
public makubex_dropweapons(id)
{
	if( !is_user_alive(id) || !shModActive() ) return

	for (new x = 0; x < giveTotal; x++) {
		engclient_cmd(id,"drop", weapArray[x])
	}

	new iCurrent = -1
	new Float:weapvel[3]

	while ( (iCurrent = find_ent_by_class(iCurrent, "weaponbox")) > 0 ) {
		//Skip anything not owned by this client
		if( entity_get_edict(iCurrent, EV_ENT_owner) != id) continue
		
		//Get Weapon velocites
		entity_get_vector(iCurrent, EV_VEC_velocity, weapvel)
		if (weapvel[0] == 0.0 && weapvel[1] == 0.0 && weapvel[2] == 0.0) continue
		
		remove_entity(iCurrent)
	}
}
//----------------------------------------------------------------------------------------------
