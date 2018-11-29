module CPP-TRANSLATION-EXPR-EVAL
     imports BOOL
     imports CPP-ABSTRACT-SYNTAX
     imports CPP-CONVERSION-SYNTAX
     imports CPP-DYNAMIC-SYNTAX
     imports CPP-TYPING-SYNTAX

     rule convertReval(E:GLExpr) => convertLVal(E)
          requires Translation() andBool notBool isCPPArrayType(type(E)) andBool notBool isCPPFunctionType(type(E))

     rule convertReval(le(E::Expr, Tr::Trace, T:CPPArrayType)) => pre(E, Tr, type(pointerType(innerType(T))))
          requires Translation()

     rule convertReval(xe(E::Expr, Tr::Trace, T:CPPArrayType)) => pre(E, Tr, type(pointerType(innerType(T))))
          requires Translation()

     rule convertReval(pre(E::Expr, Tr::Trace, T:CPPArrayType)) => pre(E, Tr, type(pointerType(innerType(T))))
          requires Translation()

     rule convertReval(le(E::Expr, Tr::Trace, T:CPPFunctionType)) => pre(E, Tr, type(pointerType(T)))
          requires Translation()

endmodule
