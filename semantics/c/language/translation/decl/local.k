module C-DECL-LOCAL
     imports C-CONFIGURATION
     imports BASIC-K
     imports BOOL
     imports STRING
     imports COMPAT-SYNTAX
     imports C-ABSTRACT-SYNTAX
     imports C-DECL-GLOBAL-SYNTAX
     imports C-DECL-INITIALIZER-SYNTAX
     imports C-DYNAMIC-SYNTAX
     imports C-ELABORATOR-SYNTAX
     imports C-ENV-SYNTAX
     imports C-ERROR-SYNTAX
     imports C-MEMORY-ALLOC-SYNTAX
     imports C-SYMLOC-SYNTAX
     imports C-SYNTAX
     imports C-TYPING-COMMON-SYNTAX
     imports C-TYPING-COMPATIBILITY-SYNTAX
     imports C-TYPING-SYNTAX

     // TODO(chathhorn): Totally not sure what to do about these first cases.
     // Should the external types be updated/completed? That appears to be the
     // case according to 6.2.7p4, but does that update only last for the scope
     // of the current block?
     //
     // Extern, external type and def exist.
     rule <k> declareInternalVariable(X:CId, T':Type, _:NoInit)
               => addToEnv(X, T, Base)
          ...</k>
          <elab>... .K => declareInternalVariable(X, T', NoInit()) </elab>
          <types> M:Map => M[X <- T] </types>
          <external-types>... X |-> T:Type ...</external-types>
          <external-defs>... X |-> Base:SymBase ...</external-defs>
          <curr-tu> TU:String </curr-tu>
          <tu-id> TU </tu-id>
          <local-types> LocalTypes:Set </local-types>
          requires (isFunctionType(T') orBool isExternType(T'))
               andBool notBool isStaticType(T')
               andBool areDeclCompat(T, T')
               andBool notBool (X in LocalTypes)
               andBool (notBool isAutoType(T'))
          [structural]
     // Extern, external type exists but no def.
     rule <k> declareInternalVariable(X:CId, T':Type, _:NoInit)
               => giveType(X, T)
          ...</k>
          <elab>... .K => declareInternalVariable(X, T', NoInit()) </elab>
          <external-types>... X |-> T:Type ...</external-types>
          <external-defs> Defs:Map </external-defs>
          <curr-tu> TU:String </curr-tu>
          <tu-id> TU </tu-id>
          <local-types> LocalTypes:Set </local-types>
          requires (isFunctionType(T') orBool isExternType(T'))
               andBool notBool isStaticType(T')
               andBool areDeclCompat(T, T')
               andBool notBool (X in_keys(Defs))
               andBool notBool (X in LocalTypes)
               andBool (notBool isAutoType(T'))
          [structural]
     // Extern, external type does not exist.
     rule <k> declareInternalVariable(X:CId, T:Type, _:NoInit)
               => addToEnv(X, T, nonStatic)
               ~> giveType(X, T)
          ...</k>
          <elab>... .K => declareInternalVariable(X, T, NoInit()) </elab>
          <external-types> Types:Map </external-types>
          <curr-tu> TU:String </curr-tu>
          <tu-id> TU </tu-id>
          <local-types> LocalTypes:Set </local-types>
          requires (isFunctionType(T) orBool isExternType(T))
               andBool notBool isStaticType(T)
               andBool notBool (X in_keys(Types))
               andBool notBool (X in LocalTypes)
               andBool (notBool isAutoType(T))
          [structural]
     rule <k> declareInternalVariable(X:CId, T:Type, Init:KResult)
               => initLocalStatic(X, toInitValue(X, T, Init))
          ...</k>
          <elab>... .K => declareInternalVariable(X, T, NoInit()) </elab>
          requires isStaticType(T)
               andBool (notBool isExternType(T))
               andBool (notBool isFunctionType(T))
               andBool (notBool isAutoType(T))
          [structural]
     rule <k> declareInternalVariable(X:CId, T:Type, Init:KResult)
               => defineAndInit(X, T, toInitValue(X, T, Init))
          ...</k>
          <elab>... .K => declareInternalVariable(X, T, Init) </elab>
          requires isNaked(T)
               andBool (notBool isAutoType(T))
          [structural]
     rule declareInternalVariable(_, t(_, _, auto-type) => T, initValue(_, T::Type, _))
          [structural]
     // We don't give local extern decls an entry in the "local-types" map in
     // order to detect this case.
     rule <k> (.K => CV("TDL1", "Extern declaration of "
                    +String showCId(X) +String " follows one with no linkage."))
               ~> declareInternalVariable(X:CId, T:Type, _:NoInit)
          ...</k>
          <curr-tu> TU:String </curr-tu>
          <tu-id> TU </tu-id>
          <local-types>... SetItem(X) ...</local-types>
          requires isExternType(T) andBool notBool isStaticType(T)
          [structural]
     rule (.K => CV("TDL2", "Extern declaration of " +String showCId(X)
               +String " appears at block scope with an initializer."))
          ~> declareInternalVariable(X:CId, T:Type, K:KResult)
          requires isExternType(T) andBool notBool isNoInit(K)
          [structural]
     rule <k> (.K => CV("TDL3", "Extern declaration of " +String showCId(X)
                    +String " with incompatible type."))
               ~> declareInternalVariable(X:CId, T':Type, _:NoInit)
          ...</k>
          <external-types>... X |-> T:Type ...</external-types>
          requires (isFunctionType(T') orBool isExternType(T'))
               andBool notBool isStaticType(T')
               andBool notBool areDeclCompat(T, T')
          [structural]

     syntax K ::= toInitValue(CId, Type, K) [function]
     rule toInitValue(X:CId, T:Type, NoInit()) => initValue(X, T, .K)
     rule toInitValue(_, _, Init:K) => Init [owise]

     syntax KItem ::= initLocalStatic(CId, K)
     rule <k> initLocalStatic(X:CId, initValue(_, T:Type, Init:K))
               => allocObject(bnew(!I:Int, T, static(TU)), T)
               ~> addToEnv(X, T, bnew(!I, T, static(TU)))
               ~> giveType(X, T)
               ~> Init
          ...</k>
          <curr-scope> S:Scope </curr-scope>
          <curr-tu> TU:String </curr-tu>
          <tu-id> TU </tu-id>
          <local-statics>
               LocalStatics:Map (.Map =>  kpair(X, S) |-> kpair(bnew(!I, T, static(TU)), T))
          </local-statics>
          <local-types>
               LocalTypes:Set (.Set => SetItem(X))
          </local-types>
          requires notBool ((kpair(X, S) in_keys(LocalStatics))
               orBool (X in LocalTypes))
          [structural]
     rule <k> (.K => CV("TDL4","Redeclaration of " +String showCId(X)
                    +String " with no linkage."))
               ~> initLocalStatic(X:CId, _)
          ...</k>
          <curr-scope> S:Scope </curr-scope>
          <curr-tu> TU:String </curr-tu>
          <tu-id> TU </tu-id>
          <local-statics>
               LocalStatics:Map
          </local-statics>
          <local-types>
               LocalTypes:Set
          </local-types>
          requires (kpair(X, S) in_keys(LocalStatics))
               orBool (X in LocalTypes)
          [structural]

     syntax KItem ::= defineAndInit(CId, Type, K)
     syntax KItem ::= addLocalToFunction(Type)
     rule <k> addLocalToFunction(T:Type) => .K ...</k>
          <curr-scope> S:Scope </curr-scope>
          requires notBool isBlockScope(S)
     rule <k> addLocalToFunction(T:Type) => .K ...</k>
          <curr-scope> S:BlockScope </curr-scope>
          <curr-function> Base:SymBase </curr-function>
          <functions>... Base |-> functionObject(... locals: (_:List (.List => ListItem(T)))) ...</functions>

     rule <k> defineAndInit(X:CId, _, initValue(_, T:Type, _))
               => addToEnv(X, T, nonStatic)
               ~> giveType(X, T)
               ~> addLocalToFunction(T)
          ...</k>
          <curr-tu> Tu:String </curr-tu>
          <tu-id> Tu </tu-id>
          <local-types>
               // local-types is just a flag in this case.
               LocalTypes:Set => SetItem(X) LocalTypes
          </local-types>
          requires isCompleteType(T)
               andBool notBool (X in LocalTypes)
          [structural]
     rule (.K => UNDEF("TDL5",
               "Declaration of an identifier for an object with no linkage and incomplete type."))
          ~> defineAndInit(_, _, initValue(_, T:Type, _))
          requires notBool isCompleteType(T)
          [structural]
     rule <k> (.K => CV("TDL4","Redeclaration of " +String showCId(X)
                    +String " with no linkage."))
               ~> defineAndInit(X:CId, _, initValue(_, T:Type, _))
          ...</k>
          <local-types> LocalTypes:Set </local-types>
          requires isCompleteType(T) andBool (X in LocalTypes)
          [structural]

endmodule

