#include <amxmodx>
#include <amxmisc>
#include <superheromod>
#include <fakemeta>
#include <engine>
#include <fun>

new gHeroName[] = "Rogue"
new gSound[] = "ambience/alien_zonerator.wav"

new Cooldown[SH_MAXSLOTS+1] = 0
new bool:Stealthed[SH_MAXSLOTS+1] = false

new Float:gNormalSpeed[SH_MAXSLOTS+1] 
new Float:gStealthSpeed[SH_MAXSLOTS+1]
new Float:gCurrentSpeed[SH_MAXSLOTS+1]

public plugin_init()
{
    register_plugin("SUPERHERO Rogue", "1.0", "XunTric")

    register_cvar("rogue_level", "10")
    register_cvar("rogue_radius", "800")
    register_cvar("rogue_stealth_speed", "0.5")
    register_cvar("rogue_cooldown", "10")    

    shCreateHero(gHeroName, "Stealth, WoW style", "Walk around with stealth, World of Warcraft style", true, "rogue_level")

    register_event("DeathMsg", "Death", "b")
    register_event("Damage", "Damage", "b")
    register_event("CurWeapon","CurWeapon","be")

    register_forward(FM_PlayerPreThink, "forward_playerprethink")
    
    register_srvcmd("rogue_kd", "rogue_kd")
    shRegKeyDown(gHeroName, "rogue_kd")

    register_srvcmd("rogue_init", "rogue_init")
    shRegHeroInit(gHeroName, "rogue_init")
}

public plugin_precache()
{
    precache_sound(gSound)
}

public plugin_modules()
{
    require_module("Fun")
    require_module("Engine")
    require_module("Fakemeta")
}

public rogue_init()
{
    new temp[6]
    read_argv(1, temp, 5)
    new id = str_to_num(temp)

    read_argv(2, temp, 5)
    new hasPowers = str_to_num(temp)

    if(!hasPowers)
    {
        UnStealth(id)
    }
}       

public get_team(id)
{
    new team[2]
    get_user_team(id,team,1)
    switch(team[0]){
        case 'T':{
            return 1
        }
        case 'C':{
            return 2
        }
        case 'S':{
            return 3
        }
        default:{}
    }
    return 0
}  

public client_PostThink(id) 
{
    if(!is_user_alive(id))
    {
        return 0
    }

    if(Stealthed[id] == false)
    {
        return 0
    }

    gCurrentSpeed[id] = get_user_maxspeed(id)
    
    if(gCurrentSpeed[id] != gStealthSpeed[id])
    {
        set_user_maxspeed(id, gStealthSpeed[id])
    }

    new origin[3]
    get_user_origin(id, origin)

    new players[32], num, i;
    get_players(players, num, "a")

    for(i = 0; i < num; i++)
    {
        if(is_user_alive(i))
        {
            new team[2]
            team[0] = get_team(id)
            team[1] = get_team(i)

            if(team[0] != team[1])
            {
                new vorigin[3], distance, maxdist
                get_user_origin(i, vorigin, 0)

                maxdist = (get_cvar_num("rogue_radius"))
                distance = get_distance(origin, vorigin)

                if(distance < maxdist)
                {
                    ShowHudMessage(id, "You are now unstealthed! You got too close to an enemy!")
                    UnStealth(id)
                }
            }
        }
    }

    return 0
}               

public forward_playerprethink(id)
{
    if(is_user_alive(id))
    {
        if(Stealthed[id] == true)
        {
            if(entity_get_int(id, EV_INT_button) & IN_ATTACK || entity_get_int(id, EV_INT_button) & IN_ATTACK2)
            {
                ShowHudMessage(id, "You got unstealthed!")
                UnStealth(id)
            }
        }
    }

    return FMRES_IGNORED
}

public StopMusic(id)
{
    emit_sound(id, CHAN_STATIC, gSound, 0.0, ATTN_NORM, 0, PITCH_LOW)

    return PLUGIN_HANDLED
}

public StartMusic(id)
{
    emit_sound(id, CHAN_STATIC, gSound, 0.2, ATTN_NORM, 0, PITCH_LOW)

    return PLUGIN_HANDLED
}

ShowHudMessage(id, const hudmessage[])
{
    set_hudmessage(225, 0, 0, -1.0, 0.3, 0, 0.25, 3.0, 0.0, 0.0, 87)
    show_hudmessage(id, hudmessage)
}

public GoStealth(id)
{
    Stealthed[id] = true

    SetInvinsibility(id)
    SetSpeed(id)
    StartMusic(id)

    return PLUGIN_HANDLED     
}

public UnStealth(id)
{
    Stealthed[id] = false
    Cooldown[id] = get_cvar_num("rogue_cooldown")
    
    set_task(0.1, "StealthCooldown", id)

    RemoveInvinsibility(id)
    RemoveSpeed(id)
    StopMusic(id)

    return PLUGIN_HANDLED
}

public SetInvinsibility(id)
{
    set_user_rendering(id, kRenderFxGlowShell, 0, 0, 0, kRenderTransAlpha, 0)

    return PLUGIN_HANDLED
}

public RemoveInvinsibility(id)
{
    set_user_rendering(id, kRenderFxGlowShell, 0, 0, 0, kRenderTransAlpha, 255)

    return PLUGIN_HANDLED
}

public SetSpeed(id)
{
    gNormalSpeed[id] = get_user_maxspeed(id)

    gStealthSpeed[id] = gNormalSpeed[id] * get_cvar_float("rogue_stealth_speed")

    set_user_maxspeed(id, gStealthSpeed[id])

    //In case of effects by other heroes
    set_task(0.2, "SetSpeed2", id)

    return PLUGIN_HANDLED
}

public SetSpeed2(id)
{
    set_user_maxspeed(id, gStealthSpeed[id])

    return PLUGIN_HANDLED
}

public RemoveSpeed(id)
{
    set_user_maxspeed(id, gNormalSpeed[id])

    set_task(0.2, "RemoveSpeed2", id)

    return PLUGIN_HANDLED
}

public RemoveSpeed2(id)
{
    set_user_maxspeed(id, gNormalSpeed[id])

    return PLUGIN_HANDLED
}

public StealthCooldown(id)
{
    if(!is_user_alive(id))
    {
        Cooldown[id] = 0
        return PLUGIN_HANDLED
    }

    if(Cooldown[id] <= 0)
    {
        Cooldown[id] = 0
        return PLUGIN_HANDLED
    }

    Cooldown[id] -= 1
    set_task(1.0, "StealthCooldown", id)

    return PLUGIN_HANDLED
}
         
public CurWeapon(id)
{
    if(Stealthed[id] == true)
    {
        SetSpeed2(id)        
    }

    return PLUGIN_CONTINUE
}

public Damage(id)
{
    if(Stealthed[id] == true)
    {
        ShowHudMessage(id, "You got damaged! You are now unstealthed!")
        UnStealth(id)
    }

    return PLUGIN_CONTINUE
}
          
public Death(id)
{    
    if(Stealthed[id] == true)
    {
        UnStealth(id)
    }

    return PLUGIN_CONTINUE
}

public rogue_kd()
{
    if(!shModActive())
    {
        return PLUGIN_HANDLED
    }

    new temp[6]
    read_argv(1, temp, 5)
    new id = str_to_num(temp)

    if(!is_user_alive(id))
    {
        ShowHudMessage(id, "You cant stealth while you are dead!")
        playSoundDenySelect(id)

        return PLUGIN_HANDLED
    }

    if(Cooldown[id] >= 1)
    {
        new buffer[128]
        format(buffer, 127, "You must wait %d secs before stealthing again!", Cooldown[id])

        ShowHudMessage(id, buffer)
        playSoundDenySelect(id)
        
        return PLUGIN_HANDLED
    }
        
    if(Stealthed[id] == false)
    {
        ShowHudMessage(id, "You are now stealthed! Dont get too close to enemies!")
        GoStealth(id)

        return PLUGIN_HANDLED
    }

    else
    {
        ShowHudMessage(id, "You are now unstealthed!")
        UnStealth(id)

        return PLUGIN_HANDLED
    }

    return PLUGIN_HANDLED
} 
