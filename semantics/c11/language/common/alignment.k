module C-ALIGNMENT-SYNTAX
     imports LIST
     imports C-TYPING-SORTS
     imports SYMLOC-SORTS

     syntax Int ::= getAlign(SymLoc) [function]
     syntax Int ::= getNativeAlign(Int) [function]

     syntax Int ::= getAlignas(Type) [function]

     syntax Int ::= byteAlignofType(Type) [function]

     syntax Int ::= maxByteAlignofList(List) [function]
endmodule

module C-ALIGNMENT
     imports C-ALIGNMENT-SYNTAX
     imports C-CONFIGURATION
     imports BOOL
     imports INT
     imports K-REFLECTION
     imports MAP
     imports SET
     imports MEMORY-SYNTAX
     imports SYMLOC-SYNTAX
     imports C-SETTINGS-SYNTAX
     imports C-TYPING-SYNTAX

     // TODO(chathhorn): make configurable.
     rule byteAlignofType(t(_, _, bool)) => cfg:alignofBool
     rule byteAlignofType(t(_, _, signed-char)) => cfg:alignofSignedChar
     rule byteAlignofType(t(_, _, short-int)) => cfg:alignofShortInt
     rule byteAlignofType(t(_, _, int)) => cfg:alignofInt
     rule byteAlignofType(t(_, _, long-int)) => cfg:alignofLongInt
     rule byteAlignofType(t(_, _, long-long-int)) => cfg:alignofLongLongInt
     rule byteAlignofType(t(_, _, float)) => cfg:alignofFloat
     rule byteAlignofType(t(_, _, double)) => cfg:alignofDouble
     rule byteAlignofType(t(_, _, long-double)) => cfg:alignofLongDouble
     rule byteAlignofType(t(_, _, no-type)) => cfg:alignofMalloc

     rule byteAlignofType(t(_, _, unsigned-char))
          => byteAlignofType(type(signed-char))
     rule byteAlignofType(t(_, _, unsigned-short-int))
          => byteAlignofType(type(short-int))
     rule byteAlignofType(t(_, _, unsigned-int))
          => byteAlignofType(type(int))
     rule byteAlignofType(t(_, _, unsigned-long-int))
          => byteAlignofType(type(long-int))
     rule byteAlignofType(t(_, _, unsigned-long-long-int))
          => byteAlignofType(type(long-long-int))

     rule byteAlignofType(t(Qs::Quals, Mods::Set, enumType(_)))
          => byteAlignofType(t(Qs, Mods, cfg:enumAlias))

     syntax Int ::= "maxByteAlignofList'" "(" Int "," List ")" [function]
     rule maxByteAlignofList(L:List) => maxByteAlignofList'(1, L)
     rule maxByteAlignofList'(Sz:Int, ListItem(T:Type) LL:List)
          => maxByteAlignofList'(maxInt(Sz, byteAlignofType(T)), LL)
     rule maxByteAlignofList'(Sz:Int, ListItem(typedDeclaration(T::Type, _)) LL:List)
          => maxByteAlignofList'(maxInt(Sz, byteAlignofType(T)), LL)
     rule maxByteAlignofList'(Sz:Int, .List) => Sz

     rule byteAlignofType(T:ArrayType)  => byteAlignofType(innerType(T))
     rule byteAlignofType(t(_, _, pointerType(_))) => cfg:alignofPointer
     rule byteAlignofType(t(_, _, structType(S:StructId)))
          => byteAlignofStruct(getFieldInfo(S))
     rule byteAlignofType(t(_, _, unionType(S:StructId)))
          => byteAlignofStruct(getFieldInfo(S))

     syntax Int ::= byteAlignofStruct(FieldInfo) [function]

     rule byteAlignofStruct(fieldInfo(Decls:List, _, _, _, _))
          => maxByteAlignofList(Decls)

     // TODO(dwightguth): make sure we correctly handle all the corner cases
     rule byteAlignofType(_) => 1 [owise]

     rule getAlignas(T::Type) => getAlignasMod(getModifiers(T))
          requires hasAlignasMod(getModifiers(T))
     rule getAlignas(T::Type) => byteAlignofType(T)
          requires notBool hasAlignasMod(getModifiers(T))

     syntax Bool ::= hasAlignasMod(Set) [function]
     rule hasAlignasMod(SetItem(alignas(_)) _) => true
     rule hasAlignasMod(_) => false [owise]

     // Gets the alignment requirement of the type with the strictest alignment
     // at the offset in the effective type of a location.
     // TODO(chathhorn): This means alignment of a pointer could change if the
     // effective type changes -- probably offsets (and padding) just need to
     // be set initially based on alignment requirements (and then that
     // _Alignas modifier can be forgotten).
     rule getAlign(Loc::SymLoc) => getAlign'(base(Loc), offset(Loc), #configuration)
          requires notBool isNativeLoc(Loc) andBool Loc =/=K NullPointer
     rule getAlign(NullPointer) => cfg:alignofMalloc
     rule getAlign(Loc::SymLoc) => getNativeAlign(offset(Loc))
          requires isNativeLoc(Loc)

     syntax Int ::= "getAlign'" "(" SymBase "," Int "," K ")" [function]
     rule getAlign'(Base::SymBase, Offset::Int, <generatedTop>... <mem>... Base |-> object(T::Type, _, _) ...</mem> ...</generatedTop>)
          => getAlign''(1, getTypesAtOffset(unlockAll(T), Offset *Int cfg:bitsPerByte))
     rule getAlign'(Base::SymBase => Base', _, <generatedTop>... <linkings>... Base |-> Base':SymBase ...</linkings> ...</generatedTop>)
     rule getAlign'(_, _, _) => 1 [owise]

     syntax Int ::= "getAlign''" "(" Int "," List ")" [function]
     rule getAlign''(N::Int, ListItem(T:Type) Ts:List) => getAlign''(N, Ts)
          requires N >=Int getAlignas(T)
     rule getAlign''(N::Int, ListItem(T:Type) Ts:List) => getAlign''(getAlignas(T), Ts)
          requires N <Int getAlignas(T)
     rule getAlign''(N::Int, _) => N [owise]

     syntax Int ::= #getNativeAlign(Int, Int, Int) [function]
     rule getNativeAlign(Address:Int) => #getNativeAlign(Address, 1, 0)
     rule #getNativeAlign(Address:Int, Accum:Int, I:Int) => #getNativeAlign(Address /Int 2, Accum *Int 2, I +Int 1)
          requires Address %Int 2 ==Int 0 andBool I <Int cfg:ptrsize *Int cfg:bitsPerByte
     rule #getNativeAlign(_, Accum:Int, _) => Accum [owise]

endmodule
