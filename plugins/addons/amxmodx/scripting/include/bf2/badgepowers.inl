//Bf2 Rank Mod badge powers File
//Contains all the power giving etc checking functions.


#if defined bf2_powers_included
  #endinput
#endif
#define bf2_powers_included

public set_speed(id)
{
	if (!is_user_alive(id) || freezetime)
		return;
	
	if (!get_pcvar_num(g_badges_active) || (!get_pcvar_num(g_powers)))
		return;	

	if (imobile[id])
	{
		set_pev(id, pev_maxspeed, 100.0)
		return;
	}

	new dummy;
	new weapon = get_user_weapon( id,dummy,dummy);
	new zoom=cs_get_user_zoom(id);


	//only get here if not imobilised. Reset to normal speed.
	if (cs_get_user_vip(id))
	{
		set_pev(id, pev_maxspeed, CS_SPEED_VIP);
	}
	else if ((zoom==2) || (zoom==3) || (zoom==4))
	{
		set_pev(id, pev_maxspeed, CS_WEAPON_SPEED_ZOOM[weapon]);
	}
	else
	{
		set_pev(id, pev_maxspeed, CS_WEAPON_SPEED[weapon]);
	}
	
	new smglevel=g_PlayerBadges[id][7];
	
	if (smglevel) //15 units faster per level.
	{
		new Float:maxspeed
		pev(id,pev_maxspeed,maxspeed)
		maxspeed+=(float(smglevel)*15.0)
		set_pev(id,pev_maxspeed,maxspeed)
	}
}

public set_invis(id)
{
	if (!is_user_alive(id))
		return PLUGIN_CONTINUE;

	new weapon,dummy

	weapon=get_user_weapon(id,dummy,dummy)

	new shotgunlevel=g_PlayerBadges[id][6]
	
	if (shotgunlevel && (weapon == CSW_KNIFE))
	{
		fm_set_rendering( id, kRenderFxNone, 0, 0, 0, kRenderTransTexture,p_invisibility[shotgunlevel-1]);
		g_invis[id]=1

	}
	else
	{
		fm_set_rendering(id);
		g_invis[id]=0

	}

	return PLUGIN_CONTINUE;
}

public remove_imobile(id)
{
	imobile[id]=false;
	
	set_speed(id);
}

public give_weapons()
{
	new players[32],num;

	get_players(players,num,"h")
	
	for (new counter=0; counter<num; counter++)
	{
		give_userweapon(players[counter])
	}


}

public give_userweapon(id)
{
	if (!get_pcvar_num(g_powers) || !is_user_alive(id))
		return PLUGIN_CONTINUE;	

	new bool:givenitem=false;
	new hp;	

	new assaultbadge=g_PlayerBadges[id][2];
	if (assaultbadge>0)
	{
		hp = 100 + (assaultbadge*10);

		set_user_health (id,hp)

		givenitem=true;
	}
 	
	new sniperlevel=g_PlayerBadges[id][3];
	
	if (sniperlevel!=0)
	{
		if (random_num(1,(4-sniperlevel))==1)
		{
			if (!get_pcvar_num(g_free_awp))	
			{
				new weaponName[32], weaponID, temp
				weaponID = get_user_weapon(id, temp, temp)
				fm_give_item(id,"weapon_scout");
				if (weaponID)
				{
					get_weaponname(weaponID, weaponName, 31)
					engclient_cmd(id, weaponName)
				}
				givenitem=true;
			}
			else
			{
				new weaponName[32], weaponID, temp
				weaponID = get_user_weapon(id, temp, temp)
				fm_give_item(id,"weapon_awp");
				if (weaponID)
				{
					get_weaponname(weaponID, weaponName, 31)
					engclient_cmd(id, weaponName)
				}
				givenitem=true;	
			}
		}
	}
	
	new CsArmorType:ArmorType

	switch (numofbadges[id])
	{
		case 6 .. 11: {
			if (cs_get_user_armor(id, ArmorType)<50)
			{
				cs_set_user_armor ( id, 50,CS_ARMOR_VESTHELM)
				givenitem=true;
			}
		}

		case 12 .. 17: {
			if (cs_get_user_armor(id, ArmorType)<100)
			{
				cs_set_user_armor ( id, 100,CS_ARMOR_VESTHELM)
				givenitem=true;
			}
		}

		case 18 .. 24: {
			cs_set_user_armor ( id, 200,CS_ARMOR_VESTHELM)
			givenitem=true;
		}
	}
		
	if (givenitem)
		screen_flash(id,0,255,0,100) //Green screen flash

	return PLUGIN_CONTINUE;


}

public kill(id,attacker,weapon[])
{
	set_user_frags(id,get_user_frags(id)+1)
	set_user_frags(attacker,get_user_frags(attacker)+1)


	set_msg_block(gmsgDeathMsg,BLOCK_ONCE)
	set_user_health(id,-1)
	set_msg_block(gmsgDeathMsg,BLOCK_NOT) //having problems with more than one message being blocked :S

	//Display death
	message_begin( MSG_ALL, gmsgDeathMsg,{0,0,0},0)
	write_byte(attacker)
	write_byte(id)
	write_byte(0)
	write_string(weapon)
	message_end()

	//Change scoreboard for victim
	message_begin(MSG_ALL, gmsgScoreInfo)
	write_byte(id)				//Player
	write_short(get_user_frags(id))	//Frags
	write_short(cs_get_user_deaths(id))	//Deaths
	write_short(0)				//"Class"
	write_short(get_user_team(id))	//Team
	message_end()

	//Change scoreboard for attacker
	message_begin(MSG_ALL, gmsgScoreInfo)
	write_byte(attacker)				//Player
	write_short(get_user_frags(attacker))	//Frags
	write_short(cs_get_user_deaths(attacker))	//Deaths
	write_short(0)					//"Class"
	write_short(get_user_team(attacker))	//Team
	message_end()

}