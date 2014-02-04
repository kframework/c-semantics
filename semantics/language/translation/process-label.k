module C-PROCESS-LABEL-SYNTAX
     syntax K ::= calculateGotoMap(Id, K)
endmodule

module C-PROCESS-LABEL
     imports C-PROCESS-LABEL-SYNTAX

     imports C-SYNTAX
     imports C-DYNAMIC-SYNTAX
     imports C-TYPING-SYNTAX
     imports COMPAT-SYNTAX

     // now that we can have different strictnesses in different cells, maybe
     // this can be redone easily
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
     rule <k> calculateGotoMap(F:Id, K:K) => waitingOnGotoMap ...</k>
          <currentFunction> _ => F </currentFunction>
          <currTU> Tu:String </currTU>
          <tu-id> Tu </tu-id>
          <goto-map> M:Map => M:Map[map(.Map) / F] </goto-map>
          <calculateGotoMap>
               .Bag => (<gotoCalculation>... 
                         <computation> 
                              K:K ~> Return(NothingExpression)
                         </computation>
                    ...</gotoCalculation>)
          </calculateGotoMap>
          [structural] 
          
     rule (<gotoCalculation>
               <computation> .K </computation>
          ...</gotoCalculation>) => .Bag
          [structural] 

     rule <k> waitingOnGotoMap => . ...</k>
          <calculateGotoMap> .Bag </calculateGotoMap>
          <currentFunction> F:Id => file-scope </currentFunction>
          <currTU> Tu:K </currTU>
          <tu-id> Tu </tu-id>
          <goto-map>... F |-> map(.Map) => .Map ...</goto-map>
          [structural] 
     rule <k> waitingOnGotoMap => . ...</k>
          <calculateGotoMap> .Bag </calculateGotoMap>
          <currentFunction> F:Id => file-scope </currentFunction>
          <currTU> Tu:K </currTU>
          <tu-id> Tu </tu-id>
          <goto-map>... F |-> map(M:Map) ...</goto-map>
          when M =/=Map .Map
          [structural] 

     syntax K ::= "endBlockForGoto" "(" Int ")"
     rule <computation> 
                  BlockStatement(Blk:K) => Blk ~> popBlock
          ...</computation>
          <nestingDepthGoto> N:Int => N +Int 1 </nestingDepthGoto>
          <blockHistoryGoto> ListItem(_:Int) ...</blockHistoryGoto>
          [structural] 
     rule <computation>
               Block(Num:Int, _, list(L:List)) => listToK(L)
          ...</computation> 
          <blockHistoryGoto> . => ListItem(Num) ...</blockHistoryGoto>
          [structural] 
          
     rule <computation> popBlock => .K ...</computation>
          <nestingDepthGoto> I:Int => I -Int 1 </nestingDepthGoto>
          <blockHistoryGoto>
               (_:ListItem => .List) ListItem(_:Int)
          ...</blockHistoryGoto>
          when I:Int >Int 0
          [structural] 
          
     rule [DefinitionLoc-computation]:
          <computation> CodeLoc(K:K, L:CabsLoc) => K ...</computation>
          <currentProgramLoc> _ => L </currentProgramLoc>
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
          <declarationStack>... 
               .List 
               => ListItem(frozenDeclaration(Depth, BlockNum,
                    DeclarationDefinition(InitNameGroup(T, list(ListItem(K)))))) 
          </declarationStack>
          <nestingDepthGoto> Depth:Int </nestingDepthGoto>
          <blockHistoryGoto> ListItem(BlockNum:Int) ...</blockHistoryGoto>
          [structural, large]
          
     rule <computation> OnlyTypedef(K:K) => .K ...</computation>
          <declarationStack>... .List 
               => ListItem(frozenDeclaration(Depth, BlockNum, OnlyTypedef(K)))
          </declarationStack>
          <nestingDepthGoto> Depth:Int </nestingDepthGoto>
          <blockHistoryGoto> ListItem(BlockNum:Int) ...</blockHistoryGoto>
          [structural] 
          
     rule [compute-label-typedef]:
          <computation> Typedef(K:K) => .K ...</computation>
          <declarationStack>... .List 
               => ListItem(frozenDeclaration(Depth, BlockNum, Typedef(K))) 
          </declarationStack>
          <nestingDepthGoto> Depth:Int </nestingDepthGoto>
          <blockHistoryGoto> ListItem(BlockNum:Int) ...</blockHistoryGoto>
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
          <gotoCalculation>
               <computation> 
                    (For(ForNum:Int, Pre:K, Control:K, Post:K, S:K) => .K) 
                    ~> K:K 
               </computation>
               <computationTail> Tail:K </computationTail>
               B:Bag
               <nestingDepthGoto> N:Int </nestingDepthGoto>
               <blockHistoryGoto>
                    ListItem(Num:Int) OldBlockHistory:List
               </blockHistoryGoto>
               <loopStackGoto> OldLoopStack:List </loopStackGoto>
          </gotoCalculation>
          (. =>
               <gotoCalculation> 
                    <computation> S </computation>
                    <computationTail>
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
                    </computationTail>
                    B
                    <nestingDepthGoto> N +Int 1 </nestingDepthGoto>
                    <blockHistoryGoto>
                         ListItem(ForNum) 
                         ListItem(Num) OldBlockHistory
                    </blockHistoryGoto>
                    <loopStackGoto>
                         ListItem(kpair(Num, (K ~> Tail))) 
                         OldLoopStack
                    </loopStackGoto>
               </gotoCalculation>
          )
          [structural, large] 
          
     rule [compute-label-do-while]:
          <gotoCalculation>
               <computation> (DoWhile(E:K, S:K) => .K) ~> K:K </computation>
               <computationTail> Tail:K </computationTail>
               B:Bag
               <blockHistoryGoto>
                    ListItem(Num:Int) OldBlockHistory:List
               </blockHistoryGoto>
               <loopStackGoto> OldLoopStack:List </loopStackGoto>
          </gotoCalculation>
          (. =>
               <gotoCalculation> 
                    <computation> S </computation>
                    <computationTail>
                         IfThenElse(E, (loopMarked ~> DoWhile(E, S)), Nop)
                         ~> popLoop
                         ~> K
                         ~> Tail
                    </computationTail>
                    B
                    <blockHistoryGoto>
                         ListItem(Num) OldBlockHistory
                    </blockHistoryGoto>
                    <loopStackGoto>
                         ListItem(kpair(Num, (K ~> Tail)))
                         OldLoopStack
                    </loopStackGoto>
               </gotoCalculation>
          )
          [structural, large]
          
     rule [compute-label-while-mark]:
          <computation>
               (. => S ~> loopMarked)
               ~> While(_:K, S:K)
               ~> (. => popLoop)
               ~> K:K
          </computation>
          <computationTail> Tail:K </computationTail>
          <blockHistoryGoto> ListItem(Num:Int) ...</blockHistoryGoto>
          <loopStackGoto>
               (. => ListItem(kpair(Num, (K ~> Tail))))
          ...</loopStackGoto>
          [structural] 
     rule [compute-label-while-done]:
          <computation>
               (loopMarked ~> While(_, _) => .K) ~> popLoop ~> _
          </computation>
          [structural] 
          
     rule [compute-label-if-then-else]:
          <gotoCalculation>
               <computation>
                    (IfThenElse(_, S1:K, S2:K) => .K) ~> K:K
               </computation>
               <computationTail> Tail:K </computationTail>
               B:Bag
          </gotoCalculation>
          (. =>
               <gotoCalculation> 
                    <computation> S1 </computation> 
                    <computationTail> K ~> Tail </computationTail>
                    B
               </gotoCalculation>
          )
          (. =>
               <gotoCalculation> 
                    <computation> S2 </computation>
                    <computationTail> K ~> Tail </computationTail>
                    B
               </gotoCalculation>
          )
          [structural, large] 
          
     rule [compute-label-switch]:
          <computation>
               (Switch(_, _, S:K) => S ~> popLoop) ~> K:K
          </computation>
          <computationTail> Tail:K </computationTail>
          <blockHistoryGoto> ListItem(Num:Int) ...</blockHistoryGoto>
          <loopStackGoto>
               (. => ListItem(kpair(Num, (K ~> Tail))))
          ...</loopStackGoto>
          [structural] 
          
     rule [compute-label-poploop]:
          <computation> popLoop => .K ...</computation>
          <loopStackGoto> (_:ListItem => .) ...</loopStackGoto>
          [structural] 
          
     rule <computation> (Label(Target:Id, S:K) => S) ~> K:K </computation>
          <computationTail> Tail:K </computationTail>
          <loopStackGoto> LoopStack:List </loopStackGoto>
          <declarationStack> DeclStack:List </declarationStack>
          <currentFunction> F:Id </currentFunction>
          <nestingDepthGoto> Depth:Int </nestingDepthGoto>
          <blockHistoryGoto> BlockHistory:List </blockHistoryGoto>
          <currTU> Tu:K </currTU>
          <tu-id> Tu </tu-id>
          <goto-map>...
               F |-> map(
                    (M:Map => M:Map[
                    gotoObject(Depth, BlockHistory, 
                         (S ~> K ~> Tail), LoopStack, DeclStack) 
                    / Target]))
          ...</goto-map>
          when notBool $hasMapping(M, Target)
          [structural, large]
          
     rule <computation> 
               (Case(SwitchNum:Int, CaseNum:Int, Val:K, S:K) => S) ~> K:K
          </computation>
          <computationTail> Tail:K </computationTail>
          <loopStackGoto> LoopStack:List </loopStackGoto>
          <declarationStack> DeclStack:List </declarationStack>
          <currentFunction> F:Id </currentFunction>
          <nestingDepthGoto> Depth:Int </nestingDepthGoto>
          <blockHistoryGoto> BlockHistory:List </blockHistoryGoto>
          <currTU> Tu:K </currTU>
          <tu-id> Tu </tu-id>
          <goto-map>... 
               F:Id |-> map(
                    (M:Map => (M:Map[
                         case(CaseNum) 
                         / genLabel(SwitchNum, Val)])[
                    gotoObject(Depth, BlockHistory,
                         (S ~> K ~> Tail), LoopStack, DeclStack)
                    / case(CaseNum)])) 
          ...</goto-map>
          when notBool $hasMapping(M, genLabel(SwitchNum, Val))
          [structural, large] 
     rule <computation>
               (Default(SwitchNum:Int, S:K) => S) ~> K:K
          </computation>
          <computationTail> Tail:K </computationTail>
          <loopStackGoto> LoopStack:List </loopStackGoto>
          <declarationStack> DeclStack:List </declarationStack>
          <currentFunction> F:Id </currentFunction>
          <nestingDepthGoto> Depth:Int </nestingDepthGoto>
          <blockHistoryGoto> BlockHistory:List </blockHistoryGoto>
          <currTU> Tu:K </currTU>
          <tu-id> Tu </tu-id>
          <goto-map>... 
               F:Id |-> map(
                    (M:Map => M:Map[
                    gotoObject(Depth, BlockHistory,
                         (S ~> K ~> Tail), LoopStack, DeclStack) 
                    / genLabel(SwitchNum, l('Default))])) 
          ...</goto-map>
          when notBool $hasMapping(M, genLabel(SwitchNum, l('Default)))
          [structural, large]
endmodule
 
