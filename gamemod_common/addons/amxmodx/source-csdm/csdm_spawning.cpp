#include "amxxmodule.h"
#include "csdm_spawning.h"

SpawnMngr g_SpawnMngr;
int g_SpawnMethod = -1;

SpawnMethod::SpawnMethod(const char *name, int callback)
{
	m_Name.assign(name);
	m_Callback = callback;
}

void SpawnMethod::Spawn(int player, bool fake)
{
	MF_ExecuteForward(m_Callback, (cell)player, (cell)(fake ? 1 : 0));
}

const char *SpawnMethod::GetName()
{
	return m_Name.c_str();
}

int SpawnMngr::AddMethod(const char *name, int callback)
{
	SpawnMethod *pSpawn = new SpawnMethod(name, callback);

	m_Methods.push_back(pSpawn);

	return (int)m_Methods.size() - 1;
}

void SpawnMngr::SpawnPlayer(int method, int player, bool fake)
{
	if (method < 0 || method >= (int)m_Methods.size())
		return;

	m_Methods[method]->Spawn(player, fake);
}

SpawnMethod *SpawnMngr::GetSpawn(int method)
{
	if (method < 0 || method >= (int)m_Methods.size())
		return NULL;

	return m_Methods[method];
}

void SpawnMngr::Clear()
{
	for (size_t i=0; i<m_Methods.size(); i++)
		delete m_Methods[i];

	m_Methods.clear();
}

size_t SpawnMngr::Spawns()
{
	return m_Methods.size();
}

SpawnMngr::~SpawnMngr()
{
	Clear();
}
