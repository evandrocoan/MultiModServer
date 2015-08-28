#include <amxmod.inc>
#include <xtrafun>
#include <superheromod.inc>

// CAPTAIN INSANO!

// CVARS
// captaini_level
// captaini_randhigh   // Random Number between 1- and randhigh - If hero level <= rand# - God Mode!
// captaini_pctperlev", "0.08" ) 
// captaini_speed", "1000" )
// captaini_armor", "600")
// captaini_health", "125")
// captaini_speed", "1000" )
// captaini_godsecs", "3")

// VARIABLES
new gHeroName[]="Captain Insano"
new bool:gHasCaptainIPowers[SH_MAXSLOTS+1]
new gPlayerLevels[SH_MAXSLOTS+1]
//----------------------------------------------------------------------------------------------
public plugin_init()
{
  // Plugin Info
  register_plugin("SUPERHERO Captain Insano","1.14.4","{HOJ}Batman/Necro/NonStop/AssKicR/Madskillz")
 
  // FIRE THE EVENT TO CREATE THIS SUPERHERO!
  if ( isDebugOn() ) server_print("Attempting to create Captain Insano Hero")
  register_cvar("captaini_level", "9" )
  shCreateHero(gHeroName, "Green Flash", "shshack says Has high speed and armor with Ultimate Green Flashes to protect him (Godmode)", false, "captaini_level" )
  
  // REGISTER EVENTS THIS HERO WILL RESPOND TO! (AND SERVER COMMANDS)
  // INIT
  register_srvcmd("captaini_init", "captaini_init")
  shRegHeroInit(gHeroName, "captaini_init")
  // OK Random Generator
  register_srvcmd("captaini_loop", "captaini_loop")
  //shRegLoop1P0(gHeroName, "captaini_loop", "ac" )
  set_task(1.0,"captaini_loop",0,"",0,"b" )
  register_srvcmd("captaini_init", "captaini_init")
  shRegHeroInit(gHeroName, "captaini_init")
  
  // DEFAULT THE CVARS
  register_cvar("captaini_pctperlev", "0.08" ) 
  register_cvar("captaini_speed", "1000" )
  register_cvar("captaini_armor", "250")
  register_cvar("captaini_health", "200")

  // Let Server know about captain insanos max speed
  
  shSetMaxSpeed(gHeroName, "captaini_speed", "[0]" )
  shSetMaxArmor(gHeroName, "captaini_armor" )
  shSetMaxHealth(gHeroName, "captaini_health" ) 

  // LEVELS
  register_srvcmd("captaini_levels", "captaini_levels")
  shRegLevels(gHeroName,"captaini_levels")

}
//----------------------------------------------------------------------------------------------
public captaini_init()
{
  new temp[6]
  // First Argument is an id
  read_argv(1,temp,5)
  new id=str_to_num(temp)
  
  // 2nd Argument is 0 or 1 depending on whether the id has captain insano skills
  read_argv(2,temp,5)
  new hasPowers=str_to_num(temp)

  if ( hasPowers )
    gHasCaptainIPowers[id]=true
  else
    gHasCaptainIPowers[id]=false  
}
//----------------------------------------------------------------------------------------------
public captaini_levels()
{
  new id[5]
  new lev[5]
  
  read_argv(1,id,4)
  read_argv(2,lev,4)
 
  gPlayerLevels[str_to_num(id)]=str_to_num(lev)
}
//----------------------------------------------------------------------------------------------
public captaini_loop()
{
  
  new id
  new players[32],count
  
  get_players(players,count,"a")
  
  for ( new x=0; x<count; x++ )
  {
    id=players[x]
    if ( gHasCaptainIPowers[id] && is_user_alive(id) )
    {
      new randNum = random_num(0, 100 )
      new heroLevel= floatround(gPlayerLevels[id] * get_cvar_float("captaini_pctperlev") * 100)
      // server_print("setting god mode: heroLevel=%d, randNum=%d", heroLevel, randNum)
      if ( heroLevel >= randNum && !get_user_godmode(id) )
      {
         // New API 5/15 - Make sure other heros setting godmode aren't interfered with (Cyclops etc.)
         shSetGodMode(id,get_cvar_num("captaini_godsecs")+3)
         setScreenFlash(id, 0, 255, 0, 10, 50 )  //Quick Green Screen Flash Letting You know about god mode
      }
    }
  }
}
//----------------------------------------------------------------------------------------------