void exit(int status);
void abort(void);
long x = -1L;

int main()
{
  long b = (x != -1L);

  if (b)
    abort();

  exit(0);
}

