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
         7 |-> piece(subObject(?PNext:CanonicalSymLoc, 3, 3), 8)
        ,0 |-> t(.Set, int)
         4 |-> t(.Set, pointerType(t(.Set, structType(global(Identifier("listNode"), "list.c"))))))
       list(?PNext:CanonicalSymLoc)(L:List)
    ensures  I:Int ==K (((((?I3:Int <<Int 8) |Int ?I2:Int) <<Int 8) |Int ?I1:Int) <<Int 8) |Int ?I0:Int
     andBool min(t(.Set, int)) <=Int I:Int andBool I:Int <=Int max(t(.Set, int)) // overflow
    [pattern]
  rule list(NullPointer)(.List) => .Map
    [pattern]

  /* lseg pattern */
  syntax Map ::= "lseg" "(" CanonicalSymLoc "," CanonicalSymLoc ")" "(" List ")"    [pattern(2)]
  rule lseg(loc(P:Int @ alloc, 0, SetItem(align(16)) SetItem(fromArray(0, 8))), Q:CanonicalSymLoc)(ListItem(I:Int) L:List)
    => P:Int @ alloc |-> object(t(.Set, no-type), 8,
         0 |-> piece(?I0:Int, 8) 
         1 |-> piece(?I1:Int, 8) 
         2 |-> piece(?I2:Int, 8) 
         3 |-> piece(?I3:Int, 8) 
         4 |-> piece(subObject(?PNext:CanonicalSymLoc, 0, 0), 8)
         5 |-> piece(subObject(?PNext:CanonicalSymLoc, 1, 1), 8)
         6 |-> piece(subObject(?PNext:CanonicalSymLoc, 2, 2), 8)
         7 |-> piece(subObject(?PNext:CanonicalSymLoc, 3, 3), 8)
        ,0 |-> t(.Set, int)
         4 |-> t(.Set, pointerType(t(.Set, structType(global(Identifier("listNode"), "list.c"))))))
       lseg(?PNext:CanonicalSymLoc, Q:CanonicalSymLoc)(L:List)
    requires loc(P:Int @ alloc, 0, SetItem(align(16)) SetItem(fromArray(0, 8))) =/=K Q:CanonicalSymLoc
    ensures  I:Int ==K (((((?I3:Int <<Int 8) |Int ?I2:Int) <<Int 8) |Int ?I1:Int) <<Int 8) |Int ?I0:Int
     andBool min(t(.Set, int)) <=Int I:Int andBool I:Int <=Int max(t(.Set, int)) // overflow
    [pattern]
  rule lseg(P:CanonicalSymLoc, P:CanonicalSymLoc)(.List) => .Map
    [pattern]

  // p->null => lseg(p,null)    where p =/= null
  rule 
    (
       // p->null
       P:Int @ alloc |-> object(t(.Set, no-type), 8,
         0 |-> piece(I0:Int, 8) 
         1 |-> piece(I1:Int, 8) 
         2 |-> piece(I2:Int, 8) 
         3 |-> piece(I3:Int, 8) 
         4 |-> piece(subObject(NullPointer, 0, 0), 8)
         5 |-> piece(subObject(NullPointer, 1, 1), 8)
         6 |-> piece(subObject(NullPointer, 2, 2), 8)
         7 |-> piece(subObject(NullPointer, 3, 3), 8)
        ,0 |-> t(.Set, int)
         4 |-> t(.Set, pointerType(t(.Set, structType(global(Identifier("listNode"), "list.c"))))))
    => 
       // lseg(p,null)
       lseg(loc(P:Int @ alloc, 0, SetItem(align(16)) SetItem(fromArray(0, 8))),
            NullPointer)
           (ListItem((((((I3:Int <<Int 8) |Int I2:Int) <<Int 8) |Int I1:Int) <<Int 8) |Int I0:Int))
    )
       F:Map
    // overflow
    ensures  min(t(.Set, int))
             <=Int
             ((((((I3:Int <<Int 8) |Int I2:Int) <<Int 8) |Int I1:Int) <<Int 8) |Int I0:Int) // I
             andBool
             ((((((I3:Int <<Int 8) |Int I2:Int) <<Int 8) |Int I1:Int) <<Int 8) |Int I0:Int) // I
             <=Int
             max(t(.Set, int))
    [pattern-folding]

  // ( p->q => lseg(p,q) ) q->...   where p =/= null, q =/= null
  rule 
    (
       // p->q
       P:Int @ alloc |-> object(t(.Set, no-type), 8,
         0 |-> piece(I0:Int, 8) 
         1 |-> piece(I1:Int, 8) 
         2 |-> piece(I2:Int, 8) 
         3 |-> piece(I3:Int, 8) 
         4 |-> piece(subObject(loc(Q:Int @ alloc, 0, SetItem(align(16)) SetItem(fromArray(0, 8))), 0, 0), 8)
         5 |-> piece(subObject(loc(Q:Int @ alloc, 0, SetItem(align(16)) SetItem(fromArray(0, 8))), 1, 1), 8)
         6 |-> piece(subObject(loc(Q:Int @ alloc, 0, SetItem(align(16)) SetItem(fromArray(0, 8))), 2, 2), 8)
         7 |-> piece(subObject(loc(Q:Int @ alloc, 0, SetItem(align(16)) SetItem(fromArray(0, 8))), 3, 3), 8)
        ,0 |-> t(.Set, int)
         4 |-> t(.Set, pointerType(t(.Set, structType(global(Identifier("listNode"), "list.c"))))))
    => 
       // lseg(p,q)
       lseg(loc(P:Int @ alloc, 0, SetItem(align(16)) SetItem(fromArray(0, 8))), 
            loc(Q:Int @ alloc, 0, SetItem(align(16)) SetItem(fromArray(0, 8))))
           (ListItem((((((I3:Int <<Int 8) |Int I2:Int) <<Int 8) |Int I1:Int) <<Int 8) |Int I0:Int))
    )
       // q->...
       (Q:Int @ alloc |-> object(t(.Set, no-type), 8, MV:Map, MT:Map))
       F:Map
    // overflow
    ensures  min(t(.Set, int))
             <=Int
             ((((((I3:Int <<Int 8) |Int I2:Int) <<Int 8) |Int I1:Int) <<Int 8) |Int I0:Int) // I
             andBool
             ((((((I3:Int <<Int 8) |Int I2:Int) <<Int 8) |Int I1:Int) <<Int 8) |Int I0:Int) // I
             <=Int
             max(t(.Set, int))
    [pattern-folding]

  // ( p->q => lseg(p,q) ) lseg(q,null)     where p =/= null, q nullable
  rule 
    (
       // p->q
       P:Int @ alloc |-> object(t(.Set, no-type), 8,
         0 |-> piece(I0:Int, 8) 
         1 |-> piece(I1:Int, 8) 
         2 |-> piece(I2:Int, 8) 
         3 |-> piece(I3:Int, 8) 
         4 |-> piece(subObject(Q:CanonicalSymLoc, 0, 0), 8)
         5 |-> piece(subObject(Q:CanonicalSymLoc, 1, 1), 8)
         6 |-> piece(subObject(Q:CanonicalSymLoc, 2, 2), 8)
         7 |-> piece(subObject(Q:CanonicalSymLoc, 3, 3), 8)
        ,0 |-> t(.Set, int)
         4 |-> t(.Set, pointerType(t(.Set, structType(global(Identifier("listNode"), "list.c"))))))
    => 
       // lseg(p,q)
       lseg(loc(P:Int @ alloc, 0, SetItem(align(16)) SetItem(fromArray(0, 8))),
            Q:CanonicalSymLoc)
           (ListItem((((((I3:Int <<Int 8) |Int I2:Int) <<Int 8) |Int I1:Int) <<Int 8) |Int I0:Int))
    )
       // lseg(q,null)
       lseg(Q:CanonicalSymLoc,
            NullPointer)(L:List)
       F:Map
    // overflow
    ensures  min(t(.Set, int))
             <=Int
             ((((((I3:Int <<Int 8) |Int I2:Int) <<Int 8) |Int I1:Int) <<Int 8) |Int I0:Int) // I
             andBool
             ((((((I3:Int <<Int 8) |Int I2:Int) <<Int 8) |Int I1:Int) <<Int 8) |Int I0:Int) // I
             <=Int
             max(t(.Set, int))
    [pattern-folding]

  // ( p->q => lseg(p,q) ) lseg(q,r) r->...     where p =/= null, q nullable but should be non-null, r =/= null
  rule 
    (
       // p->q
       P:Int @ alloc |-> object(t(.Set, no-type), 8,
         0 |-> piece(I0:Int, 8) 
         1 |-> piece(I1:Int, 8) 
         2 |-> piece(I2:Int, 8) 
         3 |-> piece(I3:Int, 8) 
         4 |-> piece(subObject(Q:CanonicalSymLoc, 0, 0), 8)
         5 |-> piece(subObject(Q:CanonicalSymLoc, 1, 1), 8)
         6 |-> piece(subObject(Q:CanonicalSymLoc, 2, 2), 8)
         7 |-> piece(subObject(Q:CanonicalSymLoc, 3, 3), 8)
        ,0 |-> t(.Set, int)
         4 |-> t(.Set, pointerType(t(.Set, structType(global(Identifier("listNode"), "list.c"))))))
    => 
       // lseg(p,q)
       lseg(loc(P:Int @ alloc, 0, SetItem(align(16)) SetItem(fromArray(0, 8))), 
            Q:CanonicalSymLoc)
           (ListItem((((((I3:Int <<Int 8) |Int I2:Int) <<Int 8) |Int I1:Int) <<Int 8) |Int I0:Int))
    )
       // lseg(q,r)
       lseg(Q:CanonicalSymLoc, 
            loc(R:Int @ alloc, 0, SetItem(align(16)) SetItem(fromArray(0, 8))))(L:List)
       // r->...
       (R:Int @ alloc |-> object(t(.Set, no-type), 8, MV:Map, MT:Map))
       F:Map
    // overflow
    ensures  min(t(.Set, int))
             <=Int
             ((((((I3:Int <<Int 8) |Int I2:Int) <<Int 8) |Int I1:Int) <<Int 8) |Int I0:Int) // I
             andBool
             ((((((I3:Int <<Int 8) |Int I2:Int) <<Int 8) |Int I1:Int) <<Int 8) |Int I0:Int) // I
             <=Int
             max(t(.Set, int))
    [pattern-folding]

  // lseg(p,q) lseg(q,null) => lseg(p,null)     where p nullable, q nullable
  rule 
    (
       // lseg(p,q)
       lseg(P:CanonicalSymLoc,
            Q:CanonicalSymLoc)(L1:List)
       // lseg(q,null)
       lseg(Q:CanonicalSymLoc,
            NullPointer)(L2:List)
    => 
       // lseg(p,null)
       lseg(P:CanonicalSymLoc,
            NullPointer)(L1:List L2:List)
    )
       F:Map
    [pattern-folding]

  // ( lseg(p,r) lseg(r,q) => lseg(p,q) ) q->...    where p nullable but should non-null, q =/= null, r nullable but should non-null
  rule 
    (
       // lseg(p,r)
       lseg(P:CanonicalSymLoc,
            R:CanonicalSymLoc)(L1:List)
       // lseg(r,q)
       lseg(R:CanonicalSymLoc,
            loc(Q:Int @ alloc, 0, SetItem(align(16)) SetItem(fromArray(0, 8))))(L2:List)
    => 
       // lseg(p,q)
       lseg(P:CanonicalSymLoc,
            loc(Q:Int @ alloc, 0, SetItem(align(16)) SetItem(fromArray(0, 8))))(L1:List L2:List)
    )
       // q->...
       (Q:Int @ alloc |-> object(t(.Set, no-type), 8, MV:Map, MT:Map))
       F:Map
    [pattern-folding]

  // ( lseg(p,r) lseg(r,q) => lseg(p,q) ) lseg(q,null)      where p nullable, q nullable, r nullable
  rule 
    (
       // lseg(p,r)
       lseg(P:CanonicalSymLoc,
            R:CanonicalSymLoc)(L1:List)
       // lseg(r,q)
       lseg(R:CanonicalSymLoc,
            Q:CanonicalSymLoc)(L2:List)
    => 
       // lseg(p,q)
       lseg(P:CanonicalSymLoc, 
            Q:CanonicalSymLoc)(L1:List L2:List)
    )
       // lseg(q,null)
       lseg(Q:CanonicalSymLoc,
            NullPointer)(L3:List)
       F:Map
    [pattern-folding]

endmodule
