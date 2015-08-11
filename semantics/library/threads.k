module LIBC-THREADS
     imports LIBC-BOOTSTRAP-SYNTAX

     imports C-SYNTAX
     imports C-DYNAMIC-SYNTAX
     imports C-TYPING-SYNTAX
     imports C-SYMLOC-SYNTAX
     imports C-SETTINGS-SYNTAX

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
          <k> prepareBuiltin(Identifier("thrd_create"),
                    hrItem(ThIdPointer:KResult) hs::
                    hrItem(ThFuncPointer) hs::
                    hrItem(ThArg))
               => Computation(
                    (* ThIdPointer:KResult) := tv(Fresh:Int, t(.Set, int)))
                    ~> spawn-aux(
                    Fresh:Int, ThFuncPointer:RValue, ThArg:RValue)
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
               <k> Call(ThFuncPointer, list(ListItem(ThArg)))
               </k>
               <env> Env:Map </env>
               <curr-tu> Tu:String </curr-tu>
          ...</thread>)
          [large, ndthread]

     rule [thrd-current]:
          <k> prepareBuiltin(Identifier("thrd_current"), .HeatList)
               => tv(ThId:Int, t(.Set, int))
          ...</k>
          <thread-id> ThId:Int </thread-id>
          [structural]

     syntax KItem ::= "join-aux" "(" Int "," RValue ")"

     rule [thrd-join-start]:
          prepareBuiltin(Identifier("thrd_join"),
               hrItem(tv(ThId:Int, t(_, int))) hs::
               hrItem(ResultPointer))
          => join-aux(ThId:Int, ResultPointer:RValue)
          [structural]

     rule [thrd-join]:
          <thread>...
               <k> join-aux(ThId:Int, tv(Loc:SymLoc, _))
                    => #if (Loc =/=K NullPointer)
                         #then Computation((* Loc) := V:KResult)
                         #else dotK
                         #fi
                         ~> thrd-success
               ...</k>
               <buffer> .List </buffer>
          ...</thread>
          <thread>...
               <k> V:KResult </k>
               <thread-id> ThId:Int </thread-id>
          ...</thread>
          [ndthread]

     rule [mtx-init]:
          <k> prepareBuiltin(Identifier("mtx_init"),
                    hrItem(tv(Loc:Int, _)) hs::
                    hrItem(tv(Type:Int, _)))
               => thrd-success
          ...</k>
          <mutexes> M:Map (.Map => Loc |-> Type:Int) </mutexes>
          // only handling plain mutexes for now
          requires notBool (Loc in_keys(M))
               andBool (Type ==Int cfg:mtxPlain)
          [structural]

     rule [mtx-lock]:
          <k> prepareBuiltin(Identifier("mtx_lock"),
                    hrItem(tv(Loc:Int, _)))
               => thrd-success
          ...</k>
          <buffer> .List </buffer>
          <mutexes>... Loc |-> Type:Int ...</mutexes>
          <glocks> B:List (.List => ListItem(Loc)) </glocks>
          <locks> .List => ListItem(Loc) ...</locks>
          requires (notBool (Loc in B))
               andBool (Type:Int ==Int cfg:mtxPlain)
          [ndthread]

     rule [mtx-unlock]:
          <k> prepareBuiltin(Identifier("mtx_unlock"),
                    hrItem(tv(Loc:Int, _)))
               => thrd-success
          ...</k>
          <buffer> .List </buffer>
          <mutexes>... Loc:Int |-> Type:Int ...</mutexes>
          <glocks> M:List => removeListItem(M, Loc) </glocks>
          <locks> M':List => removeListItem(M', Loc) </locks>
          requires Type:Int ==Int cfg:mtxPlain
          [ndthread]

endmodule
