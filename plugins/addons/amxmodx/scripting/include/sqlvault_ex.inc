#if defined _sqlvault_ex_included
	#endinput
#endif

#define _sqlvault_ex_included

#include <sqlvault>
#include <fakemeta>

SQLVAULT_VAR_ATTRIB const SQLVAULTEX_VERSION[] = "0.0.2";

/*
 * Structure used for sqlv_read_all_ex()
 * 
 * @elem		SQLVEx_Key1 - String that holds the key1 of the 2 key pair
 * @elem		SQLVEx_Key2 - String that holds the key2 of the 2 key pair
 * @elem		SQLVEx_Data - String that holds the data
 * @elem		SQLVEx_TimeStamp - Integer that holds the timestamp
 * 
 */
enum _:SQLVaultEntryEx
{
	SQLVEx_Key1[64],
	SQLVEx_Key2[64],
	SQLVEx_Data[512],
	SQLVEx_TimeStamp
};

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
SQLVAULT_FUNC_ATTRIB sqlv_init_ex(SQLVault:hVault)
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
			log_amx("Connection failed in sqlv_init_ex() (%d): %s", __SQLVAULT_ERRCODE, __SQLVAULT_ERROR);
			
			return 0;
		}
		
		bNewConnection = true;
	}
	
	new szVaultName[32];
	TrieGetString(Trie:hVault, "vaultname", szVaultName, charsmax(szVaultName));
	
	new Handle:hQuery = SQL_PrepareQuery(hConnection,\
		"CREATE TABLE IF NOT EXISTS `%s_ex` \
		(`key1` VARCHAR(64) NOT NULL, \
		`key2` VARCHAR(64) NOT NULL, \
		`data` VARCHAR(512) NOT NULL, \
		`timestamp` INT(11) NOT NULL, \
		`permanent` INT(11) NOT NULL, \
		PRIMARY KEY (`key1`, `key2`));",
		szVaultName);
	
	new iReturn = 1;
	
	if(!SQL_Execute(hQuery))
	{
		SQL_QueryError(hQuery, __SQLVAULT_ERROR, charsmax(__SQLVAULT_ERROR));
		log_amx("Error in sqlv_init_ex(): %s", __SQLVAULT_ERROR);
		
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
 * @param		szKey1 - The key1 of the 2 key pair holding the data
 * @param		szKey2 - The key2 of the 2 key pair holding the data
 * @param		szData - The buffer to hold the data
 * @param		iDataLen - The max length of the data buffer
 * @param		iTimeStamp - The byref variable holding the timestamp
 * 
 * @return		Returns 1 on success, 0 on failure
 * 
 */
SQLVAULT_FUNC_ATTRIB sqlv_get_data_ex(SQLVault:hVault, szKey1[], szKey2[], szData[], iDataLen, &iTimeStamp = 0)
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
			log_amx("Connection failed in sqlv_get_data_ex() (%d): %s", __SQLVAULT_ERRCODE, __SQLVAULT_ERROR);
			
			return 0;
		}
		
		bNewConnection = true;
	}
	
	new szVaultName[32];
	TrieGetString(Trie:hVault, "vaultname", szVaultName, charsmax(szVaultName));
	
	QuoteString(szKey1);
	QuoteString(szKey2);
	
	new Handle:hQuery = SQL_PrepareQuery(hConnection,\
		"SELECT `data`, `timestamp` \
		FROM `%s_ex` \
		WHERE `key1` = '%s' \
		AND `key2` = '%s';",
		szVaultName, szKey1, szKey2);
	
	UnQuoteString(szKey1);
	UnQuoteString(szKey2);
	
	new iReturn = 0;
	
	if(!SQL_Execute(hQuery))
	{
		SQL_QueryError(hQuery, __SQLVAULT_ERROR, charsmax(__SQLVAULT_ERROR));
		log_amx("Error in sqlv_get_data_ex(): %s", __SQLVAULT_ERROR);
	}
	else
	{
		iReturn = SQL_NumResults(hQuery);
		
		if(iReturn)
		{
			SQL_ReadResult(hQuery, 0, szData, iDataLen);
			
			iTimeStamp = SQL_ReadResult(hQuery, 1);
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
 * Gets an integer value from a vault
 * 
 * @param		hVault - The vault to get the data from
 * @param		szKey1 - The key1 holding the data of the 2 key pair
 * @param		szKey2 - The key2 holding the data of the 2 key pair
 * @param		iTimeStamp - The byref variable holding the timestamp
 * 
 * @return		Returns the integer value on success, 0 on failure
 * 
 */
SQLVAULT_FUNC_ATTRIB sqlv_get_num_ex(SQLVault:hVault, szKey1[], szKey2[], &iTimeStamp = 0)
{
	if(sqlv_get_data_ex(hVault, szKey1, szKey2, __SQLVAULT_TEMPSTRING, charsmax(__SQLVAULT_TEMPSTRING), iTimeStamp))
	{
		return str_to_num(__SQLVAULT_TEMPSTRING);
	}
	
	return 0;
}

/*
 * Gets a float value from a vault
 * 
 * @param		hVault - The vault to get the data from
 * @param		szKey1 - The key1 holding the data of the 2 key pair
 * @param		szKey2 - The key2 holding the data of the 2 key pair
 * @param		iTimeStamp - The byref variable holding the timestamp
 * 
 * @return		Returns the float value on success, 0.0 on failure
 * 
 */
SQLVAULT_FUNC_ATTRIB Float:sqlv_get_float_ex(SQLVault:hVault, szKey1[], szKey2[], &iTimeStamp = 0)
{
	if(sqlv_get_data_ex(hVault, szKey1, szKey2, __SQLVAULT_TEMPSTRING, charsmax(__SQLVAULT_TEMPSTRING), iTimeStamp))
	{
		return str_to_float(__SQLVAULT_TEMPSTRING);
	}
	
	return 0.0;
}

/*
 * Checks if a key exists in a vault
 * 
 * @param		hVault - The vault to look in
 * @param		szKey1 - The key1 to look for of the 2 key pair
 * @param		szKey2 - The key2 to look for of the 2 key pair
 * 
 * @return		Returns 1 if exists, 0 if it doesn't.
 * 
 */
SQLVAULT_FUNC_ATTRIB sqlv_key_exists_ex(SQLVault:hVault, szKey1[], szKey2[])
{
	return sqlv_get_data_ex(hVault, szKey1, szKey2, __SQLVAULT_TEMPSTRING, charsmax(__SQLVAULT_TEMPSTRING));
}

/*
 * Sets a vault entry to a string value
 * 
 * @param		hVault - The vault to set the data in
 * @param		szKey1 - The key1 to hold the data of the 2 key pair
 * @param		szKey2 - The key2 to hold the data of the 2 key pair
 * @param		szData - The string value to set
 * 
 * @return		Returns 1 on success, 0 on failure.
 * 
 * @note		Use "*" for szKey1 and it will set all values matching szKey2
 * @note		Use "*" for szKey2 and it will set all values matching szKey1
 * @note		Use "*" for szKey1 and szKey2 and all values in the vault will be set
 * 
 * @note		When using "*" as either key, all entries that are affected have the timestamp update.
 * 			Also, all entries affected are set to non-permanent (even permanent entries)!
 * 
 */
SQLVAULT_FUNC_ATTRIB sqlv_set_data_ex(SQLVault:hVault, szKey1[], szKey2[], szData[])
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
			log_amx("Connection failed in sqlv_set_data_ex() (%d): %s", __SQLVAULT_ERRCODE, __SQLVAULT_ERROR);
			
			return 0;
		}
		
		bNewConnection = true;
	}
	
	new szVaultName[32];
	TrieGetString(Trie:hVault, "vaultname", szVaultName, charsmax(szVaultName));
	
	QuoteString(szData);
	
	new Handle:hQuery;
	
	if(equal(szKey1, "*"))
	{
		if(equal(szKey2, "*"))
		{
			hQuery = SQL_PrepareQuery(hConnection,\
				"UPDATE `%s_ex` \
				SET `data` = '%s' \
				AND `timestamp` = %d \
				AND `permanent` = 0;",
				szVaultName, szData, get_systime());
		}
		else
		{
			QuoteString(szKey2);
			
			hQuery = SQL_PrepareQuery(hConnection,\
				"UPDATE `%s_ex` \
				SET `data` = '%s' \
				AND `timestamp` = %d \
				AND `permanent` = 0 \
				WHERE `key2` = '%s';",
				szVaultName, szData, get_systime(), szKey2);
			
			QuoteString(szKey2);
		}
	}
	else
	{
		QuoteString(szKey1);
		
		if(equal(szKey2, "*"))
		{
			hQuery = SQL_PrepareQuery(hConnection,\
				"UPDATE `%s_ex` \
				SET `data` = '%s' \
				AND `timestamp` = %d \
				AND `permanent` = 0 \
				WHERE `key1` = '%s';",
				szVaultName, szData, get_systime(), szKey1);
		}
		else
		{
			QuoteString(szKey2);
			
			hQuery = SQL_PrepareQuery(hConnection,\
				"REPLACE INTO `%s_ex` \
				(`key1`, `key2`, `data`, `timestamp`, `permanent`) \
				VALUES \
				('%s', '%s', '%s', %d, 0);",\
				szVaultName, szKey1, szKey2, szData, get_systime());
			
			QuoteString(szKey2);
		}
		
		UnQuoteString(szKey1);
	}
	
	UnQuoteString(szData);
	
	new iReturn = 0;
	
	if(!SQL_Execute(hQuery))
	{
		SQL_QueryError(hQuery, __SQLVAULT_ERROR, charsmax(__SQLVAULT_ERROR));
		log_amx("Error in sqlv_set_data_ex(): %s", __SQLVAULT_ERROR);
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
 * @param		szKey1 - The key1 to hold the data of the 2 key pair
 * @param		szKey2 - The key2 to hold the data of the 2 key pair
 * @param		iData - The integer value to set
 * 
 * @return		Returns 1 on success, 0 on failure.
 * 
 * @note		Use "*" for szKey1 and it will set all values matching szKey2
 * @note		Use "*" for szKey2 and it will set all values matching szKey1
 * @note		Use "*" for szKey1 and szKey2 and all values in the vault will be set
 * 
 * @note		When using "*" as either key, all entries that are affected have the timestamp update.
 * 			Also, all entries affected are set to non-permanent (even permanent entries)!
 * 
 */
SQLVAULT_FUNC_ATTRIB sqlv_set_num_ex(SQLVault:hVault, szKey1[] ,szKey2[], const iData)
{
	num_to_str(iData, __SQLVAULT_TEMPSTRING, charsmax(__SQLVAULT_TEMPSTRING));
	
	return sqlv_set_data_ex(hVault, szKey1, szKey2, __SQLVAULT_TEMPSTRING);
}

/*
 * Sets a vault entry to a float value
 * 
 * @param		hVault - The vault to set the data in
 * @param		szKey1 - The key1 to hold the data of the 2 key pair
 * @param		szKey2 - The key2 to hold the data of the 2 key pair
 * @param		flData - The float value to set
 * 
 * @return		Returns 1 on success, 0 on failure.
 * 
 * @note		Use "*" for szKey1 and it will set all values matching szKey2
 * @note		Use "*" for szKey2 and it will set all values matching szKey1
 * @note		Use "*" for szKey1 and szKey2 and all values in the vault will be set
 * 
 * @note		When using "*" as either key, all entries that are affected have the timestamp update.
 * 			Also, all entries affected are set to non-permanent (even permanent entries)!
 * 
 */
SQLVAULT_FUNC_ATTRIB sqlv_set_float_ex(SQLVault:hVault, szKey1[], szKey2[], Float:flData)
{
	float_to_str(flData, __SQLVAULT_TEMPSTRING, charsmax(__SQLVAULT_TEMPSTRING));
	
	return sqlv_set_data_ex(hVault, szKey1, szKey2, __SQLVAULT_TEMPSTRING);
}

/*
 * Sets a vault entry to a string value with a permanent entry
 * 
 * @param		hVault - The vault to set the data in
 * @param		szKey1 - The key1 to hold the data of the 2 key pair
 * @param		szKey2 - The key2 to hold the data of the 2 key pair
 * @param		szData - The string value to set
 * 
 * @return		Returns 1 on success, 0 on failure.
 * 
 * @note		Permanent means that the entry cannot be deleted by sqlv_prune_ex().
 * 
 * @note		Use "*" for szKey1 and it will set all values matching szKey2
 * @note		Use "*" for szKey2 and it will set all values matching szKey1
 * @note		Use "*" for szKey1 and szKey2 and all values in the vault will be set
 * 
 * @note		When using "*" as either key, all entries that are affected have the timestamp update.
 * 			Also, all entries affected are set to permanent (even non-permanent entries)!
 * 
 */
SQLVAULT_FUNC_ATTRIB sqlv_pset_data_ex(SQLVault:hVault, szKey1[], szKey2[], szData[])
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
			log_amx("Connection failed in sqlv_pset_data_ex() (%d): %s", __SQLVAULT_ERRCODE, __SQLVAULT_ERROR);
			
			return 0;
		}
		
		bNewConnection = true;
	}
	
	new szVaultName[32];
	TrieGetString(Trie:hVault, "vaultname", szVaultName, charsmax(szVaultName));
	
	QuoteString(szData);
	
	new Handle:hQuery;
	
	if(equal(szKey1, "*"))
	{
		if(equal(szKey2, "*"))
		{
			hQuery = SQL_PrepareQuery(hConnection,\
				"UPDATE `%s_ex` \
				SET `data` = '%s' \
				AND `timestamp` = %d \
				AND `permanent` = 1;",
				szVaultName, szData, get_systime());
		}
		else
		{
			QuoteString(szKey2);
			
			hQuery = SQL_PrepareQuery(hConnection,\
				"UPDATE `%s_ex` \
				SET `data` = '%s' \
				AND `timestamp` = %d \
				AND `permanent` = 1 \
				WHERE `key2` = '%s';",
				szVaultName, szData, get_systime(), szKey2);
			
			QuoteString(szKey2);
		}
	}
	else
	{
		QuoteString(szKey1);
		
		if(equal(szKey2, "*"))
		{
			hQuery = SQL_PrepareQuery(hConnection,\
				"UPDATE `%s_ex` \
				SET `data` = '%s' \
				AND `timestamp` = %d \
				AND `permanent` = 1 \
				WHERE `key1` = '%s';",
				szVaultName, szData, get_systime(), szKey1);
		}
		else
		{
			QuoteString(szKey2);
			
			hQuery = SQL_PrepareQuery(hConnection,\
				"REPLACE INTO `%s_ex` \
				(`key1`, `key2`, `data`, `timestamp`, `permanent`) \
				VALUES \
				('%s', '%s', '%s', %d, 1);",\
				szVaultName, szKey1, szKey2, szData, get_systime());
			
			QuoteString(szKey2);
		}
		
		UnQuoteString(szKey1);
	}
	
	UnQuoteString(szData);
	
	new iReturn = 0;
	
	if(!SQL_Execute(hQuery))
	{
		SQL_QueryError(hQuery, __SQLVAULT_ERROR, charsmax(__SQLVAULT_ERROR));
		log_amx("Error in sqlv_set_data_ex(): %s", __SQLVAULT_ERROR);
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
 * @param		szKey1 - The key1 to hold the data of the 2 key pair
 * @param		szKey2 - The key2 to hold the data of the 2 key pair
 * @param		iData - The integer value to set
 * 
 * @return		Returns 1 on success, 0 on failure.
 * 
 * @note		Permanent means that the entry cannot be deleted by sqlv_prune_ex().
 * 
 * @note		Use "*" for szKey1 and it will set all values matching szKey2
 * @note		Use "*" for szKey2 and it will set all values matching szKey1
 * @note		Use "*" for szKey1 and szKey2 and all values in the vault will be set
 * 
 * @note		When using "*" as either key, all entries that are affected have the timestamp update.
 * 			Also, all entries affected are set to permanent (even non-permanent entries)!
 * 
 */
SQLVAULT_FUNC_ATTRIB sqlv_pset_num_ex(SQLVault:hVault, szKey1[], szKey2[], const iData)
{
	num_to_str(iData, __SQLVAULT_TEMPSTRING, charsmax(__SQLVAULT_TEMPSTRING));
	
	return sqlv_pset_data_ex(hVault, szKey1, szKey2, __SQLVAULT_TEMPSTRING);
}

/*
 * Sets a vault entry to a float value with a permanent entry
 * 
 * @param		hVault - The vault to set the data in
 * @param		szKey1 - The key1 to hold the data of the 2 key pair
 * @param		szKey2 - The key2 to hold the data
 * @param		flData - The float value to set
 * 
 * @return		Returns 1 on success, 0 on failure.
 * 
 * @note		Permanent means that the entry cannot be deleted by sqlv_prune_ex().
 * 
 * @note		Use "*" for szKey1 and it will set all values matching szKey2
 * @note		Use "*" for szKey2 and it will set all values matching szKey1
 * @note		Use "*" for szKey1 and szKey2 and all values in the vault will be set
 * 
 * @note		When using "*" as either key, all entries that are affected have the timestamp update.
 * 			Also, all entries affected are set to permanent (even non-permanent entries)!
 * 
 */
SQLVAULT_FUNC_ATTRIB sqlv_pset_float_ex(SQLVault:hVault, szKey1[], szKey2[], Float:flData)
{
	float_to_str(flData, __SQLVAULT_TEMPSTRING, charsmax(__SQLVAULT_TEMPSTRING));
	
	return sqlv_pset_data_ex(hVault, szKey1, szKey2, __SQLVAULT_TEMPSTRING);
}

/*
 * Removes a key from a vault
 * 
 * @param		hVault - The vault to delete the key from
 * @param		szKey1 - The key1 to delete of the 2 key pair
 * @param		szKey2 - The key2 to delete of the 2 key pair
 * 
 * @return		Returns 1 on success, 0 on failure.
 * 
 * @note		Use "*" for key1 to delete all keys matching key2.
 * @note		Use "*" for key2 to delete all keys matching key1.
 * @note		If "*" is used for both keys, it is the same as using sqlv_clear_ex().
 * 
 */
SQLVAULT_FUNC_ATTRIB sqlv_remove_ex(SQLVault:hVault, szKey1[], szKey2[])
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
			log_amx("Connection failed in sqlv_remove_ex() (%d): %s", __SQLVAULT_ERRCODE, __SQLVAULT_ERROR);
			
			return 0;
		}
		
		bNewConnection = true;
	}
	
	new szVaultName[32];
	TrieGetString(Trie:hVault, "vaultname", szVaultName, charsmax(szVaultName));
	
	new Handle:hQuery;
	
	if(equal(szKey1, "*"))
	{
		if(equal(szKey2, "*"))
		{
			hQuery = SQL_PrepareQuery(hConnection,\
				"DELETE FROM `%s_ex`;",
				szVaultName);
		}
		else
		{
			QuoteString(szKey2);
			
			hQuery = SQL_PrepareQuery(hConnection,\
				"DELETE FROM `%s_ex` \
				WHERE `key2` = '%s';",
				szVaultName, szKey2);
			
			UnQuoteString(szKey2);
		}
	}
	else
	{
		QuoteString(szKey1);
		
		if(equal(szKey2, "*"))
		{
			hQuery = SQL_PrepareQuery(hConnection,\
				"DELETE FROM `%s_ex` \
				WHERE `key1` = '%s';",
				szVaultName, szKey1);
		}
		else
		{
			QuoteString(szKey2);
			
			hQuery = SQL_PrepareQuery(hConnection,\
				"DELETE FROM `%s_ex` \
				WHERE `key1` = '%s' \
				AND `key2` = '%s';",
				szVaultName, szKey1, szKey2);
			
			UnQuoteString(szKey2);
		}
		
		UnQuoteString(szKey2);
	}
	
	new iReturn = 0;
	
	if(!SQL_Execute(hQuery))
	{
		SQL_QueryError(hQuery, __SQLVAULT_ERROR, charsmax(__SQLVAULT_ERROR));
		log_amx("Error in sqlv_remove_ex(): %s", __SQLVAULT_ERROR);
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
SQLVAULT_FUNC_ATTRIB sqlv_prune_ex(SQLVault:hVault, iStart, iEnd)
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
			log_amx("Connection failed in sqlv_prune_ex() (%d): %s", __SQLVAULT_ERRCODE, __SQLVAULT_ERROR);
			
			return 0;
		}
		
		bNewConnection = true;
	}
	
	new szVaultName[32];
	TrieGetString(Trie:hVault, "vaultname", szVaultName, charsmax(szVaultName));
	
	new Handle:hQuery = SQL_PrepareQuery(hConnection,\
		"DELETE FROM `%s_ex` \
		WHERE `permanent` = 0 \
		AND %d <= `timestamp` \
		AND `timestamp` <= %d;",
		szVaultName, iStart, iEnd);
	
	new iReturn = 0;
	
	if(!SQL_Execute(hQuery))
	{
		SQL_QueryError(hQuery, __SQLVAULT_ERROR, charsmax(__SQLVAULT_ERROR));
		log_amx("Error in sqlv_prune_ex(): %s", __SQLVAULT_ERROR);
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
 * @param		szKey1 - The key1 to update the timestamp for of the 2 key pair
 * @param		szKey2 - The key2 to update the timestamp for of the 2 key pair
 * @param		iTimeStamp - The timestamp to set for the vault (optional, default is -1)
 * 
 * @return		Returns 1 on success, 0 on failure.
 * 
 * @note		Use -1 for timestamp to update with the current timestamp
 * 
 * @note		Permanent means that the entry cannot be deleted by sqlv_prune_ex().
 * 
 * @note		Use "*" for szKey1 and it will update all timestamps on entries matching szKey2
 * @note		Use "*" for szKey2 and it will update all timestamps on entries matching szKey1
 * @note		Use "*" for szKey1 and szKey2 and all timestamps will be updated
 * 
 */
SQLVAULT_FUNC_ATTRIB sqlv_touch_ex(SQLVault:hVault, szKey1[], szKey2[], iTimeStamp = -1)
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
			log_amx("Connection failed in sqlv_touch_ex() (%d): %s", __SQLVAULT_ERRCODE, __SQLVAULT_ERROR);
			
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
	
	if(equal(szKey1, "*"))
	{
		if(equal(szKey2, "*"))
		{
			hQuery = SQL_PrepareQuery(hConnection,\
				"UPDATE `%s_ex` \
				SET `timestamp` = %d;",
				szVaultName, iTimeStamp);
		}
		else
		{
			QuoteString(szKey2);
			
			hQuery = SQL_PrepareQuery(hConnection,\
				"UPDATE `%s_ex` \
				SET `timestamp` = %d \
				WHERE `key2` = '%s';",
				szVaultName, iTimeStamp, szKey2);
			
			QuoteString(szKey2);
		}
	}
	else
	{
		QuoteString(szKey1);
		
		if(equal(szKey2, "*"))
		{
			hQuery = SQL_PrepareQuery(hConnection,\
				"UPDATE `%s_ex` \
				SET `timestamp` = %d \
				WHERE `key1` = '%s';",
				szVaultName, iTimeStamp, szKey1);
		}
		else
		{
			QuoteString(szKey2);
			
			hQuery = SQL_PrepareQuery(hConnection,\
				"UPDATE `%s_ex` \
				SET `timestamp` = %d \
				WHERE `key1` = '%s' \
				AND `key2` = '%s';",
				szVaultName, iTimeStamp, szKey1, szKey2);
			
			QuoteString(szKey2);
		}
		
		UnQuoteString(szKey1);
	}
	
	new iReturn = 0;
	
	if(!SQL_Execute(hQuery))
	{
		SQL_QueryError(hQuery, __SQLVAULT_ERROR, charsmax(__SQLVAULT_ERROR));
		log_amx("Error in sqlv_touch_ex(): %s", __SQLVAULT_ERROR);
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
SQLVAULT_FUNC_ATTRIB sqlv_clear_ex(SQLVault:hVault, bool:bSavePermanent = false)
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
			log_amx("Connection failed in sqlv_clear_ex() (%d): %s", __SQLVAULT_ERRCODE, __SQLVAULT_ERROR);
			
			return 0;
		}
		
		bNewConnection = true;
	}
	
	new szVaultName[32];
	TrieGetString(Trie:hVault, "vaultname", szVaultName, charsmax(szVaultName));
	
	new Handle:hQuery = SQL_PrepareQuery(hConnection,\
		"DELETE FROM `%s_ex`%s;",
		szVaultName, bSavePermanent ? " WHERE `permanent` = 0" : "");
	
	new iReturn = 0;
	
	if(!SQL_Execute(hQuery))
	{
		SQL_QueryError(hQuery, __SQLVAULT_ERROR, charsmax(__SQLVAULT_ERROR));
		log_amx("Error in sqlv_clear_ex(): %s", __SQLVAULT_ERROR);
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
SQLVAULT_FUNC_ATTRIB sqlv_size_ex(SQLVault:hVault)
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
			log_amx("Connection failed in sqlv_size_ex() (%d): %s", __SQLVAULT_ERRCODE, __SQLVAULT_ERROR);
			
			return 0;
		}
		
		bNewConnection = true;
	}
	
	new szVaultName[32];
	TrieGetString(Trie:hVault, "vaultname", szVaultName, charsmax(szVaultName));
	
	new Handle:hQuery = SQL_PrepareQuery(hConnection,\
		"SELECT COUNT(*) FROM `%s_ex`;",
		szVaultName);
	
	new iReturn = 0;
	
	if(!SQL_Execute(hQuery))
	{
		SQL_QueryError(hQuery, __SQLVAULT_ERROR, charsmax(__SQLVAULT_ERROR));
		log_amx("Error in sqlv_size_ex(): %s", __SQLVAULT_ERROR);
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
 * @param		szKey - The string to hold the key of the 2 key pair (optional)
 * @param		iKeyLen - The max length of the key buffer of the 2 key pair (optional)
 * @param		szKey1 - The string to hold the key1 of the 2 key pair (optional)
 * @param		iKey2Len - The max length of the key2 buffer of the 2 key pair (optional)
 * @param		szData - The string to hold the data (optional)
 * @param		iDataLen - The max length of the data buffer (optional)
 * @param		iTimeStamp - The byref variable that holds the timestamp
 * 
 * @return		Returns 1 on success, 0 on failure.
 * 
 * @note		Key indexes start at 0 and stop at 1 before the size of the vault (sqlv_size_ex() - 1)
 * 
 * @note		If you want to read all keys in the vault, use sqlv_read_all_ex().
 * 
 */
SQLVAULT_FUNC_ATTRIB sqlv_read_ex(SQLVault:hVault, iKeyIndex, szKey1[] = "", iKey1Len = 0, szKey2[] = "", iKey2Len = 0, szData[] = "", iDataLen = 0, &iTimeStamp = 0)
{
	if(iKey1Len)
	{
		szKey1[0] = 0;
	}
	
	if(iKey2Len)
	{
		szKey2[0] = 0;
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
			log_amx("Connection failed in sqlv_read_ex() (%d): %s", __SQLVAULT_ERRCODE, __SQLVAULT_ERROR);
			
			return 0;
		}
		
		bNewConnection = true;
	}
	
	new szVaultName[32];
	TrieGetString(Trie:hVault, "vaultname", szVaultName, charsmax(szVaultName));
	
	new Handle:hQuery = SQL_PrepareQuery(hConnection,\
		"SELECT `key1`, `key2`, `data`, `timestamp` FROM `%s_ex` LIMIT %d, 1;",
		szVaultName, iKeyIndex);
	
	new iReturn = 0;
	
	if(!SQL_Execute(hQuery))
	{
		SQL_QueryError(hQuery, __SQLVAULT_ERROR, charsmax(__SQLVAULT_ERROR));
		log_amx("Error in sqlv_read_ex(): %s", __SQLVAULT_ERROR);
	}
	else if(SQL_NumResults(hQuery))
	{
		iReturn = 1;
		
		if(iKey1Len)
		{
			SQL_ReadResult(hQuery, 0, szKey1, iKey1Len);
		}
		
		if(iKey2Len)
		{
			SQL_ReadResult(hQuery, 1, szKey2, iKey2Len);
		}
		
		if(iDataLen)
		{
			SQL_ReadResult(hQuery, 2, szData, iDataLen);
		}
		
		iTimeStamp = SQL_ReadResult(hQuery, 3);
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
 * @note		The cell array contains arrays that correspond to the SQLVaultEntryEx enum
 * 			
 * @note		Example:
 * 			
 * 			new Array:aVaultData;
 * 			new iVaultKeys = sqlv_read_all_ex(hVault, aVaultData);
 * 			
 * 			new eVaultData[SQLVaultEntryEx];
 * 			
 * 			for(new i = 0; i < iVaultKeys; i++)
 * 			{
 * 				ArrayGetArray(aVaultData, i, eVaultData);
 * 				
 * 				eVaultData[SQLVEx_Key1] = key1 of the 2 key pair
 * 				eVaultData[SQLVEx_Key2] = key2 of the 2 key pair
 * 				eVaultData[SQLVEx_Data] = data
 * 				eVaultData[SQLVEx_TimeStamp] = timestamp
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
SQLVAULT_FUNC_ATTRIB sqlv_read_all_ex(SQLVault:hVault, &Array:aVaultData)
{
	if(aVaultData != Invalid_Array)
	{
		ArrayDestroy(aVaultData);
	}
	
	aVaultData = ArrayCreate(SQLVaultEntryEx);
	
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
			log_amx("Connection failed in sqlv_read_all_ex() (%d): %s", __SQLVAULT_ERRCODE, __SQLVAULT_ERROR);
			
			return 0;
		}
		
		bNewConnection = true;
	}
	
	new szVaultName[32];
	TrieGetString(Trie:hVault, "vaultname", szVaultName, charsmax(szVaultName));
	
	new Handle:hQuery = SQL_PrepareQuery(hConnection,\
		"SELECT `key1`, `key2`, `data`, `timestamp` FROM `%s_ex`;",
		szVaultName);
	
	new iReturn = 0;
	
	if(!SQL_Execute(hQuery))
	{
		SQL_QueryError(hQuery, __SQLVAULT_ERROR, charsmax(__SQLVAULT_ERROR));
		log_amx("Error in sqlv_read_all_ex(): %s", __SQLVAULT_ERROR);
	}
	else if((iReturn = SQL_NumResults(hQuery)))
	{
		new eVaultData[SQLVaultEntryEx];
		
		while(SQL_MoreResults(hQuery))
		{
			SQL_ReadResult(hQuery, 0, eVaultData[SQLVEx_Key1], charsmax(eVaultData[SQLVEx_Key1]));
			SQL_ReadResult(hQuery, 1, eVaultData[SQLVEx_Key2], charsmax(eVaultData[SQLVEx_Key2]));
			SQL_ReadResult(hQuery, 2, eVaultData[SQLVEx_Data], charsmax(eVaultData[SQLVEx_Data]));
			eVaultData[SQLVEx_TimeStamp] = SQL_ReadResult(hQuery, 3);
			
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
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang11274\\ f0\\ fs16 \n\\ par }
*/
