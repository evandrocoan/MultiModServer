
/** *************************************************************************
*** AMXX Plugin:   Ultimate Warcraft3 (UWC3)
*** Plugin Author: K2mia
*** UWC3 Module:   General Abilities and Support Routines
*** Date:          May 25, 2004
*** Last Update:   September 23, 2004
*
*  Module: General Abilities and Support Routines
*  Abilities and their supporting routines are defined in this file.
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
// BEGIN Abilities Subroutine Declarations
// **************************************************************************


// **************************************************************************
// BEGIN ability_wcward and supporting routines
// Shadow Hunter serpant ward ultimate
// **************************************************************************
public ability_wcward(id){

   if (!p_skills[id][SKILLIDX_SERPWARD]){
      client_print(id, print_chat, "You do not know the Serpant Ward ultimate yet")
      return PLUGIN_HANDLED
   }

   if(is_user_alive(id)){
      if (serpents[id]>0 && !endround){

         if (get_user_team(id)==TEAM_T)
            serpentteam[id]=TEAM_T
         else
            serpentteam[id]=TEAM_CT

         new parm[6]
         new origin[3]
         get_user_origin(id,origin)
         parm[0]=origin[0]
         parm[1]=origin[1]
         parm[2]=origin[2]
         parm[5]=id
         lightpls(parm)
         set_hudmessage(200, 100, 0, 0.2, 0.3, 0, 1.0, 5.0, 0.1, 0.2, 2)
         serpents[id]--
         show_hudmessage(id,"Serpent Ward Placed, %d remaining", serpents[id])
      }
   }
   return PLUGIN_HANDLED
}

public lightpls(parm[6]){
   new id = parm[5]
   if (!is_user_alive(id))
      return PLUGIN_CONTINUE

   new origin[3], damage
   origin[0]=parm[0]
   origin[1]=parm[1]
   origin[2]=parm[2]

   message_begin( MSG_BROADCAST,SVC_TEMPENTITY)
   write_byte( 0 )
   write_coord(origin[0])
   write_coord(origin[1])
   write_coord(origin[2]+600)
   write_coord(origin[0])
   write_coord(origin[1])
   write_coord(origin[2]-600)
   write_short( lightning )
   write_byte( 1 ) // framestart
   write_byte( 5 ) // framerate
   write_byte( 2 ) // life
   write_byte( 500 ) // width
   write_byte( 20 ) // noise

   if (serpentteam[id]==1){
      write_byte( 255 ) // r
      write_byte( 0 ) // g
      write_byte( 0 ) // b
   }else{
      write_byte( 0 ) // r
      write_byte( 0 ) // g
      write_byte( 255 ) // b
   }

   write_byte( 100 ) // brightness
   write_byte( 100 ) // speed
   message_end()


   new players[32]
   new numberofplayers
   get_players(players, numberofplayers)
   new i
   new targetid = 0
   new distancebetween = 0
   new targetorigin[3]

   for (i = 0; i < numberofplayers; ++i){
      targetid=players[i]
      //if (serpentteam[id]!=get_user_team(targetid) &&
      //   is_user_alive(targetid) && playeritem[targetid]!=IMMUNITY )
      // [10-30-04] - Necklaces no longer protect against Serpent Wards
      if ( (serpentteam[id] != get_user_team(targetid)) && is_user_alive(targetid) ){

         get_user_origin(targetid,targetorigin)
         distancebetween=sqrt((origin[1]-targetorigin[1])*(origin[1]-targetorigin[1])+(origin[0]-targetorigin[0])*(origin[0]-targetorigin[0]))
         if ((distancebetween < 85)){

            // [08-08-04] - Check if Magic Resistance protects against Ward - K2mia
            if ( (p_resists[targetid][RESISTIDX_MAGIC] >= RESIST_MAX_VALUE) ||
                 magic_saving_throw(targetid))
            {
               client_print(targetid, print_chat,
                  "[%s] Your magic resistance protects you from a Serpent Ward", MOD)
               continue
            }

            damage = 10
            do_damage(targetid,id, damage,14, 3, 0, 0, 0)

            client_cmd(targetid, "spk ambience/thunder_clap.wav")

            message_begin(MSG_ONE,gmsgFade,{0,0,0},id)
            write_short( 1<<10 ) // fade lasts this long duration
            write_short( 1<<10 ) // fade lasts this long hold time
            write_short( 1<<12 ) // fade type (in / out)
            write_byte( 255 ) // fade red
            write_byte( 255 ) // fade green
            write_byte( 255 ) // fade blue
            write_byte( iglow[id][3] ) // fade alpha
            message_end()

            if (iglow[id][0] < 1){
               new parm2[2]
               parm2[0]=id
               set_task(0.01,"glow_change",8,parm2,2)
            }
            iglow[id][0] += 3*damage
            iglow[id][1] = 0
            iglow[id][2] = 0
            iglow[id][3] = 0
            if (iglow[id][0]>MAXGLOW)
               iglow[id][0]=MAXGLOW

            message_begin(MSG_ONE,gmsgFade,{0,0,0},id)
            write_short( 1<<10 ) // fade lasts this long duration
            write_short( 1<<10 ) // fade lasts this long hold time
            write_short( 1<<12 ) // fade type (in / out)
            write_byte( 255 ) // fade red
            write_byte( 0 ) // fade green
            write_byte( 0 ) // fade blue
            write_byte( iglow[id][0] ) // fade alpha
            message_end()

         }
      }
   }

   if (!endround)
      set_task(0.45, "lightpls", 43, parm, 6)

   return PLUGIN_CONTINUE
}
// **************************************************************************
// END ability_wcward and supporting and routines
// **************************************************************************


// **************************************************************************
// BEGIN ability_wcrepair and supporting routine
// Special Ability: Repair Armor - fix a teammate's damaged armor
// **************************************************************************
public ability_wcrepair(id){

   if (!warcraft3)
      return PLUGIN_CONTINUE

   if (!p_skills[id][SKILLIDX_REPAIR]){
      client_print(id, print_chat, "You do not know the Repair Armor ability yet")
      return PLUGIN_HANDLED
   }

   if (freezetime==1){
      set_hudmessage(178, 14, 41, -1.0, -0.4, 1, 0.5, 1.7, 0.2, 0.2,5)
      show_hudmessage(id,"You may not use this ability during freezetime")
      return PLUGIN_HANDLED
   }

   if(u_delay){
      set_hudmessage(178, 14, 41, -1.0, -0.4, 1, 0.5, 1.7, 0.2, 0.2,5)
      show_hudmessage(id,"This ability is disabled for the^nfirst %d seconds of the round",get_cvar_num("FT_ultimatedelay"))
      return PLUGIN_HANDLED
   }

   new friend, body
   get_user_aiming(id, friend, body)

   if ((0 < friend <= MAX_PLAYERS) && (friend != id) && (get_user_team(id) == get_user_team(friend)) &&
       is_user_alive(id) && is_user_alive(friend))
   {
      // id has a friend to check for armor repairs
      new max_repairs = 0

      // Number of max repairs based on player level
      if (p_level[id] >= 34) max_repairs = 5
      else if (p_level[id] > 30) max_repairs = 4
      else if (p_level[id] > 20) max_repairs = 3
      else max_repairs = 2

      if (repairs[id] >= max_repairs){
         client_print(id, print_chat, "[%s] You have already performed the maximum number of repairs for this round", MOD)
         return PLUGIN_HANDLED
      }

      new name[32], fname[32]
      get_user_name(id, name, 31)
      get_user_name(friend, fname, 31)

      if (get_user_armor(friend) <= 0 || get_user_armor(friend) >= maxarmor[friend]){
         client_print(id, print_chat, "[%s] %s does not need armor repair at this time", MOD, fname)
         return PLUGIN_HANDLED
      }

      repairs[id] += 1

      new abonus = 0
      new xpbonus = 0

      if (p_level[id] > 30){
         abonus = (7 * ARMORBONUS1)
         //xpbonus = (4 * REPAIRXP) + xpgiven_lev[p_level[id]]
      }else if (p_level[id]  > 25){
         abonus = (6 * ARMORBONUS1)
         //xpbonus = (3 * REPAIRXP) + xpgiven_lev[p_level[id]]
      }else if (p_level[id]  > 20){
         abonus = (5 * ARMORBONUS1)
         //xpbonus = (3 * REPAIRXP) + xpgiven_lev[p_level[id]]
      }else if (p_level[id]  > 15){
         abonus = (4 * ARMORBONUS1)
         //xpbonus = (2 * REPAIRXP) + xpgiven_lev[p_level[id]]
      }else if (p_level[id]  > 10){
         abonus = (3 * ARMORBONUS1)
         //xpbonus = (2 * REPAIRXP) + xpgiven_lev[p_level[id]]
      }else if (p_level[id]  > 5){
         abonus = (2 * ARMORBONUS1)
         //xpbonus = REPAIRXP + xpgiven_lev[p_level[id]]
      }else{
         abonus = ARMORBONUS1
         //xpbonus = REPAIRXP + xpgiven_lev[p_level[id]]
      }

      xpbonus = REPAIRXP + xpgiven_lev[p_level[id]]

      // Extra incentive for long-term XP
      if (get_cvar_num("mp_savexp"))
         xpbonus += (REPAIRXP * p_level[id])

      // Award the player XP for their service
      playerxp[id] += xpbonus

      //set_user_armor(friend, get_user_armor(friend) + abonus)
      set_user_armor_log(friend, (get_user_armor(friend) + abonus), true, "wcrepair()-1")

      if (get_user_armor(friend) > maxarmor[friend])
         set_user_armor_log(friend, maxarmor[friend], true, "wcrepair()-2")
         //set_user_armor(friend, maxarmor[friend])

      client_print(id, print_chat,
         "[%s] You have made some repairs to your teammate's armor <%d XP>.", MOD, xpbonus)
      client_print(friend, print_chat,
         "[%s] %s has made some repairs to your armor.", MOD, name)

      emit_sound(id, CHAN_ITEM, "items/suitchargeok1.wav", 1.0, ATTN_NORM, 0, PITCH_NORM)

   }else if (!is_user_alive(id)){
      client_print(id, print_chat, "[%s] Shhhh, you are dead, act like it.", MOD)
   }else{
      //emit_sound(id, CHAN_ITEM, "buttons/button10.wav", 1.0, ATTN_NORM, 0, PITCH_NORM)
      //new sound[32] = {"buttons/button10.wav"}
      //client_cmd( id, "spk ^"%s^"", sound )
   }

   return PLUGIN_HANDLED
}
// **************************************************************************
// END ability_wcrepair and supporting routine
// **************************************************************************


// **************************************************************************
// BEGIN ability_wcmend and supporting routine
// Special Ability: Mend Wounds - heal a teammate's wounds
// **************************************************************************
public ability_wcmend(id){

   if (!warcraft3)
      return PLUGIN_CONTINUE

   if (!p_skills[id][SKILLIDX_MEND]){
      client_print(id, print_chat, "You do not know the Mend Wounds ability yet")
      return PLUGIN_HANDLED
   }

   if (freezetime==1){
      set_hudmessage(178, 14, 41, -1.0, -0.4, 1, 0.5, 1.7, 0.2, 0.2,5)
      show_hudmessage(id,"You may not use this ability during freezetime")
      return PLUGIN_HANDLED
   }

   if(u_delay){
      set_hudmessage(178, 14, 41, -1.0, -0.4, 1, 0.5, 1.7, 0.2, 0.2,5)
      show_hudmessage(id,"This ability is disabled for the^nfirst %d seconds of the round",get_cvar_num("FT_ultimatedelay"))
      return PLUGIN_HANDLED
   }

   new friend, body
   get_user_aiming(id, friend, body)

   if ((0 < friend <= MAX_PLAYERS) && (friend != id) &&
       (get_user_team(id) == get_user_team(friend)) && is_user_alive(id) &&
        is_user_alive(friend))
   {
      // id has a friend to check for wounds

      // Number of max mends based on player level
      new max_mends = 0

      if (p_level[id] >= 34) max_mends = 5
      else if (p_level[id] > 30) max_mends = 4
      else if (p_level[id] > 20) max_mends = 3
      else max_mends = 2

      if (mends[id] >= max_mends){
         client_print(id, print_chat,
            "[%s] You have already mended the maximum number of wounds for this round", MOD)
         return PLUGIN_HANDLED
      }

      new name[32], fname[32]
      get_user_name(id, name, 31)
      get_user_name(friend, fname, 31)

      if ( get_user_health(friend) >= maxhealth[friend] ){
         client_print(id, print_chat,
            "[%s] %s does not have wounds to be mended at this time", MOD, fname)
         return PLUGIN_HANDLED
      }

      mends[id] += 1

      new hbonus = 0
      new xpbonus = 0

      if (p_level[id] > 30){
         hbonus = (7 * HEALTHBONUS)
         //xpbonus = (4 * MENDXP) + xpgiven_lev[p_level[id]]
      }else if (p_level[id]  > 25){
         hbonus = (6 * HEALTHBONUS)
         //xpbonus = (3 * MENDXP) + xpgiven_lev[p_level[id]]
      }else if (p_level[id]  > 20){
         hbonus = (5 * HEALTHBONUS)
         //xpbonus = (3 * MENDXP) + xpgiven_lev[p_level[id]]
      }else if (p_level[id]  > 15){
         hbonus = (4 * HEALTHBONUS)
         //xpbonus = (2 * MENDXP) + xpgiven_lev[p_level[id]]
      }else if (p_level[id]  > 10){
         hbonus = (3 * HEALTHBONUS)
         //xpbonus = (2 * MENDXP) + xpgiven_lev[p_level[id]]
      }else if (p_level[id]  > 5){
         hbonus = (2 * HEALTHBONUS)
         //xpbonus = MENDXP + xpgiven_lev[p_level[id]]
      }else{
         hbonus = HEALTHBONUS
         //xpbonus = MENDXP + xpgiven_lev[p_level[id]]
      }

      xpbonus = MENDXP + xpgiven_lev[p_level[id]]

      // Extra incentive for long-term XP
      if (get_cvar_num("mp_savexp"))
         xpbonus += (MENDXP * p_level[id])


      set_user_health(friend, get_user_health(friend) + hbonus)
      if (get_user_health(friend) > maxhealth[friend])
         set_user_health(friend, maxhealth[friend])

      new cured_burns = 0;
      new cured_poison = 0;
      new cured_disease = 0;

      if (isburning[friend] || isnburning[friend] && (p_skills[id][SKILLIDX_MEND] >= 3)){
         // 3rd tier cures flamethrower and napalm burns
         isburning[friend] = 0
         isnburning[friend] = 0
         cured_burns = 1
      }

      if (ispoisonedss[friend] && (p_skills[id][SKILLIDX_MEND] >= 2)){
         // 2nd tier of Mend can cure poison
         ispoisonedss[friend] = 0
         cured_poison = 1
      }

      if (isdiseasedcb[friend] && (p_skills[id][SKILLIDX_MEND] >= 2)){
         // 2nd tier of Mend can cure disease
         isdiseasedcb[friend] = 0
         cured_disease = 1
      }


      // Handle extra XP bonuses and messages for burns, poison, disease, etc
      if (cured_burns && cured_poison && cured_disease){
         xpbonus += xplevel_lev[p_level[id]]
         client_print(id, print_chat, "[%s] You have provided medical care to %s : tended burns, cured poison, cured disease <%d XP>", MOD, fname, xpbonus)
         client_print(friend, print_chat, "[%s] %s has provided the following medical care : tended burns, cured poison, cured disease", MOD, name )
      }else if (cured_burns && cured_poison || cured_disease){
         xpbonus += (2 * MENDXP)
         client_print(id, print_chat, "[%s] You have provided medical care to %s : tended burns, cured poison (or) disease <%d XP>", MOD, fname, xpbonus)
         client_print(friend, print_chat, "[%s] %s has provided the following medical care : tended burns, cured poison (or) disease", MOD, name )
      }else if (cured_poison && cured_disease){
         xpbonus += floatround(1.5 * MENDXP)
         client_print(id, print_chat, "[%s] You have provided medical care to %s : cured poison and disease <%d XP>", MOD, fname, xpbonus)
         client_print(friend, print_chat, "[%s] %s has provided the following medical care : cured poison and disease", MOD, name )
      }else if (cured_poison || cured_disease){
         xpbonus += MENDXP
         client_print(id, print_chat, "[%s] You have provided medical care to %s : cured poison (or) disease <%d XP>", MOD, fname, xpbonus)
         client_print(friend, print_chat, "[%s] %s has provided the following medical care : cured poison (or) disease", MOD, name )
      }else{
         client_print(id, print_chat, "[%s] You have provided basic medical care to %s <%d XP>", MOD, fname, xpbonus)
         client_print(friend, print_chat, "[%s] %s has provided basic medical care to you", MOD, name )
      }

      // Award the player XP for their service
      playerxp[id] += xpbonus

      emit_sound(id, CHAN_ITEM, "items/medshot5.wav", 1.0, ATTN_NORM, 0, PITCH_NORM)

   }else if (!is_user_alive(id)){
      client_print(id, print_chat, "[%s] Shhhh, you are dead, act like it.", MOD)
   }else{
      //emit_sound(id, CHAN_ITEM, "buttons/button10.wav", 1.0, ATTN_NORM, 0, PITCH_NORM)
      //new sound[32] = {"buttons/button10.wav"}
      //client_cmd( id, "spk ^"%s^"", sound )
   }

   return PLUGIN_HANDLED
}

// **************************************************************************
// BEGIN draw_medicspr
// Draw the medic alert sprites for injured players
// **************************************************************************
public draw_medicspr(){

   if (get_cvar_num("UW_medicalerts") != 2)
      return PLUGIN_CONTINUE

   new players[32], numofplayers, idself, id, i, j
   new origin[3]

   new wsprite // Which sprite to display for a player -> teammate

   get_players(players, numofplayers)

   for (i = 0; i < numofplayers; i++){
      idself = players[i] // Player id to display medic sprites to

      if ( !is_user_alive(idself) )
         // If idself player is dead skip to next
         continue

      new idself_skill = 0

      // Determine extent of skill (mend, repair or both)
      if ( ( p_skills[idself][SKILLIDX_MEND] ) &&
           ( p_skills[idself][SKILLIDX_REPAIR] ) )
      {
         idself_skill = 3
      }else if ( p_skills[idself][SKILLIDX_MEND] ){
         idself_skill = 1
      }else if ( p_skills[idself][SKILLIDX_REPAIR] ){
         idself_skill = 2
      }else{
         // If player is not a medic or armorsmith skip to next
         idself_skill = 0
         continue
      }

      // If we make it here idself is either medic, armorsmith or both
      // Scan through players and isolate living teammates
      for (j = 0; j < numofplayers; j++){
         id = players[j]  // Player id to see if medic sprite should be displayed

         if ( (idself != id) && (get_user_team(idself) == get_user_team(id)) &&
              is_user_alive(id) && ((get_user_health(id) < maxhealth[id]) ||
              (get_user_armor(id) < maxarmor[id])) )
         {

            //client_print(idself, print_chat, "evaluating id=(%d)", id)

            // Determine extent of injury (health, armor or both)
            new winjury = 0

            if ( (get_user_health(id) < maxhealth[id]) &&
                 (get_user_armor(id) < maxarmor[id]) )
            {
               winjury = 3
            }else if (get_user_health(id) < maxhealth[id]){
               winjury = 1
            }else if (get_user_armor(id) < maxarmor[id]){
               winjury = 2
            }else{
               // Player id has no injuries or damaged armor
               continue
            }

            if (idself_skill == 3){
               if (winjury == 3)
                  wsprite = medshieldspr
               else if (winjury == 1)
                  wsprite = medicspr
               else if (winjury == 2)
                  wsprite = shieldspr
               else
                  continue
            }else if ( (idself_skill == 1) && ((winjury == 3) || (winjury == 1)) ){
               wsprite = medicspr
            }else if ( (idself_skill == 2) && ((winjury == 3) || (winjury == 2)) ){
               wsprite = shieldspr
            }else{
               // Nothing to show for this player -> teammate combo
               continue
            }

            //client_print(idself, print_chat, "idself_skill=(%d) winjury=(%d)",
            //   idself_skill, winjury)

            get_user_origin(id, origin)

            message_begin(MSG_ONE,SVC_TEMPENTITY,{0,0,0},idself)
            write_byte(TE_PLAYERATTACHMENT)
            write_byte(id)
            write_coord( 30 )       // z axis for sprite
            write_short( wsprite )  // which sprite to display
            write_short(50)
            message_end()
         }
      }
   }

   set_task(5.0, "draw_medicspr", 357)
      
   return PLUGIN_CONTINUE
      
}        
// **************************************************************************
// END draw_medicspr  
// **************************************************************************

// **************************************************************************
// END ability_wcmend and supporting routine
// **************************************************************************


// **************************************************************************
// END Abilities Subroutine Declarations
// **************************************************************************

