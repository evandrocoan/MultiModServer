#if defined _zp50_log_included
	#endinput
#endif
#define _zp50_log_included

/**
 * This is used to log ZP-specific information/errors into a
 * location where it is separate from other messages.
 **/
stock zp_log(const message_fmt[], any:...)
{
	static message[256], filename[32], date[16];
	vformat(message, charsmax(message), message_fmt, 2);
	format_time(date, charsmax(date), "%Y%m%d");
	formatex(filename, charsmax(filename), "ZombiePlague_%s.log", date);
	log_to_file(filename, "%s", message);
}
/** AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1033\\ f0\\ fs16 \n\\ par }
*/
