require "builtins/model-checker.k"

module C-LTLMC-SYNTAX
     imports LTL-HOOKS
     imports MODEL-CHECKER-HOOKS
     imports C-BITS-SYNTAX

     // Ltl atomic propositions.
     syntax ValueProp ::= Int
                        | #ptr(SymLoc, Type)
                        | #struct(List, FieldInfo)
                        | #union(List, FieldInfo)

     syntax CProp ::= ValueProp | CId
                    | "-" CProp
                    | "+" CProp
                    | "*" CProp
                    > CProp "[" CProp "]"
                    | CProp "." CId
                    | CProp "->" CId
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
     imports C-ENV-SYNTAX
     imports C-BITSIZE-SYNTAX
     imports C-DECL-INITIALIZER-SYNTAX

     imports C-MEMORY-ALLOC-SYNTAX
     imports C-MEMORY-READING-SYNTAX
     imports C-MEMORY-WRITING-SYNTAX

     imports C-SYMLOC-SYNTAX
     imports C-SETTINGS-SYNTAX
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

     syntax Bool ::= #running(Bag) [function]
     rule #running(
          <generatedTop>...
               <status> mainCalled </status>
          ...</generatedTop>)
          => true

     syntax Bool ::= #error(Bag) [function]
     rule #error(
          <generatedTop>... <T>...
               <error-cell> _ </error-cell>
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

     /*TODO(liyili2): cannot handle this, maybe this is not needed
     rule ltlRVal(B:Bag, L:CProp[R:CProp])
          => ltlRVal(B, * (L + R))
     */

     // I don't really think & is necessary.
     // rule ltlRVal(B:Bag, & P:CProp)
     //      => ltlLVal(B, P)

     // "strictness"
     /*TODO(liyili2): cannot handle this cases
     rule ltlRVal(B:Bag, L:KLabel(P:CProp))
          => ltlRVal(B, L(ltlRVal(B, P)))
          requires notBool (isValueProp(P:CProp) ==K true)
     rule ltlRVal(B:Bag, M:KLabel(L:CProp,, KL:KList))
          => ltlRVal(B, M(ltlRVal(B, L),, KL))
          requires notBool (isValueProp(L:CProp) ==K true)
     rule ltlRVal(B:Bag, Lbl:KLabel(KL:KList,, R:CProp))
          => ltlRVal(B, Lbl(KL,, ltlRVal(B, R)))
          requires notBool (isValueProp(R:CProp) ==K true)
               // Don't try resolving the field specifier.
               andBool (Lbl =/=KLabel '_._)
               andBool (Lbl =/=KLabel '_->_)
     */
     rule ltlRVal(B:Bag, * #ptr(L:SymLoc, T:Type))
          => ltlRVal(B, dumbRead(B, L, T))

     /*TODO(liyili2): cannot handle this
     rule ltlRVal(B:Bag, P:CProp -> X:CId)
          => ltlRVal(B, (* P) . X)
     */

     rule ltlRVal(_,
          #struct(V:List,
               fieldInfo(_, _, (_ X |-> T:Type), (_ X |-> Offset:Int))
          ) . X:CId)
          => joinBytes(T,
               fillToBytes-aux(
                    extractBitsFromList-aux(
                         dataList(explodeToBits(V)),
                         Offset *Int cfg:bitsPerByte,
                         bitSizeofType(T), .List),
                    .List))
     rule ltlRVal(_,
          #union(V:List,
               fieldInfo(_, _, (_ X |-> T:Type), (_ X |-> Offset:Int))
          ) . X:CId)
          => joinBytes(T,
               fillToBytes-aux(
                    extractBitsFromList-aux(
                         dataList(explodeToBits(V)),
                         Offset, bitSizeofType(T), .List),
                    .List))

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

     syntax ValueProp ::= dumbRead(Bag, SymLoc, Type) [function]
     syntax ValueProp ::= "dumbRead'" "(" Map "," SymLoc "," Type "," Int "," List ")"
          [function]
     /*TODO(liyili2): cannot handle this cases
     rule ltlRVal(B:Bag, X:CId) => ltlRVal(B, * ltlLVal(B, X))
     */
     rule dumbRead(
               <generatedTop>... <T>...
                    <mem> Mem:Map </mem>
               ...</T> ...</generatedTop>,
               Loc:SymLoc, T:Type)
          => dumbRead'(Mem, stripProv(Loc), T, byteSizeofType(T), .List)

     rule dumbRead'(
               (BaseMap:Map (Base |-> object(OT:Type, OI:Int, (OffMap:Map (Offset |-> V:K))))),
               loc(Base:SymBase, (Offset:Int)),
               TT:Type,
               (NBytes:Int),
               VL:List)
          => dumbRead'(
               (BaseMap (Base |-> object(OT, OI, (OffMap (Offset |-> V))))),
               loc(Base, (Offset +Int 1)),
               TT,
               (NBytes -Int 1),
               VL ListItem(V))
               requires NBytes >Int 0

     syntax ValueProp ::= joinBytes(Type, K) [function]
     syntax ValueProp ::= "joinBytes'" "(" Type "," List "," List ")" [function]
     rule dumbRead'(
          _,
          _,
          T:Type,
          0,
          Bytes:List)
          => joinBytes(T, dataList(Bytes))

     rule joinBytes(T:Type, dataList(L:List))
          => joinBytes'(T, L, ListItem(piece(0, 0)))

     rule joinBytes(t(_, pointerType(T:Type)),
               dataList(ListItem(piece(subObject(L:SymLoc, _, _), _)) _:List))
          => #ptr(L, T)
     rule joinBytes(t(_, structType(_, Info:FieldInfo)), dataList(V:List))
          => #struct(V, Info)
     rule joinBytes(t(_, unionType(_, Info:FieldInfo)), dataList(V:List))
          => #union(V, Info)
     rule joinBytes(T:Type, dataList(V:List))
          => joinBytes'(T, V, .List)
          requires hasIntegerType(T:Type)

     rule joinBytes'(T:Type,
               L:List ListItem(piece(N:Int, Len:Int)),
               ListItem(piece(N':Int, Len':Int)))
          => joinBytes'(T, L, ListItem(piece(
               piece(N', Len') bit:: piece(N, Len), Len +Int Len')))

     rule joinBytes'(_, .List, ListItem(piece(N:Int, _))) => N

     // Not so interested in l-values.
     syntax ValueProp ::= ltlLVal(Bag, CId) [function]
     syntax ValueProp ::= "ltlLVal'" "(" Bag "," String ")" [function]

     rule ltlLVal(B:Bag, X:CId) => ltlLVal'(B, idToString(X))
     rule ltlLVal'(
          <generatedTop>... <T>...
               <genv>...
                    Identifier(S) |-> Base:SymBase
               ...</genv>
               <gtypes>...
                    Identifier(S) |-> T:Type
               ...</gtypes>
          ...</T> ...</generatedTop>,
          S:String)
          => #ptr(lnew(Base), T)
endmodule
