#include <amxmodx>
#include <fakemeta>
#include <hamsandwich>

#define PLUGIN	"Back Weapons"
#define AUTHOR	"hoboman313/cheap_suit"
#define VERSION	"1.87"

#define MAX_PLAYERS 		32
#define OFFSET_PRIMARYWEAPON 	116
#define OFFSET_WEAPONTYPE 	43
#define EXTRAOFFSET_WEAPONS 	4
#define OFFSET_AUTOSWITCH 	509
#define OFFSET_SHIELD 		510
#define HAS_SHIELD 		(1<<24)

#define PRIMARY_WEAPONS (1<<CSW_SCOUT | 1<<CSW_XM1014 | 1<<CSW_MAC10 | 1<<CSW_AUG | 1<<CSW_UMP45 | 1<<CSW_SG550 | 1<<CSW_GALIL | 1<<CSW_FAMAS | 1<<CSW_AWP | 1<<CSW_MP5NAVY | 1<<CSW_M249 | 1<<CSW_M3 | 1<<CSW_M4A1 | 1<<CSW_TMP | 1<<CSW_G3SG1 | 1<<CSW_SG552 | 1<<CSW_AK47 | 1<<CSW_P90)

#define is_weapon_primary(%1)      (PRIMARY_WEAPONS & (1<<%1))
#define cs_get_weapon_type(%1)     get_pdata_int(%1, OFFSET_WEAPONTYPE, EXTRAOFFSET_WEAPONS)
#define cs_get_user_hasprim(%1)    get_pdata_int(%1, OFFSET_PRIMARYWEAPON)
#define cs_get_user_autoswitch(%1) get_pdata_int(%1, OFFSET_AUTOSWITCH)
#define cs_get_user_shield(%1)	   (get_pdata_int(%1, OFFSET_SHIELD) & HAS_SHIELD) ? 1 : 0

enum
{
	MODEL_NULL    = 0,
	MODEL_AUG     = 1,
	MODEL_AK47    = 2,
	MODEL_AWP     = 3,
	MODEL_MP5NAVY = 4,
	MODEL_P90     = 5,
	MODEL_GALIL   = 6,
	MODEL_M4A1    = 7,
	MODEL_SG550   = 8,
	MODEL_SG552   = 9,
	MODEL_SCOUT   = 10,
	MODEL_XM1014  = 11,
	MODEL_M3      = 12,
	MODEL_G3SG1   = 13,
	MODEL_M249    = 14,
	MODEL_FAMAS   = 15,
	MODEL_UMP45   = 16
}

new g_weapons[][] =
{	
	"weapon_p228",
	"weapon_scout",
	"weapon_hegrenade",
	"weapon_xm1014",
	"weapon_c4",
	"weapon_mac10",
	"weapon_aug",
	"weapon_smokegrenade",
	"weapon_elite",
	"weapon_fiveseven",
	"weapon_ump45",
	"weapon_sg550",
	"weapon_galil",
	"weapon_famas",
	"weapon_usp",
	"weapon_glock18",
	"weapon_awp",
	"weapon_mp5navy",
	"weapon_m249",
	"weapon_m3",
	"weapon_m4a1",
	"weapon_tmp",
	"weapon_g3sg1",
	"weapon_flashbang",
	"weapon_deagle",
	"weapon_sg552",
	"weapon_ak47",
	"weapon_knife",
	"weapon_p90"
}

new g_weaponclass[] = "backweapon"
new g_weaponmodel[] = "models/backweapons.mdl"

new g_weaponent[MAX_PLAYERS+1]

public plugin_init() 
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	register_cvar(PLUGIN, VERSION, FCVAR_SPONLY|FCVAR_SERVER)
	
	RegisterHam(Ham_Killed,           "player", "bacon_killed")
	RegisterHam(Ham_Spawn,            "player", "bacon_spawn_post", 1)
	RegisterHam(Ham_AddPlayerItem,    "player", "bacon_addplayeritem")
	RegisterHam(Ham_RemovePlayerItem, "player", "bacon_removeplayeritem")
	
	for(new i = 0; i < sizeof g_weapons; i++)
	{
		RegisterHam(Ham_Item_AttachToPlayer, g_weapons[i], "bacon_item_attachtoplayer_post", 1)
		RegisterHam(Ham_Item_Deploy,         g_weapons[i], "bacon_item_deploy_post",         1)
	}
}

public plugin_precache()
	precache_model(g_weaponmodel)

public client_putinserver(id)
{
	static infotarget 
	if(!infotarget) infotarget = engfunc(EngFunc_AllocString, "info_target")
	
	g_weaponent[id] = engfunc(EngFunc_CreateNamedEntity, infotarget)
	if(pev_valid(g_weaponent[id]))
	{
		engfunc(EngFunc_SetModel, g_weaponent[id], g_weaponmodel)
		set_pev(g_weaponent[id], pev_classname, g_weaponclass)
		set_pev(g_weaponent[id], pev_movetype, MOVETYPE_FOLLOW)
		set_pev(g_weaponent[id], pev_effects, EF_NODRAW)
		set_pev(g_weaponent[id], pev_aiment, id)
	}
}

public client_disconnect(id)
{
	if(g_weaponent[id] > 0 && pev_valid(g_weaponent[id]))
		engfunc(EngFunc_RemoveEntity, g_weaponent[id])
	
	g_weaponent[id] = 0
}

public bacon_killed(id, idattacker, shouldgib)
	fm_set_entity_visibility(g_weaponent[id], 0)

public bacon_addplayeritem(id, ent)
{
	static weaponid; weaponid = cs_get_weapon_type(ent)
	if(is_weapon_primary(weaponid) && pev_valid(g_weaponent[id]))
	{
		fm_set_entity_visibility(g_weaponent[id], 0)
		set_pev(g_weaponent[id], pev_body, get_weapon_model(weaponid))
	}
}

public bacon_removeplayeritem(id, ent)
{
	if(is_weapon_primary(cs_get_weapon_type(ent)) && pev_valid(g_weaponent[id]))
		fm_set_entity_visibility(g_weaponent[id], 0)
}

public bacon_spawn_post(id) if(is_user_alive(id))
{
	if(!cs_get_user_hasprim(id))
		fm_set_entity_visibility(g_weaponent[id], 0)
}

public bacon_item_attachtoplayer_post(ent, id) if(is_user_alive(id) && !cs_get_user_autoswitch(id))
{
	if(is_weapon_primary(cs_get_weapon_type(ent)) && pev_valid(g_weaponent[id]))
		fm_set_entity_visibility(g_weaponent[id], 1)
}

public bacon_item_deploy_post(ent)
{
	static id; id = pev(ent, pev_owner)
	if(is_user_alive(id)) 
	{
		static weapon; weapon = cs_get_weapon_type(ent)
		if(is_weapon_primary(weapon) || cs_get_user_shield(id))
			fm_set_entity_visibility(g_weaponent[id], 0)
		
		else if(cs_get_user_hasprim(id))
			fm_set_entity_visibility(g_weaponent[id], 1)
	}
}

stock get_weapon_model(weapon)
{
	switch(weapon)
	{
		case CSW_SCOUT:   return MODEL_SCOUT
		case CSW_XM1014:  return MODEL_XM1014
		case CSW_AUG:	  return MODEL_AUG
		case CSW_UMP45:   return MODEL_UMP45
		case CSW_SG550:   return MODEL_SG550
		case CSW_GALIL:   return MODEL_GALIL
		case CSW_FAMAS:   return MODEL_FAMAS
		case CSW_AWP:     return MODEL_AWP
		case CSW_MP5NAVY: return MODEL_MP5NAVY
		case CSW_M249:    return MODEL_M249
		case CSW_M3:      return MODEL_M3
		case CSW_M4A1:    return MODEL_M4A1
		case CSW_G3SG1:   return MODEL_G3SG1
		case CSW_SG552:   return MODEL_SG552
		case CSW_AK47:    return MODEL_AK47
		case CSW_P90:     return MODEL_P90
	}
	return 0
}

stock fm_set_entity_visibility(index, visible = 1) 
	set_pev(index, pev_effects, visible == 1 ? pev(index, pev_effects) & ~EF_NODRAW : pev(index, pev_effects) | EF_NODRAW)