module LIBC-THREADS
     imports LIBC-BOOTSTRAP-SYNTAX

     imports C-SYNTAX
     imports C-DYNAMIC-SYNTAX
     imports C-TYPING-SYNTAX
     imports C-SYMLOC-SYNTAX
     imports C11-SETTINGS-SYNTAX

     imports COMPAT-SYNTAX
     
     ////////////////////////////--
     // Threads
     ////////////////////////////--
     syntax K ::= "thrd-success" | "thrd-error" | "thrd-timeout" 
                | "thrd-busy" | "thrd-nomem"
     rule thrd-success => tv(0, t(.Set, int)) [macro, structural]
     rule thrd-error => tv(1, t(.Set, int)) [macro, structural]
     rule thrd-timeout => tv(2, t(.Set, int)) [macro, structural]
     rule thrd-busy => tv(3, t(.Set, int)) [macro, structural]
     rule thrd-nomem => tv(4, t(.Set, int)) [macro, structural]
     
     syntax K ::= "threadRunning"
     
     syntax K ::= "spawn-aux" "(" Int "," Value "," Value ")"
     rule [thrd-create-start]:
          <k> 
               prepareBuiltin((Identifier("thrd_create")), 
                    (ThreadIdPointer:KResult,, ThreadFuncPointer:KResult,, 
                    ThreadArg:KResult))
               => Computation(
                    (* ThreadIdPointer:KResult) := tv(Fresh:Int, t(.Set, int)))
                    ~> spawn-aux(
                    Fresh:Int, ThreadFuncPointer:KResult, ThreadArg:KResult)
          ...</k>
          <nextThreadId> Fresh:Int => Fresh:Int +Int 1 </nextThreadId>
          [structural]
     /*
     See http://www.open-std.org/jtc1/sc22/wg14/www/docs/n1521.htm
     */
     rule [thrd-create]:
          <thread>...
               <k> 
                    spawn-aux(
                         ThreadId:Int, ThreadFuncPointer:KResult, ThreadArg:KResult) 
                    => thrd-success 
               ...</k>
               <currTU> Tu:K </currTU>
               <buffer> .List </buffer>
          ...</thread>
          <genv> Env:Map </genv>
          <threadStatus> 
               Status:Map => Status:Map[threadRunning / ThreadId:Int]
          </threadStatus>
          <br/>
          (.Bag =>
          <thread>...
               <nextLoc> firstLoc(ThreadId:Int) </nextLoc>
               <threadId> ThreadId:Int </threadId>
               <k> 
                    Call(ThreadFuncPointer:KResult, klist(ThreadArg:KResult)) 
               </k>
               <env> Env:Map </env>
               <currTU> Tu:K </currTU>
          ...</thread>)
          [large, ndthread]
          
     rule [thrd-current]:
          <k> 
               prepareBuiltin((Identifier("thrd_current")), .KList)
               => tv(ThreadId:Int, t(.Set, int))
          ...</k>
          <threadId> ThreadId:Int </threadId>
          [structural]
          
     syntax K ::= "join-aux" "(" Int "," Value ")"
          
     rule [thrd-join-start]:
          prepareBuiltin((Identifier("thrd_join")),
               (tv(ThreadId:Int, t(_, int)),, ResultPointer:KResult))
          => join-aux(ThreadId:Int, ResultPointer:KResult)
          [structural]
     
     rule [thrd-join]:
          <thread>...
               <k> 
                    join-aux(ThreadId:Int, tv(Loc:SymLoc, _))
                    => #if (Loc =/=K NullPointer) 
                         #then Computation((* Loc) := V:KResult) 
                         #else .K
                         #fi
                         ~> thrd-success
               ...</k>
               <buffer> .List </buffer>
          ...</thread>
          <thread>...
               <k> V:KResult </k>
               <threadId> ThreadId:Int </threadId>
          ...</thread>
          [ndthread]

     rule [mtx-init]:
          <k> 
               prepareBuiltin((Identifier("mtx_init")),
               (tv(Loc:Int, _),, tv(Type:Int, _)))
               => thrd-success
          ...</k>
          <mutexes> M:Map (. => Loc |-> Type:Int) </mutexes>
          // only handling plain mutexes for now
          when notBool (Loc in keys M:Map)
               andBool (Type ==Int cfg:mtxPlain) 
          [structural]

     rule [mtx-lock]:
          <k> 
               prepareBuiltin((Identifier("mtx_lock")), (tv(Loc:Int, _)))
               => thrd-success
          ...</k>
          <buffer> .List </buffer>
          <mutexes>... Loc |-> Type:Int ...</mutexes>
          <glocks> B:Bag (.Bag => BagItem(Loc)) </glocks>
          <locks>... .Bag => BagItem(Loc) ...</locks>
          when (notBool (Loc #inBag B))
          andBool (Type:Int ==Int cfg:mtxPlain)
          [ndthread]

     rule [mtx-unlock]:
          <k> 
               prepareBuiltin((Identifier("mtx_unlock")), (tv(Loc:Int, _)))
               => thrd-success
          ...</k>
          <buffer> .List </buffer>
          <mutexes>... Loc:Int |-> Type:Int ...</mutexes>
          <glocks>... BagItem(Loc:Int) => .Bag ...</glocks>
          <locks>... BagItem(Loc:Int) => .Bag ...</locks>
          when Type:Int ==Int cfg:mtxPlain
          [ndthread]

endmodule
