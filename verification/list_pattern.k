// Copyright (c) 2014-2015 K Team. All Rights Reserved.

module LIST-PATTERN
  imports C-COMMON
  imports INT-LIST

  /* list pattern */
  syntax Map ::= "list" "(" CanonicalSymLoc ")" "(" List ")"    [pattern(1)]
  rule list(loc(P:Int @ alloc, 0, SetItem(align(16)) SetItem(fromArray(0, 8))))(ListItem(I:Int) L:List)
    => P:Int @ alloc |-> object(t(.Set, no-type), 8,
         0 |-> piece(?I0:Int, 8) 
         1 |-> piece(?I1:Int, 8) 
         2 |-> piece(?I2:Int, 8) 
         3 |-> piece(?I3:Int, 8) 
         4 |-> piece(subObject(?PNext:CanonicalSymLoc, 0, 0), 8)
         5 |-> piece(subObject(?PNext:CanonicalSymLoc, 1, 1), 8)
         6 |-> piece(subObject(?PNext:CanonicalSymLoc, 2, 2), 8)
         7 |-> piece(subObject(?PNext:CanonicalSymLoc, 3, 3), 8),
         0 |-> t(.Set, int)
         4 |-> t(.Set, pointerType(t(.Set, structType(global(Identifier("listNode"), "list.c"))))))
       list(?PNext:CanonicalSymLoc)(L:List)
    ensures  I:Int ==K (((((?I3:Int <<Int 8) |Int ?I2:Int) <<Int 8) |Int ?I1:Int) <<Int 8) |Int ?I0:Int
     andBool min(t(.Set, int)) <=Int I:Int andBool I:Int <=Int max(t(.Set, int)) // overflow
    [pattern]
  rule list(NullPointer)(.List) => .Map
    [pattern]

  /* lseg pattern */
/*
  syntax Map ::= "lseg" "(" CanonicalSymLoc "," CanonicalSymLoc ")" "(" List ")"    [pattern(2)]
  rule lseg(loc(P:Int @ alloc, 0, SetItem(align(16)) SetItem(fromArray(0, 8))),
            Q:CanonicalSymLoc)(ListItem(I:Int) L:List)
    => P:Int @ alloc |-> object(t(.Set, no-type), 8,
         0 |-> piece(?I0:Int, 8) 
         1 |-> piece(?I1:Int, 8) 
         2 |-> piece(?I2:Int, 8) 
         3 |-> piece(?I3:Int, 8) 
         4 |-> piece(subObject(?PNext:CanonicalSymLoc, 0, 0), 8)
         5 |-> piece(subObject(?PNext:CanonicalSymLoc, 1, 1), 8)
         6 |-> piece(subObject(?PNext:CanonicalSymLoc, 2, 2), 8)
         7 |-> piece(subObject(?PNext:CanonicalSymLoc, 3, 3), 8),
         0 |-> t(.Set, int)
         4 |-> t(.Set, pointerType(t(.Set, structType(global(Identifier("listNode"), "list.c"))))))
       lseg(?PNext:CanonicalSymLoc, Q:CanonicalSymLoc)(L:List)
    requires loc(P:Int @ alloc, 0, SetItem(align(16)) SetItem(fromArray(0, 8))) =/=K Q:CanonicalSymLoc
    ensures  I:Int ==K (((((?I3:Int <<Int 8) |Int ?I2:Int) <<Int 8) |Int ?I1:Int) <<Int 8) |Int ?I0:Int
     andBool min(t(.Set, int)) <=Int I:Int andBool I:Int <=Int max(t(.Set, int)) // overflow
    [pattern]
  rule lseg(P:CanonicalSymLoc, P:CanonicalSymLoc)(.List) => .Map
    [pattern]

  rule P:Int @ alloc |-> object(t(.Set, no-type), 8,
         0 |-> piece(I0:Int, 8) 
         1 |-> piece(I1:Int, 8) 
         2 |-> piece(I2:Int, 8) 
         3 |-> piece(I3:Int, 8) 
         4 |-> piece(subObject(NullPointer, 0, 0), 8)
         5 |-> piece(subObject(NullPointer, 1, 1), 8)
         6 |-> piece(subObject(NullPointer, 2, 2), 8)
         7 |-> piece(subObject(NullPointer, 3, 3), 8),
         0 |-> t(.Set, int)
         4 |-> t(.Set, pointerType(t(.Set, structType(global(Identifier("listNode"), "list.c"))))))
       F:Map
    => lseg(loc(P:Int @ alloc, 0, SetItem(align(16)) SetItem(fromArray(0, 8))), NullPointer)(ListItem(?I:Int))
       F:Map
    ensures  ?I:Int ==K (((((I3:Int <<Int 8) |Int I2:Int) <<Int 8) |Int I1:Int) <<Int 8) |Int I0:Int
     andBool min(t(.Set, int)) <=Int ?I:Int andBool ?I:Int <=Int max(t(.Set, int)) // overflow
    [pattern-folding]
  rule P:Int @ alloc |-> object(t(.Set, no-type), 8,
         0 |-> piece(I0:Int, 8) 
         1 |-> piece(I1:Int, 8) 
         2 |-> piece(I2:Int, 8) 
         3 |-> piece(I3:Int, 8) 
         4 |-> piece(subObject(loc(Q:Int @ alloc, 0, SetItem(align(16)) SetItem(fromArray(0, 8))), 0, 0), 8)
         5 |-> piece(subObject(loc(Q:Int @ alloc, 0, SetItem(align(16)) SetItem(fromArray(0, 8))), 1, 1), 8)
         6 |-> piece(subObject(loc(Q:Int @ alloc, 0, SetItem(align(16)) SetItem(fromArray(0, 8))), 2, 2), 8)
         7 |-> piece(subObject(loc(Q:Int @ alloc, 0, SetItem(align(16)) SetItem(fromArray(0, 8))), 3, 3), 8),
         0 |-> t(.Set, int)
         4 |-> t(.Set, pointerType(t(.Set, structType(global(Identifier("listNode"), "list.c"))))))
       (Q:Int @ alloc |-> object(t(.Set, no-type), 8, MV:Map, MT:Map))
       F:Map
    => lseg(loc(P:Int @ alloc, 0, SetItem(align(16)) SetItem(fromArray(0, 8))), 
            loc(Q:Int @ alloc, 0, SetItem(align(16)) SetItem(fromArray(0, 8))))(ListItem(?I:Int))
       (Q:Int @ alloc |-> object(t(.Set, no-type), 8, MV:Map, MT:Map))
       F:Map
    ensures  ?I:Int ==K (((((I3:Int <<Int 8) |Int I2:Int) <<Int 8) |Int I1:Int) <<Int 8) |Int I0:Int
     andBool min(t(.Set, int)) <=Int ?I:Int andBool ?I:Int <=Int max(t(.Set, int)) // overflow
    [pattern-folding]
  rule P:CanonicalSymLoc |-> (
          val  |-> tv(int, I:Int)
          next |-> tv(struct listNode *, Q:CanonicalSymLoc))
       lseg(Q, null)(L:List)
       F:Map
    => lseg(P, Q)(ListItem(I))
       lseg(Q, null)(L)
       F
    [pattern-folding]
  rule P:CanonicalSymLoc |-> (
          val  |-> tv(int, I:Int)
          next |-> tv(struct listNode *, Q:CanonicalSymLoc))
       lseg(Q, R:CanonicalSymLoc)(L:List)
       R |-> M:Map
       F:Map
    => lseg(P, Q)(ListItem(I))
       lseg(Q, R)(L)
       R |-> M:Map
       F
    [pattern-folding]
  rule lseg(P:CanonicalSymLoc, Q:CanonicalSymLoc)(L1:List)
       lseg(Q, null)(L2:List)
       F:Map
    => lseg(P, null)(L1 L2)
       F
    [pattern-folding]
  rule lseg(P:CanonicalSymLoc, R:CanonicalSymLoc)(L1:List)
       lseg(R, Q:CanonicalSymLoc)(L2:List)
       (Q |-> M:Map)
       F:Map
    => lseg(P, Q)(L1 L2)
       (Q |-> M)
       F
    [pattern-folding]
  rule lseg(P:CanonicalSymLoc, R:CanonicalSymLoc)(L1:List)
       lseg(R, Q:CanonicalSymLoc)(L2:List)
       lseg(Q, null)(L3:List)
       F:Map
    => lseg(P, Q)(L1 L2)
       lseg(Q, null)(L3)
       F
    [pattern-folding]
*/

endmodule
