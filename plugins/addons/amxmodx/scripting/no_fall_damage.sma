#include <amxmodx>
#include <engine>

#define FALL_VELOCITY 350.0

public plugin_init() {
  register_plugin("No fall damage", "0.2", "v3x");
  if(!cvar_exists("mp_falldamage")) {
    register_cvar("mp_falldamage", "0");
  }
}

new bool:falling[33];

public client_PreThink(id) {
  if(get_cvar_num("mp_falldamage") == 0 
  && is_user_alive(id) 
  && is_user_connected(id)) {
    if(entity_get_float(id, EV_FL_flFallVelocity) >= FALL_VELOCITY) {
      falling[id] = true;
    } else {
      falling[id] = false;
    }
  }
}

public client_PostThink(id) {
  if(get_cvar_num("mp_falldamage") == 0 
  && is_user_alive(id) 
  && is_user_connected(id)) {
    if(falling[id]) {
      entity_set_int(id, EV_INT_watertype, -3);
    }
  }
}