// SuperHero MySQL Include File
// Version 1.2.0

//----------------------------------------------------------------------------------------------
// Abstract Methods that must be implemented by a save superhero include file...
//
// memoryTableWrite()
// loadXP(id, const savekey[32])
// cleanXP(clearAll = false)
//----------------------------------------------------------------------------------------------
/*

//Plugin will auto create the tables if they do not exist

//If shmod's mysql cvars not set plugin will try to setup
//database in amxmodx's database if one exists

//Use these to create the tables manually if necessary

CREATE TABLE `sh_savexp` (
	`SH_KEY` varchar(32) binary NOT NULL default '',
	`PLAYER_NAME` varchar(32) binary NOT NULL default '',
	`LAST_PLAY_DATE` timestamp(14) NOT NULL,
	`XP` int(10) NOT NULL default '0',
	`HUDHELP` tinyint(3) unsigned NOT NULL default '1',
	`SKILL_COUNT` tinyint(3) unsigned NOT NULL default '0',
	PRIMARY KEY  (`SH_KEY`)
) TYPE=MyISAM COMMENT='SUPERHERO XP Saving Table';

CREATE TABLE `sh_saveskills` (
	`SH_KEY` varchar(32) binary NOT NULL default '',
	`SKILL_NUMBER` tinyint(3) unsigned NOT NULL default '0',
	`HERO_NAME` varchar(25) NOT NULL default '',
	PRIMARY KEY  (`SH_KEY`,`SKILL_NUMBER`)
) TYPE=MyISAM COMMENT='SUPERHERO Skill Saving Table';

//Upgrade from prior to 1.17.5
ALTER TABLE `sh_savexp` ADD `HUDHELP` TINYINT( 3 ) UNSIGNED DEFAULT '1' NOT NULL AFTER `XP`;

//Upgraded from prior to 1.20 (XP from unsigned to signed and usage of tinyint over int)
ALTER TABLE `sh_savexp` CHANGE `XP` `XP` INT( 10 ) SIGNED NOT NULL DEFAULT '0';
ALTER TABLE `sh_savexp` CHANGE `HUDHELP` `HUDHELP` TINYINT( 3 ) UNSIGNED NOT NULL DEFAULT '1';
ALTER TABLE `sh_savexp` CHANGE `SKILL_COUNT` `SKILL_COUNT` TINYINT( 3 ) UNSIGNED NOT NULL DEFAULT '0';
ALTER TABLE `sh_saveskills` CHANGE `SKILL_NUMBER` `SKILL_NUMBER` TINYINT( 3 ) UNSIGNED NOT NULL DEFAULT '0';

*/

#if defined _shsave_included || !defined SHCORE
  #endinput
#endif
#define _shsave_included

//Comment this out to use old syntax for MySQL 3.23
#define NEW_MYSQL

#include <sqlx>

// Global to this save class
new Handle:gDbTuple
new Handle:gDbConnect
new gVaultFile[128]
new bool:gPersistentTemp
new bool:gCreateTables = true
new sh_mysql_host, sh_mysql_user, sh_mysql_pass
new sh_mysql_db, sh_mysql_persistent
//----------------------------------------------------------------------------------------------
saving_init()
{
	sh_mysql_host = register_cvar("sh_mysql_host", "")
	sh_mysql_user = register_cvar("sh_mysql_user", "")
	sh_mysql_pass = register_cvar("sh_mysql_pass", "")
	sh_mysql_db = register_cvar("sh_mysql_db", "")
	sh_mysql_persistent = register_cvar("sh_mysql_persistent", "0")

	register_concmd("amx_shvaulttosql", "adminCopyVault", ADMIN_RCON, "- Copies vault XP to MySQL, should only be done once.")

	get_localinfo("amxx_vault", gVaultFile, charsmax(gVaultFile))
}
//----------------------------------------------------------------------------------------------
public adminCopyVault(id, level, cid)
{
	if ( !cmd_access(id, level, cid, 1) ) return

	mySQLConnect()

	if ( gDbConnect == Empty_Handle ) return

	//Turn Persistant on for this function
	gPersistentTemp = true

	// Open up the vault file - read line by line
	if ( !file_exists(gVaultFile) ) return

	console_print(id, "Please wait while the XP data is copied")

	// Read through the file looking for shinfo entries
	new parm[2]
	parm[0] = id
	parm[1] = 0
	adminCopyVHelper(parm)

	//Rest of this is done in the helper function
}
//----------------------------------------------------------------------------------------------
public adminCopyVHelper(parm[])
{
	//Get data from parm
	new id = parm[0]
	new nextLine = parm[1]

	// Read through the file looking for shinfo entries
	new lengthRead
	new data[512]

	while ((nextLine = read_file(gVaultFile, nextLine, data, charsmax(data), lengthRead)) != 0) {
		if ( lengthRead > 0 && containi(data, "shinfo") == 0 ) {
			parseXP(gMemoryTableSize - 1, data)
			if (nextLine % 200 == 0) {
				parm[1] = nextLine
				console_print(id,"Delaying a few seconds before copying the next set of entries")
				set_task(3.0, "adminCopyVHelper", _, parm, 2)
				return
			}
		}
	}

	//If it makes it this far it must be done copying

	// OK now load the XP for any players playing
	new savekey[32]

	for ( new x = 1; x <= SH_MAXSLOTS; x++ ) {
		if ( !is_user_connected(x) ) continue
		getSaveKey(x, savekey)
		loadXP(x, savekey)
	}
	console_print(id, "Saved XP has been copied from the vault to the MySQL Database Successfully")

	//Set Persistent back how it was
	gPersistentTemp = false

	//Closes the connection if set not to be persistent
	close_mysql()
}
//----------------------------------------------------------------------------------------------
parseXP(id, const data[])
{
	// "name" epochtime XP HUDHELP "SKILL1" "SKILL2" ...
	new heroIndex
	static Left[39], Right[1501]
	Left[0] = '^0'
	Right[0] = '^0'

	copy(Right, charsmax(Right), data)

	//Get the key out
	strbrkqt(Right, Left, charsmax(Left), Right, charsmax(Right))
	replace(Left, charsmax(Left), "shinfo.", "")
	copy(gMemoryTableKeys[id], charsmax(gMemoryTableKeys[]), Left)

	//Get the name out
	strbrkqt(Right, Left, charsmax(Left), Right, charsmax(Right))
	copy(gMemoryTableNames[id], charsmax(gMemoryTableNames[]), Left)

	//Get the epochtime out
	strbrkqt(Right, Left, charsmax(Left), Right, charsmax(Right))

	//Get the XP out and save it
	strbrkqt(Right, Left, charsmax(Left), Right, charsmax(Right))
	gMemoryTableXP[id] = str_to_num(Left)

	//Get the HUD Status out
	strbrkqt(Right, Left, charsmax(Left), Right, charsmax(Right))
	gMemoryTableFlags[id] = str_to_num(Left)

	//Now load in all the skills
	new powerCount = 0
	new MaxPowers = min(get_pcvar_num(sh_maxpowers), SH_MAXLEVELS)

	while ( Right[0] != '^0' && powerCount < MaxPowers ) {
		strbrkqt(Right, Left, charsmax(Left), Right, charsmax(Right))
		heroIndex = getHeroID(Left)
		if ( heroIndex >= 0 )  {
			gMemoryTablePowers[id][0] = ++powerCount
			gMemoryTablePowers[id][powerCount] = heroIndex
		}
	}

	// Now save it to the SQL database
	writeData(id)
}
//----------------------------------------------------------------------------------------------
public memoryTableWrite()
{
	if ( !get_pcvar_num(sh_savexp) ) return

	debugMsg(0, 3, "Writing XP Data to SQL Database")

	//Turn Persistant on for this function
	gPersistentTemp = true

	// Write Memory Table to File
	for (new x = 1; x < gMemoryTableCount; x++) {
		if ( gMemoryTableKeys[x][0] != '^0' ) {
			writeData(x)
		}
		// Can even clear the MemoryKey - if a player is disconnected no reason to save again and again...
		gMemoryTableKeys[x][0] = '^0'
	}

	// No need to keep disconnected player around...
	gMemoryTableCount = 33

	//Set Persistent back how it was
	gPersistentTemp = false

	//Closes the connection if set not to be persistent
	close_mysql()
}
//----------------------------------------------------------------------------------------------
//
//AMXX SQL API Code
//
//----------------------------------------------------------------------------------------------
mySQLConnect()
{
	if ( gDbConnect ) {
		if ( !get_pcvar_num(sh_mysql_persistent) && !gPersistentTemp ) close_mysql()
		else return
	}

	// Only create the tuple it was not done yet or a connection could not be made
	static host[64], user[32], pass[32], db[32]
	if ( !gDbTuple ) {
		get_pcvar_string(sh_mysql_host, host, charsmax(host))
		get_pcvar_string(sh_mysql_user, user, charsmax(user))
		get_pcvar_string(sh_mysql_pass, pass, charsmax(pass))
		get_pcvar_string(sh_mysql_db, db, charsmax(db))

		if ( host[0] == '^0' && user[0] == '^0' && db[0] == '^0' ) {
			get_cvar_string("amx_mysql_host", host, charsmax(host))
			get_cvar_string("amx_mysql_user", user, charsmax(user))
			get_cvar_string("amx_mysql_pass", pass, charsmax(pass))
			get_cvar_string("amx_mysql_db", db, charsmax(db))
		}

		//mysql only for now
		SQL_SetAffinity("mysql")

		// Set up the tuple, cache the information
		gDbTuple = SQL_MakeDbTuple(host, user, pass, db)
	}

	// Attempt to connect
	static error[128]
	new errcode
	if ( gDbTuple ) gDbConnect = SQL_Connect(gDbTuple, errcode, error, charsmax(error))

	if ( gDbConnect == Empty_Handle ) {
		debugMsg(0, 0, "MySQL connect error: [%d] '%s' (%s,%s,%s)", errcode, error, host, user, db)

		// Free the tuple on a connection error
		SQL_FreeHandle(gDbTuple)
		gDbTuple = Empty_Handle
		return
	}

	if ( gCreateTables ) {
		// Only try to create the tables once
		static sql[410]
		new Handle:query

		copy(sql, charsmax(sql), "CREATE TABLE IF NOT EXISTS `sh_savexp` ( `SH_KEY` varchar(32) binary NOT NULL default '', `PLAYER_NAME` varchar(32) binary NOT NULL default '', `LAST_PLAY_DATE` timestamp(14) NOT NULL, `XP` int(10) NOT NULL default '0', `HUDHELP` tinyint(3) unsigned NOT NULL default '1', `SKILL_COUNT` tinyint(3) unsigned NOT NULL default '0', PRIMARY KEY  (`SH_KEY`) ) TYPE=MyISAM COMMENT='SUPERHERO XP Saving Table'")

		query = SQL_PrepareQuery(gDbConnect, "%s", sql)
		if ( !SQL_Execute(query) ) {
			errcode = SQL_QueryError(query, error, charsmax(error))
			debugMsg(0, 0, "Error Making Tables: [%d] '%s' - '%s'", errcode, error, sql)
			SQL_FreeHandle(query)
			return
		}
		SQL_FreeHandle(query)

		sql[0] = '^0'
		copy(sql, charsmax(sql), "CREATE TABLE IF NOT EXISTS `sh_saveskills` ( `SH_KEY` varchar(32) binary NOT NULL default '', `SKILL_NUMBER` tinyint(3) unsigned NOT NULL default '0', `HERO_NAME` varchar(25) NOT NULL default '', PRIMARY KEY  (`SH_KEY`,`SKILL_NUMBER`) ) TYPE=MyISAM COMMENT='SUPERHERO Skill Saving Table'")
		query = SQL_PrepareQuery(gDbConnect, "%s", sql)
		if ( !SQL_Execute(query) ) {
			errcode = SQL_QueryError(query, error, charsmax(error))
			debugMsg(0, 0, "Error Making Tables: [%d] '%s' - '%s'", errcode, error, sql)
			SQL_FreeHandle(query)
			return
		}
		SQL_FreeHandle(query)

		gCreateTables = false
	}
}
//----------------------------------------------------------------------------------------------
// Flushes data in memory table position x to database...
writeData(x)
{
	mySQLConnect()

	if ( gDbConnect == Empty_Handle ) return

	debugMsg(x, 8, "Trying to save XP data to MySQL database")

	static error[128], sql[540]
	new Handle:query
	new errcode

	static savekey[63]
	copy(savekey, charsmax(savekey), gMemoryTableKeys[x])
	replace_all(savekey, charsmax(savekey), "'", "\'")

	static bkqtname[63]
	copy(bkqtname, charsmax(bkqtname), gMemoryTableNames[x])
	replace_all(bkqtname, charsmax(bkqtname), "'", "\'")

	// Thanks to HC for help with writing more efficient queries
	// Check if this user has an entry already, if not make one
	formatex(sql, charsmax(sql), "UPDATE `sh_savexp` SET `PLAYER_NAME`='%s', `LAST_PLAY_DATE`=SYSDATE(), `XP`='%d', `HUDHELP`='%d', `SKILL_COUNT`='%d' WHERE `SH_KEY`='%s'", bkqtname, gMemoryTableXP[x], gMemoryTableFlags[x], gMemoryTablePowers[x][0], savekey)
	query = SQL_PrepareQuery(gDbConnect, "%s", sql)

	if ( !SQL_Execute(query) ) {
		errcode = SQL_QueryError(query, error, charsmax(error))
		debugMsg(0, 0, "Error Querying MySQL DB for %s: [%d] '%s' - '%s'", savekey, errcode, error, sql)
		SQL_FreeHandle(query)
		return
	}

	if ( !SQL_AffectedRows(query) ) {
		SQL_FreeHandle(query)
		// There is no entry for this user lets create one
		sql[0] = '^0'
		formatex(sql, charsmax(sql), "INSERT INTO `sh_savexp` (`SH_KEY`, `PLAYER_NAME`, `LAST_PLAY_DATE`, `XP`, `HUDHELP`, `SKILL_COUNT`) VALUES ('%s', '%s', SYSDATE(), '%d', '%d', '%d')", savekey, bkqtname, gMemoryTableXP[x], gMemoryTableFlags[x], gMemoryTablePowers[x][0])
		query = SQL_PrepareQuery(gDbConnect, "%s", sql)
		if ( !SQL_Execute(query) ) {
			errcode = SQL_QueryError(query, error, charsmax(error))
			debugMsg(0, 0, "Error Writing MySQL XP for %s: [%d] '%s' - '%s'", savekey, errcode, error, sql)
			SQL_FreeHandle(query)
			return
		}
	}
	SQL_FreeHandle(query)

	if ( !is_user_connected(x) || gChangedHeroes[x] ) {

		// Remove all saved powers for this user
		sql[0] = '^0'
		formatex(sql, charsmax(sql), "DELETE FROM `sh_saveskills` WHERE `SH_KEY`='%s'", savekey)
		query = SQL_PrepareQuery(gDbConnect, "%s", sql)
		if ( !SQL_Execute(query) ) {
			errcode = SQL_QueryError(query, error, charsmax(error))
			debugMsg(0, 0, "Error Deleting MySQL Skills for %s: [%d] '%s' - '%s'", savekey, errcode, error, sql)
			SQL_FreeHandle(query)
			return
		}
		SQL_FreeHandle(query)

		// Saving by SuperHeroName since the hero order in the plugin.ini can change...
		new numHeroes, count, n
		numHeroes = gMemoryTablePowers[x][0]

		for ( new p = 1; p <= numHeroes; p++ ) {
			//heroIndex = gMemoryTablePowers[x][p] //Value only used once per loop no need to set variable, but leave here to see what it is
			if ( !count ) {
				sql[0] = '^0'
				n = copy(sql, charsmax(sql), "INSERT INTO `sh_saveskills` VALUES ")
			}

			// (savekey, user's hero number, hero name)
			n += formatex(sql[n], charsmax(sql)-n, "('%s','%d','%s')", savekey, p, gSuperHeros[gMemoryTablePowers[x][p]][hero])
			++count

			// sql[] should not exceed 543 with 5 inserts
			// Send the query and reset the count if count is 5 or it's the last hero of the loop
			if ( count == 5 || p == numHeroes ) {
				count = 0
				query = SQL_PrepareQuery(gDbConnect, "%s", sql)
				if ( !SQL_Execute(query) ) {
					errcode = SQL_QueryError(query, error, charsmax(error))
					debugMsg(0, 0, "Error Writing MySQL Skills for %s: [%d] '%s' - '%s'", savekey, errcode, error, sql)
					SQL_FreeHandle(query)
					return
				}
				SQL_FreeHandle(query)
			}
			else {
				n += add(sql[n], charsmax(sql)-n, ", ")
			}
		}

		// x can be higher than max slots, however sizeof gChangedHeroes can not be
		if ( 0 < x <= SH_MAXSLOTS ) {
			gChangedHeroes[x] = false
		}
	}

	//Closes the connection if set not to be persistent
	close_mysql()
}
//----------------------------------------------------------------------------------------------
//immediate use, no threading
loadXP(id, const savekey[32])
{
	mySQLConnect()

	if ( gDbConnect == Empty_Handle ) return false

	debugMsg(id, 8, "Trying to load XP data from MySQL database")

	static sql[180], error[128], shkey[63]
	new Handle:query
	new errcode

	copy(shkey, charsmax(shkey), savekey)
	replace_all(shkey, charsmax(shkey), "'", "\'")

	sql[0] = '^0'
	formatex(sql, charsmax(sql), "SELECT `XP`, `HUDHELP`, `SKILL_COUNT` FROM `sh_savexp` WHERE `SH_KEY` = '%s'", shkey)
	query = SQL_PrepareQuery(gDbConnect, "%s", sql)

	if ( !SQL_Execute(query) ) {
		errcode = SQL_QueryError(query, error, charsmax(error))
		debugMsg(0, 0, "Error Loading MySQL XP for %s: [%d] '%s' - '%s'", shkey, errcode, error, sql)
		SQL_FreeHandle(query)
		return false
	}

	if ( !SQL_NumResults(query) ) {
		debugMsg(id, 1, "No Saved XP to Load for ^"%s^"", shkey)
		SQL_FreeHandle(query)

		//Closes the connection if set not to be persistent
		close_mysql()

		return true
	}

	static skillCount[4]
	new playerLevel

	gPlayerXP[id] = SQL_ReadResult(query, 0)
	gPlayerLevel[id] = playerLevel = getPlayerLevel(id)
	setLevel(id, playerLevel)

	gPlayerFlags[id] = SQL_ReadResult(query, 1)

	SQL_ReadResult(query, 2, skillCount, charsmax(skillCount))

	SQL_FreeHandle(query)

	sql[0] = '^0'
	formatex(sql, charsmax(sql), "SELECT `HERO_NAME` FROM `sh_saveskills` WHERE `SH_KEY` = '%s' AND `SKILL_NUMBER` <= '%s' ORDER BY `SKILL_NUMBER` ASC", shkey, skillCount)
	query = SQL_PrepareQuery(gDbConnect, "%s", sql)

	if ( !SQL_Execute(query) ) {
		errcode = SQL_QueryError(query, error, charsmax(error))
		debugMsg(0, 0, "Error Loading MySQL XP for %s: [%d] '%s' - '%s'", shkey, errcode, error, sql)
		SQL_FreeHandle(query)
		return false
	}

	if ( SQL_NumResults(query) ) {
		static heroName[25]
		new heroIndex, skills
		gPlayerPowers[id][0] = 0

		while ( SQL_MoreResults(query) ) {
			heroName[0] = '^0'
			SQL_ReadResult(query, 0, heroName, charsmax(heroName))
			heroIndex = getHeroID(heroName)
			if ( -1 < heroIndex < gSuperHeroCount && getHeroLevel(heroIndex) <= playerLevel ) {
				gPlayerPowers[id][0] = ++skills
				gPlayerPowers[id][skills] = heroIndex
				initHero(id, heroIndex, SH_HERO_ADD)
			}

			SQL_NextRow(query)
		}
	}

	SQL_FreeHandle(query)

	memoryTableUpdate(id)

	//Closes the connection if set not to be persistent
	close_mysql()

	return true
}
//----------------------------------------------------------------------------------------------
cleanXP(bool:clearAll)
{
	new xpSaveDays = get_pcvar_num(sh_xpsavedays)

	if ( !clearAll && (!get_pcvar_num(sh_savexp) || xpSaveDays < 0) ) return

	mySQLConnect()

	if ( gDbConnect == Empty_Handle ) return

	static error[128], sql[216]
	new Handle:query
	new errcode

	if ( clearAll ) {
		sql[0] = '^0'
		formatex(sql, charsmax(sql), "TRUNCATE TABLE `sh_saveskills`")
		query = SQL_PrepareQuery(gDbConnect, "%s", sql)
		if ( !SQL_Execute(query) ) {
			errcode = SQL_QueryError(query, error, charsmax(error))
			debugMsg(0, 0, "Couldn't Erase XP: [%d] '%s' - '%s'", errcode, error, sql)
			SQL_FreeHandle(query)
			return
		}
		SQL_FreeHandle(query)

		sql[0] = '^0'
		formatex(sql, charsmax(sql), "TRUNCATE TABLE `sh_savexp`")
		query = SQL_PrepareQuery(gDbConnect, "%s", sql)
		if ( !SQL_Execute(query) ) {
			errcode = SQL_QueryError(query, error, charsmax(error))
			debugMsg(0, 0, "Couldn't Erase XP: [%d] '%s' - '%s'", errcode, error, sql)
			SQL_FreeHandle(query)
			return
		}
		SQL_FreeHandle(query)
	}
	else {

#if defined NEW_MYSQL

		sql[0] = '^0'
		formatex(sql, charsmax(sql), "DELETE FROM `sh_saveskills` USING `sh_saveskills`, `sh_savexp` WHERE sh_savexp.`SH_KEY` = sh_saveskills.`SH_KEY` AND sh_savexp.`LAST_PLAY_DATE` < (SYSDATE() - INTERVAL '%d' DAY) AND NOT (sh_savexp.`HUDHELP` & '%d')", xpSaveDays, SH_FLAG_XPIMMUNE)
		query = SQL_PrepareQuery(gDbConnect, "%s", sql)
		if ( !SQL_Execute(query) ) {
			errcode = SQL_QueryError(query, error, charsmax(error))
			debugMsg(0, 0, "Couldn't Clean Powers: [%d] '%s' - '%s'", errcode, error, sql)
			SQL_FreeHandle(query)
			return
		}
		SQL_FreeHandle(query)

		sql[0] = '^0'
		formatex(sql, charsmax(sql), "DELETE FROM `sh_savexp` WHERE `LAST_PLAY_DATE` < (SYSDATE() - INTERVAL '%d' DAY) AND NOT (`HUDHELP` & '%d')", xpSaveDays, SH_FLAG_XPIMMUNE)
		query = SQL_PrepareQuery(gDbConnect, "%s", sql)
		if ( !SQL_Execute(query) ) {
			errcode = SQL_QueryError(query, error, charsmax(error))
			debugMsg(0, 0, "Couldn't Clean XP: [%d] '%s' - '%s'", errcode, error, sql)
			SQL_FreeHandle(query)
			return
		}

#else

		sql[0] = '^0'
		formatex(sql, charsmax(sql), "SELECT `SH_KEY` FROM `sh_savexp` WHERE `LAST_PLAY_DATE` < (SYSDATE() - INTERVAL '%d' DAY) AND NOT (`HUDHELP` & '%d')", xpSaveDays, SH_FLAG_XPIMMUNE)
		query = SQL_PrepareQuery(gDbConnect, "%s", sql)
		if ( !SQL_Execute(query) ) {
			errcode = SQL_QueryError(query, error, charsmax(error))
			debugMsg(0, 0, "Couldn't SELECT to Clean XP: [%d] '%s' - '%s'", errcode, error, sql)
			SQL_FreeHandle(query)
			return
		}

		if ( SQL_NumResults(query) ) {
			static savekey[63]
			new Handle:query2
			while ( SQL_MoreResults(query) ) {
				savekey[0] = '^0'
				SQL_ReadResult(query, 0, savekey, charsmax(savekey))

				if ( savekey[0] == '^0' ) {
					SQL_NextRow(query)
					continue
				}

				replace_all(savekey, charsmax(savekey), "'", "\'")

				sql[0] = '^0'
				formatex(sql, charsmax(sql), "DELETE FROM `sh_savexp` WHERE `SH_KEY`='%s'", savekey)
				query2 = SQL_PrepareQuery(gDbConnect, "%s", sql)
				if ( !SQL_Execute(query2) ) {
					errcode = SQL_QueryError(query2, error, charsmax(error))
					debugMsg(0, 0, "Couldn't Clean XP: [%d] '%s' - '%s'", errcode, error, sql)
					SQL_FreeHandle(query2)
					return
				}
				SQL_FreeHandle(query2)

				sql[0] = '^0'
				formatex(sql, charsmax(sql), "DELETE FROM `sh_saveskills` WHERE `SH_KEY`='%s'", savekey)
				query2 = SQL_PrepareQuery(gDbConnect, "%s", sql)
				if ( !SQL_Execute(query2) ) {
					errcode = SQL_QueryError(query2, error, charsmax(error))
					debugMsg(0, 0, "Couldn't Clean Powers: [%d] '%s' - '%s'", errcode, error, sql)
					SQL_FreeHandle(query2)
					return
				}
				SQL_FreeHandle(query2)

				SQL_NextRow(query)
			}
		}

#endif

		SQL_FreeHandle(query)
	}

	//Closes the connection if set not to be persistent
	close_mysql()
}
//----------------------------------------------------------------------------------------------
close_mysql()
{
	if ( gDbConnect == Empty_Handle || get_pcvar_num(sh_mysql_persistent) || gPersistentTemp ) return

	SQL_FreeHandle(gDbConnect)
	gDbConnect = Empty_Handle
}
//----------------------------------------------------------------------------------------------
saving_end()
{
	if ( gDbConnect ) {
		SQL_FreeHandle(gDbConnect)
		gDbConnect = Empty_Handle
		
	}

	if ( gDbTuple ) {
		SQL_FreeHandle(gDbTuple)
		gDbTuple = Empty_Handle
	}
}
//----------------------------------------------------------------------------------------------