/**
 * (C)2003-2006 David "BAILOPAN" Anderson
 * Counter-Strike: Deathmatch
 *
 * Licensed under the GNU General Public License, version 2
 */

#ifndef _INCLUDE_CSIGMNGR_H
#define _INCLUDE_CSIGMNGR_H

struct signature_t
{
	void *allocBase;
	void *memInBase;
	size_t memSize;
	void *offset;
	const char *sig;
	size_t siglen;
};

class CSigMngr
{
public:
	void *ResolveSig(void *memInBase, const char *pattern, size_t siglen);
	int ResolvePattern(void *memInBase, const char *pattern, size_t siglen, int number, ...);
private:
	bool ResolveAddress(signature_t *sigmem);
};

extern CSigMngr g_SigMngr;

#endif //_INCLUDE_CSIGMNGR_H
