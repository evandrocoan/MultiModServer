#include <amxmodx>
#include <engine>

/*

The cvar is controlled like this

sv_grentrail 0 = No Grentrail
sv_grentrail 1 = All Green Trails
sv_grentrail 2 = Random Colors
sv_grentrail 3 = Team Specific (Tested In CS...)

*/

#define TE_BEAMFOLLOW 22

new m_iTrail

public plugin_init()
{
	register_plugin("Grentrail","1.3","AssKicR")
	register_event("SendAudio","FireInTheHole","bc","2=%!MRAD_FIREINHOLE")
	register_cvar("sv_grentrail","0")
}

public plugin_precache() {
	m_iTrail = precache_model("sprites/smoke.spr")
}

public FireInTheHole()
{
	if(get_cvar_num("sv_grentrail") == 0)
		return PLUGIN_HANDLED

	new id = read_data(1)
	set_task(0.3, "grenid", id)
	return PLUGIN_HANDLED
}

public grenid(id){
	new grenadeid = get_grenade(id)
	if (grenadeid) {
		message_begin( MSG_BROADCAST, SVC_TEMPENTITY )
		write_byte( TE_BEAMFOLLOW )
		write_short(grenadeid) // entity
		write_short(m_iTrail)  // model
		write_byte( 10 )       // life
		write_byte( 5 )        // width
		if (get_cvar_num("sv_grentrail")==1) {
			write_byte( 0 )      // r, g, b
			write_byte( 255 )    // r, g, b
			write_byte( 0 )      // r, g, b
		}
		else if (get_cvar_num("sv_grentrail")==2)
		{
			new red = random_num(0,255)
			new green = random_num(0,255)
			new blue = random_num(0,255)
			write_byte( red )     // r, g, b
			write_byte( green )   // r, g, b
			write_byte( blue )    // r, g, b
		}
		else if (get_cvar_num("sv_grentrail")==3)
		{
			if (get_user_team(id)==1) // Terrorist 
			{ 
				write_byte( 255 ) // r, g, b 
				write_byte( 0 )   // r, g, b 
				write_byte( 0 )   // r, g, b 
			} 
			else // Counter-Terrorist 
			{ 
				write_byte( 0 )   // r, g, b 
				write_byte( 0 )   // r, g, b 
				write_byte( 255 ) // r, g, b 
			}
		}
		else
		{
			write_byte( 0 )       // r, g, b 
			write_byte( 0 )       // r, g, b 
			write_byte( 0 )       // r, g, b 
		}
		switch (random_num(0,2))
		{
			case 0:write_byte( 64 )	 // brightness
			case 1:write_byte( 128 ) // brightness
			case 2:write_byte( 192 ) // brightness
		}
		message_end() // move PHS/PVS data sending into here (SEND_ALL, SEND_PVS, SEND_PHS)
	}
}