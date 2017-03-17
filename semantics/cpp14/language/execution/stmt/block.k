module CPP-STMT-BLOCK
     imports C-CONFIGURATION
     imports INT
     imports C-CHECK-LOC-SYNTAX
     imports C-IO-BUFFERED-SYNTAX
     imports CPP-DYNAMIC-SYNTAX
     imports CPP-ENV-SYNTAX

     rule <k> pushBlock(Tag:Int)
               => addToHistory(Tag) ~> enterRestrictBlock(blockScope(F, Base, Tag))
          ...</k>
          <curr-scope> blockScope(F::QualId, Base::SymBase, (_ => Tag)) </curr-scope>
          <block-control>
               C::Bag
               <catch-handlers> Catch::List => .List </catch-handlers>
               <local-vars> Vars::List => .List </local-vars>
               <local-addresses> Addresses::Set => .Set </local-addresses>
               <nesting-depth> N::Int => N +Int 1 </nesting-depth>
          </block-control>
          <block-stack> .List
               => ListItem(<block-control>
                    C
                    <catch-handlers> Catch </catch-handlers>
                    <local-vars> Vars </local-vars>
                    <local-addresses> Addresses </local-addresses>
                    <nesting-depth> N </nesting-depth>
               </block-control>)
          ...</block-stack>

     syntax KItem ::= "updateScope"

     rule <k> updateScope => .K ...</k>
          <curr-scope> blockScope(_, _, (_ => Tag)) </curr-scope>
          <block-history> ListItem(Tag::Int) ...</block-history>
     rule <k> updateScope => .K ...</k>
          <curr-scope> blockScope(_, _, (_ => 0)) </curr-scope>
          <block-history> .List </block-history>

     rule <k> popBlock => deleteObjects(Locals) ~> exitRestrictBlock(Locals) ~> updateScope ...</k>
          (<block-control>...
               <local-addresses> Locals::Set </local-addresses>
          ...</block-control> => C)
          <block-stack> ListItem(C:BlockControlCell) => .List ...</block-stack>
          [structural]

endmodule
