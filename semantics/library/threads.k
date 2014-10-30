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
     
     syntax K ::= "spawn-aux" "(" Int "," RValue "," RValue ")"
     rule [thrd-create-start]:
          <k> prepareBuiltin(Identifier("thrd_create"),
                    ListItem(ThIdPointer:RValue)
                    ListItem(ThFuncPointer:RValue)
                    ListItem(ThArg:RValue))
               => Computation((* ThIdPointer) := tv(Fresh, t(.Set, int)))
               ~> spawn-aux(Fresh, ThFuncPointer, ThArg)
          ...</k>
          <next-thread-id> Fresh:Int => Fresh:Int +Int 1 </next-thread-id>
          [structural]
     /*
     See http://www.open-std.org/jtc1/sc22/wg14/www/docs/n1521.htm
     */
     rule [thrd-create]:
          <thread>...
               <k> spawn-aux(
                         ThId:Int, ThFuncPointer:RValue, ThArg:RValue) 
                    => thrd-success 
               ...</k>
               <curr-tu> Tu:K </curr-tu>
               <buffer> .List </buffer>
          ...</thread>
          <genv> Env:Map </genv>
          <thread-status> 
               Status:Map => Status[threadRunning <- ThId:Int]
          </thread-status>
          <br/>
          (.Bag =>
          <thread>...
               <next-loc> 0 @ thread(ThId:Int) </next-loc>
               <thread-id> ThId:Int </thread-id>
               <k> Call(ThFuncPointer:RValue, list(ListItem(ThArg:RValue)))
               </k>
               <env> Env:Map </env>
               <curr-tu> Tu:K </curr-tu>
          ...</thread>)
          [large, ndthread]
          
     rule [thrd-current]:
          <k> prepareBuiltin(Identifier("thrd_current"), .List)
               => tv(ThId:Int, t(.Set, int))
          ...</k>
          <thread-id> ThId:Int </thread-id>
          [structural]
          
     syntax K ::= "join-aux" "(" Int "," RValue ")"
          
     rule [thrd-join-start]:
          prepareBuiltin(Identifier("thrd_join"),
               ListItem(tv(ThId:Int, t(_, int)))
               ListItem(ResultPointer:RValue))
          => join-aux(ThId, ResultPointer)
          [structural]
     
     rule [thrd-join]:
          <thread>...
               <k> join-aux(ThId:Int, tv(Loc:SymLoc, _))
                    => #if (Loc =/=K NullPointer) 
                         #then Computation((* Loc) := V) 
                         #else .K
                         #fi
                         ~> thrd-success
               ...</k>
               <buffer> .List </buffer>
          ...</thread>
          <thread>...
               <k> V:RValue </k>
               <thread-id> ThId:Int </thread-id>
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
          when notBool (Loc in keys(M))
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
