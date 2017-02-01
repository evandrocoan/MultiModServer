/* 
 Bomb Countdown HUD Timer v0.2 by SAMURAI

 * Plugin Details
 With this plugin enabled, you can see an colored Hud Message with the c4 time left, until explode
 Remeber : if until explode remains less than 8 seconds, hudmessage color will be red, if > 7 will be yellow and > 13 will be green.

 * Required Modules:
 - CSX
 
 * Credits:
 - Emp` for various indicates
 - Alka for full tests 

 * Changelog
 - Fixed Events problems
 - Pcvars
 - Fixed any bug on plugin

 */

#include <amxmodx>
#include <csx>

#define PLUGIN "Bomb Countdown HUD Timer"
#define VERSION "0.2"
#define AUTHOR "SAMURAI" 

new g_c4timer, pointnum;
new bool:b_planted = false;

new g_msgsync;

public plugin_init()
{   
    register_plugin(PLUGIN,VERSION,AUTHOR);

    pointnum = get_cvar_pointer("mp_c4timer");

    register_logevent("newRound", 2, "1=Round_Start");
    register_logevent("endRound", 2, "1=Round_End");
    register_logevent("endRound", 2, "1&Restart_Round_");

    g_msgsync = CreateHudSyncObj();
}

public newRound()
{   
    g_c4timer = -1;
    remove_task(652450);
    b_planted = false;
}

public endRound()
{   
    g_c4timer = -1;
    remove_task(652450);
}

public bomb_planted()
{   
    b_planted = true;
    g_c4timer = get_pcvar_num(pointnum);
    dispTime()
    set_task(1.0, "dispTime", 652450, "", 0, "b");

    client_cmd(0, "spk djeyl/c4powa.wav" )
}

public bomb_defused()
{   
    if(b_planted)
    {   
        remove_task(652450);
        b_planted = false;
    }

}

public bomb_explode()
{   
    if(b_planted)
    {   
        remove_task(652450);
        b_planted = false;
    }
}

public dispTime()
{   
    if(!b_planted)
    {   
        remove_task(652450);
        return;
    }
    /*if(g_c4timer >= 0)
     {   
     if(g_c4timer > 13)
     {   
     set_hudmessage(0, 150, 0, -1.0, 0.80, 0, 1.0, 1.0, 0.01, 0.01, -1);
     } else
     {   
     if(g_c4timer > 7)
     {   
     set_hudmessage(150, 150, 0, -1.0, 0.80, 0, 1.0, 1.0, 0.01, 0.01, -1);
     }
     else
     {   
     set_hudmessage(150, 0, 0, -1.0, 0.80, 0, 1.0, 1.0, 0.01, 0.01, -1);
     }
     }
     ShowSyncHudMsg(0, g_msgsync, "C4: %d", g_c4timer);

     --g_c4timer;
     }*/
    set_hudmessage(0, 150, 0, -1.0, 0.80, 0, 1.0, 1.0, 0.01, 0.01, -1);
    ShowSyncHudMsg(0, g_msgsync, "C4: %d", g_c4timer);
    --g_c4timer
}