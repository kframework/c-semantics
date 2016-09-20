module CPP-EXPR-FUNCTION-CALL
     imports FUNCTION-CALL-SYNTAX
     imports C-CONFIGURATION
     imports INT
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
     imports CPP-SYNTAX
     imports CPP-TYPING-SYNTAX

     // Function call (from C++ function)
     rule BuiltinCallOp(lv((loc(Base::SymBase, Offset::Int, _) => loc(Base, Offset)), _, _), _, _)
     rule <k> BuiltinCallOp(lv(loc((Base::SymBase => Base'), _), _, _), _, _) ...</k>
          <linkings>... Base |-> Base'::SymBase ...</linkings>

     rule <k> BuiltinCallOp(lv(loc(Base::SymBase, 0), _, T:CPPFunctionType), N::Int, Init::K)
              => prepareArguments(CurrLoc, Base, Fun, T, N, Init)
          ...</k>
          <functions>... Base |-> Fun:K ...</functions>
          <curr-program-loc> CurrLoc::CabsLoc </curr-program-loc>
          requires notBool isLinkerLoc(Base)

     syntax Expr ::= prepareArguments(CabsLoc, SymBase, K, CPPType, Int, K)

     rule prepareArguments(CurrLoc::CabsLoc, Base::SymBase, Fun:K, CallT::CPPType, N::Int, Init::K)
          => makeArgumentTemporaries(N, 0, CallT)
          ~> allowInit(Init)
          ~> application(CurrLoc, Base, Fun, CallT, CPPLinkage, list(readArgumentTemporaries(N)))

     // evaluating arguments for call to C function
     context application(_, _, functionObject(_::CId, _, _, _), _, _, HOLE:StrictList => prval(HOLE))
     // evaluating arguments for call to C++ function
     context application(_, _, functionObject(_::QualId, _, _, _), _, _, HOLE:StrictList)

     syntax KItem ::= makeArgumentTemporaries(Int, Int, CPPType)
     syntax List ::= readArgumentTemporaries(Int) [function]

     rule <k> (.K => #if notBool isCPPRefType(T) #then allocObject(!I:Int @ D, T, byteSizeofType(T)) #else .K #fi
                  ~> addToEnv(arg(I), T, !I @ D, false))
              ~> makeArgumentTemporaries(NArgs::Int, (I::Int => I +Int 1), t(_, _, functionType(_, (T::CPPType, Ts::CPPTypes => Ts), _)))
          ...</k>
          <duration> D::Duration </duration>
          <local-addresses>... .Set => SetItem(!I @ D) ...</local-addresses>
          requires I =/=Int NArgs
     rule makeArgumentTemporaries(I::Int, I::Int, _) => .K

     rule readArgumentTemporaries(I::Int) => readArgumentTemporaries(I -Int 1) ListItem(Name(NoNNS(), arg(I -Int 1)))
          requires I >Int 0
     rule readArgumentTemporaries(0) => .List

     // Function call (into C++ function)
     rule <k> application(CurrLoc::CabsLoc, Base::SymBase,
                    functionObject(X::QualId, DefT::CPPFunctionType, Params::List, Blk:K),
                    _, CallingLang::LanguageLinkage, krlist(L::List))
              ~> K:K
              => sequencePoint
              ~> enterRestrictScope(blockScope(X, Base, 0))
              ~> bind(Params, getParams(DefT), L)
              ~> Blk
          </k>
          <call-stack> .List => ListItem(
               <call-stack-frame>
                    <continuation> K:K </continuation>
                    <stack-function-control>
                         C
                    </stack-function-control>
                    <stack-lang-linkage> CallingLang </stack-lang-linkage>
               </call-stack-frame>
          ) ...</call-stack>
          (C:FunctionControlCell
          => <function-control>...
               <curr-tu> getTU(loc(Base, 0)) </curr-tu>
               <curr-scope> blockScope(X, Base, 0) </curr-scope>
               <curr-program-loc> CurrLoc </curr-program-loc>
          ...</function-control>)

     rule bindParam(X::CId, T::CPPType, V:Val) => declareNonStaticObject(X, T, 
               initValue(le(Name(NoNNS(), X), hasTrace(Name(NoNNS(), X)), T), T, ExpressionStmt(Name(NoNNS(), X) := V)), 
               Var, AutoStorage, .Set)
          requires notBool isCPPRefType(T)
     rule bindParam(X::CId, T::CPPType, V:Val) => declareNonStaticObject(X, T,
               initValue(le(Name(NoNNS(), X), hasTrace(Name(NoNNS(), X)), T), T, bindReference(Name(NoNNS(), X), V)),
               Var, AutoStorage, .Set)
          requires isCPPRefType(T)

     // Function call conversion (C linkage)
     rule application(_, _, functionObject(X::CId, _, _, _),
               (T:CPPFunctionType => convertTypeToC(T)), _, krlist(L::List => mapList(L, #klabel(`convertValToC`))))

     syntax RValue ::= convertValToC(PRVal) [function]
     rule convertValToC(prv(V::CPPValue, _, T::CPPType)) => tv({V}:>CValue, utype(convertTypeToC(T)))
          requires isCValue(V)

endmodule
