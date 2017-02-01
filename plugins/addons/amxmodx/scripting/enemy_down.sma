// (c) 2005 v3x :D

#include <amxmodx>
#include <cstrike>

#define PLUGIN    "Enemy Down"
#define VERSION   "1.1"
#define AUTHOR    "v3x"

new g_iMsgSayText

public plugin_init()
{
    register_plugin(PLUGIN,VERSION,AUTHOR)
    register_event("DeathMsg","OnDeath","a","1>0")
    g_iMsgSayText = get_user_msgid("SayText")
}

new g_szSoundFile[] = "radio/enemydown.wav"

public plugin_precache()
{
    precache_sound(g_szSoundFile)
}

public plugin_modules()
{
    require_module("cstrike")
}

public OnDeath()
{
    new vID = read_data(2)
    new aID = read_data(1)
    new CsTeams:iTeam = cs_get_user_team(vID)
    new aPlayers[32],iNum,i
    new szUsernameV[33],szUsernameA[33]
    get_user_name(vID,szUsernameV,32)
    get_user_name(aID,szUsernameA,32)

    new szMessage[164]

    switch(iTeam)
    {
        case CS_TEAM_T:
        {
            get_players(aPlayers,iNum,"ce","CT")
            for(i=0; i<=iNum; i++)
            {
                if(!is_user_connected(aPlayers[i])) continue
                client_cmd(aPlayers[i],"spk %s",g_szSoundFile)
                format(szMessage,163,"^x01%s (RADIO):^x03 Enemy ^x04%s ^x03 down!",szUsernameA,szUsernameV)
                message_begin(MSG_ONE,g_iMsgSayText,{0,0,0},aPlayers[i])
                write_byte(aPlayers[i])
                write_string(szMessage)
                message_end()
            }
        }
        case CS_TEAM_CT:
        {
            get_players(aPlayers,iNum,"ce","TERRORIST")
            for(i=0; i<=iNum; i++)
            {
                if(!is_user_connected(aPlayers[i])) continue
                client_cmd(aPlayers[i],"spk %s",g_szSoundFile)
                format(szMessage,163,"^x01%s (RADIO):^x03 Enemy ^x04%s ^x03 down!",szUsernameA,szUsernameV)
                message_begin(MSG_ONE,g_iMsgSayText,{0,0,0},aPlayers[i])
                write_byte(aPlayers[i])
                write_string(szMessage)
                message_end()
            }
        }
    }
    
    return PLUGIN_CONTINUE
} 