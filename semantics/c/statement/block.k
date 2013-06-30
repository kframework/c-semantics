module C-STATEMENT-BLOCK-SYNTAX
     syntax K ::= "pushBlock"
     syntax K ::= "popBlock"
endmodule

module C-STATEMENT-BLOCK
     imports C-STATEMENT-BLOCK-SYNTAX

     imports C-SYNTAX
     imports C-DYNAMIC-SYNTAX
     imports C-COMPAT-SYNTAX
     imports C-MEMORY-SYNTAX

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
