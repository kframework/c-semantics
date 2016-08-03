module CPP-STMT-RETURN
     imports RETURN-SYNTAX
     imports C-CHECK-LOC-SYNTAX
     imports C-CONFIGURATION
     imports CPP-BITSIZE-SYNTAX
     imports CPP-DYNAMIC-SYNTAX
     imports CPP-ENV-SYNTAX
     imports CPP-MEMORY-ALLOC-SYNTAX
     imports CPP-STMT-BLOCK-SYNTAX
     imports CPP-SYNTAX
     imports CPP-TYPING-SYNTAX

     // Return (from C++ function)
     rule <k> ReturnOp(Init:K) => prepareReturn(getReturnType(T), Init) ...</k>
          <curr-scope> blockScope(_, Base::SymBase, _) </curr-scope>
          <functions>... Base |-> functionObject(_, T::CPPFunctionType, _, _) ...</functions>

     syntax KItem ::= prepareReturn(CPPType, K)

     rule <k> prepareReturn(T::CPPType, Init:K)
              => allocObject(!I:Int @ D, T, byteSizeofType(T))
              ~> addToEnv(ret, T, !I @ D, false)
              ~> allowInit(Init)
              ~> Return'(Name(NoNNS(), ret))
          ...</k>
          <duration> D::Duration </duration>
          <local-addresses>... .Set => SetItem(!I @ D) ...</local-addresses>

     syntax KItem ::= "Return'" "(" K ")"
     context Return'(HOLE:Expr => reval(HOLE)) [result(PRVal)]

     /* recursively exits each Block wrapped in BlockStatement */
     rule <k> (.K => popBlock) ~> Return'(_:PRVal) ...</k>
          <block-history> ListItem(_) ...</block-history>
          <block-stack> ListItem(_) ...</block-stack>

     rule <k> Return'(V:PRVal) => deleteLocals ~> return(V) ...</k>
          <block-history> .List </block-history>
          <block-stack> .List </block-stack>

     // Return (to C++ function)
     rule <k> return(V:PRVal) ~> _
              => exitRestrictScope(Scope)
              ~> V
              ~> K
          </k>
          (<function-control>
               <curr-scope> Scope::BlockScope </curr-scope>
               <live-va-lists> .Set </live-va-lists>
               <block-control>...
                    <local-addresses> .Set </local-addresses>
               ...</block-control>
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
     rule convertValToCPP(tv(V::CValue, T::UType)) => prv({V}:>CPPValue, convertTypeToCPP(type(T)))
          requires isCPPValue(V)

endmodule
