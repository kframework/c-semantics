#include<climits>
#include<cstdio>
class Integer {
  int val;
public:

  void increment() & {
    if (val == INT_MAX) {
      throw "integer overflow";
    }
    val = val + 1;
  }

  void increment() && {
    val = val + 1;
  }

  void print() {
    printf("%d\n", val);
  }

  Integer(int val) : val(val) {}
};

int main() {
  Integer x(INT_MAX);
  try {
    x.increment();
  } catch (const char *msg) {
    printf("%s\n", msg);
  }
  try {
    reinterpret_cast<Integer&&>(x).increment();
  } catch (const char *msg) {
    printf("%s\n", msg);
  }
}
