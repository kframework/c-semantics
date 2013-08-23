#ifndef _KCC_STDINT_H
#define _KCC_STDINT_H
#include <kcc_settings.h>

typedef signed char int8_t;
typedef unsigned char uint8_t;
# define INT8_MIN		(-128)
# define INT8_MAX		(127)
# define UINT8_MAX		(255)

typedef signed short int16_t;
typedef unsigned short uint16_t;
# define INT16_MIN		(-32767-1)
# define INT16_MAX		(32767)
# define UINT16_MAX		(65535)

typedef signed int int32_t;
typedef unsigned int uint32_t;
# define INT32_MIN		(-2147483647-1)
# define INT32_MAX		(2147483647)
# define UINT32_MAX		(4294967295U)

typedef signed long long int64_t;
typedef unsigned long long uint64_t;
# define INT64_MIN		(-9223372036854775807LL-1)
# define INT64_MAX		(9223372036854775807LL)
# define UINT64_MAX		(18446744073709551615ULL)

typedef signed char int_least8_t;
typedef unsigned char uint_least8_t;
# define INT_LEAST8_MIN		(-128)
# define INT_LEAST8_MAX		(127)
# define UINT_LEAST8_MAX	(255)

typedef signed short int_least16_t;
typedef unsigned short uint_least16_t;
# define INT_LEAST16_MIN		(-32767-1)
# define INT_LEAST16_MAX		(32767)
# define UINT_LEAST16_MAX		(65535)

typedef signed int int_least32_t;
typedef unsigned int uint_least32_t;
# define INT_LEAST32_MIN		(-2147483647-1)
# define INT_LEAST32_MAX		(2147483647)
# define UINT_LEAST32_MAX		(4294967295U)

typedef signed long long int int_least64_t;
typedef unsigned long long int uint_least64_t;
# define INT_LEAST64_MIN		(-9223372036854775807LL-1)
# define INT_LEAST64_MAX		(9223372036854775807LL)
# define UINT_LEAST64_MAX		(18446744073709551615ULL)


typedef signed char int_fast8_t;
typedef unsigned char uint_fast8_t;
# define INT_FAST8_MIN		(-128)
# define INT_FAST8_MAX		(127)
# define UINT_FAST8_MAX	(255)

typedef signed short int_fast16_t;
typedef unsigned short uint_fast16_t;
# define INT_FAST16_MIN		(-32767-1)
# define INT_FAST16_MAX		(32767)
# define UINT_FAST16_MAX		(65535)

typedef signed int int_fast32_t;
typedef unsigned int uint_fast32_t;
# define INT_FAST32_MIN		(-2147483647-1)
# define INT_FAST32_MAX		(2147483647)
# define UINT_FAST32_MAX		(4294967295U)

typedef signed long long int int_fast64_t;
typedef unsigned long long int uint_fast64_t;
# define INT_FAST64_MIN		(-9223372036854775807LL-1)
# define INT_FAST64_MAX		(9223372036854775807LL)
# define UINT_FAST64_MAX		(18446744073709551615ULL)


// intptr_t and uintptr_t are optional

typedef signed long long int intmax_t;
typedef unsigned long long int uintmax_t;
# define INTMAX_MIN		(-9223372036854775807LL-1)
# define INTMAX_MAX		(9223372036854775807LL)
# define UINTMAX_MAX		(18446744073709551615ULL)

# define PTRDIFF_MIN (-2147483647-1)
# define PTRDIFF_MAX (2147483647)

# define SIZE_MAX	(4294967295U)

# define WCHAR_MIN (-2147483647-1)
# define WCHAR_MAX (2147483647)


# define INT8_C(value) ((int_least8_t) value)
# define INT16_C(value) ((int_least16_t) value)
# define INT32_C(value) ((int_least32_t) value)
# define INT64_C(value) ((int_least64_t) value)

# define UINT8_C(value) ((uint_least8_t) value)
# define UINT16_C(value) ((uint_least16_t) value)
# define UINT32_C(value) ((uint_least32_t) value)
# define UINT64_C(value) ((uint_least64_t) value)


# define INTMAX_C(value) ((intmax_t) value)
# define UINTMAX_C(value) ((uintmax_t) value)

#endif
