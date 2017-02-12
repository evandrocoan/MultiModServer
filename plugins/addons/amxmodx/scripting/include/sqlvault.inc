#if defined _sqlv_included
	#endinput
#endif
#define _sqlv_included

#include <amxmodx>
#include <sqlx>

#if AMXX_VERSION_NUM >= 175
	#pragma reqlib sqlite
	#if !defined AMXMODX_NOAUTOLOAD
		#pragma loadlib sqlite
	#endif
#else
	#pragma library sqlite
#endif

// debug idea found from xs.inc
//#define SQLVAULT_DEBUG_LIB

#if defined SQLVAULT_DEBUG_LIB
	#define SQLVAULT_FUNC_ATTRIB
	#define SQLVAULT_VAR_ATTRIB new
#else
	#define SQLVAULT_FUNC_ATTRIB stock
	#define SQLVAULT_VAR_ATTRIB stock
#endif

SQLVAULT_VAR_ATTRIB const SQLVAULT_VERSION[] = "0.0.2";

SQLVAULT_VAR_ATTRIB __SQLVAULT_ERRCODE;
SQLVAULT_VAR_ATTRIB __SQLVAULT_ERROR[128];
SQLVAULT_VAR_ATTRIB __SQLVAULT_TEMPSTRING[1024];

enum SQLVault
{
	Invalid_SQLVault = 0
};

/*
 * Structure used for sqlv_read_all()
 * 
 * @elem		SQLV_Key - String that holds the key
 * @elem		SQLV_Data - String that holds the data
 * @elem		SQLV_TimeStamp - Integer that holds the timestamp
 * 
 */
enum _:SQLVaultEntry
{
	SQLV_Key[64],
	SQLV_Data[512],
	SQLV_TimeStamp
};

/*
 * Opens a vault database
 * 
 * @param		szHost - The host used to connect to the database
 * @param		szUser - The user used to connect to the database
 * @param		szPass - The password used to connect to the database
 * @param		szDb - The name of the database to connect to
 * @param		szVaultName - The vault name to open
 * @param		bAutoInit - If true, sqlv_init() is called inside the function. If false, sqlv_init() is not called.
 * 
 * @return		Returns a valid vault handle on success, Invalid_SQLVault on failure.
 * 
 */
SQLVAULT_FUNC_ATTRIB SQLVault:sqlv_open(szHost[], szUser[], szPass[], szDb[], szVaultName[], bool:bAutoInit = true)
{
	new Handle:hTuple = SQL_MakeDbTuple(szHost, szUser, szPass, szDb);
	
	if(hTuple == Empty_Handle)
	{
		log_amx("Could not create SQL tuple");
		
		return Invalid_SQLVault;
	}
	
	QuoteString(szVaultName, '`');
	
	new Trie:tVaultData = TrieCreate();
	
	TrieSetCell(tVaultData, "tuple", hTuple);
	TrieSetString(tVaultData, "vaultname", szVaultName);
	
	UnQuoteString(szVaultName, '`');
	
	if(bAutoInit && !sqlv_init(SQLVault:tVaultData))
	{
		SQL_FreeHandle(hTuple);
		
		TrieDestroy(tVaultData);
		
		return Invalid_SQLVault;
	}
	
	return SQLVault:tVaultData;
}

/*
 * Opens a vault database based on the amx_sql_* cvars in addons/amxmodx/configs/sql.cfg
 * 
 * @param		szVaultName - The vault name to open
 * @param		bAutoInit - If true, sqlv_init() is called inside the function. If false, sqlv_init() is not called.
 * 
 * @return		Returns a valid vault handle on success, Invalid_SQLVault on failure.
 * 
 */
SQLVAULT_FUNC_ATTRIB SQLVault:sqlv_open_default(szVaultName[], bool:bAutoInit = true)
{
	// code taken from SQL_MakeStdTuple()
	
	new szConfigsDir[64];
	get_localinfo("amxx_configsdir", szConfigsDir, charsmax(szConfigsDir));
	
	server_cmd("exec %s/sql.cfg", szConfigsDir);
	server_exec();
	
	new szHost[64], szUser[64], szPass[64], szDb[64], szSetType[12];
	get_cvar_string("amx_sql_host",	szHost,		charsmax(szHost));
	get_cvar_string("amx_sql_user",	szUser,		charsmax(szUser));
	get_cvar_string("amx_sql_pass",	szPass,		charsmax(szPass));
	get_cvar_string("amx_sql_db",	szDb,		charsmax(szDb));
	get_cvar_string("amx_sql_type",	szSetType,	charsmax(szSetType));
	
	if(!sqlv_affinity(szSetType))
	{
		return Invalid_SQLVault;
	}
	
	return sqlv_open(szHost, szUser, szPass, szDb, szVaultName, bAutoInit);
}

/*
 * Opens a local vault database using the sqlite module
 * 
 * @param		szVaultName - The vault name to open
 * @param		bAutoInit - If true, sqlv_init() is called inside the function. If false, sqlv_init() is not called.
 * 
 * @return		Returns a valid vault handle on success, Invalid_SQLVault on failure.
 * 
 */
SQLVAULT_FUNC_ATTRIB SQLVault:sqlv_open_local(szVaultName[], bool:bAutoInit = true)
{
	static SQLITE_HOST[] =	"127.0.0.1";
	static SQLITE_USER[] =	"root";
	static SQLITE_PASS[] =	"";
	static SQLITE_DB[] =	"amx";
	
	// added requirement for "sqlite" library at top of .inc
	/*if(!is_module_loaded("sqlite"))
	{
		log_amx("SQLite module needs to be enabled in modules.ini to open local database!");
		
		return Invalid_SQLVault;
	}*/
	
	if(!sqlv_affinity("sqlite"))
	{
		return Invalid_SQLVault;
	}
	
	return sqlv_open(SQLITE_HOST, SQLITE_USER, SQLITE_PASS, SQLITE_DB, szVaultName, bAutoInit);
}

/*
 * Sets the SQL driver
 * 
 * @param		szSetType - The driver to set
 * 
 * @return		Returns 1 on success, 0 on failure.
 * 
 */
SQLVAULT_FUNC_ATTRIB sqlv_affinity(szSetType[])
{
	new szGetType[12];
	SQL_GetAffinity(szGetType, charsmax(szGetType));
	
	if(!equali(szGetType, szSetType) && !SQL_SetAffinity(szSetType))
	{
		log_amx("Failed to set affinity from %s to %s.", szGetType, szSetType);
		
		return 0;
	}
	
	return 1;
}

/*
 * Closes the vault
 * 
 * @param		hVault - The vault to close
 * 
 * @return		No return
 * 
 * @note		The vault handle is set to Invalid_SQLVault after it is closed.
 * 
 */
SQLVAULT_FUNC_ATTRIB sqlv_close(&SQLVault:hVault)
{
	if(hVault == Invalid_SQLVault)
	{
		return;
	}
	
	new Handle:hTuple;
	TrieGetCell(Trie:hVault, "tuple", hTuple);
	
	SQL_FreeHandle(hTuple);
	
	if(TrieGetCell(Trie:hVault, "connection", hTuple))
	{
		SQL_FreeHandle(hTuple);
	}
	
	TrieDestroy(Trie:hVault);
	
	hVault = Invalid_SQLVault;
}

/*
 * Connects to the vault database
 * 
 * @param		hVault - The vault to connect to
 * 
 * @return		Returns 1 on success, 0 on failure.
 * 
 * @note		This does not open the vault!
 * 			It only creates a cached connection.
 * 
 * @note		This should be used when multiple vault functions are used in a row
 * 			Doing this will reduce CPU usage in connecting/disconnecting each time those functions are used.
 * 
 * @note		After those functions are used, this connection should be closed.
 * 
 * @note		It is not recommended to keep the connection open the whole time the plugin is running.
 * 
 */
SQLVAULT_FUNC_ATTRIB sqlv_connect(SQLVault:hVault)
{
	if(hVault == Invalid_SQLVault)
	{
		return 0;
	}
	
	new Handle:hTuple;
	TrieGetCell(Trie:hVault, "tuple", hTuple);
	
	if(hTuple == Empty_Handle)
	{
		return 0;
	}
	
	if(TrieKeyExists(Trie:hVault, "connection"))
	{
		return 1;
	}
	
	new Handle:hConnection = SQL_Connect(hTuple, __SQLVAULT_ERRCODE, __SQLVAULT_ERROR, 127);
	
	if(hConnection == Empty_Handle)
	{
		log_amx("Connection failed in sqlv_connect() (%d): %s", __SQLVAULT_ERRCODE, __SQLVAULT_ERROR);
		
		return 0;
	}
	
	TrieSetCell(Trie:hVault, "connection", hConnection);
	
	return 1;
}

/*
 * Disconnects from the vault database
 * 
 * @param		hVault - The vault to disconnect
 * 
 * @return		Returns 1 if disconnected, 0 on error or no connection existed.
 * 
 * @note		This does not close the vault!
 * 			It only closes the cached connection made.
 * 
 */
SQLVAULT_FUNC_ATTRIB sqlv_disconnect(SQLVault:hVault)
{
	if(hVault == Invalid_SQLVault)
	{
		return 0;
	}
	
	new Handle:hTuple;
	TrieGetCell(Trie:hVault, "tuple", hTuple);
	
	if(hTuple == Empty_Handle)
	{
		return 0;
	}
	
	new Handle:hConnection;
	
	if(!TrieGetCell(Trie:hVault, "connection", hConnection))
	{
		return 0;
	}
	
	SQL_FreeHandle(hConnection);
	
	TrieDeleteKey(Trie:hVault, "connection");
	
	return 1;
}

/*
 * Initializes the vault for use
 * 
 * @param		hVault - The vault to initialize
 * 
 * @return		Returns 1 on success, 0 on failure
 * 
 * @note		This must be used before any other vault functions are used (except open and close)!
 * 
 */
SQLVAULT_FUNC_ATTRIB sqlv_init(SQLVault:hVault)
{
	if(hVault == Invalid_SQLVault)
	{
		return 0;
	}
	
	new Handle:hTuple;
	TrieGetCell(Trie:hVault, "tuple", hTuple);
	
	if(hTuple == Empty_Handle)
	{
		return 0;
	}
	
	new Handle:hConnection, bool:bNewConnection = false;
	
	if(!TrieGetCell(Trie:hVault, "connection", hConnection))
	{
		hConnection = SQL_Connect(hTuple, __SQLVAULT_ERRCODE, __SQLVAULT_ERROR, 127);
		
		if(hConnection == Empty_Handle)
		{
			log_amx("Connection failed in sqlv_init() (%d): %s", __SQLVAULT_ERRCODE, __SQLVAULT_ERROR);
			
			return 0;
		}
		
		bNewConnection = true;
	}
	
	new szVaultName[32];
	TrieGetString(Trie:hVault, "vaultname", szVaultName, charsmax(szVaultName));
	
	new Handle:hQuery = SQL_PrepareQuery(hConnection,\
		"CREATE TABLE IF NOT EXISTS `%s` \
		(`key` VARCHAR(64) NOT NULL PRIMARY KEY, \
		`data` VARCHAR(512) NOT NULL, \
		`timestamp` INT(11) NOT NULL, \
		`permanent` INT(11) NOT NULL);",
		szVaultName);
	
	new iReturn = 1;
	
	if(!SQL_Execute(hQuery))
	{
		SQL_QueryError(hQuery, __SQLVAULT_ERROR, charsmax(__SQLVAULT_ERROR));
		log_amx("Error in sqlv_init(): %s", __SQLVAULT_ERROR);
		
		iReturn = 0;
	}
	
	SQL_FreeHandle(hQuery);
	
	if(bNewConnection)
	{
		SQL_FreeHandle(hConnection);
	}
	
	return iReturn;
}

/*
 * Gets a string value from a vault
 * 
 * @param		hVault - The vault to get the data from
 * @param		szKey - The key holding the data
 * @param		szData - The buffer to hold the data
 * @param		iDataLen - The max length of the data buffer
 * @param		iTimeStamp - The byref variable holding the timestamp
 * 
 * @return		Returns 1 on success, 0 on failure
 * 
 */
SQLVAULT_FUNC_ATTRIB sqlv_get_data(SQLVault:hVault, szKey[], szData[], iDataLen, &iTimeStamp = 0)
{
	szData[0] = 0;
	
	iTimeStamp = 0;
	
	if(hVault == Invalid_SQLVault)
	{
		return 0;
	}
	
	new Handle:hTuple;
	TrieGetCell(Trie:hVault, "tuple", hTuple);
	
	if(hTuple == Empty_Handle)
	{
		return 0;
	}
	
	new Handle:hConnection, bool:bNewConnection = false;
	
	if(!TrieGetCell(Trie:hVault, "connection", hConnection))
	{
		hConnection = SQL_Connect(hTuple, __SQLVAULT_ERRCODE, __SQLVAULT_ERROR, 127);
		
		if(hConnection == Empty_Handle)
		{
			log_amx("Connection failed in sqlv_get_data() (%d): %s", __SQLVAULT_ERRCODE, __SQLVAULT_ERROR);
			
			return 0;
		}
		
		bNewConnection = true;
	}
	
	new szVaultName[32];
	TrieGetString(Trie:hVault, "vaultname", szVaultName, charsmax(szVaultName));
	
	QuoteString(szKey);
	
	new Handle:hQuery = SQL_PrepareQuery(hConnection,\
		"SELECT `data`, `timestamp` \
		FROM `%s` \
		WHERE `key` = '%s';",
		szVaultName, szKey);
	
	UnQuoteString(szKey);
	
	new iReturn = 0;
	
	if(!SQL_Execute(hQuery))
	{
		SQL_QueryError(hQuery, __SQLVAULT_ERROR, charsmax(__SQLVAULT_ERROR));
		log_amx("Error in sqlv_get_data(): %s", __SQLVAULT_ERROR);
	}
	else if((iReturn = SQL_NumResults(hQuery)))
	{
		SQL_ReadResult(hQuery, 0, szData, iDataLen);
		
		iTimeStamp = SQL_ReadResult(hQuery, 1);
	}
	
	SQL_FreeHandle(hQuery);
	
	if(bNewConnection)
	{
		SQL_FreeHandle(hConnection);
	}
	
	return iReturn;
}

/*
 * Gets an integer value from a vault
 * 
 * @param		hVault - The vault to get the data from
 * @param		szKey - The key holding the data
 * @param		iTimeStamp - The byref variable holding the timestamp
 * 
 * @return		Returns the integer value on success, 0 on failure
 * 
 */
SQLVAULT_FUNC_ATTRIB sqlv_get_num(SQLVault:hVault, szKey[], &iTimeStamp = 0)
{
	if(sqlv_get_data(hVault, szKey, __SQLVAULT_TEMPSTRING, charsmax(__SQLVAULT_TEMPSTRING), iTimeStamp))
	{
		return str_to_num(__SQLVAULT_TEMPSTRING);
	}
	
	return 0;
}

/*
 * Gets a float value from a vault
 * 
 * @param		hVault - The vault to get the data from
 * @param		szKey - The key holding the data
 * @param		iTimeStamp - The byref variable holding the timestamp
 * 
 * @return		Returns the float value on success, 0.0 on failure
 * 
 */
SQLVAULT_FUNC_ATTRIB Float:sqlv_get_float(SQLVault:hVault, szKey[], &iTimeStamp = 0)
{
	if(sqlv_get_data(hVault, szKey, __SQLVAULT_TEMPSTRING, charsmax(__SQLVAULT_TEMPSTRING), iTimeStamp))
	{
		return str_to_float(__SQLVAULT_TEMPSTRING);
	}
	
	return 0.0;
}

/*
 * Checks if a key exists in a vault
 * 
 * @param		hVault - The vault to look in
 * @param		szKey - The key to look for
 * 
 * @return		Returns 1 if exists, 0 if it doesn't.
 * 
 */
SQLVAULT_FUNC_ATTRIB sqlv_key_exists(SQLVault:hVault, szKey[])
{
	return sqlv_get_data(hVault, szKey, __SQLVAULT_TEMPSTRING, charsmax(__SQLVAULT_TEMPSTRING));
}

/*
 * Sets a vault entry to a string value
 * 
 * @param		hVault - The vault to set the data in
 * @param		szKey - The key to hold the data
 * @param		szData - The string value to set
 * 
 * @return		Returns 1 on success, 0 on failure.
 * 
 * @note		Use "*" for the key to set all entries to that data.
 * 			This will update all the timestamps and also set all to non-permanent (even permanent entries)!
 * 
 */
SQLVAULT_FUNC_ATTRIB sqlv_set_data(SQLVault:hVault, szKey[], szData[])
{
	if(hVault == Invalid_SQLVault)
	{
		return 0;
	}
	
	new Handle:hTuple;
	TrieGetCell(Trie:hVault, "tuple", hTuple);
	
	if(hTuple == Empty_Handle)
	{
		return 0;
	}
	
	new Handle:hConnection, bool:bNewConnection = false;
	
	if(!TrieGetCell(Trie:hVault, "connection", hConnection))
	{
		hConnection = SQL_Connect(hTuple, __SQLVAULT_ERRCODE, __SQLVAULT_ERROR, 127);
		
		if(hConnection == Empty_Handle)
		{
			log_amx("Connection failed in sqlv_set_data() (%d): %s", __SQLVAULT_ERRCODE, __SQLVAULT_ERROR);
			
			return 0;
		}
		
		bNewConnection = true;
	}
	
	new szVaultName[32];
	TrieGetString(Trie:hVault, "vaultname", szVaultName, charsmax(szVaultName));
	
	QuoteString(szData);
	
	new Handle:hQuery;
	
	if(equal(szKey, "*"))
	{
		hQuery = SQL_PrepareQuery(hConnection,\
			"UPDATE `%s` \
			SET `data` = '%s' \
			AND `timestamp` = %d \
			AND `permanent` = 0;",\
			szVaultName, szData, get_systime());
	}
	else
	{
		QuoteString(szKey);
		
		hQuery = SQL_PrepareQuery(hConnection,\
			"REPLACE INTO `%s` \
			(`key`, `data`, `timestamp`, `permanent`) \
			VALUES \
			('%s', '%s', %d, 0);",\
			szVaultName, szKey, szData, get_systime());
		
		UnQuoteString(szKey);
	}
	
	UnQuoteString(szData);
	
	new iReturn = 0;
	
	if(!SQL_Execute(hQuery))
	{
		SQL_QueryError(hQuery, __SQLVAULT_ERROR, charsmax(__SQLVAULT_ERROR));
		log_amx("Error in sqlv_set_data(): %s", __SQLVAULT_ERROR);
	}
	else
	{
		iReturn = 1;
	}
	
	SQL_FreeHandle(hQuery);
	
	if(bNewConnection)
	{
		SQL_FreeHandle(hConnection);
	}
	
	return iReturn;
}

/*
 * Sets a vault entry to an integer value
 * 
 * @param		hVault - The vault to set the data in
 * @param		szKey - The key to hold the data
 * @param		iData - The integer value to set
 * 
 * @return		Returns 1 on success, 0 on failure.
 * 
 * @note		Use "*" for the key to set all entries to that data.
 * 			This will update all the timestamps and also set all to non-permanent (even permanent entries)!
 * 
 */
SQLVAULT_FUNC_ATTRIB sqlv_set_num(SQLVault:hVault, szKey[], const iData)
{
	num_to_str(iData, __SQLVAULT_TEMPSTRING, charsmax(__SQLVAULT_TEMPSTRING));
	
	return sqlv_set_data(hVault, szKey, __SQLVAULT_TEMPSTRING);
}

/*
 * Sets a vault entry to a float value
 * 
 * @param		hVault - The vault to set the data in
 * @param		szKey - The key to hold the data
 * @param		flData - The float value to set
 * 
 * @return		Returns 1 on success, 0 on failure.
 * 
 * @note		Use "*" for the key to set all entries to that data.
 * 			This will update all the timestamps and also set all to non-permanent (even permanent entries)!
 * 
 */
SQLVAULT_FUNC_ATTRIB sqlv_set_float(SQLVault:hVault, szKey[], Float:flData)
{
	float_to_str(flData, __SQLVAULT_TEMPSTRING, charsmax(__SQLVAULT_TEMPSTRING));
	
	return sqlv_set_data(hVault, szKey, __SQLVAULT_TEMPSTRING);
}

/*
 * Sets a vault entry to a string value with a permanent entry
 * 
 * @param		hVault - The vault to set the data in
 * @param		szKey - The key to hold the data
 * @param		szData - The string value to set
 * 
 * @return		Returns 1 on success, 0 on failure.
 * 
 * @note		Permanent means that the entry cannot be deleted by sqlv_prune().
 * 
 * @note		Use "*" for the key to set all entries to that data.
 * 			This will update all the timestamps and also set all to permanent (even non-permanent entries)!
 * 
 */
SQLVAULT_FUNC_ATTRIB sqlv_pset_data(SQLVault:hVault, szKey[], szData[])
{
	if(hVault == Invalid_SQLVault)
	{
		return 0;
	}
	
	new Handle:hTuple;
	TrieGetCell(Trie:hVault, "tuple", hTuple);
	
	if(hTuple == Empty_Handle)
	{
		return 0;
	}
	
	new Handle:hConnection, bool:bNewConnection = false;
	
	if(!TrieGetCell(Trie:hVault, "connection", hConnection))
	{
		hConnection = SQL_Connect(hTuple, __SQLVAULT_ERRCODE, __SQLVAULT_ERROR, 127);
		
		if(hConnection == Empty_Handle)
		{
			log_amx("Connection failed in sqlv_pset_data() (%d): %s", __SQLVAULT_ERRCODE, __SQLVAULT_ERROR);
			
			return 0;
		}
		
		bNewConnection = true;
	}
	
	new szVaultName[32];
	TrieGetString(Trie:hVault, "vaultname", szVaultName, charsmax(szVaultName));
	
	QuoteString(szData);
	
	new Handle:hQuery;
	
	if(equal(szKey, "*"))
	{
		hQuery = SQL_PrepareQuery(hConnection,\
			"UPDATE `%s` \
			SET `data` = '%s' \
			AND `timestamp` = %d \
			AND `permanent` = 1;",\
			szVaultName, szData, get_systime());
	}
	else
	{
		QuoteString(szKey);
		
		hQuery = SQL_PrepareQuery(hConnection,\
			"REPLACE INTO `%s` \
			(`key`, `data`, `timestamp`, `permanent`) \
			VALUES \
			('%s', '%s', %d, 1);",\
			szVaultName, szKey, szData, get_systime());
		
		UnQuoteString(szKey);
	}
	
	UnQuoteString(szData);
	
	new iReturn = 0;
	
	if(!SQL_Execute(hQuery))
	{
		SQL_QueryError(hQuery, __SQLVAULT_ERROR, charsmax(__SQLVAULT_ERROR));
		log_amx("Error in sqlv_set_data(): %s", __SQLVAULT_ERROR);
	}
	else
	{
		iReturn = 1;
	}
	
	SQL_FreeHandle(hQuery);
	
	if(bNewConnection)
	{
		SQL_FreeHandle(hConnection);
	}
	
	return iReturn;
}

/*
 * Sets a vault entry to an integer value with a permanent entry
 * 
 * @param		hVault - The vault to set the data in
 * @param		szKey - The key to hold the data
 * @param		iData - The integer value to set
 * 
 * @return		Returns 1 on success, 0 on failure.
 * 
 * @note		Permanent means that the entry cannot be deleted by sqlv_prune().
 * 
 * @note		Use "*" for the key to set all entries to that data.
 * 			This will update all the timestamps and also set all to permanent (even non-permanent entries)!
 * 
 */
SQLVAULT_FUNC_ATTRIB sqlv_pset_num(SQLVault:hVault, szKey[], const iData)
{
	num_to_str(iData, __SQLVAULT_TEMPSTRING, charsmax(__SQLVAULT_TEMPSTRING));
	
	return sqlv_pset_data(hVault, szKey, __SQLVAULT_TEMPSTRING);
}

/*
 * Sets a vault entry to a float value with a permanent entry
 * 
 * @param		hVault - The vault to set the data in
 * @param		szKey - The key to hold the data
 * @param		flData - The float value to set
 * 
 * @return		Returns 1 on success, 0 on failure.
 * 
 * @note		Permanent means that the entry cannot be deleted by sqlv_prune().
 * 
 * @note		Use "*" for the key to set all entries to that data.
 * 			This will update all the timestamps and also set all to permanent (even non-permanent entries)!
 * 
 */
SQLVAULT_FUNC_ATTRIB sqlv_pset_float(SQLVault:hVault, szKey[], Float:flData)
{
	float_to_str(flData, __SQLVAULT_TEMPSTRING, charsmax(__SQLVAULT_TEMPSTRING));
	
	return sqlv_pset_data(hVault, szKey, __SQLVAULT_TEMPSTRING);
}

/*
 * Removes a key from a vault
 * 
 * @param		hVault - The vault to delete the key from
 * @param		szKey - The key to delete
 * 
 * @return		Returns 1 on success, 0 on failure.
 * 
 */
SQLVAULT_FUNC_ATTRIB sqlv_remove(SQLVault:hVault, szKey[])
{
	if(hVault == Invalid_SQLVault)
	{
		return 0;
	}
	
	new Handle:hTuple;
	TrieGetCell(Trie:hVault, "tuple", hTuple);
	
	if(hTuple == Empty_Handle)
	{
		return 0;
	}
	
	new Handle:hConnection, bool:bNewConnection = false;
	
	if(!TrieGetCell(Trie:hVault, "connection", hConnection))
	{
		hConnection = SQL_Connect(hTuple, __SQLVAULT_ERRCODE, __SQLVAULT_ERROR, 127);
		
		if(hConnection == Empty_Handle)
		{
			log_amx("Connection failed in sqlv_remove() (%d): %s", __SQLVAULT_ERRCODE, __SQLVAULT_ERROR);
			
			return 0;
		}
		
		bNewConnection = true;
	}
	
	new szVaultName[32];
	TrieGetString(Trie:hVault, "vaultname", szVaultName, charsmax(szVaultName));
	
	QuoteString(szKey);
	
	new Handle:hQuery = SQL_PrepareQuery(hConnection,\
		"DELETE FROM `%s` \
		WHERE `key` = '%s';",
		szVaultName, szKey);
	
	UnQuoteString(szKey);
	
	new iReturn = 0;
	
	if(!SQL_Execute(hQuery))
	{
		SQL_QueryError(hQuery, __SQLVAULT_ERROR, charsmax(__SQLVAULT_ERROR));
		log_amx("Error in sqlv_remove(): %s", __SQLVAULT_ERROR);
	}
	else if(!(iReturn = SQL_AffectedRows(hQuery)))
	{
		iReturn = 1;
	}
	
	SQL_FreeHandle(hQuery);
	
	if(bNewConnection)
	{
		SQL_FreeHandle(hConnection);
	}
	
	return iReturn;
}

/*
 * Removes all non-permanent entries in a vault that have a timestamp between the start and end timestamps
 * 
 * @param		hVault - The vault to prune
 * @param		iStart - The start timestamp
 * @param		iEnd - The end timestamp
 * 
 * @return		Returns the number of deleted entries (or 1 if none deleted) on success, 0 on failure.
 * 
 */
SQLVAULT_FUNC_ATTRIB sqlv_prune(SQLVault:hVault, iStart, iEnd)
{
	if(hVault == Invalid_SQLVault)
	{
		return 0;
	}
	
	new Handle:hTuple;
	TrieGetCell(Trie:hVault, "tuple", hTuple);
	
	if(hTuple == Empty_Handle)
	{
		return 0;
	}
	
	new Handle:hConnection, bool:bNewConnection = false;
	
	if(!TrieGetCell(Trie:hVault, "connection", hConnection))
	{
		hConnection = SQL_Connect(hTuple, __SQLVAULT_ERRCODE, __SQLVAULT_ERROR, 127);
		
		if(hConnection == Empty_Handle)
		{
			log_amx("Connection failed in sqlv_prune() (%d): %s", __SQLVAULT_ERRCODE, __SQLVAULT_ERROR);
			
			return 0;
		}
		
		bNewConnection = true;
	}
	
	new szVaultName[32];
	TrieGetString(Trie:hVault, "vaultname", szVaultName, charsmax(szVaultName));
	
	new Handle:hQuery = SQL_PrepareQuery(hConnection,\
		"DELETE FROM `%s` \
		WHERE `permanent` = 0 \
		AND %d <= `timestamp` \
		AND `timestamp` <= %d;",
		szVaultName, iStart, iEnd);
	
	new iReturn = 0;
	
	if(!SQL_Execute(hQuery))
	{
		SQL_QueryError(hQuery, __SQLVAULT_ERROR, charsmax(__SQLVAULT_ERROR));
		log_amx("Error in sqlv_prune(): %s", __SQLVAULT_ERROR);
	}
	else if(!(iReturn = SQL_AffectedRows(hQuery)))
	{
		iReturn = 1;
	}
	
	SQL_FreeHandle(hQuery);
	
	if(bNewConnection)
	{
		SQL_FreeHandle(hConnection);
	}
	
	return iReturn;
}

/*
 * Updates the timestamp for a key in a vault
 * 
 * @param		hVault - The vault to update the key in
 * @param		szKey - The key to update the timestamp for
 * @param		iTimeStamp - The timestamp to set for the vault (optional, default is -1)
 * 
 * @return		Returns 1 on success, 0 on failure.
 * 
 * @note		Use -1 for timestamp to update with the current timestamp
 * 
 * @note		Use "*" for the key to touch all entries.
 * 
 */
SQLVAULT_FUNC_ATTRIB sqlv_touch(SQLVault:hVault, szKey[], iTimeStamp = -1)
{
	if(hVault == Invalid_SQLVault)
	{
		return 0;
	}
	
	new Handle:hTuple;
	TrieGetCell(Trie:hVault, "tuple", hTuple);
	
	if(hTuple == Empty_Handle)
	{
		return 0;
	}
	
	new Handle:hConnection, bool:bNewConnection = false;
	
	if(!TrieGetCell(Trie:hVault, "connection", hConnection))
	{
		hConnection = SQL_Connect(hTuple, __SQLVAULT_ERRCODE, __SQLVAULT_ERROR, 127);
		
		if(hConnection == Empty_Handle)
		{
			log_amx("Connection failed in sqlv_touch() (%d): %s", __SQLVAULT_ERRCODE, __SQLVAULT_ERROR);
			
			return 0;
		}
		
		bNewConnection = true;
	}
	
	new szVaultName[32];
	TrieGetString(Trie:hVault, "vaultname", szVaultName, charsmax(szVaultName));
	
	if(iTimeStamp < 0)
	{
		iTimeStamp = get_systime();
	}
	
	new Handle:hQuery;
	
	if(equal(szKey, "*"))
	{
		hQuery = SQL_PrepareQuery(hConnection,\
			"UPDATE `%s` \
			SET `timestamp` = %d;",
			szVaultName, iTimeStamp);
	}
	else
	{
		QuoteString(szKey);
		
		hQuery = SQL_PrepareQuery(hConnection,\
			"UPDATE `%s` \
			SET `timestamp` = %d \
			WHERE `key` = '%s';",
			szVaultName, iTimeStamp, szKey);
		
		UnQuoteString(szKey);
	}
	
	new iReturn = 0;
	
	if(!SQL_Execute(hQuery))
	{
		SQL_QueryError(hQuery, __SQLVAULT_ERROR, charsmax(__SQLVAULT_ERROR));
		log_amx("Error in sqlv_touch(): %s", __SQLVAULT_ERROR);
	}
	else if(!(iReturn = SQL_AffectedRows(hQuery)))
	{
		iReturn = 1;
	}
	
	SQL_FreeHandle(hQuery);
	
	if(bNewConnection)
	{
		SQL_FreeHandle(hConnection);
	}
	
	return iReturn;
}

/*
 * Deletes all entries in a vault
 * 
 * @param		hVault - The vault to delete entries from
 * @param		bSavePermanent - If true, deletes only entries that are not permanent. If false, deletes all entries. (optional, default is false)
 * 
 * @return		Returns total entries deleted (or 1 if empty) on success, 0 on failure.
 * 
 */
SQLVAULT_FUNC_ATTRIB sqlv_clear(SQLVault:hVault, bool:bSavePermanent = false)
{
	if(hVault == Invalid_SQLVault)
	{
		return 0;
	}
	
	new Handle:hTuple;
	TrieGetCell(Trie:hVault, "tuple", hTuple);
	
	if(hTuple == Empty_Handle)
	{
		return 0;
	}
	
	new Handle:hConnection, bool:bNewConnection = false;
	
	if(!TrieGetCell(Trie:hVault, "connection", hConnection))
	{
		hConnection = SQL_Connect(hTuple, __SQLVAULT_ERRCODE, __SQLVAULT_ERROR, 127);
		
		if(hConnection == Empty_Handle)
		{
			log_amx("Connection failed in sqlv_clear() (%d): %s", __SQLVAULT_ERRCODE, __SQLVAULT_ERROR);
			
			return 0;
		}
		
		bNewConnection = true;
	}
	
	new szVaultName[32];
	TrieGetString(Trie:hVault, "vaultname", szVaultName, charsmax(szVaultName));
	
	new Handle:hQuery = SQL_PrepareQuery(hConnection,\
		"DELETE FROM `%s`%s;",
		szVaultName, bSavePermanent ? " WHERE `permanent` = 0" : "");
	
	new iReturn = 0;
	
	if(!SQL_Execute(hQuery))
	{
		SQL_QueryError(hQuery, __SQLVAULT_ERROR, charsmax(__SQLVAULT_ERROR));
		log_amx("Error in sqlv_clear(): %s", __SQLVAULT_ERROR);
	}
	else if(!(iReturn = SQL_AffectedRows(hQuery)))
	{
		iReturn = 1;
	}
	
	SQL_FreeHandle(hQuery);
	
	if(bNewConnection)
	{
		SQL_FreeHandle(hConnection);
	}
	
	return iReturn;
}

/*
 * Gets the total number of entries in the vault
 * 
 * @param		hVault - The vault to find the size of
 * 
 * @return		Returns the total number of entries in the vault
 * 
 */
SQLVAULT_FUNC_ATTRIB sqlv_size(SQLVault:hVault)
{
	if(hVault == Invalid_SQLVault)
	{
		return 0;
	}
	
	new Handle:hTuple;
	TrieGetCell(Trie:hVault, "tuple", hTuple);
	
	if(hTuple == Empty_Handle)
	{
		return 0;
	}
	
	new Handle:hConnection, bool:bNewConnection = false;
	
	if(!TrieGetCell(Trie:hVault, "connection", hConnection))
	{
		hConnection = SQL_Connect(hTuple, __SQLVAULT_ERRCODE, __SQLVAULT_ERROR, 127);
		
		if(hConnection == Empty_Handle)
		{
			log_amx("Connection failed in sqlv_size() (%d): %s", __SQLVAULT_ERRCODE, __SQLVAULT_ERROR);
			
			return 0;
		}
		
		bNewConnection = true;
	}
	
	new szVaultName[32];
	TrieGetString(Trie:hVault, "vaultname", szVaultName, charsmax(szVaultName));
	
	new Handle:hQuery = SQL_PrepareQuery(hConnection,\
		"SELECT COUNT(*) FROM `%s`;",
		szVaultName);
	
	new iReturn = 0;
	
	if(!SQL_Execute(hQuery))
	{
		SQL_QueryError(hQuery, __SQLVAULT_ERROR, charsmax(__SQLVAULT_ERROR));
		log_amx("Error in sqlv_size(): %s", __SQLVAULT_ERROR);
	}
	else if(SQL_NumResults(hQuery))
	{
		iReturn = SQL_ReadResult(hQuery, 0);
	}
	
	SQL_FreeHandle(hQuery);
	
	if(bNewConnection)
	{
		SQL_FreeHandle(hConnection);
	}
	
	return iReturn;
}

/*
 * Reads a vault by key index
 * 
 * @param		hVault - The vault to read from
 * @param		iKeyIndex - The key index to read
 * @param		szKey - The string to hold the key (optional)
 * @param		iKeyLen - The max length of the key buffer (optional)
 * @param		szData - The string to hold the data (optional)
 * @param		iDataLen - The max length of the data buffer (optional)
 * @param		iTimeStamp - The byref variable that holds the timestamp
 * 
 * @return		Returns 1 on success, 0 on failure.
 * 
 * @note		Key indexes start at 0 and stop at 1 before the size of the vault (sqlv_size() - 1)
 * 
 * @note		If you want to read all keys in the vault, use sqlv_read_all().
 * 
 * @note		If a vault is changed by setting data, changing timestamps, deleteing, etc. then the key indexes may change.
 * 			Therefore, those type of actions should not be done if more than 1 key is being read.
 * 
 */
SQLVAULT_FUNC_ATTRIB sqlv_read(SQLVault:hVault, iKeyIndex, szKey[] = "", iKeyLen = 0, szData[] = "", iDataLen = 0, &iTimeStamp = 0)
{
	if(iKeyLen)
	{
		szKey[0] = 0;
	}
	
	if(iDataLen)
	{
		szData[0] = 0;
	}
	
	iTimeStamp = 0;
	
	if(hVault == Invalid_SQLVault)
	{
		return 0;
	}
	
	new Handle:hTuple;
	TrieGetCell(Trie:hVault, "tuple", hTuple);
	
	if(hTuple == Empty_Handle)
	{
		return 0;
	}
	
	new Handle:hConnection, bool:bNewConnection = false;
	
	if(!TrieGetCell(Trie:hVault, "connection", hConnection))
	{
		hConnection = SQL_Connect(hTuple, __SQLVAULT_ERRCODE, __SQLVAULT_ERROR, 127);
		
		if(hConnection == Empty_Handle)
		{
			log_amx("Connection failed in sqlv_read() (%d): %s", __SQLVAULT_ERRCODE, __SQLVAULT_ERROR);
			
			return 0;
		}
		
		bNewConnection = true;
	}
	
	new szVaultName[32];
	TrieGetString(Trie:hVault, "vaultname", szVaultName, charsmax(szVaultName));
	
	new Handle:hQuery = SQL_PrepareQuery(hConnection,\
		"SELECT `key`, `data`, `timestamp` FROM `%s` LIMIT %d, 1;",
		szVaultName, iKeyIndex);
	
	new iReturn = 0;
	
	if(!SQL_Execute(hQuery))
	{
		SQL_QueryError(hQuery, __SQLVAULT_ERROR, charsmax(__SQLVAULT_ERROR));
		log_amx("Error in sqlv_read(): %s", __SQLVAULT_ERROR);
	}
	else if(SQL_NumResults(hQuery))
	{
		iReturn = 1;
		
		if(iKeyLen)
		{
			SQL_ReadResult(hQuery, 0, szKey, iKeyLen);
		}
		
		if(iDataLen)
		{
			SQL_ReadResult(hQuery, 1, szData, iDataLen);
		}
		
		iTimeStamp = SQL_ReadResult(hQuery, 2);
	}
	
	SQL_FreeHandle(hQuery);
	
	if(bNewConnection)
	{
		SQL_FreeHandle(hConnection);
	}
	
	return iReturn;
}

/*
 * Reads all of the vault data into a cell array
 * 
 * @param		hVault - The vault to read from
 * @param		aVaultData - The cell array to hold the data
 * 
 * @return		Returns the total number of vault entries
 * 
 * @note		The cell array contains arrays that correspond to the SQLVaultEntry enum
 * 			
 * @note		Example:
 * 			
 * 			new Array:aVaultData;
 * 			new iVaultKeys = sqlv_read_all(hVault, aVaultData);
 * 			
 * 			new eVaultData[SQLVaultEntry];
 * 			
 * 			for(new i = 0; i < iVaultKeys; i++)
 * 			{
 * 				ArrayGetArray(aVaultData, i, eVaultData);
 * 				
 * 				eVaultData[SQLV_Key] = key
 * 				eVaultData[SQLV_Data] = data
 * 				eVaultData[SQLV_TimeStamp] = timestamp
 * 			}
 * 			
 * 			ArrayDestroy(aVaultData);
 * 
 * @note		The cell array should not be created.
 * 			It is auto-created in the function.
 * 			If the cell array already contains a handle, it is destroyed first.
 * 
 * @note		The cell array needs to be destroyed after being used
 * 
 */
SQLVAULT_FUNC_ATTRIB sqlv_read_all(SQLVault:hVault, &Array:aVaultData)
{
	if(aVaultData != Invalid_Array)
	{
		ArrayDestroy(aVaultData);
	}
	
	aVaultData = ArrayCreate(SQLVaultEntry);
	
	if(hVault == Invalid_SQLVault)
	{
		return 0;
	}
	
	new Handle:hTuple;
	TrieGetCell(Trie:hVault, "tuple", hTuple);
	
	if(hTuple == Empty_Handle)
	{
		return 0;
	}
	
	new Handle:hConnection, bool:bNewConnection = false;
	
	if(!TrieGetCell(Trie:hVault, "connection", hConnection))
	{
		hConnection = SQL_Connect(hTuple, __SQLVAULT_ERRCODE, __SQLVAULT_ERROR, 127);
		
		if(hConnection == Empty_Handle)
		{
			log_amx("Connection failed in sqlv_read_all() (%d): %s", __SQLVAULT_ERRCODE, __SQLVAULT_ERROR);
			
			return 0;
		}
		
		bNewConnection = true;
	}
	
	new szVaultName[32];
	TrieGetString(Trie:hVault, "vaultname", szVaultName, charsmax(szVaultName));
	
	new Handle:hQuery = SQL_PrepareQuery(hConnection,\
		"SELECT `key`, `data`, `timestamp` FROM `%s`;",
		szVaultName);
	
	new iReturn = 0;
	
	if(!SQL_Execute(hQuery))
	{
		SQL_QueryError(hQuery, __SQLVAULT_ERROR, charsmax(__SQLVAULT_ERROR));
		log_amx("Error in sqlv_read_all(): %s", __SQLVAULT_ERROR);
	}
	else if((iReturn = SQL_NumResults(hQuery)))
	{
		new eVaultData[SQLVaultEntry];
		
		while(SQL_MoreResults(hQuery))
		{
			SQL_ReadResult(hQuery, 0, eVaultData[SQLV_Key], charsmax(eVaultData[SQLV_Key]));
			SQL_ReadResult(hQuery, 1, eVaultData[SQLV_Data], charsmax(eVaultData[SQLV_Data]));
			eVaultData[SQLV_TimeStamp] = SQL_ReadResult(hQuery, 2);
			
			ArrayPushArray(aVaultData, eVaultData);
			
			SQL_NextRow(hQuery);
		}
	}
	
	SQL_FreeHandle(hQuery);
	
	if(bNewConnection)
	{
		SQL_FreeHandle(hConnection);
	}
	
	return iReturn;
}

/*
 * Makes a string safe to be held in the vault
 * 
 * @param		szString - The string to be made safe
 * 
 * @return		Returns the length of the string
 * 
 * @note		This overwrites the string's contents, so constants cannot be used.
 * 
 */
SQLVAULT_FUNC_ATTRIB QuoteString(szString[], cRemoveChar = ''')
{
	new i, cChar;
	
	while((cChar = szString[i]))
	{
		if(cChar == cRemoveChar)
		{
			szString[i] = 30;
		}
		
		i++;
	}
	
	return i;
}

/*
 * Restores the strings original state after being used by QuoteString()
 * 
 * @param		szString - The string to be restored
 * 
 * @return		Returns the length of the string
 * 
 * @note		This overwrites the string's contents, so constants cannot be used.
 * 
 */
SQLVAULT_FUNC_ATTRIB UnQuoteString(szString[], cRemoveChar = ''')
{
	new i, cChar;
	
	while((cChar = szString[i]))
	{
		if(cChar == 30)
		{
			szString[i] = cRemoveChar;
		}
		
		i++;
	}
	
	return i;
}
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang11274\\ f0\\ fs16 \n\\ par }
*/
