#if defined _cs_maxspeed_stocks_included
  #endinput
#endif
#define _cs_maxspeed_stocks_included

#include <cs_maxspeed_api>

stock cs_set_player_maxspeed_auto(id, Float:maxspeed)
{
	if (MAXSPEED_BARRIER_MIN <= maxspeed <= MAXSPEED_BARRIER_MAX)
		cs_set_player_maxspeed(id, maxspeed, true)
	else
		cs_set_player_maxspeed(id, maxspeed, false)
}

stock cs_maxspeed_display_value(Float:maxspeed)
{
	if (MAXSPEED_BARRIER_MIN <= maxspeed <= MAXSPEED_BARRIER_MAX)
		return floatround(maxspeed * CS_KNIFE_MAXSPEED);
	
	return floatround(maxspeed);
}
