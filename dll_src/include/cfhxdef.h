#ifdef __cplusplus
extern "C" {
#endif

#ifndef _CFHX_DEFINES
#define _CFHX_DEFINES

#define E_NO_MEM() val_throw(alloc_string("out of memory"))
#define THROW(x) val_throw(alloc_string(x))


#ifdef NEKO_WINDOWS
#	include <windows.h>
#	define MUTEX_CREATE(x) CRITICAL_SECTION x
#	define MUTEX_INIT(x) InitializeCriticalSection(&x)
#	define MUTEX_LOCK(x) EnterCriticalSection(&x)
#	define MUTEX_UNLOCK(x) LeaveCriticalSection(&x)
#	define MUTEX_DESTROY(x) DeleteCriticalSection(&x)
#else
#	ifdef HAVE_PTHREAD
#		include <pthread.h>
#		define MUTEX_CREATE(x) pthread_mutex_t x
//#		define MUTEX_CREATE_STATIC(x) pthread_mutex_t x = PTHREAD_MUTEX_INITIALIZER
#		define MUTEX_INIT(x) pthread_mutex_init(&x, 0)
#		define MUTEX_LOCK(x) pthread_mutex_lock(&x)
#		define MUTEX_UNLOCK(x) pthread_mutex_unlock(&x)
#		define MUTEX_DESTROY(x) pthread_mutex_destroy(&x)
#	else
#		define MUTEX_CREATE(x)
#		define MUTEX_CREATE_STATIC(x)
#		define MUTEX_INIT(x)
#		define MUTEX_LOCK(x)
#		define MUTEX_UNLOCK(x)
#		define MUTEX_DESTROY(x)
#	endif
#endif

#endif // _CFHX_DEFINES

#ifdef __cplusplus
}
#endif

