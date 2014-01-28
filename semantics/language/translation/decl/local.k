module C-DECL-LOCAL-SYNTAX
     syntax K ::= declareInternalVariable(Id, Type, K)
endmodule

module C-DECL-LOCAL
     imports C-DECL-LOCAL-SYNTAX
     imports C-DECL-GLOBAL-SYNTAX
     imports C-DECL-INITIALIZER-SYNTAX
     imports C-DECL-DEFINITION-SYNTAX
     imports C-ENV-SYNTAX
     imports C-SYMBOLIC-VALUE-SYNTAX

     imports C-SYNTAX
     imports C-TYPING-SYNTAX
     imports C-SYMLOC-SYNTAX
     imports COMPAT-SYNTAX

     // TODO(chathhorn): note that execution/declaration/local.k starts from
     // doDeclare, not declareInternalVariable.

     // TODO(chathhorn): Totally not sure what to do about these first cases.
     // Should the external types be updated/completed?
     rule <k> declareInternalVariable(X:Id, T':Type, NoInit) 
               => addToEnv(X, Loc)
               ~> giveType(X, unqualifyType(T'))
          ...</k>
          <external-types>... X |-> T:Type ...</external-types>
          <external-defs>... X |-> Loc:SymLoc ...</external-defs>
          when (isFunctionType(T') orBool isExternType(T'))
               andBool notBool isStaticType(T')
               andBool isTypeCompatible(T, T')
          [structural] 
     rule <k> declareInternalVariable(X:Id, T':Type, NoInit) 
               => addToEnv(X, symVal)
               ~> giveType(X, unqualifyType(T'))
          ...</k>
          <external-types>... X |-> T:Type ...</external-types>
          <external-defs> Defs:Map </external-defs>
          when (isFunctionType(T') orBool isExternType(T'))
               andBool notBool isStaticType(T')
               andBool isTypeCompatible(T, T')
               andBool notBool (X in keys Defs)
          [structural] 
     rule <k> declareInternalVariable(X:Id, T:Type, NoInit) 
               => addToEnv(X, symVal)
               ~> giveType(X, unqualifyType(T))
          ...</k>
          <external-types> Types:Map </external-types>
          when (isFunctionType(T) orBool isExternType(T))
               andBool notBool isStaticType(T)
               andBool notBool (X in keys Types)
          [structural] 
     
     rule declareInternalVariable(X:Id, T:Type, NoInit)
          => addToEnv(X, symVal)
          ~> giveType(X, unqualifyType(T))
          when isNaked(T) orBool isStaticType(T)
          [structural] 

     rule declareInternalVariable(X:Id, T:Type, K:K)
          => addToEnv(X, symVal)
          ~> defineAndInit(X, unqualifyType(T), 
               figureInit(X, removeStorageSpecifiers(T), K))
          when (isNaked(T) orBool isStaticType(T))
               andBool (K =/=K NoInit)
          [structural] 
          
     syntax K ::= defineAndInit(Id, Type, K) [strict(3)] 
     rule defineAndInit(X:Id, _, initValue(_, T:Type, K:K))
          => giveType(X, T)
          ~> K
          [structural] 

endmodule

