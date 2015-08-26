
/** *************************************************************************
*** AMXX Plugin:   Ultimate Warcraft3 (UWC3)
*** Plugin Author: K2mia
*** UWC3 Module:   Vaul / SQL Storage
*** Date:          May 25, 2004
*** Last Update:   September 24, 2004
*
*  Module: Vault / SQL Storage
*  Subroutines to handle saving XP / Resists / Attribs
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
// BEGIN Vault and SQL Storage Subroutines
// **************************************************************************


// **************************************************************************
// BEGIN check_sql and grab_sql_vars subroutines
// Check if mp_sqp is set and load sql config file if so
// **************************************************************************
public check_sql(){

   new basedir[64]
   new sql_cfgfile[64]
   get_customdir(basedir, 63)

   // [09-08-04] Added SQL support, config file loading
   if (get_cvar_num("mp_sql") == 1){
      format(sql_cfgfile, 63, "%s/UWC3/UWC3_sql.cfg", basedir)
      if (file_exists(sql_cfgfile)){
         log_amx("UWC3 SQL :: Loading Configuration File...")
         server_cmd("exec %s", sql_cfgfile)
         log_amx("UWC3 SQL :: Configuration File Loaded [OK]")

         set_task(0.6, "grab_sql_vars", 824)

      }else{
         log_amx("UWC3 SQL :: Configuration File NOT FOUND, Switching to Fast XP Mode")
         set_cvar_num("mp_savexp", 0)
         set_cvar_num("mp_sql", 0)
      }
   }

   return PLUGIN_CONTINUE
}

public grab_sql_vars(){

   get_cvar_string("UW_sql_host", sqlhost, 63)
   get_cvar_string("UW_sql_user", sqluser, 31)
   get_cvar_string("UW_sql_pass", sqlpass, 31)
   get_cvar_string("UW_sql_db", sqldb, 31)

   log_amx("UWC3 SQL :: Config Report: host=(%s) user=(%s) pass=(*) db=(%s)",
           sqlhost, sqluser, sqldb)

   new Sql:sql = dbi_connect(sqlhost, sqluser, sqlpass, sqldb, sqlerror, 127)
   if (sql <= SQL_FAILED) {
     log_amx("UWC3 SQL :: Connect Error [ %s ]", sqlerror)
     return PLUGIN_HANDLED
   }else{
     log_amx("UWC3 SQL :: Connected [OK]" )
   }

   // Create the uwc3_xp table if necessary
   dbi_query(sql, "CREATE TABLE IF NOT EXISTS %s ( name VARCHAR(32) NOT NULL, steamid VARCHAR(32) NOT NULL, xp INT, ip VARCHAR(32), mtime VARCHAR(32), PRIMARY KEY ( steamid ) )", sqltable_xp)

   if (get_cvar_num("mp_sql_saveby") == SQL_SAVEBY_NAME){
      dbi_query(sql, "ALTER TABLE %s DROP PRIMARY KEY, ADD PRIMARY KEY ( name )", sqltable_xp)
   }else{
      dbi_query(sql, "ALTER TABLE %s DROP PRIMARY KEY, ADD PRIMARY KEY ( steamid )", sqltable_xp)
   }

   /*
   new squery[2048]
   new len = 0
   len += format(squery[len], 512, "CREATE TABLE IF NOT EXISTS %s ( name VARCHAR(32) NOT NULL, steamid VARCHAR(32) NOT NULL, nset TINYINT NOT NULL, skill1 SMALLINT, skill2 SMALLINT, skill3 SMALLINT, skill4 SMALLINT, skill5 SMALLINT, skill6 SMALLINT, skill7 SMALLINT, skill8 SMALLINT, skill9 SMALLINT, skill10 SMALLINT, ", sqltable_skills)
   len += format(squery[len], 512-len, "skill11 SMALLINT, skill12 SMALLINT, skill13 SMALLINT, skill14 SMALLINT, skill15 SMALLINT, skill16 SMALLINT, skill17 SMALLINT, skill18 SMALLINT, skill19 SMALLINT, skill20 SMALLINT, ")
   len += format(squery[len], 512-len, "skill21 SMALLINT, skill22 SMALLINT, skill23 SMALLINT, skill24 SMALLINT, skill25 SMALLINT, skill26 SMALLINT, skill27 SMALLINT, skill28 SMALLINT, skill29 SMALLINT, skill30 SMALLINT, ")
   len += format(squery[len], 512-len, "skill31 SMALLINT, skill32 SMALLINT, skill33 SMALLINT, skill34 SMALLINT, skill35 SMALLINT, skill36 SMALLINT, skill37 SMALLINT, skill38 SMALLINT, skill39 SMALLINT, skill40 SMALLINT, PRIMARY KEY ( steamid, nset ) )")
   dbi_query(sql, "%s", squery)

   if (get_cvar_num("mp_sql_saveby") == SQL_SAVEBY_NAME){
      dbi_query(sql, "ALTER TABLE %s DROP PRIMARY KEY, ADD PRIMARY KEY ( name, nset )", sqltable_skills)
   }else{
      dbi_query(sql, "ALTER TABLE %s DROP PRIMARY KEY, ADD PRIMARY KEY ( steamid, nset )", sqltable_skills)
   }
   */

   dbi_query(sql, "CREATE TABLE IF NOT EXISTS %s ( name VARCHAR(32) NOT NULL, steamid VARCHAR(32) NOT NULL, nset TINYINT NOT NULL, skill1 SMALLINT, skill2 SMALLINT, skill3 SMALLINT, skill4 SMALLINT, skill5 SMALLINT, skill6 SMALLINT, skill7 SMALLINT, skill8 SMALLINT, skill9 SMALLINT, skill10 SMALLINT, PRIMARY KEY ( steamid, nset ) )", sqltable_skills1)
   dbi_query(sql, "CREATE TABLE IF NOT EXISTS %s ( name VARCHAR(32) NOT NULL, steamid VARCHAR(32) NOT NULL, nset TINYINT NOT NULL, skill11 SMALLINT, skill12 SMALLINT, skill13 SMALLINT, skill14 SMALLINT, skill15 SMALLINT, skill16 SMALLINT, skill17 SMALLINT, skill18 SMALLINT, skill19 SMALLINT, skill20 SMALLINT, PRIMARY KEY ( steamid, nset ) )", sqltable_skills2)
   dbi_query(sql, "CREATE TABLE IF NOT EXISTS %s ( name VARCHAR(32) NOT NULL, steamid VARCHAR(32) NOT NULL, nset TINYINT NOT NULL, skill21 SMALLINT, skill22 SMALLINT, skill23 SMALLINT, skill24 SMALLINT, skill25 SMALLINT, skill26 SMALLINT, skill27 SMALLINT, skill28 SMALLINT, skill29 SMALLINT, skill30 SMALLINT, PRIMARY KEY ( steamid, nset ) )", sqltable_skills3)
   dbi_query(sql, "CREATE TABLE IF NOT EXISTS %s ( name VARCHAR(32) NOT NULL, steamid VARCHAR(32) NOT NULL, nset TINYINT NOT NULL, skill31 SMALLINT, skill32 SMALLINT, skill33 SMALLINT, skill34 SMALLINT, skill35 SMALLINT, skill36 SMALLINT, skill37 SMALLINT, skill38 SMALLINT, skill39 SMALLINT, skill40 SMALLINT, PRIMARY KEY ( steamid, nset ) )", sqltable_skills4)

   if (get_cvar_num("mp_sql_saveby") == SQL_SAVEBY_NAME){
      dbi_query(sql, "ALTER TABLE %s DROP PRIMARY KEY, ADD PRIMARY KEY ( name, nset )", sqltable_skills1)
      dbi_query(sql, "ALTER TABLE %s DROP PRIMARY KEY, ADD PRIMARY KEY ( name, nset )", sqltable_skills2)
      dbi_query(sql, "ALTER TABLE %s DROP PRIMARY KEY, ADD PRIMARY KEY ( name, nset )", sqltable_skills3)
      dbi_query(sql, "ALTER TABLE %s DROP PRIMARY KEY, ADD PRIMARY KEY ( name, nset )", sqltable_skills4)
   }else{
      dbi_query(sql, "ALTER TABLE %s DROP PRIMARY KEY, ADD PRIMARY KEY ( steamid, nset )", sqltable_skills1)
      dbi_query(sql, "ALTER TABLE %s DROP PRIMARY KEY, ADD PRIMARY KEY ( steamid, nset )", sqltable_skills2)
      dbi_query(sql, "ALTER TABLE %s DROP PRIMARY KEY, ADD PRIMARY KEY ( steamid, nset )", sqltable_skills3)
      dbi_query(sql, "ALTER TABLE %s DROP PRIMARY KEY, ADD PRIMARY KEY ( steamid, nset )", sqltable_skills4)
   }

   // Create the uwc3_enh table if necessary
   dbi_query(sql, "CREATE TABLE IF NOT EXISTS %s ( name VARCHAR(32) NOT NULL, steamid VARCHAR(32) NOT NULL, nset TINYINT NOT NULL, att1 SMALLINT, att2 SMALLINT, att3 SMALLINT, att4 SMALLINT, att5 SMALLINT, res1 SMALLINT, res2 SMALLINT, res3 SMALLINT, res4 SMALLINT, res5 SMALLINT, PRIMARY KEY ( steamid, nset ) ) ", sqltable_enh)

   if (get_cvar_num("mp_sql_saveby") == SQL_SAVEBY_NAME){
      dbi_query(sql, "ALTER TABLE %s DROP PRIMARY KEY, ADD PRIMARY KEY ( name, nset )", sqltable_enh)
   }else{
      dbi_query(sql, "ALTER TABLE %s DROP PRIMARY KEY, ADD PRIMARY KEY ( steamid, nset )", sqltable_enh)
   }

   dbi_close(sql)

   return PLUGIN_CONTINUE
}
// **************************************************************************
// END check_sql and grab_sql_vars subroutines
// **************************************************************************



// **************************************************************************
// BEGIN sqlwrite_xp_id subroutine
// Write a player's xp / info to the SQL table
// **************************************************************************
public sqlwrite_xp_id(id){

   if (!warcraft3)
      return PLUGIN_HANDLED

   if (!get_cvar_num("mp_savexp") || !get_cvar_num("mp_sql") || xpreadytoload[id]){
      // Do not write XP if it mp_savexp not set or xp hasn't been loaded yet
      // or if mp_sql mode not set
      //log_amx("In write_xp_id() id=(%d) mp_savexp=(%d) xpready=(%d)",
      //   id, get_cvar_num("mp_savexp"), xpreadytoload[id])
      return PLUGIN_CONTINUE
   }


   new playerid[32], playername[32], timet[32], ip[32]

   get_time("%m %d %H %M", timet, 31)
   get_user_authid(id, playerid, 31)
   get_user_name(id, playername, 31)
   get_user_ip(id, ip, 31)

   replaceall(playername, 32, "'", "")

   if (playerxp[id] <= 150){
      // Do not save XP if <= 150
      //log_amx("In write_xp_id() id=(%d) playerxp=(%d) Not enough XP to save",
      //  id, playerxp[id] )
      return PLUGIN_CONTINUE
   }

   // Connect to the SQL server and create the tables if they do not exist
   new Sql:sql = dbi_connect(sqlhost, sqluser, sqlpass, sqldb, sqlerror, 127)
   if (sql <= SQL_FAILED) {
     log_amx("UWC3 SQL :: sqlwrite_xp_id() :: Connect Error: %s", sqlerror)
     return PLUGIN_HANDLED
   }

   dbi_query(sql,"REPLACE INTO %s (name, steamid, xp, ip, mtime) VALUES ('%s', '%s', '%d', '%s', '%s')", sqltable_xp, playername, playerid, playerxp[id], ip, timet )

   dbi_close(sql)

   return PLUGIN_CONTINUE

}
// **************************************************************************
// END sqlwrite_xp_id subroutine
// **************************************************************************



// **************************************************************************
// BEGIN write_xp_id subroutine
// Write a player's xp / info to the vault
// **************************************************************************
public write_xp_id(id){
   if (!warcraft3)
      return PLUGIN_HANDLED
   
   if (!get_cvar_num("mp_savexp") || xpreadytoload[id]){
      // Do not write XP if it mp_savexp not set or xp hasn't been loaded yet
      //log_amx("In write_xp_id() id=(%d) mp_savexp=(%d) xpready=(%d)",
      //   id, get_cvar_num("mp_savexp"), xpreadytoload[id])
      return PLUGIN_CONTINUE
   }

   new playerid[32], playername[32], timet[32], ip[32]
   new pkey[128]
   new pdata[512]
   
   get_time("%m %d %H %M", timet, 31)
   get_user_authid(id, playerid, 31)
   get_user_name(id, playername, 31)
   get_user_ip(id, ip, 31)
   
   if (playerxp[id] <= 150){
      // Do not save XP if <= 150
      //log_amx("In write_xp_id() id=(%d) playerxp=(%d) Not enough XP to save",
      //  id, playerxp[id] )
      return PLUGIN_CONTINUE
   }  
   
   format(pdata, 255, "%s %d %s %s", playerid, playerxp[id], ip, timet)
   
   format(pkey, 127, "%s", playerid ) 
   set_vaultdata(pkey, pdata)
     
   return PLUGIN_CONTINUE
}  
// **************************************************************************
// END write_xp_id subroutine
// **************************************************************************

   
// **************************************************************************
// BEGIN sqlwrite_enh_id subroutine
// Write a player's enh info (attribs / resists) to the SQL table
// **************************************************************************
public sqlwrite_enh_id(id, nset){

   if (!warcraft3)
      return PLUGIN_HANDLED

   if (!get_cvar_num("mp_savexp") || !get_cvar_num("mp_sql") ){
      // Do not write XP if it mp_savexp not set or mp_sql not set
      //log_amx("In write_xp_id() id=(%d) mp_savexp=(%d) xpready=(%d)",
      //   id, get_cvar_num("mp_savexp"), xpreadytoload[id])
      return PLUGIN_CONTINUE
   }

   if ((nset < 1) || (nset > 4)) nset = 1


   new playerid[32], playername[32]

   get_user_authid(id, playerid, 31)
   get_user_name(id, playername, 31)

   replaceall(playername, 32, "'", "")


   // Connect to the SQL server and create the tables if they do not exist
   new Sql:sql = dbi_connect(sqlhost, sqluser, sqlpass, sqldb, sqlerror, 127)
   if (sql <= SQL_FAILED) {
     log_amx("UWC3 SQL :: sqlwrite_enh_id() :: Connect Error: %s", sqlerror)
     return PLUGIN_HANDLED
   }

   new squery[1024]

   format(squery, 1024, "REPLACE INTO %s (name, steamid, nset, att1, att2, att3, att4, att5, res1, res2, res3, res4, res5) VALUES ('%s', '%s', '%d', '%d', '%d', '%d', '%d', '%d', '%d', '%d', '%d', '%d', '%d')", sqltable_enh, playername, playerid, nset, p_attribs[id][1], p_attribs[id][2], p_attribs[id][3], p_attribs[id][4], p_attribs[id][5], p_resists[id][1], p_resists[id][2], p_resists[id][3], p_resists[id][4], p_resists[id][5])

   dbi_query(sql, "%s", squery)

   dbi_close(sql)

   return PLUGIN_CONTINUE

}
// **************************************************************************
// END sqlwrite_enh_id subroutine
// **************************************************************************


// **************************************************************************
// BEGIN write_enh_id subroutine
// Write a player's enhancements (attributes/resists) info to the vault
// **************************************************************************
public write_enh_id(id){
   if (!warcraft3)
      return PLUGIN_HANDLED

   if (!get_cvar_num("mp_savexp") || xpreadytoload[id]){
      // Do not write XP if it mp_savexp not set or xp hasn't been loaded yet
      //log_amx("In write_xp_id() id=(%d) mp_savexp=(%d) xpready=(%d)",
      //   id, get_cvar_num("mp_savexp"), xpreadytoload[id])
      return PLUGIN_CONTINUE
   }

   new playerid[32]
   new pkey[128]
   new pdata[128]

   get_user_authid(id, playerid, 31)

   format(pkey, 127, "%s_enh", playerid )
   format(pdata, 127, "%d %d %d %d %d %d %d %d %d %d", p_attribs[id][ATTRIBIDX_STR], p_attribs[id][ATTRIBIDX_INT], p_attribs[id][ATTRIBIDX_DEX], p_attribs[id][ATTRIBIDX_AGI], p_attribs[id][ATTRIBIDX_CON], p_resists[id][RESISTIDX_POISON], p_resists[id][RESISTIDX_DISEASE], p_resists[id][RESISTIDX_ELECTRIC], p_resists[id][RESISTIDX_FIRE], p_resists[id][RESISTIDX_MAGIC] )

   set_vaultdata(pkey, pdata)

   return PLUGIN_CONTINUE

}
// **************************************************************************
// END write_enh_id subroutine
// **************************************************************************


// **************************************************************************
// BEGIN sqlwrite_skills_id subroutine
// Write a player's enh info (attribs / resists) to the SQL table
// **************************************************************************
public sqlwrite_skills_id(id, sidx, nset){

   if (!warcraft3)
      return PLUGIN_HANDLED

   if (!get_cvar_num("mp_savexp") || !get_cvar_num("mp_sql") ){
      // Do not write XP if it mp_savexp not set or mp_sql not set
      //log_amx("In write_xp_id() id=(%d) mp_savexp=(%d) xpready=(%d)",
      //   id, get_cvar_num("mp_savexp"), xpreadytoload[id])
      return PLUGIN_CONTINUE
   }


   new playerid[32], playername[32]

   get_user_authid(id, playerid, 31)
   get_user_name(id, playername, 31)

   replaceall(playername, 32, "'", "")

   new squery[1024]

   sidx = -1	// This should fix the extra skills bug, force all skills to save

   if ( sidx == -1 ){
      // Special Case - save all 4 skills tables

      // Connect to the SQL server and create the tables if they do not exist
      new Sql:sql = dbi_connect(sqlhost, sqluser, sqlpass, sqldb, sqlerror, 127)
      if (sql <= SQL_FAILED) {
         log_amx("UWC3 SQL :: sqlwrite_skills_id() :: Connect Error: %s", sqlerror)
         return PLUGIN_HANDLED
      }

      format( squery, 256, "REPLACE INTO %s (name, steamid, nset, skill1, skill2, skill3, skill4, skill5, skill6, skill7, skill8, skill9, skill10) VALUES ('%s', '%s', '%d', '%d', '%d', '%d', '%d', '%d', '%d', '%d', '%d', '%d', '%d')", sqltable_skills1, playername, playerid, nset, p_skills[id][1],  p_skills[id][2],  p_skills[id][3],  p_skills[id][4],  p_skills[id][5],  p_skills[id][6],  p_skills[id][7],  p_skills[id][8],  p_skills[id][9],  p_skills[id][10] )

      dbi_query(sql, "%s", squery)

      format( squery, 256, "REPLACE INTO %s (name, steamid, nset, skill11, skill12, skill13, skill14, skill15, skill16, skill17, skill18, skill19, skill20) VALUES ('%s', '%s', '%d', '%d', '%d', '%d', '%d', '%d', '%d', '%d', '%d', '%d', '%d')", sqltable_skills2, playername, playerid, nset, p_skills[id][11],  p_skills[id][12],  p_skills[id][13],  p_skills[id][14],  p_skills[id][15],  p_skills[id][16],  p_skills[id][17],  p_skills[id][18],  p_skills[id][19],  p_skills[id][20] )

      dbi_query(sql, "%s", squery)

      format( squery, 256, "REPLACE INTO %s (name, steamid, nset, skill21, skill22, skill23, skill24, skill25, skill26, skill27, skill28, skill29, skill30) VALUES ('%s', '%s', '%d', '%d', '%d', '%d', '%d', '%d', '%d', '%d', '%d', '%d', '%d')", sqltable_skills3, playername, playerid, nset, p_skills[id][21],  p_skills[id][22],  p_skills[id][23],  p_skills[id][24],  p_skills[id][25],  p_skills[id][26],  p_skills[id][27],  p_skills[id][28],  p_skills[id][29],  p_skills[id][30] )

      dbi_query(sql, "%s", squery)

      format( squery, 256, "REPLACE INTO %s (name, steamid, nset, skill31, skill32, skill33, skill34, skill35, skill36, skill37, skill38, skill39, skill40) VALUES ('%s', '%s', '%d', '%d', '%d', '%d', '%d', '%d', '%d', '%d', '%d', '%d', '%d')", sqltable_skills4, playername, playerid, nset, p_skills[id][31],  p_skills[id][32],  p_skills[id][33],  p_skills[id][34],  p_skills[id][35],  p_skills[id][36],  p_skills[id][37],  p_skills[id][38],  p_skills[id][39],  p_skills[id][40] )

      dbi_query(sql, "%s", squery)

      dbi_close(sql)

      return PLUGIN_CONTINUE

   }else if ( (sidx >= 1) && (sidx <= 10)){
      format( squery, 256, "REPLACE INTO %s (name, steamid, nset, skill1, skill2, skill3, skill4, skill5, skill6, skill7, skill8, skill9, skill10) VALUES ('%s', '%s', '%d', '%d', '%d', '%d', '%d', '%d', '%d', '%d', '%d', '%d', '%d')", sqltable_skills1, playername, playerid, nset, p_skills[id][1],  p_skills[id][2],  p_skills[id][3],  p_skills[id][4],  p_skills[id][5],  p_skills[id][6],  p_skills[id][7],  p_skills[id][8],  p_skills[id][9],  p_skills[id][10] )
   }else if ( (sidx >= 11) && (sidx <= 20)){
      format( squery, 256, "REPLACE INTO %s (name, steamid, nset, skill11, skill12, skill13, skill14, skill15, skill16, skill17, skill18, skill19, skill20) VALUES ('%s', '%s', '%d', '%d', '%d', '%d', '%d', '%d', '%d', '%d', '%d', '%d', '%d')", sqltable_skills2, playername, playerid, nset, p_skills[id][11],  p_skills[id][12],  p_skills[id][13],  p_skills[id][14],  p_skills[id][15],  p_skills[id][16],  p_skills[id][17],  p_skills[id][18],  p_skills[id][19],  p_skills[id][20] )
   }else if ( (sidx >= 21) && (sidx <= 30)){
      format( squery, 256, "REPLACE INTO %s (name, steamid, nset, skill21, skill22, skill23, skill24, skill25, skill26, skill27, skill28, skill29, skill30) VALUES ('%s', '%s', '%d', '%d', '%d', '%d', '%d', '%d', '%d', '%d', '%d', '%d', '%d')", sqltable_skills3, playername, playerid, nset, p_skills[id][21],  p_skills[id][22],  p_skills[id][23],  p_skills[id][24],  p_skills[id][25],  p_skills[id][26],  p_skills[id][27],  p_skills[id][28],  p_skills[id][29],  p_skills[id][30] )
   }else if ( (sidx >= 31) && (sidx <= 40)){
      format( squery, 256, "REPLACE INTO %s (name, steamid, nset, skill31, skill32, skill33, skill34, skill35, skill36, skill37, skill38, skill39, skill40) VALUES ('%s', '%s', '%d', '%d', '%d', '%d', '%d', '%d', '%d', '%d', '%d', '%d', '%d')", sqltable_skills4, playername, playerid, nset, p_skills[id][31],  p_skills[id][32],  p_skills[id][33],  p_skills[id][34],  p_skills[id][35],  p_skills[id][36],  p_skills[id][37],  p_skills[id][38],  p_skills[id][39],  p_skills[id][40] )
   }


   // Connect to the SQL server and create the tables if they do not exist
   new Sql:sql = dbi_connect(sqlhost, sqluser, sqlpass, sqldb, sqlerror, 127)
   if (sql <= SQL_FAILED) {
     log_amx("UWC3 SQL :: sqlwrite_skills_id() :: Connect Error: %s", sqlerror)
     return PLUGIN_HANDLED
   }

   //log_amx("In sqlwrite_skills_id: sidx=(%d) sq=(%s)", sidx, squery)

   dbi_query(sql, "%s", squery)

   dbi_close(sql)

   return PLUGIN_CONTINUE

}
// **************************************************************************
// END sqlwrite_skills_id subroutine
// **************************************************************************



// **************************************************************************
// BEGIN write_skills_id subroutine
// Write a player's skills settings to the vault
// **************************************************************************
public write_skills_id(id, set){
   if (!warcraft3)
      return PLUGIN_HANDLED

   if (!get_cvar_num("mp_savexp") || xpreadytoload[id]){
      // Do not write XP if it mp_savexp not set or xp hasn't been loaded yet
      //log_amx("In write_xp_id() id=(%d) mp_savexp=(%d) xpready=(%d)",
      //   id, get_cvar_num("mp_savexp"), xpreadytoload[id])
      return PLUGIN_CONTINUE
   }

   if (set < 1 || set > 4){
      // set will allow multiple skillsets to be saved and retrieved
      set = 1
   }

   new pkey[128]
   new playerid[32]
   new temp1[256]
   new temp2[256]
   new temp3[256]
   new temp4[256]
   new pdata[512]

   get_user_authid(id, playerid, 31)

   format(pkey, 127, "%s_%d", playerid, set )

   format(temp1, 255, "%d %d %d %d %d %d %d %d %d %d", p_skills[id][1], p_skills[id][2], p_skills[id][3], p_skills[id][4], p_skills[id][5], p_skills[id][6], p_skills[id][7], p_skills[id][8], p_skills[id][9], p_skills[id][10])
   format(temp2, 255, "%d %d %d %d %d %d %d %d %d %d", p_skills[id][11], p_skills[id][12], p_skills[id][13], p_skills[id][14], p_skills[id][15], p_skills[id][16], p_skills[id][17], p_skills[id][18], p_skills[id][19], p_skills[id][20])
   format(temp3, 255, "%d %d %d %d %d %d %d %d %d %d", p_skills[id][21], p_skills[id][22], p_skills[id][23], p_skills[id][24], p_skills[id][25], p_skills[id][26], p_skills[id][27], p_skills[id][28], p_skills[id][29], p_skills[id][30])
   format(temp4, 255, "%d %d %d %d %d %d %d %d %d %d", p_skills[id][31], p_skills[id][32], p_skills[id][33], p_skills[id][34], p_skills[id][35], p_skills[id][36], p_skills[id][37], p_skills[id][38], p_skills[id][39], p_skills[id][40] )
   format(pdata, 255, "%s %s %s %s", temp1, temp2, temp3, temp4)

   set_vaultdata(pkey, pdata)

   return PLUGIN_CONTINUE

}
// **************************************************************************
// END write_skills_id subroutine
// **************************************************************************


// **************************************************************************
// BEGIN write_all_xp subroutine
// Call routines to write all player's xp
// **************************************************************************
public write_all(){
   if (!warcraft3)
      return PLUGIN_HANDLED

   new players[32], numofplayers, id, i
   get_players(players, numofplayers)

   for (i=0; i<numofplayers; i++){
      id = players[i]
      if (get_cvar_num("mp_sql") && !get_cvar_num("mp_sql_saveoncmdonly") )
         sqlwrite_xp_id(id)
      else
         write_xp_id(id)
   }

   return PLUGIN_CONTINUE
}
// **************************************************************************
// END write_all_xp subroutine
// **************************************************************************



// **************************************************************************
// BEGIN sqlget_xp_id subroutine
// Retrieve a player's xp from the sql server
// **************************************************************************
public sqlget_xp_id(id){
   if (!warcraft3)
      return PLUGIN_HANDLED

   if ( !get_cvar_num("mp_savexp") || !get_cvar_num("mp_sql") )
      return PLUGIN_CONTINUE

   new playerid[32], playername[32], error[128]

   get_user_authid(id, playerid, 31)
   get_user_name(id, playername, 31)

   replaceall(playername, 32, "'", "")

   // Connect to the SQL server and create the tables if they do not exist
   new Sql:sql = dbi_connect(sqlhost, sqluser, sqlpass, sqldb, sqlerror, 127)
   if (sql <= SQL_FAILED) {
     log_amx("UWC3 SQL :: sqlget_xp_id() :: Connect Error: %s", sqlerror)
     return PLUGIN_HANDLED
   }

   new Result:Res

   if ( get_cvar_num("mp_sql_saveby") == SQL_SAVEBY_NAME ){
      Res = dbi_query(sql,"SELECT name, steamid, xp, ip, mtime FROM %s WHERE name = '%s'", sqltable_xp, playername )
   }else{
      Res = dbi_query(sql,"SELECT name, steamid, xp, ip, mtime FROM %s WHERE steamid = '%s'", sqltable_xp, playerid )
   }

   if (Res == RESULT_FAILED) {
      dbi_error(sql,error,127)
      client_print(id, print_chat,
         "[%s] Error Retrieving Your SQL Data: [ %s ]", MOD, error)
      dbi_free_result(Res)
      dbi_close(sql)
      return PLUGIN_CONTINUE
   }else if (Res == RESULT_NONE) {
      client_print(id, print_chat, "[%s] No Saved XP SQL Data Found for Player %s",
         MOD, playername )
      dbi_free_result(Res)
      dbi_close(sql)
      return PLUGIN_CONTINUE
   }

   new name[32], pid[32], ip[32], mtime[32], xp

   if ( dbi_nextrow(Res) > 0 ){
      dbi_result(Res, "name", name, 31)
      dbi_result(Res, "steamid", pid, 31)
      xp = dbi_result(Res, "xp" )
      dbi_result(Res, "ip", ip, 31)
      dbi_result(Res, "mtime", mtime, 31)

      playerxp[id] = xp

      displaylevel(id, 0)

      log_amx("UWC3 SQL :: XP Table Loaded [OK] : name=(%s) steamid=(%s) xp=(%d) last_ip=(%s) last_savetime=(%s)", name, pid, xp, ip, mtime)
   }

   dbi_close(sql)

   return PLUGIN_CONTINUE
}
// **************************************************************************
// END sqlget_xp_id subroutine
// **************************************************************************


// **************************************************************************
// BEGIN get_xp_id subroutine
// Retrieve a player's xp from the vault
// **************************************************************************
public get_xp_id(id){
   if (!warcraft3)
      return PLUGIN_HANDLED

   if (!get_cvar_num("mp_savexp"))
      return PLUGIN_CONTINUE

   new playerid[32]
   new playername[32]
   new ip[32]
   new xp[32]
   new tmth[32], tday[32], thr[32], tmin[32]


   get_user_name(id, playername, 31)
   get_user_authid(id, playerid, 31)
   get_user_ip(id, ip, 31)

   new pkey[128] = ""
   new pdata[512] = ""
   new temp1[512] = ""
   new temp2[512] = ""

   format(pkey, 127, "%s", playerid )

   new attempt = get_vaultdata(pkey, pdata, 511)

   if (attempt){
      //server_print("From Vault for (%s)- [%s]", pkey, pdata)

      str_break(pdata, playerid, temp1, 32, 511)
      str_break(temp1, xp, temp2, 32, 511)
      str_break(temp2, ip, temp1, 32, 511)
      str_break(temp1, tmth, temp2, 32, 511)
      str_break(temp2, tday, temp1, 32, 511)
      str_break(temp1, thr, temp2, 32, 511)
      str_break(temp2, tmin, temp1, 32, 511)

      playerxp[id] = str_to_num(xp)


      //server_print("Loaded %d XP for %s", playerxp[id], playername)

      client_print(id, print_chat, "Your XP has been loaded from the vault")
      displaylevel(id, 0)
   }else{
      client_print(id, print_chat, "No XP found for SteamID %s", playerid)
   }

   return PLUGIN_CONTINUE
}
// **************************************************************************
// END get_xp_id subroutine
// **************************************************************************


// **************************************************************************
// BEGIN sqlget_enh_id subroutine
// Retrieve a player's enh info (attribs/resists) from the sql server
// **************************************************************************
public sqlget_enh_id(id){
   if (!warcraft3)
      return PLUGIN_HANDLED

   if (!get_cvar_num("mp_savexp"))
      return PLUGIN_CONTINUE

   new playerid[32], playername[32], error[128]

   get_user_authid(id, playerid, 31)
   get_user_name(id, playername, 31)

   replaceall(playername, 32, "'", "")

   // Connect to the SQL server and create the tables if they do not exist
   new Sql:sql = dbi_connect(sqlhost, sqluser, sqlpass, sqldb, sqlerror, 127)
   if (sql <= SQL_FAILED) {
     log_amx("UWC3 SQL :: sqlget_enh_id() :: Connect Error: %s", sqlerror)
     return PLUGIN_HANDLED
   }

   new Result:Res

   if ( get_cvar_num("mp_sql_saveby") == SQL_SAVEBY_NAME ){
      Res = dbi_query(sql,"SELECT name, steamid, att1, att2, att3, att4, att5, res1, res2, res3, res4, res5 FROM %s WHERE name = '%s'", sqltable_enh, playername )
   }else{
      Res = dbi_query(sql,"SELECT name, steamid, att1, att2, att3, att4, att5, res1, res2, res3, res4, res5 FROM %s WHERE steamid = '%s'", sqltable_enh, playerid )
   }

   if (Res == RESULT_FAILED) {
      dbi_error(sql,error,127)
      client_print(id, print_chat,
         "[%s] Error Retrieving Your SQL Data: [ %s ]", MOD, error)
      log_amx("UWC3 SQL :: Error Retrieving SQL Data for %s", playername)
      dbi_free_result(Res)
      dbi_close(sql)
      return PLUGIN_CONTINUE
   }else if (Res == RESULT_NONE) {
      client_print(id, print_chat,
       "[%s] No Saved Attribute/Resistance SQL Data Found for Player %s", MOD, playername )
      log_amx("UWC3 SQL :: No Attrib/Resist SQL Data Found for %s", playername)
      dbi_free_result(Res)
      dbi_close(sql)
      return PLUGIN_CONTINUE
   }

   new name[32], pid[32], att[6], res[6]

   if ( dbi_nextrow(Res) > 0 ){
      dbi_result(Res, "name", name, 31)
      dbi_result(Res, "steamid", pid, 31)
      att[1] = dbi_result( Res, "att1" )
      att[2] = dbi_result( Res, "att2" )
      att[3] = dbi_result( Res, "att3" )
      att[4] = dbi_result( Res, "att4" )
      att[5] = dbi_result( Res, "att5" )
      res[1] = dbi_result( Res, "res1" )
      res[2] = dbi_result( Res, "res2" )
      res[3] = dbi_result( Res, "res3" )
      res[4] = dbi_result( Res, "res4" )
      res[5] = dbi_result( Res, "res5" )

      p_attribs[id] = att
      p_resists[id] = res

      log_amx("UWC3 SQL :: Attrib/Resist Table Loaded: name=(%s) steamid=(%s) Attribs=(%d %d %d %d %d) Resists=(%d %d %d %d %d)", name, pid, att[1], att[2], att[3], att[4], att[5], res[1], res[2], res[3], res[4], res[5])
   }

   dbi_close(sql)

   return PLUGIN_CONTINUE
}
// **************************************************************************
// END sqlget_enh_id subroutine
// **************************************************************************


// **************************************************************************
// BEGIN get_enh_id subroutine
// Retrieve a player's enh info (attribs/resists) from the vault
// **************************************************************************
public get_enh_id(id){
   if (!warcraft3)
      return PLUGIN_HANDLED

   if (!get_cvar_num("mp_savexp"))
      return PLUGIN_CONTINUE

   new playerid[32]
   new pkey[128] = ""
   new pdata[512] = ""
   new temp1[512] = ""
   new temp2[512] = ""
   new tnum[32] = ""

   get_user_authid(id, playerid, 31)
   format(pkey, 127, "%s_enh", playerid )

   new attempt = get_vaultdata(pkey, pdata, 511)

   if (attempt){
      server_print("Attempt Get From Vault for OK (%s)- [%s]", pkey, pdata)
      str_break(pdata, tnum, temp1, 32, 511)
      p_attribs[id][ATTRIBIDX_STR] = str_to_num(tnum)
      str_break(temp1, tnum, temp2, 32, 511)
      p_attribs[id][ATTRIBIDX_INT] = str_to_num(tnum)
      str_break(temp2, tnum, temp1, 32, 511)
      p_attribs[id][ATTRIBIDX_DEX] = str_to_num(tnum)
      str_break(temp1, tnum, temp2, 32, 511)
      p_attribs[id][ATTRIBIDX_AGI] = str_to_num(tnum)
      str_break(temp2, tnum, temp1, 32, 511)
      p_attribs[id][ATTRIBIDX_CON] = str_to_num(tnum)
      str_break(temp1, tnum, temp2, 32, 511)
      p_resists[id][RESISTIDX_POISON] = str_to_num(tnum)
      str_break(temp2, tnum, temp1, 32, 511)
      p_resists[id][RESISTIDX_DISEASE] = str_to_num(tnum)
      str_break(temp1, tnum, temp2, 32, 511)
      p_resists[id][RESISTIDX_ELECTRIC] = str_to_num(tnum)
      str_break(temp2, tnum, temp1, 32, 511)
      p_resists[id][RESISTIDX_FIRE] = str_to_num(tnum)
      str_break(temp1, tnum, temp2, 32, 511)
      p_resists[id][RESISTIDX_MAGIC] = str_to_num(tnum)
      server_print("Loaded From Vault for (%s) Attribs=(%d %d %d %d %d) Resists=(%d %d %d %d %d)", playerid, p_attribs[id][ATTRIBIDX_STR], p_attribs[id][ATTRIBIDX_INT], p_attribs[id][ATTRIBIDX_DEX], p_attribs[id][ATTRIBIDX_AGI], p_attribs[id][ATTRIBIDX_CON], p_resists[id][RESISTIDX_POISON], p_resists[id][RESISTIDX_DISEASE], p_resists[id][RESISTIDX_ELECTRIC], p_resists[id][RESISTIDX_FIRE], p_resists[id][RESISTIDX_MAGIC])

      // [09-07-04] Now check to make sure total attrib/resist pts meet server limits - K2
      new acount = get_attribcount( id )
      new rcount = get_resistcount( id ) 

      if (acount > ATTRIB_MAX_PTS){
         resetattrib[id] = true
         client_print(id, print_chat,
            "Accrued Attrib Pts [%d] Exceeds Server Limit [%d], Invoking Reset",
            acount, ATTRIB_MAX_PTS)
         server_print("Accrued Attrib Pts [%d] Exceeds Server Limit [%d], Invoking Reset",
            acount, ATTRIB_MAX_PTS)
      }

      if (rcount > RESIST_MAX_PTS){
         resetresist[id] = true
         client_print(id, print_chat,
            "Accrued Resist Pts [%d] Exceeds Server Limit [%d], Invoking Reset",
            rcount, RESIST_MAX_PTS)
         server_print("Accrued Resist Pts [%d] Exceeds Server Limit [%d], Invoking Reset",
            rcount, RESIST_MAX_PTS)
      }

   }else{
      client_print(id, print_chat, "No ENH data found for SteamID %s", playerid)
   }

   return PLUGIN_CONTINUE

}
// **************************************************************************
// END get_enh_id subroutine
// **************************************************************************


// **************************************************************************
// BEGIN sqlget_skills_id subroutine
// Retrieve a player's skills info from the sql server
// **************************************************************************
public sqlget_skills_id(id){
   if (!warcraft3)
      return PLUGIN_HANDLED

   if (!get_cvar_num("mp_savexp"))
      return PLUGIN_CONTINUE

   new playerid[32], playername[32], error[128]

   get_user_authid(id, playerid, 31)
   get_user_name(id, playername, 31)

   replaceall(playername, 32, "'", "")

   // Connect to the SQL server and create the tables if they do not exist
   new Sql:sql = dbi_connect(sqlhost, sqluser, sqlpass, sqldb, sqlerror, 127)
   if (sql <= SQL_FAILED) {
     log_amx("UWC3 SQL :: sqlget_skills_id() :: Connect Error: %s", sqlerror)
     return PLUGIN_HANDLED
   }

   new Result:Res1
   new Result:Res2
   new Result:Res3
   new Result:Res4

   if ( get_cvar_num("mp_sql_saveby") == SQL_SAVEBY_NAME ){
      Res1 = dbi_query(sql,"SELECT name, steamid, skill1, skill2, skill3, skill4, skill5, skill6, skill7, skill8, skill9, skill10 FROM %s WHERE name = '%s'", sqltable_skills1, playername )
      Res2 = dbi_query(sql,"SELECT name, steamid, skill11, skill12, skill13, skill14, skill15, skill16, skill17, skill18, skill19, skill20 FROM %s WHERE name = '%s'", sqltable_skills2, playername )
      Res3 = dbi_query(sql,"SELECT name, steamid, skill21, skill22, skill23, skill24, skill25, skill26, skill27, skill28, skill29, skill30 FROM %s WHERE name = '%s'", sqltable_skills3, playername )
      Res4 = dbi_query(sql,"SELECT name, steamid, skill31, skill32, skill33, skill34, skill35, skill36, skill37, skill38, skill39, skill40 FROM %s WHERE name = '%s'", sqltable_skills4, playername )
   }else{
      Res1 = dbi_query(sql,"SELECT name, steamid, skill1, skill2, skill3, skill4, skill5, skill6, skill7, skill8, skill9, skill10 FROM %s WHERE steamid = '%s'", sqltable_skills1, playerid )
      Res2 = dbi_query(sql,"SELECT name, steamid, skill11, skill12, skill13, skill14, skill15, skill16, skill17, skill18, skill19, skill20 FROM %s WHERE steamid = '%s'", sqltable_skills2, playerid )
      Res3 = dbi_query(sql,"SELECT name, steamid, skill21, skill22, skill23, skill24, skill25, skill26, skill27, skill28, skill29, skill30 FROM %s WHERE steamid = '%s'", sqltable_skills3, playerid )
      Res4 = dbi_query(sql,"SELECT name, steamid, skill31, skill32, skill33, skill34, skill35, skill36, skill37, skill38, skill39, skill40 FROM %s WHERE steamid = '%s'", sqltable_skills4, playerid )
   }

   if (Res1 == RESULT_FAILED || Res2 == RESULT_FAILED || Res3 == RESULT_FAILED ||
       Res4 == RESULT_FAILED )
   {
      dbi_error(sql,error,127)
      client_print(id, print_chat,
         "[%s] Error Retrieving Your Skills SQL Data: [ %s ]", MOD, error)
      log_amx("UWC3 SQL :: Error Retrieving Skills SQL Data for %s", playername)
      dbi_free_result(Res1)
      dbi_free_result(Res2)
      dbi_free_result(Res3)
      dbi_free_result(Res4)
      dbi_close(sql)
      return PLUGIN_CONTINUE
   }else if (Res1 == RESULT_NONE && Res2 == RESULT_NONE && Res3 == RESULT_NONE &&
             Res4 == RESULT_NONE )
   {
      client_print(id, print_chat,
       "[%s] No Saved Skills SQL Data Found for Player %s", MOD, playername )
      log_amx("UWC3 SQL :: No Skills SQL Data Found for %s", playername)
      dbi_free_result(Res1)
      dbi_free_result(Res2)
      dbi_free_result(Res3)
      dbi_free_result(Res4)
      dbi_close(sql)
      return PLUGIN_CONTINUE
   }

   new name[32], pid[32], skills[41] = 0

   if ( (Res1 != RESULT_NONE) && (dbi_nextrow(Res1) > 0) ){
      dbi_result(Res1, "name", name, 31)
      dbi_result(Res1, "steamid", pid, 31)
      skills[1] = dbi_result( Res1, "skill1" )
      skills[2] = dbi_result( Res1, "skill2" )
      skills[3] = dbi_result( Res1, "skill3" )
      skills[4] = dbi_result( Res1, "skill4" )
      skills[5] = dbi_result( Res1, "skill5" )
      skills[6] = dbi_result( Res1, "skill6" )
      skills[7] = dbi_result( Res1, "skill7" )
      skills[8] = dbi_result( Res1, "skill8" )
      skills[9] = dbi_result( Res1, "skill9" )
      skills[10] = dbi_result( Res1, "skill10" )
   }

   if ( (Res2 != RESULT_NONE) && (dbi_nextrow(Res2) > 0) ){
      dbi_result(Res2, "name", name, 31)
      dbi_result(Res2, "steamid", pid, 31)
      skills[11] = dbi_result( Res2, "skill11" )
      skills[12] = dbi_result( Res2, "skill12" )
      skills[13] = dbi_result( Res2, "skill13" )
      skills[14] = dbi_result( Res2, "skill14" )
      skills[15] = dbi_result( Res2, "skill15" )
      skills[16] = dbi_result( Res2, "skill16" )
      skills[17] = dbi_result( Res2, "skill17" )
      skills[18] = dbi_result( Res2, "skill18" )
      skills[19] = dbi_result( Res2, "skill19" )
      skills[20] = dbi_result( Res2, "skill20" )
   }

   if ( (Res3 != RESULT_NONE) && (dbi_nextrow(Res3) > 0) ){
      dbi_result(Res3, "name", name, 31)
      dbi_result(Res3, "steamid", pid, 31)
      skills[21] = dbi_result( Res3, "skill21" )
      skills[22] = dbi_result( Res3, "skill22" )
      skills[23] = dbi_result( Res3, "skill23" )
      skills[24] = dbi_result( Res3, "skill24" )
      skills[25] = dbi_result( Res3, "skill25" )
      skills[26] = dbi_result( Res3, "skill26" )
      skills[27] = dbi_result( Res3, "skill27" )
      skills[28] = dbi_result( Res3, "skill28" )
      skills[29] = dbi_result( Res3, "skill29" )
      skills[30] = dbi_result( Res3, "skill30" )
   }

   if ( (Res4 != RESULT_NONE) && (dbi_nextrow(Res4) > 0) ){
      dbi_result(Res4, "name", name, 31)
      dbi_result(Res4, "steamid", pid, 31)
      skills[31] = dbi_result( Res4, "skill31" )
      skills[32] = dbi_result( Res4, "skill32" )
      skills[33] = dbi_result( Res4, "skill33" )
      skills[34] = dbi_result( Res4, "skill34" )
      skills[35] = dbi_result( Res4, "skill35" )
      skills[36] = dbi_result( Res4, "skill36" )
      skills[37] = dbi_result( Res4, "skill37" )
      skills[38] = dbi_result( Res4, "skill38" )
      skills[39] = dbi_result( Res4, "skill39" )
      skills[40] = dbi_result( Res4, "skill40" )
   }

   p_skills[id] = skills

   for (new i = 1; i < MAX_SKILLS; i++){
      if ((p_skills[id][i] >= 1) && (skill_ultimates[i][0])){
         // This is an Ultimate ability being retrieved from saved skills
         client_print(id, print_console, "[%s] Retrieved saved ultimate (%s)^n",
            MOD, skill_ultimates[i][0] )
         ultlearned[id]++
      }
   }

   new tstr[512]
   new len = 0

   len += format(tstr[len], 512-len, "UWC3 SQL :: Skills Table Loaded: name=(%s) steamid=(%s) Skills=(%d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d ", name, pid, skills[1], skills[2], skills[3], skills[4], skills[5], skills[6], skills[7], skills[8], skills[9], skills[10], skills[11], skills[12], skills[13], skills[14], skills[15], skills[16], skills[17], skills[18], skills[19], skills[20])
   len += format(tstr[len], 512-len, "%d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d)", skills[21], skills[22], skills[23], skills[24], skills[25], skills[26], skills[27], skills[28], skills[29], skills[30], skills[31], skills[32], skills[33], skills[34], skills[35], skills[36], skills[37], skills[38], skills[39], skills[40] )

   log_amx( "%s", tstr )

   dbi_close(sql)

   return PLUGIN_CONTINUE

}
// **************************************************************************
// END sqlget_skills_id subroutine
// **************************************************************************


// **************************************************************************
// BEGIN get_skills_id subroutine
// Retrieve a player's skills from the vault
// **************************************************************************
public get_skills_id(id, set){
   if (!warcraft3)
      return PLUGIN_HANDLED

   if (!get_cvar_num("mp_savexp"))
      return PLUGIN_CONTINUE

   if (set < 1 || set > 4){
      // set will allow multiple skillsets to be saved and retrieved
      set = 1
   }

   new Nskills[MAX_SKILLS]

   for (new i = 1; i< MAX_SKILLS; i++)
      Nskills[i] = 0

   new playername[32]
   new playerid[32]
   new pkey[128] = ""
   new pdata[512] = ""

   get_user_name(id, playername, 31)
   get_user_authid(id, playerid, 31)

   format(pkey, 127, "%s_%d", playerid, set )

   new attempt = get_vaultdata(pkey, pdata, 511)

   if (attempt){
      //server_print("From Vault for (%s)- [%s]", pkey, pdata)
      //server_print("Ready to Parse pdata=[%s]", pdata)

      log_amx("Loading vault data for key (%s)", pkey)
      new i = 0
      new j = 1
      new k = 0
      new skills_loaded = 0
      new s = strlen(pdata)

      for (i=0; i<s; i++){
         //check for space or quote
         if (i == (s-1)){
            ++skills_loaded

            if (k == 0)
               Nskills[j] = str_to_num( pdata[i] )
            else
               Nskills[j] += power(10, k) * str_to_num( pdata[i] )


            /*if (j <= 8) copy(sname, 31, skillset1[j])
            else if (j <= 16) copy(sname, 31, skillset2[j-8])
            else if (j <= 24) copy(sname, 31, skillset3[j-16])
            else if (j <= 32) copy(sname, 31, skillset4[j-24])
            else if (j <= 40) copy(sname, 31, skillset5[j-32])

            server_print("Parsing skills: i=(%d) j=(%d) skill=(%s) val=<%d>",
               i, j, sname, Nskills[j]) */
         }else if (pdata[i] == 32 || pdata[i] == 34){

            /*if (j <= 8) copy(sname, 31, skillset1[j])
            else if (j <= 16) copy(sname, 31, skillset2[j-8])
            else if (j <= 24) copy(sname, 31, skillset3[j-16])
            else if (j <= 32) copy(sname, 31, skillset4[j-24])
            else if (j <= 40) copy(sname, 31, skillset5[j-32])

            server_print("Parsing skills: i=(%d) j=(%d) skill=(%s) val=<%d>",
               i, j, sname, Nskills[j]) */

            ++j
            k = 0
            ++skills_loaded
         }else{
            // Reading in a non-space or EOL character
            Nskills[j] += power(10, k++) * str_to_num( pdata[i] )

            //server_print("NEW - Parsing skills: i=(%d) j=(%d) val=(%d)", i, j, Nskills[j])
         }
      }
     
      //for (i = 1; i<= skills_loaded; i++)
      for (i = 1; i< MAX_SKILLS; i++){
         new tnum = Nskills[i]
         if (tnum >= 0 && tnum <= 10){
            p_skills[id][i] = tnum
      
            // Check for an Ultimate ability in saved skills
            new skill_idx = i

            /*if (i <= 8) copy(sname, 31, skillset1[i])
            else if (i <= 16) copy(sname, 31, skillset2[i-8])
            else if (i <= 24) copy(sname, 31, skillset3[i-16])
            else if (i <= 32) copy(sname, 31, skillset4[i-24])
            else if (i <= 40) copy(sname, 31, skillset5[i-32])
            
            server_print("Loading %d for skill %s", tnum, sname)*/
            
            if ((tnum >= 1) && (skill_ultimates[skill_idx][0])){ 
               // This is an Ultimate ability being retrieved from saved skills
               client_print(id, print_console, "[%s] Retrieved saved ultimate (%s)",
                  MOD, skill_ultimates[skill_idx][0] )
               ultlearned[id]++
            }
         }else{
            p_skills[id][i] = 0
         }
      }     
               
         
      //server_print("Loaded %d skills [skillset%d] for %s ", skills_loaded, set, playername)         
            
      client_print(id, print_chat, "Your skillset %d has been loaded from the vault", set)
      displaylevel(id, 0) 
   }else{   
      client_print(id, print_chat, "No Skills found for skillset %d , SteamID %s",
         set, playerid)
   }           

   return PLUGIN_CONTINUE
}           
// **************************************************************************
// END get_skills_id subroutine
// **************************************************************************


// **************************************************************************
// BEGIN uwc3_save*** routines
// Frontend for saving a player's XP, Attribs, Resists, Skills, etc
// **************************************************************************
public uwc3_savexp(id){
   if (get_cvar_num("mp_savexp")){
      if ( get_cvar_num("mp_sql") )
         sqlwrite_xp_id( id )
      else
         write_xp_id( id )
      client_print(id,print_chat, "[%s] Your UWC3 XP has been saved.",MOD)
   }else{
      client_print(id,print_chat,"[%s] Long term XP mode is NOT enabled now.", MOD)
   }

   return PLUGIN_HANDLED
}

public uwc3_saveskills(id){
   if (!get_cvar_num("mp_savexp")){
      client_print(id,print_chat,"[%s] Long term XP mode is NOT enabled now.", MOD)
      return PLUGIN_HANDLED
   }

   /*new arg[32]
   read_argv(1,arg,31)

   new set = str_to_num(arg)

   if (set < 1 || set > 4){
      // set will allow multiple skillsets to be saved and retrieved
      set = 1
   }
   write_skills_id( id, set )
   client_print(id, print_chat, "[%s] You have saved UWC3 skillset %d.",MOD, set)
   client_print(id, print_console, "[%s] You have saved UWC3 skillset %d.",MOD, set)
   */

   if ( get_cvar_num("mp_sql") )
      sqlwrite_skills_id( id, -1, 1)
   else
      write_skills_id( id, 1 )

   client_print(id, print_chat, "[%s] You have saved your UWC3 skills",MOD )

   return PLUGIN_HANDLED
}

public uwc3_saveattribs(id){

   if (!get_cvar_num("mp_savexp")){
      client_print(id,print_chat,"[%s] Long term XP mode is NOT enabled now.", MOD)
      return PLUGIN_HANDLED
   }

   if (get_cvar_num("mp_sql"))
      sqlwrite_enh_id( id, 1 )
   else
      write_enh_id( id )

   client_print(id,print_chat, "[%s] Your UWC3 Attributes have been saved.",MOD)

   return PLUGIN_HANDLED
}

public uwc3_saveresists(id){

   if (!get_cvar_num("mp_savexp")){
      client_print(id,print_chat,"[%s] Long term XP mode is NOT enabled now.", MOD)
      return PLUGIN_HANDLED
   }

   if (get_cvar_num("mp_sql"))
      sqlwrite_enh_id( id, 1 )
   else
      write_enh_id( id )

   client_print(id,print_chat, "[%s] Your UWC3 Resistances have been saved.",MOD)

   return PLUGIN_HANDLED
}

public uwc3_saveall(id){

   if (!get_cvar_num("mp_savexp")){
      client_print(id,print_chat,"[%s] Long term XP mode is NOT enabled now.", MOD)
      return PLUGIN_HANDLED
   }

   if (get_cvar_num("mp_sql")){
      sqlwrite_xp_id( id )
      sqlwrite_skills_id( id, -1, 1)
      sqlwrite_enh_id( id, 1 )
   }else{
      write_xp_id( id )
      write_skills_id( id, 1 )
      write_enh_id( id )
   }

   client_print(id,print_chat, "[%s] Saving all your UWC3 Data now.",MOD)

   return PLUGIN_HANDLED
}
// **************************************************************************
// END uwc3_save*** subroutines
// **************************************************************************



// **************************************************************************
// END Vault and SQL Storage Subroutines
// **************************************************************************

