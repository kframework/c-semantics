module CPP-EXPR-EVAL
     imports BOOL
     imports CPP-CONVERSION-SYNTAX
     imports CPP-DYNAMIC-SYNTAX
     imports CPP-REVAL-SYNTAX
     imports CPP-TYPING-SYNTAX

     rule reval(lv(Loc::SymLoc, T:CPPArrayType)
          => convertArray(lv(Loc, T)))

     rule reval(lv(Loc::SymLoc, T:CPPFunctionType)
          => convertFunction(lv(Loc, T)))

     rule reval(L:LVal
          => convertLVal(L))
          requires notBool isCPPArrayType(type(L))
               andBool notBool isCPPFunctionType(type(L))


endmodule
