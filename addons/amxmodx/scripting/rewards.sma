
/* AMX Mod
*   Tuff kill Rewards
* 
*  Rewards Headshots w/ 2 frags +10 health 
*  Rewards Knife Kills w/ +25 health   
*    
*       by mongo 
*  the_mongo@hotmail.com
*  
*  Modified from Head Shot Location announcer
*/

#include <amxmod>
#include <fun>

#define MESSAGES   1


new messages[MESSAGES][] = {
""
}

public hs_kill(){
   if(!get_cvar_num("amx_hsreward")) return PLUGIN_HANDLED 
   new killer = read_data(1)
   if (killer == 0)  
      return PLUGIN_CONTINUE
      
   new killer_name[32]
   get_user_name(read_data(1),killer_name,31)
   set_hudmessage(255, 255, 000, -1.0, 0.12, 0, 6.0, 6.0, 0.5, 0.15, 3)
   show_hudmessage(0,messages[ random_num(0,MESSAGES-1) ],killer_name)
   set_user_frags(killer, get_user_frags(killer)+0)
   set_user_health(killer, get_user_health(killer)+20)
   return PLUGIN_CONTINUE
}

public knife_kill(){
   if(!get_cvar_num("amx_knifereward")) return PLUGIN_HANDLED 
   new killer = read_data(1)
   if (killer == 0) 
      return PLUGIN_CONTINUE
      
   new killer_name[32]
   get_user_name(read_data(1),killer_name,31)
   set_hudmessage(255, 255, 000, -1.0, 0.12, 0, 6.0, 6.0, 0.5, 0.15, 3)
   show_hudmessage(0,messages[ random_num(0,MESSAGES-1) ],killer_name)
   set_user_health(killer, get_user_health(killer)+20)
   return PLUGIN_CONTINUE
}

public plugin_init() {
   register_plugin("Tuff kill Rewards","0.3","mongo")
   register_event("DeathMsg","hs_kill","ade","3=1","5=0")
   register_event("DeathMsg","knife_kill","ade","3=1","5=0")
   register_cvar("amx_hsreward", "1")
   register_cvar("", "1")
   return PLUGIN_CONTINUE
}




/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1046\\ f0\\ fs16 \n\\ par }
*/
