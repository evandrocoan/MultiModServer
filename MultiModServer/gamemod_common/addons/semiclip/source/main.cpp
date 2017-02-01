#include "main.h"
#include "mem_parse.h"

static edict_t *maxEdict;
static edict_t *nullEdict;
static edict_t *startEdict;

bool g_bNotActive = false;
char **global_host_client;

patch_t patchData[] =
{
	{ (void *)NULL, {}, 0 },
	{ (void *)NULL, {}, 0 },
	{ (void *)NULL, {}, 0 }
};

semiclipData_t semiclipData;
semiclip_t g_pSemiclip[MAX_CLIENTS + 1];

void OnMetaDetach()
{
	for(int j = 0; j < 3; j++)
	{
		if(patchData[j].addr)
			mem_memcpy(patchData[j].addr,patchData[j].bytes,patchData[j].nSize);
	}
}
int OnMetaAttach()
{
	load_config();

	if(load_parse())
	{
		REG_SVR_COMMAND("semiclip_option",SVR_SemiclipOption);
		return 1;
	}
	return 0;
}
static uint16_t FixedUnsigned16(float fValue,float fScale)
{
	int output = (int)(fValue * fScale);

	if(output < 0)
		output = 0;

	if(output > 0xFFFF)
		output = 0xFFFF;

	return (uint16_t)output;
}
void UTIL_ScreenFade(edict_t *pEdict,float flFadeTime,float flFadeHold,int iAlpha)
{
	static int gmsigScreenFade = 0;
	if(gmsigScreenFade || (gmsigScreenFade = REG_USER_MSG("ScreenFade",-1)))
	{
		gpEnginefuncInterface->pfnMessageBegin(MSG_ONE,gmsigScreenFade,NULL,pEdict);
		gpEnginefuncInterface->pfnWriteShort(FixedUnsigned16(flFadeTime,1<<12));
		gpEnginefuncInterface->pfnWriteShort(FixedUnsigned16(flFadeHold,1<<12));
		gpEnginefuncInterface->pfnWriteShort(0);
		gpEnginefuncInterface->pfnWriteByte(255);
		gpEnginefuncInterface->pfnWriteByte(255);
		gpEnginefuncInterface->pfnWriteByte(255);
		gpEnginefuncInterface->pfnWriteByte(iAlpha);
		gpEnginefuncInterface->pfnMessageEnd();
	}
}
void RadiusFlash_Handler(Vector vecStart,entvars_t *pevInflictor,entvars_t *pevAttacker,float flDamage)
{
	void *pData;

	int iAlpha;
	int m_iFlashAlpha;

	float flFadeTime;
	float flFadeHold;
	float flRadius = 1500;
	float flAdjustedDamage;
	float flCurrentHoldTime;
	float flFallDmg = flDamage / flRadius;
	float flCurrentTime = gpGlobals->time;

	float m_flFlashedAt;
	float m_flFlashHoldTime;
	float m_flFlashDuration;

	Vector vecEnd;
	Vector vecPlane;
	Vector vecTemp;

	TraceResult tr;

	edict_t *pHit;
	edict_t *pEdict;
	edict_t *pObserver;
	edict_t *pAttacker = (pevAttacker != NULL) ? pevAttacker->pContainingEntity : NULL;
	edict_t *pFlashbang = pevInflictor->pContainingEntity;

	static int iMaxClients = gpGlobals->maxClients;

	bool bInWater = (POINT_CONTENTS(vecStart) == CONTENTS_WATER);
	bool bIsValid = (semiclipData.noteamflash && pAttacker);

	vecStart.z += 1.0f;
	vecTemp = vecStart;

	for(int j = 1; j <= iMaxClients; j++)
	{
		pEdict = EDICT_NUM(j);

		if(!pEdict->pvPrivateData
			|| pEdict->v.deadflag != DEAD_NO
			/*|| pEdict->v.flags & FL_FAKECLIENT*/
			|| (bInWater ? pEdict->v.waterlevel == 0 : pEdict->v.waterlevel == 3)
			|| (bIsValid && pEdict != pAttacker && NUM_FOR_TEAM_ID(pEdict) == NUM_FOR_TEAM_ID(pAttacker))
		)
		{
			continue;
		}

		vecStart = vecTemp;

		pData = pEdict->pvPrivateData;
		vecEnd = pEdict->v.origin + pEdict->v.view_ofs;
		vecPlane = vecStart - vecEnd;

		if(vecPlane.Length() > flRadius)
		{
			continue;
		}

		TRACE_LINE(vecStart,vecEnd,0,pFlashbang,&tr);

		if(semiclipData.semiclip)
		{
			for(int k = 0; k < iMaxClients; k++)
			{
				int iHit = NUM_FOR_EDICT(tr.pHit);

				if(!iHit || iHit > iMaxClients || j == iHit || !g_pSemiclip[j].solid[iHit])
				{
					break;
				}

				pHit = tr.pHit;

				vecStart = pHit->v.origin + pHit->v.view_ofs;

				TRACE_LINE(vecStart,vecEnd,0,pHit,&tr);
			}
		}
		if(tr.flFraction == 1.0f || tr.pHit == pEdict)
		{
			flAdjustedDamage = flDamage - (vecPlane.Length() * flFallDmg);

			if(flAdjustedDamage < 0.0f)
			{
				flAdjustedDamage = 0.0f;
			}

			MAKE_VECTORS(pEdict->v.v_angle);

			if(DotProduct(vecPlane,gpGlobals->v_forward) < 0.3f)
			{
				flFadeTime = flAdjustedDamage * 1.75f;
				flFadeHold = flAdjustedDamage / 3.5f;
				iAlpha = 200;
			}
			else
			{
				flFadeTime = flAdjustedDamage * 3.0f;
				flFadeHold = flAdjustedDamage / 1.5f;
				iAlpha = 255;
			}

			m_flFlashedAt = *((float *)pData + OFFSET_FLASH_AT);
			m_flFlashHoldTime = *((float *)pData + OFFSET_FLASH_HOLD_TIME);
			m_flFlashDuration = *((float *)pData + OFFSET_FLASH_DURATION);
			m_iFlashAlpha = *((int *)pData + OFFSET_FLASH_ALPHA);

			flCurrentHoldTime = m_flFlashedAt + m_flFlashHoldTime - flCurrentTime;

			if(flCurrentHoldTime > 0.0f && iAlpha == 255.0f)
			{
				flFadeHold += flCurrentHoldTime;
			}
			if(m_flFlashedAt != 0.0f && m_flFlashDuration != 0.0f && (m_flFlashedAt + m_flFlashDuration + m_flFlashHoldTime) > flCurrentTime)
			{
				if(m_flFlashDuration > flFadeTime)
				{
					flFadeTime = m_flFlashDuration;
				}
				if(m_iFlashAlpha > iAlpha)
				{
					iAlpha = m_iFlashAlpha;
				}
			}

			UTIL_ScreenFade(pEdict,flFadeTime,flFadeHold,iAlpha);
			for(int i = 1; i <= iMaxClients; i++)
			{
				pObserver = EDICT_NUM(i);

				if(!i == j
					|| !pObserver->pvPrivateData
					|| (pObserver->v.flags == FL_DORMANT)
					|| !(pObserver->v.iuser1 == 4 && pObserver->v.iuser2 == j))
				{
					continue;
				}

				UTIL_ScreenFade(pObserver,flFadeTime,flFadeHold,iAlpha);
			}

			*((float *)pData + OFFSET_FLASH_UNTIL) = flFadeTime / 3 + flCurrentTime;
			*((float *)pData + OFFSET_FLASH_AT) = flCurrentTime;

			*((float *)pData + OFFSET_FLASH_HOLD_TIME) = flFadeHold;
			*((float *)pData + OFFSET_FLASH_DURATION) = flFadeTime;
			*((int *)pData + OFFSET_FLASH_ALPHA) = iAlpha;
		}
	}
}
void SVR_SemiclipOption()
{
	if(CMD_ARGC() < 3)
	{
		print_settings();
		return;
	}

	const char *argv = CMD_ARGV(1);
	const char *value = CMD_ARGV(2);

	if(*value == '\0')
	{
		return;
	}

	static const char *szRestrict[] =
	{
		"patch", "flashfix"
	};

	for(int i = 0; i < 2; i++)
	{
		if(!strcasecmp(argv,szRestrict[i]))
		{
			printf("[%s] Error: Setting \"%s\" you can't change\n",Plugin_info.logtag,argv);
			return;
		}
	}
	if(!parse_settings(argv,value,READ_IN_GAME))
	{
		print_settings();
	}
	else if(!semiclipData.semiclip)
	{
		g_bNotActive = true;

		g_pFunctionTable->pfnPM_Move = NULL;
		g_pEnginefuncsTable_Post->pfnAlertMessage = NULL;
	}
	else
	{
		if(!semiclipData.time)
		{
			memset(g_pSemiclip,0,sizeof(g_pSemiclip));

			g_bNotActive = false;
			g_pFunctionTable->pfnPM_Move = PM_Move;
			g_pEnginefuncsTable_Post->pfnAlertMessage = NULL;
		}
		else g_pEnginefuncsTable_Post->pfnAlertMessage = AlertMessage;
	}
}
void *Q_memcpy_Handler(void *_Dst,entity_state_t *_Src,uint32_t _Size)
{
	if(g_bNotActive)
	{
		return memcpy(_Dst,_Src,_Size);
	}

	int j;
	int nSize;
	int host,ent;

	semiclip_t *a;
	edict_t *pHost,*pEntity;
	entity_state_t *state;

	nSize = _Size / sizeof(entity_state_t);
	pHost = *(edict_t **)((*global_host_client) + OFFSET_EDICT_CL);

	if(pHost->v.deadflag != DEAD_NO)
	{
		return memcpy(_Dst,_Src,_Size);
	}

	host = NUM_FOR_EDICT(pHost);
	a = &(g_pSemiclip[host]);

	for(j = 0; j < nSize; j++)
	{
		state = _Src + j;
		ent = state->number;

		if(ent > gpGlobals->maxClients)
		{
			break;
		}

		pEntity = EDICT_NUM(ent);

		if(pEntity == pHost || pEntity->v.deadflag != DEAD_NO)
		{
			continue;
		}

		if(a->solid[ent])
		{
			state->solid = SOLID_NOT;

			if(semiclipData.transparency)
			{
				state->rendermode = kRenderTransAlpha;
				state->renderamt = semiclipData.effects ? (a->diff[ent] > MIN_AMOUNT) ? a->diff[ent] : MIN_AMOUNT : semiclipData.transparency;
			}
		}
	}
	return memcpy(_Dst,_Src,_Size);
}
static bool allowDontSolid(playermove_t *pmove,edict_t *pHost,int host,int j)
{
	int ent;
	int entTeamId;
	int hostTeamId;

	float fDiff;

	semiclip_t *a,*e;
	edict_t *pEntity;
	entvars_t *pevHost,*pevEnt;

	Vector entOrigin;
	Vector hostOrigin;

	ent = pmove->physents[j].player;
	
	a = &(g_pSemiclip[host]);
	e = &(g_pSemiclip[ent]);

	if(a->dont)
	{
		return a->solid[ent] = false;
	}

	pHost = EDICT_NUM(host);
	pEntity = EDICT_NUM(ent);

	pevHost = &(pHost->v);
	pevEnt = &(pEntity->v);

	hostOrigin = pevHost->origin;
	entOrigin = pevEnt->origin;

	hostTeamId = NUM_FOR_TEAM_ID(pHost);
	entTeamId = NUM_FOR_TEAM_ID(pEntity);

	a->diff[ent] = GET_DISTANCE(hostOrigin,entOrigin);
	a->solid[ent] = (hostTeamId == 3 || hostTeamId == 3 || ((semiclipData.effects || a->diff[ent] < semiclipData.distance) && (semiclipData.team == 0 ? 1 : semiclipData.team == 3 ? hostTeamId == entTeamId : (hostTeamId == semiclipData.team && entTeamId == semiclipData.team)) && !e->dont));

	if(semiclipData.crouch && a->solid[ent])
	{
		//fDiff = abs(a->diff[ent]);//abs(hostOrigin.z - entOrigin.z);
		fDiff = abs(hostOrigin.z - entOrigin.z);

		if(fDiff < FLOAT_CROUCH && a->crouch[ent] && e->crouch[host])
		{
			a->crouch[ent] = false;
			e->crouch[host] = false;
		}

		if(!a->crouch[ent] && (pevEnt->button & IN_DUCK || pevEnt->flags & FL_DUCKING) && pevHost->button & IN_DUCK && fDiff >= FLOAT_CROUCH)
		{
			a->crouch[ent] = true;
			e->crouch[host] = true;

			return a->solid[ent] = false;
		}
		else if((pevHost->groundentity == pEntity || pevEnt->groundentity == pHost || fDiff >= FLOAT_CROUCH) && (a->crouch[ent] || e->crouch[host]))
		{
			return a->solid[ent] = false;
		}
	}
	return a->solid[ent];
}
void PM_Move(playermove_t *pmove,int server)
{
	if(pmove->spectator || pmove->dead || pmove->deadflag != DEAD_NO)
	{
		RETURN_META(MRES_IGNORED);
	}

	int j;
	int host;
	int numphyspl = 0;
	int numphysent = -1;

	host = pmove->player_index + 1;
	edict_t *pHost = EDICT_NUM(host);

	for(j = 0; j < pmove->numphysent; ++j)
	{
		if(pmove->physents[++numphysent].player && ++numphyspl)
		{
			break;
		}
	}

	if(!numphyspl)
	{
		memset(&g_pSemiclip[host],0,sizeof(semiclip_t));
	}

	for(j = numphysent; j < pmove->numphysent; ++j)
		if(!pmove->physents[j].player || !allowDontSolid(pmove,pHost,host,j))
			pmove->physents[numphysent++] = pmove->physents[j];

	// if the time from the beginning of the round was passed
	if(semiclipData.time && gpGlobals->time > semiclipData.count)
	{
		bool bCollide = false;
		bool needSolid = false;
		int hostTeamId;

		entvars_t *e;
		edict_t *pEntity;
		Vector hostOrigin;

		hostOrigin = pHost->v.origin;
		hostTeamId = NUM_FOR_TEAM_ID(pHost);

		for(pEntity = startEdict, j = 1; pEntity <= maxEdict; pEntity++, j++)
		{
			e = &(pEntity->v);

			if(g_pSemiclip[j].dont || !pEntity->pvPrivateData || e->deadflag != DEAD_NO || e->health <= 0.0)
			{
				continue;
			}

			if(!bCollide && j != host
				&& ((semiclipData.team == 0) ? 1 : (semiclipData.team == 3) ? (hostTeamId == NUM_FOR_TEAM_ID(pEntity)) : (hostTeamId == semiclipData.team && NUM_FOR_TEAM_ID(pEntity) == semiclipData.team))
				&& GET_COLLIDE(hostOrigin,e->origin))
					bCollide = true;

			needSolid = true;

			if(bCollide && needSolid)
				break;
		}

		// the last player should always have g_pSemiclip[host].dont = true
		if(!numphyspl || !bCollide)
			g_pSemiclip[host].dont = true;

		// if no players uses semiclip, so put callback NULL
		if(!needSolid)
		{
			g_bNotActive = true;
			g_pFunctionTable->pfnPM_Move = NULL;
		}
	}
	pmove->numphysent = numphysent;
	RETURN_META(MRES_IGNORED);
}
void ServerActivate_Post(edict_t *pEdictList,int edictCount,int clientMax)
{
	load_config_maps();

	nullEdict = pEdictList;
	startEdict = pEdictList + 1;
	maxEdict = pEdictList + clientMax;

	memset(g_pSemiclip,0,sizeof(g_pSemiclip));

	RETURN_META(MRES_IGNORED);
}
void ClientPutInServer_Post(edict_t *pEdict)
{
	if(!pEdict->pvPrivateData)
	{
		RETURN_META(MRES_IGNORED);
	}

	int host = NUM_FOR_EDICT(pEdict);

	memset(&g_pSemiclip[host],0,sizeof(semiclip_t));

	RETURN_META(MRES_IGNORED);
}
void AlertMessage(ALERT_TYPE atype,char *fmt,...)
{
	if(atype != at_logged)
	{
		RETURN_META(MRES_IGNORED);
	}

	char buf[0x100U];

	va_list	ap;
	va_start(ap,fmt);
	vsnprintf(buf,sizeof(buf) - 1,fmt,ap);
	va_end(ap);

	if(!strcmp(buf,"World triggered \"Round_Start\"\n"))
	{
		g_bNotActive = false;
		g_pFunctionTable->pfnPM_Move = PM_Move;
		semiclipData.count = gpGlobals->time + semiclipData.time;

		memset(g_pSemiclip,0,sizeof(g_pSemiclip));
	}
	RETURN_META(MRES_IGNORED);
}
