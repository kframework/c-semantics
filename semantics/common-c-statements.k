require "common-c-semantics.k"

module COMMON-SEMANTICS-STATEMENTS-INCLUDE
     imports COMMON-INCLUDE 
     
     syntax Statement ::= "loopMarked"
     syntax K ::= "genLabel" "(" Int "," K ")" [klabel('genLabel)] //  switchid, value (tv or 'Default)
     syntax K ::= "popLoop"
     syntax K ::= "popBlock"
     syntax K ::= "frozenDeclaration" "(" Int "," Int "," K ")" //  nestingDepth, currentBlock, decl
     syntax K ::= "gotoObject" "(" Int "," List "," K "," List "," List ")" [latex(\terminal{gotoObj}\!({#1},{#2},{#3},{#4},{#5}\!))] //  nestingDepth, block history, continuation, loop stack, decl stack
     syntax K ::= "case" "(" Int ")"
endmodule 


module COMMON-SEMANTICS-PROCESS-LABELS
     imports COMMON-SEMANTICS-STATEMENTS-INCLUDE 
     // now that we can have different strictnesses in different cells, maybe this can be redone easily
/*
     things I have to keep track of:
          in goto map:
               remaining computation
               which variables are allocated on the path
               ...
          in blocks:
               which variables i've allocated so far
     
     I need to adjust the block stack, 
          
     When we goto, we need to take the variables on the goto path and subtract the variables we've already allocated in the real history.  Then we need to declare the remaining variables
          
*/
     
     syntax K ::= "waitingOnGotoMap"
     rule 
          <k> calculateGotoMap(F:Id, K:K) => waitingOnGotoMap ...</k>
          <gotoMap> M:Map => M:Map[Map(.Map) / kpair(Tu:K, F:Id)] </gotoMap>
          <currentFunction> _ => F:Id </currentFunction>
          <currTU> Tu:K </currTU>
          //<br/>
          <calculateGotoMap>
               . => (<gotoCalculation>... <computation> K:K ~> Return(NothingExpression) </computation> ...</gotoCalculation>)
          </calculateGotoMap>
          [structural] 
          
     rule
          (<gotoCalculation> <computation> .K </computation> ...</gotoCalculation>) => .Bag
          [structural] 


     rule
          <k> waitingOnGotoMap => .K ...</k>
          <calculateGotoMap> .Bag </calculateGotoMap>
          <currentFunction> _ => file-scope </currentFunction>
          [structural] 

     syntax K ::= "endBlockForGoto" "(" Int ")"
     rule 
          <computation> 
                  BlockStatement(Blk:K) => Blk:K ~> popBlock
          ...</computation>
          <nestingDepthGoto> N:Int => N:Int +Int 1 </nestingDepthGoto>
          <blockHistoryGoto> ListItem(OldNum:Int) ...</blockHistoryGoto>
          [structural] 
     rule
          <computation> Block(Num:Int, _, klist(L:KList)) => klistToK(L:KList) ...</computation> 
          <blockHistoryGoto> . => ListItem(Num:Int) ...</blockHistoryGoto>
          //  <declarationStack>... .List => ListItem(.K) </declarationStack>
          [structural] 
          
     rule
          <computation> popBlock => .K ...</computation>
          <nestingDepthGoto> I:Int => I:Int -Int 1 </nestingDepthGoto>
          <blockHistoryGoto> (_:ListItem => .List) ListItem(Num:Int) ...</blockHistoryGoto>
          when I:Int >Int 0
          [structural] 
          
     rule [DefinitionLoc-computation]:
          <computation> CodeLoc(K:K, L:CabsLoc) => K:K ...</computation>
          <currentProgramLoc> _ => L:CabsLoc </currentProgramLoc>
          [structural] 

     // this rule is different than the dynamic one because we don't enforce T to be reduced yet
     rule
          <computation> DeclarationDefinition(InitNameGroup(T:K, klist((K:K,, K':K,, L:KList))))
               => DeclarationDefinition(InitNameGroup(T:K, klist(K:K)))
               ~> DeclarationDefinition(InitNameGroup(T:K, klist((K':K,, L:KList))))
          ...</computation>
          [structural]
          
     // rule
          // <computation> Typedef(NameGroup(T:K, klist((K:K,, K':K,, L:KList))))
               // => Typedef(nameGroup-aux(T:K, K:K))
               // ~> Typedef(NameGroup(T:K, klist(K':K,, L:KList)))
          // ...</computation>
          // [structural] 

     //  fixme would like to combine the below rules
     rule
          <computation> DeclarationDefinition(InitNameGroup(T:K, klist(K:K))) => .K ...</computation>
          <br/>
          <declarationStack>... 
               .List 
               => ListItem(frozenDeclaration(Depth:Int, BlockNum:Int, DeclarationDefinition(InitNameGroup(T:K, klist(K:K))))) 
          </declarationStack>
          //<br/>
          <nestingDepthGoto> Depth:Int </nestingDepthGoto>
          <blockHistoryGoto> ListItem(BlockNum:Int) ...</blockHistoryGoto>
          [structural, large]
     // rule
          // <computation> DeclarationDefinition(K:K) => .K ...</computation>
          // <declarationStack>... .List 
               // => ListItem(frozenDeclaration(Depth:Int, BlockNum:Int, DeclarationDefinition(K:K))) 
          // </declarationStack>
          // <nestingDepthGoto> Depth:Int </nestingDepthGoto>
          // <blockHistoryGoto> ListItem(BlockNum:Int) ...</blockHistoryGoto>
          // [structural]
          
     rule
          <computation> OnlyTypedef(K:K) => .K ...</computation>
          <declarationStack>... .List 
               => ListItem(frozenDeclaration(Depth:Int, BlockNum:Int, OnlyTypedef(K:K))) 
          </declarationStack>
          //<br/>
          <nestingDepthGoto> Depth:Int </nestingDepthGoto>
          <blockHistoryGoto> ListItem(BlockNum:Int) ...</blockHistoryGoto>
          [structural] 
          
     rule [compute-label-typedef]:
          <computation> Typedef(K:K) => .K ...</computation>
          <declarationStack>... .List 
               => ListItem(frozenDeclaration(Depth:Int, BlockNum:Int, Typedef(K:K))) 
          </declarationStack>
          //<br/>
          <nestingDepthGoto> Depth:Int </nestingDepthGoto>
          <blockHistoryGoto> ListItem(BlockNum:Int) ...</blockHistoryGoto>
          [structural] 
          
     rule [compute-label-ignore-non-statement]:
          <computation> L:KLabel(Args:KList) => .K ...</computation>
          when false
          orBool L:KLabel ==KLabel 'Nop
          orBool L:KLabel ==KLabel 'Computation
          orBool L:KLabel ==KLabel 'Break
          orBool L:KLabel ==KLabel 'Continue
          orBool L:KLabel ==KLabel 'Return
          orBool L:KLabel ==KLabel 'Goto
          orBool L:KLabel ==KLabel 'CompGoto
          [structural] 
          
     // - should do this with a split
     rule [compute-label-for]:
          <gotoCalculation>
               <computation> (For(ForNum:Int, Pre:K, Control:K, Post:K, S:K) => .K) ~> K:K </computation>
               <computationTail> Tail:K </computationTail>
               <br/>
               B:Bag
               <nestingDepthGoto> N:Int </nestingDepthGoto>
               <blockHistoryGoto> ListItem(Num:Int) OldBlockHistory:List </blockHistoryGoto>
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
                         ~> For(ForNum:Int, Pre:K, (#if Control:K =/=K emptyValue #then Control:K #else tv(1, t(.Set, int)) #fi), Post:K, S:K)
                         ~> popLoop
                         ~> K:K 
                         ~> Tail:K 
                    </computationTail>
                    <br/>
                    B:Bag
                    <nestingDepthGoto> N:Int +Int 1 </nestingDepthGoto>
                    <blockHistoryGoto> ListItem(ForNum:Int) ListItem(Num:Int) OldBlockHistory:List </blockHistoryGoto>
                    <loopStackGoto> ListItem(kpair(Num:Int, (K:K ~> Tail:K))) OldLoopStack:List </loopStackGoto>
               </gotoCalculation>
          )
          [structural, large] 
          
     rule [compute-label-do-while]:
          <gotoCalculation>
               <computation> (DoWhile(E:K, S:K) => .K) ~> K:K </computation>
               <computationTail> Tail:K </computationTail>
               B:Bag
               <blockHistoryGoto> ListItem(Num:Int) OldBlockHistory:List </blockHistoryGoto>
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
                    <blockHistoryGoto> ListItem(Num:Int) OldBlockHistory:List </blockHistoryGoto>
                    <loopStackGoto> ListItem(kpair(Num:Int, (K:K ~> Tail:K))) OldLoopStack:List </loopStackGoto>
               </gotoCalculation>
          )
          [structural, large]
          
     rule [compute-label-while-mark]:
          <computation> (. => S:K ~> loopMarked) ~> While(E:K, S:K) ~> (. => popLoop) ~> K:K </computation>
          //<br/>
          <computationTail> Tail:K </computationTail>
          <blockHistoryGoto> ListItem(Num:Int) ...</blockHistoryGoto>
          <loopStackGoto> (. => ListItem(kpair(Num:Int, (K:K ~> Tail:K)))) ...</loopStackGoto>
          [structural] 
     rule [compute-label-while-done]:
          <computation> (loopMarked ~> While(E:K, S:K) => .K) ~> popLoop ~> K:K </computation>
          [structural] 
          
     rule [compute-label-if-then-else]:
          <gotoCalculation>
               <computation> (IfThenElse(_, S1:K, S2:K) => .K) ~> K:K </computation>
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
          <computation> (Switch(_, E:K, S:K) => S:K ~> popLoop) ~> K:K </computation>
          <computationTail> Tail:K </computationTail>
          <blockHistoryGoto> ListItem(Num:Int) ...</blockHistoryGoto>
          <loopStackGoto> (. => ListItem(kpair(Num:Int, (K:K ~> Tail:K)))) ...</loopStackGoto>
          [structural] 
          
     rule [compute-label-poploop]:
          <computation> popLoop => .K ...</computation>
          <loopStackGoto> (_:ListItem => .) ...</loopStackGoto>
          [structural] 
          
     rule
          <computation> (Label(Target:Id, S:K) => S:K) ~> K:K </computation>
          <computationTail> Tail:K </computationTail>
          <loopStackGoto> LoopStack:List </loopStackGoto>
          <declarationStack> DeclStack:List </declarationStack>
          <br/>
          <gotoMap>... kpair(Tu:K, F:Id) |-> Map((M:Map => M:Map[gotoObject(Depth:Int, BlockHistory:List, (S:K ~> K:K ~> Tail:K), LoopStack:List, DeclStack:List) / Target:Id])) ...</gotoMap>
          <br/>
          <currentFunction> F:Id </currentFunction>
          <currTU> Tu:K </currTU>
          <nestingDepthGoto> Depth:Int </nestingDepthGoto>
          <blockHistoryGoto> BlockHistory:List </blockHistoryGoto>
          when notBool $hasMapping(M:Map, Target:Id)
          [structural, large]
          
     rule
          <computation> (Case(SwitchNum:Int, CaseNum:Int, Val:K, S:K) => S:K) ~> K:K </computation>
          <computationTail> Tail:K </computationTail>
          <loopStackGoto> LoopStack:List </loopStackGoto>
          <declarationStack> DeclStack:List </declarationStack>
          <br/>
          <gotoMap>... 
               kpair(Tu:K, F:Id) |-> Map(
               (M:Map => (M:Map[case(CaseNum:Int) / genLabel(SwitchNum:Int, Val:K)])[gotoObject(Depth:Int, BlockHistory:List, (S:K ~> K:K ~> Tail:K), LoopStack:List, DeclStack:List) / case(CaseNum:Int)])
          ) 
          ...</gotoMap>
          <br/>
          <currentFunction> F:Id </currentFunction>
          <currTU> Tu:K </currTU>
          <nestingDepthGoto> Depth:Int </nestingDepthGoto>
          <blockHistoryGoto> BlockHistory:List </blockHistoryGoto>
          when notBool $hasMapping(M:Map, genLabel(SwitchNum:Int, Val:K))
          //  andBool hasIntegerType(T:KResult)
          [structural, large] 
     rule
          <computation> (Default(SwitchNum:Int, S:K) => S:K) ~> K:K </computation>
          <computationTail> Tail:K </computationTail>
          <loopStackGoto> LoopStack:List </loopStackGoto>
          <declarationStack> DeclStack:List </declarationStack>
          <br/>
          <gotoMap>... 
               kpair(Tu:K, F:Id) |-> Map((M:Map => M:Map[gotoObject(Depth:Int, BlockHistory:List, (S:K ~> K:K ~> Tail:K), LoopStack:List, DeclStack:List) / genLabel(SwitchNum:Int, l('Default))])) 
          ...</gotoMap>
          <br/>
          <currentFunction> F:Id </currentFunction>
          <currTU> Tu:K </currTU>
          <nestingDepthGoto> Depth:Int </nestingDepthGoto>
          <blockHistoryGoto> BlockHistory:List </blockHistoryGoto>
          when notBool $hasMapping(M:Map, genLabel(SwitchNum:Int, l('Default)))
          [structural, large]
endmodule
 
module COMMON-C-STATEMENTS
     imports COMMON-SEMANTICS-STATEMENTS-INCLUDE 
     imports COMMON-SEMANTICS-PROCESS-LABELS
     
endmodule
