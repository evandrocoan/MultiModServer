// SuperHero Main Include File
// Version 1.2.0

#if defined _shero_included
  #endinput
#endif
#define _shero_included

#pragma reqlib "SuperHero Core"
#if !defined AMXMODX_NOAUTOLOAD
  #pragma loadlib "SuperHero Core"
#endif

//Default includes used for shero
#include <amxmodx>
#include <fakemeta>
#include <hamsandwich>
#include <fun>
#include <csx>
#include <cstrike>
#include <superheroconst>

#if defined SH_BACKCOMPAT
  #include <engine>
#endif

//----------------------------------------------------------------------------------------------
// IMPORTANT FUNCTIONS - WHAT EVENTS CAN THE SUPERHEROES REGISTER FOR?
//----------------------------------------------------------------------------------------------


/**************************
 *        FORWARDS        *
 **************************/

/**
 * Called when a hero is added or dropped.
 * See superheroconst.inc for mode types.
 *
 * @param id			The index of the client.
 * @param heroID		The index of the hero.
 * @param mode			The heroID is being added or dropped.
 * @noreturn
 */
forward sh_hero_init(id, heroID, mode);

/**
 * Called when a +/-power is executed.
 * See superheroconst.inc for key types.
 *
 * @param id			The index of the client.
 * @param heroID		The index of the hero.
 * @param key			The heroID power key function, key down or key up.
 * @noreturn
 */
forward sh_hero_key(id, heroID, key);

/**
 * Called post player spawn.
 *
 * @param id			The index of the client.
 * @param bool:newRound		True if client spawned because of a new round, else false.
 * @noreturn
 */
forward sh_client_spawn(id, bool:newRound);

/**
 * Called whenever a client dies.
 * Death from sh_extra_damage will send correct info into this forward.
 *
 * @param victim		The index of the victim.
 * @param attacker		The index of the attacker.
 * @param headshot		Equals 1 if death is by a headshot else 0.
 * @param wpnDescription	Name of the weapon that killed the victim.
 * @noreturn
 */
forward sh_client_death(victim, attacker, headshot, const wpnDescription[]);

/**
 * Called every new round (start of freezetime).
 *
 * @noreturn
 */
forward sh_round_new();

/**
 * Called at the approximate time that a round is started.
 * (0.1 seconds after the end of freezetime).
 *
 * @noreturn
 */
forward sh_round_start();

/**
 * Called at the end of every round (and on sv_restart).
 *
 * @noreturn
 */
forward sh_round_end();


/**************************
 *        NATIVES         *
 **************************/

/**
 * Whether or not there is a game in progress.
 * In round is between end of freezetime and end of round.
 *
 * @return		True if game is in round, false otherwise.
 */
native bool:sh_is_inround();

/**
 * Returns current freezetime status (new round to round start).
 * Freezetime is between the start and end mp_freezetime time.
 *
 * @return		True if game is in freezetime, false otherwise.
 */
native bool:sh_is_freezetime();

/**
 * Returns server's max level.
 *
 * @note		The earliest this is guaranteed to be accurate is during plugin_cfg(). It needs
 *				the max level to be properly set or it will return 0.
 *
 * @return		The max number of levels of the server.
 */
native sh_get_num_lvls();

/**
 * Gets the XP required for the level.
 *
 * @param level		The level number to check.
 * @return		The XP needed for the level, else -1 if not a valid level.
 */
native sh_get_lvl_xp(level);

/**
 * Gets the client's current level.
 *
 * @param id		The index of the client.
 * @return		The current level of the client, else -1 if not a valid id.
 */
native sh_get_user_lvl(id);

/**
 * Sets the client's current level.
 *
 * @param id		The index of the client.
 * @param level		The level to set on the client.
 * @return		The level set on the client, else -1 if not a valid level.
 */
native sh_set_user_lvl(id, level);

/**
 * Gets the client's current XP.
 *
 * @param id		The index of the client.
 * @return		The current XP of the client.
 */
native sh_get_user_xp(id);

/**
 * Sets or Adds to the client's current XP.
 *
 * @param id		The index of the client.
 * @param xp		The xp to set/add on the client.
 * @param addtoxp	False to set client xp to the xp specified, true to add xp to client's current xp.
 * @return		1 if success, -1 if invalid client.
 */
native sh_set_user_xp(id, xp, bool:addtoxp = false);

/**
 * Adds to the client's current XP in the amount equal to if client killed victim.
 * As if client killed victim with sh_extra_damage, client recives the xp for that kill.
 *
 * @param id		The index of the client.
 * @param victim	The index of the client to calculate kill xp amount to add to id.
 * @param multiplier	Amount to multiply the kill xp by.
 * @noreturn
 */
native sh_add_kill_xp(id, victim, Float:multiplier = 1.0);

/**
 * Gets the client's max Health based on heroes client has.
 *
 * @param id		The index of the client.
 * @return		The max hero HP of the client, else 0 if invalid client.
 */
native sh_get_max_hp(id);

/**
 * Gets the client's max SuperHero Armor.
 *
 * @param id		The index of the client.
 * @return		The max hero AP of the client, else 0 if invalid client.
 */
native sh_get_max_ap(id);

//------------
// Hero Creation/Property Natives
//------------
// IMPORTANT: Make sure these are set AFTER cvars are registered

/**
 * Creates the hero and returns the heroID. (Required)
 *
 * @note	This must be the first property set as it returns the hero index to be used for the rest.
 *
 * @param heroName	The name of the Hero. (max 24 characters)
 * @param pcvarMinLevel	The pcvar value for minmum Level required CVAR for the hero.
 * @return		The hero's index, -1 on failure.
 */
native sh_create_hero(const heroName[], pcvarMinLevel);

/**
 * Sets the hero's power description and help info. (Required)
 *
 * @param heroID	The index of the hero.
 * @param powerInfo	The short info for the heroes power, used in the power select menu. (max 49 characters)
 * @param powerHelp	The long description for the heroes power, hud message displayed when users chooses the hero. (max 127 characters)
 * @noreturn
 */
native sh_set_hero_info(heroID, const powerInfo[] = "", const powerHelp[] = "");

/**
 * Sets the hero to use a +power bind key. (Optional)
 * Use only if hero requires a bound key.
 *
 * @param heroID	The index of the hero.
 * @noreturn
 */
native sh_set_hero_bind(heroID);

/**
 * Sets hero's shield restriction status. (Optional)
 *
 * @note		Set this on heroes that give weapons to avoid invisible shield bug.
 *
 * @param heroID	The index of the hero.
 * @param restricted	Set true to restict hero from allowing shield use, otherwise false.
 * @noreturn
 */
native sh_set_hero_shield(heroID, bool:restricted = false);

/**
 * Sets hero's max Health and Armor. (Optional)
 * Health and Armor do not stack, values from heroes are compared and greatest is applied.
 *
 * @note		If you only want to set one of the values, set the other to 0 or underscore "_" to use the default set value of 0.
 *
 * @param heroID	The index of the hero.
 * @param pcvarHealth	The pcvar value for maximum Health CVAR for the hero, CVAR values below 100 are ignored.
 * @param pcvarArmor	The pcvar value for maximum Armor CVAR for the hero.
 * @noreturn
 */
native sh_set_hero_hpap(heroID, pcvarHealth = 0, pcvarArmor = 0);

/**
 * Sets hero's max speed dependent on currently held weapon. (Optional)
 * Speeds do not stack, values from heroes are compared and greatest is applied.
 * weapons[] is an array of weapons this speed is good for, check CSW_ constants for weapon values.
 * {29, 30} would equal the CSW_ weapon constants corresponding to {CSW_KNIFE, CSW_P90}, etc... (see amxconst.inc)
 *
 * @note		This setting does not effect speed of sniper rifles when scoped.
 *				Max possible running speed is 2000, limited by half-life.
 *				Clients are also limited by cl_***speed client cvars defaulted to 400.
 *				Scout is the fastest default weapon at 260 and the other 3 snipers slowest at 150 when scoped.
 *
 * @param heroID	The index of the hero.
 * @param pcvarSpeed	The pcvar value for maximum Speed CVAR for the hero.
 * @param weapons	Array of weapon CSW_ constant values to set speed for, 0 is for all weapons.
 * @param numofwpns	The size of the weapons array, this MUST be passed in CORRECTLY!
 * @noreturn
 */
native sh_set_hero_speed(heroID, pcvarSpeed, const weapons[] = {0}, numofwpns = 1);

/**
 * Sets hero's min gravity dependent on currently held weapon. (Optional)
 * Gravities do not stack, values from heroes are compared and lowest is applied.
 * weapons[] is an array of weapons this gravity is good for, check CSW_ constants for weapon values.
 * {29, 30} would equal the CSW_ weapon constants corresponding to {CSW_KNIFE, CSW_P90}, etc... (see amxconst.inc)
 *
 * @note		A Gravity value 0.0 or below is ignored, 1.0 is normal gravity (800).
 *				***Weapon based gravity is not implemented yet. Maybe in next version, undecided.***
 *
 * @param heroID	The index of the hero.
 * @param pcvarGravity	The pcvar value for minimum Gravity CVAR for the hero.
 * @param weapons	Array of weapon CSW_ constant values to set gravity for, 0 is for all weapons.
 * @param numofwpns	The size of the weapons array, this MUST be passed in CORRECTLY!
 * @noreturn
 */
native sh_set_hero_grav(heroID, pcvarGravity, const weapons[] = {0}, numofwpns = 1);


/**
 * Sets hero's damage multiplier for the specified cs/cz weapon. (Optional)
 * Multipliers do not stack, values from user's heroes are compared and greatest is applied.
 * If multiple weapons required, native must be called separately for each weapon.
 *
 * @note		A Multiplier value of 1.0 or below is ignored.
 *				Multiplier is applied before armor reduces damage.
 *
 * @param heroID	The index of the hero.
 * @param pcvarSpeed	The pcvar value of the damage multiplier CVAR for the specified weaponID.
 * @param weaponID	The CSW_ constant of the weapon to set damage multiplier for, 0 is for all weapons. (see amxconst.inc)
 * @noreturn
 */
native sh_set_hero_dmgmult(heroID, pcvarWpnMult, const weaponID = 0);

//------------

/**
 * Forces client to drop weapon if they have it in inventory.
 *
 * @param id		The index of the client.
 * @param weaponID	The CSW_ index of the weapon. (see amxconst.inc)
 * @param remove	Set True to remove the weapon from world on drop, otherwise False to drop it like normal.
 * @noreturn
 */
native sh_drop_weapon(id, weaponID, bool:remove = false);

/**
 * Gives client a weapon.
 *
 * @note		This can be overridden by server using shweapon.cfg.
 *				If giving a primary weapon set sh_set_hero_shield() in hero to avoid invisible shield bug.
 *
 * @param id		The index of the client.
 * @param weaponID	The CSW_ index of the weapon. (see amxconst.inc)
 * @param switchTo	Set True to force client to switch to given weapon, otherwise False.
 * @noreturn
 */
native sh_give_weapon(id, weaponID, bool:switchTo = false);

/**
 * Gives client an item. (Use sh_give_weapon for better weapon_ handling)
 *
 * @note		Weapons can be overridden by server using shweapon.cfg.
 *				If giving a primary weapon set sh_set_hero_shield() in hero to avoid invisible shield bug.
 *
 * @param id		The index of the client.
 * @param itemName	The "item_*", "ammo_*", or "weapon_*" name of the desired item.
 * @param switchTo	Set True to force client to switch to given item if it's a weapon, otherwise False.
 * @noreturn
 */
native sh_give_item(id, const itemName[], bool:switchTo = false);

/**
 * Sets ammo reload method.
 *
 * @note		You are responsible for when this is called, usually when clip is empty.
 *
 * @param id		The index of the client.
 * @param mode		The mode	0 - follow server sh_reloadmode CVAR
 *					1 - continuous shooting, no reload
 *					2 - fill the backpack (must reload)
 *					3 - drop the gun and get a new one with full clip
 * @noreturn
 */
native sh_reload_ammo(id, mode = 0);

/**
 * Cause non-default extra damage.
 * Use this for non-default damage to correctly send damage messages and handle XP.
 *
 * @note		Set dmgFFmsg to false for looping extra damage, to avoid team attack chat spam.
 *				The default dmgOrigin of {0,0,0} will use attacker as the damage direction.
 *				Victim is unaffected if victim has godmode (this includes insta kill dmgMode).
 *
 * @param victim		The index of the victim.
 * @param attacker		The index of the attacker.
 * @param damage		Value of damage to cause, see dmgMode for effect on victim.
 * @param wpnDescription	Name of the weapon that causes the damage.
 * @param headshot		Set 1 if damage is a headshot else 0.
 * @param dmgMode		Type of damage, how victim is effected by damage value. See superheroconst.inc for types and explanations.
 * @param dmgStun		Set True to emulate damage stun on victim, otherwise False. (currently only sets horizontal velocity to 0)
 * @param dmgFFmsg		Set True to show friendly fire chat message "John Doe attacked a teammate", otherwise False.
 * @param dmgOrigin		Origin of damage bits direction (red flash indicators).
 * @noreturn
 */
native sh_extra_damage(victim, attacker, damage, const wpnDescription[], headshot = 0, dmgMode = SH_DMG_MULT, bool:dmgStun = false, bool:dmgFFmsg = true, const Float:dmgOrigin[3] = {0.0,0.0,0.0});

/**
 * Speed stuns client for time specified. Bind powers are not usable when stunned.
 *
 * @note		Does not combine time, the highest time will override.
 *
 * @param id		The index of the client.
 * @param howLong	The length of time in seconds the stun lasts.
 * @param speed		The speed of the client when stunned.
 * @noreturn
 */
native sh_set_stun(id, Float:howLong, Float:speed = 1.0);

/**
 * Returns a clients speed stun status.
 *
 * @param id		The index of the client.
 * @return		Returns 1 if client is in a stun, otherwise 0.
 */
native sh_get_stun(id);

/**
 * Sets godmode on client for time specified.
 *
 * @note		Does not combine time, the highest time will override.
 *				Client will sh glow blue {0,0,128} to indicate godmode. (This may be removed in a future version)
 *
 * @param id		The index of the client.
 * @param howLong	The length of time in seconds godmode lasts.
 * @noreturn
 */
native sh_set_godmode(id, Float:howLong);

/**
 * Gets hero's index.
 *
 * @param heroName	The name of the hero. (name must be exact spelling and case tense)
 * @return		Returns hero's index, -1 on failure
 */
native sh_get_hero_id(const heroName[]);

/**
 * Checks if the client has the hero.
 *
 * @param id		The index of the client.
 * @param heroID	The index of the hero.
 * @return		Returns 1 if client has hero, otherwise 0.
 */
native sh_user_has_hero(id, heroID);

/**
 * Reset client's max speed according to heroes they have.
 * Useful incase a temporary value was set.
 *
 * @param id		The index of the client.
 * @noreturn
 */
native sh_reset_max_speed(id);

/**
 * Reset client's min gravity according to heroes they have.
 * Useful incase a temporary value was set.
 *
 * @param id		The index of the client.
 * @noreturn
 */
native sh_reset_min_gravity(id);

/**
 * Sends a chat message thru core to append colored [SH] to front of message.
 * If heroID is supplied hero's name will be colored in parentheses ie "[SH](Batman) message displayed here"
 *
 * @note		Max characters for message without heroID supplied is 186.
 * 				Max characters for message with heroID supplied is
 * 				between 183 and 160 depending on size of hero's name.
 *
 * @param id		The index of the client.
 * @param heroID	The index of the hero, appends hero name to message. Set -1 to not append a hero name.
 * @param message	The chat message itself.
 * @noreturn
 */
native sh_chat_message(id, heroID = -1, const message[], any:...);

/**
 * Pass messages for debugging or set level to 0 and will always print message to log.
 *
 * @note		Adds "DEBUG: " to begining of message, may confuse some users if not an error.
 *
 * @param id		The index of the client.
 * @param level		The sh_debug_messages CVAR level to show the message at.
 * @param message	The message itself.
 * @noreturn
 */
native sh_debug_message(id, level, const message[],  any:...);


/**************************
 *         STOCKS         *
 **************************/

/**
 * Checks if SuperHero is currently on or off.
 *
 * @return		Returns true if Shmod is active, otherwise false.
 */
stock bool:sh_is_active()
{
	static sv_superheros;

	if ( !sv_superheros ) {
		sv_superheros = get_cvar_pointer("sv_superheros");
	}

	return (sv_superheros ? (get_pcvar_num(sv_superheros) ? true : false) : false);
}

/**
 * Checks if friendly fire is currently on or off.
 *
 * @return		Returns true if friendly fire is on, otherwise false.
 */
stock bool:sh_friendlyfire_on()
{
	static mp_friendlyfire;

	if ( !mp_friendlyfire ) {
		mp_friendlyfire = get_cvar_pointer("mp_friendlyfire");
	}

	return (get_pcvar_num(mp_friendlyfire) ? true : false);
}

/**
 * Checks max players setting of server, better then using SH_MAXSLOTS most times.
 *
 * @return		Returns max players of server.
 */
stock sh_maxplayers()
{
	static maxplayers;

	if ( !maxplayers )
		maxplayers = get_maxplayers();

	return maxplayers;
}

/**
 * Plays sound to inform the client they can not comply with the current action.
 *
 * @param id		The index of the client.
 * @noreturn
 */
stock sh_sound_deny(id)
{
	// gSoundDeny precached by core
	client_cmd(id, "spk %s", gSoundDeny);
}

/**
 * Forces client to switch to specified weapon if they have the weapon.
 *
 * @param id		The index of the client.
 * @param weaponID	The CSW_ index of the weapon. (see amxconst.inc)
 * @noreturn
 */
stock sh_switch_weapon(id, weaponID)
{
	if ( weaponID < CSW_P228 || weaponID > CSW_P90 ) return;

	if ( user_has_weapon(id, weaponID) ) {
		static weaponName[32];
		get_weaponname(weaponID, weaponName, charsmax(weaponName));
		engclient_cmd(id, weaponName);
	}
}

/**
 * Creates a screen fade on the client.
 *
 * @param id		The index of the client.
 * @param fadeTime	The time in seconds the fade lasts.
 * @param holdTime	The time in seconds the fade is held.
 * @param red		The red rgb color value of the fade. (0-255)
 * @param green		The green rgb color value of the fade. (0-255)
 * @param blue		The blue rgb color value of the fade. (0-255)
 * @param alpha		The alpha transparency value of the fade. (0-255)
 * @param type		The type of fade. (see superheroconst.inc)
 * @noreturn
 */
stock sh_screen_fade(id, Float:fadeTime, Float:holdTime, red, green, blue, alpha, type = SH_FFADE_IN)
{
	static msgScreenFade;

	if ( !msgScreenFade ) {
		msgScreenFade = get_user_msgid("ScreenFade");
	}

	// Check unsigned short range
	new fade, hold;
	fade = clamp(floatround(fadeTime * float(1<<12)), 0, 0xFFFF);
	hold = clamp(floatround(holdTime * float(1<<12)), 0, 0xFFFF);

	message_begin(MSG_ONE_UNRELIABLE, msgScreenFade, _, id);
	write_short(fade);	// fade lasts this long duration
	write_short(hold);	// fade lasts this long hold time
	write_short(type);	// fade type (in / out)
	write_byte(red);	// fade red
	write_byte(green);	// fade green
	write_byte(blue);	// fade blue
	write_byte(alpha);	// fade alpha
	message_end();
}

/**
 * Creates a screen shake on the client.
 *
 * @param id		The index of the client.
 * @param amplitude	The amount of displacement of the shake.
 * @param duration	The period of time of the shake.
 * @param frequency	The rate at which displacement of the shake is repeated.
 * @noreturn
 */
stock sh_screen_shake(id, Float:amplitude, Float:duration, Float:frequency)
{
	static msgScreenShake;

	if ( !msgScreenShake ) {
		msgScreenShake = get_user_msgid("ScreenShake");
	}

	// Check unsigned short range
	new amp, dura, freq;
	amp = clamp(floatround(amplitude * float(1<<12)), 0, 0xFFFF);
	dura = clamp(floatround(duration * float(1<<12)), 0, 0xFFFF);
	freq = clamp(floatround(frequency * float(1<<8)), 0, 0xFFFF);

	message_begin(MSG_ONE_UNRELIABLE, msgScreenShake, _, id);
	write_short(amp);	// amplitude
	write_short(dura);	// duration
	write_short(freq);	// frequency
	message_end();
}

/**
 * Set a render on an entity.
 * To set a typical glow set fx to kRenderFxGlowShell, the alpha amount of 16 is preferred.
 * To reset a glow or render on a client use sh_set_rendering(id).
 *
 * @note		For client's, lower visiblity takes preference unless it's a render reset.
 *
 * @param entity	The index of the entity.
 * @param r		The red color rgb value of the render. (0-255)
 * @param g		The green color rgb value of the render. (0-255)
 * @param b		The blue color rgb value of the render. (0-255)
 * @param amount	The alpha transparency value of the render. (0-255)
 * @param fx		The fx type of the render. (see amxconst.inc)
 * @param render	The type of render. (see amxconst.inc)
 * @return		Returns 1 on success, 0 on failure.
 */
stock sh_set_rendering(entity, r = 255, g = 255, b = 255, amount = 16, fx = kRenderFxNone, render = kRenderNormal)
{
	if ( !pev_valid(entity) ) return 0;

	new Float:alpha = float(amount);

	// This check is only to favor invisibility of a player over any other render expect a reset
	if ( entity <= sh_maxplayers() ) {

		// If client is in an alpha render do we need to block this render setting.
		if ( pev(entity, pev_rendermode) == kRenderTransAlpha ) {

			// If just resetting render allow it to reset
			if ( r != 255 || g != 255 || b != 255 || amount != 16 || fx != kRenderFxNone || render != kRenderNormal ) {

				// Skip setting any other render type, allow user to stay in alpha render
				if ( render != kRenderTransAlpha ) return 0;

				new Float:currentAlpha;
				pev(entity, pev_renderamt, currentAlpha);

				// Only set alpha render if equal or less visible (equal to allow color changes etc.)
				if ( alpha > currentAlpha ) return 0;
			}
		}
	}

	new Float:renderColor[3];
	renderColor[0] = float(r);
	renderColor[1] = float(g);
	renderColor[2] = float(b);

	set_pev(entity, pev_renderfx, fx);
	set_pev(entity, pev_rendercolor, renderColor);
	set_pev(entity, pev_rendermode, render);
	set_pev(entity, pev_renderamt, alpha);

	return 1;
}

/**
 * Add to client's current health, up to a max limit.
 *
 * @param id		The index of the client.
 * @param hitPoints	The amount of health to add.
 * @param maxHealth	The maxium possible health to add up to, set 0 to use max from client's heroes.
 * @return		The amount of health added, 0 on failure.
 */
stock sh_add_hp(id, hitPoints, maxHealth = 0)
{
	if ( hitPoints == 0 ) return 0;

	if ( maxHealth == 0 ) maxHealth = sh_get_max_hp(id);

	new currentHealth = get_user_health(id);

	if ( currentHealth < maxHealth ) {
		new newHealth = min((currentHealth + hitPoints), maxHealth);
		set_user_health(id, newHealth);
		return newHealth - currentHealth;
	}

	return 0;
}

/**
 * Add to client's current armor, up to a max limit.
 *
 * @note	Armor power does not set til approx 0.6 seconds after spawn,
 *			do not regen armor during that time to allow sh to properly set AP.
 *
 * @param id		The index of the client.
 * @param armorPoints	The amount of armor to add.
 * @param maxArmor	The maxium possible armor to add up to, set 0 to use max from client's heroes.
 * @return		The amount of health added, 0 on failure.
 */
stock sh_add_ap(id, armorPoints, maxArmor = 0)
{
	if ( armorPoints == 0 ) return 0;

	if ( maxArmor == 0 ) maxArmor = sh_get_max_ap(id);

	new CsArmorType:armorType;
	new currentArmor = cs_get_user_armor(id, armorType);

	if ( currentArmor < maxArmor ) {
		if ( !currentArmor ) armorType = CS_ARMOR_VESTHELM;

		new newArmor = min((currentArmor + armorPoints), maxArmor);
		cs_set_user_armor(id, newArmor, armorType);
		return newArmor - currentArmor;
	}

	return 0;
}

/**
 * Returns server flags for sh_blockvip cvar, can be used in heroes for custom VIP blocks.
 * (see superheroconst.inc for flag types)
 *
 * @note	You are still responsible to check if user is vip, use cs_get_user_vip(id).
 * 			example usage: if(cs_get_user_vip(id) && sh_vip_flags()&VIP_BLOCK_CUSTOM) {//do something}
 *
 * @return	The flags currently set.
 */
stock sh_vip_flags()
{
	static sh_blockvip;

	if ( !sh_blockvip ) {
		sh_blockvip = get_cvar_pointer("sh_blockvip");
	}

	if ( !sh_blockvip ) return 0;

	static temp[9];
	get_pcvar_string(sh_blockvip, temp, charsmax(temp));

	return read_flags(temp);
}

/**
 * Checks a hull to see if it is empty.
 * Good for checking if a client is or can be stuck at an origin.
 *
 * @note		While not very useful hitent is passed byref.
 * 				hitent is the index of ent in hull if any was found, otherwise 0 is passed.
 *
 * @param id		The index of the client that is ignored in the hull that is checked.
 * @param origin	The origin of the hull to check.
 * @param hullType	The type of hull to check, HULL_HEAD for crouching or HULL_HUMAN for standing. (see hlsdk_const.inc)
 * @return		True if hull is empty, otherwise false.
 */
stock bool:sh_hull_vacant(id, const Float:origin[3], hullType = HULL_HEAD, &hitent = 0)
{
	// Thanks to VEN for his is_hull_vacant stock which this is based on

	// Find an open space and ignore id in that space
	engfunc(EngFunc_TraceHull, origin, origin, 0, hullType, id, 0);

	// byref index of what was hit, multiple things may be in hull so may not return what you expect
	hitent = get_tr2(0, TraceResult:TR_pHit);

	// Is the origin's hull empty for the hull type
	if ( !get_tr2(0, TraceResult:TR_StartSolid) && !get_tr2(0, TraceResult:TR_AllSolid) && get_tr2(0, TraceResult:TR_InOpen) )
		return true;

	return false;
}

/**
 * Gets a velocity to or from an origin.
 * Usually used for movement of created entities or to push players away from an explosion.
 *
 * @note		+/- speed is limited by servers sv_maxvelocity setting (default 2000)
 *				For explosions, set inital[2] a bit above final[2] to give a bit of a upward lift
 *
 * @param initial	The start origin. Generally an entity's origin on which to set velocity on.
 * @param final		The end origin. Generally the point where velocity is set to or from.
 * @param speed		Speed of the velocity to set:
 *					- Positive value will set velocity TO final vector.
 *					- Negative value will set velocity FROM final vector.
 * @param velocity	The return velocity. If a velocity is passed in, the return will add to it.
 */
stock sh_get_velocity(const Float:initial[3], const Float:final[3], Float:speed, Float:velocity[3])
{
	// Lets make sure we are within range
	static sv_maxvelocity;

	if ( !sv_maxvelocity ) {
		sv_maxvelocity = get_cvar_pointer("sv_maxvelocity");
	}

	new Float:maxSpeed = get_pcvar_float(sv_maxvelocity);

	// Time = Distance / Speed
	new Float:fTime = vector_distance(initial, final) / floatclamp(speed, -maxSpeed, maxSpeed);

	// Velocity = Distance / Time
	velocity[0] += (final[0] - initial[0]) / fTime;
	velocity[1] += (final[1] - initial[1]) / fTime;
	velocity[2] += (final[2] - initial[2]) / fTime;
}

//------------
// Simple Functions to Help with Power Cooldowns.
//------------
// NOTE: The core will cancel cooldown task on a new spawn for safety, but
//	   the hero itself must reset the gPlayerInCooldown variable to false.

/**
 * Global variable for cooldown status.
 *
 * @noreturn
 */
stock bool:gPlayerInCooldown[SH_MAXSLOTS+1];

/**
 * Sets a cooldown in a hero.
 *
 * @param id		The index of the client.
 * @param secs		The time in seconds the cooldown lasts before it is removed.
 * @noreturn
 */
stock sh_set_cooldown(id, Float:secs)
{
	gPlayerInCooldown[id] = true;

	set_task(secs, "sh_end_cooldown", id+SH_COOLDOWN_TASKID);

	sh_debug_message(id, 5, "Cooldown Timer Started");
}

/**
 * Ends the cooldown in a hero.
 * This must be a public function since it is called by a task, rest can be stocks.
 *
 * @note		Called by cooldown through a task, so you do not need to call this.
 * 				However, it can be used to remove a cooldown earlier than task called to end it.
 *
 * @param id		The index of the client + SH_COOLDOWN_TASKID.
 * @noreturn
 */
public sh_end_cooldown(id)
{
	// This is only here incase user wants to manually end cooldown
	// before task is over, does not matter if task is not going on.
	remove_task(id);

	id -= SH_COOLDOWN_TASKID;
	gPlayerInCooldown[id] = false;

	sh_debug_message(id, 5, "Cooldown Timer Ended");
}

//------------
// Weapon Look Up Tables, faster then a switch statements.
//------------

/**
 * Returns max backpack ammo of weapon.
 *
 * @note		Stock created in superheroconst.inc, explained here for usage reference.
 *
 * @param weaponID	The CSW_ index of the weapon. (see amxconst.inc)
 * @return		The weapon's max backpack ammo.
 */
//sh_get_max_bpammo(weaponID)

/**
 * Returns max clip ammo of weapon.
 *
 * @note		Stock created in superheroconst.inc, explained here for usage reference.
 *
 * @param weaponID	The CSW_ index of the weapon. (see amxconst.inc)
 * @return		The weapon's max clip ammo.
 */
//sh_get_max_clipammo(weaponID)

/**
 * Returns weapon slot of weapon.
 * Useful to run code only on guns not on grenades, etc.
 *
 * @note		Stock created in superheroconst.inc, explained here for usage reference.
 *
 * @param weaponID	The CSW_ index of the weapon. (see amxconst.inc)
 * @return		The weapon slot.
 */
//sh_get_weapon_slot(weaponID)

/**
 * Gets the default speed of a weapon.
 *
 * @param weaponID	The CSW_ index of the weapon. (see amxconst.inc)
 * @param zoomed	Set True if weapon speed while zoomed is wanted, otherwise False.
 * @return		The speed of the weapon.
 */
stock Float:sh_get_weapon_speed(weaponID, bool:zoomed = false)
{
	if ( zoomed ) {
		// Only the 4 sniper rifles actually have different speeds when zoomed
		// And 3 of those have the same speed so lets just use a switch for them.
		switch(weaponID) {
			case CSW_SCOUT: return 220.0;
			case CSW_SG550, CSW_AWP, CSW_G3SG1: return 150.0;
		}
	}

	return gWeaponSpeed[weaponID];
}

//------------
// Odd Stocks for core, not useful to most.
//------------

/**
 * Breaks a string into two parts, Left[] and Right[], keeping the quotes intact.
 *
 * @param text		The string to break.
 * @param Left		The string containing the first paramter broken.
 * @param leftLen	The size of the Left string.
 * @param Right		The string containing the rest after first parameter was broken off, not including the starting space. 
 * @param rightLen	The size of the Right string.
 * @return		Returns true upon completion.
 */
stock strbrkqt(const text[], Left[], leftLen, Right[], rightLen)
{
	// Breaks text[] into two parts, Left[], and Right[]
	// Left[] will contain the first parameter (either quoted or non-quoted)
	// Right[] contain the rest of the string after Left[], not including the space
	new bool:in_quotes = false;
	new bool:done_flag = false;
	new i, left_pos = 0;
	new textLen = strlen(text);

	for ( i = 0; i < textLen; i++) {

		if ( text[i] == '^"' && !done_flag ) {
			if ( in_quotes ) {
				done_flag = true;
				in_quotes = false;
			}
			else in_quotes = true;
		}
		else if ( isspace(text[i]) && !in_quotes ) {
			if ( left_pos > 0 ) {
				done_flag = true;
			}
		}
		else if ( !done_flag && left_pos <= leftLen ) {
			setc(Left[left_pos], 1, text[i]);
			left_pos++;
		}
		else if ( done_flag ) break;
	}

	Left[left_pos] = '^0';
	copy(Right, rightLen, text[i]);

	return true;
}

/**
 * Prints heapsize. This is ONLY used to debug runtime 3 errors.
 *
 * @note		Unused but keep incase it is needed for debugging.
 *
 * @noreturn
 */
stock print_heapsize()
{
	server_print("[SH] HeapSize: %i", heapspace());
}


//----------------------------------------------------------------------------------------------
// Below is for Backward compatibility layer only, please do not code with it any longer.
// You can test your code for compilance by commenting out SH_BACKCOMPAT in superheroconst.inc
// and compiling your hero. Then fix any compile errors with new functions above, below
// can be a reference.
//----------------------------------------------------------------------------------------------


#if defined SH_BACKCOMPAT


/**************************
 * BACKWARD COMPATIBILITY *
 **************************/

stock shCreateHero(const heroName[], const heroPower[], const heroHelp[], bool:requiresKeyEvents = false, const heroLevel[])
{
	new heroID = sh_create_hero(heroName, get_cvar_pointer(heroLevel));
	if ( heroID != -1 ) {
		sh_set_hero_info(heroID, heroPower, heroHelp);
		if ( requiresKeyEvents ) {
			sh_set_hero_bind(heroID);
		}
	}
	return heroID;
}

stock shSetShieldRestrict(const heroName[])
{
	new heroID = sh_get_hero_id(heroName);

	if ( heroID != -1 ) {
		sh_set_hero_shield(heroID, true);
	}
}

stock shSetMaxHealth(const heroName[], const heroHPCVAR[])
{
	new heroID = sh_get_hero_id(heroName);

	if ( heroID != -1 ) {
		sh_set_hero_hpap(heroID, get_cvar_pointer(heroHPCVAR), _);
	}
}

stock shSetMaxArmor(const heroName[], const heroArmorCVAR[])
{
	new heroID = sh_get_hero_id(heroName);

	if ( heroID != -1 ) {
		sh_set_hero_hpap(heroID, _, get_cvar_pointer(heroArmorCVAR));
	}
}

stock shSetMaxSpeed(const heroName[], const heroSpeedCVAR[], weaponString[])
{
	new heroID = sh_get_hero_id(heroName);

	if ( heroID != -1 ) {
		//Convert old sh weapon string into an array of weapons
		new number[3], weaponArray[33], i, x = 0;
		for ( i = 0; weaponString[i] != '^0'; i++ ) {
			switch(weaponString[i]) {
				case '[': continue;

				case ']': {
					//Setup array
					weaponArray[x] = str_to_num(number);
					++x;
					number[0] = '^0';
				}

				default: {
					//Single out weapon number
					add(number, charsmax(number), weaponString[i]);
				}
			}
		}

		sh_set_hero_speed(heroID, get_cvar_pointer(heroSpeedCVAR), weaponArray , x);
	}
}

stock shSetMinGravity(const heroName[], const heroGravityCVAR[])
{
	new heroID = sh_get_hero_id(heroName);

	if ( heroID != -1 ) {
		sh_set_hero_grav(heroID, get_cvar_pointer(heroGravityCVAR));
	}
}

//stock playSoundDenySelect(id)
#define playSoundDenySelect sh_sound_deny

//stock shAddXP(id, victim, Float:multiplier = 1.0 )
#define shAddXP sh_add_kill_xp

//stock shModActive()
#define shModActive sh_is_active

//stock shGetNumLevels()
#define shGetNumLevels sh_get_num_lvls

//stock hasRoundStarted()
#define hasRoundStarted() !sh_is_freezetime()

//stock shReloadAmmo(id, dropwpn = 0)
#define shReloadAmmo sh_reload_ammo

//stock shExtraDamage(id, attacker, damage, weaponDescription[], headshot = 0 )
#define shExtraDamage sh_extra_damage

#define getMaxClipAmmo(%1) gMaxClipAmmo[%1]
#define getMaxBPAmmo(%1) gMaxBPAmmo[%1]

//stock shResetSpeed(id)
#define shResetSpeed sh_reset_max_speed

//stock shSetGravityPower(id)
#define shSetGravityPower sh_reset_min_gravity

//stock shGiveWeapon(id, const weaponName[], bool:switchTo = false)
#define shGiveWeapon sh_give_item

//stock shGiveWeaponID(id, weaponID, bool:switchTo = false)
#define shGiveWeaponID sh_give_weapon

//stock shSwitchWeaponID(id, weaponID)
stock shSwitchWeaponID(id, weaponID)
{
	if ( !is_user_alive(id) ) return;

	sh_switch_weapon(id, weaponID);
}

//stock shOwnsWeaponID(id, weaponID)
#define shOwnsWeaponID user_has_weapon

//stock shOwnsWeapon(id, weaponName[])
#define shOwnsWeapon(%1, %2) user_has_weapon(%1, get_weaponid(%2))

//stock shUnglow(id)
#define shUnglow sh_set_rendering

//stock shAddHPs(id, hitPoints, maxHealth = 100)
stock shAddHPs(id, hitPoints, maxHealth = 100)
{
	if ( !sh_is_active() ) return;

	sh_add_hp(id, hitPoints, maxHealth);
}

//stock shStun(id, secs)
stock shStun(id, secs)
{
	sh_set_stun(id, float(secs));
}

//stock shSetGodMode(id, secs)
stock shSetGodMode(id, secs)
{
	sh_set_godmode(id, float(secs));
}

//stock debugMessage(const message[], id = 0, level = 1)
stock debugMessage(const message[], id = 0, level = 1)
{
	sh_debug_message(id, level, message);
}

//stock shGlow(id, r, g, b)
stock shGlow(id, r, g, b)
{
	sh_set_rendering(id, r, g, b, 16, kRenderFxGlowShell);
}

//stock sh_setScreenFlash(id, red, green, blue, decisecs, alpha)
//stock setScreenFlash(id, red, green, blue, decisecs, alpha)
#define sh_setScreenFlash setScreenFlash
stock setScreenFlash(id, red, green, blue, decisecs, alpha)
{
	if ( !is_user_connected(id) ) return;

	sh_screen_fade(id, float(decisecs)/10.0, float(decisecs)/20.0, red, green, blue, alpha);
}

//stock sh_screenShake(id, amplitude, duration, frequency)
//stock setScreenShake(id, amplitude, duration, frequency)
#define sh_screenShake setScreenShake
stock setScreenShake(id, amplitude, duration, frequency)
{
	if ( !is_user_connected(id) ) return;

	sh_screen_shake(id, float(amplitude)/10.0, float(duration)/10.0, float(frequency)/10.0);
}

//cooldown stuff
#define gPlayerUltimateUsed gPlayerInCooldown
#define ultimateTimer sh_set_cooldown
#define enableUltimate sh_end_cooldown

stock shRegKeyUp(const heroName[], const keyUpFunction[])
{
	server_cmd("sh_regKeyUp ^"%s^" ^"%s^"", heroName, keyUpFunction);
}

stock shRegKeyDown(const heroName[], const keyDownFunction[])
{
	server_cmd("sh_regKeyDown ^"%s^" ^"%s^"", heroName, keyDownFunction);
}

stock shRegLevels(const heroName[], const levelFunction[])
{
	server_cmd("sh_regLevels ^"%s^" ^"%s^"", heroName, levelFunction);
}

stock shRegMaxHealth(const heroName[], const healthFunction[])
{
	server_cmd("sh_regMaxHealth ^"%s^" ^"%s^"", heroName, healthFunction);
}

stock shRegHeroInit(const heroName[], const initFunction[])
{
	server_cmd("sh_regInit ^"%s^" ^"%s^"", heroName, initFunction);
}

//These stocks should now be ignored since removal upon hero drop is done in core
//Kept to allow heroes to compile without error
stock shResetShield(id)
{
	return id;
}
stock shRemHealthPower(id)
{
	return id;
}

stock shRemArmorPower(id)
{
	return id;
}

stock shRemGravityPower(id)
{
	return id;
}

stock shRemSpeedPower(id)
{
	return id;
}

//This is pointless, kept for backward compat only
stock bool:isDebugOn()
{
	static sh_debug_messages;

	if ( !sh_debug_messages ) {
		sh_debug_messages = get_cvar_pointer("sh_debug_messages");
	}

	return (get_pcvar_num(sh_debug_messages) > 0 ? true : false);
}

//------------
// Depreciated stocks
//------------

//Now in amxmodx 1.80.
#define maxof floatmax
#define minof floatmin

//old cmath.inc port of sqroot no longer needed.
#define sqrt(%1) sqroot(%1)

//This stock was moved to core.
//Forcing old heroes to throw a compile error so that they are
//forced to update to sh_extra_damage for better compatibility.
//stock logKill(id, victim, const weaponDescription[])


#endif