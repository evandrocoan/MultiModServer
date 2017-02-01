/*
* AMX Mod X Script
* This file is provided	as is (no warranties).
*
* AutoLang v1.5.02
* 5/3/06
* This script will set the client's personal language during game connect according to they're country.
* GEOIP module required.
*
*/

#include <amxmodx>
#include <geoip>

//MAX Size for each language array
#define MAX_EN 39
#define MAX_DE 3
#define MAX_FR 25
#define MAX_NL 2
#define MAX_SP 20

new playerip[17]
new ccode[3]
new lang[33]
new geoip_check[3]

//Country array info for each language
new lang_sp[MAX_SP][] = {"ES", "AR", "BO", "CL", "CO", "CR", "CU", "DO", "EC", "SV", "GQ", "GT", "HN", "MX", "NI", "PA", "PY", "PE", "UY", "VE"}
new lang_en[MAX_EN][] = {"US", "GB", "AG", "AU", "BS", "BB", "BZ", "BW", "CA", "DM", "GM", "GH", "GD", "GY", "JM", "LR", "MW", "MH", "MR", "FM",
			 "NZ", "NG", "PG", "SL", "SB", "KN", "LC", "VC", "TT", "ZM", "ZW", "VI", "VG", "UM", "NF", "MS", "KY", "IO", "GI"}
new lang_de[MAX_DE][] = {"DE", "AT", "LI"}
new lang_fr[MAX_FR][] = {"FR", "BJ", "BF", "CD", "CF", "CI", "GA", "GN", "ML", "MC", "NE", "SN", "TG", "ZR", "MQ", "GP", "RE", "GY", "PF", "PM",
			 "NC", "WF", "YT", "TF", "GF"}
new lang_nl[MAX_NL][] = {"NL", "SR"}

public plugin_init()
{
	register_plugin("Auto Set Langauge", "1.7", "FALUCO/teame06")
}

public client_connect(id)
{
	lang[id] = 0
}

public client_putinserver(id)
{
	if (!is_user_bot(id))
	{
		set_task(0.1, "disp_Info", id)
	}
}

public client_disconnect(id)
{
	remove_task(id)
	lang[id] = 0
}

public disp_Info(id)
{
	if (is_user_bot(id))
		return PLUGIN_CONTINUE

	new i
	get_user_info(id, "lang", geoip_check, 2)
	lang[id] = str_to_num(geoip_check)
	get_user_ip(id, playerip, 16, 1)
	geoip_code2(playerip, ccode)
	
	if (!equali(lang[id], ccode))
	{
		if (equali(ccode, "err"))
		{
			set_user_info(id, "lang", "en")
			return PLUGIN_CONTINUE
		}
		
		if (equali(ccode, "SE"))
		{
			set_user_info(id, "lang", "sv")
			return PLUGIN_CONTINUE
		}
		
		if (equali(ccode, "DK"))
		{
			set_user_info(id, "lang", "da")
			return PLUGIN_CONTINUE
		}
		
		if (equali(ccode, "PL"))
		{
			set_user_info(id, "lang", "pl")
			return PLUGIN_CONTINUE
		}
		
		if (equali(ccode, "TR"))
		{
			set_user_info(id, "lang", "tr")
			return PLUGIN_CONTINUE
		}
		
		if (equali(ccode, "BR"))
		{
			set_user_info(id, "lang", "bp")
			return PLUGIN_CONTINUE
		}
		
		if (equali(ccode, "CZ"))
		{
			set_user_info(id, "lang", "cz")
			return PLUGIN_CONTINUE
		}

		if (equali(ccode, "FI"))
		{
			set_user_info(id, "lang", "fi")
			return PLUGIN_CONTINUE
		}
		
		for (i = 0; i < MAX_NL; ++i)
		{
			if (equali(lang_nl[i], ccode))
			{
        			set_user_info(id, "lang", "nl")
				return PLUGIN_CONTINUE
			}
		}

		for (i = 0; i < MAX_DE; ++i)
		{
			if (equali(lang_de[i], ccode))
			{
       				set_user_info(id, "lang", "de")
				return PLUGIN_CONTINUE
			}
		}

		for (i = 0; i < MAX_EN; ++i)
		{
			if (equali(lang_en[i], ccode))
			{
       				set_user_info(id, "lang", "en")
				return PLUGIN_CONTINUE
			}
		}

		for (i = 0; i < MAX_FR; ++i)
		{
			if (equali(lang_fr[i], ccode))
			{
       				set_user_info(id, "lang", "fr")
				return PLUGIN_CONTINUE
			}
		}
			
		for (i = 0; i < MAX_SP; ++i)
		{
			if (equali(lang_sp[i], ccode))
			{
       				set_user_info(id, "lang", "es")
				return PLUGIN_CONTINUE
			}
		}

		set_user_info(id, "lang", "en")
	}
	
	return PLUGIN_CONTINUE
}
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1046\\ f0\\ fs16 \n\\ par }
*/
