/* Amx Mod X script.
*   Anti Noob Plugin
*
* by Emilioneri
*
* This file is provided as is (without warranties)
*
* Description:
* This plugin will kick/ban/redirect noobs, or increase noobs' hp and ap (controlled by cvar amx_punishnoob).
*
* Cvars:
* amx_antinoob ------- max number of "deaths - frags" of player to get kicked/banned/redirected or to increase hp and ap. (default 15)
* amx_punishnoob ----- 0 - disabled. 1 - kick. 2 - ban. 3 - redirect. 4 - Increase their hp and ap (default 1)
* amx_noobbantype ---- 1 - ban by steamid. 2 - ban by IP (default 1)
* amx_noobbantime ---- how many minutes noob will be banned if cvar amx_punishnoob is set to 2 (default 5)
* amx_noobredirectip - where noob will be redirected if cvar amx_punishnoop is set to 3 (default 127.0.0.1:27015)
* amx_noobhp --------- How much hp an ap noob will recieve if amx_punishnoob is set to 4 (default 200)
*
* F.A.Q.
* Q) How it will detect noobs?
* A) It checks users' frags each time they spawn (so you can use it with csdm also ^^)
*    and if their "deaths - frags" is more than number set by cvar amx_antinoob, they will be kicked/banned/redirected.
*    or their hp and ap will be increased (if amx_punishnoob is set to 4).
*
* Q) Do I need to be a big asshole to use this plugin?
* A) No. Who cares about noobs? If you do, set cvar amx_punishnoob to 4 ;)
*
* Q) What if someone will die 15 times in a row to get higher hp and ap?
* A) O_O
*
* Changelog
* Version 1.3 - 19 November, 2009
* Added: cvar amx_noobbantype (ban by steamid or ip)
* Added: third option for cvar amx_punishnoob which redirects noobs
* Added: fourth option for cvar amx_punishnoob which increases noobs' hp and ap
*
* Version 1.0 - 20 September, 2009
* First Public Realise
*
* Credits
* Valve --------- No game, no Amx Mod X. Thanks theese guys for realising this game
* AMXX Dev Team - No Amx Mod X, no plugins. Thanks for realising Amx Mod X and AMXX-Studio
* Emilioneri ---- Plugin Author; English translation
* You ----------- Thanks for using this plugin
*
*          Made in Georgia
*              © 2009
*/

#include <amxmodx>
#include <amxmisc>
#include <hamsandwich>
#include <fun>

#define PLUGIN "Anti n00b"
#define VERSION "1.3"
#define AUTHOR "Emilioneri"

new g_Cvar
new g_Type
new g_Time
new g_Ip
new g_Bantype
new g_HpAp


public plugin_init() {
	register_plugin(PLUGIN, VERSION, AUTHOR)
	register_cvar("antinoob_version", VERSION, FCVAR_SERVER | FCVAR_SPONLY)
	register_cvar("antinoob_author", AUTHOR, FCVAR_SERVER | FCVAR_SPONLY)
	
	RegisterHam( Ham_Spawn, "player", "FwdHamPlayerSpawn", 1)
	g_Cvar = register_cvar("amx_antinoob", "15")
	g_Type = register_cvar("amx_punishnoob", "1")
	g_Time = register_cvar("amx_noobbantime", "5")
	g_Ip = register_cvar("amx_noobredirectip", "127.0.0.1:27015")
	g_Bantype = register_cvar("amx_noobbantype", "1")
	g_HpAp = register_cvar("amx_noobhp", "200")
	
	register_dictionary("anti_noob.txt")
}

public FwdHamPlayerSpawn(id)
{
	new iFrags = get_user_deaths(id) - get_user_frags(id)
	new iCvar = get_pcvar_num(g_Cvar)
	new iType = get_pcvar_num(g_Type)
	new iTime = get_pcvar_num(g_Time)
	new iBantype = get_pcvar_num(g_Bantype)
	new iHpAp = get_pcvar_num(g_HpAp)
	new iIp[32]
	get_pcvar_string(g_Ip, iIp, 31)
	
	if (iFrags >= iCvar)
	{
		if (iType == 1)
		{
			new iUserid = get_user_userid(id)
			new name[32]
			get_user_name(id, name, 31)
			server_cmd("kick #%d ^"%L^"", iUserid, LANG_PLAYER, "TOO_NOOB")
			client_print(0, print_chat, "%L", LANG_PLAYER, "NOOB_KICKED", name)
			return HAM_IGNORED
		}
		if (iType == 2)
		{
			if (iBantype == 1)
			{
				new iUserid = get_user_userid(id)
				new authid[32]
				new name[32]
				get_user_name(id, name, 31)
				get_user_authid(id, authid, 31)
				server_cmd("kick #%d ^"%L^"; wait; banid ^"%d^" ^"%s^"; wait; writeid", iUserid, LANG_PLAYER, "TOO_NOOB", iTime, authid) /* ban noob by steamid */
				client_print(0, print_chat, "%L", LANG_PLAYER, "NOOB_BANNED", name, iTime)
				return HAM_IGNORED
			}
			if (iBantype == 2)
			{
				new iUserid = get_user_userid(id)
				new ip[32]
				new name[32]
				get_user_name(id, name, 31)
				get_user_ip(id, ip, 31)
				server_cmd("kick #%d ^"%L^"; wait; addip ^"%d^" ^"%s^"; wait; writeip", iUserid, LANG_PLAYER, "TOO_NOOB", iTime, ip) /* ban noob by ip */
				client_print(0, print_chat, "%L", LANG_PLAYER, "NOOB_BANNED", name, iTime)
				return HAM_IGNORED
			}
		}
		if (iType == 3)
		{
			client_cmd(id, "connect %s", iIp) /* redirect noob */
			return HAM_IGNORED
		}
		if (iType == 4)
		{
			set_user_armor(id, iHpAp) /* increase noob's armor */
			set_user_health(id, iHpAp) /* increase noob's health */
			return HAM_IGNORED
		}
	}
	return HAM_IGNORED
}
