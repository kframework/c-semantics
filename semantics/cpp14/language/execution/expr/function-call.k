module CPP-EXPR-FUNCTION-CALL
     imports FUNCTION-CALL-SYNTAX
     imports C-CONFIGURATION
     imports INT
     imports BITS-SYNTAX
     imports C-CHECK-LOC-SYNTAX
     imports C-DYNAMIC-SYNTAX
     imports C-SEQUENCE-POINT-SYNTAX
     imports C-TYPING-COMMON-SYNTAX
     imports C-TYPING-SYNTAX
     imports CPP-BINDING-SYNTAX
     imports CPP-BITSIZE-SYNTAX
     imports CPP-DYNAMIC-SYNTAX
     imports CPP-ENV-SYNTAX
     imports CPP-MEMORY-ALLOC-SYNTAX
     imports CPP-MEMORY-READING-SYNTAX
     imports CPP-SYNTAX
     imports CPP-TYPING-SYNTAX
     imports CPP-EXPR-MEMBERS-SYNTAX

     rule BuiltinCallOp(lv(_, _, T:CPPPointerType) #as L::LVal => * L, false, _)
          requires isCPPFunctionType(innerType(T))
     context BuiltinCallOp((* _) #as HOLE:Expr, false, _)

     // Function call (from C++ function)
     rule BuiltinCallOp(lv((loc(Base::SymBase, Offset::Int, _) => loc(Base, Offset)), _, _:CPPFunctionType), _, _)
     rule <k> BuiltinCallOp(lv(loc((Base::SymBase => Base'), _), _, _:CPPFunctionType), _, _) ...</k>
          <linkings>... Base |-> Base'::SymBase ...</linkings>

     rule <k> BuiltinCallOp(lv(loc(Base::SymBase, 0), _, T:CPPFunctionType), IsVirtual::Bool, Args::List)
              => prepareArguments(CurrLoc, Base, Fun, T, IsVirtual, Args)
          ...</k>
          <functions>... Base |-> Fun:K ...</functions>
          <curr-program-loc> CurrLoc::CabsLoc </curr-program-loc>
          requires notBool isLinkerLoc(Base)

     syntax Expr ::= prepareArguments(CabsLoc, SymBase, K, CPPType, Bool, List)

     rule prepareArguments(CurrLoc::CabsLoc, Base::SymBase, Fun:K, CallT::CPPType, IsVirtual::Bool, Args::List)
          => evalArgs(CurrLoc, Base, Fun, CallT, IsVirtual, list(mapList(Args, #klabel(`allowInit`))))

     syntax Expr ::= evalArgs(CabsLoc, SymBase, fun: K, CPPType, Bool, args: StrictList)

     // evaluating arguments for call to C function
     context evalArgs(... fun: functionObject(_::CId, _, _, _), args: HOLE:StrictList => prval(HOLE))
     // evaluating arguments for call to C++ function
     context evalArgs(... fun: functionObject(_::QualId, _, _, _), args: HOLE:StrictList)

     rule evalArgs(CurrLoc::CabsLoc, Base::SymBase, Fun:K, CallT::CPPType, false, krlist(Args::List))
          => application(CurrLoc, Base, Fun, CallT, CPPLinkage, krlist(Args))

     rule evalArgs(_, _, functionObject(Q::QualId, _, _, _), CallT::CPPType, true, krlist(ListItem(prv(Obj::SymLoc, _, _) #as Arg1::PRVal) Args::List))
          => virtualCall(CallT, computeFinalOverrider(Q, CallT, readBytes(stripProv(Obj), byteSizeofType(type(pointerType(type(void)))), type(pointerType(type(void))))), 
               krlist(ListItem(Arg1) Args))

     syntax Expr ::= virtualCall(CPPType, Expr, StrictList) [strict(2)]
                   | computeFinalOverrider(QualId, CPPType, K) [strict(3)]
                   | #computeFinalOverrider(QualId, CPPType, CPPValue)
                   | getOverrides(Class, CId, CPPType, candidates: List)
     rule <k> computeFinalOverrider(Q::QualId, T::CPPType, dataList(L::List))
              => #computeFinalOverrider(Q, T, joinBytes(L)) ...</k>
          <curr-scope> S::Scope </curr-scope>
          requires notBool isUnderConstructionOrDestruction(S)

     syntax Bool ::= isUnderConstructionOrDestruction(Scope) [function]
     rule isUnderConstructionOrDestruction(blockScope(_ :: ConstructorId(_), _, _)) => true
     rule isUnderConstructionOrDestruction(blockScope(_ :: DestructorId(_), _, _)) => true
     rule isUnderConstructionOrDestruction(_) => false [owise]

     rule #computeFinalOverrider(C::Class :: VF::CId, T::CPPType, encodedValue(vtable(MostDerived::Class), 0, To::Int))
          => getOverrides(C, VF, T, ListItem(MostDerived))

     rule getOverrides(C::Class, _, _, (ListItem(Candidate::Class) => .List) _)
          requires notBool isBaseClassOf(C, Candidate)

     rule <k> getOverrides(C::Class, VF::CId, T::CPPType, (ListItem(Candidate::Class) => Bases) _) ...</k>
          <curr-tu> Tu::String </curr-tu>
          <tu-id> Tu </tu-id>
          <class-id> Candidate </class-id>
          <base-classes> Bases::List </base-classes>
          <cenv>... VF |-> M::Map ...</cenv>
          requires isBaseClassOf(C, Candidate) andBool getOverride(T, M) ==K type(no-type)::CPPType
     rule <k> getOverrides((C::Class => Candidate), VF::CId, (T::CPPType => getOverride(T, M)), (ListItem(Candidate::Class) => .List) _) ...</k>
          <curr-tu> Tu::String </curr-tu>
          <tu-id> Tu </tu-id>
          <class-id> Candidate </class-id>
          <base-classes> Bases::List </base-classes>
          <cenv>... VF |-> M::Map ...</cenv>
          requires isBaseClassOf(C, Candidate) andBool getOverride(T, M) =/=K type(no-type)::CPPType
     rule <k> getOverrides(C::Class, VF::CId, T::CPPType, .List) => lv(lnew(Base), noTrace, T) ...</k>
          <curr-tu> Tu::String </curr-tu>
          <tu-id> Tu </tu-id>
          <class-id> C </class-id>
          <cenv>... VF |-> (_ T::CPPType |-> envEntry(... base: Base::SymBase)) ...</cenv>

     syntax CPPType ::= getOverride(CPPType, Map) [function]
     rule getOverride(BaseClassFunc::CPPType, DerivedClassFunc::CPPType |-> envEntry(Base::SymBase, false, _) _)
          => DerivedClassFunc
          requires overrides(DerivedClassFunc, BaseClassFunc)
     rule getOverride(_, (_ |-> _ => .Map) _) [owise]
     rule getOverride(_, .Map) => type(no-type)

     rule virtualCall(StaticT::CPPType, L:LVal, krlist(Args::List))
          => setType(StaticT, BuiltinCallOp(L, false, Args))

     // Function call (into C++ function)
     rule <k> application(CurrLoc::CabsLoc, Base::SymBase,
                    functionObject(X::QualId, DefT::CPPFunctionType, Params::List, Blk:K),
                    _, CallingLang::LanguageLinkage, krlist(L::List))
              ~> K:K
              => sequencePoint
              ~> enterRestrictBlock(blockScope(X, Base, 0))
              ~> #if Obj ==K .K #then .K #else setThis(& Obj) #fi
              ~> bind(Params, getParams(DefT), L)
              ~> Blk
          </k>
          <call-stack> .List => ListItem(
               <call-stack-frame>
                    <continuation> K:K </continuation>
                    <stack-function-control>
                         <function-control> C 
                              <constructing> Obj </constructing> 
                              <curr-program-loc> CurrLoc </curr-program-loc>
                              <most-derived-class> MDC </most-derived-class>
                         </function-control>
                    </stack-function-control>
                    <stack-lang-linkage> CallingLang </stack-lang-linkage>
               </call-stack-frame>
          ) ...</call-stack>
          (<function-control> C::Bag 
               <constructing> Obj:K </constructing>
               <curr-program-loc> _ </curr-program-loc>
               <most-derived-class> MDC:K </most-derived-class>
          </function-control>
          => <function-control>...
               <curr-tu> getTU(Base) </curr-tu>
               <curr-scope> blockScope(X, Base, 0) </curr-scope>
               <curr-program-loc> CurrLoc </curr-program-loc>
               <most-derived-class> MDC </most-derived-class>
          ...</function-control>)

     rule <k> bindParam(X::CId, T::CPPType, V:Val) => declareNonStaticObject(X, T, 
               Name(NoNNS(), X) := V, 
               Var(CopyInit()), AutoStorage, .Set) ...</k>
          <curr-function-params>... .List => ListItem(X) </curr-function-params>       
          requires notBool isCPPRefType(T)
               andBool X =/=K #NoName
     rule <k> bindParam(X::CId, T::CPPType, V:Val) => declareNonStaticObject(X, T,
               bindReference(Name(NoNNS(), X), V),
               Var(CopyInit()), AutoStorage, .Set) ...</k>
          <curr-function-params>... .List => ListItem(X) </curr-function-params>       
          requires isCPPRefType(T)
               andBool X =/=K #NoName

     rule bindParam(#NoName, T::CPPType, V:Val) => declareNonStaticObject(#NoName, T, V,
               Var(CopyInit()), AutoStorage, .Set)

     // Function call conversion (C linkage)
     rule application(_, _, functionObject(X::CId, _, _, _),
               (T:CPPFunctionType => convertTypeToC(T)), _, krlist(L::List => mapList(L, #klabel(`convertValToC`))))

     syntax RValue ::= convertValToC(PRVal) [function]
     rule convertValToC(prv(V::CPPValue, _, T::CPPType)) => tv({V}:>CValue, utype(convertTypeToC(T)))
          requires isCValue(V)

endmodule
