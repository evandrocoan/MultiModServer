/*

Copyleft 2007
Plugin thread: http://forums.alliedmods.net/showthread.php?t=16418

USURF
=====

Description
This mod is designed to assist in the running of a surf server. It
includes many features, such as surfing help, semiclip, checkpoints,
"BOOM" button removal and many more features.

Was previously known as "Surf Management / Tools"

Changelog:

	March 4, 2007 - v5.0 	- Renamed and fixed major bugs
	March 13, 2007 - v5.1 	- [FEATURE] Added timer
				  [FEATURE] Added bunnyhop
				  [FEATURE] Added team stack
				  [FEATURE] Added godmode
				  [BUG] Improved semiclip
				  [BUG] Fixed crashing on Linux servers
				  [BUG] Fixed crouching with checkpoints
				  [BUG] Fixed respawn to send people back
				  to their spawns rather than killing them
	March 16, 2007 - v5.2	- [FEATURE] Cleaned up the /surfhelp MOTD display
				  [FEATURE] Added menu to /surfhelp
				  [BUG] Fixed surf help showing more than once
				  [BUG] Optimized surf help section
				  [BUG] Added new commands to /surfhelp display
				  [BUG] Removed some old semiclip code that was
				  causing problems only for people on the same team
				  [BUG] Fixed checkpoints and timers working on
				  non-surf maps

Credits:
	XxAvalanchexX	- Post about blocking knife hits
					
*/

#include <amxmodx>
#include <amxmisc>
#include <fakemeta>
#include <cstrike>
#include <time>

#define TIMER_TASK 23981293
#define TIMER_INTERVAL 1.0

new p_On
new p_AutoCvars
new p_Help
new p_HelpInterval
new p_Respawn
new p_RemoveDropped
new p_RemoveButton
new p_NoGuns
new p_SpawnDist
new p_Semiclip
new p_Cp
new p_CpDelay
new p_BunnyHop
new p_BunnyHopAutoJump
new p_Timer
new p_X
new p_Y
new p_R
new p_G
new p_B
new p_TeamStack
new p_Godmode

new bool:g_SurfMap

new Float:g_Origin[33][3]
new Float:g_Velocity[33][3]
new Float:g_Angles[33][3]
new Float:g_LastSave[33]

new g_Time[33]
new g_Timing[33]
new g_Timer[33]

new g_Menu[512]

new g_TimerMenu[] = "TimerMenu"

new g_TimerTask = TIMER_TASK
new Float:g_TimerInterval = TIMER_INTERVAL

new g_HudObject

new g_SemiclipThinkerClassname[] = "usurf_semiclip"
new g_SemiclipThinker

new g_Models[2][4] =
{
	{_:CS_T_ARCTIC,_:CS_T_GUERILLA,_:CS_T_LEET,_:CS_T_TERROR},
	{_:CS_CT_GIGN,_:CS_CT_GSG9,_:CS_CT_SAS,_:CS_CT_URBAN}
}

new g_SurfHelpMenu

public plugin_init()
{	
	new VERSION[] = "5.2"
	
	register_plugin("uSurf",VERSION,"Hawk552")
	register_cvar("usurf_version", VERSION, FCVAR_SERVER)
	
	new NewVersion[10]
	format(NewVersion,9,"usurf %s",VERSION)
	register_cvar("surf_base_version",NewVersion,FCVAR_SERVER)
	
	// Global Commands / Cvars
	p_On = register_cvar("usurf_on","1")
	
	//Auto Cvars
	p_AutoCvars = register_cvar("usurf_autocvars","1")
	
	// Before we do ANYTHING, let's see if it's a surf map or not.
	CheckSurf()
	
	if(get_pcvar_num(p_On))
		set_task(5.0,"ExecCvars")
	
	// Surf Help
	register_clcmd("say /surfhelp","CmdSurfhelp")
	p_Help = register_cvar("usurf_help","1")
	p_HelpInterval = register_cvar("usurf_help_interval","600.0")
	set_task(get_pcvar_float(p_HelpInterval),"ShowSurfHelp")
	g_SurfHelpMenu = menu_create("Surf Help","SurfHelpHandle")
	menu_additem(g_SurfHelpMenu,"Surfing Help")
	menu_additem(g_SurfHelpMenu,"uSurf Commands")
	menu_additem(g_SurfHelpMenu,"About uSurf")
	
	// Checkpoints
	register_clcmd("say /checkpoint","CmdCheckpoint")
	register_clcmd("say /gocheck","CmdGoCheck")
	p_Cp = register_cvar("usurf_checkpoint","1")
	p_CpDelay = register_cvar("usurf_checkpoint_delay","20")
	
	// extra stuff
	p_RemoveDropped = register_cvar("usurf_remove_dropped","1")
	p_RemoveButton = register_cvar("usurf_remove_button","1")
	p_NoGuns = register_cvar("usurf_noguns","0")
	p_SpawnDist = register_cvar("usurf_spawn_dist","500")
	p_Semiclip = register_cvar("usurf_semiclip","0")
	p_TeamStack = register_cvar("usurf_teamstack","0")
	p_Godmode = register_cvar("usurf_godmode","1")
	
	// bunny hopping
	p_BunnyHop = register_cvar("usurf_bunnyhop","1")
	p_BunnyHopAutoJump = register_cvar("usurf_bunnyhop_autojump","1")
	
	// timer
	p_Timer = register_cvar("usurf_timer","1")
	p_X = register_cvar("usurf_timer_x","0.8")
	p_Y = register_cvar("usurf_timer_y","-0.8")
	p_R = register_cvar("usurf_timer_r","0")
	p_G = register_cvar("usurf_timer_g","0")
	p_B = register_cvar("usurf_timer_b","255")
	register_clcmd("say /timer","CmdTimer")
	register_menucmd(register_menuid(g_TimerMenu),1023,"TimerHandle")
	register_menucmd(register_menuid("Team_Select",1),MENU_KEY_1|MENU_KEY_2|MENU_KEY_5|MENU_KEY_6,"TeamHandle") 
	register_clcmd("jointeam","TeamHandle")
	g_HudObject = CreateHudSyncObj()
	register_dictionary("time.txt")
	
	register_forward(FM_SetModel,"ForwardSetModel")
	register_forward(FM_PlayerPreThink,"ForwardPlayerPreThink")
	register_forward(FM_Touch,"ForwardTouch")
	register_forward(FM_Think,"ForwardThink")
	register_forward(FM_TraceLine,"ForwardTraceLine",1)
	register_forward(FM_TraceHull,"ForwardTraceHull",1)
	
	CheckSurf()
	CheckButton()
	
	// Respawn
	p_Respawn = register_cvar("usurf_respawn","1")
	register_event("DeathMsg","EventDeathMsg","a")
	register_clcmd("say /respawn","CmdRespawn")
	set_task(1.0,"StandardTimer",_,_,_,"b")
	
	new Ent = engfunc(EngFunc_CreateNamedEntity,engfunc(EngFunc_AllocString,"info_target"))
	if(!Ent)
		return
	
	set_pev(Ent,pev_classname,g_SemiclipThinkerClassname)
	new Float:Time
	global_get(glb_time,Time)
	set_pev(Ent,pev_nextthink,Time + 0.01)
	dllfunc(DLLFunc_Spawn,Ent)
	
	g_SemiclipThinker = Ent
}

public CheckSurf()
{
	new MapName[32]
	get_mapname(MapName,31)
	if(containi(MapName,"surf") != -1 || containi(MapName,"wurf_") != -1 || equali(MapName,"tentical"))
		g_SurfMap = true
		
	return PLUGIN_CONTINUE
}

public ExecCvars()
{
	if(get_pcvar_num(p_On) && get_pcvar_num(p_AutoCvars) && g_SurfMap)
	{
		new ConfigsDir[50],FileLocation[50]
		get_configsdir(ConfigsDir,49)
		
		format(FileLocation,49,"%s/surf.cfg",ConfigsDir)
		
		// I'm not going to update this, because the old file
		// natives are actually much easier to work with for
		// this purpose.
		if(file_exists(FileLocation))
			server_cmd("exec ^"%s^"",FileLocation)
		else
		{
			write_file(FileLocation,"sv_airaccelerate 100")
			write_file(FileLocation,"mp_freezetime 0")
			write_file(FileLocation,"amxx pause statsx.amxx")
			write_file(FileLocation,"amxx pause miscstats.amxx")
			write_file(FileLocation,"amxx pause stats_logging.amxx")
			// people seem to be stupid to fucking RTFM, so I really have to disable this by default
			write_file(FileLocation,"//humans_join_team ct // if you want all players on one team, use this")
			write_file(FileLocation,"echo Executing surf map config.",2)
			server_cmd("exec %s",FileLocation)
			
			format(FileLocation,49,"%s/amxx.cfg",ConfigsDir)
			if(file_exists(FileLocation))
			{
				write_file(FileLocation,"// AUTO WRITTEN BY USURF")
				write_file(FileLocation,"^n^nhumans_join_team any")
				write_file(FileLocation,"sv_airaccelerate 10")
			}
		}
	}
}

public client_disconnect(id)
{
	g_Origin[id][0] = 0.0
	
	g_Timing[id] = 0
	g_Time[id] = 0
	g_Timer[id] = 0
	g_LastSave[id] = 0.0
	
	g_Origin[id] = Float:{0.0,0.0,0.0}
}

public TeamHandle(id,Item)
{
	// to prevent memory corruption
	new Key = Item
	
	new Arg[2]
	read_argv(0,Arg,1)
	
	if(Arg[0] == 'j')
	{
		read_argv(1,Arg,1)
		Key = str_to_num(Arg) - 1
	}
	
	new TeamStack = get_pcvar_num(p_TeamStack)
	if(Key != 5 && Key != TeamStack - 1 && (TeamStack == _:CS_TEAM_T || TeamStack == _:CS_TEAM_CT))
	{
		client_print(id,print_center,"You must join the %s team.",TeamStack == 1 ? "Terrorist" : "Counter-Terrorist")
		engclient_cmd(id,"chooseteam")
		
		return PLUGIN_HANDLED
	}
	
	return PLUGIN_CONTINUE
}

public CmdTimer(id)
{
	if(!get_pcvar_num(p_Timer) || !get_pcvar_num(p_On) || !g_SurfMap)
		return
	
	new Len = format(g_Menu,sizeof g_Menu - 1,"uSurf Timer Menu^n^n1. %s Timer^n",g_Timer[id] ? "Disable" : "Enable")
	if(g_Timer[id])
		Len += format(g_Menu[Len],sizeof g_Menu - Len - 1,"2. %s Timing^n3. Reset Timer^n",g_Timing[id] ? "Stop" : "Begin")
	format(g_Menu[Len],sizeof g_Menu - Len - 1,"^n0. Exit")
	
	new Keys = g_Timer[id] ? MENU_KEY_1|MENU_KEY_2|MENU_KEY_3|MENU_KEY_0 : MENU_KEY_1|MENU_KEY_0
		
	show_menu(id,Keys,g_Menu,-1,g_TimerMenu)
}

public TimerHandle(id,Key)
{
	switch(Key)
	{
		case 0 :
		{
			g_Timer[id] = !g_Timer[id]
			if(!g_Timer[id])
				ShowSyncHudMsg(id,g_HudObject,"")
		}
		case 1 :
		{
			g_Timing[id] = !g_Timing[id]
			g_Timing[id] ? set_task(g_TimerInterval,"Timer",id + g_TimerTask) : remove_task(id + g_TimerTask)
		}
		case 2 :
			g_Time[id] = 0
	}
	
	if(Key != 9)
		CmdTimer(id)
}

public Timer(id)
{
	g_Time[id - g_TimerTask] += floatround(g_TimerInterval)
	
	set_task(g_TimerInterval,"Timer",id)
}

public CmdSurfhelp(id)
{
	if(!get_pcvar_num(p_On) || !get_pcvar_num(p_Help) || !g_SurfMap)
		return PLUGIN_CONTINUE
	
	menu_display(id,g_SurfHelpMenu,0)		
	
	return PLUGIN_CONTINUE
}

public SurfHelpHandle(id,Menu,Key)
{
	static MOTD[4096], Title[16],Pos
	
	switch(Key)
	{
		case 0 :
		{
			copy(Title,15,"Surf Help")
			
			Pos = format(MOTD,sizeof MOTD - 1,"<style type=^"text/css^"><!--.sty1 {color: #CC9900;font-family: Arial, Helvetica, sans-serif;}--></style><body bgcolor=^"#000000^"><span class=^"sty1^"><strong><div align=^"center^">Surf Discipline</div></strong></span></p><table width=^"100%%^" border=^"1^"><table width=^"100%%^" border=^"1^">")
			Pos += format(MOTD[Pos],sizeof MOTD - 1 - Pos,"<tr><td><span class=^"sty1^">To surf, jump or walk onto one of the curved walls (hereby referted to as 'ramps'). Then simply hold strafe (Default are the A and D keys). This will cause you to glide along the walls, or &quot;surf&quot;. </span></td></tr>")
			Pos += format(MOTD[Pos],sizeof MOTD - 1 - Pos,"<tr><td><span class=^"sty1^">While surfing, never press up, down, or crouch; pressing those will cause you to slide off the wall and fall, which, in most surf maps, will cause you to get sent back to your spawn. </span></td></tr>")
			Pos += format(MOTD[Pos],sizeof MOTD - 1 - Pos,"<tr><td><span class=^"sty1^">To change direction (in order to make it to the next ramp), press the button for the direction you wish to go before flying off of your current ramp.</span></td></tr>")
			Pos += format(MOTD[Pos],sizeof MOTD - 1 - Pos,"<tr><td><span class=^"sty1^">Surfing takes pratice, so don't be discouraged if you don't get it right the first time.</span></td></tr>")
			Pos += format(MOTD[Pos],sizeof MOTD - 1 - Pos,"</table><p align=^"center^"><span class=^"sty1^"><strong>Powered by uSurf</strong></span></p></body></html>")
		}
		case 1 :
		{
			copy(Title,15,"uSurf Commands")
			
			Pos = format(MOTD,sizeof MOTD - 1,"<style type=^"text/css^"><!--.sty1 {color: #CC9900;font-family: Arial, Helvetica, sans-serif;}--></style>")
			Pos += format(MOTD[Pos],sizeof MOTD - 1 - Pos,"<body bgcolor=^"#000000^"><strong><span class=^"sty1^"><div align=^"center^"><p>uSurf Commands</strong></p></span></div><table width=^"100%%^" border=^"1^">")
			Pos += format(MOTD[Pos],sizeof MOTD - 1 - Pos,"<tr><td><span class=^"sty1^">say /surfhelp</span></td><td><span class=^"sty1^">Brings up this window.</span>/td></tr>")
			if(get_pcvar_num(p_Respawn))
				Pos += format(MOTD[Pos],sizeof MOTD - 1 - Pos,"<tr><td><span class=^"sty1^">say /respawn</span></td><td><span class=^"sty1^">Sends you back to your spawn, or, in the event of a malfunction, allows you to respawn yourself manually.</span></td></tr>")
			if(get_pcvar_num(p_Cp))
			{
				new Cvar = get_pcvar_num(p_CpDelay)
				Pos += format(MOTD[Pos],sizeof MOTD - 1 - Pos,"<tr><td><span class=^"sty1^">say /checkpoint</span></td><td><span class=^"sty1^">Saves a checkpoint at your current location. Use &quot;say /gocheck&quot; to go to it. You can save or load a checkpoint every %d seconds.</span></td></tr>",Cvar)
				Pos += format(MOTD[Pos],sizeof MOTD - 1 - Pos,"<tr><td><span class=^"sty1^">say /gocheck</span></td><td><span class=^"sty1^">Allows you to go to one of your saved checkpoints. You can save or load a checkpoint every %d seconds.</span></td></tr>",Cvar)
			}
			if(get_pcvar_num(p_Timer))
				Pos += format(MOTD[Pos],sizeof MOTD - 1 - Pos,"<tr><td><span class=^"sty1^">say /timer</span></td><td><span class=^"sty1^">Brings up a menu with various timer options, allowing you to time various events.</span></td></tr>")
			Pos += format(MOTD[Pos],sizeof MOTD - 1 - Pos,"</table><p align=^"center^"><span class=^"sty1^"><strong>Powered by uSurf</strong></span></p></body></html>")
		}
		case 2 :
		{
			copy(Title,15,"About uSurf")
			
			Pos = format(MOTD,sizeof MOTD - 1,"<style type=^"text/css^"><!--.sty1 {color: #CC9900;font-family: Arial, Helvetica, sans-serif;}--></style>")
			Pos += format(MOTD[Pos],sizeof MOTD - 1 - Pos,"<body bgcolor=^"#000000^"><strong><span class=^"sty1^"><div align=^"center^">About uSurf</span></strong></div>")
			Pos += format(MOTD[Pos],sizeof MOTD - 1 - Pos,"<span class=^"sty1^"><p>This plugin is designed to manage surf servers. It is the successor to Surf Management / Tools.</p>")
			Pos += format(MOTD[Pos],sizeof MOTD - 1 - Pos,"<p>For more information or to download this plugin, go <a href=^"http://forums.alliedmods.net/showthread.php?t=16418^">here</a> (<a href=^"http://forums.alliedmods.net/showthread.php?t=16418^">http://forums.alliedmods.net/showthread.php?t=16418</a>)</p>")
			Pos += format(MOTD[Pos],sizeof MOTD - 1 - Pos,"</span><p align=^"center^"><span class=^"sty1^"><strong>Powered by uSurf</strong></span></p></body></html")
		}
		default :
			return
	}
	
	show_motd(id,MOTD,Title)
	menu_display(id,g_SurfHelpMenu,0)
}

public ShowSurfHelp()
{	
	if(g_SurfMap && get_pcvar_num(p_Help) && get_pcvar_num(p_On))
		client_print(0,print_chat,"[USURF] Need help surfing? Say /surfhelp")
		
	set_task(get_pcvar_float(p_HelpInterval),"ShowSurfHelp")
}

public CmdCheckpoint(id)
{
	if(!get_pcvar_num(p_Cp) || !get_pcvar_num(p_On) || !g_SurfMap)
		return PLUGIN_HANDLED
	
	new Float:Time,Float:Delay = get_pcvar_float(p_CpDelay)
	global_get(glb_time,Time)
	
	new Float:TimePassed = Time - g_LastSave[id] 
	
	if(TimePassed < Delay)
	{
		client_print(id,print_chat,"[USURF] You must wait %d seconds before saving again.",floatround(Delay - TimePassed))
		return PLUGIN_HANDLED
	}
	
	pev(id,pev_origin,g_Origin[id])
	if(pev(id,pev_button) & IN_DUCK)
		g_Origin[id][2] += 24.0
	pev(id,pev_velocity,g_Velocity[id])
	pev(id,pev_angles,g_Angles[id])
	g_LastSave[id] = Time
	
	client_print(id,print_chat,"[USURF] You have saved this checkpoint.")
	
	return PLUGIN_HANDLED
}

public CmdGoCheck(id)
{
	if(!get_pcvar_num(p_Cp) || !get_pcvar_num(p_On) || !g_SurfMap)
		return PLUGIN_HANDLED
	
	if(!g_Origin[id][0])
	{
		client_print(id,print_chat,"[USURF] You have not saved a checkpoint.")
		return PLUGIN_HANDLED
	}
	
	new Float:Time,Float:Delay = get_pcvar_float(p_CpDelay)
	global_get(glb_time,Time)
	
	new Float:TimePassed = Time - g_LastSave[id] 
	
	if(TimePassed < Delay)
	{
		client_print(id,print_chat,"[USURF] You must wait %d seconds before going to a checkpoint.",floatround(Delay - TimePassed))
		return PLUGIN_HANDLED
	}
	
	engfunc(EngFunc_SetOrigin,id,g_Origin[id])
	set_pev(id,pev_velocity,g_Velocity[id])
	set_pev(id,pev_fixangle,1)
	set_pev(id,pev_angles,g_Angles[id])
	g_LastSave[id] = Time
	
	client_print(id,print_chat,"[USURF] You have gone to your last checkpoint.")
	
	return PLUGIN_HANDLED
}

public CmdRespawn(id)
{	
	new CsTeams:Team = cs_get_user_team(id)
	
	if(!get_pcvar_num(p_On))
		return client_print(id,print_chat,"[USURF] Sorry, the surf plugin is currently disabled.")
	else if(!get_pcvar_num(p_Respawn))
		return client_print(id,print_chat,"[USURF] Respawning is currently disabled.")
	else if(!g_SurfMap)
		return client_print(id,print_chat,"[USURF] This is not a surf map.")
	
	if(Team == CS_TEAM_T || Team == CS_TEAM_CT)
		set_task(0.5,"Spawn",id)
	else
		return client_print(id,print_chat,"[USURF] You must be on a team to respawn.")
	
	client_print(id,print_chat,is_user_alive(id) ? "[USURF] You have been sent back to your spawn." : "[USURF] You have been respawned.")
		
	return PLUGIN_CONTINUE
}

public StandardTimer()
{
	if(!get_pcvar_num(p_On) || !g_SurfMap)
		return
	
	static Players[32],Playersnum,Player,CsTeams:Team
	
	new TeamStack = get_pcvar_num(p_TeamStack)
	if(TeamStack == _:CS_TEAM_CT || TeamStack == _:CS_TEAM_T)
	{
		get_players(Players,Playersnum)
		
		for(new Count;Count < Playersnum;Count++)
		{
			Player = Players[Count]
			
			Team = cs_get_user_team(Player)
			if(_:Team != TeamStack && (Team == CS_TEAM_T || Team == CS_TEAM_CT))
				cs_set_user_team(Player,CsTeams:TeamStack,CsInternalModel:g_Models[TeamStack - 1][random_num(0,3)])
		}
	}
		
	if(!get_pcvar_num(p_Respawn))
		return
	
	get_players(Players,Playersnum,"b")
	
	for(new Count = 0;Count < Playersnum;Count++)
	{
		Player = Players[Count]
		Team = cs_get_user_team(Player)
		
		if(Team == CS_TEAM_T || Team == CS_TEAM_CT)
			Spawn(Player)
	}
}

public EventDeathMsg()	
{
	new id = read_data(2)
	set_task(0.5,"Spawn",id)
	
	global_get(glb_time,g_LastSave[id])
	g_LastSave[id] -= get_pcvar_num(p_CpDelay)
}

public Spawn(id)
{
	new CsTeams:Team = cs_get_user_team(id)
	
	if(is_user_connected(id) && (Team == CS_TEAM_T || Team == CS_TEAM_CT) && get_pcvar_num(p_On) && get_pcvar_num(p_Respawn) && g_SurfMap)
	{
		dllfunc(DLLFunc_Spawn,id)
		set_task(0.2,"GiveSuit",id)
		set_task(0.3,"GiveItems",id)
	}
}

public GiveSuit(id)
	fm_give_item(id,"item_suit")

public GiveItems(id)
{
	fm_give_item(id,"")
	fm_give_item(id,"")
}

// no, VEN did not write this, I did (although I found out later that he wrote something like it)
fm_give_item(id,Item[])
{
	if(containi(Item,"item_") == -1 && containi(Item,"weapon_") == -1 && containi(Item,"ammo_") == -1 && containi(Item,"tf_weapon_") == -1)
		return
	
	new Ent = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, Item)),Float:vOrigin[3]
	
	if(!pev_valid(Ent))
		return
		
	pev(id,pev_origin,vOrigin)
	set_pev(Ent,pev_origin,vOrigin)
	
	set_pev(Ent,pev_spawnflags,pev(Ent,pev_spawnflags)|(1<<30))
	
	dllfunc(DLLFunc_Spawn,Ent)
	
	new Solid = pev(Ent,pev_solid)
	
	dllfunc(DLLFunc_Touch,Ent,id)
	
	if(pev(Ent,pev_solid) == Solid)
		engfunc(EngFunc_RemoveEntity,Ent)
}

CheckButton()
	if(get_pcvar_num(p_RemoveButton) && get_pcvar_num(p_On) && g_SurfMap)
	{
		new Ent,Value[] = "classname",ClassName[] = "env_explosion"
		while((Ent = engfunc(EngFunc_FindEntityByString,Ent,Value,ClassName)) != 0)
			if(pev_valid(Ent))
				set_pev(Ent,pev_flags,pev(Ent,pev_flags)|FL_KILLME)
	}

public ForwardPlayerPreThink(id)
{
	if(!is_user_alive(id) || !get_pcvar_num(p_On) || !g_SurfMap)
		return
		
	new NoGuns = get_pcvar_num(p_NoGuns)
	
	if(NoGuns == 1)
	{
		new SpawnDistance = get_pcvar_num(p_SpawnDist)
		
		static Float:vOrigin[3]
		pev(id,pev_origin,vOrigin)
	
		new DeathMatch = engfunc(EngFunc_FindEntityByString,-1,"classname","info_player_deathmatch")
		new PlayerStart = engfunc(EngFunc_FindEntityByString,-1,"classname","info_player_start")
		
		if(DeathMatch && PlayerStart)
		{
			static Float:vDeathMatch_Origin[3]
			pev(DeathMatch,pev_origin,vDeathMatch_Origin)
	
			static Float:vPlayerStart_Origin[3]
			pev(PlayerStart,pev_origin,vPlayerStart_Origin)
		
			new Float:DeathMatch_Distance = get_distance_f(vOrigin,vDeathMatch_Origin)
			new Float:PlayerStart_Distance = get_distance_f(vOrigin,vPlayerStart_Origin)
		
			new Clip,Ammo,Weapon = get_user_weapon(id,Clip,Ammo)
			
			if(DeathMatch_Distance < SpawnDistance || PlayerStart_Distance < SpawnDistance)
			{
				if(Weapon != CSW_KNIFE && Weapon != CSW_C4 && Weapon != CSW_HEGRENADE && Weapon != CSW_FLASHBANG && Weapon != CSW_SMOKEGRENADE)
					client_cmd(id,"drop")
			} // Argh, stupid thing doesn't understand this if I don't add the brackets.
			else if(DeathMatch_Distance > SpawnDistance || PlayerStart_Distance > SpawnDistance)
				if(!user_has_weapon(id,CSW_SCOUT))
					fm_give_item(id,"weapon_scout")
		}
	}
	else if(NoGuns == 2)
	{		
		new Clip, Ammo, Weapon = get_user_weapon(id,Clip,Ammo)
			
		if(Weapon != CSW_KNIFE && Weapon != CSW_C4 && Weapon != CSW_HEGRENADE && Weapon != CSW_FLASHBANG && Weapon != CSW_SMOKEGRENADE)
			client_cmd(id,"drop")
	}
	else if(NoGuns == 3)
	{
		new Clip, Ammo, Weapon = get_user_weapon(id,Clip,Ammo)
			
		if(Weapon != CSW_KNIFE && Weapon != CSW_C4)
		{
			fm_strip_user_weapons(id)
			fm_give_item(id,"weapon_knife")
		}
	}
	
	if(get_pcvar_num(p_BunnyHop))
	{
		set_pev(id,pev_fuser2,0.0)
		
		if(get_pcvar_num(p_BunnyHopAutoJump) && pev(id,pev_button) & IN_JUMP)
		{
			new Flags = pev(id,pev_flags)
			if(!(Flags & FL_WATERJUMP) && pev(id,pev_waterlevel) < 2 && Flags & FL_ONGROUND)
			{
				new Float:Velocity[3]
				pev(id,pev_velocity,Velocity)
				Velocity[2] += 250.0
				set_pev(id,pev_velocity,Velocity)

				set_pev(id,pev_gaitsequence,6)
			}
		}
	}
	
	if(get_pcvar_num(p_Timer) && g_Timer[id])
	{
		static Time[33]
		
		set_hudmessage(get_pcvar_num(p_R),get_pcvar_num(p_G),get_pcvar_num(p_B),get_pcvar_float(p_X),get_pcvar_float(p_Y),0,0.0,6.0,0.0,0.0,-1)
		get_time_length(id,g_Time[id],timeunit_seconds,Time,32)
		ShowSyncHudMsg(id,g_HudObject,"Timer: %s",Time)
	}
}

public ForwardSetModel(id,Model[])
{	
	if(!pev_valid(id) || !g_SurfMap || !get_pcvar_num(p_On) || !strlen(Model) || !get_pcvar_num(p_RemoveDropped))
		return
	
	static ClassName[33]
	pev(id,pev_classname,ClassName,32)
	
	if(equali(ClassName,"weaponbox"))	
		set_task(0.1,"RemoveGun",id)
}

public RemoveGun(id)	
	if(pev_valid(id))
		engfunc(EngFunc_RemoveEntity,id)

public ForwardTouch(Ptr,Ptd)
{
	if(!pev_valid(Ptr) || !pev_valid(Ptd) || !g_SurfMap || !get_pcvar_num(p_On) || !get_pcvar_num(p_Respawn))
		return FMRES_IGNORED
	
	new id
	if(is_user_alive(Ptr))
		id = Ptr
	else if(is_user_alive(Ptd))
		id = Ptd
	
	if(!id)
		return FMRES_IGNORED
		
	static Classname[33]
	pev(id == Ptr ? Ptd : Ptr,pev_classname,Classname,32)
	if(equali(Classname,"trigger_hurt"))
	{
		Spawn(id)
		return FMRES_SUPERCEDE
	}
	
	return FMRES_IGNORED
}

public ForwardThink(Ent)
{
	if(Ent != g_SemiclipThinker || !g_SurfMap)
		return
	
	if(get_pcvar_num(p_Semiclip) && get_pcvar_num(p_On))
	{
		static Players[32],Playersnum,Player
		get_players(Players,Playersnum)
		
		for(new Count;Count < Playersnum;Count++)
		{			
			Player = Players[Count]
			if(!is_user_alive(Player))
				continue
			
			set_pev(Player,pev_solid,IsColliding(Player) ? SOLID_NOT : SOLID_BBOX)
		}
	}
	
	new Float:Time
	global_get(glb_time,Time)
	set_pev(Ent,pev_nextthink,Time + 0.01)
}

public ForwardTraceLine(Float:v1[3],Float:v2[3],EntToSkip,NoMonsters,TR)
{
	if(!get_pcvar_num(p_Godmode) || !g_SurfMap || !get_pcvar_num(p_On))
		return FMRES_IGNORED
	
	new id = get_tr(TR_pHit)
	if(!is_user_alive(id))
		return FMRES_IGNORED
		
	new Attacker
	while((Attacker = engfunc(EngFunc_FindEntityInSphere,Attacker,v1,10.0)) != 0)
		if(Attacker < 33 && Attacker > 0)
			break
	
	if(!is_user_alive(Attacker))
		return FMRES_IGNORED
	
	new Button = pev(Attacker,pev_button)
	if(!(Button & IN_ATTACK) && !(Button & IN_ATTACK2))
		return FMRES_IGNORED
	
	set_tr(TR_flFraction,1.0)
	
	return FMRES_IGNORED
}

public ForwardTraceHull(Float:v1[3],Float:v2[3],NoMonsters,Hull,EntToSkip,TR)
{
	if(!g_SurfMap || !get_pcvar_num(p_On) || !get_pcvar_num(p_Godmode))
		return FMRES_IGNORED
	
	new Button = pev(EntToSkip,pev_button)
	if(!(Button & IN_ATTACK) && !(Button & IN_ATTACK2))
		return FMRES_IGNORED
	
	set_tr(TR_flFraction,1.0)
	
	return FMRES_IGNORED
}

// thanks to VEN for this stock from Fakemeta Utilities
fm_strip_user_weapons(index) {
	new ent = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "player_weaponstrip"))
	if (!pev_valid(ent))
		return 0

	dllfunc(DLLFunc_Spawn, ent)
	dllfunc(DLLFunc_Use, ent, index)
	
	engfunc(EngFunc_RemoveEntity, ent)

	return 1
}

IsColliding(id)
{
	if(pev(id,pev_flags) & FL_ONGROUND || pev(id,pev_button) & IN_JUMP)
		return false
	
	new Ent,Float:Origin[3]
	pev(id,pev_origin,Origin)
		
	while((Ent = engfunc(EngFunc_FindEntityInSphere,Ent,Origin,36.0)) != 0)
		if(Ent > 0 && Ent <= 32 && is_user_alive(Ent) && Ent != id)
			return true
	
	return false
}
