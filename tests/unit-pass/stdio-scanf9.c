#include <stdio.h>
#include <stdlib.h>
#include <string.h>

int
main (void)
{
  int matches;
  char str[10];
  char * alloced_str;

  str[0] = '\0';
  matches = -9;
  matches = sscanf ("x ]", "%[^] ]", str);
  printf ("Matches = %d, string str = \"%s\".\n", matches, str);
  printf ("str should be \"x\".\n");

  if (strcmp (str, "x"))
    abort ();

  matches = -9;
  matches = sscanf ("x ]", "%m[^] ]", &alloced_str);
  printf ("Matches = %d, string str = \"%s\".\n", matches, alloced_str);
  printf ("str should be \"x\".\n");

  if (strcmp (alloced_str, "x"))
    abort ();

  free(alloced_str);

  str[0] = '\0';
  matches = -9;
  matches = sscanf (" ] x", "%[] ]", str);
  printf ("Matches = %d, string str = \"%s\".\n", matches, str);
  printf ("str should be \" ] \".\n");

  if (strcmp (str, " ] "))
    abort ();

  matches = -9;
  matches = sscanf (" ] x", "%m[] ]", &alloced_str);
  printf ("Matches = %d, string str = \"%s\".\n", matches, alloced_str);
  printf ("str should be \" ] \".\n");

  if (strcmp (alloced_str, " ] "))
    abort ();

  free(alloced_str);

  return 0;
}
