module CPP-DYNAMIC-SORTS
     syntax LVal
     syntax XVal
     syntax PRVal
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
     syntax NNSVal ::= Namespace | Class | ClassTemplate | Enum
     syntax NNS ::= NNSVal | NNSSpecifier
     syntax Namespace
     syntax Class
     syntax ClassTemplate
     syntax NNSSpecifier
     syntax DeclarationType
     syntax InitType
     syntax Linkage
     syntax Duration
     syntax QualId
     syntax Scope
     syntax Trace
     syntax Typed ::= Val | TExpr
     syntax TemplateArgs ::= List{TemplateArg, ","}
     syntax TemplateParams ::= List{TemplateParam, ","}
     syntax TemplateParams ::= TemplateArgs
     syntax TemplateParam ::= TemplateArg
     syntax TemplateArg
     syntax CPPValue
     syntax ValueCategory
endmodule

module CPP-REVAL-SYNTAX
     imports CPP-SORTS
     syntax Expr ::= reval(Expr) [strict, klabel(revalCpp)]
endmodule

module CPP-DYNAMIC-SYNTAX
     imports COMMON-SYNTAX
     imports CPP-DYNAMIC-SORTS
     imports BITS-SORTS
     imports CPP-SYMLOC-SORTS
     imports CPP-TYPING-SORTS
     imports CPP-DEPENDENT-SYNTAX
     imports CPP-REVAL-SYNTAX
     imports FLOAT-SYNTAX
     imports INT-SYNTAX
     imports LIST
     imports SET
     imports BOOL

     syntax CPPValue ::= SymLoc
                       | BitValue
                       | NullPtrVal // value of type std::nullptr_t
                       | Float
                       | MemberPtr
                       | vtable(Class) // virtual table pointer in class object
     syntax EffectiveValue ::= CPPValue
     syntax NullPtrVal ::= "nullptrVal"

     syntax CPPValue ::= "voidVal" // not technically a value, but it can be the result of an expression

     syntax LVal ::= lv(v: SymLoc, tr: Trace, t: CPPTypeExpr) [klabel(lvcpp)]
     syntax XVal ::= xv(v: SymLoc, tr: Trace, t: CPPTypeExpr)
     syntax PRVal ::= prv(v: CPPValue, tr: Trace, t: CPPTypeExpr)

     syntax LExpr ::= le(v: Expr, tr: Trace, t: CPPTypeExpr) [klabel(lecpp)]
     syntax XExpr ::= xe(v: Expr, tr: Trace, t: CPPTypeExpr)
     syntax PRExpr ::= pre(v: Expr, tr: Trace, t: CPPTypeExpr)

     syntax LValueCategory ::= "lvalue"
     syntax XValueCategory ::= "xvalue"
     syntax PRValueCategory ::= "prvalue"
     syntax GLValueCategory ::= LValueCategory | XValueCategory
     syntax RValueCategory ::= XValueCategory | PRValueCategory
     syntax ValueCategory ::= GLValueCategory | RValueCategory | InitListCategory
     syntax KResult ::= ValueCategory
     syntax InitListCategory ::= initListCat(List)

     syntax ValueCategory ::= cat(Typed) [function]

     syntax ValueCategory ::= NoInitValueCategory
     syntax NoInitValueCategory ::= NoInitCat()

     syntax Expr ::= stripHold(Expr) [function, klabel(stripHoldCpp)]

     syntax Trace ::= hasTrace(K) | trace(Typed) [function] | "noTrace"
     syntax Trace ::= combine(Trace, K) [function]
     syntax Trace ::= combine(Trace, Trace, K) [function, klabel(combine2)]
     syntax Trace ::= combine(Trace, Trace, Trace, ValueCategory, CPPType) [function, klabel(combine3)]
 
     syntax FunctionDeclarationType ::= "Function" "(" List ")" 
     syntax VarDeclarationType ::= "Var" "(" InitType ")"
     syntax InitType ::= CopyInit() | DirectInit()
     syntax DeclarationType ::= FunctionDeclarationType | VarDeclarationType
     syntax Decl ::= declareNonStaticObject(id: CId, t: CPPType, init: K, DeclarationType, Duration, Set)
     syntax Decl ::= declareLocalStaticObject(CId, SymBase, CPPType)
     syntax KItem ::= frozenDeclaration(Int, Int, Decl) [klabel(frozenDeclarationCpp)]
     syntax Expr ::= compoundInit(Expr, Expr) [strict(1)]

     syntax Expr ::= "callTerminate"

     syntax UnnamedNamespace
     syntax NNS ::= NoNNS()
                  | NNS "::" NNSSpecifier [klabel(NestedName)]
     syntax NNSSpecifier ::= NNS(CId)
                           | TemplateNNS(CId)
                           | NNS(Name)

     syntax Namespace ::= Namespace "::" NamespaceSpecifier
                        | NoNamespace() // signifies a declaration at block scope
                        | UnnamedNamespace
     syntax NamespaceSpecifier ::= Namespace(CId)

     syntax LocalQualifier ::= localQual(BlockScope)
     // a large amount of code changes behavior based on whether it is within a namespace, a class, or a block.
     // in the event that new values must be added to this sort, please make sure to extensively examine existing
     // code involving ClassQualifier and NNSVal.
     syntax ClassQualifier ::= Namespace | Class | LocalQualifier
     syntax Class ::= ClassQualifier "::" ClassSpecifier
     syntax LocalClass ::= LocalQualifier "::" ClassSpecifier
     syntax InnerClass ::= Class "::" ClassSpecifier
     syntax LocalInnerClass ::= LocalClass
                             | LocalInnerClass "::" ClassSpecifier
     syntax ClassSpecifier ::= Class(Tag, CId, TemplateArgs) [klabel(classSpecifier)]
     syntax ClassTemplate ::= Namespace "::" ClassTemplateSpecifier
     syntax ClassTemplateSpecifier ::= Class(Tag, CId, TemplateParams) [klabel(classSpecifier)]
                                     | ClassSpecifier //not technically a class template, but this type exists primarily to support CPPClassTypeExpr, so it's needed

     syntax Enum ::= ClassQualifier "::" EnumSpecifier
     syntax EnumSpecifier ::= Enum(CId) [klabel(enumSpecifier)]

     syntax MaybeNNS ::= NNS | "noNNS"
     syntax MaybeNNS ::= getOuterClass(Class) [function]

     syntax MaybeNNS ::= getParentNamespace(Namespace) [function]

     syntax Bool ::= hasParentNamespace(Namespace) [function]

     syntax Namespace ::= getClassNamespace(Class) [function]

     syntax QualId ::= NNSVal "::" CId [klabel(QualId)]
     syntax NNSVal ::= getQual(QualId) [function]
     syntax CId ::= getId(QualId) [function]

     syntax NamespaceScope ::= namespaceScope(Namespace)
     syntax ClassScope ::= classScope(Class, isInBody: Bool)
     syntax BlockScope ::= blockScope(QualId, SymBase, Int) [klabel(blockScopeCpp)]
     syntax TemplateParameterScope ::= "templateParameterScope"
     syntax FunctionPrototypeScope ::= "prototypeScope"
     syntax EnumScope ::= enumScope(Enum)
     syntax Scope ::= NamespaceScope | ClassScope | BlockScope | TemplateParameterScope | FunctionPrototypeScope | EnumScope

     syntax Bool ::= enclosesNamespace(Namespace, Namespace) [function]

     syntax Bool ::= inClassScope(Scope) [function]

     syntax Bool ::= isClassQualId(QualId) [function]

     syntax Class ::= classFromScope(Scope) [function]

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
     syntax CPPTypes ::= toCPPTypes(List) [function]

     syntax TemplateParam ::= CPPTypeExpr
     syntax TemplateArg ::= CPPType

     syntax String ::= typesToString(CPPTypes) [function]
                     | typeToString(CPPType) [function]
                     | signatureToString(QualId, CPPType) [function]
                     | idToString(QualId) [function, klabel(qualIdToString)]

     syntax Bool ::= isValKLabel(K) [function, klabelPredicate]
     syntax Bool ::= isTExprKLabel(K) [function, klabelPredicate]

     syntax Expr ::= bindReference(Expr, Expr) [strict(2)]

     syntax KItem ::= "discard"
     syntax Expr ::= "LHOLE" | "RHOLE"
     syntax Expr ::= postOp(Expr, Expr, Trace) [strict(1), klabel(postOpCpp)]
     syntax Expr ::= compoundAssign(Expr, Expr, Trace) [strict(1), klabel(compoundAssignCpp)]
                   | compoundOp(Expr)
     syntax KItem ::= fillLHoles(K, K) [function, klabel(fillLHolesCpp)]
     syntax KItem ::= fillRHoles(K, K) [function, klabel(fillRHolesCpp)]
     syntax Expr ::= makePRVal(K)
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

endmodule

module CPP-DYNAMIC
     imports CPP-DYNAMIC-SYNTAX
     imports C-CONFIGURATION
     imports STRING
     imports CPP-SYMLOC-SYNTAX
     imports CPP-SYNTAX
     imports CPP-TYPING-SYNTAX

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

     rule inClassScope(_:NamespaceScope) => false
     rule inClassScope(_:ClassScope) => true
     rule inClassScope(blockScope(QX::QualId, _, _)) => isClassQualId(QX)
     rule inClassScope(enumScope(_)) => false

     rule isClassQualId(C:Class :: _::CId) => true
     rule isClassQualId(_) => false [owise]

     rule classFromScope(classScope(C::Class, _)) => C
     rule classFromScope(blockScope(C:Class :: _::CId, _, _)) => C

     rule enclosesNamespace(N::Namespace, N :: _) => true
     rule enclosesNamespace(N::Namespace, M::Namespace :: _) => enclosesNamespace(N, M)
          requires N =/=K M
     rule enclosesNamespace(...) => false [owise]

     rule isValKLabel(#klabel(`prv`)) => true
     rule isValKLabel(#klabel(`xv`)) => true
     rule isValKLabel(#klabel(`lvcpp`)) => true
     rule isValKLabel(_) => false [owise]
     rule isTExprKLabel(#klabel(`pre`)) => true
     rule isTExprKLabel(#klabel(`xe`)) => true
     rule isTExprKLabel(#klabel(`lecpp`)) => true
     rule isTExprKLabel(_) => false [owise]

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
     rule toSPRValList(ListItem(K:K) L::List) => K prval:: toSPRValList(L)
     rule toSPRValList(.List) => .SPRValList
     rule ofSPRValList(krlist(L1::List) prval:: L2::SPRValList) => L1 ofSPRValList(L2)
     rule ofSPRValList(.SPRValList) => .List
     rule ofSPRValList(K:K prval:: L::SPRValList) => ListItem(K) ofSPRValList(L) [owise]

     context (HOLE:Expr => reval(HOLE)) prval:: _ [result(PRVal)]
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
     rule toSTypeStrictList(ListItem(K:K) L::List) => K typeStrict:: toSTypeStrictList(L)
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
     rule toTemplateParams(ListItem(P::TemplateParam) L::List) => P, toTemplateParams(L)
     rule toTemplateParams(.List) => .TemplateParams
     rule toList(T::CPPType, Ts::CPPTypes) => ListItem(T) toList(Ts)
     rule toList(.CPPTypes) => .List

     syntax String ::= namespaceToString(Namespace) [function]
     rule idToString(N:Namespace :: X::CId)
          => namespaceToString(N) +String idToString(X)
     rule namespaceToString(NoNamespace()) => ""
     rule namespaceToString(GlobalNamespace()) => "::"
     rule namespaceToString(N::Namespace :: Namespace(X::CId))
          => namespaceToString(N) +String idToString(X) +String "::"

     rule idToString(operatornew) => "operator new"
     rule idToString(operatordelete) => "operator delete"
     rule idToString(operatornew[]) => "operator new[]"
     rule idToString(operatordelete[]) => "operator delete[]"
     rule idToString(operator+) => "operator +"
     rule idToString(operator-) => "operator -"
     rule idToString(operator*) => "operator *"
     rule idToString(operator/) => "operator /"
     rule idToString(operator%) => "operator %"
     rule idToString(operator^) => "operator ^"
     rule idToString(operator&) => "operator &"
     rule idToString(operator|) => "operator |"
     rule idToString(operator~) => "operator ~"
     rule idToString(operator!) => "operator !"
     rule idToString(operator=) => "operator ="
     rule idToString(operator<) => "operator <"
     rule idToString(operator>) => "operator >"
     rule idToString(operator+=) => "operator +="
     rule idToString(operator-=) => "operator -="
     rule idToString(operator*=) => "operator *="
     rule idToString(operator/=) => "operator /="
     rule idToString(operator%=) => "operator %="
     rule idToString(operator^=) => "operator ^="
     rule idToString(operator&=) => "operator &="
     rule idToString(operator|=) => "operator |="
     rule idToString(operator<<) => "operator <<"
     rule idToString(operator>>) => "operator >>"
     rule idToString(operator<<=) => "operator <<="
     rule idToString(operator>>=) => "operator >>="
     rule idToString(operator==) => "operator =="
     rule idToString(operator!=) => "operator !="
     rule idToString(operator<=) => "operator <="
     rule idToString(operator>=) => "operator >="
     rule idToString(operator&&) => "operator &&"
     rule idToString(operator||) => "operator ||"
     rule idToString(operator++) => "operator ++"
     rule idToString(operator--) => "operator --"
     rule idToString(operator,) => "operator ,"
     rule idToString(operator->*) => "operator ->*"
     rule idToString(operator->) => "operator ->"
     rule idToString(operator()) => "operator ()"
     rule idToString(operator[]) => "operator []"
     rule idToString(DestructorId(Identifier(S::String))) => "~" +String S

     rule signatureToString(Q::QualId, T::CPPType) => idToString(Q)
          requires notBool isCPPFunctionType(T)
     rule signatureToString(Q::QualId, t(_, _, functionType(... paramTypes: T::CPPTypes))) => idToString(Q) +String "(" +String typesToString(T) +String ")"

     rule X:K, T::CPPType in_keys(M::Map) => X in_keys(M) andBool typeInKey(M[X], T)
     syntax Bool ::= typeInKey(K, CPPType) [function]
     rule typeInKey(T1::CPPType |-> _ _::Map, T2::CPPType) => true
          requires T1 ==Type T2
     rule typeInKey((_ |-> _ => .Map) _, _) [owise]
     rule typeInKey(.Map, _) => false

     rule typesToString(.CPPTypes) => ""
     rule typesToString(T::CPPType) => typeToString(T)
     rule typesToString(T1::CPPType, T2::CPPType, Ts::CPPTypes) => typeToString(T1) +String ", " +String typesToString(T2, Ts)
     syntax String ::= typeToString(CPPSimpleType) [function, klabel(simpleTypeToString)]
     rule typeToString(t(quals(.Set), _, T::CPPSimpleType)) => typeToString(T)
     rule typeToString(char) => "char"
     rule typeToString(signed-char) => "signed char"
     rule typeToString(unsigned-char) => "unsigned char"
     rule typeToString(short) => "short"
     rule typeToString(int) => "int"
     rule typeToString(long) => "long"
     rule typeToString(long-long) => "long long"
     rule typeToString(unsigned-short) => "unsigned short"
     rule typeToString(unsigned) => "unsigned int"
     rule typeToString(unsigned-long) => "unsigned long"
     rule typeToString(unsigned-long-long) => "unsigned long long"
     rule typeToString(float) => "float"
     rule typeToString(double) => "double"
     rule typeToString(long-double) => "long double"
     rule typeToString(bool) => "bool"
     rule typeToString(void) => "void"
     rule typeToString(wchar_t) => "wchar_t"
     rule typeToString(char16_t) => "char16_t"
     rule typeToString(char32_t) => "char32_t"
     rule typeToString(nullptr_t) => "std::nullptr_t"
     rule typeToString(pointerType(T::CPPType)) => typeToString("", pointerType(T))
     rule typeToString(classType(N:Namespace :: Class(_, X::CId, .TemplateArgs)))
          => namespaceToString(N) +String idToString(X)
     rule typeToString(classType(N:Namespace :: Class(_, X::CId, T::TemplateArg, Ts::TemplateArgs)))
          => namespaceToString(N) +String idToString(X) +String "<" +String templateArgsToString(T, Ts) +String ">"
     syntax String ::= typeToString(String, CPPSimpleType) [function, klabel(compoundTypeToString)]
     rule typeToString(DDL::String, pointerType(T::CPPType))
          => typeToString(parens(T, "*" +String DDL), simpleType(T))
     rule typeToString(DDL::String, T::CPPSimpleType)
          => typeToString(T) +String " " +String DDL [owise]

     syntax String ::= parens(CPPType, String) [function]
     rule parens(_:CPPFunctionType, S::String) => "(" +String S +String ")"
     rule parens(_:CPPArrayType, S::String) => "(" +String S +String ")"
     rule parens(_, S::String) => S [owise]

     syntax String ::= templateArgsToString(TemplateArgs) [function]
     rule templateArgsToString(T:CPPType, .TemplateArgs) => typeToString(T)
     rule templateArgsToString(T:CPPType, T2:TemplateArg, Ts::TemplateArgs)
          => typeToString(T) +String "," +String templateArgsToString(T2, Ts)

     rule fillRHoles(V::PRVal, RHOLE) => V
     rule fillRHoles(V::PRVal, Lbl:KLabel(L:K))
          => Lbl(fillRHoles(V, L))
          requires #klabel(Lbl) =/=K #klabel(`compoundAssignCpp`) andBool #klabel(Lbl) =/=K #klabel(`postOpCpp`)
     rule fillRHoles(V::PRVal, Lbl:KLabel(L:K, R:K))
          => Lbl(fillRHoles(V, L), fillRHoles(V, R))
          requires #klabel(Lbl) =/=K #klabel(`compoundAssignCpp`) andBool #klabel(Lbl) =/=K #klabel(`postOpCpp`)
     rule fillRHoles(V::PRVal, Lbl:KLabel(L:K, M:K, R:K))
          => Lbl(fillRHoles(V, L), fillRHoles(V, M), fillRHoles(V, R))
          requires #klabel(Lbl) =/=K #klabel(`compoundAssignCpp`) andBool #klabel(Lbl) =/=K #klabel(`postOpCpp`)
     rule fillRHoles(_, K:K) => K [owise]

     rule fillLHoles(V::LVal, LHOLE) => V
     rule fillLHoles(V::LVal, Lbl:KLabel(L:K))
          => Lbl(fillLHoles(V, L))
          requires #klabel(Lbl) =/=K #klabel(`compoundAssignCpp`) andBool #klabel(Lbl) =/=K #klabel(`postOpCpp`)
     rule fillLHoles(V::LVal, Lbl:KLabel(L:K, R:K))
          => Lbl(fillLHoles(V, L), fillLHoles(V, R))
          requires #klabel(Lbl) =/=K #klabel(`compoundAssignCpp`) andBool #klabel(Lbl) =/=K #klabel(`postOpCpp`)
     rule fillLHoles(V::PRVal, Lbl:KLabel(L:K, M:K, R:K))
          => Lbl(fillLHoles(V, L), fillLHoles(V, M), fillLHoles(V, R))
          requires #klabel(Lbl) =/=K #klabel(`compoundAssignCpp`) andBool #klabel(Lbl) =/=K #klabel(`postOpCpp`)
     rule fillLHoles(_, K:K) => K [owise]

     rule _:KResult ~> discard => .K

     context makePRVal(HOLE:Expr => reval(HOLE)) [result(PRVal)]
     context makeXVal(HOLE:Expr) [result(LVal)]
     rule makePRVal(R:PRVal) => R
     rule makeXVal(lv(Loc::SymLoc, Tr::Trace, T::CPPType)) => xv(Loc, Tr, T)
     rule makeXVal(le(E::Expr, Tr::Trace, T::CPPType)) => xe(E, Tr, T)

     rule callTerminate => BuiltinCallOp(lv(loc(obj(0, 0, builtinSymbol("::std::terminate()")), 0), noTrace, type(functionType(type(void), .CPPTypeExprs, noMethod, CLinkage, noexcept(false)))), false, .List) 

     rule getId(_ :: X::CId) => X
     rule getQual(N::NNSVal :: _) => N

     context resolve(HOLE:Expr) [result(ResolvedExpr), structural]

     rule cat(prv(...)) => prvalue
     rule cat(pre(...)) => prvalue
     rule cat(lv(...)) => lvalue
     rule cat(le(...)) => lvalue
     rule cat(xv(...)) => xvalue
     rule cat(xe(...)) => xvalue

endmodule
