module CPP-TRANSLATION-EXPR-REFERENCE
     imports C-CONFIGURATION
     imports BOOL
     imports SYMLOC-SYNTAX
     imports CPP-DYNAMIC-SYNTAX
     imports CPP-REFERENCE-SYNTAX
     imports CPP-TYPING-SYNTAX

     rule bindReference(L:LExpr, R:Val) => le(bindReference(L, R), trace(L), type(L))
          requires Translation()

     // we need this result tag because lvalues of reference type aren't KResults
     context bindReference(HOLE:Expr, _) [result(LVal)]

     rule <k> bindReference(lv(Loc1::SymLoc, Tr::Trace, T1::CPPType), lv(Loc2::SymLoc, _, T2::CPPType))
              => lv(Loc1, Tr, T1) ...</k>
          <references>... .Map => stripProv(Loc1) |-> Loc2 ...</references>
          requires Translation() andBool isCPPLVRefType(T1) andBool notBool isCPPBitfieldType(T2) andBool isReferenceCompatible(innerType(T1), T2)


endmodule
