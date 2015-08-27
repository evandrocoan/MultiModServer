/* WEEDMAN 1.0 (by Corvae aka TheRaven)

I'm new to this so please bare with me. This hero was made
because of a suggestion in the official forum. This hero
was engineered with only two days of practice at smallcode
and superhero mod so there might be a lot of ways to improve
the code. Feel free to change it to your liking. However,
the randomization of the drug effect are very carefully balanced
and I don't recommend to change them or the looptime.

CVARS - copy and paste to shconfig.cfg
--------------------------------------------------------------------------------------------------
//Weedman
Weedman_level 0				// Character level to take this "hero".
Weedman_cooldown 20			// Time to wait until you can use the special ability again
Weedman_looptime 0.5		// Looptime for all drugeffects. It is not recommended to change that.
Weedman_healpoints 5		// How many healthpoints are healed in every loop
Weedman_slapchance 0.5		// Percent chance every loop for slap effect
Weedman_jumpchance 0.5		// Percent chance every loop for automatic jump
--------------------------------------------------------------------------------------------------*/


#include <amxmod.inc>
#include <xtrafun>
#include <Vexd_Utilities>
#include <superheromod.inc>

new gHeroName[]="Weedman"
new gHasWeedmanPower[SH_MAXSLOTS+1]
new gWeedmanStatus[SH_MAXSLOTS+1]
new gWeedmanCool[SH_MAXSLOTS+1]
new gmsgSetFOV
//----------------------------------------------------------------------------------------------
public plugin_init()
{
  register_plugin("SUPERHERO Weedman","1.0","Corvae aka TheRaven")
  if ( isDebugOn() ) server_print("Attempting to create Weedman Hero")
  register_cvar("Weedman_level", "0" )
  register_cvar("Weedman_healpoints", "5" )
  register_cvar("Weedman_slapchance", "0.5" )
  register_cvar("Weedman_jumpchance", "0.5" )
  register_cvar("Weedman_cooldown", "20" )
  register_cvar("Weedman_looptime", "0.5" )
  shCreateHero(gHeroName, "Drug Rush.", "Regenerates health very fast while being drugged.", true, "Weedman_level" )
  
  // INIT
  register_srvcmd("Weedman_init", "Weedman_init") 
  shRegHeroInit(gHeroName, "Weedman_init") 
  // KEY UP
  register_srvcmd("Weedman_kd",   "Weedman_kd") 
  shRegKeyDown(gHeroName, "Weedman_kd") 
  // LOOP
  register_srvcmd("Weedman_loop", "Weedman_loop")
  set_task(get_cvar_float("Weedman_looptime"),"Weedman_loop",0,"",0,"b" )
  // NEW ROUND
  register_event("ResetHUD","Weedman_newround","b")
  // DEATH EVENT
  register_event("DeathMsg", "Weedman_death", "a") 
  
  gmsgSetFOV = get_user_msgid("SetFOV")
}
//----------------------------------------------------------------------------------------------
public Weedman_init()
{
  new temp[6] 
  read_argv(1,temp,5) 
  new id=str_to_num(temp) 
  read_argv(2,temp,5) 
  new hasPowers=str_to_num(temp) 
  gHasWeedmanPower[id]=(hasPowers!=0) 
  if ( !hasPowers && is_user_connected(id) ) Weedman_clear(id)
}
//----------------------------------------------------------------------------------------------
public Weedman_kd() { 
  new temp[6]
  read_argv(1,temp,5) 
  new id=str_to_num(temp) 

  if ( gWeedmanStatus[id] )
  {
    Weedman_clear(id)
    return PLUGIN_HANDLED
  } else {
    if ( gWeedmanCool[id] )
    {
      set_hudmessage(0, 100, 200, 0.05, 0.60, 1, 0.1, 2.0, 0.1, 0.1, 80)
      show_hudmessage(id, "Ability not yet ready again.")
      return PLUGIN_CONTINUE
    }
    gWeedmanStatus[id]=true
    gWeedmanCool[id]=true
    set_task(get_cvar_float("Weedman_cooldown"),"Weedman_cool",id)
    return PLUGIN_HANDLED
  }
  return PLUGIN_HANDLED 
} 
//----------------------------------------------------------------------------------------------
public Weedman_loop()
{
  for ( new id=1; id<=SH_MAXSLOTS; id++ )
  {
    if (  gWeedmanStatus[id] && gHasWeedmanPower[id] && is_user_alive(id)  )
    {
      sh_screenShake(id, 25, 25, 25 )
      shAddHPs(id, get_cvar_num("Weedman_healpoints"), 100)
      
      new gmsgScreenFade = get_user_msgid("ScreenFade")
      message_begin(MSG_ONE,gmsgScreenFade,{0,0,0},id)
      write_short( 15 )
      write_short( 15 )
      write_short( 12 )
      new randNum = random_num(25, 250 )
      write_byte( randNum )
      randNum = random_num(25, 250 )
      write_byte( randNum )
      randNum = random_num(25, 250 )
      write_byte( randNum )
      randNum = random_num(125, 250 )
      write_byte( randNum )
      message_end()
      
      randNum = random_num(0, 100 )
      new Weedmanchance = floatround(get_cvar_float("Weedman_slapchance") * 100)
      if ( Weedmanchance >= randNum ) user_slap(id,0)
      
      randNum = random_num(0, 100 )
      if ( randNum >= 0 ) set_user_gravity(id, 0.2)
      if ( randNum >= 30 ) set_user_gravity(id, 0.5)
      if ( randNum >= 60 ) set_user_gravity(id, 0.8)
      if ( randNum >= 90 ) set_user_gravity(id, 1.9)
      
      client_cmd(id, "-jump")
      randNum = random_num(0, 100 )
      Weedmanchance = floatround(get_cvar_float("Weedman_jumpchance") * 100)
      if ( Weedmanchance >= randNum ) client_cmd(id, "+jump")
      
      randNum = random_num(0, 120 )
      if ( randNum >= 60 ) message_begin(MSG_ONE, gmsgSetFOV, {0,0,0}, id)
      if ( randNum >= 60 ) write_byte(randNum)
      if ( randNum >= 60 ) message_end()
    }
  }
}
//----------------------------------------------------------------------------------------------
public Weedman_death()
{
  new id=read_data(2) 
  gWeedmanCool[id]=false
  Weedman_clear(id)
  return PLUGIN_HANDLED
}
//----------------------------------------------------------------------------------------------
public Weedman_newround(id)
{
  gWeedmanCool[id]=false
  Weedman_clear(id)
  return PLUGIN_HANDLED
}
//----------------------------------------------------------------------------------------------
public Weedman_clear(id)
{
    message_begin(MSG_ONE, gmsgSetFOV, {0,0,0}, id)
    write_byte(90)
    message_end()
    gWeedmanStatus[id]=false
    set_user_gravity(id, 1.0)
    client_cmd(id, "-jump")
    new gmsgScreenFade = get_user_msgid("ScreenFade")
    message_begin(MSG_ONE,gmsgScreenFade,{0,0,0},id)
    write_short( 15 )
    write_short( 15 )
    write_short( 12 )
    write_byte( 0 )
    write_byte( 0 )
    write_byte( 0 )
    write_byte( 0 )
    message_end()
    return PLUGIN_HANDLED
}
//----------------------------------------------------------------------------------------------
public Weedman_cool(id)
{
  gWeedmanCool[id]=false
  return PLUGIN_HANDLED
}