/* shconfig.cfg cvars:

//Detonator
det_level 5   //level of hero
det_ct 0      //do you have to be on the Counter-Terrorist to explode c4?

*/

#include <amxmodx>
#include <fakemeta>
#include <superheromod>

new gHeroName[] = "Detonator";
new bool:gHasDetPower[SH_MAXSLOTS+1];
new bool:Planted;
new gEntity;

public plugin_init() {
	register_plugin("SUPERHERO Detonator", "1.0", "Rolnaaba");
	
	register_cvar("det_level", "5");
	register_cvar("det_ct", "0");
	
	shCreateHero(gHeroName, "Remotely explode the C4!", "After the C4 is planted, press the bind key and you can make it EXPLODE!", false, "det_level");
	
	register_srvcmd("det_init", "det_init");
	shRegHeroInit(gHeroName, "det_init");
	
	register_srvcmd("det_kd", "det_kd");
	shRegKeyDown(gHeroName, "det_kd");
	
	register_logevent("BombPlanted", 3, "2=Planted_The_Bomb");
	register_event("HLTV", "BeginingNewRound", "a", "1=0", "2=0");
	
	register_forward(FM_SetModel, "SetModel");
}

public det_init() {
	new temp[6];
	read_argv(1,temp,5);
	new id = str_to_num(temp);
	
	read_argv(2,temp,5);
	
	new hasPowers = str_to_num(temp);
	
	gHasDetPower[id] = (hasPowers != 0);
}

public det_kd() {
	new temp[6];
	read_argv(1,temp,5);
	new id = str_to_num(temp);
	
	if(!gHasDetPower[id] || !shModActive() || !Planted) return PLUGIN_CONTINUE;
	
	if(get_cvar_num("det_ct") && get_user_team(id) != 2) {
		client_print(id, print_chat, "You can only Detonate the C4 if you are a Counter-Terrorist!");
		return PLUGIN_CONTINUE;
	}
	
	if(pev_valid(gEntity))
		set_pdata_float(gEntity, 100, 0.0);
	
	return PLUGIN_CONTINUE;
}
	
public BombPlanted() {
	Planted = true;
}

public BeginingNewRound() {
	Planted = false;
}

public SetModel(entity, const model[]) {
	if(equal(model, "models/w_c4.mdl")) {
		gEntity = entity;
		return FMRES_IGNORED;
	}
	return FMRES_IGNORED;
}