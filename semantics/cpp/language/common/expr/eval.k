module CPP-EXPR-EVAL
     imports BOOL
     imports CPP-CONVERSION-SYNTAX
     imports CPP-DYNAMIC-SYNTAX
     imports CPP-TYPING-SYNTAX

     rule reval(L:GLVal => convertReval(L))

     rule convertReval(lv(Loc::SymLoc, Tr::Trace, T:CPPArrayType))
          => convertArray(lv(Loc, Tr, T))

     rule convertReval(xv(Loc::SymLoc, Tr::Trace, T:CPPArrayType))
          => convertArray(xv(Loc, Tr, T))

     rule convertReval(prv(Loc::SymLoc, Tr::Trace, T:CPPArrayType))
          => convertArray(prv(Loc, Tr, T))

     rule convertReval(lv(Loc::SymLoc, Tr::Trace, T:CPPFunctionType))
          => convertFunction(lv(Loc, Tr, T))

     rule convertReval(L:GLVal)
          => convertLVal(L)
          requires notBool isCPPFunctionType(type(L))
               andBool notBool isCPPArrayType(type(L))

endmodule
