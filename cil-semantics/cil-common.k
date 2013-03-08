require "cil-syntax.k"
require "builtins/mint.k"


module CIL-COMMON-PTR
  imports CIL-SYNTAX

  /*
   * Ptr of BasePtr * Offset
   * @invariant: 0 <= Offset <= BasePtr.Size
   * @immutable: BasePtr
   */
  syntax Ptr ::= "Ptr" "(" BasePtr "," Nat ")"
                | "Null"
  /*
   * BasePtr of Base * Size
   * @immutable: Base, Size 
   */
  syntax BasePtr ::= "BasePtr" "(" Int "," Nat ")"

  syntax Ptr ::= "PtrAdd" "(" Ptr "," Int "," Exp ")"    [function]
  syntax Int ::= "PtrSub" "(" Ptr "," Ptr "," Exp ")"    [function]
  syntax Bool ::= Ptr "==Ptr" Ptr    [function]
                | Ptr "=/=Ptr" Ptr   [function]
                | "PtrLt" "(" Ptr "," Ptr ")"    [function]
                | "PtrLeq" "(" Ptr "," Ptr ")"    [function]
                | "PtrGt" "(" Ptr "," Ptr ")"    [function]
                | "PtrGeq" "(" Ptr "," Ptr ")"    [function]

  /* Addition of pointer and index is defined only if there result Offset is in
   * the range [0, Size] */
  rule
    PtrAdd(Ptr(BasePtr(Base:Int, Size:Nat), Offset:Nat), I:Int, M:Nat)
  =>
    Ptr(BasePtr(Base, Size), (Offset +Int I *Int M))
  when 0 <=Int Offset +Int I *Int M andBool Offset +Int I *Int M <=Int Size

  /* Subtraction of pointers is defined only for the same BasePtr. */
  rule
    PtrSub(Ptr(BP:BasePtr, Offset1:Nat), Ptr(BP, Offset2:Nat), M:Nat)
  =>
    (Offset1 -Int Offset2) /Int M
  when (Offset1 -Int Offset2) %Int M ==Int 0

  /* Structural equality of addresses */
  rule
    Ptr(BasePtr(Base1:Int, Size1:Nat), Offset1:Nat)
    ==Ptr Ptr(BasePtr(Base2:Int, Size2:Nat), Offset2:Nat)
  =>
    Base1 ==Int Base2 andBool Size1 ==Int Size2 andBool Offset1 ==Int Offset2
  rule Null ==Ptr Null => true
  rule Ptr(_, _) ==Ptr Null => false
  rule Null ==Ptr Ptr(_, _) => false
  rule P1:Ptr =/=Ptr P2:Ptr => notBool(P1:Ptr ==Ptr P2:Ptr)

  /* Relational operations on pointers are defined only for the same BasePtr. */
  rule
    PtrLt(Ptr(BP:BasePtr, Offset1:Nat), Ptr(BP, Offset2:Nat))
  =>
    Offset1 <Int Offset2
  rule
    PtrLeq(Ptr(BP:BasePtr, Offset1:Nat), Ptr(BP, Offset2:Nat))
  =>
    Offset1 <=Int Offset2
  rule
    PtrGt(Ptr(BP:BasePtr, Offset1:Nat), Ptr(BP, Offset2:Nat))
  =>
    Offset1 >Int Offset2
  rule
    PtrGeq(Ptr(BP:BasePtr, Offset1:Nat), Ptr(BP, Offset2:Nat))
  =>
    Offset1 >=Int Offset2
endmodule

module CIL-COMMON-TYPE
  imports CIL-SYNTAX

  /*
   * @invariant
   */
  syntax Int ::= "width" "(" Type ")"       [function]
               | "byteWidth" "(" Type ")"   [function]

  syntax Value ::= Bool | Int | Float | Ptr | "undef" | MInt

  /*
   * @invariant:
   * Int ::= bytes2Value(IntType, List)
   * Float ::= bytes2Value(FloatingType, List)
   * Ptr ::= bytes2Value(PtrType, List)
   * byteWidth(T:Type) =Int #lenList(L:List)
   */
  syntax Value ::= "bytes2Value" "(" Type "," List ")"    [function]
  /*
   * @invariant:
   * value2Bytes(T:IntType, I:Int)
   * value2Bytes(T:FloatingType, F:Float)
   * value2Bytes(T:PtrType, P:Ptr)
   */
  syntax List ::= "value2Bytes" "(" Type "," Value ")"    [function] 
endmodule

module CIL-COMMON-MMU
  imports CIL-SYNTAX
  imports CIL-COMMON-PTR
  imports CIL-COMMON-TYPE

  syntax List ::= "#rangeList" "(" Int "," Int "," Int ")"        [function]
                | "#rangeList" "(" Int "," Int ")"                [function]
                | "#rangeList" "(" Int ")"                        [function]
                | "$rangeList" "(" Int "," Int "," Nat ")"        [function]
                | "$downrangeList" "(" Int "," Int "," Nat ")"    [function]
  rule #rangeList(I:Int) => #rangeList(0, I, 1)
  rule #rangeList(I:Int, J:Int) => #rangeList(I, J, 1)
  rule #rangeList(I:Int, J:Int, K:Int) => $rangeList(I, J, K)
  when K >Int 0 andBool I <Int J
  rule #rangeList(I:Int, J:Int, K:Int) => $downrangeList(I, J, (0 -Int K))
  when K <Int 0 andBool I >Int J
  rule
    $rangeList(I:Int, J:Int, K:Nat)
  =>
    ListItem(I) $rangeList(I +Int K, J:Int, K:Nat)
  when I <Int J 
  rule $rangeList(I:Int, J:Int, _) => .List
  when I >=Int J
  rule
    $downrangeList(I:Int, J:Int, K:Nat)
  =>
    ListItem(I) $downrangeList(I -Int K, J:Int, K:Nat)
  when I >Int J 
  rule $downrangeList(I:Int, J:Int, _) => .List
  when I <=Int J

  syntax Map ::= "Map" "(" List ")"   [function]
  rule Map(ListItem(K:K) L:List) => K |-> undef Map(L)
  rule Map(.List) => .Map
endmodule

module CIL-COMMON
  imports MINT
  imports CIL-COMMON-PTR
  imports CIL-COMMON-MMU
  imports CIL-COMMON-TYPE


  syntax Exp ::= TypedValue
  /*
   * @invariant:
   * tv(T:IntType, I:Int)
   * tv(T:FloatingType, F:Float)
   * tv(T:PtrType, P:Ptr)
   */
  syntax TypedValue ::= "tv" "(" Type "," Value ")"
                      | "norm" "(" Type "," Value ")"    [function]
  syntax TypedValues ::= List{TypedValue, ","}

  syntax LVal ::= NoConverionLeftValue
  syntax NoConverionLeftValue ::= "nclv" "(" Type "," Ptr ")"
  syntax LeftValue ::= "lv" "(" Type "," Ptr ")"

  syntax K ::= "noLeftValueConversion"
  rule
    //('lv`(_`,_`) => 'nclv`(_`,_`))(_:KList) ~> (noLeftValueConversion => .K)
    ('lv`(_`,_`) => 'nclv`(_`,_`))(_:KList) ~> noLeftValueConversion
  [structural]

  syntax Error ::= "dummy_Error_item"

  syntax MInt ::= "bool2mint" "(" Bool ")"   [function]
  rule
    bool2mint(B:Bool)
  =>
    tv(int, #if B #then mi((width(int)), 1) #else mi((width(int)), 0) #fi)
  /* 0 has identical signed and unsigned representations */
  syntax Bool ::= isZero(MInt)    [function]
  rule isZero(MI:MInt) => iMInt(uMInt(MI)) ==Int 0


  /*
   * List{Stmt} concatenation
   */
  syntax K ::= Stmts "@Stmts" Stmts   [function]
  rule (S:Stmt Ss1:Stmts) @Stmts Ss2:Stmts => S (Ss1 @Stmts Ss2)
  rule .Stmts @Stmts Ss:Stmts => Ss

  syntax ListItem ::= ListItem(Bag)
endmodule

