/* AMX Mod script. 
* 
* (c) Copyright 2003, ST4life 
* This file is provided as is(no warranties). 
* 
*  Original code by OLO 
*  Rewritten by ST4life 
*/ 
      
#include <amxmod> 
#include <geoip> 

new bool:specmode[33] 

public show_position(id){ 
   if (specmode[id]){ 
      new name[32], ip[32], country[45] 
      new target = read_data(2) 
      get_user_name(target,name,31) 
      get_user_ip(target,ip,31) 
      if(geoip_country(ip,country)){ 
         set_hudmessage(255,255,255,0.02,0.88,2, 1.5, 3.0, 0.02, 5.0, 26) 
         show_hudmessage(id,"%s mora em %s",name,country) 
      } 
   } 
   return PLUGIN_CONTINUE 
} 

public set_specmode(id){ 
   new arg[12] 
   read_data(2,arg,11) 
   specmode[id] = (arg[10]=='2') ? true : false 
   return PLUGIN_CONTINUE 
} 

public client_connect(id){ 
   specmode[id] = false 
   return PLUGIN_CONTINUE      
} 

public client_disconnect(id){ 
   specmode[id] = false 
   return PLUGIN_CONTINUE 
} 

public plugin_init(){ 
   register_plugin("Spec. Country Info","0.1","ST4life") 
   register_event("TextMsg","set_specmode","bd","2&ec_Mod") 
   register_event("StatusValue","show_position","bd","1=2") 
   return PLUGIN_CONTINUE 
}
