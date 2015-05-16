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
          <elab>... .K => declareInternalVariable(X, T', NoInit) </elab>
          <types> M:Map => M[X <- T] </types>
          <external-types>... X |-> T:Type ...</external-types>
          <external-defs>... X |-> Base:SymBase ...</external-defs>
          <block-history> ListItem(BlockNum:Int) ...</block-history>
          <curr-tu> TU:String </curr-tu>
          <tu-id> TU </tu-id>
          <local-types> LocalTypes:Map </local-types>
          requires (isFunctionType(T') orBool isExternType(T'))
               andBool notBool isStaticType(T')
               andBool areCompatible(T, T')
               andBool notBool (kpair(X, BlockNum) in keys(LocalTypes))
          [structural]
     // Extern, external type exists but no def.
     rule <k> declareInternalVariable(X:CId, T':Type, NoInit)
               => addToEnv(X, symVal)
          ...</k>
          <elab>... .K => declareInternalVariable(X, T', NoInit) </elab>
          <types> M:Map => M[X <- T] </types>
          <external-types>... X |-> T:Type ...</external-types>
          <external-defs> Defs:Map </external-defs>
          <block-history> ListItem(BlockNum:Int) ...</block-history>
          <curr-tu> TU:String </curr-tu>
          <tu-id> TU </tu-id>
          <local-types> LocalTypes:Map </local-types>
          requires (isFunctionType(T') orBool isExternType(T'))
               andBool notBool isStaticType(T')
               andBool areCompatible(T, T')
               andBool notBool (X in keys(Defs))
               andBool notBool (kpair(X, BlockNum) in keys(LocalTypes))
          [structural]
     // Extern, external type does not exist.
     rule <k> declareInternalVariable(X:CId, T:Type, NoInit)
               => addToEnv(X, symVal)
          ...</k>
          <elab>... .K => declareInternalVariable(X, T, NoInit) </elab>
          <types> M:Map => M[X <- T] </types>
          <external-types> Types:Map </external-types>
          <block-history> ListItem(BlockNum:Int) ...</block-history>
          <curr-tu> TU:String </curr-tu>
          <tu-id> TU </tu-id>
          <local-types> LocalTypes:Map </local-types>
          requires (isFunctionType(T) orBool isExternType(T))
               andBool notBool isStaticType(T)
               andBool notBool (X in keys(Types))
               andBool notBool (kpair(X, BlockNum) in keys(LocalTypes))
          [structural]
     rule <k> declareInternalVariable(X:CId, T:Type, Init:KResult)
               => initLocalStatic(X, toInitValue(X, T, Init))
          ...</k>
          <elab>... .K => declareInternalVariable(X, T, Init) </elab>
          requires isStaticType(T)
               andBool (notBool isExternType(T))
               andBool (notBool isFunctionType(T))
          [structural]
     rule <k> declareInternalVariable(X:CId, T:Type, Init:KResult)
               => addToEnv(X, symVal)
               ~> defineAndInit(X, T, toInitValue(X, T, Init))
          ...</k>
          <elab>... .K => declareInternalVariable(X, T, Init) </elab>
          requires isNaked(T)
          [structural]
     // This is pretty contrived, but we don't give local extern decls an entry
     // in the "local-types" map in order to detect this case.
     rule <k> (.K => CV("TDL1", "Extern declaration of "
                    +String idToString(X) +String " follows one with no linkage.", "6.7:3"))
               ~> declareInternalVariable(X:CId, T:Type, NoInit)
          ...</k>
          <block-history> ListItem(BlockNum:Int) ...</block-history>
          <curr-tu> TU:String </curr-tu>
          <tu-id> TU </tu-id>
          <local-types>... kpair(X, BlockNum) |-> _ ...</local-types>
          requires isExternType(T) andBool notBool isStaticType(T)
          [structural]
     rule (.K => CV("TDL2", "Extern declaration of " +String idToString(X)
               +String " appears at block scope with an initializer.", "6.7.9:5"))
          ~> declareInternalVariable(X:CId, T:Type, K:K)
          requires isExternType(T) andBool K =/=K NoInit
          [structural]
     rule <k> (.K => CV("TDL3", "Extern declaration of " +String idToString(X)
                    +String " with incompatible type.", "6.7:4"))
               ~> declareInternalVariable(X:CId, T':Type, NoInit)
          ...</k>
          <external-types>... X |-> T:Type ...</external-types>
          requires (isFunctionType(T') orBool isExternType(T'))
               andBool notBool isStaticType(T')
               andBool notBool areCompatible(T, T')
          [structural]

     syntax KResult ::= toInitValue(CId, Type, K) [function]
     rule toInitValue(X:CId, T:Type, NoInit) => initValue(X, T, .K)
     rule toInitValue(_, _, Init:K) => Init [owise]

     syntax KItem ::= initLocalStatic(CId, K)
     rule <k> initLocalStatic(X:CId, initValue(_, T:Type, _))
               => allocObject(Base, T)
               ~> addToEnv(X, Base)
               ~> giveType(X, T)
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
          requires notBool (kpair(X, BlockNum) in keys(LocalStatics))
               andBool notBool (kpair(X, BlockNum) in keys(LocalTypes))
     rule <k> (.K => CV("TDL4","redeclaration of " +String idToString(X)
                    +String " with no linkage.", "6.7:3"))
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
          requires (kpair(X, BlockNum) in keys(LocalStatics))
               orBool (kpair(X, BlockNum) in keys(LocalTypes))
          [structural]

     syntax KItem ::= defineAndInit(CId, Type, K)
     rule <k> defineAndInit(X:CId, _, initValue(_, T:Type, _))
               => giveType(X, T)
          ...</k>
          <block-history> ListItem(BlockNum:Int) ...</block-history>
          <curr-tu> Tu:String </curr-tu>
          <tu-id> Tu </tu-id>
          <local-types>
               // TODO(chathhorn): local-types is just a flag in this case.
               LocalTypes:Map => LocalTypes[kpair(X, BlockNum) <- .K]
          </local-types>
          requires isCompleteType(T)
          [structural]
     // Only function prototype scope?
     rule <k> defineAndInit(X:CId, _, initValue(_, T:Type, .K))
               => giveType(X, T)
          ...</k>
          <block-history> .List </block-history>
          requires isCompleteType(T)
          [structural]
     rule (.K => UNDEF("TDL5",
               "declaration of an identifier for an object with no linkage and incomplete type.",
               "6.7:7"))
          ~> defineAndInit(_, _, initValue(_, T:Type, _))
          requires notBool isCompleteType(T)
          [structural]

     rule <k> addLocalTag(X:CId, Info:FieldInfo) => .K ...</k>
          <structs> Structs:Map => Structs[local(X, Tu, BlockNum) <- Info] </structs>
          <curr-tu> Tu:String </curr-tu>
          <block-history> ListItem(BlockNum:Int) ...</block-history>
          requires notBool (X in keys(Structs))
          [structural]
     rule <k> (.K => CV("TDL6", "redefinition of a struct, union, or enum: "
               +String idToString(X), "6.7.2.3:1"))
               ~> addLocalTag(X:CId, _)
          ...</k>
          <structs>... X |-> _ ...</structs>
          [structural]
endmodule

