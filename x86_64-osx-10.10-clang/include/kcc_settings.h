#ifndef _KCC_KCC_SETTINGS_H
#define _KCC_KCC_SETTINGS_H

// Some things not in the C11 standard (mostly GCCisms, I think).
#define __FUNCTION__ __func__

#define __restrict restrict
#define __restrict__ restrict

#define __volatile volatile
#define __volatile__ volatile

#define _inline inline
#define __inline inline
#define __inline__ inline

#define alignof _Alignof
#define __alignof _Alignof
#define __alignof__ _Alignof

#define __const const

#define __signed__ signed

#define __thread _Thread_local

#define __attribute__(x)

#endif
