require "builtins/model-checker.k"

module C-LTLMC-SYNTAX
     imports LTL-HOOKS
     imports MODEL-CHECKER-HOOKS

     // Ltl atomic propositions.
     syntax ValueProp ::= Int  
                        | ptr(SymLoc, Type) 
                        | struct(KList, Id)
                        | union(KList, Id)

     syntax CProp ::= ValueProp | Id 
                    | "-" CProp
                    | "+" CProp
                    | "*" CProp
                    > CProp "[" CProp "]"
                    | CProp "." Id
                    | CProp "->" Id
                    > CProp "*" CProp [left]
                    | CProp "/" CProp [left]
                    > CProp "+" CProp [left]
                    | CProp "-" CProp [left]
                    > CProp "<" CProp [left]
                    | CProp "<=" CProp [left]
                    | CProp ">" CProp [left]
                    | CProp ">=" CProp [left]
                    > CProp "==" CProp [left]
                    | CProp "!=" CProp [left]

     syntax Prop ::= CProp | Bool | "__running" | "__error"

endmodule

module C-LTLMC
     imports C-LTLMC-SYNTAX
     imports C-SYNTAX
     imports C-DYNAMIC-SYNTAX
     imports C-TYPING-SYNTAX
     imports C-BITS-SYNTAX
     imports C-BITSIZE-SYNTAX
     imports C-DECL-INITIALIZER-SYNTAX

     imports C-MEMORY-ALLOC-SYNTAX
     imports C-MEMORY-READING-SYNTAX
     imports C-MEMORY-WRITING-SYNTAX

     imports C-SYMLOC-SYNTAX
     imports COMPAT-SYNTAX

     rule B:Bag |=Ltl P:CProp => boolify(ltlRVal(B, P))
          [anywhere]
     rule B:Bag |=Ltl __running => #running(B) ==K true
          [anywhere]
     rule B:Bag |=Ltl __error => #error(B) ==K true
          [anywhere]
     rule _ |=Ltl P:Bool => P
          [anywhere]

     syntax Bool ::= boolify(ValueProp) [function]
     rule boolify(I:Int) => notBool (I ==Int 0)

     syntax Int ::= intify(Bool) [function]
     rule intify(false) => 0
     rule intify(true) => 1

     syntax Bool ::= "#running" "(" Bag ")" [function]
     rule #running(
          <generatedTop>... 
               <status> mainCalled </status> 
          ...</generatedTop>)
          => true

     syntax Bool ::= "#error" "(" Bag ")" [function]
     rule #error(
          <generatedTop>... <T>...
               <errorCell> _ </errorCell> 
          ...</T> ...</generatedTop>)
          => true
     
     syntax ValueProp ::= ltlRVal(Bag, Prop) [function]

     // TODO(chathhorn): Very basic rewrite of C expression semantics. It'd be
     // nice to be able to re-use more of the actual semantics for this...
     rule ltlRVal(_, V:ValueProp) => V

     rule ltlRVal(B:Bag, - P:CProp) 
          => ltlRVal(B, 0 - ltlRVal(B, P))
     rule ltlRVal(B:Bag, + P:CProp) 
          => ltlRVal(B, P)
     rule ltlRVal(B:Bag, L:CProp[R:CProp])
          => ltlRVal(B, * (L + R))
     
     // I don't really think & is necessary.
     // rule ltlRVal(B:Bag, & P:CProp) 
     //      => ltlLVal(B, P)

     // "strictness"
     rule ltlRVal(B:Bag, _:KLabel(P:CProp => ltlRVal(B, P)))
          when notBool (isValueProp(P) ==K true)
     rule ltlRVal(B:Bag, _:KLabel((L:CProp => ltlRVal(B, L)),, _))
          when notBool (isValueProp(L) ==K true)
     rule ltlRVal(B:Bag, Lbl:KLabel(_,, (R:CProp => ltlRVal(B, R))))
          when notBool (isValueProp(R) ==K true)
               // Don't try resolving the field specifier.
               andBool (Lbl =/=KLabel '_._)
               andBool (Lbl =/=KLabel '_->_)

     rule ltlRVal(B:Bag, * ptr(L:SymLoc, T:Type))
          => ltlRVal(B, dumbRead(B, L, T))

     rule ltlRVal(B:Bag, P:CProp -> X:Id)
          => ltlRVal(B, (* P) . X)

     rule ltlRVal(
          <generatedTop>... <T>... <gstructs>...
               S |-> aggregateInfo(_,
                    (_ X |-> T:Type),
                    (_ X |-> Offset:Int))
          ...</gstructs> ...</T> ...</generatedTop>,
          struct(V:KList, S:Id) . X:Id)
          => joinBytes(T, 
               fillToBytes-aux(
                    extractBitsFromList-aux(
                         dataList(explodeToBits(V)), 
                         Offset, value(bitSizeofType(T)), .KList),
                    .KList))
     rule ltlRVal(
          <generatedTop>... <T>... <gstructs>...
               S |-> aggregateInfo(_,
                    (_ X |-> T:Type),
                    (_ X |-> Offset:Int))
          ...</gstructs> ...</T> ...</generatedTop>,
          union(V:KList, S:Id) . X:Id)
          => joinBytes(T, 
               fillToBytes-aux(
                    extractBitsFromList-aux(
                         dataList(explodeToBits(V)), 
                         Offset, value(bitSizeofType(T)), .KList),
                    .KList))

     rule ltlRVal(_, L:Int * R:Int) => L *Int R
     rule ltlRVal(_, L:Int / R:Int) => L /Int R
     rule ltlRVal(_, L:Int + R:Int) => L +Int R
     rule ltlRVal(_, L:Int - R:Int) => L -Int R

     rule ltlRVal(_, L:Int < R:Int) => intify(L <Int R)
     rule ltlRVal(_, L:Int <= R:Int) => intify(L <=Int R)
     rule ltlRVal(_, L:Int < R:Int) => intify(L >Int R)
     rule ltlRVal(_, L:Int <= R:Int) => intify(L >=Int R)

     rule ltlRVal(_, L:Int == R:Int) => intify(L ==Int R)
     rule ltlRVal(_, L:Int != R:Int) => intify(L ==Int R)

     syntax Int ::= dumbRead(Bag, SymLoc, Type) [function]
     syntax Int ::= "dumbRead'" "(" Map "," SymLoc "," Type "," Int "," KList ")" 
          [function]

     rule ltlRVal(B:Bag, X:Id) => ltlRVal(B, * ltlLVal(B, X))

     // TODO(chathhorn): need to rework how bitSizeofType() functions in order
     // to actually support structs/unions here.
     rule dumbRead(
               <generatedTop>... <T>... 
                    <mem> Mem:Map </mem> 
               ...</T> ...</generatedTop>, 
               Loc:SymLoc, T:Type) 
          => dumbRead'(Mem, Loc, T, value(byteSizeofType(T)), .KList)

     rule dumbRead'(
          (_ Base |-> memblock(_, _, (_ Offset |-> V:K))), 
          loc(Base:SymBase, (Offset:Int => Offset +Int 1), _), 
          _, 
          (NBytes:Int => NBytes -Int 1), 
          (_,, (.KList => V)))
          when NBytes >Int 0

     syntax ValueProp ::= joinBytes(Type, KList) [function]
     syntax ValueProp ::= "joinBytes'" "(" Type "," KList "," KList ")" [function]
     rule dumbRead'(
          _,
          _,
          T:Type,
          0,
          Bytes:KList)
          => joinBytes(T, Bytes)

     rule joinBytes(T:Type, L:KList) => joinBytes'(T, L, piece(0,0))

     rule joinBytes(t(_, pointerType(T:Type)), 
               (piece(subObject(L:SymLoc, _, _), _),, _:KList))
          => ptr(L, T)
     rule joinBytes(t(_, structType(S:Id)), V:KList)
          => struct(V, S)
     rule joinBytes(t(_, unionType(S:Id)), V:KList)
          => union(V, S)
     rule joinBytes(T:Type, V:KList) => joinBytes'(T, V, .KList)
          when hasIntegerType(T)

     rule joinBytes'(T:Type, (L:KList,, 
               piece(N:Int, Len:Int)), piece(N':Int, Len':Int))
          => joinBytes'(T, L, piece(
               piece(N', Len') bit:: piece(N, Len), Len +Int Len'))

     rule joinBytes'(_, .KList, piece(N:Int, _)) => N

     // Not so interested in l-values.
     syntax ValueProp ::= "ltlLVal" "(" Bag "," Id ")" [function]
     syntax ValueProp ::= "ltlLVal'" "(" Bag "," String ")" [function]

     rule ltlLVal(B:Bag, X:Id) => ltlLVal'(B, Id2String(X))
     rule ltlLVal'(
          <generatedTop>... <T>...
               <genv>... 
                    Identifier(S) |-> Loc:SymLoc
               ...</genv>
               <gtypes>... 
                    Identifier(S) |-> T:Type
               ...</gtypes>
          ...</T> ...</generatedTop>, 
          S:String)
          => ptr(Loc, unqualifyType(T))

endmodule
