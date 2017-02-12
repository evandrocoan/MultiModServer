#if defined _kve_included
  #endinput
#endif
#define _kve_included
#include <amxmodx>

// entity_callback(const szValue[], entid, kvdid)
// worldspawn_callback(bExists, const szValue[])

native register_keyvalue(szClassName[32], szKeyName[64], szFunction[32]);
