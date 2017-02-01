
/** *************************************************************************
*** AMXX Plugin:   Ultimate Warcraft3 (UWC3)
*** Plugin Author: K2mia
*** UWC3 Module:   Main 
*** Date:          May 25, 2004
*** Last Update:   October 08, 2004
*
*   This plugin is a new approach to the War3 and War3FT plugins created by
*  SpaceDude and Pimp Daddy. UWC3 provides a raceless, skill/level based 
*  system. Much of the internal workings of Warcraft3FT skills and items were 
*  kept intact from Pimp Daddy's version, though the overall player structures
*  have been changed to allow a flexible skill-based system. This version of UWC3
*  was built for AMX Mod X v0.20 
*
*  Module: Main
*  Plugin initialization routines, client connection/disconnection routines as
*  well as plugin-wide task handlers.
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


/** *************************************************************************
*
*  Original War3FT Credits Follow:
*  Warcraft 3: Frozen Throne
*  by Pimp Daddy (OoTOAoO)
*  email: PimpDaddy@cinci.rr.com
*  MSN: PimpDaddy@cinci.rr.com

*
*  Credits to:
*  Spacedude (for War3 MOD)
*  Ludwig Van (for flamethrower)
*  OLO (for spectating rank info)
*  JGHG for the mole code
*  [AOL]Demandred, [AOL]LuckyJ for help coding it for steam
*  [AOL]Demandred for freezetime exploit fix
*  Denkkar for some of his code (ie. STEAM_POWERED)
*  Everyone at amxmod.net for help
*  joecool12321 for various health related fixes
*  Tri Moon for various improvements (No Race, war3menu, etc...)
*  xeroblood for spotting some bugs for me :)
*  bad-at-this for contributing the status bar code used for godmode (
*     big bad voodoo)
*  kamikaze for help w/testing version before release
*  lui for the delayed ultimate code
*  The following people helped convert the text to German:
*               Walken / Altegarde.com
*               Fire
*               ^^plan.los^^
****************************************************************************/

#include <amxmodx>
#include <amxmisc>
#include <engine>
#include <cstrike>
#include <fun>
#include <dbi>

#include "uwc3_defs.inc"	// Include the UWC3 #defines file
#include "uwc3_vars.inc"	// Include the UWC3 global variables file
#include "uwc3_ultimates.inc"	// Include the UWC3 ultimate subroutines file
#include "uwc3_abilities.inc"	// Include the UWC3 abilities subroutines file
#include "uwc3_enh.inc"		// Include the UWC3 enhancements subroutines file
#include "uwc3_utility.inc"	// Include the UWC3 utilities subroutines file
#include "uwc3_storage.inc"	// Include the UWC3 storage subroutines file
#include "uwc3_infohelp.inc"	// Include the UWC3 help/info subroutines file
#include "uwc3_dmgevents.inc"	// Include the UWC3 damage events subroutines file
#include "uwc3_mole.inc"	// Include the UWC3 mole subroutines file
#include "uwc3_respawn.inc"	// Include the UWC3 respawn subroutines file
#include "uwc3_items.inc"	// Include the UWC3 items subroutines file
#include "uwc3_skills.inc"	// Include the UWC3 skills subroutines file
#include "uwc3_xp.inc"		// Include the UWC3 xp subroutines file
#include "uwc3_events.inc"	// Include the UWC3 events subroutines file


#pragma dynamic 65536 		// Give the plugin some extra memory to use

// **************************************************************************
// END Global variable Declarations
// **************************************************************************

// **************************************************************************
// BEGIN subroutine declarations section
// **************************************************************************

// **************************************************************************
// BEGIN plugin_init subroutine
// Plugin Initialization and Registration
// **************************************************************************
public plugin_init(){

   register_plugin( "UWC3", VER, "K2mia")

   // Set messagning variables  
   gMsgScreenFade = get_user_msgid("ScreenFade") 
   gmsgDeathMsg = get_user_msgid("DeathMsg")
   gmsgFade = get_user_msgid("ScreenFade")
   gmsgShake = get_user_msgid("ScreenShake")
   gmsgStatusText = get_user_msgid("StatusText")
   //gmsgIcon = get_user_msgid("StatusIcon")

   // [09-13-04] Nasty exploit, this prevents it - K2mia
   register_clcmd("fullupdate", "fullupdate")
 
   // Client command entries follow
   register_clcmd( "war3menu", "main_menu", -1,
      "- Display the UWC3 Main Menu")
   register_clcmd( "wc3menu", "main_menu", -1,
      "- Display the UWC3 Main Menu")
   register_clcmd( "warcraft", "main_menu", -1,
      "- Display the UWC3 Main Menu")
   register_clcmd( "help", "help_menu", -1, 
      "- Displays the main help menu")
   register_clcmd( "news", "show_news", -1, 
      "- Displays news about the Ultimate Warcraft3 plugin")
   register_clcmd( "war3help", "war3_info", -1, 
      "- Displays help information for the UWC3 module")
   register_clcmd( "wc3start", "restart_round", ADMIN_MENU, 
      "- Restarts the UWC3 mod fresh")

   register_clcmd( "charsheet", "character_sheet", -1, 
      "- Displays your character sheet")

   register_clcmd("savexp", "uwc3_savexp", -1,
      "-In long term XP mode, saves your XP to the vault")
   register_clcmd("saveattribs", "uwc3_saveattribs", -1,
      "-In long term XP mode, saves your Attributes")
   register_clcmd("saveresists", "uwc3_saveresists", -1,
      "-In long term XP mode, saves your Resistances")
   register_clcmd("saveall", "uwc3_saveall", -1,
      "-In long term XP mode, saves your XP / Skills / Attributes / Resistances")
   register_clcmd("resetskills", "resetskills", -1,
      "-Resets your skills while keeping your XP")
   register_clcmd("resetattribs", "resetattribs", -1,
      "-Resets your attributes while keeping your XP")
   register_clcmd("resetresists", "resetresists", -1,
      "-Resets your resistances while keeping your XP")
   register_clcmd("deletexp", "amx_deletexp", -1, 
      "- Deletes all skills and sets your XP to 0")
   register_clcmd("saveskills", "uwc3_saveskills", -1,
      "-In long term XP mode, saves your skills to the vault")
   register_clcmd("reloadskills", "reloadskills", -1,
      "-Reloads the default saved set of skills")
   register_clcmd("admin_loadskills", "admin_loadskills", ADMIN_MENU,
      "-Loads a saved set of skills")

   register_clcmd("admin_showxp", "admin_showxp", ADMIN_MENU, 
      "-Admin Cmd: Displays a player's XP")

   register_clcmd("examine", "do_examine", -1, 
      "-Allows a player to examine the health and armor of a teammate")
   register_clcmd("/examine", "do_examine", -1, 
      "-Allows a player to examine the health and armor of a teammate")

   register_clcmd("toggle_lowres", "toggle_lowres", -1, 
      "-Toggle low-res mode on/off")

   register_clcmd("xp_table", "xp_table", -1, 
      "-Displays the XP table")

   // ******************** TEST COMMANDS *******************
   register_clcmd("admin_loadxp", "get_xp_id", ADMIN_MENU, 
      "-Debug cmd for testing load data from vault routine")
   register_clcmd("debug_info", "debug_info", ADMIN_MENU, 
      "-Dumps some debug info to the admin")
   register_clcmd("debuginfo", "debug_info", ADMIN_MENU, 
      "-Dumps some debug info to the admin")
   register_clcmd("loc", "admin_loc", ADMIN_MENU, 
      "-Displays your coordinate location")
   // ****************** END TEST COMMANDS ******************

   register_clcmd("changerace", "change_race", -1, "-Display UWC3 info")
   register_clcmd("/changerace", "change_race", -1, "-Display UWC3 info")
   register_clcmd("selectrace", "change_race", -1, "-Display UWC3 info")
   register_clcmd("/selectrace", "change_race", -1, "-Display UWC3 info")
   register_clcmd("selectskill", "select_skill", -1, "-Displays the skills menu")
   register_clcmd("/selectskill", "select_skill", -1, "-Displays the skills menu")
   register_clcmd("selectattrib", "select_attrib", -1, "-Displays the attributes menu")
   register_clcmd("/selectattrib", "select_attrib", -1, "-Displays the attributes menu")
   register_clcmd("selectresist", "select_resist", -1, "-Displays the resistances menu")
   register_clcmd("/selectresist", "select_resist", -1, "-Displays the resistances menu")

   register_clcmd("shopmenu", "shopmenu", -1, "shopmenu")
   register_clcmd("shopmenu2", "shopmenu2", -1, "shopmenu2")
   register_clcmd("rings", "rings5", -1, "-Saying this allows you to buy 5 rings")

   //register_clcmd("shield", "shieldbuy")
   //register_clcmd("drop", "hook_drop")

   register_clcmd( "say", "check_say")
   register_clcmd( "say_team", "check_say")

   // Ultimate skills - client commands to bind
   register_clcmd("wcsuicide", "ultimate_wcsuicide", -1, "-Suicide Bomber Ultimate")
   register_clcmd("wcteleport", "ultimate_wcteleport", -1, "-Teleport Ultimate Skill")
   register_clcmd("wclightning", "ultimate_wcchain", -1, "-Chain Lightning Ultimate")
   register_clcmd("wcentangle", "ultimate_wcentangle", -1, "-Entangle Ultimate")
   register_clcmd("wcflame", "ultimate_wcflame", -1, "-Flame Strike Ultimate Skill")
   register_clcmd("wcvoodoo", "ultimate_wcvoodoo", -1, "-Big Bad Voodoo Ultimate Skill")
   register_clcmd("wclocust", "ultimate_wclocust", -1, "-Locust Swarm Ultimate Skill")
   register_clcmd("wcflash", "ultimate_wcflash", -1, "-Flash of Light Ultimate Skill")
   register_clcmd("wcdecoy", "ultimate_wcdecoy", -1, 
      "-Decoy Ultimate Skill, spawns a decoy to briefly fool your enemies")
   register_clcmd("wcgate", "ultimate_wcgate", -1,
      "-Gate Ultimate Skill, Opens a gateway back to your spawn")

   register_clcmd("wcward", "ability_wcward", -1, "-Serpant Ward Ultimate Skill")
   register_clcmd("wcrepair", "ability_wcrepair", -1, 
      "-Special Ability: Repair Armor (aim at teammate and trigger the wcrepair cmd)")
   register_clcmd("wcmend", "ability_wcmend", -1, 
      "-Special Ability: Mend Wounds (aim at teammate and trigger the wcmend command)")

    
   // Console command entries follow
   register_concmd("amx_givexp", "amx_givexp", -1,"-Console command used to give XP")
   register_concmd("amx_givemole", "amx_givemole", -1, "-Admin make a mole command")
   register_concmd("playerskills", "player_skills", -1, "-Displays the players rank and skills")


   // Menu related entries follow
   register_menucmd(register_menuid("\yUWC3: Main Menu"), 1023, "do_wc3menu") 
   register_menucmd(register_menuid("\ySelect an Attribute"), 1023, "do_attribmenu")
   register_menucmd(register_menuid("\ySelect a Resistance"), 1023, "do_resistmenu")
   register_menucmd(register_menuid("\yHelp Menu"), 1023, "do_helpmenu")
   register_menucmd(register_menuid("\yAdmin Menu"), 1023, "do_adminmenu")
   register_menucmd(register_menuid("\ySkills Options"), 1023, "do_skillsmenu")
   register_menucmd(register_menuid("\yItem Options"), 1023, "do_itemmenu")
   register_menucmd(register_menuid("\yGive Players XP"), 1023,"do_playerxpmenu")
   register_menucmd(register_menuid("\yTeam XP Menu"), 1023, "do_teamxpmenu")
   register_menucmd(register_menuid("Select Skill: "), (1<<0)|(1<<1)|(1<<2)|(1<<3)|(1<<4)|(1<<5)|(1<<6)|(1<<7)|(1<<8)|(1<<9), "set_skill")
   register_menucmd(register_menuid("\yBuy An Item"), 1023, "buy_item2")
   register_menucmd(register_menuid("\yBuy Item"), 1023, "buy_item")
   register_menucmd(register_menuid("BuyItem"),(1<<2),"flashbuy")
   register_menucmd(register_menuid("BuyItem"),(1<<3),"hebuy")
   register_menucmd(-34,(1<<2),"flashbuy")
   register_menucmd(-34,(1<<3),"hebuy")                         
   register_clcmd("flash",  "flashbuy")
   register_clcmd("hegren", "hebuy")                          


   // Event related entries follow
   register_event("TextMsg", "game_commencing", "a", "2&#Game_C")
   register_event("TextMsg", "restart_round", "a", "2&#Game_will_restart_in")
   register_event("TextMsg", "Target_Bombed", "a", "2&#Target_Bombed")
   register_event("TextMsg", "setSpecMode", "bd", "2&ec_Mod")
   register_event("StatusValue", "setTeam", "be", "1=1")
   register_event("StatusValue", "showStatus", "be", "1=2", "2!0")
   register_event("StatusValue", "hideStatus", "be", "1=1", "2=0")
   register_event("StatusValue", "showRank", "bd", "1=2")
   register_event("StatusIcon", "BuyZone", "be", "2=buyzone")
   register_event("StatusIcon", "got_defuse", "be", "1=1", "1=2", "2=defuser")
   register_event("ResetHUD", "new_round", "b")
   register_event("SetFOV", "zoomed2", "be", "1<90")
   register_event("SetFOV", "unzoomed", "be", "1=90")
   register_event("Damage", "damage_event", "b", "2!0")
   register_event("DeathMsg", "death", "a")
   register_event("SendAudio", "T_win", "a", "2=%!MRAD_terwin")
   register_event("SendAudio", "CT_win", "a", "2=%!MRAD_ctwin")
   register_event("SendAudio","nade_thrown","bc","2=%!MRAD_FIREINHOLE")
   register_event("WeapPickup", "check_weap", "b")
   register_event("CurWeapon", "change_weapon", "be", "1=1")
   register_event("ArmorType", "armor_type", "be")

   // Log events: Requires AMX 0.9.3 or better
   register_logevent("event_player_action", 3, "1=triggered")
   register_logevent("freezetimedone", 2, "0=World triggered", "1=Round_Start")
   register_logevent("end_round", 2, "0=World triggered", "1=Round_End")

   // Next 3 register commands copied from Warcraft3 for STEAM (unsure why)
   //register_menucmd(register_menuid("Team_Select",1),(1<<0)|(1<<1)|(1<<4),"teamselect")
   //register_event("ShowMenu","teamselect","b","4&CT_Select","4&Terrorist_Select")
   //register_clcmd("jointeam","teamselect")

   register_cvar("amx_uwc3", VER, FCVAR_SERVER)
   register_cvar("FT_objectives", "1")
   register_cvar("FT_ultimatedelay", "0")
   register_cvar("FT_min_b4_XP","2")
   register_cvar("FT_no_orcnades_on_he","0")
   register_cvar("FT_centerhud","1")
   register_cvar("FT_saveby","0")
   register_cvar("FT_position","0")
   register_cvar("FT_8race","1")
   register_cvar("FT_glove_timer","25")
   register_cvar("FT_competitive","0")
   register_cvar("FT_glove_orc_damage","1")
   register_cvar("FT_glove_napalm_damage","0")
   register_cvar("FT_round_win_XP","10")
   register_cvar("FT_healing_range","750")
   register_cvar("FT_xp_radius","750")
   register_cvar("FT_explosion_max_damage","50")
   register_cvar("FT_explosion_range","300")
   register_cvar("FT_blast_radius","250")
   register_cvar("FT_bigbadvoodoo_cooldown","35.0")
   register_cvar("FT_flamestrike_cooldown","35.0")
   register_cvar("FT_locusts_cooldown","35.0")
   register_cvar("FT_chainlightning_cooldown","35.0")
   register_cvar("FT_teleport_cooldown","35.0")
   register_cvar("FT_entanglingroots_cooldown","35.0")
   register_cvar("FT_kill_objectives","1")
   register_cvar("FT_reset_skills","1")
   register_cvar("FT_show_player","1")
   register_cvar("FT_show_icons","1")
   register_cvar("FT_hostage_touch_bonus","0")
   register_cvar("FT_attempt_defuse_bonus","0")
   register_cvar("FT_bomb_event_bonus","0")
   register_cvar("FT_VIP_spawn_bonus","0")
   register_cvar("FT_hostage_kill_xp","0")
   register_cvar("FT_headshot_bonus","30")
   register_cvar("FT_defuser_kill_bonus","60")
   register_cvar("FT_VIP_escape_bonus","60")
   register_cvar("FT_hostage_touch_bonus","9")
   register_cvar("FT_kill_bomb_carrier_bonus","60")
   register_cvar("FT_bombplanterxp","60")
   register_cvar("FT_defusexp","60")
   register_cvar("FT_hostagexp","60")
   register_cvar("FT_killrescuemanxp","60")
   register_cvar("FT_xpbonus","60")
   register_cvar("FT_warn_suicide","1")
   register_cvar("FT_no_gloves_on_ka","1")
   register_cvar("FT_blink_radius","500")
   register_cvar("FT_blink_delay","15.0")
   register_cvar("FT_blink_protection","1")
   register_cvar("FT_blink_diziness","1")
   register_cvar("FT_blink_cooldown","3.0")
   register_cvar("FT_blinkenabled","1")
   register_cvar("FT_blinkstartdisabled","0")             
   register_cvar("FT_spec_info","1")   // Show spectating information
   register_cvar("FT_items_in_hud","0")                    
   register_cvar("mp_savexp","1", FCVAR_SERVER)
   register_cvar("mp_sql","1")
   register_cvar("mp_sql_saveby","1")
   register_cvar("mp_sql_saveoncmdonly","0")
   register_cvar("mp_xpmultiplier","1.50")
   register_cvar("mp_weaponxpmodifier","1")
   register_cvar("sv_warcraft3","1",0)
   register_cvar("sv_restrictultimate","0",0)
   register_cvar("sv_allowwar3vote","0")
   register_cvar("mp_grenadeprotection","0")
   register_cvar("sv_daysbeforedelete","31")
   register_cvar("amx_vote_delay","60")
   register_cvar("amx_vote_time","10")
   register_cvar("amx_vote_answers","1")
   register_cvar("amx_votewar3_ratio","0.70")
   register_cvar("UW_sql_host","127.0.0.1")
   register_cvar("UW_sql_user","root")
   register_cvar("UW_sql_pass","")
   register_cvar("UW_sql_db","uwc3")
   register_cvar("UW_normalspeed","250.0")
   register_cvar("UW_underdog_kills","1")
   register_cvar("UW_dmgxpbonus","1")
   register_cvar("UW_medicalerts","2")
   register_cvar("UW_repair_XP","60")
   register_cvar("UW_mend_XP","60")
   register_cvar("UW_phoenix_XP","90")
   register_cvar("UW_force_vengeance","1")
   register_cvar("UW_luck_skill","1")
   register_cvar("UW_use_enh","0")
   register_cvar("UW_enh_minlevel","34")
   register_cvar("UW_max_resistvalue","100")
   register_cvar("UW_max_attribpts","40")
   register_cvar("UW_max_resistpts","500")
   register_cvar("UW_DEBUG","0")
   register_cvar("UW_DEBUG_code","0")
   register_cvar("UW_round_check","1")
   register_cvar("UW_admin_mode","0")
   register_cvar("UW_admin_flag","1048576")
   register_cvar("UW_disable_adminmenu","0")
   register_cvar("UW_disable_givexp","0")
   register_cvar("UW_lowres_default","0")
   register_cvar("UW_BOOTSPEED","275.0")
   register_cvar("UW_FROSTSPEED","125.0")
   register_cvar("UW_MASKPERCENT","0.3")
   register_cvar("UW_CLAWSOFATTACK","6")
   register_cvar("UW_CLOAKINVISIBILITY","180")
   register_cvar("UW_HEALTHBONUS","15")
   register_cvar("UW_price_ANKH","1500")
   register_cvar("UW_price_BOOTS","1500")
   register_cvar("UW_price_CLAWS","1000")
   register_cvar("UW_price_CLOAK","800")
   register_cvar("UW_price_MASK","2000")
   register_cvar("UW_price_IMMUNITY","800")
   register_cvar("UW_price_FROST","2000")
   register_cvar("UW_price_HEALTH","1000")
   register_cvar("UW_price_TOME","4000")
   register_cvar("UW_price_RESPAWN","11000")
   register_cvar("UW_price_PROTECTANT","1500")
   register_cvar("UW_price_HELM","1550")
   register_cvar("UW_price_CAT","1500")
   register_cvar("UW_price_FEATHER","1500")
   register_cvar("UW_price_INFERNO","1750")
   register_cvar("UW_price_REGEN","1000")
   register_cvar("UW_price_CHAMELEON","9000")
   register_cvar("UW_price_MOLE","16000")
   register_cvar("UW_attrib_xpmodifier","1.0")
   register_cvar("UW_resist_xpmodifier","1.0")

   // set_task calls for functions needed by init or to run continuously
   set_task(10.0, "check_war3",456,"",0,"b")
   set_task(1.0, "check_war3",457)
   set_task(3.0, "set_xpfrontend", 458)
   set_task(0.6, "set_variables", 822)
   // check_duck used by decoy ultimate
   set_task(0.01, "check_duck", 0, "", 0, "b")

   set_xpmultiplier()	// Set weapon xp modifiers
   set_skill_limits()	// Set skills-based tables (skill levels, effects, etc)

   new basedir[64]
   new cfgfile[64]
   get_customdir(basedir, 63)
   format(cfgfile, 63, "%s/UWC3/UWC3.cfg", basedir)

   if (file_exists(cfgfile)){
      log_amx("UWC3 Startup :: Loading Configuration File [ UWC3.cfg ]...")
      server_cmd("exec %s", cfgfile)
      log_amx("UWC3 Startup :: Configuration File Loaded [OK]")
   }else{
      log_amx("UWC3 Startup :: Configuration File NOT FOUND [ Using Default settings ]")
   }

   set_task(0.6, "check_sql", 823)


}
// **************************************************************************
// END plugin_init subroutine
// **************************************************************************


// **************************************************************************
// BEGIN plugin_modules subroutine
// Specify which modules are required by UWC3
// **************************************************************************
public plugin_modules()
{

   require_module("engine")	// Requires the engine module
   require_module("fun")	// Requires the fun module
   require_module("cstrike")	// Requires the cstrike module
   require_module("dbi")	// Requires the dbi module

}
// **************************************************************************
// END plugin_modules subroutine
// **************************************************************************


// **************************************************************************
// BEGIN plugin_precache subroutine
// Specify resources to be precached on client side 
// **************************************************************************
public plugin_precache() {

   g_sModelIndexFireball = precache_model("sprites/zerogxplode.spr")
   g_sModelIndexSmoke = precache_model("sprites/steam1.spr")
   m_iSpriteTexture = precache_model( "sprites/shockwave.spr")
   flaresprite = precache_model( "sprites/blueflare2.spr")
   //iBeam4 = precache_model("sprites/zbeam4.spr")
   m_iTrail = precache_model("sprites/smoke.spr")
   lightning = precache_model("sprites/lgtning.spr")
   //shadow = precache_model("sprites/animglow01.spr")
   shadow = precache_model("sprites/xspark3.spr")
   carrion = precache_model("sprites/carrion.spr")
   snow = precache_model("sprites/snow.spr")
   fire = precache_model("sprites/explode1.spr")
   burning = precache_model("sprites/xfire.spr")

   // [09-02-04] Added sprites for medic, shield and combo, and other effects
   medicspr = precache_model("sprites/medic3.spr")
   shieldspr = precache_model("sprites/shield3.spr")
   medshieldspr = precache_model("sprites/medshield1.spr")
   blast = precache_model("sprites/blast2.spr")
   gatespr = precache_model("sprites/gate1.spr")
   cbgreen = precache_model("sprites/bm7.spr")
   poison = precache_model("sprites/poison1.spr")
   spikes = precache_model("sprites/spikes1.spr")
   thorns = precache_model("sprites/thorns2.spr")

   if (file_exists("models/player/zombie/zombie.mdl"))
      precache_model("models/player/zombie/zombie.mdl")
   if (file_exists("models/roots2.mdl"))
      precache_model("models/roots2.mdl")

   precache_sound("ambience/particle_suck1.wav")
   precache_sound("turret/tu_ping.wav")
   precache_sound("weapons/cbar_hitbod3.wav")

   // [06-13-2004] New sounds added by K2mia for Napalm Grenades
   precache_sound("ambience/flameburst1.wav")
   precache_sound("scientist/scream07.wav")
   precache_sound("buttons/button10.wav")
   precache_sound("fans/fan5.wav")
   precache_sound("items/medshot5.wav")
   precache_sound("items/suitchargeok1.wav")


   if (file_exists("sound/warcraft3/banishcaster.wav"))
      precache_sound("warcraft3/banishcaster.wav")
   if (file_exists("sound/warcraft3/antend.wav"))
      precache_sound("warcraft3/antend.wav")
   if (file_exists("sound/warcraft3/tomes.wav"))
      precache_sound("warcraft3/tomes.wav")
   if (file_exists("sound/warcraft3/locustswarmloopwav.wav"))
      precache_sound("warcraft3/locustswarmloopwav.wav")
   if (file_exists("sound/warcraft3/impalelaunch1.wav"))
      precache_sound("warcraft3/impalelaunch1.wav")
   if (file_exists("sound/warcraft3/shadowstrikemissile1.wav"))
      precache_sound("warcraft3/shadowstrikemissile1.wav")
   if (file_exists("sound/warcraft3/locustswarmloop.wav"))
      precache_sound("warcraft3/locustswarmloop.wav")
   if (file_exists("sound/warcraft3/soundpack/reincarnation.wav"))
      precache_sound("warcraft3/soundpack/reincarnation.wav")
   if (file_exists("sound/warcraft3/shadowstrikebirth1.wav"))
      precache_sound("warcraft3/shadowstrikebirth1.wav")
   if (file_exists("sound/warcraft3/carrionswarmdamage1.wav"))
      precache_sound("warcraft3/carrionswarmdamage1.wav")
   if (file_exists("sound/warcraft3/carrionswarmlaunch1.wav"))
      precache_sound("warcraft3/carrionswarmlaunch1.wav")
   if (file_exists("sound/warcraft3/impalehit.wav"))
      precache_sound("warcraft3/impalehit.wav")
   if (file_exists("sound/warcraft3/divineshield.wav"))
      precache_sound("warcraft3/divineshield.wav")
   if (file_exists("sound/warcraft3/flamestriketargetwavenonloop1.wav"))
      precache_sound("warcraft3/flamestriketargetwavenonloop1.wav")
   if (file_exists("sound/warcraft3/entanglingrootstarget1.wav"))
      precache_sound("warcraft3/entanglingrootstarget1.wav")
   else{
      precache_sound("weapons/electro5.wav")
      precache_sound("weapons/cbar_hitbod3.wav")
   }
   if (file_exists("sound/warcraft3/levelupcaster.wav"))
      precache_sound("warcraft3/levelupcaster.wav")
   else
      precache_sound("plats/elevbell1.wav")

   if (file_exists("sound/warcraft3/lightningbolt.wav"))
      precache_sound("warcraft3/lightningbolt.wav")
   else
      precache_sound("weapons/gauss2.wav")

   if (file_exists("sound/warcraft3/massteleporttarget.wav"))
      precache_sound("warcraft3/massteleporttarget.wav")
   else
      precache_sound("x/x_shoot1.wav")

   if (file_exists("sound/warcraft3/blinkarrival.wav"))
      precache_sound("warcraft3/blinkarrival.wav")
   else
      precache_sound("x/x_shoot1.wav")

   if (file_exists("sound/warcraft3/pickupitem.wav"))
      precache_sound("warcraft3/pickupitem.wav")

   // Precache std CS player models for use with decoy ability
   precache_model("models/player/leet/leet.mdl")
   precache_model("models/player/arctic/arctic.mdl")
   precache_model("models/player/guerilla/guerilla.mdl")
   precache_model("models/player/terror/terror.mdl")

   precache_model("models/player/gign/gign.mdl")
   precache_model("models/player/sas/sas.mdl")
   precache_model("models/player/gsg9/gsg9.mdl")
   precache_model("models/player/urban/urban.mdl")

   precache_model("models/player/vip/vip.mdl")
   precache_model("models/guerilla.mdl")

   return PLUGIN_CONTINUE
}
// **************************************************************************
// END plugin_precache subroutine
// **************************************************************************


// **************************************************************************
// BEGIN set_variables subroutine
// Setup variables and use cvar data where applicable 
// **************************************************************************
public set_variables(){
   MOD = "UWC3"
   BOMBPLANTXP = get_cvar_num("FT_bombplanterxp")
   DEFUSEXP = get_cvar_num("FT_defusexp")
   HOSTAGEXP = get_cvar_num("FT_hostagexp")
   KILLRESCUEMANXP = get_cvar_num("FT_killrescuemanxp")
   XPBONUS = get_cvar_num("FT_xpbonus")
   KILL_BOMB_CARRIER = get_cvar_num("FT_kill_bomb_carrier_bonus")
   HEADSHOT_BONUS = get_cvar_num("FT_headshot_bonus")
   DEFUSER_KILL_BONUS = get_cvar_num("FT_defuser_kill_bonus")
   VIP_ESCAPE_BONUS = get_cvar_num("FT_VIP_escape_bonus")
   ROUNDXP = get_cvar_num("FT_round_win_XP")
   REPAIRXP = get_cvar_num("UW_repair_XP")
   MENDXP = get_cvar_num("UW_mend_XP")
   PHOENIXXP = get_cvar_num("UW_phoenix_XP")

   // [08-01-04] Admin Only sets skills reserved only for admins
   if (get_cvar_num("UW_admin_mode")){
      admin_only[SKILLIDX_REPAIR] = true
      admin_only[SKILLIDX_NAPALM] = true
      admin_only[SKILLIDX_VOODOO] = true
      admin_only[SKILLIDX_FAN] = true
      admin_only[SKILLIDX_VENGEANCE] = true
      admin_only[SKILLIDX_TRUESHOT] = true
   }

   // If attribute enhancements allowed but no min. level set use default
   if (get_cvar_num("UW_use_enh")){
      USE_ENH = 1
      if (get_cvar_num("UW_enh_minlevel"))
         enh_minlevel = get_cvar_num("UW_enh_minlevel") 
      else 
         enh_minlevel = ENH_MIN_LEVEL
      log_amx("Enhancements ON with minimum level set to [%d]", enh_minlevel)

      if (get_cvar_num("UW_max_resistvalue")){
         RESIST_MAX_VALUE = get_cvar_num("UW_max_resistvalue")
         log_amx("Override Detected : Max Resist Value [%d]", RESIST_MAX_VALUE)
      }

      if (get_cvar_num("UW_max_attribpts")){
         ATTRIB_MAX_PTS = get_cvar_num("UW_max_attribpts")
         log_amx("Override Detected : Max Attrib Pts [%d]", ATTRIB_MAX_PTS)
      }

      if (get_cvar_num("UW_max_resistpts")){
         RESIST_MAX_PTS = get_cvar_num("UW_max_resistpts")
         log_amx("Override Detected : Max Resist Pts [%d]", RESIST_MAX_PTS)
      }
   }


   // [07-31-04] Check for other setting overrides from config file
   if (get_cvar_float("UW_BOOTSPEED")){
      BOOTSPEED = get_cvar_float("UW_BOOTSPEED")
      log_amx("Override Detected : BOOTSPEED [%f]", BOOTSPEED)
   }
   if (get_cvar_float("UW_FROSTSPEED")){
      FROSTSPEED = get_cvar_float("UW_FROSTSPEED")
      log_amx("Override Detected : FROSTSPEED [%f]", FROSTSPEED)
   }
   if (get_cvar_float("UW_MASKPERCENT")){
      MASKPERCENT = get_cvar_float("UW_MASKPERCENT")
      log_amx("Override Detected : MASKPERCENT [%f]", MASKPERCENT)
   }
   if (get_cvar_num("UW_CLAWSOFATTACK")){
      CLAWSOFATTACK = get_cvar_num("UW_CLAWSOFATTACK")
      log_amx("Override Detected : CLAWSOFATTACK [%d]", CLAWSOFATTACK)
   }
   if (get_cvar_num("UW_CLOAKINVISIBILITY")){
      CLOAKINVISIBILITY = get_cvar_num("UW_CLOAKINVISIBILITY")
      log_amx("Override Detected : CLOAKINVISIBILITY [%d]", CLOAKINVISIBILITY)
   }
   if (get_cvar_num("UW_HEALTHBONUS")){
      HEALTHBONUS = get_cvar_num("UW_HEALTHBONUS")
      log_amx("Override Detected : HEALTHBONUS [%d]", HEALTHBONUS)
   }

   // [07-31-04] Check for shop item cost overrides from config file
   if (get_cvar_num("UW_price_ANKH") != itemcost[ANKH-1]){
      itemcost[ANKH-1] = get_cvar_num("UW_price_ANKH")
      log_amx("Item Price Override Detected : ANKH [%d]", itemcost[ANKH-1])
   }
   if (get_cvar_num("UW_price_BOOTS") != itemcost[BOOTS-1]){
      itemcost[BOOTS-1] = get_cvar_num("UW_price_BOOTS")
      log_amx("Item Price Override Detected : BOOTS [%d]", itemcost[BOOTS-1])
   }
   if (get_cvar_num("UW_price_CLAWS") != itemcost[CLAWS-1]){
      itemcost[CLAWS-1] = get_cvar_num("UW_price_CLAWS")
      log_amx("Item Price Override Detected : CLAWS [%d]", itemcost[CLAWS-1])
   }
   if (get_cvar_num("UW_price_CLOAK") != itemcost[CLOAK-1]){
      itemcost[CLOAK-1] = get_cvar_num("UW_price_CLOAK")
      log_amx("Item Price Override Detected : CLOAK [%d]", itemcost[CLOAK-1])
   }
   if (get_cvar_num("UW_price_MASK") != itemcost[MASK-1]){
      itemcost[MASK-1] = get_cvar_num("UW_price_MASK")
      log_amx("Item Price Override Detected : MASK [%d]", itemcost[MASK-1])
   }
   if (get_cvar_num("UW_price_IMMUNITY") != itemcost[IMMUNITY-1]){
      itemcost[IMMUNITY-1] = get_cvar_num("UW_price_IMMUNITY")
      log_amx("Item Price Override Detected : IMMUNITY [%d]", itemcost[IMMUNITY-1])
   }
   if (get_cvar_num("UW_price_FROST") != itemcost[FROST-1]){
      itemcost[FROST-1] = get_cvar_num("UW_price_FROST")
      log_amx("Item Price Override Detected : FROST [%d]", itemcost[FROST-1])
   }
   if (get_cvar_num("UW_price_HEALTH") != itemcost[HEALTH-1]){
      itemcost[HEALTH-1] = get_cvar_num("UW_price_HEALTH")
      log_amx("Item Price Override Detected : HEALTH [%d]", itemcost[HEALTH-1])
   }
   if (get_cvar_num("UW_price_TOME") != itemcost[TOME-1]){
      itemcost[TOME-1] = get_cvar_num("UW_price_TOME")
      log_amx("Item Price Override Detected : TOME [%d]", itemcost[TOME-1])
   }
   if (get_cvar_num("UW_price_RESPAWN") != itemcost2[RESPAWN-1]){
      itemcost2[RESPAWN-1] = get_cvar_num("UW_price_RESPAWN")
      log_amx("Item Price Override Detected : RESPAWN [%d]", itemcost2[RESPAWN-1])
   }
   if (get_cvar_num("UW_price_PROTECTANT") != itemcost2[PROTECTANT-1]){
      itemcost2[PROTECTANT-1] = get_cvar_num("UW_price_PROTECTANT")
      log_amx("Item Price Override Detected : PROTECTANT [%d]", itemcost2[PROTECTANT-1])
   }
   if (get_cvar_num("UW_price_HELM") != itemcost2[HELM-1]){
      itemcost2[HELM-1] = get_cvar_num("UW_price_HELM")
      log_amx("Item Price Override Detected : HELM [%d]", itemcost2[HELM-1])
   }
   if (get_cvar_num("UW_price_CAT") != itemcost2[CAT-1]){
      itemcost2[CAT-1] = get_cvar_num("UW_price_CAT")
      log_amx("Item Price Override Detected : CAT [%d]", itemcost2[CAT-1])
   }
   if (get_cvar_num("UW_price_FEATHER") != itemcost2[FEATHER-1]){
      itemcost2[FEATHER-1] = get_cvar_num("UW_price_FEATHER")
      log_amx("Item Price Override Detected : FEATHER [%d]", itemcost2[FEATHER-1])
   }
   if (get_cvar_num("UW_price_INFERNO") != itemcost2[INFERNO-1]){
      itemcost2[INFERNO-1] = get_cvar_num("UW_price_INFERNO")
      log_amx("Item Price Override Detected : INFERNO [%d]", itemcost2[INFERNO-1])
   }
   if (get_cvar_num("UW_price_REGEN") != itemcost2[REGEN-1]){
      itemcost2[REGEN-1] = get_cvar_num("UW_price_REGEN")
      log_amx("Item Price Override Detected : REGEN [%d]", itemcost2[REGEN-1])
   }
   if (get_cvar_num("UW_price_CHAMELEON") != itemcost2[CHAMELEON-1]){
      itemcost2[CHAMELEON-1] = get_cvar_num("UW_price_CHAMELEON")
      log_amx("Item Price Override Detected : CHAMELEON [%d]", itemcost2[CHAMELEON-1])
   }
   if (get_cvar_num("UW_price_MOLE") != itemcost2[MOLE-1]){
      itemcost2[MOLE-1] = get_cvar_num("UW_price_MOLE")
      log_amx("Item Price Override Detected : MOLE [%d]", itemcost2[MOLE-1])
   }
 

   return PLUGIN_CONTINUE
}
// **************************************************************************
// END set_variables subroutine
// **************************************************************************


// **************************************************************************
// BEGIN client_connect subroutine
// A new client has connected
// **************************************************************************
public client_connect(id){
   client_cmd(id, "hud_centerid 0")
   g_specMode[id] = false

   init_pdata( id, 0 )	// Initialize player data (NOT limited init mode)

   if (get_cvar_num("UW_DEBUG_code")){
      // Server set to start w/ XP and max. attribs/resists
      playerxp[id] = DEBUG_STARTXP 

      for (new j=0; j<MAX_ATTRIBS; j++)
         p_attribs[id][j] = ATTRIB_MAX_VALUE

      for (new j=0; j<MAX_RESISTS; j++)
         p_resists[id][j] = RESIST_MAX_VALUE 
   }

   if (get_cvar_num("mp_savexp"))
      xpreadytoload[id] = 1

   client_cmd(id, "echo ")
   client_cmd(id, "echo ^" *=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=* ^" ")
   client_cmd(id, "echo ^" *=-= Welcome to: Ultimate Warcraft3 (UWC3) ^" ")
   client_cmd(id, "echo ^" *=-= UWC3 Website: http://www.uwc3.com/    ^" ")
   client_cmd(id, "echo ^" *=-= UWC3 Dev Team: K2mia (admin@uwc3.com) ^" ")
   client_cmd(id, "echo ^" *=-=                Jim Rhoades (website)   ^" ")
   client_cmd(id, "echo ^" *=-=                steve french (graphics) ^" ")
   client_cmd(id, "echo ^" *=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=* ^" ")
   client_cmd(id, "echo ")


   return PLUGIN_CONTINUE
}
// **************************************************************************
// END client_connect subroutine
// **************************************************************************


// **************************************************************************
// BEGIN client_disconnect subroutine
// A client has disconnected
// **************************************************************************
public client_disconnect(id){
   g_specMode[id] = false	// Reset spectator status for player
   isburning[id] = 0		// Reset burning status for player (flamethrower)
   isnburning[id] = 0		// Reset burning status for player (napalm burn)
   ispoisonedss[id] = 0		// Reset poisoned status for player
   isdiseasedcb[id] = 0		// Reset diseased status for player
   repairs[id] = 0		// Reset number of repairs done
   mends[id] = 0		// Reset number of mends done
   he[id] = 0			// Reset he grenade status
   threwnapalm[id] = 0		// Reset status of napalm gren for round
   diedlastround[id]=false	// Reset status for player death previous round
   lastpspage[id] = 0		// Reset last player skill page read to 0
   hasmole[id] = false 		// Reset mole item global
   itemsrunning[id] = false     // Reset itemsrunning for userid
   loadedlevel[id] = 0		// Reset status for having initial level loaded
   vengeance_used[id] = 0	// Reset vengeance status

   if ( get_cvar_num("UW_lowres_default") )
      lowres[id] = true		// Reset lowres to true for player slot
   else
      lowres[id] = false		// Reset lowres boolean for thisplayer

   for (new i=0; i<32; ++i){
      // Reset due to Equipment Reincarnation
      savedweapons[id][i]=0
   }

   if (playerxp[id] < 100)
      return PLUGIN_CONTINUE

   if (get_cvar_num("mp_savexp") && !is_user_bot(id) && playerxp[id]){
      if (get_cvar_num("mp_sql"))
         sqlwrite_xp_id(id)
      else
         write_xp_id(id)
      xpreadytoload[id] = 0
   }

   return PLUGIN_CONTINUE
}
// **************************************************************************
// END client_disconnect subroutine
// **************************************************************************


// **************************************************************************
// BEGIN client_prethink subroutine
// Prethink routines 
// **************************************************************************
public client_PreThink(id) {

   if ( is_user_connected( id ) )
      entity_set_float(id, EV_FL_fuser2, 0.0)  // Disable slow down after jumping

}
// **************************************************************************
// END client_prethink subroutine
// **************************************************************************


// **************************************************************************
// BEGIN plugin_end  routine
// End of the plugin
// **************************************************************************
public plugin_end(){
   if (!warcraft3)
      return PLUGIN_CONTINUE

   if (get_cvar_num("mp_savexp"))
      write_all()

   return PLUGIN_CONTINUE
}
// **************************************************************************
// END plugin_end  routine
// **************************************************************************


// **************************************************************************
// END Ultimate WC3FT Plugin
// **************************************************************************

