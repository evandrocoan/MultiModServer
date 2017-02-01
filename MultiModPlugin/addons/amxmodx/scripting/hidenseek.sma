/*

	HideNSeek
	Version 2.8
	By Exolent
	
	Information about this plugin can be found at:
	http://forums.alliedmods.net/showthread.php?t=65370

*/

#include <amxmodx>
#include <amxmisc>
#include <fakemeta>
#include <fakemeta_util>

/* YAY! No <cstrike> <csx> <fun> or <engine>!! =D */


#define PLUGIN_NAME	"HideNSeek"
#define PLUGIN_VERSION	"2.8"
#define PLUGIN_AUTHOR	"Exolent"


#pragma semicolon 1


/* save memory */
new const g_sBlank[] = "";
new const g_sA[] = "a";
new const g_sB[] = "b";
new const g_sS[] = "s";
new const g_sKnifeModel_v[] = "models/v_knife.mdl";
new const g_sKnifeModel_w[] = "models/w_knife.mdl";
new const g_sModel[] = "model";
new const g_sLightsNormal[] = "m";
new const g_sClassBreakable[] = "func_breakable";
new const g_sClassDoor[] = "func_door";
new const g_sClassDoorRotating[] = "func_door_rotating";
/* end of save memory globals */

/* CONVERT CSTRIKE TO FAKEMETA */

enum CsTeams
{
	CS_TEAM_UNASSIGNED = 0,
	CS_TEAM_T,
	CS_TEAM_CT,
	CS_TEAM_SPECTATOR
};
enum CsInternalModel
{
	CS_DONTCHANGE = 0,
	CS_CT_URBAN,
	CS_T_TERROR,
	CS_T_LEET,
	CS_T_ARCTIC,
	CS_CT_GSG9,
	CS_CT_GIGN,
	CS_CT_SAS,
	CS_T_GUERILLA,
	CS_CT_VIP,
	CZ_T_MILITIA,
	CZ_CT_SPETSNAZ
};
enum CsArmorType
{
	CS_ARMOR_NONE = 0,
	CS_ARMOR_KEVLAR,
	CS_ARMOR_VESTHELM
};

#define OFFSET_ARMORTYPE		112
#define OFFSET_TEAM			114
#define OFFSET_MONEY			115
#define OFFSET_INTERNALMODEL		126
#define OFFSET_AWP_AMMO			377 
#define OFFSET_SCOUT_AMMO		378
#define OFFSET_PARA_AMMO		379
#define OFFSET_FAMAS_AMMO		380
#define OFFSET_M3_AMMO			381
#define OFFSET_USP_AMMO			382
#define OFFSET_FIVESEVEN_AMMO		383
#define OFFSET_DEAGLE_AMMO		384
#define OFFSET_P228_AMMO		385
#define OFFSET_GLOCK_AMMO		386
#define OFFSET_FLASHBANG_AMMO		387
#define OFFSET_HEGRENADE_AMMO		388
#define OFFSET_SMOKEGRENADE_AMMO	389
#define OFFSET_C4_AMMO			390

#define cs_set_user_bpammo(%1,%2,%3) set_pdata_int(%1, __get_ammo_offset(%2), %3)
#define cs_set_user_model(%1,%2) engfunc(EngFunc_SetClientKeyValue, %1, engfunc(EngFunc_GetInfoKeyBuffer, %1), g_sModel, %2)
#define cs_get_user_model(%1,%2,%3) engfunc(EngFunc_InfoKeyValue, engfunc(EngFunc_GetInfoKeyBuffer, %1), g_sModel, %2, %3)

/* END OF CSTRIKE TO FAKEMETA CONVERSION */


#define HIDE_MONEY		(1<<5)

new const CsTeams:HNS_TEAM_HIDER = CS_TEAM_T;
new const CsTeams:HNS_TEAM_SEEKER = CS_TEAM_CT;

new const CsInternalModel:HNS_MODEL_HIDER = CS_T_LEET;
new const CsInternalModel:HNS_MODEL_SEEKER = CS_CT_GIGN;

enum
{
	SCRIM_NONE = 0,
	SCRIM_ROUNDS,
	SCRIM_POINTS,
	
	SCRIM_TYPES
};

new const g_sBuyCommands[][] =
{
	"usp", "glock", "deagle", "p228", "elites",
	"fn57", "m3", "xm1014", "mp5", "tmp", "p90",
	"mac10", "ump45", "ak47", "galil", "famas",
	"sg552", "m4a1", "aug", "scout", "awp", "g3sg1",
	"sg550", "m249", "vest", "vesthelm", "flash",
	"hegren", "sgren", "defuser", "nvgs", "shield",
	"primammo", "secammo", "km45", "9x19mm", "nighthawk",
	"228compact", "fiveseven", "12gauge", "autoshotgun",
	"mp", "c90", "cv47", "defender", "clarion", "krieg552",
	"bullpup", "magnum", "d3au1", "krieg550"
};
new const MAX_BUY_COMMANDS = sizeof(g_sBuyCommands);
new const g_sRemoveEntities[][] =
{
	"func_bomb_target",
	"info_bomb_target",
	"hostage_entity",
	"monster_scientist",
	"func_hostage_rescue",
	"info_hostage_rescue",
	"info_vip_start",
	"func_vip_safetyzone",
	"func_escapezone",
	"armoury_entity"
};
new const MAX_REMOVED_ENTITIES = sizeof(g_sRemoveEntities);
new const g_sAllModels[CsTeams][][] =
{
	{"", "", "", ""},
	{"terror", "arctic", "leet", "guerilla"},
	{"gign", "gsg9", "sas", "urban"},
	{"", "", "", ""}
};
new const g_sDefaultModels[CsTeams][] =
{
	"",
	"leet",
	"gign",
	""
};
new const g_sTeamInfo[CsTeams][] =
{
	"UNASSIGNED",
	"TERRORIST",
	"CT",
	"SPECTATOR"
};
new const g_sTeamNames[CsTeams][] =
{
	"Spectator",
	"Terrorist",
	"Counter-Terrorist",
	"Spectator"
};

enum (+= 1000)
{
	TASK_ID_STRIPWEAPONS = 1000,
	TASK_ID_GIVEWEAPONS,
	TASK_ID_GIVEKNIFE,
	TASK_ID_CHECKMODEL,
	TASK_ID_HIDETIMER,
	TASK_ID_SWAPTEAMS,
	TASK_ID_SETLIGHTS,
	TASK_ID_SHOWPLUGININFO,
	TASK_ID_SCRIMVOTE
};

new const g_PlayerTasks[] =
{
	TASK_ID_STRIPWEAPONS,
	TASK_ID_GIVEWEAPONS,
	TASK_ID_GIVEKNIFE,
	TASK_ID_CHECKMODEL,
	TASK_ID_SHOWPLUGININFO
};
new const MAX_PLAYER_TASKS = sizeof(g_PlayerTasks);

new bool:g_bHnsOn = true;
new bool:g_bScrimOn;
new bool:g_bWarmup;

new g_ScrimVoteTimer;
new g_ScrimVoteCount[SCRIM_TYPES];
new bool:g_bScrimVoted[33];

new g_ScrimType;
new CsTeams:g_ScrimWinner;
new g_ScrimSaveWins;
new g_ScrimRounds[CsTeams];
new g_ScrimLosses[CsTeams];
new g_ScrimMaxRounds;
new g_ScrimMaxLosses;
new bool:g_bScrimIsDraw;
new CsTeams:g_ScrimTeams[3];
new g_ScrimTeamNums[CsTeams];
new g_ScrimScores[CsTeams];

new g_PointsKnife;
new g_PointsHeadshot;
new g_PointsGrenade;
new g_PointsKill;
new g_PointsSuicide;
new g_PointsTeamKill;
new g_PointsRoundWin;
new g_PointsRoundLose;

new bool:g_bRestartRound;

new bool:g_bConnected[33];
new bool:g_bAlive[33];
new bool:g_bFirstSpawn[33];
new CsTeams:g_Team[33];

new bool:g_bSolid[33];
new bool:g_bRestoreSolid[33];

new bool:g_bWeaponsGiven;

new g_sHelpMotd[43];
new g_sScrimMotd[49];

new Float:g_fKillMsgDelay[33];

new g_RoundsLost;
new g_RoundsEnded;

new bool:g_bDisableSlash = true;

new g_HideTimer;

new g_OldMoney;

new g_sLights[16];

new bool:g_bNonSpawnEvent[33];
new g_FwdClientCommand_post;

new bool:g_bRemovedBreakables;
new bool:g_bRemovedDoors;
new bool:g_bRemovedDoorsRotating;

new Float:g_fBoostPunishDelay[33];
new Float:g_fBoostMessageDelay[33];

new g_BoostHud;

new hns_footsteps;
new hns_money;
new hns_nubslash;
new hns_disablebuy;
new hns_hiders_knife;
new hns_grenades[CsTeams];
new hns_grenades_percent[CsTeams];
new hns_flashbangs[CsTeams];
new hns_flashbangs_percent[CsTeams];
new hns_smokegren[CsTeams];
new hns_smokegren_percent[CsTeams];
new hns_armor[CsTeams];
new hns_hidetime;
new hns_timersounds;
new hns_noslowdown;
new hns_teamchange;
new hns_disablekill;
new hns_blindcolors;
new hns_hudcolors;
new hns_hiders_alivefrags;
new hns_lights;
new hns_visiblecommands;
new hns_chooseteam;
new hns_semiclip;
new hns_semiclip_alpha;
new hns_gametype;
new hns_prefix;
new hns_removebreakables;
new hns_noflash;
new hns_removedoors;
new hns_noboosting;
new hns_noboosting_damage;
new hns_noboosting_punish;
new hns_noboosting_interval;
new hns_warmup_godmode;
new hns_warmup_respawn;

new hnss_prefix;
new hnss_vote_timer;
new hnss_rounds_wins;
new hnss_rounds_losses;
new hnss_rounds_savewins;
new hnss_points_knife;
new hnss_points_headshot;
new hnss_points_grenade;
new hnss_points_kill;
new hnss_points_suicide;
new hnss_points_teamkill;
new hnss_points_roundwin;
new hnss_points_roundlose;
new hnss_points_rounds;

new amx_vote_answers;
new sv_restart;

new g_msgSayText;
new g_msgHideWeapon;
new g_msgScreenFade;
new g_msgTeamInfo;
new g_msgMoney;
new g_msgArmorType;

new g_MaxPlayers;
new g_MaxEntities;

new g_HostageEnt;

public plugin_precache()
{
	register_forward(FM_Spawn, "fwdSpawn", 0);
	
	new allocHostageEntity = engfunc(EngFunc_AllocString, "hostage_entity");
	do
	{
		g_HostageEnt = engfunc(EngFunc_CreateNamedEntity, allocHostageEntity);
	}
	while( !pev_valid(g_HostageEnt) );
	
	engfunc(EngFunc_SetOrigin, g_HostageEnt, Float:{0.0, 0.0, -55000.0});
	engfunc(EngFunc_SetSize, g_HostageEnt, Float:{-1.0, -1.0, -1.0}, Float:{1.0, 1.0, 1.0});
	dllfunc(DLLFunc_Spawn, g_HostageEnt);
	
	return PLUGIN_CONTINUE;
}

public plugin_init()
{
	register_plugin(PLUGIN_NAME, PLUGIN_VERSION, PLUGIN_AUTHOR);
	
	register_cvar(PLUGIN_NAME, PLUGIN_VERSION, FCVAR_SERVER|FCVAR_SPONLY, 0.0);
	
	new sBuyHandle[] = "cmdBuy";
	register_clcmd("buy", sBuyHandle, -1, g_sBlank);
	register_clcmd("buyammo1", sBuyHandle, -1, g_sBlank);
	register_clcmd("buyammo2", sBuyHandle, -1, g_sBlank);
	register_clcmd("buyequip", sBuyHandle, -1, g_sBlank);
	register_clcmd("cl_autobuy", sBuyHandle, -1, g_sBlank);
	register_clcmd("cl_rebuy", sBuyHandle, -1, g_sBlank);
	register_clcmd("cl_setautobuy", sBuyHandle, -1, g_sBlank);
	register_clcmd("cl_setrebuy", sBuyHandle, -1, g_sBlank);
	
	register_concmd("hns_status", "cmdHnsStatus", ADMIN_KICK, "<0|1> -- 0=HNS OFF   1=HNS ON");
	register_concmd("hns_scrim", "cmdScrim", ADMIN_KICK, "<0|1> -- 0=STOP SCRIM   1=START SCRIM");
	register_concmd("hns_scrimtype", "cmdScrimType", ADMIN_KICK, "<0|1|2> -- 0=VOTE TYPE   1=WIN ROUNDS   2=POINT SYSTEM");
	register_concmd("hns_captains", "cmdCaptains", ADMIN_KICK, "-- chooses two (2) random players to be captains for a pug");
	register_concmd("hns_warmup", "cmdWarmup", ADMIN_KICK, "<0|1> -- 0=STOP WARMUP   1=START WARMUP");
	
	new sPointsHandle[] = "cmdPoints";
	register_say_command("hnshelp", "cmdHelp", -1, g_sBlank);
	register_say_command("scrimhelp", "cmdScrimHelp", -1, g_sBlank);
	register_say_command("points", sPointsHandle, -1, g_sBlank);
	register_say_command("scores", sPointsHandle, -1, g_sBlank);
	register_say_command("wins", sPointsHandle, -1, g_sBlank);
	register_say_command("rounds", "cmdRounds", -1, g_sBlank);
	register_say_command("team", "cmdTeam", -1, g_sBlank);
	
	register_forward(FM_Touch, "fwdTouch", 0);
	register_forward(FM_CmdStart, "fwdCmdStart", 0);
	register_forward(FM_SetModel, "fwdSetModel", 0);
	register_forward(FM_ClientKill, "fwdClientKill", 0);
	register_forward(FM_PlayerPreThink, "fwdPlayerPreThink", 0);
	register_forward(FM_PlayerPostThink, "fwdPlayerPostThink", 0);
	register_forward(FM_AddToFullPack, "fwdAddToFullPackPost", 1);
	//register_forward(FM_GetGameDescription, "fwdGetGameDescription", 0);
	register_forward(FM_Voice_SetClientListening, "fwdSetVoice", 0);
	
	register_event("TextMsg", "eventRestartAttempt", g_sA, "2&#Game_w");
	register_clcmd("fullupdate", "cmdFullupdate", -1, g_sBlank);
	
	hns_footsteps = register_cvar("hns_footsteps", "1", 0, 0.0);
	hns_money = register_cvar("hns_money", "0", 0, 0.0);
	hns_nubslash = register_cvar("hns_nubslash", "3", 0, 0.0);
	hns_disablebuy = register_cvar("hns_disablebuy", "1", 0, 0.0);
	hns_hiders_knife = register_cvar("hns_hiders_knife", "1", 0, 0.0);
	hns_grenades[HNS_TEAM_HIDER] = register_cvar("hns_hiders_grenades", "1", 0, 0.0);
	hns_grenades_percent[HNS_TEAM_HIDER] = register_cvar("hns_hiders_grenades_percent", "100", 0, 0.0);
	hns_flashbangs[HNS_TEAM_HIDER] = register_cvar("hns_hiders_flashbangs", "2", 0, 0.0);
	hns_flashbangs_percent[HNS_TEAM_HIDER] = register_cvar("hns_hiders_flashbangs_percent", "100", 0, 0.0);
	hns_smokegren[HNS_TEAM_HIDER] = register_cvar("hns_hiders_smokegren", "1", 0, 0.0);
	hns_smokegren_percent[HNS_TEAM_HIDER] = register_cvar("hns_hiders_smokegren_percent", "100", 0, 0.0);
	hns_armor[HNS_TEAM_HIDER] = register_cvar("hns_hiders_armor", "100", 0, 0.0);
	hns_grenades[HNS_TEAM_SEEKER] = register_cvar("hns_seekers_grenades", "0", 0, 0.0);
	hns_grenades_percent[HNS_TEAM_SEEKER] = register_cvar("hns_seekers_grenades_percent", "0", 0, 0.0);
	hns_flashbangs[HNS_TEAM_SEEKER] = register_cvar("hns_seekers_flashbangs", "0", 0, 0.0);
	hns_flashbangs_percent[HNS_TEAM_SEEKER] = register_cvar("hns_seekers_flashbangs_percent", "0", 0, 0.0);
	hns_smokegren[HNS_TEAM_SEEKER] = register_cvar("hns_seekers_smokegren", "0", 0, 0.0);
	hns_smokegren_percent[HNS_TEAM_SEEKER] = register_cvar("hns_seekers_smokegren_percent", "0", 0, 0.0);
	hns_armor[HNS_TEAM_SEEKER] = register_cvar("hns_seekers_armor", "100", 0, 0.0);
	hns_hidetime = register_cvar("hns_hidetime", "10", 0, 0.0);
	hns_timersounds = register_cvar("hns_timersounds", "1", 0, 0.0);
	hns_noslowdown = register_cvar("hns_noslowdown", "0", 0, 0.0);
	hns_teamchange = register_cvar("hns_teamchange", "0", 0, 0.0);
	hns_disablekill = register_cvar("hns_disablekill", "1", 0, 0.0);
	hns_blindcolors = register_cvar("hns_blindcolors", "0 0 0 255", 0, 0.0);
	hns_hudcolors = register_cvar("hns_hudcolors", "0 255 0", 0, 0.0);
	hns_hiders_alivefrags = register_cvar("hns_hiders_alivefrags", "1", 0, 0.0);
	hns_lights = register_cvar("hns_lights", g_sLightsNormal, 0, 0.0);
	hns_visiblecommands = register_cvar("hns_visiblecommands", "0", 0, 0.0);
	hns_chooseteam = register_cvar("hns_chooseteam", "0", 0, 0.0);
	hns_semiclip = register_cvar("hns_semiclip", "1", 0, 0.0);
	hns_semiclip_alpha = register_cvar("hns_semiclip_alpha", "127", 0, 0.0);
	hns_prefix = register_cvar("hns_prefix", "[HNS]", 0, 0.0);
	hns_removebreakables = register_cvar("hns_removebreakables", "1", 0, 0.0);
	hns_noflash = register_cvar("hns_noflash", "1", 0, 0.0);
	hns_removedoors = register_cvar("hns_removedoors", "1", 0, 0.0);
	hns_noboosting = register_cvar("hns_noboosting", "1", 0, 0.0);
	hns_noboosting_damage = register_cvar("hns_noboosting_damage", "25", 0, 0.0);
	hns_noboosting_punish = register_cvar("hns_noboosting_punish", "3", 0, 0.0);
	hns_noboosting_interval = register_cvar("hns_noboosting_interval", "1.0", 0, 0.0);
	hns_warmup_godmode = register_cvar("hns_warmup_godmode", "1", 0, 0.0);
	hns_warmup_respawn = register_cvar("hns_warmup_respawn", "1", 0, 0.0);
	
	new sHideNSeek[32];
	formatex(sHideNSeek, 31, "HideNSeek v%s", PLUGIN_VERSION);
	hns_gametype = register_cvar("hns_gametype", sHideNSeek, 0, 0.0);
	
	hnss_prefix = register_cvar("hnss_prefix", "[HNS-SCRIM]", 0, 0.0);
	hnss_vote_timer = register_cvar("hnss_vote_timer", "30", 0, 0.0);
	hnss_rounds_wins = register_cvar("hnss_rounds_wins", "3", 0, 0.0);
	hnss_rounds_losses = register_cvar("hnss_rounds_losses", "5", 0, 0.0);
	hnss_rounds_savewins = register_cvar("hnss_rounds_savewins", "0", 0, 0.0);
	hnss_points_knife = register_cvar("hnss_points_knife", "1", 0, 0.0);
	hnss_points_headshot = register_cvar("hnss_points_headshot", "1", 0, 0.0);
	hnss_points_grenade = register_cvar("hnss_points_grenade", "2", 0, 0.0);
	hnss_points_kill = register_cvar("hnss_points_kill", "1", 0, 0.0);
	hnss_points_suicide = register_cvar("hnss_points_suicide", "1", 0, 0.0);
	hnss_points_teamkill = register_cvar("hnss_points_teamkill", "2", 0, 0.0);
	hnss_points_roundwin = register_cvar("hnss_points_roundwin", "1", 0, 0.0);
	hnss_points_roundlose = register_cvar("hnss_points_roundlose", "1", 0, 0.0);
	hnss_points_rounds = register_cvar("hnss_points_rounds", "10", 0, 0.0);
	
	g_BoostHud = CreateHudSyncObj();
	
	amx_vote_answers = get_cvar_pointer("amx_vote_answers");
	sv_restart = get_cvar_pointer("sv_restart");
	
	g_msgSayText = get_user_msgid("SayText");
	g_msgHideWeapon = get_user_msgid("HideWeapon");
	g_msgScreenFade = get_user_msgid("ScreenFade");
	g_msgTeamInfo = get_user_msgid("TeamInfo");
	g_msgMoney = get_user_msgid("Money");
	g_msgArmorType = get_user_msgid("ArmorType");
	
	register_message(g_msgHideWeapon, "messageHideWeapon");
	register_message(g_msgScreenFade, "messageScreenFade");
	
	register_event("ResetHUD", "eventResetHUD", g_sB);
	register_event("Money", "eventMoney", g_sB);
	register_event("HLTV", "eventNewRound", g_sA, "1=0", "2=0");
	register_event("SendAudio", "eventTerrWin", g_sA, "2=%!MRAD_terwin");
	register_event("TextMsg", "eventRestartRound", g_sA, "2&#Game_C", "2&#Game_w");
	register_event("CurWeapon", "eventCurWeapon", g_sB, "1=1");
	register_event("DeathMsg", "eventDeathMsg", g_sA, "2!0");
	
	register_logevent("logeventRoundStart", 2, "1=Round_Start");
	register_logevent("logeventRoundEnd", 2, "1=Round_End");
	
	g_MaxPlayers = global_get(glb_maxClients);
	g_MaxEntities = global_get(glb_maxEntities);
	
	copy(g_sLights, 15, g_sLightsNormal);
	set_task(1.0, "taskSetLights", TASK_ID_SETLIGHTS, g_sBlank, 0, g_sB, 0);
	
	new dir[23];
	get_configsdir(dir, 22);
	
	formatex(g_sHelpMotd, 42, "%s/hidenseek_help.txt", dir);
	formatex(g_sScrimMotd, 48, "%s/hidenseek_scrim_help.txt", dir);
	
	set_task(1.0, "taskExecuteConfig");
	
	return PLUGIN_CONTINUE;
}

public plugin_natives()
{
	register_library("hidenseek");
	register_native("hns_get_status", "_GetHnsStatus");
	register_native("hnss_get_status", "_GetScrimStatus");
	
	return PLUGIN_CONTINUE;
}

public bool:_GetHnsStatus(plugin, params)
{
	return g_bHnsOn;
}

public bool:_GetScrimStatus(plugin, params)
{
	return g_bScrimOn;
}

public client_putinserver(plr)
{
	g_bConnected[plr] = true;
	g_bAlive[plr] = false;
	g_bFirstSpawn[plr] = false;
	
	return PLUGIN_CONTINUE;
}

public client_disconnect(plr)
{
	g_bConnected[plr] = false;
	
	for( new i = 0; i < MAX_PLAYER_TASKS; i++ )
	{
		remove_task(plr + g_PlayerTasks[i], 0);
	}
	
	if( g_ScrimVoteTimer > 0 && !g_bScrimVoted[plr] )
	{
		g_bScrimVoted[plr] = true;
	
		if( check_last_vote(plr) )
		{
			g_ScrimVoteTimer = 1;
		}
	}
	
	return PLUGIN_CONTINUE;
}

public client_command(plr)
{
	if( !g_bHnsOn )
	{
		return PLUGIN_CONTINUE;
	}
	
	new sArg[13];
	if( read_argv(0, sArg, 12) > 11 )
	{
		return PLUGIN_CONTINUE;
	}
	
	if( equali(sArg, "chooseteam") && (CS_TEAM_UNASSIGNED < cs_get_user_team(plr) < CS_TEAM_SPECTATOR) )
	{
		new CsTeams:team = cs_get_user_team(plr);
		new chooseteam = get_pcvar_num(hns_chooseteam);
		
		if( team != HNS_TEAM_HIDER && team != HNS_TEAM_SEEKER
		|| chooseteam == 1
		|| chooseteam == 2 && is_user_admin(plr) )
		{
			return PLUGIN_CONTINUE;
		}
		
		return PLUGIN_HANDLED;
	}
	
	if( !get_pcvar_num(hns_disablebuy) )
	{
		return PLUGIN_CONTINUE;
	}
	
	for( new i = 0; i < MAX_BUY_COMMANDS; i++ )
	{
		if( equali(g_sBuyCommands[i], sArg, 0) )
		{
			return PLUGIN_HANDLED;
		}
	}
	
	return PLUGIN_CONTINUE;
}

public cmdBuy(plr)
{
	return (g_bHnsOn && get_pcvar_num(hns_disablebuy)) ? PLUGIN_HANDLED : PLUGIN_CONTINUE;
}

public cmdFullupdate(plr)
{
	g_bNonSpawnEvent[plr] = true;
	
	g_FwdClientCommand_post = register_forward(FM_ClientCommand, "fwdClientCommandPost", 1);
	
	return PLUGIN_CONTINUE;
}

public cmdHnsStatus(plr, level, cid)
{
	if( !cmd_access(plr, level, cid, 2) )
	{
		return PLUGIN_HANDLED;
	}
	
	new sArg[16];
	read_argv(1, sArg, 15);
	
	new bool:bOn = bool:clamp(str_to_num(sArg), 0, 1);
	
	if( bOn == g_bHnsOn )
	{
		new sPrefix[16];
		get_pcvar_string(hns_prefix, sPrefix, 15);
		
		console_print(plr, "%s HideNSeek is already o%s!", sPrefix, g_bHnsOn ? "n" : "ff");
		return PLUGIN_HANDLED;
	}
	
	g_bHnsOn = bOn;
	set_pcvar_num(sv_restart, 1);
	
	new sName[64]; /* server hostnames can be longer than player names */
	get_user_name(plr, sName, 63);
	
	hns_print(0, "^x03%s :^x01  st%sed HideNSeek!", sName, bOn ? "art" : "opp");
	
	return PLUGIN_HANDLED;
}

public cmdScrim(plr, level, cid)
{
	if( !cmd_access(plr, level, cid, 2) )
	{
		return PLUGIN_HANDLED;
	}
	
	new sArg[2];
	read_argv(1, sArg, 1);
	new bool:bScrim = bool:clamp(str_to_num(sArg), 0, 1);
	
	if( bScrim == g_bScrimOn )
	{
		console_print(plr, "[HNS] Scrim mod is already %s!", g_bScrimOn ? "on" : "off");
		return PLUGIN_HANDLED;
	}
	
	if( bScrim && !g_bHnsOn )
	{
		console_print(plr, "[HNS] HideNSeek must be on to start a scrim!");
		return PLUGIN_HANDLED;
	}
	
	new sName[64]; /* server hostnames can be long */
	get_user_name(plr, sName, 63);
	scrim_print(0, "^x03%s^x01 :  %s the HideNSeek scrim!", sName, bScrim ? "started" : "stopped");
	
	if( bScrim )
	{
		if( g_ScrimType == SCRIM_NONE )
		{
			show_scrim_vote();
		}
		else
		{
			if( g_ScrimType == SCRIM_POINTS )
			{
				/* in case of an odd number, we need to round it up one */
				g_ScrimMaxRounds = floatround(get_pcvar_float(hnss_points_rounds) / 2.0, floatround_ceil) * 2;
				
				g_PointsKnife = get_pcvar_num(hnss_points_knife);
				g_PointsHeadshot = get_pcvar_num(hnss_points_headshot);
				g_PointsGrenade = get_pcvar_num(hnss_points_grenade);
				g_PointsKill = get_pcvar_num(hnss_points_kill);
				g_PointsSuicide = get_pcvar_num(hnss_points_suicide);
				g_PointsTeamKill = get_pcvar_num(hnss_points_teamkill);
				g_PointsRoundWin = get_pcvar_num(hnss_points_roundwin);
				g_PointsRoundLose = get_pcvar_num(hnss_points_roundlose);
			}
			else if( g_ScrimType == SCRIM_ROUNDS )
			{
				g_ScrimMaxRounds = get_pcvar_num(hnss_rounds_wins);
				g_ScrimMaxLosses = get_pcvar_num(hnss_rounds_losses);
				g_ScrimSaveWins = get_pcvar_num(hnss_rounds_savewins);
			}
			
			g_ScrimWinner = CS_TEAM_UNASSIGNED;
			g_ScrimRounds[HNS_TEAM_HIDER] = 0;
			g_ScrimRounds[HNS_TEAM_SEEKER] = 0;
			g_bScrimIsDraw = false;
			g_ScrimTeams[1] = HNS_TEAM_HIDER;
			g_ScrimTeams[2] = HNS_TEAM_SEEKER;
			g_ScrimTeamNums[HNS_TEAM_HIDER] = 1;
			g_ScrimTeamNums[HNS_TEAM_SEEKER] = 2;
			g_ScrimScores[HNS_TEAM_HIDER] = 0;
			g_ScrimScores[HNS_TEAM_SEEKER] = 0;
			
			g_bScrimOn = true;
			set_pcvar_num(sv_restart, 1);
		}
	}
	else
	{
		g_bScrimOn = false;
		g_ScrimType = SCRIM_NONE;
		set_pcvar_num(sv_restart, 1);
	}
	
	return PLUGIN_HANDLED;
}

public cmdScrimType(plr, level, cid)
{
	if( !cmd_access(plr, level, cid, 2) )
	{
		return PLUGIN_HANDLED;
	}
	
	if( !g_bHnsOn )
	{
		console_print(plr, "[HNS] HideNSeek must be on to set the scrim type!");
		return PLUGIN_HANDLED;
	}
	
	if( g_bScrimOn )
	{
		console_print(plr, "[HNS] You cannot change the scrim type during a scrim!");
		return PLUGIN_HANDLED;
	}
	
	if( task_exists(TASK_ID_SCRIMVOTE, 0) )
	{
		console_print(plr, "[HNS] A vote is already determining the scrim type!");
		return PLUGIN_HANDLED;
	}
	
	new sArg[2];
	read_argv(1, sArg, 1);
	new type = str_to_num(sArg);
	
	if( g_ScrimType == type )
	{
		console_print(plr, "[HNS] This is already the scrim type!");
		return PLUGIN_HANDLED;
	}
	
	new sName[64]; /* server hostnames can be long */
	get_user_name(plr, sName, 63);
	switch( type )
	{
		case SCRIM_ROUNDS: scrim_print(0, "^x03%s^x01 :  set the scrim type to Win %i Rounds!", sName, get_pcvar_num(hnss_rounds_wins));
		case SCRIM_POINTS: scrim_print(0, "^x03%s^x01 :  set the scrim type to Point System!", sName);
		default:
		{
			type = SCRIM_NONE;
			scrim_print(0, "^x03%s^x01 :  set the scrim type to none!", sName);
		}
	}
	
	g_ScrimType = type;
	
	return PLUGIN_HANDLED;
}

public cmdCaptains(plr, level, cid)
{
	if( !cmd_access(plr, level, cid, 1) )
	{
		return PLUGIN_HANDLED;
	}
	
	new players[32], pnum;
	for( new i = 1; i <= g_MaxPlayers; i++ )
	{
		if( g_bConnected[i] )
		{
			players[pnum++] = i;
		}
	}
	
	new rand = random(pnum);
	new captain1 = players[rand];
	
	for( new i = rand; i < pnum; i++ )
	{
		if( (i + 1) == pnum )
		{
			continue;
		}
		
		players[i] = players[i + 1];
	}
	
	new captain2 = (pnum > 0) ? players[random(--pnum)] : 0;
	
	new sName1[32], sName2[32];
	get_user_name(captain1, sName1, 31);
	if( captain2 )	get_user_name(captain2, sName2, 31);
	else		copy(sName2, 31, "Player Not Available");
	
	scrim_print(0, "Captains will be:^x03 %s^x01 and^x03 %s", sName1, sName2);
	
	return PLUGIN_HANDLED;
}

public cmdWarmup(plr, level, cid)
{
	if( !cmd_access(plr, level, cid, 2) )
	{
		return PLUGIN_HANDLED;
	}
	
	new sArg[2];
	read_argv(1, sArg, 1);
	new bool:bWarmup = bool:clamp(str_to_num(sArg), 0, 1);
	
	if( bWarmup == g_bWarmup )
	{
		console_print(plr, "[HNS] Warmup is already %s!", g_bWarmup ? "on" : "off");
		return PLUGIN_HANDLED;
	}
	
	if( bWarmup && !g_bHnsOn )
	{
		console_print(plr, "[HNS] HideNSeek must be on to start warmup!");
		return PLUGIN_HANDLED;
	}
	
	new sName[64]; /* server hostnames can be long */
	get_user_name(plr, sName, 63);
	hns_print(0, "^x03%s^x01 :  %s the HideNSeek warmup!", sName, bWarmup ? "started" : "stopped");
	
	set_pcvar_num(sv_restart, 1);
	
	return PLUGIN_HANDLED;
}

public cmdHelp(plr)
{
	if( file_exists(g_sHelpMotd) )
	{
		new sText[2500];
		
		new f = fopen(g_sHelpMotd, "rt"), sData[512];
		while( !feof(f) )
		{
			fgets(f, sData, 511);
			add(sText, 2499, sData, 0);
		}
		fclose(f);
		
		new sTeamChange[64];
		copy(sTeamChange, 63, "The teams will switch ");
		new info = get_pcvar_num(hns_teamchange);
		if( info > 0 )
		{
			format(sTeamChange, 63, "%safter %i rounds have ended", sTeamChange, info);
		}
		else
		{
			add(sTeamChange, 63, "when Seekers win the round");
		}
		
		new sHiderEquipment[512];
		if( get_pcvar_num(hns_hiders_knife) == 2 )
		{
			copy(sHiderEquipment, 511, "Broken knife<br>");
		}
		info = get_pcvar_num(hns_grenades[HNS_TEAM_HIDER]);
		new percent = get_pcvar_num(hns_grenades_percent[HNS_TEAM_HIDER]);
		if( info > 0 && percent > 0 )
		{
			format(sHiderEquipment, 511, "%s%i HE Grenade%s", sHiderEquipment, info, info == 1 ? g_sBlank : g_sS);
			if( percent < 100 )
			{
				format(sHiderEquipment, 511, "%s (%i%% chance per grenade)<br>", sHiderEquipment, percent);
			}
			else
			{
				add(sHiderEquipment, 511, "<br>", 0);
			}
		}
		info = get_pcvar_num(hns_flashbangs[HNS_TEAM_HIDER]);
		percent = get_pcvar_num(hns_flashbangs_percent[HNS_TEAM_HIDER]);
		if( info > 0 && percent > 0 )
		{
			format(sHiderEquipment, 511, "%s%i Flashbang%s", sHiderEquipment, info, info == 1 ? g_sBlank : g_sS);
			if( percent < 100 )
			{
				format(sHiderEquipment, 511, "%s (%i%% chance per flashbang)<br>", sHiderEquipment, percent);
			}
			else
			{
				add(sHiderEquipment, 511, "<br>", 0);
			}
		}
		info = get_pcvar_num(hns_smokegren[HNS_TEAM_HIDER]);
		percent = get_pcvar_num(hns_smokegren_percent[HNS_TEAM_HIDER]);
		if( info > 0 && percent > 0 )
		{
			format(sHiderEquipment, 511, "%s%i Smoke Grenade%s", sHiderEquipment, info, info == 1 ? g_sBlank : g_sS);
			if( percent < 100 )
			{
				format(sHiderEquipment, 511, "%s (%i%% chance per smoke grenade)<br>", sHiderEquipment, percent);
			}
			else
			{
				add(sHiderEquipment, 511, "<br>", 0);
			}
		}
		info = get_pcvar_num(hns_armor[HNS_TEAM_HIDER]);
		format(sHiderEquipment, 511, "%sArmor: %i", sHiderEquipment, info);
		
		new sSeekerEquipment[512];
		copy(sSeekerEquipment, 511, "A Knife");
		info = get_pcvar_num(hns_grenades[HNS_TEAM_SEEKER]);
		percent = get_pcvar_num(hns_grenades_percent[HNS_TEAM_SEEKER]);
		if( info > 0 && percent > 0 )
		{
			format(sSeekerEquipment, 511, "%s<br>%i HE Grenade%s", sSeekerEquipment, info, info == 1 ? g_sBlank : g_sS);
			if( percent < 100 )
			{
				format(sSeekerEquipment, 511, "%s (%i%% chance per grenade)", sSeekerEquipment, percent);
			}
		}
		info = get_pcvar_num(hns_flashbangs[HNS_TEAM_SEEKER]);
		percent = get_pcvar_num(hns_flashbangs_percent[HNS_TEAM_SEEKER]);
		if( info > 0 && percent > 0 )
		{
			format(sSeekerEquipment, 511, "%s<br>%i Flashbang%s", sSeekerEquipment, info, info == 1 ? g_sBlank : g_sS);
			if( percent < 100 )
			{
				format(sSeekerEquipment, 511, "%s (%i%% chance per flashbang)", sSeekerEquipment, percent);
			}
		}
		info = get_pcvar_num(hns_smokegren[HNS_TEAM_SEEKER]);
		percent = get_pcvar_num(hns_smokegren_percent[HNS_TEAM_SEEKER]);
		if( info > 0 && percent > 0 )
		{
			format(sSeekerEquipment, 511, "%s<br>%i Smoke Grenade%s", sSeekerEquipment, info, info == 1 ? g_sBlank : g_sS);
			if( percent < 100 )
			{
				format(sSeekerEquipment, 511, "%s (%i%% chance per smoke grenade)", sSeekerEquipment, percent);
			}
		}
		info = get_pcvar_num(hns_armor[HNS_TEAM_SEEKER]);
		format(sSeekerEquipment, 511, "%s<br>Armor: %i", sSeekerEquipment, info);
		
		
		format(sText, 2499, sText, PLUGIN_NAME, PLUGIN_VERSION, PLUGIN_AUTHOR, PLUGIN_NAME, g_sTeamNames[HNS_TEAM_HIDER], g_sTeamNames[HNS_TEAM_SEEKER], sTeamChange, sHiderEquipment, sSeekerEquipment);
		show_motd(plr, sText, "HideNSeek Help");
	}
	else
	{
		hns_print(plr, "^x03HideNSeek Help^x01 does not exist for this server.");
	}
	
	return get_pcvar_num(hns_visiblecommands) ? PLUGIN_CONTINUE : PLUGIN_HANDLED;
}

public cmdScrimHelp(plr)
{
	if( file_exists(g_sScrimMotd) )
	{
		new sText[3000];
		
		new f = fopen(g_sScrimMotd, "rt"), sData[512];
		while( !feof(f) )
		{
			fgets(f, sData, 511);
			add(sText, 2999, sData, 0);
		}
		fclose(f);
		
		new rounds = get_pcvar_num(hnss_rounds_wins);
		
		new sRounds[32];
		formatex(sRounds, 31, "%i round%s", rounds, (rounds != 1) ? "s in a row" : g_sBlank);
		
		new sSave[96];
		if( get_pcvar_num(hnss_rounds_savewins) && rounds > 1 )
		{
			copy(sSave,95, "<br>However, the amount of rounds you won will stay with you if you become hiders again!");
		}
		else
		{
			copy(sSave,95, "<br>The amount of rounds you won will reset and you will start over next time you are a hider!");
		}
		
		new losses = get_pcvar_num(hnss_rounds_losses), sLosses[96];
		if( losses )
		{
			formatex(sLosses, 95, "<br>After the teams switch %i time%s, the scrim will end in a draw.", losses, (losses != 1) ? g_sS : g_sBlank);
		}
		
		new sPoints[512], len;
		
		new points = get_pcvar_num(hnss_points_knife);
		if( points )
		{
			len += format(sPoints[len], 511-len, "Earn %i point%s for killing with a knife<br>", points, (points != 1) ? g_sS : g_sBlank);
		}
		
		points = get_pcvar_num(hnss_points_headshot);
		if( points )
		{
			len += format(sPoints[len], 511-len, "Earn %i extra point%s for your kill if you get a headshot!<br>", points, (points != 1) ? g_sS : g_sBlank);
		}
		
		points = get_pcvar_num(hnss_points_grenade);
		if( points )
		{
			len += format(sPoints[len], 511-len, "Earn %i point%s for killing with a grenade or frostgrenade!<br>", points, (points != 1) ? g_sS : g_sBlank);
		}
		
		points = get_pcvar_num(hnss_points_kill);
		if( points )
		{
			len += format(sPoints[len], 511-len, "Earn %i point%s for killing with some else that was already described<br>", points, (points != 1) ? g_sS : g_sBlank);
		}
		
		points = get_pcvar_num(hnss_points_suicide);
		if( points )
		{
			len += format(sPoints[len], 511-len, "Lose %i point%s for killing yourself<br>", points, (points != 1) ? g_sS : g_sBlank);
		}
		
		points = get_pcvar_num(hnss_points_teamkill);
		if( points )
		{
			len += format(sPoints[len], 511-len, "Lose %i point%s for killing your teammate!<br>", points, (points != 1) ? g_sS : g_sBlank);
		}
		
		points = get_pcvar_num(hnss_points_roundwin);
		if( points )
		{
			len += format(sPoints[len], 511-len, "Earn %i point%s for winning the round!<br>", points, (points != 1) ? g_sS : g_sBlank);
		}
		
		points = get_pcvar_num(hnss_points_roundlose);
		if( points )
		{
			len += format(sPoints[len], 511-len, "Lose %i point%s for losing the round<br>", points, (points != 1) ? g_sS : g_sBlank);
		}
		
		new ps_rounds = get_pcvar_num(hnss_points_rounds);
		
		format(sText, 2999, sText, rounds, (rounds != 1) ? g_sS : g_sBlank, sRounds, sRounds, sSave, sLosses, sPoints, ps_rounds, (ps_rounds != 1) ? g_sS : g_sBlank, ps_rounds, (ps_rounds != 1) ? g_sS : g_sBlank);
		
		show_motd(plr, sText, "HideNSeek Scrim Help");
	}
	else
	{
		scrim_print(plr, "^x03HideNSeek Scrim Help^x01 does not exist for this server.");
	}
	
	return get_pcvar_num(hns_visiblecommands) ? PLUGIN_CONTINUE : PLUGIN_HANDLED;
}

public cmdPoints(plr)
{
	if( g_bScrimOn )
	{
		switch( g_ScrimType )
		{
			case SCRIM_POINTS:
			{
				scrim_print(0, "Scrim scores:^x03 Team 1 [%i]^x01 ::^x03 Team 2 [%i]", g_ScrimScores[g_ScrimTeams[1]], g_ScrimScores[g_ScrimTeams[2]]);
			}
			case SCRIM_ROUNDS:
			{
				scrim_print(0, "Hiders have won^x03 %i / %i^x01 rounds!", g_ScrimRounds[HNS_TEAM_HIDER], g_ScrimMaxRounds);
			}
		}
	}
	else
	{
		scrim_print(plr, "There is no scrim taking place.");
	}
	
	return get_pcvar_num(hns_visiblecommands) ? PLUGIN_CONTINUE : PLUGIN_HANDLED;
}

public cmdRounds(plr)
{
	if( g_bScrimOn )
	{
		switch( g_ScrimType )
		{
			case SCRIM_POINTS:
			{
				new half = (g_ScrimMaxRounds / 2), rounds;
				if( g_ScrimRounds[HNS_TEAM_HIDER] < half )
				{
					rounds = half - g_ScrimRounds[HNS_TEAM_HIDER];
				}
				else
				{
					rounds = g_ScrimMaxRounds - g_ScrimRounds[HNS_TEAM_HIDER];
				}
				
				scrim_print(0, "There %s^x03 %i round%s^x01 left in the^x03 half.", (rounds != 1) ? "are" : "is", rounds, (rounds != 1) ? g_sS : g_sBlank);
				
				rounds = g_ScrimMaxRounds - g_ScrimRounds[HNS_TEAM_HIDER];
				scrim_print(0, "There %s^x03 %i round%s^x01 left in the^x03 scrim.", (rounds != 1) ? "are" : "is", rounds, (rounds != 1) ? g_sS : g_sBlank);
			}
			case SCRIM_ROUNDS:
			{
				new rounds = g_ScrimMaxRounds - g_ScrimRounds[HNS_TEAM_HIDER];
				scrim_print(0, "Hiders need^x03 %i round%s^x01 to win the scrim!", rounds, (rounds != 1) ? g_sS : g_sBlank);
			}
		}
	}
	else
	{
		scrim_print(plr, "There is no scrim taking place.");
	}
	
	return get_pcvar_num(hns_visiblecommands) ? PLUGIN_CONTINUE : PLUGIN_HANDLED;
}

public cmdTeam(plr)
{
	if( g_bScrimOn )
	{
		switch( g_ScrimType )
		{
			case SCRIM_POINTS:
			{
				scrim_print(plr, "You are on^x03 Team %i^x01!", g_ScrimTeamNums[cs_get_user_team(plr)]);
			}
			case SCRIM_ROUNDS:
			{
				new CsTeams:team = cs_get_user_team(plr);
				if( team == HNS_TEAM_HIDER )
				{
					scrim_print(plr, "You are on the^x03 Hiding^x01 team!");
				}
				else if( team == HNS_TEAM_SEEKER )
				{
					scrim_print(plr, "You are on the^x03 Seeking^x01 team!");
				}
				else
				{
					scrim_print(plr, "You are not on a scrim team!");
				}
			}
		}
	}
	else
	{
		scrim_print(plr, "There is no scrim taking place.");
	}
	
	return get_pcvar_num(hns_visiblecommands) ? PLUGIN_CONTINUE : PLUGIN_HANDLED;
}

public fwdClientCommandPost(plr)
{
	unregister_forward(FM_ClientCommand, g_FwdClientCommand_post, 1);
	
	g_bNonSpawnEvent[plr] = false;
	
	return FMRES_HANDLED;
}

public fwdSpawn(ent)
{
	if( !pev_valid(ent) || ent == g_HostageEnt )
	{
		return FMRES_IGNORED;
	}
	
	new sClass[32];
	pev(ent, pev_classname, sClass, 31);
	
	for( new i = 0; i < MAX_REMOVED_ENTITIES; i++ )
	{
		if( equal(sClass, g_sRemoveEntities[i]) )
		{
			engfunc(EngFunc_RemoveEntity, ent);
			return FMRES_SUPERCEDE;
		}
	}
	
	return FMRES_IGNORED;
}

public fwdTouch(booster, plr)
{
	if( !g_bHnsOn
	|| !pev_valid(booster) || !pev_valid(plr)
	|| !(0 < booster <= g_MaxPlayers) || !(0 < plr <= g_MaxPlayers)
	|| !g_bAlive[booster] || !g_bAlive[plr] )
	{
		return FMRES_IGNORED;
	}
	
	new boosting = get_pcvar_num(hns_noboosting);
	
	if( boosting == get_pcvar_num(hns_semiclip)
	|| boosting != 2 && !(boosting == 1 && cs_get_user_team(booster) == cs_get_user_team(plr)) )
	{
		return FMRES_IGNORED;
	}
	
	new Float:vBoosterOrigin[3], Float:vPlrOrigin[3];
	pev(booster, pev_origin, vBoosterOrigin);
	pev(plr, pev_origin, vPlrOrigin);
	
	if( !(49.0 < (vPlrOrigin[2] - vBoosterOrigin[2]) < 73.0) )
	{
		return FMRES_IGNORED;
	}
	
	switch( get_pcvar_num(hns_noboosting_punish) )
	{
		case 3:
		{
			handle_booster(booster);
			handle_booster(plr);
		}
		case 2:
		{
			handle_booster(booster);
		}
		case 1:
		{
			handle_booster(plr);
		}
	}
	
	return FMRES_IGNORED;
}

public fwdCmdStart(plr, ucHandle, seed)
{
	if( !g_bHnsOn || !g_bAlive[plr] )
	{
		return FMRES_IGNORED;
	}
	
	static clip, ammo;
	if( get_user_weapon(plr, clip, ammo) != CSW_KNIFE )
	{
		return FMRES_IGNORED;
	}
	
	new CsTeams:team = cs_get_user_team(plr);
	
	if( team == HNS_TEAM_HIDER )
	{
		new button = get_uc(ucHandle, UC_Buttons);
		
		if( button&IN_ATTACK )
		{
			button &= ~IN_ATTACK;
		}
		if( button&IN_ATTACK2 )
		{
			button &= ~IN_ATTACK2;
		}
		
		set_uc(ucHandle, UC_Buttons, button);
		
		return FMRES_SUPERCEDE;
	}
	else if( team == HNS_TEAM_SEEKER )
	{
		if( g_bDisableSlash )
		{
			new button = get_uc(ucHandle, UC_Buttons);
			
			if( button&IN_ATTACK )
			{
				button &= ~IN_ATTACK;
				button |= IN_ATTACK2;
			}
			
			set_uc(ucHandle, UC_Buttons, button);
			
			return FMRES_SUPERCEDE;
		}
	}
	
	return FMRES_IGNORED;
}

public fwdSetModel(ent, sModel[])
{
	if( !g_bHnsOn )
	{
		return FMRES_IGNORED;
	}
	
	if( !pev_valid(ent) || !equal(sModel, "models/w_", 9) || equal(sModel, "models/w_weaponbox.mdl", 0) )
	{
		return FMRES_IGNORED;
	}
	
	new owner = pev(ent, pev_owner);
	if( !(0 < owner <= g_MaxPlayers) )
	{
		return FMRES_IGNORED;
	}
	
	new sClass[32];
	pev(ent, pev_classname, sClass, 31);
	
	if( equal(sClass, "weapon_shield", 0) )
	{
		set_pev(ent, pev_effects, EF_NODRAW);
		set_task(0.1, "taskRemoveShield", ent);
		
		return FMRES_IGNORED;
	}
	
	if( !equal(sClass, "weaponbox", 0) )
	{
		return FMRES_IGNORED;
	}
	
	for( new i = g_MaxPlayers + 1; i <= g_MaxEntities; i++ )
	{
		if( !pev_valid(i) )
		{
			continue;
		}
		
		if( pev(i, pev_owner) == ent )
		{
			dllfunc(DLLFunc_Think, ent);
			break;
		}
	}
	
	return FMRES_IGNORED;
}

public fwdClientKill(plr)
{
	if( !g_bHnsOn )
	{
		return FMRES_IGNORED;
	}
	
	if( get_pcvar_num(hns_disablekill) )
	{
		new Float:fGametime = get_gametime();
		if( fGametime >= g_fKillMsgDelay[plr] )
		{
			g_fKillMsgDelay[plr] = fGametime + 1.0;
			
			hns_print(plr, "You cannot kill yourself during HideNSeek!");
		}
		
		return FMRES_SUPERCEDE;
	}
	
	return FMRES_IGNORED;
}

public fwdPlayerPreThink(plr)
{
	if( !g_bHnsOn )
	{
		return FMRES_IGNORED;
	}
	
	new semiclip = get_pcvar_num(hns_semiclip);
	
	if( g_bAlive[plr] )
	{
		new CsTeams:team = cs_get_user_team(plr);
		if( g_HideTimer > 0 && team == HNS_TEAM_SEEKER )
		{
			set_pev(plr, pev_maxspeed, -1.0);
			set_pev(plr, pev_velocity, Float:{0.0, 0.0, 0.0});
			//set_pev(plr, pev_flags, pev(plr, pev_flags) | FL_FROZEN);
		}
		
		new footsteps = get_pcvar_num(hns_footsteps);
		if( footsteps && (footsteps == 3 || footsteps == _:team) )
		{
			set_pev(plr, pev_flTimeStepSound, 999);
		}
		
		if( get_pcvar_num(hns_noslowdown) )
		{
			set_pev(plr, pev_fuser2, 0.0);
		}
		
		if( g_bWarmup && get_pcvar_num(hns_warmup_godmode) )
		{
			fm_set_user_godmode(plr, 1);
		}
		
		if( semiclip )
		{
			// thanks Jon for code
			
			new target, body;
			get_user_aiming(plr, target, body, 9999);
			
			if( 0 < target <= g_MaxPlayers && g_bAlive[target] )
			{
				new CsTeams:targetTeam = cs_get_user_team(target);
				if( semiclip == 2 || targetTeam == team )
				{
					new sName[32];
					get_user_name(target, sName, 31);
					
					new sMessage[64];
					if( targetTeam == team )
					{
						formatex(sMessage, 63, "Friend: %s^nHealth: %i", sName, get_user_health(target));
					}
					else
					{
						formatex(sMessage, 63, "Enemy: %s", sName);
					}
					
					if( targetTeam == CS_TEAM_CT )
					{
						set_hudmessage(0, 63, 127, -1.0, -1.0, 0, 0.0, 0.1, 0.0, 0.0, -1);
					}
					else if( targetTeam == CS_TEAM_T )
					{
						set_hudmessage(127, 0, 0, -1.0, -1.0, 0, 0.0, 0.1, 0.0, 0.0, -1);
					}
					
					show_hudmessage(plr, "%s", sMessage);
				}
			}
		}
	}
	
	static LastThink, i;
	
	if( plr < LastThink ) // player think loop started again
	{
		for( i = 1; i <= g_MaxPlayers; i++ )
		{
			if( !g_bConnected[i] || !g_bAlive[i] )
			{
				g_bSolid[i] = false;
				continue;
			}
			
			g_Team[i] = cs_get_user_team(i);
			g_bSolid[i] = bool:(pev(i, pev_solid) == SOLID_SLIDEBOX);
		}
	}
	
	LastThink = plr;
	
	if( !g_bSolid[plr] || !semiclip )
	{
		return FMRES_IGNORED;
	}
	
	for( i = 1; i <= g_MaxPlayers; i++ )
	{
		if( !g_bSolid[i] || g_bRestoreSolid[i] || i == plr )
		{
			continue;
		}
		
		if( semiclip == 2 || g_Team[plr] == g_Team[i] )
		{
			set_pev(i, pev_solid, SOLID_NOT);
			g_bRestoreSolid[i] = true;
		}
	}
	
	return FMRES_IGNORED;
}

public fwdPlayerPostThink(plr)
{
	static i;
	
	for( i = 1; i <= g_MaxPlayers; i++ )
	{
		if( g_bRestoreSolid[i] )
		{
			set_pev(i, pev_solid, SOLID_SLIDEBOX);
			g_bRestoreSolid[i] = false;
		}
	}
	
	return FMRES_IGNORED;
}

public fwdAddToFullPackPost(es, e, ent, host, hostflags, player, pSet)
{
	if( !g_bHnsOn )
	{
		return FMRES_IGNORED;
	}
	
	if( player )
	{
		if( g_bSolid[host] && g_bSolid[ent] )
		{
			new semiclip = get_pcvar_num(hns_semiclip);
			if( semiclip == 2 || g_Team[host] == g_Team[ent] )
			{
				set_es(es, ES_Solid, SOLID_NOT);
				
				static Float:fOldAlpha;
				
				new Float:fAlpha = get_pcvar_float(hns_semiclip_alpha);
				if( fAlpha < 255.0 )
				{
					set_es(es, ES_RenderMode, kRenderTransAlpha);
					set_es(es, ES_RenderAmt, fAlpha);
				}
				else if( fOldAlpha < 255.0 )
				{
					set_es(es, ES_RenderMode, kRenderNormal);
					set_es(es, ES_RenderAmt, 16.0);
				}
				
				fOldAlpha = fAlpha;
			}
		}
	}
	
	return FMRES_IGNORED;
}

public fwdGetGameDescription()
{
	if( !g_bHnsOn )
	{
		return FMRES_IGNORED;
	}
	
	new sGameType[32];
	get_pcvar_string(hns_gametype, sGameType, 31);
	
	if( !strlen(sGameType) || had_older_version(sGameType) )
	{
		formatex(sGameType, 31, "HideNSeek v%s", PLUGIN_VERSION);
		
		set_pcvar_string(hns_gametype, sGameType);
	}
	
	forward_return(FMV_STRING, sGameType);
	return FMRES_SUPERCEDE;
}

public fwdPlayerSpawn(plr)
{
	g_bAlive[plr] = true;
	
	if( !g_bHnsOn )
	{
		return PLUGIN_CONTINUE;
	}
	
	new CsTeams:team = cs_get_user_team(plr);
	if( team != HNS_TEAM_SEEKER && team != HNS_TEAM_HIDER )
	{
		return PLUGIN_CONTINUE;
	}
	
	if( !g_bFirstSpawn[plr] )
	{
		show_plugin_info(plr);
		
		set_task(360.0, "taskShowPluginInfo", TASK_ID_SHOWPLUGININFO + plr, g_sBlank, 0, g_sB, 0);
		
		g_bFirstSpawn[plr] = true;
	}
	
	set_task(0.3, "taskStripWeapons", plr + TASK_ID_STRIPWEAPONS, g_sBlank, 0, g_sBlank, 0);
	
	new param[2];
	param[0] = _:team;
	set_task(0.6, "taskGiveKnife", plr + TASK_ID_GIVEKNIFE, param, 2, g_sBlank, 0);
	set_task(0.9, "taskCheckModel", plr + TASK_ID_CHECKMODEL, param, 2, g_sBlank, 0);
	
	if( g_bWeaponsGiven )
	{
		set_task(0.6, "taskGiveWeapons", plr + TASK_ID_GIVEWEAPONS, param, 2, g_sBlank, 0);
	}
	
	if( g_bScrimOn && g_ScrimType == SCRIM_POINTS )
	{
		new CsTeams:team1 = g_ScrimTeams[1];
		new CsTeams:team2 = g_ScrimTeams[2];
		
		scrim_print(plr, "You are on^x03 Team %i^x01!", g_ScrimTeamNums[cs_get_user_team(plr)]);
		scrim_print(plr, "Scrim scores:^x03 Team 1 [%i]^x01 ::^x03 Team 2 [%i]", g_ScrimScores[team1], g_ScrimScores[team2]);
	}
	
	return PLUGIN_CONTINUE;
}

public fwdSetVoice(receiver, sender, bool:bListen)
{
	if( !g_bConnected[receiver]
	|| !g_bConnected[sender]
	|| receiver == sender
	|| !g_bScrimOn )
	{
		return FMRES_IGNORED;
	}
	
	if( cs_get_user_team(receiver) == cs_get_user_team(sender) )
	{
		engfunc(EngFunc_SetClientListening, receiver, sender, 1);
	}
	else
	{
		engfunc(EngFunc_SetClientListening, receiver, sender, 0);
	}
	
	return FMRES_SUPERCEDE;
}

public messageHideWeapon(msgid, dest, plr)
{
	if( !g_bHnsOn )
	{
		return PLUGIN_CONTINUE;
	}
	
	if( get_pcvar_num(hns_money) == 0 )
	{
		set_msg_arg_int(1, ARG_BYTE, get_msg_arg_int(1)|HIDE_MONEY);
	}
	
	return PLUGIN_CONTINUE;
}

public messageScreenFade(msgid, dest, plr)
{
	if( !g_bHnsOn )
	{
		return PLUGIN_CONTINUE;
	}
	
	new noflash = get_pcvar_num(hns_noflash);
	if( !noflash )
	{
		return PLUGIN_CONTINUE;
	}
	
	if( get_msg_arg_int(4) == 255 && get_msg_arg_int(5) == 255 && get_msg_arg_int(6) == 255 )
	{
		// flashbang
		
		if( noflash == _:cs_get_user_team(plr) )
		{
			return PLUGIN_HANDLED;
		}
	}
	
	return PLUGIN_CONTINUE;
}

public eventRestartAttempt()
{
	new players[32], pnum;
	get_players(players, pnum, g_sA);
	
	for( new i = 0; i < pnum; i++ )
	{
		g_bNonSpawnEvent[players[i]] = true;
	}
	
	return PLUGIN_CONTINUE;
}

public eventResetHUD(plr)
{
	if( g_bHnsOn && get_pcvar_num(hns_money) == 0 )
	{
		make_HideWeapon(plr, HIDE_MONEY);
	}
	
	if( is_user_alive(plr) )
	{
		if( g_bNonSpawnEvent[plr] )
		{
			g_bNonSpawnEvent[plr] = false;
		}
		else
		{
			fwdPlayerSpawn(plr);
		}
	}
	
	return PLUGIN_CONTINUE;
}

public eventMoney(plr)
{
	if( !g_bHnsOn )
	{
		return PLUGIN_CONTINUE;
	}
	
	new money = get_pcvar_num(hns_money);
	money = clamp(money, -1, 16000);
	
	if( money >= 0 )
	{
		cs_set_user_money(plr, money, 0);
	}
	if( money == 0 && g_OldMoney != 0 )
	{
		make_HideWeapon(plr, HIDE_MONEY);
	}
	
	g_OldMoney = money;
	
	return PLUGIN_HANDLED;
}

public eventNewRound()
{
	if( !g_bHnsOn )
	{
		return PLUGIN_CONTINUE;
	}
	
	if( g_bDisableSlash )
	{
		new rounds = get_pcvar_num(hns_nubslash);
		if( rounds > 0 && g_RoundsLost >= rounds )
		{
			hns_print(0, "Seekers can now use nubslash after losing %i round%s!",\
				rounds, (rounds == 1) ? g_sBlank : "s in a row");
			
			g_bDisableSlash = false;
		}
	}
	
	g_HideTimer = get_pcvar_num(hns_hidetime);
	
	return PLUGIN_CONTINUE;
}

public eventTerrWin()
{
	if( g_bDisableSlash )
	{
		g_RoundsLost++;
	}
	
	return PLUGIN_CONTINUE;
}

public eventRestartRound()
{
	g_RoundsLost = 0;
	g_RoundsEnded = 0;
	g_bDisableSlash = true;
	
	g_bWeaponsGiven = false;
	
	g_HideTimer = -1;
	
	if( !g_bScrimOn
	|| g_ScrimType != SCRIM_ROUNDS
	|| !g_ScrimSaveWins )
	{
		g_ScrimRounds[HNS_TEAM_HIDER] = 0;
	}
	
	return PLUGIN_CONTINUE;
}

public eventCurWeapon(plr)
{
	if( !g_bHnsOn )
	{
		return PLUGIN_CONTINUE;
	}
	
	if( cs_get_user_team(plr) == HNS_TEAM_HIDER && get_pcvar_num(hns_hiders_knife) == 1 )
	{
		new sModel[32];
		
		pev(plr, pev_viewmodel2, sModel, 31);
		if( equali(sModel, g_sKnifeModel_v, 0) )
		{
			set_pev(plr, pev_viewmodel2, g_sBlank);
		}
		
		pev(plr, pev_weaponmodel2, sModel, 31);
		if( equali(sModel, g_sKnifeModel_w, 0) )
		{
			set_pev(plr, pev_weaponmodel2, g_sBlank);
		}
	}
	
	return PLUGIN_CONTINUE;
}

public TaskRespawn(plr)
{
	// thanks GHW_Chronic & MeRcyLeZZ
	set_pev(plr, pev_deadflag, DEAD_RESPAWNABLE);
	dllfunc(DLLFunc_Think, plr);
}

public eventDeathMsg()
{
	new victim = read_data(2);
	g_bAlive[victim] = false;
	
	if( g_bWarmup && get_pcvar_num(hns_warmup_respawn) )
	{
		set_task(1.0, "TaskRespawn", victim);
	}
	
	if( !g_bScrimOn
	|| g_ScrimType != SCRIM_POINTS )
	{
		return PLUGIN_CONTINUE;
	}
	
	new sNameVictim[32];
	get_user_name(victim, sNameVictim, 31);
	
	new CsTeams:vTeam = cs_get_user_team(victim);
	
	new killer = read_data(1);
	if( !killer || killer == victim )
	{
		g_ScrimScores[vTeam] -= g_PointsSuicide;
		
		scrim_print(0, "^x03%s^x01 lost^x03 %i point%s^x01 from their^x03 team's score^x01 for^x03 suiciding^x01!", sNameVictim, g_PointsSuicide, g_PointsSuicide == 1 ? "" : "s");
		
		return PLUGIN_CONTINUE;
	}
	
	new sNameKiller[32];
	get_user_name(killer, sNameKiller, 31);
	
	new CsTeams:kTeam = cs_get_user_team(killer);
	
	if( kTeam == vTeam )
	{
		g_ScrimScores[vTeam] -= g_PointsTeamKill;
		
		scrim_print(0, "^x03%s^x01 lost^x03 %i point%s^x01 from their^x03 team's score^x01 for^x03 killing a teammate^x01!", sNameKiller, g_PointsTeamKill, g_PointsKill == 1 ? "" : "s");
		
		return PLUGIN_CONTINUE;
	}
	
	new sWeapon[32];
	read_data(4, sWeapon, 31);
	
	if( equali(sWeapon, "grenade", 0) || equali(sWeapon, "frostgrenade", 0) )
	{
		g_ScrimScores[kTeam] += g_PointsGrenade;
		
		new sMessage[192]; /* vformat() only allows 3 arguments max ... lame */
		formatex(sMessage, 191, "^x03%s^x01 gained^x03 %i point%s^x01 for their^x03 team's score^x01 for^x03 killing %s with a %s^x01!", sNameKiller, g_PointsGrenade, g_PointsGrenade == 1 ? "" : "s", sNameVictim, sWeapon);
		scrim_print(0, "%s", sMessage);
		
		return PLUGIN_CONTINUE;
	}
	
	if( equali(sWeapon, "knife", 0) )
	{
		g_ScrimScores[kTeam] += g_PointsKnife;
		
		new sMessage[192];
		formatex(sMessage, 191, "^x03%s^x01 gained^x03 %i point%s^x01 for their^x03 team's score^x01 for^x03 killing %s with a knife!", sNameKiller, g_PointsKnife, g_PointsKnife == 1 ? "" : "s", sNameVictim);
		scrim_print(0, "%s", sMessage);
	}
	else
	{
		g_ScrimScores[kTeam] += g_PointsKill;
		
		new sMessage[192]; /* vformat() only allows 3 arguments max ... lame */
		formatex(sMessage, 191, "^x03%s^x01 gained^x03 %i point%s^x01 for their^x03 team's score^x01 for^x03 killing %s^x01!", sNameKiller, g_PointsKill, g_PointsKill == 1 ? "s" : "", sNameVictim);
		scrim_print(0, "%s", sMessage);
	}
	
	if( read_data(3) )
	{
		g_ScrimScores[kTeam] += g_PointsHeadshot;
		
		scrim_print(0, "^x03%s^x01 gained^x03 %d extra point%s^x01 for getting a^x03 headshot^x01!", sNameKiller, g_PointsHeadshot, g_PointsHeadshot == 1 ? "" : "s");
	}
	
	return PLUGIN_CONTINUE;
}

public logeventRoundStart()
{
	if( !g_bHnsOn )
	{
		if( g_bRemovedBreakables )
		{
			g_bRemovedBreakables = restore_entities(g_sClassBreakable);
		}
		
		return PLUGIN_CONTINUE;
	}
	
	if( get_pcvar_num(hns_removebreakables) )
	{
		g_bRemovedBreakables = remove_entities(g_sClassBreakable);
	}
	else if( g_bRemovedBreakables )
	{
		g_bRemovedBreakables = restore_entities(g_sClassBreakable);
	}
	
	if( get_pcvar_num(hns_removedoors) )
	{
		g_bRemovedDoors = remove_entities(g_sClassDoor);
		g_bRemovedDoorsRotating = remove_entities(g_sClassDoorRotating);
	}
	else
	{
		if( g_bRemovedDoors )
		{
			g_bRemovedDoors = restore_entities(g_sClassDoor);
		}
		
		if( g_bRemovedDoorsRotating )
		{
			g_bRemovedDoorsRotating = restore_entities(g_sClassDoorRotating);
		}
	}
	
	remove_task(TASK_ID_HIDETIMER, 0);
	set_task(0.0, "taskHideTimer", TASK_ID_HIDETIMER, g_sBlank, 0, g_sBlank, 0);
	
	if( !g_bScrimOn )
	{
		return PLUGIN_CONTINUE;
	}
	
	switch( g_ScrimType )
	{
		case SCRIM_ROUNDS:
		{
			if( g_ScrimWinner )
			{
				/* switch() statement gave me an error */
				if( g_ScrimWinner == HNS_TEAM_HIDER )
				{
					scrim_print(0, "^x03Hiders^x01 lost^x03 %i / %i^x01 rounds!", g_ScrimLosses[HNS_TEAM_SEEKER], g_ScrimMaxLosses);
					scrim_print(0, "The scrim is a draw!");
				}
				else if( g_ScrimWinner == HNS_TEAM_SEEKER )
				{
					scrim_print(0, "^x03Hiding team^x01 has won^x03 %i / %i^x01 rounds!", g_ScrimRounds[HNS_TEAM_HIDER], g_ScrimMaxRounds);
					scrim_print(0, "Hiding team has won!");
				}
				
				scrim_print(0, "^x03Turning off scrim mod.");
				
				g_bScrimOn = false;
				g_ScrimType = SCRIM_NONE;
				set_pcvar_num(sv_restart, 1);
			}
			else if( g_bRestartRound )
			{
				g_bRestartRound = false;
				set_pcvar_num(sv_restart, 1);
			}	
		}
		case SCRIM_POINTS:
		{
			if( g_ScrimWinner )
			{
				new CsTeams:team1 = g_ScrimTeams[1];
				new CsTeams:team2 = g_ScrimTeams[2];
				
				scrim_print(0, "Final scrim scores:^x03 Team 1 [%i]^x01 ::^x03 Team 2 [%i]", g_ScrimScores[team1], g_ScrimScores[team2]);
				scrim_print(0, "^x03Team %i^x01 has won!", g_ScrimTeamNums[g_ScrimWinner]);
				
				g_bScrimOn = false;
				g_ScrimType = SCRIM_NONE;
				set_pcvar_num(sv_restart, 1);
			}
			else if( g_bScrimIsDraw )
			{
				new CsTeams:team1 = g_ScrimTeams[1];
				new CsTeams:team2 = g_ScrimTeams[2];
				
				scrim_print(0, "Final scrim scores:^x03 Team 1 [%i]^x01 ::^x03 Team 2 [%i]", g_ScrimScores[team1], g_ScrimScores[team2]);
				scrim_print(0, "The scrim results in a tie!");
				
				g_bScrimOn = false;
				g_ScrimType = SCRIM_NONE;
				set_pcvar_num(sv_restart, 1);
			}
		}
	}
	
	return PLUGIN_CONTINUE;
}

public logeventRoundEnd()
{
	if( !g_bHnsOn )
	{
		return PLUGIN_CONTINUE;
	}
	
	remove_task(TASK_ID_HIDETIMER, 0);
	
	new sMessage[192];
	new CsTeams:winner = HNS_TEAM_SEEKER;
	
	new hider, seeker, hider_alive;
	get_hider_and_seeker(hider, seeker, hider_alive);
	
	if( hider_alive )
	{
		winner = HNS_TEAM_HIDER;
	}
	
	if( !hider || !seeker )
	{
		return PLUGIN_CONTINUE;
	}
	
	static const sTaskSwapTeams[] = "taskSwapTeams";
	
	++g_RoundsEnded;
	
	new teamchange = get_pcvar_num(hns_teamchange);
	if( teamchange && teamchange == g_RoundsEnded && !g_bScrimOn )
	{
		hns_print(0, "%i rounds have ended. Switching teams.", g_RoundsEnded);
		
		set_task(0.5, sTaskSwapTeams, TASK_ID_SWAPTEAMS, g_sBlank, 0, g_sBlank, 0);
	}
	
	static const sNoTeamChange[] = "^nNo Team Change";
	if( winner == HNS_TEAM_SEEKER )
	{
		copy(sMessage, 191, "Seekers Won Round");
		
		if( !teamchange && (!g_bScrimOn || g_ScrimType == SCRIM_ROUNDS) )
		{
			add(sMessage, 191, "^nSwitching Teams", 0);
			
			set_task(0.5, sTaskSwapTeams, TASK_ID_SWAPTEAMS, g_sBlank, 0, g_sBlank, 0);
		}
	}
	else if( winner == HNS_TEAM_HIDER )
	{
		copy(sMessage, 191, "Hiders Won Round");
		
		new frags = get_pcvar_num(hns_hiders_alivefrags);
		
		if( frags )
		{
			static Float:fFrags;
			for( new plr = 1; plr <= g_MaxPlayers; plr++ )
			{
				if( g_bConnected[plr] && g_bAlive[plr] && cs_get_user_team(plr) == HNS_TEAM_HIDER )
				{
					pev(plr, pev_frags, fFrags);
					set_pev(plr, pev_frags, fFrags + float(frags));
					
					hns_print(plr, "You earned %i frag%s for surviving the round!",\
						frags, (frags == 1) ? g_sBlank : g_sS);
				}
			}
		}
		
		if( !teamchange )
		{
			add(sMessage, 191, sNoTeamChange, 0);
		}
	}
	
	static red, green, blue;
	get_hud_colors(red, green, blue);
	set_hudmessage(red, green, blue, -1.0, -1.0, 0, 0.0, 5.0, 0.1, 0.2, 1);
	show_hudmessage(0, "%s", sMessage);
	
	g_bWeaponsGiven = false;
	
	if( !g_bScrimOn )
	{
		return PLUGIN_CONTINUE;
	}
	
	switch( g_ScrimType )
	{
		case SCRIM_ROUNDS:
		{
			/* switch() statement gave me an error */
			if( winner == HNS_TEAM_HIDER )
			{
				++g_ScrimRounds[HNS_TEAM_HIDER];
				
				if( g_ScrimMaxRounds )
				{
					scrim_print(0, "^x03Hiders^x01 have won^x03 %i / %i^x01 rounds!", g_ScrimRounds[HNS_TEAM_HIDER], g_ScrimMaxRounds);
					
					if( g_ScrimRounds[HNS_TEAM_HIDER] == g_ScrimMaxRounds )
					{
						g_ScrimWinner = HNS_TEAM_SEEKER;
					}
				}
			}
			else if( winner == HNS_TEAM_SEEKER && g_ScrimMaxLosses )
			{
				++g_ScrimLosses[HNS_TEAM_HIDER];
				
				scrim_print(0, "^x03Hiders^x01 have lost^x03 %i / %i^x01 rounds!", g_ScrimLosses[HNS_TEAM_HIDER], g_ScrimMaxLosses);
				
				scrim_print(0, "^x03Seekers^x01 won the round");
				scrim_print(0, "Switching teams.");
				
				g_bRestartRound = true;
				
				if( g_ScrimLosses[HNS_TEAM_HIDER] == g_ScrimMaxLosses )
				{
					g_ScrimWinner = HNS_TEAM_HIDER; /* seeking team won, but they will be hiders next round (team switching) */
				}
			}
		}
		case SCRIM_POINTS:
		{
			++g_ScrimRounds[HNS_TEAM_HIDER];
			
			new CsTeams:loser;
			if( winner == HNS_TEAM_HIDER )
			{
				loser = HNS_TEAM_SEEKER;
			}
			else if( winner == HNS_TEAM_SEEKER )
			{
				loser = HNS_TEAM_HIDER;
			}
			
			g_ScrimScores[loser] -= g_PointsRoundLose;
			g_ScrimScores[winner] += g_PointsRoundWin;
			
			new sTeam[CsTeams][16];
			formatex(sTeam[HNS_TEAM_HIDER], 15, "Team %i", g_ScrimTeamNums[HNS_TEAM_HIDER]);
			formatex(sTeam[HNS_TEAM_SEEKER], 15, "Team %i", g_ScrimTeamNums[HNS_TEAM_SEEKER]);
			
			new sMessageLose[192];
			formatex(sMessageLose, 191, "^x03%s^x01 lost^x03 %i point%s^x01 for^x03 losing^x01 the round!", "%s", g_ScrimTeamNums[loser], g_PointsRoundLose, g_PointsRoundLose == 1 ? "" : "s");
			
			new sMessageWin[192];
			formatex(sMessageWin, 191, "^x03%s^x01 gained^x03 %i point%s^x01 for^x03 winning^x01 the round!", "%s", g_ScrimTeamNums[winner], g_PointsRoundWin, g_PointsRoundWin == 1 ? "" : "s");
			
			new CsTeams:team;
			for( new plr = 1; plr <= g_MaxPlayers; plr++ )
			{
				if( !g_bConnected[plr] )
				{
					continue;
				}
				
				team = cs_get_user_team(plr);
				if( team == winner )
				{
					scrim_print(plr, sMessageWin, "Your team");
					scrim_print(plr, sMessageLose, sTeam[loser]);
				}
				else if( team == loser )
				{
					scrim_print(plr, sMessageWin, sTeam[winner]);
					scrim_print(plr, sMessageLose, "Your team");
				}
			}
			
			if( g_ScrimRounds[HNS_TEAM_HIDER] == g_ScrimMaxRounds )
			{
				if( g_ScrimScores[HNS_TEAM_HIDER] > g_ScrimScores[HNS_TEAM_SEEKER] )
				{
					g_ScrimWinner = HNS_TEAM_HIDER;
				}
				else if( g_ScrimScores[HNS_TEAM_SEEKER] > g_ScrimScores[HNS_TEAM_HIDER] )
				{
					g_ScrimWinner = HNS_TEAM_SEEKER;
				}
				else /* not one is greater than the other, so they are equal */
				{
					g_bScrimIsDraw = true;
				}
			}
			else if( g_ScrimRounds[HNS_TEAM_HIDER] == (g_ScrimMaxRounds / 2) ) /* half of the scrim has gone by, so swap the teams */
			{
				set_task(0.5, "taskSwapTeams", TASK_ID_SWAPTEAMS, "", 0, "", 0);
				
				scrim_print(0, "^x03Half^x01 of the scrim is over,^x03 switching teams^x01.");
			}
		}
	}
	
	return PLUGIN_CONTINUE;
}

public mnuScrimType(plr, menu, item)
{
	if( item == MENU_EXIT
	|| g_ScrimVoteTimer == 0 )
	{
		return PLUGIN_HANDLED;
	}
	
	new sInfo[2], _access, callback;
	menu_item_getinfo(menu, item, _access, sInfo, 1, "", 0, callback);
	
	new type = str_to_num(sInfo);
	g_ScrimVoteCount[type]++;
	
	if( get_pcvar_num(amx_vote_answers) )
	{
		new sName[32];
		get_user_name(plr, sName, 31);
		
		switch( type )
		{
			case SCRIM_ROUNDS: scrim_print(0, "^x03%s^x01 voted for^x03 Win %i Rounds", sName, get_pcvar_num(hnss_rounds_wins));
			case SCRIM_POINTS: scrim_print(0, "^x03%s^x01 voted for^x03 Point System", sName);
		}
	}
	
	g_bScrimVoted[plr] = true;
	
	if( check_last_vote(plr) )
	{
		g_ScrimVoteTimer = 1;
	}
	
	return PLUGIN_HANDLED;
}

public taskRemoveShield(ent)
{
	dllfunc(DLLFunc_Think, ent);
	
	return PLUGIN_CONTINUE;
}

public taskHideTimer()
{
	new seeker, hider;
	
	if( g_HideTimer <= 0 )
	{
		seeker = 1;
		hider = 1;
	}
	else
	{
		get_hider_and_seeker(hider, seeker);
	}
	
	static const sTaskHideTimer[] = "taskHideTimer";
	if( !hider || !seeker )
	{
		g_HideTimer = 0;
		set_task(0.0, sTaskHideTimer, TASK_ID_HIDETIMER, g_sBlank, 0, g_sBlank, 0);
		
		return PLUGIN_CONTINUE;
	}
	
	static CsTeams:team;
	
	if( g_HideTimer > 0 )
	{
		new sounds = get_pcvar_num(hns_timersounds);
		
		new sSound[16];
		num_to_word(g_HideTimer, sSound, 15);
		
		static blind_red, blind_green, blind_blue, blind_alpha;
		get_blind_colors(blind_red, blind_green, blind_blue, blind_alpha);
		
		static hud_red, hud_green, hud_blue;
		get_hud_colors(hud_red, hud_green, hud_blue);
		
		for( new plr = 1; plr <= g_MaxPlayers; plr++ )
		{
			if( !g_bConnected[plr] )
			{
				continue;
			}
			
			team = cs_get_user_team(plr);
			if( team == HNS_TEAM_SEEKER || team == HNS_TEAM_HIDER )
			{
				if( team == HNS_TEAM_SEEKER && g_bAlive[plr] )
				{
					make_ScreenFade(plr, 1.5, 1.5, blind_red, blind_green, blind_blue, blind_alpha);
					
					/*set_pev(plr, pev_flags, pev(plr, pev_flags) | FL_FROZEN);
					set_pev(plr, pev_maxspeed, -1.0);*/
				}
				
				set_hudmessage(hud_red, hud_green, hud_blue, -1.0, -1.0, 0, 0.0, 1.1, 0.1, 0.1, 1);
				show_hudmessage(plr, "Hiders have %i seconds to hide!", g_HideTimer);
				
				if( sounds )
				{
					client_cmd(plr, "spk vox/%s.wav", sSound);
				}
			}
		}
		
		g_HideTimer--;
		set_task(1.0, sTaskHideTimer, TASK_ID_HIDETIMER, g_sBlank, 0, g_sBlank, 0);
	}
	else if( g_HideTimer == 0 )
	{
		static hud_red, hud_green, hud_blue;
		get_hud_colors(hud_red, hud_green, hud_blue);
		
		static param[2];
		for( new plr = 1; plr <= g_MaxPlayers; plr++ )
		{
			if( !g_bConnected[plr] )
			{
				continue;
			}
			
			team = cs_get_user_team(plr);
			if( team == HNS_TEAM_SEEKER || team == HNS_TEAM_HIDER )
			{
				if( team == HNS_TEAM_SEEKER && g_bAlive[plr] )
				{
					make_ScreenFade(plr, 0.0, 0.0, 0, 0, 0, 255);
					
					cs_reset_user_maxspeed(plr);
					//set_pev(plr, pev_flags, pev(plr, pev_flags) & ~FL_FROZEN);
				}
				
				set_hudmessage(hud_red, hud_green, hud_blue, -1.0, -1.0, 0, 0.0, 3.0, 0.1, 0.1, 1);
				show_hudmessage(plr, "Ready Or Not, Here We Come!");
				
				param[0] = _:team;
				taskGiveWeapons(param, plr + TASK_ID_GIVEWEAPONS);
			}
		}
		
		g_bWeaponsGiven = true;
		
		g_HideTimer--;
		set_task(1.0, sTaskHideTimer, TASK_ID_HIDETIMER, g_sBlank, 0, g_sBlank, 0);
	}
	else
	{
		for( new plr = 1; plr <= g_MaxPlayers; plr++ )
		{
			if( !g_bConnected[plr] )
			{
				continue;
			}
			
			if( g_bAlive[plr] && cs_get_user_team(plr) == HNS_TEAM_SEEKER )
			{
				make_ScreenFade(plr, 0.0, 0.0, 0, 0, 0, 255);
				
				cs_reset_user_maxspeed(plr);
				//set_pev(plr, pev_flags, pev(plr, pev_flags) & ~FL_FROZEN);
			}
		}
	}
	
	return PLUGIN_CONTINUE;
}

public taskStripWeapons(plr)
{
	plr -= TASK_ID_STRIPWEAPONS;
	
	fm_strip_user_weapons(plr);
	
	return PLUGIN_CONTINUE;
}

public taskGiveKnife(param[], plr)
{
	plr -= TASK_ID_GIVEKNIFE;
	
	new CsTeams:team = CsTeams:param[0];
	
	if( team != HNS_TEAM_HIDER || get_pcvar_num(hns_hiders_knife))
	{
		fm_give_item(plr, "weapon_knife");
	}
	
	return PLUGIN_CONTINUE;
}

public taskGiveWeapons(param[], plr)
{
	plr -= TASK_ID_GIVEWEAPONS;
	
	new CsTeams:team = CsTeams:param[0];
	if( team != HNS_TEAM_HIDER && team != HNS_TEAM_SEEKER )
	{
		return PLUGIN_CONTINUE;
	}
	
	chance(plr, get_pcvar_num(hns_grenades[team]), get_pcvar_num(hns_grenades_percent[team]),"weapon_hegrenade", CSW_HEGRENADE, "HE Grenade");
	chance(plr, get_pcvar_num(hns_flashbangs[team]), get_pcvar_num(hns_flashbangs_percent[team]), "weapon_flashbang", CSW_FLASHBANG, "Flashbang");
	chance(plr, get_pcvar_num(hns_smokegren[team]), get_pcvar_num(hns_smokegren_percent[team]), "weapon_smokegrenade", CSW_SMOKEGRENADE, "Smoke Grenade");
	
	new num = get_pcvar_num(hns_armor[team]);
	num = clamp(num, 0, 100);
	
	switch( num )
	{
		case 0:
		{
			cs_set_user_armor(plr, 0, CS_ARMOR_NONE);
		}
		case 1..99:
		{
			cs_set_user_armor(plr, num, CS_ARMOR_KEVLAR);
		}
		case 100:
		{
			cs_set_user_armor(plr, num, CS_ARMOR_VESTHELM);
		}
	}
	
	return PLUGIN_CONTINUE;
}

public taskCheckModel(param[], plr)
{
	plr -= TASK_ID_CHECKMODEL;
	
	new CsTeams:team = CsTeams:param[0];
	
	if( team == HNS_TEAM_SEEKER || team == HNS_TEAM_HIDER )
	{
		new CsTeams:otherteam = (team == HNS_TEAM_HIDER) ? HNS_TEAM_SEEKER : HNS_TEAM_HIDER;
		
		new sModel[32];
		cs_get_user_model(plr, sModel, 31);
		
		for( new i = 0; i < 4; i++ )
		{
			if( equal(sModel, g_sAllModels[otherteam][i], 0) )
			{
				cs_set_user_model(plr, g_sDefaultModels[team]);
				break;
			}
		}
	}
	
	return PLUGIN_CONTINUE;
}

public taskSwapTeams(taskid)
{
	static CsTeams:team;
	
	if( g_bScrimOn )
	{
		static temp;
		
		if( g_ScrimType == SCRIM_POINTS )
		{
			temp = g_ScrimScores[HNS_TEAM_HIDER];
			g_ScrimScores[HNS_TEAM_HIDER] = g_ScrimScores[HNS_TEAM_SEEKER];
			g_ScrimScores[HNS_TEAM_SEEKER] = temp;
			
			temp = g_ScrimTeamNums[HNS_TEAM_HIDER];
			g_ScrimTeamNums[HNS_TEAM_HIDER] = g_ScrimTeamNums[HNS_TEAM_SEEKER];
			g_ScrimTeamNums[HNS_TEAM_SEEKER] = temp;
			
			team = g_ScrimTeams[1];
			g_ScrimTeams[1] = g_ScrimTeams[2];
			g_ScrimTeams[2] = team;
		}
		else if( g_ScrimType == SCRIM_ROUNDS )
		{
			if( !g_ScrimSaveWins )
			{
				g_ScrimRounds[HNS_TEAM_HIDER] = 0;
				g_ScrimRounds[HNS_TEAM_SEEKER] = 0;
			}
			else
			{
				temp = g_ScrimRounds[HNS_TEAM_HIDER];
				g_ScrimRounds[HNS_TEAM_HIDER] = g_ScrimRounds[HNS_TEAM_SEEKER];
				g_ScrimRounds[HNS_TEAM_SEEKER] = temp;
			}
		}
	}
	
	for( new plr = 1; plr <= g_MaxPlayers; plr++ )
	{
		if( !g_bConnected[plr] )
		{
			continue;
		}
		
		team = cs_get_user_team(plr);
		if( team == HNS_TEAM_HIDER )
		{
			cs_set_user_team(plr, HNS_TEAM_SEEKER, HNS_MODEL_SEEKER);
			
			emake_TeamInfo(plr, g_sTeamInfo[HNS_TEAM_SEEKER]); /* let other plugins know that the player changed teams */
		}
		else if( team == HNS_TEAM_SEEKER )
		{
			cs_set_user_team(plr, HNS_TEAM_HIDER, HNS_MODEL_HIDER);
			
			emake_TeamInfo(plr, g_sTeamInfo[HNS_TEAM_HIDER]); /* let other plugins know that the player changed teams */
		}
	}
	
	g_RoundsLost = 0;
	g_RoundsEnded = 0;
	g_bDisableSlash = true;
	
	return 1;
}

public taskSetLights()
{
	if( !g_bHnsOn )
	{
		if( !equali(g_sLights, g_sLightsNormal) )
		{
			set_lights(g_sLightsNormal);
		}
	}
	else
	{
		new sLights[16];
		get_pcvar_string(hns_lights, sLights, 15);
		
		if( !equali(g_sLights, sLights) )
		{
			if( !strlen(sLights) )
			{
				set_lights(g_sLightsNormal);
				set_pcvar_string(hns_lights, g_sLightsNormal);
			}
			else
			{
				set_lights(sLights);
			}
		}
	}
	
	return PLUGIN_CONTINUE;
}

public taskShowPluginInfo(plr)
{
	if( g_bHnsOn )
	{
		show_plugin_info(plr - TASK_ID_SHOWPLUGININFO);
	}
	
	return PLUGIN_CONTINUE;
}

public taskScrimVote(aMenu[])
{
	if( !--g_ScrimVoteTimer )
	{
		remove_task(TASK_ID_SCRIMVOTE, 0);
		
		for( new plr = 1; plr <= g_MaxPlayers; plr++ )
		{
			if( !g_bScrimVoted[plr] )
			{
				menu_cancel(plr); /* block any more menu key pressing */
				
				client_cmd(plr, "slot1"); /* remove menu from player's screen */
			}
		}
		
		menu_destroy(aMenu[0]);
		
		new rounds = get_pcvar_num(hnss_rounds_wins);
		scrim_print(0, "Vote result:^x03 Win %i Rounds^x01 [^x03%i^x01] -^x03 Point System^x01 [^x03%i^x01]", rounds, g_ScrimVoteCount[SCRIM_ROUNDS], g_ScrimVoteCount[SCRIM_POINTS]);
		
		new best;
		
		if( g_ScrimVoteCount[SCRIM_ROUNDS] > g_ScrimVoteCount[SCRIM_POINTS] )
		{
			best = SCRIM_ROUNDS;
			scrim_print(0, "The scrim type will be^x03 Win %i Rounds^x01!", rounds);
		}
		else if( g_ScrimVoteCount[SCRIM_POINTS] > g_ScrimVoteCount[SCRIM_ROUNDS] )
		{
			best = SCRIM_POINTS;
			scrim_print(0, "The scrim type will be^x03 Point System^x01!");
		}
		else /* not one is greater than the other, so they are equal */
		{
			best = random_num(1, SCRIM_TYPES-1);
			
			new sWinner[16];
			switch( best )
			{
				case SCRIM_ROUNDS: formatex(sWinner, 15, "Win %i Rounds", rounds);
				case SCRIM_POINTS: copy(sWinner, 15, "Point System");
			}
			
			scrim_print(0, "^x03The votes are a tie!^x01 The random generator chooses^x03 %s^x01!", sWinner);
		}
		
		if( best == SCRIM_POINTS )
		{
			/* in case of an odd number, we need to round it up one */
			g_ScrimMaxRounds = floatround(get_pcvar_float(hnss_points_rounds) / 2.0, floatround_ceil) * 2;
			
			g_PointsKnife = get_pcvar_num(hnss_points_knife);
			g_PointsHeadshot = get_pcvar_num(hnss_points_headshot);
			g_PointsGrenade = get_pcvar_num(hnss_points_grenade);
			g_PointsKill = get_pcvar_num(hnss_points_kill);
			g_PointsSuicide = get_pcvar_num(hnss_points_suicide);
			g_PointsTeamKill = get_pcvar_num(hnss_points_teamkill);
			g_PointsRoundWin = get_pcvar_num(hnss_points_roundwin);
			g_PointsRoundLose = get_pcvar_num(hnss_points_roundlose);
		}
		else if( best == SCRIM_ROUNDS )
		{
			g_ScrimMaxRounds = rounds;
			g_ScrimMaxLosses = get_pcvar_num(hnss_rounds_losses);
			g_ScrimSaveWins = get_pcvar_num(hnss_rounds_savewins);
		}
		
		g_ScrimType = best;
		g_ScrimWinner = CS_TEAM_UNASSIGNED;
		g_ScrimRounds[HNS_TEAM_HIDER] = 0;
		g_ScrimRounds[HNS_TEAM_SEEKER] = 0;
		g_bScrimIsDraw = false;
		g_ScrimTeams[1] = HNS_TEAM_HIDER;
		g_ScrimTeams[2] = HNS_TEAM_SEEKER;
		g_ScrimTeamNums[HNS_TEAM_HIDER] = 1;
		g_ScrimTeamNums[HNS_TEAM_SEEKER] = 2;
		g_ScrimScores[HNS_TEAM_HIDER] = 0;
		g_ScrimScores[HNS_TEAM_SEEKER] = 0;
		
		g_bScrimOn = true;
		set_pcvar_num(sv_restart, 1);
	}
	else
	{
		new sTitle[32];
		formatex(sTitle, 31, "Choose a scrim type \r[\w%i\r]", g_ScrimVoteTimer);
		
		new menu = aMenu[0];
		menu_setprop(menu, MPROP_TITLE, sTitle);
		
		for( new plr = 1; plr <= g_MaxPlayers; plr++ )
		{
			if( !g_bScrimVoted[plr] )
			{
				menu_display(plr, menu, 0);
			}
		}
	}
	
	return PLUGIN_CONTINUE;
}

public taskExecuteConfig()
{
	new sConfig[64];
	get_configsdir(sConfig, 63);
	add(sConfig, 63, "/hidenseek.cfg", 0);
	
	if( file_exists(sConfig) )
	{
		server_cmd("exec %s", sConfig);
		server_exec();
		
		set_task(1.0, "TaskCheckOldVersion");
	}
	else
	{
		make_config(sConfig, true);
		
		register_forward(FM_GetGameDescription, "fwdGetGameDescription", 0);
	}
}

public TaskCheckOldVersion()
{
	new sValue[32];
	get_pcvar_string(hns_gametype, sValue, 31);
	
	if( had_older_version(sValue) || is_config_old() )
	{
		formatex(sValue, 31, "HideNSeek v%s", PLUGIN_VERSION);
		set_pcvar_string(hns_gametype, sValue);
		
		set_task(1.0, "TaskResetConfig");
	}
	else
	{
		register_forward(FM_GetGameDescription, "fwdGetGameDescription", 0);
	}
}

public TaskResetConfig()
{
	new sConfig[64];
	get_configsdir(sConfig, 63);
	add(sConfig, 63, "/hidenseek.cfg", 0);
	
	//delete_file(sConfig);
	make_config(sConfig, false);
	
	register_forward(FM_GetGameDescription, "fwdGetGameDescription", 0);
}

bool:had_older_version(const sGameType[])
{
	new bool:bOld = false;
	
	new sTemp[32];
	formatex(sTemp, 31, "HideNSeek v%s", PLUGIN_VERSION);
	
	if( !equali(sTemp, sGameType) )
	{
		new Float:version = str_to_float(PLUGIN_VERSION);
		for( new Float:i = 2.0; i < version; i += 0.1 )
		{
			formatex(sTemp, 31, "HideNSeek v%.1f", i);
			
			if( equali(sTemp, sGameType) )
			{
				bOld = true;
				break;
			}
		}
	}
	
	return bOld;
}

bool:is_config_old()
{
	new sConfig[64];
	get_configsdir(sConfig, 63);
	add(sConfig, 63, "/hidenseek.cfg", 0);
	
	new f = fopen(sConfig, "rt");
	new data[128];
	
	while( !feof(f) )
	{
		fgets(f, data, sizeof(data) - 1);
		
		if( containi(data, "hns_warmup") != -1 )
		{
			fclose(f);
			
			return false;
		}
	}
	
	fclose(f);
	
	return true;
}

make_config(const sConfig[], bool:bCheckVersion)
{
	new f = fopen(sConfig, "wt");
	
	fputs(f, "// This is where all the cvars go for HideNSeek^n// Information about the cvars can be found at: http://forums.alliedmods.net/showthread.php?t=65370^n^n");
	
	new sValue[32]; // any string needed from a cvar
	
	fprintf(f, "hns_footsteps %i^n", get_pcvar_num(hns_footsteps));
	fprintf(f, "hns_money %i^n", get_pcvar_num(hns_money));
	fprintf(f, "hns_nubslash %i^n", get_pcvar_num(hns_nubslash));
	fprintf(f, "hns_disablebuy %i^n", get_pcvar_num(hns_disablebuy));
	fprintf(f, "hns_hidetime %i^n", get_pcvar_num(hns_hidetime));
	fprintf(f, "hns_timersounds %i^n", get_pcvar_num(hns_timersounds));
	fprintf(f, "hns_noslowdown %i^n", get_pcvar_num(hns_noslowdown));
	fprintf(f, "hns_teamchange %i^n", get_pcvar_num(hns_teamchange));
	fprintf(f, "hns_disablekill %i^n", get_pcvar_num(hns_disablekill));
	fprintf(f, "hns_chooseteam %i^n", get_pcvar_num(hns_chooseteam));
	fprintf(f, "hns_semiclip %i^n", get_pcvar_num(hns_semiclip));
	fprintf(f, "hns_semiclip_alpha %i^n", get_pcvar_num(hns_semiclip_alpha));
	fprintf(f, "hns_noflash %i^n", get_pcvar_num(hns_noflash));
	fprintf(f, "hns_removebreakables %i^n", get_pcvar_num(hns_removebreakables));
	fprintf(f, "hns_removedoors %i^n", get_pcvar_num(hns_removedoors));
	fprintf(f, "hns_visiblecommands %i^n", get_pcvar_num(hns_visiblecommands));
	fprintf(f, "hns_noboosting %i^n", get_pcvar_num(hns_noboosting));
	fprintf(f, "hns_noboosting_punish %i^n", get_pcvar_num(hns_noboosting_punish));
	fprintf(f, "hns_noboosting_damage %i^n", get_pcvar_num(hns_noboosting_damage));
	fprintf(f, "hns_noboosting_interval %.4f^n", get_pcvar_float(hns_noboosting_interval));
	get_pcvar_string(hns_blindcolors, sValue, 31);
	fprintf(f, "hns_blindcolors ^"%s^"^n", sValue);
	get_pcvar_string(hns_hudcolors, sValue, 31);
	fprintf(f, "hns_hudcolors ^"%s^"^n", sValue);
	get_pcvar_string(hns_lights, sValue, 31);
	fprintf(f, "hns_lights ^"%s^"^n", sValue);
	
	get_pcvar_string(hns_gametype, sValue, 31);
	if( bCheckVersion )
	{
		if( had_older_version(sValue) )
		{
			formatex(sValue, 31, "HideNSeek v%s", PLUGIN_VERSION);
		}
	}
	fprintf(f, "hns_gametype ^"%s^"^n", sValue);
	
	get_pcvar_string(hns_prefix, sValue, 31);
	fprintf(f, "hns_prefix ^"%s^"^n", sValue);
	fprintf(f, "hns_warmup_godmode %i^n", get_pcvar_num(hns_warmup_godmode));
	fprintf(f, "hns_warmup_respawn %i^n^n", get_pcvar_num(hns_warmup_respawn));
	
	new sTeams[CsTeams][16];
	copy(sTeams[HNS_TEAM_HIDER], 15, "hiders");
	copy(sTeams[HNS_TEAM_SEEKER], 15, "seekers");
	fprintf(f, "hns_hiders_knife %i^n", get_pcvar_num(hns_hiders_knife));
	fprintf(f, "hns_hiders_alivefrags %i^n", get_pcvar_num(hns_hiders_alivefrags));
	for( new CsTeams:team = HNS_TEAM_HIDER; team < CS_TEAM_SPECTATOR; team++ )
	{
		fprintf(f, "hns_%s_grenades %i^n", sTeams[team], get_pcvar_num(hns_grenades[team]));
		fprintf(f, "hns_%s_grenades_percent %i^n", sTeams[team], get_pcvar_num(hns_grenades_percent[team]));
		fprintf(f, "hns_%s_flashbangs %i^n", sTeams[team], get_pcvar_num(hns_flashbangs[team]));
		fprintf(f, "hns_%s_flashbangs_percent %i^n", sTeams[team], get_pcvar_num(hns_flashbangs_percent[team]));
		fprintf(f, "hns_%s_smokegren %i^n", sTeams[team], get_pcvar_num(hns_smokegren[team]));
		fprintf(f, "hns_%s_smokegren_percent %i^n", sTeams[team], get_pcvar_num(hns_smokegren_percent[team]));
		fprintf(f, "hns_%s_armor %i^n^n", sTeams[team], get_pcvar_num(hns_armor[team]));
	}
	
	get_pcvar_string(hnss_prefix, sValue, 31);
	fprintf(f, "hnss_prefix ^"%s^"^n", sValue);
	fprintf(f, "hnss_vote_timer %i^n^n", get_pcvar_num(hnss_vote_timer));
	
	fprintf(f, "hnss_rounds_wins %i^n", get_pcvar_num(hnss_rounds_wins));
	fprintf(f, "hnss_rounds_losses %i^n", get_pcvar_num(hnss_rounds_losses));
	fprintf(f, "hnss_rounds_savewins %i^n^n", get_pcvar_num(hnss_rounds_savewins));
	
	fprintf(f, "hnss_points_knife %i^n", get_pcvar_num(hnss_points_knife));
	fprintf(f, "hnss_points_headshot %i^n", get_pcvar_num(hnss_points_headshot));
	fprintf(f, "hnss_points_grenade %i^n", get_pcvar_num(hnss_points_grenade));
	fprintf(f, "hnss_points_kill %i^n", get_pcvar_num(hnss_points_kill));
	fprintf(f, "hnss_points_suicide %i^n", get_pcvar_num(hnss_points_suicide));
	fprintf(f, "hnss_points_teamkill %i^n", get_pcvar_num(hnss_points_teamkill));
	fprintf(f, "hnss_points_roundwin %i^n", get_pcvar_num(hnss_points_roundwin));
	fprintf(f, "hnss_points_roundwin %i^n", get_pcvar_num(hnss_points_roundwin));
	fprintf(f, "hnss_points_rounds %i", get_pcvar_num(hnss_points_rounds));
	
	fclose(f);
}

register_say_command(const sCommand[], const sHandle[], const flags=-1, const sDescription[]="", const FlagManager=-1)
{
	new sTemp[64];
	
	formatex(sTemp, 63, "say /%s", sCommand);
	register_clcmd(sTemp, sHandle, flags, sDescription, FlagManager);
	
	formatex(sTemp, 63, "say .%s", sCommand);
	register_clcmd(sTemp, sHandle, flags, sDescription, FlagManager);
	
	formatex(sTemp, 63, "say_team /%s", sCommand);
	register_clcmd(sTemp, sHandle, flags, sDescription, FlagManager);
	
	formatex(sTemp, 63, "say_team .%s", sCommand);
	register_clcmd(sTemp, sHandle, flags, sDescription, FlagManager);
}

handle_booster(plr)
{
	new sPrefix[16];
	new Float:fGametime = get_gametime();
	new Float:fInterval = get_pcvar_float(hns_noboosting_interval);
	get_pcvar_string(hns_prefix, sPrefix, 15);
	
	if( fGametime >= g_fBoostPunishDelay[plr] )
	{
		punish_booster(plr);
		g_fBoostPunishDelay[plr] = fGametime + fInterval;
	}
	
	if( fGametime >= g_fBoostMessageDelay[plr] )
	{
		set_hudmessage(255, 50, 50, -1.0, 0.6, 1, 3.0, 3.0, 0.1, 0.1, -1);
		ShowSyncHudMsg(plr, g_BoostHud, "%s No Boosting Allowed!", sPrefix);
		
		g_fBoostMessageDelay[plr] = fGametime + 2.8;
	}
}

punish_booster(plr)
{
	new damage = get_pcvar_num(hns_noboosting_damage);
	
	if( damage >= get_user_health(plr) )
	{
		fm_fakedamage(plr, "anti-boost system", float(damage), DMG_CRUSH);
	}
	else
	{
		user_slap(plr, damage, 1);
		user_slap(plr, 0, 1);
	}
}

get_hider_and_seeker(&hider = 0, &seeker = 0, &hider_alive = 0)
{
	static CsTeams:team;
	for( new plr = 1; plr <= g_MaxPlayers; plr++ )
	{
		if( !g_bConnected[plr] )
		{
			continue;
		}
		
		team = cs_get_user_team(plr);
		if( team == HNS_TEAM_SEEKER && !seeker )
		{
			seeker = plr;
			
			if( hider && hider_alive )
			{
				break;
			}
		}
		else if( team == HNS_TEAM_HIDER )
		{
			if( !hider )
			{
				hider = plr;
			}
			if( !hider_alive && g_bAlive[plr] )
			{
				hider_alive = plr;
				
				if( seeker && hider )
				{
					break;
				}
			}
		}
	}
}

bool:remove_entities(const class[])
{
	new bool:remove = false;
	
	new ent = g_MaxPlayers, properties[32], Float:amt;
	while( (ent = engfunc(EngFunc_FindEntityByString, ent, "classname", class)) )
	{
		pev(ent, pev_renderamt, amt);
		formatex(properties, 31, "^"%i^" ^"%f^" ^"%i^"", pev(ent, pev_rendermode), amt, pev(ent, pev_solid));
		
		set_pev(ent, pev_message, properties);
		set_pev(ent, pev_rendermode, kRenderTransAlpha);
		set_pev(ent, pev_renderamt, 0.0);
		set_pev(ent, pev_solid, SOLID_NOT);
		
		remove = true;
	}
	
	return remove;
}

bool:restore_entities(const class[])
{
	new bool:remove = true;
	
	new ent = g_MaxPlayers, properties[32], rendermode[4], amt[16], solid[4];
	while( (ent = engfunc(EngFunc_FindEntityByString, ent, "classname", class)) )
	{
		pev(ent, pev_message, properties, 31);
		parse(properties, rendermode, 3, amt, 15, solid, 3);
		
		set_pev(ent, pev_rendermode, str_to_num(rendermode));
		set_pev(ent, pev_renderamt, str_to_float(amt));
		set_pev(ent, pev_solid, str_to_num(solid));
		set_pev(ent, pev_message, g_sBlank);
		
		remove = false;
	}
	
	return remove;
}

show_scrim_vote()
{
	new menu = menu_create("", "mnuScrimType", 0);
	
	new sItem[32];
	formatex(sItem, 31, "Win %i Rounds", get_pcvar_num(hnss_rounds_wins));
	
	menu_additem(menu, sItem, "1", 0, -1);
	menu_additem(menu, "Point System", "2", 0, -1);
	
	menu_setprop(menu, MPROP_PERPAGE, 0);
	
	for( new plr = 1; plr <= g_MaxPlayers; plr++ )
	{
		if( g_bConnected[plr] )
		{
			g_bScrimVoted[plr] = false;
		}
		else
		{
			g_bScrimVoted[plr] = true;
		}
	}
	
	g_ScrimVoteTimer = get_pcvar_num(hnss_vote_timer) + 1;
	g_ScrimVoteCount[SCRIM_ROUNDS] = 0;
	g_ScrimVoteCount[SCRIM_POINTS] = 0;
	
	new aMenu[2];
	aMenu[0] = menu;
	set_task(1.0, "taskScrimVote", TASK_ID_SCRIMVOTE, aMenu, 2, "b", 0);
	
	return 1;
}

bool:check_last_vote(plr_to_skip)
{
	for( new i = 1; i <= g_MaxPlayers; i++ )
	{
		if( !g_bConnected[i]
		|| i == plr_to_skip )
		{
			continue;
		}
		
		if( !g_bScrimVoted[i] )
		{
			return false;
		}
	}
	
	return true;
}

show_plugin_info(plr)
{
	hns_print(plr, "This server is using^x03 HideNSeek v%s^x01, by^x03 Exolent", PLUGIN_VERSION);
	hns_print(plr, "Type^x03 /hnshelp^x01 for information about^x03 HideNSeek");
	
	return 1;
}

cs_reset_user_maxspeed(plr)
{
	static Float:fMaxSpeed;
	
	static clip, ammo;
	switch( get_user_weapon(plr, clip, ammo) )
	{
		case CSW_SG550, CSW_AWP, CSW_G3SG1:
		{
			fMaxSpeed = 210.0;
		}
		case CSW_M249:
		{
			fMaxSpeed = 220.0;
		}
		case CSW_AK47:
		{
			fMaxSpeed = 221.0;
		}
		case CSW_M3, CSW_M4A1:
		{
			fMaxSpeed = 230.0;
		}
		case CSW_SG552:
		{
			fMaxSpeed = 235.0;
		}
		case CSW_XM1014, CSW_AUG, CSW_GALIL, CSW_FAMAS:
		{
			fMaxSpeed = 240.0;
		}
		case CSW_P90:
		{
			fMaxSpeed = 245.0;
		}
		case CSW_SCOUT:
		{
			fMaxSpeed = 260.0;
		}
		default:
		{
			fMaxSpeed = 250.0;
		}
	}
	
	engfunc(EngFunc_SetClientMaxspeed, plr, fMaxSpeed);
	set_pev(plr, pev_maxspeed, fMaxSpeed);
	
	return 1;
}

chance(plr, maxcount, percent, sClass[], CSW_type=0, sName[]="")
{
	if( !maxcount || !percent )
	{
		return 0;
	}
	
	new count;
	for( new i = 0; i < maxcount; i++ )
	{
		if( random_num(1, 100) <= percent )
		{
			if( count == 0 )
			{
				fm_give_item(plr, sClass);
			}
			
			count++;
		}
	}
	
	if( count && CSW_type )
	{
		if( percent < 100 )
		{
			hns_print(plr, "You received %i %s%s! (%i%% chance)", count, sName, (count == 1) ? g_sBlank : g_sS, percent);
		}
		
		cs_set_user_bpammo(plr, CSW_type, count);
	}
	
	return 1;
}

get_blind_colors(&red, &green, &blue, &alpha)
{
	new sColors[20];
	get_pcvar_string(hns_blindcolors, sColors, 19);
	
	static sRed[5], sGreen[5], sBlue[5], sAlpha[5];
	if( parse(sColors, sRed, 4, sGreen, 4, sBlue, 4, sAlpha, 4) < 4 )
	{
		red = 0;
		green = 0;
		blue = 0;
		alpha = 255;
		
		formatex(sColors, 19, "%i %i %i %i", red, green, blue, alpha);
		set_pcvar_string(hns_blindcolors, sColors);
		
		return 0;
	}
	
	red =	equali(sRed, "rand", 0) ?	random(256) : clamp(str_to_num(sRed), 0, 255);
	green =	equali(sGreen, "rand", 0) ?	random(256) : clamp(str_to_num(sGreen), 0, 255);
	blue =	equali(sBlue, "rand", 0) ?	random(256) : clamp(str_to_num(sBlue), 0, 255);
	alpha =	equali(sAlpha, "rand", 0) ?	random(256) : clamp(str_to_num(sAlpha), 0, 255);
	
	return 1;
}

get_hud_colors(&red, &green, &blue)
{
	new sColors[20];
	get_pcvar_string(hns_hudcolors, sColors, 19);
	
	static sRed[5], sGreen[5], sBlue[5];
	if( parse(sColors, sRed, 4, sGreen, 4, sBlue, 4) < 3 )
	{
		red = 255;
		green = 255;
		blue = 255;
		
		formatex(sColors, 19, "%i %i %i", red, green, blue);
		set_pcvar_string(hns_blindcolors, sColors);
		
		return 0;
	}
	
	red =	equali(sRed, "rand", 0) ?	random(256) : clamp(str_to_num(sRed), 0, 255);
	green =	equali(sGreen, "rand", 0) ?	random(256) : clamp(str_to_num(sGreen), 0, 255);
	blue =	equali(sBlue, "rand", 0) ?	random(256) : clamp(str_to_num(sBlue), 0, 255);
	
	return 1;
}

set_lights(const sLights[])
{
	engfunc(EngFunc_LightStyle, 0, sLights);
	copy(g_sLights, 16, sLights);
	
	return 1;
}

make_HideWeapon(plr, flags)
{
	static i; i = plr ? plr : get_player();
	if( !i )
	{
		return 0;
	}
	
	message_begin(plr ? MSG_ONE : MSG_ALL, g_msgHideWeapon, {0, 0, 0}, plr);
	write_byte(flags);
	message_end();
	
	return 1;
}

make_ScreenFade(plr, Float:fDuration, Float:fHoldtime, red, green, blue, alpha)
{
	static i; i = plr ? plr : get_player();
	if( !i )
	{
		return 0;
	}
	
	message_begin(plr ? MSG_ONE : MSG_ALL, g_msgScreenFade, {0, 0, 0}, plr);
	write_short(floatround(4096.0 * fDuration, floatround_round));
	write_short(floatround(4096.0 * fHoldtime, floatround_round));
	write_short(4096);
	write_byte(red);
	write_byte(green);
	write_byte(blue);
	write_byte(alpha);
	message_end();
	
	return 1;
}

emake_TeamInfo(plr, sTeam[])
{
	if( !plr )
	{
		return 0;
	}
	
	emessage_begin(MSG_ALL, g_msgTeamInfo, {0, 0, 0}, 0);
	ewrite_byte(plr);
	ewrite_string(sTeam);
	emessage_end();
	
	return 1;
}

make_TeamInfo(plr, sTeam[])
{
	if( !plr )
	{
		return 0;
	}
	
	message_begin(MSG_ALL, g_msgTeamInfo, {0, 0, 0}, 0);
	write_byte(plr);
	write_string(sTeam);
	message_end();
	
	return 1;
}

make_Money(plr, money, flash)
{
	if( !plr )
	{
		return 0;
	}
	
	message_begin(MSG_ONE, g_msgMoney, {0, 0, 0}, plr);
	write_long(money);
	write_byte(flash ? 1 : 0);
	message_end();
	
	return 1;
}

make_ArmorType(plr, helmet)
{
	if( !plr )
	{
		return 0;
	}
	
	message_begin(MSG_ONE, g_msgArmorType, {0, 0, 0}, plr);
	write_byte(helmet);
	message_end();
	
	return 1;
}

make_SayText(receiver, sender, sMessage[])
{
	if( !sender )
	{
		return 0;
	}
	
	message_begin(receiver ? MSG_ONE : MSG_ALL, g_msgSayText, {0, 0, 0}, receiver);
	write_byte(sender);
	write_string(sMessage);
	message_end();
	
	return 1;
}

hns_print(plr, const sFormat[], any:...)
{
	static i; i = plr ? plr : get_player();
	if( !i )
	{
		return 0;
	}
	
	new sPrefix[16];
	get_pcvar_string(hns_prefix, sPrefix, 15);
	
	new sMessage[256];
	new len = formatex(sMessage, 255, "^x04%s^x01 ", sPrefix);
	vformat(sMessage[len], 255-len, sFormat, 3);
	sMessage[192] = '^0';
	
	make_SayText(plr, i, sMessage);
	
	return 1;
}

scrim_print(plr, const sFmt[], any:...)
{
	new i = plr ? plr : get_player();
	if( !i )
	{
		return 0;
	}
	
	new sPrefix[16];
	get_pcvar_string(hnss_prefix, sPrefix, 15);
	
	new sMessage[256];
	new len = formatex(sMessage, 255, "^x04%s^x01 ", sPrefix);
	vformat(sMessage[len], 255-len, sFmt, 3);
	sMessage[192] = '^0';
	
	make_SayText(plr, i, sMessage);
	
	return 1;
}

get_player()
{
	for( new plr = 1; plr <= g_MaxPlayers; plr++ )
	{
		if( g_bConnected[plr] )
		{
			return plr;
		}
	}
	
	return 0;
}

/* cstrike -> fakemeta stocks */
CsTeams:cs_get_user_team(plr, &{CsInternalModel,_}:model=CS_DONTCHANGE)
{
	model = CsInternalModel:get_pdata_int(plr, OFFSET_INTERNALMODEL);
	
	return CsTeams:get_pdata_int(plr, OFFSET_TEAM);
}

cs_set_user_team(plr, {CsTeams,_}:team, {CsInternalModel,_}:model=CS_DONTCHANGE)
{
	set_pdata_int(plr, OFFSET_TEAM, _:team);
	if( model )
	{
		set_pdata_int(plr, OFFSET_INTERNALMODEL, _:model);
	}
	
	dllfunc(DLLFunc_ClientUserInfoChanged, plr);
	
	make_TeamInfo(plr, g_sTeamInfo[team]);
	
	return 1;
}

cs_set_user_money(plr, money, flash=1)
{
	set_pdata_int(plr, OFFSET_MONEY, money);
	
	make_Money(plr, money, flash);
	
	return 1;
}

cs_set_user_armor(plr, amount, CsArmorType:type)
{
	set_pdata_int(plr, OFFSET_ARMORTYPE, _:type);
	set_pev(plr, pev_armorvalue, float(amount));
	
	if( type != CS_ARMOR_NONE )
	{
		make_ArmorType(plr, (type == CS_ARMOR_VESTHELM) ? 1 : 0);
	}
	
	return 1;
}

__get_ammo_offset(weapon)
{
	static offset;
	
	switch( weapon )
	{
		case CSW_AWP:
		{
			offset = OFFSET_AWP_AMMO;
		}
		case CSW_SCOUT, CSW_AK47, CSW_G3SG1:
		{
			offset = OFFSET_SCOUT_AMMO;
		}
		case CSW_FAMAS, CSW_M4A1, CSW_AUG, CSW_SG550, CSW_GALIL, CSW_SG552:
		{
			offset = OFFSET_FAMAS_AMMO;
		}
		case CSW_M3, CSW_XM1014:
		{
			offset = OFFSET_M3_AMMO;
		}
		case CSW_USP, CSW_UMP45, CSW_MAC10:
		{
			offset = OFFSET_USP_AMMO;
		}
		case CSW_FIVESEVEN, CSW_P90:
		{
			offset = OFFSET_FIVESEVEN_AMMO;
		}
		case CSW_DEAGLE:
		{
			offset = OFFSET_DEAGLE_AMMO;
		}
		case CSW_P228:
		{
			offset = OFFSET_P228_AMMO;
		}
		case CSW_GLOCK18, CSW_MP5NAVY, CSW_TMP, CSW_ELITE:
		{
			offset = OFFSET_GLOCK_AMMO;
		}
		case CSW_FLASHBANG:
		{
			offset = OFFSET_FLASHBANG_AMMO;
		}
		case CSW_HEGRENADE:
		{
			offset = OFFSET_HEGRENADE_AMMO;
		}
		case CSW_SMOKEGRENADE:
		{
			offset = OFFSET_SMOKEGRENADE_AMMO;
		}
		case CSW_C4:
		{
			offset = OFFSET_C4_AMMO;
		}
		default:
		{
			return 0;
		}
	}
	
	return offset;
}
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1033\\ f0\\ fs16 \n\\ par }
*/
