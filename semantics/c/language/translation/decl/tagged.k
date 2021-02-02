module C-DECL-TAGGED-SYNTAX
     imports LIST
     imports COMMON-SORTS
     imports C-TYPING-SORTS
     // Not defined, just used.
     syntax KItem ::= addGlobalTag(CId, TagInfo)
     syntax KItem ::= addLocalTag(CId, TagInfo)

endmodule

module C-DECL-TAGGED
     imports C-DECL-TAGGED-SYNTAX
     imports C-CONFIGURATION
     imports BOOL
     imports INT
     imports MAP
     imports STRING
     imports C-ABSTRACT-SYNTAX
     imports C-ALIGNMENT-SYNTAX
     imports C-BITSIZE-SYNTAX
     imports C-DECL-DEFINITION-SYNTAX
     imports C-DYNAMIC-SYNTAX
     imports C-ENV-SYNTAX
     imports C-ERROR-SYNTAX
     imports COMPAT-SYNTAX
     imports C-SETTINGS-SYNTAX
     imports C-SYNTAX
     imports C-TYPING-INTERPRETATION-SYNTAX
     imports C-TYPING-SYNTAX
     imports C-TYPING-MISC
     imports SETTINGS-SYNTAX

     context StructDef(_, HOLE:StrictList => seqstrict(HOLE), _)
     context UnionDef(_, HOLE:StrictList => seqstrict(HOLE), _)

     // TODO(chathhorn): handle global/local differently.
     // note that struct defs might appear buried in a type.
     rule EnumDef(X::CId, list(L::List), list(Mods::List))
          => defEnumConstants(Packed() in Mods, X, 0, 0, 0, L, .Map)
          [structural]
     rule StructDef(X::CId, krlist(L::List), list(Mods::List))
          => addTag(X, makeStructFieldInfo(Packed() in Mods, incompleteToFlexibleArrayMember(numberUnnamed(L))))
          requires hasNamedField(L) andBool structFieldsComplete(L)
               andBool (firstNamedZeroLengthBitfield(L) ==String "")
          [structural]
     rule (.K => UNDEF("CDT1", "Structs must contain a named member."))
          ~> StructDef(_, krlist(L::List), _)
          requires notBool hasNamedField(L)
          [structural]
     rule (.K => CV("CDT3", "Field " +String firstIncompleteOrFlexible(L) +String " has incomplete type or contains a flexible array member."))
          ~> StructDef(_, krlist(L::List), _)
          requires notBool structFieldsComplete(L)
          [structural]
     rule (.K => errorNamedZeroLengthBitfield(firstNamedZeroLengthBitfield(L)))
          ~> StructDef(_, krlist(L::List), _)
          requires firstNamedZeroLengthBitfield(L) =/=String ""
          [structural]
     rule UnionDef(X::CId, krlist(L::List), list(Mods::List))
          => addTag(X, makeUnionFieldInfo(Packed() in Mods, numberUnnamed(L)))
          requires hasNamedField(L) andBool allComplete(L)
               andBool (firstNamedZeroLengthBitfield(L) ==String "")
          [structural]
     rule (.K => UNDEF("CDT2", "Unions must contain a named member."))
          ~> UnionDef(_, krlist(L::List), _)
          requires notBool hasNamedField(L)
          [structural]
     rule (.K => CV("CDT4", "Field " +String firstIncomplete(L) +String " has incomplete type."))
          ~> UnionDef(_, krlist(L::List), _)
          requires notBool allComplete(L)
          [structural]
     rule (.K => errorNamedZeroLengthBitfield(firstNamedZeroLengthBitfield(L)))
          ~> UnionDef(_, krlist(L::List), _)
          requires firstNamedZeroLengthBitfield(L) =/=String ""
          [structural]

     syntax KItem ::= errorNamedZeroLengthBitfield(String) [function]
     rule errorNamedZeroLengthBitfield(F::String)
          => CV("CDT5", "Declaration for zero-length bit-field " +String F +String " has a declarator.")

     syntax KItem ::= defEnumConstants(Bool, CId, Int, Int, Int, List, Map)

     rule defEnumConstants(Pack::Bool, X::CId, Min::Int, Max::Int, Next::Int, ListItem(EnumItem(E::CId)) L::List, M::Map)
          => initEnum(E, tv(Next, ut(SetItem(IntegerConstant), int)))
          ~> defEnumConstants(Pack, X, minInt(Min, Next), maxInt(Max, Next), Next +Int 1, L, M[Next <- E])
          [structural]
     context defEnumConstants(_, _, _, _, _, ListItem(EnumItemInit(_, HOLE:KItem => reval(HOLE))) _, _) [result(RValue)]
     rule defEnumConstants(Pack::Bool, X::CId, Min::Int, Max::Int, _, ListItem(EnumItemInit(E::CId, R:RValue)) L::List, M::Map)
          => initEnum(E, R)
          ~> defEnumConstants(Pack, X, minInt(Min, asInt(R)), maxInt(Max, asInt(R)), asInt(R) +Int 1, L, M[asInt(R) <- E])
          [structural]
      // Packed enums attempt to use a smaller type as the alias.
     rule defEnumConstants(true, X::CId, Min::Int, Max::Int, _, .List, M::Map)
          => addTag(X, enumInfo(firstSuitableType(Min, Max, packedEnumAliases), M))
          [structural]
     rule defEnumConstants(false, X::CId, Min::Int, Max::Int, _, .List, M::Map)
          => addTag(X, enumInfo(firstSuitableType(Min, Max, enumAliases), M))
          [structural]

     syntax SimpleIntegerType ::= firstSuitableType(Int, Int, List) [function]
     rule firstSuitableType(Min::Int, Max::Int, ListItem(T::SimpleIntegerType) _) => T
          requires Min >=Int min(utype(T)) andBool Max <=Int max(utype(T))
     rule firstSuitableType(Min::Int, _, .List)
          // Appears to be gcc's behavior.
          => #if Min >=Int 0 #then unsigned-long-int #else long-int #fi
     rule firstSuitableType(_, _, (ListItem(_) => .List) _) [owise]

     syntax List ::= "packedEnumAliases" [function]
     rule packedEnumAliases
          => ListItem(unsigned-char)
             ListItem(signed-char)
             ListItem(unsigned-short-int)
             ListItem(short-int)
             ListItem(unsigned-int)
             ListItem(int)
             ListItem(unsigned-long-int)
             ListItem(long-int)

     syntax List ::= "enumAliases" [function]
     rule enumAliases
          => ListItem(unsigned-int)
             ListItem(int)
             ListItem(unsigned-long-int)
             ListItem(long-int)

     syntax Int ::= asInt(RValue) [function]
     rule asInt(R::RValue) => {value(R)}:>Int
          requires isInt(value(R))
     // In this case, the configuration should be about to get stuck, so it
     // doesn't matter.
     rule asInt(_) => 0 [owise]

     syntax KItem ::= initEnum(CId, KItem) [strict(2)]
     rule initEnum(X:CId, tv(Value:Int, integerUType #as T::UType)) => addEnum(X, Value)
          requires IntegerConstant in getModifiers(T)
               andBool intInRange(Value, ut(.Set, int))
     rule (.K => CV("CDE1", "Enum initializer not an integer constant expression."))
          ~> initEnum(_, R:RValue)
          requires isHold(R) orBool notBool isIntegerType(type(R))
               orBool notBool IntegerConstant in getModifiers(utype(R))
     rule (.K => CV("CDE2", "Enum initializer outside the range representable by int."))
          ~> initEnum(_, tv(Value:Int, integerUType #as T::UType))
          requires notBool intInRange(Value, ut(.Set, int))
               andBool (IntegerConstant in getModifiers(T))

     syntax Bool ::= hasNamedField(List) [function]
     rule hasNamedField(ListItem(typedDeclaration(_, F::CId)) _) => true
          requires notBool isNoName(F)
     rule hasNamedField(ListItem(F:CId) _) => true
          requires notBool isNoName(F)
     rule hasNamedField(ListItem(_:NoName) L::List)
          => hasNamedField(L)
     rule hasNamedField(ListItem(typedDeclaration(T::Type, _:NoName)) L::List)
          => hasNamedField(L)
          requires notBool isStructOrUnionType(T)
     rule hasNamedField(ListItem(typedDeclaration(structOrUnionType #as T::Type, _:NoName)) L::List)
          => hasNamedField(findFieldNames(T) L)
     rule hasNamedField(.List) => false

     syntax List ::= incompleteToFlexibleArrayMember(List) [function]
     rule incompleteToFlexibleArrayMember(
          ListItem(typedDeclaration(t(Qs::Quals, Mods::Set, incompleteArrayType(T::Type)), X:CId)))
          => ListItem(typedDeclaration(t(Qs, Mods, flexibleArrayType(T)), X))
     rule incompleteToFlexibleArrayMember(ListItem(D::KItem) L::List)
          => ListItem(D) incompleteToFlexibleArrayMember(L)
          [owise]
     rule incompleteToFlexibleArrayMember(.List) => .List

     syntax Bool ::= structFieldsComplete(List) [function]
     rule structFieldsComplete(ListItem(D::KItem) L::List)
          => isCompleteType(type(D)) andBool isRigidType(type(D))
               andBool structFieldsComplete(L)
          requires L =/=K .List
     rule structFieldsComplete(ListItem(D::KItem))
          => (isCompleteType(type(D)) andBool isRigidType(type(D))) orBool isIncompleteArrayType(type(D))
     rule structFieldsComplete(.List) => true

     syntax Bool ::= isRigidType(Type) [function]
     rule isRigidType(T::Type) => notBool isFlexibleType(T)

     syntax String ::= firstIncomplete(List) [function]
     rule firstIncomplete(ListItem(typedDeclaration(T::Type, X::CId)) _) => showCId(X)
          requires notBool isCompleteType(T)
     rule firstIncomplete((ListItem(typedDeclaration(T::Type, X::CId)) => .List) _)
          requires isCompleteType(T)
     rule firstIncomplete(.List) => ""

     syntax String ::= firstIncompleteOrFlexible(List) [function]
     rule firstIncompleteOrFlexible(ListItem(typedDeclaration(T::Type, X::CId)) _) => showCId(X)
          requires notBool isCompleteType(T) orBool isFlexibleType(T)
     rule firstIncompleteOrFlexible((ListItem(_) => .List) _) [owise]
     rule firstIncompleteOrFlexible(.List) => ""

     syntax String ::= firstNamedZeroLengthBitfield(List) [function]
     rule firstNamedZeroLengthBitfield(ListItem(typedDeclaration(T::Type, X::CId)) _) => showCId(X)
          requires (bitSizeofType(T) ==Int 0) andBool isBitfieldType(T)
               andBool notBool isNoName(X)
     rule firstNamedZeroLengthBitfield((ListItem(_) => .List) _) [owise]
     rule firstNamedZeroLengthBitfield(.List) => ""

     syntax KItem ::= addTag(CId, TagInfo)
     rule <k> addTag(S:CId, fieldInfo(Fs:List, NBits:Int, Ts:Map, Offs:Map, PaddingOffs:Set, MaxAlign:Int))
               // Elide function parameter names in struct types.
               => addGlobalTag(S, fieldInfo(elideList(Fs), NBits, elideMap(Ts), Offs, PaddingOffs, MaxAlign))
          ...</k>
          <curr-scope> fileScope </curr-scope>
          [structural]
     rule <k> addTag(S:CId, enumInfo(...) #as EI::EnumInfo)
               => addGlobalTag(S, EI)
          ...</k>
          <curr-scope> fileScope </curr-scope>
          [structural]
     rule <k> addTag(S:CId, fieldInfo(Fs:List, NBits:Int, Ts:Map, Offs:Map, PaddingOffs:Set, MaxAlign:Int))
               => addLocalTag(S, fieldInfo(elideList(Fs), NBits, elideMap(Ts), Offs, PaddingOffs, MaxAlign))
          ...</k>
          <curr-scope> Scope:Scope </curr-scope>
          requires isFileScope(Scope) =/=K true
          [structural]
     rule <k> addTag(S:CId, enumInfo(...) #as EI::EnumInfo)
               => addLocalTag(S, EI)
          ...</k>
          <curr-scope> Scope:Scope </curr-scope>
          requires isFileScope(Scope) =/=K true
          [structural]

     rule <k> addLocalTag(_, _) ...</k>
          <curr-tu> Tu:String </curr-tu>
          <tags> S:Map => S[Tu <- .Map] </tags>
          requires notBool (Tu in_keys(S))

     rule <k> addLocalTag(X:CId, Info::TagInfo) => .K ...</k>
          <tags>... Tu |-> (Structs:Map => Structs[tag(X, Tu, BlockNum) <- Info]) ...</tags>
          <curr-tu> Tu:String </curr-tu>
          <curr-scope> blockScope(... block: BlockNum:Int) </curr-scope>
          requires notBool (tag(X, Tu, global) in_keys(Structs))
               andBool notBool (tag(X, Tu, BlockNum) in_keys(Structs))
          [structural]
     rule <k> (.K => CV("TDG15", "Redefinition of a struct, union, or enum: "
               +String showCId(X)))
               ~> addLocalTag(X:CId, _)
          ...</k>
          <curr-tu> Tu:String </curr-tu>
          <tags>... Tu |-> Structs:Map ...</tags>
          <curr-scope> blockScope(... block: BlockNum:Int) </curr-scope>
          requires (tag(X, Tu, global) in_keys(Structs))
               orBool (tag(X, Tu, BlockNum) in_keys(Structs))
          [structural]

     rule makeUnionFieldInfo(Pack::Bool, Fs::List)
          => makeUnionFieldInfo'(Pack, Fs, .Map, .Map, .List)

     syntax FieldInfo ::= "makeUnionFieldInfo'" "(" Bool "," List "," Map ","  Map "," List ")" [function]
     rule makeUnionFieldInfo'(Pack::Bool,
               ListItem(typedDeclaration(T::Type, Field::CId)) L::List,
               Types::Map,
               Offsets::Map,
               NL::List)
          => makeUnionFieldInfo'(Pack, L,
               Types[Field <- T], Offsets[Field <- 0],
               NL ListItem(typedDeclaration(T, Field)))
     rule makeUnionFieldInfo'(true, .List, Types::Map, Offsets::Map, NL::List)
          => fieldInfo(NL, maxByteSizeofList(NL) *Int cfg:bitsPerByte, Types, Offsets, .Set, maxByteAlignofDecls(NL))
     rule makeUnionFieldInfo'(false, .List, Types::Map, Offsets::Map, NL::List)
          => fieldInfo(NL,
               roundBits(maxByteSizeofList(NL) *Int cfg:bitsPerByte, maxByteAlignofDecls(NL)),
               Types, Offsets, getPaddingOffsets(maxByteSizeofList(NL) *Int cfg:bitsPerByte, roundBits(maxByteSizeofList(NL) *Int cfg:bitsPerByte, maxByteAlignofDecls(NL))), maxByteAlignofDecls(NL))


     rule makeStructFieldInfo(Pack::Bool, Fs::List)
          => makeStructFieldInfo'(Pack, Fs, 0, .Map, .Map, .List)

     syntax FieldInfo ::= "makeStructFieldInfo'" "(" Bool "," List "," Int "," Map ","  Map "," List ")" [function]
     rule makeStructFieldInfo'(Pack::Bool,
               ListItem(typedDeclaration(T::Type, Field::CId)) L::List,
               V::Int,
               Types::Map,
               Offsets::Map,
               NL::List)
          => makeStructFieldInfo'(Pack,
               L,
               pad(V, T) +Int bitSizeofType(T),
               Types[Field <- T],
               Offsets[Field <- pad(V, T)],
               NL ListItem(typedDeclaration(T, Field)))
     rule makeStructFieldInfo'(true, .List, V::Int, Types::Map, Offsets::Map, NL::List)
          => fieldInfo(NL, roundBits(V, 1),
               Types, Offsets,
               computePaddingOffsets(NL, roundBits(V, 1), Types, Offsets), maxByteAlignofDecls(NL))
     rule makeStructFieldInfo'(false, .List, V::Int, Types::Map, Offsets::Map, NL::List)
          => fieldInfo(NL, roundBits(V, maxByteAlignofDecls(NL)),
               Types, Offsets,
               computePaddingOffsets(NL, roundBits(V, maxByteAlignofDecls(NL)), Types, Offsets),
               maxByteAlignofDecls(NL))

     // The padding associated with a particular field precedes it, with
     // possibly some extra padding at the end of the whole struct not
     // associated with any field. This is important for understanding the
     // effect of the gcc et al. packed attr as applied to a particular field.

     syntax Int ::= pad(Int, Type) [function]
     // Non-bitfields are aligned according to their type (if we note that
     // fields tagged with the Packed() attribute have an alignment of 1 byte).
     rule [[ pad(V::Int, T::Type) => roundBits(V, minInt(byteAlignofType(T), PackV)) ]]
          <pragma-pack-value> PackV::Int </pragma-pack-value>
          requires notBool isBitfieldType(T)
     // Non-packed bitfields that would cross an alignment boundary and
     // zero-length bitfields have an alignment of the bitfield field type.
     rule [[ pad(V::Int, t(... st: bitfieldType(...)) #as T::Type) => roundBits(V, minInt(byteAlignofType(innerType(T)), PackV)) ]]
          <pragma-pack-value> PackV::Int </pragma-pack-value>
          requires notBool (Packed() in getModifiers(T))
               andBool (V +Int bitSizeofType(T)) >Int roundBits(V, byteAlignofType(innerType(T)))
     rule pad(V::Int, t(... st: bitfieldType(...)) #as T::Type) => roundBits(V, byteAlignofType(innerType(T)))
          requires bitSizeofType(T) ==Int 0
     // Packed bitfields and non-packed bitfields that don't cross an alignment
     // boundary have 1-bit alignment (no padding).
     rule pad(V::Int, _) => V [owise]

     rule maxByteAlignofDecls(L:List) => maxByteAlignofDecls'(1, L)

     syntax Int ::= "maxByteAlignofDecls'" "(" Int "," List ")" [function]

     rule [[ maxByteAlignofDecls'(Sz::Int, ListItem(typedDeclaration(T::Type, _)) LL:List)
          => maxByteAlignofDecls'(maxInt(Sz, minInt(byteAlignofType(T), PackV)), LL) ]]
          <pragma-pack-value> PackV::Int </pragma-pack-value>

     rule maxByteAlignofDecls'(Sz::Int, .List) => Sz


endmodule

