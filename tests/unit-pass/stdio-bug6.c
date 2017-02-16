#include <stdio.h>

int
main (void)
{
  char buf[12];
  int i;
  int lost = 0;

  FILE* f = tmpfile();
  fprintf(f, "%s", "XY 1234L");
  rewind(f);

  fscanf (f, "%2s", buf);
  lost |= (buf[0] != 'X' || buf[1] != 'Y' || buf[2] != '\0');
  if (lost)
    puts ("test of %2s failed.");
  fscanf (f, " ");
  fscanf (f, "%d", &i);
  lost |= (i != 1234);
  if (lost)
    puts ("test of %d failed.");
  fscanf (f, "%c", buf);
  lost |= (buf[0] != 'L');
  if (lost)
    puts ("test of %c failed.\n");

  puts (lost ? "Test FAILED!" : "Test succeeded.");
  return lost;
}
