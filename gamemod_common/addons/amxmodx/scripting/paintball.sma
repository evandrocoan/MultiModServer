/*******************************************************************************
                            AMX Paint Ball


  Author: KRoTaL
  Version: 0.5
  - Ported to AMX MOD X by SAMURAI and Updated !

  0.1    Release
  0.2    Optimization + added cvar paintball_randomcolor
  0.3    Added cvar paintball_lifetime
  0.4    Added pcvars
  0.5 (10/02/2007) - Added a new cvar (read on Cvars part)


  Cvars:

  paintball "1"    -  0: disables the plugin
                      1: enables the plugin

  paintball_randomcolor "0"   - 0: use defined colors
                                1: completely random colors
				NEW :
				2: by team functions :
				   players from CT Team will have blue colors
				   players from T Team will have red colors
                                
  paintball_maxballs "200"    - how many balls (entities) on the map can be created by the plugin
                                decrease the value if your server crashes
                                
  paintball_lifetime "10"   -   lifetime in seconds of the colored entities


  Setup:

  Install the amxx file.
  Enable Engine and Cstrike Module


*******************************************************************************/

#include <amxmodx>
#include <engine>
#include <cstrike>

#define MAX_COLORS 9


new g_paintSprite[2][] = {"sprites/bhit.spr", "sprites/richo1.spr"}
new g_paintColors[MAX_COLORS][3] = {
{255,255,255}, // white
{255,0,0}, // red
{0,255,0}, // green
{0,0,255}, // blue
{255,255,0}, // yellow
{255,0,255}, // magenta
{0,255,255}, // cyan
{255,20,147}, // pink
{255,165,0} // orange
}

new lastwpn[33]
new lastammo[33]
new g_ballsnum = 0

// Cvars //
new paintball
new paintball_lifetime
new paintball_randomcolor
new paintball_maxballs


public plugin_init()
{
  register_plugin("Paint Ball", "0.5", "KRoTaL")
  paintball = register_cvar("paintball", "1")
  paintball_randomcolor = register_cvar("paintball_randomcolor", "0")
  paintball_maxballs = register_cvar("paintball_maxballs", "200")
  paintball_lifetime = register_cvar("paintball_lifetime", "10")
  register_event("CurWeapon", "make_paint", "be", "3>0")
  register_logevent("new_round", 2, "0=World triggered", "1=Round_Start")
}

public plugin_precache()
{
  precache_model("sprites/bhit.spr")
  precache_model("sprites/richo1.spr")
}

stock worldInVicinity(Float:origin[3]) {
  new ent = find_ent_in_sphere(-1, origin, 4.0)
  while(ent > 0)
  {
    if(entity_get_float(ent, EV_FL_health) > 0 || entity_get_float(ent, EV_FL_takedamage) > 0.0)
      return 0
    ent = find_ent_in_sphere(ent, origin, 4.0)
  }

  new Float:traceEnds[8][3], Float:traceHit[3], hitEnt

  traceEnds[0][0] = origin[0] - 2.0
  traceEnds[0][1] = origin[1] - 2.0
  traceEnds[0][2] = origin[2] - 2.0

  traceEnds[1][0] = origin[0] - 2.0
  traceEnds[1][1] = origin[1] - 2.0
  traceEnds[1][2] = origin[2] + 2.0

  traceEnds[2][0] = origin[0] + 2.0
  traceEnds[2][1] = origin[1] - 2.0
  traceEnds[2][2] = origin[2] + 2.0

  traceEnds[3][0] = origin[0] + 2.0
  traceEnds[3][1] = origin[1] - 2.0
  traceEnds[3][2] = origin[2] - 2.0

  traceEnds[4][0] = origin[0] - 2.0
  traceEnds[4][1] = origin[1] + 2.0
  traceEnds[4][2] = origin[2] - 2.0

  traceEnds[5][0] = origin[0] - 2.0
  traceEnds[5][1] = origin[1] + 2.0
  traceEnds[5][2] = origin[2] + 2.0

  traceEnds[6][0] = origin[0] + 2.0
  traceEnds[6][1] = origin[1] + 2.0
  traceEnds[6][2] = origin[2] + 2.0

  traceEnds[7][0] = origin[0] + 2.0
  traceEnds[7][1] = origin[1] + 2.0
  traceEnds[7][2] = origin[2] - 2.0

  for (new i = 0; i < 8; i++) {
    if (PointContents(traceEnds[i]) != CONTENTS_EMPTY)
    {
      return 1
    }

    hitEnt = trace_line(0, origin, traceEnds[i], traceHit)
    if (hitEnt != -1)
    {
      return 1
    }
    for (new j = 0; j < 3; j++) {
      if (traceEnds[i][j] != traceHit[j])
      {
        return 1
      }
    }
  }

  return 0
}

public make_paint(id)
{
  new wpn = read_data(2)
  new ammo = read_data(3)
  
  new CsTeams:playert = cs_get_user_team(id)
  
  if(get_pcvar_num(paintball) == 1 && lastwpn[id] == wpn && lastammo[id] > ammo)
  {
    new iOrigin[3]
    get_user_origin(id, iOrigin, 4)
    new Float:fOrigin[3]
    IVecFVec(iOrigin, fOrigin)

    if(g_ballsnum < get_pcvar_num(paintball_maxballs) /*get_num_ents() < (global_get_int(GV_INT_maxEntities) - 100)*/ && worldInVicinity(fOrigin))
    {
      new ent = create_entity("info_target")
      if(ent > 0)
      {
        entity_set_string(ent, EV_SZ_classname, "paint_ent")
        entity_set_int(ent, EV_INT_movetype, 0)
        entity_set_int(ent, EV_INT_solid, 0)
        entity_set_model(ent, g_paintSprite[random_num(0,1)])
        new r, g, b
        if(get_pcvar_num(paintball_randomcolor) == 0)
        {
          new i = random_num(0, MAX_COLORS-1)
          r = g_paintColors[i][0]
          g = g_paintColors[i][1]
          b = g_paintColors[i][2]
        }
        else if(get_pcvar_num(paintball_randomcolor) == 1)
        {
          r = random_num(64,255)
          g = random_num(64,255)
          b = random_num(64,255)
        }
	
        else if(get_pcvar_num(paintball_randomcolor) == 2)
         {
	 	if(playert == CS_TEAM_CT)
		{			
			r = 0
			g = 0
			b = 255
		}
		
		else 
		{
			r = 255
			g = 0
			b = 0
		}
	}
		
        set_rendering(ent, kRenderFxNoDissipation, r, g, b, kRenderGlow, 255)
        entity_set_origin(ent, fOrigin)
        entity_set_int(ent, EV_INT_flags, FL_ALWAYSTHINK)
        entity_set_float(ent, EV_FL_nextthink, get_gametime() + get_pcvar_float(paintball_lifetime))
        ++g_ballsnum
      }
    }
  }
  lastwpn[id] = wpn
  lastammo[id] = ammo
}

public pfn_think(entity) {
  if(entity > 0) {
    new class[32]
    entity_get_string(entity, EV_SZ_classname, class, 31)
    if(equal(class, "paint_ent")) {
      remove_entity(entity)
      --g_ballsnum
    }
  }
}

public new_round()
{
  remove_entity_name("paint_ent")
  g_ballsnum = 0
}



/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1033\\ f0\\ fs16 \n\\ par }
*/
