module C-DECL-LOCAL
     imports C-DECL-DEFINITION-SYNTAX
     imports C-DECL-GLOBAL-SYNTAX
     imports C-DECL-INITIALIZER-SYNTAX
     imports C-DECL-TAGGED-SYNTAX
     imports C-ENV-SYNTAX
     imports C-ERROR-SYNTAX
     imports C-MEMORY-ALLOC-SYNTAX
     imports C-SYMBOLIC-VALUE-SYNTAX
     imports C-SYMLOC-SYNTAX
     imports C-SYNTAX
     imports C-TYPING-COMPATIBILITY-SYNTAX
     imports C-TYPING-SYNTAX

     imports COMPAT-SYNTAX

     // TODO(chathhorn): Totally not sure what to do about these first cases.
     // Should the external types be updated/completed? That appears to be the
     // case according to 6.2.7p4, but does that update only last for the scope
     // of the current block?
     //
     // Extern, external type and def exist.
     rule <k> declareInternalVariable(X:CId, T':Type, NoInit)
               => addToEnv(X, Base)
          ...</k>
          <types> M:Map => M[T <- X] </types>
          <external-types>... X |-> T:Type ...</external-types>
          <external-defs>... X |-> Base:SymBase ...</external-defs>
          <block-history> ListItem(BlockNum:Int) ...</block-history>
          <curr-tu> TU:String </curr-tu>
          <tu-id> TU </tu-id>
          <local-types> LocalTypes:Map </local-types>
          when (isFunctionType(T') orBool isExternType(T'))
               andBool notBool isStaticType(T')
               andBool areCompatible(T, T')
               andBool notBool (kpair(X, BlockNum) in keys(LocalTypes))
          [structural]
     // Extern, external type exists but no def.
     rule <k> declareInternalVariable(X:CId, T':Type, NoInit)
               => addToEnv(X, symVal)
          ...</k>
          <types> M:Map => M[T <- X] </types>
          <external-types>... X |-> T:Type ...</external-types>
          <external-defs> Defs:Map </external-defs>
          <block-history> ListItem(BlockNum:Int) ...</block-history>
          <curr-tu> TU:String </curr-tu>
          <tu-id> TU </tu-id>
          <local-types> LocalTypes:Map </local-types>
          when (isFunctionType(T') orBool isExternType(T'))
               andBool notBool isStaticType(T')
               andBool areCompatible(T, T')
               andBool notBool (X in keys(Defs))
               andBool notBool (kpair(X, BlockNum) in keys(LocalTypes))
          [structural]
     // Extern, external type does not exist.
     rule <k> declareInternalVariable(X:CId, T:Type, NoInit)
               => addToEnv(X, symVal)
          ...</k>
          <types> M:Map => M[T <- X] </types>
          <external-types> Types:Map </external-types>
          <block-history> ListItem(BlockNum:Int) ...</block-history>
          <curr-tu> TU:String </curr-tu>
          <tu-id> TU </tu-id>
          <local-types> LocalTypes:Map </local-types>
          when (isFunctionType(T) orBool isExternType(T))
               andBool notBool isStaticType(T)
               andBool notBool (X in keys(Types))
               andBool notBool (kpair(X, BlockNum) in keys(LocalTypes))
          [structural]
     rule declareInternalVariable(X:CId, T:Type, K:K)
          => initLocalStatic(X,
               // Need the allowInit here to enable storing compound literals
               // and again below to enable storing the value of this declared
               // variable into the actual static memory.
               allowInit(figureInit(X, T, K)))
          when isStaticType(T)
               andBool (notBool isExternType(T))
               andBool (notBool isFunctionType(T))
          [structural]
     rule declareInternalVariable(X:CId, T:Type, K:K)
          => addToEnv(X, symVal)
          ~> defineAndInit(X, T, figureInit(X, T, K))
          when isNaked(T)
          [structural]
     // This is pretty contrived, but we don't give local extern decls an entry
     // in the "local-types" map in order to detect this case.
     rule <k> (.K => ERROR("TDL1", "Extern declaration of "
                    +String idToString(X) +String " follows one with no linkage."))
               ~> declareInternalVariable(X:CId, T:Type, NoInit)
          ...</k>
          <block-history> ListItem(BlockNum:Int) ...</block-history>
          <curr-tu> TU:String </curr-tu>
          <tu-id> TU </tu-id>
          <local-types>... kpair(X, BlockNum) |-> _ ...</local-types>
          when isExternType(T) andBool notBool isStaticType(T)
          [structural]
     rule (. => ERROR("TDL2", "Extern declaration of " +String idToString(X)
               +String " appears at block scope with an initializer."))
          ~> declareInternalVariable(X:CId, T:Type, K:K)
          when isExternType(T) andBool K =/=K NoInit
          [structural]
     rule <k> (. => ERROR("TDL3", "Extern declaration of " +String idToString(X)
                    +String " with incompatible type."))
               ~> declareInternalVariable(X:CId, T':Type, NoInit)
          ...</k>
          <external-types>... X |-> T:Type ...</external-types>
          when (isFunctionType(T') orBool isExternType(T'))
               andBool notBool isStaticType(T')
               andBool notBool areCompatible(T, T')
          [structural]

     syntax K ::= initLocalStatic(CId, K) [strict(2)]
     rule <k> initLocalStatic(X:CId, initValue(_, T:Type, K:K))
               => allocObject(Base, T)
               ~> addToEnv(X, Base)
               ~> giveType(X, T)
               ~> allowInit(K)
          ...</k>
          <block-history> ListItem(BlockNum:Int) ...</block-history>
          <curr-tu> TU:String </curr-tu>
          <tu-id> TU </tu-id>
          <next-static-loc> Base:SymBase => linc(Base) </next-static-loc>
          <local-statics>
               LocalStatics:Map (.Map =>  kpair(X, BlockNum) |-> Base)
          </local-statics>
          <local-types>
               LocalTypes:Map (.Map =>  kpair(X, BlockNum) |-> T)
          </local-types>
          when notBool (kpair(X, BlockNum) in keys(LocalStatics))
               andBool notBool (kpair(X, BlockNum) in keys(LocalTypes))
          [structural]
     rule <k> (.K => ERROR("TDL4","redeclaration of " +String idToString(X)
                    +String " with no linkage."))
               ~> initLocalStatic(X:CId, _)
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
          when (kpair(X, BlockNum) in keys(LocalStatics))
               orBool (kpair(X, BlockNum) in keys(LocalTypes))
          [structural]

     syntax K ::= defineAndInit(CId, Type, K) [strict(3)]
     rule <k> defineAndInit(X:CId, _, initValue(_, T:Type, K:K))
               => giveType(X, T)
               // Needed because we still need to process the initializers and
               // we also need to disable e.g. const checks during init.
               ~> allowInit(K)
          ...</k>
          <block-history> ListItem(BlockNum:Int) ...</block-history>
          <curr-tu> Tu:String </curr-tu>
          <tu-id> Tu </tu-id>
          <local-types>
               // TODO(chathhorn): local-types is just a flag in this case.
               LocalTypes:Map => LocalTypes[.K <- kpair(X, BlockNum)]
          </local-types>
          when isCompleteType(T)
          [structural]
     // Only function prototype scope?
     rule <k> defineAndInit(X:CId, _, initValue(_, T:Type, .K))
               => giveType(X, T)
          ...</k>
          <block-history> .List </block-history>
          when isCompleteType(T)
          [structural]
     rule (. => UNDEF("TDL5",
               "declaration of an identifier for an object with no linkage and incomplete type.",
               "6.7:7"))
          ~> defineAndInit(_, _, initValue(_, T:Type, _))
          when notBool isCompleteType(T)
          [structural]

     rule <k> addLocalTag(X:CId, Info:FieldInfo) => . ...</k>
          <structs> Structs:Map => Structs[Info <- X] </structs>
          when notBool (X in keys(Structs))
          [structural]
     rule <k> (. => CV("TDL6", "redefinition of a struct, union, or enum: "
               +String idToString(X), "6.7.2.3:1"))
               ~> addLocalTag(X:CId, _)
          ...</k>
          <structs>... X |-> _ ...</structs>
          [structural]
endmodule

