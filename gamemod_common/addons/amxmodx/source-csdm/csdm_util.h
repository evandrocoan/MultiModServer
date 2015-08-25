#ifndef _INCLUDE_CSDM_UTIL_H
#define _INCLUDE_CSDM_UTIL_H

#include "CVector.h"
#include "CString.h"
#include "chooker.h"

class FakeCommand
{
public:
	FakeCommand() : num_args(0)
	{
	};
	~FakeCommand();
public:
	void AddArg(const char *str);
	int GetArgc() const;
	const char *GetArg(int i) const;
	void Reset();
	void Clear();
	void SetFullString(const char *fmt, ...);
	const char *GetFullString() const;
private:
	CVector<String *> args;
	String full;
	size_t num_args;
};

//returns true if plugins said ok to remove the weapons 
bool NotifyForRemove(unsigned int owner, edict_t *ent, edict_t *box);

void RespawnPlayer(edict_t *pEdict);
void FakespawnPlayer(edict_t *pEdict);
edict_t *GetEdict(int index);
void print_srvconsole( const char *fmt, ...);
void print_client(edict_t *pEdict, int type, const char *fmt, ...);
bool InitUtilCode();
void InternalSpawnPlayer(edict_t *pEdict);
void FFA_Enable();
void FFA_Disable();

#ifdef __linux__
	typedef void ( *FuncRestartRound )( void* );

	extern CFunc*			RestartRoundHook;
	extern FuncRestartRound	RestartRoundOrig;
#endif

extern FakeCommand g_FakeCmd;

#endif //_INCLUDE_CSDM_UTIL_H
