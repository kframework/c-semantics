module CPP-TRANSLATION-EXPR-MEMBERS
     imports C-CONFIGURATION
     imports CPP-EXPR-MEMBERS-SYNTAX
     imports CPP-SYNTAX
     imports CPP-ABSTRACT-SYNTAX
     imports CPP-DYNAMIC-SYNTAX
     imports CPP-TRANSLATION-OVERLOADING-SYNTAX
     imports CPP-TRANSLATION-OPERATORS-SYNTAX

     rule <k> This() => Obj ...</k>
          <tr-this> Obj::Expr </tr-this>
          requires Translation()

     context CallExpr(HOLE:Expr . _ _, _, _)

     syntax KItem ::= CallExprOpArrowFreezer(StrictList, StrictListResult)

     rule CallExpr(BinaryOperator(operator->, _, _) #as E::Expr, S::StrictList, R::StrictListResult)
          => resolveBinaryOperator(E)
          ~> CallExprOpArrowFreezer(S, R)

     rule resolveOverloadResult(E:ResolvedExpr)
          ~> CallExprOpArrowFreezer(S::StrictList, R::StrictListResult)
          => CallExpr(E, S, R)

     rule fieldExp(E:GLExpr, T::CPPType, Offset::Int)
          => makeExpr(cat(E), fieldExp(E, T, Offset), trace(E), T)
endmodule
