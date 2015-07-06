module C-STMT-BLOCK-SYNTAX
     syntax KItem ::= "deleteLocals"
endmodule

module C-STMT-BLOCK
     imports C-STMT-BLOCK-SYNTAX

     imports C-CHECK-LOC-SYNTAX
     imports C-DYNAMIC-SYNTAX
     imports C-ENV-SYNTAX
     imports C-IO-BUFFERED-SYNTAX
     imports C-SEQUENCE-POINT-SYNTAX
     imports C-SYNTAX

     imports C-CONFIGURATION

     rule <k> pushBlock(Tag:Int)
               => addToHistory(Tag) ~> enterRestrictScope(blockScope(F, Tag))
          ...</k>
          <curr-scope> blockScope(F:CId, (_ => Tag)) </curr-scope>
          <local>
               C:Bag
               <local-vars> Vars:List => .List </local-vars>
               <local-addresses> Addresses:Set => .Set </local-addresses>
               <nesting-depth> N:Int => N:Int +Int 1 </nesting-depth>
          </local>
          <block-stack> .List
               => ListItem(bag2K(<local>
                    C
                    <local-vars> Vars </local-vars>
                    <local-addresses> Addresses </local-addresses>
                    <nesting-depth> N </nesting-depth>
               </local>))
          ...</block-stack>
          [structural]

     rule <k> popBlock => exitRestrictScope(blockScope(F, OldTag)) ...</k>
          <curr-scope> blockScope(F:CId, (OldTag:Int => Tag)) </curr-scope>
          (<local>...
               <block-history> ListItem(Tag:Int) ...</block-history>
               <local-addresses> .Set </local-addresses>
          ...</local> => C)
          <block-stack> ListItem(bag2K(C:Bag)) => .List ...</block-stack>
          [structural]
     rule <k> (.K => deleteLocals) ~> popBlock ...</k>
          <local-addresses>... SetItem(_) ...</local-addresses>
          [structural]

     rule <k> (.K => deleteObject(Base)) ~> deleteLocals ...</k>
          <local-addresses>...
               SetItem(Base:SymBase) => .Set
          ...</local-addresses>
          [structural]
     rule <k> deleteLocals => .K ...</k>
          <local-addresses> .Set </local-addresses>

     /*@ \fromStandard{\source[n1570]{\para{6.8.3}{2}}}{
     The expression in an expression statement is evaluated as a void expression
     for its side effects.
     }*/
     rule Computation(_:RValue) => sequencePoint
          [structural]

     /*@ \fromStandard{\source[n1570]{\para{6.8.3}{3}}}{
     A null statement (consisting of just a semicolon) performs no operations.
     }*/
     rule Nop => .K
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

endmodule
