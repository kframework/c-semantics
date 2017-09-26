/* Derived from the test case in
   http://sourceware.org/bugzilla/show_bug.cgi?id=713.  */
#include <stdio.h>

int main (void)
{
  FILE* fp = tmpfile();
  fprintf(fp, "%s", "hello");
  rewind(fp);

  char buf[2];
  char *bp = fgets (buf, sizeof (buf), fp);
  printf ("fgets: %s\n", bp == buf ? "OK" : "ERROR");
  int res = bp != buf;
  rewind(fp);

  char buf2[10];
  bp = fgets (buf2, 5, fp);
  printf ("fgets: %s\n", bp == buf2 ? "OK" : "ERROR");
  res |= bp != buf2;
  rewind(fp);

  bp = fgets (buf2, sizeof (buf2), fp);
  printf ("fgets: %s\n", bp == buf2 ? "OK" : "ERROR");
  res |= bp != buf2;
  rewind(fp);

  // bp = fgets_unlocked (buf, sizeof (buf), fp);
  // printf ("fgets_unlocked: %s\n", bp == buf ? "OK" : "ERROR");
  // res |= bp != buf;
  return res;
}

