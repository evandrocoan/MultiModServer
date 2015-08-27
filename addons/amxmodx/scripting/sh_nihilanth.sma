#include <amxmod.inc>
#include <xtrafun>
#include <superheromod.inc>

//Nihilanth rocks!!!

// VARIABLES
new gHeroName[]="Nihilanth"
new bool:gHasNihilanthPowers[SH_MAXSLOTS+1]=
{   false}
new gPlayerLevels[SH_MAXSLOTS+1]
//BREAK
//--------------------------------------------------------------------------------------------------------
public plugin_init()
{   
    // Plugin Info
    register_plugin("Nihilanth","1.0","Coolfat3459")

    if ( isDebugOn() ) server_print("Attempting to create NIHILANTH Hero")
    register_cvar("nil_level", "2" )
    shCreateHero(gHeroName, "Spawn aliens", "Spawn aliens from Xen on keydown", true, "nil_level" )

    register_event("ResetHUD","nil_newround","b")
    register_srvcmd("nil_init", "nil_init")
    shRegHeroInit(gHeroName, "nil_init")

    register_srvcmd("nil_levels", "nil_levels")
    shRegLevels(gHeroName,"nil_levels")

    register_srvcmd("nil_kd", "nil_kd")
    shRegKeyDown(gHeroName, "nil_kd")

    register_cvar("nil_cooldown", "3")
}
//--------------------------------------------------------------------------------------------------------
public nil_newround(id)
{   
    gPlayerUltimateUsed[id]=false

}
//--------------------------------------------------------------------------------------------------------
public nil_kd()
{   
    // First Argument is an id with Nihilanth Powers!
    new temp[6]
    read_argv(1,temp,5)
    new id=str_to_num(temp)

    if ( gHasNihilanthPowers[id] && hasRoundStarted() )
    {   
        if ( gPlayerUltimateUsed[id] )
        {   
            playSoundDenySelect(id)
            return PLUGIN_HANDLED
        }
        nil_summon(id)
        ultimateTimer(id, get_cvar_num("nil_cooldown") * 1.0)
    }
    return PLUGIN_HANDLED
}
//----------------------------------------------------------------------------------------------
public plugin_precache()
{   
    precache_sound("debris/beamstart7.wav")
}
//--------------------------------------------------------------------------------------------------------
public nil_init()
{   
    new temp[6]
    // First Argument is an id
    read_argv(1,temp,5)
    new id=str_to_num(temp)

    // 2nd Argument is 0 or 1 depending on whether the id has Nihilanth skills
    read_argv(2,temp,5)
    new hasPowers=str_to_num(temp)

    if ( hasPowers )
    gHasNihilanthPowers[id]=true
    else
    gHasNihilanthPowers[id]=false
}
//--------------------------------------------------------------------------------------------------------
public nil_levels()
{   
    new id[5]
    new lev[5]

    read_argv(1,id,4)
    read_argv(2,lev,4)

    gPlayerLevels[str_to_num(id)]=str_to_num(lev)
}
//--------------------------------------------------------------------------------------------------------
public nil_summon(id)
{   
    if ( gHasNihilanthPowers[id] && is_user_alive(id) )
    {   
        new targetid, body
        get_user_aiming(id, targetid, body)
        if (targetid)
        {   
            new cmd[128]
            format(cmd, 127, "monster islave #%i", targetid )
            server_cmd(cmd)
            emit_sound(id, CHAN_STATIC, "debris/beamstart7.wav", 1.0, ATTN_NORM, 0, PITCH_NORM)
        }
        else
        {   
            client_print(id,print_center,"Crosshairs must be on someone to spawn")
        }
    }
    return PLUGIN_HANDLED
}
//--------------------------------------------------------------------------------------------------------
