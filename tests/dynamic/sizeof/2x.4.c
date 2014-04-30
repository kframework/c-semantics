
// "The sizeof operator shall not be applied to an expression that has function
// type or an incomplete type, to the parenthesized name of such a type, or to
// an expression that designates a bit-field member."

struct {
      int x:4;
} s;

int main(void) {
      return sizeof(s.x);
}
