module C-TYPING-CANONICALIZATION-SYNTAX
     syntax KItem ::= canonicalizeType(MSet)
endmodule

module C-TYPING-CANONICALIZATION
     imports C-TYPING-CANONICALIZATION-SYNTAX
     imports C-TYPING-SYNTAX

     imports C-SYNTAX
     imports C-DYNAMIC-SYNTAX
     imports C-BITSIZE-SYNTAX
     imports COMPAT-SYNTAX
     imports DEBUG-SYNTAX
     
     syntax KItem ::= "canonicalizeType-aux" "(" MSet "," K "," MSet "," MSet "," MSet ")"
     context canonicalizeType-aux(_, HOLE,_ ,_ ,_)

     rule canonicalizeType(M:MSet)
          => canonicalizeType-aux(M, .K, .MSet, .MSet, .MSet)
          [structural]

     rule (. => DeclType(K1, K2))
          ~> canonicalizeType-aux(_:MSet MSetItem(TAtomic(K1:K, K2:K)), _, _, _, _) 
          [structural]
     rule (. => DeclType(K1, K2))
          ~> canonicalizeType-aux(_:MSet MSetItem(AlignasType(K1:K, K2:K)), _, _, _, _) 
          [structural]
     rule (. => typeof(K))
          ~> canonicalizeType-aux(_:MSet MSetItem(AlignasExpression(K:K)), _, _, _, _) 
          [structural]
          
     syntax KItem ::= atomic(Type)
     syntax KItem ::= alignas(Type)
     
     rule (T:Type => .)
          ~> canonicalizeType-aux(
               (_:MSet (MSetItem(TAtomic(_, _)) => .MSet)), _, 
               (_ (.MSet => MSetItem(atomic(T)))), _, _) 
          [structural]
     rule (T:Type => .)
          ~> canonicalizeType-aux(
               (_:MSet (MSetItem(AlignasType(_, _)) => .MSet)), _, 
               (_ (.MSet => MSetItem(alignas(T)))), _, _) 
          [structural]
     rule (T:Type => .)
          ~> canonicalizeType-aux(
               (_:MSet (MSetItem(AlignasExpression(_)) => .MSet)), _, 
               (_ (.MSet => MSetItem(alignas(T)))), _, _) 
          [structural]
          
     // specifier, modifier, storage
     rule canonicalizeType-aux((_:MSet (MSetItem(T:K) => .MSet)), _, 
               (_ (.MSet => MSetItem(T))), _, _)
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

     rule canonicalizeType-aux(_:MSet (MSetItem(T:K) => .MSet), _, _, _, 
               (_ (.MSet => MSetItem(T))))
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
          
     rule canonicalizeType-aux(.MSet, 
               t((.Set => SetItem(Q)) _:Set, _),
               .MSet, .MSet, (_ (MSetItem(Q:K) => .MSet)))
          when (Q ==K Extern)
               orBool (Q ==K Static)
               orBool (Q ==K Volatile)
               orBool (Q ==K Atomic)
               orBool (Q ==K Restrict)
               orBool (Q ==K Auto)
               orBool (Q ==K Register)
               orBool (Q ==K ThreadLocal)
          [structural]
     rule canonicalizeType-aux(.MSet, (t((.Set => SetItem(Const)) _, _)),
               .MSet, .MSet, (_ (MSetItem(Q:K) => .MSet)))
          when Q ==K Const
          [structural]
          
     /*@ \fromStandard{\source[n1570]{\para{6.7.3}{9}}}{
     If the specification of an array type includes any type qualifiers, the
     element type is so-qualified, not the array type. \ldots
     }*/
     rule t(SetItem(Const) S:Set, arrayType(t(S':Set, T:K), N:CSize))
          => t(S, arrayType(t(SetItem(Const) S', T), N))
          [structural, anywhere]
     
     syntax KItem ::= canonicalizeSpecifier(MSet)

     rule <k> canonicalizeSpecifier(MSetItem(Named(X:CId)))
               => t(.Set, typedefType(X, T))
          ...</k>
          <types>... typedef(X) |-> T:Type ...</types>
          when X =/=K Identifier("")
          [structural]
          
     rule <k> canonicalizeSpecifier(MSetItem(StructRef(X:CId)))
               => t(.Set, structType(X, bitSizeofStruct(Info), Info))
          ...</k>
          <structs>...
               X |-> Info:FieldInfo
          ...</structs>
          when X =/=K Identifier("")
          [structural]
     rule <k> canonicalizeSpecifier(MSetItem(StructRef(X:CId)))
               => t(.Set, incompleteStructType(X))
          ...</k>
          <structs> Structs:Map </structs>
          <curr-function> file-scope </curr-function>
          <curr-tu> Tu:String </curr-tu>
          <tu-id> Tu </tu-id>
          <incomplete-tags>... .Set => SetItem(X) </incomplete-tags>
          when (X =/=K Identifier(""))
               andBool notBool (X in keys(Structs))
          [structural]
     rule <k> canonicalizeSpecifier(MSetItem(StructRef(X:CId)))
               => t(.Set, incompleteStructType(X))
          ...</k>
          <structs> Structs:Map </structs>
          <curr-function> F:K </curr-function>
          when (X =/=K Identifier(""))
               andBool notBool (X in keys(Structs))
               andBool (F =/=K file-scope)
          [structural]
     rule canonicalizeSpecifier(MSetItem(EnumRef(X:CId)))
          => t(.Set, enumType(X))
          when X =/=K Identifier("")
          [structural]
     rule <k> canonicalizeSpecifier(MSetItem(UnionRef(X:CId)))
               => t(.Set, unionType(X, bitSizeofUnion(Info), Info))
          ...</k>
          <structs>...
               X |-> Info:FieldInfo
          ...</structs>
          when X =/=K Identifier("")
          [structural]
     rule <k> canonicalizeSpecifier(MSetItem(UnionRef(X:CId)))
               => t(.Set, incompleteUnionType(X))
          ...</k>
          <structs> Structs:Map </structs>
          <curr-function> file-scope </curr-function>
          <curr-tu> Tu:String </curr-tu>
          <tu-id> Tu </tu-id>
          <incomplete-tags>... .Set => SetItem(X) </incomplete-tags>
          when (X =/=K Identifier(""))
               andBool notBool (X in keys(Structs))
          [structural]
     rule <k> canonicalizeSpecifier(MSetItem(UnionRef(X:CId)))
               => t(.Set, incompleteUnionType(X))
          ...</k>
          <structs> Structs:Map </structs>
          <curr-function> F:K </curr-function>
          when (X =/=K Identifier(""))
               andBool notBool (X in keys(Structs))
               andBool (F =/=K file-scope)
          [structural]
          
     rule canonicalizeSpecifier(MSetItem(EnumDef(X:CId, L:K)))
          => EnumDef(X, L) ~> t(.Set, enumType(X))
          when X =/=K Identifier("")
          [structural]
     
     rule <k> canonicalizeSpecifier(MSetItem(
                StructDef((Identifier("") => unnamed(N, TU)), _)))
           ...</k>
           <curr-tu> TU:String </curr-tu>
           <tu-id> TU </tu-id>
           <next-unnamed> N:Int => N +Int 1 </next-unnamed>
           [structural]
     rule <k> canonicalizeSpecifier(MSetItem(
               EnumDef((Identifier("") => unnamed(N, TU)), _)))
          ...</k>
          <curr-tu> TU:String </curr-tu>
          <tu-id> TU </tu-id>
          <next-unnamed> N:Int => N +Int 1 </next-unnamed>
          [structural]
     rule <k> canonicalizeSpecifier(MSetItem(
               UnionDef((Identifier("") => unnamed(N, TU)), _)))
          ...</k>
          <curr-tu> TU:String </curr-tu>
          <tu-id> TU </tu-id>
          <next-unnamed> N:Int => N +Int 1 </next-unnamed>
          [structural]
     
     rule (.K => StructDef(X, L))
          ~> canonicalizeSpecifier(MSetItem(
               StructDef(X:CId, L:K) => StructRef(X)))
          when X =/=K Identifier("")
          [structural]
     rule (.K => UnionDef(X, L))
          ~> canonicalizeSpecifier(MSetItem(
               UnionDef(X:CId, L:K) => UnionRef(X)))
          when X =/=K Identifier("")
          [structural]

     // FIXME what good is this_
     rule MSetItem(SpecTypedef) => .MSet [structural, anywhere]
     // FIXME ignoring inlines
     rule [ignore-inline]: MSetItem(Inline) => .MSet [structural, anywhere]
     rule [ignore-noreturn]: MSetItem(Noreturn) => .MSet [structural, anywhere]
     // FIXME should save these for later use
     rule MSetItem(Attribute(_:String, _)) => .MSet [structural, anywhere]

     rule canonicalizeType-aux(.MSet, (.K => canonicalizeSpecifier(B)),
               (B:MSet => .MSet), _, _)
          when B =/=MSet .MSet
          [structural]
          
     rule canonicalizeType-aux(.MSet, T:Type, .MSet, .MSet, .MSet) => T
          [structural]
          
     // C99 6.7.2:2
     rule canonicalizeSpecifier(MSetItem(Void)) => t(.Set, void)
     rule canonicalizeSpecifier(MSetItem(Bool)) => t(.Set, bool)
     rule canonicalizeSpecifier(MSetItem(Char)) => t(.Set, char)
     rule canonicalizeSpecifier(MSetItem(Signed) MSetItem(Char))
          => t(.Set, signed-char)
     rule canonicalizeSpecifier(MSetItem(Unsigned) MSetItem(Char))
          => t(.Set, unsigned-char)
     
     rule MSetItem(atomic(_)) => .MSetItem [structural, anywhere]
     rule MSetItem(alignas(_)) => .MSetItem [structural, anywhere]
     
     rule canonicalizeSpecifier(MSetItem(Double))
          => t(.Set, double)
     rule canonicalizeSpecifier(MSetItem(Float))
          => t(.Set, float)
     rule canonicalizeSpecifier(MSetItem(Long) MSetItem(Double))
          => t(.Set, long-double)

     rule canonicalizeSpecifier(MSetItem(Complex) MSetItem(Double))
          => t(SetItem(Complex), double)
     rule canonicalizeSpecifier(MSetItem(Complex) MSetItem(Float))
          => t(SetItem(Complex), float)
     rule canonicalizeSpecifier(MSetItem(Complex) MSetItem(Long) MSetItem(Double))
          => t(SetItem(Complex), long-double)

     rule canonicalizeSpecifier(MSetItem(Imaginary) MSetItem(Double))
          => t(SetItem(Imaginary), double)
     rule canonicalizeSpecifier(MSetItem(Imaginary) MSetItem(Float))
          => t(SetItem(Imaginary), float)
     rule canonicalizeSpecifier(MSetItem(Imaginary) MSetItem(Long) MSetItem(Double))
          => t(SetItem(Imaginary), long-double)

     rule canonicalizeSpecifier(B:MSet) => t(.Set, short-int)
          when (B ==MSet MSetItem(Short))
               orBool (B ==MSet MSetItem(Signed) MSetItem(Short))
               orBool (B ==MSet MSetItem(Short) MSetItem(Int))
               orBool (B ==MSet MSetItem(Signed) MSetItem(Short) MSetItem(Int))
          [structural]
     rule canonicalizeSpecifier(B:MSet) => t(.Set, unsigned-short-int)
          when (B ==MSet MSetItem(Unsigned) MSetItem(Short))
               orBool (B ==MSet MSetItem(Unsigned) MSetItem(Short) MSetItem(Int))
          [structural]
     rule canonicalizeSpecifier(B:MSet) => t(.Set, int)
          when (B ==MSet MSetItem(Int))
               orBool (B ==MSet MSetItem(Signed))
               orBool (B ==MSet MSetItem(Signed) MSetItem(Int))
          [structural]
     rule canonicalizeSpecifier(B:MSet) => t(.Set, unsigned-int)
          when (B ==MSet MSetItem(Unsigned))
               orBool (B ==MSet MSetItem(Unsigned) MSetItem(Int))
          [structural]
     rule canonicalizeSpecifier(B:MSet) => t(.Set, long-int)
          when (B ==MSet MSetItem(Long))
               orBool (B ==MSet MSetItem(Signed) MSetItem(Long))
               orBool (B ==MSet MSetItem(Long) MSetItem(Int))
               orBool (B ==MSet MSetItem(Signed) MSetItem(Long) MSetItem(Int))
          [structural]
     rule canonicalizeSpecifier(B:MSet) => t(.Set, unsigned-long-int)
          when (B ==MSet MSetItem(Unsigned) MSetItem(Long))
               orBool (B ==MSet MSetItem(Unsigned) MSetItem(Long) MSetItem(Int))
          [structural]
     rule canonicalizeSpecifier(B:MSet) => t(.Set, long-long-int)
          when (B ==MSet MSetItem(Long) MSetItem(Long))
               orBool (B ==MSet MSetItem(Signed) MSetItem(Long) MSetItem(Long))
               orBool (B ==MSet MSetItem(Long) MSetItem(Long) MSetItem(Int))
               orBool (B ==MSet
                    MSetItem(Signed) MSetItem(Long) MSetItem(Long) MSetItem(Int))
          [structural]
     rule canonicalizeSpecifier(B:MSet) => t(.Set, unsigned-long-long-int)
          when (B ==MSet MSetItem(Unsigned) MSetItem(Long) MSetItem(Long))
               orBool (B ==MSet
                    MSetItem(Unsigned) MSetItem(Long) MSetItem(Long) MSetItem(Int))
          [structural]
endmodule
