module CPP-TYPING-EXPR-SYNTAX
     imports COMPAT-SYNTAX

     syntax StrictList ::= types(StrictList)
     syntax KItem ::= typeof(K)

endmodule

module CPP-TYPING-EXPR
     imports CPP-TYPING-EXPR-SYNTAX

     imports CPP-ABSTRACT-SYNTAX
     imports CPP-TYPING-SYNTAX

     syntax STypeList ::= toSTypeList(List) [function]
     syntax List ::= ofSTypeList(STypeList) [function]
     syntax KItem ::= "types()"
     rule types(list(HOLE:List)) => toSTypeList(HOLE) ~> types() [heat]
     rule HOLE:STypeList ~> types() => types(krlist(ofSTypeList(HOLE))) [cool]

     syntax STypeList ::= K "types::" STypeList
                     | ".STypeList"
     rule isKResult(.STypeList) => true
     rule isKResult(S1::STypeList types:: S2::STypeList) => isKResult(S1) andBool isKResult(S2)
     rule toSTypeList(ListItem(K:K) L::List) => K types:: toSTypeList(L)
     rule toSTypeList(.List) => .STypeList
     rule ofSTypeList(krlist(L1::List) types:: L2::STypeList) => L1 ofSTypeList(L2)
     rule ofSTypeList(.STypeList) => .List
     rule ofSTypeList(K:K types:: L::STypeList) => ListItem(K) ofSTypeList(L) [owise]

     context (HOLE:KItem => typeof(HOLE)) types:: _ [result(CPPType)]
     context K:KResult types:: HOLE:STypeList

     // ----------------------------------

     rule typeof(StringLiteral(Ascii(), S::String) => type(arrayType(const(char), lengthString(S) +Int 1)))
     context typeof(IntegerLiteral(_, HOLE:AType))
     rule typeof(IntegerLiteral(_, T:CPPType) => T)
     rule typeof(NullPointerLiteral() => type(nullptr_t))
     context typeof(HOLE:KItem)
             requires getKLabel(HOLE) ==K #klabel(`Name`)
     rule typeof(T:Typed => type(T))

endmodule
