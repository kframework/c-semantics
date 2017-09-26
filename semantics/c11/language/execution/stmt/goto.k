module C-STMT-GOTO
     imports C-CONFIGURATION
     imports BOOL
     imports K-REFLECTION
     imports C-SYNTAX
     imports C-DYNAMIC-SYNTAX

     syntax CId ::= getIdOfDeclaration(K) [function]
     rule getIdOfDeclaration(declareInternalVariable(X:CId, _, _)) => X
     rule getIdOfDeclaration(typedef(X:CId, _)) => X

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

     syntax KItem ::= processGoto(K)
     syntax KItem ::= processGotoDown(K)

     // declaration stack, actual local variables
     syntax KItem ::= processGotoSameBlock(List, List)
                    | preprocessGoto(K, CId) [function]

     rule <k> Goto(Lbl:CId) ~> _ => preprocessGoto(K, Lbl) </k>
          <curr-scope> blockScope(F:CId, _) </curr-scope>
          <curr-tu> Tu:String </curr-tu>
          <tu-id> Tu </tu-id>
          <goto-map>...
               F |-> K:K
          ...</goto-map>
     rule preprocessGoto(map(M:Map), Lbl:CId)
          => preprocessGoto(M[Lbl], Lbl)
     rule preprocessGoto(GotoInfo:K, Lbl:CId) => processGoto(GotoInfo)
          requires getKLabel(GotoInfo) =/=K #klabel(`map`)
               andBool getKLabel(Lbl) =/=K #klabel(`funLabel`)
     rule preprocessGoto(gotoObject(_, _, Blk:K, _, _), Lbl:CId)
          => Blk
          requires getKLabel(Lbl) ==K #klabel(`funLabel`)

     syntax Bool ::= isGotoKLabel(K) [function, klabelPredicate]
     rule isGotoKLabel(#klabel(`processGoto`)) => true
     rule isGotoKLabel(#klabel(`processGotoDown`)) => true
     rule isGotoKLabel(_) => false [owise]

     // isSuffixOf(A, B) => true if A is a suffix of B
     syntax Bool ::= isSuffixOf(List, List) [function]
     rule isSuffixOf(.List, _) => true
     rule isSuffixOf(ListItem(_) _, .List) => false
     rule isSuffixOf(L:List ListItem(K:K), L':List ListItem(K))
          => isSuffixOf(L, L')
     rule isSuffixOf(_ ListItem(K:K), _ ListItem(K':K)) => false
          requires K =/=K K'

     // - first case, when we're in the same block
     rule <k> L:KLabel(gotoObject(Depth::Int,
                    ListItem(CurrentBlock::Int) BlockHistory::List,
                    K:K, LoopStack::List, DeclStack::List))
               ~> _
               => addVariablesForBlock(CurrentBlock, DeclStack)
               ~> K
          </k>
          <env> Env::Map => rewindEnv(Env', Env, filterIds(CurrentBlock, DeclStack)) </env>
          <nesting-depth> Depth </nesting-depth>
          <block-history>
               ListItem(CurrentBlock) BlockHistory
          </block-history>
          <loop-stack> _ => LoopStack </loop-stack>
          <block-stack>
               ListItem(<block-control>... <env> Env':Map </env> ...</block-control>)
          ...</block-stack>
          requires isGotoKLabel(#klabel(L))
          [structural]

     // - second case, as long as there are entries in the actual block
     // history that differ from the target block history, we need to pop
     rule <k> (.K => popBlock)
               ~> processGoto(gotoObject(_, TargetHistory:List, _, _, _))
          ...</k>
          <block-history>
               ListItem(BlockNum:Int) ActualHistory:List
          </block-history>
          requires notBool BlockNum in TargetHistory
               orBool notBool isSuffixOf(ListItem(BlockNum) ActualHistory, TargetHistory)
          [structural]

     // once we share a history, we start to push
     rule <k> processGoto(gotoObject(TargetDepth:Int,
                    BlockNums:List, K:K, LoopStack:List, DeclStack:List))
               => addVariablesForBlock(CurrentBlock, DeclStack)
               ~> processGotoDown(gotoObject(TargetDepth,
                     (range(BlockNums, 0, size(ActualHistory) +Int 1)
                     ListItem(CurrentBlock) ActualHistory),
                     K, LoopStack, DeclStack))
          ...</k>
          <nesting-depth> ActualDepth:Int </nesting-depth>
          <block-history>
               ListItem(CurrentBlock:Int) ActualHistory:List
          </block-history>
          requires ActualDepth <Int TargetDepth
               andBool isSuffixOf(ActualHistory, BlockNums)
               andBool notBool (ActualHistory ==K BlockNums)
          [structural]

     rule <k> (.K => pushBlock(
                        {BlockNums[-1 -Int size(ActualHist)]}:>Int)
               ~> addVariablesForBlock(
                        {BlockNums[-1 -Int size(ActualHist)]}:>Int, DeclStk)
               ) ~> processGotoDown(gotoObject(TargetDepth:Int,
                    BlockNums:List, _, _,
                    DeclStk:List))
          ...</k>
          <nesting-depth> ActualDepth:Int </nesting-depth>
          <block-history> ActualHist:List </block-history>
          requires ActualDepth <Int TargetDepth
               andBool isSuffixOf(ActualHist, BlockNums)
               andBool notBool (BlockNums ==K ActualHist)
          [structural]

     syntax Map ::= rewindEnv(Map, Map, List) [function]
     rule rewindEnv(Env'::Map => Env'[X <- Env[X]], Env::Map, (ListItem(X:CId) => .List) _)
          requires X in_keys(Env)
     rule rewindEnv(_, _, (ListItem(_) => .List) _) [owise]
     rule rewindEnv(Env'::Map, (K:K |-> _ => .Map) _, .List)
          requires isIdent(K)
     rule rewindEnv(Env'::Map => Env'[K <- V], (K:K |-> V:K => .Map) _, .List)
          requires notBool isIdent(K)
     rule rewindEnv(Env'::Map, .Map, .List) => Env'

     syntax Bool ::= isIdent(K) [function]
     rule isIdent(Identifier(_)) => true
     rule isIdent(_) => false [owise]

     syntax List ::= filterIds(Int, List) [function]
     rule filterIds(B::Int, ListItem(frozenDeclaration(_, B, Decl:K)) Ds::List)
          => ListItem(getIdOfDeclaration(Decl)) filterIds(B, Ds)
     rule filterIds(_, (ListItem(_) => .List) _) [owise]
     rule filterIds(_, .List) => .List

     syntax KItem ::= addVariablesForBlock(Int, List)
          [latex(\terminal{addVarsForBlock}\!({#1},{#2}\!))]

     // skip variables from other blocks
     rule addVariablesForBlock(TargetBlock::Int,
               (ListItem(frozenDeclaration(_, BlockNum::Int, _)) => .List) _)
          requires BlockNum =/=Int TargetBlock
          [structural]

     // skip variables in the real history
     rule <k> addVariablesForBlock(TargetBlock::Int,
                    (ListItem(frozenDeclaration(_, TargetBlock, Decl:K)) => .List) _)
          ...</k>
          <local-vars> Vars:List </local-vars>
          requires getIdOfDeclaration(Decl) in Vars
          [structural]

     rule <k> (.K => Decl ~> enableInits)
               ~> addVariablesForBlock(TargetBlock::Int,
                    (ListItem(frozenDeclaration(_, TargetBlock, Decl:K)) => .List) _)
          ...</k>
          <local-vars> Vars:List </local-vars>
          <should-init> _ => false </should-init>
          requires notBool getIdOfDeclaration(Decl) in Vars
          [structural]

     rule addVariablesForBlock(_, .List) => .K
          [structural]

     syntax KItem ::= "enableInits"

     rule <k> enableInits => .K ...</k>
          <should-init> _ => true </should-init>
          [structural]

endmodule
