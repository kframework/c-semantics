module CPP-TRANSLATION-DECL-CLASS-SYNTAX
     imports BOOL-SYNTAX
     imports LIST
     imports SET
     imports COMMON-SORTS
     imports CPP-SORTS
     imports CPP-CLASS-SORTS
     imports CPP-DYNAMIC-SORTS
     imports CPP-TYPING-SORTS
     imports SYMLOC-SORTS
     syntax AType ::= declareClassName(Tag, CId, Bool)

     syntax KItem ::= classContext(AType, List, List) [strict(1)]

     // these functions don't check for whether or not it's a constructor and
     // therefore should only be called after we know that something is a
     // constructor. The exception is hasConstructorThat which checks
     // whether any constructor in a given class meets the specified constructor
     // property.
     // Atomic constructor properties
     syntax TypePredicate ::= "isTrivialDefaultConstructor"
                            | "isNonTrivialDefaultConstructor"
                            | "isDefaultConstructor"
                            | "isCopyConstructor"
                            | "isConstCopyConstructor"
                            | "isMoveConstructor"
                            | "isUserProvidedConstructor"
                            | "isUserProvidedDefaultConstructor"
                            | "isDeleted"
                            | "isDeletedDefaultConstructor"
                            | "isNonTrivialDestructor"
                            | "isTrivialDestructor"
                            | "isUserProvidedDestructor"
                            | "isVirtualDestructor"

     // Compound constructor properties
     syntax TypePredicate ::= "isUserProvidedMoveConstructor"
                            | "isUserProvidedCopyConstructor"

     // Atomic method properties
     syntax TypePredicate ::= "isCopyAssignOp"

     // Compound method properties
     syntax TypePredicate ::= "isUserProvidedMoveAssignOp"

     // Class queries for constructors and other methods
     syntax TypePredicate ::= "hasConstructorThat"
                            | "hasDestructorThat"

     syntax Bool ::= ClassPredicate "(" Class ")" [function]

     syntax Bool ::= hasConstructorThat(Class, TypePredicate) [function, klabel(hasConstructorThat2)]
                   | hasDestructorThat(Class, TypePredicate) [function, klabel(hasDestructorThat2)]
     syntax ClassPredicate ::= "hasCopyConstructor"
                             | "hasConstCopyConstructor"
                             | "hasVirtualDestructor"
                             | "hasUserProvidedMoveAssignOp"
                             | "hasUserProvidedMoveConstructor"
                             | "hasUserProvidedCopyConstructor"
     syntax Bool ::= some(List, ClassPredicate) [function, klabel(someClass), prefer]

     syntax Bool ::= isPODLayoutType(CPPType) [function]

     syntax List ::= "Class.getNonStaticDataMembers" "(" ClassInfo ")" [function]

     syntax Map ::= "Class.getDataMembersInitializers" "(" ClassInfo ")" [function]

endmodule

module CPP-TRANSLATION-DECL-CLASS-DESTRUCTOR-SYNTAX
     imports CPP-TRANSLATION-DECL-CLASS-SYNTAX

     syntax KItem ::= "Class.potentiallyInvokeDestructor" "(" Class ")"
                    | "Class.invokeDestructor" "(" Class ")"

endmodule

module CPP-TRANSLATION-DECL-CLASS-DESTRUCTOR
     imports CPP-TRANSLATION-DECL-CLASS-DESTRUCTOR-SYNTAX
     imports CPP-TRANSLATION-ODR-SYNTAX
     imports CPP-SYNTAX // DestructorId
     imports CPP-CLASS-BASIC-SYNTAX
     imports CPP-SYMLOC-SYNTAX // envEntry, SymBase
     imports C-CONFIGURATION
     imports CPP-TYPE-MAP-SYNTAX

     // @ref N4296 3.2/3
     // @ref N4778 6.2/8
     // <quote>
     // [...] A destructor for a class is odr-used if it is potentially invoked.
     // </quote>
     rule <k> Class.potentiallyInvokeDestructor((_ :: Class(_, X::CId, _)) #as C::Class) => Odr.newUse(Base) ...</k>
          <curr-tr-tu> Tu::String </curr-tr-tu>
          <tu-id> Tu </tu-id>
          <class-id> C </class-id>
          <cenv>... DestructorId(X) |-> (_::CPPType |-> (_, envEntry(... base: Base::SymBase))) ...</cenv>

     // @ref N4296 12.4/11
     // @ref N4778 10.3.6/12
     // <quote>
     // A destructor is potentially invoked if it is invoked or as specified in [...]
     // </quote>
     rule Class.invokeDestructor(C::Class) => Class.potentiallyInvokeDestructor(C)

endmodule

module CPP-TRANSLATION-DECL-CLASS
     imports CPP-TRANSLATION-DECL-CLASS-SYNTAX
     imports C-CONFIGURATION
     imports K-REFLECTION
     imports MAP
     imports COMMON-SYNTAX
     imports COMPAT-SYNTAX
     imports SETTINGS-SYNTAX
     imports CPP-ABSTRACT-SYNTAX
     imports CPP-ALIGNMENT-SYNTAX
     imports CPP-BITSIZE-SYNTAX
     imports CPP-CLASS-SYNTAX
     imports CPP-TRANSLATION-DECL-DECLARATOR-SYNTAX
     imports CPP-TRANSLATION-DECL-INITIALIZER-SYNTAX
     imports CPP-DYNAMIC-SYNTAX
     imports CPP-TRANSLATION-ELABORATOR-SYNTAX
     imports CPP-TRANSLATION-ENV-SYNTAX
     imports CPP-TRANSLATION-EXPR-NEW-SYNTAX
     imports CPP-TRANSLATION-OVERLOADING-SYNTAX
     imports CPP-SYMLOC-SYNTAX
     imports CPP-SYNTAX
     imports CPP-SYMLOC-SYNTAX
     imports CPP-TRANSLATION-NAME-SYNTAX
     imports CPP-TYPE-MAP-SYNTAX
     imports CPP-TRANSLATION-TYPING-EXPR-SYNTAX
     imports CPP-TYPING-SYNTAX
     imports CPP-TRANSLATION-VALUE-CATEGORY-SYNTAX
     imports CPP-TRANSLATION-DECL-CLASS-DESTRUCTOR

     rule TypeDecl(ElaboratedTypeSpecifier(T:ClassKey, X::CId, NoNNS()) => declareClassName(T, X, true))

     context TypeDecl(HOLE:AType)
             requires notBool isClassNameElabSpecifier(HOLE) [result(CPPType)]

     syntax Bool ::= isClassNameElabSpecifier(K) [function]

     rule isClassNameElabSpecifier(ElaboratedTypeSpecifier(_:ClassKey, _, NoNNS())) => true

     rule isClassNameElabSpecifier(_) => false [owise]

     rule <k> declareClassName(T::Tag, X::CId, true) => t(noQuals, .Set, classType(N :: Class(T, X, .TemplateArgs))) ...</k>
          <curr-tr-scope> namespaceScope(N::Namespace) </curr-tr-scope>

     rule <k> declareClassName(T::Tag, X::CId, true) => t(noQuals, .Set, classType(C :: Class(T, X, .TemplateArgs))) ...</k>
          <curr-tr-scope> classScope(C::Class, _) </curr-tr-scope>

     rule <k> TypeDecl(t(_, _, classType(N::Namespace :: Class(ClassKey::Tag, X::CId, _))) #as T::CPPType) => .K ...</k>
          <curr-template-context> noTemplate </curr-template-context>
          <curr-tr-tu> Tu::String </curr-tr-tu>
          <tu-id> Tu </tu-id>
          <ns-id> N </ns-id>
          <ntypes> NT::Map => NT[X <- T] </ntypes>

     rule <k> TypeDecl(t(_, _, classType(C::Class :: Class(ClassKey::Tag, X::CId, _))) #as T::CPPType) => .K ...</k>
          <curr-template-context> noTemplate </curr-template-context>
          <curr-tr-tu> Tu::String </curr-tr-tu>
          <tu-id> Tu </tu-id>
          <class-id> C </class-id>
          <ctypes> CT::Map => CT[X <- T] </ctypes>

     rule ClassDef(T:ClassKey, X::CId, NoNNS(), Bases::List, Members::List, IsAnon:Bool) => classContext(declareClassName(T, X, true), Bases, Members)
          requires notBool IsAnon orBool T =/=K Union()

     rule ClassDef(Union(), X::CId, NoNNS(), Bases::List, Members::List, true)
          => DeclaratorAndSpecifiers(defAnonymousUnion(declareClassName(Union(), X, true), Bases, Members), .Set)

     syntax Declarator ::= defAnonymousUnion(AType, List, List)

     context DeclaratorAndSpecifiers(defAnonymousUnion(HOLE:AType,_,_), _)

     rule DeclaratorAndSpecifiers(defAnonymousUnion(t(... st: classType(C::Class)) #as T::CPPType, Bases::List, Members::List), S::Set)
          => classContext(T, Bases, Members) ~> defineUnnamedObject(C, S) ~> addMembersToScope(C)

     rule NoDecl() => .K

     syntax KItem ::= defineUnnamedObject(Class, Set)

     rule <k> defineUnnamedObject(C::Class, S::Set)
           => #if isClassScope(Scope)
              #then FieldDecl(NoNNS(), unnamedObject(C), type(classType(C)), NoInit())
              #else
              DeclaratorAndSpecifiers(
                VarDecl(getNNSVal(Scope), unnamedObject(C), #NoName, type(classType(C)), NoInit(), false),
                #if isNamespaceScope(Scope)
                #then SetItem(Static()) S // kast does not add Specifiers if in namespaceScope
                #else S
                #fi
              )
              #fi ...</k>
          <curr-tr-scope> Scope::Scope </curr-tr-scope>

     syntax KItem ::= addMembersToScope(Class)

     rule <k> addMembersToScope(C::Class) => addMembersToScope(C, Members) ...</k>
          <class-id> C </class-id>
          <non-static-data-members> Members::List </non-static-data-members>

     syntax KItem ::= addMembersToScope(Class, List)

     rule addMembersToScope(_, .List) => .K

     // TODO(traiansf): propagate addToEnv upward if getNNSVal(Scope) is an anonymous union.
     rule <k> (.K => addToEnv(getNNSVal(Scope) :: X, T, memberBase(unnamedObject(C), X, T), false))
           ~> addMembersToScope(C::Class, (ListItem(Class.DataMember(X::CId, T::CPPType)) => .List) _)
          ...</k>
          <curr-tr-scope> Scope::Scope </curr-tr-scope>

     syntax KItem ::= "Class.Declare.addToEnv" "(" Class ")"

     //TODO(jantusil) Reduce the duplication between the following two rules

     rule <k> Class.Declare.addToEnv((N::Namespace :: Class(_, X::CId, _)) #as C::Class) => .K ...</k>
          <curr-tr-tu> Tu::String </curr-tr-tu>
          <tu-id> Tu </tu-id>
          <ns-id> N </ns-id>
          <ntypes> NT::Map => NT[X <- type(classType(C))] </ntypes>

     rule <k> Class.Declare.addToEnv((C2::Class :: Class(_, X::CId, _)) #as C::Class) => .K ...</k>
          <curr-tr-tu> Tu::String </curr-tr-tu>
          <tu-id> Tu </tu-id>
          (<class-id> C2 </class-id>
          <ctypes> CT::Map => CT[X <- type(classType(C))] </ctypes>)

     rule <k> classContext(t(_, _, classType((_ :: Class(ClassKey::Tag, X::CId, _)) #as C::Class)) #as T::CPPType, Bases::List, Members::List)
              => Class.Declare.addToEnv(C)
              ~> setScope(classScope(C, false))
              ~> listToK(Bases)
              ~> setScope(classScope(C, true))
              ~> listToK(Members)
              ~> implicitDeclarations()
              ~> implicitDeclarationOfCopyConstructor(C)
              ~> deferredActions(OldClass)
              ~> setScope(OldScope)
          ...</k>
          <deferred-class-actions> OldClass:K => layoutBases(.List, .List) |> layoutVirtualBases(.List) |> .K |> .Ordering </deferred-class-actions>
          <curr-template-context> noTemplate </curr-template-context>
          <curr-tr-scope> OldScope::Scope </curr-tr-scope>
          <curr-tr-tu> Tu::String </curr-tr-tu>
          <tu-id> Tu </tu-id>
          (.Bag => <class>...
            <class-id> C </class-id>
            <class-type> ClassKey </class-type>

            // injected class name
            <ctypes> X |-> T </ctypes>
            <access> X |-> Public() </access>
            <access-specifier> getDefaultAccessType(ClassKey) </access-specifier>
          ...</class>)

     syntax KItem ::= deferredActions(K)

     rule <k> deferredActions(OldClass:K) => Functions ...</k>
          <deferred-class-actions> Functions::Ordering => OldClass </deferred-class-actions>

     syntax KItem ::= implicitDeclarations()

     // no implicit constructor if one was already declared
     rule <k> implicitDeclarations() => .K...</k>
          <curr-tr-scope> classScope(_ :: Class(_, X::CId, _) #as C::Class, _) </curr-tr-scope>
          <curr-tr-tu> Tu::String </curr-tr-tu>
          <tu-id> Tu </tu-id>
          <class-id> C </class-id>
          <cenv>... ConstructorId(X) |-> M::Map DestructorId(X) |-> _ ...</cenv>
          <is-aggregate> B:Bool => B andBool notBool some(M, isUserProvidedConstructor) andBool notBool hasVirtualMembers(type(classType(C))) </is-aggregate>

     // TODO(dwightguth): implicit exception spec
     rule <k> (.K => AccessSpec(Public()) ~> Specifier(Inline(),
                   FunctionDefinition(NoNNS(), ConstructorId(X), #NoName,
                        MethodPrototype(false, true, type(pointerType(type(classType(C)))),
                             FunctionPrototype(type(void), list(.List), NoExceptionSpec(), false)),
                        .List, OnlyIfOdrUsed(Defaulted()))))
              ~> implicitDeclarations() ...</k>
          <curr-tr-scope> classScope(_ :: Class(_, X::CId, _) #as C::Class, _) </curr-tr-scope>
          <curr-tr-tu> Tu::String </curr-tr-tu>
          <tu-id> Tu </tu-id>
          <class-id> C </class-id>
          <cenv> Env::Map </cenv>
          requires notBool ConstructorId(X) in_keys(Env)

     // TODO odr-use destructors of members and base classes
     rule <k> (.K => AccessSpec(Public()) ~> Specifier(Inline(),
                   FunctionDefinition(NoNNS(), DestructorId(X), #NoName,
                        MethodPrototype(false, false, type(pointerType(type(classType(C)))),
                             FunctionPrototype(type(void), list(.List), NoExceptionSpec(), false)),
                        .List, Defaulted())))
              ~> implicitDeclarations() ...</k>
          <curr-tr-scope> classScope(_ :: Class(_, X::CId, _) #as C::Class, _) </curr-tr-scope>
          <curr-tr-tu> Tu::String </curr-tr-tu>
          <tu-id> Tu </tu-id>
          <class-id> C </class-id>
          <cenv> Env::Map </cenv>
          <base-classes> Bases::List </base-classes>
          requires notBool DestructorId(X) in_keys(Env)
               andBool notBool some(Bases, hasVirtualDestructor)

     rule <k> (.K => AccessSpec(Public()) ~> Specifier(Inline(),
                   FunctionDefinition(NoNNS(), DestructorId(X), #NoName,
                        MethodPrototype(false, false, type(pointerType(type(classType(C)))),
                             Virtual(FunctionPrototype(type(void), list(.List), NoExceptionSpec(), false))),
                        .List, Defaulted())))
              ~> implicitDeclarations() ...</k>
          <curr-tr-scope> classScope(_ :: Class(_, X::CId, _) #as C::Class, _) </curr-tr-scope>
          <curr-tr-tu> Tu::String </curr-tr-tu>
          <tu-id> Tu </tu-id>
          <class-id> C </class-id>
          <cenv> Env::Map </cenv>
          <base-classes> Bases::List </base-classes>
          requires notBool DestructorId(X) in_keys(Env)
               andBool some(Bases, hasVirtualDestructor)

    syntax Declarator ::= "var" "(" String ")" "ofType" "(" CPPType ")" [function]
     rule var(S::String) ofType(T::CPPType) => VarDecl(NoNNS(), Identifier(S), #NoName, T, NoInit(), false)


syntax Stmt ::= Defaulted(SpecialMemberFunction, Class) [klabel(DefaultedSMF)]
                   | Deleted(SpecialMemberFunction, Class) [klabel(DeletedSMF)]
                   | "Defaulted" "(" SpecialMemberFunction "," Class ")" "unless" "(" Bool ")" [function]

     rule Defaulted(SMF::SpecialMemberFunction, C::Class) unless(true) => OnlyIfOdrUsed(Deleted(SMF, C))
     rule Defaulted(SMF::SpecialMemberFunction, C::Class) unless(false) => OnlyIfOdrUsed(Defaulted(SMF, C))

     syntax SpecialMemberFunction ::= DefaultConstructor()
                                    | CopyConstructor()
                                    | MoveConstructor()
                                    | CopyAssignOp()
                                    | MoveAssignOp()
     //                             | Destructor() [klabel(DestructorSMF)]

     // Just a hack to support 'Defaulted(Destructor(), C)'
     syntax SpecialMemberFunction ::= Stmt

     // Just some syntactic sugar
     syntax CPPType ::= CPPType "const" [function, klabel(eastConstCPPType)]
                      | CPPSimpleType "const" [function, klabel(eastConstCPPSimpleType)]
                      | CPPType "volatile" [function, klabel(eastVolatileCPPType)]
                      | CPPSimpleType "volatile" [function, klabel(eastVolatileCPPSimpleType)]
                      | CPPType "*" [function, klabel(eastPtrToCPPType)]
                      | CPPSimpleType "*" [function, klabel(eastPtrToCPPSimpleType)]
                      | CPPType "&" [function, klabel(eastLvRefToCPPType)]
                      | CPPSimpleType "&" [function, klabel(eastLvRefToCPPSimpleType)]
                      | CPPType "&&" [function, klabel(eastRvRefToCPPType)]
                      | CPPSimpleType "&&" [function, klabel(eastRvRefToCPPSimpleType)]


     rule T::CPPType const => const(T)
     rule T::CPPSimpleType const => const(T)
     rule T::CPPType volatile => volatile(T)
     rule T::CPPSimpleType volatile => volatile(T)
     rule T::CPPType * => type(pointerType(T))
     rule T::CPPSimpleType * => type(pointerType(type(T)))
     rule T::CPPType & => type(lvRefType(T))
     rule T::CPPSimpleType & => type(lvRefType(type(T)))
     rule T::CPPType && => type(rvRefType(T))
     rule T::CPPSimpleType && => type(rvRefType(type(T)))

     syntax Block ::= EmptyBlock() [function]
     rule EmptyBlock() => BlockStmt(.List)

     syntax KItem ::= implicitDeclarationOfCopyConstructor(Class)
                    | implicitDeclarationOfCopyConstructor2(Class, Bool)

     // @ref n4800 12.8:8
     rule implicitDeclarationOfCopyConstructor(C::Class)
          => implicitDeclarationOfCopyConstructor2(C, eachPTSHasConstCopyConstructor(C))

     // @ref n4296 12.8:7
     rule implicitDeclarationOfCopyConstructor2(C::Class, ConstCopyConstructor:Bool)
          =>
          #if hasUserProvidedCopyConstructor(C) #then
               .K
          #else
               AccessSpec(Public()) ~>
               Specifier(
                    Inline(),
                    FunctionDefinition(
                         NoNNS(), ConstructorId(idOf(C)), #NoName,
                         MethodPrototype(
                              false, true, classType(C) *,
                              FunctionPrototype(
                                   type(void),
                                   list(ListItem(
                                        #if ConstCopyConstructor #then
                                             classType(C) const &
                                        #else
                                             classType(C) &
                                        #fi
                                   )),
                                   NoExceptionSpec(),
                                   false
                              )
                         ),
                         ListItem(
                              var("other") ofType (
                                   #if ConstCopyConstructor #then
                                        classType(C) const &
                                   #else
                                        classType(C) &
                                   #fi
                              )
                         ),
                         Defaulted(CopyConstructor(), C) unless (hasUserProvidedMoveConstructor(C) orBool hasUserProvidedMoveAssignOp(C))
                    )
               )
          #fi

     syntax KItem ::= eachPotentiallyConstructedSubobjectConstCopyable()

     rule Defaulted(CopyConstructor(), C::Class) => Constructor(copyConstructorInitializers(directBaseClassesOf(C), nonStaticDataMembersOf(C)), EmptyBlock())

     // Construct the initializer list
     syntax List ::= copyConstructorInitializers(bases: List, dataMembers: List) [function]
                   | copyConstructorInitializers2(bases: List, dataMembers: List, initializers: List) [function]

     rule copyConstructorInitializers(B::List, M::List) => copyConstructorInitializers2(B, M, .List)
     // base classes
     // N4296 12.8:15.3
     rule copyConstructorInitializers2(
          (ListItem(C::Class) => .List) _,
          _,
          (.List => ListItem(ConstructorBase(type(classType(C)), false, false, Name(NoNNS(), Identifier("other"))))) _)

     // members
     rule copyConstructorInitializers2(
          .List,
          (ListItem(Class.DataMember(X::CId, T::CPPType)) => .List) _,
          (.List => ListItem(ConstructorMember(X, copyOrMoveInitializeMember(Name(NoNNS(), Identifier("other")) . no-template Name(NoNNS(), X), T)))) _)

     // done
     rule copyConstructorInitializers2(.List, .List, I::List) => I

     syntax Bool ::= eachPTSHasConstCopyConstructor(Class) [function]
                   | #eachPTSHasConstCopyConstructor(List, List) [function]

     rule eachPTSHasConstCopyConstructor(C::Class)
          => #eachPTSHasConstCopyConstructor(directBaseClassesOf(C), nonStaticDataMembersOf(C))

     rule #eachPTSHasConstCopyConstructor(ListItem(C::Class) L::List, NSDM::List)
          => hasConstCopyConstructor(C)
          andBool #eachPTSHasConstCopyConstructor(L, NSDM)

     rule #eachPTSHasConstCopyConstructor(.List,
               (ListItem(Class.DataMember(_, T::CPPType)) => .List) _)
          requires notBool isCPPClassType(T)

     rule #eachPTSHasConstCopyConstructor(.List,
               ListItem(Class.DataMember(_, t(... st: classType(C::Class)))) L::List)
          => hasConstCopyConstructor(C)
          andBool #eachPTSHasConstCopyConstructor(.List, L)

     rule #eachPTSHasConstCopyConstructor(.List, .List) => true

     syntax Init ::= copyOrMoveInitializeMember(Expr, CPPType) [function]

     // N4296 12.8:15.1
     rule copyOrMoveInitializeMember(E::Expr, t(... st: _:CPPSimpleArrayType) #as T::CPPType) => BraceInit(copyOrMoveInitializeArrayMember(E, T))

     syntax List ::= copyOrMoveInitializeArrayMember(Expr, CPPType) [function]

     rule copyOrMoveInitializeArrayMember(_, t(... st: arrayType(_, 0))) => .List

     rule copyOrMoveInitializeArrayMember(E::Expr, t(Q::Quals, M::Set, arrayType(T::CPPType, N::Int)))
          => ListItem(copyOrMoveInitializeMember(E[prv(N -Int 1, noTrace, type(size_t))], T))
             copyOrMoveInitializeArrayMember(E, t(Q, M, arrayType(T, N -Int 1)))
          requires N >Int 0

     // N4296 12.8:15.2
     rule copyOrMoveInitializeMember(E::Expr, t(... st: rvRefType(...)) #as T::CPPType) => StaticCast(T, E)

     // N4296 12.8:15.3
     rule copyOrMoveInitializeMember(E::Expr, T::CPPType) => E [owise]

     syntax List ::= directBaseClassesOf(Class) [function]
                   | #directBaseClassesOf(K)    [function]
                   | nonStaticDataMembersOf(Class) [function]
                   | #nonStaticDataMembersOf(K) [function]

     rule directBaseClassesOf(C::Class) => #directBaseClassesOf(getClassInfo(C))
     rule #directBaseClassesOf(<class>... <base-classes> L::List </base-classes> ...</class>) => L
     rule nonStaticDataMembersOf(C::Class) => #nonStaticDataMembersOf(getClassInfo(C))
     rule #nonStaticDataMembersOf(<class>... <non-static-data-members> L::List </non-static-data-members> ...</class>) => L

     // @ref n4296 12.8:2
     // TODO: check non-template.
     // TODO function parameter packs are not allowed
     rule isCopyConstructor(
               t(... st: functionType(... paramTypes: (t(... st: lvRefType(t(... st: classType(C::Class)))), _), methodInfo: methodInfo(... class: C::Class))) #as T::CPPType,
               envEntry(... defaultArgs: DA::DefaultArgumentsResult)
          ) => acceptsNArgs(1, T, getDefaultArgsVals(DA))
     rule isCopyConstructor(_, _) => false [owise]

     rule isConstCopyConstructor(T::CPPType, K::K)
          => isCopyConstructor(T, K) andBool  isConstType(innerType(firstParamOf(T)))

     syntax CPPType ::= firstParamOf(CPPType) [function]

     rule firstParamOf(t(... st: functionType(... paramTypes: (T::CPPType, _)))) => T

     // @ref n4296 12.8:3 same as copy constructor, but rvalue reference
     rule isMoveConstructor(
               t(... st: functionType(... paramTypes: (t(... st: rvRefType(t(... st: classType(C::Class)))), _), methodInfo: methodInfo(... class: C::Class))) #as T::CPPType,
               envEntry(... defaultArgs: DA::DefaultArgumentsResult)
          ) => acceptsNArgs(1, T, getDefaultArgsVals(DA))
     rule isMoveConstructor(_, _) => false [owise]

     syntax Bool ::= isExplicitlyDeclaredCopyConstructor(CPPType, K) [function]
     rule isExplicitlyDeclaredCopyConstructor(T::CPPType, K::K) => isUserProvidedConstructor(T, K) andBool isCopyConstructor(T, K)

     syntax Stmt ::= "TwriteVTables"

     rule toExecution(TwriteVTables) => writeVTables

     rule <k> Constructor(Ctor::List, S::Stmt) => figureConstruct(Ctor, .Map, Bases, NSDM, S, elaborateThen(TwriteVTables), false) ...</k>
          <curr-tr-scope> blockScope(C::Class :: ConstructorId(_), _, _) </curr-tr-scope>
          <curr-tr-tu> Tu::String </curr-tr-tu>
          <tu-id> Tu </tu-id>
          <class-id> C </class-id>
          <base-classes> Bases::List </base-classes>
          <non-static-data-members> NSDM::List </non-static-data-members>

     rule <k> Defaulted() => Constructor(.List, BlockStmt(.List)) ...</k>
          <curr-tr-scope> blockScope(C::Class :: ConstructorId(_), _, _) </curr-tr-scope>

     syntax Stmt ::= figureConstruct(ctors: List, processedCtors: Map, bases: List, dataMembers: List, body: Stmt, result: K, hasNonConstVariantMember: Bool)

     rule figureConstruct(... ctors: (ListItem(ConstructorMember(X::CId, I::Init)) => .List) _, processedCtors: M::Map => M[X <- I])

     context figureConstruct(... ctors: ListItem(ConstructorBase(HOLE:AType, _, _, _)) _)

     rule figureConstruct(... ctors: (ListItem(ConstructorBase(t(... st: classType(C::Class)), false, false, I::Init)) => .List) _, processedCtors: M::Map => M[C <- I])

     // 12.1:4
     rule <k> figureConstruct(.List, _, .List, ListItem(Class.DataMember(X::CId, T::CPPType)) _, _, _, _) => Deleted() ...</k>
          <curr-tr-scope> blockScope(C::Class :: ConstructorId(_), Base::SymBase, _) </curr-tr-scope>
          <functions>... Base |-> functionObject(_, FuncT::CPPType, _, _) ...</functions>
          <curr-tr-tu> Tu::String </curr-tr-tu>
          <tu-id> Tu </tu-id>
          <class-id> C </class-id>
          <variant-members> VM::Set </variant-members>
          <initializers>... X |-> (stripType(T) |-> (_, I::Init)) ...</initializers>
          requires isDeletedDefaultConstructor(X, T, C, FuncT, VM, I)

     syntax KItem ::= ".Init"

     // @ref n4296 12.1:4.6-4.7
     rule <k> (.K => checkCtorAndDtor(MemInit[X] orDefault .Init, X, T, true, I, getMostDerivedArrayElement(T))) ~> figureConstruct(.List, MemInit::Map, .List, (ListItem(Class.DataMember(X::CId, T::CPPType)) => .List) _, _, _, _) ...</k>
          <curr-tr-scope> blockScope(C::Class :: ConstructorId(_), Base::SymBase, _) </curr-tr-scope>
          <functions>... Base |-> functionObject(_, FuncT::CPPType, _, _) ...</functions>
          <curr-tr-tu> Tu::String </curr-tr-tu>
          <tu-id> Tu </tu-id>
          <class-id> C </class-id>
          <variant-members> VM::Set </variant-members>
          <initializers>... X |-> (stripType(T) |-> (_, I::Init)) ...</initializers>
          requires notBool isDeletedDefaultConstructor(X, T, C, FuncT, VM, I)

     rule <k> (.K => checkCtorAndDtor(MemInit[C] orDefault .Init, baseClass(C), type(classType(C)), false, NoInit(), type(classType(C)))) ~> figureConstruct(.List, MemInit::Map, (ListItem(C::Class) => .List) _, _, _, _, _) ...</k>
          <curr-tr-scope> blockScope(_, Base::SymBase, _) </curr-tr-scope>
          <functions>... Base |-> functionObject(_, FuncT::CPPType, _, _) ...</functions>
          requires notBool isMethodUserProvided(FuncT)

     rule <k> (.K => figureConstructItem(MemInit[C] orDefault .Init, baseClass(C), type(classType(C)), false)) ~> figureConstruct(.List, MemInit::Map, (ListItem(C::Class) => .List) _, _, _, _, _) ...</k>
          <curr-tr-scope> blockScope(_, Base::SymBase, _) </curr-tr-scope>
          <functions>... Base |-> functionObject(_, FuncT::CPPType, _, _) ...</functions>
          requires isMethodUserProvided(FuncT)

     syntax K ::= checkCtorAndDtor(K, CId, CPPType, Bool, Init, CPPType) [function]

     syntax KItem ::= checkCtor(Class)
                    | checkDtor(Class)

     rule checkCtorAndDtor(K:K, X::CId, T::CPPType, B::Bool, _, M::CPPType)
          => figureConstructItem(K, X, T, B)
          requires notBool isCPPClassType(M)

     rule checkCtorAndDtor(K:K, X::CId, T::CPPType, B:Bool, I::Init, t(... st: classType(M::Class)))
          => checkCtor(M) ~> checkDtor(M) ~> figureConstructItem(K, X, T, B)
          requires notBool (B andBool I =/=K NoInit())

     rule checkCtorAndDtor(K:K, X::CId, T::CPPType, B::Bool, _, t(... st: classType(M::Class)))
          => checkDtor(M) ~> figureConstructItem(K, X, T, B) [owise]

     rule <k> (.K => resolveOverload(cSet(Candidates, M :: ConstructorId(X)), list(.List), constructor))
              ~> checkCtor(_ :: Class(_, X::CId, _) #as M::Class)
          ...</k>
          <curr-tr-tu> Tu::String </curr-tr-tu>
          <tu-id> Tu </tu-id>
          <class-id> M </class-id>
          <cenv>... ConstructorId(X) |-> Candidates::Map ...</cenv>

     rule resolveOverloadResult(E:ResolvedExpr) ~> checkCtor(_) => .K

     rule <k> (.K => checkAccess(CallExpr(lv(lnew(Base), hasTrace(Name(NoNNS(), DestructorId(X))), T), list(.List), krlist(.List))))
              ~> checkDtor(_ :: Class(_, X::CId, _) #as M::Class)
          ...</k>
          <curr-tr-tu> Tu::String </curr-tr-tu>
          <tu-id> Tu </tu-id>
          <class-id> M </class-id>
          <cenv>... DestructorId(X) |-> (_::CPPType |-> (T::CPPType, envEntry(... base: Base::SymBase))) ...</cenv>

     rule resolveOverloadResult(E:ResolvedExpr) ~> checkDtor(_) => .K

     syntax Bool  ::= isDeletedDefaultConstructor(CId, CPPType, Class, CPPType, Set, Init) [function]

     // @ref n4296 12.1:4.1
     rule isDeletedDefaultConstructor(X::CId, T::CPPType, C::Class, FuncT::CPPType, VM::Set, _) => true
          requires X in VM andBool isUnionLikeClass(C) andBool #fun(InnerT::CPPType => isCPPClassType(InnerT)
               andBool hasConstructorThat(InnerT, isNonTrivialDefaultConstructor))(getMostDerivedArrayElement(T))
               andBool notBool isUserProvidedConstructor(FuncT, .K)

     // @ref n4296 12.1:4.2
     rule isDeletedDefaultConstructor(_, cppRefType #as T::CPPType, C::Class, FuncT::CPPType, _, NoInit()) => true
          requires notBool isUserProvidedConstructor(FuncT, .K)

     // @ref n4296 12.1:4.3
     rule isDeletedDefaultConstructor(X::CId, T::CPPType, _, FuncT::CPPType, VM::Set, NoInit()) => true
          requires notBool X in VM andBool #fun(InnerT::CPPType => isCPPClassType(InnerT) andBool isConstType(InnerT) andBool notBool hasConstructorThat(InnerT, isUserProvidedDefaultConstructor))(getMostDerivedArrayElement(T))
               andBool notBool isUserProvidedConstructor(FuncT, .K)

     rule isDeletedDefaultConstructor(_::CId, _, _, _, _, _) => false [owise]

     // @ref n4296 12.1:4.4 (4.5 is implicit when constructing the anonymous union)
     rule <k> figureConstruct(.List, _, .List, .List, _, _, false) => Deleted() ...</k>
          <curr-tr-scope> blockScope((_::ClassQualifier :: Class(Union(), _, _)) #as C::Class :: ConstructorId(_), Base::SymBase, _) </curr-tr-scope>
          <functions>... Base |-> functionObject(_, FuncT::CPPType, _, _) ...</functions>
          requires notBool isUserProvidedConstructor(FuncT, .K)


     syntax KItem ::= figureConstructItem(memInit: K, CId, CPPType, isMember: Bool)

     // @ref n4296 12.6.2:7
     rule <k> (figureConstructItem(I::Init, X::CId, T::CPPType, IsMember:Bool) => .K) ~> figureConstruct(.List, _, _, _, _,
                   (Res:K => Res ~> TExpressionStmt(figureConstructorInit(Name(C, X), T, I, notBool IsMember))),
                   B:Bool => B orBool (IsMember andBool X in VM andBool notBool isConstType(getMostDerivedArrayElement(T)))) ...</k>
          <curr-tr-scope> blockScope(C::Class :: ConstructorId(_), _, _) </curr-tr-scope>
          <curr-tr-tu> Tu::String </curr-tr-tu>
          <tu-id> Tu </tu-id>
          <class-id> C </class-id>
          <variant-members> VM::Set </variant-members>
          requires I =/=K .Init

     // @ref n4296 12.6.2:8.1
     // TODO(dwightguth): ctor-initializers and base classes
     // TODO(traiansf): unions
     rule <k> (figureConstructItem(.Init, X::CId, T::CPPType, true) => .K) ~> figureConstruct(.List, .Map, _, _, _,
                   (Res:K => Res ~> TExpressionStmt(figureConstructorInit(Name(C, X), T, I, false))),
                   B:Bool => B orBool (X in VM andBool notBool isConstType(getMostDerivedArrayElement(T)))) ...</k>
          <curr-tr-scope> blockScope(C::Class :: ConstructorId(_), _, _) </curr-tr-scope>
          <curr-tr-tu> Tu::String </curr-tr-tu>
          <tu-id> Tu </tu-id>
          <class-id> C </class-id>
          <initializers>... X |-> (stripType(T) |-> (_, I::Init)) ...</initializers>
          <variant-members> VM::Set </variant-members>
          requires I =/=K NoInit()

     // @ref n4296 12.6.2:8.2
     // TODO(traiansf): anonymous unions
     rule <k> (figureConstructItem(.Init, X::CId, T::CPPType, true) => .K) ~> figureConstruct(.List, _, _, _, _, _,
                   B:Bool => B orBool (notBool isConstType(getMostDerivedArrayElement(T)))) ...</k>
          <curr-tr-scope> blockScope(C::Class :: ConstructorId(_), _, _) </curr-tr-scope>
          <curr-tr-tu> Tu::String </curr-tr-tu>
          <tu-id> Tu </tu-id>
          <class-id> C </class-id>
          <initializers>... X |-> (stripType(T) |-> (_, I::Init)) ...</initializers>
          <variant-members> VM::Set </variant-members>
          requires I ==K NoInit() andBool X in VM

     // @ref n4296 12.6.2:8.3
     rule <k> (figureConstructItem(.Init, X::CId, T::CPPType, true) => .K) ~> figureConstruct(.List, _, _, _, _,
                   (Res:K => Res ~> TExpressionStmt(defaultConstructorInit(Name(C, X), T, false))), _) ...</k>
          <curr-tr-scope> blockScope(C::Class :: ConstructorId(_), _, _) </curr-tr-scope>
          <curr-tr-tu> Tu::String </curr-tr-tu>
          <tu-id> Tu </tu-id>
          <class-id> C </class-id>
          <initializers>... X |-> (stripType(T) |-> (_, I::Init)) ...</initializers>
          <variant-members> VM::Set </variant-members>
          requires I ==K NoInit() andBool notBool X in VM

     rule <k> (figureConstructItem(.Init, X::CId, T::CPPType, false) => .K) ~> figureConstruct(.List, _, _, _, _,
                   (Res:K => Res ~> TExpressionStmt(defaultConstructorInit(Name(C, X), T, true))), _) ...</k>
          <curr-tr-scope> blockScope(C::Class :: ConstructorId(_), _, _) </curr-tr-scope>

     rule <k> figureConstruct(.List, _, .List, .List, Body::Stmt, Res:K, HasNonConst:Bool) => Res ~> Body ...</k>
          <curr-tr-scope> blockScope(_::ClassQualifier :: Class(T::Tag, _, _) #as C::Class :: ConstructorId(_), _, _) </curr-tr-scope>
          <curr-tr-tu> Tu::String </curr-tr-tu>
          <tu-id> Tu </tu-id>
          <class-id> C </class-id>
          <base-classes> Bases::List </base-classes>
          <non-static-data-members> NSDM::List </non-static-data-members>
          <variant-members> VM::Set </variant-members>
          requires HasNonConst orBool T =/=K Union()

     syntax Bool ::= #isTrivialDefaultConstructor(ClassInfo) [function]
                   | #hasMethodThat(CId, ClassInfo, TypePredicate) [function]
                   | #isDeleted(SymBase) [function]

     // @ref n4296 12.1:4.8
     rule isTrivialDefaultConstructor(T::CPPType, K:K) => isDefaultConstructor(T, K) andBool notBool isUserProvidedConstructor(T, K) andBool notBool hasVirtualMembers(type(classType(getMethodClass(T)))) andBool #isTrivialDefaultConstructor(getClassInfo(getMethodClass(T)))

     // @ref n4296 12.1:4.10
     rule #isTrivialDefaultConstructor(<class>... <base-classes> ListItem(C::Class) => .List ...</base-classes> ...</class>)
          requires hasConstructorThat(type(classType(C)), isTrivialDefaultConstructor)

     // @ref n4296 12.1:4.9,4.11
     rule #isTrivialDefaultConstructor(<class>... <non-static-data-members> ListItem(Class.DataMember(X::CId, T::CPPType)) => .List ...</non-static-data-members> <initializers>... X |-> (stripType(T) |-> (_, NoInit())) ...</initializers> ...</class>)
          requires #if isCPPClassType(getMostDerivedArrayElement(T)) #then hasConstructorThat(getMostDerivedArrayElement(T), isTrivialDefaultConstructor) #else true #fi

     rule #isTrivialDefaultConstructor(<class>... <base-classes> .List </base-classes> <non-static-data-members> .List </non-static-data-members> ...</class>) => true

     rule #isTrivialDefaultConstructor(...) => false [owise]

     rule isNonTrivialDefaultConstructor(T::CPPType, K:K) => isDefaultConstructor(T, K) andBool notBool isTrivialDefaultConstructor(T, K)

     rule isDefaultConstructor(T::CPPType, envEntry(... defaultArgs: DA::DefaultArgumentsResult)) => acceptsNArgs(0, T, getDefaultArgsVals(DA))

     // n4296 12.8:2, TODO: check non-template. TODO function parameter packs are not allowed
     rule isCopyConstructor(
               t(... st: functionType(... paramTypes: (t(... st: lvRefType(t(... st: classType(C::Class)))), _), methodInfo: methodInfo(... class: C::Class))) #as T::CPPType,
               envEntry(... defaultArgs: DA::DefaultArgumentsResult)
          ) => acceptsNArgs(1, T, getDefaultArgsVals(DA))

     rule isCopyConstructor(_, _) => false [owise]

     // n4296 12.8:3 same as copy constructor, but rvalue reference
     rule isMoveConstructor(
               t(... st: functionType(... paramTypes: (t(... st: rvRefType(t(... st: classType(C::Class)))), _), methodInfo: methodInfo(... class: C::Class))) #as T::CPPType,
               envEntry(... defaultArgs: DA::DefaultArgumentsResult)
          ) => acceptsNArgs(1, T, getDefaultArgsVals(DA))

     rule isMoveConstructor(_, _) => false [owise]

     rule isUserProvidedConstructor(T::CPPType, _) => isMethodUserProvided(T)

     rule isUserProvidedDestructor(T::CPPType, _) => isMethodUserProvided(T)

     rule isVirtualDestructor(T::CPPType, _) => isMethodVirtual(T)

     rule isUserProvidedDefaultConstructor(T::CPPType, K:K) => isDefaultConstructor(T, K) andBool isUserProvidedConstructor(T, K)

     rule isUserProvidedMoveConstructor(T::CPPType, K:K) => isUserProvidedConstructor(T, K) andBool isMoveConstructor(T, K)

     rule isUserProvidedCopyConstructor(T::CPPType, K:K) => isUserProvidedConstructor(T, K) andBool isCopyConstructor(T, K)

     // 'has' queries
     // -------------

     rule hasUserProvidedMoveConstructor(C::Class)
          => hasConstructorThat(C, isUserProvidedMoveConstructor)

     rule hasVirtualDestructor(C::Class)
          => hasDestructorThat(C, isVirtualDestructor)

     rule hasCopyConstructor(C::Class)
          => hasConstructorThat(C, isCopyConstructor)

     rule hasConstCopyConstructor(C::Class)
          => hasConstructorThat(C, isConstCopyConstructor)

     rule hasUserProvidedCopyConstructor(C::Class)
          => hasConstructorThat(C, isUserProvidedCopyConstructor)

     rule hasUserProvidedMoveAssignOp(_)
          => false // TODO(jantusil)

     rule hasConstructorThat(C::Class, Lbl::TypePredicate)
          => hasConstructorThat(type(classType(C)), Lbl)

     rule hasDestructorThat(C::Class, Lbl::TypePredicate)
          => hasDestructorThat(type(classType(C)), Lbl)

     syntax Bool ::= isWhatever(CPPType, K) [function]

     rule isWhatever(_, _) => true

     rule hasConstructorThat(t(... st: classType(_ :: Class(_, X::CId, _))) #as T::CPPType, Lbl::TypePredicate) => #hasMethodThat(ConstructorId(X), getClassInfo(T), Lbl)

     rule hasDestructorThat(t(... st: classType(_ :: Class(_, X::CId, _))) #as T::CPPType, Lbl::TypePredicate) => #hasMethodThat(DestructorId(X), getClassInfo(T), Lbl)

     rule #hasMethodThat(X::CId, <class>... <cenv>... X |-> M::Map ...</cenv> ...</class>, Lbl::TypePredicate)
          => some(M, Lbl)

     rule #hasMethodThat(...) => false [owise]

     rule isDeleted(_, envEntry(... base: Base::SymBase)) => #isDeleted(Base)

     rule [[ #isDeleted(Base::SymBase) => true ]]
          <functions>... Base |-> Deleted() ...</functions>

     rule #isDeleted(...) => false [owise]

     rule isDeletedDefaultConstructor(T::CPPType, K:K) => isDeleted(T, K) andBool isDefaultConstructor(T, K)

     rule <k> Destructor() => figureDestruct(Bases, NSDM, .K) ...</k>
          <curr-tr-scope> blockScope(C::Class :: DestructorId(_), _, _) </curr-tr-scope>
          <curr-tr-tu> Tu::String </curr-tr-tu>
          <tu-id> Tu </tu-id>
          <class-id> C </class-id>
          <base-classes> Bases::List </base-classes>
          <non-static-data-members> NSDM::List </non-static-data-members>

     rule <k> Defaulted() => .K ...</k>
          <curr-tr-scope> blockScope(C::Class :: DestructorId(_), _, _) </curr-tr-scope>

     // TODO(chathhorn)
     rule Deleted() => .K

     syntax Stmt ::= figureDestruct(bases: List, dataMembers: List, result: K)

     // @ref n4296 12.4:5
     rule <k> figureDestruct(.List, ListItem(Class.DataMember(X::CId, T::CPPType)) _, _) => Deleted() ...</k>
          <curr-tr-scope> blockScope(C::Class :: ConstructorId(_), Base::SymBase, _) </curr-tr-scope>
          <functions>... Base |-> functionObject(_, FuncT::CPPType, _, _) ...</functions>
          <curr-tr-tu> Tu::String </curr-tr-tu>
          <tu-id> Tu </tu-id>
          <class-id> C </class-id>
          <variant-members> VM::Set </variant-members>
          requires isDeletedDefaultDestructor(X, T, C, FuncT, VM)

     // @ref n4296 12.4:5.2
     rule <k> (.K => checkDtor(X, T, getMostDerivedArrayElement(T), VM, FuncT)) ~> figureDestruct(.List, (ListItem(Class.DataMember(X::CId, T::CPPType)) => .List) _, _) ...</k>
          <curr-tr-scope> blockScope(C::Class :: DestructorId(_), Base::SymBase, _) </curr-tr-scope>
          <functions>... Base |-> functionObject(_, FuncT::CPPType, _, _) ...</functions>
          <curr-tr-tu> Tu::String </curr-tr-tu>
          <tu-id> Tu </tu-id>
          <class-id> C </class-id>
          <variant-members> VM::Set </variant-members>
          requires notBool isDeletedDefaultDestructor(X, T, C, FuncT, VM)

     rule <k> (.K => checkDtor(baseClass(M), type(classType(M)), type(classType(M)), VM, FuncT)) ~> figureDestruct((ListItem(M::Class) => .List) _, _, _) ...</k>
          <curr-tr-scope> blockScope(C::Class :: DestructorId(_), Base::SymBase, _) </curr-tr-scope>
          <functions>... Base |-> functionObject(_, FuncT::CPPType, _, _) ...</functions>
          <curr-tr-tu> Tu::String </curr-tr-tu>
          <tu-id> Tu </tu-id>
          <class-id> C </class-id>
          <variant-members> VM::Set </variant-members>
          <virtual-bases> .Set </virtual-bases>

     syntax K ::= checkDtor(CId, CPPType, CPPType, Set, CPPType) [function, klabel(checkDtor3)]

     rule checkDtor(X::CId, T::CPPType, M::CPPType, VM::Set, FuncT::CPPType)
          => figureDestructItem(X, T, VM)
          requires notBool isCPPClassType(M) orBool isMethodUserProvided(FuncT)

     rule checkDtor(X::CId, T::CPPType, t(... st: classType(M::Class)), VM::Set, _)
          => checkDtor(M) ~> figureDestructItem(X, T, VM) [owise]

     syntax Bool ::= isDeletedDefaultDestructor(CId, CPPType, Class, CPPType, Set) [function]

     // @ref n4296 12.4:5.1
     rule isDeletedDefaultDestructor(X::CId, T::CPPType, C::Class, FuncT::CPPType, VM::Set) => true
          requires X in VM andBool isUnionLikeClass(C) andBool #fun(InnerT::CPPType => isCPPClassType(InnerT)
               andBool hasDestructorThat(InnerT, isNonTrivialDestructor))(getMostDerivedArrayElement(T))
               andBool notBool isUserProvidedDestructor(FuncT, .K)

     rule isDeletedDefaultDestructor(_::CId, _, _, _, _) => false [owise]

     syntax KItem ::= figureDestructItem(CId, CPPType, Set)

     rule figureDestructItem(X::CId, T::CPPType, VM::Set) => .K
          requires notBool isCPPClassType(getMostDerivedArrayElement(T))
               orBool X in VM

     rule (figureDestructItem(X::CId, T::CPPType, VM::Set) => .K)
          ~> figureDestruct(... result: Res:K => Res ~> TaddToConstructed(Name(NoNNS(), X), T))
          requires notBool X in VM andBool isCPPClassType(getMostDerivedArrayElement(T))

     rule <k> figureDestruct(.List, .List, Res:K) => Res ...</k>
          <curr-tr-scope> blockScope(_ :: DestructorId(_), Base::SymBase, _) </curr-tr-scope>
          <functions>... Base |-> functionObject(_, FuncT::CPPType, _, _) ...</functions>
          requires notBool isMethodVirtual(FuncT)

     rule <k> (.K => lookupAllocationFunction(operatordelete, type(classType(C)), false)) ~> figureDestruct(.List, .List, _) ...</k>
          <curr-tr-scope> blockScope(C::Class :: DestructorId(_), Base::SymBase, _) </curr-tr-scope>
          <functions>... Base |-> functionObject(_, FuncT::CPPType, _, _) ...</functions>
          requires isMethodVirtual(FuncT)

     rule (cSet(... candidates: Cands::Map, id: Q::QualId) #as C:CandidateSet => resolveOverload(C, list(ListItem(prv(NullPointer, noTrace, type(pointerType(type(void))))) getSecondDeleteArg(Cands, prv(0, noTrace, type(size_t)))), Name(NoNNS(), operatordelete)))
          ~> figureDestruct(...)

     rule resolveOverloadResult(E:ResolvedExpr) ~> figureDestruct(.List, .List, Res:K) => Res

     syntax KItem ::= TaddToConstructed(Expr, CPPType) [strict(c; 1)]

     rule <k> TaddToConstructed(L:LVal, T::CPPType) => .K ...</k>
          <elab>... .K => addToConstructed(L, T) </elab>

     syntax Bool ::= #isTrivialDestructor(ClassInfo) [function]

     // @ref n4296 12.4:5.4
     rule isTrivialDestructor(T::CPPType, K:K) => notBool isUserProvidedDestructor(T, K) andBool notBool isMethodVirtual(T) andBool #isTrivialDestructor(getClassInfo(getMethodClass(T)))

     rule #isTrivialDestructor(<class>... <base-classes> ListItem(C::Class) => .List ...</base-classes> ...</class>)
          requires hasDestructorThat(type(classType(C)), isTrivialDestructor)

     rule #isTrivialDestructor(<class>... <non-static-data-members> ListItem(Class.DataMember(_, T::CPPType)) => .List ...</non-static-data-members> ...</class>)
          requires #if isCPPClassType(getMostDerivedArrayElement(T)) #then hasDestructorThat(getMostDerivedArrayElement(T), isTrivialDestructor) #else true #fi

     rule #isTrivialDestructor(<class>... <base-classes> .List </base-classes> <non-static-data-members> .List </non-static-data-members> ...</class>) => true

     rule #isTrivialDestructor(...) => false [owise]

     rule isNonTrivialDestructor(T::CPPType, K:K)
          => notBool isTrivialDestructor(T, K)

     rule some(.List, _::ClassPredicate) => false

     rule some(ListItem(C::Class) L::List, P::ClassPredicate) => P(C) orBool some(L, P)

     syntax AccessSpecifier ::= getDefaultAccessType(Tag) [function]

     rule getDefaultAccessType(Class()) => Private()

     rule getDefaultAccessType(Struct()) => Public()

     rule getDefaultAccessType(Union()) => Public()

     context BitFieldDecl(_, _, _, (HOLE:Expr => reval(HOLE))) [result(PRVal)]

     rule BitFieldDecl(NoNNS(), X::CId, t(Q::Quals, Mods::Set, T::CPPSimpleType), prv(N::Int, _, _)) => declareField(X, t(Q, Mods, bitfieldType(T, N)), NoInit())

     rule FieldDecl(NoNNS(), X::CId, T:CPPType, Init::Init) => declareField(X, T, Init)

     syntax KItem ::= declareField(CId, CPPType, Init)

     syntax ClassOffset ::= "uninitialized"

     syntax KItem ::= layoutField(CId, CPPType)
                    | layoutBases(nonVirtual: List, virtual: List)
                    | #layoutBases(List)
                    | layoutVirtualBases(List)
                    | computePrimaryBase(nonVirtual: List, virtual: List, nonPrimary: List, primary: K)

     rule First:K |> Second::Ordering => First ~> Second

     rule .Ordering => .K

     // POD for the purposes of layout is a concept in the Itanium C++ ABI.
     // we do not currently support non-GNU-Linux ABI layouts for class/struct/union types.
     // thus we encode the layout in the semantics directly.
     // eventually we will want to support arbitrary ABIs which means this will
     // get moved to an extension specific to the Itanium ABI.
     rule isPODLayoutType(cppScalarType #as T::CPPType) => true

     rule isPODLayoutType(t(... st: _:CPPSimpleArrayType) #as T::CPPType) => isPODLayoutType(innerType(T))

     rule isPODLayoutType(t(... st: classType(...)) #as T::CPPType) => isPODLayoutClass(T, getClassInfo(T))

     rule isPODLayoutType(_) => false [owise]

     rule isPOD03Type(cppScalarType #as T::CPPType) => true

     rule isPOD03Type(t(... st: _:CPPSimpleArrayType) #as T::CPPType) => isPOD03Type(innerType(T))

     rule isPOD03Type(t(... st: classType(...)) #as T::CPPType) => isPOD03Class(T, getClassInfo(T))

     rule isPOD03Type(_) => false [owise]

     syntax Bool ::= isPODLayoutClass(CPPType, ClassInfo) [function]
                   | isEmptyClass(CPPType, ClassInfo) [function]
                   | isPOD03Type(CPPType) [function]
                   | isPOD03Class(CPPType, ClassInfo) [function]

     rule isPODLayoutClass(_,
               <class>...
                 <non-static-data-members> ListItem(Class.DataMember(X::CId, T::CPPType)) => .List ...</non-static-data-members>
                 <access>... X |-> Public() ...</access>
               ...</class>)
          requires notBool (isCPPClassType(getMostDerivedArrayElement(T)) andBool notBool isPODLayoutType(T))
               andBool notBool isCPPRefType(T)
               andBool notBool isWideBitfield(T)

     rule isPODLayoutClass(t(... st: classType(_ :: Class(Key::ClassKey, X::CId, _))) #as T::CPPType,
               <class>...
                 <non-static-data-members> .List </non-static-data-members>
                 <base-classes> .List </base-classes>
               ...</class>)
          => notBool (#hasMethodThat(operator=, getClassInfo(T), isUserProvidedCopyAssignment)
               orBool hasDestructorThat(T, isUserProvidedDestructor)
               orBool hasConstructorThat(T, isUserProvidedConstructor)
               orBool hasVirtualMembers(T))
               andBool (Key ==K Struct() orBool Key ==K Union())

     rule isPODLayoutClass(...) => false [owise]

     rule isPOD03Class(_,
               <class>...
                 <non-static-data-members> ListItem(Class.DataMember(X::CId, T::CPPType)) => .List ...</non-static-data-members>
                 <access>... X |-> Public() ...</access>
               ...</class>)
          requires notBool (isCPPClassType(getMostDerivedArrayElement(T)) andBool notBool isPOD03Type(T))
               andBool notBool isCPPRefType(T)

     rule isPOD03Class(t(... st: classType(_ :: Class(Key::ClassKey, X::CId, _))) #as T::CPPType,
               <class>...
                 <non-static-data-members> .List </non-static-data-members>
                 <base-classes> .List </base-classes>
               ...</class>)
          => notBool (#hasMethodThat(operator=, getClassInfo(T), isUserProvidedCopyAssignment)
               orBool hasDestructorThat(T, isUserProvidedDestructor)
               orBool hasConstructorThat(T, isUserProvidedConstructor)
               orBool hasVirtualMembers(T))
               andBool (Key ==K Struct() orBool Key ==K Union())

     rule isPOD03Class(...) => false [owise]

     rule isEmptyClass(T::CPPType, <class>... <base-classes> .List </base-classes> <non-static-data-members> .List </non-static-data-members> ...</class>)
          => notBool hasVirtualMembers(T)

     rule isEmptyClass(_, <class>... <base-classes> ListItem(B::Class) => .List ...</base-classes> ...
</class>)
          requires isEmptyClass(type(classType(B)), getClassInfo(B))

     rule isEmptyClass(...) => false [owise]

     syntax TypePredicate ::= "isUserProvidedCopyAssignment"

     rule isUserProvidedCopyAssignment(t(... st: functionType(... paramTypes: t(quals(.Set), _, classType(X::Class)), methodInfo: methodInfo(... static: false, class: X, userProvided: true))), envEntry(...)) => true

     rule isUserProvidedCopyAssignment(t(... st: functionType(... paramTypes: t(... st: lvRefType(t(... st: classType(X::Class)))), methodInfo: methodInfo(... static: false, class: X, userProvided: true))), envEntry(...)) => true

     rule isUserProvidedCopyAssignment(_, _) => false [owise]

     syntax Bool ::= isWideBitfield(CPPType) [function]

     rule isWideBitfield(t(... st: bitfieldType(...)) #as T::CPPType) => bitSizeofType(T) >Int bitSizeofType(innerType(T))

     rule isWideBitfield(_) => false [owise]

     rule (.K => nameLookup(X, NoTag(), typeMask)) ~> BaseClass(_, false, _, Name(NoNNS(), X::CId))

     rule <k> t(... st: classType(D::Class)) #as T:KItem ~> BaseClass(false, false, AS::AccessSpecifier, _) => .K ...</k>
          <curr-tr-scope> classScope(C::Class, _) </curr-tr-scope>
          <curr-tr-tu> Tu::String </curr-tr-tu>
          <tu-id> Tu </tu-id>
          <class>...
            <class-id> C </class-id>
            <is-aggregate> _ => false </is-aggregate>
            <base-classes>... .List => ListItem(D) </base-classes>
            <cenv> CE::Map => CE[baseClass(D), T <- uninitialized] </cenv>
            <base-access> AE::Map => AE [D <- AS] </base-access>
          ...</class>
          <deferred-class-actions> layoutBases(_::List (.List => ListItem(D)), _) |> _ |> _ |> .Ordering </deferred-class-actions>

     rule <k> t(... st: classType(D::Class)) #as T:KItem ~> BaseClass(true, false, AS::AccessSpecifier, _) => .K ...</k>
          <curr-tr-scope> classScope(C::Class, _) </curr-tr-scope>
          <curr-tr-tu> Tu::String </curr-tr-tu>
          <tu-id> Tu </tu-id>
          <class>...
            <class-id> C </class-id>
            <is-aggregate> _ => false </is-aggregate>
            <base-classes>... .List => ListItem(D) </base-classes>
            <cenv> CE::Map => CE[baseClass(D), T <- uninitialized] </cenv>
            <base-access> AE::Map => AE [D <- AS] </base-access>
          ...</class>
          <deferred-class-actions> layoutBases(_, _::List (.List => ListItem(D))) |> layoutVirtualBases(_::List (.List => ListItem(D))) |> _ |> _ |> .Ordering </deferred-class-actions>

     rule <k> declareField(X::CId, T::CPPType, Init::Init) => .K ...</k>
          <curr-tr-scope> classScope(C::Class, _) </curr-tr-scope>
          <curr-tr-tu> Tu::String </curr-tr-tu>
          <tu-id> Tu </tu-id>
          <class>...
            <class-type> Key::ClassKey </class-type>
            <class-id> C </class-id>
            <is-aggregate> B:Bool => B andBool (AS ==K Public()) </is-aggregate>
            <non-static-data-members>... .List => ListItem(Class.DataMember(X, T)) </non-static-data-members>
            <access-specifier> AS::AccessSpecifier </access-specifier>
            <access> AE::Map => AE[X <- AS] </access>
            <cenv> CE::Map => CE[X, T <- uninitialized] </cenv>
            <initializers> Inits::Map => Inits[X, T <- Init] </initializers>
            <variant-members> VM::Set => #if Key ==K Union() #then VM SetItem(X) #else VM #fi </variant-members>
          ...</class>
          <deferred-class-actions> (K:K => K ~> layoutField(X, T)) |> _ |> _ |> .Ordering </deferred-class-actions>
          requires notBool (X in_keys(CE)) andBool X =/=K #NoName

     rule <k> declareField(#NoName, t(... st: bitfieldType(...)) #as T::CPPType, NoInit()) => .K ...</k>
          <curr-tr-scope> classScope(C::Class, _) </curr-tr-scope>
          <curr-tr-tu> Tu::String </curr-tr-tu>
          <tu-id> Tu </tu-id>
          <class>...
            <class-type> Key::ClassKey </class-type>
            <class-id> C </class-id>
          ...</class>
          <deferred-class-actions> (K:K => K ~> layoutField(#NoName, T)) |> _ |> _ |> .Ordering </deferred-class-actions>

     // POD layout
     rule <k> layoutField(X::CId, T::CPPType) => .K ...</k>
          <curr-tr-scope> classScope(C::Class, _) </curr-tr-scope>
          <curr-tr-tu> Tu::String </curr-tr-tu>
          <tu-id> Tu </tu-id>
          <class>...
            <class-id> C </class-id>
            <class-type> Key::ClassKey </class-type>
            <cenv> CE::Map => #if X ==K #NoName #then CE #else CE[X, T <- classOffset(V, padOrNot(V, T, Key))] #fi </cenv>
            <sizeof> V::Int => updateMaxOffset(V, T, Key) </sizeof>
            <align> M::Int => maxInt(M, byteAlignofType(T)) </align>
          ...</class>
          requires isPODLayoutType(type(classType(C)))

     // non-POD-layout, non-wide bitfield
     rule <k> layoutField(X::CId, t(... st: bitfieldType(...)) #as T::CPPType) => .K ...</k>
          <curr-tr-scope> classScope(C::Class, _) </curr-tr-scope>
          <curr-tr-tu> Tu::String </curr-tr-tu>
          <tu-id> Tu </tu-id>
          <class>...
            <class-id> C </class-id>
            <class-type> Key::ClassKey </class-type>
            <cenv> CE::Map => #if X ==K #NoName #then CE #else CE[X, T <- classOffset(V, padOrNot(V, T, Key))] #fi </cenv>
            <dsize> V::Int => updateMaxOffset(V, T, Key) </dsize>
            <align> M::Int => maxInt(M, byteAlignofType(T)) </align>
            <sizeof> V2::Int => maxInt(V2, padTo(updateMaxOffset(V, T, Key), 1)) </sizeof>
          ...</class>
          requires notBool isPODLayoutType(type(classType(C)))
               andBool notBool isWideBitfield(T)

     // non-POD-layout, wide bitfield
     rule <k> layoutField(X::CId, T::CPPType) => .K ...</k>
          <curr-tr-scope> classScope(C::Class, _) </curr-tr-scope>
          <curr-tr-tu> Tu::String </curr-tr-tu>
          <tu-id> Tu </tu-id>
          <class>...
            <class-id> C </class-id>
            <class-type> Key::ClassKey </class-type>
            <cenv> CE::Map => #if X ==K #NoName #then CE #else CE[X, T <- classOffset(V, padOrNot(V, getT'(T), Key))] #fi </cenv>
            <dsize> V::Int => updateMaxOffset(V, T, Key) </dsize>
            <align> M::Int => maxInt(M, byteAlignofType(getT'(T))) </align>
            <sizeof> V2::Int => maxInt(V2, padTo(updateMaxOffset(V, T, Key), 1)) </sizeof>
          ...</class>
          requires notBool isPODLayoutType(type(classType(C)))
               andBool isWideBitfield(T)

     syntax CPPType ::= "getT'" "(" CPPType ")" [function]

     rule getT'(t(... st: bitfieldType(_, N::Int))) =>
          #if byteSizeofType(type(long-long)) *Int cfg:bitsPerByte <=Int N #then type(long-long) #else
          #if byteSizeofType(type(long)) *Int cfg:bitsPerByte <=Int N #then type(long) #else
          #if byteSizeofType(type(int)) *Int cfg:bitsPerByte <=Int N #then type(int) #else
          #if byteSizeofType(type(short)) *Int cfg:bitsPerByte <=Int N #then type(short) #else
          type(char)
          #fi #fi #fi #fi

     // non-POD-layout union, non-bitfield, data member
     rule <k> layoutField(X::CId, T::CPPType) => .K ...</k>
          <curr-tr-scope> classScope(C::Class, _) </curr-tr-scope>
          <curr-tr-tu> Tu::String </curr-tr-tu>
          <tu-id> Tu </tu-id>
          <class>...
            <class-id> C </class-id>
            <class-type> Union() </class-type>
            <cenv> CE::Map => CE[X, T <- classOffset(0, 0)] </cenv>
            <dsize> V::Int => maxInt(V, bitSizeofType(T)) </dsize>
            <align> M::Int => maxInt(M, byteAlignofType(T)) </align>
            <sizeof> V2::Int => maxInt(V2, maxInt(V, bitSizeofType(T))) </sizeof>
          ...</class>
          requires notBool isPODLayoutType(type(classType(C)))
               andBool notBool isCPPBitfieldType(T)

     // non-POD-layout non-union, non-bitfield, non-empty-base-class
     rule <k> layoutField(X::CId, T::CPPType) => tryLayoutField(X, T, V, padTo(V, #if isBaseClass(X) #then nvAlignof(T) #else byteAlignofType(T) #fi), false) ...</k>
          <curr-tr-scope> classScope(C::Class, _) </curr-tr-scope>
          <curr-tr-tu> Tu::String </curr-tr-tu>
          <tu-id> Tu </tu-id>
          <class>...
            <class-id> C </class-id>
            <class-type> Key::ClassKey </class-type>
            <dsize> V::Int </dsize>
          ...</class>
          requires notBool isPODLayoutType(type(classType(C)))
               andBool notBool isCPPBitfieldType(T)
               andBool Key =/=K Union()
               andBool notBool (isBaseClass(X) andBool isEmptyClass(T, getClassInfo(T)))

     syntax Int ::= nvSizeof(CPPType) [function]
                  | #nvSizeof(ClassInfo) [function]
                  | nvAlignof(CPPType) [function]
                  | #nvAlignof(ClassInfo) [function]

     rule nvSizeof(T::CPPType) => #nvSizeof(getClassInfo(T))

     rule nvAlignof(T::CPPType) => #nvAlignof(getClassInfo(T))

     rule #nvSizeof(<class>... <nvsize> V::Int </nvsize> ...</class>) => V

     rule #nvAlignof(<class>... <nvalign> V::Int </nvalign> ...</class>) => V

     syntax KItem ::= tryLayoutField(CId, CPPType, naoffset: Int, offset: Int, isEmptyBase: Bool)

     rule <k> tryLayoutField(X::CId, T::CPPType, NaOffset::Int, Offset::Int, false) => .K ...</k>
          <curr-tr-scope> classScope(C::Class, _) </curr-tr-scope>
          <curr-tr-tu> Tu::String </curr-tr-tu>
          <tu-id> Tu </tu-id>
          <class>...
            <class-id> C </class-id>
            <class-type> Key::ClassKey </class-type>
            <cenv> CE::Map => CE[X, T <- classOffset(NaOffset, Offset)] </cenv>
            <dsize> V::Int => Offset +Int #if isBaseClass(X) #then nvSizeof(T) #else bitSizeofType(T) #fi </dsize>
            <align> M::Int => maxInt(M, #if isBaseClass(X) #then nvAlignof(T) #else byteAlignofType(T) #fi) </align>
            <sizeof> V2::Int => maxInt(V2, Offset +Int #if isBaseClass(X) #then nvSizeof(T) #else bitSizeofType(T) #fi) </sizeof>
          ...</class>
          requires size(intersectSet(getTypesAtOffsetForLayout(T, 0), getTypesAtOffsetForLayout(type(classType(C)), Offset))) ==Int 0

     rule <k> tryLayoutField(X::CId, T::CPPType, NaOffset::Int, Offset::Int, true) => .K ...</k>
          <curr-tr-scope> classScope(C::Class, _) </curr-tr-scope>
          <curr-tr-tu> Tu::String </curr-tr-tu>
          <tu-id> Tu </tu-id>
          <class>...
            <class-id> C </class-id>
            <class-type> Key::ClassKey </class-type>
            <cenv> CE::Map => CE[X, T <- classOffset(NaOffset, Offset)] </cenv>
            <align> M::Int => maxInt(M, nvAlignof(T)) </align>
            <sizeof> V2::Int => maxInt(V2, Offset +Int bitSizeofType(T)) </sizeof>
          ...</class>
          requires size(intersectSet(getTypesAtOffsetForLayout(T, 0), getTypesAtOffsetForLayout(type(classType(C)), Offset))) ==Int 0

     rule <k> tryLayoutField(X::CId, T::CPPType, _, Offset::Int => Offset +Int #if isBaseClass(X) #then nvAlignof(T) #else byteAlignofType(T) #fi *Int cfg:bitsPerByte, _) ...</k>
          <curr-tr-scope> classScope(C::Class, _) </curr-tr-scope>
          requires size(intersectSet(getTypesAtOffsetForLayout(T, 0), getTypesAtOffsetForLayout(type(classType(C)), Offset))) >Int 0

     // non-POD-layout non-union, empty base class, layout at 0
     rule <k> layoutField(baseClass(D::Class), T::CPPType) => .K ...</k>
          <curr-tr-scope> classScope(C::Class, _) </curr-tr-scope>
          <curr-tr-tu> Tu::String </curr-tr-tu>
          <tu-id> Tu </tu-id>
          <class>...
            <class-id> C </class-id>
            <class-type> Key::ClassKey </class-type>
            <cenv> CE::Map => CE[baseClass(D), T <- classOffset(0, 0)] </cenv>
            <align> M::Int => maxInt(M, nvAlignof(T)) </align>
            <sizeof> V2::Int => maxInt(V2, bitSizeofType(T)) </sizeof>
          ...</class>
          requires notBool isPODLayoutType(type(classType(C)))
               andBool Key =/=K Union()
               andBool isEmptyClass(T, getClassInfo(D))
               andBool size(intersectSet(getTypesAtOffsetForLayout(T, 0), getTypesAtOffsetForLayout(type(classType(C)), 0))) ==Int 0

     // non-POD-layout non-union, empty base class, type conflict at 0
     rule <k> layoutField(baseClass(D::Class), T::CPPType) => tryLayoutField(baseClass(D), T, V, padTo(V, nvAlignof(T)), true) ...</k>
          <curr-tr-scope> classScope(C::Class, _) </curr-tr-scope>
          <curr-tr-tu> Tu::String </curr-tr-tu>
          <tu-id> Tu </tu-id>
          <class>...
            <class-id> C </class-id>
            <class-type> Key::ClassKey </class-type>
            <dsize> V::Int </dsize>
          ...</class>
          requires notBool isPODLayoutType(type(classType(C)))
               andBool Key =/=K Union()
               andBool isEmptyClass(T, getClassInfo(D))
               andBool size(intersectSet(getTypesAtOffsetForLayout(T, 0), getTypesAtOffsetForLayout(type(classType(C)), 0))) >Int 0

     syntax Set ::= getTypesAtOffsetForLayout(CPPType, Int) [function]

     rule getTypesAtOffsetForLayout(t(... st: bitfieldType(T::CPPSimpleType, _)), 0)
          => SetItem(type(T))

     rule getTypesAtOffsetForLayout(t(... st: arrayType(InnerT::CPPType, _)) #as T::CPPType, 0)
          => SetItem(utype(T)) getTypesAtOffsetForLayout(InnerT, 0)

     rule getTypesAtOffsetForLayout(t(... st: incompleteArrayType(InnerT::CPPType)) #as T::CPPType, 0)
          => SetItem(utype(T)) getTypesAtOffsetForLayout(InnerT, 0)

     rule getTypesAtOffsetForLayout(t(... st: classType(_ :: Class(Struct(), _, _))) #as T::CPPType, 0)
          => SetItem(utype(T)) getTypesAtOffsetForLayoutInStruct(T, getClassInfo(T), 0)

     rule getTypesAtOffsetForLayout(t(... st: classType(_ :: Class(Class(), _, _))) #as T::CPPType, 0)
          => SetItem(utype(T)) getTypesAtOffsetForLayoutInStruct(T, getClassInfo(T), 0)

     rule getTypesAtOffsetForLayout(t(... st: classType(_ :: Class(Union(), _, _))) #as T::CPPType, 0)
          => SetItem(utype(T)) getTypesAtOffsetForLayoutInUnion(T, getClassInfo(T), 0)

     rule getTypesAtOffsetForLayout(t(... st: arrayType(InnerT::CPPType, _)) #as T::CPPType, Offset::Int)
          => getTypesAtOffsetForLayout(InnerT, Offset %Int bitSizeofType(InnerT))
          requires Offset >Int 0

     rule getTypesAtOffsetForLayout(t(... st: incompleteArrayType(InnerT::CPPType)) #as T::CPPType, Offset::Int)
          => getTypesAtOffsetForLayout(InnerT, Offset %Int bitSizeofType(InnerT))
          requires Offset >Int 0

     rule getTypesAtOffsetForLayout(t(... st: classType(_ :: Class(Struct(), _, _))) #as T::CPPType, Offset::Int)
          => getTypesAtOffsetForLayoutInStruct(T, getClassInfo(T), Offset)
          requires Offset >Int 0

     rule getTypesAtOffsetForLayout(t(... st: classType(_ :: Class(Class(), _, _))) #as T::CPPType, Offset::Int)
          => getTypesAtOffsetForLayoutInStruct(T, getClassInfo(T), Offset)
          requires Offset >Int 0

     rule getTypesAtOffsetForLayout(t(... st: classType(_ :: Class(Union(), _, _))) #as T::CPPType, Offset::Int)
          => getTypesAtOffsetForLayoutInUnion(T, getClassInfo(T), Offset)
          requires Offset >Int 0

     rule getTypesAtOffsetForLayout(T::CPPType, Offset::Int) => #if Offset ==Int 0 #then SetItem(utype(T)) #else .Set #fi [owise]

     syntax Set ::= getTypesAtOffsetForLayoutInStruct(CPPType, ClassInfo, Int) [function]
                  | getTypesAtOffsetForLayoutInUnion(CPPType, ClassInfo, Int) [function]

     rule getTypesAtOffsetForLayoutInStruct(_, <class>...
               <non-static-data-members>... ListItem(Class.DataMember(X::CId, T::CPPType)) => .List </non-static-data-members>
               <cenv>... X |-> (_::Map stripType(T) |-> (_, classOffset(_, FOffset::Int))) ...</cenv>
          ...</class>, Offset::Int)
          requires FOffset >Int Offset

     rule getTypesAtOffsetForLayoutInStruct(_, <class>...
               <non-static-data-members>... ListItem(Class.DataMember(X::CId, T::CPPType)) => .List </non-static-data-members>
               <cenv>... X |-> (_::Map stripType(T) |-> (_, uninitialized)) ...</cenv>
          ...</class>, Offset::Int)

     rule getTypesAtOffsetForLayoutInStruct(T::CPPType, <class>...
               <non-static-data-members>... ListItem(Class.DataMember(X::CId, T'::CPPType)) </non-static-data-members>
               <cenv>... X |-> (_::Map stripType(T') |-> (_, classOffset(_, FOffset::Int))) ...</cenv>
          ...</class>, Offset::Int)
          => getTypesAtOffsetForLayout(T', Offset -Int FOffset)
          requires FOffset <=Int Offset

     rule getTypesAtOffsetForLayoutInStruct(_, <class>...
               <base-classes>... ListItem(C:Class) => ListItem(type(classType(C))) </base-classes>
          ...</class>, _)

     rule getTypesAtOffsetForLayoutInStruct(T::CPPType, <class>...
               <base-classes>... ListItem(t(... st: classType(C::Class)) #as T'::CPPType) => .List </base-classes>
               <non-static-data-members> .List </non-static-data-members>
               <cenv>... baseClass(C) |-> (_::Map stripType(T') |-> (_, classOffset(_, FOffset::Int))) ...</cenv>
          ...</class>, Offset::Int)
          requires FOffset >Int Offset

     rule getTypesAtOffsetForLayoutInStruct(T::CPPType, <class>...
               <base-classes>... ListItem(t(... st: classType(C::Class)) #as T'::CPPType) => .List </base-classes>
               <non-static-data-members> .List </non-static-data-members>
               <cenv>... baseClass(C) |-> (_::Map stripType(T') |-> (_, uninitialized)) ...</cenv>
          ...</class>, Offset::Int)

     rule getTypesAtOffsetForLayoutInStruct(T::CPPType, <class>...
               <base-classes>... ListItem(t(... st: classType(C::Class)) #as T'::CPPType) </base-classes>
               <non-static-data-members> .List </non-static-data-members>
               <cenv>... baseClass(C) |-> (_::Map stripType(T') |-> (_, classOffset(_, FOffset::Int))) ...</cenv>
          ...</class>, Offset::Int)
          => getTypesAtOffsetForLayout(T', Offset -Int FOffset)
          requires FOffset <=Int Offset

     rule getTypesAtOffsetForLayoutInStruct(_, <class>...
               <base-classes> .List </base-classes>
               <non-static-data-members> .List </non-static-data-members>
          ...</class>, _) => .Set

     rule getTypesAtOffsetForLayoutInUnion(T::CPPType, <class>
               <non-static-data-members> ListItem(Class.DataMember(_, T'::CPPType)) Ds::List </non-static-data-members>
               Rest::Bag
          </class>, Offset::Int)
          => getTypesAtOffsetForLayout(T', Offset)
               getTypesAtOffsetForLayoutInUnion(T, <class> <non-static-data-members> Ds </non-static-data-members> Rest </class>, Offset)

     rule getTypesAtOffsetForLayoutInUnion(...) => .Set [owise]

     rule <k> layoutBases(.List, .List) => .K ...</k>
          <curr-tr-scope> classScope(C::Class, _) </curr-tr-scope>
          requires isPODLayoutType(type(classType(C)))

     rule <k> layoutVirtualBases(.List) => .K ...</k>
          <curr-tr-scope> classScope(C::Class, _) </curr-tr-scope>
          <curr-tr-tu> Tu::String </curr-tr-tu>
          <tu-id> Tu </tu-id>
          <class>...
            <class-id> C </class-id>
            <sizeof> V::Int => maxInt(1, padTo(V,A) /Int cfg:bitsPerByte) </sizeof> // becomes size in bytes after completing layout
            <align> A::Int </align>
            <nvsize> _ => maxInt(1, padTo(V,A) /Int cfg:bitsPerByte) *Int cfg:bitsPerByte </nvsize> // becomes final size in bits
            <nvalign> _ => A </nvalign> // align in bytes
          ...</class>
          requires isPOD03Type(type(classType(C)))


     rule <k> layoutVirtualBases(.List) => .K ...</k>
          <curr-tr-scope> classScope(C::Class, _) </curr-tr-scope>
          <curr-tr-tu> Tu::String </curr-tr-tu>
          <tu-id> Tu </tu-id>
          <class>...
            <class-id> C </class-id>
            <align> A::Int </align>
            <sizeof> V::Int => maxInt(1, padTo(V, A) /Int cfg:bitsPerByte) </sizeof> // becomes size in bytes after completing layout
            <nvalign> _ => A </nvalign> // align in bytes
            <nvsize> _ => V </nvsize> // becomes sizeof in bits
          ...</class>
          requires notBool isPOD03Type(type(classType(C)))

     rule <k> layoutBases(Bases::List, VirtualBases::List) => computePrimaryBase(Bases, VirtualBases, .List, .K) ...</k>
          <curr-tr-scope> classScope(C::Class, _) </curr-tr-scope>
          requires hasVirtualMembers(type(classType(C)))

     rule <k> computePrimaryBase((ListItem(Base::Class) => .List) _, _, _::List (.List => ListItem(Base)), Primary:K) ...</k>
          requires notBool hasVirtualMembers(type(classType(Base))) orBool Primary =/=K .K

     rule <k> computePrimaryBase((ListItem(Base::Class) => .List) _, _, _, .K => Base) ...</k>
          requires hasVirtualMembers(type(classType(Base)))

     rule <k> computePrimaryBase(.List, .List, NonPrimary::List, .K) => #layoutBases(NonPrimary) ...</k>
          <curr-tr-scope> classScope(C::Class, _) </curr-tr-scope>
          <curr-tr-tu> Tu::String </curr-tr-tu>
          <tu-id> Tu </tu-id>
          <class>...
            <class-id> C </class-id>
            <sizeof> 0 => bitSizeofType(type(pointerType(type(void)))) </sizeof>
            <dsize> 0 => bitSizeofType(type(pointerType(type(void)))) </dsize>
            <align> 1 => byteAlignofType(type(pointerType(type(void)))) </align>
          ...</class>

     rule computePrimaryBase(.List, .List, NonPrimary::List, Primary:Class) => #layoutBases(ListItem(Primary) NonPrimary)

     rule <k> layoutBases(Bases::List, .List) => #layoutBases(Bases) ...</k>
          <curr-tr-scope> classScope(C::Class, _) </curr-tr-scope>
          requires notBool hasVirtualMembers(type(classType(C)))

     rule <k> (.K => layoutField(baseClass(B), type(classType(B))))
              ~> #layoutBases((ListItem(B::Class) => .List) _) ...</k>
          <curr-tr-scope> classScope(C::Class, _) </curr-tr-scope>

     rule <k> #layoutBases(.List) => .K ...</k>
          <curr-tr-scope> classScope(C::Class, _) </curr-tr-scope>

     rule <k> AccessSpec(AS::AccessSpecifier) => .K ...</k>
          <curr-tr-scope> classScope(C::Class, _) </curr-tr-scope>
          <curr-tr-tu> Tu::String </curr-tr-tu>
          <tu-id> Tu </tu-id>
          <class>...
            <class-id> C </class-id>
            <access-specifier> _ => AS </access-specifier>
          ...</class>

     syntax Int ::= updateMaxOffset(Int, CPPType, ClassKey) [function]

     rule updateMaxOffset(V::Int, T::CPPType, Union()) => maxInt(V, bitSizeofType(T))

     rule updateMaxOffset(V::Int, T::CPPType, _) => pad(V,T) +Int bitSizeofType(T)
          requires notBool isWideBitfield(T)

     rule updateMaxOffset(V::Int, T::CPPType, _) => pad(V, getT'(T)) +Int bitSizeofType(T) [owise]

     syntax Int ::= padOrNot(Int, CPPType, ClassKey) [function]

     rule padOrNot(_, _, Union()) => 0

     rule padOrNot(V::Int, T::CPPType, _) => pad(V, T) [owise]

     // TODO(traiansf): Handle pack directives
     // taken from c-semantics/semantics/c/language/translation/decl/tagged.k
     //
     // The padding associated with a particular field precedes it, with
     // possibly some extra padding at the end of the whole struct not
     // associated with any field. This is important for understanding the
     // effect of the gcc et al. padding attr as applied to a particular field.

     syntax Int ::= pad(Int, CPPType) [function, klabel(cppPad)]

     // Non-bitfields are aligned according to their type (if we note that
     // fields tagged with the Packed() attribute have an alignment of 1 byte).
     rule pad(V::Int, T::CPPType) => padTo(V, byteAlignofType(T))
          requires notBool isCPPBitfieldType(T)

     // Non-packed bitfields that would cross an alignment boundary and
     // zero-length bitfields have an alignment of the bitfield field type.
     rule pad(V::Int, t(... st: bitfieldType(...)) #as T::CPPType) => padTo(V, byteAlignofType(innerType(T)))
          requires // notBool (Packed() in getModifiers(T)) andBool
            (V +Int bitSizeofType(T)) >Int padTo(V, byteAlignofType(innerType(T)))

     rule pad(V::Int, t(... st: bitfieldType(...)) #as T::CPPType) => padTo(V, byteAlignofType(innerType(T)))
          requires bitSizeofType(T) ==Int 0

     // Packed bitfields and non-packed bitfields that don't cross an alignment
     // boundary have 1-bit alignment (no padding).
     rule pad(V::Int, _) => V [owise]

     // brace-or-equal initializers need to be evalauted in class scope
     rule <k> evalBraceOrEqualInitializer(C::Class, Base::LVal, E::Expr) => E ~> returnFromBraceOrEqualInitializer(Base, OldScope) ...</k>
          <curr-tr-scope> OldScope::Scope => classScope(C, true) </curr-tr-scope>
          requires Translation()

     rule <k> le(E::Expr => evalBraceOrEqualInitializer(C, Base, E), _, _)
           ~> (returnFromBraceOrEqualInitializer(Base::LVal, Scope::Scope) => .K)
          ...</k>
          <curr-tr-scope> classScope(C::Class, _) => Scope </curr-tr-scope>

     rule <k> xe(E::Expr => evalBraceOrEqualInitializer(C, Base, E), _, _)
           ~> (returnFromBraceOrEqualInitializer(Base::LVal, Scope::Scope) => .K)
          ...</k>
          <curr-tr-scope> classScope(C::Class, _) => Scope </curr-tr-scope>

     rule <k> pre(E::Expr => evalBraceOrEqualInitializer(C, Base, E), _, _)
           ~> (returnFromBraceOrEqualInitializer(Base::LVal, Scope::Scope) => .K)
          ...</k>
          <curr-tr-scope> classScope(C::Class, _) => Scope </curr-tr-scope>

     rule <k> V:Val ~> (returnFromBraceOrEqualInitializer(_, Scope::Scope) => .K) ...</k>
          <curr-tr-scope> _ => Scope </curr-tr-scope>
          requires notBool (isLExpr(V) orBool isPRExpr(V))

     rule <k> typeof(evalBraceOrEqualInitializer(C::Class, Base::LVal, E::Expr) => E)
           ~> (.K => returnFromBraceOrEqualInitializer(Base, OldScope))
          ...</k>
          <curr-tr-scope> OldScope::Scope => classScope(C, true) </curr-tr-scope>

     rule <k> typeof(V:CPPType) ~> (returnFromBraceOrEqualInitializer(_, Scope::Scope) => .K) ...</k>
          <curr-tr-scope> _ => Scope </curr-tr-scope>

     rule <k> catof(evalBraceOrEqualInitializer(C::Class, Base::LVal, E::Expr) => E)
           ~> (.K => returnFromBraceOrEqualInitializer(Base, OldScope))
          ...</k>
          <curr-tr-scope> OldScope::Scope => classScope(C, true) </curr-tr-scope>

     rule <k> catof(V:ValueCategory) ~> (returnFromBraceOrEqualInitializer(_, Scope::Scope) => .K) ...</k>
          <curr-tr-scope> _ => Scope </curr-tr-scope>

     rule Class.getNonStaticDataMembers(<class>... <non-static-data-members> L::List </non-static-data-members> ...</class>) => L

     rule Class.getDataMembersInitializers(<class>... <initializers> M::Map </initializers> ...</class>) => M
endmodule
