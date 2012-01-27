
#ifdef NEKO_WINDOWS
#include <windows.h>
#endif

#include <hx/CFFI.h>

// This macro is for dealing with Bytes passed from haxe to the ndll
// An int holding the buffer length is created and so is a pointer to
// the char data
#define BYTES_TO_NEKO(b) \
	int b##_len =0; \
	char* b##_ptr; \
	if(val_is_string(b)) { \
		b##_ptr = (char *)val_string(b); \
		b##_len = val_strlen(b); \
	} else if(val_is_buffer(b)) { \
		b##_ptr = buffer_data(val_to_buffer(b)); \
		b##_len = buffer_size(val_to_buffer(b)); \
	} else { \
		return alloc_null(); \
	}

