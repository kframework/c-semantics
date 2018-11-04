module C-TYPING-CANONICALIZATION-SYNTAX
     imports LIST
     syntax KItem ::= canonicalizeType(List)
     syntax KItem ::= "canonicalizeType'" "(" List "," List "," List ")"
     syntax KItem ::= canonicalizeSpecifier(List)
     syntax Bool ::= isReducibleSpecifier(K) [function]
     syntax KItem ::= addMods(List, K) [strict(2)]
endmodule

module C-TYPING-CANONICALIZATION
     imports C-TYPING-CANONICALIZATION-SYNTAX

     imports BOOL
     imports C-ABSTRACT-SYNTAX
     imports C-ALIGNMENT-SYNTAX
     imports C-BITSIZE-SYNTAX
     imports C-CONFIGURATION
     imports C-DECL-TAGGED-SYNTAX
     imports C-DYNAMIC-SYNTAX
     imports C-ERROR-SYNTAX
     imports COMMON-SYNTAX
     imports COMPAT-SYNTAX
     imports C-SYNTAX
     imports C-TYPING-SYNTAX
     imports INT
     imports K-REFLECTION
     imports MAP
     imports STRING
     imports C-SETTINGS-SYNTAX

     rule canonicalizeType(M::List) => canonicalizeType'(M, .List, .List)
          [structural]
     // Sort specifiers from modifiers.
     rule canonicalizeType'(_::List (ListItem(S:TypeSpecifier) => .List),
               _::List (.List => ListItem(S)),
               _)
          [structural]
     rule canonicalizeType'(_::List (ListItem(M:Modifier) => .List),
               _,
               _::List (.List => ListItem(M)))
          [structural]
     rule canonicalizeType'(_::List (ListItem(S:KItem) => .List),
               _,
               _)
          requires notBool isModifier(S)
               andBool notBool isTypeSpecifier(S)
               andBool notBool isReducibleSpecifier(S)
          [structural]
     rule (.K => DeclType(S, D))
          ~> canonicalizeType'(_ ListItem(TAtomic(S:K, D:K)), _, _)
          [structural]
     rule (T:Type => .K)
          ~> canonicalizeType'(_::List (ListItem(TAtomic(_, _)) => .List),
               _,
               _::List (.List => ListItem(atomic(T))))
          [structural]
     rule (.K => DeclType(S, D))
          ~> canonicalizeType'(_ ListItem(AlignasType(S:K, D:K)), _, _)
          [structural]
     rule (T:Type => .K)
          ~> canonicalizeType'(_::List (ListItem(AlignasType(_, _)) => .List),
               _,
               _::List (.List => ListItem(alignas(byteAlignofType(T)))))
          [structural]
     context canonicalizeType'(_ ListItem(AlignasExpression(HOLE:KItem)), _, _)
     rule canonicalizeType'(_::List (ListItem(AlignasExpression(tv(A:Int, _))) => .List),
               _,
               _::List (.List => ListItem(alignas(A))))
          [structural]
     rule canonicalizeType'(_::List (ListItem(S:KItem) => ListItem(SpecExtendsTuOf(getKccExtendsTuOfAttr(S)))), _, _)
          requires getKccExtendsTuOfAttr(S) =/=K #NoName
          [structural]
     rule (.K => CV("TCANON3", "Function declared without a return type."))
          ~> canonicalizeType'(_::List ListItem(MissingType()), _, _)
          [structural]
     // Canonicalize the specifiers then add the modifiers.
     rule canonicalizeType'(.List, Specs::List, Mods::List)
          => addMods(Mods, canonicalizeSpecifier(Specs))
          [structural]

     // Done like this to ignore unsupported attributes.
     rule isReducibleSpecifier(TAtomic(_, _)) => true
     rule isReducibleSpecifier(AlignasExpression(_)) => true
     rule isReducibleSpecifier(AlignasType(_, _)) => true
     rule isReducibleSpecifier(MissingType()) => true
     rule isReducibleSpecifier(Attribute(_, list(Attrs::List))) => true
          requires getKccExtendsTuOf(Attrs) =/=K #NoName
     rule isReducibleSpecifier(_) => false [owise]

     syntax CId ::= getKccExtendsTuOfAttr(K) [function]
     rule getKccExtendsTuOfAttr(Attribute(_, list(Attrs::List))) => getKccExtendsTuOf(Attrs)
     rule getKccExtendsTuOfAttr(_) => #NoName [owise]

     syntax CId ::= getKccExtendsTuOf(List) [function]
     rule getKccExtendsTuOf(ListItem(Call(Identifier("kcc_extends_tu_of"), list(ListItem(X::CId)))) _) => X
     rule getKccExtendsTuOf(.List) => #NoName
     rule getKccExtendsTuOf((ListItem(_) => .List) _) [owise]

     rule addMods(Mods::List ListItem(RestrictReserved(Tok:String, _)), T:Type)
          => addMods(Mods, addQualifier(Restrict(), T))
          requires cfg:reservedKeywordSupported(Tok)
          [structural]
     rule addMods(Mods::List ListItem(RestrictReserved(Tok::String, Loc::CabsLoc)), T:Type)
          => SE("TCANON2","Unsupported reserved identifier "+String Tok +String " (reserved variant of restrict).")
          requires notBool cfg:reservedKeywordSupported(Tok)
          [structural]
     rule addMods(Mods::List ListItem(Q:Qualifier), T:Type)
          => addMods(Mods, addQualifier(Q, T))
          requires getKLabel(Q) =/=K #klabel(`RestrictReserved`)
          [structural]
     rule addMods(Mods::List ListItem(M:Modifier), T:Type)
          => addMods(Mods, addModifier(M, T))
          requires notBool isQualifier(M)
          [structural]
     rule addMods(Mods::List (ListItem(S:KItem) => .List), _)
          requires notBool isModifier(S)
               andBool notBool isReducibleSpecifier(S)
          [structural]
     rule addMods(_::List (ListItem(S:KItem) => ListItem(SpecExtendsTuOf(getKccExtendsTuOfAttr(S)))), _)
          requires getKccExtendsTuOfAttr(S) =/=K #NoName
          [structural]
     rule addMods(.List, T:Type) => T
          requires notBool isCompleteType(T)
               orBool getAlignas(T) >=Int byteAlignofType(T)
          [structural]
     rule (.K => CV("TCANON1", "Alignas attribute specifying an alignment less strict than would otherwise be required."))
          ~> addMods(.List, T:Type)
          requires isCompleteType(T)
               andBool getAlignas(T) <Int byteAlignofType(T)
          [structural]

     rule <k> canonicalizeSpecifier(ListItem(Named(X:CId)))
               => type(typedefType(X, T))
          ...</k>
          <types>... typedef(X) |-> T:Type ...</types>
          requires X =/=K Identifier("")
          [structural]

     rule canonicalizeSpecifier(Specs::List ListItem(EnumRef(X::CId, list(Attrs::List))))
          => canonicalizeSpecifier(Attrs Specs ListItem(EnumRef(X, .K)))
          [structural]
     rule canonicalizeSpecifier(Specs::List ListItem(StructRef(X::CId, list(Attrs::List))))
          => canonicalizeSpecifier(Attrs Specs ListItem(StructRef(X, .K)))
          [structural]
     rule canonicalizeSpecifier(Specs::List ListItem(UnionRef(X::CId, list(Attrs::List))))
          => canonicalizeSpecifier(Attrs Specs ListItem(UnionRef(X, .K)))
          [structural]

     rule <k> canonicalizeSpecifier(ListItem(EnumRef(X:CId, .K)))
               => type(enumType(tag(X, Tu, global)))
          ...</k>
          <tags>...
               Tu |-> (_:Map tag(X, Tu, global) |-> _)
          ...</tags>
          <curr-tu> Tu:String </curr-tu>
          requires X =/=K Identifier("")
          [structural]
     rule <k> canonicalizeSpecifier(ListItem(EnumRef(X:CId, .K)))
               => type(enumType(tag(X, Tu, canonicalizeLocalTag(X, Tu, BlockNum, BlockHistory, Tags))))
          ...</k>
          <tags> Tags:Map </tags>
          <curr-tu> Tu:String </curr-tu>
          <curr-scope> blockScope(_, BlockNum:Int) </curr-scope>
          <block-history> BlockHistory:List </block-history>
          requires X =/=K Identifier("")
               andBool notBool (tag(X, Tu, global) in_keys({{Tags[Tu]}<:KItem}:>Map))
          [structural]
     rule <k> canonicalizeSpecifier(ListItem(EnumRef(X:CId, .K)))
               => type(enumType(tag(X, Tu, global)))
          ...</k>
          <tags> Tags:Map </tags>
          <curr-scope> S:Scope </curr-scope>
          <curr-tu> Tu:String </curr-tu>
          <tu-id> Tu </tu-id>
          <incomplete-tags>... .Set => SetItem(X) </incomplete-tags>
          requires (X =/=K Identifier(""))
               andBool notBool (tag(X, Tu, global) in_keys({{Tags[Tu]}<:KItem}:>Map))
               andBool (isFileScope(S) ==K true
                    orBool isPrototypeScope(S) ==K true)
          [structural]

     rule <k> canonicalizeSpecifier(ListItem(StructRef(X:CId, .K)))
               => type(structType(tag(X, Tu, global)))
          ...</k>
          <tags>...
               Tu |-> (_:Map tag(X, Tu, global) |-> _)
          ...</tags>
          <curr-tu> Tu:String </curr-tu>
          requires X =/=K Identifier("")
          [structural]
     rule <k> canonicalizeSpecifier(ListItem(StructRef(X:CId, .K)))
               => type(structType(tag(X, Tu, canonicalizeLocalTag(X, Tu, BlockNum, BlockHistory, Tags))))
          ...</k>
          <tags> Tags:Map </tags>
          <curr-tu> Tu:String </curr-tu>
          <curr-scope> blockScope(_, BlockNum:Int) </curr-scope>
          <block-history> BlockHistory:List </block-history>
          requires X =/=K Identifier("")
               andBool notBool (tag(X, Tu, global) in_keys({{Tags[Tu]}<:KItem}:>Map))
          [structural]
     rule <k> canonicalizeSpecifier(ListItem(StructRef(X:CId, .K)))
               => type(structType(tag(X, Tu, global)))
          ...</k>
          <tags> Structs:Map </tags>
          <curr-scope> S:Scope </curr-scope>
          <curr-tu> Tu:String </curr-tu>
          <tu-id> Tu </tu-id>
          <incomplete-tags>... .Set => SetItem(X) </incomplete-tags>
          requires (X =/=K Identifier(""))
               andBool notBool (tag(X, Tu, global) in_keys({{Structs[Tu]}<:KItem}:>Map))
               andBool (isFileScope(S) ==K true
                    orBool isPrototypeScope(S) ==K true)
          [structural]

     rule <k> canonicalizeSpecifier(ListItem(UnionRef(X:CId, .K)))
               => type(unionType(tag(X, Tu, global)))
          ...</k>
          <tags>...
               Tu |-> (_:Map tag(X, Tu, global) |-> _)
          ...</tags>
          <curr-tu> Tu:String </curr-tu>
          requires X =/=K Identifier("")
          [structural]
     rule <k> canonicalizeSpecifier(ListItem(UnionRef(X:CId, .K)))
               => type(unionType(tag(X, Tu, canonicalizeLocalTag(X, Tu, BlockNum, BlockHistory, Structs))))
          ...</k>
          <tags> Structs:Map </tags>
          <curr-tu> Tu:String </curr-tu>
          <curr-scope> blockScope(_, BlockNum:Int) </curr-scope>
          <block-history> BlockHistory:List </block-history>
          requires X =/=K Identifier("")
               andBool notBool (tag(X, Tu, global) in_keys({{Structs[Tu]}<:KItem}:>Map))
          [structural]
     rule <k> canonicalizeSpecifier(ListItem(UnionRef(X:CId, .K)))
               => type(unionType(tag(X, Tu, global)))
          ...</k>
          <tags> Structs:Map </tags>
          <curr-scope> S:Scope </curr-scope>
          <curr-tu> Tu:String </curr-tu>
          <tu-id> Tu </tu-id>
          <incomplete-tags>... .Set => SetItem(X) </incomplete-tags>
          requires (X =/=K Identifier(""))
               andBool notBool (tag(X, Tu, global) in_keys({{Structs[Tu]}<:KItem}:>Map))
               andBool (isFileScope(S) ==K true
                    orBool isPrototypeScope(S) ==K true)
          [structural]

     syntax BlockRef ::= canonicalizeLocalTag(CId, String, Int, List, Map) [function]
     rule canonicalizeLocalTag(X:CId, Tu:String, _, ListItem(CurrBlock:Int) _:List, Structs:Map) => CurrBlock
          requires tag(X, Tu, CurrBlock) in_keys({{Structs[Tu]}<:KItem}:>Map)
     rule canonicalizeLocalTag(X:CId, Tu:String, BlockNum:Int, ListItem(CurrBlock:Int) L:List, Structs:Map)
          => canonicalizeLocalTag(X, Tu, BlockNum, L, Structs)
          requires notBool(tag(X, Tu, CurrBlock) in_keys({{Structs[Tu]}<:KItem}:>Map))
     rule canonicalizeLocalTag(_, _, BlockNum:Int, .List, _) => BlockNum

     rule <k> canonicalizeSpecifier(_ ListItem(
               EnumDef((Identifier("") => unnamed(N, TU)), _, _)))
          ...</k>
          <curr-tu> TU:String </curr-tu>
          <tu-id> TU </tu-id>
          <curr-program-loc> L::CabsLoc </curr-program-loc>
          <unnamed-locs>... .Map => unnamed(N,TU) |-> L ...</unnamed-locs>
          <next-unnamed> N:Int => N +Int 1 </next-unnamed>
          [structural]
     rule <k> canonicalizeSpecifier(_ ListItem(
                StructDef((Identifier("") => unnamed(N, TU)), _, _)))
           ...</k>
           <curr-tu> TU:String </curr-tu>
           <tu-id> TU </tu-id>
          <curr-program-loc> L::CabsLoc </curr-program-loc>
          <unnamed-locs>... .Map => unnamed(N,TU) |-> L ...</unnamed-locs>
           <next-unnamed> N:Int => N +Int 1 </next-unnamed>
           [structural]
     rule <k> canonicalizeSpecifier(_ ListItem(
               UnionDef((Identifier("") => unnamed(N, TU)), _, _)))
          ...</k>
          <curr-tu> TU:String </curr-tu>
          <tu-id> TU </tu-id>
          <curr-program-loc> L::CabsLoc </curr-program-loc>
          <unnamed-locs>... .Map => unnamed(N,TU) |-> L ...</unnamed-locs>
          <next-unnamed> N:Int => N +Int 1 </next-unnamed>
          [structural]

     rule canonicalizeSpecifier((ListItem(S:KItem) => .List) _)
          requires notBool isTypeSpecifier(S)
               andBool notBool isReducibleSpecifier(S)
          [structural]

     rule canonicalizeSpecifier(Specs::List ListItem(EnumDef(X::CId, Fs:K, list(Attrs::List))))
          => canonicalizeSpecifier(Attrs Specs ListItem(EnumDef(X, Fs, list(.List))))
          requires Attrs =/=K .List
          [structural]
     rule canonicalizeSpecifier(Specs::List ListItem(StructDef(X::CId, Fs:K, list(Attrs::List))))
          => canonicalizeSpecifier(Attrs Specs ListItem(StructDef(X, Fs, list(.List))))
          requires Attrs =/=K .List
          [structural]
     rule canonicalizeSpecifier(Specs::List ListItem(UnionDef(X::CId, Fs:K, list(Attrs::List))))
          => canonicalizeSpecifier(Attrs Specs ListItem(UnionDef(X, Fs, list(.List))))
          requires Attrs =/=K .List
          [structural]

     rule (.K => EnumDef(X, L, list(.List)))
          ~> canonicalizeSpecifier(ListItem(EnumDef(X::CId, L:K, list(.List)) => EnumRef(X, .K)))
          requires X =/=K Identifier("")
          [structural]
     rule (.K => StructDef(X, L, list(.List)))
          ~> canonicalizeSpecifier(ListItem(StructDef(X:CId, L:K, list(.List)) => StructRef(X, .K)))
          requires X =/=K Identifier("")
          [structural]
     rule (.K => UnionDef(X, L, list(.List)))
          ~> canonicalizeSpecifier(ListItem(UnionDef(X:CId, L:K, list(.List)) => UnionRef(X, .K)))
          requires X =/=K Identifier("")
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

     rule canonicalizeSpecifier(ListItem(OversizedInt())) => type(oversized-int)
     rule canonicalizeSpecifier(ListItem(Signed()) ListItem(OversizedInt())) => type(oversized-int)
     rule canonicalizeSpecifier(ListItem(OversizedInt()) ListItem(Signed())) => type(oversized-int)

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

     rule canonicalizeSpecifier(ListItem(Unsigned()) ListItem(OversizedInt())) => type(unsigned-oversized-int)
     rule canonicalizeSpecifier(ListItem(OversizedInt()) ListItem(Unsigned())) => type(unsigned-oversized-int)

     rule canonicalizeSpecifier(ListItem(AutoType())) => type(auto-type)

     rule (.K => CV("TCANON4", "Declaration with no type specifiers."))
          ~> canonicalizeSpecifier(.List)

endmodule
