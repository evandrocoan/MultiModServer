#include <amxmod.inc>
#include <xtrafun> 
#include <Vexd_Utilities> 
#include <superheromod.inc> 

#define TE_BEAMPOINTS 0
#define TE_EXPLOSION 3
#define TE_EXPLOSION2 12


new gHeroName[]="Pesk" 
new gHaspeskPower[SH_MAXSLOTS+1] 
new Beam,Fire
new bool:InBeam[33] = false
new smoke

public plugin_init()
{
  register_plugin("SUPERHERO Pesk","1.0","[FTW]-S.W.A.T")
  if ( isDebugOn() ) server_print("Attempting to create Pesk Hero")
  register_cvar("pesk_level", "2" )
  shCreateHero(gHeroName, "Pesk", "Shoot people when your dead", true, "pesk_level" )
  register_srvcmd("pesk_init", "pesk_init") 
  shRegHeroInit(gHeroName, "pesk_init") 
  register_srvcmd("pesk_kd",   "pesk_kd") 
  shRegKeyDown(gHeroName, "pesk_kd") 
  register_event("ResetHUD","newRound","b")
  register_srvcmd("pesk_loop", "pesk_loop")
  set_task(1.0,"pesk_loop",0,"",0,"b" )

  register_cvar("pesk_cooldown", "40" ) 
  register_cvar("pesk_maxdamage", "300" )
  register_cvar("pesk_radius", "300" )
}

public pesk_init()
{
  new temp[6] 
  read_argv(1,temp,5) 
  new id=str_to_num(temp) 
  read_argv(2,temp,5) 
  new hasPowers=str_to_num(temp) 
  gHaspeskPower[id]=(hasPowers!=0) 

  if ( hasPowers )
   gHaspeskPower[id]=true
  else
   gHaspeskPower[id]=false 
}

public plugin_precache()
{
 Beam = precache_model("sprites/smoke.spr")
 smoke = precache_model("sprites/steam1.spr") 
 Fire = precache_model("sprites/zerogxplode.spr")
}

public pesk_kd() { 
  new temp[6] 
  read_argv(1,temp,5) 
  new id=str_to_num(temp)
  if ( is_user_alive(id) ) return PLUGIN_HANDLED 
  if ( gPlayerUltimateUsed[id] ) 
  {
    playSoundDenySelect(id) 
    return PLUGIN_HANDLED 
  } 
  
  new peskCooldown=get_cvar_num("pesk_cooldown") 
  if ( peskCooldown>0 ) 
	ultimateTimer(id, peskCooldown * 1.0 ) 
  beamp(id)
  return PLUGIN_HANDLED 
} 

public beamp(id)
{
if ( gHaspeskPower[id] )
	{
		InBeam[id] = true
		new parm[1]
		parm[0] = id
		client_print(id,print_chat,"PESKY YOU.")
		set_task(0.1,"beam",1,parm,1)
	}
}

public beam(parm[])
{
	new id = parm[0]
	new origin1[3],origin2[3]
	get_user_origin(id,origin1)
	get_user_origin(id,origin2,3)

	message_begin( MSG_BROADCAST, SVC_TEMPENTITY ) 
	write_byte(TE_BEAMPOINTS) 
	write_coord(origin1[0]) 
	write_coord(origin1[1]) 
	write_coord(origin1[2]) 
	write_coord(origin2[0]) 
	write_coord(origin2[1]) 
	write_coord(origin2[2]) 
	write_short(Beam)   // model 
	write_byte(1) // start frame 
	write_byte(20) // framerate 
	write_byte(6) // life 
	write_byte(5)  // width 
	write_byte(2)   // noise 
	write_byte(255)   // r, g, b 
	write_byte(255)   // r, g, b 
	write_byte(255)   // r, g, b 
	write_byte(500)   // brightness 
	write_byte(2)      // speed 
	message_end()
	
	
	message_begin( MSG_BROADCAST, SVC_TEMPENTITY ) 
	write_byte(TE_EXPLOSION)
	write_coord(origin2[0]) 
	write_coord(origin2[1])
	write_coord(origin2[2])
	write_short(Fire)
	write_byte(100)
	write_byte(50)
	write_byte(0)
	message_end()
	
	message_begin( MSG_BROADCAST, SVC_TEMPENTITY ) 
	write_byte(TE_EXPLOSION)
	write_coord(origin2[0]+20) 
	write_coord(origin2[1]+20) 
	write_coord(origin2[2])
	write_short(Fire)
	write_byte(100)
	write_byte(100)
	write_byte(0)
	message_end()
	
	message_begin( MSG_BROADCAST, SVC_TEMPENTITY ) 
	write_byte(TE_EXPLOSION)
	write_coord(origin2[0]-20) 
	write_coord(origin2[1]-20) 
	write_coord(origin2[2])
	write_short(Fire)
	write_byte(100)
	write_byte(150)
	write_byte(0)
	message_end()

	message_begin( MSG_BROADCAST,SVC_TEMPENTITY)  
	write_byte(TE_EXPLOSION2) 
	write_coord(origin2[0]) 
	write_coord(origin2[1]) 
	write_coord(origin2[2]) 
	write_byte(188) // start color 
	write_byte(10) // num colors 
	message_end() 
	AssRadiusDamage(id,origin2)
	InBeam[id] = true
	
	return PLUGIN_HANDLED
}

public pbeamon(id)
{
	InBeam[id] =  false
	client_print(id,print_chat,"PESKY YOU.")
	client_print(id,print_chat,"PESKY YOU.")
}

public newRound(id)
{
  gPlayerUltimateUsed[id]=false
  return PLUGIN_HANDLED
}

public AssRadiusDamage(id,origin[3]) {

	new distanceBetween
	new damage, multiplier
	
	new FFOn= get_cvar_num("mp_friendlyfire")

	for(new vic = 1; vic <= SH_MAXSLOTS; vic++) 
	{ 
		if( is_user_alive(vic) && ( get_user_team(id) != get_user_team(vic) || FFOn != 0 || vic==id ) )
		{
			new origin1[3]
			get_user_origin(vic,origin1) 
			distanceBetween = get_distance(origin, origin1 )
			if( distanceBetween < get_cvar_num("pesk_radius") )
			{
			multiplier=(get_cvar_num("pesk_maxdamage")*get_cvar_num("pesk_maxdamage"))/get_cvar_num("pesk_radius")
			damage=(get_cvar_num("pesk_radius")-distanceBetween)*multiplier
			damage=sqrt(damage)
			shExtraDamage(vic, id, damage, "Pesk")
			} // distance
		} // alive target...
	} // loop	
}

public pesk_loop()
{
  for ( new id=1; id<=SH_MAXSLOTS; id++ )
  {
    if (  gHaspeskPower[id] && !is_user_alive(id)  )
    {
      make_fog(id)
    }
  }
}

public fog_this_area(origin[3]){ 
   message_begin( MSG_BROADCAST,SVC_TEMPENTITY,origin ) 
   write_byte( 5 ) 
   write_coord( origin[0] + random_num( -100, 100 )) 
   write_coord( origin[1] + random_num( -100, 100 )) 
   write_coord( origin[2] + random_num( -75, 75 )) 
   write_short( smoke ) 
   write_byte( 60 ) 
   write_byte( 5 ) 
   message_end() 
} 

public make_fog(id){ 
   new origin[3] 
   get_user_origin(id,origin) 
   fog_this_area(origin) 
   fog_this_area(origin) 
   fog_this_area(origin) 
   fog_this_area(origin) 
   fog_this_area(origin) 
   fog_this_area(origin) 
   fog_this_area(origin) 
   return PLUGIN_HANDLED 
} 
