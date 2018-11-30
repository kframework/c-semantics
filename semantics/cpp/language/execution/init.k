module CPP-EXECUTION-INIT
     imports C-CONFIGURATION
     imports K-EQUAL
     imports K-IO
     imports C-CHECK-RESTRICT-SYNTAX
     imports C-CPP-VAL-CONVERSION-SYNTAX
     imports CPP-DYNAMIC-SYNTAX
     imports CPP-EXECUTION-EXPR-EXPRLOC-SYNTAX
     imports CPP-SYMLOC-SYNTAX
     imports CPP-SYNTAX
     imports CPP-TYPE-MAP-SYNTAX
     imports CPP-TYPING-SYNTAX

     imports LIBC-IO-SYNTAX

     rule Execution() => true

     rule <k> initMainThread(EP::String) => initMainThread'(getTU(Base)) ...</k>
          <odr-defs>... GlobalNamespace() :: Identifier(EP) |-> (_::CPPType |-> Base::SymBase) ...</odr-defs>

     rule <k> callEntryPoint(EP::String, N:Int, Args:K)
               => enterRestrictTU ~> K ~> reval(#callCppEntryPoint(T, getBase(Entry), N, mainArguments, Args)) ~> callAtExit
          ...</k>
          <dynamic-init> K:K </dynamic-init>
          <uncaught-exception> _ => true </uncaught-exception>
          <curr-tu> Tu::String </curr-tu>
          <tu-id> Tu </tu-id>
          <ns-id> GlobalNamespace() </ns-id>
          <nenv>... Identifier(EP) |-> (T::CPPType |-> Entry::EnvEntry) ...</nenv>
          <status> _ => mainCalled </status>

     syntax Expr ::= #callCppEntryPoint(CPPType, SymBase, Int, CId, K)

     rule #callCppEntryPoint(T::CPPFunctionType, Base::SymBase, _, _, _)
          => BuiltinCallOp(lv(lnew(Base), noTrace, T), false, .List)
          requires getParams(T) ==K .List

     rule #callCppEntryPoint(T::CPPFunctionType, Base::SymBase, Argc:Int, X:CId, Args:K)
          => Args ~> setupCppEnv(Argc) ~> BuiltinCallOp(lv(lnew(Base), noTrace, T), false, ListItem(prv(Argc, noTrace, type(int))) ListItem(ExecName(NoNNS(), X)))
          requires size(getParams(T)) ==Int 2

     syntax KItem ::= setupCppEnv(Int)

     rule <k> setupCppEnv(Argc::Int) => .K ...</k>

          // adjust environment to C++ form
          <env>... mainArguments |-> Argv::SymBase => mainArguments |-> (type(arrayType(type(pointerType(type(char))), Argc +Int 1)) |-> envEntry(Argv, false, NoDefArgs())) ...</env>
          <types>... mainArguments |-> _ => .Map ...</types>

     rule <k> reval(V:PRVal) ~> callAtExit => AtExit:KItem ~> reval(V) ~> callAtExit ...</k>
          <atexit> AtExit:KItem => .K ...</atexit>
          <status> _ => mainExited </status>

     rule <k> reval(V:PRVal) ~> callAtExit => reval(V) ...</k>
          <atexit> .K </atexit>
          <status> _ => mainExited </status>

     rule <k> reval(V:PRVal) ~> callAtQuickExit => AtExit:KItem ~> reval(V) ~> callAtQuickExit ...</k>
          <at-quick-exit> AtExit:KItem => .K ...</at-quick-exit>
          <status> _ => mainExited </status>

     rule <k> reval(V:PRVal) ~> callAtQuickExit => reval(V) ...</k>
          <at-quick-exit> .K </at-quick-exit>
          <status> _ => mainExited </status>

     rule <exec>...
               (<thread>...
                    <thread-id> 0 </thread-id>
                    <k> reval(prv(V::CPPValue, _, _)) </k>
               ...</thread> => .Bag)
          ...</exec>
          <status> _ => terminated </status>
          <result-value> _ => V </result-value>

     rule hasTrace(_) => noTrace [anywhere]

     rule combine(_, _) => noTrace

     rule combine(_, _::Trace, _) => noTrace

     rule combine(_, _, _::Trace, _, _) => noTrace

     syntax Expr ::= RValue

     rule <k> #ExecExprLoc(L::CabsLoc, V:RValue) => convertValToCPP(V) ...</k>
          <curr-program-loc> _ => L </curr-program-loc>
endmodule
