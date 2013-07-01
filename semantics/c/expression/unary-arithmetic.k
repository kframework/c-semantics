module C-EXPRESSION-UNARY-ARITHMETIC
     imports C-SYNTAX
     imports C-DYNAMIC-SYNTAX
     imports C-CONVERSION-SYNTAX
     imports C-PROMOTION-SYNTAX
     imports C-TYPING-SYNTAX
     imports C-BITS-SYNTAX

     /*@ \fromStandard{\source[n1570]{\para{6.5.3.3}{2}}}{
     The result of the unary \cinline{+} operator is the value of its
     (promoted) operand. The integer promotions are performed on the operand,
     and the result has the promoted type.
     }*/       
     rule [unaryPlus-int]: 
          + tv(I:Int, T:Type) => arithInterpret(T, I:Int)
          when isPromoted(T)
          [structural]
     rule [unaryPlus-float]: 
          + tv(F:Float, T:Type) => tv(F:Float, T:Type)
          [structural]   
          
     /*@ \fromStandard{\source[n1570]{\para{6.5.3.3}{3}}}{
     The result of the unary \cinline{-} operator is the negative of its
     (promoted) operand. The integer promotions are performed on the operand,
     and the result has the promoted type.
     }*/
     rule [unaryMinus-int]: 
          - tv(I:Int, T:Type) => arithInterpret(T, 0 -Int I:Int)
          when isPromoted(T)
          [structural]
     rule [unaryMinus-float]: 
          - tv(F:Float, T:Type) => arithInterpret(T, 0.0 -Float F:Float)
          [structural]

     /*@ \fromStandard{\source[n1570]{\para{6.5.3.3}{4}}}{
     The result of the \cinline{\~} operator is the bitwise complement of its
     (promoted) operand (that is, each bit in the result is set if and only if
     the corresponding bit in the converted operand is not set). The integer
     promotions are performed on the operand, and the result has the promoted
     type. If the promoted type is an unsigned type, the expression
     \cinline{\~E} is equivalent to the maximum value representable in that
     type minus \cinline{E}.
     }*/
     rule ~ tv(I:Bits, T:Type) => arithInterpret(T, ~Bits I)
          when isPromoted(T)
          [structural]

     /*@ \fromStandard{\source[n1570]{\para{6.5.3.3}{5}}}{
     The result of the logical negation operator \cinline{!} is 0 if the value
     of its operand compares unequal to 0, 1 if the value of its operand
     compares equal to 0. The result has type \cinline{int}.  The expression
     \cinline{!E} is equivalent to \cinline{(0==E)}.
     }*/
     rule !(E:K) => tv(0, t(.Set, int)) == E:K
          [structural]
endmodule
     
