#include <amxmodx>
#include <engine>

public plugin_init() {
	register_plugin("rotate_fix_EN","1.2","NL)Ramon(NL")
	if(!is_linux_server()) 
	{
		pause("ad")
		server_print("The func_rotating fix plugin is for linux servers ONLY. Operations aborted.")
		return PLUGIN_CONTINUE
	}
	if(find_ent_by_class(-1, "func_rotating") != 0)
		set_task(10.0,"fix_bug",0,"",0,"b")
	return PLUGIN_CONTINUE
}

public fix_bug() {
	new f_rota = find_ent_by_class(-1, "func_rotating")
	while(f_rota != 0)
	{
		new Float:angles[3]
		entity_get_vector(f_rota,EV_VEC_angles,angles)
		angles[0] -= floatround(angles[0] / 360.0,floatround_floor) * 360.0
		angles[1] -= floatround(angles[1] / 360.0,floatround_floor) * 360.0
		angles[2] -= floatround(angles[2] / 360.0,floatround_floor) * 360.0
		entity_set_vector(f_rota,EV_VEC_angles,angles)
		f_rota = find_ent_by_class(f_rota, "func_rotating") 
	} 
	
}
