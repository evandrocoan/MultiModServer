/*******************************************************************************************************
                            AMX Advanced Slow Motion


  Author: KRoTaL
  Version: 0.1

  0.1    Release


  Cvar:

  adv_slowmo "abcdef"  -  a: c4 explosion in slow motion
                          b: last kill in slow motion
                          c: grenade kill in slow motion
                          d: knife kill in slow motion
                          e: hs kill in slow motion
                          f: special effect (progressive slowdown)


  Setup (AMX 0.9.9):

  Install the amx file.
  Enable VexdUM (both in metamod/plugins.ini and amx/config/modules.ini)


*******************************************************************************************************/

#include <amxmodx>
#include <amxmisc>
#include <fun>
#include <engine>

#define SLOWMO_C4EXPLOSION 1
#define SLOWMO_LASTKILL 2
#define SLOWMO_NADEKILL 4
#define SLOWMO_KNIFEKILL 8
#define SLOWMO_HSKILL 16
#define SLOWMO_SPECIALEFFECT 32

#define SLOWMO_RATE 0.2


new g_slowmo[33]
new g_maxplayers
new g_bombPlanted
new Float:g_bombOri[3]
new bool:g_isDead[33]
new g_exploSpr

getSlowMoFlags()
{
  new flags[32]
  get_cvar_string("adv_slowmo", flags, 31)
  return read_flags(flags)
}

public plugin_init()
{
  register_plugin("Advanced Slow Motion", "0.1", "KRoTaL")
  register_cvar("adv_slowmo", "abcdef")
  register_event("ResetHUD", "resethud_event", "b")
  register_event("DeathMsg", "death_event", "a")
  register_event("Damage", "damage_event", "b")
  register_event("SendAudio","bombplanted_event","a","2&%!MRAD_BOMBPL")
  register_event("SendAudio", "end_round", "a", "2&%!MRAD_terwin", "2&%!MRAD_ctwin", "2&%!MRAD_rounddraw")
  register_event("TextMsg", "end_round", "a", "2&#Game_C", "2&#Game_w")
  g_maxplayers = get_maxplayers() + 1
}

public plugin_precache()
{
  g_exploSpr = precache_model("sprites/fexplo.spr")
}

public client_connect(id)
{
  g_slowmo[id] = 0
  g_isDead[id] = false
}

public resethud_event(id)
{
  g_slowmo[id] = 0
  g_isDead[id] = false
}

public death_event()
{
  new id = read_data(2)
  new wname[32]
  read_data(4, wname, 31)
  if(equal(wname, "grenade"))
  {
    if(getSlowMoFlags() & SLOWMO_NADEKILL)
    {
      set_task(0.1, "slowDown", id)
      set_user_gravity(id, 0.3)
      g_slowmo[id] = 1
    }
  }
  if(equal(wname, "knife"))
  {
    if(getSlowMoFlags() & SLOWMO_KNIFEKILL)
    {
      g_slowmo[id] = 1
    }
  }
  if(read_data(3) == 1)
  {
    if(getSlowMoFlags() & SLOWMO_HSKILL)
    {
      g_slowmo[id] = 1
    }
  }
  new players[32], inum
  get_players(players, inum, "ae", (get_user_team(id) == 1) ? "TERRORIST" : "CT")
  if(!inum)
  {
    if(getSlowMoFlags() & SLOWMO_LASTKILL)
    {
      g_slowmo[id] = 1
    }
  }
}

public damage_event(id)
{
  if(!is_user_alive(id))
  {
    if(g_bombPlanted && !g_isDead[id])
    {
      new ent = entity_get_edict(id, EV_ENT_dmg_inflictor)
      if(is_valid_ent(ent))
      {
        new classname[32]
        entity_get_string(ent, EV_SZ_classname, classname, 31)
        new model[32]
        entity_get_string(ent, EV_SZ_model, model, 31)
        if(equal(classname, "grenade") && equal(model, "")
        && entity_get_int(ent, EV_INT_spawnflags) == 1 && entity_get_int(ent, EV_INT_effects) == 128)
        {
          if(getSlowMoFlags() & SLOWMO_C4EXPLOSION)
          {
            new Float:vel[3]
            entity_get_vector(id, EV_VEC_velocity, vel)
            set_task(0.1, "slowDown", id)
            set_user_gravity(id, 0.3)
            g_slowmo[id] = 1
          }
          g_isDead[id] = true
        }
      }
    }
  }
}

public slowDown(id)
{
  new Float:vel[3]
  entity_get_vector(id, EV_VEC_velocity, vel)
  vel[0] /= 3.0
  vel[1] /= 3.0
  vel[2] /= 2.0
  entity_set_vector(id, EV_VEC_velocity, vel)
}

public bombplanted_event()
{
  g_bombPlanted = 1
  new c4 = find_ent_by_class(-1, "grenade")
  while(c4 > 0)
  {
    new model[32]
    entity_get_string(c4, EV_SZ_model, model, 31)
    if(equal(model, "models/w_c4.mdl"))
    {
      entity_get_vector(c4, EV_VEC_origin, g_bombOri)
      return
    }
    c4 = find_ent_by_class(c4, "grenade")
  }
}

public bombexploded_event()
{
  if(getSlowMoFlags() & SLOWMO_C4EXPLOSION)
  {
    new ori[3]
    FVecIVec(g_bombOri, ori)
    message_begin(MSG_PVS, SVC_TEMPENTITY, ori)
    write_byte(3)
    write_coord(ori[0])
    write_coord(ori[1])
    write_coord(ori[2])
    write_short(g_exploSpr)
    write_byte(30)
    write_byte(1)
    write_byte(0)
    message_end()
  }
}

public end_round()
{
  set_task(2.0, "resetBombPlanted", 9798415)
}

public resetBombPlanted()
{
  g_bombPlanted = 0
}

public server_frame()
{
  for(new i = 1; i < g_maxplayers; i++)
  {
    if(g_slowmo[i] == 1)
    {
      if(getSlowMoFlags() & SLOWMO_SPECIALEFFECT)
      {
        new Float:fr = entity_get_float(i, EV_FL_framerate)
        fr = (fr > SLOWMO_RATE) ? (fr - 0.03) : SLOWMO_RATE
        entity_set_float(i, EV_FL_framerate, fr)
      }
      else
      {
        entity_set_float(i, EV_FL_framerate, SLOWMO_RATE)
      }
    }
  }
  return PLUGIN_CONTINUE
}
