int a = 1;
int f(int x) { return x; }
int g(int x = f(a)) { return x; }
int main() {
  a = 2;
  {
    int a = 3;
    return g() - 2;
  }
}