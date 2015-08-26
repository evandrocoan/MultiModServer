// Map Configs
// This Plugin executes commands given in a file for a specific map
// serverside whenever a map starts and clientside on putinserver.

// Idea partially from [RST] FireStorm @ http://www.amxmodx.org/forums/viewtopic.php?t=13711
// but I intended to write a script with greater functionality
// Coding & Testing by MistaGee

#include <amxmodx>
#include <amxmisc>

#define FLE_MAPCFG "addons/amxmodx/configs/mapcommands.txt"
#define TMR_W8 0.5
//#define DEBUG

void:exec_clients(cmd[], bool:ignorelisten = false){
	// Send the given command to all players
	new players[32], plnum;
	get_players(players, plnum);
	// IMPORTANT :: Listenservers are identical with client #1, so don't send the cmd twice to them!
	for(new i = 0; i < plnum; i++) if(ignorelisten || is_dedicated_server() || players[i] != 1)client_cmd(players[i], cmd);
	}

public plugin_init(){
	register_plugin("Map CFG", "1.0", "MistaGee");
	
	register_concmd("amx_mapcfg", "mapcfg_execnow", ADMIN_CFG, "Use this to execute the map config right now.");
	
	// This CVar MUST be set to 1 b4 my script does anything to make sure (listen)server.cfg has been exec'ed
	register_cvar("amx_mapcfg_execed", "0");
	
	// This Task checks if the Cvar has been set to one
	set_task(TMR_W8, "check_cvar");
	
	}
	
void:exec_mapcfg(){
	// This function now finally loops through the file and execs the given cmds.
	if(!file_exists(FLE_MAPCFG)){
		write_file(FLE_MAPCFG, "// This is the map configuration file. Add Cmds for specific maps here.", -1);
		write_file(FLE_MAPCFG, "// Format:", -1);
		write_file(FLE_MAPCFG, "//   Map sections are named with '[map]' or '[map'. If the closing bracket is not set,", -1);
		write_file(FLE_MAPCFG, "//      this means that not the full name was given - example: '[fy_ice' means that these", -1);
		write_file(FLE_MAPCFG, "//      are executed for fy_iceworld, fy_iceworld2k_ fy_icewhatever as well.", -1);
		write_file(FLE_MAPCFG, "//   Server and Client Sections are named #server, #client or #all.", -1);
		write_file(FLE_MAPCFG, "//      This specifies where the commands are being executed.", -1);
		write_file(FLE_MAPCFG, "//   Comments (like these (-.-) ) HAVE to be made with // at the BEGINNING of the line.", -1);
		write_file(FLE_MAPCFG, "//   Listen servers are identical with their first client, so the #client commands are not", -1);
		write_file(FLE_MAPCFG, "//      sent to the first client. Use #ignorelisten <on|off> in the cfg file to override.", -1);
		write_file(FLE_MAPCFG, "//      Default for this setting is off.", -1);
		return;
		}

	new ThisMap[32], cmdMap[32], line = 0, cmd[129], txtlen, wildcard = 0, execmode = 0, commentcount = 0, bool:ignorelisten = false; 
	get_mapname(ThisMap, 31);
	
	// File exists, so lezz parse it...
	while((line=read_file(FLE_MAPCFG, line, cmd, 128, txtlen)) != 0){
		// Check the given cmd for the line beginning...
		if(equali(cmd, "//", 2) || !txtlen) commentcount++; // comment line or whitespace - just do a li'l bullshit to satisfy the compiler...
		else if(equali(cmd, "[", 1)){ 
			// this is a map name. if terminated with ], mapname has to be fully equal.
			if(equali(cmd[txtlen - 1], "]", 1)){
				wildcard = 0;
				copyc(cmdMap, 31, cmd[1], ']'); // Copy cmd without the [ to mapname UNTIL ] is found
#if defined DEBUG
				server_print("[AMXX][MCFG] Found closed map name ''%s'' on line %d", cmdMap, line); 
#endif
			}
			else{
				// Wildcard was found - check how long the mapname is and save the whole shit...
				wildcard = txtlen - 1; // Whole text except the [
				copy(cmdMap, 31, cmd[1]);
#if defined DEBUG
				server_print("[AMXX][MCFG] Found open map name ''%s'' on line %d", cmdMap, line); 
#endif
				}
			// Default exec mode: server
			execmode = 2;
			}
		// Server / client / all modifiers
		else if(equali(cmd, "#all"))				execmode = 1;
		else if(equali(cmd, "#server"))				execmode = 2;
		else if(equali(cmd, "#client"))				execmode = 3;
		else if(equali(cmd, "#ignorelisten on"))	ignorelisten = true;
		else if(equali(cmd, "#ignorelisten off"))	ignorelisten = false;
		else{
			// If no execmode was specified, do nothing
			if(!execmode) return;
			// Normal Command was found - check if map is running and then exec it
			if(wildcard && !equali(cmdMap, ThisMap, wildcard)) continue;
			if(!wildcard && !equali(cmdMap, ThisMap)) continue;
			// OK, map is running
#if defined DEBUG
			server_print("[AMXX][MCFG] Found map command ''%s'' on line %d", cmd, line); 
#endif
			// Check execmode. For all modes < 3 the command is exec'ed serverside.
			if(execmode < 3) server_cmd(cmd);
			// For all modes != 2 the command is exec'ed clientside.
			if(execmode != 2) exec_clients(cmd, ignorelisten);
			}
		}
#if defined DEBUG
	server_print("[AMXX][MCFG] Found %d commented or whitespace line(s)", commentcount);
#endif
	return;
	}
	
public check_cvar(){
	// If CVar has been set, exec the mapcfg - otherwise wait another .5 seconds
	if(get_cvar_num("amx_mapcfg_execed")) exec_mapcfg();
	else set_task(TMR_W8, "check_cvar");
	}

public mapcfg_execnow(id, level, cid){
	if(cmd_access(id, level, cid, 0)) exec_mapcfg();
	return PLUGIN_HANDLED;
	}
		
