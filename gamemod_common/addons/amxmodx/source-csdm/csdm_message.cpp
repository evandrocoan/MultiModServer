#include "csdm_message.h"

Message::Message()
{
	m_CurParams = 0;
}

Message::~Message()
{
	unsigned int c = m_Params.size();
	unsigned int i;

	for (i=0; i<c; i++)
	{
		delete m_Params[i];
		m_Params[i] = NULL;
	}

	m_Params.clear();
}

void Message::AddParam(const char *szData)
{
	msgprm_s *pMsg;

	if (m_CurParams == m_Params.size())
	{
		pMsg = new msgprm_s;
		m_Params.push_back(pMsg);
	} else {
		pMsg = m_Params[m_CurParams];
	}

	pMsg->szData.assign(szData);
	pMsg->type = Msg_String;

	m_CurParams++;
}

void Message::AddParam(float fdata)
{
	msgprm_s *pMsg;

	if (m_CurParams == m_Params.size())
	{
		pMsg = new msgprm_s;
		m_Params.push_back(pMsg);
	} else {
		pMsg = m_Params[m_CurParams];
	}

	pMsg->v.fData = fdata;
	pMsg->type = Msg_Float;

	m_CurParams++;
}

void Message::AddParam(int idata)
{
	msgprm_s *pMsg;

	if (m_CurParams == m_Params.size())
	{
		pMsg = new msgprm_s;
		m_Params.push_back(pMsg);
	} else {
		pMsg = m_Params[m_CurParams];
	}

	pMsg->v.iData = idata;
	pMsg->type = Msg_Int;

	m_CurParams++;
}

int Message::GetParamInt(unsigned int index)
{
	if (index < 0 || index >= m_CurParams)
		return 0;
	
	msgprm_s *pMsg = m_Params[index];

	if (pMsg->type != Msg_Int)
		return 0;

	return pMsg->v.iData;
}

float Message::GetParamFloat(unsigned int index)
{
	if (index < 0 || index >= m_CurParams)
		return 0;
	
	msgprm_s *pMsg = m_Params[index];

	if (pMsg->type != Msg_Float)
		return 0;

	return pMsg->v.fData;
}

const char *Message::GetParamString(unsigned int index)
{
	if (index < 0 || index >= m_CurParams)
		return 0;
	
	msgprm_s *pMsg = m_Params[index];

	if (pMsg->type != Msg_String)
		return 0;

	return pMsg->szData.c_str();
}

MsgType Message::GetParamType(unsigned int index)
{
	if (index < 0 || index >= m_CurParams)
		return static_cast<MsgType>(0);
	
	msgprm_s *pMsg = m_Params[index];

	return pMsg->type;
}

size_t Message::Parameters()
{
	return m_CurParams;
}

void Message::Reset()
{
	m_CurParams = 0;
}
