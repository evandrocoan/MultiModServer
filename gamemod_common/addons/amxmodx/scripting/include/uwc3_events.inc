
/** *************************************************************************
*** AMXX Plugin:   Ultimate Warcraft3 (UWC3)
*** Plugin Author: K2mia
*** UWC3 Module:   Event Handlers 
*** Date:          May 25, 2004
*** Last Update:   September 28, 2004
*
*  Module: Event Handlers 
*  Subroutines for handling events not handled in more specific modules 
*----------------------------------------------------------------------------
*
*  UWC3 is written exclusively for AMX Mod X
*
*  Ultimate Warcraft3 Dev. Team
*  ------------------------------
*   Small scripting:  K2mia ( Andrew Cowan ) < admin@mudconnect.com >
*   Graphics:         steve french < garbageweed@hotmail.com >
*   Website Design:   Jim Rhoades < jim@radzone.org >
*
*  str_break() routine provided by BAILOPAN from AMXX0.20 to replace parse()
*  ultimate_decoy() code derived from code for Beyonder superhero (Freecode/Asskicr)
*    some decoy concepts from AMXX forums posts by jjkiller
*
****************************************************************************/


// **************************************************************************
// BEGIN Event Handler Subroutine Declarations
// **************************************************************************


// **************************************************************************
// BEGIN game_commencing subroutine
// The game is beginning
// **************************************************************************
public game_commencing(){
   new players[32], numplayers, id
   get_players(players, numplayers)

   for (new i=0; i<numplayers; i++){
      id=players[i]
      game_commence[id]=true
   }
}
// **************************************************************************
// END game_commencing subroutine
// **************************************************************************


// **************************************************************************
// BEGIN restart_round subroutine
// Called when round restarts
// **************************************************************************
public restart_round(){
   if (!warcraft3)
      return PLUGIN_CONTINUE

   new players[32]
   new numplayers
   new id
   get_players(players, numplayers)

   //write_all()        // For saving xp info!

   //client_print(0, print_console, "UWC3-DEBUG: In restart_round!")

   for (new i=0; i<numplayers; i++){
      // Iterate over all players and initialize player data
      id = players[i]
      playeritem[id] = 0
      playeritem2[id] = 0
      he[id]=0
      threwnapalm[id]=0
      flashg[id]=0
      diedlastround[id]=false

      if (get_cvar_num("mp_savexp")==0){
         p_level[id]=0          // Set player to level 0

         if (get_cvar_num("UW_DEBUG_code"))
            playerxp[id]= DEBUG_STARTXP // Set player starting XP to DEBUG value
         else
            playerxp[id]= 0             // Set player starting XP to 0

         for (new j=0; j<MAX_SKILLS; j++)
            p_skills[id][j]=0   // Set all skills to 0
      }
   }

   return PLUGIN_CONTINUE
}
// **************************************************************************
// END restart_round subroutine
// **************************************************************************


// **************************************************************************
// BEGIN new_round subroutine
// Called when a new round begins
// **************************************************************************
public new_round(id){
   new origin[3]
   new name[32]

   if (warcraft3==false)
      return PLUGIN_CONTINUE

   if ((id <= 0) || (id > MAX_PLAYERS))
      return PLUGIN_CONTINUE

   if ( !is_user_connected( id ) )
      return PLUGIN_CONTINUE

   bombstate = BOMB_NOTPLANTED

   if(game_commence[id]){
      playeritem[id] = 0
      playeritem2[id] = 0
      diedlastround[id]=false
      game_commence[id]=false

      // Reset spawn sites internally
      //client_print(0, print_console, "Resetting Spawn sites")
      for (new i=0; i<MAX_PLAYERS; i++){
         Tspawnpts[i] = {0,0,0}
         CTspawnpts[i] = {0,0,0}
      }
   }


   if (get_cvar_num("UW_DEBUG") == 5){
      // Added special debug info dump
      new mapname[32]
      get_mapname(mapname,31)
      new pname[32]
      get_user_name(id, pname, 31)

      new skillcount = get_skillcount( id ) 
      new acount = get_attribcount( id )
      new rcount = get_resistcount( id )

      new apts = get_availattribpts( id )
      new rpts = get_availresistpts( id )

      log_amx( "DEBUG #1: Mapname=(%s) Player=(%s) Level=(%d) #Skills=(%d) XP=(%d)",
         mapname, pname, p_level[id], skillcount, playerxp[id] )
      log_amx( "DEBUG #2: Server Max_Attribs=(%d) Apts_spent=(%d) Apts_left=(%d)",
         ATTRIB_MAX_PTS, acount, apts)
      log_amx( "DEBUG #3: Server Max_Resists=(%d) Rpts_spent=(%d) Rpts_left=(%d)",
         RESIST_MAX_PTS, rcount, rpts)
   }


   // [09-13-04] Fix for Voodoo missing end_round task check - K2mia
   if (task_exists(4500+id)){  // Resets godmode
      remove_task(4500+id)

      //client_print(0, print_console, "new_round: task exists 4500 + %d", id)

      set_user_health_log(id, maxhealth[id], true, "reset_godmode() from new_round()")

      hasgodmode[id]=false
      set_hudmessage(0, 100, 0, 0.05, 0.75, 2, 0.02, 10.0, 0.01, 0.1, 2)
      show_hudmessage(id,"Your Voodoo has been reset")
   }

   // [09-24-04] Added check for # skill points being in sync with player level - K2mia
   if ( get_cvar_num("UW_round_check") ){
      new pname[32]
      get_user_name(id, pname, 31)

      new skillcount = get_skillcount( id ) 

      if ( skillcount > p_level[id] ){
         client_print(id, print_chat,
            "[%s] You have spent too many skillpoints, skills reset forced.", MOD)
         log_amx("TOO MANY SKILLPOINTS: (%s) level=(%d) skillcount=(%d)",
            pname, p_level[id], skillcount)

         for (new j=0; j<MAX_SKILLS; j++)
            p_skills[id][j] = 0 // Set all skills to 0

         ultlearned[id] = 0
         displaylevel(id, 3)

         if (get_cvar_num("mp_sql")){
            sqlwrite_skills_id( id, -1, 1)
         }else{
            write_skills_id( id, 1 )
         }
      }
   }
   // [09-24-04] End of Added check for # skill points being in sync with player level

   // Free this mole spawn position for use this round
   MOLEspawnpts[id] = 0

   if(get_cvar_num("FT_competitive") && !buycalled){
      set_task(get_cvar_float("mp_buytime")*60.0,"set_buytime",899)
      buycalled = true
   }

   icon_controller(id,ICON_HIDE)
   deathmessageshown[id] = false
   to_be_revived[id] = false
   vengeance_state[id] = VENG_READY

   if (get_cvar_num("UW_dmgxpbonus"))
      for (new i=0; i < MAX_PLAYERS; i++){
         damageto[id][i] = -1
      }

   if (get_cvar_num("mp_savexp") && xpreadytoload[id]){
      if ( get_cvar_num("mp_sql") ){
         sqlget_xp_id(id)
         sqlget_enh_id(id)
         sqlget_skills_id(id)
      }else{
         get_xp_id(id)
         get_skills_id(id, 1)
         get_enh_id(id)
      }
      xpreadytoload[id] = 0
   }

   if (!get_cvar_num("mp_savexp")){
      set_hudmessage(200, 100, 0, -1.0, 0.35, 0, 1.0, 15.0, 0.1, 0.2, 2)
      show_hudmessage(id, "Server Mode: Fast XP -- Long Term XP is Disabled")
   }

   if (get_cvar_num("UW_DEBUG_code"))
      cs_set_user_money( id, DEBUG_CASH )


   // Store spawn pt for use with mole
   get_user_name(id, name, 31)
   get_user_origin(id, origin)
   if (get_user_team(id) == TEAM_T){
      for (new i=0; i<MAX_PLAYERS; i++){
         if ((Tspawnpts[i][0] + Tspawnpts[i][1] + Tspawnpts[i][2]) == 0){
            Tspawnpts[i] = origin
            break
         }
      }
   }else{
      for (new i=0; i<MAX_PLAYERS; i++){
         if ((CTspawnpts[i][0] + CTspawnpts[i][1] + CTspawnpts[i][2]) == 0){
            CTspawnpts[i] = origin
            break
         }
      }
   }

   //client_print(0, print_console, "%s has spawned a %s at < %d %d %d>", name, ( (get_user_team(id) == TEAM_T) ? "Terrorist" : "CT" ), origin[0], origin[1], origin[2])


   if (playerhasspawned[id]){

      if (p_skills[id][SKILLIDX_SERPWARD]){
         // Serpent Ward
         serpents[id] = p_serpent[p_skills[id][SKILLIDX_SERPWARD]-1]
         if (USE_ENH && (p_attribs[id][ATTRIBIDX_INT] >= INT_SERPENT_LEVEL)){
            serpents[id] += INT_SERPENT_BONUS
            if (get_cvar_num("UW_DEBUG") == 1){
               client_print(id, print_console,
                  "[%s DEBUG] Intellect-SerpWard #=(%d)", MOD, serpents[id])
            }
         }
      }else{
         serpents[id] = 0
      }

      if(!freezetime && !ultimateused[id])
         icon_controller(id,ICON_SHOW)

      if(stunned[id] || slowed[id])
         set_user_maxspeed(id,240.0)

      if(playeritem2[id]!=MOLE)
         playeritem2[id]=0

      playeritem[id]=0
      changeskin(id,1)
      displaylevel(id,3)
      return PLUGIN_CONTINUE
   }

   if (hasmole[id] && playeritem2[id] != MOLE)
      playeritem2[id] = MOLE

   u_delay = false
   if (get_cvar_num("FT_ultimatedelay")){
      u_delay = true
      if (!task_exists(12385))
         set_task(get_cvar_float("FT_ultimatedelay"), "udelay_cooldown", 12385)
   }


   if (task_exists(357))
      // Stops the medic sprite display
      remove_task(357)
   if (task_exists(358))
      // Stops the monitor_players routine
      remove_task(358)
   if (task_exists(200+id))
      // Stops any ultimates from continuing when the new round starts
      remove_task(200+id)
   if (task_exists(id+500))
      // Stop any cooldowns in effect
      remove_task(500+id)
   if (task_exists(id+645))
      // Remove bomb count down
      remove_task(645+id)


   // [09-03-04] - Display the medic alert sprites - K2mia
   if (get_cvar_num("UW_medicalerts") == 2)
      set_task(1.0, "draw_medicspr", 357)

   // [09-24-04] - Added check for insane amounts of player health
   set_task(1.0, "monitor_players", 358)

   buytime=true
   checkmap()
   new parm[2]
   parm[0]=id

   if (freezecalled==0){
      freezetime = 1
      freezecalled = 1
   }

   if(get_cvar_num("FT_blinkstartdisabled")){
      blinkdelayed[id]=true
      set_task(get_cvar_float("FT_blink_delay"),"cooldown2",50 + id,parm,1)
   }

   if (get_cvar_num("FT_warn_suicide"))
      suicideAttempt[id] = 0

   if ( is_user_connected( id ) ){
      set_user_maxspeed(id, 1.0)

      if ( playeritem2[id]==HELM)
         set_user_hitzones(0,id,253)
   }

   set_task(0.1, "weapon_controller", 10091, parm, 2) // Weapon Reincarnation

   init_pdata( id, 1 )		// Perform a Limited init of player data
   
   endround = false		// New round, reset endround state
   hostagesaver = 0		// Reset hostagesaver state

   // Checks skills
   check_skills( id, true)	// Check skill affects, set user health
   check_fan( id )		// Chec for Fan of Knives


   if (get_cvar_num("FT_reset_skills")){
      if (resetskill[id]) {
         for (new j=0; j<MAX_SKILLS; j++)
            p_skills[id][j] = 0 // Set all skills to 0

         p_level[id] = 0
         ultlearned[id] = 0
         resetskill[id] = false
         displaylevel(id, 3)
      }
      // [08-04-04] - Added check for resetting attribs/resists - K2mia
      if (resetattrib[id]) {
         for (new j=0; j<MAX_ATTRIBS; j++)
            p_attribs[id][j] = ATTRIB_BASE // Set all attributes to the default
         resetattrib[id] = false
      }
      if (resetresist[id]) {
         for (new j=0; j<MAX_RESISTS; j++)
            p_resists[id][j] = 0 // Set all resistances to 0
         resetresist[id] = false
      }
      if (reloadskill[id]) {
         for (new j=0; j<MAX_SKILLS; j++)
            p_skills[id][j]=0   // Set all skills to 0

         ultlearned[id] = 0
         reloadskill[id]=false

         get_skills_id(id, 1)

         displaylevel(id, 3)
      }
   }

   vengeance_used[id] = 0

   new acount = get_attribcount( id )
   new apts = get_availattribpts( id )
   new rcount = get_resistcount( id )
   new rpts = get_availresistpts( id )

   if ((apts > 0) && (acount < ((MAX_ATTRIBS-1) * (ATTRIB_MAX_VALUE - ATTRIB_BASE))) &&
       (acount < ATTRIB_MAX_PTS) )
   {
      select_attrib(id)
   }else if ((rpts > 0) && (rcount < ((MAX_RESISTS-1) * RESIST_MAX_VALUE)) &&
             (rcount < RESIST_MAX_PTS) )
   {
      select_resist(id)
   }else{
      // Determine if player has skills that can be learned
      new skillptsavail = get_availskillpts( id )

      if ( skillptsavail )
         select_skill(id, 1)
   }

   return PLUGIN_CONTINUE

}
// **************************************************************************
// END new_round subroutine
// **************************************************************************


// **************************************************************************
// BEGIN end_round subroutine
// Handler for the end of a round event
// **************************************************************************
public end_round(){

   if (!warcraft3)
     return PLUGIN_CONTINUE

   endround=true
   buycalled=false
   new players[32]
   new numberofplayers
   get_players(players, numberofplayers)
   new y, id

   if(task_exists(899))
      remove_task(899)

   for(y=0;y<MAX_PLAYERS;++y){
      spawnPointsused[y]=false
   }

   for (y = 0; y < numberofplayers; ++y){
      id = players[y]
      if(task_exists(600+id))     // Removes walker (undead changing speed)
         remove_task(600+id)

      if (task_exists(id+90))     // Removes any current healing processes
         remove_task(id+90)

      if (task_exists(id+1100))   // Removes any current con healing proocesses
         remove_task(id+1100)

      if (task_exists(id+1200))   // Removes any leather/steel skin proocesses
         remove_task(id+1200)

      if (task_exists(9000+id))   // Removes undead flashing process
         remove_task(9000+id)

      if (task_exists(50+id))     // Remove any current cooldowns
         remove_task(50+id)

      if (task_exists(1000+id)){
         // Remove any reset_maxspeeds occuring (a person could to move during freezetime
         remove_task(1000+id)
         new parm[2]
         parm[0]=id
         reset_maxspeed(parm)
      }



      if (task_exists(4500+id)){  // Resets godmode
         remove_task(4500+id)

         new parm[2]
         parm[0]=id
         reset_godmode(parm)
      }

      if(is_user_alive(id))
         saveweapons(id)

      spawnedfromitem[id]=false
      playerhasspawned[id]=false

      if(playeritem2[id]!=CHAMELEON)
         changeskin(id,1)

      he[id]=0
      threwnapalm[id]=0
      carrioncount[id]=2
      shadowcount[id]=2
      flashg[id]=0
      ismole[id]=false
      //itemsrunning[id]=true
   }

   freezecalled = 0
   pheonixexistsT=0
   pheonixexistsCT=0

   if (get_cvar_num("mp_savexp"))
      write_all()

   return PLUGIN_CONTINUE
}
// **************************************************************************
// END end_round subroutine
// **************************************************************************



// **************************************************************************
// BEGIN Target_Bombed subroutine
// Handler for the Target_Bombed event
// **************************************************************************
public Target_Bombed(){
   new players[32], numberofplayers
   get_players(players, numberofplayers)
   new id, i, parm[1]

   for (i = 0; i < numberofplayers; ++i){
      id=players[i]
      parm[0]=id
      set_task(0.1,"check_alive",2,parm,1)
   }
}
// **************************************************************************
// END Target_Bombed subroutine
// **************************************************************************


// **************************************************************************
// BEGIN T_win subroutine
// Handler for the T team winning - Rewritten by K2mia 9-22-04
// **************************************************************************
public T_win(){
   if (!warcraft3)
      return PLUGIN_CONTINUE


   new CTnum = count_CT()
   new Tnum = count_T()

   //client_print(0, print_console, "DEBUG: MIH T_win() CTnum=(%d) Tnum=(%d)", CTnum, Tnum)
   //log_amx("DEBUG: MIH T_win() CTnum=(%d) Tnum=(%d)", CTnum, Tnum)

   if((Tnum+CTnum)<get_cvar_num("FT_min_b4_XP"))
      return PLUGIN_HANDLED
   if (Tnum>0 && CTnum>0){}
     else
   return PLUGIN_HANDLED

   new a, players[32], numberofplayers
   get_players(players, numberofplayers)

   for (a = 0; a < numberofplayers; ++a){
      new id = players[a]

      if ( get_user_team(id) == TEAM_T ){
         new temp = (ROUNDXP+xpgiven_lev[p_level[players[a]]])
         if (get_cvar_num("FT_objectives")){
            new sName[32]
            get_user_name(players[a],sName,31)
            client_print(players[a],print_chat,
               "[%s] %s recieved %d XP for winning the round",MOD,sName,temp)
         }
         playerxp[players[a]]+=temp
         displaylevel(players[a],3)
      }
   }

   return PLUGIN_CONTINUE
}
// **************************************************************************
// END T_win subroutine
// **************************************************************************


// **************************************************************************
// BEGIN CT_win subroutine
// Handler for the CT team winning - Rewritten by K2mia 9-22-04
// **************************************************************************
public CT_win(){
   if (!warcraft3)
      return PLUGIN_CONTINUE


   new CTnum = count_CT()
   new Tnum = count_T()

   //client_print(0, print_console, "DEBUG: MIH CT_win() CTnum=(%d) Tnum=(%d)", CTnum, Tnum)
   //log_amx("DEBUG: MIH CT_win() CTnum=(%d) Tnum=(%d)", CTnum, Tnum)

   if((Tnum+CTnum)<get_cvar_num("FT_min_b4_XP"))
      return PLUGIN_HANDLED
   if (Tnum>0 && CTnum>0){}
     else
   return PLUGIN_HANDLED

   new a, players[32], numberofplayers
   get_players(players, numberofplayers)

   for (a = 0; a < numberofplayers; ++a){
      new id = players[a]

      if ( get_user_team(id) == TEAM_CT ){
         new temp = (ROUNDXP+xpgiven_lev[p_level[players[a]]])
         if (get_cvar_num("FT_objectives")){
            new sName[32]
            get_user_name(players[a],sName,31)
            client_print(players[a],print_chat,
               "[%s] %s recieved %d XP for winning the round",MOD,sName,temp)
         }
         playerxp[players[a]]+=temp
         displaylevel(players[a],3)
      }
   }

   return PLUGIN_CONTINUE
}
// **************************************************************************
// END CT_win subroutine
// **************************************************************************


// **************************************************************************
// BEGIN nade_thrown and hethrowevent subroutines
// Routines for handling nades in Warcraft
// **************************************************************************
public nade_thrown(){
   new parm[2]
   parm[0] = read_data(1)

   //client_print(parm[0], print_console, "[DEBUG] you threw a nade")
   set_task(0.1, "hethrowevent",parm[0])

   return PLUGIN_HANDLED
}

public hethrowevent(id){
   new szModel[64] , grenadeid = 0
   grenadeid = get_grenade(id)

   // [10-05-04] - Check for Valid grenade entity
   if ( !is_valid_ent( grenadeid ) )
      return PLUGIN_CONTINUE

   entity_get_string(grenadeid, EV_SZ_model, szModel, 63)

   new rgb[3]

   if (p_skills[id][SKILLIDX_CRITGREN] && p_skills[id][SKILLIDX_NAPALM])
      rgb = {255, 32, 32}
   else if (p_skills[id][SKILLIDX_CRITGREN])
      rgb = {32, 255, 32}
   else if (p_skills[id][SKILLIDX_NAPALM])
      rgb = {32, 32, 255}

   if (grenadeid && equal(szModel, "models/w_hegrenade.mdl")){
      if ( p_skills[id][SKILLIDX_CRITGREN] || p_skills[id][SKILLIDX_NAPALM] ){
         if ( (playeritem2[id]==INFERNO && get_cvar_num("FT_glove_orc_damage")) ||
              (playeritem2[id]!=INFERNO))
         {
            message_begin( MSG_BROADCAST, SVC_TEMPENTITY )
            write_byte( TE_BEAMFOLLOW )
            write_short(grenadeid) // entity
            write_short(m_iTrail)  // model
            write_byte( 20 )       // life
            write_byte( 10 )       // width
            write_byte( rgb[0] )   // r, g, b
            write_byte( rgb[1] )   // r, g, b
            write_byte( rgb[2] )   // r, g, b
            write_byte( 210 )      // Brightness
            message_end() // move PHS/PVS data sending here (SEND_ALL,SEND_PVS,SEND_PHS)
         }

         /*if (is_running("czero")){
            new parm2[2]
            parm2[0]=id
            parm2[1]=grenadeid
            get_nade_origin(parm2)
         }*/
      }
   }

   return PLUGIN_CONTINUE
}
// **************************************************************************
// END nade_thrown and hethrowevent subroutines
// **************************************************************************


// **************************************************************************
// BEGIN event_player_action subroutine
// Handler for player events (bomb, hostages, etc)
// **************************************************************************
public event_player_action(){

   new sArg[MAX_VAR_LENGTH], sAction[MAX_VAR_LENGTH]
   new sName[MAX_NAME_LENGTH]
   new id, iUserId

   if (!warcraft3)
      return PLUGIN_CONTINUE

   new CTnum = count_CT()
   new Tnum = count_T()

   //client_print(0, print_console, "DEBUG: MIH event_player_action() CTnum=(%d) Tnum=(%d)", CTnum, Tnum)
   //log_amx("DEBUG: MIH event_player_action() CTnum=(%d) Tnum=(%d)", CTnum, Tnum)

   if((Tnum+CTnum)<get_cvar_num("FT_min_b4_XP"))
      return PLUGIN_HANDLED
   if (Tnum>0 && CTnum>0){}
   else
      return PLUGIN_HANDLED

   read_logargv(0,sArg,MAX_VAR_LENGTH)
   read_logargv(2,sAction,MAX_VAR_LENGTH)
   parse_loguser(sArg,sName,MAX_NAME_LENGTH,iUserId)
   id = find_player("k",iUserId)


   //client_print(0, print_console, "DEBUG: MIH event_player_action() id=(%d) iUid=(%d)  sAction=(%s)",id, iUserId, sAction )
   //log_amx("DEBUG: MIH event_player_action() id=(%d) iUid=(%d) sAction=(%s)",id, sAction, iUserId )


   if(id==0) {
      // Prevents the server from gaining XP
      return PLUGIN_CONTINUE
   }

   new temp = 0 // Used for XP gain from objectives

   if (equal(sAction,"Planted_The_Bomb")) {
      // Bomb planted
      new origin[3]
      new teamname[32]
      new player[32]
      new numplayers
      new targetorigin[3]
      new targetid

      get_user_origin(id, origin)
      get_user_team(id, teamname, 31)
      get_players(player, numplayers)
      bombCarrier = 0

      bombstate = BOMB_PLANTED  // Set BOMB_PLANTED state, bomb was planted

      // Used to help reincarnation after dying from bomb
      set_task(get_cvar_num("mp_c4timer")-1.0,"check_for_living",645+id)
      set_task(float(get_cvar_num("mp_c4timer")) + 1.0, "check_for_living2", 645+id)


      if (get_cvar_num("FT_objectives")) {
         temp = 3 * xpgiven_lev[p_level[id]]
         playerxp[id] += temp

         client_print(id, print_chat,
            "[%s] %s recieved %d extra XP for personally planting the bomb.",
            MOD,sName,temp)
      }

      for (new i=0; i<numplayers; ++i){
         targetid=player[i]

         if (get_user_team(targetid) != TEAM_T) continue

         get_user_origin(targetid, targetorigin)

         // [09-27-04] Modified playerlist so now have to check for living status - K2mia
         if ( is_user_alive(targetid) &&
              (get_distance(origin, targetorigin) <= get_cvar_num("FT_xp_radius")) )
         {
            if (get_cvar_num("FT_objectives")){
               temp = BOMBPLANTXP + xpgiven_lev[p_level[targetid]]
               playerxp[targetid]+=  temp

               get_user_name(targetid,sName,31)
               client_print(targetid, print_chat,
                  "[%s] %s recieved %d for supporting the bomb planting effort.",
                  MOD,sName,temp)
            }
         }
      }
      displaylevel(targetid, 1)
   }else if (equal(sAction,"Defused_The_Bomb")) {
      // Bomb defused
      new origin[3]
      new teamname[32]
      new player[32]
      new numplayers
      new targetorigin[3]
      new targetid

      get_user_origin(id, origin)
      get_user_team(id, teamname, 31)
      get_players(player, numplayers)

      bombstate = BOMB_DEFUSED  // Set BOMB_DEFUSED state, bomb was defused


      if (get_cvar_num("FT_objectives")){
         temp = 3 *  xpgiven_lev[p_level[id]]
         playerxp[id] += temp
         client_print(id, print_chat,
            "[%s] %s recieved %d extra XP for defusing the bomb.",MOD,sName,temp)
      }

      for (new i=0; i<numplayers; ++i){
         targetid=player[i]

         if (get_user_team(targetid) != TEAM_CT) continue

         get_user_origin(targetid, targetorigin)

         // [09-27-04] Modified playerlist so now have to check for living status - K2mia
         if ( is_user_alive(targetid) &&
              (get_distance(origin, targetorigin)<=get_cvar_num("FT_xp_radius")) )
         {

            if (get_cvar_num("FT_objectives")){
               temp = DEFUSEXP +  xpgiven_lev[p_level[targetid]]
               playerxp[targetid]+=  temp

               get_user_name(targetid,sName,31)
               client_print(targetid, print_chat,
                  "[%s] %s recieved %d for supporting the bomb defusing effort.",
                  MOD,sName,temp)
            }
         }
         displaylevel(targetid, 1)
      }
   }else if (equal(sAction,"Begin_Bomb_Defuse_With_Kit")) {
      // Bomb defusing with a kit
      if(get_cvar_num("FT_attempt_defuse_bonus")){
         if( (++bombDefuserIndex[id] == 1) && (get_user_team(id) == TEAM_CT) ){

            if (get_cvar_num("FT_objectives")){
               temp = (1/6 * DEFUSEXP) + xpgiven_lev[p_level[id]]
               playerxp[id] += temp

               client_print(id, print_chat,
                  "[%s] %s recieved %d XP for cutting the red wire on the bomb.",
                  MOD,sName,temp)
            }

            displaylevel(id, 1)
         }
      }
   }else if (equal(sAction,"Begin_Bomb_Defuse_Without_Kit")) {
      // Bomb defusing without a kit

      if(get_cvar_num("FT_attempt_defuse_bonus")){
         if( (++bombDefuserIndex[id] == 1) && (get_user_team(id) == TEAM_CT) ){
            if (get_cvar_num("FT_objectives")){
               temp = xpgiven_lev[p_level[id]]
               playerxp[bombdefuser]+=  temp

               client_print(id, print_chat,
                  "[%s] %s recieved %d XP for attempting to defuse bare handed.^n",
                  MOD,id,temp)
            }

            displaylevel(id, 1)
         }
      }
   }else if (equal(sAction,"Spawned_With_The_Bomb")) {
      // Spawned with the bomb
      bombCarrier = id

      if(get_cvar_num("FT_bomb_event_bonus")){

         if (get_cvar_num("FT_objectives")){
            temp = xpgiven_lev[p_level[id]]
            playerxp[id] += temp
            client_print(id, print_chat,
               "[%s] %s recieved %d XP for spawning with the bomb.",MOD,sName,temp)
         }

         displaylevel(id, 1)
      }
   }else if (equal(sAction,"Dropped_The_Bomb")) {
      // Dropped bomb
      bombCarrier = 0
      if(get_cvar_num("FT_bomb_event_bonus")){

         if (get_cvar_num("FT_objectives")){
            temp = xpgiven_lev[p_level[id]]
            playerxp[id] -=  temp
            client_print(id, print_chat,
               "[%s] %s lost the %d XP bomb carrying bonus.",MOD,sName,temp)
         }

         displaylevel(id, 1)
      }
   }else if (equal(sAction,"Got_The_Bomb")) {
      // Picked up bomb
      bombCarrier = id
      if(get_cvar_num("FT_bomb_event_bonus")){
         if (get_cvar_num("FT_objectives")){
            temp = xpgiven_lev[p_level[id]]
            playerxp[id] += temp
            client_print(id, print_chat,
               "[%s] %s gained %d XP for picking up the bomb.",MOD,sName,temp)
         }

         displaylevel(id, 1)
      }
   }else if (equal(sAction,"Touched_A_Hostage")) {
      // Hostage touched
      if(get_cvar_num("FT_hostage_touch_bonus")){
         if (get_cvar_num("FT_objectives")){
            temp = xpgiven_lev[p_level[id]]
            playerxp[id]+=  temp
            client_print(id, print_chat,
               "[%s] %s recieved %d XP for beginning to escort the hostage to safety.",
               MOD,sName,temp)
         }

         displaylevel(id, 1)
         hostagesaver = id
      }
   }else if (equal(sAction,"Rescued_A_Hostage")) {
      // Hostage rescued
      new origin[3]
      new teamname[32]
      new player[32]
      new numplayers
      new targetorigin[3]
      new targetid

      get_user_origin(id, origin)
      get_user_team(id, teamname, 31)
      get_players(player, numplayers)


      if (get_cvar_num("FT_objectives")){
         temp = 1 * xpgiven_lev[p_level[id]]
         playerxp[id]+=  temp
         client_print(id, print_chat,
            "[%s] %s is given %d XP for escorting a hostage to safety.",MOD,sName,temp)
      }

      // Supporters and self
      for (new i=0; i<numplayers; ++i){
         targetid=player[i]

         if (get_user_team(targetid) != TEAM_CT) continue

         get_user_origin(targetid, targetorigin)

         // [09-27-04] Modified playerlist so now have to check for living status - K2mia
         if ( is_user_alive(targetid) &&
              (get_distance(origin, targetorigin)<=get_cvar_num("FT_xp_radius")) )
         {
            if (get_cvar_num("FT_objectives")){
               temp = HOSTAGEXP + xpgiven_lev[p_level[targetid]]
               playerxp[targetid]+=  temp
               get_user_name(targetid,sName,31)
               client_print(targetid, print_chat,
                  "[%s] %s recieved %d for supporting the hostage run.",MOD,sName,temp)
            }
         }
      }
      displaylevel(targetid, 1)
   }else if (equal(sAction,"Killed_A_Hostage")) {
      // Hostage killed
      if(get_cvar_num("FT_hostage_kill_xp")){
         if (get_cvar_num("FT_objectives")){
            temp = xpgiven_lev[p_level[id]]
            playerxp[id] -= temp
            client_print(id,print_chat, "[%s] %s lost %d XP for killing a hostage.",
               MOD,sName,(temp))
         }

         displaylevel(id, 1)
      }
   }else if (equal(sAction,"Became_VIP")) {
      // VIP spawn
      vipID = id
      if(get_cvar_num("FT_VIP_spawn_bonus")){
         if (get_cvar_num("FT_objectives")){
            temp = xpgiven_lev[p_level[id]]
            playerxp[id]+=  temp
            client_print(id,print_chat, "[%s] %s recieved %d XP for being so important.",
               MOD,sName,temp)
         }
      
         displaylevel(id, 1)
      }
   }else if (equal(sAction,"Assassinated_The_VIP")) {
      // VIP assassinated
      new sNameVIP[MAX_NAME_LENGTH]
      get_user_name( vipID,sNameVIP,MAX_NAME_LENGTH)
         
      if(get_cvar_num("FT_VIP_kill_bonus")){
         if (get_cvar_num("FT_objectives")){
            temp = VIP_KILL_BONUS + xpgiven_lev[p_level[id]]
            playerxp[id]+=  temp
            client_print(id,print_chat, "[%s] %s gained %d XP for assinating %s the VIP.",
               MOD,sName,sNameVIP)
         }
         
         displaylevel(id, 1)
      }  
   }else if (equal(sAction,"Escaped_As_VIP")) {
      // VIP escaped
      new origin[3]
      new teamname[32]
      new player[32]
      new numplayers
      new targetorigin[3]
      new targetid
               
      get_user_origin(id, origin)
      get_user_team(id, teamname, 31)
      get_players(player, numplayers)
         
      new nName[31]
      if (get_cvar_num("FT_objectives")){
         temp = xpgiven_lev[p_level[id]]         
         playerxp[id]+=  temp
         client_print(id,print_chat, "[%s] %s gained %d XP for evading assasination.",
            MOD,sName,temp)
      }     

      for (new i=0; i<numplayers; ++i){ 
         targetid=player[i]
         
         if (get_user_team(targetid) != TEAM_CT) continue
         
         get_user_origin(targetid, targetorigin)
   
         // [09-27-04] Added check for alive status of player - K2mia
         if ( is_user_alive(targetid) &&
              (get_distance(origin, targetorigin)<=get_cvar_num("FT_xp_radius")) &&
              (targetid!=id) )
         {
            if (get_cvar_num("FT_objectives")){
               temp = VIP_ESCAPE_BONUS + xpgiven_lev[p_level[targetid]]
               playerxp[targetid] += temp
               get_user_name(targetid,nName,31)
               client_print(targetid, print_chat,
                  "[%s] %s recieved %d for helping the %s escape.",MOD,nName,temp,sName)
            }
         }
         displaylevel(targetid, 1)
      }
   }
   return PLUGIN_HANDLED
}
// **************************************************************************
// END event_player_action subroutine
// **************************************************************************



// **************************************************************************
// END Event Handler Subroutine Declarations
// **************************************************************************


