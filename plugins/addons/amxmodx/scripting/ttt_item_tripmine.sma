#include <amxmodx>
#include <fakemeta>
#include <engine>
#include <hamsandwich>
#include <xs>
#include <ttt>

#define LASERMINE_OWNER   pev_iuser2
#define LASERMINE_STEP    pev_iuser3
#define LASERMINE_HITING  pev_iuser4

#define LASERMINE_COUNT   pev_fuser1
#define LASERMINE_POWERUP pev_fuser2
#define LASERMINE_BEAMTHINK pev_fuser3

#define LASERMINE_BEAMENDPOINT  pev_vuser1

enum _:TaskData
{
	myplaceholder,
	Float:mytime
}

enum tripmine_e
{
	TRIPMINE_IDLE1 = 0,
	TRIPMINE_IDLE2,
	TRIPMINE_ARM1,
	TRIPMINE_ARM2,
	TRIPMINE_FIDGET,
	TRIPMINE_HOLSTER,
	TRIPMINE_DRAW,
	TRIPMINE_WORLD,
	TRIPMINE_GROUND,
};

enum
{
	THINK_POWERUP,
	THINK_BEAMBREAK
};

enum
{
	SOUND_POWERUP,
	SOUND_ACTIVATE,
	SOUND_STOP,
	SOUND_BEAM,
	SOUND_EXPLODE
};

new const
	ENT_MODELS[]  = "models/v_tripmine.mdl",
	ENT_SOUND1[]  = "weapons/mine_deploy.wav",
	ENT_SOUND2[]  = "weapons/mine_charge.wav",
	ENT_SOUND3[]  = "weapons/mine_activate.wav",
	ENT_SOUND4[]  = "ttt/tinnitus.wav",
	ENT_SOUND5[]	= "debris/bustglass1.wav",
	ENT_SOUND6[]	= "debris/bustglass2.wav",
	ENT_SOUND7[]	= "weapons/explode3.wav",
	ENT_SPRITE1[]   = "sprites/laserbeam.spr";

new const ENT_CLASS_NAME[]  = "ttt_tripmine";

new g_pBeamSprite;
new g_iSettingLaser[33], g_iWasSetting[33], g_iHasMine[33], g_iBlockPlayer[33];
new cvar_price, cvar_radius, cvar_damage, cvar_inflict, cvar_visible;
new g_pMsgSetFOV, g_pMsgScreenShake, g_pMsgScreenFade;
new Float:g_fPlayerSpeed[33];
new g_iItemID, g_iItem_Backpack[33], g_iHitWithLaser[33];

new const g_szBlockZoom[][] =
{
	"weapon_aug",
	"weapon_awp",
	"weapon_g3sg1",
	"weapon_scout",
	"weapon_sg550",
	"weapon_sg552"
};

public plugin_init()
{
	// Full credit to creator of lasermines SandStriker/+ARUKARI-
	register_plugin("[TTT] Item: Tripmine", TTT_VERSION, TTT_AUTHOR);

	cvar_inflict	= my_register_cvar("ttt_tripmine_inflict",	"0",		"Tripmine should inflict damage? (Default: 0)");
	cvar_damage		= my_register_cvar("ttt_tripmine_damage",	"300.0",	"Tripmine explosion damage. (Default: 300.0)");
	cvar_radius		= my_register_cvar("ttt_tripmine_radius",	"420.0",	"Tripmine explosion radius. (Default: 420.0)");
	cvar_visible	= my_register_cvar("ttt_tripmine_visible",	"1",		"Tripmine laser should be visible? 0-disabled, 1-traitor only, 2-all (Default: 1)");
	cvar_price		= my_register_cvar("ttt_price_tripmine",	"1",		"Tripmine price. (Default: 1)");

	register_event("CurWeapon", "Event_CurWeapon", "be", "1=1");

	register_forward(FM_Think, "Forward_Think_pre", 0);
	register_forward(FM_PlayerPostThink, "Forward_PlayerPostThink_pre", 0);

	RegisterHamPlayer(Ham_Killed, "Ham_Killed_pre", 0);
	for(new i = 0; i < sizeof(g_szBlockZoom); i++)
		RegisterHam(Ham_Weapon_SecondaryAttack, g_szBlockZoom[i], "Ham_SecondaryAttack_pre", 0);

	g_pMsgSetFOV		= get_user_msgid("SetFOV");
	g_pMsgScreenShake	= get_user_msgid("ScreenShake");
	g_pMsgScreenFade	= get_user_msgid("ScreenFade");
}

public ttt_plugin_cfg()
{
	new name[TTT_ITEMLENGHT];
	formatex(name, charsmax(name), "%L", LANG_PLAYER, "TTT_ITEM_TRIPMINE");
	g_iItemID = ttt_buymenu_add(name, get_pcvar_num(cvar_price), PC_TRAITOR);
}

public plugin_precache() 
{
	precache_sound(ENT_SOUND1);
	precache_sound(ENT_SOUND2);
	precache_sound(ENT_SOUND3);
	precache_sound(ENT_SOUND4);
	precache_sound(ENT_SOUND5);
	precache_sound(ENT_SOUND6);
	precache_sound(ENT_SOUND7);
	precache_model(ENT_MODELS);
	g_pBeamSprite = precache_model(ENT_SPRITE1);
	
	return PLUGIN_CONTINUE;
}

public client_putinserver(id)
{
	remove_player_task(id);
	return PLUGIN_CONTINUE;
}

public client_disconnect(id)
{
	remove_player_task(id);
	remove_player_mines(id);
	return PLUGIN_CONTINUE;
}

public ttt_gamemode(mode)
{
	if(mode == GAME_PREPARING || mode == GAME_RESTARTING)
	{
		new num, id;
		static players[32];
		get_players(players, num);

		for(--num; num >= 0; num--)
		{
			id = players[num];
			remove_player_task(id);
			remove_player_mines(id);
			g_iSettingLaser[id] = 0;
			g_iWasSetting[id] = 0;
			g_iHasMine[id] = 0;
			g_iHitWithLaser[id] = 0;
			g_iItem_Backpack[id] = -1;
		}
	}
}

public ttt_item_selected(id, item, name[], price)
{
	if(g_iItemID == item)
	{
		g_iHasMine[id] = true;
		g_iItem_Backpack[id] = ttt_backpack_add(id, name);
		client_print_color(id, print_team_default, "%s %L", TTT_TAG, id, "TTT_ITEM2", name, id, "TTT_ITEM_BACKPACK", name);
		return PLUGIN_HANDLED;
	}

	return PLUGIN_CONTINUE;
}

public ttt_item_backpack(id, item)
{
	if(g_iHasMine[id] && g_iItem_Backpack[id] == item)
	{
		if(!g_iSettingLaser[id])
			mine_start(id);
	}

	return PLUGIN_CONTINUE;
}

public Event_CurWeapon(id) 
{
	if(!g_iSettingLaser[id])
		return PLUGIN_CONTINUE;

	set_pev(id, pev_maxspeed, 1.0);
	return PLUGIN_CONTINUE;
}

public Forward_Think_pre(ent)
{
	if(!pev_valid(ent))
		return FMRES_IGNORED;

	new classname[32];
	pev(ent, pev_classname, classname, charsmax(classname));

	if(!equal(classname, ENT_CLASS_NAME))
		return FMRES_IGNORED;

	static Float:time;
	time = get_gametime();

	switch(pev(ent, LASERMINE_STEP))
	{
		case THINK_POWERUP:
		{
			new Float:powertime;
			pev(ent, LASERMINE_POWERUP, powertime);

			if(time > powertime)
			{
				set_pev(ent, pev_solid, SOLID_TRIGGER);
				set_pev(ent, LASERMINE_STEP, THINK_BEAMBREAK);

				mine_sound(ent, SOUND_ACTIVATE);
			}

			set_pev(ent, pev_nextthink, time + 0.1);
		}
		case THINK_BEAMBREAK:
		{
			static Float:vEnd[3],Float:vOrigin[3];
			pev(ent, pev_origin, vOrigin);
			pev(ent, LASERMINE_BEAMENDPOINT, vEnd);

			static id, Float:fFraction;
			engfunc(EngFunc_TraceLine, vOrigin, vEnd, DONT_IGNORE_MONSTERS, ent, 0);

			get_tr2(0, TR_flFraction, fFraction);
			id = get_tr2(0, TR_pHit);

			if(fFraction < 1.0 && is_user_alive(id))
			{
				set_pev(ent, pev_enemy, id);
				player_touch_laser(ent, id);
			}
 
			if(pev_valid(ent))
			{
				static Float:fHealth;
				pev(ent, pev_health, fHealth);

				static Float:fBeamthink;
				pev(ent, LASERMINE_BEAMTHINK, fBeamthink);
										
				if(fBeamthink < time)
				{
					mine_laser(vOrigin, vEnd);
					set_pev(ent, LASERMINE_BEAMTHINK, time + 0.1);
				}
				set_pev(ent, pev_nextthink, time + 0.01);
			}
		}
	}

	return FMRES_IGNORED;
}

public Forward_PlayerPostThink_pre(id) 
{
	if(!g_iSettingLaser[id] && g_iWasSetting[id])
		set_pev(id, pev_maxspeed, g_fPlayerSpeed[id]);
	else if(g_iSettingLaser[id] && !g_iWasSetting[id])
	{
		pev(id, pev_maxspeed, g_fPlayerSpeed[id]);
		set_pev(id, pev_maxspeed, 1.0);
	}

	g_iWasSetting[id] = g_iSettingLaser[id];
	return FMRES_IGNORED;
}

public Ham_Killed_pre(victim)
{
	remove_player_task(victim);
	g_iHasMine[victim] = false;
	g_iHitWithLaser[victim] = false;
}

public mine_start(id)
{
	if(!mine_check(id))
		return PLUGIN_HANDLED;
	g_iSettingLaser[id] = true;

	message_begin(MSG_ONE_UNRELIABLE, 108, _, id);
	write_byte(1);
	write_byte(0);
	message_end();
	set_task(1.2, "mine_spawn", id);

	return PLUGIN_HANDLED;
}

public mine_spawn(id)
{
	if(!mine_check(id))
		return PLUGIN_HANDLED_MAIN;

	new ent = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "info_target"));
	if(!ent)
		return PLUGIN_HANDLED_MAIN;

	set_pev(ent, pev_classname, ENT_CLASS_NAME);
	
	engfunc(EngFunc_SetModel, ent, ENT_MODELS);
	
	set_pev(ent, pev_solid, SOLID_NOT);
	set_pev(ent, pev_movetype, MOVETYPE_FLY);
	
	set_pev(ent, pev_frame, 0);
	set_pev(ent, pev_body, 3);
	set_pev(ent, pev_sequence, TRIPMINE_WORLD);
	set_pev(ent, pev_framerate, 0);
	
	new Float:vOrigin[3];
	new Float:vNewOrigin[3],Float:vNormal[3],Float:vTraceDirection[3],
		Float:vTraceEnd[3],Float:vEntAngles[3];
	pev(id, pev_origin, vOrigin);
	velocity_by_aim(id, 128, vTraceDirection);
	xs_vec_add(vTraceDirection, vOrigin, vTraceEnd);
	
	engfunc(EngFunc_TraceLine, vOrigin, vTraceEnd, DONT_IGNORE_MONSTERS, id, 0);
	new Float:fFraction;
	get_tr2(0, TR_flFraction, fFraction);
	
	if(fFraction < 1.0)
	{
		get_tr2(0, TR_vecEndPos, vTraceEnd);
		get_tr2(0, TR_vecPlaneNormal, vNormal);
	}

	xs_vec_mul_scalar(vNormal, 8.0, vNormal);
	xs_vec_add(vTraceEnd, vNormal, vNewOrigin);
	
	engfunc(EngFunc_SetSize, ent, Float:{-4.0, -4.0, -4.0}, Float:{4.0, 4.0, 4.0});
	engfunc(EngFunc_SetOrigin, ent, vNewOrigin);
	
	vector_to_angle(vNormal, vEntAngles);
	set_pev(ent, pev_angles, vEntAngles);
	
	// -- Calculate laser end origin.
	new Float:vBeamEnd[3], Float:vTracedBeamEnd[3];
	xs_vec_mul_scalar(vNormal, 8192.0, vNormal);
	xs_vec_add(vNewOrigin, vNormal, vBeamEnd);
	
	engfunc(EngFunc_TraceLine, vNewOrigin, vBeamEnd, IGNORE_MONSTERS, -1, 0);
	
	get_tr2(0, TR_vecPlaneNormal, vNormal);
	get_tr2(0, TR_vecEndPos, vTracedBeamEnd);
	
	// -- Save results to be used later.
	set_pev(ent, LASERMINE_OWNER, id);
	set_pev(ent, LASERMINE_BEAMENDPOINT, vTracedBeamEnd);
	new Float:time = get_gametime();
	
	set_pev(ent, LASERMINE_POWERUP, time + 2.5);
	set_pev(ent, LASERMINE_STEP, THINK_POWERUP);
	set_pev(ent, pev_nextthink, time + 0.2);
	
	mine_sound(ent, SOUND_POWERUP);
	remove_player_task(id);
	g_iHasMine[id] = false;
	ttt_backpack_remove(id, g_iItem_Backpack[id]);
	return 1;
}

public mine_check(id)
{
	new Float:vTraceDirection[3], Float:vTraceEnd[3],Float:vOrigin[3];
	
	pev(id, pev_origin, vOrigin);
	velocity_by_aim(id, 128, vTraceDirection);
	xs_vec_add(vTraceDirection, vOrigin, vTraceEnd);
	
	engfunc(EngFunc_TraceLine, vOrigin, vTraceEnd, DONT_IGNORE_MONSTERS, id, 0);
	new Float:fFraction,Float:vTraceNormal[3];
	get_tr2(0, TR_flFraction, fFraction);
	if(fFraction < 1.0)
	{
		get_tr2(0, TR_vecEndPos, vTraceEnd);
		get_tr2(0, TR_vecPlaneNormal, vTraceNormal);

		return true;
	}

	remove_player_task(id);
	return false;
}

player_touch_laser(mine, id)
{
	if(id < 0)
		return PLUGIN_CONTINUE;

	if(pev(mine, LASERMINE_HITING) == id)
	{		
		static Float:cnt;
		static now, htime; now = floatround(get_gametime());

		pev(mine, LASERMINE_COUNT, cnt);
		htime = floatround(cnt);
		if(now - htime < 1)
			return PLUGIN_CONTINUE;
		else set_pev(mine, LASERMINE_COUNT, get_gametime());
	}
	else set_pev(mine, LASERMINE_COUNT, get_gametime());

	if(is_user_alive(id))
	{
		set_pev(mine, LASERMINE_HITING, id);
		CreateExplosion(id, mine);
		mine_sound(mine, SOUND_EXPLODE);
		engfunc(EngFunc_RemoveEntity, mine);
		clear_players(mine);
	}

	return PLUGIN_CONTINUE;
}

clear_players(ent)
{
	new num, id;
	static players[32];
	get_players(players, num);
	for(--num; num >= 0; num--)
	{
		id = players[num];
		if(g_iHitWithLaser[id] == ent)
			g_iHitWithLaser[id] = false;
	}
}

remove_player_mines(id)
{
	new ent = 33;
	while((ent = engfunc( EngFunc_FindEntityByString, ent, "classname", ENT_CLASS_NAME)))
	{
		if(id)
		{
			if(pev(ent, LASERMINE_OWNER) != id)
				continue;

			mine_sound(ent, SOUND_STOP);
			engfunc(EngFunc_RemoveEntity, ent);
			g_iHasMine[id] = false;
		}
		else set_pev(ent, pev_flags, FL_KILLME);
	}
}

remove_player_task(id)
{
	if(task_exists(id))
		remove_task(id);
	g_iSettingLaser[id] = false;
	return PLUGIN_CONTINUE;
}

stock mine_laser(const Float:v_Origin[3], const Float:v_EndOrigin[3])
{
	new cvar = get_pcvar_num(cvar_visible);
	if(cvar)
	{
		new num, id;
		static players[32];
		get_players(players, num);
		for(--num; num >= 0; num--)
		{
			id = players[num];
			if(cvar == 1 && ttt_get_playerstate(id) == PC_TRAITOR)
				beam_points(id, v_Origin, v_EndOrigin);
			else if(cvar == 2)
				beam_points(id, v_Origin, v_EndOrigin);
		}
	}
}

stock beam_points(id, const Float:v_Origin[3], const Float:v_EndOrigin[3])
{
	message_begin(MSG_ONE_UNRELIABLE, SVC_TEMPENTITY, _, id);
	write_byte(TE_BEAMPOINTS);
	engfunc(EngFunc_WriteCoord, v_Origin[0]);
	engfunc(EngFunc_WriteCoord, v_Origin[1]);
	engfunc(EngFunc_WriteCoord, v_Origin[2]);
	engfunc(EngFunc_WriteCoord, v_EndOrigin[0]); //Random
	engfunc(EngFunc_WriteCoord, v_EndOrigin[1]); //Random
	engfunc(EngFunc_WriteCoord, v_EndOrigin[2]); //Random
	write_short(g_pBeamSprite);
	write_byte(0);
	write_byte(0);
	write_byte(1);	//Life
	write_byte(5);	//Width
	write_byte(0);	//wave
	write_byte(g_iTeamColors[PC_TRAITOR][0]); // r
	write_byte(g_iTeamColors[PC_TRAITOR][1]); // g
	write_byte(g_iTeamColors[PC_TRAITOR][2]); // b
	write_byte(255);
	write_byte(255);
	message_end();
}

stock mine_sound(ent, sound)
{
	switch(sound)
	{
		case SOUND_POWERUP:
		{
			emit_sound(ent, CHAN_VOICE, ENT_SOUND1, 0.3, ATTN_NORM, SND_SPAWNING, PITCH_NORM);
			emit_sound(ent, CHAN_BODY , ENT_SOUND2, 0.3, ATTN_NORM, SND_SPAWNING, PITCH_NORM);
		}
		case SOUND_ACTIVATE: emit_sound(ent, CHAN_VOICE, ENT_SOUND3, 0.3, ATTN_NORM, SND_SPAWNING, PITCH_NORM);
		case SOUND_STOP:
		{
			emit_sound(ent, CHAN_BODY , ENT_SOUND2, 0.3, ATTN_NORM, SND_STOP, PITCH_NORM);
			emit_sound(ent, CHAN_VOICE, ENT_SOUND3, 0.3, ATTN_NORM, SND_STOP, PITCH_NORM);
		}
		case SOUND_BEAM: emit_sound(ent, CHAN_BODY, ENT_SOUND4, 0.3, ATTN_NORM, SND_SPAWNING, PITCH_NORM);
		case SOUND_EXPLODE: emit_sound(ent, CHAN_BODY, ENT_SOUND7, VOL_NORM, ATTN_NORM, SND_SPAWNING, PITCH_NORM);
	}
}

// DIZZY

public Ham_SecondaryAttack_pre(ent)
{
	if(pev_valid(ent))
	{
		if(g_iBlockPlayer[pev(ent, pev_owner)])
			return HAM_SUPERCEDE;
	}

	return HAM_IGNORED;
}

give_dizzy_effects(victim, Float:damage)
{
	if(is_user_alive(victim))
	{
		new Float:time = damage/4.0;
		static Float:angles[3];
		pev(victim, pev_angles, angles);

		angles[0] += random_float(damage, damage);
		angles[1] += random_float(damage, damage);
		set_pev(victim, pev_angles, angles);

		angles[2] += random_float(damage, damage);
		set_pev(victim, pev_punchangle, angles);
		set_pev(victim, pev_fixangle, 1);

		client_cmd(victim, "spk ^"%s^"", ENT_SOUND4);
		g_iBlockPlayer[victim] = true;
		message_begin(MSG_ONE_UNRELIABLE, g_pMsgSetFOV, _, victim);
		write_byte(180);
		message_end();

		new param[TaskData];
		param[mytime] = _:fabs((time/2.0) - 0.5);
		message_begin(MSG_ONE_UNRELIABLE, g_pMsgScreenFade, _, victim);
		write_short(FixedUnsigned16(param[mytime], 1<<12));
		write_short(0);
		write_short((SF_FADE_IN + SF_FADE_ONLYONE)); //flags (SF_FADE_IN + SF_FADE_ONLYONE) (SF_FADEOUT)
		write_byte(255);
		write_byte(0);
		write_byte(0);
		write_byte(130);
		message_end();

		param[mytime] = _:(time/4.0);
		set_task(param[mytime], "reset_view", victim);
		set_task(param[mytime], "reset_screenfade", victim, param, sizeof(param));

		message_begin(MSG_ONE_UNRELIABLE, g_pMsgScreenShake, _, victim);
		write_short(FixedUnsigned16(10.0, 1<<12)); // shake amount
		write_short(FixedUnsigned16(param[mytime], 1<<12)); // shake lasts this long
		write_short(FixedUnsigned16(5.0, 1<<8)); // shake noise frequency
		message_end();
	}
}

public reset_view(victim)
{
	g_iBlockPlayer[victim] = false;
	message_begin(MSG_ONE_UNRELIABLE, g_pMsgSetFOV, _, victim);
	write_byte(90);
	message_end();
}

public reset_screenfade(param[TaskData], victim)
{
	message_begin(MSG_ONE_UNRELIABLE, g_pMsgScreenFade, _, victim);
	write_short(FixedUnsigned16(param[mytime], 1<<12));
	write_short(0);
	write_short((0)); //flags (SF_FADE_IN + SF_FADE_ONLYONE) (SF_FADEOUT)
	write_byte(255);
	write_byte(0);
	write_byte(0);
	write_byte(130);
	message_end();
}

stock Float:fabs(Float:x)
{
	return x > 0.0 ? x : -x;
}

CreateExplosion(id, ent)
{
	static Float:origin[3];
	entity_get_vector(ent, EV_VEC_origin, origin);

	new victim = -1, Float:damage, cvar = get_pcvar_num(cvar_inflict);
	new Float:radius = get_pcvar_float(cvar_radius);
	new Float:dmg = get_pcvar_float(cvar_damage);

	while((victim = find_ent_in_sphere(victim, origin, radius)) != 0)
	{
		if(is_valid_ent(victim) && entity_get_float(victim, EV_FL_takedamage) != DAMAGE_NO)
		{
			damage = ((dmg/radius)*(radius - entity_range(ent, victim)))/(dmg/100.0);

			if(damage > 0.0)
			{
				if(cvar)
				{
					if(is_user_connected(victim))
						ttt_set_playerdata(victim, PD_KILLEDBYITEM, g_iItemID);
					ExecuteHam(Ham_TakeDamage, victim, id, id, damage, DMG_BLAST);
				}

				entity_set_vector(victim, EV_VEC_velocity, Float:{0.0, 0.0, 0.0});
				if(is_user_alive(victim) && !g_iHitWithLaser[victim])
				{
					give_dizzy_effects(victim, damage);
					CreatePush(victim, origin, radius, damage);
					ttt_set_playerdata(victim, PD_KILLEDBYITEM, -1);
					g_iHitWithLaser[victim] = ent;
				}
			}
		}
	}
}

CreatePush(id, Float:origin[3], Float:radius, Float:damage)
{
	if(is_user_alive(id))
	{
		static Float:plOrigin[3], Float:velocity[3], Float:newvelocity[3];
		pev(id, pev_origin, plOrigin);
		new Float:dist = get_distance_f(plOrigin, origin);
		new Float:speed = (1.0 - (dist / radius)) * damage;

		velocity[0] = plOrigin[0] - origin[0];
		velocity[1] = plOrigin[1] - origin[1];
		velocity[2] = plOrigin[2] - origin[2];

		new Float:length = vector_length(velocity);
		velocity[0] = (velocity[0] / length) * speed;
		velocity[1] = (velocity[1] / length) * speed;
		velocity[2] += (radius-dist);

		pev(id, pev_velocity, newvelocity);
		newvelocity[0] += velocity[0];
		newvelocity[1] += velocity[1];
		newvelocity[2] += velocity[2];
		set_pev(id, pev_velocity, newvelocity);
	}
}