/* 
Plugin: SpawnProtection
Version: 1.6

Credits:
-- Hafner
-- Fedcomp
-- xPaw
-- PomanoB
-- DJ_WEST / fezh
*/

#include <amxmodx>
#include <hamsandwich>
#include <cstrike>
#include <fun>

#define PLUGIN "SpawnProtection"
#define VERSION "1.6"
#define AUTHOR "a.aqua"

new CvarTime, CvarMsg, CvarHudEffect, CvarNdmg, CvarHologram
new bool:g_bDisable[33]
new HamHook: fwd_TraceAttack

public plugin_init() {
	register_plugin (PLUGIN, VERSION, AUTHOR)
	register_dictionary ("SpawnProtection.txt")
	CvarTime	= register_cvar ( "sp_time", "10.0")
	CvarMsg		= register_cvar ( "sp_msgshow", "1")
	CvarHudEffect	= register_cvar ( "sp_msgeffect", "0")
	CvarNdmg	= register_cvar	( "sp_noattack", "1")
	CvarHologram	= register_cvar ( "sp_hologram", "1")

	RegisterHam(Ham_Spawn, "player", "SpOn", 1)
	fwd_TraceAttack = RegisterHam(Ham_TraceAttack, "player", "Forward_TraceAttack")
	DisableHamForward (fwd_TraceAttack)

	register_cvar ( "sp_version", VERSION, FCVAR_SERVER|FCVAR_SPONLY)
}

public SpOn(id) {
	new Float:iTime = get_pcvar_float(CvarTime)
	new iMsg = get_pcvar_num(CvarMsg)
	new iHlg = get_pcvar_num(CvarHologram)
	new iEffect = clamp(get_pcvar_num(CvarHudEffect), 0, 2)

	if (!iHlg) {
		new iTeam = _:cs_get_user_team(id)
		new g_colors[4][3] = {
			{0, 0, 0},
			{255, 0, 0},
			{0, 0, 255},
			{0, 0, 0}
		}
	}

	if (is_user_alive(id)) {
		EnableHamForward(fwd_TraceAttack)
		if (iMsg) {
			set_hudmessage(255, 1, 1,  0.4, 0.85, iEffect, 6.0, iTime, 0.1, 0.2, -1)
			show_hudmessage(id, "%L", id, "SP_SHWMSG", floatround(get_pcvar_float(CvarTime)))
		}

		if (iHlg) {
			set_user_rendering(id, kRenderFxDistort, 0, 0, 0, kRenderTransAdd, 127)
		} else {
			set_user_rendering(id, kRenderFxGlowShell, g_colors[iTeam][0], g_colors[iTeam][1], g_colors[iTeam][2], kRenderNormal, 10)
		}
		set_task(iTime, "SpOff", id)
		g_bDisable[id] = true
	}
}

public SpOff(id) {
	DisableHamForward(fwd_TraceAttack)
	g_bDisable[id] = false

	set_user_rendering(id)
}

public Forward_TraceAttack(id, attacker, Float:dmg, Float:dir[3], tr, dmgbit) {
	new iNoAttack = get_pcvar_num(CvarNdmg)

	if(g_bDisable[attacker] && iNoAttack || g_bDisable[id] && id != attacker) {
			if(get_user_weapon(attacker) == CSW_KNIFE) {
				return HAM_IGNORED
			}
			return HAM_SUPERCEDE
	}
	
	return HAM_IGNORED
}

/* WHY DO YOU HATE? DOCMOT? BAØ DPYÃ */