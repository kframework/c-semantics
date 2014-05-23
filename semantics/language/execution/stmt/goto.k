module C-STMT-GOTO
     imports C-SYNTAX
     imports C-DYNAMIC-SYNTAX
     imports C-ENV-SYNTAX
     imports COMPAT-SYNTAX

     syntax K ::= getIdOfDeclaration(K) [function]
     syntax K ::= getIdOfName(K) [function]

     rule getIdOfDeclaration(
               DeclarationDefinition(InitNameGroup(_, list(ListItem(K:K)))))
          => getIdOfName(K)

     rule getIdOfName(InitName(K:K, _)) => getIdOfName(K)
     rule getIdOfName(SingleName(_, K:K)) => getIdOfName(K)
     rule getIdOfName(Name(X:CId, _)) => X

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
                         a. Skip any entries in the frozen decl-stack
                         where the nesting-depth is smaller than our current
                         nesting-depth
                         b. All that remains should be variables in the same
                         block as the target
                         c. As we step through the variables in the frozen
                         decl-stack
                              i. any variables we see that we have already
                              declared stay allocated and keep their old value
                              ii. any variables that are in the
                              decl-stack but have not been declared are
                              variables we must allocate but not initialize
                              iii. any variables that have been declared but
                              are not in the decl-stack need to be
                              deallocated
               - Case 2: We are in a different block than the target
                    1. We need to unwind blocks from the blockstack until we're
                    in at nesting-depth 1 less than the nesting depth of the
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
     rule <k> Goto(Lbl:CId) ~> _ => processGoto(GotoInfo) </k>
          <curr-function> F:CId </curr-function>
          <curr-tu> Tu:String </curr-tu>
          <tu-id> Tu </tu-id>
          <goto-map>... 
               F |-> map((_ (Lbl |-> GotoInfo:K))) 
          ...</goto-map>
          when #isFunLabel(Lbl) =/=K true
          [structural]  // rule so that looping programs see repetition
     rule <k> Goto(Lbl:CId) ~> _ => Blk </k>
          <curr-function> F:CId </curr-function>
          <curr-tu> Tu:String </curr-tu>
          <tu-id> Tu </tu-id>
          <goto-map>... 
               F |-> map(_ Lbl |-> gotoObject(_, _, Blk:K, _, _))
          ...</goto-map>
          when #isFunLabel(Lbl) ==K true

     syntax Bool ::= "#isFunLabel" "(" CId ")" [function]
     rule #isFunLabel(funLabel(_)) => true
          
     // - first case, when we're in the same block
     rule <k> L:KLabel(gotoObject(Depth:Int, 
                    (ListItem(CurrentBlock:Int) BlockHistory:List), 
                    K:K, LoopStack:List, DeclStack:List)) 
                    ~> _ 
               => addVariablesForBlock(CurrentBlock, DeclStack)
                    ~> K
          </k>
          <nesting-depth> Depth:Int </nesting-depth>
          <block-history> 
               ListItem(CurrentBlock:Int) BlockHistory:List
          </block-history>
          <loop-stack> _ => LoopStack </loop-stack>
          when (L ==KLabel 'processGoto)
               orBool (L ==KLabel 'processGotoDown)
          [structural] 
          
     // - second case, we're in a different block
     
     //  as long as there are entries in the actual block history that differ
     //  from the target block history, we need to pop
     rule [processGoto-pop-differing-1]:
          <k> (. => popBlock) 
               ~> processGoto(gotoObject(
                    _:Int, TargetBlockHistory:List, _, _, _))
          ...</k>
          <block-history> 
               ListItem(BlockNum:Int) _:List
          </block-history>
          when notBool BlockNum in TargetBlockHistory
          [structural] 
          
     //  same
     rule [processGoto-pop-differing-2]:
          <k> (. => popBlock) 
               ~> processGoto(gotoObject(_:Int, 
                    _:List ListItem(BlockNum:Int)
                    TargetBlockHistory:List, _, _, _))
          ...</k>
          <block-history>
               ListItem(BlockNum:Int) ActualHistory:List
          </block-history>
          when TargetBlockHistory =/=List ActualHistory
          [structural] 
               
     //  once we share a history, we start to push
     rule <k> processGoto(gotoObject(TargetDepth:Int, 
                    (Prefix:List ListItem(_:Int) ActualHistory:List),
                    K:K, LoopStack:List, DeclStack:List))
               => addVariablesForBlock(CurrentBlock, DeclStack)
                    ~> processGotoDown(gotoObject(TargetDepth, 
                         (Prefix ListItem(CurrentBlock) ActualHistory),
                         K, LoopStack, DeclStack))
          ...</k>
          <nesting-depth> ActualDepth:Int </nesting-depth>
          <block-history>
               ListItem(CurrentBlock:Int) ActualHistory:List
          </block-history>
          when ActualDepth +Int 1 =/=Int TargetDepth
          [structural] 
          
     rule <k> ( . => pushBlock
               ~> addToHistory(TargetBlk)
               ~> addVariablesForBlock(TargetBlk, DeclStk)
               ) ~> processGotoDown(gotoObject(TargetDepth:Int, 
                    (_ ListItem(TargetBlk:Int) ActualHist:List), _, _,
                    DeclStk:List))
          ...</k>
          <nesting-depth> ActualDepth:Int </nesting-depth>
          <block-history> ActualHist:List </block-history>
          when ActualDepth +Int 1 =/=Int TargetDepth
          [structural] 
     
     //  We've made it to the block above the target
     rule <k> L:KLabel(gotoObject(SIntDepth:Int, 
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
          <nesting-depth> Depth:Int </nesting-depth>
          <block-history> BlockHistory:List </block-history>
          <loop-stack> _ => LoopStack </loop-stack>
          when ((L ==KLabel 'processGoto)
               orBool (L ==KLabel 'processGotoDown))
               andBool (SIntDepth ==Int Depth +Int 1)
          [structural] 
          
     syntax K ::= addVariablesForBlock(Int, List)
          [latex(\terminal{addVarsForBlock}\!({#1},{#2}\!))] 
     
     //  skip variables from other blocks
     rule <k> addVariablesForBlock(TargetBlock:Int, 
                    ((ListItem(frozenDeclaration(_:Int, BlockNum:Int, _)) => .)
                    _:List)
               )
          ...</k>
          <block-history> ListItem(TargetBlock:Int) ...</block-history>
          when BlockNum =/=Int TargetBlock
          [structural] 
          
     //  skip variables in the real history
     rule <k> addVariablesForBlock(TargetBlock:Int,
                    ((ListItem(frozenDeclaration(
                         _:Int, TargetBlock:Int, Decl:K)) => .)
                    _:List)
               )
          ...</k>
          <local-vars> Vars:List </local-vars>
          <block-history> ListItem(TargetBlock:Int) ...</block-history>
          when getIdOfDeclaration(Decl) in Vars
          [structural]
     
     syntax K ::= "enableInits"
     
     rule <k> enableInits => . ...</k>
          <should-init> _ => true </should-init>
          [structural] 
     
     rule <k> (. => Decl:K
                    ~> enableInits
               )
               ~> addVariablesForBlock(TargetBlock:Int, 
                    ((ListItem(frozenDeclaration(
                         _:Int, TargetBlock:Int, Decl:K)) => .List) _)
               )
          ...</k>
          <local-vars> Vars:List </local-vars>
          <block-history> ListItem(TargetBlock:Int) ...</block-history>
          <should-init> _ => false </should-init>
          when notBool getIdOfDeclaration(Decl) in Vars
          [structural]
          
     //  fixme this is wrong
     rule addVariablesForBlock(_:Int, .List) => .
          [structural] 

endmodule
