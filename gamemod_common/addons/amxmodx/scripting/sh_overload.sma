#include <amxmod.inc>
#include <xtrafun>
#include <Vexd_Utilities>
#include <superheromod.inc>

// SuperHero OvErLoAd!

// VARIABLES
new gHeroName[]="OvErLoAd"
new bool:g_hasoverloadPower[SH_MAXSLOTS+1]
new maxheal
new g_overloadTimer[SH_MAXSLOTS+1]
new gPlayerMaxHealth[SH_MAXSLOTS+1]
new gHealPoints
//new curhealth
//----------------------------------------------------------------------------------------------
// Plugin Init
public plugin_init()
{
  // Plugin Info
  register_plugin("SUPERHERO OvErLoAd","1.0","Organs Rare/Chivas/[TBS]-[]2eNeGaDe/{HOJ}Batman/JTP10181")
 
  // FIRE THE EVENT TO CREATE THIS SUPERHERO!
  if ( isDebugOn() ) server_print("Attempting to create OvErLoAd Hero")
  register_cvar("Overload_level", "9" )
  shCreateHero(gHeroName, "OveRLoAd Assistance!", "On Key Down, Once Per Round, You Gain 100 HP Instantly!", true, "Overload_level" )
  
  // REGISTER EVENTS THIS HERO WILL RESPOND TO! (AND SERVER COMMANDS)
  
  // INIT
  register_srvcmd("overload_init", "overload_init")
  shRegHeroInit(gHeroName, "overload_init")
  // KEY DOWN
  register_srvcmd("overload_kd",   "overload_kd")
  shRegKeyDown(gHeroName, "overload_kd")
  // NEW ROUND
  register_event("ResetHUD","newRound","b")
  // LOOP
  register_srvcmd("overload_loop", "overload_loop")
  //shRegLoop1P0(gHeroName, "overload_loop", "ac" ) // Alive overload Heros="ac"
  set_task(1.0,"overload_loop",0,"",0,"b") //forever loop

  // DEFAULT THE CVARS
  register_cvar("overload_level",  "9" )
  register_cvar("overload_overloadtime", "1" )
  register_cvar("overload_cooldown", "999" )      
  register_cvar("overload_healpoints", "100" )    
  register_cvar("overload_invisibility", "0")     
  gHealPoints=get_cvar_num("overload_healpoints") 

  //Makes superhero tell Overload a players max health
  register_srvcmd("overload_maxhealth", "overload_maxhealth")
  shRegMaxHealth(gHeroName, "overload_maxhealth" )
  gHealPoints = get_cvar_num("overload_healpoints")
}
//----------------------------------------------------------------------------------------------
// INIT
public overload_init()
{
  new temp[6]
  // First Argument is an id
  read_argv(1,temp,5)
  new id=str_to_num(temp)
  
  // 2nd Argument is 0 or 1 depending on whether the id has iron man powers
  read_argv(2,temp,5)
  new hasPowers=str_to_num(temp)
	
  gPlayerMaxHealth[id] = 100
  g_hasoverloadPower[id] = (hasPowers!=0)

  // REMOVE the powers if he is not Overload
  if ( !hasPowers )
  {
    overload_endmode(id)
    g_overloadTimer[id]=0
  }
  
  g_hasoverloadPower[id]=(hasPowers!=0)
  
}
//----------------------------------------------------------------------------------------------
// RESPOND TO KEYDOWN
public overload_kd() 
{ 
  new temp[6] 

  if ( !hasRoundStarted() ) return PLUGIN_HANDLED 

  // Might need to delete
  read_argv(1,temp,5) 
  new id=str_to_num(temp) 
  if ( !is_user_alive(id) ) return PLUGIN_HANDLED 
//  curhealth=get_user_health(id)
//  client_print(id,print_chat,"%d Your health", curhealth)
//  server_print("%d his health", curhealth)
  //Let them know they already used their ultimate if they have 
  if ( gPlayerUltimateUsed[id] ) 
  { 
    playSoundDenySelect(id) 
    return PLUGIN_HANDLED 
  } 
  if ( g_hasoverloadPower[id]  && ( get_user_health(id) < maxheal ) ) {
	use_health(id)
  }
  
  // Make sure they're not in the middle of overloadmode already
  
  if ( g_overloadTimer[id]>0 ) return PLUGIN_HANDLED

  g_overloadTimer[id]=get_cvar_num("overload_overloadtime")+1
  set_user_godmode(id,1)
  set_user_rendering(id,kRenderFxGlowShell,8,8,8,kRenderTransAlpha,get_cvar_num("overload_invisibility"))
  ultimateTimer(id, get_cvar_num("overload_cooldown") * 1.0)
 
  // overload Messsage 
  new message[128]
  format(message, 127, "You Have Gained 100 HP!" )
  set_hudmessage(255,0,0,-1.0,0.3,0,0.25,1.0,0.0,0.0,4)
  show_hudmessage(id, message)
  
  return PLUGIN_HANDLED 
} 
//----------------------------------------------------------------------------------------------
public overload_loop()
{
  for ( new id=1; id<=SH_MAXSLOTS; id++ ) {
    if ( g_hasoverloadPower[id] && is_user_alive(id)  ) {
      if ( g_overloadTimer[id]>0 )
	{
        g_overloadTimer[id]--
        new message[128]
        format(message, 127, "INSTANT BOOST!", g_overloadTimer[id] )
	set_user_rendering(id,kRenderFxGlowShell,255,0,0,100,50)
        set_hudmessage(255,0,0,-1.0,0.3,0,1.0,1.0,0.0,0.0,4)
        show_hudmessage( id, message)
      }
      else
      {if ( g_overloadTimer[id] == 0 )
        {
          g_overloadTimer[id]--
          overload_endmode(id)
        }
      }
    }
  }
}
//----------------------------------------------------------------------------------------------
public newRound(id)
{
  maxheal=get_user_health(id) 
//  client_print(id,print_chat,"%d Your health", maxheal)
//  server_print("%d his health", maxheal)
  gPlayerUltimateUsed[id]=false
  if (g_overloadTimer[id]>0) {
  overload_endmode(id)
  }
  return PLUGIN_HANDLED
}
//----------------------------------------------------------------------------------------------
public use_health(id)
{
	new player[1]
	player[0]=id
	shAddHPs(id, gHealPoints, maxheal )
	setScreenFlash(id, 255, 0, 0, 100, 50 )  //Red flash
	shSetGodMode(id,2)
	set_user_godmode(id, 0)
	shGlow(id,0,128,0)
	gPlayerUltimateUsed[id] = true
	return PLUGIN_HANDLED
}
//----------------------------------------------------------------------------------------------
public overload_endmode(id)
{
  g_overloadTimer[id]=0
  if ( get_user_godmode(id) == 1)
  {
    // Turn off 5 sec God
    	set_user_godmode(id,0)
	set_user_rendering(id,kRenderFxGlowShell,0,0,0,kRenderNormal,255)
	// Trun off invisability
    	set_user_rendering(id,kRenderFxGlowShell,0,0,0,kRenderTransAlpha,255)
  }
  return PLUGIN_CONTINUE
}
//----------------------------------------------------------------------------------------------
public overload_maxhealth()
{
	new id[6]
	new health[9]

	read_argv(1,id,5)
	read_argv(2,health,8)

	gPlayerMaxHealth[str_to_num(id)] = str_to_num(health)
}
//----------------------------------------------------------------------------------------------