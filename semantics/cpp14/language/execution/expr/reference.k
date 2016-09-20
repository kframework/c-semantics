module CPP-EXPR-REFERENCE
     imports C-CONFIGURATION
     imports CPP-DYNAMIC-SYNTAX
     imports CPP-TYPING-SYNTAX

     // we need this result tag because lvalues of reference type aren't KResults
     context bindReference(HOLE:Expr, _) [result(LVal)]

     rule <k> bindReference(lv(Loc1::SymLoc, Tr::Trace, T1::CPPType), lv(Loc2::SymLoc, _, T2::CPPType))
              => .K ...</k>
          <references>... .Map => stripProv(Loc1) |-> Loc2 ...</references>
          requires isCPPLVRefType(T1) andBool notBool isCPPBitfieldType(T2) andBool isReferenceCompatible(innerType(T1), T2)

     syntax Bool ::= isReferenceCompatible(CPPType, CPPType) [function]
                   | isReferenceRelated(CPPType, CPPType) [function]

     rule isReferenceRelated(T1::CPPType, T2::CPPType) => true
          requires T1 ==Type T2
     rule isReferenceCompatible(T1::CPPType, T2::CPPType) => isReferenceRelated(utype(T1), utype(T2)) andBool getQuals(T2) <=Quals getQuals(T1)

endmodule
