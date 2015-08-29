Amx_Ultra - After the great success of Amx_Super... There is Amx_Ultra

Amx_Ultra is a multi-plugin and multi-mod setup for amxmodx and contains 
numerous mods and comes standard configured for maximum performance and server control. 

You will have a new plugins list beyond you own "plugins.ini" at addons/amxmodx/configs.
This will be "plugins-ultra.ini", too at addons/amxmodx/configs. It contains the descriptions
of all plugins at Amx_Ultra mod. There you can active or deactivate then as you usually do 
at your own "plugins.ini". The first 4 plugins at it are: 
```
//To get commands use "amx_multimodz help 1" for more options/information. 
amx_ultra_core.amxx			; DON'T DISABLE THIS or your configs files will not be loaded! Execute the core configuration file.
multi-mod_core.amxx			; Responsible for managing the mods, superheros, predator... Activations/Deactivations.
multi-mod_menus.amxx		; Create this menus at amxmodmenu: amx_msgmenu, amx_stmenu, amx_cmdsndmenu, amx_restartmenu
multi-mod_help.amxx			; Displays help/info message when a player enters the server.
```
And right after it, you will have a series of default active plugins with short descriptions 
sorted alphabetically and right after, active plugins with long descriptions. 
Then start the list of deactivated with short descriptions and right after the long ones. 
You surely can deactivate they all, but consider better the first 4 ones quoted above 
because of they importance. 

Like, you want to play SuperHeros, Zombie or Dragon Ball? Then active it 
by typing "amx_multimodz help 1" at console to see the command, or just type, 
"amx_votemod"  to force a mod votation, admins only command, of course, 
but players can still try "say votemod". 
Hence sure, you can create you own new mod Mod as "My Super 4 Fun Mod", 
combining some of those [plugins-ultra.ini](addons/amxmodx/configs/plugins-ultra.ini) of 
Amx_Ultra, like amx_gore_ultimate, Ultimate Quake Sounds, 
pain_shock_free, cssurfboards, bad_camper, etc... 
See at "[Multi-Mod_Core v5.0 - Configuration section](https://forums.alliedmods.net/showthread.php?t=270188#Configuration)" 
how to configure it. 
The "Multi-Mod_Core" plugin is already integrated with Amx_Ultra. 

####Requirements
1. Amx Mod X 1.8.x
2. Tested under Counter-Strike and with default settings at Counter-Strike: Condition Zero

**Cvars** See [here](addons/amxmodx/configs/amxx_ultra.cfg) 
the big list of cvars actually activated. You can too, configure 
the default cvars at "addons/amxmodx/configs/amxx_ultra.cfg"

**Commands** See [here](Commands.txt) 
the big list of commands actually activated. 
To see the new ones after active a plugin, go to its source code at 
addons/amxmodx/scripting/pluginname.sma and search for plugin_ini(). 
Or just type amx_help at console to see the commands of all plugins activated. 

#To install it

Download the binaries 
[amx_ultra_plugin.zip](https://github.com/Addonszz/Amx_Ultra/releases/download/v1.0/amx_ultra_plugin.zip), 
[amx_ultra_resources.zip](https://github.com/Addonszz/Amx_Ultra/releases/download/v1.0/amx_ultra_resources.zip) 
and 
[Amx_Ultra-master](https://github.com/Addonszz/Amx_Ultra/archive/master.zip), 
then just unzip and put the content of 
[amx_ultra_plugin.zip](https://github.com/Addonszz/Amx_Ultra/releases/download/v1.0/amx_ultra_plugin.zip), 
[amx_ultra_resources.zip](https://github.com/Addonszz/Amx_Ultra/releases/download/v1.0/amx_ultra_resources.zip) 
and the folder "Amx_Ultra-master" inside 
[Amx_Ultra-master.zip](https://github.com/Addonszz/Amx_Ultra/archive/master.zip), 
at your's Game Mod's folder like cstrike or czero, replacing existents files. 
Your Game Mod's folder is usually at: 
"C:\Program Files (x86)\Steam\SteamApps\common\Half-Life\gamemod" 

If you have trouble configuring/installing the server, install the Addons Multi-Mod below: 
https://github.com/addonszz/AddonsMultiMod

####Frequently Asked Questions

1. This Amx_Ultra is the same as [Amx_Super](https://forums.alliedmods.net/forumdisplay.php?f=111)? 
 * Yes, it is the same as our dear [Amx_Super](https://forums.alliedmods.net/forumdisplay.php?f=111), but with one difference, 
now you deactivate 100% of its functionalities/plugins. 
Hence, just let active what you want to more easily and save your server memory, 
because once its deactivated it is not loaded, instead of [Amx_Super](https://forums.alliedmods.net/forumdisplay.php?f=111), 
where your have to disable a cvar at "amx_super.cfg" config file. 

2. Why is better at small pieces than a big file with its 150.000 or 5.000 lines? 
 * Because such thing is a nightmare, then small and well related pieces are 
better to debug, that is, find bugs, add new related functionality, improve the 
code, whatever you want to. That is why the default Amx Mod X plugins 
don't come all at once big file. 

3. Why all these plugins are not too much functionality? 
 * They all are here to save your trouble of going out there taking one by one 
and installing and configuring and testing. All the ones here are already installed 
and tested. Hence, this was not developed from night to day, took years of experience 
and hours testing and debuging to finally bring it here, specially to you. 
And there is not too much functionality because there is only some actives by default. 
These plugins are located at "addons/amxmodx/configs/plugins/[plugins-ultra.ini](addons/amxmodx/configs/plugins-ultra.ini)". 
Then you choose which ones are good for you, activating or deactivating then. 

4. Where it come from and why? 
 * Come from [Addons Multi-Mod](https://github.com/addonszz/AddonsMultiMod), 
and did so because is much better develop it separated than mix everything at 
once. Hence too, because Addons Multi-Mod is another Amx Mod X setup, 
so its is incompatible with you own setup. That is, you have you own plugins 
installed at you own Amx Mod X and Addons Multi-Mod is incompatible 
because it will replace the yours and the original Amx Mod X plugins and 
your own server configurations files. 
So now, Amx_Ultra is compatible with you own Amx Mod X and server 
configuration files. And it is composed with small and well defined parts that 
realise its own function. Such approach is better because you can 
customize/personalize Amx_Ultra with you own taste easily. 

5. For who Amx_Ultra is designed and why it is here? 
 * To whoever want its functionalities, and to [Addons Multi-Mod](https://github.com/addonszz/AddonsMultiMod) use it. 
And its is here for those who don't want install the Addons Multi-Mod but 
still want its functionalities. And of course, to find tested plugins 
and to save time testing and configuring they. 

That are a lot of credits, so just read its own source code doc to heads up. But you can see 
a general credits name list [here](Credits.txt). 

[Veja Aqui em Português](http://translate.google.com.br/translate?hl=pt-BR&sl=en&u=https://github.com/addonszz/Amx_Ultra)
==========================
