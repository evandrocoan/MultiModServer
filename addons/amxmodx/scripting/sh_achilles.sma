#include <amxmod.inc> 
#include <superheromod.inc> 

// Achilles Superhero

// CVARS 
// achilles_level 8     - level at which he becomes available
// achilles_dmgmult 3.0 - multiplier of the damage he takes in the left leg; set to 100 for instant death

// VARIABLES 
new gHeroName[] = "Achilles" 
new bool:gHasAchillesPowers[SH_MAXSLOTS + 1] 

public plugin_init() 
{ 
   // Plugin Info 
   register_plugin("SUPERHERO Achilles", "1.0", "Mydas") 
   register_cvar("achilles_level", "8" ) 
   shCreateHero(gHeroName, "Immortality", "You can get hit only in the left leg - careful if you fall !", false, "achilles_level") 
  
   // REGISTER EVENTS THIS HERO WILL RESPOND TO! (AND SERVER COMMANDS) INIT 
   register_srvcmd("achilles_init", "achilles_init") 
   register_event("Damage", "achilles_damage", "b", "2!0")  

   shRegHeroInit(gHeroName, "achilles_init") 
} 

public achilles_init() 
{ 
   new temp[128] 
   // First Argument is an id 
   read_argv(1, temp, 5) 
   new id = strtonum(temp) 

   // 2nd Argument is 0 or 1 depending on whether the id has Achilles powers 
   read_argv(2, temp, 5) 
   new hasPowers = strtonum(temp) 

   register_cvar("achilles_dmgmult", "3.0") 

   if(hasPowers) {
	gHasAchillesPowers[id] = true 
	set_user_hitzones(0, id, 65) 
   }
   else if (is_user_connected(id)){ 
	gHasAchillesPowers[id] = false 
	set_user_hitzones(0, id, 255) 
 }
} 

public achilles_damage(id) 
{
	if (!is_user_alive(id) || !gHasAchillesPowers[id]) return

	new damage = read_data(2)
	new weapon, bodypart, attacker = get_user_attacker(id, weapon, bodypart)

	if ( attacker <= 0 || attacker > SH_MAXSLOTS ) return
	new extradamage = floatround(damage*get_cvar_float("achilles_dmgmult") - damage)
	
	if (extradamage > 0) shExtraDamage(id, attacker, extradamage, "Achilles Heel")
	else shAddHPs (id, -extradamage, 3000)
}