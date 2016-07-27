module CPP-EXPR-FUNCTION-CALL
     imports FUNCTION-CALL-SYNTAX
     imports C-CHECK-LOC-SYNTAX
     imports C-DYNAMIC-SYNTAX
     imports C-SEQUENCE-POINT-SYNTAX
     imports C-TYPING-COMMON-SYNTAX
     imports C-CONFIGURATION
     imports CPP-BINDING-SYNTAX
     imports CPP-BITSIZE-SYNTAX
     imports CPP-ENV-SYNTAX
     imports CPP-MEMORY-ALLOC-SYNTAX
     imports CPP-TYPING-SYNTAX

     // Function call (from C++ function)
     rule BuiltinCallOp(lv((loc(Base::SymBase, Offset::Int, _) => loc(Base, Offset)), _), _, _)
     rule <k> BuiltinCallOp(lv(loc((Base::SymBase => Base'), _), _), _, _) ...</k>
          <linkings>... Base |-> Base'::SymBase ...</linkings>

     rule <k> BuiltinCallOp(lv(loc(Base::SymBase, 0), T:CPPFunctionType), N::Int, Init::K)
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

     rule <k> (.K => allocObject(!I:Int @ D, T, byteSizeofType(T))
                  ~> addToEnv(arg(I), T, !I @ D, false))
              ~> makeArgumentTemporaries(NArgs::Int, (I::Int => I +Int 1), t(_, _, functionType(_, (ListItem(T::CPPType) => .List) _, _)))
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
                    functionObject(X::QualId, DefT::CPPFunctionType, Locals::List, Blk:K),
                    CallT:CPPFunctionType, CallingLang::LanguageLinkage, krlist(L::List))
              ~> K:K
              => sequencePoint
              ~> enterRestrictScope(blockScope(X, Base, 0))
              ~> bind(getParams(DefT), getParams(CallT), L, 0)
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

     // Function call conversion (C linkage)
     rule application(_, _, functionObject(X::CId, _, _, _),
               (T:CPPFunctionType => convertTypeToC(T)), _, krlist(L::List => mapList(L, #klabel(`convertValToC`))))

     syntax RValue ::= convertValToC(PRVal) [function]
     rule convertValToC(prv(V::CPPValue, T::CPPType)) => tv(V:>CValue, utype(convertTypeToC(T)))
          requires isCValue(V)

endmodule
