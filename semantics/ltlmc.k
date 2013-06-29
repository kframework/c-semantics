require "builtins/model-checker.k"

module C-LTLMC
     imports C-DYNAMIC-SYNTAX 
     imports C-COMPAT-SYNTAX

     imports MODEL-CHECKER-HOOKS

     syntax Prop ::= Expression // Ltl atomic propositions.
     syntax K ::= LtlEval(Bag, K) [function]

     rule _ |=Ltl false => false 
          [anywhere]
     rule _ |=Ltl true => true 
          [anywhere]
     rule _ |=Ltl tv(0, _) => false 
          [anywhere]
     rule _ |=Ltl tv(I:Int, _) => true 
          when I =/=Int 0 
          [anywhere]
     rule B:Bag |=Ltl X:Expression => B |=Ltl LtlEval(B, X) 
          when getKLabel(X) =/=KLabel 'tv
          [anywhere]
     
     // TODO(chathhorn): really rudimentary, must be a better way.
     rule LtlEval(B:Bag, L:K == R:K) 
          => LtlEval(B, LtlEval(B, L) == LtlEval(B, R))
          when getKLabel(L) =/=KLabel 'tv
               andBool getKLabel(R) =/=KLabel 'tv
     rule LtlEval(B:Bag, L:K == R:K) 
          => LtlEval(B, LtlEval(B, L) == R)
          when getKLabel(L) =/=KLabel 'tv
               andBool getKLabel(R) ==KLabel 'tv
     rule LtlEval(B:Bag, L:K == R:K) 
          => LtlEval(B, L == LtlEval(B, R))
          when getKLabel(L) ==KLabel 'tv
               andBool getKLabel(R) =/=KLabel 'tv
     rule LtlEval(_, tv(X:K, _) == tv(Y:K, _))
          => true
          when X ==K Y
     rule LtlEval(_, tv(X:K, _) == tv(Y:K, _))
          => false
          when X =/=K Y

     rule LtlEval(B:Bag, L:K != R:K) 
          => LtlEval(B, LtlEval(B, L) != LtlEval(B, R))
          when getKLabel(L) =/=KLabel 'tv
               andBool getKLabel(R) =/=KLabel 'tv
     rule LtlEval(B:Bag, L:K != R:K) 
          => LtlEval(B, LtlEval(B, L) != R)
          when getKLabel(L) =/=KLabel 'tv
               andBool getKLabel(R) ==KLabel 'tv
     rule LtlEval(B:Bag, L:K != R:K) 
          => LtlEval(B, L != LtlEval(B, R))
          when getKLabel(L) ==KLabel 'tv
               andBool getKLabel(R) =/=KLabel 'tv
     rule LtlEval(_, tv(X:K, _) != tv(Y:K, _))
          => false
          when X ==K Y
     rule LtlEval(_, tv(X:K, _) != tv(Y:K, _))
          => true
          when X =/=K Y

     rule LtlEval(
          <generatedTop>... 
               <env>... Identifier(S) |-> Loc:SymLoc ...</env>
               <types>... Identifier(S) |-> T:Type ...</types>
          ...</generatedTop>, 
          #token("#Id",, S:String))
          => rkludge(lval(Loc, T))

     syntax K ::= LtlEval(Bag, Expression)


endmodule
