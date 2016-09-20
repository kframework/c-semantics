module CPP-EXPR-NEW
     imports CPP-ABSTRACT-SYNTAX
     imports CPP-DYNAMIC-SYNTAX
     imports CPP-SYNTAX
     imports CPP-TYPING-SYNTAX

     rule (.K => CallExpr(Name(GlobalNamespace(), operatornew[]), list(ListItem(Size)))) ~> NewExpr(T:CPPType, Size:Expr, _, .List)
          requires notBool isCPPClassType(T) andBool notBool isCPPArrayType(T)

     // TODO(dwightguth): default initialization
     rule R:PRExpr ~> NewExpr(T:CPPType, Size::Expr, NoInit(), P::List) => pre(NewOp(T, R, .K), hasTrace(NewExpr(T, Size, NoInit(), P)), type(pointerType(T)))
          requires notBool isCPPClassType(T) andBool notBool isCPPArrayType(T)

endmodule
