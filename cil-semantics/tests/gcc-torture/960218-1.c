void exit(int status);
void abort(void);
int glob;

int g (x)
{
  glob = x;
  return 0;
}

void f (x)
{
  int a = ~x;
  while (a)
    a = g (a);
}

int main ()
{
  f (3);
  if (glob != -4)
    abort ();
  exit (0);
}
