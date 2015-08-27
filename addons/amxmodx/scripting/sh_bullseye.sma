#include <amxmodx>
#include <fun>
#include <cstrike>
#include <engine>
#include <superheromod>

// VARIABLES
new gHeroName[]="Bullseye"
new gHasbullseyePower[SH_MAXSLOTS+1]
new gmsgSetFOV
new Zooming[SH_MAXSLOTS+1]
new laststate[SH_MAXSLOTS+1]
new gLastWeapon[SH_MAXSLOTS+1]
//----------------------------------------------------------------------------------------------
public plugin_init()
{
  // Plugin Info
  register_plugin("SUPERHERO Bullseye","1.0","AssKicR¨& Freecode")
 
  // FIRE THE EVENT TO CREATE THIS SUPERHERO!
  if ( isDebugOn() ) server_print("Attempting to create Bullseye Hero")
  register_cvar("bullseye_level", "5")
  shCreateHero(gHeroName, "Expert Aim", "You can now zoom with any gun", true, "bullseye_level" )
  
  // REGISTER EVENTS THIS HERO WILL RESPOND TO! (AND SERVER COMMANDS)
  // INIT
  register_srvcmd("bullseye_init", "bullseye_init")
  shRegHeroInit(gHeroName, "bullseye_init")
  register_event("ResetHUD","newRound","b")
  register_event("CurWeapon","changeweapon","be","1=1")

  // KEY DOWN 
  register_srvcmd("bullseye_kd", "bullseye_kd") 
  shRegKeyDown(gHeroName, "bullseye_kd") 


  // DEFAULT THE CVARS
  register_cvar("bullseye_health", "100")
  register_cvar("bullseye_armor", "100")
  register_cvar("bullseye_zoommode", "0")

  shSetMaxHealth(gHeroName, "bullseye_health" )
  shSetMaxArmor(gHeroName, "bullseye_armor" )

  gmsgSetFOV = get_user_msgid("SetFOV")

  set_task(0.01,"check_reload",0,"",0,"b")

  return PLUGIN_CONTINUE
}
//----------------------------------------------------------------------------------------------
public bullseye_init()
{
  new temp[6]
  // First Argument is an id
  read_argv(1,temp,5)
  new id=str_to_num(temp)
  
  // 2nd Argument is 0 or 1 depending on whether the id has flash
  read_argv(2,temp,5)
  new hasPowers=str_to_num(temp)
  gHasbullseyePower[id]=(hasPowers != 0)
  
  // Got to slow down a Flash that lost his powers...
  if ( !hasPowers && is_user_connected(id) )
  {
	 shRemHealthPower(id)
	 shRemArmorPower(id)
	 bullseye_zoomout(id)
  }
}
//----------------------------------------------------------------------------------------------
public newRound(id)
{
  if ( gHasbullseyePower[id] && is_user_alive(id) && shModActive() )
  {
	bullseye_zoomout(id)
  }
  return PLUGIN_CONTINUE
}
//----------------------------------------------------------------------------------------------
public plugin_precache() {
	precache_sound("weapons/zoom.wav")
}
//----------------------------------------------------------------------------------------------
public bullseye_zoom(id)
{
  Zooming[id]=4
  message_begin(MSG_ONE, gmsgSetFOV, {0,0,0}, id)
  write_byte(60) //Zooming AUG/SIG style
  message_end()
  return PLUGIN_CONTINUE
}
//----------------------------------------------------------------------------------------------
public bullseye_zoomonce(id)
{
  Zooming[id]=1
  emit_sound(id,CHAN_WEAPON, "weapons/zoom.wav", 1.0, ATTN_NORM, 0, PITCH_NORM)
  message_begin(MSG_ONE, gmsgSetFOV, {0,0,0}, id)
  write_byte(40) //Zooming once
  message_end()
  return PLUGIN_CONTINUE
} 
//----------------------------------------------------------------------------------------------
public bullseye_zoomtwice(id)
{
  Zooming[id]=2
  emit_sound(id,CHAN_WEAPON, "weapons/zoom.wav", 1.0, ATTN_NORM, 0, PITCH_NORM)
  message_begin(MSG_ONE, gmsgSetFOV, {0,0,0}, id)
  write_byte(20) //Zooming twice
  message_end()
  return PLUGIN_CONTINUE
} 
//----------------------------------------------------------------------------------------------
public bullseye_zoomtrice(id)
{
  Zooming[id]=3
  emit_sound(id,CHAN_WEAPON, "weapons/zoom.wav", 1.0, ATTN_NORM, 0, PITCH_NORM)
  message_begin(MSG_ONE, gmsgSetFOV, {0,0,0}, id)
  write_byte(1) //Zooming trice
  message_end()
  return PLUGIN_CONTINUE
} 
//----------------------------------------------------------------------------------------------
public bullseye_zoomout(id)
{
  Zooming[id]=0
  message_begin(MSG_ONE, gmsgSetFOV, {0,0,0}, id)
  write_byte(90) //not Zooming
  message_end()
  return PLUGIN_CONTINUE
} 
//----------------------------------------------------------------------------------------------
public check_zoom(id) {
	if (is_user_alive(id)) {
		if (gHasbullseyePower[id]) { 
			new temp,temp2
			new wpn_id = get_user_weapon(id,temp,temp2)
			gLastWeapon[id]=wpn_id
			if ( wpn_id==CSW_AWP || wpn_id==CSW_SCOUT || wpn_id==CSW_SG552 || wpn_id==CSW_G3SG1 || wpn_id==CSW_AUG || wpn_id==CSW_SG550 || wpn_id==CSW_KNIFE || wpn_id==CSW_C4 || wpn_id==CSW_HEGRENADE || wpn_id==CSW_FLASHBANG || wpn_id==CSW_SMOKEGRENADE ) {
				playSoundDenySelect(id) 
			}else{
				if (get_cvar_num("bullseye_zoommode")==1) {
					if (Zooming[id]==3) {
						bullseye_zoomout(id)
					} else if  (Zooming[id]==2) {
						bullseye_zoomtrice(id)
					} else if (Zooming[id]==1) {
						bullseye_zoomtwice(id)
					} else {
						bullseye_zoomonce(id)
					}
				}else{
					if (Zooming[id]!=0) {
						bullseye_zoomout(id)
					} else {
						bullseye_zoom(id)
					}
				}
			}
		}
	} 
	return PLUGIN_CONTINUE 
} 
//----------------------------------------------------------------------------------------------
public changeweapon(id) {
	if (!gHasbullseyePower[id]) return PLUGIN_CONTINUE
	new clip,temp
	new wpn_id = get_user_weapon(id,clip,temp) 
	if (gLastWeapon[id]!=wpn_id) bullseye_zoomout(id)
	gLastWeapon[id]=wpn_id

	if ( wpn_id==CSW_AWP || wpn_id==CSW_SCOUT || wpn_id==CSW_SG552 || wpn_id==CSW_G3SG1 || wpn_id==CSW_AUG || wpn_id==CSW_SG550 || wpn_id==CSW_KNIFE || wpn_id==CSW_C4 || wpn_id==CSW_HEGRENADE || wpn_id==CSW_FLASHBANG || wpn_id==CSW_SMOKEGRENADE ) return PLUGIN_CONTINUE
    
    // Never Run Out of Ammo!
    //server_print("STATUS ID=%d CLIP=%d, AMMO=%d WPN=%d", id, clip, ammo, wpn_id)
	if ( clip == 0 ) {
		if (Zooming[id]!=0) {
			laststate[id]=Zooming[id]
			bullseye_zoomout(id)
			new parm[2]
			parm[0]=id
			parm[1]=wpn_id
			set_task(float(3),"zoom_return",0,parm,2)
			shResetSpeed(id)
		}
	}
	return PLUGIN_CONTINUE
}
//----------------------------------------------------------------------------------------------
// RESPOND TO KEYDOWN 
public bullseye_kd() { 
	new temp[6] 

	// First Argument is an id with NightCrawler Powers! 
	read_argv(1,temp,5) 
	new id=str_to_num(temp) 

	if ( !is_user_alive(id) ) return PLUGIN_HANDLED 

	// Let them know they already used their ultimate if they have 
	if ( !gHasbullseyePower[id] ) return PLUGIN_HANDLED

	check_zoom(id)

	return PLUGIN_HANDLED 
} 
//------------------------------------------------------------------------------------------
public check_reload() { 
  
	for(new id = 1; id <= get_maxplayers(); ++id) { 
		if (is_user_alive(id)) {
			new clip,temp
			new wpn_id = get_user_weapon(id,clip,temp) 
			if ( wpn_id==CSW_AWP || wpn_id==CSW_SCOUT || wpn_id==CSW_SG552 || wpn_id==CSW_G3SG1 || wpn_id==CSW_AUG || wpn_id==CSW_SG550 || wpn_id==CSW_KNIFE || wpn_id==CSW_C4 || wpn_id==CSW_HEGRENADE || wpn_id==CSW_FLASHBANG || wpn_id==CSW_SMOKEGRENADE ) {
				//nottin
			}else{
				if (get_user_button(id)&IN_RELOAD) {
					if (CheckMaxAmmo(id)) {
						laststate[id]=Zooming[id]
						bullseye_zoomout(id)
						new parm[2]
						parm[0]=id
						parm[1]=wpn_id
						set_task(float(3),"zoom_return",0,parm,2)
					}
				}else{
					//nottin
				}
			}
		}
	}
	return PLUGIN_CONTINUE 
}
//----------------------------------------------------------------------------------------------
public zoom_return(parm[]) {
	new id=parm[0]
	new clip,ammo
	new wpn_id = get_user_weapon(id,clip,ammo) 
	if (parm[1]==wpn_id) {
		if (get_cvar_num("bullseye_zoommode")==1) {
			if (laststate[id]==3) {
				bullseye_zoomtrice(id)
			} else if  (laststate[id]==2) {
				bullseye_zoomtwice(id)
			} else if (laststate[id]==1) {
				bullseye_zoomonce(id)
			} else {
				bullseye_zoomout(id)
			}
		}else{
			if (laststate[id]!=0) {
				bullseye_zoom(id)
			} else {
				bullseye_zoomout(id)
			}
		}	
	}
	return PLUGIN_CONTINUE
}
//----------------------------------------------------------------------------------------------
public CheckMaxAmmo(id) { 
	new clip,temp
	new wpn_id = get_user_weapon(id,clip,temp)
	switch (wpn_id) { 
		case CSW_M3:		if (clip!=8)	return true 
		case CSW_XM1014:	if (clip!=7)	return true 
		case CSW_MP5NAVY:	if (clip!=30)	return true 
		case CSW_TMP:		if (clip!=30)	return true 
		case CSW_P90:		if (clip!=50)	return true 
		case CSW_MAC10:		if (clip!=30)	return true 
		case CSW_UMP45:		if (clip!=25)	return true 
		case CSW_AK47:		if (clip!=30)	return true 
		case CSW_SG552:		if (clip!=30)	return true 
		case CSW_M4A1:		if (clip!=30)	return true 
		case CSW_AUG:		if (clip!=30)	return true 
		case CSW_SCOUT:		if (clip!=10)	return true 
		case CSW_AWP:		if (clip!=10)	return true 
		case CSW_G3SG1:		if (clip!=20)	return true 
		case CSW_SG550:		if (clip!=30)	return true 
		case CSW_M249:		if (clip!=100)	return true 
		case CSW_USP:		if (clip!=12)	return true 
		case CSW_GLOCK18:	if (clip!=20)	return true 
		case CSW_DEAGLE:	if (clip!=7)	return true 
		case CSW_P228:		if (clip!=13)	return true 
		case CSW_ELITE:		if (clip!=30)	return true 
		case CSW_FIVESEVEN:	if (clip!=20)	return true 
	}
	return false 
} 
//---------------------------------------------------------------------------------------------- 