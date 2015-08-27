
/*
HE Arena 0.5
Copyleft jghg
2003

Thanks to SpaceDude, OLO, aak2002_2k2, AssKicR,
for ideas and stuff.

  VERSIONS
  ========
  0.1			First version
  0.2			- Auto disables WC3 if you have it, will be
				put back on if you disable HE Arena.
				- Auto disables friendly fire. Puts back
				to previous state when HE Arena is
				disabled.
				- Welcome msg, if HE Arena is enabled.
				- Can now switch to C4.
  0.3			- Does not require xtrafun module anymore!!!
  0.4			- Voting added, thanks AssKicR.
                - Some touch ups, sometimes you weren't
				given a HE if you tried hard enough. :-)
				Should be fixed.
  0.5			- Optional gren trail added

  HE ARENA
  ========
  When HE Arena is enabled, you will get a HE
  grenade. And as soon as you throw one,
  you will get a new.

  INSTALLATION
  ============
  1) Put compiled hearena.amx in your amx/plugins directory.
  2) To amx/plugins/plugins.ini, add a line containing
     "hearena.amx", but without the quotes.
  3) Restart map/server.
  4) Admin will have to activate HE arena by typing amx_hearena
     in console. (HE Arena is off at map start by default,
	 you can put a line with "amx_hearena" (without the quotes)
	 in your server.cfg to have this enabled by default.
	 "amx_hearena" again to disable. Or you can use
	 "amx_hearena on" (or off) if you forget if it's on or
	 not. :-)
  5) Your users can initiate a vote to enable/disable HE Arena
     by command "say /votehearena" or "say votehearena"
  6) Have fun!

	  - Johnny got his gun

  EXTRA:
  7) If you want nice colourful trails after throwed grenades,
     you must:
	 A) Uncomment the line below "//#define RUN_WITH_GRENTRAIL".
	 That means you remove the two initial slashes on the line,
	 so it looks like this: "#define RUN_WITH_GRENTRAIL"
	 B) Download and install xtrafun module, if you don't
	 already have it. It can be found in the Modules forum
	 of amxmod.net forums. Currently at:
	 http://amxmod.net/forums/viewtopic.php?t=10714
	 It's in the xtrafun.zip file at bottom of top post.
	 Be sure to install it PROPERLY, or this will NOT work!
	                       ********               ***
     If you don't want the grenade trails, just comment
	 the "#define RUN_WITH_GRENTRAIL" line away again.
*/

// UNCOMMENT THE LINE BELOW IF YOU WANT GRENTRAIL!!!
//#define RUN_WITH_GRENTRAIL
// UNCOMMENT THE LINE ABOVE IF YOU WANT GRENTRAIL!!!

#include <amxmod>
#include <fun>
#include <amxmisc>
#if defined(RUN_WITH_GRENTRAIL)
	#include <xtrafun>
	#define TE_BEAMFOLLOW 22
	new const HEGRENADE_MODEL[] = "models/w_hegrenade.mdl"
	new m_iTrail
	public plugin_precache() {
		m_iTrail = precache_model("sprites/smoke.spr")
	}
#endif

new bool:heArena
new defaultwc3
new defaultff

public hethrowevent(parm[]) {
#if defined(RUN_WITH_GRENTRAIL)

	new string[32], grenadeid = 0
	do
	{
		grenadeid = get_grenade_id(parm[0], string, 31, grenadeid)
	}
	while (grenadeid &&!equali(HEGRENADE_MODEL,string))

	if (grenadeid)
	{
		new rgb[3]
		rgb[0] = random_num(0,255)
		rgb[1] = random_num(0,255)
		rgb[2] = random_num(0,255)
		if (rgb[0] + rgb[1] + rgb[2] < 255)
			rgb[random_num(0,2)] = random_num(225,255)
		else if (rgb[0] + rgb[1] + rgb[2] > 535)
			rgb[random_num(0,2)] = random_num(0,100)

		if (rgb[1] > rgb[0] - 50 && rgb[1] < rgb[0] + 50
		&&  rgb[2] > rgb[0] - 50 && rgb[2] < rgb[0] + 50
		&&  rgb[2] > rgb[1] - 50 && rgb[2] < rgb[1] + 50) {

			new i = random_num(0,2)
			new j
			if (i == 0)
				j = random_num(1,2)
			else if (i == 2)
				j = random_num(0,1)
			else {
				new k = random_num(0,1)
				if (k == 0)
					j = 0
				else
					j = 2
			}
			if (rgb[j] < 100)
				rgb[i] = 255
			else
				rgb[i] = 0
		}
			

		message_begin( MSG_BROADCAST, SVC_TEMPENTITY )
		write_byte( TE_BEAMFOLLOW )
		write_short(grenadeid)	// entity
		write_short(m_iTrail)	// model
		write_byte( 10 ) // life
		write_byte( 5 ) // width
		write_byte( rgb[0] )	// r
		write_byte( rgb[1] ) // g
		write_byte( rgb[2] )	// b
		switch (random_num(0,2))
		{
		case 0:
			write_byte( 64 )	// brightness
		case 1:
			write_byte( 128 )	// brightness
		case 2:
			write_byte( 192 )	// brightness
		}
		message_end();  // move PHS/PVS data sending into here (SEND_ALL, SEND_PVS, SEND_PHS)

		//client_print(parm[0],print_chat,"r:%d g:%d b:%d",rgb[0],rgb[1],rgb[2])
	}
#endif

	if (heArena)
		give_item(parm[0],"weapon_hegrenade")
}

public TextMsg() {
	//if (!heArena)
		//return PLUGIN_HANDLED
	new name[32]
	read_data(3,name,31)
	new parm[1]
	parm[0] = get_user_index(name)
	set_task(0.01,"hethrowevent",0,parm,1)
	//set_task(0.1,"grenid",0,parm,1) 

	return PLUGIN_CONTINUE
}

public hearenatoggle(id,level,cid) {
	if (!cmd_access(id,level,cid,1)) {
		return PLUGIN_HANDLED
	}

	if (read_argc() == 2) {
		new argument[10]
		read_argv(1,argument,9)
		if (equal(argument,"on")) {
			if (heArena)
				return PLUGIN_HANDLED
			else
				heArena = true
		}
		else if (equal(argument,"off")) {
			if (!heArena)
				return PLUGIN_HANDLED
			else
				heArena = false
		}
	}
	else {
		heArena = !heArena
	}

	if (heArena) {
		set_hudmessage(0, 100, 0, -1.0, 0.65, 2, 0.02, 10.0, 0.01, 0.1, 2)   
		show_hudmessage(0,"HE Arena is enabled!")
		client_print(id,print_console,"[AMX] HE Arena was enabled!") 
		server_print("[AMX] HE Arena was enabled!")

		// Collect all alive players and give'm a nade if they
		// already not have one.
		new playersList[32]
		new playersFound
		get_players(playersList,playersFound,"a")
		for (new i = 0;i < playersFound;i++) {
			giveheifnothas(playersList[i])
			engclient_cmd(playersList[i],"weapon_hegrenade")
		}

		// If WC3 is installed, store default WC3 setting
		// and set WC3 off (crit nade skill is a little unfair)
		if (cvar_exists("sv_warcraft3")) {
			defaultwc3 = get_cvar_num("sv_warcraft3")
			set_cvar_num("sv_warcraft3",0)
		}

		// Store default ff setting, and set it off.
		// FF will just get your players kicked for tk:ing too much
		// Believe me it's hard to stay away from it if you're not used
		// to HE Arena.
		defaultff = get_cvar_num("mp_friendlyfire")
		set_cvar_num("mp_friendlyfire",0)
	}
	else {
		set_hudmessage(0, 100, 0, -1.0, 0.65, 2, 0.02, 10.0, 0.01, 0.1, 2)   
		show_hudmessage(0,"HE Arena is disabled!")
		//client_print(0,print_center,"HE Arena is disabled!")
		client_print(id,print_console,"[AMX] HE Arena was disabled!") 
		server_print("[AMX] HE Arena was disabled!")

		// Reset WC3 and FF values to previous.
		set_cvar_num("sv_warcraft3",defaultwc3)
		set_cvar_num("mp_friendlyfire",defaultff)
	}


	return PLUGIN_HANDLED
}

public client_putinserver(id) {
	if (heArena) {
		new param[1]
		param[0] = id
		set_task(10.0,"welcome",0,param,1)
	}

	return PLUGIN_CONTINUE
}

public welcome(param[]) {
	if (heArena) {
		set_hudmessage(0, 130, 0, -1.0, 0.45, 2, 0.02, 15.0, 0.01, 0.1, 2)   
		show_hudmessage(param[0],"Welcome! HE Arena is enabled! Please cover your ears!")
	}

	return PLUGIN_CONTINUE
}

public holdwpn(id) {
	if (!heArena)
		return PLUGIN_HANDLED

	new weapontypeid = read_data(2)
	// Only valid weapons to hold are HE and C4.
	if (weapontypeid == CSW_HEGRENADE || weapontypeid == CSW_C4) {
	}
	else {
		giveheifnothas(id)
		engclient_cmd(id,"weapon_hegrenade")
	}

	return PLUGIN_CONTINUE
}

public newround(id) {
	if (heArena) {
		giveheifnothas(id)
		engclient_cmd(id,"weapon_hegrenade")
	}
}

public giveheifnothas(id) {
	new wpnList[32]
	new number
	new foundNade = false
	get_user_weapons(id,wpnList,number)
	for (new i = 0;i < number && !foundNade;i++) {
		if (wpnList[i] == CSW_HEGRENADE)
			foundNade = true
	}

	if (!foundNade)
		give_item(id,"weapon_hegrenade")
	//else
		//client_print(id,print_chat,"You already have a HE, will not give a new.")

	return PLUGIN_CONTINUE
}

// Voting part below
new moption[2] 
new votehearena[] = "\yAMX %s HE Arena?\w^n^n1. Yes^n2. No" 

public vote_he(id){
	new Float:voting = get_cvar_float("amx_last_voting") 
	if (voting > get_gametime()) { 
		client_print(id,print_chat,"* There is already one voting...") 
		return PLUGIN_HANDLED 
	}

	if (voting && voting + get_cvar_float("amx_vote_delay") > get_gametime()) { 
		client_print(id,print_chat,"* Voting not allowed at this time...") 
		return PLUGIN_HANDLED 
	}

	new menu_msg[256] 
	format(menu_msg,255,votehearena,heArena ? "Disable" : "Enable") 
	new Float:vote_time = get_cvar_float("amx_vote_time") + 2.0 
	set_cvar_float("amx_last_voting",  get_gametime() + vote_time ) 
	show_menu(0,(1<<0)|(1<<1),menu_msg,floatround(vote_time)) 
	set_task(vote_time,"check_mvotes") 
	client_print(0,print_chat,"* Voting has started...") 
	moption[0]=moption[1]=0 
	return PLUGIN_CONTINUE      
} 

public mvote_count(id,key){ 
    if ( get_cvar_float("amx_vote_answers") ) { 
        new name[32] 
        get_user_name(id,name,31) 
        client_print(0,print_chat,"* %s voted %s", name, key ? "against" : "for" ) 
    } 
    ++moption[key] 
    return PLUGIN_HANDLED 
} 

public check_mvotes(id){ 
    if (moption[0] > moption[1]){ 
        //server_cmd(  "amx_hevotesb %s", heArena ? "off" : "on")
		if (heArena)
			server_cmd("amx_hearena off")
		else if (!heArena)
			server_cmd("amx_hearena on")
		client_print(0,print_chat,"* Voting results: (yes ^"%d^") (no ^"%d^").",moption[0],moption[1])
    } 
    else{
		if (heArena)
			server_cmd("amx_hearena on")
		else if (!heArena)
			server_cmd("amx_hearena off")
		client_print(0,print_chat,"* Voting results: (yes ^"%d^") (no ^"%d^").",moption[0],moption[1])
    } 
    return PLUGIN_CONTINUE 
}
// Voting part above

public plugin_init() {
	register_plugin("HE Arena","0.5","jghg")
	register_event("TextMsg","TextMsg","bc","2&#Game_radio", "4&#Fire_in_the_hole")
	register_event("ResetHUD","newround", "b")
	//register_event("23", "he_explosion","a","1=3","")
	//register_event("Damage", "damageevent", "b", "2!0")
	register_concmd("amx_hearena","hearenatoggle",ADMIN_LEVEL_H,": toggles HE Arena on/off")
	register_event("CurWeapon","holdwpn","be","1=1")

	heArena = false

	// Voting part below
	register_clcmd("","vote_he") 
	register_clcmd("","vote_he") 
	register_menucmd(register_menuid("HE Arena?"),(1<<0)|(1<<1),"mvote_count") 
	// Voting part above
	
	return PLUGIN_CONTINUE
}

/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1046\\ f0\\ fs16 \n\\ par }
*/
