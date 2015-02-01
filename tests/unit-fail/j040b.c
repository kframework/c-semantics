int f(p)
      int* p;
{
      return *p;
}
int main(void) {
      long long int x = 5;
      return f(&x);
}

