/* 

- Spec Kick 1.0
by foo.bar (foo.bar@arrobaponto.com)

- Description:
Kicks all spectators, except players with the immunity tag, on round start.
This plugin is Steam Counter-strike 1.6 specific.

- Motivations:
I run a very popular CS server and folks that connect don't like to leave
the server whenever they go out for dinner, take a shower or go to sleep (yes, 
I've really had players going to bed when they went into spectator mode).
I whipped up this script to keep those asshats off the server.

- Usage:
1. If you want, edit the MIN_PLAYERS to set the minimum number of players on 
the server before it starts checking for spectators.
2. Compile.
3. Plug into the the plugin.ini file.
4. There is no step 4
5. Finnish!

- Possible future additions:
Interface with a database to keep track of repeat offenders
Ban repeat offeners for a few minutes to teach them a lesson
Code optimizations?

- Acknowledgments:
Freecode, thanks for the help with debugging the code

*/

#include <amxmodx>
#include <cstrike>

#define MIN_PLAYERS 9

public Round_Time()
{
        new Float:roundtime = get_cvar_float("mp_roundtime") * 60.0
        new rtime = read_data(1)

        if ( roundtime == rtime )   {
		new playerCount = get_playersnum()

		if (playerCount > MIN_PLAYERS) {
			new Players[32]
			get_players(Players, playerCount) 

			for (new i = 0; i < playerCount; i++) {
                               if (is_user_connected(Players[i])) {
                                       if (!(get_user_flags(Players[i]) & ADMIN_IMMUNITY)) {
						if ((cs_get_user_team(Players[i]) == 3)) {
							new name[32], authid[32]

							get_user_name(Players[i],name,31)
							get_user_authid(Players[i],authid,31)

							new userid = get_user_userid(Players[i])
	      						server_cmd("kick #%d ^"Quem fica de Spectator, nao e bem vindo neste servidor.^"",userid)

  							log_amx("Spec Kick: ^"%s<%d><%s>^" foi kickado por ficar de spectator)", name,userid,authid)
						}
					}
				}
			}
		}
        }
        return PLUGIN_CONTINUE
}

public plugin_init() {
        register_plugin("Spec Kick","1.0","foo.bar")
	register_event("RoundTime", "Round_Time", "bc")

        return PLUGIN_CONTINUE
}
