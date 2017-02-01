// SuperHero nVault Include File
// Version 1.2.0

//----------------------------------------------------------------------------------------------
// Abstract Methods that must be implemented by a save superhero include file...
//
// memoryTableWrite()
// loadXP(id, const savekey[32])
// cleanXP(clearAll = false)
//----------------------------------------------------------------------------------------------

#if defined _shsave_included || !defined SHCORE
	#endinput
#endif
#define _shsave_included

//Include the nvault file
#include <nvault>

//Global to save the vault handle
new gVaultHandle

//----------------------------------------------------------------------------------------------
saving_init()
{
	gVaultHandle = nvault_open("superhero")

	if ( gVaultHandle == INVALID_HANDLE ) {
		debugMsg(0, 0, "Error opening nVault file: superhero.vault")
	}
}
//----------------------------------------------------------------------------------------------
public memoryTableWrite()
{
	if ( !get_pcvar_num(sh_savexp) ) return

	debugMsg(0, 3, "Writing XP Data to nVault file")

	// Write Memory Table to File
	for ( new x = 1; x < gMemoryTableCount; x++ ) {
		if ( gMemoryTableKeys[x][0] != '^0' ) {
			writeData(x)
		}
		// Can even clear the MemoryKey - if a player is disconnected no reason to save again and again...
		gMemoryTableKeys[x][0] = '^0'
	}

	// No need to keep disconnected players around if this has been flushed...
	gMemoryTableCount = 33
}
//----------------------------------------------------------------------------------------------
writeData(id)
{
	// Formats Player Information and writes to file:
	// "name" XP USERFLAGS "SKILL1" "SKILL2" ...
	static data[1501]
	new heroIndex, len
	new powerCount = gMemoryTablePowers[id][0]

	data[0] = '^0'

	len += formatex(data[len], charsmax(data)-len, "^"%s^" %d %d", gMemoryTableNames[id], gMemoryTableXP[id], gMemoryTableFlags[id])

	for ( new x = 1; x <= powerCount && x <= gSuperHeroCount && len < charsmax(data); x++ ) {
		heroIndex = gMemoryTablePowers[id][x]
		if ( -1 < heroIndex < gSuperHeroCount ) {
			len += formatex(data[len], charsmax(data)-len, " ^"%s^"", gSuperHeros[heroIndex][hero])
		}
	}

	nvault_set(gVaultHandle, gMemoryTableKeys[id], data)

	if ( 0 < id <= SH_MAXSLOTS ) {
		gChangedHeroes[id] = false
	}
}
//----------------------------------------------------------------------------------------------
loadXP(id, const savekey[32])
{
	static Right[1501], temp
	Right[0] = '^0'

	if ( nvault_lookup(gVaultHandle, savekey, Right, charsmax(Right), temp) ) {
		// parseXP

		// "name" XP USERFLAGS "SKILL1" "SKILL2" ...
		new heroIndex, powerCount, maxPowers, playerLevel
		static Left[32]
		Left[0] = '^0'

		// Get the name out
		strbrkqt(Right, Left, charsmax(Left), Right, charsmax(Right))
		Left[0] = '^0'

		// Get the XP out and save it
		strbrkqt(Right, Left, charsmax(Left), Right, charsmax(Right))
		gPlayerXP[id] = str_to_num(Left)
		gPlayerLevel[id] = playerLevel = getPlayerLevel(id)
		setLevel(id, playerLevel)
		Left[0] = '^0'

		// Get the User Flags out and save them
		strbrkqt(Right, Left, charsmax(Left), Right, charsmax(Right))
		gPlayerFlags[id] = str_to_num(Left)

		// Now load in all the skills
		powerCount = 0
		maxPowers = min(get_pcvar_num(sh_maxpowers), SH_MAXLEVELS)

		while ( Right[0] != '^0' && powerCount < maxPowers ) {
			Left[0] = '^0'
			strbrkqt(Right, Left, charsmax(Left), Right, charsmax(Right))
			heroIndex = getHeroID(Left)
			if ( -1 < heroIndex < gSuperHeroCount ) {
				if ( getHeroLevel(heroIndex) <= playerLevel ) {
					gPlayerPowers[id][0] = ++powerCount
					gPlayerPowers[id][powerCount] = heroIndex
					initHero(id, heroIndex, SH_HERO_ADD)
				}
			}
		}
	}

	memoryTableUpdate(id)

	return true
}
//----------------------------------------------------------------------------------------------
cleanXP(bool:clearAll)
{
	if ( clearAll ) {
		nvault_prune(gVaultHandle, 0, 0)
	}
	else if ( get_pcvar_num(sh_savexp) ) {
		new xpSaveDays = get_pcvar_num(sh_xpsavedays)

		if ( xpSaveDays < 0 ) return

		nvault_prune(gVaultHandle, 0, get_systime() - (xpSaveDays * 24 * 3600))
	}
}
//----------------------------------------------------------------------------------------------
saving_end()
{
	//Close the vault to save all the data
	nvault_close(gVaultHandle)
}
//----------------------------------------------------------------------------------------------