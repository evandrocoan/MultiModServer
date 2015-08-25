/*	Copyright © 2008, ConnorMcLeod

	Set Player Model is free software;
	you can redistribute it and/or modify it under the terms of the
	GNU General Public License as published by the Free Software Foundation.

	This program is distributed in the hope that it will be useful,
	but WITHOUT ANY WARRANTY; without even the implied warranty of
	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
	GNU General Public License for more details.

	You should have received a copy of the GNU General Public License
	along with Set Player Model; if not, write to the
	Free Software Foundation, Inc., 59 Temple Place - Suite 330,
	Boston, MA 02111-1307, USA.
*/

#include <amxmodx>
#include <fakemeta>

#define VERSION "0.0.2"

const MAX_MODEL_LENGTH	= 32
const MAX_PLAYERS	= 32

new const model[] = "model"

new g_szModel[MAX_PLAYERS+1][MAX_MODEL_LENGTH]

new g_bitModeledPlayers
#define MarkPlayerModeled(%0)		g_bitModeledPlayers |= 1<<(%0&31)
#define ClearPlayerModeled(%0)		g_bitModeledPlayers &= ~(1<<(%0&31))
#define CheckPlayerModeled(%0)	( g_bitModeledPlayers & 1<<(%0&31) )

new g_iMaxPlayers
#define IsPlayer(%0)	( 1 <= %0 <= g_iMaxPlayers )

// pdata
const g_ulModelIndexPlayer = 491

new g_iFwd, g_iMsg
new gmsgClCorpse

public plugin_init()
{
	register_plugin("Set Player Model", VERSION, "ConnorMcLeod")

	gmsgClCorpse = get_user_msgid("ClCorpse")
	g_iMaxPlayers = get_maxplayers()
}

public client_disconnect(id)
{
	ClearPlayerModeled(id)
	CheckForwards()
}

public plugin_natives()
{
	register_library("playermodel")
	register_native("fm_set_user_model", "_set_user_model")
	register_native("fm_reset_user_model", "_reset_user_model")
}

public _set_user_model()
{
	new id = get_param(1)

	if( ! IsPlayer(id) )
	{
		log_error(AMX_ERR_NATIVE, "Invalid index %d", id)
		return 0
	}

	if( !is_user_connected(id) )
	{
		log_error(AMX_ERR_NATIVE, "Player %d not connected", id)
		return 0
	}

	MarkPlayerModeled(id)
	CheckForwards()

	new szModel[MAX_MODEL_LENGTH]
	get_string(2, szModel, charsmax(szModel))

	copy(g_szModel[id], charsmax(g_szModel[]), szModel)
	set_user_info(id, model, szModel)
	if( get_param(3) )
	{
		set_pdata_int(id, g_ulModelIndexPlayer, engfunc(EngFunc_PrecacheModel, szModel))
	}
	return 1
}

public _reset_user_model()
{
	new id = get_param(1)

	if( ! IsPlayer(id) )
	{
		log_error(AMX_ERR_NATIVE, "Invalid index %d", id)
		return 0
	}

	if( !CheckPlayerModeled(id) )
	{
		return 0
	}

	ClearPlayerModeled(id)

	if( is_user_connected(id) )
	{
		dllfunc(DLLFunc_ClientUserInfoChanged, id, engfunc(EngFunc_GetInfoKeyBuffer, id))
	}

	CheckForwards()

	return 1
}

public SetClientKeyValue(id, szInfoBuffer[], szKey[], szValue[])
{
	if( CheckPlayerModeled(id) && equal(szKey, model) && !equal(szValue, g_szModel[id]))
	{
		set_user_info(id, model, g_szModel[id])
		return FMRES_SUPERCEDE
	}
	return FMRES_IGNORED
}

public Message_ClCorpse()
{
	new id = get_msg_arg_int(12)
	if( CheckPlayerModeled(id) )
	{
		set_msg_arg_string(1, g_szModel[id])
	}
}

CheckForwards()
{
	if( g_bitModeledPlayers )
	{
		if( !g_iFwd )
		{
			g_iFwd = register_forward(FM_SetClientKeyValue, "SetClientKeyValue")
		}
		if( !g_iMsg  )
		{
			g_iMsg = register_message(gmsgClCorpse, "Message_ClCorpse")
		}
	}
	else
	{
		if( g_iFwd )
		{
			unregister_forward(FM_SetClientKeyValue, g_iFwd)
			g_iFwd = 0
		}
		
		if( g_iMsg )
		{
			unregister_message(gmsgClCorpse, g_iMsg)
			g_iMsg = 0
		}
	}
}
