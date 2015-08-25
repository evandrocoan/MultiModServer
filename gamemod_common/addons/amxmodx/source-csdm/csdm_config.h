#ifndef _INCLUDE_CSDM_CONFIG_H
#define _INCLUDE_CSDM_CONFIG_H

#include "CString.h"
#include "sh_list.h"

#define	CFG_READ	0
#define	CFG_RELOAD	1
#define	CFG_DONE	2

enum CfgError
{
	Config_Ok=0,
	Config_NoFile,
	Config_BadFile
};

class Config
{
public:
	~Config();
public:
	CfgError ReadConfig(const char *file);
	void AddHook(const char *section, int forward);
	void Clear();
private:
	struct cfghook
	{
		int forward;
		String section;
	};
	List<cfghook *> m_Hooks;
};

extern Config g_Config;

#endif //_INCLUDE_CSDM_CONFIG_H
