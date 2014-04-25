
// "The sizeof operator shall not be applied to an expression that has function
// type or an incomplete type, to the parenthesized name of such a type, or to
// an expression that designates a bit-field member."

int main(void) {
      return sizeof(int[]);
}
