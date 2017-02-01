/* 
 Glow Damage v0.1.0
 
* Details : Makes players glow when damage. 

* Cvars: 
glowdamage_type 1/2
1= Random Colors
2= Colors in function by user team : Terro Team and CT Team and if Damage > 15 have some colors,
else if damage > 40 have another colors, etc

* Tests:
- Tested on CS 1.6 with AMXMODX 1.76b

* Required Modules
- Fun & Cstrike

* Credits:
- Doombringer for an fixed on CS Teams 
- MaximusBrood for if conditions fixes

Have a nice day now
*/

#include <amxmodx>
#include <fun>
#include <cstrike>
 
new const PLUGIN[] = "Glow Damage"
new const VERSION[] = "0.1.0"
new const AUTHOR[] = "SAMURAI"
 
new pcvartype;
 
public plugin_init() 
{
        register_plugin(PLUGIN, VERSION, AUTHOR)
        pcvartype = register_cvar("glowdamage_type","1")
        register_event("Damage","glow_event","b","2!0","3=0","4!0")
         
}
 

 
public glow_event()
{
        new r,g,b
 
        new Victim = read_data(0)
        new Damage = get_user_health(Victim)
 
        new CsTeams:playert = cs_get_user_team(Victim)
 
        switch (get_pcvar_num(pcvartype))
        {
                case 1:
                {
                        // random num for r,g,b colors
                        r = random_num(0,255)
                        g = random_num(0,255)
                        b = random_num(0,255)
                }
        
                case 2:
                {
                        // if is user from Terro team
                        if(playert == CS_TEAM_T)
                        {
                            if (Damage < 15)
                            {
                                r = 255
                                g = 80
                                b = 0
                            } else if(Damage > 40)
                            {
                                r = 255
                                g = 0
                                b = 0
                            } else
                            {
                                r = 200
                                g = 70
                                b = 0
                            }
                        } else
                        {
                            if(Damage <= 15)
                            {
                                r = 23
                                g = 243
                                b = 0
                            } else if(Damage >= 40)
                            {
                                r = 0
                                g = 255
                                b = 0 
                            } else
                            {
                                r = 0
                                g = 65
                                b = 12
                            }
                        }
                }
        }
        
        playerglow(Victim,r,g,b)
 
        return PLUGIN_HANDLED
} 

public playerglow(player,r,g,b)
{
    new Params[1]
    Params[0] = player    
    set_user_rendering(player,kRenderFxGlowShell,r,g,b,kRenderNormal,25)
    set_task(1.0,"stopglow",0,Params,1);
                      
}

public stopglow(Params[])
{
    if( !is_user_connected(Params[0]) )
        return PLUGIN_HANDLED;
    
    set_user_rendering(Params[0],kRenderFxGlowShell,0,0,0,kRenderNormal,25)
    return PLUGIN_CONTINUE;
}
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1033\\ f0\\ fs16 \n\\ par }
*/
