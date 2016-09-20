module CPP-EXPR-CAST-SYNTAX
     imports CPP-DYNAMIC-SORTS
     imports CPP-TYPING-SORTS

     syntax Expr ::= convertConst(CPPType, Val) [function]
     syntax Val ::= "cannot-convert"

endmodule

module CPP-EXPR-CAST
     imports CPP-EXPR-CAST-SYNTAX
     imports CPP-CONVERSION-SYNTAX
     imports CPP-DYNAMIC-SYNTAX
     imports CPP-TYPING-SYNTAX

     rule convertConst(T2::CPPType, prv(V::CPPValue, Tr::Trace, T1::CPPType))
          => prv(V, Tr, T2)
          requires isSimilar(T2, T1)
     rule convertConst(t(_, _, lvRefType(T2::CPPType)), lv(Loc::SymLoc, Tr::Trace, T1::CPPType))
          => lv(Loc, Tr, T2)
          requires isObjectType(T1) andBool isObjectType(T2)
               andBool isSimilar(type(pointerType(T2)), 
                                 type(pointerType(T1)))

     rule convertConst(t(_, _, rvRefType(T2::CPPType)), lv(Loc::SymLoc, Tr::Trace, T1::CPPType))
          => xv(Loc, Tr, T2)
          requires isObjectType(T1) andBool isObjectType(T2)
               andBool isSimilar(type(pointerType(T2)), 
                                 type(pointerType(T1)))
     rule convertConst(t(_, _, rvRefType(T2::CPPType)), xv(Loc::SymLoc, Tr::Trace, T1::CPPType))
          => xv(Loc, Tr, T2)
          requires isObjectType(T1) andBool isObjectType(T2)
               andBool isSimilar(type(pointerType(T2)), 
                                 type(pointerType(T1)))
     rule convertConst(t(_, _, rvRefType(T2::CPPType)), prv(Loc::SymLoc, Tr::Trace, T1:CPPClassType))
          => xv(Loc, Tr, T2)
     rule convertConst(_, V:Val) => cannot-convert
          requires notBool isTExpr(V) [owise]


endmodule
