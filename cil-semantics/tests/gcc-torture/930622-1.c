void exit(int status);
void abort(void);
int a = 1, b;

int g () { return 0; }
void h (x) {}

int f ()
{
  if (g () == -1)
    return 0;
  a = g ();
  if (b >= 1)
    h (a);
  return 0;
}

int main ()
{
  f ();
  if (a != 0)
    abort ();
  exit (0);
}
