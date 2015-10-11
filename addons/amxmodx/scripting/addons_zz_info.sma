/******************************************************************************
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
 ******************************************************************************

[SIZE="6"][COLOR="Blue"][B]Addons zz's Multi-Mod Server v1.0-alpha1.hotfix2[/B][/COLOR][/SIZE]
[B]Release: 10.10.2015 | Last Update: 10.10.2015[/B]

[anchor]Top[/anchor][SIZE="5"][COLOR="blue"][B]Contents' Table[/B][/COLOR][/SIZE] 

[LIST]
[*][goanchor=Introduction]Introduction[/goanchor] 
[*][goanchor=Requirements]Requirements and Commands[/goanchor]
[*][goanchor=Installation]Installation[/goanchor] 
[*][goanchor=Configuration]Configuration[/goanchor] 
[*][goanchor=Profiler]Profiler Benchmark[/goanchor]
[*][goanchor=Change]Change Log[/goanchor] 
[*][goanchor=Credits]Credits[/goanchor] 
[*][goanchor=TODO]TODO[/goanchor] 
[*][goanchor=Sourcecode]Source Code and Support[/goanchor]
[*][goanchor=Downloads]Downloads[/goanchor] 
[/LIST]
The "Addons zz's Multi-Mod Server" is my [B]multi-mod server configuration[/B] for amxmodx and contains 
numerous mods and comes standard configured for maximum performance and server control. 

This is a Alpha version. This Alpha software can be unstable, see [goanchor=TODO]TODO[/goanchor] section for more information. 
As [B]Alpha software[/B] may not contain all of the features that are planned for the final version, see [goanchor=TODO]TODO[/goanchor] 
section for features that are [B]planned[/B] for the final version. 

[IMG]http://addons.zz.mu/recursos/2015-10-11_01-43_CommandMenuNew.jpg[/IMG]
[URL="http://www.gametracker.com/search/?search_by=server_variable&search_by2=MultiModServer&query=&loc=_all&sort=&order="] 
[SIZE=3][B][COLOR=DarkGreen]Click here to see all servers using this configuration.[/COLOR][/B][/SIZE][/URL] 

********************** [anchor]Introduction[/anchor][B][SIZE="5"][COLOR="blue"]Introduction[/COLOR][/SIZE][/B] [goanchor=Top]Go Top[/goanchor]  *******************************
You will have a new plugins list beyond you own "[B]plugins.ini[/B]" at "[COLOR="Blue"]yourgamemod/addons/amxmodx/[/COLOR][B]configs[/B]". 
This will be "[URL="https://github.com/addonszz/Multi-Mod_Server/blob/master/addons/amxmodx/configs/plugins-ultra.ini"]plugins-ultra.ini[/URL]", too at "[COLOR="Blue"]yourgamemod/addons/amxmodx/[/COLOR][B]configs[/B]". It contains the descriptions 
of all plugins at this Multi-Mod_Server. There you can active or deactivate then as you usually do 
at your own "[B]plugins.ini[/B]. 

This Multi-Mod_Server comes with the following Mods [B]installed[/B] and configured: 
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
********************** [anchor]Requirements[/anchor][SIZE="5"][COLOR="Blue"][B]Requirements and Commands[/B][/COLOR][/SIZE] [goanchor=Top]Go Top[/goanchor]  ******
[B]Amx Mod X 1.8.2[/B] 
Tested under [B]Counter-Strike[/B] and Counter-Strike: [B]Condition Zero[/B] 

[B]Cvars[/B]
You can see and configure the [B]default cvars[/B] at "[COLOR="Blue"]yougamemod/addons/amxmodx/[B]configs/[/B][/COLOR][URL="https://github.com/addonszz/Multi-Mod_Server/blob/master/addons/amxmodx/configs/amxx_ultra.cfg"]amxx_ultra.cfg[/URL]" 
file.

[B]Commands[/B]
See [URL="https://github.com/addonszz/Multi-Mod_Server/blob/master/Commands.txt"]here[/URL] the big list of commands actually activated. To see the new ones after active a plugin, just type 
"[B]amx_help[/B]"/"[B]amxx cvars[/B]" at server's console, to see the commands and cvars of all plugins activated. 

If you enter at a new map, like "[B]zm_*[/B]" maps for zombie plague mod, the Zombie Mod is activated automatically. 
If you was using some other mod, it [B]automatically deactivate[/B] when you are at "[B]zm_*[/B]" maps. When you leave 
the "[B]zm_*[/B]" map, the Zombie Mod is deactivated automatically, and you last mod is activated automatically, 
if there was [B]an active[/B] mod before you enter at the "[B]zm_*[/B]" map. 

The same happens to "[B]catch_*[/B]" and "[B]surf_*[/B]" maps. If want to disable that feature, rename the folder 
"[COLOR="Blue"]yourgamemod/addons/amxmodx/configs/[/COLOR][B]maps[/B]" to [B]"maps_old"[/B]. If you want to enable that feature again, 
rename back the [B]"maps_old"[/B] folder. 

[B]Example[/B] of "[B]amx_setmod help 1[/B]":
[QUOTE]
amx_setmod help 1	   | To show this help.
amx_setmod disable 1   | To deactivate any active Mod.
amx_votemod	 | To force a votemod.
say nextmod	  | To see which is the next mod.
say_team nextmod			   | To see which is the next mod.
say currentmod  | To see which is the current mod.
say votemod	  | To try start a vote mod.
say_team votemod		 | To try start a vote mod.
amx_setmod csdm 1		  | to use CS-DM (DeathMatch)
amx_setmod catch 1		  | to use Catch Mod
amx_setmod dragon 1		  | to use Dragon Ball Mod
amx_setmod gungame 1		  | to use Gun Game Mod
amx_setmod hiden 1		  | to use Hide N Seek Mod
amx_setmod jctf 1		  | to use Just Capture The Flag
amx_setmod knife 1		  | to use Knife Arena Mod
amx_setmod predator 1		  | to use Predator Mod_b2
amx_setmod shero 1		  | to use Super Heros
amx_setmod surf 1		  | to use Surf Mod
amx_setmod warcraft 1		  | to use Warcraft Ultimate Mod 3
amx_setmod zp50Money 1		  | to use Zombie Money Mod
amx_setmod zp50Ammo 1		  | to use Zombie Pack Ammo Mod
[/QUOTE]
******************************** [anchor]Installation[/anchor][B][SIZE="5"][COLOR="Blue"]Installation[/COLOR][/SIZE][/B] [goanchor=Top]Go Top[/goanchor]  **********************
[B]1.[/B] Download the files "[B]Multi-Mod_Server-master.zip[/B]" and "[B]Multi-Mod_Server_resources.zip[/B]" at 
[goanchor=Downloads]Downloads[/goanchor] section. 

[B]2.[/B] Then take the contents at the folder "[B]Multi-Mod_Server-master[/B]" inside "[B]Multi-Mod_Server-master.zip[/B]" 
and the contents at "[B]Multi-Mod_Server_resources.zip[/B]" to your gamemod folder, replacing the existents 
files.

[B]3.[/B] Go to [COLOR="Blue"]yourgamemod/addons/amxmodx/[/COLOR][B]scripting/[/B] and compile all files and take the [B]compiled files[/B] 
at the folder [COLOR="Blue"]yourgamemod/addons/amxmodx/[/COLOR][B]scripting/compiled/[/B] to your plugins folder at 
[COLOR="Blue"]yourgamemod/addons/amxmodx/[/COLOR][B]plugins/[/B].
[B]Note:[/B] To compile all files at your [B]scripting/[/B] folder, just run "[B]compile.exe[/B]" (windows) or [B]compile.sh[/B] 
(linux/mac).

[anchor]Configuration[/anchor][B]4.[/B] [SIZE="4"]Edit[/SIZE] the "[URL="https://github.com/addonszz/Multi-Mod_Server/blob/master/addons/amxmodx/configs/plugins-ultra.ini"]plugins-ultra.ini[/URL]" file at [COLOR="Blue"]yourgamemod/addons/amxmodx/[/COLOR][B]configs/[/B] folder, to your own taste. 

[B]5.[/B] If you want, [SIZE="4"][COLOR="red"]learn how to configure[/COLOR][/SIZE] your [URL="https://forums.alliedmods.net/showthread.php?t=273020#Configuration"]own mods here[/URL].

******************************** [anchor]Profiler[/anchor][B] Profiler Benchmark [/B] *****************************************
[goanchor=TODO]TODO[/goanchor] 

******************************** [anchor]Change[/anchor][B][SIZE="5"][COLOR="blue"]Change Log[/COLOR][/SIZE][/B] [goanchor=Top]Go Top[/goanchor] ***********************
[QUOTE]
v1.0-alpha1
 * Initial alpha release. 
v1.0-alpha1.hotfix2
 * Fixed misssing include at addons_zz_info.sma
[/QUOTE]

******************************** [anchor]TODO[/anchor][B][SIZE="5"][COLOR="blue"]TODO[/COLOR][/SIZE][/B] [goanchor=Top]Go Top[/goanchor] *********************************
[QUOTE]
 * Compile a good map pack and good mapcycles for each mods, weeks days and to default one. 
 * Realise server benchmarks/profiler against a default AMXX Default install. 
 * Find plugins which are leaking server's and client's performance and ping. 
 * Remove, fix or substitute plugins bad coded which are leaking server's and client's performance and ping.
 * Install deathrun, jailbreak mods and fix superheros mod crashing czero server's due 512 GoldSrc models limit. 
 * Install hideNseek mod recommended complementary plugins as blockmarker. 
[/QUOTE] 

******************************** [anchor]Credits[/anchor][B][SIZE="5"][COLOR="blue"]Credits[/COLOR][/SIZE][/B] [goanchor=Top]Go Top[/goanchor] *******************************
These mods and plugins was originally written by hundreds and hundreds of people 
all around the world. Now, after lot work from everybody, it is easy to install and use them. 
Hence, that are a lot of credits, so just read its own source code doc to heads up. 

******************************** [anchor]Sourcecode[/anchor][SIZE="5"][COLOR="blue"][B]Source Code and Support[/B][/COLOR][/SIZE] [goanchor=Top]Go Top[/goanchor] ***
This source code is available on [B]GitHub[/B]. 
[URL]https://github.com/addonszz/Multi-Mod_Server[/URL]

For any problems with this plugin visit [B][URL="https://forums.alliedmods.net/showthread.php?t=273018"]this own page[/URL][/B] or:
[url]https://github.com/Addonszz/Multi-Mod_Server/issues[/url]
for support. 

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
[*]Paste here [COLOR="red"][B]*only*[/B][/COLOR] the CVARs that contain "[COLOR="SeaGreen"][B]plugin_name.amxx[/B][/COLOR]" in the last column 
from the [B]amxx cvars[/B] command. They will be grouped together.
[/LIST]
[/QUOTE]

***************************************************************************************	
Testing server
[URL="http://cache.www.gametracker.com/server_info/jacks.noip.me:27015/"][IMG]http://cache.www.gametracker.com/server_info/jacks.noip.me:27015/b_560_95_1.png[/IMG][/URL]

[anchor]Downloads[/anchor][SIZE="6"][COLOR="Blue"][B]Downloads[/B][/COLOR][/SIZE] [goanchor=Top]Go Top[/goanchor]

[URL="https://github.com/Addonszz/Multi-Mod_Server/releases/download/v1.0-alpha1/Multi-Mod_Server_resources.zip"]Multi-Mod_Server_resources.zip[/URL] (131.49 MB)

 */
#include <amxmodx>
#include <amxmisc>

#define PLUGIN "Addons zz Info"
#define VERSION "1.0"
#define AUTHOR "Addons zz"

#define LONG_STRING 256

new g_configFolder[ LONG_STRING ]

/*
 * Called just after server activation.
 * 
 * Good place to initialize most of the plugin, such as registering
 * cvars, commands or forwards, creating data structures for later use, or
 * generating and loading other required configurations.
 */
public plugin_init()
{   
	register_plugin( PLUGIN, VERSION, AUTHOR ) 

	register_dictionary( "multimodhelp.txt" ) 
	register_cvar("MultiModServer", VERSION, FCVAR_SERVER|FCVAR_SPONLY) 
}

/*
 * Called when all plugins went through plugin_init().
 * 
 * When this forward is called, most plugins should have registered their
 * cvars and commands already.
 */
public plugin_cfg()
{
	get_configsdir(g_configFolder, charsmax(g_configFolder))

	server_cmd( "exec %s/amxx_ultra.cfg", g_configFolder )
}

public plugin_precache()
{   
	precache_sound( "ambience/ratchant.wav" );
	precache_sound( "misc/snore.wav" );
}

public client_putinserver( id )
{   
	if ( is_user_bot( id ) )
	{   
		return
	}

	set_task( 50.1, "dispInfo", id )
}

public dispInfo( id )
{   
	client_print( id, print_chat, "%L", id, "TYPE_ADDONS_CONTATO" )
}

public client_disconnect( id )
{   
	remove_task (id)
}
