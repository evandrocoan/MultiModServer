/**
* @brief Pauses / Unpauses the round timer.
*
* @note  The countdown timer will be paused and will also put any time objective 
*	 check on hold.
*
* @noreturn
*/
native RoundTimerPause();

/**
* @brief Returns whether the round timer is paused or not.
*
* @return type	boolean
*/
native bool:IsRoundTimerPaused();

/**
* @brief Sets the round timer to the given time.
*
* @param int	Minutes	
* @param int	Seconds
*
* @noreturn
*/
native RoundTimerSet( iMinutes, iSeconds = 0 );

/**
* @brief Returns round timer in seconds.
*
* @return time
*/
native RoundTimerGet();