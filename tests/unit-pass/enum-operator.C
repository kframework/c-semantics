enum A : long {
  a, b, c
};

enum B : long long {
  d, e, f
};

enum C : unsigned {
  g, h, i
};
enum D : char {
  j, k, l
};

int main() {
  a < b; //chooses A, A
  a > d; //chooses long, long long
  a <= g; //chooses long, unsigned
  g >= j; //chooses unsigned, int
}
