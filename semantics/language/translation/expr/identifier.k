module C-EXPR-IDENTIFIER
     imports C-SYMBOLIC-VALUE-SYNTAX
     imports C-COMMON-EXPR-EVAL-SYNTAX
     imports C-DYNAMIC-SYNTAX
     imports C-SYMLOC-SYNTAX

     rule [lookup]:
          <k> X:Id => lv(Loc, T) ...</k>
          <env>... X |-> Loc:SymLoc ...</env>
          <types>... X |-> T:Type ...</types>
          when notBool isLinkerLoc(Loc)
          [structural]

     rule [lookup-internal]:
          <k> X:Id => lv(Loc, T) ...</k>
          <env>... X |-> Loc:SymLoc ...</env>
          <types>... X |-> T:Type ...</types>
          <currTU> Tu:String </currTU>
          <tu-id> Tu </tu-id>
          <internals>... X |-> _ ...</internals>
          when isLinkerLoc(Loc)
          [structural]

     // We need to record uses of external symbols because if an external
     // without a definition isn't ever used, then it isn't a link error.
     rule [lookup-external]:
          <k> X:Id => lv(Loc, T) ...</k>
          <env>... X |-> Loc:SymLoc ...</env>
          <types>... X |-> T:Type ...</types>
          <currTU> Tu:String </currTU>
          <tu-id> Tu </tu-id>
          <externals>... X |-> _ ...</externals>
          <external-uses>... (. => SetItem(X)) </external-uses>
          when isLinkerLoc(Loc)
          [structural]

     rule <k> instantiateIdVal(_, T:Type) => tv(symVal, T) ...</k>
          <currentFunction> F:Id </currentFunction>
          when F =/=K file-scope
          
endmodule
