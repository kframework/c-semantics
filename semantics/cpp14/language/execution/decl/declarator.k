module CPP-DECL-DECLARATOR
     imports C-CONFIGURATION
     imports K-EQUAL
     imports C-SEQUENCE-POINT-SYNTAX
     imports CPP-BITSIZE-SYNTAX
     imports CPP-DYNAMIC-SYNTAX
     imports CPP-ENV-SYNTAX
     imports CPP-MEMORY-ALLOC-SYNTAX
     imports CPP-SYMLOC-SYNTAX
     imports CPP-SYNTAX
     imports CPP-TYPING-SYNTAX

     syntax KItem ::= initializeObject(K)

     rule <k> declareNonStaticObject(X::CId, T::CPPType, Init::Expr, Var(_), AutoStorage, Mods::Set)
              => #if notBool isCPPRefType(T) #then allocObject(bnew(!I:Int, T, Mods, D), T, byteSizeofType(T)) #else .K #fi
              ~> addToEnv(X, T, bnew(!I:Int, T, Mods, D), false)
              ~> initializeObject(Init)
          ...</k>
          <duration> D::Duration </duration>
          <local-vars> Vars:Set (.Set => SetItem(X)) </local-vars>
          <local-addresses>... .Set => SetItem(bnew(!I:Int, T, Mods, D)) ...</local-addresses>
          requires notBool X in Vars andBool X =/=K #NoName

     rule declareNonStaticObject(#NoName, _, Init::Expr, _, _, _) => ExpressionStmt(Init)

     rule <k> initializeObject(Init::Expr) 
              => allowInit(ExpressionStmt(Init))
              ~> sequencePoint
          ...</k>
          <should-init> true </should-init>

     rule declareLocalStaticObject(X::CId, Base::SymBase, T::CPPType)
          => addToEnv(X, T, Base, false)

endmodule

