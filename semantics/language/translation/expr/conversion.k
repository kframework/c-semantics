module C-EXPR-CONVERSION
     imports C-CONVERSION-SYNTAX

     imports C-ABSTRACT-SYNTAX
     imports C-DYNAMIC-SYNTAX
     imports C-TYPING-SYNTAX
     imports C-SYMLOC-SYNTAX

     rule cast(T':Type, te(K:K, _)) => te(Cast(T', K), T')

endmodule

