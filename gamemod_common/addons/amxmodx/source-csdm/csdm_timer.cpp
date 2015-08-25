#include "amxxmodule.h"
#include "csdm_timer.h"
#include "sh_stack.h"

Timer g_Timer;
CStack<tasksel *> *g_FreeTasks;

Timer::~Timer()
{
	Clear();

	tasksel *pTask;
	while (!g_FreeTasks->empty())
	{
		pTask = g_FreeTasks->front();
		if (pTask->task)
			pTask->task->deleteThis();
		delete pTask;
		g_FreeTasks->pop();
	}

	m_Tasks.clear();

	delete g_FreeTasks;
	g_FreeTasks = NULL;
}

Timer::Timer()
{
	g_FreeTasks = new CStack<tasksel *>();
}

void Timer::AddTask(ITask *pTask, float interval)
{
	tasksel *pSel;

	if (g_FreeTasks->empty())
	{
		pSel = new tasksel;
	} else {
		pSel = g_FreeTasks->front();
		g_FreeTasks->pop();
	}

	pSel->task = pTask;
	pSel->interval = interval;
	pSel->think = gpGlobals->time;

	m_Tasks.push_back(pSel);
}

void Timer::RemoveTask(ITask *pTask)
{
	List<tasksel *>::iterator iter;
    iter = m_Tasks.begin();

	while (iter != m_Tasks.end())
	{
		if ( (*iter)->task == pTask )
		{
			pTask->deleteThis();
			(*iter)->task = NULL;
			g_FreeTasks->push( (*iter) );
			iter = m_Tasks.erase(iter);
			return;
		}
		iter++;
	}
}

void Timer::Clear()
{
	List<tasksel *>::iterator iter;
    iter = m_Tasks.begin();

	while (iter != m_Tasks.end())
	{
		(*iter)->task->deleteThis();
		(*iter)->task = NULL;
		g_FreeTasks->push( (*iter) );
		iter++;
	}

	m_Tasks.clear();
}

void Timer::TaskInfo(int &num, int &avail)
{
	num = m_Tasks.size();
	avail = g_FreeTasks->size();
}

size_t Timer::Tick(float curTime)
{
	List<tasksel *>::iterator iter;
	iter = m_Tasks.begin();

	bool done;
	tasksel *pSel;
	size_t num = 0;
	ITask *pRun;
	while (iter != m_Tasks.end())
	{
		done = false;
		pSel = (*iter);
		pRun = (*iter)->task;
		if (pSel->think + pSel->interval < curTime)
		{
			pRun->Run();
			done = true;
			num++;
			pSel->think = curTime;
		}
		if (done)
		{
			pRun->deleteThis();
			pSel->task = NULL;
			g_FreeTasks->push(pSel);
			iter = m_Tasks.erase(iter);
		} else {
			iter++;
		}
	}

	return num;
}

