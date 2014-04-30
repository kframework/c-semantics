
// "If the type of the operand is a variable length array type, the operand is
// evaluated; otherwise, the operand is not evaluated and the result is an
// integer constant."

int main(void) {
      int n = 1;
      int x[n][n];

      sizeof (x[--n]);

      return n;
}
