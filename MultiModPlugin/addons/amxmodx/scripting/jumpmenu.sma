#include <amxmodx>
#include <engine>

#define PLUGIN	"Jump Menu"
#define VERSION "2.0"
#define AUTHOR	"v3x"

#define MAX_PLAYERS	33

static const CVAR_MAX_JUMPS[] 	= "amx_maxjumps";
static const CVAR_WJ_STRENGTH[]	= "walljump_strength";
static const CVAR_WJ_NUM[]	= "walljump_num";
static const CVAR_WJ_TEAM[]	= "walljump_team"; 

new PCVAR_MAX_JUMPS;
new PCVAR_WJ_STRENGTH;
new PCVAR_WJ_NUM;
new PCVAR_WJ_TEAM;

new bool:caughtJump[MAX_PLAYERS];
new bool:doWJump[MAX_PLAYERS];
new Float:jumpVeloc[MAX_PLAYERS][3];
new newButton[MAX_PLAYERS];
new numJumps[MAX_PLAYERS];
new team[MAX_PLAYERS];
new wallteam;

public plugin_init() 
{
	register_plugin(PLUGIN , VERSION , AUTHOR);

	register_clcmd("say /jumpmenu"	, "ClCmd_JumpMenu");
	register_clcmd("jumpmenu"	, "ClCmd_JumpMenu");

	if(!cvar_exists(CVAR_MAX_JUMPS))
		PCVAR_MAX_JUMPS	= register_cvar(CVAR_MAX_JUMPS , "15");
	else
		PCVAR_MAX_JUMPS = -1;

	PCVAR_WJ_STRENGTH	= register_cvar(CVAR_WJ_STRENGTH	, "300.0");
	PCVAR_WJ_NUM 		= register_cvar(CVAR_WJ_NUM		, "25");
	PCVAR_WJ_TEAM		= register_cvar(CVAR_WJ_TEAM		, "0");

	register_touch("player" , "worldspawn"		, "Touch_World");
	register_touch("player" , "func_wall"		, "Touch_World");
	register_touch("player" , "func_breakable"	, "Touch_World");
}

enum 
{
	JUMP_REGULAR = 0,
	JUMP_MULTI,
	JUMP_BUNNY,
	JUMP_WALL
}

new g_iJumpType[33];
new jumpnum[33];
new bool:dojump[33];

public client_putinserver(id) 
{
	g_iJumpType[id] = JUMP_MULTI;
	jumpnum[id] = 0;
	dojump[id] = false;
}

public client_disconnect(id) 
{
	jumpnum[id] = 0;
	dojump[id] = false;

	caughtJump[id] = false;
	doWJump[id] = false;
	for(new x = 0; x < 3; x++)
		jumpVeloc[id][x] = 0.0;
	newButton[id] = 0;
	numJumps[id] = 0;
}

public ClCmd_JumpMenu(id) 
{
	new menu = menu_create("Select your jump type:" , "menuHandler_Jump");

	menu_additem(menu , "Multi-jump"	, "" , 0);
	menu_additem(menu , "Bunnyhop"		, "" , 0);
	menu_additem(menu , "Wall Jump^n"	, "" , 0);
	menu_additem(menu , "Regular"		, "" , 0);

	menu_setprop(menu , MPROP_EXIT , MEXIT_ALL);
	
	menu_display(id , menu , 0);

	new arg[21];
	read_argv(0 , arg , 20);
	if(!contain(arg , "say"))
		return PLUGIN_CONTINUE;

	return PLUGIN_HANDLED;
}

public menuHandler_Jump(id , menu , item) 
{
	if(item == MENU_EXIT) 
	{
		menu_destroy(menu);
		return PLUGIN_HANDLED;
	}
	
	new szCommand[6] , szName[64];
	new access , callback;
	
	menu_item_getinfo(menu , item , access , szCommand , 5 , szName , 63 , callback);
	
	if(equal(szName , "Multi-jump")) 
	{
		client_print(id , print_chat , "[AMXX] Multi-jump enabled");
		g_iJumpType[id] = JUMP_MULTI;

		menu_destroy(menu); return PLUGIN_CONTINUE;
	}
	else if(equal(szName , "Bunnyhop")) 
	{
		client_print(id , print_chat , "[AMXX] Bunnyhop enabled");
		g_iJumpType[id] = JUMP_BUNNY;

		menu_destroy(menu); return PLUGIN_CONTINUE;
	}
	else if(equal(szName , "Wall Jump^n"))
	{
		client_print(id , print_chat , "[AMXX] Walljump enabled");
		g_iJumpType[id] = JUMP_WALL;

		menu_destroy(menu); return PLUGIN_CONTINUE;
	}
	else 
	{
		client_print(id , print_chat , "[AMXX] Regular jumping enabled");
		g_iJumpType[id] = JUMP_REGULAR;

		menu_destroy(menu); return PLUGIN_CONTINUE;
	}
	
	menu_destroy(menu);
	
	return PLUGIN_HANDLED;
}

public client_PreThink(id) 
{
	if(!is_user_alive(id) || !g_iJumpType[id])
		return PLUGIN_CONTINUE;
		
	if(g_iJumpType[id] == JUMP_BUNNY) 
	{
		entity_set_float(id, EV_FL_fuser2, 0.0)	 // Disable slow down after jumping

		// Code from CBasePlayer::Jump (player.cpp)	 Make a player jump automatically
		if (entity_get_int(id, EV_INT_button) & 2) {	// If holding jump
			new flags = entity_get_int(id, EV_INT_flags)

			if (flags & FL_WATERJUMP)
				return PLUGIN_CONTINUE
			if ( entity_get_int(id, EV_INT_waterlevel) >= 2 )
				return PLUGIN_CONTINUE
			if ( !(flags & FL_ONGROUND) )
				return PLUGIN_CONTINUE

			new Float:velocity[3]
			entity_get_vector(id, EV_VEC_velocity, velocity)
			velocity[2] += 250.0
			entity_set_vector(id, EV_VEC_velocity, velocity)

			entity_set_int(id, EV_INT_gaitsequence, 6)	// Play the Jump Animation
			
			return PLUGIN_CONTINUE;
		}
	}
	else if(g_iJumpType[id] == JUMP_MULTI) 
	{
		if((get_user_button(id) & IN_JUMP) && !(get_entity_flags(id) & FL_ONGROUND) && !(get_user_oldbutton(id) & IN_JUMP)) 
		{
			if(jumpnum[id] < get_pcvar_num(PCVAR_MAX_JUMPS)) 
			{
				dojump[id] = true
				jumpnum[id]++
				return PLUGIN_CONTINUE
			}
		}
		if((get_user_button(id) & IN_JUMP) && (get_entity_flags(id) & FL_ONGROUND)) 
		{
			jumpnum[id] = 0
			return PLUGIN_CONTINUE
		}
	}
	else if(g_iJumpType[id] == JUMP_WALL)
	{
		wallteam = get_pcvar_num(PCVAR_WJ_TEAM)
		team[id] = get_user_team(id)
		if(!wallteam || wallteam == team[id]) 
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
				jumpVeloc[id][2] = get_pcvar_float(PCVAR_WJ_STRENGTH)
			}
		}
	}
	return PLUGIN_CONTINUE;
}

public client_PostThink(id) 
{
	if((g_iJumpType[id] != JUMP_MULTI && g_iJumpType[id] != JUMP_WALL) || !is_user_alive(id)) 
		return PLUGIN_CONTINUE

	if(dojump[id]) 
	{
		new Float:velocity[3]	
		entity_get_vector(id,EV_VEC_velocity,velocity)
		velocity[2] = random_float(265.0,285.0)
		entity_set_vector(id,EV_VEC_velocity,velocity)
		dojump[id] = false

		return PLUGIN_CONTINUE
	}
	//do velocity if we walljumped
	else if(doWJump[id]) 
	{
		entity_set_vector(id,EV_VEC_velocity,jumpVeloc[id])
			
		doWJump[id] = false
			
		if(numJumps[id] >= get_pcvar_num(PCVAR_WJ_NUM)) //reset if we ran out of jumps
		{
			numJumps[id] = 0
			caughtJump[id] = false
		}
	}
	return PLUGIN_CONTINUE
}

public Touch_World(id, world) 
{
	if(is_user_alive(id) && g_iJumpType[id] == JUMP_WALL) 
	{
		//if we touch wall and have jump pressed, setup for jump
		if(caughtJump[id] && (newButton[id] & IN_JUMP) && !(get_entity_flags(id) & FL_ONGROUND)) 
		{
			//reverse velocity
			for(new x=0;x<2;x++)
				jumpVeloc[id][x] *= -1.0
				
			numJumps[id]++
			doWJump[id] = true
		}	
	}
}