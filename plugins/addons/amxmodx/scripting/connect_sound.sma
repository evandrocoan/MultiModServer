#include <amxmod>
#include <amxmisc>

public client_connect(id)
{
	new mp3var[] = "Half-Life10.mp3"
        if(!is_user_bot(id)) {
		client_cmd(id,"echo ^"Playing MP3.. Type mp3 stop to stop it.^";mp3 play ^"media/%s^"",mp3var)
	}
	return PLUGIN_CONTINUE
}

public plugin_init () {
	register_plugin("connect_sound", "0.1", "[FAW]Terran")
	return PLUGIN_CONTINUE;
}
