/*
*   _______     _      _  __          __
*  | _____/    | |    | | \ \   __   / /
*  | |         | |    | |  | | /  \ | |
*  | |         | |____| |  | |/ __ \| |
*  | |   ___   | ______ |  |   /  \   |
*  | |  |_  |  | |    | |  |  /    \  |
*  | |    | |  | |    | |  | |      | |
*  | |____| |  | |    | |  | |      | |
*  |_______/   |_|    |_|  \_/      \_/
*
*
*
*  Last Edited: 01-05-08
*
*  ============
*   Changelog:
*  ============
*
*  v1.0
*    -Initial Release
*
*/

#define VERSION	"2.0"

#include <amxmodx>
#include <amxmisc>
#include <fun>
#include <cstrike>
#include <fakemeta>

new blah[33]
new blah2[33]

new const menu1_weapon_names_T[10][32] =
{
	"weapon_glock18", "400",
	"weapon_usp", "500",
	"weapon_p228", "600",
	"weapon_deagle", "650",
	"weapon_elite", "800"
}

new const menu1_weapon_names_CT[10][32] =
{
	"weapon_glock18", "400",
	"weapon_usp", "500",
	"weapon_p228", "600",
	"weapon_deagle", "650",
	"weapon_fiveseven", "750"
}

new const menu2_weapon_names_T[4][32] =
{
	"weapon_m3", "1700",
	"weapon_xm1014", "3000"
}

new const menu2_weapon_names_CT[4][32] =
{
	"weapon_m3", "1700",
	"weapon_xm1014", "3000"
}

new const menu3_weapon_names_T[8][32] =
{
	"weapon_mac10", "1400",
	"weapon_mp5navy", "1500",
	"weapon_ump45", "1700",
	"weapon_p90", "2350"
}

new const menu3_weapon_names_CT[8][32] =
{
	"weapon_tmp", "1250",
	"weapon_mp5navy", "1500",
	"weapon_ump45", "1700",
	"weapon_p90", "2350"
}

new const menu4_weapon_names_T[12][32] =
{
	"weapon_galil", "2000",
	"weapon_ak47", "2500",
	"weapon_scout", "2750",
	"weapon_sg552", "3500",
	"weapon_awp", "4750",
	"weapon_g3sg1", "5000"
}

new const menu4_weapon_names_CT[12][32] =
{
	"weapon_famas", "2250",
	"weapon_scout", "2750",
	"weapon_m4a1", "3100",
	"weapon_aug", "3500",
	"weapon_sg550", "4200",
	"weapon_awp", "4750"
}

new const menu5_weapon_names_T[2][32] =
{
	"weapon_m249", "5750"
}

new const menu5_weapon_names_CT[2][32] =
{
	"weapon_m249", "5750"
}

new const keys = 511

new maxplayers
new bool:justdropped[33]

new primcvar, seccvar

public plugin_init()
{
	register_plugin("CS Pickup Multiple Weapons",VERSION,"GHW_Chronic")

	//Old Style Menus
	register_menucmd(register_menuid("BuyPistol",1),keys,"hook_menu1")
	register_menucmd(register_menuid("BuyShotgun",1),keys,"hook_menu2")
	register_menucmd(register_menuid("BuySub",1),keys,"hook_menu3")
	register_menucmd(register_menuid("BuyRifle",1),keys,"hook_menu4")
	register_menucmd(register_menuid("BuyMachine",1),keys,"hook_menu5")

	//VGUI Menus
	register_menucmd(-29,keys,"hook_menu1")
	register_menucmd(-30,keys,"hook_menu2")
	register_menucmd(-32,keys,"hook_menu3")
	register_menucmd(-31,keys,"hook_menu4")
	register_menucmd(-33,keys,"hook_menu5")

	register_forward(FM_Touch,"FM_Touch_hook")

	register_clcmd("drop","dropped")

	maxplayers = get_maxplayers()

	primcvar = register_cvar("max_primary","3")
	seccvar = register_cvar("max_secnodary","3")
}

public dropped(id)
{
	justdropped[id]=true
	set_task(0.5,"notdropped",id)
}

public notdropped(id) justdropped[id]=false

public hook_menu1(id,key) return hook_menus(1,id,key)
public hook_menu2(id,key) return hook_menus(2,id,key)
public hook_menu3(id,key) return hook_menus(3,id,key)
public hook_menu4(id,key) return hook_menus(4,id,key)
public hook_menu5(id,key) return hook_menus(5,id,key)

public hook_menus(menu,id,key)
{
	//Send Info to the weapon handler function.
	static weapon[32]
	new CsTeams:team = cs_get_user_team(id)
	switch(menu)
	{
		case 1:
		{
			switch(team)
			{
				case CS_TEAM_T: format(weapon,31,menu1_weapon_names_T[key*2])
				case CS_TEAM_CT: format(weapon,31,menu1_weapon_names_CT[key*2])
			}
		}
		case 2:
		{
			switch(team)
			{
				case CS_TEAM_T: format(weapon,31,menu2_weapon_names_T[key*2])
				case CS_TEAM_CT: format(weapon,31,menu2_weapon_names_CT[key*2])
			}
		}
		case 3:
		{
			switch(team)
			{
				case CS_TEAM_T: format(weapon,31,menu3_weapon_names_T[key*2])
				case CS_TEAM_CT: format(weapon,31,menu3_weapon_names_CT[key*2])
			}
		}
		case 4:
		{
			switch(team)
			{
				case CS_TEAM_T: format(weapon,31,menu4_weapon_names_T[key*2])
				case CS_TEAM_CT: format(weapon,31,menu4_weapon_names_CT[key*2])
			}
		}
		case 5:
		{
			switch(team)
			{
				case CS_TEAM_T: format(weapon,31,menu5_weapon_names_T[key*2])
				case CS_TEAM_CT: format(weapon,31,menu5_weapon_names_CT[key*2])
			}
		}
	}

	new price
	switch(menu)
	{
		case 1:
		{
			switch(team)
			{
				case CS_TEAM_T: price = str_to_num(menu1_weapon_names_T[key*2 + 1])
				case CS_TEAM_CT: price = str_to_num(menu1_weapon_names_CT[key*2 + 1])
			}
		}
		case 2:
		{
			switch(team)
			{
				case CS_TEAM_T: price = str_to_num(menu2_weapon_names_T[key*2 + 1])
				case CS_TEAM_CT: price = str_to_num(menu2_weapon_names_CT[key*2 + 1])
			}
		}
		case 3:
		{
			switch(team)
			{
				case CS_TEAM_T: price = str_to_num(menu3_weapon_names_T[key*2 + 1])
				case CS_TEAM_CT: price = str_to_num(menu3_weapon_names_CT[key*2 + 1])
			}
		}
		case 4:
		{
			switch(team)
			{
				case CS_TEAM_T: price = str_to_num(menu4_weapon_names_T[key*2 + 1])
				case CS_TEAM_CT: price = str_to_num(menu4_weapon_names_CT[key*2 + 1])
			}
		}
		case 5:
		{
			switch(team)
			{
				case CS_TEAM_T: price = str_to_num(menu5_weapon_names_T[key*2 + 1])
				case CS_TEAM_CT: price = str_to_num(menu5_weapon_names_CT[key*2 + 1])
			}
		}
	}
	return handle_weapon(id,weapon,price)
}

public handle_weapon(id,weapon[32],price)
{
	//Check for if they already have it & if they have the cash.
	if(cs_user_has_weapon(id,get_weaponid(weapon)))
	{
		client_print(id,print_center,"You already own that weapon.")
		engclient_cmd(id,"menuselect","10")
		return PLUGIN_HANDLED
	}

	if(cs_get_user_money(id)<price)
	{
		client_print(id,print_center,"You have insufficient funds!")
		engclient_cmd(id,"menuselect","10")
		return PLUGIN_HANDLED
	}

	new weaptype = weapon_type(get_weaponid(weapon))
	if(weaptype==1 && count_weaps(id,1)>=get_pcvar_num(primcvar) || weaptype==2 && count_weaps(id,2)>=get_pcvar_num(seccvar))
	{
		client_print(id,print_center,"You cannot carry anymore of that type!")
		engclient_cmd(id,"menuselect","10")
		return PLUGIN_HANDLED
	}

	//Give them their weapon and take their money.
	give_item(id,weapon)
	cs_set_user_money(id,cs_get_user_money(id) - price)

	//Close Menu so CS doesn't handle weapon buy.
	engclient_cmd(id,"menuselect","10")
	return PLUGIN_HANDLED
}

public FM_Touch_hook(weaponbox,id)
{
	if(id && id<=maxplayers && !justdropped[id] && is_user_alive(id) && !is_user_bot(id) && weaponbox>maxplayers && pev_valid(weaponbox))
	{
		static classname[64], trash[4]
		pev(weaponbox,pev_classname,classname,63)
		if(equali(classname,"weaponbox"))
		{
			//Support for most custom models.
			pev(weaponbox,pev_model,classname,63)
			replace(classname,63,"w_"," ")
			replace(classname,63,".mdl","")
			strbreak(classname,trash,3,classname,63)
			format(classname,63,"weapon_%s",classname)

			new ent = engfunc(EngFunc_FindEntityByString,maxplayers,"classname",classname)
			while(ent && pev_valid(ent))
			{
				if(pev(ent,pev_owner)==weaponbox)
				{
					static weaponid
					weaponid = get_weaponid(classname)
					if(!cs_user_has_weapon(id,weaponid))
					{
						new weaptype = weapon_type(weaponid)
						if(weaptype==1 && count_weaps(id,1)>=get_pcvar_num(primcvar) || weaptype==2 && count_weaps(id,2)>=get_pcvar_num(seccvar))
						{
							break;
						}
						justdropped[id]=true
						set_task(0.5,"notdropped",id)
						give_item(id,classname)
					}

					static classname2[32]
					pev(ent,pev_classname,classname2,31)
					blah2[id]=cs_get_weapon_ammo(ent)

					if(pev_valid(weaponbox)) engfunc(EngFunc_RemoveEntity,weaponbox)
					if(pev_valid(ent)) engfunc(EngFunc_RemoveEntity,ent)

					set_task(0.1,"give_ammo",id,classname2,31)
					break;
				}
				ent = engfunc(EngFunc_FindEntityByString,ent,"classname",classname)
			}
		}
	}
}

public give_ammo(classname2[32],id)
{
	if(is_user_alive(id))
	{
		static Float:origin[3]
		pev(id,pev_origin,origin)
		new ent = engfunc(EngFunc_FindEntityInSphere,maxplayers,origin,20.0)
		while(ent && pev_valid(ent))
		{
			static classname[32]
			pev(ent,pev_classname,classname,31)
			if(equali(classname,classname2) && pev(ent,pev_owner)==id)
			{
				cs_set_weapon_ammo(ent,blah2[id])
				break;
			}
			ent = engfunc(EngFunc_FindEntityInSphere,ent,origin,20.0)
		}
	}
	blah[id]=0
}

/*
* Types:
* 1 = primary weps
* 2 = secondary weps
*/
public count_weaps(id,type)
{
	if(!is_user_alive(id))
	{
		return PLUGIN_HANDLED
	}
	new num, num2, weapons[32]
	cs_get_user_weapons(id,weapons,num2)
	switch(type)
	{
		case 2:
		{
			for(new i=0;i<num2;i++)
			{
				if(weapons[i]==1 || weapons[i]==10 || weapons[i]==11 || weapons[i]==16 || weapons[i]==26 || weapons[i]==17) num++
			}
		}
		default:
		{
			for(new i=0;i<num2;i++)
			{
				if(weapons[i]==30 || weapons[i]==8 || weapons[i]==12 || weapons[i]==13 || weapons[i]==14 || weapons[i]==15 || weapons[i]==18 || weapons[i]==19 || weapons[i]==20 || weapons[i]==21 || weapons[i]==22 || weapons[i]==23 || weapons[i]==24 || weapons[i]==27 || weapons[i]==28 || weapons[i]==3 || weapons[i]==5 || weapons[i]==7) num++
			}
		}
	}
	return num;
}

public cs_get_user_weapons(id,weapons[32],& num)
{
	num=0
	new ent, origin[3], classname[32], owner
	pev(id,pev_origin,origin)
	ent = engfunc(EngFunc_FindEntityInSphere,get_maxplayers(),origin,1.0)
	while(ent)
	{
		owner = pev(ent,pev_owner)
		if(owner==id)
		{
			pev(ent,pev_classname,classname,31)
			if(containi(classname,"weapon_")==0)
			{
				weapons[num] = get_weaponid(classname)
				num++
			}
		}
		ent = engfunc(EngFunc_FindEntityInSphere,ent,origin,1.0)
	}
	return 1;		
}

/*
* Returns 1 for primary weapon
* and 2 for secondary weapon
*/
public weapon_type(weapid)
{
	if(weapid==1 || weapid==10 || weapid==11 || weapid==16 || weapid==26 || weapid==17) return 2;
	return 1;
}

/*
* 
*/
public cs_user_has_weapon(id,weapid)
{
	new ent, origin[3], classname[32], owner, weapname[32]
	get_weaponname(weapid,weapname,31)
	pev(id,pev_origin,origin)
	ent = engfunc(EngFunc_FindEntityInSphere,get_maxplayers(),origin,1.0)
	while(ent)
	{
		owner = pev(ent,pev_owner)
		if(owner==id)
		{
			pev(ent,pev_classname,classname,31)
			if(equali(classname,weapname))
			{
				return 1;
			}
		}
		ent = engfunc(EngFunc_FindEntityInSphere,ent,origin,1.0)
	}
	return 0;
}

/*
*Code for giving BPAmmo
public give_ammo2(params[2],id)
{
	if(pev_valid(params[1]))
	{
		new bpammo
		switch(params[0])
		{
			//case 16: bpammo = get_pdata_int(params[1],43591)
			//case 17: bpammo = get_pdata_int(params[1],5189)
			default: bpammo = 0
		}
		engfunc(EngFunc_RemoveEntity,params[1])
		cs_set_user_bpammo(id,params[0],cs_get_user_bpammo(id,params[0]) + bpammo)
	}
	blah[id]=0
}

*Code for finding offsets. Will need for later.
	for(new i=0;i<=50000;i++) if(get_pdata_int(param[0],i)==24) client_print(0,print_chat,"%d",i)
	client_print(0,print_chat,"%d. %d",5189,get_pdata_int(param[0],5189))
*/
