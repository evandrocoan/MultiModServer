#if defined _ttt_included
	#endinput
#endif
#define _ttt_included

#include <ttt_const> 

#if AMXX_VERSION_NUM >= 175
    #pragma reqlib ttt
    #if !defined AMXMODX_NOAUTOLOAD
        #pragma loadlib ttt
    #endif
#else
    #pragma library ttt
#endif

/**
 * Sets players state.
 *
 * @param id			Player index.
 * @param PLAYER_STATE	New state, enum PLAYER_STATE.
 */
native ttt_set_specialstate(id, PLAYER_STATE);

/**
 * Returns special count.
 *
 * @param PLAYER_STATE	PLAYER_STATE enum.
 * @return				Number of specials.
 */
native ttt_get_specialcount(PLAYER_STATE);

/**
 * Returns roundtime.
 *
 * @return		Roundtime.
 */
native Float:ttt_get_roundtime();

/**
 * Sets/returns players data.
 *
 * @param id				Player index.
 * @param PLAYER_DATA		Enum PLAYER_DATA.
 * @param newvalue			New value to set.
 * @return					Data.
 */
native ttt_get_playerdata(id, PLAYER_DATA);
native ttt_set_playerdata(id, PLAYER_DATA, newvalue);

/**
 * Sets/returns game state.
 *
 * @param GLOBAL_INFO		Enum GLOBAL_INFO.
 * @param newvalue			New value to set.
 * @return					value.
 */
native ttt_get_globalinfo(GLOBAL_INFO);
native ttt_set_globalinfo(GLOBAL_INFO, newvalue);

/**
 * Sets/returns game winner. Also, ends round if still active.
 *
 * @param team			INNOCENT or TRAITOR.
 * @return				Game winner.
 */
native ttt_get_winner();
native ttt_set_winner(team);

/**
 * Adds item to Buymenu and returns id.
 *
 * @param name[]			Items name.
 * @param price				Items price.
 * @param team				Items team, INNOCENT = INNO + DET, SPECIAL = TRA + DET.
 * @return					Item id.
 */
native ttt_buymenu_add(const name[], const price, const team);

/**
 * Opens buy menu for player.
 *
 * @param owner				Players id.
 */
native ttt_buymenu_show(owner);

/**
 * Adds item to Backpack and returns id.
 *
 * @param owner				Players id.
 * @param name[]			Items name.
 * @return					Item id.
 */
native ttt_backpack_add(owner, name[]);

/**
 * Remove item from Backpack.
 *
 * @param owner				Players id.
 * @param itemid[]			Item id.
 * @return					something.
 */
native ttt_backpack_remove(owner, itemid);

/**
 * Opens backpack for player.
 *
 * @param owner				Players id.
 */
native ttt_backpack_show(owner);

/**
 * Gets/sets/clears players dead body data.
 *
 * @param id				Players id.
 * @param BODY_DATA			Enum BODY_DATA.
 * @param newvalue			New value to set.
 * @return					data.
 */
native ttt_get_bodydata(id, BODY_DATA);
native ttt_set_bodydata(id, BODY_DATA, newvalue);
native ttt_clear_bodydata(id);

/**
 * Setups item from backpack that will have DNA sample left on it, for example, Death Station and returns setupid.
 *
 * @param id				Items or players (dont know) id.
 * @param ent				Entity id.
 * @param time				Time before DNA decays.
 * @param owner				DNA Sample owner.
 * @param tracer			Detective who can see DNA.
 * @param active			Is DNA seeable.
 * @param name[]			Items name.
 * @return					setupid.
 */
native ttt_item_setup_add(id, ent, time, owner, tracer, active, name[]);

/**
 * Removes setuped item - DNA stop existing, I think.
 *
 * @param setupid			Setups id.
 */
native ttt_item_setup_remove(setupid);

/**
 * Updates/gets info about setup.
 *
 * @param setupid			Setups id.
 * @param array[]			For example, static data[SetupData].
 */
native ttt_item_setup_update(setupid, array[]);
native ttt_item_setup_get(setupid, array[]);

/**
 * Gets item name from item_id.
 *
 * @param item_id			Item id.
 * @param name[]			Items name.
 * @param charsmax			Items name size-1.
 * @return					name.
 */
native ttt_get_item_name(item_id, name[], charsmax);

/**
 * Gets item_id from item name.
 *
 * @param name[]			Items name.
 * @return					Item id.
 */
native ttt_get_item_id(name[]);

/**
 * Checks if selected entity is setuped for DNA tracking.
 *
 * @param ent				Entity id.
 * @return					True or false.
 */
native ttt_is_item_setup(ent);

/**
 * Logs your message to files.
 *
 * @param type				Enum LOG_MESSAGES.
 * @param msg[]				Your message.
 */
native ttt_logging(LOG_MESSAGES, msg[]);

/**
 * Register cvar to file.
 *
 * @param name[]				Cvar name.
 * @param string[]				Cvar value.
 * @param description[]			Cvar description.
 * @return						true/false.
 */
native ttt_register_cvar(name[], string[], description[]);

/**
 * Sets/gets player stats.
 *
 * @param id				Players id.
 * @param PLAYER_STATS		Enum PLAYER_STATS.
 * @param newvalue			New value to set.
 * @return					stat.
 */
native ttt_get_stats(id, PLAYER_STATS);
native ttt_set_stats(id, PLAYER_STATS, newvalue);

/**
 * Sets/gets player warnings.
 *
 * @param id				Player id.
 * @param array[]			Player warning array.
 * @return					true/false.
 */
native ttt_get_warnings(id, array[]);
native ttt_set_warnings(id, array[]);

/**
 * Sets/finds item as exception in karma reduction.
 *
 * @param item				Item id.
 * @return					true/false.
 */
native ttt_add_exception(item);
native ttt_find_exception(item);

/**
 * Adds command to commands menu.
 *
 * @param name[]			Commands name.
 * @return					Command id.
 */
native ttt_command_add(name[]);

/**
 * Called when player bought item.
 *
 * @param id				Players id.
 * @param item				Item id.
 * @param name[]			Item name.
 * @param price				Item price.
 */
forward ttt_item_selected(id, item, name[], price);

/**
 * Called when player uses item from Backpack.
 *
 * @param id				Players id.
 * @param item				Item id.
 * @param name[]			Item name.
 */
forward ttt_item_backpack(id, item, name[]);

/**
 * Called when game state changes.
 *
 * @param mode				Gamestate.
 */
forward ttt_gamemode(mode);

/**
 * Called when winner is set.
 *
 * @param winner			winner.
 */
forward ttt_winner(winner);

/**
 * Called when dead body is created.
 *
 * @param owner				Player id.
 * @param ent				Entity id.
 */
forward ttt_spawnbody(owner, ent);

/**
 * Called when player interacts with bomb.
 *
 * @param id				Player id.
 * @param status			BOMB_STATUS enum.
 * @param ent				Bomb entity.
 */
forward ttt_bomb_status(id, status, ent);

/**
 * Called when player choses command from menu.
 *
 * @param id				Players id.
 * @param itemid			Menu id.
 * @param name[]			Item name.
 */
forward ttt_command_selected(id, menuid, name[]);

/**
 * Called TTT config files has been executed.
 */
forward ttt_plugin_cfg();

#include <ttt_stocks>