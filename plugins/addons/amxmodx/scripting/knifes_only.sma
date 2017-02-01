/*********************************************************************
AMX Mod Script
Created by BillyTheKid
Test it first @ 69.31.7.140:27016
Knifes Only
Version 0.9
Email = admin@madtechview

Commands -
amx_knifesonly <1|0> Default off

1 = on
0 = off

Client Command -
say /voteknifesonly
Starts a vote to turn knifes Only On and off...


Description - This will force users to knife only
              If guns are drawn they will be dropped


BugFixes    - Added Admin Level Access to the amx_knifesonly Command
  		  

Added - 	  A hud message to display who starts a vote

Thanks to Zaltoa @ Darkelite1776@yahoo.com
I used his code as a template to make this one 
*********************************************************************/

#include <amxmodx>
#include <amxmisc>


new knifeonly = 0
new choice[2]
new voteknifesonly[] = "\yKnifes Only?\w^n^n1. On^n2. Off"

public plugin_init(){
register_plugin("Knifes Only","0.1","BillyTheKid")
register_concmd("amx_knifesonly","cmdknifes_only",ADMIN_LEVEL_A,"- disable and enable knife war 1 = on 0 = off")
register_concmd("say voteknife","cmdvoteknifes_only",ADMIN_VOTE,"- Starts a vote for knifesonly")
register_concmd("amx_voteknifeonly","cmdvote",ADMIN_VOTE,"- Start a vote to turn knifes Only on or off")
register_menucmd(register_menuid("\yKnifes Only?"),(1<<0)|(1<<1),"count_votes")
register_event("CurWeapon","knife","b")
}

public cmdknifes_only(id){
   new arg[2]
   read_argv(1,arg,1)
   set_hudmessage(200, 100, 0, -1.0, 0.25, 0, 1.0, 5.0, 0.1, 0.2, 2)
   if(equal(arg,"1")){
   knifeonly = 1
   client_cmd(id,"weapon_knife")
   console_print(id,"Knifes Only has been turned on.")
   show_hudmessage(0,"Knifes Only has been turned on.")
   } else if(equal(arg,"0")){
   knifeonly = 0
   console_print(id,"Knifes Only has been turned off.")
   show_hudmessage(0,"Knifes Only has been turned off.")
   } else {
   if (knifeonly==0){
   console_print(id,"Usage: amx_knifesonly 1 = 0n 0 = off Currently: OFF")
   }
   if (knifeonly==1){
   console_print(id,"Usage: amx_knifesonly 1 = 0n 0 = off Currently: ON")
   }
   }
   return PLUGIN_CONTINUE
   }

public knife(id){
        if(knifeonly==0){
            //nothing
        }
        if(knifeonly==1){
            new clip, ammo
            new usersweapon = get_user_weapon(id,clip,ammo)
            client_cmd(id, "drop")
            if(usersweapon==CSW_KNIFE) {
                //nothing
            } else {
                client_cmd(id,"weapon_knife")
            }
        }
        return PLUGIN_CONTINUE
}

public cmdvote(id){
    new Float:voting = get_cvar_float("amx_last_voting")
    if (voting > get_gametime()){
        client_print(id,print_chat,"*A vote has already been cast.*")
        return PLUGIN_HANDLED
    }
    if (voting && voting + get_cvar_float("amx_vote_delay") > get_gametime()) {
        client_print(id,print_chat,"*Please wait awhile before you can vote again.*")
        return PLUGIN_HANDLED
    }
    new menu_msg[256]
    new name[32]
    format(menu_msg,255,voteknifesonly)
    new Float:votetime = get_cvar_float("amx_vote_time") + 10.0
    get_user_info(id, "name", name, 31)
    set_cvar_float("amx_last_voting",  get_gametime() + votetime )
    show_menu(0,(1<<0)|(1<<1),menu_msg,floatround(votetime))
    set_hudmessage(200, 0, 0, 0.05, 0.65, 2, 0.02, 30.0, 0.03, 0.3, 2)
		
    show_hudmessage(0, "%s has started the Vote for knifesonly",name)
    set_task(votetime,"check_the_votes")
    choice[0]=choice[1]=0
    return PLUGIN_HANDLED     
}

public cmdvoteknifes_only(id){
    new Float:voting = get_cvar_float("amx_last_voting")
    if (voting > get_gametime()){
        client_print(id,print_chat,"*A vote has already been cast.*")
        return PLUGIN_HANDLED
    }
    if (voting && voting + get_cvar_float("amx_vote_delay") > get_gametime()) {
        client_print(id,print_chat,"*Please wait awhile before you can vote again.*")
        return PLUGIN_HANDLED
    }
    new menu_msg[256]
    format(menu_msg,255,voteknifesonly)
    new Float:votetime = get_cvar_float("amx_vote_time") + 10.0
    set_cvar_float("amx_last_voting",  get_gametime() + votetime )
    show_menu(0,(1<<0)|(1<<1),menu_msg,floatround(votetime))
    set_task(votetime,"check_the_votes")
    client_print(0,print_chat,"*Voting has started.*")
    choice[0]=choice[1]=0
    return PLUGIN_HANDLED     
}


public count_votes(id,key){
    if (get_cvar_float("amx_vote_answers") ) {
        new name[32]
        get_user_name(id,name,31)
        client_print(0,print_chat,"* %s voted %s", name, key ? "against knifes only" : "for knifes only" )
    }
    ++choice[key]
    return PLUGIN_HANDLED
}

public check_the_votes(id){
    if (choice[0] > choice[1]){
        server_cmd("amx_knifesonly 1")
        client_print(0,print_chat,"* Votes For Knifes Only Succeded (yes ^"%d^") (no ^"%d^"). *",choice[0],choice[1])
    } else {
        server_cmd("amx_knifesonly 0")
        client_print(0,print_chat,"* Votes Against Knifes Only Succeded (yes ^"%d^") (no ^"%d^"). *",choice[0],choice[1])
    }
    return PLUGIN_CONTINUE
}