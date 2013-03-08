void exit(int status);
void abort(void);
int f (x)
{
  x &= 010000;
  x &= 007777;
  x ^= 017777;
  x &= 017770;
  return x;
}

int main ()
{
  if (f (-1) != 017770)
    abort ();
  exit (0);
}
