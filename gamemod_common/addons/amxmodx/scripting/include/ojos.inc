
#if defined _engine_included

	#define DISPATCH_KEYVALUE(%1,%2,%3)	DispatchKeyValue(%1,%2,%3) 
	
	#define SET_INT(%1,%2,%3)   	entity_set_int(%1,EV_INT_%2,%3)
	#define GET_INT(%1,%2)			entity_get_int(%1, EV_INT_%2)
	#define SET_FLOAT(%1,%2,%3)		entity_set_float(%1,EV_FL_%2,%3)
	#define GET_FLOAT(%1,%2)		entity_get_float(%1,EV_FL_%2)
	#define SET_VECTOR(%1,%2,%3) 	entity_set_vector(%1,EV_VEC_%2,%3) 
	#define GET_VECTOR(%1,%2,%3)	entity_get_vector(%1,EV_VEC_%2,%3)
	#define SET_EDICT(%1,%2,%3) 	entity_set_edict(%1,EV_ENT_%2,%3)
	#define GET_EDICT(%1,%2,%3) 	entity_get_edict(%1,EV_ENT_%2,%3)
	#define SET_STRING(%1,%2,%3)	entity_set_string(%1,EV_SZ_%2,%3)
	#define GET_STRING(%1,%2,%3,%4)	entity_get_string(%1,EV_SZ_%2,%3,%4)
	
	#define FIND_ENT_BY_CLASS(%1,%2)	find_ent_by_class(%1,%2)
	
	#define IS_VALID_ENT(%1)	is_valid_ent(%1)
	#define CREATE_ENTITY(%1)	create_entity(%1)
	#define REMOVE_ENTITY(%1)	remove_entity(%1)
	#define SET_MODEL(%1,%2)	entity_set_model(%1,%2)
	#define MDLL_SPAWN(%1)		DispatchSpawn(%1)
	#define THINK(%1,%2)		register_think(%1,%2)
	#define FAKE_TOUCH(%1,%2)	fake_touch(%1,%2)
	#define POINTCONTENTS(%1)	point_contents(%1)
	#define TRACE_LINE(%1,%2,%3,%4)	trace_line(%1,%2,%3,%4)
	
#else
	//Make sure its loaded
	#if !defined _fakemeta_included
		#include <fakemeta>
	#endif
	
	stock DISPATCH_KEYVALUE(idEntity,szKeyName[],szValue[]) {
		set_kvd(0,KV_KeyName,szKeyName)
		set_kvd(0,KV_Value,szValue)
		set_kvd(0,KV_fHandled,0)
		return dllfunc(DLLFunc_KeyValue,idEntity,0)	
	}

	#define SET_INT(%1,%2,%3)   	set_pev(%1,pev_%2,%3)
	#define GET_INT(%1,%2)			pev(%1,pev_%2)
	#define SET_FLOAT(%1,%2,%3)		set_pev(%1,pev_%2,%3)
	#define GET_FLOAT(%1,%2)		pev(%1,pev_%2)
	#define SET_VECTOR(%1,%2,%3) 	set_pev(%1,pev_%2,%3) 
	#define GET_VECTOR(%1,%2,%3)	pev(%1,pev_%2,%3)
	#define SET_EDICT(%1,%2,%3) 	set_pev(%1,pev_%2,%3) 
	#define GET_EDICT(%1,%2,%3) 	pev(%1,pev_%2,%3) 
	#define SET_STRING(%1,%2,%3)	set_pev(%1,pev_%2,%3)
	#define GET_STRING(%1,%2,%3,%4)	pev(%1,pev_%2,%3,%4)
	
	#define FIND_ENT_BY_CLASS(%1,%2)	engfunc(EngFunc_FindEntityByString,%1,"classname",%2)
	
	#define IS_VALID_ENT(%1)		pev_valid(%1)
	#define CREATE_ENTITY(%1)		engfunc(EngFunc_CreateNamedEntity,engfunc(EngFunc_AllocString,%1))
	#define REMOVE_ENTITY(%1)		engfunc(EngFunc_RemoveEntity,%1)
	#define SET_MODEL(%1,%2)		engfunc(EngFunc_SetModel,%1,%2)
	#define MDLL_SPAWN(%1)			dllfunc(DLLFunc_Spawn,%1)
	#define THINK(%1,%2)			register_forward(FM_Think,%2)
	#define FAKE_TOUCH(%1,%2)		dllfunc(DLLFunc_Touch,%1,%2)
	#define POINTCONTENTS(%1)		engfunc(EngFunc_PointContents,%1)
	#define TRACE_LINE(%1,%2,%3,%4)	engfunc(EngFunc_TraceLine,%1,%2,%3,%4)
#endif

#define NEXTTHINK(%1,%2)	SET_FLOAT(%1,nextthink,get_gametime()+%2)
#define GET_ORIGIN(%1,%2)	GET_VECTOR(%1,origin,%2)
#define SET_VISIBILE(%1,%2)	SET_INT(%1,effects,%2==1?GET_INT(%1,effects)&~EF_NODRAW:GET_INT(%1,effects)|EF_NODRAW)

stock FAKE_DAMAGE(idvictim,szClassname[],Float:takedmgdamage,damagetype)
{
	new entity = CREATE_ENTITY("trigger_hurt")
	if (entity)
	{
		new szDamage[16]
		format(szDamage,15,"%f",takedmgdamage * 2)
		DISPATCH_KEYVALUE(entity,"dmg",szDamage)
		format(szDamage,15,"%i",damagetype)
		DISPATCH_KEYVALUE(entity,"damagetype",szDamage)
		MDLL_SPAWN(entity)
		SET_STRING(entity,classname,szClassname)
		FAKE_TOUCH(entity,idvictim)
		REMOVE_ENTITY(entity)
		return 1
	}
	return 0
}

