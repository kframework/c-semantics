#ifndef _KCC_KCC_SETTINGS_H
#define _KCC_KCC_SETTINGS_H

#define __FUNCTION__ __func__

#define __volatile volatile
#define __volatile__ volatile

#define _inline inline
#define __inline inline
#define __inline__ inline

#define __const const

#define __signed__ signed

typedef long int __kcc_va_list;
typedef long unsigned int __kcc_size_t;
#undef __SIZE_TYPE__
#define __SIZE_TYPE__ __kcc_size_t

#ifndef __cplusplus

/* We don't use the C parser for C++, so we need clang to recognize these
 * primitives. */

#define __alignof _Alignof
#define __alignof__ _Alignof

#define __thread _Thread_local

#define __builtin_offsetof(t, m) __kcc_offsetof(t, m)

#define typeof __kcc_typeof
#define __typeof__ __kcc_typeof
#define __auto_type __kcc_auto_type
#define __int128 __kcc_oversized_int
typedef __int128 __int128_t;
typedef unsigned __int128 __uint128_t;

/* OpenSSL checks for these macros rather than checking __GNUC__ like it's
 * supposed to, so we have to undefine these so that it knows the extensions
 * are missing. */
#undef __ATOMIC_RELAXED
#undef __ATOMIC_CONSUME
#undef __ATOMIC_ACQUIRE
#undef __ATOMIC_RELEASE
#undef __ATOMIC_ACQ_REL
#undef __ATOMIC_SEQ_CST

#define __STDC_NO_ATOMICS__

#endif

#define _DEFAULT_SOURCE

/* This should not affect semantics on 64 bit machine and violates a constraint
 * if you do not have gcc. */
#undef _FILE_OFFSET_BITS

#endif
