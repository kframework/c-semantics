require "dynamic-c-semantics.k"

module DYNAMIC-SEMANTICS-STATEMENTS-INCLUDE
     imports COMMON-SEMANTICS-STATEMENTS-INCLUDE
     imports COMMON-SEMANTIC-SYNTAX
     imports C-SETTINGS
     imports C-COMPAT-SYNTAX
     imports C-HELPERS
     imports URIS
     imports C-CONFIGURATION

     syntax K ::= "pushBlock"
     syntax K ::= "addToHistory" "(" Int ")"
          [latex(\terminal{addToHist}\!({#1}\!))]
endmodule 

module DYNAMIC-SEMANTICS-LABELED-STATEMENTS
     imports DYNAMIC-SEMANTICS-STATEMENTS-INCLUDE

     /*@ \fromStandard{\source[n1570]{\para{6.8.1}{4}}}{
     Any statement may be preceded by a prefix that declares an identifier as a
     label name. Labels in themselves do not alter the flow of control, which
     continues unimpeded across them.
     }*/
     rule [skip-label]: 
          Label(_:Id, K:K) => K
          [structural]
     rule [case-fall-through]:
          Case(_:Int, _:Int, _, K:K) => K
          [structural] 
     rule [default-fall-through]:
          Default(_:Int, K:K) => K
          [structural] 
endmodule


module DYNAMIC-SEMANTICS-BLOCKS
     imports DYNAMIC-SEMANTICS-STATEMENTS-INCLUDE
     
     /*@ \fromStandard{\source[n1570]{\para{6.8.2}{2}}}{
     A \emph{compound statement} is a block.
     }*/
     rule BlockStatement(B:K)
          => pushBlock ~> B ~> popBlock
          [structural]
          
     rule [push-block]:
          <k> pushBlock => . ...</k>
          <local>
               C:Bag
               <localVariables> Vars:List => .List </localVariables>
               <localAddresses> Addresses:Set => .Set </localAddresses>
               <nestingDepth> N:Int => N:Int +Int 1 </nestingDepth>
          </local>
          <br/>
          <blockStack> .List 
               => ListItem(C:Bag 
               <nestingDepth> N:Int </nestingDepth> 
               <localVariables> Vars:List </localVariables>
               <localAddresses> Addresses:Set </localAddresses>)
          ...</blockStack>
          [structural, large] 
          
     rule [pop-block-free-memory]:
          <k> (.K => deleteBlock(Loc:SymLoc)) ~> popBlock ...</k>
          <localAddresses>... (SetItem(Loc) => .Set) ...</localAddresses>
          [structural] 
          
     rule [pop-block]:
          <k> popBlock => . ...</k>
          <local>
               (_ => C:Bag)
               (<localAddresses> .Set </localAddresses> => .Bag)
          </local>
          <blockStack> 
               ListItem(C:Bag) => .List 
          ...</blockStack>
          [structural] 
          
     /*@ \fromStandard{\source[n1570]{\para{6.8.3}{2}}}{
     The expression in an expression statement is evaluated as a void expression
     for its side effects.
     }*/
     rule [expression-statement]:
          Computation(_:KResult) => sequencePoint
          [structural]

     /*@ \fromStandard{\source[n1570]{\para{6.8.3}{3}}}{
     A null statement (consisting of just a semicolon) performs no operations.
     }*/
     rule Nop => .
          [structural]
     
     /*@ \fromStandard{\source[n1570]{\para{6.8}{3}}}{
     A block allows a set of declarations and statements to be grouped into one
     syntactic unit.  The initializers of objects that have automatic storage
     duration, and the variable length array declarators of ordinary identifiers
     with block scope, are evaluated and the values are stored in the objects
     (imports storing an indeterminate value in objects without an initializer)
     each time the declaration is reached in the order of execution, as if it
     were a statement, and within each declaration in the order that declarators
     appear.
     }*/
     rule [dissolve-block]:
          <k> 
               Block(BlockNum:Int, _, klist(Statements:KList))
               => klistToK(Statements:KList)
          ...</k>
          <blockHistory> .List => ListItem(BlockNum:Int) ...</blockHistory>
          [structural]
endmodule
          
module DYNAMIC-SEMANTICS-IF-THEN
     imports DYNAMIC-SEMANTICS-STATEMENTS-INCLUDE 
          
     /*@ \fromStandard{\source[n1570]{\para{6.8}{4}}}{
     \ldots There is a sequence point between the evaluation of a full
     expression and the evaluation of the next full expression to be evaluated.
     }*/
          
     /*@ \fromStandard{\source[n1570]{\para{6.8.4.1}{10}}}{
     In both forms, the first substatement is executed if the expression
     compares unequal to 0. In the \cinline{else} form, the second substatement
     is executed if the expression compares equal to 0. If the first
     substatement is reached via a label, the second substatement is not
     executed.
     }*/

     rule [if-then-else-true]:
          IfThenElse(tv(1, t(_, int)), S:K, _) => sequencePoint ~> S
          [structural]
     rule [if-then-else-false]:
          IfThenElse(tv(0, t(_, int)), _, S:K) => sequencePoint ~> S
          [structural]
     rule IfThenElse((V:KResult => simplifyTruth(V:KResult)), _, _)
          when isNotTruthValue(V:KResult)
          [structural]
endmodule

module DYNAMIC-SEMANTICS-SWITCH
     imports DYNAMIC-SEMANTICS-STATEMENTS-INCLUDE 
     
     //  fixme shouldn't there be sequence points here?
     //  fixme not doing promoting or conversion
     
     // switch num, promoted value of controlling exp, int value of exp
     syntax K ::= "handleSwitch" "(" Int "," K ")" [strict(2)] 
     syntax K ::= "handleSwitch-aux" "(" K "," Value "," K ")"
     
     /*@ \fromStandard{\source[n1570]{\para{6.8.4.2}{4}}}{
     A \cinline{switch} statement causes control to jump to, into, or past the
     statement that is the \emph{switch body}, depending on the value of a
     controlling expression, and on the presence of a \cinline{default} label
     and the values of any \cinline{case} labels on or in the switch body. A
     \cinline{case} or \cinline{default} label is accessible only within the
     closest enclosing \cinline{switch} statement.
     }
     
     \fromStandard{\source[n1570]{\para{6.8.4.2}{5}}}{
     The integer promotions are performed on the controlling expression. The
     constant expression in each \cinline{case} label is converted to the
     promoted type of the controlling expression. If a converted value matches
     that of the promoted controlling expression, control jumps to the statement
     following the matched \cinline{case} label. Otherwise, if there is a
     default label, control jumps to the labeled statement. If no converted
     \cinline{case} constant expression matches and there is no
     \cinline{default} label, no part of the switch body is executed.
     }*/
     
     rule Switch(SN:Int, tv(V:K, T:KResult), _)
          => sequencePoint 
          ~> handleSwitch(SN:Int, cast(promote(T:KResult), tv(V:K, T:KResult))) 
          when hasIntegerType(T:KResult)
          [structural] 
          
     rule <k> handleSwitch(SN:Int, V:KResult) 
               => handleSwitch-aux(SN:Int, V:KResult, map(M:Map)) 
          ...</k>
          <currentFunction> F:Id </currentFunction>
          <currTU> Tu:K </currTU>
          <gotoMap>... kpair(Tu:K, F:Id) |-> map(M:Map) ...</gotoMap>
          [structural] 
          
     // K to be evaluated, val it should be, casehelper
     syntax K ::= "tryCase" "(" K "," Value "," K ")"
     context tryCase((HOLE => reval(HOLE)), _, _)
     rule (. => tryCase(Exp:K, V:KResult, CaseHelper:K)) 
          ~> handleSwitch-aux(SN:Int, V:KResult,
               map((_ ((genLabel(SN:Int, Exp:K) |-> CaseHelper:K) => .Map))))
          when Exp:K =/=K l('Default)
          [structural] 
          
     //  if all that's left is a default, do it
     rule handleSwitch-aux(SN:Int, _, map((genLabel(SN:Int, l('Default)) |-> _))) 
          => Goto(genLabel(SN:Int, l('Default)))
          [structural] 
     
     //  if there's nothing left, no case matches
     rule handleSwitch-aux(_, _, map(.Map)) => .
          [structural] 
          
     rule handleSwitch-aux(SN:Int, _,
               map((_ ((genLabel(SN':Int, _) |-> _) => .Map))))
          when SN:Int =/=Int SN':Int
          [structural] 
     rule handleSwitch-aux(_:Int, _, map((_ ((L:KLabel(_) |-> _) => .Map))))
          when L:KLabel =/=KLabel 'genLabel
          [structural] 

     rule tryCase((tv(V:K, T':KResult)
          => cast(T:KResult, tv(V:K, T':KResult))), tv(_, T:KResult), _)
          when T:KResult =/=K T':KResult
          [structural]
     rule tryCase(tv(V':K, T:KResult), tv(V:K, T:KResult), _) => .
          when V:K =/=K V':K
          [structural] 
     //  match found in value and type, goto it
     //  don't need to erase the rest of K since we're GOTOing
     rule tryCase(V:KResult, V:KResult, CaseHelper:K) => Goto(CaseHelper:K)
          [structural]
endmodule

module DYNAMIC-SEMANTICS-WHILE
     imports DYNAMIC-SEMANTICS-STATEMENTS-INCLUDE 
     
     /*@ \fromStandard{\source[n1570]{\para{6.8.5.1}{1}}}{
     The evaluation of the controlling expression takes place before each
     execution of the loop body.
     }*/
     
     rule [while-mark]:
          <k> While(B:K, S:K) ~> K:K
               => loopMarked 
               ~> While(B:K, S:K) 
               ~> popLoop
          </k>
          <blockHistory> ListItem(Num:Int) ...</blockHistory>
          <loopStack> .List => ListItem(kpair(Num:Int, K:K)) ...</loopStack>
          [structural] 
     rule [while]:
          loopMarked ~> While(B:K, S:K)
          => IfThenElse(B:K, (S:K ~> loopMarked ~> While(B:K, S:K)), Nop)
          [structural]  // rule so that looping programs see repetition
endmodule

module DYNAMIC-SEMANTICS-DO-WHILE
     imports DYNAMIC-SEMANTICS-STATEMENTS-INCLUDE 
     
     /*@ \fromStandard{\source[n1570]{\para{6.8.5.2}{1}}}{
     The evaluation of the controlling expression takes place after each
     execution of the loop body.
     }*/
     
     rule [do-while-mark]:
          <k> DoWhile(B:K, S:K) ~> K:K
               => loopMarked 
               ~> DoWhile(B:K, S:K) 
               ~> popLoop
          </k>
          <blockHistory> ListItem(Num:Int) ...</blockHistory>
          <loopStack> .List => ListItem(kpair(Num:Int, K:K)) ...</loopStack>
          [structural] 
     rule [do-while]:
          loopMarked ~> DoWhile(B:K, S:K)
          => S:K ~> IfThenElse(B:K, (loopMarked ~> DoWhile(B:K, S:K)), Nop)
          [structural]  // rule so that looping programs see repetition
endmodule

module DYNAMIC-SEMANTICS-FOR
     imports DYNAMIC-SEMANTICS-STATEMENTS-INCLUDE 
     
     /*@ \fromStandard{\source[n1570]{\para{6.8.5.2}{1}}}{
     The statement 
     \cdisplay{for ( $\textit{clause-1}$ ; $\textit{expression-2}$ ;
     $\textit{expression-3}$ ) $\textit{statement}$ } behaves as follows: The
     expression $\textit{expression-2}$ is the controlling expression that is
     evaluated before each execution of the loop body. The expression
     $\textit{expression-3}$ is evaluated as a void expression after each
     execution of the loop body. If $\textit{clause-1}$ is a declaration, the
     scope of any identifiers it declares is the remainder of the declaration
     and the entire loop, imports the other two expressions; it is reached in
     the order of execution before the first evaluation of the controlling
     expression. If $\textit{clause-1}$ is an expression, it is evaluated as a
     void expression before the first evaluation of the controlling expression.
     }
     
     \fromStandard{\source[n1570]{\para{6.8.5.2}{1}}}{
     Both $\textit{clause-1}$ and $\textit{expression-3}$ can be omitted. An
     omitted $\textit{expression-2}$ is replaced by a nonzero constant.
     }*/
     
     rule ForClauseExpression(K:K) => Computation(K:K) [structural]
     
     rule <k> addToHistory(Num:Int) => .K ...</k>
          <blockHistory> .List => ListItem(Num:Int) ...</blockHistory>
          [structural] 
     
     //  fixme fishy interaction with continue i think
     rule [for-mark]:
          <k> (For(ForNum:Int, Pre:K, Control:K, Post:K, S:K) ~> K:K
               => pushBlock 
               ~> addToHistory(ForNum:Int) 
               ~> Pre:K 
               ~> loopMarked 
               ~> For(ForNum:Int, Pre:K, 
                    (#if Control:K =/=K emptyValue 
                    #then Control:K 
                    #else tv(1, t(.Set, int)) #fi),
                    Post:K, S:K)
               ~> popLoop)
          </k>
          <br/>
          <blockHistory> ListItem(Num:Int) ...</blockHistory>
          <loopStack> .List => ListItem(kpair(Num:Int, K:K)) ...</loopStack>
          [structural, large] 
          
     rule [for]:
          <k> loopMarked ~> For(ForNum:Int, Pre:K, Control:K, Post:K, S:K)
               => IfThenElse(Control:K, 
                    (S:K ~> Computation(Post:K) ~> loopMarked 
                    ~> For(ForNum:Int, Pre:K, Control:K, Post:K, S:K)), Nop)
          ...</k>
          <blockHistory> ListItem(_:Int) ...</blockHistory>
          [structural] // rule so that looping programs see repetition 
endmodule

module DYNAMIC-SEMANTICS-GOTO
     imports DYNAMIC-SEMANTICS-STATEMENTS-INCLUDE 
     
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

     syntax K ::= "processGoto" "(" K ")" [klabel('processGoto)]
     syntax K ::= "processGotoDown" "(" K ")" [klabel('processGotoDown)] 

     // declaration stack, actual local variables
     syntax K ::= "processGotoSameBlock" "(" List "," List ")"
     rule <k> Goto(Lbl:K) ~> _ => processGoto(GotoInfo:K) </k>
          <currentFunction> F:Id </currentFunction>
          <currTU> Tu:K </currTU>
          <gotoMap>... 
               kpair(Tu:K, F:Id) |-> map((_ (Lbl:K |-> GotoInfo:K))) 
          ...</gotoMap>
          [structural]  // rule so that looping programs see repetition
          
     // - first case, when we're in the same block
     rule <k> 
               L:KLabel(gotoObject(Depth:Int, 
                    (ListItem(CurrentBlock:Int) BlockHistory:List), 
                    K:K, LoopStack:List, DeclStack:List)) 
                    ~> _ 
               => addVariablesForBlock(CurrentBlock:Int, DeclStack:List)
                    ~> K:K
          </k>
          <nestingDepth> Depth:Int </nestingDepth>
          <blockHistory> 
               ListItem(CurrentBlock:Int) BlockHistory:List
          </blockHistory>
          <loopStack> _ => LoopStack:List </loopStack>
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
          when notBool BlockNum:Int in TargetBlockHistory:List
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
          when TargetBlockHistory:List =/=List ActualHistory:List
          [structural] 
               
     //  once we share a history, we start to push
     rule <k> 
               processGoto(gotoObject(TargetDepth:Int, 
                    (Prefix:List ListItem(_:Int) ActualHistory:List),
                    K:K, LoopStack:List, DeclStack:List))
               => addVariablesForBlock(CurrentBlock:Int, DeclStack:List)
                    ~> processGotoDown(gotoObject(TargetDepth:Int, 
                         (Prefix ListItem(CurrentBlock) ActualHistory),
                         K:K, LoopStack:List, DeclStack:List))
          ...</k>
          <br/>
          <nestingDepth> ActualDepth:Int </nestingDepth>
          <blockHistory>
               ListItem(CurrentBlock:Int) ActualHistory:List
          </blockHistory>
          when ActualDepth:Int +Int 1 =/=Int TargetDepth:Int
          [structural, large] 
          
     rule <k> 
               ( . => pushBlock
               ~> addToHistory(TargetBlk:Int)
               ~> addVariablesForBlock(TargetBlk:Int, DeclStk:List)
               ) ~> processGotoDown(gotoObject(TargetDepth:Int, 
                    (_ ListItem(TargetBlk:Int) ActualHist:List), _, _,
                    DeclStk:List))
          ...</k>
          <br/>
          <nestingDepth> ActualDepth:Int </nestingDepth>
          <blockHistory> ActualHist:List </blockHistory>
          when ActualDepth:Int +Int 1 =/=Int TargetDepth:Int
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
                    ~> addToHistory(TargetBlock:Int)
                    ~> addVariablesForBlock(TargetBlock:Int, DeclStack:List)
                    ~> K:K
          </k>
          <nestingDepth> Depth:Int </nestingDepth>
          <blockHistory> BlockHistory:List </blockHistory>
          <loopStack> _ => LoopStack:List </loopStack>
          when ((L:KLabel ==KLabel 'processGoto)
          orBool (L:KLabel ==KLabel 'processGotoDown))
          andBool (SIntDepth:Int ==Int Depth:Int +Int 1)
          [structural] 
          
     syntax K ::= "addVariablesForBlock" "(" Int "," List ")"
          [latex(\terminal{addVarsForBlock}\!({#1},{#2}\!))] 
     
     //  skip variables from other blocks
     rule <k> 
               addVariablesForBlock(TargetBlock:Int, 
                    ((ListItem(frozenDeclaration(_:Int, BlockNum:Int, _)) => .)
                    _:List)
               )
          ...</k>
          <blockHistory> ListItem(TargetBlock:Int) ...</blockHistory>
          when BlockNum:Int =/=Int TargetBlock:Int
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
          when getIdOfDeclaration(Decl:K) in Vars:List
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
          when notBool getIdOfDeclaration(Decl:K) in Vars:List
          [structural]
          
     //  fixme this is wrong
     rule addVariablesForBlock(_:Int, .List) => .
          [structural] 

endmodule

module DYNAMIC-SEMANTICS-CONTINUE
     imports DYNAMIC-SEMANTICS-STATEMENTS-INCLUDE 

     /*@
     \begin{lrbox}{\LstBox}
     \begin{minipage}{0.5\linewidth}
     \begin{lstlisting}[multicols=3]
     while (...) {
          ...
          continue;
          ...
          contin: ;
     }

     do {
          ...
          continue;
          ...
          contin: ;
     } while (...);

     for (...) {
          ...
          continue;
          ...
          contin: ;
     }
     \end{lstlisting}
     \end{minipage}
     \end{lrbox}
     \fromStandard{\source[n1570]{\para{6.8.6.2}{2}}}{
     A \cinline{continue} statement causes a jump to the loop-continuation
     portion of the smallest enclosing iteration statement; that is, to the end
     of the loop body. More precisely, in each of the statements\\
     \usebox{\LstBox}\\
     unless the \cinline{continue} statement shown is in an enclosed iteration
     statement (in which case it is interpreted within that statement), it is
     equivalent to \cinline{goto contin;}.
     }
     */
     rule [continue]:
          Continue ~> ((L:KLabel)(_) => .)
          when (L =/=KLabel 'loopMarked)
               andBool (L =/=KLabel 'popBlock)
               andBool (L =/=KLabel 'pushBlock)
               andBool (L =/=KLabel 'popLoop)
          [structural]
     rule [continue-through-pop]:
          Continue ~> popBlock 
          => popBlock ~> Continue
          [structural]

     rule [continue-done-for]:
          (Continue => Computation(Post:K)) 
          ~> loopMarked 
          ~> For(_:Int, _, _, Post:K, _)
          [structural]
     rule [continue-done]:
          (Continue => .K) ~> loopMarked ~> L:KLabel(_)
          when L:KLabel =/=KLabel 'For
          [structural]
          
endmodule

module DYNAMIC-SEMANTICS-BREAK
     imports DYNAMIC-SEMANTICS-STATEMENTS-INCLUDE
     /*@ \fromStandard{\source[n1570]{\para{6.8.6.3}{2}}}{
     A break statement terminates execution of the smallest enclosing switch or
     iteration statement.
     }*/
     rule [break]:
          Break => popLoop
          [structural] 
endmodule

module DYNAMIC-SEMANTICS-RETURN
     imports DYNAMIC-SEMANTICS-STATEMENTS-INCLUDE

     /*@ \fromStandard{\source[n1570]{\para{6.8.6.4}{2}}}{
     A \cinline{return} statement terminates execution of the current function
     and returns control to its caller. A function may have any number of
     \cinline{return} statements.
     }
     
     \fromStandard{\source[n1570]{\para{6.8.6.4}{3}}}{
     If a \cinline{return} statement with an expression is executed, the value
     of the expression is returned to the caller as the value of the function
     call expression. If the expression has a type different from the return
     type of the function in which it appears, the value is converted as if by
     assignment to an object having the return type of the function.
     }*/
     
     rule [return-clean-local]:
          <k> (.K => deleteBlock(Loc:SymLoc)) ~> Return(_:KResult) ...</k>
          <localAddresses>... SetItem(Loc) => .Set ...</localAddresses>     
          [structural] 
          
     rule [fetch-all-locals]:
          <k> Return(_:KResult) ...</k>
          <localAddresses> .Set => Addresses:Set </localAddresses>
          <blockStack> 
               ListItem(_ <localAddresses> Addresses:Set </localAddresses>)
               => .List
          ...</blockStack>
          [structural] 

     //  this is used for returns with no return value as well, since we return
     //  "emptyValue", which will hopefully be cast to void
     rule [return]: 
          <k> Return(V:KResult) ~> _
               => sequencePoint 
               ~> cast(T:KResult, V:KResult) 
               ~> K:K
          </k>
          <gtypes>... 
               Tu:K |-> map((_ (F:Id |-> t(_, functionType(T:KResult, _))))) 
          ...</gtypes>
          <br/>
          <control>
               //  these cells get replaced by the ones in C:Bag, so we can
               //  delete them when we match them
               (<local>... <localAddresses> .Set </localAddresses> ...</local> 
               => .Bag)
               <currentFunction> (F:Id => CurrFun:K) </currentFunction>
               <currentProgramLoc> _ => CurrLoc:K </currentProgramLoc>
               (<currTU> Tu:K </currTU> => .Bag)
               (<blockStack> .List </blockStack> => .Bag)
               (_ => C:Bag)
          </control>
          <br/>
          <callStack>
               ListItem(
                    <callStackFrame>...
                         <continuation> K:K </continuation>
                         <stackControl>C:Bag</stackControl>
                         <stackCurrentFunction>
                              CurrFun:K
                         </stackCurrentFunction>
                         <stackCurrentProgramLoc> 
                              CurrLoc:K
                         </stackCurrentProgramLoc>
                    ...</callStackFrame>
               ) => .List
          ...</callStack>
          [structural, large] 
endmodule

module DYNAMIC-SEMANTICS-STATEMENTS-MISC
     imports DYNAMIC-SEMANTICS-STATEMENTS-INCLUDE
     
     rule [popLoop]:
          <k> popLoop ~> _ => K:K </k>
          <blockHistory> ListItem(Num:Int) ...</blockHistory>
          <loopStack> ListItem(kpair(Num:Int, K:K)) => .List ...</loopStack>
          [structural] 

     rule [popLoop-popBlock]:
          <k> (. => popBlock) ~> popLoop ...</k>
          <blockHistory> ListItem(Num:Int) ...</blockHistory>
          <loopStack> ListItem(kpair(Num':Int, _)) ...</loopStack>
          when Num':Int =/=Int Num:Int
          [structural] 
endmodule

module DYNAMIC-C-STATEMENTS
     imports DYNAMIC-SEMANTICS-STATEMENTS-INCLUDE
     imports DYNAMIC-SEMANTICS-LABELED-STATEMENTS
     imports DYNAMIC-SEMANTICS-IF-THEN 
     imports DYNAMIC-SEMANTICS-FOR 
     imports DYNAMIC-SEMANTICS-WHILE 
     imports DYNAMIC-SEMANTICS-SWITCH 
     imports DYNAMIC-SEMANTICS-GOTO 
     imports DYNAMIC-SEMANTICS-RETURN 
     imports DYNAMIC-SEMANTICS-BLOCKS 
     imports DYNAMIC-SEMANTICS-DO-WHILE 
     imports DYNAMIC-SEMANTICS-CONTINUE
     imports DYNAMIC-SEMANTICS-BREAK
     imports DYNAMIC-SEMANTICS-STATEMENTS-MISC
endmodule
