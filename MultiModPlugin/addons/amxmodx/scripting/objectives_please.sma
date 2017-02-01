
/*
Complete Objectives Please v0.1
By JGHG, 2003

  Cvar: mp_notifyobjectivetime
  
  This cvar specifies the amount of
  minutes before round ends that the players
  will receive the objectives.
  Defaults to 1.0, to change this, just
  specify another value in console/server.cfg/
  amx.cfg.

  Releases:

  v0.1 - 2003-06-01
  First release

*/

#include <amxmod>
#include <VexdUM>

new bool:alreadyRun = false
new bool:csMap = false
new bool:deMap = false
new bool:asMap = false
new bool:esMap = false

new bool:bombPlanted = false

new redClr = 50
new greenClr = 240
new blueClr = 50
new Float:xPos = -1.0
new Float:yPos = 0.4
new effects2 = 0
new Float:fxtime2 = 0.0
new Float:holdtime2 = 10.0
new Float:fadeintime2 = 2.0
new Float:fadeouttime2 = 2.0
new channel2 = 142

public newround_event() {
	if (alreadyRun)
		return PLUGIN_HANDLED

	new Float:time2 = get_cvar_float("mp_roundtime") - get_cvar_float("mp_notifyobjectivetime")
	time2 = time2 * 60.0
	if (time2 < 0.0)
		time2 = 0.0
	//console_print(0,"COP Debug: Starting timer... %f seconds to go",time)
	set_task(time2,"hurryup",666)

	bombPlanted = false

	alreadyRun = true

	return PLUGIN_HANDLED
}

public hurryup() {
	new buffer[512]
	if (csMap)
		buffer = "Nos nao temos o dia todo, Contra-Terroristas devem salvar os Refens, HOJE! SE APRENSSEM "
	else if (deMap && !bombPlanted)
		buffer = "Nos nao temos o dia todo, Terroristas plantem a bomba hoje se apressem, HOJE! SE APRENSSEM "
	else if (asMap)
		buffer = "Nos nao temos o dia todo, Contra-Terroristas levem o refem a zona de fuga, HOJE! SE APRENSSEM "
	else if (esMap)
		buffer = "Nos nao temos o dia todo, Terroristas deveriam cuidar da zona de fuga, HOJE! SE APRENSSEM "

	//Sets format for hudmessage.
	//native set_hudmessage(red=200, green=100, blue=0,
	//Float:x=-1.0, Float:y=0.35, effects=0, Float:fxtime=6.0,
	//Float:holdtime=12.0, Float:fadeintime=0.1, Float:fadeouttime=0.2,channel=4);
	//set_hudmessage(WS_STANDARDRED,WS_STANDARDGREEN,WS_STANDARDBLUE,-2.0,0.7,0,0.0,5.0,0.05,0.05,HMCHAN_SHOWLVL)

	set_hudmessage(redClr,greenClr,blueClr,xPos,yPos,effects2,fxtime2,holdtime2,fadeintime2,fadeouttime2,channel2)
	show_hudmessage(0,buffer)
	console_print(0,buffer)
}

public endround_event() {
	remove_task(666)
	alreadyRun = false
}

public bombplanted() {
	bombPlanted = true
}

public plugin_init(){
	register_plugin("Complete Objectives Please","0.1","jghg")

	register_event("ResetHUD","newround_event","abc")
	register_event("SendAudio","endround_event", "a", "2&%!MRAD_terwin","2&%!MRAD_ctwin","2&%!MRAD_rounddraw")
	register_event("TextMsg","endround_event","a","2&#Game_C","2&#Game_w")
	register_event("TextMsg","endround_event","a","2&#Game_will_restart_in")
	register_event("SendAudio","bombplanted","a","2&%!MRAD_BOMBPL")

	// Find out what kind of map this is.
	if (find_entity(-1,"hostage_entity") > 0)
		csMap = true
	if (find_entity(-1,"info_bomb_target") > 0 || find_entity(-1,"func_bomb_target"))
		deMap = true
	if (find_entity(-1,"info_vip_start") > 0)
		asMap = true
	if (find_entity(-1,"func_escapezone") > 0)
		esMap = true

	//console_print(0,"%d %d %d %d",csMap,deMap,asMap,esMap)

	if (!csMap && !deMap && !asMap && !esMap)
		pause("a")

	register_cvar("mp_notifyobjectivetime","")
	set_cvar_float("mp_notifyobjectivetime",1.0)

	return PLUGIN_CONTINUE
}


