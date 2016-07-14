module C-COMMON-EXPR-MEMBERS
     imports C-BITSIZE-SYNTAX
     imports C-BITS-SYNTAX
     imports C-DYNAMIC-SYNTAX
     imports C-ENV-SYNTAX
     imports C-ERROR-SYNTAX
     imports C-MEMORY-READING-SYNTAX
     imports C-MEMORY-WRITING-SYNTAX
     imports C-SETTINGS-SYNTAX
     imports C-SYMLOC-SYNTAX
     imports C-SYNTAX
     imports C-TYPING-COMMON-SYNTAX
     imports C-TYPING-SYNTAX
     imports C-CONFIGURATION

     /*@ \fromStandard{\source[n1570]{\para{6.5.2.3}{3}}}{
     A postfix expression followed by the \cinline{.} operator and an
     identifier designates a member of a structure or union object. The value
     is that of the named member, and is an lvalue if the first expression is
     an lvalue. If the first expression has qualified type, the result has the
     so-qualified version of the type of the designated member.
     }*/
     rule <k> nclv(Loc:SymLoc, t(Qs::Quals, _,
                    structType(tag(X:CId, Tu:String, B:BlockRef)))) . F:CId
               => lookupField(F, addProv(fromUnion(Loc, F, Fields, false), Loc),
                    Qs, X, Fields, Fields)
          ...</k>
          <initializing> Initializing:Bool </initializing>
          <structs>... Tu |-> (_:Map tag(X, Tu, B) |-> Fields:FieldInfo) ...</structs>
          requires notBool (Atomic() inQuals Qs) orBool Initializing
          [structural]
     rule <k> nclv(Loc:SymLoc, t(Qs::Quals, _,
                    unionType(tag(X:CId, Tu:String, B:BlockRef)))) . F:CId
               => lookupField(F, addProv(fromUnion(Loc, F, Fields, true), Loc),
                    Qs, X, Fields, Fields)
          ...</k>
          <initializing> Initializing:Bool </initializing>
          <structs>... Tu |-> (_:Map tag(X, Tu, B) |-> Fields:FieldInfo) ...</structs>
          requires notBool (Atomic() inQuals Qs) orBool Initializing
          [structural]
     rule <k> (.K => UNDEF("CEM1",
               "Attempting to access a member in an atomic struct.",
               "6.5.2.3:5, J.2:1 item 42"))
               ~> Lbl:KLabel(_, t(Qs::Quals, _, structType(_))) . _:CId
          ...</k>
          <initializing> false </initializing>
          requires Atomic() inQuals Qs
               andBool isNCLKLabel(#klabel(Lbl))
          [structural]
     rule <k> (.K => UNDEF("CEM2",
               "Attempting to access a member in an atomic union.",
               "6.5.2.3:5, J.2:1 item 42"))
               ~> Lbl:KLabel(_, t(Qs::Quals, _, unionType(_))) . _:CId
          ...</k>
          <initializing> false </initializing>
          requires Atomic() inQuals Qs
               andBool isNCLKLabel(#klabel(Lbl))
          [structural]

     // The last two parameters are for convenience and should be the same.
     // TODO(chathhorn): anonymous structs/unions.
     syntax KItem ::= lookupField(CId, SymLoc, Quals, CId, FieldInfo, FieldInfo)
          [function]
     syntax KItem ::= lookupFieldHold(CId, SymLoc, Quals, CId, FieldInfo, FieldInfo)

     syntax SymLoc ::= setBitOffset(Int, SymLoc, Type) [function]
     rule setBitOffset(Offset:Int, Loc:SymLoc, T:BitfieldType) => addProv(bitOffset(Offset), Loc)
     rule setBitOffset(_, Loc:SymLoc, _) => Loc [owise]

     rule lookupField(F:CId, Loc:SymLoc, Qs::Quals, _, _,
          fieldInfo(_, _,
               F |-> T::Type _,
               F |-> Offset:Int _,
               _))
          // Complete recursive struct/union definitions.
          => lv(setBitOffset(Offset modInt cfg:bitsPerByte,
                    Loc +bytes Offset /Int cfg:bitsPerByte, T),
               addQualifiers(Qs, T))
     rule lookupField(F:CId, Loc:SymLoc, Qs::Quals, S:CId, Fields:FieldInfo,
               fieldInfo(Decls:List, Size:Int, Types:Map, Offsets:Map, PaddingOffs:Set))
          => lookupFieldHold(F, Loc, Qs, S, Fields, fieldInfo(Decls, Size, Types, Offsets, PaddingOffs))
          requires notBool (F in_keys(Types) andBool F in_keys(Offsets))

     rule (.K => CV("CEM3", "Attempting to access member but it does not exist.", "6.5.2.3:1"))
          ~> lookupFieldHold(F:CId, _, _, _, _, fieldInfo(_, _, Types:Map, Offsets:Map, _))

     // Same deal as above, only for byte lists.
     rule <k> tv(agg(L:List), ut(Mods::Set,
               structType(tag(X:CId, Tu:String, B:BlockRef)))) . F:CId
          => extractField(F, L, Mods, X, Fields, Fields) ...</k>
          <structs>... Tu |-> (_:Map tag(X, Tu, B) |-> Fields:FieldInfo) ...</structs>
          [structural]
     rule <k> tv(agg(L:List), ut(Mods::Set,
               unionType(tag(X:CId, Tu:String, B:BlockRef)))) . F:CId
          => extractField(F, L, Mods, X, Fields, Fields) ...</k>
          <structs>... Tu |-> (_:Map tag(X, Tu, B) |-> Fields:FieldInfo) ...</structs>
          [structural]

     syntax KItem ::= extractField(CId, List, Set, CId, FieldInfo, FieldInfo)
          [function]

     rule extractField(F:CId, L:List, Mods:Set, _, _,
          fieldInfo(_, _,
               F |-> t(_, Mods'::Set, T'::SimpleType) _,
               F |-> Offset:Int _,
               _))
          => concretize(addModifiers(Mods Mods', utype(T')),
               fillToBytes(extractBitsFromList(dataList(L),
                    Offset,
                    bitSizeofType(type(T')))))
endmodule
