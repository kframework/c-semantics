module CPP-TRANSLATION-EXPR-MEMBERS
     imports C-CONFIGURATION
     imports CPP-EXPR-MEMBERS-SYNTAX
     imports CPP-SYNTAX
     imports CPP-ABSTRACT-SYNTAX
     imports CPP-DYNAMIC-SYNTAX

     context CallExpr(HOLE:Expr . _ _, _, _)
     context CallExpr(BinaryOperator(operator->, _, _) #as HOLE:Expr, _, _) [result(ResolvedExpr), structural]

     rule fieldExp(E:LExpr, T::CPPType, Offset::Int)
          => le(fieldExp(E, T, Offset), trace(E), T)
endmodule
