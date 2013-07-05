require "builtins/model-checker.k"

module C11-LTLMC-SYNTAX
     imports LTL-HOOKS
     imports MODEL-CHECKER-HOOKS

     // Ltl atomic propositions.
     syntax CompProp ::= Prop "==" Prop [left]
                       | Prop "!=" Prop [left]

     syntax ValueProp ::= Int | Float | Bool
     syntax BaseProp ::= ValueProp | Id

     syntax Prop ::= CompProp | BaseProp

endmodule

module C11-LTLMC
     imports C11-LTLMC-SYNTAX
     imports C-SYNTAX
     imports C-DYNAMIC-SYNTAX
     imports C-EXPRESSION-SYNTAX
     imports C-TYPING-SYNTAX
     imports C-BITS-SYNTAX
     imports C-BITSIZE-SYNTAX
     imports C-MEMORY-SYNTAX
     imports C-MEMORY-ALLOC-SYNTAX
     imports C-SYMLOC-SYNTAX
     imports COMPAT-SYNTAX

     rule _ |=Ltl false => false 
          [anywhere]
     rule _ |=Ltl true => true 
          [anywhere]
     rule _ |=Ltl 0 => false 
          [anywhere]
     rule _ |=Ltl I:Int => true 
          when I =/=Int 0 
          [anywhere]

     syntax ValueProp ::= ltlEval(Bag, Prop) [function]

     rule B:Bag |=Ltl X:Id => B |=Ltl ltlEval(B, X) 
          [anywhere]
     rule B:Bag |=Ltl P:CompProp => B |=Ltl ltlEval(B, P) 
          [anywhere]
     
     // TODO(chathhorn): really rudimentary.
     rule ltlEval(B:Bag, L:Prop == R:Prop) 
          => true
          when ltlEval(B, L) ==K ltlEval(B, R)
     rule ltlEval(B:Bag, L:Prop == R:Prop) 
          => false
          when ltlEval(B, L) =/=K ltlEval(B, R)

     rule ltlEval(B:Bag, L:Prop != R:Prop) 
          => true
          when ltlEval(B, L) =/=K ltlEval(B, R)
     rule ltlEval(B:Bag, L:Prop != R:Prop) 
          => false
          when ltlEval(B, L) ==K ltlEval(B, R)

     rule ltlEval(_, I:Int) => I
     rule ltlEval(_, B:Bool) => B

     // TODO(chathhorn): In a more perfect world we could use the rules we've
     // already written for this stuff.
     syntax Int ::= dumbRead(Map, SymLoc, Type) [function]
     syntax Int ::= "dumbRead'" "(" Map "," SymLoc "," Type "," Int "," KList ")" 
          [function]

     syntax ValueProp ::= "ltlEvalPrime" "(" Bag "," String ")" [function]

     rule ltlEval(B:Bag, X:Id) => ltlEvalPrime(B, Id2String(X))

     rule ltlEvalPrime(
          <generatedTop>... <T>...
               <genv>... 
                    _ |-> map(_ Identifier(S) |-> Loc:SymLoc) 
               ...</genv>
               <gtypes>... 
                    _ |-> map(_ Identifier(S) |-> T:Type) 
               ...</gtypes>
               <mem> Mem:Map </mem>
          ...</T> ...</generatedTop>, S:String)
          => dumbRead(Mem, Loc, T)

     rule dumbRead(Mem:Map, Loc:SymLoc, T:Type) 
          => dumbRead'(Mem, Loc, unqualifyType(T), 
               bitsToBytes(value(bitSizeofType(T))), .KList)

     rule dumbRead'(
          (_ Base |-> memblock(_, _, (_ Offset |-> V:K))), 
          loc(Base:SymBase, (Offset:Int => Offset +Int 1), _), 
          _, 
          (NBytes:Int => NBytes -Int 1), 
          (_,, (.KList => V)))
          when NBytes >Int 0

     syntax ValueProp ::= joinBytes(KList) [function]
     syntax Int ::= "joinBytes'" "(" KList "," KList ")" [function]
     rule dumbRead'(
          _,
          _,
          _,
          0,
          Bytes:KList)
          => joinBytes(Bytes)

     rule joinBytes(L:KList) => joinBytes'(L, piece(0,0))
     rule joinBytes'((piece(encodedFloat(F:Float), _),, _), _) => F
     rule joinBytes'((L:KList,, 
               piece(N:Int, Len:Int)), piece(N':Int, Len':Int))
          => joinBytes'(L, piece(
               piece(N', Len') bit:: piece(N, Len), Len +Int Len'))

     rule joinBytes'(.KList, piece(N:Int, _)) => N

endmodule
