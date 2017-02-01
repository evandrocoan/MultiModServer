/* AMX Mod script
 *
 * mofoRates v0.01b
 * ----------------
 *
 * Developed by Tilted Logic for
 * *mofo* and PUB Counter-Strike clans
 * 
 * www.tiltedlogic.com
 * www.mofo-cs.tk
 * www.pub-community.com
 *
 * test server - 82.38.180.214:27016
 *
 * cvars
 *     mofo_auto_check     - checks a players rates when they join the server
 *                           also monitors the player, should the player change
 *                           rates then it will validate them
 *                           note: admins are not checked
 *     mofo_auto_fix       - defines whether invalid rates are 'fixed'
 *     mofo_min_rate       - minimum allowable rate
 *     mofo_min_updaterate - minimum allowable updaterate
 *     mofo_min_cmdrate    - minimum allowable cmdrate
 *     mofo_silent         - dont tell people about low rates or changed rates
 *
 * admin commands
 *     mofo_rates        - perform a full rates check on all players, displays players with low rates
 *     mofo_list         - displays a list of all players and their rates
 *
 * (c) Tilted Logic 2004
 * You may use this script on your server providing all notices are unchanged
 *
 * #include <stddisclaimer.h>
 * This file is provided as is (no warranties). 
 *
 */

#include <amxmodx>

public plugin_init() {
    register_plugin("mofoRates", "0.01", "Tilted Logic")

    //register_clcmd("rate", "mofo_check_rate", ADMIN_USER)
    //register_clcmd("cl_updaterate", "mofo_check_updaterate", ADMIN_USER)
    //register_clcmd("cl_cmddaterate", "mofo_check_cmdrate", ADMIN_USER)

    register_cvar("mofo_min_rate", "18000")
    register_cvar("mofo_min_updaterate", "80")
    register_cvar("mofo_min_cmdrate", "80")

    register_cvar("mofo_auto_check", "1") // 1 = enabled, 0 = disabled
    register_cvar("mofo_auto_fix", "1")   // 1 = enabled, 0 = disabled
    register_cvar("mofo_silent", "0")     // 1 = enabled, 0 = disabled
    
    register_concmd("mofo_rates", "mofo_rates", ADMIN_LEVEL_H, "List players with low rates.")
    register_concmd("mofo_list", "mofo_list", ADMIN_LEVEL_H, "Display rates for all players.")
    
    return PLUGIN_CONTINUE
}

public client_putinserver(id) {
    client_cmd(id,"echo This server is running mofoRates by Tilted Logic (www.tiltedlogic.com)") 
    
    client_infochanged(id);
    
    return PLUGIN_CONTINUE
}

public client_infochanged(id) {
    new rate[32]
    new updaterate[32]
    new cmdrate[32]
    
    if (mofo_check_user(id) == 0) 
        return PLUGIN_CONTINUE 
    
    get_user_info(id, "rate", rate, 31) 
    if (mofo_number_valid(rate) == 1) {
        mofo_check_data(id, "rate", "mofo_min_rate", rate)
    }
    
    get_user_info(id, "cl_updaterate", updaterate, 31) 
    if (mofo_number_valid(updaterate) == 1) {
        mofo_check_data(id, "cl_updaterate", "mofo_min_updaterate", updaterate)
    }
    
    get_user_info(id, "cl_cmdrate", cmdrate, 31) 
    if (mofo_number_valid(cmdrate) == 1) {
        mofo_check_data(id, "cl_cmdrate", "mofo_min_cmdrate", cmdrate)
    }
    
    return PLUGIN_CONTINUE
}

public mofo_check_user(id) {
    /* Do we do a check on this user? */ 
    
    if (get_cvar_num("mofo_auto_check") == 0) 
        return 0
    
    //if (get_user_flags(id) & ADMIN_IMMUNITY) 
    //    return 0
    
    if (is_user_bot(id))
        return 0
    
    if (is_user_hltv(id))
        return 0
    
    return 1
}

public mofo_number_valid(numstr[]) {
    new num

    num = str_to_num(numstr)
    
    if (num == 0) {
        if (!numstr[0]) {
            return 0
        }
    }
    
    return 1
}

/* player has manually changed rate */
public mofo_check_rate(id) { 
    new rate[50]
    
    client_print(id, print_console, "You have just changed your rate") 
    
    read_args(rate, 49) 
    
    return mofo_check_data(id, "rate", "mofo_min_rate", rate)
}

/* player has manually changed updaterate */
public mofo_check_updaterate(id) { 
    new updaterate[50] 
    
    client_print(id, print_console, "You have just changed your cl_updaterate") 
    
    read_args(updaterate, 49) 
    
    return mofo_check_data(id, "cl_updaterate", "mofo_min_updaterate", updaterate)
}

/* player has manually changed updaterate */
public mofo_check_cmdrate(id) { 
    new cmdrate[50] 
    
    client_print(id, print_console, "You have just changed your cl_cmdrate") 
    
    read_args(cmdrate, 49) 
    
    return mofo_check_data(id, "cl_cmdrate", "mofo_min_cmdrate", cmdrate)
} 

public mofo_check_data(id, desc[], cvar[], value[]) { 
    new user[32]
    
    if (mofo_check_user(id) == 0) 
        return PLUGIN_CONTINUE 
    
    if (mofo_number_valid(value) == 0) 
        return PLUGIN_CONTINUE 
    
    if (get_cvar_num(cvar) > str_to_num(value)) { 
        /* bad rate detected */ 
        /* what do we do now? */ 
        
        get_user_name(id, user, 31)
        
        /* tell player his rate is invalid for this server */ 
        if (get_cvar_num("mofo_silent") == 0) {
            set_hudmessage 
            client_print(0, print_console, "Invalid %s detected, %s has set his %s to %s", desc, user, desc, value)
            client_print(0, print_console, "Minimum %s for this server is set to %d.", desc, get_cvar_num(cvar)) 
        }
        
        if (get_cvar_num("mofo_auto_fix") == 1) {
            /* set players rate to a valid value - informing the player of this change */ 
            if (get_cvar_num("mofo_silent") == 0) {
                client_print(id, print_console, "Your %s has been changed to the minimum allowable setting.", desc) 
            }
            client_cmd(id, "%s %d", desc, get_cvar_num(cvar)) 
        }
        
        return PLUGIN_HANDLED 
    }
    
    return PLUGIN_CONTINUE 
} 

public mofo_list(id) {
    new players[32]
    new num
    new name[32]
    new rate[32]
    new updaterate[32]
    new cmdrate[32]
    new steamid[35]
    
    get_players(players,num,"a") 
    
    client_print(id, print_console, "Currently connected players...")
    client_print(id, print_console, "ID SteamID Name rate cl_updaterate cl_cmdrate")
    
    for (new i = 0; i < num; ++i) {
        get_user_name(players[i], name, 31)
        get_user_authid(players[i], steamid, 34);
        get_user_info(players[i], "rate", rate, 31) 
        get_user_info(players[i], "cl_updaterate", updaterate, 31)
        get_user_info(players[i], "cl_cmdrate", cmdrate, 31)
        
        client_print(id, print_console, "%d  %s   %s   %s   %s   %s", players[i], steamid, name, rate, updaterate, cmdrate)
    }
    
    if (num == 0) {
        client_print(id, print_console, "The server is currently empty")
    }
    return PLUGIN_HANDLED
} 

public mofo_rates(id) {
    new players[32]
    new num
    new name[32]
    new rate[32]
    new updaterate[32]
    new cmdrate[32]
    new steamid[35]
    new flag
    new playerflag
    
    get_players(players, num) 
    
    client_print(id, print_console, "Scanning currently connected players...")
    client_print(id, print_console, "ID SteamID Name rate cl_updaterate cl_cmdrate")
    
    playerflag = 0
    
    for (new i = 0; i < num; ++i) {
        get_user_name(players[i], name, 31)
        get_user_authid(players[i], steamid, 34);
        get_user_info(players[i], "rate", rate, 31) 
        get_user_info(players[i], "cl_updaterate", updaterate, 31)
        get_user_info(players[i], "cl_cmdrate", cmdrate, 31)  
        
        flag = 0
        
        if (mofo_number_valid(rate) == 1) {
            if (get_cvar_num("mofo_min_rate") > str_to_num(rate)) {
                flag = 1
                playerflag = 1
            }
        }
        
        if (flag == 0) {
            if (mofo_number_valid(updaterate) == 1) {
                if (get_cvar_num("mofo_min_updaterate") > str_to_num(updaterate)) {
                    flag = 1
                    playerflag = 1
                }
            }
        }
        
        if (flag == 0) {
            if (mofo_number_valid(cmdrate) == 1) {
                if (get_cvar_num("mofo_min_cmdrate") > str_to_num(cmdrate)) {
                    flag = 1
                    playerflag = 1
                }
            }
        }
        
        if (flag == 1) {
            client_print(id, print_console, "%d  %s   %s   %s   %s   %s", players[i], steamid, name, rate, updaterate, cmdrate)
        }
    }
    
    
    if (num == 0) {
        client_print(id, print_console, "The server is currently empty")
    } else if (playerflag == 0) {
        client_print(id, print_console, "There are no players on this server with low settings")
    }
    
    return PLUGIN_HANDLED
} 
