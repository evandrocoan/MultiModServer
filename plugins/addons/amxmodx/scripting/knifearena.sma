/*
	This program is free software; you can redistribute it and/or
	modify it under the terms of the GNU General Public License
	as published by the Free Software Foundation; either version 2
	of the License, or (at your option) any later version.
	
	This program is distributed in the hope that it will be useful,
	but WITHOUT ANY WARRANTY; without even the implied warranty of
	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
	GNU General Public License for more details.
*/

#include <amxmodx>
#include <amxmisc>
#include <fakemeta>
#include <engine>
#include <fun>
#include <cstrike>

#define NORM_SPEED 250.0
#define REACH 215
#define MAX 32
#define x 0
#define y 1
#define z 2

#define SLAM_RADIUS 350.0
#define LIGHTNING_RADIUS 400.0
#define LIGHTNING_REACH 1000.0
#define HEAL_REACH 400.0
#define POISION_NOVA_DIST 300
#define ARCANE_LINK_DMG 5
#define ARCANE_MANA_REQ 150
#define FEAR_DIST 200.0
#define DRAINLIFE_DIST 1000.0
#define BLINK_DIST 450
#define SILENCE_DIST 600.0
#define IGNITE_DIST 500.0

#define CS_PLAYER_HEIGHT 72.0

//Every spell has to pass the global cooldown to be cast
#define GLOBAL_COOLDOWN 0.5

#define MAXSPELL 5
#define TASK_HUD 120

new mSelectyourclass 
new mcbSelectyourclass

#define dbg 0
#define private stock

enum
{
	Flag_Stun = 0,
	Flag_Freeze,
	Flag_Fear,
	Flag_Poision,
	Flag_PoisionDagger,
	Flag_Invisible,
	Flag_Drainlife,
	Flag_SpellImmunity,
	Flag_Enrage,
	Flag_Focus,
	Flag_Dazed,
	Flag_Renew,
	Flag_Heal,
	Flag_Vengeance,
	Flag_Backstab,
	Flag_Doublestab,
	Flag_Haste,
	Flag_Meditation,
	Flag_Silence,
	Flag_Arcane_Link,
	Flag_Wrath,
	Flag_Ignite,
	Flag_Max
}

enum
{
	Class_Necromancer = 1,
	Class_Warrior,
	Class_Cleric,
	Class_Rogue,
	Class_Archmage,
	Class_Max
}

new Class_Names[Class_Max][32] = {
	"None",
	"Necromancer",
	"Warrior",
	"Cleric",
	"Rogue",
	"Archmage"
}
	

enum
{
	Spell_Poison_Dagger = 1,
	Spell_Shadow_Veil,
	Spell_Drainlife,
	Spell_Spirit_Ward,
	Spell_Fear,
	Spell_Bark_Skin,
	Spell_Sunder,
	Spell_Enrage,
	Spell_Fire_Totem,
	Spell_Wrath,	
	Spell_Ground_Slam,
	Spell_Natures_Blessing,
	Spell_Force_Of_Nature,
	Spell_Natures_Will,
	Spell_Vengeance,
	Spell_Focus,
	Spell_Lurk,
	Spell_Backstab,
	Spell_Ground_Totem,
	Spell_Stab,
	Spell_Blink,
	Spell_Meditation,
	Spell_Nova,
	Spell_Silence,
	Spell_Arcane_Link,	
	Spell_Ignite_Totem,
	Spell_Max
}

new Spell_Names[Spell_Max][32] = {
	"None",
	"Poison Dagger",
	"Shadow Veil",
	"Drainlife",
	"Spirit Ward",
	"Fear",
	"Bark Skin",
	"Sunder",
	"Enrage",
	"Fire Totem",
	"Wrath",
	"Ground Slam",
	"Natures Blessing",
	"Force Of Nature",
	"Natures Will",
	"Vengeance",
	"Focus",
	"Lurk",
	"Backstab",
	"Ground Totem",
	"Stab",
	"Blink",
	"Meditation",
	"Nova",
	"Silence",
	"Arcane Link",
	"Ignite Totem"
}

new Float:Spell_Casttime[Spell_Max] = {
	0.0,
	15.0,
	10.0,
	20.0,
	10.0,
	10.0,
	15.0,
	20.0,
	20.0,
	10.0,
	10.0,
	10.0,
	10.0,
	20.0,
	10.0,
	15.0,
	10.0,
	15.0,
	20.0,
	15.0,
	10.0,
	10.0,
	10.0,
	15.0,
	20.0,
	10.0,
	15.0
}

new afflicted[MAX][Flag_Max]
new class_armor[MAX]

new player_class[MAX]
new player_spell[MAX][MAXSPELL]
new Float:player_casttime[MAX][MAXSPELL]
new Float:player_huddelay[MAX]


new Float:player_global_cooldown[MAX]


new focus_target[MAX]
new sprite_white = 0
new sprite_fear = 0
new sprite_laser = 0
new sprite_mark = 0
new sprite_stun = 0
new sprite_dazed = 0
new sprite_blood_drop = 0
new sprite_blood_spray = 0
new sprite_poison = 0
new sprite_silence = 0
new sprite_poision_silence = 0
new sprite_ignite = 0
new sprite_smoke = 0
new sprite_spell_immune = 0

new bool:freezetime_done = false

public Float:Distance2D( Float:X, Float:Y ) {return floatsqroot( (X*X) + (Y*Y) ); }
public Float:Vec2DLength( Float:Vec[2] )  { return floatsqroot(Vec[x]*Vec[x] + Vec[y]*Vec[y] ); }




public plugin_init() 
{
	register_plugin("knifearena", "1.2", "MrDev")
	
	for (new i=0; i < MAX; i++)
	{
		for (new j=0; j < Flag_Max; j++)
			afflicted[i][j] = 0
		
		class_armor[i] = 0
		player_class[i] = -1
	}
	
	//Clcmd
	register_clcmd("fullupdate","Block")
	
	
	//Events	
	register_logevent("Event_RoundStart", 2, "0=World triggered", "1=Round_Start")
	register_event("CurWeapon", "Event_CurWeapon", "be", "1=1")
	
	//Menu
	mSelectyourclass = menu_create("Select your class", "mh_Selectyourclass")
	mcbSelectyourclass = menu_makecallback("mcb_Selectyourclass")
	menu_additem(mSelectyourclass, "Necromancer [Damage/Control]", "ma_Selectyourclass", ADMIN_ALL, mcbSelectyourclass)
	menu_additem(mSelectyourclass, "Warrior [Survival]", "ma_Selectyourclass", ADMIN_ALL, mcbSelectyourclass)
	menu_additem(mSelectyourclass, "Cleric [Healer/Damage]", "ma_Selectyourclass", ADMIN_ALL, mcbSelectyourclass)
	menu_additem(mSelectyourclass, "Rogue [Damage/Subtle]", "ma_Selectyourclass", ADMIN_ALL, mcbSelectyourclass)
	menu_additem(mSelectyourclass, "Archmage [Control/Speed]", "ma_Selectyourclass", ADMIN_ALL, mcbSelectyourclass)
		
	register_clcmd("say", "Event_Say", 0)
	
	//Help commands
	register_clcmd("say /info", "Event_Info", 0)
	register_clcmd("say /help", "Event_Info", 0)
	register_clcmd("say info", "Event_Info", 0)
	register_clcmd("say help", "Event_Info", 0)
	register_clcmd("say skills", "Event_Info", 0)
	register_clcmd("say /skills", "Event_Info", 0)
	register_clcmd("say /knifearena", "Event_Info", 0)
	register_clcmd("say /selectclass", "Event_Selectclass", 0)
	register_clcmd("say /changeclass", "Event_Selectclass", 0)
	register_clcmd("say /changerace", "Event_Selectclass", 0)
	register_clcmd("say /class", "Event_Selectclass", 0)
	
	register_logevent("Event_RoundEnd", 2, "1=Round_End")
	
	
	register_event("Damage","Event_Damage","be")
	register_event("TextMsg", "Event_RoundEnd", "a", "2=#Game_will_restart_in")
	register_event("DeathMsg", "Event_Death", "a", "1>0");
	register_event("ResetHUD","Event_Resethud","b")
	
	//Forwards	
	register_forward(FM_Touch,"FW_Touch");
	register_forward(FM_UpdateClientData, "FW_UpdateClientData_Post", 1)
	register_forward(FM_AddToFullPack, "FW_AddToFullPack")
	register_forward(FM_CmdStart,"FW_CmdStart")
	register_forward(FM_PlayerPreThink,"FW_Prethink")
	
	//Configs
	register_think("Game_Config", "Game_Config_Think")
	register_think("Mana_Limiter", "Mana_Limiter_Think")
	
	//Think	
	register_think("Effect_Stun","Effect_Stun_Think")
	register_think("Effect_Ice_Block","Effect_Ice_Block_Think")
	register_think("Freeze_Effect","Freeze_Effect_Think")
	register_think("Effect_Fire_Totem","Effect_Fire_Totem_Think")
	register_think("Effect_Fear","Effect_Fear_Think")
	register_think("Effect_Spirit_Ward","Effect_Spirit_Ward_Think")
	register_think("Effect_Poision","Effect_Poision_Think")
	register_think("Effect_Invisible","Effect_Invisible_Think")
	register_think("Effect_Drainlife","Effect_Drainlife_Think")
	register_think("Effect_Spell_Immunity","Effect_Spell_Immunity_Think")
	register_think("Effect_Armor_Add","Effect_Armor_Add_Think")
	register_think("Effect_Mark","Effect_Mark_Think")
	register_think("Effect_Daze","Effect_Daze_Think")
	register_think("Effect_Renew","Effect_Renew_Think")
	register_think("Effect_Heal", "Effect_Heal_Think")
	register_think("Effect_Vengeance", "Effect_Vengeance_Think")
	register_think("Effect_Backstab", "Effect_Backstab_Think")
	register_think("Effect_Focus", "Effect_Focus_Think")
	register_think("Effect_Doublestab", "Effect_Doublestab_Think")
	register_think("Effect_Rogue_Totem", "Effect_Rogue_Totem_Think")
	register_think("Effect_Haste", "Effect_Haste_Think")
	register_think("Effect_Meditation", "Effect_Meditation_Think")
	register_think("Effect_Silence", "Effect_Silence_Think")
	register_think("Effect_Arcane_Link", "Effect_Arcane_Link_Think")
	register_think("Effect_Wrath", "Effect_Wrath_Think")
	register_think("Effect_Ignite_Totem", "Effect_Ignite_Totem_Think")
	register_think("Effect_Ignite", "Effect_Ignite_Think")
		
	//Buy block
	register_menucmd(register_menuid("#Buy", 1 ),511,"Block")
	register_menucmd(register_menuid("BuyPistol", 1 ),511,"Block")
	register_menucmd(register_menuid("BuyShotgun", 1 ),511,"Block")
	register_menucmd(register_menuid("BuySub", 1 ),511,"Block")
  	register_menucmd(register_menuid("BuyRifle", 1),511,"Block")
  	register_menucmd(register_menuid("BuyMachine", 1),511,"Block")
  	register_menucmd(register_menuid("BuyItem", 1),511,"Block")
	register_menucmd(-28,511,"Block")
	register_menucmd(-29,511,"Block")
  	register_menucmd(-30,511,"Block")
  	register_menucmd(-32,511,"Block")
  	register_menucmd(-31,511,"Block")
  	register_menucmd(-33,511,"Block")
  	register_menucmd(-34,511,"Block")
	
	Start_Game_Config()
	
	log("Plugin_Init called")
	
	
}

public log(const fmt[], {Float,Sql,Result,_}:...)
{	
	#if debug==1
	new buffer[512]
	vformat(buffer, 511, fmt, 2)
	log_amx(buffer)
	#endif
}


stock Remove_Ent(ent)
{
	if(pev_valid(ent))
		engfunc(EngFunc_RemoveEntity, ent)
}

stock Spawn_Ent(const classname[]) 
{
    new ent = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, classname))
    set_pev(ent, pev_origin, {0.0, 0.0, 0.0})    
    dllfunc(DLLFunc_Spawn, ent)
    return ent
}



public plugin_precache()
{
	log("precache called")
		
	precache_model("models/totem_fire.mdl")
	precache_model("models/rpgrocket.mdl")
	precache_model("models/spirit_ward.mdl")
	precache_model("models/totem_rogue.mdl")
	precache_model("models/totem_ignite.mdl")

	
	sprite_white = precache_model("sprites/white.spr")
	sprite_fear = precache_model("sprites/fear.spr")
	sprite_laser = precache_model("sprites/laserbeam.spr")
	sprite_mark = precache_model("sprites/mark.spr")
	sprite_stun = precache_model("sprites/stun.spr")
	sprite_dazed = precache_model("sprites/dazed.spr")
	sprite_blood_drop = precache_model("sprites/blood.spr")
	sprite_blood_spray = precache_model("sprites/bloodspray.spr")
	sprite_poison = precache_model("sprites/poison.spr")
	sprite_silence = precache_model("sprites/silence.spr")
	sprite_poision_silence = precache_model("sprites/poision_silence.spr")
	sprite_ignite = precache_model("sprites/flame.spr")
	sprite_smoke = precache_model("sprites/steam1.spr")
	sprite_spell_immune = precache_model("sprites/si.spr")
	
	
}


public client_connect(id)
{
	log("client_connect called")
	player_class[id] = 0
	
}

public client_disconnect(id)
{
	log("client disconnect")
	class_armor[id] = 0
	player_class[id] = 0
	ResetFlags(id)
}

//Touch event. Do not pickup weapons
public FW_Touch(ptr, ptd) 
{		
	if (ptd > 0 && ptd <= MAX && is_user_connected(ptd) && ptr > MAX) 
	{ 
		new model[32]
		pev(ptr,pev_model,model,31)
				
		if ((equal(model, "models/w_", 9))) 
			return FMRES_SUPERCEDE;
			
		else if ((containi(model, "shield") > -1))
			return FMRES_SUPERCEDE;
			
		new classname[32]
		pev(ptr, pev_classname, classname, 31)
		
		
		//Hunter trap - Freeze target
		if (equal(classname,"Effect_Hunter_Trap"))
		{
			new owner = pev(ptr,pev_owner)
			
			//If enemy, freeze the scumbag
			if (get_user_team(owner) != get_user_team(ptd))
			{
				
				Remove_Ent(ptr)
				Spawn_Ice_Block(ptd,5)
			}
			
		}
			

	}
	
		
	return FMRES_IGNORED
}


//ClientData event
public FW_UpdateClientData_Post(id, sendweapons, cd_handle)
{

	if (!is_user_alive(id))
		return FMRES_HANDLED;
		

	if (HasFlag(id,Flag_Stun))
	{
		set_cd(cd_handle, CD_ID, 0);   
	}

	return FMRES_HANDLED
}

//Send message ABOUT e to HOST
public FW_AddToFullPack(ent_state,e,edict_t_ent,edict_t_host,hostflags,player,pSet) 
{
	if (!pev_valid(e)|| !pev_valid(edict_t_ent) || !pev_valid(edict_t_host))
		return FMRES_HANDLED

		
	new classname[32]
	pev(e,pev_classname,classname,31)
	
	new hostclassname[32]
	pev(edict_t_host,pev_classname,hostclassname,31)
		
	//If hunters trap, hide to enemies
	if (equal(classname,"Effect_Hunter_Trap") && !player && equal(hostclassname,"player"))
	{
		new owner = pev(e,pev_owner)
					
		//Hide for enemies
		if (get_user_team(owner) != get_user_team(edict_t_host))
			return FMRES_SUPERCEDE		
		
	}
	
	
	//If we have focus on us only show us to the enemy and vv
	if (equal(classname,"player") && equal(hostclassname,"player") && player)
	{
		// only take effect if both players are alive & and not somthing else like a ladder
		if (is_user_alive(e) && is_user_alive(edict_t_host)) 
		{
			// Get players teams
			if (get_user_team(e) != get_user_team(edict_t_host))
			{
				//We have focus flag, render all opponets invis except target
				if (HasFlag(edict_t_host,Flag_Focus) && e != focus_target[edict_t_host])
					return FMRES_SUPERCEDE
								
				//We update someone who has focus flag, and we aren't target
				if (HasFlag(e,Flag_Focus) && focus_target[e] != edict_t_host)
					return FMRES_SUPERCEDE				
			}
		}
					
	}
		
	return FMRES_HANDLED
		
}

public FW_CmdStart(id, uc_handle, seed) 
{
	if( !is_user_alive(id) )
		return PLUGIN_CONTINUE;
				   
	if (HasFlag(id,Flag_Stun) || HasFlag(id,Flag_Fear) || HasFlag(id,Flag_Freeze))
	{
		set_pev( id, pev_button, pev(id,pev_button) & ~IN_ATTACK );
		set_pev( id, pev_button, pev(id,pev_button) & ~IN_ATTACK2 );
		new buttons = get_uc(uc_handle,UC_Buttons)
		buttons &= ~IN_ATTACK
		buttons &= ~IN_ATTACK2
		set_uc(uc_handle,UC_Buttons,buttons)
	}
	
	  
	return FMRES_HANDLED
}

//Spell Control
public FW_Prethink(id)
{

		if (pev(id,pev_button) & IN_USE && pev(id,pev_button) & IN_FORWARD)
			Cast_Spell(id,0)
		
		if (pev(id,pev_button) & IN_USE && pev(id,pev_button) & IN_BACK)
			Cast_Spell(id,1)
			
		if (pev(id,pev_button) & IN_RELOAD && pev(id,pev_button) & IN_FORWARD)
			Cast_Spell(id,2)
			
		if (pev(id,pev_button) & IN_RELOAD && pev(id,pev_button) & IN_BACK)
			Cast_Spell(id,3)
			
		if (pev(id,pev_button) & IN_RELOAD && pev(id,pev_button) & IN_USE)
			Cast_Spell(id,4)
}


public Block()
{
	return PLUGIN_HANDLED
}


public Event_RoundStart()
{
	log("Event_RoundStart called")

	
	for (new i=0; i < MAX; i++)
	{
		if (is_user_alive(i))
		{
			set_user_armor(i,class_armor[i])
			Help_Player(i)
			
			if (player_class[i] == 0)
				menu_display(i, mSelectyourclass, 0)
		}
	}
	
	freezetime_done = true


}

public Event_RoundEnd()
{
	log("Event RoundEnd called")

	Remove_All_Effects()
	
	for (new i=0; i < MAX; i++)
	{
		if (is_user_connected(i))
		{
			ResetFlags(i)
			
			if (player_class[i] == -1)
				menu_display(i, mSelectyourclass, 0)
		}
	}
	
	freezetime_done = false

}

public Event_CurWeapon(id)
{
	log("Event_Curweapon called")

	if (!is_user_alive(id))
		return PLUGIN_CONTINUE
		
	new ammo
	new clip
		
	if (get_user_weapon(id,ammo,clip) != CSW_KNIFE)
	{
		client_cmd(id,"drop")
		
		if (is_user_bot(id))
			engclient_cmd(id,"weapon_knife")
	}


	return PLUGIN_CONTINUE
		
	
}

//This function is only hooked for debugging purposes
public Event_Say(id)
{
	#if debug==1
	log("Event_Say called")
	
	new message[129]
	read_argv(1,message,128)
	
	if ((strlen(message) < 1) || equal(message,"") || equal(message,"["))
		return PLUGIN_CONTINUE
			
	if (containi(message, "stun") > -1) 
	{
		Stun_Player(id,5)
	}
	
	if (contain(message, "ft") > -1)
	{
		MakeFireTotem(id,10)
	}
	
	if (contain(message, "hunt") > -1)
	{
		MakeHunterTrap(id)
	}
	
	if (contain(message, "iceblock") > -1)
	{
		Spawn_Ice_Block(id,5)
	}

	
	if (contain(message, "fear") > -1)
	{
		Fear_Player(id,5)
	}
	if (contain(message, "spirit") > -1)
	{
		MakeSpiritWard(id,10)
	}
	if (contain(message, "dagger") > -1)
	{
		MakePoisionDagger(id)
	}
	if (contain(message, "drainlife") > -1)
	{
		new target = Find_Best_Angle(id,1000.0)
		
		if (pev_valid(target))
			Player_Drainlife(id,target,5)
	}
	if (contain(message, "invis") > -1)
	{
		Invisible_Player(id,5,10)
	}
	
	if (contain(message, "armor") > -1)
	{

		Player_Armoradd(id,15,25)
	}
	
	if (contain(message, "enrage") > -1)
	{

		new target = Find_Best_Angle(id,9999.9,true)
		
		if (pev_valid(target))
			Player_Enrage(id,target,7)
	}
	if (contain(message, "sunder") > -1)
	{
		new target = Find_Best_Angle(id,REACH+0.0,true)
		
		if (pev_valid(target))
			Player_Sunder(id,target,10)
	}
	if (contain(message, "slam") > -1)
	{

		Player_Ground_Slam(id,5)
	}
	if (contain(message, "daze") > -1)
	{

		Player_Daze(id,5)
	}
	if (contain(message, "renew") > -1)
	{

		Player_Renew(id,5)
	}
	if (contain(message, "chain") > -1)
	{

		new target = Find_Best_Angle(id,LIGHTNING_REACH,true)
		
		if (pev_valid(target))
			Effect_Chainlightning(id,target,35.0,get_user_team(target))
	}
	if (contain(message, "heal") > -1)
	{

		new target = Find_Best_Angle(id,HEAL_REACH,true)
		
		if (pev_valid(target))
			Effect_Heal(id,target,25,2)
	}
	
	if (contain(message, "veng") > -1)
	{
		Effect_Vengeance(id,10)
	}
	
	if (contain(message, "backs") > -1)
	{
		Effect_Backstab(id,10)
	}
	
	if (contain(message, "focus") > -1)
	{
		new target = Find_Best_Angle(id,9999.9,false)
		
		if (pev_valid(target))
			Effect_Focus(id,target,25)
	}
	
	if (contain(message, "double") > -1)
	{
		Effect_Doublestab(id,15)
	}
	if (contain(message, "rt") > -1)
	{
		MakeRogueTotem(id,10)
	}
	
	if (contain(message, "punch") > -1)
	{
		Effect_Punch(id,-5,-5,-5)
	}
	
	if (contain(message, "tele") > -1)
	{
		Effect_Teleport(id,500)
	}
	
	if (contain(message, "contain") > -1)
	{
		new Float:origin[3]
		pev(id,pev_origin,origin)
		Is_Point_Stuck(origin,16.0)
	}
	
	if (contain(message, "pnova") > -1)
	{
		Effect_Poision_Nova(id,10)
	}
	
	if (contain(message, "poison") > -1)
	{
		Player_Poision(id,10,3)
	}
	if (contain(message, "3d") > -1)
	{
		set_view(id,CAMERA_3RDPERSON)
	}
	if (contain(message, "silence") > -1)
	{
		new target = Find_Best_Angle(id,600.0,true)
		
		if (pev_valid(target))
			Effect_Silence(target,10)
	}
	
	if (contain(message, "arcane") > -1)
	{
		Effect_Arcane_Link(id,10)
	}
	
	if (contain(message, "wrath") > -1)
	{
		Effect_Wrath(id,10)

	}
	if (contain(message, "it") > -1)
	{
		Effect_Ignite_Totem(id,10)

	}
	if (contain(message, "ignite") > -1)
	{
		Effect_Ignite(id,id,1)

	}
	#endif
	


	return PLUGIN_CONTINUE

}

public Event_Damage(id)
{
	new damage = read_data(2)
	new victim = read_data(0);
	new attacker = get_user_attacker(victim)
		
	if (!pev_valid(attacker) || !pev_valid(victim) || attacker > MAX)
		return PLUGIN_CONTINUE
			
	set_user_armor(id,class_armor[id])
	
	//Small damage is not absorbed well by armor
	new absorbed = 0
	
	if (damage < 15)
		absorbed = class_armor[id]/15 
	else
		absorbed = class_armor[id]/8
				
	//No self-afflicated damage, atleast for now
	if (victim == attacker)
		return PLUGIN_CONTINUE
		
	
	//We attacked with poision dagger
	if (HasFlag(attacker,Flag_PoisionDagger))
	{
		RemoveFlag(attacker,Flag_PoisionDagger)
		Player_Poision(victim,10,3)
		
	}
	
	//We got hit with poision dagger
	if (HasFlag(victim,Flag_PoisionDagger))
	{
		RemoveFlag(victim,Flag_PoisionDagger)
		Player_Poision(victim,10,3)
	}
	
	//We got hit with vengeance
	if (HasFlag(attacker,Flag_Vengeance))
	{
		Player_Daze(victim,3)
	}

	//We have backstab and hit someone
	if (HasFlag(attacker,Flag_Backstab))
	{
		//If player is in OUT fov and we aren't in player FOV. We succesfully make a backstab
		if (In_FOV(attacker,victim) && !In_FOV(victim,attacker))
		{
			Effect_Punch(victim,-5,-5,-5)
			RemoveFlag(attacker,Flag_Backstab)
			Stun_Player(victim,5)
		}
	}
	
	//If we have doublestab, see if we are seen and if we are apply bleed
	if (HasFlag(attacker,Flag_Doublestab))
	{
		if (In_FOV(attacker,victim) && !In_FOV(victim,attacker))
		{
			Effect_Punch(victim,-5,-5,-5)
			RemoveFlag(attacker,Flag_Doublestab)
			Effect_Bleed(attacker,victim,5,248)
		}
	}
	
	//We have enrage and attacks someone, see if he has the mark
	if (HasFlag(attacker,Flag_Enrage))
	{
		new ent = find_ent_by_owner(-1,"Effect_Mark",victim)
			
		if (pev_valid(ent))
		{
			new marker = pev(ent,pev_euser2)
			
			if (marker == attacker)
			{
				set_pev(ent,pev_ltime,0)								
				Stun_Player(victim,3)
			}
		}
						
	}
	
	//We have arcane link and attacks someone and have > 50 mana
	if (HasFlag(attacker,Flag_Arcane_Link))
	{
			if (get_user_health(attacker)+ARCANE_LINK_DMG <= 100)
				set_user_health(attacker,get_user_health(attacker)+ARCANE_LINK_DMG)
			else
				set_user_health(attacker,100)				
	}
	
	if (HasFlag(attacker,Flag_Wrath))
	{
		Hurt_Entity(attacker,victim,5.0)
	}
	
	if (HasFlag(victim,Flag_Wrath))
	{
		Hurt_Entity(attacker,victim,10.0)
		Display_Fade(victim,2500,2500,0,255,0,0,50)
	}
	
	//If we deal damage while having ignite on us, cancel it
	if (HasFlag(attacker,Flag_Ignite))
		RemoveFlag(attacker,Flag_Ignite)

	//Armor goes last because it also "cancels" spells
	if (get_user_health(id)+absorbed < 100)
		set_user_health(id,get_user_health(id)+absorbed)
	else
		set_user_health(id,100)
	
	return PLUGIN_CONTINUE
}

public Event_Death()
{
	new killer = read_data(1);
	
	//If we have wrath and kill someone, we regain full life
	if (HasFlag(killer,Flag_Wrath))
		set_user_health(killer,100)

}

public Event_Resethud(id)
{
	cs_set_user_money(id, 0,0)
}

//Remove all effects by setting ltime to 0 so they will be removed at next think
stock Remove_All_Effects()
{
	log("Remove_All_Effects called")
	
	new maxEntities = global_get(glb_maxEntities);

	for (new i = 0; i < maxEntities; i++) 
	{
		if (!pev_valid(i))
			continue;
		    
		new classname[32];
		pev(i, pev_classname, classname, 31);
		    
		if (containi(classname, "Effect_") > -1)
		{
			new ltime = pev(i,pev_ltime)
			
			if (ltime == 0)
				Remove_Ent(i)
			else
			{
				set_pev(i,pev_ltime,0)
				set_pev(i,pev_nextthink, halflife_time() + 0.1)
			}
		}
		    
	}
	
}

//Create an entity, set owner to player and make sure that aslong as entity exist, player is stunned
stock Stun_Player(id, seconds)
{
		
	new ent = Spawn_Ent("info_target")
	set_pev(ent,pev_classname,"Effect_Stun")
	set_pev(ent,pev_owner,id)
	set_pev(ent,pev_ltime, halflife_time() + seconds + 0.1)
	set_pev(ent,pev_nextthink, halflife_time() + 0.1)
	

	if (pev(id,pev_flags) & FL_ONGROUND)
		set_user_gravity(id,9999.9)
		
	AddFlag(id,Flag_Stun)

	log("Creating stun entity for player %i", id)

}

public Effect_Stun_Think(ent)
{
	new id = pev(ent,pev_owner)
	
	//Entity should be destroyed because livetime is over
	if (pev(ent,pev_ltime) < halflife_time() || !is_user_alive(id))
	{
		Remove_Ent(ent)
				
		//Only unstun IF there are no stun entities left
		if (!find_ent_by_owner(-1,"Effect_Stun",id))
		{
			set_user_maxspeed(id,NORM_SPEED)
			set_user_gravity(id,1.0)
			Display_Icon(id,100,100,100,"dmg_rad",0)
			Remove_All_Tents(id)
			RemoveFlag(id,Flag_Stun)
		}
					
		return PLUGIN_CONTINUE
	}
	
	//Apply Effect
	Display_Icon(id,100,100,100,"dmg_rad",1)		
	set_pev(ent,pev_nextthink, halflife_time() + 0.2)
	
	set_user_maxspeed(id,0.1)
	Display_Tent(id,sprite_stun,1)
	
	return PLUGIN_CONTINUE
}

stock Freeze_Player(id,seconds)
{
	new ent = Spawn_Ent("info_target")
	set_pev(ent,pev_classname,"Freeze_Effect")
	set_pev(ent,pev_owner,id)
	set_pev(ent,pev_ltime, halflife_time() + seconds + 0.1)
	set_pev(ent,pev_nextthink, halflife_time() + 0.1)
	
	if (!HasFlag(id,Flag_Stun) && !HasFlag(id,Flag_Freeze))
		set_pev(id, pev_flags, pev(id, pev_flags) | FL_FROZEN)
		
	AddFlag(id,Flag_Freeze)
	
	Display_Fade(id,2500*seconds,2500*seconds,0,0,25,255,130)
	
	log("Creating freeze entity for player %i", id)
}

public Freeze_Effect_Think(ent)
{
	new id = pev(ent,pev_owner)
	
	//Entity should be destroyed because livetime is over
	if (pev(ent,pev_ltime) < halflife_time() || !is_user_alive(id))
	{
		set_pev(id, pev_flags, pev(id, pev_flags) & ~FL_FROZEN)	
		Display_Icon(id,0,0,255,"dmg_cold",0)				
		RemoveFlag(id,Flag_Freeze)					
		return PLUGIN_CONTINUE
	}
	
	//Apply Effect
	Display_Icon(id,0,0,255,"dmg_cold",1)		
	set_pev(ent,pev_nextthink, halflife_time() + 0.3)
	
	return PLUGIN_CONTINUE
}

stock Effect_Fear(id,seconds)
{
	//Find people near and damage them
	new entlist[513]
	new numfound = find_sphere_class(id,"player",FEAR_DIST,entlist,512)
		
	for (new i=0; i < numfound; i++)
	{		
		new pid = entlist[i]
			
		if (get_user_team(pid) == get_user_team(id))
			continue
				
		Fear_Player(pid,seconds)
				
	}
}

stock Fear_Player(id,seconds)
{
	new ent = Spawn_Ent("info_target")
	set_pev(ent,pev_classname,"Effect_Fear")
	set_pev(ent,pev_owner,id)
	set_pev(ent,pev_ltime, halflife_time() + seconds + 0.1)
	set_pev(ent,pev_nextthink, halflife_time() + 0.1)
			
	AddFlag(id,Flag_Fear)
	Display_Tent(id,sprite_fear, seconds)
		
	log("Creating fear entity for player %i", id)
}

public Effect_Fear_Think(ent)
{
	new id = pev(ent,pev_owner)
	
	//Entity should be destroyed because livetime is over
	if (pev(ent,pev_ltime) < halflife_time() || !is_user_alive(id))
	{		
		if (is_user_alive(id))
		{
			Display_Icon(id,255,0,0,"dmg_gas",0)
			client_cmd(id,"-back")
		}
				
		RemoveFlag(id,Flag_Fear)
					
		return PLUGIN_CONTINUE
	}
	
	//Apply Effect
	Display_Icon(id,255,0,0,"dmg_gas",1)		
	
	//Force forward
	client_cmd(id,"-forward")
	client_cmd(id,"+back")
		
	set_pev(ent,pev_nextthink, halflife_time() + 0.1)
	
	return PLUGIN_CONTINUE
}

stock Invisible_Player(id,seconds, amount)
{
	new ent = Spawn_Ent("info_target")
	set_pev(ent,pev_classname,"Effect_Invisible")
	set_pev(ent,pev_owner,id)
	set_pev(ent,pev_ltime, halflife_time() + seconds + 0.1)
	set_pev(ent,pev_nextthink, halflife_time() + 0.1)
			
	AddFlag(id,Flag_Invisible)
	Display_Fade(id,seconds*2500,seconds*2500,0,255,255,255,60)
	set_rendering ( ent, kRenderFxNone, 0,0,0, kRenderTransAlpha, amount ) 
		
	log("Creating invisible entity for player %i", id)
}

public Effect_Invisible_Think(ent)
{
	new id = pev(ent,pev_owner)
	
	//Entity should be destroyed because livetime is over
	if (pev(ent,pev_ltime) < halflife_time() || !is_user_alive(id))
	{		
		if (is_user_alive(id))
			set_rendering ( id, kRenderFxNone, 0,0,0, kRenderFxNone, 0 ) 
			
		Display_Icon(id,0,255,100,"train_forward1",0)
		RemoveFlag(id,Flag_Invisible)					
		return PLUGIN_CONTINUE
	}
			
	Display_Icon(id,0,255,100,"train_forward1",1)
	set_pev(ent,pev_nextthink, halflife_time() + 0.1)	
	return PLUGIN_CONTINUE
}

stock Display_Icon(id,red,green,blue,name[], enable)
{
	if (!pev_valid(id))
	{
		log("Display_Icon called on bad player")
		return PLUGIN_HANDLED
	}
	
	message_begin( MSG_ONE, get_user_msgid("StatusIcon"), {0,0,0}, id ) 
	write_byte( enable ) 	
	write_string( name ) 
	write_byte( red ) // red 
	write_byte( green ) // green 
	write_byte( blue ) // blue 
	message_end()
	
	return PLUGIN_CONTINUE
}

stock Display_Fade(id,duration,holdtime,fadetype,red,green,blue,alpha)
{
	message_begin( MSG_ONE,get_user_msgid("ScreenFade"),{0,0,0},id )
	write_short( duration )	// Duration of fadeout
	write_short( holdtime )	// Hold time of color
	write_short( fadetype )	// Fade type
	write_byte ( red )		// Red
	write_byte ( green )		// Green
	write_byte ( blue )		// Blue
	write_byte ( alpha )	// Alpha
	message_end()
}


stock MakeFireTotem(id, seconds)
{
	new origin[3]
	pev(id,pev_origin,origin)
		
	new ent = Spawn_Ent("info_target")
	set_pev(ent,pev_classname,"Effect_Fire_Totem")
	set_pev(ent,pev_owner,id)
	set_pev(ent,pev_solid,SOLID_TRIGGER)
	set_pev(ent,pev_origin,origin)
	set_pev(ent,pev_ltime, halflife_time() + seconds + 0.1)
	
	engfunc(EngFunc_SetModel, ent, "models/totem_fire.mdl")  	
	set_rendering ( ent, kRenderFxGlowShell, 255,0,0, kRenderFxNone, 255 ) 	
	engfunc(EngFunc_DropToFloor,ent)
	
	set_pev(ent,pev_nextthink, halflife_time() + 0.1)
	
}

stock MakeSpiritWard(id, seconds)
{
	new origin[3]
	pev(id,pev_origin,origin)
		
	new ent = Spawn_Ent("info_target")
	set_pev(ent,pev_classname,"Effect_Spirit_Ward")
	set_pev(ent,pev_owner,id)
	set_pev(ent,pev_solid,SOLID_NOT)
	set_pev(ent,pev_origin,origin)
	set_pev(ent,pev_ltime, halflife_time() + seconds + 0.1)
	
	engfunc(EngFunc_SetModel, ent, "models/spirit_ward.mdl")  
	
	set_rendering ( ent, kRenderFxGlowShell, 255,255,255, kRenderFxNone, 100 ) 
	
	engfunc(EngFunc_DropToFloor,ent)
	
	set_pev(ent,pev_nextthink, halflife_time() + 0.1)
}


public Effect_Spirit_Ward_Think(ent)
{
	new id = pev(ent,pev_owner)
	new totem_dist = 300
	new damage_amount = 5
	
	//We have emitted beam. Apply effect (this is delayed)
	if (pev(ent,pev_euser2) == 1)
	{		

		new Float:forigin[3], origin[3]
		pev(ent,pev_origin,forigin)	
		FVecIVec(forigin,origin)
		
		//Find people near and damage them
		new entlist[513]
		new numfound = find_sphere_class(0,"player",totem_dist+0.0,entlist,512,forigin)
		
		for (new i=0; i < numfound; i++)
		{		
			new pid = entlist[i]
			
			if (get_user_team(pid) == get_user_team(id))
				continue
				
			if (is_user_alive(pid) && get_user_health(pid) - damage_amount > 0)
				Hurt_Entity(id,pid,5.0)
				
		}
		
		set_pev(ent,pev_euser2,0)
		set_pev(ent,pev_nextthink, halflife_time() + 1.5)
		
		return PLUGIN_CONTINUE
	}
	
	//Entity should be destroyed because livetime is over
	if (pev(ent,pev_ltime) < halflife_time() || !is_user_alive(id))
	{
		remove_entity(ent)
		return PLUGIN_CONTINUE
	}
	
	//If this object is almost dead, apply some render to make it fade out
	if (pev(ent,pev_ltime)-2.0 < halflife_time())
		set_rendering ( ent, kRenderFxNone, 255,255,255, kRenderTransAlpha, 100 ) 
	
	new Float:forigin[3], origin[3]
	pev(ent,pev_origin,forigin)	
	FVecIVec(forigin,origin)
					
	//Find people near and give them health
	message_begin( MSG_BROADCAST, SVC_TEMPENTITY, origin );
	write_byte( TE_BEAMCYLINDER );
	write_coord( origin[0] );
	write_coord( origin[1] );
	write_coord( origin[2] );
	write_coord( origin[0] );
	write_coord( origin[1] + totem_dist );
	write_coord( origin[2] + totem_dist );
	write_short( sprite_white );
	write_byte( 0 ); // startframe
	write_byte( 0 ); // framerate
	write_byte( 10 ); // life
	write_byte( 10 ); // width
	write_byte( 255 ); // noise
	write_byte( 255 ); // r, g, b
	write_byte( 255 ); // r, g, b
	write_byte( 255 ); // r, g, b
	write_byte( 128 ); // brightness
	write_byte( 5 ); // speed
	message_end();
	
	//Time till we apply totems effect
	set_pev(ent,pev_euser2,1)
	set_pev(ent,pev_nextthink, halflife_time() + 0.5)
	    
	return PLUGIN_CONTINUE
}


public Effect_Fire_Totem_Think(ent)
{
	new id = pev(ent,pev_owner)
	new totem_dist = 300
	new amount_healed = 5
	
	//We have emitted beam. Apply effect (this is delayed)
	if (pev(ent,pev_euser2) == 1)
	{		
		new Float:forigin[3], origin[3]
		pev(ent,pev_origin,forigin)	
		FVecIVec(forigin,origin)
		
		//Find people near and damage them
		new entlist[513]
		new numfound = find_sphere_class(0,"player",totem_dist+0.0,entlist,512,forigin)
		
		for (new i=0; i < numfound; i++)
		{		
			new pid = entlist[i]
			
			if (get_user_team(pid) != get_user_team(id))
				continue
				
				
			if (is_user_alive(pid) && get_user_health(pid) + amount_healed < 100)
				set_user_health(pid,get_user_health(pid)+amount_healed)
			else
				set_user_health(pid,100)				
		}
		
		
		set_pev(ent,pev_euser2,0)
		set_pev(ent,pev_nextthink, halflife_time() + 1.5)
		
		return PLUGIN_CONTINUE
	}
	
	
	//Entity should be destroyed because livetime is over
	if (pev(ent,pev_ltime) < halflife_time() || !is_user_alive(id))
	{
		remove_entity(ent)
		return PLUGIN_CONTINUE
	}
	
	
	
	//If this object is almost dead, apply some render to make it fade out
	if (pev(ent,pev_ltime)-2.0 < halflife_time())
		set_rendering ( ent, kRenderFxNone, 255,255,255, kRenderTransAlpha, 100 ) 
		
		
	
	new Float:forigin[3], origin[3]
	pev(ent,pev_origin,forigin)	
	FVecIVec(forigin,origin)
	
	
					
	//Find people near and give them health
	message_begin( MSG_BROADCAST, SVC_TEMPENTITY, origin );
	write_byte( TE_BEAMCYLINDER );
	write_coord( origin[0] );
	write_coord( origin[1] );
	write_coord( origin[2] );
	write_coord( origin[0] );
	write_coord( origin[1] + totem_dist );
	write_coord( origin[2] + totem_dist );
	write_short( sprite_white );
	write_byte( 0 ); // startframe
	write_byte( 0 ); // framerate
	write_byte( 10 ); // life
	write_byte( 10 ); // width
	write_byte( 255 ); // noise
	write_byte( 255 ); // r, g, b
	write_byte( 100 ); // r, g, b
	write_byte( 100 ); // r, g, b
	write_byte( 128 ); // brightness
	write_byte( 5 ); // speed
	message_end();
	
	//Time till we apply totems effect
	
	
	set_pev(ent,pev_euser2,1)
	set_pev(ent,pev_nextthink, halflife_time() + 0.5)
	
	    
	return PLUGIN_CONTINUE

}

stock MakeRogueTotem(id, seconds)
{
	new origin[3]
	pev(id,pev_origin,origin)
		
	new ent = Spawn_Ent("info_target")
	set_pev(ent,pev_classname,"Effect_Rogue_Totem")
	set_pev(ent,pev_owner,id)
	set_pev(ent,pev_solid,SOLID_TRIGGER)
	set_pev(ent,pev_origin,origin)
	set_pev(ent,pev_ltime, halflife_time() + seconds + 0.1)
	
	engfunc(EngFunc_SetModel, ent, "models/totem_rogue.mdl")  	
	set_rendering ( ent, kRenderFxGlowShell, 150,150,0, kRenderFxNone, 255 ) 	
	engfunc(EngFunc_DropToFloor,ent)
	
	set_pev(ent,pev_nextthink, halflife_time() + 0.1)
	
}

public Effect_Rogue_Totem_Think(ent)
{
	new id = pev(ent,pev_owner)
	new totem_dist = 300
	new haste_amount = 45
	
	//We have emitted beam. Apply effect (this is delayed)
	if (pev(ent,pev_euser2) == 1)
	{		
		new Float:forigin[3], origin[3]
		pev(ent,pev_origin,forigin)	
		FVecIVec(forigin,origin)
		
		//Find people near and damage them
		new entlist[513]
		new numfound = find_sphere_class(0,"player",totem_dist+0.0,entlist,512,forigin)
		
		for (new i=0; i < numfound; i++)
		{		
			new pid = entlist[i]
			
			if (get_user_team(pid) != get_user_team(id))
				continue
				
				
			//Effect, if no haste is found give haste for 5 seconds
			new ent = find_ent_by_owner(-1,"Effect_Haste",pid)
			
			if (!is_valid_ent(ent))
				Effect_Haste(pid,haste_amount,2)
			
		}
		
		
		set_pev(ent,pev_euser2,0)
		set_pev(ent,pev_nextthink, halflife_time() + 1.5)
		
		return PLUGIN_CONTINUE
	}
	
	
	//Entity should be destroyed because livetime is over
	if (pev(ent,pev_ltime) < halflife_time() || !is_user_alive(id))
	{
		remove_entity(ent)
		return PLUGIN_CONTINUE
	}
	
	
	
	//If this object is almost dead, apply some render to make it fade out
	if (pev(ent,pev_ltime)-2.0 < halflife_time())
		set_rendering ( ent, kRenderFxNone, 255,255,255, kRenderTransAlpha, 100 ) 
		
		
	
	new Float:forigin[3], origin[3]
	pev(ent,pev_origin,forigin)	
	FVecIVec(forigin,origin)
					
	//Find people near and give them health
	message_begin( MSG_BROADCAST, SVC_TEMPENTITY, origin );
	write_byte( TE_BEAMCYLINDER );
	write_coord( origin[0] );
	write_coord( origin[1] );
	write_coord( origin[2] );
	write_coord( origin[0] );
	write_coord( origin[1] + totem_dist );
	write_coord( origin[2] + totem_dist );
	write_short( sprite_white );
	write_byte( 0 ); // startframe
	write_byte( 0 ); // framerate
	write_byte( 10 ); // life
	write_byte( 10 ); // width
	write_byte( 255 ); // noise
	write_byte( 150 ); // r, g, b
	write_byte( 150 ); // r, g, b
	write_byte( 0 ); // r, g, b
	write_byte( 128 ); // brightness
	write_byte( 5 ); // speed
	message_end();
	
	//Time till we apply totems effect
	set_pev(ent,pev_euser2,1)
	set_pev(ent,pev_nextthink, halflife_time() + 0.4)
	
	    
	return PLUGIN_CONTINUE

}

stock MakePoisionDagger(id)
{
	Display_Fade(id,1000,1000,0,0,255,0,150)
	AddFlag(id,Flag_PoisionDagger)
}

stock Effect_Vengeance(id,seconds)
{
	new ent = Spawn_Ent("info_target")
	set_pev(ent,pev_classname,"Effect_Vengeance")
	set_pev(ent,pev_owner,id)
	set_pev(ent,pev_ltime, halflife_time() + seconds + 0.1)
	set_pev(ent,pev_solid,SOLID_NOT)	
	AddFlag(id,Flag_Vengeance)
	Display_Fade(id,2600,2600,0,255,0,0,150)
	set_rendering ( id, kRenderFxGlowShell, 255,0,0, kRenderFxNone, 0 ) 
	set_pev(ent,pev_nextthink, halflife_time() + 0.1)	
}

public Effect_Vengeance_Think(ent)
{
	new id = pev(ent,pev_owner)
	
	if (pev(ent,pev_ltime) < halflife_time() || !is_user_alive(id))
	{
		remove_entity(ent)
		RemoveFlag(id,Flag_Vengeance)
		Display_Icon(id,255,0,0,"item_longjump",0)
		
		if (is_user_alive(id))
			set_rendering ( id, kRenderFxNone, 0,0,0, kRenderFxNone, 0 ) 
	}
	else		
	{
		Display_Icon(id,255,0,0,"item_longjump",1)	
		set_pev(ent,pev_nextthink, halflife_time() + 0.2)
	}
	
	
}

stock Effect_Arcane_Link(id,seconds)
{
	new ent = Spawn_Ent("info_target")
	set_pev(ent,pev_classname,"Effect_Arcane_Link")
	set_pev(ent,pev_owner,id)
	set_pev(ent,pev_ltime, halflife_time() + seconds + 0.1)
	set_pev(ent,pev_solid,SOLID_NOT)	
	AddFlag(id,Flag_Arcane_Link)
	Display_Fade(id,2600,2600,50,0,200,0,40)
	set_pev(ent,pev_nextthink, halflife_time() + 0.1)	
}

public Effect_Arcane_Link_Think(ent)
{
	new id = pev(ent,pev_owner)
	
	if (pev(ent,pev_ltime) < halflife_time() || !is_user_alive(id))
	{
		remove_entity(ent)
		RemoveFlag(id,Flag_Arcane_Link)
		Display_Icon(id,50,0,200,"item_longjump",0)
	}
	else		
	{
		Display_Icon(id,50,0,200,"item_longjump",1)	
		set_pev(ent,pev_nextthink, halflife_time() + 0.2)
	}
	
}


stock Effect_Backstab(id,seconds)
{
	new ent = Spawn_Ent("info_target")
	set_pev(ent,pev_classname,"Effect_Backstab")
	set_pev(ent,pev_owner,id)
	set_pev(ent,pev_ltime, halflife_time() + seconds + 0.1)
	set_pev(ent,pev_solid,SOLID_NOT)	
	AddFlag(id,Flag_Backstab)
	Display_Fade(id,2600,2600,0,255,0,0,0)
	set_pev(ent,pev_nextthink, halflife_time() + 0.1)	
}

public Effect_Backstab_Think(ent)
{
	new id = pev(ent,pev_owner)
	
	if (pev(ent,pev_ltime) < halflife_time() || !is_user_alive(id) || !HasFlag(id,Flag_Backstab))
	{
		remove_entity(ent)
		RemoveFlag(id,Flag_Backstab)
		Display_Icon(id,255,255,0,"item_battery",0)
	}
	else		
	{
		Display_Icon(id,255,255,0,"item_battery",1)	
		set_pev(ent,pev_nextthink, halflife_time() + 0.2)
	}
	
}

stock Effect_Doublestab(id,seconds)
{
	new ent = Spawn_Ent("info_target")
	set_pev(ent,pev_classname,"Effect_Doublestab")
	set_pev(ent,pev_owner,id)
	set_pev(ent,pev_ltime, halflife_time() + seconds + 0.1)
	set_pev(ent,pev_solid,SOLID_NOT)	
	AddFlag(id,Flag_Doublestab)
	set_pev(ent,pev_nextthink, halflife_time() + 0.1)	
}

public Effect_Doublestab_Think(ent)
{
	new id = pev(ent,pev_owner)
	
	if (pev(ent,pev_ltime) < halflife_time() || !is_user_alive(id) || !HasFlag(id,Flag_Doublestab))
	{
		remove_entity(ent)
		RemoveFlag(id,Flag_Doublestab)
		Display_Icon(id,255,255,0,"item_healthkit",0)
	}
	else		
	{
		Display_Icon(id,255,255,0,"item_healthkit",1)	
		set_pev(ent,pev_nextthink, halflife_time() + 0.2)
	}
	
}


stock Effect_Focus(id,target, seconds)
{
	new ent = Spawn_Ent("info_target")
	set_pev(ent,pev_classname,"Effect_Focus")
	set_pev(ent,pev_owner,id)
	set_pev(ent,pev_ltime, halflife_time() + seconds + 0.1)
	set_pev(ent,pev_solid,SOLID_NOT)	
	AddFlag(id,Flag_Focus)
	set_pev(ent,pev_euser2,target)
	set_pev(ent,pev_nextthink, halflife_time() + 0.1)	
	focus_target[id] = target
}

public Effect_Focus_Think(ent)
{
	new id = pev(ent,pev_owner)
	new target = pev(ent,pev_euser2)
	
	if (pev(ent,pev_ltime) < halflife_time() || !is_user_alive(id) || !is_user_alive(target) || !HasFlag(id,Flag_Focus))
	{
		remove_entity(ent)
		RemoveFlag(id,Flag_Focus)
		focus_target[id] = -1
	}
	else		
	{
		Display_Fade(id,2600,2600,0,255,255,255,50)
		set_pev(ent,pev_nextthink, halflife_time() + 0.2)
	}
	
}

//Ammount can be negative, can't get haste if we are freezed/stunned/dazed
stock Effect_Haste(id,amount,seconds)
{
	if (HasFlag(id,Flag_Freeze) || HasFlag(id,Flag_Stun) || HasFlag(id,Flag_Dazed))
		return PLUGIN_CONTINUE
	
	new ent = Spawn_Ent("info_target")
	set_pev(ent,pev_classname,"Effect_Haste")
	set_pev(ent,pev_owner,id)
	set_pev(ent,pev_ltime, halflife_time() + seconds + 0.1)
	set_pev(ent,pev_solid,SOLID_NOT)	
	AddFlag(id,Flag_Haste)
	set_pev(ent,pev_nextthink, halflife_time() + 0.1)	
	
	if (get_user_maxspeed(id) + amount <= 0.0)
			set_user_maxspeed(id,1.0)
	else
		set_user_maxspeed(id,get_user_maxspeed(id)+amount+0.0)
		
	return PLUGIN_CONTINUE
}

public Effect_Haste_Think(ent)
{
	new id = pev(ent,pev_owner)

	if (pev(ent,pev_ltime) < halflife_time() || !is_user_alive(id) || !HasFlag(id,Flag_Haste))
	{
		remove_entity(ent)
		RemoveFlag(id,Flag_Haste)
		set_user_maxspeed(id,NORM_SPEED)
	}
	else		
	{		
		set_pev(ent,pev_nextthink, halflife_time() + 0.2)
	}	
}

stock MakeHunterTrap(id)
{
	new origin[3]
	pev(id,pev_origin,origin)
		
	new ent = Spawn_Ent("info_target")
	set_pev(ent,pev_classname,"Effect_Hunter_Trap")
	set_pev(ent,pev_owner,id)
	set_pev(ent,pev_ltime, 0)
	set_pev(ent,pev_origin,origin)
	set_pev(ent,pev_solid,SOLID_TRIGGER)
	
	engfunc(EngFunc_SetModel, ent, "models/hunter_trap.mdl")  
	engfunc(EngFunc_SetSize,ent,Float:{-1.0,-1.0,-1.0},Float:{1.0,1.0,1.0})
	
	drop_to_floor(ent)
}


//Spawn iceblock ONTO id for n seconds
stock Spawn_Ice_Block(id, seconds)
{
	new origin[3]
	pev(id,pev_origin,origin)
		
	new ent = Spawn_Ent("info_target")
	set_pev(ent,pev_classname,"Effect_Ice_Block")
	set_pev(ent,pev_owner,id)
	set_pev(ent,pev_ltime, halflife_time() + seconds + 0.1)
	set_pev(ent,pev_origin,origin)
	set_pev(ent,pev_solid,SOLID_NOT)
	
	engfunc(EngFunc_SetModel, ent, "models/ice_block.mdl")  
	engfunc(EngFunc_SetSize,ent,Float:{-1.0,-1.0,-1.0},Float:{1.0,1.0,1.0})
	set_rendering ( ent, kRenderFxGlowShell, 0,0,0, kRenderTransAlpha, 110 ) 
	
	drop_to_floor(ent)
	set_pev(ent,pev_nextthink, halflife_time() + 0.1)
		
	Freeze_Player(id, seconds)
	
}

public Effect_Ice_Block_Think(ent)
{
	new id = pev(ent,pev_owner)
	
	//Entity should be destroyed because livetime is over
	if (pev(ent,pev_ltime) < halflife_time() || !is_user_alive(id))
		remove_entity(ent)
	else		
		set_pev(ent,pev_nextthink, halflife_time() + 0.3)

}

//Poision Effect. Dot with damage each round damagetime = 1.5
stock Player_Poision(id, seconds, tick)
{		
	new ent = Spawn_Ent("info_target")
	set_pev(ent,pev_classname,"Effect_Poision")
	set_pev(ent,pev_owner,id)
	set_pev(ent,pev_ltime, halflife_time() + seconds + 0.1)
	set_pev(ent,pev_solid,SOLID_NOT)
	set_pev(ent,pev_nextthink, halflife_time() + 0.1)	
	set_pev(ent,pev_euser2, tick)
	set_rendering ( id, kRenderFxGlowShell, 0,200,0, kRenderFxNone, 100 ) 
	AddFlag(id,Flag_Poision)

			
}

public Effect_Poision_Think(ent)
{
	new id = pev(ent,pev_owner)
	new tick = pev(ent,pev_euser2)
	
	//Entity should be destroyed because livetime is over
	if (pev(ent,pev_ltime) < halflife_time() || !is_user_alive(id))
	{
		if (is_user_alive(id))
		{
			set_user_maxspeed(id,NORM_SPEED)
		}
		
		set_rendering ( id, kRenderFxNone, 0,0,0, kRenderFxNone, 0 ) 
		Remove_All_Tents(id)
		RemoveFlag(id,Flag_Poision)
		Display_Icon(id,0,255,0,"dmg_poison",0)	
		remove_entity(ent)
		return PLUGIN_CONTINUE
	}
	else		
		set_pev(ent,pev_nextthink, halflife_time() + 1.5)
		
	
	//If already silenced, display silence/poision tent
	if (HasFlag(id,Flag_Silence))
		Display_Tent(id,sprite_poision_silence,2)
	else
		Display_Tent(id,sprite_poison,2)
	
	//Apply poision
	if (get_user_health(id) - tick > 0)
		Hurt_Entity(0,id,tick+0.0)
		
	Display_Icon(id,0,255,0,"dmg_poison",1)	
	set_user_maxspeed(id,NORM_SPEED-60)
		
	return PLUGIN_CONTINUE
}

//Drainlife effect
stock Player_Drainlife(id, target, seconds)
{		
	new ent = Spawn_Ent("info_target")
	set_pev(ent,pev_classname,"Effect_Drainlife")
	set_pev(ent,pev_owner,id)
	set_pev(ent,pev_ltime, halflife_time() + seconds + 0.1)
	set_pev(ent,pev_solid,SOLID_NOT)
	set_pev(ent,pev_nextthink, halflife_time() + 0.1)	
	set_pev(ent,pev_euser2, target)	
			
	AddFlag(id,Flag_Drainlife)
	AddFlag(target,Flag_Drainlife)
}

//Spell Immunity
stock Player_Spell_Immunity(id, seconds)
{		
	new ent = Spawn_Ent("info_target")
	set_pev(ent,pev_classname,"Effect_Spell_Immunity")
	set_pev(ent,pev_owner,id)
	set_pev(ent,pev_ltime, halflife_time() + seconds + 0.1)
	set_pev(ent,pev_solid,SOLID_NOT)
	set_pev(ent,pev_nextthink, halflife_time() + 0.1)	
			
	AddFlag(id,Flag_SpellImmunity)
}

public Effect_Spell_Immunity_Think(ent)
{
	new id = pev(ent,pev_owner)
	if (pev(ent,pev_ltime) < halflife_time() || !is_user_alive(id))
	{
		Display_Icon(id,255,255,255,"suithelmet_empty",0)
		Remove_All_Tents(id)
		RemoveFlag(id,Flag_SpellImmunity)
		remove_entity(ent)
		return PLUGIN_CONTINUE
	}
	
	Display_Tent(id,sprite_spell_immune,1)
	Display_Icon(id,255,255,255,"suithelmet_empty",1)	
	set_pev(ent,pev_nextthink, halflife_time() + 0.5)
	return PLUGIN_CONTINUE
}


//Meditation finish cooldown on all spells
stock Effect_Meditation(id, seconds)
{		
	new ent = Spawn_Ent("info_target")
	set_pev(ent,pev_classname,"Effect_Meditation")
	set_pev(ent,pev_owner,id)
	set_pev(ent,pev_ltime, halflife_time() + seconds + 0.1)
	set_pev(ent,pev_solid,SOLID_NOT)
	set_pev(ent,pev_nextthink, halflife_time() + 0.1)	
		
	AddFlag(id,Flag_Meditation)
	
}

public Effect_Meditation_Think(ent)
{
	new id = pev(ent,pev_owner)
	if (pev(ent,pev_ltime) < halflife_time() || !is_user_alive(id))
	{
		Display_Icon(id,0,0,255,"dmg_rad",0)
		RemoveFlag(id,Flag_Meditation)
		remove_entity(ent)
		return PLUGIN_CONTINUE
	}
	
	Display_Icon(id,0,0,255,"dmg_rad",1)
	set_pev(ent,pev_nextthink, halflife_time() + 0.5)
	return PLUGIN_CONTINUE
}

//Totem explodes after x seconds. Everyone court will have incenerate on them which damage until deal
//themselves deal damage
stock Effect_Ignite_Totem(id,seconds)
{
	new origin[3]
	pev(id,pev_origin,origin)
		
	new ent = Spawn_Ent("info_target")
	set_pev(ent,pev_classname,"Effect_Ignite_Totem")
	set_pev(ent,pev_owner,id)
	set_pev(ent,pev_solid,SOLID_TRIGGER)
	set_pev(ent,pev_origin,origin)
	set_pev(ent,pev_ltime, halflife_time() + seconds + 0.1)
	
	engfunc(EngFunc_SetModel, ent, "models/totem_ignite.mdl")  	
	set_rendering ( ent, kRenderFxGlowShell, 250,150,0, kRenderFxNone, 255 ) 	
	engfunc(EngFunc_DropToFloor,ent)
	
	set_pev(ent,pev_euser3,0)
	set_pev(ent,pev_nextthink, halflife_time() + 0.1)
}

public Effect_Ignite_Totem_Think(ent)
{
	//Safe check because effect on death
	if (!freezetime_done)
		remove_entity(ent)
		
	new id = pev(ent,pev_owner)
	
	//Apply and destroy
	if (pev(ent,pev_euser3) == 1)
	{
		new entlist[513]
		new numfound = find_sphere_class(id,"player",IGNITE_DIST,entlist,512)
			
		for (new i=0; i < numfound; i++)
		{		
			new pid = entlist[i]
			
			//This totem can hit the caster
			if (pid == id && is_user_alive(id))
			{
				Effect_Ignite(pid,id,2)
				continue
			}
			
			if (!is_user_alive(pid) || get_user_team(id) == get_user_team(pid))
				continue
					
			Effect_Ignite(pid,id,2)
		}
		
		remove_entity(ent)
	}
	
	//Entity should be destroyed because livetime is over
	if (pev(ent,pev_ltime) < halflife_time())
	{
		set_pev(ent,pev_euser3,1)
		
		//Show animation and die
		
		new Float:forigin[3], origin[3]
		pev(ent,pev_origin,forigin)	
		FVecIVec(forigin,origin)
		
		//Find people near and give them health
		message_begin( MSG_BROADCAST, SVC_TEMPENTITY, origin );
		write_byte( TE_BEAMCYLINDER );
		write_coord( origin[0] );
		write_coord( origin[1] );
		write_coord( origin[2] );
		write_coord( origin[0] );
		write_coord( origin[1] + floatround(IGNITE_DIST));
		write_coord( origin[2] + floatround(IGNITE_DIST));
		write_short( sprite_white );
		write_byte( 0 ); // startframe
		write_byte( 0 ); // framerate
		write_byte( 10 ); // life
		write_byte( 10 ); // width
		write_byte( 255 ); // noise
		write_byte( 150 ); // r, g, b
		write_byte( 150 ); // r, g, b
		write_byte( 0 ); // r, g, b
		write_byte( 128 ); // brightness
		write_byte( 5 ); // speed
		message_end();
		
		set_pev(ent,pev_nextthink, halflife_time() + 0.2)
		
	}
	else	
	{
		set_pev(ent,pev_nextthink, halflife_time() + 1.5)
	}
}

//Damage over time until target does damage himself
stock Effect_Ignite(id,attacker,damage)
{
	new ent = Spawn_Ent("info_target")
	set_pev(ent,pev_classname,"Effect_Ignite")
	set_pev(ent,pev_owner,id)
	set_pev(ent,pev_ltime, halflife_time() + 99 + 0.1)
	set_pev(ent,pev_solid,SOLID_NOT)
	set_pev(ent,pev_euser1,attacker)
	set_pev(ent,pev_euser2,damage)
	set_pev(ent,pev_nextthink, halflife_time() + 0.1)	
	
	AddFlag(id,Flag_Ignite)
}

//euser3 = destroy and apply effect
public Effect_Ignite_Think(ent)
{
	new id = pev(ent,pev_owner)
	new attacker = pev(ent,pev_euser1)
	new damage = pev(ent,pev_euser2)
	
	if (pev(ent,pev_ltime) < halflife_time() || !is_user_alive(id) || !HasFlag(id,Flag_Ignite))
	{
		RemoveFlag(id,Flag_Ignite)
		Remove_All_Tents(id)
		Display_Icon(id,200,0,0,"dmg_heat",0)
		remove_entity(ent)		
		return PLUGIN_CONTINUE
	}
	
	
	//Display ignite tent and icon
	Display_Tent(id,sprite_ignite,2)
	Display_Icon(id,200,0,0,"dmg_heat",1)
	
	new origin[3]
	get_user_origin(id,origin)
	
	//Make some burning effects
	message_begin( MSG_BROADCAST,SVC_TEMPENTITY)
	write_byte( TE_SMOKE ) // 5
	write_coord(origin[0])
	write_coord(origin[1])
	write_coord(origin[2])
	write_short( sprite_smoke )
	write_byte( 22 )  // 10
	write_byte( 10 )  // 10
	message_end()
	
	//Decals
	message_begin( MSG_BROADCAST,SVC_TEMPENTITY)
	write_byte( TE_GUNSHOTDECAL ) // decal and ricochet sound
	write_coord( origin[0] ) //pos
	write_coord( origin[1] )
	write_coord( origin[2] )
	write_short (0) // I have no idea what thats supposed to be
	write_byte (random_num(199,201)) //decal
	message_end()

	
	//Do the actual damage
	Hurt_Entity(attacker,id,damage+0.0)
	
	set_pev(ent,pev_nextthink, halflife_time() + 1.5)
	
	
	return PLUGIN_CONTINUE
}

stock Effect_Implosion(id)
{
	new origin[3]
	get_user_origin(id,origin)
	
	message_begin( MSG_BROADCAST, SVC_TEMPENTITY );
	write_byte( TE_IMPLOSION );
	write_coord(origin[0]);
	write_coord(origin[1]);
	write_coord(origin[2]);
	write_byte(100);
	write_byte(20);
	write_byte(5);
	message_end();
}

//Meditation effect applied
stock Effect_Silence(id, seconds)
{		
	new ent = Spawn_Ent("info_target")
	set_pev(ent,pev_classname,"Effect_Silence")
	set_pev(ent,pev_owner,id)
	set_pev(ent,pev_ltime, halflife_time() + seconds + 0.1)
	set_pev(ent,pev_solid,SOLID_NOT)
	set_pev(ent,pev_nextthink, halflife_time() + 0.1)	
			
	AddFlag(id,Flag_Silence)
}

public Effect_Silence_Think(ent)
{
	new id = pev(ent,pev_owner)
	if (pev(ent,pev_ltime) < halflife_time() || !is_user_alive(id))
	{
		RemoveFlag(id,Flag_Silence)
		Remove_All_Tents(id)
		remove_entity(ent)		
		return PLUGIN_CONTINUE
	}
	
	set_pev(ent,pev_nextthink, halflife_time() + 1.0)
	
	//If poisioned display poision_silence
	if (HasFlag(id,Flag_Poision))
		Display_Tent(id,sprite_poision_silence,1)
	else
		Display_Tent(id,sprite_silence,1)
	return PLUGIN_CONTINUE
}

//Meditation effect applied
stock Effect_Wrath(id, seconds)
{		
	new ent = Spawn_Ent("info_target")
	set_pev(ent,pev_classname,"Effect_Wrath")
	set_pev(ent,pev_owner,id)
	set_pev(ent,pev_ltime, halflife_time() + seconds + 0.1)
	set_pev(ent,pev_solid,SOLID_NOT)
	set_pev(ent,pev_nextthink, halflife_time() + 0.1)	
	set_rendering ( id, kRenderFxGlowShell, 255,255,0, kRenderFxNone, 0 ) 
			
	AddFlag(id,Flag_Wrath)
}

public Effect_Wrath_Think(ent)
{
	new id = pev(ent,pev_owner)
	if (pev(ent,pev_ltime) < halflife_time() || !is_user_alive(id))
	{
		RemoveFlag(id,Flag_Wrath)
		Display_Icon(id,255,255,0,"suithelmet_full",0)	
		remove_entity(ent)	
		
		set_rendering ( id, kRenderFxNone, 0,0,0, kRenderFxNone, 0 ) 
			
		return PLUGIN_CONTINUE
	}
	
	Display_Icon(id,255,255,0,"suithelmet_full",1)
	set_pev(ent,pev_nextthink, halflife_time() + 1.0)	
	return PLUGIN_CONTINUE
}

//Daze player
stock Player_Daze(id,seconds)
{		
	new ent = Spawn_Ent("info_target")
	set_pev(ent,pev_classname,"Effect_Daze")
	set_pev(ent,pev_owner,id)
	set_pev(ent,pev_ltime, halflife_time() + seconds + 0.1)
	set_pev(ent,pev_solid,SOLID_NOT)
	set_pev(ent,pev_nextthink, halflife_time() + 0.1)	
			
	AddFlag(id,Flag_Dazed)
}

public Effect_Daze_Think(ent)
{
	new id = pev(ent,pev_owner)
	if (pev(ent,pev_ltime) < halflife_time() || !is_user_alive(id))
	{
		Remove_All_Tents(id)
		Display_Icon(id,255,255,0,"dmg_heat",0)	
		RemoveFlag(id,Flag_Dazed)
		set_user_maxspeed(id,NORM_SPEED)
		remove_entity(ent)
		return PLUGIN_CONTINUE
	}
	
	set_pev(ent,pev_nextthink, halflife_time() + 1.0)
	set_user_maxspeed(id,NORM_SPEED-150)
	Display_Icon(id,255,255,0,"dmg_heat",1)	
	Display_Tent(id,sprite_dazed,1)
	return PLUGIN_CONTINUE
}



public Effect_Drainlife_Think(ent)
{
	new id = pev(ent,pev_owner)
	new victim = pev(ent,pev_euser2)
				
	//Entity should be destroyed because livetime is over
	if (pev(ent,pev_ltime) < halflife_time() || !is_user_alive(id) || !is_user_alive(victim) || !Can_Trace_Line(id,victim) || !In_FOV(id,victim))
	{
		if (is_user_alive(victim))
		{
			set_rendering (victim, kRenderFxNone, 0,0,0, kRenderFxNone, 0 ) 
			set_user_maxspeed(victim,NORM_SPEED)
		}
		if (is_user_alive(id))
		{
			set_user_maxspeed(id,NORM_SPEED)
		}
		
		RemoveFlag(id,Flag_Drainlife)
		RemoveFlag(victim,Flag_Drainlife)
		remove_entity(ent)
		return PLUGIN_CONTINUE
	}
	else		
		set_pev(ent,pev_nextthink, halflife_time() + 0.3)
		
	//Apply drainlife
	if (get_user_health(victim) - 1.0 > 0)
	{
		Hurt_Entity(id,victim,1.0)
		if (get_user_health(id) < 100)
			set_user_health(id,get_user_health(id)+1)
	}
		
		
	new origin1[3]
	new origin2[3]
	
	get_user_origin(id,origin1)
	get_user_origin(victim,origin2)
	
	message_begin(MSG_BROADCAST,SVC_TEMPENTITY) 
	write_byte (TE_BEAMPOINTS)
	write_coord(origin1[0])
	write_coord(origin1[1])
	write_coord(origin1[2]+8)
	write_coord(origin2[0])
	write_coord(origin2[1])
	write_coord(origin2[2]+8)
	write_short(sprite_laser);
	write_byte(1) // framestart 
	write_byte(1) // framerate 
	write_byte(3) // life 
	write_byte(5) // width 
	write_byte(10) // noise 
	write_byte(0) // r, g, b (red)
	write_byte(255) // r, g, b (green)
	write_byte(0) // r, g, b (blue)
	write_byte(45) // brightness 
	write_byte(5) // speed 
	message_end()    
	
	set_rendering ( victim, kRenderFxGlowShell, 0,200,0, kRenderFxNone, 0 ) 
	set_user_maxspeed(victim,NORM_SPEED-100)
	set_user_maxspeed(id,NORM_SPEED-180)
	
	return PLUGIN_CONTINUE
}

//Bonus Armor, eu2 = amount, eu3 = applied
stock Player_Armoradd(id, seconds,amount)
{		
	new ent = Spawn_Ent("info_target")
	set_pev(ent,pev_classname,"Effect_Armor_Add")
	set_pev(ent,pev_owner,id)
	set_pev(ent,pev_ltime, halflife_time() + seconds + 0.1)
	set_pev(ent,pev_solid,SOLID_NOT)
	set_pev(ent,pev_nextthink, halflife_time() + 0.1)
	set_pev(ent,pev_euser2,amount)
	
	if (class_armor[id]+amount >= 0)
	{
		set_pev(ent,pev_euser3,1)
		class_armor[id]+=amount
	}
		
	set_user_armor(id,class_armor[id])
}

public Effect_Armor_Add_Think(ent)
{
	new id = pev(ent,pev_owner)
	if (pev(ent,pev_ltime) < halflife_time() || !is_user_alive(id))
	{
		new amount = pev(ent,pev_euser2)
		
		if (pev(ent,pev_euser3) == 1)
			class_armor[id]-=amount
			
		set_user_armor(id,class_armor[id])
		remove_entity(ent)
		return PLUGIN_CONTINUE
	}
	
	set_pev(ent,pev_nextthink, halflife_time() + 0.5)
	return PLUGIN_CONTINUE
}

//Sunder - removes armor
stock Player_Sunder(id, target, seconds)
{	
	new id_origin[3]
	new target_origin[3]
	
	get_user_origin(id,id_origin)
	get_user_origin(target,target_origin)
	
	if (get_distance(id_origin,target_origin) > REACH)
		return PLUGIN_CONTINUE
			
	Player_Armoradd(target,seconds, -50)
	Effect_Haste(target,-50,3)
	
	for (new i=0; i < 5; i+=2)
	{
		target_origin[z]+=i
		Display_Spark(target_origin)
	}
	
	return PLUGIN_CONTINUE
}

stock Player_Ground_Slam(id,seconds)
{
	message_begin(MSG_ONE , get_user_msgid("ScreenShake") , {0,0,0} ,id)
	write_short( 1<<14 );
	write_short( 1<<12 );
	write_short( 1<<14 );
	message_end();
		
	new entlist[513]
	new numfound = find_sphere_class(id,"player",SLAM_RADIUS,entlist,512)
		
	
	for (new i=0; i < numfound; i++)
	{		
		new pid = entlist[i]
			
		if (pid == id || !is_user_alive(pid))
			continue
			
		if (get_user_team(id) == get_user_team(pid))
			continue
			
		new Float:id_origin[3]
		new Float:pid_origin[3]
		new Float:delta_vec[3]
		
		pev(id,pev_origin,id_origin)
		pev(pid,pev_origin,pid_origin)
		
		delta_vec[x] = (pid_origin[x]-id_origin[x])+10
		delta_vec[y] = (pid_origin[y]-id_origin[y])+10
		delta_vec[z] = (pid_origin[z]-id_origin[z])+200
		
		set_pev(pid,pev_velocity,delta_vec)
						
		message_begin(MSG_ONE , get_user_msgid("ScreenShake") , {0,0,0} ,pid)
		write_short( 1<<14 );
		write_short( 1<<12 );
		write_short( 1<<14 );
		message_end();
				
		Player_Daze(pid,seconds)
				
	}
	
		
}

//Sunder Armor - Will remove all of players armor temporarily
stock Player_Enrage(id, target, seconds)
{		
	new ent = Spawn_Ent("info_target")
	set_pev(ent,pev_classname,"Effect_Enrage")
	set_pev(ent,pev_owner,id)
	set_pev(ent,pev_ltime, halflife_time() + seconds + 0.1)
	set_pev(ent,pev_solid,SOLID_NOT)
	set_pev(ent,pev_nextthink, halflife_time() + 0.1)	
	
	//Add marked effect to player
	Player_Marked(id,target,seconds)
	Player_Armoradd(id,seconds,25)
	Player_Armoradd(id,seconds,25)
	AddFlag(id,Flag_Enrage)
	
	Display_Fade(id,seconds*2600,seconds*2600,0,255,0,0,45)
	
}

public Effect_Enrage_Think(ent)
{
	new id = pev(ent,pev_owner)
	new target = pev(ent,pev_euser2)
	
	if (pev(ent,pev_ltime) < halflife_time() || !is_user_alive(id) || !is_user_alive(target))
	{
		set_user_maxspeed(id,NORM_SPEED)
		RemoveFlag(id,Flag_Enrage)
		remove_entity(ent)	
		return PLUGIN_CONTINUE
	}
		
	set_user_maxspeed(id,NORM_SPEED+135)
	set_pev(ent,pev_nextthink, halflife_time() + 0.5)
	return PLUGIN_CONTINUE
}

//Renew - Regains healing over time
stock Player_Renew(id, seconds)
{		
	new ent = Spawn_Ent("info_target")
	set_pev(ent,pev_classname,"Effect_Renew")
	set_pev(ent,pev_owner,id)
	set_pev(ent,pev_ltime, halflife_time() + seconds + 0.1)
	set_pev(ent,pev_solid,SOLID_NOT)
	set_pev(ent,pev_nextthink, halflife_time() + 0.1)	
	
	AddFlag(id,Flag_Renew)
	
	
}

public Effect_Renew_Think(ent)
{
	new id = pev(ent,pev_owner)
	
	if (pev(ent,pev_ltime) < halflife_time() || !is_user_alive(id))
	{
		RemoveFlag(id,Flag_Renew)
		remove_entity(ent)	
		return PLUGIN_CONTINUE
	}
		
	Display_Fade(id,2600,2600,0,0,255,50,15)
	
	if (get_user_health(id) + 4 <= 100)
		set_user_health(id,get_user_health(id)+4)
	else
		set_user_health(id,100)
	
	set_pev(ent,pev_nextthink, halflife_time() + 1.5)
	return PLUGIN_CONTINUE
}


//Marked. Owner = Marked
stock Player_Marked(marker, marked, seconds)
{		
	new ent = Spawn_Ent("info_target")
	set_pev(ent,pev_classname,"Effect_Mark")
	set_pev(ent,pev_owner,marked)
	set_pev(ent,pev_ltime, halflife_time() + seconds + 0.1)
	set_pev(ent,pev_solid,SOLID_NOT)
	set_pev(ent,pev_nextthink, halflife_time() + 0.1)	
	set_pev(ent,pev_euser2,marker)
	
	Display_Tent(marked,sprite_mark,seconds)
}

public Effect_Mark_Think(ent)
{
	new id = pev(ent,pev_owner)
	if (pev(ent,pev_ltime) < halflife_time() || !is_user_alive(id))
	{
		set_user_maxspeed(id,NORM_SPEED)
		Remove_All_Tents(id)
		remove_entity(ent)
		return PLUGIN_CONTINUE
	}
	
	set_user_maxspeed(id,NORM_SPEED-20)
	set_pev(ent,pev_nextthink, halflife_time() + 0.1)
	return PLUGIN_CONTINUE
}

//Fires a chainlightning from id, to target doing damage where team = teamtarget
stock Effect_Chainlightning(id,target,Float:damage,teamtarget)
{
	new targets[MAX]
	new targetsize = 0		
	new origin1[3]
	new origin2[3]
	
	targets[targetsize] = target
	targetsize++
			
	Display_Fade(id,2600,2600,0,255,255,50,30)
	
	//Find opponent closest to player and apply chainlightning there also, if we can traceline
	new entlist[513]
	new numfound = find_sphere_class(id,"player",LIGHTNING_RADIUS,entlist,512)
			
	for (new i=0; i < numfound; i++)
	{		
		new pid = entlist[i]
			
		if (pid == id || pid == target || !is_user_alive(pid) || get_user_team(pid) != teamtarget)
			continue
			
		if (!Can_Trace_Line(id,pid))
			continue
			
		targets[targetsize] = pid
		targetsize++
	}
	
	//Amplify damage
	damage+=targetsize*4
	
	//Apply damage and show animation
	for (new i=0; i < targetsize; i++)
	{
		new pid = targets[i]
		
		get_user_origin(id,origin1)
		get_user_origin(pid,origin2)
		
		message_begin(MSG_BROADCAST,SVC_TEMPENTITY) 
		write_byte (TE_BEAMPOINTS)
		write_coord(origin1[0])
		write_coord(origin1[1])
		write_coord(origin1[2]+8)
		write_coord(origin2[0])
		write_coord(origin2[1])
		write_coord(origin2[2]+8)
		write_short(sprite_laser);
		write_byte(1) // framestart 
		write_byte(1) // framerate 
		write_byte(3) // life 
		write_byte(15) // width 
		write_byte(10) // noise 
		write_byte(255) // r, g, b (red)
		write_byte(255) // r, g, b (green)
		write_byte(255) // r, g, b (blue)
		write_byte(45) // brightness 
		write_byte(5) // speed 
		message_end()  
		
		Hurt_Entity(id,pid,damage)
	}
	
	return PLUGIN_CONTINUE
	
}

//While there's sight between the target and the healer (id) and the target is under 100 hp
//the healing connection will be sustrained and the target will be healed slowly
stock Effect_Heal(id,target,seconds,tick)
{
	new ent = Spawn_Ent("info_target")
	set_pev(ent,pev_classname,"Effect_Heal")
	set_pev(ent,pev_owner,id)
	set_pev(ent,pev_ltime, halflife_time() + seconds + 0.1)
	set_pev(ent,pev_solid,SOLID_NOT)
	set_pev(ent,pev_nextthink, halflife_time() + 0.1)	
	set_pev(ent,pev_euser2, target)	
	set_pev(ent,pev_euser3, tick)
			
	AddFlag(id,Flag_Heal)
	AddFlag(target,Flag_Heal)
}

public Effect_Heal_Think(ent)
{
	new id = pev(ent,pev_owner)
	new victim = pev(ent,pev_euser2)
	new tick = pev(ent,pev_euser3)
	
	//Do once first to indicate we're healing
	new origin1[3]
	new origin2[3]
	
	get_user_origin(id,origin1)
	get_user_origin(victim,origin2)
	
	message_begin(MSG_BROADCAST,SVC_TEMPENTITY) 
	write_byte (TE_BEAMPOINTS)
	write_coord(origin1[0])
	write_coord(origin1[1])
	write_coord(origin1[2]+8)
	write_coord(origin2[0])
	write_coord(origin2[1])
	write_coord(origin2[2]+8)
	write_short(sprite_white);
	write_byte(1) // framestart 
	write_byte(1) // framerate 
	write_byte(3) // life 
	write_byte(5) // width 
	write_byte(30) // noise 
	write_byte(150) // r, g, b (red)
	write_byte(150) // r, g, b (green)
	write_byte(0) // r, g, b (blue)
	write_byte(45) // brightness 
	write_byte(5) // speed 
	message_end()    
				
	//Entity should be destroyed because livetime is over
	if (pev(ent,pev_ltime) < halflife_time() || !is_user_alive(id) || !is_user_alive(victim) || !Can_Trace_Line(id,victim) || !In_FOV(id,victim) || get_user_health(victim)+tick >= 100)
	{		
		RemoveFlag(id,Flag_Heal)
		RemoveFlag(victim,Flag_Heal)
		
		if (is_user_alive(victim) && get_user_health(victim)+tick >= 100)
			set_user_health(victim,100)
			
		if (is_user_alive(victim))
			set_rendering ( victim, kRenderFxNone, 0,0,0, kRenderFxNone, 0 ) 
			
		remove_entity(ent)
		return PLUGIN_CONTINUE
	}
	else
	{			
		set_pev(ent,pev_nextthink, halflife_time() + 0.3)
	}
		
	set_user_health(victim,get_user_health(victim)+tick)
	
	if (get_user_health(id)+tick >= 100)
		set_user_health(id,100)
	else
		set_user_health(id,get_user_health(id)+tick)
			
	get_user_origin(id,origin1)
	get_user_origin(victim,origin2)
	
	message_begin(MSG_BROADCAST,SVC_TEMPENTITY) 
	write_byte (TE_BEAMPOINTS)
	write_coord(origin1[0])
	write_coord(origin1[1])
	write_coord(origin1[2]+8)
	write_coord(origin2[0])
	write_coord(origin2[1])
	write_coord(origin2[2]+8)
	write_short(sprite_white);
	write_byte(1) // framestart 
	write_byte(1) // framerate 
	write_byte(3) // life 
	write_byte(5) // width 
	write_byte(30) // noise 
	write_byte(150) // r, g, b (red)
	write_byte(150) // r, g, b (green)
	write_byte(0) // r, g, b (blue)
	write_byte(45) // brightness 
	write_byte(5) // speed 
	message_end()    
	
	set_rendering ( victim, kRenderFxGlowShell, 150,150,0, kRenderFxNone, 0 ) 
	
	return PLUGIN_CONTINUE
}

//Make id bleed and apply some damage
stock Effect_Bleed(attacker,id,amount,color)
{
	new origin[3]
	get_user_origin(id,origin)
	
	Hurt_Entity(attacker,id,amount+0.0)
	
	new dx, dy, dz

	for(new i = 0; i < 3; i++) 
	{
		dx = random_num(-15,15)
		dy = random_num(-15,15)
		dz = random_num(-20,25)
		
		for(new j = 0; j < 2; j++) 
		{
			message_begin(MSG_BROADCAST,SVC_TEMPENTITY)
			write_byte(TE_BLOODSPRITE)
			write_coord(origin[0]+(dx*j))
			write_coord(origin[1]+(dy*j))
			write_coord(origin[2]+(dz*j))
			write_short(sprite_blood_spray)
			write_short(sprite_blood_drop)
			write_byte(color) // color index
			write_byte(15) // size
			message_end()
		}
	}
}

stock Effect_Punch(id,dx,dy,dz)
{
	if (!is_valid_ent(id))
		return PLUGIN_CONTINUE
		
	new Float:punch[3]
	punch[x] = dx+0.0
	punch[y] = dy+0.0
	punch[z] = dz+0.0
		
	set_pev(id,pev_punchangle,punch)

	return PLUGIN_CONTINUE
}

stock Effect_Teleport(id,distance)
{
	
	Set_Origin_Forward(id,distance)
	
	new origin[3]
	get_user_origin(id,origin)
	
	//Particle burst ie. teleport effect	
	message_begin(MSG_BROADCAST ,SVC_TEMPENTITY) //message begin
	write_byte(TE_PARTICLEBURST )
	write_coord(origin[0]) // origin
	write_coord(origin[1]) // origin
	write_coord(origin[2]) // origin
	write_short(20) // radius
	write_byte(1) // particle color
	write_byte(4) // duration * 10 will be randomized a bit
	message_end()

	
}

stock Effect_Poision_Nova(id, seconds)
{
	new origin[3]
	get_user_origin(id,origin)
	
	//Effect
	message_begin( MSG_BROADCAST, SVC_TEMPENTITY, origin );
	write_byte( TE_BEAMCYLINDER );
	write_coord( origin[0] );
	write_coord( origin[1] );
	write_coord( origin[2] );
	write_coord( origin[0] );
	write_coord( origin[1] + POISION_NOVA_DIST );
	write_coord( origin[2] + POISION_NOVA_DIST );
	write_short( sprite_laser );
	write_byte( 0 ); // startframe
	write_byte( 0 ); // framerate
	write_byte( 10 ); // life
	write_byte( 10 ); // width
	write_byte( 255 ); // noise
	write_byte( 0 ); // r, g, b
	write_byte( 255 ); // r, g, b
	write_byte( 0 ); // r, g, b
	write_byte( 128 ); // brightness
	write_byte( 5 ); // speed
	message_end();
	
	message_begin( MSG_BROADCAST, SVC_TEMPENTITY, origin );
	write_byte( TE_BEAMCYLINDER );
	write_coord( origin[0] );
	write_coord( origin[1] );
	write_coord( origin[2] );
	write_coord( origin[0] );
	write_coord( origin[1] + POISION_NOVA_DIST-50 );
	write_coord( origin[2] + POISION_NOVA_DIST-50 );
	write_short( sprite_laser );
	write_byte( 0 ); // startframe
	write_byte( 0 ); // framerate
	write_byte( 10 ); // life
	write_byte( 10 ); // width
	write_byte( 255 ); // noise
	write_byte( 0 ); // r, g, b
	write_byte( 150 ); // r, g, b
	write_byte( 0 ); // r, g, b
	write_byte( 128 ); // brightness
	write_byte( 6 ); // speed
	message_end();
		
	new entlist[513]
	new numfound = find_sphere_class(id,"player",POISION_NOVA_DIST+0.0,entlist,512)
			
	for (new i=0; i < numfound; i++)
	{		
		new pid = entlist[i]
			
		if (pid == id || !is_user_alive(pid) || get_user_team(id) == get_user_team(pid))
			continue
					
		Player_Poision(pid,seconds,3)				
	}
			
}

stock Start_Game_Config()
{
	new ent = Spawn_Ent("info_target")
	set_pev(ent,pev_classname,"Game_Config")
	set_pev(ent,pev_owner,0)
	set_pev(ent,pev_nextthink, halflife_time() + 0.1)
				
	new ent1 = Spawn_Ent("info_target")
	set_pev(ent1,pev_owner,0)
	set_pev(ent1,pev_nextthink, halflife_time() + 0.1)
	
	log("Game Config Created")
}

public Game_Config_Think(ent)
{
	//Update mana on all players
	for (new i=0; i < MAX; i++)
	{
		if (is_user_alive(i))
		{

		}
	}
	
	set_pev(ent,pev_nextthink, halflife_time() + 5.0)	

}


stock AddFlag(id,flag)
{
	afflicted[id][flag] = 1	
}

stock RemoveFlag(id,flag)
{
	afflicted[id][flag] = 0
}

stock bool:HasFlag(id,flag)
{
	if (afflicted[id][flag])
		return true
	
	return false
}

stock ResetFlags(id)
{
	for (new i=0; i < Flag_Max; i++)
	{
		afflicted[id][i] = 0
		focus_target[id] = 0
	}
}

stock Display_Spark(Origin[]) 
{
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY);
	write_byte(TE_SPARKS);
	write_coord(Origin[x]);
	write_coord(Origin[y]);
	write_coord(Origin[z]);
	message_end();
}

stock Display_Tent(id,sprite, seconds)
{
	message_begin(MSG_ALL,SVC_TEMPENTITY)
	write_byte(TE_PLAYERATTACHMENT)
	write_byte(id)
	write_coord(40) //Offset
	write_short(sprite)
	write_short(seconds*10)
	message_end()
}

stock Remove_All_Tents(id)
{
	message_begin(MSG_ALL ,SVC_TEMPENTITY) //message begin
	write_byte(TE_KILLPLAYERATTACHMENTS)
	write_byte(id) // entity index of player
	message_end()
}

stock Set_Origin_Forward(id, distance) 
{
	new Float:origin[3]
	new Float:angles[3]
	new Float:teleport[3]
	new Float:heightplus = 10.0
	new Float:playerheight = 64.0
	new bool:recalculate = false
	new bool:foundheight = false
	pev(id,pev_origin,origin)
	pev(id,pev_angles,angles)
	
	teleport[0] = origin[0] + distance * floatcos(angles[1],degrees) * floatabs(floatcos(angles[0],degrees));
	teleport[1] = origin[1] + distance * floatsin(angles[1],degrees) * floatabs(floatcos(angles[0],degrees));
	teleport[2] = origin[2]+heightplus
	
	while (!Can_Trace_Line_Origin(origin,teleport) || Is_Point_Stuck(teleport,48.0))
	{	
		if (distance < 10)
			break;
			
		//First see if we can raise the height to MAX playerheight, if we can, it's a hill and we can teleport there	
		for (new i=1; i < playerheight+20.0; i++)
		{
			teleport[2]+=i
			if (Can_Trace_Line_Origin(origin,teleport) && !Is_Point_Stuck(teleport,48.0))
			{
				foundheight = true
				heightplus += i
				break
			}
			
			teleport[2]-=i
		}
		
		if (foundheight)
			break
			
		recalculate = true
		distance-=10
		teleport[0] = origin[0] + (distance+32) * floatcos(angles[1],degrees) * floatabs(floatcos(angles[0],degrees));
		teleport[1] = origin[1] + (distance+32) * floatsin(angles[1],degrees) * floatabs(floatcos(angles[0],degrees));
		teleport[2] = origin[2]+heightplus
	}
		
	if (!recalculate)
	{
		set_pev(id,pev_origin,teleport)
		return PLUGIN_CONTINUE
	}
		
	teleport[0] = origin[0] + distance * floatcos(angles[1],degrees) * floatabs(floatcos(angles[0],degrees));
	teleport[1] = origin[1] + distance * floatsin(angles[1],degrees) * floatabs(floatcos(angles[0],degrees));
	teleport[2] = origin[2]+heightplus
	set_pev(id,pev_origin,teleport)
	
	return PLUGIN_CONTINUE
}


//3D Area Stuck Control
stock bool:Is_Point_Stuck(Float:Origin[3], Float:hullsize)
{
	new Float:temp[3]
	new Float:iterator = hullsize/3
	
	temp[2] = Origin[2]
		
	for (new Float:i=Origin[0]-hullsize; i < Origin[0]+hullsize; i+=iterator)
	{
		for (new Float:j=Origin[1]-hullsize; j < Origin[1]+hullsize; j+=iterator)
		{
			//72 mod 6 = 0
			for (new Float:k=Origin[2]-CS_PLAYER_HEIGHT; k < Origin[2]+CS_PLAYER_HEIGHT; k+=6) 
			{
				temp[0] = i
				temp[1] = j
				temp[2] = k
						
				if (point_contents(temp) != -1)
					return true
			}
		}
	}
	
	return false
}
	
stock Set_Aiming( CoreID, TargetID )
{
	new Float:CoreAngles[3] = { 0.0, 0.0, 0.0 };
	
	new Float:CoreOrigin[3];
	pev(CoreID, pev_origin, CoreOrigin );
	
	new Float:TargetOrigin[3];
	pev(TargetID, pev_origin, TargetOrigin );
	
	new anglemode:Mode = degrees;
	
	new Float:DeltaOrigin[3];
	for ( new i = 0; i < 3; i++ )
		DeltaOrigin[i] = CoreOrigin[i] - TargetOrigin[i];
	    
	CoreAngles[x] = floatatan( DeltaOrigin[z] / Distance2D( DeltaOrigin[x], DeltaOrigin[y] ), Mode ) ;
	CoreAngles[y] = floatatan( DeltaOrigin[y] / DeltaOrigin[x], Mode );
	
	( DeltaOrigin[x] >= 0.0 ) ? ( CoreAngles[y] += 180.0 ): ( CoreAngles[y] += 0.0 )
	
	set_pev(CoreID, pev_angles, CoreAngles,3 );
	set_pev(CoreID, pev_fixangle, 1 );
} 

stock Find_Best_Angle(id,Float:dist, same_team = false)
{
	new Float:bestangle = 0.0
	new winner = -1
	
	for (new i=0; i < MAX; i++)
	{
		if (!is_user_alive(i) || i == id || (get_user_team(i) == get_user_team(id) && !same_team))
			continue
			
		if (get_user_team(i) != get_user_team(id) && same_team)
			continue
			
		//User has spell immunity, don't target
		
		new Float:c_angle = Find_Angle(id,i,dist)
				
		if (c_angle > bestangle && Can_Trace_Line(id,i))
		{
			winner = i
			bestangle = c_angle
		}
		
	}
	
	return winner
}


stock Float:Find_Angle(Core,Target,Float:dist)
{
	new Float:vec2LOS[2]
	new Float:flDot	
	new Float:CoreOrigin[3]
	new Float:TargetOrigin[3]
	new Float:CoreAngles[3]
	
	pev(Core,pev_origin,CoreOrigin)
	pev(Target,pev_origin,TargetOrigin)
	
	if (get_distance_f(CoreOrigin,TargetOrigin) > dist)
		return 0.0
	
	pev(Core,pev_angles, CoreAngles)
	
	for ( new i = 0; i < 2; i++ )
		vec2LOS[i] = TargetOrigin[i] - CoreOrigin[i]
		
	new Float:veclength = Vec2DLength(vec2LOS)
	
	//Normalize V2LOS
	if (veclength <= 0.0)
	{
		vec2LOS[x] = 0.0
		vec2LOS[y] = 0.0
	}
	else
	{
		new Float:flLen = 1.0 / veclength;
		vec2LOS[x] = vec2LOS[x]*flLen
		vec2LOS[y] = vec2LOS[y]*flLen
	}
	
	//Do a makevector to make v_forward right
	engfunc(EngFunc_MakeVectors,CoreAngles)
	
	new Float:v_forward[3]
	new Float:v_forward2D[2]
	get_global_vector(GL_v_forward, v_forward)
	
	v_forward2D[x] = v_forward[x]
	v_forward2D[y] = v_forward[y]

	flDot = vec2LOS[x]*v_forward2D[x]+vec2LOS[y]*v_forward2D[y]
	
	if ( flDot > 0.5 )
	{
		return flDot
	}

	return 0.0
	
}

stock In_FOV(id,target)
{
	if (Find_Angle(id,target,9999.9) > 0.0)
		return true
	
	return false
}

//This is an interpolation. We make tree lines with different height as to make sure
stock bool:Can_Trace_Line(id, target)
{	
	for (new i=-35; i < 60; i+=35)
	{		
		new Float:Origin_Id[3]
		new Float:Origin_Target[3]
		new Float:Origin_Return[3]
		
		pev(id,pev_origin,Origin_Id)
		pev(target,pev_origin,Origin_Target)
		
		Origin_Id[z] = Origin_Id[z] + i
		Origin_Target[z] = Origin_Target[z] + i
		
		trace_line(-1, Origin_Id, Origin_Target, Origin_Return) 
		
		if (get_distance_f(Origin_Return,Origin_Target) < 25.0)
			return true
		
	}
	
	return false
}

stock bool:Can_Trace_Line_Origin(Float:origin1[3], Float:origin2[3])
{	
	new Float:Origin_Return[3]	
	new Float:temp1[3]
	new Float:temp2[3]
	
	temp1[x] = origin1[x]
	temp1[y] = origin1[y]
	temp1[z] = origin1[z]-30
	
	temp2[x] = origin2[x]
	temp2[y] = origin2[y]
	temp2[z] = origin2[z]-30
	
	trace_line(-1, temp1, temp2, Origin_Return) 
		
	if (get_distance_f(Origin_Return,temp2) < 1.0)
		return true
			
	return false
}


//Select and setup the class
//1 = FORWARD+USE , 2 = BACK+USE , 3 = RELOAD + FORWARD, 4 = RELOAD + BACK , 5 = RELOAD+USE
public mh_Selectyourclass(id, menu, item) 
{
	item++
	
	//User pressed exit
	if (item < 0)
	{
		return PLUGIN_CONTINUE
	}
	
	if (player_class[id] == item && item > 0)
	{
		client_print(id,print_chat, "You already are this class. Please select another")
		return PLUGIN_CONTINUE
	}
	
	//We changed to another class. And we are alive. KIll the player and change class
	if (player_class[id] > 0 && is_user_alive(id))
			set_user_health(id,-1)
	
	if (item < Class_Max)
	{
		player_class[id] = item
		
		switch(player_class[id])
		{
			case Class_Necromancer:
			{
				player_spell[id][0] = Spell_Poison_Dagger
				player_spell[id][1] = Spell_Fear
				player_spell[id][2] = Spell_Drainlife
				player_spell[id][3] = Spell_Spirit_Ward
				player_spell[id][4] = Spell_Shadow_Veil
				
				class_armor[id] = 35
			}
			
			case Class_Warrior:
			{
				player_spell[id][0] = Spell_Sunder
				player_spell[id][1] = Spell_Bark_Skin
				player_spell[id][2] = Spell_Enrage
				player_spell[id][3] = Spell_Fire_Totem
				player_spell[id][4] = Spell_Wrath
				
				class_armor[id] = 75
			}
			
			case Class_Cleric:
			{
				player_spell[id][0] = Spell_Ground_Slam
				player_spell[id][1] = Spell_Natures_Blessing	//RENEW
				player_spell[id][2] = Spell_Force_Of_Nature	//lightning
				player_spell[id][3] = Spell_Natures_Will	//healing
				player_spell[id][4] = Spell_Vengeance
				
				class_armor[id] = 50
			}
			
			case Class_Rogue:
			{
				player_spell[id][0] = Spell_Focus
				player_spell[id][1] = Spell_Lurk
				player_spell[id][2] = Spell_Backstab
				player_spell[id][3] = Spell_Ground_Totem
				player_spell[id][4] = Spell_Stab
				
				class_armor[id] = 40
			}
			
			case Class_Archmage:
			{
				player_spell[id][0] = Spell_Blink
				player_spell[id][1] = Spell_Silence
				player_spell[id][2] = Spell_Nova
				player_spell[id][3] = Spell_Ignite_Totem
				player_spell[id][4] = Spell_Arcane_Link
				
				class_armor[id] = 10
			}
			
		}
		
		//Give some game info
		new name[32]
		get_user_name(id,name,31)
		client_print(id,print_chat, "Welcome %s(%s) to the knifearena beta v. 1.0! Say /info for spell and class information", name, Class_Names[player_class[id]])
			
	}
	
	return PLUGIN_CONTINUE
}

public ma_Selectyourclass(id) 
{
}

public mcb_Selectyourclass(id, menu, item) 
{
}

/* -------------------------------------------------------------------------------------------------
*						
*						Spell System 
*
* ------------------------------------------------------------------------------------------------*/


	
stock Cast_Spell(id,num)
{
	//No spells and no warnings if we're dead
	if (!is_user_alive(id))
		return PLUGIN_CONTINUE
		
	//Cooldown control
	if (player_global_cooldown[id] + GLOBAL_COOLDOWN >= halflife_time())
		return PLUGIN_CONTINUE
	else
		player_global_cooldown[id] = halflife_time()
		
	//Freezetime control
	if (!freezetime_done)
	{
		hudmsg(id,2.0,"Unable to cast spells when dead or before round start")
		return PLUGIN_CONTINUE
	}
		
	//We are silenced
	if (HasFlag(id,Flag_Silence))
	{
		hudmsg(id,2.0,"Can't cast spells when silenced")
		return PLUGIN_CONTINUE
	}
	
	
	//Cooldown on spell
	if (player_casttime[id][num] > halflife_time())
	{
		new spell = player_spell[id][num]		
		hudmsg(id,2.0,"%s not ready yet. Cooldown remaining: %i", Spell_Names[spell], floatround(player_casttime[id][num] - halflife_time()))
		return PLUGIN_CONTINUE
	}
	
	new Float:spelltime = Spell_Casttime[player_spell[id][num]]
	
	
	switch (player_spell[id][num])
	{	
		case Spell_Poison_Dagger: { 
			MakePoisionDagger(id)
			player_casttime[id][num] = halflife_time()+spelltime
		}
		
		case Spell_Fear: {
			Effect_Fear(id,5)
			player_casttime[id][num] = halflife_time()+spelltime
		}
		
		case Spell_Drainlife: {
			new target = Find_Best_Angle(id,DRAINLIFE_DIST)
		
			if (pev_valid(target))
			{
				Player_Drainlife(id,target,5)
				player_casttime[id][num] = halflife_time()+spelltime
			}
			else
				hudmsg(id,2.0,"Drainlife: No target")
		}
		
		case Spell_Spirit_Ward: {
			MakeSpiritWard(id,10)
			player_casttime[id][num] = halflife_time()+spelltime
		}
		
		case Spell_Shadow_Veil: {
			Invisible_Player(id,5,10)
			player_casttime[id][num] = halflife_time()+spelltime
		}
		
		case Spell_Bark_Skin: {
			Player_Spell_Immunity(id,10)
			player_casttime[id][num] = halflife_time()+spelltime
		}
		
		case Spell_Sunder: {
			new target = Find_Best_Angle(id,REACH+0.0)
		
			if (pev_valid(target))
			{
				Player_Sunder(id,target,10)
				player_casttime[id][num] = halflife_time()+spelltime
			}
			else
				hudmsg(id,2.0,"Sunder: No target")
		}
		
		case Spell_Enrage: {
			new target = Find_Best_Angle(id,9999.9)
		
			if (pev_valid(target))
			{
				Player_Enrage(id,target,7)
				player_casttime[id][num] = halflife_time()+spelltime
			}
			else
				hudmsg(id,2.0,"Enrage: No target")
		}
		
		case Spell_Fire_Totem: {
			MakeFireTotem(id,10)
			player_casttime[id][num] = halflife_time()+spelltime
		}
		
		case Spell_Wrath: {
			Effect_Wrath(id,10)
			player_casttime[id][num] = halflife_time()+spelltime
		}
		
		case Spell_Ground_Slam: {
			Player_Ground_Slam(id,3)
			player_casttime[id][num] = halflife_time()+spelltime
		}
			
		case Spell_Natures_Blessing: {
			Player_Renew(id,5)
			player_casttime[id][num] = halflife_time()+spelltime
		}
		
		case Spell_Force_Of_Nature: {
			new target = Find_Best_Angle(id,LIGHTNING_REACH)
		
			if (pev_valid(target))
			{
				Effect_Chainlightning(id,target,35.0,get_user_team(target))
				player_casttime[id][num] = halflife_time()+spelltime
			}
			else
				hudmsg(id,2.0,"Force Of Nature: No target")
		}
		
		case Spell_Natures_Will: {
			new target = Find_Best_Angle(id,HEAL_REACH,true)
		
			if (pev_valid(target))
			{
				Effect_Heal(id,target,25,2)
				player_casttime[id][num] = halflife_time()+spelltime
			}
			else
				hudmsg(id,2.0,"Heal: No target")
		}
		
		case Spell_Vengeance: {
			Effect_Vengeance(id,10)
			player_casttime[id][num] = halflife_time()+spelltime
		}
		
		case Spell_Focus: {
			new target = Find_Best_Angle(id,9999.9)
		
			if (pev_valid(target))
			{
				player_casttime[id][num] = halflife_time()+spelltime
				Effect_Focus(id,target,25)
			}
			else
				hudmsg(id,2.0,"Focus: No target")
		}
		
		case Spell_Lurk: {
			player_casttime[id][num] = halflife_time()+spelltime
			Invisible_Player(id,5,10)
		}
		
		case Spell_Backstab: {
			player_casttime[id][num] = halflife_time()+spelltime
			Effect_Backstab(id,10)
		}
		
		case Spell_Ground_Totem: {
			player_casttime[id][num] = halflife_time()+spelltime
			MakeRogueTotem(id,10)
		}
		
		case Spell_Stab: {
			player_casttime[id][num] = halflife_time()+spelltime
			Effect_Doublestab(id,15)
		}
		
		case Spell_Blink: {
			player_casttime[id][num] = halflife_time()+spelltime
			Effect_Teleport(id,BLINK_DIST)
		}
		
		case Spell_Meditation: {
			player_casttime[id][num] = halflife_time()+spelltime
			Effect_Meditation(id,10)
		}
		
		case Spell_Nova: {
			player_casttime[id][num] = halflife_time()+spelltime
			Effect_Poision_Nova(id,10)
		}
		
		case Spell_Silence: {
			new target = Find_Best_Angle(id,SILENCE_DIST)
		
			if (pev_valid(target))
			{
				Effect_Silence(target,10)
				player_casttime[id][num] = halflife_time()+spelltime
			}
			else
				hudmsg(id,2.0,"Silence: No target")
		}
		
		case Spell_Arcane_Link: {
			Effect_Arcane_Link(id,10)
			player_casttime[id][num] = halflife_time()+spelltime
		}
		
		case Spell_Ignite_Totem: {
			Effect_Ignite_Totem(id,5)
			player_casttime[id][num] = halflife_time()+spelltime
		}
				
	}	
	
	return PLUGIN_CONTINUE
}

stock Log_Kill(killer, victim, weapon[],headshot) 
{
	new id = victim

	set_msg_block(get_user_msgid("DeathMsg"),BLOCK_ONCE)
	set_user_health(id,-1)
	set_msg_block(get_user_msgid("DeathMsg"),BLOCK_NOT)
	message_begin(MSG_ALL, get_user_msgid("DeathMsg"), {0,0,0}, 0)
	write_byte(killer)
	write_byte(victim)
	write_byte(headshot)
	write_string(weapon)
	message_end()
	new frags = get_user_frags(killer)
	set_user_frags(killer,frags+1)
	
	/* Update scoreboard also */
	message_begin(MSG_ALL, get_user_msgid("ScoreInfo"))
	write_byte(killer)
	write_short(get_user_frags(killer))
	write_short(get_user_deaths(killer))
	write_short(0)
	write_short(get_user_team(killer))
	message_end()
		
	// Update victims scoreboard with correct info
	message_begin(MSG_ALL, get_user_msgid("ScoreInfo"))
	write_byte(victim)
	write_short(get_user_frags(victim))
	write_short(get_user_deaths(victim))
	write_short(0)
	write_short(get_user_team(victim))
	message_end()

        
	return  PLUGIN_HANDLED
}

stock Hurt_Entity(attacker,victim,Float:amount)
{
	if (get_user_health(victim)-amount <= 0.1)
	{
		Log_Kill(attacker,victim,"world",0)
	}
	else
	{
		fakedamage(victim,"player",amount,DMG_ENERGYBEAM)
	}
}

stock hudmsg(id,Float:display_time,const fmt[], {Float,Sql,Result,_}:...)
{	
	if (player_huddelay[id] >= 0.03*4)
		return PLUGIN_CONTINUE
		
	new buffer[512]
	vformat(buffer, 511, fmt, 4)
		
	set_hudmessage ( 255, 0, 0, -1.0, 0.4 + player_huddelay[id], 0, display_time/2, display_time, 0.1, 0.2, -1 ) 	
	show_hudmessage(id, buffer)
		
	player_huddelay[id]+=0.03
	
	remove_task(id+TASK_HUD)
	set_task(display_time, "hudmsg_clear", id+TASK_HUD, "", 0, "a", 3)
	
	
	return PLUGIN_CONTINUE
		
}

public hudmsg_clear(id)
{
	new pid = id-TASK_HUD
	player_huddelay[pid]=0.0
}

//Display help about class and spells
public Event_Info(id)
{	
	if (player_class[id] <= 0)
	{
		client_print(id,print_chat, "Please select a class first. Do this by typing /selectclass")
		return PLUGIN_CONTINUE
	}
	
	new g_ItemFile[64]
	new amxbasedir[64]
	get_basedir(amxbasedir,63)
	
	if (is_user_connected(id))
	{
		format(g_ItemFile,63,"%s/infopl%i.txt",amxbasedir, id)
		if(file_exists(g_ItemFile))
			delete_file(g_ItemFile)
			
		new Data[768]
					
		//Header
		format(Data,767,"<html><head><title></title></head>")
		write_file(g_ItemFile,Data,-1)
		
		format(Data,767,"<body text=^"#FFEE00^" bgcolor=^"#000000^">")
		write_file(g_ItemFile,Data,-1)
		
		format(Data,767,"<h1>Welcome to the knifearena</h1><br>")
		write_file(g_ItemFile,Data,-1)
		
		format(Data,767,"Spells are cast with USE and RELOAD.<br>")
		write_file(g_ItemFile,Data,-1)
		
		format(Data,767,"<b>Spell1:</b> USE+FORWARD<br><b>Spell2:</b> USE+BACK<br><b>Spell3:</b> RELOAD+FORWARD<br><b>Spell4:</b> RELOAD+BACK<br><b>Spell5:</b> USE+RELOAD<br>")
		write_file(g_ItemFile,Data,-1)
		
		
		format(Data,767,"<br><b>Your class:</b> %s<br>", Class_Names[player_class[id]])
		write_file(g_ItemFile,Data,-1)
		
		for (new i=0; i < 5; i++)
		{
			format(Data,767,"<br><b>Spell %i: </b>", i+1)
			write_file(g_ItemFile,Data,-1)
			Write_Spell_Info(g_ItemFile,player_spell[id][i])
			format(Data,767,"<br>", i+1)
			write_file(g_ItemFile,Data,-1)
		}
		

		//show window with message
		show_motd(id, g_ItemFile, "Information")
		
	}
	else 
	{
		show_motd(id, "Server Error: Could not generate information file on server", "Server Error")	
	}
	
	return PLUGIN_CONTINUE
}

public Event_Selectclass(id)
{	

	menu_display(id, mSelectyourclass, 0)
	return PLUGIN_CONTINUE
}

stock Write_Spell_Info(g_file[], Spell)
{
	new Data[768]
	
	switch (Spell)
	{
		case Spell_Poison_Dagger: { 
			format(Data,767,"You dagger gains poision. The first enemy you hit will be poisioned. If you get hit first you are poisioned")
		}
		
		case Spell_Fear: {
			format(Data,767,"You fear all players in a small radius around you. Players feared will not be able to move forward")
		}
		
		case Spell_Drainlife: {
			format(Data,767,"You drain the target. While draining you gain life from the enemy. Both the enemy and your spell is reduced while this effect last")
		}
		
		case Spell_Spirit_Ward: {
			format(Data,767,"You create a spirit ward. This ward will damage all enemies in the radius of the ward.")
		}
		
		case Spell_Shadow_Veil: {
			format(Data,767,"You become nearly invisble.")
		}
		
		case Spell_Bark_Skin: {
			format(Data,767,"You become immune from direct target spells such as drainlife and force of nature")
		}
		
		case Spell_Sunder: {
			format(Data,767,"Your target looses 50 armor and becomes crippled")
		}
		
		case Spell_Enrage: {
			format(Data,767,"Your target will be marked. While the target is marked any damage you inflict upon him will result in a stun")
		}
		
		case Spell_Fire_Totem: {
			format(Data,767,"You create a fire totem. This totem will heal all friends in its radius")
		}
		
		case Spell_Wrath: {
			format(Data,767,"You become filled with wrath. All damage you do and receive is doubled. If you kill anyone while this effect is active you regain all life")
		}
		
		case Spell_Ground_Slam: {
			format(Data,767,"You slam the ground dazing all enemies near")
		}
			
		case Spell_Natures_Blessing: {
			format(Data,767,"You regain life over time")
		}
		
		case Spell_Force_Of_Nature: {
			format(Data,767,"All enemy players in sight will be struct by lightning. The more players you hit the more will each lightning damage")
		}
		
		case Spell_Natures_Will: {
			format(Data,767,"Your target will be healed while the link is active. You will be healed for the same amount as your target")
		}
		
		case Spell_Vengeance: {
			format(Data,767,"While this effect is active all targets hit will become dazed")
		}
		
		case Spell_Focus: {
			format(Data,767,"While this effect is active only your target and the players on your team will see you. The effect goes both ways")
		}
		
		case Spell_Lurk: {
			format(Data,767,"You become nearly invisible")
		}
		
		case Spell_Backstab: {
			format(Data,767,"While this effect is active the first target hit which is unable to see you will take massive damage")
		}
		
		case Spell_Ground_Totem: {
			format(Data,767,"You create a ground totem which gives more speed to friends around it")
		}
		
		case Spell_Stab: {
			format(Data,767,"While this effect is active the first target hit which is unable to see you will become stunned")
		}
		
		case Spell_Blink: {
			format(Data,767,"You teleport a short distance ahead")
		}
		
		case Spell_Meditation: {
			format(Data,767,"??")
		}
		
		case Spell_Nova: {
			format(Data,767,"You emit a poision nova. All enemies caugt in it will be poisioned")
		}
		
		case Spell_Silence: {
			format(Data,767,"Your target becomes silenced and therefore unable to cast spells")
		}
		
		case Spell_Arcane_Link: {
			format(Data,767,"While this effect is active all damage you do will give you back life")
		}
		
		case Spell_Ignite_Totem: {
			format(Data,767,"You create an ignite totem. When this totem explodes all enemies will gain the ignite effect burning until they damage someone. This can hit you also")
		}
	}
	
	write_file(g_file,Data,-1)
}

public Help_Player(id)
{
	new rnd = random_num(1,4)
	if (rnd <= 4)
		set_hudmessage(0, 180, 0, -1.0, 0.70, 0, 10.0, 5.0, 0.1, 0.5, -1) 			
	if (rnd == 1)
		show_hudmessage(id, "You can view information about your class and spell by saying /info")
	if (rnd == 2)
		show_hudmessage(id, "You can select a different class by typing /selectclass. Note that this will kill you")
	if (rnd == 3)
		show_hudmessage(id, "This is only a beta version. Alot more will come later, please report all errors on www.amxmodx.org @ knifearena Beta")
}
