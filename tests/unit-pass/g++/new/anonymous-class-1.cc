int b = 2;
struct S {
  virtual int f() {
    struct T : public S {
      int f() override {
        return b + c;
      }
      int c = 2;
    } x;
    return x.f()-1;
  }
  static int b;
};

int S::b = 1;

int main() {
  return S().f() - 2;
}