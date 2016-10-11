module CPP-TRANSLATION-EXPR-EVAL
     imports BOOL
     imports CPP-DYNAMIC-SYNTAX
     imports CPP-TYPING-SYNTAX

     rule reval(le(E::Expr, Tr::Trace, T::CPPType) => pre(E, Tr, T))
          requires notBool isCPPArrayType(T) andBool notBool isCPPFunctionType(T)
     rule reval(le(E::Expr, Tr::Trace, T:CPPArrayType) => pre(E, Tr, type(pointerType(innerType(T)))))
     rule reval(le(E::Expr, Tr::Trace, T:CPPFunctionType) => pre(E, Tr, type(pointerType(T))))

endmodule
