/* AMX Mod script.
*
* Announces knife kills
*  by JustinHoMi (justin@justinmitchell.net)
*
* Changelog:
* V0.6 : Bug Fixes & Tweaks by Rav and Olo
* V0.52: Added Sound
* V0.51: Added Random Messages by ToT|V!PER
* V0.5 : First Public Release
*
*/

#include <amxmod>

#define MESSAGES   4

new messages[MESSAGES][] = {
"",
"",
"",
""
}


public knife_kill(){
   new killer_name[32], victim_name[32]
   get_user_name(read_data(1),killer_name,31)
   get_user_name(read_data(2),victim_name,31)

   set_hudmessage(200, 100, 0, -1.0, 0.30, 0, 6.0, 6.0, 0.5, 0.15, 1)
   show_hudmessage(0,messages[ random_num(0,MESSAGES-1) ],killer_name,victim_name)

   client_cmd(0,"spk misc/olhafacaaa")
}

public plugin_precache(){
	precache_sound("misc/olhafacaaa.wav")
}

public plugin_init() {
   register_plugin("Knifekill Announcer","0.111","JustinHoMi")
   register_event("DeathMsg","knife_kill","a","4&kni")
   return PLUGIN_CONTINUE
}
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1046\\ f0\\ fs16 \n\\ par }
*/
