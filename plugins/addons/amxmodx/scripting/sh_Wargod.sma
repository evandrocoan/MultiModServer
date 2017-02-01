//Wargod

/*
 Credits : kanu|DarkPredator for DarkPredator
 Credits : {HOJ} Batman for Skeletor
 Credits : Freecode / AssKicR for Alien
 Credits : AssKicR/Batman/JTP10181 for Cyclops
 Credits : {HOJ} Batman/JTP10181 for Captain America
 Credits : {HOJ} Batman for Xavier 
 Credits : AssKicR / JTP10181 for Magneto
 Credits : AssKicR / JTP10181 for Anubis
 Credits : {HOJ} Batman/JTP10181 for Zeus
 */

/* CVARS - COPY AND PASTE TO SHCONFIG.CFG

 Wargod_level 0
 Wargod_armor 600
 Wargod_health 600
 Wargod_alpha 10
 Wargod_delay 2
 Wargod_checkmove 0
 Wargod_radius 900
 Wargod_bright 192
 Wargod_healpoints 10
 Wargod_bullets 7
 Wargod_vision 160
 Wargod_tint 50
 Wargod_deaglemode 0
 Wargod_cooldown 10
 Wargod_camptime 10
 Wargod_movedist 10
 Wargod_pctperlev 0.1
 Wargod_godsecs 2
 Wargod_traillength 25
 Wargod_showteam 0
 Wargod_showenemy 1
 Wargod_refreshtimer 5.0
 Wargod_boost 250
 Wargod_giveglock 1
 Wargod_showdamage 1
 Wargod_showchat 1
 Wargod_laser_ammo 999
 Wargod_laser_burndecals 1
 Wargod_mulishot 1
 */

// Damage Variables
#define h1_dam 1000 //head
#define h2_dam 560  //body
#define h3_dam 560  //stomach
#define h4_dam 360  //arm
#define h6_dam 360  //leg

#include <amxmod>
#include <Vexd_Utilities>
#include <superheromod>
#include <xtrafun>

// VARIABLES
new gHeroName[]="Wargod"
new gHasWargodPower[SH_MAXSLOTS+1]
new gIsInvisible[SH_MAXSLOTS+1]
new gStillTime[SH_MAXSLOTS+1]
new gSpriteWhite, gRadius, gBright
new gPlayerMaxHealth[SH_MAXSLOTS+1]
new gHealPoints
new gBullets[SH_MAXSLOTS+1]
new gLastWeapon[SH_MAXSLOTS+1]
new gLastClipCount[SH_MAXSLOTS+1]
new laser,laser_impact,blast_shroom,smoke,laser_shots[SH_MAXSLOTS+1]
new gmsgSetFOV, gTintView, gAlphaInvis
new bool:gWargodModeOn[SH_MAXSLOTS+1]
new gPlayerPosition[SH_MAXSLOTS+1][3]
new gMoveTimer[SH_MAXSLOTS+1]
new gPlayerLevels[SH_MAXSLOTS+1]
new gSpriteLightning
new gmsgSayText
static const burn_decal[5] =
{   199,200,201,202,203}
new gBetweenRounds

//----------------------------------------------------------------------------------------------

public plugin_init()
{   
    // Plugin Info
    register_plugin("SUPERHERO Wargod","2.0","Mega")

    // FIRE THE EVENT TO CREATE THIS SUPERHERO!
    if ( isDebugOn() ) server_print("Attempting to create Wargod Hero")
    register_cvar("Wargod_level", "10" )

    shCreateHero(gHeroName, "Wargod", "HP,AP,Ivisible,regenration,alien vision,esp,exploding bullets,summon monsters,random invincibility,Detect Team,Metal Control,Dark Notices,Raise Dead,Laser Shots", true, "Predalien_level" )

    // REGISTER EVENTS THIS HERO WILL RESPOND TO! (AND SERVER COMMANDS)
    
    // INIT
    register_srvcmd("Wargod_init", "Wargod_init")
    shRegHeroInit(gHeroName, "Wargod_init")

    // NEW ROUND
    register_event("ResetHUD","newRound","b")//Called on a New Round
    // WEAPON EVENT
    register_event("CurWeapon","changeWeapon","be","1=1")
    //Damage
    register_event("Damage", "Wargod_damage", "b", "2!0")

    // DEFAULT THE CVARS
    register_cvar("Wargod_level","0")
    register_cvar("Wargod_armor", "600")
    register_cvar("Wargod_health", "600")
    register_cvar("Wargod_alpha", "10")
    register_cvar("Wargod_delay", "2")
    register_cvar("Wargod_checkmove", "0")
    register_cvar("Wargod_healpoints", "10" )
    register_cvar("Wargod_radius", "900")
    register_cvar("Wargod_bright", "192")
    register_cvar("Wargod_bullets", "7")
    register_cvar("Wargod_vision", "160")
    register_cvar("Wargod_tint", "50")
    register_cvar("Wargod_deaglemode", "0")
    register_cvar("Wargod_cooldown", "10" )
    register_cvar("Wargod_camptime", "10" )
    register_cvar("Wargod_movedist", "10" )
    register_cvar("Wargod_pctperlev", "0.1" )
    register_cvar("Wargod_godsecs", "2" )
    register_cvar("Wargod_traillength", "25" )
    register_cvar("Wargod_showteam", "0" )
    register_cvar("Wargod_showenemy", "1" )
    register_cvar("Wargod_refreshtimer", "5.0" )
    register_cvar("Wargod_boost", "250" )
    register_cvar("Wargod_giveglock", "1" )
    register_cvar("Wargod_laser_ammo", "999")
    register_cvar("Wargod_laser_burndecals", "1")
    register_cvar("Wargod_mulishot", "1" )

    // Let Server know about Wargods Variables
    // It is possible that another hero has more hps, less gravity, or more armor
    // so rather than just setting these - let the superhero module decide each round
    shSetMaxArmor(gHeroName, "Wargod_armor" )
    shSetMaxHealth(gHeroName, "Wargod_health" )

    // CHECK SOME BUTTONS
    set_task(0.1,"checkButtons",0,"",0,"b")

    // HEAL LOOP
    set_task(1.0,"Wargod_loop",0,"",0,"b" )

    //ESP Rings Task
    set_task(2.0, "Wargod_esploop", 0, "", 0, "b")

    //Makes superhero tell DarkPredator a players max health
    register_srvcmd("Wargod_maxhealth", "Wargod_maxhealth")
    shRegMaxHealth(gHeroName, "Wargod_maxhealth" )
    gHealPoints = get_cvar_num("Wargod_healpoints")

    // BULLETS FIRED
    register_event("CurWeapon","Wargod_fire", "be", "1=1", "3>0")

    gmsgSetFOV = get_user_msgid("SetFOV")

    // LEVELS
    register_srvcmd("Wargod_levels", "Wargod_levels")
    shRegLevels(gHeroName,"Wargod_levels")

    set_task(1.0,"Wargod_campcheck",0,"",0,"b" )

    // OK Random Generator
    set_task(1.0,"Wargod_loop",0,"",0,"b" )

    // GET MORE GUNZ!
    register_event("ResetHUD","newRound","b")
    register_event("Damage", "Wargod_damage", "b", "2!0")

    //Shield Restrict
    shSetShieldRestrict(gHeroName)

    // Damage Event
    register_event("Damage", "damage_msg", "b", "2!0", "3=0", "4!0")

    // Say
    register_clcmd("say", "handle_say")
    register_clcmd("say_team", "handle_say")

    gmsgSayText = get_user_msgid("SayText")

    // KEY DOWN
    register_srvcmd("Wargod_kd", "Wargod_kd")
    shRegKeyDown(gHeroName, "Wargod_kd")
    register_srvcmd("Wargod_ku", "Wargod_ku")
    shRegKeyUp(gHeroName, "Wargod_ku")

    // ROUND EVENTS
    register_logevent("round_start", 2, "1=Round_Start")
    register_logevent("round_end", 2, "1=Round_End")
    register_logevent("round_end", 2, "1&Restart_Round_")

    // DEATH
    register_event("DeathMsg", "Wargod_death", "a")
}
//----------------------------------------------------------------------------------------------
public plugin_precache()
{   
    gSpriteWhite = precache_model("sprites/white.spr")
    laser = precache_model("sprites/laserbeam.spr")
    laser_impact = precache_model("sprites/zerogxplode.spr")
    blast_shroom = precache_model("sprites/mushroom.spr")
    precache_sound("ambience/port_suckin1.wav")
    precache_sound("ambience/deadsignal1.wav")
    gSpriteLightning = precache_model("sprites/lgtning.spr")
    smoke = precache_model("sprites/steam1.spr")

}
//----------------------------------------------------------------------------------------------
public Wargod_init()
{   
    new temp[6] //Variable to store temp info in
    // First Argument is an id
    read_argv(1,temp,5)//This Checks for the ID of the person selecting/dropping this hero and saves as string
    new id=str_to_num(temp)//This makes the string Into a num
    
    // 2nd Argument is 0 or 1 depending on whether the id has Predalien
    read_argv(2,temp,5)//This Checks if ID has this hero
    new hasPowers=str_to_num(temp)//This makes the string into a num
    gHasWargodPower[id]=(hasPowers!=0)//Store if this person has the hero
    
    if ( hasPowers && is_user_alive(id) )
    {   
        changeWeapon(id)

        gPlayerMaxHealth[id] = 100

        if ( hasPowers ) //Check if person selected this hero
        {   
            remInvisibility(id)
            shGiveWeapon(id,"weapon_deagle")
        }
        // Got to slow down Predalien that lost his powers...
        if ( !hasPowers && is_user_connected(id) )//Check if person dropped this hero
        
        //This gets run if they had the power but don't anymore
        if ( !hasPowers && gHasWargodPower[id] )
        {   
            Wargod_normal(id)
            shRemHealthPower(id)
            shRemArmorPower(id) //Loose the AP power of this hero
            
            //Clear out any stale tasks
            remove_task(id)

            if ( hasPowers )
            {   
                set_task(get_cvar_float("Wargod_refreshtimer"),"trailMoveCheck", id, "", 0, "b")
            }
            //This gets run if they had the power but don't anymore
            else if (gHasWargodPower[id])
            {   
                removeAllMarks(id)

                //Reset thier shield restrict status
                //Shield restrict MUST be before weapons are given out
                shResetShield(id)

                if (gHasWargodPower[id]) Wargod_speak_on(id)
                else Wargod_speak_off(id)

                if (gHasWargodPower[id])
                {   
                    gPlayerUltimateUsed[id] = false
                    laser_shots[id] = get_cvar_num("Wargod_laser_ammo")

                }
            }

        }
    }
}
//----------------------------------------------------------------------------------------------
public newSpawn(id)
{   
    if ( shModActive() && gHasWargodPower[id] && is_user_alive(id) )
    {   
        changeWeapon(id)
    }
}
//----------------------------------------------------------------------------------------------
public newRound(id)
{   
    laser_shots[id] = get_cvar_num("Wargod_laser_ammo")
    gPlayerUltimateUsed[id] = false

    remInvisibility(id)
    if ( gHasWargodPower[id] )
    {   
        gBullets[id] = get_cvar_num("Wargod_bullets")
        gLastWeapon[id] = -1
        set_task(0.1, "Wargod_deagle",id)

        gMoveTimer[id] = 0
        gPlayerUltimateUsed[id] = false

        if ( is_user_alive(id) )
        {   
            get_user_origin(id, gPlayerPosition[id])

            addAllMarks(id)

            if (gHasWargodPower[id]) Wargod_speak_on(id)

            if ( !hasRoundStarted() )
            {   
                gPlayerUltimateUsed[id] = false
            }
            else
            {   
                gPlayerUltimateUsed[id] = true //dead wargod's loose their zeus...
                
            }

        }
        return PLUGIN_HANDLED
    }
}
//----------------------------------------------------------------------------------------------
public setInvisibility(id, alpha)
{   

    if (alpha < 125)
    {   
        set_user_rendering(id,kRenderFxGlowShell,1,1,1,kRenderTransAlpha,alpha)
    }
    else
    {   
        set_user_rendering(id,kRenderFxNone,0,0,0,kRenderTransAlpha,alpha)
    }
}
//----------------------------------------------------------------------------------------------
public remInvisibility(id)
{   
    gStillTime[id] = -1

    if (gIsInvisible[id] > 0)
    {   
        shUnglow(id)
        client_print(id,print_center,"[SH]Wargod: You are no longer cloaked")
    }

    gIsInvisible[id] = 0
}
//----------------------------------------------------------------------------------------------
public checkButtons()
{   
    if ( !hasRoundStarted() || !shModActive()) return

    new bool:setVisible
    new butnprs

    for(new id = 1; id <= SH_MAXSLOTS; id++)
    {   
        if (!is_user_alive(id) || !gHasWargodPower[id]) continue

        setVisible = false
        butnprs = Entvars_Get_Int(id, EV_INT_button)

        //Always check these
        if (butnprs&IN_ATTACK || butnprs&IN_ATTACK2 || butnprs&IN_RELOAD || butnprs&IN_USE) setVisible = true

        //Only check these if Predalien_checkmove is off
        if ( get_cvar_num("Predalien_checkmove") )
        {   
            if (butnprs&IN_JUMP) setVisible = true
            if (butnprs&IN_FORWARD || butnprs&IN_BACK || butnprs&IN_LEFT || butnprs&IN_RIGHT) setVisible = true
            if (butnprs&IN_MOVELEFT || butnprs&IN_MOVERIGHT) setVisible = true
        }

        if (setVisible) remInvisibility(id)
        else
        {   
            new sysTime = get_systime()
            new delay = get_cvar_num("Wargod_delay")

            if ( gStillTime[id] < 0 )
            {   
                gStillTime[id] = sysTime
            }
            if ( sysTime - delay >= gStillTime[id] )
            {   
                if (gIsInvisible[id] != 100) client_print(id,print_center,"[SH]Wargod: 100%s cloaked", "%")
                gIsInvisible[id] = 100
                setInvisibility(id, get_cvar_num("Wargod_alpha"))
            }
            else if ( sysTime > gStillTime[id] )
            {   
                new alpha = get_cvar_num("Wargod_alpha")
                new Float:prcnt = float(sysTime - gStillTime[id]) / float(delay)
                new rPercent = floatround(prcnt * 100)
                alpha = floatround(255 - ((255 - alpha) * prcnt) )
                client_print(id,print_center,"[SH]Wargod: %d%s cloaked", rPercent, "%")
                gIsInvisible[id] = rPercent
                setInvisibility(id, alpha)
            }
        }
    }
}
//----------------------------------------------------------------------------------------------
public changeWeapon(id)
{   
    if ( !gHasWargodPower[id] || !shModActive() ) return

    new wpnid = read_data(2)
    new clip = read_data(3)

    // Never Run Out of Ammo!
    if ( wpnid == CSW_DEAGLE && clip == 0 )
    {   
        shReloadAmmo(id)
    }

    if ( wpnid == CSW_DEAGLE ) Wargod_mode(id)
    else
    {   
        if ( get_cvar_num("Wargod_deaglemode") == 1 )
        {   
            client_cmd(id, "weapon_deagle")
        }
        else Wargod_normal(id)
    }
}
//----------------------------------------------------------------------------------------------
public Wargod_damage(id)
{   

    new damage = read_data(2)
    new weapon, bodypart, attacker = get_user_attacker(id,weapon,bodypart)

    if ( attacker < 0 || attacker > SH_MAXSLOTS ) return PLUGIN_CONTINUE

    if ( gHasWargodPower[attacker] && weapon == CSW_DEAGLE && gBullets[attacker] >= 0 && is_user_alive(id) )
    {   
        new health = get_user_health(id)

        // damage is less than 10%
        if ( ( (1.0 * damage) / (1.0 * (health + damage) ) ) < 0.01 ) return PLUGIN_CONTINUE

        new origin[3]
        get_user_origin(id, origin)

        // player fades..
        set_user_rendering(id, kRenderFxFadeSlow, 255, 255, 255, kRenderTransColor, 4);

        // beeeg explody!
        message_begin(MSG_ALL, SVC_TEMPENTITY)
        write_byte(3)// TE_EXPLOSION
        write_coord(origin[0])
        write_coord(origin[1])
        write_coord(origin[2]-22)
        write_short(blast_shroom)// mushroom cloud
        write_byte(40)// scale in 0.1's
        write_byte(12)// frame rate
        write_byte(12)// TE_EXPLFLAG_NOPARTICLES & TE_EXPLFLAG_NOSOUND
        message_end()

        // do turn down that awful racket..to be replaced by a blood spurt!
        message_begin(MSG_ALL, SVC_TEMPENTITY)
        write_byte(10)// TE_LAVASPLASH
        write_coord(origin[0])
        write_coord(origin[1])
        write_coord(origin[2]-26)
        message_end()

        // kill victim
        user_kill(id, 1)

        message_begin( MSG_ALL, get_user_msgid("DeathMsg"),
                {   0,0,0},0 )
        write_byte(attacker)
        write_byte(id)
        write_byte(0)
        write_string("deagle")
        message_end()

        //Save Hummiliation
        new namea[24],namev[24],authida[20],authidv[20],teama[8],teamv[8]
        //Info On Attacker
        get_user_name(attacker,namea,23)
        get_user_team(attacker,teama,7)
        get_user_authid(attacker,authida,19)
        //Info On Victim
        get_user_name(id,namev,23)
        get_user_team(id,teamv,7)
        get_user_authid(id,authidv,19)
        //Log This Kill
        log_message("^"%s<%d><%s><%s>^" killed ^"%s<%d><%s><%s>^" with ^"Dark Deagle^"",
                namea,get_user_userid(attacker),authida,teama,namev,get_user_userid(id),authidv,teamv)

        // team check!
        new attacker_team[2], victim_team[2]
        get_user_team(attacker, attacker_team, 1)
        get_user_team(id, victim_team, 1)

        // for some reason this doesn't update in the hud until the next round.. whatever.
        if (!equali(attacker_team, victim_team))
        {   
            // diff. team;    $attacker gets credited for the kill and $250 and XP.
            //        $id gets their suicidal -1 frag back.
            set_user_frags(attacker, get_user_frags(attacker)+1)

#if defined AMXX_VERSION
            cs_set_user_money(attacker, cs_get_user_money(attacker)+150)
#else
            set_user_money(attacker, get_user_money(attacker)+150)
#endif
            
            shAddXP(attacker, id, 1)
        }
        else
        {   
            // same team;    $attacker loses a frag and $500 and XP.
            set_user_frags(attacker, get_user_frags(attacker)-1)

#if defined AMXX_VERSION
            cs_set_user_money(attacker, cs_get_user_money(attacker)-500, 0)
#else
            set_user_money(attacker, get_user_money(attacker)-500, 0)
#endif
            
            shAddXP(attacker, id, -1)

            if (!shModActive() || !gHasWargodPower[id] || gPlayerUltimateUsed[id] || !is_user_alive(id)) return

            new damage = read_data(2)
            new weapon, bodypart, attacker = get_user_attacker(id,weapon,bodypart)

            //Don't want to do anything with some weapons
            if (weapon == CSW_C4 || weapon == CSW_KNIFE || weapon == CSW_HEGRENADE || weapon == CSW_SMOKEGRENADE || weapon == CSW_FLASHBANG)
            {   
                return
            }

            if ( is_user_alive(id) && id != attacker )
            {   
                // Start Timer
                ultimateTimer(id, get_cvar_num("Wargod_cooldown") * 1.0)

                // Disarm enemy and get their gun!
                playSound(id)
                playSound(attacker)
                Wargod_disarm(id,attacker)

                //Screen Flash
                new alphanum = damage * 2
                if (alphanum > 200) alphanum = 200
                else if (alphanum < 40) alphanum = 40
                setScreenFlash(attacker, 100, 100, 100, 10, alphanum )
            }
        }
    }
}
//----------------------------------------------------------------------------------------------
public Wargod_fire(id)
{   

    if ( !gHasWargodPower[id] ) return PLUGIN_CONTINUE

    new weap = read_data(2) // id of the weapon
    new ammo = read_data(3)// ammo left in clip
    
    if ( weap == CSW_DEAGLE && is_user_alive(id) )
    {   
        if (gLastWeapon[id] == 0) gLastWeapon[id] = weap

        if ( gLastClipCount[id] > ammo && gLastWeapon[id] == weap && gBullets[id] > 0 )
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
            write_short(laser)// laserbeam sprite
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
            write_short(laser_impact)// blast sprite
            write_byte(10)// scale in 0.1u
            write_byte(30)// frame rate
            write_byte(8)// TE_EXPLFLAG_NOPARTICLES
            message_end()// ..unless i'm mistaken, noparticles helps avoid a crash
            
            gBullets[id]--

            new message[128]
            format(message, 127, "You Have %d bullet(s) left",gBullets[id])
            set_hudmessage(255,0,0,-1.0,0.3,0,0.25,1.0,0.0,0.0,4)
            show_hudmessage(id, message)

            if ( gBullets[id] == 0 ) gBullets[id] = -1
        }

        gLastClipCount[id] = ammo
        gLastWeapon[id] = weap
    }
    return PLUGIN_CONTINUE
}
//----------------------------------------------------------------------------------------------
public Wargod_deagle(id)
{   
    shGiveWeapon(id,"weapon_deagle")
}
//----------------------------------------------------------------------------------------------
public Wargod_esploop()
{   
    if (!shModActive()) return

    new players[SH_MAXSLOTS]
    new pnum, vec1[3]
    new idring, id

    gRadius = get_cvar_num("Wargod_radius")
    gBright = get_cvar_num("Wargod_bright")

    get_players(players,pnum,"a")

    for(new i = 0; i < pnum; i++)
    {   
        idring = players[i]
        if (!is_user_alive(idring)) continue
        if (!get_user_origin(idring,vec1,0)) continue
        for (new j = 0; j < pnum; j++)
        {   
            id = players[j]
            if (!gHasWargodPower[id]) continue
            if (!is_user_alive(id)) continue
            if (idring == id) continue
            message_begin(MSG_ONE,SVC_TEMPENTITY,vec1,id)
            write_byte( 21 )
            write_coord(vec1[0])
            write_coord(vec1[1])
            write_coord(vec1[2] + 16)
            write_coord(vec1[0])
            write_coord(vec1[1])
            write_coord(vec1[2] + gRadius )
            write_short( gSpriteWhite )
            write_byte( 0 ) // startframe
            write_byte( 1 )// framerate
            write_byte( 6 )// 3 life 2
            write_byte( 8 )// width 16
            write_byte( 1 )// noise
            write_byte( 0 )// r
            write_byte( 0 )// g
            write_byte( 0 )// b
            write_byte( gBright )//brightness
            write_byte( 0 )// speed
            message_end()
        }
    }
}
//----------------------------------------------------------------------------------------------
public Wargod_loop()
{   
    if (!shModActive()) return
    for ( new id = 1; id <= SH_MAXSLOTS; id++ )
    {   
        if ( gHasWargodPower[id] && is_user_alive(id) )
        {   
            // Let the server add the hps back since the # of max hps is controlled by it
            // I.E. Superman has more than 100 hps etc.
            shAddHPs(id, gHealPoints, gPlayerMaxHealth[id] )
            {   
                if ( !is_user_connected(id) )
                {   
                    remove_task(id)
                    return
                }

                if( gHasWargodPower[id] && is_user_alive(id) )
                {   
                    setScreenFlash(id, 0, 119, 0, 13, gTintView)
                    set_user_rendering(id, kRenderFxGlowShell, 0, 0, 0, kRenderTransAlpha, gAlphaInvis)
                    new players[32], count, id
                    get_players(players,count,"ac")

                    for ( new x = 0; x < count; x++ )
                    {   
                        id = players[x]
                        if ( gHasWargodPower[id] && is_user_alive(id) )
                        {   
                            new randNum = random_num(0, 100 )
                            new heroLevel = floatround(gPlayerLevels[id] * get_cvar_float("Wargod_pctperlev") * 100)
                            //server_print("setting god mode: heroLevel=%d, randNum=%d", heroLevel, randNum)
                            if ( heroLevel >= randNum && !get_user_godmode(id) )
                            {   
                                shSetGodMode(id,get_cvar_num("Wargod_godsecs"))
                                setScreenFlash(id, 0, 0, 255, 10, 50 ) //Quick Blue Screen Flash Letting You know about god mode
                            }
                        }
                    }
                }
            }
        }
    }
}
//----------------------------------------------------------------------------------------------
public Wargod_maxhealth()
{   
    new id[6]
    new health[9]

    read_argv(1,id,5)
    read_argv(2,health,8)

    gPlayerMaxHealth[str_to_num(id)] = str_to_num(health)
}
//----------------------------------------------------------------------------------------------
public Wargod_mode(id)
{   
    if ( gHasWargodPower[id] && is_user_alive(id) )
    {   

        gWargodModeOn[id] = true

        // Prevent cvar from being set too low
        new Zoom = get_cvar_num("Predalien_vision")
        if ( Zoom < 100 )
        {   
            debugMessage("(Wargod) Wargod Vision must be set higher than 100, defaulting to 100", 0, 0)
            Zoom = 100
            set_cvar_num("Wargod_vision", Zoom)
        }

        // Set Zoom
        message_begin(MSG_ONE, gmsgSetFOV,
                {   0,0,0}, id)
        write_byte(Zoom)
        message_end()

        gTintView = get_cvar_num("Wargod_tint")

        // Set once before loop task
        setScreenFlash(id, 0, 200, 0, 130, gTintView)
        set_user_rendering(id, kRenderFxGlowShell, 0, 0, 0, kRenderTransAlpha, gAlphaInvis)

        // Loop to make sure their screen stays green and they stay invisible
        set_task(1.0, "Wargod_loop", id, "", 0, "b")
    }
}
//----------------------------------------------------------------------------------------------
public Wargod_normal(id)
{   
    if ( !is_user_connected(id) || !gWargodModeOn[id] ) return

    // Quickly removes screenflash
    setScreenFlash(id, 0, 200, 0, 1, gTintView)

    remove_task(id)

    // Reset Zoom
    message_begin(MSG_ONE, gmsgSetFOV,
            {   0,0,0}, id)
    write_byte(90) //not Zooming
    message_end()

    set_user_rendering(id)

    // Make sure this is only called once, if alien mode was on
    gWargodModeOn[id] = false
}
//----------------------------------------------------------------------------------------------
public Wargod_death()
{   
    new id = read_data(2)

    if ( !gHasWargodPower[id] ) return

    Wargod_normal(id)

    new victim_id = read_data(2)
    removeAllMarks(victim_id)

    if ( id <= 0 || id > SH_MAXSLOTS ) return
    remove_task(id)

    if ( gBetweenRounds ) return
    if ( !is_user_connected(id) || is_user_alive(id) ) return

    // Look for alive players with unused Wargod Powers on the same team
    for ( new player = 1; player <= SH_MAXSLOTS; player++ )
    {   
        if ( player != id && is_user_alive(player) && gHasWargodPower[player] && !gPlayerUltimateUsed[player] && get_user_team(id) == get_user_team(player) )
        {   
            // We got a Wargod character willing to raise the dead!
            new parm[2]
            parm[0] = id
            parm[1] = player
            set_task(1.0,"Wargod_respawn", 0, parm, 2)
            break
        }
    }
}
//----------------------------------------------------------------------------------------------
public Wargod_levels()
{   
    new id[5]
    new lev[5]

    read_argv(1,id,4)
    read_argv(2,lev,4)

    gPlayerLevels[str_to_num(id)] = str_to_num(lev)
}
//----------------------------------------------------------------------------------------------
public Wargod_campcheck()
{   
    if ( !shModActive() || !hasRoundStarted() ) return

    // Check all players to see if they've moved...
    new origin[3]
    new dx,dy,dz

    for ( new i = 1; i <= SH_MAXSLOTS; i++ )
    {   
        if ( is_user_alive(i) )
        {   
            get_user_origin(i,origin)
            dx = gPlayerPosition[i][0] - origin[0]
            dy = gPlayerPosition[i][1] - origin[1]
            dz = gPlayerPosition[i][2] - origin[2]
            new d = sqrt( dx*dx + dy*dy + dz*dz )
            if ( d<=get_cvar_num("Predalien_movedist") )
            {   
                gMoveTimer[i]++
                if ( gMoveTimer[i]>get_cvar_num("Wargod_camptime") )
                {   
                    gMoveTimer[i]=0
                    Wargod_summon(i)
                }
            }
            else
            {   
                gMoveTimer[i] = 0
            }
            gPlayerPosition[i][0] = origin[0]
            gPlayerPosition[i][1] = origin[1]
            gPlayerPosition[i][2] = origin[2]
        }
    }
}
//----------------------------------------------------------------------------------------------
public Wargod_summon(id)
{   
    // Go through a list of skeletor looking for
    // 1) ultimate available
    // 2) opposite team than (id)
    // 3) skeletor powers...
    for ( new i = 1; i <= SH_MAXSLOTS; i++ )
    {   
        if ( is_user_alive(i) && gHasWargodPower[i] && get_user_team(i)!=get_user_team(id) && !gPlayerUltimateUsed[i] )
        {   
            // COOL WE HAVE A Wargod TO STICK SNARKS ON Player id!
            ultimateTimer(i, get_cvar_num("Wargod_cooldown") * 1.0)
            // SUMMON THE MONSTERS USING MONSTOR MOD
            new name[32]
            new enemyName[32]
            get_user_name(id,enemyName,31)
            get_user_name(i,name,31)
            client_print(0,3,"%s using Wargod Powers Against Camper %s", name, enemyName )
            emit_sound(id, CHAN_STATIC, "ambience/port_suckin1.wav", 1.0, ATTN_NORM, 0, PITCH_NORM)
            emit_sound(i, CHAN_STATIC, "ambience/port_suckin1.wav", 1.0, ATTN_NORM, 0, PITCH_NORM)

            // The Higher the Level - The more Snarks!
            //server_print("LEVEL OF %s=%d", name, gPlayerLevels[i] )
            for ( new m = 1; m <= gPlayerLevels[i] / 2 + 1; m++ )
            {   
                set_task(m * 0.2,"summon_monster", id)
            }
            break //ok no more poeple need to syc this guy
        }
    }
}
//----------------------------------------------------------------------------------------------
public summon_monster(id)
{   
    if (is_user_alive(id))
    {   
        server_cmd("monster snark #%i", id)
    }
}
//----------------------------------------------------------------------------------------------
public removeAllMarks(id)
{   
    new players[32], n

    if ( is_user_connected(id) && gHasWargodPower[id] )
    {   
        get_players(players, n, "a")
        for ( new p = 0; p < n; p++ )
        {   
            if ( players[p] == id ) continue
            removeMark(id,players[p])
        }
    }
}
//----------------------------------------------------------------------------------------------
public removeMark(id, pid)
{   
    if ( !is_user_connected(id) ) return
    message_begin(MSG_ONE, SVC_TEMPENTITY,
            {   0,0,0}, id)
    write_byte(99)
    write_short(pid)
    message_end()
}
//----------------------------------------------------------------------------------------------
public addAllMarks(id)
{   
    new players[32], n
    new bool:sameTeam
    new bool:showTeam
    new bool:showEnemy

    if ( is_user_alive(id) && gHasWargodPower[id] )
    {   

        showTeam = ( get_cvar_num("Wargod_showteam") != 0 )
        showEnemy =( get_cvar_num("Wargod_showenemy") != 0 )

        get_players(players, n, "a")
        for ( new p = 0; p < n; p++ )
        {   

            if ( players[p] == id ) continue
            sameTeam = ( get_user_team(id)==get_user_team(players[p]) )

            if ( (sameTeam && showTeam) || (!sameTeam && showEnemy) )
            addMark(id,players[p])
        }
    }
}
//----------------------------------------------------------------------------------------------
public addMark(id, pid)
{   
    if ( !is_user_alive(pid) ) return

    removeMark(id, pid)
    if ( get_user_team(pid) == 1 )
    {   
        make_trail(id, pid, 255, 0, 0, laser)
    }
    if ( get_user_team(pid) == 2 )
    {   
        make_trail(id, pid, 0, 0, 255, laser)
    }
}
//----------------------------------------------------------------------------------------------
public make_trail(id, markid, iRed, iGreen, iBlue, spr)
{   
    if ( id == markid ) return

    if ( !is_user_alive(id) ) return
    message_begin(MSG_ONE, SVC_TEMPENTITY,
            {   0,0,0}, id)
    write_byte(22)
    write_short(markid)
    write_short(spr)
    write_byte(get_cvar_num("Predalien_traillength") ) //length
    write_byte(8)//width
    write_byte(iRed)//red
    write_byte(iGreen)//green
    write_byte(iBlue)//blue
    write_byte(150)//bright
    message_end()
}
//----------------------------------------------------------------------------------------------
public trailMoveCheck(id)
{   
    addAllMarks(id) // Refresh the Marks...
}
//----------------------------------------------------------------------------------------------
public Wargod_disarm(id,victim)
{   
    new Float:velocity[3]

    Entvars_Get_Vector(victim, EV_VEC_velocity, velocity)
    velocity[2] = velocity[2] + get_cvar_num("Wargod_boost")

    // Give em an upwards Jolt
    Entvars_Set_Vector(victim, EV_VEC_velocity, velocity)

    new iweapons[32], inum, weapname[24]
    get_user_weapons(victim,iweapons,inum)

    for(new a = 0; a < inum; a++)
    {   
        //Don't want to do anything with some weapons
        if (iweapons[a] == CSW_C4 || iweapons[a] == CSW_KNIFE || iweapons[a] == CSW_HEGRENADE || iweapons[a] == CSW_SMOKEGRENADE || iweapons[a] == CSW_FLASHBANG)
        {   
            continue
        }

        get_weaponname(iweapons[a], weapname, 23)

        engclient_cmd(victim,"drop", weapname)
        shGiveWeapon(id, weapname)
    }

    new iCurrent = -1
    new Float:weapvel[3]

    while ( (iCurrent = FindEntity(iCurrent, "weaponbox")) > 0 )
    {   

        //Skip anything not owned by this client
        if ( Entvars_Get_Edict(iCurrent, EV_ENT_owner) != victim) continue

        Entvars_Get_Vector(iCurrent, EV_VEC_velocity, weapvel)

        //If Velocities are all Zero its on the ground already and should stay there
        if (weapvel[0] == 0.0 && weapvel[1] == 0.0 && weapvel[2] == 0.0) continue

        RemoveEntity(iCurrent)
    }

    if ( get_cvar_num("Wargod_giveglock") )
    {   
        shGiveWeapon(victim, "weapon_glock18", true)
    }
    else
    {   
        engclient_cmd(victim,"weapon_knife")
    }

    lightning_effect(id, victim, 10)

    client_print(victim,print_chat,"[SH] Wargod's power has removed your weapons")

}
//----------------------------------------------------------------------------------------------
public lightning_effect(id, targetid, linewidth)
{   
    message_begin( MSG_BROADCAST, SVC_TEMPENTITY )
    write_byte( 8 )
    write_short(id) // start entity
    write_short(targetid)// entity
    write_short(gSpriteLightning )// model
    write_byte( 0 )// starting frame
    write_byte( 15 )// frame rate
    write_byte( 10 )// life
    write_byte( linewidth )// line width
    write_byte( 10 )// noise amplitude
    write_byte( 255 )// r, g, b
    write_byte( 255 )// r, g, b
    write_byte( 255 )// r, g, b
    write_byte( 255 )// brightness
    write_byte( 0 )// scroll speed
    message_end()
}
//----------------------------------------------------------------------------------------------
public playSound(id)
{   
    new parm[1]
    parm[0] = id

    emit_sound(id, CHAN_AUTO, "ambience/deadsignal1.wav", 1.0, ATTN_NORM, 0, PITCH_HIGH)
    set_task(1.5,"stopSound", 0, parm, 1)
}
//----------------------------------------------------------------------------------------------
public stopSound(parm[])
{   
    new sndStop = (1<<5)
    emit_sound(parm[0], CHAN_AUTO, "ambience/deadsignal1.wav", 1.0, ATTN_NORM, sndStop, PITCH_NORM)
}
//----------------------------------------------------------------------------------------------
public handle_say(id)
{   

    if ( !get_cvar_num("Wargod_showchat") ) return PLUGIN_CONTINUE

    new command[10],players[SH_MAXSLOTS]
    new message[191],name[33], player_count
    new teamname[5], sMessage[191]
    read_argv(0, command, 16)
    read_argv(1, message, 190)

    if (equal(message,"") || equal(message,"[")) return PLUGIN_CONTINUE

    new is_alive = is_user_alive(id)
    new team = get_user_team(id)
    new isSayTeam = equal(command, "say_team")
    get_user_name(id, name, 32)

    if (team == 1) copy(teamname,4,"(T)")
    else if (team == 2) copy(teamname,4,"(CT)")

    format(sMessage,190, "%c[DN]%s%s%s :  %s^n", 2, isSayTeam ? teamname : "", is_alive ? "*ALIVE*" : "*DEAD*", name, message)
    get_players(players, player_count, "c")

    for (new i = 0; i < player_count; i++)
    {   
        if (gHasWargodPower[players[i]] && is_user_connected(players[i]))
        {   
            if (is_user_alive(players[i]) && !is_alive || isSayTeam && team != get_user_team(players[i]))
            {   
                message_begin(MSG_ONE,gmsgSayText,
                        {   0,0,0},players[i])
                write_byte(id)
                write_string(sMessage)
                message_end()
            }
        }
    }
    return PLUGIN_CONTINUE
}
//----------------------------------------------------------------------------------------------
public Wargod_speak_on(id)
{   
    if (gHasWargodPower[id] && is_user_connected(id))
    {   
        SetSpeak(id, SPEAK_LISTENALL)
    }
}
//----------------------------------------------------------------------------------------------
public Wargod_speak_off(id)
{   
    if (!gHasWargodPower[id] && is_user_connected(id))
    {   
        SetSpeak(id, SPEAK_NORMAL)
    }
}
//----------------------------------------------------------------------------------------------
public damage_msg(vIndex)
{   

    if (!is_user_connected(vIndex)) return PLUGIN_CONTINUE

    if ( get_cvar_num("Wargod_showdamage") )
    {   
        new aIndex = get_user_attacker(vIndex)
        if ( aIndex <= 0 || aIndex > SH_MAXSLOTS ||vIndex <= 0 || vIndex > SH_MAXSLOTS || vIndex == aIndex ) return PLUGIN_CONTINUE

        new damage = read_data(2)
        if ( is_user_alive(aIndex) && gHasWargodPower[aIndex])
        {   
            set_hudmessage(0, 100, 200, -1.0, 0.55, 2, 0.1, 2.0, 0.02, 0.02, 74)
            show_hudmessage(aIndex,"%i", damage)
        }

        if ( is_user_alive(vIndex) && gHasWargodPower[vIndex] )
        {   
            set_hudmessage(200, 0, 0, -1.0, 0.48, 2, 0.1, 2.0, 0.02, 0.02, 76)
            show_hudmessage(vIndex,"%i", damage)
        }
    }
}

//----------------------------------------------------------------------------------------------
// RESPOND TO KEYDOWN
public Wargod_kd()
{   
    if ( !hasRoundStarted() ) return PLUGIN_HANDLED

    // First Argument is an id with Wargod Powers!
    new temp[6]
    read_argv(1,temp,5)
    new id = str_to_num(temp)
    if ( !is_user_alive(id) ) return PLUGIN_HANDLED

    if ( laser_shots[id] <= 0 )
    {   
        client_print(id,print_center,"No Wargod Shots Left" )
        playSoundDenySelect(id)
        return PLUGIN_HANDLED
    }

    if ( gPlayerUltimateUsed[id] )
    {   
        playSoundDenySelect(id)
        return PLUGIN_HANDLED
    }

    // Remember this weapon...
    new clip,ammo,weaponID = get_user_weapon(id,clip,ammo)
    gLastWeapon[id] = weaponID

    // switch to knife
    engclient_cmd(id,"weapon_knife")

    fire_laser(id)// 1 immediate shot
    if (get_cvar_float("Wargod_mulishot") > 0.0)
    {   
        set_task( get_cvar_float("Wargod_mulishot"), "fire_laser", id, "", 0, "b") //delayed shots
    }

    return PLUGIN_HANDLED
}
//----------------------------------------------------------------------------------------------
public Wargod_ku()
{   
    // First Argument is an id with Wargod Powers!
    new temp[6]
    read_argv(1,temp,5)
    new id = str_to_num(temp)

    remove_task(id)

    if ( !hasRoundStarted() ) return

    // Use the ultimate
    ultimateTimer(id, get_cvar_float("Wargod_cooldown") )

    // Switch back to previous weapon...
    if ( gLastWeapon[id] != CSW_KNIFE ) shSwitchWeaponID( id, gLastWeapon[id] )
}
//----------------------------------------------------------------------------------------------
public laserEffects(id, aimvec[3] )
{   
    new origin[3]
    new decal_id = burn_decal[random_num(0,4)]
    emit_sound(id,CHAN_ITEM, "weapons/electro5.wav", 1.0, ATTN_NORM, 0, PITCH_NORM)
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
    write_byte( 40 )// width
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

    if(get_cvar_num("Wargod_laser_burndecals") == 1)
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
    new FFOn = get_cvar_num("mp_friendlyfire")

    if( !is_user_alive(id) ) return PLUGIN_HANDLED

    if ( laser_shots[id] <= 0 )
    {   
        client_print(id,print_center,"No Wargod Shots Left" )
        playSoundDenySelect(id)
        return PLUGIN_HANDLED
    }

    // Make sure still on knife
    new clip,ammo,weaponID = get_user_weapon(id,clip,ammo)
    if ( weaponID != CSW_KNIFE ) engclient_cmd(id,"weapon_knife")

    // Warn How many Blasts Left...
    laser_shots[id]--
    if(laser_shots[id] < 6) client_print(id,print_center,"Warning: %d Wargod Shots Left", laser_shots[id] )

    get_user_origin(id,aimvec,3)
    laserEffects(id, aimvec)

    get_user_aiming(id,tid,tbody)

    if( is_user_alive(tid) && ( FFOn || get_user_team(id) != get_user_team(tid) ) )
    {   
        emit_sound(tid,CHAN_BODY, "weapons/xbow_hitbod2.wav", 1.0, ATTN_NORM, 0, PITCH_NORM)

        // Determine the damage
        new damage
        switch(tbody)
        {   
            case 1: damage = h1_dam
            case 2: damage = h2_dam
            case 3: damage = h3_dam
            case 4: damage = h4_dam
            case 5: damage = h4_dam
            case 6: damage = h6_dam
            case 7: damage = h6_dam
        }

        // Deal the damage...
        shExtraDamage(tid, id, damage, "Wargod Laser")
    }
    return PLUGIN_CONTINUE
}
//----------------------------------------------------------------------------------------------
public Wargod_respawn(parm[])
{   
    new dead = parm[0]
    new Wargod = parm[1]

    if (gPlayerUltimateUsed[Wargod] || gBetweenRounds) return
    if ( !is_user_connected(dead) || !is_user_connected(Wargod)) return
    if ( !is_user_alive(Wargod) || is_user_alive(dead) ) return
    if ( get_user_team(dead) != get_user_team(Wargod) ) return

    ultimateTimer(Wargod, get_cvar_float("Wargod_cooldown"))
    emit_sound(Wargod, CHAN_STATIC, "ambience/port_suckin1.wav", 1.0, ATTN_NORM, 0, PITCH_NORM)
    new WargodName[32],deadName[32]
    get_user_name(Wargod,WargodName,31)
    get_user_name(dead,deadName,31)
    client_print(0,print_chat,"%s used Wargod Powers to Raise Dead Team Member %s!", WargodName, deadName )

    //Double spawn prevents the no HUD glitch (hopefully)
    user_spawn(dead)
    user_spawn(dead)
    emit_sound(dead, CHAN_STATIC, "ambience/port_suckin1.wav", 1.0, ATTN_NORM, 0, PITCH_NORM)
    shGlow(dead,255,255,0)
    set_task(3.0, "Wargod_unglow", dead)
    set_task(1.0, "Wargod_teamcheck", 0, parm, 2)
}
//----------------------------------------------------------------------------------------------
public Wargod_unglow(id)
{   
    shUnglow(id)
}
//----------------------------------------------------------------------------------------------
public Wargod_teamcheck(parm[])
{   
    new dead = parm[0]
    new Wargod = parm[1]

    if ( get_user_team(dead) != get_user_team(Wargod) )
    {   
        client_print(dead,print_chat,"You changed teams and got Wargod respawned, now you shall die")
        user_kill(dead,1)
        gPlayerUltimateUsed[Wargod] = false
    }
}
//----------------------------------------------------------------------------------------------
public round_start()
{   
    gBetweenRounds = false
}
//----------------------------------------------------------------------------------------------
public round_end()
{   
    gBetweenRounds = true
}
//----------------------------------------------------------------------------------------------
public client_disconnect(id)
{   
    remove_task(id)
    // Yeah don't want any left over residuals
    remove_task(id)
    gHasWargodPower[id] = false
}
//----------------------------------------------------------------------------------------------