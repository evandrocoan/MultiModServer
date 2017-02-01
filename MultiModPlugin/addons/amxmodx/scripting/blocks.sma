/*
	Based on BCM by Fatalis (FatalisDK@hotmail.com)

	CVARS:
		bb_noslowdown (0|1) - Stop slowdown once you touch a bhop box? (For people new to bhopping)
		bb_heal # - How much HP do heal blocks heal?
		bb_hurt # - How much damage do hurt blocks do?
		bb_kill (0|1) - Should hurt and kill blocks kill players or set their hp to 1? (1==kill)
	
	Chat Commands:
	/blocks - Open the main menu of the plugin - Admins with flag defined only.
	
	Console Commands:
	amx_blocks - Open the main menu of the plugin - Admins with flag defined only.
	+grab_block - Grabs a block without having to go through menu
*/

#define ADMIN_BLOCKS ADMIN_KICK

#include <amxmodx>
#include <amxmisc>
#include <fakemeta>
#include <fun>
#include <xs>

#define MAX_PLAYERS 32

#pragma semicolon 1;

#define fm_remove_entity(%1) engfunc(EngFunc_RemoveEntity, %1)

#define TSK_UNSOLID	5000
#define TSK_SOLID	6000

#define BOOSTER		2
#define JUMPER		500.0
#define THROWER		500
#define STICK		20
#define CHICK_JUMP	200.0

#define SNAP_DISTANCE 10.0

#define TELE_FRAMES 25

#define TASK_CHECK	10.0

#define TSK_CHICK	3000
#define TSK_SHOW	4000

/* Strings */
new const gPLUGIN[] =  "Building Blocks";
new const gVERSION[] =  "1.4";
new const gAUTHOR[] =  "Emp`";

new gFile[97];

new Float:Mover[MAX_PLAYERS];

/* Integers */
new gBhopMenu;
new gCreateMenu;
new gCreateMenu2;
new gEditMenu;
new gMoveMenu;
new gSetMenu;
new gAdvMenu;
new gInfoTarget;

new bb_noslowdown, bb_hurt, bb_heal, bb_kill;

new LastAction[MAX_PLAYERS+1];
new Float:nVelocity[MAX_PLAYERS+1][3];
new PlayerGrab[MAX_PLAYERS+1];
new PlayerNoClip[MAX_PLAYERS+1];
new PlayerGodMode[MAX_PLAYERS+1];
new PlayerSnap[MAX_PLAYERS+1];
new PlayerSmartMode[MAX_PLAYERS+1];
new PlayerSafeMove[MAX_PLAYERS+1];

new PlayerInSmart[MAX_PLAYERS+1];
new PlayerSmartTele[MAX_PLAYERS+1];

new PlayerBoxClass[MAX_PLAYERS+1];
new PlayerBoxType[MAX_PLAYERS+1];
new PlayerTeleport[MAX_PLAYERS+1];

new gGrablength[33];

new bool:NoFall[MAX_PLAYERS+1];

new const Enabled[] = "Enabled";
new const Disabled[] = "Disabled";

new const box_classname[] = "bbb";
new const tele_classname[] = "bbt";

enum
{
	MODE_OLD,
	MODE_SMART,
	MODE_MAX
}

enum
{
	TELE_IN,
	TELE_OUT,
	TELE_MAX
}

new const telesprites[TELE_MAX][] = {
	"sprites/enter1.spr",
	"sprites/exit1.spr"
};

new const Float:telesize[2][3] = {
	{-16.0,	-16.0,	-16.0},		{16.0,	16.0,	16.0}
};

enum
{
	AC_CRE,
	AC_DUP,
	AC_MOV,
	AC_MAX
}

enum
{
	ROT_NONE,
	ROT_LEFT,
	ROT_UP,
	ROT_LEFTUP,
	ROT_SWING,
	ROT_SWINGUP,
	ROT_MAX
}

enum
{
	TY_BLOCK,
	TY_CUBE,
	TY_CHICK,
	TY_WALL,
	TY_MAX
}

new const blocks[TY_MAX][] = {
	"Block",
	"Cube",
	"Chicken",
	"Wall"
};

new const models[TY_MAX][] = {
	"models/blocks/bhopbox.mdl",
	"models/blocks/pac_cube.mdl",
	"models/blocks/chick.mdl",
	"models/blocks/wall_n.mdl"
};

new const Float:sizes[TY_MAX][2][3] = {
	{{-32.0,	-32.0,	-4.0},		{32.0,	32.0,	4.0}},
	{{-8.0,		-8.0,	-8.0},		{8.0,	8.0,	8.0}},
	{{-8.0,		-8.0,	-8.0},		{8.0,	8.0,	8.0}},
	{{-88.0,	-6.0,	-19.0},		{88.0,	6.0,	169.0}}
};

new const rotation_num[TY_MAX] = {
	2,
	0,
	0,
	1
};

enum
{
	BX_NORM,
	BX_SOLI,
	BX_HEAL,
	BX_HURT,
	BX_BOOS,
	BX_JUMP,
	BX_TBLO,
	BX_CBLO,
	BX_DELA,
	BX_INVI,
	BX_THRO,
	BX_WATE,
	BX_ICE,
	BX_STIC,
	BX_KILL,
	BX_ATHR,
	BX_FNOR,
	BX_REFL,
	BX_GHOS,
	BX_MAX
}

new const classes[BX_MAX][] = {
	"B-Hop",
	"Solid",
	"Heal",
	"Hurt",
	"Boost",
	"Jump",
	"T-Blocker",
	"CT-Blocker",
	"Delayed",
	"Invisible",
	"Throw",
	"Water",
	"Ice",
	"Sticky",
	"Kill",
	"Anti-Throw",
	"Normal",
	"Reflect",
	"Ghost"
};

new const colors[BX_MAX][3] = {
	{0,		0,		0},		// B-Hop
	{0,		255,	0},		// Solid
	{0,		0,		255},	// Heal
	{255,	0,		0},		// Hurt
	{255,	255,	0},		// Boost
	{255,	0,		255},	// Jump
	{128,	0,		0},		// T-Blocker
	{0,		0,		128},	// CT-Blocker
	{190,	190,	190},	// Delayed
	{-1,	-1,		-1},	// Invisible
	{255,	140,	0},		// Throw
	{0,		191,	255},	// Water
	{176,	224,	230},	// Ice
	{184,	134,	11},	// Sticky
	{233,	150,	122},	// Kill
	{0,		255,	140},	// Anti-Throw
	{0,		0,		0},		// Fake B-Hop
	{255,	250,	250},	// Reflect
	{-1,	-1,		-1}		// Ghost
};

#define TeleType(%1) pev(%1, pev_iuser1)
#define TeleMate(%1) pev(%1, pev_iuser2)
#define SetTeleType(%1,%2) set_pev(%1, pev_iuser1, %2)
#define SetTeleMate(%1,%2) set_pev(%1, pev_iuser2, %2)

#define BoxClass(%1) pev(%1, pev_iuser1)
#define BoxType(%1) pev(%1, pev_iuser2)
#define BoxRot(%1) pev(%1, pev_iuser3)
#define SetBoxClass(%1,%2) set_pev(%1, pev_iuser1, %2)
#define SetBoxType(%1,%2) set_pev(%1, pev_iuser2, %2)
#define SetBoxRot(%1,%2) set_pev(%1, pev_iuser3, %2)

#define TypeRot(%1) rotation_num[%1]

public plugin_init()
{
	register_plugin(gPLUGIN, gVERSION, gAUTHOR);

	set_pcvar_string(
		register_cvar("Building_Blocks",gVERSION,FCVAR_SERVER|FCVAR_SPONLY)
	,gVERSION);

	/* CVARS */
	bb_noslowdown = register_cvar("bb_noslowdown", "1");
	bb_hurt = register_cvar("bb_hurt", "10");
	bb_heal = register_cvar("bb_heal", "4");
	bb_kill = register_cvar("bb_kill", "1");
	
	/* CLCMDS */
	register_clcmd("say /blocks", "cmdBhopMenu", ADMIN_BLOCKS);
	register_clcmd("amx_blocks", "cmdBhopMenu", ADMIN_BLOCKS);

	register_clcmd("+grab_block", "grab_command", ADMIN_BLOCKS);
	register_clcmd("-grab_block", "grab_command");

	/* Forwards */
	register_forward(FM_Touch, "fwdTouch", 0);
	register_forward(FM_PlayerPreThink, "PlayerPreThink");
	register_forward(FM_PlayerPostThink, "PlayerPostThink");

	/* Events */
	
	new szDir[65];
	new szMap[33];
	
	gBhopMenu = menu_create("Building Blocks", "mnuBhop");

	menu_additem(gBhopMenu, "Create Block", "1");
	menu_additem(gBhopMenu, "Create Teleport", "9");
	menu_additem(gBhopMenu, "Edit Block", "2");
	menu_additem(gBhopMenu, "Duplicate Block", "3");
	menu_additem(gBhopMenu, "Grab/Release Block", "4");
	menu_additem(gBhopMenu, "Destroy Block", "5");
	menu_additem(gBhopMenu, "Settings", "6");
	menu_additem(gBhopMenu, "Advanced", "7");
	menu_additem(gBhopMenu, "Smart Menu", "8");
	menu_additem(gBhopMenu, "Exit", "100");
	menu_setprop(gBhopMenu, MPROP_PERPAGE, 0);

	gAdvMenu = menu_create("Advanced", "mnuAdv");
	menu_additem(gAdvMenu, "Delete All Blocks", "1");
	menu_additem(gAdvMenu, "Delete All Teleports", "2");
	menu_additem(gAdvMenu, "Load file", "3");
	menu_additem(gAdvMenu, "Write to file", "4");
	menu_additem(gAdvMenu, "Delete Copies", "5");

	gSetMenu = menu_create("Settings", "mnuSet");
	menu_additem(gSetMenu, "Move More", "1");
	menu_additem(gSetMenu, "Move Less", "2");
	menu_additem(gSetMenu, "Godmode", "3");
	menu_additem(gSetMenu, "No-Clip", "4");
	menu_additem(gSetMenu, "Snapping", "5");
	menu_additem(gSetMenu, "Safe Create/Move", "6");
	menu_additem(gSetMenu, "Exit", "100");
	menu_setprop(gSetMenu, MPROP_PERPAGE, 0);

	gCreateMenu = menu_create("Create Type", "mnuCreate");
	for(new i=0; i<TY_MAX; i++){
		formatex( szDir, 64, "%s", blocks[i]);
		formatex( szMap, 32, "%d", i);
		menu_additem(gCreateMenu, szDir, szMap);
	}
	gCreateMenu2 = menu_create("Create Class", "mnuCreate2");
	for(new i=0; i<BX_MAX; i++){
		formatex( szDir, 64, "%s", classes[i]);
		formatex( szMap, 32, "%d", i);
		menu_additem(gCreateMenu2, szDir, szMap);
	}
	
	gEditMenu = menu_create("Edit Block", "mnuEdit");
	menu_additem(gEditMenu, "Move Block", "1");
	menu_additem(gEditMenu, "Change Class(+)", "10");
	menu_additem(gEditMenu, "Change Class(-)", "11");
	menu_additem(gEditMenu, "Change Type(+)", "12");
	menu_additem(gEditMenu, "Change Type(-)", "13");
	menu_additem(gEditMenu, "Rotate(+)", "14");
	menu_additem(gEditMenu, "Rotate(-)", "15");
	menu_additem(gEditMenu, "Exit", "100");
	menu_setprop(gEditMenu, MPROP_PERPAGE, 0);

	gMoveMenu = menu_create("Move Object", "mnuMove");
	menu_additem(gMoveMenu, "Move Forward", "0");
	menu_additem(gMoveMenu, "Move Back", "1");
	menu_additem(gMoveMenu, "Move Left", "2");
	menu_additem(gMoveMenu, "Move Right", "3");
	menu_additem(gMoveMenu, "Move Up", "4");
	menu_additem(gMoveMenu, "Move Down", "5");
	menu_additem(gMoveMenu, "Exit", "100");
	menu_setprop(gMoveMenu, MPROP_PERPAGE, 0);

	
	gInfoTarget = engfunc(EngFunc_AllocString, "info_target");
	
	get_configsdir(szDir, 64);
	add(szDir, 64, "/blocks", 0);
	if( !dir_exists(szDir) )
		mkdir(szDir);

	register_menucmd(register_menuid("Smart Menu:"), 1023, "old_menu_handler");

	get_mapname(szMap, 32);
	formatex(gFile, 96, "%s/%s.cfg", szDir, szMap);

	set_task(1.0, "look_check", 0, "", 0, "b");
}
public client_connect(id)
{
	Mover[id] = 16.0;
	PlayerGrab[id] = 0;
	PlayerNoClip[id] = 0;
	PlayerGodMode[id] = 0;
	PlayerSnap[id] = 1;
	PlayerSmartMode[id] = MODE_OLD;
	PlayerInSmart[id] = 0;
	PlayerSmartTele[id] = 0;
	PlayerSafeMove[id] = 1;
	LastAction[id] = AC_MAX;
}
public look_check()
{
	static players[32], pnum, i, id;
	static aiment, classname[6];
	poke_get_players(players, pnum, "c");
	for(i=0; i<pnum; i++)
	{
		id = players[i];
		get_user_aiming(id, aiment, classname[0]);
		if(ValidBox(id,aiment))
			blocks_print(id, print_center, "%s %s",classes[ BoxClass(aiment) ], blocks[ BoxType(aiment) ]);
		else if(ValidTele(id,aiment))
			blocks_print(id, print_center, "Teleport %s", TeleType(aiment) ? "Exit":"Entrance" );
	}
}

delete_course()
{
	new ent = 0;
	while( (ent = engfunc(EngFunc_FindEntityByString, ent, "classname", box_classname)) )
	{
		fm_remove_entity(ent);
	}
}
delete_teles()
{
	new ent = 0;
	while( (ent = engfunc(EngFunc_FindEntityByString, ent, "classname", tele_classname)) )
	{
		fm_remove_entity(ent);
	}
}

public plugin_precache()
{
	new i;
	for(i=0; i<TY_MAX; i++)
		precache_model( models[i] );
	for(i=0; i<TELE_MAX; i++)
		precache_model( telesprites[i] );
}

public plugin_cfg()
{
	readFile();
}

readFile()
{
	if( !file_exists(gFile) )
	{
		return;
	}

	delete_course();

	new szData[101]; /*S -9999.999999 -9999.999999 -9999.999999*/
	new szType[5], szX[13], szY[13], szZ[13], szType2[5], szRot[5];
	new box_type, box_type2, rotation;
	new Float:vOrigin[3];
	new f = fopen(gFile, "rt");
	while( !feof(f) )
	{
		fgets(f, szData, 100);
		parse(szData, szType, 4, szX, 12, szY, 12, szZ, 12, szType2, 4, szRot, 4);

		vOrigin[0] = str_to_float(szX);
		vOrigin[1] = str_to_float(szY);
		vOrigin[2] = str_to_float(szZ);

		box_type = str_to_num(szType);
		box_type2 = str_to_num(szType2);
		rotation = str_to_num(szRot);

		if( szType[0] == 'S' ){
			makeTele(0, TELE_IN, vOrigin);
		}
		else if( szType[0] == 'E' ){
			makeTele(0, TELE_OUT, vOrigin);
		}
		else if( box_type < BX_MAX && box_type >= 0 )
		{
			makeBox(0, box_type, vOrigin, box_type2, rotation);
		}
		else
		{
			log_amx("[BB] Invalid Building Block: ^"%s^" in: %s", szData, gFile);
		}
	}
	fclose(f);
}

public fwdTouch(ptr, ptd)
{
	if( !is_user_alive(ptd) )
	{
		return FMRES_IGNORED;
	}
	
	static szClassname[6];
	pev(ptr, pev_classname, szClassname, 5);
	if( !equal(szClassname, box_classname) )
	{
		if( equal(szClassname, tele_classname) )
		{
			if( TeleType(ptr) == TELE_IN ){
				new mate = TeleMate( ptr );
				if( pev_valid( mate ) ){
					new Float:mate_origin[3];
					set_pev(mate, pev_solid, SOLID_NOT);
					set_task(5.0,"solidify",mate);
					pev(mate, pev_origin, mate_origin);
					engfunc(EngFunc_SetOrigin, ptd, mate_origin);
					poke_UnStuck( ptd );
				}
			}
			else{
				set_pev(ptr, pev_solid, SOLID_NOT);
				set_task(5.0,"solidify",ptr);
			}
		}
		return FMRES_IGNORED;
	}

	if( get_pcvar_num( bb_noslowdown ) )
	{
		set_pev(ptd, pev_fuser2, 0.0);
	}

	switch( BoxClass(ptr) )
	{
		case BX_NORM, BX_GHOS:
		{
			if( !task_exists(ptr+TSK_UNSOLID) && !task_exists(ptr+TSK_SOLID) )
			{
				set_task(0.1, "tskUnsolid", ptr+TSK_UNSOLID);
			}
		}
		case BX_HEAL:
		{
			if( !task_exists(ptr+TSK_UNSOLID) )
			{
				static Float:maxhp, hp;
				pev(ptd, pev_max_health, maxhp);
				hp = get_user_health(ptd);
				if( hp < floatround( maxhp ) ){
					set_user_health(ptd, min(	hp + get_pcvar_num(bb_heal),
												floatround(maxhp) ) );

					fm_set_rendering(ptr, kRenderFxNone, 0, 0, 0, kRenderNormal, 16);
					set_task(1.0, "reglow", ptr+TSK_UNSOLID);
				}
			}
		}
		case BX_HURT:
		{
			if( !get_user_godmode(ptd) && !task_exists(ptr+TSK_UNSOLID) )
			{
				static set_hp;
				set_hp = max( get_user_health(ptd) - get_pcvar_num(bb_hurt), 0 );
				if( set_hp == 0 ){
					if( get_pcvar_num(bb_kill) == 1 )
						user_kill( ptd, 1 );
					else
						set_user_health(ptd, 1 );
				}
				else{
					set_user_health(ptd, set_hp );
					fm_set_rendering(ptr, kRenderFxNone, 0, 0, 0, kRenderNormal, 16);
					set_task(1.0, "reglow", ptr+TSK_UNSOLID);
				}
			}
		}
		case BX_BOOS:
		{
			pev( ptd, pev_velocity, nVelocity[ptd] );
			if(vector_length(nVelocity[ptd]) < 1000){
				nVelocity[ptd][0] *= BOOSTER;
				nVelocity[ptd][1] *= BOOSTER;
			}
			if(nVelocity[ptd][2] <= 0)
				nVelocity[ptd][2] = 10.0;
		}
		case BX_JUMP:
		{
			pev( ptd, pev_velocity, nVelocity[ptd] );
			nVelocity[ptd][2] = JUMPER;
		}
		case BX_TBLO:
		{
			if( Team(ptd)==2 && !task_exists(ptr+TSK_UNSOLID) && !task_exists(ptr+TSK_SOLID) )
			{
				set_task(0.1, "tskUnsolid", ptr+TSK_UNSOLID);
			}
		}
		case BX_CBLO:
		{
			if( Team(ptd)==1 && !task_exists(ptr+TSK_UNSOLID) && !task_exists(ptr+TSK_SOLID) )
			{
				set_task(0.1, "tskUnsolid", ptr+TSK_UNSOLID);
			}
		}
		case BX_DELA:
		{
			if( !task_exists(ptr+TSK_UNSOLID) && !task_exists(ptr+TSK_SOLID) )
			{
				set_task(1.0, "tskUnsolid", ptr+TSK_UNSOLID);
			}
		}
		case BX_THRO:
		{
			velocity_by_aim( ptd, THROWER, nVelocity[ptd] );
			nVelocity[ptd][2] = JUMPER;
		}
		case BX_ATHR:
		{
			velocity_by_aim( ptd, THROWER, nVelocity[ptd] );
			nVelocity[ptd][0] *= -1;
			nVelocity[ptd][1] *= -1;
			nVelocity[ptd][2] = JUMPER;
		}
		case BX_KILL:
		{
			if( !get_user_godmode( ptd ) ){
				if( get_pcvar_num(bb_kill) == 1 )
					user_kill( ptd, 1 );
				else
					set_user_health(ptd, 1 );
			}
		}
		case BX_REFL:
		{
			new Float:origin[3], Float:oFar[3], Float:oRetNormal[3];
			pev(ptd, pev_velocity, nVelocity[ptd]);
			pev(ptd, pev_origin, origin);
			oFar[0] = origin[0] + (nVelocity[ptd][0] * 8192.0);
			oFar[1] = origin[1] + (nVelocity[ptd][1] * 8192.0);
			oFar[2] = origin[2] + (nVelocity[ptd][2] * 8192.0);
			fm_trace_normal(ptd, origin, oFar, oRetNormal);
			nVelocity[ptd][0] = -2.0 * (nVelocity[ptd][0]*oRetNormal[0])*oRetNormal[0] + nVelocity[ptd][0];
			nVelocity[ptd][1] = -2.0 * (nVelocity[ptd][1]*oRetNormal[1])*oRetNormal[1] + nVelocity[ptd][1];
			nVelocity[ptd][2] = -2.0 * (nVelocity[ptd][2]*oRetNormal[2])*oRetNormal[2] + nVelocity[ptd][2];
		}
	}
	
	return FMRES_IGNORED;
}
public reglow(taskid)
{
	taskid -= TSK_UNSOLID;
	glow_box(taskid, BoxClass(taskid) );
}

public PlayerPreThink(id)
{
	if( is_user_alive(id) ){
		if(	nVelocity[id][0] != 0.0
		||	nVelocity[id][1] != 0.0
		||	nVelocity[id][2] != 0.0
		){
			set_pev(id, pev_velocity, nVelocity[id]);
			nVelocity[id][0] = 0.0;
			nVelocity[id][1] = 0.0;
			nVelocity[id][2] = 0.0;
		}

		//taken straight from blockmaker

		//trace directly down to see if there is a block beneath player
		static Float:pOrigin[3], Float:pSize[3], Float:pMaxs[3], Float:vTrace[3], Float:vReturn[3], ent, i;
		pev(id, pev_origin, pOrigin);
		pev(id, pev_size, pSize);
		pev(id, pev_maxs, pMaxs);

		//calculate position of players feet
		pOrigin[2] = pOrigin[2] - ((pSize[2] - 36.0) - (pMaxs[2] - 36.0));

		//make the trace longer for other blocks
		vTrace[2] = pOrigin[2] - 20.0;

		static szClassname[6];
		//do 4 traces for each corner of the player
		for ( i = 0; i < 4; i++ )
		{
			switch (i)
			{
				case 0: { vTrace[0] = pOrigin[0] - 18; vTrace[1] = pOrigin[1] + 18; }
				case 1: { vTrace[0] = pOrigin[0] + 18; vTrace[1] = pOrigin[1] + 18; }
				case 2: { vTrace[0] = pOrigin[0] + 18; vTrace[1] = pOrigin[1] - 18; }
				case 3: { vTrace[0] = pOrigin[0] - 18; vTrace[1] = pOrigin[1] - 18; }
			}
			
			ent = fm_trace_line(id, pOrigin, vTrace, vReturn);
			pev(ent, pev_classname, szClassname, 5);
			
			if (equal(szClassname, box_classname)){
				switch( BoxClass(ent) )
				{
					case BX_JUMP, BX_WATE, BX_THRO, BX_BOOS, BX_ATHR:
						NoFall[id] = true;
					case BX_ICE:
						pev(id, pev_velocity, nVelocity[id]);
					case BX_STIC:{
						pev(id, pev_velocity, nVelocity[id]);
						if( floatabs( nVelocity[id][0] ) > STICK )
							nVelocity[id][0] /= 2;
						if( floatabs( nVelocity[id][1] ) > STICK )
							nVelocity[id][1] /= 2;
					}
				}
			}
		}
	}

	if( is_user_connected(id) ){
		if( PlayerInSmart[id] && PlayerSmartMode[id] == MODE_SMART ){
			static button, old_button;
			button = pev(id, pev_button);
			old_button = pev(id, pev_oldbuttons);

			if (button & IN_ATTACK && !(old_button & IN_ATTACK)){
				if( pev_valid( PlayerGrab[id] ) ){
					pev( PlayerGrab[id], pev_origin, nVelocity[id] );
					if( PlayerSmartTele[id] )
						makeTele(id, ValidTele( id, PlayerTeleport[id] ) ? TELE_OUT : TELE_IN, nVelocity[id]);
					else
						makeBox(id, BoxClass(PlayerGrab[id]), nVelocity[id], BoxType(PlayerGrab[id]), BoxRot(PlayerGrab[id]));
					nVelocity[id][0] = 0.0;
					nVelocity[id][1] = 0.0;
					nVelocity[id][2] = 0.0;
				}
				else
					if( PlayerSmartTele[id] )
						makeTele(id, ValidTele( id, PlayerTeleport[id] ) ? TELE_OUT : TELE_IN);
					else
						makeBox(id, PlayerBoxClass[id], _, PlayerBoxType[id]);
			}
			else if (button & IN_ATTACK2 && !(old_button & IN_ATTACK2)){
				destroy_aim( id, PlayerGrab[id] );
			}
			else if (button & IN_RELOAD && !(old_button & IN_RELOAD)){
				PlayerSmartTele[id] = !PlayerSmartTele[id];
				show_main_menu(id);
			}

			else if( pev_valid( PlayerGrab[id] ) ){
				if (button & IN_JUMP  && !(old_button & IN_JUMP)){
					if (gGrablength[id] > 72)
						gGrablength[id] -= 16;
				}
				else if (button & IN_DUCK && !(old_button & IN_DUCK)){
					gGrablength[id] += 16;
				}
				else
					moveBox( id, -1, PlayerGrab[id] );
			}
		}
		else if( pev_valid( PlayerGrab[id] ) )
			moveBox( id, -1, PlayerGrab[id] );
	}
}
public PlayerPostThink(id)
{
	if(is_user_alive(id)){
		if(NoFall[id]){
			set_pev(id, pev_watertype, -3);
			NoFall[id] = false;
		}
	}
}

public tskUnsolid(taskid)
{
	taskid -= TSK_UNSOLID;
	set_pev(taskid, pev_solid, SOLID_NOT);
	fm_set_rendering(taskid, kRenderFxNone, 0, 0, 0, kRenderTransAdd, 100);
	set_task(1.0, "tskSolid", taskid+TSK_SOLID);
}

public tskSolid(taskid)
{
	taskid -= TSK_SOLID;
	solidify(taskid);
	glow_box(taskid, BoxClass(taskid) );
}
public solidify(ent)
	if(pev_valid(ent))	set_pev(ent, pev_solid, SOLID_BBOX);

public cmdBhopMenu(id, level, cid)
{
	if( !cmd_access(id, level, cid, 1) )
	{
		return PLUGIN_HANDLED;
	}

	show_main_menu( id );
	
	return PLUGIN_HANDLED;
}

show_main_menu( id )
{
	if( PlayerSmartMode[id] == MODE_OLD )
		menu_display(id, gBhopMenu, 0);
	else{
		PlayerInSmart[id] = 1;
		smart_menu( id );
	}
}
public delayed_show( id )
	show_main_menu( id-TSK_SHOW );

smart_menu( id )
{
	new menu_body[512], len, keys;
	len += copy(menu_body[len], (511-len),			"Smart Menu:^n");
	len += copy(menu_body[len], (511-len),			"^n");
	len += copy(menu_body[len], (511-len),			"Left Click to Create^n");
	len += copy(menu_body[len], (511-len),			"Right Click to Delete^n");
	len += copy(menu_body[len], (511-len),	 		"Duck/Jump to move Further/Closer^n");
	len += formatex(menu_body[len], (511-len),	 	"Reload to switch to %s^n",		PlayerSmartTele[id]?"Blocks":"Teleports");
	len += copy(menu_body[len], (511-len),			"^n");
	if(PlayerSmartTele[id]){
		len += formatex(menu_body[len], (511-len),	"Creating Teleport %s^n",		pev_valid(PlayerTeleport[id])?"Exit":"Entrance");
		len += copy(menu_body[len], (511-len),		"^n");
		len += copy(menu_body[len], (511-len),		"5. Move Object^n");
		keys |= MENU_KEY_5;
	}
	else{
		len += formatex(menu_body[len], (511-len),	"Creating %s %s^n",				classes[PlayerBoxClass[id]],blocks[PlayerBoxType[id]]);
		len += copy(menu_body[len], (511-len),		"1. Box Type(+)^n");
		len += copy(menu_body[len], (511-len),		"2. Box Type(-)^n");
		len += copy(menu_body[len], (511-len),		"3. Box Class(+)^n");
		len += copy(menu_body[len], (511-len),		"4. Box Class(-)^n");
		len += copy(menu_body[len], (511-len),		"5. Edit Object^n");
		keys |= MENU_KEY_1|MENU_KEY_2|MENU_KEY_3|MENU_KEY_4|MENU_KEY_5;
	}
	len += formatex(menu_body[len], (511-len),		"6. %s Object^n",				PlayerGrab[id]?"Release":"Grab");
	len += copy(menu_body[len], (511-len),			"7. Settings^n");
	len += copy(menu_body[len], (511-len),			"8. Advanced^n");
	len += copy(menu_body[len], (511-len),			"9. Old Style^n");
	len += copy(menu_body[len], (511-len),			"0. Exit");
	show_menu(id, keys|MENU_KEY_5|MENU_KEY_6|MENU_KEY_7|MENU_KEY_8|MENU_KEY_9|MENU_KEY_0, menu_body, -1, "Smart Menu:");
}

public mnuBhop(id, menu, item)
{
	new szCmd[4],  _trash;
	menu_item_getinfo(menu, item, _trash, szCmd, 3, "", 0, _trash);
	
	if( item == MENU_EXIT )
	{
		PlayerGrab[id] = 0;
		return PLUGIN_HANDLED;
	}

	switch( str_to_num(szCmd) )
	{
		case 1: 
		{
			if( !just_duplicated(id) )
				menu_display(id, gCreateMenu, 0);
			return PLUGIN_HANDLED;
		}
		case 2:
		{
			menu_display(id, gEditMenu, 0);
			return PLUGIN_HANDLED;
		}
		case 3:
		{
			if( just_duplicated(id) )
				return PLUGIN_HANDLED;

			new ent;
			get_user_aiming(id, ent, _trash);
			
			if( ValidBox(id, ent, "You must aim at a box to duplicate it!") )
			{
				new Float:origin[3];
				pev(ent, pev_origin, origin);
				makeBox(0, BoxClass(ent), origin, BoxType(ent), BoxRot(ent));
				blocks_print(id, print_chat, "Object duplicated!");
				LastAction[id] = AC_DUP;
			}
			menu_display(id, gEditMenu, 0);
			return PLUGIN_HANDLED;
		}
		case 4:
		{
			grab( id );
		}
		case 5:
		{
			destroy_aim(id);
		}
		case 6:
		{
			menu_display(id, gSetMenu, 0);
			return PLUGIN_HANDLED;
		}
		case 7:
		{
			menu_display(id, gAdvMenu, 0);
			return PLUGIN_HANDLED;
		}
		case 8:
		{
			PlayerSmartMode[id] = !PlayerSmartMode[id];
			blocks_print(id, print_chat, "Menu Mode : %s", PlayerSmartMode[id] ? "Smart Menu" : "Old Style" );
			show_main_menu( id );
			return PLUGIN_HANDLED;
		}
		case 9:
		{
			makeTele(id, ValidTele( id, PlayerTeleport[id] ) ? TELE_OUT : TELE_IN);
		}
		case 100:
		{
			PlayerGrab[id] = 0;
			return PLUGIN_HANDLED;
		}
	}
	
	show_main_menu( id );
	
	return PLUGIN_HANDLED;
}
just_duplicated(id)
{
	if(LastAction[id]==AC_DUP){
		blocks_print(id, print_chat, "Please move the box you just duplicated.");
		menu_display(id, gEditMenu, 0);
		return true;
	}
	return false;
}
public mnuAdv(id, menu, item)
{
	new szCmd[4],  _trash;
	menu_item_getinfo(menu, item, _trash, szCmd, 3, "", 0, _trash);
	
	if( item == MENU_EXIT )
	{
		show_main_menu( id );
		return PLUGIN_HANDLED;
	}
	
	switch( str_to_num(szCmd) )
	{
		case 1:
		{
			delete_course();
			blocks_print(id, print_chat, "All blocks have been deleted!");
		}
		case 2:
		{
			delete_teles();
			blocks_print(id, print_chat, "All teleports have been deleted!");
		}
		case 3:
		{
			readFile();
			blocks_print(id, print_chat, "File read successful!");
		}
		case 4:
		{
			save_course(id);
		}
		case 5:
		{
			new ent, ent2, Float:vOrigin[3], Float:vOrigin2[3], copy_count;
			ent = 0;
			while( (ent = engfunc(EngFunc_FindEntityByString, ent, "classname", box_classname)) )
			{
				pev(ent, pev_origin, vOrigin);

				ent2 = 0;
				while( (ent2 = engfunc(EngFunc_FindEntityByString, ent2, "classname", box_classname)) )
				{
					if( ent == ent2 )
						continue;

					pev(ent2, pev_origin, vOrigin2);

					if(	vOrigin[0] == vOrigin2[0]
					&&	vOrigin[1] == vOrigin2[1]
					&&	vOrigin[2] == vOrigin2[2]
					&&	BoxRot(ent) == BoxRot(ent2)
					){
						fm_remove_entity(ent2);
						copy_count++;
					}
				}
			}
			if( copy_count )
				blocks_print(id, print_chat, "Deleted %d blocks with similar origins.",copy_count);
			else
				blocks_print(id, print_chat, "There are no blocks with similar origins.");
		}
	}
	
	menu_display(id, gAdvMenu, 0);
	
	return PLUGIN_HANDLED;
}
public mnuSet(id, menu, item)
{
	new szCmd[4],  _trash;
	menu_item_getinfo(menu, item, _trash, szCmd, 3, "", 0, _trash);
	
	if( item == MENU_EXIT )
	{
		show_main_menu( id );
		return PLUGIN_HANDLED;
	}
	
	switch( str_to_num(szCmd) )
	{
		case 1: 
		{
			Mover[id] += 1.0;
			blocks_print(id, print_center, "Moving objects %.1f units.", Mover[id]);
		}
		case 2: 
		{
			Mover[id] -= 1.0;
			blocks_print(id, print_center, "Moving objects %.1f units.", Mover[id]);
		}
		case 3: 
		{
			PlayerGodMode[id] = !PlayerGodMode[id];
			task_godmode( id );
			blocks_print(id, print_chat, "Godmode %s", PlayerGodMode[id] ? Enabled : Disabled);
		}
		case 4: 
		{
			PlayerNoClip[id] = !PlayerNoClip[id];
			task_noclip( id );
			blocks_print(id, print_chat, "No-Clip %s", PlayerNoClip[id] ? Enabled : Disabled);
		}
		case 5: 
		{
			PlayerSnap[id] = !PlayerSnap[id];
			blocks_print(id, print_chat, "Snapping %s", PlayerSnap[id] ? Enabled : Disabled);
		}
		case 6: 
		{
			PlayerSafeMove[id] = !PlayerSafeMove[id];
			blocks_print(id, print_chat, "Safe Creating/Moving %s", PlayerSafeMove[id] ? "Enabled. Blocks can't be created/moved out of your sight." : Disabled);
		}
		case 100:
		{
			show_main_menu( id );
			return PLUGIN_HANDLED;
		}
	}
	
	menu_display(id, gSetMenu, 0);
	
	return PLUGIN_HANDLED;
}
public task_godmode(id)
{
	set_user_godmode( id, PlayerGodMode[id] );
	if( PlayerGodMode[id] ){
		set_task( TASK_CHECK, "task_godmode", id);
	}
}
public task_noclip(id)
{
	set_user_noclip( id, PlayerNoClip[id] );
	if( PlayerNoClip[id] ){
		set_task( TASK_CHECK, "task_noclip", id);
	}
}

public old_menu_handler(id, key)
{
	key++;
	if(key==10){
		PlayerInSmart[id] = 0;
		PlayerGrab[id] = 0;
		remove_task(id+TSK_SHOW);
		return;
	}

	PlayerInSmart[id] = 0;
	remove_task(id+TSK_SHOW);
	switch( key )
	{
		case 1: 
		{
			PlayerBoxType[id]++;
			if(PlayerBoxType[id] == TY_MAX)
				PlayerBoxType[id] = 0;
		}
		case 2:
		{
			PlayerBoxType[id]--;
			if(PlayerBoxType[id] == -1)
				PlayerBoxType[id] = TY_MAX-1;
		}
		case 3: 
		{
			PlayerBoxClass[id]++;
			if(PlayerBoxClass[id] == BX_MAX)
				PlayerBoxClass[id] = 0;
		}
		case 4: 
		{
			PlayerBoxClass[id]--;
			if(PlayerBoxClass[id] == -1)
				PlayerBoxClass[id] = BX_MAX-1;
		}
		case 5: 
		{
			if( PlayerSmartTele[id] )
				menu_display(id, gMoveMenu, 0);
			else
				menu_display(id, gEditMenu, 0);
			return;
		}
		case 6:
		{
			grab( id );
		}
		case 7:
		{
			menu_display(id, gSetMenu, 0);
			return;
		}
		case 8:
		{
			menu_display(id, gAdvMenu, 0);
			return;
		}
		case 9: 
		{
			PlayerSmartMode[id] = !PlayerSmartMode[id];
			blocks_print(id, print_chat, "Menu Mode : %s", PlayerSmartMode[id] ? "Smart Menu" : "Old Style" );
			show_main_menu( id );
			return;
		}
	}
	show_main_menu( id );
	set_task(10.0,"delayed_show", id+TSK_SHOW, "", 0, "b");
}

public grab_command(id)
{
	if( !(get_user_flags(id) & ADMIN_BLOCKS) ){
		console_print(id, "You have no access to that command.");
		return PLUGIN_HANDLED;
	}

	new cmd[5];
	read_argv(0,cmd,4);
	if(	cmd[0] == '+' && !pev_valid( PlayerGrab[id] )
	||	cmd[0] == '-' && pev_valid( PlayerGrab[id] ) )
		grab(id);
	return PLUGIN_HANDLED;
}
grab(id)
{
	if( pev_valid( PlayerGrab[id]) ){
		if( ValidBox(id, PlayerGrab[id]) )
			blocks_print(id, print_chat, "Block Released.");
		else if( ValidTele(id, PlayerGrab[id]) )
			blocks_print(id, print_chat, "Teleport Released.");
		PlayerGrab[id] = 0;
	}
	else {
		new ent, _trash;
		gGrablength[id] = floatround( get_user_aiming(id, ent, _trash) );

		if( ValidTele(id, ent) )
		{
			PlayerGrab[id] = ent;
			blocks_print(id, print_chat, "Grabbed a Teleport.");
			LastAction[id] = AC_MOV;
		}
		else if( ValidBox(id, ent, "You must aim at a box to grab it!") )
		{
			PlayerGrab[id] = ent;
			blocks_print(id, print_chat, "Grabbed a %s %s."
			, classes[ (PlayerBoxClass[id] = BoxClass(ent)) ]
			, blocks[ (PlayerBoxType[id] = BoxType(ent)) ]);
			LastAction[id] = AC_MOV;
		}
	}
}

public mnuCreate(id, menu, item)
{
	new szCmd[4],  _trash;
	menu_item_getinfo(menu, item, _trash, szCmd, 3, "", 0, _trash);
	
	if( item == MENU_EXIT )
	{
		show_main_menu( id );
		return PLUGIN_HANDLED;
	}

	PlayerBoxType[id] = str_to_num(szCmd);
	menu_display(id, gCreateMenu2, 0);
	
	return PLUGIN_HANDLED;
}
public mnuCreate2(id, menu, item)
{
	new szCmd[4],  _trash;
	menu_item_getinfo(menu, item, _trash, szCmd, 3, "", 0, _trash);
	
	if( item == MENU_EXIT )
	{
		show_main_menu( id );
		return PLUGIN_HANDLED;
	}
	
	new box_class = str_to_num(szCmd);
	makeBox(id, box_class, _, PlayerBoxType[id]);
	LastAction[id] = AC_CRE;

	menu_display(id, gCreateMenu2, box_class/7);
	
	return PLUGIN_HANDLED;
}
public mnuEdit(id, menu, item)
{
	new szCmd[5],  _trash, key;
	menu_item_getinfo(menu, item, _trash, szCmd, 4, "", 0, _trash);
	
	if( item == MENU_EXIT )
	{
		show_main_menu( id );
		return PLUGIN_HANDLED;
	}
	key = str_to_num(szCmd);
	switch( key )
	{
		case 1:
		{
			menu_display(id, gMoveMenu, 0);
			return PLUGIN_HANDLED;
		}

		case 12,13:
		{
			new ent;
			get_user_aiming(id, ent, _trash);
			
			if( ValidBox(id, ent, "You must aim at a box to change it!") )
			{
				new new_class = BoxType(ent);
				if( key == 12 ){
					new_class++;
					if(new_class == TY_MAX)
						new_class = 0;
				}
				else{
					new_class--;
					if(new_class == -1)
						new_class = TY_MAX-1;
				}
				SetBoxType(ent, new_class);
				look_check();
				model_box(ent, new_class);
				movetype_box(ent, new_class);
				glow_box(ent, BoxClass(ent));
			}
		}
		case 10,11:
		{
			new ent;
			get_user_aiming(id, ent, _trash);

			if( ValidBox(id, ent, "You must aim at a box to change it!") )
			{
				new new_class = BoxClass(ent);
				if( key == 10 ){
					new_class++;
					if(new_class == BX_MAX)
						new_class = 0;
				}
				else{
					new_class--;
					if(new_class == -1)
						new_class = BX_MAX-1;
				}
				SetBoxClass(ent, new_class);
				look_check();
				glow_box(ent, new_class);
				update_solid(ent, new_class);
			}
		}
		case 14,15:
		{
			new ent;
			get_user_aiming(id, ent, _trash);

			if( ValidBox(id, ent, "You must aim at a box to change it!") )
			{
				new new_rot = BoxRot(ent);
				new box_type = BoxType(ent);
				new type_rot_add = TypeRot( box_type );
				if( !type_rot_add ){
					blocks_print(id, print_chat, "You cannot rotate %s boxes.", blocks[ box_type ] );
				}
				else{
					if( key == 14 ){
						new_rot += type_rot_add;
						if(new_rot >= ROT_MAX)
							new_rot = 0;
					}
					else{
						new_rot -= type_rot_add;
						if(new_rot <= -1)
							new_rot = ROT_MAX-1;
					}
					SetBoxRot(ent, new_rot);
					rotate_box(ent, new_rot);
				}
			}
		}
		case 100:
		{
			show_main_menu( id );
			return PLUGIN_HANDLED;
		}
	}
	
	LastAction[id] = AC_MOV;
	menu_display(id, gEditMenu, 0);
	
	return PLUGIN_HANDLED;
}
public mnuMove(id, menu, item)
{
	new szCmd[5],  _trash, key;
	menu_item_getinfo(menu, item, _trash, szCmd, 4, "", 0, _trash);
	
	if( item == MENU_EXIT )
	{
		show_main_menu( id );
		return PLUGIN_HANDLED;
	}
	key = str_to_num(szCmd);
	switch( key )
	{
		case 0..5:
		{
			moveBox(id, key);
		}

		case 100:
		{
			show_main_menu( id );
			return PLUGIN_HANDLED;
		}
	}

	LastAction[id] = AC_MOV;
	menu_display(id, gMoveMenu, 0);
	
	return PLUGIN_HANDLED;
}

save_course(id)
{
	if( file_exists(gFile) )
	{
		delete_file(gFile);
	}

	new ent, Float:vOrigin[3], szData[101];
	new bool:opened = false;
	new f, mate;
	new block_count[TY_MAX];
	new tele_count;
	ent = 0;
	while( (ent = engfunc(EngFunc_FindEntityByString, ent, "classname", box_classname)) )
	{
		if(!opened){
			f = fopen(gFile, "at");
			opened = true;
		}
		pev(ent, pev_origin, vOrigin);

		formatex(szData, 100, "%d %0.1f %0.1f %0.1f %d %d^n",
		BoxClass(ent), vOrigin[0], vOrigin[1], vOrigin[2], BoxType(ent), BoxRot(ent) );
		fputs(f, szData);

		block_count[ BoxType(ent) ]++;
	}
	while( (ent = engfunc(EngFunc_FindEntityByString, ent, "classname", tele_classname)) )
	{
		if( TeleType( ent ) == TELE_OUT )
			continue;

		mate = TeleMate( ent );
		if( !pev_valid( mate ) )
			continue;

		if(!opened){
			f = fopen(gFile, "at");
			opened = true;
		}

		pev(ent, pev_origin, vOrigin);
		formatex(szData, 100, "S %0.1f %0.1f %0.1f^n", vOrigin[0], vOrigin[1], vOrigin[2] );
		fputs(f, szData);

		pev(mate, pev_origin, vOrigin);
		formatex(szData, 100, "E %0.1f %0.1f %0.1f^n", vOrigin[0], vOrigin[1], vOrigin[2] );
		fputs(f, szData);

		tele_count++;
	}

	if(opened){
		new ilen = 0, blockmsg[256];
		for(ent = 0; ent < TY_MAX; ent++)
			if(block_count[ent])
				ilen += formatex( blockmsg[ilen], (256-ilen), " %d %s.", block_count[ent], blocks[ent]);
		if( tele_count )
			ilen += formatex( blockmsg[ilen], (256-ilen), " %d Teleports.", tele_count);
		blocks_print(id, print_chat, "File Writen Successful!%s",blockmsg);
		fclose(f);
	}
	else
		blocks_print(id, print_chat, "Empty File Writen Successful!");
}

makeBox(id, const box_class, Float:pOrigin[3]={0.0,0.0,0.0}, const box_type, const box_rot=0)
{
	new ent = engfunc(EngFunc_CreateNamedEntity, gInfoTarget);

	if( !pev_valid(ent) )
		return PLUGIN_HANDLED;

	set_pev(ent, pev_classname, box_classname);
	SetBoxClass(ent, box_class);
	SetBoxType(ent, box_type);
	SetBoxRot(ent, box_rot);

	glow_box(ent, box_class);
	update_solid(ent, box_class);

	movetype_box(ent, box_type);
	model_box(ent, box_type);

	rotate_box(ent, box_rot);

	if( id
	&& pOrigin[0] == 0.0
	&& pOrigin[1] == 0.0
	&& pOrigin[2] == 0.0 )
	{
		new origin[3];
		get_user_origin(id, origin, 3);
		IVecFVec(origin, pOrigin);
		pOrigin[2] += 16;
		doSnapping( id, ent, pOrigin );
		engfunc(EngFunc_SetOrigin, ent, pOrigin);
	}
	else
	{
		engfunc(EngFunc_SetOrigin, ent, pOrigin);
	}

	if( box_type == TY_CHICK )
	{
		new Float:rand_vec[3];
		rand_vec[1] = random_float(0.0, 360.0);
		set_pev(ent, pev_angles, rand_vec);
		set_pev(ent, pev_v_angle, rand_vec);
	}

	glow_box(ent, box_class);

	if( !PlayerInSmart[id] && PlayerSafeMove[id] && !fm_is_ent_visible( id, ent ) ){
		blocks_print(id, print_center, "You cannot create blocks out of your sight.");
		fm_remove_entity(ent);
	}

	return PLUGIN_HANDLED;
}
makeTele(id, const tele_type, Float:pOrigin[3]={0.0,0.0,0.0})
{
	new ent = engfunc(EngFunc_CreateNamedEntity, gInfoTarget);

	if( !pev_valid(ent) )
		return PLUGIN_HANDLED;

	set_pev(ent, pev_classname, tele_classname);
	SetTeleType(ent, tele_type);

	switch( tele_type )
	{
		case TELE_IN:{
			if( ValidTele(id, PlayerTeleport[id]) ){
				fm_remove_entity( PlayerTeleport[id] );
				return PLUGIN_HANDLED;
			}
			PlayerTeleport[id] = ent;
		}
		case TELE_OUT:{
			if( !ValidTele(id, PlayerTeleport[id]) ){
				fm_remove_entity( ent );
				return PLUGIN_HANDLED;
			}
			SetTeleMate(ent, PlayerTeleport[id]);
			SetTeleMate(PlayerTeleport[id], ent);
			PlayerTeleport[id] = 0;
		}
	}

	set_pev(ent, pev_solid, SOLID_BBOX);
	set_pev(ent, pev_movetype, MOVETYPE_NONE);
	engfunc(EngFunc_SetModel, ent, telesprites[tele_type]);
	set_pev(ent, pev_rendermode, 5);
	set_pev(ent, pev_renderamt, 255.0);
	engfunc(EngFunc_SetSize, ent, telesize[0], telesize[1]);
	teleport_frame( ent );

	if( id
	&& pOrigin[0] == 0.0
	&& pOrigin[1] == 0.0
	&& pOrigin[2] == 0.0 )
	{
		new origin[3];
		get_user_origin(id, origin, 3);
		IVecFVec(origin, pOrigin);
		pOrigin[2] += 16;
		engfunc(EngFunc_SetOrigin, ent, pOrigin);
	}
	else
	{
		engfunc(EngFunc_SetOrigin, ent, pOrigin);
	}

	if( !PlayerInSmart[id] && PlayerSafeMove[id] && !fm_is_ent_visible( id, ent ) ){
		blocks_print(id, print_center, "You cannot create teleports out of your sight.");
		fm_remove_entity(ent);
	}

	return PLUGIN_HANDLED;
}
public teleport_frame( ent )
{
	if( pev_valid(ent) ){
		new Float:current_frame;
		pev(ent, pev_frame, current_frame);
		if (current_frame < 0 || current_frame >= TELE_FRAMES )
			set_pev(ent, pev_frame, 1.0);
		else
			set_pev(ent, pev_frame, current_frame + 1 );
		set_task(0.1, "teleport_frame", ent );
	}
}
glow_box(ent, box_class)
{
	if(colors[box_class][0]==-1)
		fm_set_rendering(ent, kRenderFxNone, 0, 0, 0, kRenderTransAdd, 100);
	else
		fm_set_rendering(ent, kRenderFxGlowShell, colors[box_class][0],  colors[box_class][1],  colors[box_class][2], kRenderNormal, 16);
}
model_box(ent, box_class)
{
	engfunc(EngFunc_SetModel, ent, models[box_class]);
}
movetype_box(ent, box_type)
{
	if(box_type == TY_CHICK){
		set_pev(ent, pev_movetype, MOVETYPE_TOSS);
		set_task(0.1,"bounce_chick",ent);
	}
	else{
		remove_task(TSK_CHICK+ent);
		set_pev(ent, pev_movetype, MOVETYPE_NONE);
	}
}
rotate_box(ent, box_rot)
{
	new Float:box_size[2][3], box_type = BoxType(ent);
	new Float:box_angles[3];
	switch(box_rot)
	{
		case 0:{
			//angles
			box_angles[0] = 0.0;
			box_angles[1] = 0.0;
			box_angles[2] = 0.0;
			//mins
			box_size[0][0] = sizes[box_type][0][0];
			box_size[0][1] = sizes[box_type][0][1];
			box_size[0][2] = sizes[box_type][0][2];
			//maxs
			box_size[1][0] = sizes[box_type][1][0];
			box_size[1][1] = sizes[box_type][1][1];
			box_size[1][2] = sizes[box_type][1][2];
		}
		case 1:{
			//angles
			box_angles[0] = 0.0;
			box_angles[1] = 90.0;
			box_angles[2] = 0.0;
			//mins
			box_size[0][0] = sizes[box_type][0][1];
			box_size[0][1] = sizes[box_type][0][0];
			box_size[0][2] = sizes[box_type][0][2];
			//maxs
			box_size[1][0] = sizes[box_type][1][1];
			box_size[1][1] = sizes[box_type][1][0];
			box_size[1][2] = sizes[box_type][1][2];
		}
		case 2:{//
			//angles
			box_angles[0] = 0.0;
			box_angles[1] = 180.0;
			box_angles[2] = 90.0;
			//mins
			box_size[0][0] = sizes[box_type][0][0];
			box_size[0][1] = sizes[box_type][0][2];
			box_size[0][2] = sizes[box_type][0][1];
			//maxs
			box_size[1][0] = sizes[box_type][1][0];
			box_size[1][1] = sizes[box_type][1][2];
			box_size[1][2] = sizes[box_type][1][1];
		}
		case 3:{
			//angles
			box_angles[0] = -90.0;
			box_angles[1] = 90.0;
			box_angles[2] = 0.0;
			//mins
			box_size[0][0] = sizes[box_type][0][1];
			box_size[0][1] = sizes[box_type][0][2];
			box_size[0][2] = sizes[box_type][0][0];
			//maxs
			box_size[1][0] = sizes[box_type][1][1];
			box_size[1][1] = sizes[box_type][1][2];
			box_size[1][2] = sizes[box_type][1][0];
		}
		case 4:{
			//angles
			box_angles[0] = -90.0;
			box_angles[1] = 0.0;
			box_angles[2] = 0.0;
			//mins
			box_size[0][0] = sizes[box_type][0][2];
			box_size[0][1] = sizes[box_type][0][1];
			box_size[0][2] = sizes[box_type][0][0];
			//maxs
			box_size[1][0] = sizes[box_type][1][2];
			box_size[1][1] = sizes[box_type][1][1];
			box_size[1][2] = sizes[box_type][1][0];
		}
		case 5:{
			//angles
			box_angles[0] = 0.0;
			box_angles[1] = 90.0;
			box_angles[2] = 90.0;
			//mins
			box_size[0][0] = sizes[box_type][0][2];
			box_size[0][1] = sizes[box_type][0][0];
			box_size[0][2] = sizes[box_type][0][1];
			//maxs
			box_size[1][0] = sizes[box_type][1][2];
			box_size[1][1] = sizes[box_type][1][0];
			box_size[1][2] = sizes[box_type][1][1];
		}
	}
	set_pev(ent, pev_angles, box_angles);
	set_pev(ent, pev_v_angle, box_angles);
	engfunc(EngFunc_SetSize, ent, box_size[0], box_size[1]);
}
update_solid(ent, box_class)
{
	if(box_class != BX_MAX)
		set_pev(ent, pev_solid, SOLID_BBOX);
}
public bounce_chick(ent)
{
	if(pev_valid(ent) && BoxType(ent)==TY_CHICK){
		if(pev(ent, pev_flags)&FL_ONGROUND){
			new Float:velocity[3];
			velocity[2] = CHICK_JUMP;
			set_pev(ent, pev_velocity, velocity);
		}
		set_task(0.1,"bounce_chick",ent);
	}
}

moveBox(id, mode, ent=0)
{
	if( !ent ){
		new body;
		get_user_aiming(id, ent, body);
		if( !ValidBox(id, ent, "You must aim at an object to move.") )
			return;
	}

	static Float:vOrigin[3], Float:original[3];
	pev(ent, pev_origin, original);
	vOrigin[0] = original[0];
	vOrigin[1] = original[1];
	vOrigin[2] = original[2];
	
	switch( mode )
	{
		case 0..5:
		{
			if( !is_num_odd(mode) )		vOrigin[mode/2] += Mover[id];
			else						vOrigin[mode/2] -= Mover[id];
		}
		case -1:
		{
			static eye_pos[3], Float:velocity[3];

			get_user_origin( id, eye_pos, 1);
			IVecFVec( eye_pos, vOrigin );
			velocity_by_aim(id, gGrablength[id], velocity);

			vOrigin[0] += velocity[0];
			vOrigin[1] += velocity[1];
			vOrigin[2] += velocity[2];
		}
	}

	doSnapping( id, ent, vOrigin );
	engfunc(EngFunc_SetOrigin, ent, vOrigin);

	if( PlayerSafeMove[id] && !fm_is_ent_visible( id, ent ) ){
		blocks_print(id, print_center, "You cannot move the block out of your sight.");
		engfunc(EngFunc_SetOrigin, ent, original);
	}
}

destroy_aim(id, ent=0)
{
	if( !ent ){
		new body;
		get_user_aiming(id, ent, body);
	}

	new i;
	if( ValidTele(id, ent) )
	{
		LastAction[id] = AC_MOV;
		new mate = TeleMate(ent);
		if( pev_valid( mate ) ){
			blocks_print(id, print_center, "Teleport Entrance and Exit destroyed!");
			for( i=1; i<=MAX_PLAYERS; i++ )
				if( PlayerGrab[i] == mate ){
					PlayerGrab[i] = 0;
					show_main_menu( i );
				}
			fm_remove_entity(mate);
		}
		else
			blocks_print(id, print_center, "Teleport Entrance destroyed!");
		fm_remove_entity(ent);

		for( i=1; i<=MAX_PLAYERS; i++ )
			if( PlayerGrab[i] == ent ){
				PlayerGrab[i] = 0;
				show_main_menu( i );
			}
	}
	else if( ValidBox(id, ent, "You must aim at an object to destroy it!") )
	{
		LastAction[id] = AC_MOV;
		fm_remove_entity(ent);
		blocks_print(id, print_center, "Object destroyed!");

		for( i=1; i<=MAX_PLAYERS; i++ )
			if( PlayerGrab[i] == ent ){
				PlayerGrab[i] = 0;
				show_main_menu( i );
			}
	}
}

ValidBox(const id, const ent, const msg[]="")
{
	if( pev_valid(ent) )
	{
		new szClassname[6];
		pev(ent, pev_classname, szClassname, 5);
		if( equal(szClassname, box_classname) )
			return true;
	}
	if( id && msg[0] ) blocks_print(id, print_chat, msg);
	return false;
}
ValidTele(const id, const ent, const msg[]="")
{
	if( pev_valid(ent) )
	{
		new szClassname[6];
		pev(ent, pev_classname, szClassname, 5);
		if( equal(szClassname, tele_classname) )
			return true;
	}
	if( id && msg[0] ) blocks_print(id, print_chat, msg);
	return false;
}
blocks_print(index, type, const message[],{Float,Sql,Result,_}:...)
{
	new msg[256];
	vformat(msg, 255, message, 4);
	if( type == print_center )
		client_print(index, type, msg);
	else
		client_print(index, type, "[BB] %s", msg);
}

//taken from blockmaker
doSnapping(id, ent, Float:fMoveTo[3])
{
	//if player has snapping enabled
	if( PlayerSnap[id] )
	{
		new Float:fSnapSize = SNAP_DISTANCE;
		new Float:vReturn[3];
		new Float:dist;
		new Float:distOld = 9999.9;
		new Float:vTraceStart[3];
		new Float:vTraceEnd[3];
		new tr;
		new trClosest = 0;
		new blockFace;
		
		//get the size of the block being grabbed
		new Float:fSizeMin[3];
		new Float:fSizeMax[3];
		pev(ent, pev_mins, fSizeMin);
		pev(ent, pev_maxs, fSizeMax);
		
		//do 6 traces out from each face of the block
		for (new i = 0; i < 6; ++i)
		{
			//setup the start of the trace
			vTraceStart = fMoveTo;
			
			switch(i)
			{
				case 0: vTraceStart[0] += fSizeMin[0];		//edge of block on -X
				case 1: vTraceStart[0] += fSizeMax[0];		//edge of block on +X
				case 2: vTraceStart[1] += fSizeMin[1];		//edge of block on -Y
				case 3: vTraceStart[1] += fSizeMax[1];		//edge of block on +Y
				case 4: vTraceStart[2] += fSizeMin[2];		//edge of block on -Z
				case 5: vTraceStart[2] += fSizeMax[2];		//edge of block on +Z
			}
			
			//setup the end of the trace
			vTraceEnd = vTraceStart;
			
			switch(i)
			{
				case 0: vTraceEnd[0] -= fSnapSize;
				case 1: vTraceEnd[0] += fSnapSize;
				case 2: vTraceEnd[1] -= fSnapSize;
				case 3: vTraceEnd[1] += fSnapSize;
				case 4: vTraceEnd[2] -= fSnapSize;
				case 5: vTraceEnd[2] += fSnapSize;
			}
			
			//trace a line out from one of the block faces
			tr = fm_trace_line(ent, vTraceStart, vTraceEnd, vReturn);
			
			//if the trace found a block and block is not in group or block to snap to is not in group
			if( ValidBox(id, tr) )
			{
				//get the distance from the grabbed block to the found block
				dist = get_distance_f(vTraceStart, vReturn);
				
				//if distance to found block is less than the previous block
				if (dist < distOld)
				{
					trClosest = tr;
					distOld = dist;
					
					//save the block face where the trace came from
					blockFace = i;
				}
			}
		}
		
		//if there is a block within the snapping range
		if( pev_valid(trClosest) )
		{
			//get origin of closest block
			new Float:vOrigin[3];
			pev(trClosest, pev_origin, vOrigin);
			
			//get sizes of closest block
			new Float:fTrSizeMin[3];
			new Float:fTrSizeMax[3];
			pev(trClosest, pev_mins, fTrSizeMin);
			pev(trClosest, pev_maxs, fTrSizeMax);
			
			//move the subject block to the origin of the closest block
			fMoveTo = vOrigin;
			
			//offset the block to be on the side where the trace hit the closest block
			if (blockFace == 0) fMoveTo[0] += (fTrSizeMax[0] + fSizeMax[0]);
			if (blockFace == 1) fMoveTo[0] += (fTrSizeMin[0] + fSizeMin[0]);
			if (blockFace == 2) fMoveTo[1] += (fTrSizeMax[1] + fSizeMax[1]);
			if (blockFace == 3) fMoveTo[1] += (fTrSizeMin[1] + fSizeMin[1]);
			if (blockFace == 4) fMoveTo[2] += (fTrSizeMax[2] + fSizeMax[2]);
			if (blockFace == 5) fMoveTo[2] += (fTrSizeMin[2] + fSizeMin[2]);
		}
	}
}


stock fm_set_rendering(ent, fx=kRenderFxNone, r=255, g=255, b=255, rend=kRenderNormal, amt=16)
{
	set_pev(ent, pev_renderfx, fx);
	
	new Float:rendColor[3];
	rendColor[0] = float(r);
	rendColor[1] = float(g);
	rendColor[2] = float(b);
	set_pev(ent, pev_rendercolor, rendColor);
	
	set_pev(ent, pev_rendermode, rend);
	set_pev(ent, pev_renderamt, float(amt));
}
stock Team(id)
{
	if(!is_user_connected(id))
		return 0;
	return get_user_team(id);
}
 /* Sets indexes of players.
 * Flags:
 * "a" - don't collect dead players.
 * "b" - don't collect alive players.
 * "c" - skip bots.
 * "d" - skip real players.
 * "e" - match with team number.
 * "f" - match with part of name.   //not used - leaving blank to match AMXX's get_players
 * "g" - ignore case sensitivity.   //not used - leaving blank to match AMXX's get_players
 * "h" - skip HLTV.
 * "i" - not equal to team number.
 * Example: Get all alive on team 2: poke_get_players(players,num,"ae",2) */
stock poke_get_players(players[MAX_PLAYERS], &pnum, const flags[]="", team=-1)
{
	new total = 0, bitwise = read_flags(flags);
	for(new i=1; i<=MAX_PLAYERS; i++)
	{
		if(is_user_connected(i))
		{
			if( is_user_alive(i) ? (bitwise & 2) : (bitwise & 1))
				continue;
			if( is_user_bot(i) ? (bitwise & 4) : (bitwise & 8))
				continue;
			if( (bitwise & 16) && team!=-1 && Team(i)!=team)
				continue;
			// & 32
			// & 64
			if( (bitwise & 128) && is_user_hltv(i))
				continue;
			if( (bitwise & 256) && team!=-1 && Team(i)==team)
				continue;
			players[total] = i;
			total++;
		}
	}
	pnum = total;

	return true;
}

stock fm_trace_line(ignoreent, const Float:start[3], const Float:end[3], Float:ret[3]) {
	engfunc(EngFunc_TraceLine, start, end, ignoreent == -1 ? 1 : 0, ignoreent);

	new ent = global_get(glb_trace_ent);
	global_get(glb_trace_endpos, ret);

	return pev_valid(ent) ? ent : 0;
}

stock bool:fm_is_ent_visible(index, entity)
{
	new Float:origin[3], Float:view_ofs[3], Float:eyespos[3];
	pev(index, pev_origin, origin);
	pev(index, pev_view_ofs, view_ofs);
	xs_vec_add(origin, view_ofs, eyespos);

	new Float:entpos[3];
	pev(entity, pev_origin, entpos);
	engfunc(EngFunc_TraceLine, eyespos, entpos, 0, index);

	switch(pev(entity, pev_solid)) {
		case SOLID_BBOX..SOLID_BSP: return global_get(glb_trace_ent) == entity;
	}

	new Float:fraction;
	global_get(glb_trace_fraction, fraction);
	if(fraction == 1.0)
		return true;

	return false;
}
 
stock is_num_odd( num )
{
	if( num & 1 )
		return true;
	return false;
}

//Thank you from AMXX NS unstuck plugin
stock poke_UnStuck(id)
{
	if(!is_user_alive(id))
		return true;

	new hullsize = (pev(id, pev_flags) & FL_DUCKING) ? HULL_HEAD : HULL_HUMAN;
	if (!hullsize) {
		return true;
	}

	new Float:origin[3], Float:new_origin[3], distance;
	pev(id, pev_origin, origin);
	distance = 32;

	while( distance < 1000 ) {	// 1000 is just incase, should never get anywhere near that
		for (new i = 0; i < 128; ++i) {
			new_origin[0] = random_float(origin[0]-distance,origin[0]+distance);
			new_origin[1] = random_float(origin[1]-distance,origin[1]+distance);
			new_origin[2] = random_float(origin[2]-distance,origin[2]+distance);

			if ( fm_trace_hull(new_origin, hullsize, id) == 0 ) {
				engfunc(EngFunc_SetOrigin, id, new_origin);
				return true;
			}
		}
		distance += 32;
	}

	return false;
}
stock fm_trace_hull(const Float:origin[3], hull, ignoredent = 0, ignoremonsters = 0)
{
	new tr = 0, result = 0;
	engfunc(EngFunc_TraceHull, origin, origin, ignoremonsters, hull, ignoredent > 0 ? ignoredent : 0, tr);

	if (get_tr2(tr, TR_StartSolid))
		result += 1;
	if (get_tr2(tr, TR_AllSolid))
		result += 2;
	if (!get_tr2(tr, TR_InOpen))
		result += 4;

	return result;
}
stock fm_trace_normal(ignoreent, const Float:start[3], const Float:end[3], Float:ret[3]) {
	engfunc(EngFunc_TraceLine, start, end, 0, ignoreent, 0);
	get_tr2(0, TR_vecPlaneNormal, ret);

	new Float:fraction;
	get_tr2(0, TR_flFraction, fraction);
	if (fraction >= 1.0)
		return 0;

	return 1;
}
