#include <amxmodx>
#include <engine>

new bool:caughtJump[33]
new bool:doJump[33]
new Float:jumpVeloc[33][3]
new newButton[33]
new numJumps[33]
new wallteam

//====================================================================================================
static const TITLE[] = "Wall Jump"
static const VERSION[] = "0.6"
static const AUTHOR[] = "OneEyed"
//====================================================================================================

public plugin_init()
{
	register_plugin(TITLE,VERSION,AUTHOR)
	
	register_cvar("walljump_str","300.0")
	register_cvar("walljump_num","25")
	register_cvar("walljump_team", "0")
	
	register_touch("player", "worldspawn", "Touch_World")
	register_touch("player", "func_wall", "Touch_World")
	register_touch("player", "func_breakable", "Touch_World")
} 

public client_disconnect(id) {
	caughtJump[id] = false
	doJump[id] = false
	for(new x=0;x<3;x++)
		jumpVeloc[id][x] = 0.0
	newButton[id] = 0
	numJumps[id] = 0
}

public client_PreThink(id)
{
	wallteam = get_cvar_num("walljump_team")
	new team = get_user_team(id)
	if(is_user_alive(id) && (!wallteam || wallteam == team)) 
	{
		newButton[id] = get_user_button(id)
		new oldButton = get_user_oldbutton(id)
		new flags = get_entity_flags(id)
		
		//reset if we are on ground
		if(caughtJump[id] && (flags & FL_ONGROUND)) 
		{
			numJumps[id] = 0
			caughtJump[id] = false
		}
		
		//begin when we jump
		if((newButton[id] & IN_JUMP) && (flags & FL_ONGROUND) && !caughtJump[id] && !(oldButton & IN_JUMP) && !numJumps[id]) 
		{
			caughtJump[id] = true
			entity_get_vector(id,EV_VEC_velocity,jumpVeloc[id])
			jumpVeloc[id][2] = get_cvar_float("walljump_str")
		}
	}
}

public client_PostThink(id) 
{
	if(is_user_alive(id)) 
	{
		//do velocity if we walljumped
		if(doJump[id]) 
		{
			entity_set_vector(id,EV_VEC_velocity,jumpVeloc[id])
			
			doJump[id] = false
			
			if(numJumps[id] >= get_cvar_num("walljump_num")) //reset if we ran out of jumps
			{
				numJumps[id] = 0
				caughtJump[id] = false
			}
		}
	}
}

public Touch_World(id, world) 
{
	if(is_user_alive(id)) 
	{
		//if we touch wall and have jump pressed, setup for jump
		if(caughtJump[id] && (newButton[id] & IN_JUMP) && !(get_entity_flags(id) & FL_ONGROUND)) 
		{
			
			//reverse velocity
			for(new x=0;x<2;x++)
				jumpVeloc[id][x] *= -1.0
				
			numJumps[id]++
			doJump[id] = true
		}	
	}
}