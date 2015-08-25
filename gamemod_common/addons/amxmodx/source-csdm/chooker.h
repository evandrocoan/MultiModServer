
/***
 *  Copyright 2012 Carlos Sola, Vincent Herbet.
 *
 *  This file is part of CHooker library.
 *
 *  CHooker library is free software: you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation, either version 3 of the License, or
 *  (at your option) any later version.
 *
 *  CHooker library is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with CHooker library. If not, see <http://www.gnu.org/licenses/>.
 */

/* HookByCall array format
 * 
CHOOKER_SIG_CALL custom_array[] =
{
    { "0x12,0x13,0x14,?,0x15,*,0x16", -2 },
    { NULL, NULL }
};
*/

#ifndef _CHOOKER_H_
#define _CHOOKER_H_

#include <stdio.h>
#include <string.h>
#include <stdlib.h>

#if defined __linux__

	#include <sys/mman.h>
	#include <dlfcn.h>
	#include <link.h>
	#include <limits.h>
	#include <unistd.h>
	#include <errno.h>

	#ifndef uint32
		#define uint32	unsigned int
	#endif

	#ifndef byte
		#define byte	unsigned char
	#endif

	#ifndef FALSE
		#define FALSE	0
	#endif

	#ifndef TRUE
		#define TRUE	1
	#endif

	#ifndef PAGESIZE
		#define PAGESIZE sysconf(_SC_PAGESIZE)
	#endif

	inline void* Align( void* address )
	{
		return ( void* )( ( long )address & ~( PAGESIZE - 1 ) );
	}

	inline uint32 IAlign( uint32 address )
	{
		return ( address & ~( PAGESIZE - 1 ) );
	}

	inline uint32 IAlign2( uint32 address )
	{
		return ( IAlign( address ) + PAGESIZE );
	}


	//#define GET_EAX_POINTER(x) __asm volatile ("movl %%edx, %0; lea 0x01020304, %%edx;" : "=m" (x):)
	#define GET_EAX_POINTER(x) __asm volatile ("movl %%edx, %0;" : "=m" (x):)

	const unsigned long PAGE_EXECUTE_READWRITE = PROT_READ | PROT_WRITE | PROT_EXEC;
	const unsigned long PAGE_READWRITE = PROT_READ | PROT_WRITE;

	static int dl_callback( struct dl_phdr_info *info, size_t size, void *data );

#else

	#pragma comment( lib, "Psapi.lib" ) 
	#pragma comment( lib, "Kernel32.lib" ) 
	
	#define PSAPI_VERSION 1
	
	#include <windows.h>
	#include <Psapi.h>
	#include <WinBase.h>
	#include <io.h>

	#define GET_EAX_POINTER(x) __asm mov x, edx;
	#define PAGESIZE 4096

#endif

#define GET_ORIG_FUNC(x) CFunc *x; GET_EAX_POINTER(x);

typedef int BOOL;

typedef enum
{
	ReturnOnError,
	ReturnOnFirst,
	ContinueOnError
} PatchActionType;

typedef enum
{ 
	SpecificByte, 
	AnyByteOrNothing, 
	AnyByte 
} SignatureEntryType;

#define CHOOKER_NONE	0 << 0
#define CHOOKER_FOUND	1 << 0
#define CHOOKER_PATCHED	2 << 0

typedef struct {
	const char *sig;
	int offset;
	BOOL mandatory;
	int result;
} CHOOKER_SIG_CALL;

class CMemory
{
	public:

		unsigned char* signature;
		unsigned char* signatureData;

		int sigsize;

		char *baseadd;
		char *endadd;
		char *library;

		CMemory() : signature( 0 ), signatureData( 0 ), sigsize( 0 ), baseadd( ( char* )0xffffffff ), endadd( 0 ), library( 0 ) {}

		BOOL ChangeMemoryProtection( void* function, unsigned int size, unsigned long newProtection )
		{
			#ifdef __linux__

				void* alignedAddress = Align( function );
				return !mprotect( alignedAddress, size, newProtection );

			#else

				FlushInstructionCache( GetCurrentProcess(), function, size );

				static DWORD oldProtection;
				return VirtualProtect( function, size, newProtection, &oldProtection );

			#endif
		}

		BOOL ChangeMemoryProtection( void* address, unsigned int size, unsigned long newProtection, unsigned long &oldProtection )
		{
			#ifdef __linux__

				void* alignedAddress = Align( address );

				oldProtection = newProtection;

				return !mprotect( alignedAddress, size, newProtection );

			#else

				FlushInstructionCache( GetCurrentProcess(), address, size );

				return VirtualProtect( address, size, newProtection, &oldProtection );

			#endif
		}

		void SetupSignature( char *src )
		{
			int len = strlen( src );

			unsigned char *sig = new unsigned char[ len + 1 ];

			signature = new unsigned char[ len ];
			signatureData = new unsigned char[ len ];

			unsigned char *s1 = signature;
			unsigned char *s2 = signatureData;

			sigsize = 0;

			memcpy( sig, src, len + 1 );

			char *tok = strtok( ( char* )sig, "," );

			while( tok )
			{
				sigsize++;

				if( strstr( tok, "0x" ) )
				{
					*s1 = strtol( tok, NULL, 0 );
					*s2 = SpecificByte;

					*s1++;
					*s2++;
				}
				else
				{
					*s1 = 0xff;
					*s1++;

					switch( *tok )
					{
					case '*':
						{
							*s2 = AnyByte;
							break;
						}
					case '?':
						{
							*s2 = AnyByteOrNothing;
							break;
						}
					}

					*s2++;
				}

				tok = strtok( NULL, "," );
			}

			delete[] sig;
		}

		BOOL CompareSig( unsigned char *address, unsigned char *signature, unsigned char *signaturedata, int length )
		{
//printf("Compare: 0x%x 0x%x 0x%x 0x%x\t%d\n", address, *signature, *address, *signaturedata, length);
			if( length == 1 )
			{
				switch( *signaturedata )
				{
					case AnyByteOrNothing:
					case AnyByte:
					{
						return TRUE;
					}
					case SpecificByte:
					{
						return ( (byte )*address == ( byte )*signature );
					}
				}
			}
			else
			{
				switch( *signaturedata )
				{
					case SpecificByte:
					{
//printf("\tSpecificByte:\t0x%x 0x%x 0x%x 0x%x 0x%x %d\n", address, signature, *signature, *address, *signaturedata, ( *address != ( byte )*signature ));
						if( (byte )*address != ( byte )*signature )
							return FALSE;
						else
							return CompareSig( address + 1, signature + 1, signaturedata + 1, length - 1 );
					}
					case AnyByteOrNothing:
					{
						if( CompareSig( address, signature + 1, signaturedata + 1, length - 1 ) ) 
							return TRUE;
					}
					case AnyByte:
					{
						return CompareSig( address + 1, signature + 1, signaturedata + 1, length - 1 );
					}
				}

			}

			return TRUE;
		}

		void *SearchSignatureByLibrary( char *sig, char *libname )
		{
			void *ret;
			baseadd = endadd = NULL;
			if(!libname)
				return SearchSignatureByAddress( sig, this );

			GetLibraryFromName( libname );
			ret = SearchSignature( sig );

			baseadd = endadd = NULL;
			return ret;
		}

		void *SearchSignatureByAddress( char *sig, void* libaddr )
		{
			void *ret;
			baseadd = endadd = NULL;
//			if(!libaddr)
//				libaddr = (void*)dl_callback;

//printf("SearchSignatureByAddress: 0x%x 0x%x %s\n", libaddr, (void*)dl_callback, sig);
			GetLibraryFromAddress( libaddr );
//printf("SearchSignatureByAddress: 0x%x 0x%x\n", baseadd, endadd);

			ret = SearchSignature( sig );

			baseadd = endadd = NULL;
			return ret;
		}

		void *SearchSignature( char *signeedle )
		{
			SetupSignature( signeedle );

			void *ret = NULL;

			unsigned char *start = ( unsigned char* )baseadd;
			unsigned char *end = ( ( unsigned char* )endadd ) - sigsize;

			unsigned int length = end - start ;

//printf("SearchSignatureByAddress: 0x%x 0x%x - 0x%x\n", start, length, ChangeMemoryProtection( start, length, PAGE_EXECUTE_READWRITE ));
			if( ChangeMemoryProtection( start, length, PAGE_EXECUTE_READWRITE ) )
			{
//printf("*SearchSignatureByAddress: 0x%x 0x%x - 0x%x\n", start, length, ChangeMemoryProtection( start, length, PAGE_EXECUTE_READWRITE ));
				for( unsigned int i = 0; i <= length - sigsize; i++ )
				{
					if( CompareSig( start + i, signature, signatureData, sigsize ) )
					{
						ret = (void *)( start + i );
						break;
					}
				}
			}

			delete[] signature;
			delete[] signatureData;

			return ret;
		}

		void *SearchSymbolByAddress( char *symbol, void *libaddr )
		{
			//printf("SearchSymbolByAddress: %s libaddr:0x%x\n", symbol, libaddr);
			#if defined __linux__

				Dl_info info;
				void *handle = ( void* )0xffffffff;
				BOOL should_close = FALSE;

				if( libaddr && dladdr( libaddr, &info ) )
				{
					handle = dlopen( info.dli_fname, RTLD_NOW );
					should_close = TRUE;
				}
				else if( !libaddr )
				{
					handle = RTLD_DEFAULT;
				}

				if( handle >= 0 )
				{
					void *s = dlsym( handle, symbol );

					if( !dlerror() )
					{
						if(should_close)
							dlclose(handle);
						return (void *)s;
					}
					if(should_close)
						dlclose(handle);
				}

			#else

				HMODULE module;

				if( GetModuleHandleEx( GET_MODULE_HANDLE_EX_FLAG_FROM_ADDRESS, ( LPCSTR )libaddr, &module ) )
				{
					void* s = GetProcAddress( module, symbol );

					if( s )
					{
						return (void *)s;
					}
				}

			#endif

			return FALSE;
		}

		void *SearchSymbolByLibrary( char *symbol, char *libname )
		{
			printf("SearchSymbolByLibrary: %s libname:%s\n", symbol, libname);
			if(!libname)
				GetLibraryFromAddress( NULL );
			else
				GetLibraryFromName( libname );
			
			return SearchSymbolByAddress( symbol, baseadd );
		}
	
		void* GetLibraryFromAddress( void* libaddr )
		{
			#ifdef __linux__
			
				Dl_info info;


//printf("GetLibraryFromAddress: 0x%x\n", libaddr);
				if( libaddr && dladdr( libaddr, &info ) )
				{
//printf("found name: 0x%x\n", libaddr);
					return GetLibraryFromName( ( char* )info.dli_fname );
				}
			
//printf("not found name: 0x%x\n", libaddr);
				return GetLibraryFromName( NULL );
	
			#else

				HMODULE module;

				if( GetModuleHandleEx( GET_MODULE_HANDLE_EX_FLAG_FROM_ADDRESS, ( LPCSTR )libaddr, &module ) )
				{
					HANDLE process =  GetCurrentProcess();
					_MODULEINFO moduleInfo;

					if( GetModuleInformation( process, module, &moduleInfo, sizeof moduleInfo ) )
					{
						CloseHandle( process );

						baseadd = ( char* )moduleInfo.lpBaseOfDll;
						endadd = ( char* )( baseadd + moduleInfo.SizeOfImage );

						return ( void* )baseadd;
					}
				}

				return NULL;

			#endif
		}

		void* GetLibraryFromName( char *libname )
		{
			#ifdef __linux__

				library = libname;
				int baseaddress;

//printf("GetLibraryFromName: %s\n", libname);

				baseadd = ( char * )0xffffffff;
				endadd = NULL;

				if( ( baseaddress = dl_iterate_phdr( dl_callback, this ) ) )
				{
//printf("return library: 0x%x 0x%x 0x%x\n", baseaddress, baseadd, endadd);
					return ( void* )baseaddress;
				}

			#else

				HMODULE hMods[ 1024 ];
				HANDLE	hProcess;
				DWORD	cbNeeded;

				unsigned int	i;
				static char		msg[100];

				hProcess = GetCurrentProcess();

				if( hProcess == NULL ) // IS NOT POSSIBLE!
					return NULL;

				if( EnumProcessModules( hProcess, hMods, sizeof( hMods ), &cbNeeded ) )
				{
					TCHAR szModName[ MAX_PATH ];
					_MODULEINFO info;

					for( i = 0; i < ( cbNeeded / sizeof( HMODULE ) ); i++ )
					{
						if( GetModuleFileNameEx(hProcess, hMods[i], szModName, sizeof( szModName ) / sizeof( TCHAR ) ) )
						{
							if( strstr( szModName, libname ) > 0 )
							{
								if( GetModuleInformation( hProcess, hMods[i], &info, sizeof( info ) ) )
								{
									baseadd = ( char* )info.lpBaseOfDll;
									endadd	= ( char* )( baseadd + info.SizeOfImage );

									return ( void* )baseadd;
								}
							}
						}
					}
				}

			#endif

			return NULL;
		}

		BOOL PatchCall( void *src, int offset, void *dst )
		{
			char* call = ( char* )src;
			call += ++offset;
			
			unsigned long address = ( unsigned long )dst - ( unsigned long )call - sizeof( unsigned long );
			unsigned long oldProtection;
			
			if( ChangeMemoryProtection( call, sizeof( unsigned long ), PAGE_EXECUTE_READWRITE, oldProtection ) )
			{
				*( unsigned long* )call = address;
				
				if( oldProtection == PAGE_EXECUTE_READWRITE || ChangeMemoryProtection( call, sizeof( unsigned long ), oldProtection ) )
				{
					return TRUE;
				}
			}
			
			return FALSE;
		}

};

class CFunc
{
	private:

		void* address;
		void* detour;

		CMemory* memFunc;

		unsigned char i_original[12];
		unsigned char i_patched[12];
		unsigned char *original;
		unsigned char *patched;

		BOOL ispatched;
		BOOL ishooked;

	public:

		CFunc( void* src, void* dst )
		{
			address		= src;
			detour		= dst;
			ishooked	= ispatched = 0;
			original	= &i_original[0];
			patched		= &i_patched[0];

			memFunc = new CMemory;
		};

		~CFunc() 
		{ 
			delete memFunc;
		};

		void *Hook( void *dst, BOOL hook )
		{
			if( !ishooked && !ispatched )
			{
				unsigned int *p;
				detour = dst;

				memcpy( original, address, 12 );

				// lea    this ,%edx
				// movl    this ,%edx
				patched[0] = 0x8d;
				patched[1] = 0x15;

				p = ( unsigned int* )( patched + 2 );
				*p = ( unsigned int )this;

				// nop
				patched[6] = 0x90;

				// jmp detour
				patched[7] = 0xE9;
				p = ( unsigned int* )( patched + 8 );
				*p = ( unsigned int )dst - ( unsigned int )address - 12;

				if( hook && Patch() )
				{
					return address;
				}

				ishooked = FALSE;
			}

			return NULL;
		}

		void *GetOriginal()
		{
			return address;
		}

		BOOL Patch()
		{
			if( !ispatched )
			{
				if( memFunc->ChangeMemoryProtection( address, PAGESIZE, PAGE_EXECUTE_READWRITE ) )
				{
					memcpy( address, patched, 12 );
					ispatched = TRUE;
				}
			}

			return ispatched;
		}

		BOOL Restore()
		{
			if( ispatched )
			{
				if( memFunc->ChangeMemoryProtection( address, PAGESIZE, PAGE_EXECUTE_READWRITE ) )
				{
					memcpy( address, original, 12 );
					ispatched = FALSE;
				}
			}

			return !ispatched;
		}
};

class CHooker
{
	private:

		struct Obj
		{
			void*	src;
			CFunc*	func;
			Obj*	next;
		} *head;

	public:

		CMemory* memFunc;

		CHooker() : head( 0 ) 
		{
			memFunc = new CMemory;
		};

		~CHooker() 
		{ 
			Clear(); 
		};

		void Clear()
		{
			while( head )
			{
				Obj *obj = head->next;

				delete head->func;
				delete head;

				head = obj;
			}

			delete memFunc;
		}

		template <typename Tdst>
		BOOL MemoryCallPatchByAddress(CHOOKER_SIG_CALL *sigs, void *libaddr, Tdst dst, PatchActionType action)
		{
			void *address;
			int c = 0;
			BOOL ret = TRUE;
	
			while(sigs[c].sig)
			{
				address = memFunc->SearchSignatureByAddress((char*)sigs[c].sig, libaddr);
				printf("SIG: %d\t%s\t0x%08x\n", sigs[c].offset, sigs[c].sig, address);
				if(address)
				{
					sigs[c].result |= CHOOKER_FOUND;
					if(memFunc->PatchCall(address, sigs[c].offset, (void*)dst))
					{
						sigs[c].result |= CHOOKER_PATCHED;
					}
					else
					{
						ret = FALSE;
					}
					if( ( action == ReturnOnFirst ) && ( sigs[c].result & CHOOKER_PATCHED ) )
						return TRUE;
				}
				else
				{
					ret = FALSE;
					if(sigs[c].mandatory || action == ReturnOnError)
						return FALSE;
				}
				c++;
			}
			return ret;
		}

		template <typename Tdst>
		BOOL MemoryCallPatchByLibrary(CHOOKER_SIG_CALL *sigs, char *libname, Tdst dst, PatchActionType action)
		{
			void *address;
			int c = 0;
			BOOL ret = TRUE;
	
			while(sigs[c].sig)
			{
				address = memFunc->SearchSignatureByLibrary((char*)sigs[c].sig, libname);
				printf("SIG: %d\t%s\t0x%08x\n", sigs[c].offset, sigs[c].sig, address);
				if(address)
				{
					sigs[c].result |= CHOOKER_FOUND;
					if(memFunc->PatchCall(address, sigs[c].offset, (void*)dst))
					{
						sigs[c].result |= CHOOKER_PATCHED;
					}
					else
					{
						ret = FALSE;
					}
					if( ( action == ReturnOnFirst ) && ( sigs[c].result & CHOOKER_PATCHED ) )
						return TRUE;
				}
				else
				{
					ret = FALSE;
					if(sigs[c].mandatory || action== ReturnOnError)
						return FALSE;
				}
				c++;
			}
			return ret;
		}

		template <typename Tdst>
		BOOL MemoryCallPatch(CHOOKER_SIG_CALL *sigs, void *libaddr, Tdst dst, PatchActionType action)
		{
			return MemoryCallPatchByAddress(sigs, libaddr, dst, action);
		}

		template <typename Tdst>
		BOOL MemoryCallPatch(CHOOKER_SIG_CALL *sigs, char *libname, Tdst dst, PatchActionType action)
		{
			return MemoryCallPatchByLibrary(sigs, libname, dst, action);
		}

		template <typename Tret, typename Tdata>
		Tret MemorySearch(Tdata const data, void *libaddr, BOOL issym)
		{
			//printf("MemorySearch: 0x%x %s\n", libaddr, data);
			if(issym)
				return (Tret)memFunc->SearchSymbolByAddress((char *)data, libaddr);
			else
				return (Tret)memFunc->SearchSignatureByAddress((char *)data, libaddr);
		}

		template <typename Tret, typename Tdata, typename Tlib>
		Tret MemorySearch(Tdata const data, Tlib const libname, BOOL issym)
		{
			//printf("MemorySearch: %s %s\n", libname, data);
			if(issym)
				return (Tret)memFunc->SearchSymbolByLibrary((char *)data, (char *)libname);
			else
				return (Tret)memFunc->SearchSignatureByLibrary((char *)data, (char *)libname);
		}

		void* MemoryByLibrary( char *libname )
		{
			return memFunc->GetLibraryFromName( libname );
		}

		void* MemoryByAddress( void *libaddr )
		{
			return memFunc->GetLibraryFromAddress( libaddr );
		}

		template <typename Tsrc, typename Tdst>
		CFunc* CreateHook(Tsrc src, Tdst dst, BOOL hook)
		{
			if( !src || !dst )
				return NULL;

			Obj *obj = head;

			if( !obj )
			{
				head = new Obj();
				obj = head;

				obj->src = ( void* )src;
				obj->func = new CFunc( ( void* )src, ( void* )dst);
				obj->next = NULL;
			}
			else
			{
				while( obj )
				{
					if( obj->src == ( void* )src )
					{
						break;
					}
					else if( !obj->next )
					{
						obj->next = new Obj();
						obj = obj->next;

						obj->src = ( void* )src;
						obj->func = new CFunc( ( void* )src, ( void* )dst );
						obj->next = NULL;

						break;
					}
					obj = obj->next;
				}
			}

			if( obj->func )
				obj->func->Hook( ( void* )dst, hook );

			return obj->func;
		}
};

#ifdef __linux__

	static int dl_callback( struct dl_phdr_info *info, size_t size, void *data )
	{
		CMemory* obj = ( CMemory* )data;

		if( ( !obj->library ) || strstr( info->dlpi_name, obj->library ) > 0 )
		{
			int i;
			BOOL ismain = FALSE;

			if( info->dlpi_addr == 0x00 )
				ismain = TRUE;
			else
				obj->baseadd = ( char * )info->dlpi_addr;

			for( i = 0; i < info->dlpi_phnum; i++)
			{
				if( info->dlpi_phdr[i].p_memsz && IAlign( info->dlpi_phdr[i].p_vaddr ) )
				{
					if( ismain && ( uint32 )obj->baseadd > IAlign( info->dlpi_phdr[i].p_vaddr ) )
						obj->baseadd = ( char* )IAlign( info->dlpi_phdr[i].p_vaddr );
				
					if( ( uint32 )obj->endadd < ( info->dlpi_phdr[i].p_vaddr + info->dlpi_phdr[i].p_memsz ) )
						obj->endadd = ( char* )IAlign2( ( info->dlpi_phdr[i].p_vaddr + info->dlpi_phdr[i].p_memsz ) );
				}
			}

			obj->endadd += info->dlpi_addr;

			return ( int )obj->baseadd;
		}

		return 0;
	}

#endif

#endif // _CHOOKER_H_
  
