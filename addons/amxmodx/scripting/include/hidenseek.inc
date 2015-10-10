#if defined _hidenseek_included
	#endinput
#endif

#define _hidenseek_included

#if AMXX_VERSION_NUM >= 175
	#pragma reqlib "hidenseek"
	#if !defined AMXMODX_NOAUTOLOAD
		#pragma loadlib "hidenseek"
	#endif
#else
	#pragma library "hidenseek"
#endif

native bool:hns_get_status();
native bool:hnss_get_status();
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1033\\ f0\\ fs16 \n\\ par }
*/
