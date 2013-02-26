int main(void) 
{
  int x, *p = &x;
  x = 0;
  ++*p;
  x += *p;
  return *p;
}

