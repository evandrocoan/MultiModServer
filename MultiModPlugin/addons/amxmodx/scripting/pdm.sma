#include <amxmodx>
#include <fakemeta>

#define PLUGIN	"Players Drop Money"
#define AUTHOR	"Sh!nE*"
#define VERSION	"1.7"

#if cellbits == 32
#define OFFSET_CSMONEY  115
#else
#define OFFSET_CSMONEY  140
#endif

#define OFFSET_LINUX      5

#define MAXENTS 1500

new moneybox[MAXENTS]
new model[] = "models/w_money_new.mdl"
new money_sound1[] = "money/money_sound.wav"

new method, ison, m_amount, ran_money, random_nums, money_drop, money_drop_a, fadeon, money_sound, divide, force
//new method6
new g_msgScreenFade
new bool:can_pickup[33]

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	
	ison = register_cvar("amx_dropmoney","1")
	method = register_cvar("amx_dropmethod","2")
	divide = register_cvar("amx_moneydivide","2")
	m_amount = register_cvar("amx_dropamount","300")
	ran_money = register_cvar("amx_droprandom","300 500 700")
	random_nums = register_cvar("amx_droprandomnums","300 7500")
	money_drop = register_cvar("amx_playerdrop","1")
	money_drop_a = register_cvar("amx_playerdropamount","1000")
	fadeon = register_cvar("amx_moneyfade","1")
	money_sound = register_cvar("amx_moneysound","1")
	force = register_cvar("amx_dropforce","10")
	g_msgScreenFade = get_user_msgid("ScreenFade")
	
	register_clcmd("drop","hook_drop")
	
	register_event("DeathMsg", "deatha", "a")
	register_forward(FM_Touch,"player_Touch")
	register_logevent("round_start", 2, "1=Round_Start")
}

public client_connect(id)	can_pickup[id]=true
public client_disconnect(id)	can_pickup[id]=false

public plugin_precache() {
	precache_model(model)
	precache_sound(money_sound1)
}

public hook_drop(id) {
	if(!get_pcvar_num(ison) || !get_pcvar_num(money_drop))	return PLUGIN_CONTINUE
	new weapon,clip,ammo,money,Float:velo[3]
	weapon = get_user_weapon(id,clip,ammo)
	if(weapon == CSW_KNIFE) {
		if(fm_get_user_money(id) < get_pcvar_num(money_drop_a))
			money = fm_get_user_money(id)
		else
			money = get_pcvar_num(money_drop_a)
		
		fm_set_user_money(id,fm_get_user_money(id) - money)
		can_pickup[id] = false
		set_task(0.3,"reset_pick",id)
		new start_velo = get_pcvar_num(force) * 15
		new end_velo = get_pcvar_num(force) * 50
		velocity_by_aim(id,random_num(start_velo,end_velo),velo)
		make_money(id,money,velo)
		return PLUGIN_HANDLED
	}
	return PLUGIN_CONTINUE
}

public reset_pick(id)	can_pickup[id] = true

public deatha() {
	if(!get_pcvar_num(ison))	return PLUGIN_CONTINUE
	
	new money, Float:velo[3]
	new victim = read_data(2)
	new killer = read_data(1)
	
	if(killer && killer != victim)
		fm_set_user_money(killer,fm_get_user_money(killer) - 300)
	
	switch(get_pcvar_num(method)) {
		case 1:{
			money = get_pcvar_num(m_amount)
			if(fm_get_user_money(victim) < money) {
				money = fm_get_user_money(victim)
				fm_set_user_money(victim,0)
			}
			else	fm_set_user_money(victim,fm_get_user_money(victim) - get_pcvar_num(m_amount))
			}
		case 2:{
			new tempmoney = fm_get_user_money(victim)
			if(money != 1) {
				money = (tempmoney / get_pcvar_num(divide))
				fm_set_user_money(victim,fm_get_user_money(victim) - money)
			}
			else {
				fm_set_user_money(victim,0)
				money = 1
			}
		}
		case 3:{
			new maxmoney = fm_get_user_money(victim)
			money = random_num(1,maxmoney)
			fm_set_user_money(victim,fm_get_user_money(victim) - money)
		}
		case 4:{
			new tempmoney2[32]
			get_pcvar_string(ran_money,tempmoney2,31)
			new tempmoney[3][6]
			parse(tempmoney2, tempmoney[0], sizeof tempmoney[] - 1,tempmoney[1], sizeof tempmoney[] - 1,tempmoney[2], sizeof tempmoney[] - 1)
			new num = random_num(1,3)
			switch(num) {
				case 1:{
					money = str_to_num(tempmoney[0])
				}
				case 2:{
					money = str_to_num(tempmoney[1])
				}
				case 3:{
					money = str_to_num(tempmoney[2])
				}
			}
			if(fm_get_user_money(victim) < money) {
				fm_set_user_money(victim,0)
				money = fm_get_user_money(victim)
			}
			else	fm_set_user_money(victim,fm_get_user_money(victim) - money)
			}
		case 5:{
			new tempmoney22[32], num_from, num_to
			get_pcvar_string(random_nums,tempmoney22,31)
			new tempmoney1[2][6]
			parse(tempmoney22, tempmoney1[0], sizeof tempmoney1[] - 1,tempmoney1[1], sizeof tempmoney1[] - 1)
			num_from = str_to_num(tempmoney1[0])
			num_to = str_to_num(tempmoney1[1])
			if(num_to > 16000)	num_to = 16000
			if(num_from < 0)	num_to = 0
			money = random_num(num_from,num_to)
			
			if(fm_get_user_money(victim) < money) {
				fm_set_user_money(victim,0)
				money = fm_get_user_money(victim)
			}
			else	fm_set_user_money(victim,fm_get_user_money(victim) - money)
			}
	}
	make_money(victim,money,velo)
	return PLUGIN_CONTINUE
}

public round_start() {
	new money_ent
	while((money_ent=engfunc(EngFunc_FindEntityByString,money_ent,"classname","pdm_money")) != 0){
		engfunc(EngFunc_RemoveEntity,money_ent)
	}
}


public make_money(id,money,Float:velo[]) {
	new moneybags = money/1000
	new moneyleft = money
	new Float:origin[3]
	new Float:angles[3]
	new Float:mins[3] = {-2.79, -0.0, -6.14}
	new Float:maxs[3] = {2.42, 1.99, 6.35}
	
	if((moneybags * 1000) < money)	moneybags++
	
	for(new i = 0; i < moneybags; ++i) {
		new newent = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString,"info_target"))
		if(!is_user_alive(id)) {
			velo[0] = random_float(1.0,150.0)
			velo[1] = random_float(1.0,150.0)
			velo[2] = random_float(1.0,150.0)
		}
		else 
			velo[2] += 100
		
		pev(newent,pev_angles,angles)
		angles[1] += random_num(1,360)
		pev(id,pev_origin,origin)
		set_pev(newent, pev_origin, origin)
		set_pev(newent, pev_classname, "pdm_money")
		engfunc(EngFunc_SetModel, newent, model)
		engfunc(EngFunc_SetSize,newent,mins,maxs)
		set_pev(newent,pev_angles,angles)
		set_pev(newent, pev_solid, SOLID_TRIGGER)
		set_pev(newent,pev_movetype,MOVETYPE_TOSS)
		set_pev(newent, pev_velocity,velo)
		engfunc(EngFunc_DropToFloor,newent)
		
		if(moneyleft == 0)	return FMRES_IGNORED
		
		if(moneyleft < 1000) {
			moneybox[newent]=moneyleft
			moneyleft = 0
			return FMRES_IGNORED
		}
		moneyleft -= 1000
		moneybox[newent]=1000
	}
	return FMRES_IGNORED
}

public player_Touch(touched, toucher) { 
	
	if (!pev_valid(touched) || !is_user_alive(toucher) ||  !get_pcvar_num(ison) || !can_pickup[toucher])
		return FMRES_IGNORED
	
	new classname[32]
	pev(touched, pev_classname, classname, sizeof classname - 1)
	
	if (equali(classname, "pdm_money")) {
		if(fm_get_user_money(toucher) == 16000)	return FMRES_IGNORED
		else if((fm_get_user_money(toucher)+moneybox[touched]) > 16000)		fm_set_user_money(toucher,16000)
		else	fm_set_user_money(toucher,fm_get_user_money(toucher) + moneybox[touched])
			
		if(get_pcvar_num(money_sound))	client_cmd(toucher,"spk %s",money_sound1)
		
		if(pev_valid(touched))
			engfunc(EngFunc_RemoveEntity,touched)
		
		if(get_pcvar_num(fadeon))
			screen_fade(toucher)
	}
	
	return FMRES_IGNORED
}


public screen_fade(id) {
	message_begin(MSG_ONE, g_msgScreenFade, {0,0,0}, id) 
	write_short(1<<12)
	write_short(1<<12)
	write_short(1<<12)
	write_byte(0)
	write_byte(200)
	write_byte(0)
	write_byte(20)
	message_end()
}


//XxAvalanchexX Stocks
stock fm_set_user_money(id,money,flash=0)
{
	set_pdata_int(id,OFFSET_CSMONEY,money,OFFSET_LINUX);
	
	message_begin(MSG_ONE,get_user_msgid("Money"),{0,0,0},id);
	write_long(money);
	write_byte(flash);
	message_end();
}




stock fm_get_user_money(id)
{
	return get_pdata_int(id,OFFSET_CSMONEY,OFFSET_LINUX);
}



