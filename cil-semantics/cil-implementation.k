/*
 ************************************
 * Implementation defined semantics *
 ************************************
 */


require "cil-common.k"


module CIL-IMPLEMENTATION
  imports CIL-COMMON
  /* FIXME: it would be faster to treat each basic type individually */

  rule char => signed char

  /* The following values are used by gcc on MacOS X Mountain Lion. */
  rule byteWidth(signed char)        => 1
  rule byteWidth(short)              => 2
  rule byteWidth(int)                => 4
  rule byteWidth(long)               => 8
  rule byteWidth(long long)          => 8
  //rule byteWidth(_Bool)              => 1
  rule byteWidth(unsigned char)      => 1
  rule byteWidth(unsigned short)     => 2
  rule byteWidth(unsigned int)       => 4
  rule byteWidth(unsigned long)      => 8
  rule byteWidth(unsigned long long) => 8

  syntax Int ::= "ByteWidthMacro"   [function]
  rule ByteWidthMacro => 8

  rule width(T:Type) => byteWidth(T:Type) *Int ByteWidthMacro


  syntax MInt ::= "bytes2SignedMInt" "(" List ")"               [function]
                | "bytes2UnsignedMInt" "(" List ")"             [function]
  rule
    bytes2UnsignedMInt(ListItem(M:Nat) L:List)
  =>
    mi((wMInt(bytes2UnsignedMInt(L)) +Int ByteWidthMacro),
       (iMInt(bytes2UnsignedMInt(L)) <<Int ByteWidthMacro) +Int M)
  rule bytes2UnsignedMInt(.List) => mi((0), 0)
  rule bytes2SignedMInt(L:List) => sMInt(bytes2UnsignedMInt(L))

  syntax List ::= "MInt2Bytes" "(" MInt ")"   [function]
  rule
    MInt2Bytes(mi(N:Nat, I:Int))
  =>
    ListItem(I modInt (1 <<Int ByteWidthMacro))
    MInt2Bytes(mi((N -Int ByteWidthMacro), I >>Int ByteWidthMacro))
  when N >Int 0
  rule MInt2Bytes(mi((0), _)) => .List

  rule bytes2Value(T:UnsignedIntType, L:List) => bytes2UnsignedMInt(L)
  rule bytes2Value(T:SignedIntType, L:List) => bytes2SignedMInt(L)
  rule value2Bytes(T:IntType, MI:MInt) => MInt2Bytes(MI)
endmodule

