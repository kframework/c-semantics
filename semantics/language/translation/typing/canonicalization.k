module C-TYPING-CANONICALIZATION-SYNTAX
     imports LIST
     syntax KItem ::= canonicalizeType(List)
     syntax KItem ::= "canonicalizeType-aux" "(" List "," K "," List "," List "," List ")"
endmodule

module C-TYPING-CANONICALIZATION
     imports C-TYPING-CANONICALIZATION-SYNTAX
     imports C-TYPING-SYNTAX

     imports C-ABSTRACT-SYNTAX
     imports C-ALIGNMENT-SYNTAX
     imports C-BITSIZE-SYNTAX
     imports C-DYNAMIC-SYNTAX
     imports C-ENV-SYNTAX
     imports C-CONFIGURATION

     context canonicalizeType-aux(_, HOLE:KItem, _, _, _)

     syntax List ::= deleteUnuseType(List) [function]

     rule deleteUnuseType(.List) => .List
     rule deleteUnuseType(ListItem(K:K) L:List)
          => deleteUnuseType(L)
          requires K ==K SpecTypedef
     rule deleteUnuseType(ListItem(Attribute(_, _)) L:List)
          => deleteUnuseType(L)
     rule deleteUnuseType(ListItem(K:K) L:List)
          => ListItem(K) deleteUnuseType(L)
          requires K =/=K SpecTypedef
               andBool getKLabel(K) =/=K #klabel(`Attribute`)

     rule canonicalizeType(M:List)
          => canonicalizeType-aux(deleteUnuseType(M), .K, .List, .List, .List)
          [structural]

     rule (.K => DeclType(K1, K2))
          ~> canonicalizeType-aux(_:List ListItem(TAtomic(K1:K, K2:K)), _, _, _, _)
          [structural]
     rule (.K => DeclType(K1, K2))
          ~> canonicalizeType-aux(_:List ListItem(AlignasType(K1:K, K2:K)), _, _, _, _)
          [structural]
     rule (.K => K)
          ~> canonicalizeType-aux(_:List ListItem(AlignasExpression(K:K)), _, _, _, _)
          [structural]

     rule (T:Type => .K)
          ~> canonicalizeType-aux(
               _:List (ListItem(TAtomic(_, _)) => .List), _, _, _,
               _:List (.List => ListItem(atomic(T))))
          [structural]

     //might need to change this later
     rule (T:Type => .K)
          ~> canonicalizeType-aux(
               _:List (ListItem(AlignasType(_, _)) => .List), _, _, _,
               _:List (.List => ListItem(alignas(byteAlignofType(T)))))
          [structural]
     rule (tv(A:Int, _) => .K)
          ~> canonicalizeType-aux(
               _:List (ListItem(AlignasExpression(_)) => .List), _, _, _,
               _:List (.List => ListItem(alignas(A))))
          [structural]

     // specifier, modifier, storage
     rule canonicalizeType-aux((_:List (ListItem(T:K) => .List)), _:K,
               (_:List (.List => ListItem(T))), _:List, _:List)
          requires false
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
               orBool (getKLabel(T) ==K #klabel(`StructDef`))
               orBool (getKLabel(T) ==K #klabel(`UnionDef`))
               orBool (getKLabel(T) ==K #klabel(`EnumDef`))
               orBool (getKLabel(T) ==K #klabel(`StructRef`))
               orBool (getKLabel(T) ==K #klabel(`UnionRef`))
               orBool (getKLabel(T) ==K #klabel(`EnumRef`))
               orBool (getKLabel(T) ==K #klabel(`Named`))
               orBool (getKLabel(T) ==K #klabel(`Attribute`))
          [structural]

     rule canonicalizeType-aux(_:List (ListItem(T:K) => .List), _:K, _:List, _:List,
               (_:List (.List => ListItem(T))))
          requires (T ==K Extern)
               orBool (T ==K Atomic)
               orBool (T ==K Auto)
               orBool (T ==K Const)
               orBool (T ==K Inline)
               orBool (T ==K Noreturn)
               orBool (T ==K Register)
               orBool (T ==K Restrict)
               orBool (T ==K Static)
               orBool (T ==K ThreadLocal)
               orBool (T ==K Volatile)
          [structural]

     rule canonicalizeType-aux(.List,
               t((.Set => SetItem(Q)) _, _),
               .List, .List, (_:List (ListItem(Q:K) => .List)))
          requires (Q ==K Extern)
               orBool (Q ==K Atomic)
               orBool (Q ==K Auto)
               orBool (Q ==K Const)
               orBool (Q ==K Inline)
               orBool (Q ==K Noreturn)
               orBool (Q ==K Register)
               orBool (Q ==K Restrict)
               orBool (Q ==K Static)
               orBool (Q ==K ThreadLocal)
               orBool (Q ==K Volatile)
               orBool (getKLabel(Q) ==K #klabel(`alignas`))
               orBool (getKLabel(Q) ==K #klabel(`atomic`))
          [structural]

     //need this to solve array type anywhere rule
     //syntax Type ::= canonicalizeArrayType(Type) [function]
     //syntax List ::= canonicalizeArrayTypeInList(List) [function]
     //syntax Map ::= canonicalizeArrayTypeInMap(Map) [function]

// TODO(chathhorn): merging; doesn't make sense to me.
//     //change this because of anywhere rule
//     rule canonicalizeType-aux(.List, (t(S:Set, T:SimpleType)
//          => canonicalizeArrayType(t(SetItem(Const) S, T))),
//               .List, .List, (_:List (ListItem(Const) => .List)))
//          [structural]
     /*@ \fromStandard{\source[n1570]{\para{6.7.3}{9}}}{
     If the specification of an array type includes any type qualifiers, the
     element type is so-qualified, not the array type. \ldots
     }*/
     /*TODO(liyili2): anywhere rule refactor
     rule t(SetItem(Const) S:Set, arrayType(t(S':Set, T:K), N:Int))
          => t(S, arrayType(t(SetItem(Const) S', T), N))
          [structural, anywhere]
     */
// TODO(chathhorn): merging; rework.
//      rule canonicalizeArrayTypeInList(.List) => .List
//      rule canonicalizeArrayTypeInList(ListItem(T:Type) L:List)
//      => ListItem(canonicalizeArrayType(T)) canonicalizeArrayTypeInList(L)
//
//      rule canonicalizeArrayTypeInMap(.Map) => .Map
//      rule canonicalizeArrayTypeInMap((K:K |-> T:Type) M:Map)
//      => (K |-> canonicalizeArrayType(T)) canonicalizeArrayTypeInMap(M)
//
//      rule canonicalizeArrayType(T:Type) => T
//      requires getKLabel(T) =/=K #klabel(t)
//          andBool getKLabel(T) =/=K #klabel(typedDeclaration)
//      rule canonicalizeArrayType(typedDeclaration(T:Type, C:CId))
//      => typedDeclaration(canonicalizeArrayType(T), C)
//      rule canonicalizeArrayType(t(SetItem(Const) S:Set,
//        arrayType(t(S':Set, T:K), N:Int)))
//      => t(S, arrayType(canonicalizeArrayType(t(SetItem(Const) S', T)), N))
//      rule canonicalizeArrayType(t(S:Set, bitfieldType(T:Type, N:Int)))
//      => t(S, bitfieldType(canonicalizeArrayType(T), N))
//      rule canonicalizeArrayType(t(S:Set, functionType(T:Type, L:List)))
//      => t(S, functionType(canonicalizeArrayType(T), canonicalizeArrayTypeInList(L)))
//      rule canonicalizeArrayType(t(S:Set, pointerType(T:Type)))
//      => t(S, pointerType(canonicalizeArrayType(T)))
//      rule canonicalizeArrayType(t(S:Set, incompleteArrayType(T:Type)))
//      => t(S, incompleteArrayType(canonicalizeArrayType(T)))
//      rule canonicalizeArrayType(t(S:Set, flexibleArrayType(T:Type)))
//      => t(S, flexibleArrayType(canonicalizeArrayType(T)))
//      rule canonicalizeArrayType(t(S:Set, structType(C:CId, N:Int, fieldInfo(L:List, M1:Map, M2:Map))))
//      => t(S, structType(C, N, fieldInfo(canonicalizeArrayTypeInList(L),
//                canonicalizeArrayTypeInMap(M1), M2)))
//      rule canonicalizeArrayType(t(S:Set, incompleteStructType(C:CId)))
//      => t(S, incompleteStructType(C))
//      rule canonicalizeArrayType(t(S:Set, unionType(C:CId, N:Int, fieldInfo(L:List, M1:Map, M2:Map))))
//      => t(S, unionType(C, N, fieldInfo(canonicalizeArrayTypeInList(L),
//                canonicalizeArrayTypeInMap(M1), M2)))
//      rule canonicalizeArrayType(t(S:Set, incompleteUnionType(C:CId)))
//      => t(S, incompleteUnionType(C))
//      rule canonicalizeArrayType(t(S:Set, typedefType(C:CId, T:Type)))
//      => t(S, typedefType(C, canonicalizeArrayType(T)))
//      rule canonicalizeArrayType(T:BasicType) => T

     syntax KItem ::= canonicalizeSpecifier(List)
     rule <k> canonicalizeSpecifier(ListItem(Named(X:CId)))
               => t(.Set, typedefType(X, T))
          ...</k>
          <types>... typedef(X) |-> T:Type ...</types>
          requires X =/=K Identifier("")
          [structural]

     rule <k> canonicalizeSpecifier(ListItem(StructRef(X:CId)))
               => t(.Set, structType(global(X, Tu)))
          ...</k>
          <structs>...
               global(X, Tu) |-> _
          ...</structs>
          <curr-tu> Tu:String </curr-tu>
          requires X =/=K Identifier("")
          [structural]
     rule <k> canonicalizeSpecifier(ListItem(StructRef(X:CId)))
               => t(.Set, structType(local(X, Tu, BlockNum)))
          ...</k>
          <structs>...
               local(X, Tu, BlockNum) |-> _
          ...</structs>
          <curr-tu> Tu:String </curr-tu>
          <curr-scope> blockScope(_, BlockNum:Int) </curr-scope>
          requires X =/=K Identifier("")
          [structural]
     rule <k> canonicalizeSpecifier(ListItem(StructRef(X:CId)))
               => t(.Set, structType(global(X, Tu)))
          ...</k>
          <structs> Structs:Map </structs>
          <curr-scope> S:Scope </curr-scope>
          <curr-tu> Tu:String </curr-tu>
          <tu-id> Tu </tu-id>
          <incomplete-tags>... .Set => SetItem(X) </incomplete-tags>
          requires (X =/=K Identifier(""))
               andBool notBool (global(X, Tu) in_keys(Structs))
               andBool (isFileScope(S) ==K true
                    orBool isPrototypeScope(S) ==K true)
          [structural]
     rule <k> canonicalizeSpecifier(ListItem(StructRef(X:CId)))
               => t(.Set, structType(local(X, Tu, BlockNum)))
          ...</k>
          <structs> Structs:Map </structs>
          <curr-scope> blockScope(_, BlockNum:Int) </curr-scope>
          <curr-tu> Tu:String </curr-tu>
          <incomplete-tags>... .Set => SetItem(X) </incomplete-tags>
          requires (X =/=K Identifier(""))
               andBool notBool (global(X, Tu) in_keys(Structs))
               andBool notBool (local(X, Tu, BlockNum) in_keys(Structs))
          [structural]
     rule canonicalizeSpecifier(ListItem(EnumRef(X:CId)))
          => t(.Set, enumType(X))
          requires X =/=K Identifier("")
          [structural]
     rule <k> canonicalizeSpecifier(ListItem(UnionRef(X:CId)))
               => t(.Set, unionType(global(X, Tu)))
          ...</k>
          <structs>...
               global(X, Tu) |-> _
          ...</structs>
          <curr-tu> Tu:String </curr-tu>
          requires X =/=K Identifier("")
          [structural]
     rule <k> canonicalizeSpecifier(ListItem(UnionRef(X:CId)))
               => t(.Set, unionType(local(X, Tu, BlockNum)))
          ...</k>
          <structs>...
               local(X, Tu, BlockNum) |-> _
          ...</structs>
          <curr-tu> Tu:String </curr-tu>
          <curr-scope> blockScope(_, BlockNum:Int) </curr-scope>
          requires X =/=K Identifier("")
          [structural]
     rule <k> canonicalizeSpecifier(ListItem(UnionRef(X:CId)))
               => t(.Set, unionType(global(X, Tu)))
          ...</k>
          <structs> Structs:Map </structs>
          <curr-scope> S:Scope </curr-scope>
          <curr-tu> Tu:String </curr-tu>
          <tu-id> Tu </tu-id>
          <incomplete-tags>... .Set => SetItem(X) </incomplete-tags>
          requires (X =/=K Identifier(""))
               andBool notBool (global(X, Tu) in_keys(Structs))
               andBool (isFileScope(S) ==K true
                    orBool isPrototypeScope(S) ==K true)
          [structural]
     rule <k> canonicalizeSpecifier(ListItem(UnionRef(X:CId)))
               => t(.Set, unionType(local(X, Tu, BlockNum)))
          ...</k>
          <structs> Structs:Map </structs>
          <curr-scope> blockScope(_, BlockNum:Int) </curr-scope>
          <curr-tu> Tu:String </curr-tu>
          <incomplete-tags>... .Set => SetItem(X) </incomplete-tags>
          requires (X =/=K Identifier(""))
               andBool notBool (global(X, Tu) in_keys(Structs))
               andBool notBool (local(X, Tu, BlockNum) in_keys(Structs))
          [structural]
 
     rule canonicalizeSpecifier(ListItem(EnumDef(X:CId, L:K)))
          => EnumDef(X, L) ~> t(.Set, enumType(X))
          requires X =/=K Identifier("")
          [structural]

     rule <k> canonicalizeSpecifier(ListItem(
                StructDef((Identifier("") => unnamed(N, TU)), _)))
           ...</k>
           <curr-tu> TU:String </curr-tu>
           <tu-id> TU </tu-id>
           <next-unnamed> N:Int => N +Int 1 </next-unnamed>
           [structural]
     rule <k> canonicalizeSpecifier(ListItem(
               EnumDef((Identifier("") => unnamed(N, TU)), _)))
          ...</k>
          <curr-tu> TU:String </curr-tu>
          <tu-id> TU </tu-id>
          <next-unnamed> N:Int => N +Int 1 </next-unnamed>
          [structural]
     rule <k> canonicalizeSpecifier(ListItem(
               UnionDef((Identifier("") => unnamed(N, TU)), _)))
          ...</k>
          <curr-tu> TU:String </curr-tu>
          <tu-id> TU </tu-id>
          <next-unnamed> N:Int => N +Int 1 </next-unnamed>
          [structural]

     rule (.K => StructDef(X, L))
          ~> canonicalizeSpecifier(ListItem(
               StructDef(X:CId, L:K) => StructRef(X)))
          requires X =/=K Identifier("")
          [structural]
     rule (.K => UnionDef(X, L))
          ~> canonicalizeSpecifier(ListItem(
               UnionDef(X:CId, L:K) => UnionRef(X)))
          requires X =/=K Identifier("")
          [structural]

     rule canonicalizeType-aux(.List, (.K => canonicalizeSpecifier(B)),
               (B:List => .List), _, _)
          requires B =/=K .List
          [structural]

     rule canonicalizeType-aux(.List, T:Type, .List, .List, .List) => T
          [structural]

     // C99 6.7.2:2
     rule canonicalizeSpecifier(ListItem(Void)) => t(.Set, void)
     rule canonicalizeSpecifier(ListItem(Bool)) => t(.Set, bool)
     rule canonicalizeSpecifier(ListItem(Char)) => t(.Set, char)
     rule canonicalizeSpecifier(L:List)
          => t(.Set, signed-char)
          requires L ==MSet (ListItem(Signed) ListItem(Char))
     rule canonicalizeSpecifier(L:List )
          => t(.Set, unsigned-char)
          requires L ==MSet (ListItem(Unsigned) ListItem(Char))

     rule canonicalizeSpecifier(ListItem(Double))
          => t(.Set, double)
     rule canonicalizeSpecifier(ListItem(Float))
          => t(.Set, float)
     rule canonicalizeSpecifier(L:List)
          => t(.Set, long-double)
          requires L ==MSet (ListItem(Long) ListItem(Double))

     rule canonicalizeSpecifier(L:List)
          => t(SetItem(Complex), double)
          requires L ==MSet (ListItem(Complex) ListItem(Double))

     rule canonicalizeSpecifier(L:List)
          => t(SetItem(Complex), float)
          requires L ==MSet (ListItem(Complex) ListItem(Float))

     rule canonicalizeSpecifier(L:List)
          => t(SetItem(Complex), long-double)
          requires L ==MSet (ListItem(Complex) ListItem(Long) ListItem(Double))

     rule canonicalizeSpecifier(ListItem(Imaginary) ListItem(Double))
          => t(SetItem(Imaginary), double)
     rule canonicalizeSpecifier(ListItem(Imaginary) ListItem(Float))
          => t(SetItem(Imaginary), float)
     rule canonicalizeSpecifier(ListItem(Imaginary) ListItem(Long) ListItem(Double))
          => t(SetItem(Imaginary), long-double)

     rule canonicalizeSpecifier(B:List) => t(.Set, short-int)
          requires B ==MSet ListItem(Short) 
               orBool B ==MSet (ListItem(Signed) ListItem(Short))
               orBool B ==MSet (ListItem(Short) ListItem(Int))
               orBool B ==MSet (ListItem(Signed) ListItem(Short) ListItem(Int))
          [structural]
     rule canonicalizeSpecifier(B:List) => t(.Set, unsigned-short-int)
          requires B ==MSet (ListItem(Unsigned) ListItem(Short))
               orBool B ==MSet (ListItem(Unsigned) ListItem(Short) ListItem(Int))
          [structural]
     rule canonicalizeSpecifier(B:List) => t(.Set, int)
          requires B ==MSet ListItem(Int)
               orBool B ==MSet (ListItem(Signed))
               orBool B ==MSet (ListItem(Signed) ListItem(Int))
          [structural]
     rule canonicalizeSpecifier(B:List) => t(.Set, unsigned-int)
          requires B ==MSet ListItem(Unsigned)
               orBool B ==MSet (ListItem(Unsigned) ListItem(Int))
          [structural]
     rule canonicalizeSpecifier(B:List) => t(.Set, long-int)
          requires B ==MSet ListItem(Long)
               orBool B ==MSet (ListItem(Signed) ListItem(Long))
               orBool B ==MSet (ListItem(Long) ListItem(Int))
               orBool B ==MSet (ListItem(Signed) ListItem(Long) ListItem(Int))
          [structural]
     rule canonicalizeSpecifier(B:List) => t(.Set, unsigned-long-int)
          requires B ==MSet (ListItem(Unsigned) ListItem(Long))
               orBool B ==MSet (ListItem(Unsigned) ListItem(Long) ListItem(Int))
          [structural]
     rule canonicalizeSpecifier(B:List) => t(.Set, long-long-int)
          requires B ==MSet (ListItem(Long) ListItem(Long))
               orBool B ==MSet (ListItem(Signed) ListItem(Long) ListItem(Long))
               orBool B ==MSet (ListItem(Long) ListItem(Long) ListItem(Int))
               orBool B ==MSet (ListItem(Signed) ListItem(Long) ListItem(Long) ListItem(Int))
          [structural]
     rule canonicalizeSpecifier(B:List) => t(.Set, unsigned-long-long-int)
          requires B ==MSet (ListItem(Unsigned) ListItem(Long) ListItem(Long))
               orBool B ==MSet (ListItem(Unsigned) ListItem(Long) ListItem(Long) ListItem(Int))
          [structural]
endmodule
