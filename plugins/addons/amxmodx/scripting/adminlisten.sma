//ported by Oj@eKiLLzZz
// *******************************************************************************
// Admin Listen 2.3x, Also Copyright 2004, /dev/ urandom. No Warranties, 
// either expressed or implied.
// Props to Maxim for the remake of Luke Sankeys original plugin.
// Props to Luke Sankey for the original AdminMod plugin (SankListen).
// Inspired by PsychoListen by PsychoGuard
//
// Allows administrators (with flag "n") to see all team chats, and dead chats.
//
// Use amx_adminlisten_voice 0|1 to turn off and on the hearing of voicecomms

// In 2.0 the Chat Engine was totally rewritten from ground up,
// a different, more efficent method, was used to pick up say messages,
// also fewer calculations and variables in this version.
//
// 2.1 - VoiceComm rewrite, fixed a few typos in the comments.
//
// 2.2 - Updated for Condition Zero 1.2, Note that while I've attempted to keep
//       backwards compatability with other mods, I cannot vouch for it working
//       in other mods as I only have a CS:CZ server to test it in.
//
// 2.3 - Updated to work with Counter-Strike after steams update June 14, 2004.
// *******************************************************************************


#include <amxmodx>
#include <amxmisc>
#include <engine>

// Counter for the SayText event.
new count[32][32]     
new g_voice_status[2]

public catch_say(id)
{
	new reciever = read_data(0) //Reads the ID of the message recipient
	new sender = read_data(1)   //Reads the ID of the sender of the message
	new message[151]            //Variable for the message
	new channel[151]
	new sender_name[32]

	if (is_running("czero")||is_running("cstrike"))
	{
   		read_data(2,channel,150)
	   	read_data(4,message,150)
   		get_user_name(sender, sender_name, 31)
	} else {
	        read_data(2,message,150)
	}
   
	// DEBUG. 
	// console_print(0, "DEBUG MESSAGE: %s", message)
	// console_print(0, "DEBUG channel: %s", channel)
	// console_print(0, "DEBUG sender: %s, %i", sender_name, sender)
	// console_print(0, "DEBUG receiver: %i", reciever)
   
   	//With the SayText event, the message is sent to the person who sent it last.
   	//It's sent to everyone else before the sender recieves it.

	// Keeps count of who recieved the message
   	count[sender][reciever] = 1          
	// If current SayText message is the last then...
   	if (sender == reciever)
	{      
      		new player_count = get_playersnum()  //Gets the number of players on the server
      		new players[32] //Player IDs
      		get_players(players, player_count, "c")

      		for (new i = 0; i < player_count; i++) 
		{
			// If the player is an admin...
         		if (get_user_flags(players[i]) & ADMIN_LEVEL_B)
			{     
				// If the player did not recieve the message then...
            			if (count[sender][players[i]] != 1)
				{              
               				message_begin(MSG_ONE, get_user_msgid("SayText"),{0,0,0},players[i])
               				// Appends the ID of the sender to the message, so the engine knows what color to make the name.
               				write_byte(sender)
               				// Appends the message to the message (depending on the mod).
					if (is_running("czero")||is_running("cstrike"))
	       				{
   						write_string(channel)
	       					write_string(sender_name)
	       				}
               				write_string(message)
               				message_end()
            			}
         		}
         		count[sender][players[i]] = 0  //Set everyone's counter to 0 so it's ready for the next SayText
      		}
   	}
	
   	return PLUGIN_CONTINUE
}

public plugin_init(){
   register_plugin("AdminListen","2.3x","/dev/ urandom")
   register_srvcmd("amx_adminlisten_voice","voice_status")
   register_event("SayText","catch_say","b")
   return PLUGIN_CONTINUE
}

public plugin_modules(){
   require_module("engine") 
}

// *********************
// VoiceComm Stuff
// *********************

public client_infochanged(id)
{
   if ((get_user_flags(id) & ADMIN_LEVEL_B) && equal(g_voice_status,"1")) set_speak(id, 4)
}

public client_connect(id)
{
   if ((get_user_flags(id) & ADMIN_LEVEL_B) && equal(g_voice_status,"1")) set_speak(id, 4)
}

public voice_status(){
   read_argv(1,g_voice_status,1)
   new player_count = get_playersnum()
   new players[32] //Player IDs
   get_players(players, player_count, "c")
   for (new i = 0; i < player_count; i++) {
      if ((get_user_flags(players[i]) & ADMIN_LEVEL_B)){         
         if (equal(g_voice_status,"0")) set_speak(players[i], 0)
         if (equal(g_voice_status,"1")) set_speak(players[i], 4)
      }
   }
}
