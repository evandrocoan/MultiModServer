
/** *************************************************************************
*** AMXX Plugin:   Ultimate Warcraft3 (UWC3)
*** Plugin Author: K2mia
*** UWC3 Module:   Skills (General Routines)
*** Date:          May 25, 2004
*** Last Update:   September 23, 2004
*
*  Module: Skills Handler
*  All skill handler routines not covered by more specific modules (such as
*  damage modules, ultimates, mole, etc ...
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
// BEGIN General Skills Related Subroutines
// **************************************************************************


// **************************************************************************
// BEGIN set_skill_limits subroutine
// Set skill limits for each skill
// **************************************************************************
public set_skill_limits(){

   // Minimum level to train skill
   skill_minlev[SKILLIDX_FAN] = 19
   skill_minlev[SKILLIDX_EQREINC] = 1
   skill_minlev[SKILLIDX_PHOENIX] = 13
   skill_minlev[SKILLIDX_BLINK] = 11
   skill_minlev[SKILLIDX_SERPWARD] = 6

   skill_minlev[SKILLIDX_VAMPIRIC] = 3
   skill_minlev[SKILLIDX_LEVITATION] = 1
   skill_minlev[SKILLIDX_DEVOTION] = 2
   skill_minlev[SKILLIDX_SIPHON] = 2
   skill_minlev[SKILLIDX_IMPALE] = 1
   skill_minlev[SKILLIDX_CARAPACE] = 3
   skill_minlev[SKILLIDX_UNHOLY] = 5
   skill_minlev[SKILLIDX_BASH] = 6
   skill_minlev[SKILLIDX_CRITSTRIKE] = 9
   skill_minlev[SKILLIDX_THORNS] = 8
   skill_minlev[SKILLIDX_BANISH] = 7
   skill_minlev[SKILLIDX_HEX] = 5
   skill_minlev[SKILLIDX_EVASION] = 24
   skill_minlev[SKILLIDX_TRUESHOT] = 24
   skill_minlev[SKILLIDX_HEALWAVE] = 2
   skill_minlev[SKILLIDX_CARRION] = 10
   skill_minlev[SKILLIDX_SSTRIKE] = 11
   skill_minlev[SKILLIDX_CRITGREN] = 12
   skill_minlev[SKILLIDX_INVIS] = 13

   skill_minlev[SKILLIDX_SUICIDE] = 17
   skill_minlev[SKILLIDX_ENTANGLE] = 16
   skill_minlev[SKILLIDX_FSTRIKE] = 16
   skill_minlev[SKILLIDX_LOCUST] = 14
   skill_minlev[SKILLIDX_TELEPORT] = 8
   skill_minlev[SKILLIDX_LIGHTNING] = 15
   skill_minlev[SKILLIDX_VOODOO] = 12
   skill_minlev[SKILLIDX_VENGEANCE] = 15
   skill_minlev[SKILLIDX_FLASH] = 9
   skill_minlev[SKILLIDX_LSKIN] = 2
   skill_minlev[SKILLIDX_SSKIN] = 11
   skill_minlev[SKILLIDX_NAPALM] = 13
   skill_minlev[SKILLIDX_REPAIR] = 4
   skill_minlev[SKILLIDX_MEND] = 4
   skill_minlev[SKILLIDX_DECOY] = 14
   skill_minlev[SKILLIDX_GATE] = 12

   new tmp

   for (new i=1; i<MAX_SKILLS; i++)
      sortedskills[i] = i

   // Sort the skill list by min. level to train the skill
   for (new i=1; i<MAX_SKILLS; i++){
      for (new j=1; j<MAX_SKILLS-i; j++){
         if (skill_minlev[sortedskills[j+1]] < skill_minlev[sortedskills[j]]){
            // Swap the two out of place score positions
            tmp = sortedskills[j]
            sortedskills[j] = sortedskills[j+1]
            sortedskills[j+1] = tmp
         }
      }
   }

   // Now define skill limits for each skill (# times can be trained)

   // These skills have 3 trainable levels
   skill_limits[SKILLIDX_FAN] = MAX_SKILL_LEVEL3
   skill_limits[SKILLIDX_EQREINC] = MAX_SKILL_LEVEL3
   skill_limits[SKILLIDX_SERPWARD] = MAX_SKILL_LEVEL3
   skill_limits[SKILLIDX_MEND] = MAX_SKILL_LEVEL3

   // These skills have 5 trainable levels
   skill_limits[SKILLIDX_BLINK] = MAX_SKILL_LEVEL5
   skill_limits[SKILLIDX_PHOENIX] = MAX_SKILL_LEVEL5
   skill_limits[SKILLIDX_EVASION] = MAX_SKILL_LEVEL5

   // These skills have 10 trainable levels
   skill_limits[SKILLIDX_VAMPIRIC] = MAX_SKILL_LEVEL10
   skill_limits[SKILLIDX_LEVITATION] = MAX_SKILL_LEVEL10
   skill_limits[SKILLIDX_DEVOTION] = MAX_SKILL_LEVEL10
   skill_limits[SKILLIDX_SIPHON] = MAX_SKILL_LEVEL10
   skill_limits[SKILLIDX_IMPALE] = MAX_SKILL_LEVEL10
   skill_limits[SKILLIDX_CARAPACE] = MAX_SKILL_LEVEL10
   skill_limits[SKILLIDX_UNHOLY] = MAX_SKILL_LEVEL10
   skill_limits[SKILLIDX_BASH] = MAX_SKILL_LEVEL10
   skill_limits[SKILLIDX_CRITSTRIKE] = MAX_SKILL_LEVEL10
   skill_limits[SKILLIDX_THORNS] = MAX_SKILL_LEVEL10
   skill_limits[SKILLIDX_BANISH] = MAX_SKILL_LEVEL10
   skill_limits[SKILLIDX_HEX] = MAX_SKILL_LEVEL10
   skill_limits[SKILLIDX_TRUESHOT] = MAX_SKILL_LEVEL10
   skill_limits[SKILLIDX_HEALWAVE] = MAX_SKILL_LEVEL10
   skill_limits[SKILLIDX_LSKIN] = MAX_SKILL_LEVEL10
   skill_limits[SKILLIDX_CARRION] = MAX_SKILL_LEVEL10
   skill_limits[SKILLIDX_SSTRIKE] = MAX_SKILL_LEVEL10
   skill_limits[SKILLIDX_CRITGREN] = MAX_SKILL_LEVEL10
   skill_limits[SKILLIDX_INVIS] = MAX_SKILL_LEVEL10

   skill_limits[SKILLIDX_SUICIDE] = MAX_SKILL_LEVEL1    // Ult. Ability: wcsuicide
   skill_limits[SKILLIDX_ENTANGLE] = MAX_SKILL_LEVEL1   // Ult. Ability: wcentangle
   skill_limits[SKILLIDX_FSTRIKE] = MAX_SKILL_LEVEL1    // Ult. Ability: wcflame
   skill_limits[SKILLIDX_LOCUST] = MAX_SKILL_LEVEL1     // Ult. Ability: wclocust
   skill_limits[SKILLIDX_TELEPORT] = MAX_SKILL_LEVEL1   // Ult. Ability: wcteleport
   skill_limits[SKILLIDX_LIGHTNING] = MAX_SKILL_LEVEL1  // Ult. Ability: wclightning
   skill_limits[SKILLIDX_VOODOO] = MAX_SKILL_LEVEL1     // Ult. Ability: wcvoodoo
   skill_limits[SKILLIDX_VENGEANCE] = MAX_SKILL_LEVEL1  // Ult. Passive Ability
   skill_limits[SKILLIDX_FLASH] = MAX_SKILL_LEVEL1      // Ult. Ability: wcflash
   skill_limits[SKILLIDX_DECOY] = MAX_SKILL_LEVEL1      // Ult. Ability: wcdecoy
   skill_limits[SKILLIDX_GATE] = MAX_SKILL_LEVEL1       // Ult. Ability: wcgate
   skill_limits[SKILLIDX_SSKIN] = MAX_SKILL_LEVEL1      // Ability: Upgrade to Leather Skin
   skill_limits[SKILLIDX_NAPALM] = MAX_SKILL_LEVEL1     // Ability: 1st HE = Napalm Grenade
   skill_limits[SKILLIDX_REPAIR] = MAX_SKILL_LEVEL1     // Ability: Repair Teammate Armor

   // Now set the skill_ultimates list for the ultimate indices
   copy(skill_ultimates[SKILLIDX_SUICIDE], 32, "wcsuicide")
   copy(skill_ultimates[SKILLIDX_ENTANGLE], 32, "wcentangle")
   copy(skill_ultimates[SKILLIDX_FSTRIKE], 32, "wcflame")
   copy(skill_ultimates[SKILLIDX_LOCUST], 32, "wclocust")
   copy(skill_ultimates[SKILLIDX_TELEPORT], 32, "wcteleport")
   copy(skill_ultimates[SKILLIDX_LIGHTNING], 32, "wclightning")
   copy(skill_ultimates[SKILLIDX_VOODOO], 32, "wcvoodoo")
   copy(skill_ultimates[SKILLIDX_VENGEANCE], 32, "Passive Ability")
   copy(skill_ultimates[SKILLIDX_FLASH], 32, "wcflash")
   copy(skill_ultimates[SKILLIDX_DECOY], 32, "wcdecoy")
   copy(skill_ultimates[SKILLIDX_GATE], 32, "wcgate")

   // Now setup skill values for all skill levels
   for (new i=0; i<MAX_SKILL_LEVEL10; i++){
      p_vampiric[i] = 0.10 + (i * 0.03)    // Vampiric Aura  {0.10,0.14,.,0.37}
      p_vampirichealth[i] = (110 + (i*5))  // Vampiric Aura Max Health {110,115,.,155}
      p_unholy[i] = (260.0 + (i*7.0))      // Unholy Aura {260.0, 267.0,..., 323.0}
      p_levitation[i] = (0.8 - (i*0.05))   // Levitation {0.8,0.75,.,0.35}

      p_invisibility[i] = (205 - (i*5))    // Invisibility {205,200,.,160}
      p_devotion[i] = (110 + (i*5))        // Devotion Aura {110,115,.,155}
      p_bash[i] = (0.10 + (i*0.03))        // Bash {0.10,0.13,.,0.37}

      p_critical[i] = (0.10 + (i*0.01))    // Critical Strike {0.10,0.11,.,0.19}
      p_grenade[i] = (1.20 + (i*0.20))     // Critical Grenade {1.20, 1.40,., 3.0}

      p_thorns[i] = (0.10 + (i*0.03))      // Thorns Aura {0.10,0.13,..,0.37}
      p_trueshot[i] = (0.10 + (i*0.02))    // Trueshot Aura {0.10,0.12,..,0.28}

      p_banish[i] = (0.06 + (i*0.02))      // Banish {0.06,0.08,..,0.24}
      p_mana[i] = (0.05 + (i*0.01))        // Siphon Mana {0.05,0.06,..,0.14}

      p_heal[i] = (6.0 - (i*0.5))          // Healing Wave {6.0,5.5,..,1.5}
      p_lskin[i] = (6.0 - (i*0.5))         // Leather Skin {6.0,5.5,..,1.5}
      p_hex[i] = (0.05 + (i*0.02))         // Hex {0.05,0.07,..,0.23}

      p_shadow[i] = (0.10 + (i*0.03))      // Shadow Strike {0.10,0.13,..,0.37}

      p_impale[i] = (0.10 + (i*0.03))      // Impale {0.10,0.13,..,0.37}
      p_spiked[i] = (0.05 + (i*0.02))      // Spiked Carapace {0.05,0.07,..,0.23}
      p_carrion[i] = (0.10 + (i*0.03))     // Carrion Beetle {0.10,0.13,..,0.37}

   }

   return PLUGIN_CONTINUE
}
// **************************************************************************
// END set_skill_limits subroutine
// **************************************************************************



// **************************************************************************
// BEGIN skills_menu subroutine
// Display the skills menu
// **************************************************************************
public skills_menu(id){

   new pos = 0, i, menu_body[512], menu_items[8][32]
   new keys = (1<<0)|(1<<1)|(1<<2)|(1<<3)|(1<<4)|(1<<5)|(1<<6)|(1<<8)|(1<<9)

   menu_items[0]= "Select Skills"
   menu_items[1]= "1st Tier Skills Information"
   menu_items[2]= "2nd Tier Skills Information"
   menu_items[3]= "3rd Tier Skills Information"
   menu_items[4]= "4th Tier Skills Information"
   menu_items[5]= "5th Tier Skills Information"
   menu_items[7]= "Reselect Skills"

   pos += format(menu_body[pos], 511-pos, "\ySkills Options^n^n")
   for (i = 0; i<=MAX_SKILL_PAGES; i++){
      pos += format(menu_body[pos], 511-pos, "\w%d. %s^n",i+1,menu_items[i])
   }
   pos += format(menu_body[pos], 511-pos, "^n^n\w9. Back")
   pos += format(menu_body[pos], 511-pos, "^n\w0. Exit")
   show_menu(id,keys,menu_body,-1)

   return PLUGIN_CONTINUE

}
// **************************************************************************
// END skills_menu subroutine
// **************************************************************************


// **************************************************************************
// BEGIN do_skillsmenu subroutine
// Handler for the skills menu
// **************************************************************************
public do_skillsmenu(id,key){
   switch (key){
      case 0: select_skill(id, 1)
      case 1: skills_info(id, 1)
      case 2: skills_info(id, 2)
      case 3: skills_info(id, 3)
      case 4: skills_info(id, 4)
      case 5: skills_info(id, 5)
      case 7: resetskills(id)
      case 8: main_menu(id)
      default: return PLUGIN_HANDLED
   }
   return PLUGIN_HANDLED
}
// **************************************************************************
// END do_skillsmenu subroutine
// **************************************************************************


// **************************************************************************
// BEGIN select_skill subroutine
// Skill selection menu
// **************************************************************************
public select_skill(id, page){
   if (!warcraft3)
      return PLUGIN_CONTINUE


   new skillname[32] = ""

   /*
   client_print(0, print_console, "Dumping sorted skill info:")

   for (new i=1; i<MAX_SKILLS; i++){
      new j = sortedskills[i]

      if (j <= 8) copy(skillname, 31, skillset1[j])
      else if (j <= 16) copy(skillname, 31, skillset2[j-8])
      else if (j <= 24) copy(skillname, 31, skillset3[j-16])
      else if (j <= 32) copy(skillname, 31, skillset4[j-24])
      else if (j <= 40) copy(skillname, 31, skillset5[j-32])

      client_print(0, print_console, "[%d] j=(%d) %s min.level=%d ",
         i, j, skillname, skill_minlev[j] )
   }
   */


   new message[2048] = ""
   //new temp[512] = ""
   new temp2[256] = ""
   new temp3[32] = ""

   new keys = (1<<0)|(1<<1)|(1<<2)|(1<<3)|(1<<4)|(1<<5)|(1<<6)|(1<<7)|(1<<8)|(1<<9)

   page = (page > 0) ? page : 1

   nSkillsPage[id] = page

   // Calculate how many skill points can be spent
   new skillpts = get_availskillpts( id )

   new whichset[32] = ""

   format(whichset, 31, "/skillsinfo%d", page)

   format(temp2, 256,"\ySelect Skill: (pg-%d) [%d pts remaining]\w^n", page, skillpts)
   add(message, 2048, temp2)

   format(temp2, 256, "\y(say %s for info about skills on this page) \w^n", whichset )
   add(message, 2048, temp2)

   if (get_cvar_num("UW_admin_mode")){
      format(temp2, 256, "\y[AS] = Admin-Reserved Skills\w^n" )
      add(message, 2048, temp2)
   }

   new startidx = ((page-1) * SKILLS_PER_SET) + 1
   new endidx = startidx + (SKILLS_PER_SET - 1)

   for (new i=startidx; i <= endidx; i++){
      new vis_i = (i - startidx) + 1
      new j = sortedskills[i]
      new idx = j

      new sLevelText[32] = ""
      new admstr[32] = ""

      if (skill_minlev[j] == 0) continue

      if (j <= 8) copy(skillname, 31, skillset1[j])
      else if (j <= 16) copy(skillname, 31, skillset2[j-8])
      else if (j <= 24) copy(skillname, 31, skillset3[j-16])
      else if (j <= 32) copy(skillname, 31, skillset4[j-24])
      else if (j <= 40) copy(skillname, 31, skillset5[j-32])


      if (get_cvar_num("UW_admin_mode") && admin_only[idx]){
         if ( p_level[id] < skill_minlev[idx] )
            format(admstr, 32, "\r[AS] \d")
         else
            format(admstr, 32, "\r[AS] \w")
      }

      if ( p_level[id] < skill_minlev[idx] ){
         // Blank out option of level not high enough to train
         format(temp3, 32, "\d")
         add(message, 2048, temp3)

         if (get_cvar_num("UW_admin_mode"))
            format(sLevelText, 32, "[ Lvl %d ]", skill_minlev[idx])
         else
            format(sLevelText, 32, "[Lvl %d required]", skill_minlev[idx])

         if (equali(skillname,"NOSKILL"))
            copy(skillname, 31, "coming soon")

         format(temp2, 256, "\d^n%d. %s %s %s   %s\w",
            vis_i, admstr, skillname, " - ", sLevelText)
      }else if (idx == SKILLIDX_SERPWARD){
         // Special ability
         format(temp2, 256, "^n%d. %s %s %s %d/%d (bind key wcward)  %s\w", vis_i,
            admstr, skillname, " - ", p_skills[id][idx], skill_limits[idx], sLevelText)
      }else if (idx == SKILLIDX_VENGEANCE){
         // Passive ultimate ability - special case
         format(temp2, 256, "^n%d. %s %s %s %d/%d (Passive Ability)  %s\w", vis_i,
            admstr, skillname, " - ", p_skills[id][idx], skill_limits[idx], sLevelText)
      }else if (equali(skillname,"NOSKILL")){
         // Special Case - skill not ready yet
         format(temp2, 256, "^n%d. skill being developed \w", vis_i)
      }else{
         if (skill_ultimates[idx][0])
            format(temp2, 256, "^n%d. %s %s %s %d/%d (bind key %s)  %s\w",
               vis_i, admstr, skillname, " - ", p_skills[id][idx], skill_limits[idx],
               skill_ultimates[idx], sLevelText)
         else
            format(temp2, 256, "^n%d. %s %s %s %d/%d  %s\w", vis_i, admstr, skillname,
                " - ", p_skills[id][idx], skill_limits[idx], sLevelText)
      }

      add(message, 2048, temp2)
   } 

   format(temp3, 32, "^n^n9. Next Page")
   add(message, 2048, temp3)
      
   format(temp3, 32, "^n^n0. Exit")
   add(message, 2048, temp3)
      
   show_menu(id, keys, message, -1)

   return PLUGIN_HANDLED
}
// **************************************************************************
// END select_skill subroutine
// **************************************************************************


// **************************************************************************
// BEGIN set_skill subroutine
// Set a specific skill for a player
// **************************************************************************
public set_skill(id, key){

   new name[32]
   new skillname[32]
   get_user_name(id, name, 31)


   // Calculate how many skill points can be spent
   new skillpts = get_availskillpts( id )


   if ( (key >= 0) && (key <= 7) ){
      // Player chose one of the skill training keys
      new sorted_idx = ((nSkillsPage[id]-1) * SKILLS_PER_SET) + key + 1
      new skill_idx = sortedskills[sorted_idx]
      new j = skill_idx

      if (j <= 8) copy(skillname, 31, skillset1[j])
      else if (j <= 16) copy(skillname, 31, skillset2[j-8])
      else if (j <= 24) copy(skillname, 31, skillset3[j-16])
      else if (j <= 32) copy(skillname, 31, skillset4[j-24])
      else if (j <= 40) copy(skillname, 31, skillset5[j-32])


      if (get_cvar_num("UW_DEBUG") == 5){
         new mapname[32]
         get_mapname(mapname,31)

         new skillcount = get_skillcount( id )

         log_amx( "DEBUG #4: In set_skill() Mapname=(%s) Player=(%s) skill_key=(%d)<%s> Level=(%d) #Skills=(%d), skillpts=(%d)", mapname, name, key, skillname, p_level[id], skillcount, skillpts )
      }


      // One of the skills was selected, check applicability
      if ( skillpts <= 0 ){
         // Player has no skill pts to spend
         client_print(id, print_chat, "[%s] You have no skill points to spend", MOD)
         return PLUGIN_HANDLED
      }


      // [06-08-2004] Changed skills training system, all skills have min. level
      if (p_level[id] < skill_minlev[skill_idx]){
         // Player is not yet allowed to train this skill
         client_print(id, print_chat, "[%s] You are not yet able to train that skill", MOD)
         return PLUGIN_HANDLED
      }

      // Check if player is trained to the max in this skill
      if (p_skills[id][skill_idx] >= skill_limits[skill_idx]){
         client_print(id, print_chat,
            "[%s] You have reached the maximum level for this skill", MOD)
         return PLUGIN_HANDLED
      }

      // [08-01-04] Admin-Reserved Skills Check
      if (get_cvar_num("UW_admin_mode") && admin_only[skill_idx]){
         if (!(get_user_flags(id)&ADMIN_IMMUNITY)) {
            client_print(id, print_chat, "[%s] This skill is reserved for Administrators, Admin accounts are available -- see http://www.wolfpaw.net/csadm/")
            return PLUGIN_HANDLED
         }
      }


      // [07-13-04] More restrictive training system, can only put 1 skill pt into
      // a skill for each level over (or equal) to the min. level to train it
      new allowed_pts = (p_level[id] - skill_minlev[skill_idx] + 1)
      if ((skill_limits[skill_idx] > 1) && (p_skills[id][skill_idx] >= allowed_pts)){
         client_print(id, print_chat,
            "[%s] You have trained the allowed limit for this skill at your current level. Try again next level.", MOD)
         return PLUGIN_HANDLED
      }

      // Specific skill-restrictions follow (some skills dont work with others)

      // [06-10-2004] K2mia - Only allow Steel Skin if Vampiric and Leather Skin trained
      if (skill_idx == SKILLIDX_SSKIN &&
          ((p_skills[id][SKILLIDX_LSKIN] < 3) || !(p_skills[id][SKILLIDX_VAMPIRIC])))
      {
         client_print(id, print_chat, "[%s] You must be trained in 1 level of Vampiric Aura and 3 levels of Leather Skin to train this skill", MOD)
         return PLUGIN_HANDLED
      }

      // [06-09-2004] K2mia - Allow only one damage shield skill
      if ((skill_idx == SKILLIDX_CARAPACE) && (p_skills[id][SKILLIDX_THORNS])){
         client_print(id, print_chat, "[%s] Only one damage shield skill is allowed, you would have to give up your Thorns Aura", MOD)
         client_print(id, print_center, "[%s] Only one damage shield skill is allowed, you would have to give up your Thorns Aura", MOD)
         return PLUGIN_HANDLED
      }else if ((skill_idx == SKILLIDX_THORNS) && (p_skills[id][SKILLIDX_CARAPACE])){
         client_print(id, print_chat, "[%s] Only one damage shield skill is allowed, you would have to give up your Spiked Carapace", MOD)
         client_print(id, print_center, "[%s] Only one damage shield skill is allowed, you would have to give up your Spiked Carapace", MOD)
         return PLUGIN_HANDLED
      }

      // [06-09-2004] K2mia - Allow only one of Shadow Strike / Carrion Beetles
      if ((skill_idx == SKILLIDX_SSTRIKE) && (p_skills[id][SKILLIDX_CARRION])){
         client_print(id, print_chat, "[%s] You would have to first give up your Carrion Beetles skill to train this", MOD)
         client_print(id, print_center, "[%s] You would have to first give up your Carrion Beetles skill to train this", MOD)
         return PLUGIN_HANDLED
      }else if ((skill_idx == SKILLIDX_CARRION) && (p_skills[id][SKILLIDX_SSTRIKE])){
         client_print(id, print_chat, "[%s] You would have to first give up your Shadow Strike skill to train this", MOD)
         client_print(id, print_center, "[%s] You would have to first give up your Shadow Strike skill to train this", MOD)
         return PLUGIN_HANDLED
      }

      // [07-02-2004] K2mia - Allow only one of Vengeance / Suicide Bomber
      if ((skill_idx == SKILLIDX_VENGEANCE) && (p_skills[id][SKILLIDX_SUICIDE])){
         client_print(id, print_chat, "[%s] You would have to first give up your Suicide Bomber ultimate to train this", MOD)
         client_print(id, print_center, "[%s] You would have to first give up your Suicide Bomber ultimate to train this", MOD)
         return PLUGIN_HANDLED
      }else if ((skill_idx == SKILLIDX_SUICIDE) && (p_skills[id][SKILLIDX_VENGEANCE])){
         client_print(id, print_chat, "[%s] You would have to first give up your Vegeance ultimate to train this", MOD)
         client_print(id, print_center, "[%s] You would have to first give up your Vegeance ultimate to train this", MOD)
         return PLUGIN_HANDLED
      }


      // If we make it here the player is able to train this skill

      if ((ultlearned[id] >= MAX_ULTIMATES) && (skill_ultimates[skill_idx][0])){
         // Player has trained maximum # of ultimate skills
         client_print(id, print_chat, "[%s] You have already trained the maximum number of ultimate skills [%d]", MOD, MAX_ULTIMATES)
         return PLUGIN_HANDLED
      }


      if(equali(skillname,"NOSKILL")){
         // Prevent player from blowing a point on a non-existant skill
         client_print(id, print_chat, "[%s] This skill slot is reserved for an upcoming skill", MOD)
         return PLUGIN_HANDLED
      }

      if (p_skills[id][skill_idx])
         if (p_skills[id][skill_idx] == (skill_limits[skill_idx] - 1)){
            client_print(0, print_chat,
               "[%s] Announcement ::  %s has mastered %s", MOD, name, skillname)
         }else{
            client_print(id, print_chat,
               "[%s] You have expanded your knowledge of %s", MOD, skillname)
         }
      else{
         new utext[128] = ""
         if (skill_ultimates[skill_idx][0] && (skill_idx != SKILLIDX_VENGEANCE) ){
            format(utext, 128, "[ Ultimate Skill, in console: bind key %s ]",
               skill_ultimates[skill_idx])
         }
         client_print(id, print_chat, "[%s] You have learned the basics of %s %s",
            MOD, skillname, utext)
      }

      // Increase the player's skill in the skill at index skill_idx
      p_skills[id][skill_idx] += 1

      // [07-18-2004] - Save to default skillset 1
      if ( get_cvar_num("mp_sql") && !get_cvar_num("mp_sql_saveoncmdonly") )
         sqlwrite_skills_id( id, skill_idx, 1)
      else
         write_skills_id( id, 1 )

      // See what adjustments are needed for new skill
      check_skills( id, false)

      //client_print(0, print_console, "DEB: id=(%d) sidx=(%d) sk_ult=(%s)", id, skill_idx, skill_ultimates[skill_idx][0])

      if (skill_ultimates[skill_idx][0]){
         new utext[128] = ""
         // Player learned an ultimate skill
         ultimateused[id]=false
         //icon_controller(id, ICON_HIDE)
         ultlearned[id]++

         if ( skill_idx == SKILLIDX_VENGEANCE ){
            format(utext, 128, "Ultimate ability Vengeance trained, no bind required" )
         }else{
            format(utext, 128, "Ultimate ability trained, in console: bind key %s",
               skill_ultimates[skill_idx])
         }

         set_hudmessage(200, 100, 0, -1.0, 0.3, 0, 1.0, 7.0, 0.1, 0.2, 3)
         show_hudmessage(id, utext)

         icon_controller(id, ICON_SHOW)

      }

      displaylevel(id, 3)

      if (skillpts > 1){
         // Player still has skillpts to spend, return to skill menu
         select_skill(id, nSkillsPage[id])
         return PLUGIN_HANDLED
      }
   }

   if (key == 8){
      // Set global skills page variable
      nSkillsPage[id] = (nSkillsPage[id] < MAX_SKILL_PAGES) ? nSkillsPage[id] + 1 : 1
      select_skill(id, nSkillsPage[id])
      return PLUGIN_HANDLED 
   }     
            
   return PLUGIN_HANDLED 
         
}     
// **************************************************************************
// END set_skill subroutine
// **************************************************************************


// **************************************************************************
// BEGIN get_skillcount subroutine
// Count the number of skill pts a player has 
// **************************************************************************
public get_skillcount(id){

   new skillcount = 0

   for (new j=0; j<MAX_SKILLS; j++)
      skillcount += p_skills[id][j]

   return skillcount
}
// **************************************************************************
// END get_skillcount subroutine
// **************************************************************************


// **************************************************************************
// BEGIN get_availskillpts subroutine
// Count the number of skill pts available to a player
// **************************************************************************
public get_availskillpts(id){

   new skillptsavail = 0
   new skillcount = get_skillcount(id)

   if (skillcount < p_level[id])
      skillptsavail = (p_level[id] - skillcount)

   return skillptsavail
}
// **************************************************************************
// END get_availskillpts subroutine
// **************************************************************************


// **************************************************************************
// BEGIN resetskills subroutine
// Sets a flag to reset all skill values to 0 
// **************************************************************************
public resetskills(id){
   if (!warcraft3)
     return PLUGIN_CONTINUE
         
   if (get_cvar_num("FT_reset_skills")){
      client_print(id, print_center, "Your skills will be reset next round")
      resetskill[id] = true
   }else{
      client_print(id, print_center, "This server has disabled that option")
      resetskill[id] = false
   }  
         
   return PLUGIN_HANDLED
}
// **************************************************************************
// END resetskills subroutine
// **************************************************************************  


// **************************************************************************
// BEGIN reloadskills subroutine
// Reloads a set of skills
// **************************************************************************
public reloadskills(id){
   if (!warcraft3)
     return PLUGIN_CONTINUE

   if (get_cvar_num("FT_reset_skills")){
      client_print(id,print_center, "Your skills will be reloaded next round")
      reloadskill[id]=true
   }else{
      client_print(id,print_center, "This server has disabled that option")
      reloadskill[id]=false
   }

   return PLUGIN_HANDLED
}
// **************************************************************************
// END reloadskills subroutine
// **************************************************************************


// **************************************************************************
// BEGIN admin_loadskills subroutine
// Loads a saved set of skills
// **************************************************************************
public admin_loadskills(id){
   if (!warcraft3)
     return PLUGIN_CONTINUE

   if (!(get_user_flags(id) & get_cvar_num("UW_admin_flag")) ) {
      if(id != 0){
         client_print(id,print_center,"You have no access to that command")
         return PLUGIN_HANDLED
      }
   }

   new arg[32]
   read_argv(1,arg,31)

   new set = str_to_num(arg)

   if (set < 1 || set > 4){
      // set will allow multiple skillsets to be saved and retrieved
      set = 1
   }

   get_skills_id( id, set)


   return PLUGIN_HANDLED
}
// **************************************************************************
// END admin_loadskills subroutine
// **************************************************************************


// **************************************************************************
// BEGIN set_maxhealth subroutine
// Sets a player's maxhealth based on skills and attrib settings
// **************************************************************************
public set_maxhealth(id, sethealth){

   if (p_skills[id][SKILLIDX_DEVOTION]){
      // Devotion Aura
      // Set player's max. health for use with mend
      maxhealth[id] = p_devotion[p_skills[id][SKILLIDX_DEVOTION]-1]
   }else{
      // Set player's max. health for use with mend
      maxhealth[id] = 100
   }

   if (USE_ENH && (p_attribs[id][ATTRIBIDX_STR] > ATTRIB_BASE)){
      // Player has enhanced their strength attribute
      new estr = (p_attribs[id][ATTRIBIDX_STR] - ATTRIB_BASE)
      maxhealth[id] += (STR_HEALTH_BONUS * estr)
   }

   if ( sethealth ){
      set_user_health_log(id, maxhealth[id], true, "set_maxhealth()")
   }

   if ( get_cvar_num("UW_DEBUG") == 5 ){
      new name[32]
      get_user_name(id, name, 31)
      log_amx( "In set_maxhealth() :: [%s} maxhealth=(%d) devotion=(%d) str=(%d)", 
               name, maxhealth[id], p_skills[id][SKILLIDX_DEVOTION], 
               p_attribs[id][ATTRIBIDX_STR] ) 
   }

   return PLUGIN_CONTINUE
}
// **************************************************************************
// END set_maxhealth subroutine
// **************************************************************************


// **************************************************************************
// BEGIN check_conregen subroutine
// Check player's constitution and start regen task if necessary
// **************************************************************************
public check_conregen(id){

   // [08-04-04] - Constitution health regen code - K2mia
   if (p_attribs[id][ATTRIBIDX_CON] > ATTRIB_BASE){
      // Remove running task for Con Health
      if (task_exists(id+1100))
         remove_task(id+1100)

      new econ = (p_attribs[id][ATTRIBIDX_CON] - ATTRIB_BASE)

      new newparm[2]
      newparm[0] = id
      newparm[1] = econ

      set_task(1.0, "con_heal", id+1100, newparm, 2)
   }else{
      if (task_exists(id+1100))
         remove_task(id+1100)
   }

   return PLUGIN_CONTINUE
}
// **************************************************************************
// END check_conregen subroutine
// **************************************************************************


// **************************************************************************
// BEGIN check_skinbonus subroutine
// Check if player has leather/steel skin for armor bonuses
// **************************************************************************
public check_skinbonus(id){

   // [09-04-04] - Modified for helmet and suit checks, maxarmor modifier - K2mia
   if (p_skills[id][SKILLIDX_LSKIN]){
      // Set player adjusted max. armor for use with repair armor
      new abonusmult = 0
      new abonus = 0

      // If Steel Skin trained use improved armor bonus
      if (p_skills[id][SKILLIDX_SSKIN]){
         helmet[id] = true
         abonusmult = ARMORBONUS2
      }else{
         helmet[id] = false
         abonusmult = ARMORBONUS1
      }

      if (p_level[id] > 30) abonus = (abonusmult * 6)
      else if (p_level[id] > 25) abonus = (abonusmult * 5)
      else if (p_level[id] > 20) abonus = (abonusmult * 4)
      else if (p_level[id] > 15) abonus = (abonusmult * 3)
      else if (p_level[id] > 10) abonus = (abonusmult * 2)
      else abonus = abonusmult

      hassuit[id] = true

      maxarmor[id] = (NORMALARMORMAX + abonus)
   }else{
      // Set player default max. armor for use with repair armor
      if (get_user_armor(id) > 0){
         maxarmor[id] = 100
         hassuit[id] = true
      }else
         maxarmor[id] = 0
   }

   //client_print(id, print_console, "[%s DEBUG] helmet=(%d) hassuit=(%d)
   //  maxarmor: %d", MOD, helmet[id], hassuit[id], maxarmor[id])


   return PLUGIN_CONTINUE
}
// **************************************************************************
// END check_skinbonus subroutine
// **************************************************************************


// **************************************************************************
// BEGIN check_tasks subroutine
// Check for skill-related tasks to be removed or restarted
// **************************************************************************
public check_tasks(id){

   new parm[2]
   parm[0]=id

   if ( !is_user_connected( id ) )
      return PLUGIN_CONTINUE

   if (p_skills[id][SKILLIDX_HEALWAVE]){
      // Healing Wave
      if (task_exists(id+90))
         remove_task(id+90)
      set_task(1.0,"healitnow",id+90,parm,2)
   }else{
      if (task_exists(id+90))
         remove_task(id+90)
   }

   if (p_skills[id][SKILLIDX_LSKIN]){
      // Leather Skin
      if (task_exists(id+1200))
         remove_task(id+1200)

      if (get_user_armor(id) <= 0){
         if (p_skills[id][SKILLIDX_SSKIN])
            give_item(id, "item_assaultsuit")
         else
            give_item(id, "item_kevlar")
      }

      set_task(1.0,"dolskin",id+1200,parm,2)
   }else{
      if (task_exists(id+1200))
         remove_task(id+1200)
   }

   if(!task_exists(600+id))
      walker(parm)

   if (!task_exists(50+id)){
      if (get_cvar_num("FT_blinkstartdisabled")){
         blinkdelayed[id]=true
         set_task(get_cvar_float("FT_blink_delay"),"cooldown2",50 + id,parm,1)
      }
   }

   return PLUGIN_CONTINUE
}
// **************************************************************************
// BEGIN check_tasks subroutine
// Check for skill-related tasks to be removed or restarted
// **************************************************************************


// **************************************************************************
// BEGIN check_serpwards subroutine
// Check for serpant ward skill, set ward count
// **************************************************************************
public check_serpwards(id){

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

   return PLUGIN_CONTINUE
}
// **************************************************************************
// END check_serpwards subroutine
// **************************************************************************


// **************************************************************************
// BEGIN phoenix_count subroutine
// Count up number of phoenixes for each team
// **************************************************************************
public phoenix_count(id){

   if (p_skills[id][SKILLIDX_PHOENIX] && is_user_alive(id)){
      // Pheonix
      new Float:randomnumber = random_float(0.0,1.0)
      new teamnumber = get_user_team(id)
      
      if (randomnumber <= p_phoenix[p_skills[id][SKILLIDX_PHOENIX]-1]){
         phoenix[id]=true
         if (teamnumber == 1)
            pheonixexistsT++
         else if (teamnumber == 2)
            pheonixexistsCT++
      }  
   }

   return PLUGIN_CONTINUE
}
// **************************************************************************
// END phoenix_count subroutine
// **************************************************************************


// **************************************************************************
// BEGIN check_skills subroutine
// Gives skill abilities at new round start and when skills are selected
// **************************************************************************
public check_skills(id, sethealth){

   new parm[2]
   parm[0]=id

   set_maxhealth( id, sethealth )	// Set user id's maxhealth[] for the round
   check_conregen( id )	 		// Check if constitution regen should be started
   check_skinbonus( id )		// Set user id's maxarmor[] for the round 
   check_blink( id )	 		// Check if user id gets blink active this round
   check_tasks (id )	 		// Check for task cleanup/restarts
   check_serpwards( id ) 		// Give serpant wards if necessary
   phoenix_count( id )	 		// Count phoenixes for each team
   
      
   if (p_skills[id][SKILLIDX_GATE]){
      // Gate Ultimate, determine number of gates this round by level
      if (p_level[id] >= 30) numgates[id] = 3
      else if (p_level[id] >= 20) numgates[id] = 2
      else numgates[id] = 1
   }
   
   icon_controller(id,ICON_SHOW)
      
   return PLUGIN_CONTINUE
         
}        
// **************************************************************************
// END check_skills subroutine
// **************************************************************************



// **************************************************************************
// BEGIN skills_info subroutine
// Displays the skills info page
// **************************************************************************
public skills_info(id, tier){

   if (warcraft3==false)
      return PLUGIN_CONTINUE

   //new message[2048] = ""
   new temp[2048] = ""
   new pos = 0

   pos+= format(temp[pos],2048-pos,"<body bgcolor=#000000><font color=#FFB000>" )

   new startidx = ((tier-1) * SKILLS_PER_SET) + 1
   new endidx = startidx + (SKILLS_PER_SET - 1)

   pos+= format(temp[pos],2048-pos,"<b>Skill Listings: Page %d</b>: <p><ol>", tier)

   for (new i=startidx; i <= endidx; i++){
      new j = sortedskills[i]

      switch (j){
         case SKILLIDX_VAMPIRIC:
            pos+= format(temp[pos],2048-pos,"<li>Vampiric Aura: Gives you (10%% to 37%%) of the damage you do in attack back as health<p>" )
         case SKILLIDX_LEVITATION:
            pos+= format(temp[pos],2048-pos,"<li>Levitation: Allows you to jump higher by reducing your gravity<p>" )
         case SKILLIDX_DEVOTION:
            pos+= format(temp[pos],2048-pos,"<li>Devotion Aura: Gives you (110 to 155) health at the start of the round.<p>" )
         case SKILLIDX_EQREINC:
            pos+= format(temp[pos],2048-pos,"<li>Equipment Reincarnation: Gives you a (%d%%, %d%% or %d%%) chance of regaining your equipment on death<p>",floatround(p_ankh[0]*100),floatround(p_ankh[1]*100),floatround(p_ankh[2]*100) )
         case SKILLIDX_HEALWAVE:
            pos+= format(temp[pos],2048-pos,"<li>Healing Wave: Every (6 down to 1.5) seconds you and your nearby teammates around you gain 2 HP<p>" )
         case SKILLIDX_SIPHON:
            pos+= format(temp[pos],2048-pos,"<li>Siphon Mana: Steal (5%% to 14%%) of the enemy's money<p>" )
         case SKILLIDX_IMPALE:
            pos+= format(temp[pos],2048-pos,"<li>Impale: Adds a chance to cause the ground the shake beneath your enemy. High intellect may help your chances to land a successful impale attack.<p>" )
         case SKILLIDX_LSKIN:
            pos+= format(temp[pos],2048-pos,"<li>Leather Skin: Natural armor enhancement and regeneration<p>")
         case SKILLIDX_UNHOLY:
            pos+= format(temp[pos],2048-pos,"<li>Unholy Aura: Gives you a speed boost, weapons will no longer affect your unholy speed. Enhancing your agility improves your overall run speed.<p>" )
         case SKILLIDX_BASH:
            pos+= format(temp[pos],2048-pos,"<li>Bash: When you shoot someone you have a (10%% to 37%%) chance of rendering them immobile for 1 second. Enhancements made to your Intellect may help a Bash attack.<p>" )
         case SKILLIDX_CRITSTRIKE:
            pos+= format(temp[pos],2048-pos,"<li>Critical Strike: Gives you a 15%% to 24%% chance of doing double the normal damage<p>" )
         case SKILLIDX_REPAIR:
            pos+= format(temp[pos],2048-pos,"<li>Repair Armor (Special Ability): Allows you the opportunity to repair a teammate's armor as an alternate means of gaining XP. As your rank/level increases your effectiveness at armor repair also improves. To use: target a teammate and trigger the wcrepair command<p>" )
         case SKILLIDX_BANISH:
            pos+= format(temp[pos],2048-pos,"<li>Banish: You have a (6%% to 24%%) chance of slapping your enemy. High intellect may help your chance to banish an enemy.<p>" )
         case SKILLIDX_HEX:
            pos+= format(temp[pos],2048-pos,"<li>Hex: You have a (5%% to 23%%) chance of morphing your enemy into a less than desirable form. Enhancements made to your intellect may help your Hex attacks.<p>" )
         case SKILLIDX_CARAPACE:
            pos+= format(temp[pos],2048-pos,"<li>Spiked Carapace: Does (5%% to 23%%) mirror damage to the person who shot you and you gain armor<p>" )
         case SKILLIDX_MEND:
            pos+= format(temp[pos],2048-pos,"<li>Mend Wounds (Special Ability): Allows you the opportunity to heal a teammate's wounds as an alternate means of gaining XP. As your rank/level increases your effectiveness at mending wounds also improves. 2nd skill level adds ability to cure poison, 3rd skill level adds ability to cure burns from napalm or a flame thrower. To use: target a teammate and trigger the wcmend command<p>" )
         case SKILLIDX_EVASION:
            pos+= format(temp[pos],2048-pos,"<li>Evasion: Gives you a (5%% to 17%%) chance of evading each shot. Enhancing your dexterity improves your Evasion skill.<p>" )
         case SKILLIDX_TRUESHOT:
            pos+= format(temp[pos],2048-pos,"<li>Trueshot Aura: Does (10%% to 37%%) extra damage to the enemy. A superior Intellect will cause your Trueshot to inflict more damage.<p>" )
         case SKILLIDX_SSKIN:
            pos+= format(temp[pos],2048-pos,"<li>Steel Skin: [Requires 1 level Vampiric Aura and 3 levels Leather Skin] Upgrades your Leather Skin and allows Vampiric Aura to steal armor from your enemy<p>" )
         case SKILLIDX_CARRION:
            pos+= format(temp[pos],2048-pos,"<li>Carrion Beetles: You have a (10%% to 37%%) chance of sending Carrion Beetles to attack your enemy and spread disease<p>")
         case SKILLIDX_SSTRIKE:
            pos+= format(temp[pos],2048-pos,"<li>Shadow Strike: You have a (10%% to 37%%) chance of poisoning your enemy with<p>" )
         case SKILLIDX_ENTANGLE:
            pos+= format(temp[pos],2048-pos,"<li>Entangle Roots (Ultimate Ability): Allows you to prevent an enemy player from moving for 10 seconds<p>")
         case SKILLIDX_FSTRIKE:
            pos+= format(temp[pos],2048-pos,"<li>Flame Strike (Ultimate Ability): You receive a flame throwers (1 uses every 20 seconds)<p>")
         case SKILLIDX_FLASH:
            pos+= format(temp[pos],2048-pos,"<li>Flash of Light (Ultimate Ability): This ultimate ablity temporarily blinds your enemy (the duration improves as you gain levels)<p>" )
         case SKILLIDX_CRITGREN:
            pos+= format(temp[pos],2048-pos,"<li>Critical Grenade: Your HE grenades do (1.5 to 7.8) times normal damage<p>" )
         case SKILLIDX_SERPWARD:
            pos+= format(temp[pos],2048-pos,"<li>Serpent Ward (Special Ability): You receive (%d, %d or %d) serpent wards each round that damage nearby enemy units ( bind a key to wcward to plant one)<p>",p_serpent[0],p_serpent[1],p_serpent[2] )
         case SKILLIDX_THORNS:
            pos+= format(temp[pos],2048-pos,"<li>Thorns Aura: Does (10%% to 37%%) mirror damage to the person who shot you<p>" ) 
         case SKILLIDX_INVIS:
            pos+= format(temp[pos],2048-pos,"<li>Invisibility: Makes you partially invisible, you will be harder to see<p>" )
         case SKILLIDX_TELEPORT:
            pos+= format(temp[pos],2048-pos,"<li>Teleport (Ultimate Ability): Allows you to teleport to where you aim (avoid ceilings).<p>")
         case SKILLIDX_VOODOO:
            pos+= format(temp[pos],2048-pos,"<li>Big Bad Voodoo (Ultimate Ability): Invincibility for 3 seconds<p>")
         case SKILLIDX_FAN:
            pos+= format(temp[pos],2048-pos,"<li>Fan of Knives: You have a (%d%%, %d%% or %d%%) chance of becoming a mole<p>",floatround(p_fan[0]*100),floatround(p_fan[1]*100),floatround(p_fan[2]*100) )
         case SKILLIDX_VENGEANCE:
            pos+= format(temp[pos],2048-pos,"<li>Vengeance (Ultimate Ability): Respawn once with 50 health<p>" )
         case SKILLIDX_LOCUST:
            pos+= format(temp[pos],2048-pos,"<li>Locust Swarm (Ultimate Ability): A Swarm of Green Locusts attacks the enemy<p>") 
         case SKILLIDX_BLINK:
            pos+= format(temp[pos],2048-pos,"<li>Blink: Chance to disables ALL enemy ultimates (20%% to 100%%)<p>" ) 
         case SKILLIDX_PHOENIX:
            pos+= format(temp[pos],2048-pos,"<li>Phoenix: You have a (20%% to 100%%) chance of reviving the first teammate who dies<p>" )
         case SKILLIDX_NAPALM:
            pos+= format(temp[pos],2048-pos,"<li>Napalm Grenades: Each round your first he grenade will coat your enemies with napalm, anyone they touch will spread the napalm<p>" )        
         case SKILLIDX_SUICIDE:
            pos+= format(temp[pos],2048-pos,"<li>Suicide Bomber (Ultimate Ability): When you die you will explode killing nearby enemies and regenerate<p>")
         case SKILLIDX_LIGHTNING:
            pos+= format(temp[pos],2048-pos,"<li>Chain Lightning (Ultimate Ability): Discharges a bolt of lightning that jumps to all nearby enemies<p>")
         case SKILLIDX_DECOY:
            pos+= format(temp[pos],2048-pos,"<li>Decoy (Ultimate Ability): Spawns a temporary decoy (looks like you) where you are aiming<p>")
         case SKILLIDX_GATE:
            pos+= format(temp[pos],2048-pos,"<li>Gate (Ultimate Ability): Opens a Gateway for you to be teleported back to your spawn point and away from danger (hopefully)<p>")
      }
   }     
            
   pos+= format(temp[pos],2048-pos,"</ol><p>" ) 
         
   //add(message,2047,temp)

   show_motd( id, temp,"Skills Information")
            
   return PLUGIN_HANDLED

}        
// **************************************************************************
// END skills_info subroutine
// **************************************************************************


// **************************************************************************
// BEGIN dolskin  subroutines
// Handles leather skin armor regen events
// **************************************************************************
public dolskin(parm[2]){
   new id = parm[0]

   if (!endround && is_user_alive(id) && p_skills[id][SKILLIDX_LSKIN])
      set_task(p_lskin[p_skills[id][SKILLIDX_LSKIN]-1], "dolskin", id+1200, parm, 2)

   new abonusmult = 0
   new abonus = 0
   new atotal = 0

   // If Steel Skin trained use improved armor bonus
   if (p_skills[id][SKILLIDX_SSKIN]) abonusmult = ARMORBONUS2
   else abonusmult = ARMORBONUS1

   if (p_level[id] > 30) abonus = (abonusmult * 6)
   else if (p_level[id] > 25) abonus = (abonusmult * 5)
   else if (p_level[id] > 20) abonus = (abonusmult * 4)
   else if (p_level[id] > 15) abonus = (abonusmult * 3)
   else if (p_level[id] > 10) abonus = (abonusmult * 2)
   else abonus = abonusmult

   atotal = (NORMALARMORMAX + abonus)

   if (get_user_armor(id) < atotal){
      // Leather skin armor regen here
      //set_user_armor(id, get_user_armor(id) + 2)
      set_user_armor_log(id, (get_user_armor(id) + 2) , true, "dolskin()-1")
      if (get_user_armor(id) > atotal) 
         set_user_armor_log(id, atotal , true, "dolskin()-2")
         //set_user_armor(id, atotal)
   }

   new origin[3]
   get_user_origin(id,origin)

   if(playeritem[id]!=CLOAK && (!p_skills[id][SKILLIDX_INVIS])){
      message_begin( MSG_BROADCAST, SVC_TEMPENTITY );
      write_byte( TE_IMPLOSION );
      write_coord(origin[0])  // initial position
      write_coord(origin[1])  // initial position
      write_coord(origin[2])  // initial position
      write_byte(100)   // radius
      write_byte( 8 );  // count
      write_byte( 1 );  // life
      message_end();
   }

   return PLUGIN_CONTINUE
}
// **************************************************************************
// END dolskin  subroutines
// **************************************************************************


// **************************************************************************
// BEGIN healingitnow healingnext and healingeffect subroutines
// Handles Healing Wave effects       
// **************************************************************************
public healitnow(parm[2]){
   new id = parm[0]
         
   if (!endround && is_user_alive(id) && p_skills[id][SKILLIDX_HEALWAVE])
      set_task(p_heal[p_skills[id][SKILLIDX_HEALWAVE]-1],"healitnow",id+90,parm,2)
   healingnext(parm)
   
   return PLUGIN_CONTINUE
}  
   
public healingnext(parm[2]){
   // Healing Wave
   new id=parm[0]
   new origin[3]
   get_user_origin(id, origin)
   new players[32]
   new numberofplayers
   new teamname[32]
   get_user_team(id, teamname, 31)
   //get_players(players, numberofplayers,"ae",teamname)
   get_players(players, numberofplayers)
   new i
   new targetid = 0
   new distancebetween = 0
   new targetorigin[3]
   new heal = 2    // [5-21-04] Changed from heal of 1 to heal of 2 by K2mia
   new closestid = 0
   for (i = 0; i < numberofplayers; ++i){
      targetid=players[i]
      
      if ( get_user_team(id) != get_user_team(targetid) ) continue
      
      if (get_user_team(id)==get_user_team(targetid) && is_user_alive(targetid)){
         get_user_origin(targetid,targetorigin)
         distancebetween=get_distance(origin,targetorigin)
         if (distancebetween < get_cvar_num("FT_healing_range") &&!healinghit[targetid])
            closestid = targetid
      }
   }  

   if (closestid){
      healingeffect(id,closestid,heal)
      parm[0]=targetid
      parm[1]=heal
      set_task(0.2,"healingnext",27,parm,2)
   }else{
      for (i = 0; i < numberofplayers; ++i){
         targetid=players[i]
         healinghit[targetid]=false
      }
   }
   return PLUGIN_CONTINUE
}

public healingeffect(id,targetid,heal){

   // [08-10-04] - Subroutine completely rewritten - K2mia

   healinghit[targetid]=true

   if (!is_user_alive(targetid))
      return PLUGIN_HANDLED

   new bool:was_healed = false

   new health = maxhealth[targetid] + (playeritem[targetid] == HEALTH ? HEALTHBONUS : 0)

   if (get_user_health(targetid) < health){
      was_healed = true
      set_user_health_log(targetid, get_user_health(targetid) + heal, true,
         "healingeffect() HEAL")
   }


   // [09-26-04] Adjustment if maxhealth exceeded - K2mia
   if (get_user_health(targetid) > health)
      set_user_health_log(targetid, health, true, "healingeffect() ADJUST")


   if (!was_healed)
      return PLUGIN_CONTINUE


   new origin[3]
   get_user_origin(targetid,origin)

   if(playeritem[targetid]!=CLOAK && (!p_skills[targetid][SKILLIDX_INVIS])){
      message_begin( MSG_BROADCAST, SVC_TEMPENTITY );
      write_byte( TE_IMPLOSION );
      write_coord(origin[0])  // initial position
      write_coord(origin[1])  // initial position
      write_coord(origin[2])  // initial position
      write_byte(100)   // radius
      write_byte( 8 );  // count
      write_byte( 1 );  // life
      message_end();
   }

   return PLUGIN_CONTINUE
}
// **************************************************************************
// END healingitnow healingnext and healingeffect subroutines
// **************************************************************************


// **************************************************************************
// BEGIN jumper subroutine
// Set the goomba jumping
// **************************************************************************
public jumper(parm[2]){ 
   new id = parm[0]
   client_cmd(id,"+jump;wait;-jump")
   parm[1]++     
   if(!endround && is_user_alive(id))
      set_task(3.0, "jumper", 2000+id, parm, 1)
            
   return PLUGIN_CONTINUE
}           
// **************************************************************************
// END jumper subroutine
// **************************************************************************


// **************************************************************************
// BEGIN walker subroutine
// Legacy routine from War3FT, no longer footstep related code 
// **************************************************************************
public walker(parm[2]){
   new id = parm[0]

   // Other function calls to do every .1 seconds
   client_cmd(id,"cl_minmodels 0")
   if(get_cvar_num("FT_centerhud"))
      client_cmd(id,"hud_centerid 0")

   // End Other function calls
   if (!endround)
      set_task(0.1,"walker",600+id,parm,2)

}
// **************************************************************************
// END walker subroutine
// **************************************************************************


// **************************************************************************
// BEGIN regenerate subroutine
// Regenerate a player's health due to skill or item
// **************************************************************************
public regenerate(parm[]){
   // [08-10-04] - Subroutine completely rewritten - K2mia
   new id = parm[0]

   if(playeritem2[id]!=REGEN)
      return PLUGIN_HANDLED

   new bonus = rings[id]

   set_hudmessage(0, 100, 0, 0.05, 0.65, 2, 0.02, 10.0, 0.01, 0.1, 2)
   set_task(2.0,"regenerate",9000+id,parm,2)

   if(get_user_health(id)>1500)
      return PLUGIN_HANDLED

   new health = maxhealth[id] + (playeritem[id] == HEALTH ? HEALTHBONUS : 0)

   if (get_user_health(id) < health){
      set_user_health_log(id, get_user_health(id) + bonus, true,
         "regenerate()")
   }

   return PLUGIN_CONTINUE

}
// **************************************************************************
// END regenerate subroutine
// **************************************************************************


// **************************************************************************
// BEGIN unholyspeed subroutine
// Handles the Unholy Aura skill
// **************************************************************************
public unholyspeed(parm[1]){
   if (!warcraft3)
      return PLUGIN_CONTINUE

   new id = parm[0]
   new Float:speed = 0.0

   if ( !is_user_connected( id ) )
      return PLUGIN_CONTINUE

   //client_print(id, print_console,
   // "[%s DEBUG begin unholyspeed()] id=(%d) maxspeed=(%f)", MOD, id,get_user_maxspeed(id))

   if (p_skills[id][SKILLIDX_UNHOLY]){
      speed = p_unholy[p_skills[id][SKILLIDX_UNHOLY]-1] +
         ((playeritem[id] == BOOTS) ? 25.0 : 0.0)
   }else{
      speed = (playeritem[id] == BOOTS) ? BOOTSPEED : get_cvar_float("UW_normalspeed")
   }

   if (USE_ENH && (p_attribs[id][ATTRIBIDX_AGI] > ATTRIB_BASE) ){
      new eagi = (p_attribs[id][ATTRIBIDX_AGI] - ATTRIB_BASE)
      new Float:espeed = (float(eagi) * 8.0)
      speed += espeed
   }


   if (stunned[id]){
      set_user_maxspeed(id, 1.0)
      return PLUGIN_HANDLED
   }else if (slowed[id]){
      set_user_maxspeed(id, FROSTSPEED)
   }else if (isdiseasedcb[id]){
      // Added slowness component to Carrion Beetles disease
      set_user_maxspeed(id, CBSPEED)
   }else if (get_user_maxspeed(id) > 10 && !freezetime && (get_user_maxspeed(id) < speed) ){
      set_user_maxspeed(id, speed)
   }

   //new Float:tspeed = get_user_maxspeed(id)
   //client_print(id, print_console,
   //   "[%s DEBUG end of unholyspeed()] Player %d has speed %f", MOD, id, tspeed)

   return PLUGIN_CONTINUE

}
// **************************************************************************
// END unholyspeed subroutine
// **************************************************************************


// **************************************************************************
// BEGIN check_blink subroutine
// Check the blink blades skill
// **************************************************************************
public check_blink(id){
   if (p_skills[id][SKILLIDX_BLINK]){
      // Blink
      new Float:randomnumber = random_float(0.0,1.0)
      if (randomnumber <= p_blink[p_skills[id][SKILLIDX_BLINK]-1])
         hasblink[id]=true
      else
         hasblink[id]=false
   }else
      hasblink[id]=false

}
// **************************************************************************
// END check_blink subroutine
// **************************************************************************


// **************************************************************************
// END General Skills Related Subroutines
// **************************************************************************

