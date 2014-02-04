module C-STMT-GOTO
     imports C-STMT-LOOP-SYNTAX

     imports C-SYNTAX
     imports C-DYNAMIC-SYNTAX
     imports COMPAT-SYNTAX

     syntax K ::= getIdOfDeclaration(K) [function]
     syntax K ::= getIdOfName(K) [function]

     rule getIdOfDeclaration(
               DeclarationDefinition(InitNameGroup(_, list(ListItem(K:K)))))
          => getIdOfName(K)

     rule getIdOfName(InitName(K:K, _)) => getIdOfName(K)
     rule getIdOfName(SingleName(_, K:K)) => getIdOfName(K)
     rule getIdOfName(Name(X:Id, _)) => X

     /*@ \fromStandard{\source[n1570]{\para{6.8.6.1}{2}}}{
     A \cinline{goto} statement causes an unconditional jump to the statement
     prefixed by the named label in the enclosing function.
     }*/
     
     //  fixme CONFIRM It seems there are no sequence points for a goto
     
     /*@ \fromStandard{\source[n1570]{\para{6.2.4}{6}}}{
     For such an object that does not have a variable length array type, its
     lifetime extends from entry into the block with which it is associated
     until execution of that block ends in any way. (Entering an enclosed block
     or calling a function suspends, but does not end, execution of the current
     block.) If the block is entered recursively, a new instance of the object
     is created each time. The initial value of the object is indeterminate. If
     an initialization is specified for the object, it is performed each time
     the declaration or compound literal is reached in the execution of the
     block; otherwise, the value becomes indeterminate each time the
     declaration is reached.
     }*/
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

     /* 
          To do the actual goto:
               - Case 1: We are in the same block as the target
                    1. We might be jumping forwards or backwards, across
                    declarations, so we need to figure out which variables
                    should be left alone, allocated but not initialized, or
                    deallocated
                         a. Skip any entries in the frozen declarationStack
                         where the nestingDepth is smaller than our current
                         nestingDepth
                         b. All that remains should be variables in the same
                         block as the target
                         c. As we step through the variables in the frozen
                         declarationStack
                              i. any variables we see that we have already
                              declared stay allocated and keep their old value
                              ii. any variables that are in the
                              declarationStack but have not been declared are
                              variables we must allocate but not initialize
                              iii. any variables that have been declared but
                              are not in the declarationStack need to be
                              deallocated
               - Case 2: We are in a different block than the target
                    1. We need to unwind blocks from the blockstack until we're
                    in at nestingDepth 1 less than the nesting depth of the
                    target
                         a. for each block we pop, we need to unallocate the
                         memory
                         b. once we're at the right place, we enter the block
                         and then proceed similarly to case 1, except all the
                         cases will be to allocate and not initialize
          
          The variables mentioned above are meant to be those with automatic
          storage duration.  Variables with external or static storage duration
          have their own rules
                    
     */

     syntax K ::= processGoto(K) [klabel('processGoto)]
     syntax K ::= processGotoDown(K) [klabel('processGotoDown)] 

     // declaration stack, actual local variables
     syntax K ::= processGotoSameBlock(List, List)
     rule <k> Goto(Lbl:K) ~> _ => processGoto(GotoInfo) </k>
          <currentFunction> F:Id </currentFunction>
          <currTU> Tu:String </currTU>
          <tu-id> Tu </tu-id>
          <goto-map>... 
               F |-> map((_ (Lbl |-> GotoInfo:K))) 
          ...</goto-map>
          [structural]  // rule so that looping programs see repetition
          
     // - first case, when we're in the same block
     rule <k> 
               L:KLabel(gotoObject(Depth:Int, 
                    (ListItem(CurrentBlock:Int) BlockHistory:List), 
                    K:K, LoopStack:List, DeclStack:List)) 
                    ~> _ 
               => addVariablesForBlock(CurrentBlock, DeclStack)
                    ~> K
          </k>
          <nestingDepth> Depth:Int </nestingDepth>
          <blockHistory> 
               ListItem(CurrentBlock:Int) BlockHistory:List
          </blockHistory>
          <loopStack> _ => LoopStack </loopStack>
          when (L ==KLabel 'processGoto)
               orBool (L ==KLabel 'processGotoDown)
          [structural] 
          
     // - second case, we're in a different block
     
     //  as long as there are entries in the actual block history that differ
     //  from the target block history, we need to pop
     rule [processGoto-pop-differing-1]:
          <k> 
               (. => popBlock) 
               ~> processGoto(gotoObject(
                    _:Int, TargetBlockHistory:List, _, _, _))
          ...</k>
          <blockHistory> 
               ListItem(BlockNum:Int) _:List
          </blockHistory>
          when notBool BlockNum in TargetBlockHistory
          [structural] 
          
     //  same
     rule [processGoto-pop-differing-2]:
          <k> 
               (. => popBlock) 
               ~> processGoto(gotoObject(_:Int, 
                    _:List ListItem(BlockNum:Int)
                    TargetBlockHistory:List, _, _, _))
          ...</k>
          <blockHistory>
               ListItem(BlockNum:Int) ActualHistory:List
          </blockHistory>
          when TargetBlockHistory =/=List ActualHistory
          [structural] 
               
     //  once we share a history, we start to push
     rule <k> 
               processGoto(gotoObject(TargetDepth:Int, 
                    (Prefix:List ListItem(_:Int) ActualHistory:List),
                    K:K, LoopStack:List, DeclStack:List))
               => addVariablesForBlock(CurrentBlock, DeclStack)
                    ~> processGotoDown(gotoObject(TargetDepth, 
                         (Prefix ListItem(CurrentBlock) ActualHistory),
                         K, LoopStack, DeclStack))
          ...</k>
          <nestingDepth> ActualDepth:Int </nestingDepth>
          <blockHistory>
               ListItem(CurrentBlock:Int) ActualHistory:List
          </blockHistory>
          when ActualDepth +Int 1 =/=Int TargetDepth
          [structural, large] 
          
     rule <k> 
               ( . => pushBlock
               ~> addToHistory(TargetBlk)
               ~> addVariablesForBlock(TargetBlk, DeclStk)
               ) ~> processGotoDown(gotoObject(TargetDepth:Int, 
                    (_ ListItem(TargetBlk:Int) ActualHist:List), _, _,
                    DeclStk:List))
          ...</k>
          <nestingDepth> ActualDepth:Int </nestingDepth>
          <blockHistory> ActualHist:List </blockHistory>
          when ActualDepth +Int 1 =/=Int TargetDepth
          [structural, large] 
     
     //  We've made it to the block above the target
     rule <k> 
               L:KLabel(gotoObject(SIntDepth:Int, 
                    (ListItem(TargetBlock:Int) BlockHistory:List),
                    K:K, 
                    LoopStack:List, 
                    DeclStack:List)
               ) 
                    ~> _
               => pushBlock
                    ~> addToHistory(TargetBlock)
                    ~> addVariablesForBlock(TargetBlock, DeclStack)
                    ~> K
          </k>
          <nestingDepth> Depth:Int </nestingDepth>
          <blockHistory> BlockHistory:List </blockHistory>
          <loopStack> _ => LoopStack </loopStack>
          when ((L ==KLabel 'processGoto)
               orBool (L ==KLabel 'processGotoDown))
               andBool (SIntDepth ==Int Depth +Int 1)
          [structural] 
          
     syntax K ::= addVariablesForBlock(Int, List)
          [latex(\terminal{addVarsForBlock}\!({#1},{#2}\!))] 
     
     //  skip variables from other blocks
     rule <k> 
               addVariablesForBlock(TargetBlock:Int, 
                    ((ListItem(frozenDeclaration(_:Int, BlockNum:Int, _)) => .)
                    _:List)
               )
          ...</k>
          <blockHistory> ListItem(TargetBlock:Int) ...</blockHistory>
          when BlockNum =/=Int TargetBlock
          [structural] 
          
     //  skip variables in the real history
     rule <k> 
               addVariablesForBlock(TargetBlock:Int,
                    ((ListItem(frozenDeclaration(
                         _:Int, TargetBlock:Int, Decl:K)) => .)
                    _:List)
               )
          ...</k>
          <localVariables> Vars:List </localVariables>
          <blockHistory> ListItem(TargetBlock:Int) ...</blockHistory>
          when getIdOfDeclaration(Decl) in Vars
          [structural]
     
     syntax K ::= "enableInits"
     
     rule <k> enableInits => . ...</k>
          <shouldInit> _ => true </shouldInit>
          [structural] 
     
     rule <k> (. => Decl:K
                    ~> enableInits
               )
               ~> addVariablesForBlock(TargetBlock:Int, 
                    ((ListItem(frozenDeclaration(
                         _:Int, TargetBlock:Int, Decl:K)) => .List) _)
               )
          ...</k>
          <localVariables> Vars:List </localVariables>
          <blockHistory> ListItem(TargetBlock:Int) ...</blockHistory>
          <shouldInit> _ => false </shouldInit>
          when notBool getIdOfDeclaration(Decl) in Vars
          [structural]
          
     //  fixme this is wrong
     rule addVariablesForBlock(_:Int, .List) => .
          [structural] 

endmodule
