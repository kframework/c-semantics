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
              => #if notBool isCPPRefType(T) #then
                    allocObject(bnew(!I:Int, T, Mods, D), T, byteSizeofType(T))
                 #else .K #fi
              ~> addToExecEnv(X, T, bnew(!I:Int, T, Mods, D), false)
              ~> #if notBool isCPPRefType(T) #then
                    registerForDestruction(ExecName(NoNNS(), X))
                 #else .K #fi
              ~> initializeObjectExec(Init)
              ~> #if notBool isCPPRefType(T) #then
                    updateRegisteredForDestruction()
                 #else .K #fi
          ...</k>
          <duration> D::Duration </duration>
          <local-vars> Vars:Set (.Set => SetItem(X)) </local-vars>
          requires notBool X in Vars andBool X =/=K #NoName

     syntax KItem ::= registerForDestruction(Expr) [strict(1)]

     // we register the object for destruction before
     // its initializer runs (but with the `IsConstructor` flag set)
     // so that if an exception is thrown in the initializer,
     // the allocated object gets deleted.
     // The `IsConstructor` flag is cleared later
     // in `updateRegisteredForDestruction()`.
     // TODO what happens with references?
     rule <k> registerForDestruction(Obj:LVal) => .K ...</k>
          <locally-constructed> .List =>
               ListItem(ktriple(Obj, true, true))
          ...</locally-constructed>

     syntax KItem ::= updateRegisteredForDestruction()

     rule <k> updateRegisteredForDestruction() => .K ...</k>
          <locally-constructed>
               ListItem(ktriple(_, _, true => false))
          ...</locally-constructed>

     rule declareNonStaticObjectExec(#NoName, _, Init::Expr, _, _, _) => ExpressionStmt(Init)

     rule <k> initializeObjectExec(Init::Expr)
              => ExpressionStmt(Init)
              ~> sequencePoint
          ...</k>
          <should-init> true </should-init>

     rule declareLocalStaticObject(X::CId, Base::SymBase, T::CPPType)
          => addToExecEnv(X, T, Base, false)

endmodule

