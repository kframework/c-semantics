module CPP-EXECUTION-INIT
     imports C-CONFIGURATION
     imports CPP-DYNAMIC-SYNTAX
     imports CPP-SYMLOC-SYNTAX
     imports CPP-SYNTAX
     imports CPP-TYPING-SYNTAX

     imports LIBC-IO-SYNTAX

     rule pre(E::Expr, _) => E
     rule xe(E::Expr, _) => E
     rule le(E::Expr, _) => E

     rule <k> callMain(N:Int, Args:K)
               => reval(#callMain(T, Base, N, Identifier("#incomingArgumentsArray"), Args)) ~> callAtExit
          ...</k>
          <curr-tu> Tu::String </curr-tu>
          <tu-id> Tu </tu-id>
          <ns-id> GlobalNamespace() </ns-id>
          <nenv>... Identifier("main") |-> (T::CPPType |-> kpair(_, Base::SymBase)) ...</nenv>
          <status> _ => mainCalled </status>

     syntax Expr ::= "#callMain" "(" K "," SymBase "," Int "," CId "," K ")"
     rule #callMain(T::CPPFunctionType, Base::SymBase, _, _, _)
          => BuiltinCallOp(lv(lnew(Base,T), T), 0, .K)
          requires getParams(T) ==K .List

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
                    <k> reval(prv(V::CPPValue, _)) </k>
               ...</thread> => .Bag)
          ...</exec>
          <status> _ => terminated </status>
          <result-value> _ => V </result-value>
          <files>...
               // Flush stdout.
               <file-commands>... (.K => f-flush(1)) </file-commands>
          ...</files>

endmodule
