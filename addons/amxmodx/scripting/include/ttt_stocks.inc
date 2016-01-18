#if defined _ttt_stocks_included
  #endinput
#endif
#define _ttt_stocks_included

#if !defined _ttt_included
	#include <ttt>
#endif

#define LOG_MSG_SIZE 200
stock const death_messages[][] =
{
	"TTT_KILL_SUICIDE",
	"TTT_KILL_GENERIC",
	"TTT_KILL_SLASH",
	"TTT_KILL_BURN",
	"TTT_KILL_FREEZE",
	"TTT_KILL_FALL",
	"TTT_KILL_BLAST",
	"TTT_KILL_SHOCK",
	"TTT_KILL_DROWN",
	"TTT_KILL_NERVEGAS",
	"TTT_KILL_POISON",
	"TTT_KILL_RADIATION",
	"TTT_KILL_ACID"
};

stock const special_names[][] =
{
	"TTT_NONE",
	"TTT_TRAITOR",
	"TTT_DETECTIVE",
	"TTT_INNOCENT",
	"TTT_DEAD",
	"TTT_SPECIAL"
};

stock const player_loyalty[][] =
{
	"TTT_LOYALTY_NONE",
	"TTT_LOYALTY_PROVABLE",
	"TTT_LOYALTY_SUSPICIOUS",
	"TTT_LOYALTY_AVOIDABLE",
	"TTT_LOYALTY_TRAITOROUS"
};

stock is_dead_body(classname[])
{
	if(equal(classname, TTT_DEADBODY))
		return 1;
	return 0;
}

stock ttt_return_check(id)
{
	new game = ttt_get_gamemode();
	if(!is_user_connected(id) || game == GAME_OFF || game == GAME_ENDED)
		return 1;

	return 0;
}

stock ttt_get_gamemode()
	return ttt_get_globalinfo(GI_GAMEMODE);

stock ttt_get_playerstate(id)
	return ttt_get_playerdata(id, PD_PLAYERSTATE);

stock ttt_is_exception(victim)
{
	new item = ttt_get_playerdata(victim, PD_KILLEDBYITEM);
	if(item > -1)
		return ttt_find_exception(item);

	return 0;
}

stock ttt_get_alivestate(id)
{
	if(!is_user_alive(id))
		return ttt_get_playerdata(id, PD_KILLEDSTATE);

	return ttt_get_playerstate(id);
}

stock ttt_get_user_name(id, name[], size)
{
	new other_id = ttt_get_playerdata(id, PD_OTHERNAME);
	if(!is_user_connected(other_id) || is_user_alive(other_id))
	{
		other_id = id;
		ttt_set_playerdata(id, PD_OTHERNAME, 0);
	}

	get_user_name(other_id, name, size);
}

stock ttt_state_special(player_state)
{
	return player_state == PC_TRAITOR || player_state == PC_DETECTIVE;
}

stock escape_mysql(string[], len)
{
	replace_all(string, len, "\\", "\\\\");
	replace_all(string, len, "\0", "\\0");
	replace_all(string, len, "\n", "\\n");
	replace_all(string, len, "\r", "\\r");
	replace_all(string, len, "\x1a", "\Z");
	replace_all(string, len, "'", "\'");
	replace_all(string, len, "%", "\%");
	replace_all(string, len, "#", "\#");
	replace_all(string, len, ";", "\;");
	replace_all(string, len, "_", "\_");
}

stock auto_exec_config(const szName[])
{
	new szFileName[32];
	new iLen = copy(szFileName, charsmax(szFileName), szName);
	if(iLen <= 4 || !equal(szFileName[iLen-4], ".cfg"))
		add(szFileName, charsmax(szFileName), ".cfg");

	new szConfigPath[96];
	get_localinfo("amxx_configsdir", szConfigPath, charsmax(szConfigPath));
	format(szConfigPath, charsmax(szConfigPath), "%s/%s", szConfigPath, szFileName);

	if(file_exists(szConfigPath))
	{
		server_cmd("exec %s", szConfigPath);
		server_exec();
		return 1;
	}

	return 0;
}

stock create_icon_origin(id, Float:origin[3], sprite, scale) // By sontung0
{
	if(!is_in_viewcone(id, origin))
		return;

	new Float:fMyOrigin[3];
	entity_get_vector(id, EV_VEC_origin, fMyOrigin);

	new Float:fMiddle[3], Float:fHitPoint[3];
	xs_vec_sub(origin, fMyOrigin, fMiddle);
	trace_line(-1, fMyOrigin, origin, fHitPoint);

	new Float:fWallOffset[3], Float:fDistanceToWall;
	fDistanceToWall = vector_distance(fMyOrigin, fHitPoint) - 10.0;
	normalize(fMiddle, fWallOffset, fDistanceToWall);

	new Float:fSpriteOffset[3];
	xs_vec_add(fWallOffset, fMyOrigin, fSpriteOffset);

	te_sprite(id, fSpriteOffset, sprite, scale);
}

stock te_sprite(id, Float:origin[3], sprite, scale) // By sontung0
{	
	message_begin(MSG_ONE_UNRELIABLE, SVC_TEMPENTITY, _, id);
	write_byte(TE_SPRITE);
	write_coord(floatround(origin[0]));
	write_coord(floatround(origin[1]));
	write_coord(floatround(origin[2]));
	write_short(sprite);
	write_byte(scale);
	write_byte(255);
	message_end();
}

stock normalize(Float:fIn[3], Float:fOut[3], Float:fMul) // By sontung0
{
	new Float:fLen = xs_vec_len(fIn);
	xs_vec_copy(fIn, fOut);
	
	fOut[0] /= fLen, fOut[1] /= fLen, fOut[2] /= fLen;
	fOut[0] *= fMul, fOut[1] *= fMul, fOut[2] *= fMul;
}

stock ttt_is_jailmap()
{
	static mapname[32];
	get_mapname(mapname, charsmax(mapname));

	if(equali(mapname, "jail_", 5) || equali(mapname, "jb_", 3) || equali(mapname, "jailbreak_", 10))
		return 1;

	return 0;
}

stock ttt_make_deathmsg(killer, victim, headshot, const weapon[], flags)
{
	if(!is_user_connected(victim) || !is_user_connected(killer))
		return;

	static const cvar_state[] =
	{
		(1<<0),	// a = PC_NONE,
		(1<<1),	// b = TRAITOR,
		(1<<2),	// c = DETECTIVE,
		(1<<3),	// d = INNOCENT,
		(1<<4),	// e = PC_DEAD,
		(1<<5),	// f = PC_SPECIAL,
		(1<<6),	// g = show victim
		(1<<7)	// h = show killer
	};

	static const size = PLAYER_CLASS+2;
	new show[PLAYER_CLASS+2];
	for(new i; i < size; i++)
	{
		if(flags & cvar_state[i])
			show[i] = i;
	}
	
	static msg;
	if(!msg)
		msg = get_user_msgid("DeathMsg");

	static players[32];
	new i, j, should, specstate, num;
	get_players(players, num);
	for(--num; num >= 0; num--)
	{
		i = players[num];
		specstate = ttt_get_playerstate(i);
		
		should = false;
		if(i == victim && show[PLAYER_CLASS])
			should = true;
		else if(i == killer && show[PLAYER_CLASS+1])
			should = true;
		else
		{
			for(j = 0; j < PLAYER_CLASS; j++)
			{
				if(specstate == show[j])
				{
					should = true;
					break;
				}
			}
		}

		if(should)
		{
			message_begin(MSG_ONE_UNRELIABLE, msg, _, i);
			write_byte(killer);
			write_byte(victim);
			write_byte(headshot);
			write_string(weapon);
			message_end();
		}
	}	
}

stock ttt_find_valid_killer(victim, killer)
{
	new new_killer = ttt_get_playerdata(victim, PD_KILLEDBY);
	return new_killer ? new_killer : killer;
}

stock ttt_get_kill_message(victim, killer, message[], len, type=0)
{
	if(!is_user_alive(victim))
	{
		static const weapon_names[][] = 
		{
			"suicide", "p228", "", "scout", "hegrenade", "xm1014", "c4", "mac10", "aug", "hegrenade", "elite", "fiveseven",
			"ump45", "sg550", "galil", "famas", "usp", "glock18", "awp", "mp5navy", "m249", "m3", "m4a1", "tmp", "g3sg1", "hegrenade",
			"deagle", "sg552", "ak47", "crowbar", "p90"
		};

		static weapmsg[32];
		new item_id = ttt_get_playerdata(victim, PD_KILLEDBYITEM);
		if(item_id > -1)
			ttt_get_item_name(item_id, weapmsg, charsmax(weapmsg));
		else
		{
			//killer = ttt_get_playerdata(victim, KILLEDBY);
			new weap = ttt_get_playerdata(victim, PD_KILLEDWEAP);
			if(weap >= 3000)
				formatex(weapmsg, charsmax(weapmsg), "%L", LANG_PLAYER, death_messages[weap-3000]);
			else formatex(weapmsg, charsmax(weapmsg), "%s", weapon_names[weap]);
		}

		if(type)
		{
			if(is_user_connected(killer))
			{
				static name[32];
				get_user_name(killer, name, charsmax(name));
				formatex(message, len, "[%L] %s with %s", LANG_PLAYER, special_names[ttt_get_alivestate(killer)], name, weapmsg);
			}
			else formatex(message, len, "%s", weapmsg);
		}
		else formatex(message, len, "%s", weapmsg);

		return 1;
	}

	return 0;
}

stock ttt_log_api_error(text[], plugin, params, any:...)
{
	static plugin_name[32], msg[LOG_MSG_SIZE];
	get_plugin(plugin, plugin_name, charsmax(plugin_name));
	vformat(msg, charsmax(msg), text, 4);
	ttt_log_to_file(LOG_ERROR, "%s (params %d, plugin: %s)", msg, params, plugin_name);
	return 0;
}

stock ttt_log_to_file(type, text[], any:...)
{
	static msg[LOG_MSG_SIZE];
	vformat(msg, charsmax(msg), text, 3);
	ttt_logging(type, msg);
}

stock find_dead_body_1d(id, array[], count)
{
	new Float:fOrigin[2][3], origin[3];
	entity_get_vector(id, EV_VEC_origin, fOrigin[0]);
	get_user_origin(id, origin, 3);
	IVecFVec(origin, fOrigin[1]);
	if(get_distance_f(fOrigin[0], fOrigin[1]) > 60.0)
		return 0;

	for(new ent, i = 0; i < count; i++)
	{
		ent = array[i];
		if(!is_valid_ent(ent) || !is_visible(id, ent))
			continue;

		if(get_dat_deadbody(ent, fOrigin[0], fOrigin[1]))
			return ent;
	}

	return 0;
}

stock find_dead_body_2d(id, array[33][])
{
	new Float:fOrigin[2][3], origin[3];
	entity_get_vector(id, EV_VEC_origin, fOrigin[0]);
	get_user_origin(id, origin, 3);
	IVecFVec(origin, fOrigin[1]);
	if(get_distance_f(fOrigin[0], fOrigin[1]) > 60.0)
		return 0;

	for(new ent, i = 0; i < 33; i++)
	{
		ent = array[i][BODY_ENTID];
		if(!is_valid_ent(ent) || !is_visible(id, ent))
			continue;

		if(get_dat_deadbody(ent, fOrigin[0], fOrigin[1]))
			return ent;
	}

	return 0;
}

stock get_dat_deadbody(ent, Float:startOrigin[3], Float:endOrigin[3])
{
	if(!is_valid_ent(ent))
		return false;

	new ptr = create_tr2();
	engfunc(EngFunc_TraceModel, startOrigin, endOrigin, HULL_POINT, ent, ptr);
	if(get_tr2(ptr, TR_pHit) == ent)
	{
		free_tr2(ptr);
		return true;
	}

	free_tr2(ptr);
	return false;
}

stock set_attrib_all(id, msg)
{
	if(!is_user_connected(id))
		return;

	static g_Msg_ScoreAttrib;
	if(!g_Msg_ScoreAttrib)
		g_Msg_ScoreAttrib = get_user_msgid("ScoreAttrib");

	message_begin(MSG_BROADCAST, g_Msg_ScoreAttrib);
	write_byte(id);
	write_byte(msg);
	message_end();
}

stock set_attrib_special(id, msg, special1, special2=-1, special3=-1, special4=-1)
{
	if(!is_user_connected(id))
		return;

	static g_Msg_ScoreAttrib;
	if(!g_Msg_ScoreAttrib)
		g_Msg_ScoreAttrib = get_user_msgid("ScoreAttrib");

	new num, i, specstate;
	static players[32];
	get_players(players, num);
	for(--num; num >= 0; num--)
	{
		i = players[num];
		specstate = ttt_get_playerstate(i);
		if(specstate == special1 || specstate == special2 || specstate == special3 || specstate == special4)
		{
			message_begin(MSG_ONE_UNRELIABLE, g_Msg_ScoreAttrib, _, i);
			write_byte(id);
			write_byte(msg);
			message_end();
		}
	}
}

stock move_grenade()
{
	new ent = -1;
	while((ent = find_ent_by_class(ent, "grenade")))
	{
		if(is_valid_ent(ent))
			entity_set_origin(ent, Float:{-8191.0, -8191.0, -8191.0});
	}

	return 1;
}

stock my_register_cvar(name[], string[], description[], flags = 0, Float:fvalue = 0.0)
{
	ttt_register_cvar(name, string, description);
	return register_cvar(name, string, flags, fvalue);
}

stock get_weapon_owner(ent)
	return get_pdata_cbase(ent, 41, 4);

stock strip_weapons(id)
{
	if(!is_user_alive(id))
		return;

	static const PRIMARY_WEAPONS_BIT_SUM = (1<<CSW_SCOUT)|(1<<CSW_XM1014)|(1<<CSW_MAC10)|(1<<CSW_AUG)|(1<<CSW_UMP45)|(1<<CSW_SG550)|(1<<CSW_GALIL)|(1<<CSW_FAMAS)|
		(1<<CSW_AWP)|(1<<CSW_MP5NAVY)|(1<<CSW_M249)|(1<<CSW_M3)|(1<<CSW_M4A1)|(1<<CSW_TMP)|(1<<CSW_G3SG1)|(1<<CSW_SG552)|(1<<CSW_AK47)|(1<<CSW_P90);
	static const SECONDARY_WEAPONS_BIT_SUM = (1<<CSW_P228)|(1<<CSW_ELITE)|(1<<CSW_FIVESEVEN)|(1<<CSW_USP)|(1<<CSW_GLOCK18)|(1<<CSW_DEAGLE);
	static const GRENADES_WEAPONS_BIT_SUM = (1<<CSW_HEGRENADE)|(1<<CSW_FLASHBANG)|(1<<CSW_SMOKEGRENADE)|(1<<CSW_C4);
	new weapons[32], num_weapons, index, weaponid;
	get_user_weapons(id, weapons, num_weapons);

	static wname[32];
	for (index = 0; index < num_weapons; index++)
	{
		weaponid = weapons[index];
		
		if(((1<<weaponid) & PRIMARY_WEAPONS_BIT_SUM) || ((1<<weaponid) & SECONDARY_WEAPONS_BIT_SUM) || ((1<<weaponid) & GRENADES_WEAPONS_BIT_SUM))
		{
			get_weaponname(weaponid, wname, charsmax(wname));

			ham_strip_weapon(id, wname);
			cs_set_user_bpammo(id, weaponid, 0);
		}
	}

	set_pdata_float(id, 116, 0.0); // m_fHasPrimary
	remove_user_shield(id);
}

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
	static msg;
	if(!msg)
		msg = get_user_msgid("CurWeapon");

	new weaponid = get_weaponid(weapon);
	if(user_has_weapon(id, weaponid))
		ExecuteHamB(Ham_Item_Deploy, find_ent_by_owner(-1, weapon, id));

	engclient_cmd(id, weapon);

	emessage_begin(MSG_ONE_UNRELIABLE, msg, _, id);
	ewrite_byte(1);
	ewrite_byte(weaponid);
	ewrite_byte(-1);
	emessage_end();
}

stock remove_user_shield(id)
{
	#if AMXX_VERSION_NUM >= 183
	if(get_pdata_bool(id, 2043))								//m_bHasShield
	{
		set_pdata_bool(id, 2043, false);						//m_bHasShield
		set_pdata_int(id, 116, 0);								// m_fHasPrimary
		set_pdata_bool(id, 2042, false);						// m_bUsesShield
		set_pev(id, pev_gamestate, 1);
		new iHideHUD = get_pdata_int(id, 361);					// m_iHideHUD
		if(iHideHUD & (1<<7))
			set_pdata_int(id, 361, iHideHUD & ~(1<<7));	// m_iHideHUD

		return 1;
	}

	#endif
	return -id;
}

stock is_holding_dna_scanner(id)
{
	static DNAScannerID;
	if(!DNAScannerID)
	{
		new name[TTT_ITEMLENGHT];
		formatex(name, charsmax(name), "%L", LANG_SERVER, "TTT_ITEM_ID5");
		DNAScannerID = ttt_get_item_id(name);
	}

	if(get_user_weapon(id) == CSW_C4)
	{
		new ent = find_ent_by_owner(-1, "weapon_c4", id);
		if(get_weapon_edict(ent, REPL_CSWA_SET) == 2 && get_weapon_edict(ent, REPL_CSWA_ITEMID) == DNAScannerID)
			return 1;
	}

	return 0;
}

stock FixedUnsigned16(Float:value, scale)
{
	new output;
	output = floatround(value * scale);
	if(output < 0)
		output = 0;
	if(output > 0xFFFF)
		output = 0xFFFF;

	return output;
}