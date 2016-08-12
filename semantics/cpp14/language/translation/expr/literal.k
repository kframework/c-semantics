module CPP-EXPR-LITERAL
     imports C-CONFIGURATION
     imports STRING
     imports CPP-ABSTRACT-SYNTAX
     imports CPP-ELABORATOR-SYNTAX
     imports CPP-MEMORY-ALLOC-SYNTAX
     imports CPP-MEMORY-WRITING-SYNTAX
     imports CPP-TYPING-EXPR-SYNTAX
     imports CPP-TYPING-SYNTAX
     imports CPP-SYMLOC-SYNTAX

     syntax Expr ::= StringLiteral(String, K) [klabel(StringLiteral2)]
     context StringLiteral(_, (HOLE:KItem => typeof(HOLE)))

     rule StringLiteral(K::CharKind, S::String) => StringLiteral(S, StringLiteral(K, S))

     rule StringLiteral(S::String, T:CPPType) => stringLiteral(S, T)

     rule IntegerLiteral(I::Int, T:CPPType) => prv(I, hasTrace(IntegerLiteral(I, T)), T)

     rule NullPointerLiteral() => prv(nullptrVal, hasTrace(NullPointerLiteral()), type(nullptr_t))

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
          => allocObject(Base, T, lengthString(S) +Int 1)
          ~> writeString(lnew(Base, T), S)

endmodule
