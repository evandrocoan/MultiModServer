#include <amxmodx>
#include <amxmisc>
#include <fakemeta>

// constats
new const PLUGIN_NAME[] = "Rain Events";
new const PLUGIN_VERSION[] = "0.1";
new const PLUGIN_AUTHOR[] = "SAMURAI";

new const sCommand[] = "cl_weather 0";

#define MAX_TIME 180

// pcvars;
new pcvar[3];
new gcount = 0;


// stocks
stock samurai_create_ent(const classname[])
{
    // return create a entity called "classname"
    return engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, classname));
}



stock set_keyvalue(ent, key[], value[]) 
{
    new classname[32];
    pev(ent, pev_classname, classname, 31);
    set_kvd(0, KV_ClassName, classname);
    set_kvd(0, KV_KeyName, key);
    set_kvd(0, KV_Value, value);
    set_kvd(0, KV_fHandled, 0);
    dllfunc(DLLFunc_KeyValue, ent, 0);
}




/************** Plugin Precache Forward *****************/
public plugin_precache()
{
    // register the plugin
    register_plugin(PLUGIN_NAME,PLUGIN_VERSION,PLUGIN_AUTHOR);
    
    // register cvars :
    pcvar[0] = register_cvar("enable_rain","1");
    pcvar[1] = register_cvar("enable_fog","1");

    
    if(get_pcvar_num(pcvar[0]) == 1) {
        // create a env_rain entity
        samurai_create_ent("env_rain");
    }
    
    static fog;
    // create a env_fog entity
    fog = samurai_create_ent("env_fog");
    
    switch(get_pcvar_num(pcvar[1])) {
        case 1:
        {
            // FOG OWNZ
            set_keyvalue(fog,"density","0.001");
            set_keyvalue(fog,"rendercolor","28 28 28");
        }
        
        case 2:
        {
            set_task(300.0,"task_fog",fog+1111,_,_,"a",8);
            set_task(1.0,"task_fog",0,"",0,"b");
        }
    }
            
    
}

/************** Client Connect Forward *******************/
public client_connect(id)
{
    client_cmd(id,"cl_weather 1");
}


/*************** Client Putinserver ***********************/
public client_putinserver(id)
{
    set_task(10.0,"task_display_msg",id);
    
    
}

public task_display_msg(id)
{
    if(is_user_connected(id) ) {
        client_print(id,print_chat,"If you want to stop the rain, write %s in console", sCommand);
    }
}


public task_fog(taskid)
{
    new ent = taskid - 1111;
    
    if(gcount < MAX_TIME)
    {
        // AGAIN FOG OWNZ
        set_keyvalue(ent,"density","0.001");
        set_keyvalue(ent,"rendercolor","28 28 28");
    }
    
    else if(gcount >= MAX_TIME)
    {
        // remove the fucking fog entity
        engfunc(EngFunc_RemoveEntity,ent);
        
        gcount = 0;
        
    
    }
        
    gcount += 1;
    
}