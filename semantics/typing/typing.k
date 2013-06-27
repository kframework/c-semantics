module C-TYPING-INCLUDE
     // FIXME need to automatically pad structs
     syntax K ::= "MYHOLE"
     
     syntax K ::= "addStruct" "(" Id "," KList ")"
     syntax K ::= "addUnion" "(" Id "," KList ")"
     syntax K ::= "canonicalizeType" "(" Bag ")"
     
     // rules that use specifier should be careful to use extractActualType if
     // going to be used in a typed name
     syntax Type ::= extractActualType(Type) [function] 
     
     syntax K ::= "evalToType"

     syntax Set ::= "typeStrictLeftBinaryOperators" [function] // [memo] 
     rule typeStrictLeftBinaryOperators => 
          SetItem(l('_<<_))
          SetItem(l('_>>_))
          SetItem(l('_*=_))
          SetItem(l('_/=_))
          SetItem(l('_%=_))
          SetItem(l('_+=_))
          SetItem(l('_-=_))
          SetItem(l('_<<=_))
          SetItem(l('_>>=_))
          SetItem(l('_&=_))
          SetItem(l('_^=_))
          SetItem(l('_|=_))
          SetItem(l('_++))
          SetItem(l('_--))
          SetItem(l('--_))
          SetItem(l('++_))
          [structural]
endmodule

module C-TYPING
     imports C-TYPING-DECLARATIONS 
     imports C-TYPING-CANONICALIZATION 
     imports C-TYPING-INTERPRETATION
     imports C-TYPING-MISC
endmodule
