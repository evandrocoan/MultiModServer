/*

	Weapon Chance
	Version 2.8
	By Exolent
	
	Information about this plugin can be found at:
	http://forums.alliedmods.net/showthread.php?t=65370

*/

#include <amxmodx>
#include <amxmisc>
#include <fun>
#include <engine>
#include <cstrike>
#include <hamsandwich>


new const PLUGIN_NAME[] =	"Weapon Chance";
new const PLUGIN_VERSION[] =	"2.8";
new const PLUGIN_AUTHOR[] =	"Exolent";


#pragma semicolon 1


#define PISTOL_WEAPONS_BIT	(1<<CSW_GLOCK18|1<<CSW_USP|1<<CSW_DEAGLE|1<<CSW_P228|1<<CSW_FIVESEVEN|1<<CSW_ELITE)
#define SHOTGUN_WEAPONS_BIT	(1<<CSW_M3|1<<CSW_XM1014)
#define SUBMACHINE_WEAPONS_BIT	(1<<CSW_TMP|1<<CSW_MAC10|1<<CSW_MP5NAVY|1<<CSW_UMP45|1<<CSW_P90)
#define RIFLE_WEAPONS_BIT	(1<<CSW_FAMAS|1<<CSW_GALIL|1<<CSW_AK47|1<<CSW_SCOUT|1<<CSW_M4A1|1<<CSW_SG550|1<<CSW_SG552|1<<CSW_AUG|1<<CSW_AWP|1<<CSW_G3SG1)
#define MACHINE_WEAPONS_BIT	(1<<CSW_M249)

#define PRIMARY_WEAPONS_BIT	(SHOTGUN_WEAPONS_BIT|SUBMACHINE_WEAPONS_BIT|RIFLE_WEAPONS_BIT|MACHINE_WEAPONS_BIT)
#define SECONDARY_WEAPONS_BIT	(PISTOL_WEAPONS_BIT)

#define IsPrimaryWeapon(%1)	((1<<%1) & PRIMARY_WEAPONS_BIT)
#define IsSecondaryWeapon(%1)	((1<<%1) & SECONDARY_WEAPONS_BIT)

// include health, nightvision, armor, and defuser so that they can be given even with a shield

#define MISC_WEAPONS_BIT	(1<<CSW_HEGRENADE|1<<CSW_FLASHBANG|1<<CSW_SMOKEGRENADE|1<<CSW_KNIFE|1<<CSW_SHIELD|1<<CSW_HEALTH|1<<CSW_NIGHTVISION|1<<CSW_ARMOR|1<<CSW_DEFUSER)
#define SHIELD_WEAPONS_BIT	(SECONDARY_WEAPONS_BIT|MISC_WEAPONS_BIT)

#define is_shield_weapon(%1) ((SHIELD_WEAPONS_BIT & (1<<%1)) && %1 != CSW_ELITE)

new const g_weapon_names[][] =
{
	"", // NULL
	"weapon_p228",
	"weapon_shield",
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
	"weapon_p90",
	"weapon_armor",		// These only have weapon_ so the names are used in cvars and messages
	"weapon_nightvision",	// These only have weapon_ so the names are used in cvars and messages
	"weapon_defuser",	// These only have weapon_ so the names are used in cvars and messages
	"weapon_health"		// These only have weapon_ so the names are used in cvars and messages
};
#define CSW_SHIELD		2
#define CSW_ARMOR		31
#define CSW_NIGHTVISION		32
#define CSW_DEFUSER		33
#define CSW_HEALTH		34
#define MAX_WEAPONS sizeof(g_weapon_names)

new Trie:g_weapon_trie;

new const g_weapon_teams[MAX_WEAPONS] =
{
	0, 0, 2, 0, 0, 0, 1, 1, 2, 0, 1, 2, 0, 2, 1, 2, 0, 0, 0, 0, 0, 0, 2, 2, 1, 0, 0, 1, 1, 0, 0, 0, 0, 2, 0
};

new bool:g_an[MAX_WEAPONS];
new bool:g_plural[MAX_WEAPONS];

new g_weapon_names_short[MAX_WEAPONS][32];

#define WEAPON_CLIP	0
#define WEAPON_AMMO	1
new const g_weapon_maxammo[MAX_WEAPONS][2] =
{
	{0, 0}, // NULL
	{13, 52},
	{0, 0},
	{10, 90},
	{0, 1},
	{7, 32},
	{0, 0},
	{30, 100},
	{30, 90},
	{0, 1},
	{30, 120},
	{20, 100},
	{25, 100},
	{30, 90},
	{35, 90},
	{25, 90},
	{12, 100},
	{20, 120},
	{10, 30},
	{30, 120},
	{100, 200},
	{8, 32},
	{30, 90},
	{30, 120},
	{20, 90},
	{0, 2},
	{7, 35},
	{30, 90},
	{30, 90},
	{0, 0},
	{50, 100},
	{0, 0},
	{0, 0},
	{0, 0},
	{0, 0}
};

new wc_on;
new wc_delay;
new wc_prefix;
new wc_weaponcount;

new Array:g_weapon_type;
new Array:g_weapon_team;
new Array:g_weapon_chance;
new Array:g_weapon_clip;
new Array:g_weapon_ammo;
new Array:g_weapon_announce;
new g_total_weapons;

new g_weapon_on;
new Float:g_weapon_delay;
new g_weapon_count;
new g_weapon_prefix[16];

new bool:g_connected[33];

new g_msgid_Health;
new g_msgid_SayText;
new g_max_players;

new g_forward_giveitem;
new g_forward_hasitem;
new g_forward_message;

public plugin_init()
{
	register_plugin(PLUGIN_NAME, PLUGIN_VERSION, PLUGIN_AUTHOR);
	register_cvar("wc_version", PLUGIN_VERSION, FCVAR_SPONLY);
	
	new _1[] = "1";
	wc_on = register_cvar("wc_on", _1);
	wc_delay = register_cvar("wc_delay", _1);
	wc_weaponcount = register_cvar("wc_weaponcount", _1);
	wc_prefix = register_cvar("wc_prefix", "[CHANCE]");
	
	// you received a aug? no. you received an aug. :)
	g_an[CSW_HEGRENADE] = true;
	g_an[CSW_XM1014] = true;
	g_an[CSW_AUG] = true;
	g_an[CSW_ELITE] = true;
	g_an[CSW_UMP45] = true;
	g_an[CSW_SG550] = true;
	g_an[CSW_AWP] = true;
	g_an[CSW_MP5NAVY] = true;
	g_an[CSW_M249] = true;
	g_an[CSW_M3] = true;
	g_an[CSW_M4A1] = true;
	g_an[CSW_SG552] = true;
	g_an[CSW_AK47] = true;
	
	// you received an elite? no. you received elites. :)
	g_plural[CSW_ELITE] = true;
	
	g_weapon_trie = TrieCreate();
	
	new name[32];
	for( new i = 1; i < MAX_WEAPONS; i++ ) // 0 = NULL
	{
		copy(name, 31, g_weapon_names[i]);
		replace(name, 31, "weapon_", "");
		copy(g_weapon_names_short[i], 31, name);
		
		TrieSetCell(g_weapon_trie, name, i);
	}
	
	RegisterHam(Ham_Spawn, "player", "FwdPlayerSpawn", 1);
	
	register_logevent("EventRoundEnd", 2, "1=Round_End");
	register_event("TextMsg", "EventRoundEnd", "a", "2&#Game_C", "2&#Game_w");
	
	register_srvcmd("wc_add", "CmdAdd", -1, "<name> <chance> <team> <clip> <ammo> <announce>");
	register_concmd("wc_list", "CmdList", ADMIN_CVAR);
	
	g_msgid_Health = get_user_msgid("Health");
	g_msgid_SayText = get_user_msgid("SayText");
	g_max_players = get_maxplayers();
	
	g_weapon_type = ArrayCreate(1);
	g_weapon_team = ArrayCreate(1);
	g_weapon_chance = ArrayCreate(1);
	g_weapon_clip = ArrayCreate(1);
	g_weapon_ammo = ArrayCreate(1);
	g_weapon_announce = ArrayCreate(1);
	
	g_forward_giveitem = CreateMultiForward("wc_give_item", ET_STOP2, FP_CELL, FP_CELL);
	g_forward_hasitem = CreateMultiForward("wc_has_item", ET_STOP2, FP_CELL, FP_CELL);
	g_forward_message = CreateMultiForward("wc_format_message", ET_IGNORE, FP_CELL, FP_CELL, FP_ARRAY);
	
	// set the weapon chance variables for the first time
	set_task(1.0, "TaskExecuteConfig");
}

public plugin_natives()
{
	register_library("weapon_chance");
	
	register_native("wc_add", "_add");
}

public _add(plugin, params)
{
	if( params != 3 )
	{
		return -1;
	}
	
	if( get_func_id("wc_give_item", plugin) == -1
	||  get_func_id("wc_has_item", plugin) == -1
	||  get_func_id("wc_format_message", plugin) == -1 )
	{
		new filename[128];
		get_plugin(plugin, filename, 127);
		
		pause("ac", filename);
		
		log_amx("%s needs to have these public forwards: wc_give_item() , wc_has_item() , wc_format_message()", filename);
		
		return -1;
	}
	
	new team = clamp(get_param(1), 0, 2);
	new chance = clamp(get_param(2), 0, 100);
	new bool:announce = bool:!!get_param(3);
	
	ArrayPushCell(g_weapon_type, 0);
	ArrayPushCell(g_weapon_team, team);
	ArrayPushCell(g_weapon_chance, chance);
	ArrayPushCell(g_weapon_clip, g_total_weapons);
	ArrayPushCell(g_weapon_ammo, 0);
	ArrayPushCell(g_weapon_announce, announce);
	
	g_total_weapons++;
	
	return (g_total_weapons - 1);
}

public plugin_end()
{
	TrieDestroy(g_weapon_trie);
	ArrayDestroy(g_weapon_type);
	ArrayDestroy(g_weapon_team);
	ArrayDestroy(g_weapon_chance);
	ArrayDestroy(g_weapon_clip);
	ArrayDestroy(g_weapon_ammo);
	ArrayDestroy(g_weapon_announce);
	
	DestroyForward(g_forward_giveitem);
	DestroyForward(g_forward_hasitem);
	DestroyForward(g_forward_message);
}

public TaskExecuteConfig()
{
	new config[64];
	get_configsdir(config, sizeof(config) - 1);
	add(config, sizeof(config) - 1, "/weapon_chance.cfg");
	
	if( file_exists(config) )
	{
		server_cmd("exec %s", config);
		
		set_task(1.0, "EventRoundEnd"); // allow time for cvars to be set
	}
	else
	{
		EventRoundEnd();
		
		new f = fopen(config, "wt");
		
		fputs(f, "// This is where all the cvars and commands go for Weapon Chance^n");
		fputs(f, "// Information about the cvars and all weapon names can be found at:^n");
		fputs(f, "// http://forums.alliedmods.net/showthread.php?t=65370^n^n");
		
		fprintf(f, "wc_on %i^n", g_weapon_on);
		fprintf(f, "wc_delay %f^n", g_weapon_delay);
		fprintf(f, "wc_prefix ^"%s^"^n", g_weapon_prefix);
		fprintf(f, "wc_weaponcount %i^n^n", g_weapon_count);
		
		fputs(f, "// To add a weapon, use this format:^n//^n// wc_add <name> <chance> <team> <clip> <ammo> <announce>^n");
		fputs(f, "// Example: wc_add ^"deagle^" ^"50^" ^"0^" ^"7^" ^"0^" ^"1^"^n//^n// Remember for the teams:^n");
		fputs(f, "// 0 = Everyone, 1 = Terrorist, 2 = Counter-Terrorist^n//^n");
		fputs(f, "// The <announce> parameter is for telling all other players when one player receives a weapon.^n");
		fputs(f, "//^n// For health and armor, use the <ammo> parameter for the amount.^n//^n");
		
		// 11 = "Weapon Name"
		// 12 = "smokegrenade" (longest weapon name)
		// 11 = "nightvision" (second longest)
		// 12 = "Default Team"
		// 8 = "Max Clip"
		// 8 = "Max Ammo"
		
		fputs(f, "// Weapon Name  - Default Team - Max Clip - Max Ammo^n");
		
		for( new i = 1; i < MAX_WEAPONS; i++ )
		{
			fprintf(f, "// %-12.12s - %12i - %8i - %8i^n", g_weapon_names_short[i], g_weapon_teams[i], g_weapon_maxammo[i][WEAPON_CLIP], g_weapon_maxammo[i][WEAPON_AMMO]);
		}
		
		fputs(f, "^n^n");
		
		fclose(f);
	}
}

public client_putinserver(client)
{
	g_connected[client] = true;
}

public client_disconnect(client)
{
	remove_task(client);
	
	g_connected[client] = false;
}

public CmdAdd()
{
	if( read_argc() != 7 )
	{
		log_amx("Incorrect usage of wc_add.");
		log_amx("How to use: wc_add <name> <chance> <team> <clip> <ammo> <announce>");
		return PLUGIN_HANDLED;
	}
	
	static name[32], weapon;
	read_argv(1, name, sizeof(name) - 1);
	strtolower(name);
	
	if( TrieGetCell(g_weapon_trie, name, weapon) )
	{
		static arg[10];
		
		read_argv(2, arg, sizeof(arg) - 1);
		new chance = str_to_num(arg);
		
		if( chance < 0 ) return PLUGIN_HANDLED;
		if( chance > 100 )
		{
			chance = 100;
		}
		
		read_argv(3, arg, sizeof(arg) - 1);
		new team = str_to_num(arg);
		
		if( !(0 <= team <= 2) )
		{
			team = g_weapon_teams[weapon];
		}
		
		read_argv(4, arg, sizeof(arg) - 1);
		new clip = str_to_num(arg);
		
		read_argv(5, arg, sizeof(arg) - 1);
		new ammo = str_to_num(arg);
		
		if( weapon != CSW_ARMOR && weapon != CSW_HEALTH )
		{
			if( clip < 0 )
			{
				clip = 0;
			}
			else if( clip > g_weapon_maxammo[weapon][WEAPON_CLIP] )
			{
				clip = g_weapon_maxammo[weapon][WEAPON_CLIP];
			}
			
			if( ammo < 0 )
			{
				ammo = 0;
			}
			else if( ammo > g_weapon_maxammo[weapon][WEAPON_AMMO] )
			{
				ammo = g_weapon_maxammo[weapon][WEAPON_AMMO];
			}
		}
		
		read_argv(6, arg, sizeof(arg) - 1);
		new announce = str_to_num(arg);
		
		ArrayPushCell(g_weapon_type, weapon);
		ArrayPushCell(g_weapon_chance, chance);
		ArrayPushCell(g_weapon_team, team);
		ArrayPushCell(g_weapon_clip, clip);
		ArrayPushCell(g_weapon_ammo, ammo);
		ArrayPushCell(g_weapon_announce, announce);
		
		g_total_weapons++;
	}
	
	return PLUGIN_HANDLED;
}

public CmdList(client, level, cid)
{
	if( !cmd_access(client, level, cid, 1) ) return PLUGIN_HANDLED;
	
	console_print(client, "List of weapon chance's weapon names:");
	for( new i = 1; i < MAX_WEAPONS; i++ ) // 0 = NULL
	{
		console_print(client, "%s", g_weapon_names_short[i]);
	}
	
	return PLUGIN_HANDLED;
}

public EventRoundEnd()
{
	// save some memory?
	
	g_weapon_on = get_pcvar_num(wc_on);
	g_weapon_delay = floatmax(get_pcvar_float(wc_delay), 0.3);
	g_weapon_count = clamp(get_pcvar_num(wc_weaponcount), 0, MAX_WEAPONS - 1);
	get_pcvar_string(wc_prefix, g_weapon_prefix, 15);
}

public FwdPlayerSpawn(client)
{
	if( is_user_alive(client) )
	{
		if( g_weapon_on )
		{
			new CsTeams:team = cs_get_user_team(client);
			if( team != CS_TEAM_T && team != CS_TEAM_CT ) return;
			
			new param[2];
			param[0] = _:team;
			set_task(g_weapon_delay, "TaskGiveWeapons", client, param, 2);
		}
	}
}

public TaskGiveWeapons(param[], client)
{
	if( !g_weapon_count || !g_total_weapons ) return;
	
	new player_team = param[0];
	
	new Array:weapon_type = ArrayCreate(1);
	new Array:weapon_chance = ArrayCreate(1);
	new Array:weapon_clip = ArrayCreate(1);
	new Array:weapon_ammo = ArrayCreate(1);
	new Array:weapon_announce = ArrayCreate(1);
	new weapon_count;
	
	for( new i = 0; i < g_total_weapons; i++ )
	{
		if( (1<<ArrayGetCell(g_weapon_team, i)) & (1<<0|1<<player_team) )
		{
			ArrayPushCell(weapon_type, ArrayGetCell(g_weapon_type, i));
			ArrayPushCell(weapon_chance, ArrayGetCell(g_weapon_chance, i));
			ArrayPushCell(weapon_clip, ArrayGetCell(g_weapon_clip, i));
			ArrayPushCell(weapon_ammo, ArrayGetCell(g_weapon_ammo, i));
			ArrayPushCell(weapon_announce, ArrayGetCell(g_weapon_announce, i));
			
			weapon_count++;
		}
	}
	
	if( weapon_count )
	{
		new weapon;
		
		new given, total = min(g_weapon_count, weapon_count);
		
		new rand, i;
		while( given < total && weapon_count > 0 )
		{
			rand = random(weapon_count);
			weapon = ArrayGetCell(weapon_type, rand);
			i = 0;
			
			if( weapon == CSW_SHIELD && user_has_nonshield_weapon(client)
			|| !is_shield_weapon(weapon) && _user_has_weapon(client, CSW_SHIELD)
			|| (i = GiveWeapon(client, weapon, ArrayGetCell(weapon_chance, rand), ArrayGetCell(weapon_clip, rand), ArrayGetCell(weapon_ammo, rand), bool:ArrayGetCell(weapon_announce, rand))) >= 0 )
			{
				if( i == 1 )
				{
					given++;
				}
				
				ArrayDeleteItem(weapon_type, rand);
				ArrayDeleteItem(weapon_chance, rand);
				ArrayDeleteItem(weapon_clip, rand);
				ArrayDeleteItem(weapon_ammo, rand);
				ArrayDeleteItem(weapon_announce, rand);
				
				weapon_count--;
			}
		}
	}
	
	ArrayDestroy(weapon_type);
	ArrayDestroy(weapon_chance);
	ArrayDestroy(weapon_clip);
	ArrayDestroy(weapon_ammo);
	ArrayDestroy(weapon_announce);
}

bool:user_has_nonshield_weapon(client)
{
	new weapons[32], num;
	get_user_weapons(client, weapons, num);
	
	for( new i = 0; i < num; i++ )
	{
		if( !is_shield_weapon(weapons[i]) ) return true;
	}
	
	return false;
}

GiveWeapon(client, weapon, chance, clip, ammo, bool:announce)
{
	if( _user_has_weapon(client, weapon, clip) ) return 0;
	
	if( chance == 100 || random_num(1, 100) <= chance )
	{
		switch( weapon )
		{
			case 0:
			{
				new retval;
				ExecuteForward(g_forward_giveitem, retval, client, clip);
				
				if( retval )
				{
					return -1;
				}
			}
			case CSW_ARMOR:
			{
				if( ammo < 100 )
				{
					give_item(client, "item_kevlar");
					cs_set_user_armor(client, ammo, CS_ARMOR_KEVLAR);
				}
				else
				{
					give_item(client, "item_assaultsuit");
					cs_set_user_armor(client, ammo, CS_ARMOR_VESTHELM);
				}
			}
			case CSW_HEALTH:
			{
				set_user_health(client, ammo);
				
				message_begin(MSG_ONE, g_msgid_Health, _, client);
				write_byte(ammo);
				message_end();
			}
			case CSW_DEFUSER:
			{
				cs_set_user_defuse(client, 1);
			}
			case CSW_NIGHTVISION:
			{
				cs_set_user_nvg(client, 1);
			}
			case CSW_HEGRENADE, CSW_SMOKEGRENADE:
			{
				cs_set_user_bpammo(client, weapon, 1);
			}
			case CSW_FLASHBANG:
			{
				cs_set_user_bpammo(client, CSW_FLASHBANG, min(2, cs_get_user_bpammo(client, CSW_FLASHBANG) + ammo));
			}
			default:
			{
				new ent = give_item(client, g_weapon_names[weapon]);
				if( !is_valid_ent(ent) )
				{
					// not the player's fault or random number fault
					return -1;
				}
				
				if( g_weapon_maxammo[weapon][WEAPON_CLIP] )
				{
					cs_set_weapon_ammo(ent, clip);
				}
				
				if( g_weapon_maxammo[weapon][WEAPON_AMMO] )
				{
					cs_set_user_bpammo(client, weapon, ammo);
				}
				
				if( weapon == CSW_C4 )
				{
					cs_set_user_plant(client, 1);
				}
			}
		}
		
		new receive[128];
		
		if( g_plural[weapon] )
		{
			formatex(receive, 127, "received^x03 %ss^x01! (%i%% chance)", g_weapon_names_short[weapon], chance);
		}
		else
		{
			switch( weapon )
			{
				case 0:
				{
					new retval;
					ExecuteForward(g_forward_message, retval, client, clip, PrepareArray(receive, 64, 1));
					
					format(receive, 127, "received^x03 %s^x01! (%i%% chance)", receive, chance);
				}
				case CSW_HEGRENADE, CSW_FLASHBANG, CSW_SMOKEGRENADE:
				{
					formatex(receive, 127, "received^x03 %i %s%s^x01! (%i%% chance)", ammo, g_weapon_names_short[weapon], ammo > 1 ? "s" : "", chance);
				}
				case CSW_ARMOR:
				{
					formatex(receive, 127, "received^x03 %i armor^x01! (%i%% chance)", ammo, chance);
				}
				case CSW_HEALTH:
				{
					formatex(receive, 127, "received^x03 %i health^x01! (%i%% chance)", ammo, chance);
				}
				case CSW_NIGHTVISION:
				{
					formatex(receive, 127, "received^x03 nightvision^x01! (%i%% chance)", chance);
				}
				case CSW_DEFUSER:
				{
					formatex(receive, 127, "received^x03 a defuser kit^x01! (%i%% chance)", chance);
				}
				case CSW_KNIFE:
				{
					formatex(receive, 127, "received^x03 a knife^x01! (%i%% chance)", chance);
				}
				case CSW_C4:
				{
					formatex(receive, 127, "received^x03 a C4^x01! (%i%% chance)", chance);
				}
				default:
				{
					clip += ammo;
					
					formatex(receive, 127, "received^x03 a%s %s^x01 with^x03 %i bullet%s^x01! (%i%% chance)", g_an[weapon] ? "n" : "", g_weapon_names_short[weapon], clip, clip == 1 ? "" : "s", chance);
				}
			}
		}
		
		ChancePrint(client, "You %s", receive);
		
		if( announce )
		{
			new name[32];
			get_user_name(client, name, 31);
			
			for( new i = 1; i <= g_max_players; i++ )
			{
				if( i != client && g_connected[i] )
				{
					ChancePrint(i, "^x03%s^x01 %s", name, receive);
				}
			}
		}
		
		return 1;
	}
	
	return 0;
}

ChancePrint(client, const fmt[], any:...)
{ 
	new i = client ? client : GetPlayer();
	if( !i ) return;
	
	new message[256], len;
	if( g_weapon_prefix[0] )
	{
		len = formatex(message, 255, "^x04%s^x01 ", g_weapon_prefix);
	}
	vformat(message[len], 255-len, fmt, 3);
	message[192] = '^0';
	
	message_begin(client ? MSG_ONE : MSG_ALL, g_msgid_SayText, _, client);
	write_byte(i);
	write_string(message);
	message_end();
}

GetPlayer()
{
	for( new client = 1; client <= g_max_players; client++ )
	{
		if( g_connected[client] ) return client;
	}
	
	return 0;
}

bool:_user_has_weapon(client, weaponid, clip=0)
{
	switch( weaponid )
	{
		case 0:
		{
			new retval;
			ExecuteForward(g_forward_hasitem, retval, client, clip);
			
			if( retval )
			{
				return true;
			}
		}
		case CSW_HEGRENADE, CSW_SMOKEGRENADE:
		{
			if( cs_get_user_bpammo(client, weaponid) )
			{
				return true;
			}
		}
		case CSW_FLASHBANG:
		{
			if( cs_get_user_bpammo(client, CSW_FLASHBANG) == 2 )
			{
				return true;
			}
		}
		case CSW_SHIELD:
		{
			if( cs_get_user_shield(client) )
			{
				return true;
			}
		}
		case CSW_ARMOR, CSW_HEALTH:
		{
			return false;
		}
		case CSW_DEFUSER:
		{
			if( cs_get_user_defuse(client) )
			{
				return true;
			}
		}
		case CSW_NIGHTVISION:
		{
			if( cs_get_user_nvg(client) )
			{
				return true;
			}
		}
		case CSW_C4:
		{
			if( is_valid_ent(find_ent_by_owner(-1, "weapon_c4", client)) )
			{
				return true;
			}
		}
		default:
		{
			new weapons[32], num;
			get_user_weapons(client, weapons, num);
			
			new weapon;
			for( new i = 0; i < num; i++ )
			{
				weapon = weapons[i];
				
				if( weapon == weaponid
				|| IsPrimaryWeapon(weapon) && IsPrimaryWeapon(weaponid)
				|| IsSecondaryWeapon(weapon) && IsSecondaryWeapon(weaponid) )
				{
					return true;
				}
			}
		}
	}
	
	return false;
}
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1033\\ f0\\ fs16 \n\\ par }
*/
