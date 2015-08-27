#include <amxmod.inc> 
#include <xtrafun> 
#include <superheromod.inc> 

#define TE_EXPLOSION 3
#define TE_SMOKE 5
#define TE_IMPLOSION 14
#define TE_BEAMCYLINDER	21
#define TE_EXPLFLAG_NONE 0


new blast_cir
new g_sModelIndexFireball
new g_sModelIndexSmoke
new m_iSpriteTexture

// VARIABLES 
new gHeroName[]="Explosion" 
new bool:g_hasexplosionPower[SH_MAXSLOTS+1] 


//---------------------------------------------------------------------------------------------- 
public plugin_init() 
{ 
  // Plugin Info 
  register_plugin("SUPERHERO Explosion","1.0","LiToViEtBoI") 

  // FIRE THE EVENT TO CREATE THIS SUPERHERO! 
  register_cvar("explosion_level", "7" ) 
  shCreateHero(gHeroName, "Explosion", "Blows up when killed!", false, "explosion_level" ) 

  // REGISTER EVENTS THIS HERO WILL RESPOND TO! (AND SERVER COMMANDS) 
  register_event("DeathMsg","death","a") 

    // INIT 
  register_srvcmd("explosion_init", "explosion_init") 
  shRegHeroInit(gHeroName, "explosion_init") 

  // DEFAULT THE CVARS 
  register_cvar("explosion_radius", "300" ) 
  register_cvar("explosion_damage", "100" )   
  blast_cir = get_cvar_num("explosion_radius")
} 
//---------------------------------------------------------------------------------------------- 
public plugin_precache() 
{ 
   	m_iSpriteTexture = precache_model( "sprites/shockwave.spr")
   	g_sModelIndexFireball = precache_model("sprites/zerogxplode.spr")
   	g_sModelIndexSmoke = precache_model("sprites/steam1.spr")
	precache_sound("ambience/particle_suck1.wav")
   
} 
//---------------------------------------------------------------------------------------------- 
public explosion_init() 
{ 
  new temp[6] 
  // First Argument is an id 
  read_argv(1,temp,5) 
  new id=str_to_num(temp) 

  // 2nd Argument is 0 or 1 depending on whether the id has explosion powers 
  read_argv(2,temp,5) 
  new hasPowers=str_to_num(temp) 

  g_hasexplosionPower[id]=(hasPowers!=0) 

} 
//---------------------------------------------------------------------------------------------- 
public explode( vec1[3] )
{ 
	message_begin( MSG_BROADCAST, SVC_TEMPENTITY )
	write_byte( TE_IMPLOSION )
	write_coord(vec1[0])
	write_coord(vec1[1])
	write_coord(vec1[2])
	write_byte(100)
	write_byte(20)
	write_byte(5)
	message_end()
}	

public blastcircles(parm[2]){
	new id = parm[0]
	new origin[3]
	get_user_origin(id,origin)

	// blast circles
	message_begin( MSG_PAS, SVC_TEMPENTITY, origin )
	write_byte( TE_BEAMCYLINDER )
	write_coord( origin[0])
	write_coord( origin[1])
	write_coord( origin[2] - 16)
	write_coord( origin[0])
	write_coord( origin[1])
	write_coord( origin[2] - 16 + blast_cir)
	write_short( m_iSpriteTexture )
	write_byte( 0 ) // startframe
	write_byte( 0 ) // framerate
	write_byte( 6 ) // life
	write_byte( 16 )  // width
	write_byte( 0 )	// noise
	write_byte( 188 )
	write_byte( 220 )
	write_byte( 255 )
	write_byte( 255 ) //brightness
	write_byte( 0 ) // speed
	message_end()

	message_begin( MSG_PAS, SVC_TEMPENTITY, origin )
	write_byte( TE_BEAMCYLINDER )
	write_coord( origin[0])
	write_coord( origin[1])
	write_coord( origin[2] - 16)
	write_coord( origin[0])
	write_coord( origin[1])
	write_coord( origin[2] - 16 + ( blast_cir / 2 ))
	write_short( m_iSpriteTexture )
	write_byte( 0 ) // startframe
	write_byte( 0 ) // framerate
	write_byte( 6 ) // life
	write_byte( 16 )  // width
	write_byte( 0 )	// noise
	write_byte( 188 )
	write_byte( 220 )
	write_byte( 255 )
	write_byte( 255 ) //brightness
	write_byte( 0 ) // speed
	message_end()

	return PLUGIN_CONTINUE
}



public apacheexplode(parm[2]){		
	new id = parm[0]
	new origin[3]
	get_user_origin(id,origin)

	// random explosions
	message_begin( MSG_PVS, SVC_TEMPENTITY, origin )
	write_byte( TE_EXPLOSION) // This just makes a dynamic light now
	write_coord( origin[0] + random_num( -100, 100 ))
	write_coord( origin[1] + random_num( -100, 100 ))
	write_coord( origin[2] + random_num( -50, 50 ))
	write_short( g_sModelIndexFireball )
	write_byte( random_num(0,20) + 20  ) // scale * 10
	write_byte( 12  ) // framerate
	write_byte( TE_EXPLFLAG_NONE )
	message_end()

	// lots of smoke
	message_begin( MSG_PVS, SVC_TEMPENTITY, origin )
	write_byte( TE_SMOKE )
	write_coord( origin[0] + random_num( -100, 100 ))
	write_coord( origin[1] + random_num( -100, 100 ))
	write_coord( origin[2] + random_num( -50, 50 ))
	write_short( g_sModelIndexSmoke )
	write_byte( 60 ) // scale * 10
	write_byte( 10  ) // framerate
	message_end()
}

//---------------------------------------------------------------------------------------------- 
public death()
{
  new id = read_data(2)
  if (g_hasexplosionPower[id] == true) BlowUp(id)
}
//---------------------------------------------------------------------------------------------- 

public BlowUp(id)
{ 
   new origin[3] 
   get_user_origin(id,origin)
   
   emit_sound(id,CHAN_STATIC, "ambience/particle_suck1.wav", 1.0, ATTN_NORM, 0, PITCH_NORM)
   new parm[2]
   parm[0]=id
   parm[1]=6
   set_task(0.5,"apacheexplode",1,parm,2)
   set_task(0.5,"blastcircles",2,parm,2)
   set_task(1.0,"bum",3,parm,1)
   explode(origin)
   
} 

public bum(parm[2]){
   new damage, distanceBetween
   new id = parm[0]
   new origin[3] 
   get_user_origin(id,origin)

   for(new a = 1; a <= SH_MAXSLOTS; a++) 
   { 
     if( is_user_alive(a) && ( get_user_team(id) != get_user_team(a)) )
     {
       new origin1[3]
       get_user_origin(a,origin1) 
     
       distanceBetween = get_distance(origin, origin1 )
       if( distanceBetween < blast_cir )
       {
         damage=get_cvar_num("explosion_damage")
         shExtraDamage(a, id, damage, "Explosion")
         } // distance
     } // alive
   } // loop    
	
}
//---------------------------------------------------------------------------------------------- 
