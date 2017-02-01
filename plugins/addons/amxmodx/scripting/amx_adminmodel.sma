/*########################################################################## 
## 
## -- www.SteamTools.net 
##      ___   _____       ___  ___   _   __   _            ___  ___   _____   _      
##     /   | |  _  \     /   |/   | | | |  \ | |          /   |/   | |  _  \ | |      
##    / /| | | | | |    / /|   /| | | | |   \| |         / /|   /| | | | | | | |      
##   / / | | | | | |   / / |__/ | | | | | |\   |        / / |__/ | | | | | | | |      
##  / /  | | | |_| |  / /       | | | | | | \  |       / /       | | | |_| | | |___  
## /_/   |_| |_____/ /_/        |_| |_| |_|  \_|      /_/        |_| |_____/ |_____| 
##                                                        
##          |__                   |__  o _|_   ___   __ __  o |__,  ___  
##      --  |__) (__|     (__(__( |  ) |  |_, (__/_ |  )  ) | |  \ (__/_ 
##                  |                                                    
## 
##   Originated as a simple idea back in 2004, it was forgotten due to 
## lack of my 'Small' coding skills. However I have progressed in recent 
## months and somehow crossed that old post with this concept in it. So 
## naturally I challenged myself to see if I could do it, and voila! I 
## could :) 
## 
##   Once you join, you play a normal person for the first round, and for 
## all remaining rounds your CT or TE models are custom. They now read 
## "ADMIN" on front and back, and also have small "A" patches on the arms. 
## I designed these models myself, it's very easy, just bring the textures 
## into photoshop, tweak out, and replace. 
## 
##   Enjoy! 
## 
## 
## CHANGELOG 
##------------------------------------------------------------------------ 
## 2) v1.1.1 - Fixed missing event 
## 1) v1.1.0 - Fixed VIP and other model bugs 
## 
## 
## INSTALLATION 
##------------------------------------------------------------------------ 
## 1) Unzip (which you may have done already) 
## 2) Place 'amx_adminmodel.amxx' in 'cstrike/addons/amxmodx/plugins' 
## 3) Add a line in 'configs/plugins.ini' containing 'amx_adminmodel.amxx' 
## 4) Put the 'admin_ct' and 'admin_te' folders into 'cstrike/models' folder 
## 5) -- Visit www.SteamTools.net and enjoy your new plugin! 
## 
## 
## 
## THE CVARs 
##------------------------------------------------------------------------ 
## 
## No CVARs for this plugin :) 
## 
## 
##########################################################################*/	


#include <amxmodx>
#include <amxmisc>
#include <cstrike>

public plugin_init() {
        register_plugin("AMX Admin Model", "1.1.1", "whitemike")
        register_event("ResetHUD", "resetModel", "b")
        return PLUGIN_CONTINUE
}

public plugin_precache() {
        precache_model("models/player/admin_ct/admin_ct.mdl")
        precache_model("models/player/admin_te/admin_te.mdl")

        return PLUGIN_CONTINUE
}

public resetModel(id, level, cid) {
        if (get_user_flags(id) & ADMIN_KICK) {
                new CsTeams:userTeam = cs_get_user_team(id)
                if (userTeam == CS_TEAM_T) {
                        cs_set_user_model(id, "admin_te")
                }
                else if(userTeam == CS_TEAM_CT) {
                        cs_set_user_model(id, "admin_ct")
                }
                else {
                        cs_reset_user_model(id)
                }
        }

        return PLUGIN_CONTINUE
}
