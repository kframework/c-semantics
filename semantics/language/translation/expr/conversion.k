module C-EXPR-CONVERSION
     imports C-CONVERSION-SYNTAX
     imports C-SYMBOLIC-VALUE-SYNTAX

     imports C-DYNAMIC-SYNTAX
     imports C-TYPING-SYNTAX
     imports C-SYMLOC-SYNTAX

     rule cast(T':Type, tv(symVal, _)) => tv(symVal, T')
          [structural, anywhere]

endmodule

