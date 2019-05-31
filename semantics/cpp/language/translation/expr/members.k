module CPP-TRANSLATION-EXPR-MEMBERS
     imports C-CONFIGURATION
     imports CPP-EXPR-MEMBERS-SYNTAX
     imports CPP-SYNTAX
     imports CPP-ABSTRACT-SYNTAX
     imports CPP-DYNAMIC-SYNTAX

     rule <k> This() => Obj ...</k>
          <tr-this> Obj::Expr </tr-this>
          requires Translation()

     context CallExpr(HOLE:Expr . _ _, _, _)

     context CallExpr(BinaryOperator(operator->, _, _) #as HOLE:Expr, _, _) [result(ResolvedExpr), structural]

     rule fieldExp(E:GLExpr, T::CPPType, Offset::Int)
          => makeExpr(cat(E), fieldExp(E, T, Offset), trace(E), T)
endmodule
