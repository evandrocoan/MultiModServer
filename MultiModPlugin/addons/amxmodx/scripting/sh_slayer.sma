#include <amxmod.inc>
#include <superheromod.inc>

// Slayer (GGXX) - founder of the Assassins guild, has an unblockable move :-"
/*
slayer_level 6     - level at which he's available
slayer_cooldown 40 - cooldown between god removals
slayer_chance 0.05 - chance of assassination
*/
new gHeroName[]="Slayer"
new gHasSlayerPowers[SH_MAXSLOTS+1]

public plugin_init()
{
  register_plugin("SUPERHERO Slayer","1.0","Mydas")
  register_cvar("slayer_level", "6" )
  shCreateHero(gHeroName, "God Removal/Assassinate", "Godmode removal; small chance of assassinating enemies with 1 bullet", false, "slayer_level" )
  register_srvcmd("slayer_init", "slayer_init")
  shRegHeroInit(gHeroName, "slayer_init")  

  set_task(0.1,"slayer_loop",0,"",0,"b")

  register_event("Damage", "slayer_damage", "b", "2!0")
  register_event("ResetHUD","newRound","b") 
  register_cvar("slayer_cooldown", "40" )
  register_cvar("slayer_chance", "0.05" )
}
//----------------------------------------------------------------------------------------------
public newRound(id)
{
  gPlayerUltimateUsed[id]=false
}
//----------------------------------------------------------------------------------------------
public slayer_init()
{
  new temp[6] 
  read_argv(1,temp,5) 
  new id=str_to_num(temp) 
  read_argv(2,temp,5) 
  new hasPowers=str_to_num(temp) 
  gHasSlayerPowers[id]=(hasPowers!=0) 
   
}
//----------------------------------------------------------------------------------------------
public slayer_loop()
{
  for ( new id=1; id<=SH_MAXSLOTS; id++ ) if (gHasSlayerPowers[id])
  {
    new aid,abody
    get_user_aiming(id,aid,abody)
    if (aid && is_user_alive(aid) && get_user_godmode(aid) && (get_user_team(id)!=get_user_team(aid))) {
      set_user_godmode(aid,0)
      shExtraDamage(id, id, get_user_health(id)/2, "Slayer Sacrifice" )
    }
  }
}
//---------------------------------------------------------------------------------------------- 
public slayer_damage(id)
{
    if (!shModActive() || !is_user_alive(id)) return PLUGIN_CONTINUE

    new weapon, bodypart, attacker = get_user_attacker(id, weapon, bodypart)

    if ( attacker <= 0 || attacker > SH_MAXSLOTS ) return PLUGIN_CONTINUE

    if ( gHasSlayerPowers[attacker] && (weapon != CSW_HEGRENADE) && is_user_alive(attacker) && is_user_alive(id) && (id!=attacker) ) {
      new randNum = random_num(0, 100)
      if (get_cvar_float("slayer_chance") * 100 >= randNum) {
		shExtraDamage(attacker, attacker, get_user_health(attacker)/2, "Slayer Sacrifice" )
		shExtraDamage(id, attacker, get_user_health(id), "Assassination" )		
      }
    }
    return PLUGIN_CONTINUE
}
//----------------------------------------------------------------------------------------------