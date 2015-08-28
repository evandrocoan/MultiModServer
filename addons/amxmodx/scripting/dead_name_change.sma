/* AMX Mod X
*   Dead Name Change
*
* (c) Copyright 2007 by VEN
*
* This file is provided as is (no warranties)
*
*     DESCRIPTION
*       Plugin allow to a players change their names while not alive.
*       By default the plugin will work for anyone on the server.
*       Via CVars you can configure access level flags, disable text
*       "* NAME1 changed name to NAME2" and also disable the plugin.
*
*     CVARs
*       dnc_enable (0: OFF, 1: ON, default: 1) - controls plugin state
*       dnc_access (access level flags, default: "") - allowed access level flags
*       dnc_announce (0: OFF, 1: ON, default: 1) - controls announce text state
*
*     CREDITS
*       L3X - initial idea
*/

#include <amxmodx>
#include <fakemeta>

// plugin's main information
#define PLUGIN_NAME "Dead Name Change"
#define PLUGIN_VERSION "0.1"
#define PLUGIN_AUTHOR "VEN"

// CVars names
#define CVAR_NAME_ENABLE "dnc_enable"
#define CVAR_NAME_ACCESS "dnc_access"
#define CVAR_NAME_ANNOUNCE "dnc_announce"

// CVars default values
#define CVAR_DVAL_ENABLE "1"
#define CVAR_DVAL_ACCESS ""
#define CVAR_DVAL_ANNOUNCE "1"

new const g_name[] = "name"
new /* const */ g_name_change[] = "#Cstrike_Name_Change"

new g_pcvar_enable
new g_pcvar_access
new g_pcvar_announce

new g_msgid_saytext

public plugin_init() {
	register_plugin(PLUGIN_NAME, PLUGIN_VERSION, PLUGIN_AUTHOR)

	g_pcvar_enable = register_cvar(CVAR_NAME_ENABLE, CVAR_DVAL_ENABLE)
	g_pcvar_access = register_cvar(CVAR_NAME_ACCESS, CVAR_DVAL_ACCESS)
	g_pcvar_announce = register_cvar(CVAR_NAME_ANNOUNCE, CVAR_DVAL_ANNOUNCE)

	register_forward(FM_ClientUserInfoChanged, "forward_client_userinfochanged")

	g_msgid_saytext = get_user_msgid("SayText")
}

public forward_client_userinfochanged(id, buffer) {
	if (!get_pcvar_num(g_pcvar_enable) || !is_user_connected(id) || is_user_alive(id))
		return FMRES_IGNORED

	static oldname[32], newname[32]
	get_user_name(id, oldname, sizeof oldname - 1)
	engfunc(EngFunc_InfoKeyValue, buffer, g_name, newname, sizeof newname - 1)
	if (equal(newname, oldname))
		return FMRES_IGNORED

	static iflags, szflags[28]
	get_pcvar_string(g_pcvar_access, szflags, sizeof szflags - 1)
	iflags = read_flags(szflags)
	if (iflags != ADMIN_ALL && !(get_user_flags(id) & iflags))
		return FMRES_IGNORED

	if (get_pcvar_num(g_pcvar_announce))
		msg_name_change(id, oldname, newname)

	return FMRES_SUPERCEDE
}

msg_name_change(id, /* const */ oldname[], /* const */ newname[]) {
	message_begin(MSG_BROADCAST, g_msgid_saytext)
	write_byte(id)
	write_string(g_name_change)
	write_string(oldname)
	write_string(newname)
	message_end()
}
