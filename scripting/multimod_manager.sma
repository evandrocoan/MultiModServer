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


[SIZE="6"][COLOR="Blue"][B]Multi-Mod Manager v1.0-release_candidate2.hotfix4[/B][/COLOR][/SIZE]
[B]Release: 10.10.2015 | Last Update: 21.10.2015[/B]

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
[B]See its current development at: [URL="https://github.com/addonszz/MultiMod_Manager"]Github
[IMG]https://cdn3.iconfinder.com/data/icons/social-network-round-gloss-shine/128/GitHub_Social-Network-Communicate-Page-Curl-Effect-Circle-Glossy-Shadow-Shine.png[/IMG][/URL][/B] 
[B][COLOR="Blue"](look for the developer and feature branches)[/COLOR][/B]

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

[anchor]MyMultiModServer[/anchor][SIZE="4"][B]There is a Multi-Mod Server Configuration with:[/B][/SIZE] 
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
[SIZE="6"]Is available [URL="https://forums.alliedmods.net/showthread.php?t=273018"]here[/URL][/SIZE]. 

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

[anchor]Configuration[/anchor][B]6. [SIZE="5"][COLOR="red"]Configure[/COLOR][/SIZE][/B] your own mods at "[COLOR="Blue"]yourgamemod/addons/amxmodx/configs/multimod/[/COLOR][B]voting_list.ini[/B]" 
file as follow (the short mod name cannot be longer than 15 characters neither have spaces):

--- [B]Example of:[/B] [COLOR="Blue"]yourgamemod/addons/amxmodx/configs/multimod/[/COLOR][B]voting_list.ini[/B] ------
[QUOTE]
[Gun Game]:[gungame]:

;[mode name]:[shortModName]:
[/QUOTE]

-------------- And you have [B]to create[/B] the files:----------------------------
[QUOTE][COLOR="Blue"]yourgamemod/addons/amxmodx/configs/multimod/[/COLOR][B]plugins/gungame.ini[/B]

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
 * Add exception handle when the currentmod_id.ini or currentmod_shortname.ini is not found. 

2015-10-12 | v1.0-release_candidate2
 * Removed unused function get_firstmap() and variable g_nextmap. 
 * Replaced unnecessary functions configMapManager and configDailyMaps. 
 * Removed unnecessary MULTIMOD_MAPCHOOSER compiler constant. 
 * Added to multimod_daily_changer.sma compatibility with galileo_reloaded.sma 

2015-10-13 | v1.0-release_candidate2.hotfix1
 * Added missing format parameter at messageModActivated function.

2015-10-13 | v1.0-release_candidate2.hotfix2
 * Added missing MM_CHOOSE line at multilingual file.

2015-10-19 | v1.0-release_candidate2.hotfix3
 * Translated to english lost code variables. 
 * Replaced a implemented switch by a native switch. 
 * Replaced another implemented switch by a native switch. 
 * Improved variables names meaningful. 

2015-10-21 | v1.0-release_candidate2.hotfix4
 * Fixed mapcycle not setting when a mod was activated by command line or voting.  

2015-10-21 | v1.0-release_candidate3
 * Added late configuration file execution to built-in AMXX per map configurations. 
 * Added restaure the last mapcycle used. 
 * Improved code clearness. 
 * Added path coders to every multi-generated string. 
 * Added immutable strings paths as global variables. 
 * Removed unnecessary variables like g_messageFileNames and g_pluginsFileNames. 
[/QUOTE]

******************************** [anchor]TODO[/anchor][B][SIZE="5"][COLOR="blue"]TODO[/COLOR][/SIZE][/B] [goanchor=Top]Go Top[/goanchor] *********************************
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
[*]receive commands more efficiently than "command firstCommand_lineArgument secondCommand_lineArgument" even a for 1 argument command. 
[/LIST]

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
#define VERSION "v1.0-rc2.4"
#define AUTHOR "Addons zz"

#define TASK_VOTEMOD 2487002
#define TASK_CHVOMOD 2487004

#define MAXMODS 100
#define LONG_STRING 256
#define SHORT_STRING 64

#define MENU_ITEMS_PER_PAGE	8

// Enables debug server console messages.
new g_is_debug = 1

new g_totalVotes
new g_sayText
new g_coloredmenus
new g_menu_total_pages
new g_currentMod_id
new g_mapManagerType
new g_isFirstTime_serverLoad

new g_modNames					[MAXMODS][SHORT_STRING] 
new g_modShortNames			[MAXMODS][SHORT_STRING] 
new g_votemodcount				[MAXMODS]

new g_modCounter 									= 0 
new g_isTimeTo_changeMapcyle 			= false
new g_menuname[] 									= "VOTE MOD MENU"

new g_menuPosition							[33]
new g_currentMod_shortName			[SHORT_STRING]

new g_configFolder								[LONG_STRING]
new g_masterConfig_filePath				[LONG_STRING]
new g_masterPlugin_filePath					[LONG_STRING]
new g_voteFinished_filePath				[LONG_STRING]
new g_currentMod_id_filePath						[LONG_STRING]
new g_currentMod_shortName_filePath		[LONG_STRING]
new g_multimod_votingList_filePath			[LONG_STRING]

new gp_allowedvote
new gp_endmapvote
new gp_mintime
new gp_voteanswers
new gp_timelimit
new gp_mapcyclefile

new g_alertMultiMod[512] = ";Configuration files of Multi-Mod System^n//\
which is run every time the server starts and defines which mods are enabled.^n//\
This file is managed automatically by multimod_manager.sma plugin^n//\
and any modification will be discarded in the activation of some mod.^n^n"

new g_helpamx_setmod[LONG_STRING] = "help 1	      | for help."
new g_helpamx_setmods[LONG_STRING] = "shortModName <1 or 0> to restart or not       | Enable/Disable any mod, \
loaded or not (silent mod). "

new g_cmdsAvailables1[LONG_STRING] = "^namx_setmod help 1       | To show this help.^n\
amx_setmod disable 1   | To deactivate any active Mod.^n\
amx_votemod	| To force a votemod. "

new g_cmdsAvailables2[LONG_STRING] = "say_team nextmod	       | To see which is the next mod.^n\
say currentmod	| To see which is the current mod.^n\
say votemod	 | To try start a vote mod.^n\
say_team votemod	 | To try start a vote mod."

/**
 * Register plugin commands and load configurations.
 */
public plugin_init()
{   
	register_plugin( PLUGIN, VERSION, AUTHOR )

	register_cvar( "MultiModManager", VERSION, FCVAR_SERVER|FCVAR_SPONLY )

	register_dictionary( "mapchooser.txt" )
	register_dictionary( "multimodmanager.txt" )

	gp_mintime = 			register_cvar( "amx_mintime", "10" )
	gp_allowedvote = 		register_cvar( "amx_multimod_voteallowed", "1" )
	gp_endmapvote = 		register_cvar( "amx_multimod_endmapvote", "0" )

	register_clcmd( "amx_votemod", "start_vote", ADMIN_MAP, "Vote for the next mod" )
	register_clcmd( "say currentmod", "user_currentmod" )
	register_clcmd( "say_team currentmod", "user_currentmod" )
	register_clcmd( "say votemod", "user_votemod" )
	register_clcmd( "say_team votemod", "user_votemod" )

	register_concmd( "amx_setmod", "receiveCommand", ADMIN_CFG, g_helpamx_setmod )
	register_concmd( "amx_setmods", "receiveCommandSilent", ADMIN_IMMUNITY, g_helpamx_setmods )
	register_menucmd( register_menuid( g_menuname ), 2047, "player_vote" )

	g_sayText = get_user_msgid("SayText");
	g_coloredmenus = colored_menus()
	g_totalVotes = 0
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

	get_configsdir( g_configFolder, charsmax(g_configFolder) )

	formatex( g_masterPlugin_filePath, charsmax(g_masterPlugin_filePath), "%s/plugins-multi.ini", g_configFolder )
	formatex( g_masterConfig_filePath, charsmax(g_masterConfig_filePath), "%s/multimod/multimod.cfg", g_configFolder )

	formatex( g_currentMod_id_filePath, charsmax(g_currentMod_id_filePath), "%s/multimod/currentmod_id.ini", g_configFolder ) 
	formatex( g_currentMod_shortName_filePath, charsmax(g_currentMod_shortName_filePath), "%s/multimod/currentmod_shortname.ini", g_configFolder )

	formatex( g_multimod_votingList_filePath, charsmax(g_multimod_votingList_filePath), "%s/multimod/voting_list.ini", g_configFolder )
	formatex( g_voteFinished_filePath, charsmax(g_voteFinished_filePath), "%s/multimod/votefinished.cfg", g_configFolder )

	switchMapManager()
	retrievesCurrentMod_atLocalInfo()
	loadCurrentMod()
	unloadLastActiveMod()

	if( get_pcvar_num( gp_endmapvote ) )
	{
		set_task(15.0, "check_task", TASK_VOTEMOD, "", 0, "b")
	}
}

/**
 * After the first time the server loads, this function execute the late configuration file 
 *   used to restaure the last active mod cvars changed and the last mapcycle used. 
 * 
 * This function stills detect when the mod is changed due specific maps configurations 
 *   files like, "./configs/maps/plugins-zm.ini", that actives the zombie plague mod. 
 * 
 * In order to this works, you must configure the file "./configs/maps/prefix_zm.cfg"
 *   with the command:
 *          localinfo amx_lastmod zp50Money
 *
 * For the zombie plague mod, short mod name. 
 */
public unloadLastActiveMod()
{
	new lastMod_shortName	[ SHORT_STRING ]
	new lastMod_Mapcycle	[ SHORT_STRING ]
	new lateConfig_filePath		[LONG_STRING]

	get_localinfo( "amx_lastmod", lastMod_shortName, charsmax( lastMod_shortName ) )
	get_localinfo( "lastmapcycle", lastMod_Mapcycle, charsmax( lastMod_Mapcycle ) )

	if( !equal( lastMod_shortName, g_currentMod_shortName ) && !g_isFirstTime_serverLoad )
	{
		lateConfig_pathCoder( lastMod_shortName, lateConfig_filePath, charsmax( lateConfig_filePath ) )

		if( file_exists( lateConfig_filePath ) )
		{   
			printMessage( 0, "Executing the deactivation mod configuration file ( %s ).", lateConfig_filePath )
			server_cmd( "exec %s", lateConfig_filePath )
		}

		server_cmd( "mapcyclefile %s", lastMod_Mapcycle )
	}
}

/**
 * Process the input command "amx_setmod OPITON1 OPITON2".
 * 
 * @param player_id - will hold the players id who started the command
 * @param level - will hold the access level of the command
 * @param cid - will hold the commands internal id 
 *
 * @ARG1 firstCommand_lineArgument the modShortName to enable 
 * @ARG2 secondCommand_lineArgument inform to start a vote map "1" or not "0" 
 */
public receiveCommand(player_id, level, cid)
{   
	//Make sure this user is an admin
	if (!cmd_access(player_id, level, cid, 3))
	{   
		return PLUGIN_HANDLED
	}
	new firstCommand_lineArgument			[ SHORT_STRING ]
	new secondCommand_lineArgument		[SHORT_STRING]

	//Get the command arguments from the console
	read_argv( 1, firstCommand_lineArgument, 		charsmax( firstCommand_lineArgument ) )
	read_argv( 2, secondCommand_lineArgument, charsmax( secondCommand_lineArgument ) )

	new isTimeToRestart 			= equal( secondCommand_lineArgument, "1" )
	g_isTimeTo_changeMapcyle = true

	if( primitiveFunctions( player_id, firstCommand_lineArgument, isTimeToRestart ) )
	{   
		if( activateMod_byShortName( firstCommand_lineArgument )  ) 
		{   
			configureModID( firstCommand_lineArgument )
			messageModActivated( firstCommand_lineArgument, isTimeToRestart, true )
		} 
		else
		{   
			printHelp( player_id )
		}
	}
	g_isTimeTo_changeMapcyle = false

	return PLUGIN_HANDLED
}

/**
 * Given a mod short name like "predator", set its plugin internal mod id. 
 * 
 * @param shortName the mod short name. 
 *
 * @return true if shortName is a valid mod, false otherwise. 
 */
public configureModID( shortName[] )
{   
	for( new mod_id_number = 3; mod_id_number <= g_modCounter; mod_id_number++ )
	{   
		if( equal( shortName, g_modShortNames[mod_id_number] ) )
		{   
			g_currentMod_id = mod_id_number
			saveCurrentModBy_id( mod_id_number )
		}
	}
}

/**
 * Check the activation of the function of disableMods and help.
 * 
 * @param firstCommand_lineArgument[] the first command line argument
 * @param secondCommand_lineArgument[] the second command line argument
 * @param player_id the player id
 *
 * @return true if was not asked for a primitive function, false otherwise.
 */
public primitiveFunctions( player_id, firstCommand_lineArgument[], isTimeToRestart )
{   
	if( equal( firstCommand_lineArgument, "disable" ) )
	{   
		disableMods()

		if( isTimeToRestart )
		{
			msgResourceActivated( "disable", isTimeToRestart, true )
		}
		return false
	}
	if( equal( firstCommand_lineArgument, "help" ) )
	{   
		printHelp( player_id )
		return false
	}
	return true
}

/**
 * Given a player id, prints to him and at server console the help about the command 
 * "amx_setmod".
 *
 * @param player_id the player id
 */
public printHelp( player_id )
{   
	new text[LONG_STRING]

	client_print( player_id, print_console , g_cmdsAvailables1 )
	client_print( player_id, print_console , g_cmdsAvailables2 )

	server_print( g_cmdsAvailables1 )
	server_print( g_cmdsAvailables2 )

	for( new i = 3; i <= g_modCounter; i++ )
	{   
		formatex( text, charsmax(text), "amx_setmod %s 1          | to use %s", g_modShortNames[i], g_modNames[i] )

		client_print( player_id, print_console , text )
		server_print( text )
	}
	client_print( player_id, print_console , "^n" )
	server_print( "^n" )
}

/**
 * Process the input command "amx_setmod OPITON1 OPITON2". 
 * Straight restarting the server, (silent mod) and changes and configures the mapcycle if 
 *   there is one
 * 
 * @param player_id - will hold the players id who started the command
 * @param level - will hold the access level of the command
 * @param cid - will hold the commands internal id 
 * 
 * @arg firstCommand_lineArgument the modShortName to enable silently
 * @arg secondCommand_lineArgument inform to restart the current map "1" or not "0" 
 */
public receiveCommandSilent( player_id, level, cid )
{   
	//Make sure this user is an admin
	if ( !cmd_access( player_id, level, cid, 3 ) )
	{   
		return PLUGIN_HANDLED
	}
	new firstCommand_lineArgument			[SHORT_STRING]
	new secondCommand_lineArgument		[SHORT_STRING]

	read_argv( 1, firstCommand_lineArgument, charsmax( firstCommand_lineArgument ) )
	read_argv( 2, secondCommand_lineArgument, charsmax( secondCommand_lineArgument ) )

	new isTimeToRestart 			= equal( secondCommand_lineArgument, "1" )
	g_isTimeTo_changeMapcyle = true

	if( equal( firstCommand_lineArgument, "disable" ) )
	{   
		disableMods()
		msgResourceActivated( "disable", isTimeToRestart, false )
	} 
	else if( activateMod_byShortName( firstCommand_lineArgument ) )
	{
		g_currentMod_id = 0 
		saveCurrentModBy_id( 2 )

		saveCurrentModBy_ShortName( firstCommand_lineArgument			 )
		messageModActivated( 				firstCommand_lineArgument, isTimeToRestart, false )
	}
	g_isTimeTo_changeMapcyle = false

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
 * Loads the 'currentmod_id.ini' and 'currentmod_shortname.ini', at ".configs/multimod" folder, 
 *    that stores the current mod actually active and the current mod was activated by 
 *    silent mode, respectively. 
 * 
 * If the mod_id stored at 'currentmod_id.ini' is:
 *     greater than 0, it is any mod saved. 
 *	    0, a silent mod is activated. 
 *     -1, the mods are disabled. 
 * 
 * When 'currentmod_id.ini' stores 0, 'currentmod_shortname.ini' defines the current mod. 
 * When 'currentmod_id.ini' stores anything that is not 0, 'currentmod_id.ini' defines the current mod. 
 */
public loadCurrentMod()
{   
	new currentModCode
	new lenghtInteger

	new currentModId_String[SHORT_STRING]
	new currentMod_shortName[SHORT_STRING]

	if( file_exists( g_currentMod_id_filePath ) ) // normal mod activation 
	{
		read_file( 			g_currentMod_id_filePath, 0, currentModId_String, charsmax(currentModId_String), lenghtInteger )
		currentModCode 	= str_to_num( currentModId_String )
	} 
	else
	{
		currentModCode = -1
		write_file( g_currentMod_id_filePath,	"-1" 	)
	}

	if( file_exists( g_currentMod_shortName_filePath ) ) // silent mod activation 
	{
		read_file( g_currentMod_shortName_filePath, 0, currentMod_shortName, charsmax(currentMod_shortName), lenghtInteger )
	} 
	else
	{
		currentModCode = -1
		write_file( g_currentMod_shortName_filePath, "" )
	} 

	build_first_mods() 
	load_votingList() 

	configureMod_byModCode( currentModCode, currentMod_shortName ) 
}

/**
 * Configure the current mod action after is being loaded from the file at map server start. 
 * 
 * @param currentModCode the code loaded from the current mod file. If it is: 
 *			-1, there is no mod active. 
 * 		0, the current mod was activated by silent mode.
 * 
 * @param currentMod_shortName[] the current mod short name loaded from the 
 *    current mod silent file. 
 */
public configureMod_byModCode( currentModCode, currentMod_shortName[] ) 
{
	debugMessageLog( 1,  "^n^ncurrentModCode: %d | currentMod_shortName: %s^n", currentModCode, currentMod_shortName )

	switch( currentModCode )
	{   
		case -1: 
		{   
			g_currentMod_id = 2 
			disableMods()
		}
		case 0: 
		{
			g_currentMod_id = 0 
			activateMod_byShortName( currentMod_shortName )
		}
		default: 
		{
			g_currentMod_id = currentModCode + 2 
			activateMod_byShortName( g_modShortNames[ currentModCode + 2 ] )
		}
	}
}

/**
 * Configure the current mod action after being voted the next mod. 
 * 
 * If 1, is to keep the current mod
 * If 2, is to disable the current mod. 
 * 
 * @param mostVoted_modID the mod most voted during the vote mod. 
 */
public configureMod_byModID( mostVoted_modID ) 
{
	g_currentMod_id = mostVoted_modID 

	switch( mostVoted_modID )
	{   
		case 1: 
		{

		}
		case 2: 
		{
			disableMods()
		}
		default: 
		{	
			saveCurrentModBy_id( mostVoted_modID )
			activateMod_byShortName( g_modShortNames[ mostVoted_modID ] )
		}
	}
}

/**
 * Saves the last mod activated at localinfo "amx_lastmod" and sets the localinfo 
 *   "amx_correntmod" and the global variable "g_currentMod_shortName" to the mod 
 *   short name currently activated. 
 * 
 * @param currentMod_shortName the current just activated mod short name. 
 */ 
public setCurrentMod_atLocalInfo( currentMod_shortName[] )
{
	set_localinfo( "amx_lastmod", g_currentMod_shortName )
	set_localinfo( "amx_correntmod", 	currentMod_shortName )

	copy( g_currentMod_shortName, charsmax( g_currentMod_shortName ), currentMod_shortName )
}

/**
 * Retrieves the localinfo "amx_correntmod"  as a mod short name to the global variable 
 *   "g_currentMod_shortName". 
 */ 
public retrievesCurrentMod_atLocalInfo()
{
	get_localinfo( "amx_correntmod", g_currentMod_shortName, charsmax( g_currentMod_shortName ) );
}

/**
 * Given a mod_id_number, salves it to file "currentmod_id.ini", at multimod folder.
 * 
 * @param mod_id_number the mod id. If the mod_id_number is:
 * 		greater than 2, it is any mod. 
 *			2, a silent mod activated. 
 * 		1, the mods are disabled. 
 */
saveCurrentModBy_id( mod_id_number )
{   
	new mod_idString[SHORT_STRING]

	if ( file_exists( g_currentMod_id_filePath ) )
	{   
		delete_file( g_currentMod_id_filePath )
	}

	formatex( mod_idString, charsmax(mod_idString), "%d", mod_id_number - 2 )

	write_file( g_currentMod_id_filePath, mod_idString )
}

/**
 *  Saves the current silent mod activated to file "currentmod_shortname.ini", at multimod folder.
 *
 * @param modShortName[] the mod short name. Ex: surf.
 */
public saveCurrentModBy_ShortName( modShortName[] )
{
	if( file_exists( g_currentMod_shortName_filePath ) )
	{   
		delete_file( g_currentMod_shortName_filePath )
	}
	write_file( g_currentMod_shortName_filePath, modShortName )
}

/**
 * Makes at votemod menu, display the first mod as the option: "Keep Current Mod". And at 
 * votemod menu, display the second mod as the option: "No mod - Disable Mod".
 */
public build_first_mods()
{   
	formatex( g_modNames[g_modCounter], SHORT_STRING - 1, "Silent Mod  Currently" )
	formatex( g_modShortNames[g_modCounter], SHORT_STRING - 1, "silentMod" )

	g_modCounter++

	formatex( g_modNames[g_modCounter], SHORT_STRING - 1, "Keep Current Mod" )
	formatex( g_modShortNames[g_modCounter], SHORT_STRING - 1, "keepCurrent" )

	g_modCounter++

	formatex( g_modNames[g_modCounter], SHORT_STRING - 1, "No mod - Disable Mod" )
	formatex( g_modShortNames[g_modCounter], SHORT_STRING - 1, "disableMod" )
}

/**
 * Loads the config file "multimod.ini" and all mods stored there.
 */
public load_votingList()
{   
	new currentLine								[LONG_STRING]
	new currentLine_splited					[SHORT_STRING]
	new modName									[SHORT_STRING]
	new modShortName_string				[SHORT_STRING]
	new unusedLast_string					[SHORT_STRING]

	new currentMod_filePointer = fopen( g_multimod_votingList_filePath, "rt" )

	while( !feof( currentMod_filePointer ) )
	{   
		fgets( currentMod_filePointer, currentLine, charsmax(currentLine) )
		trim( currentLine )

		// skip commentaries while reading file
		if( !currentLine[0] || currentLine[0] == ';' || ( currentLine[0] == '/' && currentLine[1] == '/' ) )
		{   
			continue
		}

		if( currentLine[0] == '[' )
		{   
			g_modCounter++

			// remove line delimiters [ and ]
			replace_all( currentLine, charsmax(currentLine), "[", "" )
			replace_all( currentLine, charsmax(currentLine), "]", "" )

			// broke the current config line, in modname (modName), modtag (modShortName_string) 
			strtok( currentLine, modName, charsmax(modName), currentLine_splited, charsmax(currentLine_splited), ':', 0 )
			strtok( currentLine_splited, modShortName_string, charsmax(modShortName_string), unusedLast_string, charsmax( unusedLast_string ), ':', 0 )

			// stores at memory the modname and the modShortName
			formatex( g_modNames[g_modCounter], SHORT_STRING - 1, "%s", modName )
			formatex( g_modShortNames[g_modCounter], SHORT_STRING - 1, "%s", modShortName_string )

			debugMessageLog( 1, "[AMX MOD Loaded] %d - %s",  g_modCounter - 2, g_modNames[g_modCounter] )

			if( g_is_debug & 2 ) 
			{   
				new mapcycle_filePath					[SHORT_STRING] 
				new config_filePath						[SHORT_STRING] 
				new plugin_filePath						[SHORT_STRING] 
				new message_filePath					[SHORT_STRING]
				new messageResource_filePath			[SHORT_STRING]
				new lateConfig_filePath				[SHORT_STRING] 

				mapcycle_pathCoder( modShortName_string, mapcycle_filePath, charsmax( mapcycle_filePath ) ) 
				config_pathCoder( modShortName_string, config_filePath, charsmax( config_filePath ) ) 
				plugin_pathCoder( modShortName_string, plugin_filePath, charsmax( plugin_filePath ) ) 
				message_pathCoder( modShortName_string, message_filePath, charsmax( message_filePath ) ) 
				messageResource_pathCoder( modShortName_string, messageResource_filePath, charsmax( messageResource_filePath ) ) 
				lateConfig_pathCoder( modShortName_string, lateConfig_filePath, charsmax( lateConfig_filePath ) )

				server_print( "[AMX MOD Loaded] %s", modShortName_string )
				server_print( "[AMX MOD Loaded] %s", mapcycle_filePath )
				server_print( "[AMX MOD Loaded] %s", plugin_filePath )
				server_print( "[AMX MOD Loaded] %s", config_filePath )
				server_print( "[AMX MOD Loaded] %s", message_filePath )
				server_print( "[AMX MOD Loaded] %s", lateConfig_filePath )
				server_print( "[AMX MOD Loaded] %s^n", messageResource_filePath )
			}
		}
	}
	fclose( currentMod_filePointer )
}

/**
 * Hard code the message recourse file location at the string parameter messageResource_filePath[]. 
 * These are the resource messages files at ".configs/multimod/" folder. executed when a 
 *   resource as disable, is activated by the command "amx_setmod". 
 * 
 * @param modShortName[] the mod short name without extension. Ex: surf
 * @param messageResource_filePath[] the message resource file path containing its file extension. Ex: mapcycles/surf.txt
 * @param stringReturnSize the messageResource_filePath[] charsmax value. 
 */
public messageResource_pathCoder( resourceName[], messageResource_filePath[], stringReturnSize )
{   
	formatex( messageResource_filePath, stringReturnSize, "%s/multimod/%s.cfg", g_configFolder, resourceName )
}

/**
 * Hard code the message file location at the string parameter message_filePath[]. 
 * These are the messages files at ".configs/multimod/msg/" folder, executed when a 
 *   mod is activated by the command "amx_setmod". 
 * 
 * @param modShortName[] the mod short name without extension. Ex: surf
 * @param message_filePath[] the message file path containing its file extension. Ex: mapcycles/surf.txt
 * @param stringReturnSize the message_filePath[] charsmax value. 
 */
public message_pathCoder( modShortName[], message_filePath[], stringReturnSize )
{   
	formatex( message_filePath, stringReturnSize, "%s/multimod/msg/%s.cfg", g_configFolder, modShortName )
}

/**
 * Hard code the plugin file location at the string parameter plugin_filePath[]. 
 * These are the mods plugins files, to be activated at ".configs/multimod/plugins/" folder. 
 * 
 * @param modShortName[] the mod short name without extension. Ex: surf
 * @param plugin_filePath[] the plugin file path containing its file extension. Ex: mapcycles/surf.txt
 * @param stringReturnSize the plugin_filePath[] charsmax value. 
 */
public plugin_pathCoder( modShortName[], plugin_filePath[], stringReturnSize)
{   
	formatex( plugin_filePath, stringReturnSize, "%s/multimod/plugins/%s.ini", g_configFolder, modShortName )
}

/**
 * Hard code the config file location at the string parameter config_filePath[]. 
 * These are the mods configuration files, to be loaded at ".configs/multimod/cfg/" folder. 
 * 
 * @param modShortName[] the mod short name without extension. Ex: surf
 * @param config_filePath[] the config file path containing its file extension. Ex: mapcycles/surf.txt
 * @param stringReturnSize the config_filePath[] charsmax value. 
 */
public config_pathCoder( modShortName[], config_filePath[], stringReturnSize)
{   
	formatex( config_filePath, stringReturnSize, "%s/multimod/cfg/%s.cfg", g_configFolder, modShortName )
}

/**
 * Hard code the late config file location at the string parameter lateConfig_filePath[]. 
 * These are the mods configuration files, to be loaded at ".configs/multimod/latecfg/" folder. 
 * These files are only executed once when the mod is deactivated. 
 * 
 * @param modShortName[] the mod short name without extension. Ex: surf
 * @param lateConfig_filePath[] the late config file path containing its file extension. Ex: mapcycles/surf.txt
 * @param stringReturnSize the lateConfig_filePath[] charsmax value. 
 */
public lateConfig_pathCoder( modShortName[], lateConfig_filePath[], stringReturnSize)
{   
	formatex( lateConfig_filePath, stringReturnSize, "%s/multimod/latecfg/%s.cfg", g_configFolder, modShortName )
}

/**
 * Hard code the mapcycle file location at the string parameter mapcycle_filePath[]. 
 * These are the mods mapcycles files at ".gamemod/mapcycles/" folder, to be used when a mod is 
 *   activated.  
 * 
 * @param modShortName[] the mod short name without extension. Ex: surf
 * @param mapcycle_filePath[] the mapcycle file path containing its file extension. Ex: mapcycles/surf.txt
 * @param stringReturnSize the mapcycle_filePath[] charsmax value. 
 */
public mapcycle_pathCoder( modShortName[], mapcycle_filePath[], stringReturnSize)
{   
	formatex( mapcycle_filePath, stringReturnSize, "mapcycles/%s.txt", modShortName )
}

/**
 * Makes the autoswitch between mapchooser and galileo_reloaded. If both are 
 *   active, prevails galileo_reloaded.
 */
public switchMapManager()
{   
	if( is_plugin_loaded( "Galileo" ) != -1 )
	{   
		g_mapManagerType = 2
	} 
	else if( find_plugin_byfile( "Nextmap Chooser" ) != -1 )
	{   
		g_mapManagerType = 1
	}
}

/**
 * Setup the map manager to work with votemod menu at Silent mode. That is, configures
 *  the compatibility with galileo_reloaded, multimod_mapchooser and daily_maps, because now 
 *  there is no mod_id_number, hence because the mod is not loaded from the mod file configs.
 * 
 * @param firstCommand_lineArgument[] the mapcycle file name with extension and path. Ex: mapcycles/surf.txt
 */
public configMapManagerSilent( firstCommand_lineArgument[] )
{   
	if( file_exists( firstCommand_lineArgument ) )
	{   
		switch( g_mapManagerType )
		{   
			case 1:
			{   
				if( callfunc_begin("plugin_init", "multimod_mapchooser.amxx" ) == 1 )
				{   
					callfunc_end()
				} 
				else
				{   
					printMessage( 0, "Error at configMapManager!! multimod_mapchooser.amxx NOT FOUND!^n" )
				}
			}
			case 2:
			{   
				new galileo_mapfile = get_cvar_pointer( "gal_vote_mapfile" )

				if( galileo_mapfile )
				{   
					set_pcvar_string( galileo_mapfile, firstCommand_lineArgument )
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
 * @param firstCommand_lineArgument[] the mapcycle file name with its extension and path. Ex: mapcycles/surf.txt
 */
public configDailyMapsSilent( firstCommand_lineArgument[] )
{
	new isFirstTime[32]

	get_localinfo( "isFirstTimeLoadMapCycle", isFirstTime, charsmax( isFirstTime ) );

	g_isFirstTime_serverLoad = str_to_num( isFirstTime )

	if( file_exists( firstCommand_lineArgument ) )
	{   
		if( g_isFirstTime_serverLoad  == 0 || g_isTimeTo_changeMapcyle )
		{
			new currentMapcycle_filePath[SHORT_STRING]

			g_isTimeTo_changeMapcyle = false

			get_cvar_string( "mapcyclefile", currentMapcycle_filePath, charsmax( currentMapcycle_filePath ) );

			set_localinfo( 			"lastmapcycle", 								currentMapcycle_filePath )
			set_localinfo(			 "isFirstTimeLoadMapCycle", 		"1" 	)
			set_pcvar_string( 			gp_mapcyclefile, 						firstCommand_lineArgument )
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
	g_currentMod_id = 2

	setCurrentMod_atLocalInfo( g_modShortNames[ g_currentMod_id ] )

	debugMessageLog( 1, "^n AT disableMods, the g_currentMod_shortName is: %s^n", g_currentMod_shortName )

	if( file_exists( g_currentMod_id_filePath ) )
	{   
		delete_file( g_currentMod_id_filePath )
	}

	if( file_exists( g_masterConfig_filePath ) )
	{   
		delete_file( g_masterConfig_filePath )
	}

	if( file_exists( g_currentMod_shortName_filePath ) )
	{   
		delete_file( g_currentMod_shortName_filePath )
	}

	if( file_exists( g_masterPlugin_filePath ) )
	{   
		delete_file( g_masterPlugin_filePath )
	}

	write_file( g_masterConfig_filePath, 					g_alertMultiMod )
	write_file( g_masterPlugin_filePath, 									g_alertMultiMod )
	write_file( g_currentMod_shortName_filePath, 		"" 							)
	write_file( g_currentMod_id_filePath,				 		"-1" 							)
}

/**
 * Actives a mod by its short name. If the the short name plugin file exists and 
 *    change the current mod to 'Keep Current Mod'. 
 * 
 * @param modShortName[] the mod short name to active. Ex: surf 
 *
 * @throws error any configuration file is missing!
 */
public activateMod_byShortName( modShortName[] )
{   
	new plugin_filePath[LONG_STRING]

	plugin_pathCoder( modShortName, plugin_filePath, charsmax( plugin_filePath ) ) 

	if( file_exists(plugin_filePath) )
	{   
		new config_filePath[LONG_STRING] 
		new mapcycle_filePath[SHORT_STRING] 

		config_pathCoder( modShortName, config_filePath, charsmax( config_filePath ) ) 
		mapcycle_pathCoder( modShortName, mapcycle_filePath, charsmax( mapcycle_filePath ) )

		if( file_exists( config_filePath ) )
		{
			copyFiles( config_filePath, g_masterConfig_filePath, g_alertMultiMod )
		}
		copyFiles( plugin_filePath, g_masterPlugin_filePath, g_alertMultiMod )

		configMapManagerSilent( mapcycle_filePath )
		configDailyMapsSilent( mapcycle_filePath )

		server_print( "[AMX MOD Loaded] Setting multimod to %s", modShortName )

		setCurrentMod_atLocalInfo( modShortName )

		return true
	}
	else
	{   
		printMessage( 0, "Error at activateMod_byShortName!! plugin_filePath: %s", plugin_filePath )
	}
	debugMessageLog( 1, "^n activateMod_byShortName, plugin_filePath: %s^n", plugin_filePath )

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
 * @param isTimeToRestart inform to restart the server 
 * @param isTimeTo_executeMessage instruct to execute the message activation file. Ex: "msg/csdm.cfg"
 */
public messageModActivated( modShortName[], isTimeToRestart, isTimeTo_executeMessage )
{   
	printMessage( 0, "^1The mod ( ^4%s^1 ) will be activated at ^4next server restart^1.", modShortName )

	if( isTimeToRestart )
	{
		new message_filePath[LONG_STRING]

		message_pathCoder( modShortName, message_filePath, charsmax( message_filePath ) ) 

		if( file_exists( message_filePath ) && isTimeTo_executeMessage )
		{
			server_cmd( "exec %s", message_filePath )
		} 
		else
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
 * @param isTimeToRestart inform to restart the server 
 * @param isTimeTo_executeMessage instruct to execute the message activation file. Ex: "msg/csdm.cfg"
 */
public msgResourceActivated( resourceName[], isTimeToRestart, isTimeTo_executeMessage )
{   
	printMessage( 0, "^1The resource ( ^4%s^1 ) will be activated at ^4next server restart^1.", resourceName )

	if( isTimeToRestart )
	{
		new messageResource_filePath[LONG_STRING]

		messageResource_pathCoder( resourceName, messageResource_filePath, charsmax( messageResource_filePath ) ) 

		if( file_exists( messageResource_filePath ) && isTimeTo_executeMessage )
		{
			server_cmd( "exec %s", messageResource_filePath )
		} 
		else
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
 * @param player_id the player id. 
 * @param message[] the text formatting rules to display. 
 * @param any the variable number of formatting parameters. 
 */
public printMessage( player_id, message[], any:... )
{   
	static formated_message[LONG_STRING] 

	vformat( formated_message, charsmax( formated_message ), message, 3 ) 

#if AMXX_VERSION_NUM < 183
	print_color( player_id, formated_message )
#else
	print_chat_color( player_id, formated_message )
#endif
	
	replace_all( formated_message, charsmax( formated_message ), "^4", "" ) 
	replace_all( formated_message, charsmax( formated_message ), "^1", "" ) 
	replace_all( formated_message, charsmax( formated_message ), "^3", "" ) 
	
	client_print( 	player_id, print_console, formated_message )
	server_print( formated_message )
}

/**
 * DeRoiD's Mapchooser print_color function:
 *   https://forums.alliedmods.net/showthread.php?t=261412
 * 
 * @param player_id the player id to display, use 0 for all players.
 * @param input the colored formatting rules
 * @param any the variable number of formatting parameters
 */
stock print_color( const player_id, const input[], any:... )
{
	new playerIndex_idsCounter = 1, players_ids[32];

	static formated_message[LONG_STRING];

	vformat(formated_message, charsmax( formated_message ), input, 3);

	if( player_id ) players_ids[0] = player_id; else get_players(players_ids, playerIndex_idsCounter, "ch");
	{
		for (new i = 0; i < playerIndex_idsCounter; i++)
		{
			if (is_user_connected(players_ids[i]))
			{
				message_begin( MSG_ONE_UNRELIABLE, g_sayText, _, players_ids[i] );
				write_byte( players_ids[i] );
				write_string( formated_message );
				message_end();
			}
		}
	}
	return PLUGIN_HANDLED;
}

/**
 * Displays a message to a specific server player show the current mod.
 * 
 * @param player_id the player id
 */
public user_currentmod(player_id)
{   
	client_print(0, print_chat, "The game current mod is: %s", g_modNames[ g_currentMod_id ] )

	return PLUGIN_HANDLED
}

/**
 * Called with "say votemod". Checks:
 *	If users can invoke voting.
 *	If its already voted.
 * 
 * @param player_id the player id
 */
public user_votemod(player_id)
{   
	if( get_pcvar_num( gp_allowedvote ) )
	{   
		client_print(0, print_chat, "%L", LANG_PLAYER, "MM_VOTEMOD", g_modNames[g_currentMod_id] )
		return PLUGIN_HANDLED
	}
	new Float:elapsedTime = get_pcvar_float(gp_timelimit) - (float(get_timeleft()) / 60.0)
	new Float:minTime
	minTime = get_pcvar_float(gp_mintime)

	if(elapsedTime < minTime)
	{   
		client_print( player_id, print_chat, "[AMX MultiMod] %L", LANG_PLAYER, "MM_PL_WAIT",
		floatround(minTime - elapsedTime, floatround_ceil) )

		return PLUGIN_HANDLED
	}
	new timeleft = get_timeleft()

	if(timeleft < 180)
	{   
		client_print( player_id, print_chat, "You can't start a vote mod while the timeleft is %d seconds",
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
 * @param player_id the player id to display the menu.
 * @param menu_current_page the number of the current menu page to draw the menu.
 */
public display_votemod_menu( player_id, menu_current_page )
{   
	if( menu_current_page < 0 )
	{   
		return
	}

	new menu_body[1024]
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
				sizeof( menu_body ) - current_write_position , "%d. %s^n", for_index + 1,
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
					sizeof( menu_body ) - current_write_position, "^n0. Back" )
		} else
		{   
			current_write_position += formatex( menu_body[current_write_position],
					sizeof( menu_body ) - current_write_position, "^n9. More...^n0. Back" )
		}
	} else
	{   
		if( g_menu_total_pages != menu_current_page + 1 )
		{   
			current_write_position += formatex( menu_body[current_write_position],
					sizeof( menu_body ) - current_write_position, "^n9. More...^n" )
		}
	}

	if( g_is_debug )
	{   
		new debug_player_name[64]

		get_user_name( player_id, debug_player_name, 63 )

		server_print( "Player: %s^nMenu body %s ^nMenu name: %s ^nMenu valid keys: %i", 
				debug_player_name, menu_body, g_menuname, menu_valid_keys )

		show_menu( player_id, menu_valid_keys, menu_body, 5, g_menuname )
	} 
	else
	{   
		show_menu( player_id, menu_valid_keys, menu_body, 25, g_menuname )
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
 * @param player_id the player id
 * @param key the player pressed/option key.
 */
public player_vote( player_id, key )
{   
	debugMessageLog( 4, "Key before switch: %d", key )

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
	debugMessageLog( 4, "Key after switch: %d", key )

	if( key == 9 )
	{   
		if( g_menuPosition[ player_id ] + 1 != g_menu_total_pages )
		{   
			display_votemod_menu( player_id, ++g_menuPosition[ player_id ] )
		} else
		{   
			display_votemod_menu( player_id, g_menuPosition[ player_id ] )
		}
	} else
	{   
		if( key == 0 )
		{   
			if( g_menuPosition[ player_id ] != 0 )
			{   
				display_votemod_menu( player_id, --g_menuPosition[ player_id ] )
			} else
			{   
				display_votemod_menu( player_id, g_menuPosition[ player_id ] )
			}
		} else
		{   
			new mod_vote_id = get_mod_vote_id( g_menuPosition[player_id], key )

			if( mod_vote_id <= g_modCounter && get_pcvar_num( gp_voteanswers) )
			{   
				new player_name				[SHORT_STRING]

				get_user_name( player_id, player_name, charsmax( player_name ) )

				printMessage( 0, "%L", LANG_PLAYER, "X_CHOSE_X", player_name, g_modNames[ mod_vote_id ] )

				g_votemodcount[ mod_vote_id ]++
			} 
			else
			{   
				display_votemod_menu( player_id, g_menuPosition[ player_id ] )
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
	new mostVoted_modID = 1

	for( new a = 0; a <= g_modCounter; a++ )
	{   
		if( g_votemodcount[mostVoted_modID] < g_votemodcount[a] )
		{   
			mostVoted_modID = a
		}
		g_totalVotes = g_totalVotes + g_votemodcount[a]
	}
	displayVoteResults( mostVoted_modID, g_totalVotes )
}

/**
 * Calculates the minimum votes required and print to server users the mod voting results.
 * 
 * @param mostVoted_modID the most voted mod id.
 * @param g_totalVotes the number total of votes.
 */
public displayVoteResults( mostVoted_modID, g_totalVotes )
{   
	new result_message[ LONG_STRING ]

	new playerMin = playersPlaying( 0.3 )

	if( g_totalVotes > playerMin )
	{   
		g_isTimeTo_changeMapcyle = true 

		configureMod_byModID( mostVoted_modID )

		formatex( result_message, charsmax(result_message), "%L", LANG_PLAYER, "MM_VOTEMOD",
				g_modNames[ mostVoted_modID ])

		server_cmd( "exec %s", g_voteFinished_filePath )
	} 
	else
	{   
		new result_message[LONG_STRING]
		formatex( result_message, charsmax(result_message), "The vote did not reached the required minimum! \
		The next mod remains: %s", g_modNames[ g_currentMod_id ])
	}
	g_totalVotes = 0

	printMessage( 0, result_message )

	server_print( "Total Mod Votes: %d  | Player Min: %d  | Most Voted: %s", g_totalVotes, playerMin, g_modNames[ mostVoted_modID ] )
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

/**
 * Write debug messages to server's console accordantly to the global variable g_is_debug. 
 * 
 * @param mode the debug level to be used: 
 *   		(00000) 0 disable all debug. 
 *   		(00001) 1 displays basic debug messages. 
 *   		(00010) 2 displays each mod loaded. 
 *   		(00010) 4 displays the keys pressed during voting. 
 * 
 * @param message[] the text formatting rules to display. If omitted displays ""
 * @param any the variable number of formatting parameters. 
 */
public debugMessageLog( mode, message[], any:... )
{   
	if( mode & g_is_debug )
	{
		static formated_message[LONG_STRING] 

		vformat( formated_message, charsmax( formated_message ), message, 3 ) 

		server_print( "%s", formated_message 		)
		client_print( 		0, print_console, 			"%s", formated_message )
	}
}
