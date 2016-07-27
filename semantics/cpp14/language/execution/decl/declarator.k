module CPP-DECL-DECLARATOR
     imports C-CONFIGURATION
     imports C-SEQUENCE-POINT-SYNTAX
     imports CPP-BITSIZE-SYNTAX
     imports CPP-ENV-SYNTAX
     imports CPP-MEMORY-ALLOC-SYNTAX
     imports CPP-TYPING-SYNTAX

     syntax KItem ::= initializeObject(K)

     rule <k> declareNonStaticObject(X::CId, T::CPPType, initValue(_, _, Init:K), Var, AutoStorage, _)
              => allocObject(!I:Int @ D, T, byteSizeofType(T))
              ~> addToEnv(X, T, !I @ D, false)
              ~> initializeObject(Init)
          ...</k>
          <duration> D::Duration </duration>
          <local-vars> Vars:List (.List => ListItem(X)) </local-vars>
          <local-addresses>... .Set => SetItem(!I @ D) ...</local-addresses>
          requires notBool X in Vars

     rule <k> initializeObject(Init:K) 
              => allowInit(Init)
              ~> sequencePoint
          ...</k>
          <should-init> true </should-init>

endmodule

