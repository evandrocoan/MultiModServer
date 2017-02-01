#include <amxmod.inc>
#include <xtrafun>
#include <superheromod.inc>


// VARIABLES
new gHeroName[]="Black Mage"
new bool:g_hasBlackMagePowers[SH_MAXSLOTS+1]
new g_blackMageTimer[SH_MAXSLOTS+1]
//----------------------------------------------------------------------------------------------
public plugin_init()
{
  // Plugin Info
  register_plugin("SUPERHERO Black Mage","1.0","scoutPractice")
 
  // FIRE THE EVENT TO CREATE THIS SUPERHERO!
  register_cvar("blackmage_level", "8" )
  shCreateHero(gHeroName, "Death and Decay!", "Death and Decay!", true, "blackmage_level" )
  
  // REGISTER EVENTS THIS HERO WILL RESPOND TO! (AND SERVER COMMANDS)
  register_event("ResetHUD","newRound","b")
  
  // KEY DOWN
  register_srvcmd("blackmage_kd", "blackmage_kd")
  shRegKeyDown(gHeroName, "blackmage_kd")
  
  register_srvcmd("blackmage_loop", "blackmage_loop")
  //  shRegLoop1P0(gHeroName, "blackmage_loop", "ac" ) // Alive blackmageHeros="ac"
  set_task(1.0,"blackmage_loop",0,"",0,"b") //forever loop
  
  // INIT
  register_srvcmd("blackmage_init", "blackmage_init")
  shRegHeroInit(gHeroName, "blackmage_init")

  // DEFAULT THE CVARS
  register_cvar("blackmage_cooldown", "45" )
  register_cvar("blackmage_time", "5" )
  register_cvar("blackmage_decayradius", "150" )
  register_cvar("blackmage_decaydamage", "15" )
  register_cvar("blackmage_instantdamage", "20" )
  register_cvar("blackmage_deathradius", "300" )
  register_cvar("blackmage_deathdamage", "25" )
}
//----------------------------------------------------------------------------------------------
public blackmage_init()
{
  new temp[6]
  // First Argument is an id
  read_argv(1,temp,5)
  new id=str_to_num(temp)
  
  // 2nd Argument is 0 or 1 depending on whether the id has iron man powers
  read_argv(2,temp,5)
  new hasPowers=str_to_num(temp)
  
  g_hasBlackMagePowers[id]=(hasPowers!=0)
  set_user_rendering(id,kRenderFxGlowShell,64,64,64,kRenderTransAlpha,100)
  
  if ( !hasPowers )
  {
    if ( is_user_alive(id) && g_blackMageTimer[id]>=0 && g_hasBlackMagePowers[id] )
    {
      blackmage_endmode(id)
    }
  }
  else
  {
    g_blackMageTimer[id]=-1  // Make sure looop doesn't fire for em...
    set_user_rendering(id,kRenderFxGlowShell,0,0,0,kRenderTransAlpha,255)
  }

}
//----------------------------------------------------------------------------------------------
public newRound(id)
{
  gPlayerUltimateUsed[id]=false
  if (g_hasBlackMagePowers[id]) {
    blackmage_setrender(id)
    gPlayerUltimateUsed[id]=false
  }
  g_blackMageTimer[id]=0
  return PLUGIN_HANDLED
}
//----------------------------------------------------------------------------------------------
public blackmage_setrender(id)
{
  set_user_rendering(id,kRenderFxGlowShell,64,64,64,kRenderTransAlpha,100)
}
//----------------------------------------------------------------------------------------------
// RESPOND TO KEYDOWN
public blackmage_kd() 
{ 
  new temp[6]
  
  if ( !hasRoundStarted() ) return PLUGIN_HANDLED
  
  // First Argument is an id with Carnage Powers!
  read_argv(1,temp,5)
  new id=str_to_num(temp)
  if ( !is_user_alive(id) ) return PLUGIN_HANDLED
   
    
  // Let them know they already used their ultimate if they have
  if ( gPlayerUltimateUsed[id] )
  {
    playSoundDenySelect(id)
    return PLUGIN_HANDLED 
  }  
  
  if ( !is_user_alive(id) ) return PLUGIN_HANDLED
  
  // Make sure they're not in the middle of it already
  if ( g_blackMageTimer[id]>0 ) return PLUGIN_HANDLED
  
  
  g_blackMageTimer[id]=get_cvar_num("blackmage_time")+1
  
  new userOrigin[3]
  new victimOrigin[3]
  new distanceBetween
  
  new blackMageCooldown=get_cvar_num("blackmage_cooldown")
  new blackMageDeathRadius=get_cvar_num("blackmage_deathradius")
  
  ultimateTimer(id, blackMageCooldown * 1.0)
  g_blackMageTimer[id]=get_cvar_num("blackmage_time")+1
  
  get_user_origin(id,userOrigin)
  for ( new x=1; x<=SH_MAXSLOTS; x++) 
  {
     if ( (is_user_alive(x) && get_user_team(id)!=get_user_team(x)) || x!=id )
     {
       if (!g_hasBlackMagePowers[x])
       {
         get_user_origin(x,victimOrigin)
         distanceBetween = get_distance(userOrigin, victimOrigin )
         if ( distanceBetween < blackMageDeathRadius )
         {
           if (!g_hasBlackMagePowers[x]) {
             blackmage_instant(x, id)
           }
           else {
             blackmage_noinstant(x, id)
           }
         }
       }
     }
  }

  new message[128]
  format(message, 127, "Death and Decay!  Your enemies are withering!" )
  set_hudmessage(255,0,0,-1.0,1.0,0,0.25,1.0,0.0,0.0,4)
  show_hudmessage(id, message)
  return PLUGIN_HANDLED
}
//----------------------------------------------------------------------------------------------   
public blackmage_loop()
{
  for ( new id=1; id<=SH_MAXSLOTS; id++ )
  {
    if ( g_hasBlackMagePowers[id] && is_user_alive(id)  ) 
    {
      blackmage_setrender(id)
      // DEATH SETTINGS START HERE
      if ( g_blackMageTimer[id]>0 )
      {
        g_blackMageTimer[id]--
        new message[128]
        format(message, 127, "%d seconds left of Death and Decay!", g_blackMageTimer[id] )
        set_hudmessage(255,0,0,-1.0,1.0,0,1.0,1.0,0.0,0.0,4)
        show_hudmessage( id, message)
        set_user_rendering(id,kRenderFxGlowShell,255,0,0,kRenderTransAlpha,255)       
        
        new uOrigin[3]
        new vOrigin[3]
        new dBetween
        
        new blackMageDeathRadius=get_cvar_num("blackmage_deathradius")
        get_user_origin(id,uOrigin)
        for ( new x=1; x<=SH_MAXSLOTS; x++) 
        {
          if ( (is_user_alive(x) && get_user_team(id)!=get_user_team(x)) || x!=id )
          {
            get_user_origin(x,vOrigin)
            dBetween = get_distance(uOrigin, vOrigin )
            if ( dBetween < blackMageDeathRadius )
            {
              if (!g_hasBlackMagePowers[x])
              {
                blackmage_death(x, id)
              }
              else {
                blackmage_nodeath(x, id)
              }
            }
          }
        }
      }
      else
      {
        if ( g_blackMageTimer[id] == 0 )
        {
          g_blackMageTimer[id]--
          blackmage_endmode(id)
        }
      }
      // DEATH SETTINGS STOP HERE
      // DECAY SETTINGS START HERE
      
      new userOrigin[3]
      new enemyOrigin[3]
      new distance
      new blackMageDecayRadius=get_cvar_num("blackmage_decayradius")
      get_user_origin(id, userOrigin)
      for ( new eid=1; eid<=SH_MAXSLOTS; eid++) 
      {
        if ( (is_user_alive(eid) && get_user_team(id)!=get_user_team(eid)) || eid!=id )
        {
          get_user_origin(eid,enemyOrigin)
          distance = get_distance(userOrigin, enemyOrigin )
          if ( distance < blackMageDecayRadius )
          {
            if (!g_hasBlackMagePowers[eid])
            {
              blackmage_decay(eid, id)
            }
            else
            {
              blackmage_nodecay(eid, id)
            }
          }
        }
      }
      // DECAY SETTINGS STOP HERE
    }
  }
}
// All Black Mage Effects START HERE
//----------------------------------------------------------------------------------------------
public blackmage_instant(x, id)
{
  new blackMageInstantDamage=get_cvar_num("blackmage_instantdamage")
  shExtraDamage( x, id, blackMageInstantDamage, "Black Mage Instant Damage" )
}
//----------------------------------------------------------------------------------------------
public blackmage_noinstant(x, id)
{
  new nodamage[128]
  format(nodamage, 127, "You are immune to all Black Mage effects!" )
  set_hudmessage(255,0,0,-1.0,0.3,0,1.0,1.0,0.0,0.0,4)
  show_hudmessage( x, nodamage)
}
//----------------------------------------------------------------------------------------------
public blackmage_death(x, id)
{
  new blackMageDeathDamage=get_cvar_num("blackmage_deathdamage")
//  shExtraDamage( x, id, blackMageDeathDamage, "Black Mage Death" )
  new enemyHealth=get_user_health(x)
  new newHP=enemyHealth-blackMageDeathDamage
  set_user_health(x, newHP)
  return PLUGIN_HANDLED
}
//----------------------------------------------------------------------------------------------
public blackmage_nodeath(x, id)
{
  new nodeath[128]
  format(nodeath, 127, "You are immune to all Black Mage Death effects!" )
  set_hudmessage(255,0,0,-1.0,-0.3,0,1.0,1.0,0.0,0.0,4)
  show_hudmessage( x, nodeath)
}
//----------------------------------------------------------------------------------------------
public blackmage_decay(eid, id)
{
  new blackMageDecayDamage=get_cvar_num("blackmage_decaydamage")
//  shExtraDamage( x, id, blackMageDecayDamage, "Black Mage Decay" )
  new enemyHealth=get_user_health(eid)
  new newHP=enemyHealth-blackMageDecayDamage
  set_user_health(eid, newHP)
  return PLUGIN_HANDLED
}
//----------------------------------------------------------------------------------------------
public blackmage_nodecay(eid, id)
{
  new nodecay[128]
  format(nodecay, 127, "You are immune to all Black Mage Decay effects!" )
  set_hudmessage(255,0,0,-1.0,-1.0,0,1.0,1.0,0.0,0.0,4)
  show_hudmessage( eid, nodecay)
}
// ALL Black Mage Effects END HERE
//----------------------------------------------------------------------------------------------
public blackmage_endmode(id)
{
  g_blackMageTimer[id]=0
}
//----------------------------------------------------------------------------------------------
//----------------------------------------------------------------------------------------------