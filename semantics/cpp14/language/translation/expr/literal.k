module CPP-EXPR-LITERAL
     imports C-CONFIGURATION
     imports FLOAT
     imports STRING
     imports CPP-ABSTRACT-SYNTAX
     imports CPP-BITSIZE-SYNTAX
     imports CPP-ELABORATOR-SYNTAX
     imports CPP-MEMORY-ALLOC-SYNTAX
     imports CPP-MEMORY-WRITING-SYNTAX
     imports CPP-TYPING-EXPR-SYNTAX
     imports CPP-TYPING-SYNTAX
     imports CPP-SYMLOC-SYNTAX

     syntax Expr ::= StringLiteral(String, TypeExpr) [klabel(StringLiteral2)]
     context StringLiteral(_, (HOLE:TypeExpr => typeof(HOLE)))
     syntax Expr ::= CharacterLiteral(Int, TypeExpr) [klabel(CharacterLiteral2)]
     context CharacterLiteral(_, (HOLE:TypeExpr => typeof(HOLE)))

     rule StringLiteral(K::CharKind, S::String) => StringLiteral(S, StringLiteral(K, S))
     rule CharacterLiteral(K::CharKind, I::Int) => CharacterLiteral(I, CharacterLiteral(K, I))

     rule StringLiteral(S::String, T:CPPType) => stringLiteral(S +String terminator(byteSizeofType(innerType(T))), T)

     syntax String ::= terminator(Int) [function]
     rule terminator(0) => ""
     rule terminator(I::Int) => "\x00" +String terminator(I -Int 1) [owise]

     rule CharacterLiteral(I::Int, T:CPPType) => prv(I, hasTrace(CharacterLiteral(I, T)), T)

     rule IntegerLiteral(I::Int, T:CPPType) => prv(I, hasTrace(IntegerLiteral(I, T)), T)

     rule BoolLiteral(false) => prv(0, hasTrace(BoolLiteral(false)), type(bool))
     rule BoolLiteral(true) => prv(1, hasTrace(BoolLiteral(true)), type(bool))

     rule NullPointerLiteral() => prv(nullptrVal, hasTrace(NullPointerLiteral()), type(nullptr_t))

     rule FloatingLiteral(F::Float, T:CPPFloatingType) => prv(roundFloat(F, precision(T), exponent(T)), hasTrace(FloatingLiteral(F, T)), T)

     syntax Expr ::= stringLiteral(String, CPPType)

     rule <k> (.K => runInit(allocString(string(S), T, S)))
               ~> stringLiteral(S::String, T::CPPType)
          ...</k>
          <mem> Mem::Map </mem>
          requires notBool (string(S) in_keys(Mem))

     rule <k> stringLiteral(S::String, T::CPPType)
              => lv(lnew(string(S), T), hasTrace(StringLiteral(S, T)), T)
          ...</k>
          <mem>... string(S) |-> _ ...</mem>

     syntax KItem ::= allocString(SymBase, CPPType, String)
     rule allocString(Base::SymBase, T::CPPType, S::String)
          => allocObject(Base, T, lengthString(S))
          ~> writeString(lnew(Base, T), S)
          ~> lv(lnew(Base, T), hasTrace(StringLiteral(S, T)), T)

endmodule
