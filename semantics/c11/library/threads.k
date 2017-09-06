module LIBC-THREADS-SYNTAX
     imports INT-SYNTAX
     imports C-DYNAMIC-SORTS

     syntax RValue ::= "thrd-error" [function]
                     | "thrd-timeout" [function]
                     | "thrd-busy" [function]
                     | "thrd-nomem" [function]

     syntax KItem ::= "threadRunning" | "threadJoined"
     syntax KItem ::= "spawn-aux" "(" Int "," RValue "," RValue ")"
endmodule

module LIBC-THREADS
     imports BOOL
     imports C-CONFIGURATION
     imports C-DYNAMIC-SYNTAX
     imports C-ERROR-SYNTAX
     imports C-EXECUTION-ERROR-SYNTAX
     imports C-SETTINGS-SYNTAX
     imports C-SYNTAX
     imports C-TYPING-SYNTAX
     imports INT
     imports K-EQUAL
     imports LIBC-BUILTIN-SYNTAX
     imports LIBC-THREADS-SYNTAX
     imports SYMLOC-SYNTAX

     ////////////////////////////--
     // Threads
     ////////////////////////////--
     rule thrd-error => tv(1, utype(int))
     rule thrd-timeout => tv(2, utype(int))
     rule thrd-busy => tv(3, utype(int))
     rule thrd-nomem => tv(4, utype(int))

     rule [thrd-create-start]:
          <k> builtin("thrd_create",
                    ThIdPtr:RValue,
                    ThFuncPtr:RValue,
                    ThArg:RValue)
               => Computation(
                    (* ThIdPtr) := tv(Fresh, utype(cfg:thrdut)))
                    ~> spawn-aux(Fresh, ThFuncPtr, ThArg)
          ...</k>
          <next-thread-id> Fresh:Int => Fresh +Int 1 </next-thread-id>
          [structural]
     /*
     See http://www.open-std.org/jtc1/sc22/wg14/www/docs/n1521.htm
     */
     rule [thrd-create]:
          <thread>...
               <k> spawn-aux(
                         ThId:Int, ThFuncPtr:RValue, ThArg:RValue)
                    => success
               ...</k>
               <curr-tu> Tu:String </curr-tu>
               <buffer> .List </buffer>
          ...</thread>
          <genv> Env:Map </genv>
          <thread-status>
               Status:Map => Status[ThId <- threadRunning]
          </thread-status>
          (.Bag =>
          <thread>...
               <duration> threadLocal(ThId:Int) </duration>
               <thread-id> ThId:Int </thread-id>
               <k> Call(ThFuncPtr, list(ListItem(ThArg)))
               </k>
               <env> Env:Map </env>
               <curr-tu> Tu:String </curr-tu>
          ...</thread>)
          requires notBool hasLint
          [large, ndthread]

     rule [thrd-current]:
          <k> builtin("thrd_current")
               => tv(ThId:Int, utype(cfg:thrdut))
          ...</k>
          <thread-id> ThId:Int </thread-id>
          [structural]

     syntax KItem ::= "join-aux" "(" Int "," RValue ")"

     rule [thrd-join-start]:
          builtin("thrd_join",
               tv(ThId:Int, ut(_, T::SimpleUType)),
               ResultPtr:RValue)
          => join-aux(ThId, ResultPtr)
          requires T ==K cfg:thrdut
          [structural]

     rule [thrd-join]:
          <thread>...
               <k> join-aux(ThId:Int, Ptr:RValue)
                    => #if (notBool isNull(Ptr))
                       #then Computation((* Ptr) := V)
                       #else .K
                       #fi
                    ~> success
               ...</k>
               <thread-id> ThisThread:Int </thread-id>
               <buffer> .List </buffer>
          ...</thread>
          <thread-status>
               Status:Map => Status[ThId <- threadJoined]
          </thread-status>
          (<thread>...
               <k> V:KResult </k>
               <thread-id> ThId </thread-id>
          ...</thread> => .Bag)
          requires (ThId in_keys(Status))
               andBool (Status[ThId] =/=K threadJoined)
               andBool ThId =/=K ThisThread
          [ndthread]
     rule <k> (.K => UNDEF("THREADS1", "'thrd_join' or 'pthread_join' called for an invalid or already-joined thread."))
               ~> join-aux(ThId:Int, _)
          ...</k>
          <thread-status>
               Status:Map
          </thread-status>
          <thread-id> ThisThread:Int </thread-id>
          requires notBool ((ThId in_keys(Status))
               andBool (Status[ThId] =/=K threadJoined)
               andBool ThId =/=K ThisThread)
          [ndthread]

     rule [mtx-init]:
          <k> builtin("mtx_init", tv(Loc:Int, _), tv(Type:Int, _))
               => success
          ...</k>
          <mutexes> M:Map (.Map => Loc |-> Type:Int) </mutexes>
          // only handling plain mutexes for now
          requires notBool (Loc in_keys(M))
               andBool (Type ==Int cfg:mtxPlain)
          [structural]

     rule [mtx-lock]:
          <k> builtin("mtx_lock", tv(Loc:Int, _))
               => success
          ...</k>
          <buffer> .List </buffer>
          <mutexes>... Loc |-> Type:Int ...</mutexes>
          <glocks> M:Map (.Map => Loc |-> printStackTrace(CallStack, Tu, S, L, Env)) </glocks>
          <locks> .List => ListItem(Loc) ...</locks>
          <call-stack> CallStack:List </call-stack>
          <curr-tu> Tu::String </curr-tu>
          <renv> Env::Map </renv>
          <curr-program-loc> L:CabsLoc </curr-program-loc>
          <curr-scope> S:Scope </curr-scope>
          requires (notBool (Loc in_keys(M)))
               andBool (Type:Int ==Int cfg:mtxPlain)
          [ndthread]

     rule [mtx-unlock]:
          <k> builtin("mtx_unlock", tv(Loc:Int, _))
               => success
          ...</k>
          <buffer> .List </buffer>
          <mutexes>... Loc:Int |-> Type:Int ...</mutexes>
          <glocks> M:Map => M [ Loc <- undef ] </glocks>
          <locks> M':List => removeListItem(M', Loc) </locks>
          requires Type:Int ==Int cfg:mtxPlain
          [ndthread]

endmodule
