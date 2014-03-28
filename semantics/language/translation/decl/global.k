module C-DECL-GLOBAL-SYNTAX
     syntax Linkage ::= "external" | "internal"
     syntax K ::= verifyDecl(K) [strict]

     syntax Bool ::= isNaked(Type) [function]

     syntax DeclState ::= "declared" | "completed" 
                        | "allocated" | "initialized"

     // The last bool argument indicates whether a tentative def has been
     // encountered. This is only relevant in the case of symbols with external
     // linkage, which must then be completed and allocated at the end of
     // processing the TU if a tentative def exists and the type is still
     // incomplete.
     syntax K ::= declState(SymLoc, Type, DeclState, Bool)

     // Used in error.k...
     syntax K ::= "doDeclare'" "(" Type "," K ")" 

     syntax K ::= allowInit(K) [function]
     syntax K ::= updateDecl(Id, DeclState, Linkage)
     syntax K ::= updateLinkState(Id, Type, SymLoc)
     syntax K ::= allocateDecl(Id, Type, SymLoc)
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
     imports C-ERROR-SYNTAX

     imports C-BITSIZE-SYNTAX
     imports C-SETTINGS-SYNTAX

     imports COMPAT-SYNTAX

     rule doDeclare(T:Type, K:K) 
          => verifyDecl(T) ~> doDeclare'(T, K)

     rule <k> doDeclare'(typedDeclaration(T:Type, X:Id), K:K) 
               => declareInternalVariable(X, T, K)
          ...</k>
          <curr-function> F:K </curr-function>
          when F =/=K file-scope
          [structural] 
          
     rule <k> doDeclare'(typedDeclaration(T:Type, X:Id), K:K)
               => declareExternalVariable(X, T,
                    #if K ==K NoInit 
                    #then NoInit 
                    #else CodeLoc(K, L) #fi)
          ...</k>
          <curr-function> file-scope </curr-function>
          <curr-program-loc> L:CabsLoc </curr-program-loc>
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
          <curr-function> file-scope </curr-function>
          <curr-program-loc> L:CabsLoc </curr-program-loc>
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
          <curr-tu> Tu:String </curr-tu>
          <tu-id> Tu </tu-id>
          <internals>...
               X |-> declState(Loc:SymLoc, _, State:DeclState, _)
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
          <curr-tu> Tu:String </curr-tu>
          <tu-id> Tu </tu-id>
          <externals>... 
               X |-> declState(Loc:SymLoc, OldT:Type, State:DeclState, _) 
          ...</externals>
          when isNaked(T)
          [structural]

     // Extern, previously declared extern.
     rule <k> declareExternalVariable(X:Id, T:Type, K:K)
               => addToEnv(X, Loc)
               ~> giveType(X, OldT) // Tentative type.
               ~> declareExternalVariable'(figureInit(X, unqualifyType(T), K), 
                    Loc, State, external, true)
          ...</k>
          <curr-tu> Tu:String </curr-tu>
          <tu-id> Tu </tu-id>
          <externals>... 
               X |-> declState(Loc:SymLoc, OldT:Type, State:DeclState, _) 
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
               ~> declareExternalVariable'(figureInit(X, unqualifyType(T), K), 
                    Loc, declared, internal, false)
          ...</k>
          <curr-tu> Tu:String </curr-tu>
          <tu-id> Tu </tu-id>
          <next-static-loc> Loc:SymLoc => linc(Loc) </next-static-loc>
          <internals>
               Ints:Map
               (. => X |-> declState(Loc, unqualifyType(T), declared, false))
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

     // If this declaration has an incomplete type, then we're done.
     rule declareExternalVariable'(initValue(_, T:Type, .K), _, _, _, true)
          => .
          when isIncompleteType(T)
          [structural]
     rule declareExternalVariable'(initValue(X:Id, T:Type, .K),
               _, _, Lnk:Linkage, false)
          => recordTentDef(X, Lnk)
          when isIncompleteType(T)
          [structural]

     // *** Extern, already completed.  ***

     rule declareExternalVariable'(initValue(_, _, .K), 
               _, State:DeclState, _, true)
          => .
          when State =/=K declared
          [structural]

     // *** Complete, no initializer ***

     // static or naked => tentative def
     // extern => external def

     // Completed type, no init.
     // declared => allocated
     rule declareExternalVariable'(initValue(X:Id, T:Type, .K), 
               Loc:SymLoc, declared, Lnk:Linkage, false)
          => giveType(X, T)
          ~> allocateDecl(X, T, Loc)
          ~> updateDecl(X, allocated, Lnk)
          ~> recordTentDef(X, Lnk)
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
          ~> recordTentDef(X, Lnk)
          when notBool isIncompleteType(T)
          [structural]

     // Already encountered a allocated or initialized decl, no init.
     rule declareExternalVariable'(initValue(X:Id, T:Type, .K), 
               _, State:DeclState, Lnk:Linkage, false)
          => recordTentDef(X, Lnk) // Don't really need this.
          when notBool isIncompleteType(T)
               andBool (State ==K allocated orBool State ==K initialized)
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

     rule allowInit(K:K)
          => setInitializing(true)
          ~> K
          ~> setInitializing(false)

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
               andBool isIncompleteType(T')
               andBool isTypeCompatible(T, T')
          [structural]
     // Complete type, no def.
     rule <k> updateLinkState(X:Id, T':Type, Loc':SymLoc) => . ...</k>
          <curr-tu> Tu:String </curr-tu>
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
   
     rule <k> (.K => ERROR("DG1",
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

     // *** TODO *** Struct/UnionDef *** TODO ***
          
     // First map is for type, second map is for offset.
     syntax AggInfo ::= makeStructAggInfo(List) [function]
     syntax AggInfo ::= makeUnionAggInfo(List) [function]

     // TODO(chathhorn): handle global/local differently.
     // note that struct defs might appear buried in a type.
     rule StructDef(X:Id, krlist(L:List))
          => structDef'(X,
               makeStructAggInfo(fillBitHoles(incompleteToFlexibleArrayMember(L))))
          when L =/=List .List
          [structural]
     rule UnionDef(X:Id, krlist(L:List))
          => unionDef'(X, makeUnionAggInfo(fillUnionBitHoles(L)))
          when L =/=List .List
          [structural]

     // FIXME: chould check for some struct contraints here.
     syntax List ::= incompleteToFlexibleArrayMember(List) [function]

     rule incompleteToFlexibleArrayMember(
          ListItem(typedDeclaration(T:Type, X:Id)) 
          L:List)
          => ListItem(typedDeclaration(T, X)) incompleteToFlexibleArrayMember(L)
          when notBool isIncompleteType(T)
          [structural]
     rule incompleteToFlexibleArrayMember(
          ListItem(typedDeclaration(t(S:Set, incompleteArrayType(T:Type)), X:Id)))
          => ListItem(typedDeclaration(t(S, flexibleArrayType(T)), X))
          [structural]
     rule incompleteToFlexibleArrayMember(.List) => .List

     syntax List ::= fillBitHoles(List) [function]
     syntax List ::=  "fillBitHoles-aux" "(" Int "," List ")" [function]
     rule [fillBitHoles-none]:
          fillBitHoles(.List) => .List 
          [structural]
     // if we haven't seen bitfields
     rule [fillBitHoles-not-bitfield]:
          fillBitHoles(ListItem(typedDeclaration(T:Type, X:Id)) L:List) 
          => ListItem(typedDeclaration(T, X)) fillBitHoles(L)
          when notBool isBitfieldType(T) 
          [structural]
     
     rule [fillBitHoles-bitfield]:
          fillBitHoles(ListItem(typedDeclaration(T:Type, X:Id)) L:List) 
          => fillBitHoles-aux(0, ListItem(typedDeclaration(T, X)) L)
          when isBitfieldType(T) 
          [structural]
     
     // if we have seen bitfields
     rule [fillBitHoles-aux-not-bitfield]:
          fillBitHoles-aux(N:Int, 
               ListItem(typedDeclaration(T:Type, X:Id)) L:List) 
          => ListItem(typedDeclaration(t(.Set, bitfieldType(t(.Set, unsigned-int), 
               absInt(cfg:bitsPerByte -Int (N %Int cfg:bitsPerByte)) 
               %Int cfg:bitsPerByte)), #NoName))
               fillBitHoles(ListItem(typedDeclaration(T, X)) L)
          when notBool isBitfieldType(T) 
          [structural]
     
     rule [fillBitHoles-aux-bitfield-normal]:
          fillBitHoles-aux(N:Int, 
               ListItem(typedDeclaration(t(S:Set,
               bitfieldType(T:Type, N':Int)), X:Id))
               L:List) 
          => ListItem(typedDeclaration(t(S, bitfieldType(T, N')), X))
               fillBitHoles-aux(N +Int N', L)
          when N' =/=Int 0 
          [structural]
          
     rule [fillBitHoles-bitfield-zero]:
          fillBitHoles-aux(N:Int, ListItem(typedDeclaration(t(_, 
               bitfieldType(_:Type, N':Int)), _:Id)) L:List) 
          => ListItem(typedDeclaration(t(.Set, bitfieldType(t(.Set, unsigned-int), 
               absInt(cfg:bitsPerByte -Int (N %Int cfg:bitsPerByte)) 
               %Int cfg:bitsPerByte)), #NoName))
               fillBitHoles(L)
          when N' ==Int 0
          [structural]
     
     rule [fillBitHoles-done]:
          fillBitHoles-aux(N:Int, .List) 
          => ListItem(typedDeclaration(
               t(.Set, bitfieldType(t(.Set, unsigned-int), 
               absInt(cfg:bitsPerByte -Int (N %Int cfg:bitsPerByte))
               %Int cfg:bitsPerByte)), #NoName))
          [structural]
          
     syntax List ::= fillUnionBitHoles(List) [function]
     syntax List ::= "fillUnionBitHoles-aux" "(" Int "," List ")" [function]
     rule fillUnionBitHoles(.List) => .List
     rule fillUnionBitHoles(ListItem(K:K) L:List) 
          => fillUnionBitHoles-aux(0, ListItem(K) L)
     rule fillUnionBitHoles-aux(N:Int, 
               ListItem(typedDeclaration(T:Type, X:Id)) L:List) 
          => ListItem(typedDeclaration(T, X))
               fillUnionBitHoles-aux(N, L)
          when notBool isBitfieldType(T)
          [structural]
     rule fillUnionBitHoles-aux(N:Int, ListItem(typedDeclaration(t(S:Set, 
               bitfieldType(T:Type, N':Int)), X:Id)) L:List) 
          => ListItem(typedDeclaration(t(S, bitfieldType(T, N')), X))
               fillUnionBitHoles-aux(maxInt(N, N'), L)
          [structural]
     rule fillUnionBitHoles-aux(N:Int, .List) 
          => ListItem(typedDeclaration(t(.Set, bitfieldType(t(.Set, unsigned-int), 
               N +Int (absInt(cfg:bitsPerByte -Int 
               (N %Int cfg:bitsPerByte)) %Int cfg:bitsPerByte))), #NoName))
          [structural]
     
     // TODO(chathhorn): this surely doesn't work.
     rule ListItem(typedDeclaration(t(_, bitfieldType(_, N:Int)), #NoName))
          ListItem(typedDeclaration(t(_, bitfieldType(_, N':Int)), #NoName))
          => ListItem(typedDeclaration(t(.Set, bitfieldType(t(.Set, unsigned-int),
               N +Int N')), #NoName))
          [structural, anywhere]
     
     
     syntax K ::= "structDef'" "(" Id "," AggInfo ")"
                | "unionDef'" "(" Id "," AggInfo ")"

     rule structDef'(X:Id, Info:AggInfo)
          => addAgg(X, bitSizeofStruct(Info), Info)
          ~> giveType(X, t(.Set, structType(X, bitSizeofStruct(Info))))
          [structural]

     rule unionDef'(X:Id, Info:AggInfo)
          => addAgg(X, bitSizeofUnion(Info), Info)
          ~> giveType(X, t(.Set, unionType(X, bitSizeofUnion(Info))))
          [structural]

     syntax K ::= addGlobalAggregate(Id, Int, AggInfo)
                | addLocalAggregate(Id, AggInfo)

     syntax AggInfo ::= "makeStructAggInfo'" "(" List "," Int "," Map ","  Map "," List ")"
                         [function]
     rule makeStructAggInfo(L:List) 
          => makeStructAggInfo'(L:List, 0, .Map, .Map, L:List)
          when L:List =/=List .List
     rule makeStructAggInfo'(
               ListItem(typedDeclaration(T:Type, Field:Id)) L:List
               , V:Int
               , Types:Map
               , Offsets:Map
               , L':List
          )
          => makeStructAggInfo'(L, V +Int bitSizeofType(T),
               Types:Map[T / Field], Offsets:Map[V / Field], L')
     rule makeStructAggInfo'(.List, _, Types:Map, Offsets:Map, L:List) 
          => aggInfo(L, Types, Offsets)

     syntax AggInfo ::= "makeUnionAggInfo'" "(" List "," Map ","  Map "," List ")"
                         [function]
     
     rule makeUnionAggInfo(L:List) 
          => makeUnionAggInfo'(L, .Map, .Map, L)
          when L =/=List .List
     rule makeUnionAggInfo'(
               ListItem(typedDeclaration(T:Type, Field:Id)) L:List
               , Types:Map
               , Offsets:Map
               , L':List
          ) 
          => makeUnionAggInfo'(L,
               Types:Map[T / Field], Offsets:Map[0 / Field],
               L')
     rule makeUnionAggInfo'(.List, Types:Map, Offsets:Map, L:List) 
          => aggInfo(L, Types, Offsets)

     syntax K ::= addAgg(Id, Int, AggInfo)
     rule <k> addAgg(S:Id, NBits:Int, Info:AggInfo)
               => addGlobalAggregate(S, NBits, Info)
          ...</k>
          <curr-function> file-scope </curr-function>
          [structural]        
     rule <k> addAgg(S:Id, _, Info:AggInfo)
               => addLocalAggregate(S, Info)
          ...</k>
          <curr-function> F:Id </curr-function>
          when F =/=K file-scope
          [structural]        

     rule <k> addGlobalAggregate(X:Id, NBits:Int, Agg:AggInfo)
               => completeAggInExtDecls(X, NBits, keys Exts)
               ~> completeAggInIntDecls(X, NBits, keys Ints)
               ~> completeAggInTypes(X, NBits, keys GTypes)
               ~> completeAggInAggs(X, NBits, keys Structs)
          ...</k>
          <curr-tu> Tu:String </curr-tu>
          <tu-id> Tu </tu-id>
          <gtypes> GTypes:Map </gtypes>
          <structs> Structs:Map => Structs:Map[Agg / X] </structs>
          <gstructs> GStructs:Map => GStructs:Map[Agg / X] </gstructs>
          <externals> Exts:Map </externals>
          <internals> Ints:Map </internals>
          <incomplete-aggs>... SetItem(X) => .Set ...</incomplete-aggs>
          [structural]

     rule <k> addGlobalAggregate(X:Id, _, Agg:AggInfo) => . ...</k>
          <curr-tu> Tu:String </curr-tu>
          <tu-id> Tu </tu-id>
          <structs> Structs:Map => Structs:Map[Agg / X] </structs>
          <gstructs> GStructs:Map => GStructs:Map[Agg / X] </gstructs>
          <incomplete-aggs> Incs:Set </incomplete-aggs>
          when notBool (X in Incs)
          [structural]
     rule <k> addLocalAggregate(X:Id, Agg:AggInfo) => . ...</k>
          <structs> Structs:Map => Structs:Map[Agg / X] </structs>
          [structural]

     // TODO(chathhorn): I just don't know.
     // Re-evaluate declarations that can now be allocated...
     syntax K ::= completeAggInExtDecls(Id, Int, Set)
     rule <k> (.K => doDeclare(
                    typedDeclaration(completeAgg(Tag, NBits, T), X), NoInit))
               ~> completeAggInExtDecls(Tag:Id, NBits:Int,
                    (SetItem(X:Id) => .Set) _)
          ...</k>
          <curr-tu> Tu:String </curr-tu>
          <tu-id> Tu:String </tu-id>
          <externals>...
               X |-> declState(_, T:Type, declared, _)
          ...</externals>
          when notBool isIncompleteType(completeAgg(Tag, NBits, T))
     rule <k> completeAggInExtDecls(Tag:Id, NBits:Int, (SetItem(X:Id) => .Set) _)
          ...</k>
          <curr-tu> Tu:String </curr-tu>
          <tu-id> Tu:String </tu-id>
          <externals>...
               X |-> declState(_, T:Type, declared, _)
          ...</externals>     
          when isIncompleteType(completeAgg(Tag, NBits, T))
     rule completeAggInExtDecls(_, _, .Set) => .K

     syntax K ::= completeAggInIntDecls(Id, Int, Set)
     rule <k> (.K => doDeclare(
                    typedDeclaration(t(.Set,
                         qualifiedType(completeAgg(Tag, NBits, T), Static)), X),
                         NoInit))
               ~> completeAggInIntDecls(Tag:Id, NBits:Int,
                    (SetItem(X:Id) => .Set) _)
          ...</k>
          <curr-tu> Tu:String </curr-tu>
          <tu-id> Tu:String </tu-id>
          <internals>...
               X |-> declState(_, T:Type, declared, _)
          ...</internals>     
          when notBool isIncompleteType(completeAgg(Tag, NBits, T))
     rule <k> completeAggInIntDecls(Tag:Id, NBits:Int, (SetItem(X:Id) => .Set) _)
          ...</k>
          <curr-tu> Tu:String </curr-tu>
          <tu-id> Tu:String </tu-id>
          <internals>...
               X |-> declState(_, T:Type, declared, _)
          ...</internals>     
          when isIncompleteType(completeAgg(Tag, NBits, T))
     rule completeAggInIntDecls(_, _, .Set) => .K

     syntax K ::= completeAggInTypes(Id, Int, Set)
     rule <k> completeAggInTypes(S:Id, NBits:Int, (SetItem(X:Id) => .Set)  _)
          ...</k>
          <gtypes>...
               X |-> (T:Type => completeAgg(S, NBits, T))
          ...</gtypes>
          [structural]
     rule completeAggInTypes(_, _, .Set) => .K
          [structural]

     syntax K ::= completeAggInAggs(Id, Int, Set)
     rule <k> (.K => completeAggInAgg(S, NBits, S2, keys(Fields)))
               ~> completeAggInAggs(S:Id, NBits:Int, (SetItem(S2:Id) => .Set)  _)
          ...</k>
          <curr-tu> Tu:String </curr-tu>
          <tu-id> Tu </tu-id>
          <gstructs>...
               S2 |-> aggInfo(_, Fields:Map, _)
          ...</gstructs>
          [structural]
     rule completeAggInAggs(_, _, .Set) => .K
          [structural]

     syntax K ::= completeAggInAgg(Id, Int, Id, Set)
     rule <k> completeAggInAgg(S:Id, NBits:Int, S2:Id, (SetItem(F:Id) => .Set)  _)
          ...</k>
          <curr-tu> Tu:String </curr-tu>
          <tu-id> Tu </tu-id>
          <gstructs>...
               S2 |-> aggInfo(_, _ F |-> (T:Type => completeAgg(S, NBits, T)), _)
          ...</gstructs>
          [structural]
     rule completeAggInAgg(_, _, _, .Set) => .K
          [structural]

     // *** TODO *** End Struct/UnionDef *** TODO ***


endmodule
