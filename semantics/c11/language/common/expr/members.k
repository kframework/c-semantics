module C-COMMON-EXPR-MEMBERS
     imports C-CONFIGURATION
     imports BOOL
     imports INT
     imports LIST
     imports SET
     imports SETTINGS-SYNTAX
     imports C-ALIGNMENT-SYNTAX
     imports C-BITSIZE-SYNTAX
     imports C-BITS-SYNTAX
     imports C-COMMON-EXPR-EVAL-SYNTAX
     imports C-DYNAMIC-SYNTAX
     imports C-ERROR-SYNTAX
     imports C-MEMORY-READING-SYNTAX
     imports COMMON-SORTS
     imports C-SYMLOC-SYNTAX
     imports C-SYNTAX
     imports C-TYPING-SYNTAX

     /*@ \fromStandard{\source[n1570]{\para{6.5.2.3}{3}}}{
     A postfix expression followed by the \cinline{.} operator and an
     identifier designates a member of a structure or union object. The value
     is that of the named member, and is an lvalue if the first expression is
     an lvalue. If the first expression has qualified type, the result has the
     so-qualified version of the type of the designated member.
     }*/
     rule <k> nclv(Loc:SymLoc, T:StructOrUnionType) . F:CId
               => createLv(F, Loc, getQualifiers(T), findFieldOffset(F, T), findFieldType(F, T))
          ...</k>
          <initializing> Initializing:Bool </initializing>
          requires notBool (Atomic() inQuals getQualifiers(T)) orBool Initializing
          [structural]
     rule <k> (.K => UNDEF("CEM1",
               "Attempting to access a member in an atomic struct."))
               ~> Lbl:KLabel(_, t(Qs::Quals, _, structType(_))) . _:CId
          ...</k>
          <initializing> false </initializing>
          requires Atomic() inQuals Qs
               andBool isNCLKLabel(#klabel(Lbl))
          [structural]
     rule <k> (.K => UNDEF("CEM2",
               "Attempting to access a member in an atomic union."))
               ~> Lbl:KLabel(_, t(Qs::Quals, _, unionType(_))) . _:CId
          ...</k>
          <initializing> false </initializing>
          requires Atomic() inQuals Qs
               andBool isNCLKLabel(#klabel(Lbl))
          [structural]

     syntax SymLoc ::= setBitOffset(Int, SymLoc, Type) [function]
     rule setBitOffset(Offset:Int, Loc:SymLoc, T:BitfieldType) => addProv(bitOffset(Offset), Loc)
     rule setBitOffset(_, Loc:SymLoc, _) => Loc [owise]

     syntax KItem ::= lookupField(CId, SymLoc, Quals, FieldInfo) [function]

     syntax KItem ::= createLv(CId, SymLoc, Quals, Int, Type)
     rule createLv(F:CId, Loc:SymLoc, Qs::Quals, Offset::Int, T::Type)
          => lv(setBitOffset(Offset modInt cfg:bitsPerByte,
                    Loc +bytes Offset /Int cfg:bitsPerByte, T),
               addQualifiers(Qs, T))
          requires notBool isNoType(T)
     rule (.K => CV("CEM3", "Attempting to access member but it does not exist."))
          ~> createLv(_, _, _, _, _:NoType)

     // Same deal as above, only for byte lists.
     rule tv(agg(L:List), T:StructOrUnionUType) . F:CId
          => extractField(L, getModifiers(T), findFieldType(F, {type(T)}:>StructOrUnionType), findFieldOffset(F, {type(T)}:>StructOrUnionType))
          [structural]

     syntax KItem ::= extractField(List, Set, Type, Int) [function]
     rule extractField(L::List, Mods::Set, T::Type, Offset::Int)
          => concretize(addModifiers(Mods getModifiers(T), utype(T)),
               fillToBytes(extractBitsFromList(dataList(L), Offset, bitSizeofType(T))))

endmodule
