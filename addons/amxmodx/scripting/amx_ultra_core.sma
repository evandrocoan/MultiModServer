/*********************** Licensing *******************************************************
 * Amx Ultra Core
 *
 * by Addons zz
 *
 *  This program is free software; you can redistribute it and/or modify it
 *  under the terms of the GNU General Public License as published by the
 *  Free Software Foundation; either version 2 of the License, or (at
 *  your option) any later version.
 *
 *  This program is distributed in the hope that it will be useful, but
 *  WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 *  General Public License for more details.
 *
 ************************ Introduction ***************************************************
 *
 * Execute the amx_ultra core config file: addons/amxmodx/configs/amxx_ultra.cfg
 * 
 */

#include <amxmodx>
#include <amxmisc>

#define PLUGIN "Amx Ultra Core"
#define VERSION "1.0"
#define AUTHOR "Addons zz"

#define BIG_STRING 2048
#define LONG_STRING 256
#define SHORT_STRING 64

new configFolder[ LONG_STRING ]

/*
 * Called just after server activation.
 * 
 * Good place to initialize most of the plugin, such as registering
 * cvars, commands or forwards, creating data structures for later use, or
 * generating and loading other required configurations.
 */
public plugin_init()
{
    register_plugin( PLUGIN, VERSION, AUTHOR )
    
    get_configsdir( configFolder, charsmax( configFolder ) )
}

/*
 * Called when all plugins went through plugin_init().
 * 
 * When this forward is called, most plugins should have registered their
 * cvars and commands already.
 */
public plugin_cfg()
{
    server_cmd( "exec %s/amxx_ultra.cfg", configFolder )
}
