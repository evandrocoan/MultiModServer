///////////////////////////////////////////////////
//  AMXMOD[X]                                    //
//   ::Ultimate sounds::                         //
//    by Hephaistos (hephaistos@djeyl.net)       //
//    edited by Dizzy (dizzythermal@gmail.com)   //
//    edited by Toster v2.1 (Tosterv2.1@inbox.lv)//
//                                               //                                           
// cvar:                                         //
//  streak_mode < flags >                        //
//  "a" - messages                               //
//  "b" - sounds                                 //
//                                               //
//  kniff_mode < flags >                         //
//  "a" - messages                               //
//  "b" - sounds                                 //
//                                               //
//  hs_mode < flags >                            //
//  "a" - messages                               //
//  "b" - sounds                                 //
//                                               //
//  lastman_mode < flags >                       //
//  "a" - messages                               //
//  "b" - hp                                     //
//  "c" - sounds                                 //
///////////////////////////////////////////////////

#include <amxmodx>

#define KNIFFMESSAGES 4
#define LEVELS 7
#define MESSAGESNOHP 4
#define MESSAGESHP 4

new kills[33] = {0,...};
new deaths[33] = {0,...};
new alone_ann = 0
new levels[7] = {3, 5, 7, 9, 10, 13, 15};

new stksounds[7][] = {
"misc/female/multikill",
"misc/female/dominating",
"misc/female/monsterkill",
"misc/female/killingspree",
"misc/female/rampage",
"misc/female/holyshit",
"misc/female/godlike"};

new stkmessages[7][] = {
"%s: Multi-Kill!",
"%s: Dominating!",
"%s: Monster-Kill!",
"%s: Killing Spree!",
"%s: Rampage!",
"%s: Holy Shit!",
"%s: Godlike!"};


new kniffmessages[KNIFFMESSAGES][] = {
"%s Sliced And Diced %s!",
"%s Shanked %s!",
"%s Pulled A Knife On %s!",
"%s Knived %s!"}

new messagesnohp[MESSAGESNOHP][] = {
"%i terrorist vs %i CT^n%s: Now All Depends On You!",
"%i terrorist vs %i CT^n%s: I Hope You Still Have A Healthpack.",
"%i terrorist vs %i CT^n%s: All Your Teammates Were Killed. Good Luck!",
"%i terrorist vs %i CT^n%s: Now You Are Alone. Have Fun!"}

new messageshp[MESSAGESHP][] = {
"%i terrorist vs %i CT^n%s (%i hp): Now All Depend On You!",
"%i terrorist vs %i CT^n%s (%i hp): I Hope You Still Have A Healthpack.",
"%i terrorist vs %i CT^n%s (%i hp): All Your Teammates Were Killed. Good Luck!",
"%i terrorist vs %i CT^n%s (%i hp): Now You Are alone. Have Fun!"}

get_streak()
{
	new streak[3]
	get_cvar_string("streak_mode",streak,2)
	return read_flags(streak)
}

public death_event(id)
{
	new streak = get_streak()

	if ((streak&1) || (streak&2))
	{
    		new killer = read_data(1);
    		new victim = read_data(2);

    		kills[killer] += 1;
    		kills[victim] = 0;
    		deaths[killer] = 0;
    		deaths[victim] += 1;

    		for (new i = 0; i < LEVELS; i++)
		{
        		if (kills[killer] == levels[i])
			{
         	  		 announce(killer, i);
         	  		 return PLUGIN_CONTINUE;
			}
		}
	}
	return PLUGIN_CONTINUE;
}

announce(killer, level)
{
	new streak = get_streak()

	if (streak&1)
	{
    		new name[32];

   		get_user_name(killer, name, 32);
		set_hudmessage(0, 100, 200, 0.05, 0.65, 2, 0.02, 6.0, 0.01, 0.1, 2);
		show_hudmessage(0, stkmessages[level], name);
	}

	if (streak&2){
    		client_cmd(0, "spk %s", stksounds[level]);
	}
}

public reset_hud(id)
{
	set_hudmessage(200, 0, 0, -1.0, 0.30, 0, 3.0, 3.0, 0.15, 0.15, 1)
	show_hudmessage(0, "Prepare To Fight!")
	client_cmd(0,"spk misc/female/prepare")

	new streak = get_streak()

	if (streak&1)
	{

		if (kills[id] > levels[0])
		{
		        client_print(id, print_chat, 
			"* You are on a killstreak with %d kills.", kills[id]);

		}

		else if (deaths[id] > 1)
		{
			client_print(id, print_chat, 
			"* Take care, you are on a deathstreak with %d deaths in a row.", deaths[id]);
		}
	}
}

public client_connect(id)
{
	new streak = get_streak()

	if ((streak&1) || (streak&2))
	{
		kills[id] = 0;
		deaths[id] = 0;
	}
}

public knife_kill()
{
	new kniffmode[4] 
	get_cvar_string("kniff_mode",kniffmode,4) 
	new kniffmode_bit = read_flags(kniffmode)

	if (kniffmode_bit & 1)
	{
		new killer_id = read_data(1)
		new victim_id = read_data(2)
		new killer_name[33], victim_name[33]

		get_user_name(killer_id,killer_name,33)
		get_user_name(victim_id,victim_name,33)


		set_hudmessage(200, 100, 0, -1.0, 0.30, 0, 6.0, 6.0, 0.5, 0.15, 1)
		show_hudmessage(0,kniffmessages[ random_num(0,KNIFFMESSAGES-1) ],killer_name,victim_name)
	}

	if (kniffmode_bit & 2)
	{
		client_cmd(0,"spk misc/female/humiliation")
   	}
}


public roundend_msg(id)

	alone_ann = 0

public death_msg(id)
{

	new lmmode[8] 
	get_cvar_string("lastman_mode",lmmode,8) 
	new lmmode_bit = read_flags(lmmode)

	new players_ct[32], players_t[32], ict, ite, last
	get_players(players_ct,ict,"ae","CT")   
	get_players(players_t,ite,"ae","TERRORIST")   

	if (ict==1&&ite==1)
	{
		new name1[32], name2[32]
		get_user_name(players_ct[0],name1,32)
		get_user_name(players_t[0],name2,32)
		set_hudmessage(200, 100, 0, -1.0, 0.30, 0, 6.0, 6.0, 0.5, 0.15, 1)

		if (lmmode_bit & 1)
		{
			if (lmmode_bit & 2)
			{
				show_hudmessage(0,"%s (%i hp) vs. %s (%i hp)",name1,get_user_health(players_ct[0]),name2,get_user_health(players_t[0]))
			}

			else
			{
				show_hudmessage(0,"%s vs. %s",name1,name2)
			}

			if (lmmode_bit & 4)
			{
				client_cmd(0,"spk misc/maytheforce")
			}
		}
	} 
	else
{   
	if (ict==1&&ite>1&&alone_ann==0&&(lmmode_bit & 4))
	{
		last=players_ct[0]
		client_cmd(last,"spk misc/oneandonly")
	}

	else if (ite==1&&ict>1&&alone_ann==0&&(lmmode_bit & 4))
	{
		last=players_t[0]
		client_cmd(last,"spk misc/oneandonly")
	}

	else
	{
		return PLUGIN_CONTINUE
	}
	alone_ann = last
	new name[32]   
	get_user_name(last,name,32)

	if (lmmode_bit & 1)
	{
		set_hudmessage(200, 100, 0, -1.0, 0.30, 0, 6.0, 6.0, 0.5, 0.15, 1)

		if (lmmode_bit & 2)
		{
			show_hudmessage(0,messageshp[ random_num(0,MESSAGESHP-1) ],ite ,ict ,name,get_user_health(last))
		}

		else
		{
			show_hudmessage(0,messagesnohp[ random_num(0,MESSAGESNOHP-1) ],ite ,ict ,name )
		}
	}

	if (lmmode_bit & 4)
	{
		client_cmd(last,"spk misc/maytheforce")
	}
}
	return PLUGIN_CONTINUE   
}


public hs()
{
	new hsmode[4] 
	get_cvar_string("hs_mode",hsmode,4) 
	new hsmode_bit = read_flags(hsmode)

	if (hsmode_bit & 1)
	{
	new killer_id = read_data(1)
	new victim_id = read_data(2)
	new victim_name[33]

	get_user_name(victim_id,victim_name,33)

	set_hudmessage(200, 100, 0, -1.0, 0.30, 0, 3.0, 3.0, 0.15, 0.15, 1)
	show_hudmessage(killer_id,"::HEADSHOT::^nYou Owned %s !!",victim_name)
	}

	if (hsmode_bit & 2)
	{
		client_cmd(0,"spk misc/female/headshot")
	}
}

public plugin_precache()
{
	precache_sound("misc/female/monsterkill.wav")
	precache_sound("misc/female/godlike.wav")
	precache_sound("misc/female/headshot.wav")
	precache_sound("misc/female/humiliation.wav")
	precache_sound("misc/female/killingspree.wav")
	precache_sound("misc/female/multikill.wav")
	precache_sound("misc/female/dominating.wav")
	precache_sound("misc/maytheforce.wav")
	precache_sound("misc/oneandonly.wav")
	precache_sound("misc/female/prepare.wav")
	precache_sound("misc/female/rampage.wav")
	precache_sound("misc/female/holyshit.wav")

	return PLUGIN_CONTINUE 
}



public plugin_init()
{
	register_plugin("Ultimate Sound Female","1.1","Toster v2.1")
	register_event("DeathMsg","hs","a","3=1")
	register_event("DeathMsg","knife_kill","a","4&kni")
	register_event("ResetHUD", "reset_hud", "b");
	register_event("DeathMsg", "death_event", "a")
	register_event("SendAudio","roundend_msg","a","2=%!MRAD_terwin","2=%!MRAD_ctwin","2=%!MRAD_rounddraw")
	register_event("TextMsg","roundend_msg","a","2&#Game_C","2&#Game_w")
	register_event("DeathMsg","death_msg","a")
	register_cvar("lastman_mode","abc")
	register_cvar("streak_mode","ab")
	register_cvar("kniff_mode","ab")
	register_cvar("hs_mode","ab")

	return PLUGIN_CONTINUE
}
