#include <amxmodx>
#include <cstrike>
#include <csx>

static const PLUGIN_NAME[] = "Bomb Plant Money Bonus"
static const PLUGIN_VERSION[] = "1.0"
static const PLUGIN_AUTHOR[] = "Locks"

new PCvarBonus

public plugin_init()
{
	register_plugin(PLUGIN_NAME, PLUGIN_VERSION, PLUGIN_AUTHOR)
	PCvarBonus = register_cvar("amx_plant_bonus", "150")
}

public bomb_planted(id)
{
	new money = cs_get_user_money(id)
	new bonus = get_pcvar_num(PCvarBonus)
	cs_set_user_money(id, money + bonus)
}