module C-EXPR-IDENTIFIER
     imports C-COMMON-EXPR-EVAL-SYNTAX
     imports C-DYNAMIC-SYNTAX
     imports C-MEMORY-READING-SYNTAX
     imports C-SYMBOLIC-VALUE-SYNTAX
     imports C-SYMLOC-SYNTAX
     imports C-TYPING-SYNTAX

     rule <k> X:Id => lv(Loc, T) ...</k>
          <env>... X |-> Loc:SymLoc ...</env>
          <types>... X |-> T:Type ...</types>
          when notBool isLinkerLoc(Loc)
          [structural]

     rule <k> X:Id => lv(Loc, T) ...</k>
          <env>... X |-> Loc:SymLoc ...</env>
          <types>... X |-> T:Type ...</types>
          <curr-tu> Tu:String </curr-tu>
          <tu-id> Tu </tu-id>
          <internals>... X |-> _ ...</internals>
          when isLinkerLoc(Loc)
          [structural]

     // We need to record uses of external symbols because if an external
     // without a definition isn't ever used, then it isn't a link error.
     rule <k> X:Id => lv(Loc, T) ...</k>
          <env>... X |-> Loc:SymLoc ...</env>
          <types>... X |-> T:Type ...</types>
          <curr-tu> Tu:String </curr-tu>
          <tu-id> Tu </tu-id>
          <externals>... X |-> _ ...</externals>
          <external-uses>... (. => SetItem(X)) </external-uses>
          when isLinkerLoc(Loc)
          [structural]

     rule <k> instantiate(_, T:Type) => tv(symVal, stripQualifiers(T)) ...</k>
          <initializing> false </initializing>

     rule <k> instantiate(L:SymLoc, T:Type) => read(L, T) ...</k>
          <initializing> true </initializing>
          when L =/=K symVal
endmodule
