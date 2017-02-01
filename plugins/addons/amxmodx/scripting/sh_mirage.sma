#include <amxmod>
#include <superheromod>

// Mirage - made by Mydas

// CVARS
// mirage_level 3
// mirage_fadetime 0.5 - time it takes for him to become invisible
// mirage_invistime 3  - how long will he stay invis
// mirage_cooldown 5   - how long till he will invis again

// GLOBAL VARIABLES
new gHeroName[]="Mirage"
new bool:gHasMiragePowers[SH_MAXSLOTS+1]

public plugin_init() {
  // Plugin Info
  register_plugin("SUPERHERO Mirage","1.0","Mydas")

  register_cvar("mirage_level", "3" )
  register_cvar("mirage_fadetime", "0.5")
  register_cvar("mirage_invistime", "3")
  register_cvar("mirage_cooldown", "5")

  // FIRE THE EVENT TO CREATE THIS SUPERHERO!
  shCreateHero(gHeroName, "Delusion", "Turn invisible for a short time when someone aims at you", false, "mirage_level" )

  // REGISTER EVENTS THIS HERO WILL RESPOND TO! (AND SERVER COMMANDS)
  register_srvcmd("mirage_init", "mirage_init")
  shRegHeroInit(gHeroName, "mirage_init")

  register_srvcmd("mirage_loop", "mirage_loop")
  set_task(0.1,"mirage_loop",0,"",0,"b")

}

public mirage_init() {
  new temp[6]
  read_argv(1,temp,5)
  new id=str_to_num(temp)
  read_argv(2,temp,5)
  new hasPowers=str_to_num(temp)
  gHasMiragePowers[id]=(hasPowers!=0)
}

public mirage_loop()
{
	new parm[2],i
	for ( new id=1; id<=SH_MAXSLOTS; id++ ) if (gHasMiragePowers[id]&&is_user_alive(id)) 
	{
		for (new enemy=1;enemy<=SH_MAXSLOTS;enemy++) 
		{
			if (is_user_alive(enemy) && get_user_team(enemy)!=get_user_team(id) && !gPlayerUltimateUsed[id]) 
			{
				new aid,abody
				get_user_aiming(enemy,aid,abody)
				if (aid==id) {
					parm[0]=id
					ultimateTimer(id, get_cvar_num("mirage_cooldown") * 1.0)
					for(i=1; i<=floatround(get_cvar_float("mirage_fadetime")*10); i++) {
						parm[1]=i
						set_task(i*0.1,"turn_invis",i*100+id,parm,2)
					}
					return PLUGIN_CONTINUE
				}
			}
		}
	}
	return PLUGIN_CONTINUE
}

public turn_invis(parm[])
{
	new id=parm[0], step=parm[1]
	set_user_rendering(id,kRenderFxGlowShell,8,8,8,kRenderTransAlpha,
		255-floatround(step*(25.5/get_cvar_float("mirage_fadetime"))))
	set_task(get_cvar_float("mirage_invistime"),"remove_invis",step*100+50+id,parm,2)
	if (step==floatround(get_cvar_float("mirage_fadetime")*10)) 
	client_print(id,print_chat,"-Turned invisible-")
	return PLUGIN_CONTINUE
}

public remove_invis(parm[])
{
	new id=parm[0], step=parm[1]
	set_user_rendering(id,kRenderFxGlowShell,0,0,0,kRenderTransAlpha,
		floatround(step*(25.5/get_cvar_float("mirage_fadetime"))))
	if (step==floatround(get_cvar_float("mirage_fadetime")*10)) 
	client_print(id,print_chat,"-Visible again-")
	return PLUGIN_CONTINUE
}