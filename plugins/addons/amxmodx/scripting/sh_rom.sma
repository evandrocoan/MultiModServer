#include <amxmod.inc>
#include <xtrafun>
#include <superheromod.inc>

// Rom!

// CVARS
// rom_level
// rom_cooldown
// rom_sensetime


// VARIABLES
new gHeroName[]="Rom"
new bool:gHasRomPower[SH_MAXSLOTS+1]
new beam
new gRomTimer[SH_MAXSLOTS+1]
//----------------------------------------------------------------------------------------------
public plugin_init()
{
  // Plugin Info
  register_plugin("SUPERHERO Rom V1","1.0","Freecode & T(+)rget")
 
  // FIRE THE EVENT TO CREATE THIS SUPERHERO!
  register_cvar("rom_level", "0" )
  shCreateHero(gHeroName, "Senses", "Know where the player is", true, "rom_level" )
  
  // REGISTER EVENTS THIS HERO WILL RESPOND TO! (AND SERVER COMMANDS)
  register_event("ResetHUD","newRound","b")
  register_event("DeathMsg","death","a")
  // LOOP
  register_srvcmd("rom_loop", "rom_loop")
  set_task(1.0,"rom_loop",0,"",0,"b")
  // KEY DOWN
  register_srvcmd("rom_kd", "rom_kd")
  shRegKeyDown(gHeroName, "rom_kd")
  
  // INIT
  register_srvcmd("rom_init", "rom_init")
  shRegHeroInit(gHeroName, "rom_init")
  
  // DEFAULT THE CVARS
  register_cvar("rom_cooldown", "15" )
  register_cvar("rom_sensetime","20")
}
//----------------------------------------------------------------------------------------------
public rom_init() 
{ 
  new temp[6]
  // First Argument is an id
  read_argv(1,temp,5)
  new id=str_to_num(temp)
  
  // 2nd Argument is 0 or 1 depending on whether the id has iron man powers
  read_argv(2,temp,5)
  new hasPowers=str_to_num(temp)
  
  if ( !hasPowers )
  {
    rom_endtrack(id)
    gRomTimer[id]=0
  }
    
  gHasRomPower[id]=(hasPowers!=0)


} 
//----------------------------------------------------------------------------------------------
public newRound(id)
{
  gPlayerUltimateUsed[id]=false
  message_begin(MSG_ONE, SVC_TEMPENTITY, {0,0,0}, id) 
  write_byte(99) // TE_KILLBEAM 
  write_short(id) 
  message_end()
  gRomTimer[id]=0
  return PLUGIN_HANDLED
}
//----------------------------------------------------------------------------------------------
public death()
{
new id=read_data(2)
message_begin(MSG_ONE, SVC_TEMPENTITY, {0,0,0}, id) 
write_byte(99) // TE_KILLBEAM 
write_short(id) 
message_end()
gRomTimer[id]=0
}
//----------------------------------------------------------------------------------------------
public rom_kd() 
{ 
   new temp[6] 
   if(!hasRoundStarted()) return PLUGIN_HANDLED 

   // First Argument is an id with Carnage Powers! 
   read_argv(1, temp, 5) 
   new id = strtonum(temp) 
   if(!is_user_alive(id)) return PLUGIN_HANDLED 

   // Let them know they already used their ultimate if they have 
   if(gPlayerUltimateUsed[id]) 
   { 
      playSoundDenySelect(id) 
      return PLUGIN_HANDLED 
   } 

   // Make sure they're not in the middle of it already 
   if(gRomTimer[id] > 0) return PLUGIN_HANDLED 

   gRomTimer[id] = get_cvar_num("rom_sensetime") + 1 
   ultimateTimer(id, get_cvar_num("rom_cooldown") * 1.0)
   new var = get_cvar_num("rom_sensetime")*10

   for(new x = 1; x <= SH_MAXSLOTS; x++) 
   { 
      if(x != id && is_user_alive(x) && get_user_team(x) != get_user_team(id)) 
      { 
         message_begin(MSG_ONE, SVC_TEMPENTITY, {0,0,0}, id) 
         write_byte(8) // TE_BEAMENTS 
         write_short(id) // Start Entity 
         write_short(x) // End Entity 
         write_short(beam) // Sprite Index 
         write_byte(1) // Starting Frame 
         write_byte(1) // Frame Rate in 0.1's 
         write_byte(var) // Life in 0.1's 
         write_byte(10) // Line width in 0.1's 
         write_byte(0) // Noise amplitude in 0.01's 
         write_byte(0) // Red 
         write_byte(255) // Green 
         write_byte(0) // Blue 
         write_byte(100) // Brightness 
         write_byte(0) // Scroll speed in 0.1's 
         message_end()
         new idorigin[3]
         new xorigin[3]
         new xname[32]
         get_user_origin(id,idorigin)
         get_user_origin(x,xorigin)
         get_user_name(x,xname,31)
         new distance=get_distance(idorigin,xorigin)
         set_hudmessage(255,0,0,1.0,35.0,0,0.0,3.0,0.1,0.2,4)
         show_hudmessage(id,"%s is %i meters away from you.",xname,distance)
      } 
   } 
   return PLUGIN_HANDLED 
} 
//----------------------------------------------------------------------------------------------
public rom_loop()
{
  for ( new id=1; id<=SH_MAXSLOTS; id++ )
  {
    if ( gHasRomPower[id] && is_user_alive(id)  ) 
    {
      if ( gRomTimer[id]>0 )
      {
        gRomTimer[id]--
        new message[128]
        format(message, 127, "%d seconds left of Tracking device ", gRomTimer[id] )
        set_hudmessage(255,0,0,-1.0,0.3,0,1.0,1.0,0.0,0.0,4)
        show_hudmessage( id, message)
        new var = get_cvar_num("rom_sensetime")*10 

        for(new x = 1; x <= SH_MAXSLOTS; x++) 
        { 
          if(x != id && is_user_alive(x) && get_user_team(x) != get_user_team(id)) 
          { 
             message_begin(MSG_ONE, SVC_TEMPENTITY, {0,0,0}, id) 
             write_byte(8) // TE_BEAMENTS 
             write_short(id) // Start Entity 
             write_short(x) // End Entity 
             write_short(beam) // Sprite Index 
             write_byte(1) // Starting Frame 
             write_byte(1) // Frame Rate in 0.1's 
             write_byte(var) // Life in 0.1's 
             write_byte(10) // Line width in 0.1's 
             write_byte(0) // Noise amplitude in 0.01's 
             write_byte(0) // Red 
             write_byte(255) // Green 
             write_byte(0) // Blue 
             write_byte(100) // Brightness 
             write_byte(0) // Scroll speed in 0.1's 
             message_end()
             new idorigin[3]
             new xorigin[3]
             new xname[32]
             get_user_origin(id,idorigin)
             get_user_origin(x,xorigin)
             get_user_name(x,xname,31)
             new distance=get_distance(idorigin,xorigin)
             set_hudmessage(255,0,0,1.0,35.0,0,0.0,3.0,0.1,0.2,4)
             show_hudmessage(id,"%s is %i meters away from you.",xname,distance)
          } 
       } 
      }
      else
      {
        if ( gRomTimer[id] == 0 )
        {
          gRomTimer[id]--
          rom_endtrack(id)
        }
      }
    }
  }
}
//----------------------------------------------------------------------------------------------
public rom_endtrack(id) 
{ 
   message_begin(MSG_ONE, SVC_TEMPENTITY, {0,0,0}, id) 
   write_byte(99) // TE_KILLBEAM 
   write_short(id) 
   message_end()
}
//----------------------------------------------------------------------------------------------
public plugin_precache()
{
beam = precache_model("sprites/xenobeam.spr")
}
//----------------------------------------------------------------------------------------------