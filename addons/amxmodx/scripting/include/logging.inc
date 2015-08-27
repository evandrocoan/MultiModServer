#if defined _logging_included
  #endinput
#endif
#define _logging_included


// logging flags
#define LOG_AMXX 1
#define LOG_CHAT 2
#define LOG_FILE 4

// name,userid,authid,team

stock create_log_entry(id, pluginAbbr[], logFlags, logText[])
{
	// get trigger information
	new name[32], userID[8], authID[32], team[16]
	if (id) // player triggered this log entry
	{
		get_user_name(id, name, 31)
		num_to_str(get_user_userid(id), userID, 7)
		get_user_authid(id, authID, 31)
		get_user_team(id, team, 15)
	}

	// create the trigger text
	new logTrigger[128]
	format(logTrigger, 127, "^"<%s><%s><%s><%s>^"", name, userID, authID, team)

	// log in the current AMXX log
	if (logFlags & LOG_AMXX) 
	{
		log_amx("%s %s", logTrigger, logText)
	}

	// log into a unique file for this plugin
	if (logFlags & LOG_FILE) 
	{
		new logFile[32]
		get_current_log(pluginAbbr, logFile, 31)

		log_to_file(logFile, "%s %s", logTrigger, logText)
	}

	// log as a chat message in the server log
	if (logFlags & LOG_CHAT) 
	{
		new chatLogText[128]
		
		// make quotes in log text palatable to 3rd party chat log viewers
		new isFound = 1
		format(chatLogText, 127, "%s", logText)
		while (isFound) isFound = replace(chatLogText, 127, "^"", "'")

		// if player triggered this log entry, add the player name to the log text
		if (id) format(chatLogText, 127, "%s %s", name, chatLogText)
		
		log_message("^"<><><>^" triggered ^"amx_chat^" (text ^"[%s] %s^")", pluginAbbr, chatLogText)
	}
}

stock get_current_log(pluginAbbr[], currentFile[], currentFileSize)
{
	// get the current month number
	new currentMonth[3]
	get_time("%m", currentMonth, 2)
	
	// right-justify the month and pad the left with a 0
	if (equal(currentMonth[1], "/0"))
		format(currentMonth, 2, "0%s", currentMonth[0])

	// ensure the plugin shortname is in lowercase
	new lowerPluginAbbr[16]
	copy(lowerPluginAbbr, 15, pluginAbbr)
	strtolower(lowerPluginAbbr)
	
	// set the current log file
	format(currentFile, currentFileSize, "%s%s.log", lowerPluginAbbr, currentMonth, 31)	
}

stock cycle_log_files(pluginAbbr[], prevMonthsToKeep)
{
	// delete old log file
	if (prevMonthsToKeep < 11) // always retain the current month
	{
		// get the current month number
		new currentMonthText[3]
		get_time("%m", currentMonthText, 2)

		new currentMonthNum = str_to_num(currentMonthText)
		new monthToDelete = constraint_offset(1, 12, currentMonthNum, (-prevMonthsToKeep - 1))
		new logToDelete[128]
		get_localinfo("amxx_logdir", logToDelete, 127)

		if (monthToDelete < 10)
			format(logToDelete, 127, "%s/%s0%d.log", logToDelete, pluginAbbr, monthToDelete)
		else
			format(logToDelete, 127, "%s/%s%d.log", logToDelete, pluginAbbr, monthToDelete)

		if (file_exists(logToDelete)) delete_file(logToDelete)
	}
}