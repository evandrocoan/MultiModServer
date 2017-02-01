//Bf2 Rank Mod events File
//Contains all the client command functions


#if defined bf2_events_included
  #endinput
#endif
#define bf2_events_included

//Normal register event functions..

public event_hud_reset(id) 
{
	if (!get_pcvar_num(g_bf2_active))
		return;

	set_task(0.2, "new_spawn_task", id)
}

public new_spawn_task(id)
{
	if (!get_pcvar_num(g_bf2_active) || !is_user_alive(id))
		return;

	check_level(id);
	ShowHUD(id);

	if ((!get_pcvar_num(g_badges_active)) || (!get_pcvar_num(g_powers)))
		return;

	set_invis(id)
}

public event_new_round() 
{
	if ((!get_pcvar_num(g_bf2_active)) || (!get_pcvar_num(g_badges_active)) || (!get_pcvar_num(g_powers)))
		return;	

	freezetime=true;
	
	#if defined CSDM
		return;
	#else

	set_task(2.0,"give_weapons")

	#endif
	
}

public event_intermission(msg_id,msg_dest,msg_entity)
{
	set_task(0.1,"award_check")
}

public event_curweapon(id)
{
	if(!is_user_alive(id) || (!get_pcvar_num(g_bf2_active)))
		return PLUGIN_HANDLED;

	if (!get_pcvar_num(g_powers))
		return PLUGIN_HANDLED;

	new weapon_id = read_data(2); 
	
	g_invis[id]=0    

	if ( g_lastwpn[id] != weapon_id)
	{
		set_speed(id);
		set_invis(id);
	}
	
	g_lastwpn[id] = weapon_id;

	return PLUGIN_HANDLED;
    
}
public hook_StatusValue()
{
	//Block the name info, of person you aim at
	set_msg_block(gmsgStatusText, BLOCK_SET);
}

public setTeam(id)
{
	g_friend[id] = read_data(2)
}

public flags_check()
{
	new temp[8]
	get_pcvar_string(g_hud_options,temp,7)
	
	return read_flags(temp)
}

public on_ShowStatus(id) //called when id looks at someone
{
	new name[32], pid = read_data(2);
	new pidrank = g_PlayerRank[pid];

	get_user_name(pid, name, 31);
	new color1 = 0, color2 = 0;

	if (get_user_team(pid) == 1)
		color1 = 255;
	else
		color2 = 255;

	new Float:height
	new flags=flags_check()
	
	if (flags & ABOVEHEAD)
		height=0.35
	else
		height=0.60

	if (g_friend[id] == 1)	// friend
	{
		new clip, ammo, wpnid = get_user_weapon(pid, clip, ammo);
		new wpnname[32];

		if (wpnid)
			xmod_get_wpnname(wpnid, wpnname, 31);

		set_hudmessage(color1, 50, color2, -1.0, height, 1, 0.01, 3.0, 0.01, 0.01);
		
		if (flags & TEAMRANK)
		{
			if (flags & STATS)
				ShowSyncHudMsg(id, g_status_sync, "%s : %s^n%d HP / %d AP / %s", name, RANKS[pidrank], get_user_health(pid), get_user_armor(pid), wpnname);
			else
				ShowSyncHudMsg(id, g_status_sync, "%s : %s", name, RANKS[pidrank]);
		}
		else
		{
			if (flags & STATS)
				ShowSyncHudMsg(id, g_status_sync, "%s^n%d HP / %d AP / %s", name, get_user_health(pid), get_user_armor(pid), wpnname);
			else
				ShowSyncHudMsg(id, g_status_sync, "%s", name);
		}

		new time = get_pcvar_num(g_icon_hold)*10;
		if (time > 0)
			Create_TE_PLAYERATTACHMENT(id, pid, 55, sprite[pidrank], time);

	} 
	else 
	{
		set_hudmessage(color1, 50, color2, -1.0, height, 1, 0.01, 3.0, 0.01, 0.01);
		
		if (!((flags & HIDEINVIS) && (g_invis[pid])))
		{
			if (flags & ENEMYRANK)
				ShowSyncHudMsg(id, g_status_sync, "%s : %s", name, RANKS[pidrank]);
			else
				ShowSyncHudMsg(id, g_status_sync, "%s", name);
		}

			
			
	}

	DisplayHUD(id);
}

public on_HideStatus(id)
{
	ClearSyncHud(id, g_status_sync);

	DisplayHUD(id);
}

//Register logevent functions

public Event_Round_End()
{
	set_task(0.2,"badge_check_loop");

}

public end_freezetime()
{
	freezetime=false;
}