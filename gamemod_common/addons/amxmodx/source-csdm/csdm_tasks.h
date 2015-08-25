#ifndef _INCLUDE_CSDM_TASKS_H
#define _INCLUDE_CSDM_TASKS_H

#include "csdm_timer.h"
#include "CString.h"
#include "sh_stack.h"

class Respawn : public ITask
{
public:
	Respawn(edict_t *pEdict, int notify=-1);
	void Run();
	bool deleteThis();
	void set(edict_t *pEdict, int notify=-1);
	static Respawn *NewRespawn(edict_t *pEdict, int notify);
private:
	edict_t *m_pEdict;
	int m_Notify;
};

extern CStack<Respawn *> g_FreeSpawns;

class Welcome : public ITask
{
public:
	Welcome(edict_t *pEdict) :
	  m_pEdict(pEdict)
	  {
	  };
public:
	void Run();
private:
	edict_t *m_pEdict;
};

class RemoveWeapon : public ITask
{
public:
	RemoveWeapon(edict_t *pOwner, edict_t *pBox, edict_t *pWeapon)
	  {
		  set(pOwner, pBox, pWeapon);
	  };
public:
	void Run();
	bool deleteThis();
	void invalidate();
	bool valid();
	static void SchedRemoval(int seconds, edict_t *pOwner, edict_t *pBox, edict_t *pWeapon);
	void set(edict_t *pOwner, edict_t *pBox, edict_t *pWeapon);
private:
	edict_t *m_pOwner;
	edict_t *m_pBox;
	edict_t *m_pWeapon;
	int box_serial;
	int weapon_serial;
	int m_BaseIdx;
};

class FindWeapon : public ITask
{
public:
	FindWeapon(edict_t *pOwner, const char *className, int delay);
	void Run();
	bool deleteThis();
	static FindWeapon *NewFindWeapon(edict_t *pOwner, const char *className, int delay);
	void set(edict_t *pOwner, const char *className, int delay);
private:
	String m_Classname;
	edict_t *m_pOwner;
	int m_Delay;
};

class RestartRoundTask : public ITask
{
public:
	RestartRoundTask() { };
	void Run();
};

extern CStack<FindWeapon *> g_FreeFinds;

void ClearAllTaskCaches();

#endif //_INCLUDE_CSDM_TASKS_H
