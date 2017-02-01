/* Ultimate KillStreak Advanced

 
 ! Available Sounds for enemy kills, headshot kills, knife kills , first blood kills , double kill , round counter.
 
 1) 10 sounds for enemy kills :
 - At 3 kills -> play TripleKill sound
 - 4 -> play MultiKill sound (it's not basically multikill sound)
 - 6 -> play UltraKill sound (it's not basically ultrakill sound)
 - 8  -> play KillingSpree sound (it's not basically killingspree sound)
 - 10 -> play MegaKill sound
 - 12 -> play Holy Shit sound
 - 14 -> play Ludicrouskill sound
 - 15 -> play rampage sound 
 - 16 -> play Unstoppable Sound (it's not basically unstoppable sound)
 - 18 -> play Monster Kill sound (it's not basically monster kill sound)


 2) 2 Sounds for Headshot (random play)
 3) 2 Sounds for Knife Kill (random play)
 4) 2 Sounds for First Blood (random play)
 5) 3 Sounds for Round Counter Events (random play)
 6) 1 Sound for Grenade Kill Events
 7) 4 Sounds for Suicide Events
 8) 2 Sounds for Double Kill Events



 * CVARs:

 - ut_killstreak_advanced (default 3) - enable/disable kill report, hudmessages
 1 = Only HudMessages
 2 = Only Sounds
 3 = Sounds and HudMessages
 Another number disable this event


 - ut_killstreak_hs (default 1) -> enable/disable headshot events
 Includes 2 sounds, hudmessages
 
 - ut_killstreak_knife (default 1) -> enable/disable knife kill events
 Includes 2 sounds, hudmessages
 
 - ut_firstblood (default 1) -> enable/disable first blood events
 Includes 2 sounds, hudmessages
 
 - ut_nade_events (default 1) -> enable/disable Grenade kill events
 Includes 1 sounds, hudmessages
 
 - ut_suicide_events (default 1) -> enable/disable Suicide Events
 Includes 4 sounds, hudmessages
 
 - ut_doublekill_events (default 1) -> enable/disable Double Kill Events
 Includes 2 sounds, hudmessage

 - ut_roundcout_sounds (default 1) -> enable/disable Round Counter Sounds 
 Includes 3 sounds, hudmessage
 

 * [UPDATE] 0.6 - > 0.7 (10/02/2007)
 - Changed the ul_killstreak_advanced cvar (read on head plugin at "CVARS"
 - Chaged the cord of hudmessages, to be to center
 - Now on killstreak announce, messages will be with random colors
 
 
 * [UPDATE] 0.5 -> 0.6
 - Fixed bugs
 - Added Round Counter Cvar:
 ut_roundcout_sounds



 * [UPDATE] 0.4 -> 0.5
 - Added Double Kill Events
 Cvar : ut_doublekill_events (default 1)
 Sounds : 2 sounds (random play)
 Messages : 1 Hud Message
 This is only if you kill 2 players with a bullet

 * [UPDATE] 0.3 -> 0.4
 - Added Grenade Kill Events -> 
 Cvar : ut_nade_events (default 1)
 Sounds : 1 sound
 Messages : 4 hud messages (random display)

 - Added Suicide Events 
 Cvar : ut_suicide_events (default 1)
 Sounds : 4 (random play)
 Messages : 2 hud messages (random display)


 * [UPDATE] 0.2 -> 0.3
 - Added First Blood Events:
 Cvar : ut_firstblood (default 1)
 Sounds : 2 sounds (random play)
 Messages : 3 hud messages (random display)

 - Added Round Counter Events:
 Sounds : 3 sounds (random play)
 Messages : 1 hud message



 * [UPDATE] 0.1 -> 0.2
 - Added new 4 headshot kill messages
 - Added new 3 knife kill messages
 This messages will displayed at random
 

 * Install:
 1) Enable Plugin
 2) Copy "ultimate_sounds" folder in to your "cstrike\sound" folder
 3) Restart server


 * Credits:
 - xxAvalancheXx for double kill codes
 - jim_yang for some sugestion and grenade events codes
 - bo0m! for help me with an register event function 
 - Duca for Streak Mode Example

 * Have a nice day now

 */

#include <amxmodx>
#include <amxmisc>

#define PLUGIN_NAME "Ultimate KillStreak Advanced"
#define PLUGIN_VERSION "0.7"
#define PLUGIN_AUTHOR "Ori, SAMURAI" 

new kills[33] =
{   0,...};
new deaths[33] =
{   0,...};
new firstblood
new kill[33][24];

#define LEVELS 10
#define hsounds 2
#define knsounds 2
#define fbsounds 2
#define prpsounds 3
#define suicidesounds 4
#define maxdbsounds 2
#define TASK_CLEAR_KILL    100

new hsenable
new knifeenable
new firstbloodenable
new nadecvar
new suicidecvar
new cvardouble
new rnstartcvar
new killstreaktype

new levels[10] =
{   3, 4, 6, 8, 10, 12,14,15,16,18};

new sounds[10][] =
{   
    "misc/triplekill_ut",
    "",
    "",
    "",
    "misc/megakill_ut",
    "misc/holyshit_ut",
    "misc/ludicrouskill_ut",
    "",
    "",
    "misc/dominating"
};

new messages[10][] =
{   
    "%s: Triple Kill !",
    "",
    "",
    "",
    "%s: Mega Kill !",
    "%s: Holy Shit !",
    "%s: Ludicrous Kill !",
    "",
    "",
    "%s: is Dominating !"
};

new hslist[hsounds][] =
{   
    "",
    ""
}

new fblist[fbsounds][]=
{   
    "",
    ""
}

new preplist[prpsounds][]=
{   
    "misc/prepare1_ut",
    "misc/prepare2_ut",
    "misc/prepare3_ut"
}

new fbmessages[3][]=
{   
    "",
    "",
    ""
}

new hsmessages[4][]=
{   
    "",
    "",
    "",
    ""
}

new knlist[knsounds][]=
{   
    "",
    ""
}

new knmessages[3][]=
{   
    "",
    "",
    ""
}

new nademessages[3][]=
{   
    "",
    "",
    ""
}

new suicidemess[2][]=
{   
    "%s Decidiu que se matar era mais facil que JOGAR!!!!!",
    "%s, Tem que matar INIMIGOS, nao a si Mesmo!!!!!!!!"
}

new suicidelist[suicidesounds][]=
{   
    "misc/suicide1_ut",
    "misc/suicide2_ut",
    "misc/suicide3_ut",
    "misc/suicide4_ut"
}

new doublelist[maxdbsounds][]=
{   
    "",
    ""
}

is_mode_set(bits)
{   
    new mode[9];
    get_cvar_string("ut_killstreak_advanced", mode, 8);
    return read_flags(mode) & bits;
}

public plugin_init()
{   
    register_plugin(PLUGIN_NAME, PLUGIN_VERSION, PLUGIN_AUTHOR);
    killstreaktype = register_cvar("ut_killstreak_advanced", "3");
    register_event("ResetHUD", "reset_hud", "b");
    register_event("HLTV","rnstart","a", "1=0", "2=0");
    register_event("DeathMsg", "event_death", "a");
    hsenable = register_cvar("ut_killstreak_hs","1");
    knifeenable = register_cvar("ut_killstreak_knife","1");
    firstbloodenable = register_cvar("ut_firstblood","1");
    nadecvar = register_cvar("ut_nade_events","1");
    suicidecvar = register_cvar("ut_suicide_events","1");
    cvardouble = register_cvar("ut_doublekill_events","1");
    rnstartcvar = register_cvar("ut_roundcout_sounds","1");

    return PLUGIN_CONTINUE;
}

public event_death(id)
{   
    new killer = read_data(1);
    new victim = read_data(2);
    new headshot = read_data(3);
    new weapon[24], vicname[32], killname[32]
    read_data(4,weapon,23)
    get_user_name(victim,vicname,31)
    get_user_name(killer,killname,31)

    if(headshot == 1 && get_pcvar_num(hsenable) ==1)
    {   
        set_hudmessage(0, 200, 20, -1.0, 0.30, 0, 6.0, 6.0)
        show_hudmessage(0, (hsmessages[random_num(0,3)]), killname, vicname)
        new i
        i = random_num(0,hsounds-1)
        client_cmd(0,"spk %s",hslist[i])
    }

    if(weapon[0] == 'k' && get_pcvar_num(knifeenable) ==1)
    {   
        set_hudmessage(255, 0, 255, -1.0, 0.30, 0, 6.0, 6.0)
        show_hudmessage(0, (knmessages[random_num(0,2)]), killname, vicname)
        new r
        r = random_num(0,knsounds-1)
        client_cmd(0,"spk %s",knlist[r])
    }

    if(firstblood && killer!=victim && killer>0 && get_pcvar_num(firstbloodenable) ==1)
    {   
        set_hudmessage(255, 220, 0, -1.0, 0.30, 0, 6.0, 6.0)
        show_hudmessage(0, (fbmessages[random_num(0,2)]), killname)
        new t
        t = random_num(0,fbsounds-1)
        client_cmd(0,"spk %s",fblist[t])
        firstblood = 0
    }

    if(weapon[1] == 'r' && get_pcvar_num(nadecvar) ==1)
    {   
        set_hudmessage(255, 0, 255, -1.0, 0.30, 0, 6.0, 6.0)
        show_hudmessage(0,(nademessages[random_num(0,2)]),killname,vicname)
        client_cmd(0,"spk misc/nade_ut")
    }

    if(killer == victim && get_pcvar_num(suicidecvar) ==1)
    {   
        set_hudmessage(255, 0, 255, -1.0, 0.30, 0, 6.0, 6.0)
        show_hudmessage(0,(suicidemess[random_num(0,1)]), vicname)
        new z
        z = random_num(0,suicidesounds-1)
        client_cmd(0,"spk %s",suicidelist[z])

    }

    if(kill[killer][0] && equal(kill[killer],weapon) && get_pcvar_num(cvardouble) == 1)
    {   
        set_hudmessage(255, 0, 255, -1.0, 0.30, 0, 6.0, 6.0)
        show_hudmessage(0,"", killname)
        kill[killer][0] = 0;
        new q
        q= random_num(0,maxdbsounds-1)
        client_cmd(0,"spk %s",doublelist[q])
    }

    else
    {   
        kill[killer] = weapon;
        set_task(0.1,"clear_kill",TASK_CLEAR_KILL+killer);
    }

    kills[killer] += 1;
    kills[victim] = 0;
    deaths[killer] = 0;
    deaths[victim] += 1;

    for (new i = 0; i < LEVELS; i++)
    {   
        if (kills[killer] == levels[i])
        {   
            announce(killer, i);
            return PLUGIN_CONTINUE;
        }
    }

    return PLUGIN_CONTINUE;
}

announce(killer, level)
{   

    new name[33]
    new r = random(256)
    new g = random(256)
    new b = random(256)

    get_user_name(killer, name, 32);
    set_hudmessage(r,g,b, 0.05, 0.65, 2, 0.02, 6.0, 0.01, 0.1, 2);

    if( (get_pcvar_num(killstreaktype) <= 0 ) || get_pcvar_num(killstreaktype) > 3)
    return PLUGIN_HANDLED;

    if(get_pcvar_num(killstreaktype) == 1)
    {   
        show_hudmessage(0, messages[level], name);
    }

    if(get_pcvar_num(killstreaktype) == 2)
    {   
        client_cmd(0, "spk %s", sounds[level]);
    }

    if(get_pcvar_num(killstreaktype) == 3)
    {   
        show_hudmessage(0, messages[level], name);
        client_cmd(0, "spk %s", sounds[level]);
    }

    return PLUGIN_CONTINUE;

}

public reset_hud(id)
{   
    firstblood = 1
    if (is_mode_set(16))
    {   
        if (kills[id] > levels[0])
        {   
            client_print(id, print_chat,
            "", kills[id]);
        } else if (deaths[id] > 1)
        {   
            client_print(id, print_chat,
            "", deaths[id]);

        }
    }
}

public rnstart(id)
{   
    if(get_pcvar_num(rnstartcvar) == 1)
    {   
        firstblood = 1
        set_hudmessage(255, 0, 255, -1.0, 0.30, 0, 6.0, 6.0)
        show_hudmessage(0, "")
        new q
        q = random_num(0,prpsounds-1)
        client_cmd(0,"spk %s",preplist[q])
    }
}

public client_connect(id)
{   
    kills[id] = 0;
    deaths[id] = 0;
}

public clear_kill(taskid)
{   
    new id = taskid-TASK_CLEAR_KILL;
    kill[id][0] = 0;
}

public plugin_precache()
{   
    precache_sound("misc/dominating.wav")
    precache_sound("misc/doublekill.wav")
    precache_sound("misc/firstblood.wav")
    precache_sound("misc/godlike.wav")
    precache_sound("misc/headshot.wav")
    precache_sound("misc/holyshit_ut.wav")
    precache_sound("misc/humiliation.wav")
    precache_sound("misc/killingspree.wav")
    precache_sound("misc/ludicrouskill_ut.wav")
    precache_sound("misc/maytheforce.wav")
    precache_sound("misc/megakill_ut.wav")
    precache_sound("misc/monsterkill.wav")
    precache_sound("misc/multikill.wav")
    precache_sound("misc/multikill2.wav")
    precache_sound("misc/nade_ut.wav")
    precache_sound("misc/never_die.wav")
    precache_sound("misc/olhafacaaa.wav")
    precache_sound("misc/oneandonly.wav")
    precache_sound("misc/onekill.wav")
    precache_sound("misc/perfect.wav")
    precache_sound("misc/prepare.wav")
    precache_sound("misc/prepare1_ut.wav")
    precache_sound("misc/prepare2_ut.wav")
    precache_sound("misc/prepare3_ut.wav")
    precache_sound("misc/rampage.wav")
    precache_sound("misc/suicide1_ut.wav")
    precache_sound("misc/suicide2_ut.wav")
    precache_sound("misc/suicide3_ut.wav")
    precache_sound("misc/suicide4_ut.wav")
    precache_sound("misc/tick_tock_1b.wav")
    precache_sound("misc/tick_tock_2b.wav")
    precache_sound("misc/tick_tock_3b.wav")
    precache_sound("misc/TomouHead.wav")
    precache_sound("misc/triplekill_ut.wav")
    precache_sound("misc/ultrakill.wav")
    precache_sound("misc/ultrakill2.wav")
    precache_sound("misc/unstoppable.wav")
    precache_sound("misc/statsme/connect.wav")
    precache_sound("misc/statsme/desc.wav")
    precache_sound("weapons/nuke_fly.wav")
}