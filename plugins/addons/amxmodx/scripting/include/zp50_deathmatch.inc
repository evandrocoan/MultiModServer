#if defined _zp50_deathmatch_included
  #endinput
#endif
#define _zp50_deathmatch_included

#include <zp50_core>


/**
 * Called before the deathmatch module respawns a player.
 * Returning PLUGIN_HANDLED will block respawn.
 *
 * @param id		Player index.
 */
forward zp_fw_deathmatch_respawn_pre(id)
