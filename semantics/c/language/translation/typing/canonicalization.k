module C-TYPING-CANONICALIZATION-SYNTAX
     imports LIST
     syntax KItem ::= canonicalizeType(List)
     syntax KItem ::= "canonicalizeType'" "(" List "," List "," List ")"
     syntax KItem ::= canonicalizeSpecifier(List)
     syntax Bool ::= isReducibleSpecifier(KItem) [function]
     syntax Bool ::= isReducibleModifier(KItem) [function]
     syntax KItem ::= addMods(List, KItem) [strict(2)]
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
     imports C-TYPING-COMMON-SYNTAX
     imports C-TYPING-SYNTAX
     imports INT
     imports K-REFLECTION
     imports MAP
     imports STRING
     imports C-SETTINGS-SYNTAX

     rule canonicalizeType(M::List) => canonicalizeType'(M, .List, .List)
          [structural]

     // Sort type specifiers from modifiers/qualifiers.
     rule canonicalizeType'(_::List (ListItem(S:TypeSpecifier) => .List),
               _::List (.List => ListItem(S)),
               _)
          requires notBool isReducibleSpecifier(S)
          [structural]
     rule canonicalizeType'((.List => Attrs) _::List ListItem(EnumDef(_, _, list(Attrs::List => .List))), _, _)
          requires Attrs =/=K .List
          [structural]
     rule canonicalizeType'((.List => Attrs) _::List ListItem(EnumRef(_, list(Attrs::List) => .K)), _, _)
          [structural]
     rule canonicalizeType'((.List => Attrs) _::List ListItem(StructDef(_, _, list(Attrs::List => .List))), _, _)
          requires Attrs =/=K .List
          [structural]
     rule canonicalizeType'((.List => Attrs) _::List ListItem(StructRef(_, list(Attrs::List) => .K)), _, _)
          [structural]
     rule canonicalizeType'((.List => Attrs) _::List ListItem(UnionDef(_, _, list(Attrs::List => .List))), _, _)
          requires Attrs =/=K .List
          [structural]
     rule canonicalizeType'((.List => Attrs) _::List ListItem(UnionRef(_, list(Attrs::List) => .K)), _, _)
          [structural]
     rule (.K => CV("TCANON3", "Function declared without a return type."))
          ~> canonicalizeType'(_::List ListItem(MissingType()), _, _)
          [structural]
     rule canonicalizeType'(_::List (ListItem(S::KItem) => .List),
               _,
               _::List (.List => ListItem(S)))
          requires notBool isTypeSpecifier(S)
               andBool notBool isReducibleSpecifier(S)
          [structural]
     // Canonicalize the specifiers then add the modifiers.
     rule canonicalizeType'(.List, Specs::List, Mods::List)
          => addMods(Mods, canonicalizeSpecifier(Specs))
          [structural]

     // Done like this to ignore unsupported attributes.
     rule isReducibleSpecifier(EnumDef(_, _, list(ListItem(_) _::List))) => true
     rule isReducibleSpecifier(EnumRef(_, list(_))) => true
     rule isReducibleSpecifier(StructDef(_, _, list(ListItem(_) _::List))) => true
     rule isReducibleSpecifier(StructRef(_, list(_))) => true
     rule isReducibleSpecifier(UnionDef(_, _, list(ListItem(_) _::List))) => true
     rule isReducibleSpecifier(UnionRef(_, list(_))) => true
     rule isReducibleSpecifier(MissingType()) => true
     rule isReducibleSpecifier(_) => false [owise]

     rule isReducibleModifier(TAtomic(_, _)) => true
     rule isReducibleModifier(AlignasExpression(_)) => true
     rule isReducibleModifier(AlignasType(_, _)) => true
     rule isReducibleModifier(_) => false [owise]

     rule addMods(_::List ListItem(RestrictReserved(Tok:String, _) => Restrict()), _)
          requires cfg:reservedKeywordSupported(Tok)
          [structural]
     rule (.K => SE("TCANON2","Unsupported reserved identifier "+String Tok +String " (reserved variant of restrict)."))
          ~> addMods(_Mods::List ListItem(RestrictReserved(Tok::String, _::CabsLoc)), _:Type)
          requires notBool cfg:reservedKeywordSupported(Tok)
          [structural]
     rule addMods(Mods::List ListItem(Restrict()), T:Type)
          => lintRestrictUsed() ~> addMods(Mods, addQualifier(Restrict(), T))
          [structural]
     rule addMods(Mods::List ListItem(Q:Qualifier), T:Type)
          => addMods(Mods, addQualifier(Q, T))
          requires RestrictReserved(...) :/=K Q
               andBool Restrict() :/=K Q
               andBool notBool isReducibleModifier(Q)
          [structural]
     rule addMods(Mods::List ListItem(M:Modifier), T:Type)
          => addMods(Mods, addModifier(M, T))
          requires notBool isReducibleModifier(M)
          [structural]
     rule (.K => CV("TCANON1", "Alignas attribute specifying an alignment less strict than would otherwise be required."))
          ~> addMods(.List, T:Type)
          requires isCompleteType(T)
               andBool getAlignas(T) <Int byteAlignofType(T)
          [structural]
     rule (.K => DeclType(S, D))
          ~> addMods(_ ListItem(TAtomic(S:KItem, D:KItem)), _)
          [structural]
     rule (T:Type => .K)
          ~> addMods(_::List ListItem(TAtomic(_, _) => atomic(T)), _)
          [structural]
     rule (.K => DeclType(S, D))
          ~> addMods(_ ListItem(AlignasType(S:KItem, D:KItem)), _)
          [structural]
     rule (T:Type => .K)
          ~> addMods(_::List ListItem(AlignasType(_, _) => alignas(byteAlignofType(T))), _)
          [structural]
     context addMods(_ ListItem(AlignasExpression(HOLE:KItem)), _)
     rule addMods(_::List ListItem(AlignasExpression(tv(A:Int, _)) => alignas(A)), _)
          [structural]
     rule addMods(_Mods::List (ListItem(S:KItem) => .List), _:KResult)
          requires notBool isModifier(S)
               andBool notBool isQualifier(S)
               andBool notBool isReducibleModifier(S)
          [structural]
     rule addMods(.List, T:Type) => T
          requires notBool isCompleteType(T)
               orBool getAlignas(T) >=Int byteAlignofType(T)
          [structural]

     syntax Error ::= lintRestrictUsed()
     rule lintRestrictUsed() => .K
          requires notBool hasLint

     rule <k> canonicalizeSpecifier(ListItem(Named(X:CId)))
               => type(typedefType(X, T))
          ...</k>
          <types>... typedef(X) |-> T:Type ...</types>
          requires X =/=K #NoName
          [structural]

     rule <k> canonicalizeSpecifier(ListItem(EnumRef(X:CId, .K)))
               => type(enumType(tag(X, Tu, global)))
          ...</k>
          <tags>...
               Tu |-> (_:Map tag(X, Tu, global) |-> _)
          ...</tags>
          <curr-tu> Tu:String </curr-tu>
          requires X =/=K #NoName
          [structural]
     rule <k> canonicalizeSpecifier(ListItem(EnumRef(X:CId, .K)))
               => type(enumType(tag(X, Tu, canonicalizeLocalTag(X, Tu, BlockNum, BlockHistory, Tags))))
          ...</k>
          <tags> Tags:Map </tags>
          <curr-tu> Tu:String </curr-tu>
          <curr-scope> blockScope(... block: BlockNum:Int) </curr-scope>
          <block-history> BlockHistory:List </block-history>
          requires X =/=K #NoName
               andBool notBool (tag(X, Tu, global) in_keys({{Tags[Tu] orDefault .Map}<:KItem}:>Map))
          [structural]
     rule <k> canonicalizeSpecifier(ListItem(EnumRef(X:CId, .K)))
               => type(enumType(tag(X, Tu, global)))
          ...</k>
          <tags> Tags:Map </tags>
          <curr-scope> S:Scope </curr-scope>
          <curr-tu> Tu:String </curr-tu>
          <tu-id> Tu </tu-id>
          <incomplete-tags>... .Set => SetItem(X) </incomplete-tags>
          requires (X =/=K #NoName)
               andBool notBool (tag(X, Tu, global) in_keys({{Tags[Tu] orDefault .Map}<:KItem}:>Map))
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
          requires X =/=K #NoName
          [structural]
     rule <k> canonicalizeSpecifier(ListItem(StructRef(X:CId, .K)))
               => type(structType(tag(X, Tu, canonicalizeLocalTag(X, Tu, BlockNum, BlockHistory, Tags))))
          ...</k>
          <tags> Tags:Map </tags>
          <curr-tu> Tu:String </curr-tu>
          <curr-scope> blockScope(... block: BlockNum:Int) </curr-scope>
          <block-history> BlockHistory:List </block-history>
          requires X =/=K #NoName
               andBool notBool (tag(X, Tu, global) in_keys({{Tags[Tu] orDefault .Map}<:KItem}:>Map))
          [structural]
     rule <k> canonicalizeSpecifier(ListItem(StructRef(X:CId, .K)))
               => type(structType(tag(X, Tu, global)))
          ...</k>
          <tags> Structs:Map </tags>
          <curr-scope> S:Scope </curr-scope>
          <curr-tu> Tu:String </curr-tu>
          <tu-id> Tu </tu-id>
          <incomplete-tags>... .Set => SetItem(X) </incomplete-tags>
          requires (X =/=K #NoName)
               andBool notBool (tag(X, Tu, global) in_keys({{Structs[Tu] orDefault .Map}<:KItem}:>Map))
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
          requires X =/=K #NoName
          [structural]
     rule <k> canonicalizeSpecifier(ListItem(UnionRef(X:CId, .K)))
               => type(unionType(tag(X, Tu, canonicalizeLocalTag(X, Tu, BlockNum, BlockHistory, Structs))))
          ...</k>
          <tags> Structs:Map </tags>
          <curr-tu> Tu:String </curr-tu>
          <curr-scope> blockScope(... block: BlockNum:Int) </curr-scope>
          <block-history> BlockHistory:List </block-history>
          requires X =/=K #NoName
               andBool notBool (tag(X, Tu, global) in_keys({{Structs[Tu] orDefault .Map}<:KItem}:>Map))
          [structural]
     rule <k> canonicalizeSpecifier(ListItem(UnionRef(X:CId, .K)))
               => type(unionType(tag(X, Tu, global)))
          ...</k>
          <tags> Structs:Map </tags>
          <curr-scope> S:Scope </curr-scope>
          <curr-tu> Tu:String </curr-tu>
          <tu-id> Tu </tu-id>
          <incomplete-tags>... .Set => SetItem(X) </incomplete-tags>
          requires (X =/=K #NoName)
               andBool notBool (tag(X, Tu, global) in_keys({{Structs[Tu] orDefault .Map}<:KItem}:>Map))
               andBool (isFileScope(S) ==K true
                    orBool isPrototypeScope(S) ==K true)
          [structural]

     syntax BlockRef ::= canonicalizeLocalTag(CId, String, Int, List, Map) [function]
     rule canonicalizeLocalTag(X:CId, Tu:String, _, ListItem(CurrBlock:Int) _:List, Structs:Map) => CurrBlock
          requires tag(X, Tu, CurrBlock) in_keys({{Structs[Tu] orDefault .Map}<:KItem}:>Map)
     rule canonicalizeLocalTag(X:CId, Tu:String, BlockNum:Int, ListItem(CurrBlock:Int) L:List, Structs:Map)
          => canonicalizeLocalTag(X, Tu, BlockNum, L, Structs)
          requires notBool(tag(X, Tu, CurrBlock) in_keys({{Structs[Tu] orDefault .Map}<:KItem}:>Map))
     rule canonicalizeLocalTag(_, _, BlockNum:Int, .List, _) => BlockNum

     rule <k> canonicalizeSpecifier(_ ListItem(
               EnumDef((#NoName => unnamed(N, TU)), _, _)))
          ...</k>
          <curr-tu> TU:String </curr-tu>
          <tu-id> TU </tu-id>
          <curr-program-loc> L::CabsLoc </curr-program-loc>
          <unnamed-locs>... .Map => unnamed(N,TU) |-> L ...</unnamed-locs>
          <next-unnamed> N:Int => N +Int 1 </next-unnamed>
          [structural]
     rule <k> canonicalizeSpecifier(_ ListItem(
                StructDef((#NoName => unnamed(N, TU)), _, _)))
           ...</k>
           <curr-tu> TU:String </curr-tu>
           <tu-id> TU </tu-id>
          <curr-program-loc> L::CabsLoc </curr-program-loc>
          <unnamed-locs>... .Map => unnamed(N,TU) |-> L ...</unnamed-locs>
           <next-unnamed> N:Int => N +Int 1 </next-unnamed>
           [structural]
     rule <k> canonicalizeSpecifier(_ ListItem(
               UnionDef((#NoName => unnamed(N, TU)), _, _)))
          ...</k>
          <curr-tu> TU:String </curr-tu>
          <tu-id> TU </tu-id>
          <curr-program-loc> L::CabsLoc </curr-program-loc>
          <unnamed-locs>... .Map => unnamed(N,TU) |-> L ...</unnamed-locs>
          <next-unnamed> N:Int => N +Int 1 </next-unnamed>
          [structural]

     rule (.K => EnumDef(X, L, list(.List)))
          ~> canonicalizeSpecifier(ListItem(EnumDef(X::CId, L:K, list(.List)) => EnumRef(X, .K)))
          requires X =/=K #NoName
          [structural]
     rule (.K => StructDef(X, L, list(.List)))
          ~> canonicalizeSpecifier(ListItem(StructDef(X:CId, L:K, list(.List)) => StructRef(X, .K)))
          requires X =/=K #NoName
          [structural]
     rule (.K => UnionDef(X, L, list(.List)))
          ~> canonicalizeSpecifier(ListItem(UnionDef(X:CId, L:K, list(.List)) => UnionRef(X, .K)))
          requires X =/=K #NoName
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
     rule canonicalizeSpecifier(ListItem(OversizedFloat())) => type(oversized-float)

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
     rule canonicalizeSpecifier(ListItem(Signed())) => type(signed-int)
     rule canonicalizeSpecifier(ListItem(Signed()) ListItem(Int())) => type(signed-int)
     rule canonicalizeSpecifier(ListItem(Int()) ListItem(Signed())) => type(signed-int)

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
