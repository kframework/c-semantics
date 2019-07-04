module CPP-STMT-RETURN-SYNTAX
     imports BASIC-K
     syntax KItem ::= "Return''" "(" K ")" [strict(c)]
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
     imports CPP-MEMORY-ALLOC-SYNTAX
     imports CPP-REFERENCE-SYNTAX
     imports CPP-SYNTAX
     imports CPP-TYPING-SYNTAX

     // Return (from C++ function)
     rule <k> ReturnOp(V::Expr) => prepareReturn(getReturnType(T), V) ...</k>
          <curr-scope> blockScope(_, Base::SymBase, _) </curr-scope>
          <functions>... Base |-> functionObject(_, T::CPPType, _, _) ...</functions>

     syntax KItem ::= prepareReturn(CPPType, K)

     rule prepareReturn(T::CPPType, Init:K)
          => Return'(Init, T)
          requires notBool isCPPVoidType(T)

     rule prepareReturn(t(... st: void) #as T::CPPType, V:PRVal) => Return''(V)

     syntax KItem ::= "Return'" "(" K "," CPPType ")" [strict(c; 1)]

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
     rule <k> (.K => popBlock) ~> Return''(_:Val) ...</k>
          <block-history> ListItem(_) ...</block-history>
          <block-stack> ListItem(_) ...</block-stack>

     rule <k> Return''(V:Val) => fullExpression ~> destructLocals(false) ~> deleteObjects(Locals) ~> return(V) ...</k>
          <local-addresses> Locals::Set </local-addresses>
          <block-history> .List </block-history>
          <block-stack> .List </block-stack>

     // Return (to C++ function)
     rule <k> return(V:Val) ~> _
              => exitRestrictBlock(.Set)
              ~> sequencePoint
              ~> V
              ~> K
          </k>
          (<function-control>
               <live-va-lists> .Set </live-va-lists>
               <block-stack> .List </block-stack>
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

endmodule
