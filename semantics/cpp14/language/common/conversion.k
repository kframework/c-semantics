module CPP-CONVERSION-SYNTAX
     imports SYMLOC-SORTS
     imports CPP-DYNAMIC-SORTS
     imports CPP-TYPING-SORTS

     syntax Expr ::= instantiate(SymLoc, Trace, CPPType) [klabel(instantiateCpp)]

     syntax PRVal ::= convertType(CPPType, PRVal) [function]
                    | convertType(CPPType, PRExpr) [function]
     syntax PRVal ::= convertLVal(GLVal) [function]
                    | convertLVal(GLExpr) [function]
     syntax PRVal ::= convertArray(Val) [function]
     syntax PRVal ::= convertFunction(LVal) [function]
endmodule

module CPP-CONVERSION
     imports CPP-CONVERSION-SYNTAX
     imports CPP-DYNAMIC-SYNTAX
     imports CPP-TYPING-SYNTAX

     rule convertType(T::CPPType, prv(V::CPPValue, Tr::Trace, T)) => prv(V, Tr, T)
     rule convertType(T::CPPType, pre(E::Expr, Tr::Trace, T)) => pre(E, Tr, T)

     rule convertType(T:CPPPointerType, prv(_, Tr::Trace, _:CPPNullPtrTType)) => prv(NullPointer, Tr, T)

     rule convertArray(lv(Loc::SymLoc, Tr::Trace, t(Q::Quals, Mods::Set, T::CPPSimpleArrayType)))
          => prv(Loc, Tr, t(Q, Mods, pointerType(innerType(t(Q, Mods, T)))))

     rule convertFunction(lv(Loc::SymLoc, Tr::Trace, T::CPPFunctionType))
          => prv(Loc, Tr, t(noQuals, .Set, pointerType(T)))

     rule convertLVal(lv(Loc::SymLoc, Tr::Trace, T::CPPType))
          => instantiate(Loc, Tr, T)
     rule convertLVal(le(E::Expr, Tr::Trace, T::CPPType))
          => pre(E, Tr, utype(T))

endmodule
