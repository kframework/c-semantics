module CPP-EXECUTION-EXPR-FUNCTION-CALL
     imports FUNCTION-CALL-SYNTAX
     imports C-CONFIGURATION
     imports INT
     imports BITS-SYNTAX
     imports SYMLOC-SYNTAX
     imports C-CHECK-RESTRICT-SYNTAX
     imports C-SEQUENCE-POINT-SYNTAX
     imports C-TYPING-COMMON-SYNTAX
     imports C-TYPING-SYNTAX
     imports CPP-BINDING-SYNTAX
     imports CPP-BITSIZE-SYNTAX
     imports CPP-DYNAMIC-SYNTAX
     imports CPP-EXECUTION-ENV-SYNTAX
     imports CPP-MEMORY-ALLOC-SYNTAX
     imports CPP-MEMORY-READING-SYNTAX
     imports CPP-REFERENCE-SYNTAX
     imports CPP-SYNTAX
     imports CPP-TYPE-MAP-SYNTAX
     imports CPP-TYPING-SYNTAX
     imports CPP-EXPR-MEMBERS-SYNTAX

     rule BuiltinCallOp(lv(_, _, t(... st: pointerType(...)) #as T::CPPType) #as L::LVal => * L, false, _)
          requires isCPPFunctionType(innerType(T))

     context BuiltinCallOp((* _) #as HOLE:Expr, false, _)
          requires Execution()

     // Function call (from C++ function)
     rule BuiltinCallOp(lv((loc(Base::SymBase, Offset::Int, _) => loc(Base, Offset)), _, t(... st: functionType(...))), _, _)

     rule <k> BuiltinCallOp(lv(loc((Base::SymBase => Base'), _), _, t(... st: functionType(...))), _, _) ...</k>
          <linkings>... Base |-> Base'::SymBase ...</linkings>

     rule <k> BuiltinCallOp(lv(loc(Base::SymBase, 0), _, t(... st: functionType(...)) #as T::CPPType), IsVirtual:Bool, Args::List)
              => prepareArguments(CurrLoc, Base, Fun, T, CPPLinkage, IsVirtual, Args)
          ...</k>
          <functions>... Base |-> Fun:KItem ...</functions>
          <curr-program-loc> CurrLoc::CabsLoc </curr-program-loc>
          requires isDirectBase(Base) orBool (isMethodPure(T) andBool IsVirtual)

     rule <k> BuiltinCallOp(lv(loc(obj(0, Align::Int, nativeSymbol(S::String)) #as Base::SymBase, _), _, t(... st: functionType(...)) #as T::CPPType), IsVirtual:Bool, Args::List)
              => prepareArguments(CurrLoc, obj(0, Align, nativeSymbol(S)), functionObject(Identifier(S), CType, .List, .Map), T, CLinkage, IsVirtual, Args)
          ...</k>
          <external-types>... Identifier(S) |-> CType::Type ...</external-types>
          <curr-program-loc> CurrLoc::CabsLoc </curr-program-loc>

     syntax Expr ::= prepareArguments(CabsLoc, SymBase, KItem, EffectiveType, LanguageLinkage, Bool, List)

     rule prepareArguments(CurrLoc::CabsLoc, Base::SymBase, Fun::KItem, CallT::EffectiveType, Linkage::LanguageLinkage, IsVirtual::Bool, Args::List)
          => evalArgs(CurrLoc, Base, Fun, CallT, Linkage, IsVirtual, list(Args))

     syntax Expr ::= evalArgs(CabsLoc, SymBase, fun: KItem, EffectiveType, LanguageLinkage, Bool, args: StrictList)

     // evaluating arguments for call to C function
     context evalArgs(... fun: functionObject(_::CId, _, _, _), args: HOLE:StrictList => prval(HOLE))

     // evaluating arguments for call to C++ function
     context evalArgs(... fun: functionObject(_::QualId, _, _, _), args: HOLE:StrictList)

     rule evalArgs(CurrLoc::CabsLoc, Base::SymBase, Fun::KItem, CallT::EffectiveType, Linkage::LanguageLinkage, false, krlist(Args::List))
          => application(CurrLoc, Base, Fun, CallT, Linkage, krlist(Args))

     rule evalArgs(_, _, functionObject(Q::QualId, _, _, _), CallT::CPPType, _, true, krlist(ListItem(prv(Obj::SymLoc, _, _) #as Arg1::PRVal) Args::List))
          => virtualCall(CallT, computeFinalOverrider(Q, CallT, readBytes(stripProv(Obj), byteSizeofType(type(pointerType(type(void)))), type(pointerType(type(void))))),
               krlist(ListItem(Arg1) Args))

     syntax Expr ::= virtualCall(CPPType, Expr, StrictList) [strict(c; 2)]
                   | computeFinalOverrider(QualId, CPPType, KItem) [strict(3)]
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

     rule #computeFinalOverrider(C::Class :: VF::CId, T::CPPType, encodedPtr(vtable(MostDerived::Class), 0, To::Int))
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
          <cenv>... VF |-> (_::Map stripType(T::CPPType) |-> (_, envEntry(... base: Base::SymBase))) ...</cenv>

     syntax CPPType ::= getOverride(CPPType, Map) [function]

     rule getOverride(BaseClassFunc::CPPType, _::CPPType |-> (DerivedClassFunc::CPPType, envEntry(Base::SymBase, false, _)) _)
          => DerivedClassFunc
          requires overrides(DerivedClassFunc, BaseClassFunc)

     rule getOverride(_, (_ |-> _ => .Map) _) [owise]

     rule getOverride(_, .Map) => type(no-type)::CPPType

     rule virtualCall(StaticT::CPPType, L:LVal, krlist(Args::List))
          => setType(#fun(Ret::CPPType => #if isCPPRefType(Ret) #then innerType(Ret) #else Ret #fi)(getReturnType(StaticT)), BuiltinCallOp(L, false, Args))

     // Function call (into C++ function)
     rule <k> application(CurrLoc::CabsLoc, Base::SymBase,
                    functionObject(X::QualId, DefT::CPPType, Params::List, Blk:K),
                    _, CallingLang::LanguageLinkage, krlist(L::List))
              ~> K:K
              => sequencePoint
              ~> enterRestrictBlock(blockScope(X, Base, 0))
              ~> #if Obj ==K .K #then .K #else setThis(& {Obj}:>Expr) #fi
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

     syntax SymBase ::= getBaseOfVal(Val) [function]

     rule getBaseOfVal(lv(...v: L::SymLoc) #Or xv(...v: L::SymLoc) #Or prv(...v: L::SymLoc))
          => base(L)

     rule getBaseOfVal(referenceBindingResult(V::Val))
          => getBaseOfVal(V)

     rule <k> bindParam(X::CId, T::CPPType, V:Val)
              => addToExecEnv(X, T, getBaseOfVal(V), false)
           ...</k>
          <curr-function-params>... .List => ListItem(X) </curr-function-params>
          requires X =/=K #NoName

     rule bindParam(#NoName, T::CPPType, V:Val) => declareNonStaticObjectExec(#NoName, T, V,
               Var(CopyInit()), AutoStorage, .Set)

endmodule
