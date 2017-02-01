#include <amxmodx>

#define PLUGIN	"Hostage Down"
#define VERSION	"1.1"
#define AUTHOR	"v3x"

public plugin_init() 
{
	register_plugin(PLUGIN,VERSION,AUTHOR)
	register_event("TextMsg","HostageKilled","b","2&#Killed_Hostage") 
}

new g_szSoundFile[] = "radio/hosdown.wav"

public plugin_precache()
{
	precache_sound(g_szSoundFile)
}

public HostageKilled() 
{
	new aPlayers[32],iNum,i
	get_players(aPlayers,iNum,"ce","CT")

	for( i=0; i<=iNum; i++)
	{
		if(!is_user_connected(aPlayers[i])) continue
		client_cmd(aPlayers[i],"spk %s",g_szSoundFile)
		client_print(aPlayers[i],print_chat,"(RADIO): Hostage down!")
	}
	
	return PLUGIN_CONTINUE
}