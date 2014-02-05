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

     rule <k> declareInternalVariable(X:Id, T:Type, K:K)
               => allocateType(Loc, T)
               ~> addToEnv(X, Loc)
               ~> initLocalStatic(X, unqualifyType(T), 
                    figureInit(X, unqualifyType(T), K))
          ...</k>
          <current-block> BlockNum:Int </current-block>
          <currTU> TU:String </currTU>
          <tu-id> TU </tu-id>
          <next-static-loc> Loc:SymLoc => linc(Loc) </next-static-loc>
          <local-statics>
               LocalStatics:Map (.Map =>  kpair(X, BlockNum) |-> Loc)
          </local-statics>
          when isStaticType(T)
               andBool (notBool isExternType(T))
               andBool (notBool kpair(X, BlockNum) in keys LocalStatics)
          [structural] 

     syntax K ::= initLocalStatic(Id, Type, K) [strict(3)] 
     rule <k> initLocalStatic(X:Id, _, initValue(_, T:Type, K:K))
               => giveType(X, T)
               ~> zero(X)
               ~> K
          ...</k>
          <current-block> BlockNum:Int </current-block>
          <currTU> TU:String </currTU>
          <tu-id> TU </tu-id>
          <local-types>
               LocalStaticsTypes:Map (.Map =>  kpair(X, BlockNum) |-> T)
          </local-types>
          when notBool kpair(X, BlockNum) in keys LocalStaticsTypes
          [structural] 

     rule declareInternalVariable(X:Id, T:Type, NoInit)
          => addToEnv(X, symVal)
          ~> giveType(X, unqualifyType(T))
          when isNaked(T)
          [structural] 

     rule declareInternalVariable(X:Id, T:Type, K:K)
          => addToEnv(X, symVal)
          ~> defineAndInit(X, unqualifyType(T), 
               figureInit(X, unqualifyType(T), K))
          when isNaked(T)
               andBool (K =/=K NoInit)
          [structural] 
          
     syntax K ::= defineAndInit(Id, Type, K) [strict(3)] 
     rule defineAndInit(X:Id, _, initValue(_, T:Type, K:K))
          => giveType(X, T)
          ~> K
          [structural] 

endmodule

