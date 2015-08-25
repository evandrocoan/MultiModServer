#ifndef _INCLUDE_CSDM_TIMERS_H
#define _INCLUDE_CSDM_TIMERS_H

#include "sh_list.h"

class ITask
{
public:
	~ITask() { }
	virtual void Run() =0;
	virtual bool deleteThis()
	{
		delete this;
		return false;
	}
};

struct tasksel
{
	ITask *task;
	float think;
	float interval;
};

class Timer
{
public:
	Timer();
	~Timer();
public:
	size_t Tick(float curTime);
	void AddTask(ITask *pTask, float interval);
	void Clear();
	void RemoveTask(ITask *pTask);
	void TaskInfo(int &num, int &avail);
private:
	List<tasksel *> m_Tasks;
};

extern Timer g_Timer;

#endif //_INCLUDE_CSDM_TIMERS_H
