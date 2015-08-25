/* 
 *  This program is free software; you can redistribute it and/or modify it
 *  under the terms of the GNU General Public License as published by the
 *  Free Software Foundation; either version 2 of the License, or (at
 *  your option) any later version.
 *
 *  This program is distributed in the hope that it will be useful, but
 *  WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 *  General Public License for more details.
 */
#include <amxmodx>

public plugin_init()
{   
    register_plugin( "Multi-Mod Help", "1.0", "Addons zz" )
    register_dictionary( "multimodhelp.txt" )
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

    set_task( 50.0, "dispInfo", id )
}

public dispInfo( id )
{   
    client_print( id, print_chat, "%L", id, "TYPE_ADDONS_CONTATO" )
}

public client_disconnect( id )
{   
    remove_task (id)
}
