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
     imports C-CONFIGURATION
     imports C-DYNAMIC-SYNTAX
     imports C-ENV-SYNTAX
     imports C-ERROR-SYNTAX

     context canonicalizeType-aux(_, HOLE:KItem, _, _, _)

     syntax List ::= deleteUnuseType(List) [function]

     rule deleteUnuseType(.List) => .List
     rule deleteUnuseType(ListItem(K:K) L:List)
          => deleteUnuseType(L)
          requires K ==K SpecTypedef()
     rule deleteUnuseType(ListItem(Attribute(_, _)) L:List)
          => deleteUnuseType(L)
     rule deleteUnuseType(ListItem(K:K) L:List)
          => ListItem(K) deleteUnuseType(L)
          requires K =/=K SpecTypedef()
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
               _::List (ListItem(TAtomic(_, _)) => .List), _, _, _,
               _::List (.List => ListItem(atomic(T))))
          [structural]

     //might need to change this later
     rule (T:Type => .K)
          ~> canonicalizeType-aux(
               _::List (ListItem(AlignasType(_, _)) => .List), _, _, _,
               _::List (.List => ListItem(alignas(byteAlignofType(T)))))
          [structural]
     rule (tv(A:Int, _) => .K)
          ~> canonicalizeType-aux(
               _:List (ListItem(AlignasExpression(_)) => .List), _, _, _,
               _:List (.List => ListItem(alignas(A))))
          [structural]

     // specifier, modifier, storage
     rule canonicalizeType-aux(_:List (ListItem(T:K) => .List), _:K,
               _:List (.List => ListItem(T)), _:List, _:List)
          requires false
               orBool (T ==K Void())
               orBool (T ==K Bool())
               orBool (T ==K Char())
               orBool (T ==K Short())
               orBool (T ==K Int())
               orBool (T ==K Long())
               orBool (T ==K Float())
               orBool (T ==K Double())
               orBool (T ==K Signed())
               orBool (T ==K Unsigned())
               orBool (T ==K Complex())
               orBool (T ==K Imaginary())
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
               _:List (.List => ListItem(T)))
          requires (T ==K Extern())
               orBool (T ==K Atomic())
               orBool (T ==K Auto())
               orBool (T ==K Const())
               orBool (T ==K Inline())
               orBool (T ==K Noreturn())
               orBool (T ==K Register())
               orBool (T ==K Restrict())
               orBool (T ==K Static())
               orBool (T ==K ThreadLocal())
               orBool (T ==K Volatile())
          [structural]

     rule canonicalizeType-aux(.List,
               T:Type => addQualifier(Q, T),
               .List, .List, _:List (ListItem(Q:Qualifier) => .List))
          [structural]
     rule canonicalizeType-aux(.List,
               T:Type => addModifier(S, T),
               .List, .List, _:List (ListItem(S:K) => .List))
          requires (S in storageSpecifiers)
               orBool (S in functionSpecifiers)
               orBool (getKLabel(S) ==K #klabel(`alignas`))
          [structural]

     syntax KItem ::= canonicalizeSpecifier(List)
     rule <k> canonicalizeSpecifier(ListItem(Named(X:CId)))
               => type(typedefType(X, T))
          ...</k>
          <types>... typedef(X) |-> T:Type ...</types>
          requires X =/=K Identifier("")
          [structural]

     rule <k> canonicalizeSpecifier(ListItem(StructRef(X:CId)))
               => type(structType(tag(X, Tu, global)))
          ...</k>
          <structs>...
               Tu |-> (_:Map tag(X, Tu, global) |-> _)
          ...</structs>
          <curr-tu> Tu:String </curr-tu>
          requires X =/=K Identifier("")
          [structural]
     rule <k> canonicalizeSpecifier(ListItem(StructRef(X:CId)))
               => type(structType(tag(X, Tu, canonicalizeLocalTag(X, Tu, BlockNum, BlockHistory, Structs))))
          ...</k>
          <structs> Structs:Map </structs>
          <curr-tu> Tu:String </curr-tu>
          <curr-scope> blockScope(_, BlockNum:Int) </curr-scope>
          <block-history> BlockHistory:List </block-history>
          requires X =/=K Identifier("")
               andBool notBool (tag(X, Tu, global) in_keys(Structs[Tu]<:K:>Map))
          [structural]
     rule <k> canonicalizeSpecifier(ListItem(StructRef(X:CId)))
               => type(structType(tag(X, Tu, global)))
          ...</k>
          <structs> Structs:Map </structs>
          <curr-scope> S:Scope </curr-scope>
          <curr-tu> Tu:String </curr-tu>
          <tu-id> Tu </tu-id>
          <incomplete-tags>... .Set => SetItem(X) </incomplete-tags>
          requires (X =/=K Identifier(""))
               andBool notBool (tag(X, Tu, global) in_keys(Structs[Tu]<:K:>Map))
               andBool (isFileScope(S) ==K true
                    orBool isPrototypeScope(S) ==K true)
          [structural]
     rule canonicalizeSpecifier(ListItem(EnumRef(X:CId)))
          => type(enumType(X))
          requires X =/=K Identifier("")
          [structural]
     rule <k> canonicalizeSpecifier(ListItem(UnionRef(X:CId)))
               => type(unionType(tag(X, Tu, global)))
          ...</k>
          <structs>...
               Tu |-> (_:Map tag(X, Tu, global) |-> _)
          ...</structs>
          <curr-tu> Tu:String </curr-tu>
          requires X =/=K Identifier("")
          [structural]
     rule <k> canonicalizeSpecifier(ListItem(UnionRef(X:CId)))
               => type(unionType(tag(X, Tu, canonicalizeLocalTag(X, Tu, BlockNum, BlockHistory, Structs))))
          ...</k>
          <structs> Structs:Map </structs>
          <curr-tu> Tu:String </curr-tu>
          <curr-scope> blockScope(_, BlockNum:Int) </curr-scope>
          <block-history> BlockHistory:List </block-history>
          requires X =/=K Identifier("")
               andBool notBool (tag(X, Tu, global) in_keys(Structs[Tu]<:K:>Map))
          [structural]
     rule <k> canonicalizeSpecifier(ListItem(UnionRef(X:CId)))
               => type(unionType(tag(X, Tu, global)))
          ...</k>
          <structs> Structs:Map </structs>
          <curr-scope> S:Scope </curr-scope>
          <curr-tu> Tu:String </curr-tu>
          <tu-id> Tu </tu-id>
          <incomplete-tags>... .Set => SetItem(X) </incomplete-tags>
          requires (X =/=K Identifier(""))
               andBool notBool (tag(X, Tu, global) in_keys(Structs[Tu]<:K:>Map))
               andBool (isFileScope(S) ==K true
                    orBool isPrototypeScope(S) ==K true)
          [structural]

     syntax BlockRef ::= canonicalizeLocalTag(CId, String, Int, List, Map) [function]
     rule canonicalizeLocalTag(X:CId, Tu:String, _, ListItem(CurrBlock:Int) _:List, Structs:Map) => CurrBlock
          requires tag(X, Tu, CurrBlock) in_keys(Structs[Tu]<:K:>Map)
     rule canonicalizeLocalTag(X:CId, Tu:String, BlockNum:Int, ListItem(CurrBlock:Int) L:List, Structs:Map)
          => canonicalizeLocalTag(X, Tu, BlockNum, L, Structs)
          requires notBool(tag(X, Tu, CurrBlock) in_keys(Structs[Tu]<:K:>Map))
     rule canonicalizeLocalTag(_, _, BlockNum:Int, .List, _) => BlockNum

     rule canonicalizeSpecifier(ListItem(EnumDef(X:CId, L:K)))
          => EnumDef(X, L) ~> type(enumType(X))
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
          requires notBool isCompleteType(T)
               orBool getAlignas(T) >=Int byteAlignofType(T)
          [structural]
     rule (.K => CV("TCANON1", "Alignas attribute specifying an alignment less strict than would otherwise be required.", "6.7.5:4"))
          ~> canonicalizeType-aux(.List, T:Type, .List, .List, .List)
          requires isCompleteType(T)
               andBool getAlignas(T) <Int byteAlignofType(T)
          [structural]

     // C99 6.7.2:2
     // the way we match these by enumerating all cases is somewhat verbose, 
     // but it performs much faster than testing each individually because we
     // can evaluate all of these rules using at most four comparisons

     rule canonicalizeSpecifier(ListItem(Void())) => type(void)
     rule canonicalizeSpecifier(ListItem(Bool())) => type(bool)
     rule canonicalizeSpecifier(ListItem(Char())) => type(char)
     rule canonicalizeSpecifier(ListItem(Signed()) ListItem(Char())) => type(signed-char)
     rule canonicalizeSpecifier(ListItem(Char()) ListItem(Signed())) => type(signed-char)
     rule canonicalizeSpecifier(ListItem(Unsigned()) ListItem(Char())) => type(unsigned-char)
     rule canonicalizeSpecifier(ListItem(Char()) ListItem(Unsigned())) => type(unsigned-char)

     rule canonicalizeSpecifier(ListItem(Double())) => type(double)
     rule canonicalizeSpecifier(ListItem(Float())) => type(float)
     rule canonicalizeSpecifier(ListItem(Long()) ListItem(Double())) => type(long-double)
     rule canonicalizeSpecifier(ListItem(Double()) ListItem(Long())) => type(long-double)

     rule canonicalizeSpecifier(ListItem(Complex()) ListItem(Double()))
          => t(noQuals, SetItem(Complex()), double)
     rule canonicalizeSpecifier(ListItem(Double()) ListItem(Complex()))
          => t(noQuals, SetItem(Complex()), double)

     rule canonicalizeSpecifier(ListItem(Complex()) ListItem(Float()))
          => t(noQuals, SetItem(Complex()), float)
     rule canonicalizeSpecifier(ListItem(Float()) ListItem(Complex()))
          => t(noQuals, SetItem(Complex()), float)

     rule canonicalizeSpecifier(ListItem(Complex()) ListItem(Long()) ListItem(Double()))
          => t(noQuals, SetItem(Complex()), long-double)
     rule canonicalizeSpecifier(ListItem(Complex()) ListItem(Double()) ListItem(Long()))
          => t(noQuals, SetItem(Complex()), long-double)
     rule canonicalizeSpecifier(ListItem(Double()) ListItem(Complex()) ListItem(Long()))
          => t(noQuals, SetItem(Complex()), long-double)
     rule canonicalizeSpecifier(ListItem(Double()) ListItem(Long()) ListItem(Complex()))
          => t(noQuals, SetItem(Complex()), long-double)
     rule canonicalizeSpecifier(ListItem(Long()) ListItem(Double()) ListItem(Complex()))
          => t(noQuals, SetItem(Complex()), long-double)
     rule canonicalizeSpecifier(ListItem(Long()) ListItem(Complex()) ListItem(Double()))
          => t(noQuals, SetItem(Complex()), long-double)

     rule canonicalizeSpecifier(ListItem(Imaginary()) ListItem(Double()))
          => t(noQuals, SetItem(Imaginary()), double)
     rule canonicalizeSpecifier(ListItem(Double()) ListItem(Imaginary()))
          => t(noQuals, SetItem(Imaginary()), double)

     rule canonicalizeSpecifier(ListItem(Imaginary()) ListItem(Float()))
          => t(noQuals, SetItem(Imaginary()), float)
     rule canonicalizeSpecifier(ListItem(Float()) ListItem(Imaginary()))
          => t(noQuals, SetItem(Imaginary()), float)

     rule canonicalizeSpecifier(ListItem(Imaginary()) ListItem(Long()) ListItem(Double()))
          => t(noQuals, SetItem(Imaginary()), long-double)
     rule canonicalizeSpecifier(ListItem(Imaginary()) ListItem(Double()) ListItem(Long()))
          => t(noQuals, SetItem(Imaginary()), long-double)
     rule canonicalizeSpecifier(ListItem(Double()) ListItem(Imaginary()) ListItem(Long()))
          => t(noQuals, SetItem(Imaginary()), long-double)
     rule canonicalizeSpecifier(ListItem(Double()) ListItem(Long()) ListItem(Imaginary()))
          => t(noQuals, SetItem(Imaginary()), long-double)
     rule canonicalizeSpecifier(ListItem(Long()) ListItem(Double()) ListItem(Imaginary()))
          => t(noQuals, SetItem(Imaginary()), long-double)
     rule canonicalizeSpecifier(ListItem(Long()) ListItem(Imaginary()) ListItem(Double()))
          => t(noQuals, SetItem(Imaginary()), long-double)

     rule canonicalizeSpecifier(ListItem(Short())) => type(short-int)
     rule canonicalizeSpecifier(ListItem(Signed()) ListItem(Short())) => type(short-int)
     rule canonicalizeSpecifier(ListItem(Short()) ListItem(Signed())) => type(short-int)
     rule canonicalizeSpecifier(ListItem(Short()) ListItem(Int())) => type(short-int)
     rule canonicalizeSpecifier(ListItem(Int()) ListItem(Short())) => type(short-int)
     rule canonicalizeSpecifier(ListItem(Signed()) ListItem(Short()) ListItem(Int())) => type(short-int)
     rule canonicalizeSpecifier(ListItem(Signed()) ListItem(Int()) ListItem(Short())) => type(short-int)
     rule canonicalizeSpecifier(ListItem(Int()) ListItem(Signed()) ListItem(Short())) => type(short-int)
     rule canonicalizeSpecifier(ListItem(Int()) ListItem(Short()) ListItem(Signed())) => type(short-int)
     rule canonicalizeSpecifier(ListItem(Short()) ListItem(Signed()) ListItem(Int())) => type(short-int)
     rule canonicalizeSpecifier(ListItem(Short()) ListItem(Int()) ListItem(Signed())) => type(short-int)

     rule canonicalizeSpecifier(ListItem(Unsigned()) ListItem(Short())) => type(unsigned-short-int)
     rule canonicalizeSpecifier(ListItem(Short()) ListItem(Unsigned())) => type(unsigned-short-int)
     rule canonicalizeSpecifier(ListItem(Unsigned()) ListItem(Short()) ListItem(Int())) => type(unsigned-short-int)
     rule canonicalizeSpecifier(ListItem(Unsigned()) ListItem(Int()) ListItem(Short())) => type(unsigned-short-int)
     rule canonicalizeSpecifier(ListItem(Int()) ListItem(Unsigned()) ListItem(Short())) => type(unsigned-short-int)
     rule canonicalizeSpecifier(ListItem(Int()) ListItem(Short()) ListItem(Unsigned())) => type(unsigned-short-int)
     rule canonicalizeSpecifier(ListItem(Short()) ListItem(Unsigned()) ListItem(Int())) => type(unsigned-short-int)
     rule canonicalizeSpecifier(ListItem(Short()) ListItem(Int()) ListItem(Unsigned())) => type(unsigned-short-int)

     rule canonicalizeSpecifier(ListItem(Int())) => type(int)
     rule canonicalizeSpecifier(ListItem(Signed())) => type(int)
     rule canonicalizeSpecifier(ListItem(Signed()) ListItem(Int())) => type(int)
     rule canonicalizeSpecifier(ListItem(Int()) ListItem(Signed())) => type(int)

     rule canonicalizeSpecifier(ListItem(Unsigned())) => type(unsigned-int)
     rule canonicalizeSpecifier(ListItem(Unsigned()) ListItem(Int())) => type(unsigned-int)
     rule canonicalizeSpecifier(ListItem(Int()) ListItem(Unsigned())) => type(unsigned-int)

     rule canonicalizeSpecifier(ListItem(Long())) => type(long-int)
     rule canonicalizeSpecifier(ListItem(Signed()) ListItem(Long())) => type(long-int)
     rule canonicalizeSpecifier(ListItem(Long()) ListItem(Signed())) => type(long-int)
     rule canonicalizeSpecifier(ListItem(Long()) ListItem(Int())) => type(long-int)
     rule canonicalizeSpecifier(ListItem(Int()) ListItem(Long())) => type(long-int)
     rule canonicalizeSpecifier(ListItem(Signed()) ListItem(Long()) ListItem(Int())) => type(long-int)
     rule canonicalizeSpecifier(ListItem(Signed()) ListItem(Int()) ListItem(Long())) => type(long-int)
     rule canonicalizeSpecifier(ListItem(Int()) ListItem(Signed()) ListItem(Long())) => type(long-int)
     rule canonicalizeSpecifier(ListItem(Int()) ListItem(Long()) ListItem(Signed())) => type(long-int)
     rule canonicalizeSpecifier(ListItem(Long()) ListItem(Signed()) ListItem(Int())) => type(long-int)
     rule canonicalizeSpecifier(ListItem(Long()) ListItem(Int()) ListItem(Signed())) => type(long-int)

     rule canonicalizeSpecifier(ListItem(Unsigned()) ListItem(Long())) => type(unsigned-long-int)
     rule canonicalizeSpecifier(ListItem(Long()) ListItem(Unsigned())) => type(unsigned-long-int)
     rule canonicalizeSpecifier(ListItem(Unsigned()) ListItem(Long()) ListItem(Int())) => type(unsigned-long-int)
     rule canonicalizeSpecifier(ListItem(Unsigned()) ListItem(Int()) ListItem(Long())) => type(unsigned-long-int)
     rule canonicalizeSpecifier(ListItem(Int()) ListItem(Unsigned()) ListItem(Long())) => type(unsigned-long-int)
     rule canonicalizeSpecifier(ListItem(Int()) ListItem(Long()) ListItem(Unsigned())) => type(unsigned-long-int)
     rule canonicalizeSpecifier(ListItem(Long()) ListItem(Unsigned()) ListItem(Int())) => type(unsigned-long-int)
     rule canonicalizeSpecifier(ListItem(Long()) ListItem(Int()) ListItem(Unsigned())) => type(unsigned-long-int)

     rule canonicalizeSpecifier(ListItem(Long()) ListItem(Long())) => type(long-long-int)
     rule canonicalizeSpecifier(ListItem(Signed()) ListItem(Long()) ListItem(Long())) => type(long-long-int)
     rule canonicalizeSpecifier(ListItem(Long()) ListItem(Signed()) ListItem(Long())) => type(long-long-int)
     rule canonicalizeSpecifier(ListItem(Long()) ListItem(Long()) ListItem(Signed())) => type(long-long-int)
     rule canonicalizeSpecifier(ListItem(Int()) ListItem(Long()) ListItem(Long())) => type(long-long-int)
     rule canonicalizeSpecifier(ListItem(Long()) ListItem(Int()) ListItem(Long())) => type(long-long-int)
     rule canonicalizeSpecifier(ListItem(Long()) ListItem(Long()) ListItem(Int())) => type(long-long-int)
     rule canonicalizeSpecifier(ListItem(Signed()) ListItem(Long()) ListItem(Long()) ListItem(Int())) => type(long-long-int)
     rule canonicalizeSpecifier(ListItem(Long()) ListItem(Signed()) ListItem(Long()) ListItem(Int())) => type(long-long-int)
     rule canonicalizeSpecifier(ListItem(Long()) ListItem(Long()) ListItem(Signed()) ListItem(Int())) => type(long-long-int)
     rule canonicalizeSpecifier(ListItem(Signed()) ListItem(Long()) ListItem(Int()) ListItem(Long())) => type(long-long-int)
     rule canonicalizeSpecifier(ListItem(Long()) ListItem(Signed()) ListItem(Int()) ListItem(Long())) => type(long-long-int)
     rule canonicalizeSpecifier(ListItem(Long()) ListItem(Long()) ListItem(Int()) ListItem(Signed())) => type(long-long-int)
     rule canonicalizeSpecifier(ListItem(Signed()) ListItem(Int()) ListItem(Long()) ListItem(Long())) => type(long-long-int)
     rule canonicalizeSpecifier(ListItem(Long()) ListItem(Int()) ListItem(Signed()) ListItem(Long())) => type(long-long-int)
     rule canonicalizeSpecifier(ListItem(Long()) ListItem(Int()) ListItem(Long()) ListItem(Signed())) => type(long-long-int)
     rule canonicalizeSpecifier(ListItem(Int()) ListItem(Signed()) ListItem(Long()) ListItem(Long())) => type(long-long-int)
     rule canonicalizeSpecifier(ListItem(Int()) ListItem(Long()) ListItem(Signed()) ListItem(Long())) => type(long-long-int)
     rule canonicalizeSpecifier(ListItem(Int()) ListItem(Long()) ListItem(Long()) ListItem(Signed())) => type(long-long-int)

     rule canonicalizeSpecifier(ListItem(Unsigned()) ListItem(Long()) ListItem(Long())) => type(unsigned-long-long-int)
     rule canonicalizeSpecifier(ListItem(Long()) ListItem(Unsigned()) ListItem(Long())) => type(unsigned-long-long-int)
     rule canonicalizeSpecifier(ListItem(Long()) ListItem(Long()) ListItem(Unsigned())) => type(unsigned-long-long-int)
     rule canonicalizeSpecifier(ListItem(Unsigned()) ListItem(Long()) ListItem(Long()) ListItem(Int())) => type(unsigned-long-long-int)
     rule canonicalizeSpecifier(ListItem(Long()) ListItem(Unsigned()) ListItem(Long()) ListItem(Int())) => type(unsigned-long-long-int)
     rule canonicalizeSpecifier(ListItem(Long()) ListItem(Long()) ListItem(Unsigned()) ListItem(Int())) => type(unsigned-long-long-int)
     rule canonicalizeSpecifier(ListItem(Unsigned()) ListItem(Long()) ListItem(Int()) ListItem(Long())) => type(unsigned-long-long-int)
     rule canonicalizeSpecifier(ListItem(Long()) ListItem(Unsigned()) ListItem(Int()) ListItem(Long())) => type(unsigned-long-long-int)
     rule canonicalizeSpecifier(ListItem(Long()) ListItem(Long()) ListItem(Int()) ListItem(Unsigned())) => type(unsigned-long-long-int)
     rule canonicalizeSpecifier(ListItem(Unsigned()) ListItem(Int()) ListItem(Long()) ListItem(Long())) => type(unsigned-long-long-int)
     rule canonicalizeSpecifier(ListItem(Long()) ListItem(Int()) ListItem(Unsigned()) ListItem(Long())) => type(unsigned-long-long-int)
     rule canonicalizeSpecifier(ListItem(Long()) ListItem(Int()) ListItem(Long()) ListItem(Unsigned())) => type(unsigned-long-long-int)
     rule canonicalizeSpecifier(ListItem(Int()) ListItem(Unsigned()) ListItem(Long()) ListItem(Long())) => type(unsigned-long-long-int)
     rule canonicalizeSpecifier(ListItem(Int()) ListItem(Long()) ListItem(Unsigned()) ListItem(Long())) => type(unsigned-long-long-int)
     rule canonicalizeSpecifier(ListItem(Int()) ListItem(Long()) ListItem(Long()) ListItem(Unsigned())) => type(unsigned-long-long-int)

endmodule
