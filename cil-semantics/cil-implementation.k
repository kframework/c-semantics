/*
 ************************************
 * Implementation defined semantics *
 ************************************
 */


require "cil-common.k"


module CIL-IMPLEMENTATION
  imports CIL-COMMON

  /*
   * FIXME: it would be faster to treat each basic type individually, rather
   * that us byteWidthMacro
   */
  syntax Int ::= "byteWidthMacro" [function]
  rule byteWidthMacro => 8
  rule width(T:Type) => byteWidth(T:Type) *Int byteWidthMacro


  /*
   * Integer types.
   */
  rule char => signed char [macro]

  /* The following values are used by gcc on x86_64 architectures. */
  rule byteWidth(signed char)        => 1
  rule byteWidth(short)              => 2
  rule byteWidth(int)                => 4
  rule byteWidth(long)               => 8
  rule byteWidth(long long)          => 8
  // rule byteWidth(_Bool)              => 1
  rule byteWidth(unsigned char)      => 1
  rule byteWidth(unsigned short)     => 2
  rule byteWidth(unsigned int)       => 4
  rule byteWidth(unsigned long)      => 8
  rule byteWidth(unsigned long long) => 8

  syntax MInt ::= bytes2SignedMInt(List)      [function]
                | bytes2UnsignedMInt(List)    [function]
  rule
    bytes2UnsignedMInt(ListItem(M:Int) L:List)
  =>
    mi((wMInt(bytes2UnsignedMInt(L)) +Int byteWidthMacro),
       (iMInt(bytes2UnsignedMInt(L)) <<Int byteWidthMacro) +Int M)
  rule bytes2UnsignedMInt(.List) => mi((0), 0)
  rule bytes2SignedMInt(L:List) => sMInt(bytes2UnsignedMInt(L))

  syntax List ::= "MInt2Bytes" "(" MInt ")" [function]
  rule
    MInt2Bytes(mi(N:Int, I:Int))
  =>
    ListItem(I modInt (1 <<Int byteWidthMacro))
    MInt2Bytes(mi((N -Int byteWidthMacro), I >>Int byteWidthMacro))
  when N >Int 0
  rule MInt2Bytes(mi((0), _)) => .List

  /* implement conversions */
  rule bytes2Value(_:UnsignedIntType, L:List) => bytes2UnsignedMInt(L)
  rule bytes2Value(_:SignedIntType, L:List) => bytes2SignedMInt(L)
  rule value2Bytes(_:IntType, MI:MInt) => MInt2Bytes(MI)

  rule bytes2Value(_:AggTypeSpec, L:List) => agg(L)
  rule value2Bytes(_:AggTypeSpec, agg(L:List)) => L

  /*
   * Pointer type.
   */
  /* Size of pointers is 4 bytes (also the size of int) */
  rule byteWidth(T:Type) => 4
     when isPtrType(T)

  /* implement conversions */
  rule
    value2Bytes(_:Type, Ptr(BasePtr(Base:Int, (Size:Int)), (Offset:Int)))
  =>
    ListItem(Base) ListItem(Size) ListItem(Offset) ListItem(0)
  rule value2Bytes(_:Type, Null) 
    => ListItem(0) ListItem(0) ListItem(0) ListItem(0)

  rule
    bytes2Value(
        _:Type,
        ListItem(Base:Int) ListItem(Size:Int) ListItem(Offset:Int) ListItem(0))
  =>
    Ptr(BasePtr(Base, (Size)), (Offset))
endmodule

