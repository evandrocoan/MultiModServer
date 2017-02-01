
#include <amxmodx>

/* Choose One */
//#include <engine>
#include <fakemeta>

#include "ojos.inc"

#define MAX_LIGHT_POINTS 3

new weather_ent
new Float:g_strikedelay
new g_lightpoints[MAX_LIGHT_POINTS]
new g_fxbeam;
new g_soundstate[33]
new g_maxplayers;
new g_stormintensity;

public plugin_precache() 
{
	register_plugin("RainySnowy", "2.0y", "OneEyed & teame06");
	register_cvar("rainysnowy", "2.0y", FCVAR_SERVER);
	register_cvar("weather_type", "1");
	register_cvar("weather_storm", "50");
	
	g_maxplayers = get_maxplayers();
	
	new type = get_cvar_num("weather_type");
	if(type == 3)
		type = random_num(0,2);
		
	switch(type) {
		case 1: 
		{	
			g_fxbeam = precache_model("sprites/laserbeam.spr");
			precache_model("models/chick.mdl");
			precache_sound("ambience/rain.wav");
			precache_sound("ambience/thunder_clap.wav");
			weather_ent = CREATE_ENTITY("env_rain")
			THINK("env_rain","WeatherSystem")
			NEXTTHINK(weather_ent,1.0)
		}
		case 2: 
		{
			weather_ent = CREATE_ENTITY("env_snow");
		}
	}	
}

public client_putinserver(id)
	client_cmd(id,"cl_weather 1");	

//This is only for rain.
public WeatherSystem(entid) {
	if(entid == weather_ent) 
	{
		//Is weather_storm activated? ( 0 = OFF ) -- ( 1-100 = INTENSITY )
		g_stormintensity = get_cvar_num("weather_storm");
		
		//Do our soundstate and picks random player.
		new victim = GetSomeoneUnworthy(); 
		
		if(g_stormintensity) 
		{
			//Is the delay up?
			if(g_strikedelay < get_gametime()) 
			{
				//We got player to create lightning from?
				if(victim)
				{
					//Do our Lightning Technique.
					CreateLightningPoints(victim);
				}
			}
		}
		NEXTTHINK(weather_ent,2.0)
	}
	return PLUGIN_CONTINUE
}

GetSomeoneUnworthy() {
	new cnt, id, total[33];
	for(id=1;id<g_maxplayers;id++)
		if(is_user_alive(id))
			if(is_user_outside(id)) 
			{
				total[cnt++] = id;	
				
				if(!g_soundstate[id]) {
					g_soundstate[id] = 1;
					client_cmd(id, "speak ambience/rain.wav");
				}	
			}
			else if(g_soundstate[id]) 
			{
				g_soundstate[id] = 0;
				client_cmd(id, "speak NULL")
			}
	
	if(cnt)
		return total[random_num(0, (cnt-1))];
	return 0;
}

CreateLightningPoints(victim) 
{
	if(IS_VALID_ENT(g_lightpoints[0]))
		return 0;
		
	new ent, x, Float:tVel[3];
	new Float:vOrig[3];
	new Float:mins[3] = { -1.0, -1.0, -1.0 };
	new Float:maxs[3] = { 1.0, 1.0, 1.0 };
	new Float:dist = is_user_outside(victim)-5; //Get distance to set ents at.
	
	GET_ORIGIN(victim,vOrig)
	if(dist > 700.0) { //cap distance.
		dist = 700.0;
	}
	vOrig[2] += dist;

	//Create lightning bolts by spreading X entities randomly with velocity
	for(x=0;x<MAX_LIGHT_POINTS;x++) 
	{
		ent = CREATE_ENTITY("env_sprite")
		SET_INT(ent,movetype,MOVETYPE_FLY)
		SET_INT(ent,solid,SOLID_TRIGGER)
		SET_FLOAT(ent,renderamt,0.0)
		SET_INT(ent,rendermode,kRenderTransAlpha)
		SET_MODEL(ent,"models/chick.mdl")
		
		SET_VECTOR(ent,mins,mins)
		SET_VECTOR(ent,maxs,maxs)
		tVel[0] = random_float(-500.0,500.0);
		tVel[1] = random_float(-500.0,500.0);
		tVel[2] = random_float((dist<=700.0?0.0:-100.0),(dist<=700.0?0.0:50.0));
		
		SET_VECTOR(ent,origin,vOrig)
		SET_VECTOR(ent,velocity,tVel)
		g_lightpoints[x] = ent;
	}
	emit_sound(ent, CHAN_STREAM, "ambience/thunder_clap.wav", 1.0, ATTN_NORM, 0, PITCH_NORM)
	set_task(random_float(0.6,2.0),"Lightning",victim);
	return 1;
}

// Creating a beam at each entity consecutively.
// Player has 1 in 1000 chance of getting struck !
public Lightning(victim) 
{
	new x, a, b, rand;
	new endpoint = MAX_LIGHT_POINTS-1;
	while(x < endpoint) {
		a = g_lightpoints[x];
		b = g_lightpoints[x+1];
		x++
		if(x == endpoint) {
			rand = random_num(1,1000); //One unlucky son of a bish.
			if(rand == 1) {
				b = victim;
				FAKE_DAMAGE(victim,"Lightning",100.0,1);
			}
		}
		CreateBeam(a,b);
	}
	
	for(x=0;x<MAX_LIGHT_POINTS;x++)
		if(IS_VALID_ENT(g_lightpoints[x]))
			REMOVE_ENTITY(g_lightpoints[x])
	
	
	//Set up next lightning.
	if(g_stormintensity > 100) {
		set_cvar_num("weather_storm", 100);
		g_stormintensity = 100;	
	}
	new Float:mins = 50.0-float(g_stormintensity/2);
	new Float:maxs = 50.0-float(g_stormintensity/3);
	g_strikedelay = get_gametime() + random_float(mins, maxs);
}

//return distance above us to sky
Float:is_user_outside(id) {
	new Float:origin[3], Float:dist;
	GET_ORIGIN(id, origin)
	
	dist = origin[2];
	
	while (POINTCONTENTS(origin) == -1)
		origin[2] += 5.0;

	if (POINTCONTENTS(origin) == -6) return (origin[2]-dist);
	return 0.0;
}

CreateBeam(entA, entB)
{
	message_begin( MSG_BROADCAST, SVC_TEMPENTITY );
	write_byte( 8 );
	write_short( entA );
	write_short( entB );
	write_short( g_fxbeam );
	write_byte(0);  	//start frame
	write_byte(10); 	//framerate
	write_byte(5); 		//life
	write_byte(8);  	//width
	write_byte(100); 	//noise
	write_byte(255);	//red
	write_byte(255);	//green
	write_byte(255);	//blue
	write_byte(255);	//brightness
	write_byte(10);		//scroll speed
	message_end();
}