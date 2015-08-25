#ifndef _INCLUDE_CSDM_MESSAGE_H
#define _INCLUDE_CSDM_MESSAGE_H

#include "CString.h"
#include "CVector.h"

enum MsgType
{
	Msg_Int = 0,
	Msg_Float,
	Msg_String
};

struct msgprm_s
{
	union
	{
		int iData;
		float fData;
	} v;
	String szData;
	MsgType type;
};

class Message
{
public:
	Message();
	~Message();
public:
	size_t Parameters();
	int GetParamInt(unsigned int index);
	float GetParamFloat(unsigned int index);
	const char *GetParamString(unsigned int index);
	MsgType GetParamType(unsigned int index);
	void AddParam(int idata);
	void AddParam(float fdata);
	void AddParam(const char *szdata);
	void Reset();
private:
	CVector<msgprm_s *> m_Params;
	size_t m_CurParams;
};

#endif //_INCLUDE_CSDM_MESSAGE_H
