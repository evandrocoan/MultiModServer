/*
Changelog:

v1.9
	* Finally fixed voice control
	* Added cvar to disable team change
	* Fixed OldStyle team menu issue
	* Fixed crowbar user + he damage issue

v1.8
	* Fixed duel bug
	* Fixed clcmd/concmd flags problem
	* Added cell opener for maps with multi_manager 
	* Added cvar to enable last request
	* Added cvar to enable motd

v1.7
	* Fixed auto Simon mode

v1.6
	* Updated dictionary
	* Fixed last request abuse bug
	* Fixed voice mode bugs
	* Added auto team transfer to Guards that never been Simon
	* Added auto disconnect to Spectators that doesn't join any team in 3 rounds
	* Added blocking for hints messages
	* Added auto door open on freeday
	* Added /open command only for Simon

v1.5
	* Improved team select code
	* Improved team status code
	* Updated dictionary
	* Added custom model (using body+skin)
	* Added sounds
	* Added freeday menu command
	* Added lastrequest menu command & functionalities
	* Added help command
	* Added last prisoner hud message
	* Added cvar to change talk mode control (+simonvoice optional or required to talk)
	* Added cvar to allow shooting func_button to activate it
	* Added cvar to allow auto-freeday hud message after 60 seconds with no Simon selected
	* Added cvar to force round end after some time of auto-freeday
	* Added cvar to change game mode (classic counter for days)
	* Added simon footsteps decals (controlled by cvar)
	* Added restriction on HE for guards

v1.3
	* First public release
*/

#include <amxmodx>
#include <amxmisc>
#include <engine>
#include <fakemeta>
#include <hamsandwich>
#include <fun>
#include <cstrike>
 
#define PLUGIN_NAME	"JailBreak Extreme"
#define PLUGIN_AUTHOR	"JoRoPiTo"
#define PLUGIN_VERSION	"1.9"
#define PLUGIN_CVAR	"jbextreme"

#define TASK_STATUS	2487000
#define TASK_FREEDAY	2487100
#define TASK_ROUND	2487200
#define TASK_HELP		2487300
#define TASK_SAFETIME	2487400
#define TASK_FREEEND	2487500
#define TEAM_MENU		"#Team_Select_Spect"
#define TEAM_MENU2	"#Team_Select_Spect"
#define HUD_DELAY		Float:4.0
#define CELL_RADIUS	Float:200.0

#define get_bit(%1,%2) 		( %1 &   1 << ( %2 & 31 ) )
#define set_bit(%1,%2)	 	%1 |=  ( 1 << ( %2 & 31 ) )
#define clear_bit(%1,%2)	%1 &= ~( 1 << ( %2 & 31 ) )

#define vec_len(%1)		floatsqroot(%1[0] * %1[0] + %1[1] * %1[1] + %1[2] * %1[2])
#define vec_mul(%1,%2)		( %1[0] *= %2, %1[1] *= %2, %1[2] *= %2)
#define vec_copy(%1,%2)		( %2[0] = %1[0], %2[1] = %1[1],%2[2] = %1[2])

// Offsets
#define m_iPrimaryWeapon	116
#define m_iVGUI			510
#define m_fGameHUDInitialized	349
#define m_fNextHudTextArgsGameTime	198
 
enum _hud { _hudsync, Float:_x, Float:_y, Float:_time }
enum _lastrequest { _knife, _deagle, _freeday, _weapon }
enum _duel { _name[16], _csw, _entname[32], _opt[32], _sel[32] }

new gp_PrecacheSpawn
new gp_PrecacheKeyValue

new gp_CrowbarMax
new gp_CrowbarMul
new gp_TeamRatio
new gp_CtMax
new gp_BoxMax
new gp_TalkMode
new gp_VoiceBlock
new gp_RetryTime
new gp_RoundMax
new gp_ButtonShoot
new gp_SimonSteps
new gp_SimonRandom
new gp_GlowModels
new gp_AutoLastresquest
new gp_LastRequest
new gp_Motd
new gp_SpectRounds
new gp_NosimonRounds
new gp_AutoOpen
new gp_TeamChange

new g_MaxClients
new g_MsgStatusText
new g_MsgStatusIcon
new g_MsgVGUIMenu
new g_MsgShowMenu
new g_MsgClCorpse
new g_MsgMOTD

new gc_TalkMode
new gc_VoiceBlock
new gc_SimonSteps
new gc_ButtonShoot
new Float:gc_CrowbarMul

// Precache
new const _FistModels[][] = { "models/p_bknuckles.mdl", "models/v_bknuckles.mdl" }
new const _CrowbarModels[][] = { "models/p_crowbar.mdl", "models/v_crowbar.mdl" }
new const _FistSounds[][] = { "weapons/cbar_hitbod2.wav", "weapons/cbar_hitbod1.wav", "weapons/bullet_hit1.wav", "weapons/bullet_hit2.wav" }
new const _RemoveEntities[][] = {
	"func_hostage_rescue", "info_hostage_rescue", "func_bomb_target", "info_bomb_target",
	"hostage_entity", "info_vip_start", "func_vip_safetyzone", "func_escapezone"
}

new const _WeaponsFree[][] = { "weapon_scout", "weapon_deagle", "weapon_mac10", "weapon_elite", "weapon_ak47", "weapon_m4a1", "weapon_mp5navy" }
new const _WeaponsFreeCSW[] = { CSW_SCOUT, CSW_DEAGLE, CSW_MAC10, CSW_ELITE, CSW_AK47, CSW_M4A1, CSW_MP5NAVY }
new const _WeaponsFreeAmmo[] = { 90, 35, 100, 120, 90, 90, 120 }

new const _Duel[][_duel] =
{
	{ "Deagle", CSW_DEAGLE, "weapon_deagle", "JBE_MENU_LASTREQ_OPT4", "JBE_MENU_LASTREQ_SEL4" },
	{ "Scout", CSW_SCOUT, "weapon_scout", "JBE_MENU_LASTREQ_OPT5", "JBE_MENU_LASTREQ_SEL5" },
	{ "Grenades", CSW_HEGRENADE, "weapon_hegrenade", "JBE_MENU_LASTREQ_OPT6", "JBE_MENU_LASTREQ_SEL6" },
	{ "Awp", CSW_AWP, "weapon_awp", "JBE_MENU_LASTREQ_OPT7", "JBE_MENU_LASTREQ_SEL7" }
}

// Reasons
new const g_Reasons[][] =  {
	"",
	"JBE_PRISONER_REASON_1",
	"JBE_PRISONER_REASON_2",
	"JBE_PRISONER_REASON_3",
	"JBE_PRISONER_REASON_4",
	"JBE_PRISONER_REASON_5",
	"JBE_PRISONER_REASON_6"
}

// HudSync: 0=ttinfo / 1=info / 2=simon / 3=ctinfo / 4=player / 5=day / 6=center / 7=help / 8=timer
new const g_HudSync[][_hud] =
{
	{0,  0.6,  0.2,  2.0},
	{0, -1.0,  0.7,  5.0},
	{0,  0.1,  0.2,  2.0},
	{0,  0.1,  0.3,  2.0},
	{0, -1.0,  0.9,  3.0},
	{0,  0.6,  0.1,  3.0},
	{0, -1.0,  0.6,  3.0},
	{0,  0.8,  0.3, 20.0},
	{0, -1.0,  0.4,  3.0}
}

// Colors: 0:Simon / 1:Freeday / 2:CT Duel / 3:TT Duel
new const g_Colors[][3] = { {0, 255, 0}, {255, 140, 0}, {0, 0, 255}, {255, 0, 0} }


new CsTeams:g_PlayerTeam[33]
new Float:g_SimonRandom
new Trie:g_CellManagers
new g_HelpText[512]
new g_JailDay
new g_PlayerJoin
new g_PlayerReason[33]
new g_PlayerSpect[33]
new g_PlayerSimon[33]
new g_PlayerNomic
new g_PlayerWanted
new g_PlayerCrowbar
new g_PlayerRevolt
new g_PlayerHelp
new g_PlayerFreeday
new g_PlayerLast
new g_FreedayAuto
new g_FreedayNext
new g_TeamCount[CsTeams]
new g_TeamAlive[CsTeams]
new g_BoxStarted
new g_CrowbarCount
new g_Simon
new g_SimonAllowed
new g_SimonTalking
new g_SimonVoice
new g_RoundStarted
new g_LastDenied
new g_Freeday
new g_BlockWeapons
new g_RoundEnd
new g_Duel
new g_DuelA
new g_DuelB
new g_SafeTime
new g_Buttons[10]
 
public plugin_init()
{
	unregister_forward(FM_Spawn, gp_PrecacheSpawn)
	unregister_forward(FM_KeyValue, gp_PrecacheKeyValue)
 
	register_plugin(PLUGIN_NAME, PLUGIN_VERSION, PLUGIN_AUTHOR)
	register_cvar(PLUGIN_CVAR, PLUGIN_VERSION, FCVAR_SERVER|FCVAR_SPONLY)
 
	register_dictionary("jbextreme.txt")

	g_MsgStatusText = get_user_msgid("StatusText")
	g_MsgStatusIcon = get_user_msgid("StatusIcon")
	g_MsgVGUIMenu = get_user_msgid("VGUIMenu")
	g_MsgShowMenu = get_user_msgid("ShowMenu")
	g_MsgMOTD = get_user_msgid("MOTD")
	g_MsgClCorpse = get_user_msgid("ClCorpse")

	register_message(g_MsgStatusText, "msg_statustext")
	register_message(g_MsgStatusIcon, "msg_statusicon")
	register_message(g_MsgVGUIMenu, "msg_vguimenu")
	register_message(g_MsgShowMenu, "msg_showmenu")
	register_message(g_MsgMOTD, "msg_motd")
	register_message(g_MsgClCorpse, "msg_clcorpse")

	register_event("CurWeapon", "current_weapon", "be", "1=1", "2=29")
	register_event("StatusValue", "player_status", "be", "1=2", "2!0")
	register_event("StatusValue", "player_status", "be", "1=1", "2=0")

	register_impulse(100, "impulse_100")

	RegisterHam(Ham_Spawn, "player", "player_spawn", 1)
	RegisterHam(Ham_TakeDamage, "player", "player_damage")
	RegisterHam(Ham_TraceAttack, "player", "player_attack")
	RegisterHam(Ham_TraceAttack, "func_button", "button_attack")
	RegisterHam(Ham_Killed, "player", "player_killed", 1)
	RegisterHam(Ham_Touch, "weapon_hegrenade", "player_touchweapon")
	RegisterHam(Ham_Touch, "weaponbox", "player_touchweapon")
	RegisterHam(Ham_Touch, "armoury_entity", "player_touchweapon")

	register_forward(FM_SetClientKeyValue, "set_client_kv")
	register_forward(FM_EmitSound, "sound_emit")
	register_forward(FM_Voice_SetClientListening, "voice_listening")
	register_forward(FM_CmdStart, "player_cmdstart", 1)

	register_logevent("round_end", 2, "1=Round_End")
	register_logevent("round_first", 2, "0=World triggered", "1&Restart_Round_")
	register_logevent("round_first", 2, "0=World triggered", "1=Game_Commencing")
	register_logevent("round_start", 2, "0=World triggered", "1=Round_Start")

	register_menucmd(register_menuid(TEAM_MENU), 51, "team_select") 
	register_menucmd(register_menuid(TEAM_MENU2), 51, "team_select") 

	register_clcmd("jointeam", "cmd_jointeam")
	register_clcmd("joinclass", "cmd_joinclass")
	register_clcmd("+simonvoice", "cmd_voiceon")
	register_clcmd("-simonvoice", "cmd_voiceoff")

	register_clcmd("say /fd", "cmd_freeday")
	register_clcmd("say /freeday", "cmd_freeday")
	register_clcmd("say /day", "cmd_freeday")
	register_clcmd("say /lr", "cmd_lastrequest")
	register_clcmd("say /lastrequest", "cmd_lastrequest")
	register_clcmd("say /duel", "cmd_lastrequest")
	register_clcmd("say /simon", "cmd_simon")
	register_clcmd("say /open", "cmd_open")
	register_clcmd("say /nomic", "cmd_nomic")
	register_clcmd("say /box", "cmd_box")
	register_clcmd("say /help", "cmd_help")

	register_clcmd("jbe_freeday", "adm_freeday", ADMIN_KICK)
	register_concmd("jbe_nomic", "adm_nomic", ADMIN_KICK)
	register_concmd("jbe_open", "adm_open", ADMIN_KICK)
	register_concmd("jbe_box", "adm_box", ADMIN_KICK)
 
	gp_GlowModels = register_cvar("jbe_glowmodels", "0")
	gp_SimonSteps = register_cvar("jbe_simonsteps", "1")
	gp_CrowbarMul = register_cvar("jbe_crowbarmultiplier", "25.0")
	gp_CrowbarMax = register_cvar("jbe_maxcrowbar", "1")
	gp_TeamRatio = register_cvar("jbe_teamratio", "3")
	gp_TeamChange = register_cvar("jbe_teamchange", "0") // 0-disable team change for tt / 1-enable team change
	gp_CtMax = register_cvar("jbe_maxct", "6")
	gp_BoxMax = register_cvar("jbe_boxmax", "6")
	gp_RetryTime = register_cvar("jbe_retrytime", "10.0")
	gp_RoundMax = register_cvar("jbe_freedayround", "240.0")
	gp_AutoLastresquest = register_cvar("jbe_autolastrequest", "1")
	gp_LastRequest = register_cvar("jbe_lastrequest", "1")
	gp_Motd = register_cvar("jbe_motd", "1")
	gp_SpectRounds = register_cvar("jbe_spectrounds", "3")
	gp_NosimonRounds = register_cvar("jbe_nosimonrounds", "7")
	gp_SimonRandom = register_cvar("jbe_randomsimon", "0")
	gp_AutoOpen = register_cvar("jbe_autoopen", "1")
	gp_TalkMode = register_cvar("jbe_talkmode", "2")	// 0-alltak / 1-tt talk / 2-tt no talk
	gp_VoiceBlock = register_cvar("jbe_blockvoice", "2")	// 0-dont block / 1-block voicerecord / 2-block voicerecord except simon
	gp_ButtonShoot = register_cvar("jbe_buttonshoot", "1")	// 0-standard / 1-func_button shoots!
 
	g_MaxClients = get_global_int(GL_maxClients)
 
	for(new i = 0; i < sizeof(g_HudSync); i++)
		g_HudSync[i][_hudsync] = CreateHudSyncObj()

	formatex(g_HelpText, charsmax(g_HelpText), "%L^n^n%L^n^n%L^n^n%L",
			LANG_SERVER, "JBE_HELP_TITLE",
			LANG_SERVER, "JBE_HELP_BINDS",
			LANG_SERVER, "JBE_HELP_GUARD_CMDS",
			LANG_SERVER, "JBE_HELP_PRISONER_CMDS")

	setup_buttons()
}
 
public plugin_precache()
{
	static i
	precache_model("models/player/jbemodel/jbemodel.mdl")
 
	for(i = 0; i < sizeof(_FistModels); i++)
		precache_model(_FistModels[i])
 
	for(i = 0; i < sizeof(_CrowbarModels); i++)
		precache_model(_CrowbarModels[i])
 
	for(i = 0; i < sizeof(_FistSounds); i++)
		precache_sound(_FistSounds[i])

	precache_sound("jbextreme/nm_goodbadugly.wav")
	precache_sound("jbextreme/brass_bell_C.wav")
 
 	g_CellManagers = TrieCreate()
	gp_PrecacheSpawn = register_forward(FM_Spawn, "precache_spawn", 1)
	gp_PrecacheKeyValue = register_forward(FM_KeyValue, "precache_keyvalue", 1)
}

public precache_spawn(ent)
{
	if(is_valid_ent(ent))
	{
		static szClass[33]
		entity_get_string(ent, EV_SZ_classname, szClass, sizeof(szClass))
		for(new i = 0; i < sizeof(_RemoveEntities); i++)
			if(equal(szClass, _RemoveEntities[i]))
				remove_entity(ent)
	}
}

public precache_keyvalue(ent, kvd_handle)
{
	static info[32]
	if(!is_valid_ent(ent))
		return FMRES_IGNORED

	get_kvd(kvd_handle, KV_ClassName, info, charsmax(info))
	if(!equal(info, "multi_manager"))
		return FMRES_IGNORED

	get_kvd(kvd_handle, KV_KeyName, info, charsmax(info))
	TrieSetCell(g_CellManagers, info, ent)
	return FMRES_IGNORED
}

public client_putinserver(id)
{
	clear_bit(g_PlayerJoin, id)
	clear_bit(g_PlayerHelp, id)
	clear_bit(g_PlayerCrowbar, id)
	clear_bit(g_PlayerNomic, id)
	clear_bit(g_PlayerWanted, id)
	clear_bit(g_SimonTalking, id)
	clear_bit(g_SimonVoice, id)
	g_PlayerSpect[id] = 0
	g_PlayerSimon[id] = 0
}

public client_disconnect(id)
{
	if(g_Simon == id)
	{
		g_Simon = 0
		ClearSyncHud(0, g_HudSync[2][_hudsync])
		player_hudmessage(0, 2, 5.0, _, "%L", LANG_SERVER, "JBE_SIMON_HASGONE")
	}
	else if(g_PlayerLast == id || (g_Duel && (id == g_DuelA || id == g_DuelB)))
	{
		g_Duel = 0
		g_DuelA = 0
		g_DuelB = 0
		g_LastDenied = 0
		g_BlockWeapons = 0
		g_PlayerLast = 0
	}
	team_count()
}

public client_PostThink(id)
{
	if(id != g_Simon || !gc_SimonSteps || !is_user_alive(id) ||
		!(entity_get_int(id, EV_INT_flags) & FL_ONGROUND) || entity_get_int(id, EV_ENT_groundentity))
		return PLUGIN_CONTINUE
	
	static Float:origin[3]
	static Float:last[3]

	entity_get_vector(id, EV_VEC_origin, origin)
	if(get_distance_f(origin, last) < 32.0)
	{
		return PLUGIN_CONTINUE
	}

	vec_copy(origin, last)
	if(entity_get_int(id, EV_INT_bInDuck))
		origin[2] -= 18.0
	else
		origin[2] -= 36.0


	message_begin(MSG_BROADCAST, SVC_TEMPENTITY, {0,0,0}, 0)
	write_byte(TE_WORLDDECAL)
	write_coord(floatround(origin[0]))
	write_coord(floatround(origin[1]))
	write_coord(floatround(origin[2]))
	write_byte(105)
	message_end()

	return PLUGIN_CONTINUE
}

 
public msg_statustext(msgid, dest, id)
{
	return PLUGIN_HANDLED
}

public msg_statusicon(msgid, dest, id)
{
	static icon[5] 
	get_msg_arg_string(2, icon, charsmax(icon))
	if(icon[0] == 'b' && icon[2] == 'y' && icon[3] == 'z')
	{
		set_pdata_int(id, 235, get_pdata_int(id, 235) & ~(1<<0))
		return PLUGIN_HANDLED
	}

	return PLUGIN_CONTINUE
}

public msg_vguimenu(msgid, dest, id)
{
	static msgarg1
	static CsTeams:team

	msgarg1 = get_msg_arg_int(1)
	if(msgarg1 == 2)
	{
		team = cs_get_user_team(id)
		if((team == CS_TEAM_T) && !is_user_admin(id) && (is_user_alive(id) || !get_pcvar_num(gp_TeamChange)))
		{
			client_print(id, print_center, "%L", LANG_SERVER, "JBE_TEAM_CANTCHANGE")
			return PLUGIN_HANDLED
		}
		show_menu(id, 51, TEAM_MENU, -1)
		return PLUGIN_HANDLED
	}

	return PLUGIN_CONTINUE
}

public msg_showmenu(msgid, dest, id)
{
	static msgarg1, roundloop
	static CsTeams:team
	msgarg1 = get_msg_arg_int(1)

	if(msgarg1 != 531 && msgarg1 != 563)
		return PLUGIN_CONTINUE

	roundloop = floatround(get_pcvar_float(gp_RetryTime) / 2)
	team = cs_get_user_team(id)

	if(team == CS_TEAM_T)
	{
		if(!is_user_admin(id) && (is_user_alive(id) || (g_RoundStarted >= roundloop) || !get_pcvar_num(gp_TeamChange)))
		{
			client_print(id, print_center, "%L", LANG_SERVER, "JBE_TEAM_CANTCHANGE")
			return PLUGIN_HANDLED
		}
		else
		{
			show_menu(id, 51, TEAM_MENU, -1)
			return PLUGIN_HANDLED
		}
	}
	else
	{
		show_menu(id, 51, TEAM_MENU, -1)
		return PLUGIN_HANDLED
	}

	return PLUGIN_CONTINUE
}

public msg_motd(msgid, dest, id)
{
	if(get_pcvar_num(gp_Motd))
		return PLUGIN_HANDLED

	return PLUGIN_CONTINUE
}

public msg_clcorpse(msgid, dest, id)
{
	return PLUGIN_HANDLED
}

public current_weapon(id)
{
	if(!is_user_alive(id))
		return PLUGIN_CONTINUE

	if(get_bit(g_PlayerCrowbar, id))
	{
		set_pev(id, pev_viewmodel2, _CrowbarModels[1])
		set_pev(id, pev_weaponmodel2, _CrowbarModels[0])
	}
	else
	{
		set_pev(id, pev_viewmodel2, _FistModels[1])
		set_pev(id, pev_weaponmodel2, _FistModels[0])
	}
	return PLUGIN_CONTINUE
}

public player_status(id)
{
	static type, player, CsTeams:team, name[32], health
	type = read_data(1)
	player = read_data(2)
	switch(type)
	{
		case(1):
		{
			ClearSyncHud(id, g_HudSync[1][_hudsync])
		}
		case(2):
		{
			team = cs_get_user_team(player)
			if((team != CS_TEAM_T) && (team != CS_TEAM_CT))
				return PLUGIN_HANDLED

			health = get_user_health(player)
			get_user_name(player, name, charsmax(name))
			player_hudmessage(id, 4, 2.0, {0, 255, 0}, "%L", LANG_SERVER,
				(team == CS_TEAM_T) ? "JBE_PRISONER_STATUS" : "JBE_GUARD_STATUS", name, health)
		}
	}
	
	return PLUGIN_HANDLED
}

public impulse_100(id)
{
	if(cs_get_user_team(id) == CS_TEAM_T)
		return PLUGIN_HANDLED

	return PLUGIN_CONTINUE
}

public player_spawn(id)
{
	static CsTeams:team

	if(!is_user_connected(id))
		return HAM_IGNORED

	set_pdata_float(id, m_fNextHudTextArgsGameTime, get_gametime() + 999999.0)
	player_strip_weapons(id)
	if(g_RoundEnd)
	{
		g_RoundEnd = 0
		g_JailDay++
	}

	set_user_rendering(id, kRenderFxNone, 0, 0, 0, kRenderNormal, 0)

	clear_bit(g_PlayerCrowbar, id)
	clear_bit(g_PlayerWanted, id)
	team = cs_get_user_team(id)

	switch(team)
	{
		case(CS_TEAM_T):
		{
			g_PlayerLast = 0
			if(!g_PlayerReason[id])
				g_PlayerReason[id] = random_num(1, 6)

			player_hudmessage(id, 0, 5.0, {255, 0, 255}, "%L %L", LANG_SERVER, "JBE_PRISONER_REASON",
				LANG_SERVER, g_Reasons[g_PlayerReason[id]])

			set_user_info(id, "model", "jbemodel")
			entity_set_int(id, EV_INT_body, 2)
			if(is_freeday() || get_bit(g_FreedayAuto, id))
			{
				freeday_set(0, id)
				clear_bit(g_FreedayAuto, id)
			}
			else
			{
				entity_set_int(id, EV_INT_skin, random_num(0, 2))
			}

			if(g_CrowbarCount < get_pcvar_num(gp_CrowbarMax))
			{
				if(random_num(0, g_MaxClients) > (g_MaxClients / 2))
				{
					g_CrowbarCount++
					set_bit(g_PlayerCrowbar, id)
				}
			}
			cs_set_user_armor(id, 0, CS_ARMOR_NONE)
		}
		case(CS_TEAM_CT):
		{
			g_PlayerSimon[id]++
			set_user_info(id, "model", "jbemodel")
			entity_set_int(id, EV_INT_body, 3)
			cs_set_user_armor(id, 100, CS_ARMOR_VESTHELM)
		}
	}
	first_join(id)
	return HAM_IGNORED
}

public player_damage(victim, ent, attacker, Float:damage, bits)
{
	if(!is_user_connected(victim) || !is_user_connected(attacker) || victim == attacker)
		return HAM_IGNORED

	switch(g_Duel)
	{
		case(0):
		{
			if(attacker == ent && get_user_weapon(attacker) == CSW_KNIFE && get_bit(g_PlayerCrowbar, attacker) && cs_get_user_team(victim) != CS_TEAM_T)
			{
				SetHamParamFloat(4, damage * gc_CrowbarMul)
				return HAM_OVERRIDE
			}
		}
		case(2):
		{
			if(attacker != g_PlayerLast)
				return HAM_SUPERCEDE
		}
		default:
		{
			if((victim == g_DuelA && attacker == g_DuelB) || (victim == g_DuelB && attacker == g_DuelA))
				return HAM_IGNORED
	
			return HAM_SUPERCEDE
		}
	}

	return HAM_IGNORED
}

public player_attack(victim, attacker, Float:damage, Float:direction[3], tracehandle, damagebits)
{
	static CsTeams:vteam, CsTeams:ateam
	if(!is_user_connected(victim) || !is_user_connected(attacker) || victim == attacker)
		return HAM_IGNORED

	vteam = cs_get_user_team(victim)
	ateam = cs_get_user_team(attacker)

	if(ateam == CS_TEAM_CT && vteam == CS_TEAM_CT)
		return HAM_SUPERCEDE

	switch(g_Duel)
	{
		case(0):
		{
			if(ateam == CS_TEAM_CT && vteam == CS_TEAM_T)
			{
				if(get_bit(g_PlayerRevolt, victim))
				{
					clear_bit(g_PlayerRevolt, victim)
					hud_status(0)
				}
				return HAM_IGNORED
			}
		}
		case(2):
		{
			if(attacker != g_PlayerLast)
				return HAM_SUPERCEDE
		}
		default:
		{
			if((victim == g_DuelA && attacker == g_DuelB) || (victim == g_DuelB && attacker == g_DuelA))
				return HAM_IGNORED

			return HAM_SUPERCEDE
		}
	}

	if(ateam == CS_TEAM_T && vteam == CS_TEAM_T && !g_BoxStarted)
		return HAM_SUPERCEDE

	if(ateam == CS_TEAM_T && vteam == CS_TEAM_CT)
	{
		if(!g_PlayerRevolt)
			revolt_start()

		set_bit(g_PlayerRevolt, attacker)
	}

	return HAM_IGNORED
}

public button_attack(button, id, Float:damage, Float:direction[3], tracehandle, damagebits)
{
	if(is_valid_ent(button) && gc_ButtonShoot)
	{
		ExecuteHamB(Ham_Use, button, id, 0, 2, 1.0)
		entity_set_float(button, EV_FL_frame, 0.0)
	}

	return HAM_IGNORED
}

public player_killed(victim, attacker, shouldgib)
{
	static CsTeams:vteam, CsTeams:kteam
	if(!(0 < attacker <= g_MaxClients) || !is_user_connected(attacker))
		kteam = CS_TEAM_UNASSIGNED
	else
		kteam = cs_get_user_team(attacker)

	vteam = cs_get_user_team(victim)
	if(g_Simon == victim)
	{
		g_Simon = 0
		ClearSyncHud(0, g_HudSync[2][_hudsync])
		player_hudmessage(0, 2, 5.0, _, "%L", LANG_SERVER, "JBE_SIMON_KILLED")
	}

	switch(g_Duel)
	{
		case(0):
		{
			switch(vteam)
			{
				case(CS_TEAM_CT):
				{
					if(kteam == CS_TEAM_T && !get_bit(g_PlayerWanted, attacker))
					{
						set_bit(g_PlayerWanted, attacker)
						entity_set_int(attacker, EV_INT_skin, 4)
					}
				}
				case(CS_TEAM_T):
				{
					clear_bit(g_PlayerRevolt, victim)
					clear_bit(g_PlayerWanted, victim)
				}
			}
		}
		default:
		{
			if(g_Duel != 2 && (attacker == g_DuelA || attacker == g_DuelB))
			{
				set_user_rendering(victim, kRenderFxNone, 0, 0, 0, kRenderNormal, 0)
				set_user_rendering(attacker, kRenderFxNone, 0, 0, 0, kRenderNormal, 0)
				g_Duel = 0
				g_LastDenied = 0
				g_BlockWeapons = 0
				g_PlayerLast = 0
				team_count()
			}
		}
	}
	hud_status(0)
	return HAM_IGNORED
}

public player_touchweapon(id, ent)
{
	static model[32], class[32]
	if(g_BlockWeapons)
		return HAM_SUPERCEDE

	if(is_valid_ent(id) && g_Duel != 6 && is_user_alive(ent) && cs_get_user_team(ent) == CS_TEAM_CT)
	{
		entity_get_string(id, EV_SZ_model, model, charsmax(model))
		if(model[7] == 'w' && model[9] == 'h' && model[10] == 'e' && model[11] == 'g')
		{
			entity_get_string(id, EV_SZ_classname, class, charsmax(class))
			if(equal(class, "weapon_hegrenade"))
				remove_entity(id)

			return HAM_SUPERCEDE
		}

	}

	return HAM_IGNORED
}

public set_client_kv(id, const info[], const key[])
{
	if(equal(key, "model"))
		return FMRES_SUPERCEDE

	return FMRES_IGNORED
}

public sound_emit(id, channel, sample[])
{
	if(is_user_alive(id) && equal(sample, "weapons/knife_", 14))
	{
		switch(sample[17])
		{
			case('b'):
			{
				emit_sound(id, CHAN_WEAPON, "weapons/cbar_hitbod2.wav", 1.0, ATTN_NORM, 0, PITCH_NORM)
			}
			case('w'):
			{
				emit_sound(id, CHAN_WEAPON, "weapons/cbar_hitbod1.wav", 1.0, ATTN_NORM, 0, PITCH_LOW)
			}
			case('1', '2'):
			{
				emit_sound(id, CHAN_WEAPON, "weapons/bullet_hit2.wav", random_float(0.5, 1.0), ATTN_NORM, 0, PITCH_NORM)
			}
		}
		return FMRES_SUPERCEDE
	}
	return FMRES_IGNORED
}

public voice_listening(receiver, sender, bool:listen)
{
	if((receiver == sender))
		return FMRES_IGNORED

	if(is_user_admin(sender))
	{
		engfunc(EngFunc_SetClientListening, receiver, sender, true)
		return FMRES_SUPERCEDE
	}

	switch(gc_VoiceBlock)
	{
		case(2):
		{
			if((sender != g_Simon) && (!get_bit(g_SimonVoice, sender) && gc_VoiceBlock))
			{
				engfunc(EngFunc_SetClientListening, receiver, sender, false)
				return FMRES_SUPERCEDE
			}
		}
		case(1):
		{
			if(!get_bit(g_SimonVoice, sender) && gc_VoiceBlock)
			{
				engfunc(EngFunc_SetClientListening, receiver, sender, false)
				return FMRES_SUPERCEDE
			}
		}
	}
	if(!is_user_alive(sender))
	{
		engfunc(EngFunc_SetClientListening, receiver, sender, false)
		return FMRES_SUPERCEDE
	}

	if(sender == g_Simon)
	{
		engfunc(EngFunc_SetClientListening, receiver, sender, true)
		return FMRES_SUPERCEDE
	}

	listen = true

	if(g_SimonTalking && (sender != g_Simon))
	{
		listen = false
	}
	else
	{
		static CsTeams:steam
		steam = cs_get_user_team(sender)
		switch(gc_TalkMode)
		{
			case(2):
			{
				listen = (steam == CS_TEAM_CT)
			}
			case(1):
			{
				listen = (steam == CS_TEAM_CT || steam == CS_TEAM_T)
			}
		}
	}

	engfunc(EngFunc_SetClientListening, receiver, sender, listen)
	return FMRES_SUPERCEDE
}

public player_cmdstart(id, uc, random)
{
	if(g_Duel > 3)
	{
		cs_set_user_bpammo(id, _Duel[g_Duel - 4][_csw], 1)
	}
}

public round_first()
{
	g_JailDay = 0
	for(new i = 1; i <= g_MaxClients; i++)
		g_PlayerSimon[i] = 0

	set_cvar_num("sv_alltalk", 1)
	set_cvar_num("mp_roundtime", 2)
	set_cvar_num("mp_limitteams", 0)
	set_cvar_num("mp_autoteambalance", 0)
	set_cvar_num("mp_tkpunish", 0)
	set_cvar_num("mp_friendlyfire", 1)
	round_end()
}

public round_end()
{
	static CsTeams:team
	static maxnosimon, spectrounds
	g_SafeTime = 0
	g_PlayerRevolt = 0
	g_PlayerFreeday = 0
	g_PlayerLast = 0
	g_BoxStarted = 0
	g_CrowbarCount = 0
	g_Simon = 0
	g_SimonAllowed = 0
	g_RoundStarted = 0
	g_LastDenied = 0
	g_BlockWeapons = 0
	g_TeamCount[CS_TEAM_T] = 0
	g_TeamCount[CS_TEAM_CT] = 0
	g_Freeday = 0
	g_FreedayNext = (random_num(0,99) >= 95)
	g_RoundEnd = 1
	g_Duel = 0

	remove_task(TASK_STATUS)
	remove_task(TASK_FREEDAY)
	remove_task(TASK_FREEEND)
	remove_task(TASK_ROUND)
	maxnosimon = get_pcvar_num(gp_NosimonRounds)
	spectrounds = get_pcvar_num(gp_SpectRounds)
	for(new i = 1; i <= g_MaxClients; i++)
	{
		if(!is_user_connected(i))
			continue

		menu_cancel(i)
		team = cs_get_user_team(i)
		player_strip_weapons(i)
		switch(team)
		{
			case(CS_TEAM_CT):
			{
				if(g_PlayerSimon[i] > maxnosimon)
				{
					cmd_nomic(i)
				}
			}
			case(CS_TEAM_SPECTATOR,CS_TEAM_UNASSIGNED):
			{
				g_PlayerSpect[i]++
				if(g_PlayerSpect[i] > spectrounds)
				{
					client_cmd(i, "disconnect")
					server_print("JBE Disconnected spectator client #%i", i)
				}
				else
				{
					show_menu(i, 51, TEAM_MENU, -1)
				}
			}
		}
	}
	for(new i = 0; i < sizeof(g_HudSync); i++)
		ClearSyncHud(0, g_HudSync[i][_hudsync])

}

public round_start()
{
	if(g_RoundEnd)
		return

	team_count()
	if(!g_Simon && is_freeday())
	{
		g_Freeday = 1
		emit_sound(0, CHAN_AUTO, "jbextreme/brass_bell_C.wav", 1.0, ATTN_NORM, 0, PITCH_NORM)
		check_freeday(TASK_FREEDAY)
	}
	else
	{
		set_task(60.0, "check_freeday", TASK_FREEDAY)
	}
	set_task(HUD_DELAY, "hud_status", TASK_STATUS, _, _, "b")
	set_task(get_pcvar_float(gp_RetryTime) + 1.0, "safe_time", TASK_SAFETIME)
	set_task(120.0, "freeday_end", TASK_FREEDAY)
	g_SimonRandom = get_pcvar_num(gp_SimonRandom) ? random_float(15.0, 45.0) : 0.0
	g_SimonAllowed = 1
	g_FreedayNext = 0
}

public cmd_jointeam(id)
{
	return PLUGIN_HANDLED
}

public cmd_joinclass(id)
{
	return PLUGIN_HANDLED
}

public cmd_voiceon(id)
{
	client_cmd(id, "+voicerecord")
	set_bit(g_SimonVoice, id)
	if(g_Simon == id || is_user_admin(id))
		set_bit(g_SimonTalking, id)

	return PLUGIN_HANDLED
}

public cmd_voiceoff(id)
{
	client_cmd(id, "-voicerecord")
	clear_bit(g_SimonVoice, id)
	if(g_Simon == id || is_user_admin(id))
		clear_bit(g_SimonTalking, id)

	return PLUGIN_HANDLED
}

public cmd_simon(id)
{
	static CsTeams:team, name[32]
	if(!is_user_connected(id))
		return PLUGIN_HANDLED

	team = cs_get_user_team(id)
	if(g_SimonAllowed && !g_Freeday && is_user_alive(id) && team == CS_TEAM_CT && !g_Simon)
	{
		g_Simon = id
		get_user_name(id, name, charsmax(name))
		entity_set_int(id, EV_INT_body, 1)
		g_PlayerSimon[id]--
		if(get_pcvar_num(gp_GlowModels))
			player_glow(id, g_Colors[0])

		hud_status(0)
	}
	return PLUGIN_HANDLED
}

public cmd_open(id)
{
	if(id == g_Simon)
		jail_open()

	return PLUGIN_HANDLED
}

public cmd_nomic(id)
{
	static CsTeams:team
	team = cs_get_user_team(id)
	if(team == CS_TEAM_CT)
	{
		server_print("JBE Transfered guard to prisoners team client #%i", id)
		if(g_Simon == id)
		{
			g_Simon = 0
			player_hudmessage(0, 2, 5.0, _, "%L", LANG_SERVER, "JBE_SIMON_TRANSFERED")
		}
		if(!is_user_admin(id))
			set_bit(g_PlayerNomic, id)

		user_silentkill(id)
		cs_set_user_team(id, CS_TEAM_T)
	}
	return PLUGIN_HANDLED
}

public cmd_box(id)
{
	static i
	if((id < 0) || (is_user_alive(id) && cs_get_user_team(id) == CS_TEAM_CT))
	{
		if(g_TeamAlive[CS_TEAM_T] <= get_pcvar_num(gp_BoxMax) && g_TeamAlive[CS_TEAM_T] > 1)
		{
			for(i = 1; i <= g_MaxClients; i++)
				if(is_user_alive(i) && cs_get_user_team(i) == CS_TEAM_T)
					set_user_health(i, 100)

			set_cvar_num("mp_tkpunish", 0)
			set_cvar_num("mp_friendlyfire", 1)
			g_BoxStarted = 1
			player_hudmessage(0, 1, 3.0, _, "%L", LANG_SERVER, "JBE_GUARD_BOX")
		}
		else
		{
			player_hudmessage(id, 1, 3.0, _, "%L", LANG_SERVER, "JBE_GUARD_CANTBOX")
		}
	}
	return PLUGIN_HANDLED
}

public cmd_help(id)
{
	if(id > g_MaxClients)
		id -= TASK_HELP

	remove_task(TASK_HELP + id)
	switch(get_bit(g_PlayerHelp, id))
	{
		case(0):
		{
			set_bit(g_PlayerHelp, id)
			player_hudmessage(id, 7, 15.0, {230, 100, 10}, "%s", g_HelpText)
			set_task(15.0, "cmd_help", TASK_HELP + id)
		}
		default:
		{
			clear_bit(g_PlayerHelp, id)
			ClearSyncHud(id, g_HudSync[7][_hudsync])
		}
	}
}

public cmd_freeday(id)
{
	static menu, menuname[32], option[64]
	if(!is_freeday() && ((is_user_alive(id) && cs_get_user_team(id) == CS_TEAM_CT) || is_user_admin(id)))
	{
		formatex(menuname, charsmax(menuname), "%L", LANG_SERVER, "JBE_MENU_FREEDAY")
		menu = menu_create(menuname, "freeday_choice")

		formatex(option, charsmax(option), "%L", LANG_SERVER, "JBE_MENU_FREEDAY_PLAYER")
		menu_additem(menu, option, "1", 0)

		formatex(option, charsmax(option), "%L", LANG_SERVER, "JBE_MENU_FREEDAY_ALL")
		menu_additem(menu, option, "2", 0)

		menu_display(id, menu)
	}
	return PLUGIN_HANDLED
}

public cmd_freeday_player(id)
{
	if((is_user_alive(id) && cs_get_user_team(id) == CS_TEAM_CT) || is_user_admin(id))
		menu_players(id, CS_TEAM_T, id, 1, "freeday_select", "%L", LANG_SERVER, "JBE_MENU_FREEDAY")

	return PLUGIN_CONTINUE
}

public cmd_lastrequest(id)
{
	static i, num[5], menu, menuname[32], option[64]
	if(!get_pcvar_num(gp_LastRequest) || g_Freeday || g_LastDenied || id != g_PlayerLast || g_RoundEnd || get_bit(g_PlayerWanted, id) || get_bit(g_PlayerFreeday, id) || !is_user_alive(id))
		return PLUGIN_CONTINUE

	formatex(menuname, charsmax(menuname), "%L", LANG_SERVER, "JBE_MENU_LASTREQ")
	menu = menu_create(menuname, "lastrequest_select")

	formatex(option, charsmax(option), "%L", LANG_SERVER, "JBE_MENU_LASTREQ_OPT1")
	menu_additem(menu, option, "1", 0)

	formatex(option, charsmax(option), "%L", LANG_SERVER, "JBE_MENU_LASTREQ_OPT2")
	menu_additem(menu, option, "2", 0)

	formatex(option, charsmax(option), "%L", LANG_SERVER, "JBE_MENU_LASTREQ_OPT3")
	menu_additem(menu, option, "3", 0)

	for(i = 0; i < sizeof(_Duel); i++)
	{
		num_to_str(i + 4, num, charsmax(num))
		formatex(option, charsmax(option), "%L", LANG_SERVER, _Duel[i][_opt])
		menu_additem(menu, option, num, 0)
	}

	menu_display(id, menu)
	return PLUGIN_CONTINUE
}

public adm_freeday(id)
{
	static player, user[32]
	if(!is_user_admin(id))
		return PLUGIN_CONTINUE

	read_argv(1, user, charsmax(user))
	player = cmd_target(id, user, 2)
	if(is_user_connected(player) && cs_get_user_team(player) == CS_TEAM_T)
	{
		freeday_set(id, player)
	}
	return PLUGIN_HANDLED
}

public adm_nomic(id)
{
	static player, user[32]
	if(id == 0 || is_user_admin(id))
	{
		read_argv(1, user, charsmax(user))
		player = cmd_target(id, user, 3)
		if(is_user_connected(player))
		{
			cmd_nomic(player)
		}
	}
	return PLUGIN_HANDLED
}

public adm_open(id)
{
	if(!is_user_admin(id))
		return PLUGIN_CONTINUE

	jail_open()
	return PLUGIN_HANDLED
}

public adm_box(id)
{
	if(!is_user_admin(id))
		return PLUGIN_CONTINUE

	cmd_box(-1)
	return PLUGIN_HANDLED
}

public team_select(id, key)
{
	static CsTeams:team, roundloop, admin

	roundloop = get_pcvar_num(gp_RetryTime) / 2
	team = cs_get_user_team(id)
	admin = is_user_admin(id)
	team_count()

	if(!admin && (team == CS_TEAM_UNASSIGNED) && (g_RoundStarted >= roundloop) && g_TeamCount[CS_TEAM_CT] && g_TeamCount[CS_TEAM_T] && !is_user_alive(id))
	{
		team_join(id, CS_TEAM_SPECTATOR)
		client_print(id, print_center, "%L", LANG_SERVER, "JBE_TEAM_CANTJOIN")
		return PLUGIN_HANDLED
	}


	switch(key)
	{
		case(0):
		{
			if(team == CS_TEAM_T)
				return PLUGIN_HANDLED

			g_PlayerReason[id] = random_num(1, 6)

			team_join(id, CS_TEAM_T)
		}
		case(1):
		{
			if(team == CS_TEAM_CT || (!admin && get_bit(g_PlayerNomic, id)))
				return PLUGIN_HANDLED

			if(g_TeamCount[CS_TEAM_CT] < ctcount_allowed() || admin)
				team_join(id, CS_TEAM_CT)
			else
				client_print(id, print_center, "%L", LANG_SERVER, "JBE_TEAM_CTFULL")
		}
		case(5):
		{
			user_silentkill(id)
			team_join(id, CS_TEAM_SPECTATOR)
		}
	}
	return PLUGIN_HANDLED
}

public team_join(id, CsTeams:team)
{
	static restore, vgui, msgblock

	restore = get_pdata_int(id, m_iVGUI)
	vgui = restore & (1<<0)
	if(vgui)
		set_pdata_int(id, m_iVGUI, restore & ~(1<<0))

	switch(team)
	{
		case CS_TEAM_SPECTATOR:
		{
			msgblock = get_msg_block(g_MsgShowMenu)
			set_msg_block(g_MsgShowMenu, BLOCK_ONCE)
			dllfunc(DLLFunc_ClientPutInServer, id)
			set_msg_block(g_MsgShowMenu, msgblock)
			set_pdata_int(id, m_fGameHUDInitialized, 1)
			engclient_cmd(id, "jointeam", "6")
		}
		case CS_TEAM_T, CS_TEAM_CT:
		{
			msgblock = get_msg_block(g_MsgShowMenu)
			set_msg_block(g_MsgShowMenu, BLOCK_ONCE)
			engclient_cmd(id, "jointeam", (team == CS_TEAM_CT) ? "2" : "1")
			engclient_cmd(id, "joinclass", "1")
			set_msg_block(g_MsgShowMenu, msgblock)
			g_PlayerSpect[id] = 0
		}
	}
	
	if(vgui)
		set_pdata_int(id, m_iVGUI, restore)
}

public team_count()
{
	static CsTeams:team, last
	g_TeamCount[CS_TEAM_UNASSIGNED] = 0
	g_TeamCount[CS_TEAM_T] = 0
	g_TeamCount[CS_TEAM_CT] = 0
	g_TeamCount[CS_TEAM_SPECTATOR] = 0
	g_TeamAlive[CS_TEAM_UNASSIGNED] = 0
	g_TeamAlive[CS_TEAM_T] = 0
	g_TeamAlive[CS_TEAM_CT] = 0
	g_TeamAlive[CS_TEAM_SPECTATOR] = 0
	for(new i = 1; i <= g_MaxClients; i++)
	{
		if(is_user_connected(i))
		{
			team = cs_get_user_team(i)
			g_TeamCount[team]++
			g_PlayerTeam[i] = team
			if(is_user_alive(i))
			{
				g_TeamAlive[team]++
				if(team == CS_TEAM_T)
					last = i
			}
		}
		else
		{
			g_PlayerTeam[i] = CS_TEAM_UNASSIGNED
		}
	}
	if(g_TeamAlive[CS_TEAM_T] == 1)
	{
		if(last != g_PlayerLast && g_SafeTime)
		{
			prisoner_last(last)
		}
	}
	else
	{
		if(g_Duel || g_DuelA || g_DuelB)
		{
			if(is_user_alive(g_DuelA))
			{
				set_user_rendering(g_DuelA, kRenderFxNone, 0, 0, 0, kRenderNormal, 0)
				player_strip_weapons(g_DuelA)
			}

			if(is_user_alive(g_DuelB))
			{
				set_user_rendering(g_DuelB, kRenderFxNone, 0, 0, 0, kRenderNormal, 0)
				player_strip_weapons(g_DuelB)
			}

		}
		g_PlayerLast = 0
		g_DuelA = 0
		g_DuelB = 0
		g_Duel = 0
	}
}

public revolt_start()
{
	client_cmd(0,"speak ambience/siren")
	set_task(8.0, "stop_sound")
	hud_status(0)
}

public stop_sound(task)
{
	client_cmd(0, "stopsound")
}

public hud_status(task)
{
	static i, n
	new name[32], szStatus[64], wanted[1024]
 
	if(g_RoundStarted < (get_pcvar_num(gp_RetryTime) / 2))
		g_RoundStarted++

	if(!g_Freeday && !g_Simon && g_SimonAllowed && (0.0 < g_SimonRandom < get_gametime()))
	{
		cmd_simon(random_num(1, g_MaxClients))
	}

	n = 0
	formatex(wanted, charsmax(wanted), "%L", LANG_SERVER, "JBE_PRISONER_WANTED")
	n = strlen(wanted)
	for(i = 0; i < g_MaxClients; i++)
	{
		if(get_bit(g_PlayerWanted, i) && is_user_alive(i) && n < charsmax(wanted))
		{
			get_user_name(i, name, charsmax(name))
			n += copy(wanted[n], charsmax(wanted) - n, "^n^t")
			n += copy(wanted[n], charsmax(wanted) - n, name)
		}
	}

	team_count()
	formatex(szStatus, charsmax(szStatus), "%L", LANG_SERVER, "JBE_STATUS", g_TeamAlive[CS_TEAM_T], g_TeamCount[CS_TEAM_T])
	message_begin(MSG_BROADCAST, get_user_msgid("StatusText"), {0,0,0}, 0)
	write_byte(0)
	write_string(szStatus)
	message_end()

	if(g_Simon)
	{
		get_user_name(g_Simon, name, charsmax(name))
		player_hudmessage(0, 2, HUD_DELAY + 1.0, {0, 255, 0}, "%L", LANG_SERVER, "JBE_SIMON_FOLLOW", name)
	}
	else if(g_Freeday)
	{
		player_hudmessage(0, 2, HUD_DELAY + 1.0, {0, 255, 0}, "%L", LANG_SERVER, "JBE_STATUS_FREEDAY")
	}

	if(g_PlayerWanted)
		player_hudmessage(0, 3, HUD_DELAY + 1.0, {255, 25, 50}, "%s", wanted)
	else if(g_PlayerRevolt)
		player_hudmessage(0, 3, HUD_DELAY + 1.0, {255, 25, 50}, "%L", LANG_SERVER, "JBE_PRISONER_REVOLT")

	player_hudmessage(0, 5, HUD_DELAY + 1.0, {0, 255, 0}, "%L", LANG_SERVER, "JBE_STATUS_DAY", g_JailDay)

	gc_TalkMode = get_pcvar_num(gp_TalkMode)
	gc_VoiceBlock = get_pcvar_num(gp_VoiceBlock)
	gc_SimonSteps = get_pcvar_num(gp_SimonSteps)
	gc_ButtonShoot = get_pcvar_num(gp_ButtonShoot)
	gc_CrowbarMul = get_pcvar_float(gp_CrowbarMul)

}

public safe_time(task)
{
	g_SafeTime = 1
}

public check_freeday(task)
{
	static Float:roundmax, i
	if(!g_Simon && !g_PlayerLast)
	{
		g_Freeday = 1
		hud_status(0)
		roundmax = get_pcvar_float(gp_RoundMax)
		if(roundmax > 0.0)
		{
			for(i = 1; i <= g_MaxClients; i++)
			{
				if(is_user_alive(i) && cs_get_user_team(i) == CS_TEAM_T)
					freeday_set(0, i)
			}
			emit_sound(0, CHAN_AUTO, "jbextreme/brass_bell_C.wav", 1.0, ATTN_NORM, 0, PITCH_NORM)
			player_hudmessage(0, 8, 3.0, {0, 255, 0}, "%L", LANG_SERVER, "JBE_STATUS_ENDTIMER", floatround(roundmax - 60.0))
			remove_task(TASK_ROUND)
			set_task(roundmax - 60.0, "check_end", TASK_ROUND)
		}
	}

	if(get_pcvar_num(gp_AutoOpen))
		jail_open()
}

public freeday_end(task)
{
	if(g_Freeday || g_PlayerFreeday)
	{
		emit_sound(0, CHAN_AUTO, "jbextreme/brass_bell_C.wav", 1.0, ATTN_NORM, 0, PITCH_NORM)
		player_hudmessage(0, 8, 3.0, {0, 255, 0}, "%L", LANG_SERVER, "JBE_STATUS_ENDFREEDAY")
	}
}

public check_end(task)
{
	team_count()
	for(new i = 1; i <= g_MaxClients; i++)
	{
		if(g_PlayerTeam[i] == CS_TEAM_T && is_user_alive(i))
		{
			user_silentkill(i)
			cs_set_user_deaths(i, get_user_deaths(i) - 1)
		}
	}
	for(new i = 1; i <= g_MaxClients; i++)
	{
		if(g_PlayerTeam[i] == CS_TEAM_CT && is_user_alive(i))
		{
			user_silentkill(i)
			cs_set_user_deaths(i, get_user_deaths(i) - 1)
		}
	}
	player_hudmessage(0, 6, 3.0, {0, 255, 0}, "%L", LANG_SERVER, "JBE_STATUS_ROUNDEND")
}

public prisoner_last(id)
{
	static name[32], Float:roundmax
	if(is_user_alive(id) && cs_get_user_team(id) == CS_TEAM_T)
	{
		roundmax = get_pcvar_float(gp_RoundMax)
		get_user_name(id, name, charsmax(name))
		g_PlayerLast = id
		player_hudmessage(0, 6, 5.0, {0, 255, 0}, "%L", LANG_SERVER, "JBE_PRISONER_LAST", name)
		remove_task(TASK_ROUND)
		if(roundmax > 0.0)
		{
			player_hudmessage(0, 8, 3.0, {0, 255, 0}, "%L", LANG_SERVER, "JBE_STATUS_ENDTIMER", floatround(roundmax - 60.0))
			set_task(roundmax - 60.0, "check_end", TASK_ROUND)
		}
		if((g_TeamAlive[CS_TEAM_CT] > 0) && get_pcvar_num(gp_AutoLastresquest))
			cmd_lastrequest(id)
	}
}

public freeday_select(id, menu, item)
{
	if(item == MENU_EXIT)
	{
		menu_destroy(menu)
		return PLUGIN_HANDLED
	}

	static dst[32], data[5], player, access, callback

	menu_item_getinfo(menu, item, access, data, charsmax(data), dst, charsmax(dst), callback)
	player = str_to_num(data)
	freeday_set(id, player)
	return PLUGIN_HANDLED
}

public duel_knives(id, menu, item)
{
	if(item == MENU_EXIT)
	{
		menu_destroy(menu)
		g_LastDenied = 0
		return PLUGIN_HANDLED
	}

	static dst[32], data[5], access, callback, option[128], player, src[32]

	menu_item_getinfo(menu, item, access, data, charsmax(data), dst, charsmax(dst), callback)
	get_user_name(id, src, charsmax(src))
	player = str_to_num(data)
	formatex(option, charsmax(option), "%L^n%L", LANG_SERVER, "JBE_MENU_LASTREQ_SEL3", src, LANG_SERVER, "JBE_MENU_DUEL_SEL", src, dst)
	player_hudmessage(0, 6, 3.0, {0, 255, 0}, option)

	g_DuelA = id
	clear_bit(g_PlayerCrowbar, id)
	player_strip_weapons(id)
	player_glow(id, g_Colors[3])
	set_user_health(id, 100)

	g_DuelB = player
	player_strip_weapons(player)
	player_glow(player, g_Colors[2])
	set_user_health(player, 100)
	g_BlockWeapons = 1
	return PLUGIN_HANDLED
}

public duel_guns(id, menu, item)
{
	if(item == MENU_EXIT)
	{
		menu_destroy(menu)
		g_LastDenied = 0
		g_Duel = 0
		return PLUGIN_HANDLED
	}

	static gun, dst[32], data[5], access, callback, option[128], player, src[32]

	menu_item_getinfo(menu, item, access, data, charsmax(data), dst, charsmax(dst), callback)
	get_user_name(id, src, charsmax(src))
	player = str_to_num(data)
	formatex(option, charsmax(option), "%L^n%L", LANG_SERVER, _Duel[g_Duel - 4][_sel], src, LANG_SERVER, "JBE_MENU_DUEL_SEL", src, dst)
	emit_sound(0, CHAN_AUTO, "jbextreme/nm_goodbadugly.wav", 1.0, ATTN_NORM, 0, PITCH_NORM)
	player_hudmessage(0, 6, 3.0, {0, 255, 0}, option)

	g_DuelA = id
	clear_bit(g_PlayerCrowbar, id)
	player_strip_weapons(id)
	gun = give_item(id, _Duel[g_Duel - 4][_entname])
	cs_set_weapon_ammo(gun, 1)
	set_user_health(id, 100)
	player_glow(id, g_Colors[3])

	g_DuelB = player
	player_strip_weapons(player)
	gun = give_item(player, _Duel[g_Duel - 4][_entname])
	cs_set_weapon_ammo(gun, 1)
	set_user_health(player, 100)
	player_glow(player, g_Colors[2])

	g_BlockWeapons = 1
	return PLUGIN_HANDLED
}

public freeday_choice(id, menu, item)
{
	if(item == MENU_EXIT)
	{
		menu_destroy(menu)
		return PLUGIN_HANDLED
	}

	static dst[32], data[5], access, callback

	menu_item_getinfo(menu, item, access, data, charsmax(data), dst, charsmax(dst), callback)
	menu_destroy(menu)
	get_user_name(id, dst, charsmax(dst))
	switch(data[0])
	{
		case('1'):
		{
			cmd_freeday_player(id)
		}
		case('2'):
		{
			if((id == g_Simon) || is_user_admin(id))
			{
				g_Simon = 0
				get_user_name(id, dst, charsmax(dst))
				client_print(0, print_console, "%s gives freeday for everyone", dst)
				server_print("JBE Client %i gives freeday for everyone", id)
				check_freeday(TASK_FREEDAY)
			}
		}
	}
	return PLUGIN_HANDLED
}

public lastrequest_select(id, menu, item)
{
	if(item == MENU_EXIT)
	{
		menu_destroy(menu)
		return PLUGIN_HANDLED
	}

	static i, dst[32], data[5], access, callback, option[64]

	menu_item_getinfo(menu, item, access, data, charsmax(data), dst, charsmax(dst), callback)
	get_user_name(id, dst, charsmax(dst))
	switch(data[0])
	{
		case('1'):
		{
			formatex(option, charsmax(option), "%L", LANG_SERVER, "JBE_MENU_LASTREQ_SEL1", dst)
			player_hudmessage(0, 6, 3.0, {0, 255, 0}, option)
			set_bit(g_FreedayAuto, id)
			user_silentkill(id)
		}
		case('2'):
		{
			formatex(option, charsmax(option), "%L", LANG_SERVER, "JBE_MENU_LASTREQ_SEL2", dst)
			player_hudmessage(0, 6, 3.0, {0, 255, 0}, option)
			g_Duel = 2
			player_strip_weapons_all()
			i = random_num(0, sizeof(_WeaponsFree) - 1)
			give_item(id, _WeaponsFree[i])
			g_BlockWeapons = 1
			cs_set_user_bpammo(id, _WeaponsFreeCSW[i], _WeaponsFreeAmmo[i])
		}
		case('3'):
		{
			g_Duel = 3
			menu_players(id, CS_TEAM_CT, 0, 1, "duel_knives", "%L", LANG_SERVER, "JBE_MENU_DUEL")
		}
		default:
		{
			g_Duel = str_to_num(data)
			menu_players(id, CS_TEAM_CT, 0, 1, "duel_guns", "%L", LANG_SERVER, "JBE_MENU_DUEL")
		}
	}
	g_LastDenied = 1
	menu_destroy(menu)
	return PLUGIN_HANDLED
}

public setup_buttons()
{
	new ent[3]
	new Float:origin[3]
	new info[32]
	new pos

	while((pos <= sizeof(g_Buttons)) && (ent[0] = engfunc(EngFunc_FindEntityByString, ent[0], "classname", "info_player_deathmatch")))
	{
		pev(ent[0], pev_origin, origin)
		while((ent[1] = engfunc(EngFunc_FindEntityInSphere, ent[1], origin, CELL_RADIUS)))
		{
			if(!is_valid_ent(ent[1]))
				continue

			entity_get_string(ent[1], EV_SZ_classname, info, charsmax(info))
			if(!equal(info, "func_door"))
				continue

			entity_get_string(ent[1], EV_SZ_targetname, info, charsmax(info))
			if(!info[0])
				continue

			if(TrieKeyExists(g_CellManagers, info))
			{
				TrieGetCell(g_CellManagers, info, ent[2])
			}
			else
			{
				ent[2] = engfunc(EngFunc_FindEntityByString, 0, "target", info)
			}

			if(is_valid_ent(ent[2]) && (in_array(ent[2], g_Buttons, sizeof(g_Buttons)) < 0))
			{
				g_Buttons[pos] = ent[2]
				pos++
				break
			}
		}
	}
	TrieDestroy(g_CellManagers)
}

stock in_array(needle, data[], size)
{
	for(new i = 0; i < size; i++)
	{
		if(data[i] == needle)
			return i
	}
	return -1
}

stock freeday_set(id, player)
{
	static src[32], dst[32]
	get_user_name(player, dst, charsmax(dst))

	if(is_user_alive(player) && !get_bit(g_PlayerWanted, player))
	{
		set_bit(g_PlayerFreeday, player)
		entity_set_int(player, EV_INT_skin, 3)
		if(get_pcvar_num(gp_GlowModels))
			player_glow(player, g_Colors[1])

		if(0 < id <= g_MaxClients)
		{
			get_user_name(id, src, charsmax(src))
			player_hudmessage(0, 6, 3.0, {0, 255, 0}, "%L", LANG_SERVER, "JBE_GUARD_FREEDAYGIVE", src, dst)
		}
		else if(!is_freeday())
		{
			player_hudmessage(0, 6, 3.0, {0, 255, 0}, "%L", LANG_SERVER, "JBE_PRISONER_HASFREEDAY", dst)
		}
	}
}

stock first_join(id)
{
	if(!get_bit(g_PlayerJoin, id))
	{
		set_bit(g_PlayerJoin, id)
		clear_bit(g_PlayerHelp, id)
		set_task(5.0, "cmd_help", TASK_HELP + id)
	}
}

stock ctcount_allowed()
{
	static count
	count = ((g_TeamCount[CS_TEAM_T] + g_TeamCount[CS_TEAM_CT]) / get_pcvar_num(gp_TeamRatio))
	if(count < 2)
		count = 2
	else if(count > get_pcvar_num(gp_CtMax))
		count = get_pcvar_num(gp_CtMax)

	return count
}

stock player_hudmessage(id, hudid, Float:time = 0.0, color[3] = {0, 255, 0}, msg[], any:...)
{
	static text[512], Float:x, Float:y
	x = g_HudSync[hudid][_x]
	y = g_HudSync[hudid][_y]
	
	if(time > 0)
		set_hudmessage(color[0], color[1], color[2], x, y, 0, 0.00, time, 0.00, 0.00)
	else
		set_hudmessage(color[0], color[1], color[2], x, y, 0, 0.00, g_HudSync[hudid][_time], 0.00, 0.00)

	vformat(text, charsmax(text), msg, 6)
	ShowSyncHudMsg(id, g_HudSync[hudid][_hudsync], text)
}

stock menu_players(id, CsTeams:team, skip, alive, callback[], title[], any:...)
{
	static i, name[32], num[5], menu, menuname[32]
	vformat(menuname, charsmax(menuname), title, 7)
	menu = menu_create(menuname, callback)
	for(i = 1; i <= g_MaxClients; i++)
	{
		if(!is_user_connected(i) || (alive && !is_user_alive(i)) || (skip == i))
			continue

 		if(!(team == CS_TEAM_T || team == CS_TEAM_CT) || ((team == CS_TEAM_T || team == CS_TEAM_CT) && (cs_get_user_team(i) == team)))
		{
			get_user_name(i, name, charsmax(name))
			num_to_str(i, num, charsmax(num))
			menu_additem(menu, name, num, 0)
		}
	}
	menu_display(id, menu)
}

stock player_glow(id, color[3], amount=40)
{
	set_user_rendering(id, kRenderFxGlowShell, color[0], color[1], color[2], kRenderNormal, amount)
}

stock player_strip_weapons(id)
{
	strip_user_weapons(id)
	give_item(id, "weapon_knife")
	set_pdata_int(id, m_iPrimaryWeapon, 0)
}

stock player_strip_weapons_all()
{
	for(new i = 1; i <= g_MaxClients; i++)
	{
		if(is_user_alive(i))
		{
			player_strip_weapons(i)
		}
	}
}

stock is_freeday()
{
	return (g_FreedayNext || g_Freeday || (g_JailDay == 1))
}

public jail_open()
{
	static i
	for(i = 0; i < sizeof(g_Buttons); i++)
	{
		if(g_Buttons[i])
		{
			ExecuteHamB(Ham_Use, g_Buttons[i], 0, 0, 1, 1.0)
			entity_set_float(g_Buttons[i], EV_FL_frame, 0.0)
		}
	}
}
