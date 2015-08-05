module C-COMMON-EXTENSIONS
  imports C-SYNTAX
  imports C-CONFIGURATION
  imports C-DYNAMIC-SYNTAX
  imports C-TYPING-SYNTAX

  // Statement expressions
  syntax KItem ::= GnuBodyReturn(K)
  context GnuBodyReturn(HOLE => reval(HOLE)) [result(RValue)]

endmodule
