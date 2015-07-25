module C-PROCESS-LABEL-SYNTAX
     imports C-SYNTAX

     syntax KItem ::= calculateGotoMap(CId, K)
endmodule

module C-PROCESS-LABEL
     imports C-PROCESS-LABEL-SYNTAX

     imports C-DYNAMIC-SYNTAX
     imports C-TYPING-SYNTAX
     imports C-ABSTRACT-SYNTAX

     imports C-CONFIGURATION

     /*
     things I have to keep track of:
          in goto map:
               remaining computation
               which variables are allocated on the path
               ...
          in blocks:
               which variables i've allocated so far

     I need to adjust the block stack,

     When we goto, we need to take the variables on the goto path and subtract
     the variables we've already allocated in the real history.  Then we need
     to declare the remaining variables
     */

     syntax KItem ::= "waitingOnGotoMap"
     rule <k> calculateGotoMap(F:CId, K:K) => waitingOnGotoMap ...</k>
          <curr-tu> Tu:String </curr-tu>
          <tu-id> Tu </tu-id>
          <goto-map> M:Map => M[F <- map(.Map)] </goto-map>
          <goto-map-calc>
               .Bag => (<goto-calc>...
                         <computation>
                              K
                         </computation>
                    ...</goto-calc>)
          </goto-map-calc>

     rule (<goto-calc>
               <computation> .K </computation>
          ...</goto-calc>) => .Bag

     rule <k> waitingOnGotoMap => .K ...</k>
          <goto-map-calc> .Bag </goto-map-calc>
          <curr-scope> blockScope(F:CId, _) </curr-scope>
          <curr-tu> Tu:String </curr-tu>
          <tu-id> Tu </tu-id>
          <goto-map>... F |-> map(.Map) => .Map ...</goto-map>
     rule <k> waitingOnGotoMap => .K ...</k>
          <goto-map-calc> .Bag </goto-map-calc>
          <curr-scope> blockScope(F:CId, _) </curr-scope>
          <curr-tu> Tu:String </curr-tu>
          <tu-id> Tu </tu-id>
          <goto-map>... F |-> map(M:Map) ...</goto-map>
          requires M =/=K .Map

     rule <computation> K:KItem => .K ...</computation>
          requires (getKLabel(K) ==K #klabel(`Nop`))
               orBool (getKLabel(K) ==K #klabel(`Computation`))
               orBool (getKLabel(K) ==K #klabel(`Break`))
               orBool (getKLabel(K) ==K #klabel(`Continue`))
               orBool (getKLabel(K) ==K #klabel(`Return`))
               orBool (getKLabel(K) ==K #klabel(`Goto`))

     rule <computation> pushBlock(Tag:Int) => .K ...</computation>
          <goto-nesting-depth> N:Int => N +Int 1 </goto-nesting-depth>
          <goto-block-history> .List => ListItem(Tag) ...</goto-block-history>
     rule <computation> popBlock => .K ...</computation>
          <goto-nesting-depth> I:Int => I -Int 1 </goto-nesting-depth>
          <goto-block-history> ListItem(_) => .List ...</goto-block-history>
          requires I >Int 0

     rule <computation> L:CabsLoc => .K ...</computation>
          <curr-program-loc> _ => L </curr-program-loc>

     rule <computation>
               declareInternalVariable(X:CId, T:Type, Init:KResult) => .K
          ...</computation>
          <decl-stack>...
               .List
               => ListItem(frozenDeclaration(Depth, BlockNum,
                    declareInternalVariable(X, T, Init)))
          </decl-stack>
          <goto-nesting-depth> Depth:Int </goto-nesting-depth>
          <goto-block-history> ListItem(BlockNum:Int) ...</goto-block-history>

     rule <computation> typedef(X:CId, T:Type) => .K ...</computation>
          <decl-stack>... .List
               => ListItem(frozenDeclaration(Depth, BlockNum, typedef(X, T)))
          </decl-stack>
          <goto-nesting-depth> Depth:Int </goto-nesting-depth>
          <goto-block-history> ListItem(BlockNum:Int) ...</goto-block-history>

     // - should do this with a split
     rule <goto-calc>
               <computation>
                    (For(Control:K, Post:K, S:K) => .K)
                    ~> K:K
               </computation>
               <computation-tail> Tail:K </computation-tail>
               B:Bag
               <goto-nesting-depth> N:Int </goto-nesting-depth>
               <goto-block-history>
                    ListItem(Num:Int) OldBlockHistory:List
               </goto-block-history>
               <goto-loop-stack> OldLoopStack:List </goto-loop-stack>
          </goto-calc>
          (.Bag =>
               <goto-calc>
                    <computation> S </computation>
                    <computation-tail>
                         Computation(Post)
                         ~> loopMarked
                         ~> For((#if Control =/=K emptyValue
                              #then Control
                              #else tv(1, t(.Set, int))
                              #fi), Post, S)
                         ~> popLoop
                         ~> K
                         ~> Tail
                    </computation-tail>
                    B
                    <goto-nesting-depth> N </goto-nesting-depth>
                    <goto-block-history>
                         ListItem(Num) OldBlockHistory
                    </goto-block-history>
                    <goto-loop-stack>
                         ListItem(kpair(Num, (K ~> Tail)))
                         OldLoopStack
                    </goto-loop-stack>
               </goto-calc>
          )

     rule <goto-calc>
               <computation> (DoWhile(E:K, S:K) => .K) ~> K:K </computation>
               <computation-tail> Tail:K </computation-tail>
               B:Bag
               <goto-block-history>
                    ListItem(Num:Int) OldBlockHistory:List
               </goto-block-history>
               <goto-loop-stack> OldLoopStack:List </goto-loop-stack>
          </goto-calc>
          (.Bag =>
               <goto-calc>
                    <computation> S </computation>
                    <computation-tail>
                         IfThenElse(E, (loopMarked ~> DoWhile(E, S)), Nop)
                         ~> popLoop
                         ~> K
                         ~> Tail
                    </computation-tail>
                    B
                    <goto-block-history>
                         ListItem(Num) OldBlockHistory
                    </goto-block-history>
                    <goto-loop-stack>
                         ListItem(kpair(Num, (K ~> Tail)))
                         OldLoopStack
                    </goto-loop-stack>
               </goto-calc>
          )

     rule <computation>
               (.K => S ~> loopMarked)
               ~> While(_:K, S:K)
               ~> (.K => popLoop)
               ~> K:K
          </computation>
          <computation-tail> Tail:K </computation-tail>
          <goto-block-history> ListItem(Num:Int) ...</goto-block-history>
          <goto-loop-stack>
               (.List => ListItem(kpair(Num, (K ~> Tail))))
          ...</goto-loop-stack>
     rule <computation>
               (loopMarked ~> While(_, _) => .K) ~> popLoop ~> _
          </computation>

     rule <goto-calc>
               <computation>
                    (IfThenElse(_, S1:K, S2:K) => .K) ~> K:K
               </computation>
               <computation-tail> Tail:K </computation-tail>
               B:Bag
          </goto-calc>
          (.Bag =>
               <goto-calc>
                    <computation> S1 </computation>
                    <computation-tail> K ~> Tail </computation-tail>
                    B
               </goto-calc>
          )
          (.Bag =>
               <goto-calc>
                    <computation> S2 </computation>
                    <computation-tail> K ~> Tail </computation-tail>
                    B
               </goto-calc>
          )

     rule <computation>
               (Switch(_, _, S:K) => S ~> popLoop) ~> K:K
          </computation>
          <computation-tail> Tail:K </computation-tail>
          <goto-block-history> ListItem(Num:Int) ...</goto-block-history>
          <goto-loop-stack>
               (.List => ListItem(kpair(Num, (K ~> Tail))))
          ...</goto-loop-stack>

     rule <computation> popLoop => .K ...</computation>
          <goto-loop-stack> (ListItem(_:K) => .List) ...</goto-loop-stack>

     rule <computation> (Label(Target:CId, S:K) => S) ~> K:K </computation>
          <computation-tail> Tail:K </computation-tail>
          <goto-loop-stack> LoopStack:List </goto-loop-stack>
          <decl-stack> DeclStack:List </decl-stack>
          <curr-scope> blockScope(F:CId, _) </curr-scope>
          <goto-nesting-depth> Depth:Int </goto-nesting-depth>
          <goto-block-history> BlockHistory:List </goto-block-history>
          <curr-tu> Tu:String </curr-tu>
          <tu-id> Tu </tu-id>
          <goto-map>...
               F |-> map(
                    (M:Map => M[Target
                         <- gotoObject(Depth, BlockHistory,
                         (S ~> K ~> Tail), LoopStack, DeclStack)]))
          ...</goto-map>
          requires notBool (Target in_keys(M))

     rule <computation>
               (Case(SwitchNum:Int, _, Val:K, S:K) => S) ~> K:K
          </computation>
          <computation-tail> Tail:K </computation-tail>
          <goto-loop-stack> LoopStack:List </goto-loop-stack>
          <decl-stack> DeclStack:List </decl-stack>
          <curr-scope> blockScope(F:CId, _) </curr-scope>
          <goto-nesting-depth> Depth:Int </goto-nesting-depth>
          <goto-block-history> BlockHistory:List </goto-block-history>
          <curr-tu> Tu:String </curr-tu>
          <tu-id> Tu </tu-id>
          <goto-map>...
               F:CId |-> map(
                    (M:Map => M[caseLabel(SwitchNum, Val)
                         <- gotoObject(Depth, BlockHistory,
                         (S ~> K ~> Tail), LoopStack, DeclStack)]))
          ...</goto-map>
          requires notBool (caseLabel(SwitchNum, Val) in_keys(M))

     rule <computation>
               (Default(SwitchNum:Int, S:K) => S) ~> K:K
          </computation>
          <computation-tail> Tail:K </computation-tail>
          <goto-loop-stack> LoopStack:List </goto-loop-stack>
          <decl-stack> DeclStack:List </decl-stack>
          <curr-scope> blockScope(F:CId, _) </curr-scope>
          <goto-nesting-depth> Depth:Int </goto-nesting-depth>
          <goto-block-history> BlockHistory:List </goto-block-history>
          <curr-tu> Tu:String </curr-tu>
          <tu-id> Tu </tu-id>
          <goto-map>...
               F:CId |-> map(
                    (M:Map => M[caseLabel(SwitchNum, #klabel(`Default`))
                         <- gotoObject(Depth, BlockHistory,
                         (S ~> K ~> Tail), LoopStack, DeclStack)]))
          ...</goto-map>
          requires notBool (caseLabel(SwitchNum, #klabel(`Default`)) in_keys(M))

endmodule

