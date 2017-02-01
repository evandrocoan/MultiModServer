/* 	
	(c) 2008 - anakin_cstrike
	Thread: http://forums.alliedmods.net/showthread.php?p=650796
	
	CREDIT: d3n14
	VERSION: 2.1.1
| Changelog |
[2.1.1]
- added cvar to control changing model
[2.1]
- map lighting change on x headshots
[2.0]
- added hs effects.
- added screen flash
- remove sound cvar.

[1.0]
- first released.

	CVARS: 
	- deagle_power 1/0 - enable/disable plugin (default 1)
	- deagle_power_shake 1/0 - enable/disable shake (default 1)
	- deagle_power_icon 1/0 - enable/disable thunder icon (default 1)
	- deagle_power_screenflash 1/0 - enable/disable screenflash victim (default 1)
	- deagle_power_explode 1/0 - enable/disable hs effects: thunder,explode,blood (default 1)
	- deagle_power_light 1/0 - enable/disable map lightning change (default 1)
	- deagle_power_lightduration 1/0 - duration in seconds for dark lightning
	- deagle_power_hs - number of kills with headshots a player must make to change the lights (default 3)

	MODULES required: Fakemeta
*/
#include <amxmodx>
#include <fakemeta>

#define V_MODEL 		"models/v_deagle_power.mdl"
#define W_MODEL			"models/w_deagle_power.mdl"
#define P_MODEL 		"models/p_deagle_power.mdl"
#define DEAGLE_W_MODEL 		"models/w_deagle_power.mdl"
new 
toggle,toggle_icon,toggle_shake,
toggle_fade,toggle_explode, toggle_mdl,
toggle_light,toggle_dur,p_dur,toggle_hs,p_hs;
new 
shake,atack,
iconstatus,screenfade;
new bool:g_Icon[33];
new white,lightning,g_sModelIndexSmoke;
new g_Hs[33];

public plugin_init()
{
	register_plugin("Deagle Power","2.1.1","anakin_cstrike");
	register_forward(FM_SetModel,"fw_setmodel"/*,1*/);
	register_event("CurWeapon", "event_curw", "be","1=1");
	register_event("DeathMsg","hook_death","a");
	
	toggle = register_cvar("deagle_power","1");
	toggle_shake = register_cvar("deagle_power_shake","1");
	toggle_icon = register_cvar("deagle_power_icon","1");
	toggle_fade = register_cvar("deagle_power_screenflash","1");
	toggle_explode = register_cvar("deagle_power_explode","1");
	toggle_light = register_cvar("deagle_power_light","1");
	toggle_dur = register_cvar("deagle_power_lightduration","3");
	toggle_hs = register_cvar("deagle_power_hs","3");
	toggle_mdl = register_cvar("deagle_power_model","1");
	
	p_dur = get_pcvar_num(toggle_dur);
	p_hs = get_pcvar_num(toggle_hs);
	
	shake = get_user_msgid("ScreenShake");
	iconstatus = get_user_msgid("StatusIcon");
	screenfade = get_user_msgid("ScreenFade");
}
public client_connect(id) {g_Hs[id] = 0;g_Icon[id] = false;}
public client_disconnect(id) {g_Hs[id] = 0;g_Icon[id] = false;}
public plugin_precache()
{
	engfunc(EngFunc_PrecacheModel,V_MODEL);
	engfunc(EngFunc_PrecacheModel,P_MODEL);
	engfunc(EngFunc_PrecacheModel,W_MODEL);
	precache_sound( "ambience/thunder_clap.wav");
	precache_sound( "weapons/headshot2.wav");
	precache_sound( "weapons/explode3.wav");
	
	g_sModelIndexSmoke = precache_model("sprites/steam1.spr");
	lightning = precache_model("sprites/lgtning.spr");
	white = precache_model("sprites/white.spr");
	return PLUGIN_CONTINUE
}
public fw_setmodel(ent,const model[])
{
	if(get_pcvar_num(toggle) != 1)
		return FMRES_IGNORED;
	if(get_pcvar_num(toggle_mdl) != 1)
		return FMRES_IGNORED;
		
	if(strcmp(DEAGLE_W_MODEL,model))
		return FMRES_IGNORED;
		
	static classname[32]
	pev(ent,pev_classname,classname,31);
	
	if(!strcmp(classname, "weaponbox") || !strcmp(classname, "armoury_entity") || !strcmp(classname, "grenade"))
	{
		engfunc(EngFunc_SetModel,ent,W_MODEL);
		return FMRES_SUPERCEDE;
	}
	return FMRES_IGNORED;
}

public event_curw(id)
{
	if(get_pcvar_num(toggle) != 1)
		return PLUGIN_CONTINUE;
	if(!is_user_alive(id))
		return PLUGIN_CONTINUE;
	new wID = read_data(2);
	if(wID != CSW_DEAGLE)
		return PLUGIN_CONTINUE;
		
	set_pev(id,pev_viewmodel2,V_MODEL);
	set_pev(id,pev_weaponmodel2,P_MODEL);
	
	atack = pev(id,pev_button)
	if(wID == CSW_DEAGLE && get_pcvar_num(toggle_shake) == 1 && atack & IN_ATTACK)
	{
		message_begin(MSG_ONE,shake,{0,0,0},id);
		write_short(1<<13);
		write_short(1<<13);
		write_short(1<<13);
		message_end();
	}
	return PLUGIN_CONTINUE;
}

public hook_death()
{
	if(get_pcvar_num(toggle) != 1)
		return PLUGIN_CONTINUE;
	static weapon[2];
	read_data(4,weapon,1);
	if(weapon[0] != 'd')
		return PLUGIN_CONTINUE;
		
	static killer,victim,kname[32];
	killer = read_data(1);
	victim = read_data(2);
	get_user_name(killer,kname,31);
	g_Hs[victim] = 0;
	if(read_data(3))
	{
		g_Hs[killer]++;
		if(get_pcvar_num(toggle_icon) == 1)
		{
			g_Icon[killer] = true;
			message_begin(MSG_ONE,iconstatus,{0,0,0},killer);
			write_byte(2);
			write_string("dmg_shock"); 
			write_byte(255);
			write_byte(0); 
			write_byte(0); 
			message_end();
			set_task(3.0,"reset_icon",killer);
		}
		if(get_pcvar_num(toggle_explode) == 1)
		{
			new vorigin[3],srco[3];
			get_user_origin(victim,vorigin);
			vorigin[2] -= 26
			srco[0] = vorigin[0] + 150
			srco[1] = vorigin[1] + 150
			srco[2] = vorigin[2] + 800
		
			switch(random_num(1,3))
			{
				case 1:
				{
					emit_sound(0,CHAN_ITEM, "ambience/thunder_clap.wav", 1.0, ATTN_NORM, 0, PITCH_NORM);
					deagle_thunder(srco,vorigin);
				}
				case 2:
				{
					emit_sound(0,CHAN_ITEM, "weapons/headshot2.wav", 1.0, ATTN_NORM, 0, PITCH_NORM);
					deagle_blood(vorigin);
				}
				case 3:
				{
					emit_sound(0,CHAN_ITEM, "weapons/explode3.wav", 1.0, ATTN_NORM, 0, PITCH_NORM);
					deagle_explode(vorigin);
				}
			}
		}
		if(!is_user_alive(victim) && !is_user_bot(victim) && get_pcvar_num(toggle_fade) == 1)
		{
			message_begin(MSG_ONE_UNRELIABLE,screenfade,{0,0,0},victim);
			write_short(6<<10);
			write_short(5<<10);
			write_short(1<<12);
			write_byte(255);
			write_byte(0);
			write_byte(0);
			write_byte(170);
			message_end();
		}
		if(g_Hs[killer] == p_hs)
		{
			set_hudmessage(85, 215, 255, 0.05, 0.20, 0, 6.0, 5.0);
			show_hudmessage(0, "%s: Deagle Warrior !",kname);
			if(get_pcvar_num(toggle_light) == 1)
			{
				lights("d");
				set_task(float(p_dur),"relights");
			}
			g_Hs[killer] = 0;
		}
	}
	if(g_Icon[victim])
	{
		g_Icon[victim] = false;
		message_begin(MSG_ONE,iconstatus,{0,0,0},victim);
		write_byte(0);
		write_string("dmg_shock"); 
		message_end();
	}
	return PLUGIN_CONTINUE;
}

deagle_explode(vec1[3])
{
	message_begin(MSG_BROADCAST,SVC_TEMPENTITY,vec1);
	write_byte(21);
	write_coord(vec1[0]); 
	write_coord(vec1[1]); 
	write_coord(vec1[2] + 16); 
	write_coord(vec1[0]); 
	write_coord(vec1[1]); 
	write_coord(vec1[2] + 1936); 
	write_short(white); 
	write_byte(0);
	write_byte(0); 
	write_byte(2); 
	write_byte(16);
	write_byte(0);
	write_byte(188); 
	write_byte(220);
	write_byte(255); 
	write_byte(255); 
	write_byte(0); 
	message_end();

	message_begin(MSG_BROADCAST,SVC_TEMPENTITY); 
	write_byte(12); 
	write_coord(vec1[0]); 
	write_coord(vec1[1]); 
	write_coord(vec1[2]); 
	write_byte(188); 
	write_byte(10); 
	message_end();
	
	message_begin(MSG_BROADCAST,SVC_TEMPENTITY,vec1); 
	write_byte(5); 
	write_coord(vec1[0]); 
	write_coord(vec1[1]); 
	write_coord(vec1[2]); 
	write_short(g_sModelIndexSmoke); 
	write_byte(2);  
	write_byte(10);  
	message_end();
}
deagle_thunder(vec1[3],vec2[3])
{
	message_begin(MSG_BROADCAST,SVC_TEMPENTITY); 
	write_byte(0); 
	write_coord(vec1[0]); 
	write_coord(vec1[1]); 
	write_coord(vec1[2]); 
	write_coord(vec2[0]); 
	write_coord(vec2[1]); 
	write_coord(vec2[2]); 
	write_short(lightning); 
	write_byte(1);
	write_byte(5);
	write_byte(2);
	write_byte(20);
	write_byte(30);
	write_byte(200); 
	write_byte(200);
	write_byte(200);
	write_byte(200);
	write_byte(200);
	message_end();

	message_begin( MSG_PVS, SVC_TEMPENTITY,vec2); 
	write_byte(9); 
	write_coord(vec2[0]); 
	write_coord(vec2[1]); 
	write_coord(vec2[2]); 
	message_end();
	
	message_begin(MSG_BROADCAST,SVC_TEMPENTITY,vec2); 
	write_byte(5); 
	write_coord(vec2[0]); 
	write_coord(vec2[1]); 
	write_coord(vec2[2]); 
	write_short(g_sModelIndexSmoke); 
	write_byte(10);  
	write_byte(10)  
	message_end();
}
deagle_blood(vec1[3])
{
	message_begin(MSG_BROADCAST,SVC_TEMPENTITY); 
	write_byte(10); 
	write_coord(vec1[0]); 
	write_coord(vec1[1]); 
	write_coord(vec1[2]); 
	message_end(); 
}
public reset_icon(id)
{
	message_begin(MSG_ONE,iconstatus,{0,0,0},id);
	write_byte(0);
	write_string("dmg_shock"); 
	message_end();
}
public relights() lights("n");
stock lights(const light[]) return engfunc(EngFunc_LightStyle,0,light);
