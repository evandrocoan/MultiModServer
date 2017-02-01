/* AMX Mod X script.
*
*   Ultimate Gore Enhancement (amx_gore_ultimate.sma)
*   Copyright (C) 2003-2004  mike_cao / fizzarum / jtp10181
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
****************************************************************************
*
*   Version 1.6 - 05/18/2008
*
*   by jtp10181 <jtp@jtpage.net>
*   Homepage: http://www.jtpage.net
*
*   Original code by:
*     by mike_cao <mike@mikecao.com> (plugin_gore)
*     fizzarum <tntmr2gg2@icqmail.com> (plugin_gore2)
*
****************************************************************************
*
*   This plugin adds gore effects. It is configured
*   with the cvar "amx_gore" using these flags:
*
*   a - Headshot blood
*   b - Extra blood effects
*   c - Bleeding on low health
*   d - Gib explosion (Explosives and damage over "amx_gore_exphp")
*   e - Extra Gory Mode
*   f - Extra Headshot Gore Only (same as with flag "e")
*   g - Hostage Gore (CS/CZ Only)
*
*   Default is: amx_gore "abcd"
*
*   New CVAR: amx_gore_exphp (default 160)
*         The amount of health that must be lost upon death
*         for the player to "explode"
*
*   Add the cvars to your amxx.cfg to change it and have it load every map
*
*   *NOTE*: the decal indexes are pulled form the servers decals.wad  If you
*	do not have the orginal decals.wad (for your mod) on the server the
*	decals may not appear as blood, but arrows, numbers, text, etc.
*
*   v1.6 - JTP10181 - 07/09/06
*	- Added a single spray with normal headshot gore
*	- Added new flag for extra headshot gore only
*	- Added support for module auto loading
*	- Added support for SvenCoop
*	- Added minimal support for NS
*	- Finally found proper way to hide corpses in CS/CZ/DoD
*	- Fully ported to FakeMeta
*
*   v1.5 - JTP10181 - 06/27/06
*	- Added support for ESF
*	- Added support for TS
*	- Added support for TFC
*	- Tweaked a lot of numbers
*	- Made gibs fly around more instead of in a big heap
*	- Added support for hostages in CS
*	- Switched all supporting mods to client_damage/death forwards
*
*   v1.4 - JTP10181 - 06/16/06
*	- Switched to Pointer CVAR commands
*	- Updated to work on "valve" mod by request
*	- Finally finished support for DoD
*	- Reduced the insane ammount of blood spray with gibs & extra gore enabled
*
*   v1.3.5 - JTP10181 - 03/05/06
*	- Fixed possible runtime errors if player disconnects during events
*
*   v1.3.4 - JTP10181 - 10/25/05
*	- Added knife to the gib_wpncheck check
*	- Fixed bug where if all damage was from falling the player would not bleed
*
*   v1.3.3 - JTP10181 - 09/25/04
*	- Made it really easy to change the weapons that cause explosion
*	- Minor code tweaks
*
*   v1.3.2 - JTP10181 - 09/24/04
*	- Fixed code to work on AMXModX 0.20
*	- Added new CVAR to adjust the HP loss that triggers a GIB explosion
*	- Used task for body hiding so items wont end up underground
*
*   v1.3.1 - JTP10181 - 06/02/04
*	- Fixed runtime error if victim is null on a damage or death event
*		Was happening in conjunction with superhero mod
*		Thanks to drummeridiot25 for testing it for me
*
*   v1.3 - JTP
*	- Automatic mod detection, no more recompiling for CZERO.
*	- Decal indexes verified for CZ, they work perfectly.
*	- Started working on DoD support
*
*   v1.2 - JTP
*	- Combined various gore plugins into one that has the best features
*		out of all of them.
*	- Plan to maintain this plugin if any issues/requests arrise.
*	- Added extra gory mode:
*		Classic headshot death with the sprays shooting up (from orginal plugin_gore)
*		More blood spraying on a gib explosion (from orginal plugin_gore)
*		Extra blood decals on damage and deaths
*	- Fixed divide by zero error in fx_blood and fx_gib_explode
*	- Minor tweaks here and there to some of the numbers
*	- Put in fix for CZERO decals from "euro" and "out" from AMX forums
*	- Fixed runtime error when the attacker was not able to be determinted.
*		get_user_origin was getting passed a "0" player index.
*
*
*   v1.03 - ( by fizzarum ) :
*	- Each hit now causes a blood stream depending on the positions of the
*		agressor and the victim.
*	- Reduce the previous headshot fx to a less extravagant thing
*	- The gib explosion now happens after a damage higher than 110 EVEN IF
*		the victim's head was hit
*	- A knife kill does not cause a gib explosion
*	- Minor changes on the bleeding effect, the position of the gibs
*
*   Thanks:
*	- mike_cao for the orginal plugin
*	- fizzarum on plugin_gore2.sma (for AMX)
*	- euro and out (AMX forums) for posting decal numbers for CZero
*	- SidLuke (AMX forums) for his version for DoD,
*		I grabbed some of that code for my DoD support
*
**************************************************************************/

//Comment this out to totally disable the GIB code
//This can help if maps are crashing from exceeding the precache limit
#define GIBS_ENABLED

#include <amxmodx>
#include <amxmisc>
#include <fakemeta>
#include <dodconst>
#include <tfcconst>
#include <tsconst>

//Auto-load the correct module if not loaded
#pragma reqclass xstats
#if !defined AMXMODX_NOAUTOLOAD
   #pragma defclasslib xstats csx
   #pragma defclasslib xstats dodx
   #pragma defclasslib xstats tfcx
   #pragma defclasslib xstats tsx
#endif

#define MAX_PLAYERS 32
#define MAX_HOSTAGES 16

#define GORE_HEADSHOT       (1<<0) // "a"
#define GORE_BLOOD          (1<<1) // "b"
#define GORE_BLEEDING       (1<<2) // "c"
#define GORE_GIB            (1<<3) // "d"
#define GORE_EXTRA          (1<<4) // "e"
#define GORE_EXTRA_HS       (1<<5) // "f"
#define GORE_HOSTAGES       (1<<6) // "g"

#define BLOOD_COLOR_RED		247
#define BLOOD_COLOR_YELLOW	195
#define BLOOD_STREAM_RED	70
#define BLOOD_STREAM_YELLOW	60

new gHealthIndex[MAX_PLAYERS+1]
new Float:hostage_hp[MAX_HOSTAGES], hostages[MAX_HOSTAGES], host_num

#if defined GIBS_ENABLED
new mdl_gib_flesh, mdl_gib_head, mdl_gib_legbone
new mdl_gib_lung, mdl_gib_meat, mdl_gib_spine
#endif

new spr_blood_drop, spr_blood_spray

#define BLOOD_SM_NUM 8
#define BLOOD_LG_NUM 2
new blood_small_red[BLOOD_SM_NUM], blood_large_red[BLOOD_LG_NUM]
//new blood_small_yellow[BLOOD_SM_NUM], blood_large_yellow[BLOOD_LG_NUM]

new mod_name[32], bool:body_hidden[33]
new pcvar_gore, pcvar_gore_exphp

//Offsets to place blood is more realistic hit location
new Offset[8][3] = {{0,0,10},{0,0,30},{0,0,16},{0,0,10},{4,4,16},{-4,-4,16},{4,4,-12},{-4,-4,-12}}

// #####################################################################
// ##     Change which weapons cause GIB explosions on death HERE     ##
// #####################################################################

public gib_wpncheck(iWeapon)
{
	//This section is used for CS/CZ
	if (cstrike_running()) {
		switch (iWeapon) {
			case CSW_P228			: return false
			case CSW_SCOUT			: return false
			case CSW_HEGRENADE		: return true
			case CSW_XM1014		: return false
			case CSW_C4			: return true
			case CSW_MAC10			: return false
			case CSW_AUG			: return false
			case CSW_SMOKEGRENADE	: return true
			case CSW_ELITE			: return false
			case CSW_FIVESEVEN		: return false
			case CSW_UMP45			: return false
			case CSW_SG550			: return false
			case CSW_GALIL			: return false
			case CSW_FAMAS			: return false
			case CSW_USP			: return false
			case CSW_GLOCK18		: return false
			case CSW_AWP			: return false
			case CSW_MP5NAVY		: return false
			case CSW_M249			: return false
			case CSW_M3			: return false
			case CSW_M4A1			: return false
			case CSW_TMP			: return false
			case CSW_G3SG1			: return false
			case CSW_FLASHBANG		: return true
			case CSW_DEAGLE		: return false
			case CSW_SG552			: return false
			case CSW_AK47			: return false
			case CSW_KNIFE			: return false
			case CSW_P90			: return false
		}
	}
	//This section is used for DoD
	else if (equali(mod_name,"dod")) {
		switch (iWeapon) {
			case DODW_AMERKNIFE			: return false
			case DODW_GERKNIFE			: return false
			case DODW_COLT				: return false
			case DODW_LUGER			: return false
			case DODW_GARAND			: return false
			case DODW_SCOPED_KAR		: return false
			case DODW_THOMPSON			: return false
			case DODW_STG44			: return false
			case DODW_SPRINGFIELD		: return false
			case DODW_KAR				: return false
			case DODW_BAR				: return false
			case DODW_MP40				: return false
			case DODW_HANDGRENADE		: return true
			case DODW_STICKGRENADE		: return true
			case DODW_STICKGRENADE_EX	: return true
			case DODW_HANDGRENADE_EX		: return true
			case DODW_MG42				: return false
			case DODW_30_CAL			: return false
			case DODW_SPADE			: return false
			case DODW_M1_CARBINE		: return false
			case DODW_MG34				: return false
			case DODW_GREASEGUN			: return false
			case DODW_FG42				: return false
			case DODW_K43				: return false
			case DODW_ENFIELD			: return false
			case DODW_STEN				: return false
			case DODW_BREN				: return false
			case DODW_WEBLEY			: return false
			case DODW_BAZOOKA			: return true
			case DODW_PANZERSCHRECK		: return false
			case DODW_PIAT				: return false
			case DODW_SCOPED_FG42		: return false
			case DODW_FOLDING_CARBINE	: return false
			case DODW_KAR_BAYONET		: return false
			case DODW_SCOPED_ENFIELD		: return false
			case DODW_MILLS_BOMB		: return true
			case DODW_BRITKNIFE			: return false
			case DODW_GARAND_BUTT		: return false
			case DODW_ENFIELD_BAYONET	: return false
			case DODW_MORTAR			: return false
			case DODW_K43_BUTT			: return false
		}
	}
	//This section is used for TFC
	else if (equali(mod_name,"tfc")) {
		switch (iWeapon) {
			case TFC_WPN_NONE				: return false
			case TFC_WPN_TIMER				: return false
			case TFC_WPN_SENTRYGUN			: return false
			case TFC_WPN_MEDIKIT			: return false
			case TFC_WPN_SPANNER			: return false
			case TFC_WPN_AXE				: return false
			case TFC_WPN_SNIPERRIFLE			: return false
			case TFC_WPN_AUTORIFLE			: return false
			case TFC_WPN_SHOTGUN			: return false
			case TFC_WPN_SUPERSHOTGUN		: return false
			case TFC_WPN_NG				: return false
			case TFC_WPN_SUPERNG			: return false
			case TFC_WPN_GL				: return false
			case TFC_WPN_FLAMETHROWER		: return false
			case TFC_WPN_RPG				: return true
			case TFC_WPN_IC				: return false
			case TFC_WPN_FLAMES				: return false
			case TFC_WPN_AC				: return false
			case TFC_WPN_UNK18				: return false
			case TFC_WPN_UNK19				: return false
			case TFC_WPN_TRANQ				: return false
			case TFC_WPN_RAILGUN			: return false
			case TFC_WPN_PL				: return false
			case TFC_WPN_KNIFE				: return false
			case TFC_WPN_CALTROP			: return false
			case TFC_WPN_CONCUSSIONGRENADE	: return true
			case TFC_WPN_NORMALGRENADE		: return true
			case TFC_WPN_NAILGRENADE			: return true
			case TFC_WPN_MIRVGRENADE			: return true
			case TFC_WPN_NAPALMGRENADE		: return true
			case TFC_WPN_GASGRENADE			: return false
			case TFC_WPN_EMPGRENADE			: return false
		}

	}
	//This section is used for TS
	else if (equali(mod_name,"ts")) {
		switch (iWeapon) {
			case TSW_GLOCK18		: return false
			case TSW_UNK1			: return false
			case TSW_UZI			: return false
			case TSW_M3			: return false
			case TSW_M4A1			: return false
			case TSW_MP5SD			: return false
			case TSW_MP5K			: return false
			case TSW_ABERETTAS		: return false
			case TSW_MK23			: return false
			case TSW_AMK23			: return false
			case TSW_USAS			: return false
			case TSW_DEAGLE		: return false
			case TSW_AK47			: return false
			case TSW_57			: return false
			case TSW_AUG			: return false
			case TSW_AUZI			: return false
			case TSW_TMP			: return false
			case TSW_M82A1			: return false
			case TSW_MP7			: return false
			case TSW_SPAS			: return false
			case TSW_GCOLTS		: return false
			case TSW_GLOCK20		: return false
			case TSW_UMP			: return false
			case TSW_M61GRENADE		: return true
			case TSW_CKNIFE		: return false
			case TSW_MOSSBERG		: return false
			case TSW_M16A4			: return false
			case TSW_MK1			: return false
			case TSW_C4			: return true
			case TSW_A57			: return false
			case TSW_RBULL			: return false
			case TSW_M60E3			: return false
			case TSW_SAWED_OFF		: return true
			case TSW_KATANA		: return false
			case TSW_SKNIFE		: return false
			case TSW_KUNG_FU		: return false
			case TSW_TKNIFE		: return false
		}
	}
	//This section is used for ESF
	else if (equali(mod_name,"esf")) {
		//Always do GIB explosions on ESF
		return true
	}
	//This section is used for the "valve" mod
	else if (equali(mod_name,"valve")) {
		switch (iWeapon) {
			case HLW_NONE			: return false
			case HLW_CROWBAR		: return false
			case HLW_GLOCK			: return false
			case HLW_PYTHON		: return false
			case HLW_MP5			: return false
			case HLW_CHAINGUN		: return false
			case HLW_CROSSBOW		: return false
			case HLW_SHOTGUN		: return false
			case HLW_RPG			: return true
			case HLW_GAUSS			: return false
			case HLW_EGON			: return false
			case HLW_HORNETGUN		: return false
			case HLW_HANDGRENADE	: return true
			case HLW_TRIPMINE		: return true
			case HLW_SATCHEL		: return true
			case HLW_SNARK			: return false
		}
	}

	//Always false on Sven Co-op
	return false
}

// #####################################################################
// ##                     DO NOT EDIT BELOW HERE                      ##
// #####################################################################

/************************************************************
* PLUGIN FUNCTIONS
************************************************************/

public plugin_init()
{
	register_plugin("Ultimate Gore","1.6","JTP10181")

	get_modname(mod_name,31)

	if (cstrike_running()) {
		register_logevent("event_roundstart", 2, "1=Round_Start")
		register_event("TextMsg","event_host_damage","b","2=#Injured_Hostage")
		register_event("TextMsg","event_host_killed","b","2=#Killed_Hostage")
		register_message(122, "event_ClCorpse") //ClCorpse
	}
	else if (equali(mod_name,"dod")) {
		register_message(126, "event_ClCorpse") //ClCorpse
	}
	else if (equali(mod_name,"esf")) {
		register_event("DeathMsg","event_death","a")
		register_event("Health","event_damage","b")
	}
	else if (equali(mod_name,"svencoop")) {
		register_event("Damage","event_damage","b","2!0")
	}
	else if (equali(mod_name,"valve") || equali(mod_name,"ns")) {
		register_event("DeathMsg","event_death","a")
		register_event("Damage","event_damage","b","2!0")
	}

	register_event("ResetHUD","event_respawn","b")

	pcvar_gore = register_cvar("amx_gore","abcd")
	pcvar_gore_exphp = register_cvar("amx_gore_exphp","160")
	set_task(1.5,"event_blood",100,"",0,"b")

	// Blood decals
	if (equali(mod_name,"cstrike")) {
		blood_large_red = {204,205}
		blood_small_red = {190,191,192,193,194,195,196,197}
	}
	else if (equali(mod_name,"czero")) {
		blood_large_red = {216,217}
		blood_small_red = {202,203,204,205,206,207,208,209}
	}
	else if (equali(mod_name,"dod")) {
		blood_large_red = {217,218}
		blood_small_red = {203,204,205,206,207,208,209,210}
	}
	else if (equali(mod_name,"tfc")) {
		blood_large_red = {208,209}
		blood_small_red = {194,195,196,197,198,199,200,201}
	}
	else if (equali(mod_name,"ts")) {
		blood_large_red = {218,219}
		blood_small_red = {204,205,206,207,208,209,210,211}
	}
	else if (equali(mod_name,"svencoop")) {
		blood_large_red = {210,211}
		blood_small_red = {196,197,198,199,200,201,202,203}
	}
	//"valve" mod and others that use its decals.wad (ESF, NS)
	else {
		blood_large_red = {19,20}
		blood_small_red = {27,28,29,30,31,32,33,34}
	}

	//Setup jtp10181 CVAR
	new cvarString[256], shortName[16]
	copy(shortName,15,"gore")

	register_cvar("jtp10181","",FCVAR_SERVER|FCVAR_SPONLY)
	get_cvar_string("jtp10181",cvarString,255)

	if (strlen(cvarString) == 0) {
		formatex(cvarString,255,shortName)
		set_cvar_string("jtp10181",cvarString)
	}
	else if (contain(cvarString,shortName) == -1) {
		format(cvarString,255,"%s,%s",cvarString, shortName)
		set_cvar_string("jtp10181",cvarString)
	}
}

public plugin_natives()
{
	set_module_filter("module_filter")
	set_native_filter("native_filter")
}

public module_filter(const module[])
{
	if (equali(module, "xstats")) {
		if (cstrike_running()) return PLUGIN_CONTINUE
		if (equali(mod_name,"dod")) return PLUGIN_CONTINUE
		if (equali(mod_name,"tfc")) return PLUGIN_CONTINUE
		if (equali(mod_name,"ts")) return PLUGIN_CONTINUE

		return PLUGIN_HANDLED
	}
	return PLUGIN_CONTINUE
}

public native_filter(const name[], index, trap)
{
	if (!trap) return PLUGIN_HANDLED

	return PLUGIN_CONTINUE
}

public plugin_precache()
{
	spr_blood_drop = precache_model("sprites/blood.spr")
	spr_blood_spray = precache_model("sprites/bloodspray.spr")

	#if defined GIBS_ENABLED
	mdl_gib_flesh = precache_model("models/Fleshgibs.mdl")
	mdl_gib_meat = precache_model("models/GIB_B_Gib.mdl")
	mdl_gib_head = precache_model("models/GIB_Skull.mdl")

	if (!equali(mod_name,"dod")) {
		mdl_gib_spine = precache_model("models/GIB_B_Bone.mdl")
		mdl_gib_lung = precache_model("models/GIB_Lung.mdl")
		mdl_gib_legbone = precache_model("models/GIB_Legbone.mdl")
	}
	#endif
}

public plugin_cfg()
{
	if (!cstrike_running()) return

	new iEnt = -1
	host_num = 0
	while ((iEnt = engfunc(EngFunc_FindEntityByString, iEnt, "classname", "hostage_entity")) != 0) {
		hostages[host_num++] = iEnt
		if (host_num >= MAX_HOSTAGES) break
	}
}

//Custom function to get origin with FM and return it as an integer
public get_origin_int(index, origin[3])
{
	new Float:FVec[3]

	pev(index,pev_origin,FVec)

	origin[0] = floatround(FVec[0])
	origin[1] = floatround(FVec[1])
	origin[2] = floatround(FVec[2])

	return 1
}

/************************************************************
* EVENTS
************************************************************/

//For "valve", ESF, NS, SvenCoop
public event_damage(iVictim)
{
	if (iVictim <= 0 || iVictim > MAX_PLAYERS) return

	new iWeapon, iHitPlace, iAgressor
	iAgressor = get_user_attacker(iVictim,iWeapon,iHitPlace)

	//Sven Co-op does not seem to send Death messages so we will do this
	if (equali(mod_name,"svencoop")) {
		if (get_user_health(iVictim) <=0) {
			process_death(iAgressor, iVictim, iWeapon, iHitPlace)
			return
		}
	}

	process_damage(iAgressor, iVictim, iHitPlace)
}

//Forward for CS/CZ, DoD, TFC, TS
public client_damage(attacker,victim,damage,wpnindex,hitplace)
{
	if (victim <= 0 || victim > MAX_PLAYERS) return
	process_damage(attacker, victim, hitplace)
}

//This will process the damage info for all mods
process_damage(iAgressor, iVictim, iHitPlace)
{
	new iFlags = get_gore_flags()

	//Don't want to do this if the player just died
	new vHealth = get_user_health(iVictim)
	if (vHealth <= 0 || vHealth >= gHealthIndex[iVictim]) return

	//server_print("************************* DAMAGE: %d %d %d %d", iVictim, iAgressor, vHealth, iHitPlace)

	gHealthIndex[iVictim] = vHealth

	//Check to make sure its a valid entity
	if (!pev_valid(iAgressor)) {
		iAgressor = iVictim
		iHitPlace = 0
	}

	//Crash/error check
	if (!is_user_connected(iVictim)) return
	if (iHitPlace < 0 || iHitPlace > 7) iHitPlace = 0

	if (iFlags&GORE_BLOOD) {
		new iOrigin[3], iOrigin2[3]
		get_origin_int(iVictim,iOrigin)
		get_origin_int(iAgressor,iOrigin2)

		fx_blood(iOrigin,iOrigin2,iHitPlace)
		fx_blood_small(iOrigin,8)
		if (iFlags&GORE_EXTRA) {
			fx_blood(iOrigin,iOrigin2,iHitPlace)
			fx_blood(iOrigin,iOrigin2,iHitPlace)
			fx_blood(iOrigin,iOrigin2,iHitPlace)
			fx_blood_small(iOrigin,4)
		}
	}
}

//Hostage Event for CS/CZ
public event_host_damage(iAgressor)
{
	new Float:vHeatlh, iVictim, iHitPlace = 0
	new iFlags = get_gore_flags()
	new hostid, Float:hosthp

	if (!(iFlags&GORE_HOSTAGES)) return

	//Find what hostage was injured
	for (new x = 0; x < host_num; x++) {
		hostid = hostages[x]
		hosthp = hostage_hp[x]

		if (!pev_valid(hostid)) continue
		if (hosthp <= 0.0) continue
		pev(hostid, pev_health, vHeatlh)

		if (vHeatlh > 0.0 && vHeatlh < hosthp) {
			iVictim = hostid
		}

		hosthp = vHeatlh
	}

	//No valid hostage entity found
	if (iVictim <= 0) return

	//Check to make sure its a player
	if (!is_user_connected(iAgressor)) {
		iAgressor = iVictim
	}

	if (iFlags&GORE_BLOOD) {
		new iOrigin[3], iOrigin2[3]

		get_origin_int(iVictim, iOrigin)
		get_origin_int(iAgressor, iOrigin2)

		//Add height to Hostage origin
		iOrigin[2] += 36

		fx_blood(iOrigin,iOrigin2,iHitPlace)
		fx_blood_small(iOrigin,8)
		if (iFlags&GORE_EXTRA) {
			fx_blood(iOrigin,iOrigin2,iHitPlace)
			fx_blood(iOrigin,iOrigin2,iHitPlace)
			fx_blood(iOrigin,iOrigin2,iHitPlace)
			fx_blood_small(iOrigin,4)
		}
	}
}

//For "valve", ESF, NS
public event_death()
{
	new iVictim = read_data(2)
	new iWeapon, iHitPlace

	if (iVictim <= 0 || iVictim > MAX_PLAYERS) return
	new iAgressor = get_user_attacker(iVictim,iWeapon,iHitPlace)

	process_death(iAgressor, iVictim, iWeapon, iHitPlace)
}

//Forward for CS/CZ, DoD, TFC, TS
public client_death(killer,victim,wpnindex,hitplace)
{
	if (victim <= 0 || victim > MAX_PLAYERS) return
	process_death(killer, victim, wpnindex, hitplace)
}

//This will process the death info for all mods
process_death(iAgressor, iVictim, iWeapon, iHitPlace)
{
	//server_print("************************* DEATH: %d %d %d %d", iVictim, iAgressor, iWeapon, iHitPlace)

	new iOrigin[3], iOrigin2[3]
	new iFlags = get_gore_flags()

	//Check to make sure its a valid entity
	if (!pev_valid(iAgressor)) {
		iAgressor = iVictim
		iWeapon = 0
		iHitPlace = 0
	}

	if (!is_user_connected(iVictim)) return

	get_origin_int(iVictim, iOrigin)
	get_origin_int(iAgressor, iOrigin2)

	if (iFlags&GORE_HEADSHOT && iHitPlace == HIT_HEAD) {
		fx_headshot(iOrigin)
	}

	#if defined GIBS_ENABLED
	if (iFlags&GORE_GIB && (gib_wpncheck(iWeapon) || gHealthIndex[iVictim] - get_user_health(iVictim) >= get_pcvar_num(pcvar_gore_exphp))) {

		// Effects
		fx_invisible(iVictim)
		body_hidden[iVictim] = true

		fx_gib_explode(iOrigin,iOrigin2)
		fx_blood_large(iOrigin,4)
		fx_blood_small(iOrigin,4)
	}
	#endif

	fx_blood_small(iOrigin,8)

	if (iFlags&GORE_EXTRA && !equali(mod_name,"dod")) {
		fx_extra_blood(iOrigin)
		fx_blood_large(iOrigin,2)
		fx_blood_small(iOrigin,4)
	}
}

//Hostage Event for CS/CZ
public event_host_killed(iAgressor)
{
	new Float:vHeatlh, HP_Loss, iVictim, iWeapon = 0, clip, ammo
	new iFlags = get_gore_flags()
	new hostid, Float:hosthp

	if (!(iFlags&GORE_HOSTAGES)) return

	//Find what hostage was killed
	for (new x = 0; x < host_num; x++) {
		hostid = hostages[x]
		hosthp = hostage_hp[x]

		if (!pev_valid(hostid)) continue
		if (hosthp <= 0.0) continue

		pev(hostid, pev_health, vHeatlh)

		if (vHeatlh <= 0.0 && vHeatlh < hosthp) {
			iVictim = hostid
			HP_Loss = floatround(hosthp - vHeatlh)
		}

		hosthp = vHeatlh
	}

	//No valid hostage entity found
	if (iVictim <= 0) return

	//Check to make sure its a player
	if (is_user_alive(iAgressor)) {
		iWeapon =  get_user_weapon(iAgressor,clip,ammo)
	}
	else {
		iAgressor = iVictim
	}

	new iOrigin[3], iOrigin2[3]

	get_origin_int(iVictim, iOrigin)
	get_origin_int(iAgressor, iOrigin2)

	//Add height to Hostage origin
	iOrigin[2] += 36

	#if defined GIBS_ENABLED
	if (iFlags&GORE_GIB && (gib_wpncheck(iWeapon) || HP_Loss >= floatround(get_pcvar_float(pcvar_gore_exphp) * 0.6))) {

		// Effects
		fx_invisible(iVictim)
		fx_gib_explode(iOrigin,iOrigin2)
		fx_blood_large(iOrigin,4)
		fx_blood_small(iOrigin,4)
	}
	#endif

	fx_blood_small(iOrigin,8)
	if (iFlags&GORE_EXTRA) {
		fx_extra_blood(iOrigin)
		fx_blood_large(iOrigin,2)
		fx_blood_small(iOrigin,4)
	}
}

public event_blood()
{
	new iFlags = get_gore_flags()
	if (!(iFlags&GORE_BLEEDING)) return

	new iPlayer, iPlayers[MAX_PLAYERS], iNumPlayers, iOrigin[3]
	get_players(iPlayers,iNumPlayers,"a")
	for (new i = 0; i < iNumPlayers; i++) {
		iPlayer = iPlayers[i]
		gHealthIndex[iPlayer] = get_user_health(iPlayer)
		if (gHealthIndex[iPlayer] < 20) {
			get_origin_int(iPlayer, iOrigin)
			fx_bleed(iOrigin)
			fx_blood_small(iOrigin,3)
		}
	}

	if (!(iFlags&GORE_HOSTAGES)) return

	//Hostage Bleeding
	if (cstrike_running()) {
		new iOrigin[3], hostid, Float:hosthp
		for (new x = 0; x < host_num; x++) {
			hostid = hostages[x]
			hosthp = hostage_hp[x]
			if (!pev_valid(hostid)) continue
			pev(hostid, pev_health, hosthp)
			if (hosthp > 0.0 && hosthp < 20.0) {
				get_origin_int(hostid, iOrigin)
				iOrigin[2] += 36.0
				fx_bleed(iOrigin)
				fx_blood_small(iOrigin,3)
			}
		}
	}
}

public event_respawn(id)
{
	if (is_user_alive(id)) {
		//Reset body_hidden flag
		body_hidden[id] = false
		//Restore model visibility
		set_pev(id, pev_rendermode, kRenderNormal)
		//Save clients current Health
		gHealthIndex[id] = get_user_health(id)
	}
}

public event_roundstart(id)
{
	set_task(0.1,"roundstart_delay",100)
}

public roundstart_delay()
{
	for ( new id = 1; id <= MAX_PLAYERS; id++ ) {
		if (is_user_alive(id)) {
			//Reset body_hidden flag
			body_hidden[id] = false
			//Save clients current Health
			gHealthIndex[id] = get_user_health(id)
		}
	}

	if (cstrike_running()) {
		new hostid
		for (new x = 0; x < host_num; x++) {
			hostid = hostages[x]
			if (!pev_valid(hostid)) continue
			set_pev(hostid, pev_rendermode, kRenderNormal)
			pev(hostid, pev_health, hostage_hp[x])
		}
	}
}

//Hides Corpses in CS / DoD
public event_ClCorpse()
{
	//If there is not 12 args something is wrong
	if (get_msg_args() != 12) return PLUGIN_CONTINUE

	//Arg 12 is the player id the corpse is for
	new id = get_msg_arg_int(12)

	//If the corpse should be hidden block this message
	if (body_hidden[id]) return PLUGIN_HANDLED

	return PLUGIN_CONTINUE
}

public get_gore_flags()
{
	new sFlags[24]
	get_pcvar_string(pcvar_gore,sFlags,23)
	return read_flags(sFlags)
}

/************************************************************
* FX FUNCTIONS
************************************************************/

fx_invisible(id)
{
	set_pev(id, pev_renderfx, kRenderFxNone)
	set_pev(id, pev_rendermode, kRenderTransAlpha)
	set_pev(id, pev_renderamt, 0.0)
}

fx_blood(origin[3],origin2[3],HitPlace)
{
	//Crash Checks
	if (HitPlace < 0 || HitPlace > 7) HitPlace = 0
	new rDistance = get_distance(origin,origin2) ? get_distance(origin,origin2) : 1

	new rX = ((origin[0]-origin2[0]) * 300) / rDistance
	new rY = ((origin[1]-origin2[1]) * 300) / rDistance
	new rZ = ((origin[2]-origin2[2]) * 300) / rDistance

	message_begin(MSG_BROADCAST,SVC_TEMPENTITY)
	write_byte(TE_BLOODSTREAM)
	write_coord(origin[0]+Offset[HitPlace][0])
	write_coord(origin[1]+Offset[HitPlace][1])
	write_coord(origin[2]+Offset[HitPlace][2])
	write_coord(rX) // x
	write_coord(rY) // y
	write_coord(rZ) // z
	write_byte(BLOOD_STREAM_RED) // color
	write_byte(random_num(100,200)) // speed
	message_end()
}

fx_bleed(origin[3])
{
	// Blood spray
	message_begin(MSG_BROADCAST,SVC_TEMPENTITY)
	write_byte(TE_BLOODSTREAM)
	write_coord(origin[0])
	write_coord(origin[1])
	write_coord(origin[2]+10)
	write_coord(random_num(-360,360)) // x
	write_coord(random_num(-360,360)) // y
	write_coord(-10) // z
	write_byte(BLOOD_STREAM_RED) // color
	write_byte(random_num(50,100)) // speed
	message_end()
}

fx_blood_small(origin[3],num)
{
	if (equali(mod_name,"esf")) return

	// Write Small splash decal
	for (new j = 0; j < num; j++) {
		message_begin(MSG_BROADCAST,SVC_TEMPENTITY)
		write_byte(TE_WORLDDECAL)
		write_coord(origin[0]+random_num(-100,100))
		write_coord(origin[1]+random_num(-100,100))
		write_coord(origin[2]-36)
		write_byte(blood_small_red[random_num(0,BLOOD_SM_NUM - 1)]) // index
		message_end()
	}
}

fx_blood_large(origin[3],num)
{
	if (equali(mod_name,"esf")) return

	// Write Large splash decal
	for (new i = 0; i < num; i++) {
		message_begin(MSG_BROADCAST,SVC_TEMPENTITY)
		write_byte(TE_WORLDDECAL)
		write_coord(origin[0]+random_num(-50,50))
		write_coord(origin[1]+random_num(-50,50))
		write_coord(origin[2]-36)
		write_byte(blood_large_red[random_num(0,BLOOD_LG_NUM - 1)]) // index
		message_end()
	}
}

#if defined GIBS_ENABLED
fx_gib_explode(origin[3],origin2[3])
{
	new flesh[2]
	flesh[0] = mdl_gib_flesh
	flesh[1] = mdl_gib_meat
	new mult, gibtime = 400 //40 seconds

	if (equali(mod_name,"esf"))		mult = 400
	else if (equali(mod_name,"ts"))	mult = 140
	else							mult = 80

	new rDistance = get_distance(origin,origin2) ? get_distance(origin,origin2) : 1
	new rX = ((origin[0]-origin2[0]) * mult) / rDistance
	new rY = ((origin[1]-origin2[1]) * mult) / rDistance
	new rZ = ((origin[2]-origin2[2]) * mult) / rDistance
	new rXm = rX >= 0 ? 1 : -1
	new rYm = rY >= 0 ? 1 : -1
	new rZm = rZ >= 0 ? 1 : -1

	// Gib explosions

	// Head
	message_begin(MSG_BROADCAST,SVC_TEMPENTITY)
	write_byte(TE_MODEL)
	write_coord(origin[0])
	write_coord(origin[1])
	write_coord(origin[2]+40)
	write_coord(rX + (rXm * random_num(0,80)))
	write_coord(rY + (rYm * random_num(0,80)))
	write_coord(rZ + (rZm * random_num(80,200)))
	write_angle(random_num(0,360))
	write_short(mdl_gib_head)
	write_byte(0) // bounce
	write_byte(gibtime) // life
	message_end()

	// Parts
	for(new i = 0; i < 4; i++) {
		message_begin(MSG_BROADCAST,SVC_TEMPENTITY)
		write_byte(TE_MODEL)
		write_coord(origin[0])
		write_coord(origin[1])
		write_coord(origin[2])
		write_coord(rX + (rXm * random_num(0,80)))
		write_coord(rY + (rYm * random_num(0,80)))
		write_coord(rZ + (rZm * random_num(80,200)))
		write_angle(random_num(0,360))
		write_short(flesh[random_num(0,1)])
		write_byte(0) // bounce
		write_byte(gibtime) // life
		message_end()
	}

	if (!equali(mod_name,"dod")) {

		// Spine
		message_begin(MSG_BROADCAST,SVC_TEMPENTITY)
		write_byte(TE_MODEL)
		write_coord(origin[0])
		write_coord(origin[1])
		write_coord(origin[2]+30)
		write_coord(rX + (rXm * random_num(0,80)))
		write_coord(rY + (rYm * random_num(0,80)))
		write_coord(rZ + (rZm * random_num(80,200)))
		write_angle(random_num(0,360))
		write_short(mdl_gib_spine)
		write_byte(0) // bounce
		write_byte(gibtime) // life
		message_end()

		// Lung
		for(new i = 0; i <= 1; i++) {
			message_begin(MSG_BROADCAST,SVC_TEMPENTITY)
			write_byte(TE_MODEL)
			write_coord(origin[0])
			write_coord(origin[1])
			write_coord(origin[2]+10)
			write_coord(rX + (rXm * random_num(0,80)))
			write_coord(rY + (rYm * random_num(0,80)))
			write_coord(rZ + (rZm * random_num(80,200)))
			write_angle(random_num(0,360))
			write_short(mdl_gib_lung)
			write_byte(0) // bounce
			write_byte(gibtime) // life
			message_end()
		}

		//Legs
		for(new i = 0; i <= 1; i++) {
			message_begin(MSG_BROADCAST,SVC_TEMPENTITY)
			write_byte(TE_MODEL)
			write_coord(origin[0])
			write_coord(origin[1])
			write_coord(origin[2]-10)
			write_coord(rX + (rXm * random_num(0,80)))
			write_coord(rY + (rYm * random_num(0,80)))
			write_coord(rZ + (rZm * random_num(80,200)))
			write_angle(random_num(0,360))
			write_short(mdl_gib_legbone)
			write_byte(0) // bounce
			write_byte(gibtime) // life
			message_end()
		}
	}

	message_begin(MSG_BROADCAST,SVC_TEMPENTITY)
	write_byte(TE_BLOODSPRITE)
	write_coord(origin[0])
	write_coord(origin[1])
	write_coord(origin[2]+20)
	write_short(spr_blood_spray)
	write_short(spr_blood_drop)
	write_byte(BLOOD_COLOR_RED) // color index
	write_byte(10) // size
	message_end()
}
#endif

fx_extra_blood(origin[3])
{
	new x, y, z

	for(new i = 0; i < 3; i++) {
		x = random_num(-15,15)
		y = random_num(-15,15)
		z = random_num(-20,25)
		for(new j = 0; j < 2; j++) {
			message_begin(MSG_BROADCAST,SVC_TEMPENTITY)
			write_byte(TE_BLOODSPRITE)
			write_coord(origin[0]+(x*j))
			write_coord(origin[1]+(y*j))
			write_coord(origin[2]+(z*j))
			write_short(spr_blood_spray)
			write_short(spr_blood_drop)
			write_byte(BLOOD_COLOR_RED) // color index
			write_byte(15) // size
			message_end()
		}
	}
}

fx_headshot(origin[3])
{
	new iFlags = get_gore_flags()

	new Sprays = 1

	if (iFlags&GORE_EXTRA || iFlags&GORE_EXTRA_HS) {
		if (equali(mod_name,"dod"))	Sprays = 4
		else 					Sprays = 8
	}

	message_begin(MSG_BROADCAST,SVC_TEMPENTITY)
	write_byte(TE_BLOODSPRITE)
	write_coord(origin[0])
	write_coord(origin[1])
	write_coord(origin[2]+40)
	write_short(spr_blood_spray)
	write_short(spr_blood_drop)
	write_byte(BLOOD_COLOR_RED) // color index
	write_byte(15) // size
	message_end()

	// Blood sprays
	for (new i = 0; i < Sprays; i++) {
		message_begin(MSG_BROADCAST,SVC_TEMPENTITY)
		write_byte(TE_BLOODSTREAM)
		write_coord(origin[0])
		write_coord(origin[1])
		write_coord(origin[2]+40)
		write_coord(random_num(-30,30)) // x
		write_coord(random_num(-30,30)) // y
		write_coord(random_num(80,300)) // z
		write_byte(BLOOD_STREAM_RED) // color
		write_byte(random_num(100,200)) // speed
		message_end()
	}
}