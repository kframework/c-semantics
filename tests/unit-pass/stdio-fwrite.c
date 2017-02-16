/* Derived from the test case in
   http://sourceware.org/bugzilla/show_bug.cgi?id=1078.  */
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>

#define OUT_SIZE 100

int
main (void)
{
  FILE* f = tmpfile ();
  if (f == NULL) {
    puts ("cannot create stream");
    return 1;
  }
  puts ("Opened temp file");

  if (fwrite ("a", 1, 1, f) != 1)
    {
      puts ("1st fwrite failed");
      return 1;
    }
  puts ("Wrote a byte");
  fflush (f);

  char buffer[OUT_SIZE];
  size_t i = fread (buffer, 1, sizeof (buffer), f);
  printf ("Read %zu bytes\n", i);

  for (i = 0; i < OUT_SIZE; i++)
    {
      if (fwrite ("n", 1, 1, f) != 1)
	{
	  printf ("fwrite in loop round %zu failed\n", i);
	  return 1;
	}

      if ((i + 1) % (OUT_SIZE/10) == 0)
	printf ("wrote %zu bytes ...\n", i + 1);
    }

  printf ("Wrote %i bytes [done]\n", OUT_SIZE);

  return 0;
}
