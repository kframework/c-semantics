// PR c++/50787
// { dg-do run }

extern "C" void abort(void);

int main() {
  const int Ci = 0;
  const int &rCi = Ci;
  if (!(&Ci == &rCi)) abort();
}
