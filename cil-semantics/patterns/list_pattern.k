// Copyright (c) 2014 K Team. All Rights Reserved.

module LIST-PATTERN
  imports CIL-SEMANTICS

  /* list pattern */
  syntax Bag ::= "list" "(" Ptr ")" "(" List ")"   [pattern(1)]
  rule
    <heap>...
      list(Ptr(BP:BasePtr, 0))(ListItem(MI:MInt) L:List)
    =>
      <object>
        <base-ptr> BP </base-ptr>
        <bytes>
          0 |-> ?B0:MInt
          1 |-> ?B1:MInt
          2 |-> ?B2:MInt
          3 |-> ?B3:MInt
          //4 |-> ?B4:MInt
          //5 |-> ?B5:MInt
          //6 |-> ?B6:MInt
          //7 |-> ?B7:MInt
          4 |-> ?P:Ptr
          5 |-> used
          6 |-> used
          7 |-> used
        </bytes>
      </object>
      list(?P:Ptr)(L)
    ...</heap>
  //ensures (E ==K mIntOfDigits(ListItem(?B0) ListItem(?B1) ListItem(?B2) ListItem(?B3))) andBool (?P ==K bytes2Value(void*, ListItem(?B4) ListItem(?B5) ListItem(?B6) ListItem(?B7)))
    ensures MI ==K mIntOfDigits(ListItem(?B0) ListItem(?B1) ListItem(?B2) ListItem(?B3))
    [pattern]
  rule <heap>... list(Null)(.List) => .Bag ...</heap>
    [pattern]

endmodule
