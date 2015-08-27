<?php
/* 
------------------
Language: ENGLISH
------------------
*/

$lang = array();

$lang[ 'HEADER' ] = <<<EOD
    <meta name="description"content="The Addons Multi-Mod is an add-in for Counter-Strike and Counter-Strike Condition Zero games. The Addons Multi-Mod contains numerous mods and comes standard configured for maximum performance and server control.">
    <title>Addons Multi-Mod - For Counter-Strike - CS </title>
    <meta itemprop="name" content="Addons Multi-Mod - For Counter-Strike - CS ">
    <meta itemprop="description"content="The Addons Multi-Mod is an add-in for Counter-Strike and Counter-Strike Condition Zero games. The Addons Multi-Mod contains numerous mods and comes standard configured for maximum performance and server control.">
EOD;

$lang[ 'MENU_PRINCIPAL' ] = <<<EOD
<div id="barraDoIdioma" style="text-align:left; margin: 0 auto; ">Language/Idioma: 
    <a href="default.php?lang=en">English</a>
    - - 
    <a href="default.php?lang=pt">Português</a>
</div>
<div id="conteinerDoLogo" align="center" style="display: table; min-height:150px; max-width: 1360px; width:98%; text-align: center; margin: 0 auto; align-content:center; ">
    <a href="http://www.addons.zz.mu/">
    <span id="logoPrincipal"></span></a>
</div>
EOD;

if( $_SESSION[ 'screen_width' ] < 800 )
{
    $lang[ 'MENU_PRINCIPAL' ] = $lang[ 'MENU_PRINCIPAL' ] . <<<EOD
<div class="tableContainer " style="border:double; margin: 0 auto; border-color:#232323; ">
    <div id="tableRow">
        <div class="tableColumn " style="border-right:double; border-bottom:double; padding:5px; border-color:#232323; ">
            <a href="http://www.addons.zz.mu/"><b>Home Page</b></a>
        </div>
        <div class="tableColumn " style="border-bottom:double; padding:5px; border-color:#232323; ">
            <a href="https://github.com/Addonszz/AddonsMultiMod/issues"><b>Forum - Questions - Request Features</b></a>
        </div>
    </div>
    <div id="tableRow">
        <div class="tableColumn " style="border-right:double; border-color:#232323; padding:5px; ">
            <a href="#installation"><b>Installation</b></a>
        </div>
        <div class="tableColumn " style="border-right:double; border-color:#232323; padding:5px; ">
            <a href="https://github.com/Addonszz/AddonsMultiMod/releases"><b>Downloads</b></a>
        </div>
        <div class="tableColumn " align="center" style="padding:5px; border-color:#232323; ">
            <a href="https://github.com/Addonszz"><b>Contact</b></a>
        </div>
    </div>
</div>
EOD;
} else
{
    $lang[ 'MENU_PRINCIPAL' ] = $lang[ 'MENU_PRINCIPAL' ] . <<<EOD
<div class="tableContainer " style="border:double; margin: 0 auto; border-color:#232323;">
    <div id="tableRow">
        <div class="tableColumn " style="border-right:double; padding:5px; border-color:#232323;">
            <a href="http://www.addons.zz.mu/"><b>Home Page</b></a>
        </div>
        <div class="tableColumn " style="border-right:double; padding:5px; border-color:#232323;">
            <a href="https://github.com/Addonszz/AddonsMultiMod/issues"><b>Forum - Questions - Request Features</b></a>
        </div>
        <div class="tableColumn " style="border-right:double; padding:5px; border-color:#232323;">
            <a href="#installation"><b>Installation</b></a>
        </div>
        <div class="tableColumn " style="border-right:double; padding:5px; border-color:#232323;">
            <a href="https://github.com/Addonszz/AddonsMultiMod/releases"><b>Downloads</b></a>
        </div>
        <div class="tableColumn " style="padding:5px; border-color:#232323;">
            <a href="https://github.com/Addonszz"><b>Contact</b></a>
        </div>
    </div>
</div>
EOD;
}

$lang[ 'DESCRICAO_INICIAL' ] = <<<EOD
The Addons Multi-Mod is an add-in for &quot;Counter-Strike 1.6&quot; and &quot;Counter-Strike: Condition Zero&quot; game.
<p>
The Addons Multi-Mod contains numerous mods and comes standard configured for maximum performance and server control.</p>
EOD;

$lang[ 'PRIMEIRA_COLUNA' ] = <<<EOD
<p><span style="font-size:40px">About Addons Multi-Mod? See here:</span>
<p><a href="https://github.com/Addonszz/AddonsMultiMod">https://github.com/Addonszz/AddonsMultiMod</a></p>
</p>
<p><span style="font-size:40px">About Amx Ultra? See here:</span>
<p><a href="https://github.com/Addonszz/Amx_Ultra">https://github.com/Addonszz/Amx_Ultra</a></p>
</p>
<p>Basic information on the latest version of <strong><font color="red"><u>Addons Multi-Mod v2.0</u></font></strong>
    released on 12/08/2015: </p>
* Galileo 1.1.290 that is a feature rich map voting plugin.<br>
* In the last five minutes or be asked before a vote by the command "say votemod", creates a vote to select what will be the Mod played in próprimo round.<br>
*  Developed a multi-page votemod menu system to display until 100 mods.<br>
*  Added a currentmod.ini file to save current active mod id and load it at server start.
<p><img src="recursos/2015-08-16_14-08_Counter-Strike.jpg" width="600" ></p>
<p><img src="recursos/2015-08-16_14-08_Counter-Strike(2).jpg" width="600" ></p>
*  Changes the mapcycle, if and only if a custom mod mapcycle was created.<br>
*  Made the votemod keep the current mod if less than 30% of players voted.<br>
*  Made "Extend current map" right after choose, not to restart the game at the current map.<br>
*  Made the "currentmod.ini" store mod ids related to the mods order at "multimod.ini".<br>
*  Fixed current mod message is displaying "Next Mod: ".<br>
*  Made "Next Mod: " message display there is no actived mod, when there is not.<br>
*  When the min vote time is not reached/disabled, display e message informing that.

<p>Version of <strong><font color="red"><u>Addons Multi-Mod v1.5</u></font></strong>
    released on 12/08/2015: <br>

* Added Dragon Ball Mod v1.3<br>
* New multi-mod_core with improved server control.<br>
* Fixed daily_maps incompatibility with nextmap.<br>
* Placed multi-mod_plugin and info to its originals plugins nextmap and cmdmenus.

<p>Version of <strong><font color="red"><u>Addons Multi-Mod v1.4</u></font></strong>
    released on 10/08/2015: <br>
* Added pain_shock_free plugins that disables the slow walking when taking shots.<br>
* Added new Command Menu (h button on the game) with support:<br>
* Enabling Superheros Mod, Mod Predator, Knife Arena Mod and Ultimate Warcraft Mod.<br>
* Greater control of the server and finish the round in a tie, or the CT's or TR's winning.

<p><img src="recursos/2015-07-28_05-18_Untitled.jpg" width="362" height="424" alt=""/></p>
* Binds configured as walk-continue and fast change.<br>
* Enabling PODBot and commands Superheros Mod.<br>
* Access to the top 15, remaining time of the map and the current map.<br>
* Control of PODBots settings such as quota, time, difficulty, kill, remove, weapons mode and etc ...<br>
* Gravity Change, friendly fire, equilibrium times, times limit ...</p>

<p><img src="instalacao/2015-07-27_04-02_Counter-Strike.jpg" width="360" height="334"></p>

* Added support for linux and windows servers.<br>
* Added support for Mac OS PODBot, Linux and Windows.<br>
* Added support for Zombie Plague Mod 5.08a<br>
* Added support for Superheros Mod 1.2.1<br>
* Added support for CSDM (Death-Match) v2.1.3c<br>
* Added support for Gun-Game Mod v2.13c<br>
* Added support for Predator Mod_B2 2.1<br>
* Added support for Ultimate Warcraft Mod 3<br>
* Added support for Knife Arena Mod 1.2<br>
* Added hlds.bat file and hlds.sh to create served by command line in Windows on Linux.

<p><img src="recursos/2015-07-28_04-18_Half-Life.jpg" width="465" height="118" alt=""/></p>

*** Added all the code sources used:<br>
* A total of 450 plugins to sources.<br>
* player_wanted that pays rewards for CT's and TR's most sought after.<br>
* amx_plant_bonus giving a bonus in cash, who plant the C4.<br>
* Amx Mod X 1.82 and PODBot V3.0 metamod Build 22.<br>
* usurf that provides help and other things to surf maps.<br>
* cssurfboards adding a surfboard, (amx_createnpc).

<p><img src="recursos/2015-07-28_03-39_Counter-Strike.jpg" width="607" height="711" alt=""/></p>

* lastmanbets Plugin bets when left over 1x1.<br>
* BombSite_Radar to see where the locals to plant the bomb<br>
* bad_camper that punishes who does camper indiscriminately.<br>
* multi-mod_core, amx_exec, head_shot_announcer, grentrail, parachute, knife_duel, amx_chicken,
adv_killstreak, countdown_exec, ...<br>
* Total possible modification of available resources addons.

<p><a href="https://github.com/Addonszz/AddonsMultiMod/blob/master/gamemod_common/addons/amxmodx/configs/plugins.ini">See more info here.</a></p>
EOD;

$lang[ 'SEGUNDA_COLUNA' ] = <<<EOF
<p>It works in <a name="installation"><strong><font color="red"><u>Counter-Strike e Counter-Strike Condition Zero</u></font></strong></a>  updated.</p>

<p><span style="font-size:66px">To install it</span><br>Download the binaries 
<a href="https://github.com/Addonszz/Amx_Ultra/releases/download/v1.0/amx_ultra_plugin.zip">amx_ultra_plugin.zip</a>, 
<a href="https://github.com/Addonszz/Amx_Ultra/releases/download/v1.0/amx_ultra_resources.zip">amx_ultra_resources.zip</a>, 
<a href="https://github.com/Addonszz/AddonsMultiMod/releases/download/v4.0/addons_resources.zip">addons_resources.zip</a>, 
<a href="https://github.com/Addonszz/Amx_Ultra/archive/master.zip">Amx_Ultra-master.zip</a> 
and 
<a href="https://github.com/Addonszz/AddonsMultiMod/archive/master.zip">AddonsMultiMod-master.zip</a>, 
then just unzip and put the content of cstrike or czero and gamemod_common at your Counter-Strike's cstrike or czero folder, replacing existents files. 
The Counter-Strike's cstrike or czero folder usually is at:</p>

<p><u>C:\Program Files (x86)\Steam\SteamApps\common\Half-Life\cstrike</u></p>
<p><u>C:\Program Files (x86)\Steam\SteamApps\common\Half-Life\czero</u></p>

<p>After installing addons, just set your STEAM ID user.</p>

<p>Please update the file:</p>

<p>***users (user.ini) at folder gamemod/addons/amxmodx/configs</p>

<p>After installing addons, just set your RCON password.</p>

<p>***autoexec (autoexec.cfg) at folder gamemod. </p>

<p>Following the instructions contained therein.</p>

<p>Note 1: In order to use the commandmenu (key h in game). Every server 
administrator should have the file 
<a href="https://github.com/Addonszz/AddonsMultiMod/archive/master.zip">AddonsMultiMod-master.zip</a> 
above installed, and with the RCON password configured at his own Game Mod copy. 
An admin can too just have the folder "gamemod_common/admin" with its contents and 
the files "gamemod_common/commandmenu.txt" and "gamemod_common/autoexec.cfg",
with the RCON password configured.</p>

<p>Note 2: The PASSWORD at podbotconfig.cfg at your gamemod folder, serves 
to create waypoint using the linstenserver (play offline at new game) and add 
podbots. But who has rcon authentication can also control the podbots.</p>

<p>If you have trouble configuring the server, this is an awesome tutorial on setting an updated Steam server that works with any type of customer:</p>

<p>
    <a href="http://steamcommunity.com/sharedfiles/filedetails/?id=340974032">http://steamcommunity.com/sharedfiles/filedetails/?id=340974032</a>
</p>

<p>
    <a href="https://developer.valvesoftware.com/wiki/SteamCMD">https://developer.valvesoftware.com/wiki/SteamCMD</a>
</p>

EOF;
?>