#include <amxmodx>
 
#define	PLUGIN_NAME	"JailBreak Extreme Tanslations"
#define	PLUGIN_AUTHOR	"JoRoPiTo"
#define	PLUGIN_VERSION	"1.5"
#define	PLUGIN_CVAR	"jbe_es"

public plugin_init()
{
	register_plugin(PLUGIN_NAME, PLUGIN_VERSION, PLUGIN_AUTHOR)
	register_cvar(PLUGIN_CVAR, PLUGIN_VERSION, FCVAR_SERVER|FCVAR_SPONLY)
 
	register_clcmd("say /dia", "cmd_freeday")
	register_clcmd("say /duelo", "cmd_lastrequest")
	register_clcmd("say /voluntad", "cmd_lastrequest")
	register_clcmd("say /ayuda", "cmd_help")
}

public cmd_freeday(id)
{
	client_cmd(id, "say /fd")
	return PLUGIN_HANDLED
}

public cmd_lastrequest(id)
{
	client_cmd(id, "say /lr")
	return PLUGIN_HANDLED
}

public cmd_help(id)
{
	client_cmd(id, "say /help")
	return PLUGIN_HANDLED
}
