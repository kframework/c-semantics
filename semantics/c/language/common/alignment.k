module C-ALIGNMENT-SYNTAX
     imports ALIGNMENT-SYNTAX
     imports LIST
     imports C-TYPING-SORTS
     imports SYMLOC-SORTS

     syntax Int ::= getAlignas(Type) [function]

     syntax Int ::= byteAlignofType(Type) [function]

     syntax Int ::= maxByteAlignofDecls(List) [function]
endmodule

module C-ALIGNMENT
     imports BOOL
     imports C-ALIGNMENT-SYNTAX
     imports C-CONFIGURATION
     imports C-SETTINGS-SYNTAX
     imports C-TYPING-SYNTAX
     imports INT
     imports K-REFLECTION
     imports MAP
     imports MEMORY-SYNTAX
     imports SET
     imports SYMLOC-SYNTAX

     rule byteAlignofType(T::Type) => 1
          // This should only be the case for (packed) struct fields.
          requires Packed() in getModifiers(T)
     rule byteAlignofType(T::Type) => byteAlignofType'(T) [owise]

     syntax Int ::= "byteAlignofType'" "(" Type ")" [function]
     rule byteAlignofType'(t(_, _, bool)) => cfg:alignofBool
     rule byteAlignofType'(t(_, _, _:SimpleSignedCharType)) => cfg:alignofSignedChar
     rule byteAlignofType'(t(_, _, short-int)) => cfg:alignofShortInt
     rule byteAlignofType'(t(_, _, int)) => cfg:alignofInt
     rule byteAlignofType'(t(_, _, signed-int)) => cfg:alignofInt
     rule byteAlignofType'(t(_, _, long-int)) => cfg:alignofLongInt
     rule byteAlignofType'(t(_, _, long-long-int)) => cfg:alignofLongLongInt
     rule byteAlignofType'(t(_, _, oversized-int)) => cfg:alignofOversizedInt
     rule byteAlignofType'(t(_, _, float)) => cfg:alignofFloat
     rule byteAlignofType'(t(_, _, double)) => cfg:alignofDouble
     rule byteAlignofType'(t(_, _, long-double)) => cfg:alignofLongDouble
     rule byteAlignofType'(t(_, _, oversized-float)) => cfg:alignofOversizedFloat
     rule byteAlignofType'(t(_, _, no-type)) => cfg:alignofMalloc

     rule byteAlignofType'(t(_, _, _:SimpleUnsignedCharType => signed-char))
     rule byteAlignofType'(t(_, _, unsigned-short-int => short-int))
     rule byteAlignofType'(t(_, _, unsigned-int => int))
     rule byteAlignofType'(t(_, _, unsigned-long-int => long-int))
     rule byteAlignofType'(t(_, _, unsigned-long-long-int => long-long-int))
     rule byteAlignofType'(t(_, _, unsigned-oversized-int => oversized-int))
     rule byteAlignofType'(t(... st: _:SimpleArrayType) #as T::Type)  => byteAlignofType(innerType(T))
     rule byteAlignofType'(t(_, _, pointerType(_))) => cfg:alignofPointer

     rule byteAlignofType'(t(_, _, enumType(S::TagId)))
          => byteAlignofTagged(getTagInfo(S))
     rule byteAlignofType'(t(_, _, structType(S::TagId)))
          => byteAlignofTagged(getTagInfo(S))
     rule byteAlignofType'(t(_, _, unionType(S::TagId)))
          => byteAlignofTagged(getTagInfo(S))

     rule byteAlignofType'(t(_, _, bitfieldType(T::SimpleType, _)))
          => byteAlignofType'(type(T))

     rule byteAlignofType'(t(_, _, functionType(_, _))) => 0

     // TODO(dwightguth): make sure we correctly handle all the corner cases
     rule byteAlignofType'(_) => 1 [owise]

     syntax Int ::= byteAlignofTagged(TagInfo) [function]
     rule byteAlignofTagged(fieldInfo(Decls:List, _, _, _, _))
          => maxByteAlignofDecls(Decls)
     rule byteAlignofTagged(enumInfo(... enumAlias: T::SimpleIntegerType))
          => byteAlignofType'(type(T))
     rule byteAlignofTagged(_) => 1 [owise]

     syntax Int ::= #getAlignas(Type, Type) [function]
     syntax Int ::= #getAlignas(Set, Int) [function, klabel(getAlignas2)]
     // the alignas modifier is adhered to the type specified
     // by the type specifier, so we need to push past the declarators
     // to get to the type specifiers before we can check the modifiers
     rule getAlignas(T::Type) => #getAlignas(T, T)
     rule #getAlignas((t(... st: pointerType(_)) #as T::Type => innerType(T)), _)
     rule #getAlignas((t(... st: _:SimpleArrayType) #as T::Type => innerType(T)), _)
     rule #getAlignas((t(_, _, functionType(T::UType, _)) => type(T)), _)
     rule #getAlignas(T::Type, T'::Type) => #getAlignas(getModifiers(T), byteAlignofType(T')) [owise]
     rule #getAlignas(Mods::Set, _) => getAlignasMod(Mods)
          requires hasAlignasMod(Mods)
     rule #getAlignas(_, Align::Int) => Align [owise]

     syntax Bool ::= hasAlignasMod(Set) [function]
     rule hasAlignasMod(SetItem(alignas(_)) _) => true
     rule hasAlignasMod(_) => false [owise]
endmodule
