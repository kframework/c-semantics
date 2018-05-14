module CPP-STMT-RETURN-SYNTAX
     imports BASIC-K
     syntax KItem ::= "Return''" "(" K ")" [strict]
endmodule

module CPP-STMT-RETURN
     imports RETURN-SYNTAX
     imports CPP-STMT-RETURN-SYNTAX
     imports C-CONFIGURATION
     imports BOOL
     imports C-CHECK-RESTRICT-SYNTAX
     imports C-IO-SYNTAX
     imports C-SEQUENCE-POINT-SYNTAX
     imports CPP-BITSIZE-SYNTAX
     imports CPP-DYNAMIC-SYNTAX
     imports CPP-ENV-SYNTAX
     imports CPP-MEMORY-ALLOC-SYNTAX
     imports CPP-SYNTAX
     imports CPP-TYPING-SYNTAX

     // Return (from C++ function)
     rule <k> ReturnOp(V::Expr) => prepareReturn(getReturnType(T), V) ...</k>
          <curr-scope> blockScope(_, Base::SymBase, _) </curr-scope>
          <functions>... Base |-> functionObject(_, T::CPPFunctionType, _, _) ...</functions>

     syntax KItem ::= prepareReturn(CPPType, K)

     rule prepareReturn(T::CPPType, Init:K)
          => Return'(Init, T)
          requires notBool isCPPVoidType(T)

     rule prepareReturn(T:CPPVoidType, V:PRVal) => Return''(V)

     syntax KItem ::= "Return'" "(" K "," CPPType ")" [strict(1)]

     // compute value category of result
     rule Return'(lv(Loc::SymLoc, Tr::Trace, T::CPPType), DeclT::CPPType) => 
          Return''(makeCall(Loc, Tr, T, DeclT))

     syntax Val ::= makeCall(SymLoc, Trace, CPPType, CPPType) [function]
     rule makeCall(Loc::SymLoc, Tr::Trace, T::CPPType, DeclT::CPPType)
          => lv(Loc, Tr, T)
          requires isUnnamedLValue(DeclT)
     rule makeCall(Loc::SymLoc, Tr::Trace, T::CPPType, DeclT::CPPType)
          => xv(Loc, Tr, T)
          requires isUnnamedXValue(DeclT)
     rule makeCall(Loc::SymLoc, Tr::Trace, T::CPPType, DeclT::CPPType)
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

module C-CPP-STMT-RETURN
     imports CPP-STMT-RETURN
     imports C-DYNAMIC-SYNTAX
     imports C-TYPING-SYNTAX

     rule <k> return(V:RValue => convertValToCPP(V)) ...</k>
          <call-stack>
               ListItem(
                    <call-stack-frame>...
                         <stack-lang-linkage> CPPLinkage </stack-lang-linkage>
                    ...</call-stack-frame>
               )
          ...</call-stack>

     syntax PRVal ::= convertValToCPP(RValue) [function]
     rule convertValToCPP(tv(V::CValue, T::UType)) => prv({V}:>CPPValue, noTrace, convertTypeToCPP(type(T)))
          requires isCPPValue(V)
     rule convertValToCPP(voidVal) => prv(voidVal, noTrace, type(void))

endmodule
