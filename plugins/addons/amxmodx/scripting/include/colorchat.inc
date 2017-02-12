#if defined _colorchat_included
  #endinput
#endif
#define _colorchat_included

/* ColorChat Support */
#define NORMAL DontChange
#define GREEN DontChange
#define TEAM_COLOR DontChange
#define RED Red
#define BLUE Blue
#define GREY Grey
#define ColorChat client_print_color
/* ColorChat Support */

enum _:Colors {
	DontChange,
	Red,
	Blue,
	Grey
};

stock const g_szTeamName[Colors][] = 
{
	"UNASSIGNED",
	"TERRORIST",
	"CT",
	"SPECTATOR"
};

stock client_print_color(id, iColor=DontChange, const szMsg[], any:...)
{
	// check if id is different from 0
	if( id && !is_user_connected(id) )
	{
		return 0;
	}

	if( iColor > Grey )
	{
		iColor = DontChange;
	}

	new szMessage[192];
	if( iColor == DontChange )
	{
		szMessage[0] = 0x04;
	}
	else
	{
		szMessage[0] = 0x03;
	}

	new iParams = numargs();
	// Specific player code
	if(id)
	{
		if( iParams == 3 )
		{
			copy(szMessage[1], charsmax(szMessage)-1, szMsg);
		}
		else
		{
			vformat(szMessage[1], charsmax(szMessage)-1, szMsg, 4);
		}

		if( iColor )
		{
			new szTeam[11]; // store current team so we can restore it
			get_user_team(id, szTeam, charsmax(szTeam));

			// set id TeamInfo in consequence
			// so SayText msg gonna show the right color
			Send_TeamInfo(id, id, g_szTeamName[iColor]);

			// Send the message
			Send_SayText(id, id, szMessage);

			// restore TeamInfo
			Send_TeamInfo(id, id, szTeam);
		}
		else
		{
			Send_SayText(id, id, szMessage);
		}
	} 

	// Send message to all players
	else
	{
		// Figure out if at least 1 player is connected
		// so we don't send useless message if not
		// and we gonna use that player as team reference (aka SayText message sender) for color change
		new iPlayers[32], iNum;
		get_players(iPlayers, iNum, "ch");
		if( !iNum )
		{
			return 0;
		}

		new iFool = iPlayers[0];

		new iMlNumber, i, j;
		new Array:aStoreML = ArrayCreate();
		if( iParams >= 5 ) // ML can be used
		{
			for(j=4; j<iParams; j++)
			{
				// retrieve original param value and check if it's LANG_PLAYER value
				if( getarg(j) == LANG_PLAYER )
				{
					i=0;
					// as LANG_PLAYER == -1, check if next parm string is a registered language translation
					while( ( szMessage[ i ] = getarg( j + 1, i++ ) ) ) {}
					if( GetLangTransKey(szMessage) != TransKey_Bad )
					{
						// Store that arg as LANG_PLAYER so we can alter it later
						ArrayPushCell(aStoreML, j++);

						// Update ML array saire so we'll know 1st if ML is used,
						// 2nd how many args we have to alterate
						iMlNumber++;
					}
				}
			}
		}

		// If arraysize == 0, ML is not used
		// we can only send 1 MSG_BROADCAST message
		if( !iMlNumber )
		{
			if( iParams == 3 )
			{
				copy(szMessage[1], charsmax(szMessage)-1, szMsg);
			}
			else
			{
				vformat(szMessage[1], charsmax(szMessage)-1, szMsg, 4);
			}

			if( iColor )
			{
				new szTeam[11];
				get_user_team(iFool, szTeam, charsmax(szTeam));
				Send_TeamInfo(0, iFool, g_szTeamName[iColor]);
				Send_SayText(0, iFool, szMessage);
				Send_TeamInfo(0, iFool, szTeam);
			}
			else
			{
				Send_SayText(0, iFool, szMessage);
			}
		}

		// ML is used, we need to loop through all players,
		// format text and send a MSG_ONE_UNRELIABLE SayText message
		else
		{
			new szTeam[11], szFakeTeam[10];
			
			if( iColor )
			{
				get_user_team(iFool, szTeam, charsmax(szTeam));
				copy(szFakeTeam, charsmax(szFakeTeam), g_szTeamName[iColor]);
			}

			for( i = 0; i < iNum; i++ )
			{
				id = iPlayers[i];

				for(j=0; j<iMlNumber; j++)
				{
					// Set all LANG_PLAYER args to player index ( = id )
					// so we can format the text for that specific player
					setarg(ArrayGetCell(aStoreML, j), _, id);
				}

				// format string for specific player
				vformat(szMessage[1], charsmax(szMessage)-1, szMsg, 4);

				if( iColor )
				{
					Send_TeamInfo(id, iFool, szFakeTeam);
					Send_SayText(id, iFool, szMessage);
					Send_TeamInfo(id, iFool, szTeam);
				}
				else
				{
					Send_SayText(id, iFool, szMessage);
				}
			}
			ArrayDestroy(aStoreML);
		}
	}
	return 1;
}

stock Send_TeamInfo(iReceiver, iPlayerId, szTeam[])
{
	static iTeamInfo = 0;
	if( !iTeamInfo )
	{
		iTeamInfo = get_user_msgid("TeamInfo");
	}
	message_begin(iReceiver ? MSG_ONE_UNRELIABLE : MSG_BROADCAST, iTeamInfo, .player=iReceiver);
	write_byte(iPlayerId);
	write_string(szTeam);
	message_end();
}

stock Send_SayText(iReceiver, iPlayerId, szMessage[])
{
	static iSayText = 0;
	if( !iSayText )
	{
		iSayText = get_user_msgid("SayText");
	}
	message_begin(iReceiver ? MSG_ONE_UNRELIABLE : MSG_BROADCAST, iSayText, .player=iReceiver);
	write_byte(iPlayerId);
	write_string(szMessage);
	message_end();
}

stock register_dictionary_colored(const filename[])
{
	if( !register_dictionary(filename) )
	{
		return 0;
	}

	new szFileName[256];
	get_localinfo("amxx_datadir", szFileName, charsmax(szFileName));
	format(szFileName, charsmax(szFileName), "%s/lang/%s", szFileName, filename);
	new fp = fopen(szFileName, "rt");
	if( !fp )
	{
		log_amx("Failed to open %s", szFileName);
		return 0;
	}

	new szBuffer[512], szLang[3], szKey[64], szTranslation[256], TransKey:iKey;

	while( !feof(fp) )
	{
		fgets(fp, szBuffer, charsmax(szBuffer));
		trim(szBuffer);

		if( szBuffer[0] == '[' )
		{
			strtok(szBuffer[1], szLang, charsmax(szLang), szBuffer, 1, ']');
		}
		else if( szBuffer[0] )
		{
			strbreak(szBuffer, szKey, charsmax(szKey), szTranslation, charsmax(szTranslation));
			iKey = GetLangTransKey(szKey);
			if( iKey != TransKey_Bad )
			{
				while( replace(szTranslation, charsmax(szTranslation), "!g", "^4") ){}
				while( replace(szTranslation, charsmax(szTranslation), "!t", "^3") ){}
				while( replace(szTranslation, charsmax(szTranslation), "!n", "^1") ){}
				AddTranslation(szLang, iKey, szTranslation[2]);
			}
		}
	}
	
	fclose(fp);
	return 1;
}
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1033\\ f0\\ fs16 \n\\ par }
*/
/** AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1033\\ f0\\ fs16 \n\\ par }
*/
