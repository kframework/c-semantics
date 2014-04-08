module C-DECL-GLOBAL-SYNTAX
     syntax Linkage ::= "external" | "internal"

     syntax Bool ::= isNaked(Type) [function]

     syntax DeclState ::= "declared" | "completed" 
                        | "allocated" | "initialized"

     // The last bool argument indicates whether a tentative def has been
     // encountered. This is only relevant in the case of symbols with external
     // linkage, which must then be completed and allocated at the end of
     // processing the TU if a tentative def exists and the type is still
     // incomplete.
     syntax K ::= declState(SymLoc, Type, DeclState, Bool)

     syntax K ::= allowInit(K)
     syntax K ::= updateDecl(Id, DeclState, Linkage)
     syntax K ::= updateLinkState(Id, Type, SymLoc)
     syntax K ::= allocateDecl(Id, Type, SymLoc)
endmodule

module C-DECL-GLOBAL
     imports C-DECL-DEFINITION-SYNTAX
     imports C-DECL-GLOBAL-SYNTAX
     imports C-DECL-INITIALIZER-SYNTAX
     imports C-DECL-LOCAL-SYNTAX
     imports C-DECL-TAGGED-SYNTAX
     imports C-DECL-ZERO-SYNTAX

     imports C-BITSIZE-SYNTAX
     imports C-DYNAMIC-SYNTAX
     imports C-ENV-SYNTAX
     imports C-ERROR-SYNTAX
     imports C-MEMORY-ALLOC-SYNTAX
     imports C-SETTINGS-SYNTAX
     imports C-SYMLOC-SYNTAX
     imports C-SYNTAX
     imports C-TYPING-SYNTAX

     imports COMPAT-SYNTAX

     rule <k> doDeclare(typedDeclaration(T:Type, X:Id), K:K) 
               => declareInternalVariable(X, T, K)
          ...</k>
          <curr-function> F:K </curr-function>
          when F =/=K file-scope
               andBool validLocalStorageClass(T)
          [structural] 
          
     rule <k> doDeclare(typedDeclaration(T:Type, X:Id), K:K)
               => declareExternalVariable(X, T,
                    #if K ==K NoInit 
                    #then NoInit 
                    #else CodeLoc(K, L) #fi)
          ...</k>
          <curr-function> file-scope </curr-function>
          <curr-program-loc> L:CabsLoc </curr-program-loc>
          when isFunctionType(T)
               andBool validGlobalStorageClass(T)
          [structural] 
     rule <k> doDeclare(typedDeclaration(T:Type, X:Id), K:K)
               => declareExternalVariable(X, T,
                    #if K ==K NoInit 
                    #then NoInit 
                    #else CodeLoc(K, L) #fi)
          ...</k>
          <curr-function> file-scope </curr-function>
          <curr-program-loc> L:CabsLoc </curr-program-loc>
          when notBool isFunctionType(T)
               andBool validGlobalStorageClass(T)
          [structural] 

     rule (. => ERROR("DG1", "Declaration for " +String idToString(X)
               +String " appears with multiple storage class specifiers.", 8))
          ~> doDeclare(typedDeclaration(T:Type, X:Id), _)
          when notBool validStorageClass(T)
          [structural] 

     rule <k> (. => ERROR("DG2", "Declaration for " +String idToString(X)
               +String " appears with invalid storage class specifiers.", 8))
               ~> doDeclare(typedDeclaration(T:Type, X:Id), _)
          ...</k>
          <curr-function> F:K </curr-function>
          when F =/=K file-scope
               andBool validStorageClass(T)
               andBool notBool validLocalStorageClass(T)
          [structural] 

     rule <k> (. => ERROR("DG3", "Declaration for " +String idToString(X)
               +String " appears with invalid storage class specifiers.", 8))
               ~> doDeclare(typedDeclaration(T:Type, X:Id), _)
          ...</k>
          <curr-function> file-scope </curr-function>
          when validStorageClass(T)
               andBool notBool validGlobalStorageClass(T)
          [structural] 
          
     syntax K ::= declareExternalVariable(Id, Type, K)

     syntax Bool ::= validStorageClass(Type) [function]
                   | "validStorageClass'" "(" Type "," Set ")" [function]
     syntax Bool ::= validGlobalStorageClass(Type) [function]
                   | "validGlobalStorageClass'" "(" Type "," Set ")" [function]
     syntax Bool ::= validLocalStorageClass(Type) [function]
                   | "validLocalStorageClass'" "(" Type "," Set ")" [function]

     // TODO(chathhorn): storage class of function parameters (only register is
     // allowed).

     // TODO(chathhorn): probably cleaner just to check the intersection
     // between the storage class specifiers and the "qualities," but there are
     // some annoying special cases (ThreadLocal & extern/static is legal).
     // Also, consider moving this to type canonicalization.
     rule validStorageClass(T:Type) => validStorageClass'(T, getQualities(T))
     rule validStorageClass'(T:Type, Qualities:Set) => notBool (
               // TODO(chathhorn): type canonicalization doesn't work right so
               // we can't do this. Qualifiers on function decls appear to
               // always be applied to the declared function type, and not to
               // the function's return type. AFAIK, the only time qualifiers
               // should be applied to the declared function type is when the
               // function type is actually a typedef.
               (Static in Qualities andBool Extern in Qualities)
               orBool (Auto in Qualities andBool Static in Qualities)
               orBool (Auto in Qualities andBool Extern in Qualities)
               orBool (Auto in Qualities andBool ThreadLocal in Qualities)
               orBool (Register in Qualities andBool Static in Qualities)
               orBool (Register in Qualities andBool Extern in Qualities)
               orBool (Register in Qualities andBool ThreadLocal in Qualities)
               orBool (isFunctionType(T) andBool ThreadLocal in Qualities)
               orBool (isFunctionType(T) andBool Auto in Qualities)
               orBool (isFunctionType(T) andBool Register in Qualities)
          )

     rule validGlobalStorageClass(T:Type)
          => validGlobalStorageClass'(T, getQualities(T))
     rule validGlobalStorageClass'(T:Type, Qualities:Set) =>
          validStorageClass'(T, Qualities)
          andBool notBool (
               (Auto in Qualities)
               orBool (Register in Qualities)
          )

     rule validLocalStorageClass(T:Type)
          => validLocalStorageClass'(T, getQualities(T))
     rule validLocalStorageClass'(T:Type, Qualities:Set) =>
          validStorageClass'(T, Qualities)
          andBool notBool (
               (isFunctionType(T) andBool Static in Qualities)
          )

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
     rule isNaked(T:Type) 
          => notBool (isExternType(T) orBool isStaticType(T))
               andBool notBool isFunctionType(T)
     
     // Naked function declarations are treated as though they were qualified
     // extern.
     syntax K ::= isExtern(Type) [function]
     rule isExtern(T:Type)
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

     // Static or extern, previously declared static.
     rule <k> declareExternalVariable(X:Id, T:Type, K:K)
               => declareExternalVariable'(
                    allowInit(figureInit(X, unqualifyType(T), K)), 
                    Loc, State, internal, 
                    #if isExtern(T) #then Extern #else Static #fi)
          ...</k>
          <curr-tu> Tu:String </curr-tu>
          <tu-id> Tu </tu-id>
          <externals> Exts:Map </externals>
          <internals>...
               X |-> declState(Loc:SymLoc, OldT:Type, State:DeclState, _)
          ...</internals>
          when notBool isNaked(T)
               andBool notBool (X in keys Exts)
               andBool isTypeCompatible(T, OldT)
          [structural]

     rule <k> (. => ERROR("DG4", "Conflicting types for "
                    +String idToString(X) +String "."))
               ~> declareExternalVariable(X:Id, T:Type, _)
          ...</k>
          <curr-tu> Tu:String </curr-tu>
          <tu-id> Tu </tu-id>
          <internals>... 
               X |-> declState(_, OldT:Type, _, _) 
          ...</internals>
          when notBool isTypeCompatible(T, OldT)
          [structural]

     // Naked, previously declared extern.
     rule <k> declareExternalVariable(X:Id, T:Type, K:K)
               => addToEnv(X, Loc)
               ~> giveType(X, OldT) // Tentative type.
               ~> declareExternalVariable'(
                    allowInit(figureInit(X, unqualifyType(T), K)), 
                    Loc, State, external, .K)
          ...</k>
          <curr-tu> Tu:String </curr-tu>
          <tu-id> Tu </tu-id>
          <externals>... 
               X |-> declState(Loc:SymLoc, OldT:Type, State:DeclState, _) 
          ...</externals>
          <internals> Ints:Map </internals>
          when isNaked(T)
               andBool notBool (X in keys Ints)
               andBool isTypeCompatible(T, OldT)
          [structural]

     // Extern, previously declared extern.
     rule <k> declareExternalVariable(X:Id, T:Type, K:K)
               => addToEnv(X, Loc)
               ~> giveType(X, OldT) // Tentative type.
               ~> declareExternalVariable'(
                    allowInit(figureInit(X, unqualifyType(T), K)), 
                    Loc, State, external, Extern)
          ...</k>
          <curr-tu> Tu:String </curr-tu>
          <tu-id> Tu </tu-id>
          <externals>... 
               X |-> declState(Loc:SymLoc, OldT:Type, State:DeclState, _) 
          ...</externals>
          <internals> Ints:Map </internals>
          when isExtern(T)
               andBool notBool (X in keys Ints)
               andBool isTypeCompatible(T, OldT)
          [structural]

     rule <k> (. => ERROR("DG5", "Conflicting types for "
                    +String idToString(X) +String "."))
               ~> declareExternalVariable(X:Id, T:Type, _)
          ...</k>
          <curr-tu> Tu:String </curr-tu>
          <tu-id> Tu </tu-id>
          <externals>... 
               X |-> declState(_, OldT:Type, _, _) 
          ...</externals>
          when notBool isTypeCompatible(T, OldT)
          [structural]

     // Naked or extern, not previously declared.
     rule <k> declareExternalVariable(X:Id, T:Type, K:K)
               => addToEnv(X, Loc)
               ~> giveType(X, unqualifyType(T)) // Tentative type.
               ~> declareExternalVariable'(
                    allowInit(figureInit(X, unqualifyType(T), K)), 
                    Loc, declared, external,
                    #if isExtern(T) #then Extern #else Static #fi)
          ...</k>
          <curr-tu> Tu:String </curr-tu>
          <tu-id> Tu </tu-id>
          <next-link-loc> Loc:SymLoc => linc(Loc) </next-link-loc>
          <externals>
               Exts:Map
               (. => X |-> declState(Loc, unqualifyType(T), declared, false))
          </externals>
          <internals> Ints:Map </internals>
          when notBool isStaticType(T)
               andBool notBool (X in keys Exts) 
               andBool notBool (X in keys Ints)
          [structural]

     // Static, not previously declared.
     rule <k> declareExternalVariable(X:Id, T:Type, K:K)
               => addToEnv(X, Loc)
               ~> giveType(X, unqualifyType(T)) // Tentative type.
               ~> declareExternalVariable'(
                    allowInit(figureInit(X, unqualifyType(T), K)), 
                    Loc, declared, internal, Static)
          ...</k>
          <curr-tu> Tu:String </curr-tu>
          <tu-id> Tu </tu-id>
          <next-static-loc> Loc:SymLoc => linc(Loc) </next-static-loc>
          <externals> Exts:Map </externals>
          <internals>
               Ints:Map
               (. => X |-> declState(Loc, unqualifyType(T), declared, false))
          </internals>
          when isStaticType(T)
               andBool notBool (X in keys Exts)
               andBool notBool (X in keys Ints)
          [structural]

     // Static, previously extern.
     rule <k> (. => ERROR("DG6",
               "Static declaration of " +String idToString(X)
               +String " follows non-static declaration.", 8))
               ~> declareExternalVariable(X:Id, T:Type, _)
          ...</k>
          <curr-tu> Tu:String </curr-tu>
          <tu-id> Tu </tu-id>
          <externals> Exts:Map </externals>
          when isStaticType(T)
               andBool (X in keys Exts)
          [structural]

     // Now we just need to handle allocation, initialization, and updating the
     // declState, when necessary. The last argument can be thought of as the
     // "true" storage class specifier of the decl, counting functions as
     // extern. In C11, because extern-qualified declarations can have
     // initializers, the difference between a global extern-qualified
     // declaration and a global naked declaration is very slight: they only
     // differ in the case of declarations without initializers. A naked
     // declaration without an initializer constitutes a tentative definition,
     // but an extern declaration without an initializer does not.
     syntax K ::= "declareExternalVariable'" "(" K "," SymLoc "," DeclState ","
     Linkage "," Storage ")" [strict(1)]

     // *** Incomplete ***

     // If this declaration has an incomplete type, then we're done.
     rule declareExternalVariable'(initValue(_, T:Type, .K), _, _, _, Extern)
          => .
          when notBool isCompleteType(T)
          [structural]
     rule declareExternalVariable'(initValue(X:Id, T:Type, .K),
               _, _, Lnk:Linkage, Sto:Storage)
          => recordTentDef(X, Lnk)
          when notBool isCompleteType(T)
               andBool Sto =/=K Extern
          [structural]

     // *** Extern, already completed.  ***

     rule declareExternalVariable'(initValue(_, _, .K), 
               _, State:DeclState, _, Extern)
          => .
          when State =/=K declared
          [structural]

     // *** Complete, no initializer ***

     // static or naked => tentative def
     // extern => external def

     // Completed type, no init.
     // declared => allocated
     rule declareExternalVariable'(initValue(X:Id, T:Type, .K), 
               Loc:SymLoc, declared, Lnk:Linkage, Sto:Storage)
          => giveType(X, T)
          ~> allocateDecl(X, T, Loc)
          ~> updateDecl(X, allocated, Lnk)
          ~> recordTentDef(X, Lnk)
          when isCompleteType(T)
               andBool Sto =/=K Extern
          [structural]

     // declared => completed
     rule declareExternalVariable'(initValue(X:Id, T:Type, .K), 
               _, declared, Lnk:Linkage, Extern)
          => giveType(X, T)
          ~> updateDecl(X, completed, Lnk)
          when isCompleteType(T)
          [structural]

     // Already encountered a completed decl, no init.
     // completed => allocated
     rule declareExternalVariable'(initValue(X:Id, T:Type, .K), 
               Loc:SymLoc, completed, Lnk:Linkage, Sto:Storage)
          => allocateDecl(X, T, Loc)
          ~> updateDecl(X, allocated, Lnk)
          ~> recordTentDef(X, Lnk)
          when isCompleteType(T)
               andBool Sto =/=K Extern
          [structural]

     // Already encountered a allocated or initialized decl, no init.
     rule declareExternalVariable'(initValue(X:Id, T:Type, .K), 
               _, State:DeclState, Lnk:Linkage, Sto:Storage)
          => recordTentDef(X, Lnk) // Don't really need this.
          when isCompleteType(T)
               andBool (State ==K allocated orBool State ==K initialized)
               andBool Sto =/=K Extern
          [structural]

     // *** Initializer ***

     // declared => initialized
     rule declareExternalVariable'(initValue(X:Id, T:Type, K:K), 
               Loc:SymLoc, declared, Lnk:Linkage, _)
          => giveType(X, T)
          ~> allocateDecl(X, T, Loc)
          ~> allowInit(K)
          ~> updateDecl(X, initialized, Lnk)
          when K =/=K .K
          [structural]

     // completed => initialized
     rule declareExternalVariable'(initValue(X:Id, T:Type, K:K), 
               Loc:SymLoc, completed, Lnk:Linkage, _)
          => allocateDecl(X, T, Loc)
          ~> allowInit(K)
          ~> updateDecl(X, initialized, Lnk)
          when K =/=K .K
          [structural]

     // allocated => initialized
     rule declareExternalVariable'(initValue(X:Id, _, K:K), 
               _, allocated, Lnk:Linkage, _)
          => allowInit(K)
          ~> updateDecl(X, initialized, Lnk)
          when K =/=K .K
          [structural]

     syntax K ::= setInitializing(Bool)
     rule <k> setInitializing(I:Bool) => .K ...</k>
          <initializing> _ => I </initializing>
          [structural]

     rule <k> updateDecl(X:Id, S:DeclState, external) 
               => updateLinkState(X, T', Loc') 
          ...</k>
          <curr-tu> Tu:String </curr-tu>
          <tu-id> Tu </tu-id>
          <genv>... X |-> Loc':SymLoc ...</genv>
          <gtypes>... X |-> T':Type ...</gtypes>
          <externals>... 
               X |-> declState((_ => Loc'), (T:Type => T'), (_ => S), _)
          ...</externals>
          when isTypeCompatible(T, T') 
          [structural]
     rule <k> updateDecl(X:Id, S:DeclState, internal) => . ...</k>
          <curr-tu> Tu:String </curr-tu>
          <tu-id> Tu </tu-id>
          <genv>... X |-> Loc':SymLoc ...</genv>
          <gtypes>... X |-> T':Type ...</gtypes>
          <internals>...
               X |-> declState((_ => Loc'), (T:Type => T'), (_ => S), _)
          ...</internals>
          when isTypeCompatible(T, T')
          [structural]

     rule <k> updateLinkState(X:Id, T':Type, _) ...</k>
          <curr-tu> Tu:String </curr-tu>
          <external-decls> Decls:Map (. => X |-> set(SetItem(Tu))) </external-decls>
          <external-types> _ (. => X |-> T') </external-types>
          when notBool X in keys Decls
          [structural]
     // Incomplete type, no def.
     rule <k> updateLinkState(X:Id, T':Type, Loc':SymLoc) => . ...</k>
          <curr-tu> Tu:String </curr-tu>
          <external-decls>... X |-> set(_ (. => SetItem(Tu))) ...</external-decls>
          <external-types>... X |-> T:Type ...</external-types>
          when isLinkerLoc(Loc')
               andBool (notBool isCompleteType(T'))
               andBool isTypeCompatible(T, T')
          [structural]
     // Complete type, no def.
     rule <k> updateLinkState(X:Id, T':Type, Loc':SymLoc) => . ...</k>
          <curr-tu> Tu:String </curr-tu>
          <external-decls>... X |-> set(_ (. => SetItem(Tu))) ...</external-decls>
          <external-types>... X |-> (T:Type => T') ...</external-types>
          when isLinkerLoc(Loc')
               andBool isCompleteType(T')
               andBool isTypeCompatible(T, T')
          [structural]
     // New def.
     rule <k> updateLinkState(X:Id, T':Type, Loc':SymLoc) => . ...</k>
          <external-types>... X |-> (T:Type => T') ...</external-types>
          <external-defs> Defs:Map (. => X |-> Loc') </external-defs>
          when notBool isLinkerLoc(Loc')
               andBool (notBool X in keys Defs)
               andBool isTypeCompatible(T, T')
          [structural]
     // Def already encountered.
     rule <k> updateLinkState(X:Id, _, Loc':SymLoc) => . ...</k>
          <external-defs>... X |-> Loc' ...</external-defs>
          [structural]
   
     rule <k> (.K => ERROR("DG7",
                    "redefinition of symbol with external linkage: "
                    +String idToString(X)))
               ~> updateLinkState(X:Id, _, Loc':SymLoc)
          ...</k>
          <external-defs>...
               X |-> Loc:SymLoc
          ...</external-defs>
          when notBool isLinkerLoc(Loc')
               andBool (Loc =/=K Loc')
          [structural]
     
     syntax K ::= recordTentDef(Id, Linkage)
     rule <k> recordTentDef(X:Id, internal) => . ...</k>
          <internals>...
               X |-> declState(_, _, _, (_ => true))
          ...</internals>
          [structural]
     rule <k> recordTentDef(X:Id, external) => . ...</k>
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
     rule allocateDecl(X:Id, T:Type, Loc:SymLoc) 
          => allocateType(Loc, T) 
          ~> allowInit(zero(X))
          when notBool isLinkerLoc(Loc)
          [structural]
     rule <k> allocateDecl(X:Id, T:Type, Loc:SymLoc) 
               => addToEnv(X, Loc')
               ~> allocateType(Loc', T) 
               ~> allowInit(zero(X))
          ...</k>
          <curr-tu> Tu:String </curr-tu>
          <tu-id> Tu </tu-id>
          <next-static-loc> Loc':SymLoc => linc(Loc') </next-static-loc>
          <linkings>... (. => Loc |-> Loc') </linkings>
          when isLinkerLoc(Loc)
          [structural]


     // *** TODO(chathhorn) struct/union stuff *** 

     rule <k> addGlobalTag(X:Id, Info:FieldInfo)
               => completeTagInExtDecls(X, Info, keys Exts)
               ~> completeTagInIntDecls(X, Info, keys Ints)
               ~> completeTagInTags(X, Info, keys Structs)
          ...</k>
          <curr-tu> Tu:String </curr-tu>
          <tu-id> Tu </tu-id>
          <gtypes> GTypes:Map => completeTagsInMap(X |-> Info, GTypes) </gtypes>
          <types> Types:Map => completeTagsInMap(X |-> Info, Types) </types>
          <structs> Structs:Map => Structs:Map[Info / X] </structs>
          <gstructs> GStructs:Map => GStructs:Map[Info / X] </gstructs>
          <externals> Exts:Map </externals>
          <internals> Ints:Map </internals>
          <incomplete-tags>... SetItem(X) => .Set ...</incomplete-tags>
          [structural]

     rule <k> addGlobalTag(X:Id, Info:FieldInfo) => . ...</k>
          <curr-tu> Tu:String </curr-tu>
          <tu-id> Tu </tu-id>
          <structs> Structs:Map => Structs:Map[Info / X] </structs>
          <gstructs> GStructs:Map => GStructs:Map[Info / X] </gstructs>
          <incomplete-tags> Incs:Set </incomplete-tags>
          when notBool (X in Incs)
          [structural]

     // TODO(chathhorn): This is all a mess, I really need to come up with a
     // better way to handle this.
     // Re-evaluate declarations that can now be allocated...
     syntax K ::= completeTagInExtDecls(Id, FieldInfo, Set)
     rule <k> (.K => doDeclare(
                    typedDeclaration(completeTag(Tag, Info, T), X), NoInit))
               ~> completeTagInExtDecls(Tag:Id, Info:FieldInfo,
                    (SetItem(X:Id) => .Set) _)
          ...</k>
          <curr-tu> Tu:String </curr-tu>
          <tu-id> Tu:String </tu-id>
          <externals>...
               X |-> declState(_, T:Type, declared, _)
          ...</externals>
          when notBool isFunctionType(T)
               andBool isCompleteType(completeTag(Tag, Info, T))
     rule <k> completeTagInExtDecls(Tag:Id, Info:FieldInfo, (SetItem(X:Id) => .Set) _)
          ...</k>
          <curr-tu> Tu:String </curr-tu>
          <tu-id> Tu:String </tu-id>
          <externals>...
               X |-> declState(_, T:Type, DS:DeclState, _)
          ...</externals>     
          when isFunctionType(T)
               orBool isCompleteType(completeTag(Tag, Info, T))
               orBool DS =/=K declared
     rule completeTagInExtDecls(_, _, .Set) => .K

     syntax K ::= completeTagInIntDecls(Id, FieldInfo, Set)
     rule <k> (.K => doDeclare(
                    typedDeclaration(t(.Set,
                         qualifiedType(completeTag(Tag, Info, T), Static)), X),
                         NoInit))
               ~> completeTagInIntDecls(Tag:Id, Info:FieldInfo,
                    (SetItem(X:Id) => .Set) _)
          ...</k>
          <curr-tu> Tu:String </curr-tu>
          <tu-id> Tu:String </tu-id>
          <internals>...
               X |-> declState(_, T:Type, declared, _)
          ...</internals>     
          when notBool isFunctionType(T)
               andBool isCompleteType(completeTag(Tag, Info, T))
     rule <k> completeTagInIntDecls(Tag:Id, Info:FieldInfo, (SetItem(X:Id) => .Set) _)
          ...</k>
          <curr-tu> Tu:String </curr-tu>
          <tu-id> Tu:String </tu-id>
          <internals>...
               X |-> declState(_, T:Type, DS:DeclState, _)
          ...</internals>     
          when isFunctionType(T)
               orBool (notBool isCompleteType(completeTag(Tag, Info, T)))
               orBool DS =/=K declared
     rule completeTagInIntDecls(_, _, .Set) => .K

     syntax K ::= completeTagInTags(Id, FieldInfo, Set)
     rule <k> completeTagInTags(S:Id, Info:FieldInfo, (SetItem(S2:Id) => .Set)  _)
          ...</k>
          <curr-tu> Tu:String </curr-tu>
          <tu-id> Tu </tu-id>
          <gstructs>...
               S2 |-> fieldInfo(
                    (Decls:List => completeTagsInList(S |-> Info, Decls)),
                    (Fields:Map => completeTagsInMap(S |-> Info, Fields)), _)
          ...</gstructs>
          <structs>...
               S2 |-> fieldInfo(
                    (Decls:List => completeTagsInList(S |-> Info, Decls)),
                    (Fields:Map => completeTagsInMap(S |-> Info, Fields)), _)
          ...</structs>
          when S =/=K S2
          [structural]
     rule completeTagInTags(_, _, .Set) => .K
          [structural]
     rule completeTagInTags(S:Id, _, SetItem(S)) => .K
          [structural]

     syntax K ::= "allowInit'" [strict]

     rule allowInit(K:K)
          => setInitializing(true)
          ~> K
          ~> allowInit'
          [structural]
     rule R:KResult ~> allowInit'
          => setInitializing(false) ~> R
          [structural]
     rule allowInit' => setInitializing(false)
          [structural]

endmodule
