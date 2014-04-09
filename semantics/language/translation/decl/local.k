module C-DECL-LOCAL-SYNTAX
     syntax K ::= declareInternalVariable(Id, Type, K)
endmodule

module C-DECL-LOCAL
     imports C-DECL-LOCAL-SYNTAX
     imports C-DECL-GLOBAL-SYNTAX
     imports C-DECL-INITIALIZER-SYNTAX
     imports C-DECL-DEFINITION-SYNTAX
     imports C-DECL-ZERO-SYNTAX
     imports C-ENV-SYNTAX
     imports C-SYMBOLIC-VALUE-SYNTAX

     imports C-SYNTAX
     imports C-TYPING-SYNTAX
     imports C-SYMLOC-SYNTAX
     imports C-MEMORY-ALLOC-SYNTAX
     imports COMPAT-SYNTAX

     // TODO(chathhorn): note that execution/declaration/local.k starts from
     // doDeclare, not declareInternalVariable.

     // TODO(chathhorn): Totally not sure what to do about these first cases.
     // Should the external types be updated/completed?
     rule <k> declareInternalVariable(X:Id, T':Type, NoInit) 
               => addToEnv(X, Loc)
               ~> giveType(X, T')
          ...</k>
          <external-types>... X |-> T:Type ...</external-types>
          <external-defs>... X |-> Loc:SymLoc ...</external-defs>
          when (isFunctionType(T') orBool isExternType(T'))
               andBool notBool isStaticType(T')
               andBool isTypeCompatible(T, T')
          [structural] 
     rule <k> declareInternalVariable(X:Id, T':Type, NoInit) 
               => addToEnv(X, symVal)
               ~> giveType(X, T')
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
               ~> giveType(X, T)
          ...</k>
          <external-types> Types:Map </external-types>
          when (isFunctionType(T) orBool isExternType(T))
               andBool notBool isStaticType(T)
               andBool notBool (X in keys Types)
          [structural] 

     rule declareInternalVariable(X:Id, T:Type, K:K)
          => initLocalStatic(X,
               allowInit(figureInit(X, unqualifyType(T), K)))
          when isStaticType(T)
               andBool (notBool isExternType(T))
               andBool (notBool isFunctionType(T))
          [structural] 

     syntax K ::= initLocalStatic(Id, K) [strict(2)] 
     rule <k> initLocalStatic(X:Id, initValue(_, T:Type, K:K))
               => allocateType(Loc, T)
               ~> addToEnv(X, Loc)
               ~> giveType(X, T)
               ~> allowInit(zero(X) ~> K)
          ...</k>
          <curr-block> BlockNum:Int </curr-block>
          <curr-tu> TU:String </curr-tu>
          <tu-id> TU </tu-id>
          <next-static-loc> Loc:SymLoc => linc(Loc) </next-static-loc>
          <local-statics>
               LocalStatics:Map (.Map =>  kpair(X, BlockNum) |-> Loc)
          </local-statics>
          <local-types>
               LocalTypes:Map (.Map =>  kpair(X, BlockNum) |-> T)
          </local-types>
          when notBool kpair(X, BlockNum) in keys LocalTypes
               andBool (notBool kpair(X, BlockNum) in keys LocalStatics)
          [structural] 

     rule declareInternalVariable(X:Id, T:Type, NoInit)
          => addToEnv(X, symVal)
          ~> giveType(X, T)
          when isNaked(T)
          [structural] 

     rule declareInternalVariable(X:Id, T:Type, K:K)
          => addToEnv(X, symVal)
          ~> defineAndInit(X, unqualifyType(T), 
               allowInit(figureInit(X, unqualifyType(T), K)))
          when isNaked(T)
               andBool (K =/=K NoInit)
          [structural] 
          
     syntax K ::= defineAndInit(Id, Type, K) [strict(3)] 
     rule defineAndInit(X:Id, _, initValue(_, T:Type, K:K))
          => giveType(X, T)
          ~> K
          [structural] 

endmodule

