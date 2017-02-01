#include <amxmodx>
#include <amxmisc>
#include <ttt>

new g_iRules[33], g_pCommandMenuID;
new Array:g_aFilePath, Array:g_aFileName;

public plugin_init()
{
	register_plugin("[TTT] Rules", TTT_VERSION, TTT_AUTHOR);
	register_clcmd("say /rules", "ttt_rules_show");
	register_clcmd("say_team /rules", "ttt_rules_show");
	register_clcmd("say /help", "ttt_rules_show");
	register_clcmd("say_team /help", "ttt_rules_show");
	register_concmd("ttt_rules", "cmd_force_rules", TTT_ADMINACCESS, "#nickname #rule_id");

	g_pCommandMenuID = ttt_command_add("Rules menu");
	g_aFilePath = ArrayCreate(64, 3);
	g_aFileName = ArrayCreate(20, 3);

	static directory[40];
	get_localinfo("amxx_configsdir", directory, charsmax(directory));
	formatex(directory, charsmax(directory), "%s/rules_ttt", directory);

	static filename[32];
	new handle = open_dir(directory, filename, charsmax(filename));
	if(!handle)
		return;

	static line[96], len, left[48], right[48];
	do
	{
		if(strlen(filename) > 3)
		{
			formatex(line, charsmax(line), "%s/%s", directory, filename);
			ArrayPushString(g_aFilePath, line);
			read_file(line, 0, line, charsmax(line), len);
			
			strtok(line, left, charsmax(left), right, charsmax(right), ''');
			strtok(right, left, charsmax(left), right, charsmax(right), ''');
			ArrayPushString(g_aFileName, left);
		}
	}
	while(next_file(handle, filename, charsmax(filename)));
	close_dir(handle);
}

public plugin_end()
{
	ArrayDestroy(g_aFilePath);
	ArrayDestroy(g_aFileName);
}

public client_putinserver(id)
{
	static out[2];
	get_user_info(id, "_ttt_rules", out, charsmax(out));
	g_iRules[id] = str_to_num(out);

	if(!g_iRules[id])
		set_task(10.0, "ttt_rules_show", id);
}

public ttt_command_selected(id, menuid, name[])
{
	if(g_pCommandMenuID == menuid)
		ttt_rules_show(id);
}

public ttt_rules_show(id)
{
	new menu = menu_create("\rRules", "ttt_rules_handler");

	static data[5], option[20];
	new size = ArraySize(g_aFileName);
	for(new i = 0; i < size; i++)
	{
		ArrayGetString(g_aFileName, i, option, charsmax(option));
		num_to_str(i, data, charsmax(data));
		menu_additem(menu, option, data, 0);
	}

	menu_addblank(menu, 0);

	if(g_iRules[id])
		menu_additem(menu, "RULES [HIDE]", "1000", 0);
	else menu_additem(menu, "RULES [SHOW]", "1000", 0);

	menu_setprop(menu, MPROP_EXIT, MEXIT_ALL);
	menu_setprop(menu, MPROP_NOCOLORS, 1);

	menu_display(id, menu, 0);

	return PLUGIN_HANDLED;
}

public ttt_rules_handler(id, menu, item)
{
	if(item == MENU_EXIT)
	{
		menu_destroy(menu);
		return PLUGIN_HANDLED;
	}

	static command[6], name[64], access, callback;
	menu_item_getinfo(menu, item, access, command, charsmax(command), name, charsmax(name), callback);
	menu_destroy(menu);

	new num = str_to_num(command);
	if(num < 1000)
	{
		show_rules(id, num);
	}
	else
	{
		g_iRules[id] = !g_iRules[id];
		client_cmd(id, "setinfo _ttt_rules %d", g_iRules[id]);
		ttt_rules_show(id);
	}

	return PLUGIN_HANDLED;
}

public cmd_force_rules(id, level, cid)
{
	if(!cmd_access(id, level, cid, 2))
		return PLUGIN_HANDLED;

	static player_name[32], rule_id[3];
	read_argv(1, player_name, charsmax(player_name));
	read_argv(2, rule_id, charsmax(rule_id));

	new target = cmd_target(id, player_name, 1);
	if(target)
	{
		new rule = -1;
		if(is_str_num(rule_id))
			rule = str_to_num(rule_id)-1;

		new size = ArraySize(g_aFileName);
		if(-1 < rule < size)
		{
			static admin_name[32];
			get_user_name(id, admin_name, charsmax(admin_name));
			get_user_name(target, player_name, charsmax(player_name));
			ttt_log_to_file(LOG_MISC, "Admin %s forced rule with ID #%d to player %s", admin_name, rule, player_name);
			show_rules(target, rule);
		}
		else
		{
			static option[20];
			console_print(id, "Rule with ID %d could not be found, available rules:", rule);
			for(new i = 0; i < size; i++)
			{
				ArrayGetString(g_aFileName, i, option, charsmax(option));
				console_print(id, "#%d --- %s", i+1, option);
			}
		}
	}

	return PLUGIN_HANDLED;
}

stock show_rules(id, rule)
{
	static option[20], path[64];
	ArrayGetString(g_aFileName, rule, option, charsmax(option));
	ArrayGetString(g_aFilePath, rule, path, charsmax(path));
	show_motd(id, path, option);
}