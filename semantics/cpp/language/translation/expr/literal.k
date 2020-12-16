module CPP-TRANSLATION-EXPR-LITERAL
     imports C-CONFIGURATION
     imports FLOAT
     imports STRING
     imports CPP-ABSTRACT-SYNTAX
     imports CPP-ALIGNMENT-SYNTAX
     imports CPP-BITSIZE-SYNTAX
     imports CPP-TRANSLATION-ELABORATOR-SYNTAX
     imports CPP-MEMORY-ALLOC-SYNTAX
     imports CPP-MEMORY-WRITING-SYNTAX
     imports CPP-TRANSLATION-TYPING-EXPR-SYNTAX
     imports CPP-TYPING-SYNTAX
     imports CPP-SYMLOC-SYNTAX
     imports CPP-SYNTAX

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

     rule FloatingLiteral(F::Float, t(... st: _:CPPSimpleFloatingType) #as T::CPPType) => prv(roundFloat(F, precision(T), exponent(T)), hasTrace(FloatingLiteral(F, T)), T)

     syntax Expr ::= stringLiteral(String, CPPType)

     rule <k> (.K => runInit(allocString(obj(0, byteAlignofType(T), string(S)), T, S)))
               ~> stringLiteral(S::String, T::CPPType, _)
          ...</k>
          <mem> Mem::Map </mem>
          requires notBool (obj(0, byteAlignofType(T), string(S)) in_keys(Mem))

     rule stringLiteral(S::String, T::CPPType) => stringLiteral(S, T, byteAlignofType(T))

     syntax KItem ::= stringLiteral(String, CPPType, Int)

     rule <k> stringLiteral(S::String, T::CPPType, Align::Int)
              => lv(lnew(obj(0, Align, string(S))), hasTrace(StringLiteral(S, T)), T)
          ...</k>
          <mem>... obj(0, Align, string(S)) |-> _ ...</mem>

     syntax KItem ::= allocString(SymBase, CPPType, String) [klabel(allocStringCpp)]

     rule allocString(Base::SymBase, T::CPPType, S::String)
          => allocObject(Base, T, lengthString(S))
          ~> initString(lnew(Base), S)
          ~> lv(lnew(Base), hasTrace(StringLiteral(S, T)), T)

     syntax KItem ::= initString(SymLoc, String) [klabel(initStringCpp)]

     rule initString(Loc::SymLoc, S::String)
          => TExpressionStmt(
               lv(Loc, noTrace, type(unsigned-char))
               :=init prv(ordChar(firstChar(S)), noTrace, type(unsigned-char)))
               ~> initString(Loc +bytes 1, butFirstChar(S))
          requires S =/=String ""

     rule initString(_::SymLoc, "")
          => .K

endmodule
