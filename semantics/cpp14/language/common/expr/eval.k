module CPP-EXPR-EVAL
     imports BOOL
     imports CPP-CONVERSION-SYNTAX
     imports CPP-DYNAMIC-SYNTAX
     imports CPP-REVAL-SYNTAX
     imports CPP-TYPING-SYNTAX

     rule reval(L:LVal => convertReval(L))

     rule convertReval(lv(Loc::SymLoc, Tr::Trace, T:CPPArrayType))
          => convertArray(lv(Loc, Tr, T))

     rule convertReval(lv(Loc::SymLoc, Tr::Trace, T:CPPFunctionType))
          => convertFunction(lv(Loc, Tr, T))

     rule convertReval(L:LVal)
          => convertLVal(L) [owise]

endmodule
