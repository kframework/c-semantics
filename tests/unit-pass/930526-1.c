void exit(int status);
void abort(void);
static inline
void f (x)
      int x;
{
  int *(p[25]);
  int m[25*7];
  int i;

  for (i = 0; i < 25; i++)
    p[i] = m + x*i;

  p[1][0] = 0;
}

int main ()
{
  f (7);
  exit (0);
}
