struct A
{
  virtual void Foo() = 0;
};

struct B : A
{
  void Foo() { }
};

int main()
{
  B b;
  b.Foo();
  return 0;
}
