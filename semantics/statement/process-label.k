module C-STATEMENT-PROCESS-LABEL
     imports C-STATEMENT-SYNTAX
     imports C-STATEMENT-SWITCH-SYNTAX
     imports C-STATEMENT-BLOCK-SYNTAX
     imports C-STATEMENT-LOOP-SYNTAX
     imports C-STATEMENT-GOTO-SYNTAX

     imports C-SYNTAX
     imports C-DYNAMIC-SYNTAX
     imports C-COMPAT-SYNTAX
     imports C-DECLARATION-SYNTAX
     imports C-TYPING-SYNTAX

     // TODO(chathhorn): is this really used?
     syntax K ::= "case" "(" Int ")"

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
          <gotoMap> M:Map => M:Map[map(.Map) / kpair(Tu:K, F:Id)] </gotoMap>
          <currentFunction> _ => F:Id </currentFunction>
          <currTU> Tu:K </currTU>
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
          <currentFunction> _ => file-scope </currentFunction>
          [structural] 

     syntax K ::= "endBlockForGoto" "(" Int ")"
     rule <computation> 
                  BlockStatement(Blk:K) => Blk:K ~> popBlock
          ...</computation>
          <nestingDepthGoto> N:Int => N:Int +Int 1 </nestingDepthGoto>
          <blockHistoryGoto> ListItem(_:Int) ...</blockHistoryGoto>
          [structural] 
     rule <computation>
               Block(Num:Int, _, klist(L:KList)) => klistToK(L:KList)
          ...</computation> 
          <blockHistoryGoto> . => ListItem(Num:Int) ...</blockHistoryGoto>
          [structural] 
          
     rule <computation> popBlock => .K ...</computation>
          <nestingDepthGoto> I:Int => I:Int -Int 1 </nestingDepthGoto>
          <blockHistoryGoto>
               (_:ListItem => .List) ListItem(_:Int)
          ...</blockHistoryGoto>
          when I:Int >Int 0
          [structural] 
          
     rule [DefinitionLoc-computation]:
          <computation> CodeLoc(K:K, L:CabsLoc) => K:K ...</computation>
          <currentProgramLoc> _ => L:CabsLoc </currentProgramLoc>
          [structural] 

     // this rule is different than the dynamic one because we don't enforce T
     // to be reduced yet
     rule <computation> 
               DeclarationDefinition(
                    InitNameGroup(T:K, klist((K:K,, K':K,, L:KList))))
               => DeclarationDefinition(InitNameGroup(T:K, klist(K:K)))
                    ~> DeclarationDefinition(
                    InitNameGroup(T:K, klist((K':K,, L:KList))))
          ...</computation>
          [structural]
          
     //  fixme would like to combine the below rules
     rule <computation> 
               DeclarationDefinition(InitNameGroup(T:K, klist(K:K))) => .K 
          ...</computation>
          <br/>
          <declarationStack>... 
               .List 
               => ListItem(frozenDeclaration(Depth:Int, BlockNum:Int,
                    DeclarationDefinition(InitNameGroup(T:K, klist(K:K))))) 
          </declarationStack>
          <nestingDepthGoto> Depth:Int </nestingDepthGoto>
          <blockHistoryGoto> ListItem(BlockNum:Int) ...</blockHistoryGoto>
          [structural, large]
          
     rule <computation> OnlyTypedef(K:K) => .K ...</computation>
          <declarationStack>... .List 
               => ListItem(frozenDeclaration(
                    Depth:Int, BlockNum:Int, OnlyTypedef(K:K))) 
          </declarationStack>
          <nestingDepthGoto> Depth:Int </nestingDepthGoto>
          <blockHistoryGoto> ListItem(BlockNum:Int) ...</blockHistoryGoto>
          [structural] 
          
     rule [compute-label-typedef]:
          <computation> Typedef(K:K) => .K ...</computation>
          <declarationStack>... .List 
               => ListItem(frozenDeclaration(
                    Depth:Int, BlockNum:Int, Typedef(K:K))) 
          </declarationStack>
          <nestingDepthGoto> Depth:Int </nestingDepthGoto>
          <blockHistoryGoto> ListItem(BlockNum:Int) ...</blockHistoryGoto>
          [structural] 
          
     rule [compute-label-ignore-non-statement]:
          <computation> L:KLabel(_:KList) => .K ...</computation>
          when false
               orBool (L:KLabel ==KLabel 'Nop)
               orBool (L:KLabel ==KLabel 'Computation)
               orBool (L:KLabel ==KLabel 'Break)
               orBool (L:KLabel ==KLabel 'Continue)
               orBool (L:KLabel ==KLabel 'Return)
               orBool (L:KLabel ==KLabel 'Goto)
               orBool (L:KLabel ==KLabel 'CompGoto)
          [structural] 
          
     // - should do this with a split
     rule [compute-label-for]:
          <gotoCalculation>
               <computation> 
                    (For(ForNum:Int, Pre:K, Control:K, Post:K, S:K) => .K) 
                    ~> K:K 
               </computation>
               <computationTail> Tail:K </computationTail>
               <br/>
               B:Bag
               <nestingDepthGoto> N:Int </nestingDepthGoto>
               <blockHistoryGoto>
                    ListItem(Num:Int) OldBlockHistory:List
               </blockHistoryGoto>
               <loopStackGoto> OldLoopStack:List </loopStackGoto>
          </gotoCalculation>
          <br/>
          (. =>
               <gotoCalculation> 
                    <computation> S:K </computation>
                    <br/>
                    <computationTail>
                         Computation(Post:K)
                         ~> loopMarked
                         ~> For(ForNum:Int, Pre:K, (
                              #if Control:K =/=K emptyValue 
                              #then Control:K 
                              #else tv(1, t(.Set, int)) 
                              #fi), Post:K, S:K)
                         ~> popLoop
                         ~> K:K 
                         ~> Tail:K 
                    </computationTail>
                    <br/>
                    B:Bag
                    <nestingDepthGoto> N:Int +Int 1 </nestingDepthGoto>
                    <blockHistoryGoto>
                         ListItem(ForNum:Int) 
                         ListItem(Num:Int) OldBlockHistory:List
                    </blockHistoryGoto>
                    <loopStackGoto>
                         ListItem(kpair(Num:Int, (K:K ~> Tail:K))) 
                         OldLoopStack:List
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
          <br/>
          (. =>
               <gotoCalculation> 
                    <computation> S:K </computation>
                    <br/>
                    <computationTail>
                         IfThenElse(E:K, (loopMarked ~> DoWhile(E:K, S:K)), Nop)
                         ~> popLoop
                         ~> K:K 
                         ~> Tail:K 
                    </computationTail>
                    <br/>
                    B:Bag
                    <blockHistoryGoto>
                         ListItem(Num:Int) OldBlockHistory:List
                    </blockHistoryGoto>
                    <loopStackGoto>
                         ListItem(kpair(Num:Int, (K:K ~> Tail:K)))
                         OldLoopStack:List
                    </loopStackGoto>
               </gotoCalculation>
          )
          [structural, large]
          
     rule [compute-label-while-mark]:
          <computation>
               (. => S:K ~> loopMarked)
               ~> While(_:K, S:K)
               ~> (. => popLoop)
               ~> K:K
          </computation>
          <computationTail> Tail:K </computationTail>
          <blockHistoryGoto> ListItem(Num:Int) ...</blockHistoryGoto>
          <loopStackGoto>
               (. => ListItem(kpair(Num:Int, (K:K ~> Tail:K))))
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
          <br/>
          (. =>
               <gotoCalculation> 
                    <computation> S1:K </computation> 
                    <computationTail> K:K ~> Tail:K </computationTail>
                    B:Bag 
               </gotoCalculation>
          )
          (. =>
               <gotoCalculation> 
                    <computation> S2:K </computation>
                    <computationTail> K:K ~> Tail:K </computationTail>
                    B:Bag 
               </gotoCalculation>
          )
          [structural, large] 
          
     rule [compute-label-switch]:
          <computation>
               (Switch(_, _, S:K) => S:K ~> popLoop) ~> K:K
          </computation>
          <computationTail> Tail:K </computationTail>
          <blockHistoryGoto> ListItem(Num:Int) ...</blockHistoryGoto>
          <loopStackGoto>
               (. => ListItem(kpair(Num:Int, (K:K ~> Tail:K))))
          ...</loopStackGoto>
          [structural] 
          
     rule [compute-label-poploop]:
          <computation> popLoop => .K ...</computation>
          <loopStackGoto> (_:ListItem => .) ...</loopStackGoto>
          [structural] 
          
     rule <computation> (Label(Target:Id, S:K) => S:K) ~> K:K </computation>
          <computationTail> Tail:K </computationTail>
          <loopStackGoto> LoopStack:List </loopStackGoto>
          <declarationStack> DeclStack:List </declarationStack>
          <br/>
          <gotoMap>...
               kpair(Tu, F) |-> map(
                    (M:Map => M:Map[
                    gotoObject(Depth, BlockHistory, 
                         (S ~> K ~> Tail), LoopStack, DeclStack) 
                    / Target]))
          ...</gotoMap>
          <br/>
          <currentFunction> F:Id </currentFunction>
          <currTU> Tu:K </currTU>
          <nestingDepthGoto> Depth:Int </nestingDepthGoto>
          <blockHistoryGoto> BlockHistory:List </blockHistoryGoto>
          when notBool $hasMapping(M, Target)
          [structural, large]
          
     rule <computation> 
               (Case(SwitchNum:Int, CaseNum:Int, Val:K, S:K) => S:K) ~> K:K
          </computation>
          <computationTail> Tail:K </computationTail>
          <loopStackGoto> LoopStack:List </loopStackGoto>
          <declarationStack> DeclStack:List </declarationStack>
          <br/>
          <gotoMap>... 
               kpair(Tu:K, F:Id) |-> map(
                    (M:Map => (M:Map[
                         case(CaseNum:Int) 
                         / genLabel(SwitchNum:Int, Val:K)])[
                    gotoObject(Depth, BlockHistory,
                         (S ~> K ~> Tail), LoopStack, DeclStack)
                    / case(CaseNum:Int)])) 
          ...</gotoMap>
          <br/>
          <currentFunction> F:Id </currentFunction>
          <currTU> Tu:K </currTU>
          <nestingDepthGoto> Depth:Int </nestingDepthGoto>
          <blockHistoryGoto> BlockHistory:List </blockHistoryGoto>
          when notBool $hasMapping(M:Map, genLabel(SwitchNum:Int, Val:K))
          [structural, large] 
     rule <computation>
               (Default(SwitchNum:Int, S:K) => S:K) ~> K:K
          </computation>
          <computationTail> Tail:K </computationTail>
          <loopStackGoto> LoopStack:List </loopStackGoto>
          <declarationStack> DeclStack:List </declarationStack>
          <br/>
          <gotoMap>... 
               kpair(Tu:K, F:Id) |-> map(
                    (M:Map => M:Map[
                    gotoObject(Depth, BlockHistory,
                         (S ~> K ~> Tail), LoopStack, DeclStack) 
                    / genLabel(SwitchNum:Int, l('Default))])) 
          ...</gotoMap>
          <br/>
          <currentFunction> F:Id </currentFunction>
          <currTU> Tu:K </currTU>
          <nestingDepthGoto> Depth:Int </nestingDepthGoto>
          <blockHistoryGoto> BlockHistory:List </blockHistoryGoto>
          when notBool $hasMapping(M:Map, genLabel(SwitchNum:Int, l('Default)))
          [structural, large]
endmodule
 
