module C-COMMON-EXPR-MEMBERS
     imports BOOL
     imports C-ALIGNMENT-SYNTAX
     imports C-BITSIZE-SYNTAX
     imports C-BITS-SYNTAX
     imports C-CONFIGURATION
     imports C-DYNAMIC-SYNTAX
     imports C-ERROR-SYNTAX
     imports C-MEMORY-READING-SYNTAX
     imports COMMON-SORTS
     imports C-SYMLOC-SYNTAX
     imports C-SYNTAX
     imports C-TYPING-SYNTAX
     imports INT
     imports LIST
     imports SET
     imports SETTINGS-SYNTAX

     /*@ \fromStandard{\source[n1570]{\para{6.5.2.3}{3}}}{
     A postfix expression followed by the \cinline{.} operator and an
     identifier designates a member of a structure or union object. The value
     is that of the named member, and is an lvalue if the first expression is
     an lvalue. If the first expression has qualified type, the result has the
     so-qualified version of the type of the designated member.
     }*/
     rule <k> nclv(Loc:SymLoc, t(Qs::Quals, _,
                    structType(tag(X:CId, Tu:String, B:BlockRef)))) . F:CId
               => lookupField(F, Loc, false, Qs, X, Fields, Fields)
          ...</k>
          <initializing> Initializing:Bool </initializing>
          <tags>... Tu |-> (_:Map tag(X, Tu, B) |-> Fields:FieldInfo) ...</tags>
          requires notBool (Atomic() inQuals Qs) orBool Initializing
          [structural]
     rule <k> nclv(Loc:SymLoc, t(Qs::Quals, _,
                    unionType(tag(X:CId, Tu:String, B:BlockRef)))) . F:CId
               => lookupField(F, Loc, true, Qs, X, Fields, Fields)
          ...</k>
          <initializing> Initializing:Bool </initializing>
          <tags>... Tu |-> (_:Map tag(X, Tu, B) |-> Fields:FieldInfo) ...</tags>
          requires notBool (Atomic() inQuals Qs) orBool Initializing
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

     // The last two parameters are for convenience and should be the same.
     // TODO(chathhorn): anonymous structs/unions.
     syntax KItem ::= lookupField(CId, SymLoc, Bool, Quals, CId, FieldInfo, FieldInfo)
          [function]
     syntax KItem ::= addProvField(CId, SymLoc, Quals, Type, Int, List) [function]
     syntax KItem ::= createLv(CId, SymLoc, Quals, Int, Type) [function]
     syntax KItem ::= lookupFieldHold(CId, SymLoc, Quals, CId, FieldInfo, FieldInfo)
     syntax KItem ::= checkAnons(CId, SymLoc, Bool, Quals, CId, FieldInfo, List, Int) [function]
     syntax KItem ::= getLVItem(CId, SymLoc, Quals, CId, FieldInfo, List) [function]

     syntax SymLoc ::= setBitOffset(Int, SymLoc, Type) [function]
     rule setBitOffset(Offset:Int, Loc:SymLoc, T:BitfieldType) => addProv(bitOffset(Offset), Loc)
     rule setBitOffset(_, Loc:SymLoc, _) => Loc [owise]

     rule lookupField(F:CId, Loc:SymLoc, IsUnion:Bool, Qs::Quals, _, Fields:FieldInfo,
          fieldInfo(_, _,
               F |-> T::Type _,
               F |-> Offset:Int _,
               _))
          => createLv(F, addProv(fromUnion(Loc, F, Fields, IsUnion), Loc), Qs, Offset, T)

     rule createLv(F:CId, Loc:SymLoc, Qs::Quals, Offset:Int, T::Type)
          => lv(setBitOffset(Offset modInt cfg:bitsPerByte,
                    Loc +bytes Offset /Int cfg:bitsPerByte, T),
              addQualifiers(Qs, T))

     rule lookupField(F:CId, Loc:SymLoc, IsUnion:Bool, Qs::Quals, S:CId, Fields:FieldInfo,
           fieldInfo(Decls:List, _, Types:Map, Offsets:Map, _))
          => checkAnons(F, Loc, IsUnion, Qs, S, Fields, Decls, 0)
          requires anonInDecls(Decls)
                   andBool notBool (F in_keys(Types)) andBool notBool (F in_keys(Offsets))

     rule checkAnons(F:CId, Loc:SymLoc, IsUnion:Bool, Qs::Quals, S:CId,
            Fields:FieldInfo, Decls:List, Offset:Int)
          => getLVItem(F, Loc, Qs, S, Fields,
                searchAnons(F, IsUnion, Fields, Offset, Decls, .List))

     rule getLVItem(F:CId, Loc:SymLoc, Qs::Quals, _, _,
            ListItem(fieldInfo(Decls:List, Size:Int,
                      F |-> T::Type Types:Map, F |-> Offset:Int Offsets:Map, PaddingOffs:Set))
            ListItem(Offset':Int) ListItem(IsUnion:Bool) Structs:List)
          => addProvField(F, Loc, Qs, T, Offset +Int Offset',
              Structs ListItem(provInfo(F, IsUnion,
                                fieldInfo(Decls, Size, F |-> T Types, F |-> Offset Offsets, PaddingOffs))))

     rule getLVItem(F:CId, Loc:SymLoc, Qs::Quals, S:CId, Fields:FieldInfo, .List)
          => lookupFieldHold(F, Loc, Qs, S, Fields, Fields)

     rule addProvField(F:CId, Loc:SymLoc, Qs::Quals, T::Type, Offset:Int,
            ListItem(provInfo(CF:CId, IsUnion:Bool, Fields:FieldInfo))
            Rest:List)
          => addProvField(F, addProv(fromUnion(Loc, CF, Fields, IsUnion), Loc),
                Qs, T, Offset, Rest)
          requires Rest =/=K .List

     rule addProvField(F:CId, Loc:SymLoc, Qs::Quals, T::Type, Offset:Int,
            ListItem(provInfo(F, IsUnion:Bool, Fields:FieldInfo)) .List)
          => createLv(F, addProv(fromUnion(Loc, F, Fields, IsUnion), Loc),
                Qs, Offset, T)

     rule lookupField(F:CId, Loc:SymLoc, IsUnion:Bool, Qs::Quals, S:CId, Fields:FieldInfo,
               fieldInfo(Decls:List, Size:Int, Types:Map, Offsets:Map, PaddingOffs:Set))
          => lookupFieldHold(F, Loc, Qs, S, Fields, fieldInfo(Decls, Size, Types, Offsets, PaddingOffs))
          requires notBool anonInDecls(Decls)
                   andBool notBool (F in_keys(Types)) andBool notBool (F in_keys(Offsets))

     rule (.K => CV("CEM3", "Attempting to access member but it does not exist."))
          ~> lookupFieldHold(F:CId, _, _, _, _, fieldInfo(_, _, Types:Map, Offsets:Map, _))

     // Same deal as above, only for byte lists.
     rule <k> tv(agg(L:List), ut(Mods::Set,
               structType(tag(X:CId, Tu:String, B:BlockRef)))) . F:CId
          => extractField(F, false, L, Mods, X, Fields, Fields) ...</k>
          <tags>... Tu |-> (_:Map tag(X, Tu, B) |-> Fields:FieldInfo) ...</tags>
          [structural]
     rule <k> tv(agg(L:List), ut(Mods::Set,
               unionType(tag(X:CId, Tu:String, B:BlockRef)))) . F:CId
          => extractField(F, true, L, Mods, X, Fields, Fields) ...</k>
          <tags>... Tu |-> (_:Map tag(X, Tu, B) |-> Fields:FieldInfo) ...</tags>
          [structural]

     syntax KItem ::= extractField(CId, Bool, List, Set, CId, FieldInfo, FieldInfo)
          [function]
     syntax KItem ::= extractAnon(CId, List, Set, List)
          [function]
     syntax KItem ::= extractItem(CId, List, Set, Int, FieldInfo)
          [function]

     rule extractField(F:CId, IsUnion:Bool, L:List, Mods:Set, S:CId, Fields:FieldInfo,
               fieldInfo(Decls:List, _, Types:Map, Offsets:Map, _))
          => extractAnon(F, L, Mods, searchAnons(F, IsUnion, Fields, 0, Decls, .List))
          requires anonInDecls(Decls)
                   andBool notBool (F in_keys(Types)) andBool notBool (F in_keys(Offsets))
     rule extractField(F::CId, _, L::List, Mods::Set, _, _, Info::FieldInfo)
          => extractItem(F, L, Mods, 0, Info)
          [owise]

     rule extractAnon(F::CId, L::List, Mods::Set,
               ListItem(Info:FieldInfo)
               ListItem(Offset':Int) _::List)
          => extractItem(F, L, Mods, Offset', Info)

     rule extractItem(F::CId, L::List, Mods::Set, Offset'::Int,
               fieldInfo(_, _,
                         F |-> t(_, Mods'::Set, T'::SimpleType) _,
                         F |-> Offset:Int _,
                         _))
          => concretize(addModifiers(Mods Mods', utype(T')),
              fillToBytes(extractBitsFromList(dataList(L),
                   Offset +Int Offset',
                   bitSizeofType(type(T')))))

endmodule
