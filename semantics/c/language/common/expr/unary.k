module C-COMMON-EXPR-UNARY
     imports FLOAT
     imports INT
     imports C-SYNTAX
     imports C-COMMON-PROMOTION-SYNTAX
     imports C-CONVERSION-SYNTAX
     imports C-DYNAMIC-SYNTAX
     imports C-TYPING-SYNTAX

     /*@ \fromStandard{\source[n1570]{\para{6.5.3.3}{2}}}{
     The result of the unary \cinline{+} operator is the value of its
     (promoted) operand. The integer promotions are performed on the operand,
     and the result has the promoted type.
     }*/
     rule [unaryPlus-int]:
          + tv(I:Int, T::UType) => intArithInterpret(T, I)
          requires isPromoted(T)
          [structural]
     rule [unaryPlus-intptr]:
          + tv(L:SymLoc, T::UType) => tv(L, T)
          requires isPromoted(T)
     rule [unaryPlus-float]:
          + tv(F:Float, T::UType) => tv(F, T)
          [structural]

     /*@ \fromStandard{\source[n1570]{\para{6.5.3.3}{3}}}{
     The result of the unary \cinline{-} operator is the negative of its
     (promoted) operand. The integer promotions are performed on the operand,
     and the result has the promoted type.
     }*/
     rule [unaryMinus-int]:
          - tv(I:Int, T::UType) => intArithInterpret(T, 0 -Int I)
          requires isPromoted(T)
          [structural]
     rule [unaryMinus-float]:
          - tv(F:Float, T::UType) => floatArithInterpret(T, zeroCFloat(T) -Float F)
          [structural]

     /*@ \fromStandard{\source[n1570]{\para{6.5.3.3}{5}}}{
     The result of the logical negation operator \cinline{!} is 0 if the value
     of its operand compares unequal to 0, 1 if the value of its operand
     compares equal to 0. The result has type \cinline{int}.  The expression
     \cinline{!E} is equivalent to \cinline{(0==E)}.
     }*/
     rule !(E:RValue) => tv(0, ut(SetItem(IntegerConstant), int)) == E
          [structural]
endmodule

