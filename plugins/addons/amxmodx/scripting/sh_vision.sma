#include <amxmod.inc>
#include <xtrafun>
#include <superheromod.inc>

// Vision! 

// CVARS
// vis_cooldown # of seconds before Vision can NoClip Again
// vis_cliptime # of seconds Vision has in noclip mode.
// vis_gravity # self-explanative
// vis_health # self-explanative
// vis_armor # self_explanative
// vis_level

// VARIABLES
new gHeroName[]="Vision"
new bool:gHasvisPower[SH_MAXSLOTS+1]
new g_VisionTimer[SH_MAXSLOTS+1]
new g_lastPosition[SH_MAXSLOTS+1][3];// Variable to help with position checking
new g_VisionSound[]="ambience/vision_beat.mp3"

//----------------------------------------------------------------------------------------------
public plugin_precache()
{   
    // TBD - May want to do Ludwigs scotty teleport graphics later for this...
    precache_sound(g_VisionSound)
//----------------------------------------------------------------------------------------------
}

public plugin_init()
{   
    // Plugin Info
    register_plugin("SUPERHERO Vision","1.14.4","a|eX")

    // FIRE THE EVENT TO CREATE THIS SUPERHERO!
    if ( isDebugOn() ) server_print("Attempting to create Vision Hero")
    register_cvar("vis_level", "3" ),
    shCreateHero(gHeroName, "Walk Through Walls, Robotic Skin, High Grav.", "You can walk through walls for a bit, Your armor and hp is SKY HIGH, real heavy!", true, "vis_level")

    // REGISTER EVENTS THIS HERO WILL RESPOND TO! (AND SERVER COMMANDS)
    register_event("ResetHUD","newRound","b")

    // KEY DOWN
    register_srvcmd("vis_kd", "vis_kd")
    shRegKeyDown(gHeroName, "vis_kd")
    // INIT
    register_srvcmd("vis_init", "vis_init")
    shRegHeroInit(gHeroName, "vis_init")
    // LOOP
    register_srvcmd("vis_loop", "vis_loop")
    //shRegLoop1P0(gHeroName, "vis_loop", "ac" ) // Alive VisionHeros="ac"
    set_task(1.0,"vis_loop",0,"",0,"b" )

    // DEATH
    register_event("DeathMsg", "vis_death", "a")

    // DEFAULT THE CVARS
    register_cvar("vis_gravity", "4.50" )
    register_cvar("vis_armor", "350")
    register_cvar("vis_health", "130")
    register_cvar("vis_cooldown", "10" )
    register_cvar("vis_cliptime", "15" )
    register_cvar("vis_speed", "150" )

    // Let Server know about Visions Variable
    // It is possible that another hero has more hps, less gravity, or more armor
    // so rather than just setting these - let the superhero module decide each round
    shSetMaxHealth(gHeroName, "vis_health" )
    shSetMinGravity(gHeroName, "vis_gravity" )
    shSetMaxArmor(gHeroName, "vis_armor" )
    shSetMaxSpeed(gHeroName, "vis_speed", "[0]" )
}
//----------------------------------------------------------------------------------------------
public vis_init()
{   
    new temp[6]
    // First Argument is an id
    read_argv(1,temp,5)
    new id=str_to_num(temp)

    // 2nd Argument is 0 or 1 depending on whether the id has iron man powers
    read_argv(2,temp,5)
    new hasPowers=str_to_num(temp)

    if ( !hasPowers )
    {   
        if ( is_user_alive(id) && g_VisionTimer[id]>=0 && gHasvisPower[id] )
        {   
            vis_endnoclip(id)
        }
    }
    else
    {   
        g_VisionTimer[id]=-1 // Make sure looop doesn't fire for em... 1.14.4-b check
    }
    {   
        shRemHealthPower(id)
        shRemGravityPower(id)
        shRemArmorPower(id)
        shRemSpeedPower(id)
    }
    gHasvisPower[id]=(hasPowers!=0)
}
//----------------------------------------------------------------------------------------------
public newRound(id)
{   
    gPlayerUltimateUsed[id]=false
    g_VisionTimer[id]=-1
    if (is_user_alive(id) && get_user_noclip(id) ) set_user_noclip(id,0)
    return PLUGIN_HANDLED
}
//----------------------------------------------------------------------------------------------
// RESPOND TO KEYDOWN
public vis_kd()
{   
    new temp[6]

    // First Argument is an id with Vision Powers!
    read_argv(1,temp,5)
    new id=str_to_num(temp)

    if ( !is_user_alive(id) ) return PLUGIN_HANDLED

    // Let them know they already used their ultimate if they have
    if ( gPlayerUltimateUsed[id] )
    {   
        playSoundDenySelect(id)
        return PLUGIN_HANDLED
    }

    // Make sure they're not in the middle of clip already
    if ( g_VisionTimer[id]>0 ) return PLUGIN_HANDLED

    g_VisionTimer[id]=get_cvar_num("vis_cliptime")+1
    set_user_noclip(id,1)
    ultimateTimer(id, get_cvar_num("vis_cooldown") * 1.0)

    // Vision Messsage 
    new message[128]
    format(message, 127, "Entered Vision Mode - Don't get Stuck or you will die" )
    set_hudmessage(255,0,0,-1.0,0.3,0,0.25,1.0,0.0,0.0,4)
    show_hudmessage(id, message)
    emit_sound(id,CHAN_STATIC, g_VisionSound, 0.1, ATTN_NORM, 0, PITCH_LOW)

    return PLUGIN_HANDLED
}
//----------------------------------------------------------------------------------------------
public stopSound(id)
{
    emit_sound(id,CHAN_STATIC, g_VisionSound, 0.1, ATTN_NORM, 0, PITCH_LOW);
}
//----------------------------------------------------------------------------------------------   
public vis_loop()
{   
    for ( new id=1; id<=SH_MAXSLOTS; id++ )
    {   
        if ( gHasvisPower[id] && is_user_alive(id) )
        {   
            if ( g_VisionTimer[id]>0 )
            {   
                g_VisionTimer[id]--
                new message[128]
                format(message, 127, "%d seconds left of Vision Mode - Don't get Stuck or you will die", g_VisionTimer[id] )
                set_hudmessage(255,0,0,-1.0,0.3,0,1.0,1.0,0.0,0.0,4)
                show_hudmessage( id, message)
            }
            else
            {   
                if ( g_VisionTimer[id] == 0 )
                {   
                    g_VisionTimer[id]--
                    vis_endnoclip(id)
                    stopSound(id)
                }
            }
        }
    }
}
//----------------------------------------------------------------------------------------------
public vis_endnoclip(id)
{   
    g_VisionTimer[id]=0
    if ( get_user_noclip(id) == 1)
    {   
        // Turn off no-clipping and make sure the user has moved in 1/4 second
        stopSound(id)
        g_VisionTimer[id]=-1
        set_user_noclip(id,0)
        if ( is_user_alive(id) ) positionChangeTimer(id, 0.1 )
    }
}
//----------------------------------------------------------------------------------------------
public vis_death()
{   
    new id=read_data(2)
    vis_endnoclip(id)
    gPlayerUltimateUsed[id]=false
}
//----------------------------------------------------------------------------------------------
public positionChangeTimer(id, Float: secs)
{   
    new origin[3]
    new velocity[3]

    if ( !is_user_alive(id) ) return

    get_user_origin(id, origin, 0)
    g_lastPosition[id][0]=origin[0]
    g_lastPosition[id][1]=origin[1]
    g_lastPosition[id][2]=origin[2]

    get_user_velocity(id, velocity)
    if ( velocity[0]==0 && velocity[1]==0 && velocity[2] )
    {   
        // Force a Move (small jump)
        velocity[0]=50
        velocity[1]=50
        set_user_velocity(id, velocity)
    }

    new parm[1]
    parm[0]=id
    set_task(secs,"positionChangeCheck",0,parm,1)
}
//----------------------------------------------------------------------------------------------
public positionChangeCheck( parm[1] )
{   
    new id=parm[0]
    new origin[3]

    if (!is_user_alive(id) ) return

    get_user_origin(id, origin, 0)
    if ( g_lastPosition[id][0] == origin[0] && g_lastPosition[id][1] == origin[1] && g_lastPosition[id][2] == origin[2] && is_user_alive(id) )
    {   
        // Kill this player - Vision Still Stuck in wall!
        set_user_health(id, -1)
        set_user_frags(id, get_user_frags(id)-1)
    }
}
//----------------------------------------------------------------------------------------------
