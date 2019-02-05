module C-PROCESS-LABEL-SYNTAX
     imports BASIC-K
     imports COMMON-SORTS

     syntax KItem ::= calculateGotoMap(K)
endmodule

module C-PROCESS-LABEL
     imports C-PROCESS-LABEL-SYNTAX
     imports C-CONFIGURATION
     imports BOOL
     imports INT
     imports K-EQUAL
     imports COMPAT-SYNTAX
     imports C-SYNTAX
     imports C-DYNAMIC-SYNTAX
     imports C-TYPING-SYNTAX
     imports C-TYPING-COMMON-SYNTAX

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
     rule <k> calculateGotoMap(K:K) => waitingOnGotoMap ...</k>
          <goto-map-calc>
               .Bag => (<goto-calc>...
                         <computation>
                              K
                         </computation>
                    ...</goto-calc>)
          </goto-map-calc>

     rule <k> waitingOnGotoMap ...</k>
          ((<goto-calc>
               <computation> .K </computation>
          ...</goto-calc>) => .Bag)

     rule <k> waitingOnGotoMap => .K ...</k>
          <goto-map-calc> .Bag </goto-map-calc>

     rule <k> waitingOnGotoMap ...</k>
          <computation> Nop() => .K ...</computation>
     rule <k> waitingOnGotoMap ...</k>
          <computation> Computation(_) => .K ...</computation>
     rule <k> waitingOnGotoMap ...</k>
          <computation> Break() => .K ...</computation>
     rule <k> waitingOnGotoMap ...</k>
          <computation> Continue() => .K ...</computation>
     rule <k> waitingOnGotoMap ...</k>
          <computation> Return(_) => .K ...</computation>
     rule <k> waitingOnGotoMap ...</k>
          <computation> Goto(_) => .K ...</computation>

     rule <k> waitingOnGotoMap ...</k>
          <computation> pushBlock(Tag::Int) => .K ...</computation>
          <goto-block-history> .List => ListItem(Tag) ...</goto-block-history>
     rule <k> waitingOnGotoMap ...</k>
          <computation> popBlock => .K ...</computation>
          <goto-block-history> ListItem(_) => .List ...</goto-block-history>

     rule <k> waitingOnGotoMap ...</k>
          <computation> L:CabsLoc => .K ...</computation>
          <curr-program-loc> _ => L </curr-program-loc>

     rule <k> waitingOnGotoMap ...</k>
          <computation>
               declareInternalVariable(X::CId, T::Type, Init::KResult) => .K
          ...</computation>
          <decl-stack>...
               .List
               => ListItem(frozenDeclaration(BlockNum,
                    declareInternalVariable(X, T, Init)))
          </decl-stack>
          <goto-block-history> ListItem(BlockNum::Int) ...</goto-block-history>

     rule <k> waitingOnGotoMap ...</k>
          <computation> typedef(X::CId, T::Type) => .K ...</computation>
          <decl-stack>... .List
               => ListItem(frozenDeclaration(BlockNum, typedef(X, T)))
          </decl-stack>
          <goto-block-history> ListItem(BlockNum::Int) ...</goto-block-history>

     // - should do this with a split
     rule <k> waitingOnGotoMap ...</k>
          <goto-calc>
               <computation>
                    (For(Control:K, Post:K, S:K) => .K)
                    ~> K:K
               </computation>
               <computation-tail> Tail:K </computation-tail>
               B::Bag
               <goto-block-history>
                    ListItem(Num::Int) OldBlockHistory::List
               </goto-block-history>
               <goto-loop-stack> OldLoopStack::List </goto-loop-stack>
          </goto-calc>
          (.Bag =>
               <goto-calc>
                    <computation> S </computation>
                    <computation-tail>
                         Computation(Post)
                         ~> loopMarked
                         ~> For((#if Control =/=K emptyValue
                              #then Control
                              #else tv(1, utype(int))
                              #fi), Post, S)
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

     rule <k> waitingOnGotoMap ...</k>
          <computation>
               (.K => S ~> loopMarked)
               ~> While(_, S:K)
               ~> (.K => popLoop)
               ~> K:K
          </computation>
          <computation-tail> Tail:K </computation-tail>
          <goto-block-history> ListItem(Num::Int) ...</goto-block-history>
          <goto-loop-stack>
               (.List => ListItem(kpair(Num, (K ~> Tail))))
          ...</goto-loop-stack>

     rule <k> waitingOnGotoMap ...</k>
          <computation>
               (loopMarked ~> While(_, _) => .K) ~> popLoop ~> _
          </computation>

     rule <k> waitingOnGotoMap ...</k>
          <goto-calc>
               <computation> (DoWhile(E:K, S:K) => .K) ~> K:K </computation>
               <computation-tail> Tail:K </computation-tail>
               B::Bag
               <goto-block-history>
                    ListItem(Num::Int) OldBlockHistory::List
               </goto-block-history>
               <goto-loop-stack> OldLoopStack::List </goto-loop-stack>
          </goto-calc>
          (.Bag =>
               <goto-calc>
                    <computation> S </computation>
                    <computation-tail>
                         IfThenElse(E, (loopMarked ~> DoWhile(E, S)), Nop())
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

     rule <k> waitingOnGotoMap ...</k>
          <goto-calc>
               <computation>
                    (IfThenElse(_, S1:K, S2:K) => .K) ~> K:K
               </computation>
               <computation-tail> Tail:K </computation-tail>
               B::Bag
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

     rule <k> waitingOnGotoMap ...</k>
          <computation>
               (Switch(_, _, S:K) => S ~> popLoop) ~> K:K
          </computation>
          <computation-tail> Tail:K </computation-tail>
          <goto-block-history> ListItem(Num::Int) ...</goto-block-history>
          <goto-loop-stack>
               (.List => ListItem(kpair(Num, (K ~> Tail))))
          ...</goto-loop-stack>

     rule <k> waitingOnGotoMap ...</k>
          <computation> popLoop => .K ...</computation>
          <goto-loop-stack> ListItem(_) => .List ...</goto-loop-stack>

     rule <k> waitingOnGotoMap ...</k>
          <computation> (Label(Target::CId, S:K) => S) ~> K:K </computation>
          <computation-tail> Tail:K </computation-tail>
          <goto-loop-stack> LoopStack::List </goto-loop-stack>
          <decl-stack> DeclStack::List </decl-stack>
          <goto-block-history> BlockHistory::List </goto-block-history>
          <curr-scope> blockScope(... functionLoc: Base::SymBase) </curr-scope>
          <functions>...
               Base |-> functionObject(... gotoMap: (
                    M::Map => M[Target
                         <- gotoObject(BlockHistory,
                         (S ~> K ~> Tail), LoopStack, DeclStack)]
               ))
          ...</functions>
          requires notBool (Target in_keys(M))

     rule <k> waitingOnGotoMap ...</k>
          <computation>
               (Case(SwitchNum::Int, _, Val:K, S:K) => S) ~> K:K
          </computation>
          <computation-tail> Tail:K </computation-tail>
          <goto-loop-stack> LoopStack::List </goto-loop-stack>
          <decl-stack> DeclStack::List </decl-stack>
          <goto-block-history> BlockHistory::List </goto-block-history>
          <curr-scope> blockScope(... functionLoc: Base::SymBase) </curr-scope>
          <functions>...
               Base |-> functionObject(... gotoMap: (
                    M::Map => M[caseLabel(SwitchNum, Val)
                              <- gotoObject(BlockHistory,
                              (S ~> K ~> Tail), LoopStack, DeclStack)]
               ))
          ...</functions>
          requires notBool (caseLabel(SwitchNum, Val) in_keys(M))

     rule <k> waitingOnGotoMap ...</k>
          <computation>
               (Default(SwitchNum::Int, S:K) => S) ~> K:K
          </computation>
          <computation-tail> Tail:K </computation-tail>
          <goto-loop-stack> LoopStack::List </goto-loop-stack>
          <decl-stack> DeclStack::List </decl-stack>
          <goto-block-history> BlockHistory::List </goto-block-history>
          <curr-scope> blockScope(... functionLoc: Base::SymBase) </curr-scope>
          <functions>...
               Base |-> functionObject(... gotoMap: (
                    M::Map => M[caseLabel(SwitchNum, #klabel(`Default`))
                              <- gotoObject(BlockHistory,
                              (S ~> K ~> Tail), LoopStack, DeclStack)]
               ))
          ...</functions>
          requires notBool (caseLabel(SwitchNum, #klabel(`Default`)) in_keys(M))

endmodule

