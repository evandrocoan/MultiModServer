![Addons zz](http://addons.zz.mu/Addons_zz.mu_600x107_github_painINmyASS5.png)

The Addons zz's Multi-Mod Server contains numerous mods and comes 
standard configured for maximum performance and server control.
Currently it is tested under Counter-Strike and Counter-Strike Condition Zero.

It's differential are servers adjustments create to provide a customized 
CS Server and a plugin called "multimod_manager.sma" that in game 
(with server running) can switch between "usual game" and superheros 
1.2.0.14, predator, knife arena, ultimate warcraft mod or deactivate any 
of them. Once a mod like superheros is active, it continues active forever 
(you can reopen the server, changelevel, etc). It continues active until you
deactivate it or active some other mod like predator. And in the last five minutes 
or be asked before a vote by the command "say votemod", creates a vote to select 
what will be the Mod played in the next changelevel/restart.

####Some Features with its Core Plugin [Multi-Mod_Plugin](https://github.com/addonszz/Multi-Mod_Plugin) installed
- Support for: 
- linux and windows servers.
- Mac OS PODBot, Linux and Windows.
- pain_shock_free that turn off original player's slowdown on bullet hit.
- Galileo 1.1.290 that is a feature rich map voting plugin.
- Gun-Game Mod v2.13c
- Superheros Mod 1.2.1
- CSDM (Death-Match) v2.1.3c
- Predator Mod_B2 2.1
- Ultimate Warcraft Mod 3
- Knife Arena Mod 1.2
- Dragon Ball Mod v1.3
- Zombie Mod 5.08a with new game modes.
- player_wanted that pays rewards for CT's and TR's most sought after.
- amx_plant_bonus giving a bonus in cash, who plant the C4.
- Amx Mod X 1.82 and PODBot V3.0 metamod Build 22.
- usurf that provides help and other things to surf maps.
- cssurfboards adding a surfboard, (amx_createnpc).
- lastmanbets bets plugin when left over 1x1.
- BombSite_Radar to see where the locals to plant the bomb
- bad_camper that punishes who does camper indiscriminately.
- multi-mod_core, amx_exec, head_shot_announcer, grentrail, parachute, 
knife_duel, amx_chicken, adv_killstreak, countdown_exec, ... 

[See more info here.](https://github.com/addonszz/Amx_Ultra/blob/master/addons/amxmodx/configs/plugins-ultra.ini)

#To install it

Download the binaries 
[server_resources.zip](https://github.com/Addonszz/Multi-Mod_Server/releases/download/v4.0/server_resources.zip)
and [Multi-Mod_Server-master.zip](https://github.com/Addonszz/Multi-Mod_Server/archive/master.zip), 
then just unzip and put the content of 
[server_resources.zip](https://github.com/Addonszz/Multi-Mod_Server/releases/download/v4.0/server_resources.zip) 
and gamemod_common inside [Multi-Mod_Server-master.zip](https://github.com/Addonszz/Multi-Mod_Server/archive/master.zip), 
at your's Game Mod's folder like cstrike or czero, replacing existents files. 
Your Game Mod's folder usually is at: C:\Program Files (x86)\Steam\SteamApps\common\Half-Life\gamemod

If your game mode is cstrike or czero, copy the content of cstrike or czero inside the downloaded 
[Multi-Mod_Server-master.zip](https://github.com/Addonszz/Multi-Mod_Server/archive/master.zip)
to your cstrike or czero game folder, replacing the existents files.
And if your game is different than cstrike or czero, edit your "liblist.gam" at your 
gamemod folder as the "liblist.gam" at cstrike or czero folder inside 
[Multi-Mod_Server-master.zip](https://github.com/Addonszz/Multi-Mod_Server/archive/master.zip).

Observation 1: The folder website at 
[Multi-Mod_Server-master.zip](https://github.com/Addonszz/Multi-Mod_Server/archive/master.zip) 
is just illustrative website and does not fill any role at your installation/setup.

Observation 2: The files hlds_cstrike_27015 and hlds_czero_27015 are to create 
a command line server, due highly use less resources. It is configured at 27015 port. 
To open more then one serve at once, duplicate the file and edit inside it, changing it to 
use another port at the command +port 27015.

After installing the addons, install its Core Plugin [Multi-Mod_Plugin](https://github.com/addonszz/Multi-Mod_Plugin).

And too, after installing the addons, just set your STEAM ID user. Please update the file:

1. users (users.ini) at folder gamemod/addons/amxmodx/configs

After installing addons, just set your RCON password:

2. autoexec (autoexec.cfg) at the folder gamemod.

Following the instructions contained therein. 

Note 1: In order to use the commandmenu (key h in game). Every server 
administrator should have the 
[AddonsMultiMod-master.zip](https://github.com/Addonszz/AddonsMultiMod/archive/master.zip) 
above installed and with the RCON password configured, at his own Game Mod copy. 
An admin can too just have the folder "gamemod_common/admin" with its contents and 
the files "gamemod_common/commandmenu.txt" and "gamemod_common/autoexec.cfg",
with the RCON password configured. 

Note 2: The PASSWORD at podbotconfig.cfg at your gamemod folder, serves 
to create waypoint using the linstenserver (play offline at new game) and add 
podbots. But who has rcon authentication can also control the podbots.

If you have trouble configuring the server, this below is an awesome tutorial on 
setting an updated Steam server that works with any type of customer 
using SteamCMD:

http://steamcommunity.com/sharedfiles/filedetails/?id=340974032

https://developer.valvesoftware.com/wiki/SteamCMD

### [Veja Aqui em Português](http://translate.google.com.br/translate?hl=pt-BR&sl=en&u=https://github.com/addonszz/AddonsMultiMod)


___

# Change Log

```
- All notable changes to this project will be documented in this file.
- This project adheres to [Semantic Versioning](http://semver.org/).


 * Installed the slLent semiclip plugin.

2016-02-24 - v4.0.2
	* Minor misspellings.

2015-08-30 - v4.0.1
	* Added new commandmenu options.
	* Fixed messages menu sounds and messages.

2015-08-27 - v4.0
	* Separated the Amx_Ultra plugin from the Addons Multi-Mod.

2015-08-22 - v3.0
	* Currently it is tested under Counter-Strike and Counter-Strike Condition Zero
	* Added support to control PodBot and CSBot throw commandmenu.txt
	* Log chat messages of: say, say_team, amx_say, ...

2015-08-17 - v2.0
    * Added Galileo 1.1.290 that is a feature rich map voting plugin.
    * In the last five minutes or be asked before a vote by the command "say votemod", 
	   creates a vote to select what will be the Mod played in the next changelevel/restart.
    * Developed a multi-page votemod menu system to display until 100 mods.
    * Added a currentmod.ini file to save current active mod id and load it at server start.
    * Changes the mapcycle, if and only if a custom mod mapcycle was created.
    * Made the votemod keep the current mod if less than 30% of players voted.
    * Made "Extend current map" right after choose, not to restart the game at the current map.
    * Made the "currentmod.ini" store mod ids related to the mods order at "multimod.ini".
    * Fixed current mod message is displaying "Next Mod: ".
    * Made "Next Mod: " message display there is no actived mod, when there is not.
    * When the min vote time is not reached/disabled, display e message informing that.

2015-08-12 v1.5
	* Added Dragon Ball Mod v1.3
	* New multi-mod_core with improved server control.
	* Fixed daily_maps incompatibility with nextmap.
	* Placed multi-mod_plugin and info to its originals plugins nextmap and cmdmenus.

2015-08-10 1.4
	* Added Gun-Game Mod v2.13c
	* Added CSDM (Death-Match) v2.1.3c
	* Restaured the broken restart menu.

2015-08-10 v1.3
	* Added pain_shock_free plugins that disables the floor wander when taking shots.
	* Added support for Superheros Mod 1.2.1
	* Added support for Predator Mod_B2 2.1
	* Added support for Ultimate Warcraft Mod 3
	* Added support for Knife Arena Mod 1.2
	* Added the mod Zombie Mod 5.08a with new game modes:
	* Nemesis:
	   The first zombie may turn into a Nemesis, a powerful fast-moving
	   beast. His goal is to kill every human while sustaining the gunfire.
	* Survivor:
	   Everyone became a zombie except him. The survivor gets a machinegun
	   with unlimited ammo and has to stop the never-ending army of undead.
	* Multiple Infection:
	   The round starts with many humans infected, so the remaining players
	   will have to act quickly in order to control the situation.
	* Swarm Mode:
	   Half of the players turn into zombies, the rest become immune and
	   cannot be infected. It's a battle to death.
	* Plague Mode: [bonus]
	   A full armed Survivor and his soldiers are to face Nemesis and
	   his zombie minions. The future of the world is in their hands.

2015-07-27 v1.2
	* Added new Command Menu (h button on the game) with support:
	- Enabling Superheros Mod, Mod Predator, Knife Arena Mod and Ultimate Warcraft Mod.
	- Greater control of the server and finish the round in a tie, or the CT's or TR's winning.
	- Binds configured as walk-continue and fast change.
	- Enabling PODBot and commands Superheros Mod.
	- Access to the top 15, remaining time of the map and the current map.
	- Control of PODBots settings such as quota, time, difficulty, kill, remove, weapons mode and etc ...
	- Gravity Change, friendly fire, equilibrium times, times limit ...
	- Added support for linux and windows servers.
	- Added support for Mac OS PODBot and Linux.
	* Added hlds.bat file and hlds.sh to create served by command line in Windows on Linux.
	* Added all the code sources used:
	- A total of 397 plugins to sources.
	- player_wanted that pays rewards for CT's and TR's most sought after.
	- amx_plant_bonus giving a bonus in cash, who plant the C4.
	- Amx Mod X 1.82 and PODBot V3.0 metamod Build 22.
	- usurf that provides help and other things to surf maps.
	- cssurfboards adding a surfboard, (amx_createnpc).
	- lastmanbets Plugin bets when left over 1x1.
	- BombSite_Radar to see where the locals to plant the bomb
	- bad_camper that punishes who does camper indiscriminately.
	- multi-mod_core, amx_exec, head_shot_announcer, grentrail, parachute, knife_duel, 
	  amx_chicken, adv_killstreak, countdown_exec, ... 

2015-07-09
	* Hlds.bat: Created a file that creates a server throw command line. That is
     useful because a command line server usually is 50% more efficient in the use
     procesador.
```


