module LIBC-SIGNAL-SYNTAX
     imports INT-SYNTAX
     syntax KItem ::= exception(Int)
endmodule

module LIBC-SIGNAL
     imports C-CONFIGURATION
     imports INT
     imports K-EQUAL
     imports SYMLOC-SYNTAX
     imports C-DYNAMIC-SYNTAX
     imports C-ERROR-SYNTAX
     imports C-MEMORY-ALLOC-SYNTAX
     imports C-MEMORY-WRITING-SYNTAX
     imports C-NATIVE-BRIDGE-SYNTAX
     imports C-OS-SETTINGS-SYNTAX
     imports C-SYMLOC-SYNTAX
     imports C-SYNTAX
     imports C-TYPE-BUILDER-SYNTAX
     imports C-TYPING-SYNTAX
     imports LIBC-BUILTIN-SYNTAX
     imports LIBC-IO-SYNTAX
     imports LIBC-SIGNAL-SYNTAX

     rule builtin("signal", Sig::RValue, Handler::RValue)
          => checkMultiThreaded
          ~> checkSignalArg(Handler)
          ~> nativeCall("signal", ListItem(Sig) ListItem(Handler), .List)
          [structural]

     rule <k> checkMultiThreaded => .K ...</k>
          <next-thread-id> 1 </next-thread-id>
          [structural]
     rule <k> (.K => UNDEF("SIGNAL1", "The 'signal' function is used in a multi-threaded program."))
               ~> checkMultiThreaded
          ...</k>
          <next-thread-id> ThId:Int </next-thread-id>
          requires ThId =/=Int 1
          [structural]

     rule checkSignalArg(V::RValue) => .K
          requires isSpecialHandler(V)
          [structural]
     rule <k> checkSignalArg(tv(Loc:SymLoc, _) #as V::RValue) => .K ...</k>
          <functions> Funs:Map </functions>
          requires notBool isSpecialHandler(V) andBool (base(Loc) in_keys(Funs))
          [structural]
     rule <k> (.K => UNDEF("SIGNAL4", "The 'signal' function is called with an invalid signal handler argument."))
               ~> checkSignalArg(tv(Loc:SymLoc, _) #as V::RValue)
          ...</k>
          <functions> Funs:Map </functions>
          requires notBool isSpecialHandler(V) andBool (notBool (base(Loc) in_keys(Funs)))
          [structural]

     syntax Bool ::= isSpecialHandler(RValue) [function]
     rule isSpecialHandler(V::RValue) => true
          requires isNull(V)
     rule isSpecialHandler(tv(Loc:SymLoc, _) #as V::RValue) => true
          requires notBool isNull(V) andBool (isNativeLoc(Loc) andBool offset(Loc) ==Int 1)
     rule isSpecialHandler(_) => false [owise]

     syntax KItem ::= "checkMultiThreaded" | checkSignalArg(RValue)

     rule builtin("raise", tv(Sig:Int, _)) => raise(Sig) ~> success
          [structural]

     syntax KItem ::= "raiseOrAbort" | "exceptionRaised"
     syntax KItem ::= raise(Int)
     rule <k> raise(Sig::Int)
               => Computation(nativeCall("raise", ListItem(tv(Sig, utype(int))), .List))
               ~> checkComputational(Sig)
               ~> revertSigHandlingState(State)
          ...</k>
          <sig-handling-state> State:K => raiseOrAbort </sig-handling-state>
          requires State =/=K raiseOrAbort
          [structural]
     rule <k> (.K => UNDEF("SIGNAL2", "A signal handler for a signal generated from a call to raise or abort calls the raise function."))
               ~> raise(_)
          ...</k>
          <sig-handling-state> raiseOrAbort </sig-handling-state>
          [structural]

     rule <k> exception(Sig::Int)
               => Computation(nativeCall("raise", ListItem(tv(Sig, utype(int))), .List))
               ~> checkComputational(Sig)
               ~> revertSigHandlingState(State)
          ...</k>
          <sig-handling-state> State:K => exceptionRaised </sig-handling-state>
          [structural]

     syntax KItem ::= revertSigHandlingState(K)
     rule <k> revertSigHandlingState(S::K) => .K ...</k>
          <sig-handling-state> _ => S </sig-handling-state>
          [structural]

     syntax KItem ::= checkComputational(Int)
     rule (.K => UNDEF("SIGNAL3", "A signal handler returned when the signal corresponded to a computational exception."))
          ~> checkComputational(Sig::Int)
          requires isComputational(Sig)
          [structural]
     rule checkComputational(Sig::Int) => .K
          requires notBool isComputational(Sig)
          [structural]

     syntax Bool ::= isComputational(Int) [function]
     rule isComputational(Sig::Int)
          => Sig ==Int getSigno(#SIGFPE) orBool Sig ==Int getSigno(#SIGILL) orBool Sig ==Int getSigno(#SIGSEGV)

endmodule
