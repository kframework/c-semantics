int f(x)
      int x;
{
      return x - x;
}

int g(p)
      int* p;
{
      return *p;
}

int h(x)
      float x;
{
      return 0;
}

int main(void) {
      int x = 0;
      return f(1) + f(&x) + h(3.3);
}

