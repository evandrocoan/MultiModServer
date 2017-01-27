/** AMX Mod X Script
 *
 *  This program is free software; you can redistribute it and/or modify it
 *  under the terms of the GNU General Public License as published by the
 *  Free Software Foundation; either version 2 of the License, or ( at
 *  your option ) any later version.
 *
 *  This program is distributed in the hope that it will be useful, but
 *  WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
 *  See the GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 * ***********************************************************
 *
 */

#include <amxmodx>


#define MAX_MAPNAME_LENGHT 64

new g_nextMapName   [ MAX_MAPNAME_LENGHT  ];
new g_currentMapName[ MAX_MAPNAME_LENGHT  ];


public plugin_init()
{
    register_plugin( "Show Server Info", "1.0", "Addons zz" );
}

public plugin_cfg()
{
    set_task( 1.0, "printTheCurrentAndNextMapNames" );
}

/**
 * To print on the server console the current and next map names aligned. Output example:
 *
 * L 01/23/2017 - 00:40:44: {1.000 15768 778942    1}
 * L 01/23/2017 - 00:40:44: {1.000 15768 778943    1}
 * L 01/23/2017 - 00:40:44: {1.000 15764 778945    2}  The current map is [ cs_italy    ]
 * L 01/23/2017 - 00:40:44: {1.000 15764 778946    1}  The  next   map is [ cs_italy_cz ]
 * L 01/23/2017 - 00:40:44: {1.000 15768 778948    2}
 * L 01/23/2017 - 00:40:44: {1.000 15768 778949    1}
 *
 * There is not point in adding the entry statement to this function as its purpose is only to
 * print few lines as possible.
 */
public printTheCurrentAndNextMapNames()
{
    new nextMap     [ MAX_MAPNAME_LENGHT ];
    new currentMap  [ MAX_MAPNAME_LENGHT ];
    new lastMapcycle[ MAX_MAPNAME_LENGHT ];

    get_mapname( g_currentMapName, charsmax( g_currentMapName ) );
    get_cvar_string( "amx_nextmap", g_nextMapName, charsmax( g_nextMapName )  );

    get_localinfo( "lastmapcycle", lastMapcycle, charsmax( lastMapcycle ) );

    copy( nextMap, charsmax( nextMap ), g_nextMapName );
    copy( currentMap, charsmax( currentMap ), g_currentMapName );

    new nextLength    = strlen( nextMap );
    new currentLength = strlen( currentMap );
    new maximumLength = max( nextLength, currentLength );

    while( nextLength    < maximumLength ) nextMap  [ nextLength++    ] = ' ';
    while( currentLength < maximumLength )currentMap[ currentLength++ ] = ' ';

    nextMap   [ nextLength    ] = '^0';
    currentMap[ currentLength ] = '^0';

    server_print( "" );
    server_print( "" );
    server_print( " The current map is [ %s ]", currentMap );
    server_print( " The  next   map is [ %s ]", nextMap );
    server_print( "" );
    server_print( " The lastmapcycle: %s", lastMapcycle );
    server_print( "" );
    server_print( "" );

    return 0;
}

