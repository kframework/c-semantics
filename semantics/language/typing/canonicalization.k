module C-TYPING-CANONICALIZATION-SYNTAX
     syntax K ::= "canonicalizeType" "(" Bag ")"
endmodule

module C-TYPING-CANONICALIZATION
     imports C-TYPING-CANONICALIZATION-SYNTAX
     imports C-TYPING-SYNTAX

     imports C-SYNTAX
     imports C-DYNAMIC-SYNTAX
     imports COMPAT-SYNTAX
     
     syntax K ::= "canonicalizeType-aux" "(" Bag "," K "," Bag "," Bag "," Bag ")"
     context canonicalizeType-aux(_,HOLE,_,_,_) when HOLE =/=K .K 

     rule canonicalizeType(B:Bag)
          => canonicalizeType-aux(B, .K, .Bag, .Bag, .Bag)
          [structural]

     rule (. => DeclType(K1, K2))
          ~> canonicalizeType-aux((_:Bag BagItem(TAtomic(K1:K, K2:K))), _, _, _, _) 
          [structural]
     rule (. => DeclType(K1, K2))
          ~> canonicalizeType-aux((_:Bag BagItem(AlignasType(K1:K, K2:K))), _, _, _, _) 
          [structural]
     rule (. => typeof(K))
          ~> canonicalizeType-aux((_:Bag BagItem(AlignasExpression(K:K))), _, _, _, _) 
          [structural]
          
     syntax K ::= "atomic" "(" Type ")"
     syntax K ::= "alignas" "(" Type ")"
     
     rule (T:Type => .)
          ~> canonicalizeType-aux(
               (_:Bag (BagItem(TAtomic(_, _)) => .Bag)), _, 
               (_ (.Bag => BagItem(atomic(T)))), _, _) 
          [structural]
     rule (T:Type => .)
          ~> canonicalizeType-aux(
               (_:Bag (BagItem(AlignasType(_, _)) => .Bag)), _, 
               (_ (.Bag => BagItem(alignas(T)))), _, _) 
          [structural]
     rule (T:Type => .)
          ~> canonicalizeType-aux(
               (_:Bag (BagItem(AlignasExpression(_)) => .Bag)), _, 
               (_ (.Bag => BagItem(alignas(T)))), _, _) 
          [structural]
          
     // specifier, modifier, storage
     rule canonicalizeType-aux((_:Bag (BagItem(T:K) => .Bag)), _, 
               (_ (.Bag => BagItem(T))), _, _)
          when false
               orBool (T ==K Void)
               orBool (T ==K Bool)
               orBool (T ==K Char)
               orBool (T ==K Short)
               orBool (T ==K Int)
               orBool (T ==K Long)
               orBool (T ==K Float)
               orBool (T ==K Double)
               orBool (T ==K Signed)
               orBool (T ==K Unsigned)
               orBool (T ==K Complex)
               orBool (T ==K Imaginary)
               orBool (getKLabel(T) ==KLabel 'StructDef)
               orBool (getKLabel(T) ==KLabel 'UnionDef)
               orBool (getKLabel(T) ==KLabel 'EnumDef)
               orBool (getKLabel(T) ==KLabel 'StructRef)
               orBool (getKLabel(T) ==KLabel 'UnionRef)
               orBool (getKLabel(T) ==KLabel 'EnumRef)
               orBool (getKLabel(T) ==KLabel 'Named)
               orBool (getKLabel(T) ==KLabel 'Attribute)
          [structural]

     rule canonicalizeType-aux(_:Bag (BagItem(T:K) => .Bag), _, _, _, 
               (_ (.Bag => BagItem(T))))
          when (T ==K Extern)
               orBool (T ==K Static)
               orBool (T ==K Const)
               orBool (T ==K Volatile)
               orBool (T ==K Atomic)
               orBool (T ==K Restrict)
               orBool (T ==K Auto)
               orBool (T ==K Register)
               orBool (T ==K ThreadLocal)
          [structural]
          
     rule canonicalizeType-aux(.Bag, 
               (T:Type => t(.Set, qualifiedType(T, Q))),
               .Bag, .Bag, (_ (BagItem(Q:K) => .Bag)))
          when (Q ==K Extern)
               orBool (Q ==K Static)
               orBool (Q ==K Volatile)
               orBool (Q ==K Atomic)
               orBool (Q ==K Restrict)
               orBool (Q ==K Auto)
               orBool (Q ==K Register)
               orBool (Q ==K ThreadLocal)
          [structural]
     rule canonicalizeType-aux(.Bag, (t((.Set => SetItem(Const)) _, _)),
               .Bag, .Bag, (_ (BagItem(Q:K) => .Bag)))
          when Q ==K Const
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
               => t(.Set, typedefType(X, T))
          ...</k>
          <types>... typedef(X) |-> T:Type ...</types>
          when X =/=K Identifier("")
          [structural]
          
     rule canonicalizeSpecifier(BagItem(StructRef(X:Id)))
          => t(.Set, structType(X))
          when X =/=K Identifier("")
          [structural]
     rule canonicalizeSpecifier(BagItem(EnumRef(X:Id)))
          => t(.Set, enumType(X))
          when X =/=K Identifier("")
          [structural]
     rule canonicalizeSpecifier(BagItem(UnionRef(X:Id)))
          => t(.Set, unionType(X))
          when X =/=K Identifier("")
          [structural]
          
     rule canonicalizeSpecifier(BagItem(EnumDef(X:Id, L:K)))
          => EnumDef(X, L) ~> t(.Set, enumType(X))
          when X =/=K Identifier("")
          [structural]
     
     rule <k> 
               canonicalizeSpecifier(BagItem(
                    Lbl:KLabel(((Identifier("") => unnamed(N)),, _))))
          ...</k>
          <freshNat> N:Int => N +Int 1 </freshNat>
          when Lbl ==KLabel 'StructDef
               orBool Lbl ==KLabel 'EnumDef
               orBool Lbl ==KLabel 'UnionDef
          [structural]
     
     rule canonicalizeSpecifier(BagItem(StructDef(X:Id, L:K)))
          => StructDef(X, L) ~> t(.Set, structType(X))
          when X =/=K Identifier("")
          [structural]
     rule canonicalizeSpecifier(BagItem(UnionDef(X:Id, L:K)))
          => UnionDef(X, L) ~> t(.Set, unionType(X))
          when X =/=K Identifier("")
          [structural]

     // FIXME what good is this_
     rule BagItem(SpecTypedef) => .Bag [structural, anywhere]
     // fixme ignoring inlines
     rule [ignore-inline]: BagItem(Inline) => .Bag [structural, anywhere]
     rule [ignore-noreturn]: BagItem(Noreturn) => .Bag [structural, anywhere]
     // fixme should save these for later use
     rule BagItem(Attribute(_:String, _)) => .Bag [structural, anywhere]

     rule canonicalizeType-aux(.Bag, (.K => canonicalizeSpecifier(B)),
               (B:Bag => .Bag), _, _)
          when B =/=Bag .Bag
          [structural]
          
     rule canonicalizeType-aux(.Bag, T:Type, .Bag, .Bag, .Bag) => T
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
          when (B ==Bag BagItem(Short))
               orBool (B ==Bag BagItem(Signed) BagItem(Short))
               orBool (B ==Bag BagItem(Short) BagItem(Int))
               orBool (B ==Bag BagItem(Signed) BagItem(Short) BagItem(Int))
          [structural]
     rule canonicalizeSpecifier(B:Bag) => t(.Set, unsigned-short-int)
          when (B ==Bag BagItem(Unsigned) BagItem(Short))
               orBool (B ==Bag BagItem(Unsigned) BagItem(Short) BagItem(Int))
          [structural]
     rule canonicalizeSpecifier(B:Bag) => t(.Set, int)
          when (B ==Bag BagItem(Int))
               orBool (B ==Bag BagItem(Signed))
               orBool (B ==Bag BagItem(Signed) BagItem(Int))
          [structural]
     rule canonicalizeSpecifier(B:Bag) => t(.Set, unsigned-int)
          when (B ==Bag BagItem(Unsigned))
               orBool (B ==Bag BagItem(Unsigned) BagItem(Int))
          [structural]
     rule canonicalizeSpecifier(B:Bag) => t(.Set, long-int)
          when (B ==Bag BagItem(Long))
               orBool (B ==Bag BagItem(Signed) BagItem(Long))
               orBool (B ==Bag BagItem(Long) BagItem(Int))
               orBool (B ==Bag BagItem(Signed) BagItem(Long) BagItem(Int))
          [structural]
     rule canonicalizeSpecifier(B:Bag) => t(.Set, unsigned-long-int)
          when (B ==Bag BagItem(Unsigned) BagItem(Long))
               orBool (B ==Bag BagItem(Unsigned) BagItem(Long) BagItem(Int))
          [structural]
     rule canonicalizeSpecifier(B:Bag) => t(.Set, long-long-int)
          when (B ==Bag BagItem(Long) BagItem(Long))
               orBool (B ==Bag BagItem(Signed) BagItem(Long) BagItem(Long))
               orBool (B ==Bag BagItem(Long) BagItem(Long) BagItem(Int))
               orBool (B ==Bag
                    BagItem(Signed) BagItem(Long) BagItem(Long) BagItem(Int))
          [structural]
     rule canonicalizeSpecifier(B:Bag) => t(.Set, unsigned-long-long-int)
          when (B ==Bag BagItem(Unsigned) BagItem(Long) BagItem(Long))
               orBool (B ==Bag
                    BagItem(Unsigned) BagItem(Long) BagItem(Long) BagItem(Int))
          [structural]
endmodule
