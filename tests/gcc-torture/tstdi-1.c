#include <stdlib.h>
#define FALSE 140
#define TRUE 13

int feq (x)
     long long int x;
{
  if (x == 0)
    return TRUE;
  else
    return FALSE;
}

int fne (x)
     long long int x;
{
  if (x != 0)
    return TRUE;
  else
    return FALSE;
}

int flt (x)
     long long int x;
{
  if (x < 0)
    return TRUE;
  else
    return FALSE;
}

int fge (x)
     long long int x;
{
  if (x >= 0)
    return TRUE;
  else
    return FALSE;
}

int fgt (x)
     long long int x;
{
  if (x > 0)
    return TRUE;
  else
    return FALSE;
}

int fle (x)
     long long int x;
{
  if (x <= 0)
    return TRUE;
  else
    return FALSE;
}

int main ()
{
  if (feq (0LL) != TRUE)
    abort ();
  if (feq (-1LL) != FALSE)
    abort ();
  if (feq (0x8000000000000000LL) != FALSE)
    abort ();
  if (feq (0x8000000000000001LL) != FALSE)
    abort ();
  if (feq (1LL) != FALSE)
    abort ();
  if (feq (0x7fffffffffffffffLL) != FALSE)
    abort ();

  if (fne (0LL) != FALSE)
    abort ();
  if (fne (-1LL) != TRUE)
    abort ();
  if (fne (0x8000000000000000LL) != TRUE)
    abort ();
  if (fne (0x8000000000000001LL) != TRUE)
    abort ();
  if (fne (1LL) != TRUE)
    abort ();
  if (fne (0x7fffffffffffffffLL) != TRUE)
    abort ();

  if (flt (0LL) != FALSE)
    abort ();
  if (flt (-1LL) != TRUE)
    abort ();
  if (flt (0x8000000000000000LL) != TRUE)
    abort ();
  if (flt (0x8000000000000001LL) != TRUE)
    abort ();
  if (flt (1LL) != FALSE)
    abort ();
  if (flt (0x7fffffffffffffffLL) != FALSE)
    abort ();

  if (fge (0LL) != TRUE)
    abort ();
  if (fge (-1LL) != FALSE)
    abort ();
  if (fge (0x8000000000000000LL) != FALSE)
    abort ();
  if (fge (0x8000000000000001LL) != FALSE)
    abort ();
  if (fge (1LL) != TRUE)
    abort ();
  if (fge (0x7fffffffffffffffLL) != TRUE)
    abort ();

  if (fgt (0LL) != FALSE)
    abort ();
  if (fgt (-1LL) != FALSE)
    abort ();
  if (fgt (0x8000000000000000LL) != FALSE)
    abort ();
  if (fgt (0x8000000000000001LL) != FALSE)
    abort ();
  if (fgt (1LL) != TRUE)
    abort ();
  if (fgt (0x7fffffffffffffffLL) != TRUE)
    abort ();

  if (fle (0LL) != TRUE)
    abort ();
  if (fle (-1LL) != TRUE)
    abort ();
  if (fle (0x8000000000000000LL) != TRUE)
    abort ();
  if (fle (0x8000000000000001LL) != TRUE)
    abort ();
  if (fle (1LL) != FALSE)
    abort ();
  if (fle (0x7fffffffffffffffLL) != FALSE)
    abort ();

  exit (0);
}
