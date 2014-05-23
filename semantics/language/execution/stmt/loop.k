module C-STMT-LOOP
     imports C-SYNTAX
     imports C-DYNAMIC-SYNTAX
     imports C-TYPING-SYNTAX
     imports C-ENV-SYNTAX
     imports COMPAT-SYNTAX
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
     
     rule ForClauseExpression(K:K) => Computation(K) [structural]
     
     //  fixme fishy interaction with continue i think
     rule [for-mark]:
          <k> For(ForNum:Int, Pre:K, Control:K, Post:K, S:K) ~> K:K
               => pushBlock 
               ~> addToHistory(ForNum) 
               ~> Pre
               ~> loopMarked 
               ~> For(ForNum, Pre, 
                    (#if Control =/=K emptyValue 
                    #then Control
                    #else tv(1, t(.Set, int)) #fi),
                    Post, S)
               ~> popLoop
          </k>
          <block-history> ListItem(Num:Int) ...</block-history>
          <loop-stack> .List => ListItem(kpair(Num, K)) ...</loop-stack>
          [structural] 
          
     rule [for]:
          <k> loopMarked ~> For(ForNum:Int, Pre:K, Control:K, Post:K, S:K)
               => IfThenElse(Control:K, 
                    (S:K ~> Computation(Post:K) ~> loopMarked 
                    ~> For(ForNum:Int, Pre:K, Control:K, Post:K, S:K)), Nop)
          ...</k>
          <block-history> ListItem(_:Int) ...</block-history>
          [structural] // rule so that looping programs see repetition 

     /*@ \fromStandard{\source[n1570]{\para{6.8.5.1}{1}}}{
     The evaluation of the controlling expression takes place before each
     execution of the loop body.
     }*/
     
     rule [while-mark]:
          <k> 
               While(B:K, S:K) ~> K:K
               => loopMarked 
                    ~> While(B, S) 
                    ~> popLoop
          </k>
          <block-history> ListItem(Num:Int) ...</block-history>
          <loop-stack> .List => ListItem(kpair(Num, K)) ...</loop-stack>
          [structural] 
     rule [while]:
          loopMarked ~> While(B:K, S:K)
          => IfThenElse(B, (S ~> loopMarked ~> While(B, S)), Nop)
          [structural]  // rule so that looping programs see repetition
     
     /*@ \fromStandard{\source[n1570]{\para{6.8.5.2}{1}}}{
     The evaluation of the controlling expression takes place after each
     execution of the loop body.
     }*/
     
     rule [do-while-mark]:
          <k>
               DoWhile(B:K, S:K) ~> K:K
               => loopMarked 
                    ~> DoWhile(B, S) 
                    ~> popLoop
          </k>
          <block-history> ListItem(Num:Int) ...</block-history>
          <loop-stack> .List => ListItem(kpair(Num, K)) ...</loop-stack>
          [structural] 
     rule [do-while]:
          loopMarked ~> DoWhile(B:K, S:K)
          => S ~> IfThenElse(B, (loopMarked ~> DoWhile(B, S)), Nop)
          [structural]  // rule so that looping programs see repetition

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
          (Continue => Computation(Post)) 
          ~> loopMarked 
          ~> For(_:Int, _, _, Post:K, _)
          [structural]
     rule [continue-done]:
          (Continue => .K) ~> loopMarked ~> L:KLabel(_)
          when L =/=KLabel 'For
          [structural]
          
     rule [popLoop]:
          <k> popLoop ~> _ => K </k>
          <block-history> ListItem(Num:Int) ...</block-history>
          <loop-stack> ListItem(kpair(Num:Int, K:K)) => .List ...</loop-stack>
          [structural] 

     rule [popLoop-popBlock]:
          <k> (. => popBlock) ~> popLoop ...</k>
          <block-history> ListItem(Num:Int) ...</block-history>
          <loop-stack> ListItem(kpair(Num':Int, _)) ...</loop-stack>
          when Num' =/=Int Num
          [structural] 
endmodule
