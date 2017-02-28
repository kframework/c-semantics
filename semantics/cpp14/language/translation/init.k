module CPP-TRANSLATION-INIT-SYNTAX
     imports COMMON-SORTS

     syntax KItem ::= makeNs(Namespace)
endmodule

module CPP-TRANSLATION-INIT
     imports CPP-TRANSLATION-INIT-SYNTAX
     imports STRING
     imports COMMON-BUILTIN-SYNTAX
     imports COMPAT-SYNTAX
     imports MEMORY-SYNTAX
     imports C-LINKING-INIT-SYNTAX
     imports C-LINKING-RESOLUTION-SYNTAX
     imports CPP-ABSTRACT-SYNTAX
     imports CPP-BUILTIN-SYNTAX
     imports CPP-DECL-DECLARATOR-SYNTAX
     imports CPP-DYNAMIC-SYNTAX
     imports CPP-ERROR-SYNTAX
     imports CPP-SYMLOC-SYNTAX
     imports CPP-SYNTAX
     imports CPP-TYPING-SYNTAX

     imports C-CONFIGURATION

     rule isKResult(Lbl:KLabel(_::CPPValue, _::Trace, T::CPPType)) => notBool isCPPRefType(T)
          requires isTExprKLabel(#klabel(Lbl))

     rule <k> TranslationUnit(TU:String, Decls:List)
               => makeTu(TU +String newUUID)
               ~> makeNs(GlobalNamespace())
               ~> implicitDecls
               ~> listToK(Decls)
               ~> removeUnusedIdentifiers
          ...</k>
          // don't delete this... we want to make sure the fresh counter starts
          // at 1 for each TU because unlike C, C++ doesn't give us unique block
          // numbers directly from the parser, so we are using the fresh counter to
          // assign block numbers. But the fresh counter starts at 0 and block 0
          // is the privileged "haven't entered the outer block of the function yet"
          // block.
          requires !Fresh:Int >=Int 0 

     syntax KItem ::= "implicitDecls"
                    | "func" "(" Namespace "," CId "," CPPType "," CPPTypes "," ExceptionSet ")" [function]
     rule implicitDecls
          => func(GlobalNamespace(), operatornew, ptr(type(void)), type(size_t), noexcept(false))
          ~> func(GlobalNamespace(), operatornew[], ptr(type(void)), type(size_t), noexcept(false))
          ~> func(GlobalNamespace(), operatordelete, type(void), ptr(type(void)), noexcept(true))
          ~> func(GlobalNamespace(), operatordelete[], type(void), ptr(type(void)), noexcept(true))
          ~> func(GlobalNamespace(), operatordelete, type(void), ptr(type(void)), type(size_t), noexcept(true))
          ~> func(GlobalNamespace(), operatordelete[], type(void), ptr(type(void)), type(size_t), noexcept(true))

     rule func(N::Namespace, X::CId, Ret::CPPType, Args::CPPTypes, E::ExceptionSet) 
          => declareObject(N, N, X, type(functionType(Ret, Args, noMethod, CPPLinkage, E)), NoInit(), Function(.List), ExternalLinkage, StaticStorage, .Set)

     rule <k> makeNs(N::Namespace) => .K ...</k>
          <curr-tu> Tu::String </curr-tu>
          <tu-id> Tu </tu-id>
          <namespaces>...
               (.Bag => <ns>...
                             <ns-id> N </ns-id>
                        ...</ns>)
          ...</namespaces>

     rule addCPPBuiltins => addCPPBuiltins(weakCppBuiltins, false)

     rule <k> builtinTu => TranslationUnit("cpp-builtin", ListItem(addCPPBuiltins(cppBuiltins, true)))
          ...</k>
          <options>... SetItem(XBuiltins()) ...</options>

     rule <k> builtinTu => .K ...</k>
          <options> Opts:Set </options>
          requires notBool (XBuiltins() in Opts)

     syntax KItem ::= addCPPBuiltins(K, Bool)
     rule <k> (.K => addBuiltin(B, T, AddAll))
               ~> addCPPBuiltins((B::QualId -> T::CPPType => .K) ~> _, AddAll::Bool) ...</k>
     rule addCPPBuiltins(.K, _) => .K

     syntax KItem ::= addBuiltin(QualId, CPPType, Bool) [klabel(addBuiltinCpp)]
 
     // we use the empty modifier set because this is a function and can't really
     // have an alignment anyway since it's not an object.
     rule <k> addBuiltin(Q::QualId, T:CPPFunctionType, AddAll:Bool)
              => declareBuiltinFunction(Q, T, linc(T, .Set, builtinSymbol(signatureToString(Q, T)))) ...</k>
          <odr-defs> Defs:Map </odr-defs>
          <curr-tu> Tu::String </curr-tu>
          <tu-id> Tu </tu-id>
          requires (notBool (Q, T in_keys(Defs))) orBool AddAll

     rule <k> addBuiltin(Q::QualId, T::CPPType, false) => checkReplaceable(Q, T, Defs) ...</k>
          <odr-defs> Defs:Map </odr-defs>
          requires Q, T in_keys(Defs)

     syntax K ::= checkReplaceable(QualId, CPPType, Map) [function]
     syntax Error ::= "replaceableError"
     rule checkReplaceable(GlobalNamespace() :: operatordelete, t(_, _, functionType(... returnType: t(_, _, void), paramTypes: t(_, _, pointerType(t(_, _, void))), linkage: CPPLinkage)), Defs::Map)
          => ILL("TIN1", "Declared replacement function operator delete(void *) but no operator delete(void *, std::size_t).")
          ~> replaceableError
          requires notBool(GlobalNamespace() :: operatordelete, func(type(void), ptr(type(void)), type(size_t)) in_keys(Defs))
     rule checkReplaceable(GlobalNamespace() :: operatordelete, t(_, _, functionType(... returnType: t(_, _, void), paramTypes: (t(_, _, pointerType(t(_, _, void))), t(_, _, T::CPPSimpleType)), linkage: CPPLinkage)), Defs::Map)
          => ILL("TIN2", "Declared replacement function operator delete(void *, std::size_t) but no operator delete(void *).")
          ~> replaceableError
          requires T ==K size_t andBool notBool(GlobalNamespace() :: operatordelete, func(type(void), ptr(type(void))) in_keys(Defs))
     rule checkReplaceable(_, _, _) => .K [owise]

     syntax KItem ::= declareBuiltinFunction(QualId, CPPType, SymBase) [klabel(declareBuiltinFunctionCpp)]
     rule <k> declareBuiltinFunction(N::Namespace :: X::CId, T::CPPType, Base::SymBase) => .K ...</k>
          <mem> Mem::Map => Mem[Base <- object(T, 0, makeEmptyArray(0))] </mem>
          <functions> Fun::Map => Fun[Base <- functionObject(N :: X, T, getDummyParams(T), callBuiltin)] </functions>
          <odr-defs> Defs::Map => Defs[N :: X, T <- Base] </odr-defs>

     syntax List ::= getDummyParams(CPPType) [function]
     syntax List ::= #getDummyParams(CPPTypes, Int) [function]
     rule getDummyParams(t(_, _, functionType(... paramTypes: Ts::CPPTypes))) => #getDummyParams(Ts, 0)
     rule #getDummyParams(T::CPPType, Ts::CPPTypes, I::Int) => ListItem(Identifier("_" +String Int2String(I))) #getDummyParams(Ts, I +Int 1)
     rule #getDummyParams(.CPPTypes, _) => .List

     rule isCLinkage(t(_, _, functionType(... linkage: CLinkage))) => true
     rule isCLinkage(_) => false [owise]

     rule combine(hasTrace(E::Expr), #klabel(Lbl:KLabel)) => hasTrace(Lbl(E))
     rule combine(hasTrace(E::Expr), hasTrace(E2::Expr), #klabel(Lbl:KLabel)) => hasTrace(Lbl(E, E2))
     rule combine(hasTrace(E::Expr), hasTrace(E2::Expr), hasTrace(E3::Expr), V::ValueCategory, T::CPPType) => hasTrace(ConditionalOp(E, E2, E3, V, T))
     rule combine(_, _) => noTrace [owise]
     rule combine(_, _::Trace, _) => noTrace [owise]
     rule combine(_, _, _::Trace, _, _) => noTrace [owise]

     rule DeclLoc(L::CabsLoc, D::Decl) => L ~> D
     rule StmtLoc(L::CabsLoc, S::Stmt) => L ~> S

     rule <k> L:CabsLoc => .K ...</k>
          <elab>... .K => L </elab>
          <curr-program-loc> _ => L </curr-program-loc>

     rule <k> ExprLoc(L::CabsLoc, E::Expr) => #ExprLoc(L, E) ...</k>
          <curr-program-loc> _ => L </curr-program-loc>

     syntax Expr ::= #ExprLoc(CabsLoc, Expr) [strict(2)]
     rule <k> #ExprLoc(L::CabsLoc, V:Val) => V ...</k>
          <curr-program-loc> _ => L </curr-program-loc>
          requires notBool isTExpr(V)
     rule <k> #ExprLoc(L::CabsLoc, V:PRExpr) => pre(ExprLoc(L, stripHold(V)), trace(V), type(V)) ...</k>
          <curr-program-loc> _ => L </curr-program-loc>
     rule <k> #ExprLoc(L::CabsLoc, V:XExpr) => xe(ExprLoc(L, stripHold(V)), trace(V), type(V)) ...</k>
          <curr-program-loc> _ => L </curr-program-loc>
     rule <k> #ExprLoc(L::CabsLoc, V:LExpr) => le(ExprLoc(L, stripHold(V)), trace(V), type(V)) ...</k>
          <curr-program-loc> _ => L </curr-program-loc>
     
endmodule
