#if defined _cs_core_included
  #endinput
#endif
#define _cs_core_included

#if AMXX_VERSION_NUM >= 175
	#pragma reqlib cs_core
	#if !defined AMXMODX_NOAUTOLOAD
		#pragma loadlib cs_core
	#endif
#else
	#pragma library cs_core
#endif

/****************************************************
*                    CS Core                        *
*****************************************************/
/**
 * Return whether a player is a terrorist
 * param id - ID of client
 */
native cs_is_terrorist(id);

/**
 * Return whether a player is the last terrorist
 * param id - ID of client
 */
native cs_is_last_terrorist(id);

/**
 * Return whether a player is the last counter-terrorist
 * param id - ID of client
 */
native cs_is_last_counter(id);

/**
 * Returns number of alive terrorists
 * param iType - 0; Show all || 1; Alive players || 2; Not-alive players
 */
native cs_get_terrorist_count(iType);

/**
 * Return number of alive counter-terrorists
 * param iType - 0; Show all || 1; Alive players || 2; Not-alive players
 */
native cs_get_counter_count(iType);

/**
 * This is called during a player spawn
 * param id - ID of client
 */
forward cs_fw_spawn_post(id);

/**
 * This is called when a player becomes the last terrorists
 * param id - ID of client
 */
forward cs_fw_last_terrorist(id);

/**
 * This is called when a player becomes the last counter-terrorists
 * param id - ID of client
 */
forward cs_fw_last_counter(id);

/**
 * This is called when a player has drew the first blood
 * param victim - ID of client
 * param attacker - ID of client
 */
forward cs_fw_first_blood(victim, attacker);

/****************************************************
*                    CS Reward                      *
*****************************************************/
/*
 * This is to give health rewards.
 * param id - ID of client
 * param Float:fHP - the values of health given
 * param iType - if you set it to 0, it will reset your health
*/
native cs_health_reward(id, Float:fHP, iType);

/*
 * This is to give armor rewards.
 * param id - ID of client
 * param Float:fAP - the values of armor given
 * param iType - if you set it to 0, it will reset your armor
*/
native cs_armor_reward(id, Float:fAP, iType);

/*
 * This is to give money rewards.
 * param id - ID of client
 * param iMoney - the values of money given
 * param iType - if you set it to 0, it will reset your money
*/
native cs_money_reward(id, iMoney, iType);

/*
 * This is to give invisible rewards.
 * param id - ID of client
 * param iValue - if you set it to 0, it will restore the reward
 * param iInvi - the values of visibility
 * param iType - if you set it to 0, it will give permanent reward
 * param Float:fInviT - the durations of the reward
*/
native cs_invisible_reward(id, iValue, iInvi, iType, Float:fInviT);

/*
 * This is to give noclip rewards.
 * param id - ID of client
 * param iValue - if you set it to 0, it will restore the reward
 * param iType - if you set it to 0, it will give permanent noclip
 * param Float:fNoclipT - the durations of the reward
*/
native cs_noclip_reward(id, iValue, iType, Float:fNoclipT);

/*
 * This is to enable unstuc2 feature
 * param id - ID of client
*/
native cs_istrap(id);

/*
 * This is to give grenade rewards.
 * param id - ID of client
 * param iGrenade - the values of grenades given
 * param iType - 0; HE grenade || 1; Flashbang || 2; Smo2e grenade || 3:; All grenades
*/
native cs_grenade_reward(id, iGrenade, iType);

/*
 * This is to give weapon rewards.
 * param id - ID of client
 * param const szName[] - the name of weapon given
*/
native cs_weapon_reward(id, const szName[]);

/*
 * This is to give headshot rewards.
 * param id - ID of client
 * param iValue - if you set it to 0, it will restore the reward
 * param iType - if you set it to 0, it will give permanent headshot
 * param Float:fHeadshotT - the durations of the reward
*/
native cs_headshot_reward(id, iValue, iType, Float:fHeadshotT);

/*
 * This is to give godmode rewards.
 * param id - ID of client
 * param iValue - if you set it to 0, it will restore the reward
 * param iType - if you set it to 0, it will give permanent godmode
 * param Float:fGodmodeT - the durations of the reward
*/
native cs_godmode_reward(id, iValue, iType, Float:fGodmodeT);

/*
 * This is to give glow rewards.
 * param id - ID of client
 * param iValue - if you set it to 0, it will restore the reward
 * param const g_iColor[] - is color of glow
 * param iType - if you set it to 0, it will give permanent glow
 * param Float:fGlowT - the durations of the reward
*/
native cs_glow_reward(id, iValue, const g_iColor[], iType, Float:fGlowT);

/*
 * This is to give aura rewards
 * param id - ID of client
 * param iValue - if you set it to 0, it will restore the reward
 * param const g_iColor[] - is color of aura
 * param iType - if you set it to 0, it will give permanent aura
 * param Float:fAuraT - the durations of the reward
*/
native cs_aura_reward(id, iValue, const g_iColor[], iType, Float:fAuraT);

/*
 * This is to give speed boost rewards
 * param id - ID of client
 * param iValue - if you set it to 0, it will restore the reward
 * param g_iAddSpeed - the values of speed boost
 * param iType - if you set it to 0, it will give permanent speed boost
 * param Float:fSpeedT - the durations of the reward
*/
native cs_speed_reward(id, iValue, g_iAddSpeed, iType, Float:fSpeedT);

/*
 * This is to give multi-jump rewards
 * param id - ID of client
 * param iValue - if you set it to 0, it will restore the reward
 * param g_iAddJump - the values of multi-jump
 * param iType - if you set it to 0, it will give permanent multi-jump
 * param Float:fJumpT - the durations of the reward
*/
native cs_jump_reward(id, iValue, g_iAddJump, iType, Float:fJumpT);

/*
 * This is to give unlimited bullet rewards
 * param id - ID of client
 * param iValue - if you set it to 0, it will restore the reward || 1; Unlimited clip ammo || 2; Unlimited BP ammo
 * param iType - if you set it to 0, it will give permanent unlimited bullet
 * param Float:fUnlimitT - the durations of the reward
*/
native cs_unlimited_reward(id, iValue, iType, Float:fUnlimitT);

/*
 * This is to give no-recoil rewards
 * param id - ID of client
 * param iValue - if you set it to 0, it will restore the reward
 * param iType - if you set it to 0, it will give permanent no-recoil
 * param Float:fRecoilT - the durations of the reward
*/
native cs_norecoil_reward(id, iValue, iType, Float:fRecoilT);

/*
 * This is to give line drawing rewards
 * param id - ID of client
 * param iValue - if you set it to 0, it will restore the reward
 * param const g_iColor[] - is color of line
 * param g_iFindLine - allow you to configure the finding. 0; All alive players || 1; Nearest player
 * param iType - if you set it to 0, it will give permanent line drawing
 * param Float:fLineT - the durations of the reward
*/
native cs_line_reward(id, iValue, const g_iColor[], g_iFindLine, iType, Float:fLineT);

/*
 * This is to give ring indicator rewards
 * param id - ID of client
 * param iValue - if you set it to 0, it will restore the reward
 * param const g_iColor[] - is color of ring
 * param g_iFindRing - allow you to configure the color. 0; All alive players || 1; Nearest player
 * param iType - if you set it to 0, it will give permanent ring indicator
 * param Float:fRingT - the durations of the reward
*/
native cs_ring_reward(id, iValue, const g_iColor[], g_iFindRing, iType, Float:fRingT);

/*
 * This is to give trail rewards
 * param id - ID of client
 * param iValue - if you set it to 0, it will restore the reward
 * param const g_iColor[] - is color of trail
 * param iType - if you set it to 0, it will give permanent trail
 * param Float:fTrailT - the durations of the reward
*/
native cs_trail_reward(id, iValue, const g_iColor[], iType, Float:fTrailT);

/*
 * This is to give gravity rewards
 * param id - ID of client
 * param iValue - if you set it to 0, it will restore the reward
 * param g_iAddLow - the values of custom gravity
 * param iType - if you set it to 0, it will give permanent custom gravity
 * param Float:fLowT - the durations of the reward
*/
native cs_gravity_reward(id, iValue, Float:g_iAddLow, iType, Float:fLowT);

/*
 * This is to give wall rewards
 * param id - ID of client
 * param iValue - if you set it to 0, it will restore the reward
 * param iType - if you set it to 0, it will give permanent wall ability
 * param Float:fWallT - the durations of the reward
*/
native cs_wall_reward(id, iValue, iType, Float:fWallT);

/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1033\\ f0\\ fs16 \n\\ par }
*/