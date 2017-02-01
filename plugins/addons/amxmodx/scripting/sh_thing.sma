/* The Thing 1.1 (by Corvae aka TheRaven)

I'm new to this so please bare with me. This hero was made
because of a suggestion in the official forum. This hero
was engineered with only two days of practice at smallcode
and superhero mod so there might be a lot of ways to improve
the code. Feel free to change it to your liking.

CVARS - copy and paste to shconfig.cfg
--------------------------------------------------------------------------------------------------
//The Thing
Thing_level 5				// Character level this hero becomes available.
Thing_weapon_percent 0.25	// Percent chance to ignore bullets
Thing_knife_percent 1.00	// Percent chance to ignore knife hits (headshots always hit)
--------------------------------------------------------------------------------------------------*/


#include <amxmod>
#include <superheromod>

new gHeroName[]="Thing" 
new gHasThingPower[SH_MAXSLOTS+1]
//----------------------------------------------------------------------------------------------
public plugin_init()
{
  register_plugin("SUPERHERO Thing","1.1","Corvae aka TheRaven")
  if ( isDebugOn() ) server_print("Attempting to create Thing Hero")
  
  register_cvar("Thing_level", "5" )
  register_cvar("Thing_weapon_percent", "0.25" )
  register_cvar("Thing_knife_percent", "1.00" )

  shCreateHero(gHeroName, "Rock Skin", "Chance to ignore bullets and knife hits.", false, "Thing_level" )

  register_srvcmd("Thing_init", "Thing_init")
  shRegHeroInit(gHeroName, "Thing_init")
  register_event("Damage", "Thing_damage", "b", "2!0")
}
//----------------------------------------------------------------------------------------------
public Thing_init()
{
  new temp[6]
  read_argv(1,temp,5)
  new id=str_to_num(temp)
  read_argv(2,temp,5)
  new hasPowers=str_to_num(temp)
  gHasThingPower[id]=(hasPowers!=0)
}
//----------------------------------------------------------------------------------------------
public Thing_damage(id)
{
  if (!shModActive() ) return PLUGIN_CONTINUE

  new damage = read_data(2)
  new weapon, bodypart, attacker = get_user_attacker(id,weapon,bodypart)

  new randNum = random_num(0, 100 )
  new ThingLevel = floatround(get_cvar_float("Thing_weapon_percent") * 100)
  if ( ThingLevel >= randNum && is_user_alive(id) && id != attacker && gHasThingPower[id] && weapon!=CSW_KNIFE ) {
    shAddHPs(id, damage, 500 )
    set_hudmessage(0, 100, 200, 0.05, 0.60, 1, 0.1, 2.0, 0.1, 0.1, 80)
    show_hudmessage(id, "Bullet bounces off your rock skin.")
  }
  randNum = random_num(0, 100 )
  ThingLevel = floatround(get_cvar_float("Thing_knife_percent") * 100)
  if ( ThingLevel >= randNum && is_user_alive(id) && id != attacker && gHasThingPower[id] && weapon==CSW_KNIFE && bodypart!=HIT_HEAD ) {
    shAddHPs(id, damage, 500 )
    set_hudmessage(0, 100, 200, 0.05, 0.63, 1, 0.1, 2.0, 0.1, 0.1, 81)
    show_hudmessage(id, "Your rock skin blocks the knife attack.")
  }

  return PLUGIN_CONTINUE
}