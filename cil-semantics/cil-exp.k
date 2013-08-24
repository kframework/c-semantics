// vim: set ts=2 sw=2:
require "cil-common.k"

/* CId variable conventions:
     X variable
     M structure member
     F function */

module CIL-LITERAL

  syntax String ::= carStr(String) [function]
                  | cdrStr(String) [function]

  rule carStr(S:String) => substrString(S, 0, 1)
  rule cdrStr(S:String) => substrString(S, 1, lengthString(S))

  syntax String ::= getNumericPart(String) [function]
                  | "getNumericPart'" "(" String "," String ")" [function]

  // lnp x::xs => lnp xs when x == 0 or x

  syntax Bool ::= isPrefixChar(String) [function]
                | isSuffixChar(String) [function]

  rule isPrefixChar(S:String) => true
    when (S ==String "0") 
      orBool (S ==String "x")
      orBool (S ==String "X")
      orBool (S ==String "\\")
  rule isPrefixChar(S:String) => false
    when (S =/=String "0") 
      andBool (S =/=String "x")
      andBool (S =/=String "X")
      andBool (S =/=String "\\")

  rule isSuffixChar(S:String) => true
    when (S ==String "u") 
      orBool (S ==String "l")
      orBool (S ==String "U")
      orBool (S ==String "L")
  rule isSuffixChar(S:String) => false
    when (S =/=String "u") 
      andBool (S =/=String "l")
      andBool (S =/=String "U")
      andBool (S =/=String "L")

  rule getNumericPart(S:String) 
    => getNumericPart(cdrStr(S))
    when isPrefixChar(carStr(S))
      andBool (S =/=String "")
  rule getNumericPart(S:String) 
    => getNumericPart'(S, "")
    when notBool isPrefixChar(carStr(S))
      andBool (S =/=String "")
  rule getNumericPart("") => "0"
  
  rule getNumericPart'(S:String, Num:String)
    => getNumericPart'(cdrStr(S), Num +String carStr(S))
    when notBool isSuffixChar(carStr(S))
      andBool (S =/=String "")
  rule getNumericPart'(S:String, Num:String) => Num
    when isSuffixChar(carStr(S))
      andBool (Num =/=String "")

  rule getNumericPart'("", Num:String) => Num
    when Num =/=String ""
  rule getNumericPart'(S:String, "") => "0"
    when isSuffixChar(carStr(S))
  rule getNumericPart'("", "") => "0"

  syntax String ::= getSuffix(String) [function]

  rule getSuffix(S:String) => getSuffix(cdrStr(S))
    when notBool isSuffixChar(carStr(S))
      andBool (S =/=String "")
  rule getSuffix(S:String) => normSuffix(S)
    when isSuffixChar(carStr(S))
  rule getSuffix("") => ""

  syntax String ::= normSuffix(String) [function]

  rule normSuffix("") => ""
  rule normSuffix(S:String) => "U"
    when (S ==String "u")
      orBool (S ==String "U")

  rule normSuffix(S:String) => "L"
    when (S ==String "l")
      orBool (S ==String "L")

  rule normSuffix(S:String) => "LL"
    when (S ==String "ll")
      orBool (S ==String "LL")

  rule normSuffix(S:String) => "UL"
    when (S ==String "ul")
      orBool (S ==String "uL")
      orBool (S ==String "Ul")
      orBool (S ==String "UL")
      orBool (S ==String "lu")
      orBool (S ==String "Lu")
      orBool (S ==String "lU")
      orBool (S ==String "LU")

  rule normSuffix(S:String) => "ULL"
    when (S ==String "ull")
      orBool (S ==String "uLL")
      orBool (S ==String "Ull")
      orBool (S ==String "ULL")
      orBool (S ==String "llu")
      orBool (S ==String "LLu")
      orBool (S ==String "llU")
      orBool (S ==String "LLU")

  syntax Int ::= String2Base(String, Int)
    [function, hook(#CONVERSION:string2Base)]

endmodule

module CIL-PROMOTION
  imports CIL-COMMON

  syntax K ::= "typeinfo" "(" Int "," Int "," Int ")"

  /* empty: implicit casts inserted by cilly */
endmodule

module CIL-EXP
  imports CIL-TYPING-SYNTAX
  imports CIL-PROMOTION
  imports CIL-IMPLEMENTATION
  imports CIL-LITERAL

  syntax K ::= "noLeftValueConversion"

  syntax K ::= Type [avoid]

  rule I:Int => norm(int, I)

  /* Constants. */
  rule C:DecimalConstant 
    => norm(int, String2Int(getNumericPart(#tokenToString(C))))
    when getSuffix(#tokenToString(C)) ==String ""
    [structural]
  rule C:DecimalConstant 
    => norm(long, String2Int(getNumericPart(#tokenToString(C))))
    when getSuffix(#tokenToString(C)) ==String "L"
    [structural]
  rule C:DecimalConstant 
    => norm(long long, String2Int(getNumericPart(#tokenToString(C))))
    when getSuffix(#tokenToString(C)) ==String "LL"
    [structural]
  rule C:DecimalConstant 
    => norm(unsigned int, String2Int(getNumericPart(#tokenToString(C))))
    when getSuffix(#tokenToString(C)) ==String "U"
    [structural]
  rule C:DecimalConstant 
    => norm(unsigned long, String2Int(getNumericPart(#tokenToString(C))))
    when getSuffix(#tokenToString(C)) ==String "UL"
    [structural]
  rule C:DecimalConstant 
    => norm(unsigned long long, String2Int(getNumericPart(#tokenToString(C))))
    when getSuffix(#tokenToString(C)) ==String "ULL"
    [structural]

  rule C:OctalConstant 
    => norm(int, String2Base(getNumericPart(#tokenToString(C)), 8))
    when getSuffix(#tokenToString(C)) ==String ""
    [structural]
  rule C:OctalConstant 
    => norm(long, String2Base(getNumericPart(#tokenToString(C)), 8))
    when getSuffix(#tokenToString(C)) ==String "L"
    [structural]
  rule C:OctalConstant 
    => norm(long long, String2Base(getNumericPart(#tokenToString(C)), 8))
    when getSuffix(#tokenToString(C)) ==String "LL"
    [structural]
  rule C:OctalConstant 
    => norm(unsigned int, String2Base(getNumericPart(#tokenToString(C)), 8))
    when getSuffix(#tokenToString(C)) ==String "U"
    [structural]
  rule C:OctalConstant 
    => norm(unsigned long, String2Base(getNumericPart(#tokenToString(C)), 8))
    when getSuffix(#tokenToString(C)) ==String "UL"
    [structural]
  rule C:OctalConstant 
    => norm(unsigned long long, 
      String2Base(getNumericPart(#tokenToString(C)), 8))
    when getSuffix(#tokenToString(C)) ==String "ULL"
    [structural]

  rule C:HexConstant 
    => norm(int, String2Base(getNumericPart(#tokenToString(C)), 16))
    when getSuffix(#tokenToString(C)) ==String ""
    [structural]
  rule C:HexConstant 
    => norm(long, String2Base(getNumericPart(#tokenToString(C)), 16))
    when getSuffix(#tokenToString(C)) ==String "L"
    [structural]
  rule C:HexConstant 
    => norm(long long, String2Base(getNumericPart(#tokenToString(C)), 16))
    when getSuffix(#tokenToString(C)) ==String "LL"
    [structural]
  rule C:HexConstant 
    => norm(unsigned int, String2Base(getNumericPart(#tokenToString(C)), 16))
    when getSuffix(#tokenToString(C)) ==String "U"
    [structural]
  rule C:HexConstant 
    => norm(unsigned long, String2Base(getNumericPart(#tokenToString(C)), 16))
    when getSuffix(#tokenToString(C)) ==String "UL"
    [structural]
  rule C:HexConstant 
    => norm(unsigned long long, 
      String2Base(getNumericPart(#tokenToString(C)), 16))
    when getSuffix(#tokenToString(C)) ==String "ULL"
    [structural]

  rule F:Float => tv(double, F)
    [structural]

  // TODO(chathhorn): prefixes (wide chars I guess).
  rule ' C:Char ' => norm(int, ordChar(#tokenToString(C)))
  rule ' \' ' => norm(int, 39)
  rule ' \\ ' => norm(int, 92)
  rule ' \a ' => norm(int, 7)
  rule ' \b ' => norm(int, 8)
  rule ' \t ' => norm(int, 9)
  rule ' \v ' => norm(int, 11)
  // TODO(chathhorn): Geh, the token becomes a string containing an octal
  // escape code.
  rule ' C:OctalStringEscape ' 
    => norm(int, ordChar(#tokenToString(C)))
  rule ' C:HexStringEscape ' 
    => norm(int, String2Base(getNumericPart(#tokenToString(C)), 16))

  /* lookup */
  rule
    <k> X:CId => lv(expandTypedefs(T, E), P) ...</k>
    <env> E:Map X |-> lv(T:Type, P:Ptr) </env>
    [structural]

  // Typedefs.
  rule
    <k> X:CId => nt(expandTypedefs(T, E)) ...</k>
    <env> E:Map X |-> T:Type </env>
    [structural]

  rule 
    <k> S:String 
      => newString(S, newObject(normType(char [lengthString(S) +Int 1])))
    ...</k>
    <strings> Ss:Map </strings>
    when notBool (S in keys Ss)

  rule 
    <k> S:String => lv(normType(char [lengthString(S) +Int 1]), P) ...</k>
    <strings>... S |-> P:Ptr ...</strings>

  syntax K ::= newString(String, K) [strict(2)]
  rule <k> newString(S:String, tv(T:Type, P:Ptr))
    => store(downPtr(T), P, S) ~> lv(downPtr(T), P)
    ...</k>
    <strings>... . => S |-> P </strings>

  // Doesn't work as a macro because it will mangle array declarations.
  rule E1:Exp[E2:Exp] => *(E1 + E2) 

  context (HOLE => HOLE ~> noLeftValueConversion) . _:CId
  rule 
    <k> 
      nclv(Agg:AggTypeSpec, Ptr(Base:BasePtr, Offset:Int)) . M:CId 
      => lv(T, Ptr(Base, Offset +Int MOffset))
    ...</k>
    <agg-id> Agg </agg-id>
    <field-id> M </field-id>
    <field-type> T:Type </field-type>
    <offset> MOffset:Int </offset>

  /* TODO: '&_ */
  context &(HOLE => HOLE ~> noLeftValueConversion)
  rule &nclv(T:Type, P:Ptr) => tv(upPtr(T), P)
    when isArrayType(T) =/=K true
    [structural]
  
  /* Pointer dereference. */
  rule *tv(T:Type, P:Ptr) => lv(downPtr(T), P) 
    when isVaList(P) =/=K true 
    [structural]

  /* Dereference of hacky VaLists, which should never be r-values. */
  rule *tv(T:Type, va_list(tv(_, V:Value))) => tv(downPtr(T), V) 
    [structural]

  context '_=_;((HOLE => HOLE ~> noLeftValueConversion),, _)
  rule nclv(T:Type, P:Ptr) = tv(T, V:Value); => store(T, P, V)
    
  rule (lv(T:Type, P:Ptr) => load(T, P)) ~> KLabel:KLabel(KList:KList)
    when (KLabel(KList) =/=K noLeftValueConversion)
      andBool ((isArrayType(T) =/=K true)
        orBool (KLabel(KList) ==K sizeofContext))
      andBool (isFunType(T) =/=K true)
  // Arrays decay to a pointer (except as an operand to sizeof() or &).
  rule (lv(T:Type, P:Ptr) => tv(upPtr(downArray(T)), P)) 
    ~> KLabel:KLabel(KList:KList)
    when (KLabel(KList) =/=K noLeftValueConversion)
      andBool (KLabel(KList) =/=K sizeofContext)
      andBool (isArrayType(T) ==K true)
  // Functions decay to a function pointer.
  rule (lv(T:Type, P:Ptr) => tv(upPtr(T), P)) 
    ~> KLabel:KLabel(KList:KList)
    when (KLabel(KList) =/=K noLeftValueConversion)
      andBool (isFunType(T) ==K true)

  rule ('lv => 'nclv)(_:KList) ~> noLeftValueConversion
  [structural]

  /*
   * Arithmetic operators semantics.
   */
  /* Unary plus */
  rule +tv(T:Type, I:MInt) => tv(T, I)
  /* Unary minus */
  /* FIXME standard is unclear about the semantics of unary minus */
  rule -tv(T:Type, I:MInt) => norm(T, 0) - tv(T, I)

  // TODO: under/overflow.
  /* Addition */
  rule tv(T:SignedIntType, MI1:MInt) + tv(T, MI2:MInt) 
    => tv(T, miMInt(addMInt(MI1, MI2)))
//    when notBool ufMInt(addMInt(MI1, MI2)) andBool
//      notBool ofMInt(addMInt(MI1, MI2))
  rule tv(T:UnsignedIntType, MI1:MInt) + tv(T, MI2:MInt)
    => tv(T, miMInt(uaddMInt(MI1, MI2)))

  /* Subtraction */
  rule tv(T:SignedIntType, MI1:MInt) - tv(T, MI2:MInt)
    => tv(T, miMInt(subMInt(MI1, MI2)))
//  when notBool ufMInt(subMInt(MI1, MI2)) andBool
//    notBool ofMInt(subMInt(MI1, MI2))
  rule tv(T:UnsignedIntType, MI1:MInt) - tv(T, MI2:MInt)
    => tv(T, miMInt(usubMInt(MI1, MI2)))

  /* Multiplication */
  rule tv(T:SignedIntType, MI1:MInt) * tv(T, MI2:MInt)
    => tv(T, miMInt(mulMInt(MI1, MI2)))
//  when notBool ufMInt(mulMInt(MI1, MI2)) andBool
//    notBool ofMInt(mulMInt(MI1, MI2))
  rule tv(T:UnsignedIntType, MI1:MInt) * tv(T, MI2:MInt)
    => tv(T, miMInt(umulMInt(MI1, MI2)))

  /* Division */
  rule tv(T:SignedIntType, MI1:MInt) / tv(T, MI2:MInt)
    => tv(T, miMInt(divMInt(MI1, MI2)))
    when divMInt(MI1, MI2) =/=K errMInt 
      andBool notBool ofMInt(divMInt(MI1, MI2))
  rule tv(T:UnsignedIntType, MI1:MInt) / tv(T, MI2:MInt)
    => tv(T, miMInt(udivMInt(MI1, MI2)))
    when udivMInt(MI1, MI2) =/=K errMInt

  /* Remainder */
  /* signed remainder is defined only when signed division is defined */
  rule tv(T:SignedIntType, MI1:MInt) % tv(T, MI2:MInt)
    => tv(T, miMInt(remMInt(MI1, MI2)))
    when divMInt(MI1, MI2) =/=K errMInt 
      andBool notBool ofMInt(divMInt(MI1, MI2))
  rule tv(T:UnsignedIntType, MI1:MInt) % tv(T, MI2:MInt)
    => tv(T, miMInt(uremMInt(MI1, MI2)))
    when udivMInt(MI1, MI2) =/=K errMInt

  rule ~tv(T:Type, I:MInt) => norm(T, ~Int iMInt(I))
  rule tv(T:Type, I:MInt) << tv(_, N:MInt) 
    => norm(T, iMInt(I) <<Int iMInt(N))
    when iMInt(N) <Int width(T)
  rule tv(T:Type, I:MInt) >> tv(_, N:MInt) 
    => norm(T, iMInt(I) <<Int iMInt(N))
    when iMInt(N) <Int width(T)

  /* Relation operators */
  rule tv(T:SignedIntType, MI1:MInt) < tv(T, MI2:MInt)
    => norm(int, ltMInt(MI1, MI2))
  rule tv(T:UnsignedIntType, MI1:MInt) < tv(T, MI2:MInt)
    => norm(int, ultMInt(MI1, MI2))
  rule tv(T:SignedIntType, MI1:MInt) <= tv(T, MI2:MInt)
    => norm(int, leqMInt(MI1, MI2))
  rule tv(T:UnsignedIntType, MI1:MInt) <= tv(T, MI2:MInt)
    => norm(int, uleqMInt(MI1, MI2))
  rule tv(T:SignedIntType, MI1:MInt) > tv(T, MI2:MInt)
    => norm(int, gtMInt(MI1, MI2))
  rule tv(T:UnsignedIntType, MI1:MInt) > tv(T, MI2:MInt)
    => norm(int, ugtMInt(MI1, MI2))
  rule tv(T:SignedIntType, MI1:MInt) >= tv(T, MI2:MInt)
    => norm(int, geqMInt(MI1, MI2))
  rule tv(T:UnsignedIntType, MI1:MInt) >= tv(T, MI2:MInt)
    => norm(int, ugeqMInt(MI1, MI2))

  /* Relation operators */
  rule tv(T:Type, MI1:MInt) == tv(T, MI2:MInt)
    => norm(int, MI1 ==MInt MI2)
  rule tv(T:Type, MI1:MInt) != tv(T, MI2:MInt)
    => norm(int, MI1 =/=MInt MI2)

  rule !tv(_:Type, I:MInt) => norm(int, 1)
    when isZero(I)
  rule !tv(_:Type, I:MInt) => norm(int, 0)
    when notBool isZero(I)

  /*
   * Sizeof
   */

  // Things are special inside a sizeof (in particular, arrays don't decay).
  syntax K ::= "sizeofContext"
  context sizeof(HOLE => HOLE ~> sizeofContext)

  syntax K ::= "sizeof'" "(" Type ")"
  rule sizeof(nt(T:Type)) => sizeof'(T)
  rule sizeof(tv(T:Type, _)) => sizeof'(T)

  rule sizeof'(T:Type) => (size_t) byteWidth(T)
    when (isBasicType(T) ==K true) 
      orBool (isPtrType(T) ==K true)
    [structual]
  rule sizeof'(T:Type) 
    => (size_t) sizeof'(downArray(T)) * (size_t) getArraySize(T)
    when isArrayType(T) ==K true
    [structual]
  rule <k> sizeof'(T:AggTypeSpec) => (size_t) Size ...</k>
    <agg-id> T </agg-id>
    <size> Size:Int </size>
    [structural]
  
  /*
   * Casting
   */
  rule <k> T:Type => nt(expandTypedefs(normType(T), E)) ...</k>
    <env> E:Map </env>
    // If it's a CId then we look it up in the env until we get an unambiguous
    // type.
    when ((isCId(T) =/=K true) orBool (isKeyword(T) ==K true))
      andBool (isNormType(T) =/=K true)
      // This case is ambiguous with the Exp syntax.
      andBool ($isConstArrayDeref(T, E) =/=K true)

  // Disambiguate the typedef_name[Constant] case from the var[Constant] case.
  syntax Bool ::= "$isConstArrayDeref" "(" K "," Map ")" [function]
  rule $isConstArrayDeref(X:CId[_:Constant], (_ X |-> lv(_,_) _)) => true

  // TODO(chathhorn): should find a better way. I'm basically turning something
  // that has been misparsed as a Type into an Exp.
  rule <k> X:CId[C:Constant] => '_`[_`](X,, C)::Exp ...</k>
    <env>... X |-> lv(_,_) ...</env>

  /* the rule for signed integer types is implementation defined */
  rule (nt(T:SignedIntType)) tv(_:Type, I:MInt) => norm(T, I)

  rule (nt(T:UnsignedIntType)) tv(_:Type, I:MInt) => norm(T, I)

  // Allowing all casts between floating point types.
  rule (nt(To:FloatingType)) tv(_, F:Float) => norm(To, F)

  // Allowing all casts between ints and floats.
  rule (nt(To:FloatingType)) tv(_, I:MInt) => norm(To, I)
  rule (nt(To:IntType)) tv(_, F:Float) => norm(To, F)

  // Pointers to void may be cast to or from any pointer type.
  rule (nt(To:Type)) tv(From:Type, V:Value) => tv(To, V)
    when ((isPtrType(To) ==K true) andBool (isPtrType(From) ==K true))
      andBool ((downPtr(To) ==K void) orBool (downPtr(From) ==K void))

  // Null pointers (or 0) may be cast to any pointer type.
  rule (nt(To:Type)) tv(_, I:MInt) => tv(To, Null)
    when (isPtrType(To) ==K true) andBool (iMInt(I) ==Int 0)
  rule (nt(To:IntType)) tv(_, Null) => norm(To, 0)

  // TODO(chathhorn): Pointers may be converted to integers and the result is
  // implementation-defined (apparently except in the case of Null). But also
  // comparisons and such must still work for pointers with the same base, even
  // after being cast to an IntType. 
  rule (nt(To:IntType)) tv(_:Type, Ptr(BasePtr(Base:Int, _), Offset:Int)) 
    => norm(To, symToInt(Base) +Int Offset)

  // Ints to pointers.
  rule (nt(To:Type)) tv(_:IntType, I:MInt) => norm(To, I)
    when isPtrType(To) ==K true

  syntax Int ::= symToInt(K) [function]
  rule symToInt(#symInt(I:Int)) => I

  // Pointers of one type may be converted to pointers of another type and back
  // again. The result should compare equal to the original pointer.
  rule (nt(To:Type)) tv(From:Type, P:Ptr) => tv(To, P)
    when (isPtrType(To) ==K true) andBool (isPtrType(From) ==K true)

  rule tv(T:Type, F1:Float) * tv(T, F2:Float) => tv(T, F1 *Float F2)
  rule tv(T:Type, F1:Float) / tv(T, F2:Float) => tv(T, F1 /Float F2)
    when F2 =/=Float 0.0

  rule tv(T:Type, F1:Float) + tv(T, F2:Float) => tv(T, F1 +Float F2)
  rule tv(T:Type, F1:Float) - tv(T, F2:Float) => tv(T, F1 -Float F2)
 
  context tv(_, PtrAdd(_, _, HOLE))
  rule tv(T:Type, P:Ptr) + tv(_, mi(_, I:Int)) 
    => tv(T, PtrAdd(P, I, sizeof(downPtr(T))))
    when isPtrType(T)
  rule tv(_, mi(_, I:Int)) + tv(T:Type, P:Ptr) 
    => tv(T, PtrAdd(P, I, sizeof(downPtr(T))))
    when isPtrType(T)
  rule tv(_, I:Int) + tv(T:Type, P:Ptr) 
    => tv(T, PtrAdd(P, I, sizeof(downPtr(T))))
    when isPtrType(T)
  rule
    tv(T:Type, P:Ptr) - tv(_, mi(_, I:Int))
    => tv(T, PtrAdd(P, 0 -Int I, sizeof(downPtr(T))))
    when isPtrType(T)
// 
//   /* TODO: replace int with size_ptr */
//   context tv(_, PtrSub(_, _, HOLE))
//   rule
//     tv(T:Type*, P1:Ptr) - tv(T*, P2:Ptr) => tv(int, PtrSub(P1, P2, sizeof(T)))
  
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

  rule tv(T:Type, I1:MInt) & tv(T, I2:MInt) 
    => norm(T, iMInt(I1) &Int iMInt(I2))
  rule tv(T:Type, I1:MInt) ^ tv(T, I2:MInt) 
    => norm(T, iMInt(I1) xorInt iMInt(I2))
  rule tv(T:Type, I1:MInt) | tv(T, I2:MInt) 
    => norm(T, iMInt(I1) |Int iMInt(I2))

  /* TODO: '_&&_, '_||_ and '_?_:_  are not generated by CIL */
  /* FIXME: convert non-zero values to 1 */
  // rule tv(int, 1) && E:Exp => !(E == 0)
  // rule tv(int, 0) && _:Exp => tv(int, 0)
  // rule tv(int, 1) || _:Exp => tv(int, 1)
  // rule tv(int, 0) || E:Exp => !(E == 0)

  /* FIXME: undefined if E1 and E2 do not have compatible types */
  // rule tv(int, 1) ? E1:Exp : _:Exp => E1
  // rule tv(int, 0) ? _:Exp : E2:Exp => E2
endmodule

