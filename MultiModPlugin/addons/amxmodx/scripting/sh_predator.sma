#include <amxmod.inc> 
#include <amxmisc> 
#include <xtrafun>
#include <superheromod.inc>

// Predator - Watch the movie

// CVARS
// pred_level      
// perd_DLbullets
// pred_cooldown
// pred_clockedmove
// pred_knifemult

// sprites! 
new spr_laser
new spr_laser_impact
new spr_blast_shroom

// VARIABLES
new gHeroName[]="Predator"
new gHasPredPower[SH_MAXSLOTS+1]
new gLastWeapon[SH_MAXSLOTS+1]
new gDLaserFired[33] = 0
new gDLLastWeapon[33]=0
new gLastClipCount[33]=0

// VARIABLES
new smoke
new laser
new laser_shots[33]
new lastammo[33]
new lastweap[33]

// Damage Variables
#define h1_dam 400 //head
#define h2_dam 200  //body
#define h3_dam 200  //stomach
#define h4_dam 80  //arm
#define h6_dam 80  //leg

//----------------------------------------------------------------------------------------------
public plugin_init()
{   
    // Plugin Info
    register_plugin("SUPERHERO Predator","1.14.4","norma jean")

    // FIRE THE EVENT TO CREATE THIS SUPERHERO!
    if ( isDebugOn() ) server_print("Attempting to create Predator Hero")
    register_cvar("pred_level", "7")
    shCreateHero(gHeroName, "Invisibility, LaserCannon, Lazer Deagle, SuperClaw", "Invisibility while not shooting, Super Claw, Laser Beam", true, "pred_level")

    // REGISTER EVENTS THIS HERO WILL RESPOND TO! (AND SERVER COMMANDS)
    register_event("ResetHUD","newRound","b")
    // LASER DEAGLE DAMAGE
    register_event("Damage", "pred_DLdamage", "b", "2!0")
    // COUTING Laser
    register_event("CurWeapon","changeWeapon","be","1=1")
    // MAKE A TRAIL OF THE Laser
    register_event("CurWeapon","make_tracer", "be", "1=1", "3>0")

    // INIT
    shRegHeroInit(gHeroName, "pred_init")
    register_srvcmd("pred_init", "pred_init")

    // KEY DOWN
    register_srvcmd("pred_kd", "pred_kd")
    shRegKeyDown(gHeroName, "pred_kd")
    register_srvcmd("pred_ku", "pred_ku")
    shRegKeyUp(gHeroName, "pred_ku")

    // Laser
    register_cvar("pred_laser_ammo", "1")// total # of shots...
    register_cvar("pred_laser_burndecals", "1")
    register_cvar("pred_cooldown", "10" )

    // EXTRA KNIFE DAMAGE
    register_event("Damage", "pred_damage", "b", "2!0")

    // CHECK SOME BUTTONS
    set_task(0.01,"check_attack",0,"",0,"b")
    set_task(0.01,"check_two_buttons",0,"",0,"b")
    set_task(0.01,"check_move_buttons",0,"",0,"b")

    // DEFAULT THE CVARS
    register_cvar("pred_clockedmove", "1")
    register_cvar("pred_knifemult", "10" )
    if ( !cvar_exists("pred_DLbullets") ) register_cvar("pred_DLbullets", "7")
    if ( !cvar_exists("pred_getdeagle") ) register_cvar("pred_getdeagle", "0")

}
//----------------------------------------------------------------------------------------------
public plugin_precache()
{   
    smoke = precache_model("sprites/steam1.spr")
    laser = precache_model("sprites/laserbeam.spr")
    precache_sound("weapons/electro5.wav")
    precache_sound("weapons/xbow_hitbod2.wav")
    spr_laser = precache_model("sprites/laserbeam.spr")
    spr_laser_impact = precache_model("sprites/zerogxplode.spr")
    spr_blast_shroom = precache_model("sprites/mushroom.spr")
    return PLUGIN_CONTINUE
}

public pred_init()
{   
    new temp[128]
    // First Argument is an id
    read_argv(1,temp,5)
    new id=str_to_num(temp)

    // 2nd Argument is 0 or 1 depending on whether the id has Predator
    read_argv(2,temp,5)
    new hasPowers=str_to_num(temp)
    gHasPredPower[id]=(hasPowers!=0)

    // Got to remove the powers if he is not Predator
    if ( !hasPowers )
    uninvis(id)

    //Give Powers to the Predator
    if ( hasPowers )
    {   
        stillInvis(id)
        set_user_footsteps(id,1)
    }
}

public newRound(id)
{   
    if ( is_user_alive(id) && gHasPredPower[id])
    {   
        stillInvis(id)
    }

    if ( !hasRoundStarted() )
    {   
        laser_shots[id] = get_cvar_num("pred_laser_ammo")
        set_user_rendering(id,kRenderGlow,0,128,0,kRenderFxNone,255)
        gPlayerUltimateUsed[id]=false
    }

    gDLaserFired[id] = 0
    gPlayerUltimateUsed[id]=false
    gDLLastWeapon[id]=-1 // I think the change Weapon automatically gets called on spawn death too...
    
    if (gHasPredPower[id] && get_cvar_num("pred_getdeagle")==1)
    {   
        shGiveWeapon(id,"weapon_deagle")
    }
}

public pred_kd()
{   
    new temp[6]

    if ( !hasRoundStarted() ) return PLUGIN_HANDLED

    // First Argument is an id with Pred Powers! 
    read_argv(1,temp,5)
    new id=str_to_num(temp)
    if ( !is_user_alive(id) ) return PLUGIN_HANDLED

    // Remember this weapon...
    new clip,ammo,weaponID=get_user_weapon(id,clip,ammo);
    gLastWeapon[id]=weaponID

    // switch to knife
    // engclient_cmd(id,"weapon_knife")    
    
    // Let them know they already used their ultimate if they have 
    new parm[1]
    parm[0]=id
    predFire(parm)// 1 immediate shot
    set_task( get_cvar_float("pred_cooldown"), "predFire", id, parm, 1, "b")//delayed shots
    return PLUGIN_HANDLED
}

public predFire(parm[])
{   
    fire_laser(parm[0])
}

//----------------------------------------------------------------------------------------------
public pred_ku()
{   
    new temp[6]

    // First Argument is an id with Predator Powers! 
    read_argv(1,temp,5)
    new id=str_to_num(temp)

    remove_task(id)

    // Switch back to previous weapon... 
    // if ( gLastWeapon[id]!=CSW_KNIFE ) shSwitchWeaponID( id, gLastWeapon[id])
}
//----------------------------------------------------------------------------------------------
public laserEffects(id, aimvec[3] )
{   
    new choose_decal,decal_id

    emit_sound(id,CHAN_ITEM, "weapons/electro5.wav", 1.0, ATTN_NORM, 0, PITCH_NORM)

    choose_decal = random_num(0,0)
    switch(choose_decal)
    {   
        case 0: decal_id = 28
        case 1: decal_id = 103
        case 2: decal_id = 198
        case 3: decal_id = 199
    }

    new origin[3]
    get_user_origin(id, origin, 1)

    // DELIGHT
    message_begin( MSG_BROADCAST,SVC_TEMPENTITY)
    write_byte( 27 )
    write_coord( origin[0] )//pos 
    write_coord( origin[1] )
    write_coord( origin[2] )
    write_byte( 10 )
    write_byte( 250 )// r, g, b 
    write_byte( 0 )// r, g, b 
    write_byte( 0 )// r, g, b 
    write_byte( 2 )// life
    write_byte( 1 )// decay
    message_end()

    //BEAMENTPOINTS
    message_begin( MSG_BROADCAST,SVC_TEMPENTITY)
    write_byte ( 0 )//TE_BEAMENTPOINTS 0  
    write_coord(origin[0])
    write_coord(origin[1])
    write_coord(origin[2])
    write_coord(aimvec[0])
    write_coord(aimvec[1])
    write_coord(aimvec[2])
    write_short( laser )
    write_byte( 1 )// framestart 
    write_byte( 5 )// framerate 
    write_byte( 2 )// life 
    write_byte( 20 )// width 
    write_byte( 0 )// noise 
    write_byte( 250 )// r, g, b 
    write_byte( 0 )// r, g, b 
    write_byte( 0 )// r, g, b 
    write_byte( 200 )// brightness 
    write_byte( 200 )// speed 
    message_end()

    //Sparks 
    message_begin( MSG_PVS, SVC_TEMPENTITY)
    write_byte( 9 )
    write_coord( aimvec[0] )
    write_coord( aimvec[1] )
    write_coord( aimvec[2] )
    message_end()

    //Smoke    
    message_begin( MSG_BROADCAST,SVC_TEMPENTITY)
    write_byte( 5 )// 5 
    write_coord(aimvec[0])
    write_coord(aimvec[1])
    write_coord(aimvec[2])
    write_short( smoke )
    write_byte( 22 )// 10 
    write_byte( 10 )// 10 
    message_end()

    if(get_cvar_num("pred_laser_burndecals") == 1)
    {   
        //TE_GUNSHOTDECAL 
        message_begin( MSG_BROADCAST,SVC_TEMPENTITY)
        write_byte( 109 )// decal and ricochet sound 
        write_coord( aimvec[0] )//pos 
        write_coord( aimvec[1] )
        write_coord( aimvec[2] )
        write_short (0)// I have no idea what thats supposed to be 
        write_byte (decal_id)//decal 
        message_end()
    }

}
//----------------------------------------------------------------------------------------------
public fire_laser(id)
{   
    new aimvec[3]
    new tid,tbody
    new FFOn= get_cvar_num("mp_friendlyfire")

    if( !is_user_alive(id) ) return

    if ( laser_shots[id]<=0 )
    {   
        playSoundDenySelect(id)
        return
    }

    // Use the ultimate
    // ultimateTimer(id, get_cvar_float("pred_cooldown") )
    
    // Make sure still on knife
    new clip,ammo,weaponID=get_user_weapon(id,clip,ammo);
    if ( weaponID != CSW_KNIFE ) engclient_cmd(id,"weapon_knife")

    // Warn How many Blasts Left...
    laser_shots[id]--
    if(laser_shots[id] < 6) client_print(id,print_chat,"Warning %d Predator Shots Left", laser_shots[id] )

    get_user_origin(id,aimvec,3)
    laserEffects(id, aimvec)

    get_user_aiming(id,tid,tbody,9999)

    if( tid > 0 && tid < 33 && ( FFOn || get_user_team(id)!=get_user_team(tid) ) )
    {   
        emit_sound(tid,CHAN_BODY, "weapons/xbow_hitbod2.wav", 1.0, ATTN_NORM, 0, PITCH_NORM)

        // Determine the damage
        new damage;
        switch(tbody)
        {   
            case 1: damage=h1_dam
            case 2: damage=h2_dam
            case 3: damage=h3_dam
            case 4: damage=h4_dam
            case 5: damage=h4_dam
            case 6: damage=h6_dam
            case 7: damage=h6_dam
        }

        // Deal the damage...
        shExtraDamage(tid, id, damage, "Predator Laser")
    }
}

public stillInvis(id)
{   
    set_user_rendering(id,kRenderFxGlowShell,0,0,0,kRenderTransAlpha,30)
}

public moveInvis(id)
{   
    set_user_rendering(id,kRenderFxGlowShell,0,0,0,kRenderTransAlpha,80)
}

public uninvis(id)
{   
    set_user_rendering(id,kRenderFxGlowShell,0,0,0,kRenderTransAlpha,255)
}

public check_attack()
{   

    for(new i = 1; i <= get_maxplayers(); ++i)
    {   
        if (is_user_alive(i))
        {   
            if ((get_user_button(i)&IN_ATTACK) && gHasPredPower[i])
            {   
                uninvis(i)
            }
            else if (!(get_user_button(i)&IN_ATTACK) && gHasPredPower[i])
            {   
                stillInvis(i)
            }
        }
    }
    return PLUGIN_CONTINUE
}

public check_two_buttons()
{   

    for(new i = 1; i <= get_maxplayers(); ++i)
    {   
        if (is_user_alive(i))
        {   
            if ((get_user_button(i)&IN_USE) && gHasPredPower[i])
            {   
                stillInvis(i)
            }
            if ((get_user_button(i)&IN_ATTACK2) && gHasPredPower[i])
            {   
                uninvis(i)
            }
        }
    }
    return PLUGIN_CONTINUE
}

public check_move_buttons()
{   
    if (get_cvar_num("pred_clockedmove")==1)
    {   
        for(new i = 1; i <= get_maxplayers(); ++i)
        {   
            if (is_user_alive(i))
            {   
                if ((get_user_button(i)&IN_BACK) && gHasPredPower[i])
                {   
                    moveInvis(i)
                }
                if ((get_user_button(i)&IN_MOVELEFT) && gHasPredPower[i])
                {   
                    moveInvis(i)
                }
                if ((get_user_button(i)&IN_MOVERIGHT) && gHasPredPower[i])
                {   
                    moveInvis(i)
                }
                if ((get_user_button(i)&IN_FORWARD) && gHasPredPower[i])
                {   
                    moveInvis(i)
                }
                if ((get_user_button(i)&IN_RUN) && gHasPredPower[i])
                {   
                    moveInvis(i)
                }
            }
        }
        return PLUGIN_CONTINUE
    }

    for(new i = 1; i <= get_maxplayers(); ++i)
    {   
        if (is_user_alive(i))
        {   
            if ((get_user_button(i)&IN_BACK) && gHasPredPower[i])
            {   
                uninvis(i)
            }
            if ((get_user_button(i)&IN_MOVELEFT) && gHasPredPower[i])
            {   
                uninvis(i)
            }
            if ((get_user_button(i)&IN_MOVERIGHT) && gHasPredPower[i])
            {   
                uninvis(i)
            }
            if ((get_user_button(i)&IN_FORWARD) && gHasPredPower[i])
            {   
                uninvis(i)
            }
            if ((get_user_button(i)&IN_RUN) && gHasPredPower[i])
            {   
                uninvis(i)
            }
        }
    }
    return PLUGIN_CONTINUE
}

public pred_damage(id)
{   
    if (!shModActive() ) return PLUGIN_CONTINUE
    new damage = read_data(2)
    new weapon, bodypart, attacker = get_user_attacker(id, weapon, bodypart)

    if ( attacker <=0 || attacker>SH_MAXSLOTS ) return PLUGIN_CONTINUE

    if ( gHasPredPower[attacker] && weapon == CSW_KNIFE && is_user_alive(id) )
    {   
        // do extra damage
        new extraDamage = floatround(damage * get_cvar_float("pred_knifemult") - damage)
        shExtraDamage( id, attacker, extraDamage, "Super Knife" )
    }
    return PLUGIN_CONTINUE
}

public pred_DLdamage(id)
{   
    if (!shModActive()) return PLUGIN_CONTINUE

    new damage = read_data(2)
    new weapon, bodypart, attacker_id = get_user_attacker(id,weapon,bodypart)

    if ( attacker_id <=0 || attacker_id>SH_MAXSLOTS ) return PLUGIN_CONTINUE

    if ( gHasPredPower[attacker_id] && weapon == CSW_DEAGLE && is_user_alive(id) && (!gPlayerUltimateUsed[attacker_id]))
    {   
        new health = get_user_health(id)

        // mah nigga $id wasn't attacked by another player 
        if (!is_user_connected(attacker_id)) return PLUGIN_CONTINUE
        if (attacker_id == id) return PLUGIN_CONTINUE

        // damage is less than 10% 
        if (((1.0 * damage) / (1.0 * (health + damage))) < 0.01) return PLUGIN_CONTINUE

        new origin[3]
        new attacker_team[2], victim_team[2]

        get_user_origin(id, origin)

        // beeeg explody! 
        message_begin(MSG_ALL, SVC_TEMPENTITY)
        write_byte(3)// TE_EXPLOSION 
        write_coord(origin[0])
        write_coord(origin[1])
        write_coord(origin[2]-22)
        write_short(spr_blast_shroom)// mushroom cloud 
        write_byte(40)// scale in 0.1u 
        write_byte(12)// frame rate 
        write_byte(12)// TE_EXPLFLAG_NOPARTICLES & TE_EXPLFLAG_NOSOUND 
        message_end()

        // do turn down that awful racket 
        
        // ..to be replaced by a blood spurt! 
        message_begin(MSG_ALL, SVC_TEMPENTITY)
        write_byte(10)// TE_LAVASPLASH 
        write_coord(origin[0])
        write_coord(origin[1])
        write_coord(origin[2]-26)
        message_end()

        // kill victim
        user_kill(id, 1)
        message_begin( MSG_ALL, get_user_msgid("DeathMsg"),
                {   0,0,0},0)
        write_byte(attacker_id)
        write_byte(id)
        write_byte(0)
        write_string("deagle")
        message_end()
        //Save Hummiliation
        new namea[24],namev[24],authida[20],authidv[20],teama[8],teamv[8]
        //Info On Attacker
        get_user_name(attacker_id,namea,23)
        get_user_team(attacker_id,teama,7)
        get_user_authid(attacker_id,authida,19)
        //Info On Victim
        get_user_name(id,namev,23)
        get_user_team(id,teamv,7)
        get_user_authid(id,authidv,19)
        //Log This Kill
        log_message("^"%s<%d><%s><%s>^" killed ^"%s<%d><%s><%s>^" with ^"Predator Laser Deagle^"",
                namea,get_user_userid(attacker_id),authida,teama,namev,get_user_userid(id),authidv,teamv)

        /* set_user_health(id, 0) */

        // team check! 
        get_user_team(attacker_id, attacker_team, 1)
        get_user_team(id, victim_team, 1)

        // for some reason this doesn't update in the hud until the next round.. whatever. 
        if (!equali(attacker_team, victim_team))
        {   
            // diff. team;    $attacker_id gets credited for the kill and $250 and XP.
            //        $id gets their suicidal -1 frag back. 
            set_user_frags(attacker_id, get_user_frags(attacker_id)+1)
            set_user_money(attacker_id, get_user_money(attacker_id)+150)
            shAddXP(attacker_id, id, 1)
        }
        else
        {   
            // same team;    $attacker loses a frag and $500 and XP.
            set_user_frags(attacker_id, get_user_frags(attacker_id)-1)
            set_user_money(attacker_id, get_user_money(attacker_id)-500, 0)
            shAddXP(attacker_id, id, -1)
        }
        return PLUGIN_CONTINUE
    }
    return PLUGIN_CONTINUE
}

public make_tracer(id)
{   

    if (!shModActive()) return PLUGIN_CONTINUE

    new weap = read_data(2) // id of the weapon 
    new ammo = read_data(3)// ammo left in clip 
    
    if ( gHasPredPower[id] && weap == CSW_DEAGLE && is_user_alive(id) && (!gPlayerUltimateUsed[id]) )
    {   

        if (lastweap[id] == 0) lastweap[id] = weap

        if ((lastammo[id] > ammo) && (lastweap[id] == weap))
        {   

            new vec1[3], vec2[3]
            get_user_origin(id, vec1, 1) // origin; where you are 
            get_user_origin(id, vec2, 4)// termina; where your bullet goes 
            
            // tracer beam 
            message_begin(MSG_PAS, SVC_TEMPENTITY, vec1)
            write_byte(0)// TE_BEAMPOINTS 
            write_coord(vec1[0])
            write_coord(vec1[1])
            write_coord(vec1[2])
            write_coord(vec2[0])
            write_coord(vec2[1])
            write_coord(vec2[2])
            write_short(spr_laser)// laserbeam sprite 
            write_byte(0)// starting frame 
            write_byte(10)// frame rate 
            write_byte(2)// life in 0.1s 
            write_byte(4)// line width in 0.1u 
            write_byte(1)// noise in 0.1u 
            write_byte(255)// red
            write_byte(0)// green 
            write_byte(0)// blue
            write_byte(80)// brightness 
            write_byte(100)// scroll speed 
            message_end()

            // bullet impact explosion 
            message_begin(MSG_PAS, SVC_TEMPENTITY, vec2)
            write_byte(3)// TE_EXPLOSION 
            write_coord(vec2[0])// end point of beam 
            write_coord(vec2[1])
            write_coord(vec2[2])
            write_short(spr_laser_impact)// blast sprite 
            write_byte(10)// scale in 0.1u 
            write_byte(30)// frame rate 
            write_byte(8)// TE_EXPLFLAG_NOPARTICLES 
            message_end()// ..unless i'm mistaken, noparticles helps avoid a crash 
        }

        lastammo[id] = ammo
        lastweap[id] = weap

        return PLUGIN_CONTINUE
    }
    return PLUGIN_CONTINUE
}
//----------------------------------------------------------------------------------------------
//----------------------------------------------------------------------------------------------
public changeWeapon(id)
{   
    if ( !gHasPredPower[id] || !shModActive() ) return PLUGIN_CONTINUE
    new clip, ammo
    new wpn_id=get_user_weapon(id, clip, ammo);

    if ( wpn_id!=CSW_DEAGLE ) return PLUGIN_CONTINUE

    // This event gets trigger on a switch to a weapon too...
    // Easy work around
    if ( wpn_id != gDLLastWeapon[id] )
    {   
        gDLLastWeapon[id]=wpn_id
        return PLUGIN_CONTINUE // user just switched weapons
    }

    if ( clip >= gLastClipCount[id] )
    {   
        gLastClipCount[id]=clip
        return PLUGIN_CONTINUE
    }
    gLastClipCount[id]=clip

    // Ok - if it fell through here - you got a user firing the laser deagle
    
    // Bullet Count
    gDLaserFired[id]=(gDLaserFired[id] + 1)
    new bullets = (get_cvar_num("pred_DLbullets")-gDLaserFired[id])

    if (bullets == 0)
    {   
        gPlayerUltimateUsed[id]=true
    }
    if (bullets <= 0)
    {   
        gPlayerUltimateUsed[id]=true
    }
    if ((bullets != 0) && bullets >= 0 )
    {   
        new message[128]
        format(message, 127, "You Have %d laser bullets left",bullets)
        set_hudmessage(255,0,0,-1.0,0.3,0,0.25,1.0,0.0,0.0,4)
        show_hudmessage(id, message)
    }
    return PLUGIN_CONTINUE
}

