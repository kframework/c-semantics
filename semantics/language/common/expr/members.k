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
     imports C-TYPING-SYNTAX
     imports C-CONFIGURATION

     /*@ \fromStandard{\source[n1570]{\para{6.5.2.3}{3}}}{
     A postfix expression followed by the \cinline{.} operator and an
     identifier designates a member of a structure or union object. The value
     is that of the named member, and is an lvalue if the first expression is
     an lvalue. If the first expression has qualified type, the result has the
     so-qualified version of the type of the designated member.
     }*/
     rule <k> nclv(Loc:SymLoc, t(Mods:Set,
                    structType(S:StructId))) . F:CId
               => lookupField(F, Loc, Mods, getTag(S), Fields, Fields)
          ...</k>
          <initializing> Initializing:Bool </initializing>
          <structs>... S |-> Fields:FieldInfo ...</structs>
          requires notBool (Atomic in Mods)
               orBool Initializing
          [structural]
     rule <k> nclv(Loc:SymLoc, t(Mods:Set,
                    unionType(S:StructId))) . F:CId
               => lookupField(F, addProv(fromUnion(Loc, F, Fields), Loc),
                    Mods, getTag(S), Fields, Fields)
          ...</k>
          <initializing> Initializing:Bool </initializing>
          <structs>... S |-> Fields:FieldInfo ...</structs>
          requires notBool (Atomic in Mods)
               orBool Initializing
          [structural]
     rule <k> (.K => UNDEF("CEM1",
               "attempting to access a member in an atomic struct.",
               "6.5.2.3:5, J.2:1 item 42"))
               ~> Lbl:KLabel(_, t(Mods:Set, structType(_))) . _:CId
          ...</k>
          <initializing> false </initializing>
          requires Atomic in Mods
               andBool (#klabel(Lbl) ==K #klabel(`nclv`) orBool #klabel(Lbl) ==K #klabel(`ncle`))
          [structural]
     rule <k> (.K => UNDEF("CEM2",
               "attempting to access a member in an atomic union.",
               "6.5.2.3:5, J.2:1 item 42"))
               ~> Lbl:KLabel(_, t(Mods:Set, unionType(_))) . _:CId
          ...</k>
          <initializing> false </initializing>
          requires Atomic in Mods
               andBool (#klabel(Lbl) ==K #klabel(`nclv`) orBool #klabel(Lbl) ==K #klabel(`ncle`))
          [structural]
     rule <k> (_:ErrorExit => .K) 
              ~> Lbl:KLabel(_, t((SetItem(Atomic) => .Set) Mods:Set, structType(_))) . _:CId
          ...</k>
          <initializing> false </initializing>
          requires (#klabel(Lbl) ==K #klabel(`nclv`) orBool #klabel(Lbl) ==K #klabel(`ncle`))
              andBool isErrorRecovery
     rule <k> (_:ErrorExit => .K) 
              ~> Lbl:KLabel(_, t((SetItem(Atomic) => .Set) Mods:Set, unionType(_))) . _:CId
          ...</k>
          <initializing> false </initializing>
          requires (#klabel(Lbl) ==K #klabel(`nclv`) orBool #klabel(Lbl) ==K #klabel(`ncle`))
              andBool isErrorRecovery


     // The last two parameters are for convenience and should be the same.
     // TODO(chathhorn): anonymous structs/unions.
     syntax KItem ::= lookupField(CId, SymLoc, Set, CId, FieldInfo, FieldInfo)
          [function]
     syntax KItem ::= lookupFieldHold(CId, SymLoc, Set, CId, FieldInfo, FieldInfo)

     syntax SymLoc ::= setBitOffset(Int, SymLoc, Type) [function]
     rule setBitOffset(Offset:Int, Loc:SymLoc, T:BitfieldType) => addProv(bitOffset(Offset), Loc)
     rule setBitOffset(_, Loc:SymLoc, _) => Loc [owise]

     rule lookupField(F:CId, Loc:SymLoc, Mods:Set, _, _,
          fieldInfo(_, _,
               F |-> T:Type _,
               F |-> Offset:Int _))
          // Complete recursive struct/union definitions.
          => lv(setBitOffset(Offset modInt cfg:bitsPerByte, 
                    Loc +bytes Offset /Int cfg:bitsPerByte, T),
               addQualifiers(Mods, T))
     rule lookupField(F:CId, Loc:SymLoc, Mods:Set, S:CId, Fields:FieldInfo,
               fieldInfo(Decls:List, Size:Int, Types:Map, Offsets:Map))
          => lookupFieldHold(F, Loc, Mods, S, Fields, fieldInfo(Decls, Size, Types, Offsets))
          requires notBool (F in_keys(Types) andBool F in_keys(Offsets))

     rule (.K => CV("CEM3", "attempting to access member but it does not exist", "6.5.2.3:1"))
          ~> lookupFieldHold(F:CId, _, _, _, _, fieldInfo(_, _, Types:Map, Offsets:Map))

     // Same deal as above, only for byte lists.
     rule <k> tv(agg(L:List), t(Mods:Set,
               structType(S:StructId))) . F:CId
          => extractField(F, L, Mods, getTag(S), Fields, Fields) ...</k>
          <structs>... S |-> Fields:FieldInfo ...</structs>
          [structural]
     rule <k> tv(agg(L:List), t(Mods:Set,
               unionType(S:StructId))) . F:CId
          => extractField(F, L, Mods, getTag(S), Fields, Fields) ...</k>
          <structs>... S |-> Fields:FieldInfo ...</structs>
          [structural]

     syntax KItem ::= extractField(CId, List, Set, CId, FieldInfo, FieldInfo)
          [function]

     rule extractField(F:CId, L:List, Mods:Set, _, _,
          fieldInfo(_, _,
               F |-> t(Mods':Set, T':SimpleType) _,
               F |-> Offset:Int _))
          => concretize(t(Mods Mods', T'),
               fillToBytes(extractBitsFromList(dataList(L),
                    Offset,
                    bitSizeofType(t(Mods Mods', T')))))
endmodule
