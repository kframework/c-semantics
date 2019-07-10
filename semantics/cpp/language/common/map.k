module CPP-TYPE-MAP-SYNTAX
     imports CPP-TYPING-SORTS
     imports BASIC-K
     imports MAP

     syntax Bool ::= some(Map, TypePredicate) [function, klabel(someTypeMap), prefer]
     syntax TypePredicate
     syntax Bool ::= TypePredicate "(" CPPType "," K ")" [function]
     syntax KItem ::= "(" CPPType "," KItem ")"
     syntax List ::= Map2List(Map) [function]
endmodule

module CPP-TYPE-MAP
     imports CPP-TYPE-MAP-SYNTAX
     imports CPP-TYPING-SYNTAX
     imports COMPAT-SYNTAX
     imports BOOL
     imports LIST
     imports MAP

     rule some(.Map, _::TypePredicate) => false

     rule some(_::CPPType |-> (K1::CPPType, K2:KItem) M::Map, T::TypePredicate) => T(K1, K2) orBool some(M, T) [owise]

     rule Map2List(.Map) => .List
     rule Map2List(_::CPPType |-> (T::CPPType, K:KItem) M::Map) => ListItem(kpair(T, K)) Map2List(M)

endmodule
