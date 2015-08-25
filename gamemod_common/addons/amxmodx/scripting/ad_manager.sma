#include <amxmodx>
#include <amxmisc>

#pragma semicolon 1

new const PLUGIN[] = "Autoresponder/Advertiser";
new const VERSION[] = "0.5";
new const AUTHOR[] = "MaximusBrood";

#define NORM_AD 0
#define SAY_AD 1

#define COND 0
#define STORE 1

#define COND_TKN '%'
#define SAY_TKN '@'

#define COND_STKN "%"
#define DEVIDE_STKN "~"
#define SAY_STKN "@"

//-.-.-.-.-.-.-.-.DEFINES.-.-.-.-.-.-.-.-.-.-.

//Maximum amount of ads
#define MAXADS 64

//Minimum difference between two different ads (float)
new const Float:RAND_MIN = 360.0;

//Maximum difference between two different ads (float)
new const Float:RAND_MAX = 360.0;

//-.-.-.-.-.-.-.-.END DEFINES..-.-.-.-.-.-.-.

//Stores
new sayConditions[MAXADS][3][32];
new normConditions[MAXADS][3][32];
new normStore[MAXADS][128];
new sayStore[MAXADS][2][128];

new gmsgSayText;

//Counters
new adCount[2] = {0, 0};

public plugin_init() {
	register_plugin(PLUGIN, VERSION, AUTHOR);
	
	register_cvar("ad_react_all", "1");
	
	gmsgSayText = get_user_msgid("SayText");
	
	register_clcmd("say","eventSay");
	register_clcmd("say_team","eventSay");
	
	//Delay the load proces by 10 sec because we don't want to get more load
	//on the already high-load mapchange.
	//Too soon to affect players while playing, too late to create time-out @ mapchange
	set_task(10.0, "load");
}

public load()
{
	//Load the data
	new filepath[64];
	get_configsdir(filepath, 63);
	format(filepath, 63, "%s/advertisements.ini", filepath);
	
	if(file_exists(filepath))
	{
		new output[512], conditions[128], temp[64], type;
		
		//Open file
		new fHandle = fopen(filepath, "rt");
		
		//Checks for failure
		if(!fHandle)
			return;
		
		//Loop through all lines
		for(new a = 0; a < MAXADS && !feof(fHandle); a++)
		{
			//Get line
			fgets(fHandle, output, 511);
			
			
			//Work away comments
			if(output[0] == ';' || !output[0] || output[0] == ' ' || output[0] == 10) 
			{
				//Line is not counted
				a--;
				continue;
			}
			
			//Reset type
			type = 0;
			
			//Check if it contains conditions
			if(output[0] == COND_TKN)
			{
				//Cut the conditions off the string
				split(output, conditions, 127, output, 511, DEVIDE_STKN);
				
				//Determine if its say check or normal ad
				type = output[0] == SAY_TKN ? 1 : 0;
				
				//Put the conditions in own space
				for(new b = 0; b < 3; b++)
				{
					new sort[16], cond[32], numb;
					
					//Remove the % from line 
					conditions[0] = ' ';
					trim(conditions);
					
					//Get one condition from the line
					split(conditions, temp, 64, conditions, 127, COND_STKN);
					
					split(temp, sort, 15, cond, 31, " ");
					
					if(equali(sort, "map"))
					{
						numb = 0;
					} else if(equali(sort, "min_players"))
					{
						numb = 1;
					} else if(equali(sort, "max_players"))
					{
						numb = 2;
					} else
					{
						continue;
					}
					
					//Copy it to its final resting place ^^
					setString(COND, type, cond, adCount[type], numb);
					
					//Exit if it hasn't got more conditions
					if(!conditions[0])
						break;
				}
			}
			
			if(type == 0)
				type = output[0] == SAY_TKN ? 1 : 0;
			
			if(type == SAY_AD)
			{
				new said[32], answer[128];
				
				//Remove the @ from line
				output[0] = ' ';
				trim(output);
				
				split(output, said, 31, answer, 127, DEVIDE_STKN);
				
				//Apply color
				setColor(answer, 127);
				
				//Save it
				setString(STORE, SAY_AD, said, adCount[SAY_AD], 0);
				setString(STORE, SAY_AD, answer, adCount[SAY_AD], 1);
			} else//if(type == NORM_AD)
			{
				//Apply color
				setColor(output, 511);
				
				//Save it
				setString(STORE, NORM_AD, output, adCount[NORM_AD]);
			}
			
			//Increment the right counter
			adCount[NORM_AD] += type == NORM_AD ? 1 : 0;
			adCount[SAY_AD]  += type == SAY_AD  ? 1 : 0;
		}
		
		//Set a first task, if there are any normal ads
		if(adCount[NORM_AD] != 0)
			set_task(random_float(RAND_MIN, RAND_MAX), "eventTask");
		
		//Close file to prevent lockup
		fclose(fHandle);	
	}
}

new currAd = -1;

public eventTask()
{
	//Go past all ads and check conditions
	for(new a = 0; a < adCount[NORM_AD]; a++)
	{
		//Put current ad to the next one
		currAd = currAd == adCount[NORM_AD] - 1 ? 0 : currAd + 1;
		
		if(checkConditions(currAd, NORM_AD))
		{
			//Display the ad
			new data[3];
			data[0] = currAd;
			data[1] = NORM_AD;
			data[2] = 0;
			displayAd(data);
			
			break;
		}
	}
		
	//Set a new task
	set_task(random_float(RAND_MIN, RAND_MAX), "eventTask");
	
	return PLUGIN_CONTINUE;
}

public eventSay(id)
{
	//If nothing is said, don't check
	if(adCount[SAY_AD] == 0)
		return PLUGIN_CONTINUE;
	
	new talk[64], keyword[16];
	read_args(talk, 63) ;
		
	//En nu rennen voor jullie zakgeld klootzjakken!
	for(new a = 0; a < adCount[SAY_AD]; a++)
	{
		//Get the string
		getString(STORE, SAY_AD, keyword, 15, a, 0);
		
		if(containi(talk, keyword) != -1)
		{
			//Check the rest if it fails to conditions
			if(!checkConditions(a, SAY_AD))
				continue;
			
			new data[3];
			data[0] = a;
			data[1] = SAY_AD;
			data[2] = id;
			
			//Set the task
			set_task(0.3, "displayAd", 0, data, 3);
			
			//Don't execute more of them
			break;
		}
	}
	
	return PLUGIN_CONTINUE;
}

public displayAd(params[])
{
	//Get the string that is going to be displayed
	new message[128];
	getString(STORE, params[1], message, 127, params[0], params[1]);
	
	//If its enabled by cvar and id is set, display to person who triggered message only
	if(get_cvar_num("ad_react_all") == 0 && params[2] != 0)
	{
		message_begin(MSG_ONE, gmsgSayText, {0,0,0}, params[2]);
		write_byte(params[2]);
		write_string(message);
		message_end();
	
	} else
	{
		//Display the message to everyone
		new plist[32], playernum, player;
		
		get_players(plist, playernum, "c");
	
		for(new i = 0; i < playernum; i++)
		{
			player = plist[i];
			
			message_begin(MSG_ONE, gmsgSayText, {0,0,0}, player);
			write_byte(player);
			write_string(message);
			message_end();
		}
	}
	
	return PLUGIN_HANDLED;
}

//---------------------------------------------------------------------------
//                                STOCKS
//---------------------------------------------------------------------------

stock checkConditions(a, type)
{
	//Mapname
	if((type == NORM_AD && normConditions[a][0][0]) || (type == SAY_AD && sayConditions[a][0][0]))
	{
		new mapname[32];
		get_mapname(mapname, 31);
		
		if(! (type == NORM_AD && equali(mapname, normConditions[a][0]) ) || (type == SAY_AD && equali(mapname, sayConditions[a][0]) ) )
			return false;
	}
	
	//Min Players
	if((type == NORM_AD && normConditions[a][1][0]) || (type == SAY_AD && sayConditions[a][1][0]))
	{
		new playersnum = get_playersnum();
		
		if( (type == NORM_AD && playersnum < str_to_num(normConditions[a][1]) ) || (type == SAY_AD && playersnum < str_to_num(sayConditions[a][1]) ) )
			return false;
	}
	
	//Max Players
	if((type == NORM_AD && normConditions[a][2][0]) || (type == SAY_AD && sayConditions[a][2][0]))
	{
		new playersnum = get_playersnum();
		
		if( (type == NORM_AD && playersnum > str_to_num(normConditions[a][2]) ) || (type == SAY_AD && playersnum > str_to_num(sayConditions[a][2]) ) )
			return false;
	}
	
	//If everything went fine, return true
	return true;
}	

stock setColor(string[], len)
{
	if (contain(string, "!t") != -1 || contain(string, "!g") != -1 || contain(string,"!n") != -1)
	{
		//Some nice shiny colors ^^
		replace_all(string, len, "!t", "^x03");
		replace_all(string, len, "!n", "^x01");
		replace_all(string, len, "!g", "^x04");
		
		//Work away a stupid bug
		format(string, len, "^x01%s", string);
	}
}

stock getString(mode, type, string[], len, one, two = 0)
{
	//server_print("mode: %d type: %d len: %d one: %d two %d", mode, type, len, one, two);
	
	//Uses the fact that a string is passed by reference
	if(mode == COND)
	{
		if(type == NORM_AD)
		{
			copy(string, len, normConditions[one][two]);
		} else//if(type = SAY_AD)
		{
			copy(string, len, sayConditions[one][two]);
		}
	} else//if(mode == STORE)
	{
		if(type == NORM_AD)
		{
			copy(string, len, normStore[one]);
		} else//if(type == SAY_AD)
		{
			copy(string, len, sayStore[one][two]);
		}
	}
}

stock setString(mode, type, string[], one, two = 0)
{
	if(mode == COND)
	{
		if(type == NORM_AD)
		{
			copy(normConditions[one][two], 31, string);
		} else//if(type = SAY_AD)
		{
			copy(sayConditions[one][two], 31, string);
		}
	} else//if(mode == STORE)
	{
		if(type == NORM_AD)
		{
			copy(normStore[one], 127, string);
		} else//if(type == SAY_AD)
		{
			copy(sayStore[one][two], 127, string);
		}
	}
}