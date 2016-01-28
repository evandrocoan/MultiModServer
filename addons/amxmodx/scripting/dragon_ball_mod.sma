/*===============================================================================================================
				  [Dragon Ball Z Mode]
				
				** Description of Mod: 
	      Each character has a power and has a different Transformation and which 
			has a similar power as Super Buu and Broly.
			
	\----------------------------------------------------------------------------------------/
			
			** Description of Characters (Heroes): 
		* Goku : 

			- Transformations and Attacks :
			Super Saiajin : Unleash a Simple Ki - Blast
			Super Saiajin 2 : Unleash an Simple Blue Kamehameha
			Super Saiajin 3 : Unleash an Dragon First
			Super Saiajin 4 : Unleash an Enhanced 10x Kamehameha
			Super Saiajin 5 : Unleash a Spirit Bomb
		
		* Vegeta :
		
			- Transformations and Attacks :
			Super Saiajin : Unleash a Simple Ki - Blast
			Super Saiajin 2 : Unleash an Garlic Gun
			Super Saiajin 3 : Unleash a Final Flash
			Super Saiajin 4 : Unleash a Final Shine Attack
		
		* Gohan : 
		
			- Transformations and Attacks :
			Attack 1 : Simple Unleash Ki - Blast 
			Super Saiajin : Unleash an Masenko
			Super Saiajin 2 : Unleash an Kamehameha
		
		* Krilin :
		
			- Attacks :
			Attack 1 : Unleash a Simple Ki - Blast
			Attack 2 : Unleash an Kamehameha
			Attack 3 : Unleash an Destruction Disc
		
		* Picolo :

			- Attacks :
			Attack 1 : Unleash a Simple Ki - Blast
			Attack 2 : Unleash an Masenko
			Attack 3 : Unleash a Special Beam Cannon
			
	\----------------------------------------------------------------------------------------/
			
			** Description of Character (Villains): 
			
		* Frieza :

			- Transformations and Attacks :
			1st Transformation : Unleash a Simple Ki - Blast
			Transformation 2 : Unleash a Death Beam
			Final Form : Unleash an Destruction Disc (Similar Krilin the only purple)
			100 % Power : Unleash a Death Ball
		
		* Cell:
		
			- Transformations and Attacks :
			Semi - Perfect Form : Unleash a Simple Ki - Blast
			Perfect Form : Unleash a Death Beam
			Super Perfect Form : Unleash a Green Kamehameha
		
		* Super Buu & Broly :
		
			- Attacks :
			Attack 1 : Unleash an Galitgun
			Attack 2 : Unleash a Final Flash
			Attack 3 : Unleash a Big Bang
			Attack 4 : Unleash a Death Ball
		
		* Omega Sheron (Or Li - Shen - Long) :
		
			- Transformations and Attacks :
			3 Dragon Balls Absorbed : Unleash a Simple Ki - Blast
			5 Dragon Balls Absorbed : Unleash an Dragon Thunder 
			All Dragon Balls Absorbed : Unleash an Minus Energy Power Ball
			
	\----------------------------------------------------------------------------------------/			
				  ** Credits:

		- Version Created By: [P]erfec[T] [S]cr[@]s[H]
		- Thanks Vittu For Goku Hero´s Code
		- Thanks green name for some sprites and sounds
		
	\----------------------------------------------------------------------------------------/
		
				** Change Log:
		v 1.0:
			* First Relase
				
		v 1.1: 
			* Fixed Some Bugs
			* Optimized Code
			* Added .cfg File

		v 1.2:
			* Fixed Health's Engine Bug
			* Fixed Bug of Reable Channel Overflow with powerup effect
			* Optimized Code

		v 1.3: (BIG UPDATE)
			* Added Player Models
			* Added Sounds of Attacks/Tranformations for all characters (Execpt Omega Shenron)
			* Added Knife Sound
			* Fixed Some Bugs
			* Etc.
		v 1.4:
			* Fixed Sounds
			* Use button in FM_emitsound
			* Fixed Some bugs
			* Added Join Spec Option
			* Added More Superbuu Models
	
======================================================================================================================*/

#include <amxmodx>
#include <amxmisc>
#include <fakemeta>
#include <engine>
#include <hamsandwich>
#include <cstrike>
#include <colorchat>

#define PLAYER_MODELS // Enable Player Models

// Hud Position (X, Y)
#define TRANSFORM_HUD_POS -1.0, 0.25
#define HUD_INFO_POS -1.0, 0.7

// CS Player PData Offsets (win32)
const PDATA_SAFE = 2
const OFFSET_CSMENUCODE = 205

// CS Weapon CBase Offsets (win32)
const OFFSET_WEAPONOWNER = 41

// Linux diff's
const OFFSET_LINUX = 5 // offsets 5 higher in Linux builds
const OFFSET_LINUX_WEAPONS = 4 // weapon offsets are only 4 steps higher on Linux

#if defined PLAYER_MODELS
#include <playermodel>
#define TASK_MODEL 31219283
#endif

#define PLUGIN "Dragon Ball Mod [Heroes vs Villains]"
#define VERSION "1.5"
#define AUTHOR "[P]erfec[T] [S]cr[@]s[H]"

#define is_user_valid_connected(%1) (1 <= %1 <= g_maxpl && is_user_connected(%1))
#define TASK_LOOP 2139812931
#define TASK_SHOWHUD 1293192
#define ID_SHOWHUD (taskid - TASK_SHOWHUD)
#define DBZ_KNIFE_V_MODEL "models/dbz_mod/v_knife_dbz.mdl" // Knife Model

new const HeroLangs[][] = { "NONE", "CHARACTER_GOKU", "CHARACTER_VEGETA", "CHARACTER_GOHAN", "CHARACTER_KRILLIN", "CHARACTER_PICCOLO"};
new const VillainLangs[][] = { "NONE", "CHARACTER_FRIEZA", "CHARACTER_CELL", "CHARACTER_BUU", "CHARACTER_BROLY", "CHARACTER_OMEGA"};

// General variables
new g_villain_id[33], g_hero_id[33], cvar_energy_for_second, cvar_energy_need, cvar_start_life_quantity, cvar_blast_decalls, cvar_powerup_effect
new g_power[4][33], g_max[2][33], g_energy_level[6], fw_gSpawn, spr[2], g_msg_syc, g_maxpl, cvar_bot_maxtime, cvar_bot_mintime

// Characters Cvars
new cvar_goku[10], cvar_frieza[8], cvar_vegeta[8], cvar_gohan[6], cvar_krilin[6], cvar_picolo[6], cvar_broly[8], cvar_superbuu[8], cvar_cell[6], cvar_omega_sheron[6]

static const g_burnDecal[3] = {28, 29, 30}
static const g_burnDecalBig[3] = {46, 47, 48}

new const Remove_Entities[][] = { "func_bomb_target", "info_bomb_target", "hostage_entity", "monster_scientist", "func_hostage_rescue", "info_hostage_rescue",
"info_vip_start", "func_vip_safetyzone", "func_escapezone"}

// Weapon entity names
new const wpn_ent_names[][] = { "", "weapon_p228", "", "weapon_scout", "weapon_hegrenade", "weapon_xm1014", "weapon_c4", "weapon_mac10", "weapon_aug", "weapon_smokegrenade", 
"weapon_elite", "weapon_fiveseven", "weapon_ump45", "weapon_sg550", "weapon_galil", "weapon_famas", "weapon_usp", "weapon_glock18", "weapon_awp", "weapon_mp5navy", "weapon_m249",
"weapon_m3", "weapon_m4a1", "weapon_tmp", "weapon_g3sg1", "weapon_flashbang", "weapon_deagle", "weapon_sg552", "weapon_ak47", "weapon_knife", "weapon_p90" }

#define MAX_TRAILS 15
new g_trail[MAX_TRAILS]
new const Trail_Sprs[MAX_TRAILS][] = { "sprites/dbz_mod/trail_yellow.spr", "sprites/dbz_mod/trail_blue.spr", "sprites/dbz_mod/trail_red.spr", "sprites/dbz_mod/dragon_first_trail.spr", "sprites/dbz_mod/broly_gallitgun_trail.spr", 
"sprites/dbz_mod/broly_final_flash_trail.spr", "sprites/dbz_mod/broly_big_bang_trail.spr", "sprites/dbz_mod/buu_gallitgun_trail.spr", "sprites/dbz_mod/buu_final_flash_trail.spr", "sprites/dbz_mod/buu_big_bang_trail.spr", 
"sprites/lgtning.spr", "sprites/muzzleflash2.spr", "sprites/dbz_mod/purpletrail.spr", "sprites/dbz_mod/gallitguntrail.spr", "sprites/dbz_mod/masenkotrail.spr" }

#define MAX_EXPLOSION 5
new g_explosion[MAX_EXPLOSION]
new const Exp_Sprs[MAX_EXPLOSION][] = { "sprites/dbz_mod/exp_yellow.spr", "sprites/dbz_mod/exp_blue.spr", "sprites/dbz_mod/exp_red.spr", "sprites/dbz_mod/purpleexplosion.spr", "sprites/dbz_mod/exp_green.spr" }

new const knife_sounds[][] = { "dbz_mod/knife_hit.wav", "dbz_mod/knife_hitstab.wav", "dbz_mod/knife_miss1.wav", "dbz_mod/knife_miss2.wav", "dbz_mod/knife_miss3.wav" }

#if defined PLAYER_MODELS
// Hero Player Models
new goku_models[][] = { "dbz_goku", "dbz_goku2", "dbz_goku2", "dbz_goku3", "dbz_goku4", "dbz_goku5" }
new vegeta_models[][] = { "dbz_vegeta", "dbz_vegeta2", "dbz_vegeta2", "dbz_vegeta3", "dbz_vegeta4" }
new gohan_models[][] = { "dbz_gohan", "dbz_gohan", "dbz_gohan_ssj", "dbz_gohan_ssj2" }
#define KRILLIN_MODEL "dbz_krillin"
#define PICCOLO_MODEL "dbz_piccolo"

// Villain Player Models
new frieza_models[][] = { "dbz_frieza", "dbz_frieza2", "dbz_frieza3", "dbz_frieza4", "dbz_frieza4"}
new cell_models[][] = { "dbz_cell1", "dbz_cell2", "dbz_cell3", "dbz_cell3" }
new broly_models[][] = { "dbz_broly2", "dbz_broly2", "dbz_broly2", "dbz_broly3", "dbz_broly4" }
new superbuu_models[][] = { "dbz_evilbuu", "dbz_superbuu", "dbz_superbuu2", "dbz_superbuu3", "dbz_kidbuu" }
#define OMEGASHENRON_MODEL "dbz_omegashenron"
#endif

/*===============================================================================
[Plugin Register]
================================================================================*/
public plugin_init() 
{
	register_plugin(PLUGIN, VERSION, AUTHOR) // Plugin Register
	register_cvar("dragon_ball_z_mod", VERSION, FCVAR_SERVER|FCVAR_UNLOGGED|FCVAR_SPONLY);
	
	register_dictionary("dragon_ball_mod.txt") // Lang Register

	// Events
	register_message(get_user_msgid("ShowMenu"), "message_show_menu")
	register_message(get_user_msgid("VGUIMenu"), "message_vgui_menu")
	register_menucmd(register_menuid("Terrorist_Select",1),511,"cmd_joinclass"); // Choose Team menu
	register_menucmd(register_menuid("CT_Select",1),511,"cmd_joinclass"); // Choose Team menu
	RegisterHam(Ham_Spawn, "player", "fwd_PlayerSpawn", 1)
	register_clcmd("chooseteam", "protecao3");
	register_clcmd("jointeam", "protecao_jointeam");
	register_message(get_user_msgid("StatusIcon"),	"Message_StatusIcon")
	register_forward(FM_EmitSound, "fw_EmitSound")
	register_forward(FM_Touch, "fwd_Touch")
	register_forward(FM_GetGameDescription, "fw_GetGameDescription")
	register_message(get_user_msgid("Health"), "message_health")
	unregister_forward(FM_Spawn, fw_gSpawn);

	for (new i = 1; i < sizeof wpn_ent_names; i++)
		if(wpn_ent_names[i][0]) RegisterHam(Ham_Item_Deploy, wpn_ent_names[i], "fw_Item_Deploy_Post", 1)
	
	// General Cvars
	cvar_energy_for_second = register_cvar("dbz_energy_for_second", "20") 	// Amount of energy to Earn Per Second
	cvar_energy_need = register_cvar("dbz_energy_need", "250")		// Amount of Energy Needed To Use Any Skill
	cvar_blast_decalls = register_cvar("dbz_blast_decals_enable", "1")
	cvar_start_life_quantity = register_cvar("dbz_start_life_on_spawn", "1000") // How life should begin when reviving
	cvar_powerup_effect = register_cvar("dbz_powerup_effect_enable", "1") // Enable Powerup Effect
	cvar_bot_maxtime = register_cvar("dbz_bot_power_maxtime", "20.0") // Time of Range for Bot use the powers
	cvar_bot_mintime = register_cvar("dbz_bot_power_mintime", "5.0")
	
	// Cvars - Goku	
	cvar_goku[0] = register_cvar("dbz_goku_damage_ki_blast", "50")		// Ki-Blast Damage
	cvar_goku[1] = register_cvar("dbz_goku_damage_kamehameha", "150")	// Kamehameha Damage
	cvar_goku[2] = register_cvar("dbz_goku_damage_dragon_first", "300")	// Dragon First Damage
	cvar_goku[3] = register_cvar("dbz_goku_damage_10x_kamehameha", "500")	// 10x Kamehameha Damage
	cvar_goku[4] = register_cvar("dbz_goku_damage_spirit_bomb", "700")	// Spirit Bomb Damage
	cvar_goku[5] = register_cvar("dbz_goku_radius_ki_blast", "100")		// Ki-Blast Radius
	cvar_goku[6] = register_cvar("dbz_goku_radius_kamehameha", "300")	// Kamehameha Radius
	cvar_goku[7] = register_cvar("dbz_goku_radius_dragon_first", "700")	// Dragon First Radius
	cvar_goku[8] = register_cvar("dbz_goku_radius_10x_kamehameha", "1000")	// 10x Kamehameha Radius
	cvar_goku[9] = register_cvar("dbz_goku_radius_spirit_bomb", "1500")	// Spirit Bomb Radius
	
	// Cvars - Vegeta
	cvar_vegeta[0] = register_cvar("dbz_goku_vegeta_damage_ki_blast", "50")			// Ki-Blast Damage
	cvar_vegeta[1] = register_cvar("dbz_goku_vegeta_damage_garlic_gun", "150")			// Garlic Gun Damage
	cvar_vegeta[2] = register_cvar("dbz_goku_vegeta_damage_final_flash", "300")			// Final Flash Damage
	cvar_vegeta[3] = register_cvar("dbz_goku_vegeta_damage_final_shine_attack", "500")		// Final Shine Attack Damage
	cvar_vegeta[4] = register_cvar("dbz_goku_vegeta_radius_ki_blast", "100")			// Ki-Blast Radius
	cvar_vegeta[5] = register_cvar("dbz_goku_vegeta_radius_garlic_gun", "300")			// Garlic Gun Radius
	cvar_vegeta[6] = register_cvar("dbz_goku_vegeta_radius_final_flash", "700")			// Final Flash Radius
	cvar_vegeta[7] = register_cvar("dbz_goku_vegeta_radius_final_shine_attack", "1000")		// Final Shine Attack Radius
	
	// Cvars - Gohan	
	cvar_gohan[0] = register_cvar("dbz_gohan_damage_ki_blast", "50")		// Ki-Blast Damage
	cvar_gohan[1] = register_cvar("dbz_gohan_damage_masenko", "150")		// Masenko Damage
	cvar_gohan[2] = register_cvar("dbz_gohan_damage_kamehameha", "300")		// Kamehameha Damage
	cvar_gohan[3] = register_cvar("dbz_gohan_radius_ki_blast", "100")		// Ki-Blast Radius
	cvar_gohan[4] = register_cvar("dbz_gohan_radius_masenko", "200")		// Masenko Radius
	cvar_gohan[5] = register_cvar("dbz_gohan_radius_kamehameha", "500")		// Kamehameha Radius
	
	// Cvars - Krillin	
	cvar_krilin[0] = register_cvar("dbz_krilin_damage_ki_blast", "50")		// Ki-Blast Damage
	cvar_krilin[1] = register_cvar("dbz_krilin_damage_kamehameha", "150")		// Kamehameha Damage
	cvar_krilin[2] = register_cvar("dbz_krilin_damage_destruction_disc", "300")	// Destrucion Disc Damage
	cvar_krilin[3] = register_cvar("dbz_krilin_radius_ki_blast", "100")		// Ki-Blast Radius
	cvar_krilin[4] = register_cvar("dbz_krilin_radius_kamehameha", "200")		// Kamehameha Radius
	cvar_krilin[5] = register_cvar("dbz_krilin_radius_destruction_disc", "500")	// Destrucion Disc Radius
	
	// Cvars - Picolo	
	cvar_picolo[0] = register_cvar("dbz_picolo_damage_ki_blast", "50")			// Ki-Blast Damage
	cvar_picolo[1] = register_cvar("dbz_picolo_damage_masenko", "150")		// Masenko Damage
	cvar_picolo[2] = register_cvar("dbz_picolo_damage_special_bean_cannon", "300")	// Special Bean Cannon Damage
	cvar_picolo[3] = register_cvar("dbz_picolo_radius_ki_blast", "100")		// Ki-Blast Radius
	cvar_picolo[4] = register_cvar("dbz_picolo_radius_masenko", "200")		// Masenko Radius
	cvar_picolo[5] = register_cvar("dbz_picolo_radius_special_bean_cannon", "500")	// Special Bean Cannon Radius
	
	// Cvars - Frieza
	cvar_frieza[0] = register_cvar("dbz_goku_frieza_damage_ki_blast", "50")		// Ki-Blast Damage
	cvar_frieza[1] = register_cvar("dbz_goku_frieza_damage_death_beam", "150")		// Death Beam Damage
	cvar_frieza[2] = register_cvar("dbz_goku_frieza_damage_destruction_disc", "300")	// Destrucion Disc Damage
	cvar_frieza[3] = register_cvar("dbz_goku_frieza_damage_death_ball", "500")		// Death Ball Damage
	cvar_frieza[4] = register_cvar("dbz_goku_frieza_radius_ki_blast", "100")		// Ki-Blast Radius
	cvar_frieza[5] = register_cvar("dbz_goku_frieza_radius_death_beam", "300")		// Death Beam Radius
	cvar_frieza[6] = register_cvar("dbz_goku_frieza_radius_destruction_disc", "700")	// Destrucion Disc Radius
	cvar_frieza[7] = register_cvar("dbz_goku_frieza_radius_death_ball", "1000")		// Death Ball Radius

	// Cvars - Broly
	cvar_broly[0] = register_cvar("dbz_goku_broly_damage_galitgun", "50")	// Galitgun Damage
	cvar_broly[1] = register_cvar("dbz_goku_broly_damage_final_flash", "150")	// Final Flash Damage
	cvar_broly[2] = register_cvar("dbz_goku_broly_damage_big_bang", "300")	// Big Bang Damage
	cvar_broly[3] = register_cvar("dbz_goku_broly_damage_death_ball", "500")	// Death Ball Damage
	cvar_broly[4] = register_cvar("dbz_goku_broly_radius_ki_blast", "100")	// Galitgun Radius
	cvar_broly[5] = register_cvar("dbz_goku_broly_radius_final_flash", "300")	// Final Flash Radius
	cvar_broly[6] = register_cvar("dbz_goku_broly_radius_big_bang", "700")	// Big Bang Radius
	cvar_broly[7] = register_cvar("dbz_goku_broly_radius_death_ball", "1000")	// Death Ball Radius
	
	// Cvars - Super Buu
	cvar_superbuu[0] = register_cvar("dbz_goku_superbuu_damage_galitgun", "50")		// Galitgun Damage
	cvar_superbuu[1] = register_cvar("dbz_goku_superbuu_damage_final_flash", "150")	// Final Flash Damage
	cvar_superbuu[2] = register_cvar("dbz_goku_superbuu_damage_big_bang", "300")	// Big Bang Damage
	cvar_superbuu[3] = register_cvar("dbz_goku_superbuu_damage_death_ball", "500")	// Death Ball Damage
	cvar_superbuu[4] = register_cvar("dbz_goku_superbuu_radius_ki_blast", "100")	// Galitgun Radius
	cvar_superbuu[5] = register_cvar("dbz_goku_superbuu_radius_final_flash", "300")	// Final Flash Radius
	cvar_superbuu[6] = register_cvar("dbz_goku_superbuu_radius_big_bang", "700")	// Big Bang Radius
	cvar_superbuu[7] = register_cvar("dbz_goku_superbuu_radius_death_ball", "1000")	// Death Ball Radius
	
	// Cvars - Cell	
	cvar_cell[0] = register_cvar("dbz_cell_damage_ki_blast", "50")		// Ki-Blast Damage
	cvar_cell[1] = register_cvar("dbz_cell_damage_death_beam", "150")		// Death Beam Damage
	cvar_cell[2] = register_cvar("dbz_cell_damage_kamehameha", "300")		// Kamehameha Damage
	cvar_cell[3] = register_cvar("dbz_cell_radius_ki_blast", "100")		// Ki-Blast Radius
	cvar_cell[4] = register_cvar("dbz_cell_radius_death_beam", "200")		// Death Beam Radius
	cvar_cell[5] = register_cvar("dbz_cell_radius_kamehameha", "500")		// Kamehameha Radius
	
	// Cvars - Omega Sheron	
	cvar_omega_sheron[0] = register_cvar("dbz_omega_sheron_damage_ki_blast", "50")			// Ki-Blast Damage
	cvar_omega_sheron[1] = register_cvar("dbz_omega_sheron_damage_dragon_thunder", "150")		// Dragon Thunder Damage
	cvar_omega_sheron[2] = register_cvar("dbz_omega_sheron_damage_minus_energy_power_ball", "700")	// Minus Energy Power Ball Damage
	cvar_omega_sheron[3] = register_cvar("dbz_omega_sheron_radius_ki_blast", "100")			// Ki-Blast Radius
	cvar_omega_sheron[4] = register_cvar("dbz_omega_sheron_radius_dragon_thunder", "200")		// Dragon Thunder Radius
	cvar_omega_sheron[5] = register_cvar("dbz_omega_sheron_radius_minus_energy_power_ball", "1000")	// Minus Energy Power Ball Radius
	
	g_msg_syc = CreateHudSyncObj()
	g_maxpl = get_maxplayers()
}

/*===============================================================================
[Plugin Natives]
================================================================================*/
public plugin_natives()
{
	register_native("dbz_get_user_energy", "native_get_user_energy", 1)
	register_native("dbz_set_user_energy", "native_set_user_energy", 1)
	register_native("dbz_get_user_hero_id", "native_get_user_hero_id", 1)
	register_native("dbz_get_user_villain_id", "native_get_user_villain_id", 1)
	register_native("dbz_get_energy_level", "native_get_energy_level", 1)
	register_native("dbz_set_energy_level", "native_set_energy_level", 1)
}

/*===============================================================================
[Game Description]
================================================================================*/
public fw_GetGameDescription()
{
	// Return the mod name so it can be easily identified
	forward_return(FMV_STRING, "Dragon Ball Z Mod v1.5")
	return FMRES_SUPERCEDE;
}

/*===============================================================================
[Plugin Precache]
================================================================================*/
public plugin_precache()
{
	precache_sound("dbz_mod/goku_ki_blast.wav")
	precache_sound("dbz_mod/goku_kamehameha.wav")
	precache_sound("dbz_mod/goku_10x_kamehameha.wav")
	precache_sound("dbz_mod/goku_spirit_bomb.wav")
	precache_sound("dbz_mod/goku_powerup1.wav")
	precache_sound("dbz_mod/goku_powerup2.wav")
	precache_sound("dbz_mod/goku_powerup3.wav")
	precache_sound("dbz_mod/goku_powerup4.wav")
	precache_sound("dbz_mod/goku_powerup5.wav")
	precache_sound("dbz_mod/frieza_powerup1.wav")
	precache_sound("dbz_mod/frieza_powerup2.wav")
	precache_sound("dbz_mod/frieza_powerup3.wav")
	precache_sound("dbz_mod/frieza_powerup4.wav")
	precache_sound("dbz_mod/frieza_deathball.wav")
	precache_sound("dbz_mod/vegeta_powerup1.wav")
	precache_sound("dbz_mod/vegeta_powerup2.wav")
	precache_sound("dbz_mod/vegeta_powerup3.wav")
	precache_sound("dbz_mod/vegeta_powerup4.wav")	
	precache_sound("dbz_mod/gallitgunfire.wav")
	precache_sound("dbz_mod/vegeta_finalflash.wav")
	precache_sound("dbz_mod/gohan_powerup1.wav")
	precache_sound("dbz_mod/gohan_powerup2.wav")
	precache_sound("dbz_mod/gohan_powerup3.wav")
	precache_sound("dbz_mod/gohan_masenko.wav")
	precache_sound("dbz_mod/ssjgohan_kamehameha.wav")
	precache_sound("dbz_mod/krillin_powerup1.wav")
	precache_sound("dbz_mod/krillin_powerup2.wav")
	precache_sound("dbz_mod/krillin_kamehameha.wav")
	precache_sound("dbz_mod/krillin_destructodisc.wav")
	precache_sound("dbz_mod/cell_powerup1.wav")
	precache_sound("dbz_mod/cell_powerup2.wav")
	precache_sound("dbz_mod/cell_powerup3.wav")
	precache_sound("dbz_mod/cell_kamehameha.wav")
	precache_sound("dbz_mod/superbuu_galitgun.wav")
	precache_sound("dbz_mod/superbuu_finalflashb_fix.wav")
	precache_sound("dbz_mod/superbuu_bigbang.wav")
	precache_sound("dbz_mod/superbuu_deathball_fix.wav")
	precache_sound("dbz_mod/superbuu_powerup1_fix.wav")
	precache_sound("dbz_mod/superbuu_powerup2.wav")
	precache_sound("dbz_mod/superbuu_powerup3.wav")
	precache_sound("dbz_mod/frieza_destructodisc.wav")
	precache_sound("dbz_mod/piccolo_masenko.wav")
	precache_sound("dbz_mod/specialbeamcannon.wav")
	precache_sound("dbz_mod/piccolo_powerup1.wav")
	precache_sound("dbz_mod/piccolo_powerup2.wav")
	precache_sound("dbz_mod/piccolo_powerup3.wav")
	precache_sound("player/pl_pain2.wav")
	precache_sound("dbz_mod/broly_galitgun.wav")
	precache_sound("dbz_mod/broly_finalflashb.wav")
	precache_sound("dbz_mod/broly_bigbang.wav")
	precache_sound("dbz_mod/broly_deathball.wav")
	precache_sound("dbz_mod/broly_powerup1.wav")
	precache_sound("dbz_mod/broly_powerup2.wav")
	precache_sound("dbz_mod/broly_powerup3.wav")
	precache_sound("dbz_mod/broly_powerup4.wav")	
	
	spr[1] = precache_model("sprites/dbz_mod/powerup.spr")
	spr[0] = precache_model("sprites/wall_puff4.spr")
	
	precache_model("sprites/dbz_mod/ki_blast.spr")
	precache_model("sprites/dbz_mod/kamehameha_blue.spr")
	precache_model("sprites/dbz_mod/kamehameha_red.spr")
	precache_model("sprites/dbz_mod/spirit_bomb.spr")	
	precache_model("sprites/dbz_mod/masenkob.spr")
	precache_model("sprites/dbz_mod/dragon_first.spr")
	precache_model("sprites/dbz_mod/special_bean.spr")
	precache_model("models/dbz_mod/kurilin_disc.mdl")
	precache_model("sprites/dbz_mod/frieza_deathball.spr")
	precache_model("models/dbz_mod/frieza_friezadisc.mdl")
	precache_model("sprites/dbz_mod/broly_final_flash_charge.spr")
	precache_model("sprites/dbz_mod/broly_big_bang.spr")
	precache_model("sprites/dbz_mod/broly_death_ball.spr")
	precache_model("sprites/dbz_mod/buu_gallitgun.spr")
	precache_model("sprites/dbz_mod/buu_final_flash_charge.spr")
	precache_model("sprites/dbz_mod/buu_big_bang.spr")
	precache_model("sprites/dbz_mod/buu_death_ball.spr")
	precache_model("sprites/dbz_mod/green_kamehameha.spr")
	precache_model("sprites/dbz_mod/gallitgunb.spr")
	precache_model("sprites/dbz_mod/minus_enegy_power_ball.spr")
	precache_model("sprites/nhth1.spr")

	precache_model(DBZ_KNIFE_V_MODEL)
	
	new i
	for(i = 0; i < MAX_EXPLOSION; i++) {
		g_explosion[i] = precache_model(Exp_Sprs[i])
	}
	for(i = 0; i < MAX_TRAILS; i++) {
		g_trail[i] = precache_model(Trail_Sprs[i])
	}
	for (i = 0; i < sizeof knife_sounds; i++) {
		precache_sound(knife_sounds[i])
	}

	// Player Models
	#if defined PLAYER_MODELS
	for (i = 0; i < sizeof goku_models; i++) {
		precache_playermodel(goku_models[i])
	}

	for (i = 0; i < sizeof vegeta_models; i++) {
		precache_playermodel(vegeta_models[i])
	}

	for (i = 0; i < sizeof gohan_models; i++) {
		precache_playermodel(gohan_models[i])
	}
	
	precache_playermodel(KRILLIN_MODEL)
	precache_playermodel(PICCOLO_MODEL)

	for (i = 0; i < sizeof frieza_models; i++) {
		precache_playermodel(frieza_models[i])
	}

	for (i = 0; i < sizeof cell_models; i++) {
		precache_playermodel(cell_models[i])
	}

	for (i = 0; i < sizeof broly_models; i++) {
		precache_playermodel(broly_models[i])
	}

	for (i = 0; i < sizeof superbuu_models; i++) {
		precache_playermodel(superbuu_models[i])
	}
	
	precache_playermodel(OMEGASHENRON_MODEL)
	#endif

	fw_gSpawn = register_forward(FM_Spawn, "fw_Spawn")
}

/*===============================================================================
[Remove Unecessary Entities]
================================================================================*/
public fw_Spawn(entity)
{
	// Invalid entity
	if (!pev_valid(entity)) return FMRES_IGNORED;
	
	// Get classname
	new classname[32]; pev(entity, pev_classname, classname, charsmax(classname))
	
	// Check whether it needs to be removed
	for (new i = 0; i < sizeof(Remove_Entities); i++)
	{
		if (equal(classname, Remove_Entities[i]))
		{
			engfunc(EngFunc_RemoveEntity, entity)
			return FMRES_SUPERCEDE;
		}
	}
	
	return FMRES_IGNORED;
}	

/*===============================================================================
[Reset Variables When Player Spawn]
================================================================================*/
public fwd_PlayerSpawn(id)
{
	if(!is_user_alive(id))
		return

	if (g_power[3][id] > 0) 
		remove_power(id, g_power[3][id]);
	
	g_power[2][id] = 0
	g_power[0][id] = 0
	
	#if defined PLAYER_MODELS
	model_update(id)
	#endif
	
	// Bug Prevention on Auto Balance
	if(g_villain_id[id] > 0 && cs_get_user_team(id) == CS_TEAM_CT) {
		g_villain_id[id] = 0
		g_hero_id[id] = random_num(1,5) 
	}
	if(g_hero_id[id] > 0 && cs_get_user_team(id) == CS_TEAM_T) {
		g_hero_id[id] = 0
		g_villain_id[id] = random_num(1,5) 
	}
	
	ColorChat(id, id, "^4--==^3 Dragon Ball Z Mod %s By: [P]erfec[T] [S]cr[@]s[H] ^4==--", VERSION) // Show Credits
	client_cmd(id, "stopsound") // Stop sounds
	
	set_user_health(id, get_pcvar_num(cvar_start_life_quantity))
	
	new iwpn, iwpns[32], nwpn[32];
	get_user_weapons ( id, iwpns, iwpn );
	for ( new a = 0; a < iwpn; ++a ) {
		get_weaponname ( iwpns[a], nwpn, 31 ); // Use Knifes Only
		engclient_cmd ( id, "drop", nwpn );
	}
	
	if(!task_exists(id+TASK_LOOP))
		set_task(1.0, "dbz_loop", id+TASK_LOOP, "", 0, "b");

	// Bot Suport
	if(is_user_bot(id)) {
		if(cs_get_user_team(id) == CS_TEAM_T) g_villain_id[id] = random_num(1,5); // Choose villain automatically
		
		if(cs_get_user_team(id) == CS_TEAM_CT) g_hero_id[id] = random_num(1,5); // Choose hero automatically
		
		remove_task(id)
		set_task(random_float(get_pcvar_float(cvar_bot_mintime), get_pcvar_float(cvar_bot_maxtime)), "use_power", id, _, _, "b") // For Bots use the Powers
	}
}


public Message_StatusIcon(iMsgId, MSG_DEST, id) 
{ 
	static szIcon[5] 
	get_msg_arg_string(2, szIcon, 4) 
	if(szIcon[0] == 'b' && szIcon[2] == 'y' && szIcon[3] == 'z') 
	{ 
		if(get_msg_arg_int(1)) { 
			fm_cs_set_user_nobuy(id) 
			return PLUGIN_HANDLED;
		} 
	}  
	return PLUGIN_CONTINUE;
}
/*===============================================================================
[For Use the Powers]
================================================================================*/
public use_power(id)
{
	if(!is_user_alive(id))
		return

	if (g_power[2][id] < g_energy_level[0]) {
		ColorChat(id, GREY, "^4%L^1 %L", id, "DBZ_TAG", id, "DONT_HAVE_ENERGY")
		return
	}
	if(g_power[3][id]){
		ColorChat(id, GREY, "^4%L^1 %L", id, "DBZ_TAG", id, "ONE_POWER_BY_TIME")
		return
	}
	
	if(g_hero_id[id] > 0) {
		switch(g_hero_id[id])
		{
			// Goku
			case 1: {
				
				if (g_power[2][id] >= g_energy_level[0] && g_power[2][id] < g_energy_level[1]) {
					ColorChat(id, GREY, "^4%L^1 Ki Blast!", id, "DBZ_TAG")
					emit_sound(id, CHAN_STATIC, "dbz_mod/goku_ki_blast.wav", 0.8, ATTN_NORM, 0, PITCH_NORM)
					g_power[2][id] -= g_energy_level[0]
					g_max[1][id] = get_pcvar_num(cvar_goku[0])
					g_max[0][id] = get_pcvar_num(cvar_goku[5])
					g_power[1][id] = 1
				}
				else if (g_power[2][id] >= g_energy_level[1] && g_power[2][id] < g_energy_level[2]) {
					ColorChat(id, GREY, "^4%L^1 Kamehameha!!", id, "DBZ_TAG")
					// Wish this sound was shorter
					emit_sound(id, CHAN_STATIC, "dbz_mod/goku_kamehameha.wav", 0.8, ATTN_NORM, 0, PITCH_NORM)
					g_power[2][id] -= g_energy_level[1]
					g_max[1][id] = get_pcvar_num(cvar_goku[1])
					g_max[0][id] = get_pcvar_num(cvar_goku[6])
					g_power[1][id] = 2
				}
				else if (g_power[2][id] >= g_energy_level[2] && g_power[2][id] < g_energy_level[3]) {
					ColorChat(id, GREY, "^4%L^1 Dragon First!!!", id, "DBZ_TAG")
					g_power[2][id] -= g_energy_level[2]
					g_max[1][id] = get_pcvar_num(cvar_goku[2])
					g_max[0][id] = get_pcvar_num(cvar_goku[7])
					g_power[1][id] = 3
				}
				else if (g_power[2][id] >= g_energy_level[3] && g_power[2][id] < g_energy_level[4]) {
					ColorChat(id, GREY, "^4%L^1 10x Kamehameha!!!", id, "DBZ_TAG")
					emit_sound(id, CHAN_STATIC, "dbz_mod/goku_10x_kamehameha.wav", 0.8, ATTN_NORM, 0, PITCH_NORM)
					g_power[2][id] -= g_energy_level[3]
					g_max[1][id] = get_pcvar_num(cvar_goku[3])
					g_max[0][id] = get_pcvar_num(cvar_goku[8])
					g_power[1][id] = 4
				}
				else if (g_power[2][id] >= g_energy_level[4]) {
					set_rendering(id)
					ColorChat(id, GREY, "^4%L^1 Spirit Bomb!!!!", id, "DBZ_TAG")
					emit_sound(id, CHAN_STATIC, "dbz_mod/goku_spirit_bomb.wav", 0.8, ATTN_NORM, 0, PITCH_NORM)
					g_power[2][id] -= g_energy_level[4]
					g_max[1][id] = get_pcvar_num(cvar_goku[4])
					g_max[0][id] = get_pcvar_num(cvar_goku[9])
					g_power[1][id] = 5
				}
				create_power(id)
			}
			
			// Vegeta
			case 2:	{
				if (g_power[2][id] >= g_energy_level[0] && g_power[2][id] < g_energy_level[1]) {
					ColorChat(id, GREY, "^4%L^1 Ki Blast!", id, "DBZ_TAG")
					emit_sound(id, CHAN_STATIC, "dbz_mod/goku_ki_blast.wav", 0.8, ATTN_NORM, 0, PITCH_NORM)
					g_power[2][id] -= g_energy_level[0]
					g_max[1][id] = get_pcvar_num(cvar_vegeta[0])
					g_max[0][id] = get_pcvar_num(cvar_vegeta[4])
					g_power[1][id] = 1
				}
				else if (g_power[2][id] >= g_energy_level[1] && g_power[2][id] < g_energy_level[2]) {
					ColorChat(id, GREY, "^4%L^1 Garlic Gun !!", id, "DBZ_TAG")
					emit_sound(id, CHAN_STATIC, "dbz_mod/gallitgunfire.wav", 0.8, ATTN_NORM, 0, PITCH_NORM)
					g_power[2][id] -= g_energy_level[1]
					g_max[1][id] = get_pcvar_num(cvar_vegeta[1])
					g_max[0][id] = get_pcvar_num(cvar_vegeta[5])
					g_power[1][id] = 2
				}
				else if (g_power[2][id] >= g_energy_level[2] && g_power[2][id] < g_energy_level[3]) {
					ColorChat(id, GREY, "^4%L^1 Final Flash !!!", id, "DBZ_TAG")
					g_power[2][id] -= g_energy_level[2]
					g_max[1][id] = get_pcvar_num(cvar_vegeta[2])
					g_max[0][id] = get_pcvar_num(cvar_vegeta[6])
					emit_sound(id, CHAN_STATIC, "dbz_mod/vegeta_finalflash.wav", 0.8, ATTN_NORM, 0, PITCH_NORM)
					g_power[1][id] = 3
				}
				else if (g_power[2][id] >= g_energy_level[3]) {
					ColorChat(id, GREY, "^4%L^1 Final Shine Attack!!!", id, "DBZ_TAG")
					g_power[2][id] -= g_energy_level[3]
					g_max[1][id] = get_pcvar_num(cvar_vegeta[3])
					g_max[0][id] = get_pcvar_num(cvar_vegeta[7])
					g_power[1][id] = 4
				}
				create_power(id)
			}
			
			// Gohan
			case 3:	{
				if (g_power[2][id] >= g_energy_level[0] && g_power[2][id] < g_energy_level[1]) {
					ColorChat(id, GREY, "^4%L^1 Ki Blast!", id, "DBZ_TAG")
					emit_sound(id, CHAN_STATIC, "dbz_mod/goku_ki_blast.wav", 0.8, ATTN_NORM, 0, PITCH_NORM)
					g_power[2][id] -= g_energy_level[0]
					g_max[1][id] = get_pcvar_num(cvar_gohan[0])
					g_max[0][id] = get_pcvar_num(cvar_gohan[3])
					g_power[1][id] = 1
				}
				else if (g_power[2][id] >= g_energy_level[1] && g_power[2][id] < g_energy_level[2]) {
					ColorChat(id, GREY, "^4%L^1 Masenko!!", id, "DBZ_TAG")
					emit_sound(id, CHAN_STATIC, "dbz_mod/gohan_masenko.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
					g_power[2][id] -= g_energy_level[1]
					g_max[1][id] = get_pcvar_num(cvar_gohan[1])
					g_max[0][id] = get_pcvar_num(cvar_gohan[4])
					g_power[1][id] = 2
				}
				else if (g_power[2][id] >= g_energy_level[2]) {
					ColorChat(id, GREY, "^4%L^1 Kamehameha!!!", id, "DBZ_TAG")
					emit_sound(id, CHAN_STATIC, "dbz_mod/ssjgohan_kamehameha.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
					g_power[2][id] -= g_energy_level[2]
					g_max[1][id] = get_pcvar_num(cvar_gohan[2])
					g_max[0][id] = get_pcvar_num(cvar_gohan[5])
					g_power[1][id] = 3
				}
				create_power(id)
			}
			
			// Krilin
			case 4:	{
				if (g_power[2][id] >= g_energy_level[0] && g_power[2][id] < g_energy_level[1]) {
					ColorChat(id, GREY, "^4%L^1 Ki Blast!", id, "DBZ_TAG")
					emit_sound(id, CHAN_STATIC, "dbz_mod/goku_ki_blast.wav", 0.8, ATTN_NORM, 0, PITCH_NORM)
					g_power[2][id] -= g_energy_level[0]
					g_max[1][id] = get_pcvar_num(cvar_krilin[0])
					g_max[0][id] = get_pcvar_num(cvar_krilin[3])
					g_power[1][id] = 1
				}
				else if (g_power[2][id] >= g_energy_level[1] && g_power[2][id] < g_energy_level[2]) {
					ColorChat(id, GREY, "^4%L^1 Kamehameha !!", id, "DBZ_TAG")
					g_power[2][id] -= g_energy_level[1]
					g_max[1][id] = get_pcvar_num(cvar_krilin[1])
					g_max[0][id] = get_pcvar_num(cvar_krilin[4])
					g_power[1][id] = 2
					emit_sound(id, CHAN_STATIC, "dbz_mod/krillin_kamehameha.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
				}
				else if (g_power[2][id] >= g_energy_level[2]) {
					ColorChat(id, GREY, "^4%L^1 Destrucion Disc !!!", id, "DBZ_TAG")
					g_power[2][id] -= g_energy_level[2]
					g_max[1][id] = get_pcvar_num(cvar_krilin[2])
					g_max[0][id] = get_pcvar_num(cvar_krilin[5])
					g_power[1][id] = 3
					emit_sound(id, CHAN_STATIC, "dbz_mod/krillin_destructodisc.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
				}
				create_power(id)
			}
			
			// Picolo
			case 5:	{
				if (g_power[2][id] >= g_energy_level[0] && g_power[2][id] < g_energy_level[1]) {
					ColorChat(id, GREY, "^4%L^1 Ki Blast!", id, "DBZ_TAG")
					emit_sound(id, CHAN_STATIC, "dbz_mod/goku_ki_blast.wav", 0.8, ATTN_NORM, 0, PITCH_NORM)
					g_power[2][id] -= g_energy_level[0]
					g_max[1][id] = get_pcvar_num(cvar_picolo[0])
					g_max[0][id] = get_pcvar_num(cvar_picolo[3])
					g_power[1][id] = 1
				}
				else if (g_power[2][id] >= g_energy_level[1] && g_power[2][id] < g_energy_level[2]) {
					ColorChat(id, GREY, "^4%L^1 Masenko !!!", id, "DBZ_TAG")
					emit_sound(id, CHAN_STATIC, "dbz_mod/piccolo_masenko.wav", 0.8, ATTN_NORM, 0, PITCH_NORM)
					g_power[2][id] -= g_energy_level[2]
					g_max[1][id] = get_pcvar_num(cvar_picolo[1])
					g_max[0][id] = get_pcvar_num(cvar_picolo[4])
					g_power[1][id] = 2
				}
				else if (g_power[2][id] >= g_energy_level[2]) {
					ColorChat(id, GREY, "^4%L^1 Special Bean Cannon!!", id, "DBZ_TAG")
					emit_sound(id, CHAN_STATIC, "dbz_mod/specialbeamcannon.wav", 0.8, ATTN_NORM, 0, PITCH_NORM)
					g_power[2][id] -= g_energy_level[1]
					g_max[1][id] = get_pcvar_num(cvar_picolo[2])
					g_max[0][id] = get_pcvar_num(cvar_picolo[5])
					g_power[1][id] = 3
				}
				create_power(id)
			}
		}
	}
	else {
		switch(g_villain_id[id])
		{
			// Frieza
			case 1:	{
				if (g_power[2][id] >= g_energy_level[0] && g_power[2][id] < g_energy_level[1]) {
					ColorChat(id, GREY, "^4%L^1 Ki Blast!", id, "DBZ_TAG")
					emit_sound(id, CHAN_STATIC, "dbz_mod/goku_ki_blast.wav", 0.8, ATTN_NORM, 0, PITCH_NORM)
					g_power[2][id] -= g_energy_level[0]
					g_max[1][id]  = get_pcvar_num(cvar_frieza[0])
					g_max[0][id] = get_pcvar_num(cvar_frieza[4])
					g_power[1][id] = 1
				}
				else if (g_power[2][id] >= g_energy_level[1] && g_power[2][id] < g_energy_level[2]) {
					ColorChat(id, GREY, "^4%L^1 Death Beam!!", id, "DBZ_TAG")
					g_power[2][id] -= g_energy_level[1]
					g_max[1][id]  = get_pcvar_num(cvar_frieza[1])
					g_max[0][id] = get_pcvar_num(cvar_frieza[5])
					g_power[1][id] = 2
				}
				else if (g_power[2][id] >= g_energy_level[2] && g_power[2][id] < g_energy_level[3]) {
					ColorChat(id, GREY, "^4%L^1 Destrucion Disc !!!", id, "DBZ_TAG")
					emit_sound(id, CHAN_STATIC, "dbz_mod/frieza_destructodisc.wav", 0.8, ATTN_NORM, 0, PITCH_NORM)
					g_power[2][id] -= g_energy_level[2]
					g_max[1][id]  = get_pcvar_num(cvar_frieza[2])
					g_max[0][id] = get_pcvar_num(cvar_frieza[6])
					g_power[1][id] = 3
				}
				else if (g_power[2][id] >= g_energy_level[3]) {
					ColorChat(id, GREY, "^4%L^1 Death Ball!!!", id, "DBZ_TAG")
					g_power[2][id] -= g_energy_level[3]
					g_max[1][id]  = get_pcvar_num(cvar_frieza[3])
					g_max[0][id] = get_pcvar_num(cvar_frieza[7])
					g_power[1][id] = 4
					emit_sound(id, CHAN_STATIC, "dbz_mod/frieza_deathball.wav", 0.8, ATTN_NORM, 0, PITCH_NORM)
				}
				create_power(id)
			}
		
			// Cell
			case 2:	{
				if (g_power[2][id] >= g_energy_level[0] && g_power[2][id] < g_energy_level[1]) {
					ColorChat(id, GREY, "^4%L^1 Ki Blast!", id, "DBZ_TAG")
					emit_sound(id, CHAN_STATIC, "dbz_mod/goku_ki_blast.wav", 0.8, ATTN_NORM, 0, PITCH_NORM)
					g_power[2][id] -= g_energy_level[0]
					g_max[1][id] = get_pcvar_num(cvar_cell[0])
					g_max[0][id] = get_pcvar_num(cvar_cell[3])
					g_power[1][id] = 1
				}
				else if (g_power[2][id] >= g_energy_level[1] && g_power[2][id] < g_energy_level[2]) {
					ColorChat(id, GREY, "^4%L^1 Death Beam !!", id, "DBZ_TAG")
					g_power[2][id] -= g_energy_level[1]
					g_max[1][id] = get_pcvar_num(cvar_cell[1])
					g_max[0][id] = get_pcvar_num(cvar_cell[4])
					g_power[1][id] = 2
				}
				else if (g_power[2][id] >= g_energy_level[2]) {
					ColorChat(id, GREY, "^4%L^1 Kamehameha !!!", id, "DBZ_TAG")
					g_power[2][id] -= g_energy_level[2]
					g_max[1][id] = get_pcvar_num(cvar_cell[2])
					g_max[0][id] = get_pcvar_num(cvar_cell[5])
					g_power[1][id] = 3
					emit_sound(id, CHAN_STATIC, "dbz_mod/cell_kamehameha.wav", 0.8, ATTN_NORM, 0, PITCH_NORM)
				}
				create_power(id)
			}
			// Super Buu
			case 3: {
				if (g_power[2][id] >= g_energy_level[0] && g_power[2][id] < g_energy_level[1]) {
					ColorChat(id, GREY, "^4%L^1 Ki Blast!", id, "DBZ_TAG")
					emit_sound(id, CHAN_STATIC, "dbz_mod/superbuu_galitgun.wav", 1.0, ATTN_NORM, 0, PITCH_NORM)
					g_power[2][id] -= g_energy_level[0]
					g_max[1][id] = get_pcvar_num(cvar_superbuu[0])
					g_max[0][id] = get_pcvar_num(cvar_superbuu[4])
					g_power[1][id] = 1
				}
				else if (g_power[2][id] >= g_energy_level[1] && g_power[2][id] < g_energy_level[2]) {
					ColorChat(id, GREY, "^4%L^1 Final Flash!!", id, "DBZ_TAG")
					emit_sound(id, CHAN_STATIC, "dbz_mod/superbuu_finalflashb_fix.wav", 1.0, ATTN_NORM, 0, PITCH_NORM)
					g_power[2][id] -= g_energy_level[1]
					g_max[1][id] = get_pcvar_num(cvar_superbuu[1])
					g_max[0][id] = get_pcvar_num(cvar_superbuu[5])
					g_power[1][id] = 2
				}
				else if (g_power[2][id] >= g_energy_level[2] && g_power[2][id] < g_energy_level[3]) {
					ColorChat(id, GREY, "^4%L^1 Big Bang!!!", id, "DBZ_TAG")
					emit_sound(id, CHAN_STATIC, "dbz_mod/superbuu_bigbang.wav", 1.0, ATTN_NORM, 0, PITCH_NORM)
					g_power[2][id] -= g_energy_level[2]
					g_max[1][id] = get_pcvar_num(cvar_superbuu[2])
					g_max[0][id] = get_pcvar_num(cvar_superbuu[6])
					g_power[1][id] = 3
				}
				else if (g_power[2][id] >= g_energy_level[3]) {
					ColorChat(id, GREY, "^4%L^1 Deathball!!!", id, "DBZ_TAG")
					emit_sound(id, CHAN_STATIC, "dbz_mod/superbuu_deathball_fix.wav", 1.0, ATTN_NORM, 0, PITCH_NORM)
					g_power[2][id] -= g_energy_level[3]
					g_max[1][id] = get_pcvar_num(cvar_superbuu[3])
					g_max[0][id] = get_pcvar_num(cvar_superbuu[7])
					g_power[1][id] = 4
				}
				create_power(id)
			}
			
			// Broly
			case 4:	{
				if (g_power[2][id] >= g_energy_level[0] && g_power[2][id] < g_energy_level[1]) {
					ColorChat(id, GREY, "^4%L^1 Ki Blast!", id, "DBZ_TAG")
					g_power[2][id] -= g_energy_level[0]
					g_max[1][id] = get_pcvar_num(cvar_broly[0])
					g_max[0][id] = get_pcvar_num(cvar_broly[4])
					g_power[1][id] = 1
				}
				else if (g_power[2][id] >= g_energy_level[1] && g_power[2][id] < g_energy_level[2]) {
					ColorChat(id, GREY, "^4%L^1 Final Flash!!", id, "DBZ_TAG")
					emit_sound(id, CHAN_STATIC, "dbz_mod/broly_finalflashb.wav", 1.0, ATTN_NORM, 0, PITCH_NORM)
					g_power[2][id] -= g_energy_level[1]
					g_max[1][id] = get_pcvar_num(cvar_broly[1])
					g_max[0][id] = get_pcvar_num(cvar_broly[5])
					g_power[1][id] = 2
				}
				else if (g_power[2][id] >= g_energy_level[2] && g_power[2][id] < g_energy_level[3]) {
					ColorChat(id, GREY, "^4%L^1 Big Bang!!!", id, "DBZ_TAG")
					emit_sound(id, CHAN_STATIC, "dbz_mod/broly_bigbang.wav", 1.0, ATTN_NORM, 0, PITCH_NORM)
					g_power[2][id] -= g_energy_level[2]
					g_max[1][id] = get_pcvar_num(cvar_broly[2])
					g_max[0][id] = get_pcvar_num(cvar_broly[6])
					g_power[1][id] = 3
				}
				else if (g_power[2][id] >= g_energy_level[3]) {
					ColorChat(id, GREY, "^4%L^1 Deathball!!!", id, "DBZ_TAG")
					emit_sound(id, CHAN_STATIC, "dbz_mod/broly_deathball.wav", 1.0, ATTN_NORM, 0, PITCH_NORM)
					g_power[2][id] -= g_energy_level[3]
					g_max[1][id] = get_pcvar_num(cvar_broly[3])
					g_max[0][id] = get_pcvar_num(cvar_broly[7])
					g_power[1][id] = 4
				}
				create_power(id)
			}
			
			// Omega Sheron
			case 5: {
				if (g_power[2][id] >= g_energy_level[0] && g_power[2][id] < g_energy_level[1]) {
					ColorChat(id, GREY, "^4%L^1 Ki Blast!", id, "DBZ_TAG")
					emit_sound(id, CHAN_STATIC, "dbz_mod/goku_ki_blast.wav", 0.8, ATTN_NORM, 0, PITCH_NORM)
					g_power[2][id] -= g_energy_level[0]
					g_max[1][id] = get_pcvar_num(cvar_omega_sheron[0])
					g_max[0][id] = get_pcvar_num(cvar_omega_sheron[3])
					g_power[1][id] = 1
				}
				else if (g_power[2][id] >= g_energy_level[1] && g_power[2][id] < g_energy_level[2]) {
					ColorChat(id, GREY, "^4%L^1 Dragon Thunder !!", id, "DBZ_TAG")
					g_power[2][id] -= g_energy_level[1]
					g_max[1][id] = get_pcvar_num(cvar_omega_sheron[1])
					g_max[0][id] = get_pcvar_num(cvar_omega_sheron[4])
					g_power[1][id] = 2
				}
				else if (g_power[2][id] >= g_energy_level[2]) {
					ColorChat(id, GREY, "^4%L^1 Minus Energy Power Ball !!!", id, "DBZ_TAG")
					g_power[2][id] -= g_energy_level[2]
					g_max[1][id] = get_pcvar_num(cvar_omega_sheron[2])
					g_max[0][id] = get_pcvar_num(cvar_omega_sheron[5])
					g_power[1][id] = 3
				}
				create_power(id)
			}
		}
	}
}

/*===============================================================================
[Some Protections]
================================================================================*/
public fwd_Touch(ent, id)
{
	if (!is_user_alive(id) || !pev_valid(ent)) return FMRES_IGNORED;
	
	static szEntModel[32]; pev(ent , pev_model , szEntModel , 31); 
	if (contain(szEntModel, "w_") != -1) return FMRES_SUPERCEDE; // Don't Pick Weapons on ground
	
	return FMRES_IGNORED;
}

public message_show_menu(msgid, dest, id) 
{	
	if(g_villain_id[id] <= 0 && g_hero_id[id] <= 0) return PLUGIN_HANDLED
	
	static team_select[] = "#Team_Select"
	
	static menu_text_code[sizeof team_select]
	get_msg_arg_string(4, menu_text_code, sizeof menu_text_code - 1)
	
	if (!equal(menu_text_code, team_select)) return PLUGIN_CONTINUE
	
	static param_menu_msgid[2]
	param_menu_msgid[0] = msgid
	
	set_force_team_join_task(id, msgid)
	
	return PLUGIN_HANDLED
}

public message_vgui_menu(msgid, dest, id) 
{	
	if (get_msg_arg_int(1) != 2 || g_villain_id[id] <= 0 && g_hero_id[id] <= 0) return PLUGIN_CONTINUE
	
	static param_menu_msgid[2]
	param_menu_msgid[0] = msgid
	
	set_force_team_join_task(id, msgid)
	
	return PLUGIN_HANDLED
}

set_force_team_join_task(id, menu_msgid) 
{
	static param_menu_msgid[2]
	param_menu_msgid[0] = menu_msgid
	set_task(0.1, "task_force_team_join", id, param_menu_msgid, sizeof param_menu_msgid)
}

public task_force_team_join(menu_msgid[], id) 
{	
	static msg_block; msg_block = get_msg_block(menu_msgid[0])
	
	set_msg_block(menu_msgid[0], BLOCK_SET)
	set_msg_block(menu_msgid[0], msg_block)
}

/*===============================================================================
[Reset variables If the player connects or disconnects]
================================================================================*/
public client_putinserver(id)
{
	if (g_power[3][id] > 0)	remove_power(id, g_power[3][id]);
	g_villain_id[id] = 0
	g_hero_id[id] = 0
	g_power[2][id] = 0
	g_power[0][id] = 0

	if(!is_user_bot(id)) set_task(1.0, "ShowHUD", id+TASK_SHOWHUD, _, _, "b")
}

public client_disconnect(id)
{
	if (g_power[3][id] > 0)	remove_power(id, g_power[3][id]);

	g_villain_id[id] = 0
	g_hero_id[id] = 0
	g_power[2][id] = 0
	g_power[0][id] = 0
	remove_task(id)
	remove_task(id+TASK_LOOP)
	remove_task(id+TASK_SHOWHUD)
	#if defined PLAYER_MODELS
	remove_task(id+TASK_MODEL)
	#endif
}
/*===============================================================================
[Some Protections]
================================================================================*/
public protecao_jointeam(id)
{
	static Team; Team = get_user_team(id)
	if(Team == 0 || Team == 3 || g_hero_id[id] <= 0 && g_villain_id[id] <= 0) {
		menu_choose_team(id)
		return PLUGIN_HANDLED
	}

	return PLUGIN_CONTINUE
}

public protecao3(id) {
	menu_choose_team(id)
	return PLUGIN_HANDLED
}

public cmd_joinclass(id) return PLUGIN_HANDLED;

/*===============================================================================
[Choose Team Menu]
================================================================================*/
public menu_choose_team(id)
{
	new szText[2000 char]
	formatex(szText, charsmax(szText), "%L %L", id, "MENU_DBZ_TAG", id, "CHOSE_TEAM_MENU_TITLE");

	new menu = menu_create(szText, "menu_choose_team_handler")

	formatex(szText, charsmax(szText), "%L", id, "CHOSE_TEAM_MENU_ITEM1");
	menu_additem(menu, szText, "1", 0)
	
	formatex(szText, charsmax(szText), "%L^n", id, "CHOSE_TEAM_MENU_ITEM2");
	menu_additem(menu, szText, "2", 0)
	
	formatex(szText, charsmax(szText), "%L", id, "CHOSE_TEAM_MENU_ITEM3");
	menu_additem(menu, szText, "3", 0)
	
	menu_setprop(menu, MPROP_EXIT, MEXIT_ALL)
	
	if(g_hero_id[id] == 0 && g_villain_id[id] == 0) menu_setprop(menu, MPROP_EXIT, MEXIT_NEVER)
	
	// Fix for AMXX custom menus
	if (pev_valid(id) == PDATA_SAFE)
		set_pdata_int(id, OFFSET_CSMENUCODE, 0, OFFSET_LINUX)

	menu_display(id, menu, 0)
}

public menu_choose_team_handler(id, menu, item)
{
	new data[6], iName[64], access, callback
	menu_item_getinfo(menu, item, access, data, 5, iName, 63, callback)
	new key = str_to_num(data)
	
	if(item == MENU_EXIT)
	{
		menu_destroy(menu)
		return PLUGIN_HANDLED
	}
	
	switch(key) {
		case 1: choose_character(id, 1)
		case 2: choose_character(id, 0)
		case 3: {
			if(is_user_alive(id))
				dllfunc(DLLFunc_ClientKill, id)
				
			cs_set_user_team(id, CS_TEAM_SPECTATOR)
		}
	}

	menu_destroy(menu)
	return PLUGIN_HANDLED
}

/*===============================================================================
[Choose Character Menu]
================================================================================*/
public choose_character(id, team)
{
	new szText[2000 char], szItem[10]

	formatex(szText, charsmax(szText), "%L %L", id, "MENU_DBZ_TAG", id, team == 1 ? "CHOSE_VILAN_MENU" : "CHOSE_HERO_MENU");
	new menu = menu_create(szText, team == 1 ? "choose_vilain_handler" : "choose_hero_handler")
	
	for (new i = 1; i < (team == 1 ? sizeof VillainLangs : sizeof HeroLangs); i++) {
		formatex(szText, charsmax(szText), "%L", id, team == 1 ? VillainLangs[i] : HeroLangs[i])
		num_to_str(i, szItem, charsmax(szItem))
		menu_additem(menu, szText, szItem, 0)
	}
	
	menu_setprop(menu, MPROP_EXIT, MEXIT_ALL)
	
	// Fix for AMXX custom menus
	if (pev_valid(id) == PDATA_SAFE)
		set_pdata_int(id, OFFSET_CSMENUCODE, 0, OFFSET_LINUX)
	
	menu_display(id, menu, 0)
}


public choose_vilain_handler(id, menu, item)
{
	if(item == MENU_EXIT)
	{
		menu_destroy(menu)
		return PLUGIN_HANDLED
	}
	
	new data[6], iName[64], access, callback
	menu_item_getinfo(menu, item, access, data, 5, iName, 63, callback)
	new key = str_to_num(data)
	
	if(g_hero_id[id] > 0 || g_villain_id[id] != key)
	{
		if (g_power[3][id] > 0)	remove_power(id, g_power[3][id]);
		if(is_user_alive(id)) dllfunc(DLLFunc_ClientKill, id);
			
		g_hero_id[id] = 0
		g_power[2][id] = 0
		g_power[0][id] = 0
		cs_set_user_team(id, CS_TEAM_T)
		g_villain_id[id] = key
		ColorChat(id, GREY, "^4%L^1 %L", id, "DBZ_TAG", id, "CHOSED_CHARACTER", id, VillainLangs[g_villain_id[id]])
	}
	engclient_cmd(id,"jointeam","1") 
	engclient_cmd(id,"joinclass","1")
	menu_destroy(menu)
	return PLUGIN_HANDLED
}

public choose_hero_handler(id, menu, item)
{
	if(item == MENU_EXIT)
	{
		menu_destroy(menu)
		return PLUGIN_HANDLED
	}
	
	new data[6], iName[64], access, callback
	menu_item_getinfo(menu, item, access, data, 5, iName, 63, callback)
	new key = str_to_num(data)
	
	if(g_villain_id[id] > 0 || g_hero_id[id] != key)
	{
		if (g_power[3][id] > 0) remove_power(id, g_power[3][id]);
		if(is_user_alive(id)) dllfunc(DLLFunc_ClientKill, id);
			
		g_villain_id[id] = 0
		g_power[2][id] = 0
		g_power[0][id] = 0
		cs_set_user_team(id, CS_TEAM_CT)

		g_hero_id[id] = key
		ColorChat(id, GREY, "^4%L^1 %L", id, "DBZ_TAG", id, "CHOSED_CHARACTER", id, HeroLangs[g_hero_id[id]])
	}

	engclient_cmd(id,"jointeam","2") 
	engclient_cmd(id,"joinclass","2")
	menu_destroy(menu)
	return PLUGIN_HANDLED
}

/*=======================================================================
[HUD Info Task]
=======================================================================*/
public ShowHUD(taskid)
{
	static id
	id = ID_SHOWHUD;
	
	// Player died?
	if (!is_user_alive(id))
	{
		// Get spectating target
		id = pev(id, pev_iuser2)
		
		// Target not alive
		if (!is_user_alive(id)) return;
	}
	
	new sName[32]; get_user_name(id, sName, charsmax(sName))
		
	switch(cs_get_user_team(id)) {
		case CS_TEAM_T: {
			set_hudmessage(255, 69, 0, HUD_INFO_POS, 0, 0.0, 1.1, 0.0, 0.0, 2)
			ShowSyncHudMsg(ID_SHOWHUD, g_msg_syc, "%L", ID_SHOWHUD, "HUD_INFO", sName, id, VillainLangs[g_villain_id[id]], get_user_health(id), g_power[2][id], g_power[0][id])
		}
		case CS_TEAM_CT: {
			set_hudmessage(0, 255, 255, HUD_INFO_POS, 0, 0.0, 1.1, 0.0, 0.0, 2)
			ShowSyncHudMsg(ID_SHOWHUD, g_msg_syc, "%L", ID_SHOWHUD, "HUD_INFO", sName, id, HeroLangs[g_hero_id[id]], get_user_health(id), g_power[2][id], g_power[0][id])
		}
	}
}

/*===============================================================================
[Create Entity Power]
================================================================================*/
public create_power(id)
{
	new Float:vOrigin[3], Float:vAngles[3], Float:vAngle[3], entModel[60]
	new Float:entScale, Float:entSpeed, trailModel, trailLength, trailWidth, allow_trail, allow_guide, big_attack
	new Float:VecMins[3] = {-1.0,-1.0,-1.0}
	new Float:VecMaxs[3] = {1.0,1.0,1.0}
	new trail_r, trail_g, trail_b, ismdl
	trail_r = 255; trail_g = 255; trail_b = 255; ismdl = 0
	
	g_power[0][id] = 0
	
	// Seting entSpeed higher then 2000.0 will not go where you aim
	// Vec Mins/Maxes must be below +-5.0 to make a burndecal
	if(g_hero_id[id] > 0)
	{
		switch(g_hero_id[id]) 
		{
			// Goku
			case 1:	{
				switch(g_power[1][id])
				{
					// Ki-Blast
					case 1:{
						entModel = "sprites/dbz_mod/ki_blast.spr"
						entScale = 0.20; entSpeed = 2000.0; big_attack = false
						allow_trail = true; trailModel = g_trail[0]; allow_guide = false
						trailLength = 1; trailWidth = 2
					}
					// Kamehameha
					case 2:{
						entModel = "sprites/dbz_mod/kamehameha_blue.spr"
						entScale = 1.20; entSpeed = 1500.0; big_attack = false
						allow_trail = true; trailModel = g_trail[1]
						trailLength = 100; trailWidth = 8; allow_guide = true
						VecMins[0] = -2.0; VecMins[1] = -2.0; VecMins[2] = -2.0;
						VecMaxs[0] = 2.0; VecMaxs[1] = 2.0; VecMaxs[2] = 2.0
					}
					// Dragon First
					case 3:{
						entModel = "sprites/dbz_mod/dragon_first.spr"
						entScale = 2.00; entSpeed = 1500.0; big_attack = false
						allow_trail = true; trailModel = g_trail[3]
						trailLength = 100; trailWidth = 16; allow_guide = true
						VecMins[0] = -3.0; VecMins[1] = -3.0; VecMins[2] = -3.0;
						VecMaxs[0] = 3.0; VecMaxs[1] = 3.0; VecMaxs[2] = 3.0
					}
					// 10x Kamehameha
					case 4:{
						entModel = "sprites/dbz_mod/kamehameha_red.spr"
						entScale = 2.00; entSpeed = 1000.0; big_attack = false
						allow_trail = true; trailModel = g_trail[2]
						trailLength = 100; trailWidth = 16; allow_guide = true
						VecMins[0] = -3.0; VecMins[1] = -3.0; VecMins[2] = -3.0;
						VecMaxs[0] = 3.0; VecMaxs[1] = 3.0; VecMaxs[2] = 3.0
					}
					// Spirit Bomb
					case 5:{
						entModel = "sprites/dbz_mod/spirit_bomb.spr"
						entScale = 0.70; entSpeed = 800.0; big_attack = true
						VecMins[0] = -4.0; VecMins[1] = -4.0; VecMins[2] = -4.0
						VecMaxs[0] = 4.0; VecMaxs[1] = 4.0; VecMaxs[2] = 4.0
						allow_trail = false; allow_guide = false
					}
				}
			}
			
			// Vegeta
			case 2: {
				switch(g_power[1][id])
				{
					// Ki-Blast
					case 1:{
						entModel = "sprites/dbz_mod/gallitgunb.spr"
						entScale = 0.20; entSpeed = 2000.0; big_attack = false
						allow_trail = true; trailModel = g_trail[13]; allow_guide = false
						trailLength = 1; trailWidth = 2
					}
					
					// Garlic Gun
					case 2:{
						entModel = "sprites/dbz_mod/gallitgunb.spr"
						entScale = 1.20; entSpeed = 1500.0; trailModel = g_trail[13]
						trailLength = 100; trailWidth = 8; big_attack = false
						allow_guide = true; allow_trail = true
						VecMins[0] = -2.0; VecMins[1] = -2.0; VecMins[2] = -2.0
						VecMaxs[0] = 2.0; VecMaxs[1] = 2.0; VecMaxs[2] = 2.0
					}
					
					// Final Flash
					case 3:{
						entModel = "sprites/dbz_mod/broly_final_flash_charge.spr"
						entScale = 0.60; entSpeed = 1600.0; trailModel = g_trail[0]
						trailLength = 100; trailWidth = 8; big_attack = false
						allow_guide = true; allow_trail = true
						VecMins[0] = -2.0; VecMins[1] = -2.0; VecMins[2] = -2.0
						VecMaxs[0] = 2.0; VecMaxs[1] = 2.0; VecMaxs[2] = 2.0
					}
			
					// Final Shine Attack
					case 4:{
						entModel = "sprites/dbz_mod/green_kamehameha.spr"
						entScale = 1.0; entSpeed = 1050.0; trailModel = g_trail[6]
						trailLength = 100; trailWidth = 16; allow_guide = true
						allow_trail = true; big_attack = false
						VecMins[0] = -3.0; VecMins[1] = -3.0; VecMins[2] = -3.0
						VecMaxs[0] = 3.0; VecMaxs[1] = 3.0; VecMaxs[2] = 3.0
					}
				}
			}
			
			// Gohan
			case 3: {
				switch(g_power[1][id])
				{
					// Ki-Blast
					case 1:{
						entModel = "sprites/dbz_mod/ki_blast.spr"
						entScale = 0.20; entSpeed = 2000.0; big_attack = false
						allow_trail = true; trailModel = g_trail[0]; allow_guide = false
						trailLength = 1; trailWidth = 2
					}
					
					// Masenko
					case 2:{
						entModel = "sprites/dbz_mod/masenkob.spr"
						entScale = 1.20; entSpeed = 1500.0; big_attack = false
						allow_guide = true; allow_trail = true; trailModel = g_trail[14]
						trailLength = 100; trailWidth = 8
						VecMins[0] = -2.0; VecMins[1] = -2.0; VecMins[2] = -2.0
						VecMaxs[0] = 2.0; VecMaxs[1] = 2.0; VecMaxs[2] = 2.0
					}
					
					// Kamehameha
					case 3:{
						entModel = "sprites/dbz_mod/kamehameha_blue.spr"
						entScale = 1.20; entSpeed = 1500.0; big_attack = false
						allow_trail = true; trailModel = g_trail[1]
						trailLength = 100; trailWidth = 8; allow_guide = true
						VecMins[0] = -2.0; VecMins[1] = -2.0; VecMins[2] = -2.0;
						VecMaxs[0] = 2.0; VecMaxs[1] = 2.0; VecMaxs[2] = 2.0
					}
					
				}
			}
			
			// Krilin
			case 4:	{
				switch(g_power[1][id])
				{
					// Ki-Blast
					case 1:{
						entModel = "sprites/dbz_mod/ki_blast.spr"
						entScale = 0.20; entSpeed = 2000.0; big_attack = false
						allow_trail = true; trailModel = g_trail[0]; allow_guide = false
						trailLength = 1; trailWidth = 2
					}
					
					// Kamehameha
					case 2:{
						entModel = "sprites/dbz_mod/kamehameha_blue.spr"
						entScale = 1.20; entSpeed = 1500.0; big_attack = false
						allow_trail = true; trailModel = g_trail[1]
						trailLength = 100; trailWidth = 8; allow_guide = true
						VecMins[0] = -2.0; VecMins[1] = -2.0; VecMins[2] = -2.0;
						VecMaxs[0] = 2.0; VecMaxs[1] = 2.0; VecMaxs[2] = 2.0
					}
					
					// Destruction Disc
					case 3: {
						entModel = "models/dbz_mod/kurilin_disc.mdl"
						entScale = 1.20; entSpeed = 1500.0; big_attack = false
						allow_trail = true; allow_guide = true; ismdl = 1
						trailModel = g_trail[11]; trailLength = 100; trailWidth = 8
						VecMins[0] = -2.0; VecMins[1] = -2.0; VecMins[2] = -2.0
						VecMaxs[0] = 2.0; VecMaxs[1] = 2.0; VecMaxs[2] = 2.0
					}
					
				}
			}
			
			// Picolo
			case 5: {
				switch(g_power[1][id])
				{
					// Ki-Blast
					case 1:{
						entModel = "sprites/dbz_mod/green_kamehameha.spr"
						entScale = 0.20; entSpeed = 2000.0; big_attack = false
						allow_trail = true; trailModel = g_trail[6]; allow_guide = false
						trailLength = 1; trailWidth = 2
					}
					
					// Masenko
					case 2:{
						entModel = "sprites/dbz_mod/masenkob.spr"
						entScale = 1.20; entSpeed = 1500.0; big_attack = false
						allow_guide = true; allow_trail = true; trailModel = g_trail[14]
						trailLength = 100; trailWidth = 8
						VecMins[0] = -2.0; VecMins[1] = -2.0; VecMins[2] = -2.0
						VecMaxs[0] = 2.0; VecMaxs[1] = 2.0; VecMaxs[2] = 2.0
					}
					
					// Special Bean Cannon
					case 3:{
						//entModel = "sprites/dbz_mod/special_bean.spr"
						entModel = "sprites/dbz_mod/gallitgunb.spr"
						entScale = 0.20; entSpeed = 1500.0; big_attack = false
						allow_trail = true; allow_guide = false
						trailModel = g_trail[7]; /*g_trail[10];*/ trailLength = 100; trailWidth = 2
						VecMins[0] = -2.0; VecMins[1] = -2.0; VecMins[2] = -2.0
						VecMaxs[0] = 2.0; VecMaxs[1] = 2.0; VecMaxs[2] = 2.0
					}
				}
			}
		}
	}
	else
	{
		switch(g_villain_id[id]) 
		{
			// Frieza
			case 1: {
				switch(g_power[1][id])
				{
					// Ki-Blast
					case 1:{
						entModel = "sprites/dbz_mod/gallitgunb.spr"
						entScale = 0.20; entSpeed = 2000.0; big_attack = false
						allow_trail = true; trailModel = g_trail[12]; allow_guide = false
						trailLength = 1; trailWidth = 2
					}
					
					// Death Bean
					case 2:{
						entModel = "sprites/dbz_mod/gallitgunb.spr"
						entScale = 0.20; entSpeed = 1500.0; big_attack = false
						allow_trail = true; allow_guide = true
						trailModel = g_trail[12]; trailLength = 100; trailWidth = 4
						VecMins[0] = -2.0; VecMins[1] = -2.0; VecMins[2] = -2.0
						VecMaxs[0] = 2.0; VecMaxs[1] = 2.0; VecMaxs[2] = 2.0
					}
					
					// Destrucion Disc (Purple)
					case 3:{
						entModel = "models/dbz_mod/frieza_friezadisc.mdl"
						entScale = 1.20; entSpeed = 1500.0; big_attack = false
						allow_trail = true; allow_guide = true; trail_g = 0; ismdl = 1
						trailModel = g_trail[11]; trailLength = 100; trailWidth = 8
						VecMins[0] = -2.0; VecMins[1] = -2.0; VecMins[2] = -2.0
						VecMaxs[0] = 2.0; VecMaxs[1] = 2.0; VecMaxs[2] = 2.0
					}
					
					// Death Ball
					case 4:{
						entModel = "sprites/dbz_mod/frieza_deathball.spr"
						entScale = 1.4; entSpeed = 800.0; big_attack = true
						allow_trail = false; allow_guide = false
						VecMins[0] = -4.0; VecMins[1] = -4.0; VecMins[2] = -4.0
						VecMaxs[0] = 4.0; VecMaxs[1] = 4.0; VecMaxs[2] = 4.0
					}
				}
			}
			
			// Cell
			case 2: {
				switch(g_power[1][id])
				{
					// Ki-Blast
					case 1:{
						entModel = "sprites/dbz_mod/green_kamehameha.spr"
						entScale = 0.20; entSpeed = 2000.0; big_attack = false
						allow_trail = true; trailModel = g_trail[6]; allow_guide = false
						trailLength = 1; trailWidth = 2
					}
			
					// Death Bean
					case 2:{
						entModel = "sprites/dbz_mod/special_bean.spr"
						entScale = 0.20; entSpeed = 1500.0; big_attack = false
						allow_trail = true; allow_guide = true
						trailModel = g_trail[12]; trailLength = 100; trailWidth = 4
						VecMins[0] = -2.0; VecMins[1] = -2.0; VecMins[2] = -2.0
						VecMaxs[0] = 2.0; VecMaxs[1] = 2.0; VecMaxs[2] = 2.0
					}
					
					// Green Kamehameha
					case 3:{
						entModel = "sprites/dbz_mod/green_kamehameha.spr"
						entScale = 1.20; entSpeed = 1500.0; big_attack = false
						allow_trail = true; trailModel = g_trail[6]
						trailLength = 100; trailWidth = 8; allow_guide = true
						VecMins[0] = -2.0; VecMins[1] = -2.0; VecMins[2] = -2.0;
						VecMaxs[0] = 2.0; VecMaxs[1] = 2.0; VecMaxs[2] = 2.0
					}
					
				}
			}
			
			// Super Buu
			case 3: {
				switch(g_power[1][id]){
					case 1:{
						entModel = "sprites/dbz_mod/buu_gallitgun.spr"
						entScale = 0.20; entSpeed = 2000.0; big_attack = false
						allow_trail = true; trailModel = g_trail[7]; allow_guide = false
						trailLength = 1; trailWidth = 2
					}
					case 2:{
						entModel = "sprites/dbz_mod/buu_final_flash_charge.spr"
						entScale = 0.60; entSpeed = 1600.0; big_attack = false
						allow_trail = true; allow_guide = true
						trailModel = g_trail[8]; trailLength = 100; trailWidth = 8
						VecMins[0] = -2.0; VecMins[1] = -2.0; VecMins[2] = -2.0
						VecMaxs[0] = 2.0; VecMaxs[1] = 2.0; VecMaxs[2] = 2.0
					}
					case 3:{
						entModel = "sprites/dbz_mod/buu_big_bang.spr"
						entScale = 1.0; entSpeed = 1050.0; big_attack = false
						allow_trail = true; allow_guide = true
						trailModel = g_trail[9]; trailLength = 100; trailWidth = 16
						VecMins[0] = -3.0; VecMins[1] = -3.0; VecMins[2] = -3.0
						VecMaxs[0] = 3.0; VecMaxs[1] = 3.0; VecMaxs[2] = 3.0
					}
					case 4:{
						entModel = "sprites/dbz_mod/buu_death_ball.spr"
						entScale = 1.70; entSpeed = 850.0; big_attack = true
						allow_trail = false; allow_guide = false
						VecMins[0] = -4.0; VecMins[1] = -4.0; VecMins[2] = -4.0
						VecMaxs[0] = 4.0; VecMaxs[1] = 4.0; VecMaxs[2] = 4.0
					}
				}
			}
			
			// Broly
			case 4: {
				switch(g_power[1][id])
				{
					case 1:{
						entModel = "sprites/dbz_mod/green_kamehameha.spr"
						entScale = 0.20; entSpeed = 2000.0; big_attack = false
						allow_trail = true; trailModel = g_trail[6]; allow_guide = false
						trailLength = 1; trailWidth = 2
					}
					case 2:{
						entModel = "sprites/dbz_mod/broly_final_flash_charge.spr"
						entScale = 0.60; entSpeed = 1600.0; big_attack = false
						allow_trail = true; allow_guide = true
						trailModel = g_trail[5]; trailLength = 100; trailWidth = 8
						VecMins[0] = -2.0; VecMins[1] = -2.0; VecMins[2] = -2.0
						VecMaxs[0] = 2.0; VecMaxs[1] = 2.0; VecMaxs[2] = 2.0
					}
					case 3:{
						entModel = "sprites/dbz_mod/broly_big_bang.spr"
						entScale = 1.0; entSpeed = 1050.0; big_attack = false
						allow_trail = true; allow_guide = true
						trailModel = g_trail[6]; trailLength = 100; trailWidth = 16
						VecMins[0] = -3.0; VecMins[1] = -3.0; VecMins[2] = -3.0
						VecMaxs[0] = 3.0; VecMaxs[1] = 3.0; VecMaxs[2] = 3.0
					}
					case 4:{
						entModel = "sprites/dbz_mod/broly_death_ball.spr"
						entScale = 1.70; entSpeed = 850.0; big_attack = true
						allow_trail = false; allow_guide = false
						VecMins[0] = -4.0; VecMins[1] = -4.0; VecMins[2] = -4.0
						VecMaxs[0] = 4.0; VecMaxs[1] = 4.0; VecMaxs[2] = 4.0
					}
				}
			}
			
			// Omega Sheron
			case 5: {
				switch(g_power[1][id])
				{
					// Ki-Blast
					case 1:{
						entModel = "sprites/dbz_mod/kamehameha_blue.spr"
						entScale = 0.20; entSpeed = 2000.0; big_attack = false
						allow_trail = true; trailModel = g_trail[1]; allow_guide = false
						trailLength = 1; trailWidth = 2
					}
			
					// Dragon Thunder
					case 2:{
						entModel = "sprites/nhth1.spr"
						entScale = 1.00; entSpeed = 1500.0; big_attack = false
						allow_trail = true; allow_guide = true
						trailModel = g_trail[10]; trailLength = 100; trailWidth = 2
						VecMins[0] = -2.0; VecMins[1] = -2.0; VecMins[2] = -2.0
						VecMaxs[0] = 2.0; VecMaxs[1] = 2.0; VecMaxs[2] = 2.0
					}
					
					// Minus Energy Power Ball
					case 3:{
						entModel = "sprites/dbz_mod/minus_enegy_power_ball.spr"
						entScale = 0.70; entSpeed = 800.0; big_attack = true
						allow_trail = false; allow_guide = false
						VecMins[0] = -4.0; VecMins[1] = -4.0; VecMins[2] = -4.0
						VecMaxs[0] = 4.0; VecMaxs[1] = 4.0; VecMaxs[2] = 4.0
					}
					
				}
			}
		}
	}
	
	
	// Get users postion and angles
	entity_get_vector(id, EV_VEC_origin, vOrigin)
	entity_get_vector(id, EV_VEC_angles, vAngles)
	entity_get_vector(id, EV_VEC_v_angle, vAngle)
	
	// Change height for entity origin
	if (big_attack) vOrigin[2] += 110
	else vOrigin[2] += 6
	
	new newEnt = create_entity("info_target")
	if(newEnt == 0) {
		ColorChat(id, GREY, "^4%L^1 %L", id, "DBZ_TAG", id, "ENTITY_FAIL")
		return
	}
	
	g_power[3][id] = newEnt
	
	entity_set_string(newEnt, EV_SZ_classname, "vexd_dbz_power")
	entity_set_model(newEnt, entModel)
	
	entity_set_vector(newEnt, EV_VEC_mins, VecMins)
	entity_set_vector(newEnt, EV_VEC_maxs, VecMaxs)
	
	entity_set_origin(newEnt, vOrigin)
	entity_set_vector(newEnt, EV_VEC_angles, vAngles)
	entity_set_vector(newEnt, EV_VEC_v_angle, vAngle)
	
	entity_set_int(newEnt, EV_INT_solid, 2)
	entity_set_int(newEnt, EV_INT_movetype, 5)
	entity_set_int(newEnt, EV_INT_rendermode, 5)
	entity_set_float(newEnt, EV_FL_renderamt, 255.0)
	entity_set_float(newEnt, EV_FL_scale, entScale)
	entity_set_edict(newEnt, EV_ENT_owner, id)
	
	if(ismdl) {	
		entity_set_float(newEnt, EV_FL_animtime, get_gametime()); 
		entity_set_float(newEnt, EV_FL_framerate, 1.0); 
		entity_set_float(newEnt, EV_FL_frame, 0.0); 
		entity_set_int(newEnt, EV_INT_sequence, 0); 
	}
	
	// Create a VelocityByAim() function, but instead of users
	// eyesight make it start from the entity's origin - vittu
	new Float:fl_Velocity[3], AimVec[3], velOrigin[3]
	
	velOrigin[0] = floatround(vOrigin[0])
	velOrigin[1] = floatround(vOrigin[1])
	velOrigin[2] = floatround(vOrigin[2])
	
	get_user_origin(id, AimVec, 3)
	
	new distance = get_distance(velOrigin, AimVec)
	
	// Stupid Check but lets make sure you don't devide by 0
	if (!distance) distance = 1
	
	new Float:invTime = entSpeed / distance
	
	fl_Velocity[0] = (AimVec[0] - vOrigin[0]) * invTime
	fl_Velocity[1] = (AimVec[1] - vOrigin[1]) * invTime
	fl_Velocity[2] = (AimVec[2] - vOrigin[2]) * invTime
	
	entity_set_vector(newEnt, EV_VEC_velocity, fl_Velocity)
	
	// No trail on Spirit Bomb/Death ball/etc...
	if (allow_trail) {
		// Set Trail on entity
		message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
		write_byte(22)			// TE_BEAMFOLLOW
		write_short(newEnt)		// entity:attachment to follow
		write_short(trailModel)	// sprite index
		write_byte(trailLength)	// life in 0.1's
		write_byte(trailWidth)	// line width in 0.1's
		write_byte(trail_r)	//colour
		write_byte(trail_g)
		write_byte(trail_b)
		write_byte(255)	// brightness
		message_end()
	}
	
	// Guide Kamehameha with mouse
	if (allow_guide) {
		new iNewVelocity[3], args[6]
		iNewVelocity[0] = floatround(fl_Velocity[0])
		iNewVelocity[1] = floatround(fl_Velocity[1])
		iNewVelocity[2] = floatround(fl_Velocity[2])
		
		// Pass varibles used to guide entity with
		args[0] = id
		args[1] = newEnt
		args[2] = floatround(entSpeed)
		args[3] = iNewVelocity[0]
		args[4] = iNewVelocity[1]
		args[5] = iNewVelocity[2]
		
		set_task(0.1, "guide_kamehameha", newEnt, args, 6)
	}
}

/*===============================================================================
[Guide Kamehameha With Mouse]
================================================================================*/
public guide_kamehameha(args[])
{
	new AimVec[3], avgFactor
	new Float:fl_origin[3]
	new id = args[0]
	new ent = args[1]
	new speed = args[2]
	
	if (!is_valid_ent(ent)) return
	
	if (!is_user_connected(id)) {
		vexd_pfntouch(ent, 0)
		return
	}
	
	get_user_origin(id, AimVec, 3)
	
	entity_get_vector(ent, EV_VEC_origin, fl_origin)
	
	new iNewVelocity[3]
	new origin[3]
	
	origin[0] = floatround(fl_origin[0])
	origin[1] = floatround(fl_origin[1])
	origin[2] = floatround(fl_origin[2])
	
	if (g_power[1][id] == 2)
		avgFactor = 3
	else if (g_power[1][id] == 3)
		avgFactor = 6
	// stupid check but why not
	else
		avgFactor = 8
	
	new velocityVec[3], length
	
	velocityVec[0] = AimVec[0]-origin[0]
	velocityVec[1] = AimVec[1]-origin[1]
	velocityVec[2] = AimVec[2]-origin[2]
	
	length = sqroot(velocityVec[0]*velocityVec[0] + velocityVec[1]*velocityVec[1] + velocityVec[2]*velocityVec[2])
	// Stupid Check but lets make sure you don't devide by 0
	if (!length) length = 1
	
	velocityVec[0] = velocityVec[0]*speed/length
	velocityVec[1] = velocityVec[1]*speed/length
	velocityVec[2] = velocityVec[2]*speed/length
	
	iNewVelocity[0] = (velocityVec[0] + (args[3] * (avgFactor-1))) / avgFactor
	iNewVelocity[1] = (velocityVec[1] + (args[4] * (avgFactor-1))) / avgFactor
	iNewVelocity[2] = (velocityVec[2] + (args[5] * (avgFactor-1))) / avgFactor
	
	new Float:fl_iNewVelocity[3]
	fl_iNewVelocity[0] = float(iNewVelocity[0])
	fl_iNewVelocity[1] = float(iNewVelocity[1])
	fl_iNewVelocity[2] = float(iNewVelocity[2])
	
	entity_set_vector(ent, EV_VEC_velocity, fl_iNewVelocity)
	
	args[3] = iNewVelocity[0]
	args[4] = iNewVelocity[1]
	args[5] = iNewVelocity[2]
	
	set_task(0.1, "guide_kamehameha", ent, args, 6)
}

/*===============================================================================
[Shares at the time that the power touches anything]
================================================================================*/
public vexd_pfntouch(pToucher, pTouched) {
	
	if (pToucher <= 0) return
	if (!is_valid_ent(pToucher)) return
	
	new szClassName[32]
	entity_get_string(pToucher, EV_SZ_classname, szClassName, charsmax(szClassName))
	
	if(equal(szClassName, "vexd_dbz_power")) 
	{
		new id = entity_get_edict(pToucher, EV_ENT_owner)
		new dmgRadius = g_max[0][id]
		new maxDamage = g_max[1][id]
		new Float:fl_vExplodeAt[3], damageName[32]
		new spriteExp = g_explosion[0]
				
		if(g_hero_id[id] > 0)
		{
			switch(g_hero_id[id])
			{
				// Goku
				case 1: {
					switch(g_power[1][id]){
						case 1: damageName = "Ki Blast"
						case 2: damageName = "Kamehameha", spriteExp = g_explosion[1]
						case 3: damageName = "Dragon First"
						case 4: damageName = "10x Kamehameha", spriteExp = g_explosion[2]
						case 5: damageName = "Spirit Bomb"
					}
				}
				
				// Vegeta
				case 2: {
					switch(g_power[1][id]){
						case 1: damageName = "Ki Blast"
						case 2: damageName = "Garlic Gun", spriteExp = g_explosion[3]
						case 3: damageName = "Final Flash", spriteExp = g_explosion[0]
						case 4: damageName = "Final Shine Attack", spriteExp = g_explosion[4]
					}
				}
				
				// Gohan
				case 3: {
					switch(g_power[1][id]){
						case 1: damageName = "Ki Blast"
						case 2: damageName = "Masenko"
						case 3: damageName = "Kamehameha", spriteExp = g_explosion[1]
					}
				}
				
				// Krilin
				case 4: {
					switch(g_power[1][id]){
						case 1: damageName = "Ki Blast"
						case 2: damageName = "Kamehameha", spriteExp = g_explosion[1]
						case 3: damageName = "Destrucion Disc"
					}
				}
				
				// Picolo
				case 5: {
					switch(g_power[1][id]){
						case 1: damageName = "Ki Blast", spriteExp = g_explosion[4]
						case 2: damageName = "Masenko"
						case 3: damageName = "Special Bean Cannon", spriteExp = g_explosion[3]
					}
				}
			}
		}
		else
		{
			switch(g_villain_id[id])
			{
				// Frieza
				case 1: {
					switch(g_power[1][id]){
						case 1: damageName = "Ki Blast", spriteExp = g_explosion[3]
						case 2: damageName = "Death Bean", spriteExp = g_explosion[3]
						case 3: damageName = "Destruction Disc", spriteExp = g_explosion[3]
						case 4: damageName = "Death Ball", spriteExp = g_explosion[2]
					}
				}
				
				// Cell
				case 2: {
					switch(g_power[1][id]){
						case 1: damageName = "Ki Blast", spriteExp = g_explosion[4]
						case 2: damageName = "Death Bean", spriteExp = g_explosion[3]
						case 3: damageName = "Kamehameha", spriteExp = g_explosion[4]
					}
				}
				
				// Super Buu
				case 3: {
					switch(g_power[1][id]){
						case 1: damageName = "Ki Blast"
						case 2: damageName = "Final Flash"
						case 3: damageName = "Big Bang"
						case 4: damageName = "Deathball" 
					}
					spriteExp = g_explosion[3]
				}
				
				// Broly
				case 4: {
					switch(g_power[1][id]){
						case 1: damageName = "Ki Blast"
						case 2: damageName = "Final Flash"
						case 3: damageName = "Big Bang"
						case 4: damageName = "Deathball"
					}
					spriteExp = g_explosion[4]
				}
				
				// Omega Sheron
				case 5: {
					switch(g_power[1][id]){
						case 1: damageName = "Ki Blast", spriteExp = g_explosion[1]
						case 2: damageName = "Dragon Thunder"
						case 3: damageName = "Minus Energy Power Ball", spriteExp = g_explosion[2]
					}
				}
			}
		}
		
		entity_get_vector(pToucher, EV_VEC_origin, fl_vExplodeAt)
		
		new vExplodeAt[3]; vExplodeAt[0] = floatround(fl_vExplodeAt[0]); 
		vExplodeAt[1] = floatround(fl_vExplodeAt[1]); vExplodeAt[2] = floatround(fl_vExplodeAt[2])
		
		// Cause the Damage
		new vicOrigin[3], Float:dRatio,  distance, damage, players[32], pnum, vic
		get_players(players, pnum, "a")
		
		for (new i = 0; i < pnum; i++) 
		{
			vic = players[i];
			if(!is_user_alive(vic) || cs_get_user_team(id) == cs_get_user_team(vic) && !get_cvar_num("mp_friendlyfire")) continue;
			
			get_user_origin(vic, vicOrigin); distance = get_distance(vExplodeAt, vicOrigin)
			
			if (distance < dmgRadius) {
				dRatio = floatdiv(float(distance), float(dmgRadius))
				damage = maxDamage - floatround(maxDamage * dRatio)
				
				// Lessen damage taken by self by half
				if (vic == id) damage = floatround(damage / 2.0)
				
				extra_dmg(vic, id, damage, damageName)
				
				// Make them feel it
				emit_sound(vic, CHAN_BODY, "player/pl_pain2.wav", 1.0, ATTN_NORM, 0, PITCH_NORM)
				
				new Float:fl_Time = distance / 125.0
				new Float:fl_vicVelocity[3]
				fl_vicVelocity[0] = (vicOrigin[0] - vExplodeAt[0]) / fl_Time
				fl_vicVelocity[1] = (vicOrigin[1] - vExplodeAt[1]) / fl_Time
				fl_vicVelocity[2] = (vicOrigin[2] - vExplodeAt[2]) / fl_Time
				entity_set_vector(vic, EV_VEC_velocity, fl_vicVelocity)
			}
		}
		
		// Make some Effects
		new blastSize = floatround(dmgRadius / 12.0)
		
		// Explosion Sprite
		message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
		write_byte(23)			//TE_GLOWSPRITE
		write_coord(vExplodeAt[0])
		write_coord(vExplodeAt[1])
		write_coord(vExplodeAt[2])
		write_short(spriteExp)	// model
		write_byte(01)			// life 0.x sec
		write_byte(blastSize)	// size
		write_byte(255)		// brightness
		message_end()
		
		// Explosion (smoke, sound/effects)
		message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
		write_byte(3)			//TE_EXPLOSION
		write_coord(vExplodeAt[0])
		write_coord(vExplodeAt[1])
		write_coord(vExplodeAt[2])
		write_short(spr[0])		// model
		write_byte(blastSize+5)	// scale in 0.1's
		write_byte(20)			// framerate
		write_byte(10)			// flags
		message_end()
		
		// Create Burn Decals, if they are used
		if (get_pcvar_num(cvar_blast_decalls) == 1) {
			// Change burn decal according to blast size
			new decal_id
			if (blastSize <= 18) decal_id = g_burnDecal[random_num(0,2)]
			else decal_id = g_burnDecalBig[random_num(0,2)]
			
			// Create the burn decal
			message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
			write_byte(109)		//TE_GUNSHOTDECAL
			write_coord(vExplodeAt[0])
			write_coord(vExplodeAt[1])
			write_coord(vExplodeAt[2])
			write_short(0)
			write_byte(decal_id)	//decal
			message_end()
		}
		
		remove_entity(pToucher)
		
		// Reset the Varibles
		g_power[1][id] = 0
		g_power[3][id] = 0
	}
}

/*===============================================================================
[Remove Power Entity]
================================================================================*/
public remove_power(id, powerID)
{
	new Float:fl_vOrigin[3]
	
	entity_get_vector(powerID, EV_VEC_origin, fl_vOrigin)
	
	// Create an effect of kamehameha being removed
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
	write_byte(14)		//TE_IMPLOSION
	write_coord(floatround(fl_vOrigin[0]))
	write_coord(floatround(fl_vOrigin[1]))
	write_coord(floatround(fl_vOrigin[2]))
	write_byte(200)	// radius
	write_byte(40)		// count
	write_byte(45)		// life in 0.1's
	message_end()
	
	g_power[1][id] = 0
	g_power[3][id] = 0
	
	remove_entity(powerID)
}

/*===============================================================================
[Energy gain every second and if Transforming]
================================================================================*/
public dbz_loop(id)
{
	id -= TASK_LOOP
	
	if(!is_user_alive(id)) {
		remove_task(id+TASK_LOOP)
		return;
	}
	
	new name[32]; get_user_name(id, name, charsmax(name))
	new args[2]; args[0] = id; args[1] = 0
	
	if (g_hero_id[id] > 0) {
		switch(g_hero_id[id])
		{
			// Goku
			case 1: 
			{
				if (g_power[2][id] < g_energy_level[4]) g_power[2][id] += get_pcvar_num(cvar_energy_for_second)
				
				if (g_power[2][id] < g_energy_level[0] && g_power[0][id] > 0) g_power[0][id] = 0
		
				else if (g_power[2][id] >= g_energy_level[0] && g_power[2][id] < g_energy_level[1] && g_power[0][id] < 1) {
					args[1] = 5
					set_hudmessage(255, 255, 100, TRANSFORM_HUD_POS, 0, 0.25, 3.0, 0.0, 0.0, 84)
					show_hudmessage(id, "[Goku] %L", id, "TURNED_SUPER_SAYAN")
					emit_sound(id, CHAN_STATIC, "dbz_mod/goku_powerup1.wav", 0.8, ATTN_NORM, 0, PITCH_NORM)
					g_power[0][id] = 1
				}
				else if (g_power[2][id] >= g_energy_level[1] && g_power[2][id] < g_energy_level[2] && g_power[0][id] < 2) {
					args[1] = 7
					set_hudmessage(222, 226, 0, TRANSFORM_HUD_POS, 0, 0.25, 3.0, 0.0, 0.0, 84)
					show_hudmessage(id, "[Goku] %L 2", id, "TURNED_SUPER_SAYAN")
					emit_sound(id, CHAN_STATIC, "dbz_mod/goku_powerup2.wav", 0.8, ATTN_NORM, 0, PITCH_NORM)
					g_power[0][id] = 2
				}
				else if (g_power[2][id] >= g_energy_level[2] && g_power[2][id] < g_energy_level[3] && g_power[0][id] < 3) {
					args[1] = 9
					set_hudmessage(248, 220, 117, TRANSFORM_HUD_POS, 0, 0.25, 3.0, 0.0, 0.0, 84)
					show_hudmessage(id, "[Goku] %L 3", id, "TURNED_SUPER_SAYAN")
					emit_sound(id, CHAN_STATIC, "dbz_mod/goku_powerup3.wav", 0.8, ATTN_NORM, 0, PITCH_NORM)
					g_power[0][id] = 3
				}
				else if (g_power[2][id] >= g_energy_level[3] && g_power[2][id] < g_energy_level[4] && g_power[0][id] < 4) {
					args[1] = 11
					set_hudmessage(196, 0, 0, TRANSFORM_HUD_POS, 0, 0.25, 3.0, 0.0, 0.0, 84)
					show_hudmessage(id, "[Goku] %L 4", id, "TURNED_SUPER_SAYAN")
					emit_sound(id, CHAN_STATIC, "dbz_mod/goku_powerup4.wav", 0.8, ATTN_NORM, 0, PITCH_NORM)
					g_power[0][id] = 4
				}
				
				else if (g_power[2][id] >= g_energy_level[4] && g_power[0][id] < 5) {
					args[1] = 20
					set_hudmessage(255, 255, 255, TRANSFORM_HUD_POS, 0, 0.25, 3.0, 0.0, 0.0, 84)
					show_hudmessage(0, "[Goku] %L 5", LANG_PLAYER, "MAX_TURNED_SUPER_SAYAN", name)
					emit_sound(id, CHAN_STATIC, "dbz_mod/goku_powerup5.wav", 0.8, ATTN_NORM, 0, PITCH_NORM)
					g_power[0][id] = 5
				}
			}
			
			// Vegeta
			case 2: {
				// Give him armor
				if (g_power[2][id] < g_energy_level[3]) g_power[2][id] += get_pcvar_num(cvar_energy_for_second)
				
				if (g_power[2][id] < g_energy_level[0] && g_power[0][id] > 0) g_power[0][id] = 0
				
				else if (g_power[2][id] >= g_energy_level[0] && g_power[2][id] < g_energy_level[1] && g_power[0][id] < 1) {
					args[1] = 5
					set_hudmessage(255, 255, 100, TRANSFORM_HUD_POS, 0, 0.25, 3.0, 0.0, 0.0, 84)
					show_hudmessage(id, "[Vegeta] %L", id, "TURNED_SUPER_SAYAN")
					emit_sound(id, CHAN_STATIC, "dbz_mod/vegeta_powerup1.wav", 0.8, ATTN_NORM, 0, PITCH_NORM)
					g_power[0][id] = 1
				}
				else if (g_power[2][id] >= g_energy_level[1] && g_power[2][id] < g_energy_level[2] && g_power[0][id] < 2) {
					args[1] = 7
					set_hudmessage(222, 226, 0, TRANSFORM_HUD_POS, 0, 0.25, 3.0, 0.0, 0.0, 84)
					show_hudmessage(id, "[Vegeta] %L 2", id, "TURNED_SUPER_SAYAN")
					emit_sound(id, CHAN_STATIC, "dbz_mod/vegeta_powerup2.wav", 0.8, ATTN_NORM, 0, PITCH_NORM)
					g_power[0][id] = 2
				}
				else if (g_power[2][id] >= g_energy_level[2] && g_power[2][id] < g_energy_level[3] && g_power[0][id] < 3) {
					args[1] = 9
					set_hudmessage(248, 220, 117, TRANSFORM_HUD_POS, 0, 0.25, 3.0, 0.0, 0.0, 84)
					show_hudmessage(id, "[Vegeta] %L 3", id, "TURNED_SUPER_SAYAN")
					emit_sound(id, CHAN_STATIC, "dbz_mod/vegeta_powerup3.wav", 0.8, ATTN_NORM, 0, PITCH_NORM)
					g_power[0][id] = 3
				}
				else if (g_power[2][id] >= g_energy_level[3] && g_power[0][id] < 4) {
					args[1] = 11
					set_hudmessage(196, 0, 0, TRANSFORM_HUD_POS, 0, 0.25, 3.0, 0.0, 0.0, 84)
					show_hudmessage(0, "[Vegeta] %L 4", LANG_PLAYER, "MAX_TURNED_SUPER_SAYAN", name)
					emit_sound(id, CHAN_STATIC, "dbz_mod/vegeta_powerup4.wav", 0.8, ATTN_NORM, 0, PITCH_NORM)
					g_power[0][id] = 4
				}
			}
			
			// Gohan
			case 3: {

				if (g_power[2][id] < g_energy_level[2]) g_power[2][id] += get_pcvar_num(cvar_energy_for_second)
				
				if (g_power[2][id] < g_energy_level[0] && g_power[0][id] > 0) g_power[0][id] = 0

				else if (g_power[2][id] >= g_energy_level[0] && g_power[2][id] < g_energy_level[1] && g_power[0][id] < 1) {
					args[1] = 5
					ColorChat(id, GREY, "^4%L^1 %L", id, "DBZ_TAG", id, "KI_BLAST_PREPARED")
					g_power[0][id] = 1
					emit_sound(id, CHAN_STATIC, "dbz_mod/gohan_powerup1.wav", 0.8, ATTN_NORM, 0, PITCH_NORM)
				}
				else if (g_power[2][id] >= g_energy_level[1] && g_power[2][id] < g_energy_level[2] && g_power[0][id] < 2) {
					args[1] = 7
					set_hudmessage(222, 226, 0, TRANSFORM_HUD_POS, 0, 0.25, 3.0, 0.0, 0.0, 84)
					show_hudmessage(id, "[Gohan] %L", id, "TURNED_SUPER_SAYAN")
					g_power[0][id] = 2
					emit_sound(id, CHAN_STATIC, "dbz_mod/gohan_powerup2.wav", 0.8, ATTN_NORM, 0, PITCH_NORM)
				}
				else if (g_power[2][id] >= g_energy_level[2] && g_power[0][id] < 3) {
					args[1] = 11
					set_hudmessage(248, 220, 117, TRANSFORM_HUD_POS, 0, 0.25, 3.0, 0.0, 0.0, 84)
					show_hudmessage(0, "[Gohan] %L 2", LANG_PLAYER, "MAX_TURNED_SUPER_SAYAN", name)
					g_power[0][id] = 3
					emit_sound(id, CHAN_STATIC, "dbz_mod/gohan_powerup3.wav", 0.8, ATTN_NORM, 0, PITCH_NORM)
				}
			}
			
			// Krilin
			case 4: {
				if (g_power[2][id] < g_energy_level[2]) g_power[2][id] += get_pcvar_num(cvar_energy_for_second)
				
				if (g_power[2][id] < g_energy_level[0] && g_power[0][id] > 0) g_power[0][id] = 0
				
				else if (g_power[2][id] >= g_energy_level[0] && g_power[2][id] < g_energy_level[1] && g_power[0][id] < 1) {
					args[1] = 5
					ColorChat(id, GREY, "^4%L^1 %L", id, "DBZ_TAG", id, "KI_BLAST_PREPARED")
					g_power[0][id] = 1
					emit_sound(id, CHAN_STATIC, "dbz_mod/krillin_powerup1.wav", 0.8, ATTN_NORM, 0, PITCH_NORM)
				}
				else if (g_power[2][id] >= g_energy_level[1] && g_power[2][id] < g_energy_level[2] && g_power[0][id] < 2) {
					args[1] = 7
					ColorChat(id, GREY, "^4%L^1 %L", id, "DBZ_TAG", id, "KAMEHAMEHA_PREPARED")
					g_power[0][id] = 2
					emit_sound(id, CHAN_STATIC, "dbz_mod/krillin_powerup1.wav", 0.8, ATTN_NORM, 0, PITCH_NORM)
				}
				else if (g_power[2][id] >= g_energy_level[2] && g_power[0][id] < 3) {
					args[1] = 9
					ColorChat(id, GREY, "^4%L^1 %L", id, "DBZ_TAG", id, "DESTRUCION_DISC_PREPARED")
					g_power[0][id] = 3
					emit_sound(id, CHAN_STATIC, "dbz_mod/krillin_powerup2.wav", 0.8, ATTN_NORM, 0, PITCH_NORM)
				}
			}
			
			// Picolo
			case 5: {
				if (g_power[2][id] < g_energy_level[2]) g_power[2][id] += get_pcvar_num(cvar_energy_for_second)
				
				if (g_power[2][id] < g_energy_level[0] && g_power[0][id] > 0) g_power[0][id] = 0
				
				else if (g_power[2][id] >= g_energy_level[0] && g_power[2][id] < g_energy_level[1] && g_power[0][id] < 1) {
					args[1] = 5
					ColorChat(id, GREY, "^4%L^1 %L", id, "DBZ_TAG", id, "KI_BLAST_PREPARED")
					emit_sound(id, CHAN_STATIC, "dbz_mod/piccolo_powerup1.wav", 0.8, ATTN_NORM, 0, PITCH_NORM)
					g_power[0][id] = 1
				}
				else if (g_power[2][id] >= g_energy_level[1] && g_power[2][id] < g_energy_level[2] && g_power[0][id] < 2) {
					args[1] = 7
					ColorChat(id, GREY, "^4%L^1 %L", id, "DBZ_TAG", id, "MASENKO_PREPARED")
					emit_sound(id, CHAN_STATIC, "dbz_mod/piccolo_powerup2.wav", 0.8, ATTN_NORM, 0, PITCH_NORM)
					g_power[0][id] = 2
				}
				else if (g_power[2][id] >= g_energy_level[2] && g_power[0][id] < 3) {
					args[1] = 9
					ColorChat(id, GREY, "^4%L^1 %L", id, "DBZ_TAG", id, "SPECIAL_BEAN_PREPARED")
					emit_sound(id, CHAN_STATIC, "dbz_mod/piccolo_powerup3.wav", 0.8, ATTN_NORM, 0, PITCH_NORM)
					g_power[0][id] = 3
				}
			}
		}
	}
	else if(g_villain_id[id] > 0) {
		switch(g_villain_id[id])
		{
			// Frieza
			case 1: {
				if (g_power[2][id] < g_energy_level[3]) g_power[2][id] += get_pcvar_num(cvar_energy_for_second)
				
				if (g_power[2][id] < g_energy_level[0] && g_power[0][id] > 0) g_power[0][id] = 0

				else if (g_power[2][id] >= g_energy_level[0] && g_power[2][id] < g_energy_level[1] && g_power[0][id] < 1) {
					args[1] = 5
					set_hudmessage(255, 0, 255, TRANSFORM_HUD_POS, 0, 0.25, 3.0, 0.0, 0.0, 84)
					show_hudmessage(id, "[Frieza] %L", id, "FRIEZA_TRANSFORM_1")
					emit_sound(id, CHAN_STATIC, "dbz_mod/frieza_powerup1.wav", 0.8, ATTN_NORM, 0, PITCH_NORM)
					g_power[0][id] = 1
				}
				else if (g_power[2][id] >= g_energy_level[1] && g_power[2][id] < g_energy_level[2] && g_power[0][id] < 2) {
					args[1] = 7
					set_hudmessage(255, 0, 255, TRANSFORM_HUD_POS, 0, 0.25, 3.0, 0.0, 0.0, 84)
					show_hudmessage(id, "[Frieza] %L", id, "FRIEZA_TRANSFORM_2")
					emit_sound(id, CHAN_STATIC, "dbz_mod/frieza_powerup2.wav", 0.8, ATTN_NORM, 0, PITCH_NORM)
					g_power[0][id] = 2
				}
				else if (g_power[2][id] >= g_energy_level[2] && g_power[2][id] < g_energy_level[3] && g_power[0][id] < 3) {
					args[1] = 9
					set_hudmessage(255, 0, 255, TRANSFORM_HUD_POS, 0, 0.25, 3.0, 0.0, 0.0, 84)
					show_hudmessage(id, "[Frieza] %L", id, "FRIEZA_TRANSFORM_3")
					emit_sound(id, CHAN_STATIC, "dbz_mod/frieza_powerup3.wav", 0.8, ATTN_NORM, 0, PITCH_NORM)
					g_power[0][id] = 3
				}
				else if (g_power[2][id] >= g_energy_level[3] && g_power[0][id] < 4) {
					args[1] = 11
					set_hudmessage(255, 0, 255, TRANSFORM_HUD_POS, 0, 0.25, 3.0, 0.0, 0.0, 84)
					show_hudmessage(0, "[Frieza] %L", LANG_PLAYER, "FRIEZA_TRANSFORM_4", name)
					emit_sound(id, CHAN_STATIC, "dbz_mod/frieza_powerup4.wav", 0.8, ATTN_NORM, 0, PITCH_NORM)
					g_power[0][id] = 4
				}
			}
			
			// Cell
			case 2: {
				if (g_power[2][id] < g_energy_level[2]) g_power[2][id] += get_pcvar_num(cvar_energy_for_second)
				
				if (g_power[2][id] < g_energy_level[0] && g_power[0][id] > 0) g_power[0][id] = 0

				else if (g_power[2][id] >= g_energy_level[0] && g_power[2][id] < g_energy_level[1] && g_power[0][id] < 1) {
					args[1] = 5
					set_hudmessage(0, 255, 0, TRANSFORM_HUD_POS, 0, 0.25, 3.0, 0.0, 0.0, 84)
					show_hudmessage(id, "[Cell] %L", id, "CELL_TRANSFORM_1")
					g_power[0][id] = 1
					emit_sound(id, CHAN_STATIC, "dbz_mod/cell_powerup1.wav", 0.8, ATTN_NORM, 0, PITCH_NORM)
				}
				else if (g_power[2][id] >= g_energy_level[1] && g_power[2][id] < g_energy_level[2] && g_power[0][id] < 2) {
					args[1] = 7
					set_hudmessage(0, 255, 0, TRANSFORM_HUD_POS, 0, 0.25, 3.0, 0.0, 0.0, 84)
					show_hudmessage(id, "[Cell] %L", id, "CELL_TRANSFORM_2")
					g_power[0][id] = 2
					emit_sound(id, CHAN_STATIC, "dbz_mod/cell_powerup2.wav", 0.8, ATTN_NORM, 0, PITCH_NORM)
				}
				else if (g_power[2][id] >= g_energy_level[2] && g_power[0][id] < 3) {
					args[1] = 9
					set_hudmessage(0, 255, 0, TRANSFORM_HUD_POS, 0, 0.25, 3.0, 0.0, 0.0, 84)
					show_hudmessage(0, "[Cell] %L", LANG_PLAYER, "CELL_TRANSFORM_3", name)
					g_power[0][id] = 3
					emit_sound(id, CHAN_STATIC, "dbz_mod/cell_powerup3.wav", 0.8, ATTN_NORM, 0, PITCH_NORM)
				}
			}
			
			// Super Buu
			case 3: {
				if (g_power[2][id] < g_energy_level[3]) g_power[2][id] += get_pcvar_num(cvar_energy_for_second)
				
				if (g_power[2][id] < g_energy_level[0] && g_power[0][id] > 0) g_power[0][id] = 0
					
				if (g_power[2][id] >= g_energy_level[0] && g_power[2][id] < g_energy_level[1] && g_power[0][id] < 1) 
				{
					args[1] = 7
					emit_sound(id, CHAN_STATIC, "dbz_mod/superbuu_powerup1_fix.wav", 0.8, ATTN_NORM, 0, PITCH_NORM)
					set_hudmessage(0, 255, 0, TRANSFORM_HUD_POS, 0, 0.25, 3.0, 0.0, 0.0, 84)
					show_hudmessage(id, "[Superbuu] %L", id, "SUPER_BUU_TRASNFORM")
					g_power[0][id] = 1
				}
				else if (g_power[2][id] >= g_energy_level[1] && g_power[2][id] < g_energy_level[2] && g_power[0][id] < 2) 
				{
					args[1] = 11
					set_hudmessage(255, 165, 0, TRANSFORM_HUD_POS, 0, 0.25, 3.0, 0.0, 0.0, 84)
					show_hudmessage(id, "[Superbuu] %L 2", id, "SUPER_BUU_TRASNFORM")
					emit_sound(id, CHAN_STATIC, "dbz_mod/superbuu_powerup2.wav", 0.8, ATTN_NORM, 0, PITCH_NORM)
					g_power[0][id] = 2
				}
				else if (g_power[2][id] >= g_energy_level[2] && g_power[2][id] < g_energy_level[3] && g_power[0][id] < 3) {
					args[1] = 15
					set_hudmessage(0, 255, 255, TRANSFORM_HUD_POS, 0, 0.25, 3.0, 0.0, 0.0, 84)
					show_hudmessage(id, "[Superbuu] %L 3", id, "SUPER_BUU_TRASNFORM")
					emit_sound(id, CHAN_STATIC, "dbz_mod/superbuu_powerup3.wav", 0.8, ATTN_NORM, 0, PITCH_NORM)
					g_power[0][id] = 3
				}
				else if (g_power[2][id] >= g_energy_level[3] && g_power[0][id] < 4) {
					args[1] = 20
					set_hudmessage(255, 165, 0, TRANSFORM_HUD_POS, 0, 0.25, 3.0, 0.0, 0.0, 84)
					emit_sound(id, CHAN_STATIC, "dbz_mod/superbuu_powerup3.wav", 0.8, ATTN_NORM, 0, PITCH_NORM)
					show_hudmessage(id, "[Superbuu] %L 4", id, "SUPER_BUU_TRASNFORM")
					g_power[0][id] = 4
				}
			}
			
			// Broly
			case 4: {
				if (g_power[2][id] < g_energy_level[3]) g_power[2][id] += get_pcvar_num(cvar_energy_for_second)
				
				if (g_power[2][id] < g_energy_level[0] && g_power[0][id] > 0) g_power[0][id] = 0
				
				if (g_power[2][id] >= g_energy_level[0] && g_power[2][id] < g_energy_level[1] && g_power[0][id] < 1) {
					args[1] = 7
					set_hudmessage(0, 255, 0, TRANSFORM_HUD_POS, 0, 0.25, 3.0, 0.0, 0.0, 84)
					show_hudmessage(id, "[Broly] %L", id, "TURNED_SUPER_SAYAN")
					emit_sound(id, CHAN_STATIC, "dbz_mod/broly_powerup1.wav", 0.8, ATTN_NORM, 0, PITCH_NORM)
					g_power[0][id] = 1
				}
				else if (g_power[2][id] >= g_energy_level[1] && g_power[2][id] < g_energy_level[2] && g_power[0][id] < 2) {
					args[1] = 9
					set_hudmessage(255, 165, 0, TRANSFORM_HUD_POS, 0, 0.25, 3.0, 0.0, 0.0, 84)
					show_hudmessage(id, "[Broly] %L 2", id, "TURNED_SUPER_SAYAN")
					emit_sound(id, CHAN_STATIC, "dbz_mod/broly_powerup3.wav", 0.8, ATTN_NORM, 0, PITCH_NORM)
					g_power[0][id] = 2
				}
				else if (g_power[2][id] >= g_energy_level[2] && g_power[2][id] < g_energy_level[3] && g_power[0][id] < 3) {
					args[1] = 11
					set_hudmessage(0, 255, 255, TRANSFORM_HUD_POS, 0, 0.25, 3.0, 0.0, 0.0, 84)
					show_hudmessage(id, "[Broly] %L 3", id, "TURNED_SUPER_SAYAN")
					emit_sound(id, CHAN_STATIC, "dbz_mod/broly_powerup2.wav", 1.0, ATTN_NORM, 0, PITCH_NORM)
					g_power[0][id] = 3
				}
				else if (g_power[2][id] >= g_energy_level[3] && g_power[0][id] < 4) {
					args[1] = 20
					set_hudmessage(255, 165, 0, TRANSFORM_HUD_POS, 0, 0.25, 3.0, 0.0, 0.0, 84)
					show_hudmessage(0, "[Broly] %L 4", LANG_PLAYER, "MAX_TURNED_SUPER_SAYAN", name)
					emit_sound(id, CHAN_STATIC, "dbz_mod/broly_powerup4.wav", 0.8, ATTN_NORM, 0, PITCH_NORM)         
					g_power[0][id] = 4
				}
			}
			
			// Omega Sheron
			case 5: {
				if (g_power[2][id] < g_energy_level[2]) g_power[2][id] += get_pcvar_num(cvar_energy_for_second)
				
				if (g_power[2][id] < g_energy_level[0] && g_power[0][id] > 0) g_power[0][id] = 0

				else if (g_power[2][id] >= g_energy_level[0] && g_power[2][id] < g_energy_level[1] && g_power[0][id] < 1) {
					args[1] = 5
					set_hudmessage(255, 69, 0, TRANSFORM_HUD_POS, 0, 0.25, 3.0, 0.0, 0.0, 84)
					show_hudmessage(id, "[Omega Sheron] %L", id, "OMEGA_SHERON_TRANSFORM_1")
					g_power[0][id] = 1
				}
				else if (g_power[2][id] >= g_energy_level[1] && g_power[2][id] < g_energy_level[2] && g_power[0][id] < 2) {
					args[1] = 10
					set_hudmessage(255, 69, 0, TRANSFORM_HUD_POS, 0, 0.25, 3.0, 0.0, 0.0, 84)
					show_hudmessage(id, "[Omega Sheron] %L", id, "OMEGA_SHERON_TRANSFORM_2")
					g_power[0][id] = 2
				}
				else if (g_power[2][id] >= g_energy_level[2] && g_power[0][id] < 3) {
					args[1] = 20
					set_hudmessage(255, 69, 0, TRANSFORM_HUD_POS, 0, 0.25, 3.0, 0.0, 0.0, 84)
					show_hudmessage(0, "[Omega Sheron] %L", LANG_PLAYER, "OMEGA_SHERON_TRANSFORM_3", name)
					g_power[0][id] = 3
				}
			}
		}
		
	}
	
	#if defined PLAYER_MODELS
	model_update(id)
	#endif
	
	if(get_pcvar_num(cvar_powerup_effect) && args[1] > 0)
		set_task(0.2, "powerup_effect", 0, args, 2, "a", 1)
}
#if defined PLAYER_MODELS
new g_playermodel[33][32]
public model_update(id)
{
	if(g_hero_id[id] > 0) {
		switch(g_hero_id[id]) {
			case 1: formatex(g_playermodel[id], charsmax(g_playermodel[]), "%s", goku_models[g_power[0][id]])
			case 2: formatex(g_playermodel[id], charsmax(g_playermodel[]), "%s", vegeta_models[g_power[0][id]])
			case 3: formatex(g_playermodel[id], charsmax(g_playermodel[]), "%s", gohan_models[g_power[0][id]])
			case 4: formatex(g_playermodel[id], charsmax(g_playermodel[]), "%s", KRILLIN_MODEL)
			case 5: formatex(g_playermodel[id], charsmax(g_playermodel[]), "%s", PICCOLO_MODEL)
		}
	}
	else if(g_villain_id[id] > 0) {
		switch(g_villain_id[id]) {
			case 1: formatex(g_playermodel[id], charsmax(g_playermodel[]), "%s", frieza_models[g_power[0][id]])
			case 2: formatex(g_playermodel[id], charsmax(g_playermodel[]), "%s", cell_models[g_power[0][id]])
			case 3: formatex(g_playermodel[id], charsmax(g_playermodel[]), "%s", superbuu_models[g_power[0][id]])
			case 4: formatex(g_playermodel[id], charsmax(g_playermodel[]), "%s", broly_models[g_power[0][id]])
			case 5: formatex(g_playermodel[id], charsmax(g_playermodel[]), "%s", OMEGASHENRON_MODEL)
		}
	}
	
	if(!task_exists(id+TASK_MODEL))
		set_task(random_float(0.1, 2.0), "model_change", id+TASK_MODEL)	// Prevent Server Crashes on change model
}

public model_change(id)
{
	id -= TASK_MODEL
	
	if(is_user_alive(id)) {
		new currentmodel[32]
		get_user_model(id, currentmodel, charsmax(currentmodel))
		
		if(!equali(currentmodel, g_playermodel[id]))
			fm_set_user_model(id, g_playermodel[id], false)
	}
}
#endif



// Emit Sound Forward
public fw_EmitSound(id, channel, const sample[], Float:volume, Float:attn, flags, pitch)
{
	if(!is_user_valid_connected(id))
		return FMRES_IGNORED;
	
	if(sample[8] == 'k' && sample[9] == 'n' && sample[10] == 'i')
	{
		if(sample[14] == 'h' && sample[15] == 'i' && sample[16] == 't') // hit
		{
			emit_sound(id, channel, knife_sounds[0], volume, attn, flags, pitch)
			return FMRES_SUPERCEDE;
		}
		if(sample[14] == 's' && sample[15] == 't' && sample[16] == 'a') // stab
		{
			emit_sound(id, channel, knife_sounds[1], volume, attn, flags, pitch)
			return FMRES_SUPERCEDE;
		}
		else {
			emit_sound(id, channel, knife_sounds[random_num(2, 4)], volume, attn, flags, pitch)
			return FMRES_SUPERCEDE;
		}	
	}
	
	// Use power with IN_USE button
	if(equal(sample, "common/wpn_denyselect.wav") && (pev(id, pev_button) & IN_USE))
		use_power(id)
	
	return FMRES_IGNORED;
}

/*===============================================================================
[Power Effect]
================================================================================*/
public powerup_effect(args[])
{
	new id = args[0]
	
	if (!is_user_alive(id) || !get_pcvar_num(cvar_powerup_effect)) 
		return
	
	new players[32], pnum
	new idOthers, origin[3]
	
	get_players(players, pnum, "a")
	
	// Show a powerup to all alive players except the one being powered up.
	for (new i = 0; i < pnum; i++) 
	{
		idOthers = players[i]
		if (!is_user_alive(idOthers) || idOthers == id) continue
		
		get_user_origin(id, origin)
		
		message_begin(MSG_PVS, SVC_TEMPENTITY, origin)
		write_byte(TE_SPRITE) // TE id
		write_coord(origin[0]+random_num(-5, 5)) // x
		write_coord(origin[1]+random_num(-5, 5)) // y
		write_coord(origin[2]+random_num(-10, 10)) // z
		write_short(spr[1]) // sprite
		write_byte(args[1]) // scale
		write_byte(25) // brightness
		message_end()
	}
}
/*====================================================================
[Knife Model]
=====================================================================*/
// Ham Weapon Deploy Forward
public fw_Item_Deploy_Post(weapon_ent)
{
	if(!pev_valid(weapon_ent))
		return
	
	// Get weapon's owner
	static owner
	owner = fm_cs_get_weapon_ent_owner(weapon_ent)
	
	// Get weapon's id
	static weaponid
	weaponid = cs_get_weapon_id(weapon_ent)
	
	entity_set_string(owner, EV_SZ_viewmodel, DBZ_KNIFE_V_MODEL)
	entity_set_string(owner, EV_SZ_weaponmodel, "")

	if(is_user_alive(owner) && !((1<<weaponid) & (1<<CSW_KNIFE))) {
		engclient_cmd(owner, "weapon_knife")	// Knifes Only
	}
}

/*===============================================================================
[Load .cfg File]
================================================================================*/
public plugin_cfg() 
{
	// Load .cfg File
	new configsdir[32]; get_configsdir(configsdir, charsmax(configsdir))
	server_cmd("exec %s/dragon_ball_z_mod.cfg", configsdir)
	
	// These cvars are checked very often
	for(new i = 0; i <= 4; i++)
		g_energy_level[i] = get_pcvar_num(cvar_energy_need) * (i+1)
}

/*===============================================================================
[Natives]
================================================================================*/
public native_get_user_energy(id) return g_power[2][id];
public native_set_user_energy(id, amount) g_power[2][id] = amount;
public native_get_user_hero_id(id) return g_hero_id[id];
public native_get_user_villain_id(id) return g_villain_id[id];
public native_get_energy_level(id) return g_power[0][id];
public native_set_energy_level(id, amount) 
{
	if(amount > 5) 
		amount = 5
	
	g_power[0][id] = amount
	g_power[2][id] = amount > 0 ? g_energy_level[amount-1] : 0
	
	#if defined PLAYER_MODELS
	model_update(id)
	#endif
}

/*===============================================================================
[Stocks]
================================================================================*/
// Harm and realize what and who killed
extra_dmg(id, attacker, damage, weaponDescription[])
{
	if (pev(id, pev_takedamage) == DAMAGE_NO || damage <= 0) 
		return;

	if (get_user_health(id) - damage <= 0) 
	{
		set_msg_block(get_user_msgid("DeathMsg"), BLOCK_SET);
		ExecuteHamB(Ham_Killed, id, attacker, 2);
		set_msg_block(get_user_msgid("DeathMsg"), BLOCK_NOT);

		message_begin(MSG_BROADCAST, get_user_msgid("DeathMsg"));
		write_byte(attacker);
		write_byte(id);
		write_byte(0);
		write_string(weaponDescription);
		message_end();
		
		set_pev(attacker, pev_frags, float(get_user_frags(attacker) + 1));
		
		new kname[32], vname[32], kauthid[32], vauthid[32], kteam[10], vteam[10];
		get_user_name(attacker, kname, charsmax(kname)); get_user_team(attacker, kteam, charsmax(kteam)); get_user_authid(attacker, kauthid, charsmax(kauthid));
		get_user_name(id, vname, charsmax(vname)); get_user_team(id, vteam, charsmax(vteam)); get_user_authid(id, vauthid, charsmax(vauthid));
		
		log_message("^"%s<%d><%s><%s>^" killed ^"%s<%d><%s><%s>^" with ^"%s^"", kname, get_user_userid(attacker), kauthid, kteam, 
		vname, get_user_userid(id), vauthid, vteam, weaponDescription);
	}
	else  {
		ExecuteHam(Ham_TakeDamage, id, 0, attacker, float(damage), DMG_BLAST)
	}
}

// Fix for the HL engine bug when HP is multiples of 256
public message_health(msg_id, msg_dest, msg_entity)
{
	// Get player's health
	static health
	health = get_msg_arg_int(1)
	
	// Don't bother
	if (health < 256) return;
	
	// Check if we need to fix it
	if (health % 256 == 0)
		set_user_health(msg_entity, pev(msg_entity, pev_health) + 1)
	
	// HUD can only show as much as 255 hp
	set_msg_arg_int(1, get_msg_argtype(1), 255)
}

// fakemeta_util Utilities
stock set_user_health(index, health) {
	health > 0 ? set_pev(index, pev_health, float(health)) : dllfunc(DLLFunc_ClientKill, index);
	return 1;
}

stock fm_cs_set_user_nobuy(id) {
	if (pev_valid(id) != PDATA_SAFE)
		return;
	
	set_pdata_int(id, 235, get_pdata_int(id, 235) & ~(1<<0)) //no weapon buy
}

#if defined PLAYER_MODELS
precache_playermodel(const modelname[]) 
{  
	static longname[128] 
	formatex(longname, charsmax(longname), "models/player/%s/%s.mdl", modelname, modelname)  	
	precache_model(longname)
	
	copy(longname[strlen(longname)-4], charsmax(longname) - (strlen(longname)-4), "T.mdl") 
	if (file_exists(longname)) 
		precache_model(longname)
} 
#endif

// Get Weapon Entity's Owner
stock fm_cs_get_weapon_ent_owner(ent) {
	// Prevent server crash if entity's private data not initalized
	if (pev_valid(ent) != PDATA_SAFE)
		return -1;
	
	return get_pdata_cbase(ent, OFFSET_WEAPONOWNER, OFFSET_LINUX_WEAPONS);
}