/********************************************************************************
*  AMX Mod X script.
*
*   AMX Super (amx_super.sma)
*   Copyright (C) 2006-2009 Bmann_420
*
*   This program is free software; you can redistribute it and/or
*   modify it under the terms of the GNU General Public License
*   as published by the Free Software Foundation; either version 2
*   of the License, or (at your option) any later version.
*
*   This program is distributed in the hope that it will be useful,
*   but WITHOUT ANY WARRANTY; without even the implied warranty of
*   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
*   GNU General Public License for more details.
*
*   You should have received a copy of the GNU General Public License
*   along with this program; if not, write to the Free Software
*   Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
*
*   In addition, as a special exception, the author gives permission to
*   link the code of this program with the Half-Life Game Engine ("HL
*   Engine") and Modified Game Libraries ("MODs") developed by Valve,
*   L.L.C ("Valve"). You must obey the GNU General Public License in all
*   respects for all of the code used other than the HL Engine and MODs
*   from Valve. If you modify this file, you may extend this exception
*   to your version of the file, but you are not obligated to do so. If
*   you do not wish to do so, delete this exception statement from your
*   version.
*
*********************************************************************************
*
*   AMXX Super All-In-One Commands v4.1
*   Last Update: 9/26/2008
*   Plugin Count: 46
*
*   by Bmann_420
*   Link: http://forums.alliedmods.net/forumdisplay.php?f=111
*
*
*********************************************************************************
*
*   +| Plugins |+
* -) ADMIN HEAL v0.9.3 by f117bomb, revised by JTP10181 -- Gives health to players.
* -) ADMIN ARMOR v1.0 by JTP10181 -- Gives armor to players.
* -) ADMIN REVIVE II v0.1 by SniperBeamer, revised by Bo0m! -- Revives dead players.
* -) ADMIN NOCLIP v1.0 by Bo0m! -- Gives players noclip.
* -) ADMIN GODMODE v1.0 by Bo0m! -- Give players godmode.
* -) ADMIN TELEPORT v0.9.3 by f117bomb, revised by JTP10181-- Teleport to a certain spot x y z
* -) ADMIN STACK v0.9.3 by f117bomb -- Stacks all players on someone's head.
* -) ADMIN ALLTALK v1.0 by BigBaller -- Sets alltalk.
* -) ADMIN GRAVITY v0.2 by JustinHoMi -- Sets gravity.
* -) ADMIN BURY v0.9.3 by f117bomb, revised by Bo0m! -- Buries players in the ground.
* -) ADMIN DISARM v1.1 by mike_cao, revised by Bo0m! -- Strips players of their weapons.
* -) ADMIN UBER SLAP v0.9.3 by BarMan (Skullz.NET) -- Slaps players through the air until they have 1 health (and probably die from a fall).
* -) ADMIN SLAY 2 v0.9.3 by f117bomb, revised by JTP10181 -- Like slay, only with special effects!
* -) ADMIN ROCKET v1.3 by f117bomb, revised by JTP10181 -- Turns players into rockets!
* -) ADMIN MONEY v1.0 by XxAvalanchexX with additions from Bo0m! -- Gives (or takes) money from players.
* -) ADMIN FIRE v1.0.0 by f117bomb -- Sets players on fire!
* -) ADMIN WEAPON III Build 6.7 by SniperBeamer\Girthesniper\Meatwad, revised by Bo0m!, menu by Sid 6.7-- Gives players weapons.
* -) ADMIN EXEC 2 v0.3 by v3x -- Executes commands on players.
* -) ADMIN STATUS by Zor -- Shows detailed player information in a MOTD window.
* -) ADMIN SERVER PASSWORD v1.0 by Sparky911 -- Sets a server password.
* -) ADMIN QUIT v1.0 by Bo0m! -- Forces players to close their game.
* -) ADMIN GAG v1.8.3 by EKS -- Gags players from speaking or using the voicecomm.
* -) ADMIN FLASH v1.0 by AssKicR, rewritten by Bo0m! -- Flashbangs players.
* -) ADMIN SERVER SHUTDOWN/RESTART 2.2 by Hawk552 -- Shuts down or Restarts the Server
* -) ADMIN TEAM LOCK v1.3 by Bmann_420, revised by Doombringer/Deviance -- Allows teams to be locked
* -) ADMIN TRANSFER v1.0 by Deviance -- Transfer players to diff teams, swap teams, and swap players
* -) ADMIN AMMO v1.0 by V3x, revised by Doombringer/Deviance -- Give/Take Unlimited Ammo
* -) ADMIN CHECK v1.15 by OneEyed -- Type /admin to see what admins are in the server
* -) ADMIN MAP EXTEND v1.1 by JSauce -- amx_extend the current map
* -) ADMIN LISTEN v2.3 by Psychoguard, rewritten by Maxim and ported by Oj@eKiLLzZz deb/urandom
* -) ADMIN VOCOM v1.3 by toazron1 Revised by X-olent
* -) ADMIN DRUG v1.0 by X-olent
* -) ADMIN SPEED vv1.0 by X-olent (Turbo)
* -) ADMIN BAD AIM 1.3 by Twistedeuphoria

* -) CHANGE TO SPEC AND BACK v1.0 Origional code by Regalis, Revised by Exolent
* -) ENTER/LEAVE MESSAGES v1.0 by by [Kindzhon] China Revised by Bmann_420 and X-olent
* -) DAMAGE DONE v0.4 by Manip, revised by JTP10181 and Vittu -- Shows how much damage you did to enemies by your crosshair.
* -) DEAD CHAT v2.1 by SuicideDog -- Talk to the other team via voicecomm while dead.
* -) LOADING SOUNDS v1.0 by [OSA]Odin/White Panther -- Plays music as players connect.
* -) SPECTATOR BUG FIX v1.0 by ]FUSION[ Gray Death -- Fixes the bug when ducking and being killed.
* -) "SHOWNDEAD" SCOREBOARD FIX v0.9.4 by EJ/Vantage/Mouse -- Fixes connecting players from showing up on a team.
* -) FIX ECHO SOUNDS v1.0 by Throstur -- Fixes echo sounds on some maps.
* -) AFK BOMB TRANSFER v1.4 by VEN, revised by Doombringer/Deviance-- Transfers the Bomb to another player if AFK
* -) C4 TIMER v1.1 by Cheat_Suit
* -) STATS MARQUEE v1.2 by Travo
* -) SPAWN PROTECTION v7.1 by Peli Revised for Glow On/Off by KaszpiR Some code change by Bmann_420
* -) AFK Manager by VEN Update by Bmann_420
*
*   +| 47 Plugins Total |+
*
*********************************************************************************
*
* Big Thanks To:
*
* (Author)
* Bmann_420
*
* (Fakemeta Conversion)
* Twilight Suzuka
*
* (Plugin Support/Main References)
* Bo0m!, Deviance, X-olent, Yami
* BigBaller, Iceman, JTP10181, Connorr
* f117bomb, XxAvalanchexX, VEN, Sether
* and all the fine users of this plugin.
*
*********************************************************************************
* Changelog
* v4.1.1
* Corrected some exceptions and added SpawnProtection countdown,
*	and freeze time alignment support to amx_super 4.1 Nospeed.
*
*********************************************************************************
*
* For any problems with this plugin visit
* http://forums.alliedmods.net/forumdisplay.php?f=111
* for support.
*
*********************************************************************************
*/


// Includes
#include <amxmodx>
#include <amxmisc>
#include <cstrike>
#include <csx>
#include <fakemeta>
#include <hamsandwich>

// Plugin Info
new const PLUGIN[]  = "AMX Super"
new const VERSION[] = "4.1.1 Nospeed"
new const AUTHOR[]  = "Bmann_420"


stock fm_set_user_godmode(index, godmode = 0) {
	set_pev(index, pev_takedamage, godmode == 1 ? DAMAGE_NO : DAMAGE_AIM)

	return 1
}

stock fm_set_user_armor(index, armor) {
	set_pev(index, pev_armorvalue, float(armor))

	return 1
}

stock fm_set_user_health(index, health) {
	health > 0 ? set_pev(index, pev_health, float(health)) : dllfunc(DLLFunc_ClientKill, index)

	return 1
}

stock fm_set_user_origin(index, /* const */ origin[3]) {
	new Float:orig[3]
	IVecFVec(origin, orig)

	return fm_entity_set_origin(index, orig)
}

stock fm_set_user_maxspeed(index, Float:speed = -1.0) {
	engfunc(EngFunc_SetClientMaxspeed, index, speed)
	set_pev(index, pev_maxspeed, speed)

	return 1
}

stock Float:fm_get_user_maxspeed(index) {
	new Float:speed
	pev(index, pev_maxspeed, speed)

	return speed
}

stock fm_set_user_gravity(index, Float:gravity = 1.0) {
	set_pev(index, pev_gravity, gravity)

	return 1
}

stock Float:fm_get_user_gravity(index) {
	new Float:gravity
	pev(index, pev_gravity, gravity)

	return gravity
}

stock fm_set_user_noclip(index, noclip = 0) {
	set_pev(index, pev_movetype, noclip == 1 ? MOVETYPE_NOCLIP : MOVETYPE_WALK)

	return 1
}

stock fm_set_user_frags(index, frags) {
	set_pev(index, pev_frags, float(frags))

	return 1
}

#define fm_get_user_noclip(%1) (pev(%1, pev_movetype) == MOVETYPE_NOCLIP)
/* stock fm_get_user_noclip(index)
	return (pev(index, pev_movetype) == MOVETYPE_NOCLIP) */


#define fm_create_entity(%1) engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, %1))
#define fm_remove_entity(%1) engfunc(EngFunc_RemoveEntity, %1)
#define fm_fake_touch(%1,%2) dllfunc(DLLFunc_Touch, %1, %2)


stock fm_entity_set_origin(index, const Float:origin[3]) {
	new Float:mins[3], Float:maxs[3]
	pev(index, pev_mins, mins)
	pev(index, pev_maxs, maxs)
	engfunc(EngFunc_SetSize, index, mins, maxs)

	return engfunc(EngFunc_SetOrigin, index, origin)
}

stock fm_give_item(index, const item[])
{
	if (!equal(item, "weapon_", 7) && !equal(item, "ammo_", 5) && !equal(item, "item_", 5) && !equal(item, "tf_weapon_", 10))
		return 0

	new ent = fm_create_entity(item)
	if (!pev_valid(ent))
		return 0

	new Float:origin[3]
	pev(index, pev_origin, origin)
	set_pev(ent, pev_origin, origin)
	set_pev(ent, pev_spawnflags, pev(ent, pev_spawnflags) | SF_NORESPAWN)
	dllfunc(DLLFunc_Spawn, ent)

	new save = pev(ent, pev_solid)
	dllfunc(DLLFunc_Touch, ent, index)
	if (pev(ent, pev_solid) != save)
		return ent

	engfunc(EngFunc_RemoveEntity, ent)

	return -1
}

stock fm_give_item_x(index, const item[], x)
	for(new i; i <= x; i++) fm_give_item(index, item)

stock fm_set_rendering(entity, fx = kRenderFxNone, r = 255, g = 255, b = 255, render = kRenderNormal, amount = 16)
{
	new Float:RenderColor[3]
	RenderColor[0] = float(r)
	RenderColor[1] = float(g)
	RenderColor[2] = float(b)

	set_pev(entity, pev_renderfx, fx)
	set_pev(entity, pev_rendercolor, RenderColor)
	set_pev(entity, pev_rendermode, render)
	set_pev(entity, pev_renderamt, float(amount))

	return 1
}

#define fm_DispatchSpawn(%1) dllfunc(DLLFunc_Spawn, %1)

#define fm_find_ent_by_class(%1,%2) engfunc(EngFunc_FindEntityByString, %1, "classname", %2)

#define SPEAK_NORMAL	0
#define SPEAK_MUTED	1
#define SPEAK_ALL	2
#define SPEAK_LISTENALL	4

new fm_plinfo[33]

public FM_SetListen(iReceiver, iSender, bListen)
{
	if( (fm_plinfo[iSender] & SPEAK_MUTED) != 0)
	{
		engfunc(EngFunc_SetClientListening, iReceiver, iSender, 0)

		forward_return(FMV_CELL,0)
		return FMRES_SUPERCEDE;
	}

	if( (fm_plinfo[iSender] & SPEAK_ALL) != 0)
	{
		engfunc(EngFunc_SetClientListening, iReceiver, iSender, 1)

		forward_return(FMV_CELL,1)
		return FMRES_SUPERCEDE;
	}

	if( (fm_plinfo[iReceiver] & SPEAK_LISTENALL) != 0)
	{
		engfunc(EngFunc_SetClientListening, iReceiver, iSender, 1)

		forward_return(FMV_CELL,1)
		return FMRES_SUPERCEDE;
	}

	return FMRES_IGNORED
}

stock fm_set_speak(id,tmp) (fm_plinfo[id] = tmp)
stock fm_get_speak(id) return fm_plinfo[id]

enum {
	GET_TEAM_TARGET_ISALL,
	GET_TEAM_TARGET_ISTEAMCT,
	GET_TEAM_TARGET_ISTERRORIST,
}

enum {
	GET_TEAM_TARGET_SKIPNOBODY,
	GET_TEAM_TARET_SKIPBOTS,
	GET_TEAM_TARGET_SKIPDEADPEOPLE
}

stock get_team_target(arg[],players[32],&pnum,skipMode=GET_TEAM_TARGET_SKIPNOBODY){
	//Modular Team Targeting code by Sid 6.7
	new whoTeam
	new cmdflags[4]
	switch(skipMode){
		case GET_TEAM_TARET_SKIPBOTS: cmdflags = "ce"
		case GET_TEAM_TARGET_SKIPNOBODY: cmdflags = "e"
		case GET_TEAM_TARGET_SKIPDEADPEOPLE: cmdflags = "ae"
	}
	if(equali(arg[1],"ALL",strlen(arg[1]))) 	{
		switch(skipMode){
			case GET_TEAM_TARET_SKIPBOTS: cmdflags = "c"
			case GET_TEAM_TARGET_SKIPNOBODY: cmdflags = ""
			case GET_TEAM_TARGET_SKIPDEADPEOPLE: cmdflags = "a"
		}
		whoTeam = GET_TEAM_TARGET_ISALL
		get_players(players,pnum,cmdflags)
	}

	if(equali(arg[1],"TERRORIST",strlen(arg[1]))) {
		whoTeam = GET_TEAM_TARGET_ISTERRORIST
		get_players(players,pnum,cmdflags,"TERRORIST")
	}
	if(equali(arg[1],"CT")	|| equali(arg[1],"C") 	|| equali(arg[1],"COUNTER")) {
		whoTeam = GET_TEAM_TARGET_ISTEAMCT
		get_players(players,pnum,cmdflags,"CT")
	}
	return whoTeam
}


/*
///
///// You may edit some of these Defines (not all)
///
*/
#define TASK_SPAWN_PROTECTION_ID 1337
#define ADMIN_CHECK ADMIN_KICK  // For Admin Check
#define LOADINGSOUNDS 14	// Number of loading songs
#define VoiceCommMute 1		// 0 = Disabled | 1 = Voicecomm muteing enabled.
#define BlockNameChange 1	// 0 = Disabled | 1 = Block namechange on gagged clients
#define LogAdminActions 1	// 0 = Disabled | 1 = Admin actions will be logged
#define DefaultGagTime 600.0	// The std gag time if no other time was entered. ( this is 10 min ), Remember the value MUST contain a .0
#define PlaySound 1		// 0 = Disabled | 1 = Play a sound to gagged clients when their trying to talk
#define GagReason 0		// 0 = Disabled | 1 = Gagged clients can see why there where gagged when they try to talk
#define AllowOtherPlugin2Interface 1
#define DAMAGE_RECIEVED		// Comment out this define to show only damage done, otherwise this will show damage recieved also.
#define TE 0			///////////////////
#define CT 1			//	Team Locker
#define AUTO 4			//	   Teams
#define SPEC 5			///////////////////
#define EXTENDMAX 9		// Maximum number of times a map may be extended by anyone.
#define EXTENDTIME 15		// Maximum amount of time any map can be extended at once.
#define MAX_MAPS 32		// Change this if you have more than 32 maps in mapcycle.
#define MAX_SPRITES	2	// C4 Plugin max Sprites
#define	FL_ONGROUND (1<<9)	// C4 Timer
#define MaxPlayers 32
#define LASTWEAPON_CT -1
#define LASTWEAPON_T -2
#define LASTWEAPON_ALL -3

new const g_timersprite[MAX_SPRITES][] = { "bombticking", "bombticking1" }

// Loading Sounds List
new soundlist[LOADINGSOUNDS][] = {"Half-Life01","Half-Life02","Half-Life03","Half-Life04","Half-Life06","Half-Life08","Half-Life10","Half-Life11","Half-Life12","Half-Life13","Half-Life14","Half-Life15","Half-Life16","Half-Life17"}

static const COLOR[] = "^x04"  //ADMIN CHECK chat color - green

new const SpecName[] = "UNASSIGNED"

//defines for speak flags
#define SPEAK_MUTED2	0
#define SPEAK_NORMAL2	1
#define SPEAK_ALL	2
#define SPEAK_ADMIN	5

#define MAX_PLAYERS 32

new const g_teamname[2][] = {"TERRORIST", "CT"}

// chat reasons
new const g_spec_kick_chat[] = "AMX_SUPER_AFK_SPEC_KICK_CHAT"
new const g_afk_kick_chat[]  = "AMX_SUPER_AFK_KICK_CHAT"
new const g_afktospec_chat[] = "AMX_SUPER_AFK_TO_SPEC_CHAT"

//C4 Bomb message
new const g_message[] = "Detonation time intiallized....."

// AFK check interval (seconds)
#define AFK_CHECK_INTERVAL 5

/*
///
///// End of the Defines
///
*/

// Team Locker Team Names
new const Teamnames[6][] = {
	"Terrorists",
	"Counter-Terrorists",
	"",
	"",
	"Auto",
	"Spectator"
}

enum
{
	SHUTDOWN = 0,
	RESTART
}

//Glow Information
new g_iColors[30][3] = {
	{255, 0, 0},
	{255, 190, 190},
	{165, 0, 0},
	{255, 100, 100},
	{0, 0, 255},
	{0, 0, 136},
	{95, 200, 255},
	{0, 150, 255},
	{0, 255, 0},
	{180, 255, 175},
	{0, 155, 0},
	{150, 63, 0},
	{205, 123, 64},
	{255, 255, 255},
	{255, 255, 0},
	{189, 182, 0},
	{255, 255, 109},
	{255, 150, 0},
	{255, 190, 90},
	{222, 110, 0},
	{243, 138, 255},
	{255, 0, 255},
	{150, 0, 150},
	{100, 0, 100},
	{200, 0, 0},
	{220, 220, 0},
	{192, 192, 192},
	{190, 100, 10},
	{114, 114, 114},
	{0, 0, 0}
}

new g_sColors[30][] = {
	"red",
	"pink",
	"darkred",
	"lightred",
	"blue",
	"darkblue",
	"lightblue",
	"aqua",
	"green",
	"lightgreen",
	"darkgreen",
	"brown",
	"lightbrown",
	"white",
	"yellow",
	"darkyellow",
	"lightyellow",
	"orange",
	"lightorange",
	"darkorange",
	"lightpurple",
	"purple",
	"darkpurple",
	"violet",
	"maroon",
	"gold",
	"silver",
	"bronze",
	"grey",
	"off"
}

new ammo_9mm[] = "ammo_9mm"
new ammo_45acp[] = "ammo_45acp"
new ammo_357sig[] = "ammo_357sig"
new ammo_50ae[] = "ammo_50ae"
new ammo_57mm[] = "ammo_57mm"
new ammo_buckshot[] = "ammo_buckshot"
new ammo_556nato[] = "ammo_556nato"
new ammo_762nato[] = "ammo_762nato"
new ammo_338magnum[] = "ammo_338magnum"
new ammo_556natobox[] = "ammo_556natobox"

new AMX_SUPER_GAG_CONNECTED[] = "AMX_SUPER_GAG_CONNECTED"
new AMX_SUPER_NO_PLAYERS[] = "AMX_SUPER_NO_PLAYERS"
new AMX_SUPER_TEAM_IMMUNITY[] = "AMX_SUPER_TEAM_IMMUNITY"
new AMX_SUPER_TEAM_INVALID[] = "AMX_SUPER_TEAM_INVALID"
new AMX_SUPER_AMOUNT_GREATER[] = "AMX_SUPER_AMOUNT_GREATER"


new weapons[33][] = {
	"weapon_usp",
	"weapon_glock18",
	"weapon_deagle",
	"weapon_p228",
	"weapon_elite",
	"weapon_fiveseven",
	"weapon_m3",
	"weapon_xm1014",
	"weapon_tmp",
	"weapon_mac10",
	"weapon_mp5navy",
	"weapon_p90",
	"weapon_ump45",
	"weapon_famas",
	"weapon_galil",
	"weapon_ak47",
	"weapon_m4a1",
	"weapon_sg552",
	"weapon_aug",
	"weapon_scout",
	"weapon_sg550",
	"weapon_awp",
	"weapon_g3sg1",
	"weapon_m249",
	"weapon_hegrenade",
	"weapon_smokegrenade",
	"weapon_flashbang",
	"weapon_shield",
	"weapon_c4",
	"weapon_knife",
	"item_kevlar",
	"item_assaultsuit",
	"item_thighpack"
}

enum {
	WEAPON_USP,
	WEAPON_GLOCK18,
	WEAPON_DEAGLE,
	WEAPON_P228,
	WEAPON_ELITE,
	WEAPON_FIVESEVEN,
	WEAPON_M3,
	WEAPON_XM1014,
	WEAPON_TMP,
	WEAPON_MAC10,
	WEAPON_MP5NAVY,
	WEAPON_P90,
	WEAPON_UMP45,
	WEAPON_FAMAS,
	WEAPON_GALIL,
	WEAPON_AK47,
	WEAPON_M4A1,
	WEAPON_SG552,
	WEAPON_AUG,
	WEAPON_SCOUT,
	WEAPON_SG550,
	WEAPON_AWP,
	WEAPON_G3SG1,
	WEAPON_M249,
	WEAPON_HEGRENADE,
	WEAPON_SMOKEGRENADE,
	WEAPON_FLASHBANG,
	WEAPON_SHIELD,
	WEAPON_C4,
	WEAPON_KNIFE,
	ITEM_KEVLAR,
	ITEM_ASSAULTSUIT,
	ITEM_THIGHPACK
}

//Reverse Lookup Weapons Table
new const RLWT[33] = {
	12,11,14,13,16,15,
	21,22,31,32,33,34,35,
	40,41,42,43,44,45,
	46,47,48,49,
	51,83,85,84,87,91,
	1,81,82,86
}


// Bools
new bool:g_restart_attempt[33]
new bool:g_freezetime = true
new bool:g_spawn
new bool:g_planting
new bool:HasPermGod[33]
new bool:HasPermNoclip[33]
new bool:HasPermGlow[33]
new bool:g_speed[33]
new bool:blockjoining[6]
new bool:unammo[33]
new bool:badaim[33] = false
new bool:autoban[33] = false
new bool:count[33][33]
new bool:g_connected[MAX_PLAYERS + 1]

// PCvars
new revivemsg, deadchat, bulletdamage, loadsong, soundfixon, allowsoundfix, leavemessage, autobantimed, autobanall
new flashsound, transferfm_DispatchSpawn, transfertime, allowcatchfire, cvar_showteam, adminlisten, leavemessage_enable
new cvar_flash, cvar_sprite, cvar_msg, statsm, cvPlrAmt, cvFullTime, cvTimeBetw, cvVertLoc, ba_followimmunity
new statsmarquee, sv_sp, sv_sptime, sv_spmessage, sv_spshellthick, sv_spglow, entermessage, joinleave_message, admincheck
new mp_c4timer, allow_spectators, amx_show_activity, hostname, mp_freezetime, mp_timelimit, sv_contact, sv_alltalk, sv_gravity, sv_password
new amx_reservation, immune_access, immune_time, max_afktime, afkcheck_allow, allow_public_spec, immune_access_listen

// Variables
new gmsgDamage
new gmsg_SetFOV
new mflash, smoke, blueflare2, white, light
new gmsg_TeamInfo
new gMsgScreenFade
new g_MsgSync
new g_carrier
new g_pos[33][3]
new g_time[33]
new gReloadTime[33]
new g_maxplayers
new maxplayers
new gmsgSayText
new user_limit = 0
new g_gagged[33]
new g_wasgagged[33][32]
new g_gagflags[33]
new g_c4timer
//new g_msg_showtimer
new g_msg_roundtime
new g_msg_scenario
new g_name[33][32]
new g_playerspk[33]
new g_admin[33]
new g_glow[33][4]
new players[32]
new pCount
new g_voicemask[33]
new g_origin[MAX_PLAYERS + 1][3]
new g_afktime[MAX_PLAYERS + 1]
new g_specgametime[MAX_PLAYERS + 1]
new g_bShuttingDown
new g_iMode

#if defined DAMAGE_RECIEVED
	new g_MsgSync2
#endif

new g_GagPlayers[MaxPlayers+1]	// Used to check if a player is gagged
#if GagReason == 1
new gs_GagReason[MaxPlayers+1][48]
#endif

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	register_cvar("amx_super", VERSION, FCVAR_SERVER|FCVAR_EXTDLL|FCVAR_UNLOGGED|FCVAR_SPONLY)
	register_dictionary("amx_super.txt")

	register_forward(FM_Voice_SetClientListening,"FM_SetListen");

	//Client Commands
	register_clcmd("say /gravity","check_gravity")
	register_clcmd("say /alltalk","check_alltalk")
	register_clcmd("say /fixsound","cmdStopsound")
	register_clcmd("say /spec", "cmd_spec")
	register_clcmd("say /unspec", "cmd_unspec")
	register_clcmd("say /admins", "show_admins")
	register_clcmd("say /admin", "show_admins")

	register_clcmd("say","block_gagged")
	register_clcmd("say_team","block_gagged")
	register_clcmd("jointeam", "join_team")
	register_clcmd("fullupdate","fullupdate")

	//Admin Commands
	register_concmd("amx_heal","admin_heal",ADMIN_LEVEL_A,"<nick, #userid, authid or @team> <HP to give>")
	register_concmd("amx_armor","admin_armor",ADMIN_LEVEL_A,"<nick, #userid, authid or @team> <armor to give>")
	register_concmd("amx_teleport","admin_teleport",ADMIN_LEVEL_A,"<nick, #userid or authid> [x] [y] [z]")
	register_concmd("amx_userorigin","admin_userorigin",ADMIN_LEVEL_A,"<nick, #userid or authid")
	register_concmd("amx_stack","admin_stack",ADMIN_LEVEL_A,"<nick, #userid or authid> [0|1|2]")
	register_concmd("amx_alltalk","admin_alltalk",ADMIN_LEVEL_A,"[1 = ON | 0 = OFF]")
	register_concmd("amx_gravity","admin_gravity",ADMIN_LEVEL_A,"<gravity #>")
	register_concmd("amx_unammo", "admin_unammo", ADMIN_LEVEL_A, "<nick, #userid or @team> [0|1] - 0=OFF 1=ON")
	register_concmd("amx_extend","admin_extend",ADMIN_LEVEL_A,"<added time to extend> : ex. 5, if you want to extend it five more minutes.")
	register_concmd("amx_gag","admin_gag",ADMIN_LEVEL_A,"<nick, #userid or authid> <a|b|c> <time> - Flags: a = Normal Chat | b = Team Chat | c = Voicecomm")
	register_concmd("amx_ungag","admin_ungag",ADMIN_LEVEL_A,"<nick, #userid or authid>")
	register_concmd("amx_bury","admin_bury",ADMIN_LEVEL_B,"<nick, #userid, authid or @team>")
	register_concmd("amx_unbury","admin_unbury",ADMIN_LEVEL_B,"<nick, #userid, authid or @team>")
	register_concmd("amx_disarm","admin_disarm",ADMIN_LEVEL_B,"<nick, #userid, authid or @team>")
	register_concmd("amx_slay2","admin_slay",ADMIN_LEVEL_B,"<nick, #userid, authid or @team> [1-Lightning|2-Blood|3-Explode]")
	register_concmd("amx_rocket","admin_rocket",ADMIN_LEVEL_B,"<nick, #userid, authid or @team>")
	register_concmd("amx_fire","admin_fire",ADMIN_LEVEL_B,"<nick, #userid or authid or @team>")
	register_concmd("amx_uberslap","admin_slap",ADMIN_LEVEL_B,"<nick, #userid or authid>")
	register_concmd("amx_flash","admin_flash",ADMIN_LEVEL_B,"<nick, #userid, authid or @team> - Flashes player(s)")
	register_clcmd("+adminvoice", "vocomStart")  //Custom Level B (Change in admin Voice Section)
	register_clcmd("-adminvoice", "vocomStop")   //Custom Level B (Change in admin Voice Section)
	register_concmd("amx_weapon","admin_weapon",ADMIN_LEVEL_C,"<nick, #userid, authid or @team> <weapon #>")
	register_concmd("amx_revive","admin_revive",ADMIN_LEVEL_C,"<nick, #userid, authid or @team>")
	register_concmd("amx_godmode","admin_godmode",ADMIN_LEVEL_C,"<nick, #userid or @team> [0|1|2] - 0=OFF 1=ON 2=ON + ON EACH ROUND")
	register_concmd("amx_noclip","admin_noclip",ADMIN_LEVEL_C,"<nick, #userid, authid or @team> [0|1|2] - 0=OFF 1=ON 2=ON + ON EACH ROUND")
	register_concmd("amx_drug","cmd_drug",ADMIN_LEVEL_C,"<@all, @team, nick, #userid, authid or @team>")
	//register_concmd("amx_speed","cmd_speed",ADMIN_LEVEL_C,"<nick, #userid, authid or @team> [0|1] -- gives/takes turbo running")
	register_concmd("amx_givemoney","admin_givemoney",ADMIN_LEVEL_C," <nick, #userid, authid or @team> <amount> - gives specified player money")
	register_concmd("amx_takemoney","admin_takemoney",ADMIN_LEVEL_C," <nick, #userid or authid> <amount> - takes specified player money")
	register_concmd("amx_glow", "cmd_glow", ADMIN_LEVEL_D, "<nick, #userid, authid, or @team/@all> <color> (or) <rrr> <ggg> <bbb> <aaa> -- lasts 1 round")
	register_concmd("amx_glow2", "cmd_glow", ADMIN_LEVEL_D, "<nick, #userid, authid, or @team/@all> <color> (or)  <rrr> <ggg> <bbb> <aaa> -- lasts forever")
	register_concmd("amx_glowcolors", "cmd_glowcolors", ADMIN_LEVEL_D, "shows a list of colors for amx_glow and amx_glow2")
	register_concmd("amx_badaim","bad_aim",ADMIN_LEVEL_D,"<player> <On/off or length of time: 1|0|time> <Save?: 1|0>: Turn on/off bad aim on a player.")
	register_concmd("amx_transfer", "cmd_transfer", ADMIN_LEVEL_D,"- <name> <CT/T/Spec> Transfers that player to the specified team")
	register_concmd("amx_team", "cmd_transfer", ADMIN_LEVEL_D,"- <name> <CT/T/Spec> Transfers that player to the specified team")
	register_concmd("amx_swap", "cmd_swap", ADMIN_LEVEL_D,"- <name 1> <name 2> Swaps two players with eachother")
	register_concmd("amx_teamswap", "cmd_teamswap", ADMIN_LEVEL_D,"- Swaps two teams with eachother")
	register_concmd("amx_lock", "admin_lock", ADMIN_LEVEL_D,"- <CT/T/Auto/Spec> - Locks selected team")
	register_concmd("amx_unlock", "admin_unlock", ADMIN_LEVEL_D,"- <CT/T/Auto/Spec> - Unlocks selected team")
	register_concmd("amx_exec","admin_exec",ADMIN_BAN,"<nick or @team> <command>")
	register_concmd("amx_restart","fnShutDown",ADMIN_BAN,"<seconds (1-20)> - restarts the server in seconds")
	register_concmd("amx_pass", "admin_pass", ADMIN_PASSWORD, "<server password> - Sets the server password")
	register_concmd("amx_nopass", "admin_nopass", ADMIN_PASSWORD, "- Removes the server password")
	register_concmd("amx_quit","admin_quit",ADMIN_LEVEL_E,"<nick, #userid, authid or @team>")
	register_concmd("amx_shutdown","fnShutDown",ADMIN_RCON,"<seconds (1-20)> - shuts down the server in seconds")

	//Server Commands
	register_srvcmd("soundfix","fRemove")

	//Events
	register_event("DeathMsg","event_death","a")
	register_event("ResetHUD","event_hud_reset","be")
	register_event("CurWeapon", "changeWeapon", "be", "1=1")
	register_event("Damage", "on_damage", "b", "2!0", "3=0", "4!0")
	register_event("TextMsg", "event_restart_attempt", "a", "2=#Game_will_restart_in")
	register_event("ResetHUD", "sp_on", "be")
	register_event("SayText","catch_say","b")
	register_event("DeathMsg","death_hook","a")
	register_event("VoiceMask","voice_hook","b")

	//Cvars
	revivemsg = register_cvar("amx_revivemsg","1");
	deadchat = register_cvar("amx_deadchat","1");
	bulletdamage = register_cvar("bullet_damage","1");
	loadsong = register_cvar("amx_loadsong","1");
	soundfixon = register_cvar("amx_soundfix","1");
	allowsoundfix = register_cvar("amx_soundfix_pallow","1");
	flashsound = register_cvar("amx_flashsound","1");
	transferfm_DispatchSpawn = register_cvar("afk_bombtransfer_fm_DispatchSpawn", "7");
	transfertime = register_cvar("afk_bombtransfer_time", "15");
	allowcatchfire = register_cvar("allow_catchfire", "1");
	cvar_showteam = register_cvar("amx_showc4timer", "3");
	cvar_flash = register_cvar("amx_showc4flash", "0");
	cvar_sprite = register_cvar("amx_showc4sprite", "1");
	cvar_msg = register_cvar("amx_showc4msg", "0");
	cvPlrAmt = register_cvar("amx_marqplayeramount","40");
	cvVertLoc = register_cvar("amx_marqvertlocation","2");
	cvFullTime = register_cvar("amx_marqfulltime","600.0");
	cvTimeBetw = register_cvar("amx_marqtimebetween","6.0");
	statsmarquee = register_cvar("stats_marquee","1");
	sv_sp = register_cvar("sv_sp", "1");
	sv_sptime = register_cvar("sv_sptime", "5");
   	sv_spmessage = register_cvar("sv_spmessage", "1");
   	sv_spshellthick = register_cvar("sv_spshellthick", "25");
   	sv_spglow = register_cvar("sv_spglow", "0");
	adminlisten = register_cvar("amx_adminlisten","1");
	leavemessage_enable = register_cvar("amx_leavemessage_enable","1");
	entermessage = register_cvar("amx_enter_message", "%name% has joined!\nEnjoy the Server!\nCurrent Ranking is %rankpos%");
	leavemessage = register_cvar("amx_leave_message", "%name% has left!\nHope to see you back sometime.");
	joinleave_message = register_cvar("amx_join_leave", "1");
	autobantimed = register_cvar("amx_autobantimed", "1");
	autobanall = register_cvar("amx_autobanall", "1");
	ba_followimmunity = register_cvar("amx_ba_follow_immunity", "1");
	admincheck = register_cvar("amx_admin_check", "1");
	immune_access = register_cvar("amx_immune_access","a");
	immune_time = register_cvar("amx_immune_time","5");
	max_afktime = register_cvar("amx_max_afktime","45");
	afkcheck_allow = register_cvar("amx_afkcheck_allow","1");
	allow_public_spec = register_cvar("allow_public_spec","1");
	immune_access_listen = register_cvar("listen_immune_access","d");

	// Execute main configuration file (amx_super.cfg)
	/*new configsDir[64]
	get_configsdir(configsDir, 63)
	server_cmd("exec %s/amx_super.cfg", configsDir) */

	// Variables Set
	maxplayers = get_maxplayers()
	gmsgSayText = get_user_msgid("SayText")
	gmsgDamage = get_user_msgid("Damage")
	gMsgScreenFade = get_user_msgid("ScreenFade")
	gmsg_TeamInfo = get_user_msgid("TeamInfo")
	gmsg_SetFOV = get_user_msgid("SetFOV")
	g_MsgSync = CreateHudSyncObj()
#if defined DAMAGE_RECIEVED
	g_MsgSync2 = CreateHudSyncObj()
#endif

	//Weapon III new round hook
	//register_event("RoundTime", "event_new_roundw", "bc")

	//Speed Fix
	//server_cmd("sv_maxspeed 9999999");

	//Voice Comm Admin
	register_forward(FM_Voice_SetClientListening, "fm_mute_forward")

	//C4 Timer Display
	//g_msg_showtimer	= get_user_msgid("ShowTimer")
	g_msg_roundtime	= get_user_msgid("RoundTime")
	g_msg_scenario	= get_user_msgid("Scenario")

	register_event("HLTV", "event_hltv", "a", "1=0", "2=0")
	register_logevent("logevent_plantedthebomb", 3, "2=Planted_The_Bomb")

	// Team Locker
	register_menucmd(register_menuid("Team_Select",1), (1<<0)|(1<<1)|(1<<4)|(1<<5), "team_select")

	// Fix Echo Sounds Task
	set_task(0.1,"fRemove")

	//Stats Marquee
	//set_task(15.0,"displayplr",0,"",0,"a",1);

	// Event to keep speed
	//register_event( "CurWeapon", "event_weapon", "be", "1=1" )

	//AFK Manager
	register_event("TeamInfo", "event_spectate", "a", "2=UNASSIGNED", "2=SPECTATOR")
	register_event("TeamInfo", "event_playteam", "a", "2=TERRORIST", "2=CT")
	set_task(float(AFK_CHECK_INTERVAL), "task_afk_check2", _, _, _, "b")

	// AFK Bomb Transfer Events
	register_event("WeapPickup", "event_got_bomb", "be", "1=6")
	register_event("BarTime", "event_bar_time", "be")
	register_event("TextMsg", "event_bomb_drop", "bc", "2=#Game_bomb_drop")
	register_event("TextMsg", "event_bomb_drop", "a", "2=#Bomb_Planted")
	register_event("HLTV", "event_new_round", "a", "1=0", "2=0")

	// AFK Bomb Transfer Logevents
	register_logevent("logevent_round_start", 2, "1=Round_Start")

	register_logevent( "event_roundstart", 2, "0=World triggered", "1=Round_Start" )
	register_logevent( "event_roundstart", 2, "0=World triggered", "1=Game_Commencing" )
	register_logevent( "event_roundstart", 2, "0=World triggered", "1=Restart_Round" )
	register_logevent( "event_roundend", 2, "0=World triggered", "1=Round_End" )


	// AFK Bomb Transfer Task
	set_task(1.0, "task_afk_check", _, _, _, "b") // AFK Bomb Transfer core loop
	g_maxplayers = get_maxplayers()

	// AMX MAP EXTEND
	#if defined MAPCYCLE
	new map[64], i, line = 0
	get_mapname(map,63)
  	while ( gNum < MAX_MAPS && read_file("mapcycle.txt",line++,gMap,63,i) )
	{
		if ( gMap[0] == ';' ) continue

		if (equali(gMap,map))
		{
			cyclerfile = true
			break
		}
		++gNum
	} return PLUGIN_CONTINUE
	#endif
	if (!fm_find_ent_by_class(-1, "func_bomb_target"))
		return
}

public get_immune_access_flag()
{
	new flags[24]
	get_pcvar_string(immune_access, flags, 23)

	return(read_flags(flags))
}

public get_immune_access_flag2()
{
	new flags[24]
	get_pcvar_string(immune_access_listen, flags, 23)

	return(read_flags(flags))
}

public plugin_cfg()
{
	mp_c4timer = get_cvar_pointer("mp_c4timer")
	allow_spectators = get_cvar_pointer("allow_spectators")
	amx_show_activity = get_cvar_pointer("amx_show_activity")
	hostname = get_cvar_pointer("hostname")
	mp_freezetime = get_cvar_pointer("mp_freezetime")
	mp_timelimit = get_cvar_pointer("mp_timelimit")
	sv_contact = get_cvar_pointer("sv_contact")
	sv_alltalk = get_cvar_pointer("sv_alltalk")
	sv_gravity = get_cvar_pointer("sv_gravity")
	sv_password = get_cvar_pointer("sv_password")
	amx_reservation = get_cvar_pointer("amx_reservation")
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////
//Change to spec 1.0 by Exolent
//==========================================================================================================
new CsTeams:team[33]
public cmd_spec(id)
{

	if( !team[id] && get_pcvar_num( allow_spectators ) > 0  || get_pcvar_num( allow_public_spec == 1 ))
	{
		if( is_user_alive( id ) )
		{
			client_cmd( id, "kill" )
			cs_set_user_deaths( id, cs_get_user_deaths( id ) - 1 )
			fm_set_user_frags( id, get_user_frags( id ) + 1 )
		}
		team[id] = cs_get_user_team( id )
		cs_set_user_team( id, CS_TEAM_SPECTATOR, CS_DONTCHANGE )
	}
	return PLUGIN_HANDLED;
}

public cmd_unspec( id )
{
	if( team[id] )
		cs_set_user_team( id, team[id] )
	team[id] = CS_TEAM_UNASSIGNED
	return PLUGIN_HANDLED;
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////
//AFK BOMB TRANSFER v1.4 by VEN
//Revised by Doombringer/Deviance
//==========================================================================================================
public event_new_round() {
	g_freezetime = true
	g_spawn = true
	g_planting = false
	g_carrier = 0
}

public event_got_bomb(id) {
	g_carrier = id
}

public event_bar_time(id) {
	if (id == g_carrier) {
		g_planting = bool:read_data(1)
		get_user_origin(id, g_pos[id])
		g_time[id] = 0
	}
}

public event_bomb_drop() {
	g_spawn = false
	g_planting = false
	g_carrier = 0
}

public logevent_round_start()
{
    new id[32], num
    get_players(id, num, "ae", "TERRORIST")

    if (!num) // is server empty?
    return

    g_freezetime = false

    new x
    for (new i = 0; i < num; ++i) {
        x = id[i]
        get_user_origin(x, g_pos[x])
        g_time[x] = 0
    }
}

public task_afk_check() {
	if (g_freezetime) // is freezetime right now?
		return

	new id[32], num, x, origin[3]
	get_players(id, num, "ae", "TERRORIST")
	for (new i = 0; i < num; ++i) {
		x = id[i]
		get_user_origin(x, origin)
		if (origin[0] != g_pos[x][0] || origin[1] != g_pos[x][1] || (x == g_carrier && g_planting)) {
			g_time[x] = 0
			g_pos[x][0] = origin[0]
			g_pos[x][1] = origin[1]
			if (g_spawn && x == g_carrier)
				g_spawn = false
		}
		else
			g_time[x]++
	}

	if (!g_carrier || num < 2)
		return

	new max_time = get_pcvar_num(g_spawn ? transferfm_DispatchSpawn : transfertime)

	if (max_time <= 0 || g_time[g_carrier] < max_time)
		return

	get_user_origin(g_carrier, origin)
	new min_dist = 999999, dist, recipient, origin2[3]
	for (new i = 0; i < num; ++i) {
		x = id[i]
		if (g_time[x] < max_time) {
			get_user_origin(x, origin2)
			dist = get_distance(origin, origin2)
			if (dist < min_dist) {
				min_dist = dist
				recipient = x
			}
		}
	}

	if (!recipient)
		return

	new carrier = g_carrier
	engclient_cmd(carrier, "drop", weapons[WEAPON_C4]) // drop the backpack
	new c4 = fm_find_ent_by_class(-1, weapons[WEAPON_C4]) // find weapon_c4 entity
	if (!c4)
		return

	new backpack = pev(c4, pev_owner)
	if (backpack <= g_maxplayers)
		return

	set_pev(backpack, pev_flags, pev(backpack, pev_flags) | FL_ONGROUND)
	fm_fake_touch(backpack, recipient)

	set_hudmessage(0, 255, 0, 0.35, 0.8, _, _, 7.0)
	new message[128], c_name[32], r_name[32]
	get_user_name(carrier, c_name, 31)
	get_user_name(recipient, r_name, 31)
	format(message, 127, "%L", LANG_PLAYER, "AMX_SUPER_BOMB_TRANSFER", r_name, c_name)
	for (new i = 0; i < num; ++i)
		show_hudmessage(id[i], "%s", message)

	set_hudmessage(255, 255, 0, 0.42, 0.3, _, _, 7.0, _, _, 3)
	show_hudmessage(recipient, "You got the bomb!")

}

////////////////////////////////////////////////////////////////////////////////////////////////////////////
//PLAYER SPAWN FILTERS BY VEN
//==========================================================================================================
public fullupdate(id) {
	return PLUGIN_HANDLED_MAIN
}

public event_restart_attempt() {
	new players[32], num
	get_players(players, num, "a")
	for (new i; i < num; ++i)
		g_restart_attempt[players[i]] = true
}

public event_hud_reset(id) {
	if (g_restart_attempt[id]) {
		g_restart_attempt[id] = false
		return
	}
	event_fm_DispatchSpawned(id)

	if(HasPermGod[id])
	{
		fm_set_user_godmode(id, 1)
	}
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////
//FIX ECHO SOUNDS v1.0 by Throstur
//==========================================================================================================
public fRemove() {
	if(get_pcvar_num(soundfixon) != 1)
		return PLUGIN_HANDLED

	new Echo = fm_find_ent_by_class(0,"env_sound")
	while(Echo)
	{
		fm_remove_entity(Echo)
		Echo = fm_find_ent_by_class(Echo,"env_sound")
	}
	return PLUGIN_HANDLED
}

public cmdStopsound(id)
{
	if(get_pcvar_num(allowsoundfix) == 1)
	{
		client_cmd(id,"stopsound;room_type 00")
		client_cmd(id,"stopsound")
		client_print(id,print_chat,"%L", id, "AMX_SUPER_SOUNDFIX")
	}
	else
	{
		client_print(id,print_chat,"%L", id, "AMX_SUPER_SOUNDFIX_DISABLED")
		return PLUGIN_HANDLED
	}
	return PLUGIN_CONTINUE
}


////////////////////////////////////////////////////////////////////////////////////////////////////////////
//DAMAGE DONE v0.4 by Manip
//Revised by JTP10181 and Vittu
//==========================================================================================================
public on_damage(id)
{
	if(!get_pcvar_num(bulletdamage) || 0 >= id )
		return PLUGIN_HANDLED

	new attacker = get_user_attacker(id)
#if defined DAMAGE_RECIEVED

	if ( is_user_connected(id) && is_user_connected(attacker) )
	{
		new damage = read_data(2)

		set_hudmessage(255, 0, 0, 0.45, 0.50, 2, 0.1, 4.0, 0.1, 0.1, -1)
		ShowSyncHudMsg(id, g_MsgSync2, "%i^n", damage)
#else
	if ( is_user_connected(attacker) )
	{
		new damage = read_data(2)
#endif
		set_hudmessage(0, 100, 200, -1.0, 0.55, 2, 0.1, 4.0, 0.02, 0.02, -1)
		ShowSyncHudMsg(attacker, g_MsgSync, "%i^n", damage)
	}
	return PLUGIN_CONTINUE
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////
//BAD AIM 1.3 by TwistedEuphoria
//==========================================================================================================
public death_hook()
{
	new killer = read_data(1)
	new victim = read_data(2)

	if(badaim[killer] && (killer != victim))
	{
		if(autoban[killer])
		{
			new kuid = get_user_userid(killer)
			new name[32]
			get_user_name(killer,name,31)

			server_cmd("amx_ban #%d 0 Got a kill while affected by bad aim.",kuid)
			client_print(0,print_chat, "%L", LANG_PLAYER, "AMX_SUPER_BADAIM_KILLED",name)
		}
	}
	return PLUGIN_CONTINUE
}

public client_PreThink(id)
{
	if(badaim[id])
	{
		new Float:badvec[3] = {100.0,100.0,100.0}
		for(new j = 0;j<6;j++)
		{
			set_pev(id,pev_punchangle,badvec)
			set_pev(id,pev_punchangle,badvec)
			set_pev(id,pev_punchangle,badvec)  //Three's a charm!
		}
	}
	return PLUGIN_CONTINUE
}

public bad_aim(id,level,cid)
{
	if(!cmd_access(id,level,cid,2))
		return PLUGIN_HANDLED

	new target[32],tid

	if(read_argc() == 2)
	{
		console_print(id, "%L", LANG_PLAYER, "AMX_SUPER_BADAIM_CONSOLE")
		return PLUGIN_HANDLED
	}

	read_argv(1,target,31)

	if(get_pcvar_num(ba_followimmunity))
		tid = cmd_target(id,target,1)
	else
		tid = cmd_target(id,target,2)
	if(!tid)
		return PLUGIN_HANDLED

	new decstr[8]
	read_argv(2,decstr,7)
	new decnum
	decnum = str_to_num(decstr)
	new name[32]

	get_user_name(tid,name,31)

	switch(decnum)
	{
		case 0:
		{
			if(!badaim[tid])
			{
				console_print(id, "%L", LANG_PLAYER, "AMX_SUPER_BADAIM_NO_BADAIM",name)
				return PLUGIN_HANDLED
			}

			badaim[tid] = false
			autoban[tid] = false

			console_print(id, "%L", LANG_PLAYER, "AMX_SUPER_BADAIM_UNDO",name)

			remove_bad_vault(tid)
		}
		case 1:
		{
			if(badaim[tid])
			{
				console_print(id, "%L", LANG_PLAYER, "AMX_SUPER_BADAIM_CURRENT",name)
				return PLUGIN_HANDLED
			}

			if(get_pcvar_num(autobanall))
				autoban[tid] = true
			badaim[tid] = true

			console_print(id, "%L", LANG_PLAYER, "AMX_SUPER_BADAIM_WORSE",name)
		}
		default:
		{
			if(decnum < 0)
			{
				console_print(id, "%L", LANG_PLAYER, "AMX_SUPER_BADAIM_BADTIME")

				return PLUGIN_HANDLED
			}
			if(badaim[tid])

				console_print(id, "%L", LANG_PLAYER, "AMX_SUPER_BADAIM_MESSAGE1",name,decnum)
			else
				console_print(id, "%L", LANG_PLAYER, "AMX_SUPER_BADAIM_MESSAGE2",name,decnum)

			badaim[tid] = true

			if (get_pcvar_num(autobantimed) && get_pcvar_num(autobanall))
				autoban[tid] = true

			new pstr[3]
			pstr[0] = id
			pstr[1] = tid
			set_task(float(decnum),"unbad",4554+tid,pstr,2)
		}
	}

	new savestr[2]
	read_argv(3,savestr,1)
	new savenum = str_to_num(savestr)

	if(savenum)
	{
		if((decnum != 1) && (decnum != 0))

			console_print(id, "%L", LANG_PLAYER, "AMX_SUPER_BADAIM_BAN")
		else
			bad_vault(tid)
	}
	new aname[32], authid[32]
	get_user_name(id, aname, 31)
	get_user_authid(id, authid, 31)

	log_amx( "%L", LANG_PLAYER, "AMX_SUPER_BADAIM_LOG", aname, authid, badaim[tid] == true? "set" : "removed", name)
	return PLUGIN_HANDLED
}

public unbad(pstr[])
{
	new id = pstr[0]
	new tid = pstr[1]
	new name[32]

	get_user_name(tid,name,31)

	client_print(id,print_chat,"%L", LANG_PLAYER, "AMX_SUPER_BADAIM_NO_BADAIM_MESSAGE",name)
	console_print(id, "%L", LANG_PLAYER, "AMX_SUPER_BADAIM_NO_BADAIM_MESSAGE_CONSOLE",name)

	badaim[tid] = false
	autoban[tid] = false
}

public bad_vault(id)
{
	new sid[35]
	get_user_authid(id,sid,34)
	new vaultkey[51]

	format(vaultkey,50,"BADAIM_%s",sid)

	if(vaultdata_exists(vaultkey))
		remove_vaultdata(vaultkey)
	set_vaultdata(vaultkey,"1")
}

public remove_bad_vault(id)
{
	new sid[35]
	get_user_authid(id,sid,34)
	new vaultkey[51]

	format(vaultkey,50,"BADAIM_%s",sid)

	if(vaultdata_exists(vaultkey))
		remove_vaultdata(vaultkey)
}

public check_bad_vault(id)
{
	new sid[35]
	get_user_authid(id,sid,34)
	new vaultkey[51]

	format(vaultkey,50,"BADAIM_%s",sid)

	if(vaultdata_exists(vaultkey))
	{
		badaim[id] = true
		if(get_pcvar_num(autobanall))
			autoban[id] = true
	}
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////
//ADMIN DRUG by Exolent
//==========================================================================================================
public cmd_drug( id, level, cid )
{
	if( !cmd_access( id, level, cid, 2 ) )
		return PLUGIN_HANDLED

	new arg[32]
	read_argv( 1, arg, 31 )
	if( arg[0] == '@' )
	{
		new players[32], pnum
		if( arg[1] == 'a' || arg[1] == 'A' )
		{
			formatex( arg, 31, "everyone" )
			get_players( players, pnum, "a" )
		}
		else if( arg[1] == 'c' || arg[1] == 'C' )
		{
			formatex( arg, 31, "all CTs" )
			get_players( players, pnum, "ae", "CT" )
		}
		else if( arg[1] == 't' || arg[1] == 'T' )
		{
			formatex( arg, 31, "all Ts" )
			get_players( players, pnum, "ae", "TERRORIST" )
		}
		else	return PLUGIN_HANDLED

		if( !pnum ) return PLUGIN_HANDLED

		for( new i = 0; i < pnum; i++ )
		{
			message_begin( MSG_ONE, gmsg_SetFOV, { 0, 0, 0 }, players[i] )
			write_byte( 180 )
			message_end( )
		}
		new name[32], authid[32]

		get_user_name( id, name, 31 )
		get_user_authid( id, authid, 31 )

		switch( get_pcvar_num( amx_show_activity ) )
		{
			case 2: client_print( 0, print_chat, "%L", LANG_PLAYER, "AMX_SUPER_DRUG_TEAM_CASE2", name, arg )
			case 1: client_print( 0, print_chat, "%L", LANG_PLAYER, "AMX_SUPER_DRUG_TEAM_CASE1", arg )
		}

		console_print( id, "%L", id, "AMX_SUPER_DRUG_TEAM_MSG", arg )
		log_amx( "%L", LANG_SERVER, "AMX_SUPER_DRUG_TEAM_LOG", name, authid, arg )
	}
	else
	{
		new flags = 7

		if( get_user_flags( id ) & ADMIN_IMMUNITY )
			flags--
		new player = cmd_target( id, arg, flags )

		if( !player ) return PLUGIN_HANDLED

		message_begin( MSG_ONE, gmsg_SetFOV, { 0, 0, 0 }, player )
		write_byte( 180 )
		message_end( )

		new name[32], authid[32]
		new name2[32], authid2[32]

		get_user_name( id, name, 31 )
		get_user_authid( id, authid, 31 )

		get_user_name( player, name2, 31 )
		get_user_authid( player, authid2, 31 )

		switch( get_pcvar_num( amx_show_activity ) )
		{
			case 2: client_print( 0, print_chat, "%L", LANG_PLAYER, "AMX_SUPER_DRUG_PLAYER_CASE2", name, name2 )
			case 1: client_print( 0, print_chat, "%L", LANG_PLAYER, "AMX_SUPER_DRUG_PLAYER_CASE1",name2 )
		}

		console_print( id, "%L", id, "AMX_SUPER_DRUG_PLAYER_MSG", name2 )
		log_amx( "%L", LANG_SERVER, "AMX_SUPER_DRUG_PLAYER_LOG", name, authid, name2, authid2 )
	}
	return PLUGIN_HANDLED
}

/*
////////////////////////////////////////////////////////////////////////////////////////////////////////////
//ADMIN SPEED by Exolent
//==========================================================================================================
public cmd_speed( id, level, cid )
{
	if( !cmd_access( id, level, cid, 3 ) )
		return PLUGIN_HANDLED

	new arg[32]
	new arg2[32], bool:num = false

	read_argv( 1, arg, 31 )
	read_argv( 2, arg2, 31 )

	if( str_to_num( arg2 ) == 1 )
		num = true
	if( arg[0] == '@' )
	{
		new players[32], pnum
		if( arg[1] == 'a' || arg[1] == 'A' )
		{
			formatex( arg, 31, "everyone" )
			get_players( players, pnum, "a" )
		}
		else if( arg[1] == 'c' || arg[1] == 'C' )
		{
			formatex( arg, 31, "all CTs" )
			get_players( players, pnum, "ae", "CT" )
		}
		else if( arg[1] == 't' || arg[1] == 'T' )
		{
			formatex( arg, 31, "all Ts" )
			get_players( players, pnum, "ae", "TERRORIST" )
		}
		else	return PLUGIN_HANDLED

		if( !pnum ) return PLUGIN_HANDLED

		if(  num ) formatex( arg2, 31, "on" )

		else	formatex( arg2, 31, "off" )

		new pid;
		for( new i = 0; i < pnum; i++ )
		{
			pid = players[i]
			g_speed[pid] = num
			event_weapon(pid)
		}

		new name[32], authid[32]

		get_user_name( id, name, 31 )
		get_user_authid( id, authid, 31 )

		switch( get_pcvar_num( amx_show_activity ) )
		{
			case 2: client_print( 0, print_chat, "%L", LANG_PLAYER, "AMX_SUPER_SPEED_TEAM_CASE2", name, arg2, arg )
			case 1: client_print( 0, print_chat, "%L", LANG_PLAYER, "AMX_SUPER_SPEED_TEAM_CASE1", arg2, arg )
		}

		console_print( id, "%L", id, "AMX_SUPER_SPEED_TEAM_MSG", arg2, arg )
		log_amx( "%L", LANG_SERVER, "AMX_SUPER_SPEED_TEAM_LOG", name, authid, arg )
	}
	else
	{
		new flags = 7

		if( get_user_flags( id ) & ADMIN_IMMUNITY)
			flags--
		new player = cmd_target( id, arg, flags )
		if( !player ) return PLUGIN_HANDLED

		g_speed[player] = num
		formatex( arg2, 31, "off" )

		if( g_speed[player] )
		{
			formatex( arg2, 31, "on" )
		}

		event_weapon(player);

		new name[32], name2[32], authid[32], authid2[32]

		get_user_name( id, name, 31 )
		get_user_authid( id, authid, 31 )

		get_user_name( player, name2, 31 )
		get_user_authid( player, authid2, 31 )

		switch( get_pcvar_num( amx_show_activity ) )
		{
			case 2: client_print( 0, print_chat, "%L", LANG_PLAYER, "AMX_SUPER_SPEED_PLAYER_CASE2", name, arg2, name2 )
			case 1: client_print( 0, print_chat, "%L", LANG_PLAYER, "AMX_SUPER_SPEED_PLAYER_CASE1", arg2, name2 )
		}

		console_print( id, "%L", id, "AMX_SUPER_SPEED_PLAYER_MSG", arg2, name2 )
		log_amx( "%L", LANG_SERVER, "AMX_SUPER_SPEED_PLAYER_LOG", name, authid, name2, authid2 )
	}
	return PLUGIN_HANDLED
}

public event_weapon(id)
{
	new Float:maxspeed;
	pev(id, pev_maxspeed, maxspeed);
	if(maxspeed != 1.0)
	{
		if(g_speed[id])
		{
			maxspeed *= 3.0;
		}
		else if(!g_freezetime) {
			switch(read_data(2)) {
				case CSW_SCOUT: maxspeed=260.0
				case CSW_P90: maxspeed=245.0
				case CSW_XM1014,CSW_AUG,CSW_GALIL,CSW_FAMAS: maxspeed=240.0
				case CSW_SG552 : maxspeed=235.0
				case CSW_M3,CSW_M4A1 : maxspeed=230.0
				case CSW_AK47 : maxspeed=221.0
				case CSW_M249 : maxspeed=220.0
				case CSW_AWP,CSW_SG550,CSW_G3SG1 : maxspeed=210.0
				default : maxspeed=250.0
			}
		}
		set_pev(id, pev_maxspeed, maxspeed);
	}
}
*/
////////////////////////////////////////////////////////////////////////////////////////////////////////////
//STATS MARQUEE v1.2 by Travo
//==========================================================================================================
public displayplr()
{
	if (!get_pcvar_num(statsmarquee))
	{
		set_task(60.0,"displayplr",0,"",0,"a",1)
		return PLUGIN_HANDLED
	}
	new Stats[8], Body[8], Name[31], Float:VertLoc2
	new PlrAmt = get_pcvar_num(cvPlrAmt)
	new VertLoc = get_pcvar_num(cvVertLoc)
	new Float:FullTime = get_pcvar_float(cvFullTime)
	new Float:TimeBetw = get_pcvar_float(cvTimeBetw)

	if(VertLoc==1)
		VertLoc2 = -0.74
	else
		VertLoc2 = 0.77

	get_stats(statsm, Stats, Body, Name, 31)

	statsm++

	set_hudmessage(0, 240, 10, 0.70, VertLoc2, 0, TimeBetw, TimeBetw, 0.5, 0.15, -1)
	show_hudmessage(0,"Server Top %d^n%s^nRank %d %d kills %d deaths", PlrAmt, Name, statsm, Stats[0], Stats[1])

	if(statsm >= PlrAmt)
	{
		statsm = 0
		set_task(FullTime,"displayplr",0,"",0,"a",1)
	}
	else
	{
		set_task(TimeBetw,"displayplr",0,"",0,"a",1)
	}

	return PLUGIN_CONTINUE
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////
//ADMIN LISTEN v2.3 by Psychoguard, rewritten by Maxim and ported by Oj@eKiLLzZz deb/urandom
//==========================================================================================================
public catch_say()
{
	if (!get_pcvar_num(adminlisten))
	return PLUGIN_CONTINUE;

	new reciever = read_data(0)
	new sender = read_data(1)
	new message[151]
	new channel[151]
	new sender_name[32]

	if (is_running("czero")||is_running("cstrike"))
	{
		read_data(2,channel,150)
		read_data(4,message,150)
		get_user_name(sender, sender_name, 31)

	} else {

		read_data(2,message,150)
	}

	count[sender][reciever] = true

	if (sender == reciever)
	{
		new player_count = get_playersnum()
		new players[32]

		get_players(players, player_count, "c")

		for (new i = 0; i < player_count; i++)
		{

			if (get_user_flags(players[i])&get_immune_access_flag2())
			{

				if (!count[sender][players[i]])
				{
					message_begin(MSG_ONE, get_user_msgid("SayText"),{0,0,0},players[i])

					write_byte(sender)

					if (is_running("czero")||is_running("cstrike"))
					{
						write_string(channel)
						write_string(sender_name)
					}
					write_string(message)
					message_end()
				}
			}
			count[sender][players[i]] = false
		}
	}

	return PLUGIN_CONTINUE
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////
//Enter/Leave Message v1.0 by by [Kindzhon] China Revised by Bmann_420 and Exolent
//==========================================================================================================
public client_putinserver(id)
{
	new param[1]

	param[0] = id
	g_name[id][0] = 0

	get_user_name(id, g_name[id], 31)

	set_task(2.0, "enter_msg", 0, param, 1)

	badaim[id] = false
	autoban[id] = false
	check_bad_vault(id)


	// -- CHECK IF LEFT TO DODGE GAG
	// ------------------------------
	new authid[32]

	get_user_authid( id, authid, 31 )

	g_gagged[id] = 0
	for( new i = 0; i < 33; i++ )
	{
		if( equali( authid, g_wasgagged[i] ) )
		{
			new temp[32]
			switch( g_gagflags[i] )
			{
				case 1: formatex( temp, 31, "a" )
				case 2: formatex( temp, 31, "b" )
				case 3: formatex( temp, 31, "ab" )
				case 4: formatex( temp, 31, "c" )
				case 5: formatex( temp, 31, "ac" )
				case 6: formatex( temp, 31, "bc" )
				case 7: formatex( temp, 31, "abc" )
			}
			new flags = read_flags( temp )

			g_gagged[id] = flags
			if( flags & 4 )
				fm_set_speak( id, SPEAK_MUTED )

			new name[32]

			get_user_name( id, name, 31 )

			client_print( 0, print_chat, "%L", LANG_PLAYER, AMX_SUPER_GAG_CONNECTED, name )

			new ungagid[1]

			ungagid[0] = id
			g_wasgagged[i][0] = 0

			set_task( DefaultGagTime , "task_ungag", id, ungagid, 1 )
			break;
		}
	}

	return PLUGIN_CONTINUE
}

public leave_msg(param[])
{
    if (get_pcvar_num(joinleave_message) == 1 && get_pcvar_num(leavemessage_enable) == 1)
    {
        new id = param[0]

        if(is_user_bot(id))
		return PLUGIN_HANDLED

        new message[192], _hostname[64]

        get_pcvar_string(leavemessage, message, 191)
        get_pcvar_string(hostname, _hostname, 63)

        replace(message, 191, "%hostname%", _hostname)
        replace(message, 191, "%name%", g_name[id])

        replace_all(message, 191, "\n", "^n")

        set_hudmessage(12, 240, 0, 0.10, 0.55, 0, 6.0, 6.0, 0.5, 0.15, 3)
        show_hudmessage(0, message)
    }

    return PLUGIN_CONTINUE
}

public enter_msg(param[])
{
    if (get_pcvar_num(joinleave_message) == 1)
    {
        new id = param[0]

        //if(is_user_bot(id))
		//return PLUGIN_HANDLED

        new message[192], _hostname[64]

        get_pcvar_string(entermessage, message, 191)

        get_pcvar_string(hostname, _hostname, 63)
        replace(message,191, "%hostname%", _hostname)

        if (cvar_exists("csstats_reset"))
        {
            new data[8], rankpos[8], pos

            pos = get_user_stats(id, data, data)

            num_to_str(pos, rankpos, 7)

            replace(message, 191, "%rankpos%", rankpos)
            replace(message, 191, "%name%", g_name[id])

            replace_all(message, 191, "\n", "^n")

            if (get_user_flags(id) & ADMIN_RESERVATION) {

                set_hudmessage(12, 240, 0, 0.10, 0.55, 0, 6.0, 6.0, 0.5, 0.15, 3)
                show_hudmessage(0, message)

                client_cmd(0,"spk buttons/blip1.wav")
                return PLUGIN_HANDLED

            }
            else
            {

                set_hudmessage(0, 255, 0, 0.10, 0.55, 0, 6.0, 6.0, 0.5, 0.15, 3)
                show_hudmessage(0, message)
            }
        }
    }

    return PLUGIN_CONTINUE
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////
//VOCOM ADMIN v1.3 by Nut
//==========================================================================================================
public client_authorized(id) {

	if (get_user_flags(id) & ADMIN_RESERVATION) {
		g_admin[id] = 1
	}
}

public voice_hook(id) {
	g_voicemask[id]=read_data(2)
}

public fm_mute_forward(receiver, sender, listen) {

	if (receiver == sender) return FMRES_IGNORED
	if (get_user_speak(sender) == SPEAK_ADMIN) {

		if (g_admin[receiver] == 1) {
			engfunc(EngFunc_SetClientListening, receiver, sender, SPEAK_NORMAL2)
		}else{
			engfunc(EngFunc_SetClientListening, receiver, sender, SPEAK_MUTED2)
		}

		return FMRES_SUPERCEDE
	}
	else if(g_voicemask[receiver] & 1<<(sender-1)) {
		engfunc(EngFunc_SetClientListening, receiver, sender, SPEAK_MUTED)
		forward_return(FMV_CELL,false)
	}
	return FMRES_IGNORED
}

public set_user_speak(id,listen) {
	g_playerspk[id] = listen
}

public get_user_speak(id) {
	return g_playerspk[id]
}

public vocomStart(id) {

	if (!g_admin[id]) {

		client_print(id,print_chat, "%L", LANG_PLAYER, "AMX_SUPER_VOCOM_NO_ACCESS")
		return PLUGIN_HANDLED
	}

	client_cmd(id,"+voicerecord")

	set_user_speak(id,SPEAK_ADMIN)

	new name[33]

	get_user_name(id,name,32)

	get_players(players, pCount, "c")

	for (new i = 0; i < pCount; i++) {
		if (g_admin[i]) {
			if (i != id) {

				client_print(i,print_chat, "%L", LANG_PLAYER, "AMX_SUPER_VOCOM_SPEAKING1",name)
			}
		}
	}

	client_print(id,print_chat, "%L", LANG_PLAYER, "AMX_SUPER_VOCOM_SPEAKING2",name)
	return PLUGIN_HANDLED
}

public vocomStop(id) {

	if(is_user_connected(id)) {

		client_cmd(id,"-voicerecord")
		if(get_user_speak(id) == SPEAK_ADMIN) {

			set_user_speak(id,SPEAK_NORMAL2)
		}
	}
	return PLUGIN_HANDLED
}


////////////////////////////////////////////////////////////////////////////////////////////////////////////
//Ultra Glow v1.1 by Remo Williams
//Rewritten by Exolent
//==========================================================================================================
public cmd_glow(id, level, cid)
{
	if(!cmd_access(id, level, cid, 3))
		return PLUGIN_HANDLED

	new command[16], arg1[32], arg2[32], arg3[32], arg4[32], arg5[32]
	read_argv(0, command, 15)
	read_argv(1, arg1, 31)
	read_argv(2, arg2, 31)
	read_argv(3, arg3, 31)
	read_argv(4, arg4, 31)
	read_argv(5, arg5, 31)

	new bool:isPermGlow = false
	if(command[8] == '2')
		isPermGlow = true

	new name[32], authid[32]
	get_user_name(id, name, 31)
	get_user_authid(id, authid, 31)

	if(!color_check(arg2)&&!strlen(arg3))
	{
		console_print(id, "%L", LANG_PLAYER, "AMX_SUPER_GLOW_INVALID_COLOR")
		return PLUGIN_HANDLED
	}

	new num, bool:valid = false
	for(num = 0; num < 30; num++)
	{
		if(equali(g_sColors[num],arg2))
		{
			valid = true
			break;
		}
	}
	new rnum, gnum, bnum, anum, bool:isOff = false;
	if(valid)
	{
		if(equali(arg2, "off")) isOff = true;
		rnum = g_iColors[num][0]
		gnum = g_iColors[num][1]
		bnum = g_iColors[num][2]
		anum = 255
	}
	else if(!valid && strlen(arg5))
	{
		rnum = str_to_num(arg2)
		gnum = str_to_num(arg3)
		bnum = str_to_num(arg4)
		anum = str_to_num(arg5)
		if(rnum == 0 && gnum == 0 && bnum == 0 && anum == 255) isOff = true;
	}
	else
	{
		console_print(id, "[AMXX] Please include the correct parameters.")
		console_print(id, "Usage: amx_glow(2) <nick, #userid, or authid> <color>")
		console_print(id, "Usage: amx_glow(2) <nick, #userid, or authid> <rrr> <ggg> <bbb> <aaa>")
		return PLUGIN_HANDLED;
	}
	if(rnum > 255) rnum = 255
	else if(rnum < 0) rnum = 0
	if(gnum > 255) gnum = 255
	else if(gnum < 0) gnum = 0
	if(bnum > 255) bnum = 255
	else if(bnum < 0) bnum = 0
	if(anum > 255) anum = 255
	else if(anum < 0) anum = 0

	new pid, activity = get_pcvar_num(amx_show_activity)
	if(arg1[0] == '@')
	{
		new players[32], pnum
		if(equali("T",arg1[1])) copy( arg1[1], 31, "TERRORIST" )
		if(equali("ALL",arg1[1])) get_players( players, pnum, "a" )
		else get_players( players, pnum, "ae", arg1[1] )

		if(!pnum) return PLUGIN_HANDLED
		for( new i = 0; i < pnum; i++ )
		{
			pid = players[i]
			HasPermGlow[pid] = isPermGlow
			if(isPermGlow)
			{
				g_glow[pid][0] = rnum
				g_glow[pid][1] = gnum
				g_glow[pid][2] = bnum
				g_glow[pid][3] = anum
			}
			else
			{
				for(new j = 0; j < 4; j++ )
					g_glow[pid][j] = 0
			}
			fm_set_rendering(pid, kRenderFxGlowShell, rnum, gnum, bnum, kRenderTransAlpha, anum)
		}
		switch(activity)
		{
			case 2: client_print(0, print_chat, "%L", LANG_PLAYER, isOff? "AMX_SUPER_GLOW_TEAM_OFF_CASE2" : "AMX_SUPER_GLOW_TEAM_CASE2", name, arg1[1])
			case 1: client_print(0, print_chat, "%L", LANG_PLAYER, isOff? "AMX_SUPER_GLOW_TEAM_OFF_CASE1" : "AMX_SUPER_GLOW_TEAM_CASE1", arg1[1])
		}
		console_print(id, "%L", id, "AMX_SUPER_GLOW_TEAM_MSG", arg1[1])
		log_amx("%L", LANG_SERVER, "AMX_SUPER_GLOW_TEAM_LOG", name, authid, arg1[1])
		return PLUGIN_HANDLED
	}
	pid = cmd_target(id, arg1, 2)
	if(!pid) return PLUGIN_HANDLED

	new pname[32], pauthid[32]

	get_user_name(pid, pname, 31)
	get_user_authid(pid, pauthid, 31)

	HasPermGlow[pid] = isPermGlow
	if(isPermGlow)
	{
		g_glow[pid][0] = rnum
		g_glow[pid][1] = gnum
		g_glow[pid][2] = bnum
		g_glow[pid][3] = anum
	}
	else
	{
		for( new j = 0; j < 4; j++ )
			g_glow[pid][j] = 0
	}
	fm_set_rendering(pid, kRenderFxGlowShell, rnum, gnum, bnum, kRenderTransAlpha, anum)
	switch(activity)
	{
		case 2: client_print(0, print_chat, "%L", LANG_PLAYER, isOff? "AMX_SUPER_GLOW_PLAYER_OFF_CASE2" : "AMX_SUPER_GLOW_PLAYER_CASE2", name, pname)
		case 1: client_print(0, print_chat, "%L", LANG_PLAYER, isOff? "AMX_SUPER_GLOW_PLAYER_OFF_CASE1" : "AMX_SUPER_GLOW_PLAYER_CASE1", pname)
	}
	console_print(id, "%L", id, "AMX_SUPER_GLOW_PLAYER_MSG", pname)
	log_amx("%L", LANG_SERVER, "AMX_SUPER_GLOW_PLAYER_LOG", name, authid, pname, pauthid)
	return PLUGIN_HANDLED
}

public cmd_glowcolors(id, level, cid)
{
	if(!cmd_access(id, level, cid, 0))
		return PLUGIN_HANDLED;

	new sColors[192], i
	for(i = 0; i < 30; i += 5)
	{
		if(i == 0) formatex(sColors, 191, "Colors: %s,",g_sColors[0])
		else	formatex(sColors, 191, "%s,", g_sColors[i])
		color_print(id, i + 1, sColors)
	}
	console_print(id, "Example: amx_glow ^"jimmy^" ^"red^"")
	return PLUGIN_HANDLED
}

public color_print(id, num, string[])
{
	for(new max = num + 4; num < max; num++)
		formatex(string, 191, "%s %s,", string, g_sColors[num])
	console_print(id, "%s", string)
}

stock color_check(color[])
{
	new bool:valid = false
	for(new i = 0; i < 30; i++)
	{
		if(equali(g_sColors[i],color))
		{
			valid = true
			break;
		}
	}
	return valid;
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////
//SPAWN PROTECTION v7.1 by Peli Revised for Glow On/Off by KaszpiR Revised by Bmann_420
//==========================================================================================================
public cmd_sptime(id, level, cid)
{
	if(!cmd_access(id, level, cid, 2))
		return PLUGIN_HANDLED

	new arg_str[3]
	read_argv(1, arg_str, 3)
	new arg = str_to_num(arg_str)

	if(arg > 10 || arg < 1)
	{
		client_print(id, print_chat, "%L", LANG_PLAYER, "AMX_SUPER_SPAWN_PROTECTION_BADTIME")
		return PLUGIN_HANDLED
	}

	else if (arg > 0 || arg < 11)
	{
		set_pcvar_num(sv_sptime, arg)
		client_print(id, print_chat, "%L", LANG_PLAYER, "AMX_SUPER_SPAWN_PROTECTION_TIME_SET", arg)
		return PLUGIN_HANDLED
	}
	return PLUGIN_CONTINUE
}

public cmd_spmessage(id, level, cid)
{
	if (!cmd_access(id, level, cid, 2))
	{
		return PLUGIN_HANDLED
	}

	new sp[3]
	read_argv(1, sp, 2)

	if (sp[0] == '1')
	{
		set_pcvar_num(sv_spmessage, 1)
	}

	else if (sp[0] == '0')
	{
		set_pcvar_num(sv_spmessage, 0)
	}

	else if (sp[0] != '1' || sp[0] != '0')
	{

		console_print(id, "Usage : amx_spmessage 1 = Messages ON | 0 = Messages OFF")
		return PLUGIN_HANDLED

	}

	return PLUGIN_HANDLED
}

public cmd_spshellthickness(id, level, cid)
{
	if(!cmd_access(id, level, cid, 2))
		return PLUGIN_HANDLED

	new arg_str[3]
	read_argv(1, arg_str, 3)
	new arg = str_to_num(arg_str)

	if(arg > 100 || arg < 1)
	{

		client_print(id, print_chat, "%L", LANG_PLAYER, "AMX_SUPER_SPAWN_PROTECTION_BADSHELL")
		return PLUGIN_HANDLED

	}

	else if (arg > 0 || arg < 101)
	{
		set_pcvar_num(sv_spshellthick, arg)
		client_print(id, print_chat, "%L", LANG_PLAYER, "AMX_SUPER_SPAWN_PROTECTION_SHELL_SET", arg)
		return PLUGIN_HANDLED
	}
	return PLUGIN_CONTINUE
}

public cmd_spglow(id, level, cid)
{
	if(!cmd_access(id, level, cid, 2))
		return PLUGIN_HANDLED

	new arg_str[3]
	read_argv(1, arg_str, 3)
	new arg = str_to_num(arg_str)


	if (arg > 0)
	{
		arg = 1
		client_print(id, print_chat, "%L", LANG_PLAYER, "AMX_SUPER_SPAWN_PROTECTION_GLOW_ON")
	}
	else
	{
		arg = 0
		client_print(id, print_chat, "%L", LANG_PLAYER, "AMX_SUPER_SPAWN_PROTECTION_GLOW_OFF")
	}
	set_pcvar_num(sv_spglow, arg)

	return PLUGIN_CONTINUE
}

public sp_on(id)
{
	if (get_pcvar_num(sv_sp) == 1)
	{
		set_task(0.1, "protect", id)
	}

	return PLUGIN_CONTINUE
}

new isRoundStarted = true
new SpawnProtection[512]

public event_roundstart()
{
    isRoundStarted = true
}

public event_roundend()
{
    isRoundStarted = false
}

public protect(id)
{
    new FTime = get_pcvar_num(mp_freezetime)
    new Float:SPTime = get_pcvar_float(sv_sptime)
    new SPShell = get_pcvar_num(sv_spshellthick)
    fm_set_user_godmode(id, 1)

    if( isRoundStarted )
	{
	    FTime = 0
	} else
	{
	    FTime = get_pcvar_num(mp_freezetime)
	}
    if(get_pcvar_num(sv_spglow))
	{

		if(get_user_team(id) == 1)
		{
			fm_set_rendering(id, kRenderFxGlowShell, 255, 0, 0, kRenderNormal, SPShell)
		}

		if(get_user_team(id) == 2)
		{
			fm_set_rendering(id, kRenderFxGlowShell, 0, 0, 255, kRenderNormal, SPShell)
		}
	}

    if(get_pcvar_num(sv_spmessage) == 1)
	{
	    new argSpawn[64]
	    formatex( argSpawn, charsmax(argSpawn), "%d", id )
	    set_task( 1.0, "SpawnProtectionCountDown", TASK_SPAWN_PROTECTION_ID + id, argSpawn, 64, "b", 0 )
	    SpawnProtection[id] = floatround(SPTime + FTime)
	    //server_print("%f", floatround(SPTime + FTime) )
	}

    return PLUGIN_HANDLED
}

public SpawnProtectionCountDown( stringID[] )
{
    new id = str_to_num( stringID )
    //server_print("%s - %d", stringID, id )

    set_hudmessage( 200, 200, 0, 0.35, 0.85, 0, 0.0, 1.0, 0.1, 0.1, 4 )
    show_hudmessage( id, "%L", LANG_PLAYER, "AMX_SUPER_SPAWN_PROTECTION_MESSAGE", SpawnProtection[id] - 1 )

    SpawnProtection[id]--;

    if ( SpawnProtection[id] <= 0 )
    {
        if ( task_exists( TASK_SPAWN_PROTECTION_ID + id ) )
        {
            remove_task( TASK_SPAWN_PROTECTION_ID + id );
            sp_off(id)
            return;
        }
    }
}

public sp_off(id)
{
	if(!is_user_connected(id))
	{
		return PLUGIN_HANDLED
	}
	else if( HasPermGlow[id] )
	{
		fm_set_rendering( id, kRenderFxGlowShell, g_glow[id][0], g_glow[id][1], g_glow[id][2], kRenderTransAlpha, g_glow[id][3] )
	}

	else if( !HasPermGod[id] )
	{
		fm_set_rendering(id, kRenderFxGlowShell, 0, 0, 0, kRenderTransAlpha, 255)
	}
	fm_set_user_godmode(id, 0)
	return PLUGIN_HANDLED
}


////////////////////////////////////////////////////////////////////////////////////////////////////////////
//ADMIN EXTEND v1.1 by JSauce
//==========================================================================================================
public admin_extend(id,level,cid)
{
	if (!cmd_access(id,level,cid,2))
		return PLUGIN_HANDLED

	new arg[32],name[32]
	read_argv(1,arg,31)
	get_user_name(id,name,31)
	#if defined MAPCYCLE
	if (!cyclerfile)
	{
		client_print(id,print_chat,"%L", LANG_PLAYER, "AMX_SUPER_EXTEND_NOMAPCYCLE")
		return PLUGIN_HANDLED
	}
	#endif
	if (arg[0])
	{
		if(containi(arg,"-") != -1)
		{
			client_print(id,print_chat,"%L", LANG_PLAYER, "AMX_SUPER_EXTEND_BAD_NUMBER")
			return PLUGIN_HANDLED
		}
		new tlimit = str_to_num(arg)
		if (user_limit >= EXTENDMAX)
		{
			client_print(id,print_chat,"%L", LANG_PLAYER, "AMX_SUPER_EXTEND_EXTENDMAX",EXTENDMAX)
			return PLUGIN_HANDLED
		}
		if (tlimit > EXTENDTIME)
		{
			client_print(id,print_chat,"%L", LANG_PLAYER, "AMX_SUPER_EXTEND_EXTENDTIME",EXTENDTIME)
			tlimit = EXTENDTIME
		}
		set_pcvar_float(mp_timelimit,get_pcvar_float(mp_timelimit) + tlimit)

		switch(get_pcvar_num(amx_show_activity))	{
			case 2:	client_print(0,print_chat,"%L", LANG_PLAYER, "AMX_SUPER_EXTEND_SUCCESS_CASE2",name,tlimit)
			case 1:	client_print(0,print_chat,"%L", LANG_PLAYER, "AMX_SUPER_EXTEND_SUCCESS_CASE1",tlimit)
		}
		++user_limit
		return PLUGIN_HANDLED
	}

	return PLUGIN_HANDLED
}


////////////////////////////////////////////////////////////////////////////////////////////////////////////
//C4 Timer v1.1 by Cheap_Suit
//==========================================================================================================
public event_hltv()
	g_c4timer = get_pcvar_num(mp_c4timer)

public logevent_plantedthebomb()
{
	new showtteam = get_pcvar_num(cvar_showteam)

	static players[32], num, i
	switch(showtteam)
	{
		case 1: get_players(players, num, "ace", "TERRORIST")
		case 2: get_players(players, num, "ace", "CT")
		case 3: get_players(players, num, "ac")
		default: return
	}
	for(i = 0; i < num; ++i) set_task(1.0, "update_timer", players[i])
}

public update_timer(id)
{
	//message_begin(MSG_ONE_UNRELIABLE, g_msg_showtimer, _, id)
	//message_end()

	message_begin(MSG_ONE_UNRELIABLE, g_msg_roundtime, _, id)
	write_short(g_c4timer)
	message_end()

	message_begin(MSG_ONE_UNRELIABLE, g_msg_scenario, _, id)
	write_byte(1)
	write_string(g_timersprite[clamp(get_pcvar_num(cvar_sprite), 0, (MAX_SPRITES - 1))])
	write_byte(150)
	write_short(get_pcvar_num(cvar_flash) ? 20 : 0)
	message_end()

	if(get_pcvar_num(cvar_msg))
	{
		set_hudmessage(255, 180, 0, 0.44, 0.87, 2, 6.0, 6.0)
		show_hudmessage(id, g_message)
	}
}
////////////////////////////////////////////////////////////////////////////////////////////////////////////
//ADMIN CHECK v1.15 by OneEyed
//==========================================================================================================
public show_admins(user)
{
	new message[256]
	if(get_pcvar_num(admincheck))
	{
		new adminnames[33][32]
		new contactinfo[256], contact[112]
		new id, count, x, len

		for(id = 1 ; id <= maxplayers ; id++)
			if(is_user_connected(id))
				if(get_user_flags(id) & ADMIN_CHECK)
					get_user_name(id, adminnames[count++], 31)

		len = format(message, 255, "%s ADMINS ONLINE: ",COLOR)
		if(count > 0) {
			for(x = 0 ; x < count ; x++) {
				len += format(message[len], 255-len, "%s%s ", adminnames[x], x < (count-1) ? ", ":"")
				if(len > 96 ) {
					print_message(user, message)
					len = format(message, 255, "%s ",COLOR)
				}
			}
			print_message(user, message)
		}
		else {
			len += format(message[len], 255-len, "No admins online.")
			print_message(user, message)
		}

		get_pcvar_string(sv_contact, contact, 63)
		if(contact[0])  {
			format(contactinfo, 111, "%s Contact Server Admin -- %s", COLOR, contact)
			print_message(user, contactinfo)
		}
	}
	else
	{
		formatex(message, 255, "^x04 Admin Check is currently DISABLED.")
		print_message(user, message)
	}
}

print_message(id, msg[]) {
	message_begin(MSG_ONE, gmsgSayText, {0,0,0}, id)
	write_byte(id)
	write_string(msg)
	message_end()
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////
//ADMIN FLASH v1.0 by AssKicR
//Rewritten by Bo0m!
//==========================================================================================================
public admin_flash(id,level,cid) {
	if (!cmd_access(id,level,cid,2))
		return PLUGIN_HANDLED

	new arg[32]
	new name[32], name2[32], authid[35], authid2[35]
	read_argv(1,arg,31)
	get_user_name(id,name,31)
	get_user_authid(id,authid,34)

	if (arg[0]=='@'){
		new players[32], inum
		if (equali("T",arg[1]))		copy(arg[1],31,"TERRORIST")
		if (equali("ALL",arg[1]))	get_players(players,inum)
		else						get_players(players,inum,"e",arg[1])

		if (inum == 0) {
			console_print(id,"%L", LANG_PLAYER, AMX_SUPER_NO_PLAYERS)
			return PLUGIN_HANDLED
		}

		for(new a = 0;a < inum; a++) {
			if (get_user_flags(players[a]) & ADMIN_IMMUNITY && players[a] != id) {
				get_user_name(players[a],name2,31)
				console_print(id,"%L", LANG_PLAYER, AMX_SUPER_TEAM_IMMUNITY,name2)
				continue
			}

			Flash(players[a])
		}

		switch(get_pcvar_num(amx_show_activity))	{
			case 2:	client_print(0,print_chat,"%L", LANG_PLAYER, "AMX_SUPER_FLASH_TEAM_CASE2",name,arg[1])
			case 1:	client_print(0,print_chat,"%L", LANG_PLAYER, "AMX_SUPER_FLASH_TEAM_CASE1",arg[1])
		}

		console_print(id,"%L", LANG_PLAYER, "AMX_SUPER_FLASH_TEAM_MSG",arg[1])
		log_amx("%L", LANG_SERVER, "AMX_SUPER_FLASH_TEAM_LOG", name,authid,arg[1])
	}
	else {

		new player = cmd_target(id,arg,7)
		if (!player) return PLUGIN_HANDLED

		Flash(player)

		get_user_name(player,name2,31)
		get_user_authid(player,authid2,34)

		switch(get_pcvar_num(amx_show_activity)) {
			case 2:	client_print(0,print_chat,"%L", LANG_PLAYER, "AMX_SUPER_FLASH_PLAYER_CASE2",name,name2)
			case 1:	client_print(0,print_chat,"%L", LANG_PLAYER, "AMX_SUPER_FLASH_PLAYER_CASE1",name2)
		}

		console_print(id,"%L", LANG_PLAYER, "AMX_SUPER_FLASH_PLAYER_MSG",name2)
		log_amx("%L", LANG_SERVER, "AMX_SUPER_FLASH_PLAYER_LOG", name,authid,name2,authid2)
	}
	return PLUGIN_HANDLED
}

public Flash(id) {
	message_begin(MSG_ONE,gMsgScreenFade,{0,0,0},id)
	write_short( 1<<15 )
	write_short( 1<<10 )
	write_short( 1<<12 )
	write_byte( 255 )
	write_byte( 255 )
	write_byte( 255 )
	write_byte( 255 )
	message_end()

	if(get_pcvar_num(flashsound) == 1)
		emit_sound(id,CHAN_BODY, "weapons/flashbang-2.wav", 1.0, ATTN_NORM, 0, PITCH_HIGH)
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////
//ADMIN UNLIMITED AMMO v1.0 by regalis ripped from Superhero Punisher by {HOJ} Batman
//==========================================================================================================
public admin_unammo(id, level, cid)
{
	if(!cmd_access(id, level, cid, 2)) return PLUGIN_HANDLED

	new arg1[32], arg2[2]
	read_argv(1, arg1, 31)
	read_argv(2, arg2, 1)
	new setting = str_to_num(arg2)
	new name[32], authid[36]

	get_user_name(id, name, 31)
	get_user_authid(id, authid, 35)

	if(equali(arg1, "@", 1))
	{
		new players[32], num

		if(containi(arg1, "ALL") != -1)
		{
			get_players(players, num)
			formatex(arg1[1], 30, "players");
		}
		else get_players(players, num, "e", !equali(arg1, "CT") ? "TERRORIST":"CT")

		if(!num)
		{
			console_print(id,"%L", LANG_PLAYER, AMX_SUPER_NO_PLAYERS)
			return PLUGIN_HANDLED
		}
		for(new i = 0; i < num; i++)
		{
			switch(setting)
			{
				case 0:{unammo[players[i]] = false;}
				case 1:{unammo[players[i]] = true;}
			}
		}
		switch(get_pcvar_num(amx_show_activity))
		{
			case 2:	client_print(0, print_chat, "%L", LANG_PLAYER, "AMX_SUPER_AMMO_TEAM_CASE2", name, arg1[1], setting)
			case 1:	client_print(0, print_chat, "%L", LANG_PLAYER, "AMX_SUPER_AMMO_TEAM_CASE1", arg1[1], setting)
		}
		console_print(id, "%L", LANG_PLAYER, "AMX_SUPER_AMMO_TEAM_MSG", arg1[1], setting)
		log_amx("%L", LANG_SERVER, "AMX_SUPER_AMMO_TEAM_LOG", name, authid, arg1[1], setting)
	}
	else
	{
		new name2[32], authid2[36]
		new player = cmd_target(id, arg1, 2)

		if(!player) return PLUGIN_HANDLED

		get_user_name(player, name2, 31)
		get_user_authid(player, authid2, 35)
		switch(setting)
			{
				case 0:{unammo[player] = false;}
				case 1:{unammo[player] = true;}
			}
		switch(get_pcvar_num(amx_show_activity))
		{
			case 2:	client_print(0, print_chat, "%L", LANG_PLAYER, "AMX_SUPER_AMMO_PLAYER_CASE2", name, name2, setting)
			case 1:	client_print(0, print_chat, "%L", LANG_PLAYER, "AMX_SUPER_AMMO_PLAYER_CASE1", name2, setting)
		}
		console_print(id, "%L", LANG_PLAYER, "AMX_SUPER_AMMO_PLAYER_MSG", name2, setting)
		log_amx("%L", LANG_SERVER, "AMX_SUPER_AMMO_PLAYER_LOG", name, authid, name2, authid2, setting)
	}
	return PLUGIN_HANDLED
}

public reloadAmmo(id)
{
	if (!is_user_connected(id)) return;

	if (gReloadTime[id] >= get_systime() - 1) return;
	gReloadTime[id] = get_systime();

	new clip, ammo, wpn[32];
	new wpnid = get_user_weapon(id, clip, ammo);

	if (wpnid == CSW_C4 || wpnid == CSW_KNIFE || wpnid == 0) return;
	if (wpnid == CSW_HEGRENADE || wpnid == CSW_SMOKEGRENADE || wpnid == CSW_FLASHBANG) return;

	if (clip == 0)
	{
		get_weaponname(wpnid,wpn,31);
		new iWPNidx = -1;
		while((iWPNidx = fm_find_ent_by_class(iWPNidx, wpn)) != 0)
		{
			if(id == pev(iWPNidx, pev_owner))
			{
				cs_set_weapon_ammo(iWPNidx, getMaxClipAmmo(wpnid));
				break;
			}
		}
	}
}

stock getMaxClipAmmo(wpnid)
{
	new clipammo = 0;
	switch (wpnid)
	{
		case CSW_P228 : clipammo = 13;
		case CSW_SCOUT : clipammo = 10;
		case CSW_HEGRENADE : clipammo = 0;
		case CSW_XM1014 : clipammo = 7;
		case CSW_C4 : clipammo = 0;
		case CSW_MAC10 : clipammo = 30;
		case CSW_AUG : clipammo = 30;
		case CSW_SMOKEGRENADE : clipammo = 0;
		case CSW_ELITE : clipammo = 15;
		case CSW_FIVESEVEN : clipammo = 20;
		case CSW_UMP45 : clipammo = 25;
		case CSW_SG550 : clipammo = 30;
		case CSW_GALI : clipammo = 35;
		case CSW_FAMAS : clipammo = 25;
		case CSW_USP : clipammo = 12;
		case CSW_GLOCK18 : clipammo = 20;
		case CSW_AWP : clipammo = 10;
		case CSW_MP5NAVY : clipammo = 30;
		case CSW_M249 : clipammo = 100;
		case CSW_M3 : clipammo = 8;
		case CSW_M4A1 : clipammo = 30;
		case CSW_TMP : clipammo = 30;
		case CSW_G3SG1 : clipammo = 20;
		case CSW_FLASHBANG : clipammo = 0;
		case CSW_DEAGLE : clipammo = 7;
		case CSW_SG552 : clipammo = 30;
		case CSW_AK47 : clipammo = 30;
		case CSW_KNIFE : clipammo = 0;
		case CSW_P90 : clipammo = 50;
	}
	return clipammo;
}


////////////////////////////////////////////////////////////////////////////////////////////////////////////
//TEAM/PLAYER TRANSFER v1.0 by Doombringer/Deviance
//==========================================================================================================
public cmd_transfer(id, level, cid)
{
	if (!cmd_access(id, level, cid, 2))
	return PLUGIN_HANDLED

	new arg1[32], arg2[32]

	read_argv(1, arg1, 31)
	read_argv(2, arg2, 31)

	new player = cmd_target(id, arg1, 2)

	if(!player)
		return PLUGIN_HANDLED

	new teamname[32]

	if(!strlen(arg2))
	{
		cs_set_user_team(player, cs_get_user_team(player) == CS_TEAM_CT ? CS_TEAM_T:CS_TEAM_CT)
		teamname = cs_get_user_team(player) == CS_TEAM_CT ? "Counter-Terrorists":"Terrorists"
	}
	else
	{
		if(equali(arg2, "T"))
		{
			cs_set_user_team(player, CS_TEAM_T)
			teamname = "Terrorists"
			fm_DispatchSpawn(player)
		}
		else if(equali(arg2, "CT"))
		{
			cs_set_user_team(player, CS_TEAM_CT)
			teamname = "Counter-Terrorists"
			fm_DispatchSpawn(player)
		}
		else if(equali(arg2, "SPEC"))
		{
			user_silentkill(player)
			cs_set_user_team(player, CS_TEAM_SPECTATOR)

			teamname = "Spectator"
		}
		else
		{
			client_print(id, print_console, "%L", LANG_PLAYER, AMX_SUPER_TEAM_INVALID)
			return PLUGIN_HANDLED
		}
	}

	new name[32], admin[32], authid[35]

	get_user_name(id, admin, 31)
	get_user_name(player, name, 31)

	get_user_authid(id, authid, 34)

	switch(get_pcvar_num(amx_show_activity))
	{
		case 2:	client_print(0, print_chat, "%L", LANG_PLAYER, "AMX_SUPER_TRANSFER_PLAYER_CASE2", admin, name, teamname)
		case 1:	client_print(0, print_chat, "%L", LANG_PLAYER, "AMX_SUPER_TRANSFER_PLAYER_CASE1", name, teamname)
	}

	client_print(player, print_chat, "%L", LANG_PLAYER, "AMX_SUPER_TRANSFER_PLAYER_TEAM", teamname)

	console_print(id, "%L", LANG_PLAYER, "AMX_SUPER_TRANSFER_PLAYER_CONSOLE", name, teamname)
	log_amx("%L", LANG_SERVER, "AMX_SUPER_TRANSFER_PLAYER_LOG", admin, authid, name, teamname)
	return PLUGIN_HANDLED
}

public cmd_swap(id, level, cid)
{
	if (!cmd_access(id, level, cid, 3))
	return PLUGIN_HANDLED

	new arg1[32], arg2[32]

	read_argv(1, arg1, 31)
	read_argv(2, arg2, 31)

	new player = cmd_target(id, arg1, 2)
	new player2 = cmd_target(id, arg2, 2)

	if(!player || !player2)
	return PLUGIN_HANDLED

	new CsTeams:team = cs_get_user_team(player)
	new CsTeams:team2 = cs_get_user_team(player2)

	if(team == team2)
	{
		client_print(id, print_console, "%L", LANG_PLAYER, "AMX_SUPER_TRANSFER_PLAYER_ERROR_CASE1")
		return PLUGIN_HANDLED
	}

	if(team == CS_TEAM_UNASSIGNED || team2 == CS_TEAM_UNASSIGNED)
	{
		client_print(id, print_console, "%L", LANG_PLAYER, "AMX_SUPER_TRANSFER_PLAYER_ERROR_CASE2")
		return PLUGIN_HANDLED
	}

	if(team == CS_TEAM_SPECTATOR)
		user_silentkill(player2)

	else if(team2 == CS_TEAM_SPECTATOR)
		user_silentkill(player)

	cs_set_user_team(player, team2)
	fm_DispatchSpawn(player)
	cs_set_user_team(player2, team)
	fm_DispatchSpawn(player2)

	new name[32], name2[32], admin[32], authid[35]

	get_user_name(id, admin, 31)
	get_user_name(player, name, 31)
	get_user_name(player2, name2, 31)

	get_user_authid(id, authid, 34)

	switch(get_pcvar_num(amx_show_activity)) {
		case 2:	client_print(0,print_chat,"%L", LANG_PLAYER, "AMX_SUPER_TRANSFER_SWAP_PLAYERS_SUCCESS_CASE2",admin,name,name2)
		case 1:	client_print(0, print_chat,"%L", LANG_PLAYER, "AMX_SUPER_TRANSFER_SWAP_PLAYERS_SUCCESS_CASE1", name, name2);
	}

	client_print(player, print_chat, "%L", LANG_PLAYER, "AMX_SUPER_TRANSFER_SWAP_PLAYERS_MESSAGE1", name2)
	client_print(player2, print_chat, "%L", LANG_PLAYER, "AMX_SUPER_TRANSFER_SWAP_PLAYERS_MESSAGE2", name)

	client_print(id, print_console, "%L", LANG_PLAYER, "AMX_SUPER_TRANSFER_SWAP_PLAYERS_CONSOLE", name, name2)
	log_amx("%L", LANG_PLAYER, "AMX_SUPER_TRANSFER_SWAP_PLAYERS_LOG", admin, authid, name, name2)

	return PLUGIN_HANDLED
}

public cmd_teamswap(id, level, cid)
{
	if (!cmd_access(id, level, cid, 1))
	return PLUGIN_HANDLED

	new players[32], num
	get_players(players, num)

	new player
	for(new i = 0; i < num; i++)
	{
		player = players[i]
		cs_set_user_team(player, cs_get_user_team(player) == CS_TEAM_T ? CS_TEAM_CT:CS_TEAM_T)
		fm_DispatchSpawn(player)
	}

	new name[32], authid[35]

	get_user_name(id, name, 31)
	get_user_authid(id, authid, 34)

	switch(get_pcvar_num(amx_show_activity)) {
		case 2:	client_print(0,print_chat,"%L", LANG_PLAYER, "AMX_SUPER_TRANSFER_SWAP_TEAM_SUCCESS_CASE2",name)
		case 1:	client_print(0,print_chat,"%L", LANG_PLAYER, "AMX_SUPER_TRANSFER_SWAP_TEAM_SUCCESS_CASE1")
	}

	console_print(id,"%L", LANG_PLAYER, "AMX_SUPER_TRANSFER_SWAP_TEAM_MESSAGE")
	log_amx("%L", LANG_SERVER, "AMX_SUPER_TRANSFER_SWAP_TEAM_LOG", name,authid)

	return PLUGIN_HANDLED
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////
//TEAM LOCKER v1.3 by Bmann_420
//Revised by Doombringer/Deviance
//==========================================================================================================
public admin_unlock(id, level, cid)
{
	if(!cmd_access(id, level, cid, 2))
	return PLUGIN_HANDLED

	new Arg1[6]

	read_argv(1, Arg1, 5)

	if(!equali(Arg1, "T") && !equali(Arg1, "CT") && !equali(Arg1, "Auto") && !equali(Arg1, "Spec"))
	{
		client_print(id, print_console, "%L", LANG_PLAYER, AMX_SUPER_TEAM_INVALID)
		return PLUGIN_HANDLED
	}

	new team

	if(equali(Arg1, "T"))
		team = TE
	else if(equali(Arg1, "CT"))
		team = CT
	else if(equali(Arg1, "Auto"))
		team = AUTO
	else if(equali(Arg1, "Spec"))
		team = SPEC

	blockjoining[team] = false

	new name[32], steamid[38]

	get_user_name(id, name, 31)
	get_user_authid(id, steamid, 37)

	switch(get_pcvar_num(amx_show_activity)) {
		case 2:	client_print(0,print_chat,"%L", LANG_PLAYER, "AMX_SUPER_TEAM_UNLOCK_CASE2",name,Teamnames[team])
		case 1:	client_print(0,print_chat,"%L", LANG_PLAYER, "AMX_SUPER_TEAM_UNLOCK_CASE1",Teamnames[team])
	}

	console_print(id,"%L", LANG_PLAYER, "AMX_SUPER_TEAM_UNLOCK_CONSOLE",Teamnames[team])
	log_amx("%L", LANG_SERVER, "AMX_SUPER_UNLOCK_TEAMS_LOG", name,steamid,Teamnames[team])

	return PLUGIN_HANDLED
}

public admin_lock(id, level, cid)
{
	if(!cmd_access(id, level, cid, 2))
	return PLUGIN_HANDLED

	new Arg1[6]

	read_argv(1, Arg1, 5)

	if(!equali(Arg1, "T") && !equali(Arg1, "CT") && !equali(Arg1, "Auto") && !equali(Arg1, "Spec"))
	{
		client_print(id, print_console, "%L", LANG_PLAYER, AMX_SUPER_TEAM_INVALID)
		return PLUGIN_HANDLED
	}

	new team

	if(equali(Arg1, "T"))
		team = TE
	else if(equali(Arg1, "CT"))
		team = CT
	else if(equali(Arg1, "Auto"))
		team = AUTO
	else if(equali(Arg1, "Spec"))
		team = SPEC

	blockjoining[team] = true

	new name[32], steamid[38]

	get_user_name(id, name, 31)
	get_user_authid(id, steamid, 37)

	switch(get_pcvar_num(amx_show_activity)) {
		case 2:	client_print(0,print_chat,"%L", LANG_PLAYER, "AMX_SUPER_TEAM_LOCK_CASE2",name,Teamnames[team])
		case 1:	client_print(0,print_chat,"%L", LANG_PLAYER, "AMX_SUPER_TEAM_LOCK_CASE1",Teamnames[team])
	}

	console_print(id,"%L", LANG_PLAYER, "AMX_SUPER_TEAM_LOCK_CONSOLE",Teamnames[team])
	log_amx("%L", LANG_SERVER, "AMX_SUPER_LOCK_TEAMS_LOG", name,steamid,Teamnames[team])

	return PLUGIN_HANDLED
}

public team_select(id, key)
{
	if ( blockjoining[key] == true )
	{
		engclient_cmd(id, "chooseteam")
		return PLUGIN_HANDLED
	}

	return PLUGIN_CONTINUE
}

public join_team(id)
{
        if (get_user_flags(id) & ( ADMIN_KICK | ADMIN_LEVEL_A ))
	{
		remove_task(id)
		return PLUGIN_CONTINUE
	}

	new arg[2]
        read_argv(1, arg, 1)

        if (blockjoining[str_to_num(arg)-1] == true)
	{
                engclient_cmd(id, "chooseteam")
                return PLUGIN_HANDLED
        }

        return PLUGIN_CONTINUE
}


////////////////////////////////////////////////////////////////////////////////////////////////////////////
//ADMIN REVIVE II v0.1 by SniperBeamer
//Revised by Bo0m!
//==========================================================================================================
public admin_revive(id,level,cid)
{
	if (!cmd_access(id,level,cid,2))
		return PLUGIN_HANDLED

	new arg[32]
	new name[32], name2[32], authid[35], authid2[35]
	read_argv(1,arg,31)
	get_user_name(id,name,31)
	get_user_authid(id,authid,34)

	if (arg[0]=='@'){
		new players[32], inum
		if (equali("T",arg[1]))		copy(arg[1],31,"TERRORIST")
		if (equali("ALL",arg[1]))	get_players(players,inum)
		else						get_players(players,inum,"e",arg[1])

		if (inum == 0) {
			console_print(id,"%L", LANG_PLAYER, AMX_SUPER_NO_PLAYERS)
			return PLUGIN_HANDLED
		}

		for(new a = 0;a < inum; a++) {
			if (get_user_flags(players[a]) & ADMIN_IMMUNITY && players[a] != id) {
				get_user_name(players[a],name2,31)
				console_print(id,"%L", LANG_PLAYER, AMX_SUPER_TEAM_IMMUNITY,name2)
				continue
				}

			new ids[3]
			num_to_str(players[a],ids,2)
			//fm_DispatchSpawn(players[a])
			ExecuteHamB(Ham_CS_RoundRespawn, players[a])
			set_task(0.1,"revivePl",0,ids,2)

			if (get_pcvar_num(sv_sp) == 1)
			{
				set_task(0.1, "protect", id)
			}
		}

		switch(get_pcvar_num(amx_show_activity))	{
			case 2:	client_print(0,print_chat,"%L", LANG_PLAYER, "AMX_SUPER_REVIVE_TEAM_CASE2",name,arg[1])
			case 1:	client_print(0,print_chat,"%L", LANG_PLAYER, "AMX_SUPER_REVIVE_TEAM_CASE1",arg[1])
		}

		console_print(id,"%L", LANG_PLAYER, "AMX_SUPER_REVIVE_TEAM_MSG",arg[1])
		log_amx("%L", LANG_SERVER, "AMX_SUPER_REVIVE_TEAM_LOG",name,authid,arg[1])

		if (get_pcvar_num(revivemsg))
		{
			if (equali(arg[1],"CT")) set_hudmessage(0,20,220,-1.0,0.30,0,6.0,6.0,0.5,0.15,1)
			else set_hudmessage(220,20,0,-1.0,0.30,0,6.0,6.0,0.5,0.15,1)
			show_hudmessage(0,"%L", LANG_PLAYER, "AMX_SUPER_REVIVE_TEAM_HUD",arg[1])
		}
	}
	else
	{
		new player = cmd_target(id,arg,3)
		if (!player) return PLUGIN_HANDLED

		new ids[3]
		num_to_str(player,ids,2)
		//fm_DispatchSpawn(player)
		ExecuteHamB(Ham_CS_RoundRespawn, player)
		set_task(0.1,"revivePl",0,ids,2)

		if (get_pcvar_num(sv_sp) == 1)
		{
			set_task(0.1, "protect", id)
		}

		get_user_name(player,name2,31)
		get_user_authid(player,authid2,34)

		switch(get_pcvar_num(amx_show_activity))	{
			case 2:	client_print(0,print_chat,"%L", LANG_PLAYER, "AMX_SUPER_REVIVE_PLAYER_CASE2",name,name2)
			case 1:	client_print(0,print_chat,"%L", LANG_PLAYER, "AMX_SUPER_REVIVE_PLAYER_CASE1",name2)
		}
		console_print(id,"%L", LANG_PLAYER, "AMX_SUPER_REVIVE_PLAYER_MSG",name2)
		log_amx("%L", LANG_SERVER, "AMX_SUPER_REVIVE_PLAYER_LOG",name,authid,name2,authid2)

		if (get_pcvar_num(revivemsg))
		{
			set_hudmessage(0,200,0,-1.0,0.30,0,6.0,6.0,0.5,0.15,1)
			show_hudmessage(0,"%L", LANG_PLAYER, "AMX_SUPER_REVIVE_PLAYER_HUD",name2)
		}
	}

	return PLUGIN_HANDLED
}

public revivePl(ids[])
{
	new id = str_to_num(ids)
	fm_DispatchSpawn(id)
	if (get_user_team(id)==1)
	{
		fm_give_item(id,weapons[WEAPON_KNIFE])
		fm_give_item(id,weapons[WEAPON_GLOCK18])
		fm_give_item_x(id,ammo_9mm,2)
	}
	else
	{
		fm_give_item(id,weapons[WEAPON_KNIFE])
		fm_give_item(id,weapons[WEAPON_USP])
		fm_give_item_x(id,ammo_45acp,2)
	}
}


////////////////////////////////////////////////////////////////////////////////////////////////////////////
//ADMIN TELEPORT v0.9.3 by f117bomb
//Revised by JTP10181
//==========================================================================================================
new g_savedOrigin[3] = {0,0,0}

public admin_teleport(id,level,cid)
{
	if (!cmd_access(id,level,cid,2)) return PLUGIN_HANDLED

	new arg[32], sx[8], sy[8], sz[8], origin[3]
	new name[32], name2[32], authid[36], authid2[36]

	read_argv(1,arg,31)
	get_user_name(id,name,31)
	get_user_authid(id,authid,35)

	if (read_argc() > 2) {
		read_argv(2,sx,7)
		read_argv(3,sy,7)
		read_argv(4,sz,7)
		origin[0] = str_to_num(sx)
		origin[1] = str_to_num(sy)
		origin[2] = str_to_num(sz)
	}
	else {
		origin = g_savedOrigin
	}

	new player = cmd_target(id,arg,7)
	if (!player) return PLUGIN_HANDLED

	fm_set_user_origin(player, origin)

	get_user_name(player,name2,31)
	get_user_authid(player,authid2,35)

	switch(get_pcvar_num(amx_show_activity)) {
		case 2:	client_print(0,print_chat,"%L", LANG_PLAYER, "AMX_SUPER_TELEPORT_PLAYER_CASE2",name,name2)
		case 1:	client_print(0,print_chat,"%L", LANG_PLAYER, "AMX_SUPER_TELEPORT_PLAYER_CASE1",name2)
	}

	console_print(id,"%L", LANG_PLAYER, "AMX_SUPER_TELEPORT_PLAYER_MSG",name2,origin[0],origin[1],origin[2])
	log_amx("%L", LANG_SERVER, "AMX_SUPER_TELEPORT_PLAYER_LOG",name,authid,name2,authid2,origin[0],origin[1],origin[2])

	return PLUGIN_HANDLED
}

public admin_userorigin(id,level,cid) {

	if (!cmd_access(id,level,cid,2)) return PLUGIN_HANDLED

	new arg[32], name[32]
	read_argv(1,arg,31)

	new player = cmd_target(id,arg,2)
	if (!player) return PLUGIN_HANDLED

	get_user_origin(player, g_savedOrigin)
	get_user_name(player,name,31)

	console_print(id,"%L", LANG_PLAYER, "AMX_SUPER_TELEPORT_ORIGIN_SAVED",g_savedOrigin[0],g_savedOrigin[1],g_savedOrigin[2],name)

	return PLUGIN_HANDLED
}


////////////////////////////////////////////////////////////////////////////////////////////////////////////
//ADMIN HEAL v0.9.3 by f117bomb
//Revised by JTP10181
//==========================================================================================================
public admin_heal(id,level,cid)
{
	if (!cmd_access(id,level,cid,3))
		return PLUGIN_HANDLED

	new arg[32], arg2[8]
	new name[32], name2[32], authid[36], authid2[36]
	read_argv(1,arg,31)
	read_argv(2,arg2,7)
	get_user_name(id,name,31)
	get_user_authid(id,authid,35)
	new hpGive = str_to_num(arg2)

	if (hpGive <= 0) {
		console_print(id,"%L", LANG_PLAYER, AMX_SUPER_AMOUNT_GREATER)
		return PLUGIN_HANDLED
	}

	if (arg[0]=='@'){
		new players[32], inum
		if (equali("T",arg[1]))		copy(arg[1],31,"TERRORIST")
		if (equali("ALL",arg[1]))	get_players(players,inum)
		else						get_players(players,inum,"e",arg[1])

		if (inum == 0) {
			console_print(id,"%L", LANG_PLAYER, AMX_SUPER_NO_PLAYERS)
			return PLUGIN_HANDLED
		}

		for(new a = 0;a < inum; a++) {
			new user_health = get_user_health(players[a])
			fm_set_user_health(players[a], hpGive + user_health)
		}

		switch(get_pcvar_num(amx_show_activity))	{
			case 2:	client_print(0,print_chat,"%L", LANG_PLAYER, "AMX_SUPER_HEAL_TEAM_CASE2",name,hpGive,arg[1])
			case 1:	client_print(0,print_chat,"%L", LANG_PLAYER, "AMX_SUPER_HEAL_TEAM_CASE1",hpGive,arg[1])
		}

		console_print(id,"%L", LANG_PLAYER, "AMX_SUPER_HEAL_TEAM_MSG",hpGive,arg[1])
		log_amx("%L", LANG_SERVER, "AMX_SUPER_HEAL_TEAM_LOG", name,authid,hpGive,arg[1])
	}
	else {

		new player = cmd_target(id,arg,6)
		if (!player) return PLUGIN_HANDLED

		new user_health = get_user_health(player)
		fm_set_user_health(player, hpGive + user_health)

		get_user_name(player,name2,31)
		get_user_authid(player,authid2,35)

		switch(get_pcvar_num(amx_show_activity)) {
			case 2:	client_print(0,print_chat,"%L", LANG_PLAYER, "AMX_SUPER_HEAL_PLAYER_CASE2",name,hpGive,name2)
			case 1:	client_print(0,print_chat,"%L", LANG_PLAYER, "AMX_SUPER_HEAL_PLAYER_CASE1",hpGive,name2)
		}

		console_print(id,"%L", LANG_PLAYER, "AMX_SUPER_HEAL_PLAYER_MSG",hpGive,name2)
		log_amx("%L", LANG_SERVER, "AMX_SUPER_HEAL_PLAYER_LOG", name,authid,hpGive,name2,authid2)
	}
	return PLUGIN_HANDLED
}


////////////////////////////////////////////////////////////////////////////////////////////////////////////
//ADMIN ARMOR v1.0 by JTP10181
//==========================================================================================================
public admin_armor(id,level,cid)
{
	if (!cmd_access(id,level,cid,3))
		return PLUGIN_HANDLED

	new arg[32], arg2[8]
	new name[32], name2[32], authid[36], authid2[36]
	read_argv(1,arg,31)
	read_argv(2,arg2,7)
	get_user_name(id,name,31)
	get_user_authid(id,authid,35)
	new armorGive = str_to_num(arg2)

	if (armorGive <= 0) {
		console_print(id,"%L", LANG_PLAYER, AMX_SUPER_AMOUNT_GREATER)
		return PLUGIN_HANDLED
	}

	if (arg[0]=='@'){
		new players[32], inum
		if (equali("T",arg[1]))		copy(arg[1],31,"TERRORIST")
		if (equali("ALL",arg[1]))	get_players(players,inum)
		else						get_players(players,inum,"e",arg[1])

		if (inum == 0) {
			console_print(id,"%L", LANG_PLAYER, AMX_SUPER_NO_PLAYERS)
			return PLUGIN_HANDLED
		}

		for(new a = 0;a < inum; a++) {
			new user_armor = get_user_armor(players[a])

			//Give the armor item first so CS knows the player has armor
			if (user_armor <= 0) fm_give_item(players[a], "item_assaultsuit")

			//Set the armor to the new ammount
			fm_set_user_armor(players[a], armorGive + user_armor)
		}

		switch(get_pcvar_num(amx_show_activity))	{
			case 2:	client_print(0,print_chat,"%L", LANG_PLAYER, "AMX_SUPER_ARMOR_TEAM_CASE2",name,armorGive,arg[1])
			case 1:	client_print(0,print_chat,"%L", LANG_PLAYER, "AMX_SUPER_ARMOR_TEAM_CASE1",armorGive,arg[1])
		}

		console_print(id,"%L", LANG_PLAYER, "AMX_SUPER_ARMOR_TEAM_MSG",armorGive,arg[1])
		log_amx("%L", LANG_SERVER, "AMX_SUPER_ARMOR_TEAM_LOG", name,authid,armorGive,arg[1])
	}
	else {

		new player = cmd_target(id,arg,6)
		if (!player) return PLUGIN_HANDLED

		new user_armor = get_user_armor(player)

		//Give the armor item first so CS knows the player has armor
		if (user_armor <= 0) fm_give_item(player, "item_assaultsuit")

		//Set the armor to the new ammount
		fm_set_user_armor(player, armorGive + user_armor)

		get_user_name(player,name2,31)
		get_user_authid(player,authid2,35)

		switch(get_pcvar_num(amx_show_activity)) {
			case 2:	client_print(0,print_chat,"%L", LANG_PLAYER, "AMX_SUPER_ARMOR_PLAYER_CASE2",name,armorGive,name2)
			case 1:	client_print(0,print_chat,"%L", LANG_PLAYER, "AMX_SUPER_ARMOR_PLAYER_CASE1",armorGive,name2)
		}

		console_print(id,"%L", LANG_PLAYER, "AMX_SUPER_ARMOR_PLAYER_MSG",armorGive,name2)
		log_amx("%L", LANG_SERVER, "AMX_SUPER_ARMOR_PLAYER_LOG", name,authid,armorGive,name2,authid2)
	}
	return PLUGIN_HANDLED
}


////////////////////////////////////////////////////////////////////////////////////////////////////////////
//ADMIN GODMODE v1.0 by Bo0m!
//Revised some by Doombringer/Deviance
//==========================================================================================================
public admin_godmode(id,level,cid)
{

	if (!cmd_access(id,level,cid,3))
		return PLUGIN_HANDLED

	new arg[32], arg2[8], name2[32]

	read_argv(1, arg, 31)
	read_argv(2, arg2, 7)

	new setting = str_to_num(arg2)

	new name[32], authid[36]

	get_user_name(id, name2, 31)
	get_user_authid(id, authid, 35)

	new bool:l_postRound = false;
	if(str_to_num(arg2) == 2)

	{
		arg2 = "1";
		l_postRound = true;
	}

	if (arg[0]=='@'){

		new players[32], inum

		if(!(arg[1]=='a' || arg[1]=='A' || arg[1]=='C' || arg[1]=='c' || arg[1]=='T' || arg[1]=='t'))
		inum = 0

		else

		get_players(players,inum,"")

		if (inum==0)
		{
			console_print(id,"%L", LANG_PLAYER, AMX_SUPER_NO_PLAYERS)
			return PLUGIN_HANDLED
		}

		for(new a=0;a<inum;++a)
		{
			if((arg[1]=='a' || arg[1]=='A') || (cs_get_user_team(players[a]) == CS_TEAM_T && (arg[1]=='T' || arg[1]=='t')) || (cs_get_user_team(players[a]) == CS_TEAM_CT && (arg[1]=='C' || arg[1]=='c')))

		{
			fm_set_user_godmode(players[a],str_to_num(arg2))
			HasPermGod[players[a]] = l_postRound;
		}

		}
		switch(get_pcvar_num(amx_show_activity))
		{
			case 2:	client_print(0, print_chat, "%L", LANG_PLAYER, "AMX_SUPER_GODMODE_TEAM_CASE2", name, setting, arg[1])
			case 1:	client_print(0, print_chat, "%L", LANG_PLAYER, "AMX_SUPER_GODMODE_TEAM_CASE1", setting, arg[1])
		}

		console_print(id, "%L", LANG_PLAYER, "AMX_SUPER_GODMODE_TEAM_MSG", setting, arg[1])
		log_amx("%L", LANG_SERVER, "AMX_SUPER_GODMODE_TEAM_LOG", name, authid, setting, arg[1])
	}
	else
	{
		new authid2[36]

		new player = cmd_target(id, arg, 3)

		if(!player)
			return PLUGIN_HANDLED

		get_user_name(player, name2, 31)
		get_user_authid(player, authid2, 35)

		fm_set_user_godmode(player,str_to_num(arg2))
		HasPermGod[player] = l_postRound;

		switch(get_pcvar_num(amx_show_activity))
		{
			case 2:	client_print(0, print_chat, "%L", LANG_PLAYER, "AMX_SUPER_GODMODE_PLAYER_CASE2", name, setting, name2)
			case 1:	client_print(0, print_chat, "%L", LANG_PLAYER, "AMX_SUPER_GODMODE_PLAYER_CASE1", setting, name2)
		}

		console_print(id, "%L", LANG_PLAYER, "AMX_SUPER_GODMODE_PLAYER_MSG", setting, name2)
		log_amx("%L", LANG_SERVER, "AMX_SUPER_GODMODE_PLAYER_LOG", name, authid, setting, name2, authid2)
	}
	return PLUGIN_HANDLED
}



////////////////////////////////////////////////////////////////////////////////////////////////////////////
//ADMIN NOCLIP v1.0 by Bo0m!
//==========================================================================================================
public admin_noclip(id,level,cid)
{
	if (!cmd_access(id,level,cid,3))
		return PLUGIN_HANDLED

	new arg[32], arg2[8]
	new name[32], name2[32], authid[36], authid2[36]
	read_argv(1,arg,31)
	read_argv(2,arg2,7)
	get_user_name(id,name,31)
	get_user_authid(id,authid,35)

	new noclipsetting = str_to_num(arg2)

	new bool:PermNoclip = false
	if(noclipsetting == 2)
	{
		arg2 = "1"
		PermNoclip = true
	}

	if (arg[0]=='@'){
		new players[32], inum
		if (equali("T",arg[1]))		copy(arg[1],31,"TERRORIST")
		if (equali("ALL",arg[1]))	get_players(players,inum)
		else						get_players(players,inum,"e",arg[1])

		if (inum == 0) {
			console_print(id,"%L", LANG_PLAYER, AMX_SUPER_NO_PLAYERS)
			return PLUGIN_HANDLED
		}

		for(new a = 0;a < inum; a++) {
			fm_set_user_noclip(players[a],str_to_num(arg2))
			HasPermNoclip[players[a]] = PermNoclip
		}

		switch(get_pcvar_num(amx_show_activity))	{
			case 2:	client_print(0,print_chat,"%L", LANG_PLAYER, "AMX_SUPER_NOCLIP_TEAM_CASE2",name,noclipsetting,arg[1])
			case 1:	client_print(0,print_chat,"%L", LANG_PLAYER, "AMX_SUPER_NOCLIP_TEAM_CASE1",noclipsetting,arg[1])
		}
		console_print(id,"%L", LANG_PLAYER, "AMX_SUPER_NOCLIP_TEAM_MSG",noclipsetting,arg[1])
		log_amx("%L", LANG_SERVER, "AMX_SUPER_NOCLIP_TEAM_LOG", name,authid,noclipsetting,arg[1])
	}
	else {

		new player = cmd_target(id,arg,7)
		if (!player) return PLUGIN_HANDLED

		get_user_name(player,name2,31)
		get_user_authid(player,authid2,35)


		fm_set_user_noclip(player,str_to_num(arg2))
		HasPermNoclip[player] = PermNoclip

		switch(get_pcvar_num(amx_show_activity)) {
			case 2:	client_print(0,print_chat,"%L", LANG_PLAYER, "AMX_SUPER_NOCLIP_PLAYER_CASE2",name,noclipsetting,name2)
			case 1:	client_print(0,print_chat,"%L", LANG_PLAYER, "AMX_SUPER_NOCLIP_PLAYER_CASE1",noclipsetting,name2)
		}

		console_print(id,"%L", LANG_PLAYER, "AMX_SUPER_NOCLIP_PLAYER_MSG",noclipsetting,name2)
		log_amx("%L", LANG_SERVER, "AMX_SUPER_NOCLIP_PLAYER_LOG", name,authid,noclipsetting,name2,authid2)
	}
	return PLUGIN_HANDLED
}


////////////////////////////////////////////////////////////////////////////////////////////////////////////
//ADMIN STACK v0.9.3 by f117bomb
//==========================================================================================================
public admin_stack(id,level,cid)
{
	if (!cmd_access(id,level,cid,2)) return PLUGIN_HANDLED

	new arg[32]
	new name[32], name2[32], authid[36], authid2[36]
	read_argv(1,arg,31)
	get_user_name(id,name,31)
	get_user_authid(id,authid,35)

	new player = cmd_target(id,arg,7)
	if (!player) return PLUGIN_HANDLED

	new sttype[2], origin[3], inum, players[32]
	read_argv(2,sttype,1)
	get_user_origin(player, origin)
	get_players(players,inum,"a")

	new offsety = 36, offsetz = 96
	switch( str_to_num(sttype) ) {
		case 0: offsety = 0
		case 1: offsetz = 0
	}

	for(new a = 0 ; a < inum ; a++) {
		if ((players[a] == player) || (get_user_flags(players[a])&ADMIN_IMMUNITY) && players[a] != id) continue
		origin[1] += offsety
		origin[2] += offsetz
		fm_set_user_origin(players[a], origin)
	}

	get_user_name(player,name2,32)
	get_user_authid(player,authid2,35)

	switch(get_pcvar_num(amx_show_activity)) {
		case 2:	client_print(0,print_chat,"%L", LANG_PLAYER, "AMX_SUPER_STACK_PLAYER_CASE2",name,name2)
		case 1:	client_print(0,print_chat,"%L", LANG_PLAYER, "AMX_SUPER_STACK_PLAYER_CASE1",name2)
	}

	console_print(id,"%L", LANG_PLAYER, "AMX_SUPER_STACK_PLAYER_MSG", name2)
	log_amx("%L", LANG_SERVER, "AMX_SUPER_STACK_PLAYER_LOG",name,authid,name2,authid2)

	return PLUGIN_HANDLED
}


////////////////////////////////////////////////////////////////////////////////////////////////////////////
//ADMIN MONEY v1.0 by XxAvalanchexX with additions from Bo0m!
//==========================================================================================================
public admin_givemoney(id,level,cid)
{
	if(!cmd_access(id,level,cid,3))
		return PLUGIN_HANDLED

	new arg[32], arg2[32]
	read_argv(1,arg,32)
	read_argv(2,arg2,31)

	new adminAuthid[36], adminName[32]
	get_user_authid(id,adminAuthid,35)
	get_user_name(id,adminName,31)

	new amount = str_to_num(arg2)
	if(amount < 0) {
		console_print(id,"%L", LANG_PLAYER, AMX_SUPER_AMOUNT_GREATER)
		return PLUGIN_HANDLED
	}

	if(arg[0] == '@')
	{
		new players[32], pnum, i;
		if(containi(arg, "ALL") != -1) get_players(players, pnum)
		else get_players(players, pnum, "ae", (containi(arg, "CT") != -1) ? "CT" : "TERRORIST");
		if(!pnum) return PLUGIN_HANDLED;
		new pid, money;
		for(i = 0; i < pnum; i++)
		{
			pid = players[i];
			money = amount + cs_get_user_money(pid);
			if(money > 16000) money = 16000;
			cs_set_user_money(pid, money)
		}
		switch(get_pcvar_num(amx_show_activity))
		{
			case 2: client_print(0, print_chat, "%L", LANG_PLAYER, "AMX_SUPER_GIVEMONEY_TEAM_CASE2", adminName, amount, arg[1]);
			case 1: client_print(0, print_chat, "%L", LANG_PLAYER, "AMX_SUPER_GIVEMONEY_TEAM_CASE1", amount, arg[1]);
		}
		console_print(id, "%L", LANG_PLAYER, "AMX_SUPER_GIVEMONEY_TEAM_MSG", amount, arg[1]);
		log_amx("%L", LANG_SERVER, "AMX_SUPER_GIVEMONEY_TEAM_LOG", adminName, adminAuthid, amount, arg[1]);
	}
	else
	{

		new player = cmd_target(id,arg,2)
		if(!player) return PLUGIN_HANDLED

		new playerName[32]
		get_user_name(player,playerName,31)

		new playerAuthid[36]
		get_user_authid(player,playerAuthid,35)

		cs_set_user_money(player,cs_get_user_money(player)+amount)

		switch(get_pcvar_num(amx_show_activity))
		{
			case 2: client_print(0,print_chat,"%L", LANG_PLAYER, "AMX_SUPER_GIVEMONEY_PLAYER_CASE2",adminName,amount,playerName)
			case 1: client_print(0,print_chat,"%L", LANG_PLAYER, "AMX_SUPER_GIVEMONEY_PLAYER_CASE1",amount,playerName)
		}

		console_print(id,"%L", LANG_PLAYER, "AMX_SUPER_GIVEMONEY_PLAYER_MSG",amount,playerName,amount)
		log_amx("%L", LANG_SERVER, "AMX_SUPER_GIVEMONEY_PLAYER_LOG",adminName,adminAuthid,amount,playerName,playerAuthid)

	}
	return PLUGIN_HANDLED
}

public admin_takemoney(id,level,cid)
{
	if(!cmd_access(id,level,cid,3))
		return PLUGIN_HANDLED

	new arg[32], arg2[32]
	read_argv(1,arg,32)
	read_argv(2,arg2,31)

	new player = cmd_target(id,arg,2)
	if(!player) return PLUGIN_HANDLED

	new playerName[32], adminName[32]
	get_user_name(player,playerName,31)
	get_user_name(id,adminName,31)

	new playerAuthid[36], adminAuthid[36]
	get_user_authid(player,playerAuthid,35)
	get_user_authid(id,adminAuthid,35)

	new amount = str_to_num(arg2)

	if(amount < 0) {
		console_print(id,"%L", LANG_PLAYER, AMX_SUPER_AMOUNT_GREATER)
		return PLUGIN_HANDLED
	}

	if (amount > cs_get_user_money(player)) {
		cs_set_user_money(player,0)

		switch(get_pcvar_num(amx_show_activity))
		{
			case 2: client_print(0,print_chat,"%L", LANG_PLAYER, "AMX_SUPER_TAKEMONEY_ALL_PLAYER_CASE2",adminName,playerName)
			case 1: client_print(0,print_chat,"%L", LANG_PLAYER, "AMX_SUPER_TAKEMONEY_ALL_PLAYER_CASE1",playerName)
		}

		console_print(id,"%L", LANG_PLAYER, "AMX_SUPER_TAKEMONEY_ALL_PLAYER_MSG",amount,playerName,amount)
		log_amx("%L", LANG_SERVER, "AMX_SUPER_TAKEMONEY_ALL_PLAYER_LOG",adminName,adminAuthid,playerName,playerAuthid)

		return PLUGIN_HANDLED
	}

	else {
		cs_set_user_money(player,cs_get_user_money(player)-amount)

		switch(get_pcvar_num(amx_show_activity))
		{
			case 2: client_print(0,print_chat,"%L", LANG_PLAYER, "AMX_SUPER_TAKEMONEY_PLAYER_CASE2",adminName,amount,playerName)
			case 1: client_print(0,print_chat,"%L", LANG_PLAYER, "AMX_SUPER_TAKEMONEY_PLAYER_CASE1",amount,playerName)
		}

		console_print(id,"%L", LANG_PLAYER, "AMX_SUPER_TAKEMONEY_PLAYER_MSG",amount,playerName,amount)
		log_amx("%L", LANG_SERVER, "AMX_SUPER_TAKEMONEY_PLAYER_LOG",adminName,adminAuthid,amount,playerName,playerAuthid)

		return PLUGIN_HANDLED
	}
	return PLUGIN_HANDLED
}


////////////////////////////////////////////////////////////////////////////////////////////////////////////
//ADMIN ALLTALK v1.0 by BigBaller
//==========================================================================================================
public admin_alltalk(id,level,cid)
{
	if (!cmd_access(id,level,cid,1)) return PLUGIN_HANDLED

	if (read_argc() < 2) {
		console_print(id,"%L", LANG_PLAYER, "AMX_SUPER_ALLTALK_STATUS",get_pcvar_num(sv_alltalk))
		return PLUGIN_HANDLED
	}

	new alltalk[6]
	read_argv(1,alltalk,6)
	server_cmd("sv_alltalk %s",alltalk)

	new name[32], authid[36]
	get_user_name(id,name,31)
	get_user_authid(id,authid,35)

	switch(get_pcvar_num(amx_show_activity)){
		case 2 : client_print(0,print_chat,"%L", LANG_PLAYER, "AMX_SUPER_ALLTALK_SET_CASE2",name,alltalk)
		case 1 : client_print(0,print_chat,"%L", LANG_PLAYER, "AMX_SUPER_ALLTALK_SET_CASE1",alltalk)
	}

	console_print(id,"%L", LANG_PLAYER, "AMX_SUPER_ALLTALK_MSG",alltalk)
	log_amx("%L", LANG_SERVER, "AMX_SUPER_ALLTALK_LOG", name,authid,alltalk)

	return PLUGIN_HANDLED
}

public check_alltalk(id){
	new alltalk = get_pcvar_num(sv_alltalk)
	client_print(id,print_chat,"%L", LANG_PLAYER, "AMX_SUPER_ALLTALK_STATUS",alltalk)
	return PLUGIN_HANDLED
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////
//ADMIN GRAVITY v0.2 by JustinHoMi
//==========================================================================================================
public admin_gravity(id,level,cid)
{
	if (!cmd_access(id,level,cid,1)) return PLUGIN_HANDLED

	if (read_argc() < 2) {
		console_print(id,"%L", LANG_PLAYER, "AMX_SUPER_GRAVITY_STATUS",get_pcvar_num(sv_gravity))
		return PLUGIN_HANDLED
	}

	new gravity[6]
	read_argv(1,gravity,6)
	server_cmd("sv_gravity %s",gravity)

	new name[32], authid[36]
	get_user_name(id,name,31)
	get_user_authid(id,authid,35)

	switch(get_pcvar_num(amx_show_activity)){
		case 2:	client_print(0,print_chat,"%L", LANG_PLAYER, "AMX_SUPER_GRAVITY_SET_CASE2",name,gravity)
		case 1:	client_print(0,print_chat,"%L", LANG_PLAYER, "AMX_SUPER_GRAVITY_SET_CASE1",gravity)
	}

	console_print(id,"%L", LANG_PLAYER, "AMX_SUPER_GRAVITY_MSG",gravity)
	log_amx("%L", LANG_SERVER, "AMX_SUPER_GRAVITY_LOG", name,authid,gravity)

	return PLUGIN_HANDLED
}

public check_gravity(id){
	new gravity = get_pcvar_num(sv_gravity)
	client_print(id,print_chat,"%L", LANG_PLAYER, "AMX_SUPER_GRAVITY_CHECK",gravity)
	return PLUGIN_HANDLED
}


////////////////////////////////////////////////////////////////////////////////////////////////////////////
//ADMIN BURY v0.9.3 by f117bomb
//Revised by Bo0m!
//==========================================================================================================
bury_player(id,victim){
	new name[32], iwpns[32], nwpn[32], iwpn
	get_user_name(victim,name,31)
	get_user_weapons(victim,iwpns,iwpn)
	for(new a=0;a<iwpn;++a) {
		get_weaponname(iwpns[a],nwpn,31)
		engclient_cmd(victim,"drop",nwpn)
	}
	engclient_cmd(victim,weapons[WEAPON_KNIFE])
	new origin[3]
	get_user_origin(victim, origin)
	origin[2] -=	30
	fm_set_user_origin(victim, origin)
	console_print(id,"%L", LANG_PLAYER, "AMX_SUPER_BURY_MSG",name)
}


public admin_bury(id,level,cid){
	if (!cmd_access(id,level,cid,2))
		return PLUGIN_HANDLED

	new arg[32], admin_name[32], player_name[32], admin_authid[36], player_authid[36]
	read_argv(1,arg,31)
	get_user_name(id,admin_name,31)
	get_user_authid(id,admin_authid,35)

	if (arg[0]=='@'){
		new players[32], inum
		if (equali("T",arg[1]))		copy(arg[1],31,"TERRORIST")
		if (equali("ALL",arg[1]))	get_players(players,inum,"a")
		else						get_players(players,inum,"ae",arg[1])

		if (inum == 0) {
			console_print(id,"%L", LANG_PLAYER, AMX_SUPER_NO_PLAYERS)
			return PLUGIN_HANDLED
		}

		for(new a=0;a<inum;++a){
			if (get_user_flags(players[a])&ADMIN_IMMUNITY && players[a] != id){
				get_user_name(players[a],player_name,31)
				console_print(id,"%L", LANG_PLAYER, AMX_SUPER_TEAM_IMMUNITY,player_name)
				continue
			}
			bury_player(id,players[a])
		}
		switch(get_pcvar_num(amx_show_activity)) {
			case 2:	client_print(0,print_chat,"%L", LANG_PLAYER, "AMX_SUPER_BURY_TEAM_CASE2",admin_name,arg[1])
			case 1:	client_print(0,print_chat,"%L", LANG_PLAYER, "AMX_SUPER_BURY_TEAM_CASE1",arg[1])
			}
		log_amx("%L", LANG_SERVER, "AMX_SUPER_BURY_TEAM_LOG",admin_name,admin_authid,arg[1])
	}
	else	{
		new player = cmd_target(id,arg,7)
		if (!player) return PLUGIN_HANDLED
		bury_player(id,player)

		get_user_name(player,player_name,31)
		get_user_authid(player,player_authid,35)

		switch(get_pcvar_num(amx_show_activity))	{
			case 2:	client_print(0,print_chat,"%L", LANG_PLAYER, "AMX_SUPER_BURY_PLAYER_CASE2",admin_name,player_name)
			case 1:	client_print(0,print_chat,"%L", LANG_PLAYER, "AMX_SUPER_BURY_PLAYER_CASE1",player_name)
			}
		log_amx("%L", LANG_SERVER, "AMX_SUPER_BURY_PLAYER_LOG",admin_name,admin_authid,player_name,player_authid)
	}
	return PLUGIN_HANDLED
}

unbury_player(id,victim){
	new name[32], origin[3]
	get_user_name(victim,name,31)
	get_user_origin(victim, origin)
	origin[2] +=	35
	fm_set_user_origin(victim, origin)
	console_print(id,"%L", LANG_PLAYER, "AMX_SUPER_UNBURY_MSG",name)
}

public admin_unbury(id,level,cid){
	if (!cmd_access(id,level,cid,2))
		return PLUGIN_HANDLED

	new arg[32], admin_name[32], player_name[32], admin_authid[36], player_authid[36]
	read_argv(1,arg,31)
	get_user_name(id,admin_name,31)
	get_user_authid(id,admin_authid,35)

	if (arg[0]=='@'){
		new players[32], inum
		if (equali("T",arg[1]))		copy(arg[1],31,"TERRORIST")
		if (equali("ALL",arg[1]))	get_players(players,inum,"a")
		else						get_players(players,inum,"ae",arg[1])

		if (inum == 0) {
			console_print(id,"%L", LANG_PLAYER, AMX_SUPER_NO_PLAYERS)
			return PLUGIN_HANDLED
		}

		for(new a=0;a<inum;++a){
			if (get_user_flags(players[a])&ADMIN_IMMUNITY && players[a] != id){
				get_user_name(players[a],player_name,31)
				console_print(id,"%L", LANG_PLAYER, AMX_SUPER_TEAM_IMMUNITY,player_name)
				continue
			}
			unbury_player(id,players[a])
		}
		switch(get_pcvar_num(amx_show_activity)) {
			case 2:	client_print(0,print_chat,"%L", LANG_PLAYER, "AMX_SUPER_UNBURY_TEAM_CASE2",admin_name,arg[1])
			case 1:	client_print(0,print_chat,"%L", LANG_PLAYER, "AMX_SUPER_UNBURY_TEAM_CASE1",arg[1])
			}
		log_amx("%L", LANG_SERVER, "AMX_SUPER_UNBURY_TEAM_LOG",admin_name,admin_authid,arg[1])
	}
	else	{
		new player = cmd_target(id,arg,7)
		if (!player) return PLUGIN_HANDLED
		unbury_player(id,player)

		get_user_name(player,player_name,31)
		get_user_authid(player,player_authid,35)

		switch(get_pcvar_num(amx_show_activity))	{
			case 2:	client_print(0,print_chat,"%L", LANG_PLAYER, "AMX_SUPER_UNBURY_PLAYER_CASE2",admin_name,player_name)
			case 1:	client_print(0,print_chat,"%L", LANG_PLAYER, "AMX_SUPER_UNBURY_PLAYER_CASE1",player_name)
			}
		log_amx("%L", LANG_SERVER, "AMX_SUPER_UNBURY_PLAYER_LOG",admin_name,admin_authid,player_name,player_authid)
	}
	return PLUGIN_HANDLED
}


////////////////////////////////////////////////////////////////////////////////////////////////////////////
//ADMIN DISARM v1.1 by mike_cao
//Revised by Bo0m!
//==========================================================================================================
disarm_player(id,victim){

	new name[32], origin[3]
	get_user_origin(victim,origin)
	origin[2] -= 2000
	fm_set_user_origin(victim,origin)
	new iweapons[32], wpname[32], inum
	get_user_weapons(victim,iweapons,inum)
	for(new a=0;a<inum;++a){
		get_weaponname(iweapons[a],wpname,31)
		engclient_cmd(victim,"drop",wpname)
	}
	engclient_cmd(victim,weapons[WEAPON_KNIFE])
	origin[2] += 2005
	fm_set_user_origin(victim,origin)
	get_user_name(victim,name,31)
	console_print(id,"%L", LANG_PLAYER, "AMX_SUPER_DISARM_MSG",name)
}

public admin_disarm(id,level,cid){
	if (!cmd_access(id,level,cid,2))
		return PLUGIN_HANDLED

	new arg[32], admin_name[32], player_name[32], admin_authid[36], player_authid[36]
	read_argv(1,arg,31)
	get_user_name(id,admin_name,31)
	get_user_authid(id,admin_authid,35)

	if (arg[0]=='@'){
		new players[32], inum
		if (equali("T",arg[1]))		copy(arg[1],31,"TERRORIST")
		if (equali("ALL",arg[1]))	get_players(players,inum,"a")
		else						get_players(players,inum,"ae",arg[1])

		if (inum == 0) {
			console_print(id,"%L", LANG_PLAYER, AMX_SUPER_NO_PLAYERS)
			return PLUGIN_HANDLED
		}

		for(new a=0;a<inum;++a){
			if (get_user_flags(players[a])&ADMIN_IMMUNITY && players[a] != id){
				get_user_name(players[a],player_name,31)
				console_print(id,"%L", LANG_PLAYER, AMX_SUPER_TEAM_IMMUNITY,player_name)
				continue
			}
			disarm_player(id,players[a])
		}
		switch(get_pcvar_num(amx_show_activity)) {
			case 2:	client_print(0,print_chat,"%L", LANG_PLAYER, "AMX_SUPER_DISARM_TEAM_CASE2",admin_name,arg[1])
			case 1:	client_print(0,print_chat,"%L", LANG_PLAYER, "AMX_SUPER_DISARM_TEAM_CASE1",arg[1])
			}
		log_amx("%L", LANG_SERVER, "AMX_SUPER_DISARM_TEAM_LOG",admin_name,admin_authid,arg[1])
	}
	else	{
		new player = cmd_target(id,arg,7)
		if (!player) return PLUGIN_HANDLED
		disarm_player(id,player)

		get_user_name(player,player_name,31)
		get_user_authid(player,player_authid,35)

		switch(get_pcvar_num(amx_show_activity))	{
			case 2:	client_print(0,print_chat,"%L", LANG_PLAYER, "AMX_SUPER_DISARM_PLAYER_CASE2",admin_name,player_name)
			case 1:	client_print(0,print_chat,"%L", LANG_PLAYER, "AMX_SUPER_DISARM_PLAYER_CASE1",player_name)
			}
		log_amx("%L", LANG_SERVER, "AMX_SUPER_DISARM_PLAYER_LOG",admin_name,admin_authid,player_name,player_authid)
	}
	return PLUGIN_HANDLED
}


////////////////////////////////////////////////////////////////////////////////////////////////////////////
//ADMIN SLAY 2 v0.9.3 by f117bomb
//Revised by JTP10181
//==========================================================================================================
public admin_slay(id,level,cid)
{
	if (!cmd_access(id,level,cid,2)) return PLUGIN_HANDLED

	new arg[32], arg2[3], type
	new name[32], name2[32], authid[36], authid2[36]
	read_argv(1,arg,31)
	read_argv(2,arg2,2)
	type = str_to_num(arg2)
	get_user_name(id,name,31)
	get_user_authid(id,authid,35)

	if (arg[0]=='@'){
		new players[32], inum
		if (equali("T",arg[1]))		copy(arg[1],31,"TERRORIST")
		if (equali("ALL",arg[1]))	get_players(players,inum)
		else						get_players(players,inum,"e",arg[1])

		if (inum == 0) {
			console_print(id,"%L", LANG_PLAYER, AMX_SUPER_NO_PLAYERS)
			return PLUGIN_HANDLED
		}

		for(new a = 0; a < inum; a++) {
			if (get_user_flags(players[a]) & ADMIN_IMMUNITY && players[a] != id){
				get_user_name(players[a],name2,31)
				console_print(id,"%L", LANG_PLAYER, AMX_SUPER_TEAM_IMMUNITY,name2)
				continue
			}
			slay_player(players[a],type)
		}
		switch(get_pcvar_num(amx_show_activity)) {
			case 2:	client_print(0,print_chat,"%L", LANG_PLAYER, "AMX_SUPER_SLAY2_TEAM_CASE2",name,arg[1])
			case 1:	client_print(0,print_chat,"%L", LANG_PLAYER, "AMX_SUPER_SLAY2_TEAM_CASE1",arg[1])
		}

		console_print(id,"%L", LANG_PLAYER, "AMX_SUPER_SLAY2_TEAM_MSG",arg[1])
		log_amx("%L", LANG_SERVER, "AMX_SUPER_SLAY2_TEAM_LOG",name,authid,arg[1])
	}
	else {
		new player = cmd_target(id,arg,7)
		if (!player) return PLUGIN_HANDLED

		slay_player(player,type)

		get_user_name(player,name2,31)
		get_user_authid(player,authid2,35)

		switch(get_pcvar_num(amx_show_activity)) {
			case 2:	client_print(0,print_chat,"%L", LANG_PLAYER, "AMX_SUPER_SLAY2_PLAYER_CASE2",name,name2)
			case 1:	client_print(0,print_chat,"%L", LANG_PLAYER, "AMX_SUPER_SLAY2_PLAYER_CASE1",name2)
		}

		console_print(id,"%L", LANG_PLAYER, "AMX_SUPER_SLAY2_PLAYER_MSG", name2)
		log_amx("%L", LANG_SERVER, "AMX_SUPER_SLAY2_PLAYER_LOG", name,authid,name2,authid2)
	}
	return PLUGIN_HANDLED
}

slay_player(victim,type)
{
	new origin[3], srco[3]
	get_user_origin(victim,origin)

	origin[2] -= 26
	srco[0] = origin[0]+150
	srco[1] = origin[1]+150
	srco[2] = origin[2]+400

	switch (type) {
		case 1: {
			lightning(srco,origin)
			emit_sound(victim,CHAN_ITEM, "ambience/thunder_clap.wav", 1.0, ATTN_NORM, 0, PITCH_NORM)
		}
		case 2:{
			blood(origin)
			emit_sound(victim,CHAN_ITEM, "weapons/headshot2.wav", 1.0, ATTN_NORM, 0, PITCH_NORM)
		}
		case 3: {
			explode(origin)
		}
	}
	user_kill(victim,1)
}

explode (vec1[3]) {

	//Blast Circles
	message_begin( MSG_BROADCAST,SVC_TEMPENTITY,vec1)
	write_byte( 21 )
	write_coord(vec1[0])
	write_coord(vec1[1])
	write_coord(vec1[2] + 16)
	write_coord(vec1[0])
	write_coord(vec1[1])
	write_coord(vec1[2] + 1936)
	write_short( white )
	write_byte( 0 ) // startframe
	write_byte( 0 ) // framerate
	write_byte( 2 ) // life
	write_byte( 16 ) // width
	write_byte( 0 ) // noise
	write_byte( 188 ) // r
	write_byte( 220 ) // g
	write_byte( 255 ) // b
	write_byte( 255 ) //brightness
	write_byte( 0 ) // speed
	message_end()

	//Explosion2
	message_begin( MSG_BROADCAST,SVC_TEMPENTITY)
	write_byte( 12 )
	write_coord(vec1[0])
	write_coord(vec1[1])
	write_coord(vec1[2])
	write_byte( 188 ) // byte (scale in 0.1's)
	write_byte( 10 ) // byte (framerate)
	message_end()

	//Smoke
	message_begin( MSG_BROADCAST,SVC_TEMPENTITY,vec1)
	write_byte( 5 )
	write_coord(vec1[0])
	write_coord(vec1[1])
	write_coord(vec1[2])
	write_short( smoke )
	write_byte( 2 )
	write_byte( 10 )
	message_end()
}

blood (vec1[3]) {

	//LAVASPLASH
	message_begin( MSG_BROADCAST,SVC_TEMPENTITY)
	write_byte( 10 )
	write_coord(vec1[0])
	write_coord(vec1[1])
	write_coord(vec1[2])
	message_end()
}

lightning (vec1[3],vec2[3]) {

	//Lightning
	message_begin( MSG_BROADCAST,SVC_TEMPENTITY)
	write_byte( 0 )
	write_coord(vec1[0])
	write_coord(vec1[1])
	write_coord(vec1[2])
	write_coord(vec2[0])
	write_coord(vec2[1])
	write_coord(vec2[2])
	write_short( light )
	write_byte( 1 ) // framestart
	write_byte( 5 ) // framerate
	write_byte( 2 ) // life
	write_byte( 20 ) // width
	write_byte( 30 ) // noise
	write_byte( 200 ) // r, g, b
	write_byte( 200 ) // r, g, b
	write_byte( 200 ) // r, g, b
	write_byte( 200 ) // brightness
	write_byte( 200 ) // speed
	message_end()

	//Sparks
	message_begin( MSG_PVS, SVC_TEMPENTITY,vec2)
	write_byte( 9 )
	write_coord( vec2[0] )
	write_coord( vec2[1] )
	write_coord( vec2[2] )
	message_end()

	//Smoke
	message_begin( MSG_BROADCAST,SVC_TEMPENTITY,vec2)
	write_byte( 5 )
	write_coord(vec2[0])
	write_coord(vec2[1])
	write_coord(vec2[2])
	write_short( smoke )
	write_byte( 10 )
	write_byte( 10 )
	message_end()
}


////////////////////////////////////////////////////////////////////////////////////////////////////////////
//ADMIN FIRE v1.0.0 by f117bomb
//==========================================================================================================
new bool:onfire[33]

public ignite_effects(skIndex[])   {
	new kIndex = skIndex[0]


	if (is_user_alive(kIndex) && onfire[kIndex] )    {
		new korigin[3]
		get_user_origin(kIndex,korigin)

		//TE_SPRITE - additive sprite, plays 1 cycle
		message_begin( MSG_BROADCAST,SVC_TEMPENTITY)
		write_byte( 17 )
		write_coord(korigin[0])  // coord, coord, coord (position)
		write_coord(korigin[1])
		write_coord(korigin[2])
		write_short( mflash ) // short (sprite index)
		write_byte( 20 ) // byte (scale in 0.1's)
		write_byte( 200 ) // byte (brightness)
		message_end()

		//Smoke
		message_begin( MSG_BROADCAST,SVC_TEMPENTITY,korigin)
		write_byte( 5 )
		write_coord(korigin[0])// coord coord coord (position)
		write_coord(korigin[1])
		write_coord(korigin[2])
		write_short( smoke )// short (sprite index)
		write_byte( 20 ) // byte (scale in 0.1's)
		write_byte( 15 ) // byte (framerate)
		message_end()

		set_task(0.2, "ignite_effects" , 0 , skIndex, 2)
	}
	else    {
		if( onfire[kIndex] )   {
			emit_sound(kIndex,CHAN_AUTO, "scientist/scream21.wav", 0.6, ATTN_NORM, 0, PITCH_HIGH)
			onfire[kIndex] = false
		}
	}
	return PLUGIN_CONTINUE
}

public ignite_player(skIndex[])   {
	new kIndex = skIndex[0]

	if (is_user_alive(kIndex) && onfire[kIndex] )    {
		new korigin[3]
		new players[32], inum = 0
		new pOrigin[3]
		new kHeath = get_user_health(kIndex)
		get_user_origin(kIndex,korigin)

		//create some damage
		fm_set_user_health(kIndex,kHeath - 10)
		message_begin(MSG_ONE, gmsgDamage, {0,0,0}, kIndex)
		write_byte(30) // dmg_save
		write_byte(30) // dmg_take
		write_long(1<<21) // visibleDamageBits
		write_coord(korigin[0]) // damageOrigin.x
		write_coord(korigin[1]) // damageOrigin.y
		write_coord(korigin[2]) // damageOrigin.z
		message_end()

		//create some sound
		emit_sound(kIndex,CHAN_ITEM, "ambience/flameburst1.wav", 0.6, ATTN_NORM, 0, PITCH_NORM)

		//Ignite Others
		if ( get_pcvar_num(allowcatchfire))    {
			get_players(players,inum,"a")
			for(new i = 0 ;i < inum; ++i)   {
				get_user_origin(players[i],pOrigin)

				if( get_distance(korigin,pOrigin) < 100  )   {

					if( !onfire[players[i]] )   {

						new spIndex[2]
						spIndex[0] = players[i]
						new pName[32], kName[32]
						get_user_name(players[i],pName,31)
						get_user_name(kIndex,kName,31)
						emit_sound(players[i],CHAN_WEAPON ,"scientist/scream07.wav", 1.0, ATTN_NORM, 0, PITCH_HIGH)
						client_print(0,3,"* [AMX] OH! NO! %s has caught %s on fire!",kName,pName)
						onfire[players[i]] = true
						ignite_player(players[i])
						ignite_effects(players[i])
					}
				}
			}
			players[0] = 0
			pOrigin[0] = 0
			korigin[0] = 0
		}
		//Call Again in 2 seconds
		set_task(2.0, "ignite_player" , 0 , skIndex, 2)
	}

	return PLUGIN_CONTINUE
}


public admin_fire(id,level,cid) {
	if (!cmd_access(id,level,cid,2))
		return PLUGIN_HANDLED

	new arg[32]
	read_argv(1,arg,31)
	new skIndex[2];
	new adminname[32], adminauthid[36]
	get_user_name(id,adminname,31)
	get_user_authid(id,adminauthid,35)
	if(arg[0] == '@')
	{
		new players[32], pnum;
		if(equali(arg[1], "ALL")) get_players(players, pnum, "a")
		else get_players(players, pnum, "ae", (equali(arg[1], "CT")) ? "CT" : "TERRORIST");
		if(!pnum) return PLUGIN_HANDLED;
		new i, pid;
		for(i = 0; i < pnum; i++)
		{
			pid = players[i];
			skIndex[0] = pid;
			onfire[pid] = true;
			ignite_effects(skIndex);
			ignite_player(skIndex);
		}
		switch(get_pcvar_num(amx_show_activity))
		{
			case 2: client_print(0, print_chat, "%L", LANG_PLAYER, "AMX_SUPER_FIRE_TEAM_CASE2", adminname, arg[1]);
			case 1: client_print(0, print_chat, "%L", LANG_PLAYER, "AMX_SUPER_FIRE_TEAM_CASE1", arg[1]);
		}
		console_print(id, "%L", LANG_PLAYER, "AMX_SUPER_FIRE_TEAM_MSG", arg[1]);
		log_amx("%L", LANG_SERVER, "AMX_SUPER_FIRE_TEAM_LOG", adminname, adminauthid, arg[1]);
	}
	else
	{
		new victim = cmd_target(id,arg,7)
		if (!victim)
			return PLUGIN_HANDLED

		skIndex[0] = victim
		new name[32], victimauthid[36]
		get_user_name(victim,name,31)
		get_user_authid(victim,victimauthid,35)

		onfire[victim] = true
		ignite_effects(skIndex)
		ignite_player(skIndex)

		switch(get_pcvar_num(amx_show_activity))   {
			case 2:   client_print(0,print_chat,"%L", LANG_PLAYER, "AMX_SUPER_FIRE_PLAYER_CASE2",adminname,name)
			case 1:   client_print(0,print_chat,"%L", LANG_PLAYER, "AMX_SUPER_FIRE_PLAYER_CASE1",name)
			}

		console_print(id,"%L", LANG_PLAYER, "AMX_SUPER_FIRE_PLAYER_MSG",name)
		log_amx("%L", LANG_SERVER, "AMX_SUPER_FIRE_PLAYER_LOG",adminname,adminauthid,name,victimauthid)
	}

	return PLUGIN_HANDLED
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////
//ADMIN ROCKET v1.3 by f117bomb
//Revised by JTP10181
//==========================================================================================================
new rocket_z[33]

public admin_rocket(id,level,cid)
{

	if (!cmd_access(id,level,cid,2)) return PLUGIN_HANDLED

	new arg[32]
	new name[32], name2[32], authid[36], authid2[36]
	read_argv(1,arg,31)
	get_user_name(id,name,31)
	get_user_authid(id,authid,35)

	if (arg[0]=='@'){
		new players[32], inum
		if (equali("T",arg[1]))		copy(arg[1],31,"TERRORIST")
		if (equali("ALL",arg[1]))	get_players(players,inum)
		else						get_players(players,inum,"e",arg[1])

		if (inum == 0) {
			console_print(id,"%L", LANG_PLAYER, AMX_SUPER_NO_PLAYERS)
			return PLUGIN_HANDLED
		}

		for(new a = 0; a < inum; a++) {
			if (get_user_flags(players[a]) & ADMIN_IMMUNITY && players[a] != id){
				get_user_name(players[a],name2,31)
				console_print(id,"%L", LANG_PLAYER, AMX_SUPER_TEAM_IMMUNITY,name2)
				continue
			}

			emit_sound(players[a],CHAN_WEAPON ,"weapons/rocketfire1.wav", 1.0, ATTN_NORM, 0, PITCH_NORM)
			fm_set_user_maxspeed(players[a],0.01)
			set_task(1.2, "rocket_liftoff" , players[a])
		}

		switch(get_pcvar_num(amx_show_activity)) {
			case 2:	client_print(0,print_chat,"%L", LANG_PLAYER, "AMX_SUPER_ROCKET_TEAM_CASE2",name,arg[1])
			case 1:	client_print(0,print_chat,"%L", LANG_PLAYER, "AMX_SUPER_ROCKET_TEAM_CASE1",arg[1])
		}

		console_print(id,"%L", LANG_PLAYER, "AMX_SUPER_ROCKET_TEAM_MSG",arg[1])
		log_amx("%L", LANG_SERVER, "AMX_SUPER_ROCKET_TEAM_LOG",name,authid,arg[1])

	}
	else {

		new player = cmd_target(id,arg,7)
		if (!player) return PLUGIN_HANDLED

		emit_sound(player,CHAN_WEAPON ,"weapons/rocketfire1.wav", 1.0, ATTN_NORM, 0, PITCH_NORM)
		fm_set_user_maxspeed(player,0.01)
		set_task(1.2, "rocket_liftoff", player)

		get_user_name(player,name2,31)
		get_user_authid(player,authid2,35)

		switch(get_pcvar_num(amx_show_activity)) {
			case 2:	client_print(0,print_chat,"%L", LANG_PLAYER, "AMX_SUPER_ROCKET_PLAYER_CASE2",name,name2)
			case 1:	client_print(0,print_chat,"%L", LANG_PLAYER, "AMX_SUPER_ROCKET_PLAYER_CASE1",name2)
		}

		console_print(id,"%L", LANG_PLAYER, "AMX_SUPER_ROCKET_PLAYER_MSG", name2)
		log_amx("%L", LANG_SERVER, "AMX_SUPER_ROCKET_PLAYER_LOG", name,authid,name2,authid2)
	}
	return PLUGIN_HANDLED
}

public rocket_liftoff(victim)
{
	if (!is_user_alive(victim)) return
	fm_set_user_gravity(victim,-0.50)
	client_cmd(victim,"+jump;wait;wait;-jump")
	emit_sound(victim, CHAN_VOICE, "weapons/rocket1.wav", 1.0, 0.5, 0, PITCH_NORM)
	rocket_effects(victim)
}

public rocket_effects(victim)
{
	if (!is_user_alive(victim)) return

	new vorigin[3]
	get_user_origin(victim,vorigin)

	message_begin(MSG_ONE, gmsgDamage, {0,0,0}, victim)
	write_byte(30) // dmg_save
	write_byte(30) // dmg_take
	write_long(1<<16) // visibleDamageBits
	write_coord(vorigin[0]) // damageOrigin.x
	write_coord(vorigin[1]) // damageOrigin.y
	write_coord(vorigin[2]) // damageOrigin.z
	message_end()

	if (rocket_z[victim] == vorigin[2]) {
		rocket_explode(victim)
	}

	rocket_z[victim] = vorigin[2]

	//Draw Trail and effects

	//TE_SPRITETRAIL - line of moving glow sprites with gravity, fadeout, and collisions
	message_begin( MSG_BROADCAST, SVC_TEMPENTITY )
	write_byte( 15 )
	write_coord( vorigin[0]) // coord, coord, coord (start)
	write_coord( vorigin[1])
	write_coord( vorigin[2])
	write_coord( vorigin[0]) // coord, coord, coord (end)
	write_coord( vorigin[1])
	write_coord( vorigin[2] - 30)
	write_short( blueflare2 ) // short (sprite index)
	write_byte( 5 ) // byte (count)
	write_byte( 1 ) // byte (life in 0.1's)
	write_byte( 1 )  // byte (scale in 0.1's)
	write_byte( 10 ) // byte (velocity along vector in 10's)
	write_byte( 5 )  // byte (randomness of velocity in 10's)
	message_end()

	//TE_SPRITE - additive sprite, plays 1 cycle
	message_begin( MSG_BROADCAST,SVC_TEMPENTITY)
	write_byte( 17 )
	write_coord(vorigin[0])  // coord, coord, coord (position)
	write_coord(vorigin[1])
	write_coord(vorigin[2] - 30)
	write_short( mflash ) // short (sprite index)
	write_byte( 15 ) // byte (scale in 0.1's)
	write_byte( 255 ) // byte (brightness)
	message_end()

	set_task(0.2, "rocket_effects", victim)
}

public rocket_explode(victim)
{
	if (is_user_alive(victim)) {
		new vec1[3]
		get_user_origin(victim,vec1)

		// blast circles
		message_begin( MSG_BROADCAST,SVC_TEMPENTITY,vec1)
		write_byte( 21 )
		write_coord(vec1[0])
		write_coord(vec1[1])
		write_coord(vec1[2] - 10)
		write_coord(vec1[0])
		write_coord(vec1[1])
		write_coord(vec1[2] + 1910)
		write_short( white )
		write_byte( 0 ) // startframe
		write_byte( 0 ) // framerate
		write_byte( 2 ) // life
		write_byte( 16 ) // width
		write_byte( 0 ) // noise
		write_byte( 188 ) // r
		write_byte( 220 ) // g
		write_byte( 255 ) // b
		write_byte( 255 ) //brightness
		write_byte( 0 ) // speed
		message_end()

		//Explosion2
		message_begin( MSG_BROADCAST,SVC_TEMPENTITY)
		write_byte( 12 )
		write_coord(vec1[0])
		write_coord(vec1[1])
		write_coord(vec1[2])
		write_byte( 188 ) // byte (scale in 0.1's)
		write_byte( 10 ) // byte (framerate)
		message_end()

		//smoke
		message_begin( MSG_BROADCAST,SVC_TEMPENTITY,vec1)
		write_byte( 5 )
		write_coord(vec1[0])
		write_coord(vec1[1])
		write_coord(vec1[2])
		write_short( smoke )
		write_byte( 2 )
		write_byte( 10 )
		message_end()

		user_kill(victim,1)
	}

	//stop_sound
	emit_sound(victim, CHAN_VOICE, "weapons/rocket1.wav", 0.0, 0.0, (1<<5), PITCH_NORM)

	fm_set_user_maxspeed(victim,1.0)
	fm_set_user_gravity(victim,1.00)
}


////////////////////////////////////////////////////////////////////////////////////////////////////////////
//AMX UBER SLAP v0.9.3 by BarMan (Skullz.NET)
//==========================================================================================================
public admin_slap(id,level,cid){

	if (!cmd_access(id,level,cid,2))
	return PLUGIN_HANDLED

	new name[32], name2[32], authid[36], authid2[36]
	new arg[32]
	read_argv(1,arg,31)

	new player = cmd_target(id,arg,7)
	if (!player)
	return PLUGIN_HANDLED

	new ids[2]
	ids[0] = player

	get_user_name(player,name,32)
	get_user_authid(player,authid,35)

	udisarm_player(id,player)
	set_task(0.1, "slap_player", 0, ids, 1, "a", 100)

	get_user_name(id,name2,31)
	get_user_authid(id,authid2,35)

	switch(get_pcvar_num(amx_show_activity))
	{
	case 2:	client_print(0,print_chat,"%L", LANG_PLAYER, "AMX_SUPER_UBERSLAP_PLAYER_CASE2",name2,name)
	case 1:	client_print(0,print_chat,"%L", LANG_PLAYER, "AMX_SUPER_UBERSLAP_PLAYER_CASE1",name)

	}

	console_print(id,"%L", LANG_PLAYER, "AMX_SUPER_UBERSLAP_PLAYER_MSG",name)
	log_amx("%L", LANG_SERVER, "AMX_SUPER_UBERSLAP_PLAYER_LOG",name2,authid2,name,authid)

	return PLUGIN_HANDLED
}

public udisarm_player(id,victim){

	new name[32], origin[3]

	get_user_origin(victim,origin)
	origin[2] -= 2000
	fm_set_user_origin(victim,origin)

	new iweapons[32], wpname[32], inum
	get_user_weapons(victim,iweapons,inum)

	for(new a=0;a<inum;++a){

		get_weaponname(iweapons[a],wpname,31)
		engclient_cmd(victim,"drop",wpname)
	}

	engclient_cmd(victim,weapons[WEAPON_KNIFE])
	origin[2] += 2005
	fm_set_user_origin(victim,origin)
	get_user_name(victim,name,31)

	return PLUGIN_CONTINUE
}

public slap_player(ids[]) {

	new id = ids[0]
	new upower = 1,nopower= 0

	if (get_user_health(id) > 1)
	{
		user_slap(id,upower)

	} else {

		user_slap(id,nopower)
	}

	return PLUGIN_CONTINUE
}


////////////////////////////////////////////////////////////////////////////////////////////////////////////
// AMX EXEC 2 v0.3 by v3x
//==========================================================================================================
public admin_exec(id,level,cid)
{

	if(!cmd_access(id,level,cid,3))
	{
		return PLUGIN_HANDLED
	}

	new arg[32]
	new command[64]
	new players[32]
	new player,num,i,whoTeam

	read_argv(1,arg,31)
	read_argv(2,command,63)

	remove_quotes(command)

	while(replace(command,63,"\'","^"")) { } // Credited to OLO

	new activity = get_pcvar_num(amx_show_activity)

	new admin[32], adminauthid[36]
	get_user_name(id,admin,31)
	get_user_authid(id,adminauthid,35)

	if(arg[0]=='@') {
		whoTeam = get_team_target(arg,players,num)

		if(!(num))
		{
			console_print(id,"%L", LANG_PLAYER, AMX_SUPER_NO_PLAYERS)
			return PLUGIN_HANDLED
		}


		for(i=0;i<num;i++)
		{

			player = players[i]

			if(!is_user_connected(player)) continue

			else if(player)
			{

				if(!(get_user_flags(player) & ADMIN_IMMUNITY))
				{
					client_cmd(player,command)
				}
			}
		}

		if(whoTeam == GET_TEAM_TARGET_ISALL)
		{
			switch(activity)
			{
				case 2:	client_print(0,print_chat,"%L", LANG_PLAYER, "AMX_SUPER_EXEC_ALL_CASE2",admin,command)
				case 1:	client_print(0,print_chat,"%L", LANG_PLAYER, "AMX_SUPER_EXEC_ALL_CASE1",command)
			}
			log_amx("%L", LANG_SERVER, "AMX_SUPER_EXEC_ALL_LOG",admin,adminauthid,command)
		} else {
			switch(activity)
			{
				case 2:	client_print(0,print_chat,"%L", LANG_PLAYER, "AMX_SUPER_EXEC_TEAM_CASE2",admin,command,arg[1])
				case 1:	client_print(0,print_chat,"%L", LANG_PLAYER, "AMX_SUPER_EXEC_TEAM_CASE1",command,arg[1])
			}
			log_amx("%L", LANG_SERVER, "AMX_SUPER_EXEC_TEAM_LOG",admin,adminauthid,command,arg[1])
		}
	}

	else
	{
		new target = cmd_target(id,arg,3)
		new name[33], playerauthid[36]

		if(!is_user_connected(target))
		{
			return PLUGIN_HANDLED
		}

		get_user_name(target,name,32)
		get_user_authid(target,playerauthid,35)

		if(!(get_user_flags(target) & ADMIN_IMMUNITY))
		{
			client_cmd(target,command)
		}


		switch(activity)
		{
			case 2:	client_print(0,print_chat,"%L", LANG_PLAYER, "AMX_SUPER_EXEC_PLAYER_CASE2",admin,command,name)
			case 1:	client_print(0,print_chat,"%L", LANG_PLAYER, "AMX_SUPER_EXEC_PLAYER_CASE1",command,name)
		}
		log_amx("%L", LANG_PLAYER, "AMX_SUPER_EXEC_PLAYER_LOG",admin,adminauthid,command,name,playerauthid)

	}

	return PLUGIN_HANDLED
}


////////////////////////////////////////////////////////////////////////////////////////////////////////////
//STATUS from AdminModX by Zor  Revisions by X-olent
//==========================================================================================================
public admin_status(id, level, cid)
{
    if(!cmd_access(id, level, cid, 1))
        return PLUGIN_HANDLED

    new len = 0, message[1024], temp[32]

    len += format(message[len], (1023-len), "<table>")

    new player_id[32], player_num, ping = 0, loss = 0
    new time = 0, seconds = 0, minutes = 0, hours = 0

    get_players(player_id, player_num, "c")

    for(new i = 0; i < player_num; i++)
    {
        // ID
        len += format(message[len], (1023-len), "<tr><td>#</td><td>%d</td></tr>", get_user_userid(player_id[i]))
        len += format(message[len], (1023-len), "<tr><td>Edict</td><td>%d</td>", id)

        // Name
        get_user_name(player_id[i], temp, 31)
        len += format(message[len], (1023-len), "<tr><td>Nick</td><td>%s</td>", temp)

        // Steam ID
        get_user_authid(player_id[i], temp, 31)
        len += format(message[len], (1023-len), "<tr><td>Steam</td><td>%s</td>", temp)

        // Ip
        get_user_ip(player_id[i], temp, 31)
        len += format(message[len], (1023-len), "<tr><td>IP</td><td>%s</td>", temp)

        // Flags
        get_flags(get_user_flags(player_id[i]), temp, 31)
        len += format(message[len], (1023-len), "<tr><td>Flags</td><td>%s</td>", temp)

        // Frags
        len += format(message[len], (1023-len), "<tr><td>Frags</td><td>%d</td>", get_user_frags(player_id[i]))

        // Death
        len += format(message[len], (1023-len), "<tr><td>Deaths</td><td>%d</td>", get_user_deaths(player_id[i]))

        // Health
        len += format(message[len], (1023-len), "<tr><td>Health</td><td>%d</td>", get_user_health(player_id[i]))

        // Ping
        get_user_ping(player_id[i], ping, loss)
        len += format(message[len], (1023-len), "<tr><td>Ping</td><td>%d</td>", ping)
        len += format(message[len], (1023-len), "<tr><td>Loss</td><td>%d</td>", loss)

        // Team
        get_user_team(player_id[i], temp, 31)
        len += format(message[len], (1023-len), "<tr><td>Team</td><td>%s</td>", temp)

        // Time in Seconds Playing
        time = get_user_time( player_id[i] )
        seconds = time
        while( seconds >= 60 )
            seconds -= 60
        minutes = ( time - seconds ) / 60
        hours = minutes
        while( minutes >= 60 )
            minutes -= 60
        hours = ( hours - minutes ) / 60
        len += format(message[len], (1023-len), "<tr><td>Time On</td><td>%d:%d:%d</td>", hours, minutes, seconds)
    }

    len += format(message[len], (1023-len), "</table>")

    show_motd(id, message, "Status")

    return PLUGIN_CONTINUE
}


////////////////////////////////////////////////////////////////////////////////////////////////////////////
//SERVER PASSWORD v1.0 by Sparky911
//==========================================================================================================
public admin_pass(id, level, cid)
{
	if(!cmd_access(id, level, cid, 1))
		return PLUGIN_HANDLED

	new cmd[32], password[128]

	read_argv(0, cmd, 31)
	read_args(password, 127)
	replace(password, 127, cmd, "")
	format(password, 127, "%s", password)

	new authid[36]
	new name[32]
	get_user_name(id, name, 31)
	get_user_authid(id, authid, 35)

	switch (get_pcvar_num(amx_show_activity)) {
		case 2: client_print(0,print_chat,"%L", LANG_PLAYER, "AMX_SUPER_PASSWORD_SET_CASE2",name)
		case 1: client_print(0,print_chat,"%L", LANG_PLAYER, "AMX_SUPER_PASSWORD_SET_CASE1")
	}
	log_amx("%L", LANG_SERVER, "AMX_SUPER_PASSWORD_SET_LOG",name,authid,password)
	set_pcvar_string(sv_password, password)

	return PLUGIN_HANDLED
}

public admin_nopass(id, level, cid)
{
	if(!cmd_access(id, level, cid, 1))
		return PLUGIN_HANDLED

	new authid[36]
	new name[32]
	get_user_name(id, name, 31)
	get_user_authid(id, authid, 35)

	switch (get_pcvar_num(amx_show_activity)) {
		case 2: client_print(0,print_chat,"%L", LANG_PLAYER, "AMX_SUPER_PASSWORD_REMOVE_CASE2",name)
		case 1: client_print(0,print_chat,"%L", LANG_PLAYER, "AMX_SUPER_PASSWORD_REMOVE_CASE1")
	}
	log_amx("%L", LANG_SERVER, "AMX_SUPER_PASSWORD_REMOVE_LOG",name,authid)
	set_pcvar_string(sv_password, "")

	return PLUGIN_HANDLED
}


////////////////////////////////////////////////////////////////////////////////////////////////////////////
//ADMIN QUIT v1.1 by Bo0m! (Originally from AdminModX by Zor)
//==========================================================================================================
public admin_quit(id,level,cid){
	if (!cmd_access(id,level,cid,2))
		return PLUGIN_HANDLED

	new arg[32], admin_name[32], player_name[32], admin_authid[36], player_authid[36]
	read_argv(1,arg,31)
	get_user_name(id,admin_name,31)
	get_user_authid(id,admin_authid,35)

	if (arg[0]=='@'){
		new players[32], inum
		get_team_target(arg,players,inum)

		if (inum == 0) {
			console_print(id,"%L", LANG_PLAYER, AMX_SUPER_NO_PLAYERS)
			return PLUGIN_HANDLED
		}

		for(new a=0;a<inum;++a){
			if (get_user_flags(players[a])&ADMIN_IMMUNITY && players[a] != id){
				get_user_name(players[a],player_name,31)
				console_print(id,"%L", LANG_PLAYER, AMX_SUPER_TEAM_IMMUNITY,player_name)
				continue
			}
			client_cmd(players[a], "quit")
			client_cmd(0,"spk ambience/thunder_clap.wav")
		}
		switch(get_pcvar_num(amx_show_activity)) {
			case 2:	client_print(0,print_chat,"%L", LANG_PLAYER, "AMX_SUPER_QUIT_TEAM_CASE2",admin_name,arg[1])
			case 1:	client_print(0,print_chat,"%L", LANG_PLAYER, "AMX_SUPER_QUIT_TEAM_CASE1",arg[1])
			}
		log_amx("%L", LANG_SERVER, "AMX_SUPER_QUIT_TEAM_LOG",admin_name,admin_authid,arg[1])
	}
	else	{
		new player = cmd_target(id,arg,3)
		if (!player) return PLUGIN_HANDLED
		client_cmd(player, "quit")
		emit_sound(0, CHAN_VOICE, "ambience/thunder_clap.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM)

		get_user_name(player,player_name,31)
		get_user_authid(player,player_authid,35)

		switch(get_pcvar_num(amx_show_activity))	{
			case 2:	client_print(0,print_chat,"%L", LANG_PLAYER, "AMX_SUPER_QUIT_PLAYER_CASE2",admin_name,player_name)
			case 1:	client_print(0,print_chat,"%L", LANG_PLAYER, "AMX_SUPER_QUIT_PLAYER_CASE1",player_name)
			}
		log_amx("%L", LANG_SERVER, "AMX_SUPER_QUIT_PLAYER_LOG",admin_name,admin_authid,player_name,player_authid)
	}
	return PLUGIN_HANDLED
}


////////////////////////////////////////////////////////////////////////////////////////////////////////////
//ADMIN GAG v1.8.3 by EKS
//==========================================================================================================
public block_gagged(id){
	if(!g_GagPlayers[id]) return PLUGIN_CONTINUE
	new cmd[5]
	read_argv(0,cmd,4)
	if ( cmd[3] == '_' )
		{
		if (g_GagPlayers[id] & 2){
#if GagReason == 1
			client_print(id,print_chat, "%L", LANG_PLAYER, "AMX_SUPER_GAG_REASON",gs_GagReason[id])
#else
			client_print(id,print_chat, "%L", LANG_PLAYER, "AMX_SUPER_PLAYER_GAGGED")
#endif

#if PlaySound == 1
			client_cmd(id,"spk barney/youtalkmuch")
#endif
			return PLUGIN_HANDLED
			}
		}
	else if (g_GagPlayers[id] & 1)   {
#if GagReason == 1
			client_print(id,print_chat, "%L", LANG_PLAYER, "AMX_SUPER_GAG_REASON",gs_GagReason[id])
#else
			client_print(id,print_chat, "%L", LANG_PLAYER, "AMX_SUPER_PLAYER_GAGGED")
#endif
#if PlaySound == 1
			client_cmd(id,"spk barney/youtalkmuch")
#endif
		return PLUGIN_HANDLED
		}
	return PLUGIN_CONTINUE
	}
public admin_gag(id,level,cid)
{
	if(!cmd_access (id,level,cid,2)) return PLUGIN_HANDLED
	new arg[32],VictimID

	read_argv(1,arg,31)
	VictimID = cmd_target(id,arg,8)
	if ((get_user_flags(VictimID) & ADMIN_IMMUNITY) && VictimID != id || !cmd_access (id,level,cid,2) ) { return PLUGIN_HANDLED; }
	new s_Flags[4],VictimName[32],AdminName[32],flags,ShowFlags[32],CountFlags,s_GagTime[8],Float:f_GagTime

	read_argv(2,arg,31)
	if (!arg[0])
	{
		f_GagTime = DefaultGagTime
		format(s_Flags,7,"abc")
	}
	else
	{
		if(contain(arg,"m")!=-1 && contain(arg,"!")==-1)
		{
			copyc(s_GagTime,7,arg, 'm')
			f_GagTime = floatstr(s_GagTime) * 60
		}
		else if(isdigit(arg[0])&& contain(arg,"!")==-1)
		{
			format(s_GagTime,7,arg)
			f_GagTime = floatstr(s_GagTime)
		}
		read_argv(3,arg,8)
		if (!arg[0])
			format(s_Flags,7,"abc")
		else if(contain(arg,"!")==-1)
			format(s_Flags,7,arg)
		else if(contain(arg,"!")!=-1)
			format(s_Flags,7,"abc")
		if (f_GagTime == 0.0)
		{
			read_argv(2,arg,8)
			if(contain(arg,"!")!=-1)
				format(s_Flags,3,"abc")
			else
				format(s_Flags,3,arg)
			f_GagTime = DefaultGagTime
		}
#if GagReason == 1
		new GagReasonFound=0
		for(new i=2;i<=4;i++)
		{
			read_argv(i,arg,31)
			if(contain(arg,"!")!=-1)
			{
				read_args(arg,31)
				new tmp[32]
				copyc(tmp,32,arg,33)
				copy(gs_GagReason[VictimID],47,arg[strlen(tmp)+1])
				GagReasonFound = 1
			}
		}
		if(GagReasonFound == 0)
			format(gs_GagReason[VictimID],47,"You Were Gagged For Not Following The Rules")
#endif
	}

	flags = read_flags(s_Flags)
	g_GagPlayers[VictimID] = flags
#if VoiceCommMute == 1
	if(flags & 4)
		fm_set_speak(VictimID, SPEAK_MUTED)
#endif
	new TaskParm[1]
	TaskParm[0] = VictimID
	set_task( f_GagTime,"task_UnGagPlayer",VictimID,TaskParm,1)

	CountFlags = 0
	if (flags & 1)
	{
		format(ShowFlags,31,"say")
		CountFlags++
	}
	if (flags & 2)
	{
		if(CountFlags)
			format(ShowFlags,31,"%s / say_team",ShowFlags)
		if(!CountFlags)
			format(ShowFlags,31,"say_team")
	}
#if VoiceCommMute != 0
	if(flags & 4)
	{
		if(CountFlags)
			format(ShowFlags,31,"%s / voicecomm",ShowFlags)
		if(!CountFlags)
			format(ShowFlags,31,"voicecomm")
	}
#endif
	get_user_name(id,AdminName,31)
	get_user_name(VictimID,VictimName,31)

	switch(get_pcvar_num(amx_show_activity))
	{
#if GagReason == 1
		case 2:   client_print(0,print_chat,"%L", LANG_PLAYER, "AMX_SUPER_GAG_PLAYER_REASON_CASE2",AdminName,VictimName,gs_GagReason[VictimID],ShowFlags)
   		case 1:   client_print(0,print_chat,"%L", LANG_PLAYER, "AMX_SUPER_GAG_PLAYER_REASON_CASE1",VictimName,gs_GagReason[VictimID],ShowFlags)
#else
		case 2:   client_print(0,print_chat,"%L", LANG_PLAYER, "AMX_SUPER_GAG_PLAYER_CASE2",AdminName,VictimName,ShowFlags)
   		case 1:   client_print(0,print_chat,"%L", LANG_PLAYER, "AMX_SUPER_GAG_PLAYER_CASE1",VictimName,ShowFlags)
#endif

	 }
#if LogAdminActions == 1
	new parm[5]
	parm[0] = VictimID
	parm[1] = id
	parm[2] = 0
	parm[3] = flags
	parm[4] = floatround(Float:f_GagTime)
	LogAdminAction(parm)
#endif
	return PLUGIN_HANDLED
}

public admin_ungag(id,level,cid)
{
	new arg[32],VictimID
	read_argv(1,arg,31)

	VictimID = cmd_target(id,arg,8)
	if ((get_user_flags(VictimID) & ADMIN_IMMUNITY) && VictimID != id || !cmd_access (id,level,cid,2) ) { return PLUGIN_HANDLED; }

	new AdminName[32],VictimName[32]

	get_user_name(id,AdminName,31)
	get_user_name(VictimID,VictimName,31)

	if(!g_GagPlayers[VictimID])
	{
		console_print(id, "%L", LANG_PLAYER, "AMX_SUPER_NOT_GAGGED",arg)
		return PLUGIN_HANDLED
	}
	switch(get_pcvar_num(amx_show_activity))
	{
   		case 2:   client_print(0,print_chat, "%L", LANG_PLAYER, "AMX_SUPER_UNGAG_PLAYER_CASE2",AdminName,VictimName)
   		case 1:   client_print(0,print_chat, "%L", LANG_PLAYER, "AMX_SUPER_UNGAG_PLAYER_CASE1",VictimName)
  	}

#if LogAdminActions == 1
	new parm[3]
	parm[0] = VictimID
	parm[1] = id
	parm[2] = 1
	LogAdminAction(parm)
#endif
	remove_task(VictimID)
	UnGagPlayer(VictimID)
	return PLUGIN_HANDLED
}

#if BlockNameChange == 1
public client_infochanged(id)
{
	if(g_GagPlayers[id])
	{
		new newname[32], oldname[32]
		get_user_info(id, "name", newname,31)
		get_user_name(id,oldname,31)

		if (!equal(oldname,newname))
		{
			client_print(id,print_chat, "%L", LANG_PLAYER, "AMX_SUPER_PLAYER_NAMELOCK")
			set_user_info(id,"name",oldname)
		}
	}
}
#endif
public task_UnGagPlayer(TaskParm[])
{
	new VictimName[32]
	get_user_name(TaskParm[0],VictimName,31)
	client_print(0,print_chat, "%L", LANG_PLAYER, "AMX_SUPER_GAG_END",VictimName)
	UnGagPlayer(TaskParm[0])
}
#if LogAdminActions == 1
stock LogAdminAction(parm[])
{
	new VictimName[32],AdminName[32],AdminAuth[35],VictimAuth[35]
	get_user_name(parm[1],AdminName,31)
	get_user_name(parm[0],VictimName,31)
	get_user_authid(parm[1],AdminAuth,34)
	get_user_authid(parm[0],VictimAuth,34)

#if GagReason == 1
	if(parm[2] == 0)
		log_amx( "%L", LANG_PLAYER, "AMX_SUPER_GAG_PLAYER_REASON_LOG",AdminName,AdminAuth,VictimName,VictimAuth,parm[4],parm[3],gs_GagReason[parm[0]])
#else
	if(parm[2] == 0)
		log_amx( "%L", LANG_PLAYER, "AMX_SUPER_GAG_PLAYER_LOG",AdminName,AdminAuth,VictimName,VictimAuth,parm[4],parm[3])
#endif
	if(parm[2] == 1)
		log_amx( "%L", LANG_PLAYER, "AMX_SUPER_UNGAG_PLAYER_LOG",AdminName,AdminAuth,VictimName,VictimAuth)
}
#endif
stock UnGagPlayer(id)
{
#if VoiceCommMute == 1
	if(g_GagPlayers[id] & 4)
	{
		if(get_pcvar_num(sv_alltalk) == 1)
			fm_set_speak(id, SPEAK_ALL)
		else
			fm_set_speak(id, SPEAK_NORMAL)
	}
#endif
	g_GagPlayers[id] = 0
#if GagReason == 1
	setc(gs_GagReason[id],31,0)
#endif
}
#if AllowOtherPlugin2Interface == 1
public func_AddGag(id)
{
	g_GagPlayers[id] = 7
	new TaskParm[1]
	TaskParm[0] = id
#if VoiceCommMute == 1
	fm_set_speak(id, SPEAK_MUTED)
#endif
	set_task( DefaultGagTime,"task_UnGagPlayer",id,TaskParm,1)
}

public func_RemoveGag(id)
{
	remove_task(id)
	UnGagPlayer(id)
}
#endif

////////////////////////////////////////////////////////////////////////////////////////////////////////////
//ADMIN WEAPON III Build 6.7 by SniperBeamer\Girthesniper\Meatwad
//Revised by Bo0m!
//Upgraded by [DeathTV] Sid 6.7
//==========================================================================================================
public admin_weapon(id,level,cid)
{
	if ( !cmd_access(id,level,cid,3) )
		return PLUGIN_HANDLED

	new arg[32],arg2[8],weapon
	new aName[32], aAuthid[36]
	read_argv(1,arg,31)
	read_argv(2,arg2,7)
	get_user_name(id,aName,31)
	get_user_authid(id,aAuthid,35)

	weapon = str_to_num(arg2)

	if(!weapon){
		//cycle thru our weapons array under position 30 until match
		for(new i; i < 30; i++){
			if(containi(arg2,weapons[i][7]) != -1){
				weapon = RLWT[i]
				break
			}
		}
	}

	if (arg[0]=='@'){
		new plist[32], pnum
		if (equali("T",arg[1]))         copy(arg[1],31,"TERRORIST")
		if (equali("ALL",arg[1]))       get_players(plist,pnum,"a")
		else                            get_players(plist,pnum,"ae",arg[1])

		if (pnum == 0) {
			console_print(id,"%L", LANG_PLAYER, AMX_SUPER_NO_PLAYERS)
			return PLUGIN_HANDLED
		}


		for(new i=0; i<pnum; i++)
			give_weapon(plist[i],weapon)

		switch(get_pcvar_num(amx_show_activity))	{
			case 2:	console_print(0,"%L", LANG_PLAYER, "AMX_SUPER_WEAPON_TEAM_CASE2",aName,arg[1])
			case 1:	console_print(0,"%L", LANG_PLAYER, "AMX_SUPER_WEAPON_TEAM_CASE1",arg[1])
		}

		console_print(id,"%L", LANG_PLAYER, "AMX_SUPER_WEAPON_TEAM_MSG",weapon,arg[1])
		log_amx("%L", LANG_SERVER, "AMX_SUPER_WEAPON_TEAM_LOG",aName,aAuthid,weapon,arg[1])
	}
	else
	{
		new pName[32], pAuthid[36]
		new player = cmd_target(id,arg,7)
		if (!player) return PLUGIN_HANDLED
		give_weapon(player,weapon)
		get_user_name(player,pName,31)
		get_user_authid(player,pAuthid,35)

		switch(get_pcvar_num(amx_show_activity))	{
			case 2:	console_print(0,"%L", LANG_PLAYER, "AMX_SUPER_WEAPON_PLAYER_CASE2",aName,pName)
			case 1:	console_print(0,"%L", LANG_PLAYER, "AMX_SUPER_WEAPON_PLAYER_CASE1",pName)
		}

		console_print(id,"%L", LANG_PLAYER, "AMX_SUPER_WEAPON_PLAYER_MSG",weapon,pName)
		log_amx("%L", LANG_SERVER, "AMX_SUPER_WEAPON_PLAYER_LOG",aName,aAuthid,weapon,pName,pAuthid)
	}
	return PLUGIN_HANDLED
}

give_weapon(id,weapon)
{
	switch (weapon)
	{
		//Secondary weapons
		//Pistols
		case 1:{
			fm_give_item(id,weapons[WEAPON_KNIFE])
		}
		case 11:{
			fm_give_item(id,weapons[WEAPON_GLOCK18])
			fm_give_item_x(id,ammo_9mm,8)
		}
		case 12:{
			fm_give_item(id,weapons[WEAPON_USP])
			fm_give_item_x(id,ammo_45acp,9)
		}
		case 13:{
			fm_give_item(id,weapons[WEAPON_P228])
			fm_give_item_x(id,ammo_357sig,6)
		}
		case 14:{
			fm_give_item(id,weapons[WEAPON_DEAGLE])
			fm_give_item_x(id,ammo_50ae,7)
		}
		case 15:{
			fm_give_item(id,weapons[WEAPON_FIVESEVEN])
			fm_give_item_x(id,ammo_57mm,4)
		}
		case 16:{
			fm_give_item(id,weapons[WEAPON_ELITE])
			fm_give_item_x(id,ammo_9mm,8)
		}
		case 17:{
			//all pistols
			give_weapon(id,11)
			give_weapon(id,12)
			give_weapon(id,13)
			give_weapon(id,14)
			give_weapon(id,15)
			give_weapon(id,16)
		}
		//Primary weapons
		//Shotguns
		case 21:{
			fm_give_item(id,weapons[WEAPON_M3])
			fm_give_item_x(id,ammo_buckshot,4)
		}
		case 22:{
			fm_give_item(id,weapons[WEAPON_XM1014])
			fm_give_item_x(id,ammo_buckshot,4)
		}
		//SMGs
		case 31:{
			fm_give_item(id,weapons[WEAPON_TMP])
			fm_give_item_x(id,ammo_9mm,8)
		}
		case 32:{
			fm_give_item(id,weapons[WEAPON_MAC10])
			fm_give_item_x(id,ammo_45acp,9)
		}
		case 33:{
			fm_give_item(id,weapons[WEAPON_MP5NAVY])
			fm_give_item_x(id,ammo_9mm,8)
		}
		case 34:{
			fm_give_item(id,weapons[WEAPON_P90])
			fm_give_item_x(id,ammo_57mm,4)
		}
		case 35:{
			fm_give_item(id,weapons[WEAPON_UMP45])
			fm_give_item_x(id,ammo_45acp,9)
		}
		//Rifles
		case 40:{
			fm_give_item(id,weapons[WEAPON_FAMAS])
			fm_give_item_x(id,ammo_556nato,3)
		}
		case 41:{
			fm_give_item(id,weapons[WEAPON_GALIL])
			fm_give_item_x(id,ammo_556nato,3)
		}
		case 42:{
			fm_give_item(id,weapons[WEAPON_AK47])
			fm_give_item_x(id,ammo_762nato,3)
		}
		case 43:{
			fm_give_item(id,weapons[WEAPON_M4A1])
			fm_give_item_x(id,ammo_556nato,3)
		}
		case 44:{
			fm_give_item(id,weapons[WEAPON_SG552])
			fm_give_item_x(id,ammo_556nato,3)
		}
		case 45:{
			fm_give_item(id,weapons[WEAPON_AUG])
			fm_give_item_x(id,ammo_556nato,3)
		}
		case 46:{
			fm_give_item(id,weapons[WEAPON_SCOUT])
			fm_give_item_x(id,ammo_762nato,3)
		}
		case 47:{
			fm_give_item(id,weapons[WEAPON_SG550])
			fm_give_item_x(id,ammo_556nato,3)
		}
		case 48:{
			fm_give_item(id,weapons[WEAPON_AWP])
			fm_give_item_x(id,ammo_338magnum,3)
		}
		case 49:{
			fm_give_item(id,weapons[WEAPON_G3SG1])
			fm_give_item_x(id,ammo_762nato,3)
		}
		//Machine gun (M249 Para)
		case 51:{
			fm_give_item(id,weapons[WEAPON_M249])
			fm_give_item_x(id,ammo_556natobox,7)
		}
		//Shield combos
		case 60:{
			fm_give_item(id,weapons[WEAPON_SHIELD])
			fm_give_item(id,weapons[WEAPON_GLOCK18])
			fm_give_item_x(id,ammo_9mm,8)
			fm_give_item(id,weapons[WEAPON_HEGRENADE])
			fm_give_item(id,weapons[WEAPON_FLASHBANG])
			fm_give_item(id,weapons[WEAPON_FLASHBANG])
			fm_give_item(id,weapons[ITEM_ASSAULTSUIT])
		}
		case 61:{
			fm_give_item(id,weapons[WEAPON_SHIELD])
			fm_give_item(id,weapons[WEAPON_USP])
			fm_give_item_x(id,ammo_45acp,9)
			fm_give_item(id,weapons[WEAPON_HEGRENADE])
			fm_give_item(id,weapons[WEAPON_FLASHBANG])
			fm_give_item(id,weapons[WEAPON_FLASHBANG])
			fm_give_item(id,weapons[ITEM_ASSAULTSUIT])
		}
		case 62:{
			fm_give_item(id,weapons[WEAPON_SHIELD])
			fm_give_item(id,weapons[WEAPON_P228])
			fm_give_item_x(id,ammo_357sig,6)
			fm_give_item(id,weapons[WEAPON_HEGRENADE])
			fm_give_item(id,weapons[WEAPON_FLASHBANG])
			fm_give_item(id,weapons[WEAPON_FLASHBANG])
			fm_give_item(id,weapons[ITEM_ASSAULTSUIT])
		}
		case 63:{
			fm_give_item(id,weapons[WEAPON_SHIELD])
			fm_give_item(id,weapons[WEAPON_DEAGLE])
			fm_give_item_x(id,ammo_50ae,7)
			fm_give_item(id,weapons[WEAPON_HEGRENADE])
			fm_give_item(id,weapons[WEAPON_FLASHBANG])
			fm_give_item(id,weapons[WEAPON_FLASHBANG])
			fm_give_item(id,weapons[ITEM_ASSAULTSUIT])
		}
		case 64:{
			fm_give_item(id,weapons[WEAPON_SHIELD])
			fm_give_item(id,weapons[WEAPON_FIVESEVEN])
			fm_give_item_x(id,ammo_57mm,4)
			fm_give_item(id,weapons[WEAPON_HEGRENADE])
			fm_give_item(id,weapons[WEAPON_FLASHBANG])
			fm_give_item(id,weapons[WEAPON_FLASHBANG])
			fm_give_item(id,weapons[ITEM_ASSAULTSUIT])
		}
		//Equipment
		case 81:{
			fm_give_item(id,weapons[ITEM_KEVLAR])
		}
		case 82:{
			fm_give_item(id,weapons[ITEM_ASSAULTSUIT])
		}
		case 83:{
			fm_give_item(id,weapons[WEAPON_HEGRENADE])
		}
		case 84:{
			fm_give_item(id,weapons[WEAPON_FLASHBANG])
			fm_give_item(id,weapons[WEAPON_FLASHBANG])
		}
		case 85:{
			fm_give_item(id,weapons[WEAPON_SMOKEGRENADE])
		}
		case 86:{
			fm_give_item(id,weapons[ITEM_THIGHPACK])
		}
		case 87:{
			fm_give_item(id,weapons[WEAPON_SHIELD])
		}
		//All ammo
		case 88:{
			fm_give_item_x(id,ammo_45acp,9)
			fm_give_item_x(id,ammo_357sig,6)
			fm_give_item_x(id,ammo_9mm,8)
			fm_give_item_x(id,ammo_50ae,7)
			fm_give_item_x(id,ammo_57mm,4)
			fm_give_item_x(id,ammo_buckshot,4)
			fm_give_item_x(id,ammo_556nato,3)
			fm_give_item_x(id,ammo_762nato,3)
			fm_give_item_x(id,ammo_338magnum,3)
			fm_give_item_x(id,ammo_556natobox,7)
		}
		//All grenades
		case 89:{
			fm_give_item(id,weapons[WEAPON_HEGRENADE])
			fm_give_item(id,weapons[WEAPON_SMOKEGRENADE])
			fm_give_item(id,weapons[WEAPON_FLASHBANG])
			fm_give_item(id,weapons[WEAPON_FLASHBANG])
		}
		//C4
		case 91:{
			fm_give_item(id,weapons[WEAPON_C4])
			cs_set_user_plant(id,1,1)
		}
		case 92:{
			cs_set_user_nvg(id, 1)
		}
		//AWM Combo.
		case 100:{
			fm_give_item(id,weapons[WEAPON_AWP])
			fm_give_item(id,weapons[WEAPON_DEAGLE])
			fm_give_item(id,weapons[WEAPON_HEGRENADE])
			fm_give_item(id,weapons[WEAPON_FLASHBANG])
			fm_give_item(id,weapons[WEAPON_FLASHBANG])
			fm_give_item(id,weapons[WEAPON_SMOKEGRENADE])
			fm_give_item_x(id,ammo_338magnum,3)
			fm_give_item_x(id,ammo_50ae,7)
			fm_give_item(id,weapons[ITEM_ASSAULTSUIT])
		}
		//Money case.
 		case 160:{
			cs_set_user_money(id, 16000, 1)
		}
		//AllWeapons
		case 200:{
			//all up to wpnindex 51 are given.. replace w loop
			fm_give_item(id,weapons[WEAPON_USP])
			fm_give_item(id,weapons[WEAPON_GLOCK18])
			fm_give_item(id,weapons[WEAPON_DEAGLE])
			fm_give_item(id,weapons[WEAPON_P228])
			fm_give_item(id,weapons[WEAPON_ELITE])
			fm_give_item(id,weapons[WEAPON_FIVESEVEN])
			fm_give_item(id,weapons[WEAPON_M3])
			fm_give_item(id,weapons[WEAPON_XM1014])
			fm_give_item(id,weapons[WEAPON_TMP])
			fm_give_item(id,weapons[WEAPON_MAC10])
			fm_give_item(id,weapons[WEAPON_MP5NAVY])
			fm_give_item(id,weapons[WEAPON_P90])
			fm_give_item(id,weapons[WEAPON_UMP45])
			fm_give_item(id,weapons[WEAPON_FAMAS])
			fm_give_item(id,weapons[WEAPON_GALIL])
			fm_give_item(id,weapons[WEAPON_AK47])
			fm_give_item(id,weapons[WEAPON_M4A1])
			fm_give_item(id,weapons[WEAPON_SG552])
			fm_give_item(id,weapons[WEAPON_AUG])
			fm_give_item(id,weapons[WEAPON_SCOUT])
			fm_give_item(id,weapons[WEAPON_SG550])
			fm_give_item(id,weapons[WEAPON_AWP])
 			fm_give_item(id,weapons[WEAPON_G3SG1])
			fm_give_item(id,weapons[WEAPON_M249])
			fm_give_item_x(id,ammo_45acp,9)
			fm_give_item_x(id,ammo_357sig,6)
			fm_give_item_x(id,ammo_9mm,8)
			fm_give_item_x(id,ammo_50ae,7)
			fm_give_item_x(id,ammo_57mm,4)
			fm_give_item_x(id,ammo_buckshot,4)
			fm_give_item_x(id,ammo_556nato,3)
			fm_give_item_x(id,ammo_762nato,3)
			fm_give_item_x(id,ammo_338magnum,3)
			fm_give_item_x(id,ammo_556natobox,7)
			fm_give_item(id,weapons[WEAPON_HEGRENADE])
			fm_give_item(id,weapons[WEAPON_SMOKEGRENADE])
			fm_give_item(id,weapons[WEAPON_FLASHBANG])
			fm_give_item(id,weapons[WEAPON_FLASHBANG])
		}
		default: return false
	}
	return true
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////
//SERVER SHUTDOWN/RESTART 2.2 by Hawk552
//==========================================================================================================
public fnShutDown(id,level,cid)
{
	if(!cmd_access(id,level,cid,2) || g_bShuttingDown)
		return PLUGIN_HANDLED

	new szArg[6]
	read_argv(0,szArg,5)

	if(equali(szArg,"amx_r"))
		g_iMode = RESTART

	read_argv(1,szArg,5)
	new iTime = str_to_num(szArg)

	if(!iTime || iTime > 20)
	{
		console_print(id, "%L", LANG_PLAYER, "AMX_SUPER_SHUTDOWN_CONSOLE")

		return PLUGIN_HANDLED
	}

	new szName[32]
	get_user_name(id,szName,31)

	new szAuthid[32]
	get_user_authid(id,szAuthid,31)

	log_amx("%L", LANG_PLAYER, "AMX_SUPER_SHUTDOWN_MESSAGE_LOG",szName,id,szAuthid,g_iMode ? "restart" : "shutdown")

	switch(get_pcvar_num(amx_show_activity))
	{
		case 1 : client_print(0,print_chat, "%L", LANG_PLAYER, "AMX_SUPER_SHUTDOWN_CASE1",g_iMode ? "Restart" : "Shutdown",iTime)
		case 2 : client_print(0,print_chat, "%L", LANG_PLAYER, "AMX_SUPER_SHUTDOWN_CASE2",szName,g_iMode ? "Restart" : "Shutdown",iTime)
	}

	fnInitiate(iTime)

	return PLUGIN_HANDLED
}

public fnInitiate(iTime)
{
	g_bShuttingDown = true

	new iCount
	for(iCount = iTime;iCount != 0;iCount--)
		set_task(float(abs(iCount-iTime)),"fnCallTime",iCount)

	set_task(float(iTime),"fnCallTime",0)
}

public fnCallTime(iCount)
{
	if(!iCount)
	{
		switch(g_iMode)
		{
			case SHUTDOWN :
				server_cmd("quit")

			case RESTART :
				server_cmd("reload")
		}
	}

	new szWord[32]
	num_to_word(iCount,szWord,31)

	client_cmd(0,"spk ^"fvox/%s^"",szWord)
}



////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Death Event
//==========================================================================================================
public event_death() {

//----------------------------------------------------------------------------------------------------------
//SPECTATOR BUG FIX v1.0 by ]FUSION[ Gray Death
//----------------------------------------------------------------------------------------------------------
	new ids[1]
	ids[0] = read_data(2)
	set_task(1.0,"spectbugfix",0,ids,1)

//----------------------------------------------------------------------------------------------------------
//DEAD CHAT v2.1 by SuicideDog
//----------------------------------------------------------------------------------------------------------
	if ( get_pcvar_num(deadchat) == 1 ) {
		new id = read_data(2)
		if (is_user_connected(id) && fm_get_speak(id) != SPEAK_MUTED )
			fm_set_speak(id, SPEAK_LISTENALL)
		client_print(id,print_center,"%L", LANG_PLAYER, "AMX_SUPER_DEADCHAT_MESSAGE")
	}
	return PLUGIN_CONTINUE
}

public spectbugfix(ids[]) {
	client_cmd(ids[0],"+duck;-duck;spec_menu 0")
}


////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Player Connecting Event
//==========================================================================================================
public client_connect(id) {

	HasPermGod[id] = false
	HasPermNoclip[id] = false

	HasPermGlow[id] = false

	set_user_speak(id,SPEAK_NORMAL2)
	g_admin[id] = 0
	g_speed[id] = false;

//----------------------------------------------------------------------------------------------------------
//"SHOWNDEAD" SCOREBOARD FIX v0.9.4 by EJ/Vantage/Mouse
//----------------------------------------------------------------------------------------------------------
	if(!(is_user_bot(id)) ) {
		message_begin(MSG_ALL, gmsg_TeamInfo, {0, 0, 0}, id)
		write_byte(id)
		write_string(SpecName)
		message_end()
	}

//----------------------------------------------------------------------------------------------------------
//LOADING SOUNDS v1.0 by [OSA]Odin/White Panther
//----------------------------------------------------------------------------------------------------------
	if(get_pcvar_num(loadsong) == 1) {
		new i
		i = random_num(0,LOADINGSOUNDS-1)
		client_cmd(id,"mp3 play media/%s",soundlist[i])
	}

//----------------------------------------------------------------------------------------------------------
//AFK Manager by VEN
//----------------------------------------------------------------------------------------------------------
	g_connected[id] = true

	if (amx_reservation)
	return PLUGIN_CONTINUE

	static players[32], num, i, tchar[2]
	new candidate, candidatetime
	get_players(players, num, "b")
	for (new x; x < num; ++x) {
		i = players[x]

		if (get_user_flags(i)&get_immune_access_flag())
			continue

		get_user_team(i, tchar, 1)
		if (((tchar[0] == 'U' && get_user_time(i, 1) > get_pcvar_num(immune_time)) || tchar[0] == 'S') && (!candidatetime || g_specgametime[i] < candidatetime)) {
			candidatetime = g_specgametime[i]
			candidate = i
		}
	}

	if (candidate) {
		chat_msg(candidate, g_spec_kick_chat)
		client_kick(candidate, g_spec_kick_chat)
		return PLUGIN_CONTINUE
	}

	static origin[3], afktime
	get_players(players, num, "a")
	for (new x; x < num; ++x) {
		i = players[x]
		get_user_origin(i, origin)
		if (!is_user_afk(i, origin)) {
			g_afktime[i] = 0
			g_origin[i] = origin
			continue
		}

		afktime = g_afktime[i]
		if (afktime >= get_pcvar_num(max_afktime) && afktime > candidatetime) {
			candidatetime = afktime
			candidate = i
		}
	}

	if (candidate) {
		chat_msg(candidate, g_afk_kick_chat)
		client_kick(candidate, g_afk_kick_chat)
	}

	return PLUGIN_CONTINUE
}
public task_afk_check2() {

	if(!get_pcvar_num(afkcheck_allow))
		return

	static players[32], num, i, bool:allafk, origin[3]
	for (new a; a < 2; ++a) {
		get_players(players, num, "ae", g_teamname[a])
		allafk = true
		for (new x; x < num; ++x) {
			i = players[x]
			get_user_origin(i, origin)
			if (is_user_afk(i, origin)) {
				g_afktime[i] += AFK_CHECK_INTERVAL
				if (g_afktime[i] < get_pcvar_num(max_afktime))
					allafk = false
			}
			else {
				g_afktime[i] = 0
				g_origin[i] = origin
				allafk = false
			}
		}

		if (!allafk)
			continue

		for (new x; x < num; ++x) {
			i = players[x]
			chat_msg(i, g_afktospec_chat)
			user_to_spec(i)
		}
	}
}

public event_spectate() {
	new id = read_data(1)
	if (g_connected[id] && !g_specgametime[id])
		g_specgametime[id] = floatround(get_gametime())
}

public event_playteam() {
	new id = read_data(1)
	if (g_connected[id])
		clear_vars(id)
}

clear_vars(id) {
	g_origin[id][0] = 0
	g_origin[id][1] = 0
	g_origin[id][2] = 0
	g_afktime[id] = 0
	g_specgametime[id] = 0
}

bool:is_user_afk(id, const origin[3]) {
	return (origin[0] == g_origin[id][0] && origin[1] == g_origin[id][1])
}

chat_msg(id, const text[]) {
	static name[32]
	get_user_name(id, name, 31)
	client_print(0, print_chat, "%L", LANG_PLAYER, text, name)
}

stock client_kick(id, const lang[]){
	new user_name[ 32 ];
	get_user_name( id, user_name, charsmax( user_name ) )

	server_cmd( "kick #%d ^"%L^"", get_user_userid( id ), LANG_PLAYER, lang, user_name )
	server_exec()
}

stock user_to_spec(id) {
	user_kill(id, 1)
	engclient_cmd(id, "jointeam", "6")
}
////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Player Spawn Event
//==========================================================================================================
public event_fm_DispatchSpawned(id) {

	if(HasPermGod[id])
		fm_set_user_godmode(id,1)

	if(HasPermNoclip[id])
		fm_set_user_noclip(id,1)

	if ( get_pcvar_num(deadchat)==1 ) {
		if (is_user_connected(id) && fm_get_speak(id) != SPEAK_MUTED )
			fm_set_speak(id, SPEAK_NORMAL)
	}
	return PLUGIN_CONTINUE
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////
// CurWeapon Event
//==========================================================================================================
public changeWeapon(id)
{
	if(unammo[id])
	{
		new wpnid = read_data(2);
		new clip = read_data(3);

		if (wpnid == CSW_C4 || wpnid == CSW_KNIFE) return;
		if (wpnid == CSW_HEGRENADE || wpnid == CSW_SMOKEGRENADE || wpnid == CSW_FLASHBANG) return;

		if (clip == 0) reloadAmmo(id);
	}
}


////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Player Disconnect Event
//==========================================================================================================
public client_disconnect(id) {

	fm_plinfo[id] = SPEAK_NORMAL;

	HasPermGod[id] = false
	HasPermNoclip[id] = false

	HasPermGlow[id] = false

	badaim[id] = false
	autoban[id] = false

	new param[1]
    	param[0] = id
    	set_task(2.0, "leave_msg", 0, param, 1)

	for( new i = 0; i < 4; i++ )
		g_glow[id][i] = 0

	if( g_gagged[id] )
	{
		new name[32]
		get_user_name( id, name, 31 )
		get_user_authid( id, g_wasgagged[id], 31 )
		client_print( 0, print_chat, "%L", LANG_PLAYER, AMX_SUPER_GAG_CONNECTED, name, g_wasgagged[id] )
		g_gagged[id] = 0
	}

	remove_task(id)

	if (g_admin[id]) {
		set_user_speak(id,SPEAK_NORMAL2)
		g_admin[id] = 0
	}

	team[id] = CS_TEAM_UNASSIGNED

	g_connected[id] = false
	clear_vars(id)

   	return PLUGIN_HANDLED
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Precache Files
//==========================================================================================================
public plugin_precache()
{
	mflash = precache_model("sprites/muzzleflash.spr")
	smoke = precache_model("sprites/steam1.spr")
	blueflare2 = precache_model( "sprites/blueflare2.spr")
	white = precache_model("sprites/white.spr")
	light = precache_model("sprites/lgtning.spr")

	//Slay 2 & Quit Sounds
	precache_sound("ambience/thunder_clap.wav")
	precache_sound("weapons/headshot2.wav")

	//Fire Sounds
	precache_sound("ambience/flameburst1.wav")
	precache_sound("scientist/scream21.wav")
	precache_sound("scientist/scream07.wav")

	//Rocket Sounds
	precache_sound("weapons/rocketfire1.wav")
	precache_sound("weapons/rocket1.wav")

	//Flashbang Sound
	precache_sound("weapons/flashbang-2.wav")


}
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1046\\ f0\\ fs16 \n\\ par }
*/
