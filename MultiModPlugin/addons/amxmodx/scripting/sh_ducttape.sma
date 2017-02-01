/********************************************\
|*Duct-Tape - Stick others in their tracks! *|
|*Created By: Rolnaaba                      *|
|*                                          *|
|* Have Fun,                                *|
|*           Rolnaaba                       *|
\********************************************/

/*shconfig.cfg Cvars:

//Duct Tape
duct_level 1
duct_cool 30.0		//seconds before you can stick people again
duct_last 5.0		//seconds the sticky lasts

*/

#include <amxmodx>
#include <superheromod>

new gHeroName[] = "Duct Tape";
new bool:gHasDuctPower[SH_MAXSLOTS+1];
new bool:gCanStick[SH_MAXSLOTS+1], bool:gStuck[SH_MAXSLOTS+1];

public plugin_init() {
	register_plugin("SUPERHERO Duct Tape", "1.0", "Rolnaaba");
	
	register_cvar("duct_level", "1");
	register_cvar("duct_cool", "30.0");
	register_cvar("duct_last", "5.0");

	shCreateHero(gHeroName, "Sticky Tape", "Stick others in their tracks!", false, "duct_level");

	register_srvcmd("duct_init", "duct_init");
	shRegHeroInit(gHeroName, "duct_init");
	
	register_srvcmd("duct_kd", "duct_kd");
	shRegKeyDown(gHeroName, "duct_kd");


	register_event("ResetHUD", "duct_NewRound", "b");
	register_event("CurWeapon", "duct_speed_check", "be");
}

public duct_init() {
	new temp[5];
	read_argv(1, temp, 4);
	new id = str_to_num(temp);

	read_argv(2, temp, 4);
	new haspower = str_to_num(temp);

	gHasDuctPower[id] = (haspower != 0);
}

public duct_kd() {
	new temp[5];
	read_argv(1, temp, 4);
	new id = str_to_num(temp);

	if(!is_user_alive(id) || !gHasDuctPower[id]) return;
	if(!gCanStick[id]) { playSoundDenySelect(id); client_print(id, print_chat, "[SH](Duct Tape) Wait a bit before trying to stick again!"); return; }

	new team1 = get_user_team(id);
	new team2;
	new p_origin[3], t_origin[3];
	get_user_origin(id, p_origin);

	for(new i = 0; i < SH_MAXSLOTS; i++) {
		team2 = get_user_team(i);
		if(team2 != team1 && is_user_alive(i)) {
			get_user_origin(i, t_origin);
			if(get_distance(p_origin, t_origin) <= 100) {
				gStuck[i] = true

				set_user_maxspeed(i, 0.0);
			}
		}
	}

	gCanStick[id] = false

	set_task(get_cvar_float("duct_cool"), "duct_cooldown", id);
}

public duct_cooldown(id) {
	gCanStick[id] = true;
}

public duct_NewRound(id) {
	if(!is_user_alive(id) || !gHasDuctPower[id] || !hasRoundStarted()) return;

	gCanStick[id] = true;
}

public duct_speed_check(id) {
	if(!gStuck[id]) return;

	set_user_maxspeed(id, 0.0);
}
