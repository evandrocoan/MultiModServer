
/** *************************************************************************
*** AMXX Plugin:   Ultimate Warcraft3 (UWC3)
*** Plugin Author: K2mia
*** UWC3 Module:   Mole Routines
*** Date:          May 25, 2004
*** Last Update:   September 27, 2004
*
*  Module: Mole Routines
*  Subroutines for handling MOLEs
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
// BEGIN amx_givemole routine
// Routine for making a mole
// **************************************************************************
public amx_givemole(id, level, cid){
   if (!(get_user_flags(id) & get_cvar_num("UW_admin_flag"))) {
      if(id != 0){
         client_print(id,print_console,"[%s] You have no access to that command", MOD)
         return PLUGIN_HANDLED
      }
   }

   new arg[32]
   read_argv(1,arg,31)
   if(equali(arg,"@ALL")){
      new players[32], inum
      get_players(players,inum)
      for(new a=0;a<inum;++a){
         playeritem2[players[a]]=MOLE
         hasmole[players[a]] = true
         displaylevel(id,0)
      }
      return PLUGIN_HANDLED
   }else if (arg[0]=='@'){
      new players[32], inum
      get_players(players,inum,"e",arg[1])
      if (inum==0){
         console_print(id,"No clients in such team")
         return PLUGIN_HANDLED
      }
      for(new a=0;a<inum;++a){
         playeritem2[players[a]]=MOLE
         hasmole[players[a]] = true
         displaylevel(id,0)
      }
   }else{
      new player = cmd_target2(id,arg)
      if (!player) return PLUGIN_HANDLED
      playeritem2[player]=MOLE
      hasmole[player] = true
      displaylevel(player,0)
   }

   return PLUGIN_HANDLED
}
// **************************************************************************
// END amx_givemole routine
// **************************************************************************


// **************************************************************************
// BEGIN check_spot, mole_T and mole_CT, transport routines
// Routines for handling Moles
// **************************************************************************
public check_spot(parm[]){
   new id = parm[0]

   client_print(id, print_console, "MIH check_spot!!!")

   if (get_user_team(id) == 1)
      mole_CT(id)
   else if (get_user_team(id) == 2)
      mole_T(id)
   else
      client_print(id, print_chat, "Join a Team First!")

   return PLUGIN_HANDLED

}

public mole_T(id){
   new numplayers = 0
   new Float:vicinity = 96.0
   new entsFound[1]
   new Float:origin[3]
   new porigin[3]
   new szEnt[32] = "info_player_deathmatch"
   new bool:spotOpen = false
   new teamnumber = get_user_team(id)
   new curEnt = find_ent_by_class( -1, szEnt );

   while ( curEnt > 0 ){
      numplayers = 0

      entity_get_vector( curEnt, EV_VEC_origin, origin)
      numplayers = find_sphere_class(0, "player", vicinity, entsFound, 1, origin)

      if (numplayers == 0){
         spotOpen = true
         break
      }
      curEnt = find_ent_by_class( curEnt, szEnt );
   }

   if (spotOpen){
      porigin[0] = floatround(origin[0])
      porigin[1] = floatround(origin[1])
      porigin[2] = floatround(origin[2])


      new parm2[6]
      parm2[0] = porigin[0]
      parm2[1] = porigin[1]
      parm2[2] = porigin[2]
      parm2[3] = 0
      parm2[4] = teamnumber
      parm2[5] = id
      set_task(0.1,"transport2",2,parm2,6)
   }else{
      client_print(id, print_chat,
         "No Terrorist mole locations available, will try again next round")
      return PLUGIN_HANDLED
   }


   return PLUGIN_HANDLED
}


public mole_CT(id){
   new numplayers = 0
   new Float:vicinity = 96.0
   new entsFound[1]
   new Float:origin[3]
   new porigin[3]
   new szEnt[32] = "info_player_start"
   new bool:spotOpen = false
   new teamnumber = get_user_team(id)
   new curEnt = find_ent_by_class( -1, szEnt );

   while ( curEnt > 0 ){
      numplayers = 0

      entity_get_vector( curEnt, EV_VEC_origin, origin)
      numplayers = find_sphere_class(0, "player", vicinity, entsFound, 1, origin)

      if (numplayers == 0){
         spotOpen = true
         break
      }
      curEnt = find_ent_by_class( curEnt, szEnt );
   }

   if (spotOpen){
      porigin[0] = floatround(origin[0])
      porigin[1] = floatround(origin[1])
      porigin[2] = floatround(origin[2])

      new parm2[6]
      parm2[0] = porigin[0]
      parm2[1] = porigin[1]
      parm2[2] = porigin[2]
      parm2[3] = 0
      parm2[4] = teamnumber
      parm2[5] = id
      set_task(0.1,"transport2",2,parm2,6)
   }else{
      client_print(id, print_chat,
         "No Counter-Terrorist mole locations available, will try again next round")
      return PLUGIN_HANDLED
   }

   return PLUGIN_HANDLED
}


public transport2(parm[6]){
   // Teleports the MOLE to the opposing team's base (new version)

   new id = parm[5]
   new origin[3]
   new Float:forigin[3]
   new Float:vicinity = 96.0
   new entsFound[1]

   origin[0] = parm[0]
   origin[1] = parm[1]
   origin[2] = parm[2]

   forigin[0] = float(parm[0])
   forigin[1] = float(parm[1])
   forigin[2] = float(parm[2])

   // Perform a final check to make sure this MOLE spot wasn't taken
   new numplayers = find_sphere_class(0, "player", vicinity, entsFound, 1, forigin)

   if (numplayers > 0){
      if (hasmole[id])
         client_print(id, print_chat,
            "A mole location was not found for you, item saved for next round")
      else
         client_print(id, print_chat,
            "A mole location was not found for you")
      return PLUGIN_HANDLED
   }

   client_print(id, print_chat, "Mole location ready, sending you to : < %d %d %d> ", origin[0], origin[1], origin[2])

   ismole[id]=true
   changeskin(id,0)
   set_user_origin(id,origin)

   message_begin(MSG_ONE,gmsgShake,{0,0,0},id)
   write_short(255<< 14 ) //ammount
   write_short(10 << 14) //lasts this long
   write_short(255<< 14) //frequency
   message_end()

   if (playeritem2[id] == MOLE)
      playeritem2[id] = 0

   hasmole[id] = false

   return PLUGIN_CONTINUE
}
// **************************************************************************
// END check_spot, mole_T, mole_CT, transport and other supporting mole routines
// **************************************************************************


// **************************************************************************
// BEGIN check_fan subroutine
// Check the fan of blades skill
// **************************************************************************
public check_fan(id){

   if (p_skills[id][SKILLIDX_FAN] && is_user_alive(id)){
      //Fan of Knives
      new Float:randomnumber = random_float(0.0,1.0)
      if (randomnumber <= p_fan[p_skills[id][SKILLIDX_FAN]-1]){
         new parm[2]
         parm[0]=id
         parm[1]=7
         set_task(0.1,"check_spot",id+12,parm,2)
      }
   }

}
// **************************************************************************
// END check_fan subroutine
// **************************************************************************


