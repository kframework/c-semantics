module CPP-EXECUTION-DECL-DECLARATOR
     imports C-CONFIGURATION
     imports K-EQUAL
     imports C-SEQUENCE-POINT-SYNTAX
     imports COMPAT-SYNTAX
     imports CPP-BITSIZE-SYNTAX
     imports CPP-DYNAMIC-SYNTAX
     imports CPP-EXECUTION-ENV-SYNTAX
     imports CPP-EXECUTION-STMT-BLOCK-SYNTAX
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
                    LCregisterForDestruction(ExecName(NoNNS(), X))
                 #else .K #fi
              ~> initializeObjectExec(Init)
              ~> #if notBool isCPPRefType(T) #then
                    LCupdateRegisteredForDestruction(size(LC))
                 #else .K #fi
          ...</k>
          <duration> D::Duration </duration>
          <local-vars> Vars:Set (.Set => SetItem(X)) </local-vars>
          <locally-constructed> LC::List </locally-constructed>
          requires notBool X in Vars andBool X =/=K #NoName

     syntax KItem ::= LCregisterForDestruction(Expr) [strict(1)]

     // we register the object for destruction before
     // its initializer runs (but with the `initialized` flag cleared)
     // so that if an exception is thrown in the initializer,
     // the allocated object gets deleted.
     // The `initialized` flag is set later
     // in `LCupdateRegisteredForDestruction()`.
     rule <k> LCregisterForDestruction(Obj:LVal) => .K ...</k>
          <locally-constructed> .List =>
               ListItem(lcentry(Obj, false, true, false))
          ...</locally-constructed>

     syntax KItem ::= LCupdateRegisteredForDestruction(Int)
                    | LCupdateRegisteredForDestruction2(idx: Int, entry: KItem)

     // `-1 -Int Size` from the end is the index of the newly-added entry
     rule <k> LCupdateRegisteredForDestruction(Size::Int)
          => LCupdateRegisteredForDestruction2(-1 -Int Size, LC[-1 -Int Size])
          ...</k>
          <locally-constructed> LC::List </locally-constructed>

     rule <k> LCupdateRegisteredForDestruction2(Idx::Int,
               lcentry(Obj::LVal, false, CanBeVirtual::Bool, IsConstructor::Bool)) => .K
          ...</k>
          <locally-constructed>
               LC::List => myListUpdate(LC, (size(LC) +Int Idx), lcentry(Obj, true, CanBeVirtual, IsConstructor))
          </locally-constructed>


     rule declareNonStaticObjectExec(#NoName, _, Init::Expr, _, _, _) => ExpressionStmt(Init)

     rule <k> initializeObjectExec(Init::Expr)
              => ExpressionStmt(Init)
              ~> sequencePoint
          ...</k>
          <should-init> true </should-init>

     rule declareLocalStaticObject(X::CId, Base::SymBase, T::CPPType)
          => addToExecEnv(X, T, Base, false)

endmodule

