module C-EXPR-CONVERSION
     imports C-CONVERSION-SYNTAX
     imports C-SYMBOLIC-VALUE-SYNTAX

     imports C-DYNAMIC-SYNTAX
     imports C-TYPING-SYNTAX
     imports C-SYMLOC-SYNTAX

     rule cast(t(S:Set, bool), tv(symVal, T:Type)) => tv(symVal, t(S, bool))
          when hasIntegerType(T) orBool isBitfieldType(T)
          [structural, anywhere]
     
     rule [cast-integer-no-value-change]:
          cast(T:Type, tv(symVal, T':Type)) => tv(symVal, T)
          when (hasIntegerType(T') orBool isBitfieldType(T') orBool isFloatType(T'))
               andBool (hasIntegerType(T) orBool isBitfieldType(T) orBool isFloatType(T))
               andBool notBool isBoolType(T)
          [structural, anywhere]

endmodule

