module CPP-CONVERSION-SYNTAX
     imports CPP-TYPING-SYNTAX

     syntax PRVal ::= convertType(CPPType, PRVal) [function]
     syntax PRVal ::= convertLVal(GLVal) [function]
     syntax PRVal ::= convertArray(Val) [function]
     syntax PRVal ::= convertFunction(LVal) [function]
endmodule

module CPP-CONVERSION
     imports CPP-CONVERSION-SYNTAX

     rule convertType(T::CPPType, prv(V::CPPValue, T)) => prv(V, T)

     rule convertArray(lv(Loc::SymLoc, t(Q::Quals, Mods::Set, T::CPPSimpleArrayType)))
          => prv(Loc, t(Q, Mods, pointerType(innerType(t(Q, Mods, T)))))

endmodule
