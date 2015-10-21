/*********************** Licensing *******************************************************
*  This program is free software; you can redistribute it and/or modify it
*  under the terms of the GNU General Public License as published by the
*  Free Software Foundation; either version 2 of the License, or (at
*  your option) any later version.
*
*  This program is distributed in the hope that it will be useful, but
*  WITHOUT ANY WARRANTY; without even the implied warranty of
*  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU 
*  General Public License for more details.
*  
*  You should have received a copy of the GNU General Public License
*  along with this program.  If not, see <http://www.gnu.org/licenses/>.
*
***************************************************************************************


[SIZE="6"][COLOR="Blue"][B]Multi-Mod Manager v1.0-release_candidate2.hotfix3[/B][/COLOR][/SIZE]
[B]Release: 10.10.2015 | Last Update: 19.10.2015[/B]

[SIZE="4"]Basic differences between the original [B]Joropito's MultiMod[/B] and [B]addons_zz's Multi-Mod Manager[/B][/SIZE]

[B]addons_zz's Multi-mod Manager can:[/B]
[LIST=1]
[*]display colored text messages. 
[*]easily implemented any new feature that you want, as it is a fully documented plugin. 
[*]improve its code as it is well [URL="http://www.d.umn.edu/~gshute/softeng/principles.html"]software engineered[/URL]. 
[*]easily manage extremely big mod plugins files and mods configurations files. 
[*]easily manage extremely big mods amount. 
[*]have a vote mod until 100 mods or more, despite it's not being too much comprehensive. 
[*]install the [COLOR="Red"]fully compatible[/COLOR] "[B]multimod_daily_changer[/B]" provided [goanchor=Downloads]here[/goanchor]. 
[*]install the [COLOR="Red"]fully compatible[/COLOR] and new "[B]galieo_reloaded.sma[/B]" provided [URL="https://forums.alliedmods.net/showthread.php?t=273019"]here[/URL]. 
[*]unload metamod csdm modules automatically after disable the csdm mod, or before enable any another mod, as long as you configure it. 
[*]restore server's cvars and server's commands automatically after disable any mod, or before enable another mod, as long as you configure it. 
[*]install/use every mod that exists and will exists in the universe, without any special plugin or any "Multi-Mod Manager" modification, 
            as long as this mod you wanna install runs at an AMXX very own default install. 
[*]if you want to, you can have any mod activated never ever at you server, even if there is more then 10 installed and fully working mods. 
[*]use the command "[B]amx_setmod help 1[/B]" display the acceptable inputs and loaded mods 
            from the file "[COLOR="Blue"]yourgamemod/addons/amxmodx/configs/multimod/[/COLOR][B]multimod.ini[/B]". 
[*]use the command '[COLOR="Blue"][B]amx_setmod modShortName <1 or 0>[/B][/COLOR]', to enable the mod "modShortName" as [COLOR="Blue"]csdm[/COLOR], 
            starting a vote map (1) or not (0), right after. This command can [B]only active mods loaded[/B] from 
            "[B]multimod.ini[/B]" file, and needs an admin level ADMIN_CFG. 
[*]use the command '[COLOR="Blue"][B]amx_setmods modShortName <1 or 0>[/B][/COLOR]', to enable the mod "modShortName" as [COLOR="Blue"]surf[/COLOR], 
            restarting (1) or not (0) the server immediately, [B]s[/B]ilently. This command can [B]active any mod installed at the server[/B] 
            despite it is or it is not at the "[B]multimod.ini[/B]" server configuration file. And most important, it needs an admin level ADMIN_IMMUNITY. 
[*]use the cvar [COLOR="Blue"]amx_multimod_endmapvote [B]<0 - 1>[/B][/COLOR] to enable ([B]1[/B]) or disable ([B]0[/B]) end map automatic [B]multi-mod[/B] voting.
[*]waits as long as you want to choose to activate one mod or not, by vote menu and by command line. 
[*]at voting [B]keep the current mod[/B], if less than 30% voted, or [B]keep it disabled[/B] if there is no mod enabled. 
[*]keep the server's current mod at voting as the [COLOR="Blue"]vote menu's[/COLOR] first option is always: "[B]1. Keep Current Mod[/B]". 
[*]disable the server's current mod at voting as the [COLOR="Blue"]vote menu's[/COLOR] second option is always: "[B]2. No mod - Disable Mod[/B]". 
[*]let the original AMXX very own "Map Chooser" enabled and its source code not replaced, despite it probably not be a useful plugin for voting map. 
[*]see that are any mod currently activated, when you type "say currentmod" and there is no mod active. 
[*]execute a special server's configuration file at the comment you active a server's mod. That is executed only and only at the 
            mod first activation time by the command "amx_setmod" (the silence one, "amx_setmods" has not this feature, because it is silent). 
[*]receive a clear and self-explanatory error message when you mis-configure anything, anywhere, anytime. 
[*]freeze the game and show the scoreboard when activating a mod silently, using the command "amx_setmods".
[*]see the voting results details at server's console. 
[/LIST]

[SIZE="4"]And even better, server's admins with right flag can change the server's current mod without needing direct access like ftp, to the server's files.[/SIZE]

[anchor]Top[/anchor][SIZE="5"][COLOR="blue"][B]Contents' Table[/B][/COLOR][/SIZE] 

[LIST]
[*][goanchor=Introduction]Introduction[/goanchor]
[*][goanchor=Requirements]Requirements and Commands[/goanchor]
[*][goanchor=MyMultiModServer]My Multi-Mod Server[/goanchor]
[*][goanchor=Installation]Installation[/goanchor]
[*][goanchor=Explanations]Explanations[/goanchor]
[*][goanchor=Configuration]Configuration[/goanchor]
[*][goanchor=Change]Change Log[/goanchor]
[*][goanchor=TODO]TODO[/goanchor]
[*][goanchor=Credits]Credits[/goanchor]
[*][goanchor=Sourcecode]Source Code and Support[/goanchor]
[*][goanchor=Downloads]Downloads[/goanchor]
[/LIST]
The original plugin "[URL="https://forums.alliedmods.net/showthread.php?t=95568"]multimod.sma[/URL]" is originally written by JoRoPiTo. This "[B]Multi-Mod Manager[/B]" works 
differently from the original "[COLOR="Blue"]MultiMod Manager[/COLOR]". See [goanchor=Credits]Credits[/goanchor] for information. 

This is a release candidate, which is a beta version with potential to be a final product, which is ready to be 
released unless [B]significant bugs[/B] emerge. In this stage of product stabilization, all product [B]features[/B] have been 
designed, coded and tested through one or more beta cycles with no known show stopper-class bug. 

This plugin [COLOR="Red"]is [B]not[/B] compatible[/COLOR] with the AMXX's very own [B]Map Chooser[/B] or "[B]Daily Maps[/B]", but yes with its 
modification "[B]multimod_mapchooser.sma[/B]" and "[B]multimod_daily_changer[/B]" provided [goanchor=Downloads]here[/goanchor]. The new 
[URL="https://forums.alliedmods.net/showthread.php?t=273019"]galieo_reloaded.sma[/URL] which is a different Galileo version, [COLOR="Red"]is ready[/COLOR] to be used with this [B]Multi-Mod Manager[/B]". 

The "[B]Multi-Mod Daily Maps[/B]" is a modified version of "[B]Daily Maps[/B]" to work with this "[B]Multi-Mod Manager[/B]". 
This plugin only works with "[B]Multi-Mod Manager[/B]", alone the "[B]Multi-Mod Daily Maps[/B]" does nothing. Its allows 
you to specify a different "[B]mapcycles[/B]" and "[B]server cfg[/B]" files rotation, for every day. These daily mapcycles are 
only active when you are not using any mod, or your current mod does not specifies a special mapcycle. The 
"[B]mapcycles[/B]" and "[B]server cfg[/B]" files respectively, are located at "[COLOR="Blue"]yourgamemod/mapcycles/[/COLOR][B]day[/B]" and 
"[COLOR="Blue"]yourgamemod/mapcycles/[/COLOR][B]day/cfg[/B]". 

As I am working at another plugins, I cannot provide immediately fixes and forum's answers here. But 
as soon as I can, I am going to release the final version. 
[URL="http://www.gametracker.com/search/?search_by=server_variable&search_by2=MultiModManager&query=&loc=_all&sort=&order="]
[SIZE=5][B][COLOR=DarkGreen]Click here to see all servers using this plugin.[/COLOR][/B][/SIZE][/URL] 

[anchor]Introduction[/anchor]
********************** [B][SIZE="5"][COLOR="blue"]Introduction[/COLOR][/SIZE][/B] [goanchor=Top]Go Top[/goanchor]  *******************************
This is a multi-mod server manager, that controls which mod is, or will be activated. 
A mod can be activated by vote ([B]say votemod[/B]), or by force ([B]amx_setmod[/B] or [B]amx_setmods[/B]).

There is a list of mods ([COLOR="Blue"][B]multimod.ini[/B][/COLOR]) that decides which mods will show up at a mod vote. 
The vote mod supports a multi-page menu, that display until 100 Mods loaded from “[B]multimod.ini[/B]” file. 
Beyond [B]100 mods[/B], the vote mod menu will not display then. To enable more than 100 mods, 
redefine the compiler constant "[COLOR="Blue"][B]#define MAXMODS 100[/B][/COLOR]" inside the plugin.

[IMG]http://addons.zz.mu/recursos/2015-08-16_14-08_Counter-Strike.jpg[/IMG]

The "[B]multimod_manager.sma[/B]" waits the user choose to activate one mod, by vote menu, 
or by command line. It [B]saves[/B] the current active mod and [COLOR="Blue"][B]keep it active[/B][/COLOR] forever or until some 
other mod is [COLOR="Blue"][B]activated[/B][/COLOR] or your disable the active mod by the "[B]amx_setmod disable 1[/B]" command. 

[COLOR="Blue"][B]Features' list:[/B][/COLOR] 
[QUOTE]
 * Changes the [B]default mapcycle[/B], if and only if a custom mod mapcycle was created.

 * The [COLOR="Blue"]vote menu's[/COLOR] first to options always are: "[B]1. Keep Current Mod[/B]" and "[B]2. No mod - Disable Mod[/B]". 

 * The vote mod [B]keep the current mod[/B], when less than 30% of players voted. 

 * When the min vote mod time is not [B]reached/disabled[/B], display a message informing it. 

 * Command '[COLOR="Blue"][B]amx_votemod[/B][/COLOR]', to start force start a vote mod, even if it is disabled. This command can 
       [B]only active mods loaded[/B] from "[B]multimod.ini[/B]" file, and needs an admin level ADMIN_MAP. 

 * Command '[COLOR="Blue"][B]amx_setmod modShortName <1 or 0>[/B][/COLOR]', to enable the mod "modShortName" as [COLOR="Blue"]csdm[/COLOR], 
      starting a vote map (1) or not (0), right after. This command can [B]only active mods loaded[/B] from 
      "[B]multimod.ini[/B]" file, and needs an admin level ADMIN_CFG. 

 * Command '[COLOR="Blue"][B]amx_setmods modShortName <1 or 0>[/B][/COLOR]', to enable the mod "modShortName" as [COLOR="Blue"]surf[/COLOR], 
      restarting (1) or not (0) the server immediately, [B]s[/B]ilently. This command can [B]active any mod installed 
      at the server[/B] despite it is or not at the "[B]multimod.ini[/B]" server's configuration file. And most important, 
      it needs an admin level ADMIN_IMMUNITY. 

OBS: A mod can [B]only[/B] to be/get activated after a restart. 
[/QUOTE]

The command "[B]amx_setmod help 1[/B]" display the acceptable inputs and loaded mods 
from the file "[COLOR="Blue"]yourgamemod/addons/amxmodx/configs/multimod/[/COLOR][B]multimod.ini[/B]". There is 
2 built-in operations beyond mods activation: "[COLOR="Blue"][B]amx_setmod help 1[/B][/COLOR]" and "[COLOR="Blue"][B]amx_setmod disable 1[/B][/COLOR]",
respectively to shows [B]help[/B] and [B]disable[/B] any active mod.

[IMG]http://addons.zz.mu/recursos/2015-08-16_14-08_Counter-Strike(2).jpg[/IMG]

If enabled ([B]default disabled[/B]), when remaining [COLOR="Blue"][B]5 minutes to end[/B][/COLOR] current map, this plugins launches a vote to 
choose which mod will be played at the [B]next map[/B]. If less than 30% voted, the game [B]keep the current mod[/B] 
or [B]keep it disabled[/B] if there is no mod enabled. 

********************** [anchor]Requirements[/anchor][SIZE="5"][COLOR="Blue"][B]Requirements and Commands[/B][/COLOR][/SIZE] [goanchor=Top]Go Top[/goanchor]  ******
[B]Amx Mod X 1.8.2[/B] 
Tested under [B]Counter-Strike[/B] and Counter-Strike: [B]Condition Zero[/B] 

[B]Cvars:[/B]
[QUOTE]
// Minimum [B]time[/B] to play before players can make [B]MOD voting[/B]. 
[COLOR="Blue"]amx_mintime [B]10 [/B][/COLOR]

// enable ([B]1[/B]) or disable ([B]0[/B]) end map automatic [B]multi-mod[/B] voting.
[COLOR="Blue"]amx_multimod_endmapvote [B]0 [/B][/COLOR]

// enable ([B]1[/B]) or disable ([B]0[/B]) multi-mod voting ([B]say votemod[/B]).
[COLOR="Blue"]amx_multimod_voteallowed [B]1 [/B][/COLOR]
[/QUOTE]

[B]Commands:[/B]
[QUOTE]
//Command line control of [B]multimod system[/B]
[COLOR="Blue"]amx_setmod[/COLOR] 
[COLOR="Blue"]amx_setmods[/COLOR] 

//[B]Admin only[/B] command to launch MOD voting
[COLOR="Blue"]amx_votemod[/COLOR] 

//Check which MOD [B]will be running[/B] in next map
[COLOR="Blue"]say nextmod[/COLOR]	
[COLOR="Blue"]say_team nextmod[/COLOR] 

//Check which [B]MOD[/B] is running in the [B]current map[/B]
[COLOR="Blue"]say currentmod[/COLOR] 
[COLOR="Blue"]say_team currentmod[/COLOR] 

//Player command [B]to launch[/B] MOD voting
[COLOR="Blue"]say votemod[/COLOR] 
[COLOR="Blue"]say_team votemod[/COLOR] 
[/QUOTE]

[anchor]MyMultiModServer[/anchor][SIZE="4"][B]My Multi-Mod Server with:[/B][/SIZE] 
[LIST]
[*]CS-DM (DeathMatch)
[*]Catch Mod
[*]Dragon Ball Mod
[*]Gun Game Mod
[*]Hide N Seek Mod
[*]Just Capture The Flag
[*]Knife Arena Mod
[*]Predator Mod_b2
[*]Super Heros
[*]Surf Mod
[*]Warcraft Ultimate Mod 3
[*]Zombie Money Mod
[*]Zombie Pack Ammo Mod
[/LIST]
[SIZE="4"][URL="https://forums.alliedmods.net/showthread.php?t=273018"]Is available here[/URL][/SIZE]. 

******************************** [anchor]Installation[/anchor][B][SIZE="5"][COLOR="Blue"]Installation[/COLOR][/SIZE][/B] [goanchor=Top]Go Top[/goanchor]  **********************
[B]1.[/B] Download the files "[B]multimod_manager.sma[/B]", "[B][COLOR="Red"]configuration_files.zip[/COLOR][/B]",  
"[B]multimod_mapchooser.sma[/B]" or "[B]galieo_reloaded.sma[/B]" and "[B]multimod_daily_changer.sma[/B]"(this is optional), 
at [goanchor=Downloads]Downloads[/goanchor] section. 

[B]2.[/B] Then take the contents of "[B]yourgamemod[/B]" from "[B]configuration_files.zip[/B]", to your gamemod folder. 

[B]3.[/B] [B]Compile[/B] the files and put the [B]compiled[/B] files to your plugins folder at 
"[COLOR="Blue"]yourgamemod/addons/amxmodx/[/COLOR][B]plugins[/B]" folder. 

[B]4.[/B] Put the next lines to your "[B]plugins.ini[/B]" file at "[COLOR="Blue"]yourgamemod/addons/amxmodx/[/COLOR][B]configs[/B]" and
disable the original "[B]mapchooser.amxx[/B]": 
[QUOTE]
multimod_manager.amxx
multimod_daily_changer.amxx
; Choose
multimod_mapchooser.amxx
;or
galieo_reloaded.amxx
[/QUOTE]

[B]5.[/B] Put the next line to your "[B]amxx.cfg[/B]" file at "[COLOR="Blue"]yourgamemod/addons/amxmodx/[/COLOR][B]configs[/B]":
[QUOTE]
exec addons/amxmodx/configs/multimod/multimod.cfg
[/QUOTE]

[anchor]Configuration[/anchor][B]6. [SIZE="5"][COLOR="red"]Configure[/COLOR][/SIZE][/B] your own mods at "[COLOR="Blue"]yourgamemod/addons/amxmodx/configs/multimod/[/COLOR][B]multimod.ini[/B]" 
file as follow (the short mod name cannot be longer than 15 characters neither have spaces):

--- [B]Example of:[/B] [COLOR="Blue"]yourgamemod/addons/amxmodx/configs/multimod/[/COLOR][B]multimod.ini[/B] ------
[QUOTE]
[Gun Game]:[gungame]:

;[mode name]:[shortModName]:
[/QUOTE]

-------------- And you have [B]to create[/B] the files:----------------------------
[QUOTE][COLOR="Blue"]yourgamemod/addons/amxmodx/configs/multimod/[/COLOR][B]plugins/gungame.txt[/B]

[B](Optinal files)[/B]
[COLOR="Blue"]yourgamemod/addons/amxmodx/configs/multimod/[/COLOR][B]cfg/gungame.cfg[/B]
[COLOR="Blue"]yourgamemod/addons/amxmodx/configs/multimod/[/COLOR][B]latecfg/gungame.cfg[/B]
[COLOR="Blue"]yourgamemod/addons/amxmodx/configs/multimod/[/COLOR][B]msg/gungame.cfg[/B]
[COLOR="Blue"]yourgamemod/mapcycles/[/COLOR][B]gungame.txt[/B]
[/QUOTE]

-------------- [anchor]Explanations[/anchor][B][SIZE="5"][COLOR="blue"]Explanations[/COLOR][/SIZE][/B] [goanchor=Top]Go Top[/goanchor] -------------------------

[B]1.[/B] The file "[COLOR="Blue"]yourgamemod/addons/amxmodx/configs/multimod/[/COLOR][B]plugins/gungame.txt[/B]", 
contains the plugins that compose the Mod like:
[QUOTE]
gungame.amxx
[/QUOTE]

[B]2.[/B] The file ([B]opcional[/B]) "[COLOR="Blue"]yourgamemod/addons/amxmodx/configs/multimod/[/COLOR][B]cfg/gungame.cfg[/B]", 
[COLOR="Blue"]contains[/COLOR] yours special configuration used at the mod activation, like:
[QUOTE]
amxx pause amx_adminmodel
sv_gravity 600 
[/QUOTE]

[B]3.[/B] The file ([B]opcional[/B]) "[COLOR="Blue"]yourgamemod/addons/amxmodx/configs/multimod/[/COLOR][B]cfg/gungame.cfg[/B]", 
contains [COLOR="Blue"]yours[/COLOR] special configuration used after the mod deactivation, like:
[QUOTE]
amxx unpause amx_adminmodel
sv_gravity 800 
[/QUOTE]

[B]4.[/B] The file ([B]opcional[/B]) "[COLOR="Blue"]yourgamemod/addons/amxmodx/configs/multimod/[/COLOR][B]msg/gungame.cfg[/B]" contains 
commands that are executed when a mod is activated by the command line "[B]amx_setmod[/B]". 
Usually it contains a command [B][COLOR="Blue"]to restart[/COLOR][/B] the server. 
[B]Example[/B] of "[COLOR="Blue"]yourgamemod/addons/amxmodx/configs/multimod/msg/[/COLOR][B]gungame.cfg[/B]":
[QUOTE]
amx_execall speak ambience/ratchant
amx_tsay ocean GUN-GAME will be activated at next server restart!!!!
amx_tsay blue GUN-GAME will be activated at next server restart!!!!
amx_tsay cyan GUN-GAME will be activated at next server restart!!!!
amx_tsay ocean GUN-GAME will be activated at next server restart!!!!

//amx_countdown 5 restart
exec addons/amxmodx/configs/multimod/votefinished.cfg
[/QUOTE]

[B]5.[/B] The file ([B]opcional[/B]) "[COLOR="Blue"]yourgamemod/mapcycles/[/COLOR][B]gungame.txt[/B]" contains the mapcycle used when 
[COLOR="Blue"]gungame mod[/COLOR]  is active.

******************************** [anchor]Change[/anchor][B][SIZE="5"][COLOR="blue"]Change Log[/COLOR][/SIZE][/B] [goanchor=Top]Go Top[/goanchor] ***********************
[QUOTE]
2015-10-10 | v1.0-release_candidate1
 * Initial release candidate. 

2015-10-10 | v1.0-release_candidate1.hotfix1
 * Add exception handle when the currentmod.ini or currentmodsilent.ini is not found. 

2015-10-12 | v1.0-release_candidate2
 * Removed unused function get_firstmap() and variable g_nextmap. 
 * Replaced unnecessary functions configMapManager and configDailyMaps. 
 * Removed unnecessary MULTIMOD_MAPCHOOSER compiler constant. 
 * Added to multimod_daily_changer.sma compatibility with galileo_reloaded.sma 

2015-10-13 | v1.0-release_candidate2.hotfix1
 * Added missing format parameter at msgModActivated function.

2015-10-13 | v1.0-release_candidate2.hotfix2
 * Added missing MM_CHOOSE line at multilingual file.

2015-10-19 | v1.0-release_candidate2.hotfix3
 * Translated to english lost code variables. 
 * Replaced a implemented switch by a native switch. 
 * Replaced another implemented switch by a native switch. 
 * Improved variables names meaningful. 
[/QUOTE]

******************************** [anchor]TODO[/anchor][B][SIZE="5"][COLOR="blue"]TODO[/COLOR][/SIZE][/B] [goanchor=Top]Go Top[/goanchor] *********************************
[QUOTE]
 * Removed unnecessary variables like g_messageFileNames, g_pluginsFileNames, g_mapcycleFileNames and g_configsFileNames.

[QUOTE=fysiks;2353142]
You should never return a string from a function. Strings should always be passed by-ref with the max characters 
passed as another parameter.  Then, in the function, you would either format directly into that string using the size 
provided or use copy().
[/QUOTE]
Coming soon: mapCyclePathCoder( stringToCode, sizeof( stringToCode ) - 1, stringCoded )

[QUOTE=fysiks;2353142]
Don't pass an integer value to a function by putting it in a string. Just pass the integer.  E.g. msgResourceActivated().  
If the original source of the value is from a string like read_argv() then you should convert it to an integer before 
passing it to a function like primitiveFunctions().
[/QUOTE]
Yea, I should convert it to integer. 

[QUOTE=fysiks;2353142]
If you are going to use the multilingual system to print to the server console, you should not use 
LANG_PLAYER; that just doesn't make sense.  You should use LANG_SERVER.
[*]This will only work with Counter-Strike (because of color chat) and thus your submission 
should not be labeled as "Modification:   ALL".
[/QUOTE]
I posted wrong, and I was misleading the LANG_PLAYER and LANG_SERVER's use. 
It will be fixed. And I forgot, this will be modification ALL, but it is not currently modification ALL. 
It will be correct at threads page until it is definitely modification all. 

[QUOTE=fysiks;2353142]
IIRC, printing info to the client in a for loop can cause an overflow.  Simply build the whole text into 
a single string and then send that only once.  You can create multiple lines by using "^n".
[/QUOTE]
It is the same problem as the AMXX very own "adminhelp.sma". I cannot build I a big string as pawn is limited. 
I must limit the output number as "adminhelp.sma", receiving a page list number to show and limit 
each page to show only a big string supported. 

[QUOTE=fysiks;2353142]
The use of server_print() should be rare and mostly for debugging.  For registered commands, 
it should only be used with register_srvcmd() (unless it's for debugging of course).
[/QUOTE]
I did not know this register_srvcmd(). Then now I can register a register_srvcmd to server_print, and another register_clcmd to client_print.

[QUOTE=fysiks;2353142]
I'm sure there is more but I am done for now. 
[/QUOTE]
Of course, there is more clever programing techniques to learn: 
[LIST=1]
[*]use tries instead of g_modShortNames.  
[*]count better current playing player at playersPlaying. 
[*]copy more efficiently a files at copyFiles and copyFiles2. 
[*]print colored text more efficiently than at print_color. 
[*]receive commands more efficiently than "command arg1 arg2" even a for 1 argument command. 
[/LIST]

[/QUOTE]
  
******************************** [anchor]Credits[/anchor][B][SIZE="5"][COLOR="blue"]Credits[/COLOR][/SIZE][/B] [goanchor=Top]Go Top[/goanchor] *******************************
[B]fysiks[/B]: The first to realize the idea of "multimod.sma" and some code improvements. 
[B]joropito[/B]: The idea/program developer of "[URL="https://forums.alliedmods.net/showthread.php?t=95568"]multimod.sma[/URL]". 
[B]crazyeffect[/B]: Colaborate with multilangual support of "multimod.sma". 
[B]dark vador 008[/B]: Time and server for testing under czero "multimod.sma". 
[B]Brad[/B]: The original [URL="https://forums.alliedmods.net/showthread.php?t=77391"]galileo.sma[/URL] developer. 
[B]Th3822[/B]: For find a error from map_nominate. 
[B]Addons zz[/B]: This plugin developer. 
[B]DeRoiD's[/B]: For print_color function. 
[B]JustinHoMi & JGHG[/B]: For the "[URL="https://forums.alliedmods.net/showthread.php?t=3886"]Daily Maps[/URL]" plugin. 
[B]AMXX Dev Team[/B]: For the "Map Chooser" plugin. 

******************************** [anchor]Sourcecode[/anchor][SIZE="5"][COLOR="blue"][B]Source Code and Support[/B][/COLOR][/SIZE] [goanchor=Top]Go Top[/goanchor] ***
For any problems with this plugin visit this own page for support:
[url]https://forums.alliedmods.net/showthread.php?t=273020[/url]

If you are [B]posting[/B] because the plugin or a [B]feature[/B] of the plugin isn't working for you, [B]please[/B] do 
all of the following, so we can [COLOR="Blue"]more efficiently[/COLOR] figure out what's going on:
[QUOTE]
If you have access to your game server's console, type the [COLOR="Blue"][B]following[/B][/COLOR] in the server console:
[LIST]
[*]status
[*]meta list
[*]amxx plugins
[*]amxx cvars
[/LIST]
If you don't have access the your [COLOR="Blue"][B]game server's console[/B][/COLOR], join your server and type the 
following in your game console:

[LIST]
[*]status
[*]rcon_password your_rcon_password
[*]rcon meta list
[*]rcon amxx plugins
[*]rcon amxx cvars
[/LIST]
[LIST=1]
[*]Paste here everything from the [B]status[/B] command [COLOR="Red"][B]*except*[/B][/COLOR] the player list.
[*]Paste here the entire result from the [B]meta list[/B] and [B]amxx plugins[/B] commands. 
[*]Paste here [COLOR="red"][B]*only*[/B][/COLOR] the CVARs that contain "[COLOR="SeaGreen"][B]multimod_manager.amxx[/B][/COLOR]" in the last column 
from the [B]amxx cvars[/B] command. They will be grouped together.
[/LIST]
[/QUOTE]

***************************************************************************************	
[SIZE="6"]BRAZIL (South America) Testing Server[/SIZE]
[URL="http://www.gametracker.com/server_info/jacks.noip.me:27015/"][IMG]http://www.gametracker.com/server_info/jacks.noip.me:27015/b_560_95_1.png[/IMG][/URL]

[SIZE="6"]GERMANY (Europe) Testing Server[/SIZE]
[URL="http://www.gametracker.com/server_info/vipersnake.net:27030/"][IMG]http://www.gametracker.com/server_info/vipersnake.net:27030/b_560_95_1.png[/IMG][/URL]

******************************** [anchor]Downloads[/anchor][SIZE="6"][COLOR="Blue"][B]Downloads[/B][/COLOR][/SIZE] [goanchor=Top]Go Top[/goanchor] ********************
[LIST]
[*][URL="https://forums.alliedmods.net/showthread.php?t=273019"]galieo_reloaded.sma[/URL]
[/LIST]


*/

#include <amxmodx>
#include <amxmisc>

#define PLUGIN "Multi-Mod Manager"
#define VERSION "v1.0-rc2.3"
#define AUTHOR "Addons zz"

#define TASK_VOTEMOD 2487002
#define TASK_CHVOMOD 2487004

#define MAXMODS 100

#define BIG_STRING 2048
#define LONG_STRING 256
#define SHORT_STRING 64

#define MENU_ITEMS_PER_PAGE	8

// Enables debug server console messages.
new g_is_debug = false

new g_coloredmenus
new g_menu_total_pages
new g_menuPosition[33]
new g_menuname[] = "VOTE MOD MENU"
new g_votemodcount[MAXMODS]

new g_modShortNames[MAXMODS][SHORT_STRING]// Per-mod short Names
new g_messageFileNames[MAXMODS][SHORT_STRING]// Per-mod Mod msg Names
new g_configsFileNames[MAXMODS][SHORT_STRING]// Per-mod Mod cfg Names
new g_modNames[MAXMODS][SHORT_STRING]// Per-mod Mod Names
new g_mapcycleFileNames[MAXMODS][LONG_STRING]// Per-mod Maps Files
new g_pluginsFileNames[MAXMODS][LONG_STRING]// Per-mod Plugin Files

new g_modCounter = 0 // integer with configured mods count, that is pre increment, so first mod is 1

new gp_allowedvote
new gp_endmapvote

new g_currentModShortName[SHORT_STRING]
new g_nextmodid
new g_currentmodid

new totalVotes
new SayText

new gp_mintime
new gp_voteanswers
new gp_timelimit

new g_mapmanagertype
new gp_mapcyclefile

new g_alertMultiMod[BIG_STRING] = ";Configuration files of Multi-Mod System^n//\
which is run every time the server starts and defines which mods are enabled.^n//\
This file is managed automatically by multimod_manager.sma plugin^n//\
and any modification will be discarded in the activation of some mod.^n^n"

new g_helpamx_setmod[LONG_STRING] = "help 1	      | for help."
new g_helpamx_setmods[LONG_STRING] = "shortModName <1 or 0> to restart or not       | Enable/Disable any mod, \
loaded or not (silent mod). "

new g_cmdsAvailables1[LONG_STRING] = "^namx_setmod help 1       | To show this help.^n\
amx_setmod disable 1   | To deactivate any active Mod.^n\
amx_votemod	| To force a votemod.^n\
say nextmod	 | To see which is the next mod."

new g_cmdsAvailables2[LONG_STRING] = "say_team nextmod	       | To see which is the next mod.^n\
say currentmod	| To see which is the current mod.^n\
say votemod	 | To try start a vote mod.^n\
say_team votemod	 | To try start a vote mod."

// Contains the address of the configurations folder amx mod x
new g_configFolder[LONG_STRING]

/**
 * Register plugin commands and load configurations.
 */
public plugin_init()
{   
	new MenuName[SHORT_STRING]

	register_plugin(PLUGIN, VERSION, AUTHOR)
	register_cvar("MultiModManager", VERSION, FCVAR_SERVER|FCVAR_SPONLY)
	register_dictionary("mapchooser.txt")
	register_dictionary("multimodmanager.txt")

	gp_mintime = register_cvar("amx_mintime", "10")
	gp_allowedvote = register_cvar("amx_multimod_voteallowed", "1")
	gp_endmapvote = register_cvar("amx_multimod_endmapvote", "0")

	// Setup folder addresses
	get_configsdir(g_configFolder, charsmax(g_configFolder))
	SayText = get_user_msgid("SayText");

	register_clcmd("amx_votemod", "start_vote", ADMIN_MAP, "Vote for the next mod")
	register_clcmd("say nextmod", "user_nextmod")
	register_clcmd("say_team nextmod", "user_nextmod")
	register_clcmd("say currentmod", "user_currentmod")
	register_clcmd("say_team currentmod", "user_currentmod")
	register_clcmd("say votemod", "user_votemod")
	register_clcmd("say_team votemod", "user_votemod")

	register_concmd("amx_setmod", "receiveCommand", ADMIN_CFG, g_helpamx_setmod )
	register_concmd("amx_setmods", "receiveCommandSilent", ADMIN_IMMUNITY, g_helpamx_setmods )

	formatex(MenuName, charsmax(MenuName), "%L", LANG_PLAYER, "MM_VOTE")
	register_menucmd(register_menuid(g_menuname), BIG_STRING - 1, "player_vote")
	g_coloredmenus = colored_menus()
	totalVotes = 0
	g_nextmodid = 1
}

/**
 * Makes auto configuration about mapchooser plugin, switching between multimod_mapchooser and 
 * galileo. 
 * Gets current game mods cvars pointer to this program global variables.
 * Adjust the localinfo variable that store the current mod loaded, reading the current mod file.
 */
public plugin_cfg()
{   
	gp_voteanswers = get_cvar_pointer("amx_vote_answers")
	gp_timelimit = get_cvar_pointer("mp_timelimit")
	gp_mapcyclefile = get_cvar_pointer("mapcyclefile")
	get_localinfo( "amx_multimod", g_currentModShortName, charsmax(g_currentModShortName) )

	switchMapManager()
	loadCurrentMod()

	if( get_pcvar_num( gp_endmapvote ) )
	{
		set_task(15.0, "check_task", TASK_VOTEMOD, "", 0, "b")
	}
}

/**
 * Process the input command "amx_setmod OPITON1 OPITON2".
 * 
 * @param id - will hold the players id who started the command
 * @param level - will hold the access level of the command
 * @param cid - will hold the commands internal id 
 *
 * @arg Arg1 the modShortName to enable 
 * @arg Arg2 inform to start a vote map "1" or not "0" 
 */
public receiveCommand(id, level, cid)
{   
	//Make sure this user is an admin
	if (!cmd_access(id, level, cid, 3))
	{   
		return PLUGIN_HANDLED
	}
	new Arg1[ SHORT_STRING ]
	new Arg2[SHORT_STRING]

	//Get the command arguments from the console
	read_argv( 1, Arg1, charsmax( Arg1 ) )
	read_argv( 2, Arg2, charsmax( Arg2 ) )

	if( primitiveFunctions( Arg1, Arg2, id ) )
	{   
		new mod_id_number = getModID( Arg1 )

		if( mod_id_number != -1 ) // mod_id_number is -1 if it is specified a invalid mod, at Arg1 above
		{   
			// don't need return if it was successful, because the mod_id_number guarantee it
			configureMultimod( mod_id_number ) 

			msgModActivated( Arg1, Arg2 )

		} else
		{   
			new error[128]="ERROR at receiveCommand!! Mod invalid or a configuration file is missing!"
			printMessage( error, 0 )
			printHelp( id )
		}
	}
	return PLUGIN_HANDLED
}

/**
 * Given a mod short name like "predator", finds its plugins internals mod id.
 * 
 * @param shortName the mod short name.
 */
public getModID( shortName[] )
{   
	for( new mod_id_number = 3; mod_id_number <= g_modCounter; mod_id_number++ )
	{   
		if( equal( shortName, g_modShortNames[mod_id_number] ) )
		{   
			return mod_id_number
		}
	}
	return -1
}

/**
 * Check the activation of the function of disableMods and help.
 * 
 * @param Arg1[] the first command line argument
 * @param Arg2[] the second command line argument
 * @param id the player id
 *
 * @return true if was not asked for a primitive function, false otherwise.
 */
public primitiveFunctions( Arg1[], Arg2[], id )
{   
	if( equal( Arg1, "disable" ) )
	{   
		disableMods()
		printMessage( "^1The ^4current mod^1 will be deactivated at ^4next server restart^1.", id )

		if( !equal( Arg2, "0" ) )
		{
			msgResourceActivated("disable", "1" )
		}
		return false
	}
	if( equal( Arg1, "help" ) )
	{   
		printHelp( id )
		return false
	}
	return true
}

/**
 * Given a player id, prints to him and at server console the help about the command 
 * "amx_setmod".
 *
 * @param id the player id
 */
public printHelp( id )
{   
	new text[LONG_STRING]

	client_print( id, print_console , g_cmdsAvailables1 )
	client_print( id, print_console , g_cmdsAvailables2 )
	server_print( g_cmdsAvailables1 )
	server_print( g_cmdsAvailables2 )

	for( new i = 3; i <= g_modCounter; i++ )
	{   
		formatex( text, charsmax(text), "amx_setmod %s 1          | to use %s",
				g_modShortNames[i], g_modNames[i] )

		client_print( id, print_console , text )
		server_print( text )
	}
	client_print( id, print_console , "^n" )
	server_print( "^n" )
}

/**
 * Process the input command "amx_setmod OPITON1 OPITON2". 
 * Straight restarting the server, (silent mod) and changes and configures the mapcycle if 
 *   there is one
 * 
 * @param id - will hold the players id who started the command
 * @param level - will hold the access level of the command
 * @param cid - will hold the commands internal id 
 * 
 * @arg Arg1 the modShortName to enable silently
 * @arg Arg2 inform to restart the current map "1" or not "0" 
 */
public receiveCommandSilent(id, level, cid)
{   
	//Make sure this user is an admin
	if (!cmd_access(id, level, cid, 3))
	{   
		return PLUGIN_HANDLED
	}

	new Arg1[SHORT_STRING]
	new Arg2[SHORT_STRING]

	//Get the command arguments from the console
	read_argv( 1, Arg1, charsmax( Arg1 ) )
	read_argv( 2, Arg2, charsmax( Arg2 ) )

	if( equal( Arg1, "disable" ) )
	{   
		disableMods()

		if( equal( Arg2, "1" ) )
		{
			// freeze the game and show the scoreboard
			message_begin(MSG_ALL, SVC_INTERMISSION);
			message_end();

			new deactivation_message[LONG_STRING]
			formatex( deactivation_message, charsmax(deactivation_message), "^1The ^4current mod^1 will be deactivated at ^4next \
					server restart^1.", Arg1 )

			printMessage( deactivation_message, 0 )
			set_task(5.0, "restartTheServer");
		}
	} else if( activateModSilent( Arg1 ) && equal( Arg2, "1" ) )
	{
		// freeze the game and show the scoreboard
		message_begin(MSG_ALL, SVC_INTERMISSION);
		message_end();

		new activation_message[LONG_STRING]
		formatex( activation_message, charsmax(activation_message), "^1The mod ( ^4%s^1 ) will be activated at ^4next \
				server restart^1.", Arg1 )

		printMessage( activation_message, 0 )
		set_task(5.0, "restartTheServer");
	} 

	return PLUGIN_HANDLED
}

/**
 * A simple instantly server restart.
 */
public restartTheServer()
{
	server_cmd( "restart" )
}

/**
 * The 'currentmod.ini' and 'currentmodsilent.ini', at multimod folder, stores the current 
 *    mod actually active and the current mod was activated by silent mode, respectively. 
 * When 'currentmod.ini' stores 0, 'currentmodsilent.ini' defines the current mod. 
 * When 'currentmod.ini' stores anything that is not 0, 'currentmod.ini' defines the current mod.
 */
public loadCurrentMod()
{   
	new currentModCode
	new ilen

	new currentModFilePath[LONG_STRING]
	new currentModSilentFilePath[LONG_STRING]

	new currentModId_String[SHORT_STRING]
	new currentModSilentId_String[SHORT_STRING]

	formatex(currentModFilePath, charsmax(currentModFilePath), "%s/multimod/currentmod.ini", g_configFolder)
	formatex(currentModSilentFilePath, charsmax(currentModFilePath), "%s/multimod/currentmodsilent.ini", g_configFolder)

	// normal mod activation 
	if( file_exists( currentModFilePath ) )
	{
		read_file(currentModFilePath, 0, currentModId_String, charsmax(currentModId_String), ilen )
		currentModCode = str_to_num( currentModId_String )
	} 
	else
	{
		currentModCode = -1
	}

	// silent mod activation 
	if( file_exists( currentModSilentFilePath ) )
	{
		read_file( currentModSilentFilePath, 0, currentModSilentId_String, charsmax(currentModSilentId_String), ilen )
	} 
	else
	{
		currentModCode = -1
	} 

	build_first_mods() 
	load_cfg() 

	switch( currentModCode )
	{   
		case -1: // If -1, there is no mod active. 
		{   
			configureMultimod( 2 ) 
		}
		case 0: // If 0, the current mod was activated by silent mode
		{
			g_currentmodid = 1
			activateModSilent( currentModSilentId_String ) 
		}
		default: 
		{
			configureMultimod( currentModCode + 2  ) 
		}
	}
}

/**
 * Given a mod_id_number, salves it to file "currentmod.ini", at multimod folder.
 * 
 * @param mod_id_number the mod id.
 */
saveCurrentMod( mod_id_number )
{   
	new mod_idString[SHORT_STRING]
	new currentModConfigFilePath[LONG_STRING]

	formatex( currentModConfigFilePath, charsmax(g_configFolder), "%s/multimod/currentmod.ini", g_configFolder )

	if ( file_exists( currentModConfigFilePath ) )
	{   
		delete_file( currentModConfigFilePath )
	}

	formatex( mod_idString, charsmax(mod_idString), "%d", mod_id_number - 2 )
	write_file( currentModConfigFilePath, mod_idString )
}

/**
 *  Saves the current silent mod activated to file "currentmodsilent.ini", at multimod folder.
 *
 * @param modShortName[] the mod short name. Ex: surf.
 */
public saveCurrentModSilent( modShortName[] )
{
	new currentModConfigFilePath[LONG_STRING]

	formatex( currentModConfigFilePath, charsmax(g_configFolder), "%s/multimod/currentmodsilent.ini", g_configFolder )

	if( file_exists( currentModConfigFilePath ) )
	{   
		delete_file( currentModConfigFilePath )
	}
	write_file( currentModConfigFilePath, modShortName )
}

/**
 * Set the current game mod and changes the mapcycle, if and only if it was created. 
 * 
 * @param mod_id_number the mod index.
 */
public configureMultimod( mod_id_number )
{   
	g_currentmodid = mod_id_number

	switch( mod_id_number )
	{   
		case 1: // "Keep Current Mod", it is necessary when silent mode is used.
		{   
			return
		}
		case 2: // "No mod - Disable Mod", it is necessary at user votes.
		{   
			disableMods()
		}
		default: 
		{   
			activateMod( mod_id_number  )
		}
	}
	configDailyMapsSilent( g_mapcycleFileNames[mod_id_number] )
	configMapManagerSilent( g_mapcycleFileNames[mod_id_number] )
}

/**
 * Makes at votemod menu, display the first mod as the option: "Keep Current Mod". And at 
 * votemod menu, display the second mod as the option: "No mod - Disable Mod".
 */
public build_first_mods()
{   
	g_modCounter++

	formatex( g_modNames[g_modCounter], SHORT_STRING - 1, "Keep Current Mod" )
	formatex( g_configsFileNames[g_modCounter], SHORT_STRING - 1, "none.cfg" )
	formatex( g_mapcycleFileNames[g_modCounter], SHORT_STRING - 1, "none.txt" )
	formatex( g_pluginsFileNames[g_modCounter], SHORT_STRING - 1, "none.txt" )
	formatex( g_messageFileNames[g_modCounter], SHORT_STRING - 1, "nobe.cfg" )

	g_modCounter++

	formatex( g_modNames[g_modCounter], SHORT_STRING - 1, "No mod - Disable Mod" )
	formatex( g_configsFileNames[g_modCounter], SHORT_STRING - 1, "none.cfg" )
	formatex( g_mapcycleFileNames[g_modCounter], SHORT_STRING - 1, "none.txt" )
	formatex( g_pluginsFileNames[g_modCounter], SHORT_STRING - 1, "none.txt" )
	formatex( g_messageFileNames[g_modCounter], SHORT_STRING - 1, "nobe.cfg" )
}

/**
 * Loads the config file "multimod.ini" and all mods stored there.
 */
public load_cfg()
{   
	new currentLine[LONG_STRING]
	new configFilePath[LONG_STRING]

	formatex(configFilePath, charsmax(configFilePath), "%s/multimod/multimod.ini", g_configFolder)

	new configFilePointer = fopen( configFilePath, "rt" )
	new currentLineSplited[SHORT_STRING]
	new modName[SHORT_STRING]
	new modShortNameString[SHORT_STRING]
	new unusedLastString[SHORT_STRING]

	while( !feof( configFilePointer ) )
	{   
		fgets( configFilePointer, currentLine, charsmax(currentLine) )
		trim( currentLine )

		// skip commentaries while reading file
		if( !currentLine[0] || currentLine[0] == ';' 
				|| ( currentLine[0] == '/' && currentLine[1] == '/' ) )
		{   
			continue
		}

		if( currentLine[0] == '[' )
		{   
			g_modCounter++

			// remove line delimiters [ and ]
			replace_all( currentLine, charsmax(currentLine), "[", "" )
			replace_all( currentLine, charsmax(currentLine), "]", "" )

			// broke the current config line, in modname (modName), modtag (modShortNameString) 
			strtok( currentLine, modName, charsmax(modName), currentLineSplited, charsmax(currentLineSplited), ':', 0 )
			strtok( currentLineSplited, modShortNameString, charsmax(modShortNameString), unusedLastString, charsmax( unusedLastString ), ':', 0 )

			// stores at memory multi-dimensionals arrrays: the cfgfilename, modname, 
			// filemapsname and plugin_modname
			formatex( g_modNames[g_modCounter], SHORT_STRING - 1, "%s", modName )
			formatex( g_modShortNames[g_modCounter], SHORT_STRING - 1, "%s", modShortNameString )
			formatex( g_configsFileNames[g_modCounter], SHORT_STRING - 1, "%s.cfg", modShortNameString )
			formatex( g_mapcycleFileNames[g_modCounter], SHORT_STRING - 1, "%s", mapCyclePathCoder( modShortNameString ) )
			formatex( g_pluginsFileNames[g_modCounter], SHORT_STRING - 1, "%s.txt", modShortNameString )
			formatex( g_messageFileNames[g_modCounter], SHORT_STRING - 1, "%s.cfg", modShortNameString )

			//print at server console each mod loaded
			if( g_is_debug )
			{   
				server_print( "[AMX MOD Loaded] %d %s - %s %s %s %s", g_modCounter - 2,
						g_modNames[g_modCounter], g_pluginsFileNames[g_modCounter], g_configsFileNames[g_modCounter],
						g_mapcycleFileNames[g_modCounter], g_messageFileNames[g_modCounter] )
			}
		}
	}
	fclose( configFilePointer )
}

/**
 * Hard code the mapcycle file location.
 * 
 * @param Arg1[] the mapcycle file name without extension and path. Ex: surf
 *
 * @return the mapcycle file name with extension and path. Ex: mapcycles/surf.txt
 */
public mapCyclePathCoder( Arg1[] )
{   
	new mapcycleTemp[SHORT_STRING]
	formatex( mapcycleTemp, SHORT_STRING - 1, "mapcycles/%s.txt", Arg1 )

	return mapcycleTemp
}

/**
 * Makes the autoswitch between mapchooser and galileo_reloaded. If both are 
 *   active, prevails galileo_reloaded.
 */
public switchMapManager()
{   
	if( find_plugin_byfile( "galileo_reloaded.amxx" ) != -1 )
	{   
		g_mapmanagertype = 2

	} else if( find_plugin_byfile( "multimod_mapchooser.amxx" ) != -1 )
	{   
		g_mapmanagertype = 1
	}
}

/**
 * Setup the map manager to work with votemod menu at Silent mode. That is, configures
 *  the compatibility with galileo_reloaded, multimod_mapchooser and daily_maps, because now 
 *  there is no mod_id_number, hence because the mod is not loaded from the mod file configs.
 * 
 * @param Arg1[] the mapcycle file name with extension and path. Ex: mapcycles/surf.txt
 */
public configMapManagerSilent( Arg1[] )
{   
	if( file_exists( Arg1 ) )
	{   
		switch( g_mapmanagertype )
		{   
			case 1:
			{   
				if( callfunc_begin("plugin_init", "multimod_mapchooser.amxx" ) == 1 )
				{   
					callfunc_end()

				} else
				{   
					new error[128]="ERROR at configMapManager!! multimod_mapchooser.amxx NOT FOUND!^n"
					client_print( 0, print_console , error )
					server_print( error )
				}
			}
			case 2:
			{   
				new galileo_mapfile = get_cvar_pointer( "gal_vote_mapfile" )

				if( galileo_mapfile )
				{   
					set_pcvar_string( galileo_mapfile, Arg1 )
				}
			}
		}
	}
}

/**
 * Change the game global variable at localinfo isFirstTimeLoadMapCycle to 1 or 2, after 
 *   the first map load. It is to avoid mapcycle re-change, causing the first mapcycle 
 *   map, always being the nextmap. 
 * 
 * The localinfo isFirstTimeLoadMapCycle as 1, is used by multimod_manager.sma, 
 *    to know if there is a game mod mapcycle file. 
 * The localinfo isFirstTimeLoadMapCycle as 2, is used by multimod_daily_changer.sma, 
 *    to know if there is not game mod mapcycle. 
 *
 * @param Arg1[] the mapcycle file name with its extension and path. Ex: mapcycles/surf.txt
 */
public configDailyMapsSilent( Arg1[] )
{
	new isFirstTime[32]
	get_localinfo( "isFirstTimeLoadMapCycle", isFirstTime, charsmax( isFirstTime ) );
	new isFirstTimeNum = str_to_num( isFirstTime )

	if( file_exists( Arg1 ) )
	{   
		if( isFirstTimeNum  == 0 )
		{
			//server_print("^n^n^n^n^n%d^n^n", isFirstTimeNum)
			set_localinfo( "isFirstTimeLoadMapCycle", "1" );
			set_localinfo( "lastmapcycle", Arg1 )
			set_pcvar_string( gp_mapcyclefile, Arg1 )
		}
	} else 
	{
		set_localinfo( "isFirstTimeLoadMapCycle", "2" );
	}
}

/**
 * Deactivate any loaded/active mod.
 */
public disableMods()
{   
	new currentModShortName[ SHORT_STRING ]
	get_localinfo( "amx_multimod", currentModShortName, charsmax( currentModShortName ) );
	
	new fileLateConfigRead[ LONG_STRING ]
	new filePluginsWrite[LONG_STRING]
	new fileCurrentModId[LONG_STRING]
	new fileCurrentModSilent[LONG_STRING]
	new fileMultiModConfig[LONG_STRING]

	formatex( fileLateConfigRead, charsmax(g_configFolder), "%s/multimod/latecfg/%.cfg", g_configFolder, currentModShortName )
	formatex( filePluginsWrite, charsmax(g_configFolder), "%s/plugins-multi.ini", g_configFolder )
	formatex( fileCurrentModId, charsmax(g_configFolder), "%s/multimod/currentmod.ini", g_configFolder ) 
	formatex( fileCurrentModSilent, charsmax(g_configFolder), "%s/multimod/currentmodsilent.ini", g_configFolder )
	formatex( fileMultiModConfig, charsmax(g_configFolder), "%s/multimod/multimod.cfg", g_configFolder )

	if( file_exists( fileLateConfigRead ) )
	{   
		new deactivation_message[LONG_STRING]
		formatex( deactivation_message, charsmax(deactivation_message), "Executing the deactivation mod \
				configuration file ( %s ).", fileLateConfigRead )

		printMessage( deactivation_message, 0 )
		server_cmd( "exec %s", fileLateConfigRead )
	}

	if( file_exists( fileCurrentModId ) )
	{   
		delete_file( fileCurrentModId )
	}

	if( file_exists( fileMultiModConfig ) )
	{   
		delete_file( fileMultiModConfig )
	}

	if( file_exists( fileCurrentModSilent ) )
	{   
		delete_file( fileCurrentModSilent )
	}

	if( file_exists( filePluginsWrite ) )
	{   
		delete_file( filePluginsWrite )
	}

	write_file( fileMultiModConfig, g_alertMultiMod )
	write_file( filePluginsWrite, g_alertMultiMod )
	write_file( fileCurrentModSilent, "" )
	write_file( fileCurrentModId, "-1" )
}

/**
 * Actives a mod by its configs files.
 * 
 * @param mod_id_number the mod id to active.
 *
 * Throws = ERROR !! Any configuration file is missing!
 */
public activateMod( mod_id_number )
{   
	new filePluginRead[LONG_STRING]
	new filePluginWrite[LONG_STRING]

	formatex( filePluginRead, charsmax( filePluginRead ),"%s/multimod/plugins/%s", g_configFolder, g_pluginsFileNames[mod_id_number] )
	formatex( filePluginWrite, charsmax(filePluginWrite), "%s/plugins-multi.ini", g_configFolder )

	if( file_exists(filePluginRead) )
	{   
		new fileConfigRead[LONG_STRING]
		new fileConfigWrite[LONG_STRING]

		formatex( fileConfigRead, charsmax(fileConfigRead), "%s/multimod/cfg/%s", g_configFolder, g_configsFileNames[mod_id_number] )
		formatex( fileConfigWrite, charsmax(fileConfigWrite), "%s/multimod/multimod.cfg", g_configFolder )
		disableMods()

		copyFiles( filePluginRead, filePluginWrite, g_alertMultiMod )

		if( file_exists( fileConfigRead ) )
		{
			copyFiles( fileConfigRead, fileConfigWrite, g_alertMultiMod )
		}

		saveCurrentMod( mod_id_number )

		server_print( "Setting multimod to %i - %s", mod_id_number - 2, g_modNames[mod_id_number] )
		set_localinfo( "amx_multimod", g_modShortNames[mod_id_number] )

	} else
	{   
		new error[128]="ERROR at activateMod!! Mod invalid or a configuration file is missing!"
		printMessage( error, 0 )
	}
}

/**
 * Actives a mod by its configs files silently and straight restart the server. That is, change 
 *   the current mod to 'Keep Current Mod', the active the mods by its file name exists.
 * 
 * @param modShortName[] the mod short name to active. Ex: surf
 *
 * Throws = ERROR !! Any configuration file is missing!
 */
public activateModSilent( modShortName[] )
{   
	new filePluginRead[LONG_STRING]
	new filePluginWrite[LONG_STRING]

	formatex( filePluginRead, charsmax(filePluginRead), "%s/multimod/plugins/%s.txt", g_configFolder, modShortName )
	formatex( filePluginWrite, charsmax(filePluginWrite), "%s/plugins-multi.ini", g_configFolder )

	if( file_exists(filePluginRead) )
	{   
		new fileConfigRead[LONG_STRING]
		new fileConfigWrite[LONG_STRING]
		new mapCycleFile[SHORT_STRING] 

		formatex( fileConfigRead, charsmax(fileConfigRead), "%s/multimod/cfg/%s.cfg", g_configFolder, modShortName )
		formatex( fileConfigWrite, charsmax(fileConfigWrite), "%s/multimod/multimod.cfg", g_configFolder )
		disableMods()

		copyFiles( filePluginRead, filePluginWrite, g_alertMultiMod )
		
		if( file_exists(fileConfigRead) )
		{
			copyFiles( fileConfigRead, fileConfigWrite, g_alertMultiMod )
		}

		copy( mapCycleFile, charsmax(mapCycleFile), mapCyclePathCoder( modShortName ) )
		
		configMapManagerSilent( mapCycleFile )
		configDailyMapsSilent( mapCycleFile )

		g_currentmodid = 1
		saveCurrentMod( 2 )
		saveCurrentModSilent( modShortName )

		server_print( "Setting multimod to %s", modShortName )
		set_localinfo( "amx_multimod", modShortName )
		
		return true

	} else
	{   
		new error[128]="ERROR at activateModSilent!! Mod invalid or a configuration file is missing!"
		printMessage( error, 0 )
	}
	return false
}

/**
 * Copy the sourceFilePath to destinationFilePath, replacing the existing file destination and
 * adding to its beginning the contents of the String inicialFileText.
 *
 * @param sourceFilePath[] the source file
 * @param destinationFilePath[] the destination file
 * @param inicialFileText[] an additional text
 */
public copyFiles( sourceFilePath[], destinationFilePath[], inicialFileText[] )
{   
	if ( file_exists( destinationFilePath ) )
	{   
		delete_file( destinationFilePath )
	}	
	write_file( destinationFilePath, inicialFileText, 0 )

	new sourceFilePathPointer = fopen( sourceFilePath, "rt" )
	new Text[512];

	while ( !feof( sourceFilePathPointer ) )
	{   
		fgets( sourceFilePathPointer, Text, sizeof(Text) - 1 )
		trim(Text)
		write_file( destinationFilePath, Text, -1)
	}
	fclose( sourceFilePathPointer )
}

/**
 * Copies the contents of sourceFilePath to the beginning of destinationFilePath
 * 
 * @param sourceFilePath[] the source file
 * @param destinationFilePath[] the destination file
 */
public copyFiles2( sourceFilePath[], destinationFilePath[] )
{   
	new sourceFilePathPointer = fopen( sourceFilePath, "rt" )
	new Text[512];

	while ( !feof( sourceFilePathPointer ) )
	{   
		fgets( sourceFilePathPointer, Text, sizeof(Text) - 1 )
		trim(Text)
		write_file( destinationFilePath, Text, -1 )
	}
	fclose( sourceFilePathPointer )
}

/**
 * Displays a message to all server players about a command line Mod active with "amx_setmod".
 * 
 * @param modShortName[] the activated mod mod long name. Ex: surf
 * @param is_restart[] inform to restart the server if "1"
 */
public msgModActivated( modShortName[], is_restart[] )
{   
	new activation_message[LONG_STRING]
	formatex( activation_message, charsmax(activation_message), "^1The mod ( ^4%s^1 ) will be activated at ^4next server restart^1.",
			modShortName )

	printMessage( activation_message, 0 )

	if( equal( is_restart, "1" ) )
	{
		new msgPath[LONG_STRING]
		formatex( msgPath, charsmax(msgPath), "%s/multimod/msg/%s.cfg", g_configFolder, modShortName )

		if( file_exists( msgPath ) )
		{
			server_cmd( "exec %s", msgPath )

		} else
		{
			// freeze the game and show the scoreboard
			message_begin(MSG_ALL, SVC_INTERMISSION);
			message_end();

			set_task(5.0, "restartTheServer");
		}
	}
}

/**
 * Displays a message to all server player about a command line Resource active with "amx_setmod".
 * Its must match the file msg name at "multimod" folder. 
 * 
 * @param resourceName[] the name of the activated resource. Ex: disable
 * @param is_restart[] inform to restart the server if "1"
 */
public msgResourceActivated( resourceName[], is_restart[] )
{   
	new activation_message[LONG_STRING]
	formatex( activation_message, charsmax(activation_message), "^1The resource ( ^4%s^1 ) will be activated at ^4next server restart^1.", 
			resourceName )

	printMessage( activation_message, 0 )

	if( equal( is_restart, "1" ) )
	{
		new msgPath[LONG_STRING]
		formatex( msgPath, charsmax(msgPath), "%s/multimod/%s.cfg", g_configFolder, resourceName )

		if( file_exists( msgPath ) )
		{
			server_cmd( "exec %s", msgPath )

		} else
		{
			// freeze the game and show the scoreboard
			message_begin(MSG_ALL, SVC_INTERMISSION);
			message_end();

			set_task(5.0, "restartTheServer");
		}
	}
}

/**
 * Displays a message to a specific server player id and at the server console.
 *
 * @param message[] the text to display
 * @param id the player id
 */
public printMessage( message[], id )
{   
#if AMXX_VERSION_NUM < 183
	print_color( id, message )
#else
	print_chat_color( id, message )
#endif
	
	replace_all( message, 190, "^4", "" );
	replace_all( message, 190, "^1", "" );
	replace_all( message, 190, "^3", "" );
	
	client_print( id, print_center , message )
	client_print( id, print_console , message )
	server_print( message )
}

/**
 * DeRoiD's Mapchooser print_color function:
 *   https://forums.alliedmods.net/showthread.php?t=261412
 * 
 * @id the player id to display, use 0 for all players.
 * @input the colored formatting rules
 * @any the variable number of formatting parameters
 */
stock print_color(const id, const input[], any:...)
{
	new Count = 1, Players[32];
	static Msg[191];
	vformat(Msg, 190, input, 3);
	
	//replace_all(Msg, 190, "!g", "^4");
	//replace_all(Msg, 190, "!y", "^1");
	//replace_all(Msg, 190, "!t", "^3");

	if(id) Players[0] = id; else get_players(Players, Count, "ch");
	{
		for (new i = 0; i < Count; i++)
		{
			if (is_user_connected(Players[i]))
			{
				message_begin(MSG_ONE_UNRELIABLE, SayText, _, Players[i]);
				write_byte(Players[i]);
				write_string(Msg);
				message_end();
			}
		}
	}
	return PLUGIN_HANDLED;
}

/**
 * Displays a message to a specific server player showing the next mod to be loaded. 
 * 
 * @param id the player id
 */
public user_nextmod(id)
{   
	client_print( 0, print_chat, "%L", LANG_PLAYER, "MM_NEXTMOD", g_modNames[ g_nextmodid ] )

	return PLUGIN_HANDLED
}

/**
 * Displays a message to a specific server player show the current mod.
 * 
 * @param id the player id
 */
public user_currentmod(id)
{   
	client_print(0, print_chat, "The game current mod is: %s", g_modNames[ g_currentmodid ] )

	return PLUGIN_HANDLED
}

/**
 * Called with "say votemod". Checks:
 *	If users can invoke voting.
 *	If its already voted.
 */
public user_votemod(id)
{   
	if( get_pcvar_num( gp_allowedvote ) )
	{   
		client_print(0, print_chat, "%L", LANG_PLAYER, "MM_VOTEMOD", g_modNames[g_nextmodid])
		return PLUGIN_HANDLED
	}
	new Float:elapsedTime = get_pcvar_float(gp_timelimit) - (float(get_timeleft()) / 60.0)
	new Float:minTime
	minTime = get_pcvar_float(gp_mintime)

	if(elapsedTime < minTime)
	{   
		client_print( id, print_chat, "[AMX MultiMod] %L", LANG_PLAYER, "MM_PL_WAIT",
		floatround(minTime - elapsedTime, floatround_ceil) )

		return PLUGIN_HANDLED
	}
	new timeleft = get_timeleft()

	if(timeleft < 180)
	{   
		client_print( id, print_chat, "You can't start a vote mod while the timeleft is %d seconds",
				timeleft )

		return PLUGIN_HANDLED
	}
	start_vote()
	return PLUGIN_HANDLED
}

public check_task()
{   
	new timeleft = get_timeleft()

	if(timeleft < 300 || timeleft > 330)
	{   
		return
	}
	start_vote()
}

/**
 * Start multi mod voting.
 * 
 * If a new voting was invoked:
 *   Restart voting count.
 *   Restart voting players menu position.
 */
public start_vote()
{   
	remove_task(TASK_VOTEMOD)
	remove_task(TASK_CHVOMOD)

	for( new i = 0; i < 33; i++ )
	{   
		g_menuPosition[i] = 0
	}

	for( new i = 0; i < MAXMODS; i++ )
	{   
		g_votemodcount[i] = 0
	}

	display_votemod_menu( 0, 0 )
	client_cmd(0, "spk Gman/Gman_Choose2")

	if( g_is_debug )
	{   
		set_task( 6.0, "check_vote", TASK_CHVOMOD )
	} else
	{   
		set_task( 30.0, "check_vote", TASK_CHVOMOD )
	}
}

/**
 * Create the vote mod menu multi pages.
 * 
 * @param id the player id to display the menu.
 * @param menu_current_page the number of the current menu page to draw the menu.
 */
public display_votemod_menu( id, menu_current_page )
{   
	if( menu_current_page < 0 )
	{   
		return
	}

	new menu_body[BIG_STRING]
	new menu_valid_keys
	new current_write_position
	new current_page_itens
	new g_menusNumber = g_modCounter

	// calc. g_menu_total_pages
	if( ( g_menusNumber % MENU_ITEMS_PER_PAGE ) > 0 )
	{   
		g_menu_total_pages = ( g_menusNumber / MENU_ITEMS_PER_PAGE ) + 1
	} else
	{   
		g_menu_total_pages = ( g_menusNumber / MENU_ITEMS_PER_PAGE )
	}

	// calc. Menu titles
	if( g_coloredmenus )
	{   
		current_write_position = formatex( menu_body, charsmax(menu_body), "\y%L: \R%d/%d\w^n^n",
				LANG_PLAYER, "MM_CHOOSE", menu_current_page + 1, g_menu_total_pages )
	} else
	{   
		current_write_position = formatex( menu_body, charsmax(menu_body), "%L: %d/%d^n^n",
		LANG_PLAYER, "MM_CHOOSE", menu_current_page + 1, g_menu_total_pages )
	}

	// calc. the number of current_page_itens
	if( g_menu_total_pages == menu_current_page + 1 )
	{   
		current_page_itens = g_menusNumber % MENU_ITEMS_PER_PAGE
	} else
	{   
		current_page_itens = MENU_ITEMS_PER_PAGE
	}

	// calc. the current page menu body
	new for_index = 0
	new mod_vote_id

	for( new vote_mod_code = menu_current_page * 10;
	vote_mod_code < menu_current_page * 10 + current_page_itens; vote_mod_code++ )
	{   
		mod_vote_id = convert_octal_to_decimal( vote_mod_code )

		current_write_position += formatex( menu_body[ current_write_position ],
				BIG_STRING - current_write_position , "%d. %s^n", for_index + 1,
				g_modNames[ mod_vote_id + 1] )

		g_votemodcount[ mod_vote_id ] = 0
		for_index++
	}

	// create valid keys ( 0 to 9 )
	menu_valid_keys = MENU_KEY_0
	for( new i = 0; i < 9; i++ )
	{   
		menu_valid_keys |= (1<<i)
	}
	menu_valid_keys |= MENU_KEY_9

	// calc. the final page buttons
	if ( menu_current_page )
	{   
		if( g_menu_total_pages == menu_current_page + 1 )
		{   
			current_write_position += formatex( menu_body[current_write_position],
					BIG_STRING - current_write_position, "^n0. Back" )
		} else
		{   
			current_write_position += formatex( menu_body[current_write_position],
					BIG_STRING - current_write_position, "^n9. More...^n0. Back" )
		}
	} else
	{   
		if( g_menu_total_pages != menu_current_page + 1 )
		{   
			current_write_position += formatex( menu_body[current_write_position],
					BIG_STRING - current_write_position, "^n9. More...^n" )
		}
	}

	if( g_is_debug )
	{   
		new debug_player_name[64]
		get_user_name( id, debug_player_name, 63 )

		server_print( "Player: %s^nMenu body %s ^nMenu name: %s ^nMenu valid keys: %i",
				debug_player_name, menu_body, g_menuname, menu_valid_keys )

		show_menu( id, menu_valid_keys, menu_body, 5, g_menuname )
	} else
	{   
		show_menu( id, menu_valid_keys, menu_body, 25, g_menuname )
	}
}

/**
 * Given a vote_mod_code (octal number), calculates and return the mod internal id 
 * (decimal number).
 */
public convert_octal_to_decimal( octal_number )
{   
	new decimal = 0
	new i = 0
	new remainder

	while( octal_number != 0 )
	{   
		remainder = octal_number % 10
		octal_number /= 10
		decimal += remainder * power(8, i);
		++i
	}
	return decimal;
}

/**
 * Compute a player mod vote.
 * 
 * @param id the player id
 * @param key the player pressed/option key.
 */
public player_vote(id, key)
{   
	if( g_is_debug )
	{   
		server_print( "Key before switch: %d", key )
	}
	/* Well, I dont know why, but it doesnt even matter, how hard you try...
	 * You press the key 0, you gets 9 here. ...
	 * So here, i made the switch back.  */
	switch( key )
	{   
		case 9: key = 0
		case 0: key = 1
		case 1: key = 2
		case 2: key = 3
		case 3: key = 4
		case 4: key = 5
		case 5: key = 6
		case 6: key = 7
		case 7: key = 8
		case 8: key = 9
	}
	if( g_is_debug )
	{   
		server_print( "Key after switch: %d", key )
	}

	if( key == 9 )
	{   
		if( g_menuPosition[id] + 1 != g_menu_total_pages )
		{   
			display_votemod_menu(id, ++g_menuPosition[id])
		} else
		{   
			display_votemod_menu(id, g_menuPosition[id])
		}
	} else
	{   
		if( key == 0 )
		{   
			if( g_menuPosition[id] != 0 )
			{   
				display_votemod_menu(id, --g_menuPosition[id])
			} else
			{   
				display_votemod_menu(id, g_menuPosition[id])
			}
		} else
		{   
			new mod_vote_id = get_mod_vote_id( g_menuPosition[id], key )

			if( mod_vote_id <= g_modCounter && get_pcvar_num( gp_voteanswers) )
			{   
				new player[SHORT_STRING]
				new choose_message[LONG_STRING]

				get_user_name(id, player, charsmax(player))
				formatex( choose_message, charsmax(choose_message), "%L", LANG_PLAYER, "X_CHOSE_X", player,
				g_modNames[ mod_vote_id ] )

				client_print( 0, print_chat, choose_message )
				server_print( choose_message )

				g_votemodcount[ mod_vote_id ]++
			} else
			{   
				display_votemod_menu(id, g_menuPosition[id])
			}
		}

	}
}

/**
 * Given a current_menu_page and a current_pressed_key, returns internal the vote mod id.
 * 
 * @param current_menu_page the current page of player vote menu.
 * @param current_pressed_key the key pressed by the player to vote.
 */
public get_mod_vote_id( current_menu_page, current_pressed_key )
{   
	new vote_mod_code = current_menu_page * 10 + current_pressed_key
	new mod_vote_id = convert_octal_to_decimal( vote_mod_code )

	return mod_vote_id
}

/**
 * Start computing the mod voting.
 */
public check_vote()
{   
	new mostVoted = 1

	for(new a = 0; a <= g_modCounter; a++)
	{   
		if(g_votemodcount[mostVoted] < g_votemodcount[a])
		{   
			mostVoted = a
		}
		totalVotes = totalVotes + g_votemodcount[a]
	}
	displayVoteResults( mostVoted, totalVotes )
}

/**
 * Calculates the minimum votes required and print to server users the mod voting results.
 * 
 * @param mostVoted most voted mod id.
 * @param totalVotes the number total of votes.
 */
public displayVoteResults( mostVoted, totalVotes )
{   
	new result_message[LONG_STRING]
	new playerMin = playersPlaying( 0.3 )

	server_print( "Total Mod Votes: %d  | Player Min: %d  | Most Voted: %s",
			totalVotes, playerMin, g_modNames[ mostVoted ] )

	if( totalVotes > playerMin )
	{   
		g_nextmodid = mostVoted
		configureMultimod(mostVoted)

		
		formatex( result_message, charsmax(result_message), "%L", LANG_PLAYER, "MM_VOTEMOD",
		g_modNames[ mostVoted ])

		server_cmd( "exec %s/multimod/votefinished.cfg", g_configFolder )
	} 
	else
	{   
		new result_message[LONG_STRING]
		formatex( result_message, charsmax(result_message), "The vote did not reached the required minimum! \
		The next mod remains: %s", g_modNames[ g_currentmodid ])
	}
	totalVotes = 0
	printMessage( result_message, 0 )
}

/**
 * Returns the percent of player playing at game server, skipping bots and spectators.
 * 
 * @param a percent of the total playing players, in decimal. Example for 30%: 0.3
 * 
 * @return an integer of the parameter percent of players
 */
public playersPlaying( Float:percent )
{   
	new players[ 32 ]
	new players_count
	new count = 0

	// get the players in the server skipping bots
	get_players( players, players_count, "c" )

	for( new i = 1; i <= players_count; i++ )
	{   
		switch( get_user_team( i ) )
		{   
			case 1:
			{   
				count++ // terror
			}
			case 2:
			{   
				count++ // ct
			}
		}
	}
	return floatround( count * percent )
}
