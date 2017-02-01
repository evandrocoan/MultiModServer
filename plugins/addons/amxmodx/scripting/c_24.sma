/*

		//----------------------------------------------------------------------------------//
		//	If you want to give primary weapon as a reward:                                 //
		//			                                                                        //
		//	weapon_scout, weapon_xm1014, weapon_mac10, weapon_aug, weapon_ump45,            //
		//	weapon_sg550, weapon_galil, weapon_famas, weapon_mp5navy, weapon_m249,          //
		//	weapon_m4a1, weapon_tmp, weapon_g3sg1, weapon_sg552, weapon_ak47, weapon_p90    //
		//			                                                                        //
		//	If you want to give secondary weapon as a reward:                               //
		//			                                                                        //
		//	weapon_p228, weapon_elite, weapon_fiveseven, weapon_usp,                        //
		//	weapon_glock18, weapon_deagle                                                   //
		//----------------------------------------------------------------------------------//	

*/

#include <amxmodx>
#include <cs_core>

// Configure which flag will have access to menu
#define ADMIN_FLAG ADMIN_IMMUNITY

// Variable
new g_iReward, g_iCore

public plugin_init() 
{
	register_plugin("[API] CS Core Menu", "5.9", "zmd94")
	
	// If you want to open reward menu, just say /rm
	// in you chat
	register_clcmd("say /rm", "reward_menu")
	register_clcmd("say_team /rm", "reward_menu")
	
	// If you want to test the CS core, just say /core
	// in you chat
	register_clcmd("say /core", "core_menu")
	register_clcmd("say_team /core", "core_menu")
	
	// If you want to test the unstuc native, just say /is
	// in you chat
	register_clcmd("say /is", "im_trap")
	register_clcmd("say_team /is", "im_trap")
}

public plugin_cfg()
{
	g_iReward = menu_create("\yReward Menu \r5.9", "menu_reward")
	
	menu_additem(g_iReward, "\wHealth!", "1", 0 );
	menu_additem(g_iReward, "\wArmor", "2", 0 );
	menu_additem(g_iReward, "\yMoney!", "3", 0 );
	menu_additem(g_iReward, "\yInvisibility!", "4", 0 );
	menu_additem(g_iReward, "\yNoclip!", "5", 0 );
	menu_additem(g_iReward, "\wGrenade!", "6", 0 );
	menu_additem(g_iReward, "\wWeapon!", "7", 0 );
	menu_additem(g_iReward, "\wHeadshot!", "8", 0 );
	menu_additem(g_iReward, "\wGodmode!", "9", 0 );
	menu_additem(g_iReward, "\wGlow!", "10", 0 );
	menu_additem(g_iReward, "\wAura!", "11", 0 );
	menu_additem(g_iReward, "\wSpeed boost!", "12", 0 );
	menu_additem(g_iReward, "\wMulti-jump!", "13", 0 );
	menu_additem(g_iReward, "\wUnlimited clip ammo!", "14", 0 );
	menu_additem(g_iReward, "\wUnlimited BP ammo!", "15", 0 );
	menu_additem(g_iReward, "\wNo-recoil!", "16", 0 );
	menu_additem(g_iReward, "\wAll line drawing!", "17", 0 );
	menu_additem(g_iReward, "\wAll ring indicator!", "18", 0 );
	menu_additem(g_iReward, "\wNearest line drawing!", "19", 0 );
	menu_additem(g_iReward, "\wNearest ring indicator!", "20", 0 );
	menu_additem(g_iReward, "\wTrail!", "21", 0 );
	menu_additem(g_iReward, "\wLow-gravity!", "22", 0 );
	menu_additem(g_iReward, "\wWall penetration!", "23", 0 );
	
	g_iCore = menu_create("\yWho are you now? \r5.9", "menu_core")
	
	menu_additem(g_iCore, "\wLast Terrorist!", "1", 0 );
	menu_additem(g_iCore, "\wLast Counter-Terrorist", "2", 0 );
	menu_additem(g_iCore, "\yTerrorist!", "3", 0 );
	menu_additem(g_iCore, "\yCounter-Terrorist!", "4", 0 );
	menu_additem(g_iCore, "\yAll Terrorist Count!", "5", 0 );
	menu_additem(g_iCore, "\yAlive Terrorist Count!", "6", 0 );
	menu_additem(g_iCore, "\yNot-Alive Terrorist Count!", "7", 0 );
	menu_additem(g_iCore, "\wAll Counter Count!", "8", 0 );
	menu_additem(g_iCore, "\wAlive Counter Count!", "9", 0 );
	menu_additem(g_iCore, "\wNot-Alive Counter Count!", "10", 0 );
}

public reward_menu(id)
{
	if(is_user_alive(id) && get_user_flags(id) & ADMIN_FLAG)
	{
		// Show reward menu. ;)
		menu_display(id, g_iReward, 0)
	}
}

public menu_reward(const id, const menuid, const item)
{
	if(is_user_alive(id))
	{
		switch( item )
		{
			case 0:
			{
				// native cs_health_reward(id, Float:fHP, iType);
				// Float:fHP - is the value of health reward
				// iType - if you set it to 0, it will reset your health, so to give it as a reward
				// we set it into 1
				cs_health_reward(id, 20.0, 1)
			}
			case 1:
			{
				// native cs_armor_reward(id, Float:fAP, iType);
				// Float:fAP - is the value of armor reward
				// iType - if you set it to 0, it will reset your armor, so to give it as a reward
				// we set it into 1
				cs_armor_reward(id, 20.0, 1)
			}
			case 2:
			{
				// native cs_money_reward(id, iMoney, iType);
				// iMoney is the value of money reward
				// iType - if you set it to 0, it will reset your money, so to give it as a reward
				// we set it into 1
				cs_money_reward(id, 300, 1)
			}
			case 3:
			{
				// native cs_invisible_reward(id, iValue, iInvi, iType, Float:fInviT);
				// iValue - if you set it to 0, it will restore the reward
				// iInvi is the value of the visibility
				// iType - if you set it to 0, it will give permanent reward
				// Float:fInviT is the duration of the reward, the values must in decimal
				cs_invisible_reward(id, 1, 10, 1, 30.0)
			}
			case 4:
			{
				// native cs_noclip_reward(id, iValue, iType, Float:fNoclipT);
				// iValue - if you set it to 0, it will restore the reward
				// iType - if you set it to 0, it will give permanent reward
				// Float:fNoclipT is the duration of the reward, the values must in decimal
				cs_noclip_reward(id, 1, 1, 30.0)
			}
			case 5:
			{
				// native cs_grenade_reward(id, iGrenade, iType);
				// iGrenade is the value of grenade given
				// iType - 0; HE grenade || 1; Flashbang || 2; SMOKE grenade || 3:; All grenades
				cs_grenade_reward(id, 1, 3)
			}
			case 6:
			{
				// native cs_weapon_reward(id, const szWeapon[], iAmmo);
				// const szName[] is the name of weapon reward
				// for reference of the weapon names, just see above!
				cs_weapon_reward(id, "weapon_awp")
			}
			case 7:
			{
				// native cs_headshot_reward(id, iValue, iType, Float:fHeadshotT);
				// iValue - if you set it to 0, it will restore the reward
				// iType - if you set it to 0, it will give permanent reward
				// Float:fHeadshotT is the duration of the reward, the values must in decimal
				cs_headshot_reward(id, 1, 1, 30.0)
			}
			case 8:
			{
				// native cs_godmode_reward(id, iValue, iType, Float:fGodmodeT);
				// iValue - if you set it to 0, it will restore the reward
				// iType - if you set it to 0, it will give permanent reward
				// Float:fGodmodeT is the duration of the reward, the values must in decimal
				cs_godmode_reward(id, 1, 1, 30.0)
			}
			case 9:
			{
				// native cs_glow_reward(id, iValue, const g_iColor[], iType, Float:fGlowT);
				// iValue - if you set it to 0, it will restore the reward
				// const g_iColor[] - is color of glow
				// iType - if you set it to 0, it will give permanent reward
				// Float:fGlowT is the duration of the reward, the values must in decimal
				cs_glow_reward(id, 1, "0 0 255", 1, 30.0)
			}
			case 10:
			{
				// nnative cs_aura_reward(id, iValue, const g_iColor[], iType, Float:fAuraT);
				// iValue - if you set it to 0, it will restore the reward
				// const g_iColor[] - is color of aura
				// iType - if you set it to 0, it will give permanent reward
				// Float:fAuraT is the duration of the reward, the values must in decimal
				cs_aura_reward(id, 1, "0 0 255", 1, 30.0)
			}
			case 11:
			{
				// native cs_speed_reward(id, iValue, g_iAddSpeed, iType, Float:fSpeedT);
				// iValue - if you set it to 0, it will restore the reward
				// g_iAddSpeed is the value of speed boost
				// iType - if you set it to 0, it will give permanent reward
				// Float:fSpeedT is the duration of the reward
				cs_speed_reward(id, 1, 150, 1, 30.0)
			}
			case 12:
			{
				// native cs_jump_reward(id, iValue, g_iAddJump, iType, Float:fJumpT);
				// iValue - if you set it to 0, it will restore the reward
				// g_iAddJump is the value of multi-jump
				// iType - if you set it to 0, it will give permanent reward
				// Float:fJumpT is the duration of the reward
				cs_jump_reward(id, 1, 3, 1, 30.0)
			}
			case 13:
			{
				// native cs_unlimited_reward(id, iValue, iType, Float:fUnlimitT);
				// This is to give unlimited bullet rewards
				// id - ID of client
				// iValue - if you set it to 0, it will restore the reward || 1; Unlimited clip ammo || 2; Unlimited BP ammo
				// iType - if you set it to 0, it will give permanent unlimited bullet
				// Float:fUnlimitT - the durations of the reward
				cs_unlimited_reward(id, 1, 1, 30.0);
			}
			case 14:
			{
				// native cs_unlimited_reward(id, iValue, iType, Float:fUnlimitT);
				// This is to give unlimited bullet rewards
				// id - ID of client
				// iValue - if you set it to 0, it will restore the reward || 1; Unlimited clip ammo || 2; Unlimited BP ammo
				// iType - if you set it to 0, it will give permanent unlimited bullet
				// Float:fUnlimitT - the durations of the reward
				cs_unlimited_reward(id, 2, 1, 30.0);
			}
			case 15:
			{
				// native cs_norecoil_reward(id, iValue, iType, Float:fRecoilT);
				// This is to give no-recoil rewards
				// id - ID of client
				// iValue - if you set it to 0, it will restore the reward
				// iType - if you set it to 0, it will give permanent no-recoil
				// Float:fRecoilT - the durations of the reward
				cs_norecoil_reward(id, 1, 1, 30.0);
			}
			case 16:
			{
				// native cs_line_reward(id, iValue, const g_iColor[], g_iFindLine, iType, Float:fLineT);
				// This is to give line drawing ability
				// id - ID of client
				// iValue - if you set it to 0, it will restore the reward
				// const g_iColor[] - is color of line
				// g_iFindLine - allow you to configure the finding
				// iType - if you set it to 0, it will give permanent line drawing
				// Float:fLineT - the durations of the reward
				cs_line_reward(id, 1, "255 0 0", 0, 1, 30.0);
			}
			case 17:
			{
				// native cs_ring_reward(id, iValue, g_iFindRing, const g_iColor[], iType, Float:fRingT);
				// This is to give ring indicator ability
				// id - ID of client
				// iValue - if you set it to 0, it will restore the reward
				// const g_iColor[] - is color of ring
				// g_iFindRing - allow you to configure the color
				// iType - if you set it to 0, it will give permanent ring indicator
				// Float:fRingT - the durations of the reward
				cs_ring_reward(id, 1, "255 0 0", 0, 1, 30.0);
			}
			case 18:
			{
				cs_line_reward(id, 1, "255 0 0", 1, 1, 30.0);
			}
			case 19:
			{
				cs_ring_reward(id, 1, "255 0 0", 1, 1, 30.0);
			}
			case 20:
			{
				// native cs_trail_reward(id, iValue, const g_iColor[], iType, Float:fTrailT);
				// id - ID of client
				// iValue - if you set it to 0, it will restore the reward
				// g_iColor[] - is color of trail
				// iType - if you set it to 0, it will give permanent trail
				// Float:fTrailT - the durations of the reward
				cs_trail_reward(id, 1, "255 127 0", 1, 30.0)
			}
			case 21:
			{
				// native cs_gravity_reward(id, iValue, Float:g_iAddLow, iType, Float:fLowT);
				// id - ID of client
				// iValue - if you set it to 0, it will restore the reward
				// g_iAddLow - the values of custom gravity
				// iType - if you set it to 0, it will give custom gravity
				// Float:fLowT - the durations of the reward
				cs_gravity_reward(id, 1, 0.5, 1, 30.0)
			}
			case 22:
			{
				// native cs_wall_reward(id, iValue, iType, Float:fWallT);
				// id - ID of client
				// iValue - if you set it to 0, it will restore the reward
				// iType - if you set it to 0, it will give permanent wall ability
				// Float:fWallT - the durations of the reward
				cs_wall_reward(id, 1, 1, 60.0)
			}
		}
		
		menu_cancel(id)
	}
}

public core_menu(id)
{
	// Only player that have access can open the menu
	if(is_user_alive(id) && get_user_flags(id) & ADMIN_FLAG)
	{
		// Show cs_core menu
		menu_display(id, g_iCore, 0)
	}
}

public menu_core(const id, const menuid, const item)
{
	if(is_user_alive(id))
	{
		switch( item )
		{
			case 0:
			{
				// This is how to use native cs_is_last_terrorist(id)
				if(cs_is_last_terrorist(id))
				{
					client_print(id, print_chat, "[ZM] Now, you are the last terrorist!")
				}
				else
				{
					client_print(id, print_chat, "[ZM] Now, you are not the last terrorist!")
				}
			}
			case 1:
			{
				// This is how to use native cs_is_last_counter(id)
				if(cs_is_last_counter(id))
				{
					client_print(id, print_chat, "[ZM] Now, you are the last counter-terrorist!")
				}
				else
				{
					client_print(id, print_chat, "[ZM] Now, you are not the last counter-terrorist!")
				}
			}
			case 2:
			{
				// This is how to use native cs_is_terrorist(id)
				if(cs_is_terrorist(id))
				{
					client_print(id, print_chat, "[ZM] Now, you are the terrorist!")
				}
				else
				{
					client_print(id, print_chat, "[ZM] Now, you are not the terrorist!")
				}
			}
			case 3:
			{
				// This is how to use native cs_is_terrorist(id)
				if(!cs_is_terrorist(id))
				{
					client_print(id, print_chat, "[ZM] Now, you are the counter-terrorist!")
				}
				else
				{
					client_print(id, print_chat, "[ZM] Now, you are not the counter-terrorist!")
				}
			}
			case 4:
			{
				new iHud = cs_get_terrorist_count(0)
				
				set_hudmessage(0, 255, 255, -1.0, 0.35, 0, 6.0, 6.0, 0.5, 0.15, -1)
				show_hudmessage(0, "All Terrorist: %d players!", iHud)
			}
			case 5:
			{
				new iHud = cs_get_terrorist_count(1)
				
				set_hudmessage(0, 255, 255, -1.0, 0.35, 0, 6.0, 6.0, 0.5, 0.15, -1)
				show_hudmessage(0, "Alive Terrorist: %d players!", iHud)
			}
			case 6:
			{
				new iHud = cs_get_terrorist_count(2)
				
				set_hudmessage(0, 255, 255, -1.0, 0.35, 0, 6.0, 6.0, 0.5, 0.15, -1)
				show_hudmessage(0, "Not-Alive Terrorist: %d players!", iHud)
			}
			case 7:
			{
				new iHud = cs_get_counter_count(0)
				
				set_hudmessage(0, 255, 255, -1.0, 0.35, 0, 6.0, 6.0, 0.5, 0.15, -1)
				show_hudmessage(0, "All Counter-Terrorist: %d players!", iHud)
				/*
				// If all counter-terrorist is 3
				if(cs_get_counter_count(0) == 3)
				{
					set_hudmessage(0, 255, 255, -1.0, 0.35, 0, 6.0, 6.0, 0.5, 0.15, -1)
					show_hudmessage(0, "All Counter-Terrorist = 3 players!")
				}
				else
				{
					client_print(id, print_chat, "[ZM] Now, all counter-terrorist not equal to 3!")
				}
				*/
			}
			case 8:
			{
				new iHud = cs_get_counter_count(1)
				
				set_hudmessage(0, 255, 255, -1.0, 0.35, 0, 6.0, 6.0, 0.5, 0.15, -1)
				show_hudmessage(0, "Alive Counter-Terrorist: %d players!", iHud)
				/*
				// If alive counter-terrorist is more than 3
				if(cs_get_counter_count(1) == 2)
				{
					set_hudmessage(0, 255, 255, -1.0, 0.35, 0, 6.0, 6.0, 0.5, 0.15, -1)
					show_hudmessage(0, "Alive Counter-Terrorist = 2 players!")
				}
				else
				{
					client_print(id, print_chat, "[ZM] Now, all counter-terrorist not equal to 2!")
				}
				*/
			}
			case 9:
			{
				new iHud = cs_get_counter_count(2)
				
				set_hudmessage(0, 255, 255, -1.0, 0.35, 0, 6.0, 6.0, 0.5, 0.15, -1)
				show_hudmessage(0, "Not-Alive Counter-Terrorist: %d players!", iHud)
				/*
				// If not-alive counter-terrorist is more than 2
				if(cs_get_counter_count(2) == 1)
				{
					set_hudmessage(0, 255, 255, -1.0, 0.35, 0, 6.0, 6.0, 0.5, 0.15, -1)
					show_hudmessage(0, "Not-Alive Counter-Terrorist = 1 players!")
				}
				else
				{
					client_print(id, print_chat, "[ZM] Now, not-alive counter-terrorist not equal to 1!")
				}
				*/
			}
		}
	
		menu_cancel(id)
	}
}

public im_trap(id)
{
	cs_istrap(id)
}

// This is called when a player spawn
// forward cs_fw_spawn_post(id);
public cs_fw_spawn_post(id)
{
	// If the player is a terrorist, we set the HP to 120
	// else we set the HP to 140
	cs_is_terrorist(id) ? cs_health_reward(id, 120.0, 0) : cs_health_reward(id, 140.0, 0)
}

// This is called when a player has drew the first blood
// forward cs_fw_first_blood(victim, attacker)
public cs_fw_first_blood(victim, attacker)
{
	new szName[32], szName2[32]
	get_user_name(attacker, szName, charsmax(szName)) 
	get_user_name(victim, szName2, charsmax(szName2)) 
	
	// Show the hud message about the first attacker and first victim
	set_hudmessage(random_num(10,255), random(256), random(256), -1.0, 0.20, 0, 6.0, 12.0, 0.0, 0.0, -1)
	show_hudmessage(0,"%s drew a first blood^nFirst victim is %s!", szName, szName2) 
}

// This is called when a player becomes the last terrorists
// forward cs_fw_last_terrorist(id)
public cs_fw_last_terrorist(id)
{
	// Print the message to tell that the player is the last player in the team
	client_print(id, print_chat, "[ZM] Now, you are the last terrorist!")
	
	// Free HP reward
	cs_health_reward(id, 40.0, 1)
	
	// Free armor reward
	cs_armor_reward(id, 40.0, 1)
}

// This is called when a player becomes the last counter-terrorists
// forward cs_fw_last_counter(id)
public cs_fw_last_counter(id)
{
	// Print the message to tell that the player is the last player in the team
	client_print(id, print_chat, "[ZM] Now, you are the last counter-terrorist!")
	
	// Free HP reward
	cs_health_reward(id, 40.0, 1)
	
	// Free armor reward
	cs_armor_reward(id, 40.0, 1)
}
