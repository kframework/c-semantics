// ------------------------------
//      CPP-NAMESPACE
// ------------------------------

module CPP-NAMESPACE-SORTS

     syntax Namespace

     syntax NamespaceSpecifier

     syntax UnnamedNamespace

endmodule // CPP-NAMESPACE-SORTS

module CPP-NAMESPACE-SYNTAX
     imports CPP-NAMESPACE-SORTS // self

     imports COMMON-SORTS // CId
     imports BOOL

     syntax Namespace ::= Namespace "::" NamespaceSpecifier
                        | NoNamespace() // signifies a declaration at block scope
                        | UnnamedNamespace

     syntax NamespaceSpecifier ::= Namespace(CId)

     syntax Bool ::= enclosesNamespace(Namespace, Namespace) [function]

endmodule // CPP-NAMESPACE-SYNTAX

module CPP-NAMESPACE
     imports CPP-NAMESPACE-SYNTAX // self
     imports DOMAINS

     rule enclosesNamespace(N::Namespace, N :: _) => true

     rule enclosesNamespace(N::Namespace, M::Namespace :: _) => enclosesNamespace(N, M)
          requires N =/=K M

     rule enclosesNamespace(...) => false [owise]

endmodule // CPP-NAMESPACE

// ------------------------------
//      CPP-TRACE
// ------------------------------

module CPP-TRACE-SORTS

     syntax Trace

endmodule // CPP-TRACE-SORTS

module CPP-TRACE-SYNTAX
     imports CPP-TRACE-SORTS // self

     // remote sorts
     syntax Typed

     syntax K

     syntax ValueCategory

     syntax CPPType

     syntax Trace ::= hasTrace(K) | "noTrace"
                    | combine(Trace, K) [function]
                    | combine(Trace, Trace, K) [function, klabel(combine2)]
                    | combine(Trace, Trace, Trace, ValueCategory, CPPType) [function, klabel(combine3)]

endmodule // CPP-TRACE-SYNTAX

module CPP-TRACE
     imports CPP-TRACE-SYNTAX // self

     // ...

endmodule // CPP-TRACE

// ------------------------------
//      CPP-VALUE-CATEGORY
// ------------------------------

module CPP-VALUE-CATEGORY-SORTS

     syntax ValueCategory

endmodule // CPP-VALUE-CATEGORY-SORTS

module CPP-VALUE-CATEGORY-SYNTAX
     imports CPP-VALUE-CATEGORY-SORTS // self

     imports LIST

     syntax LValueCategory ::= "lvalue"

     syntax XValueCategory ::= "xvalue"

     syntax PRValueCategory ::= "prvalue"

     syntax GLValueCategory ::= LValueCategory | XValueCategory

     syntax RValueCategory ::= XValueCategory | PRValueCategory

     syntax ValueCategory ::= GLValueCategory | RValueCategory | InitListCategory

     syntax KResult ::= ValueCategory

     syntax InitListCategory ::= initListCat(List)

     syntax ValueCategory ::= NoInitValueCategory

     syntax NoInitValueCategory ::= NoInitCat()

endmodule // CPP-VALUE-CATEGORY-SYNTAX

module CPP-VALUE-CATEGORY
     imports CPP-VALUE-CATEGORY-SYNTAX // self

     // ...

endmodule // CPP-VALUE-CATEGORY

// ------------------------------
//      CPP-SCOPE
// ------------------------------

module CPP-SCOPE-SORTS

     syntax NamespaceScope

     syntax ClassScope

     syntax BlockScope

     syntax TemplateParameterScope

     syntax FunctionPrototypeScope

     syntax EnumScope

     syntax Scope ::= NamespaceScope | ClassScope | BlockScope | TemplateParameterScope | FunctionPrototypeScope | EnumScope

endmodule // CPP-SCOPE-SORTS

module CPP-SCOPE-SYNTAX
     imports CPP-SCOPE-SORTS // self
     imports CPP-NAMESPACE-SORTS
     imports CPP-CLASS-SORTS
     imports CPP-QUALID-SORTS // NNSVal
     imports BOOL
     imports INT

     syntax SymBase

     syntax Enum

     syntax NamespaceScope ::= namespaceScope(Namespace)

     syntax ClassScope ::= classScope(Class, isInBody: Bool)

     syntax BlockScope ::= blockScope(QualId, SymBase, Int) [klabel(blockScopeCpp)]

     syntax TemplateParameterScope ::= "templateParameterScope"

     syntax FunctionPrototypeScope ::= "prototypeScope"

     syntax EnumScope ::= enumScope(Enum)

     syntax Bool ::= inClassScope(Scope) [function]

     syntax NNSVal ::= getNNSVal(Scope) [function]

     syntax Bool ::= "Scope.isClassScope" "(" Scope ")" [function]
                   | "Scope.isNamespaceScope" "(" Scope ")" [function]
                   | "Scope.isBlockScope" "(" Scope ")" [function]

endmodule // CPP-SCOPE-SYNTAX

module CPP-SCOPE
     imports CPP-SCOPE-SYNTAX // self
     imports CPP-NAMESPACE-SYNTAX // NoNamespace
     imports CPP-QUALID-SYNTAX

     rule inClassScope(_:NamespaceScope) => false
     rule inClassScope(_:ClassScope) => true
     rule inClassScope(blockScope(QX::QualId, _, _)) => isClassQualId(QX)
     rule inClassScope(enumScope(_)) => false

     syntax Bool ::= isClassQualId(QualId) [function]
     rule isClassQualId(C:Class :: _::CId) => true
     rule isClassQualId(_) => false [owise]

     rule getNNSVal(namespaceScope(N::Namespace)) => N
     rule getNNSVal(classScope(C::Class, _)) => C
     rule getNNSVal(_:BlockScope) => NoNamespace()

     rule Scope.isClassScope(classScope(_, _)) => true
     rule Scope.isClassScope(_) => false [owise]

     rule Scope.isNamespaceScope(namespaceScope(_)) => true
     rule Scope.isNamespaceScope(_) => false [owise]

     rule Scope.isBlockScope(blockScope(_,_,_)) => true
     rule Scope.isBlockScope(_) => false [owise]

endmodule // CPP-SCOPE

// ------------------------------
//      CPP-QUALID
// ------------------------------

module CPP-QUALID-SORTS

     // Remote sorts
     syntax Namespace
     syntax Class
     syntax ClassTemplate
     syntax Enum

     syntax NNSVal ::= Namespace | Class | ClassTemplate | Enum
     syntax NNS ::= NNSVal | NNSSpecifier
     syntax NNSSpecifier
     syntax QualId

endmodule // CPP-QUALID-SORTS

module CPP-QUALID-SYNTAX
     imports CPP-QUALID-SORTS // self
     imports CPP-SORTS // CId, Name

     syntax NNS ::= NoNNS()
                  | NNS "::" NNSSpecifier [klabel(NestedName)]

     syntax NNSSpecifier ::= NNS(CId)
                           | TemplateNNS(CId)
                           | NNS(Name)

     syntax QualId ::= NNSVal "::" CId [klabel(QualId)]

     syntax NNSVal ::= getQual(QualId) [function]

     syntax CId ::= getId(QualId) [function]

endmodule // CPP-QUALID-SYNTAX

module CPP-QUALID
     imports CPP-QUALID-SYNTAX // self

    rule getId(_ :: X::CId) => X

    rule getQual(N::NNSVal :: _) => N

endmodule // CPP-QUALID

// ------------------------------
//      CPP-DYNAMIC-OTHER
// ------------------------------

module CPP-DYNAMIC-OTHER-SORTS

     syntax LVal

     syntax XVal

     syntax PRV

     syntax PRVal ::= PRV

     syntax EPRVal

     syntax GLVal ::= LVal | XVal

     syntax RVal ::= XVal | PRVal

     syntax Val ::= GLVal | RVal

     syntax Expr ::= Val

     syntax LExpr

     syntax XExpr

     syntax PRExpr

     syntax GLExpr ::= LExpr | XExpr

     syntax RExpr ::= XExpr | PRExpr

     syntax TExpr ::= GLExpr | RExpr

     syntax Expr ::= TExpr

     syntax Enum

     syntax DeclarationType

     syntax InitType

     syntax Linkage

     syntax Duration

     syntax Scope

     syntax Typed ::= Val | TExpr

     syntax TemplateArgs ::= List{TemplateArg, ","}

     syntax TemplateParams ::= List{TemplateParam, ","}

     syntax TemplateParams ::= TemplateArgs

     syntax TemplateParam ::= TemplateArg

     syntax TemplateArg

     syntax CPPValue
endmodule // CPP-DYNAMIC-OTHER-SORTS

module CPP-REVAL-SYNTAX
     imports CPP-SORTS
     syntax Expr ::= reval(Expr) [strict, klabel(revalCpp)]
endmodule // CPP-REVAL-SORTS

module CPP-DYNAMIC-OTHER-SYNTAX
     imports COMMON-SYNTAX
     imports CPP-DYNAMIC-OTHER-SORTS
     imports BITS-SORTS
     imports CPP-SYMLOC-SORTS
     imports CPP-TYPING-SORTS
     imports CPP-DEPENDENT-SYNTAX
     imports CPP-REVAL-SYNTAX
     imports CPP-QUALID-SORTS
     imports OPTIONS-SYNTAX
     imports FLOAT-SYNTAX
     imports INT-SYNTAX
     imports LIST
     imports SET
     imports BOOL

     syntax CPPValue ::= BitValue
                       | PtrValue
                       | Encodable

     syntax PtrValue ::= NullPtrVal // value of type std::nullptr_t
                       | MemberPtr
                       | vtable(Class) // virtual table pointer in class object

     syntax EffectiveValue ::= CPPValue

     syntax NullPtrVal ::= "nullptrVal"

     syntax CPPValue ::= "voidVal" // not technically a value, but it can be the result of an expression

     syntax LVal ::= lv(v: SymLoc, tr: Trace, t: CPPTypeExpr) [klabel(lvcpp)]

     syntax XVal ::= xv(v: SymLoc, tr: Trace, t: CPPTypeExpr)

     syntax PRV ::= prv(v: CPPValue, tr: Trace, t: CPPTypeExpr)

     syntax LExpr ::= le(v: Expr, tr: Trace, t: CPPTypeExpr) [klabel(lecpp)]

     syntax XExpr ::= xe(v: Expr, tr: Trace, t: CPPTypeExpr)

     syntax PRExpr ::= pre(v: Expr, tr: Trace, t: CPPTypeExpr)

     syntax ValueCategory ::= cat(Typed) [function]

     syntax Bool ::= Execution() [function]
                   | Translation() [function]

     syntax Expr ::= stripHold(Expr) [function, klabel(stripHoldCpp)]

     syntax Bool ::= isEvalVal(K) [function]

     syntax FunctionDeclarationType ::= Function(List)

     syntax VarDeclarationType ::= Var(InitType)

     syntax InitType ::= CopyInit() | DirectInit()

     syntax DeclarationType ::= FunctionDeclarationType | VarDeclarationType

     syntax Decl ::= declareNonStaticObject(id: CId, t: CPPType, init: K, DeclarationType, Duration, Set)

     syntax Decl ::= declareNonStaticObjectExec(id: CId, t: CPPType, init: K, DeclarationType, Duration, Set)

     syntax Decl ::= declareLocalStaticObject(CId, SymBase, CPPType)

     syntax KItem ::= frozenDeclaration(Int, Int, Decl) [klabel(frozenDeclarationCpp)]

     syntax Expr ::= CompoundInitExpr

     syntax CompoundInitExpr ::= compoundInit(Expr, Expr) [strict(1)]

     syntax Expr ::= "callTerminate"

     syntax Enum ::= ClassQualifier "::" EnumSpecifier

     syntax EnumSpecifier ::= Enum(CId) [klabel(enumSpecifier)]

     syntax MaybeNNS ::= NNS | "noNNS"

     syntax MaybeNNS ::= getOuterClass(Class) [function]

     syntax MaybeNNS ::= getParentNamespace(Namespace) [function]

     syntax Bool ::= hasParentNamespace(Namespace) [function]

     syntax Namespace ::= getClassNamespace(Class) [function]

     syntax Class ::= classFromScope(Scope) [function]
                    | classFromType(CPPType) [function]
                    | classFromSimpleType(CPPSimpleType) [function]

     syntax Linkage ::= "ExternalLinkage" | "InternalLinkage" | "NoLinkage"

     syntax Duration ::= "StaticStorage" | "ThreadStorage" | "AutoStorage" | "DynamicStorage"

     syntax CId ::= "funLabel" "(" CId ")"

     syntax KItem ::= functionObject(QualId, CPPType, List, K) [klabel(cppFunctionObject)]


     syntax TemplateInfo ::= "noTemplate"

     syntax KItem ::= "pushBlock" "(" Int ")"
                    | "popBlock"

     syntax Stmt ::= "loopMarked"

     syntax KItem ::= "popLoop"

     syntax KItem ::= gotoObject(Int, List, K, List, List) [klabel(gotoObjectCpp)]

     syntax NotFoundNameRef ::= notFound(CId)

     syntax CandidateSet ::= NotFoundNameRef

     syntax ResolvedExpr ::= NotFoundNameRef

     syntax NameRef ::= nsRef(Namespace) | NotFoundNameRef
                      | templateRef(QualId, CPPTypeExpr)

     syntax Val ::= NameRef

     syntax KResult ::= CPPTypeExpr | NameRef

     syntax Bool ::= isLKLabel(K) [function, klabelPredicate]

     syntax StrictList ::= prval(StrictList)

     syntax TemplateArgs ::= toTemplateArgs(List) [function]
                           | toTemplateArgs(CPPTypes) [function, klabel(CPPTypesToTemplateArgs)]

     syntax TemplateParams ::= toTemplateParams(List) [function]

     syntax List ::= toList(CPPTypes) [function]
                   | toList(CPPTypeExprs) [function]
                   | toList(TemplateArgs) [function]

     syntax CPPTypes ::= toCPPTypes(List) [function]
                       | toCPPTypes(TemplateArgs) [function, klabel(TemplateArgsToCPPTypes)]

     syntax TemplateParam ::= CPPTypeExpr

     syntax TemplateArg ::= CPPType

     syntax String ::= showCPPTypes(CPPTypes) [function]
                     | showCPPType(CPPType) [function]
                     | showSignature(QualId, CPPType) [function]
                     | showQualId(QualId) [function]

     syntax Bool ::= isValKLabel(K) [function, klabelPredicate]

     syntax Bool ::= isTExprKLabel(K) [function, klabelPredicate]

     syntax Expr ::= bindReference(Expr, Expr) [strict(2)]

     syntax KItem ::= "discard"

     syntax Expr ::= "LHOLE" | "RHOLE"

     syntax Expr ::= postOp(Expr, Expr, Trace) [strict(1), klabel(postOpCpp)]

     syntax Expr ::= compoundAssign(Expr, Expr, Trace) [strict(1), klabel(compoundAssignCpp)]
                   | compoundOp(Expr)

     syntax Expr ::= makePRVal(K)

     syntax Trace ::= trace(Typed) [function]

     syntax Expr ::= makeXVal(K)

     // synthetic sort for KResults that result from expressions, but aren't actually values
     syntax ValResult

     syntax Val ::= ValResult

     syntax KResult ::= ValResult

     syntax KItem ::= resolve(Expr)

     // used by destructors
     syntax KItem ::= addToConstructed(Expr, CPPType) [strict(1)]

     syntax Ordering ::= K "|>" Ordering [right]
                       | ".Ordering"

     syntax KItem ::= odrDecl(String, QualId, CId, LanguageLinkage, CPPType)

endmodule // CPP-DYNAMIC-OTHER-SYNTAX

module CPP-DYNAMIC-OTHER
     imports CPP-DYNAMIC-OTHER-SYNTAX
     imports C-CONFIGURATION
     imports STRING
     imports CPP-SYMLOC-SYNTAX
     imports CPP-SYNTAX
     imports CPP-TYPE-MAP-SYNTAX
     imports CPP-TYPING-SYNTAX
     imports CPP-CLASS-BASIC-SYNTAX
     imports CPP-QUALID-SYNTAX
     imports CPP-NAMESPACE-SYNTAX
     imports CPP-SCOPE-SYNTAX
     imports CPP-VALUE-CATEGORY-SYNTAX
     imports CPP-TRACE-SYNTAX

     rule getOuterClass(C:Class :: _::ClassSpecifier) => C

     rule getOuterClass(_) => noNNS [owise]

     rule getParentNamespace(N:Namespace :: _::NamespaceSpecifier) => N

     rule getParentNamespace(_) => noNNS [owise]

     rule hasParentNamespace(N:Namespace :: _::NamespaceSpecifier) => true

     rule hasParentNamespace(_) => false [owise]

     rule getClassNamespace(N:Namespace :: _::ClassSpecifier) => N

     rule getClassNamespace(C:Class :: _::ClassSpecifier => C)

     rule getClassNamespace(localQual(blockScope(N:Namespace :: _:CId, _, _)) :: _::ClassSpecifier) => N

     rule getClassNamespace(localQual(blockScope(C:Class :: _:CId, _, _)) :: _::ClassSpecifier => C)

     rule classFromScope(classScope(C::Class, _)) => C

     rule classFromScope(blockScope(C:Class :: _::CId, _, _)) => C

     rule classFromType(T:CPPClassType) => classFromSimpleType(simpleType(T))

     rule classFromSimpleType(classType(C::Class)) => C

     rule isValKLabel(#klabel(`prv`)) => true

     rule isValKLabel(#klabel(`xv`)) => true

     rule isValKLabel(#klabel(`lvcpp`)) => true

     rule isValKLabel(_) => false [owise]

     rule isTExprKLabel(#klabel(`pre`)) => true

     rule isTExprKLabel(#klabel(`xe`)) => true

     rule isTExprKLabel(#klabel(`lecpp`)) => true

     rule isTExprKLabel(_) => false [owise]

     rule isEvalVal(lv(...)) => true

     rule isEvalVal(xv(...)) => true

     rule isEvalVal(prv(...)) => true

     rule isEvalVal(_) => false [owise]

     // references aren't kresults because they need to get transformed into the object they refer to.
     rule isKResult(Lbl:KLabel(_::CPPValue, _::Trace, T::CPPType)) => notBool isCPPRefType(T)
          requires isValKLabel(#klabel(Lbl))

     rule Lbl:KLabel((loc(Base::SymBase, 0, _) => loc(Base, 0)), _::Trace, _:CPPRefType)
          requires isValKLabel(#klabel(Lbl))

     // not all references are lvalues. Some are xvalues. The individual
     // cases where this is true must handle this explicitly.
     rule <k> Lbl:KLabel(loc(Base::SymBase, Offset::Int), Tr::Trace, T:CPPRefType) => Lbl(V, Tr, innerType(T)) ...</k>
          <references>... loc(Base, Offset) |-> V::SymLoc ...</references>
          requires isValKLabel(#klabel(Lbl))

     rule <k> Lbl:KLabel(E::Expr, Tr::Trace, T:CPPRefType) => Lbl(E, Tr, innerType(T)) ...</k>
          requires isTExprKLabel(#klabel(Lbl)) andBool isTExpr(Lbl(E, Tr, T))

     rule isLKLabel(#klabel(`lvcpp`)) => true

     rule isLKLabel(#klabel(`lecpp`)) => true

     rule isLKLabel(_) => false [owise]

     rule stripHold(le(E::Expr, _, _)) => E

     rule stripHold(xe(E::Expr, _, _)) => E

     rule stripHold(pre(E::Expr, _, _)) => E

     rule stripHold(E::Expr) => E [owise]

     syntax SPRValList ::= toSPRValList(List) [function]

     syntax List ::= ofSPRValList(SPRValList) [function]

     syntax KItem ::= "prval()"

     rule prval(list(HOLE:List)) => toSPRValList(HOLE) ~> prval() [heat]

     rule HOLE:SPRValList ~> prval() => prval(krlist(ofSPRValList(HOLE))) [cool]

     syntax SPRValList ::= K "prval::" SPRValList
                     | ".SPRValList"

     rule isKResult(.SPRValList) => true

     rule isKResult(S1::SPRValList prval:: S2::SPRValList) => isKResult(S1) andBool isKResult(S2)

     rule toSPRValList(ListItem(K:KItem) L::List) => K prval:: toSPRValList(L)

     rule toSPRValList(.List) => .SPRValList

     rule ofSPRValList(krlist(L1::List) prval:: L2::SPRValList) => L1 ofSPRValList(L2)

     rule ofSPRValList(.SPRValList) => .List

     rule ofSPRValList(K:K prval:: L::SPRValList) => ListItem(K) ofSPRValList(L) [owise]

     context (HOLE:Expr => reval(HOLE)) prval:: _ [result(EPRVal)]

     context K:KResult prval:: HOLE:SPRValList

     syntax STypeStrictList ::= toSTypeStrictList(List) [function]

     syntax List ::= ofSTypeStrictList(STypeStrictList) [function]

     syntax KItem ::= "typeStrict()"

     rule typeStrict(list(HOLE:List)) => toSTypeStrictList(HOLE) ~> typeStrict() [heat]

     rule HOLE:STypeStrictList ~> typeStrict() => typeStrict(krlist(ofSTypeStrictList(HOLE))) [cool]

     syntax STypeStrictList ::= K "typeStrict::" STypeStrictList
                     | ".STypeStrictList"

     rule isKResult(.STypeStrictList) => true

     rule isKResult(S1::STypeStrictList typeStrict:: S2::STypeStrictList) => isKResult(S1) andBool isKResult(S2)

     rule toSTypeStrictList(ListItem(K:KItem) L::List) => K typeStrict:: toSTypeStrictList(L)

     rule toSTypeStrictList(.List) => .STypeStrictList

     rule ofSTypeStrictList(krlist(L1::List) typeStrict:: L2::STypeStrictList) => L1 ofSTypeStrictList(L2)

     rule ofSTypeStrictList(.STypeStrictList) => .List

     rule ofSTypeStrictList(K:K typeStrict:: L::STypeStrictList) => ListItem(K) ofSTypeStrictList(L) [owise]

     context HOLE:AType typeStrict:: _ [result(CPPTypeExpr)]

     context HOLE:CPPTypeExpr typeStrict:: _
             requires notBool isDependentInScope(HOLE) [result(CPPType)]

     context K:KResult typeStrict:: HOLE:STypeStrictList

     rule trace(lv(_, Tr::Trace, _)) => Tr

     rule trace(xv(_, Tr::Trace, _)) => Tr

     rule trace(prv(_, Tr::Trace, _)) => Tr

     rule trace(le(_, Tr::Trace, _)) => Tr

     rule trace(xe(_, Tr::Trace, _)) => Tr

     rule trace(pre(_, Tr::Trace, _)) => Tr

     rule toTemplateArgs(ListItem(A::TemplateArg) L::List) => A, toTemplateArgs(L)

     rule toTemplateArgs(T::CPPTypes) => toTemplateArgs(toList(T))

     rule toTemplateArgs(.List) => .TemplateArgs

     rule toCPPTypes(ListItem(A::CPPType) L::List) => A, toCPPTypes(L)

     rule toCPPTypes(.List) => .CPPTypes

     rule toCPPTypes(T::TemplateArgs) => toCPPTypes(toList(T))

     rule toTemplateParams(ListItem(P::TemplateParam) L::List) => P, toTemplateParams(L)

     rule toTemplateParams(.List) => .TemplateParams

     rule toList(T::CPPType, Ts::CPPTypes) => ListItem(T) toList(Ts)

     rule toList(.CPPTypes) => .List

     rule toList(T::TemplateArg, Ts::TemplateArgs) => ListItem(T) toList(Ts)

     rule toList(.TemplateArgs) => .List

     syntax String ::= showNamespace(Namespace) [function]
                     | showClass(Class) [function]

     rule showQualId(N:Namespace :: X::CId)
          => showNamespace(N) +String showCId(X)

     rule showQualId(C:Class :: X::CId)
          => showClass(C) +String showCId(X)

     rule showNamespace(NoNamespace()) => ""

     rule showNamespace(GlobalNamespace()) => "::"

     rule showNamespace(N::Namespace :: Namespace(X::CId))
          => showNamespace(N) +String showCId(X) +String "::"

     rule showClass(N:Namespace :: Class(Key::ClassKey, X::CId, .TemplateArgs))
          => showNamespace(N) +String showCId(X) +String "::"

     rule showClass(C:Class :: Class(Key::ClassKey, X::CId, .TemplateArgs))
          => showClass(C) +String showCId(X) +String "::"

     rule showCId(operatornew) => "operator new"

     rule showCId(operatordelete) => "operator delete"

     rule showCId(operatornew[]) => "operator new[]"

     rule showCId(operatordelete[]) => "operator delete[]"

     rule showCId(operator+) => "operator +"

     rule showCId(operator-) => "operator -"

     rule showCId(operator*) => "operator *"

     rule showCId(operator/) => "operator /"

     rule showCId(operator%) => "operator %"

     rule showCId(operator^) => "operator ^"

     rule showCId(operator&) => "operator &"

     rule showCId(operator|) => "operator |"

     rule showCId(operator~) => "operator ~"

     rule showCId(operator!) => "operator !"

     rule showCId(operator=) => "operator ="

     rule showCId(operator<) => "operator <"

     rule showCId(operator>) => "operator >"

     rule showCId(operator+=) => "operator +="

     rule showCId(operator-=) => "operator -="

     rule showCId(operator*=) => "operator *="

     rule showCId(operator/=) => "operator /="

     rule showCId(operator%=) => "operator %="

     rule showCId(operator^=) => "operator ^="

     rule showCId(operator&=) => "operator &="

     rule showCId(operator|=) => "operator |="

     rule showCId(operator<<) => "operator <<"

     rule showCId(operator>>) => "operator >>"

     rule showCId(operator<<=) => "operator <<="

     rule showCId(operator>>=) => "operator >>="

     rule showCId(operator==) => "operator =="

     rule showCId(operator!=) => "operator !="

     rule showCId(operator<=) => "operator <="

     rule showCId(operator>=) => "operator >="

     rule showCId(operator&&) => "operator &&"

     rule showCId(operator||) => "operator ||"

     rule showCId(operator++) => "operator ++"

     rule showCId(operator--) => "operator --"

     rule showCId(operator,) => "operator ,"

     rule showCId(operator->*) => "operator ->*"

     rule showCId(operator->) => "operator ->"

     rule showCId(operator()) => "operator ()"

     rule showCId(operator[]) => "operator []"

     rule showCId(DestructorId(Identifier(S::String))) => "~" +String S

     rule showSignature(Q::QualId, T::CPPType) => showQualId(Q)
          requires notBool isCPPFunctionType(T)

     rule showSignature(Q::QualId, t(_, _, functionType(... paramTypes: T::CPPTypes))) => showQualId(Q) +String "(" +String showCPPTypes(T) +String ")"

     rule X:K, T:CPPType in_keys(M::Map) => (X in_keys(M)) andBool (T in_keys({M[X]}:>TypeMap))

     rule X:K, Y:K in_keys(M::Map) => (X in_keys(M)) andBool (Y in_keys({M[X]}:>Map)) [owise]

     rule ((A |-> M2:TypeMap) M1::Map) [A:K, B:CPPType <- C:K] => (A |-> (M2[B <- C])) M1

     rule ((A |-> M2::Map) M1::Map) [A:K, B:K <- C:K] => (A |-> (M2[B <- C])) M1
          requires notBool isCPPType(B)

     rule M::Map [A:K, B:CPPType <- C:K] => M A |-> (B |-> C) [owise]

     rule M::Map [A:K, B:K <- C:K] => M A |-> (B |-> C)::Map
          requires notBool isCPPType(B)
          [owise]

     rule showCPPTypes(.CPPTypes) => ""

     rule showCPPTypes(T::CPPType) => showCPPType(T)

     rule showCPPTypes(T1::CPPType, T2::CPPType, Ts::CPPTypes) => showCPPType(T1) +String ", " +String showCPPTypes(T2, Ts)

     syntax String ::= showCPPType(CPPSimpleType) [function, klabel(showCPPSimpleType)]

     rule showCPPType(t(quals(.Set), _, T::CPPSimpleType)) => showCPPType(T)

     rule showCPPType(char) => "char"

     rule showCPPType(signed-char) => "signed char"

     rule showCPPType(unsigned-char) => "unsigned char"

     rule showCPPType(short) => "short"

     rule showCPPType(int) => "int"

     rule showCPPType(long) => "long"

     rule showCPPType(long-long) => "long long"

     rule showCPPType(oversized) => "__int128_t"

     rule showCPPType(unsigned-short) => "unsigned short"

     rule showCPPType(unsigned) => "unsigned int"

     rule showCPPType(unsigned-long) => "unsigned long"

     rule showCPPType(unsigned-long-long) => "unsigned long long"

     rule showCPPType(unsigned-oversized) => "__uint128_t"

     rule showCPPType(float) => "float"

     rule showCPPType(double) => "double"

     rule showCPPType(long-double) => "long double"

     rule showCPPType(bool) => "bool"

     rule showCPPType(void) => "void"

     rule showCPPType(wchar_t) => "wchar_t"

     rule showCPPType(char16_t) => "char16_t"

     rule showCPPType(char32_t) => "char32_t"

     rule showCPPType(nullptr_t) => "std::nullptr_t"

     rule showCPPType(pointerType(T::CPPType)) => showCPPType("", pointerType(T))

     rule showCPPType(classType(N:Namespace :: Class(_, X::CId, .TemplateArgs)))
          => showNamespace(N) +String showCId(X)

     rule showCPPType(classType(N:Namespace :: Class(_, X::CId, T::TemplateArg, Ts::TemplateArgs)))
          => showNamespace(N) +String showCId(X) +String "<" +String showTemplateArgs(T, Ts) +String ">"

     syntax String ::= showCPPType(String, CPPSimpleType) [function, klabel(showCompoundType)]

     rule showCPPType(DDL::String, pointerType(T::CPPType))
          => showCPPType(parens(T, "*" +String DDL), simpleType(T))

     rule showCPPType(DDL::String, T::CPPSimpleType)
          => showCPPType(T) +String " " +String DDL [owise]

     syntax String ::= parens(CPPType, String) [function]

     rule parens(_:CPPFunctionType, S::String) => "(" +String S +String ")"

     rule parens(_:CPPArrayType, S::String) => "(" +String S +String ")"

     rule parens(_, S::String) => S [owise]

     syntax String ::= showTemplateArgs(TemplateArgs) [function]

     rule showTemplateArgs(T:CPPType, .TemplateArgs) => showCPPType(T)

     rule showTemplateArgs(T:CPPType, T2:TemplateArg, Ts::TemplateArgs)
          => showCPPType(T) +String "," +String showTemplateArgs(T2, Ts)

     rule _:KResult ~> discard => .K

     context makePRVal(HOLE:Expr => reval(HOLE)) [result(EPRVal)]

     context makeXVal(HOLE:Expr) [result(LVal)]

     rule makePRVal(R:PRVal) => R

     rule makeXVal(lv(Loc::SymLoc, Tr::Trace, T::CPPType)) => xv(Loc, Tr, T)

     rule makeXVal(le(E::Expr, Tr::Trace, T::CPPType)) => xe(E, Tr, T)

     rule callTerminate
          => BuiltinCallOp(
               lv(
                    loc(obj(0, 0, builtinCppSymbol("::std::terminate()")), 0),
                    noTrace,
                    type(functionType(type(void), .CPPTypeExprs, noMethod, CLinkage, noexcept(false)))
               ),
               false,
               .List
             )

     context resolve(HOLE:Expr) [result(ResolvedExpr), structural]

     rule cat(prv(...)) => prvalue

     rule cat(pre(...)) => prvalue

     rule cat(lv(...)) => lvalue

     rule cat(le(...)) => lvalue

     rule cat(xv(...)) => xvalue

     rule cat(xe(...)) => xvalue

     rule pre(E::Expr, _, _) => E
          requires Execution()

     rule xe(E::Expr, _, _) => E
          requires Execution()

     rule le(E::Expr, _, _) => E
          requires Execution()

     rule Translation() => notBool Execution()

     // is given prval fully evaluated?
     rule isEPRVal(E:PRVal) => Translation() orBool isPRV(E)

endmodule // CPP-DYNAMIC-OTHER

// ------------------------------
//      CPP-DYNAMIC
// ------------------------------

module CPP-DYNAMIC-SORTS

     imports CPP-VALUE-CATEGORY-SORTS
     imports CPP-CLASS-BASIC-SORTS
     imports CPP-NAMESPACE-SORTS
     imports CPP-TRACE-SORTS
     imports CPP-SCOPE-SORTS
     imports CPP-QUALID-SORTS
     imports CPP-DYNAMIC-OTHER-SORTS

endmodule // CPP-DYNAMIC-SORTS

module CPP-DYNAMIC-SYNTAX

     imports CPP-VALUE-CATEGORY-SYNTAX
     imports CPP-TRACE-SYNTAX
     imports CPP-NAMESPACE-SYNTAX
     imports CPP-SCOPE-SYNTAX
     imports CPP-QUALID-SYNTAX
     imports CPP-DYNAMIC-OTHER-SYNTAX

endmodule // CPP-DYNAMIC-SYNTAX

module CPP-DYNAMIC

     imports CPP-NAMESPACE
     imports CPP-TRACE
     imports CPP-VALUE-CATEGORY
     imports CPP-SCOPE
     imports CPP-QUALID
     imports CPP-DYNAMIC-OTHER

endmodule // CPP-DYNAMIC
