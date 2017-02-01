#if defined _zp50_colorchat_included
  #endinput
#endif
#define _zp50_colorchat_included

#include <zp50_colorchat_const>

// --------------
// Example usage:
// --------------
// zp_colored_print(id, "Class: %L", id, "CLASS_HUMAN")
// zp_colored_print(0, "Class: %L", LANG_PLAYER, "CLASS_HUMAN")
// ----------------------------------------------------------------------------

// Prints a colored message to target (use 0 for everyone), supports ML formatting.
// - Supports passing -1 as an argument (ZP 4.3 stock had a bug with that)
// - Does not support blue/red/gray colors
stock zp_colored_print(target, const message[], any:...)
{
	static buffer[512], msg_SayText = 0
	if( !msg_SayText ) msg_SayText = get_user_msgid("SayText")
	
	// Send to everyone
	if (!target)
	{
		static player, maxplayers, argscount
		maxplayers = get_maxplayers()
		argscount = numargs()
		
		for (player = 1; player <= maxplayers; player++)
		{
			// Not connected
			if (!is_user_connected(player))
				continue;
			
			// Remember changed arguments
			static arg_index, changed_args[20], changedcount // [20] = max LANG_PLAYER occurencies	
			changedcount = 0
			
			// Replace LANG_PLAYER with player id
			for (arg_index = 2; arg_index < argscount; arg_index++)
			{
				if (getarg(arg_index) == LANG_PLAYER && arg_index + 1 < argscount)
				{
					// Check if next param string is a registered language translation
					static lang_key[64], arg_subindex
					arg_subindex = 0
					while ((lang_key[arg_subindex] = getarg(arg_index + 1, arg_subindex++))) { /* keep looping */ }
					if (GetLangTransKey(lang_key) != TransKey_Bad)
					{
						setarg(arg_index, 0, player)
						changed_args[changedcount++] = arg_index
						arg_index++ // skip next argument since we know it's a translation key
					}
				}
			}
			
			// Format message for player (+add ZP prefix)
			vformat(buffer, charsmax(buffer), message, 3)
			format(buffer, charsmax(buffer), "%s%s", ZP_PREFIX, buffer)
			
			// Send it
			message_begin(MSG_ONE_UNRELIABLE, msg_SayText, _, player)
			write_byte(player)
			write_string(buffer)
			message_end()
			
			// Replace back player id's with LANG_PLAYER
			for (arg_index = 0; arg_index < changedcount; arg_index++)
				setarg(changed_args[arg_index], 0, LANG_PLAYER)
		}
	}
	// Send to specific target
	else
	{
		// Format message for player (+add ZP prefix)
		vformat(buffer, charsmax(buffer), message, 3)
		format(buffer, charsmax(buffer), "%s%s", ZP_PREFIX, buffer)
		
		// Send it
		message_begin(MSG_ONE, msg_SayText, _, target)
		write_byte(target)
		write_string(buffer)
		message_end()
	}
}