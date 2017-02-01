// Ivan's Advanced Tracer Plugin 0.25 by Ivan <-g-s-ivan@web.de>
// Basing on the original Tracer Script by OLO

/*
Changelog from 0.1 to 0.25

* Added check for CS, now when firing tracers will go to the hitpoint, not the aimpoint
* Added Adminclientcommands for setting Tracers, amx_settracers & amx_setamplitude
* Renamed CVAR amx_ln to amx_tracers_ln
* Lightning Tracers won't start in the middle of your screen anymore (now they come from the lower end - isn't that nasty to look at)
* Now the last shot in mag makes tracers too.
* Some Speed/CPU usage tweaks.
* Better compatibilty with other Mods.

*/

// VERY VERY CPU optimized version.

#include <amxmodx>

#define SHOTGUN_AIMING 32

new light;

new tracers, ln, is_cs = 0;

lightning(vec1[3],vec2[3])
{
    //Lightning
    message_begin( MSG_BROADCAST,SVC_TEMPENTITY);
    write_byte( 0 );
    write_coord(vec1[0]);
    write_coord(vec1[1]);
    write_coord(vec1[2]);
    write_coord(vec2[0]);
    write_coord(vec2[1]);
    write_coord(vec2[2]);
    write_short( light );
    write_byte( 1 ); // framestart
    write_byte( 5 ); // framerate
    write_byte( 2 ); // life
    write_byte( 20 ); // width
    //write_byte( 30 ); // noise
    write_byte(ln);
    write_byte( 200 ); // r, g, b
    write_byte( 200 ); // r, g, b
    write_byte( 200 ); // r, g, b
    write_byte( 200 ); // brightness
    write_byte( 200 ); // speed
    message_end();

}

tracer(vec1[3],vec2[3]) {
    message_begin(MSG_PAS, SVC_TEMPENTITY,vec1 );
    write_byte( 6 ) /* TE_TRACER - see commo/const.h in HLSDK */
    write_coord(vec1[0]);
    write_coord(vec1[1]);
    write_coord(vec1[2]);
    write_coord(vec2[0]);
    write_coord(vec2[1]);
    write_coord(vec2[2]);
    message_end();
}

draw(vec1[3],vec2[3]) {
    if(tracers==1) {
        tracer(vec1,vec2);
    } else {
        lightning(vec1,vec2);
    }
}

new users_ammo[33];
new users_w[33]

public drawtracer(id)
{
    if(tracers==0) {
        return PLUGIN_HANDLED;
    }
    new ammo = read_data(3), weapon = read_data(2); // I read it only once to save CPU time.
    if(users_ammo[id]>ammo && ammo>=0 && users_w[id]==weapon) {

        new vec1[3], vec2[3];
        if(tracers == 2) {
            get_user_origin(id,vec1);
            vec1[2]+=8;
            // For lightnings we do it a special way, 'cause lightnings from eye positon look shit
        } else {
            get_user_origin(id,vec1,1);
        }
        if(is_cs==1) {
            get_user_origin(id,vec2,4);
        } else {
            get_user_origin(id,vec2,3);
        }
        if(is_cs == 1 && (weapon==CSW_M3 || weapon==CSW_XM1014)) { // Shotguns in CS
            draw(vec1,vec2);

            vec2[0]+=SHOTGUN_AIMING;
            draw(vec1,vec2);
            vec2[1]+=SHOTGUN_AIMING;
            draw(vec1,vec2);
            vec2[2]+=SHOTGUN_AIMING;
            draw(vec1,vec2);
            vec2[0]-=SHOTGUN_AIMING; // Repeated substraction is faster then multiplication !
            vec2[0]-=SHOTGUN_AIMING; // Repeated substraction is faster then multiplication !
            draw(vec1,vec2);
            vec2[1]-=SHOTGUN_AIMING; // Repeated substraction is faster then multiplication !
            vec2[1]-=SHOTGUN_AIMING; // Repeated substraction is faster then multiplication !
            draw(vec1,vec2);
            vec2[2]-=SHOTGUN_AIMING; // Repeated substraction is faster then multiplication !
            vec2[2]-=SHOTGUN_AIMING; // Repeated substraction is faster then multiplication !
            draw(vec1,vec2);
        } else {
            draw(vec1,vec2);
        }
        users_ammo[id]=ammo;
    } else {
        users_w[id]=weapon;
        users_ammo[id]=ammo;
    }
    return PLUGIN_HANDLED;
}


public checktracervars() {
    tracers = get_cvar_num("amx_tracers");
    ln = get_cvar_num("amx_tracers_ln");
}

public amx_settracers(id)
{
    new arg1[32];
    new nt;
    read_argv(1,arg1,32);
    nt = str_to_num(arg1);
    if(nt == 1) {
        client_print(id,print_console,"[AMX] Advanced Tracers> Tracer mode set to 1, Normal Tracers.");
    } else if(nt == 2) {
        client_print(id,print_console,"[AMX] Advanced Tracers> Tracer mode set to 2, Lightning Tracers.");
    } else if(nt==0 && equal(arg1,"0")) {
        client_print(id,print_console,"[AMX] Advanced Tracers> Tracer mode set to 0, No Tracers.");
    } else {
        client_print(id,print_console,"[AMX] Advanced Tracers> Please type 0, 1 or 2!");
        return PLUGIN_HANDLED;
    }
    tracers = nt;
    set_cvar_num("amx_tracers",tracers);
    return PLUGIN_HANDLED;
}

public amx_setamplitude(id)
{
    new arg1[32];
    new na;
    read_argv(1,arg1,32);
    na = str_to_num(arg1);
    if(na>=0) {
        client_print(id,print_console,"[AMX] Advanced Tracers> Amplitude for Lightning Tracers set to %d.",na);
        ln = na;
        set_cvar_num("amx_tracers_ln",ln);
    }
    return PLUGIN_HANDLED;
}

public plugin_precache()
{
    light = precache_model("sprites/lgtning.spr");
    return PLUGIN_CONTINUE;
}

public plugin_init()
{
    new modname[32];
    register_plugin("Advanced Tracers","0.1","-g-s-ivan@web.de");
    register_event("CurWeapon","drawtracer","be","1=1"); //,"3>=0");
    register_cvar("amx_tracers","1")
    register_cvar("amx_tracers_ln","30");
    register_concmd("amx_settracers","amx_settracers",ADMIN_LEVEL_A,"<0|1|2> Set tracer mode.");
    register_concmd("amx_setamplitude","amx_setamplitude",ADMIN_LEVEL_A,"<noise> Noise for lightning tracers.");
    set_task(5.0,"checktracervars",0,"",0,"b");
    checktracervars();
    get_modname(modname,32);
    if(equal(modname,"cstrike")) is_cs = 1;
    return PLUGIN_CONTINUE;
}