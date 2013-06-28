module C-TYPING-CANONICALIZATION-SYNTAX
     syntax K ::= "canonicalizeType" "(" Bag ")"
endmodule

module C-TYPING-CANONICALIZATION
     imports C-TYPING-CANONICALIZATION-SYNTAX

     imports C-SYNTAX
     imports C-SEMANTIC-SYNTAX
     imports C-COMPAT-SYNTAX
     
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
