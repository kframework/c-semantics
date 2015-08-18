module C-EXECUTION-EXTENSIONS
  imports C-COMMON-EXTENSIONS

  // Statement expressions
  rule GnuBodyReturn(R:RValue) ~> popBlock => popBlock ~> R

endmodule
