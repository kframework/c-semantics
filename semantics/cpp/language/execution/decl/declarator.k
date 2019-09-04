module CPP-EXECUTION-DECL-DECLARATOR
     imports C-CONFIGURATION
     imports K-EQUAL
     imports C-SEQUENCE-POINT-SYNTAX
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
                    registerForDestruction(ExecName(NoNNS(), X))
                 #else .K #fi
              ~> initializeObjectExec(Init)
              ~> #if notBool isCPPRefType(T) #then
                    updateRegisteredForDestruction(size(LC))
                 #else .K #fi
          ...</k>
          <duration> D::Duration </duration>
          <local-vars> Vars:Set (.Set => SetItem(X)) </local-vars>
          <locally-constructed> LC::List </locally-constructed>
          requires notBool X in Vars andBool X =/=K #NoName

     syntax KItem ::= registerForDestruction(Expr) [strict(1)]

     // we register the object for destruction before
     // its initializer runs (but with the `IsConstructor` flag set)
     // so that if an exception is thrown in the initializer,
     // the allocated object gets deleted.
     // The `IsConstructor` flag is cleared later
     // in `updateRegisteredForDestruction()`.
     rule <k> registerForDestruction(Obj:LVal) => .K ...</k>
          <locally-constructed> .List =>
               ListItem(lcentry(Obj, false, true, false))
          ...</locally-constructed>

     syntax KItem ::= updateRegisteredForDestruction(Int)
                    | updateRegisteredForDestruction2(idx: Int, entry: KItem)

     // `-1 -Int Size` from the end is the index of the newly-added entry
     rule <k> updateRegisteredForDestruction(Size::Int)
          => updateRegisteredForDestruction2(-1 -Int Size, LC[-1 -Int Size])
          ...</k>
          <locally-constructed> LC::List </locally-constructed>

     rule <k> updateRegisteredForDestruction2(Idx::Int,
               lcentry(Obj::LVal, false, CanBeVirtual::Bool, IsConstructor::Bool)) => .K
          ...</k>
          <locally-constructed>
               LC::List => myListUpdate(LC, (size(LC) +Int Idx), lcentry(Obj, true, CanBeVirtual, IsConstructor))
          </locally-constructed>

     // implements List[Idx <- Val]
     syntax List ::= myListUpdate(List, Int, KItem) [function]
                   | #myListUpdate(List, List, Int, KItem) [function]

     rule myListUpdate(L::List, Idx::Int, V::KItem)
          => #myListUpdate(.List, L, Idx, V)

     rule #myListUpdate(L1::List, ListItem(_) L2::List, 0, V::KItem)
          => L1 ListItem(V) L2

     rule #myListUpdate(
               _::List (.List => ListItem(V)),
               (ListItem(V::KItem) => .List) _,
               N::Int => N -Int 1,
               _
          )
          requires N >Int 0

     rule declareNonStaticObjectExec(#NoName, _, Init::Expr, _, _, _) => ExpressionStmt(Init)

     rule <k> initializeObjectExec(Init::Expr)
              => ExpressionStmt(Init)
              ~> sequencePoint
          ...</k>
          <should-init> true </should-init>

     rule declareLocalStaticObject(X::CId, Base::SymBase, T::CPPType)
          => addToExecEnv(X, T, Base, false)

endmodule

