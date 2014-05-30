module C-EXPR-IDENTIFIER
     imports C-COMMON-EXPR-EVAL-SYNTAX
     imports C-DYNAMIC-SYNTAX
     imports C-MEMORY-READING-SYNTAX
     imports C-SYMBOLIC-VALUE-SYNTAX
     imports C-SYMLOC-SYNTAX
     imports C-TYPING-SYNTAX

     rule <k> X:CId => lv(lnew(Base), T) ...</k>
          <env>... X |-> Base:SymBase ...</env>
          <types>... X |-> T:Type ...</types>
          when notBool isLinkerLoc(Base)
               andBool Base =/=K symVal
          [structural]
     rule <k> X:CId => lv(symVal, T) ...</k>
          <env>... X |-> symVal ...</env>
          <types>... X |-> T:Type ...</types>
          [structural]

     rule <k> X:CId => lv(lnew(Base), T) ...</k>
          <env>... X |-> Base:SymBase ...</env>
          <types>... X |-> T:Type ...</types>
          <curr-tu> Tu:String </curr-tu>
          <tu-id> Tu </tu-id>
          <internals>... X |-> _ ...</internals>
          when isLinkerLoc(Base)
          [structural]

     // We need to record uses of external symbols because if an external
     // without a definition isn't ever used, then it isn't a link error.
     rule <k> X:CId => lv(lnew(Base), T) ...</k>
          <env>... X |-> Base:SymBase ...</env>
          <types>... X |-> T:Type ...</types>
          <curr-tu> Tu:String </curr-tu>
          <tu-id> Tu </tu-id>
          <externals>... X |-> _ ...</externals>
          <external-uses>... (. => SetItem(X)) </external-uses>
          when isLinkerLoc(Base)
          [structural]

     rule <k> instantiate(Loc:SymLoc, T:Type) => tv(symVal, stripQualifiers(T)) ...</k>
          when notBool isConstType(T)
               orBool notBool isStaticDuration(Loc)
               orBool isLinkerLoc(Loc)
     rule <k> instantiate(Loc:SymLoc, T:Type) => read(Loc, T) ...</k>
          when isConstType(T)
               andBool isStaticDuration(Loc) 
               andBool notBool isLinkerLoc(Loc)
endmodule
