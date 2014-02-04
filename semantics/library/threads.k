module LIBC-THREADS
     imports LIBC-BOOTSTRAP-SYNTAX

     imports C-SYNTAX
     imports C-DYNAMIC-SYNTAX
     imports C-TYPING-SYNTAX
     imports C-SYMLOC-SYNTAX
     imports C-SETTINGS-SYNTAX

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
               prepareBuiltin(Identifier("thrd_create"), 
                    ListItem(ThIdPointer:KResult)
                    ListItem(ThFuncPointer:KResult)
                    ListItem(ThArg:KResult))
               => Computation(
                    (* ThIdPointer:KResult) := tv(Fresh:Int, t(.Set, int)))
                    ~> spawn-aux(
                    Fresh:Int, ThFuncPointer:KResult, ThArg:KResult)
          ...</k>
          <nextThreadId> Fresh:Int => Fresh:Int +Int 1 </nextThreadId>
          [structural]
     /*
     See http://www.open-std.org/jtc1/sc22/wg14/www/docs/n1521.htm
     */
     rule [thrd-create]:
          <thread>...
               <k> spawn-aux(
                         ThId:Int, ThFuncPointer:KResult, ThArg:KResult) 
                    => thrd-success 
               ...</k>
               <currTU> Tu:K </currTU>
               <buffer> .List </buffer>
          ...</thread>
          <genv> Env:Map </genv>
          <threadStatus> 
               Status:Map => Status:Map[threadRunning / ThId:Int]
          </threadStatus>
          <br/>
          (.Bag =>
          <thread>...
               <nextLoc> firstLoc(thread(ThId:Int)) </nextLoc>
               <threadId> ThId:Int </threadId>
               <k> Call(ThFuncPointer:KResult, list(ListItem(ThArg:KResult)))
               </k>
               <env> Env:Map </env>
               <currTU> Tu:K </currTU>
          ...</thread>)
          [large, ndthread]
          
     rule [thrd-current]:
          <k> prepareBuiltin(Identifier("thrd_current"), .List)
               => tv(ThId:Int, t(.Set, int))
          ...</k>
          <threadId> ThId:Int </threadId>
          [structural]
          
     syntax K ::= "join-aux" "(" Int "," Value ")"
          
     rule [thrd-join-start]:
          prepareBuiltin(Identifier("thrd_join"),
               ListItem(tv(ThId:Int, t(_, int)))
               ListItem(ResultPointer:KResult))
          => join-aux(ThId:Int, ResultPointer:KResult)
          [structural]
     
     rule [thrd-join]:
          <thread>...
               <k> join-aux(ThId:Int, tv(Loc:SymLoc, _))
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
               <threadId> ThId:Int </threadId>
          ...</thread>
          [ndthread]

     rule [mtx-init]:
          <k> prepareBuiltin(Identifier("mtx_init"),
                    ListItem(tv(Loc:Int, _))
                    ListItem(tv(Type:Int, _)))
               => thrd-success
          ...</k>
          <mutexes> M:Map (. => Loc |-> Type:Int) </mutexes>
          // only handling plain mutexes for now
          when notBool (Loc in keys M:Map)
               andBool (Type ==Int cfg:mtxPlain) 
          [structural]

     rule [mtx-lock]:
          <k> prepareBuiltin(Identifier("mtx_lock"), 
                    ListItem(tv(Loc:Int, _)))
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
          <k> prepareBuiltin(Identifier("mtx_unlock"),
                    ListItem(tv(Loc:Int, _)))
               => thrd-success
          ...</k>
          <buffer> .List </buffer>
          <mutexes>... Loc:Int |-> Type:Int ...</mutexes>
          <glocks>... BagItem(Loc:Int) => .Bag ...</glocks>
          <locks>... BagItem(Loc:Int) => .Bag ...</locks>
          when Type:Int ==Int cfg:mtxPlain
          [ndthread]

endmodule
