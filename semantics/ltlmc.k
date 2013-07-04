require "builtins/model-checker.k"

module C11-LTLMC
     imports C-SYNTAX
     imports C-DYNAMIC-SYNTAX
     imports C-EXPRESSION-SYNTAX
     imports COMPAT-SYNTAX

     imports LTL-HOOKS
     imports MODEL-CHECKER-HOOKS

     // Ltl atomic propositions.
     syntax CompProp ::= Prop "==Ltl" Prop [left]
                         | Prop "!=Ltl" Prop [left]

     syntax BaseProp ::= Int | Bool | Id

     syntax Prop ::= CompProp | BaseProp

     syntax BaseProp ::= LtlEval(Bag, Prop) [function]

     rule _ |=Ltl false => false 
          [anywhere]
     rule _ |=Ltl true => true 
          [anywhere]
     rule _ |=Ltl 0 => false 
          [anywhere]
     rule _ |=Ltl I:Int => true 
          when I =/=Int 0 
          [anywhere]

     rule B:Bag |=Ltl X:Id => B |=Ltl LtlEval(B, X) 
          [anywhere]
     rule B:Bag |=Ltl P:CompProp => B |=Ltl LtlEval(B, P) 
          [anywhere]
     
     // TODO(chathhorn): really rudimentary.
     rule LtlEval(B:Bag, L:Prop ==Ltl R:Prop) 
          => true
          when LtlEval(B, L) ==K LtlEval(B, R)
     rule LtlEval(B:Bag, L:Prop ==Ltl R:Prop) 
          => false
          when LtlEval(B, L) =/=K LtlEval(B, R)

     rule LtlEval(B:Bag, L:Prop !=Ltl R:Prop) 
          => true
          when LtlEval(B, L) =/=K LtlEval(B, R)
     rule LtlEval(B:Bag, L:Prop !=Ltl R:Prop) 
          => false
          when LtlEval(B, L) ==K LtlEval(B, R)

     rule LtlEval(_, I:Int) => I
     rule LtlEval(_, B:Bool) => B
     rule LtlEval(
          <generatedTop>... 
               <env>... Identifier(S) |-> Loc:SymLoc ...</env>
               <types>... Identifier(S) |-> T:Type ...</types>
          ...</generatedTop>, 
          #token("#Id",, S:String))
          => value(rkludge(lval(Loc, T)))

endmodule
