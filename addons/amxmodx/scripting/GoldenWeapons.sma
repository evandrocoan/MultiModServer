/** AMX Mod script
* 
*  This program is free software; you can redistribute it and/or modify it
*  under the terms of the GNU General Public License as published by the
*  Free Software Foundation; either version 2 of the License, or (at
*  your option) any later version.
*
*  This program is distributed in the hope that it will be useful, but
*  WITHOUT ANY WARRANTY; without even the implied warranty of
*  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU 
*  General Public License for more details.
*
*/

#include <amxmodx>
#include <fakemeta>
#include <fun>
#include <cstrike>
#include <engine>
#include <amxmisc>
#include <hamsandwich>

#define is_valid_player(%1) (1 <= %1 <= 32)

new AK47_V_MODEL[64] = "models/golden/v_ak47.mdl"
new AK47_P_MODEL[64] = "models/golden/p_ak47.mdl"

new M4A1_V_MODEL[64] = "models/golden/v_m4a1.mdl"
new M4A1_P_MODEL[64] = "models/golden/p_m4a1.mdl"

new MP5_V_MODEL[64] = "models/golden/v_mp5.mdl"
new MP5_P_MODEL[64] = "models/golden/p_mp5.mdl"

new ZOOM_WEAPON_SOUND[64] = "weapons/zoom.wav"

new g_Menu
new g_weapon_cost = 16000
new g_weapon_damage

new bool:g_hasSpecialWeapon[33] = {false, ...}
new bool:g_hasZoom[ 33 ] = {false, ...}

new gp_cvar_dmg

const Wep_ak47 = ((1<<CSW_AK47))

public plugin_init()
{
    // Register The Plugin
    register_plugin("Golden Weapons", "0.1", "Addons zz")

    /* CVARS */
    gp_cvar_dmg = register_cvar("amx_goldendmg", "5")

    g_Menu = register_menuid("Silver Weapons")
    register_menucmd(g_Menu, 1023, "silvermenu")

    // Register The Buy Cmd
    register_clcmd("say /goldenak", "showmenu")
    register_clcmd("say /silvermenu", "showmenu")
    register_clcmd("say /akdemonio", "showmenu")
    register_clcmd("say /coltdemonio", "showmenu")
    register_clcmd("say akdemonio", "showmenu")
    register_clcmd("say coltdemonio", "showmenu")
    
    register_event("DeathMsg", "Death", "a")
    register_event("WeapPickup","weapPickupEvent","b","1=19")
    register_event("CurWeapon","curWeaponEvent","be","1=1")
    //register_event("TextMsg", "event_game_commencing", "a", "2=#Game_Commencing", "2=#Game_will_restart_in");

    register_forward( FM_CmdStart, "giveAugZoomForward" )

    RegisterHam(Ham_TakeDamage, "player", "fw_takedamage", 0)
}

public plugin_cfg()
{
    g_weapon_damage = get_pcvar_num( gp_cvar_dmg )
}

/**
 * There are 3 specials weapons, buy one of then you win it, but if you normally 
 *   bought another special weapons, you win that normal weapon as a special one
 * This is done to avoid extra conditional expressions then reduce processor use.
 */
public fw_takedamage(victim, inflictor, attacker, Float:damage)
{
    if( g_hasSpecialWeapon[attacker] )
    {
        SetHamParamFloat(4, damage * g_weapon_damage )
        return true
    }
    return false
}

public showmenu(id) 
{
    new menu[512]

    format(menu, 511, "\rSilver Weapons\w^n^n1. Buy Silver AK           \
            \y($%i)\w^n2. Buy Silver M4A1       \
            \y($%i)\w^n3. Buy Silver MP5         \
            \y($%i)\w^n^n0. Exit^n", g_weapon_cost, g_weapon_cost, g_weapon_cost )

    new keys = (1<<0|1<<1|1<<2|1<<9)
    show_menu(id, keys, menu, -1, "Silver Weapons")
}

public silvermenu( id, key ) 
{
    if ( !is_user_alive(id) )
    {
        client_print(id,print_chat, "[AMXX] To buy golden weapons, you need to be alive!")
        return PLUGIN_HANDLED
    }
    new money = cs_get_user_money(id)

    if( money >= g_weapon_cost)
    { 
        switch(key) 
        {
            case 0: 
            {
                drop_prim(id) 
                
                g_hasSpecialWeapon[id] = true

                new playerWeapon[32]
                copy(playerWeapon, charsmax(playerWeapon), "weapon_ak47")

                give_item(id, playerWeapon)
                give_item(id, playerWeapon)
                engclient_cmd(id, playerWeapon) 
                engclient_cmd(id, playerWeapon)
                engclient_cmd(id, playerWeapon)
            }
            case 1: 
            {
                drop_prim(id) 

                g_hasSpecialWeapon[id] = true

                new playerWeapon[32]
                copy(playerWeapon, charsmax(playerWeapon), "weapon_m4a1")

                give_item(id, playerWeapon)
                give_item(id, playerWeapon)
                engclient_cmd(id, playerWeapon) 
                engclient_cmd(id, playerWeapon)
            }
            case 2: 
            {
                drop_prim(id) 

                g_hasSpecialWeapon[id] = true

                new playerWeapon[32]
                copy(playerWeapon, charsmax(playerWeapon), "weapon_mp5navy")

                give_item(id, playerWeapon)
                give_item(id, playerWeapon)
                engclient_cmd(id, playerWeapon) 
                engclient_cmd(id, playerWeapon)
                engclient_cmd(id, playerWeapon)
            }
            default: return PLUGIN_HANDLED
        }
        cs_set_user_money( id, money - g_weapon_cost )
        weapPickupEvent( id )

    } else
    {
        client_print( id, print_chat, "[AMXX] You do not have enough money to buy Golden Weapons. Cost $%d ", g_weapon_cost )
    }
    return PLUGIN_HANDLED
}

public client_connect(id)
{
    g_hasSpecialWeapon[id] = false
}

public event_game_commencing()
{
    arrayset(g_hasSpecialWeapon, false, sizeof(g_hasSpecialWeapon) )
}

public client_disconnect(id)
{
    g_hasSpecialWeapon[id] = false
}

public Death()
{
    new id = read_data(2)

    g_hasSpecialWeapon[id] = false
}

public plugin_precache()
{
    precache_model(AK47_V_MODEL)
    precache_model(AK47_P_MODEL)

    precache_model(M4A1_V_MODEL)
    precache_model(M4A1_P_MODEL)

    precache_model(MP5_V_MODEL)
    precache_model(MP5_P_MODEL)

    precache_sound(ZOOM_WEAPON_SOUND)
}

/**
 * When a player pickup a weapon, its change the model view to the Golden Weapon.
 */
public weapPickupEvent(id)
{
    if( g_hasSpecialWeapon[id] )
    {
        new szWeapID = read_data(2)

        switch( szWeapID )
        {
            case CSW_AK47: 
            {
                set_pev(id, pev_viewmodel2, AK47_V_MODEL)
                set_pev(id, pev_weaponmodel2, AK47_P_MODEL)
            } 
            case CSW_M4A1: 
            {
                set_pev(id, pev_viewmodel2, M4A1_V_MODEL)
                set_pev(id, pev_weaponmodel2, M4A1_P_MODEL)
            } 
            case CSW_MP5NAVY: 
            {
                set_pev(id, pev_viewmodel2, MP5_V_MODEL)
                set_pev(id, pev_weaponmodel2, MP5_P_MODEL)
            }
        }
    }
    return PLUGIN_HANDLED
}

/**
 * This message updates the numerical magazine ammo count and the corresponding ammo 
 *    type icon on the HUD.
 */
public curWeaponEvent(id)
{
    weapPickupEvent(id)

    return PLUGIN_HANDLED
}

/**
 * Added 'aug' zoom to the Golden Weapons.
 */
public giveAugZoomForward( id, uc_handle, seed )
{
    if( !is_user_alive( id ) ) 
    {
        return PLUGIN_HANDLED
    }
    
    if( ( get_uc( uc_handle, UC_Buttons ) & IN_ATTACK2 ) && !( pev( id, pev_oldbuttons ) & IN_ATTACK2 ) )
    {
        new szClip, szAmmo
        new szWeapID = get_user_weapon( id, szClip, szAmmo )
        
        if( szWeapID == CSW_AK47 && g_hasSpecialWeapon[id] && !g_hasZoom[id] )
        {
            g_hasZoom[id] = true
            cs_set_user_zoom( id, CS_SET_AUGSG552_ZOOM, 0 )
            emit_sound( id, CHAN_ITEM, ZOOM_WEAPON_SOUND, 0.20, 2.40, 0, 100 )

        } else if ( szWeapID == CSW_AK47 && g_hasSpecialWeapon[id] && g_hasZoom[id])
        {
            g_hasZoom[ id ] = false 
            cs_set_user_zoom( id, CS_RESET_ZOOM, 0 )
        }
    }
    return PLUGIN_HANDLED
}

stock drop_prim(id) 
{
    new weapons[32], num
    get_user_weapons(id, weapons, num)

    for (new i = 0; i < num; i++) 
    {
        if ( Wep_ak47 & (1<<weapons[i]) ) 
        {
            static wname[32]
            get_weaponname(weapons[i], wname, sizeof wname - 1)
            engclient_cmd(id, "drop", wname)
        }
    }
}
