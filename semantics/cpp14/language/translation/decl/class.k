module CPP-DECL-CLASS-SYNTAX
     imports BOOL-SYNTAX
     imports LIST
     imports SET
     imports COMMON-SORTS
     imports CPP-SORTS
     imports CPP-DYNAMIC-SORTS
     imports CPP-TYPING-SORTS
     imports SYMLOC-SORTS
     syntax AType ::= declareClassName(Tag, CId, Bool)
     syntax KItem ::= classContext(AType, List) [strict(1)]
     syntax MemberBase ::= memberBase(CId, CId, CPPType)
     syntax SymBase ::= MemberBase

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
                   | hasConstructorThat(CPPClassType, K) [function]
                   | hasDestructorThat(CPPClassType, K) [function]
endmodule

module CPP-DECL-CLASS
     imports CPP-DECL-CLASS-SYNTAX
     imports C-CONFIGURATION
     imports K-REFLECTION
     imports MAP
     imports COMMON-SYNTAX
     imports COMPAT-SYNTAX
     imports SYMLOC-SYNTAX
     imports CPP-ABSTRACT-SYNTAX
     imports CPP-ALIGNMENT-SYNTAX
     imports CPP-BITSIZE-SYNTAX
     imports CPP-CLASS-SYNTAX
     imports CPP-DECL-DECLARATOR-SYNTAX
     imports CPP-DECL-INITIALIZER-SYNTAX
     imports CPP-DYNAMIC-SYNTAX
     imports CPP-ENV-SYNTAX
     imports CPP-OVERLOADING-SYNTAX
     imports CPP-SYMLOC-SYNTAX
     imports CPP-SYNTAX
     imports CPP-SYMLOC-SYNTAX
     imports CPP-TYPING-EXPR-SYNTAX
     imports CPP-TYPING-SYNTAX
     imports CPP-VALUE-CATEGORY-SYNTAX

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
          <curr-scope> namespaceScope(N::Namespace) </curr-scope>

     rule <k> TypeDecl(t(_, _, classType(N::Namespace :: Class(ClassKey::Tag, X::CId, _))) #as T::CPPType) => .K ...</k>
          <curr-template-context> noTemplate </curr-template-context>
          <curr-tu> Tu::String </curr-tu>
          <tu-id> Tu </tu-id>
          <ns-id> N </ns-id>
          <ntypes> NT::Map => NT[X, ClassKey <- T] </ntypes>

     rule ClassDef(T:ClassKey, X::CId, NoNNS(), .List, Members::List) => classContext(declareClassName(T, X, true), Members)
          requires notBool isUnnamedCId(X) orBool T =/=K Union()

     rule ClassDef(Union(), X:UnnamedCId, NoNNS(), .List, Members::List)
          => DeclaratorAndSpecifiers(defAnonymousUnion(declareClassName(Union(), X, true), Members), .Set)
     
     syntax Declarator ::= defAnonymousUnion(AType, List)
     context DeclaratorAndSpecifiers(defAnonymousUnion(HOLE:AType,_), _)
     rule DeclaratorAndSpecifiers(defAnonymousUnion(t(... st: classType(C::Class)) #as T::CPPType, Members::List), S::Set)
          => classContext(T, Members) ~> defineUnnamedObject(C, S) ~> addMembersToScope(C)

     rule NoDecl() => .K

     syntax KItem ::= defineUnnamedObject(Class, Set)
     rule <k> defineUnnamedObject(C::Class, S::Set)
           => DeclaratorAndSpecifiers(
                VarDecl(getNamespace(Scope), unnamedObject(C), type(classType(C)), NoInit(), false),
                #if isNamespaceScope(Scope)
                #then SetItem(Static()) S // kast does not add Specifiers if in namespaceScope
                #else S
                #fi
              ) ...</k>
          <curr-scope> Scope::Scope </curr-scope>

     syntax KItem ::= addMembersToScope(Class)
     rule <k> addMembersToScope(C::Class) => addMembersToScope(C, Members) ...</k>
          <class-id> C </class-id>
          <non-static-data-members> Members::List </non-static-data-members>

     syntax KItem ::= addMembersToScope(Class, List)
     rule addMembersToScope(_, .List) => .K
     // TODO(traiansf): propagate variant-members upward if the anonymous union was declared in class scope.
     rule <k> (.K => addToEnv(getNamespace(Scope) :: X, T, memberBase(unnamedObject(C), X, T), false))
           ~> addMembersToScope(C::Class, (ListItem(kpair(X::CId, T::CPPType)) => .List) _)
          ...</k>
          <curr-scope> Scope::Scope </curr-scope>
          requires notBool isClassScope(Scope)

     syntax Namespace ::= getNamespace(Scope) [function]
     rule getNamespace(namespaceScope(N::Namespace)) => N
     rule getNamespace(_:BlockScope) => NoNamespace()

     rule <k> classContext(t(_, _, classType((N::Namespace :: Class(ClassKey::Tag, X::CId, _)) #as C::Class)) #as T::CPPType, Members::List) 
              => setScope(classScope(C))
              ~> listToK(Members)
              ~> implicitDeclarations()
              ~> defineFunctions(OldClass)
              ~> setScope(OldScope)
          ...</k>
          <member-function-bodies> OldClass:K => .K </member-function-bodies>
          <curr-template-context> noTemplate </curr-template-context>
          <curr-scope> OldScope::Scope </curr-scope>
          <curr-tu> Tu::String </curr-tu>
          <tu-id> Tu </tu-id>
          <ns-id> N </ns-id>
          <ntypes> NT::Map => NT[X, ClassKey <- T] </ntypes>
          (.Bag => <class>...
            <class-id> C </class-id>
            <class-type> ClassKey </class-type>
            // injected class name
            <ctypes> X |-> (ClassKey |-> T) </ctypes>
            <access> X |-> Public() </access>
            <access-specifier> getDefaultAccessType(ClassKey) </access-specifier>
          ...</class>)

     syntax KItem ::= defineFunctions(K)

     rule <k> (.K => Functions:K) ~> defineFunctions(_) ...</k>
          <member-function-bodies> Functions:K => .K </member-function-bodies>
          requires Functions =/=K .K

     rule <k> defineFunctions(OldClass:K) => .K ...</k>
          <member-function-bodies> .K => OldClass </member-function-bodies>

     syntax KItem ::= implicitDeclarations()
     // no implicit constructor if one was already declared
     rule <k> implicitDeclarations() => .K...</k>
          <curr-scope> classScope(_ :: Class(_, X::CId, _) #as C::Class) </curr-scope>
          <curr-tu> Tu::String </curr-tu>
          <tu-id> Tu </tu-id>
          <class-id> C </class-id>
          <cenv>... ConstructorId(X) |-> _ DestructorId(X) |-> _ ...</cenv>

     // TODO(dwightguth): implicit exception spec
     rule <k> (.K => AccessSpec(Public()) ~> Specifier(Inline(), 
                   FunctionDefinition(NoNNS(), ConstructorId(X), 
                        MethodPrototype(false, true, type(pointerType(type(classType(C)))), 
                             FunctionPrototype(type(void), list(.List), NoExceptionSpec(), false)),
                        .List, Defaulted())))
              ~> implicitDeclarations() ...</k>
          <curr-scope> classScope(_ :: Class(_, X::CId, _) #as C::Class) </curr-scope>
          <curr-tu> Tu::String </curr-tu>
          <tu-id> Tu </tu-id>
          <class-id> C </class-id>
          <cenv> Env::Map </cenv>
          requires notBool ConstructorId(X) in_keys(Env)

     rule <k> (.K => AccessSpec(Public()) ~> Specifier(Inline(),
                   FunctionDefinition(NoNNS(), DestructorId(X),
                        MethodPrototype(false, false, type(pointerType(type(classType(C)))),
                             FunctionPrototype(type(void), list(.List), NoExceptionSpec(), false)),
                        .List, Defaulted())))
              ~> implicitDeclarations() ...</k>
          <curr-scope> classScope(_ :: Class(_, X::CId, _) #as C::Class) </curr-scope>
          <curr-tu> Tu::String </curr-tu>
          <tu-id> Tu </tu-id>
          <class-id> C </class-id>
          <cenv> Env::Map </cenv>
          requires notBool DestructorId(X) in_keys(Env)

     rule <k> Constructor(Ctor::List, S::Stmt) => figureConstruct(Ctor, Bases, NSDM, S, .K, false) ...</k>
          <curr-scope> blockScope(C::Class :: ConstructorId(_), _, _) </curr-scope>
          <curr-tu> Tu::String </curr-tu>
          <tu-id> Tu </tu-id>
          <class-id> C </class-id>
          <base-classes> Bases::List </base-classes>
          <non-static-data-members> NSDM::List </non-static-data-members>
          
     rule <k> Defaulted() => Constructor(.List, BlockStmt(!N:Int, .List)) ...</k>
          <curr-scope> blockScope(C::Class :: ConstructorId(_), _, _) </curr-scope>

     syntax Stmt ::= figureConstruct(ctors: List, bases: List, dataMembers: List, body: Stmt, result: K, hasNonConstVariantMember: Bool)
     // 12.1:4
     rule <k> figureConstruct(_, .List, ListItem(kpair(X::CId, T::CPPType)) _, _, _, _) => Deleted() ...</k>
          <curr-scope> blockScope(C::Class :: ConstructorId(_), Base::SymBase, _) </curr-scope>
          <functions>... Base |-> functionObject(_, FuncT::CPPFunctionType, _, _) ...</functions>
          <curr-tu> Tu::String </curr-tu>
          <tu-id> Tu </tu-id>
          <class-id> C </class-id>
          <variant-members> VM::Set </variant-members>
          <initializers>... X |-> (T |-> I::Init) ...</initializers>
          requires isDeletedDefaultConstructor(X, T, C, FuncT, VM, I)
     // 12.1:4.6-4.7
     rule <k> (.K => checkCtorAndDtor(.K, X, T, true, I, getMostDerivedArrayElement(T))) ~> figureConstruct(.List, .List, (ListItem(kpair(X::CId, T::CPPType)) => .List) _, _, _, _) ...</k>
          <curr-scope> blockScope(C::Class :: ConstructorId(_), Base::SymBase, _) </curr-scope>
          <functions>... Base |-> functionObject(_, FuncT::CPPFunctionType, _, _) ...</functions>
          <curr-tu> Tu::String </curr-tu>
          <tu-id> Tu </tu-id>
          <class-id> C </class-id>
          <variant-members> VM::Set </variant-members>
          <initializers>... X |-> (T |-> I::Init) ...</initializers>
          requires notBool isDeletedDefaultConstructor(X, T, C, FuncT, VM, I)

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
     rule <k> (.K => resolve(resolveOverload(cSet(Candidates, M :: ConstructorId(X), .K), list(.List), constructor)))
              ~> checkCtor(_ :: Class(_, X::CId, _) #as M::Class)
          ...</k>
          <curr-tu> Tu::String </curr-tu>
          <tu-id> Tu </tu-id>
          <class-id> M </class-id>
          <cenv>... ConstructorId(X) |-> Candidates::Map ...</cenv>
     rule resolve(E:ResolvedExpr) ~> checkCtor(_) => .K
          requires notBool isNotFoundNameRef(E)
     rule <k> (.K => resolve(checkAccess(CallExpr(lv(lnew(Base), hasTrace(Name(NoNNS(), DestructorId(X))), T), list(.List), krlist(.List)))))
              ~> checkDtor(_ :: Class(_, X::CId, _) #as M::Class)
          ...</k>
          <curr-tu> Tu::String </curr-tu>
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
     rule <k> figureConstruct(_, .List, .List, _, _, false) => Deleted() ...</k>
          <curr-scope> blockScope((_::ClassQualifier :: Class(Union(), _, _)) #as C::Class :: ConstructorId(_), Base::SymBase, _) </curr-scope>
          <functions>... Base |-> functionObject(_, FuncT::CPPFunctionType, _, _) ...</functions>
          requires notBool isUserProvidedConstructor(FuncT, .K)
 

     syntax KItem ::= figureConstructItem(memInit: K, CId, CPPType, isMember: Bool)

     // 12.6.2:8.1
     // TODO(dwightguth): ctor-initializers and base classes
     // TODO(traiansf): unions
     rule <k> (figureConstructItem(.K, X::CId, T::CPPType, true) => .K) ~> figureConstruct(.List, _, _, _, 
                   (Res:K => Res ~> ExpressionStmt(figureConstructorInit(Name(NoNNS(), X), T, I))),
                   B:Bool => B orBool (X in VM andBool notBool isConstType(getMostDerivedArrayElement(T)))) ...</k>
          <curr-scope> blockScope(C::Class :: ConstructorId(_), _, _) </curr-scope>
          <curr-tu> Tu::String </curr-tu>
          <tu-id> Tu </tu-id>
          <class-id> C </class-id>
          <initializers>... X |-> (T |-> I::Init) ...</initializers>
          <variant-members> VM::Set </variant-members>
          requires I =/=K NoInit()
     // 12.6.2:8.2
     // TODO(traiansf): anonymous unions
     rule <k> (figureConstructItem(.K, X::CId, T::CPPType, IsMember:Bool) => .K) ~> figureConstruct(_, _, _, _, _,
                   B:Bool => B orBool (notBool isConstType(getMostDerivedArrayElement(T)))) ...</k>
          <curr-scope> blockScope(C::Class :: ConstructorId(_), _, _) </curr-scope>
          <curr-tu> Tu::String </curr-tu>
          <tu-id> Tu </tu-id>
          <class-id> C </class-id>
          <initializers>... X |-> (T |-> I::Init) ...</initializers>
          <variant-members> VM::Set </variant-members>
          requires notBool (I =/=K NoInit() andBool IsMember) andBool X in VM

     // 12.6.2:8.3
     rule <k> (figureConstructItem(.K, X::CId, T::CPPType, IsMember:Bool) => .K) ~> figureConstruct(_, _, _, _, 
                   (Res:K => Res ~> ExpressionStmt(defaultInit(Name(NoNNS(), X), T, true))), _) ...</k>
          <curr-scope> blockScope(C::Class :: ConstructorId(_), _, _) </curr-scope>
          <curr-tu> Tu::String </curr-tu>
          <tu-id> Tu </tu-id>
          <class-id> C </class-id>
          <initializers>... X |-> (T |-> I::Init) ...</initializers>
          <variant-members> VM::Set </variant-members>
          requires notBool (I =/=K NoInit() andBool IsMember) andBool notBool X in VM

     rule <k> figureConstruct(_, .List, .List, Body::Stmt, Res:K, HasNonConst:Bool) => Res ~> Body ...</k>
          <curr-scope> blockScope(_::ClassQualifier :: Class(T::Tag, _, _) #as C::Class :: ConstructorId(_), _, _) </curr-scope>
          <curr-tu> Tu::String </curr-tu>
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
     rule #isTrivialDefaultConstructor(<class>... <non-static-data-members> ListItem(kpair(X::CId, T::CPPType)) => .List ...</non-static-data-members> <initializers>... X |-> (T |-> NoInit()) ...</initializers> ...</class>)
          requires #if isCPPClassType(getMostDerivedArrayElement(T)) #then hasConstructorThat({getMostDerivedArrayElement(T)}:>CPPClassType, #klabel(`isTrivialDefaultConstructor`)) #else true #fi
     rule #isTrivialDefaultConstructor(<class>... <base-classes> .List </base-classes> <non-static-data-members> .List </non-static-data-members> ...</class>) => true
     rule #isTrivialDefaultConstructor(...) => false [owise]

     rule isNonTrivialDefaultConstructor(T::CPPFunctionType, K:K) => isDefaultConstructor(T, K) andBool notBool isTrivialDefaultConstructor(T, K)

     rule isDefaultConstructor(T::CPPFunctionType, envEntry(... defaultArgs: DA::DefaultArgumentsResult)) => acceptsNArgs(0, T, getDefaultArgsVals(DA))
     rule isUserProvidedConstructor(T::CPPFunctionType, _) => isMethodUserProvided(T)
     rule isUserProvidedDestructor(T::CPPFunctionType, _) => isMethodUserProvided(T)
     rule isUserProvidedDefaultConstructor(T::CPPFunctionType, K:K) => isDefaultConstructor(T, K) andBool isUserProvidedConstructor(T, K)

     rule hasConstructorThat(t(... st: classType(_ :: Class(_, X::CId, _))) #as T::CPPClassType, Lbl:K) => #hasMethodThat(ConstructorId(X), getClassInfo(T), Lbl)
     rule hasDestructorThat(t(... st: classType(_ :: Class(_, X::CId, _))) #as T::CPPClassType, Lbl:K) => #hasMethodThat(DestructorId(X), getClassInfo(T), Lbl)
     rule #hasMethodThat(X::CId, <class>... <cenv>... X |-> M::Map ...</cenv> ...</class>, Lbl:K)
          => some(M, Lbl)

     rule isDeleted(_, envEntry(... base: Base::SymBase)) => #isDeleted(Base, #configuration)
     rule #isDeleted(Base::SymBase, <generatedTop>... <functions>... Base |-> Deleted() ...</functions> ...</generatedTop>) => true
     rule #isDeleted(...) => false [owise]
     rule isDeletedDefaultConstructor(T::CPPFunctionType, K:K) => isDeleted(T, K) andBool isDefaultConstructor(T, K)

     rule <k> Destructor() => figureDestruct(Bases, NSDM, .K) ...</k>
          <curr-scope> blockScope(C::Class :: DestructorId(_), _, _) </curr-scope>
          <curr-tu> Tu::String </curr-tu>
          <tu-id> Tu </tu-id>
          <class-id> C </class-id>
          <base-classes> Bases::List </base-classes>
          <non-static-data-members> NSDM::List </non-static-data-members>

     rule <k> Defaulted() => .K ...</k>
          <curr-scope> blockScope(C::Class :: DestructorId(_), _, _) </curr-scope>

     syntax Stmt ::= figureDestruct(bases: List, dataMembers: List, result: K)

     // 12.4:5
     rule <k> figureDestruct(.List, ListItem(kpair(X::CId, T::CPPType)) _, _) => Deleted() ...</k>
          <curr-scope> blockScope(C::Class :: ConstructorId(_), Base::SymBase, _) </curr-scope>
          <functions>... Base |-> functionObject(_, FuncT::CPPFunctionType, _, _) ...</functions>
          <curr-tu> Tu::String </curr-tu>
          <tu-id> Tu </tu-id>
          <class-id> C </class-id>
          <variant-members> VM::Set </variant-members>
          requires isDeletedDefaultDestructor(X, T, C, FuncT, VM)
     // 12.4:5.2
     rule <k> (.K => checkDtor(X, T, getMostDerivedArrayElement(T), VM)) ~> figureDestruct(.List, (ListItem(kpair(X::CId, T::CPPType)) => .List) _, _) ...</k>
          <curr-scope> blockScope(C::Class :: DestructorId(_), Base::SymBase, _) </curr-scope>
          <functions>... Base |-> functionObject(_, FuncT::CPPFunctionType, _, _) ...</functions>
          <curr-tu> Tu::String </curr-tu>
          <tu-id> Tu </tu-id>
          <class-id> C </class-id>
          <variant-members> VM::Set </variant-members>
          requires notBool isDeletedDefaultDestructor(X, T, C, FuncT, VM)

     syntax K ::= checkDtor(CId, CPPType, CPPType, Set) [function, klabel(checkDtor3)]
     rule checkDtor(X::CId, T::CPPType, M::CPPType, VM::Set)
          => figureDestructItem(X, T, VM)
          requires notBool isCPPClassType(M)
     rule checkDtor(X::CId, T::CPPType, t(... st: classType(M::Class)), VM::Set)
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
          ~> figureDestruct(... result: Res:K => Res ~> addToConstructed(Name(NoNNS(), X), T))
          requires notBool X in VM andBool isCPPClassType(getMostDerivedArrayElement(T))

     rule <k> figureDestruct(.List, .List, Res:K) => Res ...</k>
          <curr-scope> blockScope(_ :: DestructorId(_), Base::SymBase, _) </curr-scope>
          <functions>... Base |-> functionObject(_, FuncT::CPPFunctionType, _, _) ...</functions>
          requires notBool isMethodVirtual(FuncT)

     rule <k> addToConstructed(L:LVal, T::CPPType) => .K ...</k>
          <elab>... .K => addToConstructed(L, T) </elab>

     syntax Bool ::= #isTrivialDestructor(ClassInfo) [function]

     // 12.4:5.4
     rule isTrivialDestructor(T::CPPFunctionType, K:K) => notBool isUserProvidedDestructor(T, K) andBool notBool isMethodVirtual(T) andBool #isTrivialDestructor(getClassInfo(getMethodClass(T)))     
     rule #isTrivialDestructor(<class>... <base-classes> ListItem(C::Class) => .List ...</base-classes> ...</class>)
          requires hasDestructorThat(type(classType(C)), #klabel(`isTrivialDestructor`))
     rule #isTrivialDestructor(<class>... <non-static-data-members> ListItem(kpair(_, T::CPPType)) => .List ...</non-static-data-members> ...</class>)
          requires #if isCPPClassType(getMostDerivedArrayElement(T)) #then hasDestructorThat({getMostDerivedArrayElement(T)}:>CPPClassType, #klabel(`isTrivialDestructor`)) #else true #fi
     rule #isTrivialDestructor(<class>... <base-classes> .List </base-classes> <non-static-data-members> .List </non-static-data-members> ...</class>) => true
     rule #isTrivialDestructor(...) => false [owise]
     
     syntax AccessSpecifier ::= getDefaultAccessType(Tag) [function]
     rule getDefaultAccessType(Class()) => Private()
     rule getDefaultAccessType(Struct()) => Public()
     rule getDefaultAccessType(Union()) => Public()

     rule FieldDecl(NoNNS(), X::CId, T::CPPType, Init::Expr) => declareField(X, T, Init)

     syntax KItem ::= declareField(CId, CPPType, Expr) [strict(2)]

     rule <k> declareField(X::CId, T::CPPType, Init::Expr) => .K ...</k>
          <curr-scope> classScope(C::Class) </curr-scope>
          <class>...
            <class-type> Key::ClassKey </class-type>
            <class-id> C </class-id>
            <is-aggregate> B:Bool => B andBool (AS ==K Public()) </is-aggregate>
            <non-static-data-members>... .List => ListItem(kpair(X, T)) </non-static-data-members>
            <access-specifier> AS::AccessSpecifier </access-specifier>
            <access> AE::Map => AE[X <- AS] </access>
            <cenv> CE::Map => CE[X, T <- classOffset(padOrNot(V, T, Key))] </cenv>
            <initializers> Inits::Map => Inits[X, T <- Init] </initializers>
            <max-offset> V::Int => updateMaxOffset(V, T, Key) </max-offset>
            <max-align> M::Int => maxInt(M, byteAlignofType(T)) </max-align>
            <variant-members> VM::Set => #if Key ==K Union() #then VM SetItem(X) #else VM #fi </variant-members>
          ...</class>
          requires notBool (X in_keys(CE))

     rule <k> AccessSpec(AS::AccessSpecifier) => .K ...</k>
          <curr-scope> classScope(C::Class) </curr-scope>
          <class>...
            <class-id> C </class-id>
            <access-specifier> _ => AS </access-specifier>
          ...</class>

     syntax Int ::= updateMaxOffset(Int, CPPType, ClassKey) [function]
     rule updateMaxOffset(V::Int, T::CPPType, Union()) => maxInt(V, bitSizeofType(T))
     rule updateMaxOffset(V::Int, T::CPPType, _) => pad(V,T) +Int bitSizeofType(T)  [owise]

     syntax Int ::= padOrNot(Int, CPPType, ClassKey) [function]
     rule padOrNot(_, _, Union()) => 0
     rule padOrNot(V::Int, T::CPPType, _) => pad(V, T) [owise]

     // TODO(traiansf): Handle pack directives
     // TODO(traiansf): Handle bit fields
     // taken from c-semantics/semantics/c11/language/translation/decl/tagged.k
     //
     // The padding associated with a particular field precedes it, with
     // possibly some extra padding at the end of the whole struct not
     // associated with any field. This is important for understanding the
     // effect of the gcc et al. padding attr as applied to a particular field.

     syntax Int ::= pad(Int, CPPType) [function]
     // Non-bitfields are aligned according to their type (if we note that
     // fields tagged with the Packed() attribute have an alignment of 1 byte).
     rule pad(V::Int, T::CPPType) => padTo(V, byteAlignofType(T))
          // requires notBool isBitfieldType(T)
     // Non-packed bitfields that would cross an alignment boundary and
     // zero-length bitfields have an alignment of the bitfield field type.
//     rule pad(V::Int, T:BitfieldType) => padTo(V, byteAlignofType(innerType(T)))
//          requires // notBool (Packed() in getModifiers(T)) andBool
//            (V +Int bitSizeofType(T)) >Int padTo(V, byteAlignofType(innerType(T)))
//     rule pad(V::Int, T:BitfieldType) => padTo(V, byteAlignofType(innerType(T)))
//          requires bitSizeofType(T) ==Int 0
     // Packed bitfields and non-packed bitfields that don't cross an alignment
     // boundary have 1-bit alignment (no padding).
//     rule pad(V::Int, _) => V [owise]

     // brace-or-equal initializers need to be evalauted in class scope
     rule <k> evalBraceOrEqualInitializer(C::Class, Base::LVal, E::Expr) => E ~> returnFromBraceOrEqualInitializer(Base, OldScope) ...</k>
          <curr-scope> OldScope::Scope => classScope(C) </curr-scope>
     rule <k> le(E::Expr => evalBraceOrEqualInitializer(C, Base, E), _, _)
           ~> (returnFromBraceOrEqualInitializer(Base::LVal, Scope::Scope) => .K)
          ...</k>
          <curr-scope> classScope(C::Class) => Scope </curr-scope>
     rule <k> xe(E::Expr => evalBraceOrEqualInitializer(C, Base, E), _, _)
           ~> (returnFromBraceOrEqualInitializer(Base::LVal, Scope::Scope) => .K)
          ...</k>
          <curr-scope> classScope(C::Class) => Scope </curr-scope>
     rule <k> pre(E::Expr => evalBraceOrEqualInitializer(C, Base, E), _, _)
           ~> (returnFromBraceOrEqualInitializer(Base::LVal, Scope::Scope) => .K)
          ...</k>
          <curr-scope> classScope(C::Class) => Scope </curr-scope>

     rule <k> V:Val ~> (returnFromBraceOrEqualInitializer(_, Scope::Scope) => .K) ...</k>
          <curr-scope> _ => Scope </curr-scope>
          requires notBool (isLExpr(V) orBool isPRExpr(V))

     rule <k> typeof(evalBraceOrEqualInitializer(C::Class, Base::LVal, E::Expr) => E)
           ~> (.K => returnFromBraceOrEqualInitializer(Base, OldScope))
          ...</k>
          <curr-scope> OldScope::Scope => classScope(C) </curr-scope>
     rule <k> typeof(V:CPPType) ~> (returnFromBraceOrEqualInitializer(_, Scope::Scope) => .K) ...</k>
          <curr-scope> _ => Scope </curr-scope>
     rule <k> catof(evalBraceOrEqualInitializer(C::Class, Base::LVal, E::Expr) => E)
           ~> (.K => returnFromBraceOrEqualInitializer(Base, OldScope))
          ...</k>
          <curr-scope> OldScope::Scope => classScope(C) </curr-scope>
     rule <k> catof(V:ValueCategory) ~> (returnFromBraceOrEqualInitializer(_, Scope::Scope) => .K) ...</k>
          <curr-scope> _ => Scope </curr-scope>
endmodule
