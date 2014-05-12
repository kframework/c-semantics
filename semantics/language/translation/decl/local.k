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
     imports C-ERROR-SYNTAX
     imports C-SYMLOC-SYNTAX
     imports C-MEMORY-ALLOC-SYNTAX
     imports COMPAT-SYNTAX

     // TODO(chathhorn): note that execution/declaration/local.k starts from
     // doDeclare, not declareInternalVariable.

     // TODO(chathhorn): Totally not sure what to do about these first cases.
     // Should the external types be updated/completed?
     // Extern, external type and def exist.
     rule <k> declareInternalVariable(X:Id, T':Type, NoInit) 
               => addToEnv(X, Loc)
          ...</k>
          <types> M:Map => M:Map[T / X] </types>
          <external-types>... X |-> T:Type ...</external-types>
          <external-defs>... X |-> Loc:SymLoc ...</external-defs>
          <block-history> ListItem(BlockNum:Int) ...</block-history>
          <curr-tu> TU:String </curr-tu>
          <tu-id> TU </tu-id>
          <local-types> LocalTypes:Map </local-types>
          when (isFunctionType(T') orBool isExternType(T'))
               andBool notBool isStaticType(T')
               andBool isTypeCompatible(T, T')
               andBool notBool (kpair(X, BlockNum) in keys LocalTypes)
          [structural] 
     // Extern, external type exists but no def.
     rule <k> declareInternalVariable(X:Id, T':Type, NoInit) 
               => addToEnv(X, symVal)
          ...</k>
          <types> M:Map => M:Map[T / X] </types>
          <external-types>... X |-> T:Type ...</external-types>
          <external-defs> Defs:Map </external-defs>
          <block-history> ListItem(BlockNum:Int) ...</block-history>
          <curr-tu> TU:String </curr-tu>
          <tu-id> TU </tu-id>
          <local-types> LocalTypes:Map </local-types>
          when (isFunctionType(T') orBool isExternType(T'))
               andBool notBool isStaticType(T')
               andBool isTypeCompatible(T, T')
               andBool notBool (X in keys Defs)
               andBool notBool (kpair(X, BlockNum) in keys LocalTypes)
          [structural] 
     // Extern, external type does not exist.
     rule <k> declareInternalVariable(X:Id, T:Type, NoInit) 
               => addToEnv(X, symVal)
          ...</k>
          <types> M:Map => M:Map[T / X] </types>
          <external-types> Types:Map </external-types>
          <block-history> ListItem(BlockNum:Int) ...</block-history>
          <curr-tu> TU:String </curr-tu>
          <tu-id> TU </tu-id>
          <local-types> LocalTypes:Map </local-types>
          when (isFunctionType(T) orBool isExternType(T))
               andBool notBool isStaticType(T)
               andBool notBool (X in keys Types)
               andBool notBool (kpair(X, BlockNum) in keys LocalTypes)
          [structural] 
     // This is pretty contrived, but we don't give local extern decls an entry
     // in the "local-types" map in order to detect this case.
     rule <k> (.K => ERROR("DL1", "Extern declaration of "
                    +String idToString(X) +String " follows one with no linkage."))
               ~> declareInternalVariable(X:Id, T:Type, NoInit) 
          ...</k>
          <block-history> ListItem(BlockNum:Int) ...</block-history>
          <curr-tu> TU:String </curr-tu>
          <tu-id> TU </tu-id>
          <local-types>... kpair(X, BlockNum) |-> _ ...</local-types>
          when isExternType(T) andBool notBool isStaticType(T)
          [structural] 

     rule declareInternalVariable(X:Id, T:Type, K:K)
          => checkComplete(X, T, K)
          ~> initLocalStatic(X,
               allowInit(figureInit(X, stripStorageSpecifiers(T), K)))
          when isStaticType(T)
               andBool (notBool isExternType(T))
               andBool (notBool isFunctionType(T))
          [structural] 

     rule declareInternalVariable(X:Id, T:Type, K:K)
          => checkComplete(X, T, K)
          ~> addToEnv(X, symVal)
          ~> defineAndInit(X, stripStorageSpecifiers(T), 
               allowInit(figureInit(X, stripStorageSpecifiers(T), K)))
          when isNaked(T)
          [structural] 

     syntax K ::= initLocalStatic(Id, K) [strict(2)] 
     rule <k> initLocalStatic(X:Id, initValue(_, T:Type, K:K))
               => allocateType(Loc, T)
               ~> addToEnv(X, Loc)
               ~> giveType(X, T)
               ~> allowInit(zero(X) ~> K)
          ...</k>
          <block-history> ListItem(BlockNum:Int) ...</block-history>
          <curr-tu> TU:String </curr-tu>
          <tu-id> TU </tu-id>
          <next-static-loc> Loc:SymLoc => linc(Loc) </next-static-loc>
          <local-statics>
               LocalStatics:Map (.Map =>  kpair(X, BlockNum) |-> Loc)
          </local-statics>
          <local-types>
               LocalTypes:Map (.Map =>  kpair(X, BlockNum) |-> T)
          </local-types>
          when notBool (kpair(X, BlockNum) in keys LocalStatics)
               andBool notBool (kpair(X, BlockNum) in keys LocalTypes)
          [structural] 
     rule <k> (.K => ERROR("DL4","Redeclaration of " +String idToString(X)
                    +String " with no linkage."))
               ~> initLocalStatic(X:Id, _)
          ...</k>
          <block-history> ListItem(BlockNum:Int) ...</block-history>
          <curr-tu> TU:String </curr-tu>
          <tu-id> TU </tu-id>
          <local-statics>
               LocalStatics:Map
          </local-statics>
          <local-types>
               LocalTypes:Map
          </local-types>
          when (kpair(X, BlockNum) in keys LocalStatics)
               orBool (kpair(X, BlockNum) in keys LocalTypes)
          [structural] 
          
     syntax K ::= defineAndInit(Id, Type, K) [strict(3)] 
     rule <k> defineAndInit(X:Id, _, initValue(_, T:Type, K:K))
               => giveType(X, T)
               ~> K
          ...</k>
          <block-history> ListItem(BlockNum:Int) ...</block-history>
          <curr-tu> Tu:String </curr-tu>
          <tu-id> Tu </tu-id>
          <local-types>
               // TODO(chathhorn): local-types is just a flag in this case.
               LocalTypes:Map => LocalTypes:Map[.K / kpair(X, BlockNum)]
          </local-types>
          [structural] 
     // For function parameters. TODO(chathhorn): handle better?
     rule <k> defineAndInit(X:Id, _, initValue(_, T:Type, K:K))
               => giveType(X, T)
               ~> K
          ...</k>
          <block-history> .List </block-history>
          <curr-tu> Tu:String </curr-tu>
          <tu-id> Tu </tu-id>
          <local-types>
               LocalTypes:Map => LocalTypes:Map[.K / kpair(X, 0)]
          </local-types>
          [structural] 

endmodule

