/* 
* AMXmodX script. 
* 
* 
*        Plugin : Headshot DeluXe vX.16.1.0
* 
* 
* This file is provided as is (no warranties). 
* Feel free to use it or modify it. 
* Report bugs at danrazor@yahoo.fr THX 
* 
* Author: DanRaZor 
* 
* Originally Based on : 
*    Ultimate Sounds by Hephos 
*    welcome HUDMsg by JustinHoMi 
*    lots from OLO 
* 
* THX. 
* 
*/ 

/* 
*  *** AMXx Code *** 
*/ 

/* Macros */ 

#define MAX_TXT_LEN   300 
#define MAX_TXT_LEN_1 299 

#define COEF_FEETS    12 
#define MAX_RANK      5 
#define MAX_STAT      4 

//#define DEBUG

/* Includes */ 

#include <amxmodx> 
#include <amxmisc> 

/* Global vars */ 

new killr = 0      /* describes current killer ( his id ) */
new vict  = 0      /* describes current victim ( his id ) */

new nbHS[33]       /* to store HS of players connected    */
new nbFrags[33]    /* to store frags of players connected */

new ranking[33]    /* Rankingtab : 32 players from 1 to 32 ( 0 not used ) */ 

/* Center Message Position/colors/Channel */

new HUD_COL[3]        = { 0,80,220 } 
new Float:HUD_POS[2]  = { -1.0,0.3 }
new HUD_CHN           = 10 

/* Stats Message Position/colors/Channel */

new HUD_COL2[3]       = { 0,80,220 } 
new Float:HUD_POS2[2] = { 0.0,0.2 }
new HUD_CHN2          = 9 

/* Default texts */

new titleMotd[30] = "    HEADSHOT : Rankings"  /* Title for top stats */
new textSup50[25] = "Unbelievable !!!"         /* when done 50 HS     */
new textSup20[25] = "Great !!!"                /* when done 20 HS     */
new textSup10[25] = "Good job !!!"             /* when done 10 HS     */
new textSup1[25]  = ""                         /* when done 1 HS      */
new textFirst[25] = "Your first Headshot"      /* when done first HS  */
new textHS[25]    = "Headshots"                /* basic Text          */
new textRank[25]  = "Rank :"                   /* basic Text          */
new textFrags[25] = "Frags"                    /* basic Text          */
new noHeadshot[50]= "No Headshot, try later"   /* basic Text          */

/* To store language version */

new langVersion = 0 

/* To store fun activation   */

new funVersion = 0 

/* Default values for hud, chat and wavs */ 

new hudAllCvar[MAX_TXT_LEN]  = "" 
new hudVicCvar[MAX_TXT_LEN]  = "Headshot by %killer%\nwith %weapon%" 
new hudKilCvar[MAX_TXT_LEN]  = "" 

new chatAllCvar[MAX_TXT_LEN] = "* %killer% made headshot on %victim% at %distance% m ( %distFeet% ft ) with %weapon%" 
new chatVicCvar[MAX_TXT_LEN] = "" 
new chatKilCvar[MAX_TXT_LEN] = "" 

new wavAllCvar[MAX_TXT_LEN]  = "misc/headshot" 
new wavVicCvar[MAX_TXT_LEN]  = "misc/ow" 
new wavKilCvar[MAX_TXT_LEN]  = "barney/ba_gotone"

/* Sizes of random sounds lists */

#define VIC_MAX   12 
#define KIL_MAX   17 

/* To Store last Random  message   */
/* and avoid to send twice a sound */

new lastMsgKil = -1 
new lastMsgVic = -1 

/* Random sounds for FUN version */

new listKilWav[KIL_MAX][] = { 
"barney/ba_another", 
"barney/ba_buttugly", 
"barney/ba_close", 
"barney/ba_endline", 
"barney/ba_firepl", 
"barney/ba_iwish", 
"barney/ba_later", 
"barney/ba_seethat", 
"barney/beertopside", 
"barney/c1a4_ba_octo1", 
"barney/checkwounds", 
"barney/diebloodsucker", 
"barney/realbadwound", 
"barney/somethingdied", 
"barney/somethingstinky", 
"barney/stench", 
"scientist/perfectday" 
} 

new listVicWav[VIC_MAX][] = { 
"barney/ba_dotoyou", 
"barney/ba_uwish", 
"barney/bigmess", 
"barney/c1a2_ba_4zomb", 
"barney/cantfigure", 
"barney/dontbuyit", 
"barney/guyresponsible", 
"barney/hitbad", 
"barney/imdead", 
"barney/iwaithere", 
"fvox/flatline", 
"scientist/recalculate" 
} 

/* Code */ 

/* Setting languages */ 

public set_english () { 
   langVersion = 0 
   copy ( titleMotd ,29 ,"    HEADSHOT : Rankings" ) 
   copy ( textSup50 ,24 ,"Unbelievable !!!" ) 
   copy ( textSup20 ,24 ,"Great !!!" ) 
   copy ( textSup10 ,24 ,"Good job !!!" ) 
   copy ( textSup1  ,24 ,"" ) 
   copy ( textFirst ,24 ,"Your first Headshot" ) 
   copy ( textHS    ,24 ,"Headshots" ) 
   copy ( textRank  ,24 ,"Rank :" ) 
   copy ( textFrags ,24 ,"Frags" ) 
   copy ( noHeadshot,49 ,"No Headshot, try later" ) 
   return PLUGIN_CONTINUE 
} 

public set_french () { 
   langVersion = 1 
   copy ( titleMotd ,29 ,"    HEADSHOT : Classement" ) 
   copy ( textSup50 ,24 ,"Incroyable !!!" ) 
   copy ( textSup20 ,24 ,"Bravo !!!" ) 
   copy ( textSup10 ,24 ,"Bien Joue !!!" ) 
   copy ( textSup1  ,24 ,"" ) 
   copy ( textFirst ,24 ,"Premier Headshot" ) 
   copy ( textHS    ,24 ,"Headshots" ) 
   copy ( textRank  ,24 ,"Classement :" ) 
   copy ( textFrags ,24 ,"Frags" ) 
   copy ( noHeadshot,49 ,"Pas de Headshot, essayer plus tard" ) 
   return PLUGIN_CONTINUE 
} 

public set_espagnol () { 
   langVersion = 2 
   copy ( titleMotd ,29 ,"    HEADSHOT : Clasificacion" ) 
   copy ( textSup50 ,24 ,"increible !!!" ) 
   copy ( textSup20 ,24 ,"Bravo !!!" ) 
   copy ( textSup10 ,24 ,"Bien jugado !!!" ) 
   copy ( textSup1  ,24 ,"" ) 
   copy ( textFirst ,24 ,"Tu primero Headshot" ) 
   copy ( textHS    ,24 ,"Headshots" ) 
   copy ( textRank  ,24 ,"clasificacion :" ) 
   copy ( textFrags ,24 ,"Frags" ) 
   copy ( noHeadshot,49 ,"No hay Headshot, intentar mas tarde" ) 
   return PLUGIN_CONTINUE 
} 

public set_portugues () { 
   langVersion = 3 
   copy ( titleMotd ,29 ,"    HEADSHOT : Classificaçao" ) 
   copy ( textSup50 ,24 ,"So visto !!!" ) 
   copy ( textSup20 ,24 ,"Bravo !!!" ) 
   copy ( textSup10 ,24 ,"Boa !!!" ) 
   copy ( textSup1  ,24 ,"" ) 
   copy ( textFirst ,24 ,"O teu primeiro Headshot" ) 
   copy ( textHS    ,24 ,"Headshots" ) 
   copy ( textRank  ,24 ,"classificacao :" ) 
   copy ( textFrags ,24 ,"Frags" ) 
   copy ( noHeadshot,49 ,"Nao houve Headshot, tentar mais tarde" ) 
   return PLUGIN_CONTINUE 
} 

public set_german () { 
   langVersion = 4 
   copy ( titleMotd ,29 ," HEADSHOT : Rangliste" ) 
   copy ( textSup50 ,24 ,"Unglaublich !!!" ) 
   copy ( textSup20 ,24 ,"Klasse !!!" ) 
   copy ( textSup10 ,24 ,"Gute Arbeit !!!" ) 
   copy ( textSup1  ,24 ,"" ) 
   copy ( textFirst ,24 ,"Dein erster Headshot" ) 
   copy ( textHS    ,24 ,"Headshots" ) 
   copy ( textRank  ,24 ,"Rang :" ) 
   copy ( textFrags ,24 ,"Frags" ) 
   copy ( noHeadshot,49 ,"Kein Headshot, versuchs spater" ) 
   return PLUGIN_CONTINUE 
} 

public set_language ( id , level, cid ) { 

   if (!cmd_access(id,level,cid,2)) 
      return PLUGIN_HANDLED 

   new param[10] 
   read_argv(1,param,9) 

   if ( containi ( param , "fr" ) > -1 ) { 
      set_french () 
      client_print(id,print_chat,"* Activation Headshot DeluXe FR" ) 
   } 
   else if ( containi ( param , "eng" ) > -1 ) { 
      set_english () 
      client_print(id,print_chat,"* Activation Headshot DeluXe ENG" ) 
   } 
   else if ( containi ( param , "esp" ) > -1 ) { 

      set_espagnol () 
      client_print(id,print_chat,"* Activacion Headshot DeluXe ESP" ) 
   } 
   else if ( containi ( param , "port" ) > -1 ) { 
      set_portugues () 
      client_print(id,print_chat,"* Activacao Headshot DeluXe PORT" ) 
   } 
   else if ( containi ( param , "ger" ) > -1 ) { 
      set_german () 
      client_print(id,print_chat,"* Aktivierung Headshot DeluXe GER" ) 
   } 

   else  { 
      set_english () 
      client_print(id,print_chat,"* Activation Headshot DeluXe ENG ( Default )" ) 
   } 

   return PLUGIN_HANDLED_MAIN 

}    

public show_lang ( id ) { 
   new text[MAX_TXT_LEN] 
   if ( langVersion == 0 ) 
      copy ( text , MAX_TXT_LEN_1 , "* This server is using AMXmodX plugin : Headshot DeluXe" ) 
   else if ( langVersion == 1 ) 
      copy ( text , MAX_TXT_LEN_1 , "* Ce serveur utilise le plugin AMXmodX : Headshot DeluXe" ) 
   else if ( langVersion == 2 ) 
      copy ( text , MAX_TXT_LEN_1 , "* Este servidor utiliza el plugin AMXmodX : Headshot DeluXe" ) 
   else if ( langVersion == 3 ) 
      copy ( text , MAX_TXT_LEN_1 , "* Este servidor utiliza o plugin AMXmodX : Headshot DeluXe" ) 
   else if ( langVersion == 4 ) 
      copy ( text , MAX_TXT_LEN_1 , "* Dieser server benutzt das plugin AMXmodX : Headshot DeluXe" ) 
   else 
      copy ( text , MAX_TXT_LEN_1 , "* This server is using AMXmodX plugin : Headshot DeluXe" ) 

   if ( funVersion == 1 ) 
      add  ( text , MAX_TXT_LEN_1 , " (FUN)" ) 

   client_print(0,print_chat,text) 

   return PLUGIN_CONTINUE 
} 

/* About stats */ 

public init_stats() { 

   /* Done at each map start */ 

   for ( new z = 0 ; z < 33 ; ++z ) {
      nbHS[z]    = 0
      nbFrags[z] = 0
      ranking[z] = 0 
   }

   new hsflgs[10] 
   get_cvar_string("amx_hs_event",hsflgs,9) 

   return PLUGIN_CONTINUE     
} 

public get_rank(id) { 
   for ( new z = 1 ; z < 33 ; ++z ) 
      if ( ranking[z] == id ) 
         return z 
   return 0    
} 

public get_maxP() { 
   new value = 0 
   for ( new z = 1 ; z < 33 ; ++z ) 
      if ( ranking[z] != 0 ) 
         ++value 
   return value    
} 

public remove_player(id) { 
   for ( new z = 0 ; z < 33 ; ++z ) { 
      if ( ranking[z] == id ) { 
         for ( new t = z ; t < 32 ; ++t ) 
            ranking[t] = ranking[t+1] 
         ranking[32] = 0 
         return PLUGIN_CONTINUE 
      } 
   }    
   nbHS[id]=0   
   nbFrags[id]=0
   return PLUGIN_CONTINUE 
} 

public update_rankings() { 

   /* Number of HS for last killer */ 

   for ( new z = 1 ; z < 33 ; ++z ) { 
       
      if ( ranking[z] == 0 ) { 
         ranking[z] = killr 
         return PLUGIN_CONTINUE 
      } 
      else if ( ranking[z] != killr ) { 

         if ( nbHS[killr] > nbHS[ranking[z]]  ) { 
            for ( new w = 32 ; w > z ; --w ) { 
               ranking[w] = ranking[w-1] 
            } 
            ranking[z] = killr 
            new dec = 0 
            for ( new x = z+1 ; x < 33 ; ++x ) { 
               if ( ranking[x] == killr ) { 
                  ++dec    
                  ranking [33-dec] = 0 
               } 
               if ( x+dec < 33 ) 
                  ranking[x]=ranking[x+dec]                
            } 
            return PLUGIN_CONTINUE 
         } 
         else if ( nbHS[killr] == nbHS[ranking[z]] ) { 

            new Float:prct1  = ( float(nbHS[killr])     / float( nbFrags[killr] ) ) * 100 
            new Float:prct2  = ( float(nbHS[ranking[z]]) / float( nbFrags[ranking[z]] ) ) * 100 
            if ( prct1 > prct2 ) { 
               for ( new w = 32 ; w > z ; --w ) { 
                  ranking[w] = ranking[w-1] 
               } 
               ranking[z]   = killr 
               new dec = 0 
               for ( new x = z+1 ; x < 33 ; ++x ) { 
                  if ( ranking[x] == killr ) { 
                     ++dec    
                     ranking [33-dec] = 0 
                  } 
                  if ( x+dec < 33 ) 
                     ranking[x]=ranking[x+dec]                
               } 
               return PLUGIN_CONTINUE 
            } 
         } 
      } 
      else if ( ranking[z] == killr ) { 
         return PLUGIN_CONTINUE 
      } 
   } 
   return PLUGIN_CONTINUE 
} 



/* Replacing vars */ 

replace_vars ( ioText[] ) { 

   /* replacement of 
            %killer% 
            %victim% 
            %distance% 
            %distFeet% 
            %weapon% 
            \n
   */ 

   new distance,vorigin[3],korigin[3] 
   new killerStr[80], victimStr[80], distStr[8], distFtStr[8] 

   get_user_origin(vict,vorigin) 
   get_user_origin(killr,korigin) 

   distance = get_distance(vorigin,korigin) 

   new Float:distFt = ( float(distance) * 0.08333 ) 
   format(distFtStr,7,"%.1f",distFt) 

   new Float:dist   = distFt * 0.304 
   format(distStr,7,"%.1f",dist)    

   get_user_name(killr,killerStr,79) 
   get_user_name(vict,victimStr,79) 

   new wpnId,clip,ammo,wpn[32] 
   wpnId = get_user_weapon(killr,clip,ammo) 

   get_weaponname ( wpnId , wpn ,31 ) 

   /* here we have for example wpn = "weapon_m4a1" so ... */ 

   replace(wpn,31,"weapon_","") /* it's nicer */ 

   replace(ioText,MAX_TXT_LEN_1,"%killer%",killerStr) 
   replace(ioText,MAX_TXT_LEN_1,"%victim%",victimStr) 
   replace(ioText,MAX_TXT_LEN_1,"%distance%",distStr) 
   replace(ioText,MAX_TXT_LEN_1,"%distFeet%",distFtStr) 
   replace(ioText,MAX_TXT_LEN_1,"%weapon%",wpn) 
   replace(ioText,MAX_TXT_LEN_1,"\n","^n") 

   return PLUGIN_CONTINUE 

} 

/* Displaying FXs */ 

display_HS_TXTEvent() { 

   /* displays Text FX */ 

   /* text FX in HUD */ 

   new temp [MAX_TXT_LEN] 

   set_hudmessage(HUD_COL[0],HUD_COL[1],HUD_COL[2],HUD_POS[0],HUD_POS[1],0,6.0,6.0,0.5, 0.15, HUD_CHN ) 

   if ( hudAllCvar[0] != 0 ) { 
      copy ( temp , MAX_TXT_LEN_1 , hudAllCvar ) 
      replace_vars ( temp ) 
      for ( new id = 1 ; id < 33 ; ++id ) { 
         if ( is_user_connected (id) ) {       
            if ( id == vict ) { 
               if ( hudVicCvar[0] == 0 ) { 
                  /* If victim has no hud Text specified   */ 
                  /* he gots the one for all               */ 
                  show_hudmessage(id,temp) 
               } 
            } 
            else if ( id == killr ) { 
               if ( hudKilCvar[0] == 0 ) { 
                  /* If killer has no hud Text specified   */ 
                  /* he gots the one for all               */ 
                  show_hudmessage(id,temp) 
               } 
            } 
            else { 
               show_hudmessage(id,temp) 
            } 
         } 
      } 
   } 

   if ( hudKilCvar[0] != 0 ) { 
      copy ( temp , MAX_TXT_LEN_1 , hudKilCvar ) 
      replace_vars ( temp ) 
      if ( is_user_connected (killr) ) 
         show_hudmessage(killr,temp) 
   } 

   if ( hudVicCvar[0] != 0 ) { 
      copy ( temp , MAX_TXT_LEN_1 , hudVicCvar ) 
      replace_vars ( temp ) 
      if ( is_user_connected (vict) ) 
         show_hudmessage(vict,temp) 
   } 


   /* text FX in CHAT */    

   if ( chatAllCvar[0] != 0 ) { 
      copy ( temp , MAX_TXT_LEN_1 , chatAllCvar ) 
      replace_vars ( temp ) 
      for ( new id = 1 ; id < 33 ; ++id ) { 
         if ( is_user_connected (id) ) {       
            if ( id == vict ) { 
               if ( chatVicCvar[0] == 0 ) { 
                  /* If victim has no chat Text specified */ 
                  /* he gots the one for all              */ 
                  client_print(id,print_chat,temp ) 
               } 
            } 
            else if ( id == killr ) { 
               if ( chatKilCvar[0] == 0 ) { 
                  /* If killer has no chat Text specified */ 
                  /* he gots the one for all              */ 
                  client_print(id,print_chat,temp ) 
               } 
            } 
            else { 
               client_print(id,print_chat,temp ) 
            } 
         } 
      } 
   } 

   if ( chatKilCvar[0] != 0 ) { 
      copy ( temp , MAX_TXT_LEN_1 , chatKilCvar ) 
      replace_vars ( temp ) 
      if ( is_user_connected (killr) ) 
         client_print(killr,print_chat,temp ) 
   } 

   if ( chatVicCvar[0] != 0 ) { 
      copy ( temp , MAX_TXT_LEN_1 , chatVicCvar ) 
      replace_vars ( temp ) 
      if ( is_user_connected (vict) ) 
         client_print(vict,print_chat,temp ) 
   } 

   return PLUGIN_CONTINUE 

} 

play_HS_SOUNDEvent() { 

   /* Play the correct wav for correct users */ 

   if ( wavAllCvar[0] != 0 ) { 
      new text[MAX_TXT_LEN] 
      format(text,MAX_TXT_LEN_1,"spk %s", wavAllCvar) 
      for ( new id = 1 ; id < 33 ; ++id ) { 
         if ( is_user_connected (id) ) {       
            if ( id == vict ) { 
               if ( wavVicCvar[0] == 0 ) { 
                  /* If victim has no wav specified */ 
                  /* he gots the one for all        */ 
                  client_cmd(id,text) 
               } 
            } 
            else if ( id == killr ) { 
               if ( wavKilCvar[0] == 0 ) 
                  /* If killer has no wav specified */ 
                  /* he gots the one for all        */ 
                  client_cmd(id,text) 
            } 
            else { 
               client_cmd(id,text) 
            } 
         } 
      } 
   } 

   if ( funVersion == 1 ) { 
      new text[MAX_TXT_LEN] 
      new text2[MAX_TXT_LEN] 
      get_rand_kill( text2 ) 
      format(text,MAX_TXT_LEN_1,"spk %s", text2) 
      if ( is_user_connected (killr) ) 
         client_cmd(killr,text) 
   } 
   else if ( wavKilCvar[0] != 0 ) { 
      new text[MAX_TXT_LEN] 
      format(text,MAX_TXT_LEN_1,"spk %s", wavKilCvar) 
      if ( is_user_connected (killr) ) 
         client_cmd(killr,text) 
          
   } 

   if ( funVersion == 1 ) { 
      new text[MAX_TXT_LEN] 
      new text2[MAX_TXT_LEN] 
      get_rand_vict( text2 ) 
      format(text,MAX_TXT_LEN_1,"spk %s", text2) 
      if ( is_user_connected (vict) ) 
         client_cmd(vict,text)       
   } 
   else if ( wavVicCvar[0] != 0 ) { 
      new text[MAX_TXT_LEN] 
      format(text,MAX_TXT_LEN_1,"spk %s", wavVicCvar) 
      if ( is_user_connected (vict) ) 
         client_cmd(vict,text) 
   } 
    
   return PLUGIN_CONTINUE    

} 

/* Changing configs */ 

public amx_hsChangeHud ( id , level , cid ) { 

   if (!cmd_access(id,level,cid,3)) 
      return PLUGIN_HANDLED 
       
   new users[32], path[MAX_TXT_LEN] 

   read_argv(1,users,31) 
   read_argv(2,path ,MAX_TXT_LEN_1) 

   if ( users[0] == 0 ) { 
      console_print(id,"[AMX] amx_hs_set_hud : No user found ... aborting") 
      return PLUGIN_HANDLED 
   } 

   new count = 0 
   if ( containi ( users , "A" ) > -1) { 
      ++count 
   } 
   if ( containi ( users , "V" ) > -1) { 
      ++count 
   } 
   if ( containi ( users , "K" ) > -1) { 
      ++count 
   } 

   if ( count > 1 ) { 
      console_print(id,"[AMX] amx_hs_set_hud : Only specify one user at a time ... aborting") 
      return PLUGIN_HANDLED 
   }    

   if ( containi ( users , "A" ) > -1) { 
      if ( path[0] == 0 ) { 
         hudAllCvar[0] = 0 
      } 
      else 
         copy ( hudAllCvar , MAX_TXT_LEN_1 , path ) 
   } 
   else if ( containi ( users , "V" ) > -1) { 
      if ( path[0] == 0 ) { 
         chatVicCvar[0] = 0 
      } 
      else 
         copy ( hudVicCvar , MAX_TXT_LEN_1 , path ) 
   } 
   else if ( containi ( users , "K" ) > -1) { 
      if ( path[0] == 0 ) { 
         chatKilCvar[0] = 0 
      } 
      else 
         copy ( hudKilCvar , MAX_TXT_LEN_1 , path ) 
   }    
   else { 
      console_print(id,"[AMX] amx_hs_set_hud : Bad user specified ... aborting") 
      return PLUGIN_HANDLED 
   }       

   return PLUGIN_HANDLED 

    
} 

public amx_hsChangeChat ( id , level, cid ) { 

   if (!cmd_access(id,level,cid,3)) 
      return PLUGIN_HANDLED 
       
   new users[32], path[MAX_TXT_LEN] 

   read_argv(1,users,31) 
   read_argv(2,path ,MAX_TXT_LEN_1) 

   if ( users[0] == 0 ) { 
      console_print(id,"[AMX] amx_hs_set_chat : No user found ... aborting") 
      return PLUGIN_HANDLED 
   } 

   new count = 0 
   if ( containi ( users , "A" ) > -1) { 
      ++count 
   } 
   if ( containi ( users , "V" ) > -1) { 
      ++count 
   } 
   if ( containi ( users , "K" ) > -1) { 
      ++count 
   } 

   if ( count > 1 ) { 
      console_print(id,"[AMX] amx_hs_set_chat : Only specify one user at a time ... aborting") 
      return PLUGIN_HANDLED 
   }    

   if ( containi ( users , "A" ) > -1) { 
      if ( path[0] == 0 ) { 
         chatAllCvar[0] = 0 
      } 
      else 
         copy ( chatAllCvar , MAX_TXT_LEN_1 , path ) 
   } 
   else if ( containi ( users , "V" ) > -1) { 
      if ( path[0] == 0 ) { 
         chatVicCvar[0] = 0 
      } 
      else 
         copy ( chatVicCvar , MAX_TXT_LEN_1 , path ) 
   } 
   else if ( containi ( users , "K" ) > -1) { 
      if ( path[0] == 0 ) { 
         chatKilCvar[0] = 0 
      } 
      else 
         copy ( chatKilCvar , MAX_TXT_LEN_1 , path ) 
   }    
   else { 
      console_print(id,"[AMX] amx_hs_set_chat : Bad user specified ... aborting") 
      return PLUGIN_HANDLED 
   }       

   return PLUGIN_HANDLED 

} 


public amx_hsChangeWav ( id , level, cid ) { 

   if (!cmd_access(id,level,cid,3)) 
      return PLUGIN_HANDLED 
       
   new users[32], path[MAX_TXT_LEN] 

   read_argv(1,users,31) 
   read_argv(2,path ,MAX_TXT_LEN_1) 

   if ( users[0] == 0 ) { 
      console_print(id,"[AMX] amx_hs_set_wav : No user found ... aborting") 
      return PLUGIN_HANDLED 
   } 

   new count = 0 
   if ( containi ( users , "A" ) > -1) { 
      ++count 
   } 
   if ( containi ( users , "V" ) > -1) { 
      ++count 
   } 
   if ( containi ( users , "K" ) > -1) { 
      ++count 
   } 

   if ( count > 1 ) { 
      console_print(id,"[AMX] amx_hs_set_wav : Only specify one user at a time ... aborting") 
      return PLUGIN_HANDLED 
   }    

   if ( containi ( users , "A" ) > -1) { 
      if ( path[0] == 0 ) { 
         wavAllCvar[0] = 0 
      } 
      else 
         copy ( wavAllCvar , MAX_TXT_LEN_1 , path ) 
   } 
   else if ( containi ( users , "V" ) > -1) { 
      if ( path[0] == 0 ) { 
         wavVicCvar[0] = 0 
      } 
      else 
         copy ( wavVicCvar , MAX_TXT_LEN_1 , path ) 
   } 
   else if ( containi ( users , "K" ) > -1) { 
      if ( path[0] == 0 ) { 
         wavKilCvar[0] = 0 
      } 
      else 
         copy ( wavKilCvar , MAX_TXT_LEN_1 , path ) 
   }    
   else { 
      console_print(id,"[AMX] amx_hs_set_wav : Bad user specified ... aborting") 
      return PLUGIN_HANDLED 
   }       

   return PLUGIN_HANDLED 

} 

/* Displaying FX ( stats ) */ 

public display_event_Text ( id ) { 

   new nbText[MAX_TXT_LEN] 
   new ratioText[MAX_TXT_LEN] 
   new rankText[MAX_TXT_LEN] 

   new output[MAX_TXT_LEN] 

   new cnt = 0 

   new hsflgs[10] 
   get_cvar_string("amx_hs_event",hsflgs,9) 

   if ( read_flags(hsflgs)&4) { 
      ++cnt 
      new done = 0 
      if ( nbHS[id] == 50 ) { 
         format ( nbText , MAX_TXT_LEN_1 , "%s^n          %d %s" ,textSup50 ,nbHS[id], textHS ) 
         done = 1 
      } 
      if ( ( nbHS[id] == 20 ) && ( done == 0 ) ) { 
         format ( nbText , MAX_TXT_LEN_1 , "%s^n          %d %s" ,textSup20, nbHS[id], textHS ) 
         done = 1    
      } 
      if ( ( nbHS[id] == 10 ) && ( done == 0 ) ) { 
         format ( nbText , MAX_TXT_LEN_1 , "%s^n          %d %s" ,textSup10, nbHS[id], textHS ) 
         done = 1 
      } 
      if ( ( nbHS[id] > 1 ) && ( done == 0 ) ) { 
         format ( nbText , MAX_TXT_LEN_1 , "%s^n          %d %s" ,textSup1, nbHS[id], textHS ) 
         done = 1 
      } 
      if ( done == 0 ) { 
         format ( nbText , MAX_TXT_LEN_1 , "^n          %s" ,textFirst ) 
      } 
      copy ( output , MAX_TXT_LEN_1 , nbText ) 
   } 
   if ( read_flags(hsflgs)&16) { 
      ++cnt 
      new maxP = get_maxP() 
      new rk   = get_rank(id) 
      format ( rankText , MAX_TXT_LEN_1 , "^n          %s %d/%d" ,textRank ,rk, maxP ) 
      add ( output , MAX_TXT_LEN_1 , rankText ) 
   } 
   if ( read_flags(hsflgs)&8) { 
      ++cnt 
      new Float:percent = 1.0 
      percent *= float(nbHS[id])
      percent /= float(nbFrags[id])
      percent *= 100.0
      format ( ratioText , MAX_TXT_LEN_1 , "^n          %s %.0f %c" , textFrags, percent, '%' ) 
      format ( output , MAX_TXT_LEN_1 , "%s%s" , output , ratioText ) 
   }    
   if ( cnt > 0 ) { 
      set_hudmessage(HUD_COL2[0],HUD_COL2[1],HUD_COL2[2],HUD_POS2[0],HUD_POS2[1],0,6.0,6.0,0.5, 0.15, HUD_CHN2 ) 
      show_hudmessage(id,output)       
   } 

   return PLUGIN_CONTINUE 

} 

public display_HS_RANK ( id ) { 

   new rkText[MAX_TXT_LEN] 
   new r = 1 
   new n = 0 

   if ( nbHS[id] > 0 ) { 
      new rk   = get_rank(id) 
      new maxp = get_maxP() 
      format ( rkText , MAX_TXT_LEN_1 , "Headshot %s %d/%d ( %d HeadShot(s) )",textRank , rk , maxp , nbHS[id] ) 
   } 
   else { 
      format ( rkText , MAX_TXT_LEN_1 , "%s ...", noHeadshot , r , n ) 
   } 
   client_print(id,print_chat,rkText ) 
    
   return PLUGIN_CONTINUE 
    
} 

public display_HS_TOP ( id ) { 

   new title[80] 
   new topText[2000] 
   new NameP[40] 
    
   format ( title , 79 ,titleMotd ) 
   new NB = 0 
   new hsflags[10]
   get_cvar_string("amx_hs_event",hsflags,9) 

   if ( read_flags(hsflags)&32) {

      new textC1[200];  /* Rank column         */ 
      new textC2[700];  /* Name column         */ 
      new textC3[200];  /* HS column           */ 
      new textC4[200];  /* % of frags column 1 */ 
      new textC5[200];  /* % of frags column 2 */ 
    
      for ( new d = 1 ; d < 16 ; ++d ) { 
         new userId = ranking[d] 

         if ( userId == 0 ) { 
            /* No more rankings */ 
            d = 50       
         } 
         else if ( is_user_connected(userId) ) { 

            if ( nbHS[userId] > 0 ) { 
               get_user_name ( userId , NameP , 39 ) 
               new Float:percent  = ( float(nbHS[userId]) / float(nbFrags[userId]) ) * 100 
               new temp1[10] 
               format ( temp1 , 9 , "%d<br>" , d ) 
               add( textC1,199,temp1) 
               add( textC2,699,NameP) 
               add( textC2,699,"<br>") 
               new temp3[30] 
               format ( temp3 , 29 , "%d<br>" , nbHS[userId] ) 
               add( textC3,199,temp3)                
               new temp4[10] 
               format ( temp4 , 9 , "%.1f<br>" , percent ) 
               add( textC4, 199, temp4 ) 
               add( textC5, 199, "%<br>" ) 

               ++NB 
            }    
         } 
      } 

      if ( NB == 0 ) { 
         add (topText,1999,"<html><head></head><body bgcolor=^"#666666^" text=^"#FFFFFF^">") 
         add (topText,1999,"<div align=^"center^">") 
         add (topText,1999,"<font size=^"2^" face=^"Arial, Helvetica, sans-serif^" color=orange>") 
         add (topText,1999,"<br><br><br><b>") 
         new temp6[100] 
         format ( temp6 ,99, "%s ...",noHeadshot ) 
         add (topText,1999,temp6) 
         add (topText,1999,"</b></font></div></body></html>") 
      } 
      else { 
         add (topText,1999,"<html><head></head><body bgcolor=^"#666666^" text=^"#FFFFFF^">") 
         add (topText,1999,"<table align=^"center^" width=^"80%^">") 
         add (topText,1999,"<td bgcolor=^"#666666^" width=^"12%^">") 
         add (topText,1999,"<div align=^"center^">") 
         add (topText,1999,"<font size=^"2^" face=^"Arial, Helvetica, sans-serif^" color=orange><br><br><b>") 
         add (topText,1999,textC1) 
         add (topText,1999,"</b></td><td bgcolor=^"#666666^"><div align=^"left^" width=^"48%^">") 
         add (topText,1999,"<font size=^"2^" face=^"Arial, Helvetica, sans-serif^" color=orange><br><br><b>") 
         add (topText,1999,textC2) 
         add (topText,1999,"</b></font></div></td><td bgcolor=^"#666666^" width=^"20%^"><div align=^"center^">") 
         add (topText,1999,"<font size=^"2^" face=^"Arial, Helvetica, sans-serif^" color=orange><b>HS</b><br><br><b>") 
         add (topText,1999,textC3) 
         add (topText,1999,"</b></font></div></td><td bgcolor=^"#666666^" width=^"15%^"><div align=^"right^">") 
         add (topText,1999,"<font size=^"2^" face=^"Arial, Helvetica, sans-serif^" color=orange><b>Frags</b><br><br><b>") 
         add (topText,1999,textC4) 
         add (topText,1999,"</b></font></div></td><td bgcolor=^"#666666^" width=^"5%^"><div align=^"left^">") 
         add (topText,1999,"<font size=^"2^" face=^"Arial, Helvetica, sans-serif^" color=orange><br><br><b>") 
         add (topText,1999,textC5) 
         add (topText,1999,"</b></font></div></td></table></body></html>") 
      } 
   } 
   else { 

      for ( new d = 1 ; d < 33 ; ++d ) { 
         new userId = ranking[d] 

         if ( userId == 0 ) { 
            /* No more rankings */ 
            d = 50       
         } 
         else if ( is_user_connected(userId) ) { 

            if ( nbHS[userId] > 0 ) { 
               get_user_name ( userId , NameP , 39 ) 
               new Float:percent  = ( float(nbHS[userId]) / float(nbFrags[userId]) ) * 100 
               new temp[MAX_TXT_LEN] 
               format ( temp , MAX_TXT_LEN_1 ,  "^n%d - %s^n       %4d Headshot(s) - %s %.1f %% " ,d,NameP,nbHS[userId],textFrags,percent) 
               add( topText,2999,temp) 
               ++NB 
            }    
         } 
      } 

      if ( NB == 0 ) 
         format ( topText ,2047, "^n^n^n %s ...",noHeadshot )    
   } 


   show_motd(id,topText,title) 

   return PLUGIN_CONTINUE 
    
} 

/* Initiating call */ 

public made_hs(){ 

   killr = read_data(1) 
   vict  = read_data(2) 

   if ( killr > 0 )
   {
      nbHS[killr]=nbHS[killr]+1
      update_rankings()    

#if defined DEBUG
      new text[100]
      format ( text, 99, "[AMXmodX] - Player %d made HS -> Total = %d", killr, nbHS[killr] )
      log_message(text)
#endif
      new hsflags[10] 

      get_cvar_string("amx_hs_event",hsflags,9) 

      if ( read_flags(hsflags)&1)
        display_HS_TXTEvent() 

      if ( read_flags(hsflags)&2)
        play_HS_SOUNDEvent() 

      display_event_Text ( killr ) 

   }
#if defined DEBUG
   else
   {
      new text[100]
      format ( text, 99, "[AMXmodX] - WorldSpawn made hs ..." )
      log_message(text)
   }
#endif

   return PLUGIN_CONTINUE 

} 

/* Updating frags counter */

public made_frag(id){

   killr = read_data(1) 

   if ( killr > 0 )
   {
      nbFrags[killr]=nbFrags[killr]+1

#if defined DEBUG
      new text[100]
      format ( text, 99, "[AMXmodX] - Player %d made frag -> Total = %d", killr, nbFrags[killr] )
      log_message(text)
#endif

      if ( ( read_data(3) == 1 ) && ( read_data(5) == 0 ) )
      {
#if defined DEBUG
         log_message("[AMXmodX] - Frag = HS")
#endif
         made_hs()
      }
   }
#if defined DEBUG
   else
   {
      new text[100]
      format ( text, 99, "[AMXmodX] - WorldSpawn made frag ..." )
      log_message(text)
   }
#endif

   return PLUGIN_CONTINUE 

}

/* Saving configuration */ 

public save_to_file ( id , level, cid ) { 

   if (!cmd_access(id,level,cid,2)) 
      return PLUGIN_HANDLED 

   new cfgFile[MAX_TXT_LEN] 
   read_argv(1,cfgFile,MAX_TXT_LEN_1) 
    
   if ( cfgFile[0] == 0 ) { 
      console_print(id,"[AMX] amx_hs_save_config : No path or file found ... aborting") 
      return PLUGIN_HANDLED 
   } 
    
   if ( containi(cfgFile,".cfg" ) == -1 ) { 
      console_print(id,"[AMX] amx_hs_save_config : You have to use cfg extension for file ... aborting") 
      return PLUGIN_HANDLED 
   } 
    
   replace(cfgFile,MAX_TXT_LEN_1,"../","") 
    
   new counter = 0 
          
   if ( file_exists( cfgFile ) ) 
      console_print(id,"[AMX] amx_hs_save_config : File found ... adding config at end of file") 
   else 
      console_print(id,"[AMX] amx_hs_save_config : File not found ... trying to create it") 

   new temp1[MAX_TXT_LEN]= "amx_hs_event       ^"" 

   new hsCfg[MAX_TXT_LEN] 
   get_cvar_string ( "amx_hs_event" , hsCfg , MAX_TXT_LEN_1) 
   add ( temp1 , MAX_TXT_LEN_1 , hsCfg ) 
   add ( temp1 , MAX_TXT_LEN_1 , "^"" ) 

   write_file(cfgFile,"// Configuration for Plugin Headshot Deluxe",-1) 
    
   if ( write_file(cfgFile,temp1,-1) == 0 ) { 
      ++counter 
      console_print(id,"[AMX] amx_hs_save_config : Failed to write config for amx_hs_event ... skipping") 
   } 


   if ( langVersion == 0 ) { 
      if ( write_file(cfgFile,"amx_hs_set_lang    ^"eng^"",-1) == 0 ) { 
         ++counter 
         console_print(id,"[AMX] amx_hs_save_config : Failed to write config for amx_hs_set_lang ... skipping") 
      } 
   } 
   else if ( langVersion == 1 ) { 
      if ( write_file(cfgFile,"amx_hs_set_lang    ^"fr^"",-1) == 0 ) { 
         ++counter 
         console_print(id,"[AMX] amx_hs_save_config : Failed to write config for amx_hs_set_lang ... skipping") 
      } 
   } 
   else if ( langVersion == 2 ) { 
      if ( write_file(cfgFile,"amx_hs_set_lang    ^"esp^"",-1) == 0 ) { 
         ++counter 
         console_print(id,"[AMX] amx_hs_save_config : Failed to write config for amx_hs_set_lang ... skipping") 
      } 
   } 
   else if ( langVersion == 3 ) { 
      if ( write_file(cfgFile,"amx_hs_set_lang    ^"port^"",-1) == 0 ) { 
         ++counter 
         console_print(id,"[AMX] amx_hs_save_config : Failed to write config for amx_hs_set_lang ... skipping") 
      } 
   } 
   else if ( langVersion == 4 ) { 
      if ( write_file(cfgFile,"amx_hs_set_lang    ^"eng^"",-1) == 0 ) { 
         ++counter 
         console_print(id,"[AMX] amx_hs_save_config : Failed to write config for amx_hs_set_lang ... skipping") 
      } 
   } 

       
   { 
      new temp2[MAX_TXT_LEN]= "amx_hs_set_hs_hud  ^"A^" ^"" 
      add ( temp2 , MAX_TXT_LEN_1 , hudAllCvar ) 
      add ( temp2 , MAX_TXT_LEN_1 , "^""    ) 
      if ( write_file(cfgFile,temp2,-1) == 0 ) { 
         ++counter 
         console_print(id,"[AMX] amx_hs_save_config : Failed to write config for amx_hs_set_hs_hud A ... skipping") 
      } 

   } 

   { 
      new temp2[MAX_TXT_LEN]= "amx_hs_set_hs_hud  ^"V^" ^"" 
      add ( temp2 , MAX_TXT_LEN_1 , hudVicCvar ) 
      add ( temp2 , MAX_TXT_LEN_1 , "^""    ) 
      if ( write_file(cfgFile,temp2,-1) == 0 ) { 
         ++counter 
         console_print(id,"[AMX] amx_hs_save_config : Failed to write config for amx_hs_set_hs_hud V ... skipping") 
      } 

   } 

   { 
      new temp2[MAX_TXT_LEN]= "amx_hs_set_hs_hud  ^"K^" ^"" 
      add ( temp2 , MAX_TXT_LEN_1 , hudKilCvar ) 
      add ( temp2 , MAX_TXT_LEN_1 , "^""    ) 
      if ( write_file(cfgFile,temp2,-1) == 0 ) { 
         ++counter 
         console_print(id,"[AMX] amx_hs_save_config : Failed to write config for amx_hs_set_hs_hud K ... skipping") 
      } 

   } 

   { 
      new temp2[MAX_TXT_LEN]= "amx_hs_set_hs_chat ^"A^" ^"" 
      add ( temp2 , MAX_TXT_LEN_1 , chatAllCvar ) 
      add ( temp2 , MAX_TXT_LEN_1 , "^""    ) 
      if ( write_file(cfgFile,temp2,-1) == 0 ) { 
         ++counter 
         console_print(id,"[AMX] amx_hs_save_config : Failed to write config for amx_hs_set_hs_chat A ... skipping") 
      } 

   } 

   { 
      new temp2[MAX_TXT_LEN]= "amx_hs_set_hs_chat ^"V^" ^"" 
      add ( temp2 , MAX_TXT_LEN_1 , chatVicCvar ) 
      add ( temp2 , MAX_TXT_LEN_1 , "^""    ) 
      if ( write_file(cfgFile,temp2,-1) == 0 ) { 
         ++counter 
         console_print(id,"[AMX] amx_hs_save_config : Failed to write config for amx_hs_set_hs_chat V ... skipping") 
      } 

   } 

   { 
      new temp2[MAX_TXT_LEN]= "amx_hs_set_hs_chat ^"K^" ^"" 
      add ( temp2 , MAX_TXT_LEN_1 , chatKilCvar ) 
      add ( temp2 , MAX_TXT_LEN_1 , "^""    ) 
      if ( write_file(cfgFile,temp2,-1) == 0 ) { 
         ++counter 
         console_print(id,"[AMX] amx_hs_save_config : Failed to write config for amx_hs_set_hs_chat K ... skipping") 
      } 

   } 

   { 
      new temp2[MAX_TXT_LEN]= "amx_hs_set_hs_wav  ^"A^" ^"" 
      add ( temp2 , MAX_TXT_LEN_1 , wavAllCvar ) 
      add ( temp2 , MAX_TXT_LEN_1 , "^""    ) 
      if ( write_file(cfgFile,temp2,-1) == 0 ) { 
         ++counter 
         console_print(id,"[AMX] amx_hs_save_config : Failed to write config for amx_hs_set_hs_wav A ... skipping") 
      } 

   } 

   { 
      new temp2[MAX_TXT_LEN]= "amx_hs_set_hs_wav  ^"V^" ^"" 
      add ( temp2 , MAX_TXT_LEN_1 , wavVicCvar ) 
      add ( temp2 , MAX_TXT_LEN_1 , "^""    ) 
      if ( write_file(cfgFile,temp2,-1) == 0 ) { 
         ++counter 
         console_print(id,"[AMX] amx_hs_save_config : Failed to write config for amx_hs_set_hs_wav V ... skipping") 
      } 

   } 

   { 
      new temp2[MAX_TXT_LEN]= "amx_hs_set_hs_wav  ^"K^" ^"" 
      add ( temp2 , MAX_TXT_LEN_1 , wavKilCvar ) 
      add ( temp2 , MAX_TXT_LEN_1 , "^""    ) 
      if ( write_file(cfgFile,temp2,-1) == 0 ) { 
         ++counter 
         console_print(id,"[AMX] amx_hs_save_config : Failed to write config for amx_hs_set_hs_wav K ... skipping") 
      } 

   } 

   write_file(cfgFile,"//", -1) 
    
   if ( counter > 0 ) { 
      console_print(id,"[AMX] amx_hs_save_config : Configuration for HS-Deluxe stored ( %d write error(s) )" , counter )    
   } 
   else { 
      console_print(id,"[AMX] amx_hs_save_config : Configuration for HS-Deluxe stored successfully" )             
   } 
    
   return PLUGIN_HANDLED_MAIN 
    
} 

/* Fun addon */ 

public switch_funmode ( id , level, cid ) { 

   if (!cmd_access(id,level,cid,2)) 
      return PLUGIN_HANDLED 

   new act[MAX_TXT_LEN] 
   read_argv(1,act,MAX_TXT_LEN_1) 
    
   if ( act[0] == 0 ) { 
      console_print(id,"[AMX] amx_hs_set_fun : Bad value ... aborting") 
      return PLUGIN_HANDLED 
   } 
    
   if ( containi(act,"ON" ) > -1 ) { 
      funVersion = 1 
      client_print(0,print_chat,"* HS DeluXe Fun mode ON" ) 
   } 
   else if ( containi(act,"OFF" ) > -1 ) { 
      funVersion = 0 
      client_print(0,print_chat,"* HS DeluXe Fun mode OFF" ) 
   } 

   return PLUGIN_HANDLED_MAIN 
} 

public get_rand_vict( text[] ) { 
   new i = random_num(0,VIC_MAX-1) 
   while ( i == lastMsgVic ) { 
      i = random_num(0,VIC_MAX-1) 
   } 
   lastMsgVic = i 
   copy ( text , MAX_TXT_LEN_1 , listVicWav[i] ) 
   return PLUGIN_CONTINUE    
} 

public get_rand_kill( text[] ) { 
   new j = random_num(0,KIL_MAX-1) 
   while ( j == lastMsgKil ) { 
      j = random_num(0,KIL_MAX-1) 
   } 
   lastMsgKil = j 
   copy ( text , MAX_TXT_LEN_1 , listKilWav[j] ) 
   return PLUGIN_CONTINUE    
} 

/* Didn't forget disconnection IN Game .. */ 

public client_disconnect(id) { 
   remove_player(id) 
   return PLUGIN_CONTINUE 
} 

/* Precaching sounds */ 

public plugin_precache() { 
    
   if ( wavKilCvar[0] != 0 ) { 
      new text[MAX_TXT_LEN] 
      copy ( text , MAX_TXT_LEN_1 , wavKilCvar ) 
      add  ( text , MAX_TXT_LEN_1 , ".wav" ) 
      precache_sound ( text ) 
   } 
   if ( wavVicCvar[0] != 0 ) { 
      new text[MAX_TXT_LEN] 
      copy ( text , MAX_TXT_LEN_1 , wavVicCvar ) 
      add  ( text , MAX_TXT_LEN_1 , ".wav" ) 
      precache_sound ( text ) 
   } 
   if ( wavAllCvar[0] != 0 ) { 
      new text[MAX_TXT_LEN] 
      copy ( text , MAX_TXT_LEN_1 , wavAllCvar ) 
      add  ( text , MAX_TXT_LEN_1 , ".wav" ) 
      precache_sound ( text ) 
   }    
    
   return PLUGIN_CONTINUE 
} 

/* Initializing plugin */ 

public plugin_init(){    
   register_plugin("Headshot DeluXe","X.16.1.0","DanRaZor") 

   init_stats() 

   register_cvar("hsd_version","X.16.1.0",FCVAR_SERVER)

   register_event   ("DeathMsg","made_frag","a" ) 

   register_cvar    ("amx_hs_event"      ,"abf") 

   register_concmd  ("amx_hs_set_hud"    , "amx_hsChangeHud" , ADMIN_CVAR, "^"users^" ^"text^" ( users = A,V,K )") 
   register_concmd  ("amx_hs_set_chat"   , "amx_hsChangeChat", ADMIN_CVAR, "^"users^" ^"text^" ( users = A,V,K )") 
   register_concmd  ("amx_hs_set_wav"    , "amx_hsChangeWav" , ADMIN_CVAR, "^"users^" ^"wavPathFile^" ( users = A,V,K )") 
   register_concmd  ("amx_hs_set_lang"   , "set_language"    , ADMIN_CVAR, "^"language^" ( eng, fr, esp, port, ger ) ") 
   register_concmd  ("amx_hs_set_fun"    , "switch_funmode"  , ADMIN_CVAR, "^"ON^" or ^"OFF^"") 
   register_concmd  ("amx_hs_save_config", "save_to_file"    , ADMIN_RCON, "^"cfgPathFile^"") 

   register_clcmd   ("say /hs"           , "display_HS_RANK") 
   register_clcmd   ("say_team /hs"      , "display_HS_RANK") 
   register_clcmd   ("say /hsAll"        , "display_HS_TOP") 
   register_clcmd   ("say_team /hsAll"   , "display_HS_TOP") 
   register_clcmd   ("say /hd"           , "show_lang") 
   register_clcmd   ("say_team /hd"      , "show_lang") 

   return PLUGIN_CONTINUE 
} 
