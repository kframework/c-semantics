module C-DECLARATION-GLOBAL-SYNTAX
     syntax Linkage ::= "external" | "internal"
     syntax K ::= declareFunction(Id, Type, K)
     syntax K ::= verifyDecl(K) [strict]
     //syntax K ::= preDefined(K, SymLoc, Type)

     syntax Bool ::= isNaked(Type) [function]

     syntax DeclState ::= "declared" | "completed" 
                        | "allocated" | "initialized"
     syntax K ::= declState(SymLoc, Type, DeclState)
endmodule

module C-DECLARATION-GLOBAL
     imports C-DECLARATION-GLOBAL-SYNTAX
     imports C-DECLARATION-LOCAL-SYNTAX
     imports C-DECLARATION-GENERAL-SYNTAX
     imports C-DECLARATION-SYNTAX
     imports C-TYPING-SYNTAX

     imports C-MEMORY-ALLOC-SYNTAX

     imports C-SYNTAX
     imports C-DYNAMIC-SYNTAX
     imports C-SYMLOC-SYNTAX

     imports COMPAT-SYNTAX

     rule doDeclare(T:Type, K:K) 
          => verifyDecl(T) ~> doDeclare'(T, K)

     syntax K ::= "doDeclare'" "(" Type "," K ")" 

     rule <k> doDeclare'(typedDeclaration(T:Type, X:Id), K:K) 
               => declareInternalVariable(X, T, K)
          ...</k>
          <currentFunction> F:K </currentFunction>
          when F =/=K file-scope
          [structural] 
          
     // function declaration
     rule <k> doDeclare'(typedDeclaration(T:Type, X:Id), K:K) 
               => declareFunction(X, T, K)
          ...</k>
          <currentFunction> file-scope </currentFunction>
          // I'd like to get rid of this cleanly
          when notBool isIncompleteType(T)
               andBool isFunctionType(T)
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
          
     //- external variables
     // feature request : nice to have MapList

     // function definition
     rule declareFunction(X:Id, T:Type, K:K)
          => declareExternalVariable(X, T, K)
          when K =/=K NoInit
               andBool (getQualifiers(T) ==Set .Set)
          [structural] 

     rule declareFunction(X:Id, T:Type, NoInit)
          => declareExternalVariable(X,
               t(.Set, prototype(T)), NoInit)
          when getQualifiers(T) ==Set .Set
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
     // encountered, but it was qualified extern, and extern-qualified
     // declarations never cause an allocation (according to our semantics).
     //
     // allocated: once we have a complete type for a symbol, we can allocate
     // memory as long as we have encountered at least one non-extern
     // declaration of that symbol.
     //
     // initialized: if a declaration includes an initializer, its type must
     // necessarily be complete and we can therefore allocate memory for it. We
     // also need to keep track of the initialzed status in order to prevent
     // multiple initiaizations of the same symbol (gcc/clang call this
     // "multiple definitions").
     //
     // TODO(chathhorn): We also need to keep track of the type completion
     // status of symbols with external linkage on a per-TU basis. Otherwise,
     // the type of external symbols will depend on the order in which files
     // are processed.
     //
     
     // That is, no storage class specifier.
     rule isNaked(T:Type) 
          => notBool (isExternType(T) orBool isStaticType(T))

     // Static or extern, previously declared static.
     rule <k> declareExternalVariable(X:Id, T:Type, K:K)
               => declareExternalVariable'(figureInit(X, unqualifyType(T), K), 
                    Loc, State, internal, isExternType(T))
          ...</k>
          <internals>...
               Tu |-> map(_ (X |-> declState(Loc:SymLoc, _, State:DeclState)))
          ...</internals>
          <currTU> Tu:K </currTU>
          when notBool isNaked(T)
          [structural]

     // Naked, previously declared extern.
     rule <k> declareExternalVariable(X:Id, T:Type, K:K)
               => addToEnv(X, Loc)
               ~> giveType(X, OldT) // Tentative type.
               ~> declareExternalVariable'(figureInit(X, unqualifyType(T), K), 
                    Loc, State, external, false)
          ...</k>
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
          <externals>... 
               X |-> declState(Loc:SymLoc, OldT:Type, State:DeclState) 
          ...</externals>
          <internals>...
               Tu |-> map(Ints:Map)
          ...</internals>
          <currTU> Tu:K </currTU>
          when isExternType(T) 
               andBool notBool (X in keys Ints)
          [structural]

     // Naked or extern, not previously declared.
     rule <k> declareExternalVariable(X:Id, T:Type, K:K)
               => addToEnv(X, Loc)
               ~> giveType(X, unqualifyType(T)) // Tentative type.
               ~> declareExternalVariable'(figureInit(X, unqualifyType(T), K), 
                    Loc, declared, external, isExternType(T))
          ...</k>
          <nextSharedLoc> Loc:SymLoc => linc(Loc) </nextSharedLoc>
          <externals> 
               Exts:Map (. => X |-> declState(Loc, unqualifyType(T), declared))
          </externals>
          <internals>...
               Tu |-> map(Ints:Map)
          ...</internals>
          <currTU> Tu:K </currTU>
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
          <nextSharedLoc> Loc:SymLoc => linc(Loc) </nextSharedLoc>
          <internals>...
               Tu |-> map(Ints:Map 
                    (. => X |-> declState(Loc, unqualifyType(T), declared)))
          ...</internals>
          <currTU> Tu:K </currTU>
          when isStaticType(T)
               andBool notBool (X in keys Ints)
          [structural]

     // Now we just need to handle allocation, initialization, and updating the
     // declState, when necessary.
     // The last argument might be called "isExtern" or "don't allocate".
     syntax K ::= "declareExternalVariable'" "(" K "," SymLoc "," DeclState "," Linkage "," Bool")" [strict(1)]

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
          ~> updateDecl(X, T, allocated, Lnk)
          when notBool isIncompleteType(T)
          [structural]

     // declared => completed
     rule declareExternalVariable'(initValue(X:Id, T:Type, .K), 
               _, declared, Lnk:Linkage, true)
          => giveType(X, T)
          ~> updateDecl(X, T, completed, Lnk)
          when notBool isIncompleteType(T)
          [structural]

     // Already encountered a completed decl, no init.
     // completed => allocated
     rule declareExternalVariable'(initValue(X:Id, T:Type, .K), 
               Loc:SymLoc, completed, Lnk:Linkage, false)
          => allocateDecl(X, T, Loc)
          ~> updateDecl(X, T, allocated, Lnk)
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
          ~> updateDecl(X, T, initialized, Lnk)
          when K =/=K .K
          [structural]

     // completed => initialized
     rule declareExternalVariable'(initValue(X:Id, T:Type, K:K), 
               Loc:SymLoc, completed, Lnk:Linkage, _)
          => allocateDecl(X, T, Loc)
          ~> K
          ~> updateDecl(X, T, initialized, Lnk)
          when K =/=K .K
          [structural]

     // allocated => initialized
     rule declareExternalVariable'(initValue(X:Id, T:Type, K:K), 
               _, allocated, Lnk:Linkage, _)
          => K
          ~> updateDecl(X, T, initialized, Lnk)
          when K =/=K .K
          [structural]

     syntax K ::= updateDecl(Id, Type, DeclState, Linkage)
     rule <k> updateDecl(X:Id, T':Type, S:DeclState, external) => . ...</k>
          <externals>... X |-> declState(_, (T:Type => T'), (_ => S)) ...</externals>
          when isTypeCompatible(T, T')
          [structural]
     rule <k> updateDecl(X:Id, T':Type, S:DeclState, internal) => . ...</k>
          <internals>...
               Tu |-> map(_ (X |-> declState(_, (T:Type => T'), (_ => S))))
          ...</internals>
          <currTU> Tu:K </currTU>
          when isTypeCompatible(T, T')
          [structural]
   
     syntax K ::= allocateDecl(Id, Type, SymLoc) [function]
     rule allocateDecl(_, T:Type, _)
          => .
          when isFunctionType(T)
     rule allocateDecl(X:Id, T:Type, Loc:SymLoc) 
          => allocateType(Loc, T) 
          ~> zero(X)
          when notBool isFunctionType(T)

   //   // id, type, possible init, linkage (external, internal)
   //   syntax K ::= declareWithLinkage(Id, Type, K, Linkage)
   //   
   //   rule <k> declareWithLinkage(X:Id, T:Type, K:K, L:Linkage)
   //             => declareAndDefine(X, T, K, L)
   //        ...</k>
   //        <declarationOrder>...
   //             Tu |-> ListToK(_ (. => ListItem(X)))
   //        ...</declarationOrder>
   //        <currTU> Tu:K </currTU>
   //        [structural] 

     // syntax K ::= declareOnly(Id, Type, Linkage)
     // 
     // // fixme unqualifying these is probably unsafe
     // rule <k> declareOnly(X:Id, T:Type, external)
     //           => .K
     //      ...</k>
     //      <preLinkage>...
     //           Tu |-> map((LinkageMap:Map => LinkageMap[external / X]))
     //      ...</preLinkage>
     //      <preTypes>...
     //           Tu |-> map((TypesMap:Map => TypesMap[T / X]))
     //      ...</preTypes>
     //      <currTU> Tu:K </currTU>
     //      when ((notBool $hasMapping(LinkageMap, X))
     //                orElseBool (LinkageMap(X) ==K external)
     //           ) andBool (
     //                (notBool $hasMapping(TypesMap, X))
     //                orElseBool isTypeCompatible(unqualifyType(TypesMap(X)),
     //                     unqualifyType(T))
     //           )
     //      [structural] 
     //      
     // rule <k> declareOnly(X:Id, t(_, prototype(T:Type)), external)
     //           => .K
     //      ...</k>
     //      <preLinkage>...
     //           Tu |-> map((Lnk:Map => Lnk:Map[external / X]))
     //      ...</preLinkage>
     //      <preTypes>... Tu:K |-> map(Types:Map) ...</preTypes>
     //      <currTU> Tu:K </currTU>
     //      when (notBool $hasMapping(Lnk, X:Id) 
     //                orBool Lnk:Map(X) ==K external
     //           )
     //           andBool isTypeCompatible(unqualifyType(Types:Map(X)),
     //                unqualifyType(T))
     //      [structural]
     // 
     // // fixme haven't thought about this much, is it right_
     // rule <k> declareOnly(X:Id, T:Type, internal)
     //           => .K
     //      ...</k>
     //      <preLinkage>...
     //           Tu |-> map((Lnk:Map => Lnk:Map[internal / X]))
     //      ...</preLinkage>
     //      <preTypes>...
     //           Tu |-> map((Types:Map => Types:Map[T / X]))
     //      ...</preTypes>
     //      <currTU> Tu:K </currTU>
     //      when notBool $hasMapping(Lnk, X:Id) 
     //           orBool Lnk:Map(X) ==K internal
     //      [structural] 
     
     /*@ \fromStandard{\source[n1570]{\para{6.2.2}{4}}}{
     For an identifier declared with the storage-class specifier
     \cinline{extern} in a scope in which a prior declaration of that
     identifier is visible, if the prior declaration specifies internal or
     external linkage, the linkage of the identifier at the later declaration
     is the same as the linkage specified at the prior declaration. If no prior
     declaration is visible, or if the prior declaration specifies no linkage,
     then the identifier has external linkage. 
     }*/
     // exception to multiple definitions for functions since we consider
     // prototypes to be definitions to some extent
     // case when it has no previous linkage, or previous linkage is external

   //  syntax K ::= declareAndDefine(Id, Type, K, Linkage)

   //  syntax K ::= preDefine(K, SymLoc, Linkage, K) [strict(4)]
   //             | addDef(Id, K, K, Linkage)

   //  rule preDefine(Tu:K, Loc:SymLoc, Lnk:Linkage, initValue(X:Id, T:Type, K:K))
   //       => allocateType(Loc, T)
   //       ~> addToEnv(X, Loc)
   //       ~> giveType(X, T)
   //       ~> zero(X)
   //       ~> K
   //       ~> addDef(X, Tu, preDefined(Tu, Loc, T), Lnk)
   //       when K =/=K .K
   //       [structural]

   //  rule preDefine(Tu:K, Loc:SymLoc, Lnk:Linkage, initValue(X:Id, T:Type, .K))
   //       => addToEnv(X, Loc)
   //       ~> giveType(X, T)
   //       [structural]

   //  rule <k> addDef(X:Id, _, Def:K, external) => . ...</k>
   //       <externalDefinitions> 
   //            _:Map (. => (X |-> Def))
   //       </externalDefinitions>
   //       [structural]

   //  rule <k> addDef(X:Id, Tu:K, Def:K, internal) => . ...</k>
   //       <internalDefinitions>...
   //            Tu |-> map(_:Map (. => (X |-> Def)))
   //       ...</internalDefinitions>
   //       [structural]

   //  rule <k> declareAndDefine(X:Id, T:Type, K:K, external)
   //            => preDefine(Tu, Loc, external, 
   //                 figureInit(X, unqualifyType(T), K))
   //       ...</k>
   //       <externalDefinitions> 
   //            Def:Map
   //       </externalDefinitions>
   //       <preLinkage>...
   //            Tu |-> map((Lnk:Map => Lnk:Map[external / X]))
   //       ...</preLinkage>
   //       <nextSharedLoc> Loc:SymLoc => linc(Loc) </nextSharedLoc>
   //       <externalLocations>... (. => X |-> Loc) </externalLocations>
   //       <currTU> Tu:K </currTU>
   //       when (notBool $hasMapping(Def, X)
   //                 orBool isFunctionType(T))
   //            andBool (notBool $hasMapping(Lnk, X) 
   //                 orBool Lnk:Map(X) ==K external)
   //       [structural, large]
   //       
   //  // case when it has a previous linkage (internal).  
   //  rule <k> declareAndDefine(X:Id, T:Type, K:K, external)
   //            => preDefine(Tu, Loc, internal, 
   //                 figureInit(X, unqualifyType(T), K))
   //       ...</k>
   //       <internalDefinitions>... 
   //            Tu |-> map(Def:Map) 
   //       ...</internalDefinitions>
   //       <preLinkage>... Tu:K |-> map(Lnk:Map) ...</preLinkage>
   //       <nextSharedLoc> Loc:SymLoc => linc(Loc) </nextSharedLoc>
   //       <currTU> Tu:K </currTU>
   //       when (notBool $hasMapping(Def, X) orBool isFunctionType(T))
   //            andBool Lnk:Map(X) ==K internal
   //       [structural, large]
   //       
   //  rule <k> declareAndDefine(X:Id, T:Type, K:K, internal)
   //            => preDefine(Tu, Loc, internal, 
   //                 figureInit(X, unqualifyType(T), K))
   //       ...</k>
   //       <internalDefinitions>... 
   //            Tu |-> map(Def:Map) 
   //       ...</internalDefinitions>
   //       <preLinkage>...
   //            Tu |-> map((Lnk:Map => Lnk:Map[internal / X]))
   //       ...</preLinkage>
   //       <nextSharedLoc> Loc:SymLoc => linc(Loc) </nextSharedLoc>
   //       <currTU> Tu:K </currTU>
   //       when (notBool $hasMapping(Def, X) 
   //                 orBool isFunctionType(T))
   //            andBool (notBool $hasMapping(Lnk, X)
   //                 orBool Lnk:Map(X) ==K internal)
   //       [structural, large]
          
endmodule
