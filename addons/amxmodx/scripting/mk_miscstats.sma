/* AMX Mod X
*   Misc. Stats Plugin
*
* by the AMX Mod X Development Team
*  originally developed by OLO
*
*	Mortal Kombat Miscstats by Sid 6.7
*	Version 1.0 SP1
*
*
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
*  along with this program; if not, write to the Free Software Foundation, 
*  Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA
*
*  In addition, as a special exception, the author gives permission to
*  link the code of this program with the Half-Life Game Engine ("HL
*  Engine") and Modified Game Libraries ("MODs") developed by Valve, 
*  L.L.C ("Valve"). You must obey the GNU General Public License in all
*  respects for all of the code used other than the HL Engine and MODs
*  from Valve. If you modify this file, you may extend this exception
*  to your version of the file, but you are not obligated to do so. If
*  you do not wish to do so, delete this exception statement from your
*  version.
*/
#include <amxmodx>
#include <amxmisc>
#include <csx>
#include <cstrike>

#define TOASTYTIME 0.15

new PLUGIN[] = "Mortal Kombat Miscstats"

public MultiKill
public MultiKillSound
public BombPlanting
public BombDefusing
public BombPlanted
public BombDefused
public BombFailed
public BombPickUp
public BombDrop
public BombCountVoice
public BombCountDef
public BombReached
public ItalyBonusKill
public EnemyRemaining
public LastMan
public GrenadeKill
public GrenadeSuicide
public HeadShotKill
public HeadShotKillSound
public RoundCounter
public KillingStreak
public KillingStreakSound
public PlayerName
public MKBegunSound, MKEasy, MKToastySound, MKToasty, MKSlicenDiceSound, MKSlicenDice
public MKTaunt, MKCrispy, MKBegun, MKDeathCounter, MKHSFlash, MKFinishHim, MKCrispyFlash
public MKKnifeFlash, MKFightSound
public KillStreakChatOff, MKMACTMPTaunt

new g_streakKills[33][2]
new g_multiKills[33][2]
new g_C4Timer
new g_Defusing
new g_Planter 
new Float:g_LastOmg
new g_LastAnnounce
new g_roundCount
new Float:g_doubleKill
new g_doubleKillId
new g_friend[33]
new g_firstBlood = 1
new g_center1_sync
new g_announce_sync
new g_status_sync
new g_left_sync
new g_bottom_sync
new g_he_sync
new precachelevel, level1precache, level2precache
new Float:g_crispyTimestamp, Float:g_toastyTimestamp, Float:g_eNewRoundTimestamp
new g_AllTimeKills, g_totalKills
new gmsgFade
new Deluxe
new datFile[80]

new mcpHeadshotFlux, mcpPitch, mcpPitchFlux, mcpBrevity, mcpRunningDC
new headphones[33], emit[33], fluxcapacitor[33]

new g_MultiKillMsg[7][] = {
	"Well Done! %s^n%L %d %L (%d %L)",  
	"Supurb %s^n%L %d %L (%d %L)",
	"Excellence %s^n%L %d %L (%d %L)",
	"%s On Fire^n%L %d %L (%d %L)", 
	"Bloodthirsty %s^n%L %d %L (%d hs)", 
	"%s Fatality^n%L %d %L (%d %L)", 
	"%s Flawless Victory^n%L %d %L (%d %L)"
}

enum {
	MKS1_DANGER,
	MKS1_HEADSHOT,
	MKS1_DFDEATH,
	MKS1_PREPARETODIE,
	MKS1_CRISPY,
	MKS2_STRKOOHL,
	MKS2_JAXDEATH,
	MKS2_DANGERPING,
	MKS2_SCORPLAUGH,
	MKS2_SKLAUGH,	
	MKS3_WELLDONE,
	MKS3_SUPURB,
	MKS3_EXCELLENT,
	MKS3_ONFIRE,
	MKS3_BLOODTHIRSTY,
	MKS3_FATALITY,
	MKS3_FLAWLESS,
	MKS3_CHCHCHCHCH,
	MKS3_YOUSUCK,
	MKS3_TOASTY,
	MKS3_MKMASK,
	MKDL_DFREACT3,
	MKDL_DFREACT2,
	MKDL_DFWAST1,
	MKDL_DFWAST2,
	MKDL_STRIKERAWE,
	MKDL_VPDEATH,
	MKDL_VPWAST1,
	MKDL_VPWAST2,
	MKDL_YOUARENOTHING,
	MKDL_WEAKNPATHETIC,
	MKDL_QUANCHIYOUSUCK,
	MKDL_BELL,
	MKDL_DFSKREAM,
	MKDL_FIGHT,
	MKDL_FINISHHIM,
	MKDL_SCORPIONSUCCEED
}

enum {
	MKI_ALL1 = MKS2_STRKOOHL,
	MKI_ALL2UPTODE = MKS2_SCORPLAUGH,
	MKI_ALL2 = MKS3_WELLDONE,
	MKI_ALL3 = MKDL_DFREACT3,
	MKI_ALL4 = MKDL_SCORPIONSUCCEED
}

new g_Sounds[][] = {
	"mkstdanger.wav",//level 1's
	"mkheadshot.wav",
	"mkdfdeath.wav",
	"mkprepare.wav",
	"mkcrispy.wav",  
	"mkstrkoohl.wav",//level 2's
	"mkjhdeath.wav",	
	"mkdangerping.wav",
	"mkscorplaugh.wav",//level 2 Defuse sounds
	"mksklaugh.wav",		
	"mkwelldone.wav", //level 3 sounds
	"mksupurb.wav", 
	"mkexcellent.wav",
	"mkonfire.wav", 
	"mkbloodthirsty.wav", 
	"mkfatality.wav", 
	"mkflawless.wav", 
	"mkchchchch.wav",
	"mklastplace.wav",
	"mktoasty.wav",
	"mkmask.wav",
	"mkdfreact3.wav",//level 4 sounds (precachelevel 5)
	"mkdfreact2.wav",
	"mkdfwast1.wav",
	"mkdfwast2.wav",
	"mkstrkawe.wav",
	"mkvpdeath.wav",
	"mkvpwast1.wav",
	"mkvpwast2.wav",
	"mkstnothing.wav",
	"mkstwpf.wav",
	"mkqclastplace.wav",
	"mkbell.wav",
	"mkdfskream.wav",
	"mkfight.wav",
	"mkfinishhim.wav",
	"mkscorpsucceed.wav"
}

new g_Taunts[][] =
{
	"%s: You Suck!",
	"%s: You Are Nothing",
	"%s: Pathetic",
	"%s: You Suck!",
	"%s: You Really Suck"
}

new g_KillingMsg[8][] =
{
	"%s: Well Done", 
	"%s: Supurb", 
	"%s: Excellent!",
	"%s: On Fire!", 
	"%s: Bloodthirsty", 
	"%s: Fatality", 
	"%s: Flawless",
	"%s: %s Flawless"
}

/*new g_KinfeMsg[4][] =
{
	"KNIFE_MSG_1", 
	"KNIFE_MSG_2", 
	"KNIFE_MSG_3", 
	"KNIFE_MSG_4"
}*/

new g_LastMessages[4][] =
{
	"LAST_MSG_1", 
	"LAST_MSG_2", 
	"LAST_MSG_3", 
	"LAST_MSG_4"
}

new g_HeMessages[4][] =
{
	"HE_MSG_1", 
	"HE_MSG_2", 
	"HE_MSG_3", 
	"HE_MSG_4"
}

new g_SHeMessages[4][] =
{
	"SHE_MSG_1", 
	"SHE_MSG_2", 
	"SHE_MSG_3", 
	"SHE_MSG_4"
}

new g_HeadShots[7][] =
{
	"HS_MSG_1", 
	"HS_MSG_2", 
	"HS_MSG_3", 
	"HS_MSG_4", 
	"HS_MSG_5", 
	"HS_MSG_6", 
	"HS_MSG_7"
}

new g_teamsNames[4][] =
{
	"TERRORIST", 
	"CT", 
	"TERRORISTS", 
	"CTS"
}

public plugin_init()
{
	register_plugin(PLUGIN, "1.0 SP1", "AMXX Dev Team/Sid 6.7")
	register_dictionary("miscstats.txt")
	register_event("TextMsg", "eRestart", "a", "2&#Game_C", "2&#Game_w")
	register_event("SendAudio", "eEndRound", "a", "2&%!MRAD_terwin", "2&%!MRAD_ctwin", "2&%!MRAD_rounddraw")
	register_event("RoundTime", "eNewRound", "bc")
	register_event("StatusValue", "setTeam", "be", "1=1")
	register_event("StatusValue", "showStatus", "be", "1=2", "2!0")
	register_event("StatusValue", "hideStatus", "be", "1=1", "2=0")
	register_concmd("amx_taunt","amx_taunt",ADMIN_CHAT,"<name or #userid> <optional quoted ftext> - taunts the user Mortal Kombat style")
	register_concmd("amx_mkmes","mes",ADMIN_KICK,"pops up the Mini-Easy Speech Reborn menu for Mortal Kombat")
	register_concmd("amx_deathcount","amx_dc",ADMIN_CHAT,"displays the death counter on bottom screen")
	mcpHeadshotFlux = register_cvar("mkm_headshotflux","5")
	mcpPitch = register_cvar("mkm_pitch","100")
	mcpPitchFlux = register_cvar("mkm_pitchflux","-5")
	mcpBrevity = register_cvar("mkm_brevity","0")
	mcpRunningDC = register_cvar("mkm_runningdeathcounter","1000")
	//register_forward(FM_ChangeLevel, "eng_changelevel") //this is broken
	new mapname[32]
	get_mapname(mapname, 31)

	if (equali(mapname, "de_", 3) || equali(mapname, "csde_", 5))
	{
		register_event("StatusIcon", "eGotBomb", "be", "1=1", "1=2", "2=c4")
		register_event("TextMsg", "eBombPickUp", "bc", "2&#Got_bomb")
		register_event("TextMsg", "eBombDrop", "bc", "2&#Game_bomb_d")
	}
	else if (equali(mapname, "cs_italy"))
	{
		register_event("23", "chickenKill", "a", "1=108", /*"12=106", */ "15=4")
		register_event("23", "radioKill", "a", "1=108", /*"12=294", */ "15=2")
	}
	
	g_center1_sync = CreateHudSyncObj()
	g_announce_sync = CreateHudSyncObj()
	g_status_sync = CreateHudSyncObj()
	g_left_sync = CreateHudSyncObj()
	g_bottom_sync = CreateHudSyncObj()
	g_he_sync = CreateHudSyncObj()
	gmsgFade = get_user_msgid("ScreenFade")
	new Float:x = float(get_timeleft())/2.1828  //advertise slightly under the halfway mark
	if(x > 60.0*60.0) x = 60.0*60.0
	set_task(x,"advertiseDeathsX")
	set_task(1.0,"eng_changelevel",_,_,_,"d")
	get_datadir(datFile,charsmax(datFile))
	strcat(datFile,"/mkm.dat",charsmax(datFile))
	flushDeathCounter() //instantiate death counter
}

new g_SoundsPrecached
public plugin_precache(){
	new sillyString[32], mkm[2]
	get_mapname(sillyString,32)
	precachelevel = register_cvar("mkm_precachelevel","3")
	if(!vaultdata_exists("mkm_cycle")) set_vaultdata("mkm_cycle","0")
	if(get_pcvar_num(precachelevel) > 0){
		//precache level 1 sounds
		g_SoundsPrecached = MKI_ALL1
		level1precache = 1
	}
	if(get_pcvar_num(precachelevel) > 1){
		//precache level 2 sounds
		g_SoundsPrecached = MKI_ALL2UPTODE
		if(equal("de_",sillyString,3)) g_SoundsPrecached = MKI_ALL2
		level2precache = 1
	}
	if(get_pcvar_num(precachelevel) == 3){
		//multikill sounds go here
		get_vaultdata("mkm_cycle",mkm,2)
		precache_miscsound(g_Sounds[MKI_ALL2 + str_to_num(mkm)])
		num_to_str((str_to_num(mkm)+1)%11, mkm, 2)
		set_vaultdata("mkm_cycle", mkm)
	}
	if(get_pcvar_num(precachelevel) > 3){
		g_SoundsPrecached = MKI_ALL3
	}
	if(get_pcvar_num(precachelevel) > 4){
		g_SoundsPrecached = MKI_ALL4
		Deluxe = 1
	}
	for(new i; i < g_SoundsPrecached; i++) precache_miscsound(g_Sounds[i])
}

precache_miscsound(sound[]){
	new p[32]
	formatex(p,charsmax(p),"misc/%s",sound)
	precache_sound(p)
}

public plugin_cfg()
{
	new g_addStast[] = "amx_statscfg add ^"%s^" %s"
	server_cmd(g_addStast, "MK First Blood Sound", "MKBegunSound")
	server_cmd(g_addStast, "MK Taunt Player", "MKTaunt")
	server_cmd(g_addStast, "MK Crispy", "MKCrispy")
	server_cmd(g_addStast, "MK Kombat Begin", "MKBegun")
	server_cmd(g_addStast, "MK Death Counter", "MKDeathCounter")
	server_cmd(g_addStast, "MK Headshot Flash", "MKHSFlash")
	server_cmd(g_addStast, "MK Toasty", "MKToasty")
	server_cmd(g_addStast, "MK Toasty Sound", "MKToastySound")	
	server_cmd(g_addStast, "MK Fight! Sound", "MKFightSound")	
	server_cmd(g_addStast, "MK Killing Streak", "KillingStreak")
	server_cmd(g_addStast, "MK Killing Streak Sounds", "KillingStreakSound")
	server_cmd(g_addStast, "MK Finish Him!", "MKFinishHim")
	server_cmd(g_addStast, "MK Crispy Flash", "MKCrispyFlash")
	server_cmd(g_addStast, "MK Knife Flash", "MKKnifeFlash")
	server_cmd(g_addStast, "MK Easy KillStreaks", "MKEasy")
	server_cmd(g_addStast, "MK HeadShot Kill Sound", "HeadShotKillSound")	
	server_cmd(g_addStast, "MK Knife Kill", "MKSlicenDice")
	server_cmd(g_addStast, "MK Knife Kill Sound", "MKSlicenDiceSound")
	server_cmd(g_addStast, "MK Bomb Defuse Succ.", "BombDefused")
	server_cmd(g_addStast, "MK Bomb Def. Failure", "BombFailed")	
	server_cmd(g_addStast, "MultiKill Announce", "MultiKill")
	server_cmd(g_addStast, "MultiKillSound Announce", "MultiKillSound")
	server_cmd(g_addStast, "Bomb Planting", "BombPlanting")
	server_cmd(g_addStast, "Bomb Defusing", "BombDefusing")
	server_cmd(g_addStast, "Bomb Planted", "BombPlanted")
	server_cmd(g_addStast, "Bomb PickUp", "BombPickUp")
	server_cmd(g_addStast, "Bomb Drop", "BombDrop")
	server_cmd(g_addStast, "Bomb Count Down", "BombCountVoice")
	server_cmd(g_addStast, "Bomb Count Down (def)", "BombCountDef")
	server_cmd(g_addStast, "Bomb Site Reached", "BombReached")
	server_cmd(g_addStast, "Italy Bonus Kill", "ItalyBonusKill")
	server_cmd(g_addStast, "Last Man", "LastMan")
	server_cmd(g_addStast, "Grenade Kill", "GrenadeKill")
	server_cmd(g_addStast, "Grenade Suicide", "GrenadeSuicide")
	server_cmd(g_addStast, "HeadShot Kill", "HeadShotKill")
	server_cmd(g_addStast, "Round Counter", "RoundCounter")
	server_cmd(g_addStast, "Enemy Remaining", "EnemyRemaining")
	server_cmd(g_addStast, "Player Name", "PlayerName")
	server_cmd(g_addStast, "KillStreak Cht Msg's Off", "KillStreakChatOff")
	server_cmd(g_addStast, "MK TMP/MAC10 Taunts","MKMACTMPTaunt")
}

public amx_taunt(id, lvl, cid){
	if(!cmd_access(id,lvl,cid,2)) return PLUGIN_HANDLED
	new c[64]
	read_argv(2,c,charsmax(c))
	new arg[32], victimName[33]
	read_argv(1,arg,32)
	new player = cmd_target(id, arg,2)
	if(!player) {
		return PLUGIN_HANDLED
	}
	if(is_user_admin(player) && id != player){
		console_print(id,"Hey now, behave!")
		return PLUGIN_HANDLED
	}
	get_user_name(player,victimName,32)
	set_hudmessage(255, 20, 10, 0.05, 0.50, 2, random_float(0.01,1.0), 6.0, 0.04, 0.1, -1)
	new n = random(4) * Deluxe
	if(read_argc() == 2) copy(c,charsmax(c),g_Taunts[n])
	else format(c,charsmax(c),"%s: %s",victimName,c)
	ShowSyncHudMsg(0, g_left_sync, c, victimName)
	switch(n){
		case 0:	play_sound("misc", g_Sounds[MKS3_YOUSUCK])
		default: play_sound("misc", g_Sounds[MKDL_YOUARENOTHING+n-1])
	}
	new auth[32]
	get_user_name(id,c,32)
	get_user_authid(id,auth,31)
	log_amx("Cmd: ^"%s<%d><%s><>^" taunted %s", c, get_user_userid(id), auth,victimName)
	return PLUGIN_HANDLED
}

public eng_changelevel(){
	//the chgmap forward is broken - even the fakemeta way wouldnt work
   	if(MKDeathCounter){
		flushDeathCounter()
		client_print(0,print_chat,"[%s] Death count - %d total deaths this game",PLUGIN,g_totalKills)
	}
	play_sound("misc", g_Sounds[MKDL_BELL])
}

public client_putinserver(id)
{
	g_multiKills[id] = {0, 0}
	g_streakKills[id] = {0, 0}
	fluxcapacitor[id] = 0
}

superflash(who,time,r,g,b,a=255){
	if(who) message_begin( MSG_ONE, gmsgFade, _, who)
	else message_begin(MSG_ALL, gmsgFade) 
	write_short( 1<<time )					// fade lasts this long
	write_short( 1<<time )				// hold lasts this long
	write_short( 0 )					// fade type (in / out)
	write_byte( r )				// fade red
	write_byte( g )				// fade green
	write_byte( b )				// fade blue
	write_byte( a )				// alpha
	message_end()	
}

public client_death(killer, victim, wpnindex, hitplace, TK)
{
	if (wpnindex == CSW_C4)
		return
	new headshot = (hitplace == HIT_HEAD) ? 1 : 0
	new selfkill = (killer == victim) ? 1 : 0
	new killerName[33]
	new g_left_sync_used //prioritize Toasty, Crispy, Killstreak, Knifes sounds and HUD
	if(headshot && MKHSFlash){
		superflash(victim,9,1,1,1,242)
	}
	if (g_firstBlood && !selfkill)
	{
		if(MKBegunSound)
			play_sound("misc", g_Sounds[MKS3_CHCHCHCHCH])
		if(MKBegun){
			get_user_name(killer,killerName,32)
			set_hudmessage(0, 255, 255, 0.05, 0.50, 0, _, 1.0, 1.0, 3.5, -1)
			ShowSyncHudMsg(0, g_left_sync, "%s: Kombat Has Begun!", killerName)
		}
		g_firstBlood = 0
		g_left_sync_used = 2
	}

	if ((MKToasty || MKToastySound) && !selfkill && g_streakKills[killer][0] < 20)
	{
		new Float:nowtime = get_gametime()
		
		if (g_doubleKill + TOASTYTIME >= nowtime && g_doubleKillId == killer && (nowtime - g_toastyTimestamp > 1.0))
		{
			if (MKToasty)
			{
				//new name[32]
				
				get_user_name(killer, killerName, 32)
				set_hudmessage(0, 255, 255, 0.05, 0.50, 0, _, 2.0, 1.5, 3.0, -1)
				ShowSyncHudMsg(0, g_left_sync, "%s: Toasty!", killerName)
				g_left_sync_used = 1
			}
			
			if (MKToastySound){
				play_sound("misc", "mktoasty")
				g_crispyTimestamp = nowtime
				g_toastyTimestamp = nowtime
				remove_task(348207)
				remove_task(782)
			}
		}
		
		g_doubleKill = nowtime
		g_doubleKillId = killer

	}	
	if (wpnindex == CSW_HEGRENADE && MKCrispy && (get_gametime() - g_crispyTimestamp > 1.0)){
		set_task(0.04,"crispy",348207)
		g_crispyTimestamp = get_gametime()
	}
	if(wpnindex == CSW_KNIFE && MKKnifeFlash){
		new nnn, ooo
		nnn = get_user_weapon(victim,ooo,ooo)
		if(nnn != CSW_KNIFE) superflash(victim,11,255,128,1,200)
	}
	if(wpnindex == CSW_HEGRENADE && MKCrispyFlash){
		superflash(victim,11,200,1,1,242)
	}
	if ((KillingStreak || KillingStreakSound) && !TK )
	{
		g_streakKills[victim][1]++
		g_streakKills[victim][0] = 0

		if (!selfkill)
		{
			g_streakKills[killer][0]++
			g_streakKills[killer][1] = 0
			
			new a = g_streakKills[killer][0] - 3
			if(MKEasy){
				a = g_streakKills[killer][0] - 1
				switch(a){
					case 0: a = -1
					case 1: a = 0
				}
			}
			if(!g_left_sync_used && (get_gametime() - g_toastyTimestamp > 0.25))
			if ((a > -1) && !(a % 2))
			{
				new bonus, bonusMsg[24]
				get_user_name(killer, killerName, 32)
				
				if ((a >>= 1) > 6){
					bonus = a - 6
					a = 6
					switch(bonus+1){
						case 2: bonusMsg = "Double"
						case 3: bonusMsg = "Triple"
						case 4: bonusMsg = "Fourfold"
						case 5: {bonusMsg = "Jade"; superflash(0,9,0,255,0,155);}
						case 10: {bonusMsg = "Ruby"; superflash(0,9,255,0,0,155);}
						case 15: {bonusMsg = "Sapphire"; superflash(0,9,0,0,255,155);}
						case 20: {bonusMsg = "Silver"; superflash(0,11,150,150,150,240);}
						case 25: {bonusMsg = "Gold"; superflash(0,11,255,255,0,240);}
						case 50: {bonusMsg = "Perfect"; superflash(0,12,255,255,255);}
						case 100: {bonusMsg = "Hundred Times"; superflash(0,12,255,255,255);}
						default: format(bonusMsg,7,"%dX",bonus+1)
					}
				}
				if (KillingStreakSound)
				{
					set_task(0.05,"playMultiKillSound",782,g_Sounds[a+MKS3_WELLDONE],32)
				}				
				if (KillingStreak)
				{
					set_hudmessage(42*a, max(0,50-a*20), 255-42*a, 0.05, 0.50, 2, 0.16*a, 6.0, 0.01, 0.5, -1)
					if(bonus) ShowSyncHudMsg(0, g_left_sync, g_KillingMsg[a+1], killerName, bonusMsg)
					else ShowSyncHudMsg(0, g_left_sync, g_KillingMsg[a], killerName)
					g_left_sync_used = 1
				}
				
			} else {
				if(MKTaunt && (random(6-MKEasy) == 2) && !is_user_admin(victim)){
					if(islastonteam(victim)){
						new n = Deluxe*(random_num(0,3))
						new victimName[33]
						get_user_name(victim,victimName,32)
						set_hudmessage(255, 255, 0, 0.05, 0.50, 2, random_float(0.01,1.0), 6.0, 0.01, 0.1, -1)
						ShowSyncHudMsg(0, g_left_sync, g_Taunts[n], victimName)
						switch(n){
							case 0:	set_task(0.05,"playMultiKillSound",782,"mklastplace",17)
							default: set_task(0.05,"playMultiKillSound",782,g_Sounds[n-1+MKDL_YOUARENOTHING],24)
						}
						g_left_sync_used = 1
					}
				} else if(random(2) && MKTaunt && g_streakKills[victim][1] > 8 && !is_user_admin(victim)){
					new victimName[33]
					get_user_name(victim,victimName,32)
					set_hudmessage(255, 175, 0, 0.05, 0.50, 2, random_float(0.01,1.0), 6.0, 0.01, 0.1, -1)
					ShowSyncHudMsg(0, g_left_sync, g_Taunts[sizeof g_Taunts - 1], victimName)
					set_task(0.05,"playMultiKillSound",782,"mklastplace",17)
					g_left_sync_used = 1
				}
			}
		}
	}

	if (MultiKill || MultiKillSound)
	{
		if (!selfkill && !TK)
		{
			g_multiKills[killer][0]++ 
			g_multiKills[killer][1] += headshot
			
			new param[2]
			
			param[0] = killer
			param[1] = g_multiKills[killer][0]
			set_task(4.0 + float(param[1]), "checkKills", 0, param, 2)
		}
	}

	if (EnemyRemaining && is_user_connected(victim))
	{
		new ppl[32], pplnum = 0, maxplayers = get_maxplayers()
		new epplnum = 0
		new CsTeams:team = cs_get_user_team(victim)
		new CsTeams:other_team
		new CsTeams:enemy_team = (team == CS_TEAM_T) ? CS_TEAM_CT : CS_TEAM_T
		
		if (team == CS_TEAM_T || team == CS_TEAM_CT)
		{
			for (new i=1; i<=maxplayers; i++)
			{
				if (!is_user_connected(i))
				{
					continue
				}
				if (i == victim)
				{
					continue
				}
				other_team = cs_get_user_team(i)
				if (other_team == team && is_user_alive(i))
				{
					epplnum++
				} else if (other_team == enemy_team) {
					ppl[pplnum++] = i
				}
			}
			
			if (pplnum && epplnum)
			{
				new message[256], team_name[32]

				set_hudmessage(255, 255, 255, 0.02, 0.85, 2, 0.05, 0.1, 0.02, 3.0, -1)
				
				/* This is a pretty stupid thing to translate, but whatever */
				new _teamname[32]
				if (team == CS_TEAM_T)
				{
					format(_teamname, 31, "TERRORIST%s", (epplnum == 1) ? "" : "S")
				} else if (team == CS_TEAM_CT) {
					format(_teamname, 31, "CT%s", (epplnum == 1) ? "" : "S")
				}

				for (new a = 0; a < pplnum; ++a)
				{
					format(team_name, 31, "%L", ppl[a], _teamname)
					format(message, 255, "%L", ppl[a], "REMAINING", epplnum, team_name)
					ShowSyncHudMsg(ppl[a], g_bottom_sync, "%s", message)
				}
			}
		}
	}

	if (LastMan)
	{
		new cts[32], ts[32], ctsnum, tsnum
		new maxplayers = get_maxplayers()
		new CsTeams:team
		
		for (new i=1; i<=maxplayers; i++)
		{
			if (!is_user_connected(i) || !is_user_alive(i))
			{
				continue
			}
			team = cs_get_user_team(i)
			if (team == CS_TEAM_T)
			{
				ts[tsnum++] = i
			} else if (team == CS_TEAM_CT) {
				cts[ctsnum++] = i
			}
		}
		
		if (ctsnum == 1 && tsnum == 1)
		{
			new ctname[32], tname[32]
			
			get_user_name(cts[0], ctname, 31)
			get_user_name(ts[0], tname, 31)
			
			set_hudmessage(0, 255, 255, -1.0, 0.35, 0, 6.0, 6.0, 0.5, 0.15, -1)
			ShowSyncHudMsg(0, g_center1_sync, "%s vs. %s", ctname, tname)
			
			play_sound("misc", "mkstdanger")
		}
		else if (!g_LastAnnounce)
		{
			new oposite = 0, _team = 0
			
			if (ctsnum == 1 && tsnum > 1)
			{
				g_LastAnnounce = cts[0]
				oposite = tsnum
				_team = 0
			}
			else if (tsnum == 1 && ctsnum > 1)
			{
				g_LastAnnounce = ts[0]
				oposite = ctsnum
				_team = 1
			}

			if (g_LastAnnounce)
			{
				new name[32], serialKiller
				
				get_user_name(g_LastAnnounce, name, 31)
				//determine if killstreaker
				if(g_streakKills[g_LastAnnounce][0] >= 7 && get_user_health(g_LastAnnounce) > 40 && !is_user_connecting(g_LastAnnounce))
					serialKiller = 1
				set_hudmessage(0, 255, 255, -1.0, 0.38, 0, 6.0, 6.0, 0.5, 0.15, -1)
				ShowSyncHudMsg(0, g_center1_sync, "%s (%d HP) vs. %d %s%s: %L", name, get_user_health(g_LastAnnounce), oposite, g_teamsNames[_team], (oposite == 1) ? "" : "S", LANG_PLAYER, g_LastMessages[random_num(0, 3)])
				if(Deluxe && serialKiller){
					play_sound("misc", g_Sounds[MKDL_SCORPIONSUCCEED])
					ShowSyncHudMsg(0, g_center1_sync, "%s is about to kill u all",name)
				} else
				if (!is_user_connecting(g_LastAnnounce)){
					process(g_LastAnnounce, "misc", "mkprepare")
					if(MKFinishHim) {
						play_sound_exclude("misc",g_Sounds[MKDL_FINISHHIM],g_LastAnnounce)
						set_hudmessage(255, 2, 1, -1.0, 0.30, 2, 6.0, 1.0, 0.05, 0.15, -1)
						ShowSyncHudMsg(0, g_announce_sync, "FINISH HIM!")
					}
				}
					
				play_sound("misc", "mkdangerping")
			}
		}
	}

	if (wpnindex == CSW_KNIFE && (MKSlicenDice || MKSlicenDiceSound))
	{
		if (MKSlicenDice && !g_left_sync_used)
		{
			//new killer_name[48]
			new nnn, ooo
			nnn = get_user_weapon(victim,ooo,ooo)
			if(nnn != CSW_KNIFE){
				get_user_name(killer, killerName, 32)
				set_hudmessage(255, 100, 0, 0.05, 0.50, 2, random_float(0.01,1.0), 6.0, 0.01, 0.1, -1)
				ShowSyncHudMsg(0, g_left_sync, "%s: Slice 'n Dice", killerName)
			}
		}
		
		if (MKSlicenDiceSound){
			new nnn, ooo
			nnn = get_user_weapon(victim,ooo,ooo)
			if(nnn != CSW_KNIFE) play_sound("misc", "mkmask")
		}
	}
	if(MKMACTMPTaunt && (wpnindex == CSW_TMP || wpnindex == CSW_MAC10) && !g_left_sync_used && random(2)){
		//see if the guy that died had a superior weapon
		new ooo, nnn = get_user_weapon(victim,ooo,ooo)
		ooo = 1000
		switch(nnn){
			case CSW_AK47:{}
			case CSW_M4A1:{}
			case CSW_AUG:{}
			case CSW_AWP:{}
			case CSW_FAMAS:{}
			case CSW_MP5NAVY:{}
			case CSW_SG552:{}
			default: ooo = 0
		}
		if(ooo){
			new victimName[33]
			get_user_name(victim,victimName,32)
			set_hudmessage(255, 255, 255, 0.05, 0.50, 2, random_float(0.01,1.0), 6.0, 0.01, 0.1, -1)
			ShowSyncHudMsg(0, g_left_sync, wpnindex == CSW_TMP ? "%s: Taste the Steyr TMP!": "%s: You got MAC10'd", victimName)			
			play_sound("misc","mklastplace")
		}
	}
	if(wpnindex == CSW_KNIFE && level2precache){
		if(Deluxe && headshot)
		process_emit(victim,"misc/mkdfskream.wav")
		else if(!headshot) process_emit(victim,"misc/mkjhdeath.wav")
	}
	if (wpnindex == CSW_HEGRENADE && (GrenadeKill || GrenadeSuicide))
	{
		new killer_name[32], victim_name[32]
		
		get_user_name(killer, killer_name, 31)
		get_user_name(victim, victim_name, 31)
		
		set_hudmessage(255, 100, 100, -1.0, 0.25, 1, 6.0, 6.0, 0.5, 0.15, -1)
		
		if (!selfkill)
		{
			if (GrenadeKill)
				ShowSyncHudMsg(0, g_he_sync, "%L", LANG_PLAYER, g_HeMessages[random_num(0, 3)], killer_name, victim_name)
		}
		else if (GrenadeSuicide)
			ShowSyncHudMsg(0, g_he_sync, "%L", LANG_PLAYER, g_SHeMessages[random_num(0, 3)], victim_name)
	}
	if (headshot && (HeadShotKill || HeadShotKillSound))
	{
		if (HeadShotKill && wpnindex)
		{
			new killer_name[32], victim_name[32], weapon_name[32], message[256], players[32], pnum
			
			xmod_get_wpnname(wpnindex, weapon_name, 31)
			get_user_name(killer, killer_name, 31)
			get_user_name(victim, victim_name, 31)
			get_players(players, pnum, "c")
			
			for (new i = 0; i < pnum; i++)
			{
				format(message, charsmax(message), "%L", players[i], g_HeadShots[random_num(0, 6)])
				
				replace(message, charsmax(message), "$vn", victim_name)
				replace(message, charsmax(message), "$wn", weapon_name)
				replace(message, charsmax(message), "$kn", killer_name)
				
				set_hudmessage(100, 100, 255, -1.0, 0.30, 0, 6.0, 6.0, 0.5, 0.15, -1)
				ShowSyncHudMsg(players[i], g_announce_sync, "%s", message)
			}
		}
		
		if (HeadShotKillSound && (wpnindex != CSW_KNIFE || !Deluxe))
		{
			if(!g_left_sync_used && (get_gametime() - g_toastyTimestamp > 0.25)) {
				process(killer, "misc", "mkheadshot")
				process(victim, "misc", "mkheadshot")
			}
			
			if(Deluxe && random(5) != 0 && is_user_connected(victim)){
				if(cs_get_user_team(victim) == CS_TEAM_CT)
					process_emit(victim,g_Sounds[MKDL_DFREACT3+random(4)])
				else
					process_emit(victim,g_Sounds[random(4)+MKDL_STRIKERAWE])
			} else {
				if( is_user_connected(victim) && level2precache){
					if(cs_get_user_team(victim) == CS_TEAM_T) process_emit(victim,"misc/mkstrkoohl.wav")
					else process_emit(victim,"misc/mkdfdeath.wav")
				} else if(level1precache) process_emit(victim,"misc/mkdfdeath.wav")
			}
			
			if(Deluxe && (wpnindex == CSW_AWP || wpnindex == CSW_M3)) 
			process_emit(victim,"misc/mkdfskream.wav")
			
		}
	}
	if(!is_user_bot(victim)) g_AllTimeKills++
	g_totalKills++
	flushDeathCounter()
	if(get_pcvar_num(mcpRunningDC) > 0){
		if(g_AllTimeKills % get_pcvar_num(mcpRunningDC) == 0) advertiseDeaths(0)
	}
}

public hideStatus(id)
{
	if (PlayerName)
	{
		ClearSyncHud(id, g_status_sync)
	}
}

public setTeam(id)
	g_friend[id] = read_data(2)

public showStatus(id)
{
	if (PlayerName)
	{
		new name[32], pid = read_data(2)
		
		get_user_name(pid, name, 31)
		new color1 = 0, color2 = 0
		
		if (get_user_team(pid) == 1)
			color1 = 255
		else
			color2 = 255
			
		if (g_friend[id] == 1)	// friend
		{
			new clip, ammo, wpnid = get_user_weapon(pid, clip, ammo)
			new wpnname[32]
			
			if (wpnid)
				xmod_get_wpnname(wpnid, wpnname, 31)
			
			set_hudmessage(color1, 50, color2, -1.0, 0.60, 1, 0.01, 3.0, 0.01, 0.01)
			ShowSyncHudMsg(id, g_status_sync, "%s -- %d HP / %d AP / %s", name, get_user_health(pid), get_user_armor(pid), wpnname)
		} else {
			set_hudmessage(color1, 50, color2, -1.0, 0.60, 1, 0.01, 3.0, 0.01, 0.01)
			ShowSyncHudMsg(id, g_status_sync, "%s", name)
		}
	}
}

public eNewRound()
{
	if( get_gametime() - g_eNewRoundTimestamp < 1.0) return
	if (read_data(1) == floatround(get_cvar_float("mp_roundtime") * 60.0,floatround_floor))
	{
		g_C4Timer = 0
		++g_roundCount
		if(get_playersnum() < 2) return
		if (RoundCounter)
		{
			set_hudmessage(200, 0, 0, -1.0, 0.30, 0, 6.0, 6.0, 0.5, 0.15, -1)
			ShowSyncHudMsg(0, g_announce_sync, "Round %d^nFIGHT!", g_roundCount)
		}
		
		if (MKFightSound)
			play_sound("misc", "mkfight")
		
		if (KillingStreak)
		{
			new appl[32], ppl, i
			get_players(appl, ppl, "ac")
			
			if(!KillStreakChatOff)
			for (new a = 0; a < ppl; ++a)
			{
				i = appl[a]
				
				if (g_streakKills[i][0] >= 2)
					client_print(i, print_chat, "* %L", i, "KILLED_ROW", g_streakKills[i][0])
				else if (g_streakKills[i][1] >= 2)
					client_print(i, print_chat, "* %L", i, "DIED_ROUNDS", g_streakKills[i][1])
			}
		}
	}
	g_eNewRoundTimestamp = get_gametime()
}

public eRestart()
{
	eEndRound()
	g_roundCount = 0
	g_firstBlood = 1
}

public eEndRound()
{
	g_C4Timer = -2
	g_LastOmg = 0.0
	remove_task(8038)
	g_LastAnnounce = 0
}

public checkKills(param[])
{
	new id = param[0]
	new a = param[1]
	
	if (a == g_multiKills[id][0])
	{
		a -= 3
		if (a > -1)
		{
			if (a > 6)
			{
				a = 6
			}
			
			if (MultiKill)
			{
				new name[32]
				
				get_user_name(id, name, 31)
				set_hudmessage(255, 0, 100, 0.05, 0.50, 2, 0.02, 6.0, 0.01, 0.1, -1)
				
				ShowSyncHudMsg(0, g_left_sync, g_MultiKillMsg[a], name, LANG_PLAYER, "WITH", g_multiKills[id][0], LANG_PLAYER, "KILLS", g_multiKills[id][1], LANG_PLAYER, "HS")
			}
			
			if (MultiKillSound)
			{
				play_sound("misc", g_Sounds[MKS3_WELLDONE+a])
			}
		}
		g_multiKills[id] = {0, 0}
	}
}

public chickenKill()
	if (ItalyBonusKill)
		announceEvent(0, "KILLED_CHICKEN")

public radioKill()
{
	if (ItalyBonusKill)
		announceEvent(0, "BLEW_RADIO")
}

announceEvent(id, message[])
{
	new name[32]
	
	get_user_name(id, name, 31)
	set_hudmessage(128, 0, 255, -1.0, 0.30, 0, 6.0, 6.0, 0.5, 0.15, -1)
	if(message[0] == '1') ShowSyncHudMsg(0, g_announce_sync, message[1], name)
	else ShowSyncHudMsg(0, g_announce_sync, "%L", LANG_PLAYER, message, name)
	
}

public eBombPickUp(id)
	if (BombPickUp)
		announceEvent(id, "PICKED_BOMB")

public eBombDrop()
	if (BombDrop)
		announceEvent(g_Planter, "DROPPED_BOMB")

public eGotBomb(id)
{
	g_Planter = id
	
	if (BombReached && read_data(1) == 2 && g_LastOmg < get_gametime())
	{
		g_LastOmg = get_gametime() + 15.0
		announceEvent(g_Planter, "REACHED_TARGET")
	}
}

public bombTimer()
{
	if (--g_C4Timer > 0)
	{
		if (BombCountVoice)
		{
			if (g_C4Timer == 30 || g_C4Timer == 20)
			{
				new temp[64]
				
				num_to_word(g_C4Timer, temp, 63)
				format(temp, 63, "%s seconds until explosion", temp)
				play_sound("vox",temp)
			}
			else if (g_C4Timer < 11)
			{
				new temp[64]
				
				num_to_word(g_C4Timer, temp, 63)
				play_sound("vox",temp)
			}
		}
		if (BombCountDef && g_Defusing)
			client_print(g_Defusing, print_center, "%d", g_C4Timer)
	}
	else
		remove_task(8038)
}

public bomb_planted(planter)
{
	g_Defusing = 0
	
	if (BombPlanted)
		announceEvent(planter, "SET_UP_BOMB")
	
	g_C4Timer = get_cvar_num("mp_c4timer")
	set_task(1.0, "bombTimer", 8038, "", 0, "b")
}

public bomb_planting(planter)
	if (BombPlanting)
		announceEvent(planter, "PLANT_BOMB")

public bomb_defusing(defuser)
{
	if (BombDefusing)
		announceEvent(defuser, "DEFUSING_BOMB")
	
	g_Defusing = defuser
}

public bomb_defused(defuser){
	if (BombDefused)
		announceEvent(defuser, "1%s laughs in your face!")
	play_sound("misc", "mkscorplaugh")
}

public bomb_explode(planter, defuser){
	if (BombFailed && defuser && is_user_connected(planter))
		announceEvent(defuser, "1%s, you have failed!")
	play_sound("misc", "mksklaugh")
}

public play_sound(type[],sound[]){
	new players[32], pnum
	get_players(players, pnum, "c")
	new i
	
	for (i = 0; i < pnum; i++)
	{
		if (is_user_connecting(players[i]))
			continue
		process(players[i],type,sound)
	}
}

public play_sound_exclude(type[], sound[], excludePlayer)
{
	new players[32], pnum
	get_players(players, pnum, "c")
	new i
	
	for (i = 0; i < pnum; i++)
	{
		if (players[i] == excludePlayer || is_user_connecting(players[i]))
			continue
		process(players[i],type,sound)
	}
}

islastonteam(id){
	if(g_roundCount == 1) return 0
	new players[32], num, team[20], h
	get_user_team(id,team,20)
	get_players(players,num,"e",team)
	if(num < 3) return 0
	h = get_user_frags(id)
	for(new i; i < num; i++){
		if( get_user_frags(players[i]) < h) return 0
	}
	return 1
}

//from Easy Speech Reborn
#define AUTOVAL -1
process(id, ptype[], param[], pitch=AUTOVAL,volume=100,brevity=AUTOVAL,flux=0){
	if(pitch == AUTOVAL){
		pitch = get_pcvar_num(mcpPitch)
		new p = pitch + get_pcvar_num(mcpPitchFlux)
		if(p > pitch) pitch = random_num(pitch,p)
		else pitch = random_num(p,pitch)
		//if(equal(param,g_Sounds[MKS3_TOASTY],8)) pitch = 100
		pitch = clamp(pitch+flux,40,160)
	}
	if(brevity == AUTOVAL) brevity = get_pcvar_num(mcpBrevity)
	client_cmd(id,"spk ^"%s/(p%dv%dt%d) %s^"",ptype,pitch,volume,brevity,param)
}

process_emit(id, sound[]){
	new p = 100
	new q = abs(get_pcvar_num(mcpHeadshotFlux))
	p = random_num(p-q,p+q) + (fluxcapacitor[id]*40)/(random(5)+2)
	p = clamp(p,40,160)
	if(contain(sound,"misc") == -1){
		new m[32]
		formatex(m,charsmax(m),"misc/%s",sound)
		emit_sound(id,CHAN_VOICE,m,VOL_NORM,ATTN_NORM,0,p)
	} else emit_sound(id,CHAN_VOICE,sound,VOL_NORM,ATTN_NORM,0,p)
}

public crispy(){
	play_sound("misc", "mkcrispy")
}

public playMultiKillSound(sound[32]){
	play_sound("misc",sound)
}

public amx_dc(id, lvl, cid){
	if(!cmd_access(id,lvl,cid,1)) return PLUGIN_HANDLED
	advertiseDeaths()
	return PLUGIN_HANDLED
}

public advertiseDeathsX()
	advertiseDeaths()

advertiseDeaths(playbell=1){
	new d, numstr[18], host[48]
	flushDeathCounter()
	get_cvar_string("hostname",host,48)
	d = g_AllTimeKills
	if(d > 999999) format(numstr,17,"%d,%03d,%03d",d/1000000,(d%1000000)/1000,d%1000)
	else if(d > 9999) format(numstr,17,"%d,%03d",d/1000,d%1000)
	else num_to_str(d,numstr,charsmax(numstr))
	set_hudmessage(0, 255, 20, -1.0, 0.85, 0, 6.0, 3.0,_,3.0,-1)
	show_hudmessage(0, "%s - %s deaths and counting",host,numstr)
	if(playbell) play_sound("misc", "mkbell")
}

//instantiates g_AllTimeKills, logs death counter
flushDeathCounter(){
	//flush g_AllTimeKills to dat file
	if(g_AllTimeKills == 0) {
		if(file_exists(datFile)){
			new f = fopen(datFile,"r")
			fread(f,g_AllTimeKills,BLOCK_INT)
			fclose(f)
		}
		server_print("[%s] Loading death count of %d",PLUGIN,g_AllTimeKills)
	}
	new f = fopen(datFile,"w")
	fwrite(f,g_AllTimeKills,BLOCK_INT)
	fclose(f)
}

public mes(id, lvl, cid){
	if(!cmd_access(id,lvl,cid,1)) return PLUGIN_HANDLED
	//info format: #<str> - # = 1 or 0 for hp, <str> is misc sound
	if(!level2precache){
		console_print(id,"[Mini-Easy Speech Reborn] Not enough sounds precached")
		return PLUGIN_HANDLED
	}
	menu_display(id,mesrmenu(id))
	return PLUGIN_HANDLED
}

mesrmenu(id){
	new s[32], t[32]
	new menu = menu_create("Mini-Easy Speech Reborn Menu","mesmh")
	menu_additem(menu,headphones[id] ? "HEADPHONES\R\yON" : "HEADPHONES\R\rOFF","hp")
	menu_additem(menu,emit[id] ? "EMIT\R\yON" : "EMIT\R\rOFF","em")
	fluxcapacitor[id] == 0 ? 
		menu_additem(menu,"FLUX\R\dNORMAL","fl")
		: menu_additem(menu,fluxcapacitor[id] == -1 ? "FLUX\R\yNEGATIVE" : "FLUX\R\rPOSITIVE","fl")
	for(new i; i < g_SoundsPrecached; i++){	
		copy(t,charsmax(t),g_Sounds[i])
		formatex(s,charsmax(s),"%d%s",headphones[id],t)
		menu_additem(menu,t,s)
	}
	return menu
}

public mesmh(id, menu, item){
	if(item <= MENU_EXIT){
		menu_destroy(menu)
		return PLUGIN_HANDLED
	}
	new a, cmd[32], name[32], callback
	menu_item_getinfo(menu, item, a, cmd, sizeof(cmd)-1,name,sizeof(name)-1, callback)
	if(equal(cmd,"hp")){
		headphones[id] = !headphones[id]
		menu_destroy(menu)
		menu = mesrmenu(id)
	} else if(equal(cmd,"em")){
		emit[id] = !emit[id]
		menu_destroy(menu)
		menu = mesrmenu(id)
	} else if(equal(cmd,"fl")){
		fluxcapacitor[id] = (fluxcapacitor[id] + 2)%3 -1
		menu_destroy(menu)
		menu = mesrmenu(id)
	} else {
		if(cmd[0] == '0') a = 0
		else a = id
		switch(emit[id]){
			case 0: {
				process(a,"misc",name,_,_,_,(fluxcapacitor[id]*40)/(random(5)+2))
				if(headphones[id]) {
					set_hudmessage(100+random(155), 100+random(155), 100+random(155), -1.0, 0.22, 0, _, 1.5, _, 1.0)
					show_hudmessage(id,"[Mini-ESR] Headphones are ON")
				}
			}
			default: process_emit(id,name)
		}
	}
	menu_display(id,menu,item/7)
	return PLUGIN_HANDLED
}