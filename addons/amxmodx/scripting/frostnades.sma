#include <amxmodx>
#include <cstrike>
#include <fakemeta>
#include <fun>
#include <hamsandwich>

new const VERSION[] = "2.14";

#define message_begin_fl(%1,%2,%3,%4) engfunc(EngFunc_MessageBegin, %1, %2, %3, %4)
#define write_coord_fl(%1) engfunc(EngFunc_WriteCoord, %1)

#define m_pPlayer			41
#define m_pActiveItem		373
#define m_flFlashedUntil	514
#define m_flFlashHoldTime	517
#define OFFSET_WEAPON_CSWID	43
#define Ham_Player_ResetMaxSpeed Ham_Item_PreFrame

#define MAX_WEAPONS		32
#define AMMO_FLASHBANG		11
#define AMMO_HEGRENADE		12
#define AMMO_SMOKEGRENADE	13
#define DMG_GRENADE		(1<<24) // thanks arkshine
#define FFADE_IN			0x0000 // just here so we don't pass 0 into the function
#define BREAK_GLASS		0x01
#define STATUS_HIDE		0
#define STATUS_SHOW		1
#define STATUS_FLASH		2

#define GLOW_AMOUNT		1.0
#define FROST_RADIUS		240.0

#define NT_FLASHBANG		(1<<0) // 1; CSW:25
#define NT_HEGRENADE		(1<<1) // 2; CSW:4
#define NT_SMOKEGRENADE		(1<<2) // 4; CSW:9

new const GRENADE_NAMES[][] = {
	"weapon_hegrenade",
	"weapon_flashbang",
	"weapon_smokegrenade"
};

#define ICON_HASNADE		1
#define ICON_ISCHILLED		2

#define TASK_REMOVE_CHILL	100
#define TASK_REMOVE_FREEZE	200

new const MODEL_FROZEN[]	= "models/pi_shrub.mdl";
new const MODEL_GLASSGIBS[]	= "models/glassgibs.mdl";

new const SOUND_EXPLODE[]	= "x/x_shoot1.wav";
new const SOUND_FROZEN[]	= "debris/glass1.wav";
new const SOUND_UNFROZEN[]	= "debris/glass3.wav";
new const SOUND_CHILLED[]	= "player/pl_duct2.wav";
new const SOUND_PICKUP[]	= "items/gunpickup2.wav";

new const SPRITE_TRAIL[]	= "sprites/laserbeam.spr";
new const SPRITE_SMOKE[]	= "sprites/steam1.spr";
new const SPRITE_EXPLO[]	= "sprites/shockwave.spr";

new pcv_enabled, pcv_override, pcv_nadetypes, pcv_teams, pcv_price, pcv_limit, pcv_buyzone, pcv_color, pcv_icon,
		pcv_by_radius, pcv_hitself, pcv_los, pcv_maxdamage, pcv_mindamage, pcv_chill_maxchance, pcv_chill_minchance,
		pcv_chill_duration, pcv_chill_variance, pcv_chill_speed, pcv_freeze_maxchance, pcv_freeze_minchance,
		pcv_freeze_duration, pcv_freeze_variance;

new maxPlayers, gmsgScreenFade, gmsgStatusIcon, gmsgBlinkAcct, gmsgAmmoPickup, gmsgTextMsg,
		gmsgWeapPickup, glassGibs, trailSpr, smokeSpr, exploSpr, mp_friendlyfire, czero, bot_quota, czBotHams, fmFwdPPT,
		fnFwdPlayerChilled, fnFwdPlayerFrozen, bool:roundRestarting;

new isChilled[33], isFrozen[33], frostKilled[33], novaDisplay[33], Float:glowColor[33][3], Float:oldGravity[33], oldRenderFx[33],
		Float:oldRenderColor[33][3], oldRenderMode[33], Float:oldRenderAmt[33], hasFrostNade[33], nadesBought[33];

public plugin_init()
{
	register_plugin("FrostNades",VERSION,"Avalanche");
	register_cvar("fn_version",VERSION,FCVAR_SERVER);

	pcv_enabled = register_cvar("fn_enabled","1");
	pcv_override = register_cvar("fn_override","1");
	pcv_nadetypes = register_cvar("fn_nadetypes","4"); // NT_SMOKEGRENADE
	pcv_teams = register_cvar("fn_teams","3");
	pcv_price = register_cvar("fn_price","300");
	pcv_icon = register_cvar("fn_icon","1");
	pcv_limit = register_cvar("fn_limit","0");
	pcv_buyzone = register_cvar("fn_buyzone","1");
	pcv_color = register_cvar("fn_color","0 206 209");

	pcv_by_radius = register_cvar("fn_by_radius","0.0");
	pcv_hitself = register_cvar("fn_hitself","1");
	pcv_los = register_cvar("fn_los","1");
	pcv_maxdamage = register_cvar("fn_maxdamage","20.0");
	pcv_mindamage = register_cvar("fn_mindamage","1.0");
	pcv_chill_maxchance = register_cvar("fn_chill_maxchance","100.0");
	pcv_chill_minchance = register_cvar("fn_chill_minchance","100.0");
	pcv_chill_duration = register_cvar("fn_chill_duration","7.0");
	pcv_chill_variance = register_cvar("fn_chill_variance","1.0");
	pcv_chill_speed = register_cvar("fn_chill_speed","60.0");
	pcv_freeze_maxchance = register_cvar("fn_freeze_maxchance","110.0");
	pcv_freeze_minchance = register_cvar("fn_freeze_minchance","40.0");
	pcv_freeze_duration = register_cvar("fn_freeze_duration","4.0");
	pcv_freeze_variance = register_cvar("fn_freeze_variance","0.5");
	
	mp_friendlyfire = get_cvar_pointer("mp_friendlyfire");
	
	new mod[6];
	get_modname(mod,5);
	if(equal(mod,"czero"))
	{
		czero = 1;
		bot_quota = get_cvar_pointer("bot_quota");
	}
	
	maxPlayers = get_maxplayers();
	gmsgScreenFade = get_user_msgid("ScreenFade");
	gmsgStatusIcon = get_user_msgid("StatusIcon");
	gmsgBlinkAcct = get_user_msgid("BlinkAcct");
	gmsgAmmoPickup = get_user_msgid("AmmoPickup");
	gmsgWeapPickup = get_user_msgid("WeapPickup");
	gmsgTextMsg = get_user_msgid("TextMsg");

	register_forward(FM_SetModel,"fw_setmodel",1);
	register_message(get_user_msgid("DeathMsg"),"msg_deathmsg");
	
	register_event("ResetHUD", "event_resethud", "b");
	register_event("TextMsg", "event_round_restart", "a", "2=#Game_Commencing", "2=#Game_will_restart_in");
	register_event("HLTV", "event_new_round", "a", "1=0", "2=0");

	RegisterHam(Ham_Spawn,"player","ham_player_spawn",1);
	RegisterHam(Ham_Killed,"player","ham_player_killed",1);
	RegisterHam(Ham_Player_ResetMaxSpeed,"player","ham_player_resetmaxspeed",1);
	RegisterHam(Ham_Think,"grenade","ham_grenade_think",0);
	RegisterHam(Ham_Use, "player_weaponstrip", "ham_player_weaponstrip_use", 1);
	
	for(new i=0; i<sizeof GRENADE_NAMES; i++)
	{
		RegisterHam(Ham_Item_Deploy, GRENADE_NAMES[i], "ham_grenade_deploy", 1);
		RegisterHam(Ham_Item_Holster, GRENADE_NAMES[i], "ham_grenade_holster", 1);
		RegisterHam(Ham_Item_AddToPlayer, GRENADE_NAMES[i], "ham_grenade_addtoplayer", 1);
		RegisterHam(Ham_Item_AddDuplicate, GRENADE_NAMES[i], "ham_grenade_addduplicate", 1);
	}
	
	register_clcmd("say /fn","buy_frostnade");
	register_clcmd("say_team /fn","buy_frostnade");
	register_clcmd("say /frostnade","buy_frostnade");
	register_clcmd("say_team /frostnade","buy_frostnade");
	
	fnFwdPlayerChilled = CreateMultiForward("frostnades_player_chilled", ET_STOP, FP_CELL, FP_CELL);
	fnFwdPlayerFrozen  = CreateMultiForward("frostnades_player_frozen",  ET_STOP, FP_CELL, FP_CELL);
}

public plugin_end()
{
	DestroyForward(fnFwdPlayerChilled);
	DestroyForward(fnFwdPlayerFrozen);
}

public plugin_precache()
{
	precache_model(MODEL_FROZEN);
	glassGibs = precache_model(MODEL_GLASSGIBS);

	precache_sound(SOUND_EXPLODE); // grenade explodes
	precache_sound(SOUND_FROZEN); // player is frozen
	precache_sound(SOUND_UNFROZEN); // frozen wears off
	precache_sound(SOUND_CHILLED); // player is chilled
	precache_sound(SOUND_PICKUP); // player buys frostnade

	trailSpr = precache_model(SPRITE_TRAIL);
	smokeSpr = precache_model(SPRITE_SMOKE);
	exploSpr = precache_model(SPRITE_EXPLO);
}

public client_putinserver(id)
{
	isChilled[id] = 0;
	isFrozen[id] = 0;
	frostKilled[id] = 0;
	novaDisplay[id] = 0;
	hasFrostNade[id] = 0;
	
	if(czero && !czBotHams && is_user_bot(id) && get_pcvar_num(bot_quota) > 0)
		set_task(0.1,"czbot_hook_ham",id);
}

public client_disconnect(id)
{
	if(isChilled[id]) task_remove_chill(TASK_REMOVE_CHILL+id);
	if(isFrozen[id]) task_remove_freeze(TASK_REMOVE_FREEZE+id);
}

// registering a ham hook for "player" won't register it for CZ bots,
// for some reason. so we have to register it by entity. 
public czbot_hook_ham(id)
{
	if(!czBotHams && is_user_connected(id) && is_user_bot(id) && get_pcvar_num(bot_quota) > 0)
	{
		RegisterHamFromEntity(Ham_Spawn,id,"ham_player_spawn",1);
		RegisterHamFromEntity(Ham_Killed,id,"ham_player_killed",1);
		RegisterHamFromEntity(Ham_Player_ResetMaxSpeed,id,"ham_player_resetmaxspeed",1);
		czBotHams = 1;
	}
}

// intercept server log messages to replace grenade kills with frostgrenade kills
public plugin_log()
{
	static arg[512];
	
	if(get_pcvar_num(pcv_enabled) && read_logargc() >= 5)
	{
		read_logargv(1, arg, 7); // "killed"
		
		if(equal(arg, "killed"))
		{
			read_logargv(2, arg, 127); // info of player that was killed
			
			// get ID of player that was killed
			new dummy[1], killedUserId;
			parse_loguser(arg, dummy, 0, killedUserId);
			new killedId = find_player("k", killedUserId);
			
			if(killedId && frostKilled[killedId])
			{	
				// override with frostgrenade message
				read_logdata(arg, 511);
				replace(arg, 511, "with ^"grenade^"", "with ^"frostgrenade^"");				
				log_message("%s", arg);

				return PLUGIN_HANDLED;
			}
		}
	}
	
	return PLUGIN_CONTINUE;
}

/****************************************
* PRIMARY FUNCTIONS AND SUCH
****************************************/

public buy_frostnade(id)
{
	if(!get_pcvar_num(pcv_enabled) || get_pcvar_num(pcv_override))
		return PLUGIN_CONTINUE;

	if(!is_user_alive(id)) return PLUGIN_HANDLED;

	if(get_pcvar_num(pcv_buyzone) && !cs_get_user_buyzone(id))
	{
		// #Cstrike_NotInBuyZone won't work for some reason
		client_print(id,print_center,"You are not in a buy zone.");

		return PLUGIN_HANDLED;
	}

	if(!(get_pcvar_num(pcv_teams) & _:cs_get_user_team(id)))
	{
		// have to do it this way to format
		message_begin(MSG_ONE,gmsgTextMsg,_,id);
		write_byte(print_center);
		write_string("#Alias_Not_Avail");
		write_string("Frost Grenade");
		message_end();

		return PLUGIN_HANDLED;
	}

	if(hasFrostNade[id])
	{
		client_print(id,print_center,"#Cstrike_Already_Own_Weapon");
		return PLUGIN_HANDLED;
	}
	
	new limit = get_pcvar_num(pcv_limit);
	if(limit && nadesBought[id] >= limit)
	{
		client_print(id,print_center,"#Cstrike_TitlesTXT_Cannot_Carry_Anymore");
		return PLUGIN_HANDLED;
	}
	
	new money = cs_get_user_money(id), price = get_pcvar_num(pcv_price);

	// need more vespene gas
	if(money < price)
	{
		client_print(id,print_center,"#Cstrike_TitlesTXT_Not_Enough_Money");
		
		message_begin(MSG_ONE_UNRELIABLE,gmsgBlinkAcct,_,id);
		write_byte(2);
		message_end();

		return PLUGIN_HANDLED;
	}
	
	// try to use smokegrenade, then flashbang, then hegrenade
	new wpnid = CSW_SMOKEGRENADE, ammoid = AMMO_SMOKEGRENADE, wpnName[20] = "weapon_smokegrenade", type = get_pcvar_num(pcv_nadetypes);
	if(!(type & NT_SMOKEGRENADE))
	{
		if(type & NT_FLASHBANG)
		{
			wpnid = CSW_FLASHBANG;
			ammoid = AMMO_FLASHBANG;
			wpnName = "weapon_flashbang";
		}
		else if(type & NT_HEGRENADE)
		{
			wpnid = CSW_HEGRENADE;
			ammoid = AMMO_HEGRENADE;
			wpnName = "weapon_hegrenade";
		}
	}
	
	hasFrostNade[id] = wpnid;
	nadesBought[id]++;
	cs_set_user_money(id,money - price);

	new ammo = cs_get_user_bpammo(id,wpnid);

	// give him one
	if(!ammo) give_item(id,wpnName);
	else
	{
		cs_set_user_bpammo(id,wpnid,ammo+1);
		
		// just so the player can see what kind it is on his HUD

		message_begin(MSG_ONE,gmsgAmmoPickup,_,id);
		write_byte(ammoid);
		write_byte(ammo+1);
		message_end();

		message_begin(MSG_ONE,gmsgWeapPickup,_,id);
		write_byte(wpnid);
		message_end();
		
		// won't play via cs_set_user_bpammo
		engfunc(EngFunc_EmitSound,id,CHAN_ITEM,SOUND_PICKUP,VOL_NORM,ATTN_NORM,0,PITCH_NORM);
		
		// for icon management
		grenade_added(id, wpnid);
	}
	
	return PLUGIN_HANDLED;
}

// entity is given a model (used to detect for thrown grenades)
public fw_setmodel(ent,model[])
{
	if(!get_pcvar_num(pcv_enabled)) return FMRES_IGNORED;

	new owner = pev(ent,pev_owner);
	if(!is_user_connected(owner)) return FMRES_IGNORED;
	
	// this isn't going to explode
	new Float:dmgtime;
	pev(ent,pev_dmgtime,dmgtime);
	if(dmgtime == 0.0) return FMRES_IGNORED;
	
	new type, csw;
	if(model[7] == 'w' && model[8] == '_')
	{
		switch(model[9])
		{
			case 'h': { type = NT_HEGRENADE; csw = CSW_HEGRENADE; }
			case 'f': { type = NT_FLASHBANG; csw = CSW_FLASHBANG; }
			case 's': { type = NT_SMOKEGRENADE; csw = CSW_SMOKEGRENADE; }
		}
	}
	if(!type) return FMRES_IGNORED;
	
	new team = _:cs_get_user_team(owner);

	// have a frostnade (override off) ;OR; override enabled, on valid team, using valid frostnade type
	if(hasFrostNade[owner] == csw || (get_pcvar_num(pcv_override)
			&& (get_pcvar_num(pcv_teams) & team) && (get_pcvar_num(pcv_nadetypes) & type)))
	{
		// not using override
		if(hasFrostNade[owner] == csw)
		{
			hasFrostNade[owner] = 0;
			if(get_pcvar_num(pcv_icon) == ICON_HASNADE)
			{
				show_icon(owner, STATUS_HIDE);
			}
		}

		set_pev(ent,pev_team,team);
		set_pev(ent,pev_bInDuck,1); // flag it as a frostnade

		new rgb[3], Float:rgbF[3];
		get_rgb_colors(team,rgb);
		IVecFVec(rgb, rgbF);
		
		// glowshell
		set_pev(ent,pev_rendermode,kRenderNormal);
		set_pev(ent,pev_renderfx,kRenderFxGlowShell);
		set_pev(ent,pev_rendercolor,rgbF);
		set_pev(ent,pev_renderamt,16.0);

		set_beamfollow(ent,10,10,rgb,100);
	}

	return FMRES_IGNORED;
}

// freeze a player in place whilst he's frozen
public fw_playerprethink(id)
{
	/*if(isChilled[id])
	{
		// remember rendering changes
		new fx = pev(id,pev_renderfx), Float:color[3], mode = pev(id,pev_rendermode), Float:amount;
		pev(id,pev_rendercolor,color);
		pev(id,pev_renderamt,amount);

		if(fx != kRenderFxGlowShell)
		{
			oldRenderFx[id] = fx;
			set_pev(id,pev_renderfx,kRenderFxGlowShell);
		}
		if(color[0] != glowColor[id][0] || color[1] != glowColor[id][1] || color[2] != glowColor[id][2])
		{
			oldRenderColor[id] = color;
			set_pev(id,pev_rendercolor,glowColor[id]);
		}
		if(mode != kRenderNormal)
		{
			oldRenderMode[id] = mode;
			set_pev(id,pev_rendermode,kRenderNormal);
		}
		if(amount != GLOW_AMOUNT)
		{
			oldRenderAmt[id] = amount;
			set_pev(id,pev_renderamt,GLOW_AMOUNT);
		}
	}*/

	if(isFrozen[id])
	{
		set_pev(id,pev_velocity,Float:{0.0,0.0,0.0}); // stop motion
		
		new Float:gravity;
		pev(id,pev_gravity,gravity);
		
		// remember any gravity changes
		if(gravity != 0.000000001 && gravity != 999999999.9)
			oldGravity[id] = gravity;

		// if are on the ground and about to jump, set the gravity too high to really do so
		if((pev(id,pev_button) & IN_JUMP) && !(pev(id,pev_oldbuttons) & IN_JUMP) && (pev(id,pev_flags) & FL_ONGROUND))
			set_pev(id,pev_gravity,999999999.9);

		// otherwise, set the gravity so low that they don't fall
		else set_pev(id,pev_gravity,0.000000001);
	}
	
	return FMRES_IGNORED;
}

// override grenade kill message with skull and crossbones
public msg_deathmsg(msg_id,msg_dest,msg_entity)
{
	new victim = get_msg_arg_int(2);
	if(!is_user_connected(victim) || !frostKilled[victim]) return PLUGIN_CONTINUE;

	static weapon[8];
	get_msg_arg_string(4,weapon,7);
	if(equal(weapon,"grenade")) set_msg_arg_string(4,"frostgrenade");

	//frostKilled[victim] = 0;
	return PLUGIN_CONTINUE;
}

// catch HUD reset to re-display icon if necessary
public event_resethud(id)
{
	if(!is_user_alive(id) || !get_pcvar_num(pcv_enabled)) return;

	if(get_pcvar_num(pcv_icon) == ICON_HASNADE)
	{
		new status = player_has_frostnade(id);
		show_icon(id, status);
	}

	return;
}

// round is restarting (TAG: sv_restartround)
public event_round_restart()
{
	// just remember for event_new_round
	roundRestarting = true;
}

// start of a new round
public event_new_round()
{
	if(roundRestarting)
	{
		roundRestarting = false;
		
		// clear frost grenades from all players (for override mode)
		for(new i=1;i<=maxPlayers;i++)
		{
			hasFrostNade[i] = 0;
		}
	}
}

// rezzed
public ham_player_spawn(id)
{
	nadesBought[id] = 0;
	
	if(is_user_alive(id))
	{
		if(isChilled[id]) task_remove_chill(TASK_REMOVE_CHILL+id);
		if(isFrozen[id]) task_remove_freeze(TASK_REMOVE_FREEZE+id);
	}
	
	return HAM_IGNORED;
}

// killed to death
public ham_player_killed(id)
{
	hasFrostNade[id] = 0;

	if(get_pcvar_num(pcv_enabled) && get_pcvar_num(pcv_icon) == ICON_HASNADE)
	{
		show_icon(id, STATUS_HIDE);
	}

	if(isChilled[id]) task_remove_chill(TASK_REMOVE_CHILL+id);
	if(isFrozen[id]) task_remove_freeze(TASK_REMOVE_FREEZE+id);
	
	return HAM_IGNORED;
}

// movement speed is changed
public ham_player_resetmaxspeed(id)
{
	if(get_pcvar_num(pcv_enabled))
	{
		set_user_chillfreeze_speed(id);
	}

	return HAM_IGNORED;
}

// grenade is ticking away
public ham_grenade_think(ent)
{
	// not a frostnade
	if(!pev_valid(ent) || !pev(ent,pev_bInDuck)) return HAM_IGNORED;
	
	new Float:dmgtime;
	pev(ent,pev_dmgtime,dmgtime);
	if(dmgtime > get_gametime()) return HAM_IGNORED;
	
	// and boom goes the dynamite
	frostnade_explode(ent);

	return HAM_SUPERCEDE;
}

// a player_weaponstrip is used
public ham_player_weaponstrip_use(ent, idcaller, idactivator, use_type, Float:value)
{
	if(idcaller >= 1 && idcaller <= maxPlayers)
	{
		// clear frostnade when using override
		hasFrostNade[idcaller] = 0;

		if(is_user_alive(idcaller) && get_pcvar_num(pcv_enabled) && get_pcvar_num(pcv_icon) == ICON_HASNADE)
		{
			new status = player_has_frostnade(idcaller);
			show_icon(idcaller, status);
		}
	}

	return HAM_IGNORED;
}

// some kind of grenade is deployed
public ham_grenade_deploy(ent)
{	
	if(pev_valid(ent))
	{
		grenade_deployed(get_pdata_cbase(ent, m_pPlayer, 4),
			get_pdata_int(ent, OFFSET_WEAPON_CSWID, 4));
	}
	
	return HAM_IGNORED;
}

// some kind of grenade is holstered
public ham_grenade_holster(ent)
{
	if(pev_valid(ent))
	{
		grenade_holstered(get_pdata_cbase(ent, m_pPlayer, 4),
			get_pdata_int(ent, OFFSET_WEAPON_CSWID, 4));
	}
	
	return HAM_IGNORED;
}

// some kind of grenade is added to a player's inventory
public ham_grenade_addtoplayer(ent, id)
{
	if(pev_valid(ent))
	{
		grenade_added(id, get_pdata_int(ent, OFFSET_WEAPON_CSWID, 4));
	}

	return HAM_IGNORED;
}

// some kind of grenade is added to a player's inventory, when he already has one
public ham_grenade_addduplicate(ent, orig)
{
	if(pev_valid(orig))
	{
		grenade_added(pev(orig, pev_owner), get_pdata_int(orig, OFFSET_WEAPON_CSWID, 4));
	}
	
	return HAM_IGNORED;
}

// handle when player id deploys a grenade with weapon id wid
grenade_deployed(id, wid)
{
	// if we should worry about managing my icon now
	if(get_pcvar_num(pcv_enabled) && is_user_alive(id) && get_pcvar_num(pcv_icon) == ICON_HASNADE)
	{
		// if I just switched to a frost grenade
		if( wid == hasFrostNade[id]
			|| (get_pcvar_num(pcv_override) && (get_pcvar_num(pcv_teams) & _:cs_get_user_team(id)) && is_wid_in_nadetypes(wid)) )
		{
			show_icon(id, STATUS_FLASH);
		}
	}
}

// handle when player id holsters a grenade with weapon id wid
grenade_holstered(id, wid)
{	
	// if we should worry about managing my icon now
	if(get_pcvar_num(pcv_enabled) && is_user_alive(id) && get_pcvar_num(pcv_icon) == ICON_HASNADE)
	{
		// if I just holstered a frost grenade		
		if( wid == hasFrostNade[id]
			|| (get_pcvar_num(pcv_override) && (get_pcvar_num(pcv_teams) & _:cs_get_user_team(id)) && is_wid_in_nadetypes(wid)) )
		{
			// only do STATUS_SHOW or STATUS_HIDE... during holster, current weapon
			// will still technically be the frost grenade, but we don't want to
			// mistakenly flash the icon				
			new status = (player_has_frostnade(id) != STATUS_HIDE ? STATUS_SHOW : STATUS_HIDE);
			show_icon(id, status);
		}
	}
}

// handle when player id gets a grenade with weapon id wid added to his inventory
grenade_added(id, wid)
{
	// if we should worry about managing my icon now
	if(get_pcvar_num(pcv_enabled) && is_user_alive(id) && get_pcvar_num(pcv_icon) == ICON_HASNADE)
	{
		// if I just got a frost grenade
		if( wid == hasFrostNade[id]
			|| (get_pcvar_num(pcv_override) && (get_pcvar_num(pcv_teams) & _:cs_get_user_team(id)) && is_wid_in_nadetypes(wid)) )
		{
			new status = player_has_frostnade(id);
			show_icon(id, status);
		}
	}
}

// a frost grenade explodes
public frostnade_explode(ent)
{
	new nadeTeam = pev(ent,pev_team), owner = pev(ent,pev_owner), Float:nadeOrigin[3];
	pev(ent,pev_origin,nadeOrigin);
	
	// make the smoke
	message_begin_fl(MSG_PVS,SVC_TEMPENTITY,nadeOrigin,0);
	write_byte(TE_SMOKE);
	write_coord_fl(nadeOrigin[0]); // x
	write_coord_fl(nadeOrigin[1]); // y
	write_coord_fl(nadeOrigin[2]); // z
	write_short(smokeSpr); // sprite
	write_byte(random_num(30,40)); // scale
	write_byte(5); // framerate
	message_end();
	
	// explosion
	create_blast(nadeTeam,nadeOrigin);
	emit_sound(ent,CHAN_ITEM,SOUND_EXPLODE,VOL_NORM,ATTN_NORM,0,PITCH_HIGH);

	// cache our cvars
	new ff = get_pcvar_num(mp_friendlyfire), Float:by_radius = get_pcvar_float(pcv_by_radius),
			hitself = get_pcvar_num(pcv_hitself), los = get_pcvar_num(pcv_los), Float:maxdamage = get_pcvar_float(pcv_maxdamage),
			Float:mindamage = get_pcvar_float(pcv_mindamage), Float:chill_maxchance = get_pcvar_float(pcv_chill_maxchance),
			Float:chill_minchance = get_pcvar_float(pcv_chill_minchance), Float:freeze_maxchance, Float:freeze_minchance;

	if(!by_radius)
	{
		freeze_maxchance = get_pcvar_float(pcv_freeze_maxchance);
		freeze_minchance = get_pcvar_float(pcv_freeze_minchance);
	}

	new ta, Float:targetOrigin[3], Float:distance, tr = create_tr2(), Float:fraction, Float:damage, gotFrozen = 0;
	for(new target=1;target<=maxPlayers;target++)
	{
		// dead, invincible, or self attack that is not allowed
		if(!is_user_alive(target) || pev(target,pev_takedamage) == DAMAGE_NO
		|| (pev(target,pev_flags) & FL_GODMODE) ||(target == owner && !hitself))
			continue;
		
		// this is a team attack with ff disabled, excluding self attack
		ta = (_:cs_get_user_team(target) == nadeTeam);
		if(ta && !ff && target != owner) continue;
		
		pev(target,pev_origin,targetOrigin);
		distance = vector_distance(nadeOrigin,targetOrigin);
		
		// too far
		if(distance > FROST_RADIUS) continue;

		// check line of sight
		if(los)
		{
			nadeOrigin[2] += 2.0;
			engfunc(EngFunc_TraceLine,nadeOrigin,targetOrigin,DONT_IGNORE_MONSTERS,ent,tr);
			nadeOrigin[2] -= 2.0;

			get_tr2(tr,TR_flFraction,fraction);
			if(fraction != 1.0 && get_tr2(tr,TR_pHit) != target) continue;
		}

		// damaged
		if(maxdamage > 0.0)
		{
			damage = radius_calc(distance,FROST_RADIUS,maxdamage,mindamage);
			if(ta) damage /= 2.0; // half damage for friendlyfire

			if(damage > 0.0)
			{
				frostKilled[target] = 1;
				ExecuteHamB(Ham_TakeDamage,target,ent,owner,damage,DMG_GRENADE);
				if(!is_user_alive(target)) continue; // dead now
				frostKilled[target] = 0;
			}
		}

		// frozen
		if((by_radius && radius_calc(distance,FROST_RADIUS,100.0,0.0) >= by_radius)
		|| (!by_radius && random_num(1,100) <= floatround(radius_calc(distance,FROST_RADIUS,freeze_maxchance,freeze_minchance))))
		{
			if(freeze_player(target,owner,nadeTeam))
			{
				gotFrozen = 1;
				emit_sound(target,CHAN_ITEM,SOUND_FROZEN,1.0,ATTN_NONE,0,PITCH_LOW);
			}
		}
		
		// chilled
		if(by_radius || random_num(1,100) <= floatround(radius_calc(distance,FROST_RADIUS,chill_maxchance,chill_minchance)))
		{
			if(chill_player(target,owner,nadeTeam))
			{
				if(!gotFrozen) emit_sound(target,CHAN_ITEM,SOUND_CHILLED,VOL_NORM,ATTN_NORM,0,PITCH_HIGH);
			}
		}
	}

	free_tr2(tr);
	set_pev(ent,pev_flags,pev(ent,pev_flags)|FL_KILLME);
}

freeze_player(id,attacker,nadeTeam)
{
	new fwdRetVal = PLUGIN_CONTINUE;
	ExecuteForward(fnFwdPlayerFrozen, fwdRetVal, id, attacker);
	
	if(fwdRetVal == PLUGIN_HANDLED || fwdRetVal == PLUGIN_HANDLED_MAIN)
	{
		return 0;
	}

	if(!isFrozen[id])
	{
		pev(id,pev_gravity,oldGravity[id]);

		// register our forward only when we need it
		if(!fmFwdPPT)
		{
			fmFwdPPT = register_forward(FM_PlayerPreThink,"fw_playerprethink",0);
		}
	}

	isFrozen[id] = nadeTeam;
	
	set_pev(id,pev_velocity,Float:{0.0,0.0,0.0});
	set_user_chillfreeze_speed(id);
	
	new Float:duration = get_pcvar_float(pcv_freeze_duration), Float:variance = get_pcvar_float(pcv_freeze_variance);
	duration += random_float(-variance,variance);

	remove_task(TASK_REMOVE_FREEZE+id);
	set_task(duration,"task_remove_freeze",TASK_REMOVE_FREEZE+id);
	
	if(!pev_valid(novaDisplay[id])) create_nova(id);
	
	if(get_pcvar_num(pcv_icon) == ICON_ISCHILLED)
	{
		show_icon(id, STATUS_FLASH);
	}
	
	return 1;
}

public task_remove_freeze(taskid)
{
	new id = taskid-TASK_REMOVE_FREEZE;
	
	if(pev_valid(novaDisplay[id]))
	{
		new Float:origin[3];
		pev(novaDisplay[id],pev_origin,origin);

		// add some tracers
		message_begin_fl(MSG_PVS,SVC_TEMPENTITY,origin,0);
		write_byte(TE_IMPLOSION);
		write_coord_fl(origin[0]); // x
		write_coord_fl(origin[1]); // y
		write_coord_fl(origin[2] + 8.0); // z
		write_byte(64); // radius
		write_byte(10); // count
		write_byte(3); // duration
		message_end();

		// add some sparks
		message_begin_fl(MSG_PVS,SVC_TEMPENTITY,origin,0);
		write_byte(TE_SPARKS);
		write_coord_fl(origin[0]); // x
		write_coord_fl(origin[1]); // y
		write_coord_fl(origin[2]); // z
		message_end();

		// add the shatter
		message_begin_fl(MSG_PAS,SVC_TEMPENTITY,origin,0);
		write_byte(TE_BREAKMODEL);
		write_coord_fl(origin[0]); // x
		write_coord_fl(origin[1]); // y
		write_coord_fl(origin[2] + 24.0); // z
		write_coord_fl(16.0); // size x
		write_coord_fl(16.0); // size y
		write_coord_fl(16.0); // size z
		write_coord(random_num(-50,50)); // velocity x
		write_coord(random_num(-50,50)); // velocity y
		write_coord_fl(25.0); // velocity z
		write_byte(10); // random velocity
		write_short(glassGibs); // model
		write_byte(10); // count
		write_byte(25); // life
		write_byte(BREAK_GLASS); // flags
		message_end();

		emit_sound(novaDisplay[id],CHAN_ITEM,SOUND_UNFROZEN,VOL_NORM,ATTN_NORM,0,PITCH_LOW);
		set_pev(novaDisplay[id],pev_flags,pev(novaDisplay[id],pev_flags)|FL_KILLME);
	}

	isFrozen[id] = 0;
	novaDisplay[id] = 0;
	
	// unregister forward if we are no longer using it
	unregister_prethink();

	if(!is_user_connected(id)) return;
	
	// restore speed, but then check for chilled
	ExecuteHam(Ham_Player_ResetMaxSpeed, id);
	set_user_chillfreeze_speed(id);

	set_pev(id,pev_gravity,oldGravity[id]);
	
	new status = STATUS_HIDE;
	
	// sometimes trail fades during freeze, reapply
	if(isChilled[id])
	{
		status = STATUS_SHOW;
		
		new rgb[3];
		get_rgb_colors(isChilled[id],rgb);
		set_beamfollow(id,30,8,rgb,100);
	}
	
	if(get_pcvar_num(pcv_icon) == ICON_ISCHILLED)
	{
		show_icon(id, status);
	}
}

chill_player(id,attacker,nadeTeam)
{
	new fwdRetVal = PLUGIN_CONTINUE;
	ExecuteForward(fnFwdPlayerChilled, fwdRetVal, id, attacker);
	
	if(fwdRetVal == PLUGIN_HANDLED || fwdRetVal == PLUGIN_HANDLED_MAIN)
	{
		return 0;
	}

	// we aren't already been chilled
	if(!isChilled[id])
	{
		oldRenderFx[id] = pev(id,pev_renderfx);
		pev(id,pev_rendercolor,oldRenderColor[id]);
		oldRenderMode[id] = pev(id,pev_rendermode);
		pev(id,pev_renderamt,oldRenderAmt[id]);

		isChilled[id] = nadeTeam; // fix -- thanks Exolent

		// register our forward only when we need it
		//if(!fmFwdPPT) fmFwdPPT = register_forward(FM_PlayerPreThink,"fw_playerprethink",0);
	}

	isChilled[id] = nadeTeam;
	
	set_user_chillfreeze_speed(id);
	
	new Float:duration = get_pcvar_float(pcv_chill_duration), Float:variance = get_pcvar_float(pcv_chill_variance);
	duration += random_float(-variance,variance);

	remove_task(TASK_REMOVE_CHILL+id);
	set_task(duration,"task_remove_chill",TASK_REMOVE_CHILL+id);

	new rgb[3];
	get_rgb_colors(nadeTeam,rgb);
	
	IVecFVec(rgb, glowColor[id]);
	
	// glowshell
	set_user_rendering(id, kRenderFxGlowShell, rgb[0], rgb[1], rgb[2], kRenderNormal, floatround(GLOW_AMOUNT));

	set_beamfollow(id,30,8,rgb,100);

	// I decided to let the frostnade tint override a flashbang,
	// because if you are frozen, then you have much bigger problems.

	// add a blue tint to their screen
	message_begin(MSG_ONE,gmsgScreenFade,_,id);
	write_short(floatround(4096.0 * duration)); // duration
	write_short(floatround(3072.0 * duration)); // hold time (4096.0 * 0.75)
	write_short(FFADE_IN); // flags
	write_byte(rgb[0]); // red
	write_byte(rgb[1]); // green
	write_byte(rgb[2]); // blue
	write_byte(100); // alpha
	message_end();
	
	if(get_pcvar_num(pcv_icon) == ICON_ISCHILLED && !isFrozen[id])
	{
		show_icon(id, STATUS_SHOW);
	}
	
	return 1;
}

public task_remove_chill(taskid)
{
	new id = taskid-TASK_REMOVE_CHILL;

	isChilled[id] = 0;
	
	// unregister forward if we are no longer using it
	//unregister_prethink();

	if(!is_user_connected(id)) return;
	
	// set speed to normal, then check for frozen
	ExecuteHam(Ham_Player_ResetMaxSpeed, id);
	set_user_chillfreeze_speed(id);

	// reset rendering
	set_user_rendering(id, oldRenderFx[id], floatround(oldRenderColor[id][0]), floatround(oldRenderColor[id][1]),
		floatround(oldRenderColor[id][2]), oldRenderMode[id], floatround(oldRenderAmt[id]));

	clear_beamfollow(id);

	// calculate end of flashbang
	new Float:flashedUntil = get_pdata_float(id,m_flFlashedUntil),
			Float:flashHoldTime = get_pdata_float(id,m_flFlashHoldTime),
			Float:endOfFlash = flashedUntil + (flashHoldTime * 0.67);
	
	// not blinded
	if(get_gametime() >= endOfFlash)
	{
		// clear tint
		message_begin(MSG_ONE,gmsgScreenFade,_,id);
		write_short(0); // duration
		write_short(0); // hold time
		write_short(FFADE_IN); // flags
		write_byte(0); // red
		write_byte(0); // green
		write_byte(0); // blue
		write_byte(255); // alpha
		message_end();
	}
	
	if(get_pcvar_num(pcv_icon) == ICON_ISCHILLED && !isFrozen[id])
	{
		show_icon(id, STATUS_HIDE);
	}
}

// make a frost nova at a player's feet
create_nova(id)
{
	new nova = engfunc(EngFunc_CreateNamedEntity,engfunc(EngFunc_AllocString,"info_target"));

	engfunc(EngFunc_SetSize,nova,Float:{-8.0,-8.0,-4.0},Float:{8.0,8.0,4.0});
	engfunc(EngFunc_SetModel,nova,MODEL_FROZEN);

	// random orientation
	new Float:angles[3];
	angles[1] = random_float(0.0,360.0);
	set_pev(nova,pev_angles,angles);

	// put it at their feet
	new Float:novaOrigin[3];
	pev(id,pev_origin,novaOrigin);
	engfunc(EngFunc_SetOrigin,nova,novaOrigin);

	// make it translucent
	new rgb[3];
	get_rgb_colors(isFrozen[id], rgb);
	IVecFVec(rgb, angles); // let's just use angles

	set_pev(nova,pev_rendercolor,angles); // see above
	set_pev(nova,pev_rendermode,kRenderTransAlpha);
	set_pev(nova,pev_renderfx,kRenderFxGlowShell);
	set_pev(nova,pev_renderamt,128.0);

	novaDisplay[id] = nova;
}

/****************************************
* UTILITY FUNCTIONS
****************************************/

// check if prethink is still being used, if not, unhook it
unregister_prethink()
{
	if(fmFwdPPT)
	{
		new i;
		for(i=1;i<=maxPlayers;i++) if(/*isChilled[i] ||*/ isFrozen[i]) break;
		if(i > maxPlayers)
		{
			unregister_forward(FM_PlayerPreThink,fmFwdPPT,0);
			fmFwdPPT = 0;
		}
	}
}

// make the explosion effects
create_blast(team,Float:origin[3])
{
	new rgb[3];
	get_rgb_colors(team,rgb);

	// smallest ring
	message_begin_fl(MSG_PVS,SVC_TEMPENTITY,origin,0);
	write_byte(TE_BEAMCYLINDER);
	write_coord_fl(origin[0]); // x
	write_coord_fl(origin[1]); // y
	write_coord_fl(origin[2]); // z
	write_coord_fl(origin[0]); // x axis
	write_coord_fl(origin[1]); // y axis
	write_coord_fl(origin[2] + 385.0); // z axis
	write_short(exploSpr); // sprite
	write_byte(0); // start frame
	write_byte(0); // framerate
	write_byte(4); // life
	write_byte(60); // width
	write_byte(0); // noise
	write_byte(rgb[0]); // red
	write_byte(rgb[1]); // green
	write_byte(rgb[2]); // blue
	write_byte(100); // brightness
	write_byte(0); // speed
	message_end();

	// medium ring
	message_begin_fl(MSG_PVS,SVC_TEMPENTITY,origin,0);
	write_byte(TE_BEAMCYLINDER);
	write_coord_fl(origin[0]); // x
	write_coord_fl(origin[1]); // y
	write_coord_fl(origin[2]); // z
	write_coord_fl(origin[0]); // x axis
	write_coord_fl(origin[1]); // y axis
	write_coord_fl(origin[2] + 470.0); // z axis
	write_short(exploSpr); // sprite
	write_byte(0); // start frame
	write_byte(0); // framerate
	write_byte(4); // life
	write_byte(60); // width
	write_byte(0); // noise
	write_byte(rgb[0]); // red
	write_byte(rgb[1]); // green
	write_byte(rgb[2]); // blue
	write_byte(100); // brightness
	write_byte(0); // speed
	message_end();

	// largest ring
	message_begin_fl(MSG_PVS,SVC_TEMPENTITY,origin,0);
	write_byte(TE_BEAMCYLINDER);
	write_coord_fl(origin[0]); // x
	write_coord_fl(origin[1]); // y
	write_coord_fl(origin[2]); // z
	write_coord_fl(origin[0]); // x axis
	write_coord_fl(origin[1]); // y axis
	write_coord_fl(origin[2] + 555.0); // z axis
	write_short(exploSpr); // sprite
	write_byte(0); // start frame
	write_byte(0); // framerate
	write_byte(4); // life
	write_byte(60); // width
	write_byte(0); // noise
	write_byte(rgb[0]); // red
	write_byte(rgb[1]); // green
	write_byte(rgb[2]); // blue
	write_byte(100); // brightness
	write_byte(0); // speed
	message_end();

	// light effect
	message_begin_fl(MSG_PAS,SVC_TEMPENTITY,origin,0);
	write_byte(TE_DLIGHT);
	write_coord_fl(origin[0]); // x
	write_coord_fl(origin[1]); // y
	write_coord_fl(origin[2]); // z
	write_byte(floatround(FROST_RADIUS/5.0)); // radius
	write_byte(rgb[0]); // r
	write_byte(rgb[1]); // g
	write_byte(rgb[2]); // b
	write_byte(8); // life
	write_byte(60); // decay rate
	message_end();
}

// give an entity a beam trail
set_beamfollow(ent,life,width,rgb[3],brightness)
{
	clear_beamfollow(ent);

	message_begin(MSG_BROADCAST,SVC_TEMPENTITY);
	write_byte(TE_BEAMFOLLOW);
	write_short(ent); // entity
	write_short(trailSpr); // sprite
	write_byte(life); // life
	write_byte(width); // width
	write_byte(rgb[0]); // red
	write_byte(rgb[1]); // green
	write_byte(rgb[2]); // blue
	write_byte(brightness); // brightness
	message_end();
}

// removes beam trails from an entity
clear_beamfollow(ent)
{
	message_begin(MSG_BROADCAST,SVC_TEMPENTITY);
	write_byte(TE_KILLBEAM);
	write_short(ent); // entity
	message_end();
}

// gets the appropriate color and displays the frostnade icon to the player with the given status
show_icon(id, status)
{
	static rgb[3];
	if(status) get_rgb_colors(_:cs_get_user_team(id), rgb); // only get colors if we need to
	
	message_begin(MSG_ONE,gmsgStatusIcon,_,id);
	write_byte(status); // status (0=hide, 1=show, 2=flash)
	write_string("dmg_cold"); // sprite name
	write_byte(rgb[0]); // red
	write_byte(rgb[1]); // green
	write_byte(rgb[2]); // blue
	message_end();
}

// checks if a weapon id is included in fn_nadetypes
is_wid_in_nadetypes(wid)
{
	new types = get_pcvar_num(pcv_nadetypes);
	
	return ( (wid == CSW_HEGRENADE && (types & NT_HEGRENADE))
		|| (wid == CSW_FLASHBANG && (types & NT_FLASHBANG))
		|| (wid == CSW_SMOKEGRENADE && (types & NT_SMOKEGRENADE)) );
}

// checks if a player has a frostnade, taking into account fn_override and such.
// returns: STATUS_HIDE = no frostnade, STATUS_SHOW = has frostnade but not deployed, STATUS_FLASH = has frostnade and deployed
player_has_frostnade(id)
{
	new retVal = STATUS_HIDE, curwpn = get_user_weapon(id);
	
	// no override, variable explicitly set
	if(hasFrostNade[id])
	{
		retVal = (curwpn == hasFrostNade[id] ? STATUS_FLASH : STATUS_SHOW);
	}
	
	// override enabled, and I'm on the right team
	else if(get_pcvar_num(pcv_override) && (get_pcvar_num(pcv_teams) & _:cs_get_user_team(id)))
	{		
		new types = get_pcvar_num(pcv_nadetypes);
					
		if((types & NT_HEGRENADE) && cs_get_user_bpammo(id, CSW_HEGRENADE) > 0)
		{
			retVal = (curwpn == CSW_HEGRENADE ? STATUS_FLASH : STATUS_SHOW);
		}
		
		if(retVal != STATUS_FLASH && (types & NT_FLASHBANG) && cs_get_user_bpammo(id, CSW_FLASHBANG) > 0)
		{
			retVal = (curwpn == CSW_FLASHBANG ? STATUS_FLASH : STATUS_SHOW);
		}
		
		if(retVal != STATUS_FLASH && (types & NT_SMOKEGRENADE) && cs_get_user_bpammo(id, NT_SMOKEGRENADE) > 0)
		{
			retVal = (curwpn == NT_SMOKEGRENADE ? STATUS_FLASH : STATUS_SHOW);
		}
	}
	
	return retVal;
}

// gets RGB colors from the cvar
get_rgb_colors(team,rgb[3])
{
	static color[12], parts[3][4];
	get_pcvar_string(pcv_color,color,11);
	
	// if cvar is set to "team", use colors based on the given team
	if(equali(color,"team",4))
	{
		if(team == 1)
		{
			rgb[0] = 150;
			rgb[1] = 0;
			rgb[2] = 0;
		}
		else
		{
			rgb[0] = 0;
			rgb[1] = 0;
			rgb[2] = 150;
		}
	}
	else
	{
		parse(color,parts[0],3,parts[1],3,parts[2],3);
		rgb[0] = str_to_num(parts[0]);
		rgb[1] = str_to_num(parts[1]);
		rgb[2] = str_to_num(parts[2]);
	}
}

// scale a value equally (inversely?) with the distance that something
// is from the center of another thing. that makes pretty much no sense,
// so basically, the closer we are to the center of a ring, the higher
// our value gets.
//
// EXAMPLE: distance = 60.0, radius = 240.0, maxVal = 100.0, minVal = 20.0
// we are 0.75 (1.0-(60.0/240.0)) of the way to the radius, so scaled with our
// values, it comes out to 80.0 (20.0 + (0.75 * (100.0 - 20.0)))
Float:radius_calc(Float:distance,Float:radius,Float:maxVal,Float:minVal)
{
	if(maxVal <= 0.0) return 0.0;
	if(minVal >= maxVal) return minVal;
	return minVal + ((1.0 - (distance / radius)) * (maxVal - minVal));
}

// sets a user's chilled/frozen speed if applicable
// (NOTE: does NOT reset his maxspeed if he is not chilled/frozen)
set_user_chillfreeze_speed(id)
{
	if(isFrozen[id])
	{
		set_user_maxspeed(id, 1.0);
	}
	else if(isChilled[id])
	{
		set_user_maxspeed(id, get_default_maxspeed(id)*(get_pcvar_float(pcv_chill_speed)/100.0));
	}
}

// gets the maxspeed a user should have, given his current weapon
stock Float:get_default_maxspeed(id)
{	
	new wEnt = get_pdata_cbase(id, m_pActiveItem), Float:result = 250.0;

	if(pev_valid(wEnt))
	{
		ExecuteHam(Ham_CS_Item_GetMaxSpeed, wEnt, result);
	}
	
	return result;
}
