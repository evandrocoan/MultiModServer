#include <amxmod.inc>
#include <Vexd_Utilities>
#include <superheromod.inc>


// VARIABLES
new gHeroName[]="Emperor Palpatine"
new bool:g_haspalpatinePowers[SH_MAXSLOTS+1]
new g_palpatineTimer[SH_MAXSLOTS+1]
new gSpriteLightning
//----------------------------------------------------------------------------------------------
public plugin_init()
{
  // Plugin Info
  register_plugin("SUPERHERO Emperor Palpatine","1.0","FireWalker877")
 
  // FIRE THE EVENT TO CREATE THIS SUPERHERO!
  register_cvar("palpatine_level", "8" )
  shCreateHero(gHeroName, "Dark Lord", "Death and Decay!", true, "palpatine_level" )
  
  // REGISTER EVENTS THIS HERO WILL RESPOND TO! (AND SERVER COMMANDS)
  register_event("ResetHUD","newRound","b")
  
  // KEY DOWN
  register_srvcmd("palpatine_kd", "palpatine_kd")
  shRegKeyDown(gHeroName, "palpatine_kd")
  
  register_srvcmd("palpatine_loop", "palpatine_loop")
  //  shRegLoop1P0(gHeroName, "palpatine_loop", "ac" ) // Alive palpatineHeros="ac"
  set_task(1.0,"palpatine_loop",0,"",0,"b") //forever loop
  
  // INIT
  register_srvcmd("palpatine_init", "palpatine_init")
  shRegHeroInit(gHeroName, "palpatine_init")

  // DEFAULT THE CVARS
  register_cvar("palpatine_cooldown", "45" )
  register_cvar("palpatine_time", "5" )
  register_cvar("palpatine_decayradius", "300" )
  register_cvar("palpatine_decaydamage", "15" )
  register_cvar("palpatine_instantdamage", "20" )
  register_cvar("palpatine_deathradius", "300" )
  register_cvar("palpatine_deathdamage", "25" )
  register_cvar("palpatine_life", "15")
  register_cvar("palpatine_noise", "70")
  register_cvar("palpatine_scroll", "15")
}
//----------------------------------------------------------------------------------------------
public plugin_precache()
{
	gSpriteLightning = precache_model("sprites/lgtning.spr")
}

public palpatine_init()
{
  new temp[6]
  // First Argument is an id
  read_argv(1,temp,5)
  new id=str_to_num(temp)
  
  // 2nd Argument is 0 or 1 depending on whether the id has iron man powers
  read_argv(2,temp,5)
  new hasPowers=str_to_num(temp)
  
  g_haspalpatinePowers[id]=(hasPowers!=0)
  set_user_rendering(id,kRenderFxGlowShell,0,0,0,kRenderTransAlpha,255)
  
  if (!hasPowers)
  {
     if ( is_user_alive(id) && g_palpatineTimer[id]>=0 && g_haspalpatinePowers[id] )
     {
	   palpatine_endmode(id)
     }
  }
  else
  {
   	g_palpatineTimer[id]=-1  // Make sure looop doesn't fire for em...
   	set_user_rendering(id,kRenderFxGlowShell,0,0,0,kRenderTransAlpha,255)
  }

}
//----------------------------------------------------------------------------------------------
public newRound(id)
{
  gPlayerUltimateUsed[id]=false
  if (g_haspalpatinePowers[id]) {
    gPlayerUltimateUsed[id]=false
  }
  g_palpatineTimer[id]=0
  return PLUGIN_HANDLED
}
//----------------------------------------------------------------------------------------------
// RESPOND TO KEYDOWN
public palpatine_kd() 
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
  if ( g_palpatineTimer[id]>0 ) return PLUGIN_HANDLED
  
  
  g_palpatineTimer[id]=get_cvar_num("palpatine_time")+1
  
  new userOrigin[3]
  new victimOrigin[3]
  new distanceBetween
  
  new palpatineCooldown=get_cvar_num("palpatine_cooldown")
  new palpatineDeathRadius=get_cvar_num("palpatine_deathradius")
  
  ultimateTimer(id, palpatineCooldown * 1.0)
  g_palpatineTimer[id]=get_cvar_num("palpatine_time")+1
  
  get_user_origin(id,userOrigin)
  for ( new x=1; x<=SH_MAXSLOTS; x++) 
  {
     if ( (is_user_alive(x) && get_user_team(id)!=get_user_team(x)) || x!=id )
     {
       if (!g_haspalpatinePowers[x])
       {
         get_user_origin(x, victimOrigin)
         distanceBetween = get_distance(userOrigin, victimOrigin)
         if ( distanceBetween < palpatineDeathRadius )
         {
           if (!g_haspalpatinePowers[x]) {
             palpatine_instant(x, id)
           }
           else {
             palpatine_noinstant(x, id)
           }
         }
       }
     }
  }

  new message[128]
  format(message, 127, "If you will not be turned, you will be destroyed!" )
  set_hudmessage(175,0,255,-1.0,1.0,0,0.25,1.0,0.0,0.0,4)
  show_hudmessage(id, message)
  return PLUGIN_HANDLED
}
//----------------------------------------------------------------------------------------------   
public palpatine_loop()
{
  for ( new id=1; id<=SH_MAXSLOTS; id++ )
  {
    if ( g_haspalpatinePowers[id] && is_user_alive(id)  ) 
    {
      // DEATH SETTINGS START HERE
      if ( g_palpatineTimer[id]>0 )
      {
        g_palpatineTimer[id]--
        new message[128]
        format(message, 127, "%d seconds left of Sith power!", g_palpatineTimer[id] )
        set_hudmessage(175,0,255,-1.0,1.0,0,1.0,1.0,0.0,0.0,4)
        show_hudmessage( id, message)
        set_user_rendering(id,kRenderFxGlowShell,175,0,255,kRenderTransAlpha,25)       
        
        new uOrigin[3]
        new vOrigin[3]
        new dBetween
        
        new palpatineDeathRadius=get_cvar_num("palpatine_deathradius")
        get_user_origin(id,uOrigin)
        for ( new x=1; x<=SH_MAXSLOTS; x++) 
        {
          if ( (is_user_alive(x) && get_user_team(id)!=get_user_team(x)) && x!=id )
          {
            get_user_origin(x,vOrigin)
            dBetween = get_distance(uOrigin, vOrigin )
            if ( dBetween < palpatineDeathRadius )
            {
              if (!g_haspalpatinePowers[x])
              {
                palpatine_death(x, id)
              }
              else {
                palpatine_nodeath(x, id)
              }
            }
          }
        }
      }
      else
      {
        if ( g_palpatineTimer[id] == 0 )
        {
          g_palpatineTimer[id]--
          palpatine_endmode(id)
        }
      }
      // DEATH SETTINGS STOP HERE
      // DECAY SETTINGS START HERE
      
      new userOrigin[3]
      new enemyOrigin[3]
      new distance
      new palpatineDecayRadius=get_cvar_num("palpatine_decayradius")
      get_user_origin(id, userOrigin)
      for ( new eid=1; eid<=SH_MAXSLOTS; eid++) 
      {
        if ( (is_user_alive(eid) && get_user_team(id)!=get_user_team(eid)) && eid!=id )
        {
          get_user_origin(eid,enemyOrigin)
          distance = get_distance(userOrigin, enemyOrigin )
          if ( distance < palpatineDecayRadius )
          {
            if (!g_haspalpatinePowers[eid] && get_user_health(eid) > 25)
            {
              palpatine_decay(eid, id)
            }
            else
            {
              palpatine_nodecay(eid, id)
            }
          }
        }
      }
      // DECAY SETTINGS STOP HERE
    }
  }
}
// All Palpatine Effects START HERE
//----------------------------------------------------------------------------------------------
public lightning_effect(id, eid, linewidth)
{
	message_begin( MSG_BROADCAST, SVC_TEMPENTITY )
	write_byte( 8 )
	write_short(id)				// start entity
	write_short(eid)				// entity
	write_short(gSpriteLightning)		// model
	write_byte( 0 ) 				// starting frame
	write_byte( 15 )  			// frame rate
	write_byte( get_cvar_num("palpatine_life") )  			// life
	write_byte( linewidth )  		// line width
	write_byte( get_cvar_num("palpatine_noise") )  			// noise amplitude
	write_byte( 175 )				// r, g, b
	write_byte( 0 )				// r, g, b
	write_byte( 255 )				// r, g, b
	write_byte( 255 )				// brightness
	write_byte( get_cvar_num("palpatine_scroll") )				// scroll speed
	message_end()
}

public palpatine_instant(x, id)
{
  new palpatineInstantDamage=get_cvar_num("palpatine_instantdamage")
  shExtraDamage( x, id, palpatineInstantDamage, "Emperor Palpatine Instant Damage" )
}
//----------------------------------------------------------------------------------------------
public palpatine_noinstant(x, id)
{
  new nodamage[128]
  format(nodamage, 127, "You are immune to the Dark Side of the force!" )
  set_hudmessage(175,0,255,-1.0,0.3,0,1.0,1.0,0.0,0.0,4)
  show_hudmessage( x, nodamage)
}
//----------------------------------------------------------------------------------------------
public palpatine_death(x, id)
{
  new palpatineDeathDamage=get_cvar_num("palpatine_deathdamage")
//  shExtraDamage( x, id, palpatineDeathDamage, "Palpatine Death" )
  new enemyHealth=get_user_health(x)
  new newHP=enemyHealth-palpatineDeathDamage
  set_user_health(x, newHP)
  return PLUGIN_HANDLED
}
//----------------------------------------------------------------------------------------------
public palpatine_nodeath(x, id)
{
  new nodeath[128]
  format(nodeath, 127, "The Force is strong with you, indeed!" )
  set_hudmessage(175,0,255,-1.0,-0.3,0,1.0,1.0,0.0,0.0,4)
  show_hudmessage( x, nodeath)
}
//----------------------------------------------------------------------------------------------
public palpatine_decay(eid, id)
{
  new palpatineDecayDamage=get_cvar_num("palpatine_decaydamage")
//  shExtraDamage( x, id, palpatineDecayDamage, "Palpatine Decay" )
  new enemyHealth=get_user_health(eid)
  new newHP=enemyHealth-palpatineDecayDamage
  lightning_effect(id, eid, 2)
  set_user_health(eid, newHP)
  return PLUGIN_HANDLED
}
//----------------------------------------------------------------------------------------------
public palpatine_nodecay(eid, id)
{
  new nodecay[128]
  new skywalker[21] 
  get_user_name(id,skywalker,20) 
  format(nodecay, 127, "Fear not the Dark Side, young %s!", skywalker)
  set_hudmessage(175,0,255,-1.0,-1.0,0,1.0,1.0,0.0,0.0,4)
  show_hudmessage( eid, nodecay)
}
// ALL Palpatine Mage Effects END HERE
//----------------------------------------------------------------------------------------------
public palpatine_endmode(id)
{
  g_palpatineTimer[id]=0
}
//----------------------------------------------------------------------------------------------
//----------------------------------------------------------------------------------------------