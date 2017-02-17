module CPP-OPERATORS
     imports BASIC-K
     imports CPP-ABSTRACT-SYNTAX
     imports CPP-SYNTAX
     imports CPP-TYPING-EXPR-SYNTAX
     imports CPP-TYPING-SYNTAX
     imports CPP-TYPING-SORTS

     rule BinaryOperator(O::OpId, E1::Expr, E2::Init)
          => #BinaryOperator(O, E1, E1, E2, E2)

     rule UnaryOperator(O::OpId, E1::Expr)
          => #UnaryOperator(O, E1, E1)

     syntax Expr ::= #BinaryOperator(OpId, Expr, TypeExpr, Init, K)
                   | #UnaryOperator(OpId, Expr, TypeExpr)
     context #BinaryOperator(_, _, (HOLE:TypeExpr => typeof(HOLE)), _, _) [result(CPPDType)]
     context #BinaryOperator(_, _, _, _, (HOLE:TypeExpr => typeof(HOLE))) [result(CPPDType)]
     context #UnaryOperator(_, _, (HOLE:TypeExpr => typeof(HOLE))) [result(CPPDType)]

     rule #BinaryOperator(O::OpId, E1::Expr, T1:CPPType, E2::Init, T2:CPPType)
          => builtinOperator(O, E1, E2)
          requires notBool isCPPClassType(T1) andBool notBool isCPPClassType(T2)
               andBool notBool isCPPEnumType(T1) andBool notBool isCPPEnumType(T2)

     rule #UnaryOperator(O::OpId, E1::Expr, T1:CPPDType)
          => builtinOperator(O, E1)
          requires notBool isCPPClassType(T1) andBool notBool isCPPEnumType(T1)

     syntax Expr ::= builtinOperator(OpId, Expr, Init) [function]
                   | builtinOperator(OpId, Expr) [function, klabel(builtinOperator2)]
     rule builtinOperator(operator=, E1::Expr, E2::Init)
          => E1 := E2
     rule builtinOperator(operator[], E1::Expr, E2::Expr)
          => E1[E2]
     rule builtinOperator(operator+, E1::Expr, E2::Expr)
          => E1 + E2
     rule builtinOperator(operator-, E1::Expr, E2::Expr)
          => E1 - E2
     rule builtinOperator(operator*, E1::Expr, E2::Expr)
          => E1 * E2
     rule builtinOperator(operator/, E1::Expr, E2::Expr)
          => E1 / E2
     rule builtinOperator(operator%, E1::Expr, E2::Expr)
          => E1 % E2
     rule builtinOperator(operator||, E1::Expr, E2::Expr)
          => E1 || E2
     rule builtinOperator(operator&&, E1::Expr, E2::Expr)
          => E1 && E2
     rule builtinOperator(operator&, E1::Expr, E2::Expr)
          => E1 & E2
     rule builtinOperator(operator|, E1::Expr, E2::Expr)
          => E1 | E2
     rule builtinOperator(operator^, E1::Expr, E2::Expr)
          => E1 ^ E2
     rule builtinOperator(operator==, E1::Expr, E2::Expr)
          => E1 == E2
     rule builtinOperator(operator!=, E1::Expr, E2::Expr)
          => E1 != E2
     rule builtinOperator(operator<, E1::Expr, E2::Expr)
          => E1 < E2
     rule builtinOperator(operator<=, E1::Expr, E2::Expr)
          => E1 <= E2
     rule builtinOperator(operator>, E1::Expr, E2::Expr)
          => E1 > E2
     rule builtinOperator(operator>=, E1::Expr, E2::Expr)
          => E1 >= E2
     rule builtinOperator(operator+=, E1::Expr, E2::Expr)
          => E1 += E2
     rule builtinOperator(operator-=, E1::Expr, E2::Expr)
          => E1 -= E2
     rule builtinOperator(operator*=, E1::Expr, E2::Expr)
          => E1 *= E2
     rule builtinOperator(operator/=, E1::Expr, E2::Expr)
          => E1 /= E2
     rule builtinOperator(operator%=, E1::Expr, E2::Expr)
          => E1 %= E2
     rule builtinOperator(operator^=, E1::Expr, E2::Expr)
          => E1 ^= E2
     rule builtinOperator(operator&=, E1::Expr, E2::Expr)
          => E1 &= E2
     rule builtinOperator(operator|=, E1::Expr, E2::Expr)
          => E1 |= E2
     rule builtinOperator(operator<<, E1::Expr, E2::Expr)
          => E1 << E2
     rule builtinOperator(operator>>, E1::Expr, E2::Expr)
          => E1 >> E2
     rule builtinOperator(operator<<=, E1::Expr, E2::Expr)
          => E1 <<= E2
     rule builtinOperator(operator>>=, E1::Expr, E2::Expr)
          => E1 >>= E2
     rule builtinOperator(operator_++, E1::Expr)
          => E1 ++
     rule builtinOperator(operator_--, E1::Expr)
          => E1 --
     rule builtinOperator(operator++_, E1::Expr)
          => ++ E1
     rule builtinOperator(operator--_, E1::Expr)
          => -- E1
     rule builtinOperator(operator!, E1::Expr)
          => ! E1
     rule builtinOperator(operator-, E1::Expr)
          => - E1
     rule builtinOperator(operator&, E1::Expr)
          => & E1
     rule builtinOperator(operator*, E1::Expr)
          => * E1

endmodule
