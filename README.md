![Addons zz](http://addons.zz.mu/Addons_zz.mu_600x107_github_painINmyASS5.png)

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

####Some Features with its Core Plugin [Amx Ultra](https://github.com/addonszz/Amx_Ultra) installed
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
[addons_resources.zip](https://github.com/Addonszz/AddonsMultiMod/releases/download/v4.0/addons_resources.zip)
and [AddonsMultiMod-master.zip](https://github.com/Addonszz/AddonsMultiMod/archive/master.zip), 
then just unzip and put the content of 
[addons_resources.zip](https://github.com/Addonszz/AddonsMultiMod/releases/download/v4.0/addons_resources.zip) 
and gamemod_common inside [AddonsMultiMod-master.zip](https://github.com/Addonszz/AddonsMultiMod/archive/master.zip), 
at your's Game Mod's folder like cstrike or czero, replacing existents files. 
Yours Game Mod's folder usually is at: C:\Program Files (x86)\Steam\SteamApps\common\Half-Life\gamemod

If your game mode is cstrike or czero, copy the content of cstrike or czero inside the downloaded 
[AddonsMultiMod-master.zip](https://github.com/Addonszz/AddonsMultiMod/archive/master.zip)
to your cstrike or czero game folder, replacing the existents files.
And if your game is different than cstrike or czero, edit your "liblist.gam" at your 
gamemod folder as the "liblist.gam" at cstrike or czero folder inside 
[AddonsMultiMod-master.zip](https://github.com/Addonszz/AddonsMultiMod/archive/master.zip).

Observation 1: The folder website at 
[AddonsMultiMod-master.zip](https://github.com/Addonszz/AddonsMultiMod/archive/master.zip) 
is just illustrative website and does not fill any role at your installation/setup.

Observation 2: The files hlds_cstrike_27015 and hlds_czero_27015 are to create 
a command line server, due highly use less resources. It is configured at 27015 port. 
To open more then one serve at once, duplicate the file and edit inside it, changing it to 
use another port at the command +port 27015.

After installing the addons, install its Core Plugin [Amx_Ultra](https://github.com/addonszz/Amx_Ultra).

After installing the addons, too just set your STEAM ID user. Please update the file:

1. users (user.ini) at folder gamemod/addons/amxmodx/configs

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

[Veja Aqui em Português](http://translate.google.com.br/translate?hl=pt-BR&sl=en&u=https://github.com/addonszz/AddonsMultiMod)
==========================
