module LIBC-THREADS
     imports LIBC-BOOTSTRAP-SYNTAX

     imports C-DYNAMIC-SYNTAX
     imports C-SETTINGS-SYNTAX
     imports C-SYMLOC-SYNTAX
     imports C-SYNTAX
     imports C-TYPING-SYNTAX

     imports C-CONFIGURATION

     ////////////////////////////--
     // Threads
     ////////////////////////////--
     syntax KItem ::= "thrd-success" | "thrd-error" | "thrd-timeout"
                    | "thrd-busy" | "thrd-nomem"
     rule thrd-success => tv(0, t(.Set, int)) [macro, structural]
     rule thrd-error => tv(1, t(.Set, int)) [macro, structural]
     rule thrd-timeout => tv(2, t(.Set, int)) [macro, structural]
     rule thrd-busy => tv(3, t(.Set, int)) [macro, structural]
     rule thrd-nomem => tv(4, t(.Set, int)) [macro, structural]

     syntax KItem ::= "threadRunning"

     syntax KItem ::= "spawn-aux" "(" Int "," RValue "," RValue ")"
     rule [thrd-create-start]:
          <k> builtin("thrd_create",
                    ThIdPtr:RValue,
                    ThFuncPtr:RValue,
                    ThArg:RValue)
               => Computation(
                    (* ThIdPtr) := tv(Fresh, t(.Set, cfg:thrdut)))
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
                    => thrd-success
               ...</k>
               <curr-tu> Tu:String </curr-tu>
               <buffer> .List </buffer>
          ...</thread>
          <genv> Env:Map </genv>
          <thread-status>
               Status:Map => Status[ThId:Int <- threadRunning]
          </thread-status>
          (.Bag =>
          <thread>...
               <duration> thread(ThId:Int) </duration>
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
               => tv(ThId:Int, t(.Set, cfg:thrdut))
          ...</k>
          <thread-id> ThId:Int </thread-id>
          [structural]

     syntax KItem ::= "join-aux" "(" Int "," RValue ")"

     rule [thrd-join-start]:
          builtin("thrd_join",
               tv(ThId:Int, t(_, T:SimpleType)),
               ResultPtr:RValue)
          => join-aux(ThId, ResultPtr)
          requires T ==K cfg:thrdut
          [structural]

     rule [thrd-join]:
          <thread>...
               <k> join-aux(ThId:Int, Ptr:RValue)
                    => #if (notBool isNull(Ptr))
                       #then Computation((* Ptr) := V)
                       #else dotK
                       #fi
                    ~> thrd-success
               ...</k>
               <buffer> .List </buffer>
          ...</thread>
          (<thread>...
               <k> V:KResult </k>
               <thread-id> ThId:Int </thread-id>
          ...</thread> => .Bag)
          [ndthread]

     rule [mtx-init]:
          <k> builtin("mtx_init", tv(Loc:Int, _), tv(Type:Int, _))
               => thrd-success
          ...</k>
          <mutexes> M:Map (.Map => Loc |-> Type:Int) </mutexes>
          // only handling plain mutexes for now
          requires notBool (Loc in_keys(M))
               andBool (Type ==Int cfg:mtxPlain)
          [structural]

     rule [mtx-lock]:
          <k> builtin("mtx_lock", tv(Loc:Int, _))
               => thrd-success
          ...</k>
          <buffer> .List </buffer>
          <mutexes>... Loc |-> Type:Int ...</mutexes>
          <glocks> M:Map (.Map => Loc |-> printStackTrace(Stack, L, S)) </glocks>
          <locks> .List => ListItem(Loc) ...</locks>
          <call-stack> Stack:List </call-stack>
          <curr-program-loc> L:CabsLoc </curr-program-loc>
          <curr-scope> S:Scope </curr-scope>
          requires (notBool (Loc in_keys(M)))
               andBool (Type:Int ==Int cfg:mtxPlain)
          [ndthread]

     rule [mtx-unlock]:
          <k> builtin("mtx_unlock", tv(Loc:Int, _))
               => thrd-success
          ...</k>
          <buffer> .List </buffer>
          <mutexes>... Loc:Int |-> Type:Int ...</mutexes>
          <glocks> M:Map => M [ Loc <- undef ] </glocks>
          <locks> M':List => removeListItem(M', Loc) </locks>
          requires Type:Int ==Int cfg:mtxPlain
          [ndthread]

endmodule
