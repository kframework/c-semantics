// vim: set ts=2 sw=2:
require "cil-syntax.k"
require "builtins/mint.k"

module CIL-COMMON-PTR
  imports CIL-SYNTAX
  /*
   * Ptr of BasePtr * Offset
   * @invariant: 0 <= Offset <= BasePtr.Size
   * @immutable: BasePtr
   */
  syntax Ptr ::= Ptr(BasePtr, Int)
               | FunPtr(CId, TransUnit)
               | "Null"
  /*
   * BasePtr of Base * Size
   * @immutable: Base, Size 
   */
  syntax BasePtr ::= "BasePtr" "(" Int "," Int ")"

  syntax Ptr ::= "PtrAdd" "(" Ptr "," Int "," Exp ")"   [function]
  syntax Int ::= "PtrSub" "(" Ptr "," Ptr "," Exp ")"   [function]
  syntax Bool ::= Ptr "==Ptr" Ptr    [function]
                | Ptr "=/=Ptr" Ptr   [function]
                | "PtrLt" "(" Ptr "," Ptr ")"     [function]
                | "PtrLeq" "(" Ptr "," Ptr ")"    [function]
                | "PtrGt" "(" Ptr "," Ptr ")"     [function]
                | "PtrGeq" "(" Ptr "," Ptr ")"    [function]

  /* Addition of pointer and index is defined only if there result Offset is in
   * the range [0, Size] */
  rule
    PtrAdd(Ptr(BasePtr(Base:Int, Size:Int), Offset:Int), I:Int, M:Int)
  =>
    Ptr(BasePtr(Base, Size), (Offset +Int I *Int M))
  when 0 <=Int Offset +Int I *Int M andBool Offset +Int I *Int M <=Int Size

  /* Subtraction of pointers is defined only for the same BasePtr. */
  rule
    PtrSub(Ptr(BP:BasePtr, Offset1:Int), Ptr(BP, Offset2:Int), M:Int)
  =>
    (Offset1 -Int Offset2) /Int M
  when (Offset1 -Int Offset2) %Int M ==Int 0

  /* Structural equality of addresses */
  rule
    Ptr(BasePtr(Base1:Int, Size1:Int), Offset1:Int)
    ==Ptr Ptr(BasePtr(Base2:Int, Size2:Int), Offset2:Int)
  =>
    Base1 ==Int Base2 andBool Size1 ==Int Size2 andBool Offset1 ==Int Offset2
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

  syntax Value ::= ByteValue | Bool | Float | Ptr | MInt | agg(List)

  syntax ByteValue ::= Int | "undef"

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
  imports MINT
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

  syntax LVal ::= LeftValue
  syntax LeftValue ::= lv(Type, Ptr)

  syntax LVal ::= NoConversionLeftValue
  syntax NoConversionLeftValue ::= nclv(Type, Ptr)

  syntax Int ::= val(TypedValue) [function]
  rule val(tv(_, mi(_, V:Int))) => V
endmodule


module CIL-COMMON-MMU
  imports CIL-SYNTAX
  imports CIL-COMMON-TYPE
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
             | "$newObject" "(" Type "," K ")"   [strict(2)]
             | castObject(Type, Ptr)
             | deleteObject(Ptr)
  rule newObject(T:Type) => $newObject(T, sizeof(T))
  [structural]
  rule
    <k>
      $newObject(T:Type, Sz:TypedValue)
    =>
      tv(upPtr(T), Ptr(BasePtr(Base, val(Sz)), (0)))
    ...</k>
    <heap>...
      .Bag
    =>
      <object>
        <base-ptr> BasePtr(Base, (val(Sz))) </base-ptr>
        <object-type> T </object-type>
        <bytes> #initMap(#rangeList(val(Sz)), undef) </bytes>
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
             | "store" "(" Type "," Ptr "," Value ")"           [strict(1)]
             | "$store" "(" Ptr "," List ")"

  /* TODO: check beforehand that load/store would be successful */
  rule store(T:Type, P:Ptr, V:Value) => $store(P, value2Bytes(T, V))
  [structural]
  rule 
    <k> store((X:CId => T), _, _) ...</k>
    <typedefs>... X |-> T:Type ...</typedefs>
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

  rule load(T:Type, P:Ptr) => $load(T, P, sizeof(T)) [structural]
  rule 
    <k> load((X:CId => T), _) ...</k>
    <typedefs>... X |-> T:Type ...</typedefs>
  [structural]
  rule
    $load(T:Type, P:Ptr, Sz:TypedValue) => $load(T, P, (val(Sz)), .List)
  [structural]
  rule
    <k>
      $load(
          _:Type,
          Ptr(BP:BasePtr, (Offset:Int => Offset +Int 1)),
          (M:Int => M -Int 1),
          _:List (.List => ListItem(V:ByteValue)))
    ...</k>
    <heap>...
      <object>...
        <base-ptr> BP </base-ptr>
        <bytes>... Offset |-> V ...</bytes>
      ...</object>
    ...</heap>
  when M >Int 0
  [structural]
  rule
    $load(T:Type, _:Ptr, (0), L:List) => tv(T, bytes2Value(T, L))
  [structural]
endmodule


module CIL-COMMON
  imports MINT 
  imports CIL-COMMON-PTR
  imports CIL-COMMON-VALUE-SERIALIZATION-INTERFACE
  imports CIL-COMMON-TYPED-VALUE
  imports CIL-COMMON-MMU

  syntax Error ::= "dummy_Error_item"

  syntax MInt ::= bool2mint(Bool) [function]

  rule
    bool2mint(B:Bool)
  =>
    tv(int, #if B #then mi((width(int)), 1) #else mi((width(int)), 0) #fi)

  /* 0 has identical signed and unsigned representations */
  syntax Bool ::= isZero(MInt) [function]
  rule isZero(MI:MInt) => iMInt(uMInt(MI)) ==Int 0

  /*
   * List{Stmt} concatenation
   */
  syntax K ::= Stmts "@Stmts" Stmts   [function]
  rule (S:Stmt Ss1:Stmts) @Stmts Ss2:Stmts => S (Ss1 @Stmts Ss2)
  rule .Stmts @Stmts Ss:Stmts => Ss

  syntax ListItem ::= ListItem(Bag)

  syntax TransUnit ::= tu(String)
  syntax Phase ::= "initializing" | TransUnit | "executing" | "terminated"
endmodule

module CIL-COMMON-TYPE
  imports CIL-SYNTAX
  imports K-FUNCTIONAL-VISITOR

  syntax SymId ::= "#__id__"
  syntax DirectDecl ::= SymId

  // Visits only the leftmost branch of the AST.
  syntax K ::= #leftVisit(K, KLabel, KLabel) [function]
  rule #leftVisit(K:K, Trans:KLabel, Pred:KLabel)
    => Trans(K)
    when Pred(K) ==K true
  rule #leftVisit(Lbl:KLabel(K:K,, L:KList), Trans:KLabel, Pred:KLabel)
    => Lbl(#leftVisit(K, Trans, Pred),, L)
    when Pred(Lbl(K,, L)) =/=K true
  rule #leftVisit(Lbl:KLabel(.KList), Trans:KLabel, Pred:KLabel)
    => Lbl(.KList)
    when Pred(Lbl(.KList)) =/=K true

  // Searches the leftmost branch of the AST and returns the first node for
  // which the predicate holds, .K if nothing found.
  // AST to search, the predicate.
  syntax K ::= leftSearch(K, KLabel) [function]
  rule leftSearch(K:K, Pred:KLabel)
    => K
    when Pred(K) ==K true
  rule leftSearch(Lbl:KLabel(K:K,, L:KList), Pred:KLabel)
    => leftSearch(K, Pred)
    when Pred(Lbl(K,, L)) =/=K true
  rule leftSearch(Lbl:KLabel(.KList), Pred:KLabel)
    => .K
    when Pred(Lbl(.KList)) =/=K true

  // Checks if a normalized type is a pointer type.
  syntax Bool ::= isPtrType(Type) [function]
  syntax Bool ::= "$isPtrType" "(" K ")" [function, klabel('$isPtrType)]
  rule isPtrType(TS:TypeSpec) => false
  rule isPtrType(TS:TypeSpec D:Declarator) => leftSearch(D, '$isPtrType) =/=K .K
  rule $isPtrType(* #__id__) => true
  // TODO(chathhorn): not entirely sure how to treat this case.
  rule $isPtrType(#__id__[]) => true

  // Checks if a normalized type is an array type.
  syntax Bool ::= isArrayType(Type) [function]
  syntax Bool ::= "$isArrayType" "(" K ")" [function, klabel('$isArrayType)]
  rule isArrayType(TS:TypeSpec) => false
  rule isArrayType(TS:TypeSpec D:Declarator) => leftSearch(D, '$isArrayType) =/=K .K
  rule $isArrayType(#__id__[_:Constant]) => true

  // Returns the size of a normalized array type.
  syntax Int ::= getArraySize(Type) [function]
  syntax Int ::= "getArraySize'" "(" K ")" [function]
  rule getArraySize(TS:TypeSpec D:Declarator) 
    => getArraySize'(leftSearch(D, '$isArrayType))
  rule getArraySize'(#__id__[C:Constant]) => C

  // Add a layer of indirection to a normalized pointer type.
  syntax Type ::= upPtr(Type) [function]
  syntax DirectDecl ::= upPtrConv(DirectDecl) [function]
  rule upPtr(TS:TypeSpec) => normType(TS ('`(_`)(* #__id__))::Declarator)
  rule upPtr(TS:TypeSpec D:Declarator) 
    => normType(TS #leftVisit(D, 'upPtrConv, isSymId)::Declarator)
  rule upPtrConv(X:SymId) => '`(_`)(*X)

  // Remove a layer of indirection (from a normalized pointer type).
  syntax Type ::= downPtr(Type) [function]
  syntax Bool ::= "$needsDownPtrConv" "(" K ")" 
    [function, klabel('$needsDownPtrConv)]
  syntax Declarator ::= downPtrConv(Declarator) [function]
  rule downPtr(TS:TypeSpec D:Declarator) 
    => normType(TS #leftVisit(D, 'downPtrConv, '$needsDownPtrConv)::Declarator)
  rule $needsDownPtrConv(*X:SymId) => true
  rule downPtrConv(*X:SymId) => X

  // Remove a layer of indirection (from a normalized array type).
  syntax Type ::= downArray(Type) [function]
  syntax Bool ::= "$needsDownArrayConv" "(" K ")" 
    [function, klabel('$needsDownArrayConv)]
  syntax Declarator ::= downArrayConv(Declarator) [function]
  rule downArray(TS:TypeSpec D:Declarator) 
    => normType(TS #leftVisit(D, 'downArrayConv, '$needsDownArrayConv)::Declarator)
  rule $needsDownArrayConv(X:SymId[]) => true
  rule $needsDownArrayConv(X:SymId[_]) => true
  rule downArrayConv(X:SymId[]) => X
  rule downArrayConv(X:SymId[_]) => X

  // Remove a layer of indirection (from a normalized function type), i.e.,
  // extract the function result type.
  syntax Type ::= downFun(Type) [function]
  syntax Bool ::= "$needsDownFunConv" "(" K ")" 
    [function, klabel('$needsDownFunConv)]
  syntax Declarator ::= downFunConv(Declarator) [function]
  rule downFun(TS:TypeSpec D:Declarator) 
    => normType(TS #leftVisit(D, 'downFunConv, '$needsDownFunConv)::Declarator)
  rule $needsDownFunConv(X:SymId()) => true
  rule $needsDownFunConv(X:SymId(_)) => true
  rule downFunConv(X:SymId()) => X
  rule downFunConv(X:SymId(_)) => X

  // Extract the top-level identifier from the very heart of a (non-normalized)
  // declarator.
  syntax CId ::= getId(Declarator) [function]
  rule getId(X:CId) => X
  rule getId(P:Pointer D:DirectDecl) => getId(D)
  rule getId('`(_`)(D:Declarator)) => getId(D)
  rule getId(D:DirectDecl()) => getId(D)
  rule getId(D:DirectDecl[]) => getId(D)
  rule getId(D:DirectDecl(_)) => getId(D)
  rule getId(D:DirectDecl[_]) => getId(D)

  // Get the function parameters of the top-level identifier (not very useful
  // if the declarator has been normalized).
  syntax Params ::= getParams(Declarator) [function]
  syntax Params ::= "getParams'" "(" Declarator ")" [function]
  // Must normalize parens before this works.
  rule getParams(D:Declarator) => getParams'(normParens(D))

  rule getParams'(P:Pointer D:DirectDecl) => getParams'(D)
  rule getParams'('`(_`)(D:Declarator)) => getParams'(D)
  rule getParams'(X:CId()) => .Params
  rule getParams'(D:DirectDecl()) => getParams'(D)
    when isCId(D) =/=K true
  rule getParams'(D:DirectDecl[]) => getParams'(D)
  rule getParams'(X:CId(Ps:Params)) => Ps
  rule getParams'(D:DirectDecl(_)) => getParams'(D)
    when isCId(D) =/=K true
  rule getParams'(D:DirectDecl[_]) => getParams'(D)

  // The basic idea here is that a "type" will be nothing more than a
  // normalized declaration. We normalize declarations by:
  // 1. stripping storage class specifiers,
  // 2. turning abstract declarators into non-abstract declarators (noting 3)
  //    (an abstract declarator is one without an identifier)
  //    (except that we leave out the identifier if it would be undecorated),
  // 3. replacing all identifiers with a special symbolic identifier,
  // 4. and normalizing parens.
  // 
  // The resulting types are basically inside-out and a pain to work with, but
  // they at least maintain the conciseness of basic types (i.e., "unsigned
  // int" is in normal form -- but "int*" is not).
  // TODO(chathhorn): expand typedefs?
  syntax Type ::= normType(Type) [function]
  rule normType(T:Type) 
    => normParens(convDecls(stripStoClassSpec(normParens(T))))

  syntax Bool ::= "$needsStripping" "(" K ")" 
    [function, klabel('$needsStripping)]
  syntax Type ::= stripStoClassSpec(Type) [function]
  syntax K ::= "stripStoClassSpec'" "(" K ")" 
    [function, klabel('stripStoClassSpec')]
  // Ensures the parameter is a well-formed Type (necessary?).
  rule stripStoClassSpec(T:Type) => stripStoClassSpec'(T)
  rule $needsStripping(Lbl:KLabel(_:StorageClassSpec,, L:KList))
    => true
  rule stripStoClassSpec'(Lbl:KLabel(_:StorageClassSpec,, L:KList))
    => #visitAll(L, 'stripStoClassSpec', '$needsStripping)
  rule stripStoClassSpec'(Lbl:KLabel(K:K,, L:KList))
    => Lbl(K,, #visitAll(L, 'stripStoClassSpec', '$needsStripping))
    when isStorageClassSpec(K) =/=K true
  rule stripStoClassSpec'(Lbl:KLabel(.KList))
    => Lbl(.KList)

  // This is kinda subtle. Both abstract and non-abstract declarators might
  // also have children of both sorts and it's not very easy to distinguish the
  // two.
  syntax Type ::= convDecls(Type) [function]
  syntax ParamDecl ::= convParamDecl(ParamDecl) [function]
  syntax Declarator ::= convDecl(Declarator) [function]
  syntax DirectDecl ::= convDirectDecl(DirectDecl) [function]
  syntax Declarator ::= convAbsDecl(AbsDecl) [function]
  syntax DirectDecl ::= convDirectAbsDecl(DirectAbsDecl) [function]
  syntax Params ::= convParams(Params) [function]

  rule convDecls(T:ParamDecl) => convParamDecl(T)

  rule convParamDecl(TS:TypeSpec) => TS
  rule convParamDecl(TS:TypeSpec X:SymId) => TS
  rule convParamDecl(TS:TypeSpec X:CId) => TS
  rule convParamDecl(TS:TypeSpec D:Declarator) => TS convDecl(D)
    when (isCId(D) =/=K true) andBool (isSymId(D) =/=K true)
  rule convParamDecl(TS:TypeSpec D:AbsDecl) => TS convAbsDecl(D)

  rule convDecl(D:DirectDecl) => convDirectDecl(D)
  rule convDecl(P:Pointer D:DirectDecl) => P convDirectDecl(D)

  rule convDirectDecl(X:SymId) => X
  rule convDirectDecl(X:CId) => #__id__
  rule convDirectDecl('`(_`)(D:Declarator)) => '`(_`)(convDecl(D))
  rule convDirectDecl(D:DirectDecl()) => convDirectDecl(D)()
  rule convDirectDecl(D:DirectDecl[]) => convDirectDecl(D)[]
  rule convDirectDecl(D:DirectDecl(Ps:Params)) 
    => convDirectDecl(D)(convParams(Ps))
  rule convDirectDecl(D:DirectDecl[C:Constant]) => convDirectDecl(D)[C]

  rule convParams(P:ParamDecl, Ps:Params) => convParamDecl(P), Ps
  rule convParams(.Params) => .Params

  rule convAbsDecl(P:Pointer) => P #__id__
  rule convAbsDecl(D:DirectAbsDecl) 
    => convDirectAbsDecl(D)
  rule convAbsDecl(P:Pointer D:DirectAbsDecl) 
    => P convDirectAbsDecl(D)

  rule convDirectAbsDecl( () ) => #__id__()
  rule convDirectAbsDecl( [] ) => #__id__[]
  rule convDirectAbsDecl( '`(_`)(D:AbsDecl) ) => '`(_`)(convAbsDecl(D))
  rule convDirectAbsDecl( '`(_`)(Ps:Params) ) => #__id__(convParams(Ps))
  rule convDirectAbsDecl( [C:Constant] ) => #__id__[C]
  rule convDirectAbsDecl( D:DirectAbsDecl() ) => convDirectAbsDecl(D)()
  rule convDirectAbsDecl( D:DirectAbsDecl[] ) => convDirectAbsDecl(D)[]
  rule convDirectAbsDecl( D:DirectAbsDecl(Ps:Params) ) 
    => convDirectAbsDecl(D)(convParams(Ps))
  rule convDirectAbsDecl( D:DirectAbsDecl[C:Constant] ) 
    => convDirectAbsDecl(D)[C]

  // TODO(chathhorn): probably more to do here.
  syntax Bool ::= "$needsParensNorm" "(" K ")" [function]
  syntax K ::= normParens(K) [function]
  syntax KList ::= "normParens'" "(" KList ")" [function]

  rule $needsParensNorm('`(_`)('`(_`)(K:K))) => true
  rule $needsParensNorm('`(_`)(X:SymId)) => true
  rule $needsParensNorm('`(_`)(X:SymId[C:Constant])) => true

  rule normParens(Lbl:KLabel(K:K)) => normParens(K)
    when $needsParensNorm(Lbl(K)) ==K true
  rule normParens(Lbl:KLabel(L:KList)) => Lbl(normParens'(L))
    when $needsParensNorm(Lbl(L)) =/=K true

  rule normParens'(K:K,, L:KList) => normParens(K),, normParens'(L)
  rule normParens'(.KList) => .KList

endmodule

