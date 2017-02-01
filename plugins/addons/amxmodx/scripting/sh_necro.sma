/****************************************************\
|*Necromancer - Raise a dead teamate as a zombie!   *|
|*Created By: Rolnaaba                              *|
|*                                                  *|
|* Have Fun,                                        *|
|*           Rolnaaba                               *|
\****************************************************/

/*shconfig.cfg Cvars:

//Necromancer
necro_level 1
necro_speed 500.0	//how fast can zombies run?
necro_damage 2		//how much damage do they do wit knife? [default = 2 x damage]
*/

#include <amxmodx>
#include <superheromod>

new gHeroName[] = "Necromancer";
new bool:gHasNecroPower[SH_MAXSLOTS+1];
new bool:gCanSummon[SH_MAXSLOTS+1];
new bool:gIsZombie[SH_MAXSLOTS+1];

public plugin_precache() {
	precache_model("models/player/zombie/zombie.mdl");
	precache_sound("shmod/never_die.wav");
}

public plugin_init() {
	register_plugin("SUPERHERO Necromancer", "1.0", "Rolnaaba");
	
	register_cvar("necro_level", "1");
	register_cvar("necro_speed", "500.0");
	register_cvar("necro_damage", "2");

	shCreateHero(gHeroName, "Raise the Dead", "Raise a dead teamate as a zombie!", false, "necro_level");

	register_srvcmd("necro_init", "necro_init");
	shRegHeroInit(gHeroName, "necro_init");
	
	register_event("DeathMsg", "necro_death", "a");
	register_event("ResetHUD","necro_NewSpawn","b");
	register_event("CurWeapon", "necro_weapons", "b");
	register_event("Damage", "necro_damage", "b");
}

public necro_init() {
	new temp[5];
	read_argv(1, temp, 4);
	new id = str_to_num(temp);

	read_argv(2, temp, 4);
	new haspower = str_to_num(temp);

	gHasNecroPower[id] = (haspower != 0);
}

public necro_damage(id) {
	if(!is_user_alive(id) || !shModActive() || !gIsZombie[id]) return;
	
	new wpnid, bodypart, attacker = get_user_attacker(id,wpnid,bodypart)
	
	if(wpnid != CSW_KNIFE) {
		necro_set_atrib(id);
		return;
	} else {
		new damage = read_data(3)
		new xdamage = (damage * get_cvar_num("necro_damage")) - damage;
		new headshot = bodypart == 1 ? 1 : 0
		
		
		shExtraDamage(id, attacker, xdamage, "necro_zombie", headshot);
	}
}

public necro_NewSpawn(id) {
	if(!hasRoundStarted() || !gIsZombie[id] || gCanSummon[id]) return;
	
	if(gHasNecroPower[id]) gCanSummon[id] = true;
	if(gIsZombie[id]) gIsZombie[id] = false;
}

public necro_weapons(id) {
	if(!is_user_alive(id) || !shModActive() || !gIsZombie[id]) return;
	
	necro_set_atrib(id);
}
public necro_death() {
	new id = read_data(2)

	if (!shModActive() || is_user_alive(id) || !is_user_connected(id)) return;

	new team1 = get_user_team(id);

	for (new i = 0; i <= SH_MAXSLOTS; i++ ) {
		if (i != id && is_user_alive(i) && gHasNecroPower[i] && gCanSummon[i] && team1 == get_user_team(i)) {
			new parm[2]
			parm[0] = id;
			parm[1] = i;
			set_task(0.1,"necro_summon", 0, parm, 2);
		}
	}
}

public necro_summon(parm[]) {
	new dead = parm[0];
	new raiser = parm[1];

	if (!gCanSummon[raiser] || !hasRoundStarted()) return;
	if (!is_user_connected(dead) || !is_user_connected(raiser)) return;
	if (!is_user_alive(raiser) || is_user_alive(dead)) return;
	if (get_user_team(dead) != get_user_team(raiser)) return;

	new Name[32];
	get_user_name(raiser, Name,31);

	cs_user_spawn(dead);
	cs_user_spawn(dead);
	
	client_print(dead, print_chat, "[SH](Necro) %s has raised you, now spill blood for them!", Name);
	
	emit_sound(dead, CHAN_STATIC, "shmod/never_die.wav", 1.0, ATTN_NORM, 0, PITCH_NORM);
	
	necro_set_atrib(dead);
	gIsZombie[dead] = true;
}

public necro_set_atrib(id) {
	if(!is_user_alive(id) || !shModActive() || !gIsZombie[id]) return;
	
	new ammo, clip, wpnid = get_user_weapon(id, ammo, clip);
	
	if(wpnid != CSW_KNIFE) {
		strip_user_weapons(id);
		give_item(id, "weapon_knife");
	}	
	cs_set_user_model(id, "zombie");
	set_user_maxspeed(id, get_cvar_float("necro_speed"));
}
