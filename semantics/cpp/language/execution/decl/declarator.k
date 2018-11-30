module CPP-EXECUTION-DECL-DECLARATOR
     imports C-CONFIGURATION
     imports K-EQUAL
     imports C-SEQUENCE-POINT-SYNTAX
     imports CPP-BITSIZE-SYNTAX
     imports CPP-DYNAMIC-SYNTAX
     imports CPP-EXECUTION-ENV-SYNTAX
     imports CPP-MEMORY-ALLOC-SYNTAX
     imports CPP-SYMLOC-SYNTAX
     imports CPP-SYNTAX
     imports CPP-TYPING-SYNTAX

     syntax KItem ::= initializeObjectExec(K)

     rule <k> declareNonStaticObjectExec(X::CId, T::CPPType, Init::Expr, Var(_), AutoStorage, Mods::Set)
              => #if notBool isCPPRefType(T) #then allocObject(bnew(!I:Int, T, Mods, D), T, byteSizeofType(T)) #else .K #fi
              ~> addToExecEnv(X, T, bnew(!I:Int, T, Mods, D), false)
              ~> initializeObjectExec(Init)
          ...</k>
          <duration> D::Duration </duration>
          <local-vars> Vars:Set (.Set => SetItem(X)) </local-vars>
          <local-addresses>... .Set => SetItem(bnew(!I:Int, T, Mods, D)) ...</local-addresses>
          requires notBool X in Vars andBool X =/=K #NoName

     rule declareNonStaticObjectExec(#NoName, _, Init::Expr, _, _, _) => ExpressionStmt(Init)

     rule <k> initializeObjectExec(Init::Expr)
              => ExpressionStmt(Init)
              ~> sequencePoint
          ...</k>
          <should-init> true </should-init>

     rule declareLocalStaticObject(X::CId, Base::SymBase, T::CPPType)
          => addToExecEnv(X, T, Base, false)

endmodule

