/**
 * csdm_misc.sma
 * Allows for Counter-Strike to be played as DeathMatch.
 *
 * CSDM Miscellanious Settings
 *
 * By Freecode and BAILOPAN
 * (C)2003-2006 David "BAILOPAN" Anderson
 *
 *  Give credit where due.
 *  Share the source - it sets you free
 *  http://www.opensource.org/
 *  http://www.gnu.org/
 */
 
#include <amxmodx>
#include <amxmisc>
#include <cstrike>
#include <fakemeta>
#include <csdm>

#define MAPSTRIP_BOMB		(1<<0)
#define MAPSTRIP_VIP		(1<<1)
#define MAPSTRIP_HOSTAGE	(1<<2)
#define MAPSTRIP_BUY		(1<<3)

new bool:g_BlockBuy = true
new bool:g_AmmoRefill = true
new bool:g_RadioMsg = false

#define MAXMENUPOS 34

new g_Aliases[MAXMENUPOS][] = {"usp","glock","deagle","p228","elites","fn57","m3","xm1014","mp5","tmp","p90","mac10","ump45","ak47","galil","famas","sg552","m4a1","aug","scout","awp","g3sg1","sg550","m249","vest","vesthelm","flash","hegren","sgren","defuser","nvgs","shield","primammo","secammo"} 
new g_Aliases2[MAXMENUPOS][] = {"km45","9x19mm","nighthawk","228compact","elites","fiveseven","12gauge","autoshotgun","smg","mp","c90","mac10","ump45","cv47","defender","clarion","krieg552","m4a1","bullpup","scout","magnum","d3au1","krieg550","m249","vest","vesthelm","flash","hegren","sgren","defuser","nvgs","shield","primammo","secammo"}

//Tampering with the author and name lines can violate the copyright
new PLUGINNAME[] = "CSDM Misc"
new VERSION[] = CSDM_VERSION
new AUTHORS[] = "CSDM Team"

new g_MapStripFlags = 0

public csdm_Init(const version[])
{
	if (version[0] == 0)
	{
		set_fail_state("CSDM failed to load.")
		return
	}
}

public csdm_CfgInit()
{
	csdm_reg_cfg("misc", "read_cfg")
}

public plugin_init()
{
	register_plugin(PLUGINNAME, VERSION, AUTHORS);
	register_event("CurWeapon", "hook_CurWeapon", "be", "1=1")
	
	register_clcmd("buy", "generic_block")
	register_clcmd("buyammo1", "generic_block")
	register_clcmd("buyammo2", "generic_block")
	register_clcmd("buyequip", "generic_block")
	register_clcmd("cl_autobuy", "generic_block")
	register_clcmd("cl_rebuy", "generic_block")
	register_clcmd("cl_setautobuy", "generic_block")
	register_clcmd("cl_setrebuy", "generic_block")
	
	register_concmd("csdm_pvlist", "pvlist")
	
	set_task(2.0, "DoMapStrips")
}

public plugin_precache()
{
	precache_sound("radio/locknload.wav")
	precache_sound("radio/letsgo.wav")
	
	register_forward(FM_Spawn, "OnEntSpawn")
}

public OnEntSpawn(ent)
{
	if (g_MapStripFlags & MAPSTRIP_HOSTAGE)
	{
		new classname[32]
		
		pev(ent, pev_classname, classname, 31)
		
		if (equal(classname, "hostage_entity"))
		{
			engfunc(EngFunc_RemoveEntity, ent)
			return FMRES_SUPERCEDE
		}
	}
	
	return FMRES_IGNORED
}

public pvlist(id, level, cid)
{
	new players[32], num, pv, name[32]
	get_players(players, num)
	
	for (new i=0; i<num; i++)
	{
		pv = players[i]
		get_user_name(pv, name, 31)
		console_print(id, "[CSDM] Player %s flags: %d deadflags: %d", name, pev(pv, pev_flags), pev(pv, pev_deadflag))
	}
	
	return PLUGIN_HANDLED
}

public generic_block(id, level, cid)
{
	if (csdm_active())
		return PLUGIN_HANDLED
		
	return PLUGIN_CONTINUE
}

public csdm_PostSpawn(player, bool:fake)
{
	if (g_RadioMsg && !is_user_bot(player))
	{
		if (get_user_team(player) == _TEAM_T)
		{
			client_cmd(player, "spk radio/letsgo")
		} else {
			client_cmd(player, "spk radio/locknload")
		}
	}
}

public client_command(id)
{
	if (csdm_active() && g_BlockBuy)
	{
		new arg[13]
		if (read_argv(0, arg, 12) > 11)
		{
			return PLUGIN_CONTINUE 
		}
		new a = 0 
		do {
			if (equali(g_Aliases[a], arg) || equali(g_Aliases2[a], arg))
			{ 
				return PLUGIN_HANDLED 
			}
		} while(++a < MAXMENUPOS)
	}
	
	return PLUGIN_CONTINUE 
} 

public hook_CurWeapon(id)
{
	if (!g_AmmoRefill || !csdm_active())
	{
		return
	}
	
	new wp = read_data(2)
	
	if (g_WeaponSlots[wp] == SLOT_PRIMARY || g_WeaponSlots[wp] == SLOT_SECONDARY)
	{
		new ammo = cs_get_user_bpammo(id, wp)
		
		if (ammo < g_MaxBPAmmo[wp])
		{
			cs_set_user_bpammo(id, wp, g_MaxBPAmmo[wp])
		}
	}
}

public DoMapStrips()
{
	if (g_MapStripFlags & MAPSTRIP_BOMB)
	{
		RemoveEntityAll("func_bomb_target")
		RemoveEntityAll("info_bomb_target")
	}
	if (g_MapStripFlags & MAPSTRIP_VIP)
	{
		RemoveEntityAll("func_vip_safetyzone")
		RemoveEntityAll("info_vip_start")
	}
	if (g_MapStripFlags & MAPSTRIP_HOSTAGE)
	{
		RemoveEntityAll("func_hostage_rescue")
		RemoveEntityAll("info_hostage_rescue")
	}
	if (g_MapStripFlags & MAPSTRIP_BUY)
	{
		RemoveEntityAll("func_buyzone")
	}
}

public read_cfg(readAction, line[], section[])
{
	if (!csdm_active())
		return
		
	if (readAction == CFG_READ)
	{
		new setting[24], sign[3], value[32];

		parse(line, setting, 23, sign, 2, value, 31);
		
		if (equali(setting, "remove_objectives"))
		{
			new mapname[24]
			get_mapname(mapname, 23)
			
			if (containi(mapname, "de_") != -1 && containi(value, "d") != -1)
			{
				g_MapStripFlags |= MAPSTRIP_BOMB
			}
			if (containi(mapname, "as_") != -1 && containi(value, "a") != -1)
			{
				g_MapStripFlags |= MAPSTRIP_VIP
			}
			if (containi(mapname, "cs_") != -1 && containi(value, "c") != -1)
			{
				g_MapStripFlags |= MAPSTRIP_HOSTAGE
			}
			if (containi(value, "b") != -1)
			{
				g_MapStripFlags |= MAPSTRIP_BUY
			}
		} else if (equali(setting, "block_buy")) {
			g_BlockBuy = str_to_num(value) ? true : false
		} else if (equali(setting, "ammo_refill")) {
			g_AmmoRefill = str_to_num(value) ? true : false
		} else if (equali(setting, "spawn_radio_msg")) {
			g_RadioMsg = str_to_num(value) ? true : false
		}
	} else if (readAction == CFG_RELOAD) {
		g_MapStripFlags = 0
		g_BlockBuy = true
		g_AmmoRefill = true
		g_RadioMsg = false
	}
}

stock RemoveEntityAll(name[])
{
	new ent = engfunc(EngFunc_FindEntityByString, 0, "classname", name)
	new temp
	while (ent)
	{
		temp = engfunc(EngFunc_FindEntityByString, ent, "classname", name)
		engfunc(EngFunc_RemoveEntity, ent)
		ent = temp
	}
}
