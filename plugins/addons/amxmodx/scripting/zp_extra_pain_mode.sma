/*===========================================================================================================
				[ZP] Extra Item: Pain/Nagato Mode

Description:
Hold "E" For Releasing a Shinra Tensei
"R" To Release the Chibaku Tensei 
And if you want the world to know the pain hold "CTRL + E" (only available when missing 15 seconds for round end)
	
Module Requeriments:
* amxmodx
* fakemeta
* hamsandwich
* engine

Cvars:
zp_pain_mode_chibaku_cooldown "20.0"		-	Time it had taken for Using Chibaku Tensei Again
zp_pain_mode_chibaku_range "2000"		-	Chibaku Tensei Range
zp_pain_mode_chibaku_force "1200"		-	Chibaku Tensei Force
zp_pain_mode_chibaku_time "100"			-	Chibaku Tensei Time (Is not for second)
zp_pain_mode_shinra_cooldown "5.0"		-	Time it had taken for Using Shinra Tensei Again
zp_pain_mode_shinra_radius "300"		-	Shinra Tensei Radius
zp_pain_mode_shinra_damage "800"		-	Shinra Tensei Damage
zp_pain_mode_health "800"			-	Life
zp_pain_mode_armor "300"			-	Armor
zp_pain_mode_glow_color	"255 255 255"		- 	Glow Color (in RGB)

	
Credits:
* [P]erfec[T] [S]cr[@]s[H] - From Make the extra item
* K-OS - From Make the Hero Tornado (I uses the code for make the Chibaku Tensei Ability)
* Vechtaa - From extra_dmg's code
* MeRcyLeZZ - From Part of the code of Napalm Nade



=============================================================================================================*/
/*===============================================================================
[Includes]
=================================================================================*/
#include <amxmodx>
#include <hamsandwich>
#include <engine>
#include <fakemeta>
#include <zombieplague>
#include <xs>

/*===============================================================================
[Defines]
=================================================================================*/
// Task ids
#define TASK_CHIBAKU 34458888
#define TASK_SHINRA 62589
#define TASK_SUPER_SHINRA 365546
#define TASK_SUPER_SHINRA_USES 36844558

// Extra Itens Definitions
#define ITEM_NAME "Pain/Nagato Mode"
#define ITEM_COST 80

/*===============================================================================
[News & Consts]
=================================================================================*/
new g_has_pain_mode[33], g_used_chibaku[33], g_chibaku_timer, g_current_chibaku, white, gSpriteLightning, gRange, gForce, super_shinra_allow, used_super_shinra
new players[32], pnum, g_itemid, gMsgBarTime, cvar_cooldown, cvar_range, cvar_force, cvar_time, g_trailSpr, g_msgDeathMsg, g_current_ent_chibaku, Float:g_chibaku_beam_size
new g_exploSpr, used_shinra[33], cvar_shinra_cooldown, cvar_shinra_radius, cvar_shinra_dmg, Float:g_radius, g_damage, Float:g_shinra_cooldown
new cvar_hp, cvar_armor, cvar_glow_color

new const sprite_ring[] = "sprites/shockwave.spr"
new const chibaku_beam_spr[] = "sprites/3dmflared.spr"
new const chibaku_tensei_class[] = "chibaku_tensei_beam"

/*===============================================================================
[Plugin Register]
=================================================================================*/
public plugin_init()
{
	// Plugin Register
	register_plugin("[ZP] Extra Item: Pain/Nagato Mode","1.0","[P]erfec[T] [S]cr[@]s[H]")
	
	// Events
	register_forward(FM_PlayerPreThink, "fm_PlayerPreThink")
	register_event("HLTV", "event_round_start", "a", "1=0", "2=0")
	register_event("HLTV", "cache_cvars", "a", "1=0", "2=0")
	
	// Cvars
	cvar_cooldown = register_cvar("zp_pain_mode_chibaku_cooldown", "20.0")		// Time it had taken for Using Chibaku Tensei Again
	cvar_range = register_cvar("zp_pain_mode_chibaku_range", "2000")			// Chibaku Tensei Range
	cvar_force = register_cvar("zp_pain_mode_chibaku_force", "1200")			// Chibaku Tensei Force
	cvar_time = register_cvar("zp_pain_mode_chibaku_time", "100" ) 			// Chibaku Tensei Time (Is not for second)
	cvar_shinra_cooldown = register_cvar("zp_pain_mode_shinra_cooldown", "5.0")	// Time it had taken for Using Shinra Tensei Again
	cvar_shinra_radius = register_cvar("zp_pain_mode_shinra_radius", "300")		// Shinra Tensei Radius
	cvar_shinra_dmg = register_cvar("zp_pain_mode_shinra_damage", "800")		// Shinra Tensei Damage
	cvar_hp = register_cvar("zp_pain_mode_health", "800")				// Life
	cvar_armor = register_cvar("zp_pain_mode_armor", "300")				// Armor
	cvar_glow_color = register_cvar("zp_pain_mode_glow_color", "255 255 255")	// Glow Color (in RGB)
	
	g_itemid = zp_register_extra_item(ITEM_NAME, ITEM_COST, ZP_TEAM_HUMAN) // Item Register
	
	// Messages
	g_msgDeathMsg = get_user_msgid("DeathMsg")
	gMsgBarTime = get_user_msgid("BarTime")
}

public plugin_precache()
{	
	precache_model(chibaku_beam_spr)
	g_exploSpr = precache_model(sprite_ring)
	g_trailSpr = precache_model("sprites/laserbeam.spr")
	white = precache_model("sprites/xssmke1.spr")
	gSpriteLightning = precache_model("sprites/lgtning.spr")
	precache_sound("zombie_plague/pain_mode/shinra_tensei.wav")
	precache_sound("zombie_plague/pain_mode/chibaku_tensei.wav")
	precache_sound("weapons/mortarhit.wav")
}

/*===============================================================================
[Cache Cvars]
=================================================================================*/
public cache_cvars()
{
	g_radius = get_pcvar_float(cvar_shinra_radius)
	g_damage = get_pcvar_num(cvar_shinra_dmg)
	g_shinra_cooldown = get_pcvar_float(cvar_shinra_cooldown)
	
	set_task(0.15, "pain_loop", 0 , "", 0 ,"b")
}

/*===============================================================================
[Bug Prevention]
=================================================================================*/
public zp_user_infected_post(id)
{
	g_has_pain_mode[id] = false
	remove_task(id + TASK_CHIBAKU)
	remove_task(id + TASK_SHINRA)
	remove_task(id + TASK_SUPER_SHINRA)
	g_used_chibaku[id] = false
}

public client_disconnect(id)
{
	g_has_pain_mode[id] = false
	remove_task(id + TASK_CHIBAKU)
	remove_task(id + TASK_SHINRA)
	remove_task(id + TASK_SUPER_SHINRA)
	g_used_chibaku[id] = false
}

public client_putinserver(id)
{
	g_has_pain_mode[id] = false
	remove_task(id + TASK_CHIBAKU)
	remove_task(id + TASK_SHINRA)
	remove_task(id + TASK_SUPER_SHINRA)
	g_used_chibaku[id] = false
}

/*===============================================================================
[Actions to choose the item]
=================================================================================*/
public zp_extra_item_selected(id, itemid)
{
	if(g_itemid == itemid)
	{
		if(g_has_pain_mode[id])
		{
			client_printcolor(id, "!g[ZP Pain/Nagato Mode]!y You Have Alterady the !tPain/Nagato Mode")
			return ZP_PLUGIN_HANDLED;
		}
		
		new szColors[16], gRed[4], gGreen[4], gBlue[4], iRed, iGreen, iBlue;
		get_pcvar_string(cvar_glow_color, szColors, 15); parse(szColors, gRed, 3, gGreen, 3, gBlue, 3)
		iRed = clamp(str_to_num(gRed), 0, 255); iGreen = clamp(str_to_num(gGreen), 0, 255); iBlue = clamp(str_to_num(gBlue), 0, 255)
		
		g_has_pain_mode[id] = true
		set_user_health(id, get_user_health(id) + get_pcvar_num(cvar_hp)) // Life
		set_user_armor(id, get_user_armor(id) + get_pcvar_num(cvar_armor)) // Armor
		set_rendering(id, kRenderFxGlowShell, iRed, iGreen, iBlue, kRenderNormal, 16); // Glow
		
		// Mensagens
		client_printcolor(id, "!g[ZP]!y You Bought the !tPain/Nagato Mode.")
		client_printcolor(id, "!g[ZP]!y Press: !gE!y For Use the !gShira Tensei !t||!g R!y For use the !gChikabu Tensei")
		if(super_shinra_allow) client_printcolor(id, "!g[ZP]!y Press !gCtrl + E!y for The World meeting the Pain.")
	}
	return PLUGIN_CONTINUE;
}

/*===============================================================================
[When Round Start]
=================================================================================*/
public event_round_start()
{
	for(new id = 1; id <= get_maxplayers(); id++)
	{
		g_chibaku_timer = 0
		g_current_chibaku = 0
		g_current_ent_chibaku = 0
		g_chibaku_beam_size = 0.0
		g_has_pain_mode[id] = false
		g_used_chibaku[id] = false
		used_super_shinra = false
		super_shinra_allow = false
		remove_task(id + TASK_CHIBAKU)
		remove_task(id + TASK_SHINRA)
		remove_task(id + TASK_SUPER_SHINRA)
		set_task(get_cvar_float("mp_roundtime") * 60.0 - 15.0, "allow_super_shinra", id + TASK_SUPER_SHINRA)  // To stay in the 15 seconds left from round end
	}
}

/*===============================================================================
[When Round End]
=================================================================================*/
public zp_round_ended()
{
	super_shinra_allow = false
	remove_task(0)
	remove_task(TASK_SUPER_SHINRA_USES)
}

/*===============================================================================
[From Use the Power with "+use" button]
=================================================================================*/
public fm_PlayerPreThink(id)
{
	static iButton; iButton = pev(id, pev_button)
	static iOldButton; iOldButton = pev(id, pev_oldbuttons)
	
	
	// Chibaku Tensei
	if((iButton & IN_RELOAD) && !(iOldButton & IN_RELOAD))
	{
		if(!is_user_alive(id) || zp_get_user_zombie(id) || !g_has_pain_mode[id])
			return PLUGIN_HANDLED
		
		if(g_current_chibaku) 
		{
			client_printcolor(id,"!g[ZP Pain/Nagato Mode]!y There is already !tChibaku Tensei!y Invoked on Map")
			return PLUGIN_HANDLED
		}
		if(g_used_chibaku[id]) 
		{
			client_printcolor(id, "!g[ZP Pain/Nagato Mode]!y Wait Some Seconds For use the !gChibaku Tensei!y Again.")
			return PLUGIN_HANDLED
		}
		
		progressBar(id, 2)
		set_task(2.0, "chibaku_tensei", id + TASK_CHIBAKU)
		return PLUGIN_HANDLED
	}
	else if(iOldButton & IN_RELOAD && !(iButton & IN_RELOAD)) 
	{
		remove_task(id + TASK_CHIBAKU)
		progressBar(id, 0)
		return PLUGIN_HANDLED
	}
	
	// Shinra Tensei
	else if((iButton & IN_USE) && !(iOldButton & IN_USE))
	{
		if(!is_user_alive(id) || zp_get_user_zombie(id) || !g_has_pain_mode[id]) return PLUGIN_HANDLED;
		
		else if(super_shinra_allow) // Super Shinra Tensei
		{
			if(pev(id, pev_flags) & FL_DUCKING) 
			{
				if(used_super_shinra) return PLUGIN_HANDLED;
				
				progressBar(id, 2)
				set_task(2.0, "super_shinra_tensei", id + TASK_SUPER_SHINRA_USES)
				return PLUGIN_HANDLED;
			}
			else if(!(pev(id, pev_flags) & FL_DUCKING))
			{
				remove_task(id + TASK_SUPER_SHINRA_USES)
				progressBar(id, 0)
			}
		}	
		
		else if(used_shinra[id])
		{
			client_printcolor(id, "!g[ZP Pain/Nagato Mode]!y Wait Some Seconds For use the !tShinra Tensei!y Again")
			return PLUGIN_HANDLED
		}
		
		progressBar(id, 2)
		set_task(2.0, "shinra_tensei", id + TASK_SHINRA)
		return PLUGIN_HANDLED
	}
	else if((iOldButton & IN_USE) && !(iButton & IN_USE)) 
	{
		remove_task(id + TASK_SHINRA)
		progressBar(id, 0)
		return PLUGIN_HANDLED
	}
	
	return PLUGIN_CONTINUE
}

/*===============================================================================
[Shinra Tensei]
=================================================================================*/
public shinra_tensei(id)
{
	id -= TASK_SHINRA
	
	used_shinra[id] = true
	set_task(g_shinra_cooldown, "allow_shinra_again", id)
	
	emit_sound(id, CHAN_STATIC, "zombie_plague/pain_mode/shinra_tensei.wav", 1.0, ATTN_NORM, 0, PITCH_NORM) // Shinra Tensei Sound
	
	shira_tensei_power(id)
}

public allow_shinra_again(id)
{
	used_shinra[id] = false
	client_printcolor(id, "!g[ZP Pain/Nagato Mode]!y The Hability !tShinra Tensei!y is Ready.")
}

shira_tensei_power(id)
{
	// Get origin
	static Float:originF[3]
	pev(id, pev_origin, originF)
	
	// Custom explosion effect
	create_blast2(originF)
	
	// Collisions
	static victim
	victim = -1
	
	while ((victim = engfunc(EngFunc_FindEntityInSphere, victim, originF, g_radius)) != 0)
	{
		if (!is_user_alive(victim) || !zp_get_user_zombie(victim)) continue;
		
		extra_dmg(victim, id, g_damage, "Shinra Tensei")
		
		new Float:vec[3];
		new Float:oldvelo[3];
		get_user_velocity(victim, oldvelo);
		create_velocity_vector(victim , id , vec);
		vec[0] += oldvelo[0];
		vec[1] += oldvelo[1];
		set_user_velocity(victim , vec);
	}
}

/*===============================================================================
[Super Shinra Tensei]
=================================================================================*/
public super_shinra_tensei(id)
{
	id -= TASK_SUPER_SHINRA_USES
	
	if(used_super_shinra) return;
	
	set_task(0.8, "super_shinra_launch")
	set_task(2.2, "super_shinra_blast")
	
	used_super_shinra = true
	
	set_hudmessage(255, 0, 0, -1.0, 0.26, 1, 5.0, 5.0, 0.1, 0.2)
	show_hudmessage(0, "The World has meet the Pain !!!")
}

public allow_super_shinra(id)
{
	id -= TASK_SUPER_SHINRA
	
	super_shinra_allow = true
	
	if(g_has_pain_mode[id]) {
		client_printcolor(id, "!g[ZP Pain/Nagato Mode]!t Super Shinra Tensei!y Ability is Ready")
		client_printcolor(id, "!g[ZP Pain/Nagato Mode]!y Press !gCtrl + E!y for the world to know the pain.")
	}
}

public super_shinra_launch()
{
	// Launch sound
	client_cmd(0, "spk zombie_plague/pain_mode/shinra_tensei")
	
	// Screen fade effect
	message_begin(MSG_BROADCAST, get_user_msgid("ScreenFade"))
	write_short((1<<12)*4)	// Duration
	write_short((1<<12)*1)	// Hold time
	write_short(0x0001)	// Fade type
	write_byte (255)	// Red
	write_byte (255)	// Green
	write_byte (255)	// Blue
	write_byte (255)	// Alpha
	message_end()
}

public super_shinra_blast(attacker)
{
	client_cmd(0, "spk weapons/mortarhit")
	
	static id, deathmsg_block
	
	deathmsg_block = get_msg_block(g_msgDeathMsg)
	
	set_msg_block(g_msgDeathMsg, BLOCK_SET)
	
	for (id = 1; id <= 32; id++) if ( is_user_alive(id) && zp_get_user_zombie(id)) user_kill(id, 1)
	
	set_msg_block(g_msgDeathMsg, deathmsg_block)
}

/*===============================================================================
[Chibaku Tensei]
=================================================================================*/
public chibaku_tensei(id)
{
	id -= TASK_CHIBAKU
	
	g_current_chibaku = id
	g_chibaku_timer = get_pcvar_num(cvar_time)
	gForce = get_pcvar_num(cvar_force)
	
	g_used_chibaku[id] = true
	set_task(get_pcvar_float(cvar_cooldown), "end_cooldown_chibaku", id)
	
	gRange = get_pcvar_num(cvar_range)
	
	emit_sound(id, CHAN_STATIC, "zombie_plague/pain_mode/chibaku_tensei.wav", 1.0, ATTN_NORM, 0, PITCH_NORM)
	
	chibaku_beam(id)
}

public chibaku_beam(id)
{
	new Float:Origin[3]
	new Float:vAngle[3]
	
	// Get position from eyes
	get_user_eye_position(id, Origin)
	
	// Get View Angles
	entity_get_vector(id, EV_VEC_v_angle, vAngle)
	
	new NewEnt = create_entity("info_target")
	
	entity_set_string(NewEnt, EV_SZ_classname, chibaku_tensei_class)
	entity_set_model(NewEnt, chibaku_beam_spr)
	entity_set_size(NewEnt, Float:{ -0.5, -0.5, -0.5 }, Float:{ 0.5, 0.5, 0.5 })
	entity_set_origin(NewEnt, Origin)
	
	make_vector(vAngle)
	entity_set_vector(NewEnt, EV_VEC_angles, vAngle)
	
	entity_set_int(NewEnt, EV_INT_solid, SOLID_BBOX)
	
	entity_set_float(NewEnt, EV_FL_scale, 0.01)
	entity_set_int(NewEnt, EV_INT_spawnflags, SF_SPRITE_STARTON)
	entity_set_float(NewEnt, EV_FL_framerate, 25.0)
	set_rendering(NewEnt, kRenderFxNone, 0, 0, 0, kRenderTransAdd, 255)
	
	entity_set_int(NewEnt, EV_INT_movetype, MOVETYPE_FLY)
	entity_set_edict(NewEnt, EV_ENT_owner, id)
	set_pev(NewEnt, pev_velocity, { 0.0, 10.0, 100.0 }) 
	
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
	write_byte(TE_BEAMFOLLOW) // TE id
	write_short(NewEnt) // entity
	write_short(g_trailSpr) // sprite
	write_byte(3) // life
	write_byte(3) // width
	write_byte(255) // r
	write_byte(255) // g
	write_byte(255) // b
	write_byte(255) // brightness
	message_end()
	
	g_current_ent_chibaku = NewEnt
}

public pain_loop()
{
	if( !g_current_chibaku || !is_valid_ent(g_current_ent_chibaku)) return
		
	static classname[32]; entity_get_string(g_current_ent_chibaku,EV_SZ_classname,classname,31)

	if (equal(classname, chibaku_tensei_class)) 
	{			
		if( !is_user_alive(g_current_chibaku) || g_chibaku_timer < 1 || zp_get_user_zombie(g_current_chibaku)) 
		{
			g_current_chibaku = 0
			g_chibaku_timer = 0
			remove_entity(g_current_ent_chibaku)
			g_current_ent_chibaku = 0
			g_chibaku_beam_size = 0.0
			return;
		}
	
		g_chibaku_beam_size += 0.1
		
		entity_set_float(g_current_ent_chibaku, EV_FL_scale, g_chibaku_beam_size)
		
		g_chibaku_timer--
		
		new Float:fl_Origin[3]
		entity_get_vector(g_current_ent_chibaku, EV_VEC_origin, fl_Origin)
		
		// Do the cool grafics stuff
		// Random Z vector
		new Origin[3]	
		FVecIVec(fl_Origin, Origin)
		Origin[2] += random(1000) - 200	// Mostly above the player
		
		new randomNum = 1 + random(19)
		WhiteFluffyChibakuWave(Origin, gRange/2, randomNum)
		
		if(randomNum == 1) {
			Origin[0] += random(800)-400
			Origin[1] += random(800)-400
			Origin[2] += 600
			
			lightning_effect(g_current_ent_chibaku, Origin, 20)
		}
		
		get_players(players, pnum, "a")
		for (new i = 0; i < pnum; i++) 
		{
			if(players[i] == g_current_chibaku) continue
			if(!zp_get_user_zombie(players[i])) continue
			
			if(get_entity_distance(players[i], g_current_ent_chibaku) > gRange ) continue
			SuckPlayerIntoChibaku(players[i], fl_Origin, gRange/2)
		}
	}
}

SuckPlayerIntoChibaku(id, Float:fl_Eye[3], offset)
{
	new Float:fl_Player[3], Float:fl_Target[3], Float:fl_Velocity[3], Float:fl_Distance
	entity_get_vector(id, EV_VEC_origin, fl_Player)
	
	// I only want the horizontal direction
	fl_Player[2] = 0.0
	
	fl_Target[0] = fl_Eye[0]
	fl_Target[1] = fl_Eye[1]
	fl_Target[2] = 0.0
	
	// Calculate the direction and add some offset to the original target,
	// so we don't fly strait into the eye but to the side of it.
	
	fl_Distance = vector_distance(fl_Player, fl_Target)
	
	fl_Velocity[0] = (fl_Target[0] -  fl_Player[0]) / fl_Distance	
	fl_Velocity[1] = (fl_Target[1] -  fl_Player[1]) / fl_Distance
	
	fl_Target[0] += fl_Velocity[1]*offset
	fl_Target[1] -= fl_Velocity[0]*offset
	
	// Recalculate our direction and set our velocity
	fl_Distance = vector_distance(fl_Player, fl_Target)
	
	fl_Velocity[0] = (fl_Target[0] -  fl_Player[0]) / fl_Distance	
	fl_Velocity[1] = (fl_Target[1] -  fl_Player[1]) / fl_Distance
	
	fl_Velocity[0] = fl_Velocity[0] * gForce
	fl_Velocity[1] = fl_Velocity[1] * gForce
	fl_Velocity[2] = 0.4 * gForce
	
	entity_set_vector(id, EV_VEC_velocity, fl_Velocity)
}

WhiteFluffyChibakuWave(vec[3], radius, life)
{
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY, vec)
	write_byte(21)		//TE_BEAMCYLINDER
	write_coord(vec[0])
	write_coord(vec[1])
	write_coord(vec[2])
	write_coord(vec[0])
	write_coord(vec[1])
	write_coord(vec[2] + radius)
	write_short(white)
	write_byte(0)		// startframe
	write_byte(0)		// framerate
	write_byte(life)	// life
	write_byte(128)		// width 128
	write_byte(0)		// noise
	write_byte(255)		// r
	write_byte(255)		// g
	write_byte(255)		// b
	write_byte(200)		// brightness
	write_byte(0)		// scroll speed
	message_end()
}

lightning_effect(id, vec[3], life)
{
	message_begin(MSG_BROADCAST ,SVC_TEMPENTITY) //message begin
	write_byte(1)
	write_short(id)		// start entity
	write_coord(vec[0])	// end position
	write_coord(vec[1])
	write_coord(vec[2])
	write_short(gSpriteLightning) // sprite index
	write_byte(0)		// starting frame
	write_byte(0)		// frame rate in 0.1's
	write_byte(life)	// life in 0.1's
	write_byte(10)		// line width in 0.1's
	write_byte(25)		// noise amplitude in 0.01's
	write_byte(255)		// Red
	write_byte(255)		// Green
	write_byte(255)		// Blue
	write_byte(255)		// brightness
	write_byte(0)		// scroll speed in 0.1's
	message_end()
}

public end_cooldown_chibaku(id)
{
	g_used_chibaku[id] = false
	
	if(!zp_get_user_zombie(id) && g_has_pain_mode[id]) client_printcolor(id, "!g[ZP Pain/Nagato Mode]!y The !gChibaku Tensei!y is ready again.");
}

/*===============================================================================
[Stocks]
=================================================================================*/
// Progress Bar
progressBar(id, seconds)
{
	message_begin(MSG_ONE_UNRELIABLE, gMsgBarTime, _, id)
	write_byte(seconds)
	write_byte(0)
	message_end()
}

// Shinra Tensei Ring (From Napalm Nade of MeRcyLeZZ)
create_blast2(const Float:originF[3])
{
	// Smallest ring
	engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, originF, 0)
	write_byte(TE_BEAMCYLINDER) // TE id
	engfunc(EngFunc_WriteCoord, originF[0]) // x
	engfunc(EngFunc_WriteCoord, originF[1]) // y
	engfunc(EngFunc_WriteCoord, originF[2]) // z
	engfunc(EngFunc_WriteCoord, originF[0]) // x axis
	engfunc(EngFunc_WriteCoord, originF[1]) // y axis
	engfunc(EngFunc_WriteCoord, originF[2]+g_radius) // z axis
	write_short(g_exploSpr) // sprite
	write_byte(0) // startframe
	write_byte(0) // framerate
	write_byte(4) // life
	write_byte(60) // width
	write_byte(0) // noise
	write_byte(255) // red
	write_byte(255) // green
	write_byte(255) // blue
	write_byte(200) // brightness
	write_byte(0) // speed
	message_end()
	
	// Medium ring
	engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, originF, 0)
	write_byte(TE_BEAMCYLINDER) // TE id
	engfunc(EngFunc_WriteCoord, originF[0]) // x
	engfunc(EngFunc_WriteCoord, originF[1]) // y
	engfunc(EngFunc_WriteCoord, originF[2]) // z
	engfunc(EngFunc_WriteCoord, originF[0]) // x axis
	engfunc(EngFunc_WriteCoord, originF[1]) // y axis
	engfunc(EngFunc_WriteCoord, originF[2]+g_radius) // z axis
	write_short(g_exploSpr) // sprite
	write_byte(0) // startframe
	write_byte(0) // framerate
	write_byte(4) // life
	write_byte(60) // width
	write_byte(0) // noise
	write_byte(255) // red
	write_byte(255) // green
	write_byte(255) // blue
	write_byte(200) // brightness
	write_byte(0) // speed
	message_end()
	
	// Largest ring
	engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, originF, 0)
	write_byte(TE_BEAMCYLINDER) // TE id
	engfunc(EngFunc_WriteCoord, originF[0]) // x
	engfunc(EngFunc_WriteCoord, originF[1]) // y
	engfunc(EngFunc_WriteCoord, originF[2]) // z
	engfunc(EngFunc_WriteCoord, originF[0]) // x axis
	engfunc(EngFunc_WriteCoord, originF[1]) // y axis
	engfunc(EngFunc_WriteCoord, originF[2]+g_radius) // z axis
	write_short(g_exploSpr) // sprite
	write_byte(0) // startframe
	write_byte(0) // framerate
	write_byte(4) // life
	write_byte(60) // width
	write_byte(0) // noise
	write_byte(255) // red
	write_byte(255) // green
	write_byte(255) // blue
	write_byte(200) // brightness
	write_byte(0) // speed
	message_end()
}

stock get_user_eye_position(id, Float:flOrigin[3])
{
	static Float:flViewOffs[3]
	entity_get_vector(id, EV_VEC_view_ofs, flViewOffs)
	entity_get_vector(id, EV_VEC_origin, flOrigin)
	xs_vec_add(flOrigin, flViewOffs, flOrigin)
}

stock make_vector(Float:flVec[3])
{
	flVec[0] -= 30.0
	engfunc(EngFunc_MakeVectors, flVec)
	flVec[0] = -(flVec[0] + 30.0)
}

// Extra damage stock (From bazooka new modes of vechtaa)
extra_dmg(id, attacker, damage, weaponDescription[])
{
	new dmgcount[33]
	
	if ( pev(id, pev_takedamage) == DAMAGE_NO ) return;
	if ( damage <= 0 ) return;
	
	new userHealth = get_user_health(id);
	
	if (userHealth - damage <= 0 ) 
	{
		dmgcount[attacker] += userHealth - damage;
		set_msg_block(get_user_msgid("DeathMsg"), BLOCK_SET);
		ExecuteHamB(Ham_Killed, id, attacker, 2);
		set_msg_block(get_user_msgid("DeathMsg"), BLOCK_NOT);
		
		
		message_begin(MSG_BROADCAST, get_user_msgid("DeathMsg"));
		write_byte(attacker);
		write_byte(id);
		write_byte(0);
		write_string(weaponDescription);
		message_end();
		
		set_pev(attacker, pev_frags, float(get_user_frags(attacker) + 1));
		
		new kname[32], vname[32], kauthid[32], vauthid[32], kteam[10], vteam[10];
		
		get_user_name(attacker, kname, 31);
		get_user_team(attacker, kteam, 9);
		get_user_authid(attacker, kauthid, 31);
		
		get_user_name(id, vname, 31);
		get_user_team(id, vteam, 9);
		get_user_authid(id, vauthid, 31);
		
		log_message("^"%s<%d><%s><%s>^" killed ^"%s<%d><%s><%s>^" with ^"%s^"", 
		kname, get_user_userid(attacker), kauthid, kteam, 
		vname, get_user_userid(id), vauthid, vteam, weaponDescription);
	}
	else 
	{
		dmgcount[attacker] += damage;
		new origin[3];
		get_user_origin(id, origin);
		
		message_begin(MSG_ONE,get_user_msgid("Damage"),{0,0,0},id);
		write_byte(21);
		write_byte(20);
		write_long(DMG_BLAST);
		write_coord(origin[0]);
		write_coord(origin[1]);
		write_coord(origin[2]);
		message_end();
		
		set_pev(id, pev_health, pev(id, pev_health) - float(damage));
	}
}

// Colored Chat (client_printcolor)
stock client_printcolor(const id, const input[], any:...)
{
	new count = 1, players[32]
	static msg[191]
	vformat(msg, 190, input, 3)
	
	replace_all(msg, 190, "!g", "^4")  // Chat Verde
	replace_all(msg, 190, "!y", "^1")  // Chat Normal
	replace_all(msg, 190, "!t", "^3")  // Chat Do Time Tr=Vermelho Ct=Azul Spec=Branco
	
	if (id) players[0] = id; else get_players(players, count, "ch")
	{
		for (new i = 0; i < count; i++)
		{
			if (is_user_connected(players[i]))
			{
				message_begin(MSG_ONE_UNRELIABLE, get_user_msgid("SayText"), _, players[i])
				write_byte(players[i]);
				write_string(msg);
				message_end();
			}
		}
	}
}

// Shinra Tensei Knockback 
stock create_velocity_vector(victim,attacker,Float:velocity[3])
{
	if(victim > 0 && victim < 33)
	{
		if(!zp_get_user_zombie(victim) || !is_user_alive(attacker))
		return 0;
		
		new Float:vicorigin[3];
		new Float:attorigin[3];
		entity_get_vector(victim   , EV_VEC_origin , vicorigin);
		entity_get_vector(attacker , EV_VEC_origin , attorigin);
		
		new Float:origin2[3]
		origin2[0] = vicorigin[0] - attorigin[0];
		origin2[1] = vicorigin[1] - attorigin[1];
		
		new Float:largestnum = 0.0;
		
		if(floatabs(origin2[0])>largestnum) largestnum = floatabs(origin2[0]);
		if(floatabs(origin2[1])>largestnum) largestnum = floatabs(origin2[1]);
		
		origin2[0] /= largestnum;
		origin2[1] /= largestnum;
		
		new a = 1500
	
		velocity[0] = ( origin2[0] * (100 *a) ) / get_entity_distance(victim , attacker);
		velocity[1] = ( origin2[1] * (100 *a) ) / get_entity_distance(victim , attacker);
		if(velocity[0] <= 20.0 || velocity[1] <= 20.0)
		velocity[2] = random_float(200.0 , 275.0);
	}
	return 1;
}

// Armor (From fakemeta_util)
stock set_user_armor(index, armor) {
	set_pev(index, pev_armorvalue, float(armor));

	return 1;
}

// Life (From fakemeta_util)
stock set_user_health(index, health) {
	health > 0 ? set_pev(index, pev_health, float(health)) : dllfunc(DLLFunc_ClientKill, index);

	return 1;
}
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1046\\ f0\\ fs16 \n\\ par }
*/
