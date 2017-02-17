#include <amxmodx>
#include <amxmisc>

#define PLUGIN "Remove admins"
#define VERSION "0.2"
#define AUTHOR "SweatyBanana"

enum{TYPE_STEAM,TYPE_NAME}

public plugin_init()
{
	register_plugin(PLUGIN,VERSION,AUTHOR);
	register_cvar("ar_version",VERSION,FCVAR_SERVER);
	register_clcmd("amx_removeadmin","remove_cmd",ADMIN_RCON,"amx_removeadmin <steamid or nick>");
}

public remove_cmd(id,level,cid)
{
	if(!(get_user_flags(id) & ADMIN_RCON))
		return PLUGIN_HANDLED;

	new players[32], inum, i, player;
	new TARGET[32], playerinfo[32];
	new command_type;
	new bool:is_found = false;
	
	get_players(players,inum);
	
	read_argv(1,TARGET,31);
	remove_quotes(TARGET);

	if(equal(TARGET,"STEAM_",6))
	{
		command_type = TYPE_STEAM;

		for(i = 0; i < inum; i++)
		{
			player = players[i];
			
			get_user_authid(player, playerinfo, 31);
			
			if(equal(playerinfo, TARGET))
			{
				remove_user_flags(player);
				break;
			}
		}
	}
	else
	{
		command_type = TYPE_NAME;

		for(i = 0; i < inum; i++)
		{
			player = players[i];
			
			get_user_name(player,playerinfo,31);
			if( containi(playerinfo,TARGET) != -1 )
			{
				remove_user_flags(player);
				break;
			}
		}
	}
	new filename[64], text[512];
	get_configsdir(filename,63);
	format(filename,63,"%s/users.ini",filename);

	new file = fopen(filename,"rt");
	i = 0;

	while(!feof(file))
	{
		fgets(file,text,50);

		i++;

		if(text[0] == ';')
			continue;

		parse(text,playerinfo,31,players,1);

		if((command_type == TYPE_STEAM && equal(playerinfo, TARGET))
		|| (command_type == TYPE_NAME && containi(playerinfo, TARGET) != -1))
		{
			is_found = true;
			format(text,511,";%s",text);
			write_file(filename,text,i-1);

			console_print(id,"********************ADMIN ID REMOVAL TOOL**************");
			console_print(id,"");
			console_print(id," The target, %s, was removed from users.ini ",TARGET);
			console_print(id,"");
			console_print(id,"********************ADMIN ID REMOVAL TOOL**************");

			server_cmd("amx_reloadadmins")
			break;
		}
	}
	
	if(!is_found)
	{
		console_print(id,"********************ADMIN ID REMOVAL TOOL**************");
		console_print(id," The entry, %s, was not found in users.ini ",TARGET);
		console_print(id,"********************ADMIN ID REMOVAL TOOL**************");
	}

	fclose(file);

	return PLUGIN_HANDLED;
}
