#include <amxmodx>
#include <hamsandwich>
#include <fakemeta>
#include <engine>
#include <cstrike>
#include <ttt>
#include <cs_weapons_api>

new const g_szPriWeap[] = 
{
	CSW_SCOUT,
	CSW_XM1014,
	CSW_MAC10,
	CSW_UMP45,
	CSW_M249,
	CSW_M3,
	CSW_TMP,
	CSW_P90
};

new const g_szSecWeap[] = 
{
	CSW_P228,
	CSW_ELITE,
	CSW_FIVESEVEN,
	CSW_GLOCK18,
	CSW_DEAGLE
};

new const g_szPriAmmo[] = 
{
	90,
	32,
	100,
	100,
	200,
	32,
	120,
	100
};

new const g_szSecAmmo[] = 
{
	52,
	120,
	100,
	120,
	35
};

new cvar_give_nades;
public plugin_init()
{
	register_plugin("[TTT] Random weapon", TTT_VERSION, TTT_AUTHOR);
	RegisterHam(Ham_Spawn, "player", "Ham_Spawn_post", 1);
	cvar_give_nades = my_register_cvar("ttt_give_nades", "0", "Should anyone have free nades? (Default: 0)");
}

public Ham_Spawn_post(id)
{
	if(is_user_alive(id))
		give_random_weap(id);
}

public give_random_weap(id)
{
	strip_weapons(id);

	new pri = random_num(0, charsmax(g_szPriWeap));
	new sec = random_num(0, charsmax(g_szSecWeap));

	cswa_give_normal(id, g_szSecWeap[sec], -1, g_szSecAmmo[sec]);
	cswa_give_normal(id, g_szPriWeap[pri], -1, g_szPriAmmo[pri]);

	if(task_exists(id))
		remove_task(id);

	if(get_pcvar_num(cvar_give_nades))
		set_task(get_pcvar_num(get_cvar_pointer("ttt_preparation_time"))+10.0, "give_nade", id);
}

public give_nade(id)
	if(is_user_alive(id))
		ham_give_weapon(id, "weapon_hegrenade");