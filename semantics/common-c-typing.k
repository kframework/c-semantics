require "common-c-semantics.k"

module COMMON-SEMANTICS-TYPE-INCLUDE
     // FIXME need to automatically pad structs
     imports COMMON-INCLUDE 
     
     syntax K ::= "MYHOLE"
     
     syntax K ::= "addStruct" "(" Id "," KList ")"
     syntax K ::= "addUnion" "(" Id "," KList ")"
     syntax K ::= "canonicalizeType" "(" Bag ")"
     
     // rules that use specifier should be careful to use extractActualType if
     // going to be used in a typed name
     syntax Type ::= extractActualType(Type) [function] 
     
     syntax K ::= "evalToType"

     syntax Set ::= "typeStrictLeftBinaryOperators" [function] // [memo] 
     rule typeStrictLeftBinaryOperators => 
          SetItem(l('_<<_))
          SetItem(l('_>>_))
          SetItem(l('_*=_))
          SetItem(l('_/=_))
          SetItem(l('_%=_))
          SetItem(l('_+=_))
          SetItem(l('_-=_))
          SetItem(l('_<<=_))
          SetItem(l('_>>=_))
          SetItem(l('_&=_))
          SetItem(l('_^=_))
          SetItem(l('_|=_))
          SetItem(l('_++))
          SetItem(l('_--))
          SetItem(l('--_))
          SetItem(l('++_))
          [structural]
endmodule

module COMMON-SEMANTICS-TYPE-DECLARATIONS
     imports COMMON-SEMANTICS-TYPE-INCLUDE 

     syntax K ::= "giveGlobalType" "(" K "," Type ")"
     syntax K ::= "giveLocalType" "(" K "," Type ")"
     
     // FIXME these are here until I decide how to handle qualified types
     rule [ignore-volatile]: t(S:Set, qualifiedType(t(S':Set, T:K), Volatile)) 
          => t(S:Set S':Set, T:K) 
          [structural, anywhere]
     rule [ignore-atomic]: t(S:Set, qualifiedType(t(S':Set, T:K), Atomic)) 
          => t(S:Set S':Set, T:K) 
          [structural, anywhere]
     rule [ignore-restrict]: t(S:Set, qualifiedType(t(S':Set, T:K), Restrict)) 
          => t(S:Set S':Set, T:K) 
          [structural, anywhere]
     rule [ignore-auto]: t(S:Set, qualifiedType(t(S':Set, T:K), Auto)) 
          => t(S:Set S':Set, T:K) 
          [structural, anywhere]
     rule [ignore-register]: t(S:Set, qualifiedType(t(S':Set, T:K), Register)) 
          => t(S:Set S':Set, T:K)
          [structural, anywhere]
     
     rule <k> giveType(X:Id, T:KResult) => 
               #if (Fun:Id ==K file-scope) 
               #then giveGlobalType(X:Id, unqualifyType(T:KResult)) 
               #else giveLocalType(X:Id, unqualifyType(T:KResult)) 
               #fi
          ...</k>
          <currentFunction> Fun:Id </currentFunction>
          [structural]
          
     rule <k> giveGlobalType(X:Id, T:KResult) => .K ...</k>
          <types> M:Map => M:Map[T:KResult / X:Id] </types>
          <gtypes>...
               Tu:K |-> map((M':Map => M':Map[T:KResult / X:Id]))
          ...</gtypes>
          <currTU> Tu:K </currTU>
          [structural]
     rule <k> giveLocalType(X:Id, T:KResult) => .K ...</k>
          <types> M:Map => M:Map[T:KResult / X:Id] </types>
          [structural]   
endmodule

module COMMON-SEMANTICS-TYPE-CANONICALIZATION
     imports COMMON-SEMANTICS-TYPE-INCLUDE 
     
     syntax K ::= "canonicalizeType-aux" "(" Bag "," K "," Bag "," Bag "," Bag ")"
     context canonicalizeType-aux(_,HOLE,_,_,_) when HOLE =/=K .K 

     rule canonicalizeType(B:Bag)
          => canonicalizeType-aux(B:Bag, .K, .Bag, .Bag, .Bag)
          [structural]

     rule (. => DeclType(K1:K, K2:K))
               ~> canonicalizeType-aux((_:Bag BagItem(TAtomic(K1:K, K2:K))),
               _, _, _, _) 
          [structural]
     rule (. => DeclType(K1:K, K2:K))
               ~> canonicalizeType-aux((_:Bag BagItem(AlignasType(K1:K, K2:K))),
               _, _, _, _) 
          [structural]
     rule (. => typeof(K1:K))
               ~> canonicalizeType-aux((_:Bag BagItem(AlignasExpression(K1:K))),
               _, _, _, _) 
          [structural]
          
     syntax K ::= "atomic" "(" Type ")"
     syntax K ::= "alignas" "(" Type ")"
     
     rule (T:KResult => .)
          ~> canonicalizeType-aux(
               (_:Bag (BagItem(TAtomic(_, _)) => .Bag)), _, 
               (_ (.Bag => BagItem(atomic(T:KResult)))), _, _) 
          when isTypeResult(T:KResult)
          [structural]
     rule (T:KResult => .)
          ~> canonicalizeType-aux(
               (_:Bag (BagItem(AlignasType(_, _)) => .Bag)), _, 
               (_ (.Bag => BagItem(alignas(T:KResult)))), _, _) 
          when isTypeResult(T:KResult)
          [structural]
     rule (T:KResult => .)
          ~> canonicalizeType-aux(
               (_:Bag (BagItem(AlignasExpression(_)) => .Bag)), _, 
               (_ (.Bag => BagItem(alignas(T:KResult)))), _, _) 
          when isTypeResult(T:KResult)
          [structural]
          
     // specifier, modifier, storage
     rule canonicalizeType-aux((_:Bag (BagItem(T:K) => .Bag)), _, 
               (_ (.Bag => BagItem(T:K))), _, _)
          when false
               orBool (T:K ==K Void)
               orBool (T:K ==K Bool)
               orBool (T:K ==K Char)
               orBool (T:K ==K Short)
               orBool (T:K ==K Int)
               orBool (T:K ==K Long)
               orBool (T:K ==K Float)
               orBool (T:K ==K Double)
               orBool (T:K ==K Signed)
               orBool (T:K ==K Unsigned)
               orBool (T:K ==K Complex)
               orBool (T:K ==K Imaginary)
               orBool (getKLabel(T:K) ==KLabel 'StructDef)
               orBool (getKLabel(T:K) ==KLabel 'UnionDef)
               orBool (getKLabel(T:K) ==KLabel 'EnumDef)
               orBool (getKLabel(T:K) ==KLabel 'StructRef)
               orBool (getKLabel(T:K) ==KLabel 'UnionRef)
               orBool (getKLabel(T:K) ==KLabel 'EnumRef)
               orBool (getKLabel(T:K) ==KLabel 'Named)
               orBool (getKLabel(T:K) ==KLabel 'Attribute)
          [structural]

     rule canonicalizeType-aux(_:Bag (BagItem(T:K) => .Bag), _, _, _, 
               (_ (.Bag => BagItem(T:K))))
          when (T:K ==K Extern)
               orBool (T:K ==K Static)
               orBool (T:K ==K Const)
               orBool (T:K ==K Volatile)
               orBool (T:K ==K Atomic)
               orBool (T:K ==K Restrict)
               orBool (T:K ==K Auto)
               orBool (T:K ==K Register)
               orBool (T:K ==K ThreadLocal)
          [structural]
          
     rule canonicalizeType-aux(.Bag, 
               (T:KResult => t(.Set, qualifiedType(T:KResult, Q:K))),
               .Bag, .Bag, (_ (BagItem(Q:K) => .Bag)))
          when (Q:K ==K Extern)
               orBool (Q:K ==K Static)
               orBool (Q:K ==K Volatile)
               orBool (Q:K ==K Atomic)
               orBool (Q:K ==K Restrict)
               orBool (Q:K ==K Auto)
               orBool (Q:K ==K Register)
               orBool (Q:K ==K ThreadLocal)
          [structural]
     rule canonicalizeType-aux(.Bag, (t((.Set => SetItem(Const)) _, _)),
               .Bag, .Bag, (_ (BagItem(Q:K) => .Bag)))
          when (Q:K ==K Const)
          [structural]
          
     /*@ \fromStandard{\source[n1570]{\para{6.7.3}{9}}}{
     If the specification of an array type includes any type qualifiers, the
     element type is so-qualified, not the array type. \ldots
     }*/
     rule t(SetItem(Const) S:Set, arrayType(t(S':Set, T:K), N:Int))
          => t(S:Set, arrayType(t(SetItem(Const) S':Set, T:K), N:Int))
          [structural, anywhere]
     
     rule <k> 
               canonicalizeSpecifier(BagItem(Named(X:Id)))
               => t(.Set, typedefType(X:Id, T:KResult))
          ...</k>
          <types>... typedef(X:Id) |-> T:KResult ...</types>
          when X:Id =/=K Identifier("")
          [structural]
          
     rule canonicalizeSpecifier(BagItem(StructRef(X:Id)))
          => t(.Set, structType(X:Id))
          when X:Id =/=K Identifier("")
          [structural]
     rule canonicalizeSpecifier(BagItem(EnumRef(X:Id)))
          => t(.Set, enumType(X:Id))
          when X:Id =/=K Identifier("")
          [structural]
     rule canonicalizeSpecifier(BagItem(UnionRef(X:Id)))
          => t(.Set, unionType(X:Id))
          when X:Id =/=K Identifier("")
          [structural]
          
     rule canonicalizeSpecifier(BagItem(EnumDef(X:Id, L:K)))
          => EnumDef(X:Id, L:K) ~> t(.Set, enumType(X:Id))
          when X:Id =/=K Identifier("")
          [structural]
     
     rule <k> 
               canonicalizeSpecifier(BagItem(
                    L:KLabel(((Identifier("") => unnamed(N:Int)),, _))))
          ...</k>
          <freshNat> N:Int => N:Int +Int 1 </freshNat>
          when L:KLabel ==KLabel 'StructDef
               orBool L:KLabel ==KLabel 'EnumDef
               orBool L:KLabel ==KLabel 'UnionDef
          [structural]
     
     rule canonicalizeSpecifier(BagItem(StructDef(X:Id, L:K)))
          => StructDef(X:Id, L:K) ~> t(.Set, structType(X:Id))
          when X:Id =/=K Identifier("")
          [structural]
     rule canonicalizeSpecifier(BagItem(UnionDef(X:Id, L:K)))
          => UnionDef(X:Id, L:K) ~> t(.Set, unionType(X:Id))
          when X:Id =/=K Identifier("")
          [structural]

     // FIXME what good is this_
     rule BagItem(SpecTypedef) => .Bag [structural, anywhere]
     // fixme ignoring inlines
     rule [ignore-inline]: BagItem(Inline) => .Bag [structural, anywhere]
     rule [ignore-noreturn]: BagItem(Noreturn) => .Bag [structural, anywhere]
     // fixme should save these for later use
     rule BagItem(Attribute(_:String, _)) => .Bag [structural, anywhere]

     rule canonicalizeType-aux(.Bag, (.K => canonicalizeSpecifier(B:Bag)),
               (B:Bag => .Bag), _, _)
          when B:Bag =/=Bag .Bag
          [structural]
          
     rule canonicalizeType-aux(.Bag, T:KResult, .Bag, .Bag, .Bag) => T:KResult
          [structural]
          
     syntax K ::= canonicalizeSpecifier(Bag) [function]
     // C99 6.7.2:2
     rule canonicalizeSpecifier(BagItem(Void)) => t(.Set, void)
     rule canonicalizeSpecifier(BagItem(Bool)) => t(.Set, bool)
     rule canonicalizeSpecifier(BagItem(Char)) => t(.Set, char)
     rule canonicalizeSpecifier(BagItem(Signed) BagItem(Char))
          => t(.Set, signed-char)
     rule canonicalizeSpecifier(BagItem(Unsigned) BagItem(Char))
          => t(.Set, unsigned-char)
     
     rule BagItem(atomic(_)) => .Bag [structural, anywhere]
     rule BagItem(alignas(_)) => .Bag [structural, anywhere]
     
     rule canonicalizeSpecifier(BagItem(Double))
          => t(.Set, double)
     rule canonicalizeSpecifier(BagItem(Float))
          => t(.Set, float)
     rule canonicalizeSpecifier(BagItem(Long) BagItem(Double))
          => t(.Set, long-double)

     rule canonicalizeSpecifier(BagItem(Complex) BagItem(Double))
          => t(SetItem(Complex), double)
     rule canonicalizeSpecifier(BagItem(Complex) BagItem(Float))
          => t(SetItem(Complex), float)
     rule canonicalizeSpecifier(BagItem(Complex) BagItem(Long) BagItem(Double))
          => t(SetItem(Complex), long-double)

     rule canonicalizeSpecifier(BagItem(Imaginary) BagItem(Double))
          => t(SetItem(Imaginary), double)
     rule canonicalizeSpecifier(BagItem(Imaginary) BagItem(Float))
          => t(SetItem(Imaginary), float)
     rule canonicalizeSpecifier(BagItem(Imaginary) BagItem(Long) BagItem(Double))
          => t(SetItem(Imaginary), long-double)

     rule canonicalizeSpecifier(B:Bag) => t(.Set, short-int)
          when (B:Bag ==Bag BagItem(Short))
               orBool (B:Bag ==Bag BagItem(Signed) BagItem(Short))
               orBool (B:Bag ==Bag BagItem(Short) BagItem(Int))
               orBool (B:Bag ==Bag BagItem(Signed) BagItem(Short) BagItem(Int))
          [structural]
     rule canonicalizeSpecifier(B:Bag) => t(.Set, unsigned-short-int)
          when (B:Bag ==Bag BagItem(Unsigned) BagItem(Short))
               orBool (B:Bag ==Bag BagItem(Unsigned) BagItem(Short) BagItem(Int))
          [structural]
     rule canonicalizeSpecifier(B:Bag) => t(.Set, int)
          when (B:Bag ==Bag BagItem(Int))
               orBool (B:Bag ==Bag BagItem(Signed))
               orBool (B:Bag ==Bag BagItem(Signed) BagItem(Int))
          [structural]
     rule canonicalizeSpecifier(B:Bag) => t(.Set, unsigned-int)
          when (B:Bag ==Bag BagItem(Unsigned))
               orBool (B:Bag ==Bag BagItem(Unsigned) BagItem(Int))
          [structural]
     rule canonicalizeSpecifier(B:Bag) => t(.Set, long-int)
          when (B:Bag ==Bag BagItem(Long))
               orBool (B:Bag ==Bag BagItem(Signed) BagItem(Long))
               orBool (B:Bag ==Bag BagItem(Long) BagItem(Int))
               orBool (B:Bag ==Bag BagItem(Signed) BagItem(Long) BagItem(Int))
          [structural]
     rule canonicalizeSpecifier(B:Bag) => t(.Set, unsigned-long-int)
          when (B:Bag ==Bag BagItem(Unsigned) BagItem(Long))
               orBool (B:Bag ==Bag BagItem(Unsigned) BagItem(Long) BagItem(Int))
          [structural]
     rule canonicalizeSpecifier(B:Bag) => t(.Set, long-long-int)
          when (B:Bag ==Bag BagItem(Long) BagItem(Long))
               orBool (B:Bag ==Bag BagItem(Signed) BagItem(Long) BagItem(Long))
               orBool (B:Bag ==Bag BagItem(Long) BagItem(Long) BagItem(Int))
               orBool (B:Bag ==Bag
                    BagItem(Signed) BagItem(Long) BagItem(Long) BagItem(Int))
          [structural]
     rule canonicalizeSpecifier(B:Bag) => t(.Set, unsigned-long-long-int)
          when (B:Bag ==Bag BagItem(Unsigned) BagItem(Long) BagItem(Long))
               orBool (B:Bag ==Bag
                    BagItem(Unsigned) BagItem(Long) BagItem(Long) BagItem(Int))
          [structural]
endmodule

module COMMON-SEMANTICS-TYPE-INTERPRETATION
     imports COMMON-SEMANTICS-TYPE-INCLUDE 

     syntax K ::= "BitFieldType" "(" K "," K ")" [strict] 
     
     rule Specifier(klist(L:KList)) => canonicalizeType(toBag(L))
          [structural]
          
     rule BitFieldType(T:KResult, tv(N:Int, _))
          => t(.Set, bitfieldType(T:KResult, N:Int)) [structural, anywhere]
     
     syntax KLabel ::= "makeArrayType" "(" Int ")"
     syntax KLabel ::= "makeFunctionType" "(" KList ")"
     syntax Type ::= pushTypeDown(Type, KLabel) [function]
     syntax KLabel ::= "makePointerType"
     syntax KLabel ::= "makeIncompleteArrayType"
     
     // fixme, throwing away specifier
     rule ArrayType(T:KResult, tv(N:Int, _), _) 
          => pushTypeDown(T:KResult, makeArrayType(N:Int)) 
          when N:Int >Int 0
          [structural, anywhere]
     rule ArrayType(T:KResult, emptyValue, _)
          => pushTypeDown(T:KResult, makeIncompleteArrayType)
          [structural, anywhere]
     rule PointerType(T:KResult)
          => pushTypeDown(T:KResult, makePointerType)
          [structural, anywhere]
     // fixme I'm assuming functiontype is always below a prototype in the ast
     rule FunctionType(T:KResult) => T:KResult
          [structural, anywhere]
     rule Prototype(T:KResult, krlist(L:KList), false) 
          => pushTypeDown(T:KResult, makeFunctionType(L:KList)) 
          [structural, anywhere]
     rule Prototype(T:KResult, krlist(L:KList), true) 
          => pushTypeDown(T:KResult,
               makeFunctionType((L:KList,, t(.Set, variadic)))) 
          [structural, anywhere]
     
     rule [pushdown-array]: 
          pushTypeDown(t(S:Set, arrayType(T:KResult, N:Int)), K:KLabel) 
          => t(S:Set, arrayType(pushTypeDown(T:KResult, K:KLabel), N:Int))
     rule [pushdown-incomplete]: 
          pushTypeDown(t(S:Set, incompleteArrayType(T:KResult)), K:KLabel) 
          => t(S:Set, incompleteArrayType(pushTypeDown(T:KResult, K:KLabel)))
     rule [pushdown-pointer]: 
          pushTypeDown(t(S:Set, pointerType(T:KResult)), K:KLabel) 
          => t(S:Set, pointerType(pushTypeDown(T:KResult, K:KLabel)))
     rule [pushdown-qualified]: 
          pushTypeDown(t(S:Set, qualifiedType(T:KResult, K:K)), Kl:KLabel) 
          => t(S:Set, qualifiedType(pushTypeDown(T:KResult, Kl:KLabel), K:K))
     rule [pushdown-function]: 
          pushTypeDown(t(S:Set, functionType(T:KResult, L:KList)), K:KLabel) 
          => t(S:Set, functionType(pushTypeDown(T:KResult, K:KLabel), L:KList))
     rule [pushdown-struct]: 
          pushTypeDown(t(S:Set, structType(X:Id)), K:KLabel) 
          => K:KLabel(t(S:Set, structType(X:Id)))
     rule [pushdown-union]: 
          pushTypeDown(t(S:Set, unionType(X:Id)), K:KLabel) 
          => K:KLabel(t(S:Set, unionType(X:Id)))
     rule [pushdown-enum]: 
          pushTypeDown(t(S:Set, enumType(X:Id)), K:KLabel) 
          => K:KLabel(t(S:Set, enumType(X:Id)))
     
     rule [pushdown-typedef]: 
          pushTypeDown(t(S:Set, typedefType(_:Id, t(S':Set, T:K))), K:KLabel) 
          => K:KLabel(t(S:Set S':Set, T:K))
     
     rule [pushdown-basic]: 
          pushTypeDown(T:KResult, K:KLabel) => K:KLabel(T:KResult) 
          when isBasicType(T:KResult)
          [structural]
     
     rule makeArrayType(N:Int)(T:KResult)
          => t(.Set, arrayType(T:KResult, N:Int)) 
          [structural, anywhere]
     rule makeFunctionType(L:KList)(T:KResult)
          => t(.Set, functionType(T:KResult, giveNamesToArgs(L:KList))) 
          [structural, anywhere]
     rule makePointerType(T:KResult)
          => t(.Set, pointerType(T:KResult))
          [structural, anywhere]
     rule makeIncompleteArrayType(T:KResult)
          => t(.Set, incompleteArrayType(T:KResult))
          [structural, anywhere]
     
     syntax KList ::= giveNamesToArgs(KList) [function]
     syntax KList ::= "giveNamesToArgs-aux" "(" Int "," KList ")" [function]
     
     rule giveNamesToArgs(L:KList) => giveNamesToArgs-aux(0, L:KList)
     rule giveNamesToArgs-aux(N:Int, 
               (typedDeclaration(T:KResult, X:Id),, L:KList))
          => typedDeclaration(T:KResult, X:Id),,
               giveNamesToArgs-aux(N:Int, L:KList)
          when X:Id =/=K #NoName
          [structural]
     rule giveNamesToArgs-aux(N:Int, 
               (typedDeclaration(T:KResult, X:Id),, L:KList))
          => typedDeclaration(T:KResult, #NoName(N:Int)),,
               giveNamesToArgs-aux(N:Int +Int 1, L:KList)
          when X:Id ==K #NoName
          [structural]
     rule giveNamesToArgs-aux(_:Int, t(.Set, variadic))
          => t(.Set, variadic)
          [structural]
     rule giveNamesToArgs-aux(_:Int, .KList)
          => .KList
          [structural]
     
     rule <k> JustBase => T:KResult ...</k>
          <declarationTypeHolder> T:KResult => .K ...</declarationTypeHolder>
          [structural]

     syntax K ::= "extractActualTypeFreezer"
     rule <k>
               DeclType(T:KResult, K:K) => K:K ~> extractActualTypeFreezer
          ...</k>
          <declarationTypeHolder> (. => T:KResult) ...</declarationTypeHolder>
          [structural]
     
     rule T:KResult ~> extractActualTypeFreezer 
          => extractActualType(T)
          [structural]
          
     syntax KList ::= fillUnionBitHoles(KList) [function]
     syntax KList ::= "fillUnionBitHoles-aux" "(" Int "," KList ")" [function]
     rule fillUnionBitHoles(.KList) => .KList
     rule fillUnionBitHoles((K:K,, L:KList)) 
          => fillUnionBitHoles-aux(0, (K:K,, L:KList))
     rule fillUnionBitHoles-aux(N:Int, 
               (typedDeclaration(T:KResult, X:Id),, L:KList)) 
          => typedDeclaration(T:KResult, X:Id),, 
               fillUnionBitHoles-aux(N:Int, L:KList)
          when notBool isBitfieldType(T:KResult)
          [structural]
     rule fillUnionBitHoles-aux(N:Int, (typedDeclaration(t(S:Set, 
               bitfieldType(T:KResult, N':Int)), X:Id),, L:KList)) 
          => typedDeclaration(t(S:Set, bitfieldType(T:KResult, N':Int)), X:Id),, 
               fillUnionBitHoles-aux(maxInt(N:Int, N':Int), L:KList)
          [structural]
     rule fillUnionBitHoles-aux(N:Int, .KList) 
          => typedDeclaration(t(.Set, bitfieldType(t(.Set, unsigned-int), 
               N:Int +Int (absInt(numBitsPerByte -Int 
               (N:Int %Int numBitsPerByte)) %Int numBitsPerByte))), #NoName)
          [structural]
     
     syntax KList ::= fillBitHoles(KList) [function]
     syntax KList ::=  "fillBitHoles-aux" "(" Int "," KList ")" [function]
     rule [fillBitHoles-none]:
          fillBitHoles(.KList) => .KList 
          [structural]
     // if we haven't seen bitfields
     rule [fillBitHoles-not-bitfield]:
          fillBitHoles((typedDeclaration(T:KResult, X:Id),, L:KList)) 
          => typedDeclaration(T:KResult, X:Id) ,, fillBitHoles(L:KList)
          when notBool isBitfieldType(T:KResult) 
          [structural]
     
     rule [fillBitHoles-bitfield]:
          fillBitHoles((typedDeclaration(T:KResult, X:Id),, L:KList)) 
          => fillBitHoles-aux(0, (typedDeclaration(T:KResult, X:Id),, L:KList))
          when isBitfieldType(T:KResult) 
          [structural]
     
     // if we have seen bitfields
     rule [fillBitHoles-aux-not-bitfield]:
          fillBitHoles-aux(N:Int, (typedDeclaration(T:KResult, X:Id),, L:KList)) 
          => typedDeclaration(t(.Set, bitfieldType(t(.Set, unsigned-int), 
               absInt(numBitsPerByte -Int (N:Int %Int numBitsPerByte)) 
               %Int numBitsPerByte)), #NoName),,
               fillBitHoles((typedDeclaration(T:KResult, X:Id),, L:KList))
          when notBool isBitfieldType(T:KResult) 
          [structural]
     
     rule [fillBitHoles-aux-bitfield-normal]:
          fillBitHoles-aux(N:Int, (typedDeclaration(t(S:Set, 
               bitfieldType(T:KResult, N':Int)), X:Id),, L:KList)) 
          => typedDeclaration(t(S:Set, bitfieldType(T:KResult, N':Int)), X:Id),, 
               fillBitHoles-aux(N:Int +Int N':Int, L:KList)
          when N':Int =/=Int 0 
          [structural]
          
     rule [fillBitHoles-bitfield-zero]:
          fillBitHoles-aux(N:Int, (typedDeclaration(t(_, 
               bitfieldType(_:KResult, N':Int)), _:Id),, L:KList)) 
          => typedDeclaration(t(.Set, bitfieldType(t(.Set, unsigned-int), 
               absInt(numBitsPerByte -Int (N:Int %Int numBitsPerByte)) 
               %Int numBitsPerByte)), #NoName),, 
               fillBitHoles(L:KList)
          when N':Int ==Int 0
          [structural]
     
     rule [fillBitHoles-done]:
          fillBitHoles-aux(N:Int, .KList) 
          => typedDeclaration(t(.Set, bitfieldType(t(.Set, unsigned-int), 
               absInt(numBitsPerByte -Int (N:Int %Int numBitsPerByte))
               %Int numBitsPerByte)), #NoName) 
          [structural]
     
     rule typedDeclaration(t(_, bitfieldType(_, N:Int)), #NoName),,
               typedDeclaration(t(_, bitfieldType(_, N':Int)), #NoName) 
          => typedDeclaration(t(.Set, bitfieldType(t(.Set, unsigned-int),
               N:Int +Int N':Int)), #NoName) 
          [structural, anywhere]
     
     // fixme chould check for some struct contraints here
     syntax KList ::= incompleteToFlexibleArrayMember(KList) [function]

     rule incompleteToFlexibleArrayMember((typedDeclaration(T:KResult, X:Id),, 
               L:KList))
          => typedDeclaration(T:KResult, X:Id),, 
               incompleteToFlexibleArrayMember(L:KList)
          when notBool isIncompleteType(T:KResult) 
          [structural]
     rule incompleteToFlexibleArrayMember(typedDeclaration(t(S:Set,
               incompleteArrayType(T:KResult)), X:Id)) 
          => typedDeclaration(t(S:Set, flexibleArrayType(T:KResult)), X:Id) 
          [structural]
     rule incompleteToFlexibleArrayMember(.KList) => .KList
     
     rule StructDef(X:Id, krlist(L:KList))
          => addStruct(X:Id, fillBitHoles(incompleteToFlexibleArrayMember(L)))
               ~> giveType(X:Id, t(.Set, structType(X:Id)))
          [structural]
     rule UnionDef(X:Id, krlist(L:KList))
          => addUnion(X:Id, fillUnionBitHoles(L))
               ~> giveType(X:Id, t(.Set, unionType(X:Id)))
          [structural]

     // the K will resolve to a type, so throw it away
     rule OnlyTypedef(K:K) => K ~> discard
          [structural]
          
     rule NameAndType(X:Id, T:KResult) => typedDeclaration(T, X)
          [structural, anywhere] 
     
     rule [extract-basic]: 
          extractActualType(T:KResult) => T
          when isBasicType(T)
     rule [extract-enum]: 
          extractActualType(t(S:Set, enumType(X:Id))) 
          => t(S, enumType(X))
     rule [extract-struct]:
          extractActualType(t(S:Set, structType(X:Id))) 
          => t(S, structType(X))
     rule [extract-union]:
          extractActualType(t(S:Set, unionType(X:Id))) 
          => t(S, unionType(X))
     rule [extract-array]:
          extractActualType(t(S:Set, arrayType(T:KResult, N:Int))) 
          => t(S, arrayType(extractActualType(T), N))
     rule [extract-incompleteArray]:
          extractActualType(t(S:Set, incompleteArrayType(T:KResult))) 
          => t(S, incompleteArrayType(extractActualType(T)))
     rule [extract-bitfield]:
          extractActualType(t(S:Set, bitfieldType(T:KResult, N:Int))) 
          => t(S, bitfieldType(extractActualType(T), N))
     rule [extract-function]:
          extractActualType(t(S:Set, functionType(T:KResult, List:KList))) 
          => t(S, functionType(extractActualType(T), List))
     rule [extract-pointer]:
          extractActualType(t(S:Set, pointerType(T:KResult))) 
          => t(S, pointerType(extractActualType(T)))
     rule [extract-qualified]:
          extractActualType(t(S:Set, qualifiedType(T:KResult, K:K))) 
          => t(S, qualifiedType(extractActualType(T), K))
     rule [extract-typedef]:
          extractActualType(t(S:Set, typedefType(_:Id, t(S':Set, T:K)))) 
          => extractActualType(t(S S', T))
          
     syntax K ::= "NameAndType" "(" K "," K ")" [strict(2)] 
          
     rule SingleName(T:KResult, Name(X:Id, K:K)) 
          => NameAndType(X:Id, DeclType(T:KResult, K:K))
          [structural, anywhere] 
     rule [Separate-FieldGroups]:
          FieldGroup(K:K, klist((C:K,, C':K,, L:KList))) 
          => FieldGroup(K:K, klist(C:K)),, 
               FieldGroup(K:K, klist((C':K,, L:KList)))
          [structural, anywhere]

     rule FieldGroup(T:KResult, klist(Name(X:Id, K:K))) 
          => NameAndType(X:Id, DeclType(T:KResult, K:K))
          [structural, anywhere]
          
     rule FieldGroup(T:KResult, klist(BitFieldName(Name(X:Id, K:K), Size:K)))
          => NameAndType(X:Id, DeclType(T:KResult, BitFieldType(K:K, Size:K)))
          [structural, anywhere] 
     rule FieldName(K:K) => K [structural, anywhere]
endmodule

module COMMON-SEMANTICS-TYPE-MISC
     imports COMMON-SEMANTICS-TYPE-INCLUDE
     
     /*@ \fromStandard{\source[n1570]{\para{6.2.7}{1}}}{
     Two types have compatible type if their types are the same. Additional
     rules for determining whether two types are compatible are described in
     6.7.2 for type specifiers, in 6.7.3 for type qualifiers, and in 6.7.6 for
     declarators.  Moreover, two structure, union, or enumerated types declared
     in separate translation units are compatible if their tags and members
     satisfy the following requirements: If one is declared with a tag, the
     other shall be declared with the same tag. If both are completed anywhere
     within their respective translation units, then the following additional
     requirements apply: there shall be a one-to-one correspondence between
     their members such that each pair of corresponding members are declared
     with compatible types; if one member of the pair is declared with an
     alignment specifier, the other is declared with an equivalent alignment
     specifier; and if one member of the pair is declared with a name, the
     other is declared with the same name. For two structures, corresponding
     members shall be declared in the same order. For two structures or unions,
     corresponding bit-fields shall have the same widths. For two enumerations,
     corresponding members shall have the same values.
     
     \source[n1570]{\para{6.7.3}{10}}
     For two qualified types to be compatible, both shall have the identically
     qualified version of a compatible type; the order of type qualifiers
     within a list of specifiers or qualifiers does not affect the specified
     type.
     }*/
     
     rule [typeCompatible-identical]:
          isTypeCompatible(T:KResult, T:KResult) => true 
          [structural]
     rule [typeCompatible-two-ints]:
          isTypeCompatible(T:KResult, T':KResult) => true 
          when hasIntegerType(T:KResult)
               andBool hasIntegerType(T':KResult) 
          [structural]
     rule [typeCompatible-two-ptr]:
          isTypeCompatible(t(_, pointerType(_)), t(_, pointerType(_))) => true 
          [structural]
     rule [typeCompatible-ptr-int]:
          isTypeCompatible(t(_, pointerType(_)), T:KResult) => true
          when hasIntegerType(T:KResult) 
          [structural]
     rule [typeCompatible-int-ptr]:
          isTypeCompatible(T:KResult, t(_, pointerType(_))) => true
          when hasIntegerType(T:KResult)
          [structural]
          
     rule [typeCompatible-declarations]:
          isTypeCompatible(typedDeclaration(T:KResult, _:Id), 
               typedDeclaration(T':KResult, _:Id))
          => isTypeCompatible(T:KResult, T':KResult) 
          [structural]
     rule [typeCompatible-prototypes]:
          isTypeCompatible(t(_, prototype(T:KResult)), t(_, prototype(T':KResult))) 
          => isTypeCompatible(T:KResult, T':KResult) 
          [structural]

     rule [typeCompatible-array-right]:
          isTypeCompatible(T:KResult, t(S:Set, arrayType(T':KResult, _:Int)))
          => isTypeCompatible(T:KResult, t(S:Set, pointerType(T':KResult))) 
          [structural]
     rule [typeCompatible-array-left]:
          isTypeCompatible(t(S:Set, arrayType(T:KResult, _:Int)), T':KResult)
          => isTypeCompatible(t(S:Set, pointerType(T:KResult)), T':KResult) 
          [structural]
     
     rule [typeCompatible-incompleteArray-right]:
          isTypeCompatible(T:KResult, t(S:Set, incompleteArrayType(T':KResult)))
          => isTypeCompatible(T:KResult, t(S:Set, pointerType(T':KResult))) 
          [structural]
     rule [typeCompatible-incompleteArray-left]:
          isTypeCompatible(t(S:Set, incompleteArrayType(T:KResult)), T':KResult)
          => isTypeCompatible(t(S:Set, pointerType(T:KResult)), T':KResult) 
          [structural]

     rule [typeCompatible-function-void-left]:
          isTypeCompatible(t(_, functionType(T1:KResult, 
               typedDeclaration(t(_, void), _:Id))),
               t(_, functionType(T2:KResult, .KList)))
          => isTypeCompatible(T1:KResult, T2:KResult) 
          [structural]
     rule [typeCompatible-function-void-right]:
          isTypeCompatible(t(_, functionType(T1:KResult, .KList)),
               t(_, functionType(T2:KResult, 
               typedDeclaration(t(_, void), _:Id))))
          => isTypeCompatible(T1:KResult, T2:KResult) 
          [structural]
     rule [typeCompatible-function]:
          isTypeCompatible(t(S:Set, functionType(T1:KResult, 
               (T':KResult,, L:KList))),
               t(S':Set, functionType(T2:KResult, (T'':KResult,, L':KList))))
          => isTypeCompatible(t(S:Set, functionType(T1:KResult, L:KList)),
               t(S':Set, functionType(T2:KResult, L':KList)))
               andBool isTypeCompatible(T':KResult, T'':KResult) 
          [structural]
     rule [typeCompatible-incompleteArray-nil]:
          isTypeCompatible(t(_, functionType(T1:KResult, .KList)),
               t(_, functionType(T2:KResult, .KList)))
          => isTypeCompatible(T1:KResult, T2:KResult) 
          [structural]
     rule isTypeCompatible(T:KResult, T':KResult) => true
          when (hasIntegerType(T:KResult) orBool isFloatType(T:KResult))
               andBool (hasIntegerType(T':KResult) orBool isFloatType(T':KResult)) 
          [structural]
               
     syntax K ::= "addGlobalAggregate" "(" Id "," K ")"
     syntax K ::= "addLocalAggregate" "(" Id "," K ")"
     
     syntax K ::= "addStruct-aux" "(" Id "," KList "," K "," Map "," Map "," KList ")"
          [strict(3)]
     syntax K ::= "addUnion-aux" "(" Id "," KList "," Map "," Map "," KList ")"

     // TODO(chathhorn): why the hell was this necessary? this has got to be a
     // BUG.
     rule addStruct-aux(A:Id, B:KList, K:K, C:Map, D:Map, E:KList) 
          => K ~> addStruct-aux(A, B, HOLE, C, D, E) [heat]
     rule K:KResult ~> addStruct-aux(A:Id, B:KList, HOLE, C:Map, D:Map, E:KList)
          => addStruct-aux(A, B, K, C, D, E) [cool]

     rule addStruct(S:Id, L:KList) 
          => addStruct-aux(S:Id, L:KList,
               tv(0, cfg:largestUnsigned), .Map, .Map, L:KList)
          when L:KList =/=KList .KList
          [structural]
     rule addStruct-aux(
               S:Id
               , (typedDeclaration(T:KResult, Field:Id),, L:KList)
               , V:KResult
               , Types:Map
               , Offsets:Map
               , L':KList
          ) 
          => addStruct-aux(S, L, V + bitSizeofType(T:KResult),
               Types:Map[T / Field], Offsets:Map[value(V) / Field], L')
          [structural]
     rule <k> 
               addStruct-aux(S:Id, .KList, _, Types:Map, Offsets:Map, L:KList) 
               => #if (F:Id ==K file-scope) 
                    #then (addGlobalAggregate(S:Id, 
                         aggregateInfo(L:KList, Types:Map, Offsets:Map))) 
                    #else (addLocalAggregate(S:Id, 
                         aggregateInfo(L:KList, Types:Map, Offsets:Map)))
                    #fi
          ...</k>
          <currentFunction> F:Id </currentFunction>
          [structural]        
          
     rule addUnion(S:Id, L:KList) 
          => addUnion-aux(S:Id, L:KList, .Map, .Map, L:KList)
          when L:KList =/=KList .KList
          [structural]
     rule addUnion-aux(
               S:Id
               , (typedDeclaration(T:KResult, Field:Id),, L:KList)
               , Types:Map
               , Offsets:Map
               , L':KList
          ) 
          => addUnion-aux(S:Id, L,
               Types:Map[T:KResult / Field:Id], Offsets:Map[0 / Field:Id],
               L':KList)
          [structural]
     rule <k> 
               addUnion-aux(S:Id, .KList, Types:Map, Offsets:Map, L:KList) 
               => #if (F:Id ==K file-scope)
                    #then (addGlobalAggregate(S:Id,
                         aggregateInfo(L, Types:Map, Offsets:Map))) 
                    #else (addLocalAggregate(S:Id,
                         aggregateInfo(L, Types:Map, Offsets:Map)))
                    #fi
          ...</k>
          <currentFunction> F:Id </currentFunction>
          [structural]

     rule <k> addGlobalAggregate(X:Id, K:K) => . ...</k>
          <structs> M':Map => M':Map[K:K / X:Id] </structs>
          <gstructs> M:Map => M:Map[K:K / X:Id] </gstructs>
          [structural]
     rule <k> addLocalAggregate(X:Id, K:K) => . ...</k>
          <structs> M:Map => M:Map[K:K / X:Id] </structs>
          [structural]
          
     rule isTypeResult(t(_, T:K)) => true
          when l(getKLabel(T:K)) in setOfTypes
     rule isTypeResult(T:KResult) => true 
          when isBasicType(T:KResult)
     rule isTypeResult(K:K) => false
          when getKLabel(K:K) =/=KLabel 't
     rule isTypeResult(t(S:Set, T:K)) => false
          when (notBool l(getKLabel(T:K)) in setOfTypes)
               andBool (notBool isBasicType(t(S:Set, T:K)))

     rule isFloatType(t(_, float)) => true 
     rule isFloatType(t(_, double)) => true 
     rule isFloatType(t(_, long-double)) => true 
     rule isFloatType(t(_, T:K)) => false
          when (T:K =/=K float)
               andBool (T:K =/=K double)
               andBool (T:K =/=K long-double)
               andBool (getKLabel(T:K) =/=KLabel 'qualifiedType)
          
     rule [isCharType-char]: isCharType(t(_, char)) => true 
     rule [isCharType-qualified]:
          isCharType(t(_, qualifiedType(T:KResult, _)))
          => isCharType(T:KResult) 
     rule [isCharType-unsigned-char]: isCharType(t(_, unsigned-char)) => true 
     rule [isCharType-signed-char]: isCharType(t(_, signed-char)) => true 
     rule [isCharType-other]: isCharType(t(_, T:K)) => false
          when (T:K =/=K char)
               andBool (T:K =/=K unsigned-char)
               andBool (T:K =/=K signed-char)
               andBool (getKLabel(T:K) =/=KLabel 'qualifiedType)
          
     rule [isWCharType-wchar]: isWCharType(t(_, T:K)) => true 
          when T:K ==K simpleType(cfg:wcharut)
          
     rule [isWCharType-other]: isWCharType(t(_, T:K)) => false
          when (T:K =/=K simpleType(cfg:wcharut))
               andBool (getKLabel(T:K) =/=KLabel 'qualifiedType )
          
     rule [isWCharType-qualified]:
          isWCharType(t(_, qualifiedType(T:KResult, _)))
          => isWCharType(T:KResult) 
     
     rule [isPointerType-pointer]: isPointerType(t(_, pointerType(_))) => true 
     rule [isPointerType-qualified]:
          isPointerType(t(_, qualifiedType(T:KResult, _)))
          => isPointerType(T:KResult) 
     rule [isPointerType-other]: isPointerType(t(_, T:K)) => false
          when (getKLabel(T:K) =/=KLabel 'pointerType)
               andBool (getKLabel(T:K) =/=KLabel 'qualifiedType)
          
     
     rule [isBoolType-bool]: isBoolType(t(_, bool)) => true 
     rule [isBoolType-qualifiedType]:
          isBoolType(t(_, qualifiedType(T:KResult, _)))
          => isBoolType(T:KResult) 
     rule [isBoolType-other]: isBoolType(t(_, T:K)) => false
          when (T:K =/=K bool)
               andBool (getKLabel(T:K) =/=KLabel 'qualifiedType)
          
     rule [isArrayType-array]: isArrayType(t(_, arrayType(_, _:Int))) => true 
     rule [isArrayType-incompleteArray]:
          isArrayType(t(_, incompleteArrayType(_)))
          => true 
     rule [isArrayType-flexibleArray]:
          isArrayType(t(_, flexibleArrayType(_)))
          => true 
     rule [isArrayType-qualified]:
          isArrayType(t(_, qualifiedType(T:KResult, _)))
          => isArrayType(T:KResult) 
     rule [isArrayType-other]: isArrayType(t(_, T:K)) => false
          when (getKLabel(T:K) =/=KLabel 'arrayType)
               andBool (getKLabel(T:K) =/=KLabel 'incompleteArrayType)
               andBool (getKLabel(T:K) =/=KLabel 'flexibleArrayType)
               andBool (getKLabel(T:K) =/=KLabel 'qualifiedType)
          
     rule isAggregateType(T:KResult)
          => isArrayType(T:KResult) orBool isStructType(T:KResult) 
          
     rule [isStructType-struct]:
          isStructType(t(_, structType(_:Id))) => true 
     rule [isStructType-qualified]:
          isStructType(t(_, qualifiedType(T:KResult, _)))
          => isStructType(T:KResult) 
     rule [isStructType-other]: isStructType(t(_, T:K)) => false
          when (getKLabel(T:K) =/=KLabel 'structType)
               andBool (getKLabel(T:K) =/=KLabel 'qualifiedType )
          
     rule [isUnionType-union]: isUnionType(t(_, unionType(_:Id))) => true 
     rule [isUnionType-qualified]:
          isUnionType(t(_, qualifiedType(T:KResult, _)))
          => isUnionType(T:KResult) 
     rule [isUnionType-other]: isUnionType(t(_, T:K)) => false
          when (getKLabel(T:K) =/=KLabel 'unionType)
               andBool (getKLabel(T:K) =/=KLabel 'qualifiedType )

     rule [isIncompleteType-true]:
          isIncompleteType(t(_, incompleteArrayType(_)))
          => true 
     rule [isIncompleteType-qualified]:
          isIncompleteType(t(_, qualifiedType(T:KResult, _)))
          => isIncompleteType(T:KResult) 
     rule [isIncompleteType-false]: isIncompleteType(t(_, T:K)) => false
          when (getKLabel(T:K) =/=KLabel 'incompleteArrayType)
               andBool (getKLabel(T:K) =/=KLabel 'qualifiedType )
          
     rule [isExternType-qualified]: 
          isExternType(t(_, qualifiedType(T:KResult, K:K))) 
          => #if (K:K ==K Extern) #then (true) #else (isExternType(T:KResult)) #fi 
          
     rule [isExternType-false]: isExternType(t(_, T:K)) => false
          when getKLabel(T:K) =/=KLabel 'qualifiedType 
          
     rule [isStaticType-qualified]: 
          isStaticType(t(_, qualifiedType(T:KResult, K:K))) 
          => #if (K:K ==K Static) #then (true) #else (isStaticType(T:KResult)) #fi
          
     rule [isStaticType-false]: isStaticType(t(_, T:K)) => false
          when getKLabel(T:K) =/=KLabel 'qualifiedType 
          
     rule [isConstType-qualified]: 
          isConstType(t(_, qualifiedType(T:KResult, _:K)))
          => isConstType(T:KResult)
          
     rule [isConstType-false]: 
          isConstType(t(S:Set, T:K)) => false
          when (getKLabel(T:K) =/=KLabel 'qualifiedType )
               andBool (notBool Const in S:Set)
          
     rule [isConstType-true]: 
          isConstType(t(SetItem(Const) _, _:K)) => true
          
     rule [isBitfieldType-true]:
          isBitfieldType(t(_, bitfieldType(_, _:Int)))
          => true 
     rule [isBitfieldType-false]: isBitfieldType(t(_, T:K)) => false
          when getKLabel(T:K) =/=KLabel 'bitfieldType
          
     rule [isFunctionType-true]:
          isFunctionType(t(_, functionType(_, _:KList)))
          => true 
     rule [isFunctionType-prototype]:
          isFunctionType(t(_, prototype(T:KResult)))
          => isFunctionType(T:KResult) 
     rule [isFunctionType-qualified]:
          isFunctionType(t(_, qualifiedType(T:KResult, _)))
          => isFunctionType(T:KResult) 
     rule [isFunctionType-false]: isFunctionType(t(_, T:K)) => false
          when (getKLabel(T:K) =/=KLabel 'functionType)
               andBool (getKLabel(T:K) =/=KLabel 'qualifiedType)
               andBool (getKLabel(T:K) =/=KLabel 'prototype)
          
     rule [isFunctionPointerType-fp]:
          isFunctionPointerType(t(_, pointerType(t(_,
               functionType(_, _:KList)))))
          => true 
     rule [isFunctionPointerType-qualified]:
          isFunctionPointerType(t(_, qualifiedType(T:KResult, _)))
          => isFunctionPointerType(T:KResult) 
     rule [isFunctionPointerType-qualified-pointer]: 
          isFunctionPointerType(t(_, pointerType(t(_,
               qualifiedType(T:KResult, _))))) 
          => isFunctionPointerType(t(.Set, pointerType(T))) 
     rule [isFunctionPointerType-notPointer]:
          isFunctionPointerType(t(_, T:K))
          => false
          when (getKLabel(T:K) =/=KLabel 'pointerType)
               andBool (getKLabel(T:K) =/=KLabel 'qualifiedType)
          
     rule [isFunctionPointerType-notFunction]:
          isFunctionPointerType(t(_, pointerType(t(_, T:K))))
          => false
          when (getKLabel(T:K) =/=KLabel 'functionType)
               andBool (getKLabel(T:K) =/=KLabel 'qualifiedType)
          
     // /*@ \source[n1570]{\para{6.2.5}{18}}
     // Integer and floating types are collectively called arithmetic types.
     // Each arithmetic type belongs to one type domain: the real type domain
     // comprises the real types, the complex type domain comprises the complex
     // types. 
     // */
     rule isArithmeticType(T:KResult)
          => hasIntegerType(T:KResult) orBool isFloatType(T:KResult)

     rule unqualifyType(t(_:Set, qualifiedType(T:KResult, _))) => T:KResult 
     rule unqualifyType(t(_:Set, T:K)) => t(.Set, T:K)
          when getKLabel(T:K) =/=KLabel 'qualifiedType 
          
     rule removeStorageSpecifiers(t(_:Set, qualifiedType(T:KResult, _)))
          => T:KResult 
     rule removeStorageSpecifiers(t(S:Set, T:K)) => t(S:Set, T:K)
          when getKLabel(T:K) =/=KLabel 'qualifiedType
          
     rule getModifiers(t(S:Set, _)) => S:Set
endmodule


module COMMON-C-TYPING
     imports COMMON-SEMANTICS-TYPE-INCLUDE
     
     imports COMMON-SEMANTICS-TYPE-DECLARATIONS 
     imports COMMON-SEMANTICS-TYPE-CANONICALIZATION 
     imports COMMON-SEMANTICS-TYPE-INTERPRETATION
     imports COMMON-SEMANTICS-TYPE-MISC
endmodule
