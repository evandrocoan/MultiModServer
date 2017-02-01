//Marduk - by Mydas

/*
marduk_level 6
marduk_cooldown 200     - his power's cooldown, in seconds (it does NOT reset on newround)
marduk_startingsecs 3.0 - how long will his timestop last if player is at marduk_level ?
marduk_secsperlev 0.4   - how many seconds (of lasting timestop) per level will he gain ?
*/

#include <amxmod>
#include <Vexd_Utilities>
#include <superheromod>

// GLOBAL VARIABLES
new gHeroName[]="Marduk"
new bool:gHasMardukPowers[SH_MAXSLOTS + 1]
new bool:stopped[SH_MAXSLOTS + 1]
new sequence[SH_MAXSLOTS + 1]
new gPlayerLevels[SH_MAXSLOTS+1]
new Float:NullVeloc[3]
new Float:SaveVelocs[SH_MAXSLOTS + 1][3]

public plugin_init()
{
	register_plugin("SUPERHERO Marduk","1.0","Mydas")

	register_cvar("marduk_level", "6")
	register_cvar("marduk_cooldown", "200.0")
	register_cvar("marduk_startingsecs", "3.0")
	register_cvar("marduk_secsperlev", "0.4") // that will make him have a 8.6 seconds timestop at level 20

	shCreateHero(gHeroName, "Time Stop", "Press key to simply stop the time !", true, "marduk_level" )

	register_srvcmd("marduk_init", "marduk_init")
	shRegHeroInit(gHeroName, "marduk_init")

	register_srvcmd("marduk_kd", "marduk_kd")
	shRegKeyDown(gHeroName, "marduk_kd")
	
	register_srvcmd("marduk_levels", "marduk_levels")
	shRegLevels(gHeroName,"marduk_levels")
	
	register_event("DeathMsg","player_died","a")

	
	NullVeloc[0] = 0.0
	NullVeloc[1] = 0.0
	NullVeloc[2] = 9.0
}

public marduk_init()
{
	new temp[6]
	read_argv(1,temp,5)
	new id = str_to_num(temp)

	read_argv(2,temp,5)
	new hasPowers = str_to_num(temp)

	gHasMardukPowers[id] = (hasPowers != 0)
}

public marduk_kd()
{
	if(!hasRoundStarted()) return

	new temp[128]
	read_argv(1,temp,5)
	new id = str_to_num(temp)

	if(!is_user_alive(id) || !gHasMardukPowers[id]) return

	if(gPlayerUltimateUsed[id]) {
		playSoundDenySelect(id)
		client_print(id, print_chat, "[Mdk] Power not available yet.")
		return
	}

	new Float:seconds = (gPlayerLevels[id]-get_cvar_num("marduk_level")) *
		get_cvar_float("marduk_secsperlev") +
		get_cvar_float("marduk_startingsecs")
		
	set_hudmessage(50,100,255,-1.0,0.35,0,1.0,1.3,0.4,0.4,120)
	show_hudmessage(id,"You have stopped the flow of time (for %f real seconds).", seconds)	
	
	ultimateTimer(id, get_cvar_float("marduk_cooldown"))

	for(new player=1; player<=SH_MAXSLOTS; player++) 
		if(is_user_alive(player) && !gHasMardukPowers[player] && !stopped[player]) {
			
			shStun(player, floatround(seconds))
			set_user_maxspeed(player, 0.1)
			
			client_cmd(player, "writecfg temp")
			client_cmd(player, "clear")
			client_cmd(player, "-moveleft")
			client_cmd(player, "-moveright")
			client_cmd(player, "-forward")
			client_cmd(player, "-back")
			client_cmd(player, "-attack")
			
			stopped[player] = true
			Entvars_Get_Vector(player, EV_VEC_velocity, SaveVelocs[player])
			sequence[player] = Entvars_Get_Int(player, EV_INT_sequence)
			
			new parm[1]
			parm[0] = player
			set_task(seconds, "marduk_startflow", 0, parm, 1)
			
		}
}

public marduk_startflow(parm[])
{
	new id = parm[0]
	if(!stopped[id]) return
	client_cmd(id, "exec temp.cfg")
	Entvars_Set_Vector(id, EV_VEC_velocity, SaveVelocs[id])
	stopped[id] = false
}

public client_PreThink(id)
{
	if(!is_user_connected(id) || !is_user_alive(id)) return
	if (!stopped[id]) return

	set_hudmessage(50,100,255,-1.0,0.35,0,1.0,1.3,0.4,0.4,120)
	show_hudmessage(id,"Marduk has stopped the flow of time.")	

	client_cmd(id, "unbindall")
	client_cmd(id, "sensitivity 0.001")
	client_cmd(id, "-mlook")
	
	Entvars_Set_Vector(id, EV_VEC_velocity, NullVeloc)
	
	Entvars_Set_Int(id, EV_INT_sequence, sequence[id]) 
}

public marduk_levels()
{
	new id[5]
	new lev[5]

	read_argv(1,id,4)
	read_argv(2,lev,4)

	gPlayerLevels[str_to_num(id)]=str_to_num(lev)
}

public player_died()
{
	new parm[1]
	parm[0] = read_data(2) 
	set_task(0.1, "marduk_startflow", 0, parm, 1)
}

public client_disconnect(id)
{
	if(!stopped[id]) return
	client_cmd(id, "exec temp.cfg")
	stopped[id] = false
}