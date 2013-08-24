#ifndef _KCC_TIME_H
#define _KCC_TIME_H
#include <kcc_settings.h>
#include <stddef.h>

// #ifndef _KCC_EXPERIMENTAL_TIME
// #error time.h not supported
// #endif

#define NULL _KCC_NULL
#define CLOCKS_PER_SEC ((clock_t)1)
#define TIME_UTC 1

typedef signed long long clock_t;
typedef signed long long time_t;

struct timespec {
	time_t tv_sec; // whole seconds -- = 0
	long tv_nsec; // nanoseconds -- [0, 999999999]
};
struct tm {
	int tm_sec; // seconds after the minute -- [0, 60]
	int tm_min; // minutes after the hour -- [0, 59]
	int tm_hour; // hours since midnight -- [0, 23]
	int tm_mday; // day of the month -- [1, 31]
	int tm_mon; // months since January -- [0, 11]
	int tm_year; // years since 1900
	int tm_wday; // days since Sunday -- [0, 6]
	int tm_yday; // days since January 1 -- [0, 365]
	int tm_isdst; // Daylight Saving Time flag
};

clock_t clock(void);
double difftime(time_t time1, time_t time0);
time_t mktime(struct tm *timeptr);
time_t time(time_t* timer);
int timespec_get(struct timespec *ts, int base);
char *asctime(const struct tm *timeptr);
char *ctime(const time_t *timer);
struct tm *gmtime(const time_t *timer);
struct tm *localtime(const time_t *timer);
size_t strftime(char * restrict s, size_t maxsize, const char * restrict format, const struct tm * restrict timeptr);

#endif
