// vim: set ts=2 sw=2:
/*
 ************************************
 * Implementation defined semantics *
 ************************************
 */

require "cil-common.k"

module CIL-IMPLEMENTATION
  imports CIL-COMMON

  // "each enumerated type shall be compatible with char, a signed integer
  // type, or an unsigned integer type"
  rule enum X:CId => int [macro]

  /*
   * FIXME: it would be faster to treat each basic type individually, rather
   * that us byteWidthMacro
   */
  syntax Int ::= "byteWidthMacro" [function]
  rule byteWidthMacro => 8
  rule width(T:Type) => byteWidth(T:Type) *Int byteWidthMacro

  // This is also defined in a standard library header.
  syntax Type ::= "size_t" [function]
  rule size_t => unsigned long

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
  rule byteWidth(float)              => 4
  rule byteWidth(double)             => 8
  rule byteWidth(long double)        => 16
  rule byteWidth(_Bool)              => 1
  rule byteWidth(unsigned char)      => 1
  rule byteWidth(unsigned short)     => 2
  rule byteWidth(unsigned int)       => 4
  rule byteWidth(unsigned long)      => 8
  rule byteWidth(unsigned long long) => 8

  rule byteWidth(__builtin_va_list) => byteWidth(normType(void*))

  syntax MInt ::= bytes2SignedMInt(List)      [function]
                | bytes2UnsignedMInt(List)    [function]
  rule
    bytes2UnsignedMInt(ListItem(M:Int) L:List)
  =>
    mi((wMInt(bytes2UnsignedMInt(L)) +Int byteWidthMacro),
       (iMInt(bytes2UnsignedMInt(L)) <<Int byteWidthMacro) +Int M)
  rule bytes2UnsignedMInt(.List) => mi(0, 0)
  rule bytes2SignedMInt(L:List) => sMInt(bytes2UnsignedMInt(L))

  syntax List ::= "MInt2Bytes" "(" MInt ")" [function]
  rule
    MInt2Bytes(mi(N:Int, I:Int))
  =>
    ListItem(I modInt (1 <<Int byteWidthMacro))
    MInt2Bytes(mi((N -Int byteWidthMacro), I >>Int byteWidthMacro))
  when N >Int 0
  rule MInt2Bytes(mi((0), _)) => .List

  /* Size of pointers is 4 bytes (also the size of int) */
  rule byteWidth(T:Type) => 4
     when isPtrType(T)

  /* implement conversions */

  /*
   * Integers.
   */
  rule value2Bytes(_, MI:MInt) => MInt2Bytes(MI)

  rule bytes2Value(_:UnsignedIntType, L:List) => bytes2UnsignedMInt(L)
  rule bytes2Value(_:SignedIntType, L:List) => bytes2SignedMInt(L)

  /*
   * Floats.
   */
  syntax List ::= padBytes(Int) [function]
                | padBytes(Int, ByteValue) [function]
  
  rule padBytes(N:Int) => padBytes(N, used)

  rule padBytes(N:Int, V:ByteValue) 
    => ListItem(V) padBytes(N -Int 1, V)
    when N >Int 0
  rule padBytes(0, _) => .List

  rule value2Bytes(T:FloatingType, F:Float) 
    => ListItem(F) padBytes(byteWidth(T) -Int 1)

  rule bytes2Value(_:FloatingType, 
    ListItem(F:Float) _:List) => F
  rule bytes2Value(_:FloatingType, 
    ListItem(0) _:List) => 0.0

  /*
   * Strings.
   */
  rule value2Bytes(T:Type, S:String)
     => ListItem(ordChar(substrString(S, 0, 1)))
      value2Bytes(T, substrString(S, 1, lengthString(S)))
     when lengthString(S) >Int 0
  rule value2Bytes(_, "") => ListItem(0)

  /*
   * Pointers.
   */
  rule value2Bytes(T:Type, P:Ptr) 
    => ListItem(P) padBytes(byteWidth(T) -Int 1)

  rule bytes2Value(_,
      ListItem(P:Ptr) _:List)
    => P

  // TODO(chathhorn): width might be greater than the pointer type allows.
  rule bytes2Value(T:Type, L:List) 
    => bytes2UnsignedMInt(L)
    when isPtrType(T)

  /*
   * Aggregates and arrays.
   */
  rule value2Bytes(_, agg(L:List)) => L
  rule bytes2Value(T:Type, L:List) => agg(L)
    when (isArrayType(T) ==K true)
      orBool (isAggType(T) ==K true)

  /*
   * Undef.
   */
  rule value2Bytes(T:Type, undef)
    => padBytes(byteWidth(T), undef)

endmodule

