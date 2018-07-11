module C-STMT-BLOCK
     imports C-CONFIGURATION
     imports INT
     imports C-CHECK-RESTRICT-SYNTAX
     imports C-DYNAMIC-SYNTAX
     imports C-IO-SYNTAX
     imports DELETE-OBJECT-SYNTAX

     rule <k> pushBlock(Tag:Int)
               => enterRestrictBlock(blockScope(F, Tag))
          ...</k>
          <curr-tu> Tu::String </curr-tu>
          <curr-scope> blockScope(F:CId, (_ => Tag)) </curr-scope>
          <block-control>
               C::Bag
               <local-vars> Vars:Set => .Set </local-vars>
               <local-addresses> Addresses:Set => .Set </local-addresses>
               <block-history> History:List => ListItem(Tag) History </block-history>
          </block-control>
          <block-stack> .List
               => ListItem(<block-control>
                    C
                    <local-vars> Vars </local-vars>
                    <local-addresses> Addresses </local-addresses>
                    <block-history> History </block-history>
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

     rule <k> popBlock => deleteObjects(Locals) ~> exitRestrictBlock(Locals) ~> updateScope ...</k>
          (<block-control>...
               <local-addresses> Locals::Set </local-addresses>
          ...</block-control> => C)
          <block-stack> ListItem(C:BlockControlCell) => .List ...</block-stack>
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
