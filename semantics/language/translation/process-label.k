module C-PROCESS-LABEL-SYNTAX
     syntax K ::= calculateGotoMap(CId, K)
endmodule

module C-PROCESS-LABEL
     imports C-PROCESS-LABEL-SYNTAX

     imports C-SYNTAX
     imports C-DYNAMIC-SYNTAX
     imports C-TYPING-SYNTAX
     imports COMPAT-SYNTAX

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
     
     syntax K ::= "waitingOnGotoMap"
     rule <k> calculateGotoMap(F:CId, K:K) => waitingOnGotoMap ...</k>
          <curr-function> _ => F </curr-function>
          <curr-tu> Tu:String </curr-tu>
          <tu-id> Tu </tu-id>
          <goto-map> M:Map => M[map(.Map) <- F] </goto-map>
          <goto-map-calc>
               .Bag => (<goto-calc>... 
                         <computation> 
                              K ~> Return(NothingExpression)
                         </computation>
                    ...</goto-calc>)
          </goto-map-calc>
          [structural] 
          
     rule (<goto-calc>
               <computation> .K </computation>
          ...</goto-calc>) => .Bag
          [structural] 

     rule <k> waitingOnGotoMap => . ...</k>
          <goto-map-calc> .Bag </goto-map-calc>
          <curr-function> F:CId => file-scope </curr-function>
          <curr-tu> Tu:K </curr-tu>
          <tu-id> Tu </tu-id>
          <goto-map>... F |-> map(.Map) => .Map ...</goto-map>
          [structural] 
     rule <k> waitingOnGotoMap => . ...</k>
          <goto-map-calc> .Bag </goto-map-calc>
          <curr-function> F:CId => file-scope </curr-function>
          <curr-tu> Tu:K </curr-tu>
          <tu-id> Tu </tu-id>
          <goto-map>... F |-> map(M:Map) ...</goto-map>
          when M =/=Map .Map
          [structural] 

     syntax K ::= endBlockForGoto(Int)
     rule <computation> 
                  BlockStatement(Blk:K) => Blk ~> popBlock
          ...</computation>
          <goto-nesting-depth> N:Int => N +Int 1 </goto-nesting-depth>
          <goto-block-history> ListItem(_:Int) ...</goto-block-history>
          [structural] 
     rule <computation>
               Block(Num:Int, _, list(L:List)) => listToK(L)
          ...</computation> 
          <goto-block-history> . => ListItem(Num) ...</goto-block-history>
          [structural] 
          
     rule <computation> popBlock => .K ...</computation>
          <goto-nesting-depth> I:Int => I -Int 1 </goto-nesting-depth>
          <goto-block-history>
               (ListItem(_:Int) => .List) ListItem(_:Int)
          ...</goto-block-history>
          when I:Int >Int 0
          [structural] 
          
     rule [DefinitionLoc-computation]:
          <computation> CodeLoc(K:K, L:CabsLoc) => K ...</computation>
          <curr-program-loc> _ => L </curr-program-loc>
          [structural] 

     // this rule is different than the dynamic one because we don't enforce T
     // to be reduced yet
     rule <computation> 
               DeclarationDefinition(
                    InitNameGroup(T:K, 
                         list(ListItem(K:K) ListItem(K':K) L:List)))
               => DeclarationDefinition(InitNameGroup(T, list(ListItem(K))))
               ~> DeclarationDefinition(InitNameGroup(T, list(ListItem(K') L)))
          ...</computation>
          [structural]
          
     //  fixme would like to combine the below rules
     rule <computation> 
               DeclarationDefinition(InitNameGroup(T:K, list(ListItem(K:K)))) 
               => .K 
          ...</computation>
          <decl-stack>... 
               .List 
               => ListItem(frozenDeclaration(Depth, BlockNum,
                    DeclarationDefinition(InitNameGroup(T, list(ListItem(K)))))) 
          </decl-stack>
          <goto-nesting-depth> Depth:Int </goto-nesting-depth>
          <goto-block-history> ListItem(BlockNum:Int) ...</goto-block-history>
          [structural]
          
     rule <computation> OnlyTypedef(K:K) => .K ...</computation>
          <decl-stack>... .List 
               => ListItem(frozenDeclaration(Depth, BlockNum, OnlyTypedef(K)))
          </decl-stack>
          <goto-nesting-depth> Depth:Int </goto-nesting-depth>
          <goto-block-history> ListItem(BlockNum:Int) ...</goto-block-history>
          [structural] 
          
     rule [compute-label-typedef]:
          <computation> Typedef(K:K) => .K ...</computation>
          <decl-stack>... .List 
               => ListItem(frozenDeclaration(Depth, BlockNum, Typedef(K))) 
          </decl-stack>
          <goto-nesting-depth> Depth:Int </goto-nesting-depth>
          <goto-block-history> ListItem(BlockNum:Int) ...</goto-block-history>
          [structural] 
          
     rule [compute-label-ignore-non-statement]:
          <computation> L:KLabel(_:KList) => .K ...</computation>
          when false
               orBool (L ==KLabel 'Nop)
               orBool (L ==KLabel 'Computation)
               orBool (L ==KLabel 'Break)
               orBool (L ==KLabel 'Continue)
               orBool (L ==KLabel 'Return)
               orBool (L ==KLabel 'Goto)
               orBool (L ==KLabel 'CompGoto)
          [structural] 
          
     // - should do this with a split
     rule [compute-label-for]:
          <goto-calc>
               <computation> 
                    (For(ForNum:Int, Pre:K, Control:K, Post:K, S:K) => .K) 
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
          (. =>
               <goto-calc> 
                    <computation> S </computation>
                    <computation-tail>
                         Computation(Post)
                         ~> loopMarked
                         ~> For(ForNum, Pre, (
                              #if Control =/=K emptyValue 
                              #then Control
                              #else tv(1, t(.Set, int)) 
                              #fi), Post, S)
                         ~> popLoop
                         ~> K
                         ~> Tail
                    </computation-tail>
                    B
                    <goto-nesting-depth> N +Int 1 </goto-nesting-depth>
                    <goto-block-history>
                         ListItem(ForNum) 
                         ListItem(Num) OldBlockHistory
                    </goto-block-history>
                    <goto-loop-stack>
                         ListItem(kpair(Num, (K ~> Tail))) 
                         OldLoopStack
                    </goto-loop-stack>
               </goto-calc>
          )
          [structural] 
          
     rule [compute-label-do-while]:
          <goto-calc>
               <computation> (DoWhile(E:K, S:K) => .K) ~> K:K </computation>
               <computation-tail> Tail:K </computation-tail>
               B:Bag
               <goto-block-history>
                    ListItem(Num:Int) OldBlockHistory:List
               </goto-block-history>
               <goto-loop-stack> OldLoopStack:List </goto-loop-stack>
          </goto-calc>
          (. =>
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
          [structural]
          
     rule [compute-label-while-mark]:
          <computation>
               (. => S ~> loopMarked)
               ~> While(_:K, S:K)
               ~> (. => popLoop)
               ~> K:K
          </computation>
          <computation-tail> Tail:K </computation-tail>
          <goto-block-history> ListItem(Num:Int) ...</goto-block-history>
          <goto-loop-stack>
               (.List => ListItem(kpair(Num, (K ~> Tail))))
          ...</goto-loop-stack>
          [structural] 
     rule [compute-label-while-done]:
          <computation>
               (loopMarked ~> While(_, _) => .K) ~> popLoop ~> _
          </computation>
          [structural] 
          
     rule [compute-label-if-then-else]:
          <goto-calc>
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
          [structural] 
          
     rule [compute-label-switch]:
          <computation>
               (Switch(_, _, S:K) => S ~> popLoop) ~> K:K
          </computation>
          <computation-tail> Tail:K </computation-tail>
          <goto-block-history> ListItem(Num:Int) ...</goto-block-history>
          <goto-loop-stack>
               (.List => ListItem(kpair(Num, (K ~> Tail))))
          ...</goto-loop-stack>
          [structural] 
          
     rule [compute-label-poploop]:
          <computation> popLoop => .K ...</computation>
          <goto-loop-stack> (ListItem(_:K) => .List) ...</goto-loop-stack>
          [structural] 
          
     rule <computation> (Label(Target:CId, S:K) => S) ~> K:K </computation>
          <computation-tail> Tail:K </computation-tail>
          <goto-loop-stack> LoopStack:List </goto-loop-stack>
          <decl-stack> DeclStack:List </decl-stack>
          <curr-function> F:CId </curr-function>
          <goto-nesting-depth> Depth:Int </goto-nesting-depth>
          <goto-block-history> BlockHistory:List </goto-block-history>
          <curr-tu> Tu:K </curr-tu>
          <tu-id> Tu </tu-id>
          <goto-map>...
               F |-> map(
                    (M:Map => M[
                    gotoObject(Depth, BlockHistory, 
                         (S ~> K ~> Tail), LoopStack, DeclStack) 
                    <- Target]))
          ...</goto-map>
          when notBool Target in keys(M)
          [structural]
          
     rule <computation> 
               (Case(SwitchNum:Int, CaseNum:Int, Val:K, S:K) => S) ~> K:K
          </computation>
          <computation-tail> Tail:K </computation-tail>
          <goto-loop-stack> LoopStack:List </goto-loop-stack>
          <decl-stack> DeclStack:List </decl-stack>
          <curr-function> F:CId </curr-function>
          <goto-nesting-depth> Depth:Int </goto-nesting-depth>
          <goto-block-history> BlockHistory:List </goto-block-history>
          <curr-tu> Tu:K </curr-tu>
          <tu-id> Tu </tu-id>
          <goto-map>... 
               F:CId |-> map(
                    (M:Map => (M[case(CaseNum) <- genLabel(SwitchNum, Val)])[
                         gotoObject(Depth, BlockHistory,
                              (S ~> K ~> Tail), LoopStack, DeclStack)
                              <- case(CaseNum)])) 
          ...</goto-map>
          when notBool genLabel(SwitchNum, Val) in keys(M)
          [structural] 
     rule <computation>
               (Default(SwitchNum:Int, S:K) => S) ~> K:K
          </computation>
          <computation-tail> Tail:K </computation-tail>
          <goto-loop-stack> LoopStack:List </goto-loop-stack>
          <decl-stack> DeclStack:List </decl-stack>
          <curr-function> F:CId </curr-function>
          <goto-nesting-depth> Depth:Int </goto-nesting-depth>
          <goto-block-history> BlockHistory:List </goto-block-history>
          <curr-tu> Tu:K </curr-tu>
          <tu-id> Tu </tu-id>
          <goto-map>... 
               F:CId |-> map(
                    (M:Map => M[
                    gotoObject(Depth, BlockHistory,
                         (S ~> K ~> Tail), LoopStack, DeclStack) 
                    <- genLabel(SwitchNum, l('Default))])) 
          ...</goto-map>
          when notBool genLabel(SwitchNum, l('Default)) in keys(M)
          [structural]
endmodule
 
