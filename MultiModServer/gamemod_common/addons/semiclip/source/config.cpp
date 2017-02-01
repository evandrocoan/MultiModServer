#include "main.h"

#define CONFIG_FILE "config.ini"

static char mPluginPath[256];
static char mConfigPath[256];

static inline int IsCharSpecial(char j)
{
	return (j == ' ' || j == '"' || j == ';' || j == '\t' || j == '\r' || j == '\n');
}
void TrimSpace(char *pneedle)
{
	char *phaystack = pneedle;
	char *pbuf = pneedle;

	while(IsCharSpecial(*pbuf))
		++pbuf;

	while(*pbuf)
		*phaystack++ = *pbuf++;

	*phaystack = '\0';

	while(phaystack > pneedle && *--phaystack && IsCharSpecial(*phaystack))
		*phaystack = '\0';
}
static inline int clamp(int value,int _min,int _max)
{
	return value < _min ? _min : (value > _max ? _max : value);
}
static inline float clamp(double value,float _min,float _max)
{
	return value < _min ? _min : (value > _max ? _max : value);
}
int parse_settings(const char *setting,const char *value,TypeRead iType)
{
	if(!strcmp(setting,"semiclip"))
		semiclipData.semiclip = clamp(atoi(value),0,1);

	else if(!strcmp(setting,"crouch"))
		semiclipData.crouch = clamp(atoi(value),0,1);

	else if(!strcmp(setting,"distance"))
		semiclipData.distance = clamp(atof(value),64.0,200.0);

	else if(!strcmp(setting,"transparency"))
	{
		int val = clamp(atoi(value),0,255);

		semiclipData.transparency = (val > 254 ? 0 : val);
	}
	else if(!strcmp(setting,"time"))
		semiclipData.time = clamp(atof(value),0.0,60.0);

	else if(!strcmp(setting,"noteamflash"))
		semiclipData.noteamflash = clamp(atoi(value),0,1);

	else if(!strcmp(setting,"effects"))
		semiclipData.effects = clamp(atoi(value),0,1);

	else if(!strcmp(setting,"team"))
		semiclipData.team = clamp(atoi(value),0,3);

	else if(iType != READ_IN_GAME)
	{
		if(!strcmp(setting,"flashfix"))
			semiclipData.flashfix = clamp(atoi(value),0,1);

		else if(!strcmp(setting,"patch"))
			semiclipData.patch = clamp(atoi(value),0,1);
	}
	else return 0;

	return 1;
}
void print_settings()
{
	static const char *szConditon[] = {
		" (for all)",
		" (only Terrorists)",
		" (only Counter-Terrorists)",
		" (only teammates)"
	};

	printf("\n\nusage: semiclip_option\n\n [command]	[value]   [description]\n\n");
	printf(" semiclip	%d	- enable/disable semiclip\n",semiclipData.semiclip);
	printf(" team		%d	- condition for teams %s\n",semiclipData.team,szConditon[semiclipData.team]);
	printf(" time		%0.0f	- how many time in seconds semiclip will work from the beginning of the round\n",semiclipData.time);
	printf(" patch		%d	- fix jamming on a mobile platform\n",semiclipData.patch);
	printf(" crouch		%d	- allows jump to crouching players when semiclip works\n",semiclipData.crouch);
	printf(" effects	%d	- effect of transparency of the player. Depends from distance between players\n",semiclipData.effects);
	printf(" flashfix	%d	- fix flashing throw transparent players\n",semiclipData.flashfix);
	printf(" noteamflash	%d	- teammates blocking flashing\n",semiclipData.noteamflash);
	printf(" distance	%0.0f	- at what distance player can have transparency and semiclip\n",semiclipData.distance);
	printf(" transparency	%d	- transparency of the player\n\n",semiclipData.transparency);
}
static int parse_config(const char *path,TypeRead iType)
{
	FILE *fp;
	fp = fopen(path,"rt");

	if(!fp)
	{
		return 0;
	}

	char *value;
	char buf[256];

	while(!feof(fp))
	{
		if(!fgets(buf,sizeof(buf) - 1,fp))
			break;

		value = strchr(buf,'=');

		if(value == NULL)
		{
			continue;
		}

		*(value++) = '\0';

		TrimSpace(buf);
		TrimSpace(value);

		if(*buf == '\0' || *value == '\0' || parse_settings(buf,value,iType))
		{
			continue;
		}
	}

	//forcing set settings not own for cs

	char szDir[16];
	GET_GAME_DIR(szDir);
	if(strcmp(szDir,"cstrike") != 0)
	{
		semiclipData.team = 0;
		semiclipData.time = 0.0f;
		semiclipData.flashfix = 0;
		semiclipData.noteamflash = 0;
	}
	else if(semiclipData.flashfix == 0)
		semiclipData.noteamflash = 0;

	return (fclose(fp) != EOF);
}
int load_config_maps()
{
	char *tempMap;

	char path[256];
	char mapName[32];

	g_bNotActive = false;

	//read default settings
	parse_config(mConfigPath,READ_IN_GAME);
	strncpy(mapName,STRING(gpGlobals->mapname),sizeof(mapName) - 1);

	tempMap = strchr(mapName,'_');

	if(tempMap != NULL)
	{
		*tempMap = '\0';
		snprintf(path,sizeof(path) - 1,"%smaps/prefix_%s.ini",mPluginPath,mapName);

		//read settings with prefix maps
		parse_config(path,READ_IN_GAME);
	}

	snprintf(path,sizeof(path) - 1,"%smaps/%s.ini",mPluginPath,STRING(gpGlobals->mapname));

	//read settings with map name
	parse_config(path,READ_IN_GAME);
	if(!semiclipData.semiclip)
	{
		g_bNotActive = true;
		g_pFunctionTable->pfnPM_Move = NULL;
		g_pEnginefuncsTable_Post->pfnAlertMessage = NULL;
	}
	else
	{
		if(!semiclipData.time)
		{
			g_bNotActive = false;
			g_pFunctionTable->pfnPM_Move = PM_Move;
			g_pEnginefuncsTable_Post->pfnAlertMessage = NULL;
		}
		else g_pEnginefuncsTable_Post->pfnAlertMessage = AlertMessage;
	}
	return 1;
}
int load_config()
{
	char *pos;
	strcpy(mConfigPath,GET_PLUGIN_PATH(PLID));

	pos = strrchr(mConfigPath,'/');

	if(pos == NULL || *pos == '\0')
	{
		return 0;
	}

	*(pos + 1) = '\0';

	strncpy(mPluginPath,mConfigPath,sizeof(mPluginPath) - 1);
	strcat(mConfigPath,CONFIG_FILE);

	//default settings
	semiclipData.semiclip = 1;
	semiclipData.time = 0.0f;
	semiclipData.team = 3;
	semiclipData.patch = 0;
	semiclipData.crouch = 0;
	semiclipData.flashfix = 0;
	semiclipData.noteamflash = 0;
	semiclipData.distance = 160.0f;
	semiclipData.transparency = 100;

	return parse_config(mConfigPath,READ_START);
}
