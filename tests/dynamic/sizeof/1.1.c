static void a(void);

//  "... if an identifier declared with internal linkage is used in an
//  expression (other than as a part of the operand of a sizeof or _Alignof
//  operator whose result is an integer constant), there shall be exactly one
//  external definition for the identifier in the translation unit."

int main(void) {
      sizeof(a());

      return 0;
}
