module CPP-CONVERSION-SYNTAX
     imports SYMLOC-SORTS
     imports CPP-DYNAMIC-SORTS
     imports CPP-TYPING-SORTS

     syntax Expr ::= instantiate(SymLoc, CPPType) [klabel(instantiateCpp)]

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

     rule convertType(T::CPPType, prv(V::CPPValue, T)) => prv(V, T)
     rule convertType(T::CPPType, pre(E::Expr, T)) => pre(E, T)

     rule convertArray(lv(Loc::SymLoc, t(Q::Quals, Mods::Set, T::CPPSimpleArrayType)))
          => prv(Loc, t(Q, Mods, pointerType(innerType(t(Q, Mods, T)))))

     rule convertFunction(lv(Loc::SymLoc, T::CPPFunctionType))
          => prv(Loc, t(noQuals, .Set, pointerType(T)))

     rule convertLVal(lv(Loc::SymLoc, T::CPPType))
          => instantiate(Loc, T)
     rule convertLVal(le(E::Expr, T::CPPType))
          => pre(E, utype(T))

endmodule
