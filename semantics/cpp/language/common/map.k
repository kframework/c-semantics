module CPP-TYPE-MAP-SORTS
     syntax TypeMap [hook(MAP.Map)]
endmodule

module CPP-TYPE-MAP-SYNTAX
     imports CPP-TYPE-MAP-SORTS
     imports CPP-TYPING-SORTS
     imports BASIC-K

     syntax TypeMap ::= TypeMap TypeMap [left, function, hook(MAP.concat), klabel(_TypeMap_), assoc, comm, unit(.TypeMap), element(_|->TypeMap_), remove(_[_<-undef]_CPP-TYPE-MAP-SYNTAX), lookup(_[_]_CPP-TYPE-MAP-SYNTAX), choice(#filterMapChoice), filterElement(elemTypeMap)]

     syntax TypeMap ::= ".Map" [function, hook(MAP.unit), klabel(.TypeMap), prefer]

     syntax TypeMap ::= CPPTypeExpr "|->" KItem [function, klabel(_|->TypeMap_), prefer]

     syntax priorities _|->TypeMap_ > _TypeMap_ .TypeMap

     syntax priorities _|->_ > _TypeMap_ .TypeMap

     syntax non-assoc _|->TypeMap_

     syntax KItem ::= TypeMap "[" CPPTypeExpr "]" [function]

     syntax KItem ::= TypeMap "[" CPPTypeExpr "]" "orDefault" KItem [function]

     syntax TypeMap ::= TypeMap "[" CPPTypeExpr "<-" KItem "]" [function]

     syntax TypeMap ::= TypeMap "[" CPPTypeExpr "<-" "undef" "]" [function]

     syntax Map ::= Map "[" KItem "<+" TypeMap "]" [function]

     syntax Bool ::= CPPTypeExpr "in_keys" "(" TypeMap ")" [function]
                   | some(TypeMap, K) [function, klabel(someTypeMap)]

     syntax List ::= "keys_list" "(" TypeMap ")" [function]

     syntax Int ::= size(TypeMap) [function, hook(MAP.size), klabel(sizeTypeMap)]

     syntax List ::= Map2List(TypeMap) [function]
endmodule

module CPP-TYPE-MAP
     imports CPP-TYPE-MAP-SYNTAX
     imports CPP-TYPING-SYNTAX
     imports COMPAT-SYNTAX
     imports BOOL
     imports LIST
     imports MAP

     syntax TypeMap ::= elem(CPPType, KItem) [function, hook(MAP.element), klabel(elemTypeMap)]

     syntax KItem ::= lookup(TypeMap, CPPType) [function, hook(MAP.lookup), klabel(lookupTypeMap)]

     syntax KItem ::= lookupOrDefault(TypeMap, CPPType, KItem) [function, hook(MAP.lookupOrDefault), klabel(lookupOrDefaultTypeMap)]

     syntax TypeMap ::= update(TypeMap, CPPType, KItem) [function, hook(MAP.update), klabel(updateTypeMap)]

     syntax TypeMap ::= remove(TypeMap, CPPType) [function, hook(MAP.remove), klabel(removeTypeMap)]

     syntax Bool ::= inKeys(CPPType, TypeMap) [function, hook(MAP.in_keys), klabel(in_keysTypeMap)]

     syntax List ::= values(TypeMap) [function, hook(MAP.values), klabel(valuesTypeMap)]

     rule T::CPPType |-> K:KItem => elem(stripType(T), kpair(T, K))

     rule M::TypeMap [ T::CPPType ] => #selectValue(lookup(M, stripType(T)))

     syntax KItem ::= #selectValue(KItem) [function]

     rule #selectValue(kpair(_, K:KItem)) => K

     rule #selectValue(K:KItem) => K [owise] // propagate Bottom

     rule M::TypeMap [ T::CPPType ] orDefault D:KItem => #fun((kpair(_, K:KItem) => K))(lookupOrDefault(M, stripType(T), kpair(.K, D)))

     rule M::TypeMap [ T::CPPType <- K:KItem ] => update(M, stripType(T), kpair(T, K))

     rule M::TypeMap [ T::CPPType <- undef ] => remove(M, stripType(T))

     rule T::CPPType in_keys(M::TypeMap) => inKeys(stripType(T), M)

     rule some(.Map::TypeMap, Lbl:K) => false

     rule some(K1::CPPType |-> K2:KItem M::TypeMap, #klabel(Lbl:KLabel)) => Lbl(K1, K2) orBool some(M, #klabel(Lbl)) [owise]

     rule keys_list(M::TypeMap) => mapList(values(M), #klabel(`fst`))

     rule Map2List(K1::CPPType |-> K2:KItem M::TypeMap) => ListItem(kpair(K1, K2)) Map2List(M)

     rule Map2List(.Map) => .List

     rule ((A |-> M2:TypeMap) M1::Map) [A:KItem <+ B:TypeMap] => (A |-> (M2 B)) M1

     rule M::Map [A:KItem <+ B:TypeMap] => M A |-> B [owise]
endmodule
