/***************************************************************************************************
 AMX Parachute
 
 Version: 0.2.2
 Author: KRoTaL
 
 Version: 0.3
 Author: Addons zz
 
 0.1    Release
 0.1.1  Players can't buy a parachute if they already own one
 0.1.2   Release for AMX MOD X
 0.1.3  Minor changes
 0.1.4  Players lose their parachute if they die
 0.1.5  Added amx_parachute cvar
 0.1.6  Changed set_origin to movetype_follow (you won't see your own parachute)
 0.1.7   Added amx_parachute <name> | admins with admin level a get a free parachute
 0.1.8   Fixed the give parachute command
 added a admin_parachute cvar to give admins with level A a free parachute
 0.1.9   Added a sell command & added a cvar to get money back
 0.2.0   Added para_free cvar to give everyone a free parachute
 0.2.1   Fixed some minor bugs
 0.2.2  Fixed the parachute remove bug
 0.2.3  Fixed the alive bug

0.3 - Addons zz
 Removed everything except the free parachute for all.
 
 ***************************************************************************************************/

#include <amxmodx>
#include <amxmisc>
#include <engine>
#include <cstrike>

#define PLUGINNAME "AMXX Parachute"
#define VERSION    "0.3"
#define AUTHOR     "KRoT@L/Addonszz"

new g_parachute_entity[ 33 ];

public plugin_init()
{
    register_plugin( PLUGINNAME, VERSION, AUTHOR )
    register_dictionary( "parachute.txt" )
}

public plugin_modules()
{
    require_module( "engine" )
    require_module( "cstrike" )
}

public plugin_precache()
{
    precache_model( "models/parachute.mdl" )
}

public client_PreThink( id )
{
    if( !is_user_alive( id ) )
    {
        return PLUGIN_CONTINUE
    }
    
    if( get_user_button( id ) & IN_USE )
    {
        if( !( get_entity_flags( id ) & FL_ONGROUND ) )
        {
            new
            Float:velocity[ 3 ]
            entity_get_vector( id, EV_VEC_velocity, velocity )
            
            if( velocity[ 2 ] < 0 )
            {
                if( g_parachute_entity[ id ] == 0 )
                {
                    g_parachute_entity[ id ] = create_entity( "info_target" )
                    
                    if( g_parachute_entity[ id ] > 0 )
                    {
                        entity_set_model( g_parachute_entity[ id ], "models/parachute.mdl" )
                        entity_set_int( g_parachute_entity[ id ], EV_INT_movetype, MOVETYPE_FOLLOW )
                        entity_set_edict( g_parachute_entity[ id ], EV_ENT_aiment, id )
                    }
                }
                
                if( g_parachute_entity[ id ] > 0 )
                {
                    velocity[ 2 ] = -21.1
                    entity_set_vector( id, EV_VEC_velocity, velocity )
                    
                    if( entity_get_float( g_parachute_entity[ id ], EV_FL_frame ) < 0.0
                        || entity_get_float( g_parachute_entity[ id ], EV_FL_frame ) > 254.0 )
                    {
                        if( entity_get_int( g_parachute_entity[ id ], EV_INT_sequence ) != 1 )
                        {
                            entity_set_int( g_parachute_entity[ id ], EV_INT_sequence, 1 )
                        }
                        entity_set_float( g_parachute_entity[ id ], EV_FL_frame, 0.0 )
                    }
                    else
                    {
                        entity_set_float( g_parachute_entity[ id ], EV_FL_frame,
                                entity_get_float( g_parachute_entity[ id ], EV_FL_frame ) + 1.0 )
                    }
                }
            }
            else
            {
                if( g_parachute_entity[ id ] > 0 )
                {
                    remove_entity( g_parachute_entity[ id ] )
                    g_parachute_entity[ id ] = 0
                }
            }
        }
        else
        {
            if( g_parachute_entity[ id ] > 0 )
            {
                remove_entity( g_parachute_entity[ id ] )
                g_parachute_entity[ id ] = 0
            }
        }
    }
    else
    if( get_user_oldbutton( id ) & IN_USE )
    {
        if( g_parachute_entity[ id ] > 0 )
        {
            remove_entity( g_parachute_entity[ id ] )
            g_parachute_entity[ id ] = 0
        }
    }
    
    return PLUGIN_CONTINUE
}
