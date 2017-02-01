#include <amxmodx>
#include <hamsandwich>
#include <engine>
#include <fun>
#include <ttt>
#include <amx_settings_api>

new cvar_jihad_radius, cvar_jihad_damage, cvar_jihad_timer, cvar_price_jihad, g_iItemBought;
new g_szSounds[2][TTT_FILELENGHT];
new g_iTimerJihad[33], g_iHasJihad[33], g_iDidDieJihad[33], Float:g_fSoundPlaying[33], g_iItem_Jihad, g_iItem_Backpack[33], g_iItem_Backpack2[33];

public plugin_precache()
{
	if(!amx_load_setting_string(TTT_SETTINGSFILE, "Jihad", "SOUND_EXPL", g_szSounds[0], charsmax(g_szSounds[])))
	{
		g_szSounds[0] = "ttt/jihad.wav";
		amx_save_setting_string(TTT_SETTINGSFILE, "Jihad", "SOUND_EXPL", g_szSounds[0]);
	}

	if(!amx_load_setting_string(TTT_SETTINGSFILE, "Jihad", "SOUND_CALL", g_szSounds[1], charsmax(g_szSounds[])))
	{
		g_szSounds[1] = "ttt/heyoverhere.wav";
		amx_save_setting_string(TTT_SETTINGSFILE, "Jihad", "SOUND_CALL", g_szSounds[1]);
	}

	precache_sound(g_szSounds[0]);
	precache_sound(g_szSounds[1]);
}

public plugin_init()
{
	register_plugin("[TTT] Item: Jihad", TTT_VERSION, TTT_AUTHOR);

	cvar_jihad_damage	= my_register_cvar("ttt_jihad_damage",	"300.0",	"Jihad bombs damage. (Default: 300.0)");
	cvar_jihad_radius	= my_register_cvar("ttt_jihad_radius",	"420.0",	"Jihad bombs radius. (Default: 420.0)");
	cvar_jihad_timer	= my_register_cvar("ttt_jihad_timer",	"3",		"Jihad bombs timer. (Default: 3)");
	cvar_price_jihad	= my_register_cvar("ttt_price_jihad",	"2",		"Jihad bombs price. (Default: 2)");

	RegisterHamPlayer(Ham_Killed, "Ham_Killed_pre", 0);
}

public ttt_plugin_cfg()
{
	new name[TTT_ITEMLENGHT];
	formatex(name, charsmax(name), "%L", LANG_PLAYER, "TTT_ITEM_ID3");
	g_iItem_Jihad = ttt_buymenu_add(name, get_pcvar_num(cvar_price_jihad), PC_TRAITOR);
	ttt_add_exception(g_iItem_Jihad);
}

public ttt_gamemode(gamemode)
{
	if(!g_iItemBought)
		return;

	if(gamemode == GAME_PREPARING || gamemode == GAME_RESTARTING)
	{
		new num, id;
		static players[32];
		get_players(players, num);
		for(--num; num >= 0; num--)
		{
			id = players[num];
			g_iTimerJihad[id] = false;
			g_iHasJihad[id] = false;
			g_iDidDieJihad[id] = false;
			g_iItem_Backpack[id] = -1;

			if(task_exists(id))
				remove_task(id);
		}
		g_iItemBought = false;
	}
}

public ttt_item_selected(id, item, name[], price)
{
	if(g_iItem_Jihad == item)
	{
		g_iItemBought = true;
		g_iHasJihad[id] = true;
		client_print_color(id, print_team_default, "%s %L", TTT_TAG, id, "TTT_ITEM2", name, id, "TTT_ITEM_BACKPACK", name);
		g_iItem_Backpack[id] = ttt_backpack_add(id, name);

		static out[TTT_ITEMLENGHT];
		formatex(out, charsmax(out), "%L Call", id, "TTT_ITEM_ID3");
		g_iItem_Backpack2[id] = ttt_backpack_add(id, out);

		return PLUGIN_HANDLED;
	}

	return PLUGIN_CONTINUE;
}

public ttt_item_backpack(id, item)
{
	if(g_iHasJihad[id])
	{
		if(g_iItem_Backpack[id] == item)
		{
			g_iTimerJihad[id] = get_pcvar_num(cvar_jihad_timer) - 1;
			emit_sound(id, CHAN_AUTO, g_szSounds[0], 1.0, ATTN_NORM, 0, PITCH_NORM);
			set_task(1.0, "jihad_bomber", id, _, _, "a", g_iTimerJihad[id]);
			ttt_backpack_remove(id, g_iItem_Backpack2[id]);

			return PLUGIN_HANDLED;
		}
		else if(g_iItem_Backpack2[id] == item)
		{
			if(g_fSoundPlaying[id] < get_gametime())
			{
				g_fSoundPlaying[id] = get_gametime()+1.0;
				emit_sound(id, CHAN_AUTO, g_szSounds[1], 1.0, ATTN_NORM, 0, PITCH_NORM);
			}
			ttt_backpack_show(id);
		}
	}

	return PLUGIN_CONTINUE;
}

public Ham_Killed_pre(victim, killer, shouldgib)
{
	if(g_iHasJihad[victim] && g_iTimerJihad[victim] == 1 && victim == killer)
	{
		g_iHasJihad[victim] = false;
		g_iTimerJihad[victim] = 0;
	}

	if(task_exists(victim))
	{
		emit_sound(victim, CHAN_AUTO, g_szSounds[0], 1.0, ATTN_NORM, SND_STOP, PITCH_NORM);
		remove_task(victim);
	}
}

public jihad_bomber(id)
{
	if(!is_user_alive(id) || !g_iHasJihad[id] || ttt_get_gamemode() == GAME_ENDED || ttt_get_gamemode() == GAME_PREPARING)
	{
		remove_task(id);
		return PLUGIN_HANDLED;
	}
	
	if(g_iTimerJihad[id] > 1)	
		g_iTimerJihad[id]--;
	else
	{
		strip_user_weapons(id);
		Explode(id);
		CreateExplosion(id);
		remove_task(id);
	}

	return PLUGIN_HANDLED;
}

CreateExplosion(id)
{
	static Float:origin[3];
	entity_get_vector(id, EV_VEC_origin, origin);

	new victim = -1, Float:damage;
	new Float:radius = get_pcvar_float(cvar_jihad_radius);
	new Float:dmg = get_pcvar_float(cvar_jihad_damage);

	while((victim = find_ent_in_sphere(victim, origin, radius)) != 0)
	{
		if(is_valid_ent(victim) && entity_get_float(victim, EV_FL_takedamage) != DAMAGE_NO)
		{
			damage = (dmg/radius)*(radius - entity_range(id, victim));

			if(damage > 0.0)
			{
				if(is_user_connected(victim))
					ttt_set_playerdata(victim, PD_KILLEDBYITEM, g_iItem_Jihad);
				ExecuteHam(Ham_TakeDamage, victim, id, id, damage, DMG_BLAST);
				entity_set_vector(victim, EV_VEC_velocity, Float:{0.0, 0.0, 0.0});
				if(is_user_alive(victim))
					ttt_set_playerdata(victim, PD_KILLEDBYITEM, -1);
			}
		}
	}

	ttt_set_playerdata(id, PD_KILLEDBYITEM, g_iItem_Jihad);
	ExecuteHam(Ham_TakeDamage, id, id, id, dmg, DMG_BLAST);
}

Explode(id)
{
	static origin[3];
	get_user_origin(id, origin, 0);
	
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY);
	write_byte(TE_TAREXPLOSION);
	write_coord(origin[0]);
	write_coord(origin[1]);
	write_coord(origin[2]);
	message_end();
}