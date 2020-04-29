module CPP-EXECUTION-STMT-TRY
     imports C-CONFIGURATION
     imports K-REFLECTION
     imports C-CHECK-RESTRICT-SYNTAX
     imports DELETE-OBJECT-SYNTAX
     imports C-SEQUENCE-POINT-SYNTAX
     imports CPP-CONVERSION-SYNTAX
     imports CPP-DYNAMIC-SYNTAX
     imports CPP-EXECUTION-ENV-SYNTAX
     imports CPP-EXECUTION-STMT-BLOCK-SYNTAX
     imports CPP-EXECUTION-TEMPORARY-SYNTAX
     imports CPP-ERROR-SYNTAX
     imports CPP-SETTINGS-SYNTAX
     imports CPP-SYNTAX
     imports CPP-TYPING-SYNTAX

     rule TryStmt(pushBlock(Tag::Int) ~> Rest:K, Catch::List)
          => pushBlock(Tag) ~> enterTryBlock(Catch) ~> Rest ~> tryMark(Tag)

     syntax KItem ::= enterTryBlock(List)
                    | throw(LVal)

     rule <k> enterTryBlock(Catch::List) => .K ...</k>
          <catch-handlers> _ => Catch </catch-handlers>

     rule <k> ThrowOp(V:LVal) => throw(V) ...</k>
          <uncaught-exception> _ => true </uncaught-exception>

     rule <k> (.K => destructLocal(true, LCE)) ~> throw(V::LVal) ...</k>
          <catch-handlers> .List </catch-handlers>
          <ret-constructed-temporary> lcentry(...) #as LCE::KItem => .K </ret-constructed-temporary>
          requires canUnwindStack(V)

     rule <k> (.K => destructTemporaries(true)) ~> throw(V::LVal) ...</k>
          <catch-handlers> .List </catch-handlers>
          <ret-constructed-temporary> .K </ret-constructed-temporary>
          <constructed-temporaries> ListItem(_) _ </constructed-temporaries>
          requires canUnwindStack(V)

     // if there are still blocks in this function, pop them
     rule <k> (.K => popBlock(true)) ~> throw(V::LVal) ...</k>
          <catch-handlers> .List </catch-handlers>
          <ret-constructed-temporary> .K </ret-constructed-temporary>
          <constructed-temporaries> .List </constructed-temporaries>
          <block-stack> ListItem(_) _ </block-stack>
          <block-history> ListItem(Num::Int) ...</block-history>
          <loop-stack> Loops::List </loop-stack>
          requires canUnwindStack(V)
               andBool canPopBlock(Num, Loops)

     // if we are at the root of a loop, pop it before popping further blocks
     rule <k> throw(V::LVal) ~> (_ => K) </k>
          <catch-handlers> .List </catch-handlers>
          <ret-constructed-temporary> .K </ret-constructed-temporary>
          <constructed-temporaries> .List </constructed-temporaries>
          <block-stack> ListItem(_) _ </block-stack>
          <block-history> ListItem(Num::Int) ...</block-history>
          <loop-stack> ListItem(kpair(Num, K:K)) => .List ...</loop-stack>
          requires canUnwindStack(V)

     // if there are still functions in the stack trace, pop them
     rule <k> (.K => unwindFunction) ~> throw(V::LVal) ...</k>
          <catch-handlers> .List </catch-handlers>
          <ret-constructed-temporary> .K </ret-constructed-temporary>
          <constructed-temporaries> .List </constructed-temporaries>
          <block-stack> .List </block-stack>
          <call-stack> ListItem(_) _ </call-stack>
          requires canUnwindStack(V)

     // handles calling terminate on uncaught exception or when an exception
     // cannot safely be thrown
     rule (.K => catchAndCallTerminate) ~> throw(V::LVal)
          requires notBool canUnwindStack(V)

     syntax Bool ::= canUnwindStack(LVal) [function]

     rule [[ canUnwindStack(V::LVal) => #canUnwindStack(Catchs, Blocks, Funcs, type(V)) ]]
          <catch-handlers> Catchs::List </catch-handlers>
          <block-stack> Blocks::List </block-stack>
          <call-stack> Funcs::List </call-stack>

     syntax KItem ::= "unwindFunction" | tryMark(Int)

     // delete locals when function body is not wrapped in Block
     rule <k> (.K => destructLocals(true)) ~> unwindFunction ...</k>
          <block-stack> .List </block-stack>
          <locally-constructed> L::List </locally-constructed>
          requires size(L) >Int 0

     rule <k> unwindFunction ~> throw(V::LVal) ~> _
              => exitRestrictBlock(.Set)
              ~> sequencePoint
              ~> throw(V)
              ~> K
          </k>
          (<function-control>
               <curr-scope> blockScope(_, Base::SymBase, _) </curr-scope>
               <live-va-lists> .Set </live-va-lists>
               <block-control>...
                    <locally-constructed> .List </locally-constructed>
               ...</block-control>
               <block-stack> .List </block-stack>
          ...</function-control> => <function-control>
               C
               <uncaught-exception> true </uncaught-exception>
          ...</function-control>)
          <call-stack>
               ListItem(
                    <call-stack-frame>
                         <continuation> K:K </continuation>
                         <stack-function-control>
                              <function-control>
                                   C::Bag
                                   <uncaught-exception> false </uncaught-exception>
                              </function-control>
                         </stack-function-control>
                         <stack-lang-linkage> CPPLinkage </stack-lang-linkage>
                    </call-stack-frame>
               ) => .List
          ...</call-stack>
          <functions>... Base |-> functionObject(_, FuncT::CPPType, _, _) ...</functions>
          requires canThrowException(FuncT, type(V))

     rule <k> (.K => catchAndCallTerminate) ~> unwindFunction ~> throw(V::LVal) ...</k>
          <curr-scope> blockScope(_, Base::SymBase, _) </curr-scope>
          <functions>... Base |-> functionObject(_, FuncT::CPPType, _, _) ...</functions>
          <locally-constructed> .List </locally-constructed>
          requires notBool canThrowException(FuncT, type(V)) andBool notBool isDynamicExceptionSpec(FuncT)

     // TODO(dwightguth): call std::unexpected if isDynamicExceptionSpec

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

     rule <k> throw(V::LVal) => catchWithHandler(CatchAnyOp(S), V) ...</k>
          <catch-handlers> ListItem(CatchAnyOp(S::K)) ...</catch-handlers>

     rule <k> throw(V::LVal) => catchWithHandler(CatchOp(T, S), V) ...</k>
          <catch-handlers> ListItem(CatchOp(T::CPPType, S::K)) ...</catch-handlers>
          requires handlerMatches(T, type(V))

     rule <k> throw(V::LVal) ... </k>
          <catch-handlers> ListItem(CatchOp(T::CPPType, _)) => .List ...</catch-handlers>
          requires notBool handlerMatches(T, type(V))

     syntax KItem ::= catchWithHandler(Stmt, LVal)

     rule <k> catchWithHandler(CatchAnyOp(pushBlock(N::Int) ~> Rest:K), V::LVal)
              ~> tryMark(I::Int)
              => destructTemporaries(true)
              ~> popBlock(true)
              ~> pushBlock(N)
              ~> setCurrentException(V)
              ~> activateHandler
              ~> Rest
              ~> deactivateHandler
          ...</k>
          <block-history> ListItem(I) ...</block-history>

     rule <k> catchWithHandler(CatchOp(_, pushBlock(N::Int) ~> declareNonStaticObjectExec(... id: X::CId) #as D:KItem ~> Rest:K), V::LVal)
              ~> tryMark(I::Int)
              => destructTemporaries(true)
              ~> popBlock(true)
              ~> pushBlock(N)
              ~> setCurrentException(V)
              ~> #if X ==K #NoName #then .K #else D #fi
              ~> activateHandler
              ~> Rest
              ~> deactivateHandler
          ...</k>
          <block-history> ListItem(I) ...</block-history>

     rule <k> setCurrentException(V::LVal) => .K ...</k>
          <current-exception> _ => V </current-exception>

     rule <k> exceptionObject(_) => V ...</k>
          <current-exception> V::LVal </current-exception>
          requires Execution()

     syntax KItem ::= "activateHandler"
                    | "deactivateHandler"
                    | setCurrentException(LVal)

     rule <k> activateHandler => .K ...</k>
          <uncaught-exception> _ => false </uncaught-exception>

     // @ref n4296 15.1/4
     rule <k> deactivateHandler => destructLocal(false, lcentry(V, true, true, false)) ...</k>
          <current-exception> V::LVal => .K </current-exception>

     rule tryMark(_) => .K

     rule <k> catchWithHandler(_, _) ~> (tryMark(I::Int) => .K) ...</k>
          <block-history> ListItem(J::Int) ...</block-history>
          requires I =/=Int J

     rule catchWithHandler(_, _) ~> (K:KItem => .K)
          requires tryMark(...) :/=K K

     syntax Expr ::= "catchAndCallTerminate"

     rule <k> catchAndCallTerminate => callTerminate ...</k>
          <uncaught-exception> _ => false </uncaught-exception>

     syntax Bool ::= #canUnwindStack(List, List, List, CPPType) [function]
                   | canPopBlock(Int, List) [function]
                   | handlerMatches(CPPType, CPPType) [function]
                   | canThrowException(CPPType, CPPType) [function]
                   | canThrowException(ExceptionSet, CPPType) [function, klabel(canThrowExceptionSet)]
                   | isDynamicExceptionSpec(CPPType) [function]

     rule #canUnwindStack((.List => L), (ListItem(<block-control>... <catch-handlers> L::List </catch-handlers> ...</block-control>) => .List) _, _, _)

     rule #canUnwindStack((.List => L2), (.List => L), (ListItem(<call-stack-frame>... <stack-function-control> <function-control>... <uncaught-exception> false </uncaught-exception> <block-stack> L::List </block-stack> <catch-handlers> L2::List </catch-handlers> ...</function-control> </stack-function-control> ...</call-stack-frame>) => .List) _, _)

     rule #canUnwindStack(.List, .List, ListItem(<call-stack-frame>... <stack-function-control> <function-control>... <uncaught-exception> true </uncaught-exception> ...</function-control> </stack-function-control> ...</call-stack-frame>) _, _) => false

     rule #canUnwindStack(ListItem(CatchAnyOp(_)) _, _, _, _) => true

     rule #canUnwindStack(ListItem(CatchOp(T::CPPType, _)) _, _, _, E::CPPType) => true
          requires handlerMatches(T, E)

     rule #canUnwindStack((ListItem(CatchOp(T::CPPType, _)) => .List) _, _, _, E::CPPType)
          requires notBool handlerMatches(T, E)

     rule #canUnwindStack(.List, .List, .List, _) => false

     rule canPopBlock(Num::Int, ListItem(kpair(Num, _)) _) => false

     rule canPopBlock(_, _) => true [owise]

     // @ref n4296 15.3:3.1
     rule handlerMatches(T::CPPType, E::CPPType) => true
          requires utype(T) ==Type utype(E)

     rule handlerMatches(t(... st: lvRefType(T::CPPType)), E::CPPType) => true
          requires utype(T) ==Type utype(E)

     // @ref n4296 15.3:3.2
     rule handlerMatches(t(... st: classType(...)) #as T::CPPType, t(... st: classType(...)) #as E::CPPType) => true
          requires isBaseClassOf(T, E)

     rule handlerMatches(t(... st: lvRefType(t(... st: classType(...)) #as T::CPPType)), t(... st: classType(...)) #as E::CPPType) => true
          requires isBaseClassOf(T, E)

     // @ref n4296 15.3:3.3.1
     rule handlerMatches(t(... st: pointerType(t(QT::Quals, _, classType(...)) #as T::CPPType)), t(... st: pointerType(t(QE::Quals, _, classType(...)) #as E::CPPType)))
          => true
          requires isBaseClassOf(T, E) andBool QE <=Quals QT

     rule handlerMatches(t(... st: pointerType(t(QT::Quals, _, void))), t(... st: pointerType(t(QE::Quals, _, _))))
          => true
          requires QE <=Quals QT

     rule handlerMatches(t(... q: quals(SetItem(Const())), st: lvRefType(t(... st: pointerType(t(QT::Quals, _, classType(...)) #as T::CPPType)))), t(... st: pointerType(t(QE::Quals, _, classType(...)) #as E::CPPType)))
          => true
          requires isBaseClassOf(T, E) andBool QE <=Quals QT

     rule handlerMatches(t(... q: quals(SetItem(Const())), st: lvRefType(t(... st: pointerType(t(QT::Quals, _, void))))), t(... st: pointerType(t(QE::Quals, _, _))))
          => true
          requires QE <=Quals QT

     // @ref n4296 15.3:3.3.2
     rule handlerMatches(t(... st: pointerType(...)) #as T::CPPType, t(... st: pointerType(...)) #as E::CPPType)
          => true
          requires isSimilar(T, E) andBool cvQualificationSignature(E) <=QualSig cvQualificationSignature(T)

     rule handlerMatches(t(... q: quals(SetItem(Const())), st: lvRefType(t(... st: pointerType(...)) #as T::CPPType)), t(... st: pointerType(...)) #as E::CPPType)
          => true
          requires isSimilar(T, E) andBool cvQualificationSignature(E) <=QualSig cvQualificationSignature(T)

     // @ref n4296 15.3:3.4
     rule handlerMatches(t(... st: pointerType(...)) #as T::CPPType, t(... st: nullptr_t) #as E::CPPType) => true

     rule handlerMatches(t(... st: memberPointerType(...)) #as T::CPPType, t(... st: nullptr_t) #as E::CPPType) => true

     rule handlerMatches(t(... q: quals(SetItem(Const())), st: lvRefType(t(... st: pointerType(...)) #as T::CPPType)), t(... st: nullptr_t) #as E::CPPType) => true

     rule handlerMatches(t(... q: quals(SetItem(Const())), st: lvRefType(t(... st: memberPointerType(...)) #as T::CPPType)), t(... st: nullptr_t) #as E::CPPType) => true

     rule handlerMatches(_, _) => false [owise]

     rule canThrowException(t(... st: functionType(... exceptions: ES::ExceptionSet)), E::CPPType)
          => canThrowException(ES, E)

     rule canThrowException(noexcept(false), _) => true

     rule canThrowException(noexcept(true), _) => false

     rule canThrowException(exSet(SetItem(T::CPPType) _), E::CPPType)
          => true
          requires handlerMatches(T, E)

     rule canThrowException(exSet((SetItem(_) => .Set) _), _) [owise]

     rule canThrowException(exSet(.Set), _) => false

     rule isDynamicExceptionSpec(t(... st: functionType(... exceptions: exSet(_)))) => true

     rule isDynamicExceptionSpec(_) => false [owise]

endmodule
