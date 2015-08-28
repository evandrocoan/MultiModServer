#include <amxmod>
#include <superheromod>

// GREEN ARROW - Exploding Arrows (bullets from scout)

// CVARS
// noob_arrows- How many Arrows does he get each round
// noob_getdeagle- Does he get a free scout on respawn.


// VARIABLES
new gHeroName[]="Noob"
new gHasNoobPower[SH_MAXSLOTS+1]
new gArrowsFired[33] = 0
// Test
new gLastWeapon[33]=0
new gLastClipCount[33]=0
new lastammo[33]
new lastweap[33]

// sprites!
new spr_laser
new spr_laser_impact
new spr_blast_shroom

//----------------------------------------------------------------------------------------------
public plugin_init()
{
	// Plugin Info
	register_plugin("SUPERHERO Noob","1.2","AssKicR")

	register_cvar("noob_level", "0")
	register_cvar("noob_arrows", "3")
	register_cvar("noob_getdeagle", "1")

	// FIRE THE EVENT TO CREATE THIS SUPERHERO!
	shCreateHero(gHeroName, "exploding deagle shots", "U WILL HAVE A DEAGE WITH 3 EXPLODING SHOTS!!", false, "noob_level")

	// REGISTER EVENTS THIS HERO WILL RESPOND TO! (AND SERVER COMMANDS)
	// INIT
	register_srvcmd("noob_init", "noob_init")
	shRegHeroInit(gHeroName, "noob_init")

	register_event("ResetHUD","newRound","b")

	// GREEN ARROW DAMAGE
	register_event("Damage", "noob_damage", "b", "2!0")

	// COUTING ARROWS
	register_event("CurWeapon","changeWeapon","be","1=1")

	// MAKE A TRAIL OF THE ARROW
	register_event("CurWeapon","make_tracer", "be", "1=1", "3>0")
}
//----------------------------------------------------------------------------------------------
public noob_init()
{
	new temp[128]
	// First Argument is an id
	read_argv(1,temp,5)
	new id=str_to_num(temp)

	// 2nd Argument is 0 or 1 depending on whether the id has garrow
	read_argv(2,temp,5)
	new hasPowers=str_to_num(temp)
	gHasNoobPower[id]=(hasPowers!=0)
}
//----------------------------------------------------------------------------------------------
public plugin_precache()
{
	spr_laser = precache_model("sprites/laserbeam.spr")
	spr_laser_impact = precache_model("sprites/zerogxplode.spr")
	spr_blast_shroom = precache_model("sprites/mushroom.spr")
}
//----------------------------------------------------------------------------------------------
public newRound(id)
{
	new parm[1]
	parm[0]=id
	gArrowsFired[id] = 0
	gPlayerUltimateUsed[id]=false
	gLastWeapon[id]=-1  // I think the change Weapon automatically gets called on spawn death too...

	if (gHasNoobPower[id] && get_cvar_num("noob_getdeagle")==1) {
		shGiveWeapon(id,"weapon_deagle")
	}
}
//----------------------------------------------------------------------------------------------
public noob_damage(id)
{
	if (!shModActive()) return PLUGIN_CONTINUE

	new damage = read_data(2)
	new weapon, bodypart, attacker_id = get_user_attacker(id,weapon,bodypart)

	if ( attacker_id <=0 || attacker_id>SH_MAXSLOTS ) return PLUGIN_CONTINUE

	if ( gHasNoobPower[attacker_id] && weapon == CSW_DEAGLE && is_user_alive(id) && (!gPlayerUltimateUsed[attacker_id]))
	{
		new health = get_user_health(id)

		// mah nigga $id wasn't attacked by another player
		if (!is_user_connected(attacker_id)) return PLUGIN_CONTINUE
		if (attacker_id == id) return PLUGIN_CONTINUE

		// damage is less than 10%
		if (((1.0 * damage) / (1.0 * (health + damage))) < 0.01) return PLUGIN_CONTINUE

		new origin[3]
		new attacker_team[2], victim_team[2]

		get_user_origin(id, origin)

		// player fades..
		set_user_rendering(id, kRenderFxFadeSlow, 255, 255, 255, kRenderTransColor, 4);

		// beeeg explody!
		message_begin(MSG_ALL, SVC_TEMPENTITY)
		write_byte(3)            // TE_EXPLOSION
		write_coord(origin[0])
		write_coord(origin[1])
		write_coord(origin[2]-22)
		write_short(spr_blast_shroom)    // mushroom cloud
		write_byte(40)            // scale in 0.1u
		write_byte(12)            // frame rate
		write_byte(12)            // TE_EXPLFLAG_NOPARTICLES & TE_EXPLFLAG_NOSOUND
		message_end()


		// do turn down that awful racket

		// ..to be replaced by a blood spurt!
		message_begin(MSG_ALL, SVC_TEMPENTITY)
		write_byte(10)        // TE_LAVASPLASH
		write_coord(origin[0])
		write_coord(origin[1])
		write_coord(origin[2]-26)
		message_end()

		// kill victim
		user_kill(id, 1)
		message_begin( MSG_ALL, get_user_msgid("DeathMsg"),{0,0,0},0)
		write_byte(attacker_id)
		write_byte(id)
		write_byte(0)
		write_string("deagle")
		message_end()
		//Save Hummiliation
		new namea[24],namev[24],authida[20],authidv[20],teama[8],teamv[8]
		//Info On Attacker
		get_user_name(attacker_id,namea,23)
		get_user_team(attacker_id,teama,7)
		get_user_authid(attacker_id,authida,19)
		//Info On Victim
		get_user_name(id,namev,23)
		get_user_team(id,teamv,7)
		get_user_authid(id,authidv,19)
		//Log This Kill
		log_message("^"%s<%d><%s><%s>^" killed ^"%s<%d><%s><%s>^" with ^"Noob^"",
		namea,get_user_userid(attacker_id),authida,teama,namev,get_user_userid(id),authidv,teamv)

		/* set_user_health(id, 0) */

		// team check!
		get_user_team(attacker_id, attacker_team, 1)
		get_user_team(id, victim_team, 1)

		// for some reason this doesn't update in the hud until the next round.. whatever.
		if (!equali(attacker_team, victim_team)) {
			// diff. team;    $attacker_id gets credited for the kill and $250 and XP.
			//        $id gets their suicidal -1 frag back.
			set_user_frags(attacker_id, get_user_frags(attacker_id)+1)
			set_user_money(attacker_id, get_user_money(attacker_id)+150)
			shAddXP(attacker_id, id, 1)
		}
		else {
			// same team;    $attacker loses a frag and $500 and XP.
			set_user_frags(attacker_id, get_user_frags(attacker_id)-1)
			set_user_money(attacker_id, get_user_money(attacker_id)-500, 0)
			shAddXP(attacker_id, id, -1)
		}
		return PLUGIN_CONTINUE
	}
	return PLUGIN_CONTINUE
}
//----------------------------------------------------------------------------------------------,
public make_tracer(id)
{
	if (!shModActive()) return PLUGIN_CONTINUE

	new weap = read_data(2)        // id of the weapon
	new ammo = read_data(3)        // ammo left in clip

	if ( gHasNoobPower[id] && weap == CSW_DEAGLE && is_user_alive(id) && (!gPlayerUltimateUsed[id]) ) {

		if (lastweap[id] == 0) lastweap[id] = weap

		if ((lastammo[id] > ammo) && (lastweap[id] == weap)) {

			new vec1[3], vec2[3]
			get_user_origin(id, vec1, 1) // origin; where you are
			get_user_origin(id, vec2, 4) // termina; where your bullet goes

			// tracer beam
			message_begin(MSG_PAS, SVC_TEMPENTITY, vec1)
			write_byte(0)        // TE_BEAMPOINTS
			write_coord(vec1[0])
			write_coord(vec1[1])
			write_coord(vec1[2])
			write_coord(vec2[0])
			write_coord(vec2[1])
			write_coord(vec2[2])
			write_short(spr_laser)    // laserbeam sprite
			write_byte(0)        // starting frame
			write_byte(10)        // frame rate
			write_byte(2)        // life in 0.1s
			write_byte(4)        // line width in 0.1u
			write_byte(1)        // noise in 0.1u
			write_byte(153)        // red
			write_byte(0)      // green
			write_byte(0)        // blue
			write_byte(80)        // brightness
			write_byte(100)        // scroll speed
			message_end()

			// bullet impact explosion
			message_begin(MSG_PAS, SVC_TEMPENTITY, vec2)
			write_byte(3)        // TE_EXPLOSION
			write_coord(vec2[0])    // end point of beam
			write_coord(vec2[1])
			write_coord(vec2[2])
			write_short(spr_laser_impact)    // blast sprite
			write_byte(10)            // scale in 0.1u
			write_byte(30)            // frame rate
			write_byte(8)            // TE_EXPLFLAG_NOPARTICLES
			message_end()            // ..unless i'm mistaken, noparticles helps avoid a crash
		}

		lastammo[id] = ammo
		lastweap[id] = weap

		return PLUGIN_CONTINUE
	}
	return PLUGIN_CONTINUE
}
//----------------------------------------------------------------------------------------------
public changeWeapon(id)
{
	if ( !gHasNoobPower[id] || !shModActive() ) return PLUGIN_CONTINUE
	new  clip, ammo
	new wpn_id=get_user_weapon(id, clip, ammo);

	if ( wpn_id!=CSW_DEAGLE ) return PLUGIN_CONTINUE

	// This event gets trigger on a switch to a weapon too...
	// Easy work around
	if ( wpn_id != gLastWeapon[id] )
	{
		gLastWeapon[id]=wpn_id
		return PLUGIN_CONTINUE // user just switched weapons
	}

	if ( clip >= gLastClipCount[id] )
	{
		gLastClipCount[id]=clip
		return PLUGIN_CONTINUE
	}
	gLastClipCount[id]=clip

	// Ok - if it fell through here - you got a user firing the scout

	// Bullet Count
	gArrowsFired[id]=(gArrowsFired[id] + 1)
	new arrows = (get_cvar_num("noob_arrows")-gArrowsFired[id])

	if (arrows == 0) {
		gPlayerUltimateUsed[id]=true
	}
	if (arrows <= 0) {
		gPlayerUltimateUsed[id]=true
	}
	if ((arrows != 0) && arrows >= 0 ) {
		new message[128]
		format(message, 127, "You Have %d arrows left",arrows)
		set_hudmessage(255,0,0,-1.0,0.3,0,0.25,1.0,0.0,0.0,4)
		show_hudmessage(id, message)
	}
	return PLUGIN_CONTINUE
}
//----------------------------------------------------------------------------------------------