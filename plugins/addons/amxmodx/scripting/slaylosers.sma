/* AMX MOD X script.
* This file is provided as is with no warranty.
*
* Presenting: Slay Losers
*
* Effect: Losing the objective results in a random orgy of GFX destruction
*	   for the losing team (everyone on the losing team DIES).
*
* NOTE: The slaying will NOT remove frags.
*
* CVAR: Set mp_slaylosers to 0 if you want to turn it off.
*
* Written by: Denkkar Seffyd, now in a seperate WC3 independent package (no XP removal though)
*
* Install: compile then add slaylosers.amx to addons/amx/plugin.ini
*
*/

#include <amxmodx>

new white
new lightning
new g_sModelIndexSmoke

new mp_slaylosers

public plugin_init()
{
	register_plugin("AMX Slay Losers", "1.1", "d3n14@yahoo.com")
	register_event("SendAudio", "end_round", "a", "2=%!MRAD_terwin", "2=%!MRAD_ctwin", "2=%!MRAD_rounddraw")

	mp_slaylosers = register_cvar("mp_slaylosers", "1", FCVAR_SERVER)
}

public plugin_precache()
{
	g_sModelIndexSmoke = precache_model("sprites/steam1.spr")
	lightning = precache_model("sprites/lgtning.spr")
	white = precache_model("sprites/white.spr")
	precache_sound( "ambience/thunder_clap.wav")
	precache_sound( "weapons/headshot2.wav")
	precache_sound( "weapons/explode3.wav")
}


public end_round()
{
	// Only active if CVAR is not equal to 0
	new mode = get_pcvar_num(mp_slaylosers)
	if( mode )
	{
		new parm[32]
		new len = read_data(2, parm, charsmax(parm))
		set_task(0.1, "slay_those_losers", mode == 2, parm, len + 1)
	}
}

// Slays each player who failed to stop the other team from completing the objective.
// A random slay method is chosen for each player.
public slay_those_losers(parm[], effects)
{
	new origin[3], srco[3]
	new player[32], playersnum
	new id

	get_players(player,playersnum,"ea",(parm[7] == 't') ? "CT" : "TERRORIST" )

	for(new i = 0; i < playersnum; ++i)
	{
		id = player[i]

		if( effects )
		{
			get_user_origin(id,origin)
			origin[2] -= 26
			srco[0]=origin[0]+150
			srco[1]=origin[1]+150
			srco[2]=origin[2]+800
			switch(random_num(1,3))
			{
				case 1:{
					slay_lightning(srco,origin)
					emit_sound(id,CHAN_ITEM, "ambience/thunder_clap.wav", 1.0, ATTN_NORM, 0, PITCH_NORM)
				}
				case 2:{
					slay_blood(origin)
					emit_sound(id,CHAN_ITEM, "weapons/headshot2.wav", 1.0, ATTN_NORM, 0, PITCH_NORM)
				}
				case 3:	{
					slay_explode(origin)
					emit_sound(id,CHAN_ITEM, "weapons/explode3.wav", 1.0, ATTN_NORM, 0, PITCH_NORM)
				}
			}
		}
		set_hudmessage(178, 14, 41, -1.0, -0.4, 1, 0.5, 1.7, 0.2, 0.2, -1);
		show_hudmessage(id, "Objective Failed^nFailure Is Not An Option^nYou Die Now" );
		user_kill(id, 1)
	}
}

slay_explode(vec1[3])
{
	// blast circles
	message_begin( MSG_BROADCAST,SVC_TEMPENTITY,vec1)
	write_byte( TE_BEAMCYLINDER )
	write_coord(vec1[0])
	write_coord(vec1[1])
	write_coord(vec1[2] + 16)
	write_coord(vec1[0])
	write_coord(vec1[1])
	write_coord(vec1[2] + 1936)
	write_short( white )
	write_byte( 0 ) // startframe
	write_byte( 0 ) // framerate
	write_byte( 2 ) // life
	write_byte( 16 ) // width
	write_byte( 0 ) // noise
	write_byte( 188 ) // r
	write_byte( 220 ) // g
	write_byte( 255 ) // b
	write_byte( 255 ) //brightness
	write_byte( 0 ) // speed
	message_end()
	//Explosion2
	message_begin( MSG_BROADCAST,SVC_TEMPENTITY)
	write_byte( TE_EXPLOSION2 )
	write_coord(vec1[0])
	write_coord(vec1[1])
	write_coord(vec1[2])
	write_byte( 188 ) // byte (scale in 0.1's)
	write_byte( 10 ) // byte (framerate)
	message_end()
	//Smoke
	message_begin( MSG_BROADCAST,SVC_TEMPENTITY,vec1)
	write_byte( TE_SMOKE )
	write_coord(vec1[0])
	write_coord(vec1[1])
	write_coord(vec1[2])
	write_short( g_sModelIndexSmoke )
	write_byte( 2 )
	write_byte( 10 )
	message_end()
}

slay_blood(vec1[3])
{
	//LAVASPLASH
	message_begin( MSG_BROADCAST,SVC_TEMPENTITY)
	write_byte( TE_LAVASPLASH )
	write_coord(vec1[0])
	write_coord(vec1[1])
	write_coord(vec1[2])
	message_end()
}

slay_lightning(vec1[3],vec2[3])
{
	//Lightning
	message_begin( MSG_BROADCAST,SVC_TEMPENTITY)
	write_byte( TE_BEAMPOINTS )
	write_coord(vec1[0])
	write_coord(vec1[1])
	write_coord(vec1[2])
	write_coord(vec2[0])
	write_coord(vec2[1])
	write_coord(vec2[2])
	write_short( lightning )
	write_byte( 1 ) // framestart
	write_byte( 5 ) // framerate
	write_byte( 2 ) // life
	write_byte( 20 ) // width
	write_byte( 30 ) // noise
	write_byte( 200 ) // r, g, b
	write_byte( 200 ) // r, g, b
	write_byte( 200 ) // r, g, b
	write_byte( 200 ) // brightness
	write_byte( 200 ) // speed
	message_end()
	//Sparks
	message_begin( MSG_PVS, SVC_TEMPENTITY,vec2)
	write_byte( TE_SPARKS )
	write_coord( vec2[0] )
	write_coord( vec2[1] )
	write_coord( vec2[2] )
	message_end()
	//Smoke
	message_begin( MSG_BROADCAST,SVC_TEMPENTITY,vec2)
	write_byte( TE_SMOKE )
	write_coord(vec2[0])
	write_coord(vec2[1])
	write_coord(vec2[2])
	write_short( g_sModelIndexSmoke )
	write_byte( 10 )
	write_byte( 10 )
	message_end()
}
