![Addons zz](http://addons.zz.mu/Addons_zz.mu_600x107_github_painINmyASS3.png)

The Addons zz is a Addons Multi-Mod and contains numerous mods and comes 
standard configured for maximum performance and server control. 
Currently it is tested under Counter-Strike and Counter-Strike Condition Zero.

It's differential are servers adjustments create to provide a customized 
CS Server and a plugin called "multi-mod_core.sma" that in game 
(with server running) can switch between "usual game" and superheros 
1.2.0.14, predator, knife arena, ultimate warcraft mod or deactivate any 
of them. Once a mod like superheros is active, it continues active forever 
(you can reopen the server, changelevel, etc). It continues active until you
deactivate it or active some other mod like predator. And in the last five minutes 
or be asked before a vote by the command "say votemod", creates a vote to select 
what will be the Mod played in the next changelevel/restart.

####Some Features
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

[See more info here.](gamemod_common/addons/amxmodx/configs/plugins.ini)

#Install

To install it, download the binaries 
[(gamemod_common_plugins.zip)](https://github.com/Addonszz/Addons_zz/releases/download/v3.0/gamemod_common_plugins.zip), [(gamemod_common_resources.zip)](https://github.com/Addonszz/Addons_zz/releases/download/v3.0/gamemod_common_resources.zip) and the sources 
[(Source Code Zip)](https://github.com/Addonszz/Addons_zz/archive/master.zip), 
then just unzip and put the content of gamemod_common_plugins, 
gamemod_common_resources and gamemod_common at (Source Code Zip), 
at your's Game Mod's folder like cstrike and czero, replacing existents files. 
Your Game Mod folder usually is at: C:\Program Files (x86)\Steam\SteamApps\common\Half-Life\gamemod

If your game mode is cstrike or czero, copy the content of cstrike/czero at (Source Code Zip)
to your cstrike/czero game folder replacing the existents files.
And if your game is different than cstrike/czero, edit your "liblist.gam" at your gamemod folder 
as the "liblist.gam" at cstrike/czero folder at (Source Code Zip).

After installing addons, just set your STEAM ID user. Please update the file:

1. users (user.ini) at folder gamemod/addons/amxmodx/configs

After installing addons, just set your RCON password:

2. autoexec (autoexec.cfg) at folder gamemod.

Following the instructions contained therein. 

Note 1: In order to use the commandmenu (key h in game). Every server 
administrator should have the source code files (Source Code Zip) above installed, 
at his own Game Mod copy, or just the the folder "gamemod_common/admin" and
the file "gamemod_common/commandmenu.txt".

Note 2: The PASSWORD at podbotconfig.cfg at your gamemod folder, serves 
to create waypoint using the linstenserver (play offline at new game) and add 
podbots. But who has rcon authentication can also control the podbots.

If you have trouble configuring the server, this is an awesome tutorial on 
setting an updated Steam server that works with any type of customer:

http://steamcommunity.com/sharedfiles/filedetails/?id=340974032

https://developer.valvesoftware.com/wiki/SteamCMD

[Veja Aqui em Português](http://addons.zz.mu/default.php?lang=pt)
==========================
