/*

DONT EDIT ANYTHING THERE OR =

_________e$$$$$$e.
_______e$$$$$$$$$$e
______$$$$$$$$$$$$$$
_____d$$$$$$$$$$$$$$b
_____$$$$$$$$$$$$$$$$
____4$$$$$$$$$$$$$$$$F
____4$$$$$$$$$$$$$$$$F
_____$$$"_"$$$$"_"$$$F
_____$$F___4$$F___4$$
_____$$F___4$$F___F$$
_____'$$___$$$$___$$'
______4$$$$$"^$$$$$4
_______$$$$F__F$$$$
________"$$$ee$$$"
________._*$$$$*_
_________$_____.$
_________"$$$$$$"
__________^$$$$
_4$$c_______""_______.$$_
_^$$$b______________e$$$"
_d$$$$$e__________z$$$$$b
4$$$*$$$$$c____.$$$$$*$$$_
_""____^*$$$be$$$*"____^
__________"$$$$"
________.d$$P$$$b
_______d$$P___^$$$b
___.ed$$$"______"$$$be.
_$$$$$$P__________*$$$$$$
4$$$$$P____________$$$$$$"
_"*$$$"____________^$$P
____""______________^"

More info or concatct? info@cs-rockers.de or www.cs-rockers.de or in forum : www.cs-rockers.de/forum/

*/
#include <amxmodx>
#include <amxmisc>
#include <fun>
#include <engine>
#include <cstrike>
#include <fakemeta>

#define FANGEN_FLAG ADMIN_KICK
#define MIN_BOOST_DIST 100

#define FAENGER_R 150
#define FAENGER_G 255
#define FAENGER_B 0

#define OTHER_R 255
#define OTHER_G 255
#define OTHER_B 255

#define UEBERLEBEN 5

#define TURBO_VERBRAUCH 10
#define TURBO_TIME 0.25

new bool:vote = false
new bool:vote_erg[32]

new team_ct = 1
new team_t = 0

new bool:enable = false		// Wenn true, dann ist die Mod aktiviert
new team[32]			// Saves the teams
new score[32][4]		// players points (0 = Score, 1 = Score in round, 2 = catched, 3 = not be catched)
new wait = false			// if true, cant be more catched
new points[2]			// teams points (0 = Ts | 1 = CTs)
new bool:boost_show[32]
new bool:trueround = true
new round = 0
new bool:blockround = false
new turbo[32][2]		// Turbo (0 = on/off | 1 = charging)
new bool:firstspawn[32]

new statusMsg			// Took this from SH-Mod
new scoreMsg
new deathMsg

/*CVARS*/
new catch_speed,catch_f_speed,catch_o_speed,catch_l_speed,catch_t_speed,catch_godmode,
catch_distancecheck,catch_noknifes,catch_distance,catch_nofootsteps,vote_answers,vote_time,catch_render,
catch_bhop,catch_autobhop,catch_boost,catch_boostmode,catch_turbo

// =================================================================================================

public plugin_init() {
	register_plugin("...Catch-Mod...","2.0.1","One")
	
	// ===================================================================================Cvars
	register_cvar("CatchMod","2.0.2",FCVAR_SERVER)
	
	catch_speed = register_cvar("catch_speed","2.0")		// catch_speed
	catch_f_speed = register_cvar("catch_f_speed","1.0")		// normalspeed * catch_speed * catch_f_speed
	catch_o_speed = register_cvar("catch_o_speed","1.0")		// normalspeed * catch_speed * catch_o_speed
	catch_l_speed = register_cvar("catch_l_speed","1.15")		// normalspeed * catch_speed * catch_l_speed
	catch_t_speed = register_cvar("catch_t_speed","1.5")		// speed * catch_t_speed
	catch_godmode = register_cvar("catch_godmode","1")		// Godmode
	catch_distancecheck = register_cvar("catch_distancecheck","0")	// 4 players with bad commands
	catch_noknifes = register_cvar("catch_noknifes","0")
	catch_distance = register_cvar("catch_distance","70")		// DistanceCheck
	catch_nofootsteps = register_cvar("catch_nofootsteps","0")		// no Sounds, by running
	catch_render = register_cvar("catch_render","1")		// not change. ever 1.^^
	catch_bhop = register_cvar("catch_bhop","1")		// bunnyhopp
	catch_autobhop = register_cvar("catch_autobhop","0")		// Automatish Bunnyhop
	catch_boost = register_cvar("catch_boost","700")		// Boost
	catch_boostmode = register_cvar("catch_boostmode","0")		// Boostmode (0 = old | 1 = new)
	catch_turbo = register_cvar("catch_turbo","1")		// Turbo
	vote_answers = get_cvar_pointer ( "amx_vote_answers" )
	vote_time = get_cvar_pointer("amx_vote_time")

	// Cmds
	register_clcmd("say /catch_on","catch_enable",FANGEN_FLAG)
	register_clcmd("say /catch_off","catch_off",FANGEN_FLAG)
	
	register_clcmd("say /vote","start_vote",FANGEN_FLAG)
	register_clcmd("say /vote_off","cancel_vote",FANGEN_FLAG)
	
	register_srvcmd("catch_on","catch_enable")
	register_srvcmd("catch_off","catch_off")
	register_srvcmd("vote_on","start_vote")
	register_srvcmd("vote_off","cancel_vote")
	
	register_clcmd("say !stats","catch_stats")
	register_clcmd("say !help","catch_help")
	
	// ==================================================================================Events
	register_touch("player","player","touch")
	
	register_event("ResetHUD","resethud","be")
	//====================================================register_event("Damage","damage","be")
	
	register_logevent("startround",2,"0=World triggered","1=Round_Start")
	register_logevent("endround",2,"0=World triggered","1=Round_End")
	register_logevent("drawround",2,"0=World triggered","1=Round_Draw")
	register_logevent("gamestart",2,"0=World triggered","1=Game_Commencing")
	register_logevent("restartround",2,"1&Restart_Round_")
	
	// =====================================================================================Menu
	register_menu("Yeah, vote now for CATCH !",MENU_KEY_1|MENU_KEY_2,"vote_menu")
	
	// ===========================================================================Another things
	statusMsg = get_user_msgid("StatusText")
	deathMsg = get_user_msgid("DeathMsg")
	scoreMsg = get_user_msgid("ScoreInfo")
}

// =================================================================================================
// ==========[ Normal Function ]=================================================================
// =================================================================================================

public reset_stats(id) {
	team[id-1] = 0
	score[id-1][0] = 0
	score[id-1][1] = 0
	score[id-1][2] = 0
	score[id-1][3] = 0
	turbo[id-1][0] = 0
	turbo[id-1][1] = 100
}

// =================================================================================================
//===============[ Catcher ]========================================================================
//==================================================================================================
public faenger_num() {
	new count = 0
	for(new i=1;i<33;i++)
		if(team[i-1] == 1 && is_user_connected(i) && is_user_alive(i))
			count++
	
	return count
}

public other_num() {
	new count = 0
	for(new i=1;i<33;i++)
		if(team[i-1] == 0 && is_user_connected(i) && is_user_alive(i))
			count++
	
	return count
}

// =================================================================================================

public show_team() {
	for(new i=1;i<=get_maxplayers();i++) {
		if(is_user_connected(i) && is_user_alive(i)) {
			player_showteam(i)
		}
	}
}

public player_showteam(id) {
	new teams[32], turbos[32]
	if(team[id-1] == 0) {
		set_hudmessage(OTHER_R,OTHER_G,OTHER_B,0.02,0.25,0,0.1,5.0,0.0,0.0)
		copy(teams,127,"You´r a FLEER..")
		
		if(turbo[id-1][1] >= TURBO_VERBRAUCH)
			format(turbos,31,"^n%sTurbo: [===|===] %d%",turbo[id-1][0] == 1 ? "+" : "-",turbo[id-1][1])
	}
	else if(team[id-1] == 1) {
		set_hudmessage(FAENGER_R,FAENGER_G,FAENGER_B,0.02,0.25,0,0.1,5.0,0.0,0.0)
		copy(teams,127,"You have to CATCH,Go ,Go ,Go...")
	}
	
	show_hudmessage(id,"%s %s",teams,turbos)
	
	if(boost_show[id-1] == true) {
		set_hudmessage(OTHER_R,OTHER_G,OTHER_B,-1.0,0.55,0,0.1,5.0,0.0,0.0,1)
		show_hudmessage(id,"Shoot to boost ^n!")
	}
}

// =================================================================================================

public speed() {
	for(new i=1;i<33;i++)
		if(is_user_alive(i))
			speedup(i)
}


public speedup(id) {
	new Float:speed

	if(team[id-1] == 1)
		speed = 320.0 * get_pcvar_float(catch_speed) * get_pcvar_float(catch_f_speed)
	else {
		if(other_num() == 1 && !wait && get_playersnum() > 2)
			speed = 320.0 * get_pcvar_float(catch_speed) * get_pcvar_float(catch_l_speed)
		else
			speed = 320.0 * get_pcvar_float(catch_speed) * get_pcvar_float(catch_o_speed)
	}

	if(get_pcvar_num(catch_turbo) && turbo[id-1][0] == 1)
		speed *= get_pcvar_float(catch_t_speed)

	set_user_maxspeed(id,speed)
}

// =================================================================================================

/*public switchmodel(id) {
	entity_set_string(id,EV_SZ_viewmodel,"models/v_chub.mdl")
	entity_set_string(id,EV_SZ_weaponmodel,"models/p_gauss.mdl")
	entity_set_model(id,"models/player/halo/gign.mdl")
}*/

// =================================================================================================

public render(id) {
	if(get_pcvar_num(catch_render) == 1) {
		if(team[id-1] == 0)
			set_rendering(id,kRenderFxGlowShell,OTHER_R,OTHER_G,OTHER_B,kRenderNormal,25)
		else
			set_rendering(id,kRenderFxGlowShell,FAENGER_R,FAENGER_G,FAENGER_B,kRenderNormal,25)
	}
	else
		set_rendering(id)
}

// =================================================================================================

public bestimme_team(id) {
	if(get_user_team(id) == 1)
		team[id-1] = team_t
	else if(get_user_team(id) == 2)
		team[id-1] = team_ct
		
	render(id)
}

// =================================================================================================

public apply_scoreboard(id) {
	message_begin(MSG_ALL,get_user_msgid("ScoreInfo"))
	write_byte(id)
	write_short(score[id-1][0]+(score[id-1][3]*UEBERLEBEN))
	write_short(score[id-1][2])
	write_short(0)
	write_short(get_user_team(id))
	message_end()
	
	if(team[id-1] == 1) {
		new message[64]
		format(message,63,"[=======Point in thie round : %d======= ]",score[id-1][1])
		show_message(id,message)
	}
}

// =================================================================================================

public remove_hossis() {	
	new ent = find_ent(0,"monster_hostage")
	while(ent != 0) {	
		cs_set_hostage_foll(ent,0)
		ent = find_ent(ent,"monster_hostage")
	}
	
	ent = find_ent(0,"hostage_entity")
	while(ent != 0) {			
		cs_set_hostage_foll(ent,0)
		ent = find_ent(ent,"hostage_entity")
	}
}

// =================================================================================================

public catch_enable(id,level,cid) {
	if (!cmd_access(id, level, cid, 1))
		return PLUGIN_HANDLED
		
	catch_on(id)
	
	return PLUGIN_HANDLED
}

public catch_on(id) {
	if(enable == true)
		client_print(id,print_chat,"[ Catch 2.0.1 ] The Mod is active !")
	else {
		enable = true
		vote = false
		
		for(new i=1;i<33;i++) {
			team_ct = 1
			team_t = 0
			reset_stats(i)
		}
		
		points[0] = 0
		points[1] = 0
		
		for(new i=1;i<=get_maxplayers();i++)
			if(is_user_connected(i)) {
				client_print(i,print_chat,"[ Catch 2.0.1 ] The Mod is now active. [H]ave[F]un:-)")
				client_print(i,print_chat,"[ Catch 2.0.1 ] Say '!stats' for see the Statesboard and '!help' if you need HELP!")
				
				client_cmd(i,"cl_forwardspeed 9999")
				client_cmd(i,"cl_sidespeed 9999")
				client_cmd(i,"cl_backspeed 9999")
				client_cmd(i,"hud_centerid 0")
			}
		
		new catch_cfg[256], cfgdir[128]
		
		get_configsdir(cfgdir,127)	
		format(catch_cfg,255,"%s/catch.cfg",cfgdir)
		
		if(file_exists(catch_cfg)) {
			server_exec()
			server_cmd("exec %s",catch_cfg)
		}
		
		set_cvar_num("sv_restartround",1)
		
		set_task(3.0,"show_team",6000,"",0,"ab")
		set_task(2.0,"speed",7000,"",0,"ab")
		set_task(0.1,"distance_check",8000,"",0,"ab")
	}
}

public catch_off(id,level,cid) {
	if (!cmd_access(id, level, cid, 1))
		return PLUGIN_HANDLED
	
	if(enable == false)
		client_print(id,print_chat,"[ Catch 2.0.1 ] The Mod is deactive!")
	else {
		enable = false
		remove_task(1000)
		remove_task(6000)
		remove_task(7000)
		remove_task(8000)
		
		trueround = true
		round = 0
		
		for(new i=1;i<33;i++)
			if(is_user_connected(i))
				set_user_rendering(i)
			
		set_cvar_num("sv_restartround",1)
		
		set_msg_block(get_user_msgid("TeamScore"),BLOCK_NOT)
		set_msg_block(scoreMsg,BLOCK_NOT)
	}
		
	return PLUGIN_HANDLED
}

// =================================================================================================
//=============[ Help Motd ]========================================================================
//==================================================================================================

public catch_help(id) {
	if(enable) {
		new temp[2048]
		
		add(temp,2047,"<html><head><style>^n")
		add(temp,2047,"body { background-color:#000000; color:#FFFFFF; font-family:Verdana; font-size:7pt; }^n")
		add(temp,2047,"</style></head><body>^n")
		add(temp,2047,"<b>This is a AMXX-Plugin,& was writed by p4ddy, Edited/Translated/Endbugsed by One. There are 2 Teams & the Catcher-team have to catch the Fleer-Team. When anyone would be catched he is dead & have to wait for new round. The Cather become 1 Point for this & by sorvive the Team become 5 Points.</b>^n")
		add(temp,2047,"<b>How can i use my Turbo?</b><br>Prees the +attack2 key. (Standard rightmouse key)<br><br>^n")
		add(temp,2047,"<b>How can i boost my M8?</b><br>Your M8 has to getting on you & you have just to shoot.<br><br>^n")
		add(temp,2047,"<b>How can i see my Stats?</b><br>Say in chat <b>!stats</b>.<br><br>^n")
		add(temp,2047,"<b>Why am i slower?</b><br>1. delete this 3 CVars in you´r config.cfg (cl_forwardspeed, cl_sidespeed, cl_backspeed).<br>2. set this Cvats on 9999.<br><br>^n")
		add(temp,2047,"<b>Why i cant runing more on Edgs?</b><br>Just try with a Duckjump :-D.<br><br>^n")
		add(temp,2047,"<b>I touched a player, but he is not dead?</b><br>This is just a Ping-bug. Dont worry about this.<br><br>^n")
		add(temp,2047,"<b>How can i contact the Scripter?</b><br>E-Mail: <b>info@cs-rockers.de</b> or <b>www.cs-rocekrs.de</b> or <b>www.cs-rockers.de/forum/ </b>.^n")
		add(temp,2047,"</body></html>")
		
		show_motd(id,temp,"Catch 2.0.1 by One")
		
		return PLUGIN_HANDLED
	}
	
	return PLUGIN_CONTINUE
}

// =================================================================================================
//============[ Round stats ]=======================================================================
//==================================================================================================

public catch_stats(id) {
	if(enable) {
		client_print(id,print_chat,"[ Catch 2.0.1 ] You catched %d and would be %d catched.",score[id-1][0],score[id-1][2])
		client_print(id,print_chat,"[ Catch 2.0.1 ] You survived %d Rounds. Lucker",score[id-1][3])
	}
	
	return PLUGIN_HANDLED
}

// =================================================================================================
//=================[ Turbo )========================================================================
//==================================================================================================

public turbo_on(id) {
	if(is_user_alive(id) && team[id-1] == 0 && get_pcvar_num(catch_turbo)) {
		if(turbo[id-1][1] < TURBO_VERBRAUCH) {
			turbo[id-1][0] = 0
			speedup(id)
		}
		else {
			turbo[id-1][0] = 1
			turbo[id-1][1] -= TURBO_VERBRAUCH
			speedup(id)
			set_task(TURBO_TIME,"turbo_task",10000+id,"",0,"ab")
		}
		player_showteam(id)
	}

	return PLUGIN_HANDLED
}

public turbo_off(id) {
	if(get_pcvar_num(catch_turbo) || turbo[id-1][0] == 1) {
		turbo[id-1][0] = 0
		speedup(id)
		remove_task(id+10000)
		player_showteam(id)
	}

	return PLUGIN_HANDLED
}

public turbo_task(id) {
	new pid = id-10000
	if(is_user_alive(pid) && is_user_connected(pid)) {
		if(enable) {
			if(team[pid-1] == 0 && turbo[pid-1][0] == 1 && get_pcvar_num(catch_turbo)) {
				if(turbo[pid-1][1] < TURBO_VERBRAUCH) {
					turbo[pid-1][0] = 0
					speedup(pid)
					player_showteam(pid)
					remove_task(id)
				}
				else {
					turbo[pid-1][1] -= TURBO_VERBRAUCH
					player_showteam(pid)
				}
			}
			else {
				turbo[pid-1][0] = 0
				player_showteam(pid)
				speedup(pid)
				remove_task(id)
			}
		}
		else
			remove_task(id)
	}
	else {
		turbo[pid-1][0] = 0
		remove_task(id)
	}
}

// =================================================================================================

public show_message(id,text[]) {
	message_begin(MSG_ONE,statusMsg,{0,0,0},id)
	write_byte(0)
	write_string(text)
	message_end()
}

// =================================================================================================
// ==========[ Events ]=============================================================================
// =================================================================================================

public touch(pToucher, pTouched) {
	if(enable && !wait) {
		if(pToucher > 0 && pToucher < 33 && is_user_alive(pToucher) && team[pToucher-1] == 1) {
			if (pTouched > 0 && pTouched < 33 && is_user_alive(pTouched) && team[pTouched-1] == 0) {
				score[pToucher-1][0]++
				score[pToucher-1][1]++
				score[pTouched-1][2]++
				
				new team = get_user_team(pToucher)
				if(team == 1)
					points[0]++
				else
					points[1]++
				
				set_msg_block(deathMsg,BLOCK_ONCE) 
				set_msg_block(scoreMsg,BLOCK_ONCE)
				user_silentkill(pTouched)
				make_deathmsg(pToucher,pTouched,0,"his hands")
				
				entity_set_float(pToucher,EV_FL_frags,float(score[pToucher-1][0]+(score[pToucher-1][3]*UEBERLEBEN)))	
				apply_scoreboard(pToucher)
				apply_scoreboard(pTouched)
				
				update_teamscore()
				
				if(other_num() == 1)
					speed()
			}
		}
	}
}
//==================================================================================================
//============[ Distance Settings ]=================================================================
//==================================================================================================
public distance_check() {
	if(get_pcvar_num(catch_distancecheck) == 1 && !wait) {
		for(new i=1;i<33;i++) {
			if(is_user_alive(i)) {
				for(new x=1;x<33;x++) {
					if(is_user_alive(x) && is_visible(x,i) && i != x && team[i-1] != team[x-1]) {
						new iOrigin[3], xOrigin[3]
						get_user_origin(i,iOrigin)
						get_user_origin(x,xOrigin)
						if(get_distance(iOrigin,xOrigin) <= get_pcvar_num(catch_distance)) {
							if(team[i-1] == 1 && team[x-1] == 0)
								touch(i,x)
							else
								touch(x,i)
						}
					}
				}
			}
		}
	}
	
	remove_hossis()
}

// =================================================================================================
//===========[Client addCvars]======================================================================
// =================================================================================================

public resethud(id) {
	if(enable) {
		client_cmd(id,"cl_forwardspeed 9999")
		client_cmd(id,"cl_sidespeed 9999")
		client_cmd(id,"cl_backspeed 9999")
		client_cmd(id,"hud_centerid 0")
		
		set_task(0.1,"apply",id)
			
		score[id-1][1] = 0
		
		if(firstspawn[id-1]) {
			client_print(id,print_chat,"[ Catch 2.0.1 ] Welcome, [H]ave [F]un & [G]ood [L]uck !")
			client_print(id,print_chat,"[ Catch 2.0.1 ] Say '!stats' for see the Statesboard and '!help' if you need HELP!")
		}
	}
	
	firstspawn[id-1] = false
}

//==================================================================================================
//=================[God Mod & Steps]========================================================================
//==================================================================================================
public apply(id) {
	speedup(id)
	bestimme_team(id)
		
	if(get_pcvar_num(catch_godmode) == 1)
		set_user_godmode(id,1)
		
	if(get_pcvar_num(catch_nofootsteps) == 1)
		set_user_footsteps(id,1)
	

		
	player_showteam(id)
	
	client_print(id,print_center,"[ ======Terrorists %d : %d CounterTerrorists | Round: %d====== ]",points[0],points[1],round)
	
	if(team[id-1] == 1)
		client_print(id,print_chat,"[ Catch 2.0.1 ] You are now a CATCHER. You have to catch. Go,Go,Go...")
	else
		client_print(id,print_chat,"[ Catch 2.0.1 ] You have now to FLEE,Take care...")
		
	turbo[id-1][0] = 0
	turbo[id-1][1] = 100
		
	apply_scoreboard(id)
}

// =================================================================================================
//=================[ Bunnyhopp & ALL SETTINGS]====================================================================
//==================================================================================================

public client_PreThink(id) {
	if(enable) {
		new buttons = get_user_button(id)
		
		if(get_pcvar_num(catch_bhop) == 1 && buttons|IN_DUCK)
			entity_set_float(id,EV_FL_fuser2,0.1)
		
		if(get_pcvar_num(catch_autobhop) == 1) {
			if(buttons & IN_JUMP) {
				new flags = entity_get_int(id, EV_INT_flags)
				
				if(flags|FL_WATERJUMP && entity_get_int(id,EV_INT_waterlevel)<2 && flags&FL_ONGROUND) {
					new Float:velocity[3]
					get_user_velocity(id,velocity)
					velocity[2] += 250.0
					set_user_velocity(id,velocity)
					entity_set_int(id, EV_INT_gaitsequence, 6)
				}
			}
		}
		
		new clip, ammo
		if(get_pcvar_num(catch_noknifes) == 0 && user_has_weapon(id,29) && get_user_weapon(id,clip,ammo) != 29) {
			client_cmd(id,"use weapon_knife")
		}
		
		if(get_pcvar_num(catch_turbo)) {
			if(buttons&IN_ATTACK2) {
				if(turbo[id-1][0] == 0 && turbo[id-1][1] >= TURBO_VERBRAUCH)
					turbo_on(id)
			}
			else if(turbo[id-1][0] == 1)
				turbo_off(id)
		}
		
		if(get_pcvar_num(catch_boost)) {
			new Float:viewangles[3]
			entity_get_vector(id,EV_VEC_v_angle,viewangles)
			
			new aimid, body
			get_user_aiming(id,aimid,body)
			if(is_user_alive(id) && is_user_alive(aimid) && id != aimid && aimid > 0 && aimid < 33 && team[id-1] == team[aimid-1] && viewangles[0] < -75.0) {
				new aOrigin[3], pOrigin[3]
				get_user_origin(id,pOrigin)
				get_user_origin(aimid,aOrigin)
				if(get_distance(pOrigin,aOrigin) <= MIN_BOOST_DIST) {
					if(buttons & IN_ATTACK) {
						new Float:velocity[3]
						if(get_pcvar_num(catch_boostmode) == 1)
							VelocityByAim(id,get_pcvar_num(catch_boost),velocity)
						else
							velocity[2] = float(get_pcvar_num(catch_boost))
						set_user_velocity(aimid,velocity)
					}
					else if(boost_show[id-1] == false) {
						boost_show[id-1] = true
						player_showteam(id)
					}
				}
			}
			else if(boost_show[id-1] == true) {
				boost_show[id-1] = false
				set_hudmessage(0,0,0,-1.0,0.35,0,6.0,12.0,0.1,0.1,1)
				show_hudmessage(id,"")
			}
		}
	}
}

// =================================================================================================
//==================[ Endround ]====================================================================
//==================================================================================================

public endround() {
	if(enable && !blockround) {
		new other_win = 0, punkte = 0
		
		for(new i=1;i<33;i++) {
			if(is_user_alive(i) && is_user_connected(i) && team[i-1] == 0) {
				score[i-1][3]++
				if(get_user_team(i) == 1)
					points[0] += UEBERLEBEN
				else
					points[1] += UEBERLEBEN
					
				entity_set_float(i,EV_FL_frags,float(score[i-1][0]+score[i-1][3]))	
				apply_scoreboard(i)
					
				punkte++
				other_win = 1
			}
		}
		
		if(other_win == 1) {
			for(new i=1;i<33;i++) {
				if(is_user_connected(i))
					client_print(i,print_chat,"[ Catch 2.0.1 ] Fleers won this round. +%d Point%s",punkte*UEBERLEBEN,punkte*UEBERLEBEN > 1 ? "e" : "")
			}
		}
		else {
			for(new i=1;i<33;i++) {
				if(is_user_connected(i))
					client_print(i,print_chat,"[ Catch 2.0.1 ] Catchers won this round!")
			}	
		}
		
		if(team_ct == 1) {
			team_ct = 0
			team_t = 1
		}
		else {
			team_ct = 1
			team_t = 0
		}
		
		wait = true
		trueround = true
		
		update_teamscore()
		set_msg_block(get_user_msgid("TeamScore"),BLOCK_SET)
		set_msg_block(scoreMsg,BLOCK_SET)
	}
}

//==================================================================================================
//=================[ RR Game]=======================================================================
//==================================================================================================
public gamestart() {
	restartround()
	blockround = true
}

public restartround() {
	for(new i=1;i<33;i++) {
		team_ct = 1
		team_t = 0
		reset_stats(i)
	}
		
	points[0] = 0
	points[1] = 0
	
	round = 0
	trueround = true
}

// =================================================================================================

public drawround() {
	if(enable) {
		for(new i=1;i<33;i++)
			score[i-1][1] = 0
			
		trueround = false
		wait = true
		
		//set_task(0.1,"update_teamscore",502)
		
		set_msg_block(get_user_msgid("TeamScore"),BLOCK_SET)
		set_msg_block(scoreMsg,BLOCK_SET)
	}
}

public startround() {
	if(enable) {
		set_task(1.5,"unwait",1000)
		set_task(0.2,"update_teamscore",500)
		
		if(trueround)
			round++
			
		trueround = false
	}
	blockround = false
}

public unwait() {
	wait = false
	set_msg_block(get_user_msgid("TeamScore"),BLOCK_NOT)
	set_msg_block(scoreMsg,BLOCK_NOT)
}

public update_teamscore() {
	message_begin(MSG_ALL,get_user_msgid("TeamScore"))
	write_string("TERRORIST")
	write_short(points[0])
	message_end()
		
	message_begin(MSG_ALL,get_user_msgid("TeamScore"))
	write_string("CT")
	write_short(points[1])
	message_end()
}

// =================================================================================================
//==========[ Add Settings Client ]=================================================================
//==================================================================================================

public client_disconnect(id) {
	client_cmd(id,"cl_forwardspeed 400")
	client_cmd(id,"cl_backspeed 400")
	client_cmd(id,"cl_sidespeed 400")
	reset_stats(id)
	remove_task(id+10000)
	firstspawn[id-1] = true
}

public client_putinserver(id) {
	reset_stats(id)
	firstspawn[id-1] = true
}

// =================================================================================================
// ==========[ Vote ]===============================================================================
// =================================================================================================

public show_votemenu(id) {
	show_menu(id,MENU_KEY_1|MENU_KEY_2,"^n^n^nyYeah...Vote now for the CATCH-MOD?^n^nw01. Yeah^n02. Never")
}

public vote_menu(id,key) {
	if(vote == true) {
		if(key == 0) {
			vote_erg[id-1] = true
			
			if(get_pcvar_num(vote_answers) == 1) {
				new name[32]
				get_user_name(id,name,31)
			
				for(new i=1;i<=get_maxplayers();i++)
					if(is_user_connected(i))
						client_print(i,print_chat,"[ Catch 2.0.1 - Vote ] %s voted for Yeah...",name)
			}
		}
		else if(key == 1) {
			vote_erg[id-1] = false
			
			if(get_pcvar_num(vote_answers) == 1) {
				new name[32]
				get_user_name(id,name,31)
			
				for(new i=1;i<=get_maxplayers();i++)
					if(is_user_connected(i))
						client_print(i,print_chat,"[ Catch 2.0.1 - Vote ] %s voted for Never",name)
			}
		}
	}
}

// =================================================================================================

public check_vote(id) {
	if(vote) {
		vote = false
		remove_task(3000)
		
		new yes = 0, no = 0
		
		for(new i=1;i<33;i++)
			if(is_user_connected(i) && vote_erg[i-1])
				yes++
			else if(is_user_connected(i) && !vote_erg[i-1])
				no++
				
		for(new i=1;i<=get_maxplayers();i++)
			if(is_user_connected(i))
				client_print(i,print_chat,"[ Catch 2.0.1 - Vote ] Yeah: %d votes | Never: %d votes",yes,no)
				
		if(yes > no && !enable)
			catch_on(0)
	}
}

public start_vote(id,level,cid) {
	if (!cmd_access(id, level, cid, 1))
		return PLUGIN_HANDLED
	
	if(enable == true)
		client_print(id,print_chat,"[ Catch 2.0.1 ] The Mod is active!")
	else {
		vote = true
		set_task(get_pcvar_float(vote_time),"check_vote",3000)
		
		for(new i=1;i<=get_maxplayers();i++)
			if(is_user_connected(i))
				show_votemenu(i)
	}
	
	return PLUGIN_HANDLED
}

public cancel_vote(id,level,cid) {
	if (!cmd_access(id, level, cid, 1))
		return PLUGIN_HANDLED
	
	if(vote == false)
		client_print(id,print_chat,"[ Catch 2.0.1 - Vote ] There are no votes active!")
	else {
		vote = false
		remove_task(3000)
		
		for(new i=1;i<=get_maxplayers();i++)
			if(is_user_connected(i))
				client_print(i,print_chat,"[ Catch 2.0.1 - Vote ] Admin canceled the Vote!")
	}
	
	return PLUGIN_HANDLED
}
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1031\\ f0\\ fs16 \n\\ par }
*/
