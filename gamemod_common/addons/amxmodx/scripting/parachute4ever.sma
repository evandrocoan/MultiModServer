/***************************************************************************************************
 AMX Parachute
 
 Version: 0.2.2
 Author: KRoTaL

 0.1    Release
 0.1.1  Players can't buy a parachute if they already own one
 0.1.2	 Release for AMX MOD X
 0.1.3  Minor changes
 0.1.4  Players lose their parachute if they die
 0.1.5  Added amx_parachute cvar
 0.1.6  Changed set_origin to movetype_follow (you won't see your own parachute)
 0.1.7	 Added amx_parachute <name> | admins with admin level a get a free parachute
 0.1.8	 Fixed the give parachute command
 added a admin_parachute cvar to give admins with level A a free parachute
 0.1.9	 Added a sell command & added a cvar to get money back
 0.2.0	 Added para_free cvar to give everyone a free parachute
 0.2.1	 Fixed some minor bugs
 0.2.2  Fixed the parachute remove bug
 0.2.3  Fixed the alive bug


 Commands:

 say buy_parachute	- buys a parachute
 
 amx_parachute <name>|@all	- gives a player a free parachute

 Press +use to slow down your fall.

 Cvars:

 sv_parachute "1"	 -	0: disables the plugin
 1: enables the plugin

 parachute_cost "1000"	 -	cost of the parachute
 
 admin_parachute "0"	 -	0: admins with level A won't get a free parachute
 1: admins with level A get a free parachute
 
 parachute_payback "75"	 -	the amount you get back of the parachute in %(75/100*1000) = 750
 
 para_free "0"		 -	0: no free parachute
 1: free parachute for everyone
 

 Setup (AMXX 1.71):

 Install the amxx file. 
 Enable engine and cstrike(amxx's modules.ini) 
 Put the parachute.mdl file in the cstrike/models folder


 ***************************************************************************************************/

#include <amxmodx>
#include <amxmisc>
#include <engine>
#include <cstrike>

#define PLUGINNAME	"AMXX Parachute"
#define VERSION		"0.2.3"
#define AUTHOR		"KRoT@L"

new para_ent[ 33 ];

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
    if ( !is_user_alive( id ) )
    {   
        return PLUGIN_CONTINUE
    }

    if ( get_user_button( id ) & IN_USE )
    {   
        if ( ! ( get_entity_flags( id ) & FL_ONGROUND ) )
        {   
            new
            Float:velocity[ 3 ]
            entity_get_vector( id, EV_VEC_velocity, velocity )
            if ( velocity[ 2 ] < 0 )
            {   
                if ( para_ent[ id ] == 0 )
                {   
                    para_ent[ id ] = create_entity( "info_target" )
                    if ( para_ent[ id ] > 0 )
                    {   
                        entity_set_model( para_ent[ id ], "models/parachute.mdl" )
                        entity_set_int( para_ent[ id ], EV_INT_movetype, MOVETYPE_FOLLOW )
                        entity_set_edict( para_ent[ id ], EV_ENT_aiment, id )
                    }
                }
                if ( para_ent[ id ] > 0 )
                {   
                    velocity[ 2 ] = -20.0
                    entity_set_vector( id, EV_VEC_velocity, velocity )
                    if ( entity_get_float( para_ent[ id ], EV_FL_frame ) < 0.0
                    || entity_get_float( para_ent[ id ], EV_FL_frame ) > 254.0 )
                    {   
                        if ( entity_get_int( para_ent[ id ], EV_INT_sequence ) != 1 )
                        {   
                            entity_set_int( para_ent[ id ], EV_INT_sequence, 1 )
                        }
                        entity_set_float( para_ent[ id ], EV_FL_frame, 0.0 )
                    } else
                    {   
                        entity_set_float( para_ent[ id ], EV_FL_frame,
                        entity_get_float( para_ent[ id ], EV_FL_frame ) + 1.0 )
                    }
                }
            } else
            {   
                if ( para_ent[ id ] > 0 )
                {   
                    remove_entity (para_ent[ id ])
                    para_ent[ id ] = 0
                }
            }
        } else
        {   
            if ( para_ent[ id ] > 0 )
            {   
                remove_entity (para_ent[ id ])
                para_ent[ id ] = 0
            }
        }
    } else
    if ( get_user_oldbutton( id ) & IN_USE )
    {   
        if ( para_ent[ id ] > 0 )
        {   
            remove_entity (para_ent[ id ])
            para_ent[ id ] = 0
        }
    }

    return PLUGIN_CONTINUE
}
