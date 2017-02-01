/*
 * csdm_protection.sma
 * CSDM plugin that lets you have spawn protection
 *
 * (C)2003-2006 David "BAILOPAN" Anderson
 *
 *  Give credit where due.
 *  Share the source - it sets you free
 *  http://www.opensource.org/
 *  http://www.gnu.org/
 */
 
#include <amxmodx>
#include <amxmisc>
#include <fakemeta>
#include <engine_const>
#include <csdm>

new g_ProtColors[3][3] = {{0,0,0},{255,0,0},{0,0,255}}
new g_GlowAlpha[3]
new g_Protected[33]
new bool:g_Enabled = false
new Float:g_ProtTime = 2.0

//Tampering with the author and name lines can violate the copyright
new PLUGINNAME[] = "CSDM Protection"
new VERSION[] = CSDM_VERSION
new AUTHORS[] = "BAILOPAN"

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
	csdm_reg_cfg("protection", "read_cfg")
}

stock set_rendering(index, fx=kRenderFxNone, r=255, g=255, b=255, render=kRenderNormal, amount=16)
{
	set_pev(index, pev_renderfx, fx)
	new Float:RenderColor[3]
	RenderColor[0] = float(r)
	RenderColor[1] = float(g)
	RenderColor[2] = float(b)
	set_pev(index, pev_rendercolor, RenderColor)
	set_pev(index, pev_rendermode, render)
	set_pev(index, pev_renderamt, float(amount))

	return 1
}

public plugin_init()
{
	register_plugin(PLUGINNAME, VERSION, AUTHORS);
	register_forward(FM_PlayerPreThink, "On_ClientPreThink", 1);
}

public client_connect(id)
{
	g_Protected[id] = 0
}

public client_disconnect(id)
{
	if (g_Protected[id])
	{
		remove_task(g_Protected[id])
		g_Protected[id] = 0
	}
}

SetProtection(id)
{
	if (g_Protected[id])
		remove_task(g_Protected[id])
		
	if (!is_user_connected(id))
		return
		
	new team = get_user_team(id)
	
	if (!IsValidTeam(team))
	{
		return
	}

	set_task(g_ProtTime, "ProtectionOver", id)
	g_Protected[id] = id
	
	set_rendering(id, kRenderFxGlowShell, g_ProtColors[team][0], g_ProtColors[team][1], g_ProtColors[team][2], kRenderNormal, g_GlowAlpha[team])
	set_pev(id, pev_takedamage, 0.0)
}

RemoveProtection(id)
{
	if (g_Protected[id])
		remove_task(g_Protected[id])
		
	ProtectionOver(id)
}

public ProtectionOver(id)
{
	g_Protected[id] = 0
	
	if (!is_user_connected(id))
		return
	
	set_rendering(id, kRenderFxNone, 0, 0, 0, kRenderNormal, 0)
	set_pev(id, pev_takedamage, 2.0)
}

public csdm_PostDeath(killer, victim, headshot, const weapon[])
{
	if (!g_Enabled)
		return
		
	RemoveProtection(victim)
}

public csdm_PostSpawn(player, bool:fake)
{
	SetProtection(player)
}

public On_ClientPreThink(id)
{
	if (!g_Enabled || !g_Protected[id] || !is_user_connected(id))
		return
	
	new buttons = pev(id,pev_button);
     
	if ( (buttons & IN_ATTACK) || (buttons & IN_ATTACK2) )
	{
		RemoveProtection(id)
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
		
		if (equali(setting, "colorst"))
		{
			new red[10], green[10], blue[10], alpha[10]
			parse(value, red, 9, green, 9, blue, 9, alpha, 9)
			
			g_ProtColors[_TEAM_T][0] = str_to_num(red)
			g_ProtColors[_TEAM_T][1] = str_to_num(green)
			g_ProtColors[_TEAM_T][2] = str_to_num(blue)
			g_GlowAlpha[_TEAM_T] = str_to_num(alpha)
		}
		else if (equali(setting, "colorsct"))
		{
			new red[10], green[10], blue[10], alpha[10]
			parse(value, red, 9, green, 9, blue, 9, alpha, 9)
			
			g_ProtColors[_TEAM_CT][0] = str_to_num(red)
			g_ProtColors[_TEAM_CT][1] = str_to_num(green)
			g_ProtColors[_TEAM_CT][2] = str_to_num(blue)
			g_GlowAlpha[_TEAM_CT] = str_to_num(alpha)
		} 
		else if (equali(setting, "enabled")) 
		{
			g_Enabled = str_to_num(value) ? true : false
		} 
		else if (equali(setting, "time")) 
		{
			g_ProtTime = str_to_float(value)
		}
	}
}
