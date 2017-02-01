
/** *************************************************************************
*** AMXX Plugin:   Ultimate Warcraft3 (UWC3)
*** Plugin Author: K2mia
*** UWC3 Module:   Utility Routines
*** Date:          May 25, 2004
*** Last Update:   September 23, 2004
*
*  Module: Utility Routines
*  All-purpose utilities, miscellaneous subroutines
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
// BEGIN Utility Subroutine Declarations
// **************************************************************************


// **************************************************************************
// BEGIN check_war3 subroutine
// Make sure WC3 is running
// **************************************************************************
public check_war3(){

   if (get_cvar_num("sv_warcraft3")==0){
      warcraft3=false
      set_msg_block(gmsgDeathMsg, BLOCK_NOT)
   }else{
      warcraft3=true
      set_msg_block(gmsgDeathMsg, BLOCK_SET)
   }

   return PLUGIN_CONTINUE
}
// **************************************************************************
// END check_war3 subroutine
// **************************************************************************


// **************************************************************************
// BEGIN init_pdata subroutine
// Initialize player data (skills, resists, attribs)
// **************************************************************************
public init_pdata(id, limited){

   if (limited){
      // Limited initialize only, for new_round event mainly 
      issearching[id] = false	// Init player searching state (for some ultimates)
      stunned[id] = false	// Init player stunned state
      slowed[id] = false	// Init player slowed state
      hasblink[id] = false	// Init player has blink status
      ultimateused[id] = false	// Init ultimateused status
      decoyused[id] = false	// Init decoyused status for round 
      medicalert[id] = false	// Init medicalert status 
      temp_immunity[id] = false	// Init temporary immunity status
      hasrespawned[id] = false 	// Init player has respawned status
      isburning[id] = 0		// Init player burning from flamethrower status
      isnburning[id] = 0	// Init player burning from napalm status
      ispoisonedss[id] = 0	// Init ispoisoned from s. strike status
      isdiseasedcb[id] = 0	// Init isdiseased from carion status
      repairs[id] = 0		// Init # of repairs performed for round
      mends[id] = 0		// Init # of mends performed for round
      he[id] = 0		// Init player he-grenade status
      threwnapalm[id] = 0	// Init player has thrown a napalm nade status
      vengeance_used[id] = 0	// Init player's Vengeance used status
      vampiric_hits[id] = 0	// Init vampiric aura hits 
   }

   // It limited passed, make sure to exit routine here
   if (limited)
      return PLUGIN_CONTINUE

   // If limited init NOT set, we make it here
   p_level[id] = 0	// Init player level to 0
   playerxp[id] = 0	// Init playerxp to 0
   loadedlevel[id] = 0	// Init player has loaded xp/level data state	
   playeritem[id] = 0	// Init player item slot 1
   playeritem2[id] = 0	// Init player item slot 2
   ultlearned[id] = 0	// Init # of ultimates learned
   
   if ( get_cvar_num("UW_lowres_default") )
      lowres[id] = true		// Init player's lowres setting to on
   else
      lowres[id] = false	// Init player's lowres setting to off 
  
 
   // Set all skills for this player slot to 0
   for (new j=0; j<MAX_SKILLS; j++)
      p_skills[id][j] = 0

   // Set all attributes for this player slot to the base amount
   for (new j=0; j<MAX_ATTRIBS; j++)
      p_attribs[id][j] = ATTRIB_BASE

   // Set all resistances for this player slot to 0
   for (new j=0; j<MAX_RESISTS; j++)
      p_resists[id][j] = 0

   return PLUGIN_CONTINUE
}
// **************************************************************************
// END init_pdata subroutine
// **************************************************************************


// **************************************************************************
// BEGIN check_say subroutine
// Say and Team_say handler, to check for issued spoken commands
// **************************************************************************
public check_say(id){

   new said[32]
   new tsaid[32]
   new arg1[32]
   new arg2[32]
   read_args( said, 31 )

   tsaid = said
   remove_quotes(tsaid)
   strbreak(tsaid, arg1, 32, arg2, 32)

   //client_print( 0, print_chat,
   //   "DEBUG: tsaid=(%s) arg1=(%s) arg2=(%s)", tsaid, arg1, arg2 )

   if (equali(said,"^"/war3menu^"") || equali(said,"^"war3menu^"") ||
      equali(said,"^"/wc3menu^"") || equali(said,"^"wc3menu^"") ||
      equali(said,"^"/warcraft^"") || equali(said,"^"warcraft^""))
         main_menu(id)
   else if (equali(said, "^"/news^"") || equali(said, "^"news^""))
      show_news(id)
   else if (equali(said, "^"/help^"") || equali(said, "^"help^""))
      help_menu(id)
   else if (equali(said, "^"/commands^"") || equali(said, "^"commands^""))
      uwc3_commands(id)
   else if (equali(said, "^"/tips^"") || equali(said, "^"uwc3tips^""))
      uwc3_tips(id)
   else if (equali(said, "^"/tips2^"") || equali(said, "^"uwc3tips2^""))
      uwc3_tips2(id)
   else if (equali(said, "^"/war3help^"") || equali(said, "^"war3help^""))
      war3_info(id)
   else if (equali(said, "^"/changerace^"") || equali(said, "^"changerace^""))
      change_race(id)
   else if (equali(said, "^"/selectrace^"") || equali(said, "^"selectrace^""))
      change_race(id)
   else if (equali(said,"^"/level^"") || equali(said,"^"level^""))
      displaylevel(id,0)
   else if (equali(said,"^"/character^"") || equali(said,"^"character^"") ||
            equali(said,"^"/charactersheet^"") || equali(said,"^"charactersheet^"") ||
            equali(said,"^"/charsheet^"") || equali(said,"^"charsheet^""))
      character_sheet(id)
   else if (equali(arg1,"/whois") || equali(arg1,"whois")){
      cmd_whois(id, arg2)
      return PLUGIN_HANDLED
   }else if (equali(said,"^"/selectskill^"") || equali(said,"^"selectskill^""))
      select_skill(id,1)
   else if (equali(said,"^"/selectattrib^"") || equali(said,"^"selectattrib^""))
      select_attrib(id)
   else if (equali(said,"^"/selectresist^"") || equali(said,"^"selectresist^""))
      select_resist(id)
   else if (equali(said,"^"/savexp^"") || equali(said,"^"savexp^""))
      uwc3_savexp(id)
   else if (equali(said,"^"/saveskills^"") || equali(said,"^"saveskills^""))
      uwc3_saveskills(id)
   else if (equali(said,"^"/saveattribs^"") || equali(said,"^"saveattribs^""))
      uwc3_saveattribs(id)
   else if (equali(said,"^"/saveresists^"") || equali(said,"^"saveresists^""))
      uwc3_saveresists(id)
   else if (equali(said,"^"/saveall^"") || equali(said,"^"saveall^""))
      uwc3_saveall(id)
   else if (equali(said,"^"/deletexp^"") || equali(said,"^"deletexp^""))
      amx_deletexp(id)
   else if (equali(said,"^"/reset_skills^"") || equali(said,"^"reset_skills^""))
      resetskills(id)
   else if (equali(said,"^"/resetskills^"") || equali(said,"^"resetskills^""))
      resetskills(id)
   else if (equali(said,"^"/resetattribs^"") || equali(said,"^"resetattribs^"") ||
            equali(said,"^"/resetattributes^"") || equali(said,"^"resetattributes^""))
      resetattribs(id)
   else if (equali(said,"^"/resetresists^"") || equali(said,"^"resetresists^""))
      resetresists(id)
   else if (equali(said,"^"/playerskills^"") || equali(said,"^"playerskills^""))
      player_skills(id)
   else if (equali(said,"^"/who^"") || equali(said,"^"who^""))
      cmd_who(id)
   else if (equali(said,"^"/skillsinfo^"") || equali(said,"^"skillsinfo^""))
      skills_menu(id)
   else if (equali(said,"^"/skillsinfo1^"") || equali(said,"^"skillsinfo1^""))
      skills_info(id,1)
   else if (equali(said,"^"/skillsinfo2^"") || equali(said,"^"skillsinfo2^""))
      skills_info(id,2)
   else if (equali(said,"^"/skillsinfo3^"") || equali(said,"^"skillsinfo3^""))
      skills_info(id,3)
   else if (equali(said,"^"/skillsinfo4^"") || equali(said,"^"skillsinfo4^""))
      skills_info(id,4)
   else if (equali(said,"^"/skillsinfo5^"") || equali(said,"^"skillsinfo5^""))
      skills_info(id,5)
   else if (equali(said,"^"/attribinfo^"") || equali(said,"^"attribinfo^"") ||
            equali(said,"^"/attribsinfo^"") || equali(said,"^"attribsinfo^""))
      uwc3_attributes(id)
   else if (equali(said,"^"/resistinfo^"") || equali(said,"^"resistinfo^"") ||
            equali(said,"^"/resistsinfo^"") || equali(said,"^"resistsinfo^""))
      uwc3_resistances(id)
   else if (equali(said,"^"/shopmenu^"") || equali(said,"^"shopmenu^""))
      shopmenu(id)
   else if (equali(said,"^"/shopmenu2^"") || equali(said,"^"shopmenu2^""))
      shopmenu2(id)
   else if (equali(said,"^"/itemsinfo^"") || equali(said,"^"itemsinfo^""))
      items_info(id)
   else if (equali(said,"^"/itemsinfo2^"") || equali(said,"^"itemsinfo2^""))
      items_info2(id)
   else if (equali(said,"^"/examine^"") || equali(said,"^"examine^""))
      do_examine(id)
   else if (equali(said,"^"/toggle_lowres^"") || equali(said,"^"toggle_lowres^""))
      toggle_lowres(id)


   return PLUGIN_CONTINUE

}
// **************************************************************************
// END check_say subroutine
// **************************************************************************


// **************************************************************************
// BEGIN set_user_armor_log subroutine
// A frontend for set_user_armor() which adds logging for debugging
// **************************************************************************
public set_user_armor_log(id, armor, blog, sdesc[]){

   // [10-05-04] Added the next check to prevent entity errors
   if ( !is_user_connected( id ) )
      return PLUGIN_CONTINUE

   new name[32]
   get_user_name(id, name, 31)

   //if (blog)
   //   client_print(0, print_console, 
   //      "[%s DEBUG] [In set_user_armor_log()] (%s) id=(%d)<%s> BEFORE-armor=(%d)", 
   //      MOD, sdesc, id, name, get_user_armor(id))

   set_user_armor(id, armor)

   //if (blog)
   //   client_print(0, print_console, 
   //       "[%s DEBUG] [In set_user_armor_log()] (%s) id=(%d)<%s> AFTER-armor=(%d)", 
   //       MOD, sdesc, id, name, get_user_armor(id))

   return PLUGIN_CONTINUE

}
// **************************************************************************
// END set_user_armor_log subroutine
// **************************************************************************


// **************************************************************************
// BEGIN set_user_health_log subroutine
// A frontend for set_user_health() which adds logging for debugging
// **************************************************************************
public set_user_health_log(id, health, blog, sdesc[]){

   // [10-05-04] Added the next check to prevent entity errors
   if ( !is_user_connected( id ) )
      return PLUGIN_CONTINUE

   new name[32]
   get_user_name(id, name, 31)

   if ( get_cvar_num("UW_DEBUG") == 5 ){
      if ( health > maxhealth[id] ){
         
         if ( hasgodmode[id] ){
            log_amx( "In set_user_health_log() :: [%s] Set Health [%d] EXCEEDS Maxhealth [%d] (Voodoo Active) Reason=(%s)", name, health, maxhealth[id], sdesc )
         }else{
            log_amx( "In set_user_health_log() :: [%s] Set Health [%d] EXCEEDS Maxhealth [%d] (Voodoo Inactive)  Reason=(%s)", name, health, maxhealth[id], sdesc )
         }
      }
   }

   //if (blog)
   //   client_print(0, print_console, 
   //      "[%s DEBUG] [In set_user_health_log()] (%s) id=(%d)<%s> BEFORE-health=(%d)", 
   //      MOD, sdesc, id, name, get_user_health(id))

   set_user_health(id, health)

   //if (blog)
   //   client_print(0, print_console, 
   //       "[%s DEBUG] [In set_user_health_log()] (%s) id=(%d)<%s> AFTER-health=(%d)", 
   //       MOD, sdesc, id, name, get_user_health(id))

   return PLUGIN_CONTINUE

}
// **************************************************************************
// END set_user_health_log subroutine
// **************************************************************************


// **************************************************************************
// BEGIN fullupdate routine
// Prevent fullupdate client command
// **************************************************************************
public fullupdate(id) {
   new name[32]
   get_user_name(id, name, 31)
   log_amx("FULLUPDATE: %s attempted to use the fullupdate command!", name)

   return PLUGIN_HANDLED
}
// **************************************************************************
// END fullupdate routine
// **************************************************************************


// **************************************************************************
// BEGIN replaceall routine
// Routine to replace all of a specified character in a string
// **************************************************************************
stock replaceall(text[], const LEN, const WHAT[], const WITH[]) {
    while (contain(text, WHAT) != -1){
        server_print("replacing a ' ...")
        replace(text, LEN, WHAT, WITH)
    }
}
// **************************************************************************
// END replaceall routine
// **************************************************************************


// **************************************************************************
// BEGIN str_break routine
// Routine provided by BAILOPAN to replace parse()
// **************************************************************************
stock str_break(const String[], Left[], Right[], lMax, rMax)
{
    new bool:quote_flag = false
    new bool:done_flag = false
    new left_pos = 0
    new right_pos = 0
    new i
    new hold[] = "'^"x"

    copy(Left, lMax, "")
    copy(Right, rMax, "")

    for (i=0; i<=strlen(String)-1; i++) {
        if (equali(String[i], "^"", 1)) {
            quote_flag = true
        } else if ((equali(String[i], "^"", 1)) && (quote_flag)) {
            quote_flag = false
        }
        if ((equali(String[i], " ", 1)) && (!quote_flag) && (!done_flag)) {
            done_flag = true
            i++
        }
        if (!done_flag && !equali(String[i], "^"", 1)) {
            if (left_pos < lMax) {
                setc(Left[left_pos], 1, String[i])
                if (equali(Left[left_pos], "'", 1)) {
                    setc(Left[left_pos], 1, hold[1])
                }
                left_pos++
            }
        } else {
            if (right_pos < rMax && !equali(String[i], "^"", 1)) {
                setc(Right[right_pos], 1, String[i])
                if (equali(Right[right_pos], "'", 1)) {
                    setc(Right[right_pos], 1, hold[1])
                }
                right_pos++
            }
        }
    }

    Left[left_pos] = 0
    Right[right_pos] = 0

    return true
}
// **************************************************************************
// END str_break routine
// **************************************************************************


// **************************************************************************
// BEGIN count_T subroutine
// Count the members of the T team - rewrite for buggy amxx function
// **************************************************************************
public count_T(){
   if (!warcraft3)
      return PLUGIN_CONTINUE

   new players[32]
   new numberofplayers
   get_players(players, numberofplayers)
   new count = 0

   for (new i = 0; i < numberofplayers; ++i){
      new id = players[i]
      if ( get_user_team(id)==TEAM_T )
         count += 1
   }

   return count
}
// **************************************************************************
// END count_T subroutine
// **************************************************************************


// **************************************************************************
// BEGIN count_CT subroutine
// Count the members of the CT team - rewrite for buggy amxx function
// **************************************************************************
public count_CT(){
   if (!warcraft3)
      return PLUGIN_CONTINUE

   new players[32]
   new numberofplayers
   get_players(players, numberofplayers)
   new count = 0

   for (new i = 0; i < numberofplayers; ++i){
      new id = players[i]
      if ( get_user_team(id)==TEAM_CT )
         count += 1
   }

   return count
}
// **************************************************************************
// END count_CT subroutine
// **************************************************************************


// **************************************************************************
// BEGIN sqrt sq and diff subroutine
// Calculate the square root
// **************************************************************************
public sqrt(num) {
   new div = num
   new result = 1
   while (div > result) {        // end when div == result, or just below
      div = (div + result) / 2   // take mean value as new divisor
      result = num / div
   }
   return div
}

stock sq(num) {
   return (num*num)
}

stock diff(num,num2){
   if(num>num2)
      return (num-num2)
   else
      return (num2-num)
   return 0
}
// **************************************************************************
// END sqrt sq and diff subroutines
// **************************************************************************


// **************************************************************************
// BEGIN zoomed2 and unzoomed subroutines
// Not sure what they do, but needed for STEAM, copied from Wacrfat3FT
// **************************************************************************
public zoomed2(id){
   zoomed[id]=1
}

public unzoomed(id){
   zoomed[id]=0
}

public reset_maxspeed(parm[]){
   new enemy = parm[0]

   if ( !is_user_connected(enemy) )
      return PLUGIN_CONTINUE

   new normalspeed = parm[1]
   stunned[enemy]=false
   slowed[enemy]=false
   set_user_maxspeed(enemy, float(normalspeed))

   return PLUGIN_CONTINUE
}
// **************************************************************************
// END zoomed2 and unzoomed subroutines
// **************************************************************************


// **************************************************************************
// BEGIN cmd_target2 subroutine
// A varient of cmd_target, copied verbatim from Warcraft3 FT
// **************************************************************************
stock cmd_target2(id,const arg[]) {
  new player = find_player("bl",arg)
  if (player){
    if ( player != find_player("blj",arg) ){
      console_print(id,"There are more clients matching to your argument")
      return 0
    }
  }
  else if ( ( player = find_player("c",arg) )==0 && arg[0]=='#' && arg[1] )
    player = find_player("k",str_to_num(arg[1]))
  if (!player){
    console_print(id,"Client with that name or userid not found")
    return 0
  }
  return player
}
// **************************************************************************
// END cmd_target2 subroutine
// **************************************************************************


// **************************************************************************
// BEGIN admin_loc subroutine
// Display your location in coordinates
// **************************************************************************
public admin_loc(id){

   new origin[3]
   get_user_origin(id,origin)

   client_print(id, print_chat, "[%s] Your location is: <%d %d %d>",
      MOD, origin[0], origin[1], origin[2])

   return PLUGIN_HANDLED
}
// **************************************************************************
// END admin_loc subroutine
// **************************************************************************


// **************************************************************************
// BEGIN debug_info subroutine
// Dump debug info
// **************************************************************************
public debug_info(id, enemy){

   client_print(0, print_console, "Dumping debug info::")

   for (new j=1; j<MAX_LEVEL; j++){

      client_print(0, print_console, "[%d] xpgiven=(%d) xplevel=(%d) attrib_pt_cost=(%d) resist_pt_cost=(%d)", j, xpgiven_lev[j], xplevel_lev[j], attrib_pt_cost, resist_pt_cost)

   }

   /*for (new j=0; j<MAX_LEVEL; j++){
      client_print(0, print_console, "[%d] xpgiven=(%d) xplevel=(%d)",
          j, xpgiven_lev[j], xplevel_lev[j])

   }*/

   /*
   new name[32]
   new ename[32]

   new skillname[32] = ""

   get_user_name(id, name, 31)
   get_user_name(enemy, ename, 31)

   client_print(0, print_console, "[%s DEBUG] Data Dump %s health: %d , %s health: %d",
      MOD, name, get_user_health(id), ename, get_user_health(enemy))

   for (new i=1; i<MAX_SKILLS;i++){
      if (i <= 8) copy(skillname, 31, skillset1[i])
      else if (i <= 16) copy(skillname, 31, skillset2[i-8])
      else if (i <= 24) copy(skillname, 31, skillset3[i-16])
      else if (i <= 32) copy(skillname, 31, skillset4[i-24])
      else if (i <= 40) copy(skillname, 31, skillset5[i-32])

      client_print(0, print_console, "[%s DEBUG] Skill [%d] %s - id(%d) enemy(%d)",
         MOD, i, skillname, p_skills[id][i], p_skills[enemy][i])
   }
   */

   return PLUGIN_CONTINUE
}
// **************************************************************************
// END debug_info subroutine
// **************************************************************************


// **************************************************************************
// BEGIN toggle_lowres subroutine
// Toggle low-res display mode on or off
// **************************************************************************
public toggle_lowres(id){

   if (!warcraft3)
      return PLUGIN_HANDLED

   if (lowres[id]){
      lowres[id] = false
      client_print(id, print_chat, "[%s] You have toggled Low Res mode OFF", MOD)
   }else{
      lowres[id] = true
      client_print(id, print_chat, "[%s] You have toggled Low Res mode ON", MOD)
   }

   return PLUGIN_HANDLED
}
// **************************************************************************
// END toggle_lowres subroutine
// **************************************************************************


// **************************************************************************
// BEGIN do_examine subroutine
// A player may examine the health/armor of their teammates
// **************************************************************************
public do_examine(id){

   if (!warcraft3)
      return PLUGIN_HANDLED

   new friend, body
   get_user_aiming(id, friend, body)

   if ((0 < friend <= MAX_PLAYERS) && (friend != id) && is_user_alive(id) &&
       is_user_alive(friend))
   {
      // id has a friend to examine
      new sReport[64] = ""
      new fname[32]
      get_user_name(friend, fname, 31)

      set_hudmessage(200, 100, 0, -1.0, 0.35, 0, 1.0, 7.0, 0.1, 0.2, 2)

      if (get_user_team(id) != get_user_team(friend)){
         format(sReport, 64, "Examining %s :: [ ENEMY ]", fname )
         show_hudmessage(id, sReport)
         return PLUGIN_HANDLED
      }

      new fhp = get_user_health(friend)
      new farmor = get_user_armor(friend)


      format(sReport, 64, "Examining %s :: [ %d HP / %d ARM ]", fname, fhp, farmor )

      show_hudmessage(id, sReport)
   }

   return PLUGIN_HANDLED
}
// **************************************************************************
// END do_examine subroutine
// **************************************************************************


// **************************************************************************
// BEGIN setSpecMode subroutines
// From Warcraft3FT
// **************************************************************************
public setSpecMode(id){
   new arg[12]
   read_data( 2 , arg , 11 )
   g_specMode[ id ] = ( arg[10] == '2' ) ? true : false
}
// **************************************************************************
// END setSpecMode subroutines
// **************************************************************************



// **************************************************************************
// BEGIN showRank setTeam hideStatus and showStatus subroutines
// From Warcraft3FT
// **************************************************************************
public showRank(id){

   if(!get_cvar_num("FT_spec_info"))
      return PLUGIN_CONTINUE

   if(!g_specMode[id])
      return PLUGIN_CONTINUE

   new a = read_data(2)

   if (!is_user_connected(a))
      return PLUGIN_CONTINUE          // not valid target

   new name[32]
   get_user_name( a ,name,31)

   if (playerxp[a]<0)
      playerxp[a]=0

   /*for (new i=0; i<=10; ++i){
      if (playerxp[a]>=xplevel_lev[i])
         p_level[a]=i
      else
         break
   }*/

   return PLUGIN_CONTINUE

}

public setTeam(id)
  g_friend[id] = read_data(2)


public hideStatus(id){
   if (get_cvar_num("FT_show_player")){
      set_hudmessage(0,0,0,0.0,0.0,0, 0.0, 0.01, 0.0, 0.0, 4)
      show_hudmessage(id,"")
   }
}

public set_buytime()
   buytime=false

public showStatus(id){
   new pid = read_data(2)

   if (get_user_team(id)==get_user_team(pid) &&
       (playeritem2[pid]==CHAMELEON || skinchanged[pid]) && is_user_alive(pid))
   {
      client_print(id,print_center,"He's on your team, DON'T SHOOT")
      if (file_exists("sound/warcraft3/antend.wav")==1)
         emit_sound(id,CHAN_ITEM, "warcraft3/antend.wav", 1.0, ATTN_NORM, 0, PITCH_NORM)
   }

   if(get_cvar_num("FT_show_player") && !freezetime){
      new name[32]
      get_user_name(pid,name,31)
      new color1 = 0,color2 = 0
      if ( get_user_team(pid)==1 )
         color1 = 255
      else
         color2 = 255
      if (g_friend[id]==1){ // friend
         /*new clip = 0, ammo = 0, wpnid = 0
         wpnid = get_user_weapon(pid,clip,ammo)
         new wpnname[32]
         get_weaponname(wpnid,wpnname,31)*/
         set_hudmessage(color1,50,color2,-1.0,0.60,1, 0.01, 3.0, 0.01, 0.01, 4)
         new health = get_user_health(pid)
         if(health>1500)
            health=health-2048
         else if (health>500)
            health = health-1024
         show_hudmessage(id,"%s -- %d HP / %d AP", name, health, get_user_armor(pid))
      }else{
         set_hudmessage(color1,50,color2,-1.0,0.60,1, 0.01, 3.0, 0.01, 0.01, 4)
         show_hudmessage(id,name)
      }
   }

}
// **************************************************************************
// END hideStatus and showStatus subroutines
// **************************************************************************


/*
// **************************************************************************
// BEGIN reset_he_origin subroutine
// From Warcraft3FT - Temporary Fix for czero (HE nades not working)
// **************************************************************************
public reset_he_origin(parm[]){
   new enemy = parm[0]
   he_origin[enemy][0]=-1.234
   he_origin[enemy][1]=-1.234
   he_origin[enemy][2]=-1.234
}
// **************************************************************************
// END reset_he_origin subroutine
// **************************************************************************


// **************************************************************************
// BEGIN get_nade_origin subroutine
// Orc nade, temp fix for CZ
// **************************************************************************
public get_nade_origin(parm[]){
   new id = parm[0]
   new grenadeid = parm[1]

   new Float:origin[3]
   new Float:porigin[3]
   Entvars_Get_Vector(grenadeid,EV_VEC_origin,origin)
   he_origin[id][0] = origin[0]
   he_origin[id][1] = origin[1]
   he_origin[id][2] = origin[2]

   Entvars_Get_Vector(id,EV_VEC_origin,porigin)

   set_task(0.1,"get_nade_origin",2,parm,2)
}
// **************************************************************************
// END get_nade_origin subroutine
// **************************************************************************
*/


// **************************************************************************
// BEGIN check_alive subroutine
// Check for player alive
// **************************************************************************
public check_alive(parm[]){
   if (!warcraft3)
      return PLUGIN_CONTINUE

   new id = parm[0]

   if(alive_before_explosion[id] && !is_user_alive(id)){
      diedlastround[id]=true
      alive_before_explosion[id]=false
   }
   return PLUGIN_CONTINUE
}
// **************************************************************************
// END check_alive subroutine
// **************************************************************************


// **************************************************************************
// BEGIN changeskin subroutine
// Routine to change a players skin as needed by item or skill
// **************************************************************************
public changeskin(id,reset){
   if (reset==1){
      cs_reset_user_model(id)
      skinchanged[id]=false
      return PLUGIN_HANDLED
   }else if (reset==2){
      //cs_set_user_model(id,"goomba")
      cs_set_user_model(id,"zombie")
      skinchanged[id]=true
      return PLUGIN_HANDLED
   }else{
      //new newSkin[32]
      new num = random_num(0,3)

      if (get_user_team(id)==TEAM_T){
         //add(newSkin,31,CTSkins[num])
         cs_set_user_model(id,CTSkins[num])
      }else{
         //client_print(0, print_console, "CT mole, using new skin %s", TSkins[num])
         //add(newSkin,31,TSkins[num])
         cs_set_user_model(id,TSkins[num])
      }

      skinchanged[id]=true
   }

   return PLUGIN_CONTINUE
}
// **************************************************************************
// END changeskin subroutine
// **************************************************************************


// **************************************************************************
// BEGIN freezetimedone and unfreezespeed subroutine
// From Warcraft3FT - Used w/ unholyspeed routine
// **************************************************************************
public freezetimedone() {

   if (!warcraft3)
      return PLUGIN_CONTINUE

   freezetime = 0

   new players[32],numberofplayers, id, i, parm[1]
   get_players(players, numberofplayers)

   for (i = 0; i < numberofplayers; ++i){
      id = players[i]

      if ( !is_user_connected(id) )
         return PLUGIN_CONTINUE

      parm[0]=id
      set_user_maxspeed(id,240.0)
      set_task(0.1,"unholyspeed",19,parm,1)
      set_task(0.1,"unfreezespeed",21)
      if(get_cvar_num("FT_blinkstartdisabled")){
         if(!(p_skills[id][SKILLIDX_TELEPORT])){
            icon_controller(id,ICON_SHOW)
            ultimateused[id]=false
         }
      }else{
         icon_controller(id,ICON_SHOW)
         ultimateused[id]=false
      }
      displaylevel(id,3)
   }
   return PLUGIN_CONTINUE
}

public unfreezespeed() {
   if (!warcraft3)
      return PLUGIN_CONTINUE

   new players[32]
   new numberofplayers
   get_players(players, numberofplayers)
   new i
   new id
   for (i = 0; i < numberofplayers; ++i){
      id=players[i]
      change_weapon(id)
   }
   return PLUGIN_CONTINUE
}
// **************************************************************************
// END freezetimedone and unfreezespeed subroutine
// **************************************************************************


// **************************************************************************
// BEGIN teamselect subroutine
// Function determines if they are actually changing teams (untested in 1.5)
// **************************************************************************
public teamselect(id){
   new arg[2]
   read_argv(1,arg,1)
   new num = str_to_num(arg)
   if(currentteam[id]!=num)
      changingteam[id]=true
   else
      changingteam[id]=false
}
// **************************************************************************
// END teamselect subroutine
// **************************************************************************


// **************************************************************************
// BEGIN icon_controller subroutine
// Controls the icon to display for ultimate skills
// **************************************************************************
public icon_controller(id, value){
   if (!get_cvar_num("FT_show_icons") || (freezetime) || (u_delay) ||
      (p_skills[id][SKILLIDX_TELEPORT] && blinkdelayed[id] &&
       get_cvar_num("FT_blinkstartdisabled")))
         return PLUGIN_HANDLED

   if (!ultlearned[id]){
      //client_print(0, print_console,
      //  "You have no ultimates id=(%d) ultlearned=(%d)!!!", id, ultlearned[id])
      // Player doesn't know any ultimates, no icons to display
      return PLUGIN_HANDLED
   }


   return PLUGIN_CONTINUE

}
// **************************************************************************
// END icon_controller subroutine
// **************************************************************************


// **************************************************************************
// BEGIN glow_change subroutine
// From Warcraft3FT
// **************************************************************************
public glow_change(parm[]){
   new id = parm[0]

   // [10-05-04] Added the next check to prevent entity errors
   if ( !is_user_connected( id ) )
      return PLUGIN_CONTINUE

   if (p_skills[id][SKILLIDX_INVIS]){
      // Don't glow if player is invisible
      iglow[id][0] = 0
      iglow[id][1] = 0
      iglow[id][2] = 0
      iglow[id][3] = 0
   }else if (playeritem[id]==CLOAK){
      // Don't glow if player is invisible
      iglow[id][0] = 0
      iglow[id][1] = 0
      iglow[id][2] = 0
      iglow[id][3] = 0
   }else if (iglow[id][0] > 5){
      set_user_rendering(id,kRenderFxGlowShell,iglow[id][0],0,0, kRenderNormal, 16)
      iglow[id][0] -= 5
      set_task(0.2,"glow_change",15,parm,2)
   }else if (iglow[id][1] > 5){
      set_user_rendering(id,kRenderFxGlowShell,0,iglow[id][1],0, kRenderNormal, 16)
      iglow[id][1] -= 5
      set_task(0.2,"glow_change",16,parm,2)
   }else if (iglow[id][2] > 5){
      set_user_rendering(id,kRenderFxGlowShell,0,0,iglow[id][2], kRenderNormal, 16)
      iglow[id][2] -= 5
      set_task(0.2,"glow_change",17,parm,2)
   }else if (iglow[id][3] > 5){
      set_user_rendering(id,kRenderFxGlowShell,iglow[id][3],iglow[id][3],iglow[id][3], kRenderNormal, 16)
      iglow[id][3] -= 5
      set_task(0.2,"glow_change",18,parm,2)
   }else{
      iglow[id][0] = 0
      iglow[id][1] = 0
      iglow[id][2] = 0
      iglow[id][3] = 0
      set_user_rendering(id)
   }
   return PLUGIN_CONTINUE
}
// **************************************************************************
// END glow_change subroutine
// **************************************************************************


// **************************************************************************
// BEGIN BuyZone subroutine
// From Warcraft3FT
// **************************************************************************
public BuyZone(id){
   if (read_data(1))
      isBuyzone[id] = true
   else
      isBuyzone[id] = false

   return PLUGIN_CONTINUE
}
// **************************************************************************
// END BuyZone subroutine
// **************************************************************************


// **************************************************************************
// BEGIN check_for_living and check_for_living2 subroutines
// Used in conjunction with the event_player_actions routine
// Functions are used to save the weapons if someone died from the bomb exploding
// **************************************************************************
public check_for_living(){
   new players[32]
   new numberofplayers
   get_players(players, numberofplayers)
   new i, id

   for (i = 0; i < numberofplayers; ++i){
      id = players[i]
      if(is_user_alive(id)){
         alive_before_explosion[id]=true
         saveweapons(id)
      }
   }

   return PLUGIN_CONTINUE
}

// [08-28-04] - Added post bomb explosion check, for equip recincarnation
public check_for_living2(){
   new players[32]
   new numberofplayers
   get_players(players, numberofplayers)
   new i, id

   if (bombstate == BOMB_PLANTED){
      client_print(0, print_console, "MIH - Bomb Exploded")
      for (i = 0; i < numberofplayers; ++i){
         id = players[i]
         //client_print(id, print_console, "Your alive state=(%d)", is_user_alive(id))
         if (!is_user_alive(id)){
            //client_print(id, print_console, "Setting true for diedlastround")
            diedlastround[id] = true
         }
      }
   }
}
// **************************************************************************
// END check_for_living and check_for_living2 subroutines
// **************************************************************************


// **************************************************************************
// BEGIN monitor_players
// Monitor player data to keep accurate
// **************************************************************************
public monitor_players(){
   new pname[32]

   new players[32], numofplayers
   get_players(players, numofplayers)

   new allowed_diff = 5 // Max. allowed discrepancy between health and maxhealth

   for (new i = 0; i < numofplayers; i++){
      new id = players[i] // This Player ID

      if ( is_user_alive(id) ){
         new health = maxhealth[id] + (playeritem[id] == HEALTH ? HEALTHBONUS : 0)

         if ( get_user_health(id) > health ) {
            get_user_name(id, pname, 31)

            if ( hasgodmode[id] ){
               log_amx( "In monitor_players() :: [%s] Kept health (Voodoo Active) Has=(%d) Max=(%d)", pname, get_user_health(id), health )
            }else{
               if ( (get_user_health(id) - health) > allowed_diff ){
                  log_amx( "In monitor_players() :: [%s] Reset health (Voodoo Inactive) Has=(%d) Max=(%d)", pname, get_user_health(id), health )
               }
               set_user_health_log(id, health, true, "monitor_players()")
            }
         }
      }
   }

   set_task(10.0, "monitor_players", 358)

   return PLUGIN_CONTINUE
}
// **************************************************************************
// END monitor_players
// **************************************************************************


// **************************************************************************
// BEGIN stock user_spawn 
// Spawn a user
// **************************************************************************
stock user_spawn(index)
   return spawn(index)
// **************************************************************************
// END stock user_spawn 
// **************************************************************************


// **************************************************************************
// END Utility Subroutine Declarations
// **************************************************************************

