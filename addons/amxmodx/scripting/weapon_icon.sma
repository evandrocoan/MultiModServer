/**
* Changelog
*
* version 0.1
*	- Intial Release
*
* version 0.2
* 	- Fixed intial blank display of status
*	- Fixed on/off bug
* version 0.3
*	- Added suggestion: Use else/if
*	- Added suggestion: use get_players() instead of hardcoded 32
*	- Added suggestion: Changed register_forward() to register_event("CurWeapon"...)
*	- Added attempt to remove icon on death (remove_weapon_icon)
* version 0.4
*	- Completley added get_players() (whoops :| )
*	- Fixed crashing bug
*	- 2nd related bug - crashed CS upon death FIXED
*	- Finally posted some screenys :)
*	- Reverted icon_origin to a normal variable and set it to {0,0,0}
* version 0.5 (now == 5.0 KB! ha ha ha ha)
*	- Added "is_user_ok()" function
*	- Added "add_weapon_icon()" function
*	- Added "remove_weapon_icon()" function
*	- Changed use of direct manipulation of cvar "amx_show_weapon_icon" to use of a pcvar instead
*	- Attempt at removal of icon upon player's death #2 (with combo of attempt 1)
*	- No more fakemeta depedency! (for sure)
* version 0.5c
*	- Removed add_weapon_icon() function, caused the icon to continue the stay after gun change and simply add the icon to the display
*	- Modified color to a lighter green, request for a different color started
* version 0.6
*	- Added color changing icon to represent how much ammo is left
*	- Weapon icon now is removed upon death & replaced when user spawns (for sure)
* version 1.0 (Finally! w00t)
*	- Approved it! AWESOME! Thanks Hawk552!
*	- Change color back to green (sorry about the purple)
*	- Added notes to file with possible ideas
*
*/

#include <amxmodx>

#define PLUGIN "Weapon Icon"
#define VERSION "1.0"
#define AUTHOR "Zenix (m$ubn)"

new iconstatus;
new user_icons[32][192];
new icon_origin[3] = {0,0,0}
new pcv_show;
new pcv_iloc;

public plugin_init() {
	register_plugin(PLUGIN, VERSION, AUTHOR)
	
	register_event ("CurWeapon", "update_icon", "ab")
	register_event("DeathMsg", "event_death", "a")
	pcv_show = register_cvar("amx_show_weapon_icon", "1");
	pcv_iloc = register_cvar("amx_show_weapon_icon_location", "1");
	register_concmd("amx_weapon_icon", "weapon_icon_toggle", ADMIN_CVAR, "Toggle display of the weapon icon on/off (default on)")
	
	check_icon_loc();
}

public update_icon(id) {
	check_icon_loc();
	if(!get_pcvar_num(pcv_show) || get_pcvar_num(pcv_iloc) == 0)
		return PLUGIN_CONTINUE;
	
	if(is_user_alive(id))
	{
		new iwpn, wclip, wammo, sprite[192], icon_color[3] = {0, 160, 0}
		
		remove_weapon_icon(id)
		
		iwpn = get_user_weapon(id, wclip, wammo)
		switch(iwpn) {
			case CSW_P228: sprite = "d_p228"
				case CSW_SCOUT: sprite = "d_scout"
				case CSW_HEGRENADE: sprite = "d_grenade"
				case CSW_XM1014: sprite = "d_xm1014"
				case CSW_C4: sprite = "d_c4"
				case CSW_MAC10: sprite = "d_mac10"
				case CSW_AUG: sprite = "d_aug"
				case CSW_SMOKEGRENADE: sprite = "d_grenade"
				case CSW_ELITE: sprite = "d_elite"
				case CSW_FIVESEVEN: sprite = "d_fiveseven"
				case CSW_UMP45: sprite = "d_ump45"
				case CSW_SG550: sprite = "d_sg550"
				case CSW_GALIL: sprite = "d_galil"
				case CSW_FAMAS: sprite = "d_famas"
				case CSW_USP: sprite = "d_usp"
				case CSW_MP5NAVY: sprite = "d_mp5navy"
				case CSW_M249: sprite = "d_m249"
				case CSW_M3: sprite = "d_m3"
				case CSW_M4A1: sprite = "d_m4a1"
				case CSW_TMP: sprite = "d_tmp"
				case CSW_G3SG1: sprite = "d_g3sg1"
				case CSW_FLASHBANG: sprite = "d_flashbang"
				case CSW_DEAGLE: sprite = "d_deagle"
				case CSW_SG552: sprite = "d_sg552"
				case CSW_AK47: sprite = "d_ak47"
				case CSW_KNIFE: sprite = "d_knife"
				case CSW_P90: sprite = "d_p90"
				case CSW_VEST: sprite = "suit_full"
				case CSW_VESTHELM: sprite = "suithelmet_full"
				case CSW_GLOCK18: sprite = "d_glock18"
				case CSW_AWP: sprite = "d_awp"
				case 0: sprite = ""
				default: sprite = ""
		}
		if (is_user_ok(id)) {
			if (equali(sprite, "") || !is_user_ok(id)) {
				remove_weapon_icon(id)
				} else {
				// draw the sprite itself (only on a human user's screen)
				// marker ////////////////////////////////////////////////////////////////////////////////
				message_begin(MSG_ONE,iconstatus,icon_origin,id);
				write_byte(1); // status (0=hide, 1=show, 2=flash)
				write_string(sprite); // sprite name
				
				/*
				4 stages - Normal, 1 Clip, No Clip + Some ammo, Completely Out
				
				*/
				
				// ammo check, this is for the color of the icon
				get_user_ammo(id, iwpn, wammo, wclip) // update vars correctly
				if (wclip == 0 && wammo == 0) icon_color = {0, 0, 255} // outta ammo!
				if (wclip == wammo || wclip > wammo) icon_color = {255, 150, 150} // last clip!
				if (wammo > 0 && wclip == 0) icon_color = {255, 100, 100} // almost out!
				// attempt at percentage max clip & % red/green color
				// 1: Get max ammo for weapon
				//maxammo = maxclip(iwpn);
				
				
				write_byte(icon_color[0]); // red
				write_byte(icon_color[1]); // green
				write_byte(icon_color[2]); // blue
				message_end();
			}
			user_icons[id] = sprite;
		}
	}
	return PLUGIN_CONTINUE
} 

public weapon_icon_toggle(id) {
	new toggle[32], players[32], num, player, status[32] = "enabled"
	read_argv(1, toggle, 1)
	
	if (equali(toggle, "1")) {
		status = "enabled"
		} else if (equali(toggle, "0")) {
		status = "disabled"
		} else if (equali(toggle, "")) {
		console_print(id, "Usage: amx_weapon_icon <1/0> - Toggles wether or not showing the user's current weapon as an icon")
		console_print(id, "Weapon Icon is currently %s", status)
		return PLUGIN_HANDLED
	}
	
	set_cvar_string("amx_show_weapon_icon", toggle)
	client_print(0, print_chat, "Weapon Icon is now %s", status)
	get_players(players, num)
	for (new i=0; i<num; i++) {
		player = players[i]
		if (!equali(user_icons[player], "") && !equali(players[i], "") && is_user_ok(id)) {
			remove_weapon_icon(i)
		}
	}
	return PLUGIN_CONTINUE
}

public remove_weapon_icon(id) {
	if (is_user_ok(id)) {
		message_begin(MSG_ONE,iconstatus,icon_origin,id);
		write_byte(0);
		write_string(user_icons[id]);
		message_end();
	}
}

public is_user_ok(id) {
	// check if the user is "ok": they are connected, not a bot, and alive
	if (is_user_connected(id) && !is_user_bot(id) && is_user_alive(id))
		return true
	return false
}

public event_death() {
	new player = read_data(2) // the dead player's ID (1-32)
	if (is_user_connected(player) && !is_user_bot(player)) { // remove icon
		message_begin(MSG_ONE,iconstatus,icon_origin,player);
		write_byte(0);
		write_string(user_icons[player]);
		message_end();
	}
}

public check_icon_loc() {
	if(!get_pcvar_num(pcv_iloc))
		return PLUGIN_CONTINUE;
	new value = get_pcvar_num(pcv_iloc);
	if (value == 0)
		iconstatus = 0;
	if (value == 1)
		iconstatus = get_user_msgid("StatusIcon");
	if (value == 2)
		iconstatus = get_user_msgid("Scenario");
	return PLUGIN_CONTINUE;
}

