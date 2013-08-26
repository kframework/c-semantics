// vim: set ts=2 sw=2:
require "cil-syntax.k"
require "builtins/mint.k"

module CIL-COMMON-PTR
  imports CIL-SYNTAX
  imports CIL-COMMON
  imports CIL-COMMON-TYPED-VALUE
  /*
   * Ptr of BasePtr * Offset
   * @invariant: 0 <= Offset <= BasePtr.Size
   * @immutable: BasePtr
   */
  syntax Ptr ::= Ptr(BasePtr, Int)
               | FunPtr
               | "Null"
               | VaList

  // TODO(chathhorn): rather hackish.
  syntax VaList ::= "va_list" "(" TypedValues ")"

  syntax FunPtr ::= FunPtr(CId, TransUnit) | ExtFun(String)

  /*
   * BasePtr of Base * Size
   * @immutable: Base, Size 
   */
  syntax BasePtr ::= "BasePtr" "(" Int "," Int ")"

  syntax Ptr ::= "PtrAdd" "(" Ptr "," Int "," Exp ")"   [function]
  syntax Int ::= "PtrSub" "(" Ptr "," Ptr "," Exp ")"   [function]
  syntax Bool ::= Ptr "==Ptr" Ptr              [function]
                | Ptr "=/=Ptr" Ptr             [function]
                | "PtrLt" "(" Ptr "," Ptr ")"  [function]
                | "PtrLeq" "(" Ptr "," Ptr ")" [function]
                | "PtrGt" "(" Ptr "," Ptr ")"  [function]
                | "PtrGeq" "(" Ptr "," Ptr ")" [function]

  /* Addition of pointer and index is defined only if there result Offset is in
   * the range [0, Size] */
  rule PtrAdd(Ptr(BasePtr(Base:Int, Size:Int), Offset:Int), I:Int, V:TypedValue)
    => Ptr(BasePtr(Base, Size), (Offset +Int I *Int mival(V)))
    when 0 <=Int Offset +Int I *Int mival(V)
      andBool Offset +Int I *Int mival(V) <=Int Size

  /* Subtraction of pointers is defined only for the same BasePtr. */
  rule PtrSub(Ptr(BP:BasePtr, Offset1:Int), Ptr(BP, Offset2:Int), V:TypedValue)
    => (Offset1 -Int Offset2) /Int mival(V)
    when (Offset1 -Int Offset2) %Int mival(V) ==Int 0

  /* Structural equality of addresses */
  rule Ptr(BasePtr(Base1:Int, Size1:Int), Offset1:Int)
    ==Ptr Ptr(BasePtr(Base2:Int, Size2:Int), Offset2:Int)
    => Base1 ==Int Base2 andBool Size1 ==Int Size2 andBool Offset1 ==Int Offset2
  rule Null ==Ptr Null => true
  rule Ptr(_, _) ==Ptr Null => false
  rule Null ==Ptr Ptr(_, _) => false
  rule P1:Ptr =/=Ptr P2:Ptr => notBool(P1:Ptr ==Ptr P2:Ptr)

  /* Relational operations on pointers are defined only for the same BasePtr. */
  rule
    PtrLt(Ptr(BP:BasePtr, Offset1:Int), Ptr(BP, Offset2:Int))
  =>
    Offset1 <Int Offset2
  rule
    PtrLeq(Ptr(BP:BasePtr, Offset1:Int), Ptr(BP, Offset2:Int))
  =>
    Offset1 <=Int Offset2
  rule
    PtrGt(Ptr(BP:BasePtr, Offset1:Int), Ptr(BP, Offset2:Int))
  =>
    Offset1 >Int Offset2
  rule
    PtrGeq(Ptr(BP:BasePtr, Offset1:Int), Ptr(BP, Offset2:Int))
  =>
    Offset1 >=Int Offset2
endmodule


/*
 * Interface module containing operation declarations for converting a value
 * to/from a list of bytes. The implementation is in file cil-implementation.k.
 */
module CIL-COMMON-VALUE-SERIALIZATION-INTERFACE
  imports CIL-SYNTAX
  imports CIL-COMMON-PTR

  /*
   * @invariant
   */
  syntax Int ::= width(Type)        [function]
               | byteWidth(Type)    [function]

  syntax Value ::= ByteValue | Bool | Float | Ptr | MInt | agg(List) | String

  syntax ByteValue ::= Int | Float | Ptr | "undef" | "used"

  /*
   * @invariant:
   * Int ::= bytes2Value(IntType, List)
   * Float ::= bytes2Value(FloatingType, List)
   * Ptr ::= bytes2Value(PtrType, List)
   * byteWidth(T:Type) =Int #lenList(L:List)
   */
  syntax Value ::= bytes2Value(Type, List) [function]
  /*
   * @invariant:
   * value2Bytes(T:IntType, I:Int)
   * value2Bytes(T:FloatingType, F:Float)
   * value2Bytes(T:PtrType, P:Ptr)
   */
  syntax List ::= value2Bytes(Type, Value) [function] 
endmodule

module CIL-COMMON-TYPED-VALUE
  imports CIL-SYNTAX
  imports CIL-COMMON-PTR

  syntax Exp ::= TypedValue
  /*
   * @invariant:
   * tv(T:IntType, I:Int)
   * tv(T:FloatingType, F:Float)
   * tv(T:PtrType, P:Ptr)
   */
  syntax TypedValue ::= tv(Type, Value)
                      | "norm" "(" Type "," Value ")"    [function]
  syntax TypedValues ::= List{TypedValue, ","}

  syntax Exp ::= LeftValue
  syntax LeftValue ::= lv(Type, Ptr)

  syntax Exp ::= NoConversionLeftValue
  syntax NoConversionLeftValue ::= nclv(Type, Ptr)

  syntax Int ::= val(TypedValue) [function]
  rule val(tv(_, V:Value)) => V

  rule norm(T:Type, I:MInt) => norm(T, iMInt(I))

  rule norm(T:IntType, true) => tv(T, mi(width(T), 1)) 
  rule norm(T:IntType, false) => tv(T, mi(width(T), 0)) 

  rule norm(T:IntType, F:Float) => norm(T, Float2Int(F))
  rule norm(T:UnsignedIntType, I:Int) => tv(T, uMInt(mi(width(T), I)))
  rule norm(T:SignedIntType, I:Int) => tv(T, sMInt(mi(width(T), I)))

  // TODO(chathhorn): not sure about the best way to handle this.
  rule norm(T:Type, I:Int) => tv(T, uMInt(mi(width(T), I)))
    when isPtrType(T) ==K true

  rule norm(T:FloatingType, I:Int) => norm(T, Int2Float(I))
  rule norm(T:FloatingType, F:Float) => tv(T, F)
endmodule

module CIL-COMMON-MMU
  imports CIL-SYNTAX
  imports CIL-TYPING-SYNTAX
  imports CIL-COMMON-PTR
  imports CIL-COMMON-VALUE-SERIALIZATION-INTERFACE
  imports CIL-COMMON-TYPED-VALUE

  syntax List ::= #rangeList(Int, Int, Int)                       [function]
                | #rangeList(Int, Int)                            [function]
                | #rangeList(Int)                                 [function]
                | "$rangeList" "(" Int "," Int "," Int ")"        [function]
                | "$downrangeList" "(" Int "," Int "," Int ")"    [function]
  rule #rangeList(I:Int) => #rangeList(0, I, 1)
  rule #rangeList(I:Int, J:Int) => #rangeList(I, J, 1)
  rule #rangeList(I:Int, J:Int, K:Int) => $rangeList(I, J, K)
  when K >Int 0 andBool I <Int J
  rule #rangeList(I:Int, J:Int, K:Int) => $downrangeList(I, J, (0 -Int K))
  when K <Int 0 andBool I >Int J
  rule
    $rangeList(I:Int, J:Int, K:Int)
  =>
    ListItem(I) $rangeList(I +Int K, J:Int, K:Int)
  when I <Int J 
  rule $rangeList(I:Int, J:Int, _) => .List
  when I >=Int J
  rule
    $downrangeList(I:Int, J:Int, K:Int)
  =>
    ListItem(I) $downrangeList(I -Int K, J:Int, K:Int)
  when I >Int J 
  rule $downrangeList(I:Int, J:Int, _) => .List
  when I <=Int J

  syntax Map ::= #initMap(List, K) [function]
  rule #initMap(ListItem(K1:K) L:List, K2:K) => K1 |-> K2 #initMap(L, K2)
  rule #initMap(.List, _) => .Map

  /*
   * Memory management.
   */
  syntax K ::= newObject(Type)
             | newZeroObject(Type)
             | "$newObject" "(" Type "," K "," ByteValue ")"   [strict(2)]
             | castObject(Type, Ptr)
             | deleteObject(Ptr)
  rule newObject(T:Type) => $newObject(T, sizeof(T), undef)
  [structural]
  rule newZeroObject(T:Type) => $newObject(T, sizeof(T), 0)
  [structural]
  rule
    <k> $newObject(T:Type, Sz:TypedValue, V:ByteValue)
      => tv(upPtr(T), Ptr(BasePtr(Base, mival(Sz)), 0))
    ...</k>
    <heap>...
      .Bag
    =>
      <object>
        <base-ptr> BasePtr(Base, (mival(Sz))) </base-ptr>
        <object-type> T </object-type>
        <bytes> #initMap(#rangeList(mival(Sz)), V) </bytes>
      </object>
    ...</heap>
  when fresh(Base:Int)
  [structural]
  rule
    <k> deleteObject(Ptr(BP:BasePtr, (0))) => .K ...</k>
    <heap>...
      <object>...
        <base-ptr> BP </base-ptr>
      ...</object>
    =>
      .Bag
    ...</heap>
  [structural]


  /*
   * Memory access.
   */
  syntax K ::= "load" "(" Type "," Ptr ")"
             | "$load" "(" Type "," Ptr "," K ")"             [strict(3)]
             | "$load" "(" Type "," Ptr "," Int "," List ")"
             | "store" "(" Type "," Ptr "," Value ")"
             | "$store" "(" Ptr "," List ")"

  rule 
    store(T:Type, P:Ptr, V:Value) => $store(P, value2Bytes(T, V))
  [structural]
  rule
    <k>
      $store(
          Ptr(BP:BasePtr, (Offset:Int => Offset +Int 1)),
          (ListItem(V:ByteValue) => .List) _:List)
    ...</k>
    <heap>...
      <object>...
        <base-ptr> BP </base-ptr>
        <bytes>... Offset |-> (_ => V) ...</bytes>
      ...</object>
    ...</heap>
  [structural]
  rule $store(_:Ptr, .List) => .K   [structural]

  rule load(T:Type, P:Ptr) => $load(T, P, sizeof(T))
    [structural]

  rule $load(T:Type, P:Ptr, Sz:TypedValue) 
    => $load(T, P, mival(Sz), .List)
  [structural]
  rule
    <k>
      $load(
          _:Type,
          Ptr(BP:BasePtr, (Offset:Int => Offset +Int 1)),
          (M:Int => M -Int 1),
          _:List (.List => ListItem(V:ByteValue)))
    ...</k>
    <base-ptr> BP </base-ptr>
    <bytes>... Offset |-> V ...</bytes>
    when M >Int 0
    [structural]

  // TODO(chathhorn): when any part of the object is undefined, we return undef
  // This is probably too crude.
  rule
    <k>
      $load(T:Type, Ptr(BP:BasePtr, Offset:Int), M:Int, _)
      => tv(T, undef)
    ...</k>
    <base-ptr> BP </base-ptr>
    <bytes> Bytes:Map </bytes>
    when (M >Int 0) andBool notBool (Offset in keys Bytes)
    [structural]
  rule
    $load(T:Type, _:Ptr, 0, L:List) => tv(T, bytes2Value(T, L))
    [structural]
endmodule

module CIL-COMMON
  imports MINT 
  imports CIL-COMMON-PTR
  imports CIL-COMMON-VALUE-SERIALIZATION-INTERFACE
  imports CIL-COMMON-TYPED-VALUE
  imports CIL-COMMON-MMU

  syntax Error ::= "dummy_Error_item"

  syntax Int ::= mival(TypedValue) [function]
  rule mival(tv(_, I:MInt)) => iMInt(I)

  /* 0 has identical signed and unsigned representations */
  syntax Bool ::= isZero(MInt) [function]
  rule isZero(MI:MInt) => iMInt(uMInt(MI)) ==Int 0

  /*
   * List{Stmt} concatenation
   */
  syntax Stmts ::= Stmts "@Stmts" Stmts   [left, function]
  rule (S:Stmt Ss1:Stmts) @Stmts Ss2:Stmts => S (Ss1 @Stmts Ss2)
  rule .Stmts @Stmts Ss:Stmts => Ss

  syntax ListItem ::= ListItem(Bag)

  syntax TransUnit ::= tu(String)
  syntax Phase ::= "initializing" | TransUnit | "executing" | "terminated"
    
endmodule
