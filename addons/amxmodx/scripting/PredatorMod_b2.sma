#include <amxmodx>
#include <amxmisc>
#include <cstrike>
#include <fakemeta>
#include <fun>
#include <xs>

#define PLUG_NAME	"Predator"
#define PLUG_AUTH	"SgtBane"
#define PLUG_VERS	"2.1"
#define PLUG_TAG	"PRED"
#define gamename	"PWND | Predator Mod"

#define THING_KNIFE_V_VIS	"models/Knives/v_zomb.mdl"
#define THING_KNIFE_V_INV	"models/Knives/v_zomb.mdl"
//#define THING_KNIFE_P	"models/pred/p_claw.mdl"		9520
#define THING_VIEW		"models/ThingView.mdl"
#define THING_SLAMSND	"pred/dirtpound.wav"

#define menusize			255

#define offset_flashlight		100
#define offset_enforcecvar		150
#define offset_ticker			200
#define offset_dimlights		250
#define offset_invisrecover		300
#define offset_playerdieing		350
#define offset_findfeedtarget	400
#define offset_playerfeeding	450
#define offset_buytimeend		500

#define minplayers			2
#define flashdrain			2	//Per 0.1 sec
#define flashcharge			3	//Per 0.1 sec
#define jumpenergy			5	//Energy per jump
#define poundenergy			70	//Energy per pound
#define jumpdelay			0.3	//Delay between jumps
#define pounddelay			4.0	//Delay between ground pounds
#define poundrange			150
#define yelldelay			8.0
#define radiodelay			3.0
#define yellcharge			25	//Points gained for predator cry
#define seepreddist			450.0
#define preddevis			10	//Per 0.2 sec
#define hearfeetenergy		30
#define maxenergy			150
#define energychargecloak	1	//Energy gained per tick while cloaked
#define energychargeuncloak	5	//Energy gained per tick while not cloaked
#define deadcheckinterval	0.5
#define deadcheckmax		3.0
#define maxfeedhealth		50	//Max health gained per corpse
#define healthperfeed		5	//Ammount of health gained per 'bite'
#define feeddistance 		100	//Distance to corpse to be able to eat it	
#define feedangle 			40	
#define feedinterval 		1.0	//Interval per 'bite'
#define feedextrahealth		100	//Max health a predator can get from eating a corpse.  pThingHealth + this
#define predinforadius		5.0

#define formula_feed_time(%1,%2) floatround((feedinterval / (%1)) * (%2))
#define formula_feed_percent(%1,%2) floatround((100.0 * ((%2) - (%1))) / (%2))
#define fm_find_ent_in_sphere(%1,%2,%3) engfunc(EngFunc_FindEntityInSphere, %1, %2, %3)

new bool:gUseArnold
new const gThingModel[]		= "predator2"
new const USE_SOUND[]		= "common/wpn_denyselect.wav"
new const gEntViewClass[]	= "item_thingview"
new gEntView
new gPredator
new gNewPredator
new bool:gLive
new bool:gRunning
new bool:gBuyTime
new maxplayers

new usingnvg[33]
//new bool:Faded[33]

#define CustomItemCnt	3
#define ITEM_COLDBLOOD	0
#define ITEM_BATTERY	1
#define ITEM_BULLET		2
new bool:cCustomItems[33][CustomItemCnt]
new const cConsoleItemName[CustomItemCnt][] = {
	"coldblood",
	"battery",
	"bullet"
}
new const cCustomItemsName[CustomItemCnt][] = {
	"Cold Blood",
	"Battery",
	"UV Bullet"
}
new const cCustomItemsPrice[CustomItemCnt] = {
	2000,
	1000,
	2500
}

new modelwarns[33]
new feedhealth[33]
new feedorigin[33][3]
new cFlashlight[33]
new cFlashbattery[33] = {1000, ...}
new Float:cRadioDelay[33]

new bool:cPredUncloak
new bool:cPredFalling
new bool:cPredOnWall
new bool:cPredSpeedLock
new cPredVisib
new cPredViewStyle = 1
new cPredEnergy = maxenergy
new Float:cPredClingSpot[3]
new Float:cPredJumpDelay
new Float:cPredPoundDelay
new Float:cPredRadioDelay
new Float:cPredDistance[33]
#define VS_None 0
#define VS_Heat 1
#define VS_Grey 2

#define PredSndCnt	4
new const PredSnds[PredSndCnt][] = {
	"pred/Predyell.wav",
	"pred/predclick.wav",
	"pred/predgrowl.wav",
	"pred/predyell2.wav"
}
new const PredSndsName[PredSndCnt][] = {
	"Scream",
	"Click",
	"Growl",
	"Yell"
}
#define HumSndCnt	9
new const HumSnds[HumSndCnt][] = {
	"pred/affirm.wav",
	"pred/negative.wav",
	"pred/run.wav",
	"pred/gettochopper.wav",
	"pred/nogochoppa.wav",
	"pred/ugly.wav",
	"pred/relax.wav",
	"pred/ilied.wav",
	"pred/talktohand.wav"
}
new const HumSndsName[HumSndCnt][] = {
	"Affirmative",
	"Negative",
	"RUN!",
	"Get To The Chopper",
	"Nobody Left",
	"Ugly Mother Fucker",
	"Relax",
	"I Lied",
	"Talk To The Hand"
}
#define HumSndCnt2	9
new const HumSnds2[HumSndCnt2][] = {
	"radio/circleback.wav",
	"radio/clear.wav",
	"radio/com_go.wav",
	"radio/ct_affirm.wav",
	"radio/negative.wav",
	"radio/ct_backup.wav",
	"radio/followme.wav",
	"radio/sticktog.wav",
	"radio/meetme.wav"
}
new const HumSndsName2[HumSndCnt2][] = {
	"Circle Around Back",
	"Sector Clear",
	"Go Go Go",
	"Affirmative",
	"Negative",
	"Need Backup",
	"Follow Me",
	"Stick Togeather",
	"Meet Me"
}
#define HumSndCnt3	1
new const HumSnds3[HumSndCnt3][] = {
	"pred/ikilledyou.wav"
}
new const HumSndsName3[HumSndCnt3][] = {
	"I Killed You"
}

#define maxfeedingsounds	8
new const feedingsoundfiles[maxfeedingsounds][] = {
	"barnacle/bcl_bite3.wav",
	"barnacle/bcl_chew1.wav",
	"barnacle/bcl_chew2.wav",
	"barnacle/bcl_chew3.wav",
	"barnacle/bcl_toung1.wav",
	"bullchicken/bc_bite1.wav",
	"bullchicken/bc_bite3.wav",
	"headcrab/hc_headbite.wav"
}
#define maxdieingsounds 4
new const dieingsoundfiles[maxdieingsounds][] = {
	"agrunt/ag_die2.wav",
	"agrunt/ag_die3.wav",
	"agrunt/ag_die5.wav",
	"pred/dieing.wav"
}
#define maxpainsounds 6
new const painsoundfiles[maxpainsounds][] = {
	"aslave/slv_pain1.wav",
	"aslave/slv_pain2.wav",
	"bullchicken/bc_idle5.wav",
	"controller/con_pain1.wav",
	"controller/con_pain2.wav",
	"controller/con_pain3.wav"
}

//It will check the below cvars and change them if needed.
//If it needs to change any of them more then once, they will be kicked.
//(Either they keep setting it back, or it is locked)
new cWarns[33]
new curcvar
#define cvarcnt		4
new const cvarname[cvarcnt][] = {
	"cl_minmodels",
	"cl_shadows",
	"r_glowshellfreq",
	"brightness"
}
new const cvarval[cvarcnt][] = {
	"0",
	"0",
	"2.2",
	"3"
}

new wpnname[31][] = {
	"",
	"P228",
	"",
	"Scout",
	"Grenade",
	"XM1014 Shotgun",
	"C4",
	"Mac 10",
	"AUG",
	"Smoke",
	"Dual Elites",
	"Fiveseven",
	"UMP 45",
	"SG550",
	"Galil",
	"Famas",
	"USP",
	"Glock 18",
	"AWP",
	"MP5 Navy",
	"Para M249",
	"M3 Shotgun",
	"M4A1",
	"TMP",
	"G3SG1",
	"Flashbang",
	"Deagle",
	"SG552",
	"AK47",
	"Knife",
	"P90"
}

new pThingSpeed
new pThingHealth
new pThingHealthPP
new pThingArmor
new pThingAlpha
new pThingOverride
new pThingArnold
new pGameName

//new msgCorpse
new msgBartime
new msgFlashlight
new msgScreenFade
new msgDeathMsg
new msgScoreInfo
new msgStatusText
new msgNightVision
new msgSenario

new g_shockwave, blood, blood2
//			  ___________________
//___________/ INIT AND PRECACHE \___________________________________________________________________________________________
//**************************************************************************************************************************/
public plugin_init() {	
	register_plugin(PLUG_NAME, 				PLUG_VERS, 					PLUG_AUTH)
	//msgCorpse 		= get_user_msgid("ClCorpse")
	msgFlashlight	= get_user_msgid("Flashlight")
	msgScreenFade	= get_user_msgid("ScreenFade")
	msgDeathMsg 	= get_user_msgid("DeathMsg")
	msgScoreInfo 	= get_user_msgid("ScoreInfo")
	msgStatusText 	= get_user_msgid("StatusText")
	msgNightVision	= get_user_msgid("NVGToggle")
	msgSenario		= get_user_msgid("Scenario")
	msgBartime		= get_user_msgid("BarTime2")
	
	//register_message(msgCorpse,				"event_corpse")
	register_forward(FM_PlayerPreThink,			"fwd_prethink")
	register_forward(FM_PlayerPostThink,		"fwd_postthink")
	register_forward(FM_AddToFullPack,			"fwd_addtofullpack",		1)
	register_forward(FM_Touch,					"fwd_touch")
	register_forward(FM_CmdStart,				"fwd_cmdstart")
	register_forward(FM_EmitSound,				"fwd_emitsound")
	register_forward(FM_ClientUserInfoChanged,	"fwd_userinfochanged")
	register_forward(FM_GetGameDescription,		"fwd_gamedesc")

	register_logevent("event_roundend", 	2, 	"0=World triggered", 	"1=Round_End")
	register_logevent("event_roundstart", 	2,	"1=Round_Start")
	register_event("DeathMsg", 				"event_death", 				"a")
	register_event("Damage", 				"event_damage",				"b",	"2!0")
	register_event("CurWeapon",				"event_curweapon", 			"be", "1=1")
	register_event("ResetHUD", 				"event_resethud", 			"be")
	register_event("Flashlight",			"event_flashlight",			"be")
	//register_event("ScreenFade",			"event_flashed",		"be")
	
	register_menucmd(register_menuid("\yPredator Speak"),	(1<<0|1<<1|1<<2|1<<3|1<<4|1<<5|1<<6|1<<7|1<<8|1<<9),	"predmenucmd")
	register_menucmd(register_menuid("\yHuman Speak"),	(1<<0|1<<1|1<<2|1<<3|1<<4|1<<5|1<<6|1<<7|1<<8|1<<9),	"hummenucmd2")
	register_menucmd(register_menuid("\yArnold Speak"),	(1<<0|1<<1|1<<2|1<<3|1<<4|1<<5|1<<6|1<<7|1<<8|1<<9),	"hummenucmd")
	register_menucmd(register_menuid("\yArnold Talk"),	(1<<0|1<<1|1<<2|1<<3|1<<4|1<<5|1<<6|1<<7|1<<8|1<<9),	"hummenucmd3")
	register_menucmd(register_menuid("Team_Select", 1), (1<<0)|(1<<1)|(1<<4)|(1<<5), "team_select")
	register_clcmd("jointeam", 		"join_team")
	register_clcmd("fullupdate",	"blockthis")
	register_clcmd("nightvision",	"event_nightvision")
	register_clcmd("radio1",		"cmd_radio1")
	register_clcmd("radio2",		"cmd_radio2")
	register_clcmd("radio3",		"cmd_radio3")
	
	register_concmd("amx_predator",	"toggle",	ADMIN_BAN,	"1=on/0=off")
	register_clcmd("amx_buyitem",	"admin_buyitem")	
	
	pGameName		= register_cvar("pred_gamename",	"1")
	pThingSpeed		= register_cvar("pred_speed",		"350")
	pThingHealth	= register_cvar("pred_health",		"180")
	pThingHealthPP	= register_cvar("pred_healthpp",	"10")
	pThingArmor		= register_cvar("pred_armor",		"200")
	pThingAlpha		= register_cvar("pred_alpha",		"30")
	pThingOverride	= register_cvar("pred_override",	"0")
	
	register_cvar("pred_skyname",		"space")		//space
	new tempstr[31]
	get_cvar_string("pred_skyname", tempstr, 30)
	if (tempstr[0] && !equali(tempstr, "none")) {
		set_cvar_string("sv_skyname", tempstr)
	}
	
	register_cvar("pred_autorun",		"1")
	if (get_cvar_num("pred_autorun") == 1) {
		server_cmd("amx_predator 1")
	}
	
	maxplayers		= get_maxplayers()
}
public plugin_precache() {
	precache_model(THING_KNIFE_V_VIS)
	precache_model(THING_KNIFE_V_INV)
	//precache_model(THING_KNIFE_P)
	precache_model(THING_VIEW)
	new formatthis[64]
	format(formatthis, 63, "models/player/%s/%s.mdl", gThingModel, gThingModel)
	precache_model(formatthis)
	
	precache_sound(THING_SLAMSND)
	new i
	for (i=0; i < PredSndCnt; i++) {		/*PREDATOR SOUNDS*/
		precache_sound(PredSnds[i])
	}
	pThingArnold	= register_cvar("pred_humanradio",	"1")
	if (get_pcvar_num(pThingArnold) != 0) {						//use the global bool instead of the cvar, otherwise it can be changed mid-round
		gUseArnold	= true
	} else {
		gUseArnold	= false
	}
	if (gUseArnold == true) {				//Custom human sounds can be toggled off
		for (i=0; i < HumSndCnt; i++) {			/*HUMAN SOUNDS1*/
			precache_sound(HumSnds[i])
		}
		for (i=0; i < HumSndCnt2; i++) {		/*HUMAN SOUNDS2*/
			precache_sound(HumSnds2[i])
		}
		for (i=0; i < HumSndCnt3; i++) {		/*HUMAN SOUNDS3*/
			precache_sound(HumSnds3[i])
		}
	}
	for (i=0; i < maxfeedingsounds; ++i) {
		precache_sound(feedingsoundfiles[i])
	}
	for (i=0; i < maxdieingsounds; ++i) {
		precache_sound(dieingsoundfiles[i])
	}
	for (i=0; i < maxpainsounds; ++i) {
		precache_sound(painsoundfiles[i])
	}
	g_shockwave = 	precache_model("sprites/shockwave.spr")
	blood = 		precache_model("sprites/blood.spr")
	blood2 = 		precache_model("sprites/bloodspray.spr")
}

//			_________________
//___________/ ADMIN COMMANDS \___________________________________________________________________________________________
//********************************************************************************************************************************************/
public toggle(id, level, cid) {
	if(!cmd_access(id, level, cid, 1)) return PLUGIN_HANDLED
	new arg1[32]
	read_argv(1, arg1, 31)
	if(equali(arg1, "1")) {
		if (gRunning == true) {
			client_print(id, print_console, "[%s] Predator mod is already enabled", PLUG_TAG)
			return PLUGIN_HANDLED
		}
		if (playerlivecount() < minplayers && get_pcvar_num(pThingOverride) == 0) {
			client_print(0, print_chat, "[%s] Predator mode can not be activated untill there are at least %i people in the server", PLUG_TAG, minplayers)
			return PLUGIN_HANDLED
		}
		//CREATE VIEW ENT
		new tries = 0
		while (!pev_valid(gEntView) && tries <= 5) {
			gEntView = createview()
			tries += 1
		}
		if (!pev_valid(gEntView)) {
			client_print(0, print_chat, "[%s] Failed to create proper ents to activate mod.", PLUG_TAG)
			return PLUGIN_HANDLED
		}
		gNewPredator = 0
		gRunning = true
		//SET LIGHTING
		engfunc(EngFunc_LightStyle, 0, "b")
		//PICK A PREDATOR
		new name[32], randomct = randomperson()
		if (randomct == -1) return PLUGIN_HANDLED
		cs_set_user_team(randomct,	CS_TEAM_T)
		gPredator = randomct
		fixhumans()
		get_user_name(gPredator, name, 31)
		client_print(0, print_chat, "[%s] %s has become the first predator.", PLUG_TAG, name)
		//SET CVARS
		set_cvar_num("mp_limitteams",		0)	//Will allow everyone to join CT
		set_cvar_num("mp_autoteambalance",	0)	//Won't force CTs onto Terror team
		set_cvar_num("mp_flashlight",		1)	//Need to activate flashlights to hook the command
		set_cvar_num("mp_freezetime",		2)	//Allow CTs time to buy before the predator rushes in
		set_cvar_num("mp_playerid",			1)	//Don't allow CTs to see Terrorist's name
		set_cvar_num("sv_skycolor_r",		0)	//Make it so people don't glow as rediculiously as they would if this was higher.
		set_cvar_num("sv_skycolor_g",		0)	//Make it so people don't glow as rediculiously as they would if this was higher.
		set_cvar_num("sv_skycolor_b",		0)	//Make it so people don't glow as rediculiously as they would if this was higher.
		set_cvar_num("sv_airaccelerate",	100)
		set_cvar_num("sv_restartround", 	1)	//Restart the round so things take effect
		//SET TASKS
		if (!task_exists(offset_flashlight)) set_task(0.1, "task_flashlight", offset_flashlight, _, _, "b")
		if (!task_exists(offset_enforcecvar)) set_task(10.0, "task_forcecvar", offset_enforcecvar, _, _, "b")
		if (!task_exists(offset_ticker)) set_task(1.0, "task_ticker", offset_ticker, _, _, "b")
	} else if (equali(arg1, "0")) {
		if (gRunning == false) {
			client_print(id, print_console, "[%s] Predator mod is already disabled", PLUG_TAG)
			return PLUGIN_HANDLED
		}
		server_cmd("exec server.cfg")
		set_cvar_num("sv_restartround", 	1)
		gRunning = false
		gLive = false
		UnThingFX(gPredator)
		//RESET LIGHTS TO DEFAULT
		engfunc(EngFunc_LightStyle, 0, "m")
		//REMOVE VIEW ENT
		if (pev_valid(gEntView)) {
			engfunc(EngFunc_RemoveEntity, gEntView)
			gEntView = 0
		}
		//REMOVE TASKS
		if (task_exists(offset_flashlight)) remove_task(offset_flashlight)
		if (task_exists(offset_enforcecvar)) remove_task(offset_enforcecvar)
		if (task_exists(offset_ticker)) remove_task(offset_ticker)
	} else {
		if (gRunning == true) {
			client_print(id, print_console, "[%s] Predator mod is currently enabled", PLUG_TAG)
		} else {
			client_print(id, print_console, "[%s] Predator mod is currently disabled", PLUG_TAG)
		}
	}
	return PLUGIN_HANDLED
}

public admin_buyitem(id) {
	new arg1[32]
	read_argv(1, arg1, 31)
	for (new i = 0; i <= CustomItemCnt; ++i) {
		if (equali(arg1, cConsoleItemName[i])) {
			buyitem(id, i)
			break
		}
	}
	return PLUGIN_HANDLED
}
//			_________________
//___________/ CLIENT COMMANDS \___________________________________________________________________________________________
//********************************************************************************************************************************************/
public team_select(id, key) {
	if (!gRunning) return PLUGIN_CONTINUE
	if (get_user_team(id) == 1 && is_user_alive(id)) {
		client_print(id, print_chat, "[%s] You cannot change roles", PLUG_TAG)
		return PLUGIN_HANDLED
	}
	if (key == 1 || key == 5) {
		return PLUGIN_CONTINUE
	}
	client_cmd(id, "jointeam 2")
	return PLUGIN_HANDLED
}
public join_team(id) {
	if (!gRunning) return PLUGIN_CONTINUE
	if (get_user_team(id) == 1 && is_user_alive(id)) {
		client_print(id, print_chat, "[%s] You cannot change roles", PLUG_TAG)
		return PLUGIN_HANDLED
	}
	new arg[2]
	read_argv(1, arg, 1)
	if (str_to_num(arg) == 2 || str_to_num(arg) == 6) {
		return PLUGIN_CONTINUE
	}
	client_cmd(id, "jointeam 2")
	return PLUGIN_HANDLED
}
public blockthis(id) {
	if(!gRunning) return PLUGIN_CONTINUE
	return PLUGIN_HANDLED
}
public cmd_radio1(id) {
	if (!gRunning) return PLUGIN_CONTINUE
	if (!gLive) return PLUGIN_HANDLED
	if (!is_user_alive(id)) return PLUGIN_CONTINUE
	if (gPredator == id) {
		predmenu(id)
		return PLUGIN_HANDLED
	} else {
		if (gUseArnold == true) {
			hummenu2(id)
			return PLUGIN_HANDLED
		} else {
			return PLUGIN_CONTINUE
		}
	}
	return PLUGIN_HANDLED
}
public cmd_radio2(id) {
	if (!gRunning) return PLUGIN_CONTINUE
	if (!gLive) return PLUGIN_HANDLED
	if (!is_user_alive(id)) return PLUGIN_CONTINUE
	if (gPredator == id) {
		predmenu(id)
		return PLUGIN_HANDLED
	} else {
		if (gUseArnold == true) {
			hummenu3(id)
			return PLUGIN_HANDLED
		} else {
			return PLUGIN_CONTINUE
		}
	}
	return PLUGIN_HANDLED
}
public cmd_radio3(id) {
	if (!gRunning) return PLUGIN_CONTINUE
	if (!gLive) return PLUGIN_HANDLED
	if (!is_user_alive(id)) return PLUGIN_CONTINUE
	if (gPredator == id) {
		predmenu(id)
		return PLUGIN_HANDLED
	} else {
		if (gUseArnold == true) {
			hummenu(id)
			return PLUGIN_HANDLED
		} else {
			return PLUGIN_CONTINUE
		}
	}
	return PLUGIN_HANDLED
}
//			______
//___________/ TASKS \______________________________________________________________________________________________________
//********************************************************************************************************************************************/
public task_flashlight(TaskID) {
	if (!gRunning) {
		remove_task(TaskID)
		return
	}
	if (!gLive) return
	new id, jd, Float:tPredOrigin[3]
	if (is_user_alive(gPredator)) pev(gPredator, pev_origin, tPredOrigin)
	for (id=1; id<maxplayers; id++) {
		if (cFlashlight[id] == 1) {
			if (!is_user_alive(id) || get_user_team(id) != 2) {
				cFlashlight[id] = 0
				continue
			}
			if (cFlashbattery[id] <= 0) {
				cFlashlight[id] = 0
			} else {
				new hitOrigin[3]
				get_user_origin(id, hitOrigin, 3)
				if (cFlashbattery[id] > 50) {		/*FLASHLIGHT IS STRONG*/
					for (jd=1; jd<maxplayers; jd++) {
						if (is_user_alive(jd) && (get_user_team(jd) == 2 || (get_user_team(jd) == 1 && cPredViewStyle != VS_Heat)) && jd != id) drawlight(hitOrigin, jd, id, 250, false)
					}
					drawlight(hitOrigin, id, id, 250, true)
				} else {							/*FLASHLIGHT IS DIEING*/
					drawlight(hitOrigin, id, id, floatround(cFlashbattery[id] * 5.0), true)
				}
				cFlashbattery[id] -= flashdrain
				message_begin(MSG_ONE_UNRELIABLE, msgFlashlight, {0,0,0}, id)
				write_byte(cFlashlight[id])
				write_byte(floatround(cFlashbattery[id] / 10.0))
				message_end()
			}
		} else {
			if (cCustomItems[id][ITEM_BATTERY]) {
				if (cFlashbattery[id] < (1000 - flashcharge)) {
					cFlashbattery[id] += flashcharge
				} else {
					cFlashbattery[id] = 1000
				}
			} else {
				if (cFlashbattery[id] < (1000 - (flashcharge * 2))) {
					cFlashbattery[id] += (flashcharge * 2)
				} else {
					cFlashbattery[id] = 1000
				}
			}
			message_begin(MSG_ONE_UNRELIABLE, msgFlashlight, {0,0,0}, id)
			write_byte(cFlashlight[id])
			write_byte(floatround(cFlashbattery[id] / 10.0))
			message_end()
		}
		//Calculate distance from each user to the predator, to know how much to render it. I put it in here because it needs to be updated oftin, but not as oftin as fwd_addtofullpack
		if (is_user_alive(gPredator) && is_user_alive(id)) {
			new Float:tHumOrigin[3]
			pev(id, pev_origin, tHumOrigin)
			cPredDistance[id] = get_distance_f(tPredOrigin, tHumOrigin)
		}
	}
	//Updates the origin of the red 'wisps' in the predator's thermal view, and creates the blue glow.
	if (is_user_alive(gPredator)) {
		if (cPredViewStyle == VS_Heat) {
			drawthingvision(gPredator)
		} else if (cPredViewStyle == VS_Grey) {
			new selID
			drawthingvision(gPredator)
			selID = findinfotarget(gPredator)
			if (selID != 0 && pev_valid(selID)) {
				new hudmsg[81], tmpName[31], Float:tmpHP, Float:tmpAP
				if (is_user_alive(selID)) {
					get_user_name(selID, tmpName, 30)
					pev(selID, pev_health, tmpHP)
					pev(selID, pev_armorvalue, tmpAP)
					new iClip, iAmmo, iWpn = get_user_weapon(selID, iClip, iAmmo)
					format(hudmsg, 80, "%s^nHealth: %i^nArmor: %i^n^n%s (%i/%i)", tmpName, floatround(tmpHP), floatround(tmpAP), wpnname[iWpn], iClip, iAmmo)
				} else {
					pev (selID, pev_classname, tmpName, 30)
					if (equali(tmpName, "hostage_entity")) {
						pev(selID, pev_health, tmpHP)
						format(hudmsg, 80, "Hostage^nHealth: %i", floatround(tmpHP))	
					}
				}
				set_hudmessage(0,75,150, 0.0,0.15, 0,0.0,2.0, 0.0,0.5, 4)
				show_hudmessage(gPredator, hudmsg)
			}
		}
	}
}
public task_forcecvar(TaskID) {
	if (!gRunning) {
		remove_task(TaskID)
		return
	}
	if (!gLive) return
	if (curcvar +1 < cvarcnt) {
		curcvar += 1
	} else {
		curcvar = 0
	}
	new param[2]
	param[1] = curcvar
	for (new id=1; id<maxplayers; id++) {
		param[0] = id
		if (is_user_connected(id)) {
			set_task(0.5, "task_delaycvarread", _, param, 2)
		}
	}
}
public task_ticker(TaskID) {
	if (!gRunning) {
		remove_task(TaskID)
		return
	}
	if (!gLive) return
	if (cPredUncloak == true) {
		addenergy(energychargeuncloak)
	} else {
		addenergy(energychargecloak)
	}
	if (is_user_alive(gPredator)) {
		update_pred_status(gPredator)
		if (cPredEnergy <= hearfeetenergy) {
			if (get_user_footsteps(gPredator) == 1) set_user_footsteps(gPredator, 0)
		} else {
			if (get_user_footsteps(gPredator) == 0) set_user_footsteps(gPredator, 1)
		}
	}
}
public task_dimlights(TaskID) {
	engfunc(EngFunc_LightStyle, 0, "b")
}
public task_speedupagain(param[2]) {	//Speed Increase Effect (After Using Groundpound)
	if (!gLive || !cPredSpeedLock) return
	new id = param[0]
	new increase = param[1]
	new Float:curspd
	pev(id, pev_maxspeed, curspd)
	if (curspd < get_pcvar_float(pThingSpeed) - increase) {
		set_pev(id, pev_maxspeed, curspd + increase)
		set_task(0.1, "task_speedupagain", _, param, 2)
	} else if (curspd > get_pcvar_float(pThingSpeed) + increase) {
		set_pev(id, pev_maxspeed, curspd - increase)
		set_task(0.1, "task_speedupagain", _, param, 2)
	} else {
		set_pev(id, pev_maxspeed, get_pcvar_float(pThingSpeed))
		cPredSpeedLock = false
	}
}
public task_invisrecover(TaskID) {
	if (!gLive) return
	if (cPredVisib - preddevis > 0) {
		cPredVisib -= preddevis
		set_task(0.2, "task_invisrecover", offset_invisrecover)
	} else {
		cPredVisib = 0
	}
	predknifemdl(gPredator)
}
public task_delaycvarread(param[2]) {
	if (!gLive) return
	new id = param[0]
	if (!is_user_connected(id) || is_user_bot(id)) return
	param[0] = param[1]
	query_client_cvar (id, cvarname[param[0]], "queryresult", 1, param)
}
public task_deadcheck(id) {
	id -= offset_playerdieing
	if (pev(id, pev_deadflag) == 2 || ++feedhealth[id] * deadcheckinterval > deadcheckmax) {
		get_user_origin(id, feedorigin[id])
		new Float:mins[3]
		pev(id, pev_mins, mins)
		feedorigin[id][2] = feedorigin[id][2] + 2 - floatround(fm_distance_to_foothold(id) - mins[2])
		feedhealth[id] = maxfeedhealth
		remove_task(id + offset_playerdieing)
	}
}
public task_findfeedtarget(id) {
	id -= offset_findfeedtarget
	if (is_user_alive(id) && (pev(id, pev_button) & IN_USE) && !task_exists(id + offset_playerfeeding)) {
		new Float:health
		pev(id, pev_health, health)
		if (health >= get_pcvar_float(pThingHealth) + (playerlivecount() * get_pcvar_num(pThingHealthPP)) + feedextrahealth) return
		
		new corpse = can_drink(id)
		if (corpse) {	//Found A Target
			if (msgBartime) msg_bartime2(id, formula_feed_time(healthperfeed, maxfeedhealth), formula_feed_percent(feedhealth[corpse], maxfeedhealth))
			feedingsounds(id)
			drawblood(feedorigin[corpse], 83)
			new param[2]
			param[0] = id
			param[1] = corpse
			set_task(feedinterval, "task_feedoncorpse", id + offset_playerfeeding, param, 2, "b")
		} else {		//Keep Looking
			set_task(0.2, "task_findfeedtarget", id + offset_findfeedtarget)
		}
	}
	return
}
public task_feedoncorpse(param[2]) {
	new id = param[0]
	new corpse = param[1]

	if (is_user_alive(id) && (pev(id, pev_button) & IN_USE) && can_drink(id, corpse)) {
		new Float:health
		pev(id, pev_health, health)
		feedingsounds(id)
		drawblood(feedorigin[corpse], 83)
		if (health + healthperfeed <= get_pcvar_float(pThingHealth) + (playerlivecount() * get_pcvar_num(pThingHealthPP)) + feedextrahealth) {
			//If they won't go over the max health limit, Increase there health accordingly
			set_pev(id, pev_health, health + healthperfeed)
			feedhealth[corpse] -= healthperfeed
			return
		}
		//Otherwise, If they will go over the max health limit, simply set it to the max
		set_pev(id, pev_health, get_pcvar_float(pThingHealth) + (playerlivecount() * get_pcvar_num(pThingHealthPP)) + feedextrahealth)
		feedhealth[corpse] -= healthperfeed
	}

	if (msgBartime) msg_bartime2(id, 0, 0)
	remove_task(id + offset_playerfeeding)
}

//			____________________
//___________/ FORWARDS AND EVENTS \_______________________________________________________________________________________
//********************************************************************************************************************************************/
public fwd_gamedesc() {
	if (get_pcvar_num(pGameName) != 1) return FMRES_IGNORED
	forward_return(FMV_STRING, gamename)
	return FMRES_SUPERCEDE
}

public fwd_cmdstart(id, const uc_handle, random_seed) {
	if (!gRunning || !gLive) return FMRES_IGNORED
	if (!is_user_alive(id)) return FMRES_IGNORED
	if (id == gPredator) {		//THING
		static buttons
		buttons = get_uc(uc_handle, UC_Buttons)
		new holdflags = pev(id, pev_flags)
		if (buttons & IN_DUCK) {
			if (buttons & IN_JUMP && (holdflags & FL_ONGROUND || cPredOnWall == true)) {
				if (cPredEnergy >= jumpenergy && cPredJumpDelay < get_gametime() && cPredPoundDelay < get_gametime()) {
					cPredEnergy -= jumpenergy
					update_pred_status(id)
					cPredJumpDelay = get_gametime() + jumpdelay
					if (cPredOnWall == true) {
						cPredOnWall = false
						set_pev(id, pev_gravity, 1.0)
					}
					new Float:fJumpVelocity[3]
					velocity_by_aim (id, 1000, fJumpVelocity)
					set_pev(id, pev_velocity, fJumpVelocity)
				}
			}
			if (cPredOnWall == true) {
				set_pev(id, pev_velocity, {0.0, 0.0, 0.0})
				set_pev(id, pev_origin, cPredClingSpot)
				set_pev(id, pev_gravity, 0.01)
			}
		} else {
			if (cPredOnWall == true) {
				cPredOnWall = false
				set_pev(id, pev_gravity, 1.0)
			}
		}
		if (buttons & IN_RELOAD && holdflags & FL_ONGROUND && cPredOnWall == false) {
			if (cPredEnergy >= poundenergy && cPredPoundDelay < get_gametime()) {
				cPredEnergy -= poundenergy
				update_pred_status(id)
				cPredPoundDelay = get_gametime() + pounddelay
				new tOrigin[3]
				get_user_origin(id, tOrigin)
				dirtpound(tOrigin)
				fadered(id, 150)
				
				emit_sound (id, CHAN_AUTO, THING_SLAMSND, 1.0, ATTN_NORM, 0, PITCH_NORM)
				speedadjust(id, 200, pounddelay, 10)
				
				new tOrigin2[3], tDist
				for (new i=1; i<maxplayers; i++) {
					if (is_user_alive(i) && get_user_team(i) == 2) {
						get_user_origin(i, tOrigin2)
						tDist = get_distance(tOrigin, tOrigin2)
						if (tDist <= poundrange) {
							tDist = (poundrange - tDist)
							shockwavedmg(id, i, (tDist / 3))
							randompunch(i, (tDist * 3))
						}
					}
				}			
			}
		}
	}
	return FMRES_IGNORED
}
public fwd_prethink(id) {
	if (!gRunning || !gLive) return FMRES_IGNORED
	if (!is_user_alive(id)) return FMRES_IGNORED
	if (id == gPredator) {		//THING
		if (pev_valid(gEntView)) {
			new Float:ThingOri[3]
			pev(id, pev_origin, ThingOri)
			set_pev(gEntView, pev_origin, ThingOri)
		}
		set_pev(id, pev_fuser2, 0.0)
		if (pev(id, pev_flFallVelocity) >= 350.0) {
			cPredFalling = true
		} else {
			cPredFalling = false
		}
	} else {				//HUNTER
		//HUMANS DON'T NEED TO THINK! >:O
	}
	return FMRES_IGNORED
}
public fwd_postthink(id) {
	if (!gRunning || !gLive) return FMRES_IGNORED
	if (!is_user_alive(id)) return FMRES_IGNORED
	if (id == gPredator) {		//THING
		if(cPredFalling) set_pev(id, pev_watertype, -3)
	}
	return FMRES_IGNORED
}
public fwd_addtofullpack(es_handle, e, ent, host, hostflags, player, pSet) {
	if (!gRunning || !gLive) return FMRES_IGNORED
	if (!pev_valid(ent)) return FMRES_IGNORED
	//RENDER THE VIEW VISIBLE TO THE THING
	if (host == gPredator) {
		//CRAP FOR THE VIEW ENT
		if (ent == gEntView) {
			if (cPredViewStyle == VS_Heat) {
				set_es(es_handle, ES_RenderAmt, 1)
				set_es(es_handle, ES_RenderColor, {15, 0, 0})
				return FMRES_IGNORED
			} else if (cPredViewStyle == VS_Grey) {
				set_es(es_handle, ES_RenderAmt, 1)
				set_es(es_handle, ES_RenderColor, {0, 15, 0})
				return FMRES_IGNORED
			} else if (cPredViewStyle == VS_None) {
				return FMRES_IGNORED			//ITS ALREADY INVISIBLE BY DEFAULT!
			}
		}
		new classname[31]
		pev (ent, pev_classname, classname, 30)
		//COLD ENTS
		if (cPredViewStyle == VS_Heat) {
			if (equal(classname, "func_wall") || equal(classname, "func_door") || equal(classname, "func_button") || equal(classname, "func_rot_button") || equal(classname, "func_door_rotating") || equal(classname, "func_momentary_door") || equal(classname, "func_momentary_button") || equal(classname, "func_wall_toggle")) {
				set_es(es_handle, ES_RenderAmt, 100)
				set_es(es_handle, ES_RenderMode, kRenderTransColor)
				set_es(es_handle, ES_RenderColor, {0, 0, 100})
				return FMRES_IGNORED
			}
			//MEDIUM ENTS
			if (equal(classname, "func_breakable") || equal(classname, "func_pushable")) {
				set_es(es_handle, ES_RenderAmt, 100)
				set_es(es_handle, ES_RenderMode, kRenderTransColor)
				set_es(es_handle, ES_RenderColor, {75, 0, 25})
				return FMRES_IGNORED
			}
			//HOT ENTS
			if (equal(classname, "func_vehicle") || equal(classname, "func_plat") || equal(classname, "func_train") || equal(classname, "func_rotating") || equal(classname, "func_tracktrain") || equal(classname, "func_tank")) {
				set_es(es_handle, ES_RenderAmt, 100)
				set_es(es_handle, ES_RenderMode, kRenderTransColor)
				set_es(es_handle, ES_RenderColor, {100, 0, 0})
				return FMRES_IGNORED
			}
			//REMOVALS
			if (equal(classname, "env_sprite") || equal(classname, "env_glow") || equal(classname, "cycler_sprite") || equal(classname, "cycler_sprite")) {
				set_es(es_handle, ES_RenderAmt, 0)
				set_es(es_handle, ES_RenderMode, kRenderTransColor)
				set_es(es_handle, ES_RenderFx, kRenderFxNone)
				set_es(es_handle, ES_RenderColor, {0, 0, 0})
				return FMRES_IGNORED
			}
		}
		//HUMAN BODY HEAT
		if (equal(classname, "player")) {
			if (is_user_alive(ent) && get_user_team(ent) == 2) {
				if (cPredViewStyle == VS_Heat && !cCustomItems[ent][ITEM_COLDBLOOD]) {
					set_es(es_handle, ES_RenderAmt, 25)
					set_es(es_handle, ES_RenderMode, kRenderNormal)
					set_es(es_handle, ES_RenderFx, kRenderFxGlowShell)
					set_es(es_handle, ES_RenderColor, {150, 25, 0})
				}
			}
			return FMRES_IGNORED
		}
		//HOSTAGE BODY HEAT
		if (equal(classname, "hostage_entity")) {
			if (cPredViewStyle == VS_Heat) {
				set_es(es_handle, ES_RenderMode, kRenderNormal)
				set_es(es_handle, ES_RenderFx, kRenderFxGlowShell)
				set_es(es_handle, ES_RenderAmt, 25)
				set_es(es_handle, ES_RenderColor, {100, 0, 0})
			} else if (cPredViewStyle == VS_Grey) {
				set_es(es_handle, ES_RenderMode, kRenderNormal)
				set_es(es_handle, ES_RenderFx, kRenderFxGlowShell)
				set_es(es_handle, ES_RenderAmt, 25)
				set_es(es_handle, ES_RenderColor, {50, 50, 50})
			}
			return FMRES_IGNORED
		}
	} else if (get_user_team(host) == 2) {
		if (ent == gPredator) {
			if (!is_user_alive(host)) {		//Let dead people see the predator
				set_es(es_handle, ES_RenderAmt, 50)
				set_es(es_handle, ES_RenderMode, kRenderNormal)
				set_es(es_handle, ES_RenderFx, kRenderFxGlowShell)
				set_es(es_handle, ES_RenderColor, {10, 10, 10})
			} else {
				if (cPredUncloak == true) {						//Predator has Cloak Disabled
					set_es(es_handle, ES_RenderAmt, 0)
					set_es(es_handle, ES_RenderMode, kRenderNormal)
					set_es(es_handle, ES_RenderFx, kRenderFxGlowShell)
					set_es(es_handle, ES_RenderColor, {0, 0, 0})
				} else {										//Predator has Cloak Enabled
					if (cPredDistance[host] < seepreddist) {		//PRED IS CLOSE
						//FIGURE OUT HOW MUCH TO RENDER HIM ACCORDING TO DISTANCE TO THE PLAYER
						new RenderThis = floatround((seepreddist - cPredDistance[host]) / 10.0)
						new MaxAlpha = get_pcvar_num(pThingAlpha)		//Get the distance render opacity
						if (RenderThis > MaxAlpha) RenderThis = MaxAlpha
						RenderThis += cPredVisib						//ADD THE GLOBAL VISIBILITY TO PLAYERS
						if (RenderThis > 255) RenderThis = 255			//Hardcode a max render value (when damaged it goes above the distance cap)
						new clrAlpha[3]
						clrAlpha[0] = RenderThis; clrAlpha[1] = RenderThis; clrAlpha[2] = RenderThis
						set_es(es_handle, ES_RenderAmt, 1)
						set_es(es_handle, ES_RenderMode, kRenderTransTexture)
						set_es(es_handle, ES_RenderFx, kRenderFxGlowShell)
						set_es(es_handle, ES_RenderColor, clrAlpha)
					} else if (cPredVisib > 0) {					//NOT CLOSE, BUT GLOBALY VISIBLE
						new clrAlpha[3]
						clrAlpha[0] = cPredVisib; clrAlpha[1] = cPredVisib; clrAlpha[2] = cPredVisib
						set_es(es_handle, ES_RenderAmt, 1)
						set_es(es_handle, ES_RenderMode, kRenderTransTexture)
						set_es(es_handle, ES_RenderFx, kRenderFxGlowShell)
						set_es(es_handle, ES_RenderColor, clrAlpha)
					}
				}
			}
		}
	}
	return FMRES_IGNORED
}
public fwd_touch(id, touched) {
	if (!gRunning || !gLive) return FMRES_IGNORED
	if (id == gPredator && is_user_alive(id)) {
		new classname[31]
		if (pev_valid(touched)) {
			pev(touched, pev_classname, classname, 30)
			//BLOCK PICKING UP WEAPONS
			if (equal(classname, "weaponbox") || equal(classname, "armoury_entity") || equal(classname, "weapon_shield")) return FMRES_SUPERCEDE
		}
		if (cPredOnWall == false) {
			new btns = pev(id, pev_button)
			new holdflags = pev(id, pev_flags)
			if ((touched == 0 || equal(classname, "func_wall")) && !(holdflags & FL_ONGROUND) && (btns & IN_DUCK) && !(btns & IN_FORWARD)) {
				new Float:tOrigin[3], Float:tOrigin2[3]
				pev(id, pev_origin, tOrigin)
				tOrigin2 = tOrigin
				tOrigin2[2] += 25.0
				fm_trace_line(id, tOrigin, tOrigin2, tOrigin2)	//Find where the player is grabbing (if above)
				new tContents = engfunc(EngFunc_PointContents, tOrigin2)
				if (tContents != CONTENTS_SKY) {
					cPredClingSpot = tOrigin
					cPredOnWall = true
				}
			}
		}
	}
	return FMRES_IGNORED
}
public fwd_emitsound(const id, const channel, sound[]) {
	if (!gRunning || !gLive) return FMRES_IGNORED
	if (!is_user_connected(id)) return FMRES_IGNORED
	if (id != gPredator) return FMRES_IGNORED
	//Predator Die Sound
	if (contain(sound, "player/die") > -1 || contain(sound, "player/death") > -1) {
		dieingsounds(id)
		return FMRES_SUPERCEDE
	}
	//Predator Hurt Sound
	if (contain(sound, "player/headshot") > -1 || contain(sound, "player/pl_die") > -1 || contain(sound, "player/pl_shot") > -1 || contain(sound, "player/pl_pain") > -1 || contain(sound, "player/bhit_") > -1) {
		painsounds(id)
		return FMRES_SUPERCEDE
	}
	//Predator landing Sound
	/*if (contain(sound, "player/pl_fallpain") > -1|| contain(sound, "player/pl_jump") > -1) {
		return FMRES_SUPERCEDE
	}*/
	//Hook Use Button
	if (equali(sound, USE_SOUND) && is_user_alive(id) && (pev(id, pev_button) & IN_USE) && !task_exists(id + offset_playerfeeding)) {
		task_findfeedtarget(id + offset_findfeedtarget)
		return FMRES_SUPERCEDE
	}
	return FMRES_IGNORED
}

public event_flashlight(id) {
	if (!gRunning) return PLUGIN_CONTINUE
	if (get_user_team(id) == 2) {				//Humans
		if (cFlashlight[id] == 1) {
			cFlashlight[id] = 0
		} else {
			if (cFlashbattery[id] > 0) cFlashlight[id] = 1
		}
	} else if (get_user_team(id) == 1) {		//Predator
		if (cPredUncloak == true) {
			cPredUncloak = false
		} else {
			cPredUncloak = true
		}
		client_print(id, print_chat, "[%s] Your cloaking device is %s", PLUG_TAG, cPredUncloak?"Disabled":"Enabled")
		if (!task_exists(offset_invisrecover) && cPredVisib > 0) set_task(0.2, "task_invisrecover", offset_invisrecover)
		predknifemdl(id)
	}
	set_pev(id, pev_effects, pev(id, pev_effects) & ~EF_DIMLIGHT)
	return PLUGIN_HANDLED
}
public event_nightvision(id) {
	if (!gRunning) return PLUGIN_CONTINUE
	if (cs_get_user_nvg(id) && get_user_team(id) == 2) return PLUGIN_CONTINUE
	if (!is_user_alive(id)) {
		if (usingnvg[id] == 1) {
			usingnvg[id] = 0
		} else {
			usingnvg[id] = 1
		}
		setnvgstate(id, usingnvg[id])
		return PLUGIN_HANDLED
	}
	if (get_user_team(id) == 1) {
		if (cPredViewStyle++ >= 2) cPredViewStyle = 0
		return PLUGIN_HANDLED
	}
	return PLUGIN_HANDLED
}
public event_damage() {
	if (!gRunning || !gLive) return PLUGIN_CONTINUE
	new victim = read_data(0)
	if (!is_user_alive(victim)) return PLUGIN_CONTINUE
	new damage = read_data(2)
	if (damage < 1) return PLUGIN_CONTINUE
	new weapon, hitpoint, attacker = get_user_attacker(victim, weapon, hitpoint)
	//THING GETS HURT
	if (victim == gPredator) {
		addenergy(damage)
		if (cPredSpeedLock) {	//If the predator is moving slow already from something else (GroundPound), let him move fast again if shot.
			cPredSpeedLock = false
			set_pev(victim, pev_maxspeed, get_pcvar_float(pThingSpeed))
		}
		cPredPoundDelay = 0.0
		if (cCustomItems[attacker][ITEM_BULLET]) {
			/* Bullets that pack a bigger punch. Don't do more damage,
			   But when hitting the predator, he will light up brighter
			   and for longer. */
			fadeblue(victim, floatround(damage * 1.25))
			addvisibility(damage * 2)
			if (!task_exists(offset_invisrecover)) set_task(0.2, "task_invisrecover", offset_invisrecover)
		} else {
			fadeblue(victim, damage / 2)
			addvisibility(damage)
			set_task(0.2, "task_invisrecover", offset_invisrecover)		//Will stack tasks. More hits = faster recover
		}
		update_pred_status(victim)
		
		if (read_data(3) == DMG_BULLET) {
			//Draw blood where the attacker is aiming. Will MOST LIKELY be where they shot still
			new origin[3]
			get_user_origin(attacker, origin, 3)
			drawblood(origin, 83)
		}
		
		new Float:predhp
		pev(victim, pev_health, predhp)
		//Fix Health Glitch (multiple of 256)
		if (floatround(predhp / 256.0, floatround_ceil) == floatround(predhp / 256.0, floatround_floor)) {
			set_pev(victim, pev_health, predhp + 1.0)
		}
		return PLUGIN_CONTINUE
	}
	//HUMAN GETS HURT BY PREDATOR
	if (attacker == gPredator) {
		randompunch(victim, damage)
		fadered(victim, damage)
		return PLUGIN_CONTINUE
	}
	return PLUGIN_CONTINUE
}
public event_death() {
	if (!gRunning || !gLive) return PLUGIN_CONTINUE
	new Killer = read_data(1)
   	new Victim = read_data(2)
	if (Victim == gPredator) {
		if (Victim == Killer || Killer == 0) {
			client_print(0, print_chat, "[%s] The predator has died.", PLUG_TAG)
			gNewPredator = 0
		} else {
			new name[32]
			get_user_name(Killer, name, 31)
			client_print(0, print_chat, "[%s] %s has slain the predator.", PLUG_TAG, name)
			gNewPredator = Killer
		}
	} else {
		setnvgstate(Victim , usingnvg[Victim])
		if (task_exists(offset_playerdieing + Victim))	remove_task(offset_playerdieing + Victim)
		set_task(deadcheckinterval, "task_deadcheck", offset_playerdieing + Victim, _, _, "b")
	}
	for (new i=0; i < CustomItemCnt; i++) {
		cCustomItems[Victim][i] = false
	}
	return PLUGIN_CONTINUE
}
public event_curweapon(id) {
	if (!gRunning || !gLive) return PLUGIN_CONTINUE
	if (!is_user_connected(id)) return PLUGIN_CONTINUE
	//new WeapID = read_data(2)
	if (gPredator == id) {
		if (get_user_team(id) != 1) {
			UnThingFX(id)
			event_roundend()
		}
		engclient_cmd(id, "weapon_knife")
		if (cPredSpeedLock == false) set_pev(id, pev_maxspeed, get_pcvar_float(pThingSpeed))
		predknifemdl(id)
	}
	return PLUGIN_CONTINUE
}
public event_roundstart() {
	if (!gRunning) return PLUGIN_CONTINUE
	gLive = true
	cPredSpeedLock = false
	cPredUncloak = false
	cPredVisib = 0
	cPredEnergy = maxenergy
	cPredDistance[gPredator] = 999.9
	event_curweapon(gPredator)
	set_task((get_cvar_float("mp_buytime")*60), "buy_over", offset_buytimeend)
	gBuyTime = true
	return PLUGIN_CONTINUE
}
public event_roundend() {
	if (!gRunning) {
		if (get_cvar_num("pred_autorun") == 1) {
			server_cmd("amx_predator 1")
		}
		return PLUGIN_CONTINUE
	}
	if (playerlivecount() < minplayers) {
		server_cmd("amx_predator 0")
		return PLUGIN_CONTINUE
	}
	gLive = false
	if (gNewPredator == -1 && is_user_connected(gPredator)) {		//END OF ROUND, NO SPECIFIC NEW PRED
		if (undeadhum() > 1) {
/*THE ROUND ENDED AND THERE ARE HUMANS STILL ALIVE*/
			new name[32], randomct = randomperson()
			if (randomct == -1) return PLUGIN_CONTINUE
			cs_set_user_team(randomct,	CS_TEAM_T)
			if (is_user_connected(gPredator)) UnThingFX(gPredator)
			if (is_user_connected(gPredator)) {
				get_user_name(gPredator, name, 31)
				client_print(0, print_chat, "[%s] %s has failed to terminate all of the living humans.", PLUG_TAG, name)
				cs_set_user_team(gPredator,	CS_TEAM_CT)
			}
			gPredator = randomct
			ThingFX(gPredator)
			get_user_name(gPredator, name, 31)
			client_print(0, print_chat, "[%s] %s has randomly been selected to become the predator.", PLUG_TAG, name)
		} else {
/*THE PREDATOR WON. WILL CONTINUE AS THE PREDATOR*/
			new name[32]
			cs_set_user_team(gPredator,	CS_TEAM_T)
			ThingFX(gPredator)
			get_user_name(gPredator, name, 31)
			client_print(0, print_chat, "[%s] %s has survived as the predator and will continue.", PLUG_TAG, name)
		}
	} else {
		if (gNewPredator == gPredator || gPredator == 0 || !is_user_connected(gPredator) || !is_user_connected(gNewPredator)) {
/*THE PREDATOR COMITTED SUICIDE*/
			new randomct = randomperson()
			if (randomct == -1) return PLUGIN_CONTINUE
			cs_set_user_team(randomct,	CS_TEAM_T)
			if (is_user_connected(gPredator)) UnThingFX(gPredator)
			gPredator = randomct
			ThingFX(gPredator)
			new name[32]
			get_user_name(randomct, name, 31)
			client_print(0, print_chat, "[%s] %s has randomly been selected to become the predator.", PLUG_TAG, name)
		} else {
/*THE PREDATOR WAS KILLED. THIS PERSON TAKES THERE SPOT*/
			cs_set_user_team(gNewPredator,	CS_TEAM_T)
			cs_set_user_team(gPredator,	CS_TEAM_CT)
			UnThingFX(gPredator)
			gPredator = gNewPredator
			ThingFX(gPredator)
			new name[32]
			get_user_name(gPredator, name, 31)
			client_print(0, print_chat, "[%s] %s has taken the roll as the predator.", PLUG_TAG, name)
		}
		gNewPredator = -1
	}
	fixhumans()
	cPredEnergy = maxenergy
	cPredViewStyle = VS_Heat
	return PLUGIN_CONTINUE
}
public event_resethud(id) {
	if (!gRunning) return PLUGIN_CONTINUE
	if (!is_user_alive(id)) return PLUGIN_CONTINUE
	if (id == gPredator) {
		ThingFX(id)
	} else {
		//UnThingFX(id)
	}
	feedhealth[id] = 0
	if (task_exists(id + offset_playerdieing)) remove_task(id + offset_playerdieing)
	return PLUGIN_CONTINUE
}
public client_putinserver(id) {
	if(!gRunning) return PLUGIN_CONTINUE
	set_task(5.0, "task_dimlights", offset_dimlights)
	return PLUGIN_CONTINUE
}
public client_disconnect(id) {
	if(!gRunning) return PLUGIN_CONTINUE
	cWarns[id] = 0
	if (playerlivecount() < minplayers) {
		server_cmd("amx_predator 0")
		return PLUGIN_CONTINUE
	}
	feedhealth[id] = 0
	if (task_exists(id + offset_playerdieing)) remove_task(id + offset_playerdieing)
	if (id != gPredator) return PLUGIN_CONTINUE
	new randomct = 0
	while (!is_user_connected(randomct) || (get_user_team(randomct) != 1 && get_user_team(randomct) != 2)) {
		randomct = random_num(1, maxplayers)
	}
	cs_set_user_team(randomct,	CS_TEAM_T)
	gPredator = randomct
	new name[32]
	get_user_name(randomct, name, 31)
	client_print(0, print_chat, "[%s] The predator disconnected and %s took his position.", PLUG_TAG, name)
	return PLUGIN_CONTINUE
}

public fwd_userinfochanged(id, buffer) {
	if (!gRunning) return FMRES_IGNORED
	if (!is_user_connected(id)) return FMRES_IGNORED

	static newModel[32]
	engfunc(EngFunc_InfoKeyValue, buffer, "model", newModel, sizeof newModel - 1)
	
	if (get_user_team(id) == 1) {
		if (!equal(newModel, gThingModel)) {
			if (modelwarns[id] > 2) {
				client_print(id, print_chat, "[%s] Please do not attempt to change your model while being a predator.", PLUG_TAG)
			}
			client_cmd(id, "setinfo model %s", gThingModel)
			modelwarns[id]++
			return FMRES_SUPERCEDE
		}
	}
	return FMRES_IGNORED
}

//			__________________
//___________/ STOCKS/FUNCTIONS \__________________________________________________________________________________________
//********************************************************************************************************************************************/
public buy_over(id) {
	gBuyTime = false
}
public buyitem(id, itemtype) {
	if (!gRunning) return PLUGIN_HANDLED
	if (!cs_get_user_buyzone(id)) {
		client_print(id, print_center, "[%s] You must be in the buyzone to purchase this item.", PLUG_TAG)
		return PLUGIN_HANDLED
	}
	if (!gBuyTime) {
		client_print(id, print_center, "[%s] The %i seccond buytime has expired.", PLUG_TAG, floatround(get_cvar_num("mp_buytime") * 60.0))
		return PLUGIN_HANDLED
	}
	if (cs_get_user_money(id) < cCustomItemsPrice[itemtype]) {
		client_print(id, print_center, "[%s] You do not have enough money to buy this.", PLUG_TAG)
		return PLUGIN_HANDLED
	}
	if (cCustomItems[id][itemtype] == true) {
		client_print(id, print_center, "[%s] You already own '%s'.", PLUG_TAG, cCustomItemsName[itemtype])
		return PLUGIN_HANDLED
	}
	cCustomItems[id][itemtype] = true
	cs_set_user_money(id, (cs_get_user_money(id) - cCustomItemsPrice[itemtype]))
	return PLUGIN_HANDLED
}
stock can_drink(id, corpse = 0) {
	new origin[3], Float:fcorpsepos[3]
	get_user_origin(id, origin)
	for (new i = 1; i <= maxplayers; ++i) {
		if (feedhealth[i] <= 0 || get_distance(origin, feedorigin[i]) > feeddistance) continue
		IVecFVec(feedorigin[i], fcorpsepos)
		if (!fm_is_visible(id, fcorpsepos) || get_view_angle_diff(id, fcorpsepos) > feedangle) continue
		if (!corpse || corpse == i) return i
	}
	return 0
}
stock ThingFX(ThingID) {
	if (!is_user_connected(ThingID)) return
	set_pev(ThingID, pev_rendermode, 	kRenderTransAlpha)	//kRenderTransTexture
	set_pev(ThingID, pev_renderamt, 	0)
	set_pev(ThingID, pev_renderfx, 		kRenderFxGlowShell)
	set_pev(ThingID, pev_rendercolor, 	{0.0, 0.0, 0.0})
	set_pev(ThingID, pev_health, 		get_pcvar_float(pThingHealth) + (playerlivecount() * get_pcvar_num(pThingHealthPP)))
	set_pev(ThingID, pev_armorvalue, 	get_pcvar_float(pThingArmor))
	cs_set_user_model(ThingID, gThingModel)
}
stock UnThingFX(UnThingID) {
	if (!is_user_connected(UnThingID)) return
	set_pev(UnThingID, pev_rendermode, kRenderNormal)
	//set_pev(UnThingID, pev_renderamt, 255.0)
	set_pev(UnThingID, pev_renderfx, kRenderFxNone)
	//set_pev(UnThingID, pev_rendercolor, {255.0, 255.0, 255.0})
	set_user_footsteps(UnThingID, 0)
	set_pev(UnThingID, pev_armorvalue, 	100.0)
	cs_reset_user_model(UnThingID)
}
stock fadeblue(id, ammount) {		//FADE OUT FROM BLUE
	if (ammount > 255) ammount = 255
	message_begin(MSG_ONE_UNRELIABLE, msgScreenFade, {0,0,0}, id)
	write_short(ammount * 100)	//Durration
	write_short(0)		//Hold
	write_short(0)		//Type
	write_byte(0)	//R
	write_byte(0)	//G
	write_byte(200)	//B
	write_byte(ammount)	//B
	message_end()
}
stock fadered(id, ammount) {		//FADE OUT FROM RED
	if (ammount > 255) ammount = 255
	message_begin(MSG_ONE_UNRELIABLE, msgScreenFade, {0,0,0}, id)
	write_short(ammount * 100)	//Durration
	write_short(0)		//Hold
	write_short(0)		//Type
	write_byte(200)	//R
	write_byte(0)	//G
	write_byte(0)	//B
	write_byte(ammount)	//B
	message_end()
}
stock drawblood(origin[3], color) {
	message_begin(MSG_BROADCAST,SVC_TEMPENTITY)
	write_byte(TE_BLOODSPRITE)
	write_coord(origin[0])
	write_coord(origin[1])
	write_coord(origin[2])
	write_short(blood2)
	write_short(blood)
	write_byte(color)
	write_byte(10)
	message_end()
}
stock drawicon(id, iconname[], iconstatus=0) {
	message_begin(MSG_ONE_UNRELIABLE, msgSenario, {0,0,0}, id)
	write_byte(iconstatus)
	write_string(iconname)
	write_byte(150)
	message_end()
}
stock drawthingvision(id) {			//BLUE LIGHT AROUND THE PREDATOR
	new origin[3]
	get_user_origin(id, origin)
	if (cPredViewStyle == VS_Heat) {
		//DRAW GLOW
		message_begin(MSG_ONE_UNRELIABLE, SVC_TEMPENTITY, {0,0,0}, id)
		write_byte(27)
		write_coord(origin[0])
		write_coord(origin[1])
		write_coord(origin[2])
		write_byte(40)	//RADIUS
		write_byte(0)	//R
		write_byte(0)	//G
		write_byte(15)	//B
		write_byte(4)	//LIFE
		write_byte(0)	//DECAY
		message_end()
	} else if (cPredViewStyle == VS_Grey) {
		//DRAW GLOW
		message_begin(MSG_ONE_UNRELIABLE, SVC_TEMPENTITY, {0,0,0}, id)
		write_byte(27)
		write_coord(origin[0])
		write_coord(origin[1])
		write_coord(origin[2])
		write_byte(40)	//RADIUS
		write_byte(0)	//R
		write_byte(15)	//G
		write_byte(0)	//B
		write_byte(4)	//LIFE
		write_byte(0)	//DECAY
		message_end()
	}
}
stock findinfotarget(id)
{
	new garbageA, selID
	get_user_aiming (id, selID, garbageA, 9999)
	if (is_user_alive(selID)) {
		return selID
	} else {
		new iLook[3], Float:fLook[3], classname[31]
		get_user_origin(id, iLook, 3)
		IVecFVec(iLook, fLook)
		selID = 0
		while ((selID = fm_find_ent_in_sphere(selID, fLook, predinforadius)) != 0) {
			if (is_user_alive(selID) && selID != id) {
				return selID
			} else {
				if (pev_valid(selID)) {
					pev (selID, pev_classname, classname, 30)
					if (equali(classname, "hostage_entity")) {
						return selID
					}
				}
			}
		}
	}
	return 0
}
stock addenergy(addthis) {
	if (cPredEnergy + addthis < maxenergy) {
		cPredEnergy += addthis
	} else {
		cPredEnergy = maxenergy
	}
}
stock addvisibility(addthis) {
	if (cPredVisib + addthis < 200) {
		cPredVisib += addthis
	} else {
		cPredVisib = 200
	}
}
stock createview() {
	static const sInfo_target[] = "info_target"
	new iEnt = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, sInfo_target))
	if(!iEnt) return -1
	set_pev(iEnt, pev_classname, gEntViewClass)

	dllfunc(DLLFunc_Spawn, iEnt)
	engfunc(EngFunc_SetModel, iEnt, THING_VIEW)
	set_pev(iEnt, pev_solid, SOLID_NOT)				//SOLID_TRIGGER
	set_pev(iEnt, pev_movetype, MOVETYPE_FLY)
	//set_pev(iEnt, pev_framerate,	1.0)
	//set_pev(iEnt, pev_animtime,	2.0)
	//set_pev(iEnt, pev_sequence,	0)
	set_pev(iEnt, pev_rendermode, kRenderTransTexture)	//kRenderTransTexture
	set_pev(iEnt, pev_renderamt, 0.0)
	set_pev(iEnt, pev_renderfx, kRenderFxGlowShell)
	set_pev(iEnt, pev_rendercolor, {0.0, 0.0, 0.0})
	return iEnt
}
stock drawlight(origin[3], id, lightfrom, brightness, bool:Imp=false) {
	message_begin(MSG_ONE_UNRELIABLE, SVC_TEMPENTITY, {0,0,0}, id)
	write_byte(27)
	write_coord(origin[0])
	write_coord(origin[1])
	write_coord(origin[2])
	if (cCustomItems[lightfrom][ITEM_BATTERY]) {
		write_byte(15)	//RADIUS
	} else {
		write_byte(10)	//RADIUS
	}
	write_byte(brightness)	//R
	write_byte(brightness)	//G
	write_byte(brightness)	//B
	if (Imp) {		//If its important, make it last longer. Overlapping lights will eliminate flicker, but double its impact on preformance
		write_byte(2)	//LIFE
	} else {		//Not important, allow it to flicker a little
		write_byte(1)	//LIFE
	}
	write_byte(0)	//DECAY
	message_end()
}
stock fm_trace_line(ignoreent, const Float:start[3], const Float:end[3], Float:ret[3]) {
	engfunc(EngFunc_TraceLine, start, end, ignoreent == -1 ? 1 : 0, ignoreent, 0)
	new ent = get_tr2(0, TR_pHit)
	get_tr2(0, TR_vecEndPos, ret)
	return pev_valid(ent) ? ent : 0
}
stock playerlivecount() {
	new cnt = 0
	for (new id=1; id<maxplayers; id++) {
		if (is_user_connected(id) && (get_user_team(id) == 2 || get_user_team(id) == 1)) cnt += 1
	}
	return cnt
}
stock undeadhum() {
	new cnt = 0
	for (new id=1; id<maxplayers; id++) {
		if (is_user_alive(id) && get_user_team(id) == 2) cnt += 1
	}
	return cnt
}
stock randompunch(id, range) {
	new Float:fPAngles[3], direction	
	pev(id, pev_punchangle, fPAngles)
	//Pitch	-	Directly related to range.
	fPAngles[0] += (range / 4.0)
	//Yaw	-	May be minimal regardless of range.
	fPAngles[1] += (random_float(-(range / 4.0), (range / 4.0)))
	//Roll	-	Directly related to range.
	direction = random_num(0, 1)
	if (direction == 0) {
		fPAngles[2] += (range / 4.0)
	} else {
		fPAngles[2] -= (range / 4.0)
	}
	set_pev(id, pev_punchangle, fPAngles)
}
stock dirtpound(origin[3]) {
	message_begin(MSG_PVS, SVC_TEMPENTITY, origin)
	write_byte(TE_BEAMCYLINDER)
	write_coord(origin[0])
	write_coord(origin[1])
	write_coord(origin[2])
	write_coord(origin[0])
	write_coord(origin[1])
	write_coord(origin[2] + 500)
	write_short(g_shockwave)
	write_byte(0) 	// startframe
	write_byte(0) 	// framerate
	write_byte(4) 	// life
	write_byte(20) 	// width
	write_byte(100) // noise
	write_byte(255) // R
	write_byte(100) // G
	write_byte(0) 	// B
	write_byte(128) // brightness
	write_byte(5) 	// speed
	message_end()
}
stock shockwavedmg(attacker, victim, dmg) {
	new Float:victhp
	pev(victim, pev_health, victhp)
	if (victhp - dmg <= 0) {
		//Kill victim
		set_msg_block(msgDeathMsg, BLOCK_ONCE)
		dllfunc(DLLFunc_ClientKill, victim)
		set_msg_block(msgDeathMsg, BLOCK_NOT)
		//Display death
		message_begin(MSG_BROADCAST, msgDeathMsg, {0,0,0}, 0)
		write_byte(attacker)
		write_byte(victim)
		write_byte(1)
		write_string("GroundSlam")
		message_end()
		//Change scoreboard for victim
		message_begin(MSG_BROADCAST, msgScoreInfo)
		write_byte(victim)							//Player
		write_short(pev(victim, pev_frags))			//Frags
		write_short(cs_get_user_deaths(victim) - 1)	//Deaths
		write_short(0)								//"Class"
		write_short(get_user_team(victim))			//Team
		message_end()
		//Change scoreboard for attacker
		message_begin(MSG_BROADCAST, msgScoreInfo)
		write_byte(attacker)						//Player
		write_short(pev(attacker, pev_frags) + 1)	//Frags
		write_short(cs_get_user_deaths(attacker))	//Deaths
		write_short(0)								//"Class"
		write_short(get_user_team(attacker))		//Team
		message_end()
	} else {
		fm_fakedamage(victim, "GroundSlam", float(dmg), 64)
	}
}
stock speedadjust(id, newspeed, Float:DLay, increase) {
	cPredSpeedLock = true
	//EnergyBarRed = true
	set_pev(id, pev_maxspeed, float(newspeed))
	new param[2]
	param[0] = id
	param[1] = increase
	set_task(DLay, "task_speedupagain", _, param, 2)
}
public update_pred_status(id) {
	if (!is_user_connected(id) || !is_user_alive(id)) return
	//new Float:curgametime = get_gametime()
	new showthis[128], Float:curhp
	pev(id, pev_health, curhp)
	format (showthis, 127, "HP:%i Energy:%i", floatround(curhp), cPredEnergy)
	updatestatus(id, showthis)
}
stock updatestatus(id, str[]) {
	message_begin(MSG_ONE_UNRELIABLE, msgStatusText, {0,0,0}, id)
	write_byte(0)
	write_string(str)
	message_end()
}
stock setnvgstate(id, setthis) {
	message_begin(MSG_ONE_UNRELIABLE, msgNightVision, _, id)
	write_byte(setthis)
	message_end()
}
stock predmenu(id) {
	new keys = (1<<0|1<<1|1<<2|1<<3|1<<4|1<<5|1<<6|1<<7|1<<8|1<<9)
	new szMenuBody[menusize + 1]
	new nLen = format(szMenuBody, menusize, "\yPredator Speak^n\w")
	for (new menunum = 0; menunum < PredSndCnt; menunum++) {
		nLen += format(szMenuBody[nLen], menusize-nLen, "^n%i. %s", menunum + 1, PredSndsName[menunum])
	}
	nLen += format(szMenuBody[nLen], menusize-nLen, "^n\w0. Close")
	show_menu(id, keys, szMenuBody, -1)
	return PLUGIN_HANDLED
}
public predmenucmd(id, key) {
	switch(key) {
		case 9:	{	/*0 - [Close]*/	}
		default: {	/*1-8 - [Selected Sound]*/
			if (key < PredSndCnt && cPredRadioDelay < get_gametime()) {
				cPredRadioDelay = get_gametime() + yelldelay
				addenergy(yellcharge)
				update_pred_status(id)
				emit_sound (id, CHAN_AUTO, PredSnds[key], 1.0, ATTN_NORM, 0, PITCH_NORM)
			} else {
				predmenu(id)
			}
		}
	}
	return PLUGIN_HANDLED
}
stock hummenu(id) {
	new keys = (1<<0|1<<1|1<<2|1<<3|1<<4|1<<5|1<<6|1<<7|1<<8|1<<9)
	new szMenuBody[menusize + 1]
	new nLen = format(szMenuBody, menusize, "\yArnold Speak^n\w")
	for (new menunum = 0; menunum < HumSndCnt; menunum++) {
		nLen += format(szMenuBody[nLen], menusize-nLen, "^n%i. %s", menunum + 1, HumSndsName[menunum])
	}
	nLen += format(szMenuBody[nLen], menusize-nLen, "^n\w0. Close")
	show_menu(id, keys, szMenuBody, -1)
	return PLUGIN_HANDLED
}
public hummenucmd(id, key) {
	switch(key) {
		case 9:	{	/*0 - [Close]*/	}
		default: {	/*1-8 - [Selected Sound]*/
			if (key < HumSndCnt && cRadioDelay[id] < get_gametime()) {
				cRadioDelay[id] = get_gametime() + radiodelay
				emit_sound (id, CHAN_AUTO, HumSnds[key], 1.0, ATTN_NORM, 0, PITCH_NORM)
			} else {
				hummenu(id)
			}
		}
	}
	return PLUGIN_HANDLED
}
stock hummenu2(id) {
	new keys = (1<<0|1<<1|1<<2|1<<3|1<<4|1<<5|1<<6|1<<7|1<<8|1<<9)
	new szMenuBody[menusize + 1]
	new nLen = format(szMenuBody, menusize, "\yHuman Speak^n\w")
	for (new menunum = 0; menunum < HumSndCnt2; menunum++) {
		nLen += format(szMenuBody[nLen], menusize-nLen, "^n%i. %s", menunum + 1, HumSndsName2[menunum])
	}
	nLen += format(szMenuBody[nLen], menusize-nLen, "^n\w0. Close")
	show_menu(id, keys, szMenuBody, -1)
	return PLUGIN_HANDLED
}
public hummenucmd2(id, key) {
	switch(key) {
		case 9:	{	/*0 - [Close]*/	}
		default: {	/*1-8 - [Selected Sound]*/
			if (key < HumSndCnt2 && cRadioDelay[id] < get_gametime()) {
				cRadioDelay[id] = get_gametime() + radiodelay
				emit_sound (id, CHAN_AUTO, HumSnds2[key], 1.0, ATTN_NORM, 0, PITCH_NORM)
			} else {
				hummenu2(id)
			}
		}
	}
	return PLUGIN_HANDLED
}
stock hummenu3(id) {
	new keys = (1<<0|1<<1|1<<2|1<<3|1<<4|1<<5|1<<6|1<<7|1<<8|1<<9)
	new szMenuBody[menusize + 1]
	new nLen = format(szMenuBody, menusize, "\yArnold Talk^n\w")
	for (new menunum = 0; menunum < HumSndCnt3; menunum++) {
		nLen += format(szMenuBody[nLen], menusize-nLen, "^n%i. %s", menunum + 1, HumSndsName3[menunum])
	}
	nLen += format(szMenuBody[nLen], menusize-nLen, "^n\w0. Close")
	show_menu(id, keys, szMenuBody, -1)
	return PLUGIN_HANDLED
}
public hummenucmd3(id, key) {
	switch(key) {
		case 9:	{	/*0 - [Close]*/	}
		default: {	/*1-8 - [Selected Sound]*/
			if (key < HumSndCnt3 && cRadioDelay[id] < get_gametime()) {
				cRadioDelay[id] = get_gametime() + radiodelay
				emit_sound (id, CHAN_AUTO, HumSnds3[key], 1.0, ATTN_NORM, 0, PITCH_NORM)
			} else {
				hummenu3(id)
			}
		}
	}
	return PLUGIN_HANDLED
}
stock feedingsounds(id) {
	emit_sound(id, CHAN_AUTO, feedingsoundfiles[random(maxfeedingsounds)], 1.0, ATTN_NORM, 0, PITCH_NORM)
}
stock dieingsounds(id) {
	emit_sound(id, CHAN_AUTO, dieingsoundfiles[random(maxdieingsounds)], 1.0, ATTN_NORM, 0, PITCH_NORM)
}
stock painsounds(id) {
	emit_sound(id, CHAN_AUTO, painsoundfiles[random(maxpainsounds)], 1.0, ATTN_NORM, 0, PITCH_NORM)
}

public queryresult(id, const cvar[], const value[], param[1]) {
	if (!is_user_connected(id) || is_user_bot(id)) return
	new tcheck = param[0]
	if (!equal(cvar, cvarname[tcheck])) return
	new tval = str_to_num(cvarval[tcheck])
	if (str_to_num(value) == tval) return
	cWarns[id]++
	client_print(id, print_console, "[%s] Your '%s' was detected as %s. It must be %s. You have %i warnings left.", PLUG_TAG, cvar, value, cvarval[tcheck], ((cvarcnt + 1) - cWarns[id]))
	client_cmd(id, "%s %s", cvarname[tcheck], cvarval[tcheck])
	if (cWarns[id] > (cvarcnt + 1)) {
		new name[32]
		get_user_name(id, name, 31)
		client_print(id, print_console, "")
		client_print(id, print_console, "[%s] -=ACCESS VIOLATION=-", PLUG_TAG)
		client_print(id, print_console, "[%s] Illegal cvar/setting detected.", PLUG_TAG)
		client_print(id, print_console, "[%s] Your '%s' must be set to '%i' to play in this server.", PLUG_TAG, cvarname[tcheck], tval)
		client_print(0, print_chat, "[%s] %s will be kicked from the server for illegal cvar/settings.", PLUG_TAG, name)
		client_print(0, print_chat, "[%s] your '%s' must be set to '%i' to play in this server.", PLUG_TAG, cvarname[tcheck], tval)
		client_print(id, print_console, "[%s] Please fix this cvar/setting before trying to connect to this server again.", PLUG_TAG)
		client_print(id, print_console, "[%s] You will continue to be kicked untill you fix this.", PLUG_TAG)
		set_task(5.0, "kickthisuser", id)
	}
}
public kickthisuser(id) {
	new userid = get_user_userid(id)
	server_cmd("kick #%d ^"ACCESS VIOLATION^"", userid)
}
stock randomperson() {
	new cnt, randpred
	new pickme = -1
	cnt = 0
	while (cnt < maxplayers && pickme == -1) {
		randpred = random_num(1, maxplayers)
		if (is_user_connected(randpred) && get_user_team(randpred) == 2 && is_user_alive(randpred)) pickme = randpred
		cnt ++
	}
	cnt = 0
	if (pickme == -1) {
		while (cnt < maxplayers && pickme == -1) {
			randpred = random_num(1, maxplayers)
			if (is_user_connected(randpred) && get_user_team(randpred) == 2) pickme = randpred
			cnt ++
		}
	}
	cnt = 0
	if (pickme == -1) {
		while (cnt < maxplayers && pickme == -1) {
			randpred = random_num(1, maxplayers)
			if (is_user_connected(randpred)) pickme = randpred
			cnt ++
		}
	}
	return pickme
}
stock fixhumans() {
	for (new i=0; i<maxplayers; i++) {
		if (is_user_connected(i)) {
			set_pev(i, pev_health, 99999.0)
			modelwarns[i] = 0
			if (i != gPredator) {
				if (get_user_team(i) == 1) cs_set_user_team(i,	CS_TEAM_CT)	//MAKE SURE THERES NO FAKE PREDS
				cFlashlight[i]		= 0
				cFlashbattery[i]	= 1000
				cPredDistance[i]	= 999.9
			}
		}
	}
}
stock predknifemdl(id) {
	if (cPredVisib >= 10 || cPredUncloak) {
		set_pev(id, pev_viewmodel2, THING_KNIFE_V_VIS)
		set_pev(id, pev_weaponmodel2, "")	//THING_KNIFE_P
	} else {
		set_pev(id, pev_viewmodel2, THING_KNIFE_V_INV)
		set_pev(id, pev_weaponmodel2, "")	//THING_KNIFE_P
	}
}

/*FAKEMETA UTIL*/
stock fm_fakedamage(victim, const classname[], Float:takedmgdamage, damagetype) {
	new class[] = "trigger_hurt"
	new entity = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, class))
	if (!entity) return 0
	new value[16]
	float_to_str(takedmgdamage * 2, value, sizeof value - 1)
	fm_set_kvd(entity, "dmg", value, class)
	num_to_str(damagetype, value, sizeof value - 1)
	fm_set_kvd(entity, "damagetype", value, class)
	fm_set_kvd(entity, "origin", "8192 8192 8192", class)
	dllfunc(DLLFunc_Spawn, entity)
	set_pev(entity, pev_classname, classname)
	dllfunc(DLLFunc_Touch, entity, victim)
	engfunc(EngFunc_RemoveEntity, entity)
	return 1
}
stock fm_set_kvd(entity, const key[], const value[], const classname[] = "") {
	if (classname[0]) {
		set_kvd(0, KV_ClassName, classname)
	} else {
		new class[32]
		pev(entity, pev_classname, class, sizeof class - 1)
		set_kvd(0, KV_ClassName, class)
	}
	set_kvd(0, KV_KeyName, key)
	set_kvd(0, KV_Value, value)
	set_kvd(0, KV_fHandled, 0)
	return dllfunc(DLLFunc_KeyValue, entity, 0)
}
stock bool:fm_is_visible(index, const Float:point[3]) {
	new Float:origin[3], Float:view_ofs[3], Float:eyespos[3]
	pev(index, pev_origin, origin)
	pev(index, pev_view_ofs, view_ofs)
	xs_vec_add(origin, view_ofs, eyespos)
	engfunc(EngFunc_TraceLine, eyespos, point, 0, index)
	new Float:fraction
	global_get(glb_trace_fraction, fraction)
	if (fraction == 1.0) return true
	return false
}
stock Float:get_view_angle_diff(index, Float:vec_c[3]) {
	new Float:vec_a[3], Float:vec_b[3], viewend[3]
	new Float:origin[3], Float:view_ofs[3]
	pev(index, pev_origin, origin)
	pev(index, pev_view_ofs, view_ofs)
	xs_vec_add(origin, view_ofs, vec_a)
	get_user_origin(index, viewend, 3)
	IVecFVec(viewend, vec_b)
	new Float:a = get_distance_f(vec_b, vec_c)
	new Float:b = get_distance_f(vec_a, vec_c)
	new Float:c = get_distance_f(vec_a, vec_b)
	return floatacos((b*b + c*c - a*a) / (2 * b * c), _:degrees)
}
stock Float:fm_distance_to_foothold(index) {
	new Float:mins[3], Float:maxs[3], Float:start[3], Float:dest[3], Float:end[3], fuckcrap[4] = {0, 0, 1, 0}, Float:value[4], Float:ret = -8191.0
	pev(index, pev_absmin, mins)
	pev(index, pev_absmax, maxs)
	start[1] = mins[1]
	start[2] = mins[2] + 10
	dest[1] = mins[1]
	dest[2] = -8191.0
	value[0] = mins[0]
	value[1] = maxs[0]
	value[2] = maxs[1]
	value[3] = mins[0]
	for (new i = 0; i < 4; ++i) {
		start[fuckcrap[i]] = value[i]
		dest[fuckcrap[i]] = value[i]
		engfunc(EngFunc_TraceLine, start, dest, 0, fuckcrap)
		global_get(glb_trace_endpos, end)
		if (end[2] > ret) ret = end[2]
	}
	ret = mins[2] - ret
	return ret > 0 ? ret : 0.0
}
stock msg_bartime2(index, scale, start_percent) {
	message_begin(MSG_ONE_UNRELIABLE, msgBartime, _, index)
	write_short(scale)
	write_short(start_percent)
	message_end()
}