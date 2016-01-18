#include <amxmodx>
#include <engine>
#include <hamsandwich>
#include <amx_settings_api>
#include <fun>
#include <ttt>

#define HOOK_DELTA_T  0.1

enum _:HOOK_INFO
{
	HI_HASHOOK,
	HI_HOOKED,
	HI_LENGTH,
	HI_COUNT,
	Float:HI_CREATEDAT
}

new g_iHookInfo[33][HOOK_INFO], g_iHookOrigin[33][3];
new g_pWebSprite, g_iItemID;
new cvar_moveacc, cvar_reelspeed, cvar_gravity, cvar_price, cvar_tosky, cvar_count;

public plugin_precache()
{
	precache_sound("bullchicken/bc_bite2.wav");
	g_pWebSprite = precache_model("sprites/zbeam4.spr");
}

public plugin_init()
{
	register_plugin("[TTT] Item: Hook", TTT_VERSION, TTT_AUTHOR);

	cvar_moveacc	= my_register_cvar("ttt_hook_moveacc",		"140",	"Hooks movement accuracy. (Default: 140)");
	cvar_reelspeed	= my_register_cvar("ttt_hook_reelspeed",	"400",	"Hooks reel speed. (Default: 400)");
	cvar_tosky		= my_register_cvar("ttt_hook_tosky",		"1",	"Hooks attaches to sky? (Default: 1)");
	cvar_count		= my_register_cvar("ttt_hook_count",		"10",	"Hooks can be used X times, X < 0 means no limit. (Default: 10)");
	cvar_price		= my_register_cvar("ttt_price_hook",		"2",	"Hooks price. (Default: 2)");

	RegisterHamPlayer(Ham_Killed, "Ham_Killed_pre", 0);

	register_clcmd("+ttt_bind1", "cmd_hookon");
	register_clcmd("-ttt_bind1", "cmd_hookoff");

	cvar_gravity = get_cvar_pointer("sv_gravity");
}

public ttt_plugin_cfg()
{
	new name[TTT_ITEMLENGHT];
	formatex(name, charsmax(name), "%L", LANG_PLAYER, "TTT_ITEM_HOOK");
	g_iItemID = ttt_buymenu_add(name, get_pcvar_num(cvar_price), PC_SPECIAL);
}

public client_disconnect(id)
{
	if(task_exists(id))
		remove_task(id);

	g_iHookInfo[id][HI_HASHOOK] = false;
	g_iHookInfo[id][HI_COUNT] = 0;
}

public Ham_Killed_pre(victim, killer)
{
	if(g_iHookInfo[victim][HI_HOOKED])
		remove_hook(victim);

	g_iHookInfo[victim][HI_HASHOOK] = false;
	g_iHookInfo[victim][HI_COUNT] = 0;
}


public ttt_gamemode(mode)
{
	if(mode == GAME_ENDED || mode == GAME_RESTARTING)
	{
		new num, id;
		static players[32];
		get_players(players, num);

		for(--num; num >= 0; num--)
		{
			id = players[num];
			g_iHookInfo[id][HI_HOOKED] = false;
			g_iHookInfo[id][HI_HASHOOK] = false;
			g_iHookInfo[id][HI_COUNT] = 0;
		}
	}
}

public ttt_item_selected(id, item, name[], price)
{
	if(g_iItemID == item)
	{
		g_iHookInfo[id][HI_HASHOOK] = true;
		g_iHookInfo[id][HI_COUNT] += get_pcvar_num(cvar_count);
		client_print_color(id, print_team_default, "%s %L", TTT_TAG, id, "TTT_ITEM2", name, id, "TTT_ITEM_BIND1", name);
		return PLUGIN_HANDLED;
	}

	return PLUGIN_CONTINUE;
}

public cmd_hookon(id)
{
	if(!is_user_alive(id) || !g_iHookInfo[id][HI_HASHOOK] || g_iHookInfo[id][HI_HOOKED])
		return PLUGIN_HANDLED;

	if(g_iHookInfo[id][HI_COUNT] == 0)
	{
		g_iHookInfo[id][HI_HASHOOK] = false;
		g_iHookInfo[id][HI_HOOKED] = false;
		remove_hook(id);
		return PLUGIN_HANDLED;
	}

	get_user_origin(id, g_iHookOrigin[id], 3);
	if(!get_pcvar_num(cvar_tosky))
	{
		new Float:origin[3];
		IVecFVec(g_iHookOrigin[id], origin);
		if(PointContents(origin) == CONTENTS_SKY)
			return PLUGIN_HANDLED;
	}

	g_iHookInfo[id][HI_HOOKED] = true;
	g_iHookInfo[id][HI_COUNT]--;

	if(g_iHookInfo[id][HI_COUNT] >= 0)
		client_print(id, print_center, "%L %d", id, "TTT_HOOKS", g_iHookInfo[id][HI_COUNT]);

	new user_origin[3];
	get_user_origin(id, user_origin);
	g_iHookInfo[id][HI_LENGTH] = get_distance(g_iHookOrigin[id], user_origin);
	set_user_gravity(id, 0.001);

	make_beampoint(id);
	emit_sound(id, CHAN_STATIC, "bullchicken/bc_bite2.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM);

	set_task(HOOK_DELTA_T, "hook_check", id, _, _, "b");

	return PLUGIN_HANDLED;
}

public cmd_hookoff(id)
{
	if (g_iHookInfo[id][HI_HOOKED])
		remove_hook(id);
	return PLUGIN_HANDLED;
}

public hook_check(id)
{
	if(!g_iHookInfo[id][HI_HOOKED] || !g_iHookInfo[id][HI_HASHOOK])
		return;

	if(!is_user_alive(id))
	{
		remove_hook(id);
		return;
	}

	if(g_iHookInfo[id][HI_CREATEDAT] + 10 <= get_gametime())
		make_beampoint(id);

	new user_origin[3], null[3], A[3], D[3], buttonadjust[3], buttonpress;
	new Float:vTowards_A, Float:DvTowards_A, Float:velocity[3];

	get_user_origin(id, user_origin);
	entity_get_vector(id, EV_VEC_velocity, velocity);

	buttonpress = get_user_button(id);

	if(buttonpress & IN_FORWARD) ++buttonadjust[0];
	if(buttonpress & IN_BACK) --buttonadjust[0];

	if(buttonpress & IN_MOVERIGHT) ++buttonadjust[1];
	if(buttonpress & IN_MOVELEFT) --buttonadjust[1];

	if(buttonpress & IN_JUMP) ++buttonadjust[2];
	if(buttonpress & IN_DUCK) --buttonadjust[2];

	if(buttonadjust[0] || buttonadjust[1])
	{
		new user_look[3], move_direction[3];
		get_user_origin(id, user_look, 2);
		user_look[0] -= user_origin[0];
		user_look[1] -= user_origin[1];

		move_direction[0] = buttonadjust[0] * user_look[0] + user_look[1] * buttonadjust[1];
		move_direction[1] = buttonadjust[0] * user_look[1] - user_look[0] * buttonadjust[1];
		move_direction[2] = 0;

		new move_dist = get_distance(null, move_direction);
		new Float:accel = get_pcvar_float(cvar_moveacc) * HOOK_DELTA_T;

		velocity[0] += move_direction[0] * accel / move_dist;
		velocity[1] += move_direction[1] * accel / move_dist;
	}

	if(buttonadjust[2] < 0 || (buttonadjust[2] && g_iHookInfo[id][HI_LENGTH] >= 60))
		g_iHookInfo[id][HI_LENGTH] -= floatround(buttonadjust[2] * get_pcvar_float(cvar_reelspeed) * HOOK_DELTA_T);
	else if(!(buttonpress & IN_DUCK) && g_iHookInfo[id][HI_LENGTH] >= 200)
	{
		buttonadjust[2] += 1;
		g_iHookInfo[id][HI_LENGTH] -= floatround(buttonadjust[2] * get_pcvar_float(cvar_reelspeed) * HOOK_DELTA_T);
	}

	A[0] = g_iHookOrigin[id][0] - user_origin[0];
	A[1] = g_iHookOrigin[id][1] - user_origin[1];
	A[2] = g_iHookOrigin[id][2] - user_origin[2];

	new distA = get_distance(null, A);
	distA = distA ? distA : 1;

	vTowards_A = (velocity[0] * A[0] + velocity[1] * A[1] + velocity[2] * A[2]) / distA;
	DvTowards_A = float((get_distance(user_origin, g_iHookOrigin[id]) - g_iHookInfo[id][HI_LENGTH]) * 4);

	D[0] = A[0]*A[2] / distA;
	D[1] = A[1]*A[2] / distA;
	D[2] = -(A[1]*A[1] + A[0]*A[0]) / distA;

	new distD = get_distance(null, D);
	if(distD > 10)
	{
		new Float:acceleration = ((-get_pcvar_num(cvar_gravity)) * D[2] / distD) * HOOK_DELTA_T;
		velocity[0] += (acceleration * D[0]) / distD;
		velocity[1] += (acceleration * D[1]) / distD;
		velocity[2] += (acceleration * D[2]) / distD;
	}

	new Float:difference = DvTowards_A - vTowards_A;

	velocity[0] += (difference * A[0]) / distA;
	velocity[1] += (difference * A[1]) / distA;
	velocity[2] += (difference * A[2]) / distA;

	entity_set_vector(id, EV_VEC_velocity, velocity);
}

remove_hook(id)
{
	g_iHookInfo[id][HI_HOOKED] = false;
	remove_beampoint(id);

	if(is_user_connected(id))
		set_user_gravity(id);

	if(task_exists(id))
		remove_task(id);
}

make_beampoint(id)
{
	if(!is_user_connected(id) || !g_iHookInfo[id][HI_HASHOOK])
		return;

	new rgb[3] = {150, 100, 30};

	message_begin(MSG_BROADCAST, SVC_TEMPENTITY);
	write_byte(TE_BEAMENTPOINT);
	write_short(id);
	write_coord(g_iHookOrigin[id][0]);
	write_coord(g_iHookOrigin[id][1]);
	write_coord(g_iHookOrigin[id][2]);
	write_short(g_pWebSprite);
	write_byte(0);
	write_byte(0);
	write_byte(100);
	write_byte(10);
	write_byte(0);
	write_byte(rgb[0]);
	write_byte(rgb[1]);
	write_byte(rgb[2]);
	write_byte(150);
	write_byte(0);
	message_end();

	g_iHookInfo[id][HI_CREATEDAT] = _:get_gametime();
}

remove_beampoint(id)
{
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY);
	write_byte(TE_KILLBEAM);
	write_short(id);
	message_end();
}