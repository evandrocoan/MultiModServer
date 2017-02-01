/* ATAC Team Attack Addon
*
* Copyright © 2006-2007, ATAC Team
*
* This file is provided as is (no warranties).
*
*/

#include <amxmodx>
#include <fakemeta>
#include <atac>

#define PLUGIN "Team Attack"
#define VERSION "1.0"
#define AUTHOR "ATAC Team"

new bool:gRestart
new gmsgHealth
new gCVARRestart
new gCVARTeamAttacks
new gCVARAdminsImmune

new gCVARSlapAttacker
new gCVARSlayonMaxattacks
new gCVARHealthRestore
new gCVARMirrorDamage
new gCVARNoattackWithin

new no_attack[ 33 ]

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	register_event( "ResetHUD", "Event_ResetHUD", "be" )
	register_event( "TextMsg", "RestartGame", "a", "2=#Game_will_restart_in" )
	atac_register_addon()

	gmsgHealth = get_user_msgid( "Health" )
	gCVARRestart = get_cvar_pointer( "sv_restart" )
	gCVARTeamAttacks = get_cvar_pointer( "atac_team_attacks" )
	gCVARAdminsImmune = get_cvar_pointer( "atac_admins_immune" )
	gCVARSlapAttacker = register_cvar( "atac_slap_attacker", "0" )
	gCVARSlayonMaxattacks = register_cvar( "atac_slayon_maxattacks", "0" )
	gCVARHealthRestore = register_cvar( "atac_health_restore", "0" )
	gCVARMirrorDamage = register_cvar( "atac_mirror_damage", "0" )
	gCVARNoattackWithin = register_cvar( "atac_noattack_within", "5" )
}

public RestartGame()
{
	gRestart = true
	set_task( float( get_pcvar_num( gCVARRestart ) ) - 0.2, "ResetGame" )
}

public ResetGame()
{
	gRestart = false
}

public Event_ResetHUD( id )
{
	if ( !gRestart && get_pcvar_num( gCVARNoattackWithin ) )
		no_attack[ id ] = floatround( get_gametime() + get_pcvar_num( gCVARNoattackWithin ) )
}

public atac_team_attack( attacker, victim, damage )
{
	if ( get_pcvar_num( gCVARAdminsImmune ) > 1 && get_user_flags( attacker ) & ADMIN_IMMUNITY )
		return PLUGIN_CONTINUE
	
	static health

	if ( get_pcvar_num( gCVARSlapAttacker ) )
		user_slap( attacker, 0 )

	if ( get_pcvar_num( gCVARSlayonMaxattacks ) )
	{
		if ( get_atac_attacks( attacker ) >= get_pcvar_num( gCVARTeamAttacks ) )
			user_kill( attacker )
	}
	if ( get_pcvar_num( gCVARHealthRestore ) )
	{
		health = get_user_health( victim ) + damage
		update_health( victim, health )
	}
	if ( get_pcvar_num( gCVARMirrorDamage ) )
	{
		health = get_user_health( attacker ) - damage

		if ( health <= 0 )
			user_kill( attacker )
		else
			update_health( attacker, health )
	}
	if ( get_pcvar_num( gCVARNoattackWithin ) && no_attack[ victim ] >= floatround( get_gametime() ) )
		user_kill( attacker )

	return PLUGIN_CONTINUE
}

update_health( id, health ) // Special Health Updater so that ATAC can deal with adding/subtracting health in the same frame
{
	set_pev( id, pev_dmg_inflictor, 0 ) // zero inflictor pointer
	set_pev( id, pev_health, float( health ) ) // set health
	emessage_begin( MSG_ONE_UNRELIABLE, gmsgHealth, _, id ) // resend health message
	ewrite_byte( health )
	emessage_end()
}
