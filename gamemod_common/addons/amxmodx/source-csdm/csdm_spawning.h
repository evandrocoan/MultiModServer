#ifndef _INCLUDE_CSDMSPAWNING_H
#define _INCLUDE_CSDMSPAWNING_H

#include "CVector.h"
#include "CString.h"

class SpawnMethod
{
public:
	SpawnMethod(const char *name, int callback);
public:
	void Spawn(int player, bool fake);
	const char *GetName();
private:
	String m_Name;
	int m_Callback;
};

class SpawnMngr
{
public:
	~SpawnMngr();
public:
	int AddMethod(const char *name, int callback);
	void SpawnPlayer(int method, int player, bool fake);
	size_t Spawns();
	SpawnMethod *GetSpawn(int method);
	void Clear();
private:
	CVector<SpawnMethod *>m_Methods;
};

extern SpawnMngr g_SpawnMngr;

#endif //_INCLUDE_CSDMSPAWNING_H
