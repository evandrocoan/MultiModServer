#include <amxmod>
#include <superheromod>

// ICEMAN! WC3 ENTRANGLE ROOTS RIPOFF

// CVARS
// ice_level - What level till Iceman is availble? (Default 10)
// ice_armor - How much armor does Iceman start with? (Default 200)
// ice_freezetime - How long do they stay freezed? (Default 5 seconds)
// ice_freezespeed - How fast do they run when froze? (Default 50)
// ice_searchtime - How long can he look for a target to freeze? (Default 25 seconds)
// ice_cooldown - How long till he can freeze again? (Default 30 seconds)

// VARIABLES
new gHeroName[]="Iceman"
new bool:g_HasIcePowers[SH_MAXSLOTS+1]
new gPlayerLevels[SH_MAXSLOTS+1]
new bool:stunned[33]
new bool:issearching[33]
new m_iTrail
new iBeam4
//----------------------------------------------------------------------------------------------
public plugin_init()
{
	// Plugin Info
	register_plugin("SUPERHERO ICEMAN","1.0","BLU3 V1Z10N and DbTmegaman")

	// FIRE THE EVENT TO CREATE THIS SUPERHERO!
	register_cvar("ice_level", "10" )
	shCreateHero(gHeroName, "Ice Blast", "Freeze your enemy for 10 secounds", true, "ice_level" )

	// REGISTER EVENTS THIS HERO WILL RESPOND TO! (AND SERVER COMMANDS)
	// INIT
	register_srvcmd("ice_init", "ice_init")
	shRegHeroInit(gHeroName, "ice_init")

	// GENERATOR
	register_srvcmd("ice_loop", "ice_loop")
	//shRegLoop1P0(gHeroName, "ice_loop", "ac" )
	set_task(1.0,"ice_loop",0,"",0,"b" )

	// KEY DOWN
	register_srvcmd("ice_kd", "ice_kd")
	shRegKeyDown(gHeroName, "ice_kd")

	register_event("ResetHUD","newRound","b")
	register_event("Damage", "ice_damage", "b", "2!0")

	// LEVELS
	register_srvcmd("ice_levels", "ice_levels")
	shRegLevels(gHeroName,"ice_levels")

	// DEFAULT THE CVARS
	register_cvar("ice_level", "10" )
	register_cvar("ice_armor", "200")
	register_cvar("ice_freezespeed", "5" )
	register_cvar("ice_freezespeed", "50" )
	register_cvar("ice_searchtime", "25")
	register_cvar("ice_cooldown", "30")

	// LET SERVER DECIDE IF ANOTHER HERO HAS ARMOR
	shSetMaxArmor(gHeroName, "ice_armor" )
}
//----------------------------------------------------------------------------------------------
public plugin_precache()
{
	iBeam4 = precache_model("sprites/zbeam4.spr")
	m_iTrail = precache_model("sprites/smoke.spr")
	precache_sound("turret/tu_ping")
	precache_sound("weapons/cbar_hitbod3.wav")
	precache_sound("weapons/electro5.wav")
}
//----------------------------------------------------------------------------------------------
public ice_init()
{
	new temp[6]
	// 1ST ARGUMENT
	read_argv(1,temp,5)
	new id=str_to_num(temp)

	// 2ND ARGUMENT
	read_argv(2,temp,5)
	new hasPowers=str_to_num(temp)

	if ( hasPowers )
	g_HasIcePowers[id]=true
	else
	g_HasIcePowers[id]=false
}
//----------------------------------------------------------------------------------------------
public newRound(id)
{
	gPlayerUltimateUsed[id]=false
	return PLUGIN_HANDLED
}
//----------------------------------------------------------------------------------------------
public ice_kd()
{
	set_user_rendering(kRenderFxGlowShell,0,0,250,kRenderTransAlpha,64)

	if ( !hasRoundStarted() ) return PLUGIN_HANDLED
	new temp[6]

	// First Argument is an id with Iceman Powers!
	read_argv(1,temp,5)
	new id=str_to_num(temp)

	if ( !is_user_alive(id) ) return PLUGIN_HANDLED
	if ( !g_HasIcePowers[id] ) return PLUGIN_HANDLED
	if (issearching[id] || gPlayerUltimateUsed[id]) return PLUGIN_HANDLED

	if ( gPlayerUltimateUsed[id] ) {
		playSoundDenySelect(id)
		return PLUGIN_HANDLED
	}

	new parm[2]
	parm[0]=id
	parm[1]=get_cvar_num("ice_searchtime")
	searchtarget(parm)

	return PLUGIN_CONTINUE
}
//----------------------------------------------------------------------------------------------
public ice_damage(id)
{
	if (!shModActive() || !g_HasIcePowers[id] || gPlayerUltimateUsed[id] ) return PLUGIN_CONTINUE

	new damage = read_data(2)
	new weapon, bodypart, attacker = get_user_attacker(id,weapon,bodypart)

	if ( is_user_alive(id) && id != attacker )
	{
		// TIMER
		new IceManCooldown=get_cvar_num("ice_cooldown")
		ultimateTimer(id, IceManCooldown * 1.0)

		// WEAPON SWITCH
		ice_switch(id,attacker)
	}
	setScreenFlash(attacker, 0, 0, 250, 10, damage )

	return PLUGIN_CONTINUE
}
//----------------------------------------------------------------------------------------------
public ice_switch(id,victim)
{
	new name[32]
	new IceFreezeTime=get_cvar_num("ice_freezetime")
	new IceFreezeSpeed=get_cvar_num("ice_freezespeed")
	engclient_cmd(victim,"weapon_knife")
	shStun(victim, IceFreezeTime)
	set_user_maxspeed(victim, IceFreezeSpeed * 1.0)
	get_user_name(victim,name,31)
}
//----------------------------------------------------------------------------------------------
public ice_levels()
{
	new id[5]
	new lev[5]

	read_argv(1,id,4)
	read_argv(2,lev,4)

	gPlayerLevels[str_to_num(id)]=str_to_num(lev)
}
//----------------------------------------------------------------------------------------------
public ice_loop()
{

	new id
	new players[32],count

	get_players(players,count,"a")

	for ( new x=0; x<count; x++ )
	{
		id=players[x]
		if ( g_HasIcePowers[id] && is_user_alive(id) )
		{
			new randNum = random_num(0, 10 )
			new heroLevel= floatround(gPlayerLevels[id] * get_cvar_float("ice_pctperlev") * 100)
			// server_print("setting god mode: heroLevel=%d, randNum=%d", heroLevel, randNum)
			if ( heroLevel >= randNum && !get_user_godmode(id) )
			{
				shSetGodMode(id,get_cvar_num("ice_godsecs")+1)
				setScreenFlash(id, 0, 0, 250, 10, 50 )
			}
		}
	}
}
//----------------------------------------------------------------------------------------------
public searchtarget(parm[2]){
	new id = parm[0]
	new enemy, body
	get_user_aiming(id,enemy,body)
	if ( 0<enemy<=32 && get_user_maxspeed(enemy)>10 && get_user_team(id)!=get_user_team(enemy)){
		issearching[id]=false
		gPlayerUltimateUsed[id]=true
		message_begin( MSG_BROADCAST, SVC_TEMPENTITY );
		write_byte( 22 );
		write_short(enemy);
		write_short(m_iTrail );
		write_byte( 10 );
		write_byte( 5 );
		write_byte( 0 );
		write_byte( 0 );
		write_byte( 0 );
		write_byte( 0 );
		message_end();

		emit_sound(id,CHAN_ITEM, "weapons/cbar_hitbod3.wav", 1.0, ATTN_NORM, 0, PITCH_NORM)

		new waitparm[6]
		waitparm[0]=enemy
		waitparm[1]=100
		waitparm[5]=floatround(get_user_maxspeed(enemy))
		set_user_maxspeed(enemy,1.0)
		stunned[enemy]=true
		waitstop(waitparm)
		ultimateTimer(id, get_cvar_num("ice_cooldown") * 1.0 )

	}
	else {
		issearching[id]=true
		new counter = parm[1]
		while (counter >= 0){
			counter -= 10
			if (counter==0)
			emit_sound(id,CHAN_ITEM, "turret/tu_ping", 1.0, ATTN_NORM, 0, PITCH_NORM)
		}
		--parm[1]
		if (parm[1]>0 && get_user_health(id)>0)
		set_task(0.1,"searchtarget",21,parm,2)
		else
		issearching[id]=false
	}
	return PLUGIN_CONTINUE
}
//----------------------------------------------------------------------------------------------
public entangle(parm[2]){
	new id=parm[0]
	new life=parm[1]
	new radius = 20
	new counter = 0
	new origin[3]
	new x1
	new y1
	new x2
	new y2
	get_user_origin(id,origin)

	emit_sound(id,CHAN_STATIC, "weapons/electro5.wav", 1.0, ATTN_NORM, 0, PITCH_NORM)

	while (counter<=7){
		if (counter==0 || counter==8)
		x1= -radius
		else if (counter==1 || counter==7)
		x1= -radius*100/141
		else if (counter==2 || counter==6)
		x1= 0
		else if (counter==3 || counter==5)
		x1= radius*100/141
		else if (counter==4)
		x1= radius
		if (counter<=4)
		y1 = sqrt(radius*radius-x1*x1)
		else
		y1 = -sqrt(radius*radius-x1*x1)
		++counter
		if (counter==0 || counter==8)
		x2= -radius
		else if (counter==1 || counter==7)
		x2= -radius*100/141
		else if (counter==2 || counter==6)
		x2= 0
		else if (counter==3 || counter==5)
		x2= radius*100/141
		else if (counter==4)
		x2= radius
		if (counter<=4)
		y2 = sqrt(radius*radius-x2*x2)
		else
		y2 = -sqrt(radius*radius-x2*x2)
		new height=16+2*counter
		while (height > -40){

			message_begin( MSG_BROADCAST, SVC_TEMPENTITY )
			write_byte( 0 )
			write_coord(origin[0]+x1)
			write_coord(origin[1]+y1)
			write_coord(origin[2]+height)
			write_coord(origin[0]+x2)
			write_coord(origin[1]+y2)
			write_coord(origin[2]+height+2)
			write_short(iBeam4)
			write_byte( 0 )
			write_byte( 0 )
			write_byte( life )
			write_byte( 10 )
			write_byte( 5 )
			write_byte( 0 )
			write_byte( 0 )
			write_byte( 0 )
			write_byte( 0 )
			write_byte( 0 )
			message_end()

			height -= 16
		}

	}
	return PLUGIN_CONTINUE
}
//----------------------------------------------------------------------------------------------
public waitstop(parm[6]){
	new id=parm[0]
	new origin[3]
	get_user_origin(id, origin)
	if (origin[0]==parm[2] && origin[1]==parm[3] && origin[2]==parm[4]){
		new normalspeed = parm[5]
		new resetparm[2]
		resetparm[0]=id
		resetparm[1]=normalspeed
		set_task(float(parm[1]/10),"reset_maxspeed",22,resetparm,2)
		new entangleparm[2]
		entangleparm[0]=parm[0]
		entangleparm[1]=parm[1]
		entangle(entangleparm)
	}
	else {
		parm[2]=origin[0]
		parm[3]=origin[1]
		parm[4]=origin[2]
		set_task(0.1,"waitstop",23,parm,6)
	}
	return PLUGIN_CONTINUE
}
//----------------------------------------------------------------------------------------------
public reset_maxspeed(parm[]){
	new enemy = parm[0]
	new normalspeed = parm[1]
	stunned[enemy]=false
	set_user_maxspeed(enemy, float(normalspeed))
	return PLUGIN_CONTINUE
}
//----------------------------------------------------------------------------------------------