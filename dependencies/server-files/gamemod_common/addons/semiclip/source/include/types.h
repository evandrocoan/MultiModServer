#ifndef _TYPES_H_
#define _TYPES_H_

#ifndef dword
	typedef unsigned long dword;
#endif

#ifndef byte
	typedef unsigned char byte;
#endif

#ifdef _WIN32
	#ifndef intp_t
		typedef __int32 intp_t;
	#endif

	#ifndef uintp_t
		typedef unsigned __int32 uintp_t;
	#endif

	#ifndef int8_t
		typedef __int8 int8_t;
	#endif

	#ifndef uint8_t
		typedef unsigned __int8 uint8_t;
	#endif

	#ifndef int16_t
		typedef __int16 int16_t;
	#endif

	#ifndef uint16_t
		typedef unsigned __int16 uint16_t;
	#endif

	#ifndef int32_t
		typedef __int32 int32_t;
	#endif

	#ifndef uint32_t
		typedef unsigned __int32 uint32_t;
	#endif

	#ifndef int64_t
		typedef __int64 int64_t;
	#endif

	#ifndef uint64_t
		typedef unsigned __int64 uint64_t;
	#endif
#else
	#ifndef intp_t
		typedef int intp_t;
	#endif

	#ifndef uintp_t
		typedef unsigned int uintp_t;
	#endif

	/*#ifndef int8_t
		typedef char int8_t;
	#endif*/

	#ifndef uint8_t
		typedef unsigned char uint8_t;
	#endif

	#ifndef int16_t
		typedef short int16_t;
	#endif

	#ifndef uint16_t
		typedef unsigned short uint16_t;
	#endif

	#ifndef int32_t
		typedef int int32_t;
	#endif

	#ifndef uint32_t
		typedef unsigned int uint32_t;
	#endif

	#ifndef int64_t
		typedef long long int64_t;
	#endif

	#ifndef uint64_t
		typedef unsigned long long uint64_t;
	#endif
#endif

#endif //_TYPES_H_
