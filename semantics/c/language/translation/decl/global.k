module C-DECL-GLOBAL-SYNTAX
     imports C-TYPING-SORTS
     imports SYMLOC-SORTS

     syntax Linkage ::= "external" | "internal"

     syntax Bool ::= isNaked(Type) [function]

     syntax DeclState ::= "declared" | "completed"
                        | "allocated" | "initialized"

     // The last bool argument indicates whether a tentative def has been
     // encountered. This is only relevant in the case of symbols with external
     // linkage, which must then be completed and allocated at the end of
     // processing the TU if a tentative def exists and the type is still
     // incomplete.
     syntax KItem ::= declState(SymBase, Type, DeclState, Bool)

endmodule

module C-DECL-GLOBAL
     imports C-DECL-GLOBAL-SYNTAX
     imports C-CONFIGURATION
     imports BOOL
     imports K-EQUAL
     imports LIST
     imports MAP
     imports SET
     imports STRING
     imports COMMON-SORTS
     imports COMPAT-SYNTAX
     imports C-ABSTRACT-SYNTAX
     imports C-DECL-DEFINITION-SYNTAX
     imports C-DECL-INITIALIZER-SYNTAX
     imports C-DECL-TAGGED-SYNTAX
     imports C-DYNAMIC-SYNTAX
     imports C-ELABORATOR-SYNTAX
     imports C-ENV-SYNTAX
     imports C-ERROR-SYNTAX
     imports C-MEMORY-ALLOC-SYNTAX
     imports C-SYMLOC-SYNTAX
     imports C-SYNTAX
     imports C-TYPING-COMPATIBILITY-SYNTAX
     imports C-TYPING-SYNTAX

     rule declare'(typedDeclaration(T:Type, X:CId), K:K)
          => checkComplete(T, K)
          ~> declare''(T, X, K)

     syntax KItem ::= "declare''" "(" Type "," CId "," K ")"

     // Block scope declarations.
     rule <k> declare''(T::Type, X:CId, K:K)
               => addToEnv(X, T, nonStatic)
               ~> declareInternalVariable(X, T, figureInit(X, T, K))
          ...</k>
          <curr-scope> _:BlockScope </curr-scope>
          requires notBool isFunctionType(T)
               andBool validLocalStorageClass(T)
          [structural]
     rule <k> declare''(t(... st: functionType(...)) #as T::Type, X:CId, K:K)
               => declareInternalVariable(X, T, figureInit(X, T, K))
          ...</k>
          <curr-scope> _:BlockScope </curr-scope>
          requires validLocalStorageClass(T)
               andBool (getQualifiers(T) ==K noQuals)
          [structural]

     // Prototype scope declarations (includes both params in prototypes as
     // well as function defs).
     rule <k> declare''(T::Type, X:CId, NoInit())
               => declareInternalVariable(X, T, NoInit())
          ...</k>
          <curr-scope> prototypeScope </curr-scope>
          requires validPrototypeStorageClass(T)
               andBool notBool isVoidType(T)
               andBool (X =/=K #NoName)
          [structural]
     rule <k> declare''(T::Type, #NoName, NoInit()) => .K ...</k>
          <curr-scope> prototypeScope </curr-scope>
          requires validPrototypeStorageClass(T)
               andBool notBool isVoidType(T)
          [structural]
     rule <k> declare''(t(... st: void) #as T::Type, #NoName, NoInit()) => .K ...</k>
          <curr-scope> prototypeScope </curr-scope>
          requires (getStorageSpecifiers(T) ==K .Set)
               andBool (getQualifiers(T) ==K noQuals)
          [structural]

     // File scope declarations.
     rule <k> declare''(t(... st: functionType(...)) #as T::Type, X:CId, K:K)
               => declareExternalVariable(X, T,
                    #if isNoInit(K)
                    #then NoInit()
                    #else CodeLoc(K, L) #fi)
          ...</k>
          <curr-scope> fileScope </curr-scope>
          <curr-program-loc> L:CabsLoc </curr-program-loc>
          requires validGlobalStorageClass(T)
               andBool (getQualifiers(T) ==K noQuals)
          [structural]
     rule <k> declare''(T::Type, X:CId, K:K)
               => declareExternalVariable(X, T,
                    #if isNoInit(K)
                    #then NoInit()
                    #else CodeLoc(K, L) #fi)
          ...</k>
          <curr-scope> fileScope </curr-scope>
          <curr-program-loc> L:CabsLoc </curr-program-loc>
          requires notBool isFunctionType(T)
               andBool validGlobalStorageClass(T)
               andBool notBool isVariablyModifiedType(T)
          [structural]

     rule (.K => UNDEF("TDG1",
               "Declaration for the function " +String showCId(X) +String
               " appears with type qualifiers."))
          ~> declare''(t(... st: functionType(...)) #as T::Type, X:CId, _)
          requires getQualifiers(T) =/=K noQuals
          [structural]

     rule (.K => CV("TDG2",
               "Declaration for " +String showCId(X) +String
               " appears with multiple storage class specifiers."))
          ~> declare''(T::Type, X:CId, _)
          requires notBool validStorageClass(T)
          [structural]

     rule <k> (.K => UNDEF("TDG3",
               "Declaration for " +String showCId(X) +String
               " appears with invalid storage class specifiers."))
               ~> declare''(t(... st: functionType(...)) #as T::Type, X:CId, _)
          ...</k>
          <curr-scope> S:Scope </curr-scope>
          requires S =/=K fileScope
               andBool validStorageClass(T)
               andBool notBool validLocalStorageClass(T)
          [structural]

     rule <k> (.K => CV("TDG18",
               "Declaration for " +String showCId(X) +String
               " appears with invalid storage class specifiers."))
               ~> declare''(T::Type, X:CId, _)
          ...</k>
          <curr-scope> S:Scope </curr-scope>
          requires S =/=K fileScope
               andBool validStorageClass(T)
               andBool notBool validLocalStorageClass(T)
               andBool notBool isFunctionType(T)
          [structural]

     rule <k> (.K => CV("TDG4",
               "Declaration for " +String showCId(X) +String
               " appears with invalid storage class specifiers."))
               ~> declare''(T::Type, X:CId, _)
          ...</k>
          <curr-scope> fileScope </curr-scope>
          requires validStorageClass(T)
               andBool notBool validGlobalStorageClass(T)
          [structural]

     rule <k> (.K => CV("TDG5",
               "Function parameter appears with storage class other than register."))
               ~> declare''(T::Type, _, _)
          ...</k>
          <curr-scope> prototypeScope </curr-scope>
          requires notBool validPrototypeStorageClass(T)
               andBool notBool isVoidType(T)
          [structural]
     rule <k> (.K => UNDEF("TDG6",
               "Void parameter appears with a storage class specifier."))
               ~> declare''(t(... st: void) #as T::Type, _, _)
          ...</k>
          <curr-scope> prototypeScope </curr-scope>
          requires getStorageSpecifiers(T) =/=K .Set
          [structural]
     rule <k> (.K => UNDEF("TDG7",
               "Void parameter appears with qualifiers."))
               ~> declare''(t(... st: void) #as T::Type, _, _)
          ...</k>
          <curr-scope> prototypeScope </curr-scope>
          requires getQualifiers(T) =/=K noQuals
          [structural]

     rule <k> (.K => CV("TDG9",
               "file-scope declaration of " +String showCId(X)
               +String " with a variably-modified type."))
               ~> declare''(T::Type, X:CId, _)
          ...</k>
          <curr-scope> fileScope </curr-scope>
          requires notBool isFunctionType(T) andBool isVariablyModifiedType(T)

     // Checks if the type is complete if there's an initializer.
     syntax KItem ::= checkComplete(Type, K)
     rule checkComplete(T::Type, Init:K) => .K
          requires isNoInit(Init) orBool isCompleteType(T) orBool isArrayType(T)
          [structural]
     rule (.K => CV("TDG8",
               "Declaration has initializer but incomplete type."))
          ~> checkComplete(T:Type, K:K)
          requires notBool (isNoInit(K) orBool isCompleteType(T) orBool isArrayType(T))
          [structural]

     syntax Bool ::= validStorageClass(Type) [function]
                   | "validStorageClass'" "(" Type "," Set ")" [function]
     syntax Bool ::= validGlobalStorageClass(Type) [function]
                   | "validGlobalStorageClass'" "(" Type "," Set ")" [function]
     syntax Bool ::= validLocalStorageClass(Type) [function]
                   | "validLocalStorageClass'" "(" Type "," Set ")" [function]

     syntax Bool ::= validPrototypeStorageClass(Type) [function]

     // TODO(chathhorn): probably cleaner just to check the intersection
     // between the storage class specifiers and the "qualities," but there are
     // some annoying special cases (ThreadLocal & extern/static is legal).
     // Also, consider moving this to type canonicalization.
     rule validStorageClass(T::Type) => validStorageClass'(T, getStorageSpecifiers(T))
     rule validStorageClass'(T::Type, Specs::Set) => notBool (
               ((Static() in Specs) andBool (Extern() in Specs))
               orBool ((Auto() in Specs) andBool (Static() in Specs))
               orBool ((Auto() in Specs) andBool (Extern() in Specs))
               orBool ((Auto() in Specs) andBool (ThreadLocal() in Specs))
               orBool ((Register() in Specs) andBool (Static() in Specs))
               orBool ((Register() in Specs) andBool (Extern() in Specs))
               orBool ((Register() in Specs) andBool (ThreadLocal() in Specs))
          )

     rule validGlobalStorageClass(T::Type)
          => validGlobalStorageClass'(T, getStorageSpecifiers(T))
     rule validGlobalStorageClass'(T::Type, Specs::Set)
          => validStorageClass'(T, Specs)
          andBool notBool (
               (Auto() in Specs)
               orBool (Register() in Specs)
          )

     rule validLocalStorageClass(T::Type)
          => validLocalStorageClass'(T, getStorageSpecifiers(T))
     rule validLocalStorageClass'(T::Type, Specs::Set)
          => validStorageClass'(T, Specs)
          andBool notBool (
               (isFunctionType(T) andBool (Static() in Specs))
               orBool (isFunctionType(T) andBool (ThreadLocal() in Specs))
               orBool (isFunctionType(T) andBool (Auto() in Specs))
               orBool (isFunctionType(T) andBool (Register() in Specs))
               orBool (notBool isFunctionType(T) andBool ThreadLocal() in Specs
                    andBool notBool (Static() in Specs orBool Extern() in Specs))
          )

     rule validPrototypeStorageClass(T::Type)
          => (getStorageSpecifiers(T) ==K SetItem(Register()))
               orBool (getStorageSpecifiers(T) ==K .Set)

     // *** External variables ***
     //
     // The four states of external symbols during translation:
     //
     // declared => completed => allocated => initialized.
     //
     // declared: one or more declaration of the symbol encountered, but always
     // with an incomplete type.
     //
     // completed: a declaration giving a complete type for a symbol has been
     // encountered, but it was qualified extern with no initilizer, and
     // extern-qualified declarations don't cause an allocation unless they
     // have an initializer.
     //
     // allocated: once we have a complete type for a symbol, we can allocate
     // memory as long as we have encountered at least one non-extern
     // declaration of that symbol.
     //
     // initialized: if a declaration includes an initializer, its type must
     // necessarily be complete and we can therefore allocate memory for it. We
     // also need to keep track of the initialzed status in order to prevent
     // multiple initiaizations of the same symbol.
     //

     // That is, no storage class specifier (and not a function).
     rule isNaked(T::Type)
          => notBool (isExternType(T) orBool isStaticType(T))
               andBool notBool isFunctionType(T)

     // Naked function declarations are treated as though they were qualified
     // extern.
     syntax Bool ::= isExtern(Type) [function]
     rule isExtern(T::Type)
          => (isExternType(T) orBool isFunctionType(T))
               andBool notBool isStaticType(T)

     /*@ \fromStandard{\source[n1570]{\para{6.2.2}{4}}}{
     For an identifier declared with the storage-class specifier
     \cinline{extern} in a scope in which a prior declaration of that
     identifier is visible, if the prior declaration specifies internal or
     external linkage, the linkage of the identifier at the later declaration
     is the same as the linkage specified at the prior declaration. If no prior
     declaration is visible, or if the prior declaration specifies no linkage,
     then the identifier has external linkage.
     }*/

     syntax StorageClassSpecifier ::= "Naked"
     syntax KItem ::= declareExternalVariable(CId, Type, K)

     // Static or extern, previously declared static.
     rule <k> declareExternalVariable(X:CId, T::Type, K:K)
               => addToEnv(X, OldT, Base)
               ~> giveType(X, OldT) // Tentative type.
               ~> declareExternalVariable'(isNoInit(K),
                    figureInit(X, T, K),
                    State, internal,
                    #if isExtern(T) #then Extern() #else Static() #fi)
          ...</k>
          <curr-tu> Tu:String </curr-tu>
          <tu-id> Tu </tu-id>
          <externals> Exts:Map </externals>
          <internals>...
               X |-> declState(Base:SymBase, OldT:Type, State:DeclState, _)
          ...</internals>
          requires notBool isNaked(T)
               andBool notBool (X in_keys(Exts))
               andBool areDeclCompat(T, OldT)
          [structural]

     rule <k> (.K => CV("TDG10",
               "Conflicting types for " +String showCId(X) +String "."))
               ~> declareExternalVariable(X:CId, T::Type, _)
          ...</k>
          <curr-tu> Tu:String </curr-tu>
          <tu-id> Tu </tu-id>
          <internals>...
               X |-> declState(_, OldT:Type, _, _)
          ...</internals>
          requires notBool areDeclCompat(T, OldT)
          [structural]

     // Naked, previously declared extern.
     rule <k> declareExternalVariable(X:CId, T::Type, K:K)
               => addToEnv(X, OldT, Base)
               ~> giveType(X, OldT) // Tentative type.
               ~> declareExternalVariable'(isNoInit(K),
                    figureInit(X, T, K),
                    State, external, Naked)
          ...</k>
          <curr-tu> Tu:String </curr-tu>
          <tu-id> Tu </tu-id>
          <externals>...
               X |-> declState(Base:SymBase, OldT:Type, State:DeclState, _)
          ...</externals>
          <internals> Ints:Map </internals>
          requires isNaked(T)
               andBool notBool (X in_keys(Ints))
               andBool areDeclCompat(T, OldT)
          [structural]

     // Extern, previously declared extern.
     rule <k> declareExternalVariable(X:CId, T::Type, K:K)
               => addToEnv(X, OldT, Base)
               ~> giveType(X, OldT) // Tentative type.
               ~> declareExternalVariable'(isNoInit(K),
                    figureInit(X, T, K),
                    State, external, Extern())
          ...</k>
          <curr-tu> Tu:String </curr-tu>
          <tu-id> Tu </tu-id>
          <externals>...
               X |-> declState(Base:SymBase, OldT:Type, State:DeclState, _)
          ...</externals>
          <internals> Ints:Map </internals>
          requires isExtern(T)
               andBool notBool (X in_keys(Ints))
               andBool areDeclCompat(T, OldT)
          [structural]

     rule <k> (.K => CV("TDG10",
               "Conflicting types for " +String showCId(X) +String "."))
               ~> declareExternalVariable(X:CId, T::Type, _)
          ...</k>
          <curr-tu> Tu:String </curr-tu>
          <tu-id> Tu </tu-id>
          <externals>...
               X |-> declState(_, OldT:Type, _, _)
          ...</externals>
          requires notBool areDeclCompat(T, OldT)
          [structural]

     // Naked or extern, not previously declared.
     rule <k> declareExternalVariable(X:CId, T::Type, K:K)
               => addToEnv(X, T, bnew(!I:Int, T, link(Tu)))
               ~> declareExternalVariable'(isNoInit(K),
                    figureInit(X, T, K),
                    declared, external,
                    #if isExtern(T) #then Extern() #else Static() #fi)
          ...</k>
          <curr-tu> Tu:String </curr-tu>
          <tu-id> Tu </tu-id>
          <externals>
               Exts:Map
               (.Map => X |-> declState(bnew(!I, T, link(Tu)), T, declared, false))
          </externals>
          <internals> Ints:Map </internals>
          requires notBool isStaticType(T)
               andBool notBool (X in_keys(Exts))
               andBool notBool (X in_keys(Ints))
          [structural]

     // Static, not previously declared.
     rule <k> declareExternalVariable(X:CId, T::Type, K:K)
               => addToEnv(X, T, bnew(!I:Int, T, static(Tu)))
               ~> declareExternalVariable'(isNoInit(K),
                    figureInit(X, T, K),
                    declared, internal, Static())
          ...</k>
          <curr-tu> Tu:String </curr-tu>
          <tu-id> Tu </tu-id>
          <externals> Exts:Map </externals>
          <internals>
               Ints:Map
               (.Map => X |-> declState(bnew(!I, T, static(Tu)), T, declared, false))
          </internals>
          requires isStaticType(T)
               andBool notBool (X in_keys(Exts))
               andBool notBool (X in_keys(Ints))
          [structural]

     // Static, previously extern.
     rule <k> (.K => UNDEF("TDG11",
               "Static declaration of " +String showCId(X)
               +String " follows non-static declaration."))
               ~> declareExternalVariable(X:CId, T::Type, _)
          ...</k>
          <curr-tu> Tu:String </curr-tu>
          <tu-id> Tu </tu-id>
          <externals> Exts:Map </externals>
          requires isStaticType(T)
               andBool (X in_keys(Exts))
          [structural]

     // Now we just need to handle allocation, initialization, and updating the
     // declState, when necessary. The last argument can be thought of as the
     // "true" storage class specifier of the decl, counting functions as
     // extern. In C18, because extern-qualified declarations can have
     // initializers, the difference between a global extern-qualified
     // declaration and a global naked declaration is very slight: they only
     // differ in the case of declarations without initializers. A naked
     // declaration without an initializer constitutes a tentative definition,
     // but an extern declaration without an initializer does not.
     syntax KItem ::= "declareExternalVariable'" "(" Bool "," KItem "," DeclState "," Linkage "," StorageClassSpecifier ")"
          [strict(2)]

     // *** Incomplete ***

     rule declareExternalVariable'(true, initValue(X:CId, T:Type, .K),
               State:DeclState, Lnk:Linkage, Extern())
          => giveCompositeType(X, T)
          ~> updateDecl(X, Lnk, State)
          requires notBool isCompleteType(T)
          [structural]
     // Tentative definition (with incomplete type).
     rule declareExternalVariable'(true, initValue(X:CId, T:Type, .K),
               State:DeclState, Lnk:Linkage, Sto:StorageClassSpecifier)
          => giveCompositeType(X, T)
          ~> updateDecl(X, Lnk, State)
          ~> recordTentDef(X, Lnk)
          requires notBool isCompleteType(T)
               andBool (Sto ==K Naked
                    orBool (Sto ==K Static() andBool Lnk =/=K internal))
          [structural]
     rule ( .K => UNDEF("TDG12",
               "Declaration for an object is a tentative definition with internal linkage and has an incomplete type."))
          ~> declareExternalVariable'(true, initValue(_, T:Type, .K),
               _, internal, _)
          requires notBool isCompleteType(T)
          [structural]

     // *** Extern, already completed.  ***

     rule declareExternalVariable'(true, initValue(X:CId, T:Type, .K),
               State:DeclState, Lnk:Linkage, Extern())
          => giveCompositeType(X, T)
          ~> updateDecl(X, Lnk, State)
          requires isCompleteType(T)
               andBool State =/=K declared
          [structural]

     // *** Complete, no initializer ***

     // static or naked => tentative def
     // extern => external def

     // Completed type, no init.
     // declared => allocated
     rule declareExternalVariable'(true, initValue(X:CId, T:Type, .K),
               declared, Lnk:Linkage, Sto:StorageClassSpecifier)
          => giveCompositeType(X, T)
          ~> allocateDecl(X)
          ~> updateDecl(X, Lnk, allocated)
          ~> recordTentDef(X, Lnk)
          requires isCompleteType(T)
               andBool Sto =/=K Extern()
          [structural]

     // declared => completed
     rule declareExternalVariable'(true, initValue(X:CId, T:Type, .K),
               declared, Lnk:Linkage, Extern())
          => giveCompositeType(X, T)
          ~> updateDecl(X, Lnk, completed)
          requires isCompleteType(T)
          [structural]

     // Already encountered a completed decl, no init.
     // completed => allocated
     rule declareExternalVariable'(true, initValue(X:CId, T:Type, .K),
               completed, Lnk:Linkage, Sto:StorageClassSpecifier)
          => giveCompositeType(X, T)
          ~> allocateDecl(X)
          ~> updateDecl(X, Lnk, allocated)
          ~> recordTentDef(X, Lnk)
          requires isCompleteType(T)
               andBool Sto =/=K Extern()
          [structural]

     // Already encountered an allocated or initialized decl, no init.
     rule declareExternalVariable'(true, initValue(X:CId, T:Type, .K),
               State:DeclState, Lnk:Linkage, Sto:StorageClassSpecifier)
          => giveCompositeType(X, T)
          ~> updateDecl(X, Lnk, State)
          ~> recordTentDef(X, Lnk) // Don't really need this.
          requires isCompleteType(T)
               andBool (State ==K allocated orBool State ==K initialized)
               andBool Sto =/=K Extern()
          [structural]

     // *** Initializer ***

     // declared => initialized
     rule declareExternalVariable'(false, initValue(X:CId, T:Type, Init:K),
               declared, Lnk:Linkage, _)
          => giveCompositeType(X, T)
          ~> allocateDecl(X)
          ~> updateDecl(X, Lnk, initialized)
          ~> Init
          requires isCompleteType(T)
          [structural]

     // completed => initialized
     rule declareExternalVariable'(false, initValue(X:CId, T:Type, Init:K),
               completed, Lnk:Linkage, _)
          => giveCompositeType(X, T)
          ~> allocateDecl(X)
          ~> updateDecl(X, Lnk, initialized)
          ~> Init
          requires isCompleteType(T)
          [structural]

     // allocated => initialized
     rule declareExternalVariable'(false, initValue(X:CId, T:Type, Init:K),
               allocated, Lnk:Linkage, _)
          => giveCompositeType(X, T)
          ~> updateDecl(X, Lnk, initialized)
          ~> Init
          requires isCompleteType(T)
          [structural]

     // already initialized
     rule (.K => CV("TDG13", "Redefinition of symbol: "
               +String showCId(X) +String "."))
          ~> declareExternalVariable'(false, initValue(X:CId, _, _),
               initialized, _, _)
          [structural]

     syntax KItem ::= updateDecl(CId, Linkage, DeclState)
     rule <k> updateDecl(X:CId, external, S':DeclState)
               => updateLinkState(X, T', Base')
          ...</k>
          <env>... X |-> Base':SymBase ...</env>
          <types>... X |-> T':Type ...</types>
          <curr-tu> Tu:String </curr-tu>
          <tu-id> Tu </tu-id>
          <externals>...
               X |-> declState(_ => Base', _ => T', _ => S', _)
          ...</externals>
          [structural]
     rule <k> updateDecl(X:CId, internal, S':DeclState)
               => .K
          ...</k>
          <env>... X |-> Base':SymBase ...</env>
          <types>... X |-> T':Type ...</types>
          <curr-tu> Tu:String </curr-tu>
          <tu-id> Tu </tu-id>
          <internals>...
               X |-> declState(_ => Base', _ => T', _ => S', _)
          ...</internals>
          [structural]

     syntax KItem ::= updateLinkState(CId, Type, SymBase)
     // Possibly no previous decl in this TU, but this isn't a def.
     rule <k> updateLinkState(X::CId, T'::Type, Base':LinkBase) => .K ...</k>
          <curr-tu> Tu:String </curr-tu>
          <curr-program-loc> L:CabsLoc </curr-program-loc>
          <external-decls> Decls::Map => Decls[X += Tu] </external-decls>
          <external-decls-loc> DeclsLoc::Map => DeclsLoc[X <- L] </external-decls-loc>
          <external-types> Types::Map => Types[X <- T'] </external-types>
          [structural]
     // New def.
     rule <k> updateLinkState(X::CId, T'::Type, Base':DirectBase) => .K ...</k>
          <curr-tu> Tu:String </curr-tu>
          <curr-program-loc> L:CabsLoc </curr-program-loc>
          <external-decls> Decls::Map => Decls[X += Tu] </external-decls>
          <external-decls-loc> DeclsLoc::Map => DeclsLoc[X <- L] </external-decls-loc>
          <external-types> Types::Map => Types[X <- T'] </external-types>
          <external-defs> Defs::Map => Defs[X <- Base'] </external-defs>
          <external-defs-loc> DefsLoc::Map => DefsLoc[X <- L] </external-defs-loc>
          requires notBool (X in_keys(Defs))
          [structural]
     // Def already encountered.
     rule <k> updateLinkState(X::CId, T'::Type, Base'::SymBase) => .K ...</k>
          <external-types> Types::Map => Types[X <- T'] </external-types>
          <external-defs>... X |-> Base' ...</external-defs>
          [structural]

     rule <k> (.K => CV("TDG13",
               "Redefinition of symbol: " +String showCId(X) +String "."))
               ~> updateLinkState(X::CId, _, Base':DirectBase)
          ...</k>
          <external-defs>... X |-> Base:SymBase ...</external-defs>
          requires Base =/=K Base'
          [structural]

     syntax KItem ::= recordTentDef(CId, Linkage)
     rule <k> recordTentDef(X:CId, internal) => .K ...</k>
          <internals>...
               X |-> declState(_, _, _, (_ => true))
          ...</internals>
          [structural]
     rule <k> recordTentDef(X:CId, external) => .K ...</k>
          <externals>...
               X |-> declState(_, _, _, (_ => true))
          ...</externals>
          [structural]

     // If we're asked to allocate a symbolic linker loc, then we need to
     // create a "real" static location and allocate that. We also go ahead and
     // add the new location to the environment. This means both locations
     // might end up in memory if the address of the symbol is taken in
     // multiple initializers, but it should work out as long as the symbolic
     // linker locs are transparent enough.
     syntax KItem ::= allocateDecl(CId)
     rule <k> allocateDecl(X:CId)
               => allocObject(Base, T)
          ...</k>
          <types>... X |-> T::Type ...</types>
          <env>... X |-> Base:DirectBase ...</env>
          [structural]
     rule <k> allocateDecl(X:CId)
               => addToEnv(X, T, bnew(!I:Int, T, static(Tu)))
               ~> allocObject(bnew(!I, T, static(Tu)), T)
          ...</k>
          <types>... X |-> T::Type ...</types>
          <env>... X |-> Base:LinkBase ...</env>
          <curr-tu> Tu::String </curr-tu>
          <tu-id> Tu </tu-id>
          <linkings>... .Map => Base |-> bnew(!I, T, static(Tu)) ...</linkings>
          [structural]

     // *** TODO(chathhorn) struct/union stuff ***

     rule <k> addGlobalTag(_, _) ...</k>
          <curr-tu> Tu:String </curr-tu>
          <tags> S:Map => S[Tu <- .Map] </tags>
          requires notBool (Tu in_keys(S))

     rule <k> addGlobalTag(X::CId, Info::TagInfo)
               => completeTagInExtDecls(X, Info, keys_list(Exts))
               ~> completeTagInIntDecls(X, Info, keys_list(Ints))
          ...</k>
          <curr-tu> Tu:String </curr-tu>
          <tu-id> Tu </tu-id>
          <tags>... Tu |-> (Structs:Map => Structs[tag(X, Tu, global) <- Info]) ...</tags>
          <externals> Exts:Map </externals>
          <internals> Ints:Map </internals>
          <incomplete-tags>... SetItem(X) => .Set ...</incomplete-tags>
          requires notBool (tag(X, Tu, global) in_keys(Structs))
          [structural]
     rule <k> addGlobalTag(X::CId, Info::TagInfo) => .K ...</k>
          <curr-tu> Tu:String </curr-tu>
          <tu-id> Tu </tu-id>
          <tags>... Tu |-> (Structs:Map => Structs[tag(X, Tu, global) <- Info]) ...</tags>
          <incomplete-tags> Incs:Set </incomplete-tags>
          requires notBool (X in Incs)
               andBool notBool (tag(X, Tu, global) in_keys(Structs))
          [structural]
     rule <k> (.K => CV("TDG15",
               "Redefinition of a struct, union, or enum: " +String showCId(X) +String "."))
               ~> addGlobalTag(X::CId, _)
          ...</k>
          <curr-tu> Tu:String </curr-tu>
          <tu-id> Tu </tu-id>
          <tags> GStructs:Map </tags>
          requires (tag(X, Tu, global) in_keys({{GStructs[Tu] orDefault .Map}<:KItem}:>Map))
          [structural]

     // TODO(chathhorn): This is all a mess, I really need to come up with a
     // better way to handle this.
     // Re-evaluate declarations that can now be allocated...
     syntax KItem ::= completeTagInExtDecls(CId, TagInfo, List)
                    | completeTagInExtDecl(CId, TagInfo, CId)

     rule <k> ( .K => completeTagInExtDecl(Tag, Info, X))
               ~> completeTagInExtDecls(Tag::CId, Info::TagInfo,
                    (ListItem(X:CId) => .List) _) ...</k>
          [structural]

     rule completeTagInExtDecls(_, _, .List) => .K
          [structural]

     rule <k> completeTagInExtDecl(_, _, X::CId)
               => declare(typedDeclaration(T, X), NoInit())
          ...</k>
          <curr-tu> Tu::String </curr-tu>
          <tu-id> Tu </tu-id>
          <externals>...
               X |-> declState(_, T::Type,
                         declared, _)
          ...</externals>
          requires notBool isFunctionType(T)
               andBool isCompleteType(T)
          [structural]

     rule <k> (completeTagInExtDecl(_, _, X::CId) => .K )
          ...</k>
          <curr-tu> Tu::String </curr-tu>
          <tu-id> Tu </tu-id>
          <externals>...
               X |-> declState(_, T::Type, DS:DeclState, _)
          ...</externals>
          requires isFunctionType(T)
               orBool notBool isCompleteType(T)
               orBool DS =/=K declared
          [structural]

     syntax KItem ::= completeTagInIntDecls(CId, TagInfo, List)
                    | completeTagInIntDecl(CId, TagInfo, CId)

     rule <k> ( .K => completeTagInIntDecl(Tag, Info, X))
               ~> completeTagInIntDecls(Tag::CId, Info::TagInfo,
                    (ListItem(X:CId) => .List) _) ...</k>
          [structural]

     rule completeTagInIntDecls(_, _, .List) => .K
          [structural]

     rule <k> completeTagInIntDecl(_, _, X:CId)
               => declare(typedDeclaration(addStorage(Static(), T), X), NoInit())
          ...</k>
          <internals>...
               X |-> declState(_, T:Type, declared, _)
          ...</internals>
          requires notBool isFunctionType(T)
               andBool isCompleteType(T)
          [structural]

     rule <k> completeTagInIntDecl(_, _, X:CId) => .K ...</k>
          <internals>...
               X |-> declState(_, T:Type, DS:DeclState, _)
          ...</internals>
          requires isFunctionType(T)
               orBool notBool isCompleteType(T)
               orBool DS =/=K declared
          [structural]

     syntax KItem ::= giveCompositeType(CId, Type)
     rule <k> giveCompositeType(X:CId, T':Type)
               => giveType(X, compositeType(T, stripStorageSpecifiers(T')))
          ...</k>
          <types>... X |-> T:Type ...</types>
          requires areDeclCompat(T, T')
          [structural]
     rule <k> giveCompositeType(X:CId, T':Type)
               => giveType(X, T')
          ...</k>
          <types> Types:Map </types>
          requires notBool (X in_keys(Types))
          [structural]
     rule <k> (.K => CV("TDG10",
               "Conflicting types for " +String showCId(X) +String "."))
               ~> giveCompositeType(X:CId, T':Type)
          ...</k>
          <types>... X |-> T:Type ...</types>
          requires notBool areDeclCompat(T, T')
          [structural]

     rule isNoInit(initValue(_, _, .K)) => true
     rule isNoInit(CodeLoc(I, _) => I)

endmodule
