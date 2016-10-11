module CPP-STMT-BLOCK-SYNTAX
     syntax KItem ::= "deleteLocals"
endmodule

module CPP-STMT-BLOCK
     imports CPP-STMT-BLOCK-SYNTAX
     imports C-CONFIGURATION
     imports INT
     imports C-CHECK-LOC-SYNTAX
     imports C-IO-BUFFERED-SYNTAX
     imports CPP-DYNAMIC-SYNTAX
     imports CPP-ENV-SYNTAX

     rule <k> pushBlock(Tag:Int)
               => addToHistory(Tag) ~> enterRestrictScope(blockScope(F, Base, Tag))
          ...</k>
          <curr-scope> blockScope(F::QualId, Base::SymBase, (_ => Tag)) </curr-scope>
          <block-control>
               C::Bag
               <local-vars> Vars::List => .List </local-vars>
               <local-addresses> Addresses::Set => .Set </local-addresses>
               <nesting-depth> N::Int => N +Int 1 </nesting-depth>
          </block-control>
          <block-stack> .List
               => ListItem(<block-control>
                    C
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

     rule <k> popBlock => updateScope ~> exitRestrictScope(blockScope(F, Base, OldTag)) ...</k>
          <curr-scope> blockScope(F::QualId, Base::SymBase, OldTag::Int) </curr-scope>
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

endmodule
