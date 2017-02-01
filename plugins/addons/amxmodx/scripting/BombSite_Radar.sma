/* BombSite Radar 
   Show bombsite on radar (flash red color)
*/

/* Description::
 Many players always ask: "Where is bombsite???..."
 when they are playing with new or less play maps.
 I got how to show entities on radar from sentryguns plugin.
 So I done this one and has been tested for weeks.have fun!
*/

/* Commands::
 * bomb_site_radar 1/0     // Enable & Disable Function
 * bomb_site_radar_fqc 5   // Show on frequency (s)
*/

/* Change Log::
 * 2006-11-17
   Fixed some map show multiple marks for one bombsite problem
   (thx VEN for report)
 * 2006-11-09
   Support two type of bombsite(I only findout two of it)
   Auto disable show on for T when bomb has been planted
*/ 

/* Credits::
   help & some code from them
 * JGHG (sentryguns)
 * and more...
*/

#define PLUGIN  "BombSiteRadar"
#define VERSION "0.2.16"
#define AUTHOR  "iG_os"

#include <amxmodx>
#include <engine>
#include <csx>

#define MAX_BOMBSITE 5  // max bombsite allow to show

#define BOMB_TARGET_TYPE1 "func_bomb_target" 
#define BOMB_TARGET_TYPE2 "info_bomb_target"

new g_EntitySum
new BombSiteOrigin[MAX_BOMBSITE][3]
new g_msgHostagePos
new g_msgHostageK
new tmpTeam
new tmpID
new g_MaxPlayers
new bool:g_BombPlanted
new RADAR_CVAR
new RADAR_FQC_CVAR

public plugin_init()
{
   RADAR_CVAR = register_cvar("bomb_site_radar", "1")
   RADAR_FQC_CVAR = register_cvar("bomb_site_radar_fqc", "5")
}

public plugin_cfg()
{
   new entity = -1, Float:tmpOrigin[3]

   // BOMB_TARGET_TYPE1
   while ((entity = find_ent_by_class(entity, BOMB_TARGET_TYPE1)) && g_EntitySum < MAX_BOMBSITE)
   {
      get_brush_entity_origin(entity, tmpOrigin)
      FVecIVec(tmpOrigin, BombSiteOrigin[g_EntitySum])

      if (!is_nearby_other(BombSiteOrigin[g_EntitySum]))
         g_EntitySum++
   }

   // BOMB_TARGET_TYPE2
   entity = -1
   while ((entity = find_ent_by_class(entity, BOMB_TARGET_TYPE2)) && g_EntitySum < MAX_BOMBSITE)
   {
      entity_get_vector(entity,EV_VEC_origin,tmpOrigin)
      FVecIVec(tmpOrigin, BombSiteOrigin[g_EntitySum])

      if (!is_nearby_other(BombSiteOrigin[g_EntitySum]))
         g_EntitySum++
   }

   new pluginName[32]
   if (g_EntitySum>0 && get_pcvar_num(RADAR_CVAR))
   {
      formatex(pluginName,31,"%s-ON",PLUGIN)
      register_plugin(pluginName,VERSION,AUTHOR)
      register_event("HLTV", "event_new_round", "a", "1=0", "2=0")

      g_msgHostagePos = get_user_msgid("HostagePos")
      g_msgHostageK = get_user_msgid("HostageK")
      g_MaxPlayers = get_maxplayers()

      set_task(get_pcvar_float(RADAR_FQC_CVAR),"doTask",_,_,_,"b")
   }
   else
   {  // stop plugin when no bomesite was found
      formatex(pluginName,31,"%s-OFF",PLUGIN)
      register_plugin(pluginName,VERSION,AUTHOR)
      pause("ad")
   }
}

// ignore some close entity
bool:is_nearby_other(newOrigin[3])
{
   if (g_EntitySum)
   {
      for (new i=0;i<g_EntitySum;i++)
      {
         if (get_distance(BombSiteOrigin[i],newOrigin)<500
             && abs(BombSiteOrigin[i][2]-newOrigin[2])<100)
            return true
      }
   }

   return false
}

public event_new_round(){
   g_BombPlanted = false
}

public bomb_planted(planter){
   g_BombPlanted = true // stop show on T when bomb has been planted
}

public doTask()
{
   for (tmpID=1;tmpID<=g_MaxPlayers;tmpID++)
   {
      if (is_user_alive(tmpID))
      {
         tmpTeam = get_user_team(tmpID)
         if ( tmpTeam==2 || (tmpTeam==1 && !g_BombPlanted) )
            pos_ShowOnRadar(tmpID)
      }
   }
}

pos_ShowOnRadar(id) 
{
   for ( new i=0;i<g_EntitySum;i++)
   {  
      message_begin(MSG_ONE_UNRELIABLE, g_msgHostagePos, {0,0,0}, id)
      write_byte(id)
      write_byte(i+20)
      write_coord(BombSiteOrigin[i][0])
      write_coord(BombSiteOrigin[i][1])
      write_coord(BombSiteOrigin[i][2])
      message_end()

      message_begin(MSG_ONE_UNRELIABLE, g_msgHostageK, {0,0,0}, id)
      write_byte(i+20)
      message_end()
   }
}
