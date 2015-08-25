new const PLUGINNAME[] = "AMX Map Handler"
new const VERSION[] = "0.6"
new const AUTHOR[] = "JGHG"

/*
Copyleft 2003-2005
AMX Mod X: http://www.amxmodx.org/forums/viewtopic.php?p=3192

AMX MAP HANDLER
===============
*IMPORTANT*
*IMPORTANT*
*IMPORTANT* This plugin should be put BEFORE mapchooser.amx and mapsmenu.amx
*IMPORTANT* in your plugins.ini file!
*IMPORTANT*
*IMPORTANT*

*MORE IMPORTANT STUFF*
*MORE IMPORTANT STUFF* If you have above 128 maps, you probably want to edit "#define MAXMAPS 128"
*MORE IMPORTANT STUFF* below to how many maps you need. Doing so, you also have to edit the line
*MORE IMPORTANT STUFF* "#pragma dynamic 20000" to some higher value. If you get "run time error 3" while
*MORE IMPORTANT STUFF* the plugin is running, you need to adjust the value even higher. Take care though, this adjusts how much
*MORE IMPORTANT STUFF* memory the plugin is allowed to use, so don't go all crazy with this one. Sorry for this mess, I'll probably need
*MORE IMPORTANT STUFF* to rewrite this plugin to get rid of all this.
*MORE IMPORTANT STUFF*

Adding and removing maps from your server has never been this easy.
With AMX Map Handler you just put the maps into your server and don't
have to worry about editing mapcycle.txt or maps.ini, since this is
done automatically.

Maps.ini is used by the Mapchooser ("Time to choose!") and the Mapsmenu plugins.

Mapcycle.txt is updated with a console command, and maps.ini is updated
on every map startup. Because of this it is important that you put the
amx file of this BEFORE mapchooser.amx and mapsmenu.amx in your plugins.ini,
or you will have to restart map two times before you can see the newly added
maps.
After your first run you can open up maps.ini to change the default
name of each map (that's within the quotes). If you remove commented maps
from server for a while, and then put them back, AMX Map Handler will remember
the map name as you typed it. Nifty, eh?
The default name of a map is its file name.

But wait, there's more. If you download within 15 minutes, we'll add
this nifty map listing command (amx_listmaps) that has the look and feel of the
amx_help command. It completely replaces the client "listmaps" command (which can overflow the client!), and also
works on server console.

Have fun.

/JGHG

HOW TO INSTALL
==============
1. Name this file amx_maphandler.sma.
2. Compile it into amx_maphandler.amx.
3. Put amx_maphandler.amx into amxmodx/plugins directory.
4. Open up amxmodx/configs/plugins.ini and add line RIGHT BEFORE mapsmenu.amx and mapchooser.amx saying: amx_maphandler.amx
5. You can create the file amxmodx/configs/maphandler_unwantedmaps.cfg. Any maps added to it (one on each line!) will NOT be available in maps.inis/mapcycles,
regardless if they are found within maps/ dir. If you don't need this feature you don't need this file.
6. You can create the file amxmodx/configs/maphandler_wantedmaps.cfg. Any maps added to it (one on each line!) WILL be added once to mapsinis/mapcycles
regardless if it exists in maps/ dir or not. This feature was requested by some people. No need of feature no need of file.
7. Done. Type reload in your server.
8. Note that mapsmenu.amx has a default limit of 64 maps or so. You might want to change it to 128 if you have many maps and know how to do it.

HOW TO USE
==========
amx_listmaps [page], OR listmaps [page]
- Use this command to list maps. Works for both clients and
server console. If a client types "listmaps" it will replace Steam's normal (and overflowable if you have a lot of maps!) listmaps command.
If you don't specify a numeric argument, it treats the argument as a wildcard so if you for example try "listmaps ice" it will display all maps consisting
of the word "ice" in your server. If you have very many maps matching the wildcard it will still only display the max amount of maps on a page. To access the rest
you set the start number as the second parameter to this, ie "listmaps ice 16" to standard searching for "ice" from the 16th map on the server.

amx_mh_page
- This is a cvar that sets how many maps should be listed
each page. Default is 15.

AMX Map Handler automatically summons an internal textfile with all valid bsp
files residing in maps folder when a level loads. Do not touch
this textfile. Everything is handled automatically.

amx_mh_filename
- This is a cvar with path/filename of the dynamically created
maplist. Default is addons/amx/amx_maphandler.ini

amx_mapcycle <file.txt>
- Generates a mapcycle-style file. Specify "mapcycle.txt" to
output to standard mapcycle file. The maps are placed in random order.
Beware: the file you specify will be overwritten. There seems also
be a limit of HLDS of 100 maps in mapcycle. Only 100 maps will be
added to list.

amx_randommap
- Changes to a randomly chosen map.

amx_mh_mapsini
- This is a cvar with path/filename to maps.ini file. Default is
addons/amxmodx/maps.ini.

VERSIONS
========
0.6			050221	Added use of configs/maphandler_unwantedmaps.cfg and configs/maphandler_wantedmaps.cfg. Read HOW TO INSTALL for info on the use of these files.
0.5			041228	Updated listmaps/amx_listmaps to also allow listing maps by wildcards. "listmaps de_" would find all maps consisting of "de_"...
0.4			041214	"listmaps" command by client will now use this plugin's way of listing maps.
					Valve's own method would overflow the client if you had a lot (>100) of maps on your server.
					Also "listmaps" now works on server console as well.
0.3			041003	Fixed up old (amxmod/amxx) code. Shouldn't use any constant paths now.
0.2.9		040601	AMXXed the includes. Obviously forgot to do it earlier (!)
0.2.8		040531	Another small update that should fix plugin from not working sometimes.
0.2.7				Small update to use amxx/custom path used from AMX Mod X 0.16.
0.2.6				Once again updated to work with old (and current AMXX) compiler.
0.2.5				Updated to work with AMX Mod X paths.
0.2.4				(not yet released) Small update with amx_listmaps.
					Added amx_randommap.
0.2.3				Maps with uppercase letters would be sorted first in the files. This version converts all map names to lowercase.
0.2.2				If you didn't have a file at specified amx_mh_mapsini location, descriptions wouldn't be added until next time when it exists.
0.2.1				Minor tweak. Doesn't anymore remember map description if it's the same as the filename. :-)
0.2					Changed plugin name. :-)
					Added a lot of stuff. :-)
0.1					First version

TO DO
=====
?
*/

#include <amxmodx>
#include <amxmisc>

#pragma dynamic 20000 //defult 20000

#define MAXMAPS 100 // 120 // default 100
#define MAPLENGTH 32 // 30
#define DESCRIPTION 64
#define MAPDESC MAPLENGTH + DESCRIPTION
#define STANDARDPAGESIZE 15
#define MAXMAPSINMAPCYCLE 100
#define DATAFILE			"maphandler.dat"
#define UNWANTEDMAPSCFGFILE	"maphandler_unwantedmaps.cfg"
#define WANTEDMAPSCFGFILE	"maphandler_wantedmaps.cfg"
new const CVAR_MHINIFILE[] = "amx_mh_filename"
new MAPHANDLERDATAFILE[256]
new g_unwantedMapsFile[256]
new g_wantedMapsFile[256]
new MAPSINIPATH[256]

// Globals below
new bool:inited = false
// Globals above

stock charOccurances(string[],matchchar[]) {
	if (strlen(matchchar) != 1)
		return -1

	new occurances = 0
	//server_print("Occurances inited to %d", occurances)
	new len = strlen(string)
	for (new i = 0;i < len;i++) {
		if (string[i] == matchchar[0]) {
			occurances++
		}
	}

	return occurances
}

// Return true if we don't want this map
bool:InvalidMap(mapName[]) {
	// Filename must exist
	new pos = 0, textline[256], len
	do {
		pos = read_file(g_unwantedMapsFile, pos, textline, 255, len)
		if (equali(textline, mapName))
			return true
	}
	while (pos)

	return false
}

AddWantedMaps(maps[MAXMAPS][MAPLENGTH], &mapsCount) {
	//server_print("[%s] Adding extra maps defined in cfg file...", PLUGINNAME)
	// Filename must exist
	new pos = 0, mapline[MAPLENGTH], len
	while (mapsCount < MAXMAPS && (pos = read_file(g_wantedMapsFile, pos, mapline, MAPLENGTH - 1, len))) {
		if (len < 1)
			continue

		strtolower(mapline)

		// See if it's already in our list
		new bool:already = false
		for (new i = 0; i < mapsCount; i++) {
			if (equal(mapline, maps[i])) {
				already = true
				break
			}
		}
		if (already) {
			//server_print("[%s] Already in list because we found it earlier in maps directory: %s (len %d)", PLUGINNAME, mapline, len)
			continue
		}
		else {
			//server_print("[%s] Adding extra map not in maps dir: %s. Map is %s. (len %d)", PLUGINNAME, mapline, is_map_valid(mapline) ? "VALID" : "INVALID", len)
			maps[mapsCount++] = mapline
		}
	}
}

writemaps() {
	// Get valid maps to multiarray
	new pos = 0, fileName[MAPLENGTH + 4], mapName[MAPLENGTH], len, mapsCount = 0, bspPos
	new maps[MAXMAPS][MAPLENGTH]
	new bool:checkInvalid = file_exists(g_unwantedMapsFile) ? true : false
	//new debugcounter = 0
	do {
		//debugcounter++
		//server_print("[%s] DEBUG - Sending pos: %d", PLUGINNAME, pos)
		pos = read_dir("maps/", pos, fileName, MAPLENGTH + 3, len)
		//server_print("[%s] DEBUG - Reading %s at pos %d with length %d (counter: %d)", PLUGINNAME, fileName, pos, len, debugcounter)
		if (len >= 5) {
			bspPos = len - 4
			if (pos && containi(fileName,".bsp") == bspPos) {
				copy(mapName,bspPos,fileName)
				//server_print("%s: DEBUG - found map: %s", PLUGINNAME, mapName)
				if (is_map_valid(mapName)) {
					strtolower(mapName) // Nothing wrong with this native.

					// Don't add maps we specifically don't want.
					if (checkInvalid && InvalidMap(mapName)) {
						//server_print("[%s] Not adding %s because we don't want it...", PLUGINNAME, mapName)
						continue
					}
					//else
						//server_print("[%s] Adding %s...", PLUGINNAME, mapName)
					maps[mapsCount] = mapName
					mapsCount++
				}
				//else
					//server_print("[%s] DEBUG - %s is an invalid map", PLUGINNAME, mapName)
			}
			//else
				//server_print("[%s] DEBUG - File ^"%s^" does not end with ^".bsp^" so it's probably not a map file.", PLUGINNAME, fileName)
		}
		//else
			//server_print("[%s] DEBUG - File ^"%s^" is probably not a map file since its name is too short.", PLUGINNAME, fileName)
	}
	while (pos && mapsCount < MAXMAPS)

	if (file_exists(g_wantedMapsFile))
		AddWantedMaps(maps, mapsCount)

	//server_print("[%s] DEBUG - Done looking through maps/ directory. Counter: %d", PLUGINNAME, debugcounter)

	// Sort
	new bool:sorted, skoj[MAPLENGTH], iLen, iLen2, shortestLen, j
	do {
		sorted = true
		for (new i = 0;i < mapsCount - 1;i++) {

			iLen = strlen(maps[i])
			iLen2 = strlen(maps[i + 1])
			if (iLen2 < iLen)
				shortestLen = iLen2
			else
				shortestLen = iLen


			for (j = 0;j < shortestLen;j++) {
				if (maps[i + 1][j] < maps[i][j]) {
					skoj = maps[i]
					maps[i] = maps[i + 1]
					maps[i + 1] = skoj

					sorted = false
					break
				}
				else if (maps[i + 1][j] > maps[i][j])
					break
			}
			if (j == shortestLen) {
				if (iLen2 < iLen) {
					skoj = maps[i]
					maps[i] = maps[i + 1]
					maps[i + 1] = skoj

					sorted = false
				}
			}
		}
	}
	while (!sorted)

	// Get file name, write to file, start writing mapsCount
	new outfile[128]
	get_cvar_string(CVAR_MHINIFILE,outfile,127)

	server_print("[%s] %sFound %d valid maps in server.", PLUGINNAME, mapsCount == 0 ? "WARNING - " : "", mapsCount)

	new mapsCountString[8]
	num_to_str(mapsCount,mapsCountString,7)

	if (file_exists(outfile))
		if (!delete_file(outfile)) {
			server_print("[%s] ERROR, Couldn't delete %s! Failed initializing %s.", PLUGINNAME,outfile,PLUGINNAME)
			return 0
		}

	log_amx("About to write to %s.", outfile)
	if (!write_file(outfile,mapsCountString)) {
		server_print("[%s] ERROR, Couldn't write to %s! Failed initializing %s.", PLUGINNAME,outfile,PLUGINNAME)
		return 0
	}

	for (new i = 0;i < mapsCount;i++)
		if (!write_file(outfile,maps[i])) {
			server_print("[%s] ERROR, Couldn't write to %s! Failed initializing %s.", PLUGINNAME,outfile,PLUGINNAME)
			return 0
		}

	return 1
}
public amx_listmaps(id) {
	return listmaps_fn(id, "amx_listmaps")
}
public listmaps(id) {
	return listmaps_fn(id, "listmaps")
}
public listmaps_fn(id, const COMMANDUSED[]) {
	new infile[128]
	get_cvar_string(CVAR_MHINIFILE,infile,127)

	if (!inited || !file_exists(infile)) {
		console_print(id, "[%s] Map list initialization failed.", PLUGINNAME)
		return PLUGIN_HANDLED
	}

	new page = get_cvar_num("amx_mh_page")
	if (!page)
		page = STANDARDPAGESIZE

	new mapsCount, mapsCountString[10], mcs_len
	read_file(infile,0,mapsCountString,9,mcs_len)
	if (mcs_len > 0)
		mapsCount = str_to_num(mapsCountString)
	else {
		console_print(id, "[%s] Odd error. You aren't fiddling with the wrong config files, are you?", PLUGINNAME)
		return PLUGIN_HANDLED
	}

	new startPos = 1, arg[128], argCount = read_argc()
	if (argCount > 1) {
		read_argv(1, arg, 127)
		console_print(id, "----- Maps matching ^"%s^" -----", arg)
		for (new i = 0; i < strlen(arg); i++) {
			if (!isdigit(arg[i])) {
				//console_print(id, "[%s] You must specify a numerical value.", PLUGINNAME)
				// Start doing the part of listing
				if (argCount > 2) {
					new arg2[128]
					read_argv(2, arg2, 127)
					startPos = str_to_num(arg2)
				}
				else
					startPos = 1

				new textline[64], textlength, oldI = 0, displayedItems = 0
				i = startPos
				do {
					oldI = i
					textlength = 0
					i = read_file(infile, i, textline, 63, textlength)
					if (textlength < 1)
						continue
					//console_print(id, "%d: %s%s", oldI, textline, containi(textline, arg) != -1 ? " MATCH" : "")
					if (containi(textline, arg) != -1) {
						++displayedItems
						console_print(id, "%d: %s", oldI, textline)
					}
				}
				while (i != 0 && displayedItems < page)
				if (i)
					console_print(id, "----- Use '%s %s %d' to find more -----", COMMANDUSED, arg, i)
				else
					console_print(id, "----- Last page displayed. Use '%s %s' to find from start -----", COMMANDUSED, arg)

				return PLUGIN_HANDLED
			}
		}
		startPos = str_to_num(arg)
		if (startPos < 1)
			startPos = 1
		else if (startPos > mapsCount)
			startPos = mapsCount - page + 1
	}
	else if (argCount != 1) {
		console_print(id, "[%s] Incorrect use.", PLUGINNAME)
		return PLUGIN_HANDLED
	}

	new textline[64], textlength, i
	console_print(id, "----- Valid maps on server -----")
	for (i = startPos; i < startPos + page && i <= mapsCount; i++) {
		read_file(infile, i, textline, 63, textlength)
		console_print(id, "%d: %s", i, textline)
	}

	console_print(id,"----- Maps %d - %d of %d -----",startPos,i - 1,mapsCount)
	if (startPos == 1 && i - 1 == mapsCount) {}
	else if (i <= mapsCount)
		console_print(id,"----- Use '%s %d' for more -----", COMMANDUSED, i)
	else
		console_print(id,"----- Use '%s' for beginning -----", COMMANDUSED)

	return PLUGIN_HANDLED
}

public mapcycle(id,level,cid) {
	if (!cmd_access(id,level,cid,2)) {
		console_print(id,"[%s] Incorrect use. Specify a file that should be written as mapcycle. Mapcycle.txt replaces standard mapcycle.", PLUGINNAME)
		return PLUGIN_HANDLED
	}

	new argCount = read_argc()
	if (argCount != 2) {
		console_print(id,"[%s] Incorrect use. Specify a file that should be written as mapcycle. Mapcycle.txt replaces standard mapcycle.", PLUGINNAME)
		return PLUGIN_HANDLED
	}

	new infile[128]
	get_cvar_string(CVAR_MHINIFILE,infile,127)

	if (!inited || !file_exists(infile)) {
		console_print(id,"[AMX] Map list initialization failed.")
		return PLUGIN_HANDLED
	}

	new mapsCount, mapsCountString[10], mcs_len
	read_file(infile,0,mapsCountString,9,mcs_len)
	if (mcs_len > 0)
		mapsCount = str_to_num(mapsCountString)
	else {
		console_print(id,"[%s] Odd error. You aren't fiddling with the wrong config files, are you?", PLUGINNAME)
		return PLUGIN_HANDLED
	}

	new outfile[128]
	read_argv(1,outfile,127)
	if (file_exists(outfile)) {
		if (!delete_file(outfile)) {
			console_print(id,"[%s] Failed to delete already existing '%s'.", PLUGINNAME,outfile)
			return PLUGIN_HANDLED
		}
	}

	new maps[MAXMAPS][MAPLENGTH]
	new textline[MAPLENGTH], textlength, line = 1

	do {
		line = read_file(infile,line,textline,MAPLENGTH - 1,textlength)
		if (line)
			maps[line - 2] = textline
	}
	while (line)

	new moveUp, temp[MAPLENGTH], mapsCount2 = 0
	for (new i = 0;i < mapsCount && i < MAXMAPSINMAPCYCLE;i++) {
		moveUp = random_num(i,mapsCount - 1)
		temp = maps[i]
		maps[i] = maps[moveUp]
		maps[moveUp] = temp

		if (!write_file(outfile,maps[i])) {
			console_print(id,"[%s] Failed while trying to write '%s' to '%s'.", PLUGINNAME,textline,outfile)
			return PLUGIN_HANDLED
		}
		else {
			mapsCount2++
		}
	}

	console_print(id,"[%s] Successfully wrote %d maps to %s.", PLUGINNAME,mapsCount2,outfile)

	return PLUGIN_HANDLED
}

writemapsini() {
	server_print("[%s] Starting dump of maps...", PLUGINNAME)

	// Check if we inited properly.
	new infile[128]
	get_cvar_string(CVAR_MHINIFILE,infile,127)
	if (!inited || !file_exists(infile)) {
		server_print("[%s] Map list initialization failed.", PLUGINNAME)
		return PLUGIN_HANDLED
	}

	// Get mapsCount.
	new mapsCount, mapsCountString[10], mcs_len
	read_file(infile,0,mapsCountString,9,mcs_len)
	if (mcs_len > 0)
		mapsCount = str_to_num(mapsCountString)
	else {
		server_print("[%s] Odd error. You aren't fiddling with the wrong config files, are you?", PLUGINNAME)
		return PLUGIN_HANDLED
	}

	// Read in the valid maps.
	new maps[MAXMAPS][MAPDESC]
	new textline[MAPDESC], textlength, line = 1

	do {
		line = read_file(infile,line,textline,MAPDESC - 1,textlength)
		if (line)
			maps[line - 2] = textline
	}
	while (line)

	// Check if maps.ini exists.
	new mapsini[128]
	get_cvar_string("amx_mh_mapsini",mapsini,127)
	if (!file_exists(mapsini)) {
		// Doesn't exist. Just write all maps to the file.
		if (!initMapsini(mapsini)) {
			server_print("[%s] Error: couldn't initialize '%s'!", PLUGINNAME, mapsini)
			return PLUGIN_HANDLED
		}

		// Write "tab + quote + mapname + quote" to all posts in maps[][] that doesn't already have that.
		for (new i = 0;i < mapsCount;i++) {
			if (charOccurances(maps[i],"^"") == 0)
				format(maps[i],MAPDESC - strlen(maps[i]),"%s^t^"%s^"",maps[i],maps[i])
		}

		// Write contents of maps[][] to file.
		new mapsCount2 = 0
		for (new i = 0;i < mapsCount && i < MAXMAPS;i++) {
			if (!write_file(mapsini,maps[i])) {
				server_print("[%s] Failed while trying to write '%s' to '%s'.", PLUGINNAME, maps[i], mapsini)
				return PLUGIN_HANDLED
			}
			else {
				mapsCount2++
			}
		}
		server_print("[%s] Successfully wrote %d maps to '%s'.", PLUGINNAME,mapsCount2,mapsini)
		return PLUGIN_HANDLED
	}

	// This far, the maps.ini file exists. We need to make a new one. Make sure it doesn't exist, or delete it.

	//new tempfile[] = "addons/amxmodx/__tempfile3252.ini"
	new tempfile[256]
	get_configsdir(tempfile, 255)
	format(tempfile, 255, "%s/__tempfile3252.ini", tempfile)

	if (file_exists(tempfile)) {
		if (!delete_file(tempfile)) {
			server_print("[%s] Error: couldn't delete temporary initialization file '%s'!", PLUGINNAME,tempfile)
			return PLUGIN_HANDLED
		}
	}

	if (!initMapsini(tempfile)) {
		server_print("[%s] Error: couldn't initialize '%s'!", PLUGINNAME,tempfile)
		if (file_exists(tempfile)) {
			if (!delete_file(tempfile))
				server_print("[%s] Error: couldn't delete temporary initialization file '%s'!", PLUGINNAME,tempfile)
		}
		return PLUGIN_HANDLED
	}

	/*
	Read a line from current maps.ini starting from line 0. Only keep commented lines with two quotes.
	If it contains two quotes, write that line to the temp file.
	*/
	textline = "\0"
	textlength = 0
	line = 1
	new firstWord[MAPLENGTH], bool:matches
/*
	// If first character is a ; in firstWord, strip it
	server_print("firstword: %s",firstWord)
	if (firstWord[0] == ';') {
		server_print("Stripping firstword: %s to...",firstWord)
		replace(firstWord,MAPLENGTH,";","")
		server_print("...%s",firstWord)
	}
*/
	new occurances
	do {
		matches = false
		line = read_file(mapsini,line,textline,MAPDESC - 1,textlength)
		if (line && textlength > 0) {
			occurances = charOccurances(textline,"^"")
			if (textline[0] == ';' && occurances  == 2) {
				if (parse(textline,firstWord,MAPLENGTH - 1)) {

					replace(firstWord,MAPLENGTH,";","")

					for (new i = 0;i < mapsCount;i++) {
						if (equali(firstWord,maps[i])) {
							// Strip ; from textline
							replace(textline,MAPDESC,";","")
							maps[i] = textline
							matches = true
							break
						}
					}
				}

				if (!matches) {
					if (!write_file(tempfile,textline)) {
						server_print("[%s] Error: couldn't write to temporary file '%s'!", PLUGINNAME,tempfile)
						break
					}
				}
			}
			else {
				// If textline has two quotes on the line, do this:
				// Get first word of textline and see if it matches any of the strings
				// in maps[][]. If so update the maps[][] with that whole line and break.
				// Make sure it is lower case so it looks proper. :-)
				// If it doesn't match, write it to temp file with a ; before it.
				if (charOccurances(textline,"^"") == 2) {
					if (parse(textline,firstWord,MAPLENGTH - 1)) {
						for (new i = 0;i < mapsCount;i++) {
							if (equali(firstWord,maps[i])) {
								strtolower(textline)
								maps[i] = textline
								matches = true
								break
							}
						}
					}

					if (!matches) {
						new mapNameLen = strlen(firstWord)

						if (textline[textlength - (2 + mapNameLen)] == '^"'
						&& equal(textline[textlength - (1 + mapNameLen)],firstWord,mapNameLen)
						&& textline[textlength - 1] == '^"') {
							// Don't write line, a comment with just the filename isn't needed to save.
						}
						else {
							new commented[MAPDESC + 1] = ";"
							copy(commented[1],MAPDESC + 1,textline)
							if (!write_file(tempfile,commented)) {
								server_print("[%s] Error: couldn't write to temporary file '%s'!", PLUGINNAME,tempfile)
								if (file_exists(tempfile)) {
									if (!delete_file(tempfile))
										server_print("[%s] Error: couldn't delete temporary initialization file '%s'!", PLUGINNAME,tempfile)
								}

								return PLUGIN_HANDLED
							}
						}
					}
				}
			}
		}
	}
	while (line)

	// Write "tab + quote + mapname + quote" to all posts in maps[][] that doesn't already have that.
	for (new i = 0;i < mapsCount;i++) {
		if (charOccurances(maps[i],"^"") == 0)
			format(maps[i],MAPDESC - strlen(maps[i]),"%s^t^"%s^"",maps[i],maps[i])
	}

	// Write maps[][] to tempfile
	for (new i = 0;i < mapsCount;i++) {
		if (!write_file(tempfile,maps[i])) {
			server_print("[%s] Error: couldn't write to temporary file '%s'!", PLUGINNAME,tempfile)
			if (file_exists(tempfile)) {
				if (!delete_file(tempfile))
					server_print("[%s] Error: couldn't delete temporary initialization file '%s'!", PLUGINNAME,tempfile)
			}

			return PLUGIN_HANDLED
		}
	}

	// Delete old maps.ini.
	if (!delete_file(mapsini)) {
		server_print("[%s] Error: couldn't delete old '%s' to replace it with a new one! New one is saved to '%s'.", PLUGINNAME,mapsini,tempfile)
		return PLUGIN_HANDLED
	}

	// Write a new maps.ini from tempfile.
	textline = "\0"
	textlength = 0
	line = 0
	new writtenLines = 0
	do {
		line = read_file(tempfile,line,textline,MAPDESC - 1,textlength)
		if (line) {
			if (!write_file(mapsini,textline)) {
				server_print("[%s] Error: couldn't write to map file '%s'! Map list saved to '%s'.", PLUGINNAME,mapsini,tempfile)
				return PLUGIN_HANDLED
			}
			else
				writtenLines++
		}
	}
	while (line)

	server_print("[%s] Successfully wrote %d lines to '%s'.", PLUGINNAME,writtenLines,mapsini)

	// Delete the temporary file if it still exists
	if (file_exists(tempfile)) {
		if (!delete_file(tempfile))
			server_print("[%s] Error: couldn't delete temporary initialization file '%s'!", PLUGINNAME,tempfile)
	}

	return PLUGIN_HANDLED
}

initMapsini(mapsini[]) {
	new formattedLine[128]
	new amxversion[32]

	if (!write_file(mapsini,"; Maps configuration file"))
		return 0
	format(formattedLine,127,"; Automatically generated by %s version %s",PLUGINNAME,VERSION)
	if (!write_file(mapsini,formattedLine))
		return 0
	get_cvar_string("amxmodx_version",amxversion,31)
	format(formattedLine,127,"; AMX Mod X version: %s",amxversion)
	if (!write_file(mapsini,formattedLine))
		return 0
	format(formattedLine,127,"; Running %s server on %s",is_dedicated_server() ? "dedicated" : "listen",is_linux_server() ? "Linux" : "Windows")
	if (!write_file(mapsini,formattedLine))
		return 0
	get_cvar_string("amx_mh_mapsini",amxversion,31);
	format(formattedLine,127,"; File location: %s",amxversion)
	if (!write_file(mapsini,formattedLine)) // amx_mh_mapsini
		return 0
	if (!write_file(mapsini,"; This file is used by Maps Menu plugin, Nextmap chooser and maybe even more..."))
		return 0

		//; File location: $moddir/addons/amx/maps.ini

	return 1
}

public randommap(id,level,cid) {
	if (!cmd_access(id, level, cid, 1))
		return PLUGIN_HANDLED

	if (!inited) {
		console_print(id, "%s has not initialized!", PLUGINNAME)
		return PLUGIN_HANDLED
	}
	new file[128]
	get_cvar_string(CVAR_MHINIFILE, file, 127)

	new mapsCount, buffer[128], len
	if (!read_file(file, 0, buffer, 127, len)) {
		console_print(id, "Failed reading from %s!", file)
		return PLUGIN_HANDLED
	}
	mapsCount = str_to_num(buffer)

	if (mapsCount < 0) {
		console_print(id, "No maps in server!")
		return PLUGIN_HANDLED
	}
	else if (mapsCount == 1) {
		console_print(id, "Sorry, only one map exists in server.")
		return PLUGIN_HANDLED
	}

	new line, currentmap[64]
	do {
		line = random_num(1, mapsCount)

		if (!read_file(file, line, buffer, 127, len)) {
			console_print(id, "Failed reading from %s!", file)
			return PLUGIN_HANDLED
		}

		if (!is_map_valid(buffer)) {
			console_print(id, "%s is invalid!", buffer)
			return PLUGIN_HANDLED
		}

		get_mapname(currentmap, 63)
	}
	while(equal(currentmap, buffer))



	console_print(id, "Ok, changing to %s...", buffer)
	server_cmd("changelevel ^"%s^"", buffer)

	return PLUGIN_HANDLED
}

public plugin_init() {
	register_plugin(PLUGINNAME, VERSION, AUTHOR)
	register_concmd("amx_listmaps", "amx_listmaps", 0, "[page #] - displays all valid maps in server")
	register_concmd("listmaps", "listmaps", 0, "[page #] - displays all valid maps in server")
	register_concmd("amx_mapcycle", "mapcycle", ADMIN_CFG, "<file.txt> - specify target file to write all valid maps in random order to it, mapcycle style")
	register_concmd("amx_randommap", "randommap", ADMIN_MAP, "- changes to random map")

	//register_concmd("amx_mapsini","writemapsini",ADMIN_CFG,": writes all valid maps to maps.ini")

	new stdPageSize[4]
	num_to_str(STANDARDPAGESIZE, stdPageSize, 3)
	register_cvar("amx_mh_page", stdPageSize)
	/* Use this later?
	new basedir[32], workdir[64]
	get_localinfo( "amx_basedir", basedir , 31 )
	format( workdir, 63, "%s/maps.ini" , basedir )
	*/
	/*
	new MAPHANDLERDATAFILE[256] = "addons/amxmodx/configs/amx_maphandler.dat"
	new MAPSINIPATH[256] = "addons/amxmodx/configs/maps.ini"
	*/

	get_localinfo("amxx_datadir", MAPHANDLERDATAFILE, 255)
	format(MAPHANDLERDATAFILE, 255, "%s/%s", MAPHANDLERDATAFILE, DATAFILE)
	get_configsdir(MAPSINIPATH, 255)
	format(MAPSINIPATH, 255, "%s/maps.ini", MAPSINIPATH)
	get_configsdir(g_unwantedMapsFile, 255)
	format(g_unwantedMapsFile, 255, "%s/%s", g_unwantedMapsFile, UNWANTEDMAPSCFGFILE)
	get_configsdir(g_wantedMapsFile, 255)
	format(g_wantedMapsFile, 255, "%s/%s", g_wantedMapsFile, WANTEDMAPSCFGFILE)

	register_cvar(CVAR_MHINIFILE, MAPHANDLERDATAFILE, FCVAR_SPONLY)
	register_cvar("amx_mh_mapsini", MAPSINIPATH, FCVAR_SPONLY)

	inited = false

	new currentMap[64]
	get_mapname(currentMap, 63)
	log_amx("Starting map: %s", currentMap)
	server_print("[%s] Initializing...", PLUGINNAME)
	if (writemaps()) {
		inited = true
		writemapsini()
		server_print("[%s] ...done!", PLUGINNAME)
	}
	else
		server_print("[%s] ERROR - Failed initializing!", PLUGINNAME)
}