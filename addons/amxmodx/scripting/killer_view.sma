/*	Formatright © 2011, ConnorMcLeod

	This plugin is free software;
	you can redistribute it and/or modify it under the terms of the
	GNU General Public License as published by the Free Software Foundation.

	This program is distributed in the hope that it will be useful,
	but WITHOUT ANY WARRANTY; without even the implied warranty of
	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
	GNU General Public License for more details.

	You should have received a copy of the GNU General Public License
	along with this plugin; if not, write to the
	Free Software Foundation, Inc., 59 Temple Place - Suite 330,
	Boston, MA 02111-1307, USA.
*/

#include <amxmodx>

#include <fakemeta>
#include <hamsandwich>

#define VERSION "0.1.0"
#define PLUGIN "Killer's view"

#define        m_flNextSpecButtonTime                    100
#define        m_fDeadTime                                    354

new gmsgScreenFade
new g_iMaxPlayers
new g_pCvarBlockChangeViewTime, g_pCvarKv3rdPerson, g_pCvarKvFade

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, "ConnorMcLeod")

	gmsgScreenFade = get_user_msgid("ScreenFade")

	g_iMaxPlayers = get_maxplayers()

	g_pCvarBlockChangeViewTime = register_cvar("kv_buttonsdelay", "2.0")
	g_pCvarKv3rdPerson = register_cvar("kv_3rdview", "0") // 0 = first person
	g_pCvarKvFade = register_cvar("kv_fade", "030000000180") // RRRGGGBBBAAA

	RegisterHam(Ham_Killed, "player", "OnCBasePlayer_Killed_Post", true)
}

#if AMXX_VERSION_NUM < 183
    public client_disconnect( id )
#else
    public client_disconnected( id )
#endif
{
	remove_task( id );
}

public freeChaseCam( id )
{
	engclient_cmd(id, "specmode", "2")
}

#define SET_KILLER_VIEW(%1) \
	set_pev(id, pev_deadflag, DEAD_DEAD); \
	flTime = get_gametime(); \
	set_pdata_float(id, m_fDeadTime, flTime - 3.1); \
	ExecuteHam(Ham_Think, id); \
	engclient_cmd(id, "specmode", %1)

public OnCBasePlayer_Killed_Post( id, killer )
{
	if( !killer || killer > g_iMaxPlayers || id == killer )
	{
		return
	}

	new Float:flTime;

	switch(get_pcvar_num(g_pCvarKv3rdPerson))
	{
		case 1:
		{
			SET_KILLER_VIEW( "1" )
		}
		case 2:
		{
			set_task( 2.0, "freeChaseCam", id )
			return;
		}
		default:
		{
			SET_KILLER_VIEW( "4" )
		}
	}

	set_pdata_float(id, m_flNextSpecButtonTime, flTime + get_pcvar_float(g_pCvarBlockChangeViewTime))

	set_pev(id, pev_deadflag, DEAD_DYING)
	set_pev(id, pev_nextthink, flTime + 0.1)
	set_pdata_float(id, m_fDeadTime, flTime + 9999.0)

	new szFade[13], l = get_pcvar_string(g_pCvarKvFade, szFade, charsmax(szFade))
	if( l == 12 )
	{
		new r, g, b, a

		r = (szFade[0] - '0') * 100 + (szFade[1] - '0') * 10 + (szFade[2] - '0')
		g = (szFade[3] - '0') * 100 + (szFade[4] - '0') * 10 + (szFade[5] - '0')
		b = (szFade[6] - '0') * 100 + (szFade[7] - '0') * 10 + (szFade[8] - '0')
		a = (szFade[9] - '0') * 100 + (szFade[10] - '0') * 10 + (szFade[11] - '0')

		message_begin(MSG_ONE_UNRELIABLE, gmsgScreenFade, .player=id)
		write_short( 2<<12 )
		write_short( 1<<11 )
		write_short( 0 )
		write_byte( r )
		write_byte( g )
		write_byte( b )
		write_byte( a )
		message_end()
	}
}
