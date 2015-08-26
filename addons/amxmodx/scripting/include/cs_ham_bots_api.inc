#if defined _cs_ham_bots_api_included
  #endinput
#endif
#define _cs_ham_bots_api_included

#if AMXX_VERSION_NUM >= 175
	#pragma reqlib cs_ham_bots_api
	#if !defined AMXMODX_NOAUTOLOAD
		#pragma loadlib cs_ham_bots_api
	#endif
#else
	#pragma library cs_ham_bots_api
#endif

/**
 * Hooks the virtual table for CZ Bots entity class.
 * An example would be: RegisterHamBots(Ham_TakeDamage, "player_hurt");
 * Look at the Ham enum for parameter lists.
 *
 * @param function		The function to hook.
 * @param callback		The forward to call.
 * @param post			Whether or not to forward this in post.
 * @return 				Returns a handle to the forward.  Use EnableHamForwardBots/DisableHamForwardBots to toggle the forward on or off.
 */
native RegisterHamBots(Ham:function, const Callback[], Post=0);

/**
 * Stops a ham forward from triggering for CZ Bots.
 * Use the return value from RegisterHamBots as the parameter here!
 *
 * @param fwd			The forward to stop.
 */
native DisableHamForwardBots(fwd);

/**
 * Starts a ham forward back up for CZ Bots.
 * Use the return value from RegisterHamBots as the parameter here!
 *
 * @param fwd			The forward to re-enable.
 */
native EnableHamForwardBots(fwd);


// This is the callback from the module. Do not modify this!
public HamHook:__RegisterHamBots(Ham:function, EntityId, const Callback[], Post)
	return RegisterHamFromEntity(function, EntityId, Callback, Post);
