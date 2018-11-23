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
     syntax Bool ::= isTrivialDefaultConstructor(CPPFunctionType, K) [function]
                   | isNonTrivialDefaultConstructor(CPPFunctionType, K) [function]
                   | isDefaultConstructor(CPPFunctionType, K) [function]
                   | isUserProvidedConstructor(CPPFunctionType, K) [function]
                   | isUserProvidedDefaultConstructor(CPPFunctionType, K) [function]
                   | isDeleted(CPPFunctionType, K) [function]
                   | isDeletedDefaultConstructor(CPPFunctionType, K) [function, klabel(isDeletedDefaultConstructor2)]
                   | isNonTrivialDestructor(CPPFunctionType, K) [function]
                   | isTrivialDestructor(CPPFunctionType, K) [function]
                   | isUserProvidedDestructor(CPPFunctionType, K) [function]
                   | isVirtualDestructor(CPPFunctionType, K) [function]
                   | hasConstructorThat(CPPClassType, K) [function]
                   | hasDestructorThat(CPPClassType, K) [function]
     syntax Bool ::= isPODLayoutType(CPPType) [function]
     syntax List ::= "Class.getNonStaticDataMembers" "(" ClassInfo ")" [function]
     syntax Map ::= "Class.getDataMembersInitializers" "(" ClassInfo ")" [function]
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

     rule TypeDecl(ElaboratedTypeSpecifier(T:ClassKey, X::CId, NoNNS()) => declareClassName(T, X, true))

     context TypeDecl(HOLE:AType) 
             requires notBool isClassNameElabSpecifier(HOLE) [result(CPPTypeExpr)]
     context TypeDecl(HOLE:CPPTypeExpr)
             requires notBool isDependentInScope(HOLE)
                  andBool notBool isClassNameElabSpecifier(HOLE) [result(CPPType)]

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

     syntax NNSVal ::= getNNSVal(Scope) [function]
     rule getNNSVal(namespaceScope(N::Namespace)) => N
     rule getNNSVal(classScope(C::Class, _)) => C
     rule getNNSVal(_:BlockScope) => NoNamespace()

     rule <k> classContext(t(_, _, classType((N::Namespace :: Class(ClassKey::Tag, X::CId, _)) #as C::Class)) #as T::CPPType, Bases::List, Members::List) 
              => setScope(classScope(C, false))
              ~> listToK(Bases)
              ~> setScope(classScope(C, true))
              ~> listToK(Members)
              ~> implicitDeclarations()
              ~> deferredActions(OldClass)
              ~> setScope(OldScope)
          ...</k>
          <deferred-class-actions> OldClass:K => layoutBases(.List, .List) |> layoutVirtualBases(.List) |> .K |> .Ordering </deferred-class-actions>
          <curr-template-context> noTemplate </curr-template-context>
          <curr-tr-scope> OldScope::Scope </curr-tr-scope>
          <curr-tr-tu> Tu::String </curr-tr-tu>
          <tu-id> Tu </tu-id>
          <ns-id> N </ns-id>
          <ntypes> NT::Map => NT[X <- T] </ntypes>
          (.Bag => <class>...
            <class-id> C </class-id>
            <class-type> ClassKey </class-type>
            // injected class name
            <ctypes> X |-> T </ctypes>
            <access> X |-> Public() </access>
            <access-specifier> getDefaultAccessType(ClassKey) </access-specifier>
          ...</class>)

     rule <k> classContext(t(_, _, classType((C2::Class :: Class(ClassKey::Tag, X::CId, _)) #as C::Class)) #as T::CPPType, Bases::List, Members::List) 
              => setScope(classScope(C, false))
              ~> listToK(Bases)
              ~> setScope(classScope(C, true))
              ~> listToK(Members)
              ~> implicitDeclarations()
              ~> deferredActions(OldClass)
              ~> setScope(OldScope)
          ...</k>
          <deferred-class-actions> OldClass:K => layoutBases(.List, .List) |> layoutVirtualBases(.List) |> .K |> .Ordering </deferred-class-actions>
          <curr-template-context> noTemplate </curr-template-context>
          <curr-tr-scope> OldScope::Scope </curr-tr-scope>
          <curr-tr-tu> Tu::String </curr-tr-tu>
          <tu-id> Tu </tu-id>
          (<class-id> C2 </class-id>
          <ctypes> CT::Map => CT[X <- T] </ctypes>)
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
          <cenv>... ConstructorId(X) |-> M::TypeMap DestructorId(X) |-> _ ...</cenv>
          <is-aggregate> B:Bool => B andBool notBool some(M, #klabel(`isUserProvidedConstructor`)) andBool notBool hasVirtualMembers(type(classType(C))) </is-aggregate>

     // TODO(dwightguth): implicit exception spec
     rule <k> (.K => AccessSpec(Public()) ~> Specifier(Inline(), 
                   FunctionDefinition(NoNNS(), ConstructorId(X), #NoName,
                        MethodPrototype(false, true, type(pointerType(type(classType(C)))), 
                             FunctionPrototype(type(void), list(.List), NoExceptionSpec(), false)),
                        .List, Defaulted())))
              ~> implicitDeclarations() ...</k>
          <curr-tr-scope> classScope(_ :: Class(_, X::CId, _) #as C::Class, _) </curr-tr-scope>
          <curr-tr-tu> Tu::String </curr-tr-tu>
          <tu-id> Tu </tu-id>
          <class-id> C </class-id>
          <cenv> Env::Map </cenv>
          requires notBool ConstructorId(X) in_keys(Env)

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
               andBool notBool some(Bases, #klabel(`hasVirtualDestructor`))

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
               andBool some(Bases, #klabel(`hasVirtualDestructor`))

     syntax Bool ::= hasVirtualDestructor(Class) [function]
     rule hasVirtualDestructor(C::Class) => hasDestructorThat(type(classType(C)), #klabel(`isVirtualDestructor`))

     syntax Stmt ::= "TwriteVTables"
     rule toExecution(TwriteVTables) => writeVTables

     rule <k> Constructor(Ctor::List, S::Stmt) => figureConstruct(Ctor, .Map, Bases, NSDM, S, elaborateThen(TwriteVTables), false) ...</k>
          <curr-tr-scope> blockScope(C::Class :: ConstructorId(_), _, _) </curr-tr-scope>
          <curr-tr-tu> Tu::String </curr-tr-tu>
          <tu-id> Tu </tu-id>
          <class-id> C </class-id>
          <base-classes> Bases::List </base-classes>
          <non-static-data-members> NSDM::List </non-static-data-members>

     rule <k> Defaulted() => Constructor(.List, BlockStmt(!N:Int, .List)) ...</k>
          <curr-tr-scope> blockScope(C::Class :: ConstructorId(_), _, _) </curr-tr-scope>

     syntax Stmt ::= figureConstruct(ctors: List, processedCtors: Map, bases: List, dataMembers: List, body: Stmt, result: K, hasNonConstVariantMember: Bool)

     rule figureConstruct(... ctors: (ListItem(ConstructorMember(X::CId, I::Init)) => .List) _, processedCtors: M::Map => M[X <- I])
     context figureConstruct(... ctors: ListItem(ConstructorBase(HOLE:AType, _, _, _)) _)
     rule figureConstruct(... ctors: (ListItem(ConstructorBase(t(... st: classType(C::Class)), false, false, I::Init)) => .List) _, processedCtors: M::Map => M[C <- I])

     // 12.1:4
     rule <k> figureConstruct(.List, _, .List, ListItem(Class.DataMember(X::CId, T::CPPType)) _, _, _, _) => Deleted() ...</k>
          <curr-tr-scope> blockScope(C::Class :: ConstructorId(_), Base::SymBase, _) </curr-tr-scope>
          <functions>... Base |-> functionObject(_, FuncT::CPPFunctionType, _, _) ...</functions>
          <curr-tr-tu> Tu::String </curr-tr-tu>
          <tu-id> Tu </tu-id>
          <class-id> C </class-id>
          <variant-members> VM::Set </variant-members>
          <initializers>... X |-> (T |-> I::Init) ...</initializers>
          requires isDeletedDefaultConstructor(X, T, C, FuncT, VM, I)
     // 12.1:4.6-4.7
     rule <k> (.K => checkCtorAndDtor(MemInit[X] orDefault .K, X, T, true, I, getMostDerivedArrayElement(T))) ~> figureConstruct(.List, MemInit::Map, .List, (ListItem(Class.DataMember(X::CId, T::CPPType)) => .List) _, _, _, _) ...</k>
          <curr-tr-scope> blockScope(C::Class :: ConstructorId(_), Base::SymBase, _) </curr-tr-scope>
          <functions>... Base |-> functionObject(_, FuncT::CPPFunctionType, _, _) ...</functions>
          <curr-tr-tu> Tu::String </curr-tr-tu>
          <tu-id> Tu </tu-id>
          <class-id> C </class-id>
          <variant-members> VM::Set </variant-members>
          <initializers>... X |-> (T |-> I::Init) ...</initializers>
          requires notBool isDeletedDefaultConstructor(X, T, C, FuncT, VM, I)
     rule <k> (.K => checkCtorAndDtor(MemInit[C] orDefault .K, baseClass(C), type(classType(C)), false, NoInit(), type(classType(C)))) ~> figureConstruct(.List, MemInit::Map, (ListItem(C::Class) => .List) _, _, _, _, _) ...</k>
          <curr-tr-scope> blockScope(_, Base::SymBase, _) </curr-tr-scope>
          <functions>... Base |-> functionObject(_, FuncT::CPPFunctionType, _, _) ...</functions>
          requires notBool isMethodUserProvided(FuncT)
     rule <k> (.K => figureConstructItem(MemInit[C] orDefault .K, baseClass(C), type(classType(C)), false)) ~> figureConstruct(.List, MemInit::Map, (ListItem(C::Class) => .List) _, _, _, _, _) ...</k>
          <curr-tr-scope> blockScope(_, Base::SymBase, _) </curr-tr-scope>
          <functions>... Base |-> functionObject(_, FuncT::CPPFunctionType, _, _) ...</functions>
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
     rule <k> (.K => resolve(resolveOverload(cSet(Candidates, M :: ConstructorId(X)), list(.List), constructor)))
              ~> checkCtor(_ :: Class(_, X::CId, _) #as M::Class)
          ...</k>
          <curr-tr-tu> Tu::String </curr-tr-tu>
          <tu-id> Tu </tu-id>
          <class-id> M </class-id>
          <cenv>... ConstructorId(X) |-> Candidates::TypeMap ...</cenv>
     rule resolve(E:ResolvedExpr) ~> checkCtor(_) => .K
          requires notBool isNotFoundNameRef(E)
     rule <k> (.K => resolve(checkAccess(CallExpr(lv(lnew(Base), hasTrace(Name(NoNNS(), DestructorId(X))), T), list(.List), krlist(.List)))))
              ~> checkDtor(_ :: Class(_, X::CId, _) #as M::Class)
          ...</k>
          <curr-tr-tu> Tu::String </curr-tr-tu>
          <tu-id> Tu </tu-id>
          <class-id> M </class-id>
          <cenv>... DestructorId(X) |-> (T::CPPType |-> envEntry(... base: Base::SymBase)) ...</cenv>
     rule resolve(E:ResolvedExpr) ~> checkDtor(_) => .K
          requires notBool isNotFoundNameRef(E)

     syntax Bool  ::= isDeletedDefaultConstructor(CId, CPPType, Class, CPPFunctionType, Set, Init) [function]

     // 12.1:4.1
     rule isDeletedDefaultConstructor(X::CId, T::CPPType, C::Class, FuncT::CPPFunctionType, VM::Set, _) => true
          requires X in VM andBool isUnionLikeClass(C) andBool #fun(InnerT::CPPType => isCPPClassType(InnerT) 
               andBool hasConstructorThat({InnerT}:>CPPClassType, #klabel(`isNonTrivialDefaultConstructor`)))(getMostDerivedArrayElement(T))
               andBool notBool isUserProvidedConstructor(FuncT, .K)
     // 12.1:4.2
     rule isDeletedDefaultConstructor(_, T:CPPRefType, C::Class, FuncT::CPPFunctionType, _, NoInit()) => true
          requires notBool isUserProvidedConstructor(FuncT, .K)
     // 12.1:4.3
     rule isDeletedDefaultConstructor(X::CId, T::CPPType, _, FuncT::CPPFunctionType, VM::Set, NoInit()) => true
          requires notBool X in VM andBool #fun(InnerT::CPPType => isCPPClassType(InnerT) andBool isConstType(InnerT) andBool notBool hasConstructorThat({InnerT}:>CPPClassType, #klabel(`isUserProvidedDefaultConstructor`)))(getMostDerivedArrayElement(T))
               andBool notBool isUserProvidedConstructor(FuncT, .K)
     rule isDeletedDefaultConstructor(_::CId, _, _, _, _, _) => false [owise]

     // 12.1:4.4 (4.5 is implicit when constructing the anonymous union)
     rule <k> figureConstruct(.List, _, .List, .List, _, _, false) => Deleted() ...</k>
          <curr-tr-scope> blockScope((_::ClassQualifier :: Class(Union(), _, _)) #as C::Class :: ConstructorId(_), Base::SymBase, _) </curr-tr-scope>
          <functions>... Base |-> functionObject(_, FuncT::CPPFunctionType, _, _) ...</functions>
          requires notBool isUserProvidedConstructor(FuncT, .K)
 

     syntax KItem ::= figureConstructItem(memInit: K, CId, CPPType, isMember: Bool)

     // 12.6.2:7
     rule <k> (figureConstructItem(I::Init, X::CId, T::CPPType, IsMember:Bool) => .K) ~> figureConstruct(.List, _, _, _, _,
                   (Res:K => Res ~> TExpressionStmt(figureConstructorInit(Name(C, X), T, I, notBool IsMember))),
                   B:Bool => B orBool (IsMember andBool X in VM andBool notBool isConstType(getMostDerivedArrayElement(T)))) ...</k>
          <curr-tr-scope> blockScope(C::Class :: ConstructorId(_), _, _) </curr-tr-scope>
          <curr-tr-tu> Tu::String </curr-tr-tu>
          <tu-id> Tu </tu-id>
          <class-id> C </class-id>
          <variant-members> VM::Set </variant-members>
          requires I =/=K .K

     // 12.6.2:8.1
     // TODO(dwightguth): ctor-initializers and base classes
     // TODO(traiansf): unions
     rule <k> (figureConstructItem(.K, X::CId, T::CPPType, true) => .K) ~> figureConstruct(.List, .Map, _, _, _, 
                   (Res:K => Res ~> TExpressionStmt(figureConstructorInit(Name(C, X), T, I, false))),
                   B:Bool => B orBool (X in VM andBool notBool isConstType(getMostDerivedArrayElement(T)))) ...</k>
          <curr-tr-scope> blockScope(C::Class :: ConstructorId(_), _, _) </curr-tr-scope>
          <curr-tr-tu> Tu::String </curr-tr-tu>
          <tu-id> Tu </tu-id>
          <class-id> C </class-id>
          <initializers>... X |-> (T |-> I::Init) ...</initializers>
          <variant-members> VM::Set </variant-members>
          requires I =/=K NoInit()
     // 12.6.2:8.2
     // TODO(traiansf): anonymous unions
     rule <k> (figureConstructItem(.K, X::CId, T::CPPType, true) => .K) ~> figureConstruct(.List, _, _, _, _, _,
                   B:Bool => B orBool (notBool isConstType(getMostDerivedArrayElement(T)))) ...</k>
          <curr-tr-scope> blockScope(C::Class :: ConstructorId(_), _, _) </curr-tr-scope>
          <curr-tr-tu> Tu::String </curr-tr-tu>
          <tu-id> Tu </tu-id>
          <class-id> C </class-id>
          <initializers>... X |-> (T |-> I::Init) ...</initializers>
          <variant-members> VM::Set </variant-members>
          requires I ==K NoInit() andBool X in VM

     // 12.6.2:8.3
     rule <k> (figureConstructItem(.K, X::CId, T::CPPType, true) => .K) ~> figureConstruct(.List, _, _, _, _, 
                   (Res:K => Res ~> TExpressionStmt(defaultConstructorInit(Name(C, X), T, false))), _) ...</k>
          <curr-tr-scope> blockScope(C::Class :: ConstructorId(_), _, _) </curr-tr-scope>
          <curr-tr-tu> Tu::String </curr-tr-tu>
          <tu-id> Tu </tu-id>
          <class-id> C </class-id>
          <initializers>... X |-> (T |-> I::Init) ...</initializers>
          <variant-members> VM::Set </variant-members>
          requires I ==K NoInit() andBool notBool X in VM
     rule <k> (figureConstructItem(.K, X::CId, T::CPPType, false) => .K) ~> figureConstruct(.List, _, _, _, _, 
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
                   | #hasMethodThat(CId, ClassInfo, K) [function]
                   | #isDeleted(SymBase, K) [function]
     // 12.1:4.8
     rule isTrivialDefaultConstructor(T::CPPFunctionType, K:K) => isDefaultConstructor(T, K) andBool notBool isUserProvidedConstructor(T, K) andBool notBool hasVirtualMembers(type(classType(getMethodClass(T)))) andBool #isTrivialDefaultConstructor(getClassInfo(getMethodClass(T)))
     // 12.1:4.10
     rule #isTrivialDefaultConstructor(<class>... <base-classes> ListItem(C::Class) => .List ...</base-classes> ...</class>)
          requires hasConstructorThat(type(classType(C)), #klabel(`isTrivialDefaultConstructor`))
     // 12.1:4.9,4.11
     rule #isTrivialDefaultConstructor(<class>... <non-static-data-members> ListItem(Class.DataMember(X::CId, T::CPPType)) => .List ...</non-static-data-members> <initializers>... X |-> (T |-> NoInit()) ...</initializers> ...</class>)
          requires #if isCPPClassType(getMostDerivedArrayElement(T)) #then hasConstructorThat({getMostDerivedArrayElement(T)}:>CPPClassType, #klabel(`isTrivialDefaultConstructor`)) #else true #fi
     rule #isTrivialDefaultConstructor(<class>... <base-classes> .List </base-classes> <non-static-data-members> .List </non-static-data-members> ...</class>) => true
     rule #isTrivialDefaultConstructor(...) => false [owise]

     rule isNonTrivialDefaultConstructor(T::CPPFunctionType, K:K) => isDefaultConstructor(T, K) andBool notBool isTrivialDefaultConstructor(T, K)

     rule isDefaultConstructor(T::CPPFunctionType, envEntry(... defaultArgs: DA::DefaultArgumentsResult)) => acceptsNArgs(0, T, getDefaultArgsVals(DA))
     rule isUserProvidedConstructor(T::CPPFunctionType, _) => isMethodUserProvided(T)
     rule isUserProvidedDestructor(T::CPPFunctionType, _) => isMethodUserProvided(T)
     rule isVirtualDestructor(T::CPPFunctionType, _) => isMethodVirtual(T)
     rule isUserProvidedDefaultConstructor(T::CPPFunctionType, K:K) => isDefaultConstructor(T, K) andBool isUserProvidedConstructor(T, K)

     rule hasConstructorThat(t(... st: classType(_ :: Class(_, X::CId, _))) #as T::CPPClassType, Lbl:K) => #hasMethodThat(ConstructorId(X), getClassInfo(T), Lbl)
     rule hasDestructorThat(t(... st: classType(_ :: Class(_, X::CId, _))) #as T::CPPClassType, Lbl:K) => #hasMethodThat(DestructorId(X), getClassInfo(T), Lbl)
     rule #hasMethodThat(X::CId, <class>... <cenv>... X |-> M::TypeMap ...</cenv> ...</class>, Lbl:K)
          => some(M, Lbl)
     rule #hasMethodThat(...) => false [owise]

     rule isDeleted(_, envEntry(... base: Base::SymBase)) => #isDeleted(Base, #configuration)
     rule #isDeleted(Base::SymBase, <generatedTop>... <functions>... Base |-> Deleted() ...</functions> ...</generatedTop>) => true
     rule #isDeleted(...) => false [owise]
     rule isDeletedDefaultConstructor(T::CPPFunctionType, K:K) => isDeleted(T, K) andBool isDefaultConstructor(T, K)

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

     // 12.4:5
     rule <k> figureDestruct(.List, ListItem(Class.DataMember(X::CId, T::CPPType)) _, _) => Deleted() ...</k>
          <curr-tr-scope> blockScope(C::Class :: ConstructorId(_), Base::SymBase, _) </curr-tr-scope>
          <functions>... Base |-> functionObject(_, FuncT::CPPFunctionType, _, _) ...</functions>
          <curr-tr-tu> Tu::String </curr-tr-tu>
          <tu-id> Tu </tu-id>
          <class-id> C </class-id>
          <variant-members> VM::Set </variant-members>
          requires isDeletedDefaultDestructor(X, T, C, FuncT, VM)
     // 12.4:5.2
     rule <k> (.K => checkDtor(X, T, getMostDerivedArrayElement(T), VM, FuncT)) ~> figureDestruct(.List, (ListItem(Class.DataMember(X::CId, T::CPPType)) => .List) _, _) ...</k>
          <curr-tr-scope> blockScope(C::Class :: DestructorId(_), Base::SymBase, _) </curr-tr-scope>
          <functions>... Base |-> functionObject(_, FuncT::CPPFunctionType, _, _) ...</functions>
          <curr-tr-tu> Tu::String </curr-tr-tu>
          <tu-id> Tu </tu-id>
          <class-id> C </class-id>
          <variant-members> VM::Set </variant-members>
          requires notBool isDeletedDefaultDestructor(X, T, C, FuncT, VM)
     rule <k> (.K => checkDtor(baseClass(M), type(classType(M)), type(classType(M)), VM, FuncT)) ~> figureDestruct((ListItem(M::Class) => .List) _, _, _) ...</k>
          <curr-tr-scope> blockScope(C::Class :: DestructorId(_), Base::SymBase, _) </curr-tr-scope>
          <functions>... Base |-> functionObject(_, FuncT::CPPFunctionType, _, _) ...</functions>
          <curr-tr-tu> Tu::String </curr-tr-tu>
          <tu-id> Tu </tu-id>
          <class-id> C </class-id>
          <variant-members> VM::Set </variant-members>
          <virtual-bases> .Set </virtual-bases>

     syntax K ::= checkDtor(CId, CPPType, CPPType, Set, CPPFunctionType) [function, klabel(checkDtor3)]
     rule checkDtor(X::CId, T::CPPType, M::CPPType, VM::Set, FuncT::CPPFunctionType)
          => figureDestructItem(X, T, VM)
          requires notBool isCPPClassType(M) orBool isMethodUserProvided(FuncT)
     rule checkDtor(X::CId, T::CPPType, t(... st: classType(M::Class)), VM::Set, _)
          => checkDtor(M) ~> figureDestructItem(X, T, VM) [owise]

     syntax Bool ::= isDeletedDefaultDestructor(CId, CPPType, Class, CPPFunctionType, Set) [function]

     // 12.4:5.1
     rule isDeletedDefaultDestructor(X::CId, T::CPPType, C::Class, FuncT::CPPFunctionType, VM::Set) => true
          requires X in VM andBool isUnionLikeClass(C) andBool #fun(InnerT::CPPType => isCPPClassType(InnerT)
               andBool hasDestructorThat({InnerT}:>CPPClassType, #klabel(`isNonTrivialDestructor`)))(getMostDerivedArrayElement(T))
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
          <functions>... Base |-> functionObject(_, FuncT::CPPFunctionType, _, _) ...</functions>
          requires notBool isMethodVirtual(FuncT)

     rule <k> (.K => lookupAllocationFunction(operatordelete, type(classType(C)), false)) ~> figureDestruct(.List, .List, _) ...</k>
          <curr-tr-scope> blockScope(C::Class :: DestructorId(_), Base::SymBase, _) </curr-tr-scope>
          <functions>... Base |-> functionObject(_, FuncT::CPPFunctionType, _, _) ...</functions>
          requires isMethodVirtual(FuncT)

     rule (cSet(... candidates: Cands::TypeMap, id: Q::QualId) #as C:CandidateSet => resolve(resolveOverload(C, list(ListItem(prv(NullPointer, noTrace, type(pointerType(type(void))))) getSecondDeleteArg(Cands, prv(0, noTrace, type(size_t)))), Name(NoNNS(), operatordelete))))
          ~> figureDestruct(...)
     rule resolve(E:ResolvedExpr) ~> figureDestruct(.List, .List, Res:K) => Res
          requires notBool isNotFoundNameRef(E)

     syntax KItem ::= TaddToConstructed(Expr, CPPType) [strict(1)]
     rule <k> TaddToConstructed(L:LVal, T::CPPType) => .K ...</k>
          <elab>... .K => addToConstructed(L, T) </elab>

     syntax Bool ::= #isTrivialDestructor(ClassInfo) [function]

     // 12.4:5.4
     rule isTrivialDestructor(T::CPPFunctionType, K:K) => notBool isUserProvidedDestructor(T, K) andBool notBool isMethodVirtual(T) andBool #isTrivialDestructor(getClassInfo(getMethodClass(T)))     
     rule #isTrivialDestructor(<class>... <base-classes> ListItem(C::Class) => .List ...</base-classes> ...</class>)
          requires hasDestructorThat(type(classType(C)), #klabel(`isTrivialDestructor`))
     rule #isTrivialDestructor(<class>... <non-static-data-members> ListItem(Class.DataMember(_, T::CPPType)) => .List ...</non-static-data-members> ...</class>)
          requires #if isCPPClassType(getMostDerivedArrayElement(T)) #then hasDestructorThat({getMostDerivedArrayElement(T)}:>CPPClassType, #klabel(`isTrivialDestructor`)) #else true #fi
     rule #isTrivialDestructor(<class>... <base-classes> .List </base-classes> <non-static-data-members> .List </non-static-data-members> ...</class>) => true
     rule #isTrivialDestructor(...) => false [owise]

     rule isNonTrivialDestructor(T::CPPFunctionType, K:K) 
          => notBool isTrivialDestructor(T, K)
     
     syntax AccessSpecifier ::= getDefaultAccessType(Tag) [function]
     rule getDefaultAccessType(Class()) => Private()
     rule getDefaultAccessType(Struct()) => Public()
     rule getDefaultAccessType(Union()) => Public()

     context BitFieldDecl(_, _, _, (HOLE:Expr => reval(HOLE))) [result(PRVal)]

     rule BitFieldDecl(NoNNS(), X::CId, t(Q::Quals, Mods::Set, T::CPPSimpleType), prv(N::Int, _, _)) => declareField(X, t(Q, Mods, bitfieldType(T, N)), NoInit())

     rule FieldDecl(NoNNS(), X::CId, T::CPPType, Init::Init) => declareField(X, T, Init)

     syntax KItem ::= declareField(CId, CPPType, Init) [strict(2)]

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
     rule isPODLayoutType(T:CPPScalarType) => true
     rule isPODLayoutType(T:CPPArrayType) => isPODLayoutType(innerType(T))
     rule isPODLayoutType(T:CPPClassType) => isPODLayoutClass(T, getClassInfo(T))
     rule isPODLayoutType(_) => false [owise]
     rule isPOD03Type(T:CPPScalarType) => true
     rule isPOD03Type(T:CPPArrayType) => isPOD03Type(innerType(T))
     rule isPOD03Type(T:CPPClassType) => isPOD03Class(T, getClassInfo(T))
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
     rule isPODLayoutClass(t(... st: classType(_ :: Class(Key::ClassKey, X::CId, _))) #as T::CPPClassType,
               <class>...
                 <non-static-data-members> .List </non-static-data-members>
                 <base-classes> .List </base-classes>
               ...</class>)
          => notBool (#hasMethodThat(operator=, getClassInfo(T), #klabel(`isUserProvidedCopyAssignment`))
               orBool hasDestructorThat(T, #klabel(`isUserProvidedDestructor`))
               orBool hasConstructorThat(T, #klabel(`isUserProvidedConstructor`))
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
     rule isPOD03Class(t(... st: classType(_ :: Class(Key::ClassKey, X::CId, _))) #as T::CPPClassType,
               <class>...
                 <non-static-data-members> .List </non-static-data-members>
                 <base-classes> .List </base-classes>
               ...</class>)
          => notBool (#hasMethodThat(operator=, getClassInfo(T), #klabel(`isUserProvidedCopyAssignment`))
               orBool hasDestructorThat(T, #klabel(`isUserProvidedDestructor`))
               orBool hasConstructorThat(T, #klabel(`isUserProvidedConstructor`))
               orBool hasVirtualMembers(T))
               andBool (Key ==K Struct() orBool Key ==K Union())
     rule isPOD03Class(...) => false [owise]

     rule isEmptyClass(T::CPPClassType, <class>... <base-classes> .List </base-classes> <non-static-data-members> .List </non-static-data-members> ...</class>)
          => notBool hasVirtualMembers(T)
     rule isEmptyClass(_, <class>... <base-classes> ListItem(B::Class) => .List ...</base-classes> ...
</class>)
          requires isEmptyClass(type(classType(B)), getClassInfo(B))
     rule isEmptyClass(...) => false [owise]

     syntax Bool ::= isUserProvidedCopyAssignment(CPPFunctionType, K) [function]
     rule isUserProvidedCopyAssignment(t(... st: functionType(... paramTypes: t(quals(.Set), _, classType(X::Class)), methodInfo: methodInfo(... static: false, class: X, userProvided: true))), envEntry(...)) => true
     rule isUserProvidedCopyAssignment(t(... st: functionType(... paramTypes: t(... st: lvRefType(t(... st: classType(X::Class)))), methodInfo: methodInfo(... static: false, class: X, userProvided: true))), envEntry(...)) => true
     rule isUserProvidedCopyAssignment(...) => false [owise]

     syntax Bool ::= isWideBitfield(CPPType) [function]
     rule isWideBitfield(T:CPPBitfieldType) => bitSizeofType(T) >Int bitSizeofType(innerType(T))
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

     rule <k> declareField(#NoName, T:CPPBitfieldType, NoInit()) => .K ...</k>
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
     rule <k> layoutField(X::CId, T:CPPBitfieldType) => .K ...</k>
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
               andBool notBool (isBaseClass(X) andBool isEmptyClass(T, getClassInfo({T}:>CPPClassType)))

     syntax Int ::= nvSizeof(CPPType) [function]
                  | #nvSizeof(ClassInfo) [function]
                  | nvAlignof(CPPType) [function]
                  | #nvAlignof(ClassInfo) [function]

     rule nvSizeof(T::CPPClassType) => #nvSizeof(getClassInfo(T))
     rule nvAlignof(T::CPPClassType) => #nvAlignof(getClassInfo(T))
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
     rule getTypesAtOffsetForLayout(t(... st: classType(_ :: Class(Struct(), _, _))) #as T::CPPClassType, 0)
          => SetItem(utype(T)) getTypesAtOffsetForLayoutInStruct(T, getClassInfo(T), 0)
     rule getTypesAtOffsetForLayout(t(... st: classType(_ :: Class(Class(), _, _))) #as T::CPPClassType, 0)
          => SetItem(utype(T)) getTypesAtOffsetForLayoutInStruct(T, getClassInfo(T), 0)
     rule getTypesAtOffsetForLayout(t(... st: classType(_ :: Class(Union(), _, _))) #as T::CPPClassType, 0)
          => SetItem(utype(T)) getTypesAtOffsetForLayoutInUnion(T, getClassInfo(T), 0)

     rule getTypesAtOffsetForLayout(t(... st: arrayType(InnerT::CPPType, _)) #as T::CPPType, Offset::Int)
          => getTypesAtOffsetForLayout(InnerT, Offset %Int bitSizeofType(InnerT))
          requires Offset >Int 0
     rule getTypesAtOffsetForLayout(t(... st: incompleteArrayType(InnerT::CPPType)) #as T::CPPType, Offset::Int)
          => getTypesAtOffsetForLayout(InnerT, Offset %Int bitSizeofType(InnerT))
          requires Offset >Int 0
     rule getTypesAtOffsetForLayout(t(... st: classType(_ :: Class(Struct(), _, _))) #as T::CPPClassType, Offset::Int)
          => getTypesAtOffsetForLayoutInStruct(T, getClassInfo(T), Offset)
          requires Offset >Int 0
     rule getTypesAtOffsetForLayout(t(... st: classType(_ :: Class(Class(), _, _))) #as T::CPPClassType, Offset::Int)
          => getTypesAtOffsetForLayoutInStruct(T, getClassInfo(T), Offset)
          requires Offset >Int 0
     rule getTypesAtOffsetForLayout(t(... st: classType(_ :: Class(Union(), _, _))) #as T::CPPClassType, Offset::Int)
          => getTypesAtOffsetForLayoutInUnion(T, getClassInfo(T), Offset)
          requires Offset >Int 0
     rule getTypesAtOffsetForLayout(T::CPPType, Offset::Int) => #if Offset ==Int 0 #then SetItem(utype(T)) #else .Set #fi [owise]

     syntax Set ::= getTypesAtOffsetForLayoutInStruct(CPPType, ClassInfo, Int) [function]
                  | getTypesAtOffsetForLayoutInUnion(CPPType, ClassInfo, Int) [function]
     rule getTypesAtOffsetForLayoutInStruct(_, <class>...
               <non-static-data-members>... ListItem(Class.DataMember(X::CId, T::CPPType)) => .List </non-static-data-members>
               <cenv>... X |-> (_::TypeMap T |-> classOffset(_, FOffset::Int)) ...</cenv>
          ...</class>, Offset::Int)
          requires FOffset >Int Offset
     rule getTypesAtOffsetForLayoutInStruct(_, <class>...
               <non-static-data-members>... ListItem(Class.DataMember(X::CId, T::CPPType)) => .List </non-static-data-members>
               <cenv>... X |-> (_::TypeMap T |-> uninitialized) ...</cenv>
          ...</class>, Offset::Int)
     rule getTypesAtOffsetForLayoutInStruct(T::CPPType, <class>...
               <non-static-data-members>... ListItem(Class.DataMember(X::CId, T'::CPPType)) </non-static-data-members>
               <cenv>... X |-> (_::TypeMap T' |-> classOffset(_, FOffset::Int)) ...</cenv>
          ...</class>, Offset::Int)
          => getTypesAtOffsetForLayout(T', Offset -Int FOffset)
          requires FOffset <=Int Offset
     rule getTypesAtOffsetForLayoutInStruct(_, <class>...
               <base-classes>... ListItem(C:Class) => ListItem(type(classType(C))) </base-classes>
          ...</class>, _)
     rule getTypesAtOffsetForLayoutInStruct(T::CPPType, <class>...
               <base-classes>... ListItem(t(... st: classType(C::Class)) #as T'::CPPType) => .List </base-classes>
               <non-static-data-members> .List </non-static-data-members>
               <cenv>... baseClass(C) |-> (_::TypeMap T' |-> classOffset(_, FOffset::Int)) ...</cenv>
          ...</class>, Offset::Int)
          requires FOffset >Int Offset
     rule getTypesAtOffsetForLayoutInStruct(T::CPPType, <class>...
               <base-classes>... ListItem(t(... st: classType(C::Class)) #as T'::CPPType) => .List </base-classes>
               <non-static-data-members> .List </non-static-data-members>
               <cenv>... baseClass(C) |-> (_::TypeMap T' |-> uninitialized) ...</cenv>
          ...</class>, Offset::Int)
     rule getTypesAtOffsetForLayoutInStruct(T::CPPType, <class>...
               <base-classes>... ListItem(t(... st: classType(C::Class)) #as T'::CPPType) </base-classes>
               <non-static-data-members> .List </non-static-data-members>
               <cenv>... baseClass(C) |-> (_::TypeMap T' |-> classOffset(_, FOffset::Int)) ...</cenv>
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
     rule pad(V::Int, T:CPPBitfieldType) => padTo(V, byteAlignofType(innerType(T)))
          requires // notBool (Packed() in getModifiers(T)) andBool
            (V +Int bitSizeofType(T)) >Int padTo(V, byteAlignofType(innerType(T)))
     rule pad(V::Int, T:CPPBitfieldType) => padTo(V, byteAlignofType(innerType(T)))
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
