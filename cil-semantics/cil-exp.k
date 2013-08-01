require "cil-common.k"

/* CId variable conventions:
     X variable
     M structure member
     F function */

module CIL-PROMOTION
  imports CIL-COMMON

  syntax K ::= "typeinfo" "(" Int "," Int "," Int ")"

  /* empty: implicit casts inserted by cilly */
endmodule

module CIL-EXP
  imports CIL-PROMOTION

  syntax K ::= "noLeftValueConversion"


  /* constant */
  /* TODO: typed constant */
  rule I:Int => tv(int, mi((width(int)), I))
    [structural]
  rule I:Int U => tv(unsigned int, mi((width(unsigned int)), I))
    [structural]
  rule I:Int UL => tv(unsigned long, mi((width(unsigned long)), I))
    [structural]
  rule I:Int ULL => tv(unsigned long long, mi((width(unsigned long long)), I))
    [structural]

  /* lookup */
  rule
    <k> X:CId => lv(T, P) ...</k>
    <env>... X |-> P:Ptr ...</env>
    <type-env>... X |-> T:Type ...</type-env>
    [structural]

  // TODO(chathhorn): I doubt this is part of CIL
  rule E1:Exp[E2:Exp] => *(E1 + E2)   [macro]

  context (HOLE => HOLE ~> noLeftValueConversion) . _:CId

  // syntax K ::= extractField(Type, Int, K, List) [strict(3)]
  // rule 
  //   <k> 
  //     tv(Agg:AggType, agg(L:List)) . F:CId 
  //     => extractField(T, Offset, sizeof(T), L) 
  //   ...</k>
  //   <agg-id> Agg </agg-id>
  //   <field-id> F </field-id>
  //   <field-type> T:Type </field-type>
  //   <offset> Offset:Int </offset>

  rule 
    <k> 
      nclv(Agg:AggType, Ptr(Base:BasePtr, Offset:Int)) . F:CId 
      => lv(T, Ptr(Base, Offset +Int FOffset))
    ...</k>
    <agg-id> Agg </agg-id>
    <field-id> F </field-id>
    <field-type> T:Type </field-type>
    <offset> FOffset:Int </offset>

  // rule extractField(T:Type, Offset:Int, Sz:TypedValue, L:List)
  //   => tv(T, bytes2Value(T, subList(L, Offset, val(Sz))))
  // 
  // syntax List ::= subList(List, Int, Int) [function]

  // rule 
  //   subList((ListItem(K:K) => .List) _:List, (Offset:Int => Offset -Int 1), _)
  //   when Offset >Int 0

  // rule 
  //   (.List => ListItem(K)) 
  //   subList((ListItem(K:K) => .List) _:List, 0, (Len:Int => Len -Int 1))
  //   when Len >Int 0
  // 
  // rule subList(_, 0, 0) => .List

  /* TODO: '&_ */
  context &(HOLE => HOLE ~> noLeftValueConversion)
  rule &nclv(T:Type, P:Ptr) => tv(T*, P) [structural]
  
  /* dereference */
  rule *tv(T:Type*, P:Ptr) => lv(T, P) [structural]

  context '_=_;((HOLE => HOLE ~> noLeftValueConversion),, _)
  rule nclv(T:NvType, P:Ptr) = tv(T, V:Value); => store(T, P, V)
    
  rule (lv(T:NvType, P:Ptr) => load(T, P)) ~> KLabel:KLabel(KList:KList)
    when KLabel(KList) =/=K noLeftValueConversion

  rule ('lv => 'nclv)(_:KList) ~> noLeftValueConversion
  [structural]

  /*
   * Arithmetic operators semantics.
   */
  /* Unary plus */
  rule +tv(T:Type, MI:MInt) => tv(T, MI)
  /* Unary minus */
  /* FIXME standard is unclear about the semantics of unary minus */
  // rule -tv(T:Type, mi(N:Int, I:Int)) => tv(T:Type, mi(N, )) 

  /* Addition */
  rule
    tv(T:SignedIntType, MI1:MInt) + tv(T, MI2:MInt)
  =>
    tv(T, miMInt(addMInt(MI1, MI2)))
  when
    notBool ufMInt(addMInt(MI1, MI2)) andBool
    notBool ofMInt(addMInt(MI1, MI2))
  rule
    tv(T:UnsignedIntType, MI1:MInt) + tv(T, MI2:MInt)
  =>
    tv(T, miMInt(uaddMInt(MI1, MI2)))

  /* Subtraction */
  rule
    tv(T:SignedIntType, MI1:MInt) - tv(T, MI2:MInt)
  =>
    tv(T, miMInt(subMInt(MI1, MI2)))
  when
    notBool ufMInt(subMInt(MI1, MI2)) andBool
    notBool ofMInt(subMInt(MI1, MI2))
  rule
    tv(T:UnsignedIntType, MI1:MInt) - tv(T, MI2:MInt)
  =>
    tv(T, miMInt(usubMInt(MI1, MI2)))

  /* Multiplication */
  rule
    tv(T:SignedIntType, MI1:MInt) * tv(T, MI2:MInt)
  =>
    tv(T, miMInt(mulMInt(MI1, MI2)))
  when
    notBool ufMInt(mulMInt(MI1, MI2)) andBool
    notBool ofMInt(mulMInt(MI1, MI2))
  rule
    tv(T:UnsignedIntType, MI1:MInt) * tv(T, MI2:MInt)
  =>
    tv(T, miMInt(umulMInt(MI1, MI2)))

  /* Division */
  rule
    tv(T:SignedIntType, MI1:MInt) / tv(T, MI2:MInt)
  =>
    tv(T, miMInt(divMInt(MI1, MI2)))
  when divMInt(MI1, MI2) =/=K errMInt andBool notBool ofMInt(divMInt(MI1, MI2))
  rule
    tv(T:UnsignedIntType, MI1:MInt) / tv(T, MI2:MInt)
  =>
    tv(T, miMInt(udivMInt(MI1, MI2)))
  when udivMInt(MI1, MI2) =/=K errMInt

  /* Reminder */
  /* signed reminder is defined only when signed division is defined */
  rule
    tv(T:SignedIntType, MI1:MInt) % tv(T, MI2:MInt)
  =>
    tv(T, miMInt(remMInt(MI1, MI2)))
  when divMInt(MI1, MI2) =/=K errMInt andBool notBool ofMInt(divMInt(MI1, MI2))
  rule
    tv(T:UnsignedIntType, MI1:MInt) % tv(T, MI2:MInt)
  =>
    tv(T, miMInt(uremMInt(MI1, MI2)))
  when udivMInt(MI1, MI2) =/=K errMInt


  /* TODO: check for defined behaviour */
  /*
  rule ~tv(T:Type, I:Int) => norm(T, ~Int I)
  rule tv(T:Type, MI:MInt) << tv(_, mi(I2:Int)) => tv(T, I <<Int N)
  when N <Int width(T)
  rule tv(T:Type, I:Int) >> tv(_, N:Int) => norm(T, I <<Int N)
  when N <Int width(T)
  */

  /* Relation operators */
  rule
    tv(T:SignedIntType, MI1:MInt) < tv(T, MI2:MInt)
  =>
    bool2mint(ltMInt(MI1, MI2))
  rule
    tv(T:SignedIntType, MI1:MInt) <= tv(T, MI2:MInt)
  =>
    bool2mint(leqMInt(MI1, MI2))
  rule
    tv(T:SignedIntType, MI1:MInt) > tv(T, MI2:MInt)
  =>
    bool2mint(gtMInt(MI1, MI2))
  rule
    tv(T:SignedIntType, MI1:MInt) >= tv(T, MI2:MInt)
  =>
    bool2mint(geqMInt(MI1, MI2))


  /* Relation operators */
  rule
    tv(T:Type, MI1:MInt) == tv(T, MI2:MInt)
  =>
    bool2mint(MI1 ==MInt MI2)
  rule
    tv(T:Type, MI1:MInt) != tv(T, MI2:MInt)
  =>
    bool2mint(MI1 =/=MInt MI2)


  rule !tv(_:Type, I:Int) => norm(int, #if I ==Int 0 #then 1 #else 0 #fi)


  /*
   * Sizeof
   */
  /* TODO: sizeof for exp 
  */
  rule sizeof(T:BasicType) => byteWidth(T)    [structual]
  rule sizeof(T:PtrType) => byteWidth(T)    [structual]
  rule <k> sizeof(X:AggType) => Size ...</k>
     <agg-id> X </agg-id>
     <size> Size:Int </size>
     [structural]
  rule <k> sizeof(X:CId) => sizeof(T) ...</k>
     <typedefs>... X |-> T:Type ...</typedefs>
     [structural]
  
  /*
   * Casting
   */
  /* the rule for signed integer types is implementation defined */
  rule
    (T:SignedIntType) tv(_:Type, mi(_:Int, I:Int))
  =>
    tv(T, sMInt(mi((width(T)), I)))
  rule
    (T:UnsignedIntType) tv(_:Type, mi(_:Int, I:Int))
  =>
    tv(T, uMInt(mi((width(T)), I)))
  rule (T:FloatingType) tv(_:Type, F:Int) => tv(T, F)
  /* TODO: complete all the cases  */
  //rule (void *) tv(T:PtrType, A:Ptr) => 

  rule tv(T:Type, F1:Float) * tv(T, F2:Float) => tv(T, F1 *Float F2)
  rule tv(T:Type, F1:Float) / tv(T, F2:Float) => tv(T, F1 /Float F2)
  when F2 =/=Float 0.0

  rule tv(T:Type, F1:Float) + tv(T, F2:Float) => tv(T, F1 +Float F2)
  rule tv(T:Type, F1:Float) - tv(T, F2:Float) => tv(T, F1 -Float F2)
 
  context tv(_, PtrAdd(_, _, HOLE))
  rule tv(T:Type*, P:Ptr) + tv(_, I:Int) => tv(T*, PtrAdd(P, I, sizeof(T)))
  rule tv(_, I:Int) + tv(T:Type*, P:Ptr) => tv(T*, PtrAdd(P, I, sizeof(T)))
  rule
    tv(T:Type*, P:Ptr) - tv(_, I:Int)
  =>
    tv(T*, PtrAdd(P, 0 -Int I, sizeof(T)))

  /* TODO: replace int with size_ptr */
  context tv(_, PtrSub(_, _, HOLE))
  rule
    tv(T:Type*, P1:Ptr) - tv(T*, P2:Ptr) => tv(int, PtrSub(P1, P2, sizeof(T)))
  
  rule tv(T:Type, F1:Float) < tv(T, F2:Float) => norm(int, F1 <Float F2)
  rule tv(T:Type, F1:Float) <= tv(T, F2:Float) => norm(int, F1 <=Float F2)
  rule tv(T:Type, F1:Float) > tv(T, F2:Float) => norm(int, F1 >Float F2)
  rule tv(T:Type, F1:Float) >= tv(T, F2:Float) => norm(int, F1 >=Float F2)

  rule tv(_:Type, P1:Ptr) < tv(_:Type, P2:Ptr) => norm(int, PtrLt(P1, P2))
  rule tv(_:Type, P1:Ptr) <= tv(_:Type, P2:Ptr) => norm(int, PtrLeq(P1, P2))
  rule tv(_:Type, P1:Ptr) > tv(_:Type, P2:Ptr) => norm(int, PtrGt(P1, P2))
  rule tv(_:Type, P1:Ptr) >= tv(_:Type, P2:Ptr) => norm(int, PtrGeq(P1, P2))

  /* TODO: comparison of pointers and integers */
  /* TODO: for now ignoring whether the pointer is alive or dead */
  rule tv(T:Type, I1:Int) == tv(T, I2:Int) => norm(int, I1 ==Int I2)
  rule tv(T:Type, I1:Int) != tv(T, I2:Int) => norm(int, I1 =/=Int I2)
  rule tv(T:Type, F1:Float) == tv(T, F2:Float) => norm(int, F1 ==Float F2)
  rule tv(T:Type, F1:Float) != tv(T, F2:Float) => norm(int, F1 =/=Float F2)
  rule tv(_:Type, P1:Ptr) == tv(_:Type, P2:Ptr) => norm(int, P1 ==Ptr P2)
  rule tv(_:Type, P1:Ptr) != tv(_:Type, P2:Ptr) => norm(int, P1 =/=Ptr P2)

  rule tv(T:Type, I1:Int) & tv(T, I2:Int) => norm(T, I1 &Int I2)
  rule tv(T:Type, I1:Int) ^ tv(T, I2:Int) => norm(T, I1 xorInt I2)
  rule tv(T:Type, I1:Int) | tv(T, I2:Int) => norm(T, I1 |Int I2)

  /* TODO: '_&&_, '_||_ and '_?_:_  are not generated by CIL */
  /* FIXME: convert non-zero values to 1 */
  rule tv(int, 1) && E:Exp => !(E == 0)
  rule tv(int, 0) && _:Exp => tv(int, 0)
  rule tv(int, 1) || _:Exp => tv(int, 1)
  rule tv(int, 0) || E:Exp => !(E == 0)

  /* FIXME: undefined if E1 and E2 do not have compatible types */
  rule tv(int, 1) ? E1:Exp : _:Exp => E1
  rule tv(int, 0) ? _:Exp : E2:Exp => E2
endmodule

