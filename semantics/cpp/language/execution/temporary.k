module CPP-EXECUTION-TEMPORARY-SYNTAX
     imports BOOL

     syntax KItem ::= destructTemporaries(isException: Bool)
endmodule

module CPP-EXECUTION-TEMPORARY
     imports CPP-EXECUTION-TEMPORARY-SYNTAX
     imports C-CONFIGURATION
     imports CPP-DYNAMIC-SYNTAX
     imports CPP-EXECUTION-STMT-BLOCK-SYNTAX
     imports COMPAT-SYNTAX

     // This code works similarly to the code
     // of declarator.k (with LCregisterForDestruction),
     // just with another cell.
     rule <k> createTemporaryExec(Temp::Expr, Init::Expr)
          => CTregisterForDestruction(Temp)
          ~> Init
          ~> CTupdateRegisteredForDestruction(size(CT))
          ...</k>
          <constructed-temporaries> CT::List </constructed-temporaries>

     syntax KItem ::= CTregisterForDestruction(Expr) [strict(1)]

     rule <k> CTregisterForDestruction(Obj:LVal) => .K ...</k>
          <constructed-temporaries> .List =>
               ListItem(lcentry(Obj, false, true, false))
          ...</constructed-temporaries>

     syntax KItem ::= CTupdateRegisteredForDestruction(Int)
                    | CTupdateRegisteredForDestruction2(idx: Int, entry: KItem)

     // `-1 -Int Size` from the end is the index of the newly-added entry
     rule <k> V:LVal ~> CTupdateRegisteredForDestruction(Size::Int)
          => CTupdateRegisteredForDestruction2(-1 -Int Size, CT[-1 -Int Size])
          ~> V
          ...</k>
          <constructed-temporaries> CT::List </constructed-temporaries>
          requires isEvalVal(V)

     rule <k> CTupdateRegisteredForDestruction2(Idx::Int,
               lcentry(Obj::LVal, false, CanBeVirtual::Bool, IsConstructor::Bool)) => .K
          ...</k>
          <constructed-temporaries>
               CT::List => myListUpdate(CT, (size(CT) +Int Idx), lcentry(Obj, true, CanBeVirtual, IsConstructor))
          </constructed-temporaries>


     rule <k> (.K => destructLocal(IsException, Entry))
              ~> destructTemporaries(IsException:Bool)
          ...</k>
          <constructed-temporaries> ListItem(Entry::KTuple) => .List ...</constructed-temporaries>

     rule <k> destructTemporaries(...) => .K ...</k>
          <constructed-temporaries> .List </constructed-temporaries>


endmodule
