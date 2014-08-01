module LIST-PATTERN
  imports CIL-SEMANTICS

  syntax Seq ::= Value "::" Seq   [klabel(seq-cons)]
               | "[]"             [klabel(seq-nil)]
  syntax Seq ::= Seq "@" Seq      [function, klabel(seq-append)]
               | rev(Seq)         [function]
  rule (E::L1) @ L2 => E::(L1 @ L2)
  rule [] @ L => L
  rule rev(E::L) => rev(L) @ E::[]
  rule rev([]) => []

  /* lemmas */
  rule L @ [] => L                                [lemma]
  rule (L1 @ (E :: [])) @ L2 => L1 @ (E :: L2)    [lemma]

  syntax Bag ::= "list" "(" Ptr ")" "(" Seq ")"   [pattern(1)]
  rule
    <heap>...
      list(Ptr(BP:BasePtr, 0))(E:Value :: L:Seq)
    =>
      <object>
        <base-ptr> BP </base-ptr>
        <bytes>
          0 |-> ?B0:MInt
          1 |-> ?B1:MInt
          2 |-> ?B2:MInt
          3 |-> ?B3:MInt
          4 |-> ?B4:MInt
          5 |-> ?B5:MInt
          6 |-> ?B6:MInt
          7 |-> ?B7:MInt
        </bytes>
      </object>
      list(?P:Ptr)(L)
    ...</heap>
  ensures (E ==K mIntOfDigits(ListItem(?B0) ListItem(?B1) ListItem(?B2) ListItem(?B3))) andBool (?P ==K bytes2Value(void*, ListItem(?B4) ListItem(?B5) ListItem(?B6) ListItem(?B7)))
  [pattern]
  rule <heap>... (list(Null)([]) => .Bag) ...</heap>
  [pattern]

endmodule

