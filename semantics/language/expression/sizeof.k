module C-EXPRESSION-SIZEOF
     imports C-EXPRESSION-SYNTAX

     imports C-SYNTAX
     imports C-DYNAMIC-SYNTAX
     imports C-TYPING-SYNTAX
     imports C-BITSIZE-SYNTAX
     imports C-BITS-SYNTAX
     imports C11-SETTINGS-SYNTAX
     
     /*@ \fromStandard{\source[n1570]{\para{6.5.3.4}{2}}}{
     The \cinline{sizeof} operator yields the size (in bytes) of its operand,
     which may be an expression or the parenthesized name of a type. The size
     is determined from the type of the operand. The result is an integer. If
     the type of the operand is a variable length array type, the operand is
     evaluated; otherwise, the operand is not evaluated and the result is an
     integer constant.
     }*/
     
     /*@ \fromStandard{\source[n1570]{\para{6.5.3.4}{5}}}{
     The value of the result of both operators is implementation-defined, and
     its type (an unsigned integer type) is \cinline{size_t}, defined in
     \header{<stddef.h>} (and other headers).
     }*/
     
     rule sizeofType(T:Type)
          => cast(cfg:sizeut, byteSizeofType(T)) 
          [structural]
     syntax K ::= "byteSizeofType-aux" "(" K ")" [strict]
     rule byteSizeofType(T:Type)
          => byteSizeofType-aux(bitSizeofType(T)) 
          [structural, anywhere]
     rule byteSizeofType-aux(V:Value)
          => bitsToBytes(value(V))
          [structural]

     rule SizeofExpression(E:K)
          => sizeofType(typeof(E))
          [structural]
     rule SizeofType(T:Type, K:K)
          => sizeofType(DeclType(T, K))
          [structural]
endmodule

