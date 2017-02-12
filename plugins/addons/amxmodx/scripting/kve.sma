#include <amxmodx>
#include <amxmisc>
#include <fakemeta>
#include <regex>

enum event_t
{
	m_szClassName[32],
	m_szKeyName[64],
	m_szFunction[32],
	m_szPlugin[64],
	bool:m_bTriggered
};

new g_Events[128][event_t];
new g_iEventsNum = 0;

public plugin_natives()
{
	register_native("register_keyvalue", "__register_keyvalue");
}
public plugin_precache()
{
	// Handle worldspawn keyvalues
	new szWorldData[1024];
	new szFileName[128], szMapName[64];
	get_mapname(szMapName, 63);
	formatex(szFileName, 127, "maps/%s.bsp", szMapName);
	new hFile = fopen(szFileName, "rb");
	if (hFile)
	{
		new iOffset, chNewChar, n;
		fseek(hFile, 4, SEEK_SET);
		fread(hFile, iOffset, BLOCK_INT);
		fseek(hFile, iOffset, SEEK_SET);
		do
		{
			fread(hFile, chNewChar, BLOCK_CHAR)
			szWorldData[n++]  = chNewChar;
		}while(n<1024&&chNewChar!='}')
		fclose(hFile);
		new szKeyName[64], szLine[1024], szValue[1024];
		while(szWorldData[0])
		{
			strtok(szWorldData, szLine, 1023, szWorldData, 1023, '^n');
			if(!strcmp(szLine,"{")||!strcmp(szLine,"}")) continue;
			parse(szLine, szKeyName, 63, szValue, 1023);
			for(new i=0;i<g_iEventsNum;i++)
			{
				if(!strcmp("worldspawn", g_Events[i][m_szClassName], 1) &&
					!strcmp(szKeyName, g_Events[i][m_szKeyName], 1))
				{
					callfunc_begin(g_Events[i][m_szFunction], g_Events[i][m_szPlugin]);
					{
						callfunc_push_int(1);
						callfunc_push_str(szValue, false);
					}
					callfunc_end();
					g_Events[i][m_bTriggered] = true;
				}
			}
		}
		for(new i=0;i<g_iEventsNum;i++)
		{
			if(!strcmp("worldspawn", g_Events[i][m_szClassName]))
			{
				if(!g_Events[i][m_bTriggered])
				{
					callfunc_begin(g_Events[i][m_szFunction], g_Events[i][m_szPlugin]);
					{
						callfunc_push_int(0);
						callfunc_push_str("", false);
					}
					callfunc_end();
				}
				g_Events[i] = g_Events[g_iEventsNum - 1];
				g_iEventsNum--;
			}
		}
	}
	// Done with worldspawn keyvalues

	register_forward(FM_KeyValue, "on_key_value");
}
public plugin_init()
{
	register_plugin("KeyValue Event Manager", "1.0", "ts2do");
}

public on_key_value(entid, kvdid)
{
	if(pev_valid(entid))
	{
		new szClassName[32], szKeyName[64], szValue[1024];
		get_kvd(kvdid, KV_ClassName, szClassName, 31);
		get_kvd(kvdid, KV_KeyName, szKeyName, 63);
		get_kvd(kvdid, KV_Value, szValue, 1023);
	
		for(new i=0;i<g_iEventsNum;i++)
		{
			if(!strcmp(szClassName, g_Events[i][m_szClassName], 1) &&
				!strcmp(szKeyName, g_Events[i][m_szKeyName], 1))
			{
				callfunc_begin(g_Events[i][m_szFunction], g_Events[i][m_szPlugin]);
				{
					callfunc_push_str(szValue, false);
					callfunc_push_int(entid);
					callfunc_push_int(kvdid);
				}
				callfunc_end();
			}
		}
	}
	return FMRES_IGNORED;
}
public __register_keyvalue(iPlugin,iParams)
{
	static szClassName[32], szKeyName[64], szFunction[32], szPlugin[64],
		szName[2], szVersion[2], szAuthor[2], szStatus[2];
	get_string(1, szClassName, 31);
	get_string(2, szKeyName, 31);
	get_string(3, szFunction, 31);
	get_plugin(iPlugin, szPlugin, 63, szName, 1, szVersion, 1, szAuthor, 1, szStatus, 1);

	copy(g_Events[g_iEventsNum][m_szClassName], 31, szClassName);
	copy(g_Events[g_iEventsNum][m_szKeyName], 63, szKeyName);
	copy(g_Events[g_iEventsNum][m_szFunction], 31, szFunction);
	copy(g_Events[g_iEventsNum][m_szPlugin], 63, szPlugin);
	g_Events[g_iEventsNum][m_bTriggered] = false;
	g_iEventsNum++;
}
