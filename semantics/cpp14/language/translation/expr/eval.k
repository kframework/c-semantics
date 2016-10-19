module CPP-TRANSLATION-EXPR-EVAL
     imports BOOL
     imports CPP-ABSTRACT-SYNTAX
     imports CPP-CONVERSION-SYNTAX
     imports CPP-DYNAMIC-SYNTAX
     imports CPP-TYPING-SYNTAX

     rule convertReval(le(E::Expr, Tr::Trace, T::CPPType)) => pre(E, Tr, prvalType(T))
          requires notBool isCPPArrayType(T) andBool notBool isCPPFunctionType(T)
     rule convertReval(le(E::Expr, Tr::Trace, T:CPPArrayType)) => pre(E, Tr, type(pointerType(innerType(T))))
     rule convertReval(le(E::Expr, Tr::Trace, T:CPPFunctionType)) => pre(E, Tr, type(pointerType(T)))

endmodule
