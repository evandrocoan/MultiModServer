/******************************************************************************
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
*  You should have received a copy of the GNU General Public License
*  along with this program.  If not, see <http://www.gnu.org/licenses/>.
*
 ******************************************************************************

 */
#include <amxmodx>
#include <amxmisc>

#define PLUGIN "Addons zz Info"
#define VERSION "1.0-alpha2"
#define AUTHOR "Addons zz"

#define LONG_STRING 256

new g_configFolder[ LONG_STRING ]
new gp_allowedzz

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

	register_dictionary( "multimodhelp.txt" ) 
	register_cvar("MultiModServer", VERSION, FCVAR_SERVER|FCVAR_SPONLY) 

	gp_allowedzz = register_cvar("amx_allow_zz_info", "1") 
}

/*
 * Called when all plugins went through plugin_init().
 * 
 * When this forward is called, most plugins should have registered their
 * cvars and commands already.
 */
public plugin_cfg()
{
	get_configsdir(g_configFolder, charsmax(g_configFolder))

	server_cmd( "exec %s/amxx_ultra.cfg", g_configFolder )
}

public plugin_precache()
{   
	precache_sound( "ambience/ratchant.wav" );
	precache_sound( "misc/snore.wav" );
}

public client_putinserver( id )
{   
	if ( is_user_bot( id ) )
	{   
		return
	}
	if( get_pcvar_num( gp_allowedzz ) )
	{  
		set_task( 50.1, "dispInfo", id )
	}
}

public dispInfo( id )
{   
	client_print( id, print_chat, "%L", id, "TYPE_ADDONS_CONTATO" )
}

public client_disconnect( id )
{   
	remove_task (id)
}
