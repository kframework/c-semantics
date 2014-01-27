module C-DECL-GLOBAL-SYNTAX
     syntax Linkage ::= "external" | "internal"
     syntax K ::= verifyDecl(K) [strict]

     syntax Bool ::= isNaked(Type) [function]

     syntax DeclState ::= "declared" | "completed" 
                        | "allocated" | "initialized"
     syntax K ::= declState(SymLoc, Type, DeclState)

     // Used in error.k...
     syntax K ::= "doDeclare'" "(" Type "," K ")" 
endmodule

module C-DECL-GLOBAL
     imports C-DECL-GLOBAL-SYNTAX
     imports C-DECL-LOCAL-SYNTAX
     imports C-DECL-INITIALIZER-SYNTAX
     imports C-DECL-ZERO-SYNTAX
     imports C-DECL-DEFINITION-SYNTAX
     imports C-ENV-SYNTAX
     imports C-TYPING-SYNTAX

     imports C-MEMORY-ALLOC-SYNTAX

     imports C-SYNTAX
     imports C-DYNAMIC-SYNTAX
     imports C-SYMLOC-SYNTAX

     imports COMPAT-SYNTAX

     rule doDeclare(T:Type, K:K) 
          => verifyDecl(T) ~> doDeclare'(T, K)

     rule <k> doDeclare'(typedDeclaration(T:Type, X:Id), K:K) 
               => declareInternalVariable(X, T, K)
          ...</k>
          <currentFunction> F:K </currentFunction>
          when F =/=K file-scope
          [structural] 
          
     rule <k> doDeclare'(typedDeclaration(T:Type, X:Id), K:K)
               => declareExternalVariable(X, T,
                    #if K ==K NoInit 
                    #then NoInit 
                    #else CodeLoc(K, L) #fi)
          ...</k>
          <currentFunction> file-scope </currentFunction>
          <currentProgramLoc> L:CabsLoc </currentProgramLoc>
          when isFunctionType(T)
               // TODO(chathhorn): type canonicalization doesn't work right so
               // we can't do this. Qualifiers on function decls appear to
               // always be applied to the declared function type, and not to
               // the function's return type. AFAIK, the only time qualifiers
               // should be applied to the declared function type is when the
               // function type is actually a typedef.
               //andBool getQualifiers(T) ==Set .Set
          [structural] 
     rule <k> doDeclare'(typedDeclaration(T:Type, X:Id), K:K)
               => declareExternalVariable(X, T,
                    #if K ==K NoInit 
                    #then NoInit 
                    #else CodeLoc(K, L) #fi)
          ...</k>
          <currentFunction> file-scope </currentFunction>
          <currentProgramLoc> L:CabsLoc </currentProgramLoc>
          when notBool isFunctionType(T)
          [structural] 
          
     syntax K ::= declareExternalVariable(Id, Type, K)

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
     rule isExtern(T:Type) => isExternType(T) orBool isFunctionType(T)

     
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
               => declareExternalVariable'(figureInit(X, unqualifyType(T), K), 
                    Loc, State, internal, isExtern(T))
          ...</k>
          <currTU> Tu:String </currTU>
          <tu-id> Tu </tu-id>
          <internals>...
               X |-> declState(Loc:SymLoc, _, State:DeclState)
          ...</internals>
          when notBool isNaked(T)
          [structural]

     // Naked, previously declared extern.
     rule <k> declareExternalVariable(X:Id, T:Type, K:K)
               => addToEnv(X, Loc)
               ~> giveType(X, OldT) // Tentative type.
               ~> declareExternalVariable'(figureInit(X, unqualifyType(T), K), 
                    Loc, State, external, false)
          ...</k>
          <currTU> Tu:String </currTU>
          <tu-id> Tu </tu-id>
          <externals>... 
               X |-> declState(Loc:SymLoc, OldT:Type, State:DeclState) 
          ...</externals>
          when isNaked(T)
          [structural]

     // Extern, previously declared extern.
     rule <k> declareExternalVariable(X:Id, T:Type, K:K)
               => addToEnv(X, Loc)
               ~> giveType(X, OldT) // Tentative type.
               ~> declareExternalVariable'(figureInit(X, unqualifyType(T), K), 
                    Loc, State, external, 
                    true)
          ...</k>
          <currTU> Tu:String </currTU>
          <tu-id> Tu </tu-id>
          <externals>... 
               X |-> declState(Loc:SymLoc, OldT:Type, State:DeclState) 
          ...</externals>
          <internals> Ints:Map </internals>
          when isExtern(T)
               andBool notBool (X in keys Ints)
          [structural]

     // Naked or extern, not previously declared.
     rule <k> declareExternalVariable(X:Id, T:Type, K:K)
               => addToEnv(X, Loc)
               ~> giveType(X, unqualifyType(T)) // Tentative type.
               ~> declareExternalVariable'(figureInit(X, unqualifyType(T), K), 
                    Loc, declared, external, isExtern(T))
          ...</k>
          <currTU> Tu:String </currTU>
          <tu-id> Tu </tu-id>
          <next-link-loc> Loc:SymLoc => linc(Loc) </next-link-loc>
          <externals>
               Exts:Map (. => X |-> declState(Loc, unqualifyType(T), declared))
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
               ~> declareExternalVariable'(figureInit(X, unqualifyType(T), K), 
                    Loc, declared, internal, false)
          ...</k>
          <currTU> Tu:String </currTU>
          <tu-id> Tu </tu-id>
          <next-static-loc> Loc:SymLoc => linc(Loc) </next-static-loc>
          <internals>
               Ints:Map (. => X |-> declState(Loc, unqualifyType(T), declared))
          </internals>
          when isStaticType(T)
               andBool notBool (X in keys Ints)
          [structural]

     // Now we just need to handle allocation, initialization, and updating the
     // declState, when necessary. The last argument might be called "isExtern"
     // or "don't allocate (unless initialized)." In C11, because
     // extern-qualified declarations can have initializers, the difference
     // between a global extern-qualified declaration and a global naked
     // declaration is very slight: they only differ in the case of
     // declarations without initializers. A naked declaration without an
     // initializer constitutes a tentative definition, but an extern
     // declaration without an initializer does not.
     syntax K ::= "declareExternalVariable'" 
          "(" K "," SymLoc "," DeclState "," Linkage "," Bool")" [strict(1)]

     // *** Incomplete ***

     // If this declaration has an incomplete type, then do nothing.
     rule declareExternalVariable'(initValue(_, T:Type, _), _, _, _, _) => .
          when isIncompleteType(T)
          [structural]

     // *** Extern, already completed.  ***

     rule declareExternalVariable'(initValue(_, _, .K), 
               _, State:DeclState, _, true)
          => .
          when State =/=K declared
          [structural]

     // *** Complete, no initializer ***

     // Completed type, no init.
     // declared => allocated
     rule declareExternalVariable'(initValue(X:Id, T:Type, .K), 
               Loc:SymLoc, declared, Lnk:Linkage, false)
          => giveType(X, T)
          ~> allocateDecl(X, T, Loc)
          ~> updateDecl(X, allocated, Lnk)
          when notBool isIncompleteType(T)
          [structural]

     // declared => completed
     rule declareExternalVariable'(initValue(X:Id, T:Type, .K), 
               _, declared, Lnk:Linkage, true)
          => giveType(X, T)
          ~> updateDecl(X, completed, Lnk)
          when notBool isIncompleteType(T)
          [structural]

     // Already encountered a completed decl, no init.
     // completed => allocated
     rule declareExternalVariable'(initValue(X:Id, T:Type, .K), 
               Loc:SymLoc, completed, Lnk:Linkage, false)
          => allocateDecl(X, T, Loc)
          ~> updateDecl(X, allocated, Lnk)
          when notBool isIncompleteType(T)
          [structural]

     // Already encountered a allocated or initialized decl, no init.
     rule declareExternalVariable'(initValue(_, T:Type, .K), 
               _, State:DeclState, _, false)
          => .
          when notBool isIncompleteType(T)
               andBool (State ==K allocated orBool State ==K initialized)
          [structural]

     // *** Initializer ***

     // declared => initialized
     rule declareExternalVariable'(initValue(X:Id, T:Type, K:K), 
               Loc:SymLoc, declared, Lnk:Linkage, _)
          => giveType(X, T)
          ~> allocateDecl(X, T, Loc)
          ~> K
          ~> updateDecl(X, initialized, Lnk)
          when K =/=K .K
          [structural]

     // completed => initialized
     rule declareExternalVariable'(initValue(X:Id, T:Type, K:K), 
               Loc:SymLoc, completed, Lnk:Linkage, _)
          => allocateDecl(X, T, Loc)
          ~> K
          ~> updateDecl(X, initialized, Lnk)
          when K =/=K .K
          [structural]

     // allocated => initialized
     rule declareExternalVariable'(initValue(X:Id, _, K:K), 
               _, allocated, Lnk:Linkage, _)
          => K
          ~> updateDecl(X, initialized, Lnk)
          when K =/=K .K
          [structural]

     syntax K ::= updateDecl(Id, DeclState, Linkage)
     rule <k> updateDecl(X:Id, S:DeclState, external) 
               => updateLinkState(X, T', Loc') 
          ...</k>
          <currTU> Tu:String </currTU>
          <tu-id> Tu </tu-id>
          <genv>... X |-> Loc':SymLoc ...</genv>
          <gtypes>... X |-> T':Type ...</gtypes>
          <externals>... 
               X |-> declState((_ => Loc'), (T:Type => T'), (_ => S))
          ...</externals>
          when isTypeCompatible(T, T') 
          [structural]
     rule <k> updateDecl(X:Id, S:DeclState, internal) => . ...</k>
          <currTU> Tu:String </currTU>
          <tu-id> Tu </tu-id>
          <genv>... X |-> Loc':SymLoc ...</genv>
          <gtypes>... X |-> T':Type ...</gtypes>
          <internals>...
               X |-> declState((_ => Loc'), (T:Type => T'), (_ => S))
          ...</internals>
          when isTypeCompatible(T, T')
          [structural]

     syntax K ::= updateLinkState(Id, Type, SymLoc)
     rule <k> updateLinkState(X:Id, T':Type, _) ...</k>
          <currTU> Tu:String </currTU>
          <external-decls> Decls:Map (. => X |-> set(SetItem(Tu))) </external-decls>
          <external-types> _ (. => X |-> T') </external-types>
          when notBool X in keys Decls
          [structural]
     // Incomplete type, no def.
     rule <k> updateLinkState(X:Id, T':Type, Loc':SymLoc) => . ...</k>
          <currTU> Tu:String </currTU>
          <external-decls>... X |-> set(_ (. => SetItem(Tu))) ...</external-decls>
          <external-types>... X |-> T:Type ...</external-types>
          when isLinkerLoc(Loc')
               andBool isIncompleteType(T')
               andBool isTypeCompatible(T, T')
          [structural]
     // Complete type, no def.
     rule <k> updateLinkState(X:Id, T':Type, Loc':SymLoc) => . ...</k>
          <currTU> Tu:String </currTU>
          <external-decls>... X |-> set(_ (. => SetItem(Tu))) ...</external-decls>
          <external-types>... X |-> (T:Type => T') ...</external-types>
          when isLinkerLoc(Loc')
               andBool notBool isIncompleteType(T')
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
   
     syntax K ::= allocateDecl(Id, Type, SymLoc)
     rule allocateDecl(X:Id, T:Type, Loc:SymLoc) 
          => allocateType(Loc, T) 
          ~> zero(X)
          when notBool isFunctionType(T)
               andBool (notBool isLinkerLoc(Loc))
          [structural]
     rule allocateDecl(_, T:Type, Loc:SymLoc) => .
          when isFunctionType(T)
               andBool notBool isLinkerLoc(Loc)
          [structural]

     // If we're asked to allocate a symbolic linker loc, then we need to
     // create a "real" static location and allocate that. We also go ahead and
     // add the new location to the environment. This means both locations
     // might end up in memory if the address of the symbol is taken in
     // multiple initializers, but it should work out as long as the symbolic
     // linker locs are transparent enough.
     rule <k> allocateDecl(X:Id, T:Type, Loc:SymLoc) 
               => addToEnv(X, Loc') 
          ...</k>
          <currTU> Tu:String </currTU>
          <tu-id> Tu </tu-id>
          <next-static-loc> Loc':SymLoc => linc(Loc') </next-static-loc>
          <linkings>... (. => Loc |-> Loc') </linkings>
          when isFunctionType(T)
               andBool isLinkerLoc(Loc)
          [structural]
     rule <k> allocateDecl(X:Id, T:Type, Loc:SymLoc) 
               => addToEnv(X, Loc')
               ~> allocateType(Loc', T) 
               ~> zero(X)
          ...</k>
          <currTU> Tu:String </currTU>
          <tu-id> Tu </tu-id>
          <next-static-loc> Loc':SymLoc => linc(Loc') </next-static-loc>
          <linkings>... (. => Loc |-> Loc') </linkings>
          when notBool isFunctionType(T)
               andBool isLinkerLoc(Loc)
          [structural]
          
endmodule
