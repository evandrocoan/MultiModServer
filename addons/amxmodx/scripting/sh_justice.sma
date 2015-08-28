#include <amxmod.inc>
#include <vexd_utilities>
#include <superheromod.inc>

// Justice from GGXX - Mobility (Fast, Gravity, Triple Jump)

// CVARS
// justice_gravity 0.70	- how high she jumps with one jump; the lower, the higher
// justice_speed 265	- how fast she runs
// justice_level 0	- level at which her powers become available
// justice_jumpno 3	- number of jumps mid-air + 1 (the initial jump)

// VARIABLES
new gHeroName[]="Justice"
new gHasJusticePower[SH_MAXSLOTS+1]
new gJumps[SH_MAXSLOTS+1]
new bool:inAir[SH_MAXSLOTS+1]
new Float:delayBetweenJumps=0.3
new jumpNo

public plugin_init()
{   
    // Plugin Info
    register_plugin("SUPERHERO Justice","1.0","Mydas")

    // FIRE THE EVENT TO CREATE THIS SUPERHERO!
    if ( isDebugOn() ) server_print("Attempting to create Justice Hero")

    register_cvar("justice_level", "0" )

    shCreateHero(gHeroName, "Mobility", "Faster, Lower Gravity and Triple Jump", false, "justice_level" )

    // REGISTER EVENTS THIS HERO WILL RESPOND TO! (AND SERVER COMMANDS)
    
    // JUSTICE LOOP
    set_task(0.01,"justice_loop",0,"",0,"b" )

    register_srvcmd("justice_init", "justice_init")
    shRegHeroInit(gHeroName, "justice_init")

    // DEFAULT THE CVARS
    
    register_cvar("justice_gravity", "0.70" )
    register_cvar("justice_speed", "265" )
    register_cvar("justice_jumpno", "3" )

}

public justice_init()
{   
    shSetMinGravity(gHeroName, "justice_gravity" )
    shSetMaxSpeed(gHeroName, "justice_speed", "[0]" )
    jumpNo=get_cvar_num("justice_jumpno")

    new temp[128]

    read_argv(1,temp,5)
    new id=str_to_num(temp)

    read_argv(2,temp,5)
    new hasPowers=str_to_num(temp)
    gHasJusticePower[id]=(hasPowers!=0)
    gJumps[id]=0
    inAir[id]=false

    if ( !hasPowers && is_user_connected(id) )
    {   
        shRemGravityPower(id)
        shRemSpeedPower(id)
    }
}

public justice_loop()
{   
    new Float:vector[3]
    for (new id=1; id<=SH_MAXSLOTS; id++)
    {   
        if (gHasJusticePower[id] && !gPlayerUltimateUsed[id] && is_user_alive(id) && (get_user_button(id)&IN_JUMP) && (gJumps[id]<jumpNo-1)) if (inAir[id])
        {   
            gJumps[id]++
            ultimateTimer(id, delayBetweenJumps)
            Entvars_Get_Vector(id, EV_VEC_velocity, vector)
            vector[2] += 105
            if (vector[2]<250.0) vector[2]=250.0
            Entvars_Set_Vector(id, EV_VEC_velocity, vector)
        }
        else
        {   
            inAir[id]=true
            ultimateTimer(id, delayBetweenJumps)
        }
        if (gHasJusticePower[id] && is_user_alive(id) && (entity_get_int(id, EV_INT_flags) & FL_ONGROUND))
        {   
            gJumps[id]=0
            inAir[id]=false
        }
    }
}