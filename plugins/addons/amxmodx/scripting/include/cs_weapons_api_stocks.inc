#if defined _cswa_stocks_included
  #endinput
#endif
#define _cswa_stocks_included

#if !defined _cswa_included
	#include <cs_weapons_api>
#endif

stock const Float:g_fReloadTime[] =
{
	0.00,	// NULL
	2.70,   // CSW_P228
	0.00,   // NULL
	2.00,   // CSW_SCOUT
	0.00,   // CSW_HEGRENADE
	0.55,   // CSW_XM1014
	0.00,   // CSW_C4
	3.15,   // CSW_MAC10
	3.30,   // CSW_AUG
	0.00,   // CSW_SMOKEGRENADE
	4.50,   // CSW_ELITE
	2.70,   // CSW_FIVESEVEN
	3.50,   // CSW_UMP45
	3.35,   // CSW_SG550
	2.45,   // CSW_GALIL
	3.30,   // CSW_FAMAS
	2.70,   // CSW_USP
	2.20,   // CSW_GLOCK
	2.50,   // CSW_AWP
	2.63,   // CSW_MP5NAVY
	4.70,   // CSW_M249
	0.55,   // CSW_M3
	3.05,   // CSW_M4A1
	2.12,   // CSW_TMP
	3.50,   // CSW_G3SG1
	0.00,   // CSW_FLASHBANG
	2.20,   // CSW_DEAGLE
	3.00,   // CSW_SG552
	2.45,   // CSW_AK47
	0.00,   // CSW_KNIFE
	3.40    // CSW_P90
};

stock const g_iWeaponSlots[] =
{
	0,		// NULL
	2,		// CSW_P228
	0,		// NULL
	1,		// CSW_SCOUT
	4,		// CSW_HEGRENADE
	1,		// CSW_XM1014
	5,		// CSW_C4
	1,		// CSW_MAC10
	1,		// CSW_AUG
	4,		// CSW_SMOKEGRENADE
	2,		// CSW_ELITE
	2,		// CSW_FIVESEVEN
	1,		// CSW_UMP45
	1,		// CSW_SG550
	1,		// CSW_GALIL
	1,		// CSW_FAMAS
	2,		// CSW_USP
	2,		// CSW_GLOCK
	1,		// CSW_AWP
	1,		// CSW_MP5NAVY
	1,		// CSW_M249
	1,		// CSW_M3
	1,		// CSW_M4A1
	1,		// CSW_TMP
	1,		// CSW_G3SG1
	4,		// CSW_FLASHBANG
	2,		// CSW_DEAGLE
	1,		// CSW_SG552
	1,		// CSW_AK47
	3,		// CSW_KNIFE
	1		// CSW_P90
};

stock ham_strip_weapon(id, const weapon[])
{
	if(!is_user_alive(id))
		return 0;

	new weapon_ent = find_ent_by_owner(-1, weapon, id);
	if(!weapon_ent)
		return 0;

	new weapon_id = get_weaponid(weapon);
	if(!weapon_id)
		return 0;

	if(get_user_weapon(id) == weapon_id)
		ExecuteHamB(Ham_Weapon_RetireWeapon, weapon_ent);

	if(!ExecuteHamB(Ham_RemovePlayerItem, id, weapon_ent))
		return 0;

	user_has_weapon(id, weapon_id, 0);
	ExecuteHamB(Ham_Item_Kill, weapon_ent);
	remove_user_shield(id);
	//set_pev(id, pev_weapons, pev(id, pev_weapons) & ~(1<<weapon_id));

	return 1;
}

stock ham_give_weapon(id, weapon[], val = 0)
{
	if(!is_user_alive(id))
		return 0;

	if(!equal(weapon, "weapon_", 7))
		return 0;

	new ent = create_entity(weapon);
	if(!is_valid_ent(ent))
		return 0;

	entity_set_int(ent, EV_INT_spawnflags, SF_NORESPAWN);
	DispatchSpawn(ent);

	if(!ExecuteHamB(Ham_AddPlayerItem, id, ent))
	{
		if(is_valid_ent(ent))
			entity_set_int(ent, EV_INT_flags, entity_get_int(ent, EV_INT_flags) | FL_KILLME);
		return 0;
	}

	ExecuteHamB(Ham_Item_AttachToPlayer, ent, id);
	if(val && !is_user_bot(id))
		//ExecuteHamB(Ham_Item_Deploy, fm_find_ent_by_owner(-1, weapon, id));
		show_weapon(id, weapon);

	return ent;
}

stock show_weapon(id, weapon[])
{
	if(is_user_bot(id))
		return;

	if(user_has_weapon(id, get_weaponid(weapon)))
		ExecuteHamB(Ham_Item_Deploy, find_ent_by_owner(-1, weapon, id));

	engclient_cmd(id, weapon);
}

stock no_ammo_weapon(weapon_id)
{
	if(weapon_id == CSW_KNIFE || weapon_id == CSW_HEGRENADE || weapon_id == CSW_SMOKEGRENADE || weapon_id == CSW_FLASHBANG
	|| weapon_id == CSW_C4)
		return 1;

	return 0;
}

stock get_weapon_owner(ent)
	return get_pdata_cbase(ent, 41, 4);

stock slot_filled(id, slot)
	return get_pdata_cbase(id, 367+slot) > 0;

stock check_player_slot(id, weapon_ent)
{
	new slot = ExecuteHam(Ham_Item_ItemSlot, weapon_ent);
	if(slot_filled(id, slot) && !user_has_weapon(id, cs_get_weapon_id(weapon_ent)))
		return 1;

	return 0;
}

stock UTIL_PlayWeaponAnimation(const id, const seq)
{
	set_pev(id, pev_weaponanim, seq);
	
	message_begin(MSG_ONE_UNRELIABLE, SVC_WEAPONANIM, _, id);
	write_byte(seq);
	write_byte(pev(id, pev_body));
	message_end();
}