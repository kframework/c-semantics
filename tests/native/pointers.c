#include<assert.h>
#include<stdio.h>
#include<time.h>
#include<string.h>
extern char incomplete[];

char *pointer(char *);

union bar {
  short x[2];
  int y;
};

void bar3(union bar *);

int main() {
  assert(incomplete[0] == 0);
  assert(incomplete[1] == 1);
  pointer(incomplete);
  assert(incomplete[0] == 'c');
  FILE *test = fopen("./testfile.txt", "r");
  assert(fgetc(test) == 'f');
  fclose(test);
  char c[10];
  struct tm test2;
  time_t t;
  time(&t);
  test2 = *localtime(&t);
  strftime(c, 10, "%C", &test2);
  assert(strcmp(c, "20") == 0);
  union bar x = {{0, 1}};
  bar3(&x);
  assert(x.x[0] == 2);
  return 0;
}
