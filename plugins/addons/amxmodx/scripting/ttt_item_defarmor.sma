#include <amxmodx>
#include <amxmisc>
#include <hamsandwich>
#include <fakemeta>
#include <cstrike>
#include <ttt>

#define m_iKevlar 112

new g_iItem_Defuser, g_iItem_Armor, cvar_price_defuser, cvar_price_armor;
new g_iBloodSpraySprite, g_iBloodDropSprite, g_iTempEntity;

public plugin_precache()
{
	g_iBloodSpraySprite = precache_model("sprites/bloodspray.spr");
	g_iBloodDropSprite = precache_model("sprites/blood.spr");
}

public plugin_init()
{
	register_plugin("[TTT] Item: Defuser&Armor", TTT_VERSION, TTT_AUTHOR);

	cvar_price_defuser	= my_register_cvar("ttt_price_defuser",	"1", "Defuser price. (Default: 1)");
	cvar_price_armor	= my_register_cvar("ttt_price_armor",	"1", "Armor price. (Default: 1)");

	RegisterHam(Ham_TraceAttack, "player", "Ham_TraceAttack_pre", 0);
	RegisterHam(Ham_TraceAttack, "player", "Ham_TraceAttack_post", 1);
}

public ttt_plugin_cfg()
{
	new name[TTT_ITEMLENGHT];
	formatex(name, charsmax(name), "%L", LANG_PLAYER, "TTT_ITEM_ID2");
	g_iItem_Armor = ttt_buymenu_add(name, get_pcvar_num(cvar_price_armor), PC_SPECIAL);
	formatex(name, charsmax(name), "%L", LANG_PLAYER, "TTT_ITEM_ID1");
	g_iItem_Defuser = ttt_buymenu_add(name, get_pcvar_num(cvar_price_defuser), PC_DETECTIVE);
}

public ttt_gamemode(gamemode)
{
	if(gamemode == GAME_ENDED || gamemode == GAME_RESTARTING)
	{
		new num, id;
		static players[32];
		get_players(players, num, "a");
		for(--num; num >= 0; num--)
		{
			id = players[num];
			cs_set_user_armor(id, 0, CsArmorType);
		}
	}
}

public ttt_item_selected(id, item, name[], price)
{
	if(item == g_iItem_Defuser)
	{
		cs_set_user_defuse(id, 1);
		client_print_color(id, print_team_default, "%s %L", TTT_TAG, id, "TTT_ITEM2", name, id, "TTT_ITEM5");
		return PLUGIN_HANDLED;
	}
	else if(item == g_iItem_Armor)
	{
		cs_set_user_armor(id, 100, CS_ARMOR_VESTHELM);
		client_print_color(id, print_team_default, "%s %L", TTT_TAG, id, "TTT_ITEM2", name, id, "TTT_ITEM5");
		return PLUGIN_HANDLED;
	}

	return PLUGIN_CONTINUE;
}

public Ham_TraceAttack_pre(id, iAttacker, Float:flDamage, Float:vecDir[3], ptr, bitsDamageType)
{
	if(bitsDamageType & DMG_BULLET && get_tr2(ptr, TR_iHitgroup) == HIT_HEAD && get_pdata_int(id, m_iKevlar) == 2)
	{
		if(!g_iTempEntity)
			g_iTempEntity = register_message(SVC_TEMPENTITY, "Message_TempEntity");

		new Float:vecEndPos[3];
		get_tr2(ptr, TR_vecEndPos, vecEndPos);

		message_begin_f(MSG_PVS, SVC_TEMPENTITY, vecEndPos);
		{
			write_byte(TE_BLOODSTREAM);
			write_coord_f(vecEndPos[0]);
			write_coord_f(vecEndPos[1]);
			write_coord_f(vecEndPos[2]);
			write_coord_f(vecDir[0]);
			write_coord_f(vecDir[1]);
			write_coord_f(vecDir[2]);
			write_byte(223);
			write_byte(min(random(101) + floatround(flDamage * 5.0, floatround_floor), 255));
		}
		message_end();

		new amount = min(floatround(flDamage, floatround_floor) * 2, 255);
		new scale = 16;
		if(amount <= 159)
		{
			scale = 3;
			if(amount > 29)
				scale = amount / 10;
		}

		message_begin_f(MSG_PVS, SVC_TEMPENTITY, vecEndPos);
		{
			write_byte(TE_BLOODSPRITE);
			write_coord_f(vecEndPos[0]);
			write_coord_f(vecEndPos[1]);
			write_coord_f(vecEndPos[2]);
			write_short(g_iBloodSpraySprite);
			write_short(g_iBloodDropSprite);
			write_byte(ExecuteHamB(Ham_BloodColor, id));
			write_byte(scale); // scale
		}
		message_end();
	}
}

public Message_TempEntity()
{
	if(get_msg_arg_int(1) == TE_STREAK_SPLASH)
	{
		unregister_message(SVC_TEMPENTITY, g_iTempEntity);
		return PLUGIN_HANDLED;
	}

	return PLUGIN_CONTINUE;
}

public Ham_TraceAttack_post()
{
	if(g_iTempEntity)
	{
		unregister_message(SVC_TEMPENTITY, g_iTempEntity);
		g_iTempEntity = 0;
	}
}