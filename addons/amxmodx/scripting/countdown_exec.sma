/* AMX Mod script.
 *
 * Countdown Exec
 *  by SniperBeamer
 *
 *
 * Description: Countdown to execute commands
 * Usage: amx_countdown <seconds> <command>
 * Example: amx_countdown 5 amx_execall kill
 *
 */

#include <amxmodx>
#include <amxmisc>
#include <fun>

//----------------------------------------------------------------------------------------------
#define ACCESS_LEVEL ADMIN_LEVEL_A
//----------------------------------------------------------------------------------------------
#define ACCESS ADMIN_LEVEL_A

new bool:use = false
new counter
new targetid

public plugin_init ()
{   
    register_plugin ( "Countdown Exec", "1.3", "SniperBeamer" )
    register_concmd("amx_countdown","start_countdown",ACCESS_LEVEL,"- <seconds> <^"cmd^">")
    register_concmd("amx_kickdown","start_kickdown",ACCESS_LEVEL,"- <seconds> <authid, nick or #userid> <^"cmd^">")
    register_concmd("amx_stopdown","stop_countdown",ACCESS_LEVEL)

    return PLUGIN_CONTINUE
}

public start_countdown(id,level,cid)
{   
    if (!cmd_access(id,level,cid,3))
    return PLUGIN_HANDLED
    if (use)
    {   
        console_print(id,"[AMX] Already started a countdown")
        return PLUGIN_HANDLED
    }

    use = true
    new arg[8],scmd[32]
    read_argv(1,arg,7)
    read_argv(2,scmd,31)
    counter = str_to_num(arg)
    countdown(scmd)

    return PLUGIN_HANDLED
}
//----------------------------------------------------------------------------------------------

public countdown(scmd[])
{   
    set_hudmessage(255,200,0,-1.0,0.40,0,0.1,1.0,0.1,0.1,7)
    show_hudmessage(0,"[%d]^n%s",counter,scmd)
    if (counter<=10)
    {   
        new seconds[32]
        num_to_word(counter,seconds,31)
        client_cmd(0,"spk ^"fvox/%s^"",seconds)
    }

    if (counter==0)
    {   
        server_cmd("%s",scmd)
        use = false
        return PLUGIN_HANDLED
    }

    --counter
    if (use) set_task(1.0,"countdown",537,scmd,31)

    return PLUGIN_HANDLED
}
//----------------------------------------------------------------------------------------------
public start_kickdown(id,level,cid)
{   
    if (!cmd_access(id,level,cid,4))
    return PLUGIN_HANDLED
    if (use)
    {   
        console_print(id,"[AMX] Already started a countdown")
        return PLUGIN_HANDLED
    }

    new arg1[8],arg2[32],scmd[32],with[32]
    read_argv(1,arg1,7)
    read_argv(2,arg2,31)
    read_argv(3,scmd,31)
    counter = str_to_num(arg1)
    targetid = cmd_target(id,arg2,2)
    if (!targetid) return PLUGIN_HANDLED
    use = true
    format(with,31,"#%d",get_user_userid(targetid))
    replace(scmd,31,"!",with)
    kickdown(scmd)

    return PLUGIN_HANDLED
}
//----------------------------------------------------------------------------------------------
public kickdown(scmd[])
{   
    new tName[32]
    get_user_name(targetid,tName,31)
    set_hudmessage(255,200,0,-1.0,0.40,0,0.1,1.0,0.1,0.1,7)
    show_hudmessage(0,"Only [%d] sec left, %s!",counter,tName)
    if (counter<=10)
    {   
        new seconds[32]
        num_to_word(counter,seconds,31)
        client_cmd(0,"spk ^"fvox/%s^"",seconds)
    }

    if (counter==0)
    {   
        server_cmd("%s",scmd)
        use = false
        return PLUGIN_HANDLED
    }

    --counter
    if (use) set_task(1.0,"kickdown",537,scmd,31)

    return PLUGIN_HANDLED
}
//----------------------------------------------------------------------------------------------
public stop_countdown(id,level,cid)
{   
    if (!cmd_access(id,level,cid,1))
    return PLUGIN_HANDLED

    remove_task(537)
    use = false

    console_print(id,"[AMX] Stopped countdown")

    return PLUGIN_HANDLED
}
