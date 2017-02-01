/* AMX Mod X Plugin - HL Media Player (HLMP) 2.1a
* 
* by kICKED =) (anson_wongy)
* 
* Website: XGAMERHK.COM - http://xgamerhk.com
* Forum: http://forums.xgamerhk.com
* E-Mail: anson_wongy@hotmail.com or anson_wongy@xgamerhk.com
* 
* 網站: XGAMERHK.COM - http://xgamerhk.com
* 論壇: http://forums.xgamerhk.com
* E-Mail: anson_wongy@hotmail.com or anson_wongy@xgamerhk.com
* 
* This plugin has been tested on AMXModX 1.71 successfully.
* NOTE: This plugin supports the mods which have MOTD ONLY. (ex. HLDM, CS)
* 
* Commands:
* hlmp_menu - Show HLMP Menu
* say /hlmp - Show HLMP Menu
* 
* The following require ADMIN_LEVEL_H to access:
* hlmp_reloadmedia - Reload Media List
* hlmp_view - View the music which are players listening
* 
****************************************************************************
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
****************************************************************************
*/

#include <amxmodx>
#include <amxmisc>

new g_MedialistToRead[64]
new g_MediaNames[128][64], g_MediaURL[128][192], g_MediaNum = 1, g_MediaFiles = 0

new g_NowPlaying[32]
new g_showPos[32]
new g_inConfig[32]
new g_AutoShowMenu[32]
new g_Repeat[32]
new g_DefaultVol[32]
// 0=NoChanges, 1=Saved, 2=SaveNeeded
new g_ConfigSaveStatus[32]

new shownum = 4

new keys = MENU_KEY_0|MENU_KEY_1|MENU_KEY_2|MENU_KEY_3|MENU_KEY_4|MENU_KEY_5|MENU_KEY_6|MENU_KEY_7|MENU_KEY_8|MENU_KEY_9

new LANG_MENUHEADER[64], LANG_NOWPLAYING[16], LANG_RANDOM[16], LANG_NEXT[12], LANG_BACK[12], LANG_CONFIG[7], LANG_EXIT[7], LANG_STOPMUSIC[32], LANG_LOADEDMUSIC[64], LANG_CLOSEWINDOW[64], LANG_MUSICSTOPPED[64], LANG_MENUTIP[55]
new LANG_CONFIGMENUHEADER[38], LANG_ENABLED[16], LANG_DISABLED[18], LANG_REPEAT[24], LANG_DEFAULTVOL[30], LANG_AUTOSHOWMENU[48], LANG_ABOUT[18], LANG_ALLDEFAULT[32], LANG_SAVECONFIG[16], LANG_CONFIGSAVED[50], LANG_CONFIGNOTSAVED[32], LANG_BACKTOMAINMENU[38], LANG_CONFIGMENUTIP[128]

public plugin_init() {
	register_plugin("HL Media Player", "2.1a", "kICKED")
	register_clcmd("hlmp_menu", "cmdHLMPMenu", 0, "Show HLMP Menu")
	register_clcmd("say /hlmp", "cmdHLMPMenu", 0, "Show HLMP Menu")
	register_concmd("hlmp_reloadmedia", "cmdReload", ADMIN_LEVEL_H, "Reload Media List")
	register_concmd("hlmp_view", "cmdView", ADMIN_LEVEL_H, "View the music which are players listening")
	register_menucmd(register_menuid("HLMP"), keys, "actionMenu")
	register_event("DeathMsg", "EventDeath", "a", "1>0")
	register_logevent("EventJoinTeam", 3, "1=joined team") 
	
	format(LANG_MENUHEADER, 63, "HL Media Player (HLMP 2.1a)^n")
	format(LANG_NOWPLAYING, 15, "Now Playing")
	format(LANG_RANDOM, 15, "Random")
	format(LANG_NEXT, 11, "Next")
	format(LANG_BACK, 11, "Previous")
	format(LANG_CONFIG, 6, "Config")
	format(LANG_EXIT, 6, "Exit")
	format(LANG_STOPMUSIC, 31, "Stop Music")
	format(LANG_LOADEDMUSIC, 63, "[HLMP] Loaded #musicnum# Musics from Media List.")
	format(LANG_CLOSEWINDOW, 63, "Your may now close this window (Music won't stop!)")
	format(LANG_MUSICSTOPPED, 63, "Your may now close this window.")
	format(LANG_MENUTIP, 54, "Show this menu - say: /hlmp")
	
	// Settings down here
	format(LANG_CONFIGMENUHEADER, 37, "HLMP Config Menu^n")
	format(LANG_ENABLED, 15, "Enabled")
	format(LANG_DISABLED, 17, "Disabled")
	format(LANG_REPEAT, 23, "Auto Rewind")
	format(LANG_DEFAULTVOL, 29, "Default Volume")
	format(LANG_AUTOSHOWMENU, 47, "Show Menu Automatically")
	format(LANG_ABOUT, 17, "About...")
	format(LANG_ALLDEFAULT, 31, "Back to Default")
	format(LANG_SAVECONFIG, 15, "Save Changes")
	format(LANG_CONFIGSAVED, 49, "Last Changes Saved")
	format(LANG_CONFIGNOTSAVED, 31, "NOT Saved")
	format(LANG_BACKTOMAINMENU, 37, "Back to Main Menu")
	format(LANG_CONFIGMENUTIP, 127, "Note: Changes will be applied when next song starts.")
	
	get_configsdir(g_MedialistToRead, 63)
	format(g_MedialistToRead, 63, "%s/mediafiles.ini", g_MedialistToRead)
	loadMediaList(g_MedialistToRead)
}

public EventDeath() {
	new id = read_data(2)
	if (g_AutoShowMenu[id])
		showMenu(id, g_showPos[id])
}

public EventJoinTeam() {
	new Arg1[64]
	read_logargv(0, Arg1, 63)
	new name[13], userid
	parse_loguser(Arg1, name, 12, userid)
	new id = find_player("k", userid)
	
	if (g_AutoShowMenu[id])
		showMenu(id, g_showPos[id])
}

public showMenu(id, pos) {
	new menu[512]
	
	if (g_inConfig[id]) {
		format(menu, 511, LANG_CONFIGMENUHEADER)
		format(menu, 511, "%s^n 1. %s\y\R%s\w", menu, LANG_REPEAT, g_Repeat[id]?LANG_ENABLED:LANG_DISABLED)
		format(menu, 511, "%s^n 2. %s\y\R%s\w", menu, LANG_AUTOSHOWMENU, g_AutoShowMenu[id]?LANG_ENABLED:LANG_DISABLED)
		format(menu, 511, "%s^n 3. %s\y\R%d\w", menu, LANG_DEFAULTVOL, g_DefaultVol[id])		
		format(menu, 511, "%s^n 6. \y%s\w", menu, LANG_ABOUT)
		format(menu, 511, "%s^n 7. %s", menu, LANG_ALLDEFAULT)
		if (g_ConfigSaveStatus[id] == 1) {
			format(menu, 511, "%s^n \y\R%s\w", menu, LANG_CONFIGSAVED)
		} else if (g_ConfigSaveStatus[id] == 2) {
			format(menu, 511, "%s^n 8. %s\y\R%s\w", menu, LANG_SAVECONFIG, LANG_CONFIGNOTSAVED)
		}
		format(menu, 511, "%s^n 9. %s", menu, LANG_BACKTOMAINMENU)
		format(menu, 511, "%s^n 0. %s", menu, LANG_EXIT)
		format(menu, 511, "%s^n^n%s", menu, LANG_CONFIGMENUTIP)
	} else {
		format(menu, 511, LANG_MENUHEADER)
		if (g_NowPlaying[id])
			format(menu, 511, "%s%s: %s^n", menu, LANG_NOWPLAYING, g_MediaNames[g_NowPlaying[id]])
		
		new a = 1
		for (new i = pos; a <= shownum; ++i) {
			if (i != 0) {
				if (equali(g_MediaNames[pos+a], "") != 1)
					format(menu, 511, "%s^n %d. %s", menu, a, g_MediaNames[pos+a])
				
				a++
			}
		}
		format(menu, 511, "%s^n^n 5. %s", menu, LANG_RANDOM)
		format(menu, 511, "%s^n 6. %s", menu, LANG_STOPMUSIC)
		if (pos+shownum < g_MediaFiles)
			format(menu, 511, "%s^n 7. %s", menu, LANG_NEXT)
		if (pos != 0)
			format(menu, 511, "%s^n 8. %s", menu, LANG_BACK)
		format(menu, 511, "%s^n 9. %s", menu, LANG_CONFIG)
		format(menu, 511, "%s^n 0. %s", menu, LANG_EXIT)
		format(menu, 511, "%s^n^n%s", menu, LANG_MENUTIP)
	}
	show_menu(id, keys, menu, 30)
	
	return PLUGIN_HANDLED
}

public actionMenu(id, key) {
	key++
	if (g_inConfig[id]) {
		if (key == 1) {
			if (g_Repeat[id])
				g_Repeat[id] = 0
			else
				g_Repeat[id] = 1
			g_ConfigSaveStatus[id] = 2
			showMenu(id, g_showPos[id])
		} else if (key == 2) {
			if (g_AutoShowMenu[id])
				g_AutoShowMenu[id] = 0
			else
				g_AutoShowMenu[id] = 1
			g_ConfigSaveStatus[id] = 2
			showMenu(id, g_showPos[id])
		} else if (key == 3) {
			g_DefaultVol[id] += 25
			if (g_DefaultVol[id] > 100)
				g_DefaultVol[id] = 0
			g_ConfigSaveStatus[id] = 2
			showMenu(id, g_showPos[id])
		} else if (key == 6) {
			client_print(id, print_chat, "HL Media Player 2.1a by kICKED @ XGAMERHK.COM")
			client_print(id, print_center, "HL Media Player 2.1a by kICKED @ XGAMERHK.COM")
			showMenu(id, g_showPos[id])
		} else if (key == 7) {
			g_AutoShowMenu[id] = 1
			g_Repeat[id] = 0
			g_DefaultVol[id] = 50
			g_ConfigSaveStatus[id] = 2
			showMenu(id, g_showPos[id])
		} else if (key == 8) {
			if (g_ConfigSaveStatus[id] == 2) {
				client_cmd(id, "setinfo hlmp_asm %d", g_AutoShowMenu[id]) 
				client_cmd(id, "setinfo hlmp_rep %d", g_Repeat[id])
				client_cmd(id, "setinfo hlmp_vol %d", g_DefaultVol[id])
				g_ConfigSaveStatus[id] = 1
			} else {
				g_ConfigSaveStatus[id] = 0
			}
			showMenu(id, g_showPos[id])
		} else if (key == 9) {
			g_inConfig[id] = 0
			showMenu(id, g_showPos[id])
			g_ConfigSaveStatus[id] = 0
		} else if (key == 10) {
			//Do nothing
		} else {
			showMenu(id, g_showPos[id])
			g_ConfigSaveStatus[id] = 0
		}
	} else {
		if (key == 5) {
			show_HLMP(id, random_num(1, g_MediaFiles))
		} else if (key == 6) {
			new motd[256]
			g_NowPlaying[id] = 0
			format(motd, 255, "<html><head><meta http-equiv=^"content-type^" content=^"text/html; charset=UTF-8^"></head><body bgcolor=^"#000000^" align=^"center^"><span style=^"color: #FFB000; font-size: 9pt^">%s</span></body></html>", LANG_MUSICSTOPPED)
			show_motd(id, motd, "HL Media Player")
		} else if (key == 7) {
			if (g_showPos[id]+shownum < g_MediaFiles)
				g_showPos[id] = g_showPos[id]+shownum
			showMenu(id, g_showPos[id])
		} else if (key == 8) {
			if (g_showPos[id] != 0)
				g_showPos[id] = g_showPos[id]-shownum
			showMenu(id, g_showPos[id])
		} else if (key == 9) {
			g_inConfig[id] = 1
			showMenu(id, g_showPos[id])
		} else if (key == 10) {
			//Do nothing
		} else {
			new MediaID = g_showPos[id]+key
			if (!equali(g_MediaNames[MediaID], "")) {
				show_HLMP(id, MediaID)
			} else {
				showMenu(id, g_showPos[id])
			}
		}
	}
	return PLUGIN_HANDLED
}

public show_HLMP(id, MediaID) {
	new motd[1024], MediaURL[128]
	g_NowPlaying[id] = MediaID
	
	format(MediaURL, 127, g_MediaURL[MediaID][0])
	format(motd, 1023, "<html><head><meta http-equiv=^"content-type^" content=^"text/html; charset=UTF-8^"></head><body bgcolor=^"#000000^" align=^"center^"><span style=^"color: #FFB000; font-size: 9pt^">Now playing: %s (#%d)<br>", g_MediaNames[MediaID], MediaID)
	format(motd, 1023, "%s<object classid=CLSID:6BF52A52-394A-11d3-B153-00C04F79FAA6 codebase=http://www.microsoft.com/ntserver/netshow/download/en/nsmp2inf.cab#Version=5,1,51,415 type=application/x-oleobject name=msplayer width=256 height=65 align=^"middle^" id=msplayer>", motd)
	format(motd, 1023, "%s<param name=^"enableContextMenu^" value=^"0^"><param name=^"stretchToFit^" value=^"1^">", motd)
	if (g_Repeat[id])
		format(motd, 1023, "%s<param name=^"AutoRewind^" value=^"1^">", motd)
	format(motd, 1023, "%s<param name=^"Volume^" value=^"%d^">", motd, g_DefaultVol[id])
	format(motd, 1023, "%s<param name=^"AutoStart^" value=^"1^"><param name=^"URL^" value=^"%s^">", motd, MediaURL)
	format(motd, 1023, "%s<param name=^"uiMode^" value=^"full^"><param name=^"width^" value=^"256^"><param name=^"height^" value=^"65^">", motd)
	format(motd, 1023, "%s<param name=^"TransparentAtStart^" value=^"1^"></object><br>%s</span>", motd, LANG_CLOSEWINDOW)
	format(motd, 1023, "%s</body></html>", motd)
	show_motd(id, motd, "HL Media Player")
}

public loadMediaList(filename[]) {
	if (!file_exists(filename)) {
		return 0
	}
	new text[256], a = 0, pos = 0
	while (read_file(filename, pos++, text, 255, a)) {
		if (text[0] != ';') {
			if (!equali(text, "")) {
				parse(text, g_MediaNames[g_MediaNum], 63, g_MediaURL[g_MediaNum], 191)
				g_MediaNum++
				g_MediaFiles++
			}
		}
	}
	new str_MediaFiles[4]
	num_to_str(g_MediaFiles, str_MediaFiles, 3)
	new print[64]
	format(print, 63, LANG_LOADEDMUSIC)
	replace(print, 63, "#musicnum#", str_MediaFiles)
	console_print(0, print)
	return 1
}

public cmdHLMPMenu(id) {
	showMenu(id, g_showPos[id])
	return PLUGIN_HANDLED
}

public cmdReload(id, level, cid) {
	if (!cmd_access(id, level, cid, 1))
		return PLUGIN_HANDLED
	g_MediaNum = 1
	g_MediaFiles = 0
	loadMediaList(g_MedialistToRead)
	console_print(id, "[HLMP Admin] %d musics loaded from media list.", g_MediaFiles)
	return PLUGIN_HANDLED
}

public cmdView(id, level, cid) {
	if (!cmd_access(id, level, cid, 1))
		return PLUGIN_HANDLED
	
	console_print(id, "Currently Playing Media of Players: ")
	console_print(id, "*********************************")
	console_print(id, "ID | Player | Media")
	
	new players[32], num, i
	get_players(players, num)
	new playernum, playername[32], tt
	for (i=0; i<num; i++) {
		tt = players[i]
		if (g_NowPlaying[tt] > 0) {
			get_user_name(tt, playername, 31)
			console_print(id, "%d | %s | %s", players[i], playername, g_MediaNames[g_NowPlaying[tt]])
			playernum++
		}
	}
	if (playernum < 1) {
		console_print(id, "Nobody is using HLMP.")
	}
	console_print(id, "*********************************")
	console_print(id, "Total player listed: %d players", playernum)
	console_print(id, "*********************************")
	return PLUGIN_HANDLED
}

public client_putinserver(id) {
	g_showPos[id] = 0
	g_inConfig[id] = 0
	g_NowPlaying[id] = 0
	g_ConfigSaveStatus[id] = 0
	
	new asm[2], rep[2], vol[4]
	get_user_info(id, "hlmp_asm", asm, 1)
	get_user_info(id, "hlmp_rep", rep, 1)
	get_user_info(id, "hlmp_vol", vol, 3)
	
	if (equali(asm, ""))
		g_AutoShowMenu[id] = 1
	else
		g_AutoShowMenu[id] = str_to_num(asm)
	
	if (equali(rep, ""))
		g_Repeat[id] = 0
	else
		g_Repeat[id] = str_to_num(rep)
	
	if (equali(vol, ""))
		g_DefaultVol[id] = 50
	else
		g_DefaultVol[id] = str_to_num(vol)
}