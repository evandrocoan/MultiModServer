
/** *************************************************************************
*** AMXX Plugin:   Ultimate Warcraft3 (UWC3)
*** Plugin Author: K2mia
*** UWC3 Module:   Enhancements (Attributes / Resistances)
*** Date:          May 25, 2004
*** Last Update:   September 23, 2004
*
*  Module: Enhancements (Attributes / Resistances) 
*  Subroutines to handle enhancement training 
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
// BEGIN Enhancements Related Subroutines
// **************************************************************************


// **************************************************************************
// BEGIN select_attrib subroutine
// Attributes selection menu
// **************************************************************************
public select_attrib( id ){
   if (!warcraft3)
      return PLUGIN_CONTINUE

   if (!USE_ENH){
      client_print(id, print_center, "This server has restricted attribute enhancements")
      return PLUGIN_HANDLED
   }

   if (p_level[id] < enh_minlevel){
      client_print(id, print_center, 
         "[%s] You must reach level [%d] before you may enhance your attributes", 
         MOD, enh_minlevel)
      return PLUGIN_HANDLED
   }


   // Calculate how many attrib points can be spent
   new apts = get_availattribpts( id )


   new pos = 0, i, menu_body[512], menu_items[5][32]

   format(menu_items[0], 31, "Strength     [ %d/%d ]",
      p_attribs[id][ATTRIBIDX_STR], ATTRIB_MAX_VALUE)
   format(menu_items[1], 31, "Intellect    [ %d/%d ]",
      p_attribs[id][ATTRIBIDX_INT], ATTRIB_MAX_VALUE)
   format(menu_items[2], 31, "Dexterity    [ %d/%d ]",
      p_attribs[id][ATTRIBIDX_DEX], ATTRIB_MAX_VALUE)
   format(menu_items[3], 31, "Agility      [ %d/%d ]",
      p_attribs[id][ATTRIBIDX_AGI], ATTRIB_MAX_VALUE)
   format(menu_items[4], 31, "Constitution [ %d/%d ]",
      p_attribs[id][ATTRIBIDX_CON], ATTRIB_MAX_VALUE)

   new keys = (1<<0)|(1<<1)|(1<<2)|(1<<3)|(1<<4)|(1<<8)|(1<<9)

   pos += format(menu_body[pos], 511,
             "\ySelect an Attribute to enhance [%d pts remaining]: \w^n", apts )

   pos += format(menu_body[pos], 511, "\y(say /attribinfo for info about attributes) \w^n^n" )

   for (i = 0; i<5; i++){
      pos += format(menu_body[pos], 511-pos, "\w%d. %s^n",i+1,menu_items[i])
   }
   pos += format(menu_body[pos], 511-pos, "^n^n\w9. Resistances Menu")
   pos += format(menu_body[pos], 511-pos, "^n\w0. Exit")

   show_menu(id,keys,menu_body, -1)

   return PLUGIN_CONTINUE
}
// **************************************************************************
// END select_attrib subroutine
// **************************************************************************


// **************************************************************************
// BEGIN do_attribmenu subroutine
// Handler for the attributes menu
// **************************************************************************
public do_attribmenu(id, key){

   new name[32]
   get_user_name(id, name, 31)

   if (key == 8){
      select_resist(id)
      return PLUGIN_CONTINUE
   }

   if ( (key >= 0) && (key <= 7) ){
      if (p_attribs[id][key+1] >= ATTRIB_MAX_VALUE){
         // Player has trained the maximum for this attribute
         client_print(id, print_chat,
            "[%s] You have already reached the maximum enhancement level.", MOD )
         return PLUGIN_HANDLED
      }

      new extra_xp = (playerxp[id] - xplevel_lev[enh_minlevel])
      if (extra_xp < 0) extra_xp = 0
      new exp = (extra_xp / 10)

      // Calculate how many attrib points can be spent
      new acount = get_attribcount( id )
      new apts = get_availattribpts( id )

      if (apts <= 0){
         if (acount < ATTRIB_MAX_PTS){
            client_print(id, print_chat, 
               "[%s] You do not have any Attribute points to spend, earn more E-XP", MOD)
         }else{
            client_print(id, print_chat,
               "[%s] You have reached the server limit for obtainable Attribute points.",
               MOD)
         }
         return PLUGIN_HANDLED
      }

 
      // An enhancement pt was spent
      p_attribs[id][key+1] += 1

      // Call save routine
      if ( get_cvar_num("mp_sql") ){
         if ( !get_cvar_num("mp_sql_saveoncmdonly") )
            sqlwrite_enh_id( id, 1 )
      }else{
         write_enh_id(id)
      }

      new aname[32]
      if ( (key+1) == ATTRIBIDX_STR ) copy(aname, 31, "Strength")
      else if ( (key+1) == ATTRIBIDX_INT ) copy(aname, 31, "Intellect")
      else if ( (key+1) == ATTRIBIDX_DEX ) copy(aname, 31, "Dexterity")
      else if ( (key+1) == ATTRIBIDX_AGI ) copy(aname, 31, "Agility")
      else if ( (key+1) == ATTRIBIDX_CON ) copy(aname, 31, "Constitution")

      client_print(id, print_chat, "[%s] You spend 1 E-XP point to enhance your %s",
         MOD, aname)

      // Determine if there are additional E-XP pts to spend
      apts = ( exp / attrib_pt_cost ) - (acount + 1)

      // See what adjustments are needed for new skill
      if ( (key+1) == ATTRIBIDX_STR )
         set_maxhealth( id, false ) 
      else if ( (key+1) == ATTRIBIDX_CON )
         check_conregen( id )
      else if ( (key+1) == ATTRIBIDX_AGI ){
         // Call routine to set user runspeed
         new parm[1]
         parm[0]=id
         unholyspeed(parm)
      }

      if (apts > 0)
         select_attrib(id)
   }

   return PLUGIN_HANDLED
}
// **************************************************************************
// BEGIN do_attribmenu subroutine
// **************************************************************************


// **************************************************************************
// BEGIN select_resist subroutine
// Resistances selection menu
// **************************************************************************
public select_resist( id ){
   if (!warcraft3)
      return PLUGIN_CONTINUE

   if (!USE_ENH){
      client_print(id, print_center, "This server has restricted resistance enhancements")
      return PLUGIN_HANDLED
   }

   if (p_level[id] < enh_minlevel){
      client_print(id, print_center,
         "[%s] You must reach the minimum level [%d] before you may enhance your resistances",
          MOD, enh_minlevel)
      return PLUGIN_HANDLED
   }


   // Calculate how many attrib/resist points can be spent
   new rpts = get_availresistpts( id )

   new pos = 0, i, menu_body[512], menu_items[5][64]

   format(menu_items[0], 63, "Poison Resistance      [ %d/%d ]",
      p_resists[id][RESISTIDX_POISON], RESIST_MAX_VALUE)
   format(menu_items[1], 63, "Disease Resistance     [ %d/%d ]",
      p_resists[id][RESISTIDX_DISEASE], RESIST_MAX_VALUE)
   format(menu_items[2], 63, "Electricity Resistance [ %d/%d ]",
      p_resists[id][RESISTIDX_ELECTRIC], RESIST_MAX_VALUE)
   format(menu_items[3], 63, "Fire Resistance        [ %d/%d ]",
      p_resists[id][RESISTIDX_FIRE], RESIST_MAX_VALUE)
   format(menu_items[4], 63, "Magic Resistance       [ %d/%d ]",
      p_resists[id][RESISTIDX_MAGIC], RESIST_MAX_VALUE)

   new keys = (1<<0)|(1<<1)|(1<<2)|(1<<3)|(1<<4)|(1<<8)|(1<<9)

   pos += format(menu_body[pos], 511,
             "\ySelect a Resistance to enhance [%d pts remaining]: \w^n", rpts )

   pos += format(menu_body[pos], 511, "\y(say /resistinfo for info about resistances) \w^n^n" )

   for (i = 0; i< (MAX_RESISTS-1); i++){
      pos += format(menu_body[pos], 511-pos, "\w%d. %s^n",i+1,menu_items[i])
   }
   pos += format(menu_body[pos], 511-pos, "^n^n\w9. Attributes Menu")
   pos += format(menu_body[pos], 511-pos, "^n\w0. Exit")

   show_menu(id,keys,menu_body, -1)

   return PLUGIN_HANDLED
}
// **************************************************************************
// END select_resist subroutine
// **************************************************************************


// **************************************************************************
// BEGIN do_resistmenu subroutine
// Handler for the resistances menu
// **************************************************************************
public do_resistmenu(id,key){

   new name[32]
   get_user_name(id, name, 31)

   if (key == 8){
      select_attrib(id)
      return PLUGIN_CONTINUE
   }

   if ( (key >= 0) && (key <= 7) ){
      if (p_resists[id][key+1] >= RESIST_MAX_VALUE){
         // Player has trained the maximum for this resist
         client_print(id, print_chat,
            "[%s] You have already reached the maximum resistance level.", MOD )
         return PLUGIN_HANDLED
      }

      new extra_xp = (playerxp[id] - xplevel_lev[enh_minlevel])
      if (extra_xp < 0) extra_xp = 0
      new exp = (extra_xp / 10)

      // Calculate how many resist points can be spent
      new rcount = get_resistcount( id )
      new rpts = get_availresistpts( id )


      if (rpts <= 0){
         if (rcount < RESIST_MAX_PTS){
            client_print(id, print_chat, 
               "[%s] You do not have any Resistance points to spend, earn more E-XP", MOD)
         }else{
            client_print(id, print_chat,
               "[%s] You have reached the server limit for obtainable Resistance points.",
               MOD)
         }
         return PLUGIN_HANDLED
      }

      // An enhancement pt was spent
      p_resists[id][key+1] += 1

      // Call save routine
      if ( get_cvar_num("mp_sql") ){
         if ( !get_cvar_num("mp_sql_saveoncmdonly") )
            sqlwrite_enh_id( id, 1 )
      }else{
         write_enh_id(id)
      }

      new rname[32]
      if ( (key+1) == RESISTIDX_POISON ) copy(rname, 31, "Poison Resistance")
      else if ( (key+1) == RESISTIDX_DISEASE ) copy(rname, 31, "Disease Resistance")
      else if ( (key+1) == RESISTIDX_ELECTRIC ) copy(rname, 31, "Electricity Resistance")
      else if ( (key+1) == RESISTIDX_FIRE ) copy(rname, 31, "Fire Resistance")
      else if ( (key+1) == RESISTIDX_MAGIC ) copy(rname, 31, "Magic Resistance")

      client_print(id, print_chat, "[%s] You spend 1 E-XP point to enhance your %s",
         MOD, rname)

      // Determine if there are additional E-XP pts to spend
      rpts = ( exp / resist_pt_cost ) - (rcount + 1)

      if (rpts > 0)
         select_resist(id)
   }

   return PLUGIN_HANDLED
}
// **************************************************************************
// END do_resistmenu subroutine
// **************************************************************************


// **************************************************************************
// BEGIN get_attribcount subroutine
// Count the number of attributes a player is using
// **************************************************************************
public get_attribcount(id){

   new acount = 0

   for (new j=1; j< MAX_ATTRIBS; j++)
      acount += ( p_attribs[id][j] - ATTRIB_BASE )

   return acount
}
// **************************************************************************
// END get_attribcount subroutine
// **************************************************************************


// **************************************************************************
// BEGIN get_resistcount subroutine
// Count the number of resistance pts a player is using
// **************************************************************************
public get_resistcount(id){

   new rcount = 0

   for (new j=1; j< MAX_RESISTS; j++)
      rcount += p_resists[id][j]

   return rcount
}
// **************************************************************************
// END get_resistcount subroutine
// **************************************************************************


// **************************************************************************
// BEGIN get_availattribpts subroutine
// Count the number of available attribute pts for a player
// **************************************************************************
public get_availattribpts(id){

   // [11-01-04] To prevent divide by 0 errors - K2mia
   if (attrib_pt_cost <= 0)
      return 0

   // Calculate how many attrib/resist points can be spent
   new extra_xp = (playerxp[id] - xplevel_lev[enh_minlevel])
   if (extra_xp < 0) extra_xp = 0
   new exp = (extra_xp / 10)

   new acount = get_attribcount(id)

   new apts = ((exp / attrib_pt_cost) > ATTRIB_MAX_PTS) ? (ATTRIB_MAX_PTS - acount) :
              ((exp / attrib_pt_cost) - acount)

   // Prevent players from getting attrib points beyond their max allowed
   if ( (acount >= ((MAX_ATTRIBS-1) * (ATTRIB_MAX_VALUE - ATTRIB_BASE))) ||
        (acount >= ATTRIB_MAX_PTS) )
   {
      apts = 0
   }

   if (apts > ((MAX_ATTRIBS-1) * (ATTRIB_MAX_VALUE - ATTRIB_BASE)) )
      apts = ((MAX_ATTRIBS-1) * (ATTRIB_MAX_VALUE - ATTRIB_BASE)) - acount

   return apts
}
// **************************************************************************
// END get_availattribpts subroutine
// **************************************************************************


// **************************************************************************
// BEGIN get_availresistpts subroutine
// Count the number of available resistance pts for a player
// **************************************************************************
public get_availresistpts(id){

   // [11-01-04] To prevent divide by 0 errors - K2mia
   if (resist_pt_cost <= 0)
      return 0

   // Calculate how many attrib/resist points can be spent
   new extra_xp = (playerxp[id] - xplevel_lev[enh_minlevel])
   if (extra_xp < 0) extra_xp = 0
   new exp = (extra_xp / 10)

   new rcount = get_resistcount(id)

   new rpts = ((exp / resist_pt_cost) > RESIST_MAX_PTS) ? (RESIST_MAX_PTS - rcount) :
              ((exp / resist_pt_cost) - rcount)

   // Prevent players from getting resist points beyond their max allowed
   if ( (rcount >= ((MAX_RESISTS-1) * RESIST_MAX_VALUE)) ||
        (rcount >= RESIST_MAX_PTS) )
   {
      rpts = 0
   }

   if (rpts > ((MAX_RESISTS-1) * RESIST_MAX_VALUE) )
      rpts = ((MAX_RESISTS-1) * RESIST_MAX_VALUE) - rcount

   return rpts
}
// **************************************************************************
// END get_availresistpts subroutine
// **************************************************************************


// **************************************************************************
// BEGIN resetattribs subroutine
// Sets the flag to reset all attribute values to ATTRIB_BASE
// **************************************************************************
public resetattribs(id){
   if (!warcraft3)
     return PLUGIN_CONTINUE
         
   if (get_cvar_num("FT_reset_skills")){
      client_print(id, print_center, "Your attributes will be reset next round")
      resetattrib[id] = true
   }else{
      client_print(id, print_center, "This server has disabled that option")
      resetattrib[id] = false
   }     
         
   return PLUGIN_HANDLED
}     
// **************************************************************************
// END resetattribs subroutine
// **************************************************************************
   

// **************************************************************************
// BEGIN resetresists subroutine
// Sets the flag to reset all resistance values to ATTRIB_BASE
// **************************************************************************
public resetresists(id){
   if (!warcraft3)
     return PLUGIN_CONTINUE

   if (get_cvar_num("FT_reset_skills")){
      client_print(id, print_center, "Your resistances will be reset next round")
      resetresist[id] = true
   }else{
      client_print(id, print_center, "This server has disabled that option")
      resetresist[id] = false
   }

   return PLUGIN_HANDLED
}
// **************************************************************************
// END resetresists subroutine
// **************************************************************************


// **************************************************************************
// BEGIN magic_saving_throw routine
// Routine to check for a magic saving throw
// **************************************************************************
public magic_saving_throw(id){

   if (USE_ENH && p_resists[id][RESISTIDX_MAGIC]){
      new Float:randomnumber = random_float(0.0,1.0)
      new Float:tosave = float(p_resists[id][RESISTIDX_MAGIC]) / float(RESIST_MAX_VALUE)

      //new bool:bSaves = (randomnumber <= tosave)
      //client_print(id, print_console, "DEBUG: rnum=(%f) tosave=(%f) saves=(%d)",
      //   randomnumber, tosave, bSaves)

      if (randomnumber <= tosave)
         return 1
   }

   return 0

}
// **************************************************************************
// END magic_saving_throw routine
// **************************************************************************


// **************************************************************************
// BEGIN con_heal subroutine
// Heal routine for the Constitution attribute
// **************************************************************************
public con_heal(parm[]){
   
   new id = parm[0]
   new heal = parm[1]
   new Float:interval = CON_HEAL_INTERVAL
   
   if (!endround && is_user_alive(id) && (p_attribs[id][ATTRIBIDX_CON] > ATTRIB_BASE) ){
      new econ = (p_attribs[id][ATTRIBIDX_CON] - ATTRIB_BASE)
      if (econ != heal){
         parm[1] = econ
         heal = econ 
      }
      set_task(interval, "con_heal", id+1100, parm, 2)
   }
   
   new health = 0
   new bool:was_healed = false
   

   health = maxhealth[id] + (playeritem[id] == HEALTH ? HEALTHBONUS : 0)

   if (get_user_health(id) < health){
      was_healed = true
      set_user_health_log(id, get_user_health(id)+heal, true, "con_heal() HEAL")
   }   
   

   // [09-26-04] Adjustment if maxhealth exceeded - K2mia
   if (get_user_health(id) > health)
      set_user_health_log(id, health, true, "con_heal() ADJUST")
   
      
   if (!was_healed)
      return PLUGIN_CONTINUE  
      
   new origin[3]
   get_user_origin(id, origin)
      
   if(playeritem[id]!=CLOAK && (!p_skills[id][SKILLIDX_INVIS])){
      message_begin( MSG_BROADCAST, SVC_TEMPENTITY );
      write_byte( TE_IMPLOSION );
      write_coord(origin[0])  // initial position
      write_coord(origin[1])  // initial position
      write_coord(origin[2])  // initial position
      write_byte(100)   // radius
      write_byte( 8 );  // count
      write_byte( 1 );  // life
      message_end();
   }

   return PLUGIN_CONTINUE
}
// **************************************************************************
// END con_heal subroutine
// **************************************************************************


// **************************************************************************
// END Enhancements Related Subroutines
// **************************************************************************
