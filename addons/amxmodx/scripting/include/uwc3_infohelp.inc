
/** *************************************************************************
*** AMXX Plugin:   Ultimate Warcraft3 (UWC3)
*** Plugin Author: K2mia
*** UWC3 Module:   Enhancements (Attributes / Resistances)
*** Date:          May 25, 2004
*** Last Update:   September 23, 2004
*
*  Module: Help and Info / Menu Subroutines 
*  Subroutines for help and info text and menus
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
// BEGIN Help and Info Menus and Menu Handler Subroutines
// **************************************************************************


// **************************************************************************
// BEGIN show_news subroutine
// Display the server news
// **************************************************************************
public show_news(id){

   new temp[3076]
   new pos = 0

   pos += format(temp[pos], 3076-pos, "<body scroll='no' bgcolor=#000000><font color=#FFB000>")
   pos += format(temp[pos], 2048-pos, "<table border=0><tr><td><font color=#FFB000>")

   pos += format(temp[pos], 2048-pos, "<center><b>Ultimate Warcraft3</b><br><a href='http://www.uwc3.com/'><b>http://www.uwc3.com/</b></a></center><p>" )

   pos += format(temp[pos], 3076-pos, "<b>Latest News About Ultimate Warcraft3</b><br>")
   pos += format(temp[pos], 3076-pos, "<b>http://forums.uwc3.com/ - See forums for complete ChangeLog</b><br><ul>")

   pos += format(temp[pos], 3076-pos, "<li>[10-30-04] Necklaces no longer protect against serpent wards.<p>")
   
   pos += format(temp[pos], 3076-pos, "<li>[10-24-04] Testing Teleport Immunity issues bugfix. Testing Mask of Death bugfix. Mirror damage skills/evasion bug fixed. Testing fix for skill/attrib/health known reset issue. Testing bugfix for Vengeance/Phoenix overlap. Fixed Ultimate-status HUD message. Playerskills has been replaced by /who, added /whois playername command to display player character sheets.<p>")

   pos += format(temp[pos], 3076-pos, "<li>[10-10-04] Many run-time errors fixed, thanks to Hellion and Kamikaze for sending their bug reports and error logs!<p>")

   pos += format(temp[pos], 3076-pos, "<li>[9-27-04] Fixed objectives bug which awarded XP to dead players (pffft). Skillcount bug should now be fixed, players with incorrect skillsets will be forced to reset.<p>")

   pos += format(temp[pos], 3076-pos, "<li>[9-23-04] Testing fixes for skillcount being out of sync (auto-reset), insane player health bug. Testing fixes for objective/winning XP award bugs. Version change to v1.0.0RC1 . Fixed /deletexp command. New commands: saveattribs, saveresists, saveskills, saveall<p>")

   pos += format(temp[pos], 3076-pos, "<li>[9-14-04] Serious Injury XP bonus bug fixed. Voodoo end of round bug fixed.<p>")

   pos += format(temp[pos], 3076-pos, "<li>[9-07-04] Big Changes! Attributes and Resistances now have server limits, Beta1 now limits players to 20 attribute pts and 250 resistance pts -- spend them wisely.<p>")

   pos += format(temp[pos], 3076-pos, "<li>[9-06-04] New animations for Napalm hits and new teleport animations for Gate ultimate. steve modified the Carrion Beetles bubble animation. Medic alert gfx, Armorsmith alert gfx added, live testing.<p>")

   pos += format(temp[pos], 3076-pos, "<li>[9-03-04] Crit strike/Trueshot backfire damage modified. Medic alerts now issues in sprite-mode as well as text-mode. UWC3 welcomes 'steve french' to the plugin dev team, and with him his replacement model for the Entangling Roots effect and replacement Carrion Beetles animated sprite, woot!<p>")

   pos += format(temp[pos], 3076-pos, "<li>[8-29-04] Equip Reincarnation fixed for failures due to Bomb Explosion, Defusers should always reincarnate now, grenades may still have some erratic respawn issues. Vengeance ultimate cooldown added, so ultimates will become available again after vengeance-based respawn.<p>")

   pos += format(temp[pos], 3076-pos, "<li>[8-22-04] Testing new bug fix for disease and poison resistance against Carrion Beetles and Shadow Strike<p>")

   pos += format(temp[pos], 3076-pos, "</ul></td></tr></table>")

   show_motd( id, temp, "UWC3 News")

   return PLUGIN_CONTINUE
}
// **************************************************************************
// END show_news subroutine
// **************************************************************************


// **************************************************************************
// BEGIN main_menu subroutine
// The main WC3 menu
// **************************************************************************
public main_menu(id){

   if (!warcraft3)
      return PLUGIN_HANDLED

   new nLoop = 0
   new pos = 0, i, menu_body[512], menu_items[7][32]
   new keys = (1<<0)|(1<<1)|(1<<2)|(1<<3)|(1<<4)|(1<<5)|(1<<6)|(1<<9)

   menu_items[0]= "Skills Menu"
   menu_items[1]= "Item Menu"
   menu_items[2]= "Help"
   menu_items[3]= "UWC3 Credits"
   menu_items[4]= "Commands List"
   menu_items[5]= "Your Character Sheet"
   menu_items[6]= "Admin Menu"

   pos += format(menu_body[pos], 511-pos, "\yUWC3: Main Menu [ http://www.mudconnect.com/uwc3/ ]^n^n")

   if ( !get_cvar_num("UW_disable_adminmenu") && 
        (get_user_flags(id) & get_cvar_num("UW_admin_flag")) )
   {
      nLoop = 7
   }else{
      nLoop = 6
   }

   for (i = 0; i< nLoop; i++){
      pos += format(menu_body[pos], 511-pos, "\w%d. %s^n",i+1,menu_items[i])
   }

   pos += format(menu_body[pos], 511-pos, "^n\w0. Exit")
   show_menu( id, keys, menu_body, -1)

   return PLUGIN_HANDLED

}
// **************************************************************************
// END main_menu subroutine
// **************************************************************************



// **************************************************************************
// BEGIN do_wc3menu subroutine
// Handler for the main_menu routine
// **************************************************************************
public do_wc3menu(id,key){
   switch (key){
      case 0: skills_menu(id)
      case 1: item_menu(id)
      case 2: help_menu(id)
      case 3: uwc3_credits(id)
      case 4: uwc3_commands(id)
      case 5: character_sheet(id)
      case 6: admin_menu(id)
      default: return PLUGIN_HANDLED
   }
   return PLUGIN_HANDLED
}
// **************************************************************************
// END do_wc3menu subroutine
// **************************************************************************



// **************************************************************************
// BEGIN change_race subroutine
// Display the error message since no races in game
// **************************************************************************
public change_race(id){

   if (warcraft3==false)
      return PLUGIN_CONTINUE

   new temp[2048]
   new pos = 0

   pos += format(temp[pos], 2048-pos, "<body bgcolor=#000000><font color=#FFB000>")
   pos += format(temp[pos], 2048-pos, "<table border=0><tr><td><font color=#FFB000>")

   pos += format(temp[pos], 2048-pos, "<center><b>Ultimate Warcraft3</b><br><a href='http://www.uwc3.com/'><b>http://www.uwc3.com/</b></a></center><p>" )

   pos += format(temp[pos], 2048-pos, "Ultimate Warcraft3 (UWC3) is a raceless version of the Warcraft3 plugin you may be familiar with.<p>" )
   pos += format(temp[pos], 2048-pos, "UWC3 provides players with 34 playable levels and a freeform skills system which allows you to mix and match skills of your choosing. In addition UWC3 offers players a choice of 10 ultimate skills and you can train up to 3 different ultimates, as well as other special abilities. UWC3 also offers an optional Enhancement system to provide your character with even more customization. <p>")
   pos += format(temp[pos], 2048-pos, "Interested? Read on! Say <b>/help</b> for UWC3's help menu and say <b>/commands</b> to see the list of UWC3 spoken commands. Say <b>/news</b> to read up on the latest changes to the plugin.<p>" )

   pos += format(temp[pos], 2048-pos, "</td></tr></table>")

   show_motd( id, temp, "Ultimate Warcraft3")

   return PLUGIN_CONTINUE

}
// **************************************************************************
// END change_race subroutine
// **************************************************************************




// **************************************************************************
// BEGIN help_menu subroutine
// Display the help menu
// **************************************************************************
public help_menu(id){

   new pos = 0, i, menu_body[512], menu_items[8][32]
   new keys = (1<<0)|(1<<1)|(1<<2)|(1<<3)|(1<<4)|(1<<5)|(1<<6)|(1<<7)|(1<<8)|(1<<9)

   menu_items[0]= "UWC3 General Help"
   menu_items[1]= "About UWC3 Ultimates"
   menu_items[2]= "UWC3 Credits"
   menu_items[3]= "UWC3 Latest News"
   menu_items[4]= "(\rNew\w) Attributes Info"
   menu_items[5]= "(\rNew\w) Resistances Info"
   menu_items[6]= "Tips for Playing UWC3 pg.1"
   menu_items[7]= "Tips for Playing UWC3 pg.2"

   pos += format(menu_body[pos], 511-pos, "\yHelp Menu^n^n")
   for (i = 0; i<8; i++){
      pos += format(menu_body[pos], 511-pos, "\w%d. %s^n",i+1,menu_items[i])
   }
   pos += format(menu_body[pos], 511-pos, "^n^n\w9. Back")
   pos += format(menu_body[pos], 511-pos, "^n\w0. Exit")
   show_menu(id,keys,menu_body,-1)

   return PLUGIN_CONTINUE

}
// **************************************************************************
// END help_menu subroutine
// **************************************************************************


// **************************************************************************
// BEGIN do_helpmenu subroutine
// Handler for the help menu
// **************************************************************************
public do_helpmenu(id,key){
   switch (key){
      case 0: war3_info(id)
      case 1: uwc3_ultimates(id)
      case 2: uwc3_credits(id)
      case 3: show_news(id)
      case 4: uwc3_attributes(id)
      case 5: uwc3_resistances(id)
      case 6: uwc3_tips(id)
      case 7: uwc3_tips2(id)
      case 8: main_menu(id)
      default: return PLUGIN_HANDLED
   }
   return PLUGIN_HANDLED
}
// **************************************************************************
// BEGIN do_helpmenu subroutine
// **************************************************************************


// **************************************************************************
// BEGIN admin_menu subroutine
// Display the Admin menu
// **************************************************************************
admin_menu(id){

   if (!(get_user_flags(id) & get_cvar_num("UW_admin_flag"))) {
      if(id != 0){
         client_print(id,print_center,"You have no access to that command")
         return PLUGIN_HANDLED
      }
   }

   if ( get_cvar_num("UW_disable_adminmenu") ){
      client_print(id, print_center, "The Admin Menu has been disabled on this server")
      return PLUGIN_HANDLED
   }

   new pos = 0, i, menu_body[512], menu_items[3][32]
   //new keys = (1<<0)|(1<<1)|(1<<2)|(1<<8)|(1<<9)
   new keys = (1<<0)|(1<<1)|(1<<8)|(1<<9)

   menu_items[0]= "Give Individual Players XP"
   menu_items[1]= "Give Multiple Players XP"
   /*menu_items[2]= "Save everyone's XP"*/

   pos += format(menu_body[pos], 511-pos, "\yAdmin Menu^n^n")
   for (i = 0; i<2; i++){
      pos += format(menu_body[pos], 511-pos, "\w%d. %s^n",i+1,menu_items[i])
   }
   pos += format(menu_body[pos], 511-pos, "^n^n\w9. Back")
   pos += format(menu_body[pos], 511-pos, "^n\w0. Exit")
   show_menu(id,keys,menu_body,-1)

   return PLUGIN_HANDLED
}
// **************************************************************************
// END admin_menu subroutine
// **************************************************************************


// **************************************************************************
// BEGIN do_adminmenu subroutine
// Handler for the admin menu
// **************************************************************************
public do_adminmenu(id,key){
   switch (key){
      case 0:{
         g_menuOption[id] = 1
         g_menuSettings[id] = 50
         playerxp_menu(id,g_menuPosition[id] = 0)
      }
      case 1:{
         g_menuOption[id] = 1
         g_menuSettings[id] = 50
         teamxp_menu(id)
      }
      //case 2: server_cmd("amx_savexp @ALL")
      case 8: main_menu(id)
      default: return PLUGIN_HANDLED
   }
   return PLUGIN_HANDLED
}
// **************************************************************************
// BEGIN do_adminmenu subroutine
// **************************************************************************



// **************************************************************************
// BEGIN playerxp_menu subroutine
// Display the playerxp_menu for the WC3FT-Unlimited plugin
// **************************************************************************
playerxp_menu(id,pos){
   if (pos < 0){
      admin_menu(id)
      return PLUGIN_CONTINUE
   }

   get_players(g_menuPlayers[id],g_menuPlayersNum[id])
   new menuBody[512]
   new b = 0
   new i
   new name[32], team[4]
   new start = pos * 7

   if (start >= g_menuPlayersNum[id])
      start = pos = g_menuPosition[id] = 0

   new len = format(menuBody,511, "\yGive Players XP\R%d/%d^n\w^n",pos+1,(g_menuPlayersNum[id] / 7 + ((g_menuPlayersNum[id] % 7) ? 1 : 0 )))
   new end = start + 7
   new keys = (1<<9)|(1<<7)

   if (end > g_menuPlayersNum[id])
      end = g_menuPlayersNum[id]

   for(new a = start; a < end; ++a){
      i = g_menuPlayers[id][a]
      get_user_name(i,name,31)
      get_user_team(i,team,3)
      keys |= (1<<b)
      len += format(menuBody[len],511-len,"\w%d. %s^n\w",++b,name)
   }

   len += format(menuBody[len],511-len,"^n8. Give  %d XP^n",g_menuSettings[id])

   if (end != g_menuPlayersNum[id]){
      format(menuBody[len],511-len,"^n9. More...^n0. %s", pos ? "Back" : "Back")
      keys |= (1<<8)
   }else
      format(menuBody[len],511-len,"^n0. %s", pos ? "Back" : "Exit")

   show_menu(id,keys,menuBody)

   return PLUGIN_CONTINUE

}
// **************************************************************************
// END playerxp_menu subroutine
// **************************************************************************


// **************************************************************************
// BEGIN do_playerxpmenu subroutine
// Handler for the playerxp_menu for the WC3FT-Unlimited plugin
// **************************************************************************
public do_playerxpmenu(id,key){

   switch(key){
      case 7:{
         ++g_menuOption[id]
         if (g_menuOption[id]>6){
            g_menuOption[id]=1
         }
         switch(g_menuOption[id]){
            case 1: g_menuSettings[id] = 50
            case 2: g_menuSettings[id] = 100
            case 3: g_menuSettings[id] = 500
            case 4: g_menuSettings[id] = 1000
            case 5: g_menuSettings[id] = 5000
            case 6: g_menuSettings[id] = 10000
         }
         playerxp_menu(id,g_menuPosition[id])
      }
      case 8: playerxp_menu(id,++g_menuPosition[id])
      case 9: playerxp_menu(id,--g_menuPosition[id])
      default:{
         new player = g_menuPlayers[id][g_menuPosition[id] * 7 + key]

         new name[32]
         new pname[32]
         get_user_name(id, name, 31)
         get_user_name(player, pname, 31)

         log_amx( "[%s] %s used Admin-Menu XP [%s] for %s", 
                  MOD, name, g_menuSettings[id], pname )

         client_print(player, print_chat,
            "[%s] The admin just awarded you %d experience.",MOD,g_menuSettings[id])
         playerxp[player]+=g_menuSettings[id]
         displaylevel(player,1)
         playerxp_menu(id,g_menuPosition[id])
      }
   }

   return PLUGIN_HANDLED
}
// **************************************************************************
// END do_playerxpmenu subroutine
// **************************************************************************


// **************************************************************************
// BEGIN teamxp_menu subroutine
// Handler for the teamxp_menu for the WC3FT-Unlimited plugin
// **************************************************************************
teamxp_menu(id){
   new pos = 0, i, menu_body[512], menu_items[3][32]
   new keys = (1<<0)|(1<<1)|(1<<2)|(1<<7)|(1<<8)|(1<<9)

   menu_items[0]= "Terrorist"
   menu_items[1]= "Counter-Terrorists"
   menu_items[2]= "Everyone"

   pos += format(menu_body[pos], 511-pos, "\yTeam XP Menu^n^n")
   for (i = 0; i<3; i++){
      pos += format(menu_body[pos], 511-pos, "\w%d. %s^n",i+1,menu_items[i])
   }
   pos += format(menu_body[pos], 511-pos,"^n8. Give  %d XP^n",g_menuSettings[id])
   pos += format(menu_body[pos], 511-pos, "^n^n\w9. Back")
   pos += format(menu_body[pos], 511-pos, "^n\w0. Exit")
   show_menu(id,keys,menu_body,-1)

   return PLUGIN_CONTINUE
}
// **************************************************************************
// END teamxp_menu subroutine
// **************************************************************************


// **************************************************************************
// BEGIN do_teamxpmenu subroutine
// Handler for the teamxp_menu for the WC3FT-Unlimited plugin
// **************************************************************************
public do_teamxpmenu(id,key){

   // [10-08-04] Added logging of amx_givexp() command - K2mia
   new name[32]
   get_user_name(id, name, 31)

   switch(key){
      case 0:{
         log_amx( "[%s] %s used Admin-Menu XP [%d] for team Terrorist", 
                  MOD, name, g_menuSettings[id] )
         server_cmd("amx_givexp @TERRORIST %d", g_menuSettings[id])
         teamxp_menu(id)
      }
      case 1:{
         log_amx( "[%s] %s used Admin-Menu XP [%d] for team CT", 
                  MOD, name, g_menuSettings[id] )
         server_cmd("amx_givexp @CT %d",g_menuSettings[id])
         teamxp_menu(id)
      }
      case 2:{
         log_amx( "[%s] %s used Admin-Menu XP [%d] for EVERYONE", 
                  MOD, name, g_menuSettings[id] )
         server_cmd("amx_givexp @ALL %d",g_menuSettings[id])
         teamxp_menu(id)
      }
      case 7:{
         ++g_menuOption[id]
         if (g_menuOption[id]>6){
            g_menuOption[id]=1
         }
         switch(g_menuOption[id]){
            case 1: g_menuSettings[id] = 50
            case 2: g_menuSettings[id] = 100
            case 3: g_menuSettings[id] = 500
            case 4: g_menuSettings[id] = 1000
            case 5: g_menuSettings[id] = 5000
            case 6: g_menuSettings[id] = 10000
         }
         teamxp_menu(id)
      }
      case 8: admin_menu(id)
      case 9: return PLUGIN_HANDLED
      default: return PLUGIN_HANDLED
   }

   return PLUGIN_HANDLED
}
// **************************************************************************
// END do_teamxpmenu subroutine
// **************************************************************************


// **************************************************************************
// BEGIN uwc3_commands subroutine
// Display the UWC3 commands list
// **************************************************************************
public uwc3_commands(id){

   if (!warcraft3)
      return PLUGIN_CONTINUE

   new temp[2048]
   new pos = 0

   pos += format(temp[pos], 2048-pos, "<body bgcolor=#000000><font color=#FFB000>")
   pos += format(temp[pos], 2048-pos, "<center><table border=1 cellpadding=3 cellspacing=3><tr><td><font color=#FFB000>")

   pos += format(temp[pos], 2048-pos, "<center><b>Ultimate Warcraft3</b><br><a href='http://www.uwc3.com/'><b>http://www.uwc3.com/</b></a></center><p>" )

   pos += format(temp[pos], 2048-pos, "<center><b>UWC3 Commands</b></center><p>" )

   pos += format(temp[pos], 2048-pos, "The following commands are available:<p>" )
   pos += format(temp[pos], 2048-pos, "say /war3menu -  Displays the UWC3 main menu <br>" )
   pos += format(temp[pos], 2048-pos, "say /help -  Displays the UWC3 help menu <br>" )
   pos += format(temp[pos], 2048-pos, "say /selectskill - Displays the skill selection menu <br>" )
   pos += format(temp[pos], 2048-pos, "say /selectattrib - Displays the attributes selection menu <br>" )
   pos += format(temp[pos], 2048-pos, "say /selectresist - Displays the resistances selection menu <br>" )
   pos += format(temp[pos], 2048-pos, "say /charactersheet - (also /charsheet) Displays your complete character summary (skills, attributes, resists, etc) <br>" )
   pos += format(temp[pos], 2048-pos, "say /who -  Displays a list of players on the server<br>" )
   pos += format(temp[pos], 2048-pos, "say /whois player_name - Displays the character sheet for the specified player<br>" )
   pos += format(temp[pos], 2048-pos, "say /skillsinfo - Displays information about each skill <br>" )
   pos += format(temp[pos], 2048-pos, "say /resetskills - Resets your skills so you can retrain them <br>" )
   pos += format(temp[pos], 2048-pos, "say /resetattribs - Resets your attributes so you can retrain them <br>" )
   pos += format(temp[pos], 2048-pos, "say /resetresists - Resets your resistances so you can retrain them <br>" )
   pos += format(temp[pos], 2048-pos, "say /deletexp - Deletes all of your XP and skill points <br>" )
   pos += format(temp[pos], 2048-pos, "say /itemsinfo - Displays the list of items in the shopmenu <br>" )
   pos += format(temp[pos], 2048-pos, "say /itemsinfo2 - Displays the list of items in the shopmenu2 <br>" )
   pos += format(temp[pos], 2048-pos, "say /level - Displays your rank and level<br>" )
   pos += format(temp[pos], 2048-pos, "say /toggle_lowres - Toggles the position of ultimate/shopitems HUD messages<br>" )
   pos += format(temp[pos], 2048-pos, "In console: xp_table - Displays the XP/Level table for this server<br>" )

   pos += format(temp[pos], 2048-pos, "</font></td></tr></table></center>")

   show_motd( id, temp, "UWC3 Commands")

   return PLUGIN_CONTINUE

}
// **************************************************************************
// END uwc3_commands subroutine
// **************************************************************************


// **************************************************************************
// BEGIN uwc3_credits subroutine
// Display the credits for UWC3 plugin
// **************************************************************************
public uwc3_credits(id){
      
   if (warcraft3==false)
      return PLUGIN_CONTINUE
   
   new temp[3072]
   new pos = 0
   
   pos += format(temp[pos], 3072-pos, "<body bgcolor=#000000><font color=#FFB000>")
   pos += format(temp[pos], 3072-pos, "<center><table border=1 cellpadding=3 cellspacing=3><tr><td><font color=#FFB000>")

   pos += format(temp[pos], 3072-pos, "<center><b>Ultimate Warcraft3</b><br><a href='http://www.uwc3.com/'><b>http://www.uwc3.com/</b></a></center><p>" )

   pos += format(temp[pos], 3072-pos, "Ultimate Warcraft3 (UWC3) [%s] Dev Team:<ul><li>K2mia (admin@mudconnect.com) - Small Coding<li>Jim Rhoade (jim@radzone.org) - UWC3 Website<li>steve french (garbageweed@hotmail.com) - Graphic effects</ul><p>", VER)
   pos += format(temp[pos], 3072-pos, "str_break() routine provided by BAILOPAN from AMXX0.20 to replace parse()<br>" )
   pos += format(temp[pos], 3072-pos, "ultimate_decoy() code derived from code for Beyonder superhero (Freecode/Asskicr)<br>some decoy concepts from AMXX forums posts by jjkiller<br>" )
   pos += format(temp[pos], 3072-pos, "Additional Credits: Kamikaze (beta server/bug reporting), Jatsu (beta server/bug reporting),<br>NeKo (Grenade trails code from War3FT)<br>")
   pos += format(temp[pos], 3072-pos, "UWC3 testing: Skat, Burning Angel, k-os (skill tests)<br>")
   pos += format(temp[pos], 3072-pos, "Exploding Bannana, [Cas]Williamz, Spitfire, Hades, Veritas (bug reports)<br>")
   pos += format(temp[pos], 3072-pos, "Thanks to: SpaceDude, Pimp-Daddy, BAILOPAN, PM, AssKicr<br>jjkiller and the members of amxmodx.org forums<br>")
   pos += format(temp[pos], 3072-pos, "bigboom for the 'fullupdate' bug report.<br>")
   pos += format(temp[pos], 3072-pos, "</font></td></tr><tr><td><font color=#FFB000>")
   pos += format(temp[pos], 3072-pos, "<center><b>Warcraft3 and Warcraft3FT Credits</b></center><p>" ) 
   pos += format(temp[pos], 3072-pos, "Warcraft 3: Frozen Throne by Pimp Daddy (OoTOAoO)<br>[ email: PimpDaddy@cinci.rr.com / MSN: PimpDaddy@cinci.rr.com ]<p>")
   pos += format(temp[pos], 3072-pos, "Spacedude (for War3 MOD)<br>Ludwig Van (for flamethrower)<br>OLO (for spectating rank info)<br>JGHG for the mole code<br>[AOL]Demandred, [AOL]LuckyJ for help coding it for steam<br>[AOL]Demandred for freezetime exploit fix<br>")
   pos += format(temp[pos], 3072-pos, "Denkkar for some of his code (ie. STEAM_POWERED)<br>Everyone at amxmod.net for help<br>joecool12321 for various health related fixes<br>Tri Moon for various improvements (No Race, war3menu, etc...)<br>xeroblood for spotting some bugs for me :)<br>bad-at-this for contributing the status bar code used for godmode (big bad voodoo)<br>")
   pos += format(temp[pos], 3072-pos, "kamikaze for help w/testing version before release<br>lui for the delayed ultimate code<br>The following people helped convert the text to German:<br>Walken / Altegarde.com , Fire , ^^plan.los^^<br>")
   pos += format(temp[pos], 3072-pos, "</font></td></tr></table></center>")
   
   show_motd( id, temp, "Ultimate Warcraft3 Credits")
   
   return PLUGIN_CONTINUE

}
// **************************************************************************
// END uwc3_credits subroutine
// **************************************************************************



// **************************************************************************
// BEGIN war3_info subroutine
// Display the help info for the WC3FT-Unlimited plugin
// **************************************************************************
public war3_info(id){
   
   if (warcraft3==false)
      return PLUGIN_CONTINUE
   
   new temp[2048]
   new pos = 0
   
   pos += format(temp[pos], 2048-pos, "<body bgcolor=#000000><font color=#FFB000>")
   pos += format(temp[pos], 2048-pos, "<center><table border=1 cellpadding=3 cellspacing=3><tr><td><font color=#FFB000>")

   pos += format(temp[pos], 2048-pos, "<center><b>Ultimate Warcraft3</b><br><a href='http://www.uwc3.com/'><b>http://www.uwc3.com/</b></a></center><p>" )

   pos += format(temp[pos], 2048-pos, "Ultimate Warcraft3 %s created by K2mia (admin@mudconnect.com). Ultimate Warcraft3 (UWC3) is more or less a raceless, skill-based implementation of the Warcraft3 Frozen Throne plugin. Additional skills, items, etc are planned.<p>", VER )
   pos += format(temp[pos], 2048-pos, "This mod is a derived work based on Warcraft3 Frozen Thrones, developed by 4HM | Pimp Daddy, visit www.4hm.net (forums) for more details.<br><p>")
   pos += format(temp[pos], 2048-pos, "This is how you bind a key:<p>")
   pos += format(temp[pos], 2048-pos, "1) Type ` to get to the console (key to the left of number 1)<br>" )
   pos += format(temp[pos], 2048-pos, "2) Type bind - shopmenu  (displays shopmenu1)<br>" )
   pos += format(temp[pos], 2048-pos, "3) Type bind = shopmenu2 (displays shopmenu2)<br>" )
   pos += format(temp[pos], 2048-pos, "4) Type bind p wcward (to use the serpant ward ability)<p>" )
   pos += format(temp[pos], 2048-pos, "UWC3 allows you to have up to 3 ultimate skills as opposed to just one from the original Warcraft3. In the skills menu (/selectskill) ultimate skills will say (Ultimate: name), for example for the Teleport ultimate it says (Ultimate: wcteleport). Once you learn this skill you can use it by binding a key to the wcteleport command, done by typing: bind key wcteleport in the console.<p>" )
   pos += format(temp[pos], 2048-pos, "Say <b>/commands</b> to see the list of UWC3 spoken commands and say <b>/help</b> for the UWC3 help menu.<p>" )
   pos += format(temp[pos], 2048-pos, "</font></td></tr></table></center>")

   show_motd( id, temp, "Ultimate WC3FT Player Help")

   return PLUGIN_CONTINUE

}
// **************************************************************************
// END war3_info subroutine
// **************************************************************************


// **************************************************************************
// BEGIN uwc3_tips subroutine
// Display the UWC3 tips page
// **************************************************************************
public uwc3_tips(id){
   if (!warcraft3)
      return PLUGIN_CONTINUE

   new temp[2048]
   new pos = 0

   pos += format(temp[pos], 2048-pos, "<body bgcolor=#000000><font color=#FFB000>")
   pos += format(temp[pos], 2048-pos, "<table border=0><tr><td><font color=#FFB000>")

   pos += format(temp[pos], 2048-pos, "<center><b>Ultimate Warcraft3</b><br><a href='http://www.uwc3.com/'><b>http://www.uwc3.com/</b></a></center><p>" )

   pos += format(temp[pos], 2048-pos, "<b>Tips for Playing UWC3</b><p>")
   pos += format(temp[pos], 2048-pos, "This is not the Warcraft3 plugin you are used to, the favorite race you want to play isn't here, but all your favorite skills and abiltiies are, plus many more. The following are some helpful tips for players new to WC3 and veterans of WC3 alike.<p>")
   pos += format(temp[pos], 2048-pos, "<li>There is no race menu, all skills are available via the skillsmenu by saying <b>/selectskill</b> <p>")
   pos += format(temp[pos], 2048-pos, "<li>Each page of skills has a corresponding page with info about each skills listed, page 1 skills info is accessed by saying <b>/skillsinfo1</b>, ... page 5 skills are accessed by saying <b>/skillsinfo5</b> <p>")
   pos += format(temp[pos], 2048-pos, "<li>In Ultimate Warcraft3 you gain levels and skills by earning experience. You earn experience by killing your enemies or seriously injuring them (assisting a teammate in killing), performing game objectives like planting the bomb or rescuring hostages, and other skill based methods such as healing your teamates or repairing their armor.<p>")
   pos += format(temp[pos], 2048-pos, "<li>Ultimate skills in UWC3 each have a unique command to bind to a key, the skillsmenu (/selectskill) displays these commands next to Ultimate skills. <p>")
   pos += format(temp[pos], 2048-pos, "</td></tr></table>")

   show_motd( id, temp, "UWC3 Tips")

   return PLUGIN_HANDLED
}
// **************************************************************************
// END uwc3_tips subroutine
// **************************************************************************


// **************************************************************************
// BEGIN uwc3_tips2 subroutine
// Display the UWC3 tips page 2
// **************************************************************************
public uwc3_tips2(id){
   if (!warcraft3)
      return PLUGIN_CONTINUE

   new temp[2048]
   new pos = 0

   pos += format(temp[pos], 2048-pos, "<body bgcolor=#000000><font color=#FFB000>")
   pos += format(temp[pos], 2048-pos, "<table border=0><tr><td><font color=#FFB000>")

   pos += format(temp[pos], 2048-pos, "<center><b>Ultimate Warcraft3</b><br><a href='http://www.uwc3.com/'><b>http://www.uwc3.com/</b></a></center><p>" )

   pos += format(temp[pos], 2048-pos, "<b>Tips for Playing UWC3 -page 2</b><p>")
   pos += format(temp[pos], 2048-pos, "<li>Abilities are also bound like Ultimates in UWC3 and their commands are also displayed next to their skill name in the menu<p>")
   pos += format(temp[pos], 2048-pos, "<li>There are 2 shops in UWC3 where magical items can be bought, these range from items that increase your speed or attack abilities to some that will disguise you like the enemy or allow you to spawn in the enemy camp at the start of a round. More information is available by saying <b>/itemsinfo</b> and <b>/itemsinfo2</b>. <p>")
   pos += format(temp[pos], 2048-pos, "<li>One <b>VERY</b> important item in the shop that should always be bought when money allows is the <b>Necklace of Immunity</b>. The necklace will protect you from all Ultimate skill effects as well as some other nasty skills such as Napalm Grenades or Serpant Wards. If money is tight I will generally purchase a Necklace in place of Armor, but thats just me. :)<p>")
   pos += format(temp[pos], 2048-pos, "<li>One skill that is new to UWC3 is called Mend Wounds and beside being useful to your team by allowing you to heal damage, cure poison and ease burns, it also provides a reliable source of earning experience. <p>")
   pos += format(temp[pos], 2048-pos, "<li>You can reset your current skills by saying <b>/resetskills</b> - at the start of the next round your points will be returned and you may retrain a new set of skills. If by slim chance you ever want to delete your skills and XP you can do so with <b>/deletexp</b><p>")
   pos += format(temp[pos], 2048-pos, "<li>UWC3 now offers a complete line of player Attributes and Resistances you can train along with your skills. Complete information about Attributes, Resistances and Enhancement XP is available at our website -- <b>http://www.mudconnect.com/uwc3/enhancements.html</b><p>")
   pos += format(temp[pos], 2048-pos, "</td></tr></table>")

   show_motd( id, temp, "UWC3 Tips pg. 2")

   return PLUGIN_HANDLED
}
// **************************************************************************
// END uwc3_tips2 subroutine
// **************************************************************************


// **************************************************************************
// BEGIN uwc3_ultimates subroutine
// Display the info about ultimates in UWC3 plugin
// **************************************************************************
public uwc3_ultimates(id){
   if (warcraft3==false)
      return PLUGIN_CONTINUE

   new temp[3072]
   new pos = 0

   pos += format(temp[pos], 3072-pos, "<body bgcolor=#000000><font color=#FFB000>")
   pos += format(temp[pos], 3072-pos, "<table border=0><tr><td><font color=#FFB000>")

   pos += format(temp[pos], 3072-pos, "<center><b>Ultimate Warcraft3</b><br><a href='http://www.uwc3.com/'><b>http://www.uwc3.com/</b></a></center><p>" )

   pos += format(temp[pos], 3072-pos, "<b>Important Information About UWC3 Ultimates</b><p>")
   pos += format(temp[pos], 3072-pos, "Unlike previous versions of the Warcraft3 and Warcraft Frozen Throne plugins,<br>Ultimate Warcraft3 allows players to train in up to 3 ultimate skills.<p>")
   pos += format(temp[pos], 3072-pos, "In order to make use of the ultimate skills in UWC3 you will need<br>to bind a key for each ultimate and each ultimate has a unique command to be bound. Special abilities are also handled the same way in UWC3. <p>")
   pos += format(temp[pos], 3072-pos, "<table border=1 cellpadding=4 cellspacing=4><tr><th><font color=#FFB000>Ultimate or Ability</th><th><font color=#FFB000>Bind Command</th></tr>")
   pos += format(temp[pos], 3072-pos, "<tr><td><font color=#FFB000>Suicide Bomber</td><td><font color=#FFB000>bind key wcsuicide</td></tr>")
   pos += format(temp[pos], 3072-pos, "<tr><td><font color=#FFB000>Teleport</td><td><font color=#FFB000>bind key wcteleport</td></tr>")
   pos += format(temp[pos], 3072-pos, "<tr><td><font color=#FFB000>Chain Lightning</td><td><font color=#FFB000>bind key wclightning</td></tr>")
   pos += format(temp[pos], 3072-pos, "<tr><td><font color=#FFB000>Entangle Roots</td><td><font color=#FFB000>bind key wcentangle</td></tr>")
   pos += format(temp[pos], 3072-pos, "<tr><td><font color=#FFB000>Flame Strike</td><td><font color=#FFB000>bind key wcflame</td></tr>")
   pos += format(temp[pos], 3072-pos, "<tr><td><font color=#FFB000>Big Bad Voodoo</td><td><font color=#FFB000>bind key wcvoodoo</td></tr>")
   pos += format(temp[pos], 3072-pos, "<tr><td><font color=#FFB000>Vengeance</td><td><font color=#FFB000>Passive Ability</td></tr>")
   pos += format(temp[pos], 3072-pos, "<tr><td><font color=#FFB000>Locust Swarm</td><td><font color=#FFB000>bind key wclocust</td></tr>")
   pos += format(temp[pos], 3072-pos, "<tr><td><font color=#FFB000>Flash of Light</td><td><font color=#FFB000>bind key wcflash</td></tr>")
   pos += format(temp[pos], 3072-pos, "<tr><td><font color=#FFB000>Decoy</td><td><font color=#FFB000>bind key wcdecoy</td></tr>")
   pos += format(temp[pos], 3072-pos, "<tr><td><font color=#FFB000>Gate</td><td><font color=#FFB000>bind key wcgate</td></tr>")
   pos += format(temp[pos], 3072-pos, "<tr><td><font color=#FFB000>Ability: Mend Wounds</td><td><font color=#FFB000>bind key wcmend</td></tr>")
   pos += format(temp[pos], 3072-pos, "<tr><td><font color=#FFB000>Ability: Repair Armor</td><td><font color=#FFB000>bind key wcrepair</td></tr>")
   pos += format(temp[pos], 3072-pos, "<tr><td><font color=#FFB000>Ability: Serpant Ward</td><td><font color=#FFB000>bind key wcward</td></tr>")
   pos += format(temp[pos], 3072-pos, "</td></tr></table>")

   show_motd( id, temp, "UWC3 Ultimates")

   return PLUGIN_CONTINUE
}
// **************************************************************************
// END uwc3_ultimates subroutine
// **************************************************************************


// **************************************************************************
// BEGIN uwc3_attributes subroutine
// Display the UWC3 Attributes Information page
// **************************************************************************
public uwc3_attributes(id){
   if (!warcraft3)
      return PLUGIN_CONTINUE

   new temp[2048]
   new pos = 0

   pos += format(temp[pos], 2048-pos, "<body bgcolor=#000000><font color=#FFB000>")
   pos += format(temp[pos], 2048-pos, "<b>Attributes Information</b><p>")

   pos += format(temp[pos], 2048-pos, "<p>UWC3 provides, in addition to the normal XP system, a new enhancement XP system (E-XP) which allows you to earn Attribute points to spend building your character. These attributes are as follows:</p><ol>")

   pos += format(temp[pos], 2048-pos, "<li><b>Strength</b> - Determines your starting base health, stacks with Devotion Aura <p>")

   pos += format(temp[pos], 2048-pos, "<li><b>Intellect</b> - Each level of intellect you enhance from 11 - 18 provides a different benefit, check the website for complete details (http://www.mudconnect.com/uwc3/enhancements.html) <p> ")

   pos += format(temp[pos], 2048-pos, "<li><b>Dexterity</b> - Helps to successfully Evade shots for characters trained in Evasion <p> ")

   pos += format(temp[pos], 2048-pos, "<li><b>Agility</b> - Determines your base runspeed, stacks with Unholy Aura <p> ")

   pos += format(temp[pos], 2048-pos, "<li><b>Constitution</b> - Provides health regeneration which stacks with Healing Wave ")

   show_motd( id, temp, "Attributes Information")

   return PLUGIN_HANDLED
}
// **************************************************************************
// END uwc3_attributes subroutine
// **************************************************************************


// **************************************************************************
// BEGIN uwc3_resistances subroutine
// Display the UWC3 Resistances Information page
// **************************************************************************
public uwc3_resistances(id){
   if (!warcraft3)
      return PLUGIN_CONTINUE

   new temp[2048]
   new pos = 0

   pos += format(temp[pos], 2048-pos, "<body bgcolor=#000000><font color=#FFB000>")
   pos += format(temp[pos], 2048-pos, "<b>Resistances Information</b><p>")

   pos += format(temp[pos], 2048-pos, "<p>UWC3 provides, in addition to the normal XP system, a new enhancement XP system (E-XP) which allows you to earn Resistance points to spend building a defense system for your character. Each resistance can be trained to 100 points at which time you should be totally covered from the specified damage type. These resistances are as follows:</p><ol>")

   pos += format(temp[pos], 2048-pos, "<li><b>Poison</b> -  protection against Shadow Strike poison-based attacks <p>")

   pos += format(temp[pos], 2048-pos, "<li><b>Disease</b> -  protection against Carrion Beetles and Locust Swarm disease-based attacks <p>")

   pos += format(temp[pos], 2048-pos, "<li><b>Electricity</b> -  protection against Chain Lightning attacks <p>")

   pos += format(temp[pos], 2048-pos, "<li><b>Fire</b> - protection against Flamethrower and Napalm Grenade fire-based attacks <p>")

   pos += format(temp[pos], 2048-pos, "<li><b>Magic</b> - Similar to a Necklace of Immunity with some exceptions made to attacks covered by other resistance types.<p>")


   show_motd( id, temp, "Resistances Information")

   return PLUGIN_HANDLED
}
// **************************************************************************
// END uwc3_resistances subroutine
// **************************************************************************


// **************************************************************************
// BEGIN character_sheet subroutine
// Display a player's character sheet
// **************************************************************************
public character_sheet(id){

   new name[32]
   new message[2048] = ""
   new temp[1024] = ""
   new stemp[1024] = ""
   new temp2[64] = ""
   new sname[64] = ""
   new bool:bHasASkill = false
   new j = 0

   get_user_name(id, name, 31)


   new skillptsavail = get_availskillpts( id )	// Count # skillpts unspent

   new apts = get_availattribpts( id )	// Get the # available attrib pts
   new rpts = get_availresistpts( id )	// Get the # available resist pts


   // Calculate how many attrib/resist points can be spent
   new extra_xp = (playerxp[id] - xplevel_lev[enh_minlevel])
   if (extra_xp < 0) extra_xp = 0
   new exp = (extra_xp / 10)


   add( message, 2047, "<body bgcolor=#000000><font color=#FFB000>" )
   format( stemp, 1024, "<center><b>Character Sheet: %s</b></center><p>", name )
   add( message, 2047, stemp )
   add( message, 2047, "<center><table width=800 border=1 cellpadding=4 cellspacing=4>" )

   add( message, 2047, "<tr><td valign=top width=50%><font color=#FFB000>" )

   format( stemp, 1024, "Player Name: %s <br>", name )
   add( message, 2047, stemp )
   format( stemp, 1024, "Player Level: %d <br>", p_level[id] )
   add( message, 2047, stemp )
   format( stemp, 1024, "Player Rank: %s <br>", p_rank[id] )
   add( message, 2047, stemp )
   format( stemp, 1024, "Skillpts Available: %d <br>", skillptsavail )
   add( message, 2047, stemp )

   add( message, 2047, "</td><td valign=top width=50%><font color=#FFB000>" )

   if (p_level[id] == (MAX_LEVEL-1)){
      format( stemp, 1024, "Player XP: %d <br>", playerxp[id] )
   }else{
      format( stemp, 1024, "Player XP: %d / %d <br>",
         playerxp[id], xplevel_lev[p_level[id]+1] )
   }
   add( message, 2047, stemp )

   if (p_level[id] == (MAX_LEVEL-1)){
      add( message, 2047, "XP Needed: NA <br>" )
   }else{
      format( stemp, 1024, "XP Needed: %d <br>",
         (xplevel_lev[p_level[id]+1] - playerxp[id]) )
      add( message, 2047, stemp )
   }

   format( stemp, 1024, "Enhancement XP: %d <br>", exp )
   add( message, 2047, stemp )
   format( stemp, 1024, "Attribute Pts Available: %d <br>", apts )
   add( message, 2047, stemp )
   format( stemp, 1024, "Resistance Pts Available: %d <br>", rpts )
   add( message, 2047, stemp )

   add( message, 2047, "</td></tr><tr><td valign=top><font color=#FFB000>" )
   add( message, 2047, "<center><b>Attributes</b></center><p>" )
   format( stemp, 1024, "Strength: %d / %d <br>",
      p_attribs[id][ATTRIBIDX_STR], ATTRIB_MAX_VALUE )
   add( message, 2047, stemp )
   format( stemp, 1024, "Intellect: %d / %d <br>",
      p_attribs[id][ATTRIBIDX_INT], ATTRIB_MAX_VALUE )
   add( message, 2047, stemp )
   format( stemp, 1024, "Dexterity: %d / %d <br>",
      p_attribs[id][ATTRIBIDX_DEX], ATTRIB_MAX_VALUE )
   add( message, 2047, stemp )
   format( stemp, 1024, "Agility: %d / %d <br>",
      p_attribs[id][ATTRIBIDX_AGI], ATTRIB_MAX_VALUE )
   add( message, 2047, stemp )
   format( stemp, 1024, "Constitution: %d / %d <br>",
      p_attribs[id][ATTRIBIDX_CON], ATTRIB_MAX_VALUE )
   add( message, 2047, stemp )

   add( message, 2047, "</td><td valign=top><font color=#FFB000>" )
   add( message, 2047, "<center><b>Resistances</b></center><p>" )

   format( stemp, 1024, "Poison Resistance: %d / %d <br>",
      p_resists[id][RESISTIDX_POISON], RESIST_MAX_VALUE )
   add( message, 2047, stemp )
   format( stemp, 1024, "Disease Resistance: %d / %d <br>",
      p_resists[id][RESISTIDX_DISEASE], RESIST_MAX_VALUE )
   add( message, 2047, stemp )
   format( stemp, 1024, "Electricity Resistance: %d / %d <br>",
      p_resists[id][RESISTIDX_ELECTRIC], RESIST_MAX_VALUE )
   add( message, 2047, stemp )
   format( stemp, 1024, "Fire Resistance: %d / %d <br>",
      p_resists[id][RESISTIDX_FIRE], RESIST_MAX_VALUE )
   add( message, 2047, stemp )
   format( stemp, 1024, "Magic Resistance: %d / %d <br>",
      p_resists[id][RESISTIDX_MAGIC], RESIST_MAX_VALUE )
   add( message, 2047, stemp )


   add( message, 2047, "</td></tr><tr><td colspan=2 valign=top><font color=#FFB000>" )
   add( message, 2047, "<center><b>Skills Trained</b></center><p>" )

   for (j=1; j<MAX_SKILLS;j++){
      if (j <= 8) copy(sname, 31, skillset1[j])
      else if (j <= 16) copy(sname, 31, skillset2[j-8])
      else if (j <= 24) copy(sname, 31, skillset3[j-16])
      else if (j <= 32) copy(sname, 31, skillset4[j-24])
      else if (j <= 40) copy(sname, 31, skillset5[j-32])

      if (p_skills[id][j]){
         bHasASkill = true
         new mstr[32] = ""
         if ((p_skills[id][j] == skill_limits[j]) && (skill_limits[j] > 1))
            copy(mstr, 31, "(Master)")

         format(temp2,64,"%s [level %d] %s <br>",  sname, p_skills[id][j], mstr  )
         add(temp,1024,temp2)
      }
   }

   if (!bHasASkill){
      add(temp,1024, "No skills trained")
   }

   add( message, 2048, temp )
   add( message, 2048, "</td></tr>" )

   add( message,2048,"</table></center>" )

   show_motd( id, message, "Your Character Sheet")


}
// **************************************************************************
// END character_sheet subroutine
// **************************************************************************


// **************************************************************************
// BEGIN cmd_whois subroutine
// Display a specified player's character sheet to another player
// **************************************************************************
public cmd_whois(id, arg[]){

   new name[32]
   new message[2048] = ""
   new temp[1024] = ""
   new stemp[1024] = ""
   new temp2[64] = ""
   new sname[64] = ""
   new bool:bHasASkill = false
   new j = 0

   new pid = cmd_target(id, arg, 0)

   if (!pid){
      client_print(id, print_chat, "[%s] Could not find a matching player [%s]", MOD, arg)
      return PLUGIN_HANDLED
   }

   get_user_name(pid, name, 31)

   new skillptsavail = get_availskillpts( pid ) // Count # skillpts unspent

   new apts = get_availattribpts( pid ) // Get the # available attrib pts
   new rpts = get_availresistpts( pid ) // Get the # available resist pts


   // Calculate how many attrib/resist points can be spent
   new extra_xp = (playerxp[pid] - xplevel_lev[enh_minlevel])
   if (extra_xp < 0) extra_xp = 0
   new exp = (extra_xp / 10)

   add( message, 2047, "<body bgcolor=#000000><font color=#FFB000>" )
   format( stemp, 1024, "<center><b>Character Sheet: %s</b></center><p>", name )
   add( message, 2047, stemp )
   add( message, 2047, "<center><table width=800 border=1 cellpadding=4 cellspacing=4>" )

   add( message, 2047, "<tr><td valign=top width=50%><font color=#FFB000>" )

   format( stemp, 1024, "Player Name: %s <br>", name )
   add( message, 2047, stemp )
   format( stemp, 1024, "Player Level: %d <br>", p_level[pid] )
   add( message, 2047, stemp )
   format( stemp, 1024, "Player Rank: %s <br>", p_rank[pid] )
   add( message, 2047, stemp )
   format( stemp, 1024, "Skillpts Available: %d <br>", skillptsavail )
   add( message, 2047, stemp )

   add( message, 2047, "</td><td valign=top width=50%><font color=#FFB000>" )

   if (p_level[pid] == (MAX_LEVEL-1)){
      format( stemp, 1024, "Player XP: %d <br>", playerxp[pid] )
   }else{
      format( stemp, 1024, "Player XP: %d / %d <br>",
         playerxp[pid], xplevel_lev[p_level[pid]+1] )
   }
   add( message, 2047, stemp )

   if (p_level[pid] == (MAX_LEVEL-1)){
      add( message, 2047, "XP Needed: NA <br>" )
   }else{
      format( stemp, 1024, "XP Needed: %d <br>",
         (xplevel_lev[p_level[pid]+1] - playerxp[pid]) )
      add( message, 2047, stemp )
   }

   format( stemp, 1024, "Enhancement XP: %d <br>", exp )
   add( message, 2047, stemp )
   format( stemp, 1024, "Attribute Pts Available: %d <br>", apts )
   add( message, 2047, stemp )
   format( stemp, 1024, "Resistance Pts Available: %d <br>", rpts )
   add( message, 2047, stemp )

   add( message, 2047, "</td></tr><tr><td valign=top><font color=#FFB000>" )
   add( message, 2047, "<center><b>Attributes</b></center><p>" )
   format( stemp, 1024, "Strength: %d / %d <br>",
      p_attribs[pid][ATTRIBIDX_STR], ATTRIB_MAX_VALUE )
   add( message, 2047, stemp )
   format( stemp, 1024, "Intellect: %d / %d <br>",
      p_attribs[pid][ATTRIBIDX_INT], ATTRIB_MAX_VALUE )
   add( message, 2047, stemp )
   format( stemp, 1024, "Dexterity: %d / %d <br>",
      p_attribs[pid][ATTRIBIDX_DEX], ATTRIB_MAX_VALUE )
   add( message, 2047, stemp )
   format( stemp, 1024, "Agility: %d / %d <br>",
      p_attribs[pid][ATTRIBIDX_AGI], ATTRIB_MAX_VALUE )
   add( message, 2047, stemp )
   format( stemp, 1024, "Constitution: %d / %d <br>",
      p_attribs[pid][ATTRIBIDX_CON], ATTRIB_MAX_VALUE )
   add( message, 2047, stemp )

   add( message, 2047, "</td><td valign=top><font color=#FFB000>" )
   add( message, 2047, "<center><b>Resistances</b></center><p>" )

   format( stemp, 1024, "Poison Resistance: %d / %d <br>",
      p_resists[pid][RESISTIDX_POISON], RESIST_MAX_VALUE )
   add( message, 2047, stemp )
   format( stemp, 1024, "Disease Resistance: %d / %d <br>",
      p_resists[pid][RESISTIDX_DISEASE], RESIST_MAX_VALUE )
   add( message, 2047, stemp )
   format( stemp, 1024, "Electricity Resistance: %d / %d <br>",
      p_resists[pid][RESISTIDX_ELECTRIC], RESIST_MAX_VALUE )
   add( message, 2047, stemp )
   format( stemp, 1024, "Fire Resistance: %d / %d <br>",
      p_resists[pid][RESISTIDX_FIRE], RESIST_MAX_VALUE )
   add( message, 2047, stemp )
   format( stemp, 1024, "Magic Resistance: %d / %d <br>",
      p_resists[pid][RESISTIDX_MAGIC], RESIST_MAX_VALUE )
   add( message, 2047, stemp )

   add( message, 2047, "</td></tr><tr><td colspan=2 valign=top><font color=#FFB000>" )
   add( message, 2047, "<center><b>Skills Trained</b></center><p>" )

   for (j=1; j<MAX_SKILLS;j++){
      if (j <= 8) copy(sname, 31, skillset1[j])
      else if (j <= 16) copy(sname, 31, skillset2[j-8])
      else if (j <= 24) copy(sname, 31, skillset3[j-16])
      else if (j <= 32) copy(sname, 31, skillset4[j-24])
      else if (j <= 40) copy(sname, 31, skillset5[j-32])

      if (p_skills[pid][j]){
         bHasASkill = true
         new mstr[32] = ""
         if ((p_skills[pid][j] == skill_limits[j]) && (skill_limits[j] > 1))
            copy(mstr, 31, "(Master)")

         format(temp2,64,"%s [level %d] %s <br>",  sname, p_skills[pid][j], mstr  )
         add(temp,1024,temp2)
      }
   }

   if (!bHasASkill){
      add(temp,1024, "No skills trained")
   }

   add( message, 2048, temp )
   add( message, 2048, "</td></tr>" )

   add( message,2048,"</table></center>" )

   new mtitle[64]
   format( mtitle, 64, "Character Sheet for %s", name )
   show_motd( id, message, mtitle )

   return PLUGIN_HANDLED
}
// **************************************************************************
// END cmd_whois subroutine
// **************************************************************************


// **************************************************************************
// BEGIN set_rankstring subroutine
// Set the player's rank string
// **************************************************************************
public set_rankstring(id){

   p_rank[id] = ""

   // Set the player's rank title
   if ( p_level[id] >= RANK11_LEVEL )
      copy(p_rank[id], 18, ranktitles[10])
   else if ( p_level[id] >= RANK10_LEVEL )
      copy(p_rank[id], 18, ranktitles[9])
   else if ( p_level[id] >= RANK9_LEVEL )
      copy(p_rank[id], 18, ranktitles[8])
   else if ( p_level[id] >= RANK8_LEVEL )
      copy(p_rank[id], 18, ranktitles[7])
   else if ( p_level[id] >= RANK7_LEVEL )
      copy(p_rank[id], 18, ranktitles[6])
   else if ( p_level[id] >= RANK6_LEVEL )
      copy(p_rank[id], 18, ranktitles[5])
   else if ( p_level[id] >= RANK5_LEVEL )
      copy(p_rank[id], 18, ranktitles[4])
   else if ( p_level[id] >= RANK4_LEVEL )
      copy(p_rank[id], 18, ranktitles[3])
   else if ( p_level[id] >= RANK3_LEVEL )
      copy(p_rank[id], 18, ranktitles[2])
   else if ( p_level[id] >= RANK2_LEVEL )
      copy(p_rank[id], 18, ranktitles[1])
   else
      copy(p_rank[id], 18, ranktitles[0])

   return PLUGIN_CONTINUE

}
// **************************************************************************
// END set_rankstring subroutine
// **************************************************************************


// **************************************************************************
// BEGIN displaylevel subroutine
// Calculate and display a player's level
// **************************************************************************
public displaylevel(id,hide){
   if ( !id || !is_user_connected(id) )
      return PLUGIN_CONTINUE
   
   new parm2[2]
   parm2[0] = id
   if (!itemsrunning[id] && !endround)
      items(parm2)

   new bool:bLvled = false
   new skillptsavail = 0
   new addskillmesg = 0
   new xpstring[511] = ""
   new name[32]
   get_user_name(id, name, 31)


   if (playerxp[id] < 0)
      playerxp[id]=0

   if ((p_level[id] < (MAX_LEVEL-1)) && (playerxp[id] >= xplevel_lev[p_level[id]+1])){
      for (new i=(p_level[id]+1); i<MAX_LEVEL; ++i){
         if (playerxp[id] >= xplevel_lev[i]){
            // Level Gain
            bLvled = true
            p_level[id]=i
            //client_print(id, print_console, "New level: %d pxp=(%d) xplev=(%d)",
            //   p_level[id], playerxp[id], xplevel_lev[i])
         }
      }
   }

   set_rankstring( id )		// Set the player's rank string


   //client_print(id, print_console, "[%s DEBUG] Rank: %s <%d> XP: (%d / %d)",
   //   MOD, p_rank[id], p_level[id], playerxp[id], xplevel)


   if (hide != 3){
      // [08-06-04] - Now checks/displays attrib/resist pts avail before skills - K2mia
      // hide != 3 specifies available attrib/resist/skill pts can be displayed

      new acount = get_attribcount( id )
      new apts = get_availattribpts( id )
      new rcount = get_resistcount( id )
      new rpts = get_availresistpts( id )

      if ( (apts > 0) && (acount < ((MAX_ATTRIBS-1) * (ATTRIB_MAX_VALUE-ATTRIB_BASE))) &&
           (acount < ATTRIB_MAX_PTS) )
      {
         // Display attribpts available message
         set_hudmessage(200, 100, 0, 0.35, -1.00, 0, 1.0, 5.0, 0.1, 0.2, 2)
         show_hudmessage(id,
            "You have %d attribute points available (use /selectattrib)", apts)
      }else if ( (rpts > 0) && (rcount < ((MAX_RESISTS-1) * RESIST_MAX_VALUE)) &&
                 (rcount < RESIST_MAX_PTS) )
      {
         // Display resistpts available message
         set_hudmessage(200, 100, 0, 0.35, -1.00, 0, 1.0, 5.0, 0.1, 0.2, 2)
         show_hudmessage(id,
            "You have %d resistance points available (use /selectresist)", rpts)
      }else{
         // Determine if player has skills that can be learned
         skillptsavail = get_availskillpts( id )

         if (skillptsavail){
            addskillmesg = 1

            // Display skillpts available message
            set_hudmessage(200, 100, 0, 0.35, -1.00, 0, 1.0, 5.0, 0.1, 0.2, 2)
            show_hudmessage(id,
               "You have %d skillpoints available (use /selectskill)", skillptsavail)
         }
      }
   }


   if(get_cvar_num("FT_items_in_hud")){
      if(playeritem2[id]==0){
         format(xpstring,511,"Rank: %s [%d]   XP: %d",
            p_rank[id], p_level[id], playerxp[id])
      }else{
         format(xpstring,511,"Rank: %s [%d]   XP: %d",
            p_rank[id], p_level[id], playerxp[id])
      }
   }else{
      new temp2[128] = ""
      new temp3[128] = ""

      if (addskillmesg)
         format(temp3, 127, "[%d skillpts]", skillptsavail)

      format(xpstring,1023,"Rank: %s [%d]   XP: %d  %s %s", p_rank[id], p_level[id],
             playerxp[id], temp2, temp3)
   }


   message_begin( MSG_ONE, gmsgStatusText, {0,0,0}, id)
   write_byte(0)
   write_string(xpstring)
   message_end()


   if (bLvled){
      // Level Gained - Player has gained a level

      //client_print(id, print_console, "[%s DEBUG] Level Gain p_level=(%d) ",
      //   MOD, p_level[id])

      set_hudmessage(200, 100, 0, -1.0, 0.35, 0, 1.0, 7.0, 0.1, 0.2, 2)


      if (loadedlevel[id]){
         show_hudmessage(id, "Congratulations - You gained a level")
         client_print(0, print_chat,
            "[%s] Announcement ::  Congratulations %s for gaining a level", MOD, name )
      }else{
         loadedlevel[id] = 1    // Now player has initial levels loaded from saved XP
         show_hudmessage(id, "Status :: Saved XP and Levels Loaded")
      }

      if (file_exists("sound/warcraft3/levelupcaster.wav")==1 && is_user_alive(id))
         emit_sound(id,CHAN_ITEM, "warcraft3/levelupcaster.wav", 1.0, ATTN_NORM, 0, PITCH_NORM)
      else if (is_user_alive(id))
         emit_sound(id,CHAN_ITEM, "plats/elevbell1.wav", 1.0, ATTN_NORM, 0, PITCH_LOW)
   }


   if (hide!=1 && hide!=3){
      new temp[64] = ""
      new message[2048] = ""
      //new bool:bHasSkills=false

      if (p_level[id] < (MAX_LEVEL-1)){
         format(temp,64,"^n%s %s [%d] XP: %d/%d","Your Rank:",
            p_rank[id], p_level[id], playerxp[id], xplevel_lev[p_level[id]+1])
      }else{
         format(temp,64,"^n%s %s [%d] XP: %d","Your Rank:",
            p_rank[id], p_level[id], playerxp[id] )
      }
      add(message,2048,temp)

      add(message, 2048, "^n(Say /charsheet for your complete info)")

      /*
      format(temp,64,"^n%s ","Your Skills Summary: (first 20)" )
      add(message,2048,temp)

      new sname[32] = ""
      new nSkills = 0

      for (new i=1; i<MAX_SKILLS;i++){
         if (i <= 8) copy(sname, 31, skillset1[i])
         else if (i <= 16) copy(sname, 31, skillset2[i-8])
         else if (i <= 24) copy(sname, 31, skillset3[i-16])
         else if (i <= 32) copy(sname, 31, skillset4[i-24])
         else if (i <= 40) copy(sname, 31, skillset5[i-32])

         if (p_skills[id][i]){
            ++nSkills

            if (nSkills % 2 == 0){
               format(temp,64,"%s - %d ", sname, p_skills[id][i] )
               add(message,2048,temp)
            }else{
               format(temp,64,"^n%s - %d ", sname, p_skills[id][i] )
               add(message,2048,temp)
            }

            if (nSkills == 20) break
         }

      }

      if (nSkills > 0) bHasSkills = true

      if (!bHasSkills){
         format(temp,64,"^n%s ","No Skills Learned" )
         add(message,2048,temp)
      }
      */

      set_hudmessage(255, 255, 255, -1.0, 0.3, 0, 3.0, 7.0, 0.1, 0.2, 2)
      show_hudmessage(id,message)
   }

   if ( !is_user_connected( id ) )
      return PLUGIN_CONTINUE
 
   if (get_cvar_num("sv_gravity")>650){
      if (p_skills[id][SKILLIDX_LEVITATION] && playeritem2[id]!=FEATHER){
         // Levitation
         if (get_user_gravity(id)!=p_levitation[p_skills[id][SKILLIDX_LEVITATION]-1])
            set_user_gravity(id,p_levitation[p_skills[id][SKILLIDX_LEVITATION]-1])
      }else if (playeritem2[id]==FEATHER)
         set_user_gravity(id,0.35)
      else if (get_user_gravity(id)!=1.0)
         set_user_gravity(id,1.0)
   }else{
      set_user_gravity(id,1.0)
   }

   if (p_skills[id][SKILLIDX_INVIS]){
      // Invisibility
      if (knifeselected[id]){
         new invisibility = p_invisibility[p_skills[id][SKILLIDX_INVIS]-1]/2
         set_user_rendering(id,kRenderFxNone, 0,0,0, kRenderTransTexture,invisibility)
      }else
         set_user_rendering(id,kRenderFxNone, 0,0,0, kRenderTransTexture,p_invisibility[p_skills[id][SKILLIDX_INVIS]-1])
   }else if (playeritem[id]==CLOAK){
      if (knifeselected[id]){
         new invisibility = CLOAKINVISIBILITY/2
         set_user_rendering(id,kRenderFxNone, 0,0,0, kRenderTransTexture,invisibility)
      }else{
         set_user_rendering(id,kRenderFxNone, 0,0,0, kRenderTransTexture,CLOAKINVISIBILITY)
      }
   }else{
      set_user_rendering(id)
   }


   // Unholy Aura handler next - Call unholy routine
   new parm[1]
   parm[0]=id
   unholyspeed(parm)


   //if (bLvled)
   //   select_skill(id, 1)

   return PLUGIN_CONTINUE

}
// **************************************************************************
// END displaylevel subroutine
// **************************************************************************


// **************************************************************************
// BEGIN cmd_who subroutine
// Displays the list of players
// **************************************************************************
public cmd_who(id){

   new message[4096] = ""
   new name[32]
   new team[32]
   new players[32]
   new numplayers
   get_players(players, numplayers)
   new i
   new playerid
   new pos = 0

   pos += format( message[pos], 4096-pos, "<body bgcolor=#000000 text=#FFB000>^n" )
   pos += format( message[pos], 4096-pos, "<center><b>The following players are online</b></center><p>^n" )
   pos += format( message[pos], 4096-pos, "<center><table width=800 border=1 cellpadding=4 cellspacing=4>^n" )
   pos += format( message[pos], 4096-pos, "<tr><td>Name</td><td>Team</td><td>Level</td></tr>^n" )

   for (i=0; i< numplayers; i++){
      playerid = players[i]

      if ( get_user_team(playerid) == TEAM_T ) team = "Terrorist"
      else if ( get_user_team(playerid) == TEAM_CT ) team = "CT"
      else team = "Spectator"

      get_user_name( playerid, name, 31 )

      log_amx( "Adding player: %s", name )

      pos += format( message[pos], 4096-pos, "<tr><td>%s</td><td>%s</td><td>%d</td></tr>^n", 
                     name, team, p_level[playerid], name)

   }

   pos += format( message[pos], 4096-pos, "</table></center>^n" )

   new whofile[64]
   get_configsdir( whofile, 63 )
   format( whofile, 63, "%s/UWC3/uwc3_who.txt", whofile )

   if ( file_exists( whofile ) )
      delete_file( whofile )

   write_file( whofile, message ) 

   show_motd( id, whofile, "UWC3 Players Online" )

   return PLUGIN_CONTINUE

}
// **************************************************************************
// END cmd_who subroutine
// **************************************************************************


// **************************************************************************
// BEGIN player_skills subroutine
// Displays the rank and skills for all players
// **************************************************************************
public player_skills(id){
   if ( !warcraft3 )
      return PLUGIN_CONTINUE

   client_print( id, print_chat,
      "[%s] /Playerskills is deprecated, please use /who instead.", MOD)

   return PLUGIN_CONTINUE
}

public player_skills_OLD(id){
   if (!warcraft3)
      return PLUGIN_CONTINUE

   new name[32]
   new message[2048] = ""
   new temp[1024] = ""
   new temp2[64] = ""
   new temp3[128] = ""

   new players[32]
   new numberofplayers
   get_players(players, numberofplayers)
   new i
   new playerid

   add(message,2047,"<body bgcolor=#000000><font color=#FFB000>")
   add(message,2047,"<center><b>The following players are online</b></center><p>")
   add(message,2047,"<center><table width=800 border=1 cellpadding=4 cellspacing=4>")

   // [07-02-04] K2mia => Motd cannot handle a full server of players' skills
   // so now we break it up into pages, page # internally kept in lastpspage
   new sidx = (lastpspage[id] * 6)
   new eidx = sidx + 6 - 1
   if (eidx >= numberofplayers){
      sidx = ((numberofplayers - 6) >= 0) ? (numberofplayers - 6) : 0
      eidx = numberofplayers
      lastpspage[id] = 0
   }else{
      lastpspage[id] += 1
   }

   for (i = sidx; i < eidx; ++i){
      new sname[32] = ""
      new bool:bHasASkill = false

      playerid=players[i]
      get_user_name(playerid,name,31)

      temp = ""

      for (new j=1; j<MAX_SKILLS;j++){
         if (j <= 8) copy(sname, 31, skillset1[j])
         else if (j <= 16) copy(sname, 31, skillset2[j-8])
         else if (j <= 24) copy(sname, 31, skillset3[j-16])
         else if (j <= 32) copy(sname, 31, skillset4[j-24])
         else if (j <= 40) copy(sname, 31, skillset5[j-32])

         if (p_skills[playerid][j]){
            bHasASkill = true
            format(temp2,64,"[%d]%s  ",  p_skills[playerid][j], sname )
            add(temp,1024,temp2)
         }
      }

      if (!bHasASkill){
         add(temp,1024, "No skills trained")
      }


      format(temp3 ,128,
         "<tr><td valign=top><font color=#FFB000><b>%s</b>  Rank: %s [%d] - -  ",
            name, p_rank[playerid], p_level[playerid] )
      add(message, 2048, temp3)
      add(message, 2048, temp)
      add(message, 2048, "</td></tr>")

      /*if (i % 2 == 0){
         format(temp3 ,128,
            "<tr><td valign=top><font color=#FFB000><b>%s</b>  (Rank: %s [%d]) <br>",
               name, p_rank[playerid], p_level[playerid] )
         add(message, 2048, temp3)
         add(message, 2048, temp)
         add(message, 2048, "</td>")
      }else{
         format(temp3, 128,
            "<td valign=top><font color=#FFB000><b>%s</b>  (Rank: %s [%d]) <br>",
               name, p_rank[playerid], p_level[playerid] )
         add(message, 2048, temp3)
         add(message, 2048, temp)
         add(message, 2048, "</td></tr>")
      }*/

   }

   add(message,2048,"</table></center>")

   show_motd(id,message,"UWC3 Player Skills")

   return PLUGIN_CONTINUE

}
// **************************************************************************
// END player_skills subroutine
// **************************************************************************


// **************************************************************************
// END Help and Info Menus and Menu Handler Subroutines
// **************************************************************************

