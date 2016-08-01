module C-STMT-BLOCK-SYNTAX
     syntax KItem ::= "deleteLocals"
endmodule

module C-STMT-BLOCK
     imports C-STMT-BLOCK-SYNTAX
     imports C-CONFIGURATION
     imports INT
     imports C-CHECK-LOC-SYNTAX
     imports C-DYNAMIC-SYNTAX
     imports C-ENV-SYNTAX
     imports C-IO-BUFFERED-SYNTAX

     rule <k> pushBlock(Tag:Int)
               => addToHistory(Tag) ~> enterRestrictScope(blockScope(F, Tag))
          ...</k>
          <curr-scope> blockScope(F:CId, (_ => Tag)) </curr-scope>
          <block-control>
               C:Bag
               <local-vars> Vars:List => .List </local-vars>
               <local-addresses> Addresses:Set => .Set </local-addresses>
               <nesting-depth> N:Int => N:Int +Int 1 </nesting-depth>
          </block-control>
          <block-stack> .List
               => ListItem(<block-control>
                    C
                    <local-vars> Vars </local-vars>
                    <local-addresses> Addresses </local-addresses>
                    <nesting-depth> N </nesting-depth>
               </block-control>)
          ...</block-stack>
          [structural]

     syntax KItem ::= "updateScope"

     rule <k> updateScope => .K ...</k>
          <curr-scope> blockScope(_, (_ => Tag)) </curr-scope>
          <block-history> ListItem(Tag:Int) ...</block-history>
     rule <k> updateScope => .K ...</k>
          <curr-scope> blockScope(_, (_ => 0)) </curr-scope>
          <block-history> .List </block-history>

     rule <k> popBlock => updateScope ~> exitRestrictScope(blockScope(F, OldTag)) ...</k>
          <curr-scope> blockScope(F:CId, OldTag:Int) </curr-scope>
          (<block-control>...
               <local-addresses> .Set </local-addresses>
          ...</block-control> => C)
          <block-stack> ListItem(C:BlockControlCell) => .List ...</block-stack>
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
