void exit(int status);
void abort(void);
typedef enum foo E;
enum foo { e0, e1 };

struct {
  E eval;
} s;

p()
{
  abort();
}

void f()
{
  switch (s.eval)
    {
    case e0:
      p();
    }
}

main()
{
  s.eval = e1;
  f();
  exit(0);
}
