#if defined _cs_player_models_api_included
  #endinput
#endif
#define _cs_player_models_api_included

#if AMXX_VERSION_NUM >= 175
	#pragma reqlib cs_player_models_api
	#if !defined AMXMODX_NOAUTOLOAD
		#pragma loadlib cs_player_models_api
	#endif
#else
	#pragma library cs_player_models_api
#endif

/**
 * Sets a custom player model.
 *
 * @param id			Player index.
 * @param model			Custom model's short name.
 */
native cs_set_player_model(id, const model[])

/**
 * Restores CS default model for player.
 *
 * @param id		Player index.
 */
native cs_reset_player_model(id)
