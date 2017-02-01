/*AMX MOD X script
**************************************************************************
 * 		FragCounter   V    1.01		by	Scarzzurs
 *
 *
 *  *******************************************************************************
 *  
 *	Ported By KingPin( kingpin@onexfx.com ). I take no responsibility 
 *	for this file in any way. Use at your own risk. No warranties of any kind. 
 *
 *  ********************************************************************************
 *
 **********************************************************************************/

#include <amxmodx>

new pfrags[33]
new top
new gmsgStatusIcon

public playerspawn(id){
	pfrags[id]=0
	top = 0
	calculate_time(id,pfrags[id])
}

public death(){
	new killer = read_data(1)
	pfrags[killer]=pfrags[killer]+1
	if (pfrags[killer]==9 && file_exists("sound/misc/monsterkill.wav")==1)
		emit_sound(killer,CHAN_STATIC, "misc/monsterkill.wav", 1.0, ATTN_NORM, 0, PITCH_NORM)
	topplayer()
	new players[32]
	new player_num
	get_players(players, player_num)
	for (new i = 0; i < player_num; i++)
		calculate_time(players[i],pfrags[players[i]])
	return PLUGIN_CONTINUE
}

public topplayer(){
	new score
	new players[32]
	new player_num
	get_players(players, player_num)
	for (new i = 0; i < player_num; i++){
		if (pfrags[players[i]]>score){
			score=pfrags[players[i]]
			top=players[i]
		}
		else if (pfrags[players[i]]==score)
			top = 0
	}
}

public calculate_time(id,num){
	switch(num){
		case 0:{
			showtimer(id,"number_1",0)
			showtimer(id,"number_2",0)
			showtimer(id,"number_3",0)
			showtimer(id,"number_4",0)
			showtimer(id,"number_5",0)
			showtimer(id,"number_6",0)
			showtimer(id,"number_7",0)
			showtimer(id,"number_8",0)
			showtimer(id,"number_9",0)
		}
		case 1:{
			showtimer(id,"number_1",1)
			showtimer(id,"number_2",0)
			showtimer(id,"number_3",0)
			showtimer(id,"number_4",0)
			showtimer(id,"number_5",0)
			showtimer(id,"number_6",0)
			showtimer(id,"number_7",0)
			showtimer(id,"number_8",0)
			showtimer(id,"number_9",0)
		}
		case 2:{
			showtimer(id,"number_1",0)
			showtimer(id,"number_2",1)
			showtimer(id,"number_3",0)
			showtimer(id,"number_4",0)
			showtimer(id,"number_5",0)
			showtimer(id,"number_6",0)
			showtimer(id,"number_7",0)
			showtimer(id,"number_8",0)
			showtimer(id,"number_9",0)
		}
		case 3:{
			showtimer(id,"number_1",0)
			showtimer(id,"number_2",0)
			showtimer(id,"number_3",1)
			showtimer(id,"number_4",0)
			showtimer(id,"number_5",0)
			showtimer(id,"number_6",0)
			showtimer(id,"number_7",0)
			showtimer(id,"number_8",0)
			showtimer(id,"number_9",0)
		}
		case 4:{
			showtimer(id,"number_1",0)
			showtimer(id,"number_2",0)
			showtimer(id,"number_3",0)
			showtimer(id,"number_4",1)
			showtimer(id,"number_5",0)
			showtimer(id,"number_6",0)
			showtimer(id,"number_7",0)
			showtimer(id,"number_8",0)
			showtimer(id,"number_9",0)
		}
		case 5:{
			showtimer(id,"number_1",0)
			showtimer(id,"number_2",0)
			showtimer(id,"number_3",0)
			showtimer(id,"number_4",0)
			showtimer(id,"number_5",1)
			showtimer(id,"number_6",0)
			showtimer(id,"number_7",0)
			showtimer(id,"number_8",0)
			showtimer(id,"number_9",0)
		}
		case 6:{
			showtimer(id,"number_1",0)
			showtimer(id,"number_2",0)
			showtimer(id,"number_3",0)
			showtimer(id,"number_4",0)
			showtimer(id,"number_5",0)
			showtimer(id,"number_6",1)
			showtimer(id,"number_7",0)
			showtimer(id,"number_8",0)
			showtimer(id,"number_9",0)
		}
		case 7:{
			showtimer(id,"number_1",0)
			showtimer(id,"number_2",0)
			showtimer(id,"number_3",0)
			showtimer(id,"number_4",0)
			showtimer(id,"number_5",0)
			showtimer(id,"number_6",0)
			showtimer(id,"number_7",1)
			showtimer(id,"number_8",0)
			showtimer(id,"number_9",0)
		}
		case 8:{
			showtimer(id,"number_1",0)
			showtimer(id,"number_2",0)
			showtimer(id,"number_3",0)
			showtimer(id,"number_4",0)
			showtimer(id,"number_5",0)
			showtimer(id,"number_6",0)
			showtimer(id,"number_7",0)
			showtimer(id,"number_8",1)
			showtimer(id,"number_9",0)
		}
		case 9:{
			showtimer(id,"number_1",0)
			showtimer(id,"number_2",0)
			showtimer(id,"number_3",0)
			showtimer(id,"number_4",0)
			showtimer(id,"number_5",0)
			showtimer(id,"number_6",0)
			showtimer(id,"number_7",0)
			showtimer(id,"number_8",0)
			showtimer(id,"number_9",1)
		}
	}
}

public showtimer(id,number[10],onoff){
	if (is_user_connected(id)){
		if (id == top && onoff == 1)
			onoff = 2
		message_begin( MSG_ONE, gmsgStatusIcon, {0,0,0}, id )
		write_byte( onoff ) // status
		write_string( number ) // sprite name
		write_byte( 0 ) // red
		write_byte( 255 ) // green
		write_byte( 0 ) // blue
		message_end()
	}
}

public roundend(){
	if (top != 0){
		new sname[32]
		get_user_name(top,sname,32)
		set_hudmessage(0, 255, 0, -1.0, 0.3, 0, 1.0, 5.0, 0.1, 0.2, 5)
		show_hudmessage(0,"Best player of the round: %s",sname)
	}
}

public plugin_init(){
	register_plugin("FragCounter","1.01","Scarzzurs")
	gmsgStatusIcon = get_user_msgid("StatusIcon")
	register_event("DeathMsg","death","a")
	register_event("ResetHUD","playerspawn","b")
	register_event("SendAudio","roundend","a","2=%!MRAD_terwin","2=%!MRAD_ctwin","2=%!MRAD_rounddraw")
}

public plugin_precache()
	if (file_exists("sound/misc/monsterkill.wav")==1)
		precache_sound("misc/monsterkill.wav")