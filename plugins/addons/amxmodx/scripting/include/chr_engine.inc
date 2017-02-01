/* CHR Engine - v1.1b
*
* by GHW_Chronic
*   12/2006 - 07/2009
*
* This file is provided as is (no warranties).
*
*/

#if defined chr_engine_included
  #endinput
#endif
#define chr_engine_included


#include <amxmodx>
#include <fakemeta>



/*
*
*  Determines velocity (new_velocity) that
*  you would set an entity to in order for
*  it to go at "speed" from "origin1" to
*  "origin2".
*
*/

stock get_speed_vector(const Float:origin1[3],const Float:origin2[3],Float:speed, Float:new_velocity[3])
{
	new_velocity[0] = origin2[0] - origin1[0]
	new_velocity[1] = origin2[1] - origin1[1]
	new_velocity[2] = origin2[2] - origin1[2]
	new Float:num = floatsqroot(speed*speed / (new_velocity[0]*new_velocity[0] + new_velocity[1]*new_velocity[1] + new_velocity[2]*new_velocity[2]))
	new_velocity[0] *= num
	new_velocity[1] *= num
	new_velocity[2] *= num

	return 1;
}



/*
*
*  Determines velocity (new_velocity) that
*  you would set "ent1" to in order for it
*  to go at "speed" from "ent1"'s origin
*  to "ent2"'s origin.
*
*/

stock get_speed_vector2(ent1, ent2, Float:speed, Float:new_velocity[3])
{
	if(!pev_valid(ent1) || !pev_valid(ent2))
		return 0;

	static Float:origin1[3]
	pev(ent1,pev_origin,origin1)
	static Float:origin2[3]
	pev(ent2,pev_origin,origin2)

	new_velocity[0] = origin2[0] - origin1[0]
	new_velocity[1] = origin2[1] - origin1[1]
	new_velocity[2] = origin2[2] - origin1[2]
	new Float:num = floatsqroot(speed*speed / (new_velocity[0]*new_velocity[0] + new_velocity[1]*new_velocity[1] + new_velocity[2]*new_velocity[2]))
	new_velocity[0] *= num
	new_velocity[1] *= num
	new_velocity[2] *= num

	return 1;
}



/*
*
*  Determines location ("origin") of an entity
*  with supplied offset to its original angles.
*
*  Example: You want the location of 30 units
*  to the left of a model but the model is
*  turned at an angle so you cannot simply add
*  the offset to the origin. Then you would use
*  this.
*
*/

stock get_offset_origin(ent,const Float:offset[3],Float:origin[3])
{
	if(!pev_valid(ent))
		return 0;

	new Float:angle[3]
	pev(ent,pev_origin,origin)
	pev(ent,pev_angles,angle)

	origin[0] += floatcos(angle[1],degrees) * offset[0]
	origin[1] += floatsin(angle[1],degrees) * offset[0]

	origin[2] += floatsin(angle[0],degrees) * offset[0]
	origin[0] += floatcos(angle[0],degrees) * offset[0]

	origin[1] += floatcos(angle[1],degrees) * offset[1]
	origin[0] -= floatsin(angle[1],degrees) * offset[1]

	origin[2] += floatsin(angle[2],degrees) * offset[1]
	origin[1] += floatcos(angle[2],degrees) * offset[1]

	origin[2] += floatcos(angle[2],degrees) * offset[2]
	origin[1] -= floatsin(angle[2],degrees) * offset[2]

	origin[2] += floatcos(angle[0],degrees) * offset[2]
	origin[0] -= floatsin(angle[0],degrees) * offset[2]

	origin[0] -= offset[0]
	origin[1] -= offset[1]
	origin[2] -= offset[2]

	return 1;
}



/*
*
*  Determines location ("origin") of a monster
*  or player entity with supplied offset to its
*  original angles.
*
*  Example: You want the location of 30 units
*  to the left of a model but the model is
*  turned at an angle so you cannot simply add
*  the offset to the origin. Then you would use
*  this.
*
*  Works same as above but only for players and
*  monsters.
*
*/

stock get_offset_origin_body(ent,const Float:offset[3],Float:origin[3])
{
	if(!pev_valid(ent))
		return 0;

	new Float:angle[3]
	pev(ent,pev_angles,angle)

	pev(ent,pev_origin,origin)

	origin[0] += floatcos(angle[1],degrees) * offset[0]
	origin[1] += floatsin(angle[1],degrees) * offset[0]

	origin[1] += floatcos(angle[1],degrees) * offset[1]
	origin[0] += floatsin(angle[1],degrees) * offset[1]

	return 1;
}



/*
*
*  Determines if a player is crouching or not.
*  Return 1 if crouching and 0 if not.
*
*  Set ignoreplayer to 1 if you are using on
*  a HL monster that can crouch.
*
*/

stock is_user_crouching(ent,ignoreplayer=0)
{
	if(!is_user_alive(ent) && !ignoreplayer)
		return 0;

	new Float:minsize[3]
	pev(ent,pev_mins,minsize)

	if(minsize[2]==-18.0)
		return 1;

	return 0;
}



/*
*
*  Returns indexes of players in order according
*  to how close they are to "origin". Indexes are
*  stored in "players[32]" and the number of
*  indexes returned is stored in num[0]. team[] is
*  used only if flag 'e' is passed.
*
*  Flags:
*  "a" - Don't return dead players
*  "b" - Don't return alive players
*  "c" - Skip bots
*  "d" - Skip real players
*  "e" - Match with passed team
*  "h" - Skip HLTV
*  "i" - Is in Viewcone
*  "j" - Is Visible
*
*  If flag 'i' is passed, you must specify into
*  variable "index" who's viewcone to check if
*  the returned players are in.
*
*/

stock get_players_distance(const Float:origin2[3],players[32], &num,const flags[]="",index=0,const team[]="")
{
	new bool:flag1, bool:flag2
	if(containi(flags,"j")!=-1) flag2 = true
	if(containi(flags,"i")!=-1)
	{
		if(!pev_valid(index))
			return 0;
		flag1 = true
	}

	static Float:origin[3]
	origin[0] = origin2[0]
	origin[1] = origin2[1]
	origin[2] = origin2[2]

	static players2[32]
	new num2
	arrayset(players2,0,32)
	get_players(players2,num2,flags,team)
	static Float:origin3[3]
	static Float:distance[32]
	for(new i=0;i<32;i++) distance[i]=0.0
	num = num2

	static Float:hit[3]
	new bool:continuea=true
	for(new i=0;i<num2;i++)
	{
		pev(players2[i],pev_origin,origin3)
		if(flag2)
		{
			engfunc(EngFunc_TraceLine,origin2,origin3,1,index,0)
			get_tr2(0,TR_vecEndPos,hit)
			if(hit[0]==origin3[0] && hit[1]==origin3[1] && hit[2]==origin3[2])
			{
				distance[i] = vector_distance(origin,origin3)
			}
			else
			{
				continuea=false
				distance[i] = 9999999.1337
				num--
			}
		}
		if(flag1 && continuea)
		{
			static Float:angles[3], Float:diff[3], Float:reciprocalsq, Float:norm[3], Float:dot, Float:fov
			pev(index, pev_angles, angles)
			engfunc(EngFunc_MakeVectors, angles)
			global_get(glb_v_forward, angles)
			angles[2] = 0.0

			pev(index, pev_origin, origin)
			diff[0] = origin3[0] - origin[0]
			diff[1] = origin3[1] - origin[1]
			diff[2] = origin3[2] - origin[2]
			//diff[2]=0.0// - for 2D viewcone

			reciprocalsq = 1.0 / floatsqroot(diff[0]*diff[0] + diff[1]*diff[1] + diff[2]*diff[2])
			norm[0] = diff[0] * reciprocalsq
			norm[1] = diff[1] * reciprocalsq
			norm[2] = diff[2] * reciprocalsq

			dot = norm[0]*angles[0] + norm[1]*angles[1] + norm[2]*angles[2]
			pev(index, pev_fov, fov)
			if(dot >= floatcos(fov * 3.1415926535 / 360.0))
			{
				distance[i] = vector_distance(origin,origin3)
			}
			else
			{
				continuea=false
				distance[i] = 9999999.1337
				num--
			}
		}
		if(continuea)
		{
			distance[i] = vector_distance(origin,origin3)
		}
	}
	static distance_cnt[32]
	arrayset(distance_cnt,0,32)
	for(new i=0;i<num2;i++)
	{
		if(distance[i]!=9999999.1337)
		{
			for(new i2=0;i2<num;i2++)
			{
				if(distance[i2]<distance[i]) distance_cnt[i]++
			}
			players[distance_cnt[i]]=players2[i]
		}
	}
	return 1;
}



/*
*
*  Forces "ent" to aim at "origin"
*
*  Set bone to a positive value to
*  detect a specific bone the function
*  should aim from.
*
*/

stock entity_set_aim(ent,const Float:origin2[3],bone=0)
{
	if(!pev_valid(ent))
		return 0;

	static Float:origin[3]
	origin[0] = origin2[0]
	origin[1] = origin2[1]
	origin[2] = origin2[2]

	static Float:ent_origin[3], Float:angles[3]

	if(bone)
		engfunc(EngFunc_GetBonePosition,ent,bone,ent_origin,angles)
	else
		pev(ent,pev_origin,ent_origin)

	origin[0] -= ent_origin[0]
	origin[1] -= ent_origin[1]
	origin[2] -= ent_origin[2]

	static Float:v_length
	v_length = vector_length(origin)

	static Float:aim_vector[3]
	aim_vector[0] = origin[0] / v_length
	aim_vector[1] = origin[1] / v_length
	aim_vector[2] = origin[2] / v_length

	static Float:new_angles[3]
	vector_to_angle(aim_vector,new_angles)

	new_angles[0] *= -1

	if(new_angles[1]>180.0) new_angles[1] -= 360
	if(new_angles[1]<-180.0) new_angles[1] += 360
	if(new_angles[1]==180.0 || new_angles[1]==-180.0) new_angles[1]=-179.999999

	set_pev(ent,pev_angles,new_angles)
	set_pev(ent,pev_fixangle,1)

	return 1;
}



/*
*
*  If "origin" is in ent's viewcone, the location
*  of it using the hudmessage grid will be placed
*  into hudpos[2].
*
*  Returns 0 if "origin" is not on ent's hud.
*
*  ent must be a player (index 1-32).
*
*/

stock get_hudmessage_locs(ent,const Float:origin[3],Float:hudpos[2])
{
	if(!is_user_connected(ent))
		return 0;

	static Float:origin2[3]
	origin2[0] = origin[0]
	origin2[1] = origin[1]
	origin2[2] = origin[2]

	static Float:ent_origin[3]

	pev(ent,pev_origin,ent_origin)

	static Float:ent_angles[3]

	pev(ent,pev_v_angle,ent_angles)

	origin2[0] -= ent_origin[0]
	origin2[1] -= ent_origin[1]
	origin2[2] -= ent_origin[2]

	new Float:v_length
	v_length = vector_length(origin2)

	static Float:aim_vector[3]
	aim_vector[0] = origin2[0] / v_length
	aim_vector[1] = origin2[1] / v_length
	aim_vector[2] = origin2[2] / v_length

	static Float:new_angles[3]
	vector_to_angle(aim_vector,new_angles)

	new_angles[0] *= -1

	if(new_angles[1]>180.0) new_angles[1] -= 360.0
	if(new_angles[1]<-180.0) new_angles[1] += 360.0
	if(new_angles[1]==180.0 || new_angles[1]==-180.0) new_angles[1]=-179.999999

	if(new_angles[0]>180.0) new_angles[0] -= 360.0
	if(new_angles[0]<-180.0) new_angles[0] += 360.0
	if(new_angles[0]==90.0) new_angles[0]=89.999999
	else if(new_angles[0]==-90.0) new_angles[0]=-89.999999

	new Float:fov
	pev(ent,pev_fov,fov)

	if(!fov)
		fov = 90.0

	if(floatabs(ent_angles[0] - new_angles[0]) <= fov/2 && floatabs((180.0 - floatabs(ent_angles[1])) - (180.0 - floatabs(new_angles[1]))) <= fov/2)
	{
		hudpos[1] = 1 - ( ( (ent_angles[0] - new_angles[0]) + fov/2 ) / fov )
		hudpos[0] = ( (ent_angles[1] - new_angles[1]) + fov/2 ) / fov
	}
	else
		return 0;

	return 1;
}



/*
*
*  Sets ent's speed in the direction specified
*  by the mode variable
*
*  Modes:
*   0 = In direction ent is currently moving
*        but not including the z axis
*   1 = In direction ent is currently moving
*   2 = In direction ent is currently looking
*   3 = In direction ent is currently looking
*        but not including the z axis
*   4 = In direction of origin[3]
*
*
*  Use a negative speed to go in the opposite
*  direction of the specified mode.
*
*/

stock set_speed(ent,Float:speed,mode=0,const Float:origin[3]={0.0,0.0,0.0})
{
	if(!pev_valid(ent))
		return 0;

	switch(mode)
	{
		case 0:
		{
			static Float:cur_velo[3]

			pev(ent,pev_velocity,cur_velo)

			new Float:y
			y = cur_velo[0]*cur_velo[0] + cur_velo[1]*cur_velo[1]

			new Float:x
			if(y) x = floatsqroot(speed*speed / y)

			cur_velo[0] *= x
			cur_velo[1] *= x

			if(speed<0.0)
			{
				cur_velo[0] *= -1
				cur_velo[1] *= -1
			}

			set_pev(ent,pev_velocity,cur_velo)
		}
		case 1:
		{
			static Float:cur_velo[3]

			pev(ent,pev_velocity,cur_velo)

			new Float:y
			y = cur_velo[0]*cur_velo[0] + cur_velo[1]*cur_velo[1] + cur_velo[2]*cur_velo[2]

			new Float:x
			if(y) x = floatsqroot(speed*speed / y)

			cur_velo[0] *= x
			cur_velo[1] *= x
			cur_velo[2] *= x

			if(speed<0.0)
			{
				cur_velo[0] *= -1
				cur_velo[1] *= -1
				cur_velo[2] *= -1
			}

			set_pev(ent,pev_velocity,cur_velo)
		}
		case 2:
		{
			static Float:vangle[3]
			if(ent<=get_maxplayers()) pev(ent,pev_v_angle,vangle)
			else pev(ent,pev_angles,vangle)

			static Float:new_velo[3]

			angle_vector(vangle,1,new_velo)

			new Float:y
			y = new_velo[0]*new_velo[0] + new_velo[1]*new_velo[1] + new_velo[2]*new_velo[2]

			new Float:x
			if(y) x = floatsqroot(speed*speed / y)

			new_velo[0] *= x
			new_velo[1] *= x
			new_velo[2] *= x

			if(speed<0.0)
			{
				new_velo[0] *= -1
				new_velo[1] *= -1
				new_velo[2] *= -1
			}

			set_pev(ent,pev_velocity,new_velo)
		}
		case 3:
		{
			static Float:vangle[3]
			if(ent<=get_maxplayers()) pev(ent,pev_v_angle,vangle)
			else pev(ent,pev_angles,vangle)

			static Float:new_velo[3]

			pev(ent,pev_velocity,new_velo)

			angle_vector(vangle,1,new_velo)

			new Float:y
			y = new_velo[0]*new_velo[0] + new_velo[1]*new_velo[1]

			new Float:x
			if(y) x = floatsqroot(speed*speed / y)

			new_velo[0] *= x
			new_velo[1] *= x

			if(speed<0.0)
			{
				new_velo[0] *= -1
				new_velo[1] *= -1
			}

			set_pev(ent,pev_velocity,new_velo)
		}
		case 4:
		{
			static Float:origin1[3]
			pev(ent,pev_origin,origin1)

			static Float:new_velo[3]

			new_velo[0] = origin[0] - origin1[0]
			new_velo[1] = origin[1] - origin1[1]
			new_velo[2] = origin[2] - origin1[2]

			new Float:y
			y = new_velo[0]*new_velo[0] + new_velo[1]*new_velo[1] + new_velo[2]*new_velo[2]

			new Float:x
			if(y) x = floatsqroot(speed*speed / y)

			new_velo[0] *= x
			new_velo[1] *= x
			new_velo[2] *= x

			if(speed<0.0)
			{
				new_velo[0] *= -1
				new_velo[1] *= -1
				new_velo[2] *= -1
			}

			set_pev(ent,pev_velocity,new_velo)
		}
		default: return 0;
	}
	return 1;
}



/*
*
*  Determines if 2 floats are within "difference"
*  between eachother.
*
*  Example: 2.0 is within 5.0 "difference" of 7.0
*
*/

stock is_within_difference(Float:number1,Float:number2,Float:difference)
{
	if(floatabs(number2 - number1) <= difference)
		return 1;

	return 0;
}



/*
*
*  Determines if point[2] is inside of polygon[20][2].
*  Returns 1 if it is and 0 if it isn't.
*
*  Any polygon of any shape can be put into the polygon
*  array. MAX_SIDES define has to be changed for more
*  than 20 sides.
*
*  numsides if the number of sides put into polygon[20][2].
*
*  Example Usage:
*
*  new Float:square[MAX_SIDES][2], Float:point[2]
*  point[0] = 0.0
*  point[1] = 0.0
*
*  //4 sides are made up between the 4 points.
*  //The sides make up a square if you connect
*  //the points.
*  square[0][0] = 10.0
*  square[0][1] = 10.0
*  square[1][0] = 10.0
*  square[1][1] = -10.0
*  square[2][0] = -10.0
*  square[2][1] = -10.0
*  square[3][0] = -10.0
*  square[3][1] = 10.0
*
*  //will return 1 because (0,0) is
*  //inside the polygon made by the array.
*  is_inside(point,square,4)
*
*/

#define MAX_SIDES	20

stock is_inside(const Float:point[2],const Float:polygon[MAX_SIDES][2],numsides)
{
	if(numsides>MAX_SIDES || numsides<3)
		return 0;

	new num, Float:slope1, Float:slope2, Float:x, Float:y, i2

	if(point[0]==100.0)
		slope2 = (point[1] - 100.0) / 0.000001
	else
		slope2 = (point[1] - 100.0) / (point[0] - 100.00)

	for(new i=0;i<numsides;i++)
	{
		i2 = i+1
		if(i2==numsides) i2=0

		if(polygon[i][0]==polygon[i2][0]) polygon[i2][0] += 0.1

		slope1 = (polygon[i][1] - polygon[i2][1]) / (polygon[i][0] - polygon[i2][0])

		if(slope1!=slope2)
		{
			x=(polygon[i][1] + slope2*point[0] - point[1] - slope1*polygon[i][0]) / (slope2 - slope1)
			y = slope2*(x - point[0]) + point[1]
			if(
			!(y>polygon[i][1] && y>polygon[i2][1]) &&
			!(y<polygon[i][1] && y<polygon[i2][1]) &&
			!(x>polygon[i][0] && x>polygon[i2][0]) &&
			!(x<polygon[i][0] && x<polygon[i2][0]) &&
			!(x==polygon[i][0] && y==polygon[i][1]) &&
			(x>point[0])
			)
			{
				num++
			}
		}
	}

	new Float:num2 = float(num) / 2.0

	if(num2==float(floatround(num2))) return 0;

	return 1;
}



/*
*
*  Returns the distance origin[3] is at its closest
*  location to the line drawn from start[3] to end[3]
*
*  &is_visible is filled with 1 if origin[3] is visible
*  by the line at its nearest point, 0 if it is not
*
*/

stock Float:distance_from_line(Float:start[3],Float:end[3],Float:origin[3],&is_visible)
{
	new Float:deltas[3]
	deltas[0] = (start[1] - end[1]) / (start[0] - end[0])
	deltas[1] = (start[2] - end[2]) / (start[1] - end[1])
	deltas[2] = (start[1] - end[1]) / (start[2] - end[2])

	static Float:origin2[3]
	origin2[2] = origin[2]
	origin2[1] = (deltas[2] * (origin2[2] - start[2])) + start[1]
	origin2[0] = ((deltas[0] * start[0]) + origin2[1] - start[1]) / deltas[0]

	static Float:hit[3]
	engfunc(EngFunc_TraceLine,origin,origin2,1,0,0)
	get_tr2(0,TR_vecEndPos,hit)
	if(hit[0]==origin2[0] && hit[1]==origin2[1] && hit[2]==origin2[2])
		is_visible = 1
	else
		is_visible = 0
		

	return get_distance_f(origin,origin2)
}