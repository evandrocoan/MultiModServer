
/** *************************************************************************
*** AMXX Plugin:   Ultimate Warcraft3 (UWC3)
*** Plugin Author: K2mia
*** UWC3 Module:   Item Handlers
*** Date:          May 25, 2004
*** Last Update:   September 27, 2004
*
*  Module: Item Handlers
*  Subroutines for item-related activity (shopitems, weapons, equip, etc)
*----------------------------------------------------------------------------
*
*  UWC3 is written exclusively for AMX Mod X
*
*  Ultimate Warcraft3 Dev. Team
*  ------------------------------
*   Small scripting:  K2mia ( Andrew Cowan ) < admin@mudconnect.com >
*   Graphics:         steve french < garbageweed@hotmail.com >
*   Website Design:   Jim Rhoades < jim@radzone.org >
*
*  str_break() routine provided by BAILOPAN from AMXX0.20 to replace parse()
*  ultimate_decoy() code derived from code for Beyonder superhero (Freecode/Asskicr)
*    some decoy concepts from AMXX forums posts by jjkiller
*
****************************************************************************/


// **************************************************************************
// BEGIN item_menu subroutine
// Display the Item menu
// **************************************************************************
item_menu(id){

   new pos = 0, i, menu_body[512], menu_items[4][32]
   new keys = (1<<0)|(1<<1)|(1<<2)|(1<<3)|(1<<8)|(1<<9)

   menu_items[0]= "Shopmenu 1"
   menu_items[1]= "Shopmenu 2"
   menu_items[2]= "Show Shopmenu Information"
   menu_items[3]= "Show Shopmenu 2 Information"

   pos += format(menu_body[pos], 511-pos, "\yItem Options^n^n")
   for (i = 0; i<4; i++){
      pos += format(menu_body[pos], 511-pos, "\w%d. %s^n",i+1,menu_items[i])
   }
   pos += format(menu_body[pos], 511-pos, "^n^n\w9. Back")
   pos += format(menu_body[pos], 511-pos, "^n\w0. Exit")
   show_menu(id,keys,menu_body,-1)

   return PLUGIN_CONTINUE
}
// **************************************************************************
// END item_menu subroutine
// **************************************************************************


// **************************************************************************
// BEGIN do_itemmenu subroutine
// Handler for the items main menu
// **************************************************************************
public do_itemmenu(id,key){
   switch (key){
      case 0: shopmenu(id)
      case 1: shopmenu2(id)
      case 2: items_info(id)
      case 3: items_info2(id)
      case 8: main_menu(id)
      default: return PLUGIN_HANDLED
   }
   return PLUGIN_HANDLED
}
// **************************************************************************
// END do_itemmenu subroutine
// **************************************************************************


// **************************************************************************
// BEGIN items_info subroutine
// Display info about items in the shopmenu
// **************************************************************************
public items_info(id){
   if (!warcraft3)
      return PLUGIN_CONTINUE

   new temp[1024], pos = 0
   new theforward[] = "<li>"
   new backward[] = "</li>"
   new lastone[] = "</ul>"
   pos += format(temp[pos], 1024-pos, "<body bgcolor=#000000><font color=#FFB000>")

   pos += format(temp[pos], 1024-pos, "The following items are available for purchase at the shop (say shopmenu):<p><ul>")

   pos += format(temp[pos], 1024-pos, "%sAnkh of Reincarnation: If you die you will retrieve your equipment the following round%s",theforward,backward)
   pos += format(temp[pos], 1024-pos, "%sBoots of Speed: Allows you to run faster%s",theforward,backward)
   pos += format(temp[pos], 1024-pos, "%sClaws of Attack +%d: An additional %d hp will be removed from the enemy on every hit%s",theforward,CLAWSOFATTACK,CLAWSOFATTACK,backward)
   pos += format(temp[pos], 1024-pos, "%sCloak of Shadows: Makes you partially invisible, invisibility is increased when holding the knife%s",theforward,backward)
   pos += format(temp[pos], 1024-pos, "%sMask of Death: You will receive health for every hit on the enemy%s",theforward,backward)
   pos += format(temp[pos], 1024-pos, "%sNecklace of Immunity: You will be immune to enemy ultimates",theforward,backward)
   pos += format(temp[pos], 1024-pos, "%sOrb of Frost: Slows your enemy down when you hit him%s",theforward,backward)
   pos += format(temp[pos], 1024-pos, "%sPeriapt of Health: Receive extra health%s",theforward,backward)
   pos += format(temp[pos], 1024-pos, "%sTome of Experience: Purchasing a tome increases your experience by a fixed amount, the tome is consume%s%s",theforward,backward,lastone)
   show_motd(id,temp,"Shopmenu Item Information")

   return PLUGIN_CONTINUE
}
// **************************************************************************
// END items_info subroutine
// **************************************************************************


// **************************************************************************
// BEGIN items_info2 subroutine
// Display info about items in the shopmenu2
// **************************************************************************
public items_info2(id){
   if (!warcraft3)
      return PLUGIN_CONTINUE

   new temp[1024], pos = 0
   new theforward[] = "<li>"
   new backward[] = "</li>"
   new lastone[] = "</ul>"
   pos += format(temp[pos], 1024-pos, "<body bgcolor=#000000><font color=#FFB000>")

   pos += format(temp[pos], 1024-pos, "The following items are available for purchase at the shop (say shopmenu2):<p><ul>")

   pos += format(temp[pos], 1024-pos, "%sScroll of Respawning: You will respawn after death%s",theforward,backward)
   pos += format(temp[pos], 1024-pos, "%sMole Protectant: Protects you from moles (unless they hit you in the head)%s",theforward,backward)
   pos += format(temp[pos], 1024-pos, "%sAmulet of the Cat: You cannot be heard when running/going up ladders%s",theforward,backward)
   pos += format(temp[pos], 1024-pos, "%sSock of the Feather: Allows you to levitate %s",theforward,backward)
   pos += format(temp[pos], 1024-pos, "%sHelm of Excellence: Immunity to headshots%s",theforward,backward)
   pos += format(temp[pos], 1024-pos, "%sFlaming Gloves of Warmth: Given an HE grenade every %s seconds%s",theforward,get_cvar_num("FT_glove_timer"),backward)
   pos += format(temp[pos], 1024-pos, "%sRing of Regeneration +1: Gives 1 health every 2 seconds, you can have 5 max (type rings to receive 5)%s",theforward,backward)
   pos += format(temp[pos], 1024-pos, "%sChameleon: You are disguised as the enemy!!%s",theforward,backward)
   pos += format(temp[pos], 1024-pos, "%sMole: Teleports you to the enemy spawn under disguise at the start of the round %s%s",theforward,backward,lastone)

   show_motd(id,temp,"Shopmenu2 Item Information")

   return PLUGIN_CONTINUE
}
// **************************************************************************
// END items_info2 subroutine
// **************************************************************************


// **************************************************************************
// BEGIN shopmenu subroutine
// Display the shopmenu
// **************************************************************************
public shopmenu(id){

   if (warcraft3==false)
      return PLUGIN_CONTINUE

   if(get_cvar_num("FT_competitive")){
      if (!is_user_alive(id)){
         client_print(id,print_center,"You may not buy items when you are dead.")
         return PLUGIN_HANDLED
      }else if (!buytime){
         new Float:thetime = get_cvar_float("mp_buytime")*60.0
         client_print(id,print_center,"%0.0f seconds have passed. You can't buy anthing now.",thetime)
         return PLUGIN_HANDLED
      }else if(!isBuyzone[id]){
         client_print(id,print_center,"You must be in the buyzone to purchase an item")
         return PLUGIN_HANDLED
      }
   }

   new pos = 0
   new keys = (1<<0|1<<1|1<<2|1<<3|1<<4|1<<5|1<<6|1<<7|1<<8|1<<9)
   new menu_body[512]

   pos += format(menu_body[pos], 511-pos, "\yBuy Item\R$   Cost^n^n")
   for (new i = 0; i<9; i++){
      pos += format(menu_body[pos], 511-pos, "\w%d. %s\y\R%d^n",i+1,itemname[i],itemcost[i])
   }
   pos += format(menu_body[pos], 511-pos, "^n\w0. Exit")


   show_menu(id, keys, menu_body, -1)

   return PLUGIN_HANDLED

}
// **************************************************************************
// END shopmenu subroutine
// **************************************************************************


// **************************************************************************
// BEGIN shopmenu2 subroutine
// Display the shopmenu
// **************************************************************************
public shopmenu2(id){

   if (warcraft3==false)
      return PLUGIN_CONTINUE

   if(get_cvar_num("FT_competitive")){
      if (!is_user_alive(id)){
         client_print(id,print_center,"You may not buy items when you are dead.")
         return PLUGIN_HANDLED
      }else if (!buytime){
         new Float:thetime = get_cvar_float("mp_buytime")*60.0
         client_print(id,print_center,"%0.0f seconds have passed. You can't buy anthing now.",thetime)
         return PLUGIN_HANDLED
      }else if(!isBuyzone[id]){
         client_print(id,print_center,"You must be in the buyzone to purchase an item")
         return PLUGIN_HANDLED
      }
   }

   new pos = 0
   new keys = (1<<0|1<<1|1<<2|1<<3|1<<4|1<<5|1<<6|1<<7|1<<8|1<<9)
   new menu_body[512]

   pos += format(menu_body[pos], 511-pos, "\yBuy An Item\R$   Cost^n^n")
   for (new i = 0; i<9; i++){
      pos += format(menu_body[pos], 511-pos, "\w%d. %s\y\R%d^n",i+1,itemname2[i],itemcost2[i])
   }
   pos += format(menu_body[pos], 511-pos, "^n\w0. Exit")


   show_menu(id, keys, menu_body, -1)

   return PLUGIN_HANDLED

}
// **************************************************************************
// END shopmenu2 subroutine
// **************************************************************************


// **************************************************************************
// BEGIN buy_item subroutine
// Handler for the shopmenu
// **************************************************************************
public buy_item(id,key){
   if (warcraft3==false)
      return PLUGIN_CONTINUE

   if(get_cvar_num("FT_competitive")){
      if (!is_user_alive(id)){
         client_print(id,print_center,"You may not buy items when you are dead.")
         return PLUGIN_HANDLED
      }else if(!buytime){
         new Float:thetime = get_cvar_float("mp_buytime")*60.0
         client_print(id, print_center, 
            "%0.0f seconds have passed. You can't buy anthing now.",thetime)
         return PLUGIN_HANDLED
      }else if(!isBuyzone[id]){
         client_print(id,print_center,"You must be in the buyzone to purchase an item")
         return PLUGIN_HANDLED
      }
   }

   if ( !is_user_alive(id) && 
        (key==7 || key==6 || key==5 || key==4 || key==3 || key==2 || key==1))
   {
      client_print(id,print_center,"You may not purchase that item when dead")
      return PLUGIN_CONTINUE
   }

   new usermoney = cs_get_user_money(id)

   xpgiven = xpgiven_lev[p_level[id]]

   if (key==9)
      return PLUGIN_HANDLED
   else if(key==playeritem[id]-1 && key!=TOME-1){
      client_print(id,print_center,"You already own that item")
      return PLUGIN_HANDLED
   }else if (usermoney<itemcost[key]){
      client_print(id,print_center,"You have insufficient funds!")
      return PLUGIN_HANDLED
   }else if (key==TOME-1){
      cs_set_user_money(id,usermoney-itemcost[key],1)
      // Give XP bonus for buying Tome of Experience
      playerxp[id]+=(XPBONUS+xpgiven)

      if (file_exists("sound/warcraft3/tomes.wav")==1)
         emit_sound(id,CHAN_ITEM, "warcraft3/tomes.wav", 1.0, ATTN_NORM, 0, PITCH_NORM)

      displaylevel(id,3)
      return PLUGIN_HANDLED
   }else{
      cs_set_user_money(id,usermoney-itemcost[key],1)

      if (playeritem[id]==HEALTH)
         // Remove health bonus after buying new item
         set_user_health_log(id, get_user_health(id)-HEALTHBONUS, true, 
                             "buy_item() HEALTH1")

      playeritem[id]=key+1

      if (playeritem[id]==HEALTH){
         // Give health bonus for buying periapt of health
         set_user_health_log(id, get_user_health(id)+HEALTHBONUS, true, 
                             "buy_item() HEALTH2")

         if ( get_cvar_num("UW_DEBUG") == 5 ){
            new name[32]
            get_user_name(id, name, 31)
            log_amx( "In buy_item() :: [%s] Bought Health Has=(%d) Max=(%d)",
                     name, get_user_health(id), maxhealth[id] )
         }
      }
   }

   if (file_exists("sound/warcraft3/pickupitem.wav")==1)
      emit_sound(id,CHAN_ITEM, "warcraft3/pickupitem.wav", 1.0, ATTN_NORM, 0, PITCH_NORM)
   displaylevel(id,3)

   return PLUGIN_HANDLED
}
// **************************************************************************
// END buy_item subroutine
// **************************************************************************


// **************************************************************************
// BEGIN buy_item2 subroutine
// Handler for the shopmenu
// **************************************************************************
public buy_item2(id,key){

   if (warcraft3==false)
      return PLUGIN_CONTINUE

   if(get_cvar_num("FT_competitive")){
      if (!is_user_alive(id)){
         client_print(id,print_center,"You may not buy items when you are dead.")
         return PLUGIN_HANDLED
      }else if(!buytime){
         new Float:thetime = get_cvar_float("mp_buytime")*60.0
         client_print(id,print_center,"%0.0f seconds have passed. You can't buy anthing now.",thetime)
         return PLUGIN_HANDLED
      }else if(!isBuyzone[id]){
         client_print(id,print_center,"You must be in the buyzone to purchase an item")
         return PLUGIN_HANDLED
      }
   }

   if (!is_user_alive(id) && (key==7 || key==6 || key==5 || key==4 || key==3 || key==2 || key==1))
   {
      client_print(id,print_center,"You may not purchase that item when dead")
      return PLUGIN_CONTINUE
   }

   if(key==playeritem2[id]-1 && key!=REGEN-1){
      client_print(id,print_center,"You already own that item")
      return PLUGIN_HANDLED
   }

   if(key==RESPAWN-1 && endround){
      client_print(id,print_center,"You may not purchase this after the round has ended")
      return PLUGIN_HANDLED
   }

   if (key==9)
      return PLUGIN_HANDLED
   else if (cs_get_user_money(id)<itemcost2[key]){
      client_print(id,print_center,"You have insufficient funds!")
      return PLUGIN_HANDLED
   }else{
      if (playeritem2[id]==CAT){
         set_user_footsteps(id, 0)
      }
      if (playeritem2[id]==FEATHER)
         set_user_gravity(id,1.0)
      if (playeritem2[id]==HELM)
         set_user_hitzones(0,id,255)
      if (playeritem2[id]==CHAMELEON)
         changeskin(id,1)
      if (playeritem2[id]!=REGEN){
         if(task_exists(9000+id))
            remove_task(9000+id)
         rings[id]=0
      }
      if (playeritem2[id]!=INFERNO){
         if(task_exists(9400+id))
            remove_task(9400+id)
      }
      playeritem2[id]=key+1
      if (playeritem2[id]==CHAMELEON && is_user_alive(id))
         changeskin(id,0)
      if (playeritem2[id]==HELM)
         set_user_hitzones(0,id,253)
      if (playeritem2[id]==CAT){
         set_user_footsteps(id, 1)
      }
      if (playeritem2[id]==FEATHER)
         set_user_gravity(id,0.35)
      if (playeritem2[id]==RESPAWN && !is_user_alive(id)){
         if(get_user_team(id)==TEAM_T || get_user_team(id)==TEAM_CT){
            new parm[2]
            parm[0]=id
            parm[1]=6
            set_task(0.2,"func_spawn",2,parm,2)
            spawnedfromitem[id]=true
            playeritem2[id]=0
            playeritem[id]=0
         }
      }
      if (playeritem2[id]==INFERNO){
         if (get_cvar_num("FT_no_gloves_on_ka")){
            if(!givenade){
               client_print(id, print_center,
                  "Flaming Gloves of Warmth are restricted on this map")
               playeritem2[id] = 0 // Fix for Gloves bug which still allowed it to be bought
               return PLUGIN_HANDLED
            }else{
               new parm[2]
               parm[0]=id
               giveheifnothas(parm)
               nadetime[id]=get_cvar_num("FT_glove_timer")
            }
         }else{
            new parm[2]
            parm[0]=id
            giveheifnothas(parm)
            nadetime[id]=get_cvar_num("FT_glove_timer")
         }
      }
      if (playeritem2[id]==REGEN){
         new parm[2]
         parm[0]=id
         if (rings[id]<5){
            ++rings[id]
            if(!task_exists(9000+id))
               regenerate(parm)
         }else{
            client_print(id,print_center,"You may not purchase more than 5 rings")
            return PLUGIN_HANDLED
         }
      }
      if (playeritem2[id] == MOLE){
         hasmole[id] = true
      }
      cs_set_user_money(id, cs_get_user_money(id)-itemcost2[key],1)
   }

   if (file_exists("sound/warcraft3/pickupitem.wav")==1)
      emit_sound(id,CHAN_ITEM, "warcraft3/pickupitem.wav", 1.0, ATTN_NORM, 0, PITCH_NORM)

   displaylevel(id,3)

   return PLUGIN_HANDLED

}
// **************************************************************************
// END buy_item2 subroutine
// **************************************************************************


// **************************************************************************
// BEGIN player_giveitems subroutine
// Restore player equipment when dead 
// **************************************************************************
public player_giveitems(parm[2]){
   new id = parm[0]

   if ( !is_user_connected( id ) )
      return PLUGIN_CONTINUE

   if (p_skills[id][SKILLIDX_VENGEANCE] && !spawnedfromitem[id]){
      // If spawned from vengeance
      vengeance_state[id] = VENG_DONE	// Set vengeance state to completed respawn

      new health = ( maxhealth[id] / 2 )
      if ( health < 50 ) health = 50

      set_user_health_log(id, health, true, "player_giveitems() VENGEANCE1")
   }else if (p_skills[id][SKILLIDX_DEVOTION]){
      // Devotion Aura
      set_user_health_log(id, p_devotion[p_skills[id][SKILLIDX_DEVOTION]-1],
                          true, "player_giveitems() DEVOTION1")
   }else{
      // All other cases
      set_user_health_log(id,100, true, "player_giveitems() OTHER1")
   }

   check_blink(parm[0])
   give_items[parm[0]] = true
   set_task( 0.1, "weapon_controller", 10091, parm, 2 ) // Give weapons back

   give_item( id, "item_suit" )
   give_item( id, "weapon_knife" )

   // [08-29-04] Makes sure defusers get reincarnated - K2mia
   if (hasdefuse[id]){
      give_item( id, "item_thighpack" )
   }

   // [10-14-04] Makes sure Nightvision get reincarnated - K2mia
   if (hasnvision[id]){
      cs_set_user_nvg( id, 1 )
   }

   // The following code decides if pistols should be given
   if (!givepistol)
      return PLUGIN_CONTINUE

   new wpnList[32] = 0, number = 0, foundGlock = false, foundUSP = false
   get_user_weapons(id,wpnList,number)

   for (new i = 0;i < number;i++) {
      if (wpnList[i] == CSW_GLOCK18)
         foundGlock = true
      if (wpnList[i] == CSW_USP)
         foundUSP = true
   }

   if (get_user_team(id)==TEAM_T){
      if (foundGlock)
         return PLUGIN_CONTINUE
      else{
         give_item(id,"weapon_glock18")
         give_item(id,"ammo_9mm")
         give_item(id,"ammo_9mm")
         give_item(id,"ammo_9mm")
      }
   }

   if (get_user_team(id)==TEAM_CT){
      if (foundUSP)
         return PLUGIN_CONTINUE
      else{
         give_item(id,"weapon_usp")
         give_item(id,"ammo_45acp")
         give_item(id,"ammo_45acp")
         give_item(id,"ammo_45acp")
         give_item(id,"ammo_45acp")
         give_item(id,"ammo_45acp")
         give_item(id,"ammo_45acp")
         give_item(id,"ammo_45acp")
      }
   }

   return PLUGIN_CONTINUE

}
// **************************************************************************
// END player_giveitems subroutine
// **************************************************************************


// **************************************************************************
// BEGIN weapon_controller subroutine
// From Warcraft3 FT
// **************************************************************************
public weapon_controller( parm[2] ){

   if (!warcraft3)
      return PLUGIN_CONTINUE

   new id = parm[0]
   new origin[3] = 0
   new weaponid = 0, weaponname[20] = 0, ammoname[20] = 0
   new bool:reincarnate
   new iweapons[32] = 0, wpname[32] = 0, inum = 0
   get_user_weapons(id,iweapons,inum)

   reincarnate = false

   // Save weapons of people who survived: otherwise the stripper will nab them...
   if( diedlastround[id] == false ){  // LIVED LAST ROUND
      reincarnate = false
   }

   // Equipement & Eligibility Check for Re-Incarnation
   if ( diedlastround[id]){        // DIED LAST ROUND
      new Float:randomnumber = random_float(0.0,1.0)
      if (p_skills[id][SKILLIDX_EQREINC] &&
          randomnumber <= p_ankh[p_skills[id][SKILLIDX_EQREINC]-1])
      {
         reincarnate = true
         //client_print(id,print_chat, "skill detected")
      }else if(give_items[id]){
         reincarnate = true
         give_items[id]=false
      }else if (playeritem[id]==ANKH)
         reincarnate=true
   }

   // Equipement Re-Incarnation: Includes pistols. Also, living ppl
   // need to be re-incarnated.
   if (reincarnate){
      if (file_exists("sound/warcraft3/soundpack/reincarnation.wav")==1)
         emit_sound(id,CHAN_ITEM, "warcraft3/soundpack/reincarnation.wav", 1.0, ATTN_NORM, 0, PITCH_NORM)

      // Disarm and Isolate Player Before Re-Incarnation
      get_user_origin(id,origin)
      origin[2] -= 2000
      set_user_origin(id,origin)
      for(new a=0;a<inum;++a){
         if( iweapons[a] != CSW_C4){
            get_weaponname(iweapons[a],wpname,31)
            engclient_cmd(id,"drop",wpname)
         }
      }
      engclient_cmd(id,"weapon_knife")
      origin[2] += 2005

      if (armorondeath[id]){
         if (helmet[id])
            give_item(id,"item_assaultsuit")
         else
            give_item(id,"item_kevlar")
         set_user_armor_log(id, armorondeath[id], true, "armorondeath")
         //set_user_armor(id,armorondeath[id])
      }
      if (playerhasspawned[id] && !reincarnate)
         return PLUGIN_HANDLED

      if (hasdefuse[id]){
         give_item(id,"item_thighpack")
      }

      // [10-14-04] Makes sure Nightvision get reincarnated - K2mia
      if (hasnvision[id]){
         cs_set_user_nvg( id, 1 )
      }

      new weapon
      for (new j=0; (j < savednumber[id]) && (j < 32); ++j){
          weapon=savedweapons[id][j]
          if (weapon==CSW_M3||weapon==CSW_XM1014||weapon==CSW_MP5NAVY||
              weapon==CSW_TMP ||weapon==CSW_P90||weapon==CSW_MAC10||weapon==CSW_UMP45||
              weapon==CSW_AK47 ||weapon==CSW_SG552||weapon==CSW_M4A1||weapon==CSW_AUG||
              weapon==CSW_SCOUT ||weapon==CSW_AWP||weapon==CSW_G3SG1||
              weapon==CSW_SG550||weapon==CSW_M249)
                 gotShield[id]=false
      }
      //if(gotShield[id])
      //   give_item(id,"weapon_shield")

      for (new j=0; (j < savednumber[id]) && (j < 32); ++j){
          weaponid=savedweapons[id][j]

          if( weaponid==CSW_USP){
             weaponname="weapon_usp"
             ammoname="ammo_45acp"
          }else if( weaponid==CSW_ELITE){
             weaponname="weapon_elite"
             ammoname="ammo_9mm"
          }else if( weaponid==CSW_FIVESEVEN){
             weaponname="weapon_fiveseven"
             ammoname="ammo_57mm"
          }else if( weaponid==CSW_GLOCK18){
             weaponname="weapon_glock18"
             ammoname="ammo_9mm"
          }else if( weaponid==CSW_DEAGLE){
             weaponname="weapon_deagle"
             ammoname="ammo_50ae"
          }else if( weaponid==CSW_P228){
             weaponname="weapon_p228"
             ammoname="ammo_357sig"
          }else if (weaponid==3){
             weaponname="weapon_scout"
             ammoname="ammo_762nato"
          }else if (weaponid==4){
             give_item(id,"weapon_hegrenade")
          }else if (weaponid==5){
             weaponname="weapon_xm1014"
             ammoname="ammo_buckshot"
          }else if (weaponid==7){
             weaponname="weapon_mac10"
             ammoname="ammo_45acp"
          }else if (weaponid==8){
             weaponname="weapon_aug"
             ammoname="ammo_556nato"
          }else if (weaponid==9){
             give_item(id,"weapon_smokegrenade")
          }else if (weaponid==12){
             weaponname="weapon_ump45"
             ammoname="ammo_45acp"
          }else if (weaponid==13){
             weaponname="weapon_sg550"
             ammoname="ammo_556nato"
          }else if (weaponid==14){
             weaponname="weapon_galil"
             ammoname="ammo_556nato"
          }else if (weaponid==15){
             weaponname="weapon_famas"
             ammoname="ammo_556nato"
          }else if (weaponid==18){
             weaponname="weapon_awp"
             ammoname="ammo_338magnum"
          }else if (weaponid==19){
             weaponname="weapon_mp5navy"
             ammoname="ammo_9mm"
          }else if (weaponid==20){
             weaponname="weapon_m249"
             ammoname="ammo_556natobox"
          }else if (weaponid==21){
             weaponname="weapon_m3"
             ammoname="ammo_buckshot"
          }else if (weaponid==22){
             weaponname="weapon_m4a1"
             ammoname="ammo_556nato"
          }else if (weaponid==23){
             weaponname="weapon_tmp"
             ammoname="ammo_9mm"
          }else if (weaponid==24){
             weaponname="weapon_g3sg1"
             ammoname="ammo_762nato"
          }else if (weaponid==25){
             if(flashg[id]==1)
                give_item(id,"weapon_flashbang")
             else{
                give_item(id,"weapon_flashbang")
                give_item(id,"weapon_flashbang")
             }
          }else if (weaponid==27){
             weaponname="weapon_sg552"
             ammoname="ammo_556nato"
          }else if (weaponid==28){
             weaponname="weapon_ak47"
             ammoname="ammo_762nato"
          }else if (weaponid==30){
             weaponname="weapon_p90"
             ammoname="ammo_57mm"
          }else{
             weaponname=""
             ammoname=""
          }  

          if (contain(weaponname,"weapon_")==0){
             // -1 if no match found, 0 if match
             give_item(id,weaponname)
             give_item(id,ammoname)
             give_item(id,ammoname)
             give_item(id,ammoname)
             give_item(id,ammoname)
             give_item(id,ammoname)
             give_item(id,ammoname)
             give_item(id,ammoname)
          }
      }

      if (iglow[id][1] < 1){
         parm[0] = id
         set_task(0.1,"glow_change",4,parm,2)
      }

      iglow[id][1] += 100
      iglow[id][0] = 0
      iglow[id][2] = 0
      iglow[id][3] = 0

      if (iglow[id][1]>MAXGLOW)
         iglow[id][1]=MAXGLOW

      message_begin(MSG_ONE,gmsgFade,{0,0,0},id)
      write_short( 1<<10 ) // fade lasts this long duration
      write_short( 1<<10 ) // fade lasts this long hold time
      write_short( 1<<12 ) // fade type (in / out)
      write_byte( 0 ) // fade red
      write_byte( 255 ) // fade green
      write_byte( 0 ) // fade blue
      write_byte( iglow[id][1] ) // fade alpha
      message_end()

      // Restore Re-Incarnated Player to the map
      set_user_origin(id,origin)
   // [08-29-04] Not sure why hasdefuse changes here, removed - K2mia
   //}else{
   //   hasdefuse[id]=false
   }

   if ( is_user_connected( id ) ){
      if ( !cs_get_user_nvg( id ) )
         hasnvision[id] = false

      if ( !cs_get_user_defuse( id ) )
         hasdefuse[id] = false
   }
 
   item_functions(parm)

   return PLUGIN_HANDLED
}
// **************************************************************************
// END weapon_controller subroutine
// **************************************************************************


// **************************************************************************
// BEGIN item_functions subroutines
// From Warcraft3FT
// **************************************************************************
public item_functions(parm[]){
   new id = parm[0]

   if ( !is_user_connected( id ) )
      return PLUGIN_CONTINUE

   if( !hasrespawned[id] && hasmole[id])
      // [08-19-04] Fixed to prevent respawn Moling from item
      set_task(0.1,"check_spot",id+12,parm,2)

   if(diedlastround[id]){
      playeritem[id]=0
      playeritem2[id]=0
      displaylevel(id,3)
   }

   diedlastround[id]=false

   if(get_cvar_num("sv_gravity")>650){
      if (p_skills[id][SKILLIDX_LEVITATION] && playeritem2[id]!=FEATHER){
         // Levitation
         if (get_user_gravity(id)!=p_levitation[p_skills[id][SKILLIDX_LEVITATION]-1])
            set_user_gravity(id,p_levitation[p_skills[id][SKILLIDX_LEVITATION]-1])
      }else if (playeritem2[id]==FEATHER)
         set_user_gravity(id,0.35)
      else
         set_user_gravity(id,1.0)
   }else
      set_user_gravity(id,1.0)

   if (playeritem2[id]==CAT)
      set_user_footsteps(id, 1)
   else
      set_user_footsteps(id, 0)

   if(playeritem2[id]!=CHAMELEON && skinchanged[id])
      changeskin(id,1)

   if (task_exists(9000+id) && playeritem2[id]!=REGEN)
      remove_task(9000+id)

   if (playeritem[id]==HEALTH)
      set_user_health_log(id,get_user_health(id)+HEALTHBONUS, true, "item_functions() HEALTH1")

   if(playeritem2[id]==REGEN && !task_exists(9000+id))
      regenerate(parm)

   if (playeritem2[id]==HELM)
      set_user_hitzones(0,id,253)
   else
      set_user_hitzones(0,id,255)

   if (playeritem2[id]==CHAMELEON && is_user_alive(id))
      changeskin(id,0)

   return PLUGIN_CONTINUE
}
// **************************************************************************
// END item_functions subroutines
// **************************************************************************


// **************************************************************************
// BEGIN items subroutine
// Displays the player's items in the bottom center of the screen
// **************************************************************************
public items(parm2[2]){
   new id = parm2[0]
   new temp2[128] = "" 
   new temp3[32] = ""

   /*if ( get_cvar_num("UW_DEBUG") == 5 ){
      new name[32]
      get_user_name( id, name, 31)
      log_amx( "In items() Name: %s ultlearned: %d ultused: %d: ftime: %d",
               name, ultlearned[id], ultimateused[id], freezetime )
   }*/

   if (ultlearned[id] && !ultimateused[id] && !freezetime){
      format(temp3, 31, "[ Ultimates Ready ]  ")
   }else if (ultlearned[id]){
      format(temp3, 31, "[ Ultimates  NOT Ready ]  ")
   }           
            
   if (playeritem[id]!=0 && playeritem2[id]!=0){
      if (playeritem2[id]==REGEN && rings[id]>1)
         format(temp2,127,"%sMagic Items: %s and %ss x%d", temp3,
           playeritem[id]?shortitemname[playeritem[id]-1]:"",
           playeritem2[id]?shortitemname2[playeritem2[id]-1]:"",rings[id])
      else  
         format(temp2,127,"%sMagic Items: %s and %s", temp3,
           playeritem[id]?shortitemname[playeritem[id]-1]:"",
           playeritem2[id]?shortitemname2[playeritem2[id]-1]:"")
   }else if (playeritem[id]==0 && playeritem2[id]!=0){
      if (playeritem2[id]==REGEN && rings[id]>1)
         format(temp2,127,"%sMagic Item: %ss x%d", temp3,
           playeritem2[id]?shortitemname2[playeritem2[id]-1]:"",rings[id])
      else  
         format(temp2,127,"%sMagic Item: %s", temp3,
           playeritem2[id]?shortitemname2[playeritem2[id]-1]:"")
   }else if (playeritem[id]!=0 && playeritem2[id]==0)
      format(temp2,127,"%sMagic Item: %s",
         temp3, playeritem[id]?shortitemname[playeritem[id]-1]:"")
   else
      format(temp2,127,"%sNo Magic Items (say /shopmenu)", temp3)

   itemsrunning[id]=true

   // Hud message set based on lowres setting
   if (lowres[id])
      set_hudmessage(255, 255, 255, 0.65, 0.86, 2, 0.02, 10.0, 0.01, 0.1, 2)
   else
      set_hudmessage(255, 255, 255, 0.65, 0.95, 2, 0.02, 10.0, 0.01, 0.1, 2)

   //set_hudmessage(255,255,255,-1.0,0.945,2, 1.5, 40.0, 0.02, 5.0, 1)
   //set_hudmessage(255, 255, 255, 0.05, -1.0, 2, 0.02, 10.0, 0.01, 0.1, 2)

   if (is_user_alive(id) && !endround)
      show_hudmessage(id, temp2)

   set_task(1.0, "items", 451+id, parm2, 2 );
}
// **************************************************************************
// END items subroutine
// **************************************************************************


// **************************************************************************
// BEGIN giveheifnothas subroutine
// Gives a nade if the player doesn't have one
// **************************************************************************
public giveheifnothas(parm[2]) {
   new id = parm[0]
   new wpnList[32] = 0
   new number = 0
   new foundNade = false
   get_user_weapons(id,wpnList,number)
   for (new i = 0;i < number && !foundNade;i++) {
       if (wpnList[i] == CSW_HEGRENADE)
           foundNade = true
   }

   if (!foundNade && is_user_alive(id)){
      set_hudmessage(0, 100, 0, 0.05, 0.65, 2, 0.02, 10.0, 0.01, 0.1, 2)
      show_hudmessage(id, "Your Flaming Gloves provide you with a Nade!")
      give_item(id,"weapon_hegrenade")
   }

   justgivennade[id]=false

   return PLUGIN_CONTINUE

}
// **************************************************************************
// END givenadeifhasnot subroutine
// **************************************************************************


// **************************************************************************
// BEGIN flashbuy and hebuy subroutines
// Routine for handling buying of flash and he grens
// **************************************************************************
public flashbuy(id){
   if(!isBuyzone[id])
      return PLUGIN_HANDLED
   return PLUGIN_CONTINUE
}

public hebuy(id){
   if(get_cvar_num("mp_grenadeprotection")==0)
      return PLUGIN_CONTINUE
   if(!isBuyzone[id])
      return PLUGIN_HANDLED
   if (he[id]>0){
      client_print(id,print_center,"Only one HE grenade per round")
      return PLUGIN_HANDLED
   }else{
      ++he[id]
      return PLUGIN_CONTINUE
   }

   return PLUGIN_HANDLED
}
// **************************************************************************
// END flashbuy and hebuy subroutines
// **************************************************************************


// **************************************************************************
// BEGIN got_defuse subroutine
// From Warcraft3FT
// **************************************************************************
public got_defuse(id){

   if (!warcraft3)
      return PLUGIN_CONTINUE

   hasdefuse[id]=true

   return PLUGIN_CONTINUE
}
// **************************************************************************
// END got_defuse subroutine
// **************************************************************************


// **************************************************************************
// BEGIN armor_type subroutine
// From Warcraft3FT
// **************************************************************************
public armor_type(id){

   if (!warcraft3)
      return PLUGIN_CONTINUE

   if (read_data(1)){
      helmet[id] = true
      hassuit[id] = true
   }else{
      helmet[id] = false
      hassuit[id] = true
   }

   check_skinbonus( id )	// Check if helmet helps w/ skin bonus

   return PLUGIN_CONTINUE
}
// **************************************************************************
// END armor_type subroutine
// **************************************************************************


// **************************************************************************
// BEGIN nadetimer subroutine
// Handler for flaming gloves nade giving
// **************************************************************************
public nadetimer(parm[2]){
   new id = parm[0]
   set_hudmessage(0, 100, 0, 0.05, 0.65, 2, 0.02, 10.0, 0.01, 0.1, 2)
   if(playeritem2[id]!=INFERNO){
      show_hudmessage(id,"")
      return PLUGIN_HANDLED
   }

   if(nadetime[parm[0]]!=0)
      show_hudmessage(id,"%d second(s) until your next grenade", nadetime[parm[0]])

   nadetime[parm[0]] -= 1
   if (!is_user_alive(id))
      show_hudmessage(id,"If you could manage to stay alive I could provide you with more nades!")

   if (nadetime[parm[0]]!=-1 && is_user_alive(parm[0]))
      set_task(1.0,"nadetimer",9400+id,parm,2)

   if (nadetime[parm[0]]==-1){
      giveheifnothas(parm)
      nadetime[id] = get_cvar_num("FT_glove_timer")
      return PLUGIN_HANDLED
   }

   return PLUGIN_CONTINUE
}
// **************************************************************************
// END nadetimer subroutine
// **************************************************************************


// **************************************************************************
// BEGIN check_weap subroutine
// From Warcraft3FT
// **************************************************************************
public check_weap(id){
   new weapon = (read_data(1))

   if (weapon==25)
      ++flashg[id]

   if (weapon==CSW_M3||weapon==CSW_XM1014||weapon==CSW_MP5NAVY||weapon==CSW_TMP ||
       weapon==CSW_P90||weapon==CSW_MAC10||weapon==CSW_UMP45||weapon==CSW_AK47 ||
       weapon==CSW_SG552||weapon==CSW_M4A1||weapon==CSW_AUG||weapon==CSW_SCOUT ||
       weapon==CSW_AWP||weapon==CSW_G3SG1||weapon==CSW_SG550||weapon==CSW_M249)
          gotShield[id]=false

   return PLUGIN_CONTINUE
}
// **************************************************************************
// END check_weap subroutine
// **************************************************************************



// **************************************************************************
// BEGIN change_weapon subroutine
// Handler for weapon change event
// **************************************************************************
public change_weapon(id) {

   if (!warcraft3)
      return PLUGIN_CONTINUE

   if ( !is_user_connected( id ) )
      return PLUGIN_CONTINUE

   if (playeritem2[id]==INFERNO){
      // Gives person a grenade if they weren't just given one
      new wpnList[32] = 0
      new number  = 0
      new foundNade = false
      get_user_weapons(id,wpnList,number)
      for (new i = 0;i < number && !foundNade;i++) {
         if (wpnList[i] == CSW_HEGRENADE)
         foundNade = true
      }

      new parm[2]
      parm[0]=id
      if(!justgivennade[id] && !foundNade){
         justgivennade[id]=true
         nadetimer(parm)
      }
      // End nade giving segment
   }

   new clipamount = 0
   new ammoamount = 0
   new weaponnum = 0
   weaponnum = (get_user_weapon(id,clipamount,ammoamount))

   if ( !is_user_connected( id ) )
      return PLUGIN_CONTINUE

   if (p_skills[id][SKILLIDX_INVIS]){
      // Invisibility
      if (weaponnum==29){
         set_user_rendering(id,kRenderFxNone, 0,0,0, kRenderTransTexture,p_invisibility[p_skills[id][SKILLIDX_INVIS]-1]/2)
         knifeselected[id]=true
      }else{
         set_user_rendering(id,kRenderFxNone, 0,0,0, kRenderTransTexture,p_invisibility[p_skills[id][SKILLIDX_INVIS]-1])
         knifeselected[id]=false
      }
   }else if (playeritem[id]==CLOAK){
      if (weaponnum==29){
         set_user_rendering(id,kRenderFxNone, 0,0,0, kRenderTransTexture,CLOAKINVISIBILITY/2)
         knifeselected[id]=true
      }else{
         set_user_rendering(id,kRenderFxNone, 0,0,0, kRenderTransTexture,CLOAKINVISIBILITY)
         knifeselected[id]=false
      }
   }
   else
      set_user_rendering(id)

   #if STEAM_POWERED
                if (!freezetime && !slowed[id] && !stunned[id]) {
                        if (weaponnum==3){ //scout
                                if (zoomed[id]==1)
                                        set_user_maxspeed(id,220.0)
                                else
                                        set_user_maxspeed(id,260.0) //220 zoomed
                        }
                        else if (weaponnum==4){ //hegrenad
                                set_user_maxspeed(id,260.0)
                        }
                        else if (weaponnum==5){ //xm1014
                                set_user_maxspeed(id,230.0)
                        }
                        else if (weaponnum==7){ //mac10
                                set_user_maxspeed(id,250.0)
                        }
                        else if (weaponnum==8){ //aug - bollup
                                set_user_maxspeed(id,240.0)
                        }
                        else if (weaponnum==9){ //smokegrenade
                                set_user_maxspeed(id,250.0)
                        }
                        else if (weaponnum==12){ //ump45
                                set_user_maxspeed(id,250.0)
                        }
                        else if (weaponnum==13){ //sg550
                                if (zoomed[id]==1)
                                        set_user_maxspeed(id,150.0)
                                else
                                        set_user_maxspeed(id,210.0) //150 zoomed
                        }
                        else if (weaponnum==18){ //awp
                                if (zoomed[id]==1)
                                        set_user_maxspeed(id,150.0)
                                else
                                        set_user_maxspeed(id,210.0) //150 zoomed
                        }
                        else if (weaponnum==19){ //mp5
                                set_user_maxspeed(id,250.0)
                        }
                        else if (weaponnum==20){ //m249
                                set_user_maxspeed(id,220.0)
                        }
                        else if (weaponnum==21){ //auto-shotty (m3)
                                set_user_maxspeed(id,240.0)
                        }
                        else if (weaponnum==14){ //galil
                                set_user_maxspeed(id,240.0)
                        }
                        else if (weaponnum==15){ //famas
                                set_user_maxspeed(id,240.0)
                        }
                        else if (weaponnum==22){ //M4A1
                                set_user_maxspeed(id,230.0)
                        }

                        else if (weaponnum==23){ //TMP
                                set_user_maxspeed(id,250.0)
                        }
                        else if (weaponnum==24){ //G3SG1
                                if (zoomed[id]==1)
                                        set_user_maxspeed(id,150.0)
                                else    
                                        set_user_maxspeed(id,210.0) //150 zoomed
                        }
                        else if (weaponnum==25){ //flashbang
                                set_user_maxspeed(id,250.0)
                        }
                        else if (weaponnum==27){ //sg552
                                set_user_maxspeed(id,235.0)
                        }
                        else if (weaponnum==28){ //AK47
                                set_user_maxspeed(id,221.0)
                        }
                        else if (weaponnum==30){ //P90
                                set_user_maxspeed(id,245.0)
                        }
                        else if (weaponnum==1){ //p228
                                set_user_maxspeed(id,250.0)
                        }
                        else if (weaponnum==10 ){ //elite
                                set_user_maxspeed(id,250.0)
                        }
                        else if (weaponnum==11){ //fiveseven
                                set_user_maxspeed(id,250.0)
                        }       
                        else if (weaponnum==26){ //deagle
                                set_user_maxspeed(id,250.0)
                        }
                        else if (weaponnum==16){ //usp
                                set_user_maxspeed(id,250.0)
                        }       
                        else if (weaponnum==17){ //glock
                                set_user_maxspeed(id,250.0)
                        }
                        else if (weaponnum==29){ //knife
                                set_user_maxspeed(id,250.0)
                        }
                        else if (weaponnum==6){ //BOMB
                                set_user_maxspeed(id,250.0)
                        }
                }               
   #endif               
                        
   new parm[1]                  
   parm[0]=id           
   unholyspeed(parm)    
                                
   return PLUGIN_CONTINUE
}                       
// **************************************************************************
// END change_weapon subroutine 
// **************************************************************************


// **************************************************************************
// BEGIN saveweapons subroutine
// Handler for Equip reincarnation skill
// **************************************************************************
public saveweapons(id){

   armorondeath[id]=get_user_armor(id)

   for (new i=0; i<32; ++i){               // Equipment Reincarnation
      savedweapons[id][i]=0
   }

   savednumber[id]=0
   get_user_weapons(id,savedweapons[id],savednumber[id])

   return PLUGIN_CONTINUE
}
// **************************************************************************
// END saveweapons subroutine
// **************************************************************************


// **************************************************************************
// BEGIN rings5 subroutine
// Allows a player to buy 5 rings of regeneration
// **************************************************************************
public rings5(id){
   if (!is_user_alive(id))
      return PLUGIN_HANDLED

   new usermoney
   new parm[2]
   parm[0]=id

   if (playeritem2[id]==CAT)
      set_user_footsteps(id, 0)
   if (playeritem2[id]==FEATHER)
      set_user_gravity(id,1.0)
   if (playeritem2[id]==HELM)
      set_user_hitzones(0,id,255)
   if (playeritem2[id]==CHAMELEON)
      changeskin(id,1)

   while(rings[id]<5){
      usermoney = cs_get_user_money(id)
      if(usermoney<itemcost2[REGEN-1])
         break
      cs_set_user_money(id,usermoney-itemcost2[REGEN-1],1)
      ++rings[id]
      playeritem2[id]=REGEN
      if(!task_exists(9000+id))
         regenerate(parm)
   }

   displaylevel(id,3)

   return PLUGIN_HANDLED
}
// **************************************************************************
// END rings5 subroutine
// **************************************************************************


// **************************************************************************
// BEGIN shieldbuy check_shield and check_shield2 hook_drop subroutines
// Handles the buying of CT shields
// **************************************************************************
/*
public shieldbuy(id){
   if(cs_get_user_money(id)>=2200)
      gotShield[id]=true

   new parm[1]
   set_task(0.1,"check_shield",2100 + id,parm,1)
   return PLUGIN_CONTINUE
}

public check_shield(parm[1]) {
   new id = parm[0]
   new modelName[32]

   Entvars_Get_String(id, EV_SZ_viewmodel, modelName, 31)
   if ( containi(modelName,"v_shield_") != -1 )
      gotShield[id]=true
   else
      gotShield[id]=false
   return PLUGIN_HANDLED
}

public check_shield2(parm[1]) {
   new id = parm[0]
   new modelName[32]

   Entvars_Get_String(id, EV_SZ_viewmodel, modelName, 31)
   if ( containi(modelName,"v_shield_") != -1 )
      gotShield[id]=true
   else
      gotShield[id]=false

   return PLUGIN_HANDLED

}
*/

public hook_drop(id){
   new parm[1]
   parm[0] = id
   remove_task(2300 + id,0)
   set_task(0.1,"check_shield2",2300 + id,parm,1)

   return PLUGIN_CONTINUE
}
// **************************************************************************
// END shieldbuy check_shield check_shield2 and hook_drop  subroutine2
// **************************************************************************


// **************************************************************************
// BEGIN checkmap subroutine
// Prevents weapons from being given in knife only maps
// **************************************************************************
public checkmap(){
   new mapname[32]
   get_mapname(mapname,31)

   if (containi(mapname,"ka_")!=-1 || containi(mapname,"he_")!=-1 || 
       containi(mapname,"scoutzknivez")!=-1)
   {
      givepistol=false
      if (get_cvar_num("FT_no_gloves_on_ka"))
         givenade=false
      else
         givenade=true
   }else{
      givenade=true
      givepistol=true
   }

   if(get_cvar_num("FT_no_orcnades_on_he")){
      //if (containi(mapname,"ka_")!=-1 || containi(mapname,"jail_riot")!=-1)
      if (containi(mapname,"ka_")!=-1 || containi(mapname,"jail_riot")!=-1 ||
          containi(mapname,"fy_")!=-1)
      {
         no_he=true
      }else{
         no_he=false
      }
   }

   return PLUGIN_CONTINUE
}
// **************************************************************************
// END checkmap subroutine
// **************************************************************************


