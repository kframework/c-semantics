// { dg-do run { target c++11 } }

typedef decltype(nullptr) nullptr_t;

extern "C" void abort(void);

int i;
nullptr_t n;
const nullptr_t& f() { ++i; return n; }

nullptr_t g() { return f(); }

int main()
{
  g();
  if (i != 1)
    abort ();
}
