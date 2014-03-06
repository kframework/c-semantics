// vim: set ts=2 sw=2:
/*
 ************************************
 * Implementation defined semantics *
 ************************************
 */
require "builtins/list.k"

require "cil-common.k"

module CIL-IMPLEMENTATION
  imports LIST
  imports CIL-COMMON

  // "each enumerated type shall be compatible with char, a signed integer
  // type, or an unsigned integer type"
  rule enum _:CId => int [macro]

  /*
   * FIXME: it would be faster to treat each basic type individually, rather
   * that use byteWidthMacro
   */
  syntax Int ::= "byteWidthMacro" [function]
  rule byteWidthMacro => 8
  rule width(T:Type) => byteWidth(T:Type) *Int byteWidthMacro

  /* This is also defined in a standard library header. */
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

  syntax MInt ::= bytes2SignedMInt(MyList)      [function]
                | bytes2UnsignedMInt(MyList)    [function]
  rule
    bytes2UnsignedMInt(MyListItem(M:Int), L:MyList)
  =>
    mi((wMInt(bytes2UnsignedMInt(L)) +Int byteWidthMacro),
       (iMInt(bytes2UnsignedMInt(L)) <<Int byteWidthMacro) +Int M)
  rule bytes2UnsignedMInt(.MyList) => mi(0, 0)
  rule bytes2SignedMInt(L:MyList) => sMInt(bytes2UnsignedMInt(L))

  syntax MyList ::= "MInt2Bytes" "(" MInt ")" [function]
  rule
    MInt2Bytes(mi(N:Int, I:Int))
  =>
    MyListItem(I modInt (1 <<Int byteWidthMacro)),
    MInt2Bytes(mi((N -Int byteWidthMacro), I >>Int byteWidthMacro))
  when N >Int 0
  rule MInt2Bytes(mi((0), _)) => .MyList

  /* Size of pointers is 4 bytes (also the size of int) */
  rule byteWidth(T:Type) => 4
     when isPtrType(T)

  /* implement conversions */

  /*
   * Integers.
   */
  rule value2Bytes(_, MI:MInt) => MInt2Bytes(MI)

  rule bytes2Value(_:UnsignedIntType, L:MyList) => bytes2UnsignedMInt(L)
  rule bytes2Value(_:SignedIntType, L:MyList) => bytes2SignedMInt(L)

  /*
   * Floats.
   */
  syntax MyList ::= padBytes(Int) [function]
                  | padBytes(Int, ByteValue) [function]
  
  rule padBytes(N:Int) => padBytes(N, used)

  rule padBytes(N:Int, V:ByteValue) 
    => MyListItem(V), padBytes(N -Int 1, V)
    when N >Int 0
  rule padBytes(0, _) => .MyList

  rule value2Bytes(T:FloatingType, F:Float) 
    => MyListItem(F), padBytes(byteWidth(T) -Int 1)

  rule bytes2Value(_:FloatingType, (MyListItem(F:Float), _:MyList)) => F
  rule bytes2Value(_:FloatingType, (MyListItem(0), _:MyList)) => 0.0

  /*
   * Strings.
   */
  rule value2Bytes(T:Type, S:String)
    => MyListItem(ordChar(substrString(S, 0, 1))),
       value2Bytes(T, substrString(S, 1, lengthString(S)))
    when lengthString(S) >Int 0
  rule value2Bytes(_, "") => MyListItem(0)

  /*
   * Pointers.
   */
  rule value2Bytes(T:Type, P:Ptr) 
    => MyListItem(P), padBytes(byteWidth(T) -Int 1)

  rule bytes2Value(T, (MyListItem(P:Ptr), _:MyList))
    => P

  // TODO(chathhorn): width might be greater than the pointer type allows.
  // TODO(AndreiS): this rules conflicts with the one above
  //rule bytes2Value(T:Type, L:MyList) 
  //  => bytes2UnsignedMInt(L)
  //  when isPtrType(T)

  /*
   * Aggregates and arrays.
   */
  rule value2Bytes(_, agg(L:MyList)) => L
  rule bytes2Value(T:Type, L:MyList) => agg(L)
    when (isArrayType(T) ==K true) orBool (isAggType(T) ==K true)

  /*
   * Undef.
   */
  rule value2Bytes(T:Type, undef)
    => padBytes(byteWidth(T), undef)

endmodule

