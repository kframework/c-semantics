// "If the type of the operand is a variable length array type, the operand is
// evaluated; otherwise, the operand is not evaluated and the result is an
// integer constant."

// There appears to be a special exception for array declarators, but I don't
// think that exception should hold in this case.

int main(void) {
      int n = 1;
      int a[n];

      sizeof(--n, a);

      return n; // n should be 0.
}
