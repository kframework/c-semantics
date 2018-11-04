module C-TYPING-COMMON-SYNTAX
     imports LIST
     imports BASIC-K
     imports C-TYPING-SORTS
     imports COMMON-SORTS

     // Function id, def return type, def params, local declarations.
     syntax RValue ::= functionObject(CId, Type, List)

     syntax Type ::= adjustParams(Type) [function]
     syntax List ::= "adjustParams'" "(" List ")" [function]

endmodule

module C-TYPING-COMMON
     imports C-TYPING-COMMON-SYNTAX
     imports C-CONFIGURATION
     imports FLOAT
     imports K-REFLECTION
     imports COMPAT-SYNTAX
     imports C-SETTINGS-SYNTAX
     imports C-TYPING-SYNTAX

     rule type(T:Type) => T
     rule type(typedDeclaration(T::Type, _)) => T
     rule type(T:SimpleType) => t(noQuals, .Set, T)
     rule type(T:SimpleArrayUType) => t(noQuals, .Set, qualSimple(T))
     rule type(ut(Mods::Set, T::SimpleUType)) => t(noQuals, Mods, qualSimple(T))

     rule utype(t(_, Mods::Set, T::SimpleType)) => ut(Mods, unqualSimple(T))
     rule utype(typedDeclaration(T::Type, _)) => utype(T)
     rule utype(T:SimpleType) => ut(.Set, unqualSimple(T))
     rule utype(T:SimpleArrayUType) => ut(.Set, T)
     rule utype(T:UType) => T

     syntax SimpleUType ::= unqualSimple(SimpleType) [function]
     rule unqualSimple(arrayType(T::Type, N::Int))
          => arrayUType(utype(T), N)
     rule unqualSimple(incompleteArrayType(T::Type))
          => incompleteArrayUType(utype(T))
     rule unqualSimple(flexibleArrayType(T::Type))
          => flexibleArrayUType(utype(T))
     rule unqualSimple(unspecifiedArrayType(T::Type))
          => unspecifiedArrayUType(utype(T))
     rule unqualSimple(variableLengthArrayType(T::Type, N:K))
          => variableLengthArrayUType(utype(T), N)
     rule unqualSimple(T::SimpleType) => {T}:>SimpleUType
          requires isSimpleUType(T)

     syntax SimpleType ::= qualSimple(SimpleUType) [function]
     rule qualSimple(arrayUType(T::UType, N::Int))
          => arrayType(type(T), N)
     rule qualSimple(incompleteArrayUType(T::UType))
          => incompleteArrayType(type(T))
     rule qualSimple(flexibleArrayUType(T::UType))
          => flexibleArrayType(type(T))
     rule qualSimple(unspecifiedArrayUType(T::UType))
          => unspecifiedArrayType(type(T))
     rule qualSimple(variableLengthArrayUType(T::UType, N:K))
          => variableLengthArrayType(type(T), N)
     rule qualSimple(T::SimpleUType) => {T}:>SimpleType
          requires isSimpleType(T)

     rule sameAlignas(Mods:Set, Mods':Set)
          => getAlignasMod(Mods) ==Int getAlignasMod(Mods')

     rule getAlignasMod(SetItem(alignas(N::Int)) _) => N
     rule getAlignasMod(_) => -1 [owise]

     rule noQuals => quals(.Set)

     rule Q::Qualifier inQuals quals(Qs::Set) => Q in Qs

     rule quals(Qs::Set) +Qual Q::Qualifier => quals(Qs SetItem(Q))

     rule quals(SetItem(Q) Qs::Set) -Qual Q::Qualifier => quals(Qs)
     rule Qs::Quals -Qual _ => Qs [owise]

     rule quals(Qs::Set) <=Quals quals(Qs'::Set) => Qs <=Set Qs'

     rule quals(Qs::Set) +Quals quals(Qs'::Set) => quals(Qs Qs')

     rule toQuals(SetItem(Q:Qualifier) S::Set) => toQuals(S) +Qual Q
     rule toQuals(SetItem(K::KItem) S::Set) => toQuals(S)
          requires notBool isQualifier(K)
     rule toQuals(.Set) => noQuals

     rule stripQualifiers(T::Type) => type(utype(T))

     rule getModifiers(ut(S::Set, _)) => S
     rule getModifiers(_::UType) => .Set [owise]

     rule getModifiers(t(_, S::Set, _)) => S
     rule getModifiers(_::Type) => .Set [owise]

     rule getTag(tag(S:CId, _, _)) => S

     rule getEnumAlias(S::TagId) => getEnumAlias'(getTagInfo(S))

     syntax SimpleBasicType ::= "getEnumAlias'" "(" TagInfo ")" [function]
     rule getEnumAlias'(enumInfo(... enumAlias: T::SimpleBasicType)) => T
     rule getEnumAlias'(_) => no-type [owise]

     rule getFieldInfo(Tag::TagId) => toFieldInfo(getTagInfo(Tag))

     rule getFields(T:StructOrUnionType) => getFields({utype(T)}:>StructOrUnionUType)
     rule getFields(ut(SetItem(Fields:FieldInfo) _, structType(_))) => Fields
     rule getFields(ut(SetItem(Fields:FieldInfo) _, unionType(_))) => Fields
     rule getFields(T::StructOrUnionUType) => getFieldInfo(getTagId(T)) [owise]

     syntax TagId ::= getTagId(StructOrUnionUType) [function]
     rule getTagId(ut(_, structType(S::TagId))) => S
     rule getTagId(ut(_, unionType(S::TagId))) => S

     syntax FieldInfo ::= toFieldInfo(TagInfo) [function]
     rule toFieldInfo(Fields:FieldInfo) => Fields
     rule toFieldInfo(_) => fieldInfo(.List, 0, .Map, .Map, .Set) [owise]

     rule getTagInfo(S:TagId) => #getTagInfo(S, #configuration)

     syntax Bool ::= hasNoName(Map) [function]
     rule hasNoName((_:NoName |-> _:StructOrUnionType) _::Map) => true
     rule hasNoName(_) => false [owise]

     syntax TagInfo ::= #getTagInfo(TagId, K) [function]
     rule #getTagInfo(tag(X::CId, Tu::String, B::BlockRef), <generatedTop>... <global>... <tags> M::Map </tags> ...</global> ...</generatedTop>)
          => extractTagInfo({M[Tu]}:>Map[tag(X, Tu, B)])

     syntax TagInfo ::= extractTagInfo(K) [function]
     rule extractTagInfo(fieldInfo(L::List, I::Int, M1::Map, M2::Map, S::Set)) => fieldInfo(L, I, M1, M2, S)
     rule extractTagInfo(enumInfo(...) #as EI::EnumInfo) => EI
     rule extractTagInfo(_) => #incomplete [owise]

     rule numBytes(bool) => cfg:sizeofBool
     rule numBytes(_:SimpleSignedCharType) => cfg:sizeofSignedChar
     rule numBytes(short-int) => cfg:sizeofShortInt
     rule numBytes(int) => cfg:sizeofInt
     rule numBytes(long-int) => cfg:sizeofLongInt
     rule numBytes(long-long-int) => cfg:sizeofLongLongInt
     rule numBytes(oversized-int) => cfg:sizeofOversizedInt

     rule numBytes(float) => cfg:sizeofFloat
     rule numBytes(double) => cfg:sizeofDouble
     rule numBytes(long-double) => cfg:sizeofLongDouble

     rule numBytes(_:SimpleUnsignedCharType) => numBytes(signed-char)
     rule numBytes(unsigned-short-int) => numBytes(short-int)
     rule numBytes(unsigned-int) => numBytes(int)
     rule numBytes(unsigned-long-int) => numBytes(long-int)
     rule numBytes(unsigned-long-long-int) => numBytes(long-long-int)
     rule numBytes(unsigned-oversized-int) => numBytes(oversized-int)
     rule numBytes(enumType(S::TagId)) => numBytes(getEnumAlias(S))
     rule numBytes(_) => 0 [owise]

     rule typePrecision(ut(_, float)) => cfg:precisionofFloat
     rule typePrecision(ut(_, double)) => cfg:precisionofDouble
     rule typePrecision(ut(_, long-double)) => cfg:precisionofLongDouble
     rule maxFloatPrecision => 237

     rule typeExponent(ut(_, float)) => cfg:exponentofFloat
     rule typeExponent(ut(_, double)) => cfg:exponentofDouble
     rule typeExponent(ut(_, long-double)) => cfg:exponentofLongDouble
     rule maxFloatExponent => 19

     rule roundCFloat(T:FloatUType, F:Float) => roundFloat(F, typePrecision(T), typeExponent(T))
     rule Int2CFloat(T:FloatUType, I:Int) => Int2Float(I, typePrecision(T), typeExponent(T))
     rule zeroCFloat(T:FloatUType) => Int2CFloat(T, 0)

     syntax Int ::= numBits(SimpleType) [function]
     rule numBits(T::SimpleType) => numBytes(T) *Int cfg:bitsPerByte

     rule min(ut(_, bitfieldType(_:SimpleSignedType, N::Int)))
          => 0 -Int (1 <<Int absInt(N -Int 1))
     rule max(ut(_, bitfieldType(_:SimpleSignedType, N::Int)))
          => (1 <<Int absInt(N -Int 1)) -Int 1

     rule min(ut(_, _:SimpleSignedCharType))
          => 0 -Int (1 <<Int absInt(numBits(signed-char) -Int 1))
     rule max(ut(_, _:SimpleSignedCharType))
          => (1 <<Int absInt(numBits(signed-char) -Int 1)) -Int 1
     rule min(ut(_, short-int))
          => 0 -Int (1 <<Int absInt(numBits(short-int) -Int 1))
     rule max(ut(_, short-int))
          => (1 <<Int absInt(numBits(short-int) -Int 1)) -Int 1
     rule min(ut(_, int))
          => 0 -Int (1 <<Int absInt(numBits(int) -Int 1))
     rule max(ut(_, int))
          => (1 <<Int absInt(numBits(int) -Int 1)) -Int 1
     rule min(ut(_, long-int))
          => 0 -Int (1 <<Int absInt(numBits(long-int) -Int 1))
     rule max(ut(_, long-int))
          => (1 <<Int absInt(numBits(long-int) -Int 1)) -Int 1
     rule min(ut(_, long-long-int))
          => 0 -Int (1 <<Int absInt(numBits(long-long-int) -Int 1))
     rule max(ut(_, long-long-int))
          => (1 <<Int absInt(numBits(long-long-int) -Int 1)) -Int 1
     rule min(ut(_, oversized-int))
          => 0 -Int (1 <<Int absInt(numBits(oversized-int) -Int 1))
     rule max(ut(_, oversized-int))
          => (1 <<Int absInt(numBits(oversized-int) -Int 1)) -Int 1

     rule min(_:UnsignedIntegerUType) => 0

     rule max(ut(_, bool)) => 1

     rule max(ut(_, bitfieldType(_:SimpleUnsignedType, N::Int)))
          => (1 <<Int absInt(N)) -Int 1

     rule max(ut(_, _:SimpleUnsignedCharType))
          => (1 <<Int absInt(numBits(unsigned-char))) -Int 1
     rule max(ut(_, unsigned-short-int))
          => (1 <<Int absInt(numBits(unsigned-short-int))) -Int 1
     rule max(ut(_, unsigned-int))
          => (1 <<Int absInt(numBits(unsigned-int))) -Int 1
     rule max(ut(_, unsigned-long-int))
          => (1 <<Int absInt(numBits(unsigned-long-int))) -Int 1
     rule max(ut(_, unsigned-long-long-int))
          => (1 <<Int absInt(numBits(unsigned-long-long-int))) -Int 1
     rule max(ut(_, unsigned-oversized-int))
          => (1 <<Int absInt(numBits(unsigned-oversized-int))) -Int 1

     rule min(ut(_, enumType(S::TagId))) => min(utype(getEnumAlias(S)))
     rule max(ut(_, enumType(S::TagId))) => max(utype(getEnumAlias(S)))

     rule innerType(T:UType) => innerType(type(T))

     rule innerType(t(_, _, arrayType(T::Type, _))) => T
     rule innerType(t(_, _, flexibleArrayType(T::Type))) => T
     rule innerType(t(_, _, incompleteArrayType(T::Type))) => T
     rule innerType(t(_, _, unspecifiedArrayType(T::Type))) => T
     rule innerType(t(_, _, variableLengthArrayType(T::Type, _))) => T
     rule innerType(t(_, _, bitfieldType(T::SimpleType, _))) => type(T)
     rule innerType(t(_, _, functionType(T::UType, _))) => type(T)
     rule innerType(t(_, _, pointerType(T::Type))) => T

     // The qualifier slot on arrays has a special purpose: it is for
     // qualifiers set in function parameters meant to qualify the pointer type
     // after array-to-pointer conversion.
     rule addQualifiers(Qs'::Quals, t(Qs::Quals, Mods::Set, arrayType(T::Type, N::Int)))
          => t(Qs, Mods, arrayType(addQualifiers(Qs', T), N))
     rule addQualifiers(Qs'::Quals, t(Qs::Quals, Mods::Set, flexibleArrayType(T::Type)))
          => t(Qs, Mods, flexibleArrayType(addQualifiers(Qs', T)))
     rule addQualifiers(Qs'::Quals, t(Qs::Quals, Mods::Set, incompleteArrayType(T::Type)))
          => t(Qs, Mods, incompleteArrayType(addQualifiers(Qs', T)))
     rule addQualifiers(Qs'::Quals, t(Qs::Quals, Mods::Set, unspecifiedArrayType(T::Type)))
          => t(Qs, Mods, unspecifiedArrayType(addQualifiers(Qs', T)))
     rule addQualifiers(Qs'::Quals, t(Qs::Quals, Mods::Set, variableLengthArrayType(T::Type, K:K)))
          => t(Qs, Mods, variableLengthArrayType(addQualifiers(Qs', T), K))
     rule addQualifiers(Qs'::Quals, t(Qs::Quals, Mods::Set, T::SimpleType))
          => t(Qs +Quals Qs', Mods, T) [owise]

     rule getQualifiers(t(_, _, _:SimpleArrayType) #as T::Type) => getQualifiers(innerType(T))
     rule getQualifiers(t(Qs::Quals, _, _)) => Qs [owise]

     rule showEffectiveType(T:Type) => showType(T)
     rule showEffectiveType(dynamicType(T::Type)) => showType(T)
     rule showEffectiveType(T::EffectiveType) => showK(T) [owise]

     rule showUType(T::UType) => showType(type(T))

     rule showType(T::Type) => showDeclarator("", T)

     rule showDType(variadic) => "..."
     rule showDType(typedDeclaration(T::Type, #NoName)) => showDeclarator("", T)
     rule showDType(typedDeclaration(T::Type, #NoName(_))) => showDeclarator("", T)
     rule showDType(typedDeclaration(T::Type, X::CId)) => showDeclarator(" " +String showCId(X), T) [owise]

     syntax String ::= showTypeSpecifier(SimpleType) [function]
     rule showTypeSpecifier(bool) => "_Bool"
     rule showTypeSpecifier(char) => "char"
     rule showTypeSpecifier(signed-char) => "signed char"
     rule showTypeSpecifier(short-int) => "short"
     rule showTypeSpecifier(int) => "int"
     rule showTypeSpecifier(long-int) => "long"
     rule showTypeSpecifier(long-long-int) => "long long"
     rule showTypeSpecifier(oversized-int) => "__kcc_oversized_int"
     rule showTypeSpecifier(unsigned-char) => "unsigned char"
     rule showTypeSpecifier(unsigned-short-int) => "unsigned short"
     rule showTypeSpecifier(unsigned-int) => "unsigned int"
     rule showTypeSpecifier(unsigned-long-int) => "unsigned long"
     rule showTypeSpecifier(unsigned-long-long-int) => "unsigned long long"
     rule showTypeSpecifier(unsigned-oversized-int) => "__kcc_oversized_uint"
     rule showTypeSpecifier(float) => "float"
     rule showTypeSpecifier(double) => "double"
     rule showTypeSpecifier(long-double) => "long double"
     rule showTypeSpecifier(enumType(tag(X::CId, _, _))) => "enum " +String showCId(X)
     rule showTypeSpecifier(void) => "void"
     rule showTypeSpecifier(structType(tag(X::CId, _, _))) => "struct " +String showCId(X)
     rule showTypeSpecifier(unionType(tag(X::CId, _, _))) => "union " +String showCId(X)
     rule showTypeSpecifier(bitfieldType(T::SimpleType, _) => T)
     rule showTypeSpecifier(no-type) => "<none>"

     syntax String ::= showQualifiers(Set) [function]
     rule showQualifiers(SetItem(Q1::Qualifier) SetItem(Q2::Qualifier) S::Set)
          => showQualifier(Q1) +String " " +String showQualifiers(SetItem(Q2) S)
     rule showQualifiers(SetItem(Q::Qualifier)) => showQualifier(Q)
     rule showQualifiers(.Set) => ""

     syntax String ::= showQualifier(Qualifier) [function]
     rule showQualifier(Const()) => "const"
     rule showQualifier(Volatile()) => "volatile"
     rule showQualifier(Restrict()) => "restrict"
     rule showQualifier(Atomic()) => "_Atomic"

     syntax String ::= showSpecifiedType(Type) [function]
     rule showSpecifiedType(T::Type)
          => showQualifiedSpecifier(T) +String showTypeSpecifier(simpleType(T))

     syntax String ::= showQualifiedSpecifier(Type) [function]
     rule showQualifiedSpecifier(t(quals(.Set), _, _)) => ""
     rule showQualifiedSpecifier(t(quals(S::Set), _, _))
          => showQualifiers(S) +String " " [owise]

     syntax String ::= showQualifiedDeclarator(Quals) [function]
     rule showQualifiedDeclarator(quals(.Set)) => ""
     rule showQualifiedDeclarator(quals(S::Set))
          => " " +String showQualifiers(S) [owise]

     syntax String ::= showDeclarator(String, Type) [function]
     rule showDeclarator(DDL::String, t(Q::Quals, _, pointerType(T::Type)))
          => showDeclarator(parens(T, "*" +String showQualifiedDeclarator(Q) +String DDL), T)
     rule showDeclarator(DDL::String, t(Q::Quals, _, T:SimpleArrayType))
          => showDeclarator(DDL +String showArrayDeclarator(T), innerType(t(Q, .Set, T)))
     rule showDeclarator(DDL::String, t(Q::Quals, _, functionType(Ret::UType, Params::List)))
          => showDeclarator(DDL +String " (" +String showFunctionDeclarator(Params) +String ")", type(Ret))
     rule showDeclarator(DDL::String, T::Type)
          => showSpecifiedType(T) +String DDL [owise]

     syntax String ::= showArrayDeclarator(SimpleArrayType) [function]
     rule showArrayDeclarator(arrayType(_, I::Int)) => " [" +String showInt(I) +String "]"
     rule showArrayDeclarator(T:SimpleIncompleteArrayType) => " []"
     rule showArrayDeclarator(unspecifiedArrayType(_)) => " [*]"
     rule showArrayDeclarator(variableLengthArrayType(_, _)) => " [<expr>]"

     syntax String ::= showFunctionDeclarator(List) [function]
     rule showFunctionDeclarator(ListItem(T1:DType) ListItem(T2::DType) L::List)
          => showDType(T1) +String ", " +String showFunctionDeclarator(ListItem(T2) L)
     rule showFunctionDeclarator(ListItem(T:DType))
          => showDType(T)
     rule showFunctionDeclarator(ListItem(T1:Type) ListItem(T2::DType) L::List)
          => showType(T1) +String ", " +String showFunctionDeclarator(ListItem(T2) L)
     rule showFunctionDeclarator(ListItem(T:Type))
          => showType(T)
     rule showFunctionDeclarator(.List) => ""

     syntax String ::= parens(Type, String) [function, klabel(showTypeParensC)]
     rule parens(_:FunctionType, S::String) => "(" +String S +String ")"
     rule parens(_:ArrayType, S::String) => "(" +String S +String ")"
     rule parens(_, S::String) => " " +String S [owise]

     rule adjustParams(t(Qs::Quals, Mods::Set, functionType(R::UType, Params::List)))
          => t(Qs, Mods, functionType(R, adjustParams'(Params)))
     rule adjustParams(T::Type) => T [owise]

     rule adjustParams'(ListItem(typedDeclaration(T::Type, X::CId)) Ds::List)
          => ListItem(typedDeclaration(adjustParam(T), X)) adjustParams'(Ds)
     rule adjustParams'(ListItem(t(...) #as T::Type) Ds::List)
          => ListItem(adjustParam(T)) adjustParams'(Ds)
     rule adjustParams'(ListItem(variadic) Ds::List)
          => ListItem(variadic) adjustParams'(Ds)
     rule adjustParams'(.List) => .List

     rule adjustParam(t(Qs::Quals, Mods::Set, functionType(R::UType, Params::List)))
          => type(pointerType(t(Qs, Mods, functionType(R, Params))))
     rule adjustParam(T:ArrayType) => arrayToPtrType(T)
     rule adjustParam(T::Type) => T [owise]

     rule arrayToPtrType(t(Qs::Quals, Mods::Set, _:SimpleArrayType) #as T::Type)
          => t(Qs, Mods, pointerType(innerType(T)))
     rule arrayToPtrType(T::Type) => T [owise]

endmodule
