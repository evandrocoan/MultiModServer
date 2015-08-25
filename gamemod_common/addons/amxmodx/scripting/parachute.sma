/***************************************************************************************************
                        		AMX Parachute
          
  Version: 0.2.2
  Author: KRoTaL

  0.1    Release
  0.1.1  Players can't buy a parachute if they already own one
  0.1.2	 Release for AMX MOD X
  0.1.3  Minor changes
  0.1.4  Players lose their parachute if they die
  0.1.5  Added amx_parachute cvar
  0.1.6  Changed set_origin to movetype_follow (you won't see your own parachute)
  0.1.7	 Added amx_parachute <name> | admins with admin level a get a free parachute
  0.1.8	 Fixed the give parachute command
	 added a admin_parachute cvar to give admins with level A a free parachute
  0.1.9	 Added a sell command & added a cvar to get money back
  0.2.0	 Added para_free cvar to give everyone a free parachute
  0.2.1	 Fixed some minor bugs
  0.2.2  Fixed the parachute remove bug
  0.2.3  Fixed the alive bug


  Commands:

	say buy_parachute	- buys a parachute
	
	amx_parachute <name>|@all	- gives a player a free parachute

	Press +use to slow down your fall.

  Cvars:

	sv_parachute "1"	 -	0: disables the plugin
					1: enables the plugin

	parachute_cost "1000"	 -	cost of the parachute
	
	admin_parachute "0"	 -	0: admins with level A won't get a free parachute
					1: admins with level A get a free parachute
					
	parachute_payback "75"	 -	the amount you get back of the parachute in %(75/100*1000) = 750
	
	para_free "0"		 -	0: no free parachute
					1: free parachute for everyone
	

  Setup (AMXX 1.71):

    Install the amxx file. 
    Enable engine and cstrike(amxx's modules.ini) 
    Put the parachute.mdl file in the cstrike/models folder


***************************************************************************************************/

#include <amxmodx>
#include <amxmisc>
#include <engine>
#include <cstrike>

#define PLUGINNAME	"AMXX Parachute"
#define VERSION		"0.2.3"
#define AUTHOR		"KRoT@L"

new bool:has_parachute[33];
new para_ent[33];
new bool:had_parachute[33];
new bool:player_died[33];

public plugin_init()
{
	register_plugin( PLUGINNAME, VERSION, AUTHOR )
	
	register_dictionary( "parachute.txt" )
	
	register_concmd( "say buy_parachute", "buy_parachute" )
	register_concmd( "say sell_parachute", "sell_parachute" )
	register_concmd( "amx_parachute", "give_parachute", ADMIN_LEVEL_A, "amx_parachute <name, @all>" )

	register_cvar( "sv_parachute", "1" )
	register_cvar( "parachute_cost", "1000" )
	register_cvar( "parachute_payback", "75" )
	register_cvar( "admin_parachute", "0" )
	register_cvar( "para_free", "0" )
	
	register_logevent( "event_roundstart", 2, "0=World triggered", "1=Round_Start" )
	register_logevent( "event_roundend", 2, "0=World triggered", "1=Round_End" )
	register_event( "ResetHUD", "event_resethud", "be" )
	register_event( "DeathMsg", "death_event", "a" )
}

public plugin_modules() {
	require_module( "engine" )
	require_module( "cstrike" )
}

public plugin_precache()
{
	precache_model("models/parachute.mdl")
}

public client_connect(id)
{
	if(para_ent[id] > 0)
	{
		remove_entity(para_ent[id])
	}
	has_parachute[id] = false
	para_ent[id] = 0
}

public event_roundstart() {
	new MaxPlayers = get_maxplayers();
	for( new id; id < MaxPlayers; id++ ) {
		if( had_parachute[id] == true && player_died[id] == false ) {
			has_parachute[id] = true
		}
	}
	set_task( 3.0, "free_parachute" );
		
}

public event_roundend() {
	new MaxPlayers = get_maxplayers();
	for( new id; id < MaxPlayers; id++ ) {
		if( is_user_alive( id ) ) {
			if( has_parachute[id] == true ) {
				had_parachute[id] = true;
			}else{
				had_parachute[id] = false;
			}
			player_died[id] = false;

		}else {
			if(para_ent[id] > 0) {
				remove_entity(para_ent[id])
			}
			has_parachute[id] = false
			para_ent[id] = 0
			player_died[id] = true;
		}
	}
		
}

public event_resethud( id ) {
	if(para_ent[id] > 0)
	{
		remove_entity(para_ent[id])
	}
	has_parachute[id] = false
	para_ent[id] = 0
}

public death_event()
{
	new id = read_data(2)

	if(para_ent[id] > 0)
	{
		remove_entity(para_ent[id])
	}
	has_parachute[id] = false
	para_ent[id] = 0
	player_died[id] = true
}

public buy_parachute(id) {
	
	if(get_cvar_num( "sv_parachute" ) == 0)
	{
		client_print(id, print_chat, "%L", id, "para_disabled")
		return PLUGIN_HANDLED
	}

	if(has_parachute[id])
	{
		client_print(id, print_chat, "%L", id, "para_has" )
		return PLUGIN_HANDLED		
	}

	new money = cs_get_user_money(id)
	new cost = get_cvar_num( "parachute_cost" )

	if(money < cost)
	{
		client_print(id, print_chat, "%L", id, "para_money", cost)
		return PLUGIN_CONTINUE
	}

	cs_set_user_money(id, money - cost)
	client_print(id, print_chat, "%L", id, "para_buy" )
	has_parachute[id] = true

	return PLUGIN_CONTINUE
}

public sell_parachute(id) {
	if (get_cvar_num("sv_parachute") == 0) {
		client_print(id, print_chat, "%L", id, "para_disabled")
		return PLUGIN_CONTINUE
	}
	if (has_parachute[id]) {
		if(para_ent[id] > 0)
		{
			if(is_valid_ent(para_ent[id])) {
				remove_entity(para_ent[id])
			}
		}
		has_parachute[id] = false
		para_ent[id] = 0

		new money = cs_get_user_money(id)
		new cost = get_cvar_num("parachute_cost")
		new payback = floatround(float(cost) * (get_cvar_float("parachute_payback") / 100))
		cs_set_user_money(id, money + payback)
		client_print(id, print_chat, "%L", id, "para_sell", payback)
	}
	return PLUGIN_CONTINUE
}
public free_parachute() {
	new maxPlayers = get_maxplayers();
	if(get_cvar_num( "sv_parachute" ) == 0) return PLUGIN_CONTINUE

        for( new i = 1; i <= maxPlayers; i++ )
        {
		if( !is_user_connected( i ) ) return PLUGIN_CONTINUE
		
		if ( get_cvar_num( "para_free") == 1 ) {
			client_print( i, print_chat, "%L", LANG_PLAYER, "para_admin_free" )
			has_parachute[i] = true
			
			return PLUGIN_CONTINUE
		}
		if ( get_cvar_num("admin_parachute") == 1 && get_user_flags( i ) && ADMIN_LEVEL_A ) {
			client_print( i, print_chat, "%L", LANG_PLAYER, "para_admin_free" )
			has_parachute[i] = true
			
			return PLUGIN_CONTINUE
		}
	}
	return PLUGIN_CONTINUE
}

public give_parachute(id, level, cid) {
	
	if (!cmd_access(id, level, cid, 2 ) ) {
		return PLUGIN_CONTINUE
	}
	
	if (get_cvar_num("sv_parachute") == 0 ) {
		client_print(id, print_chat, "%L", id, "para_disabled")
		
		return PLUGIN_CONTINUE
	}else{
		new arg[32]
		read_argv( 1, arg, 31 )
		if (arg[0] == '@' && arg[1] == 'a') {
			new maxPlayers = get_maxplayers();
			for( new i = 1; i <= maxPlayers; i++ )
			{
				client_print( i, print_chat, "%L", LANG_PLAYER, "para_free_all" )
				has_parachute[i] = true
			}
			
			return PLUGIN_CONTINUE
		}
		new player = cmd_target( id, arg, 4 )
		
		if (has_parachute[id]) {
			client_print(id, print_chat, "%L", id, "para_has" )
			
			return PLUGIN_CONTINUE
		}
		if( !player ) {
			client_print( id, print_chat, "%L", id, "para_no_player" )
	
			return PLUGIN_CONTINUE
		}else{
			client_print(player, print_chat, "%L", player, "para_give" )
			has_parachute[player] = true
			
			return PLUGIN_CONTINUE
		}
		
	}
	return PLUGIN_CONTINUE
}

public client_PreThink(id)
{
	if( get_cvar_num( "sv_parachute" ) == 0 )
	{
		return PLUGIN_CONTINUE
	}

	if( !is_user_alive(id) )
	{
		return PLUGIN_CONTINUE
	}

	if( has_parachute[id] )
	{
		if (get_user_button(id) & IN_USE )
		{
			if ( !( get_entity_flags(id) & FL_ONGROUND ) )
			{
				new Float:velocity[3]
				entity_get_vector(id, EV_VEC_velocity, velocity)
				if(velocity[2] < 0)
				{
					if (para_ent[id] == 0)
					{
						para_ent[id] = create_entity("info_target")
						if (para_ent[id] > 0)
						{
							entity_set_model(para_ent[id], "models/parachute.mdl")
							entity_set_int(para_ent[id], EV_INT_movetype, MOVETYPE_FOLLOW)
							entity_set_edict(para_ent[id], EV_ENT_aiment, id)
						}
					}
					if (para_ent[id] > 0)
					{
						velocity[2] = (velocity[2] + 40.0 < -100) ? velocity[2] + 40.0 : -100.0
						entity_set_vector(id, EV_VEC_velocity, velocity)
						if (entity_get_float(para_ent[id], EV_FL_frame) < 0.0 || entity_get_float(para_ent[id], EV_FL_frame) > 254.0)
						{
							if (entity_get_int(para_ent[id], EV_INT_sequence) != 1)
							{
								entity_set_int(para_ent[id], EV_INT_sequence, 1)
							}
							entity_set_float(para_ent[id], EV_FL_frame, 0.0)
						}
						else 
						{
							entity_set_float(para_ent[id], EV_FL_frame, entity_get_float(para_ent[id], EV_FL_frame) + 1.0)
						}
					}
				}
				else
				{
					if (para_ent[id] > 0)
					{
						remove_entity(para_ent[id])
						para_ent[id] = 0
					}
				}
			}
			else
			{
				if (para_ent[id] > 0)
				{
					remove_entity(para_ent[id])
					para_ent[id] = 0
				}
			}
		}
		else if (get_user_oldbutton(id) & IN_USE)
		{
			if (para_ent[id] > 0)
			{
				remove_entity(para_ent[id])
				para_ent[id] = 0
			}
		}
	}
	
	return PLUGIN_CONTINUE
}