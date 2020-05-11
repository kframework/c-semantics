module CPP-STMT-RETURN-SYNTAX
     imports BASIC-K
     syntax KItem ::= "Return''" "(" KItem ")" [strict(c)]
endmodule

module CPP-EXECUTION-STMT-RETURN
     imports RETURN-SYNTAX
     imports CPP-STMT-RETURN-SYNTAX
     imports C-CONFIGURATION
     imports BOOL
     imports C-CHECK-RESTRICT-SYNTAX
     imports DELETE-OBJECT-SYNTAX
     imports C-SEQUENCE-POINT-SYNTAX
     imports CPP-BITSIZE-SYNTAX
     imports CPP-DYNAMIC-SYNTAX
     imports CPP-EXECUTION-ENV-SYNTAX
     imports CPP-EXECUTION-FULL-EXPRESSION-SYNTAX
     imports CPP-EXECUTION-STMT-BLOCK-SYNTAX
     imports CPP-MEMORY-ALLOC-SYNTAX
     imports CPP-REFERENCE-SYNTAX
     imports CPP-SYNTAX
     imports CPP-TYPING-SYNTAX

     // Return (from C++ function)
     rule <k> ReturnOp(V::Expr, Obj::Expr) => prepareReturn(getReturnType(T), V, Obj) ...</k>
          <curr-scope> blockScope(_, Base::SymBase, _) </curr-scope>
          <functions>... Base |-> functionObject(_, T::CPPType, _, _) ...</functions>

     syntax KItem ::= prepareReturn(CPPType, K, KItem)

     context prepareReturn(_, _, HOLE:Expr) [result(LV)]

     rule <k> prepareReturn(T::CPPType, Init:KItem, Obj:LV)
          => Return'(Init, T)
          ...</k>
          <ret-constructed-temporary>
               .K => lcentry(Obj, false, true, false)
          </ret-constructed-temporary>
          requires notBool isCPPVoidType(T)

     rule prepareReturn(t(... st: void) #as T::CPPType, V:PRVal, _) => Return''(V)

     syntax KItem ::= "Return'" "(" KItem "," CPPType ")" [strict(c; 1)]

     rule Return'(referenceBindingResult(V::Val) => V, _)

     // compute value category of result
     rule Return'(lv(Loc::SymLoc, Tr::Trace, T::CPPType), DeclT::CPPType) =>
          Return''(makeCall2(Loc, Tr, T, DeclT))

     syntax Expr ::= makeCall2(SymLoc, Trace, CPPType, CPPType) [function]

     rule makeCall2(Loc::SymLoc, Tr::Trace, T::CPPType, DeclT::CPPType)
          => lv(Loc, Tr, T)
          requires isUnnamedLValue(DeclT)

     rule makeCall2(Loc::SymLoc, Tr::Trace, T::CPPType, DeclT::CPPType)
          => xv(Loc, Tr, T)
          requires isUnnamedXValue(DeclT)

     rule makeCall2(Loc::SymLoc, Tr::Trace, T::CPPType, DeclT::CPPType)
          => makePRVal(lv(Loc, Tr, T)) [owise]

     /* recursively exits each Block wrapped in BlockStatement */
     rule <k> (.K => popBlock(false)) ~> Return''(_:Val) ...</k>
          <block-history> ListItem(_) ...</block-history>
          <block-stack> ListItem(_) ...</block-stack>

     rule <k> Return''(V:Val) => fullExpression ~> destructLocals(false) ~> return(V) ...</k>
          <block-history> .List </block-history>
          <block-stack> .List </block-stack>

     // Return (to C++ function)
     rule <k> return(V:Val) ~> _
              => exitRestrictBlock(.Set)
              ~> addToCT(LCE)
              ~> sequencePoint
              ~> V
              ~> K
          </k>
          (<function-control>
               <live-va-lists> .Set </live-va-lists>
               <block-stack> .List </block-stack>
               <ret-constructed-temporary> LCE::K  </ret-constructed-temporary>
          ...</function-control> => C)
          <call-stack>
               ListItem(
                    <call-stack-frame>
                         <continuation> K:K </continuation>
                         <stack-function-control>
                              C:FunctionControlCell
                         </stack-function-control>
                         <stack-lang-linkage> CPPLinkage </stack-lang-linkage>
                    </call-stack-frame>
               ) => .List
          ...</call-stack>

     syntax KItem ::= addToCT(K)

     rule addToCT(.K) => .K

     rule <k> addToCT(lcentry(Obj::LV, _, _, _)) => .K ...</k>
          <constructed-temporaries> .List =>
               ListItem(lcentry(Obj, true, true, false))
          ...</constructed-temporaries>


endmodule
