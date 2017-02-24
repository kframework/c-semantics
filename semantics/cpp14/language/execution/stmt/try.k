module CPP-STMT-TRY
     imports C-CONFIGURATION
     imports K-REFLECTION
     imports C-CHECK-LOC-SYNTAX
     imports C-SEQUENCE-POINT-SYNTAX
     imports CPP-DYNAMIC-SYNTAX
     imports CPP-ERROR-SYNTAX
     imports CPP-SETTINGS-SYNTAX
     imports CPP-STMT-BLOCK-SYNTAX
     imports CPP-SYNTAX
     imports CPP-TYPING-SYNTAX

     rule TryStmt({pushBlock(Tag::Int) ~> Rest:K}:>Block, Catch::List)
          => pushBlock(Tag) ~> enterTryBlock(Catch) ~> Rest ~> tryMark

     syntax KItem ::= enterTryBlock(List)
                    | throw(LVal)

     rule <k> enterTryBlock(Catch::List) => .K ...</k>
          <catch-handlers> _ => Catch </catch-handlers>

     rule <k> ThrowOp(V:LVal) => throw(V) ...</k>
          <uncaught-exception> _ => false </uncaught-exception>

     // if there are still blocks in this function, pop them
     rule <k> (.K => popBlock) ~> throw(_) ...</k>
          <catch-handlers> .List </catch-handlers>
          <block-stack> ListItem(B::K) Blocks::List </block-stack>
          <block-history> ListItem(Num::Int) ...</block-history>
          <call-stack> Funcs::List </call-stack>
          <loop-stack> Loops::List </loop-stack>
          requires canUnwindStack(.List, ListItem(B) Blocks, Funcs)
               andBool canPopBlock(Num, Loops)

     // if we are at the root of a loop, pop it before popping further blocks
     rule <k> throw(_) ~> (_ => K) </k>
          <catch-handlers> .List </catch-handlers>
          <block-stack> ListItem(B::K) Blocks::List </block-stack>
          <block-history> ListItem(Num::Int) ...</block-history>
          <call-stack> Funcs::List </call-stack>
          <loop-stack> ListItem(kpair(Num, K:K)) => .List ...</loop-stack>
          requires canUnwindStack(.List, ListItem(B) Blocks, Funcs)

     // if there are still functions in the stack trace, pop them
     rule <k> (.K => unwindFunction) ~> throw(_) ...</k> 
          <catch-handlers> .List </catch-handlers>
          <block-stack> .List </block-stack>
          <call-stack> ListItem(F::K) Funcs::List </call-stack>
          requires canUnwindStack(.List, .List, ListItem(F) Funcs)

     // handles calling terminate on uncaught exception for implementations
     // which unwind the stack first
     rule <k> (.K => callTerminate) ~> throw(_) ...</k>
          <catch-handlers> .List </catch-handlers>
          <block-stack> .List </block-stack>
          <call-stack> .List </call-stack>
          requires canUnwindStack(.List, .List, .List)

     // handles calling terminate on uncaught exception for implementations
     // which don't unwind the stack first
     rule <k> (.K => callTerminate) ~> throw(_) ...</k>
          <catch-handlers> Catchs::List </catch-handlers>
          <block-stack> Blocks::List </block-stack>
          <call-stack> Funcs::List </call-stack>
          requires notBool canUnwindStack(Catchs, Blocks, Funcs)

     syntax KItem ::= "unwindFunction" | "tryMark"

     // delete locals when function body is not wrapped in Block
     rule <k> (.K => deleteLocals) ~> unwindFunction ...</k>
          <block-stack> .List </block-stack>
          <local-addresses> S::Set </local-addresses>
          requires size(S) >Int 0

     rule <k> unwindFunction ~> throw(V::LVal) ~> _ 
              => exitRestrictScope(Scope)
              ~> sequencePoint
              ~> throw(V)
              ~> K
          </k>
          (<function-control>
               <curr-scope> Scope::BlockScope </curr-scope>
               <live-va-lists> .Set </live-va-lists>
               <block-control>...
                    <local-addresses> .Set </local-addresses>
               ...</block-control>
               <block-stack> .List </block-stack>
          ...</function-control> => <function-control>
               C
               <uncaught-exception> false </uncaught-exception>
          ...</function-control>)
          <call-stack>
               ListItem(
                    <call-stack-frame>
                         <continuation> K:K </continuation>
                         <stack-function-control>
                              <function-control>
                                   C::Bag
                                   <uncaught-exception> true </uncaught-exception>
                              </function-control>
                         </stack-function-control>
                         <stack-lang-linkage> CPPLinkage </stack-lang-linkage>
                    </call-stack-frame>
               ) => .List
          ...</call-stack>

     rule <k> (.K => UNDEF("EST1", "Thrown exception unwound into non-C++ function."))
              ~> unwindFunction ...</k>
          <call-stack>
               ListItem(
                    <call-stack-frame>...
                         <stack-lang-linkage> CLinkage </stack-lang-linkage>
                    ...</call-stack-frame>
               )
          </call-stack>

     rule <k> (.K => UNDEF("EST2", "Thrown exception unwound out of varargs function without calling va_end."))
              ~> unwindFunction ...</k>
          <live-va-lists> S::Set </live-va-lists>
          requires size(S) >Int 0

     // call terminate when unwinding into a stack frame which is already throwing an exception
     rule <k> (.K => callTerminate)
              ~> unwindFunction ...</k>
          <call-stack>
               ListItem(
                    <call-stack-frame>...
                         <stack-function-control> <function-control>...
                              <uncaught-exception> false </uncaught-exception>
                         ...</function-control> </stack-function-control>
                    ...</call-stack-frame>
               )
          ...</call-stack>

     rule <k> throw(_) => catchWithHandler(CatchAnyStmt(S)) ...</k>
          <catch-handlers> ListItem(CatchAnyStmt(S::Stmt)) _ </catch-handlers>

     syntax KItem ::= catchWithHandler(Stmt)

     rule <k> catchWithHandler(CatchAnyStmt(S::Stmt)) ~> tryMark => popBlock ~> S ...</k>
          <uncaught-exception> _ => true </uncaught-exception>

     rule tryMark => .K

     rule catchWithHandler(_) ~> (K:KItem => .K)
          requires getKLabel(K) =/=K #klabel(`tryMark_CPP-STMT-TRY`)

     syntax Expr ::= "callTerminate"
     rule <k> callTerminate => BuiltinCallOp(lv(loc(obj(0, 0, builtinSymbol("std::terminate (void)")), 0), noTrace, type(functionType(type(void), .CPPTypeExprs, RefNone(), noQuals, CLinkage, noexcept(false)))), .List) ...</k>
          <uncaught-exception> _ => true </uncaught-exception>

     syntax Bool ::= canUnwindStack(List, List, List) [function]
                   | canCatchException(List, List, List) [function]
                   | canPopBlock(Int, List) [function]
     rule canUnwindStack(Catchs::List, Blocks::List, Funcs::List)
          => cfg:unwindBeforeTerminate orBool canCatchException(Catchs, Blocks, Funcs)

     rule canCatchException((.List => L) _, (ListItem(<block-control>... <catch-handlers> L::List </catch-handlers> ...</block-control>) => .List) _, _)
     rule canCatchException((.List => L2) _, (.List => L) _, (ListItem(<call-stack-frame>... <stack-function-control> <function-control>... <block-stack> L::List </block-stack> <catch-handlers> L2::List </catch-handlers> ...</function-control> </stack-function-control> ...</call-stack-frame>) => .List) _)

     rule canCatchException(ListItem(CatchAnyStmt(_)) _, _, _) => true
     rule canCatchException(.List, .List, .List) => false

     rule canPopBlock(Num::Int, ListItem(kpair(Num, _)) _) => false
     rule canPopBlock(_, _) => true [owise]

endmodule
