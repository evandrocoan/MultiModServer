
#include "../pokemon/custom.inl"
#include "../pokemon/defines.inl"

#if defined _pokemod_included
  #endinput
#endif
#define _pokemod_included

#pragma reqlib "pokemod"

//is pokemod on?
native PokeMod();

//returns pokename with the name assigned to poke
native Poke_PokeToName(poke, pokename[]);
//returns the numerical value of the pokemon specified
native Poke_NameToPoke(pokename[]);
//returns itemname with the name assigned to item
native Poke_ItemToName(item, itemname[]);
//returns the numerical value of the item specified
native Poke_NameToItem(itemname[]);

//returns the bit information about a pokemon, relates to the PI_* defines in defines.inl
native Poke_PokeInfo(poke);
//returns the bit information about an item, relates to the II_* defines in defines.inl
native Poke_ItemInfo(item);

//returns what pokemon the player has in Slot num
native Poke_PlayerPokemon(id, num);
//returns how much xp the player has in Slot num
native Poke_PlayerXP(id, num);
//returns level for the pokemon in Slot num
native Poke_PlayerLevel(id, num);
//returns how many of an item the player has
native Poke_PlayerItem(id, item);
//returns status of a players status
native Poke_PlayerStatus(id, status);

//changes id's pokemon in slot num to new_poke
native Poke_Set_PlayerPokemon(id, num, new_poke);
//changes id's xp in slot num to new_xp
native Poke_Set_PlayerXP(id, num, new_xp);
//changes how many of item id has
native Poke_Set_PlayerItem(id, item, num);
//changes status of a player
native Poke_Set_PlayerStatus(id, STATUS:status, Float:num=0.0, inflictor);

//attacker damages victim for damage using Attack. Returns actual damage done
native Poke_Damage(victim, attacker, damage, Attack[]);
//attacker damages players near origin. Returns total damage done to all players. Setting a status gives the attack a chance based on damage to apply the status to the victim (status_mult changes the chance)
native Poke_AoE_Damage(attacker, Float:origin[3], radius, maxdamage, Attack[], ignore_attacker=1, STATUS:status=MAX_STATUS, status_mult=1);
//attacker damages players near the line from start to end. Returns total damage done to all players. Setting a status gives the attack a chance based on damage to apply the status to the victim (status_mult changes the chance)
native Poke_Line_Damage(attacker, Float:start[3], Float:end[3], radius, maxdamage, Attack[], STATUS:status=MAX_STATUS, status_mult=1);

//gives a player a pokemon, returns 0 on failure
native Poke_Give_Poke(id, poke, level=1);
//gives a players pokemon experience, set num to -1 to give to active pokemon, returns 0 on failure
native Poke_Give_XP(id, num, experience);
//gives a player an item
native Poke_Give_Item(id, item, how_many=1);

//make an oak at Origin, with angles Angles, with health hp, for team's team, with these properties
native Poke_MakeThisOak(Float:Origin[3],Float:Angles[3], health, team, properties[]);

//how much money someone has according to pokemod
native Poke_Money(id);
//what someone's max hp is according to pokemod
native Poke_MaxHP(id);
//what someone's delay to use their skill is
native Poke_Delay(id);

//sets a players max hp, set to a negative number if you don't want PokeMod to override it
native Poke_Set_MaxHP(id, new_value);
//sets a players money
//set do_forward to 0 to not send payment to other plugins
native Poke_Set_Money(id, new_value, do_forward=1);
//sets a players delay to use a skill
native Poke_Set_Delay(id, Float:new_seconds);
//resets someones speed
native Poke_Reset_Speed(id);

//heal a player
native Poke_Heal(id, amount);
//pay a player
//set do_forward to 0 to not send payment to other plugins
native Poke_Pay(id, amount, do_forward=1);
//repair a player's armor
native Poke_Repair(id, amount);

//returns what price something is at
//	set is_item to 0 to get the price of a pokemon
native Poke_Item_Price(item, is_item=1);
#define Poke_Price(%1) Poke_Item_Price(%1, 0);
//checks if player can buy items where they currently are
native Poke_Buy_Check(id);

//returns the xp needed for level
//if level is 0, max level is returned
native Poke_LevelXP(level);

//when someone is payed money
forward poke_pay(id, amount);
//when someone tries to buy items, return PLUGIN_HANDLED to stop the process
forward poke_buy(id, item, amount);
//when someone tries to buy pokemon, return PLUGIN_HANDLED to stop the process
forward poke_buypoke(id, poke);

//when different skills are to be activated
//return PLUGIN_HANDLED to stop other skills for the pokemon
forward poke_attack_skill(attacker, attacker_poke, victim, weapon, damage);
forward poke_victim_skill(attacker, victim, victim_poke, weapon, damage);
forward poke_bind_skill(player, poke);

//when someone activates an item
//return PLUGIN_HANDLED to stop other item effects
forward poke_item_use(player, item);

//only use Register_PokeItem in poke_register_item
native Register_PokeItem(itemname[], cost, flags[], category[]);
forward poke_register_item();
