#include <amxmodx>
#include <engine>
#include <ttt_const>

new const g_szObjectives[][] = 
{
	"func_bomb_target",
	"info_bomb_target",
	"info_vip_start",
	"func_vip_safetyzone",
	"func_escapezone",
	"hostage_entity",
	"monster_scientist",
	"func_hostage_rescue",
	"armoury_entity",
	"game_player_equip",
	"player_weaponstrip",
	"trigger_camera",
	"info_hostage_rescue",
	"func_tank",
	"func_tankmortar"
};

public plugin_init()
{
	register_plugin("[TTT] Objective remover", TTT_VERSION, TTT_AUTHOR);
}

public pfn_spawn(ent)
{
	if(!is_valid_ent(ent))
		return PLUGIN_CONTINUE;

	static classname[32];
	entity_get_string(ent, EV_SZ_classname, classname, charsmax(classname));

	for(new i = 0; i < sizeof(g_szObjectives); i++)
	{
		if(equal(classname, g_szObjectives[i]))
		{
			remove_entity(ent);
			return PLUGIN_HANDLED;
		}
	}

	return PLUGIN_CONTINUE;
}