#include <amxmodx>
#include <engine>
#include <fun>
#include <cstrike>
#include <superheromod>

#define IDLE		0
#define DIVING		1
#define ATTACKING	2

// #define DEBUG

new Status = IDLE
new JawsEnt = 0		// There can be only one true jaws
new JawsOwner = 0
new Target = 0
new GoreHP = 200
new Float:CircularMotion = 0.0
new Float:LastFind, Float:Hunting

#if defined DEBUG
new TestEnt[5] = 0
new Testnr = 0
#endif

// VARIABLES
new gHeroName[]="Jaws"
new bool:g_hasJawsPower[SH_MAXSLOTS+1]

public plugin_init() {
	register_plugin("SUPERHERO Jaws", "1.01", "K-OS")

	// FIRE THE EVENT TO CREATE THIS SUPERHERO!
	register_cvar("jaws_level", "9" )
	register_cvar("jaws_cooldown", "90" )
	register_cvar("jaws_range", "2000")

	// FIRE THE EVENT TO CREATE THIS SUPERHERO!
	shCreateHero(gHeroName, "Summon Jaws", "Jaws will hunt down and eat your enemies", true, "jaws_level")

	// REGISTER EVENTS THIS HERO WILL RESPOND TO! (AND SERVER COMMANDS)
	register_event("ResetHUD","newRound","b")

	// KEY DOWN
	register_srvcmd("jaws_kd", "jaws_kd")
	shRegKeyDown(gHeroName, "jaws_kd")
	
	// INIT
	register_srvcmd("jaws_init", "jaws_init")
	shRegHeroInit(gHeroName, "jaws_init")
	
#if defined DEBUG
	register_clcmd("jaws","jaws_create")
	register_clcmd("target","test_target")
	register_clcmd("giveup","jaws_giveup")
#endif
}

public plugin_precache() {
	precache_model("models/shmod/jaws.mdl")
	precache_sound("ichy/ichy_alert3.wav")
	precache_sound("ichy/ichy_attack1.wav")
}

public jaws_init()
{
	new temp[128]
	// First Argument is an id
	read_argv(1,temp,5)
	new id=str_to_num(temp)

	// 2nd Argument is 0 or 1 depending on whether the id has wolverine skills
	read_argv(2,temp,5)
	new hasPowers=str_to_num(temp)

	g_hasJawsPower[id]=(hasPowers!=0)
}

public newRound(id)
{
	gPlayerUltimateUsed[id] = false
	jaws_destroy()
}

public jaws_kd()
{
	new temp[6]
	read_argv(1,temp,5)
	new id = str_to_num(temp)

	if(!is_user_alive(id))
		return PLUGIN_HANDLED

	if(JawsEnt || gPlayerUltimateUsed[id]) {
		client_print(id,print_chat,"[SH](Jaws) Out for lunch, back in 5 minutes")
		playSoundDenySelect(id)
		return PLUGIN_HANDLED
	}
	
	gPlayerUltimateUsed[id] = true
	ultimateTimer(id, float(get_cvar_num("jaws_cooldown")))

	jaws_create(id)
	
	return PLUGIN_HANDLED
}

#if defined DEBUG
public test_target(id)
{
	Testnr++
	if(Testnr>4) Testnr = 0
	
	if(TestEnt[Testnr]) remove_entity(TestEnt[Testnr])
	
	TestEnt[Testnr] = create_entity("info_target")
	entity_set_string(TestEnt[Testnr], EV_SZ_classname, "testtarget")
	
	new sPlayerModel[64]
	entity_get_string(id, EV_SZ_model, sPlayerModel, 63)
	entity_set_model(TestEnt[Testnr], sPlayerModel)
	
	new Float:fl_Origin[3]
	entity_get_vector(id, EV_VEC_origin, fl_Origin)
	entity_set_origin(TestEnt[Testnr], fl_Origin)
	
	new Float:MinBox[3] = {-10.0, -10.0, -32.0}		
	new Float:MaxBox[3] = {10.0, 10.0, 32.0}
	entity_set_vector(TestEnt[Testnr], EV_VEC_mins, MinBox)
	entity_set_vector(TestEnt[Testnr], EV_VEC_maxs, MaxBox)
	
	entity_set_int(TestEnt[Testnr], EV_INT_solid, SOLID_SLIDEBOX)
	entity_set_int(TestEnt[Testnr], EV_INT_movetype, MOVETYPE_TOSS)
	
	entity_set_float(TestEnt[Testnr], EV_FL_framerate, 1.0)
	entity_set_int(TestEnt[Testnr], EV_INT_sequence, 1)

	return PLUGIN_HANDLED
}
#endif

public jaws_create(id)
{
	jaws_destroy()
	
	new Float:StartOrigin[3], Float:Angle[3]
	entity_get_vector(id, EV_VEC_origin, StartOrigin)
	entity_get_vector(id, EV_VEC_v_angle, Angle)
	Angle[0] *= -1.0
	StartOrigin[0] -= 32
  
	JawsEnt = create_entity("info_target")
	entity_set_string(JawsEnt, EV_SZ_classname, "jaws")
	entity_set_model(JawsEnt, "models/shmod/jaws.mdl")
	entity_set_origin(JawsEnt, StartOrigin)

	// Make jaws drop to the ground and let the HL engine take care of the physics
	entity_set_int(JawsEnt, EV_INT_solid, SOLID_SLIDEBOX)
//	entity_set_int(JawsEnt, EV_INT_movetype, MOVETYPE_STEP)	// Linux servers won't render entities with this movetype
	entity_set_int(JawsEnt, EV_INT_movetype, MOVETYPE_PUSHSTEP)

	// Small boundingbox so jaws is positioned just under the ground ( The origin is in his fin )
	new Float:MinBox[3] = {-1.0, -1.0, 0.0}		
	new Float:MaxBox[3] = {1.0, 1.0, 1.0}
	entity_set_vector(JawsEnt, EV_VEC_mins, MinBox)
	entity_set_vector(JawsEnt, EV_VEC_maxs, MaxBox)
	entity_set_int(JawsEnt, EV_INT_effects, 0)

	entity_set_vector(JawsEnt, EV_VEC_angles, Angle)

	JawsOwner = id
	entity_set_edict(JawsEnt, EV_ENT_owner, id)	
	
	// Give it a starting velocity ( If jaws doesn't have a velocity, he will point his nose straight down. Looks weird )
	VelocityByAim(id, 400, Angle)
	entity_set_vector(JawsEnt, EV_VEC_velocity, Angle)
	
	set_task(0.1,"jaws_loop",10349,"",0,"b" )
	set_task(45.0,"jaws_giveup", 10350)
	
	return PLUGIN_HANDLED
}

public jaws_destroy()
{
	remove_task(10349, 0)
	remove_task(10350, 0)

	if(!JawsEnt) return
	
	remove_entity(JawsEnt)
	JawsEnt = 0
	Target = 0
	Status = IDLE
	
	set_cvar_num("amx_gore_exphp", GoreHP)
}

public jaws_giveup() {
	entity_set_int(JawsEnt, EV_INT_movetype, MOVETYPE_NOCLIP)
	Status = ATTACKING
	PlayAlertSound()
	set_task(3.0,"jaws_destroy", 0)		// Jaws is back into the deep, remove his entity from the world
}

jaws_find_target(IgnorePlayer)
{
	new CsTeams:Team, Players[SH_MAXSLOTS], Pnum, Distance, TargetDistance
	
	Team = cs_get_user_team(JawsOwner)	
	Target = 0
	TargetDistance = get_cvar_num("jaws_range")
	
	if(Team == CS_TEAM_CT)
		get_players(Players, Pnum, "ae", "TERRORIST")
	else if(Team == CS_TEAM_T)
		get_players(Players, Pnum, "ae", "CT")

	for(new i=0; i<Pnum; i++) {
		if(IgnorePlayer == Players[i]) continue
		
		Distance = get_entity_distance(Players[i], JawsEnt)	
		if(Distance<TargetDistance) {
			TargetDistance = Distance
			Target = Players[i]
		}
	}
	
#if defined DEBUG
	if(!Target) {
		Pnum = find_ent_by_class(0, "testtarget")
		
		while(Pnum) {
			if(IgnorePlayer != Pnum) {
				Distance = get_entity_distance(Pnum, JawsEnt)
				
				if(Distance<TargetDistance) {
					TargetDistance = Distance
					Target = Pnum
				}
			}
			Pnum = find_ent_by_class(Pnum, "testtarget")
		}
	}
#endif
	
	if(!Target && IgnorePlayer) Target = IgnorePlayer
}

public jaws_loop()
{
	if(!JawsEnt) return

	// Get it's current velocity that is calculated by the HL engine
	new Float:Velocity[3]
	entity_get_vector(JawsEnt, EV_VEC_velocity, Velocity)
	
	if(Status == ATTACKING) {
		// The HL engine is no longer taking care of jaws's physics, so we need to add the gravity ourself
		Velocity[2] -= 100.0
			
		new Players[SH_MAXSLOTS], Pnum, Distance, DeathMSG
		get_players(Players, Pnum, "a")
		DeathMSG = get_user_msgid("DeathMsg")
		
		for(new i=0; i<Pnum; i++) {
			Distance = get_entity_distance(Players[i], JawsEnt)
		
			if(Distance<100) {
				set_msg_block(DeathMSG, BLOCK_SET)
				user_kill(Players[i], 1)
				set_msg_block(DeathMSG, BLOCK_NOT)
							
				message_begin(MSG_BROADCAST, DeathMSG)
				write_byte(JawsOwner)
				write_byte(Players[i])
				write_byte(0)
				write_string("jaws")
				message_end()
				
				if(cs_get_user_team(JawsOwner) != cs_get_user_team(Players[i]))
					set_user_frags(JawsOwner, get_user_frags(JawsOwner) + 1)
				// Let amx_gore_ultimate take care of the gibbing
			}
		}
	}
#if defined DEBUG
	else if(!Target) {
#else
	else if(!is_valid_ent(Target) || !is_user_alive(Target) ) {
#endif
		jaws_find_target(0)
//		jaws_find_target(Target)	
		if(Target) return

		CircularMotion += 0.1
		Velocity[0] += floatsin(CircularMotion)*400
		Velocity[1] += floatcos(CircularMotion)*400
		Velocity[0] /= 2
		Velocity[1] /= 2
	}
	else {
		new Float:TargetOrigin[3], Float:SelfOrigin[3], Float:DirVector[2]
		entity_get_vector(Target, EV_VEC_origin, TargetOrigin)
		entity_get_vector(JawsEnt, EV_VEC_origin, SelfOrigin)

		new Distance = floatround( floatsqroot( floatpower(SelfOrigin[0] - TargetOrigin[0], 2.0) + floatpower(SelfOrigin[1] - TargetOrigin[1], 2.0) ) )
		
		DirVector[0] = (TargetOrigin[0] -  SelfOrigin[0]) / Distance
		DirVector[1] = (TargetOrigin[1] -  SelfOrigin[1]) / Distance

		if (Status == IDLE) {
			if(Distance < 500) {
				Status = DIVING
						
				// We'll take care of jaws's physics from now, so tell the HL engine to stop doing jaws's  physics
				entity_set_int(JawsEnt, EV_INT_movetype, MOVETYPE_NOCLIP)
				PlayAlertSound()		// GGGRRRROOOOWWWWLLLL
				remove_task(10350, 0)	// Don't give up now
				
				new Float:MinBox[3] = {-180.0, -40.0, -90.0}
				new Float:MaxBox[3] = {180.0, 40.0, 20.0}
				entity_set_vector(JawsEnt, EV_VEC_mins, MinBox)
				entity_set_vector(JawsEnt, EV_VEC_maxs, MaxBox)
					
				if(Velocity[2] > -100)
					Velocity[2] -= 100.0	// Go down
			}
			else {
				if(vector_length(Velocity) < 25) {	// Jaws isn't moving that fast , he must be stuck or something
					if(LastFind+1.5 < halflife_time()) {
						LastFind = halflife_time()
						
						new Float:PointOrigin[3], Float:PointEnd[3]
						PointOrigin[0] = SelfOrigin[0] + DirVector[0] * 5
						PointOrigin[1] = SelfOrigin[1] + DirVector[1] * 5
						PointOrigin[2] = SelfOrigin[2]
						
						PointEnd[0] = PointOrigin[0]
						PointEnd[1] = PointOrigin[1]
						PointEnd[2] = PointOrigin[2] + 1500
						
						trace_line(JawsEnt, PointOrigin, PointEnd, PointEnd)
						
						if(PointEnd[2] < PointOrigin[2] + 1500) {
							Velocity[2] += (PointEnd[2] - PointOrigin[2])/1.5
						}
						else {
							jaws_find_target(Target)	// Find someone else to eat
							Hunting = halflife_time() + random_num(2,6)
						}
					}
				}
				
				if(Hunting > halflife_time()) {
					CircularMotion += 0.1
					DirVector[0] = floatsin(CircularMotion)
					DirVector[1] = floatcos(CircularMotion) 
				}
				else {
					CircularMotion += 0.3
					Velocity[0] += DirVector[1] * floatsin(CircularMotion) * 75
					Velocity[1] += DirVector[0] * floatcos(CircularMotion) * 75 
				}
			}
		}
		else if(Status == DIVING) {
			// Get below the target
			if(TargetOrigin[2] < SelfOrigin[2]+100)
				Velocity[2] -= 100
			else
				Velocity[2] = 0.0			
					
			// Close enough and jaws is underwater, start attacking
			if(Distance < 200) {
				Status = ATTACKING	
				
				set_task(0.4,"PlayAttackSound", 0)	// RRRROOOOOAAAAARRRRR		
				set_task(3.0,"jaws_destroy", 0)		// Jaws is back into the deep, remove his entity from the world
				
				if(TargetOrigin[2] > SelfOrigin[2])
					Velocity[2] = (TargetOrigin[2] - SelfOrigin[2]) * 1.1
				
				Velocity[2] += 400.0		// Move up fast
				
				GoreHP = get_cvar_num("amx_gore_exphp")					
				set_cvar_num("amx_gore_exphp", 99)
			}
		}
		
		// Decrease his horizontal speed when he falls
		new BaseVelocity = 400
		if(Velocity[2] < 0)
			BaseVelocity += floatround(Velocity[2]/2)
		else 
			BaseVelocity -= floatround(Velocity[2]/2)
			
		if(BaseVelocity < 20) BaseVelocity = 20
			
		// Add more velocity towards his target and take the average so his movement is smoothend
		Velocity[0] += DirVector[0] * BaseVelocity
		Velocity[1] += DirVector[1] * BaseVelocity		
		Velocity[0] /= 2
		Velocity[1] /= 2
	}

	entity_set_vector(JawsEnt, EV_VEC_velocity, Velocity)

	// Angle Stuff
	if(Status == DIVING)		// Dont point his nose down so much when he dives
		Velocity[2] /= 4

	new Float:Angle[3]
	vector_to_angle( Velocity, Angle )
	entity_set_vector(JawsEnt, EV_VEC_angles, Angle)
}

PlayAlertSound() {
	emit_sound(JawsEnt, CHAN_AUTO, "ichy/ichy_alert3.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
}

public PlayAttackSound() {
	emit_sound(JawsEnt, CHAN_AUTO, "ichy/ichy_attack1.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
}
