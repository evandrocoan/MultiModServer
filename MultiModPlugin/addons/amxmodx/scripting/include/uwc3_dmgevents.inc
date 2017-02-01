
/** *************************************************************************
*** AMXX Plugin:   Ultimate Warcraft3 (UWC3)
*** Plugin Author: K2mia
*** UWC3 Module:   Damage and Damage Events
*** Date:          May 25, 2004
*** Last Update:   September 27, 2004
*
*  Module: Damage and Damage Events 
*  Subroutines for handling damage, death, and uwc3-skills related damage 
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
// BEGIN Damage/Events Subroutine Declarations
// **************************************************************************

// **************************************************************************
// BEGIN get_deathbystr subroutine
// Returns the deathby name in string format
// **************************************************************************
public get_deathbystr(deathby, string[], len){

   switch (deathby){
      case 1:
         format(string, len, "%s", "Carrion Beetles")     // Carrion Beetles
      case 2:
         format(string, len, "%s", "Thorns Aura")         // Thorns Aura
      case 3:
         format(string, len, "%s", "Trueshot Aura")       // Trueshot Aura
      case 4:
         format(string, len, "%s", "Spiked Carapace")     // Spiked Carapace
      case 5:
         format(string, len, "%s", "Banish")              // Banish
      case 6:
         format(string, len, "%s", "Critical Strike")     // Critical Strike
      case 7:
         format(string, len, "%s", "Critical Grenade")    // Critical Grenade
      case 8:
         format(string, len, "%s", "Claws of Attack")     // Claws of Attack
      case 9:
         format(string, len, "%s", "Shadow Strike")       // Shadow Strike
      case 10:
         format(string, len, "%s", "Blink")               // Blink > Big Bad Voodoo
      case 11:
         format(string, len, "%s", "Chain Lightning")     // Chain Lightning Kill
      case 12:
         format(string, len, "%s", "Suicide Bomber")      // Suicide Bomber Kill
      case 13:
         format(string, len,"%s",  "Flame Strike")        // Flame Strike Kill
      case 14:
         format(string, len,"%s",  "Serpant Ward")        // Serpant Ward Kill
      case 15:
         format(string, len,"%s",  "Locust Swarm")        // Locust Kill
      case 16:
         format(string, len,"%s",  "Necklace of Immunity")// Necklace of Immunity
      case 17:
         format(string, len,"%s",  "Napalm Grenade")      // Napalm Grenade
      case 18:
         format(string, len,"%s",  "Poison")              // S. Strike Poison
      case 19:
         format(string, len,"%s",  "Disease")             // C. Beetles Disease
      case 20:
         format(string, len,"%s",  "Beginner's Luck")     // Beginner's Luck
      case 21:
         format(string, len,"%s",  "Critical Backfire")   // Critical Backfire
      case 22:
         format(string, len,"%s",  "Magic Resistance")    // Magic Resistance
   }

}
// **************************************************************************
// END get_deathbystr subroutine
// **************************************************************************


// **************************************************************************
// BEGIN do_damage subroutine
// Used by damage_event to deal out damage
// **************************************************************************
public do_damage(id,enemy, damage,deathby, victim_or_enemy, weapon, bodypart, userdead){
   // id is attacked, attacker ,damage , victim = 1, enemy = 2

   if (!warcraft3)
      return PLUGIN_CONTINUE

   new idname[32], ename[32]
   get_user_name( id, idname, 31)
   get_user_name( enemy, ename, 31)

   if (get_cvar_num("UW_dmgxpbonus"))
      damageto[enemy][id] += damage

   //client_print(0, print_console,
   //   "[%s DEBUG] [In do_damage()] <%s => %s> damage=(%d) damageto=(%d)",
   //   MOD, ename, idname, damage, damageto[enemy][id])


   new userkilled = 0
   new string[48]

   get_deathbystr(deathby, string, 47)	// Get the string form of deathby

   if (get_cvar_num("UW_DEBUG") == 1){
      client_print(0, print_console, "[%s DEBUG In do_damage()] <%s => %s> dmg=(%d) deathby=(%s) userdead=(%d) victim_evade?=(%d)", MOD, ename, idname, damage, string, userdead, p_evadethisshot[id])
   }else if (get_cvar_num("UW_DEBUG") == 6){
      log_amx( "DEBUG: In do_damage() <%s => %s> dmg=(%d) deathby=(%s)", 
               ename, idname, damage, string )
   }


   if(userdead || !is_user_alive(id)){
      return PLUGIN_HANDLED
   }

   if ( hasblink[id] && 
        (weapon ==10 || weapon==11 || weapon==12 || weapon==13 || weapon==15))
   {
      return PLUGIN_HANDLED
   }

   if (hasgodmode[id] && !hasblink[enemy] && playeritem[enemy]!=IMMUNITY &&
      (p_resists[enemy][RESISTIDX_MAGIC] < RESIST_MAX_VALUE) &&
      !magic_saving_throw(enemy))
   {
      return PLUGIN_HANDLED
   }

   /*
   if (bodypart==1 && get_user_team(id)!=get_user_team(enemy)){
      playerxp[enemy]+=HEADSHOT_BONUS
      if (get_cvar_num("FT_kill_objectives")){
          client_print(0, print_console, "UWC3-DEBUG: HEADSHOT (do_damage()) - attacked=(%d) enemy=(%d)", id, enemy)
          client_print(enemy,print_chat,"[%s] You are awarded %d XP for having a headshot", MOD, HEADSHOT_BONUS)//?
      }
      displaylevel(enemy,1)
   }
   */

   if (get_user_health(id) - damage<=0)
      userkilled = 1
   if (get_user_health(id) - damage<=1024 && get_user_health(id)>500)
      userkilled = 1
   if (userkilled)
      set_user_health_log(id, -1, true, "do_damage() USERKILLED1")
   else{
      //client_print(0, print_console, "[%s DEBUG] [In do_damage()] NOTKILLED1 damage=(%d) cause=(%s)", damage, string)
      set_user_health_log(id, get_user_health(id) - damage, true, "do_damage() NOTKILLED1")
   }

   //client_print(0, print_console, "[%s DEBUG] [do_damage()-2] <%s => %s> dmg=(%d) user_health=(%d)", MOD, ename, idname, damage, get_user_health(id))


   if (userkilled && is_user_connected(enemy) && get_user_team(id)!=get_user_team(enemy))
      cs_set_user_money(enemy, cs_get_user_money(enemy) + MONEY_PER_KILL)

   if (userkilled){
      diedlastround[id]=true
   }

   if (userkilled && id!=enemy)
      get_deathbystr(deathby, string, 47)	// Get the string form of deathby


   new name[32]
   get_user_name(id,name,31)

   xpgiven = xpgiven_lev[p_level[enemy]]

   if (userkilled && ((victim_or_enemy == 2) || (victim_or_enemy == 3)) &&
       (id != enemy) && (userdead == 0) )
   {
      // A skill resulted in a player's death
      if (get_user_team(id)!=get_user_team(enemy)){

         if ( !is_user_connected( id ) || !is_user_connected( enemy ) )
            return PLUGIN_CONTINUE

         set_user_frags(enemy, get_user_frags(enemy)+1)
         set_user_frags(id, get_user_frags(id)+1)

         //logKill(enemy,id, string)
         if (get_user_team(id) != get_user_team(enemy)){
            playerxp[enemy] += xpgiven
            if (get_cvar_num("FT_kill_objectives")){
               client_print(enemy, print_chat,
                  "[%s] You just gained %d XP for killing %s with %s",
                  MOD, xpgiven, name, string)
            }
            displaylevel(id, 1)
         }
      }

      if(!deathmessageshown[id]){
         deathmessageshown[id]=true
         message_begin( MSG_ALL, gmsgDeathMsg,{0,0,0},0)
         write_byte(enemy)
         write_byte(id)
         write_byte(0)
         write_string(string)
         message_end()
      }

      return PLUGIN_HANDLED

   }

   if (userkilled && (victim_or_enemy == 1) && (id != enemy) && (userdead == 0) ){
      // due to all aggressive auras
      new headshot
      if (bodypart==1)
         headshot=1
      else
         headshot=0

      new weaponname[32]

      switch (weapon){
         case 1:
            weaponname = "p228"
         case 3:
            weaponname = "scout"
         case 4:
            weaponname = "grenade"
         case 5:
            weaponname = "xm1014"
         case 7:
            weaponname = "mac10"
         case 8:
            weaponname = "aug"
         case 10:
            weaponname = "elite"
         case 11:
            weaponname = "fiveseven"
         case 12:
            weaponname = "ump45"
         case 13:
            weaponname = "sg550"
         case 16:
            weaponname = "usp"
         case 17:
            weaponname = "glock18"
         case 18:
            weaponname = "awp"
         case 19:
            weaponname = "mp5navy"
         case 20:
            weaponname = "m249"
         case 21:
            weaponname = "m3"
         case 22:
            weaponname = "m4a1"
         case 23:
            weaponname = "tmp"
         case 24:
            weaponname = "g3sg1"
         case 26:
            weaponname = "deagle"
         case 27:
            weaponname = "sg552"
         case 28:
            weaponname = "ak47"
         case 29:
            weaponname = "knife"
         case 30:
            weaponname = "p90"
      }

      //client_print(0, print_console, 
      //   "[%s DEBUG] [do_damage()-3] <%s => %s> weapon=(%s)", 
      //   MOD, ename, idname, weaponname)

      //logKill(enemy,id, weaponname)
      if ( is_user_connected( id ) ) set_user_frags(id, get_user_frags(id)+1)
      if ( is_user_connected( enemy ) ) set_user_frags(enemy, get_user_frags(enemy)+1)

      if (!get_cvar_num("mp_weaponxpmodifier") &&
          get_user_team(id)!=get_user_team(enemy))
      {
         playerxp[enemy]+=xpgiven
         if (get_cvar_num("FT_kill_objectives")){
            client_print(enemy, print_chat, 
              "[%s] You just gained %d XP for killing %s with %s",MOD,xpgiven,name,string)
         }
      }else if(get_user_team(id)!=get_user_team(enemy)){
         playerxp[enemy] += floatround(xpgiven*weaponxpmultiplier[weapon])
         if (get_cvar_num("FT_kill_objectives")){
            client_print(enemy, print_chat,
              "[%s] You just gained %d XP for killing %s with %s",
              MOD, floatround(xpgiven*weaponxpmultiplier[weapon]), name, string)
         }
      }

      if(!deathmessageshown[id]){
         deathmessageshown[id]=true
         message_begin( MSG_ALL, gmsgDeathMsg,{0,0,0},0)
         write_byte(enemy)
         write_byte(id)
         write_byte(headshot)
         write_string(weaponname)
         message_end()
         displaylevel(enemy, 1)
      }
   }

   return PLUGIN_CONTINUE
}
// **************************************************************************
// END do_damage subroutine
// **************************************************************************



// **************************************************************************
// BEGIN damage_event subroutine
// Handler for all damage events
// **************************************************************************
public damage_event(id){

   if (!warcraft3)
      return PLUGIN_CONTINUE

   new weapon = 0, bodypart = 0, enemy = get_user_attacker(id,weapon,bodypart)
   new damage = read_data(2)

   new name1[32], name2[32]
   get_user_name(id, name1, 31)
   get_user_name(enemy, name2, 31)


   if (get_cvar_num("UW_medicalerts") && !medicalert[id]){
      // Send out medic alert calls to all medics on the team
      medicalert[id] = true
      new pid, players[32], pnum=0
      get_players(players, pnum)
      for (new i=0; i < pnum; i++){
         pid = players[i]
         if (is_user_alive(id) && is_user_alive(pid) &&
             (get_user_team(pid) == get_user_team(id)))
         {
            if ((p_skills[pid][SKILLIDX_MEND] == 3) && (isburning[id] || isnburning[id])){
               client_print(pid, print_chat,
                  "[%s] MEDIC ALERT : %s is burning and needs medical attention",
                  MOD, name1)
            }else if ((p_skills[pid][SKILLIDX_MEND] == 2) && ispoisonedss[id]){
               client_print(pid, print_chat,
                  "[%s] MEDIC ALERT : %s is poisoned and needs medical attention",
                  MOD, name1)
            }else if ((p_skills[pid][SKILLIDX_MEND] == 2) && isdiseasedcb[id]){
               client_print(pid, print_chat,
                  "[%s] MEDIC ALERT : %s is diseased and needs medical attention",
                  MOD, name1)
            }else if (p_skills[pid][SKILLIDX_MEND]){
               client_print(pid, print_chat,
                  "[%s] MEDIC ALERT : %s needs medical attention", MOD, name1)
            }
         }
      }
   }

   if (get_cvar_num("UW_dmgxpbonus"))
      damageto[enemy][id] += damage

   //client_print(0, print_console, "[%s DEBUG] [In damage_event()] <%s => %s> damage=(%d) damageto=(%d)", MOD, name2, name1, damage, damageto[enemy][id])

   //client_print(0, print_console, "[%s DEBUG] [In damage_event()] <%s => %s> weapon=(%d) bodypart=(%d) dmg=(%d)", MOD, name2, name1, weapon, bodypart, damage)

   /*
   if(weapon==0 && enemy==0 && is_running("czero")){
      // Temporary Fix: HE nade tossed in CZ (get_user_attacker is broken in CZ
      //for nades) This is not 100% (obviously, look at the shitty code)
      new Float:porigin[3], players[32], pnum=0, y=0
      new Float:distance

      Entvars_Get_Vector(id,EV_VEC_origin,porigin)
      get_players(players, pnum)

      for(y=0;y<pnum;y++){
         enemy = players[y]
         distance = VecDist(porigin,he_origin[enemy])
         if (distance<350.0)
            break
      }
      new parm3[1]
      parm3[0]=enemy
      set_task(0.1,"reset_he_origin",1,parm3,1)
      weapon = 4
      // End Temporary Fix
   }
   */

   if(ismole[enemy] && (playeritem2[id]==PROTECTANT || hasblink[id])){
      // Mole Protectant
      damage = read_data(2)
      set_user_health_log(id,get_user_health(id)+damage, true, "damage_event() PROTECTANT1")
      client_print(id,print_chat,"[%s] %s",MOD,"A shot by a mole was deflected")
      return PLUGIN_HANDLED
   }

   if(hasgodmode[id]){
      // Godmode handler, check for necklace which will counter w/ extra dmg
      damage = read_data(2)
      if(hasblink[enemy] || playeritem[enemy]==IMMUNITY){
         godshealth[id] = godshealth[id] - damage
         if(godshealth[id]<0){
            do_damage(id,enemy, godshealth[id]+2048, 16, 1, weapon, bodypart, 0)
         }
      }else if ( (p_resists[enemy][RESISTIDX_MAGIC] >= RESIST_MAX_VALUE) ||
                  magic_saving_throw(enemy))
      {
         godshealth[id] = godshealth[id] - damage
         if(godshealth[id]<0){
            do_damage(id,enemy, godshealth[id]+2048, 22, 1, weapon, bodypart, 0)
         }
      }else{
         set_user_health_log(id,get_user_health(id)+damage, true, "damage_event() GODMODE1")
         return PLUGIN_HANDLED
      }
   }

   if (enemy==id)
      return PLUGIN_HANDLED

   if (enemy==id && weapon==0){
      return PLUGIN_CONTINUE
   }else if (enemy==0){
      return PLUGIN_CONTINUE
   }

   // [08-10-04] - Evasion completely rewritten and modified for Dexterity bonus - K2mia
   // [07-30-04] - Moved Evasion check to be before other skill checks - K2mia
   if (p_skills[id][SKILLIDX_EVASION]) {
      // Elf Evasion

      new Float:randomnumber = random_float(0.0,1.0)

      new Float:evade_percent = p_evasion[p_skills[id][SKILLIDX_EVASION]-1]

      if (USE_ENH && (p_attribs[id][ATTRIBIDX_DEX] > ATTRIB_BASE) ){
         new edex = (p_attribs[id][ATTRIBIDX_DEX] - ATTRIB_BASE)
         evade_percent += (float(edex) * DEX_EVADE_BONUS)

         if (get_cvar_num("UW_DEBUG") == 1){
            client_print(id, print_console,
               "[%s DEBUG In damage_event()-1] evade_percent=(%f)", MOD, evade_percent)
         }
      }

      if (get_cvar_num("UW_DEBUG") == 1){
         client_print(id, print_console,
          "[%s DEBUG In damage_event()-2] evade_percent modified=(%f)", MOD, evade_percent)
      }

      if (is_user_alive(id) && (randomnumber <= evade_percent)){
         p_evadethisshot[id] = true
      }else{
         p_evadethisshot[id] = false
      }

      if (p_evadethisshot[id]){
         new idname[32], ename[32]
         get_user_name(id, idname, 31)
         get_user_name(enemy, ename, 31)

         damage = read_data(2)

         set_user_health_log(id, get_user_health(id) + damage, true,
            "damage_event() EVADE (health+damage)")

         client_print(id, print_chat,"[%s] You skillfully evade a shot by %s", MOD, ename)
         client_print(enemy, print_chat, "[%s] %s skillfully evades your shot", MOD, idname)


         if (iglow[id][2] < 1){
            new parm[2]
            parm[0] = id
            set_task(0.01,"glow_change",7,parm,2)
         }

         iglow[id][2] += damage
         iglow[id][0] = 0
         iglow[id][1] = 0
         iglow[id][3] = 0

         if (iglow[id][2]>MAXGLOW)
            iglow[id][2]=MAXGLOW

         message_begin(MSG_ONE,gmsgFade,{0,0,0},id)
         write_short( 1<<10 ) // fade lasts this long duration
         write_short( 1<<10 ) // fade lasts this long hold time
         write_short( 1<<12 ) // fade type (in / out)
         write_byte( 0 ) // fade red
         write_byte( 0 ) // fade green
         write_byte( 255 ) // fade blue
         write_byte( iglow[id][2] ) // fade alpha
         message_end()
      }
      // End of Elf Evasion
   }

   if (get_cvar_num("UW_DEBUG") == 1)
      client_print(0, print_console, "[%s DEBUG In damage_event()] <%s => %s> damage=(%d) was_evaded?=(%d)", MOD, name2, name1, damage, p_evadethisshot[id])


   if (p_skills[enemy][SKILLIDX_CRITSTRIKE] && p_skills[enemy][SKILLIDX_TRUESHOT]){
      // Check for chance of Trueshot/Crit Strike backfire on enemy
      new Float:randomnumber = random_float(0.0,1.0)

      if (randomnumber < ((p_skills[enemy][SKILLIDX_CRITSTRIKE] + p_skills[enemy][SKILLIDX_TRUESHOT])/2) )
      {
         new idname[32], ename[32]
         get_user_name(id, idname, 31)
         get_user_name(enemy, ename, 31)

         // [09-03-04] Modified backfire damage to be half a player's health
         //damage = (get_user_health(enemy) - 5)
         damage = (get_user_health(enemy) / 2)
         do_damage(enemy, id, damage, 21, 2, weapon, bodypart,0)

         client_print(enemy, print_chat,
            "[%s] Your Critical Strike and Trueshot Auras have caused a backfire!", MOD)
         client_print(id, print_chat,
            "[%s] %s experienced a backfire from Critical Strike and Trueshot Auras", MOD, ename)

         if (iglow[enemy][0] < 1){
            new parm[2]
            parm[0] = enemy
            set_task(0.01,"glow_change",8,parm,2)
         }

         iglow[enemy][0] += damage
         iglow[enemy][1] = 0
         iglow[enemy][2] = 0
         iglow[enemy][3] = 0

         if (iglow[enemy][0]>MAXGLOW)
            iglow[enemy][0]=MAXGLOW

         message_begin(MSG_ONE,gmsgFade,{0,0,0},enemy)
         write_short( 1<<10 ) // fade lasts this long duration
         write_short( 1<<10 ) // fade lasts this long hold time
         write_short( 1<<12 ) // fade type (in / out)
         write_byte( 255 ) // fade red
         write_byte( 0 )   // fade green
         write_byte( 125 ) // fade blue
         write_byte( iglow[enemy][0] ) // fade alpha
         message_end()
      }
      // End of Backfire from Crit. Strike and Trueshot
   }

   // [08-05-04] - Evasion now protects against Shadow Strike
   if (p_skills[enemy][SKILLIDX_SSTRIKE] && !p_evadethisshot[id] ){
      // Shadow Strike
      new Float:randomnumber = random_float(0.0,1.0)

      new Float:ss_chance = p_shadow[p_skills[enemy][SKILLIDX_SSTRIKE]-1]

      if (USE_ENH && p_resists[id][RESISTIDX_POISON]){
         ss_chance = ss_chance - ((float(p_resists[id][RESISTIDX_POISON]) / float(RESIST_MAX_VALUE)) * ss_chance)
      }


      // [07-14-04] - Now only poisons a person one time - K2mia
      if ( (p_resists[id][RESISTIDX_POISON] < RESIST_MAX_VALUE) &&
           (randomnumber <= ss_chance) && (shadowcount[enemy] > 0) &&
           is_user_alive(id) && !ispoisonedss[id] )
      {
         new idorigin[3]
         new enemyorigin[3]
         get_user_origin(id,idorigin)
         get_user_origin(enemy,enemyorigin)
         message_begin( MSG_BROADCAST,SVC_TEMPENTITY)
         write_byte( TE_SPRITETRAIL )
         write_coord(enemyorigin[0])
         write_coord(enemyorigin[1])
         write_coord(enemyorigin[2])
         write_coord(idorigin[0])
         write_coord(idorigin[1])
         write_coord(idorigin[2])
         write_short( shadow )           // short (sprite index)
         write_byte( 50 )                // byte (count)
         write_byte( 15 )                // byte (life in 0.1's)
         write_byte( 3 )                 // byte (scale in 0.1's)
         write_byte( 2 )                 // byte (velocity along vector in 10's)
         write_byte( 6 )                 // byte (randomness of velocity in 10's)
         message_end()
         set_hudmessage(200, 100, 0, 0.2, 0.2, 0, 1.0, 5.0, 0.1, 0.2, 2)
         shadowcount[enemy]--

         if (file_exists("sound/warcraft3/shadowstrikebirth1.wav")==1)
            emit_sound(id, CHAN_STATIC, "warcraft3/shadowstrikebirth1.wav", 1.0,
                       ATTN_NORM, 0, PITCH_NORM)
         if (file_exists("sound/warcraft3/shadowstrikemissile1.wav")==1)
            emit_sound(enemy, CHAN_STATIC, "warcraft3/shadowstrikemissile1.wav", 1.0,
                       ATTN_NORM, 0, PITCH_NORM)

         new idname[32], ename[32]
         get_user_name(id, idname, 31)
         get_user_name(enemy, ename, 31)

         client_print(enemy, print_chat,
            "[%s] Your poison darts hit their mark on %s", MOD, idname)
         client_print(id, print_chat,
            "[%s] Poison darts from %s take their toll on you, seek a medic quickly!",
            MOD, ename)

         // 6-19-2004 - Damage modified to be based on level (K2mia)
         damage = floatround(p_level[enemy] / 2.0)
         do_damage(id, enemy, damage, 9, 1, weapon, bodypart,0)

         ispoisonedss[id] = 1

         // [ 09-06-04] - Attach poison1.spr to the infected
         message_begin(MSG_ALL, SVC_TEMPENTITY)
         write_byte(TE_PLAYERATTACHMENT)
         write_byte(id)
         write_coord( 0 )
         write_short( poison )
         write_short(25)
         message_end()

         new args[2]
         args[0] = id
         args[1] = enemy
         set_task(2.0, "do_sspoison", 452, args, 2, "b");

      }else if ((randomnumber <= p_shadow[p_skills[enemy][SKILLIDX_SSTRIKE]-1]) &&
                (shadowcount[enemy] > 0) && is_user_alive(id) && !ispoisonedss[id])
      {
         // If we are here then the resistance is what caused Shadow Strike to fail
         client_print(id, print_chat,
            "[%s] Your resistance to poison helps to shield you from a Shadow Strike", MOD)
         client_print(enemy, print_chat,
            "[%s] Your Shadow Strike is absorbed by your target's poison resistance", MOD)
      }
   }else if (p_skills[enemy][SKILLIDX_SSTRIKE] && p_evadethisshot[id] ){
      if (get_cvar_num("UW_DEBUG") == 1){
         client_print(id, print_console,
          "[%s DEBUG In damage_event()] Shot evaded, Shadow Strike check skipped")
      }
   // End of Shadow Strike
   }

   // [08-05-04] - Evasion now protects against Carrion Beetles
   if(p_skills[enemy][SKILLIDX_CARRION] && !p_evadethisshot[id] ){
      // Carrion Beetle
      new Float:randomnumber = random_float(0.0,1.0)

      new Float:cb_chance = p_carrion[p_skills[enemy][SKILLIDX_CARRION]-1]

      if (USE_ENH && p_resists[id][RESISTIDX_DISEASE]){
         cb_chance = cb_chance - ((float(p_resists[id][RESISTIDX_DISEASE]) / float(RESIST_MAX_VALUE)) * cb_chance)
      }

      new idname[32], ename[32]
      get_user_name(id, idname, 31)
      get_user_name(enemy, ename, 31)

      //new sDmesg[256] = ""
      //format( sDmesg, 255, "DEBUG: CB Check <%d>(%s)=><%d>(%s) victim_resist=(%d) enemy_cb=(%f) modifier=(%f) final_cb=(%f)", enemy, ename, id, idname, p_resists[id][RESISTIDX_DISEASE], p_carrion[p_skills[enemy][SKILLIDX_CARRION]-1], ((float(p_resists[id][RESISTIDX_DISEASE]) / float(RESIST_MAX_VALUE)) * (p_carrion[p_skills[enemy][SKILLIDX_CARRION]-1])), cb_chance)

      //client_print(id, print_console, "%s", sDmesg)
      //log_amx(sDmesg)

      // [07-14-04] - Now only diseases a person one time - K2mia
      if ( (p_resists[id][RESISTIDX_DISEASE] < RESIST_MAX_VALUE) &&
           (randomnumber <= cb_chance) && (carrioncount[enemy] > 0) &&
           is_user_alive(id) && !isdiseasedcb[id])
      {
         new idorigin[3]
         new enemyorigin[3]
         get_user_origin(id,idorigin)
         get_user_origin(enemy,enemyorigin)
         message_begin( MSG_BROADCAST,SVC_TEMPENTITY)
         write_byte( TE_SPRITETRAIL )
         write_coord(enemyorigin[0])
         write_coord(enemyorigin[1])
         write_coord(enemyorigin[2])
         write_coord(idorigin[0])
         write_coord(idorigin[1])
         write_coord(idorigin[2])
         write_short( carrion )          // short (sprite index)
         write_byte( 50 )                // byte (count)
         write_byte( 15 )                // byte (life in 0.1's)
         write_byte( 1 )                 // byte (scale in 0.1's)
         write_byte( 2 )                 // byte (velocity along vector in 10's)
         write_byte( 6 )                 // byte (randomness of velocity in 10's)
         message_end()
         set_hudmessage(200, 100, 0, 0.2, 0.2, 0, 1.0, 5.0, 0.1, 0.2, 2)
         carrioncount[enemy]--

         if (file_exists("sound/warcraft3/carrionswarmlaunch1.wav")==1)
            emit_sound(enemy, CHAN_STATIC, "warcraft3/carrionswarmlaunch1.wav", 1.0,
                       ATTN_NORM, 0, PITCH_NORM)
         if (file_exists("sound/warcraft3/carrionswarmdamage1.wav")==1)
            emit_sound(id, CHAN_STATIC, "warcraft3/carrionswarmdamage1.wav", 1.0,
                       ATTN_NORM, 0, PITCH_NORM)


         client_print(enemy, print_chat,
            "[%s] Your Carrion Beetles infect %s with disease", MOD, idname)
         client_print(id, print_chat,
            "[%s] Carrion Beetles from %s infect you with disease, seek a medic quickly!", 
            MOD, ename)

         // 6-19-2004 - Carrion Beetles damage modified, now based on level (K2mia)
         damage = floatround(p_level[enemy] / 2.0)
         do_damage(id, enemy,damage,1,1, weapon, bodypart,0)

         isdiseasedcb[id] = 1

         // [ 09-02-04] - Attach bm2.spr to the infected
         message_begin(MSG_ALL, SVC_TEMPENTITY)
         write_byte(TE_PLAYERATTACHMENT)
         write_byte(id)
         write_coord( 0 )
         write_short( cbgreen )
         write_short(25)
         message_end()

         new args[2]
         args[0] = id
         args[1] = enemy
         set_task(3.0, "do_cbdisease", 452, args, 2, "b");
      }else if ((randomnumber <= p_carrion[p_skills[enemy][SKILLIDX_CARRION]-1]) &&
                (carrioncount[enemy] > 0) && is_user_alive(id) && !isdiseasedcb[id])
      {
         // If we are here then the resistance is what caused Carrion Beetles to fail
         client_print(id, print_chat,
            "[%s] Your resistance to disease helps to shield you from Carrion Beetles", MOD)
         client_print(enemy, print_chat,
            "[%s] Your Carrion Beetles are absorbed by your target's disease resistance",
            MOD)
      }
   }else if (p_skills[enemy][SKILLIDX_CARRION] && p_evadethisshot[id] ){
      if (get_cvar_num("UW_DEBUG") == 1){
         client_print(id, print_console,
          "[%s DEBUG In damage_event()] Shot evaded, Carrion Beetles check skipped")
      }
   // End of Carrion Beetle
   }

   // New Beginner's Luck implied skill for levels 0-4
   if (get_cvar_num("UW_luck_skill") && (id != enemy) &&
       (0 < id <= MAX_PLAYERS) && (0 < enemy <= MAX_PLAYERS) )
   {
      // [07-25-04] - Beginner's Luck skill (evade chance for victim, dbl dmg for attacker)

      if ( ( 0 <= p_level[id] <= 4 ) && ( p_level[enemy] >= 15 ) &&
           ( get_user_health(id) > damage ) )
      {
         // [07-25-04] - Beginner's Luck skill check for evaded shot
         new Float:nEvadeChance = (0.50 - (float(p_level[id]) * 0.10))
         new Float:randomnumber = random_float(0.0, 1.0)

         //client_print(0, print_chat, "[%s-DEBUG] Chance for evade=(%f) rnum=(%f)",
         //   MOD, nEvadeChance, randomnumber)

         if (randomnumber <= nEvadeChance){
            // Player evades this shot
            new nHealth = get_user_health(id) + damage
            set_user_health_log(id, nHealth, true, "damage_event() B.Luck-Evade1")

            //client_print(0, print_chat,
            //   "[%s-DEBUG] B.Luck Evasion: Setting health to=(%d)", MOD, nHealth)

            client_print(id, print_chat,
               "[%s] Your Beginner's Luck allows you to evade a shot from %s.", MOD, name2)
            client_print(enemy, print_chat,
               "[%s] %s has Beginner's Luck and evades your shot.", MOD, name1)
         }
      }else if ( ( 0 <= p_level[enemy] <= 4 ) && ( p_level[id] >= 15 ) &&
                 !p_evadethisshot[id] )
      {
         // [07-25-04] - Beginner's Luck skill check for double damage
         new Float:nDblChance =
                (p_level[enemy] == 4) ? 0.10 : (0.80 - (float(p_level[enemy]) * 0.20))
         new Float:randomnumber = random_float(0.0, 1.0)

         if (randomnumber <= nDblChance){
            // Player gets double attack bonus
            new nDmg = damage
            do_damage(id, enemy, nDmg, 20, 1, weapon, bodypart, 0)

            //client_print(0, print_chat, "[%s-DEBUG] B.Luck DBM Dmg: dmg=(%d)",
            //   MOD, nDmg)

            client_print(enemy, print_chat,
               "[%s] Your Beginner's Luck causes you to do extra damage to %s.", MOD, name1)
            client_print(id, print_chat,
               "[%s] %s uses Beginner's Luck to cause you extra damage.", MOD, name2)
         }
      }
   }

   if (p_skills[id][SKILLIDX_THORNS] && !p_evadethisshot[id]){
      // Thorns Aura
      damage = read_data(2)
      new orig_dmg = damage

      damage = floatround(float(damage) * p_thorns[p_skills[id][SKILLIDX_THORNS]-1])

      damage = ( damage < THORNS_MAX_DMG ) ? damage : THORNS_MAX_DMG

      if ( get_cvar_num("UW_DEBUG") == 5 ){
         new idname[32], ename[32]
         get_user_name(id, idname, 31)
         get_user_name(enemy, ename, 31)

         client_print( enemy, print_console, "THORNS DEBUG: You attacked %s (has thorns) orig_dmg=(%d) thorns_dmg=(%d) orig_health=(%d) after_thorns_health=(%d)", idname, orig_dmg, damage, get_user_health(enemy), (get_user_health(enemy)-damage) )

         log_amx( "THORNS DEBUG: %s attacked %s (has thorns) orig_dmg=(%d) thorns_dmg=(%d) orig_health=(%d) after_thorns_health=(%d)", ename, idname, orig_dmg, damage, get_user_health(enemy), (get_user_health(enemy)-damage) )
      }

      do_damage(enemy, id,damage,2,2, weapon, bodypart,0)

      if (iglow[enemy][0] < 1){
         new parm[2]
         parm[0] = enemy
         set_task(0.01,"glow_change",8,parm,2)
      }

      new idname[32], ename[32]
      get_user_name(id, idname, 31)
      get_user_name(enemy, ename, 31)

      client_print(enemy, print_chat,
         "[%s] The Thorns Aura surrounding %s inflicts damage on you.", MOD,  idname)
      client_print(id, print_chat,
         "[%s] Your Thorns Aura inflicts damage on %s", MOD, ename)

      iglow[enemy][0] += 3*damage
      iglow[enemy][1] = 0
      iglow[enemy][2] = 0
      iglow[enemy][3] = 0

      if (iglow[enemy][0]>MAXGLOW)
         iglow[enemy][0]=MAXGLOW

      // [09-09-04] - Added thorns armor effect - K2mia
      //message_begin(MSG_ALL, SVC_TEMPENTITY)
      message_begin(MSG_ONE,SVC_TEMPENTITY,{0,0,0},enemy)
      write_byte(TE_PLAYERATTACHMENT)
      write_byte(id)
      write_coord( 0 ) // for thorns
      write_short( thorns )
      write_short(25)
      message_end()

      message_begin(MSG_ONE,gmsgFade,{0,0,0},enemy)
      write_short( 1<<10 ) // fade lasts this long duration
      write_short( 1<<10 ) // fade lasts this long hold time
      write_short( 1<<12 ) // fade type (in / out)
      write_byte( 255 ) // fade red
      write_byte( 0 ) // fade green
      write_byte( 0 ) // fade blue
      write_byte( iglow[enemy][0] ) // fade alpha
      message_end()
      // End of Thorns Aura
   }

   // [08-10-04] - Evasion now protects against Trueshot strikes - K2mia
   if (p_skills[enemy][SKILLIDX_TRUESHOT] && !p_evadethisshot[id] ) {
      // Trueshot
      damage = read_data(2)

      new Float:ts_dmg = p_trueshot[p_skills[enemy][SKILLIDX_TRUESHOT]-1]

      if (USE_ENH && (p_attribs[enemy][ATTRIBIDX_INT] >= INT_TRUESHOT_LEVEL) ){
         ts_dmg += INT_TRUESHOT_BONUS
         if (get_cvar_num("UW_DEBUG") == 1){
            client_print(enemy, print_console,
               "[%s DEBUG] Intellect-Trueshot damage modified=(%f)", MOD, ts_dmg)
         }
      }

      damage = floatround(float(damage) * ts_dmg)
      do_damage(id, enemy, damage, 3, 1, weapon, bodypart,0)

      if (iglow[id][0] < 1){
         new parm[2]
         parm[0] = id
         set_task(0.01,"glow_change",14,parm,2)
      }

      iglow[id][0] += 2*damage
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
      // End of Trueshot
   }

   if (p_skills[id][SKILLIDX_CARAPACE] && !p_evadethisshot[id]) {
      // Spiked Carapace
      damage = read_data(2)
      damage = floatround(float(damage) * p_spiked[p_skills[id][SKILLIDX_CARAPACE]-1])

      damage = ( damage < SPIKED_MAX_DMG ) ? damage : SPIKED_MAX_DMG

      do_damage(enemy, id,damage,4,2, weapon, bodypart,0)

      new idname[32], ename[32]
      get_user_name(id, idname, 31)
      get_user_name(enemy, ename, 31)

      client_print(enemy, print_chat, "[%s] The spiked armor about %s causes you pain", MOD,  idname)
      client_print(id, print_chat, "[%s] Your spiked carapace hurts %s", MOD, ename)

      if(get_user_armor(id)<101)
         set_user_armor_log(id, (get_user_armor(id)+damage), true, "spiked-1")
         //set_user_armor(id,get_user_armor(id)+damage)

      if (iglow[enemy][0] < 1){
         new parm[2]
         parm[0] = enemy
         set_task(0.01,"glow_change",8,parm,2)
      }

      iglow[enemy][0] += 3*damage
      iglow[enemy][1] = 0
      iglow[enemy][2] = 0
      iglow[enemy][3] = 0

      if (iglow[enemy][0]>MAXGLOW)
         iglow[enemy][0]=MAXGLOW

      // [09-07-04] - Added spiked armor effect - K2mia
      //message_begin(MSG_ALL, SVC_TEMPENTITY)
      message_begin(MSG_ONE,SVC_TEMPENTITY,{0,0,0},enemy)
      write_byte(TE_PLAYERATTACHMENT)
      write_byte(id)
      write_coord( 0 ) // for spikes symbol
      write_short( spikes )
      write_short(25)
      message_end()

      message_begin(MSG_ONE,gmsgFade,{0,0,0},enemy)
      write_short( 1<<10 ) // fade lasts this long duration
      write_short( 1<<10 ) // fade lasts this long hold time
      write_short( 1<<12 ) // fade type (in / out)
      write_byte( 255 ) // fade red
      write_byte( 0 ) // fade green
      write_byte( 0 ) // fade blue
      write_byte( iglow[enemy][0] ) // fade alpha
      message_end()
      // End of Spiked Carapace
   }

   // [08-10-04] - Evasion now protects against Impale - K2mia
   if (p_skills[enemy][SKILLIDX_IMPALE] && !p_evadethisshot[id] ){
      // Impale
      new Float:randomnumber = random_float(0.0,1.0)

      new Float:impale_chance = p_impale[p_skills[enemy][SKILLIDX_IMPALE]-1]

      if (USE_ENH && (p_attribs[enemy][ATTRIBIDX_INT] >= INT_IMPALE_LEVEL) ){
         impale_chance += INT_IMPALE_BONUS
         if (get_cvar_num("UW_DEBUG") == 1){
            client_print(enemy, print_console,
               "[%s DEBUG] Intellect-Impale modified=(%f)", MOD, impale_chance)
         }
      }

      if (randomnumber <= impale_chance){
         if (file_exists("sound/warcraft3/impalehit.wav")==1)
            emit_sound(id,CHAN_ITEM, "warcraft3/impalehit.wav", 1.0, ATTN_NORM, 0, PITCH_NORM)
         new idname[32], ename[32]
         get_user_name(id, idname, 31)
         get_user_name(enemy, ename, 31)

         client_print(enemy, print_chat, "[%s] You cause the ground to shake beneath %s", MOD,  idname)
         client_print(id, print_chat, "[%s] The ground shakes beneath your feet", MOD )

         message_begin(MSG_ONE,gmsgShake,{0,0,0},id)
         write_short(255<< 14 ) //ammount
         write_short(10 << 14) //lasts this long
         write_short(255<< 14) //frequency
         message_end()
      }
      // End of Impale
   }

   // [08-10-04] - Evasion now protects against Hex - K2mia
   if (p_skills[enemy][SKILLIDX_HEX] && !p_evadethisshot[id] ) {
      // Hex
      new Float:randomnumber = random_float(0.0,1.0)

      new Float:hex_chance = p_hex[p_skills[enemy][SKILLIDX_HEX]-1]

      if (USE_ENH && (p_attribs[enemy][ATTRIBIDX_INT] >= INT_HEX_LEVEL) ){
         hex_chance += INT_HEX_BONUS
         if (get_cvar_num("UW_DEBUG") == 1){
            client_print(enemy, print_console,
               "[%s DEBUG] Intellect-Hex modified=(%f)", MOD, hex_chance)
         }
      }

      if ((randomnumber <= hex_chance) && !skinchanged[id]){
         changeskin(id,2)
         new parm[2]
         parm[0]=id
         parm[1]=0
         jumper(parm)

         new idname[32], ename[32]
         get_user_name(id, idname, 31)
         get_user_name(enemy, ename, 31)

         client_print(id,print_chat,"[%s] %s has morphed you into an undesirable form",MOD, ename)
         client_print(enemy,print_chat,"[%s] You have morphed %s into an undesirable form",MOD, idname)
      }
      // End of Hex
   }

   // [08-10-04] - Evasion now protects against Banish - K2mia
   if (p_skills[enemy][SKILLIDX_BANISH] && !p_evadethisshot[id] ) {
      // Banish
      new Float:randomnumber = random_float(0.0,1.0)

      new Float:banish_chance = p_banish[p_skills[enemy][SKILLIDX_BANISH]-1]

      if (USE_ENH && (p_attribs[enemy][ATTRIBIDX_INT] >= INT_BANISH_LEVEL) ){
         banish_chance += INT_BANISH_BONUS
         if (get_cvar_num("UW_DEBUG") == 1){
            client_print(enemy, print_console,
               "[%s DEBUG] Intellect-Banish modified=(%f)", MOD, banish_chance)
         }
      }

      if (randomnumber <= banish_chance){
         new parm[2]
         parm[0]=id

         if(randomnumber>9){
            user_slap(id,0)
            user_slap(id,0)
            user_slap(id,0)
            do_damage(id, id,9,5,2, weapon, bodypart,0)
         }else{
            user_slap(id,0)
            user_slap(id,0)
            user_slap(id,0)
            do_damage(id, id,7,5,2, weapon, bodypart,0)
         }

         if (file_exists("sound/warcraft3/banishcaster.wav")==1)
            emit_sound(enemy,CHAN_STATIC, "warcraft3/banishcaster.wav", 1.0, ATTN_NORM, 0, PITCH_NORM)

         if (iglow[id][3] < 1){
            parm[0] = id
            parm[1] = 0
            set_task(0.01,"glow_change",11,parm,2)
         }

         iglow[id][3] += 100
         iglow[id][0] = 0
         iglow[id][1] = 0
         iglow[id][2] = 0

         if (iglow[id][3]>MAXGLOW)
            iglow[id][3]=MAXGLOW

         new idname[32], ename[32]
         get_user_name(id, idname, 31)
         get_user_name(enemy, ename, 31)

         client_print(enemy, print_chat, "[%s] You have banished %s", MOD,  idname)
         client_print(id, print_chat, "[%s] You have been banished by %s", MOD, ename)

         message_begin(MSG_ONE,gmsgFade,{0,0,0},id)
         write_short( 1<<10 ) // fade lasts this long duration
         write_short( 1<<10 ) // fade lasts this long hold time
         write_short( 1<<12 ) // fade type (in / out)
         write_byte( 255 ) // fade red
         write_byte( 255 ) // fade green
         write_byte( 255 ) // fade blue
         write_byte( iglow[id][3] ) // fade alpha
         message_end()
      }
      // End of Banish
   }

   // [08-10-04] - Evasion now protects against Siphon Mana - K2mia
   if (p_skills[enemy][SKILLIDX_SIPHON] && !p_evadethisshot[id] ) {
      // Siphon Mana
      new money = cs_get_user_money(id)

      // [08-07-04] - Money modified by high intellect bonus
      new Float:money_percent = p_mana[p_skills[enemy][SKILLIDX_SIPHON]-1]

      if (USE_ENH && (p_attribs[enemy][ATTRIBIDX_INT] >= INT_SIPHON_LEVEL) ){
         money_percent += INT_SIPHON_BONUS
         if (get_cvar_num("UW_DEBUG") == 1){
            client_print(enemy, print_console,
               "[%s DEBUG] Intellect-Siphon modified=(%f)", MOD, money_percent)
         }
      }
      money = floatround(money_percent * money)

      if ( !is_user_connected( id ) || !is_user_connected( enemy ) )
         return PLUGIN_CONTINUE

      cs_set_user_money(enemy, cs_get_user_money(enemy)+money,1)
      cs_set_user_money(id, cs_get_user_money(id)-money,1)

      new idname[32], ename[32]
      get_user_name(id, idname, 31)
      get_user_name(enemy, ename, 31)

      client_print(enemy, print_chat, "[%s] You siphon $%d from %s", MOD,  money, idname)
      client_print(id, print_chat, "[%s] You have been robbed of $%d by %s", MOD, money, ename)

      if (iglow[enemy][1] < 1){
         new parm[2]
         parm[0] = enemy
         set_task(0.01,"glow_change",9,parm,2)
      }

      iglow[enemy][1] += damage
      iglow[enemy][0] = 0
      iglow[enemy][2] = 0
      iglow[enemy][3] = 0

      if (iglow[enemy][1]>MAXGLOW)
         iglow[enemy][1]=MAXGLOW

      message_begin(MSG_ONE,gmsgFade,{0,0,0},enemy)
      write_short( 1<<10 ) // fade lasts this long duration
      write_short( 1<<10 ) // fade lasts this long hold time
      write_short( 1<<12 ) // fade type (in / out)
      write_byte( 120 ) // fade red
      write_byte( 120 ) // fade green
      write_byte( 120 ) // fade blue
      write_byte( iglow[enemy][1] ) // fade alpha
      message_end()
      // End of Siphon Mana
   }

   // [08-10-04] - Evasion now protects against Vampiric Aura - K2mia
   // [08-04-04] - Modified Vampiric to not pass test if enemy in full health  - K2mia
   if (p_skills[enemy][SKILLIDX_VAMPIRIC] && (get_user_health(enemy) < maxhealth[enemy])
       && !p_evadethisshot[id] )
   {
      // Vampiric Aura
      damage = read_data(2)
      damage = floatround(float(damage)*p_vampiric[p_skills[enemy][SKILLIDX_VAMPIRIC]-1])

      // [09-29-04] Rewrote Vampiric ceiling checks - K2mia
      // Set max_health to be the lesser of p_vampiric or maxhealth[enemy]
      new max_health = 
         ( (maxhealth[enemy] > p_vampirichealth[p_skills[enemy][SKILLIDX_VAMPIRIC]-1]) ?
           p_vampirichealth[p_skills[enemy][SKILLIDX_VAMPIRIC]-1] : maxhealth[enemy] )

      // Add in healthbonus if player has health item
      if ( playeritem[enemy]==HEALTH )
         max_health += HEALTHBONUS

      new new_health = ( get_user_health(enemy) + damage )

      if ( new_health > max_health ) 
         new_health = max_health

      set_user_health_log(enemy, new_health, true, "damage_event() VAMPIRIC")

      if (p_skills[enemy][SKILLIDX_SSKIN]){
         // Steel Skin, give armor to the enemy
         set_user_armor_log(enemy, (get_user_armor(enemy)+damage), true, "sskin-1")
         //set_user_armor(enemy, get_user_armor(enemy) + damage)

         new abonusmult = ARMORBONUS2
         new abonus = 0
         new atotal = 0

         if (p_level[enemy] > 30) abonus = (abonusmult * 6)
         else if (p_level[enemy] > 25) abonus = (abonusmult * 5)
         else if (p_level[enemy] > 20) abonus = (abonusmult * 4)
         else if (p_level[enemy] > 15) abonus = (abonusmult * 3)
         else if (p_level[enemy] > 10) abonus = (abonusmult * 2)
         else abonus = abonusmult

         atotal = (NORMALARMORMAX + abonus)

         if (get_user_armor(enemy) > atotal) 
            set_user_armor_log(enemy, atotal, true, "sskin-2")
            //set_user_armor(enemy, atotal)

         if (vampiric_hits[enemy] % 5 == 0){
            client_print(enemy, print_chat,
               "[%s] Your Steel Skin gleams as your Vampiric Aura strengthens your armor",
                MOD )
         }
      }

      // [08-03-04] - Rewrote ceiling checks for Vampiric - K2mia
      /*
      new health = (playeritem[enemy]==HEALTH) ? maxhealth[enemy] + HEALTHBONUS :
             maxhealth[enemy]
      new health2 = (playeritem[enemy]==HEALTH) ?
             p_vampirichealth[p_skills[enemy][SKILLIDX_VAMPIRIC]-1] + HEALTHBONUS :
             p_vampirichealth[p_skills[enemy][SKILLIDX_VAMPIRIC]-1]

      if (health > health2) health = health2

      if (get_user_health(enemy) > health)
         set_user_health_log(enemy, health, true, "damage_event() VAMPIRIC2" )
      */

      vampiric_hits[enemy] += 1

      if (vampiric_hits[enemy] % 5 == 0){
         // Only show Vampiric Aura messages after every 5 hits
         new idname[32], ename[32]
         get_user_name(id, idname, 31)
         get_user_name(enemy, ename, 31)

         client_print(enemy, print_chat,
            "[%s] Your Vampiric Aura steals health from %s", MOD,  idname)
         client_print(id, print_chat,
            "[%s] Your lifeforce has been drained by %s", MOD, ename)
      }

      if (iglow[enemy][1] < 1){
         new parm[2]
         parm[0] = enemy
         set_task(0.01,"glow_change",9,parm,2)
      }

      iglow[enemy][1] += damage
      iglow[enemy][0] = 0
      iglow[enemy][2] = 0
      iglow[enemy][3] = 0

      if (iglow[enemy][1]>MAXGLOW)
         iglow[enemy][1]=MAXGLOW

      message_begin(MSG_ONE,gmsgFade,{0,0,0},enemy)
      write_short( 1<<10 ) // fade lasts this long duration
      write_short( 1<<10 ) // fade lasts this long hold time
      write_short( 1<<12 ) // fade type (in / out)
      write_byte( 0 ) // fade red
      write_byte( 255 ) // fade green
      write_byte( 0 ) // fade blue
      write_byte( iglow[enemy][1] ) // fade alpha
      message_end()
      // End of Vampiric Aura
   }

   // [08-10-04] - Evasion now protects against Bash - K2mia
   if (p_skills[enemy][SKILLIDX_BASH] && !p_evadethisshot[id] ) {
      // Bash
      new Float:randomnumber = random_float(0.0,1.0)

      new Float:bash_chance = p_bash[p_skills[enemy][SKILLIDX_BASH]-1]

      if (USE_ENH && (p_attribs[enemy][ATTRIBIDX_INT] >= INT_BASH_LEVEL) ){
         bash_chance += INT_BASH_BONUS
         if (get_cvar_num("UW_DEBUG") == 1){
            client_print(enemy, print_console,
               "[%s DEBUG] Intellect-Bash modified=(%f)", MOD, bash_chance)
         }
      }

      if ((randomnumber <= bash_chance) && (get_user_maxspeed(id) > 10) && !slowed[id]){
         // Cannot bash if already bashed or frosted
         new normalspeed = floatround(get_user_maxspeed(id))
         set_user_maxspeed(id,1.0)
         stunned[id]=true
         new parm[2]
         parm[0]=id
         parm[1]=normalspeed
         set_task(1.0,"reset_maxspeed",1000+id,parm,2)

         new idname[32], ename[32]
         get_user_name(id, idname, 31)
         get_user_name(enemy, ename, 31)

         client_print(enemy, print_chat, "[%s] Your Bash has stunned %s", MOD,  idname)
         client_print(id, print_chat, "[%s] You have been stunned by %s", MOD, ename)

         if (iglow[id][3] < 1){
            parm[0] = id
            parm[1] = 0
            set_task(0.01,"glow_change",11,parm,2)
         }

         iglow[id][3] += 100
         iglow[id][0] = 0
         iglow[id][1] = 0
         iglow[id][2] = 0

         if (iglow[id][3]>MAXGLOW)
            iglow[id][3]=MAXGLOW

         message_begin(MSG_ONE,gmsgFade,{0,0,0},id)
         write_short( 1<<10 ) // fade lasts this long duration
         write_short( 1<<10 ) // fade lasts this long hold time
         write_short( 1<<12 ) // fade type (in / out)
         write_byte( 255 ) // fade red
         write_byte( 255 ) // fade green
         write_byte( 255 ) // fade blue
         write_byte( iglow[id][3] ) // fade alpha
         message_end()
      }
      // End of Bash
   }

   // [08-10-04] - Evasion now protects against Critical Strike - K2mia
   if (p_skills[enemy][SKILLIDX_CRITSTRIKE] && !p_evadethisshot[id] ){
      // Critical Strike
      new Float:randomnumber = random_float(0.0,1.0)
      if (randomnumber <= p_critical[p_skills[enemy][SKILLIDX_CRITSTRIKE]-1]){
         damage = read_data(2)
         // Changed to only do double damage
         //damage = floatround(float(damage) * 2)
            
         new idname[32], ename[32]
         get_user_name(id, idname, 31)
         get_user_name(enemy, ename, 31)

         if (hasgodmode[id]){
            client_print(enemy, print_chat,  
               "[%s] Your critical strike is deflected by Big Bad Voodoo", MOD )
            client_print(id, print_chat,
               "[%s] Your Big Bad Voodoo protects you from a critical strike", MOD )
         }else{
            do_damage(id, enemy, damage, 6, 1, weapon, bodypart,0)
            client_print(enemy, print_chat,
               "[%s] You strike a critical blow to %s", MOD,  idname)
            client_print(id, print_chat,
               "[%s] You were hit by a critical strike from %s", MOD, ename)
         }
         
         //client_print(0, print_console,
         //  "[%s DEBUG] In Critical Strike (%s => %s) Skills Dump Follows", MOD, ename, idname)   

         if (iglow[id][0] < 1){
            new parm[2]
            parm[0] = id
            set_task(0.01,"glow_change",12,parm,2)
         }

         iglow[id][0] += damage
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
      // Critical Strike
   }

   // [08-10-04] - Evasion now protects against Critical Grenades - K2mia
   if (p_skills[enemy][SKILLIDX_CRITGREN] && !p_evadethisshot[id] ){
      // Critical Grenade 
      new bool:allow=true
      if(playeritem2[enemy]==INFERNO){
         if(get_cvar_num("FT_glove_orc_damage"))
            allow=true
         else
            allow=false
      }else{
         allow=true
      }  
            
      if(no_he)
         allow=false
               
      if ( (weapon == 4) &&
          ((p_resists[id][RESISTIDX_MAGIC] >= RESIST_MAX_VALUE) || magic_saving_throw(id)))           
      {        
         allow = false
         client_print(id, print_chat,  
            "[%s] Your magic resistance protects you from Critical Grenade damage", MOD)
      }  
         
      if (weapon == 4 && allow){
         damage = read_data(2)
         damage = floatround(float(damage)*p_grenade[p_skills[enemy][SKILLIDX_CRITGREN]-1])        
         do_damage(id, enemy,damage,7,1, weapon, bodypart,0)
         new name[32] 
         get_user_name(id,name,31)
         
         if (iglow[id][0] < 1){
            new parm[2]
            parm[0] = id
            set_task(0.01,"glow_change",13,parm,2)
         }

         iglow[id][0] += damage
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
      // End of Critical Grenade
   }

   // [08-10-04] - Evasion now protects against Napalm Grenades - K2mia
   if (p_skills[enemy][SKILLIDX_NAPALM] && !p_evadethisshot[id] ){
      // Napalm Grenade
         
      if (threwnapalm[enemy]) return PLUGIN_CONTINUE
         
      new bool:allow=true
      if(playeritem2[enemy]==INFERNO){
         if(get_cvar_num("FT_glove_napalm_damage"))
            allow = true
         else
            allow = false
      }else{
         allow = true
      }
          
      if(no_he)
         allow = false
         
         
      // Necklace of Immunity now protects against Napalm 
      if (playeritem[id] == IMMUNITY)
         allow = false
      
      if (weapon == 4 && allow){
         threwnapalm[enemy] += 1

         damage = read_data(2)
         do_damage(id, enemy,damage, 17, 1, weapon, bodypart,0)
         
         emit_sound(id, CHAN_WEAPON , "scientist/scream07.wav", 1.0,
            ATTN_NORM, 0, PITCH_HIGH)
            
         // [09-05-04] Attach fireball sprite to player for 1 cycle
         message_begin(MSG_ALL, SVC_TEMPENTITY )
         write_byte(TE_PLAYERATTACHMENT)
         write_byte(id)
         write_coord( 0 )      // z axis for sprite
         write_short( blast )  // blast sprite
         write_short(9) 
         message_end()
         
         burn_victim_napalm(id, enemy, 0)
            
         new name[32], ename[32]
         get_user_name(id,name,31)
         get_user_name(enemy,ename,31)
         
         client_print(id, print_chat, 
            "[%s] %s has burned you with a Napalm Grenade, Eeek!", MOD, ename)
         client_print(enemy, print_chat, "[%s] Your Napalm Grenade burns %s", MOD, name)
      }  
      // End of Napalm Grenade
   }     
      
   // [08-10-04] - Evasion now protects against all item-based attacks - K2mia
   if ((playeritem[enemy] == CLAWS) && !p_evadethisshot[id] ){
      // Claws of Attack
      damage = CLAWSOFATTACK
      do_damage(id, enemy,damage,8,1, weapon, bodypart,0)

      if (iglow[id][0] < 1){
         new parm[2]
         parm[0] = id
         set_task(0.01,"glow_change",14,parm,2)
      }

      iglow[id][0] += 2*damage
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
      // End of Claws of Attack
   }else if (playeritem[enemy] == MASK){
      // Mask of Death
      damage = read_data(2)
      damage = floatround(float(damage) * MASKPERCENT)

      new health = get_user_health(enemy) + damage
      if ( health > maxhealth[enemy] ) health = maxhealth[enemy]

      set_user_health_log(enemy, health, true, "damage_event() MASK2")

      if (iglow[enemy][1] < 1){
          new parm[2]
          parm[0] = enemy
          set_task(0.01,"glow_change",9,parm,2)
      }

      iglow[enemy][1] += damage
      iglow[enemy][0] = 0
      iglow[enemy][2] = 0
      iglow[enemy][3] = 0

      if (iglow[enemy][1]>MAXGLOW)
         iglow[enemy][1]=MAXGLOW

      message_begin(MSG_ONE,gmsgFade,{0,0,0},enemy)
      write_short( 1<<10 ) // fade lasts this long duration
      write_short( 1<<10 ) // fade lasts this long hold time
      write_short( 1<<12 ) // fade type (in / out)
      write_byte( 0 ) // fade red
      write_byte( 255 ) // fade green
      write_byte( 0 ) // fade blue
      write_byte( iglow[enemy][1] ) // fade alpha
      message_end()
      // End of Mask of Death
   }else if (playeritem[enemy] == FROST && !p_evadethisshot[id] ){
      // Frost (DOESN'T WORK ON BOTS)
      if (get_user_maxspeed(id)>10 && !slowed[id]){
         // Cannot frost if bashed or frosted
         new normalspeed = floatround(get_user_maxspeed(id))
         // Replace "id" with "enemy" to test bash on self
         set_user_maxspeed(id,FROSTSPEED)
         slowed[id]=true
         new parm[2]
         parm[0]=id
         parm[1]=normalspeed
         set_task(1.0,"reset_maxspeed",1000+id,parm,2)

         if (iglow[id][3] < 1){
            parm[0] = id
            parm[1] = 0
            set_task(0.01,"glow_change",11,parm,2)
         }

         iglow[id][3] += 100
         iglow[id][0] = 0
         iglow[id][1] = 0
         iglow[id][2] = 0

         if (iglow[id][3]>MAXGLOW)
            iglow[id][3]=MAXGLOW

         message_begin(MSG_ONE,gmsgFade,{0,0,0},id)
         write_short( 1<<10 ) // fade lasts this long duration
         write_short( 1<<10 ) // fade lasts this long hold time
         write_short( 1<<12 ) // fade type (in / out)
         write_byte( 255 ) // fade red
         write_byte( 255 ) // fade green
         write_byte( 255 ) // fade blue
         write_byte( iglow[id][3] ) // fade alpha
         message_end()
      }
   }

   return PLUGIN_CONTINUE
}
// **************************************************************************
// END damage_event subroutine
// **************************************************************************



// **************************************************************************
// BEGIN death subroutine
// Handler for death event - Called when you die
// **************************************************************************
public death(){

   if (!warcraft3)
      return PLUGIN_CONTINUE

   new killer_id = read_data(1)
   new victim_id = read_data(2)
   new headshot = read_data(3)

   new kname[32], vname[32]
   get_user_name(killer_id, kname, 31)
   get_user_name(victim_id, vname, 31)

   //client_print(0, print_console, "[%s DEBUG] [In death()-1] killer=(%s) victim=(%s) hs=(%d)", MOD, kname, vname, headshot)

   // [07-27-04] - Added Logging for all deaths to determine if Voodoo is bugged
   //new sLogText[256] = ""
   //format( sLogText, 255, "In death() %s killed by %s :: Victim-Godmode=(%d) Killer-Godmode=(%d) :: Killer-Blink=(%d) Killer-Items=(%d , %d)", vname, kname, hasgodmode[victim_id], hasgodmode[killer_id], p_skills[killer_id][SKILLIDX_BLINK], playeritem[killer_id], playeritem2[killer_id] )
   //log_amx(sLogText)

   if ( !is_user_connected( victim_id ) )
      return PLUGIN_CONTINUE

   // Determine if victim has Nightvision
   hasnvision[victim_id] = cs_get_user_nvg(victim_id)

   if (task_exists(2000+victim_id))
      // Remove the function that makes you jump if you're goombad
      remove_task(2000+victim_id)

   // Remove icon because you don't have an ultimate when you're dead
   icon_controller(victim_id,ICON_HIDE)

   ismole[victim_id]=false                 // For use w/mole protectant

   if (playeritem2[victim_id]==CHAMELEON || skinchanged[victim_id])
      changeskin(victim_id,1)

   if (playeritem2[victim_id]==HELM)
      set_user_hitzones(0,victim_id,255)

   if(playeritem2[victim_id]==RESPAWN && !changingteam[victim_id]){
      new parm[2]
      parm[0]=victim_id
      parm[1]=6

      if(playeritem2[victim_id]!=MOLE){
         playeritem2[victim_id]=0
         rings[victim_id]=0
      }

      playeritem[victim_id]=0
      set_task(0.5,"func_spawn",72,parm,2)
      spawnedfromitem[victim_id]=true
   }

   rings[victim_id]=0
   set_user_footsteps(victim_id, 0)

   new weaponname[20]
   read_data(4,weaponname,31)
   new weapon
   get_user_attacker(victim_id,weapon)

   //client_print(0, print_console, "[%s DEBUG] [In death()-2] killer=(%s) victim=(%s) hs=(%d) weaponname=(%s)", MOD, kname, vname, headshot, weaponname)

   //if (equal(weaponname,"world")){
   //   client_print(0, print_console, "[%s DEBUG] [In death()-3] killer=(%s) victim=(%s)  KILLED BY WORLD",
   //      MOD, kname, vname )
   //}

   /*
   if( headshot && killer_id!=victim_id && !deathmessageshown[victim_id] &&
       get_user_team(victim_id)!=get_user_team(killer_id))
   {
      playerxp[killer_id]+= HEADSHOT_BONUS
      if (get_cvar_num("FT_kill_objectives")){
         client_print(0, print_console, "UWC3-DEBUG: HEADSHOT (death()) - killer=(%d) victim=(%d)", killer_id, victim_id)
         client_print(killer_id,print_chat,"[%s] You are awarded %d XP for having a headshot", MOD, HEADSHOT_BONUS)//?
      }
   }
   */

   if(!deathmessageshown[victim_id] && killer_id!=victim_id &&
      !equal(weaponname,"world"))
   {
      deathmessageshown[victim_id]=true
      message_begin( MSG_ALL, gmsgDeathMsg,{0,0,0},0)
      write_byte(killer_id)
      write_byte(victim_id)
      write_byte(headshot)
      write_string(weaponname)
      write_string(weaponname)
      message_end()
   }

   changingteam[victim_id]=false
   diedlastround[victim_id]=true

   // Player either has ultimate Vengeance OR Suicide Bomber
   if (p_skills[victim_id][SKILLIDX_VENGEANCE] &&
       (!hasblink[killer_id] || killer_id==victim_id) && !u_delay)
   {
      // Vengeance
      new parm[2]
      parm[0]=victim_id
      parm[1]=6

      // [07-14-04] Vengeance check within ultimate timer - K2mia
      if (get_cvar_num("UW_force_vengeance")){
         // Only check for end of round
         if( !endround && !vengeance_used[victim_id] ){
            vengeance_used[victim_id] = 1
            vengeance_state[victim_id] = VENG_WAIT 
            set_task(1.2,"func_spawn",2,parm,2)
            ultimateused[victim_id]=true
         }
      }else{
         // Restrict Vengeance if another ultimate was recently used
         if( !endround && !ultimateused[victim_id] && !vengeance_used[victim_id] ){
            vengeance_used[victim_id] = 1
            vengeance_state[victim_id] = VENG_WAIT 
            set_task(1.2,"func_spawn",2,parm,2)
            ultimateused[victim_id]=true
         }
      }

      // [08-27-04] - Vengeance cooldown added, so ultimates can again be used
      set_task(get_cvar_float("UW_vengeance_cooldown"), "cooldown", 500+victim_id, parm, 1)

      // End of Vengeance
   }else if (p_skills[victim_id][SKILLIDX_SUICIDE] && !hasblink[killer_id] &&
             !changingteam[victim_id] && !u_delay){
      // Suicide Bomber
      emit_sound(victim_id,CHAN_ITEM, "ambience/particle_suck1.wav", 1.0, ATTN_NORM, 0, PITCH_NORM)
      new parm[5], origin[3]
      get_user_origin(victim_id,origin)
      parm[0]=victim_id
      parm[1]=6
      parm[2]=origin[0]
      parm[3]=origin[1]
      parm[4]=origin[2]

      set_task(0.1,"implosion",1,parm,5)
      set_task(0.2,"apacheexplode",2,parm,5)
      set_task(0.3,"blastcircles",3,parm,5)
      // End of Suicide Bomber
   }

   // [10-19-04] Do not invoke Phoenix if waiting for Vengeance respawn - K2mia
   if ( vengeance_state[victim_id] != VENG_WAIT )
      check_for_reviving(victim_id)

   saveweapons(victim_id)

   xpgiven = xpgiven_lev[p_level[killer_id]]

   if (killer_id && killer_id!=victim_id && victim_id){
      new name[32]
      get_user_name(victim_id,name,31)
      if (get_user_team(killer_id) == get_user_team(victim_id)){
         // Negative experience awarded for team kill
         if (get_cvar_num("FT_kill_objectives")){
            playerxp[killer_id] -= xpgiven
            client_print(killer_id, print_chat,
              "[%s] You have been penalized %d XP for killing %s", MOD, xpgiven, name)
         }
      }else{
         if (!get_cvar_num("mp_weaponxpmodifier")){
            if (get_cvar_num("FT_kill_objectives")){
               playerxp[killer_id] += xpgiven
               client_print(killer_id, print_chat,
                 "[%s] You are awarded %d XP for killing %s",MOD,xpgiven,name)
            }
         }else{
            if (get_cvar_num("FT_kill_objectives")){
               playerxp[killer_id] += floatround(xpgiven*weaponxpmultiplier[weapon])
               client_print(killer_id, print_chat,
                 "[%s] You are awarded %d XP for killing %s",MOD,xpgiven,name)
            }
         }

         if (victim_id==hostagesaver &&
             get_user_team(victim_id) != get_user_team(killer_id))
         {
            playerxp[killer_id] += KILLRESCUEMANXP
            client_print(killer_id, print_chat,
             "[%s] You received %d XP for killing the hostage rescuer",MOD, KILLRESCUEMANXP)
         }
      }

      if ( get_cvar_num("UW_dmgxpbonus") ){
         // [7-1-04] K2mia => Added partial kill XP for majority dmg dealer
         new mdmg = 0           // current max dmg done to victim_id
         new dmg_id = killer_id // current max damager
         new dmgxp = 0

         new pid, numplayers, players[32]
         get_players(players, numplayers)

         for (new i=0; i< numplayers; i++){
            pid = players[i]
            if (damageto[pid][victim_id] > mdmg){
               mdmg = damageto[pid][victim_id]
               dmg_id = pid
            }

            // [09-14-04] Prevent dmg from being used again - K2mia
            damageto[pid][victim_id] = -1
         }

         new kteam = get_user_team(killer_id)

         // [08-22-04] - Prevent SPEC from getting serious injury XP
         if ((dmg_id != killer_id) && (dmg_id != victim_id) &&
            (kteam == TEAM_T || kteam == TEAM_CT) )
         {
            dmgxp = xpgiven_lev[p_level[dmg_id]]
            new dname[32]
            get_user_name(dmg_id, dname, 31)

            //client_print(0, print_console, "[%s] BEFORE serious injury bonus for [%d](%s) xp=(%d) bonus=(%d)", MOD, dmg_id, dname, playerxp[dmg_id], dmgxp)

            playerxp[dmg_id] += dmgxp

            //client_print(0, print_console, "[%s] AFTER serious injury bonus for [%d](%s) xp=(%d) bonus=(%d)", MOD, dmg_id, dname, playerxp[dmg_id], dmgxp)

            client_print(dmg_id, print_chat, "[%s] You receive an XP bonus of %d for seriously injuring %s", MOD, dmgxp, name)
            //client_print(0, print_console, "[%s] You receive an XP bonus of %d for seriously injuring %s", MOD, dmgxp, name)
         }


      }

      if (get_cvar_num("UW_underdog_kills") && (p_level[killer_id] < p_level[victim_id])){
         // Handler for underdog kill XP bonuses
         new lev_diff = ( p_level[victim_id] - p_level[killer_id] )
         new udogxp = (lev_diff * XPBONUS)
         new udogpenalty = udogxp

         if (lev_diff >= 30){
            udogxp += (3 * xpgiven_lev[p_level[victim_id]])
            udogpenalty += (2 * xpgiven_lev[p_level[killer_id]])
         }else if (lev_diff >= 20){
            udogxp += (2 * xpgiven_lev[p_level[victim_id]])
            udogpenalty += floatround(2.25 * xpgiven_lev[p_level[killer_id]])
         }else if (lev_diff >= 10){
            udogxp += floatround(1.5 * xpgiven_lev[p_level[victim_id]])
            udogpenalty += floatround(1.75 * xpgiven_lev[p_level[killer_id]])
         }

         playerxp[killer_id] += udogxp
         playerxp[victim_id] -= udogpenalty

         client_print(killer_id, print_chat,
            "[%s] You receive an Underdog XP bonus of %d for killing %s", MOD, udogxp, name)
         client_print(victim_id, print_chat,
            "[%s] You lose an Underdog XP penalty of %d for being killed by %s", MOD, udogpenalty, kname)
      }

      displaylevel(killer_id, 1)
   }

   if (victim_id==bombdefuser && killer_id!=bombdefuser && get_user_team(victim_id)!=get_user_team(killer_id)){
      new temp
      temp = DEFUSER_KILL_BONUS +  xpgiven

      playerxp[killer_id]+=  temp

      if (get_cvar_num("FT_objectives")){
         new killersname[33]
         get_user_name(killer_id,killersname,31)
         client_print(killer_id,print_chat, "[%s] received %s %d XP for killing the bomb defuser",MOD,killersname,temp)
      }
   }

   if (victim_id==bombCarrier && killer_id!=bombCarrier &&
       get_user_team(victim_id)!=get_user_team(killer_id))
   {
      new temp
      temp = KILL_BOMB_CARRIER +  xpgiven
      playerxp[killer_id]+=  temp

      if (get_cvar_num("FT_objectives")){
         new killersname[33]
         get_user_name(killer_id,killersname,31)
         client_print(killer_id,print_chat, "[%s] received %s %d XP for killing the bomb carrier",MOD,killersname,temp)
      }
   }

   return PLUGIN_CONTINUE

}
// **************************************************************************
// END death subroutine
// **************************************************************************


// **************************************************************************
// BEGIN do_cbdisease subroutine
// Disease effect for Carrion Beetles skill
// **************************************************************************
public do_cbdisease(args[]){

   new id = args[0]
   new enemy = args[1]

   if(!is_user_alive(id) || isdiseasedcb[id] == 0)
      return PLUGIN_CONTINUE

   if (iglow[id][0] < 1){
      new parm[2]
      parm[0] = id
      set_task(0.01,"glow_change",8,parm,2)
   }

   iglow[id][0] += 45
   iglow[id][1] = 0
   iglow[id][2] = 0
   iglow[id][3] = 0

   if (iglow[id][0]>MAXGLOW)
      iglow[id][0]=MAXGLOW

   message_begin(MSG_ONE,gmsgFade,{0,0,0},id)
   write_short( 1<<10 ) // fade lasts this long duration
   write_short( 1<<10 ) // fade lasts this long hold time
   write_short( 1<<12 ) // fade type (in / out)
   write_byte( 0 )      // fade red
   write_byte( 255 )    // fade green
   write_byte( 150 )      // fade blue
   write_byte( iglow[id][0] ) // fade alpha
   message_end()

   // Set the player to have a slow max speed
   set_user_maxspeed(id, CBSPEED)

   do_damage(id, enemy, 3, 19, 2, 0, 0, 0)

   return PLUGIN_CONTINUE
}
// **************************************************************************
// BEGIN do_cbdisease subroutine
// **************************************************************************


// **************************************************************************
// BEGIN do_sspoison subroutine
// Poison effect for Shadow Strike skill
// **************************************************************************
public do_sspoison(args[]){

   new id = args[0]
   new enemy = args[1]

   if(!is_user_alive(id) || ispoisonedss[id] == 0)
      return PLUGIN_CONTINUE

   if (iglow[id][0] < 1){
      new parm[2]
      parm[0] = id
      set_task(0.01,"glow_change",8,parm,2)
   }

   iglow[id][0] += 45
   iglow[id][1] = 0
   iglow[id][2] = 0
   iglow[id][3] = 0

   if (iglow[id][0]>MAXGLOW)
      iglow[id][0]=MAXGLOW

   message_begin(MSG_ONE,gmsgFade,{0,0,0},id)
   write_short( 1<<10 ) // fade lasts this long duration
   write_short( 1<<10 ) // fade lasts this long hold time
   write_short( 1<<12 ) // fade type (in / out)
   write_byte( 0 )      // fade red
   write_byte( 255 )    // fade green
   write_byte( 0 )      // fade blue
   write_byte( iglow[id][0] ) // fade alpha
   message_end()

   do_damage(id, enemy, 5, 18, 2, 0, 0, 0)

   return PLUGIN_CONTINUE
}
// **************************************************************************
// END do_sspoison subroutine
// **************************************************************************


// **************************************************************************
// BEGIN burn_victim_napalm on_fire_napalm subroutines
// For use with skills that cause burning from Napalm
// **************************************************************************
burn_victim_napalm(id,killer,tk){

   //client_print(0, print_console,
   //   "In burn_victim_napalm() id=(%d) killer=(%d) isnburning=(%d)", id, killer, isnburning[id])

   if(isnburning[id] == 1)
      return PLUGIN_CONTINUE

   if (playeritem[id]==IMMUNITY || hasblink[id])
      return PLUGIN_CONTINUE

   isnburning[id] = 1

   new hp,args[4]
   hp = get_user_health(id)
   if(hp > 250)
      hp = 250

   // [08-06-04] - Added Fire Resistance Checks - K2mia
   new Float:ftimer = 2.0
   new bool:do_burn = true

   if (USE_ENH && p_resists[id][RESISTIDX_FIRE]){
      new Float:chance_to_avoid = (p_resists[id][RESISTIDX_FIRE] >= RESIST_MAX_VALUE) ?
             1.00 : (float(p_resists[id][RESISTIDX_FIRE]) / float(RESIST_MAX_VALUE))

      new Float:randomnumber = random_float(0.0,1.0)

      client_print(id, print_console, "DEBUG: fresist=(%d) chance_to_avoid=(%f) rnum=(%f)",
         p_resists[id][RESISTIDX_FIRE], chance_to_avoid, randomnumber)

      if (randomnumber < chance_to_avoid){
         do_burn = false
         client_print(id, print_chat,
            "[%s] Your fire resistance protects you from a napalm grenade attack", MOD)
         client_print(killer, print_chat,
            "[%s] Your napalm grenade attack is deflected by your target's fire resistance",
            MOD)
      }else if ((randomnumber/2.0) < chance_to_avoid ){
         ftimer = 4.0
         client_print(id, print_chat, "[%s] Your fire resistance fails to fully protect you from a napalm grenade attack", MOD)
      }
   }

   if (do_burn){
      args[0] = id
      args[1] = killer
      args[2] = tk
      set_task(ftimer, "on_fire_napalm", 451, args, 4, "b");
   }else{
      isnburning[id] = 0
   }

   return PLUGIN_CONTINUE
}

public on_fire_napalm(args[]){

   new rx,ry,rz,forigin[3]
   new id = args[0]

   new killer = args[1]

   //client_print(0, print_console,
   //   "In on_fire_napalm() id=(%d) killer=(%d) isnburning=(%d)", id, killer, isnburning[id])

   if(!is_user_alive(id) || (isnburning[id] == 0))
      return PLUGIN_CONTINUE

   rx = random_num(-30,30)
   ry = random_num(-30,30)
   rz = random_num(-30,30)
   get_user_origin(id,forigin)

   emit_sound(id, CHAN_ITEM,  "ambience/flameburst1.wav", 0.6, ATTN_NORM, 0, PITCH_NORM)

   // [09-05-04] Attach fireball sprite to player for 1 cycle
   message_begin(MSG_ALL, SVC_TEMPENTITY )
   write_byte(TE_PLAYERATTACHMENT)
   write_byte(id)
   write_coord( 0 )      // z axis for sprite
   write_short( blast )  // blast sprite
   write_short(9)
   message_end()

   //TE_SPRITE - additive sprite, plays 1 cycle
   message_begin( MSG_BROADCAST,SVC_TEMPENTITY)
   write_byte( 17 )
   write_coord(forigin[0]+rx) // coord, coord, coord (position)
   write_coord(forigin[1]+ry)
   write_coord(forigin[2]+10+rz)
   write_short( burning ) // short (sprite index)
   write_byte( 30 ) // byte (scale in 0.1's)
   write_byte( 200 ) // byte (brightness)
   message_end()

   //Smoke
   message_begin( MSG_BROADCAST,SVC_TEMPENTITY)
   write_byte( 5 )
   write_coord(forigin[0]+(rx*2)) // coord, coord, coord (position)
   write_coord(forigin[1]+(ry*2))
   write_coord(forigin[2]+100+(rz*2))
   write_short( g_sModelIndexSmoke )// short (sprite index)
   write_byte( 60 ) // byte (scale in 0.1's)
   write_byte( 15 ) // byte (framerate)
   message_end()

   if(is_user_alive(id) == 0)
      return PLUGIN_CONTINUE

   do_damage(id, killer, 5, 17, 2, 0, 0, 0)

   return PLUGIN_CONTINUE
}
// **************************************************************************
// END burn_victim_napalm on_fire_napalm subroutines
// **************************************************************************



// **************************************************************************
// END Damage/Events Subroutine Declarations
// **************************************************************************

