module C-STMT-BLOCK
     imports C-CHECK-LOC-SYNTAX
     imports C-SYNTAX
     imports C-DYNAMIC-SYNTAX
     imports C-IO-BUFFERED-SYNTAX
     imports C-SEQUENCE-POINT-SYNTAX
     imports COMPAT-SYNTAX

     /*@ \fromStandard{\source[n1570]{\para{6.8.2}{2}}}{
     A \emph{compound statement} is a block.
     }*/
     rule BlockStatement(B:K)
          => pushBlock ~> B ~> popBlock
          [structural]

     rule <k> pushBlock => . ...</k>
          <local>
               C:Bag
               <local-vars> Vars:List => .List </local-vars>
               <local-addresses> Addresses:Set => .Set </local-addresses>
               <nesting-depth> N:Int => N:Int +Int 1 </nesting-depth>
          </local>
          <block-stack> .List
               => ListItem(C
               <local-vars> Vars </local-vars>
               <local-addresses> Addresses </local-addresses>
               <nesting-depth> N </nesting-depth>)
          ...</block-stack>
          [structural]

     rule <k> (.K => deleteObject(Base)) ~> popBlock ...</k>
          <local-addresses>...
               (SetItem(Base:SymBase) => .Set)
          ...</local-addresses>
          [structural]

     rule <k> popBlock => . ...</k>
          <local>
               (_ => C)
               (<local-addresses> .Set </local-addresses> => .Bag)
          </local>
          <block-stack>
               ListItem(C:Bag) => .List
          ...</block-stack>
          [structural]

     /*@ \fromStandard{\source[n1570]{\para{6.8.3}{2}}}{
     The expression in an expression statement is evaluated as a void expression
     for its side effects.
     }*/
     rule Computation(_:KResult) => sequencePoint
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
     rule <k> Block(BlockNum:Int, _, list(Statements:List))
               => enterRestrictScope(BlockNum)
               ~> listToK(Statements)
               ~> exitRestrictScope(BlockNum)
          ...</k>
          <block-history> .List => ListItem(BlockNum) ...</block-history>
          [structural]

endmodule
