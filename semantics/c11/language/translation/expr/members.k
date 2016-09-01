module C-EXPR-MEMBERS
     imports C-CONFIGURATION
     imports BOOL
     imports K-EQUAL
     imports C-SYNTAX
     imports C-DYNAMIC-SYNTAX
     imports C-TYPING-SYNTAX

     rule <k> ncle(K:K, t(Qs::Quals, _, structType(tag(X:CId, Tu:String, B:BlockRef)))) . F:CId
               => le(K . F, addQualifiers(Qs, T))
          ...</k>
          <initializing> Initializing:Bool </initializing>
          <tags>... Tu |-> (_::Map tag(X, Tu, B) |-> fieldInfo(_, _, F |-> T::Type _, _, _)) ...</tags>
          requires notBool (Atomic() inQuals Qs) orBool Initializing
     // anon access
     rule <k> ncle(K:K, t(Qs::Quals, _, structType(tag(X:CId, Tu:String, B:BlockRef)))) . F:CId
               => le(K . F, addQualifiers(Qs, getTypeForField(F, searchAnons(F, false, getFieldInfo(T), 0, getFields(getFieldInfo(T)), ListItem(AF)))))
          ...</k>
          <initializing> Initializing:Bool </initializing>
          <tags>... Tu |-> (_::Map tag(X, Tu, B) |-> fieldInfo(_, _, AF:NoName |-> T::Type _, _, _)) ...</tags>
          requires searchAnons(F, false, getFieldInfo(T), 0, getFields(getFieldInfo(T)), ListItem(AF)) =/=K .List
                   andBool (notBool (Atomic() inQuals Qs) orBool Initializing)

     rule <k> te(K:K, ut(_, structType(tag(X::CId, Tu::String, B::BlockRef)))) . F:CId
               => te(K . F, utype(T))
          ...</k>
          <tags>... Tu |-> (_::Map tag(X, Tu, B) |-> fieldInfo(_, _, F |-> T::Type _, _, _)) ...</tags>
     // anon access
     rule <k> te(K:K, ut(_, structType(tag(X::CId, Tu::String, B::BlockRef)))) . F:CId
               => te(K . F, utype(getTypeForField(F, searchAnons(F, false, getFieldInfo(T), 0, getFields(getFieldInfo(T)), ListItem(AF)))))
          ...</k>
          <tags>... Tu |-> (_::Map tag(X, Tu, B) |-> fieldInfo(_, _, AF:NoName |-> T::Type _, _, _)) ...</tags>
          requires searchAnons(F, false, getFieldInfo(T), 0, getFields(getFieldInfo(T)), ListItem(AF)) =/=K .List

     rule <k> ncle(K:K, t(Qs::Quals, _, unionType(tag(X:CId, Tu:String, B:BlockRef)))) . F:CId
               => le(K . F, addQualifiers(Qs, T))
          ...</k>
          <initializing> Initializing:Bool </initializing>
          <tags>... Tu |-> (_:Map tag(X, Tu, B) |-> fieldInfo(_, _, F |-> T::Type _, _, _)) ...</tags>
          requires notBool (Atomic() inQuals Qs) orBool Initializing
     // anon access
     rule <k> ncle(K:K, t(Qs::Quals, _, unionType(tag(X:CId, Tu:String, B:BlockRef)))) . F:CId
               => le(K . F, addQualifiers(Qs, getTypeForField(F, searchAnons(F, true, getFieldInfo(T), 0, getFields(getFieldInfo(T)), ListItem(AF)))))
          ...</k>
          <initializing> Initializing:Bool </initializing>
          <tags>... Tu |-> (_:Map tag(X, Tu, B) |-> fieldInfo(_, _, AF:NoName |-> T::Type _, _, _)) ...</tags>
          requires searchAnons(F, true, getFieldInfo(T), 0, getFields(getFieldInfo(T)), ListItem(AF)) =/=K .List
                   andBool (notBool (Atomic() inQuals Qs) orBool Initializing)

     rule <k> te(K:K, ut(_, unionType(tag(X::CId, Tu::String, B::BlockRef)))) . F:CId
               => te(K . F, utype(T))
          ...</k>
          <tags>... Tu |-> (_::Map tag(X, Tu, B) |-> fieldInfo(_, _, F |-> T::Type _, _, _)) ...</tags>
     // anon access
     rule <k> te(K:K, ut(_, unionType(tag(X::CId, Tu::String, B::BlockRef)))) . F:CId
               => te(K . F, utype(getTypeForField(F, searchAnons(F, true, getFieldInfo(T), 0, getFields(getFieldInfo(T)), ListItem(AF)))))
          ...</k>
          <tags>... Tu |-> (_::Map tag(X, Tu, B) |-> fieldInfo(_, _, AF:NoName |-> T::Type _, _, _)) ...</tags>
          requires searchAnons(F, true, getFieldInfo(T), 0, getFields(getFieldInfo(T)), ListItem(AF)) =/=K .List

endmodule
