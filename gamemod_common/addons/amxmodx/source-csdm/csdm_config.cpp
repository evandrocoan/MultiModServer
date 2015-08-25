#include "amxxmodule.h"
#include "csdm_amxx.h"
#include "csdm_config.h"

Config g_Config;

void fstrncpy(char *dest, const char *src, size_t length)
{
	while (length-- && *src)
		*dest++ = *src++;
    *dest = '\0';
}

void Config::AddHook(const char *section, int forward)
{
	cfghook *pHook = new cfghook;

	pHook->forward = forward;
	pHook->section.assign(section);

	m_Hooks.push_back(pHook);
}

Config::~Config()
{
	Clear();
}

void Config::Clear()
{
	List<cfghook *>::iterator iter;

	for (iter=m_Hooks.begin(); iter!=m_Hooks.end(); iter++)
	{
		if ( (*iter) )
			delete (*iter);
	}

	m_Hooks.clear();
}

CfgError Config::ReadConfig(const char *file)
{
	FILE *fp = fopen(file, "rt");

	if (!fp)
		return Config_NoFile;

	cfghook *pHook;
	List<cfghook *>::iterator iter;

	char buffer[255];
	char section[32] = {0};
	String temp;
	size_t length = 0;
	const char *ptr;
	while (!feof(fp))
	{
		buffer[0] = '\0';
		fgets(buffer, sizeof(buffer)-1, fp);
		if (buffer[0] == '\0' || buffer[0] == '\n')
			continue;
		if (buffer[0] == ';' || (buffer[0] == '\\' || buffer[1] == '\\'))
			continue;
		length = strlen(buffer);
		if (buffer[length-1] == '\n')
			buffer[--length] = '\0';
		temp.assign(buffer);
		temp.trim();
		if (temp.size() < 1)
			continue;
		ptr = temp.c_str();
		if (ptr[0] == '[')
		{
			size_t pos = 0;
			//quick state machine!11 :o
			for (size_t i=1; i<length; i++)
			{
				if (ptr[i] == ']')
					pos = i;
			}
			if (pos < 2)
				continue;		//invalid almost-section
			if (section[0] != '\0')
			{
				for (iter=m_Hooks.begin(); iter!=m_Hooks.end(); iter++)
				{
					pHook = (*iter);
					if (pHook->section.compare(section)==0)
						MF_ExecuteForward(pHook->forward, (cell)CFG_DONE, "", section);
				}
			}
			fstrncpy(section, &(ptr[1]), pos-1);
			for (iter=m_Hooks.begin(); iter!=m_Hooks.end(); iter++)
			{
				pHook = (*iter);
				if (pHook->section.compare(section)==0)
					MF_ExecuteForward(pHook->forward, (cell)CFG_RELOAD, "", section);
			}
		} else if (section[0] != '\0') {
			for (iter=m_Hooks.begin(); iter!=m_Hooks.end(); iter++)
			{
				pHook = (*iter);
				if (pHook->section.compare(section)==0)
					MF_ExecuteForward(pHook->forward, (cell)CFG_READ, ptr, section);
			}
		}
	}

	if (section[0] != '\0')
	{
		for (iter=m_Hooks.begin(); iter!=m_Hooks.end(); iter++)
		{
			pHook = (*iter);
			if (pHook->section.compare(section)==0)
				MF_ExecuteForward(pHook->forward, (cell)CFG_DONE, "", section);
		}
	}

	fclose(fp);

	return Config_Ok;
}
