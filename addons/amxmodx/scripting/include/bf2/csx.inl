//Bf2 Rank Mod CSX forwards File
//Contains all the CSX forwarded functions


#if defined bf2_csx_forward_included
  #endinput
#endif
#define bf2_csx_forward_included

public client_death ( killer, victim, wpnindex, hitplace, TK )
{
	switch (wpnindex)
	{
	case CSW_KNIFE: knifekills[killer]++
	case CSW_M249: parakills[killer]++
	case CSW_AWP, CSW_SCOUT, CSW_G3SG1, CSW_SG550 : sniperkills[killer]++
	case CSW_DEAGLE, CSW_ELITE, CSW_USP, CSW_FIVESEVEN, CSW_P228, CSW_GLOCK18: pistolkills[killer]++
	case CSW_HEGRENADE: grenadekills[killer]++
	case CSW_XM1014, CSW_M3: shotgunkills[killer]++
	case CSW_MAC10, CSW_UMP45, CSW_MP5NAVY, CSW_TMP, CSW_P90: smgkills[killer]++
	case CSW_AUG, CSW_GALIL, CSW_FAMAS, CSW_M4A1, CSW_SG552, CSW_AK47: riflekills[killer]++
	}

	#if defined CSDM
	
		check_badges(victim);

	#endif
		
	if ((killer<33) && (killer>0) && (killer!=victim))
		totalkills[killer]++

	if (mostkillsid==killer)
	{
		mostkills++
	}
	else if (totalkills[killer]>mostkills)
	{
		mostkills=totalkills[killer]
		mostkillsid=killer

		new line[100]
		new name[30];
		get_user_name(killer,name,29)
		line[0] = 0x04;
		format(line[1],99,"Congratulations to %s, The new Kill Leader with %i Kills",name,mostkills)
		format(mostkillsname,29,name)
		ShowColorMessage(killer,MSG_BROADCAST,line)
	}
	
	DisplayHUD(killer);
}

public client_damage(attacker,victim,damage,wpnindex,hitplace,TA)
{
	if ((!get_pcvar_num(g_bf2_active)) || (!get_pcvar_num(g_badges_active)) || (!get_pcvar_num(g_powers)))
		return PLUGIN_CONTINUE;	

	DisplayHUD(victim)

	new pistollevel=g_PlayerBadges[victim][1];
		
	if (pistollevel>0)
	{
		
		if (random_num(1,(9-pistollevel))==1)
		{
			imobile[attacker]=true;
			set_speed(attacker)
			screen_flash(attacker,255,0,0,100) //Red screen flash
			player_glow(attacker,255,0,0) //Make the player glow red too
			message_begin(MSG_ONE,gmsgScreenShake,{0,0,0},attacker) 
			write_short(10<<12)
			write_short(2<<12)
			write_short(5<<12)
			message_end()

			set_task(1.0,"remove_imobile",attacker);
		}


	}

	new bonushp,hp;

	if (!is_user_alive(attacker))
		return PLUGIN_CONTINUE;

			
	if ((wpnindex==CSW_KNIFE) && (!TA))
	{
		new attackerknifelevel=g_PlayerBadges[attacker][BADGE_KNIFE]
	
		if (attackerknifelevel==0)
			return PLUGIN_CONTINUE;
				
		bonushp=floatround(float(damage)*(float(attackerknifelevel)/5))

		hp = pev(attacker,pev_health);
		
		hp += bonushp;
		
		if (hp>130)
		{
			set_user_health(attacker,130)
		}
		else
		{
			set_user_health(attacker,hp)	
		}

		screen_flash(attacker,0,0,255,100) //Blue screen flash
		player_glow(attacker,0,0,255) //Blue model flash
	}

	if (!is_user_alive(victim))
		return PLUGIN_CONTINUE;


	if ((wpnindex == CSW_HEGRENADE) && g_PlayerBadges[attacker][5] && !TA) //Explosives badge, nade dmg
	{
		new extradamage=floatround(damage*g_PlayerBadges[attacker][5]*0.2)
		new health=get_user_health(victim)
		if (extradamage>=health)
		{
			kill(victim,attacker,"grenade")
		}
		else
		{
			set_user_health(victim,health-extradamage)
		}
		
	}
	else if ((wpnindex==CSW_M249) && g_PlayerBadges[attacker][4] && !TA) //Support badge, bonus damg
	{
		new extradamage=(g_PlayerBadges[attacker][4]*2)
		new health=get_user_health(victim)
		if (extradamage>=health)
		{
			kill(victim,attacker,"m249")
		}
		else
		{
			set_user_health(victim,health-extradamage)
		}		


	}

	return PLUGIN_CONTINUE;	
}

public bomb_planted(planter)
{
	plants[planter]++
}

public bomb_explode(planter,defuser)
{
	explosions[planter]++
	totalkills[planter]+=3
	client_print(planter,print_chat,"[BF2] You received 3 BF2 points for destroying the target")
}

public bomb_defused(defuser)
{
	defuses[defuser]++
	totalkills[defuser]+=3
	client_print(defuser,print_chat,"[BF2] You received 3 BF2 points for defusing the bomb")
}