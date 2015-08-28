#include <amxmodx>
#include <amxmisc>
#include <float>

new filepath[251],curtime=0,staytime=0,curplayers=0,currounds=0

public plugin_init()
{
	register_plugin("Empty Server","1.42","twistedeuphoria")
	register_cvar("amx_staytime","600")
	register_cvar("amx_nmap1","de_dust")
	register_cvar("amx_nmap2","de_aztec")
	register_cvar("amx_nmap3","de_inferno")
	register_cvar("amx_nmap4","de_dust2")
	register_cvar("amx_nmap5","de_cbble")
	register_cvar("amx_idletime","5")
	register_cvar("amx_smartmap","1")
	register_logevent("newround",2,"1=Round_Start")
	staytime = get_cvar_num("amx_staytime")
	set_task(1.0,"timer",0,"curtime",0,"b",1)
	new directory[201]
	get_datadir(directory,200)
	format(filepath,250,"%s/emptyserver.txt",directory)
	if(!file_exists(filepath))
	{
		new writestr[201]
		format(writestr,200,"Map - Rounds Played - Total Players")
		write_file(filepath,writestr)
	}
}

public newround()
{
	currounds++
	new players[32], playernum
	get_players(players,playernum,"c")
	curplayers += playernum
}	

public plugin_end()
{
	new retstr[201],p,a,bool:found = false
	for(p=1;read_file(filepath,p,retstr,200,a) != 0;p++)
	{
		new smap[51],srounds[51],splayers[51],curmap[51]
		parse(retstr,smap,50,srounds,50,splayers,50)
		get_mapname(curmap,50)
		if(equali(smap,curmap))
		{
			new rounds = str_to_num(srounds)
			new players = str_to_num(splayers)
			rounds += currounds
			players += curplayers
			num_to_str(rounds,srounds,50)
			num_to_str(players,splayers,50)
			format(retstr,200,"%s %s %s",smap,srounds,splayers)
			write_file(filepath,retstr,p)	
			found = true
		}
	}
	if(found == false)
	{
		new players[51],map[51],rounds[51],writestr[201]
		get_mapname(map,50)
		num_to_str(curplayers,players,50)
		num_to_str(currounds,rounds,50)
		format(writestr,200,"%s %s %s",map,rounds,players)
		write_file(filepath,writestr)
	}
}
	
	
public timer()
{
	if(get_playersnum() == 0)
	{
		curtime ++
		if(curtime >= staytime)
			change_maps()
	}
	else
	{		
		new players,i,noncounted
		players = get_playersnum()
		for(i=1;i<=get_maxplayers();i++)
		{
			if((get_user_time(i,1) >= (get_cvar_num("amx_idletime") * 216000)) || is_user_bot(i) || is_user_hltv(i))
			{
				noncounted++
			}
		}
		if(players == noncounted)
		{
			curtime++
			if(curtime >= staytime)
				change_maps()
		}
		else
			curtime = 0
	}
	return curtime
}

public change_maps()
{
	new maps[5][51],curmap[51]
	get_mapname(curmap,50)
	if(get_cvar_num("amx_smartmap") == 1)
	{
		new Float:curpercent = 0.0			
		new retstr[201],p,a
		for(new i = 0;i<5;i++)
		{
			for(p=0;read_file(filepath,p,retstr,200,a) != 0;p++)
			{
				new sroundstr[51],splayerstr[51],smap[51],roundnum,playernum
				parse(retstr,smap,50,sroundstr,50,splayerstr,50)
				if(!equali(smap,curmap) && !equali(smap,maps[0]) && !equali(smap,maps[1]) && !equali(smap,maps[2]) && !equali(smap,maps[3]) && !equali(smap,maps[4]))
				{
					roundnum = str_to_num(sroundstr)
					playernum = str_to_num(splayerstr)
					new Float:curperc = floatdiv(float(roundnum),float(playernum))
					if(curperc > curpercent)
					{
						curpercent = curperc
						copy(maps[i],50,smap)
					}
				}
			}
			curpercent = 0.0
		}
	}
	else
	{	
		get_cvar_string("amx_nmap1",maps[0],31)	
		get_cvar_string("amx_nmap2",maps[1],31)
		get_cvar_string("amx_nmap3",maps[2],31)
		get_cvar_string("amx_nmap4",maps[3],31)
		get_cvar_string("amx_nmap5",maps[4],31)
	}
	if(strlen(maps[0]) == 0)
		get_cvar_string("amx_nmap1",maps[0],31)
	if(strlen(maps[1]) == 0)
		get_cvar_string("amx_nmap2",maps[1],31)
	if(strlen(maps[2]) == 0)
		get_cvar_string("amx_nmap3",maps[2],31)
	if(strlen(maps[3]) == 0)
		get_cvar_string("amx_nmap4",maps[3],31)
	if(strlen(maps[4]) == 0)
		get_cvar_string("amx_nmap5",maps[4],31)
	new num = random_num(0,4)
	while(equali(maps[num],curmap) || (strlen(maps[num]) == 0))
	{
		num = random_num(0,4)
	}
	server_cmd("changelevel %s",maps[num])
	return PLUGIN_HANDLED
}