module C-EXPR-CONVERSION
     imports C-CONVERSION-SYNTAX
     imports C-SYMBOLIC-VALUE-SYNTAX

     imports C-DYNAMIC-SYNTAX
     imports C-TYPING-SYNTAX
     imports C-SYMLOC-SYNTAX

     rule cast(T':Type, e(K:K, _)) => e(K, T')

endmodule

