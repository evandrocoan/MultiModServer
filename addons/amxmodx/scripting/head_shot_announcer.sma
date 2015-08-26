
/* AMX Mod script.
*
* Announces Head Shots at location of killer and victim hears 'I bet that stings a little' sound
*  by {OmNi}Eternal (eternal@clanomni.net)
*
*  Modifed from JustinHoMi's KnifeKill
*  Headshot messages from StatsME
*/

#include <amxmod>

#define MESSAGES   7

new messages[MESSAGES][] = {
"",
"",
"",
"",
"",
"",
""}

public hs_kill(){
   new killer = read_data(1)
   new victim = read_data(2)


   if (killer == 0)  //if attacker is a bomb
      return PLUGIN_CONTINUE
      
   new killer_name[32], victim_name[32]
   get_user_name(read_data(1),killer_name,31)
   get_user_name(read_data(2),victim_name,31)

   set_hudmessage(200, 50, 0, -1.0, 0.20, 0, 6.0, 6.0, 0.5, 0.15, 3)
   show_hudmessage(0,messages[ random_num(0,MESSAGES-1) ],killer_name,victim_name)
   emit_sound(victim,CHAN_ITEM,"misc/tomouhead.wav", 1.0, ATTN_NORM, 0, PITCH_NORM)
   emit_sound(killer,CHAN_VOICE,"misc/tomouhead.wav", 1.0, ATTN_NORM, 0, PITCH_NORM)

   return PLUGIN_CONTINUE

}
public plugin_precache()
{
	precache_sound("misc/tomouhead.wav")
	return PLUGIN_CONTINUE
}

public plugin_init() {
   register_plugin("Head Shot Locational Announcer","0.9","{OmNi}Eternal")
   register_event("DeathMsg","hs_kill","ade","3=1","5=0")
   return PLUGIN_CONTINUE
}

