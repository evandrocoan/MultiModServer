#include <amxmodx>
#include <fakemeta>
#include <hamsandwich>

#define PLUGIN "Fake C4"
#define VERSION "1.1"
#define AUTHOR "Alka"

#define OFFSET_CS_MONEY 115
#define OFFSET_ENT_TO_INDEX 43
#define CBASE_CURR_WPN_ENT 373
#define fm_get_user_money(%1) get_pdata_int(%1, OFFSET_CS_MONEY)
#define fm_create_entity(%1) engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, %1))

#define C4_PLANT_TIME 3 //engine based.Don't modify.

new const g_szC4Sounds[][] = {
	
	"weapons/c4_beep1.wav",
	"weapons/c4_beep2.wav",
	"weapons/c4_beep3.wav",
	"weapons/c4_beep4.wav",
	"weapons/c4_beep5.wav"
};

new bool:g_bInPlant[33];
new bool:g_bBuyedC4[33];
new Float:g_fStartPlant[33];
new Float:g_fOldMaxSpeed[33];

new g_iMaxPlayers;
new g_iSprite;

new g_iTextMsg;
new g_iMoneyMsg;
new g_iBarTimeMsg;

enum _:max_cvars {
	
	CVAR_COST,
	CVAR_EXPLODETIME,
	CVAR_DAMAGE,
	CVAR_RADIUS,
	CVAR_GIVE
};
new g_iCvar[max_cvars];

public plugin_init() {
	
	register_plugin(PLUGIN, VERSION, AUTHOR);
	
	register_clcmd("say /buyc4", "clcmdBuyBomb", -1, "");
	
	g_iTextMsg = get_user_msgid("TextMsg");
	g_iMoneyMsg = get_user_msgid("Money");
	g_iBarTimeMsg = get_user_msgid("BarTime");
	
	register_forward(FM_CmdStart, "fwd_CmdStart", 0);
	RegisterHam(Ham_Spawn, "player", "fwd_HamSpawn", 1);
	RegisterHam(Ham_Think, "info_target", "fwd_HamThink", 1);
	
	register_message(g_iTextMsg, "message_TextMsg");
	register_logevent("logevent_RoundEnd", 2, "1=Round_End", "1=Round_Draw");
	
	g_iCvar[CVAR_COST] = register_cvar("c4_cost", "5000");
	g_iCvar[CVAR_EXPLODETIME] = register_cvar("c4_timer", "35");
	g_iCvar[CVAR_DAMAGE] = register_cvar("c4_damage", "400");
	g_iCvar[CVAR_RADIUS] = register_cvar("c4_radius", "1000");
	g_iCvar[CVAR_GIVE] = register_cvar("c4_give", "0");
	
	g_iMaxPlayers = get_maxplayers();
}

public plugin_precache()
	g_iSprite = precache_model("sprites/eexplo.spr");

public clcmdBuyBomb(id)
{
	if(!is_user_alive(id))
		return 1;
	
	if(user_has_weapon(id, CSW_C4))
	{
		client_print(id, print_center, "You already have a C4!");
		return 1;
	}
	else
	{
		if(fm_get_user_money(id) < get_pcvar_num(g_iCvar[CVAR_COST]))
		{
			client_print(id, print_center, "You don't have enaugh money to buy a C4!");
			return 1;
		}
		else
		{
			fm_set_user_money(id, fm_get_user_money(id) - get_pcvar_num(g_iCvar[CVAR_COST]), 1);
			
			ham_give_weapon(id, "weapon_c4");
			client_print(id, print_center, "You have buyed a C4!");
			
			g_bBuyedC4[id] = true;
		}
	}
	return 0;
}

public fwd_CmdStart(id, uc_handle, uc_seed)
{
	if(!is_user_alive(id) || !g_bBuyedC4[id])
		return FMRES_IGNORED;
	
	static iButton, iOldButton;
	iButton = get_uc(uc_handle, UC_Buttons);
	iOldButton = pev(id, pev_oldbuttons);
	
	static iWpn;
	iWpn = get_pdata_cbase(id, CBASE_CURR_WPN_ENT);
	
	if(!pev_valid(iWpn))
		return HAM_IGNORED;
	
	if((get_pdata_int(iWpn, OFFSET_ENT_TO_INDEX) == CSW_C4))
	{
		if((iButton & IN_ATTACK) && (iOldButton & IN_ATTACK) && !g_bInPlant[id])
		{
			fm_set_animation(id, 3);
			g_bInPlant[id] = true;
			g_fStartPlant[id] = get_gametime();
			
			msg_bar_time(id, C4_PLANT_TIME);
			
			pev(id, pev_maxspeed, g_fOldMaxSpeed[id]);
			fm_set_user_maxspeed(id, 1.0);
		}
		else if((iButton & IN_ATTACK) && (iOldButton & IN_ATTACK) && g_bInPlant[id])
		{
			if(get_gametime() >= g_fStartPlant[id] + float(C4_PLANT_TIME))
			{
				g_bInPlant[id] = false;
				msg_bar_time(id, 0);
				
				ham_strip_weapon(id, "weapon_c4");
				
				new Float:vOrigin[3], Float:vEnd[3];
				pev(id, pev_origin, vOrigin);
				
				vEnd[0] = vOrigin[0];
				vEnd[1] = vOrigin[1];
				vEnd[2] = -1337.0;
				
				engfunc(EngFunc_TraceLine, vOrigin, vEnd, 0, id, 0);
				get_tr2(0, TR_vecEndPos, vEnd);
				
				new iEnt = fm_create_entity("info_target");
				set_pev(iEnt, pev_classname, "c4_bomb");
				engfunc(EngFunc_SetOrigin, iEnt, vEnd);
				engfunc(EngFunc_SetModel, iEnt, "models/w_c4.mdl");
				set_pev(iEnt, pev_solid, SOLID_BBOX);
				set_pev(iEnt, pev_owner, id);
				set_pev(iEnt, pev_fuser1, get_pcvar_float(g_iCvar[CVAR_EXPLODETIME]));
				
				set_pev(iEnt, pev_nextthink, get_gametime());
				
				fm_set_user_maxspeed(id, g_fOldMaxSpeed[id]);
			}
		}
		else if(!(iButton & IN_ATTACK) && g_bInPlant[id])
		{
			fm_set_animation(id, 0);
			g_bInPlant[id] = false;
			
			msg_bar_time(id, 0);
			
			fm_set_user_maxspeed(id, g_fOldMaxSpeed[id]);
		}
	}
	else if((get_pdata_int(iWpn, OFFSET_ENT_TO_INDEX) != CSW_C4) && g_bInPlant[id])
	{
		msg_bar_time(id, 0);
		g_bInPlant[id] = false;
	}
	return FMRES_IGNORED;
}

public fwd_HamSpawn(id)
{
	if(!is_user_connected(id))
		return HAM_IGNORED;
	
	if(!user_has_weapon(id, CSW_C4))
		g_bBuyedC4[id] = false;
	
	if(get_pcvar_num(g_iCvar[CVAR_GIVE]))
	{
		if(!user_has_weapon(id, CSW_C4))
			ham_give_weapon(id, "weapon_c4");
	}
	return HAM_IGNORED;
}

public fwd_HamThink(ent)
{
	if(!pev_valid(ent))
		return HAM_IGNORED;
	
	static szClassname[32];
	pev(ent, pev_classname, szClassname, sizeof szClassname - 1);
	
	if(szClassname[0] == 'c' && szClassname[1] == '4' && szClassname[3] == 's')
	{
		switch(pev(ent, pev_iuser1))
		{
			case 3: { set_pev(ent, pev_renderamt, 100.0); }
			case 2: { set_pev(ent, pev_renderamt, 50.0); }
			case 1: { set_pev(ent, pev_renderamt, 10.0); }
			case 0:
			{
				engfunc(EngFunc_RemoveEntity, ent);
				return HAM_IGNORED;
			}
		}
		set_pev(ent, pev_iuser1, pev(ent, pev_iuser1) - 1);
		set_pev(ent, pev_nextthink, get_gametime() + 0.1);
	}
	else if(szClassname[0] == 'c' && szClassname[1] == '4' && szClassname[3] == 'b')
	{
		static Float:vOrigin[3];
		pev(ent, pev_origin, vOrigin);
		
		vOrigin[2] += 7.0;
		
		new iSprite = fm_create_entity("info_target");
		set_pev(iSprite, pev_classname, "c4_sprite");
		engfunc(EngFunc_SetOrigin, iSprite, vOrigin);
		set_pev(iSprite, pev_rendermode, 5);
		set_pev(iSprite, pev_renderamt, 200.0);
		set_pev(iSprite, pev_scale, 0.3);
		engfunc(EngFunc_SetModel, iSprite, "sprites/ledglow.spr");
		set_pev(iSprite, pev_iuser1, 3);
		set_pev(iSprite, pev_nextthink, get_gametime() + 0.1);
		
		new Float:fTime;
		pev(ent, pev_fuser1, fTime);
		new Float:fExplodeTime = get_pcvar_float(g_iCvar[CVAR_EXPLODETIME]);
		
		if(!fTime || fTime < 0.0)
		{
			client_print(pev(ent, pev_owner), print_center, "Your C4 has exploded!");
			ham_fakedamage_r(vOrigin, pev(ent, pev_owner), get_pcvar_float(g_iCvar[CVAR_DAMAGE]), get_pcvar_float(g_iCvar[CVAR_RADIUS]));
			engfunc(EngFunc_RemoveEntity, ent);
			
			return HAM_IGNORED;
		}
		
		if(0 <= fTime <= fExplodeTime / 5)
			emit_sound(ent, CHAN_AUTO, g_szC4Sounds[4], VOL_NORM, ATTN_STATIC, 0, PITCH_NORM);
		else if(fExplodeTime / 5 < fTime <= fExplodeTime / 4)
			emit_sound(ent, CHAN_AUTO, g_szC4Sounds[3], VOL_NORM, ATTN_STATIC, 0, PITCH_NORM);
		else if(fExplodeTime / 4 < fTime <= fExplodeTime / 3)
			emit_sound(ent, CHAN_AUTO, g_szC4Sounds[2], VOL_NORM, ATTN_STATIC, 0, PITCH_NORM);
		else if(fExplodeTime / 3 < fTime <= fExplodeTime / 2)
			emit_sound(ent, CHAN_AUTO, g_szC4Sounds[1], VOL_NORM, ATTN_STATIC, 0, PITCH_NORM);
		else if(fExplodeTime / 2 < fTime <= fExplodeTime)
			emit_sound(ent, CHAN_AUTO, g_szC4Sounds[0], VOL_NORM, ATTN_STATIC, 0, PITCH_NORM);
		
		set_pev(ent, pev_fuser1, fTime - 1.5);
		set_pev(ent, pev_nextthink, get_gametime() + 1.5);
	}
	return HAM_IGNORED;
}

public message_TextMsg(msg_id, msg_dest, msg_entity)
{
	static szMessage[64];
	get_msg_arg_string(2, szMessage, sizeof szMessage - 1);
	
	if(equal(szMessage, "#C4_Plant_At_Bomb_Spot") && g_bBuyedC4[msg_entity])
		return 1;
	
	return 0;
}

public logevent_RoundEnd()
{
	new iEnt;
	while((iEnt = engfunc(EngFunc_FindEntityByString, iEnt, "classname", "c4_bomb")))
	{
		if(pev_valid(iEnt))
			engfunc(EngFunc_RemoveEntity, iEnt);
	}
}

stock ham_give_weapon(id, weapon[])
{
	if(!equal(weapon, "weapon_",7)) return 0;
	
	new wEnt = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, weapon));
	if(!pev_valid(wEnt)) return 0;
	
	set_pev(wEnt,pev_spawnflags, SF_NORESPAWN);
	dllfunc(DLLFunc_Spawn, wEnt);
	
	if(!ExecuteHamB(Ham_AddPlayerItem, id, any:wEnt))
	{
		if(pev_valid(wEnt)) set_pev(wEnt, pev_flags, pev(wEnt, pev_flags) | FL_KILLME);
		return 0;
	}
	ExecuteHamB(Ham_Item_AttachToPlayer, wEnt, any:id)
	return wEnt;
}

stock ham_strip_weapon(id,weapon[])
{
	if(!equal(weapon,"weapon_",7)) return 0;
	
	new wId = get_weaponid(weapon);
	if(!wId) return 0;
	
	new wEnt;
	while((wEnt = engfunc(EngFunc_FindEntityByString, wEnt, "classname", weapon)) && pev(wEnt, pev_owner) != id) {}
	if(!wEnt) return 0;
	
	new iTmp;
	if(get_user_weapon(id, iTmp, iTmp) == wId) ExecuteHamB(Ham_Weapon_RetireWeapon, wEnt);
	
	if(!ExecuteHamB(Ham_RemovePlayerItem, id, any:wEnt)) return 0;
	
	ExecuteHamB(Ham_Item_Kill, wEnt);
	set_pev(id, pev_weapons, pev(id, pev_weapons) & ~(1<<wId));
	
	return 1;
}

stock ham_fakedamage_r(Float:origin[3], inflictor, Float:damage, Float:range)
{
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY); 
	write_byte(TE_EXPLOSION);
	write_coord(floatround(origin[0])); 
	write_coord(floatround(origin[1]));      
	write_coord(floatround(origin[2]));
	write_short(g_iSprite);
	write_byte(80);
	write_byte(15); 
	write_byte(0); 
	message_end();
	
	static Float:vOrigin[3], Float:fDistance, Float:fTmpDmg;
	
	for(new i = 1 ; i <= g_iMaxPlayers ; i++)
	{
		if(!is_user_alive(i))
			continue;
		
		pev(i, pev_origin, vOrigin);
		fDistance = vector_distance(origin, vOrigin);
		
		if(fDistance <= range)
		{
			fTmpDmg = damage - (damage / range) * fDistance;
			ExecuteHamB(Ham_TakeDamage, i, any:inflictor, any:inflictor, any:fTmpDmg, any:DMG_BLAST);
		}
	}
}

stock fm_set_user_money(index, money, flash = 1)
{
	set_pdata_int(index, OFFSET_CS_MONEY, money);
	
	message_begin(MSG_ONE, g_iMoneyMsg, _, index);
	write_long(money);
	write_byte(flash ? 1 : 0);
	message_end();
}

stock fm_set_animation(id, animation)
{
	set_pev(id, pev_weaponanim, animation);
	
	message_begin(MSG_ONE, SVC_WEAPONANIM, {0, 0, 0}, id);
	write_byte(animation);
	write_byte(pev(id, pev_body));
	message_end();
}

stock fm_set_user_maxspeed(index, Float:speed = -1.0)
{
	engfunc(EngFunc_SetClientMaxspeed, index, speed);
	set_pev(index, pev_maxspeed, speed);
	
	return 1;
}

stock msg_bar_time(id, scale)
{
	message_begin(MSG_ONE, g_iBarTimeMsg, _, id);
	write_short(scale);
	message_end();
}
