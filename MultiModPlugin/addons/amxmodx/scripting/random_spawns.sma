#define    MAX_SPAWNS    61

#include <amxmodx>
#include <amxmisc>
#include <cstrike>
#include <fakemeta>
#include <hamsandwich>

new Float:g_SpawnVecs[MAX_SPAWNS][3];
new Float:g_SpawnAngles[MAX_SPAWNS][3];
new Float:g_SpawnVAngles[MAX_SPAWNS][3];
new g_TotalSpawns = 0;

new bool:gBotsRegistered;

public plugin_init()
{
    register_plugin("CSDM Spawns", "0.0.1", "CSDM Team / Exolent")
    
    readSpawns()
}

public client_authorized( id )
    if( !gBotsRegistered && is_user_bot( id ) )
{
    
    set_task( 0.1, "register_bots", id );
}

public register_bots( id )
{
    if( !gBotsRegistered && is_user_connected( id ) )
    {
        RegisterHamFromEntity( Ham_Spawn, id, "FwdPlayerSpawn", 1 );
        gBotsRegistered = true;
    }
}

readSpawns()
{
    new Map[32], config[32],  MapFile[64]
    
    get_mapname(Map, 31)
    get_configsdir(config, 31)
    format(MapFile, 63, "%s\csdm\%s.spawns.cfg", config, Map)
    g_TotalSpawns = 0;
    
    if (file_exists(MapFile)) 
    {
        new Data[124], len
        new line = 0
        new pos[12][8]
            
        while(g_TotalSpawns < MAX_SPAWNS && (line = read_file(MapFile , line , Data , 123 , len) ) != 0 ) 
        {
            if (strlen(Data)<2 || Data[0] == '[')
                continue;

            parse(Data, pos[1], 7, pos[2], 7, pos[3], 7, pos[4], 7, pos[5], 7, pos[6], 7, pos[7], 7, pos[8], 7, pos[9], 7, pos[10], 7);
            
            // Origin
            g_SpawnVecs[g_TotalSpawns][0] = str_to_float(pos[1])
            g_SpawnVecs[g_TotalSpawns][1] = str_to_float(pos[2])
            g_SpawnVecs[g_TotalSpawns][2] = str_to_float(pos[3])
            
            //Angles
            g_SpawnAngles[g_TotalSpawns][0] = str_to_float(pos[4])
            g_SpawnAngles[g_TotalSpawns][1] = str_to_float(pos[5])
            g_SpawnAngles[g_TotalSpawns][2] = str_to_float(pos[6])
            
            //v-Angles
            g_SpawnVAngles[g_TotalSpawns][0] = str_to_float(pos[8])
            g_SpawnVAngles[g_TotalSpawns][1] = str_to_float(pos[9])
            g_SpawnVAngles[g_TotalSpawns][2] = str_to_float(pos[10])
            
            //Team - ignore - 7
            
            g_TotalSpawns++;
        }
        
        log_amx("Loaded %d spawn points for map %s.", g_TotalSpawns, Map)
        
        if (g_TotalSpawns >= 2)
        {
            RegisterHam(Ham_Spawn, "player", "FwdPlayerSpawn", 1)
        }
    } else {
        log_amx("No spawn points file found (%s)", MapFile)
    }
    
    return 1;
}

public FwdPlayerSpawn(id)
{
    if (!is_user_alive(id))
        return
    
    new list[MAX_SPAWNS]
    new num = 0
    new final = -1
    new total=0
    new players[32], n, x = 0
    new Float:loc[32][3], locnum
    
    //cache locations
    get_players(players, num)
    for (new i=0; i<num; i++)
    {
        if (is_user_alive(players[i]) && players[i] != id)
        {
            pev(players[i], pev_origin, loc[locnum])
            locnum++
        }
    }
    
    num = 0
    while (num <= g_TotalSpawns)
    {
        //have we visited all the spawns yet?
        if (num == g_TotalSpawns)
            break;
        //get a random spawn
        n = random_num(0, g_TotalSpawns-1)
        //have we visited this spawn yet?
        if (!list[n])
        {
            //yes, set the flag to true, and inc the number of spawns we've visited
            list[n] = 1
            num++
        } 
        else 
        {
            //this was a useless loop, so add to the infinite loop prevention counter
            total++;
            if (total > 100) // don't search forever
                break;
            continue;   //don't check again
        }
        
        if (locnum < 1)
        {
            final = n
            break
        }
        
        final = n
        for (x = 0; x < locnum; x++)
        {
            new Float:distance = get_distance_f(g_SpawnVecs[n], loc[x]);
            if (distance < 250.0)
            {
                //invalidate
                final = -1
                break;
            }
        }
        
        if (final != -1)
            break
    }
    
    if (final != -1)
    {
        new Float:mins[3], Float:maxs[3]
        pev(id, pev_mins, mins)
        pev(id, pev_maxs, maxs)
        engfunc(EngFunc_SetSize, id, mins, maxs)
        engfunc(EngFunc_SetOrigin, id, g_SpawnVecs[final])
        set_pev(id, pev_fixangle, 1)
        set_pev(id, pev_angles, g_SpawnAngles[final])
        set_pev(id, pev_v_angle, g_SpawnVAngles[final])
        set_pev(id, pev_fixangle, 1)
    }
}