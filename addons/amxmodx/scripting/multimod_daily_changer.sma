/*********************** Licensing *******************************************************
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
*  You should have received a copy of the GNU General Public License
*  along with this program.  If not, see <http://www.gnu.org/licenses/>.
*
*****************************************************************************************
* Daily Mapcycle
*  by JustinHoMi
**************************************
* Ported by Burnzy
*  Visit www.burnsdesign.org
**************************************
* Allows you to specify a different map rotation for every day, mapcycles.txt should
* be placed in yourgamemod/mapcycles/day and for daily_cfgs to be placed into
* yourgamemod/mapcycles/day/cfg | The cfgs should be started with the
* week days first three letters in the name.
*
* REMEMBER!:
* ==========
*  -the files in the yourgamemod/mapcycles/day folder should be .txt
*  -the files in the yourgamemod/mapcycles/day/cfg folder should be .cfg
*
* Examples:
* =========
*  Sun.txt
*  Wed.txt
*  Fri.txt
*
*  Sun.cfg
*  Wed.cfg
*  Fri.cfg
*
*   (Sun,Mon,Tue,Wed,Thu,Fri,Sat).cfg
*   (Sun,Mon,Tue,Wed,Thu,Fri,Sat).txt
*
* In the cfg's, u just put what cvars u want to apply for that day
* In the txt's, u just put the maps u want to be rotated though on that day
*	Example:
*	   de_dust
*	   de_aztec_cz
*	   cs_assault_cz
* (u dont need .bsp)
*
* Multi-Mod Daily Changer's Change log:
*  v1.0, Make compatibility with multimod_manager.sma
*  v2.0, Make compatibility with galileo_reloaded.sma and multimod_mapchooser.sma
*
* Daily Changer's Change log:
*  v1.2, Make it .ini for map stuff
*  v1.1, Made it so that there is
*  v1.0, Initial Release
*************************************/

#include <amxmodx>
#include <amxmisc>

public plugin_init()
{
	register_plugin("Multi-Mod Daily Changer", "2.0", "Addons zz/JustinHoMi & JGHG")

	new isFirstTime[32]
	get_localinfo( "isFirstTimeLoadMapCycle", isFirstTime, charsmax( isFirstTime ) );

	new isFirstTimeNum = str_to_num( isFirstTime )

	if ( isFirstTimeNum == 2 )
	{
		new today[8]
		new mapCycleFilePath[32]
		new serverCfgFilePath[32]

		get_time("%a", today, 8)
		formatex( mapCycleFilePath, charsmax( mapCycleFilePath ), "mapcycles/day/%s.txt", today )
		formatex( serverCfgFilePath, charsmax( serverCfgFilePath ), "mapcycles/day/cfg/%s.cfg", today)

		if( file_exists(mapCycleFilePath) )
		{
			set_cvar_string("mapcyclefile", mapCycleFilePath)

			if( find_plugin_byfile( "galileo_reloaded.amxx" ) != -1 )
			{   
				new galileo_mapfile = get_cvar_pointer( "gal_vote_mapfile" )

				if( galileo_mapfile )
				{   
					set_pcvar_string( galileo_mapfile, mapCycleFilePath )
				}

			} else if( find_plugin_byfile( "multimod_mapchooser.amxx" ) != -1 )
			{   
				if( callfunc_begin("plugin_init", "multimod_mapchooser.amxx" ) == 1 )
				{   
					callfunc_end()

				} else
				{   
					new error[128]="ERROR at configMapManager!! multimod_mapchooser.amxx NOT FOUND!^n"
					client_print( 0, print_console , error )
					server_print( error )
				}
			}
		}
		if( file_exists(serverCfgFilePath) )
		{
			set_cvar_string("mapchangecfgfile", serverCfgFilePath)
		}
	}
}
